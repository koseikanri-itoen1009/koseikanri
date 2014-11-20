CREATE OR REPLACE PACKAGE BODY XXINV100001C
AS
--
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : XXINV100001C(body)
 * Description      : 生産物流(計画)
 * MD.050           : 計画・移動・在庫・販売計画/引取計画 T_MD050_BPO100
 * MD.070           : 計画・移動・在庫・販売計画/引取計画 T_MD070_BPO10A
 * Version          : 1.25
 *
 * Program List
 * -------------------------------- ----------------------------------------------------------
 *  Name                            Description
 * -------------------------------- ----------------------------------------------------------
 *  if_data_disp                    インターフェースデータ行を処理結果レポートに表示する
 *  parameter_check_forecast        A-1-2-1 Forecastチェック
 *  parameter_check_yyyymm          A-1-2-2 年月チェック
 *  parameter_check_forecast_year   A-1-2-3 年度チェック
 *  parameter_check_version         A-1-2-4 世代チェック
 *  parameter_check_forecast_date   A-1-2-5 開始日付・終了日付チェック
 *  parameter_check_item_no         A-1-2-6 品目チェック
 *  parameter_check_subinventory    A-1-2-7 出庫倉庫チェック
 *  parameter_check_account_number  A-1-2-8 拠点チェック
 *  parameter_check_dept_code       A-1-2-9 取込部署チェック
 *  get_profile_start_day           A-1-3   プロファイルより年度開始月日を取得
 *  get_start_end_day               A-1-4   対象年度開始日・対象年度終了日の取得
 *  get_keikaku_start_end_day       A-1-5   計画商品対象開始・終了年月日取得
 *  get_dept_inf                    A-1-6   部署情報の取得
 *  if_data_null_check              A-*-0   インターフェースデータ項目必須チェック
 *  get_hikitori_if_data            A-2-1   引取計画インターフェースデータ抽出
 *  get_hanbai_if_data              A-3-1   販売計画インターフェースデータ抽出
 *  get_keikaku_if_data             A-4-1   計画商品インターフェースデータ抽出
 *  get_seigen_a_if_data            A-5-1   出荷数制限Aインターフェースデータ抽出
 *  get_seigen_b_if_data            A-6-1   出荷数制限Bインターフェースデータ抽出
 *  shipped_date_start_check        1.      出庫倉庫の適用日と開始日付チェック
 *  shipped_class_check             2.      出庫倉庫の出庫管理元区分チェック
 *  base_code_exist_check           3.      拠点の存在チェック
 *  item_abolition_code_check       4.      品目の廃止区分チェック
 *  item_class_check                5.      品目の品目区分チェック
 *  item_date_start_check           6.      品目の適用日と開始日付チェック
 *  item_date_year_check            7.      品目の適用日と年度警告チェック
 *  item_standard_year_check        8.      品目の標準原価適用日と年度警告チェック
 *  item_forecast_check             9.10.   品目の物流構成表計画商品対象品目と日付チェック
 *  item_not_regist_check           11.     品目の物流構成表未登録の警告チェック
 *  date_month_check                12.     日付の対象月チェック
 *  date_year_check                 13.     日付の対象年チェック
 *  date_past_check                 14.     日付の過去チェック
 *  start_date_range_check          15.     開始日付の1ヶ月以内チェック
 *  date_start_end_check            16.     日付の開始＜終了チェック
 *  inventory_date_check            17.     出庫倉庫拠点品目日付での重複チェック
 *  base_code_date_check            18.     拠点品目日付での重複チェック
 *  quantity_num_check              19.     数量のマイナス数値チェック
 *  price_num_check                 20.     金額のマイナス数値警告チェック
 *  hikitori_data_check             A-2-2   引取計画抽出データチェック
 *  hanbai_data_check               A-3-2   販売計画抽出データチェック
 *  keikaku_data_check              A-4-2   計画商品抽出データチェック
 *  seigen_a_data_check             A-5-2   出荷数制限A抽出データチェック
 *  seigen_b_data_check             A-6-2   出荷数制限B抽出データチェック
 *  get_f_degi_hikitori             A-2-3   引取計画Forecast名抽出
 *  get_f_degi_hanbai               A-3-3   販売計画Forecast名抽出
 *  get_f_degi_keikaku              A-4-3   計画商品Forecast名抽出
 *  get_f_degi_seigen_a             A-5-3   出荷数制限AForecast名抽出
 *  get_f_degi_seigen_b             A-6-3   出荷数制限BForecast名抽出
 *  get_f_dates_hikitori            A-2-4   引取計画Forecast日付抽出
 *  get_f_dates_hanbai              A-3-4   販売計画Forecast日付抽出
 *  get_f_dates_keikaku             A-4-4   計画商品Forecast日付抽出
 *  get_f_dates_seigen_a            A-5-4   出荷数制限AForecast日付抽出
 *  get_f_dates_seigen_b            A-6-4   出荷数制限BForecast日付抽出
 *  put_forecast_hikitori           A-2-5   引取計画Forecast登録
 *  put_forecast_hanbai             A-3-5   販売計画Forecast登録
 *  put_forecast_keikaku            A-4-5   計画商品Forecast登録
 *  put_forecast_seigen_a           A-5-5   出荷数制限AForecast登録
 *  put_forecast_seigen_b           A-6-5   出荷数制限BForecast登録
 *  del_if_data                     A-X-6   共通 インターフェーステーブル削除処理
 *  forecast_hikitori               A-2     引取計画
 *  forecast_hanbai                 A-3     販売計画
 *  forecast_keikaku                A-4     計画商品
 *  forecast_seigen_a               A-5     出荷数制限A
 *  forecast_seigen_b               A-6     出荷数制限B
 *  submain                         A-1     販売計画/引取計画の取込を行うプロシージャ
 *  main                                    コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/01/11   1.0  Oracle 土田 茂     初回作成
 *  2008/04/21   1.1  Oracle 土田 茂     内部変更要求 No27 対応
 *  2008/04/24   1.2  Oracle 土田 茂     内部変更要求 No27修正, No72 対応
 *  2008/05/01   1.3  Oracle 土田 茂     結合テスト時の不具合対応
 *  2008/05/26   1.4  Oracle 熊本 和郎   結合テスト障害対応(I/F削除後のコミット追加)
 *  2008/05/26   1.5  Oracle 熊本 和郎   結合テスト障害対応(エラー件数、スキップ件数の算出方法変更)
 *  2008/05/26   1.6  Oracle 熊本 和郎   規約違反(varchar使用)対応
 *  2008/05/29   1.7  Oracle 熊本 和郎   結合テスト障害対応(販売計画のMD050.機能フローとロジックの不一致修正)
 *  2008/06/04   1.8  Oracle 熊本 和郎   システムテスト障害対応(販売計画の削除対象抽出条件からROWNUM=1削除)
 *  2008/06/12   1.9  Oracle 大橋 孝郎   結合テスト障害対応(400_不具合ログ#115)
 *  2008/08/01   1.10 Oracle 山根 一浩   ST障害No10,変更要求No184対応
 *  2008/09/01   1.11 Oracle 大橋 孝郎   PT 2-2_13 指摘56,PT 2-2_14 指摘58,メッセージ出力不具合対応
 *  2008/09/16   1.12 Oracle 大橋 孝郎   PT 2-2_14指摘75,76,77対応
 *  2008/11/07   1.13 Oracle Yuko Kawano 統合指摘#585
 *  2008/11/11   1.14 Oracle 福田 直樹   統合指摘#589対応
 *  2008/11/13   1.15 Oracle 大橋 孝郎   指摘586,596対応
 *  2008/12/01   1.16 Oracle 大橋 孝郎   本番#155対応
 *  2009/02/17   1.17 Oracle 加波由香里  本番障害#38対応
 *  2009/02/27   1.18 Oracle 大橋 孝郎   本番#1240対応
 *  2009/04/08   1.19 Oracle 吉元 強樹   本番#1352,1374対応
 *  2009/04/09   1.20 Oracle 吉元 強樹   本番#1350対応
 *  2009/04/13   1.21 Oracle 吉元 強樹   本番#1350対応,メッセージ出力不具合対応(エラー重複表示)
 *  2009/04/16   1.22 Oracle 椎名 昭圭   本番#1407対応
 *  2009/05/19   1.23 Oracle 丸下        本番#1437対応
 *  2009/05/20   1.24 Oracle 丸下        本番#1341対応
 *  2009/10/08   1.25 Oracle 吉元 強樹   本番#1648対応
 *****************************************************************************************/
--
--#######################  固定グローバル定数宣言部 START   #######################
--
  gv_status_normal CONSTANT VARCHAR2(1) := '0';   --正常
  gv_status_warn   CONSTANT VARCHAR2(1) := '1';   --警告
  gv_status_error  CONSTANT VARCHAR2(1) := '2';   --エラー
  gv_sts_cd_normal CONSTANT VARCHAR2(1) := 'C';   --ステータス(正常)
  gv_sts_cd_warn   CONSTANT VARCHAR2(1) := 'G';   --ステータス(警告)
  gv_sts_cd_error  CONSTANT VARCHAR2(1) := 'E';   --ステータス(エラー)
  gv_msg_part      CONSTANT VARCHAR2(3) := ' : ';
  gv_msg_cont      CONSTANT VARCHAR2(3) := '.';
  gv_msg_pnt       CONSTANT VARCHAR2(3) := ',';
  gv_flg_on        CONSTANT VARCHAR2(1) := '1';
--
--################################  固定部 END   ##################################
--
--#######################  固定グローバル変数宣言部 START   #######################
--
  gv_out_msg              VARCHAR2(2000);
  gv_sep_msg              VARCHAR2(2000);
  gv_exec_user            VARCHAR2(100);          -- 実行ユーザ名
  gv_conc_name            VARCHAR2(30);           -- 実行コンカレント名
  gn_target_cnt           NUMBER;                 -- 対象件数
  gn_normal_cnt           NUMBER;                 -- 正常件数
  gn_warn_cnt             NUMBER;                 -- 警告件数
  gn_error_cnt            NUMBER;                 -- エラー件数
  gv_conc_status          VARCHAR2(30);           -- 終了ステータス
-- add start 1.11
  gn_del_data_cnt         NUMBER := 0;  -- あらいがえ対象データの処理カウンタ
-- add end 1.11
-- add start ver1.15
  gn_del_data_cnt2         NUMBER := 0;  -- あらいがえ対象データの処理カウンタ2
-- add end ver1.15
--
--
--################################  固定部 END   ##################################
--
--##########################  固定共通例外宣言部 START  ###########################
--
  --*** 処理部共通例外 ***
  global_process_expt       EXCEPTION;
  --*** 共通関数例外 ***
  global_api_expt           EXCEPTION;
  --*** 共通関数OTHERS例外 ***
  global_api_others_expt    EXCEPTION;
--
  PRAGMA EXCEPTION_INIT(global_api_others_expt,-20000);
--
--################################  固定部 END   ##################################
--
  -- ===============================
  -- ユーザー定義例外
  -- ===============================
  parameter_expt         EXCEPTION;     -- パラメータ例外
  quantity_expt          EXCEPTION;
  duplication            EXCEPTION;
  date_error             EXCEPTION;
  no_data                EXCEPTION;
  amount_expt            EXCEPTION;
  warning_expt           EXCEPTION;
  lock_expt              EXCEPTION;     -- ロック(ビジー)エラー
  null_expt              EXCEPTION;
  warn_expt              EXCEPTION;
--
  PRAGMA EXCEPTION_INIT(lock_expt, -54);
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  gv_pkg_name     CONSTANT VARCHAR2(100) := 'XXINV100001C';   -- パッケージ名
  gv_msg_kbn_inv  CONSTANT VARCHAR2(5)   := 'XXINV';          -- メッセージ区分XXINV
  gv_msg_kbn_cmn  CONSTANT VARCHAR2(5)   := 'XXCMN';          -- メッセージ区分XXCMN
--
  --メッセージ番号
  gv_msg_10a_001  CONSTANT VARCHAR2(15) := 'APP-XXCMN-00001'; --ユーザー名
  gv_msg_10a_002  CONSTANT VARCHAR2(15) := 'APP-XXCMN-00002'; --コンカレント名
  gv_msg_10a_003  CONSTANT VARCHAR2(15) := 'APP-XXCMN-00003'; --セパレータ
  gv_msg_10a_004  CONSTANT VARCHAR2(15) := 'APP-XXCMN-00005'; --成功データ（見出し）
  gv_msg_10a_005  CONSTANT VARCHAR2(15) := 'APP-XXCMN-00006'; --エラーデータ（見出し）
  gv_msg_10a_006  CONSTANT VARCHAR2(15) := 'APP-XXCMN-00007'; --スキップデータ（見出し）
  gv_msg_10a_007  CONSTANT VARCHAR2(15) := 'APP-XXCMN-00008'; --処理件数
  gv_msg_10a_008  CONSTANT VARCHAR2(15) := 'APP-XXCMN-00009'; --成功件数
  gv_msg_10a_009  CONSTANT VARCHAR2(15) := 'APP-XXCMN-00010'; --エラー件数
  gv_msg_10a_010  CONSTANT VARCHAR2(15) := 'APP-XXCMN-00011'; --スキップ件数
  gv_msg_10a_011  CONSTANT VARCHAR2(15) := 'APP-XXCMN-00012'; --処理ステータス
  gv_msg_10a_016  CONSTANT VARCHAR2(15) := 'APP-XXCMN-10002'; -- プロファイル取得エラー
  gv_msg_10a_043  CONSTANT VARCHAR2(15) := 'APP-XXCMN-10001'; -- 対象データなし
  gv_msg_10a_044  CONSTANT VARCHAR2(15) := 'APP-XXCMN-10053'; -- テーブルロックエラー
  gv_msg_10a_045  CONSTANT VARCHAR2(15) := 'APP-XXCMN-10018'; -- ＡＰＩエラー
  gv_msg_10a_046  CONSTANT VARCHAR2(15) := 'APP-XXCMN-10118'; -- 起動時間
  gv_msg_10a_047  CONSTANT VARCHAR2(15) := 'APP-XXCMN-10030'; -- コンカレント定型エラー
  gv_msg_10a_060  CONSTANT VARCHAR2(15) := 'APP-XXCMN-10121'; -- クイックコード取得エラー
  gv_msg_10a_072  CONSTANT VARCHAR2(15) := 'APP-XXCMN-10012'; -- 日付不正エラー
--
  gv_msg_10a_014  CONSTANT VARCHAR2(15) := 'APP-XXINV-10015'; -- 入力パラメータエラー
  gv_msg_10a_012  CONSTANT VARCHAR2(15) := 'APP-XXINV-10072'; -- 入力パラメータ必須エラー
  gv_msg_10a_013  CONSTANT VARCHAR2(15) := 'APP-XXINV-10073'; -- Forecast分類エラー
  gv_msg_10a_015  CONSTANT VARCHAR2(15) := 'APP-XXINV-10074'; -- 入力パラメータ日付比較エラー
  gv_msg_10a_017  CONSTANT VARCHAR2(15) := 'APP-XXINV-10075'; -- 引取計画フォーキャスト名取得エラー
  gv_msg_10a_018  CONSTANT VARCHAR2(15) := 'APP-XXINV-10076'; -- 販売計画フォーキャスト名取得エラー
                                                          -- 出荷数制限Ａフォーキャスト名取得エラー
  gv_msg_10a_019  CONSTANT VARCHAR2(15) := 'APP-XXINV-10077';
                                                          -- 出荷数制限Ｂフォーキャスト名取得エラー
  gv_msg_10a_020  CONSTANT VARCHAR2(15) := 'APP-XXINV-10078';
  gv_msg_10a_021  CONSTANT VARCHAR2(15) := 'APP-XXINV-10079'; -- フォーキャスト日付更新ワーニング
  gv_msg_10a_022  CONSTANT VARCHAR2(15) := 'APP-XXINV-10080'; -- 品目存在チェックエラー
  gv_msg_10a_023  CONSTANT VARCHAR2(15) := 'APP-XXINV-10081'; -- 出荷倉庫存在チェックエラー
  gv_msg_10a_024  CONSTANT VARCHAR2(15) := 'APP-XXINV-10082'; -- 拠点存在チェックエラー
  gv_msg_10a_025  CONSTANT VARCHAR2(15) := 'APP-XXINV-10083'; -- 部署コード取得エラー
  gv_msg_10a_026  CONSTANT VARCHAR2(15) := 'APP-XXINV-10084'; -- 出荷倉庫管理元区分エラー
  gv_msg_10a_027  CONSTANT VARCHAR2(15) := 'APP-XXINV-10085'; -- 品目廃止エラー
  gv_msg_10a_028  CONSTANT VARCHAR2(15) := 'APP-XXINV-10086'; -- 品目区分チェックワーニング
  gv_msg_10a_029  CONSTANT VARCHAR2(15) := 'APP-XXINV-10087'; -- 品目存在チェックワーニング
  gv_msg_10a_030  CONSTANT VARCHAR2(15) := 'APP-XXINV-10088'; -- 品目年度チェックワーニング
  gv_msg_10a_031  CONSTANT VARCHAR2(15) := 'APP-XXINV-10089'; -- 品目標準原価年度チェックワーニング
  gv_msg_10a_032  CONSTANT VARCHAR2(15) := 'APP-XXINV-10090'; -- 品目計画商品存在チェックエラー
  gv_msg_10a_033  CONSTANT VARCHAR2(15) := 'APP-XXINV-10091'; -- 品目物流構成存在チェックワーニング
  gv_msg_10a_034  CONSTANT VARCHAR2(15) := 'APP-XXINV-10092'; -- 開始日付過去年月エラー
  gv_msg_10a_035  CONSTANT VARCHAR2(15) := 'APP-XXINV-10093'; -- 開始日付過去年度エラー
  gv_msg_10a_036  CONSTANT VARCHAR2(15) := 'APP-XXINV-10094'; -- 日付過去チェックワーニング
  gv_msg_10a_037  CONSTANT VARCHAR2(15) := 'APP-XXINV-10095'; -- 日付1ヶ月以内チェックワーニング
  gv_msg_10a_038  CONSTANT VARCHAR2(15) := 'APP-XXINV-10096'; -- 日付大小比較エラー
  gv_msg_10a_039  CONSTANT VARCHAR2(15) := 'APP-XXINV-10097'; -- 重複チェックエラー１
  gv_msg_10a_040  CONSTANT VARCHAR2(15) := 'APP-XXINV-10098'; -- 重複チェックエラー２
  gv_msg_10a_041  CONSTANT VARCHAR2(15) := 'APP-XXINV-10099'; -- 数値チェックエラー
  gv_msg_10a_042  CONSTANT VARCHAR2(15) := 'APP-XXINV-10100'; -- 金額データありエラー
  gv_msg_10a_061  CONSTANT VARCHAR2(15) := 'APP-XXINV-10142'; -- 商品区分取得エラー
--
  gv_msg_10a_059  CONSTANT VARCHAR2(15) := 'APP-XXINV-10143'; -- ケース入り数取得エラー
  gv_msg_10a_058  CONSTANT VARCHAR2(15) := 'APP-XXINV-10144'; -- 計画商品フォーキャスト名取得エラー
--
  --複数取得時に使用
  gv_msg_10a_062  CONSTANT VARCHAR2(15) := 'APP-XXINV-10137'; -- 引取計画フォーキャスト名重複エラー
  gv_msg_10a_063  CONSTANT VARCHAR2(15) := 'APP-XXINV-10141'; -- 販売計画フォーキャスト名重複エラー
                                                          -- 出荷数制限Aフォーキャスト名重複エラー
  gv_msg_10a_064  CONSTANT VARCHAR2(15) := 'APP-XXINV-10139';
                                                          -- 出荷数制限Bフォーキャスト名重複エラー
  gv_msg_10a_065  CONSTANT VARCHAR2(15) := 'APP-XXINV-10140';
  gv_msg_10a_066  CONSTANT VARCHAR2(15) := 'APP-XXINV-10138'; -- 計画商品フォーキャスト名重複エラー
  gv_msg_10a_067  CONSTANT VARCHAR2(15) := 'APP-XXINV-10132'; -- 引取計画必須チェックエラー
  gv_msg_10a_068  CONSTANT VARCHAR2(15) := 'APP-XXINV-10133'; -- 計画商品必須チェックエラー
  gv_msg_10a_069  CONSTANT VARCHAR2(15) := 'APP-XXINV-10134'; -- 出荷数制限A必須チェックエラー
  gv_msg_10a_070  CONSTANT VARCHAR2(15) := 'APP-XXINV-10135'; -- 出荷数制限B必須チェックエラー
  gv_msg_10a_071  CONSTANT VARCHAR2(15) := 'APP-XXINV-10136'; -- 販売計画必須チェックエラー
  gv_msg_10a_073  CONSTANT VARCHAR2(15) := 'APP-XXINV-10154'; -- 金額マイナスエラー
--
  gv_cons_forecast_designator CONSTANT VARCHAR2(100) := 'Forecast分類';       -- Forecast分類
  gv_cons_forecast_yyyymm     CONSTANT VARCHAR2(100) := '年月';               -- 年月
  gv_cons_forecast_year       CONSTANT VARCHAR2(100) := '年度';               -- 年度
  gv_cons_forecast_version    CONSTANT VARCHAR2(100) := '世代';               -- 世代
  gv_cons_forecast_date       CONSTANT VARCHAR2(100) := '開始日付';           -- 開始日付
  gv_cons_forecast_end_date   CONSTANT VARCHAR2(100) := '終了日付';           -- 終了日付
  gv_cons_item_no             CONSTANT VARCHAR2(100) := '品目';               -- 品目
  gv_cons_subinventory_code   CONSTANT VARCHAR2(100) := '出庫倉庫';           -- 出庫倉庫
  gv_cons_account_number      CONSTANT VARCHAR2(100) := '拠点';               -- 拠点
  gv_cons_dept_code_flg       CONSTANT VARCHAR2(100) := '取込部署抽出フラグ'; -- 取込部署抽出フラグ
  gv_cons_login_user          CONSTANT VARCHAR2(100) := 'ログインユーザ';     -- ログインユーザ
  gv_cons_dept_code           CONSTANT VARCHAR2(100) := '取込部署';           -- 取込部署
  gv_cons_input_forecast      CONSTANT VARCHAR2(100) := 'Forecast分類:';      -- Forecast分類
  gv_cons_input_param         CONSTANT VARCHAR2(100) := '入力パラメータ値:';  -- 入力パラメータ値
-- add start ver1.15
  gv_object                   CONSTANT VARCHAR2(100) := 'あらいがえ対象:';  -- あらいがえ前データ
-- add end ver1.15
--
  gv_cons_fc_type             CONSTANT VARCHAR2(100) := 'XXINV_FC_TYPE';-- loopup_type=Forecast分類
--                                                        -- loopup_type=計画商品対象期間
  gv_cons_type_keikaku_term        CONSTANT VARCHAR2(100) := 'XXINV_KEIKAKU_TERM';
  gv_custmer_class_code_kyoten     CONSTANT VARCHAR2(100) := '1';      -- 顧客区分(1:拠点)
  gv_cons_flg_yes                  CONSTANT VARCHAR2(100) := 'Yes';
  gv_cons_flg_no                   CONSTANT VARCHAR2(100) := 'No';
  gv_ship_ctl_id_leaf        CONSTANT VARCHAR2(100) := '1';            -- '出荷管理元・リーフ'
  gv_ship_ctl_id_drink       CONSTANT VARCHAR2(100) := '2';            -- '出荷管理元・ドリンク'
  gv_ship_ctl_id_both        CONSTANT VARCHAR2(100) := '3';            -- '出荷管理元・両方'
  gv_cons_item_product       CONSTANT VARCHAR2(100) := '5';            -- '品目区分・製品'
--
  gv_cons_lang_ja            CONSTANT VARCHAR2(100) := 'JA';           -- 'JA'
  gv_cons_base_code          CONSTANT VARCHAR2(100) := '1';            -- '拠点'
  gv_cons_product            CONSTANT VARCHAR2(100) := '製品';         -- '製品'
-- 2009/04/08 v1.19 T.Yoshimoto Mod Start 本番#1352
--  gv_cons_p_type_standard    CONSTANT VARCHAR2(100) := '1';            -- マスタ区分＝標準＝'1'
  gv_cons_p_type_standard    CONSTANT VARCHAR2(100) := '2';            -- マスタ区分＝標準＝'2'
-- 2009/04/08 v1.19 T.Yoshimoto Mod End 本番#1352
  gn_cons_p_item_flag        CONSTANT NUMBER        := 1;              -- 計画商品
--
  gv_cons_case_quantity      CONSTANT VARCHAR2(100) := 'ケース数量';   -- 'ケース数量'
  gv_cons_quantity           CONSTANT VARCHAR2(100) := 'バラ数量';     -- 'バラ数量'
  gv_cons_amount             CONSTANT VARCHAR2(100) := '金額';         -- '金額'
--
  gn_cons_no_data_found      CONSTANT NUMBER        := 0;              -- データなし
  gn_cons_data_found         CONSTANT NUMBER        := 1;              -- データあり
--
  gv_cons_fc_type_hikitori   CONSTANT VARCHAR2(100) := '01';            -- 引取計画
  gv_cons_fc_type_keikaku    CONSTANT VARCHAR2(100) := '02';            -- 計画商品
  gv_cons_fc_type_seigen_a   CONSTANT VARCHAR2(100) := '03';            -- 出荷数制限A
  gv_cons_fc_type_seigen_b   CONSTANT VARCHAR2(100) := '04';            -- 出荷数制限B
  gv_cons_fc_type_hanbai     CONSTANT VARCHAR2(100) := '05';            -- 販売計画
--
  gv_cons_keikaku_term       CONSTANT VARCHAR2(100) := '計画商品対象期間';
  gv_cons_days               CONSTANT VARCHAR2(100) := '日数';
-- mod start 1.11
--  gv_cons_api                CONSTANT VARCHAR2(100) := '予測API';
  gv_cons_api                CONSTANT VARCHAR2(100) := '予測';
-- mod end 1.11
-- トークン
  gv_tkn_status        CONSTANT VARCHAR2(15) := 'STATUS';
  gv_tkn_cnt           CONSTANT VARCHAR2(15) := 'CNT';
  gv_tkn_conc          CONSTANT VARCHAR2(15) := 'CONC';
  gv_tkn_user          CONSTANT VARCHAR2(15) := 'USER';
  gv_tkn_time          CONSTANT VARCHAR2(15) := 'TIME';
  gv_tkn_ng_profile    CONSTANT VARCHAR2(15) := 'NG_PROFILE';
  gv_tkn_api_name      CONSTANT VARCHAR2(15) := 'API_NAME';
  gv_tkn_par           CONSTANT VARCHAR2(15) := 'PAR';
  gv_tkn_sdate         CONSTANT VARCHAR2(15) := 'SDATE';
  gv_tkn_edate         CONSTANT VARCHAR2(15) := 'EDATE';
--
  gv_tkn_parameter     CONSTANT VARCHAR2(15) := 'PARAMETER';  -- 入力パラメータ
  gv_tkn_value         CONSTANT VARCHAR2(15) := 'VALUE';      -- パラメータ値
  gv_tkn_profile       CONSTANT VARCHAR2(15) := 'PROFILE';    -- プロファイル名
  gv_tkn_item          CONSTANT VARCHAR2(15) := 'ITEM';       -- 品目コード
  gv_tkn_soko          CONSTANT VARCHAR2(15) := 'SOKO';       -- 出荷倉庫コード
  gv_tkn_kyoten        CONSTANT VARCHAR2(15) := 'KYOTEN';     -- 拠点コード
  gv_tkn_column        CONSTANT VARCHAR2(15) := 'COLUMN';     -- 項目名
  gv_tkn_table         CONSTANT VARCHAR2(15) := 'TABLE';      -- テーブル名
  gv_tkn_busho         CONSTANT VARCHAR2(15) := 'BUSHO';      -- 取込部署
  gv_tkn_forcast       CONSTANT VARCHAR2(15) := 'FORCAST';    -- Forecast
  gv_tkn_lup_type      CONSTANT VARCHAR2(15) := 'LOOKUP_TYPE';-- LOOKUP_TYPE
  gv_tkn_meaning       CONSTANT VARCHAR2(15) := 'MEANING';    -- MEANING
  gv_tkn_amount        CONSTANT VARCHAR2(15) := 'AMOUNT';     -- 金額
  gv_tkn_nendo         CONSTANT VARCHAR2(15) := 'NENDO';      -- 年度
  gv_tkn_sedai         CONSTANT VARCHAR2(15) := 'SEDAI';      -- 世代
  gv_tkn_case          CONSTANT VARCHAR2(15) := 'CASE';       -- ケース数量
  gv_tkn_bara          CONSTANT VARCHAR2(15) := 'BARA';       -- バラ数量
  gv_tkn_key           CONSTANT VARCHAR2(15) := 'KEY';        -- キー
  gv_tkn_ng_table      CONSTANT VARCHAR2(15) := 'NG_TABLE';   -- NGテーブル
--
  --プロファイル
  gv_prf_start_day     CONSTANT VARCHAR2(100) := 'XXCMN_PERIOD_START_DAY'; -- XXCMN:年度開始月日
  gv_prf_item_div      CONSTANT VARCHAR2(100) := 'XXCMN_ITEM_DIV';         -- 商品区分
  gv_prf_article_div   CONSTANT VARCHAR2(100) := 'XXCMN_ARTICLE_DIV';      -- 品目区分
--
  -- 使用DB名
                                           -- 販売計画/引取計画インターフェーステーブル名
  gv_if_table     CONSTANT VARCHAR2(100) := 'XXINV_MRP_FORECAST_INTERFACE';
  gv_if_table_jp  CONSTANT VARCHAR2(100) := '販売計画/引取計画インターフェーステーブル';
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
--
  -- レコード定義等を記述する
  -- インターフェーステーブルのデータを格納するレコード
  TYPE forecast_rec IS RECORD(
    txns_id              xxinv_mrp_forecast_interface.forecast_if_id%TYPE,      -- 取引ID
    forecast_designator  xxinv_mrp_forecast_interface.forecast_designator%TYPE, -- Forecast分類
    location_code        xxinv_mrp_forecast_interface.location_code%TYPE,       -- 出荷倉庫
    base_code            xxinv_mrp_forecast_interface.base_code%TYPE,           -- 拠点
    dept_code            xxinv_mrp_forecast_interface.dept_code%TYPE,           -- 取込部署
    item_code            xxinv_mrp_forecast_interface.item_code%TYPE,           -- 品目
    start_date_active    xxinv_mrp_forecast_interface.forecast_date%TYPE,       -- 開始日付(DATE型)
    end_date_active      xxinv_mrp_forecast_interface.forecast_end_date%TYPE,   -- 終了日付(DATE型)
    case_quantity        xxinv_mrp_forecast_interface.case_quantity%TYPE,       -- ケース数量
    quantity             xxinv_mrp_forecast_interface.indivi_quantity%TYPE,     -- バラ数量
    price                xxinv_mrp_forecast_interface.amount%TYPE               -- 金額
  );
  -- Forecast日付テーブルに登録するためのデータを格納する結合配列
  TYPE forecast_tbl IS TABLE OF forecast_rec INDEX BY PLS_INTEGER;
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
--
  gv_forecast_designator  VARCHAR2(100);      -- Forecast分類
  gv_in_param             VARCHAR2(100);      -- 入力パラメータ値
  gd_sysdate_yyyymmdd     DATE;               -- システム現在日付
  gv_in_yyyymm            VARCHAR2(10);       -- 入力バラメータの年月
  gd_in_yyyymmdd_start    DATE;               -- 入力バラメータの年月の月初日
  gd_in_yyyymmdd_end      DATE;               -- 入力バラメータの年月の月末日
  gd_in_start_date        DATE;               -- 入力バラメータの開始日付
  gd_in_end_date          DATE;               -- 入力バラメータの終了日付
  gv_in_start_date        VARCHAR2(10);               -- 入力バラメータの開始日付
  gv_in_end_date          VARCHAR2(10);               -- 入力バラメータの終了日付
  gv_start_mmdd           VARCHAR2(5);        -- 年度開始日付(A-1-3でセット)
  gv_start_yyyymmdd       VARCHAR2(10);       -- 対象年度開始年月日(A-1-4でセット)
  gd_start_yyyymmdd       DATE;               -- 対象年度開始年月日(A-1-4でセット)
  gd_end_yyyymmdd         DATE;               -- 対象年度終了年月日
--
  gd_keikaku_start_date   DATE;               -- 計画商品開始日
  gd_keikaku_end_date     DATE;               -- 計画商品終了日
  gn_login_user           NUMBER;             -- ログインユーザ名
  gn_created_by           NUMBER;             -- ログインユーザID
  gv_forecast_year        VARCHAR2(10);       -- 入力バラメータの年度
  gv_forecast_version     VARCHAR2(10);       -- 入力バラメータの世代
--
  gv_item_div             VARCHAR2(10);       -- プロファイルから取得する商品区分
  gv_article_div          VARCHAR2(10);       -- プロファイルから取得する品名区分
  gn_araigae_cnt          NUMBER := 0;
  
--
  gv_in_item_code      xxinv_mrp_forecast_interface.item_code%TYPE;     -- 入力バラメータの品目
  gv_in_base_code      xxinv_mrp_forecast_interface.base_code%TYPE;     -- 入力バラメータの拠点
  gv_in_location_code  xxinv_mrp_forecast_interface.location_code%TYPE; -- 入力バラメータの出荷倉庫
  gv_in_dept_code_flg     VARCHAR2(10); -- 取込部署抽出フラグ
--
  gv_location_short_name xxcmn_locations_all.location_short_name%TYPE;  -- 担当部署
  gv_location_code       hr_locations_all.location_code%TYPE;  -- 事業所コード
--
  -- A-*-3 で取得する
  gv_3f_forecast_designator
             mrp_forecast_designators.forecast_designator%TYPE;       -- Forecast名
  gn_3f_organization_id
             mrp_forecast_designators.organization_id%TYPE;           -- 在庫組織
  -- A-*-4 で取得する
  TYPE araigae_rec IS RECORD(
    gv_4f_txns_id
             mrp_forecast_dates.transaction_id%TYPE,                  -- 取引ID
    gv_4f_forecast_designator
             mrp_forecast_dates.forecast_designator%TYPE,             -- Forecast名
    gv_4f_organization_id
             mrp_forecast_dates.organization_id%TYPE,                 -- 在庫組織
    gv_4f_item_id
             mrp_forecast_dates.inventory_item_id%TYPE,               -- 品目
    gd_4f_start_date_active
             mrp_forecast_dates.forecast_date%TYPE,                   -- 開始日付
    gd_4f_end_date_active
             mrp_forecast_dates.rate_end_date%TYPE                   -- 終了日付
-- add start ver1.15
   ,gd_4f_item_no
             ic_item_mst_b.item_no%TYPE                              -- 品目コード
   ,gd_4f_quantity
             mrp_forecast_dates.current_forecast_quantity%TYPE       -- 数量
   ,gd_4f_case_quantity
             mrp_forecast_dates.attribute6%TYPE                      -- 元ケース数量
   ,gd_4f_bara_quantity
             mrp_forecast_dates.attribute4%TYPE                      -- 元バラ数量
-- add end ver1.15
  );
--
  --販売計画用グローバル変数
  gv_4h_txns_id
             mrp_forecast_dates.transaction_id%TYPE;                  -- 取引ID
  gv_4h_forecast_designator
             mrp_forecast_dates.forecast_designator%TYPE;             -- Forecast名
  gv_4h_organization_id
             mrp_forecast_dates.organization_id%TYPE;                 -- 在庫組織
  gv_4h_item_id
             mrp_forecast_dates.inventory_item_id%TYPE;               -- 品目
  gd_4h_start_date_active
             mrp_forecast_dates.forecast_date%TYPE;                   -- 開始日付
  gd_4h_end_date_active
             mrp_forecast_dates.rate_end_date%TYPE;                   -- 終了日付
--
  --計画商品用グローバル変数
  gd_4k_start_date_active
             mrp_forecast_dates.forecast_date%TYPE;                   -- 開始日付
  gd_4k_end_date_active
             mrp_forecast_dates.rate_end_date%TYPE;                   -- 終了日付
--
  -- Forecast日付テーブルを削除するためのデータを格納する結合配列
  TYPE araigae_tbl IS TABLE OF araigae_rec INDEX BY PLS_INTEGER;
--
  gn_datadisp_no          NUMBER := 0;        -- data行を出力した添字を保存
  -- ここに添字がある場合はすでに、データ行を表示しているのでメッセージのみ表示する。
  gn_no_msg_disp          NUMBER := 0;        -- mainにて処理結果レポートに表示しない
  -- A-2-2, A-3-2, A-4-2, A-5-2, A-6-2 でエラーメッセージを表示した場合は、mainで最後に
  -- メッセージを表示する必要がないので、mainはこの変数で表示の是非を決める
-- 2008/08/01 Add ↓
-- WHOカラム
  gn_last_updated_by         NUMBER;
  gn_request_id              NUMBER;
  gn_program_application_id  NUMBER;
  gn_program_id              NUMBER;
  gd_who_sysdate             DATE;
-- 2008/08/01 Add ↑
--
-- add start 1.11
  t_forecast_designator_tabl      MRP_FORECAST_INTERFACE_PK.t_forecast_designator;
  -- Forecast登録用レコード
  t_forecast_interface_tab_inst   MRP_FORECAST_INTERFACE_PK.t_forecast_interface;
-- add end 1.11
-- 2009/04/09 v1.20 T.Yoshimoto Add Start 本番#1350
  -- Forecast登録用レコード(販売計画マイナス値登録用)
  t_forecast_interface_tab_inst2   MRP_FORECAST_INTERFACE_PK.t_forecast_interface;
-- 2009/04/09 v1.20 T.Yoshimoto Add End 本番#1350
--
-- 2009/05/19 ADD START
   gv_forecast_type VARCHAR2(2);  -- iv_forecast_designatorの値を保持する
-- 2009/05/19 ADD END
-- 2009/02/17 本番障害#38対応 ADD Start --
-- =======================================
--  プロシージャ宣言                    
-- =======================================
  -- A-2-3 引取計画Forecast名抽出
  PROCEDURE get_f_degi_hikitori(
    in_if_data_tbl           IN  forecast_tbl,
    in_if_data_cnt           IN  NUMBER,          -- 処理中のIFデータカウンタ
    ov_errbuf                OUT NOCOPY VARCHAR2, -- エラー・メッセージ           --# 固定 #
    ov_retcode               OUT NOCOPY VARCHAR2, -- リターン・コード             --# 固定 #
    ov_errmsg                OUT NOCOPY VARCHAR2  -- ユーザー・エラー・メッセージ --# 固定 #
  );
--
  -- A-4-3 計画商品Forecast名抽出
  PROCEDURE get_f_degi_keikaku(
    in_if_data_tbl           IN  forecast_tbl,
    in_if_data_cnt           IN  NUMBER,          -- 処理中のIFデータカウンタ
    ov_errbuf                OUT NOCOPY VARCHAR2, -- エラー・メッセージ           --# 固定 #
    ov_retcode               OUT NOCOPY VARCHAR2, -- リターン・コード             --# 固定 #
    ov_errmsg                OUT NOCOPY VARCHAR2  -- ユーザー・エラー・メッセージ --# 固定 #
  );
--
  -- A-5-3 出荷数制限AForecast名抽出
  PROCEDURE get_f_degi_seigen_a(
    in_if_data_tbl           IN  forecast_tbl,
    in_if_data_cnt           IN  NUMBER,          -- 処理中のIFデータカウンタ
    ov_errbuf                OUT NOCOPY VARCHAR2, -- エラー・メッセージ           --# 固定 #
    ov_retcode               OUT NOCOPY VARCHAR2, -- リターン・コード             --# 固定 #
    ov_errmsg                OUT NOCOPY VARCHAR2  -- ユーザー・エラー・メッセージ --# 固定 #
  );
--
  -- A-6-3 出荷数制限BForecast名抽出
  PROCEDURE get_f_degi_seigen_b(
    in_if_data_tbl           IN  forecast_tbl,
    in_if_data_cnt           IN  NUMBER,          -- 処理中のIFデータカウンタ
    ov_errbuf                OUT NOCOPY VARCHAR2, -- エラー・メッセージ           --# 固定 #
    ov_retcode               OUT NOCOPY VARCHAR2, -- リターン・コード             --# 固定 #
    ov_errmsg                OUT NOCOPY VARCHAR2  -- ユーザー・エラー・メッセージ --# 固定 #
  );
-- 2009/02/17 本番障害#38対応 ADD End   --
-- 2009/05/20 ADD START
  /**********************************************************************************
   * Procedure Name   : del_if_all
   * Description      : Forecast区分レベルでIFデータを削除する
   ***********************************************************************************/
  PROCEDURE del_if_all(
    iv_forecast_designator   IN  VARCHAR2,         -- Forecast区分
    ov_errbuf                OUT NOCOPY VARCHAR2,  -- エラー・メッセージ           --# 固定 #
    ov_retcode               OUT NOCOPY VARCHAR2,  -- リターン・コード             --# 固定 #
    ov_errmsg                OUT NOCOPY VARCHAR2)  -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'del_if_all'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- IFデータをクリアする
    DELETE 
    FROM xxinv_mrp_forecast_interface mfi
    WHERE  mfi.forecast_designator = iv_forecast_designator  -- Forecast分類
    AND    mfi.created_by          = gn_created_by           -- 作成者=ログインユーザ
    ;
    -- 削除を完了するためコミットを実行する
    COMMIT;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END del_if_all;
--
-- 2009/05/20 ADD END
--
  /**********************************************************************************
   * Procedure Name   : if_data_disp
   * Description      : インターフェースデータ行を処理結果レポートに表示する
   ***********************************************************************************/
  PROCEDURE if_data_disp(
    in_if_data_tbl        IN  forecast_tbl,
    in_datadisp_no        IN  NUMBER)           -- 処理中のIFデータカウンタ
  IS
    lv_databuf  VARCHAR2(5000);  -- インターフェースデータ行
  BEGIN
    IF ( in_datadisp_no <> gn_datadisp_no ) THEN
      lv_databuf := in_if_data_tbl(in_datadisp_no).txns_id                || gv_msg_pnt ||
                    in_if_data_tbl(in_datadisp_no).forecast_designator    || gv_msg_pnt ||
                    in_if_data_tbl(in_datadisp_no).location_code          || gv_msg_pnt ||
                    in_if_data_tbl(in_datadisp_no).base_code              || gv_msg_pnt ||
                    in_if_data_tbl(in_datadisp_no).dept_code              || gv_msg_pnt ||
                    in_if_data_tbl(in_datadisp_no).item_code              || gv_msg_pnt ||
                    in_if_data_tbl(in_datadisp_no).start_date_active      || gv_msg_pnt ||
                    in_if_data_tbl(in_datadisp_no).end_date_active        || gv_msg_pnt ||
                    in_if_data_tbl(in_datadisp_no).case_quantity          || gv_msg_pnt ||
                    in_if_data_tbl(in_datadisp_no).quantity               || gv_msg_pnt ||
                    in_if_data_tbl(in_datadisp_no).price;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_databuf);
      -- インターフェースデータ行を表示したのでグローバルに添え字を保存する
      gn_datadisp_no := in_datadisp_no;
    END IF;
  END if_data_disp;
--
  /**********************************************************************************
   * Procedure Name   : parameter_check_forecast
   * Description      : 入力パラメータチェック－Forecast区分(A-1-2-1)
   ***********************************************************************************/
  PROCEDURE parameter_check_forecast(
    iv_forecast_designator   IN  VARCHAR2,         -- Forecast区分
    ov_errbuf                OUT NOCOPY VARCHAR2,  -- エラー・メッセージ           --# 固定 #
    ov_retcode               OUT NOCOPY VARCHAR2,  -- リターン・コード             --# 固定 #
    ov_errmsg                OUT NOCOPY VARCHAR2)  -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'parameter_check_forecast'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    ln_count_num NUMBER;        -- Forecast分類存在するか(1:あり、0:なし）
--
    -- *** ローカル変数 ***
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- Forecast分類の入力がない場合はエラーとする
    IF (iv_forecast_designator IS NULL) THEN
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_inv   -- 'XXINV'
                                                    ,gv_msg_10a_012   -- 入力パラメータ必須エラー
                                                    ,gv_tkn_parameter -- トークン'PARAMETER'
                                                    ,gv_cons_forecast_designator) -- 'Forecast分類'
                                                    ,1
                                                    ,5000);
      RAISE parameter_expt;
    END IF;
--
    -- 入力パラメータのForecast分類がクイックコード情報に存在するか(1:あり、0:なし）
    SELECT xlv_v.description
    INTO   gv_forecast_designator
    FROM   xxcmn_lookup_values_v xlv_v
    WHERE  xlv_v.lookup_type = gv_cons_fc_type
      AND  xlv_v.lookup_code = iv_forecast_designator
      AND  ROWNUM            = 1;
--
  EXCEPTION
    WHEN parameter_expt THEN                           --*** NULL***
      -- *** 任意で例外処理を記述する ****
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;                                            --# 任意 #
--
    WHEN NO_DATA_FOUND THEN                           --*** 存在しない ***
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_inv   -- 'XXINV'
                                                    ,gv_msg_10a_013)  -- Forecast分類エラー
                                                    ,1
                                                    ,5000);
      gv_forecast_designator := iv_forecast_designator;
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;                                            --# 任意 #
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END parameter_check_forecast;
--
--
/**********************************************************************************
   * Procedure Name   : parameter_check_yyyymm
   * Description      : 入力パラメータチェック－年月(A-1-2-2)
   ***********************************************************************************/
  PROCEDURE parameter_check_yyyymm(
    iv_forecast_designator   IN  VARCHAR2,         -- Forecast区分
    iv_forecast_yyyymm       IN  VARCHAR2,         -- 年月
    ov_errbuf                OUT NOCOPY VARCHAR2,  -- エラー・メッセージ           --# 固定 #
    ov_retcode               OUT NOCOPY VARCHAR2,  -- リターン・コード             --# 固定 #
    ov_errmsg                OUT NOCOPY VARCHAR2)  -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'parameter_check_yyyymm'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- 年月のチェックはForecast分類が'引取計画'のみ行う
    IF (iv_forecast_designator <> gv_cons_fc_type_hikitori) THEN
      RETURN;
    END IF;
--
    -- 年月の入力がない場合はエラーとする
    IF (iv_forecast_yyyymm IS NULL) THEN
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_inv   -- 'XXINV'
                                                    ,gv_msg_10a_012   -- 入力パラメータ必須エラー
                                                    ,gv_tkn_parameter -- トークン'PARAMETER'
                                                    ,gv_cons_forecast_yyyymm)   -- '年月'
                                                    ,1
                                                    ,5000);
      RAISE parameter_expt;
    END IF;
--
    -- 年月がシステム日付より古い場合はエラーとする
    IF (iv_forecast_yyyymm < TO_CHAR(gd_sysdate_yyyymmdd,'YYYYMM')) THEN
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_inv   -- 'XXINV'
                                                    ,gv_msg_10a_014   -- 入力パラメータエラー
                                                    ,gv_tkn_parameter -- トークン'PARAMETER'
                                                    ,gv_cons_forecast_yyyymm
                                                    ,gv_tkn_value     -- トークン'VALUE'
                                                    ,iv_forecast_yyyymm)   -- 年月
                                                    ,1
                                                    ,5000);
      RAISE parameter_expt;
    END IF;
--
  EXCEPTION
    WHEN parameter_expt THEN                           --*** パラメータ例外 ***
      -- *** 任意で例外処理を記述する ****
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;                                            --# 任意 #
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END parameter_check_yyyymm;
--
  /**********************************************************************************
   * Procedure Name   : parameter_check_forecast_year
   * Description      : 入力パラメータチェック－年度(A-1-2-3)
   ***********************************************************************************/
  PROCEDURE parameter_check_forecast_year(
    iv_forecast_designator   IN  VARCHAR2,         -- Forecast区分
    iv_forecast_year         IN  VARCHAR2,         -- 年度
    ov_errbuf                OUT NOCOPY VARCHAR2,  -- エラー・メッセージ           --# 固定 #
    ov_retcode               OUT NOCOPY VARCHAR2,  -- リターン・コード             --# 固定 #
    ov_errmsg                OUT NOCOPY VARCHAR2)  -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'parameter_check_forecast_year'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    ld_yyyy_format          DATE;
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- 年度のチェックはForecast分類が'販売計画'のみ行う
    IF (iv_forecast_designator <> gv_cons_fc_type_hanbai) THEN
      RETURN;
    END IF;
--
    -- 年度の入力がない場合はエラーとする
    IF (iv_forecast_year IS NULL) THEN
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_inv    -- 'XXINV'
                                                    ,gv_msg_10a_012    -- 入力パラメータ必須エラー
                                                    ,gv_tkn_parameter  -- トークン'PARAMETER'
                                                    ,gv_cons_forecast_year) -- '年度'
                                                    ,1
                                                    ,5000);
      RAISE parameter_expt;
    END IF;
--
    -- YYYYの型に変換(NULLが帰ってきたらエラー）
    ld_yyyy_format := FND_DATE.STRING_TO_DATE(iv_forecast_year, 'YYYY');
--
    -- YYYYの日付型ではない場合はエラーとする
    IF (ld_yyyy_format IS NULL) THEN
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_inv         -- 'XXINV'
                                                    ,gv_msg_10a_014         -- 入力パラメータエラー
                                                    ,gv_tkn_parameter       -- トークン'PARAMETER'
                                                    ,gv_cons_forecast_year  -- '年度'
                                                    ,gv_tkn_value           -- トークン'VALUE'
                                                    ,iv_forecast_year)      -- 年度
                                                    ,1
                                                    ,5000);
      RAISE parameter_expt;
    END IF;
--
  EXCEPTION
    WHEN parameter_expt THEN                           --*** パラメータ例外 ***
      -- *** 任意で例外処理を記述する ****
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;                                            --# 任意 #
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END parameter_check_forecast_year;
--
--
  /**********************************************************************************
   * Procedure Name   : parameter_check_version
   * Description      : 入力パラメータチェック－世代(A-1-2-4)
   ***********************************************************************************/
  PROCEDURE parameter_check_version(
    iv_forecast_designator   IN  VARCHAR2,         -- Forecast区分
    iv_forecast_version      IN  VARCHAR2,         -- 世代
    ov_errbuf                OUT NOCOPY VARCHAR2,  -- エラー・メッセージ           --# 固定 #
    ov_retcode               OUT NOCOPY VARCHAR2,  -- リターン・コード             --# 固定 #
    ov_errmsg                OUT NOCOPY VARCHAR2)  -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'parameter_check_version'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    ln_version      NUMBER;
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- 世代のチェックはForecast分類が'販売計画'のみ行う
    IF (iv_forecast_designator <> gv_cons_fc_type_hanbai) THEN
      RETURN;
    END IF;
--
    -- 世代の入力がない場合はエラーとする
    IF (iv_forecast_version IS NULL) THEN
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_inv   -- 'XXINV'
                                                    ,gv_msg_10a_012   -- 入力パラメータ必須エラー
                                                    ,gv_tkn_parameter -- トークン'PARAMETER'
                                                    ,gv_cons_forecast_version) -- '世代'
                                                    ,1
                                                    ,5000);
      RAISE parameter_expt;
    END IF;
--
    -- 数値型に変換(変換できない場合は例外処理へ＝エラー）
    ln_version := TO_NUMBER(iv_forecast_version);
--
  EXCEPTION
    WHEN parameter_expt THEN                           --*** パラメータ例外 ***
      -- *** 任意で例外処理を記述する ****
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;                                            --# 任意 #
--
    -- TO_NUMBER()で変換できなかった場合
    WHEN VALUE_ERROR THEN
      -- 世代が数値型ではない場合はエラーとする
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_inv   -- 'XXINV'
                                                    ,gv_msg_10a_014   -- 入力パラメータエラー
                                                    ,gv_tkn_parameter -- トークン'PARAMETER'
                                                    ,gv_cons_forecast_version  -- '世代'
                                                    ,gv_tkn_value              -- トークン'VALUE'
                                                    ,iv_forecast_version)      -- 世代
                                                    ,1
                                                    ,5000);
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;                                            --# 任意 #
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END parameter_check_version;
--
--
  /**********************************************************************************
   * Procedure Name   : parameter_check_forecast_date
   * Description      : 入力パラメータチェック－開始・終了日付(A-1-2-5)
   ***********************************************************************************/
  PROCEDURE parameter_check_forecast_date(
    iv_forecast_designator   IN  VARCHAR2,         -- Forecast区分
    iv_forecast_date         IN  VARCHAR2,         -- 開始日付
    iv_forecast_end_date     IN  VARCHAR2,         -- 終了日付
    ov_errbuf                OUT NOCOPY VARCHAR2,  -- エラー・メッセージ           --# 固定 #
    ov_retcode               OUT NOCOPY VARCHAR2,  -- リターン・コード             --# 固定 #
    ov_errmsg                OUT NOCOPY VARCHAR2)  -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'parameter_check_forecast_date'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    ld_yyyymmdd_format          DATE;
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- 開始・終了日付のチェックはForecast分類が'出荷数制限A'または'出荷数制限B'のみ行う
    IF ((iv_forecast_designator <> gv_cons_fc_type_seigen_a)
      AND (iv_forecast_designator <> gv_cons_fc_type_seigen_b))
    THEN
      RETURN;
    END IF;
--
    -- 開始日付の入力がない場合はエラーとする
    IF (iv_forecast_date IS NULL) THEN
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_inv   -- 'XXINV'
                                                    ,gv_msg_10a_012   -- 入力パラメータ必須エラー
                                                    ,gv_tkn_parameter -- トークン'PARAMETER'
                                                    ,gv_cons_forecast_date)   -- '開始日付'
                                                    ,1
                                                    ,5000);
      RAISE parameter_expt;
    END IF;
--
    -- 終了日付の入力がない場合はエラーとする
    IF (iv_forecast_end_date IS NULL) THEN
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_inv   -- 'XXINV'
                                                    ,gv_msg_10a_012   -- 入力パラメータ必須エラー
                                                    ,gv_tkn_parameter -- トークン'PARAMETER'
                                                    ,gv_cons_forecast_end_date)   -- '終了日付'
                                                    ,1
                                                    ,5000);
      RAISE parameter_expt;
    END IF;
--
    -- 開始日付をYYYYMMDDの型に変換(NULLが帰ってきたらエラー）
    ld_yyyymmdd_format := FND_DATE.STRING_TO_DATE(iv_forecast_date, 'YYYY/MM/DD');
--
    -- 開始日付がYYYYMMDDの日付型ではない場合はエラーとする
    IF (ld_yyyymmdd_format IS NULL) THEN
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_inv   -- 'XXINV'
                                                    ,gv_msg_10a_014   -- 入力パラメータエラー
                                                    ,gv_tkn_parameter -- トークン'PARAMETER'
                                                    ,gv_cons_forecast_date -- '開始日付'
                                                    ,gv_tkn_value     -- トークン'VALUE'
                                                    ,iv_forecast_date)     -- 開始日付
                                                    ,1
                                                    ,5000);
      RAISE parameter_expt;
    END IF;
--
    -- 終了日付をYYYYMMDDの型に変換(NULLが帰ってきたらエラー）
    ld_yyyymmdd_format := FND_DATE.STRING_TO_DATE(iv_forecast_end_date, 'YYYY/MM/DD');
--
    -- 終了日付がYYYYMMDDの日付型ではない場合はエラーとする
    IF (ld_yyyymmdd_format IS NULL) THEN
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_inv   -- 'XXINV'
                                                    ,gv_msg_10a_014   -- 入力パラメータエラー
                                                    ,gv_tkn_parameter -- トークン'PARAMETER'
                                                    ,gv_cons_forecast_end_date   -- '終了日付'
                                                    ,gv_tkn_value     -- トークン'VALUE'
                                                    ,iv_forecast_end_date)         -- 終了日付
                                                    ,1
                                                    ,5000);
      RAISE parameter_expt;
    END IF;
--
    -- 開始日付と終了日付の関係が不正な場合はエラーとする
    IF (iv_forecast_date > iv_forecast_end_date) THEN
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_inv -- 'XXINV'
                                                                  -- 入力パラメータ日付比較エラー
                                                    ,gv_msg_10a_015)
                                                    ,1
                                                    ,5000);
      RAISE parameter_expt;
    END IF;
--
  EXCEPTION
    WHEN parameter_expt THEN                           --*** パラメータ例外 ***
      -- *** 任意で例外処理を記述する ****
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;                                            --# 任意 #
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END parameter_check_forecast_date;
--
  /**********************************************************************************
   * Procedure Name   : parameter_check_item_no
   * Description      : 入力パラメータチェック－品目(A-1-2-6)
   ***********************************************************************************/
  PROCEDURE parameter_check_item_no(
    iv_forecast_designator   IN  VARCHAR2,         -- Forecast区分
    iv_item_no               IN  VARCHAR2,         -- 品目
    ov_errbuf                OUT NOCOPY VARCHAR2,  -- エラー・メッセージ           --# 固定 #
    ov_retcode               OUT NOCOPY VARCHAR2,  -- リターン・コード             --# 固定 #
    ov_errmsg                OUT NOCOPY VARCHAR2)  -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'parameter_check_item_no'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    ln_select_count    NUMBER;          -- 存在チェックのためのカウンタ
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- 品目のチェックはForecast分類が'出荷数制限A'または'出荷数制限B'で入力時のみ行う
    IF ((iv_forecast_designator <> gv_cons_fc_type_seigen_a)
      AND (iv_forecast_designator <> gv_cons_fc_type_seigen_b))
    THEN
      RETURN;
    END IF;
--
    -- 品目の入力があった場合のみチェックを行う
    IF (iv_item_no IS NOT NULL) THEN
--
      -- 品目が妥当でない(存在しない)場合はエラーとする
      SELECT COUNT(imv.item_id)
      INTO   ln_select_count
      FROM   xxcmn_item_mst_v  imv   -- OPM品目情報View
      WHERE  imv.item_no       = iv_item_no
        AND  ROWNUM            = 1;
--
      -- 品目が妥当でない(存在しない)場合の後処理
      IF (ln_select_count = 0) THEN
        lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_inv    -- 'XXINV'
                                                      ,gv_msg_10a_022    -- 品目存在チェックエラー
                                                      ,gv_tkn_item       -- トークン'ITEM'
                                                      ,iv_item_no)       -- 品目
                                                      ,1
                                                      ,5000);
        RAISE global_api_expt;
      END IF;
    END IF;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END parameter_check_item_no;
--
--
  /**********************************************************************************
   * Procedure Name   : parameter_check_subinventory
   * Description      : 入力パラメータチェック－出庫倉庫(A-1-2-7)
   ***********************************************************************************/
  PROCEDURE parameter_check_subinventory(
    iv_forecast_designator   IN  VARCHAR2,         -- Forecast区分
    iv_location_code         IN  VARCHAR2,         -- 出庫倉庫
    ov_errbuf                OUT NOCOPY VARCHAR2,  -- エラー・メッセージ           --# 固定 #
    ov_retcode               OUT NOCOPY VARCHAR2,  -- リターン・コード             --# 固定 #
    ov_errmsg                OUT NOCOPY VARCHAR2)  -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'parameter_check_subinventory'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    ln_select_count    NUMBER;          -- 存在チェックのためのカウンタ
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- 出庫倉庫のチェックはForecast分類が'出荷数制限B'で入力時のみ行う
    IF (iv_forecast_designator <> gv_cons_fc_type_seigen_b) THEN
      RETURN;
    END IF;
--
    -- 出庫倉庫の入力があった場合のみチェックを行う
    IF (iv_location_code IS NOT NULL) THEN
--
      -- OPM保管場所情報VIEW(XXCMN_ITEM_LOCATIONS_V)から保管倉庫IDを抽出する
      -- 保管倉庫IDが存在しない場合はエラーとする
      SELECT COUNT(ilv.inventory_location_id)
      INTO   ln_select_count
      FROM   xxcmn_item_locations_v ilv
      WHERE  ilv.segment1 = iv_location_code
        AND  ROWNUM        = 1;
--
      -- 出庫倉庫が妥当でない(存在しない)場合の後処理
      IF (ln_select_count = 0) THEN
        lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_inv -- 'XXINV'
                                                      ,gv_msg_10a_023 -- 出荷倉庫存在チェックエラー
                                                      ,gv_tkn_soko    -- トークン'SOKO'
                                                      ,iv_location_code)  -- 出庫倉庫
                                                      ,1
                                                      ,5000);
        RAISE global_api_expt;
      END IF;
    END IF;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END parameter_check_subinventory;
--
--
  /**********************************************************************************
   * Procedure Name   : parameter_check_account_number
   * Description      : 入力パラメータチェック－拠点(A-1-2-8)
   ***********************************************************************************/
  PROCEDURE parameter_check_account_number(
    iv_forecast_designator   IN  VARCHAR2,  -- Forecast区分
    iv_account_number        IN  VARCHAR2,  -- 拠点
    ov_errbuf                OUT NOCOPY VARCHAR2,  -- エラー・メッセージ           --# 固定 #
    ov_retcode               OUT NOCOPY VARCHAR2,  -- リターン・コード             --# 固定 #
    ov_errmsg                OUT NOCOPY VARCHAR2)  -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'parameter_check_account_number'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    ln_select_count    NUMBER;          -- 存在チェックのためのカウンタ
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- 拠点のチェックはForecast分類が'出荷数制限A'で入力時のみ行う
    IF (iv_forecast_designator <> gv_cons_fc_type_seigen_a) THEN
      RETURN;
    END IF;
--
    -- 拠点の入力があった場合のみチェックを行う
    IF (iv_account_number IS NOT NULL) THEN
--
      -- 顧客マスタ(xxcmn_cust_accounts_v)、パーティマスタ(xxcmn_parties_v)、
      -- パーティアドオンマスタ(xxcmn_parties)から顧客IDを抽出する
      -- 顧客IDが存在しない場合はエラーとする
      SELECT COUNT(cpv.cust_account_id)
      INTO   ln_select_count
-- 2009/10/08 v1.25 T.Yoshimoto Mod Start 本番#1648
      --FROM   xxcmn_parties2_v       cpv
      FROM   xxcmn_parties_v       cpv
-- 2009/10/08 v1.25 T.Yoshimoto Mod End 本番#1648
      WHERE  cpv.account_number      =  iv_account_number
        AND  cpv.customer_class_code =  gv_custmer_class_code_kyoten
-- 2009/10/08 v1.25 T.Yoshimoto Del Start 本番#1648
        --AND  cpv.start_date_active  <= gd_sysdate_yyyymmdd
        --AND  cpv.end_date_active    >= gd_sysdate_yyyymmdd
-- 2009/10/08 v1.25 T.Yoshimoto Del End 本番#1648
        AND  ROWNUM                  = 1;
--
    -- 拠点が妥当でない(存在しない)場合の後処理
      IF (ln_select_count = 0) THEN
        lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_inv   -- 'XXINV'
                                                      ,gv_msg_10a_024   -- 拠点存在チェックエラー
                                                      ,gv_tkn_kyoten    -- トークン'KYOTEN'
                                                      ,iv_account_number)  -- 拠点
                                                      ,1
                                                      ,5000);
        RAISE global_api_expt;
      END IF;
    END IF;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END parameter_check_account_number;
--
--
  /**********************************************************************************
   * Procedure Name   : parameter_check_dept_code
   * Description      : 入力パラメータチェック－取込部署(A-1-2-9)
   ***********************************************************************************/
  PROCEDURE parameter_check_dept_code(
    iv_forecast_designator   IN  VARCHAR2,         -- Forecast区分
    iv_dept_code_flg         IN  VARCHAR2,         -- 取込部署抽出フラグ
    ov_errbuf                OUT NOCOPY VARCHAR2,  -- エラー・メッセージ           --# 固定 #
    ov_retcode               OUT NOCOPY VARCHAR2,  -- リターン・コード             --# 固定 #
    ov_errmsg                OUT NOCOPY VARCHAR2)  -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'parameter_check_dept_code'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- 取込部署のチェックはForecast分類が出荷数制限B'のみ行う
    IF (iv_forecast_designator <> gv_cons_fc_type_seigen_b) THEN
      RETURN;
    END IF;
--
    -- 取込部署抽出フラグの入力がない場合はエラーとする
    IF (iv_dept_code_flg IS NULL) THEN
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_inv   -- 'XXINV'
                                                    ,gv_msg_10a_012   -- 入力パラメータ必須エラー
                                                    ,gv_tkn_parameter -- トークン'PARAMETER'
                                                    ,gv_cons_dept_code_flg) -- '取込部署抽出フラグ'
                                                    ,1
                                                    ,5000);
      RAISE parameter_expt;
    END IF;
--
    -- 取込部署抽出フラグが'Yes'または'No'以外の場合はエラーとする
    IF ((iv_dept_code_flg <> gv_cons_flg_yes) AND (iv_dept_code_flg <> gv_cons_flg_no)) THEN
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_inv   -- 'XXINV'
                                                    ,gv_msg_10a_014   -- 入力パラメータエラー
                                                    ,gv_tkn_parameter -- トークン'PARAMETER'
                                                    ,gv_cons_dept_code_flg -- '取込部署抽出フラグ'
                                                    ,gv_tkn_value      -- トークン'VALUE'
                                                    ,iv_dept_code_flg) -- 取込部署抽出フラグ
                                                    ,1
                                                    ,5000);
      RAISE parameter_expt;
    END IF;
--
  EXCEPTION
    WHEN parameter_expt THEN                           --*** パラメータ例外 ***
      -- *** 任意で例外処理を記述する ****
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;                                            --# 任意 #
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END parameter_check_dept_code;
--
  /***********************************************************************************
   * Procedure Name   : get_profile_start_day
   * Description      : A-1-3 プロファイルより年度開始月日を取得する
   ***********************************************************************************/
  PROCEDURE get_profile_start_day(
    ov_errbuf     OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_profile_start_day'; -- プログラム名
--
--##############################  固定ローカル変数宣言部 START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--#####################################  固定部 END   #############################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    lv_start_day   VARCHAR2(10);
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--################################  固定ステータス初期化部 START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  固定部 END   #############################################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    --年度開始月日取得
    lv_start_day := SUBSTRB(FND_PROFILE.VALUE(gv_prf_start_day),1,5);
--
    -- プロファイルが取得できない場合はエラー
    IF (lv_start_day IS NULL) THEN
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_cmn   -- 'XXCMN'
                                                    ,gv_msg_10a_016   -- プロファイル取得エラー
                                                    ,gv_tkn_profile   -- トークン'PROFILE'
                                                    ,gv_prf_start_day)-- XXCMN:年度開始月日
                                                    ,1
                                                    ,5000);
      RAISE global_api_expt;
    END IF;
--
    gv_start_mmdd := lv_start_day; -- 年度開始月日に設定
--
    --==============================================================
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
--#################################  固定例外処理部 START   #######################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   #############################################
--
  END get_profile_start_day;
--
  /***********************************************************************************
   * Procedure Name   : get_start_end_day
   * Description      : A-1-4 年度開始日・終了日を取得する
   ***********************************************************************************/
  PROCEDURE get_start_end_day(
    iv_forecast_year IN  VARCHAR2,            -- 年度
    ov_errbuf        OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode       OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg        OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_start_end_day'; -- プログラム名
--
--##############################  固定ローカル変数宣言部 START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--#####################################  固定部 END   #############################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--################################  固定ステータス初期化部 START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  固定部 END   #############################################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- 入力年度＋年度開始日付で対象年度開始年月日を算出する
    gv_start_yyyymmdd := iv_forecast_year || '/' || gv_start_mmdd;
    gd_start_yyyymmdd := FND_DATE.STRING_TO_DATE(gv_start_yyyymmdd,'YYYY/MM/DD');
--
    -- 対象年度開始年月日がYYYYMMDDの日付型ではない場合はエラーとする
    IF (gd_start_yyyymmdd IS NULL) THEN
      RAISE global_api_expt;
    END IF;
--
    -- 対象年度開始年月日から対象年度終了年月日を算出する(+12ヶ月-1日)
    gd_end_yyyymmdd := ADD_MONTHS(gd_start_yyyymmdd,12)-1;
--
    --==============================================================
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
--#################################  固定例外処理部 START   #######################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   #############################################
--
  END get_start_end_day;
--
  /**********************************************************************************
   * Procedure Name   : get_keikaku_start_end_day
   * Description      : 計画商品対象開始・終了年月日取得(A-1-5)
   ***********************************************************************************/
  PROCEDURE get_keikaku_start_end_day(
    ov_errbuf             OUT NOCOPY VARCHAR2,  -- エラー・メッセージ            --# 固定 #
    ov_retcode            OUT NOCOPY VARCHAR2,  -- リターン・コード              --# 固定 #
    ov_errmsg             OUT NOCOPY VARCHAR2)  -- ユーザー・エラー・メッセージ  --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_keikaku_start_end_day'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    lv_keikaku_start_date    VARCHAR2(10);
    lv_keikaku_day           VARCHAR2(10);
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- クイックコード情報から計画商品対象期間を取得する
    SELECT xlv_v.meaning,          -- 内容
           xlv_v.description       -- 摘要
    INTO   lv_keikaku_start_date,  -- 開始日
           lv_keikaku_day          -- 日数
    FROM   xxcmn_lookup_values_v xlv_v
    WHERE  xlv_v.lookup_type = gv_cons_type_keikaku_term
      AND  ROWNUM            = 1;
--
    -- 計画商品開始日
    gd_keikaku_start_date := FND_DATE.STRING_TO_DATE(lv_keikaku_start_date,'YYYY/MM/DD');
--
    -- 不正な日付が登録されていたらエラー
    IF ( gd_keikaku_start_date IS NULL ) THEN
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_cmn   -- 'XXCMN'
                                                    ,gv_msg_10a_072   -- 日付不正エラー
                                                    ,gv_tkn_item      -- トークン'ITEM'
                                                                      -- '計画商品対象期間'
                                                    ,gv_cons_keikaku_term
                                                    ,gv_tkn_value      -- トークン'VALUE'
                                                    ,lv_keikaku_start_date)  -- 開始日
                                                    ,1
                                                    ,5000);
      RAISE global_api_expt;
    END IF;
--
    -- 計画商品開始日に日数をプラスして計画商品終了日を算出する
    gd_keikaku_end_date := gd_keikaku_start_date + TO_NUMBER(lv_keikaku_day);
--
  EXCEPTION
    -- クイックコードを取得できなかった場合
    WHEN NO_DATA_FOUND THEN
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_cmn   -- 'XXCMN'
                                                    ,gv_msg_10a_060   -- クイックコード取得エラー
                                                    ,gv_tkn_lup_type  -- トークン'LOOKUP_TYPE'
                                                    ,gv_cons_type_keikaku_term -- 計画商品対象期間
                                                    ,gv_tkn_meaning   -- トークン'MEANING'
                                                    ,gv_cons_keikaku_term)     -- 計画商品対象期間
                                                    ,1
                                                    ,5000);
      -- *** 任意で例外処理を記述する ****
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;                                            --# 任意 #
--
    -- TO_NUMBER()で変換できなかった場合
    WHEN VALUE_ERROR THEN
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_cmn   -- 'XXCMN'
                                                    ,gv_msg_10a_072   -- 日付不正エラー
                                                    ,gv_tkn_item      -- トークン'ITEM'
                                                    ,gv_cons_days     -- '日数'
                                                    ,gv_tkn_value     -- トークン'VALUE'
                                                    ,lv_keikaku_day)  -- 日数
                                                    ,1
                                                    ,5000);
      -- *** 任意で例外処理を記述する ****
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;                                            --# 任意 #
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_keikaku_start_end_day;
--
  /**********************************************************************************
   * Procedure Name   : get_dept_inf
   * Description      : 部署情報の取得(A-1-6)
   ***********************************************************************************/
  PROCEDURE get_dept_inf(
    ov_errbuf             OUT NOCOPY VARCHAR2,  -- エラー・メッセージ           --# 固定 #
    ov_retcode            OUT NOCOPY VARCHAR2,  -- リターン・コード             --# 固定 #
    ov_errmsg             OUT NOCOPY VARCHAR2)  -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_dept_inf'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    ln_login_user  NUMBER;  -- ログインユーザ
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- ログインユーザの取得
    ln_login_user := FND_GLOBAL.USER_ID;
--
    -- 担当部署の取得
    gv_location_short_name := xxcmn_common_pkg.get_user_dept(
                                ln_login_user);                           -- ログインユーザ
--
    -- エラーの場合
    IF (gv_location_short_name IS NULL) THEN
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_inv       -- 'XXINV'
                                                    ,gv_msg_10a_025       -- 部署コード取得エラー
                                                    ,gv_tkn_user          -- トークン'USER'
                                                    ,ln_login_user)       -- ログインユーザー
                                                    ,1
                                                    ,5000);
      RAISE parameter_expt;
    END IF;
--
    SELECT hla.location_code
    INTO  gv_location_code
    FROM  hr_locations_all hla
         ,FND_USER fu
         ,PER_ALL_PEOPLE_F papf
         ,PER_ALL_ASSIGNMENTS_F paaf
    WHERE fu.user_id       = ln_login_user
      AND fu.EMPLOYEE_ID   = papf.PERSON_ID
      AND papf.PERSON_ID   = paaf.PERSON_ID
      AND paaf.LOCATION_ID = hla.LOCATION_ID
      AND SYSDATE BETWEEN papf.effective_start_date AND NVL(papf.effective_end_date,SYSDATE)
      ;
--
  EXCEPTION
    WHEN parameter_expt THEN                           --*** パラメータ例外 ***
      -- *** 任意で例外処理を記述する ****
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;                                            --# 任意 #
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_dept_inf;
--
  /**********************************************************************************
   * Procedure Name   : if_data_null_check
   * Description      : A-*-0 インターフェースデータ項目必須チェック
   ***********************************************************************************/
  PROCEDURE if_data_null_check(
    iv_forecast_designator  IN  VARCHAR2,        -- Forecast分類
    ov_errbuf               OUT NOCOPY VARCHAR2, -- エラー・メッセージ           --# 固定 #
    ov_retcode              OUT NOCOPY VARCHAR2, -- リターン・コード             --# 固定 #
    ov_errmsg               OUT NOCOPY VARCHAR2) -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'if_data_null_check'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    ln_target_cnt  NUMBER;  -- 重複している件数
    ln_loop_cnt    NUMBER;  -- ループカウンタ
--
    -- *** ローカル・カーソル ***
--
    -- 引取計画用 ############################################################################
    -- インターフェーステーブル重複データ抽出
    CURSOR forecast_if_cur1
    IS
      SELECT /*+ INDEX( mfi xxinv_mfi_n01 ) */               -- 2008/11/11 統合指摘#589 Add
             mfi.forecast_if_id,
             mfi.forecast_designator,
             mfi.location_code,
             mfi.base_code,
             mfi.dept_code,
             mfi.item_code,
             mfi.forecast_date,
             mfi.forecast_end_date,
             mfi.case_quantity,
             mfi.indivi_quantity,
             mfi.amount,
             mfi.created_by,
             mfi.creation_date,
             mfi.last_updated_by,
             mfi.last_update_date,
             mfi.last_update_login,
             mfi.request_id,
             mfi.program_application_id,
             mfi.program_id,
             mfi.program_update_date
      FROM   xxinv_mrp_forecast_interface  mfi
      WHERE  (mfi.location_code      IS NULL                    -- 出荷元倉庫
        OR    mfi.base_code          IS NULL)                   -- 拠点
        AND  (mfi.forecast_designator = iv_forecast_designator  -- Forecast分類
        AND   mfi.created_by          = gn_created_by);         -- 作成者=ログインユーザ
    -- *** ローカル・レコード ***
    TYPE lr_forecast_if_rec1 IS RECORD(
      forecast_if_id         xxinv_mrp_forecast_interface.forecast_if_id%TYPE,
      forecast_designator    xxinv_mrp_forecast_interface.forecast_designator%TYPE,
      location_code          xxinv_mrp_forecast_interface.location_code%TYPE,
      base_code              xxinv_mrp_forecast_interface.base_code%TYPE,
      dept_code              xxinv_mrp_forecast_interface.dept_code%TYPE,
      item_code              xxinv_mrp_forecast_interface.item_code%TYPE,
      forecast_date          xxinv_mrp_forecast_interface.forecast_date%TYPE,
      forecast_end_date      xxinv_mrp_forecast_interface.forecast_end_date%TYPE,
      case_quantity          xxinv_mrp_forecast_interface.case_quantity%TYPE,
      indivi_quantity        xxinv_mrp_forecast_interface.indivi_quantity%TYPE,
      amount                 xxinv_mrp_forecast_interface.amount%TYPE,
      created_by             xxinv_mrp_forecast_interface.created_by%TYPE,
      creation_date          xxinv_mrp_forecast_interface.creation_date%TYPE,
      last_updated_by        xxinv_mrp_forecast_interface.last_updated_by%TYPE,
      last_update_date       xxinv_mrp_forecast_interface.last_update_date%TYPE,
      last_update_login      xxinv_mrp_forecast_interface.last_update_login%TYPE,
      request_id             xxinv_mrp_forecast_interface.request_id%TYPE,
      program_application_id xxinv_mrp_forecast_interface.program_application_id%TYPE,
      program_id             xxinv_mrp_forecast_interface.program_id%TYPE,
      program_update_date    xxinv_mrp_forecast_interface.program_update_date%TYPE
    );
    -- ログ出力するためのデータを格納する結合配列
    TYPE forecast_tbl1 IS TABLE OF lr_forecast_if_rec1 INDEX BY PLS_INTEGER;
    lt_if_data1    forecast_tbl1;
--
    -- 計画商品用 ############################################################################
    -- インターフェーステーブル重複データ抽出
    CURSOR forecast_if_cur2
    IS
      SELECT mfi.forecast_if_id,
             mfi.forecast_designator,
             mfi.location_code,
             mfi.base_code,
             mfi.dept_code,
             mfi.item_code,
             mfi.forecast_date,
             mfi.forecast_end_date,
             mfi.case_quantity,
             mfi.indivi_quantity,
             mfi.amount,
             mfi.created_by,
             mfi.creation_date,
             mfi.last_updated_by,
             mfi.last_update_date,
             mfi.last_update_login,
             mfi.request_id,
             mfi.program_application_id,
             mfi.program_id,
             mfi.program_update_date
      FROM   xxinv_mrp_forecast_interface  mfi
      WHERE  (mfi.location_code      IS NULL                    -- 出荷元倉庫
        OR    mfi.base_code          IS NULL)                   -- 拠点
        AND  (mfi.forecast_designator = iv_forecast_designator  -- Forecast分類
        AND   mfi.created_by          = gn_created_by);         -- 作成者=ログインユーザ
    -- *** ローカル・レコード ***
    TYPE lr_forecast_if_rec2 IS RECORD(
      forecast_if_id         xxinv_mrp_forecast_interface.forecast_if_id%TYPE,
      forecast_designator    xxinv_mrp_forecast_interface.forecast_designator%TYPE,
      location_code          xxinv_mrp_forecast_interface.location_code%TYPE,
      base_code              xxinv_mrp_forecast_interface.base_code%TYPE,
      dept_code              xxinv_mrp_forecast_interface.dept_code%TYPE,
      item_code              xxinv_mrp_forecast_interface.item_code%TYPE,
      forecast_date          xxinv_mrp_forecast_interface.forecast_date%TYPE,
      forecast_end_date      xxinv_mrp_forecast_interface.forecast_end_date%TYPE,
      case_quantity          xxinv_mrp_forecast_interface.case_quantity%TYPE,
      indivi_quantity        xxinv_mrp_forecast_interface.indivi_quantity%TYPE,
      amount                 xxinv_mrp_forecast_interface.amount%TYPE,
      created_by             xxinv_mrp_forecast_interface.created_by%TYPE,
      creation_date          xxinv_mrp_forecast_interface.creation_date%TYPE,
      last_updated_by        xxinv_mrp_forecast_interface.last_updated_by%TYPE,
      last_update_date       xxinv_mrp_forecast_interface.last_update_date%TYPE,
      last_update_login      xxinv_mrp_forecast_interface.last_update_login%TYPE,
      request_id             xxinv_mrp_forecast_interface.request_id%TYPE,
      program_application_id xxinv_mrp_forecast_interface.program_application_id%TYPE,
      program_id             xxinv_mrp_forecast_interface.program_id%TYPE,
      program_update_date    xxinv_mrp_forecast_interface.program_update_date%TYPE
    );
    -- ログ出力するためのデータを格納する結合配列
    TYPE forecast_tbl2 IS TABLE OF lr_forecast_if_rec2 INDEX BY PLS_INTEGER;
    lt_if_data2    forecast_tbl2;
--
    -- 出荷数制限A用 ###########################################################################
    -- インターフェーステーブル重複データ抽出
    CURSOR forecast_if_cur3
    IS
      SELECT mfi.forecast_if_id,
             mfi.forecast_designator,
             mfi.location_code,
             mfi.base_code,
             mfi.dept_code,
             mfi.item_code,
             mfi.forecast_date,
             mfi.forecast_end_date,
             mfi.case_quantity,
             mfi.indivi_quantity,
             mfi.amount,
             mfi.created_by,
             mfi.creation_date,
             mfi.last_updated_by,
             mfi.last_update_date,
             mfi.last_update_login,
             mfi.request_id,
             mfi.program_application_id,
             mfi.program_id,
             mfi.program_update_date
      FROM   xxinv_mrp_forecast_interface  mfi
      WHERE   mfi.base_code          IS NULL                    -- 拠点
        AND  (mfi.forecast_designator = iv_forecast_designator  -- Forecast分類
        AND   mfi.created_by          = gn_created_by);         -- 作成者=ログインユーザ
    -- *** ローカル・レコード ***
    TYPE lr_forecast_if_rec3 IS RECORD(
      forecast_if_id         xxinv_mrp_forecast_interface.forecast_if_id%TYPE,
      forecast_designator    xxinv_mrp_forecast_interface.forecast_designator%TYPE,
      location_code          xxinv_mrp_forecast_interface.location_code%TYPE,
      base_code              xxinv_mrp_forecast_interface.base_code%TYPE,
      dept_code              xxinv_mrp_forecast_interface.dept_code%TYPE,
      item_code              xxinv_mrp_forecast_interface.item_code%TYPE,
      forecast_date          xxinv_mrp_forecast_interface.forecast_date%TYPE,
      forecast_end_date      xxinv_mrp_forecast_interface.forecast_end_date%TYPE,
      case_quantity          xxinv_mrp_forecast_interface.case_quantity%TYPE,
      indivi_quantity        xxinv_mrp_forecast_interface.indivi_quantity%TYPE,
      amount                 xxinv_mrp_forecast_interface.amount%TYPE,
      created_by             xxinv_mrp_forecast_interface.created_by%TYPE,
      creation_date          xxinv_mrp_forecast_interface.creation_date%TYPE,
      last_updated_by        xxinv_mrp_forecast_interface.last_updated_by%TYPE,
      last_update_date       xxinv_mrp_forecast_interface.last_update_date%TYPE,
      last_update_login      xxinv_mrp_forecast_interface.last_update_login%TYPE,
      request_id             xxinv_mrp_forecast_interface.request_id%TYPE,
      program_application_id xxinv_mrp_forecast_interface.program_application_id%TYPE,
      program_id             xxinv_mrp_forecast_interface.program_id%TYPE,
      program_update_date    xxinv_mrp_forecast_interface.program_update_date%TYPE
    );
    -- ログ出力するためのデータを格納する結合配列
    TYPE forecast_tbl3 IS TABLE OF lr_forecast_if_rec3 INDEX BY PLS_INTEGER;
    lt_if_data3    forecast_tbl3;
--
    -- 出荷数制限B用 ###########################################################################
    -- インターフェーステーブル重複データ抽出
    CURSOR forecast_if_cur4
    IS
      SELECT mfi.forecast_if_id,
             mfi.forecast_designator,
             mfi.location_code,
             mfi.base_code,
             mfi.dept_code,
             mfi.item_code,
             mfi.forecast_date,
             mfi.forecast_end_date,
             mfi.case_quantity,
             mfi.indivi_quantity,
             mfi.amount,
             mfi.created_by,
             mfi.creation_date,
             mfi.last_updated_by,
             mfi.last_update_date,
             mfi.last_update_login,
             mfi.request_id,
             mfi.program_application_id,
             mfi.program_id,
             mfi.program_update_date
      FROM   xxinv_mrp_forecast_interface  mfi
      WHERE  (mfi.location_code      IS NULL                    -- 出荷元倉庫
        OR    mfi.dept_code          IS NULL)                   -- 取込部署
        AND  (mfi.forecast_designator = iv_forecast_designator  -- Forecast分類
        AND   mfi.created_by          = gn_created_by);         -- 作成者=ログインユーザ
    -- *** ローカル・レコード ***
    TYPE lr_forecast_if_rec4 IS RECORD(
      forecast_if_id         xxinv_mrp_forecast_interface.forecast_if_id%TYPE,
      forecast_designator    xxinv_mrp_forecast_interface.forecast_designator%TYPE,
      location_code          xxinv_mrp_forecast_interface.location_code%TYPE,
      base_code              xxinv_mrp_forecast_interface.base_code%TYPE,
      dept_code              xxinv_mrp_forecast_interface.dept_code%TYPE,
      item_code              xxinv_mrp_forecast_interface.item_code%TYPE,
      forecast_date          xxinv_mrp_forecast_interface.forecast_date%TYPE,
      forecast_end_date      xxinv_mrp_forecast_interface.forecast_end_date%TYPE,
      case_quantity          xxinv_mrp_forecast_interface.case_quantity%TYPE,
      indivi_quantity        xxinv_mrp_forecast_interface.indivi_quantity%TYPE,
      amount                 xxinv_mrp_forecast_interface.amount%TYPE,
      created_by             xxinv_mrp_forecast_interface.created_by%TYPE,
      creation_date          xxinv_mrp_forecast_interface.creation_date%TYPE,
      last_updated_by        xxinv_mrp_forecast_interface.last_updated_by%TYPE,
      last_update_date       xxinv_mrp_forecast_interface.last_update_date%TYPE,
      last_update_login      xxinv_mrp_forecast_interface.last_update_login%TYPE,
      request_id             xxinv_mrp_forecast_interface.request_id%TYPE,
      program_application_id xxinv_mrp_forecast_interface.program_application_id%TYPE,
      program_id             xxinv_mrp_forecast_interface.program_id%TYPE,
      program_update_date    xxinv_mrp_forecast_interface.program_update_date%TYPE
    );
    -- ログ出力するためのデータを格納する結合配列
    TYPE forecast_tbl4 IS TABLE OF lr_forecast_if_rec4 INDEX BY PLS_INTEGER;
    lt_if_data4    forecast_tbl4;
--
    -- 販売計画用 ###########################################################################
    -- インターフェーステーブル重複データ抽出
    CURSOR forecast_if_cur5
    IS
      SELECT /*+ INDEX( mfi xxinv_mfi_n01 ) */              -- 2008/11/11 統合指摘#589 Add
             mfi.forecast_if_id,
             mfi.forecast_designator,
             mfi.location_code,
             mfi.base_code,
             mfi.dept_code,
             mfi.item_code,
             mfi.forecast_date,
             mfi.forecast_end_date,
             mfi.case_quantity,
             mfi.indivi_quantity,
             mfi.amount,
             mfi.created_by,
             mfi.creation_date,
             mfi.last_updated_by,
             mfi.last_update_date,
             mfi.last_update_login,
             mfi.request_id,
             mfi.program_application_id,
             mfi.program_id,
             mfi.program_update_date
      FROM   xxinv_mrp_forecast_interface  mfi
      WHERE  (mfi.base_code          IS NULL                    -- 拠点
        OR    mfi.amount             IS NULL)                   -- 金額
        AND  (mfi.forecast_designator = iv_forecast_designator  -- Forecast分類
        AND   mfi.created_by          = gn_created_by);         -- 作成者=ログインユーザ
    -- *** ローカル・レコード ***
    TYPE lr_forecast_if_rec5 IS RECORD(
      forecast_if_id         xxinv_mrp_forecast_interface.forecast_if_id%TYPE,
      forecast_designator    xxinv_mrp_forecast_interface.forecast_designator%TYPE,
      location_code          xxinv_mrp_forecast_interface.location_code%TYPE,
      base_code              xxinv_mrp_forecast_interface.base_code%TYPE,
      dept_code              xxinv_mrp_forecast_interface.dept_code%TYPE,
      item_code              xxinv_mrp_forecast_interface.item_code%TYPE,
      forecast_date          xxinv_mrp_forecast_interface.forecast_date%TYPE,
      forecast_end_date      xxinv_mrp_forecast_interface.forecast_end_date%TYPE,
      case_quantity          xxinv_mrp_forecast_interface.case_quantity%TYPE,
      indivi_quantity        xxinv_mrp_forecast_interface.indivi_quantity%TYPE,
      amount                 xxinv_mrp_forecast_interface.amount%TYPE,
      created_by             xxinv_mrp_forecast_interface.created_by%TYPE,
      creation_date          xxinv_mrp_forecast_interface.creation_date%TYPE,
      last_updated_by        xxinv_mrp_forecast_interface.last_updated_by%TYPE,
      last_update_date       xxinv_mrp_forecast_interface.last_update_date%TYPE,
      last_update_login      xxinv_mrp_forecast_interface.last_update_login%TYPE,
      request_id             xxinv_mrp_forecast_interface.request_id%TYPE,
      program_application_id xxinv_mrp_forecast_interface.program_application_id%TYPE,
      program_id             xxinv_mrp_forecast_interface.program_id%TYPE,
      program_update_date    xxinv_mrp_forecast_interface.program_update_date%TYPE
    );
    -- ログ出力するためのデータを格納する結合配列
    TYPE forecast_tbl5 IS TABLE OF lr_forecast_if_rec5 INDEX BY PLS_INTEGER;
    lt_if_data5    forecast_tbl5;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- Forecast分類で分岐して各項目の必須チェックを行う
    -- 引取計画 ############################################################################
    IF (iv_forecast_designator = gv_cons_fc_type_hikitori) THEN
      -- カーソルオープン
      OPEN forecast_if_cur1;
--
      -- データの一括取得
      FETCH forecast_if_cur1 BULK COLLECT INTO lt_if_data1;
--
      -- 処理件数のセット
      ln_target_cnt := lt_if_data1.COUNT;
--
      -- カーソルクローズ
      CLOSE forecast_if_cur1;
--
      -- NULLデータありの場合はデータをログに出力する
      IF (ln_target_cnt > 0) THEN
        <<null_data_loop1>>
        FOR ln_loop_cnt IN 1..ln_target_cnt LOOP
          -- エラーデータを合体して出力
          lv_errmsg := lt_if_data1(ln_loop_cnt).forecast_if_id         || gv_msg_pnt ||
                       lt_if_data1(ln_loop_cnt).forecast_designator    || gv_msg_pnt ||
                       lt_if_data1(ln_loop_cnt).location_code          || gv_msg_pnt ||
                       lt_if_data1(ln_loop_cnt).base_code              || gv_msg_pnt ||
                       lt_if_data1(ln_loop_cnt).dept_code              || gv_msg_pnt ||
                       lt_if_data1(ln_loop_cnt).item_code              || gv_msg_pnt ||
                       lt_if_data1(ln_loop_cnt).forecast_date          || gv_msg_pnt ||
                       lt_if_data1(ln_loop_cnt).forecast_end_date      || gv_msg_pnt ||
                       lt_if_data1(ln_loop_cnt).case_quantity          || gv_msg_pnt ||
                       lt_if_data1(ln_loop_cnt).indivi_quantity        || gv_msg_pnt ||
                       lt_if_data1(ln_loop_cnt).amount                 || gv_msg_pnt ||
                       lt_if_data1(ln_loop_cnt).created_by             || gv_msg_pnt ||
                       lt_if_data1(ln_loop_cnt).creation_date          || gv_msg_pnt ||
                       lt_if_data1(ln_loop_cnt).last_updated_by        || gv_msg_pnt ||
                       lt_if_data1(ln_loop_cnt).last_update_date       || gv_msg_pnt ||
                       lt_if_data1(ln_loop_cnt).last_update_login      || gv_msg_pnt ||
                       lt_if_data1(ln_loop_cnt).request_id             || gv_msg_pnt ||
                       lt_if_data1(ln_loop_cnt).program_application_id || gv_msg_pnt ||
                       lt_if_data1(ln_loop_cnt).program_id             || gv_msg_pnt ||
                       lt_if_data1(ln_loop_cnt).program_update_date;
          FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
          lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_inv     -- 'XXINV'
                                                        ,gv_msg_10a_067)
                                                          -- 引取計画必須チェックエラー
                                                        ,1
                                                        ,5000);
          FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errmsg);
        END LOOP null_data_loop1;
        RAISE null_expt;
      END IF;
--
    -- 計画商品 ############################################################################
    ELSIF (iv_forecast_designator = gv_cons_fc_type_keikaku) THEN
      -- カーソルオープン
      OPEN forecast_if_cur2;
--
      -- データの一括取得
      FETCH forecast_if_cur2 BULK COLLECT INTO lt_if_data2;
--
      -- 処理件数のセット
      ln_target_cnt := lt_if_data2.COUNT;
--
      -- カーソルクローズ
      CLOSE forecast_if_cur2;
--
      -- NULLデータありの場合はデータをログに出力する
      IF (ln_target_cnt > 0) THEN
        <<null_data_loop2>>
        FOR ln_loop_cnt IN 1..ln_target_cnt LOOP
          lv_errmsg := lt_if_data2(ln_loop_cnt).forecast_if_id         || gv_msg_pnt ||
                       lt_if_data2(ln_loop_cnt).forecast_designator    || gv_msg_pnt ||
                       lt_if_data2(ln_loop_cnt).location_code          || gv_msg_pnt ||
                       lt_if_data2(ln_loop_cnt).base_code              || gv_msg_pnt ||
                       lt_if_data2(ln_loop_cnt).dept_code              || gv_msg_pnt ||
                       lt_if_data2(ln_loop_cnt).item_code              || gv_msg_pnt ||
                       lt_if_data2(ln_loop_cnt).forecast_date          || gv_msg_pnt ||
                       lt_if_data2(ln_loop_cnt).forecast_end_date      || gv_msg_pnt ||
                       lt_if_data2(ln_loop_cnt).case_quantity          || gv_msg_pnt ||
                       lt_if_data2(ln_loop_cnt).indivi_quantity        || gv_msg_pnt ||
                       lt_if_data2(ln_loop_cnt).amount                 || gv_msg_pnt ||
                       lt_if_data2(ln_loop_cnt).created_by             || gv_msg_pnt ||
                       lt_if_data2(ln_loop_cnt).creation_date          || gv_msg_pnt ||
                       lt_if_data2(ln_loop_cnt).last_updated_by        || gv_msg_pnt ||
                       lt_if_data2(ln_loop_cnt).last_update_date       || gv_msg_pnt ||
                       lt_if_data2(ln_loop_cnt).last_update_login      || gv_msg_pnt ||
                       lt_if_data2(ln_loop_cnt).request_id             || gv_msg_pnt ||
                       lt_if_data2(ln_loop_cnt).program_application_id || gv_msg_pnt ||
                       lt_if_data2(ln_loop_cnt).program_id             || gv_msg_pnt ||
                       lt_if_data2(ln_loop_cnt).program_update_date;
          FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
          lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_inv     -- 'XXINV'
                                                        ,gv_msg_10a_068)
                                                          -- 計画商品必須チェックエラー
                                                        ,1
                                                        ,5000);
          FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errmsg);
        END LOOP null_data_loop2;
        RAISE null_expt;
      END IF;
--
    -- 販売計画 ###########################################################################
    ELSIF (iv_forecast_designator = gv_cons_fc_type_hanbai) THEN
      -- カーソルオープン
      OPEN forecast_if_cur5;
--
      -- データの一括取得
      FETCH forecast_if_cur5 BULK COLLECT INTO lt_if_data5;
--
      -- 処理件数のセット
      ln_target_cnt := lt_if_data5.COUNT;
--
      -- カーソルクローズ
      CLOSE forecast_if_cur5;
--
      -- NULLデータありの場合はデータをログに出力する
      IF (ln_target_cnt > 0) THEN
        <<null_data_loop5>>
        FOR ln_loop_cnt IN 1..ln_target_cnt LOOP
          lv_errmsg := lt_if_data5(ln_loop_cnt).forecast_if_id         || gv_msg_pnt ||
                       lt_if_data5(ln_loop_cnt).forecast_designator    || gv_msg_pnt ||
                       lt_if_data5(ln_loop_cnt).location_code          || gv_msg_pnt ||
                       lt_if_data5(ln_loop_cnt).base_code              || gv_msg_pnt ||
                       lt_if_data5(ln_loop_cnt).dept_code              || gv_msg_pnt ||
                       lt_if_data5(ln_loop_cnt).item_code              || gv_msg_pnt ||
                       lt_if_data5(ln_loop_cnt).forecast_date          || gv_msg_pnt ||
                       lt_if_data5(ln_loop_cnt).forecast_end_date      || gv_msg_pnt ||
                       lt_if_data5(ln_loop_cnt).case_quantity          || gv_msg_pnt ||
                       lt_if_data5(ln_loop_cnt).indivi_quantity        || gv_msg_pnt ||
                       lt_if_data5(ln_loop_cnt).amount                 || gv_msg_pnt ||
                       lt_if_data5(ln_loop_cnt).created_by             || gv_msg_pnt ||
                       lt_if_data5(ln_loop_cnt).creation_date          || gv_msg_pnt ||
                       lt_if_data5(ln_loop_cnt).last_updated_by        || gv_msg_pnt ||
                       lt_if_data5(ln_loop_cnt).last_update_date       || gv_msg_pnt ||
                       lt_if_data5(ln_loop_cnt).last_update_login      || gv_msg_pnt ||
                       lt_if_data5(ln_loop_cnt).request_id             || gv_msg_pnt ||
                       lt_if_data5(ln_loop_cnt).program_application_id || gv_msg_pnt ||
                       lt_if_data5(ln_loop_cnt).program_id             || gv_msg_pnt ||
                       lt_if_data5(ln_loop_cnt).program_update_date;
          FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
          lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_inv     -- 'XXINV'
                                                        ,gv_msg_10a_071)
                                                          -- 販売計画必須チェックエラー
                                                        ,1
                                                        ,5000);
          FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errmsg);
        END LOOP null_data_loop5;
        RAISE null_expt;
      END IF;
--
    -- 出荷数制限A #########################################################################
    ELSIF (iv_forecast_designator = gv_cons_fc_type_seigen_a) THEN
      -- カーソルオープン
      OPEN forecast_if_cur3;
--
      -- データの一括取得
      FETCH forecast_if_cur3 BULK COLLECT INTO lt_if_data3;
--
      -- 処理件数のセット
      ln_target_cnt := lt_if_data3.COUNT;
--
      -- カーソルクローズ
      CLOSE forecast_if_cur3;
--
      -- NULLデータありの場合はデータをログに出力する
      IF (ln_target_cnt > 0) THEN
        <<null_data_loop3>>
        FOR ln_loop_cnt IN 1..ln_target_cnt LOOP
          lv_errmsg := lt_if_data3(ln_loop_cnt).forecast_if_id         || gv_msg_pnt ||
                       lt_if_data3(ln_loop_cnt).forecast_designator    || gv_msg_pnt ||
                       lt_if_data3(ln_loop_cnt).location_code          || gv_msg_pnt ||
                       lt_if_data3(ln_loop_cnt).base_code              || gv_msg_pnt ||
                       lt_if_data3(ln_loop_cnt).dept_code              || gv_msg_pnt ||
                       lt_if_data3(ln_loop_cnt).item_code              || gv_msg_pnt ||
                       lt_if_data3(ln_loop_cnt).forecast_date          || gv_msg_pnt ||
                       lt_if_data3(ln_loop_cnt).forecast_end_date      || gv_msg_pnt ||
                       lt_if_data3(ln_loop_cnt).case_quantity          || gv_msg_pnt ||
                       lt_if_data3(ln_loop_cnt).indivi_quantity        || gv_msg_pnt ||
                       lt_if_data3(ln_loop_cnt).amount                 || gv_msg_pnt ||
                       lt_if_data3(ln_loop_cnt).created_by             || gv_msg_pnt ||
                       lt_if_data3(ln_loop_cnt).creation_date          || gv_msg_pnt ||
                       lt_if_data3(ln_loop_cnt).last_updated_by        || gv_msg_pnt ||
                       lt_if_data3(ln_loop_cnt).last_update_date       || gv_msg_pnt ||
                       lt_if_data3(ln_loop_cnt).last_update_login      || gv_msg_pnt ||
                       lt_if_data3(ln_loop_cnt).request_id             || gv_msg_pnt ||
                       lt_if_data3(ln_loop_cnt).program_application_id || gv_msg_pnt ||
                       lt_if_data3(ln_loop_cnt).program_id             || gv_msg_pnt ||
                       lt_if_data3(ln_loop_cnt).program_update_date;
          FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
          lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_inv     -- 'XXINV'
                                                        ,gv_msg_10a_069)
                                                          -- 出荷数制限A必須チェックエラー
                                                        ,1
                                                        ,5000);
          FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errmsg);
        END LOOP null_data_loop3;
        RAISE null_expt;
      END IF;
--
    -- 出荷数制限B #######################################################################
    ELSIF (iv_forecast_designator = gv_cons_fc_type_seigen_b) THEN
      -- カーソルオープン
      OPEN forecast_if_cur4;
--
      -- データの一括取得
      FETCH forecast_if_cur4 BULK COLLECT INTO lt_if_data4;
--
      -- 処理件数のセット
      ln_target_cnt := lt_if_data4.COUNT;
--
      -- カーソルクローズ
      CLOSE forecast_if_cur4;
--
      -- NULLデータありの場合はデータをログに出力する
      IF (ln_target_cnt > 0) THEN
        <<null_data_loop4>>
        FOR ln_loop_cnt IN 1..ln_target_cnt LOOP
          lv_errmsg := lt_if_data4(ln_loop_cnt).forecast_if_id         || gv_msg_pnt ||
                       lt_if_data4(ln_loop_cnt).forecast_designator    || gv_msg_pnt ||
                       lt_if_data4(ln_loop_cnt).location_code          || gv_msg_pnt ||
                       lt_if_data4(ln_loop_cnt).base_code              || gv_msg_pnt ||
                       lt_if_data4(ln_loop_cnt).dept_code              || gv_msg_pnt ||
                       lt_if_data4(ln_loop_cnt).item_code              || gv_msg_pnt ||
                       lt_if_data4(ln_loop_cnt).forecast_date          || gv_msg_pnt ||
                       lt_if_data4(ln_loop_cnt).forecast_end_date      || gv_msg_pnt ||
                       lt_if_data4(ln_loop_cnt).case_quantity          || gv_msg_pnt ||
                       lt_if_data4(ln_loop_cnt).indivi_quantity        || gv_msg_pnt ||
                       lt_if_data4(ln_loop_cnt).amount                 || gv_msg_pnt ||
                       lt_if_data4(ln_loop_cnt).created_by             || gv_msg_pnt ||
                       lt_if_data4(ln_loop_cnt).creation_date          || gv_msg_pnt ||
                       lt_if_data4(ln_loop_cnt).last_updated_by        || gv_msg_pnt ||
                       lt_if_data4(ln_loop_cnt).last_update_date       || gv_msg_pnt ||
                       lt_if_data4(ln_loop_cnt).last_update_login      || gv_msg_pnt ||
                       lt_if_data4(ln_loop_cnt).request_id             || gv_msg_pnt ||
                       lt_if_data4(ln_loop_cnt).program_application_id || gv_msg_pnt ||
                       lt_if_data4(ln_loop_cnt).program_id             || gv_msg_pnt ||
                       lt_if_data4(ln_loop_cnt).program_update_date;
          FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
          lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_inv     -- 'XXINV'
                                                        ,gv_msg_10a_070)
                                                        -- 出荷数制限B必須チェックエラー
                                                        ,1
                                                        ,5000);
          FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errmsg);
        END LOOP null_data_loop4;
        RAISE null_expt;
      END IF;
    END IF;
--
  EXCEPTION
    WHEN null_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
      -- 2009/05/20 ADD START
      del_if_all(iv_forecast_designator,lv_errbuf,lv_retcode,lv_errmsg);
      FND_FILE.PUT_LINE(FND_FILE.LOG,'INTERFACE DATA DELETED');
      -- 2009/05/20 ADD END
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END if_data_null_check;
--
  /**********************************************************************************
   * Procedure Name   : get_hikitori_if_data
   * Description      : 引取計画インターフェースデータ取得(A-2-1)
   ***********************************************************************************/
  PROCEDURE get_hikitori_if_data(
    io_if_data            IN OUT NOCOPY forecast_tbl,
    ov_errbuf             OUT NOCOPY VARCHAR2,  -- エラー・メッセージ            --# 固定 #
    ov_retcode            OUT NOCOPY VARCHAR2,  -- リターン・コード              --# 固定 #
    ov_errmsg             OUT NOCOPY VARCHAR2)  -- ユーザー・エラー・メッセージ  --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_hikitori_if_data'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    lr_forecast_tbl  forecast_tbl;
--
    -- *** ローカル・カーソル ***
    -- 販売計画/引取計画インタ－フェーステーブルから引取計画データ抽出
    CURSOR forecast_if_cur
    IS
      SELECT /*+ INDEX( mfi xxinv_mfi_n01 ) */                      -- 2008/11/11 統合指摘#589 Add
             mfi.forecast_if_id         -- 取引ID
            ,mfi.forecast_designator    -- Forecast分類
            ,mfi.location_code          -- 出荷倉庫
            ,mfi.base_code              -- 拠点
            ,mfi.dept_code              -- 取込部署
            ,mfi.item_code              -- 品目
            ,mfi.forecast_date          -- 開始日付
            ,mfi.forecast_end_date      -- 終了日付
            ,mfi.case_quantity          -- ケース数量
            ,mfi.indivi_quantity        -- バラ数量
            ,mfi.amount                 -- 金額
      FROM  xxinv_mrp_forecast_interface  mfi
      WHERE mfi.forecast_designator = gv_cons_fc_type_hikitori        -- '引取計画'
        AND mfi.forecast_date BETWEEN gd_in_yyyymmdd_start AND gd_in_yyyymmdd_end   -- 入力年月
        AND mfi.created_by = gn_created_by                            -- ログインユーザ
      FOR UPDATE NOWAIT;
--
    -- *** ローカル・レコード ***
    lr_forecast_if_rec forecast_if_cur%ROWTYPE;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
-- 
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- 処理件数の初期化
    gn_target_cnt := 0;
--
    -- 販売計画/引取計画インタ－フェーステーブルから引取計画データ抽出
    OPEN forecast_if_cur;
--
    -- データの一括取得
    FETCH forecast_if_cur BULK COLLECT INTO io_if_data;
--
    -- 処理件数のセット
    gn_target_cnt := io_if_data.COUNT;
--
    -- カーソルクローズ
    CLOSE forecast_if_cur;
--
    -- データがなかった場合は終了ステータスを警告とし処理を中止する
    IF (gn_target_cnt = 0) THEN
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_cmn     -- 'XXCMN'
                                                     ,gv_msg_10a_043    -- 対象データなし
                                                     ,gv_tkn_table      -- トークン'TABLE'
                                                     ,gv_if_table_jp
                                                    -- 販売計画/引取計画インターフェーステーブル
                                                     ,gv_tkn_key        -- トークン'KEY'
                                                     ,gv_cons_fc_type_hikitori)  -- '引取計画'
                                                     ,1
                                                     ,5000);
--
-- 2009/04/13 v1.21 T.Yoshimoto Del Start メッセージ不具合(重複表示)
-- add start 1.11
--      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
-- add end 1.11
-- 2009/04/13 v1.21 T.Yoshimoto Del End メッセージ不具合(重複表示)
      RAISE no_data;
    END IF;
--
  EXCEPTION
    WHEN lock_expt THEN  -- ロックできなかった
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_cmn     -- 'XXCMN'
                                                     ,gv_msg_10a_044    -- テーブルロックエラー
                                                     ,gv_tkn_ng_table   -- トークン'NG_TABLE'
                                                     ,gv_if_table_jp)
                                                    -- 販売計画/引取計画インターフェーステーブル
                                                     ,1
                                                     ,5000);
      lv_errbuf := lv_errmsg ||gv_msg_part|| SQLERRM;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    WHEN no_data THEN                           --*** 対象データなし ***
      -- *** 任意で例外処理を記述する ****
      ov_errmsg  := lv_errmsg;                  --# 任意 #
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_warn;             -- 警告
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_hikitori_if_data;
--
  /**********************************************************************************
   * Procedure Name   : get_hanbai_if_data
   * Description      : 販売計画インターフェースデータ抽出(A-3-1)
   ***********************************************************************************/
  PROCEDURE get_hanbai_if_data(
    io_if_data            IN OUT NOCOPY forecast_tbl,
    ov_errbuf             OUT NOCOPY VARCHAR2,  -- エラー・メッセージ            --# 固定 #
    ov_retcode            OUT NOCOPY VARCHAR2,  -- リターン・コード              --# 固定 #
    ov_errmsg             OUT NOCOPY VARCHAR2)  -- ユーザー・エラー・メッセージ  --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_hanbai_if_data'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    lr_forecast_tbl  forecast_tbl;
--
    -- *** ローカル・カーソル ***
    -- 販売計画/引取計画インタ－フェーステーブルから販売計画データ抽出
    CURSOR forecast_if_cur
    IS
      SELECT /*+ INDEX( mfi xxinv_mfi_n01 ) */                  -- 2008/11/11 統合指摘#589 Add
             mfi.forecast_if_id         -- 取引ID
            ,mfi.forecast_designator    -- Forecast分類
            ,mfi.location_code          -- 出荷倉庫
            ,mfi.base_code              -- 拠点
            ,mfi.dept_code              -- 取込部署
            ,mfi.item_code              -- 品目
            ,mfi.forecast_date          -- 開始日付
            ,mfi.forecast_end_date      -- 終了日付
            ,mfi.case_quantity          -- ケース数量
            ,mfi.indivi_quantity        -- バラ数量
            ,mfi.amount                 -- 金額
      FROM  xxinv_mrp_forecast_interface  mfi
      WHERE mfi.forecast_designator = gv_cons_fc_type_hanbai      -- '販売計画'
        AND mfi.forecast_date      >= gd_start_yyyymmdd           -- 対象年度開始日
        AND mfi.forecast_date      <= gd_end_yyyymmdd             -- 対象年度終了日
-- 2009/04/08 v1.19 T.Yoshimoto Del Start 本番#1374
        --AND mfi.created_by          = gn_created_by               -- ログインユーザ
-- 2009/04/08 v1.19 T.Yoshimoto Del End 本番#1374
      FOR UPDATE NOWAIT;
--
    -- *** ローカル・レコード ***
    lr_forecast_if_rec forecast_if_cur%ROWTYPE;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- 処理件数の初期化
    gn_target_cnt := 0;
--
    -- 販売計画/引取計画インタ－フェーステーブルから引取計画データ抽出
    OPEN forecast_if_cur;
--
    -- データの一括取得
    FETCH forecast_if_cur BULK COLLECT INTO io_if_data;
--
    -- 処理件数のセット
    gn_target_cnt := io_if_data.COUNT;
--
    -- カーソルクローズ
    CLOSE forecast_if_cur;
--
    -- データがなかった場合は終了ステータスを警告とし処理を中止する
    IF (gn_target_cnt = 0) THEN
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_cmn     -- 'XXCMN'
                                                     ,gv_msg_10a_043    -- 対象データなし
                                                     ,gv_tkn_table      -- トークン'TABLE'
                                                     ,gv_if_table_jp
                                                    -- 販売計画/引取計画インターフェーステーブル
                                                     ,gv_tkn_key        -- トークン'KEY'
                                                     ,gv_cons_fc_type_hanbai) -- '販売計画'
                                                     ,1
                                                     ,5000);
--
-- 2009/04/13 v1.21 T.Yoshimoto Del Start メッセージ不具合(重複表示)
-- add start 1.11
--      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
-- add end 1.11
-- 2009/04/13 v1.21 T.Yoshimoto Del End メッセージ不具合(重複表示)
      RAISE no_data;
    END IF;
--
  EXCEPTION
    WHEN lock_expt THEN  -- テーブルロックできなかった
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_cmn     -- 'XXCMN'
                                                     ,gv_msg_10a_044    -- テーブルロックエラー
                                                     ,gv_tkn_ng_table   -- トークン'NG_TABLE'
                                                     ,gv_if_table_jp)
                                                    -- 販売計画/引取計画インターフェーステーブル
                                                     ,1
                                                     ,5000);
      lv_errbuf := lv_errmsg ||gv_msg_part|| SQLERRM;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    WHEN no_data THEN                           --*** 対象データなし ***
      -- *** 任意で例外処理を記述する ****
      ov_errmsg  := lv_errmsg;                  --# 任意 #
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_warn;             -- 警告
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_hanbai_if_data;
--
--
  /**********************************************************************************
   * Procedure Name   : get_keikaku_if_data
   * Description      : A-4-1 計画商品インターフェースデータ抽出
   ***********************************************************************************/
  PROCEDURE get_keikaku_if_data(
    io_if_data            IN OUT NOCOPY forecast_tbl,
    ov_errbuf             OUT NOCOPY VARCHAR2,  -- エラー・メッセージ            --# 固定 #
    ov_retcode            OUT NOCOPY VARCHAR2,  -- リターン・コード              --# 固定 #
    ov_errmsg             OUT NOCOPY VARCHAR2)  -- ユーザー・エラー・メッセージ  --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_keikaku_if_data'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    lr_forecast_tbl  forecast_tbl;
--
    -- *** ローカル・カーソル ***
    -- 販売計画/引取計画インタ－フェーステーブルから計画商品データ抽出
    CURSOR forecast_if_cur
    IS
      SELECT mfi.forecast_if_id         -- 取引ID
            ,mfi.forecast_designator    -- Forecast分類
            ,mfi.location_code          -- 出荷倉庫
            ,mfi.base_code              -- 拠点
            ,mfi.dept_code              -- 取込部署
            ,mfi.item_code              -- 品目
            ,mfi.forecast_date          -- 開始日付
            ,mfi.forecast_end_date      -- 終了日付
            ,mfi.case_quantity          -- ケース数量
            ,mfi.indivi_quantity        -- バラ数量
            ,mfi.amount                 -- 金額
      FROM  xxinv_mrp_forecast_interface  mfi
      WHERE mfi.forecast_designator = gv_cons_fc_type_keikaku        -- '計画商品'
        AND mfi.created_by          = gn_created_by                  -- ログインユーザ
      FOR UPDATE NOWAIT;
--
    -- *** ローカル・レコード ***
    lr_forecast_if_rec forecast_if_cur%ROWTYPE;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- 処理件数の初期化
    gn_target_cnt := 0;
--
    -- 販売計画/引取計画インタ－フェーステーブルから引取計画データ抽出
    OPEN forecast_if_cur;
--
    -- データの一括取得
    FETCH forecast_if_cur BULK COLLECT INTO io_if_data;
--
    -- 処理件数のセット
    gn_target_cnt := io_if_data.COUNT;
--
    -- カーソルクローズ
    CLOSE forecast_if_cur;
--
    -- データがなかった場合は終了ステータスを警告とし処理を中止する
    IF (gn_target_cnt = 0) THEN
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_cmn     -- 'XXCMN'
                                                     ,gv_msg_10a_043    -- 対象データなし
                                                     ,gv_tkn_table      -- トークン'TABLE'
                                                     ,gv_if_table_jp
                                                    -- 販売計画/引取計画インターフェーステーブル
                                                     ,gv_tkn_key        -- トークン'KEY'
                                                     ,gv_cons_fc_type_keikaku)  -- '計画商品'
                                                     ,1
                                                     ,5000);
--
-- 2009/04/13 v1.21 T.Yoshimoto Del Start メッセージ不具合(重複表示)
-- add start 1.11
--      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
-- add end 1.11
-- 2009/04/13 v1.21 T.Yoshimoto Del Del メッセージ不具合(重複表示)
      RAISE no_data;
    END IF;
--
  EXCEPTION
    WHEN lock_expt THEN  -- テーブルロックできなかった
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_cmn     -- 'XXCMN'
                                                     ,gv_msg_10a_044    -- テーブルロックエラー
                                                     ,gv_tkn_ng_table   -- トークン'NG_TABLE'
                                                     ,gv_if_table_jp)
                                                    -- 販売計画/引取計画インターフェーステーブル
                                                     ,1
                                                     ,5000);
      lv_errbuf := lv_errmsg ||gv_msg_part|| SQLERRM;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    WHEN no_data THEN                           --*** 対象データなし ***
      -- *** 任意で例外処理を記述する ****
      ov_errmsg  := lv_errmsg;                  --# 任意 #
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_warn;             -- 警告
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_keikaku_if_data;
--
  /**********************************************************************************
   * Procedure Name   : get_seigen_a_if_data
   * Description      : A-5-1 出荷数制限Aインターフェースデータ抽出
   ***********************************************************************************/
  PROCEDURE get_seigen_a_if_data(
    io_if_data            IN OUT NOCOPY forecast_tbl,
    ov_errbuf             OUT NOCOPY VARCHAR2,  -- エラー・メッセージ            --# 固定 #
    ov_retcode            OUT NOCOPY VARCHAR2,  -- リターン・コード              --# 固定 #
    ov_errmsg             OUT NOCOPY VARCHAR2)  -- ユーザー・エラー・メッセージ  --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_seigen_a_if_data'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
--    lr_forecast_tbl  forecast_tbl;
--
    -- *** ローカル・カーソル ***
    -- 販売計画/引取計画インタ－フェーステーブルから出荷数制限Aデータ抽出
    -- 品目＆拠点あり
    CURSOR forecast_if_cur_i_b
    IS
      SELECT mfi.forecast_if_id         -- 取引ID
            ,mfi.forecast_designator    -- Forecast分類
            ,mfi.location_code          -- 出荷倉庫
            ,mfi.base_code              -- 拠点
            ,mfi.dept_code              -- 取込部署
            ,mfi.item_code              -- 品目
            ,mfi.forecast_date          -- 開始日付
            ,mfi.forecast_end_date      -- 終了日付
            ,mfi.case_quantity          -- ケース数量
            ,mfi.indivi_quantity        -- バラ数量
            ,mfi.amount                 -- 金額
      FROM  xxinv_mrp_forecast_interface  mfi
      WHERE mfi.forecast_designator = gv_cons_fc_type_seigen_a     -- '出荷数制限A'
--        AND mfi.forecast_date     = to_date(gv_in_start_date,'YYYY/MM/DD')-- 入力パラメータ開始日付
--        AND mfi.forecast_end_date = to_date(gv_in_end_date,'YYYY/MM/DD')-- 入力パラメータ終了日付
        AND mfi.forecast_date     = to_date(gv_in_start_date,'YYYY/MM/DD')-- 入力パラメータ開始日付
        AND mfi.forecast_end_date   = to_date(gv_in_end_date,'YYYY/MM/DD')-- 入力パラメータ終了日付
        AND mfi.item_code           = gv_in_item_code              -- 入力パラメータ品目
        AND mfi.base_code           = gv_in_base_code              -- 入力パラメータ拠点
        AND mfi.created_by          = gn_created_by                -- ログインユーザ
      FOR UPDATE NOWAIT;
    -- 品目のみあり
    CURSOR forecast_if_cur_i
    IS
      SELECT mfi.forecast_if_id         -- 取引ID
            ,mfi.forecast_designator    -- Forecast分類
            ,mfi.location_code          -- 出荷倉庫
            ,mfi.base_code              -- 拠点
            ,mfi.dept_code              -- 取込部署
            ,mfi.item_code              -- 品目
            ,mfi.forecast_date          -- 開始日付
            ,mfi.forecast_end_date      -- 終了日付
            ,mfi.case_quantity          -- ケース数量
            ,mfi.indivi_quantity        -- バラ数量
            ,mfi.amount                 -- 金額
      FROM  xxinv_mrp_forecast_interface  mfi
      WHERE mfi.forecast_designator = gv_cons_fc_type_seigen_a     -- '出荷数制限A'
        AND mfi.forecast_date     = to_date(gv_in_start_date,'YYYY/MM/DD')-- 入力パラメータ開始日付
        AND mfi.forecast_end_date   = to_date(gv_in_end_date,'YYYY/MM/DD')-- 入力パラメータ終了日付
        AND mfi.item_code           = gv_in_item_code              -- 入力パラメータ品目
        AND mfi.created_by          = gn_created_by                -- ログインユーザ
      FOR UPDATE NOWAIT;
    -- 拠点のみあり
    CURSOR forecast_if_cur_b
    IS
      SELECT mfi.forecast_if_id         -- 取引ID
            ,mfi.forecast_designator    -- Forecast分類
            ,mfi.location_code          -- 出荷倉庫
            ,mfi.base_code              -- 拠点
            ,mfi.dept_code              -- 取込部署
            ,mfi.item_code              -- 品目
            ,mfi.forecast_date          -- 開始日付
            ,mfi.forecast_end_date      -- 終了日付
            ,mfi.case_quantity          -- ケース数量
            ,mfi.indivi_quantity        -- バラ数量
            ,mfi.amount                 -- 金額
      FROM  xxinv_mrp_forecast_interface  mfi
      WHERE mfi.forecast_designator = gv_cons_fc_type_seigen_a     -- '出荷数制限A'
        AND mfi.forecast_date     = to_date(gv_in_start_date,'YYYY/MM/DD')-- 入力パラメータ開始日付
        AND mfi.forecast_end_date   = to_date(gv_in_end_date,'YYYY/MM/DD')-- 入力パラメータ終了日付
        AND mfi.base_code           = gv_in_base_code              -- 入力パラメータ拠点
        AND mfi.created_by          = gn_created_by                -- ログインユーザ
      FOR UPDATE NOWAIT;
    -- 両方なし
    CURSOR forecast_if_cur
    IS
      SELECT mfi.forecast_if_id         -- 取引ID
            ,mfi.forecast_designator    -- Forecast分類
            ,mfi.location_code          -- 出荷倉庫
            ,mfi.base_code              -- 拠点
            ,mfi.dept_code              -- 取込部署
            ,mfi.item_code              -- 品目
            ,mfi.forecast_date          -- 開始日付
            ,mfi.forecast_end_date      -- 終了日付
            ,mfi.case_quantity          -- ケース数量
            ,mfi.indivi_quantity        -- バラ数量
            ,mfi.amount                 -- 金額
      FROM  xxinv_mrp_forecast_interface  mfi
      WHERE mfi.forecast_designator = gv_cons_fc_type_seigen_a     -- '出荷数制限A'
        AND mfi.forecast_date     = to_date(gv_in_start_date,'YYYY/MM/DD')-- 入力パラメータ開始日付
        AND mfi.forecast_end_date   = to_date(gv_in_end_date,'YYYY/MM/DD')-- 入力パラメータ終了日付
        AND mfi.created_by          = gn_created_by                -- ログインユーザ
      FOR UPDATE NOWAIT;
--
    -- *** ローカル・レコード ***
    lr_forecast_if_rec_i_b forecast_if_cur_i_b%ROWTYPE;
    lr_forecast_if_rec_i   forecast_if_cur_i%ROWTYPE;
    lr_forecast_if_rec_b   forecast_if_cur_b%ROWTYPE;
    lr_forecast_if_rec     forecast_if_cur%ROWTYPE;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- 処理件数の初期化
    gn_target_cnt := 0;
--
    -- 入力パラメータ任意項目によりカーソルを使い分ける
    IF (( gv_in_item_code IS NOT NULL ) AND ( gv_in_base_code IS NOT NULL )) THEN
      OPEN  forecast_if_cur_i_b;
      FETCH forecast_if_cur_i_b BULK COLLECT INTO io_if_data;
      gn_target_cnt := io_if_data.COUNT;
      CLOSE forecast_if_cur_i_b;
    ELSIF ( gv_in_item_code IS NOT NULL ) THEN
      OPEN  forecast_if_cur_i;
      FETCH forecast_if_cur_i BULK COLLECT INTO io_if_data;
      gn_target_cnt := io_if_data.COUNT;
      CLOSE forecast_if_cur_i;
    ELSIF ( gv_in_base_code IS NOT NULL ) THEN
      OPEN  forecast_if_cur_b;
      FETCH forecast_if_cur_b BULK COLLECT INTO io_if_data;
      gn_target_cnt := io_if_data.COUNT;
      CLOSE forecast_if_cur_b;
    ELSE
      OPEN  forecast_if_cur;
      FETCH forecast_if_cur BULK COLLECT INTO io_if_data;
      gn_target_cnt := io_if_data.COUNT;
      CLOSE forecast_if_cur;
    END IF;
--
    -- データがなかった場合は終了ステータスを警告とし処理を中止する
    IF (gn_target_cnt = 0) THEN
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_cmn     -- 'XXCMN'
                                                     ,gv_msg_10a_043    -- 対象データなし
                                                     ,gv_tkn_table      -- トークン'TABLE'
                                                     ,gv_if_table_jp
                                                    -- 販売計画/引取計画インターフェーステーブル
                                                     ,gv_tkn_key        -- トークン'KEY'
                                                     ,gv_cons_fc_type_seigen_a) -- '出荷数制限A'
                                                     ,1
                                                     ,5000);
-- add start 1.11
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
-- add end 1.11
      RAISE no_data;
    END IF;
--
  EXCEPTION
    WHEN lock_expt THEN  -- テーブルロックできなかった
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_cmn     -- 'XXCMN'
                                                     ,gv_msg_10a_044    -- テーブルロックエラー
                                                     ,gv_tkn_ng_table   -- トークン'NG_TABLE'
                                                     ,gv_if_table_jp)
                                                    -- 販売計画/引取計画インターフェーステーブル
                                                     ,1
                                                     ,5000);
      lv_errbuf := lv_errmsg ||gv_msg_part|| SQLERRM;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    WHEN no_data THEN                           --*** 対象データなし ***
      -- *** 任意で例外処理を記述する ****
      ov_errmsg  := lv_errmsg;                  --# 任意 #
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_warn;             -- 警告
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_seigen_a_if_data;
--
  /**********************************************************************************
   * Procedure Name   : get_seigen_b_if_data
   * Description      : A-6-1 出荷数制限Bインターフェースデータ抽出
   ***********************************************************************************/
  PROCEDURE get_seigen_b_if_data(
    io_if_data            IN OUT NOCOPY forecast_tbl,
    ov_errbuf             OUT NOCOPY VARCHAR2,  -- エラー・メッセージ            --# 固定 #
    ov_retcode            OUT NOCOPY VARCHAR2,  -- リターン・コード              --# 固定 #
    ov_errmsg             OUT NOCOPY VARCHAR2)  -- ユーザー・エラー・メッセージ  --# 固定 #
  IS 
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_seigen_b_if_data'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
--mod start 1.6
--    lv_sql_buf VARCHAR(5000);  -- SQL文格納バッファ
--    lv_sql_buf2 VARCHAR(5000);  -- SQL文格納バッファ
--    lv_sql_buf3 VARCHAR(5000);  -- SQL文格納バッファ
--    lv_sql_buf4 VARCHAR(5000);  -- SQL文格納バッファ
--    lv_sql_buf5 VARCHAR(5000);  -- SQL文格納バッファ
--    lv_sql_buf6 VARCHAR(5000);  -- SQL文格納バッファ
--    lv_sql_buf7 VARCHAR(5000);  -- SQL文格納バッファ
--    lv_sql_buf8 VARCHAR(5000);  -- SQL文格納バッファ
--    lv_sql_buf9 VARCHAR(5000);  -- SQL文格納バッファ
--    lv_sql_buf10 VARCHAR(5000);  -- SQL文格納バッファ
--    lv_sql_buf11 VARCHAR(5000);  -- SQL文格納バッファ
    lv_sql_buf VARCHAR2(5000);  -- SQL文格納バッファ
    lv_sql_buf2 VARCHAR2(5000);  -- SQL文格納バッファ
    lv_sql_buf3 VARCHAR2(5000);  -- SQL文格納バッファ
    lv_sql_buf4 VARCHAR2(5000);  -- SQL文格納バッファ
    lv_sql_buf5 VARCHAR2(5000);  -- SQL文格納バッファ
    lv_sql_buf6 VARCHAR2(5000);  -- SQL文格納バッファ
    lv_sql_buf7 VARCHAR2(5000);  -- SQL文格納バッファ
    lv_sql_buf8 VARCHAR2(5000);  -- SQL文格納バッファ
    lv_sql_buf9 VARCHAR2(5000);  -- SQL文格納バッファ
    lv_sql_buf10 VARCHAR2(5000);  -- SQL文格納バッファ
    lv_sql_buf11 VARCHAR2(5000);  -- SQL文格納バッファ
--mod end 1.6
--
    -- *** ローカル・カーソル ***
    TYPE cursor_type IS REF CURSOR;
    cur cursor_type;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- 処理件数の初期化
    gn_target_cnt := 0;
--
    -- 動的SQLにより、取込部署抽出フラグ・任意入力パラメータの条件を付加する
    lv_sql_buf := 'SELECT mfi.forecast_if_id, '              ||
                         'mfi.forecast_designator, '         ||
                         'mfi.location_code, '               ||
                         'mfi.base_code, '                   ||
                         'mfi.dept_code, '                   ||
                         'mfi.item_code, ';
    lv_sql_buf2 :=       'mfi.forecast_date, '               ||
                         'mfi.forecast_end_date, '           ||
                         'mfi.case_quantity, '               ||
                         'mfi.indivi_quantity, '             ||
                         'mfi.amount ';
    lv_sql_buf3 := 'FROM  xxinv_mrp_forecast_interface mfi ';
    lv_sql_buf5 :=  'WHERE mfi.forecast_designator = ' || '''' || gv_cons_fc_type_seigen_b || '''';
    lv_sql_buf6 :=   ' AND mfi.forecast_date       =
             to_date(' || '''' || gv_in_start_date || '''' || ',' || '''YYYY/MM/DD'')';
    lv_sql_buf7 :=   ' AND mfi.forecast_end_date   =
             to_date(' || '''' || gv_in_end_date   || '''' || ',' || '''YYYY/MM/DD'')';
--
    lv_sql_buf3 := lv_sql_buf3 || lv_sql_buf5 || lv_sql_buf6 || lv_sql_buf7;
--
    -- 任意の入力パラメータの入力状態により条件を付加していく
    -- 品目が入力されていたら・・・
    IF (gv_in_item_code IS NOT NULL) THEN
      lv_sql_buf8 := --lv_sql_buf4 || 
                    ' AND mfi.item_code           = ' || '''' || gv_in_item_code || '''';
      lv_sql_buf3 := lv_sql_buf3 || lv_sql_buf8;
    END IF;
    -- 出庫倉庫が入力されていたら・・・
    IF (gv_in_location_code IS NOT NULL) THEN
      lv_sql_buf9 := --lv_sql_buf4 || 
                    ' AND mfi.location_code       = ' || '''' || gv_in_location_code || '''';
      lv_sql_buf3 := lv_sql_buf3 || lv_sql_buf9;
    END IF;
    -- 入力パラメータの取込部署抽出フラグが'Yes'の場合は事業所コードを付加する
    IF (gv_in_dept_code_flg = gv_cons_flg_yes) THEN
      lv_sql_buf10 := --lv_sql_buf4 || 
                    ' AND mfi.dept_code           = ' || '''' || gv_location_code || '''';
      lv_sql_buf3 := lv_sql_buf3 || lv_sql_buf10;
    END IF;
   lv_sql_buf11 := ' AND mfi.created_by          = ' || gn_created_by ||
                  ' FOR UPDATE NOWAIT';
--
   lv_sql_buf := lv_sql_buf || lv_sql_buf2 ||lv_sql_buf3 || lv_sql_buf11;
--
    -- ******************************************************************
    -- 販売計画/引取計画インタ－フェーステーブルから出荷数制限Bデータ抽出
    -- ******************************************************************
    -- カーソルオープン
    OPEN cur FOR lv_sql_buf;
--
    -- データの一括取得
    FETCH cur BULK COLLECT INTO io_if_data;
--
    -- 処理件数のセット
    gn_target_cnt := io_if_data.COUNT;
--
    -- カーソルクローズ
    CLOSE cur;
--
    -- データがなかった場合は終了ステータスを警告とし処理を中止する
    IF (gn_target_cnt = 0) THEN
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_cmn     -- 'XXCMN'
                                                    ,gv_msg_10a_043    -- 対象データなし
                                                    ,gv_tkn_table      -- トークン'TABLE'
                                                    ,gv_if_table_jp
                                                  -- 販売計画/引取計画インターフェーステーブル
                                                    ,gv_tkn_key        -- トークン'KEY'
                                                    ,gv_cons_fc_type_seigen_b) -- '出荷数制限B'
                                                    ,1
                                                    ,5000);
-- add start 1.11
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
-- add end 1.11
      RAISE no_data;
    END IF;
--
  EXCEPTION
    WHEN lock_expt THEN  -- テーブルロックできなかった
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_cmn     -- 'XXCMN'
                                                     ,gv_msg_10a_044    -- テーブルロックエラー
                                                     ,gv_tkn_ng_table   -- トークン'NG_TABLE'
                                                     ,gv_if_table_jp)   
                                                    -- 販売計画/引取計画インターフェーステーブル
                                                     ,1
                                                     ,5000);
      lv_errbuf := lv_errmsg ||gv_msg_part|| SQLERRM;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    WHEN no_data THEN                           --*** 対象データなし ***
      -- *** 任意で例外処理を記述する ****
      ov_errmsg  := lv_errmsg;                  --# 任意 #
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_warn;             -- 警告
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_seigen_b_if_data;
--
  /**********************************************************************************
   * Procedure Name   : shipped_date_start_check
   * Description      : 1.出庫倉庫の適用日と開始日付チェック
   ***********************************************************************************/
  PROCEDURE shipped_date_start_check(
    iv_forecast_designator   IN  VARCHAR2,      -- Forecast分類
    iv_location_cd           IN  VARCHAR2,      -- 出荷倉庫コード 
    id_start_date_active     IN  DATE,          -- 開始日付
    id_end_date_active       IN  DATE,          -- 終了日付
    ov_errbuf             OUT NOCOPY VARCHAR2,  -- エラー・メッセージ           --# 固定 #
    ov_retcode            OUT NOCOPY VARCHAR2,  -- リターン・コード             --# 固定 #
    ov_errmsg             OUT NOCOPY VARCHAR2)  -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'shipped_date_start_check'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    ln_select_count    NUMBER;          -- 存在チェックのためのカウンタ
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
--
    -- OPM保管場所マスタから保管倉庫IDを取得する
    SELECT COUNT(xil_v.inventory_location_id)           -- 保管倉庫ID
    INTO   ln_select_count
    FROM   xxcmn_item_locations2_v xil_v
    WHERE  xil_v.segment1 = iv_location_cd   -- 出荷倉庫コード
      AND  xil_v.date_from  <= id_start_date_active
      AND  ((xil_v.date_to  >= id_start_date_active) OR (xil_v.date_to IS NULL))
      AND  xil_v.disable_date IS NULL;
--
    -- 出庫倉庫が妥当でない(存在しない)場合の後処理（Forecast分類で処理結果に違いはない）
    IF (ln_select_count = 0) THEN
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_inv -- 'XXINV'
                                                    ,gv_msg_10a_023 -- 出荷倉庫存在チェックエラー
                                                    ,gv_tkn_soko    -- トークン'SOKO'
                                                    ,iv_location_cd) -- 出庫倉庫
                                                    ,1
                                                    ,5000);
      RAISE warning_expt;
    END IF;
--
  EXCEPTION
    WHEN warning_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_warn;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END shipped_date_start_check;
--
  /**********************************************************************************
   * Procedure Name   : shipped_class_check
   * Description      : 2.出庫倉庫の出庫管理元区分チェック
   ***********************************************************************************/
  PROCEDURE shipped_class_check(
    iv_forecast_designator   IN  VARCHAR2,      -- Forecast分類
    iv_item_code             IN  VARCHAR2,      -- 品目
    iv_location_code         IN  VARCHAR2,        -- 出荷倉庫 
    ov_errbuf             OUT NOCOPY VARCHAR2,  -- エラー・メッセージ           --# 固定 #
    ov_retcode            OUT NOCOPY VARCHAR2,  -- リターン・コード             --# 固定 #
    ov_errmsg             OUT NOCOPY VARCHAR2)  -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'shipped_class_check'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    lv_item_class    mtl_categories_b.segment1%TYPE;
    ln_select_count    NUMBER  := 0;          -- 存在チェックのためのカウンタ
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- 品目の商品区分を抽出する
    SELECT icv.prod_class_code
    INTO   lv_item_class
    FROM   xxcmn_item_categories3_v icv
    WHERE  icv.item_no       = iv_item_code
      AND  ROWNUM            = 1;
--
    -- 品目の商品区分がドリンクの場合
    IF (lv_item_class = gv_ship_ctl_id_drink) THEN
      SELECT COUNT(lv.location_id)              -- 事業所ID
      INTO   ln_select_count 
      FROM   xxcmn_item_locations_v       ilv,  -- OPM保管場所マスタ
             xxcmn_locations_v            lv    -- 事業所情報VIEW
      WHERE  ilv.segment1              = iv_location_code
        AND  ilv.location_id           = lv.location_id
        AND  lv.ship_mng_code         IN (gv_ship_ctl_id_drink, gv_ship_ctl_id_both)
        AND  ROWNUM                    = 1;
--
    -- 品目の商品区分がリーフの場合
    ELSIF (lv_item_class = gv_ship_ctl_id_leaf) THEN
      SELECT COUNT(lv.location_id)              -- 事業所ID
      INTO   ln_select_count 
      FROM   xxcmn_item_locations_v       ilv,  -- OPM保管場所マスタ
             xxcmn_locations_v            lv    -- 事業所情報VIEW
      WHERE  ilv.segment1              = iv_location_code
        AND  ilv.location_id           = lv.location_id
        AND  lv.ship_mng_code         IN (gv_ship_ctl_id_leaf, gv_ship_ctl_id_both)
        AND  ROWNUM                    = 1;
    END IF;
--
    -- 出庫倉庫が妥当でない(存在しない)場合(Forecast分類で処理結果に違いはない）
    IF (ln_select_count = 0) THEN
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_inv    -- 'XXINV'
                                                    ,gv_msg_10a_026    -- 出荷倉庫管理元区分エラー
                                                    ,gv_tkn_soko       -- トークン'SOKO'
                                                    ,iv_location_code  -- 出庫倉庫
                                                    ,gv_tkn_item       -- トークン'ITEM'
                                                    ,iv_item_code)     -- 品目
                                                    ,1
                                                    ,5000);
      RAISE global_api_expt;
    END IF;
--
  EXCEPTION
    -- 商品区分が取得できなかった場合
    WHEN NO_DATA_FOUND THEN
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_inv   -- 'XXINV'
                                                    ,gv_msg_10a_061   -- 商品区分取得エラー
                                                    ,gv_tkn_item      -- トークン'ITEM'
                                                    ,iv_item_code)    -- 品目コード
                                                    ,1
                                                    ,5000);
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END shipped_class_check;
--
  /**********************************************************************************
   * Procedure Name   : base_code_exist_check
   * Description      : 3.拠点の存在チェック
   ***********************************************************************************/
  PROCEDURE base_code_exist_check(
    iv_forecast_designator   IN  VARCHAR2,      -- Forecast分類
    iv_base_code             IN  VARCHAR2,      -- 拠点 
    ov_errbuf             OUT NOCOPY VARCHAR2,  -- エラー・メッセージ           --# 固定 #
    ov_retcode            OUT NOCOPY VARCHAR2,  -- リターン・コード             --# 固定 #
    ov_errmsg             OUT NOCOPY VARCHAR2)  -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'base_code_exist_check'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    ln_select_count    NUMBER;          -- 存在チェックのためのカウンタ
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- 顧客マスタから顧客IDを取得する
    SELECT COUNT(cca.cust_account_id)     -- 顧客ID
    INTO   ln_select_count
    FROM   xxcmn_cust_accounts_v  cca
    WHERE  cca.account_number      = iv_base_code
      AND  cca.customer_class_code = gv_cons_base_code
      AND  ROWNUM                  = 1;
--
    -- 存在しない場合(Forecast分類で処理結果に違いはない）
    IF (ln_select_count = 0) THEN
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_inv   -- 'XXINV'
                                                    ,gv_msg_10a_024   -- 拠点存在チェックエラー
                                                    ,gv_tkn_kyoten    -- トークン'KYOTEN'
                                                    ,iv_base_code)    -- 拠点
                                                    ,1
                                                    ,5000);
      RAISE global_api_expt;
    END IF;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END base_code_exist_check;
--
--
  /**********************************************************************************
   * Procedure Name   : item_abolition_code_check
   * Description      : 4.品目の廃止区分チェック
   ***********************************************************************************/
  PROCEDURE item_abolition_code_check(
    iv_forecast_designator  IN  VARCHAR2,        -- Forecast分類
    iv_item_code            IN  VARCHAR2,        -- 品目
    id_start_date_active    IN  DATE,            -- 開始日付
    ov_errbuf               OUT NOCOPY VARCHAR2, -- エラー・メッセージ           --# 固定 #
    ov_retcode              OUT NOCOPY VARCHAR2, -- リターン・コード             --# 固定 #
    ov_errmsg               OUT NOCOPY VARCHAR2) -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'item_abolition_code_check'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
-- 2009/04/16 v1.22 UPDATE START
--    ln_select_count    NUMBER;          -- 存在チェックのためのカウンタ
      lv_min_start_date      xxcmn_item_mst2_v.start_date_active%TYPE;  -- 最小適用開始日
      lv_max_end_date        xxcmn_item_mst2_v.end_date_active%TYPE;    -- 最大適用終了日
-- 2009/04/16 v1.22 UPDATE END
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- OPM品目マスタから品目IDを取得する
-- 2009/04/16 v1.22 UPDATE START
/*
    SELECT COUNT(imv.item_id)     -- 品目ID
    INTO   ln_select_count
    FROM   xxcmn_item_mst2_v  imv  -- OPM品目情報view
    WHERE  imv.item_no            = iv_item_code
      AND  imv.start_date_active <= id_start_date_active
      AND  imv.end_date_active   >= id_start_date_active
      AND  ROWNUM                 = 1;
*/
    SELECT MIN(imv.start_date_active)
          ,MAX(imv.end_date_active)
    INTO   lv_min_start_date
          ,lv_max_end_date
    FROM   xxcmn_item_mst2_v  imv  -- OPM品目情報view
    WHERE  imv.item_no            = iv_item_code
    ;
-- 2009/04/16 v1.22 UPDATE END
--
    -- 品目が妥当でない(存在しない)場合(Forecast分類で処理結果に違いはない）
-- 2009/04/16 v1.22 UPDATE START
--    IF (ln_select_count = 0) THEN
    IF (
         (lv_min_start_date > id_start_date_active)
         OR
         (lv_max_end_date   < id_start_date_active)
       ) THEN
-- 2009/04/16 v1.22 UPDATE END
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_inv  -- 'XXINV'
                                                    ,gv_msg_10a_027  -- 品目区分チェックワーニング
                                                    ,gv_tkn_item     -- トークン'ITEM'
                                                    ,iv_item_code)   -- 品目
                                                    ,1
                                                    ,5000);
      RAISE global_api_expt;
    END IF;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END item_abolition_code_check;
--
  /**********************************************************************************
   * Procedure Name   : item_class_check
   * Description      : 5.品目の品目区分チェック
   ***********************************************************************************/
  PROCEDURE item_class_check(
    iv_forecast_designator   IN  VARCHAR2,      -- Forecast分類
    iv_item_code             IN  VARCHAR2,      -- 品目
    id_start_date_active     IN  DATE,          -- 開始日付
    ov_errbuf             OUT NOCOPY VARCHAR2,  -- エラー・メッセージ           --# 固定 #
    ov_retcode            OUT NOCOPY VARCHAR2,  -- リターン・コード             --# 固定 #
    ov_errmsg             OUT NOCOPY VARCHAR2)  -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'item_class_check'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    ln_select_count    NUMBER;          -- 存在チェックのためのカウンタ
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- 品目IDを抽出する
    SELECT COUNT(ic.item_id)
    INTO   ln_select_count
    FROM   xxcmn_item_categories_v  ic
    WHERE  ic.item_no         = iv_item_code
      AND  segment1           = gv_cons_item_product -- 品目区分が「製品」
      AND  ROWNUM             = 1;

    -- 品目が妥当でない(存在しない)場合(Forecast分類で処理結果に違いはない）
    IF (ln_select_count = 0) THEN
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_inv  -- 'XXINV'
                                                    ,gv_msg_10a_028  -- 品目区分チェックワーニング
                                                    ,gv_tkn_item     -- トークン'ITEM'
                                                    ,iv_item_code)   -- 品目
                                                    ,1
                                                    ,5000);
      RAISE warning_expt;
    END IF;
--
  EXCEPTION
    WHEN warning_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_warn;
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END item_class_check;
--
  /**********************************************************************************
   * Procedure Name   : item_date_start_check
   * Description      : 6.品目の適用日と開始日付チェック
   ***********************************************************************************/
  PROCEDURE item_date_start_check(
    iv_forecast_designator  IN  VARCHAR2,        -- Forecast分類
    iv_item_code            IN  VARCHAR2,        -- 品目
    id_start_date_active    IN  DATE,            -- 開始日付
    ov_errbuf               OUT NOCOPY VARCHAR2, -- エラー・メッセージ           --# 固定 #
    ov_retcode              OUT NOCOPY VARCHAR2, -- リターン・コード             --# 固定 #
    ov_errmsg               OUT NOCOPY VARCHAR2) -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'item_date_start_check'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    ln_select_count    NUMBER;          -- 存在チェックのためのカウンタ
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- 品目マスタから品目IDを取得する
    SELECT COUNT(imv.item_id)
    INTO   ln_select_count
    FROM   xxcmn_item_mst2_v  imv   -- OPM品目情報View
    WHERE  imv.item_no            = iv_item_code
      AND  imv.start_date_active <= id_start_date_active
      AND  imv.end_date_active   >= id_start_date_active
      AND  ROWNUM                 = 1;
--
    -- 品目が妥当でない(存在しない)場合(Forecast分類で処理結果に違いはない）
    IF (ln_select_count = 0) THEN
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_inv  -- 'XXINV'
                                                    ,gv_msg_10a_029  -- 品目存在チェックワーニング
                                                    ,gv_tkn_item     -- トークン'ITEM'
                                                    ,iv_item_code)   -- 品目
                                                    ,1
                                                    ,5000);
      RAISE warning_expt;
    END IF;
--
  EXCEPTION
    WHEN warning_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_warn;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END item_date_start_check;
--
  /**********************************************************************************
   * Procedure Name   : item_date_year_check
   * Description      : 7.品目の適用日と年度警告チェック
   ***********************************************************************************/
  PROCEDURE item_date_year_check(
    iv_forecast_designator  IN  VARCHAR2,        -- Forecast分類
    iv_item_code            IN  VARCHAR2,        -- 品目
    ov_errbuf               OUT NOCOPY VARCHAR2, -- エラー・メッセージ           --# 固定 #
    ov_retcode              OUT NOCOPY VARCHAR2, -- リターン・コード             --# 固定 #
    ov_errmsg               OUT NOCOPY VARCHAR2) -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'item_date_year_check'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
-- 2009/04/16 v1.22 UPDATE START
--    ln_select_count    NUMBER;          -- 存在チェックのためのカウンタ
      lv_min_start_date      xxcmn_item_mst2_v.start_date_active%TYPE;  -- 最小適用開始日
      lv_max_end_date        xxcmn_item_mst2_v.end_date_active%TYPE;    -- 最大適用終了日
-- 2009/04/16 v1.22 UPDATE END
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- 品目IDを取得する
-- 2009/04/16 v1.22 UPDATE START
/*
    SELECT COUNT(imv.item_id)
    INTO   ln_select_count
    FROM   xxcmn_item_mst2_v  imv  -- OPM品目情報View2
    WHERE  imv.item_no             = iv_item_code
      AND  imv.start_date_active  <= gd_start_yyyymmdd
      AND  imv.end_date_active    >= gd_end_yyyymmdd
      AND  ROWNUM                  = 1;
*/
    SELECT MIN(imv.start_date_active)
          ,MAX(imv.end_date_active)
    INTO   lv_min_start_date
          ,lv_max_end_date
    FROM   xxcmn_item_mst2_v  imv  -- OPM品目情報View2
    WHERE  imv.item_no             = iv_item_code
    ;
-- 2009/04/16 v1.22 UPDATE END
--
    -- 品目が妥当でない(存在しない)場合の後処理（Forecast分類で処理結果に違いはない）
    -- 警告としてリターンする
-- 2009/04/16 v1.22 UPDATE START
--    IF (ln_select_count = 0) THEN
    IF (
         (lv_min_start_date > gd_start_yyyymmdd)
         OR
         (lv_max_end_date   < gd_end_yyyymmdd)
       ) THEN
-- 2009/04/16 v1.22 UPDATE END
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_inv  -- 'XXINV'
                                                    ,gv_msg_10a_030  -- 品目年度チェックワーニング
                                                    ,gv_tkn_item     -- トークン'ITEM'
                                                    ,iv_item_code)   -- 品目
                                                    ,1
                                                    ,5000);
      RAISE warning_expt;
    END IF;
--
  EXCEPTION
    WHEN warning_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_warn;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END item_date_year_check;
--
  /**********************************************************************************
   * Procedure Name   : item_standard_year_check
   * Description      : 8.品目の標準原価適用日と年度警告チェック
   ***********************************************************************************/
  PROCEDURE item_standard_year_check(
    iv_forecast_designator  IN  VARCHAR2,        -- Forecast分類
    iv_item_code            IN  VARCHAR2,        -- 品目
    ov_errbuf               OUT NOCOPY VARCHAR2, -- エラー・メッセージ           --# 固定 #
    ov_retcode              OUT NOCOPY VARCHAR2, -- リターン・コード             --# 固定 #
    ov_errmsg               OUT NOCOPY VARCHAR2) -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'item_standard_year_check'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
-- 2009/04/16 v1.22 UPDATE START
--    ln_select_count    NUMBER;          -- 存在チェックのためのカウンタ
      lv_min_start_date      xxcmn_item_mst2_v.start_date_active%TYPE;  -- 最小適用開始日
      lv_max_end_date        xxcmn_item_mst2_v.end_date_active%TYPE;    -- 最大適用終了日
-- 2009/04/16 v1.22 UPDATE END
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- 仕入/標準原価ヘッダ(アドオン)から品目IDを取得する
--
-- 2009/04/16 v1.22 UPDATE START
/*
    SELECT COUNT(pph.item_id)           -- 品目ID
    INTO   ln_select_count
    FROM   xxpo_price_headers   pph     -- 仕入/標準原価ヘッダ(アドオン)
    WHERE  pph.price_type          = gv_cons_p_type_standard   -- '標準'
      AND  pph.item_code           = iv_item_code
      AND  pph.start_date_active  <= gd_start_yyyymmdd
      AND  pph.end_date_active    >= gd_end_yyyymmdd
      AND  ROWNUM                  = 1;
*/
    SELECT MIN(pph.start_date_active)
          ,MAX(pph.end_date_active)
    INTO   lv_min_start_date
          ,lv_max_end_date
    FROM   xxpo_price_headers   pph     -- 仕入/標準原価ヘッダ(アドオン)
    WHERE  pph.price_type          = gv_cons_p_type_standard   -- '標準'
      AND  pph.item_code           = iv_item_code
    ;
-- 2009/04/16 v1.22 UPDATE END
--
    -- 品目IDが妥当でない(存在しない)場合の後処理（Forecast分類で処理結果に違いはない）
    -- 警告としてリターンする
-- 2009/04/16 v1.22 UPDATE START
--    IF (ln_select_count = 0) THEN
    IF (
         (lv_min_start_date > gd_start_yyyymmdd)
         OR
         (lv_max_end_date   < gd_end_yyyymmdd)
       ) THEN
-- 2009/04/16 v1.22 UPDATE END
      lv_errmsg := SUBSTRB(xxcmn_common_pkg.get_msg(gv_msg_kbn_inv    -- 'XXINV'
                                                             -- 品目標準原価年度チェックワーニング
                                                   ,gv_msg_10a_031
                                                   ,gv_tkn_item     -- トークン'ITEM'
                                                   ,iv_item_code)   -- 品目
                                                   ,1
                                                   ,5000);
      RAISE warning_expt;
    END IF;
--
  EXCEPTION
    WHEN warning_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_warn;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END item_standard_year_check;
--
  /**********************************************************************************
   * Procedure Name   : item_forecast_check
   * Description      : 9.10.品目の物流構成表計画商品対象品目と日付チェック
   ***********************************************************************************/
  PROCEDURE item_forecast_check(
    iv_forecast_designator   IN  VARCHAR2,      -- Forecast分類
    iv_item_code             IN  VARCHAR2,      -- 品目
    iv_base_code             IN  VARCHAR2,      -- 拠点
    iv_location_code         IN  VARCHAR2,      -- 出荷倉庫
    id_start_date_active     IN  DATE,          -- 開始日付
    id_end_date_active       IN  DATE,          -- 終了日付
    ov_errbuf             OUT NOCOPY VARCHAR2,  -- エラー・メッセージ           --# 固定 #
    ov_retcode            OUT NOCOPY VARCHAR2,  -- リターン・コード             --# 固定 #
    ov_errmsg             OUT NOCOPY VARCHAR2)  -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'item_forecast_check'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    ln_select_count    NUMBER;          -- 存在チェックのためのカウンタ
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- 物流構成アドオンマスタから品目コードを抽出する
    SELECT COUNT(csr.item_code)             -- 品目コード
    INTO   ln_select_count
    FROM   xxcmn_sourcing_rules2_v   csr    -- 物流構成アドオンマスタ
    WHERE  csr.item_code          = iv_item_code
      AND  csr.base_code          = iv_base_code
      AND  csr.delivery_whse_code = iv_location_code
      AND  csr.plan_item_flag     = gn_cons_p_item_flag     -- 1(=計画商品)
      AND  csr.start_date_active <= id_start_date_active
      AND  csr.end_date_active   >= id_end_date_active
      AND  ROWNUM                 = 1;
--
    -- 品目IDが妥当でない(存在しない)場合の後処理（Forecast分類で処理結果に違いはない）
    -- エラーとしてリターンする
    IF (ln_select_count = 0) THEN
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_inv     -- 'XXINV'
                                                            -- 品目計画商品存在チェックワーニング
                                                    ,gv_msg_10a_032
                                                    ,gv_tkn_item      -- トークン'ITEM'
                                                    ,iv_item_code)    -- 品目
                                                    ,1
                                                    ,5000);
      RAISE global_api_expt;
    END IF;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END item_forecast_check;
--
  /**********************************************************************************
   * Procedure Name   : item_not_regist_check
   * Description      : 11.品目の物流構成表未登録の警告チェック
   ***********************************************************************************/
  PROCEDURE item_not_regist_check(
    iv_forecast_designator   IN  VARCHAR2,        -- Forecast分類
    iv_item_code             IN  VARCHAR2,        -- 品目
    iv_base_code             IN  VARCHAR2,        -- 拠点
    iv_location_code         IN  VARCHAR2,        -- 出荷倉庫
    id_start_date_active     IN  DATE,            -- 開始日付
    id_end_date_active       IN  DATE,            -- 終了日付
    ov_errbuf                OUT NOCOPY VARCHAR2, -- エラー・メッセージ           --# 固定 #
    ov_retcode               OUT NOCOPY VARCHAR2, -- リターン・コード             --# 固定 #
    ov_errmsg                OUT NOCOPY VARCHAR2) -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'item_not_regist_check'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    ln_select_count       NUMBER;     -- 存在チェックのためのカウンタ
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- 物流構成アドオンマスタから物流構成アドオンIDを取得する
    SELECT COUNT(csr.sourcing_rules_id) -- 物流構成アドオンID
    INTO   ln_select_count
    FROM   xxcmn_sourcing_rules2_v  csr  -- 物流構成アドオンマスタ
    WHERE  csr.item_code          = iv_item_code
      AND  (csr.base_code          = NVL(iv_base_code,csr.base_code)
        OR
            csr.base_code          IS NULL )
      AND  (csr.delivery_whse_code = NVL(iv_location_code,csr.delivery_whse_code)  
        OR 
            csr.delivery_whse_code IS NULL )
      AND  csr.start_date_active <= id_start_date_active
      AND  csr.end_date_active   >= id_end_date_active
      AND  ROWNUM                 = 1;
--
    -- 品目が妥当でない(存在しない)場合(Forecast分類で処理結果に違いはない）
    -- 警告としてリターンする
    IF (ln_select_count = 0) THEN
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_inv    -- 'XXINV'
                                                           -- 品目物流構成存在チェックワーニング
                                                    ,gv_msg_10a_033
                                                    ,gv_tkn_item      -- トークン'ITEM'
                                                    ,iv_item_code)    -- 品目
                                                    ,1
                                                    ,5000);
      RAISE warning_expt;
    END IF;
--
  EXCEPTION
    WHEN warning_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_warn;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END item_not_regist_check;
--
  /**********************************************************************************
   * Procedure Name   : date_month_check
   * Description      : 12.日付の対象月チェック
   ***********************************************************************************/
  PROCEDURE date_month_check(
    iv_forecast_designator   IN  VARCHAR2,        -- Forecast分類
    id_start_date_active     IN  DATE,            -- 開始日付
    ov_errbuf                OUT NOCOPY VARCHAR2, -- エラー・メッセージ           --# 固定 #
    ov_retcode               OUT NOCOPY VARCHAR2, -- リターン・コード             --# 固定 #
    ov_errmsg                OUT NOCOPY VARCHAR2) -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'date_month_check'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- 年月の比較（抽出した開始日付の年月がシステム日付の年月より古かったらエラー）
    IF (TO_CHAR(id_start_date_active,'YYYY/MM') < TO_CHAR(gd_sysdate_yyyymmdd,'YYYY/MM')) THEN
      RAISE date_error;
    END IF;
--
  EXCEPTION
    -- 開始日付が妥当でない場合の後処理（Forecast分類で処理結果に違いはない）
    WHEN date_error THEN                           --*** 年月比較エラー例外 ***
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_inv    -- 'XXINV'
                                                    ,gv_msg_10a_034    -- 開始日付過去年月エラー
                                                    ,gv_tkn_sdate      -- トークン'SDATE'
                                                    ,id_start_date_active)  -- 開始日付
                                                    ,1
                                                    ,5000);
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;                                            --# 任意 #
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END date_month_check;
--
  /**********************************************************************************
   * Procedure Name   : date_year_check
   * Description      : 13.日付の対象年チェック
   ***********************************************************************************/
  PROCEDURE date_year_check(
    iv_forecast_designator   IN  VARCHAR2,        -- Forecast分類
    id_start_date_active     IN  DATE,            -- 開始日付
    ov_errbuf                OUT NOCOPY VARCHAR2, -- エラー・メッセージ           --# 固定 #
    ov_retcode               OUT NOCOPY VARCHAR2, -- リターン・コード             --# 固定 #
    ov_errmsg                OUT NOCOPY VARCHAR2) -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'date_year_check'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
   ln_year     NUMBER;   -- 年度
   ld_yyyymmdd DATE;
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- 入力パラメータ年度＋年度開始月日(プロファイル)よりインターフェースの開始日付が
    -- 古かったらエラーとする。
    ld_yyyymmdd := FND_DATE.STRING_TO_DATE(gv_forecast_year || '/' || gv_start_mmdd, 'YYYY/MM/DD');
--
    IF (id_start_date_active < ld_yyyymmdd) THEN
      RAISE date_error;
    END IF;
--
  EXCEPTION
    -- 年が妥当でない場合の後処理（Forecast分類で処理結果に違いはない）
    -- エラーとしてリターンする
    WHEN date_error THEN                           --*** 年比較エラー例外 ***
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_inv    -- 'XXINV'
                                                    ,gv_msg_10a_035    -- 開始日付過去年度エラー
                                                    ,gv_tkn_sdate      -- トークン'SDATE'
                                                    ,id_start_date_active)  -- 開始日付
                                                    ,1
                                                    ,5000);
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;                                            --# 任意 #
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END date_year_check;
--
  /**********************************************************************************
   * Procedure Name   : date_past_check
   * Description      : 14.日付の過去チェック
   ***********************************************************************************/
  PROCEDURE date_past_check(
    iv_forecast_designator   IN  VARCHAR2,        -- Forecast分類
    id_start_date_active     IN  DATE,            -- 開始日付
    id_end_date_active       IN  DATE,            -- 終了日付
    ov_errbuf                OUT NOCOPY VARCHAR2, -- エラー・メッセージ           --# 固定 #
    ov_retcode               OUT NOCOPY VARCHAR2, -- リターン・コード             --# 固定 #
    ov_errmsg                OUT NOCOPY VARCHAR2) -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'date_past_check'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- 開始日付の過去チェック（抽出した開始日付のがシステム日付より古かったらエラー）
    IF (id_start_date_active < gd_sysdate_yyyymmdd) THEN
      RAISE date_error;
    END IF;
--
    -- 終了日付の過去チェック（抽出した終了日付のがシステム日付より古かったらエラー）
    IF (id_end_date_active < gd_sysdate_yyyymmdd) THEN
      RAISE date_error;
    END IF;
--
  EXCEPTION
    -- 年が妥当でない場合の後処理（Forecast分類で処理結果に違いはない）
    -- 警告としてリターンする
    WHEN date_error THEN                           --*** 年比較エラー例外 ***
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_inv  -- 'XXINV'
                                                    ,gv_msg_10a_036  -- 日付過去チェックワーニング
                                                    ,gv_tkn_sdate    -- トークン'SDATE'
                                                    ,id_start_date_active -- 開始日付
                                                    ,gv_tkn_edate    -- トークン'EDATE'
                                                    ,id_end_date_active)  -- 終了日付
                                                    ,1
                                                    ,5000);
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_warn;                                            --# 任意 #
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END date_past_check;
--
  /**********************************************************************************
   * Procedure Name   : start_date_range_check
   * Description      : 15.開始日付の1ヶ月以内チェック
   ***********************************************************************************/
  PROCEDURE start_date_range_check(
    iv_forecast_designator   IN  VARCHAR2,        -- Forecast分類
    id_start_date_active     IN  DATE,            -- 開始日付
    ov_errbuf                OUT NOCOPY VARCHAR2, -- エラー・メッセージ           --# 固定 #
    ov_retcode               OUT NOCOPY VARCHAR2, -- リターン・コード             --# 固定 #
    ov_errmsg                OUT NOCOPY VARCHAR2) -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'start_date_range_check'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- 開始日付の未来チェック（抽出した開始日付のがシステム日付＋1ヶ月より未来なら警告）
    IF (id_start_date_active > ADD_MONTHS(gd_sysdate_yyyymmdd, 1)) THEN
      RAISE date_error;
    END IF;
--
  EXCEPTION
    -- 開始日付が妥当でない場合の後処理（Forecast分類で処理結果に違いはない）
    -- 警告としてリターンする
    WHEN date_error THEN                           --*** 年比較エラー例外 ***
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_inv    -- 'XXINV'
                                                              -- 日付1ヶ月以内チェックワーニング
                                                    ,gv_msg_10a_037
                                                    ,gv_tkn_sdate    -- トークン'SDATE'
                                                    ,id_start_date_active)    -- 開始日付
                                                    ,1
                                                    ,5000);
      ov_errmsg  := lv_errmsg;                                                 --# 任意 #
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_warn;                                            --# 任意 #
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END start_date_range_check;
--
  /**********************************************************************************
   * Procedure Name   : date_start_end_check
   * Description      : 16.日付の開始＜終了チェック
   ***********************************************************************************/
  PROCEDURE date_start_end_check(
    iv_forecast_designator   IN  VARCHAR2,        -- Forecast分類
    id_start_date_active     IN  DATE,            -- 開始日付
    id_end_date_active       IN  DATE,            -- 終了日付
    ov_errbuf                OUT NOCOPY VARCHAR2, -- エラー・メッセージ           --# 固定 #
    ov_retcode               OUT NOCOPY VARCHAR2, -- リターン・コード             --# 固定 #
    ov_errmsg                OUT NOCOPY VARCHAR2) -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'date_start_end_check'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- 開始日付と終了日付の大小チェック（抽出した終了日付が開始日付より過去ならエラー）
    IF (id_start_date_active > id_end_date_active) THEN
      RAISE date_error;
    END IF;
--
  EXCEPTION
    -- 開始日付と終了日付の大小が妥当でない場合の後処理（Forecast分類で処理結果に違いはない）
    -- エラーとしてリターンする
    WHEN date_error THEN
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_inv    -- 'XXINV'
                                                    ,gv_msg_10a_038)   -- 日付大小比較エラー
                                                    ,1
                                                    ,5000);
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;                                            --# 任意 #
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END date_start_end_check;
--
--
  /**********************************************************************************
   * Procedure Name   : inventory_date_check
   * Description      : 17.出庫倉庫拠点品目日付での重複チェック
   ***********************************************************************************/
  PROCEDURE inventory_date_check(
    iv_forecast_designator  IN  VARCHAR2,        -- Forecast分類
-- add start 1.11
    iv_item_code            IN  VARCHAR2,        -- 品目
-- add end 1.11
-- add start 1.12
    id_start_date           IN  DATE,            -- 開始日付
-- add end 1.12
    ov_errbuf               OUT NOCOPY VARCHAR2, -- エラー・メッセージ           --# 固定 #
    ov_retcode              OUT NOCOPY VARCHAR2, -- リターン・コード             --# 固定 #
    ov_errmsg               OUT NOCOPY VARCHAR2) -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'inventory_date_check'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    ln_target_cnt  NUMBER;  -- 重複している件数
    ln_loop_cnt    NUMBER;  -- ループカウンタ
--
    -- *** ローカル・カーソル ***
    -- インターフェーステーブル重複データ抽出
    CURSOR forecast_if_cur
    IS
-- mod start 1.12
--      SELECT mfi.location_code,              -- 出荷倉庫
--      SELECT /*+ INDEX(xxinv_mrp_forecast_interface,xxinv_mfi_n02) */           -- 2008/11/11 統合指摘#589 Del
      SELECT /*+ INDEX( mfi xxinv_mfi_n02 ) */                                    -- 2008/11/11 統合指摘#589 Add
            mfi.location_code,              -- 出荷倉庫
            mfi.base_code,                   -- 拠点
            mfi.item_code,                   -- 品目
            mfi.forecast_date,               -- 開始日付
            mfi.forecast_end_date            -- 終了日付
      FROM  xxinv_mrp_forecast_interface  mfi
      WHERE mfi.created_by          = gn_created_by   -- ログインユーザ
--        AND mfi.forecast_designator = iv_forecast_designator
-- add start 1.11
        AND mfi.item_code           = iv_item_code
-- add end 1.11
        AND mfi.forecast_date       = id_start_date
        AND mfi.forecast_designator = iv_forecast_designator
-- mod end 1.12
      GROUP BY mfi.location_code,
            mfi.base_code,
            mfi.item_code,
            mfi.forecast_date,
            mfi.forecast_end_date
      HAVING COUNT(mfi.location_code) > 1;
--
    -- *** ローカル・レコード ***
    TYPE lr_forecast_if_rec IS RECORD(
      location_code         xxinv_mrp_forecast_interface.location_code%TYPE,    -- 出荷倉庫
      base_code             xxinv_mrp_forecast_interface.base_code%TYPE,        -- 拠点
      item_code             xxinv_mrp_forecast_interface.item_code%TYPE,        -- 品目
      forecast_date         xxinv_mrp_forecast_interface.forecast_date%TYPE,    -- 開始日付(DATE型)
      forecast_end_date     xxinv_mrp_forecast_interface.forecast_end_date%TYPE -- 終了日付(DATE型)
    );
--
    -- Forecast日付テーブルに登録するためのデータを格納する結合配列
    TYPE forecast_tbl IS TABLE OF lr_forecast_if_rec INDEX BY PLS_INTEGER;
    lt_if_data    forecast_tbl;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- 販売計画/引取計画インターフェーステーブルに作成者＝ログインユーザで
    -- 出荷倉庫、拠点、品目、開始日付、終了日付で重複しているデータがあればエラー
    -- 販売計画/引取計画インタ－フェーステーブルから重複データ抽出
    OPEN forecast_if_cur;
--
    -- データの一括取得
    FETCH forecast_if_cur BULK COLLECT INTO lt_if_data;
--
    -- 処理件数のセット
    ln_target_cnt := lt_if_data.COUNT;
--
    -- カーソルクローズ
    CLOSE forecast_if_cur;
--
    -- 重複データがなかった場合
    IF (ln_target_cnt = 0) THEN
      RAISE no_data;
      -- 重複データありの場合はデータをログに出力する
    ELSE
      <<duplication_data_loop>>
      FOR ln_loop_cnt IN 1..ln_target_cnt LOOP
        lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_inv   -- 'XXINV'
                                                      ,gv_msg_10a_039   -- 重複チェックエラー１
                                                      ,gv_tkn_soko      -- トークン'SOKO'
                                                      ,lt_if_data(ln_loop_cnt).location_code
                                                      ,gv_tkn_kyoten    -- トークン'KYOTEN'
                                                      ,lt_if_data(ln_loop_cnt).base_code
                                                      ,gv_tkn_item      -- トークン'ITEM'
                                                      ,lt_if_data(ln_loop_cnt).item_code
                                                      ,gv_tkn_sdate     -- トークン'SDATE'
                                                      ,lt_if_data(ln_loop_cnt).forecast_date
                                                      ,gv_tkn_edate     -- トークン'EDATE'
                                                      ,lt_if_data(ln_loop_cnt).forecast_end_date)
                                                      ,1
                                                      ,5000);
      END LOOP duplication_data_loop;
      RAISE duplication;
    END IF;
--
  EXCEPTION
    WHEN duplication THEN  -- 重複データありの場合
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;                                            --# 任意 #
--
    -- 重複していないので正常終了
    WHEN no_data THEN
      NULL;
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END inventory_date_check;
--
  /**********************************************************************************
   * Procedure Name   : base_code_date_check
   * Description      : 18.拠点品目日付での重複チェック
   ***********************************************************************************/
  PROCEDURE base_code_date_check(
    iv_forecast_designator  IN  VARCHAR2,        -- Forecast分類
    iv_base_code            IN  VARCHAR2,        -- 拠点
    iv_item_code            IN  VARCHAR2,        -- 品目
    id_start_date_active    IN  DATE,            -- 開始日付
    ov_errbuf               OUT NOCOPY VARCHAR2, -- エラー・メッセージ           --# 固定 #
    ov_retcode              OUT NOCOPY VARCHAR2, -- リターン・コード             --# 固定 #
    ov_errmsg               OUT NOCOPY VARCHAR2) -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'base_code_date_check'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    ln_target_cnt  NUMBER;  -- 重複している件数
    ln_loop_cnt    NUMBER;  -- ループカウンタ
--
    -- *** ローカル・カーソル ***
    -- 拠点、品目、開始日付で重複しているデータがあればエラー
    CURSOR forecast_if_cur
    IS
      SELECT /*+ INDEX( mfi xxinv_mfi_n03 ) */                         -- 2008/11/11 統合指摘#589 Add
             mfi.base_code,                    -- 拠点
             mfi.item_code,                    -- 品目
             mfi.forecast_date                 -- 開始日付
      FROM   xxinv_mrp_forecast_interface mfi
      WHERE  mfi.base_code     = iv_base_code
        AND  mfi.item_code     = iv_item_code
        AND  mfi.forecast_date = id_start_date_active
        AND  mfi.created_by    = gn_created_by   -- ログインユーザ'
        AND mfi.forecast_designator = iv_forecast_designator
      GROUP BY mfi.base_code,                  -- 拠点
               mfi.item_code,                  -- 品目
               mfi.forecast_date               -- 開始日付
      HAVING COUNT(mfi.base_code) > 1;
--
    -- *** ローカル・レコード ***
    TYPE lr_forecast_if_rec IS RECORD(
      base_code              xxinv_mrp_forecast_interface.base_code%TYPE,      -- 拠点
      item_code              xxinv_mrp_forecast_interface.item_code%TYPE,      -- 品目
      forecast_date          xxinv_mrp_forecast_interface.forecast_date%TYPE   -- 開始日付(DATE型)
    );
--
    -- Forecast日付テーブルに登録するためのデータを格納する結合配列
    TYPE forecast_tbl IS TABLE OF lr_forecast_if_rec INDEX BY PLS_INTEGER;
    lt_if_data    forecast_tbl;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- 販売計画/引取計画インタ－フェーステーブルから重複データ抽出
    OPEN forecast_if_cur;
--
    -- データの一括取得
    FETCH forecast_if_cur BULK COLLECT INTO lt_if_data;
--
    -- 処理件数のセット
    ln_target_cnt := lt_if_data.COUNT;
--
    -- カーソルクローズ
    CLOSE forecast_if_cur;
--
    -- 重複データがなかった場合
    IF (ln_target_cnt = 0) THEN
      RAISE no_data;
      -- 重複データありの場合はデータをログに出力する
    ELSE
      <<duplication_data_loop>>
      FOR ln_loop_cnt IN 1..ln_target_cnt LOOP
        lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_inv   -- 'XXINV'
                                                      ,gv_msg_10a_040   -- 重複チェックエラー2
                                                      ,gv_tkn_kyoten    -- トークン'KYOTEN'
                                                      ,lt_if_data(ln_loop_cnt).base_code
                                                      ,gv_tkn_item      -- トークン'ITEM'
                                                      ,lt_if_data(ln_loop_cnt).item_code
                                                      ,gv_tkn_sdate     -- トークン'SDATE'
                                                      ,lt_if_data(ln_loop_cnt).forecast_date)
                                                      ,1
                                                      ,5000);
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      END LOOP duplication_data_loop;
      RAISE duplication;
    END IF;
--
  EXCEPTION
    WHEN duplication THEN                           --*** 重複しているデータあり ***
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;                                            --# 任意 #
--
    -- 重複していないので正常終了
    WHEN no_data THEN
      NULL;
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END base_code_date_check;
--
--
  /**********************************************************************************
   * Procedure Name   : quantity_num_check
   * Description      : 19.数量のマイナス数値チェック
   ***********************************************************************************/
  PROCEDURE quantity_num_check(
    iv_forecast_designator   IN  VARCHAR2,        -- Forecast分類
    in_case_quantity         IN  NUMBER,          -- ケース数量
    in_quantity              IN  NUMBER,          -- バラ数量
    ov_errbuf                OUT NOCOPY VARCHAR2, -- エラー・メッセージ           --# 固定 #
    ov_retcode               OUT NOCOPY VARCHAR2, -- リターン・コード             --# 固定 #
    ov_errmsg                OUT NOCOPY VARCHAR2) -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'quantity_num_check'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- ケース数量がマイナスだったらエラーとする
    IF (in_case_quantity < 0) THEN
      RAISE quantity_expt;
    END IF;
--
    -- バラ数量がマイナスだったらエラーとする
    IF (in_quantity < 0) THEN
      RAISE quantity_expt;
    END IF;
--
  EXCEPTION
--
   --*** ケース数量またはバラ数量がマイナス例外 ***
    WHEN quantity_expt THEN
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_inv       -- 'XXINV'
                                                    ,gv_msg_10a_041       -- 数値チェックエラー
                                                    ,gv_tkn_case          -- トークン'CASE'
                                                    ,in_case_quantity     -- ケース数量
                                                    ,gv_tkn_bara          -- トークン'BARA'
                                                    ,in_quantity)         -- バラ数量
                                                    ,1
                                                    ,5000);
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
--
    -- Forecast分類が「販売計画」のみワーニングとする（その他はエラー）
      IF (iv_forecast_designator = gv_cons_fc_type_hanbai) THEN
        ov_retcode := gv_status_warn;
      ELSE
        ov_retcode := gv_status_error;
      END IF;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END quantity_num_check;
--
  /**********************************************************************************
   * Procedure Name   : price_num_check
   * Description      : 20.金額のマイナス数値警告チェック
   ***********************************************************************************/
  PROCEDURE price_num_check(
    iv_forecast_designator   IN  VARCHAR2,        -- Forecast分類
    in_amount                IN  NUMBER,          -- 金額
    ov_errbuf                OUT NOCOPY VARCHAR2, -- エラー・メッセージ           --# 固定 #
    ov_retcode               OUT NOCOPY VARCHAR2, -- リターン・コード             --# 固定 #
    ov_errmsg                OUT NOCOPY VARCHAR2) -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'price_num_check'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- 金額がマイナスだったらエラーとする
    IF (in_amount < 0) THEN
      RAISE amount_expt;
    END IF;
--
  EXCEPTION
    --*** 金額がマイナス例外 ***
    WHEN amount_expt THEN
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_inv    -- 'XXINV'
                                                  ,gv_msg_10a_073)      -- 数値チェックエラー
                                                  ,1
                                                  ,5000);
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_warn;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END price_num_check;
--
  /**********************************************************************************
   * Procedure Name   : hikitori_data_check
   * Description      : 引取計画抽出データチェック(A-2-2)
   ***********************************************************************************/
  PROCEDURE hikitori_data_check(
    in_if_data_tbl        IN  forecast_tbl,
    in_if_data_cnt        IN  NUMBER,           -- 処理中のIFデータカウンタ
    ov_errbuf             OUT NOCOPY VARCHAR2,  -- エラー・メッセージ            --# 固定 #
    ov_retcode            OUT NOCOPY VARCHAR2,  -- リターン・コード              --# 固定 #
    ov_errmsg             OUT NOCOPY VARCHAR2)  -- ユーザー・エラー・メッセージ  --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'hikitori_data_check'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    ln_warn_cnt  NUMBER;
    ln_error_cnt NUMBER;
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
    ln_warn_cnt  := 0;
    ln_error_cnt := 0;
--
    -- 1.出庫倉庫の適用日と開始日付チェック
    shipped_date_start_check( -- Forecast分類
                              in_if_data_tbl(in_if_data_cnt).forecast_designator,
                              -- 出荷倉庫
                              in_if_data_tbl(in_if_data_cnt).location_code,
                              -- 開始日付
                              in_if_data_tbl(in_if_data_cnt).start_date_active,
                              -- 終了日付
                              in_if_data_tbl(in_if_data_cnt).end_date_active,
                              lv_errbuf,
                              lv_retcode,
                              lv_errmsg);
    -- 警告およびエラーであればログを出力し処理続行
    IF (lv_retcode <> gv_status_normal) THEN
      if_data_disp( in_if_data_tbl, in_if_data_cnt);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf);
    END IF;
    -- 警告およびエラー件数を保存
    IF (lv_retcode = gv_status_warn) THEN
      ln_warn_cnt := 1;
    ELSIF (lv_retcode = gv_status_error) THEN
      ln_error_cnt := 1;
    END IF;
    -- システムエラー(オラクルエラー)の場合はここで処理を中止してエラーリターンする。
    IF ((lv_retcode = gv_status_error ) AND ( lv_errmsg IS NULL )) THEN
      -- エラー件数は1として例外処理へ
      gn_error_cnt := 1;
      RAISE global_api_expt;
    END IF;
--
    -- 2.出庫倉庫の出庫管理元区分チェック
   shipped_class_check( -- Forecast分類
                         in_if_data_tbl(in_if_data_cnt).forecast_designator,
                         -- 品目
                         in_if_data_tbl(in_if_data_cnt).item_code,
                         -- 出荷倉庫
                         in_if_data_tbl(in_if_data_cnt).location_code,
                         lv_errbuf,
                         lv_retcode,
                         lv_errmsg);
    -- 警告およびエラーであればログを出力し処理続行
    IF (lv_retcode <> gv_status_normal) THEN
      if_data_disp( in_if_data_tbl, in_if_data_cnt);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf);
    END IF;
    -- 警告およびエラー件数を保存
    IF (lv_retcode = gv_status_warn) THEN
      ln_warn_cnt := 1;
    ELSIF (lv_retcode = gv_status_error) THEN
      ln_error_cnt := 1;
    END IF;
    -- システムエラー(オラクルエラー)の場合はここで処理を中止してエラーリターンする。
    IF ((lv_retcode = gv_status_error ) AND ( lv_errmsg IS NULL )) THEN
      -- エラー件数は1として例外処理へ
      gn_error_cnt := 1;
      RAISE global_api_expt;
    END IF;
--
    -- 3.拠点の存在チェック
    base_code_exist_check(-- Forecast分類
                          in_if_data_tbl(in_if_data_cnt).forecast_designator,
                          -- 拠点コード
                          in_if_data_tbl(in_if_data_cnt).base_code,
                          lv_errbuf,
                          lv_retcode,
                          lv_errmsg);
    -- 警告およびエラーであればログを出力し処理続行
    IF (lv_retcode <> gv_status_normal) THEN
      if_data_disp( in_if_data_tbl, in_if_data_cnt);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf);
    END IF;
    -- 警告およびエラー件数を保存
    IF (lv_retcode = gv_status_warn) THEN
      ln_warn_cnt := 1;
    ELSIF (lv_retcode = gv_status_error) THEN
      ln_error_cnt := 1;
    END IF;
    -- システムエラー(オラクルエラー)の場合はここで処理を中止してエラーリターンする。
    IF ((lv_retcode = gv_status_error ) AND ( lv_errmsg IS NULL )) THEN
      -- エラー件数は1として例外処理へ
      gn_error_cnt := 1;
      RAISE global_api_expt;
    END IF;
--
    -- 4.品目の廃止区分チェック
    item_abolition_code_check(-- Forecast分類
                              in_if_data_tbl(in_if_data_cnt).forecast_designator,
                              -- 品目
                              in_if_data_tbl(in_if_data_cnt).item_code,
                              -- 開始日付
                              in_if_data_tbl(in_if_data_cnt).start_date_active,
                              lv_errbuf,
                              lv_retcode,
                              lv_errmsg);
    -- 警告およびエラーであればログを出力し処理続行
    IF (lv_retcode <> gv_status_normal) THEN
      if_data_disp( in_if_data_tbl, in_if_data_cnt);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf);
    END IF;
    -- 警告およびエラー件数を保存
    IF (lv_retcode = gv_status_warn) THEN
      ln_warn_cnt := 1;
    ELSIF (lv_retcode = gv_status_error) THEN
      ln_error_cnt := 1;
    END IF;
    -- システムエラー(オラクルエラー)の場合はここで処理を中止してエラーリターンする。
    IF ((lv_retcode = gv_status_error ) AND ( lv_errmsg IS NULL )) THEN
      -- エラー件数は1として例外処理へ
      gn_error_cnt := 1;
      RAISE global_api_expt;
    END IF;
--
    -- 5.品目の品目区分チェック
    item_class_check( -- Forecast分類
                      in_if_data_tbl(in_if_data_cnt).forecast_designator,
                      -- 品目
                      in_if_data_tbl(in_if_data_cnt).item_code,
                      -- 開始日付
                      in_if_data_tbl(in_if_data_cnt).start_date_active,
                      lv_errbuf,
                      lv_retcode,
                      lv_errmsg);
    -- 警告およびエラーであればログを出力し処理続行
    IF (lv_retcode <> gv_status_normal) THEN
      if_data_disp( in_if_data_tbl, in_if_data_cnt);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf);
    END IF;
    -- 警告およびエラー件数を保存
    IF (lv_retcode = gv_status_warn) THEN
      ln_warn_cnt := 1;
    ELSIF (lv_retcode = gv_status_error) THEN
      ln_error_cnt := 1;
    END IF;
    -- システムエラー(オラクルエラー)の場合はここで処理を中止してエラーリターンする。
    IF ((lv_retcode = gv_status_error ) AND ( lv_errmsg IS NULL )) THEN
      -- エラー件数は1として例外処理へ
      gn_error_cnt := 1;
      RAISE global_api_expt;
    END IF;
--
    -- 6.品目の適用日と開始日付チェック
    item_date_start_check( -- Forecast分類
                           in_if_data_tbl(in_if_data_cnt).forecast_designator,
                           -- 品目
                           in_if_data_tbl(in_if_data_cnt).item_code,
                           -- 開始日付
                           in_if_data_tbl(in_if_data_cnt).start_date_active,
                           lv_errbuf,
                           lv_retcode,
                           lv_errmsg);
    -- 警告およびエラーであればログを出力し処理続行
    IF (lv_retcode <> gv_status_normal) THEN
      if_data_disp( in_if_data_tbl, in_if_data_cnt);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf);
    END IF;
    -- 警告およびエラー件数を保存
    IF (lv_retcode = gv_status_warn) THEN
      ln_warn_cnt := 1;
    ELSIF (lv_retcode = gv_status_error) THEN
      ln_error_cnt := 1;
    END IF;
    -- システムエラー(オラクルエラー)の場合はここで処理を中止してエラーリターンする。
    IF ((lv_retcode = gv_status_error ) AND ( lv_errmsg IS NULL )) THEN
      -- エラー件数は1として例外処理へ
      gn_error_cnt := 1;
      RAISE global_api_expt;
    END IF;
--
    -- 11.品目の物流構成表未登録の警告チェック
    item_not_regist_check( -- Forecast分類
                           in_if_data_tbl(in_if_data_cnt).forecast_designator,
                           -- 品目
                           in_if_data_tbl(in_if_data_cnt).item_code,
                           -- 拠点コード
                           in_if_data_tbl(in_if_data_cnt).base_code,
                           -- 出荷倉庫
                           in_if_data_tbl(in_if_data_cnt).location_code,
                           -- 開始日付
                           in_if_data_tbl(in_if_data_cnt).start_date_active,
                           -- 終了日付
                           in_if_data_tbl(in_if_data_cnt).end_date_active,
                           lv_errbuf,
                           lv_retcode,
                           lv_errmsg);
    -- 警告およびエラーであればログを出力し処理続行
    IF (lv_retcode <> gv_status_normal) THEN
      if_data_disp( in_if_data_tbl, in_if_data_cnt);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf);
    END IF;
    -- 警告およびエラー件数を保存
    IF (lv_retcode = gv_status_warn) THEN
      ln_warn_cnt := 1;
    ELSIF (lv_retcode = gv_status_error) THEN
      ln_error_cnt := 1;
    END IF;
    -- システムエラー(オラクルエラー)の場合はここで処理を中止してエラーリターンする。
    IF ((lv_retcode = gv_status_error ) AND ( lv_errmsg IS NULL )) THEN
      -- エラー件数は1として例外処理へ
      gn_error_cnt := 1;
      RAISE global_api_expt;
    END IF;
--
    -- 12.日付の対象月チェック
    date_month_check( -- Forecast分類
                      in_if_data_tbl(in_if_data_cnt).forecast_designator,
                      -- 開始日付
                      in_if_data_tbl(in_if_data_cnt).start_date_active,
                      lv_errbuf,
                      lv_retcode,
                      lv_errmsg);
    -- 警告およびエラーであればログを出力し処理続行
    IF (lv_retcode <> gv_status_normal) THEN
      if_data_disp( in_if_data_tbl, in_if_data_cnt);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf);
    END IF;
    -- 警告およびエラー件数を保存
    IF (lv_retcode = gv_status_warn) THEN
      ln_warn_cnt := 1;
    ELSIF (lv_retcode = gv_status_error) THEN
      ln_error_cnt := 1;
    END IF;
    -- システムエラー(オラクルエラー)の場合はここで処理を中止してエラーリターンする。
    IF ((lv_retcode = gv_status_error ) AND ( lv_errmsg IS NULL )) THEN
      -- エラー件数は1として例外処理へ
      gn_error_cnt := 1;
      RAISE global_api_expt;
    END IF;
--
    -- 17.出庫倉庫拠点品目日付での重複チェック
    inventory_date_check( -- Forecast分類
                          in_if_data_tbl(in_if_data_cnt).forecast_designator,
-- add start 1.11
                          in_if_data_tbl(in_if_data_cnt).item_code,
-- add end 1.11
-- add start 1.12
                          in_if_data_tbl(in_if_data_cnt).start_date_active,
-- add end 1.12
                          lv_errbuf,
                          lv_retcode,
                          lv_errmsg
    );
    -- 警告およびエラーであればログを出力し処理続行
    IF (lv_retcode <> gv_status_normal) THEN
      if_data_disp( in_if_data_tbl, in_if_data_cnt);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf);
    END IF;
    -- 警告およびエラー件数を保存
    IF (lv_retcode = gv_status_warn) THEN
      ln_warn_cnt := 1;
    ELSIF (lv_retcode = gv_status_error) THEN
      ln_error_cnt := 1;
    END IF;
    -- システムエラー(オラクルエラー)の場合はここで処理を中止してエラーリターンする。
    IF ((lv_retcode = gv_status_error ) AND ( lv_errmsg IS NULL )) THEN
      -- エラー件数は1として例外処理へ
      gn_error_cnt := 1;
      RAISE global_api_expt;
    END IF;
--
    -- 19.数量のマイナス数値チェック
    quantity_num_check( -- Forecast分類
                        in_if_data_tbl(in_if_data_cnt).forecast_designator,
                        -- ケース数量
                        in_if_data_tbl(in_if_data_cnt).case_quantity,
                        -- バラ数量
                        in_if_data_tbl(in_if_data_cnt).quantity,
                        lv_errbuf,
                        lv_retcode,
                        lv_errmsg
    );
    -- 警告およびエラーであればログを出力し処理続行
    IF (lv_retcode <> gv_status_normal) THEN
      if_data_disp( in_if_data_tbl, in_if_data_cnt);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf);
    END IF;
    -- 警告およびエラー件数を保存
    IF (lv_retcode = gv_status_warn) THEN
      ln_warn_cnt := 1;
    ELSIF (lv_retcode = gv_status_error) THEN
      ln_error_cnt := 1;
    END IF;
    -- システムエラー(オラクルエラー)の場合はここで処理を中止してエラーリターンする。
    IF ((lv_retcode = gv_status_error ) AND ( lv_errmsg IS NULL )) THEN
      -- エラー件数は1として例外処理へ
      gn_error_cnt := 1;
      RAISE global_api_expt;
    END IF;
--
-- 2009/02/17 本番障害#38対応 ADD Start --
    -- A-2-3 引取計画Forecast名抽出
    -- (Forcast名チェック)
    get_f_degi_hikitori(    in_if_data_tbl  => in_if_data_tbl -- Forcast登録用配列
                          , in_if_data_cnt  => in_if_data_cnt -- 処理中のデータカウンタ
                          , ov_errbuf       => lv_errbuf
                          , ov_retcode      => lv_retcode
                          , ov_errmsg       => lv_errmsg 
                        );
    -- 警告およびエラーであればログを出力し処理続行
    IF (lv_retcode <> gv_status_normal) THEN
      if_data_disp( in_if_data_tbl, in_if_data_cnt);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf);
    END IF;
    -- 警告およびエラー件数を保存
    IF (lv_retcode = gv_status_warn) THEN
      ln_warn_cnt := 1;
    ELSIF (lv_retcode = gv_status_error) THEN
      ln_error_cnt := 1;
    END IF;
    -- システムエラー(オラクルエラー)の場合はここで処理を中止してエラーリターンする。
    IF ((lv_retcode = gv_status_error ) AND ( lv_errmsg IS NULL )) THEN
      -- エラー件数は1として例外処理へ
      gn_error_cnt := 1;
      RAISE global_api_expt;
    END IF;
-- 2009/02/17 本番障害#38対応 ADD End   --
    -- 各チェックにてエラーまたは警告が発生していたらリターン値に
    -- エラーまたは警告をセットする。
    IF (ln_warn_cnt > 0) THEN
      ov_retcode := gv_status_warn;
      gn_warn_cnt := gn_warn_cnt + 1;
      gn_no_msg_disp := 1;
    END IF;
    IF (ln_error_cnt > 0) THEN
      ov_retcode := gv_status_error;
      gn_error_cnt := gn_error_cnt + 1;
      gn_no_msg_disp := 1;
    END IF;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
      gn_error_cnt := gn_error_cnt + 1;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
      gn_error_cnt := gn_error_cnt + 1;
--
--#####################################  固定部 END   ##########################################
--
  END hikitori_data_check;
--
  /**********************************************************************************
   * Procedure Name   : hanbai_data_check
   * Description      : 販売計画抽出データチェック(A-3-2)
   ***********************************************************************************/
  PROCEDURE hanbai_data_check(
    in_if_data_tbl        IN  forecast_tbl,
    in_if_data_cnt        IN  NUMBER,           -- 処理中のIFデータカウンタ
    ov_errbuf             OUT NOCOPY VARCHAR2,  -- エラー・メッセージ           --# 固定 #
    ov_retcode            OUT NOCOPY VARCHAR2,  -- リターン・コード             --# 固定 #
    ov_errmsg             OUT NOCOPY VARCHAR2)  -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'hanbai_data_check'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    ln_warn_cnt  NUMBER;
    ln_error_cnt NUMBER;
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
    ln_warn_cnt  := 0;
    ln_error_cnt := 0;
--
    -- 3.拠点の存在チェック
    base_code_exist_check(-- Forecast分類
                          in_if_data_tbl(in_if_data_cnt).forecast_designator,
                          -- 拠点コード
                          in_if_data_tbl(in_if_data_cnt).base_code,
                          lv_errbuf,
                          lv_retcode,
                          lv_errmsg);
    -- 警告およびエラーであればログを出力し処理続行
    IF (lv_retcode <> gv_status_normal) THEN
      if_data_disp( in_if_data_tbl, in_if_data_cnt);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf);
    END IF;
    -- 警告およびエラー件数を保存
    IF (lv_retcode = gv_status_warn) THEN
      ln_warn_cnt := 1;
    ELSIF (lv_retcode = gv_status_error) THEN
      ln_error_cnt := 1;
    END IF;
    -- システムエラー(オラクルエラー)の場合はここで処理を中止してエラーリターンする。
    IF ((lv_retcode = gv_status_error ) AND ( lv_errmsg IS NULL )) THEN
      -- エラー件数は1として例外処理へ
      gn_error_cnt := 1;
      RAISE global_api_expt;
    END IF;
--
    -- 4.品目の廃止区分チェック
    item_abolition_code_check(-- Forecast分類
                              in_if_data_tbl(in_if_data_cnt).forecast_designator,
                              -- 品目
                              in_if_data_tbl(in_if_data_cnt).item_code,
                              -- 開始日付
                              in_if_data_tbl(in_if_data_cnt).start_date_active,
                              lv_errbuf,
                              lv_retcode,
                              lv_errmsg);
    -- 警告およびエラーであればログを出力し処理続行
    IF (lv_retcode <> gv_status_normal) THEN
      if_data_disp( in_if_data_tbl, in_if_data_cnt);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf);
    END IF;
    -- 警告およびエラー件数を保存
    IF (lv_retcode = gv_status_warn) THEN
      ln_warn_cnt := 1;
    ELSIF (lv_retcode = gv_status_error) THEN
      ln_error_cnt := 1;
    END IF;
    -- システムエラー(オラクルエラー)の場合はここで処理を中止してエラーリターンする。
    IF ((lv_retcode = gv_status_error ) AND ( lv_errmsg IS NULL )) THEN
      -- エラー件数は1として例外処理へ
      gn_error_cnt := 1;
      RAISE global_api_expt;
    END IF;
--
    -- 5.品目の品目区分チェック
    item_class_check( -- Forecast分類
                      in_if_data_tbl(in_if_data_cnt).forecast_designator,
                      -- 品目
                      in_if_data_tbl(in_if_data_cnt).item_code,
                      -- 開始日付
                      in_if_data_tbl(in_if_data_cnt).start_date_active,
                      lv_errbuf,
                      lv_retcode,
                      lv_errmsg);
    -- 警告およびエラーであればログを出力し処理続行
    IF (lv_retcode <> gv_status_normal) THEN
      if_data_disp( in_if_data_tbl, in_if_data_cnt);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf);
    END IF;
    -- 警告およびエラー件数を保存
    IF (lv_retcode = gv_status_warn) THEN
      ln_warn_cnt := 1;
    ELSIF (lv_retcode = gv_status_error) THEN
      ln_error_cnt := 1;
    END IF;
    -- システムエラー(オラクルエラー)の場合はここで処理を中止してエラーリターンする。
    IF ((lv_retcode = gv_status_error ) AND ( lv_errmsg IS NULL )) THEN
      -- エラー件数は1として例外処理へ
      gn_error_cnt := 1;
      RAISE global_api_expt;
    END IF;
--
    -- 7.品目の適用日と年度警告チェック
    item_date_year_check(-- Forecast分類
                         in_if_data_tbl(in_if_data_cnt).forecast_designator,
                         -- 品目
                         in_if_data_tbl(in_if_data_cnt).item_code,
                         lv_errbuf,
                         lv_retcode,
                         lv_errmsg);
    -- 警告およびエラーであればログを出力し処理続行
    IF (lv_retcode <> gv_status_normal) THEN
      if_data_disp( in_if_data_tbl, in_if_data_cnt);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf);
    END IF;
    -- 警告およびエラー件数を保存
    IF (lv_retcode = gv_status_warn) THEN
      ln_warn_cnt := 1;
    ELSIF (lv_retcode = gv_status_error) THEN
      ln_error_cnt := 1;
    END IF;
    -- システムエラー(オラクルエラー)の場合はここで処理を中止してエラーリターンする。
    IF ((lv_retcode = gv_status_error ) AND ( lv_errmsg IS NULL )) THEN
      -- エラー件数は1として例外処理へ
      gn_error_cnt := 1;
      RAISE global_api_expt;
    END IF;
--
    -- 8.品目の標準原価適用日と年度警告チェック
    item_standard_year_check(-- Forecast分類
                             in_if_data_tbl(in_if_data_cnt).forecast_designator,
                             -- 品目
                             in_if_data_tbl(in_if_data_cnt).item_code,
                             lv_errbuf,
                             lv_retcode,
                             lv_errmsg);
    -- 警告およびエラーであればログを出力し処理続行
    IF (lv_retcode <> gv_status_normal) THEN
      if_data_disp( in_if_data_tbl, in_if_data_cnt);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf);
    END IF;
    -- 警告およびエラー件数を保存
    IF (lv_retcode = gv_status_warn) THEN
      ln_warn_cnt := 1;
    ELSIF (lv_retcode = gv_status_error) THEN
      ln_error_cnt := 1;
    END IF;
    -- システムエラー(オラクルエラー)の場合はここで処理を中止してエラーリターンする。
    IF ((lv_retcode = gv_status_error ) AND ( lv_errmsg IS NULL )) THEN
      -- エラー件数は1として例外処理へ
      gn_error_cnt := 1;
      RAISE global_api_expt;
    END IF;
--
    -- 13.日付の対象年チェック
    date_year_check(-- Forecast分類
                    in_if_data_tbl(in_if_data_cnt).forecast_designator,
                    -- 開始日付
                    in_if_data_tbl(in_if_data_cnt).start_date_active,
                    lv_errbuf,
                    lv_retcode,
                    lv_errmsg);
    -- 警告およびエラーであればログを出力し処理続行
    IF (lv_retcode <> gv_status_normal) THEN
      if_data_disp( in_if_data_tbl, in_if_data_cnt);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf);
    END IF;
    -- 警告およびエラー件数を保存
    IF (lv_retcode = gv_status_warn) THEN
      ln_warn_cnt := 1;
    ELSIF (lv_retcode = gv_status_error) THEN
      ln_error_cnt := 1;
    END IF;
    -- システムエラー(オラクルエラー)の場合はここで処理を中止してエラーリターンする。
    IF ((lv_retcode = gv_status_error ) AND ( lv_errmsg IS NULL )) THEN
      -- エラー件数は1として例外処理へ
      gn_error_cnt := 1;
      RAISE global_api_expt;
    END IF;
--
    -- 18.拠点品目日付での重複チェック
    base_code_date_check(-- Forecast分類
                         in_if_data_tbl(in_if_data_cnt).forecast_designator,
                         -- 拠点コード
                         in_if_data_tbl(in_if_data_cnt).base_code,
                         -- 品目
                         in_if_data_tbl(in_if_data_cnt).item_code,
                         -- 開始日付
                         in_if_data_tbl(in_if_data_cnt).start_date_active,
                         lv_errbuf,
                         lv_retcode,
                         lv_errmsg);
    -- 警告およびエラーであればログを出力し処理続行
    IF (lv_retcode <> gv_status_normal) THEN
      if_data_disp( in_if_data_tbl, in_if_data_cnt);
-- mod start 1.11
--      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
-- mod end 1.11
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf);
    END IF;
    -- 警告およびエラー件数を保存
    IF (lv_retcode = gv_status_warn) THEN
      ln_warn_cnt := 1;
    ELSIF (lv_retcode = gv_status_error) THEN
      ln_error_cnt := 1;
    END IF;
    -- システムエラー(オラクルエラー)の場合はここで処理を中止してエラーリターンする。
    IF ((lv_retcode = gv_status_error ) AND ( lv_errmsg IS NULL )) THEN
      -- エラー件数は1として例外処理へ
      gn_error_cnt := 1;
      RAISE global_api_expt;
    END IF;
--
    -- 19.数量のマイナス数値チェック
    quantity_num_check( -- Forecast分類
                        in_if_data_tbl(in_if_data_cnt).forecast_designator,
                        -- ケース数量 
                        in_if_data_tbl(in_if_data_cnt).case_quantity,
                        -- バラ数量
                        in_if_data_tbl(in_if_data_cnt).quantity,
                        lv_errbuf,
                        lv_retcode,
                        lv_errmsg);
    -- 警告およびエラーであればログを出力し処理続行
    IF (lv_retcode <> gv_status_normal) THEN
      if_data_disp( in_if_data_tbl, in_if_data_cnt);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf);
    END IF;
    -- 警告およびエラー件数を保存
    IF (lv_retcode = gv_status_warn) THEN
      ln_warn_cnt := 1;
    ELSIF (lv_retcode = gv_status_error) THEN
      ln_error_cnt := 1;
    END IF;
    -- システムエラー(オラクルエラー)の場合はここで処理を中止してエラーリターンする。
    IF ((lv_retcode = gv_status_error ) AND ( lv_errmsg IS NULL )) THEN
      -- エラー件数は1として例外処理へ
      gn_error_cnt := 1;
      RAISE global_api_expt;
    END IF;
--
    -- 20.金額のマイナス数値警告チェック
    price_num_check(-- Forecast分類
                    in_if_data_tbl(in_if_data_cnt).forecast_designator,
                    -- 金額 
                    in_if_data_tbl(in_if_data_cnt).price,
                    lv_errbuf,
                    lv_retcode,
                    lv_errmsg);
    -- 警告およびエラーであればログを出力し処理続行
    IF (lv_retcode <> gv_status_normal) THEN
      if_data_disp( in_if_data_tbl, in_if_data_cnt);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf);
    END IF;
    -- 警告およびエラー件数を保存
    IF (lv_retcode = gv_status_warn) THEN
      ln_warn_cnt := 1;
    ELSIF (lv_retcode = gv_status_error) THEN
      ln_error_cnt := 1;
    END IF;
    -- システムエラー(オラクルエラー)の場合はここで処理を中止してエラーリターンする。
    IF ((lv_retcode = gv_status_error ) AND ( lv_errmsg IS NULL )) THEN
      -- エラー件数は1として例外処理へ
      gn_error_cnt := 1;
      RAISE global_api_expt;
    END IF;
--
    -- 各チェックにてエラーまたは警告が発生していたらリターン値に
    -- エラーまたは警告をセットする。
    IF (ln_warn_cnt > 0) THEN
      ov_retcode := gv_status_warn;
      gn_warn_cnt := gn_warn_cnt + 1;
      gn_no_msg_disp := 1;
    END IF;
    IF (ln_error_cnt > 0) THEN
      ov_retcode := gv_status_error;
      gn_error_cnt := gn_error_cnt + 1;
      gn_no_msg_disp := 1;
    END IF;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
      gn_error_cnt := gn_error_cnt + 1;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
      gn_error_cnt := gn_error_cnt + 1;
--
--#####################################  固定部 END   ##########################################
--
  END hanbai_data_check;
--
  /**********************************************************************************
   * Procedure Name   : keikaku_data_check
   * Description      : 計画商品抽出データチェック(A-4-2)
   ***********************************************************************************/
  PROCEDURE keikaku_data_check(
    in_if_data_tbl        IN  forecast_tbl,
    in_if_data_cnt        IN  NUMBER,           -- 処理中のIFデータカウンタ
    ov_errbuf             OUT NOCOPY VARCHAR2,  -- エラー・メッセージ            --# 固定 #
    ov_retcode            OUT NOCOPY VARCHAR2,  -- リターン・コード              --# 固定 #
    ov_errmsg             OUT NOCOPY VARCHAR2)  -- ユーザー・エラー・メッセージ  --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'keikaku_data_check'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    ln_warn_cnt  NUMBER;
    ln_error_cnt NUMBER;
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
    ln_warn_cnt  := 0;
    ln_error_cnt := 0;
--
    -- 1.出庫倉庫の適用日と開始日付チェック
    shipped_date_start_check( -- Forecast分類
                              in_if_data_tbl(in_if_data_cnt).forecast_designator,
                              -- 出荷倉庫
                              in_if_data_tbl(in_if_data_cnt).location_code,
                              -- 開始日付
                              in_if_data_tbl(in_if_data_cnt).start_date_active,
                              -- 終了日付
                              in_if_data_tbl(in_if_data_cnt).end_date_active,
                              lv_errbuf,
                              lv_retcode,
                              lv_errmsg);
    -- 警告およびエラーであればログを出力し処理続行
    IF (lv_retcode <> gv_status_normal) THEN
      if_data_disp( in_if_data_tbl, in_if_data_cnt);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf);
    END IF;
    -- 警告およびエラー件数を保存
    IF (lv_retcode = gv_status_warn) THEN
      ln_warn_cnt := 1;
    ELSIF (lv_retcode = gv_status_error) THEN
      ln_error_cnt := 1;
    END IF;
    -- システムエラー(オラクルエラー)の場合はここで処理を中止してエラーリターンする。
    IF ((lv_retcode = gv_status_error ) AND ( lv_errmsg IS NULL )) THEN
      -- エラー件数は1として例外処理へ
      gn_error_cnt := 1;
      RAISE global_api_expt;
    END IF;
--
    -- 2.出庫倉庫の出庫管理元区分チェック
    shipped_class_check( -- Forecast分類
                         in_if_data_tbl(in_if_data_cnt).forecast_designator,
                         -- 品目
                         in_if_data_tbl(in_if_data_cnt).item_code,
                         -- 出荷倉庫
                         in_if_data_tbl(in_if_data_cnt).location_code,
                         lv_errbuf,
                         lv_retcode,
                         lv_errmsg);
    -- 警告およびエラーであればログを出力し処理続行
    IF (lv_retcode <> gv_status_normal) THEN
      if_data_disp( in_if_data_tbl, in_if_data_cnt);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf);
    END IF;
    -- 警告およびエラー件数を保存
    IF (lv_retcode = gv_status_warn) THEN
      ln_warn_cnt := 1;
    ELSIF (lv_retcode = gv_status_error) THEN
      ln_error_cnt := 1;
    END IF;
    -- システムエラー(オラクルエラー)の場合はここで処理を中止してエラーリターンする。
    IF ((lv_retcode = gv_status_error ) AND ( lv_errmsg IS NULL )) THEN
      -- エラー件数は1として例外処理へ
      gn_error_cnt := 1;
      RAISE global_api_expt;
    END IF;
--
    -- 3.拠点の存在チェック
    base_code_exist_check(-- Forecast分類
                          in_if_data_tbl(in_if_data_cnt).forecast_designator,
                          -- 拠点コード
                          in_if_data_tbl(in_if_data_cnt).base_code,
                          lv_errbuf,
                          lv_retcode,
                          lv_errmsg);
    -- 警告およびエラーであればログを出力し処理続行
    IF (lv_retcode <> gv_status_normal) THEN
      if_data_disp( in_if_data_tbl, in_if_data_cnt);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf);
    END IF;
    -- 警告およびエラー件数を保存
    IF (lv_retcode = gv_status_warn) THEN
      ln_warn_cnt := 1;
    ELSIF (lv_retcode = gv_status_error) THEN
      ln_error_cnt := 1;
    END IF;
    -- システムエラー(オラクルエラー)の場合はここで処理を中止してエラーリターンする。
    IF ((lv_retcode = gv_status_error ) AND ( lv_errmsg IS NULL )) THEN
      -- エラー件数は1として例外処理へ
      gn_error_cnt := 1;
      RAISE global_api_expt;
    END IF;
--
    -- 4.品目の廃止区分チェック
    item_abolition_code_check(-- Forecast分類
                              in_if_data_tbl(in_if_data_cnt).forecast_designator,
                              -- 品目
                              in_if_data_tbl(in_if_data_cnt).item_code,
                              -- 開始日付
                              in_if_data_tbl(in_if_data_cnt).start_date_active,
                              lv_errbuf,
                              lv_retcode,
                              lv_errmsg);
    -- 警告およびエラーであればログを出力し処理続行
    IF (lv_retcode <> gv_status_normal) THEN
      if_data_disp( in_if_data_tbl, in_if_data_cnt);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf);
    END IF;
    -- 警告およびエラー件数を保存
    IF (lv_retcode = gv_status_warn) THEN
      ln_warn_cnt := 1;
    ELSIF (lv_retcode = gv_status_error) THEN
      ln_error_cnt := 1;
    END IF;
    -- システムエラー(オラクルエラー)の場合はここで処理を中止してエラーリターンする。
    IF ((lv_retcode = gv_status_error ) AND ( lv_errmsg IS NULL )) THEN
      -- エラー件数は1として例外処理へ
      gn_error_cnt := 1;
      RAISE global_api_expt;
    END IF;
--
    -- 5.品目の品目区分チェック
    item_class_check( -- Forecast分類
                      in_if_data_tbl(in_if_data_cnt).forecast_designator,
                      -- 品目
                      in_if_data_tbl(in_if_data_cnt).item_code,
                      -- 開始日付
                      in_if_data_tbl(in_if_data_cnt).start_date_active,
                      lv_errbuf,
                      lv_retcode,
                      lv_errmsg);
    -- 警告およびエラーであればログを出力し処理続行
    IF (lv_retcode <> gv_status_normal) THEN
      if_data_disp( in_if_data_tbl, in_if_data_cnt);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf);
    END IF;
    -- 警告およびエラー件数を保存
    IF (lv_retcode = gv_status_warn) THEN
      ln_warn_cnt := 1;
    ELSIF (lv_retcode = gv_status_error) THEN
      ln_error_cnt := 1;
    END IF;
    -- システムエラー(オラクルエラー)の場合はここで処理を中止してエラーリターンする。
    IF ((lv_retcode = gv_status_error ) AND ( lv_errmsg IS NULL )) THEN
      -- エラー件数は1として例外処理へ
      gn_error_cnt := 1;
      RAISE global_api_expt;
    END IF;
--
    -- 6.品目の適用日と開始日付チェック
    item_date_start_check( -- Forecast分類
                           in_if_data_tbl(in_if_data_cnt).forecast_designator,
                           -- 品目
                           in_if_data_tbl(in_if_data_cnt).item_code,
                           -- 開始日付
                           in_if_data_tbl(in_if_data_cnt).start_date_active,
                           lv_errbuf,
                           lv_retcode,
                           lv_errmsg);
    -- 警告およびエラーであればログを出力し処理続行
    IF (lv_retcode <> gv_status_normal) THEN
      if_data_disp( in_if_data_tbl, in_if_data_cnt);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf);
    END IF;
    -- 警告およびエラー件数を保存
    IF (lv_retcode = gv_status_warn) THEN
      ln_warn_cnt := 1;
    ELSIF (lv_retcode = gv_status_error) THEN
      ln_error_cnt := 1;
    END IF;
    -- システムエラー(オラクルエラー)の場合はここで処理を中止してエラーリターンする。
    IF ((lv_retcode = gv_status_error ) AND ( lv_errmsg IS NULL )) THEN
      -- エラー件数は1として例外処理へ
      gn_error_cnt := 1;
      RAISE global_api_expt;
    END IF;
--
    -- 9.10.品目の物流構成表計画商品対象品目と日付チェック
    item_forecast_check(-- Forecast分類
                        in_if_data_tbl(in_if_data_cnt).forecast_designator,
                        -- 品目
                        in_if_data_tbl(in_if_data_cnt).item_code,
                        -- 拠点
                        in_if_data_tbl(in_if_data_cnt).base_code,
                        -- 出荷倉庫
                        in_if_data_tbl(in_if_data_cnt).location_code,
                        -- 開始日付
                        in_if_data_tbl(in_if_data_cnt).start_date_active,
                        -- 終了日付
                        in_if_data_tbl(in_if_data_cnt).end_date_active,
                        lv_errbuf,
                        lv_retcode,
                        lv_errmsg);
    -- 警告およびエラーであればログを出力し処理続行
    IF (lv_retcode <> gv_status_normal) THEN
      if_data_disp( in_if_data_tbl, in_if_data_cnt);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf);
    END IF;
    -- 警告およびエラー件数を保存
    IF (lv_retcode = gv_status_warn) THEN
      ln_warn_cnt := 1;
    ELSIF (lv_retcode = gv_status_error) THEN
      ln_error_cnt := 1;
    END IF;
    -- システムエラー(オラクルエラー)の場合はここで処理を中止してエラーリターンする。
    IF ((lv_retcode = gv_status_error ) AND ( lv_errmsg IS NULL )) THEN
      -- エラー件数は1として例外処理へ
      gn_error_cnt := 1;
      RAISE global_api_expt;
    END IF;
--
    -- 14.日付の過去チェック
    date_past_check(-- Forecast分類
                    in_if_data_tbl(in_if_data_cnt).forecast_designator,
                    -- 開始日付
                    in_if_data_tbl(in_if_data_cnt).start_date_active,
                    -- 終了日付
                    in_if_data_tbl(in_if_data_cnt).end_date_active,
                    lv_errbuf,
                    lv_retcode,
                    lv_errmsg);
    -- 警告およびエラーであればログを出力し処理続行
    IF (lv_retcode <> gv_status_normal) THEN
      if_data_disp( in_if_data_tbl, in_if_data_cnt);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf);
    END IF;
    -- 警告およびエラー件数を保存
    IF (lv_retcode = gv_status_warn) THEN
      ln_warn_cnt := 1;
    ELSIF (lv_retcode = gv_status_error) THEN
      ln_error_cnt := 1;
    END IF;
    -- システムエラー(オラクルエラー)の場合はここで処理を中止してエラーリターンする。
    IF ((lv_retcode = gv_status_error ) AND ( lv_errmsg IS NULL )) THEN
      -- エラー件数は1として例外処理へ
      gn_error_cnt := 1;
      RAISE global_api_expt;
    END IF;
--
    -- 15.開始日付の1ヶ月以内チェック
    start_date_range_check(-- Forecast分類
                           in_if_data_tbl(in_if_data_cnt).forecast_designator,
                           -- 開始日付
                           in_if_data_tbl(in_if_data_cnt).start_date_active,
                           lv_errbuf,
                           lv_retcode,
                           lv_errmsg);
    -- 警告およびエラーであればログを出力し処理続行
    IF (lv_retcode <> gv_status_normal) THEN
      if_data_disp( in_if_data_tbl, in_if_data_cnt);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf);
    END IF;
    -- 警告およびエラー件数を保存
    IF (lv_retcode = gv_status_warn) THEN
      ln_warn_cnt := 1;
    ELSIF (lv_retcode = gv_status_error) THEN
      ln_error_cnt := 1;
    END IF;
    -- システムエラー(オラクルエラー)の場合はここで処理を中止してエラーリターンする。
    IF ((lv_retcode = gv_status_error ) AND ( lv_errmsg IS NULL )) THEN
      -- エラー件数は1として例外処理へ
      gn_error_cnt := 1;
      RAISE global_api_expt;
    END IF;
--
    -- 16.日付の開始＜終了チェック
    date_start_end_check(-- Forecast分類
                         in_if_data_tbl(in_if_data_cnt).forecast_designator,
                         -- 開始日付
                         in_if_data_tbl(in_if_data_cnt).start_date_active,
                         -- 終了日付
                         in_if_data_tbl(in_if_data_cnt).end_date_active,
                         lv_errbuf,
                         lv_retcode,
                         lv_errmsg);
    -- 警告およびエラーであればログを出力し処理続行
    IF (lv_retcode <> gv_status_normal) THEN
      if_data_disp( in_if_data_tbl, in_if_data_cnt);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf);
    END IF;
    -- 警告およびエラー件数を保存
    IF (lv_retcode = gv_status_warn) THEN
      ln_warn_cnt := 1;
    ELSIF (lv_retcode = gv_status_error) THEN
      ln_error_cnt := 1;
    END IF;
    -- システムエラー(オラクルエラー)の場合はここで処理を中止してエラーリターンする。
    IF ((lv_retcode = gv_status_error ) AND ( lv_errmsg IS NULL )) THEN
      -- エラー件数は1として例外処理へ
      gn_error_cnt := 1;
      RAISE global_api_expt;
    END IF;
--
    -- 17.出庫倉庫拠点品目日付での重複チェック
    inventory_date_check( -- Forecast分類
                          in_if_data_tbl(in_if_data_cnt).forecast_designator,
-- add start 1.11
                          in_if_data_tbl(in_if_data_cnt).item_code,
-- add end 1.11
-- add start 1.12
                          in_if_data_tbl(in_if_data_cnt).start_date_active,
-- add end 1.12
                          lv_errbuf,
                          lv_retcode,
                          lv_errmsg
    );
    -- 警告およびエラーであればログを出力し処理続行
    IF (lv_retcode <> gv_status_normal) THEN
      if_data_disp( in_if_data_tbl, in_if_data_cnt);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf);
    END IF;
    -- 警告およびエラー件数を保存
    IF (lv_retcode = gv_status_warn) THEN
      ln_warn_cnt := 1;
    ELSIF (lv_retcode = gv_status_error) THEN
      ln_error_cnt := 1;
    END IF;
    -- システムエラー(オラクルエラー)の場合はここで処理を中止してエラーリターンする。
    IF ((lv_retcode = gv_status_error ) AND ( lv_errmsg IS NULL )) THEN
      -- エラー件数は1として例外処理へ
      gn_error_cnt := 1;
      RAISE global_api_expt;
    END IF;
--
    -- 19.数量のマイナス数値チェック
    quantity_num_check( -- Forecast分類
                        in_if_data_tbl(in_if_data_cnt).forecast_designator,
                        -- ケース数量
                        in_if_data_tbl(in_if_data_cnt).case_quantity,
                        -- バラ数量
                        in_if_data_tbl(in_if_data_cnt).quantity,
                        lv_errbuf,
                        lv_retcode,
                        lv_errmsg
    );
    -- 警告およびエラーであればログを出力し処理続行
    IF (lv_retcode <> gv_status_normal) THEN
      if_data_disp( in_if_data_tbl, in_if_data_cnt);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf);
    END IF;
    -- 警告およびエラー件数を保存
    IF (lv_retcode = gv_status_warn) THEN
      ln_warn_cnt := 1;
    ELSIF (lv_retcode = gv_status_error) THEN
      ln_error_cnt := 1;
    END IF;
    -- システムエラー(オラクルエラー)の場合はここで処理を中止してエラーリターンする。
    IF ((lv_retcode = gv_status_error ) AND ( lv_errmsg IS NULL )) THEN
      -- エラー件数は1として例外処理へ
      gn_error_cnt := 1;
      RAISE global_api_expt;
    END IF;
--
-- 2009/02/17 本番障害#38 ADD Start --
    -- A-4-3 計画商品Forecast名抽出
    -- (Forcast名称チェック)
    get_f_degi_keikaku(   in_if_data_tbl  => in_if_data_tbl
                        , in_if_data_cnt  => in_if_data_cnt
                        , ov_errbuf       => lv_errbuf 
                        , ov_retcode      => lv_retcode
                        , ov_errmsg       => lv_errmsg 
                        );
    -- 警告およびエラーであればログを出力し処理続行
    IF (lv_retcode <> gv_status_normal) THEN
      if_data_disp( in_if_data_tbl, in_if_data_cnt);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf);
    END IF;
    -- 警告およびエラー件数を保存
    IF (lv_retcode = gv_status_warn) THEN
      ln_warn_cnt := 1;
    ELSIF (lv_retcode = gv_status_error) THEN
      ln_error_cnt := 1;
    END IF;
    -- システムエラー(オラクルエラー)の場合はここで処理を中止してエラーリターンする。
    IF ((lv_retcode = gv_status_error ) AND ( lv_errmsg IS NULL )) THEN
      -- エラー件数は1として例外処理へ
      gn_error_cnt := 1;
      RAISE global_api_expt;
    END IF;
-- 2009/02/17 本番障害#38 ADD End   --

    -- 各チェックにてエラーまたは警告が発生していたらリターン値に
    -- エラーまたは警告をセットする。
    IF (ln_warn_cnt > 0) THEN
      ov_retcode := gv_status_warn;
      gn_warn_cnt := gn_warn_cnt + 1;
      gn_no_msg_disp := 1;
    END IF;
    IF (ln_error_cnt > 0) THEN
      ov_retcode := gv_status_error;
      gn_error_cnt := gn_error_cnt + 1;
      gn_no_msg_disp := 1;
    END IF;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
      gn_error_cnt := gn_error_cnt + 1;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
      gn_error_cnt := gn_error_cnt + 1;
--
--#####################################  固定部 END   ##########################################
--
  END keikaku_data_check;
--
--
  /**********************************************************************************
   * Procedure Name   : seigen_a_data_check
   * Description      : 出荷数制限A抽出データチェック(A-5-2)
   ***********************************************************************************/
  PROCEDURE seigen_a_data_check(
    in_if_data_tbl        IN  forecast_tbl,
    in_if_data_cnt        IN  NUMBER,           -- 処理中のIFデータカウンタ
    ov_errbuf             OUT NOCOPY VARCHAR2,  -- エラー・メッセージ            --# 固定 #
    ov_retcode            OUT NOCOPY VARCHAR2,  -- リターン・コード              --# 固定 #
    ov_errmsg             OUT NOCOPY VARCHAR2)  -- ユーザー・エラー・メッセージ  --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'seigen_a_data_check'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    ln_warn_cnt  NUMBER;
    ln_error_cnt NUMBER;
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
    ln_warn_cnt  := 0;
    ln_error_cnt := 0;
--
    -- 3.拠点の存在チェック
    base_code_exist_check(-- Forecast分類
                          in_if_data_tbl(in_if_data_cnt).forecast_designator,
                          -- 拠点コード
                          in_if_data_tbl(in_if_data_cnt).base_code,
                          lv_errbuf,
                          lv_retcode,
                          lv_errmsg);
    -- 警告およびエラーであればログを出力し処理続行
    IF (lv_retcode <> gv_status_normal) THEN
      if_data_disp( in_if_data_tbl, in_if_data_cnt);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf);
    END IF;
    -- 警告およびエラー件数を保存
    IF (lv_retcode = gv_status_warn) THEN
      ln_warn_cnt := 1;
    ELSIF (lv_retcode = gv_status_error) THEN
      ln_error_cnt := 1;
    END IF;
    -- システムエラー(オラクルエラー)の場合はここで処理を中止してエラーリターンする。
    IF ((lv_retcode = gv_status_error ) AND ( lv_errmsg IS NULL )) THEN
      -- エラー件数は1として例外処理へ
      gn_error_cnt := 1;
      RAISE global_api_expt;
    END IF;
--
    -- 4.品目の廃止区分チェック
    item_abolition_code_check(-- Forecast分類
                              in_if_data_tbl(in_if_data_cnt).forecast_designator,
                              -- 品目
                              in_if_data_tbl(in_if_data_cnt).item_code,
                              -- 開始日付
                              in_if_data_tbl(in_if_data_cnt).start_date_active,
                              lv_errbuf,
                              lv_retcode,
                              lv_errmsg);
    -- 警告およびエラーであればログを出力し処理続行
    IF (lv_retcode <> gv_status_normal) THEN
      if_data_disp( in_if_data_tbl, in_if_data_cnt);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf);
    END IF;
    -- 警告およびエラー件数を保存
    IF (lv_retcode = gv_status_warn) THEN
      ln_warn_cnt := 1;
    ELSIF (lv_retcode = gv_status_error) THEN
      ln_error_cnt := 1;
    END IF;
    -- システムエラー(オラクルエラー)の場合はここで処理を中止してエラーリターンする。
    IF ((lv_retcode = gv_status_error ) AND ( lv_errmsg IS NULL )) THEN
      -- エラー件数は1として例外処理へ
      gn_error_cnt := 1;
      RAISE global_api_expt;
    END IF;
--
    -- 5.品目の品目区分チェック
    item_class_check( -- Forecast分類
                      in_if_data_tbl(in_if_data_cnt).forecast_designator,
                      -- 品目
                      in_if_data_tbl(in_if_data_cnt).item_code,
                      -- 開始日付
                      in_if_data_tbl(in_if_data_cnt).start_date_active,
                      lv_errbuf,
                      lv_retcode,
                      lv_errmsg);
    -- 警告およびエラーであればログを出力し処理続行
    IF (lv_retcode <> gv_status_normal) THEN
      if_data_disp( in_if_data_tbl, in_if_data_cnt);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf);
    END IF;
    -- 警告およびエラー件数を保存
    IF (lv_retcode = gv_status_warn) THEN
      ln_warn_cnt := 1;
    ELSIF (lv_retcode = gv_status_error) THEN
      ln_error_cnt := 1;
    END IF;
    -- システムエラー(オラクルエラー)の場合はここで処理を中止してエラーリターンする。
    IF ((lv_retcode = gv_status_error ) AND ( lv_errmsg IS NULL )) THEN
      -- エラー件数は1として例外処理へ
      gn_error_cnt := 1;
      RAISE global_api_expt;
    END IF;
--
    -- 6.品目の適用日と開始日付チェック
    item_date_start_check( -- Forecast分類
                           in_if_data_tbl(in_if_data_cnt).forecast_designator,
                           -- 品目
                           in_if_data_tbl(in_if_data_cnt).item_code,
                           -- 開始日付
                           in_if_data_tbl(in_if_data_cnt).start_date_active,
                           lv_errbuf,
                           lv_retcode,
                           lv_errmsg);
    -- 警告およびエラーであればログを出力し処理続行
    IF (lv_retcode <> gv_status_normal) THEN
      if_data_disp( in_if_data_tbl, in_if_data_cnt);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf);
    END IF;
    -- 警告およびエラー件数を保存
    IF (lv_retcode = gv_status_warn) THEN
      ln_warn_cnt := 1;
    ELSIF (lv_retcode = gv_status_error) THEN
      ln_error_cnt := 1;
    END IF;
    -- システムエラー(オラクルエラー)の場合はここで処理を中止してエラーリターンする。
    IF ((lv_retcode = gv_status_error ) AND ( lv_errmsg IS NULL )) THEN
      -- エラー件数は1として例外処理へ
      gn_error_cnt := 1;
      RAISE global_api_expt;
    END IF;
--
    -- 11.品目の物流構成表未登録の警告チェック
    item_not_regist_check( -- Forecast分類
                           in_if_data_tbl(in_if_data_cnt).forecast_designator,
                           -- 品目
                           in_if_data_tbl(in_if_data_cnt).item_code,
                           -- 拠点コード
                           in_if_data_tbl(in_if_data_cnt).base_code,
                           -- 出荷倉庫
                           in_if_data_tbl(in_if_data_cnt).location_code,
                           -- 開始日付
                           in_if_data_tbl(in_if_data_cnt).start_date_active,
                           -- 終了日付
                           in_if_data_tbl(in_if_data_cnt).end_date_active,
                           lv_errbuf,
                           lv_retcode,
                           lv_errmsg);
    -- 警告およびエラーであればログを出力し処理続行
    IF (lv_retcode <> gv_status_normal) THEN
      if_data_disp( in_if_data_tbl, in_if_data_cnt);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf);
    END IF;
    -- 警告およびエラー件数を保存
    IF (lv_retcode = gv_status_warn) THEN
      ln_warn_cnt := 1;
    ELSIF (lv_retcode = gv_status_error) THEN
      ln_error_cnt := 1;
    END IF;
    -- システムエラー(オラクルエラー)の場合はここで処理を中止してエラーリターンする。
    IF ((lv_retcode = gv_status_error ) AND ( lv_errmsg IS NULL )) THEN
      -- エラー件数は1として例外処理へ
      gn_error_cnt := 1;
      RAISE global_api_expt;
    END IF;
--
    -- 14.日付の過去チェック
    date_past_check(-- Forecast分類
                    in_if_data_tbl(in_if_data_cnt).forecast_designator,
                    -- 開始日付
                    in_if_data_tbl(in_if_data_cnt).start_date_active,
                    -- 終了日付
                    in_if_data_tbl(in_if_data_cnt).end_date_active,
                    lv_errbuf,
                    lv_retcode,
                    lv_errmsg);
    -- 警告およびエラーであればログを出力し処理続行
    IF (lv_retcode <> gv_status_normal) THEN
      if_data_disp( in_if_data_tbl, in_if_data_cnt);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf);
    END IF;
    -- 警告およびエラー件数を保存
    IF (lv_retcode = gv_status_warn) THEN
      ln_warn_cnt := 1;
    ELSIF (lv_retcode = gv_status_error) THEN
      ln_error_cnt := 1;
    END IF;
    -- システムエラー(オラクルエラー)の場合はここで処理を中止してエラーリターンする。
    IF ((lv_retcode = gv_status_error ) AND ( lv_errmsg IS NULL )) THEN
      -- エラー件数は1として例外処理へ
      gn_error_cnt := 1;
      RAISE global_api_expt;
    END IF;
--
    -- 15.開始日付の1ヶ月以内チェック
    start_date_range_check(-- Forecast分類
                           in_if_data_tbl(in_if_data_cnt).forecast_designator,
                           -- 開始日付
                           in_if_data_tbl(in_if_data_cnt).start_date_active,
                           lv_errbuf,
                           lv_retcode,
                           lv_errmsg);
    -- 警告およびエラーであればログを出力し処理続行
    IF (lv_retcode <> gv_status_normal) THEN
      if_data_disp( in_if_data_tbl, in_if_data_cnt);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf);
    END IF;
    -- 警告およびエラー件数を保存
    IF (lv_retcode = gv_status_warn) THEN
      ln_warn_cnt := 1;
    ELSIF (lv_retcode = gv_status_error) THEN
      ln_error_cnt := 1;
    END IF;
    -- システムエラー(オラクルエラー)の場合はここで処理を中止してエラーリターンする。
    IF ((lv_retcode = gv_status_error ) AND ( lv_errmsg IS NULL )) THEN
      -- エラー件数は1として例外処理へ
      gn_error_cnt := 1;
      RAISE global_api_expt;
    END IF;
--
    -- 16.日付の開始＜終了チェック
    date_start_end_check(-- Forecast分類
                         in_if_data_tbl(in_if_data_cnt).forecast_designator,
                         -- 開始日付
                         in_if_data_tbl(in_if_data_cnt).start_date_active,
                         -- 終了日付
                         in_if_data_tbl(in_if_data_cnt).end_date_active,
                         lv_errbuf,
                         lv_retcode,
                         lv_errmsg);
    -- 警告およびエラーであればログを出力し処理続行
    IF (lv_retcode <> gv_status_normal) THEN
      if_data_disp( in_if_data_tbl, in_if_data_cnt);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf);
    END IF;
    -- 警告およびエラー件数を保存
    IF (lv_retcode = gv_status_warn) THEN
      ln_warn_cnt := 1;
    ELSIF (lv_retcode = gv_status_error) THEN
      ln_error_cnt := 1;
    END IF;
    -- システムエラー(オラクルエラー)の場合はここで処理を中止してエラーリターンする。
    IF ((lv_retcode = gv_status_error ) AND ( lv_errmsg IS NULL )) THEN
      -- エラー件数は1として例外処理へ
      gn_error_cnt := 1;
      RAISE global_api_expt;
    END IF;
--
    -- 18.拠点品目日付での重複チェック
    base_code_date_check(-- Forecast分類
                         in_if_data_tbl(in_if_data_cnt).forecast_designator,
                         -- 拠点コード
                         in_if_data_tbl(in_if_data_cnt).base_code,
                         -- 品目
                         in_if_data_tbl(in_if_data_cnt).item_code,
                         -- 開始日付
                         in_if_data_tbl(in_if_data_cnt).start_date_active,
                         lv_errbuf,
                         lv_retcode,
                         lv_errmsg);
    -- 警告およびエラーであればログを出力し処理続行
    IF (lv_retcode <> gv_status_normal) THEN
      if_data_disp( in_if_data_tbl, in_if_data_cnt);
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf);
    END IF;
    -- 警告およびエラー件数を保存
    IF (lv_retcode = gv_status_warn) THEN
      ln_warn_cnt := 1;
    ELSIF (lv_retcode = gv_status_error) THEN
      ln_error_cnt := 1;
    END IF;
    -- システムエラー(オラクルエラー)の場合はここで処理を中止してエラーリターンする。
    IF ((lv_retcode = gv_status_error ) AND ( lv_errmsg IS NULL )) THEN
      -- エラー件数は1として例外処理へ
      gn_error_cnt := 1;
      RAISE global_api_expt;
    END IF;
--
    -- 19.数量のマイナス数値チェック
    quantity_num_check( -- Forecast分類
                        in_if_data_tbl(in_if_data_cnt).forecast_designator,
                        -- ケース数量
                        in_if_data_tbl(in_if_data_cnt).case_quantity,
                        -- バラ数量
                        in_if_data_tbl(in_if_data_cnt).quantity,
                        lv_errbuf,
                        lv_retcode,
                        lv_errmsg);
    -- 警告およびエラーであればログを出力し処理続行
    IF (lv_retcode <> gv_status_normal) THEN
      if_data_disp( in_if_data_tbl, in_if_data_cnt);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf);
    END IF;
    -- 警告およびエラー件数を保存1
    IF (lv_retcode = gv_status_warn) THEN
      ln_warn_cnt := 1;
    ELSIF (lv_retcode = gv_status_error) THEN
      ln_error_cnt := 1;
    END IF;
    -- システムエラー(オラクルエラー)の場合はここで処理を中止してエラーリターンする。
    IF ((lv_retcode = gv_status_error ) AND ( lv_errmsg IS NULL )) THEN
      -- エラー件数は1として例外処理へ
      gn_error_cnt := 1;
      RAISE global_api_expt;
    END IF;
--
-- 2009/02/17 本番障害#38対応 ADD Start --
    -- A-5-3 出荷数制限AForecast名抽出
    -- (Forcast名チェック)
    get_f_degi_seigen_a( in_if_data_tbl => in_if_data_tbl
                        ,in_if_data_cnt => in_if_data_cnt
                        ,ov_errbuf      => lv_errbuf
                        ,ov_retcode     => lv_retcode
                        ,ov_errmsg      => lv_errmsg
    );
    -- 警告およびエラーであればログを出力し処理続行
    IF (lv_retcode <> gv_status_normal) THEN
      if_data_disp( in_if_data_tbl, in_if_data_cnt);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf);
    END IF;
    -- 警告およびエラー件数を保存
    IF (lv_retcode = gv_status_warn) THEN
      ln_warn_cnt := 1;
    ELSIF (lv_retcode = gv_status_error) THEN
      ln_error_cnt := 1;
    END IF;
    -- システムエラー(オラクルエラー)の場合はここで処理を中止してエラーリターンする。
    IF ((lv_retcode = gv_status_error ) AND ( lv_errmsg IS NULL )) THEN
      -- エラー件数は1として例外処理へ
      gn_error_cnt := 1;
      RAISE global_api_expt;
    END IF;
-- 2009/02/17 本番障害#38対応 ADD End ----
--
    -- 各チェックにてエラーまたは警告が発生していたらリターン値に
    -- エラーまたは警告をセットする。
    IF (ln_warn_cnt > 0) THEN
      ov_retcode := gv_status_warn;
      gn_warn_cnt := gn_warn_cnt + 1;
      gn_no_msg_disp := 1;
    END IF;
    IF (ln_error_cnt > 0) THEN
      ov_retcode := gv_status_error;
      gn_error_cnt := gn_error_cnt + 1;
      gn_no_msg_disp := 1;
    END IF;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
      gn_error_cnt := gn_error_cnt + 1;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
      gn_error_cnt := gn_error_cnt + 1;
--
--#####################################  固定部 END   ##########################################
--
  END seigen_a_data_check;
--
--
  /**********************************************************************************
   * Procedure Name   : seigen_b_data_check
   * Description      : 出荷数制限B抽出データチェック(A-6-2)
   ***********************************************************************************/
  PROCEDURE seigen_b_data_check(
    in_if_data_tbl        IN  forecast_tbl,
    in_if_data_cnt        IN  NUMBER,           -- 処理中のIFデータカウンタ
    ov_errbuf             OUT NOCOPY VARCHAR2,  -- エラー・メッセージ            --# 固定 #
    ov_retcode            OUT NOCOPY VARCHAR2,  -- リターン・コード              --# 固定 #
    ov_errmsg             OUT NOCOPY VARCHAR2)  -- ユーザー・エラー・メッセージ  --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'seigen_b_data_check'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    ln_warn_cnt  NUMBER;
    ln_error_cnt NUMBER;
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
    ln_warn_cnt  := 0;
    ln_error_cnt := 0;
--
    -- 1.出庫倉庫の適用日と開始日付チェック
    shipped_date_start_check( -- Forecast分類
                              in_if_data_tbl(in_if_data_cnt).forecast_designator,
                              -- 出荷倉庫 
                              in_if_data_tbl(in_if_data_cnt).location_code,
                              -- 開始日付
                              in_if_data_tbl(in_if_data_cnt).start_date_active,
                              -- 終了日付
                              in_if_data_tbl(in_if_data_cnt).end_date_active,
                              lv_errbuf,
                              lv_retcode,
                              lv_errmsg);
    -- 警告およびエラーであればログを出力し処理続行
    IF (lv_retcode <> gv_status_normal) THEN
      if_data_disp( in_if_data_tbl, in_if_data_cnt);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf);
    END IF;
    -- 警告およびエラー件数を保存
    IF (lv_retcode = gv_status_warn) THEN
      ln_warn_cnt := 1;
    ELSIF (lv_retcode = gv_status_error) THEN
      ln_error_cnt := 1;
    END IF;
    -- システムエラー(オラクルエラー)の場合はここで処理を中止してエラーリターンする。
    IF ((lv_retcode = gv_status_error ) AND ( lv_errmsg IS NULL )) THEN
      -- エラー件数は1として例外処理へ
      gn_error_cnt := 1;
      RAISE global_api_expt;
    END IF;
--
    -- 2.出庫倉庫の出庫管理元区分チェック
    shipped_class_check( -- Forecast分類
                         in_if_data_tbl(in_if_data_cnt).forecast_designator,
                         -- 品目
                         in_if_data_tbl(in_if_data_cnt).item_code,
                         -- 出荷倉庫
                         in_if_data_tbl(in_if_data_cnt).location_code,
                         lv_errbuf,
                         lv_retcode,
                         lv_errmsg);
    -- 警告およびエラーであればログを出力し処理続行
    IF (lv_retcode <> gv_status_normal) THEN
      if_data_disp( in_if_data_tbl, in_if_data_cnt);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf);
    END IF;
    -- 警告およびエラー件数を保存
    IF (lv_retcode = gv_status_warn) THEN
      ln_warn_cnt := 1;
    ELSIF (lv_retcode = gv_status_error) THEN
      ln_error_cnt := 1;
    END IF;
    -- システムエラー(オラクルエラー)の場合はここで処理を中止してエラーリターンする。
    IF ((lv_retcode = gv_status_error ) AND ( lv_errmsg IS NULL )) THEN
      -- エラー件数は1として例外処理へ
      gn_error_cnt := 1;
      RAISE global_api_expt;
    END IF;
--
    -- 3.拠点の存在チェック
    IF (in_if_data_tbl(in_if_data_cnt).base_code IS NOT NULL) THEN
      base_code_exist_check(-- Forecast分類
                            in_if_data_tbl(in_if_data_cnt).forecast_designator,
                            -- 拠点コード
                            in_if_data_tbl(in_if_data_cnt).base_code,
                            lv_errbuf,
                            lv_retcode,
                            lv_errmsg);
      -- 警告およびエラーであればログを出力し処理続行
      IF (lv_retcode <> gv_status_normal) THEN
        if_data_disp( in_if_data_tbl, in_if_data_cnt);
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
        FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf);
      END IF;
      -- 警告およびエラー件数を保存
      IF (lv_retcode = gv_status_warn) THEN
        ln_warn_cnt := 1;
      ELSIF (lv_retcode = gv_status_error) THEN
        ln_error_cnt := 1;
      END IF;
      -- システムエラー(オラクルエラー)の場合はここで処理を中止してエラーリターンする。
      IF ((lv_retcode = gv_status_error ) AND ( lv_errmsg IS NULL )) THEN
        -- エラー件数は1として例外処理へ
        gn_error_cnt := 1;
        RAISE global_api_expt;
      END IF;
    END IF;
--
    -- 4.品目の廃止区分チェック
    item_abolition_code_check(-- Forecast分類
                              in_if_data_tbl(in_if_data_cnt).forecast_designator,
                              -- 品目
                              in_if_data_tbl(in_if_data_cnt).item_code,
                              -- 開始日付
                              in_if_data_tbl(in_if_data_cnt).start_date_active,
                              lv_errbuf,
                              lv_retcode,
                              lv_errmsg);
    -- 警告およびエラーであればログを出力し処理続行
    IF (lv_retcode <> gv_status_normal) THEN
      if_data_disp( in_if_data_tbl, in_if_data_cnt);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf);
    END IF;
    -- 警告およびエラー件数を保存
    IF (lv_retcode = gv_status_warn) THEN
      ln_warn_cnt := 1;
    ELSIF (lv_retcode = gv_status_error) THEN
      ln_error_cnt := 1;
    END IF;
    -- システムエラー(オラクルエラー)の場合はここで処理を中止してエラーリターンする。
    IF ((lv_retcode = gv_status_error ) AND ( lv_errmsg IS NULL )) THEN
      -- エラー件数は1として例外処理へ
      gn_error_cnt := 1;
      RAISE global_api_expt;
    END IF;
--
    -- 5.品目の品目区分チェック
    item_class_check( -- Forecast分類
                      in_if_data_tbl(in_if_data_cnt).forecast_designator,
                      -- 品目
                      in_if_data_tbl(in_if_data_cnt).item_code,
                      -- 開始日付
                      in_if_data_tbl(in_if_data_cnt).start_date_active,
                      lv_errbuf,
                      lv_retcode,
                      lv_errmsg);
    -- 警告およびエラーであればログを出力し処理続行
    IF (lv_retcode <> gv_status_normal) THEN
      if_data_disp( in_if_data_tbl, in_if_data_cnt);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf);
    END IF;
    -- 警告およびエラー件数を保存
    IF (lv_retcode = gv_status_warn) THEN
      ln_warn_cnt := 1;
    ELSIF (lv_retcode = gv_status_error) THEN
      ln_error_cnt := 1;
    END IF;
    -- システムエラー(オラクルエラー)の場合はここで処理を中止してエラーリターンする。
    IF ((lv_retcode = gv_status_error ) AND ( lv_errmsg IS NULL )) THEN
      -- エラー件数は1として例外処理へ
      gn_error_cnt := 1;
      RAISE global_api_expt;
    END IF;
--
    -- 6.品目の適用日と開始日付チェック
    item_date_start_check( -- Forecast分類
                           in_if_data_tbl(in_if_data_cnt).forecast_designator,
                           -- 品目
                           in_if_data_tbl(in_if_data_cnt).item_code,
                           -- 開始日付
                           in_if_data_tbl(in_if_data_cnt).start_date_active,
                           lv_errbuf,
                           lv_retcode,
                           lv_errmsg);
    -- 警告およびエラーであればログを出力し処理続行
    IF (lv_retcode <> gv_status_normal) THEN
      if_data_disp( in_if_data_tbl, in_if_data_cnt);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf);
    END IF;
    -- 警告およびエラー件数を保存
    IF (lv_retcode = gv_status_warn) THEN
      ln_warn_cnt := 1;
    ELSIF (lv_retcode = gv_status_error) THEN
      ln_error_cnt := 1;
    END IF;
    -- システムエラー(オラクルエラー)の場合はここで処理を中止してエラーリターンする。
    IF ((lv_retcode = gv_status_error ) AND ( lv_errmsg IS NULL )) THEN
      -- エラー件数は1として例外処理へ
      gn_error_cnt := 1;
      RAISE global_api_expt;
    END IF;
--
    -- 11.品目の物流構成表未登録の警告チェック
    item_not_regist_check( -- Forecast分類
                           in_if_data_tbl(in_if_data_cnt).forecast_designator,
                           -- 品目
                           in_if_data_tbl(in_if_data_cnt).item_code,
                           -- 拠点コード
                           in_if_data_tbl(in_if_data_cnt).base_code,
                           -- 出荷倉庫 
                           in_if_data_tbl(in_if_data_cnt).location_code,
                           -- 開始日付
                           in_if_data_tbl(in_if_data_cnt).start_date_active,
                           -- 終了日付 
                           in_if_data_tbl(in_if_data_cnt).end_date_active,
                           lv_errbuf,
                           lv_retcode,
                           lv_errmsg);
    -- 警告およびエラーであればログを出力し処理続行
    IF (lv_retcode <> gv_status_normal) THEN
      if_data_disp( in_if_data_tbl, in_if_data_cnt);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf);
    END IF;
    -- 警告およびエラー件数を保存
    IF (lv_retcode = gv_status_warn) THEN
      ln_warn_cnt := 1;
    ELSIF (lv_retcode = gv_status_error) THEN
      ln_error_cnt := 1;
    END IF;
    -- システムエラー(オラクルエラー)の場合はここで処理を中止してエラーリターンする。
    IF ((lv_retcode = gv_status_error ) AND ( lv_errmsg IS NULL )) THEN
      -- エラー件数は1として例外処理へ
      gn_error_cnt := 1;
      RAISE global_api_expt;
    END IF;
--
    -- 14.日付の過去チェック
    date_past_check(-- Forecast分類
                    in_if_data_tbl(in_if_data_cnt).forecast_designator,
                    -- 開始日付
                    in_if_data_tbl(in_if_data_cnt).start_date_active,
                    -- 終了日付
                    in_if_data_tbl(in_if_data_cnt).end_date_active,
                    lv_errbuf,
                    lv_retcode,
                    lv_errmsg);
    -- 警告およびエラーであればログを出力し処理続行
    IF (lv_retcode <> gv_status_normal) THEN
      if_data_disp( in_if_data_tbl, in_if_data_cnt);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf);
    END IF;
    -- 警告およびエラー件数を保存
    IF (lv_retcode = gv_status_warn) THEN
      ln_warn_cnt := 1;
    ELSIF (lv_retcode = gv_status_error) THEN
      ln_error_cnt := 1;
    END IF;
    -- システムエラー(オラクルエラー)の場合はここで処理を中止してエラーリターンする。
    IF ((lv_retcode = gv_status_error ) AND ( lv_errmsg IS NULL )) THEN
      -- エラー件数は1として例外処理へ
      gn_error_cnt := 1;
      RAISE global_api_expt;
    END IF;
--
    -- 15.開始日付の1ヶ月以内チェック
    start_date_range_check(-- Forecast分類
                           in_if_data_tbl(in_if_data_cnt).forecast_designator,
                           -- 開始日付
                           in_if_data_tbl(in_if_data_cnt).start_date_active,
                           lv_errbuf,
                           lv_retcode,
                           lv_errmsg);
    -- 警告およびエラーであればログを出力し処理続行
    IF (lv_retcode <> gv_status_normal) THEN
      if_data_disp( in_if_data_tbl, in_if_data_cnt);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf);
    END IF;
    -- 警告およびエラー件数を保存
    IF (lv_retcode = gv_status_warn) THEN
      ln_warn_cnt := 1;
    ELSIF (lv_retcode = gv_status_error) THEN
      ln_error_cnt := 1;
    END IF;
    -- システムエラー(オラクルエラー)の場合はここで処理を中止してエラーリターンする。
    IF ((lv_retcode = gv_status_error ) AND ( lv_errmsg IS NULL )) THEN
      -- エラー件数は1として例外処理へ
      gn_error_cnt := 1;
      RAISE global_api_expt;
    END IF;
--
    -- 16.日付の開始＜終了チェック
    date_start_end_check(-- Forecast分類
                         in_if_data_tbl(in_if_data_cnt).forecast_designator,
                         -- 開始日付
                         in_if_data_tbl(in_if_data_cnt).start_date_active,
                         -- 終了日付
                         in_if_data_tbl(in_if_data_cnt).end_date_active,
                         lv_errbuf,
                         lv_retcode,
                         lv_errmsg);
    -- 警告およびエラーであればログを出力し処理続行
    IF (lv_retcode <> gv_status_normal) THEN
      if_data_disp( in_if_data_tbl, in_if_data_cnt);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf);
    END IF;
    -- 警告およびエラー件数を保存
    IF (lv_retcode = gv_status_warn) THEN
      ln_warn_cnt := 1;
    ELSIF (lv_retcode = gv_status_error) THEN
      ln_error_cnt := 1;
    END IF;
    -- システムエラー(オラクルエラー)の場合はここで処理を中止してエラーリターンする。
    IF ((lv_retcode = gv_status_error ) AND ( lv_errmsg IS NULL )) THEN
      -- エラー件数は1として例外処理へ
      gn_error_cnt := 1;
      RAISE global_api_expt;
    END IF;
--
    -- 17.出庫倉庫拠点品目日付での重複チェック
    inventory_date_check( -- Forecast分類
                          in_if_data_tbl(in_if_data_cnt).forecast_designator,
-- add start 1.11
                          in_if_data_tbl(in_if_data_cnt).item_code,
-- add end 1.11
-- add start 1.12
                          in_if_data_tbl(in_if_data_cnt).start_date_active,
-- add end 1.12
                          lv_errbuf,
                          lv_retcode,
                          lv_errmsg
    );
    -- 警告およびエラーであればログを出力し処理続行
    IF (lv_retcode <> gv_status_normal) THEN
      if_data_disp( in_if_data_tbl, in_if_data_cnt);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf);
    END IF;
    -- 警告およびエラー件数を保存
    IF (lv_retcode = gv_status_warn) THEN
      ln_warn_cnt := 1;
    ELSIF (lv_retcode = gv_status_error) THEN
      ln_error_cnt := 1;
    END IF;
    -- システムエラー(オラクルエラー)の場合はここで処理を中止してエラーリターンする。
    IF ((lv_retcode = gv_status_error ) AND ( lv_errmsg IS NULL )) THEN
      -- エラー件数は1として例外処理へ
      gn_error_cnt := 1;
      RAISE global_api_expt;
    END IF;
--
    -- 19.数量のマイナス数値チェック
    quantity_num_check( -- Forecast分類
                        in_if_data_tbl(in_if_data_cnt).forecast_designator,
                        -- ケース数量
                        in_if_data_tbl(in_if_data_cnt).case_quantity,
                        -- バラ数量
                        in_if_data_tbl(in_if_data_cnt).quantity,
                        lv_errbuf,
                        lv_retcode,
                        lv_errmsg
    );
    -- 警告およびエラーであればログを出力し処理続行
    IF (lv_retcode <> gv_status_normal) THEN
      if_data_disp( in_if_data_tbl, in_if_data_cnt);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf);
    END IF;
    -- 警告およびエラー件数を保存
    IF (lv_retcode = gv_status_warn) THEN
      ln_warn_cnt := 1;
    ELSIF (lv_retcode = gv_status_error) THEN
      ln_error_cnt := 1;
    END IF;
    -- システムエラー(オラクルエラー)の場合はここで処理を中止してエラーリターンする。
    IF ((lv_retcode = gv_status_error ) AND ( lv_errmsg IS NULL )) THEN
      -- エラー件数は1として例外処理へ
      gn_error_cnt := 1;
      RAISE global_api_expt;
    END IF;
--
-- 2009/02/17 本番障害#38対応 ADD Start --
    -- A-6-3 出荷数制限BForecast名抽出
    -- (Forcast名チェック)
    get_f_degi_seigen_b( in_if_data_tbl => in_if_data_tbl -- Forcast登録用配列
                        ,in_if_data_cnt => in_if_data_cnt -- 処理中のデータカウンタ
                        ,ov_errbuf      => lv_errbuf
                        ,ov_retcode     => lv_retcode
                        ,ov_errmsg      => lv_errmsg
    );
    -- 警告およびエラーであればログを出力し処理続行
    IF (lv_retcode <> gv_status_normal) THEN
      if_data_disp( in_if_data_tbl, in_if_data_cnt);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf);
    END IF;
    -- 警告およびエラー件数を保存
    IF (lv_retcode = gv_status_warn) THEN
      ln_warn_cnt := 1;
    ELSIF (lv_retcode = gv_status_error) THEN
      ln_error_cnt := 1;
    END IF;
    -- システムエラー(オラクルエラー)の場合はここで処理を中止してエラーリターンする。
    IF ((lv_retcode = gv_status_error ) AND ( lv_errmsg IS NULL )) THEN
      -- エラー件数は1として例外処理へ
      gn_error_cnt := 1;
      RAISE global_api_expt;
    END IF;
-- 2009/02/17 本番障害#38対応 ADD End ----
--
    -- 各チェックにてエラーまたは警告が発生していたらリターン値に
    -- エラーまたは警告をセットする。
    IF (ln_warn_cnt > 0) THEN
      ov_retcode := gv_status_warn;
      gn_warn_cnt := gn_warn_cnt + 1;
      gn_no_msg_disp := 1;
    END IF;
    IF (ln_error_cnt > 0) THEN
      ov_retcode := gv_status_error;
      gn_error_cnt := gn_error_cnt + 1;
      gn_no_msg_disp := 1;
    END IF;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
      gn_error_cnt := gn_error_cnt + 1;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
      gn_error_cnt := gn_error_cnt + 1;
--
--#####################################  固定部 END   ##########################################
--
  END seigen_b_data_check;
--
  /**********************************************************************************
   * Procedure Name   : get_f_degi_hikitori
   * Description      : A-2-3 引取計画Forecast名抽出
   ***********************************************************************************/
  PROCEDURE get_f_degi_hikitori(
    in_if_data_tbl           IN  forecast_tbl,
    in_if_data_cnt           IN  NUMBER,          -- 処理中のIFデータカウンタ
    ov_errbuf                OUT NOCOPY VARCHAR2, -- エラー・メッセージ           --# 固定 #
    ov_retcode               OUT NOCOPY VARCHAR2, -- リターン・コード             --# 固定 #
    ov_errmsg                OUT NOCOPY VARCHAR2) -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_f_degi_hikitori'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- Forecast名の抽出
    SELECT  mfd.forecast_designator,                   -- Forecast名
            mfd.organization_id                        -- 在庫組織ID
    INTO    gv_3f_forecast_designator,                 -- Forecast名
            gn_3f_organization_id                      -- 在庫組織
    FROM    mrp_forecast_designators  mfd            -- Forecast名テーブル
    WHERE   mfd.attribute1 = gv_cons_fc_type_hikitori  -- Forecast分類('引取計画')
      AND   mfd.attribute2 = in_if_data_tbl(in_if_data_cnt).location_code          -- 出荷倉庫
      AND   mfd.attribute3 = in_if_data_tbl(in_if_data_cnt).base_code;             -- 拠点
--
  EXCEPTION
    -- Forecast名が妥当でない(存在しない)場合の後処理
    WHEN NO_DATA_FOUND THEN
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_inv   -- 'XXINV'
                                                            -- 引取計画フォーキャスト名取得エラー
                                                    ,gv_msg_10a_017
                                                    ,gv_tkn_soko    -- トークン'SOKO'
                                                                    -- 出庫倉庫
                                                    ,in_if_data_tbl(in_if_data_cnt).location_code
                                                    ,gv_tkn_kyoten  -- トークン'KYOTEN'
                                                                    -- 拠点
                                                    ,in_if_data_tbl(in_if_data_cnt).base_code)
                                                    ,1
                                                    ,5000);
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;                                            --# 任意 #
--
    -- Forecast名が複数ヒットした場合の後処理
    WHEN TOO_MANY_ROWS THEN
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_inv   -- 'XXINV'
                                                            -- 引取計画フォーキャスト名重複エラー
                                                    ,gv_msg_10a_062
                                                    ,gv_tkn_soko    -- トークン'SOKO'
                                                                    -- 出庫倉庫
                                                    ,in_if_data_tbl(in_if_data_cnt).location_code
                                                    ,gv_tkn_kyoten  -- トークン'KYOTEN'
                                                                    -- 拠点
                                                    ,in_if_data_tbl(in_if_data_cnt).base_code)
                                                    ,1
                                                    ,5000);
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;                                            --# 任意 #
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_f_degi_hikitori;
--
  /**********************************************************************************
   * Procedure Name   : get_f_degi_hanbai
   * Description      : A-3-3 販売計画Forecast名抽出
   ***********************************************************************************/
  PROCEDURE get_f_degi_hanbai(
    in_if_data_tbl           IN  forecast_tbl,
    in_if_data_cnt           IN  NUMBER,          -- 処理中のIFデータカウンタ
    ov_errbuf                OUT NOCOPY VARCHAR2, -- エラー・メッセージ           --# 固定 #
    ov_retcode               OUT NOCOPY VARCHAR2, -- リターン・コード             --# 固定 #
    ov_errmsg                OUT NOCOPY VARCHAR2) -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_f_degi_hanbai'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- Forecast名の抽出
    SELECT  mfd.forecast_designator,                   -- Forecast名
            mfd.organization_id                        -- 在庫組織ID
    INTO    gv_3f_forecast_designator,                 -- Forecast名
            gn_3f_organization_id                      -- 在庫組織
    FROM    mrp_forecast_designators  mfd            -- Forecast名テーブル
    WHERE   mfd.attribute1 = gv_cons_fc_type_hanbai    -- Forecast分類('販売計画')
      AND   mfd.attribute6 = gv_forecast_year          -- 年度
      AND   mfd.attribute5 = gv_forecast_version;      -- 世代
--
  EXCEPTION
    -- Forecast名が妥当でない(存在しない)場合の後処理
    WHEN NO_DATA_FOUND THEN
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_inv  -- 'XXINV'
                                                             -- 販売計画フォーキャスト名取得エラー
                                                    ,gv_msg_10a_018)
                                                    ,1
                                                    ,5000);
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;                                            --# 任意 #
--
    -- Forecast名が複数ヒットした場合の後処理
    WHEN TOO_MANY_ROWS THEN
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_inv   -- 'XXINV'
                                                            -- 販売計画フォーキャスト名重複エラー
                                                    ,gv_msg_10a_063
                                                    ,gv_tkn_nendo    -- トークン'NENDO'
                                                                     -- 年度
                                                    ,gv_forecast_year
                                                    ,gv_tkn_sedai    -- トークン'SEDAI'
                                                                     -- 世代
                                                    ,gv_forecast_version)
                                                    ,1
                                                    ,5000);
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;                                            --# 任意 #
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_f_degi_hanbai;
--
--
  /**********************************************************************************
   * Procedure Name   : get_f_degi_keikaku
   * Description      : A-4-3 計画商品Forecast名抽出
   ***********************************************************************************/
  PROCEDURE get_f_degi_keikaku(
    in_if_data_tbl           IN  forecast_tbl,
    in_if_data_cnt           IN  NUMBER,          -- 処理中のIFデータカウンタ
    ov_errbuf                OUT NOCOPY VARCHAR2, -- エラー・メッセージ           --# 固定 #
    ov_retcode               OUT NOCOPY VARCHAR2, -- リターン・コード             --# 固定 #
    ov_errmsg                OUT NOCOPY VARCHAR2) -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_f_degi_keikaku'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- Forecast名の抽出
    SELECT  mfd.forecast_designator,                      -- Forecast名
            mfd.organization_id                           -- 在庫組織ID
    INTO    gv_3f_forecast_designator,                    -- Forecast名
            gn_3f_organization_id                         -- 在庫組織
    FROM    mrp_forecast_designators  mfd               -- Forecast名テーブル
    WHERE   mfd.attribute1 = gv_cons_fc_type_keikaku      -- Forecast分類('計画商品')
      AND   mfd.attribute2 = in_if_data_tbl(in_if_data_cnt).location_code  -- 出荷倉庫
      AND   mfd.attribute3 = in_if_data_tbl(in_if_data_cnt).base_code;     -- 拠点
--7
  EXCEPTION
    -- Forecast名が妥当でない(存在しない)場合の後処理
    WHEN NO_DATA_FOUND THEN                           --*** データなし例外 ***
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_inv    -- 'XXINV'
                                                            -- 計画商品フォーキャスト名取得エラー
                                                     ,gv_msg_10a_058
                                                     ,gv_tkn_soko    -- トークン'SOKO'
                                                                               -- 出庫倉庫
                                                     ,in_if_data_tbl(in_if_data_cnt).location_code
                                                     ,gv_tkn_kyoten  -- トークン'KYOTEN'
                                                                               -- 拠点
                                                     ,in_if_data_tbl(in_if_data_cnt).base_code)
                                                     ,1
                                                     ,5000);
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;                                            --# 任意 #
--
    -- Forecast名が複数ヒットした場合の後処理
    WHEN TOO_MANY_ROWS THEN
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_inv   -- 'XXINV'
                                                            -- 計画商品フォーキャスト名重複エラー
                                                    ,gv_msg_10a_066
                                                    ,gv_tkn_soko    -- トークン'SOKO'
                                                                    -- 出庫倉庫
                                                    ,in_if_data_tbl(in_if_data_cnt).location_code
                                                    ,gv_tkn_kyoten  -- トークン'KYOTEN'
                                                                    -- 拠点
                                                    ,in_if_data_tbl(in_if_data_cnt).base_code)
                                                    ,1
                                                    ,5000);
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;                                            --# 任意 #
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_f_degi_keikaku;
--
--
  /**********************************************************************************
   * Procedure Name   : get_f_degi_seigen_a
   * Description      : A-5-3 出荷数制限AForecast名抽出
   ***********************************************************************************/
  PROCEDURE get_f_degi_seigen_a(
    in_if_data_tbl           IN  forecast_tbl,
    in_if_data_cnt           IN  NUMBER,          -- 処理中のIFデータカウンタ
    ov_errbuf                OUT NOCOPY VARCHAR2, -- エラー・メッセージ           --# 固定 #
    ov_retcode               OUT NOCOPY VARCHAR2, -- リターン・コード             --# 固定 #
    ov_errmsg                OUT NOCOPY VARCHAR2) -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_f_degi_seigen_a'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- Forecast名の抽出
    SELECT  mfd.forecast_designator,                      -- Forecast名
            mfd.organization_id                           -- 在庫組織ID
    INTO    gv_3f_forecast_designator,                    -- Forecast名
            gn_3f_organization_id                         -- 在庫組織
    FROM    mrp_forecast_designators  mfd               -- Forecast名テーブル
    WHERE   mfd.attribute1 = gv_cons_fc_type_seigen_a     -- Forecast分類('出荷数制限A')
      AND   mfd.attribute3 = in_if_data_tbl(in_if_data_cnt).base_code;   -- 拠点
--
  EXCEPTION
    -- Forecast名が妥当でない(存在しない)場合の後処理
    WHEN NO_DATA_FOUND THEN
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_inv   -- 'XXINV'
                                                         -- 出荷数制限Aフォーキャスト名取得エラー
                                                    ,gv_msg_10a_019
                                                    ,gv_tkn_kyoten  -- トークン'KYOTEN'
                                                                    -- '拠点'
                                                    ,in_if_data_tbl(in_if_data_cnt).base_code)
                                                    ,1
                                                    ,5000);
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;                                            --# 任意 #
--
    -- Forecast名が複数ヒットした場合の後処理
    WHEN TOO_MANY_ROWS THEN
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_inv   -- 'XXINV'
                                                          -- 出荷数制限Aフォーキャスト名重複エラー
                                                    ,gv_msg_10a_064
                                                    ,gv_tkn_kyoten  -- トークン'KYOTEN'
                                                                    -- 拠点
                                                    ,in_if_data_tbl(in_if_data_cnt).base_code)
                                                    ,1
                                                    ,5000);
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;                                            --# 任意 #
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_f_degi_seigen_a;
--
  /**********************************************************************************
   * Procedure Name   : get_f_degi_seigen_b
   * Description      : A-6-3 出荷数制限BForecast名抽出
   ***********************************************************************************/
  PROCEDURE get_f_degi_seigen_b(
    in_if_data_tbl           IN  forecast_tbl,
    in_if_data_cnt           IN  NUMBER,          -- 処理中のIFデータカウンタ
    ov_errbuf                OUT NOCOPY VARCHAR2, -- エラー・メッセージ           --# 固定 #
    ov_retcode               OUT NOCOPY VARCHAR2, -- リターン・コード             --# 固定 #
    ov_errmsg                OUT NOCOPY VARCHAR2) -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_f_degi_seigen_b'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- 入力パラメータの取込部署抽出フラグが'Yes'の場合
    IF (gv_in_dept_code_flg = gv_cons_flg_yes) THEN
--
      -- Forecast名の抽出
      SELECT  mfd.forecast_designator,                      -- Forecast名
              mfd.organization_id                           -- 在庫組織ID
      INTO    gv_3f_forecast_designator,                    -- Forecast名
              gn_3f_organization_id                         -- 在庫組織
      FROM    mrp_forecast_designators  mfd               -- Forecast名テーブル
      WHERE   mfd.attribute1 = gv_cons_fc_type_seigen_b     -- Forecast分類('出荷数制限B')
        AND   mfd.attribute2 = in_if_data_tbl(in_if_data_cnt).location_code  -- 出荷倉庫
        AND   mfd.attribute4 = in_if_data_tbl(in_if_data_cnt).dept_code      -- 取込部署
        AND   mfd.attribute4 = gv_location_code;            -- 事業所コード
--
    -- 入力パラメータの取込部署抽出フラグが'No'の場合
    ELSE
      -- Forecast名の抽出
      SELECT  mfd.forecast_designator,                      -- Forecast名
              mfd.organization_id                           -- 在庫組織ID
      INTO    gv_3f_forecast_designator,                    -- Forecast名
              gn_3f_organization_id                         -- 在庫組織
      FROM    mrp_forecast_designators  mfd               -- Forecast名テーブル
      WHERE   mfd.attribute1 = gv_cons_fc_type_seigen_b     -- Forecast分類('出荷数制限B')
        AND   mfd.attribute2 = in_if_data_tbl(in_if_data_cnt).location_code  -- 出荷倉庫
        AND   mfd.attribute4 = in_if_data_tbl(in_if_data_cnt).dept_code;     -- 取込部署
    END IF;
--
  EXCEPTION
    -- Forecast名が妥当でない(存在しない)場合の後処理
    WHEN NO_DATA_FOUND THEN                           --*** データなし例外 ***
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_inv   -- 'XXINV'
                                                         -- 出荷数制限Bフォーキャスト名取得エラー
                                                    ,gv_msg_10a_020
                                                    ,gv_tkn_soko    -- トークン'SOKO'
                                                                    -- 出庫倉庫
                                                    ,in_if_data_tbl(in_if_data_cnt).location_code
                                                    ,gv_tkn_busho   -- トークン'BUSHO'
                                                                    -- '取込部署'
                                                    ,in_if_data_tbl(in_if_data_cnt).dept_code)
                                                    ,1
                                                    ,5000);
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;                                            --# 任意 #
--
    -- Forecast名が複数ヒットした場合の後処理
    WHEN TOO_MANY_ROWS THEN
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_inv   -- 'XXINV'
                                                          -- 出荷数制限Bフォーキャスト名重複エラー
                                                    ,gv_msg_10a_065
                                                    ,gv_tkn_soko    -- トークン'SOKO'
                                                                    -- 出庫倉庫
                                                    ,in_if_data_tbl(in_if_data_cnt).location_code
                                                    ,gv_tkn_busho   -- トークン'BUSHO'
                                                                    -- 取込部署
                                                    ,in_if_data_tbl(in_if_data_cnt).dept_code)
                                                    ,1
                                                    ,5000);
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;                                            --# 任意 #
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_f_degi_seigen_b;
--
  /**********************************************************************************
   * Procedure Name   : get_f_dates_hikitori
   * Description      : A-2-4 引取計画Forecast日付抽出
   ***********************************************************************************/
  PROCEDURE get_f_dates_hikitori(
    ov_data_flg              OUT NUMBER,          -- 削除対象(1:あり, 0:なし)
    ov_errbuf                OUT NOCOPY VARCHAR2, -- エラー・メッセージ           --# 固定 #
    ov_retcode               OUT NOCOPY VARCHAR2, -- リターン・コード             --# 固定 #
    ov_errmsg                OUT NOCOPY VARCHAR2) -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_f_dates_hikitori'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
  lv_4f_txns_id
             mrp_forecast_dates.transaction_id%TYPE;                  -- 取引ID
  lv_4f_forecast_designator
             mrp_forecast_dates.forecast_designator%TYPE;             -- Forecast名
  lv_4f_organization_id
             mrp_forecast_dates.organization_id%TYPE;                 -- 在庫組織
  lv_4f_item_id
             mrp_forecast_dates.inventory_item_id%TYPE;               -- 品目
  ld_4f_start_date_active
             mrp_forecast_dates.forecast_date%TYPE;                   -- 開始日付
  ld_4f_end_date_active
             mrp_forecast_dates.rate_end_date%TYPE;                   -- 終了日付
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- 対象データ有り無しフラグの初期データセット（あり）
    ov_data_flg := gn_cons_data_found;
--
    -- あらいがえ対象データの抽出
    SELECT  mfd.transaction_id,          -- 取引ID
            mfd.forecast_designator,     -- Forecast名
            mfd.organization_id,         -- 在庫組織ID
            mfd.inventory_item_id,       -- 品目ID
            mfd.forecast_date,           -- 開始日付
            mfd.rate_end_date            -- 終了日付
    INTO    lv_4f_txns_id,               -- 取引ID
            lv_4f_forecast_designator,   -- Forecast名
            lv_4f_organization_id,       -- 在庫組織
            lv_4f_item_id,               -- 品目
            ld_4f_start_date_active,     -- 開始日付
            ld_4f_end_date_active        -- 終了日付
    FROM    mrp_forecast_dates  mfd,   -- Forecast日付
            mrp_forecast_items  mfi    -- Forecast品目
    WHERE   mfd.forecast_designator      = gv_3f_forecast_designator   -- Forecast名
      AND   mfd.organization_id          = gn_3f_organization_id       -- 在庫組織
      AND   TO_CHAR(mfd.forecast_date,'YYYYMM') = gv_in_yyyymm  -- 入力年月
      AND   mfd.organization_id          = mfi.organization_id
      AND   mfd.inventory_item_id        = mfi.inventory_item_id
      AND   ROWNUM                       = 1;
--
  EXCEPTION
    -- 削除対象データがない場合の後処理
    WHEN NO_DATA_FOUND THEN                        --*** データなし例外 ***
      ov_data_flg :=  gn_cons_no_data_found;       -- 対象データ有り無しフラグに「なし」をセット
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_f_dates_hikitori;
--
--
  /**********************************************************************************
   * Procedure Name   : get_f_dates_hanbai
   * Description      : A-3-4 販売計画Forecast日付抽出
   ***********************************************************************************/
  PROCEDURE get_f_dates_hanbai(
    ov_data_flg              OUT NUMBER,          -- 削除対象(1:あり, 0:なし)
    ov_errbuf                OUT NOCOPY VARCHAR2, -- エラー・メッセージ           --# 固定 #
    ov_retcode               OUT NOCOPY VARCHAR2, -- リターン・コード             --# 固定 #
    ov_errmsg                OUT NOCOPY VARCHAR2) -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_f_dates_hanbai'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    lb_retcode                  BOOLEAN;
--
    -- *** ローカル・カーソル ***
--add start 1.8
    CURSOR cur_del_if IS
      SELECT  mfd.transaction_id,          -- 取引ID
              mfd.forecast_designator,     -- Forecast名
              mfd.organization_id,         -- 在庫組織ID
              mfd.inventory_item_id,       -- 品目ID
              mfd.forecast_date,           -- 開始日付
              mfd.rate_end_date            -- 終了日付
      FROM    mrp_forecast_dates  mfd,   -- Forecast日付
              mrp_forecast_items  mfi    -- Forecast品目
      WHERE   mfd.forecast_designator        = gv_3f_forecast_designator   -- Forecast名
        AND   mfd.organization_id            = gn_3f_organization_id       -- 在庫組織
        AND   mfd.forecast_designator        = mfi.forecast_designator
        AND   mfd.organization_id            = mfi.organization_id
        AND   mfd.inventory_item_id          = mfi.inventory_item_id
      ;
--
    TYPE lr_del_if IS RECORD(
      transaction_id       mrp_forecast_dates.transaction_id%TYPE
     ,forecast_designator  mrp_forecast_dates.forecast_designator%TYPE
     ,organization_id      mrp_forecast_dates.organization_id%TYPE
     ,inventory_item_id    mrp_forecast_dates.inventory_item_id%TYPE
     ,forecast_date        mrp_forecast_dates.forecast_date%TYPE
     ,rate_end_date        mrp_forecast_dates.rate_end_date%TYPE
    );
--
    TYPE lt_del_if_tbl IS TABLE OF lr_del_if INDEX BY BINARY_INTEGER;
    lt_del_if lt_del_if_tbl;
--add end 1.8
--
    -- *** ローカル・レコード ***
    t_forecast_interface_tab_del    MRP_FORECAST_INTERFACE_PK.t_forecast_interface;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- 対象データ有り無しフラグの初期データセット（あり）
    ov_data_flg := gn_cons_data_found;
--
--mod start 1.8
/*
    -- あらいがえ対象データの抽出
    SELECT  mfd.transaction_id,          -- 取引ID
            mfd.forecast_designator,     -- Forecast名
            mfd.organization_id,         -- 在庫組織ID
            mfd.inventory_item_id,       -- 品目ID
            mfd.forecast_date,           -- 開始日付
            mfd.rate_end_date            -- 終了日付
    INTO    gv_4h_txns_id,               -- 取引ID
            gv_4h_forecast_designator,   -- Forecast名
            gv_4h_organization_id,       -- 在庫組織
            gv_4h_item_id,               -- 品目
            gd_4h_start_date_active,     -- 開始日付
            gd_4h_end_date_active        -- 終了日付
    FROM    mrp_forecast_dates  mfd,   -- Forecast日付
            mrp_forecast_items  mfi    -- Forecast品目
    WHERE   mfd.forecast_designator        = gv_3f_forecast_designator   -- Forecast名
      AND   mfd.organization_id            = gn_3f_organization_id       -- 在庫組織
and mfd.FORECAST_DESIGNATOR = mfi.FORECAST_DESIGNATOR
      AND   mfd.organization_id            = mfi.organization_id
      AND   mfd.inventory_item_id          = mfi.inventory_item_id
      AND   ROWNUM                         = 1;

--
      -- 登録済みデータの削除のためのデータセット
      t_forecast_interface_tab_del(1).transaction_id        := gv_4h_txns_id;            -- 取引ID
      t_forecast_interface_tab_del(1).forecast_designator   := gv_4h_forecast_designator;-- Forecast名
      t_forecast_interface_tab_del(1).organization_id       := gv_4h_organization_id;    -- 組織ID
      t_forecast_interface_tab_del(1).inventory_item_id     := gv_4h_item_id;            -- 品目ID
      t_forecast_interface_tab_del(1).quantity              := 0;                        -- 数量
      t_forecast_interface_tab_del(1).forecast_date         := gd_4h_start_date_active;  -- 開始日付
      t_forecast_interface_tab_del(1).forecast_end_date     := gd_4h_end_date_active;    -- 終了日付
      t_forecast_interface_tab_del(1).bucket_type           := 1;
      t_forecast_interface_tab_del(1).process_status        := 2;
      t_forecast_interface_tab_del(1).confidence_percentage := 100;
--
*/
    OPEN cur_del_if;
    FETCH cur_del_if BULK COLLECT INTO lt_del_if;
    CLOSE cur_del_if;
--
    FOR i IN 1..lt_del_if.COUNT LOOP
      -- 登録済みデータの削除のためのデータセット
      t_forecast_interface_tab_del(i).transaction_id        := lt_del_if(i).transaction_id;    -- 取引ID
      t_forecast_interface_tab_del(i).forecast_designator   := gv_3f_forecast_designator;      -- Forecast名
      t_forecast_interface_tab_del(i).organization_id       := gn_3f_organization_id;          -- 組織ID
      t_forecast_interface_tab_del(i).inventory_item_id     := lt_del_if(i).inventory_item_id; -- 品目ID
      t_forecast_interface_tab_del(i).quantity              := 0;                              -- 数量
      t_forecast_interface_tab_del(i).forecast_date         := lt_del_if(i).forecast_date;     -- 開始日付
      t_forecast_interface_tab_del(i).forecast_end_date     := lt_del_if(i).rate_end_date;     -- 終了日付
      t_forecast_interface_tab_del(i).bucket_type           := 1;
      t_forecast_interface_tab_del(i).process_status        := 2;
      t_forecast_interface_tab_del(i).confidence_percentage := 100;
    END LOOP;
--mod end 1.8
      -- 登録済みデータの削除
      lb_retcode := MRP_FORECAST_INTERFACE_PK.MRP_FORECAST_INTERFACE(
                                            t_forecast_interface_tab_del);
--                                            t_forecast_interface_tab_del,
--                                            t_forecast_designator_tab);
      -- エラーだった場合
-- mod start 1.11
--      IF (lb_retcode = FALSE )THEN
--      IF ( t_forecast_interface_tab_del(1).process_status <> 5 ) THEN
      FOR i IN 1..lt_del_if.COUNT LOOP
        IF ( t_forecast_interface_tab_del(i).process_status <> 5 ) THEN
          lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_cmn  -- 'XXCMN'
                                                        ,gv_msg_10a_045  -- APIエラー
                                                        ,gv_tkn_api_name
                                                        ,gv_cons_api)    -- 予測API
                                                        ,1
                                                        ,5000);
          FND_FILE.PUT_LINE(FND_FILE.LOG,t_forecast_interface_tab_del(i).error_message);
          RAISE global_api_expt;
        END IF;
      END LOOP;
-- mod end 1.11
--
  EXCEPTION
    -- 削除対象データがない場合の後処理
    WHEN NO_DATA_FOUND THEN                        --*** データなし例外 ***
      ov_data_flg :=  gn_cons_no_data_found;       -- 対象データ有り無しフラグに「なし」をセット
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_f_dates_hanbai;
--
  /**********************************************************************************
   * Procedure Name   : get_f_dates_keikaku
   * Description      : A-4-4 計画商品Forecast日付抽出
   ***********************************************************************************/
  PROCEDURE get_f_dates_keikaku(
    in_if_data_tbl           IN  forecast_tbl,
    in_if_data_cnt           IN  NUMBER,          -- 処理中のIFデータカウンタ
    ov_data_flg              OUT NUMBER,          -- 削除対象(1:あり, 0:なし)
    ov_errbuf                OUT NOCOPY VARCHAR2, -- エラー・メッセージ           --# 固定 #
    ov_retcode               OUT NOCOPY VARCHAR2, -- リターン・コード             --# 固定 #
    ov_errmsg                OUT NOCOPY VARCHAR2) -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_f_dates_keikaku'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    lv_4f_txns_id
             mrp_forecast_dates.transaction_id%TYPE;                  -- 取引ID
    lv_4f_forecast_designator
             mrp_forecast_dates.forecast_designator%TYPE;             -- Forecast名
    lv_4f_organization_id
             mrp_forecast_dates.organization_id%TYPE;                 -- 在庫組織
    lv_4f_item_id
             mrp_forecast_dates.inventory_item_id%TYPE;               -- 品目
    ld_4f_start_date_active
             mrp_forecast_dates.forecast_date%TYPE;                   -- 開始日付
    ld_4f_end_date_active
             mrp_forecast_dates.rate_end_date%TYPE;                   -- 終了日付
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- 対象データ有り無しフラグの初期データセット（あり）
    ov_data_flg := gn_cons_data_found;
--
    -- あらいがえ対象データの抽出
    SELECT  mfd.transaction_id,          -- 取引ID
            mfd.forecast_designator,     -- Forecast名
            mfd.organization_id,         -- 在庫組織ID
            mfd.inventory_item_id,       -- 品目ID
            mfd.forecast_date,           -- 開始日付
            mfd.rate_end_date            -- 終了日付
    INTO    lv_4f_txns_id,               -- 取引ID
            lv_4f_forecast_designator,   -- Forecast名
            lv_4f_organization_id,       -- 在庫組織
            lv_4f_item_id,               -- 品目
            gd_4k_start_date_active,     -- 開始日付
            gd_4k_end_date_active        -- 終了日付
    FROM    mrp_forecast_dates  mfd,   -- Forecast日付
            mrp_forecast_items  mfi,   -- Forecast品目
            ic_item_mst_vl        im,    -- OPM品目マスタ
            mtl_system_items_vl   si     -- 品目マスタ
    WHERE   mfd.organization_id        = mfi.organization_id                      -- 在庫組織ID
      AND   mfd.inventory_item_id      = mfi.inventory_item_id                    -- 品目ID
      AND   mfd.forecast_designator    = gv_3f_forecast_designator                -- Forecast名
      AND   mfd.organization_id        = gn_3f_organization_id                    -- 在庫組織ID
      AND   mfi.forecast_designator    = mfd.forecast_designator
      AND   si.organization_id         = mfd.organization_id
      AND   mfd.attribute5             = in_if_data_tbl(in_if_data_cnt).base_code -- 拠点
      AND   im.item_no                 = in_if_data_tbl(in_if_data_cnt).item_code -- 品目コード
      AND   im.item_no                 = si.segment1                              -- 品目コード
      AND   si.inventory_item_id       = mfd.inventory_item_id                    -- 品目ID
      AND   ((gd_keikaku_start_date   >= mfd.forecast_date
              AND
              gd_keikaku_start_date   <= mfd.rate_end_date)
        OR   (gd_keikaku_end_date     >= mfd.forecast_date
              AND
              gd_keikaku_end_date     <= mfd.rate_end_date))
      AND   ROWNUM                     = 1;
--
  EXCEPTION
    -- 削除対象データがない場合の後処理
    WHEN NO_DATA_FOUND THEN                        --*** データなし例外 ***
      ov_data_flg :=  gn_cons_no_data_found;       -- 対象データ有り無しフラグに「なし」をセット
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_f_dates_keikaku;
--
  /**********************************************************************************
   * Procedure Name   : get_f_dates_seigen_a
   * Description      : A-5-4 出荷数制限AForecast日付抽出
   ***********************************************************************************/
  PROCEDURE get_f_dates_seigen_a(
    in_if_data_tbl           IN  forecast_tbl,
    in_if_data_cnt           IN  NUMBER,          -- 処理中のIFデータカウンタ
    ov_data_flg              OUT NUMBER,          -- 削除対象(1:あり, 0:なし)
    ov_errbuf                OUT NOCOPY VARCHAR2, -- エラー・メッセージ           --# 固定 #
    ov_retcode               OUT NOCOPY VARCHAR2, -- リターン・コード             --# 固定 #
    ov_errmsg                OUT NOCOPY VARCHAR2) -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_f_dates_seigen_a'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    lv_4f_txns_id
             mrp_forecast_dates.transaction_id%TYPE;                  -- 取引ID
    lv_4f_forecast_designator
             mrp_forecast_dates.forecast_designator%TYPE;             -- Forecast名
    lv_4f_organization_id
             mrp_forecast_dates.organization_id%TYPE;                 -- 在庫組織
    lv_4f_item_id
             mrp_forecast_dates.inventory_item_id%TYPE;               -- 品目
    ld_4f_start_date_active
             mrp_forecast_dates.forecast_date%TYPE;                   -- 開始日付
    ld_4f_end_date_active
             mrp_forecast_dates.rate_end_date%TYPE;                   -- 終了日付
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- 対象データ有り無しフラグの初期データセット（あり）
    ov_data_flg := gn_cons_data_found;
--
    -- あらいがえ対象データの抽出
    SELECT  mfd.transaction_id,          -- 取引ID
            mfd.forecast_designator,     -- Forecast名
            mfd.organization_id,         -- 在庫組織ID
            mfd.inventory_item_id,       -- 品目ID
            mfd.forecast_date,           -- 開始日付
            mfd.rate_end_date            -- 終了日付
    INTO    lv_4f_txns_id,               -- 取引ID
            lv_4f_forecast_designator,   -- Forecast名
            lv_4f_organization_id,       -- 在庫組織
            lv_4f_item_id,               -- 品目
            ld_4f_start_date_active,     -- 開始日付
            ld_4f_end_date_active        -- 終了日付
    FROM    mrp_forecast_dates  mfd,   -- Forecast日付
            mrp_forecast_items  mfi,   -- Forecast品目
            ic_item_mst_vl        im,    -- OPM品目マスタ
            mtl_system_items_vl   si     -- 品目マスタ
    WHERE   mfd.organization_id        = mfi.organization_id       -- 在庫組織ID
      AND   mfd.inventory_item_id      = mfi.inventory_item_id     -- 品目ID
      AND   mfd.forecast_designator    = gv_3f_forecast_designator -- Forecast名
      AND   mfd.organization_id        = gn_3f_organization_id     -- 在庫組織ID
      AND   mfi.forecast_designator    = mfd.forecast_designator
      AND   si.organization_id         = mfd.organization_id
      AND   im.item_no                 = in_if_data_tbl(in_if_data_cnt).item_code -- 品目コード
      AND   im.item_no                 = si.segment1               -- 品目コード
      AND   si.inventory_item_id       = mfd.inventory_item_id     -- 品目ID
      AND   ((gd_in_start_date         >= mfd.forecast_date
              AND
              gd_in_start_date         <= mfd.rate_end_date)
        OR   (gd_in_end_date           >= mfd.forecast_date
              AND
              gd_in_end_date           <= mfd.rate_end_date))
      AND   ROWNUM                     = 1;
--
  EXCEPTION
    -- 削除対象データがない場合の後処理
    WHEN NO_DATA_FOUND THEN                        --*** データなし例外 ***
      ov_data_flg :=  gn_cons_no_data_found;       -- 対象データ有り無しフラグに「なし」をセット
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_f_dates_seigen_a;
--
  /**********************************************************************************
   * Procedure Name   : get_f_dates_seigen_b
   * Description      : A-6-4 出荷数制限BForecast日付抽出
   ***********************************************************************************/
  PROCEDURE get_f_dates_seigen_b(
    in_if_data_tbl           IN  forecast_tbl,
    in_if_data_cnt           IN  NUMBER,          -- 処理中のIFデータカウンタ
    ov_data_flg              OUT NUMBER,          -- 削除対象(1:あり, 0:なし)
    ov_errbuf                OUT NOCOPY VARCHAR2, -- エラー・メッセージ           --# 固定 #
    ov_retcode               OUT NOCOPY VARCHAR2, -- リターン・コード             --# 固定 #
    ov_errmsg                OUT NOCOPY VARCHAR2) -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_f_dates_seigen_b'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    lv_4f_txns_id
             mrp_forecast_dates.transaction_id%TYPE;                  -- 取引ID
    lv_4f_forecast_designator
             mrp_forecast_dates.forecast_designator%TYPE;             -- Forecast名
    lv_4f_organization_id
             mrp_forecast_dates.organization_id%TYPE;                 -- 在庫組織
    lv_4f_item_id
             mrp_forecast_dates.inventory_item_id%TYPE;               -- 品目
    ld_4f_start_date_active
             mrp_forecast_dates.forecast_date%TYPE;                   -- 開始日付
    ld_4f_end_date_active
             mrp_forecast_dates.rate_end_date%TYPE;                   -- 終了日付
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- 対象データ有り無しフラグの初期データセット（あり）
    ov_data_flg := gn_cons_data_found;
--
    -- あらいがえ対象データの抽出
    SELECT  mfd.transaction_id,          -- 取引ID
            mfd.forecast_designator,     -- Forecast名
            mfd.organization_id,         -- 在庫組織ID
            mfd.inventory_item_id,       -- 品目ID
            mfd.forecast_date,           -- 開始日付
            mfd.rate_end_date            -- 終了日付
    INTO    lv_4f_txns_id,               -- 取引ID
            lv_4f_forecast_designator,   -- Forecast名
            lv_4f_organization_id,       -- 在庫組織
            lv_4f_item_id,               -- 品目
            ld_4f_start_date_active,     -- 開始日付
            ld_4f_end_date_active        -- 終了日付
    FROM    mrp_forecast_dates  mfd,   -- Forecast日付
            mrp_forecast_items  mfi,   -- Forecast品目
            ic_item_mst_vl        im,    -- OPM品目マスタ
            mtl_system_items_vl   si     -- 品目マスタ
    WHERE   mfd.organization_id        = mfi.organization_id       -- 在庫組織ID
      AND   mfd.inventory_item_id      = mfi.inventory_item_id     -- 品目ID
      AND   mfd.forecast_designator    = gv_3f_forecast_designator -- Forecast名
      AND   mfd.organization_id        = gn_3f_organization_id     -- 在庫組織ID
      AND   mfi.forecast_designator    = mfd.forecast_designator
      AND   si.organization_id         = mfd.organization_id
      AND   im.item_no                 = in_if_data_tbl(in_if_data_cnt).item_code -- 品目コード
      AND   im.item_no                 = si.segment1               -- 品目コード
      AND   si.inventory_item_id       = mfd.inventory_item_id     -- 品目ID
      AND   ((gd_in_start_date         >= mfd.forecast_date
              AND
              gd_in_start_date         <= mfd.rate_end_date)
        OR   (gd_in_end_date           >= mfd.forecast_date
              AND
              gd_in_end_date           <= mfd.rate_end_date))
      AND   ROWNUM                     = 1;
--
  EXCEPTION
    -- 削除対象データがない場合の後処理
    WHEN NO_DATA_FOUND THEN                        --*** データなし例外 ***
      ov_data_flg :=  gn_cons_no_data_found;       -- 対象データ有り無しフラグに「なし」をセット
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_f_dates_seigen_b;
--
  /**********************************************************************************
   * Procedure Name   : put_forecast_hikitori
   * Description      : A-2-5 引取計画Forecast登録
   ***********************************************************************************/
  PROCEDURE put_forecast_hikitori(
    in_if_data_tbl           IN  forecast_tbl,
    in_if_data_cnt           IN  NUMBER,          -- 処理中のIFデータカウンタ
    in_data_flg              IN  NUMBER,          -- 削除データ有り無しフラグ(0:なし, 1:あり)
    ov_errbuf                OUT NOCOPY VARCHAR2, -- エラー・メッセージ           --# 固定 #
    ov_retcode               OUT NOCOPY VARCHAR2, -- リターン・コード             --# 固定 #
    ov_errmsg                OUT NOCOPY VARCHAR2) -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'put_forecast_hikitori'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    ln_number_of_case           NUMBER := 0;                          -- ケース入数(NUMBER)
    lv_number_of_case           ic_item_mst_vl.attribute11%TYPE; -- ケース入数(VARCHAR2)
    ln_inventory_item_id        NUMBER;      -- 品目ID
    ln_quantity                 NUMBER;      -- 全数量
    t_forecast_interface_tab    MRP_FORECAST_INTERFACE_PK.t_forecast_interface;
    t_forecast_designator_tab   MRP_FORECAST_INTERFACE_PK.t_forecast_designator;
    lb_retcode                  BOOLEAN;
    ln_target_cnt               NUMBER := 0;
--
    -- *** ローカル・カーソル ***
    -- あらいがえ対象データの抽出
    CURSOR forecast_araigae_cur
    IS
    SELECT  mfd.transaction_id,          -- 取引ID
            mfd.forecast_designator,     -- Forecast名
            mfd.organization_id,         -- 在庫組織ID
            mfd.inventory_item_id,       -- 品目ID
            mfd.forecast_date,           -- 開始日付
-- mod start ver1.15
--            mfd.rate_end_date            -- 終了日付
            mfd.rate_end_date,           -- 終了日付
            NULL,                          -- 品目コード
            mfd.current_forecast_quantity, -- 数量
            mfd.attribute6,                -- 元ケース数量
            mfd.attribute4                 -- 元バラ数量
-- mod end ver1.15
    FROM    mrp_forecast_dates  mfd,   -- Forecast日付
            mrp_forecast_items  mfi    -- Forecast品目
    WHERE   mfd.forecast_designator      = gv_3f_forecast_designator   -- Forecast名
      AND   mfd.organization_id          = gn_3f_organization_id       -- 在庫組織
      AND   TO_CHAR(mfd.forecast_date,'YYYYMM') = gv_in_yyyymm  -- 入力年月
      AND   mfd.organization_id          = mfi.organization_id
--mod start kumamoto
and mfd.FORECAST_DESIGNATOR = mfi.FORECAST_DESIGNATOR
--mod end kumamoto
      AND   mfd.inventory_item_id        = mfi.inventory_item_id;
--
    -- *** ローカル・レコード ***
    lr_araigae_data     araigae_tbl;
    t_forecast_interface_tab_del    MRP_FORECAST_INTERFACE_PK.t_forecast_interface;
    t_forecast_interface_tab_ins    MRP_FORECAST_INTERFACE_PK.t_forecast_interface;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- 登録する数量を算出するために品目マスタからケース入数を抽出する
    -- 条件に主キーがあるためNO_DATA_FOUNDにはならない
    SELECT im.attribute11,             -- ケース入り数
           si.inventory_item_id
    INTO   lv_number_of_case,
           ln_inventory_item_id
    FROM   ic_item_mst_vl      im,     -- OPM品目マスタ
           mtl_system_items_vl si      -- 品目マスタ
    WHERE  im.item_no   = in_if_data_tbl(in_if_data_cnt).item_code
      AND  im.item_no   = si.segment1
      AND  ROWNUM       = 1;
--
    -- ケース数量が>0 の場合はケース入り数を変換する→変換エラーはエラーとする
    -- ケース数量が>0 の時だけケース入り数が必要となるので上記SQLでは一旦VARCHAR型
    -- で受け取っておき(TO_NUMBERしない)、ここで変換してNULLや文字であれば例外にて処理する
    IF (in_if_data_tbl(in_if_data_cnt).case_quantity > 0) THEN
      ln_number_of_case := TO_NUMBER(lv_number_of_case);
      -- NULLはINVALID_NUMBER例外が発生しないためにここでRAISEする
      IF ( lv_number_of_case IS NULL ) THEN
        RAISE null_expt;
      END IF;
    END IF;
    -- 全数量を算出する(ケース数量*ケース入数+バラ数量)
    ln_quantity := in_if_data_tbl(in_if_data_cnt).case_quantity * ln_number_of_case
                   + in_if_data_tbl(in_if_data_cnt).quantity;
--
-- mod start 1.11
    -- 登録のためのデータセット
--    t_forecast_interface_tab_ins(1).forecast_designator   := gv_3f_forecast_designator;
--    t_forecast_interface_tab_ins(1).organization_id       := gn_3f_organization_id;
--    t_forecast_interface_tab_ins(1).inventory_item_id     := ln_inventory_item_id;
--    t_forecast_interface_tab_ins(1).quantity              := ln_quantity;
--    t_forecast_interface_tab_ins(1).forecast_date         :=
--                                          in_if_data_tbl(in_if_data_cnt).start_date_active;
--    t_forecast_interface_tab_ins(1).forecast_end_date     :=
--                                          in_if_data_tbl(in_if_data_cnt).end_date_active;
--    t_forecast_interface_tab_ins(1).attribute5            :=
--                                          in_if_data_tbl(in_if_data_cnt).base_code;
--    t_forecast_interface_tab_ins(1).attribute6            :=
--                                          in_if_data_tbl(in_if_data_cnt).case_quantity;
--    t_forecast_interface_tab_ins(1).attribute4            :=
--                                          in_if_data_tbl(in_if_data_cnt).quantity;
--    t_forecast_interface_tab_ins(1).attribute2            := in_if_data_tbl(in_if_data_cnt).price;
--    t_forecast_interface_tab_ins(1).bucket_type           := 1;
--    t_forecast_interface_tab_ins(1).process_status        := 2;
--    t_forecast_interface_tab_ins(1).confidence_percentage := 100;
--
-- 2008/08/01 Add ↓
--    t_forecast_interface_tab_ins(1).last_update_date       := gd_who_sysdate;
--    t_forecast_interface_tab_ins(1).last_updated_by        := gn_last_updated_by;
--    t_forecast_interface_tab_ins(1).creation_date          := gd_who_sysdate;
--    t_forecast_interface_tab_ins(1).created_by             := gn_created_by;
--    t_forecast_interface_tab_ins(1).last_update_login      := gn_login_user;
--    t_forecast_interface_tab_ins(1).request_id             := gn_request_id;
--    t_forecast_interface_tab_ins(1).program_application_id := gn_program_application_id;
--    t_forecast_interface_tab_ins(1).program_id             := gn_program_id;
--    t_forecast_interface_tab_ins(1).program_update_date    := gd_who_sysdate;
-- 2008/08/01 Add ↓
--
    -- 登録のためのデータセット
    t_forecast_interface_tab_inst(in_if_data_cnt).forecast_designator   := gv_3f_forecast_designator;
    t_forecast_interface_tab_inst(in_if_data_cnt).organization_id       := gn_3f_organization_id;
    t_forecast_interface_tab_inst(in_if_data_cnt).inventory_item_id     := ln_inventory_item_id;
    t_forecast_interface_tab_inst(in_if_data_cnt).quantity              := ln_quantity;
    t_forecast_interface_tab_inst(in_if_data_cnt).forecast_date         :=
                                          in_if_data_tbl(in_if_data_cnt).start_date_active;
    t_forecast_interface_tab_inst(in_if_data_cnt).forecast_end_date     :=
                                          in_if_data_tbl(in_if_data_cnt).end_date_active;
    t_forecast_interface_tab_inst(in_if_data_cnt).attribute5            :=
                                          in_if_data_tbl(in_if_data_cnt).base_code;
    t_forecast_interface_tab_inst(in_if_data_cnt).attribute6            :=
                                          in_if_data_tbl(in_if_data_cnt).case_quantity;
    t_forecast_interface_tab_inst(in_if_data_cnt).attribute4            :=
                                          in_if_data_tbl(in_if_data_cnt).quantity;
    t_forecast_interface_tab_inst(in_if_data_cnt).attribute2            := in_if_data_tbl(in_if_data_cnt).price;
    t_forecast_interface_tab_inst(in_if_data_cnt).bucket_type           := 1;
    t_forecast_interface_tab_inst(in_if_data_cnt).process_status        := 2;
    t_forecast_interface_tab_inst(in_if_data_cnt).confidence_percentage := 100;
    t_forecast_interface_tab_inst(in_if_data_cnt).last_update_date       := gd_who_sysdate;
    t_forecast_interface_tab_inst(in_if_data_cnt).last_updated_by        := gn_last_updated_by;
    t_forecast_interface_tab_inst(in_if_data_cnt).creation_date          := gd_who_sysdate;
    t_forecast_interface_tab_inst(in_if_data_cnt).created_by             := gn_created_by;
    t_forecast_interface_tab_inst(in_if_data_cnt).last_update_login      := gn_login_user;
    t_forecast_interface_tab_inst(in_if_data_cnt).request_id             := gn_request_id;
    t_forecast_interface_tab_inst(in_if_data_cnt).program_application_id := gn_program_application_id;
    t_forecast_interface_tab_inst(in_if_data_cnt).program_id             := gn_program_id;
    t_forecast_interface_tab_inst(in_if_data_cnt).program_update_date    := gd_who_sysdate;
--
    -- Forecastデータに抽出したインターフェースデータを登録
--    lb_retcode := MRP_FORECAST_INTERFACE_PK.MRP_FORECAST_INTERFACE(
--                                           t_forecast_interface_tab_ins,
--                                           t_forecast_designator_tab);
--
    -- エラーだった場合
--    IF ( t_forecast_interface_tab_ins(1).process_status <> 5 ) THEN
--      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_cmn    -- 'XXCMN'
--                                                    ,gv_msg_10a_045
--                                                    ,gv_tkn_api_name
--                                                    ,gv_cons_api) -- 予測API
--                                                   ,1
--                                                   ,5000);
--add start 1.9
--      FND_FILE.PUT_LINE(FND_FILE.LOG,t_forecast_interface_tab_ins(1).error_message);
--add end 1.9
--      RAISE global_api_expt;
--    END IF;
-- mod end 1.11
--
  EXCEPTION
    -- ケース入り数が不正(TO_NUMBER()でエラー)な場合の後処理
    WHEN VALUE_ERROR THEN                           --*** TO_NUMBER()でエラー ***
      -- *** 任意で例外処理を記述する ****
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_inv   -- 'XXINV'
                                                    ,gv_msg_10a_059
                                                    ,gv_tkn_item    -- トークン'ITEM'
                                                                    -- 品目コード
                                                    ,in_if_data_tbl(in_if_data_cnt).item_code)
                                                    -- ケース入り数取得エラー
                                                    ,1
                                                    ,5000);
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;                                            --# 任意 #
    WHEN null_expt THEN                                --*** ケース入り数がNULL ***
      -- *** 任意で例外処理を記述する ****
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_inv   -- 'XXINV'
                                                    ,gv_msg_10a_059  -- ケース入り数取得エラー
                                                    ,gv_tkn_item    -- トークン'ITEM'
                                                                    -- 品目コード
                                                    ,in_if_data_tbl(in_if_data_cnt).item_code)
                                                    ,1
                                                    ,5000);
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;                                            --# 任意 #
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END put_forecast_hikitori;
--
  /**********************************************************************************
   * Procedure Name   : put_forecast_hanbai
   * Description      : A-3-5 販売計画Forecast登録
   ***********************************************************************************/
  PROCEDURE  put_forecast_hanbai(
    in_if_data_tbl           IN  forecast_tbl,
    in_if_data_cnt           IN  NUMBER,          -- 処理中のIFデータカウンタ
    in_data_flg              IN  NUMBER,          -- 削除データ有り無しフラグ(0:なし, 1:あり)
    ov_errbuf                OUT NOCOPY VARCHAR2, -- エラー・メッセージ           --# 固定 #
    ov_retcode               OUT NOCOPY VARCHAR2, -- リターン・コード             --# 固定 #
    ov_errmsg                OUT NOCOPY VARCHAR2) -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'put_forecast_hanbai'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    ln_inventory_item_id        NUMBER;      -- 品目ID
    ln_number_of_case           NUMBER := 0;                     -- ケース入数(NUMBER)
    lv_number_of_case           ic_item_mst_vl.attribute11%TYPE; -- ケース入数(VARCHAR2)
    ln_quantity                 NUMBER;      -- 全数量
    lb_retcode                  BOOLEAN;
--
-- 2009/04/09 v1.20 T.Yoshimoto Add Start 本番#1350
    ln_if_cnt              NUMBER := 0;                     -- マイナス値レコードカウント
-- 2009/04/09 v1.20 T.Yoshimoto Add End 本番#1350
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
    t_forecast_interface_tab_del    MRP_FORECAST_INTERFACE_PK.t_forecast_interface;
    t_forecast_interface_tab_ins    MRP_FORECAST_INTERFACE_PK.t_forecast_interface;
    t_forecast_designator_tab   MRP_FORECAST_INTERFACE_PK.t_forecast_designator;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- 日付データがあった場合は登録済みデータの削除をおこなう
/*
    IF (in_data_flg = gn_cons_data_found) THEN
      -- 登録済みデータの削除のためのデータセット
      t_forecast_interface_tab_del(1).transaction_id        := gv_4h_txns_id;            -- 取引ID
      t_forecast_interface_tab_del(1).forecast_designator   := gv_4h_forecast_designator;-- Forecast名
      t_forecast_interface_tab_del(1).organization_id       := gv_4h_organization_id;    -- 組織ID
      t_forecast_interface_tab_del(1).inventory_item_id     := gv_4h_item_id;            -- 品目ID
      t_forecast_interface_tab_del(1).quantity              := 0;                        -- 数量
      t_forecast_interface_tab_del(1).forecast_date         := gd_4h_start_date_active;  -- 開始日付
      t_forecast_interface_tab_del(1).forecast_end_date     := gd_4h_end_date_active;    -- 終了日付
      t_forecast_interface_tab_del(1).bucket_type           := 1;
      t_forecast_interface_tab_del(1).process_status        := 2;
      t_forecast_interface_tab_del(1).confidence_percentage := 100;
--
      -- 登録済みデータの削除
      lb_retcode := MRP_FORECAST_INTERFACE_PK.MRP_FORECAST_INTERFACE(
                                            t_forecast_interface_tab_del,
                                            t_forecast_designator_tab);
      -- エラーだった場合
      IF ( t_forecast_interface_tab_del(1).process_status <> 5 ) THEN
        lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_cmn   -- 'XXCMN'
                                                      ,gv_msg_10a_045  -- APIエラー
                                                    ,gv_tkn_api_name
                                                    ,gv_cons_api) -- 予測API
                                                      ,1
                                                      ,5000);
        RAISE global_api_expt;
      END IF;
    END IF;
*/
--
    -- 登録する数量を算出するために品目マスタからケース入数を抽出する
    -- 条件に主キーがあるためNO_DATA_FOUNDにはならない
    SELECT im.attribute11,             -- ケース入り数
           si.inventory_item_id
    INTO   lv_number_of_case,
           ln_inventory_item_id
    FROM   ic_item_mst_vl      im,     -- OPM品目マスタ
           mtl_system_items_vl si      -- 品目マスタ
    WHERE  im.item_no   = in_if_data_tbl(in_if_data_cnt).item_code
      AND  im.item_no   = si.segment1
      AND  ROWNUM       = 1;
--
    -- ケース数量が>0 の場合はケース入り数を変換する→変換エラーはエラーとする
    -- ケース数量が>0 の時だけケース入り数が必要となるので上記SQLでは一旦VARCHAR型
    -- で受け取っておき(TO_NUMBERしない)、ここで変換してNULLや文字であれば例外にて処理する
    IF (in_if_data_tbl(in_if_data_cnt).case_quantity > 0) THEN
      ln_number_of_case := TO_NUMBER(lv_number_of_case);
      -- NULLはVALUE_ERROR例外が発生しないためにここでRAISEする
      IF ( lv_number_of_case IS NULL ) THEN
        RAISE null_expt;
      END IF;
    END IF;
--
    -- 全数量を算出する(ケース数量*ケース入数+バラ数量)
    ln_quantity := in_if_data_tbl(in_if_data_cnt).case_quantity * ln_number_of_case
                   + in_if_data_tbl(in_if_data_cnt).quantity;
--
-- mod start 1.11
    -- 登録のためのデータセット
--    t_forecast_interface_tab_ins(1).forecast_designator   := gv_3f_forecast_designator;
--    t_forecast_interface_tab_ins(1).organization_id       := gn_3f_organization_id;
--    t_forecast_interface_tab_ins(1).inventory_item_id     := ln_inventory_item_id;
--    t_forecast_interface_tab_ins(1).quantity              := ln_quantity;
--    t_forecast_interface_tab_ins(1).forecast_date         :=
--                                         in_if_data_tbl(in_if_data_cnt).start_date_active;
--    t_forecast_interface_tab_ins(1).forecast_end_date     :=
--                                         in_if_data_tbl(in_if_data_cnt).end_date_active;
--    t_forecast_interface_tab_ins(1).attribute5            :=
--                                         in_if_data_tbl(in_if_data_cnt).base_code;
--    t_forecast_interface_tab_ins(1).attribute6            :=
--                                         in_if_data_tbl(in_if_data_cnt).case_quantity;
--    t_forecast_interface_tab_ins(1).attribute4            :=
--                                         in_if_data_tbl(in_if_data_cnt).quantity;
--    t_forecast_interface_tab_ins(1).attribute2            := in_if_data_tbl(in_if_data_cnt).price;
--    t_forecast_interface_tab_ins(1).bucket_type           := 1;
--    t_forecast_interface_tab_ins(1).process_status        := 2;
--    t_forecast_interface_tab_ins(1).confidence_percentage := 100;
--
-- 2008/08/01 Add ↓
--    t_forecast_interface_tab_ins(1).last_update_date       := gd_who_sysdate;
--    t_forecast_interface_tab_ins(1).last_updated_by        := gn_last_updated_by;
--    t_forecast_interface_tab_ins(1).creation_date          := gd_who_sysdate;
--    t_forecast_interface_tab_ins(1).created_by             := gn_created_by;
--    t_forecast_interface_tab_ins(1).last_update_login      := gn_login_user;
--    t_forecast_interface_tab_ins(1).request_id             := gn_request_id;
--    t_forecast_interface_tab_ins(1).program_application_id := gn_program_application_id;
--    t_forecast_interface_tab_ins(1).program_id             := gn_program_id;
--    t_forecast_interface_tab_ins(1).program_update_date    := gd_who_sysdate;
-- 2008/08/01 Add ↓
--
    -- 登録のためのデータセット
    t_forecast_interface_tab_inst(in_if_data_cnt).forecast_designator    := gv_3f_forecast_designator;
    t_forecast_interface_tab_inst(in_if_data_cnt).organization_id        := gn_3f_organization_id;
    t_forecast_interface_tab_inst(in_if_data_cnt).inventory_item_id      := ln_inventory_item_id;
    t_forecast_interface_tab_inst(in_if_data_cnt).quantity               := ln_quantity;
    t_forecast_interface_tab_inst(in_if_data_cnt).forecast_date          :=
                                         in_if_data_tbl(in_if_data_cnt).start_date_active;
    t_forecast_interface_tab_inst(in_if_data_cnt).forecast_end_date      :=
                                         in_if_data_tbl(in_if_data_cnt).end_date_active;
    t_forecast_interface_tab_inst(in_if_data_cnt).attribute5             :=
                                         in_if_data_tbl(in_if_data_cnt).base_code;
    t_forecast_interface_tab_inst(in_if_data_cnt).attribute6             :=
                                         in_if_data_tbl(in_if_data_cnt).case_quantity;
    t_forecast_interface_tab_inst(in_if_data_cnt).attribute4             :=
                                         in_if_data_tbl(in_if_data_cnt).quantity;
    t_forecast_interface_tab_inst(in_if_data_cnt).attribute2             := in_if_data_tbl(in_if_data_cnt).price;
    t_forecast_interface_tab_inst(in_if_data_cnt).bucket_type            := 1;
    t_forecast_interface_tab_inst(in_if_data_cnt).process_status         := 2;
    t_forecast_interface_tab_inst(in_if_data_cnt).confidence_percentage  := 100;
    t_forecast_interface_tab_inst(in_if_data_cnt).last_update_date       := gd_who_sysdate;
    t_forecast_interface_tab_inst(in_if_data_cnt).last_updated_by        := gn_last_updated_by;
    t_forecast_interface_tab_inst(in_if_data_cnt).creation_date          := gd_who_sysdate;
    t_forecast_interface_tab_inst(in_if_data_cnt).created_by             := gn_created_by;
    t_forecast_interface_tab_inst(in_if_data_cnt).last_update_login      := gn_login_user;
    t_forecast_interface_tab_inst(in_if_data_cnt).request_id             := gn_request_id;
    t_forecast_interface_tab_inst(in_if_data_cnt).program_application_id := gn_program_application_id;
    t_forecast_interface_tab_inst(in_if_data_cnt).program_id             := gn_program_id;
    t_forecast_interface_tab_inst(in_if_data_cnt).program_update_date    := gd_who_sysdate;
--
-- 2009/04/09 v1.20 T.Yoshimoto Add Start 本番#1350
    IF (ln_quantity < 0) THEN
      t_forecast_interface_tab_inst(in_if_data_cnt).quantity  := 0;    -- APIエラー回避の為、暫定値を設定
      -- マイナス値登録のためのデータセット
      ln_if_cnt := t_forecast_interface_tab_inst2.COUNT + 1;
      t_forecast_interface_tab_inst2(ln_if_cnt).forecast_designator    := gv_3f_forecast_designator;
      t_forecast_interface_tab_inst2(ln_if_cnt).organization_id        := gn_3f_organization_id;
      t_forecast_interface_tab_inst2(ln_if_cnt).inventory_item_id      := ln_inventory_item_id;
      t_forecast_interface_tab_inst2(ln_if_cnt).quantity               := ln_quantity;
      t_forecast_interface_tab_inst2(ln_if_cnt).forecast_date          := in_if_data_tbl(in_if_data_cnt).start_date_active;
      t_forecast_interface_tab_inst2(ln_if_cnt).attribute5             :=
                                           in_if_data_tbl(in_if_data_cnt).base_code;
    END IF;
-- 2009/04/09 v1.20 T.Yoshimoto Add End 本番#1350
--
    -- Forecastデータに抽出したインターフェースデータを登録
--    lb_retcode := MRP_FORECAST_INTERFACE_PK.MRP_FORECAST_INTERFACE(
--                                           t_forecast_interface_tab_ins,
--                                           t_forecast_designator_tab);
    -- エラーだった場合
--    IF ( t_forecast_interface_tab_ins(1).process_status <> 5 ) THEN
--      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_cmn  -- 'XXCMN'
--                                                    ,gv_msg_10a_045 -- APIエラー
--                                                    ,gv_tkn_api_name
--                                                    ,gv_cons_api) -- 予測API
--                                                    ,1
--                                                    ,5000);
--add start 1.9
--      FND_FILE.PUT_LINE(FND_FILE.LOG,t_forecast_interface_tab_ins(1).error_message);
--add end 1.9
--      RAISE global_api_expt;
--    END IF;
-- mod end 1.11
--
  EXCEPTION
    -- ケース入り数が取得できない場合の後処理
    WHEN VALUE_ERROR THEN                           --*** パラメータ例外 ***
      -- *** 任意で例外処理を記述する ****
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_inv   -- 'XXINV'
                                                    ,gv_msg_10a_059  -- ケース入り数取得エラー
                                                    ,gv_tkn_item    -- トークン'ITEM'
                                                                    -- 品目コード
                                                    ,in_if_data_tbl(in_if_data_cnt).item_code)
                                                    ,1
                                                    ,5000);
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;                                            --# 任意 #
    WHEN null_expt THEN                                --*** ケース入り数がNULL ***
      -- *** 任意で例外処理を記述する ****
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_inv   -- 'XXINV'
                                                    ,gv_msg_10a_059  -- ケース入り数取得エラー
                                                    ,gv_tkn_item    -- トークン'ITEM'
                                                                    -- 品目コード
                                                    ,in_if_data_tbl(in_if_data_cnt).item_code)
                                                    ,1
                                                    ,5000);
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;                                            --# 任意 #
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END  put_forecast_hanbai;
--
  /**********************************************************************************
   * Procedure Name   : put_forecast_keikaku
   * Description      : A-4-5 計画商品Forecast登録
   ***********************************************************************************/
  PROCEDURE  put_forecast_keikaku(
    in_if_data_tbl           IN  forecast_tbl,
    in_if_data_cnt           IN  NUMBER,          -- 処理中のIFデータカウンタ
    in_data_flg              IN  NUMBER,          -- 削除データ有り無しフラグ(0:なし, 1:あり)
    ov_errbuf                OUT NOCOPY VARCHAR2, -- エラー・メッセージ           --# 固定 #
    ov_retcode               OUT NOCOPY VARCHAR2, -- リターン・コード             --# 固定 #
    ov_errmsg                OUT NOCOPY VARCHAR2) -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'put_forecast_keikaku'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    ln_inventory_item_id        NUMBER;      -- 品目ID
    ln_number_of_case           NUMBER := 0;                     -- ケース入数(NUMBER)
    lv_number_of_case           ic_item_mst_vl.attribute11%TYPE; -- ケース入数(VARCHAR2)
    ln_quantity                 NUMBER;      -- 全数量
    lb_retcode                  BOOLEAN;
    ln_target_cnt               NUMBER := 0;
--add start 1.9
    ln_warning_count            NUMBER := 0;
--add end 1.9
--
    -- *** ローカル・カーソル ***
    CURSOR forecast_araigae_cur
    IS
    SELECT  mfd.transaction_id,          -- 取引ID
            mfd.forecast_designator,     -- Forecast名
            mfd.organization_id,         -- 在庫組織ID
            mfd.inventory_item_id,       -- 品目ID
            mfd.forecast_date,           -- 開始日付
-- mod start ver1.15
--            mfd.rate_end_date            -- 終了日付
            mfd.rate_end_date,             -- 終了日付
            im.item_no,                    -- 品目コード
            mfd.current_forecast_quantity, -- 数量
            mfd.attribute6,                -- 元ケース数量
            mfd.attribute4                 -- 元バラ数量
-- mod end ver1.15
    FROM    mrp_forecast_dates  mfd,   -- Forecast日付
            mrp_forecast_items  mfi,   -- Forecast品目
            ic_item_mst_vl        im,    -- OPM品目マスタ
            mtl_system_items_vl   si     -- 品目マスタ
    WHERE   mfd.organization_id        = mfi.organization_id                      -- 在庫組織ID
      AND   mfd.inventory_item_id      = mfi.inventory_item_id                    -- 品目ID
      AND   mfd.forecast_designator    = gv_3f_forecast_designator                -- Forecast名
      AND   mfd.organization_id        = si.organization_id                       -- 在庫組織ID
      AND   mfi.forecast_designator    = mfd.forecast_designator
      AND   si.organization_id         = mfd.organization_id
      AND   mfd.attribute5             = in_if_data_tbl(in_if_data_cnt).base_code -- 拠点
      AND   mfd.organization_id        = gn_3f_organization_id                    -- 在庫組織ID
      AND   im.item_no                 = in_if_data_tbl(in_if_data_cnt).item_code -- 品目コード
      AND   im.item_no                 = si.segment1                              -- 品目コード
      AND   si.inventory_item_id       = mfd.inventory_item_id                    -- 品目ID
      AND   ((gd_keikaku_start_date   >= mfd.forecast_date
              AND
              gd_keikaku_start_date   <= mfd.rate_end_date)
        OR   (gd_keikaku_end_date     >= mfd.forecast_date
              AND
              gd_keikaku_end_date     <= mfd.rate_end_date));
--
    -- *** ローカル・レコード ***
    lr_araigae_data                 araigae_tbl;
    t_forecast_interface_tab_del    MRP_FORECAST_INTERFACE_PK.t_forecast_interface;
    t_forecast_interface_tab_ins    MRP_FORECAST_INTERFACE_PK.t_forecast_interface;
    t_forecast_designator_tab       MRP_FORECAST_INTERFACE_PK.t_forecast_designator;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
/*
    -- 日付データがあった場合は開始日付・終了日付の比較および登録済みデータの削除をおこなう
    IF (in_data_flg = gn_cons_data_found) THEN
--
      OPEN forecast_araigae_cur;
--
      FETCH forecast_araigae_cur BULK COLLECT INTO lr_araigae_data;
--
      gn_araigae_cnt := lr_araigae_data.COUNT;
--
      CLOSE forecast_araigae_cur;
--
      <<araigae_data_loop>>
      FOR ln_target_cnt IN 1..gn_araigae_cnt LOOP
--
      -- 開始日付の比較
      IF (TRUNC(lr_araigae_data(ln_target_cnt).gd_4f_start_date_active) <>
        TRUNC(in_if_data_tbl(in_if_data_cnt).start_date_active))
      THEN
        -- メッセージセット
        lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_inv   -- 'XXINV'
                                                               -- フォーキャスト日付更新ワーニング
                                                      ,gv_msg_10a_021)
                                                      ,1
                                                      ,5000);
        -- 処理結果レポートに出力
        if_data_disp( in_if_data_tbl, in_if_data_cnt);
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      END IF;
--
      -- 終了日付の比較
      IF (TRUNC(lr_araigae_data(ln_target_cnt).gd_4f_end_date_active) <>
        TRUNC(in_if_data_tbl(in_if_data_cnt).end_date_active))
      THEN
        -- メッセージセット
        lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_inv   -- 'XXINV'
                                                               -- フォーキャスト日付更新ワーニング
                                                      ,gv_msg_10a_021)
                                                      ,1
                                                      ,5000);
        -- 処理結果レポートに出力
        if_data_disp( in_if_data_tbl, in_if_data_cnt);
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      END IF;
--
      -- 登録済みデータの削除のためのデータセット
      t_forecast_interface_tab_del(ln_target_cnt).transaction_id        :=
                             lr_araigae_data(ln_target_cnt).gv_4f_txns_id;            -- 取引ID
      t_forecast_interface_tab_del(ln_target_cnt).forecast_designator   :=
                             lr_araigae_data(ln_target_cnt).gv_4f_forecast_designator;-- Forecast名
      t_forecast_interface_tab_del(ln_target_cnt).organization_id       :=
                             lr_araigae_data(ln_target_cnt).gv_4f_organization_id;    -- 組織ID
      t_forecast_interface_tab_del(ln_target_cnt).inventory_item_id     :=
                             lr_araigae_data(ln_target_cnt).gv_4f_item_id;            -- 品目ID
      t_forecast_interface_tab_del(ln_target_cnt).quantity              := 0;                        -- 数量
      t_forecast_interface_tab_del(ln_target_cnt).forecast_date         :=
                             lr_araigae_data(ln_target_cnt).gd_4f_start_date_active;  -- 開始日付
      t_forecast_interface_tab_del(ln_target_cnt).forecast_end_date     :=
                             lr_araigae_data(ln_target_cnt).gd_4f_end_date_active;    -- 終了日付
      t_forecast_interface_tab_del(ln_target_cnt).bucket_type           := 1;
      t_forecast_interface_tab_del(ln_target_cnt).process_status        := 2;
      t_forecast_interface_tab_del(ln_target_cnt).confidence_percentage := 100;
      END LOOP araigae_data_loop;
--
      -- 登録済みデータの削除
      lb_retcode := MRP_FORECAST_INTERFACE_PK.MRP_FORECAST_INTERFACE(
                                            t_forecast_interface_tab_del,
                                            t_forecast_designator_tab);
      -- エラーだった場合
      IF ( t_forecast_interface_tab_del(ln_target_cnt).process_status <> 5 ) THEN
        lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_cmn  -- 'XXCMN'
                                                      ,gv_msg_10a_045 -- APIエラー
                                                    ,gv_tkn_api_name
                                                    ,gv_cons_api) -- 予測API
                                                      ,1
                                                      ,5000);
        RAISE global_api_expt;
      END IF;
    END IF;
*/
-- 2008/11/07 Y.Kawano Del Start
----add start 1.9
--    -- 開始日付の比較
--    IF (TRUNC(in_if_data_tbl(in_if_data_cnt).start_date_active) <> -- インタフェース開始日付
--      TRUNC(gd_keikaku_start_date))                                -- 計画商品対象開始日付
--    THEN
--      -- メッセージセット
--      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_inv  -- 'XXINV'
--                                                    ,gv_msg_10a_021) -- フォーキャスト日付更新ワーニング
--                                                    ,1
--                                                    ,5000);
--      -- 処理結果レポートに出力
--      if_data_disp( in_if_data_tbl, in_if_data_cnt);
--      ln_warning_count := ln_warning_count + 1;
----
--      -- 計画商品対象開始年月日取得を登録のためのデータセットにセット
---- mod start 1.11
----      t_forecast_interface_tab_ins(1).forecast_date := gd_keikaku_start_date;
----      t_forecast_interface_tab_inst(in_if_data_cnt).forecast_date := gd_keikaku_start_date;
----    ELSE
------      t_forecast_interface_tab_ins(1).forecast_date := 
----      t_forecast_interface_tab_ins(in_if_data_cnt).forecast_date := 
------ mod end 1.11
----                                      in_if_data_tbl(in_if_data_cnt).start_date_active;
--    END IF;
--    -- 終了日付の比較
--    IF (TRUNC(in_if_data_tbl(in_if_data_cnt).end_date_active) <> -- インタフェース終了日付
--      TRUNC(gd_keikaku_end_date))                                -- 計画商品終了日
--    THEN
--      -- メッセージセット
--      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_inv  -- 'XXINV'
--                                                    ,gv_msg_10a_021) -- フォーキャスト日付更新ワーニング
--                                                    ,1
--                                                    ,5000);
--      -- 処理結果レポートに出力
--      if_data_disp( in_if_data_tbl, in_if_data_cnt);
--      ln_warning_count := ln_warning_count + 1;
----
--      -- 計画商品対象終了年月日取得を登録のためのデータセットにセット
---- mod start 1.11
----      t_forecast_interface_tab_ins(1).forecast_end_date := gd_keikaku_end_date;
--      t_forecast_interface_tab_inst(in_if_data_cnt).forecast_end_date := gd_keikaku_end_date;
--    ELSE
----      t_forecast_interface_tab_ins(1).forecast_end_date := 
--      t_forecast_interface_tab_inst(in_if_data_cnt).forecast_end_date := 
---- mod end 1.11
--                                      in_if_data_tbl(in_if_data_cnt).end_date_active;
--    END IF;
----add end 1.9
-- 2008/11/07 Y.Kawano Add End
--
    -- 登録する数量を算出するために品目マスタからケース入数を抽出する
    -- 条件に主キーがあるためNO_DATA_FOUNDにはならない
    SELECT im.attribute11,             -- ケース入り数
           si.inventory_item_id
    INTO   lv_number_of_case,
           ln_inventory_item_id
    FROM   ic_item_mst_vl      im,     -- OPM品目マスタ
           mtl_system_items_vl si      -- 品目マスタ
    WHERE  im.item_no   = in_if_data_tbl(in_if_data_cnt).item_code
      AND  im.item_no   = si.segment1
      AND  ROWNUM       = 1;
--
    -- ケース数量が>0 の場合はケース入り数を変換する→変換エラーはエラーとする
    -- ケース数量が>0 の時だけケース入り数が必要となるので上記SQLでは一旦VARCHAR型
    -- で受け取っておき(TO_NUMBERしない)、ここで変換してNULLや文字であれば例外にて処理する
    IF (in_if_data_tbl(in_if_data_cnt).case_quantity > 0) THEN
      ln_number_of_case := TO_NUMBER(lv_number_of_case);
      -- NULLはVALUE_ERROR例外が発生しないためにここでRAISEする
      IF ( lv_number_of_case IS NULL ) THEN
        RAISE null_expt;
      END IF;
    END IF;
--
    -- 全数量を算出する(ケース数量*ケース入数+バラ数量)
    ln_quantity := in_if_data_tbl(in_if_data_cnt).case_quantity * ln_number_of_case
                   + in_if_data_tbl(in_if_data_cnt).quantity;
--
-- mod start 1.11
    -- 登録のためのデータセット
--    t_forecast_interface_tab_ins(1).forecast_designator   := gv_3f_forecast_designator;
--    t_forecast_interface_tab_ins(1).organization_id       := gn_3f_organization_id;
--    t_forecast_interface_tab_ins(1).inventory_item_id     := ln_inventory_item_id;
--    t_forecast_interface_tab_ins(1).quantity              := ln_quantity;
--del start 1.9
--    t_forecast_interface_tab_ins(1).forecast_date         :=
--                                         in_if_data_tbl(in_if_data_cnt).start_date_active;
--    t_forecast_interface_tab_ins(1).forecast_end_date     :=
--                                         in_if_data_tbl(in_if_data_cnt).end_date_active;
--del end 1.9
--    t_forecast_interface_tab_ins(1).attribute5            :=
--                                         in_if_data_tbl(in_if_data_cnt).base_code;
--    t_forecast_interface_tab_ins(1).attribute6            :=
--                                         in_if_data_tbl(in_if_data_cnt).case_quantity;
--    t_forecast_interface_tab_ins(1).attribute4            :=
--                                         in_if_data_tbl(in_if_data_cnt).quantity;
--    t_forecast_interface_tab_ins(1).attribute2            := in_if_data_tbl(in_if_data_cnt).price;
--    t_forecast_interface_tab_ins(1).bucket_type           := 1;
--    t_forecast_interface_tab_ins(1).process_status        := 2;
--    t_forecast_interface_tab_ins(1).confidence_percentage := 100;
--
-- 2008/08/01 Add ↓
--    t_forecast_interface_tab_ins(1).last_update_date       := gd_who_sysdate;
--    t_forecast_interface_tab_ins(1).last_updated_by        := gn_last_updated_by;
--    t_forecast_interface_tab_ins(1).creation_date          := gd_who_sysdate;
--    t_forecast_interface_tab_ins(1).created_by             := gn_created_by;
--    t_forecast_interface_tab_ins(1).last_update_login      := gn_login_user;
--    t_forecast_interface_tab_ins(1).request_id             := gn_request_id;
--    t_forecast_interface_tab_ins(1).program_application_id := gn_program_application_id;
--    t_forecast_interface_tab_ins(1).program_id             := gn_program_id;
--    t_forecast_interface_tab_ins(1).program_update_date    := gd_who_sysdate;
-- 2008/08/01 Add ↓
--
    -- 登録のためのデータセット
    t_forecast_interface_tab_inst(in_if_data_cnt).forecast_designator    := gv_3f_forecast_designator;
    t_forecast_interface_tab_inst(in_if_data_cnt).organization_id        := gn_3f_organization_id;
    t_forecast_interface_tab_inst(in_if_data_cnt).inventory_item_id      := ln_inventory_item_id;
    t_forecast_interface_tab_inst(in_if_data_cnt).quantity               := ln_quantity;
-- 2008/11/07 Y.Kawano Add Start
    t_forecast_interface_tab_inst(in_if_data_cnt).forecast_date          := gd_keikaku_start_date;
    t_forecast_interface_tab_inst(in_if_data_cnt).forecast_end_date      := gd_keikaku_end_date;
-- 2008/11/07 Y.Kawano Add End
    t_forecast_interface_tab_inst(in_if_data_cnt).attribute5             :=
                                         in_if_data_tbl(in_if_data_cnt).base_code;
    t_forecast_interface_tab_inst(in_if_data_cnt).attribute6             :=
                                         in_if_data_tbl(in_if_data_cnt).case_quantity;
    t_forecast_interface_tab_inst(in_if_data_cnt).attribute4             :=
                                         in_if_data_tbl(in_if_data_cnt).quantity;
    t_forecast_interface_tab_inst(in_if_data_cnt).attribute2             := in_if_data_tbl(in_if_data_cnt).price;
    t_forecast_interface_tab_inst(in_if_data_cnt).bucket_type            := 1;
    t_forecast_interface_tab_inst(in_if_data_cnt).process_status         := 2;
    t_forecast_interface_tab_inst(in_if_data_cnt).confidence_percentage  := 100;
    t_forecast_interface_tab_inst(in_if_data_cnt).last_update_date       := gd_who_sysdate;
    t_forecast_interface_tab_inst(in_if_data_cnt).last_updated_by        := gn_last_updated_by;
    t_forecast_interface_tab_inst(in_if_data_cnt).creation_date          := gd_who_sysdate;
    t_forecast_interface_tab_inst(in_if_data_cnt).created_by             := gn_created_by;
    t_forecast_interface_tab_inst(in_if_data_cnt).last_update_login      := gn_login_user;
    t_forecast_interface_tab_inst(in_if_data_cnt).request_id             := gn_request_id;
    t_forecast_interface_tab_inst(in_if_data_cnt).program_application_id := gn_program_application_id;
    t_forecast_interface_tab_inst(in_if_data_cnt).program_id             := gn_program_id;
    t_forecast_interface_tab_inst(in_if_data_cnt).program_update_date    := gd_who_sysdate;
--
    -- Forecastデータに抽出したインターフェースデータを登録
--    lb_retcode := MRP_FORECAST_INTERFACE_PK.MRP_FORECAST_INTERFACE(
--                                           t_forecast_interface_tab_ins,
--                                           t_forecast_designator_tab);
    -- エラーだった場合
--    IF ( t_forecast_interface_tab_ins(1).process_status <> 5 ) THEN
--      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_cmn  -- 'XXCMN'
--                                                    ,gv_msg_10a_045 -- APIエラー
--                                                    ,gv_tkn_api_name
--                                                    ,gv_cons_api) -- 予測API
--                                                    ,1
--                                                    ,5000);
--add start 1.9
--      FND_FILE.PUT_LINE(FND_FILE.LOG,t_forecast_interface_tab_ins(1).error_message);
--add end 1.9
--      RAISE global_api_expt;
--add start 1.9
--    ELSE
      -- 警告が発生した場合
--      IF (ln_warning_count > 0) THEN
--        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
--        ov_retcode := gv_status_warn;
--      END IF;
--add end 1.9
--    END IF;
-- mod end 1.11
--
  EXCEPTION
    -- ケース入り数が取得できない場合の後処理
    WHEN VALUE_ERROR THEN                           --*** パラメータ例外 ***
      -- *** 任意で例外処理を記述する ****
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_inv   -- 'XXINV'
                                                    ,gv_msg_10a_059  -- ケース入り数取得エラー
                                                    ,gv_tkn_item    -- トークン'ITEM'
                                                                    -- 品目コード
                                                    ,in_if_data_tbl(in_if_data_cnt).item_code)
                                                    ,1
                                                    ,5000);
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;                                            --# 任意 #
    WHEN null_expt THEN                                --*** ケース入り数がNULL ***
      -- *** 任意で例外処理を記述する ****
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_inv   -- 'XXINV'
                                                    ,gv_msg_10a_059  -- ケース入り数取得エラー
                                                    ,gv_tkn_item    -- トークン'ITEM'
                                                                    -- 品目コード
                                                    ,in_if_data_tbl(in_if_data_cnt).item_code)
                                                    ,1
                                                    ,5000);
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;                                            --# 任意 #
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END  put_forecast_keikaku;
--
  /**********************************************************************************
   * Procedure Name   : put_forecast_seigen_a
   * Description      : A-5-5 出荷数制限AForecast登録
   ***********************************************************************************/
  PROCEDURE  put_forecast_seigen_a(
    in_if_data_tbl           IN  forecast_tbl,
    in_if_data_cnt           IN  NUMBER,          -- 処理中のIFデータカウンタ
    in_data_flg              IN  NUMBER,          -- 削除データ有り無しフラグ(0:なし, 1:あり)
    ov_errbuf                OUT NOCOPY VARCHAR2, -- エラー・メッセージ           --# 固定 #
    ov_retcode               OUT NOCOPY VARCHAR2, -- リターン・コード             --# 固定 #
    ov_errmsg                OUT NOCOPY VARCHAR2) -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'put_forecast_seigen_a'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    ln_inventory_item_id        NUMBER;      -- 品目ID
    ln_number_of_case           NUMBER := 0;                     -- ケース入数(NUMBER)
    lv_number_of_case           ic_item_mst_vl.attribute11%TYPE; -- ケース入数(VARCHAR2)
    ln_quantity                 NUMBER := 0;      -- 全数量
    lb_retcode                  BOOLEAN;
    ln_target_cnt               NUMBER := 0;
--
    -- *** ローカル・カーソル ***
    CURSOR forecast_araigae_cur
    IS
    SELECT  mfd.transaction_id,          -- 取引ID
            mfd.forecast_designator,     -- Forecast名
            mfd.organization_id,         -- 在庫組織ID
            mfd.inventory_item_id,       -- 品目ID
            mfd.forecast_date,           -- 開始日付
-- mod start ver1.15
--            mfd.rate_end_date            -- 終了日付
            mfd.rate_end_date,             -- 終了日付
            im.item_no,                    -- 品目コード
            mfd.current_forecast_quantity, -- 数量
            mfd.attribute6,                -- 元ケース数量
            mfd.attribute4                 -- 元バラ数量
-- mod end ver1.15
    FROM    mrp_forecast_dates  mfd,   -- Forecast日付
            mrp_forecast_items  mfi,   -- Forecast品目
            ic_item_mst_vl        im,    -- OPM品目マスタ
            mtl_system_items_vl   si     -- 品目マスタ
    WHERE   mfd.organization_id        = mfi.organization_id       -- 在庫組織ID
      AND   mfd.inventory_item_id      = mfi.inventory_item_id     -- 品目ID
      AND   mfd.forecast_designator    = gv_3f_forecast_designator -- Forecast名
      AND   mfd.organization_id        = gn_3f_organization_id     -- 在庫組織ID
      AND   mfi.forecast_designator    = mfd.forecast_designator
      AND   si.organization_id         = mfd.organization_id
      AND   im.item_no                 = in_if_data_tbl(in_if_data_cnt).item_code -- 品目コード
      AND   im.item_no                 = si.segment1               -- 品目コード
      AND   si.inventory_item_id       = mfd.inventory_item_id     -- 品目ID
      AND   ((gd_in_start_date         >= mfd.forecast_date
              AND
              gd_in_start_date         <= mfd.rate_end_date)
        OR   (gd_in_end_date           >= mfd.forecast_date
              AND
              gd_in_end_date           <= mfd.rate_end_date));
--
    -- *** ローカル・レコード ***
    lr_araigae_data                 araigae_tbl;
    t_forecast_interface_tab_del    MRP_FORECAST_INTERFACE_PK.t_forecast_interface;
    t_forecast_interface_tab_ins    MRP_FORECAST_INTERFACE_PK.t_forecast_interface;
    t_forecast_designator_tab       MRP_FORECAST_INTERFACE_PK.t_forecast_designator;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
/*
    -- 日付データがあった場合は開始日付・終了日付の比較および登録済みデータの削除をおこなう
    IF (in_data_flg = gn_cons_data_found) THEN
--
      OPEN forecast_araigae_cur;
--
      FETCH forecast_araigae_cur BULK COLLECT INTO lr_araigae_data;
--
      gn_araigae_cnt := lr_araigae_data.COUNT;
--
      CLOSE forecast_araigae_cur;
--
      <<araigae_data_loop>>
      FOR ln_target_cnt IN 1..gn_araigae_cnt LOOP

      -- 開始日付の比較
      IF (TRUNC(lr_araigae_data(ln_target_cnt).gd_4f_start_date_active) <>
        TRUNC(in_if_data_tbl(in_if_data_cnt).start_date_active))
      THEN
        -- メッセージセット
        lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_inv   -- 'XXINV'
                                                               -- フォーキャスト日付更新ワーニング
                                                      ,gv_msg_10a_021)
                                                      ,1
                                                      ,5000);
        -- 処理結果レポートに出力
        if_data_disp( in_if_data_tbl, in_if_data_cnt);
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      END IF;
--
      -- 終了日付の比較
      IF (TRUNC(lr_araigae_data(ln_target_cnt).gd_4f_end_date_active) <>
        TRUNC(in_if_data_tbl(in_if_data_cnt).end_date_active))
      THEN
        -- メッセージセット
        lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_inv   -- 'XXINV'
                                                               -- フォーキャスト日付更新ワーニング
                                                      ,gv_msg_10a_021)
                                                      ,1
                                                      ,5000);
        -- 処理結果レポートに出力
        if_data_disp( in_if_data_tbl, in_if_data_cnt);
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      END IF;
--
      -- 登録済みデータの削除のためのデータセット
      t_forecast_interface_tab_del(ln_target_cnt).transaction_id
                         := lr_araigae_data(ln_target_cnt).gv_4f_txns_id;            -- 取引ID
      t_forecast_interface_tab_del(ln_target_cnt).forecast_designator
                         := lr_araigae_data(ln_target_cnt).gv_4f_forecast_designator;-- Forecast名
      t_forecast_interface_tab_del(ln_target_cnt).organization_id
                         := lr_araigae_data(ln_target_cnt).gv_4f_organization_id;    -- 組織ID
      t_forecast_interface_tab_del(ln_target_cnt).inventory_item_id
                         := lr_araigae_data(ln_target_cnt).gv_4f_item_id;            -- 品目ID
      t_forecast_interface_tab_del(ln_target_cnt).quantity              := 0;        -- 数量
      t_forecast_interface_tab_del(ln_target_cnt).forecast_date
                         := lr_araigae_data(ln_target_cnt).gd_4f_start_date_active;  -- 開始日付
      t_forecast_interface_tab_del(ln_target_cnt).forecast_end_date
                         := lr_araigae_data(ln_target_cnt).gd_4f_end_date_active;    -- 終了日付
      t_forecast_interface_tab_del(ln_target_cnt).bucket_type           := 1;
      t_forecast_interface_tab_del(ln_target_cnt).process_status        := 2;
      t_forecast_interface_tab_del(ln_target_cnt).confidence_percentage := 100;
      END LOOP araigae_data_loop;
--
      -- 登録済みデータの削除
      lb_retcode := MRP_FORECAST_INTERFACE_PK.MRP_FORECAST_INTERFACE(
                                            t_forecast_interface_tab_del,
                                            t_forecast_designator_tab);
      -- エラーだった場合
      IF ( t_forecast_interface_tab_del(ln_target_cnt).process_status <> 5 ) THEN
        lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_cmn  -- 'XXCMN'
                                                      ,gv_msg_10a_045 -- APIエラー
                                                    ,gv_tkn_api_name
                                                    ,gv_cons_api) -- 予測API
                                                      ,1
                                                      ,5000);
        RAISE global_api_expt;
      END IF;
    END IF;
*/
--
    -- 登録する数量を算出するために品目マスタからケース入数を抽出する
    -- 条件に主キーがあるためNO_DATA_FOUNDにはならない
    SELECT im.attribute11,             -- ケース入り数
           si.inventory_item_id
    INTO   lv_number_of_case,
           ln_inventory_item_id
    FROM   ic_item_mst_vl      im,     -- OPM品目マスタ
           mtl_system_items_vl si      -- 品目マスタ
    WHERE  im.item_no   = in_if_data_tbl(in_if_data_cnt).item_code
      AND  im.item_no   = si.segment1
      AND  ROWNUM       = 1;
--
    -- ケース数量が>0 の場合はケース入り数を変換する→変換エラーはエラーとする
    -- ケース数量が>0 の時だけケース入り数が必要となるので上記SQLでは一旦VARCHAR型
    -- で受け取っておき(TO_NUMBERしない)、ここで変換してNULLや文字であれば例外にて処理する
    IF (in_if_data_tbl(in_if_data_cnt).case_quantity > 0) THEN
      ln_number_of_case := TO_NUMBER(lv_number_of_case);
      -- NULLはVALUE_ERROR例外が発生しないためにここでRAISEする
      IF ( lv_number_of_case IS NULL ) THEN
        RAISE null_expt;
      END IF;
    END IF;
--
    -- 全数量を算出する(ケース数量*ケース入数+バラ数量)
    ln_quantity := in_if_data_tbl(in_if_data_cnt).case_quantity * ln_number_of_case
                   + in_if_data_tbl(in_if_data_cnt).quantity;
--
-- mod start 1.11
    -- 登録のためのデータセット
--    t_forecast_interface_tab_ins(1).forecast_designator   := gv_3f_forecast_designator;
--    t_forecast_interface_tab_ins(1).organization_id       := gn_3f_organization_id;
--    t_forecast_interface_tab_ins(1).inventory_item_id     := ln_inventory_item_id;
--    t_forecast_interface_tab_ins(1).quantity              := ln_quantity;
--    t_forecast_interface_tab_ins(1).forecast_date         :=
--                                          in_if_data_tbl(in_if_data_cnt).start_date_active;
--    t_forecast_interface_tab_ins(1).forecast_end_date     :=
--                                          in_if_data_tbl(in_if_data_cnt).end_date_active;
--    t_forecast_interface_tab_ins(1).attribute5         := in_if_data_tbl(in_if_data_cnt).base_code;
--    t_forecast_interface_tab_ins(1).attribute6            :=
--                                          in_if_data_tbl(in_if_data_cnt).case_quantity;
--    t_forecast_interface_tab_ins(1).attribute4         := in_if_data_tbl(in_if_data_cnt).quantity;
--    t_forecast_interface_tab_ins(1).attribute2            := in_if_data_tbl(in_if_data_cnt).price;
--    t_forecast_interface_tab_ins(1).bucket_type           := 1;
--    t_forecast_interface_tab_ins(1).process_status        := 2;
--    t_forecast_interface_tab_ins(1).confidence_percentage := 100;
--
-- 2008/08/01 Add ↓
--    t_forecast_interface_tab_ins(1).last_update_date       := gd_who_sysdate;
--    t_forecast_interface_tab_ins(1).last_updated_by        := gn_last_updated_by;
--    t_forecast_interface_tab_ins(1).creation_date          := gd_who_sysdate;
--    t_forecast_interface_tab_ins(1).created_by             := gn_created_by;
--    t_forecast_interface_tab_ins(1).last_update_login      := gn_login_user;
--    t_forecast_interface_tab_ins(1).request_id             := gn_request_id;
--    t_forecast_interface_tab_ins(1).program_application_id := gn_program_application_id;
--    t_forecast_interface_tab_ins(1).program_id             := gn_program_id;
--    t_forecast_interface_tab_ins(1).program_update_date    := gd_who_sysdate;
-- 2008/08/01 Add ↓
    -- 登録のためのデータセット
    t_forecast_interface_tab_inst(in_if_data_cnt).forecast_designator   := gv_3f_forecast_designator;
    t_forecast_interface_tab_inst(in_if_data_cnt).organization_id       := gn_3f_organization_id;
    t_forecast_interface_tab_inst(in_if_data_cnt).inventory_item_id     := ln_inventory_item_id;
    t_forecast_interface_tab_inst(in_if_data_cnt).quantity              := ln_quantity;
    t_forecast_interface_tab_inst(in_if_data_cnt).forecast_date         :=
                                          in_if_data_tbl(in_if_data_cnt).start_date_active;
    t_forecast_interface_tab_inst(in_if_data_cnt).forecast_end_date     :=
                                          in_if_data_tbl(in_if_data_cnt).end_date_active;
    t_forecast_interface_tab_inst(in_if_data_cnt).attribute5         := in_if_data_tbl(in_if_data_cnt).base_code;
    t_forecast_interface_tab_inst(in_if_data_cnt).attribute6            :=
                                          in_if_data_tbl(in_if_data_cnt).case_quantity;
    t_forecast_interface_tab_inst(in_if_data_cnt).attribute4         := in_if_data_tbl(in_if_data_cnt).quantity;
    t_forecast_interface_tab_inst(in_if_data_cnt).attribute2            := in_if_data_tbl(in_if_data_cnt).price;
    t_forecast_interface_tab_inst(in_if_data_cnt).bucket_type           := 1;
    t_forecast_interface_tab_inst(in_if_data_cnt).process_status        := 2;
    t_forecast_interface_tab_inst(in_if_data_cnt).confidence_percentage := 100;
    t_forecast_interface_tab_inst(in_if_data_cnt).last_update_date       := gd_who_sysdate;
    t_forecast_interface_tab_inst(in_if_data_cnt).last_updated_by        := gn_last_updated_by;
    t_forecast_interface_tab_inst(in_if_data_cnt).creation_date          := gd_who_sysdate;
    t_forecast_interface_tab_inst(in_if_data_cnt).created_by             := gn_created_by;
    t_forecast_interface_tab_inst(in_if_data_cnt).last_update_login      := gn_login_user;
    t_forecast_interface_tab_inst(in_if_data_cnt).request_id             := gn_request_id;
    t_forecast_interface_tab_inst(in_if_data_cnt).program_application_id := gn_program_application_id;
    t_forecast_interface_tab_inst(in_if_data_cnt).program_id             := gn_program_id;
    t_forecast_interface_tab_inst(in_if_data_cnt).program_update_date    := gd_who_sysdate;
--
    -- Forecastデータに抽出したインターフェースデータを登録
--    lb_retcode := MRP_FORECAST_INTERFACE_PK.MRP_FORECAST_INTERFACE(
--                                           t_forecast_interface_tab_ins,
--                                           t_forecast_designator_tab);
    -- エラーだった場合
--    IF ( t_forecast_interface_tab_ins(1).process_status <> 5 ) THEN
--      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_cmn  -- 'XXCMN'
--                                                    ,gv_msg_10a_045 -- APIエラー
--                                                    ,gv_tkn_api_name
--                                                    ,gv_cons_api) -- 予測API
--                                                    ,1
--                                                    ,5000);
--add start 1.9
--      FND_FILE.PUT_LINE(FND_FILE.LOG,t_forecast_interface_tab_ins(1).error_message);
--add end 1.9
--      RAISE global_api_expt;
--    END IF;
-- mod end 1.11
--
  EXCEPTION
    -- ケース入り数が取得できない場合の後処理
    WHEN VALUE_ERROR THEN                           --*** パラメータ例外 ***
      -- *** 任意で例外処理を記述する ****
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_inv   -- 'XXINV'
                                                    ,gv_msg_10a_059  -- ケース入り数取得エラー
                                                    ,gv_tkn_item    -- トークン'ITEM'
                                                                    -- 品目コード
                                                    ,in_if_data_tbl(in_if_data_cnt).item_code)
                                                    ,1
                                                    ,5000);
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;                                            --# 任意 #
    WHEN null_expt THEN                                --*** ケース入り数がNULL ***
      -- *** 任意で例外処理を記述する ****
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_inv   -- 'XXINV'
                                                    ,gv_msg_10a_059  -- ケース入り数取得エラー
                                                    ,gv_tkn_item    -- トークン'ITEM'
                                                                    -- 品目コード
                                                    ,in_if_data_tbl(in_if_data_cnt).item_code)
                                                    ,1
                                                    ,5000);
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;                                            --# 任意 #
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END  put_forecast_seigen_a;
--
  /**********************************************************************************
   * Procedure Name   : put_forecast_seigen_b
   * Description      : A-6-5 出荷数制限BForecast登録
   ***********************************************************************************/
  PROCEDURE  put_forecast_seigen_b(
    in_if_data_tbl           IN  forecast_tbl,
    in_if_data_cnt           IN  NUMBER,          -- 処理中のIFデータカウンタ
    in_data_flg              IN  NUMBER,          -- 削除データ有り無しフラグ(0:なし, 1:あり)
    ov_errbuf                OUT NOCOPY VARCHAR2, -- エラー・メッセージ           --# 固定 #
    ov_retcode               OUT NOCOPY VARCHAR2, -- リターン・コード             --# 固定 #
    ov_errmsg                OUT NOCOPY VARCHAR2) -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'put_forecast_seigen_b'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    ln_inventory_item_id        NUMBER;      -- 品目ID
    ln_number_of_case           NUMBER := 0;                     -- ケース入数(NUMBER)
    lv_number_of_case           ic_item_mst_vl.attribute11%TYPE; -- ケース入数(VARCHAR2)
    ln_quantity                 NUMBER;      -- 全数量
    lb_retcode                  BOOLEAN;
    ln_target_cnt               NUMBER := 0;
--
    -- *** ローカル・カーソル ***
    CURSOR forecast_araigae_cur
    IS
    SELECT  mfd.transaction_id,          -- 取引ID
            mfd.forecast_designator,     -- Forecast名
            mfd.organization_id,         -- 在庫組織ID
            mfd.inventory_item_id,       -- 品目ID
            mfd.forecast_date,           -- 開始日付
-- mod start ver1.15
--            mfd.rate_end_date            -- 終了日付
            mfd.rate_end_date,             -- 終了日付
            im.item_no,                    -- 品目コード
            mfd.current_forecast_quantity, -- 数量
            mfd.attribute6,                -- 元ケース数量
            mfd.attribute4                 -- 元バラ数量
-- mod end ver1.15
    FROM    mrp_forecast_dates  mfd,   -- Forecast日付
            mrp_forecast_items  mfi,   -- Forecast品目
            ic_item_mst_vl        im,    -- OPM品目マスタ
            mtl_system_items_vl   si     -- 品目マスタ
    WHERE   mfd.organization_id        = mfi.organization_id       -- 在庫組織ID
      AND   mfd.inventory_item_id      = mfi.inventory_item_id     -- 品目ID
      AND   mfd.forecast_designator    = gv_3f_forecast_designator -- Forecast名
      AND   mfd.organization_id        = gn_3f_organization_id     -- 在庫組織ID
      AND   mfi.forecast_designator    = mfd.forecast_designator
      AND   si.organization_id         = mfd.organization_id
      AND   im.item_no                 = in_if_data_tbl(in_if_data_cnt).item_code -- 品目コード
      AND   im.item_no                 = si.segment1               -- 品目コード
      AND   si.inventory_item_id       = mfd.inventory_item_id     -- 品目ID
      AND   ((gd_in_start_date         >= mfd.forecast_date
              AND
              gd_in_start_date         <= mfd.rate_end_date)
        OR   (gd_in_end_date           >= mfd.forecast_date
              AND
              gd_in_end_date           <= mfd.rate_end_date));
--
    -- *** ローカル・レコード ***
    lr_araigae_data                 araigae_tbl;
    t_forecast_interface_tab_del    MRP_FORECAST_INTERFACE_PK.t_forecast_interface;
    t_forecast_interface_tab_ins    MRP_FORECAST_INTERFACE_PK.t_forecast_interface;
    t_forecast_designator_tab       MRP_FORECAST_INTERFACE_PK.t_forecast_designator;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
/*
    -- 日付データがあった場合は開始日付・終了日付の比較および登録済みデータの削除をおこなう
    IF (in_data_flg = gn_cons_data_found) THEN
--
      OPEN forecast_araigae_cur;
--
      FETCH forecast_araigae_cur BULK COLLECT INTO lr_araigae_data;
--
      gn_araigae_cnt := lr_araigae_data.COUNT;
--
      CLOSE forecast_araigae_cur;
--
      <<araigae_data_loop>>
      FOR ln_target_cnt IN 1..gn_araigae_cnt LOOP

      -- 開始日付の比較
      IF (TRUNC(lr_araigae_data(ln_target_cnt).gd_4f_start_date_active) <>
        TRUNC(in_if_data_tbl(in_if_data_cnt).start_date_active))
      THEN
        -- メッセージセット
        lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_inv   -- 'XXINV'
                                                               -- フォーキャスト日付更新ワーニング
                                                      ,gv_msg_10a_021)
                                                      ,1
                                                      ,5000);
        -- 処理結果レポートに出力
        if_data_disp( in_if_data_tbl, in_if_data_cnt);
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      END IF;
--
      -- 終了日付の比較
      IF (TRUNC(lr_araigae_data(ln_target_cnt).gd_4f_end_date_active) <>
        TRUNC(in_if_data_tbl(in_if_data_cnt).end_date_active))
      THEN
        -- メッセージセット
        lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_inv   -- 'XXINV'
                                                               -- フォーキャスト日付更新ワーニング
                                                      ,gv_msg_10a_021)
                                                      ,1
                                                      ,5000);
        -- 処理結果レポートに出力
        if_data_disp( in_if_data_tbl, in_if_data_cnt);
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      END IF;
--
      -- 登録済みデータの削除のためのデータセット
      t_forecast_interface_tab_del(ln_target_cnt).transaction_id
                         := lr_araigae_data(ln_target_cnt).gv_4f_txns_id;            -- 取引ID
      t_forecast_interface_tab_del(ln_target_cnt).forecast_designator
                         := lr_araigae_data(ln_target_cnt).gv_4f_forecast_designator;-- Forecast名
      t_forecast_interface_tab_del(ln_target_cnt).organization_id
                         := lr_araigae_data(ln_target_cnt).gv_4f_organization_id;    -- 組織ID
      t_forecast_interface_tab_del(ln_target_cnt).inventory_item_id
                         := lr_araigae_data(ln_target_cnt).gv_4f_item_id;            -- 品目ID
      t_forecast_interface_tab_del(ln_target_cnt).quantity              := 0;        -- 数量
      t_forecast_interface_tab_del(ln_target_cnt).forecast_date
                         := lr_araigae_data(ln_target_cnt).gd_4f_start_date_active;  -- 開始日付
      t_forecast_interface_tab_del(ln_target_cnt).forecast_end_date
                         := lr_araigae_data(ln_target_cnt).gd_4f_end_date_active;    -- 終了日付
      t_forecast_interface_tab_del(ln_target_cnt).bucket_type           := 1;
      t_forecast_interface_tab_del(ln_target_cnt).process_status        := 2;
      t_forecast_interface_tab_del(ln_target_cnt).confidence_percentage := 100;
      END LOOP araigae_data_loop;
--
      -- 登録済みデータの削除
      lb_retcode := MRP_FORECAST_INTERFACE_PK.MRP_FORECAST_INTERFACE(
                                            t_forecast_interface_tab_del,
                                            t_forecast_designator_tab);
      -- エラーだった場合
      IF ( t_forecast_interface_tab_del(ln_target_cnt).process_status <> 5 ) THEN
        lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_cmn   -- 'XXCMN'
                                                      ,gv_msg_10a_045  -- APIエラー
                                                    ,gv_tkn_api_name
                                                    ,gv_cons_api) -- 予測API
                                                      ,1
                                                      ,5000);
        RAISE global_api_expt;
      END IF;
    END IF;
*/
--
    -- 登録する数量を算出するために品目マスタからケース入数を抽出する
    -- 条件に主キーがあるためNO_DATA_FOUNDにはならない
    SELECT im.attribute11,             -- ケース入り数
           si.inventory_item_id
    INTO   lv_number_of_case,
           ln_inventory_item_id
    FROM   ic_item_mst_vl      im,     -- OPM品目マスタ
           mtl_system_items_vl si      -- 品目マスタ
    WHERE  im.item_no   = in_if_data_tbl(in_if_data_cnt).item_code
      AND  im.item_no   = si.segment1
      AND  ROWNUM       = 1;
--
    -- ケース数量が>0 の場合はケース入り数を変換する→変換エラーはエラーとする
    -- ケース数量が>0 の時だけケース入り数が必要となるので上記SQLでは一旦VARCHAR型
    -- で受け取っておき(TO_NUMBERしない)、ここで変換してNULLや文字であれば例外にて処理する
    IF (in_if_data_tbl(in_if_data_cnt).case_quantity > 0) THEN
      ln_number_of_case := TO_NUMBER(lv_number_of_case);
      -- NULLはVALUE_ERROR例外が発生しないためにここでRAISEする
      IF ( lv_number_of_case IS NULL ) THEN
        RAISE null_expt;
      END IF;
    END IF;
--
    -- 全数量を算出する(ケース数量*ケース入数+バラ数量)
    ln_quantity := in_if_data_tbl(in_if_data_cnt).case_quantity * ln_number_of_case
                   + in_if_data_tbl(in_if_data_cnt).quantity;
--
-- mod start 1.11
    -- 登録のためのデータセット
--    t_forecast_interface_tab_ins(1).forecast_designator   := gv_3f_forecast_designator;
--    t_forecast_interface_tab_ins(1).organization_id       := gn_3f_organization_id;
--    t_forecast_interface_tab_ins(1).inventory_item_id     := ln_inventory_item_id;
--    t_forecast_interface_tab_ins(1).quantity              := ln_quantity;
--    t_forecast_interface_tab_ins(1).forecast_date         :=
--                                          in_if_data_tbl(in_if_data_cnt).start_date_active;
--    t_forecast_interface_tab_ins(1).forecast_end_date     :=
--                                          in_if_data_tbl(in_if_data_cnt).end_date_active;
--    t_forecast_interface_tab_ins(1).attribute5            :=
--                                          in_if_data_tbl(in_if_data_cnt).base_code;
--    t_forecast_interface_tab_ins(1).attribute6            :=
--                                          in_if_data_tbl(in_if_data_cnt).case_quantity;
--    t_forecast_interface_tab_ins(1).attribute4            :=
--                                          in_if_data_tbl(in_if_data_cnt).quantity;
--    t_forecast_interface_tab_ins(1).attribute2            := in_if_data_tbl(in_if_data_cnt).price;
--    t_forecast_interface_tab_ins(1).bucket_type           := 1;
--    t_forecast_interface_tab_ins(1).process_status        := 2;
--    t_forecast_interface_tab_ins(1).confidence_percentage := 100;
--
-- 2008/08/01 Add ↓
--    t_forecast_interface_tab_ins(1).last_update_date       := gd_who_sysdate;
--    t_forecast_interface_tab_ins(1).last_updated_by        := gn_last_updated_by;
--    t_forecast_interface_tab_ins(1).creation_date          := gd_who_sysdate;
--    t_forecast_interface_tab_ins(1).created_by             := gn_created_by;
--    t_forecast_interface_tab_ins(1).last_update_login      := gn_login_user;
--    t_forecast_interface_tab_ins(1).request_id             := gn_request_id;
--    t_forecast_interface_tab_ins(1).program_application_id := gn_program_application_id;
--    t_forecast_interface_tab_ins(1).program_id             := gn_program_id;
--    t_forecast_interface_tab_ins(1).program_update_date    := gd_who_sysdate;
-- 2008/08/01 Add ↓

    -- 登録のためのデータセット
    t_forecast_interface_tab_inst(in_if_data_cnt).forecast_designator   := gv_3f_forecast_designator;
    t_forecast_interface_tab_inst(in_if_data_cnt).organization_id       := gn_3f_organization_id;
    t_forecast_interface_tab_inst(in_if_data_cnt).inventory_item_id     := ln_inventory_item_id;
    t_forecast_interface_tab_inst(in_if_data_cnt).quantity              := ln_quantity;
    t_forecast_interface_tab_inst(in_if_data_cnt).forecast_date         :=
                                          in_if_data_tbl(in_if_data_cnt).start_date_active;
    t_forecast_interface_tab_inst(in_if_data_cnt).forecast_end_date     :=
                                          in_if_data_tbl(in_if_data_cnt).end_date_active;
    t_forecast_interface_tab_inst(in_if_data_cnt).attribute5            :=
                                          in_if_data_tbl(in_if_data_cnt).base_code;
    t_forecast_interface_tab_inst(in_if_data_cnt).attribute6            :=
                                          in_if_data_tbl(in_if_data_cnt).case_quantity;
    t_forecast_interface_tab_inst(in_if_data_cnt).attribute4            :=
                                          in_if_data_tbl(in_if_data_cnt).quantity;
    t_forecast_interface_tab_inst(in_if_data_cnt).attribute2            := in_if_data_tbl(in_if_data_cnt).price;
    t_forecast_interface_tab_inst(in_if_data_cnt).bucket_type           := 1;
    t_forecast_interface_tab_inst(in_if_data_cnt).process_status        := 2;
    t_forecast_interface_tab_inst(in_if_data_cnt).confidence_percentage := 100;
    t_forecast_interface_tab_inst(in_if_data_cnt).last_update_date       := gd_who_sysdate;
    t_forecast_interface_tab_inst(in_if_data_cnt).last_updated_by        := gn_last_updated_by;
    t_forecast_interface_tab_inst(in_if_data_cnt).creation_date          := gd_who_sysdate;
    t_forecast_interface_tab_inst(in_if_data_cnt).created_by             := gn_created_by;
    t_forecast_interface_tab_inst(in_if_data_cnt).last_update_login      := gn_login_user;
    t_forecast_interface_tab_inst(in_if_data_cnt).request_id             := gn_request_id;
    t_forecast_interface_tab_inst(in_if_data_cnt).program_application_id := gn_program_application_id;
    t_forecast_interface_tab_inst(in_if_data_cnt).program_id             := gn_program_id;
    t_forecast_interface_tab_inst(in_if_data_cnt).program_update_date    := gd_who_sysdate;
--
    -- Forecastデータに抽出したインターフェースデータを登録
--    lb_retcode := MRP_FORECAST_INTERFACE_PK.MRP_FORECAST_INTERFACE(
--                                           t_forecast_interface_tab_ins,
--                                           t_forecast_designator_tab);
    -- エラーだった場合
--    IF ( t_forecast_interface_tab_ins(1).process_status <> 5 ) THEN
--      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_cmn  -- 'XXCMN'
--                                                    ,gv_msg_10a_045 -- APIエラー
--                                                    ,gv_tkn_api_name
--                                                    ,gv_cons_api) -- 予測API
--                                                    ,1
--                                                    ,5000);
--add start 1.9
--      FND_FILE.PUT_LINE(FND_FILE.LOG,t_forecast_interface_tab_ins(1).error_message);
--add end 1.9
--      RAISE global_api_expt;
--    END IF;
-- mod end 1.11
--
  EXCEPTION
    -- ケース入り数が取得できない場合の後処理
    WHEN VALUE_ERROR THEN                           --*** パラメータ例外 ***
      -- *** 任意で例外処理を記述する ****
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_inv   -- 'XXINV'
                                                    ,gv_msg_10a_059  -- ケース入り数取得エラー
                                                    ,gv_tkn_item    -- トークン'ITEM'
                                                                    -- 品目コード
                                                    ,in_if_data_tbl(in_if_data_cnt).item_code)
                                                    ,1
                                                    ,5000);
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;                                            --# 任意 #
    WHEN null_expt THEN                                --*** ケース入り数がNULL ***
      -- *** 任意で例外処理を記述する ****
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_inv   -- 'XXINV'
                                                    ,gv_msg_10a_059  -- ケース入り数取得エラー
                                                    ,gv_tkn_item    -- トークン'ITEM'
                                                                    -- 品目コード
                                                    ,in_if_data_tbl(in_if_data_cnt).item_code)
                                                    ,1
                                                    ,5000);
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;                                            --# 任意 #
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END  put_forecast_seigen_b;
--
  /**********************************************************************************
   * Procedure Name   : del_if_data
   * Description      : A-X-6 販売計画/引取計画インターフェースデータ削除
   *                    (A-2-6, A-3-6, A-4-6, A-5-6, A-6-6 共通処理)
   ***********************************************************************************/
  PROCEDURE del_if_data(
    in_if_data_tbl        IN  forecast_tbl,
    ov_errbuf             OUT NOCOPY VARCHAR2,  -- エラー・メッセージ           --# 固定 #
    ov_retcode            OUT NOCOPY VARCHAR2,  -- リターン・コード             --# 固定 #
    ov_errmsg             OUT NOCOPY VARCHAR2)  -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'del_if_data'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    lb_retcd    BOOLEAN;   -- リターンコード
    ln_loop_cnt NUMBER;    -- ループカウンタ
--
    -- *** ローカル・カーソル ***
--
    TYPE txns_type IS TABLE OF 
         xxinv_mrp_forecast_interface.forecast_if_id%TYPE INDEX BY PLS_INTEGER;
    t_txns_type txns_type;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    ln_loop_cnt := 0;
    -- FORALLでデータを削除するために削除専用取引IDテーブルにデータをセットする
    <<table_copy_loop>>
    FOR ln_loop_cnt IN 1..gn_target_cnt LOOP
      t_txns_type(ln_loop_cnt) := in_if_data_tbl(ln_loop_cnt).txns_id;
    END LOOP table_copy_loop;
--
    -- 販売計画/引取計画インタ－フェーステーブルから対象データ削除
    ln_loop_cnt := 0;
    FORALL ln_loop_cnt IN 1..gn_target_cnt
      DELETE /*+ INDEX( xxinv_mrp_forecast_interface XXINV_MFI_PK ) */       -- 2008/11/11 統合指摘#589 Add
      FROM xxinv_mrp_forecast_interface
      WHERE  forecast_if_id = t_txns_type(ln_loop_cnt);
--
-- 2009/05/19 ADD START
    -- 出荷数制限A、Bの場合は入力パラメータに関連するごみデータの削除を行う
    IF gv_forecast_type IN( gv_cons_fc_type_seigen_a,gv_cons_fc_type_seigen_b ) THEN
      DELETE
      FROM  xxinv_mrp_forecast_interface  mfi
      WHERE mfi.forecast_designator = gv_forecast_type                    -- 出荷数制限AとB
      AND   mfi.forecast_date       = gd_in_start_date                    -- 入力パラメータ開始日付
      AND   mfi.item_code           = NVL(gv_in_item_code,mfi.item_code)  -- 入力パラメータ品目
      AND   mfi.created_by          = gn_created_by;                      -- ログインユーザ
    END IF;
-- 2009/05/19 ADD END
--add start 1.4
      COMMIT;
--add end 1.4
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END del_if_data;
--
/**********************************************************************************
   * Procedure Name   : forecast_hikitori
   * Description      : 引取計画(A-2)
   ***********************************************************************************/
  PROCEDURE forecast_hikitori(
    ov_errbuf                OUT NOCOPY VARCHAR2,  -- エラー・メッセージ           --# 固定 #
    ov_retcode               OUT NOCOPY VARCHAR2,  -- リターン・コード             --# 固定 #
    ov_errmsg                OUT NOCOPY VARCHAR2)  -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'forecast_hikitori'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
    lv_errbuf_d  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode_d VARCHAR2(1);     -- リターン・コード
    lv_errmsg_d  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    ln_data_cnt   NUMBER;    -- 抽出インターフェースデータの処理カウンタ
    ln_data_cnt2   NUMBER;    -- 抽出インターフェースデータの処理カウンタ
    ln_data_flg   NUMBER;    -- 日付データありなしフラグ(0:なし、1:あり)
    ln_error_flg  NUMBER;    -- インタ－フェースデータエラーありフラグ(0:なし, 1:あり)
    lb_retcode                  BOOLEAN;
--add start 1.11
    ln_warn_flg   NUMBER := 0; -- インタ－フェースデータ警告ありフラグ(0:なし, 1:あり)
--add end 1.11
--
    -- *** ローカル・カーソル ***
    -- あらいがえ対象データの抽出
    CURSOR forecast_araigae_cur
    IS
    SELECT  mfd.transaction_id,          -- 取引ID
            mfd.forecast_designator,     -- Forecast名
            mfd.organization_id,         -- 在庫組織ID
            mfd.inventory_item_id,       -- 品目ID
            mfd.forecast_date,           -- 開始日付
-- add start ver1.15
--            mfd.rate_end_date            -- 終了日付
            mfd.rate_end_date,             -- 終了日付
            NULL,                          -- 品目コード
            mfd.current_forecast_quantity, -- 数量
            mfd.attribute6,                -- 元ケース数量
            mfd.attribute4                 -- 元バラ数量
-- add end ver1.15
    FROM    mrp_forecast_dates  mfd,   -- Forecast日付
            mrp_forecast_items  mfi    -- Forecast品目
    WHERE   mfd.forecast_designator      = gv_3f_forecast_designator   -- Forecast名
      AND   mfd.organization_id          = gn_3f_organization_id       -- 在庫組織
-- mod start 1.11
--      AND   TO_CHAR(mfd.forecast_date,'YYYYMM') = gv_in_yyyymm  -- 入力年月
      AND   TO_CHAR(mfd.forecast_date,'YYYYMM') = TO_CHAR(TO_DATE(gv_in_yyyymm,'YYYYMM'),'YYYYMM')  -- 入力年月
-- mod strart 1.11
      AND   mfd.organization_id          = mfi.organization_id
--mod start kumamoto
      AND mfd.FORECAST_DESIGNATOR = mfi.FORECAST_DESIGNATOR
--mod end kumamoto
      AND   mfd.inventory_item_id        = mfi.inventory_item_id;
--
    -- *** ローカル・レコード ***
    lr_araigae_data     araigae_tbl;
--
    -- *** ローカル・レコード ***
    lt_if_data    forecast_tbl;
    t_forecast_interface_tab_del    MRP_FORECAST_INTERFACE_PK.t_forecast_interface;
    t_forecast_interface_tab_ins    MRP_FORECAST_INTERFACE_PK.t_forecast_interface;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- A-*-0 IFデータ項目必須チェック
    if_data_null_check( gv_cons_fc_type_hikitori,      -- Forecast分類('引取計画')
                        lv_errbuf,
                        lv_retcode,
                        lv_errmsg );
    -- エラーがあったら処理中止
    IF (lv_retcode = gv_status_error) THEN
      gn_error_cnt := gn_error_cnt + 1;
      RAISE global_api_expt;
    END IF;
--
    -- A-2-1 引取計画インタ－フェースデータ抽出
    get_hikitori_if_data( lt_if_data,
                          lv_errbuf,
                          lv_retcode,
                          lv_errmsg );
--
    -- エラーがあったら処理中止
    IF (lv_retcode = gv_status_error) THEN
      gn_error_cnt := gn_error_cnt + 1;
      RAISE global_api_expt;
    ELSIF (lv_retcode = gv_status_warn) THEN
--del start 1.5
--      gn_warn_cnt := gn_warn_cnt + 1;
--del end 1.5
      RAISE warn_expt;
    END IF;
--
    -- インタ－フェースデータエラーありフラグ初期化
    ln_error_flg :=0;
--
    -- 抽出データチェックループ
    <<if_data_check_loop>>
    FOR ln_data_cnt IN 1..gn_target_cnt LOOP
--
      -- 抽出したデータをチェックする
      --   引取計画抽出データチェック
      hikitori_data_check( lt_if_data,
                           ln_data_cnt,
                           lv_errbuf,
                           lv_retcode,
                           lv_errmsg );
      -- エラーがあった場合は、インタ－フェースデータエラーありフラグONにしつつ、
      -- いったん全データを処理(チェック)して、最後にエラーがあれば処理を中止する。
      -- 警告ならば処理は続行する。
      IF (lv_retcode = gv_status_error) THEN
        ln_error_flg := 1;
--add start 1.11
      ELSIF (lv_retcode = gv_status_warn) THEN
        ln_warn_flg := 1;
--add end 1.11
      END IF;
--
    END LOOP if_data_check_loop;
--
    -- A-2-2 引取計画抽出データチェックでエラーがあった場合は「Forecast処理データループ」
    -- は処理しないでスキップする。
    IF (ln_error_flg = 0) THEN
--
    <<araigae_loop>>
    FOR ln_data_cnt IN 1..gn_target_cnt LOOP
-- 2009/02/17 本番障害#38 DEL Start --
--        -- A-2-3 引取計画Forecast名抽出
--        get_f_degi_hikitori( lt_if_data,
--                             ln_data_cnt,
--                             lv_errbuf,
--                             lv_retcode,
--                             lv_errmsg );
--        -- エラーがあったらループ処理中止
--        IF (lv_retcode = gv_status_error) THEN
---- mod start 1.11
--          FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
---- mod end 1.11
--          gn_error_cnt := gn_error_cnt + 1;
--          ln_error_flg := 1;
--          EXIT;
--        END IF;
--
-- 2009/02/17 本番障害#38 DEL End    --
      OPEN forecast_araigae_cur;
--
      FETCH forecast_araigae_cur BULK COLLECT INTO lr_araigae_data;
--
      gn_araigae_cnt := lr_araigae_data.COUNT;
--
      CLOSE forecast_araigae_cur;
--
      <<del_loop>>
      FOR ln_data_cnt2 IN 1..gn_araigae_cnt LOOP
        -- 削除用変数にセット
-- mod start 1.11
        gn_del_data_cnt := gn_del_data_cnt + 1;
--
--        t_forecast_interface_tab_del(1).transaction_id
--                          := lr_araigae_data(ln_data_cnt2).gv_4f_txns_id;            -- 取引ID
--        t_forecast_interface_tab_del(1).forecast_designator
--                          := lr_araigae_data(ln_data_cnt2).gv_4f_forecast_designator;                    -- Forecast名
--        t_forecast_interface_tab_del(1).organization_id
--                          := lr_araigae_data(ln_data_cnt2).gv_4f_organization_id;                        -- 組織ID
--        t_forecast_interface_tab_del(1).inventory_item_id
--                          := lr_araigae_data(ln_data_cnt2).gv_4f_item_id;           -- 品目ID
--        t_forecast_interface_tab_del(1).quantity              := 0;       -- 数量
--        t_forecast_interface_tab_del(1).forecast_date
--                          := lr_araigae_data(ln_data_cnt2).gd_4f_start_date_active;  -- 開始日付
--        t_forecast_interface_tab_del(1).forecast_end_date
--                          := lr_araigae_data(ln_data_cnt2).gd_4f_end_date_active;    -- 終了日付
--        t_forecast_interface_tab_del(1).bucket_type           := 1;
--        t_forecast_interface_tab_del(1).process_status        := 2;
--        t_forecast_interface_tab_del(1).confidence_percentage := 100;
--
        t_forecast_interface_tab_del(gn_del_data_cnt).transaction_id
                          := lr_araigae_data(ln_data_cnt2).gv_4f_txns_id;            -- 取引ID
        t_forecast_interface_tab_del(gn_del_data_cnt).forecast_designator
                          := lr_araigae_data(ln_data_cnt2).gv_4f_forecast_designator;                    -- Forecast名
        t_forecast_interface_tab_del(gn_del_data_cnt).organization_id
                          := lr_araigae_data(ln_data_cnt2).gv_4f_organization_id;                        -- 組織ID
        t_forecast_interface_tab_del(gn_del_data_cnt).inventory_item_id
                          := lr_araigae_data(ln_data_cnt2).gv_4f_item_id;           -- 品目ID
        t_forecast_interface_tab_del(gn_del_data_cnt).quantity              := 0;       -- 数量
        t_forecast_interface_tab_del(gn_del_data_cnt).forecast_date
                          := lr_araigae_data(ln_data_cnt2).gd_4f_start_date_active;  -- 開始日付
        t_forecast_interface_tab_del(gn_del_data_cnt).forecast_end_date
                          := lr_araigae_data(ln_data_cnt2).gd_4f_end_date_active;    -- 終了日付
        t_forecast_interface_tab_del(gn_del_data_cnt).bucket_type           := 1;
        t_forecast_interface_tab_del(gn_del_data_cnt).process_status        := 2;
        t_forecast_interface_tab_del(gn_del_data_cnt).confidence_percentage := 100;
--
        -- Forecast日付データのクリア
--        lb_retcode := MRP_FORECAST_INTERFACE_PK.MRP_FORECAST_INTERFACE(
--                                              t_forecast_interface_tab_del);
        -- エラーだった場合
--        IF (lb_retcode = FALSE )THEN
--          lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_cmn   -- 'XXCMN'
--                                                        ,gv_msg_10a_045  -- APIエラー
--                                                    ,gv_tkn_api_name
--                                                    ,gv_cons_api) -- 予測API
--                                                        ,1
--                                                        ,5000);
--          RAISE global_api_expt;
--        END IF;
     END LOOP del_loop;
-- add start ver1.15
     -- Forecast日付データのクリア
     -- あらいがえ対象データの処理カウンタが1000件を超えた場合
     IF (gn_del_data_cnt >= 1000) THEN
--
       lb_retcode := MRP_FORECAST_INTERFACE_PK.MRP_FORECAST_INTERFACE(
                                             t_forecast_interface_tab_del);
       -- エラーだった場合
       IF (lb_retcode = FALSE )THEN
         ln_error_flg := 1;
       END IF;
       -- あらいがえ対象データの処理カウンタの初期化
       gn_del_data_cnt := 0;
       t_forecast_interface_tab_del.delete;
     -- 抽出インターフェースデータループが終了する場合
-- mod start ver1.16
--     ELSIF (ln_data_cnt = gn_araigae_cnt) THEN
     ELSIF (ln_data_cnt = gn_target_cnt) THEN
-- mod end ver1.16
--
       lb_retcode := MRP_FORECAST_INTERFACE_PK.MRP_FORECAST_INTERFACE(
                                             t_forecast_interface_tab_del);
       IF (lb_retcode = FALSE )THEN
         ln_error_flg := 1;
       END IF;
     END IF;
-- add end ver1.15
    END LOOP araigae_loop;
-- del start ver1.15
    -- Forecast日付データのクリア
--    lb_retcode := MRP_FORECAST_INTERFACE_PK.MRP_FORECAST_INTERFACE(
--                                          t_forecast_interface_tab_del);
-- del end ver1.15
--
-- mod start 1.12
--    <<del_serch_error_loop>>
--    FOR ln_data_cnt IN 1..gn_del_data_cnt LOOP
--      -- エラーだった場合
--      IF ( t_forecast_interface_tab_del(ln_data_cnt).process_status <> 5 ) THEN
--        lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_cmn   -- 'XXCMN'
--                                                      ,gv_msg_10a_045  -- APIエラー
--                                                      ,gv_tkn_api_name
--                                                      ,gv_cons_api) -- 予測API
--                                                      ,1
--                                                      ,5000);
--        FND_FILE.PUT_LINE(FND_FILE.LOG,t_forecast_interface_tab_del(ln_data_cnt).error_message);
--        gn_error_cnt := gn_error_cnt + 1;
--        ln_error_flg := 1;
--        EXIT;
--      END IF;
--    END LOOP del_serch_error_loop;
-- mod start ver1.15
    -- エラーだった場合
--    IF (lb_retcode = FALSE )THEN
    IF (ln_error_flg = 1 )THEN
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_cmn  -- 'XXCMN'
                                                    ,gv_msg_10a_045  -- APIエラー
                                                    ,gv_tkn_api_name
                                                    ,gv_cons_api)    -- 予測API
                                                    ,1
                                                    ,5000);
      gn_error_cnt := gn_error_cnt + 1;
--      ln_error_flg := 1;
    END IF;
-- mod end ver1.15
-- mod end 1.12
    -- あらいがえ対象データの処理カウンタの初期化
    gn_del_data_cnt := 0;
-- mod end 1.11
--
      -- Forecast処理データループ
/*
      <<forecast_del_set_loop>>
      FOR ln_data_cnt IN 1..gn_araigae_cnt LOOP
--
FND_FILE.PUT_LINE(FND_FILE.LOG,'forecast_del_set_loop...');
--
        -- A-2-3 引取計画Forecast名抽出
        get_f_degi_hikitori( lt_if_data,
                             ln_data_cnt,
                             lv_errbuf,
                             lv_retcode,
                             lv_errmsg );
        -- エラーがあったらループ処理中止
        IF (lv_retcode = gv_status_error) THEN
          gn_error_cnt := gn_error_cnt + 1;
          ln_error_flg := 1;
          EXIT;
        END IF;
        -- 削除用変数にセット
        t_forecast_interface_tab_del(1).transaction_id
                          := lr_araigae_data(ln_data_cnt).gv_4f_txns_id;            -- 取引ID
        t_forecast_interface_tab_del(1).forecast_designator
                          := lr_araigae_data(ln_data_cnt).gv_4f_forecast_designator;                    -- Forecast名
        t_forecast_interface_tab_del(1).organization_id
                          := lr_araigae_data(ln_data_cnt).gv_4f_organization_id;                        -- 組織ID
        t_forecast_interface_tab_del(1).inventory_item_id
                          := lr_araigae_data(ln_data_cnt).gv_4f_item_id;           -- 品目ID
        t_forecast_interface_tab_del(1).quantity              := 0;       -- 数量
        t_forecast_interface_tab_del(1).forecast_date
                          := lr_araigae_data(ln_data_cnt).gd_4f_start_date_active;  -- 開始日付
        t_forecast_interface_tab_del(1).forecast_end_date
                          := lr_araigae_data(ln_data_cnt).gd_4f_end_date_active;    -- 終了日付
        t_forecast_interface_tab_del(1).bucket_type           := 1;
        t_forecast_interface_tab_del(1).process_status        := 2;
        t_forecast_interface_tab_del(1).confidence_percentage := 100;
--
        -- Forecast日付データのクリア
        lb_retcode := MRP_FORECAST_INTERFACE_PK.MRP_FORECAST_INTERFACE(
                                              t_forecast_interface_tab_del);
        -- エラーだった場合
        IF (lb_retcode = FALSE )THEN
          lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_cmn   -- 'XXCMN'
                                                        ,gv_msg_10a_045)  -- APIエラー
                                                        ,1
                                                        ,5000);
          RAISE global_api_expt;
        END IF;
      END LOOP forecast_del_set_loop;
*/
/*
        -- A-2-4 引取計画Forecast日付抽出
        get_f_dates_hikitori( ln_data_flg,
                              lv_errbuf,
                              lv_retcode,
                              lv_errmsg );
        -- エラーがあったらループ処理中止
        IF (lv_retcode = gv_status_error) THEN
          gn_error_cnt := gn_error_cnt + 1;
          ln_error_flg := 1;
          EXIT;
        END IF;
*/
-- add start 1.11
      IF (ln_error_flg = 0) THEN
-- add end 1.11
        <<forecast_ins_loop>>
        FOR ln_data_cnt IN 1..gn_target_cnt LOOP
          -- A-2-3 引取計画Forecast名抽出
          get_f_degi_hikitori( lt_if_data,
                               ln_data_cnt,
                               lv_errbuf,
                               lv_retcode,
                               lv_errmsg );
          -- エラーがあったらループ処理中止
          IF (lv_retcode = gv_status_error) THEN
-- add start 1.11
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
-- add end 1.11
            gn_error_cnt := gn_error_cnt + 1;
            ln_error_flg := 1;
            EXIT;
          END IF;
          -- A-2-5 引取計画Forecast登録
          put_forecast_hikitori( lt_if_data,
                                 ln_data_cnt,
                                 ln_data_flg,
                                 lv_errbuf,
                                 lv_retcode,
                                 lv_errmsg );
          -- エラーがあったらループ処理中止
          IF (lv_retcode = gv_status_error) THEN
-- add start 1.11
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
-- add end 1.11
            gn_error_cnt := gn_error_cnt + 1;
            ln_error_flg := 1;
            EXIT;
          END IF;
--
        END LOOP forecast_ins_loop;
-- add start 1.11
      END IF;
-- add end 1.11
--
-- add start 1.11
      IF (ln_error_flg = 0) THEN
        -- Forecastデータに抽出したインターフェースデータを登録
        lb_retcode := MRP_FORECAST_INTERFACE_PK.MRP_FORECAST_INTERFACE(
                                               t_forecast_interface_tab_inst,
                                               t_forecast_designator_tabl);
--
        <<serch_error_loop>>
        FOR ln_data_cnt IN 1..gn_target_cnt LOOP
          -- エラーだった場合
          IF ( t_forecast_interface_tab_inst(ln_data_cnt).process_status <> 5 ) THEN
            lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_cmn    -- 'XXCMN'
                                                          ,gv_msg_10a_045
                                                          ,gv_tkn_api_name
                                                          ,gv_cons_api) -- 予測API
                                                         ,1
                                                         ,5000);
            FND_FILE.PUT_LINE(FND_FILE.LOG,t_forecast_interface_tab_inst(ln_data_cnt).error_message);
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
            gn_error_cnt := gn_error_cnt + 1;
            ln_error_flg := 1;
            EXIT;
          END IF;
        END LOOP serch_error_loop;
      END IF;
--
      -- 登録対象データのレコードの初期化
      t_forecast_interface_tab_inst.delete;
      t_forecast_designator_tabl.delete;
-- add end 1.11
    END IF;
    -- エラーがなかった場合はコミットする
    IF (ln_error_flg = 0) THEN
      COMMIT;
    ELSE
      ROLLBACK;
    END IF;
--
    -- A-X-6共通 インターフェーステーブル削除処理
    del_if_data( lt_if_data,
                 lv_errbuf_d,
                 lv_retcode_d,
                 lv_errmsg_d );
    -- エラーがあったら処理中止
    IF (lv_retcode_d = gv_status_error) THEN
      gn_error_cnt := gn_error_cnt + 1;
      lv_errbuf    := lv_errbuf_d;
      lv_retcode   := lv_retcode_d;
      lv_errmsg    :=lv_errmsg_d;
      RAISE global_api_expt;
    END IF;
--
    -- 各処理でエラーが発生していたらエラーリターンするために例外を発生させる
    IF (ln_error_flg = 1) THEN
      RAISE global_api_expt;
--add start 1.11
    ELSIF (ln_warn_flg = 1) THEN
      RAISE warn_expt;
--add end 1.11
    END IF;
--
  EXCEPTION
    WHEN warn_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_warn;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
      gn_error_cnt := gn_error_cnt + 1;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
      gn_error_cnt := gn_error_cnt + 1;
--
--#####################################  固定部 END   ##########################################
--
  END forecast_hikitori;
--
  /**********************************************************************************
   * Procedure Name   : forecast_hanbai
   * Description      : 販売計画(A-3)
   ***********************************************************************************/
  PROCEDURE forecast_hanbai(
    ov_errbuf                OUT NOCOPY VARCHAR2,  -- エラー・メッセージ            --# 固定 #
    ov_retcode               OUT NOCOPY VARCHAR2,  -- リターン・コード              --# 固定 #
    ov_errmsg                OUT NOCOPY VARCHAR2)  -- ユーザー・エラー・メッセージ  --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'forecast_hanbai'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
    lv_errbuf_d  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode_d VARCHAR2(1);     -- リターン・コード
    lv_errmsg_d  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル変数 ***
    ln_data_cnt   NUMBER;    -- 抽出インターフェースデータの処理カウンタ
    ln_data_flg   NUMBER;    -- 日付データありなしフラグ(0:なし、1:あり)
    ln_error_flg  NUMBER;    -- インタ－フェースデータエラーありフラグ(0:なし, 1:あり)
-- add start 1.11
    lb_retcode    BOOLEAN;
-- add end 1.11
--
-- 2008/08/01 Add ↓
    lv_errbuf_w  VARCHAR2(5000);  -- エラー・メッセージ
    lv_errmsg_w  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
    ln_warm_flg  NUMBER;
-- 2008/08/01 Add ↑
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
    lt_if_data    forecast_tbl;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- A-*-0 IFデータ項目必須チェック
    if_data_null_check( gv_cons_fc_type_hanbai,      -- Forecast分類('販売計画')
                        lv_errbuf,
                        lv_retcode,
                        lv_errmsg );
--
    -- エラーがあったら処理中止
    IF (lv_retcode = gv_status_error) THEN
      gn_error_cnt := gn_error_cnt + 1;
      RAISE global_api_expt;
    END IF;
--
    -- A-3-1 販売計画インタ－フェースデータ抽出
    get_hanbai_if_data( lt_if_data,
                        lv_errbuf,
                        lv_retcode,
                        lv_errmsg );
--
    -- データが取得できなければエラー
    IF (lv_retcode = gv_status_error) THEN
      gn_error_cnt := gn_error_cnt + 1;
      RAISE global_api_expt;
    ELSIF (lv_retcode = gv_status_warn) THEN
--del start 1.5
--      gn_warn_cnt := gn_warn_cnt + 1;
--del end 1.5
      RAISE warn_expt;
    END IF;
--
    -- インタ－フェースデータエラーありフラグ初期化
    ln_error_flg :=0;
--
-- 2008/08/01 Add ↓
    ln_warm_flg  := 0;
-- 2008/08/01 Add ↑
--
    -- 抽出データチェックループ
    <<if_data_check_loop>>
    FOR ln_data_cnt IN 1..gn_target_cnt LOOP
--
      -- 抽出したデータをチェックする
      -- A-3-2 販売計画抽出データチェック
       hanbai_data_check( lt_if_data,
                          ln_data_cnt,
                          lv_errbuf,
                          lv_retcode,
                          lv_errmsg );
--
      -- エラーがあった場合は、インタ－フェースデータエラーありフラグONにしつつ、
      -- いったん全データを処理(チェック)して、最後にエラーがあれば処理を中止する。
      -- 警告ならば処理は続行する。
      IF (lv_retcode = gv_status_error) THEN
        ln_error_flg := 1;
-- 2008/08/01 Add ↓
      ELSIF (lv_retcode = gv_status_warn) THEN
        lv_errbuf_w := lv_errbuf;
        lv_errmsg_w := lv_errmsg;
        ln_warm_flg := 1;
-- 2008/08/01 Add ↑
      END IF;
--add start 1.7
    END LOOP if_data_check_loop;
--add end 1.7
--
    IF (ln_error_flg = 0) THEN
      -- A-3-3 販売計画Forecast名抽出
      get_f_degi_hanbai( lt_if_data,
                         ln_data_cnt,
                         lv_errbuf,
                         lv_retcode,
                         lv_errmsg );
--
      -- エラーがあったらA-X-6まで処理をとばす
      IF (lv_retcode = gv_status_error) THEN
        gn_error_cnt := gn_error_cnt + 1;
        ln_error_flg := 1;
      END IF;
    END IF;
--add start 1.7
    IF (ln_error_flg = 0) THEN
--add end 1.7
      -- A-3-4 販売計画Forecast日付抽出
      get_f_dates_hanbai( ln_data_flg,
                          lv_errbuf,
                          lv_retcode,
                          lv_errmsg );
--
    -- エラーがあったらA-X-6まで処理をとばす
      IF (lv_retcode = gv_status_error) THEN
        gn_error_cnt := gn_error_cnt + 1;
        ln_error_flg := 1;
      END IF;
--
--add start 1.7
    END IF;
--add end 1.7
--del start 1.7
--    END LOOP if_data_check_loop;
--del end 1.7
--
    -- A-3-2 販売計画抽出データチェックでエラーがあった場合は「Forecast処理データループ」
    -- は処理しないでスキップする。
/*
    IF (ln_error_flg = 0) THEN
      -- A-3-3 販売計画Forecast名抽出
FND_FILE.PUT_LINE(FND_FILE.LOG,'(A-3)-A-3-3 call....');
      get_f_degi_hanbai( lt_if_data,
                         ln_data_cnt,
                         lv_errbuf,
                         lv_retcode,
                         lv_errmsg );
      -- エラーがあったらA-X-6まで処理をとばす
      IF (lv_retcode = gv_status_error) THEN
        gn_error_cnt := gn_error_cnt + 1;
        ln_error_flg := 1;
FND_FILE.PUT_LINE(FND_FILE.LOG,'(A-3)-A-3-3 error....');
      END IF;
    END IF;
*/
--
    --  A-3-3 が正常終了だったら
--    IF (ln_error_flg = 0) THEN
--    END IF;
--
    -- A-3-4 が正常終了だったら
    -- Forecast処理データループ
    IF (ln_error_flg = 0) THEN
      <<forecast_proc_loop>>
      FOR ln_data_cnt IN 1..gn_target_cnt LOOP
--
        -- A-3-5 販売計画Forecast登録
        put_forecast_hanbai( lt_if_data,
                             ln_data_cnt,
                             ln_data_flg,
                             lv_errbuf,
                             lv_retcode,
                             lv_errmsg );
--
        -- エラーがあったらループ処理中止
        IF (lv_retcode = gv_status_error) THEN
-- mod start 1.11
          FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
-- mod end 1.11
          gn_error_cnt := gn_error_cnt + 1;
          ln_error_flg := 1;
          EXIT;
        END IF;
--
      -- １度目で日付データは削除できているので、２回目からはデータなしとして起動
--      ln_data_flg := gn_cons_no_data_found;
      END LOOP forecast_proc_loop;
    END IF;
--
-- add start 1.11
    IF (ln_error_flg = 0) THEN
      -- Forecastデータに抽出したインターフェースデータを登録
      lb_retcode := MRP_FORECAST_INTERFACE_PK.MRP_FORECAST_INTERFACE(
                                             t_forecast_interface_tab_inst,
                                             t_forecast_designator_tabl);
--
      <<serch_error_loop>>
      FOR ln_data_cnt IN 1..gn_target_cnt LOOP
        -- エラーだった場合
        IF ( t_forecast_interface_tab_inst(ln_data_cnt).process_status <> 5 ) THEN
          lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_cmn  -- 'XXCMN'
                                                        ,gv_msg_10a_045
                                                        ,gv_tkn_api_name
                                                        ,gv_cons_api)    -- 予測API
                                                       ,1
                                                       ,5000);
          FND_FILE.PUT_LINE(FND_FILE.LOG,t_forecast_interface_tab_inst(ln_data_cnt).error_message);
          FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
          gn_error_cnt := gn_error_cnt + 1;
          ln_error_flg := 1;
          EXIT;
        END IF;
      END LOOP serch_error_loop;
    END IF;
--
-- 2009/04/09 v1.20 T.Yoshimoto Add Start 本番#1350
    -- エラーが無い場合
    IF ( ( ln_error_flg = 0 )
      AND ( t_forecast_interface_tab_inst2.COUNT > 0 ) ) THEN
--
      -- 数量更新処理(マイナス値のみ)
      FOR ln_data_cnt IN 1..t_forecast_interface_tab_inst2.COUNT LOOP
        UPDATE mrp_forecast_dates       mfd
        SET mfd.original_forecast_quantity = t_forecast_interface_tab_inst2(ln_data_cnt).quantity
           ,mfd.current_forecast_quantity  = t_forecast_interface_tab_inst2(ln_data_cnt).quantity
        WHERE mfd.forecast_designator = t_forecast_interface_tab_inst2(ln_data_cnt).forecast_designator
        AND   mfd.inventory_item_id   = t_forecast_interface_tab_inst2(ln_data_cnt).inventory_item_id
        AND   mfd.organization_id     = t_forecast_interface_tab_inst2(ln_data_cnt).organization_id
        AND   mfd.attribute5          = t_forecast_interface_tab_inst2(ln_data_cnt).attribute5
        AND   mfd.forecast_date       = t_forecast_interface_tab_inst2(ln_data_cnt).forecast_date
        ;
      END LOOP;
--
      -- 登録対象データのレコードの初期化
      t_forecast_interface_tab_inst2.delete;
--
    END IF;
-- 2009/04/09 v1.20 T.Yoshimoto Add End 本番#1350
--
    -- 登録対象データのレコードの初期化
    t_forecast_interface_tab_inst.delete;
    t_forecast_designator_tabl.delete;
-- add end 1.11
    -- エラーがなかった場合はコミットする
    IF (ln_error_flg = 0) THEN
      COMMIT;
    ELSE
      ROLLBACK;
    END IF;
--
    -- A-X-6共通 インターフェーステーブル削除処理
    del_if_data( lt_if_data,
                 lv_errbuf_d,
                 lv_retcode_d,
                 lv_errmsg_d );
--
    -- エラーがあったら処理中止
    IF (lv_retcode_d = gv_status_error) THEN
      gn_error_cnt := gn_error_cnt + 1;
      lv_errbuf    := lv_errbuf_d;
      lv_retcode   := lv_retcode_d;
      lv_errmsg    :=lv_errmsg_d;
      RAISE global_api_expt;
    END IF;
--
    -- A-3-2 販売計画抽出データチェックでエラーだったらエラーリターンするために
    -- 例外を発生させる
    IF (ln_error_flg = 1) THEN
      RAISE global_api_expt;
    END IF;
--
-- 2008/08/01 Add ↓
    IF (ln_warm_flg = 1) THEN
      lv_errbuf := lv_errbuf_w;
      lv_errmsg := lv_errmsg_w;
      RAISE warn_expt;
    END IF;
-- 2008/08/01 Add ↑
--
  EXCEPTION
    WHEN warn_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_warn;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
      gn_error_cnt := gn_error_cnt + 1;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
      gn_error_cnt := gn_error_cnt + 1;
--
--#####################################  固定部 END   ##########################################
--
  END forecast_hanbai;
--
  /**********************************************************************************
   * Procedure Name   : forecast_keikaku
   * Description      : 計画商品(A-4)
   ***********************************************************************************/
  PROCEDURE forecast_keikaku(
    ov_errbuf                OUT NOCOPY VARCHAR2,  -- エラー・メッセージ            --# 固定 #
    ov_retcode               OUT NOCOPY VARCHAR2,  -- リターン・コード              --# 固定 #
    ov_errmsg                OUT NOCOPY VARCHAR2)  -- ユーザー・エラー・メッセージ  --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'forecast_keikaku'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
    lv_errbuf_d  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode_d VARCHAR2(1);     -- リターン・コード
    lv_errmsg_d  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル変数 ***
    ln_data_cnt   NUMBER;    -- 抽出インターフェースデータの処理カウンタ
    ln_data_flg   NUMBER;    -- 日付データありなしフラグ(0:なし、1:あり)
    ln_error_flg  NUMBER;    -- インタ－フェースデータエラーありフラグ(0:なし, 1:あり)
    ln_data_cnt2   NUMBER;    -- 抽出インターフェースデータの処理カウンタ
    lb_retcode                  BOOLEAN;
--add start 1.9
    ln_warn_flg   NUMBER := 0; -- インタ－フェースデータ警告ありフラグ(0:なし, 1:あり)
--add end 1.9
-- add start ver1.15
    lv_err        VARCHAR2(5000);
-- add end ver1.15
--
    -- *** ローカル・レコード ***
    lr_araigae_data                 araigae_tbl;

    t_forecast_interface_tab_ins    MRP_FORECAST_INTERFACE_PK.t_forecast_interface;
-- mod start ver1.18
    t_forecast_interface_tab_del    MRP_FORECAST_INTERFACE_PK.t_forecast_designator;
-- mod end ver1.18
    t_forecast_designator_tab       MRP_FORECAST_INTERFACE_PK.t_forecast_designator;
--
    -- *** ローカル・レコード ***
    lt_if_data    forecast_tbl;
--
    -- *** ローカル・カーソル ***
    CURSOR forecast_araigae_cur(pv_base_code in varchar2, pv_item_code in varchar2)
    IS
    SELECT  mfd.transaction_id,          -- 取引ID
            mfd.forecast_designator,     -- Forecast名
            mfd.organization_id,         -- 在庫組織ID
            mfd.inventory_item_id,       -- 品目ID
            mfd.forecast_date,           -- 開始日付
-- mod start ver1.15
--            mfd.rate_end_date            -- 終了日付
            mfd.rate_end_date,             -- 終了日付
            im.item_no,                    -- 品目コード
            mfd.current_forecast_quantity, -- 数量
            mfd.attribute6,                -- 元ケース数量
            mfd.attribute4                 -- 元バラ数量
-- mod end ver1.15
    FROM    mrp_forecast_dates  mfd,   -- Forecast日付
            mrp_forecast_items  mfi,   -- Forecast品目
            ic_item_mst_vl        im,    -- OPM品目マスタ
            mtl_system_items_vl   si     -- 品目マスタ
    WHERE   mfd.organization_id        = mfi.organization_id                      -- 在庫組織ID
      AND   mfd.inventory_item_id      = mfi.inventory_item_id                    -- 品目ID
      AND   mfd.forecast_designator    = gv_3f_forecast_designator                -- Forecast名
      AND   mfd.organization_id        = si.organization_id                       -- 在庫組織ID
      AND   mfi.forecast_designator    = mfd.forecast_designator
      AND   si.organization_id         = mfd.organization_id
      AND   mfd.attribute5             = pv_base_code -- 拠点
      AND   mfd.organization_id        = gn_3f_organization_id                    -- 在庫組織ID
      AND   im.item_no                 = pv_item_code -- 品目コード
      AND   im.item_no                 = si.segment1                              -- 品目コード
      AND   si.inventory_item_id       = mfd.inventory_item_id                    -- 品目ID
      AND   ((gd_keikaku_start_date   >= mfd.forecast_date
              AND
              gd_keikaku_start_date   <= mfd.rate_end_date)
        OR   (gd_keikaku_end_date     >= mfd.forecast_date
              AND
              gd_keikaku_end_date     <= mfd.rate_end_date));
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- A-*-0 IFデータ項目必須チェック
    if_data_null_check( gv_cons_fc_type_keikaku,      -- Forecast分類('計画商品')
                        lv_errbuf,
                        lv_retcode,
                        lv_errmsg );
--
    -- エラーがあったら処理中止
    IF (lv_retcode = gv_status_error) THEN
      gn_error_cnt := gn_error_cnt + 1;
      RAISE global_api_expt;
    END IF;
--
    -- A-4-1 計画商品インターフェースデータ抽出
    get_keikaku_if_data( lt_if_data,
                         lv_errbuf,
                         lv_retcode,
                         lv_errmsg );
--    
    -- データが取得できなければエラー
    IF (lv_retcode = gv_status_error) THEN
      gn_error_cnt := gn_error_cnt + 1;
      RAISE global_api_expt;
    ELSIF (lv_retcode = gv_status_warn) THEN
--del start 1.5
--      gn_warn_cnt := gn_warn_cnt + 1;
--del end 1.5
      RAISE warn_expt;
    END IF;
--
    -- インタ－フェースデータエラーありフラグ初期化
    ln_error_flg :=0;
--
    -- 抽出データチェックループ
    <<if_data_check_loop>>
    FOR ln_data_cnt IN 1..gn_target_cnt LOOP
--
      -- 抽出したデータをチェックする
      -- A-4-2 計画商品抽出データチェック
      keikaku_data_check( lt_if_data,
                          ln_data_cnt,
                          lv_errbuf,
                          lv_retcode,
                          lv_errmsg );
      -- エラーがあった場合は、インタ－フェースデータエラーありフラグONにしつつ、
      -- いったん全データを処理(チェック)して、最後にエラーがあれば処理を中止する。
      -- 警告ならば処理は続行する。
      IF (lv_retcode = gv_status_error) THEN
        ln_error_flg := 1;
--add start 1.9
      ELSIF (lv_retcode = gv_status_warn) THEN
        ln_warn_flg := 1;
--add end 1.9
      END IF;
--
    END LOOP if_data_check_loop;
--
    -- A-4-2 計画商品抽出データチェックでエラーがあった場合は「Forecast処理データループ」
    -- は処理しないでスキップする。
    IF (ln_error_flg = 0) THEN
--
    <<araigae_loop>>
    FOR ln_data_cnt IN 1..gn_target_cnt LOOP
-- 2009/02/17 本番障害#38 DEL Start --
--        -- A-4-3 計画商品Forecast名抽出
--        get_f_degi_keikaku( lt_if_data,
--                            ln_data_cnt,
--                            lv_errbuf,
--                            lv_retcode,
--                            lv_errmsg );
--        -- エラーがあったらループ処理中止
--        IF (lv_retcode = gv_status_error) THEN
---- mod start 1.11
--          FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
---- mod end 1.11
--          gn_error_cnt := gn_error_cnt + 1;
--          ln_error_flg := 1;
--          EXIT;
--        END IF;
---- 2009/02/17 本番障害#38 DEL End   --
-- add start ver1.18
        -- A-4-3 計画商品Forecast名抽出
        get_f_degi_keikaku( lt_if_data,
                            ln_data_cnt,
                            lv_errbuf,
                            lv_retcode,
                            lv_errmsg );
        -- エラーがあったらループ処理中止
        IF (lv_retcode = gv_status_error) THEN
          FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
          gn_error_cnt := gn_error_cnt + 1;
          ln_error_flg := 1;
          EXIT;
        END IF;
-- add end ver1.18
--
      OPEN forecast_araigae_cur(lt_if_data(ln_data_cnt).base_code,lt_if_data(ln_data_cnt).item_code );
--
      FETCH forecast_araigae_cur BULK COLLECT INTO lr_araigae_data;
--
      gn_araigae_cnt := lr_araigae_data.COUNT;
--
      CLOSE forecast_araigae_cur;
--
      <<del_loop>>
      FOR ln_data_cnt2 IN 1..gn_araigae_cnt LOOP
-- add start ver1.15
        -- 開始日付、終了日付の比較
        IF   (TRUNC(lr_araigae_data(ln_data_cnt2).gd_4f_start_date_active) <>
              TRUNC(gd_keikaku_start_date))
          OR (TRUNC(lr_araigae_data(ln_data_cnt2).gd_4f_end_date_active) <>
              TRUNC(gd_keikaku_end_date))
        THEN
          -- メッセージセット
          lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_inv   -- 'XXINV'
                                                        ,gv_msg_10a_021)
                                                                 -- フォーキャスト日付更新ワーニング
                                                        ,1
                                                        ,5000);
          if_data_disp( lt_if_data, ln_data_cnt);
          FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
          -- あらいがえ前データセット
          lv_err := lr_araigae_data(ln_data_cnt2).gv_4f_forecast_designator || ',' || -- フォーキャスト名
                    lr_araigae_data(ln_data_cnt2).gd_4f_item_no             || ',' || -- 品目
                    lr_araigae_data(ln_data_cnt2).gd_4f_quantity            || ',' || -- 数量
                    lr_araigae_data(ln_data_cnt2).gd_4f_start_date_active   || ',' || -- 開始日付
                    lr_araigae_data(ln_data_cnt2).gd_4f_end_date_active     || ',' || -- 終了日付
                    lr_araigae_data(ln_data_cnt2).gd_4f_case_quantity       || ',' || -- 元バラ数量
                    lr_araigae_data(ln_data_cnt2).gd_4f_bara_quantity                 -- 元ケース数量
                    ;
          FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_object || lv_err);
          gn_warn_cnt := gn_warn_cnt + 1;
          ln_warn_flg := 1;
        END IF;
-- add end ver1.15
        -- 削除用変数にセット
-- mod start 1.11
        gn_del_data_cnt := gn_del_data_cnt + 1;
-- add start ver1.15
        gn_del_data_cnt2 := gn_del_data_cnt + 1;
-- add end ver1.15
--        t_forecast_interface_tab_del(1).transaction_id
--                          := lr_araigae_data(ln_data_cnt2).gv_4f_txns_id;            -- 取引ID
--        t_forecast_interface_tab_del(1).forecast_designator
--                          := lr_araigae_data(ln_data_cnt2).gv_4f_forecast_designator;                    -- Forecast名
--        t_forecast_interface_tab_del(1).organization_id
--                          := lr_araigae_data(ln_data_cnt2).gv_4f_organization_id;                        -- 組織ID
--        t_forecast_interface_tab_del(1).inventory_item_id
--                          := lr_araigae_data(ln_data_cnt2).gv_4f_item_id;           -- 品目ID
--        t_forecast_interface_tab_del(1).quantity              := 0;       -- 数量
--        t_forecast_interface_tab_del(1).forecast_date
--                          := lr_araigae_data(ln_data_cnt2).gd_4f_start_date_active;  -- 開始日付
--        t_forecast_interface_tab_del(1).forecast_end_date
--                          := lr_araigae_data(ln_data_cnt2).gd_4f_end_date_active;    -- 終了日付
--        t_forecast_interface_tab_del(1).bucket_type           := 1;
--        t_forecast_interface_tab_del(1).process_status        := 2;
--        t_forecast_interface_tab_del(1).confidence_percentage := 100;
-- del start ver1.18
--        t_forecast_interface_tab_del(gn_del_data_cnt).transaction_id
--                          := lr_araigae_data(ln_data_cnt2).gv_4f_txns_id;             -- 取引ID
-- del end ver1.18
        t_forecast_interface_tab_del(gn_del_data_cnt).forecast_designator
                          := lr_araigae_data(ln_data_cnt2).gv_4f_forecast_designator; -- Forecast名
        t_forecast_interface_tab_del(gn_del_data_cnt).organization_id
                          := lr_araigae_data(ln_data_cnt2).gv_4f_organization_id;     -- 組織ID
        t_forecast_interface_tab_del(gn_del_data_cnt).inventory_item_id
                          := lr_araigae_data(ln_data_cnt2).gv_4f_item_id;             -- 品目ID
-- del start ver1.18
/*        t_forecast_interface_tab_del(gn_del_data_cnt).quantity              := 0;                   -- 数量
        t_forecast_interface_tab_del(gn_del_data_cnt).forecast_date
                          := lr_araigae_data(ln_data_cnt2).gd_4f_start_date_active;   -- 開始日付
        t_forecast_interface_tab_del(gn_del_data_cnt).forecast_end_date
                          := lr_araigae_data(ln_data_cnt2).gd_4f_end_date_active;     -- 終了日付
        t_forecast_interface_tab_del(gn_del_data_cnt).bucket_type           := 1;
        t_forecast_interface_tab_del(gn_del_data_cnt).process_status        := 2;
        t_forecast_interface_tab_del(gn_del_data_cnt).confidence_percentage := 100;*/
-- del end ver1.18
--
--        -- Forecast日付データのクリア
--        lb_retcode := MRP_FORECAST_INTERFACE_PK.MRP_FORECAST_INTERFACE(
--                                              t_forecast_interface_tab_del);
--        -- エラーだった場合
--        IF (lb_retcode = FALSE )THEN
--          lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_cmn   -- 'XXCMN'
--                                                        ,gv_msg_10a_045  -- APIエラー
--                                                    ,gv_tkn_api_name
--                                                    ,gv_cons_api) -- 予測API
--                                                        ,1
--                                                        ,5000);
--          RAISE global_api_expt;
--        END IF;
     END LOOP del_loop;
-- add start ver1.15
      -- Forecast日付データのクリア
     -- あらいがえ対象データの処理カウンタが1000件を超えた場合
     IF (gn_del_data_cnt2 >= 1000) THEN
--
       lb_retcode := MRP_FORECAST_INTERFACE_PK.MRP_FORECAST_INTERFACE(
                                             t_forecast_interface_tab_del);
       -- あらいがえ対象データの処理カウンタ2の初期化
       gn_del_data_cnt2 := 0;
       t_forecast_interface_tab_del.delete;
     -- 抽出インターフェースデータループが終了する場合
-- mod start ver1.16
--     ELSIF (ln_data_cnt = gn_araigae_cnt) THEN
     ELSIF (ln_data_cnt = gn_target_cnt) THEN
-- mod end ver1.16
--
       lb_retcode := MRP_FORECAST_INTERFACE_PK.MRP_FORECAST_INTERFACE(
                                             t_forecast_interface_tab_del);
     END IF;
-- add end ver1.15
    END LOOP araigae_loop;
--
-- del start ver1.15
    -- Forecast日付データのクリア
--    lb_retcode := MRP_FORECAST_INTERFACE_PK.MRP_FORECAST_INTERFACE(
--                                          t_forecast_interface_tab_del);
-- del end ver1.15
--
    <<del_serch_error_loop>>
    FOR ln_data_cnt IN 1..gn_del_data_cnt LOOP
      -- エラーだった場合
-- mod start ver1.18
--      IF ( t_forecast_interface_tab_del(ln_data_cnt).process_status <> 5 ) THEN
      IF ( lb_retcode = FALSE ) THEN
-- mod end ver1.18
      FND_FILE.PUT_LINE(FND_FILE.LOG,'del_serch_error_loop');
        lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_cmn  -- 'XXCMN'
                                                      ,gv_msg_10a_045  -- APIエラー
                                                      ,gv_tkn_api_name
                                                      ,gv_cons_api)    -- 予測API
                                                      ,1
                                                      ,5000);
-- mod start ver1.18
--        FND_FILE.PUT_LINE(FND_FILE.LOG,t_forecast_interface_tab_del(ln_data_cnt).error_message);
        FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errmsg);
-- mod end ver1.18
        gn_error_cnt := gn_error_cnt + 1;
        ln_error_flg := 1;
        EXIT;
      END IF;
    END LOOP del_serch_error_loop;
    -- あらいがえ対象データの処理カウンタの初期化
    gn_del_data_cnt := 0;
-- mod end 1.11
--
-- add start 1.11
      IF (ln_error_flg = 0) THEN
-- add end 1.11
        -- Forecast処理データループ
        <<forecast_ins_loop>>
        FOR ln_data_cnt IN 1..gn_target_cnt LOOP
  --
          -- A-4-3 計画商品Forecast名抽出
          get_f_degi_keikaku( lt_if_data,
                              ln_data_cnt,
                              lv_errbuf,
                              lv_retcode,
                              lv_errmsg );
          -- エラーがあったらループ処理中止
          IF (lv_retcode = gv_status_error) THEN
-- add start 1.11
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
-- add end 1.11
            gn_error_cnt := gn_error_cnt + 1;
            ln_error_flg := 1;
            EXIT;
          END IF;
--
/*
        -- A-4-4 計画商品Forecast日付抽出
        get_f_dates_keikaku( lt_if_data,
                             ln_data_cnt,
                             ln_data_flg,
                             lv_errbuf,
                             lv_retcode,
                             lv_errmsg );
        -- エラーがあったらループ処理中止
        IF (lv_retcode = gv_status_error) THEN
          gn_error_cnt := gn_error_cnt + 1;
          ln_error_flg := 1;
          EXIT;
        END IF;
*/
--
          -- A-4-5 計画商品Forecast登録
          put_forecast_keikaku( lt_if_data,
                                ln_data_cnt,
                                ln_data_flg,
                                lv_errbuf,
                                lv_retcode,
                                lv_errmsg );
          -- エラーがあったらループ処理中止
          IF (lv_retcode = gv_status_error) THEN
-- mod start 1.11
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
-- mod end 1.11
            gn_error_cnt := gn_error_cnt + 1;
            ln_error_flg := 1;
            EXIT;
          END IF;
--
        END LOOP forecast_ins_loop;
-- add start 1.11
      END IF;
-- add end 1.11
--
-- add start 1.11
      IF (ln_error_flg = 0) THEN
        -- Forecastデータに抽出したインターフェースデータを登録
        lb_retcode := MRP_FORECAST_INTERFACE_PK.MRP_FORECAST_INTERFACE(
                                               t_forecast_interface_tab_inst,
                                               t_forecast_designator_tabl);
--
        <<serch_error_loop>>
        FOR ln_data_cnt IN 1..gn_target_cnt LOOP
          -- エラーだった場合
          IF ( t_forecast_interface_tab_inst(ln_data_cnt).process_status <> 5 ) THEN
          FND_FILE.PUT_LINE(FND_FILE.LOG,'serch_error_loop');
            lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_cmn  -- 'XXCMN'
                                                          ,gv_msg_10a_045  -- APIエラー
                                                          ,gv_tkn_api_name
                                                          ,gv_cons_api)    -- 予測API
                                                          ,1
                                                          ,5000);
            FND_FILE.PUT_LINE(FND_FILE.LOG,t_forecast_interface_tab_inst(ln_data_cnt).error_message);
--            FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
            gn_error_cnt := gn_error_cnt + 1;
            ln_error_flg := 1;
            EXIT;
          END IF;
        END LOOP serch_error_loop;
      END IF;
--
      -- 登録対象データのレコードの初期化
      t_forecast_interface_tab_inst.delete;
      t_forecast_designator_tabl.delete;
-- add end 1.11
--
    END IF;
--
    -- エラーがなかった場合はコミットする
    IF (ln_error_flg = 0) THEN
      COMMIT;
    ELSE
      ROLLBACK;
    END IF;
--
    -- A-X-6共通 インターフェーステーブル削除処理
    del_if_data( lt_if_data,
                 lv_errbuf_d,
                 lv_retcode_d,
                 lv_errmsg_d );
    -- エラーがあったら処理中止
    IF (lv_retcode_d = gv_status_error) THEN
      lv_errbuf    := lv_errbuf_d;
      lv_retcode   := lv_retcode_d;
      lv_errmsg    :=lv_errmsg_d;
      RAISE global_api_expt;
    END IF;
--
    -- 各処理でエラーだったらエラーリターンするために
    -- 例外を発生させる
    IF (ln_error_flg = 1) THEN
      RAISE global_api_expt;
--add start 1.9
    ELSIF (ln_warn_flg = 1) THEN
      RAISE warn_expt;
--add end 1.9
    END IF;
--
  EXCEPTION
    WHEN warn_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_warn;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
      gn_error_cnt := gn_error_cnt + 1;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
      gn_error_cnt := gn_error_cnt + 1;
--
--#####################################  固定部 END   ##########################################
--
  END forecast_keikaku;
--
  /**********************************************************************************
   * Procedure Name   : forecast_seigen_a
   * Description      : 出荷数制限A(A-5)
   ***********************************************************************************/
  PROCEDURE forecast_seigen_a(
    ov_errbuf                OUT NOCOPY VARCHAR2,  -- エラー・メッセージ            --# 固定 #
    ov_retcode               OUT NOCOPY VARCHAR2,  -- リターン・コード              --# 固定 #
    ov_errmsg                OUT NOCOPY VARCHAR2)  -- ユーザー・エラー・メッセージ  --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'forecast_seigen_a'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf   VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode  VARCHAR2(1);     -- リターン・コード
    lv_errmsg   VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
    lv_errbuf_d   VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode_d  VARCHAR2(1);     -- リターン・コード
    lv_errmsg_d   VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル変数 ***
    ln_data_cnt   NUMBER;    -- 抽出インターフェースデータの処理カウンタ
    ln_data_flg   NUMBER;    -- 日付データありなしフラグ(0:なし、1:あり)
    ln_error_flg  NUMBER;    -- インタ－フェースデータエラーありフラグ(0:なし, 1:あり)
    lv_err_msg2  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
    ln_data_cnt2   NUMBER;    -- 抽出インターフェースデータの処理カウンタ
    lb_retcode                  BOOLEAN;
--add start 1.9
    ln_warn_flg   NUMBER := 0; -- インタ－フェースデータ警告ありフラグ(0:なし, 1:あり)
--add end 1.9
-- add start ver1.15
    lv_err        VARCHAR2(5000);
-- add end ver1.15
--
    -- *** ローカル・レコード ***
    lt_if_data    forecast_tbl;
    lr_araigae_data                 araigae_tbl;
-- mod start ver1.18
--    t_forecast_interface_tab_del    MRP_FORECAST_INTERFACE_PK.t_forecast_interface;
    t_forecast_interface_tab_del    MRP_FORECAST_INTERFACE_PK.t_forecast_designator;
-- mod end ver1.18
    t_forecast_interface_tab_ins    MRP_FORECAST_INTERFACE_PK.t_forecast_interface;
    t_forecast_designator_tab       MRP_FORECAST_INTERFACE_PK.t_forecast_designator;
--
    -- *** ローカル・カーソル ***
    CURSOR forecast_araigae_cur(pv_item_code in varchar2)
    IS
    SELECT  mfd.transaction_id,          -- 取引ID
            mfd.forecast_designator,     -- Forecast名
            mfd.organization_id,         -- 在庫組織ID
            mfd.inventory_item_id,       -- 品目ID
            mfd.forecast_date,           -- 開始日付
-- mod start ver1.15
--            mfd.rate_end_date            -- 終了日付
            mfd.rate_end_date,             -- 終了日付
            im.item_no,                    -- 品目コード
            mfd.current_forecast_quantity, -- 数量
            mfd.attribute6,                -- 元ケース数量
            mfd.attribute4                 -- 元バラ数量
-- mod end ver1.15
    FROM    mrp_forecast_dates  mfd,   -- Forecast日付
            mrp_forecast_items  mfi,   -- Forecast品目
            ic_item_mst_vl        im,    -- OPM品目マスタ
            mtl_system_items_vl   si     -- 品目マスタ
    WHERE   mfd.organization_id        = mfi.organization_id       -- 在庫組織ID
      AND   mfd.inventory_item_id      = mfi.inventory_item_id     -- 品目ID
      AND   mfd.forecast_designator    = gv_3f_forecast_designator -- Forecast名
      AND   mfd.organization_id        = gn_3f_organization_id     -- 在庫組織ID
      AND   mfi.forecast_designator    = mfd.forecast_designator
      AND   si.organization_id         = mfd.organization_id
      AND   im.item_no                 = pv_item_code -- 品目コード
      AND   im.item_no                 = si.segment1               -- 品目コード
      AND   si.inventory_item_id       = mfd.inventory_item_id     -- 品目ID
      AND   ((gd_in_start_date         >= mfd.forecast_date
              AND
              gd_in_start_date         <= mfd.rate_end_date)
        OR   (gd_in_end_date           >= mfd.forecast_date
              AND
              gd_in_end_date           <= mfd.rate_end_date));
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- A-*-0 IFデータ項目必須チェック
    if_data_null_check( gv_cons_fc_type_seigen_a,      -- Forecast分類('出荷数制限A')
                        lv_errbuf,
                        lv_retcode,
                        lv_errmsg );
--
    -- エラーがあったら処理中止
    IF (lv_retcode = gv_status_error) THEN
      gn_error_cnt := gn_error_cnt + 1;
      RAISE global_api_expt;
    END IF;
--
    -- A-5-1 出荷数制限Aインターフェースデータ抽出
    get_seigen_a_if_data( lt_if_data,
                          lv_errbuf,
                          lv_retcode,
                          lv_errmsg );
--
    -- データが取得できなければエラー
    IF (lv_retcode = gv_status_error) THEN
      gn_error_cnt := gn_error_cnt + 1;
      RAISE global_api_expt;
    ELSIF (lv_retcode = gv_status_warn) THEN
--del start 1.5
--      gn_warn_cnt := gn_warn_cnt + 1;
--del end 1.5
-- 2009/05/19 ADD START
      -- IFデータを削除する
      -- A-X-6共通 インターフェーステーブル削除処理
      FND_FILE.PUT_LINE(FND_FILE.LOG,'del_if_data開始');
      del_if_data( lt_if_data,
                   lv_errbuf_d,
                   lv_retcode_d,
                   lv_errmsg_d );
-- 2009/05/19 ADD START
      RAISE warn_expt;
    END IF;
--
    -- インタ－フェースデータエラーありフラグ初期化
    ln_error_flg :=0;
    -- 抽出データチェックループ
    <<if_data_check_loop>>
    FOR ln_data_cnt IN 1..gn_target_cnt LOOP
--
      -- 抽出したデータをチェックする
      -- A-5-2 出荷数制限A抽出データチェック
      seigen_a_data_check( lt_if_data,
                          ln_data_cnt,
                          lv_errbuf,
                          lv_retcode,
                          lv_errmsg );
      -- エラーがあった場合は、インタ－フェースデータエラーありフラグONにしつつ、
      -- いったん全データを処理(チェック)して、最後にエラーがあれば処理を中止する。
      -- 警告ならば処理は続行する。
      IF (lv_retcode = gv_status_error) THEN
        ln_error_flg := 1;
--add start 1.9
      ELSIF (lv_retcode = gv_status_warn) THEN
        ln_warn_flg := 1;
--add end 1.9
      END IF;
--
    END LOOP if_data_check_loop;
--
    -- A-5-2 出荷数制限A抽出データチェックでエラーがあった場合は「Forecast処理データループ」
    -- は処理しないでスキップする。
    IF (ln_error_flg = 0) THEN
--
      -- Forecast処理データループ
      <<araigae_loop>>
      FOR ln_data_cnt IN 1..gn_target_cnt LOOP
--
-- 2009/02/17 本番障害#38対応 DEL Start --
--        -- A-5-3 出荷数制限AForecast名抽出
--        get_f_degi_seigen_a( lt_if_data,
--                             ln_data_cnt,
--                             lv_errbuf,
--                             lv_retcode,
--                             lv_errmsg );
--        lv_err_msg2 := lv_errmsg;
--        -- エラーがあったらループ処理中止
--        IF (lv_retcode = gv_status_error) THEN
---- mod start 1.11
--          FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
---- mod end 1.11
--          gn_error_cnt := gn_error_cnt + 1;
--          ln_error_flg := 1;
--          EXIT;
--        END IF;
-- 2009/02/17 本番障害#38対応 DEL End ----
-- add start ver1.18
        -- A-5-3 出荷数制限AForecast名抽出
        get_f_degi_seigen_a( lt_if_data,
                             ln_data_cnt,
                             lv_errbuf,
                             lv_retcode,
                             lv_errmsg );
        lv_err_msg2 := lv_errmsg;
        -- エラーがあったらループ処理中止
        IF (lv_retcode = gv_status_error) THEN
          FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
          gn_error_cnt := gn_error_cnt + 1;
          ln_error_flg := 1;
          EXIT;
        END IF;
-- add end ver1.18
--
      OPEN forecast_araigae_cur(lt_if_data(ln_data_cnt).item_code);
--
      FETCH forecast_araigae_cur BULK COLLECT INTO lr_araigae_data;
--
      gn_araigae_cnt := lr_araigae_data.COUNT;
--
      CLOSE forecast_araigae_cur;
--
      <<del_loop>>
      FOR ln_data_cnt2 IN 1..gn_araigae_cnt LOOP
--
      -- 開始日付の比較
      IF (TRUNC(lr_araigae_data(ln_data_cnt2).gd_4f_start_date_active) <>
        TRUNC(lt_if_data(ln_data_cnt).start_date_active))
      THEN
        -- メッセージセット
-- mod start ver1.15
--mod start 1.9
        lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_inv   -- 'XXINV'
--        ov_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_inv   -- 'XXINV'
--mod end 1.9
                                                               -- フォーキャスト日付更新ワーニング
                                                      ,gv_msg_10a_021)
                                                      ,1
                                                      ,5000);
        -- 処理結果レポートに出力
        if_data_disp( lt_if_data, ln_data_cnt);
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
        -- あらいがえ前データセット
        lv_err := lr_araigae_data(ln_data_cnt2).gv_4f_forecast_designator || ',' || -- フォーキャスト名
                  lr_araigae_data(ln_data_cnt2).gd_4f_item_no             || ',' || -- 品目
                  lr_araigae_data(ln_data_cnt2).gd_4f_quantity            || ',' || -- 数量
                  lr_araigae_data(ln_data_cnt2).gd_4f_start_date_active   || ',' || -- 開始日付
                  lr_araigae_data(ln_data_cnt2).gd_4f_end_date_active     || ',' || -- 終了日付
                  lr_araigae_data(ln_data_cnt2).gd_4f_case_quantity       || ',' || -- 元バラ数量
                  lr_araigae_data(ln_data_cnt2).gd_4f_bara_quantity                 -- 元ケース数量
                  ;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_object || lv_err);
        gn_warn_cnt := gn_warn_cnt + 1;
-- mod end ver1.15
--add start 1.9
        ln_warn_flg := 1;
--add end 1.9
      END IF;
--
      -- 終了日付の比較
      IF (TRUNC(lr_araigae_data(ln_data_cnt2).gd_4f_end_date_active) <>
        TRUNC(lt_if_data(ln_data_cnt).end_date_active))
      THEN
        -- メッセージセット
-- mod start ver1.15
--mod start 1.9
        lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_inv   -- 'XXINV'
--        ov_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_inv   -- 'XXINV'
--mod end 1.9
                                                               -- フォーキャスト日付更新ワーニング
                                                      ,gv_msg_10a_021)
                                                      ,1
                                                      ,5000);
        -- 処理結果レポートに出力
        if_data_disp( lt_if_data, ln_data_cnt);
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
        -- あらいがえ前データセット
        lv_err := lr_araigae_data(ln_data_cnt2).gv_4f_forecast_designator || ',' || -- フォーキャスト名
                  lr_araigae_data(ln_data_cnt2).gd_4f_item_no             || ',' || -- 品目
                  lr_araigae_data(ln_data_cnt2).gd_4f_quantity            || ',' || -- 数量
                  lr_araigae_data(ln_data_cnt2).gd_4f_start_date_active   || ',' || -- 開始日付
                  lr_araigae_data(ln_data_cnt2).gd_4f_end_date_active     || ',' || -- 終了日付
                  lr_araigae_data(ln_data_cnt2).gd_4f_case_quantity       || ',' || -- 元バラ数量
                  lr_araigae_data(ln_data_cnt2).gd_4f_bara_quantity                 -- 元ケース数量
                  ;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_object || lv_err);
        gn_warn_cnt := gn_warn_cnt + 1;
-- mod end ver1.15
--add start 1.9
        ln_warn_flg := 1;
--add end 1.9
      END IF;
--
      -- 登録済みデータの削除のためのデータセット
-- mod start 1.11
        gn_del_data_cnt := gn_del_data_cnt + 1;
-- add start ver1.15
        gn_del_data_cnt2 := gn_del_data_cnt + 1;
-- add end ver1.15
--      t_forecast_interface_tab_del(1).transaction_id
--                         := lr_araigae_data(ln_data_cnt2).gv_4f_txns_id;            -- 取引ID
--      t_forecast_interface_tab_del(1).forecast_designator
--                         := lr_araigae_data(ln_data_cnt2).gv_4f_forecast_designator;-- Forecast名
--      t_forecast_interface_tab_del(1).organization_id
--                         := lr_araigae_data(ln_data_cnt2).gv_4f_organization_id;    -- 組織ID
--      t_forecast_interface_tab_del(1).inventory_item_id
--                         := lr_araigae_data(ln_data_cnt2).gv_4f_item_id;            -- 品目ID
--      t_forecast_interface_tab_del(1).quantity              := 0;        -- 数量
--      t_forecast_interface_tab_del(1).forecast_date
--                         := lr_araigae_data(ln_data_cnt2).gd_4f_start_date_active;  -- 開始日付
--      t_forecast_interface_tab_del(1).forecast_end_date
--                         := lr_araigae_data(ln_data_cnt2).gd_4f_end_date_active;    -- 終了日付
--      t_forecast_interface_tab_del(1).bucket_type           := 1;
--      t_forecast_interface_tab_del(1).process_status        := 2;
--      t_forecast_interface_tab_del(1).confidence_percentage := 100;
-- del start ver1.18
--        t_forecast_interface_tab_del(gn_del_data_cnt).transaction_id
--                           := lr_araigae_data(ln_data_cnt2).gv_4f_txns_id;            -- 取引ID
-- del end ver1.18
        t_forecast_interface_tab_del(gn_del_data_cnt).forecast_designator
                           := lr_araigae_data(ln_data_cnt2).gv_4f_forecast_designator;-- Forecast名
        t_forecast_interface_tab_del(gn_del_data_cnt).organization_id
                           := lr_araigae_data(ln_data_cnt2).gv_4f_organization_id;    -- 組織ID
        t_forecast_interface_tab_del(gn_del_data_cnt).inventory_item_id
                           := lr_araigae_data(ln_data_cnt2).gv_4f_item_id;            -- 品目ID
-- del start ver1.18
/*        t_forecast_interface_tab_del(gn_del_data_cnt).quantity              := 0;        -- 数量
        t_forecast_interface_tab_del(gn_del_data_cnt).forecast_date
                           := lr_araigae_data(ln_data_cnt2).gd_4f_start_date_active;  -- 開始日付
        t_forecast_interface_tab_del(gn_del_data_cnt).forecast_end_date
                           := lr_araigae_data(ln_data_cnt2).gd_4f_end_date_active;    -- 終了日付
        t_forecast_interface_tab_del(gn_del_data_cnt).bucket_type           := 1;
        t_forecast_interface_tab_del(gn_del_data_cnt).process_status        := 2;
        t_forecast_interface_tab_del(gn_del_data_cnt).confidence_percentage := 100;*/
-- del end ver1.18
--
      -- 登録済みデータの削除
--        lb_retcode := MRP_FORECAST_INTERFACE_PK.MRP_FORECAST_INTERFACE(
--                                              t_forecast_interface_tab_del);
        -- エラーだった場合
--        IF (lb_retcode = FALSE )THEN
--          lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_cmn  -- 'XXCMN'
--                                                        ,gv_msg_10a_045 -- APIエラー
--                                                        ,gv_tkn_api_name
--                                                        ,gv_cons_api) -- 予測API
--                                                        ,1
--                                                        ,5000);
--          RAISE global_api_expt;
--        END IF;
      END LOOP del_loop;
-- add start ver1.15
      -- Forecast日付データのクリア
     -- あらいがえ対象データの処理カウンタが1000件を超えた場合
     IF (gn_del_data_cnt2 >= 1000) THEN
--
       lb_retcode := MRP_FORECAST_INTERFACE_PK.MRP_FORECAST_INTERFACE(
                                             t_forecast_interface_tab_del);
       -- あらいがえ対象データの処理カウンタ2の初期化
       gn_del_data_cnt2 := 0;
       t_forecast_interface_tab_del.delete;
     -- 抽出インターフェースデータループが終了する場合
-- mod start ver1.16
--     ELSIF (ln_data_cnt = gn_araigae_cnt) THEN
     ELSIF (ln_data_cnt = gn_target_cnt) THEN
-- mod end ver1.16
--
       lb_retcode := MRP_FORECAST_INTERFACE_PK.MRP_FORECAST_INTERFACE(
                                             t_forecast_interface_tab_del);
     END IF;
-- add end ver1.15
    END LOOP araigae_loop;
-- del start ver1.15
    -- Forecast日付データのクリア
--    lb_retcode := MRP_FORECAST_INTERFACE_PK.MRP_FORECAST_INTERFACE(
--                                           t_forecast_interface_tab_del);
-- del end ver1.15
--
    <<del_serch_error_loop>>
    FOR ln_data_cnt IN 1..gn_del_data_cnt LOOP
      -- エラーだった場合
-- mod start ver1.18
--      IF ( t_forecast_interface_tab_del(ln_data_cnt).process_status <> 5 ) THEN
      IF ( lb_retcode = FALSE ) THEN
-- mod end ver1.18
        lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_cmn  -- 'XXCMN'
                                                      ,gv_msg_10a_045  -- APIエラー
                                                      ,gv_tkn_api_name
                                                      ,gv_cons_api)    -- 予測API
                                                      ,1
                                                      ,5000);
-- mod start ver1.18
--        FND_FILE.PUT_LINE(FND_FILE.LOG,t_forecast_interface_tab_del(ln_data_cnt).error_message);
        FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errmsg);
-- mod end ver1.18
        gn_error_cnt := gn_error_cnt + 1;
        ln_error_flg := 1;
        EXIT;
      END IF;
    END LOOP del_serch_error_loop;
    -- あらいがえ対象データの処理カウンタの初期化
    gn_del_data_cnt := 0;
-- mod end 1.11
--
-- add start 1.11
      IF (ln_error_flg = 0) THEN
-- add end 1.11
        <<forecast_ins_loop>>
        FOR ln_data_cnt IN 1..gn_target_cnt LOOP
--
          -- A-5-3 出荷数制限AForecast名抽出
          get_f_degi_seigen_a( lt_if_data,
                               ln_data_cnt,
                               lv_errbuf,
                               lv_retcode,
                               lv_errmsg );
          lv_err_msg2 := lv_errmsg;
          -- エラーがあったらループ処理中止
          IF (lv_retcode = gv_status_error) THEN
-- mod start 1.11
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
-- mod end 1.11
            gn_error_cnt := gn_error_cnt + 1;
            ln_error_flg := 1;
            EXIT;
          END IF;
  --
  /*
          -- A-5-4 出荷数制限AForecast日付抽出
          get_f_dates_seigen_a( lt_if_data,
                                ln_data_cnt,
                                ln_data_flg,
                                lv_errbuf,
                                lv_retcode,
                                lv_errmsg );
          lv_err_msg2 := lv_errmsg;
          -- エラーがあったらループ処理中止
          IF (lv_retcode = gv_status_error) THEN
            gn_error_cnt := gn_error_cnt + 1;
            ln_error_flg := 1;
            EXIT;
          END IF;
  */
--
          -- A-5-5 出荷数制限AForecast登録
          put_forecast_seigen_a( lt_if_data,
                                 ln_data_cnt,
                                 ln_data_flg,
                                 lv_errbuf,
                                 lv_retcode,
                                 lv_errmsg );
          lv_err_msg2 := lv_errmsg;
          -- エラーがあったらループ処理中止
          IF (lv_retcode = gv_status_error) THEN
-- mod start 1.11
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
-- mod end 1.11
            gn_error_cnt := gn_error_cnt + 1;
            ln_error_flg := 1;
            EXIT;
          END IF;
--
        END LOOP forecast_ins_loop;
-- add start 1.11
      END IF;
-- add end 1.11
--
-- add start 1.11
      IF (ln_error_flg = 0) THEN
        -- Forecastデータに抽出したインターフェースデータを登録
        lb_retcode := MRP_FORECAST_INTERFACE_PK.MRP_FORECAST_INTERFACE(
                                               t_forecast_interface_tab_inst,
                                               t_forecast_designator_tabl);
--
        <<serch_error_loop>>
        FOR ln_data_cnt IN 1..gn_target_cnt LOOP
          -- エラーだった場合
          IF ( t_forecast_interface_tab_inst(ln_data_cnt).process_status <> 5 ) THEN
            lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_cmn  -- 'XXCMN'
                                                          ,gv_msg_10a_045  -- APIエラー
                                                          ,gv_tkn_api_name
                                                          ,gv_cons_api)    -- 予測API
                                                          ,1
                                                          ,5000);
            FND_FILE.PUT_LINE(FND_FILE.LOG,t_forecast_interface_tab_inst(ln_data_cnt).error_message);
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
            gn_error_cnt := gn_error_cnt + 1;
            ln_error_flg := 1;
            EXIT;
          END IF;
        END LOOP serch_error_loop;
      END IF;
--
      -- 登録対象データのレコードの初期化
      t_forecast_interface_tab_inst.delete;
      t_forecast_designator_tabl.delete;
-- add end 1.11
    END IF;
--
    -- エラーがなかった場合はコミットする
    IF (ln_error_flg = 0) THEN
      COMMIT;
    ELSE
      ROLLBACK;
    END IF;
--
    -- A-X-6共通 インターフェーステーブル削除処理
    del_if_data( lt_if_data,
                 lv_errbuf_d,
                 lv_retcode_d,
                 lv_errmsg_d );
    -- エラーがあったら処理中止
    IF (lv_retcode_d = gv_status_error) THEN
      gn_error_cnt := gn_error_cnt + 1;
      lv_errbuf    := lv_errbuf_d;
      lv_retcode   := lv_retcode_d;
      lv_errmsg    :=lv_errmsg_d;
      RAISE global_api_expt;
    END IF;
--
    -- A-5-2 出荷数制限A抽出データチェックでエラーだったらエラーリターンするために
    -- 例外を発生させる
    IF (ln_error_flg = 1) THEN
      lv_errmsg := lv_err_msg2;
      RAISE global_api_expt;
--add start 1.9
    ELSIF (ln_warn_flg = 1) THEN
      RAISE warn_expt;
--add end 1.9
    END IF;
--
  EXCEPTION
    WHEN warn_expt THEN
--del start 1.9
--      ov_errmsg  := lv_errmsg;
--del end 1.9
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_warn;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
      gn_error_cnt := gn_error_cnt + 1;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
      gn_error_cnt := gn_error_cnt + 1;
--
--#####################################  固定部 END   ##########################################
--
  END forecast_seigen_a;
--
  /**********************************************************************************
   * Procedure Name   : forecast_seigen_b
   * Description      : 出荷数制限B(A-6)
   ***********************************************************************************/
  PROCEDURE forecast_seigen_b(
    ov_errbuf                OUT NOCOPY VARCHAR2,  -- エラー・メッセージ            --# 固定 #
    ov_retcode               OUT NOCOPY VARCHAR2,  -- リターン・コード              --# 固定 #
    ov_errmsg                OUT NOCOPY VARCHAR2)  -- ユーザー・エラー・メッセージ  --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'forecast_seigen_b'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
    lv_errbuf_d  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode_d VARCHAR2(1);     -- リターン・コード
    lv_errmsg_d  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル変数 ***
    ln_data_cnt   NUMBER;    -- 抽出インターフェースデータの処理カウンタ
    ln_data_flg   NUMBER;    -- 日付データありなしフラグ(0:なし、1:あり)
    ln_error_flg  NUMBER;    -- インタ－フェースデータエラーありフラグ(0:なし, 1:あり)
    ln_data_cnt2   NUMBER;    -- 抽出インターフェースデータの処理カウンタ
    lb_retcode                  BOOLEAN;
--add start 1.9
    ln_warn_flg   NUMBER := 0; -- インタ－フェースデータ警告ありフラグ(0:なし, 1:あり)
--add end 1.9
-- add start ver1.15
    lv_err        VARCHAR2(5000);
-- add end ver1.15
--
    -- *** ローカル・レコード ***
    lr_araigae_data                 araigae_tbl;
-- mod start ver1.18
--    t_forecast_interface_tab_del    MRP_FORECAST_INTERFACE_PK.t_forecast_interface;
    t_forecast_interface_tab_del    MRP_FORECAST_INTERFACE_PK.t_forecast_designator;
-- mod end ver1.18
    t_forecast_interface_tab_ins    MRP_FORECAST_INTERFACE_PK.t_forecast_interface;
    t_forecast_designator_tab       MRP_FORECAST_INTERFACE_PK.t_forecast_designator;
    lt_if_data    forecast_tbl;
--
    -- *** ローカル・カーソル ***
    CURSOR forecast_araigae_cur(pv_item_code in varchar2)
    IS
    SELECT  mfd.transaction_id,          -- 取引ID
            mfd.forecast_designator,     -- Forecast名
            mfd.organization_id,         -- 在庫組織ID
            mfd.inventory_item_id,       -- 品目ID
            mfd.forecast_date,           -- 開始日付
-- mod start ver1.15
--            mfd.rate_end_date            -- 終了日付
            mfd.rate_end_date,             -- 終了日付
            im.item_no,                    -- 品目コード
            mfd.current_forecast_quantity, -- 数量
            mfd.attribute6,                -- 元ケース数量
            mfd.attribute4                 -- 元バラ数量
-- mod end ver1.15
    FROM    mrp_forecast_dates  mfd,   -- Forecast日付
            mrp_forecast_items  mfi,   -- Forecast品目
            ic_item_mst_vl        im,    -- OPM品目マスタ
            mtl_system_items_vl   si     -- 品目マスタ
    WHERE   mfd.organization_id        = mfi.organization_id       -- 在庫組織ID
      AND   mfd.inventory_item_id      = mfi.inventory_item_id     -- 品目ID
      AND   mfd.forecast_designator    = gv_3f_forecast_designator -- Forecast名
      AND   mfd.organization_id        = gn_3f_organization_id     -- 在庫組織ID
      AND   mfi.forecast_designator    = mfd.forecast_designator
      AND   si.organization_id         = mfd.organization_id
AND (im.item_no = NVL(pv_item_code,im.item_no)
  OR
     im.item_no IS NULL )
      AND   im.item_no                 = si.segment1               -- 品目コード
      AND   si.inventory_item_id       = mfd.inventory_item_id     -- 品目ID
      AND   ((gd_in_start_date         >= mfd.forecast_date
              AND
              gd_in_start_date         <= mfd.rate_end_date)
        OR   (gd_in_end_date           >= mfd.forecast_date
              AND
              gd_in_end_date           <= mfd.rate_end_date));
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- A-*-0 IFデータ項目必須チェック
    if_data_null_check( gv_cons_fc_type_seigen_b,      -- Forecast分類('出荷数制限B')
                        lv_errbuf,
                        lv_retcode,
                        lv_errmsg );
--
    -- エラーがあったら処理中止
    IF (lv_retcode = gv_status_error) THEN
      gn_error_cnt := gn_error_cnt + 1;
      RAISE global_api_expt;
    END IF;
--
    -- A-6-1 出荷数制限Bインターフェースデータ抽出
    get_seigen_b_if_data( lt_if_data,
                          lv_errbuf,
                          lv_retcode,
                          lv_errmsg );
--
    -- データが取得できなければエラー
    IF (lv_retcode = gv_status_error) THEN
      gn_error_cnt := gn_error_cnt + 1;
      RAISE global_api_expt;
    ELSIF (lv_retcode = gv_status_warn) THEN
--del start 1.5
--      gn_warn_cnt := gn_warn_cnt + 1;
--del end 1.5
-- 2009/05/19 ADD START
      -- IFデータを削除する
      -- A-X-6共通 インターフェーステーブル削除処理
      del_if_data( lt_if_data,
                   lv_errbuf_d,
                   lv_retcode_d,
                   lv_errmsg_d );
-- 2009/05/19 ADD START
      RAISE warn_expt;
    END IF;
--
    -- インタ－フェースデータエラーありフラグ初期化
    ln_error_flg :=0;
--
    -- 抽出データチェックループ
    <<if_data_check_loop>>
    FOR ln_data_cnt IN 1..gn_target_cnt LOOP
--
      -- 抽出したデータをチェックする
      -- A-6-2 出荷数制限B抽出データチェック
      seigen_b_data_check( lt_if_data,
                           ln_data_cnt,
                           lv_errbuf,
                           lv_retcode,
                           lv_errmsg );
      -- エラーがあった場合は、インタ－フェースデータエラーありフラグONにしつつ、
      -- いったん全データを処理(チェック)して、最後にエラーがあれば処理を中止する。
      -- 警告ならば処理は続行する。
      IF (lv_retcode = gv_status_error) THEN
        ln_error_flg := 1;
--add start 1.9
      ELSIF (lv_retcode = gv_status_warn) THEN
        ln_warn_flg := 1;
--add end 1.9
      END IF;
--
    END LOOP if_data_check_loop;
--
    -- A-6-2 出荷数制限B抽出データチェックでエラーがあった場合は「Forecast処理データループ」
    -- は処理しないでスキップする。
    IF (ln_error_flg = 0) THEN
      -- Forecast処理データループ
      <<araigae_loop>>
      FOR ln_data_cnt IN 1..gn_target_cnt LOOP
--
-- 2009/02/17 本番障害#38対応 DEL Start --
--        -- A-6-3 出荷数制限BForecast名抽出
--        get_f_degi_seigen_b( lt_if_data,
--                             ln_data_cnt,
--                             lv_errbuf,
--                             lv_retcode,
--                             lv_errmsg );
--        -- エラーがあったらループ処理中止
--        IF (lv_retcode = gv_status_error) THEN
---- mod start 1.11
--          FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
---- mod end 1.11
--          gn_error_cnt := gn_error_cnt + 1;
--          ln_error_flg := 1;
--          EXIT;
--        END IF;
-- 2009/02/17 本番障害#38対応 DEL End ----
-- add start ver1.18
        -- A-6-3 出荷数制限BForecast名抽出
        get_f_degi_seigen_b( lt_if_data,
                             ln_data_cnt,
                             lv_errbuf,
                             lv_retcode,
                             lv_errmsg );
        -- エラーがあったらループ処理中止
        IF (lv_retcode = gv_status_error) THEN
          FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
          gn_error_cnt := gn_error_cnt + 1;
          ln_error_flg := 1;
          EXIT;
        END IF;
-- add end ver1.18
--
      OPEN forecast_araigae_cur(lt_if_data(ln_data_cnt).item_code);
--
      FETCH forecast_araigae_cur BULK COLLECT INTO lr_araigae_data;
--
      gn_araigae_cnt := lr_araigae_data.COUNT;
--
      CLOSE forecast_araigae_cur;
--
      <<del_loop>>
      FOR ln_data_cnt2 IN 1..gn_araigae_cnt LOOP
--
      -- 開始日付の比較
      IF (TRUNC(lr_araigae_data(ln_data_cnt2).gd_4f_start_date_active) <>
        TRUNC(lt_if_data(ln_data_cnt).start_date_active))
      THEN
        -- メッセージセット
-- mod start ver1.15
--mod start 1.9
        lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_inv   -- 'XXINV'
--        ov_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_inv   -- 'XXINV'
--mod end 1.9
                                                               -- フォーキャスト日付更新ワーニング
                                                      ,gv_msg_10a_021)
                                                      ,1
                                                      ,5000);
        -- 処理結果レポートに出力
        if_data_disp( lt_if_data, ln_data_cnt);
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
        -- あらいがえ前データセット
        lv_err := lr_araigae_data(ln_data_cnt2).gv_4f_forecast_designator || ',' || -- フォーキャスト名
                  lr_araigae_data(ln_data_cnt2).gd_4f_item_no             || ',' || -- 品目
                  lr_araigae_data(ln_data_cnt2).gd_4f_quantity            || ',' || -- 数量
                  lr_araigae_data(ln_data_cnt2).gd_4f_start_date_active   || ',' || -- 開始日付
                  lr_araigae_data(ln_data_cnt2).gd_4f_end_date_active     || ',' || -- 終了日付
                  lr_araigae_data(ln_data_cnt2).gd_4f_case_quantity       || ',' || -- 元バラ数量
                  lr_araigae_data(ln_data_cnt2).gd_4f_bara_quantity                 -- 元ケース数量
                  ;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_object || lv_err);
-- mod end ver1.15
--add start 1.9
        ln_warn_flg := 1;
--add end 1.9
      END IF;
--
      -- 終了日付の比較
      IF (TRUNC(lr_araigae_data(ln_data_cnt2).gd_4f_end_date_active) <>
        TRUNC(lt_if_data(ln_data_cnt).end_date_active))
      THEN
        -- メッセージセット
-- mod start ver1.15
--mod start 1.9
        lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_inv   -- 'XXINV'
--        ov_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_inv   -- 'XXINV'
--mod end 1.9
                                                               -- フォーキャスト日付更新ワーニング
                                                      ,gv_msg_10a_021)
                                                      ,1
                                                      ,5000);
        -- 処理結果レポートに出力
        if_data_disp( lt_if_data, ln_data_cnt);
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
        -- あらいがえ前データセット
        lv_err := lr_araigae_data(ln_data_cnt2).gv_4f_forecast_designator || ',' || -- フォーキャスト名
                  lr_araigae_data(ln_data_cnt2).gd_4f_item_no             || ',' || -- 品目
                  lr_araigae_data(ln_data_cnt2).gd_4f_quantity            || ',' || -- 数量
                  lr_araigae_data(ln_data_cnt2).gd_4f_start_date_active   || ',' || -- 開始日付
                  lr_araigae_data(ln_data_cnt2).gd_4f_end_date_active     || ',' || -- 終了日付
                  lr_araigae_data(ln_data_cnt2).gd_4f_case_quantity       || ',' || -- 元バラ数量
                  lr_araigae_data(ln_data_cnt2).gd_4f_bara_quantity                 -- 元ケース数量
                  ;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_object || lv_err);
-- mod end ver1.15
--add start 1.9
        ln_warn_flg := 1;
--add end 1.9
      END IF;
--
      -- 登録済みデータの削除のためのデータセット
-- mod start 1.11
      gn_del_data_cnt := gn_del_data_cnt + 1;
-- add start ver1.15
      gn_del_data_cnt2 := gn_del_data_cnt + 1;
-- add end ver1.15
--      t_forecast_interface_tab_del(1).transaction_id
--                         := lr_araigae_data(ln_data_cnt2).gv_4f_txns_id;            -- 取引ID
--      t_forecast_interface_tab_del(1).forecast_designator
--                         := lr_araigae_data(ln_data_cnt2).gv_4f_forecast_designator;-- Forecast名
--      t_forecast_interface_tab_del(1).organization_id
--                         := lr_araigae_data(ln_data_cnt2).gv_4f_organization_id;    -- 組織ID
--      t_forecast_interface_tab_del(1).inventory_item_id
--                         := lr_araigae_data(ln_data_cnt2).gv_4f_item_id;            -- 品目ID
--      t_forecast_interface_tab_del(1).quantity              := 0;        -- 数量
--      t_forecast_interface_tab_del(1).forecast_date
--                         := lr_araigae_data(ln_data_cnt2).gd_4f_start_date_active;  -- 開始日付
--      t_forecast_interface_tab_del(1).forecast_end_date
--                         := lr_araigae_data(ln_data_cnt2).gd_4f_end_date_active;    -- 終了日付
--      t_forecast_interface_tab_del(1).bucket_type           := 1;
--      t_forecast_interface_tab_del(1).process_status        := 2;
--      t_forecast_interface_tab_del(1).confidence_percentage := 100;
-- del start ver1.18
--      t_forecast_interface_tab_del(gn_del_data_cnt).transaction_id
--                         := lr_araigae_data(ln_data_cnt2).gv_4f_txns_id;            -- 取引ID
-- del end ver1.18
      t_forecast_interface_tab_del(gn_del_data_cnt).forecast_designator
                         := lr_araigae_data(ln_data_cnt2).gv_4f_forecast_designator;-- Forecast名
      t_forecast_interface_tab_del(gn_del_data_cnt).organization_id
                         := lr_araigae_data(ln_data_cnt2).gv_4f_organization_id;    -- 組織ID
      t_forecast_interface_tab_del(gn_del_data_cnt).inventory_item_id
                         := lr_araigae_data(ln_data_cnt2).gv_4f_item_id;            -- 品目ID
-- del start ver1.18
/*      t_forecast_interface_tab_del(gn_del_data_cnt).quantity              := 0;        -- 数量
      t_forecast_interface_tab_del(gn_del_data_cnt).forecast_date
                         := lr_araigae_data(ln_data_cnt2).gd_4f_start_date_active;  -- 開始日付
      t_forecast_interface_tab_del(gn_del_data_cnt).forecast_end_date
                         := lr_araigae_data(ln_data_cnt2).gd_4f_end_date_active;    -- 終了日付
      t_forecast_interface_tab_del(gn_del_data_cnt).bucket_type           := 1;
      t_forecast_interface_tab_del(gn_del_data_cnt).process_status        := 2;
      t_forecast_interface_tab_del(gn_del_data_cnt).confidence_percentage := 100;*/
-- del end ver1.18
--
      -- 登録済みデータの削除
--        lb_retcode := MRP_FORECAST_INTERFACE_PK.MRP_FORECAST_INTERFACE(
--                                              t_forecast_interface_tab_del);
        -- エラーだった場合
--        IF (lb_retcode = FALSE )THEN
--          lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_cmn  -- 'XXCMN'
--                                                        ,gv_msg_10a_045 -- APIエラー
--                                                        ,gv_tkn_api_name
--                                                        ,gv_cons_api) -- 予測API
--                                                        ,1
--                                                        ,5000);
--          RAISE global_api_expt;
--        END IF;
      END LOOP del_loop;
-- add start ver1.15
      -- Forecast日付データのクリア
     -- あらいがえ対象データの処理カウンタが1000件を超えた場合
     IF (gn_del_data_cnt2 >= 1000) THEN
--
       lb_retcode := MRP_FORECAST_INTERFACE_PK.MRP_FORECAST_INTERFACE(
                                             t_forecast_interface_tab_del);
       -- あらいがえ対象データの処理カウンタ2の初期化
       gn_del_data_cnt2 := 0;
       t_forecast_interface_tab_del.delete;
     -- 抽出インターフェースデータループが終了する場合
-- mod start ver1.16
--     ELSIF (ln_data_cnt = gn_araigae_cnt) THEN
     ELSIF (ln_data_cnt = gn_target_cnt) THEN
-- mod end ver1.16
--
       lb_retcode := MRP_FORECAST_INTERFACE_PK.MRP_FORECAST_INTERFACE(
                                             t_forecast_interface_tab_del);
     END IF;
-- add end ver1.15
    END LOOP araigae_loop;
-- del start ver1.15
    -- Forecast日付データのクリア
--    lb_retcode := MRP_FORECAST_INTERFACE_PK.MRP_FORECAST_INTERFACE(
--                                           t_forecast_interface_tab_del);
-- del end ver1.15
--
    <<del_serch_error_loop>>
    FOR ln_data_cnt IN 1..gn_del_data_cnt LOOP
      -- エラーだった場合
-- mod start ver1.18
--      IF ( t_forecast_interface_tab_del(ln_data_cnt).process_status <> 5 ) THEN
      IF ( lb_retcode = FALSE ) THEN
-- mod end ver1.18
        lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_cmn  -- 'XXCMN'
                                                      ,gv_msg_10a_045  -- APIエラー
                                                      ,gv_tkn_api_name
                                                      ,gv_cons_api)    -- 予測API
                                                      ,1
                                                      ,5000);
-- mod start ver1.18
--        FND_FILE.PUT_LINE(FND_FILE.LOG,t_forecast_interface_tab_del(ln_data_cnt).error_message);
        FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errmsg);
-- mod end ver1.18
        gn_error_cnt := gn_error_cnt + 1;
        ln_error_flg := 1;
        EXIT;
      END IF;
    END LOOP del_serch_error_loop;
    -- あらいがえ対象データの処理カウンタの初期化
    gn_del_data_cnt := 0;
-- mod end 1.11
--
-- add start 1.11
      IF (ln_error_flg = 0) THEN
-- add end 1.11
        <<forecast_proc_loop>>
        FOR ln_data_cnt IN 1..gn_target_cnt LOOP
--
          -- A-6-3 出荷数制限BForecast名抽出
          get_f_degi_seigen_b( lt_if_data,
                               ln_data_cnt,
                               lv_errbuf,
                               lv_retcode,
                               lv_errmsg );
          -- エラーがあったらループ処理中止
          IF (lv_retcode = gv_status_error) THEN
-- mod start 1.11
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
-- mod end 1.11
            gn_error_cnt := gn_error_cnt + 1;
            ln_error_flg := 1;
            EXIT;
          END IF;
  --
  /*
          -- A-6-4 出荷数制限BForecast日付抽出
          get_f_dates_seigen_b( lt_if_data,
                                ln_data_cnt,
                                ln_data_flg,
                                lv_errbuf,
                                lv_retcode,
                                lv_errmsg );
          -- エラーがあったらループ処理中止
          IF (lv_retcode = gv_status_error) THEN
            gn_error_cnt := gn_error_cnt + 1;
            ln_error_flg := 1;
            EXIT;
          END IF;
  */
  --
          -- A-6-5 出荷数制限BForecast登録
          put_forecast_seigen_b( lt_if_data,
                                 ln_data_cnt,
                                 ln_data_flg,
                                 lv_errbuf,
                                 lv_retcode,
                                 lv_errmsg );
          -- エラーがあったらループ処理中止
          IF (lv_retcode = gv_status_error) THEN
  -- mod start 1.11
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
  -- mod end 1.11
            gn_error_cnt := gn_error_cnt + 1;
            ln_error_flg := 1;
            EXIT;
          END IF;
  --
        END LOOP forecast_proc_loop;
-- add start 1.11
      END IF;
-- add end 1.11
--
-- add start 1.11
      IF (ln_error_flg = 0) THEN
        -- Forecastデータに抽出したインターフェースデータを登録
        lb_retcode := MRP_FORECAST_INTERFACE_PK.MRP_FORECAST_INTERFACE(
                                               t_forecast_interface_tab_inst,
                                               t_forecast_designator_tabl);
--
        <<serch_error_loop>>
        FOR ln_data_cnt IN 1..gn_target_cnt LOOP
          -- エラーだった場合
          IF ( t_forecast_interface_tab_inst(ln_data_cnt).process_status <> 5 ) THEN
            lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_cmn  -- 'XXCMN'
                                                          ,gv_msg_10a_045  -- APIエラー
                                                          ,gv_tkn_api_name
                                                          ,gv_cons_api)    -- 予測API
                                                          ,1
                                                          ,5000);
            FND_FILE.PUT_LINE(FND_FILE.LOG,t_forecast_interface_tab_inst(ln_data_cnt).error_message);
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
            gn_error_cnt := gn_error_cnt + 1;
            ln_error_flg := 1;
          END IF;
        END LOOP serch_error_loop;
      END IF;
--
      -- 登録対象データのレコードの初期化
      t_forecast_interface_tab_inst.delete;
      t_forecast_designator_tabl.delete;
-- add end 1.11
    END IF;
--
    -- エラーがなかった場合はコミットする
    IF (ln_error_flg = 0) THEN
      COMMIT;
    ELSE
      ROLLBACK;
    END IF;
--
    -- A-X-6共通 インターフェーステーブル削除処理
    del_if_data( lt_if_data,
                 lv_errbuf_d,
                 lv_retcode_d,
                 lv_errmsg_d );
    -- エラーがあったら処理中止
    IF (lv_retcode_d = gv_status_error) THEN
      gn_error_cnt := gn_error_cnt + 1;
      lv_errbuf    := lv_errbuf_d;
      lv_retcode   := lv_retcode_d;
      lv_errmsg    :=lv_errmsg_d;
      RAISE global_api_expt;
    END IF;
--
    -- A-6-2 出荷数制限B抽出データチェックでエラーだったらエラーリターンするために
    -- 例外を発生させる
    IF (ln_error_flg = 1) THEN
      RAISE global_api_expt;
--add start 1.9
    ELSIF (ln_warn_flg = 1) THEN
      RAISE warn_expt;
--add end 1.9
    END IF;
--
  EXCEPTION
    WHEN warn_expt THEN
--del start 1.9
--      ov_errmsg  := lv_errmsg;
--del end 1.9
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_warn;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
      gn_error_cnt := gn_error_cnt + 1;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
      gn_error_cnt := gn_error_cnt + 1;
--
--#####################################  固定部 END   ##########################################
--
  END forecast_seigen_b;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
--
  PROCEDURE submain(
    iv_forecast_designator IN  VARCHAR2,         -- Forecast区分
    iv_forecast_yyyymm     IN  VARCHAR2,         -- 年月
    iv_forecast_year       IN  VARCHAR2,         -- 年度
    iv_forecast_version    IN  VARCHAR2,         -- 世代
    iv_forecast_date       IN  VARCHAR2,         -- 開始日付
    iv_forecast_end_date   IN  VARCHAR2,         -- 終了日付
    iv_item_no             IN  VARCHAR2,         -- 品目
    iv_location_code       IN  VARCHAR2,         -- 出庫倉庫
    iv_account_number      IN  VARCHAR2,         -- 拠点
    iv_dept_code_flg       IN  VARCHAR2,         -- 取込部署抽出フラグ
    ov_errbuf              OUT NOCOPY VARCHAR2,  -- エラー・メッセージ           --# 固定 #
    ov_retcode             OUT NOCOPY VARCHAR2,  -- リターン・コード             --# 固定 #
    ov_errmsg              OUT NOCOPY VARCHAR2)  -- ユーザー・エラー・メッセージ --# 固定 #
  IS
--
--#####################  固定ローカル定数変数宣言部 START   ####################
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'submain'; -- プログラム名
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    lc_out_par    VARCHAR2(1000);   -- 入力パラメータの処理結果レポート出力用
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- グローバル変数の初期化
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    gn_warn_cnt   := 0;
--
    --*********************************************
    --***      MD.050のフロー図を表す           ***
    --***      分岐と処理部の呼び出しを行う     ***
    --*********************************************
    -- 入力パラメータの年月を保存
    gv_in_yyyymm := iv_forecast_yyyymm;
--
    -- 年度
    gv_forecast_year := iv_forecast_year;
--
    -- 世代
    gv_forecast_version := iv_forecast_version;
--
    -- 開始日付
    -- ここで変換エラーになってもスルーして後述の入力パラメータチェックでエラーにする
    gd_in_start_date := FND_DATE.STRING_TO_DATE(iv_forecast_date,'YYYY/MM/DD');
    gv_in_start_date := iv_forecast_date;
--
    -- 終了日付
    -- ここで変換エラーになってもスルーして後述の入力パラメータチェックでエラーにする
    gd_in_end_date := FND_DATE.STRING_TO_DATE(iv_forecast_end_date,'YYYY/MM/DD');
    gv_in_end_date := iv_forecast_end_date;
--
    -- 品目
    gv_in_item_code := iv_item_no;
--
    -- 出庫倉庫
    gv_in_location_code := iv_location_code;
--
    -- 拠点
    gv_in_base_code := iv_account_number;
--
    -- 取込部署抽出フラグ
    gv_in_dept_code_flg := iv_dept_code_flg;
--
    -- ===============================
    -- A-1-1 システム日付取得
    -- ===============================
    gd_sysdate_yyyymmdd := TRUNC(SYSDATE);
--
    -- ========================================================
    -- A-1-2 入力パラメータチェック
    -- 各パラメータチェックではチェックしないものでも正常を返す
    -- ========================================================
    -- A-1-2-1 Forecastチェック
    parameter_check_forecast(iv_forecast_designator,  -- Forecast区分
                             ov_errbuf,               -- エラー・メッセージ           --# 固定 #
                             ov_retcode,              -- リターン・コード             --# 固定 #
                             ov_errmsg);              -- ユーザー・エラー・メッセージ --# 固定 #
--
    -- Forecast分類を出力
    lc_out_par := gv_cons_input_forecast || gv_forecast_designator ;
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lc_out_par);
-- 2009/05/19 ADD START
    gv_forecast_type := iv_forecast_designator;
-- 2009/05/19 ADD END
--
    -- 入力パラメータを合体して出力
    lc_out_par := gv_cons_input_param  || iv_forecast_designator || gv_msg_pnt ||
                  iv_forecast_yyyymm   || gv_msg_pnt || iv_forecast_year || gv_msg_pnt ||
                  iv_forecast_version  || gv_msg_pnt || iv_forecast_date || gv_msg_pnt ||
                  iv_forecast_end_date || gv_msg_pnt || iv_item_no       || gv_msg_pnt ||
                  iv_location_code     || gv_msg_pnt || iv_account_number|| gv_msg_pnt ||
                  iv_dept_code_flg;
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lc_out_par);
--
    -- エラーならば中止
    IF (ov_retcode = gv_status_error) THEN
      gn_error_cnt := gn_error_cnt + 1;
      RAISE global_process_expt;
    END IF;
--
    -- A-1-2-2 年月チェック
    parameter_check_yyyymm(iv_forecast_designator,  -- Forecast区分
                           iv_forecast_yyyymm,      -- 年月
                           ov_errbuf,               -- エラー・メッセージ           --# 固定 #
                           ov_retcode,              -- リターン・コード             --# 固定 #
                           ov_errmsg);              -- ユーザー・エラー・メッセージ --# 固定 #
    -- エラーならば中止
    IF (ov_retcode = gv_status_error) THEN
      gn_error_cnt := gn_error_cnt + 1;
      RAISE global_process_expt;
    END IF;
--
    -- 年月なので月初日・月末日を算出して保存(BETWEENに使用できる)=チェック後なのでエラーはなし
    gd_in_yyyymmdd_start := FND_DATE.STRING_TO_DATE(gv_in_yyyymm,'yyyymm');
    gd_in_yyyymmdd_end := ADD_MONTHS(FND_DATE.STRING_TO_DATE(gv_in_yyyymm,'yyyymm'),1)-1;
    -- A-1-2-3 年度チェック
    parameter_check_forecast_year(iv_forecast_designator, -- Forecast区分
                                  iv_forecast_year,       -- 年度
                                  ov_errbuf,              -- エラー・メッセージ        --# 固定 #
                                  ov_retcode,             -- リターン・コード          --# 固定 #
                                  ov_errmsg);             -- ユーザー・エラー・メッセージ--# 固定 #
    -- エラーならば中止
    IF (ov_retcode = gv_status_error) THEN
      gn_error_cnt := gn_error_cnt + 1;
      RAISE global_process_expt;
    END IF;
--
    -- A-1-2-4 世代チェック
    parameter_check_version(iv_forecast_designator,  -- Forecast区分
                            iv_forecast_version,     -- 世代
                            ov_errbuf,               -- エラー・メッセージ           --# 固定 #
                            ov_retcode,              -- リターン・コード             --# 固定 #
                            ov_errmsg);              -- ユーザー・エラー・メッセージ --# 固定 #
    -- エラーならば中止
    IF (ov_retcode = gv_status_error) THEN
      gn_error_cnt := gn_error_cnt + 1;
      RAISE global_process_expt;
    END IF;
--
    -- A-1-2-5 開始日付・終了日付チェック
    parameter_check_forecast_date(iv_forecast_designator, -- Forecast区分
                                  iv_forecast_date,       -- 開始日付
                                  iv_forecast_end_date,   -- 終了日付
                                  ov_errbuf,              -- エラー・メッセージ        --# 固定 #
                                  ov_retcode,             -- リターン・コード          --# 固定 #
                                  ov_errmsg);             -- ユーザー・エラー・メッセージ--# 固定 #
    -- エラーならば中止
    IF (ov_retcode = gv_status_error) THEN
      gn_error_cnt := gn_error_cnt + 1;
      RAISE global_process_expt;
    END IF;
--
    -- A-1-2-6 品目チェック
    parameter_check_item_no(iv_forecast_designator,  -- Forecast区分
                            iv_item_no,              -- 品目
                            ov_errbuf,               -- エラー・メッセージ           --# 固定 #
                            ov_retcode,              -- リターン・コード             --# 固定 #
                            ov_errmsg);              -- ユーザー・エラー・メッセージ --# 固定 #
    -- エラーならば中止
    IF (ov_retcode = gv_status_error) THEN
      gn_error_cnt := gn_error_cnt + 1;
      RAISE global_process_expt;
    END IF;
--
    -- A-1-2-7 出庫倉庫チェック
    parameter_check_subinventory(iv_forecast_designator, -- Forecast区分
                                 iv_location_code,       -- 出庫倉庫
                                 ov_errbuf,              -- エラー・メッセージ        --# 固定 #
                                 ov_retcode,             -- リターン・コード          --# 固定 #
                                 ov_errmsg);             -- ユーザー・エラー・メッセージ --# 固定 #
    -- エラーならば中止
    IF (ov_retcode = gv_status_error) THEN
      gn_error_cnt := gn_error_cnt + 1;
      RAISE global_process_expt;
    END IF;
--
    -- A-1-2-8 拠点チェック
    parameter_check_account_number(iv_forecast_designator,-- Forecast区分
                                   iv_account_number,     -- 拠点
                                   ov_errbuf,             -- エラー・メッセージ        --# 固定 #
                                   ov_retcode,            -- リターン・コード          --# 固定 #
                                   ov_errmsg);            -- ユーザー・エラー・メッセージ--# 固定 #
    -- エラーならば中止
    IF (ov_retcode = gv_status_error) THEN
      gn_error_cnt := gn_error_cnt + 1;
      RAISE global_process_expt;
    END IF;
--
    -- A-1-2-9 取込部署チェック
    parameter_check_dept_code(iv_forecast_designator,  -- Forecast区分
                              iv_dept_code_flg,        -- 取込部署抽出フラグ
                              ov_errbuf,               -- エラー・メッセージ           --# 固定 #
                              ov_retcode,              -- リターン・コード             --# 固定 #
                              ov_errmsg);              -- ユーザー・エラー・メッセージ --# 固定 #
    -- エラーならば中止
    IF (ov_retcode = gv_status_error) THEN
      gn_error_cnt := gn_error_cnt + 1;
      RAISE global_process_expt;
    END IF;
--
    -- =======================================
    -- A-1-3 プロファイル・オプション値の取得
    -- =======================================
    get_profile_start_day(ov_errbuf,               -- エラー・メッセージ           --# 固定 #
                          ov_retcode,              -- リターン・コード             --# 固定 #
                          ov_errmsg);              -- ユーザー・エラー・メッセージ --# 固定 #
    -- エラーならば中止
    IF (ov_retcode = gv_status_error) THEN
      gn_error_cnt := gn_error_cnt + 1;
      RAISE global_process_expt;
    END IF;
--
    -- ===========================================
    -- A-1-4 対象年度開始日・対象年度終了日の取得
    -- ===========================================
    -- 販売計画のみ実行される
    IF (iv_forecast_designator = gv_cons_fc_type_hanbai) THEN
      get_start_end_day(iv_forecast_year,     -- 年度(入力パラメータ)
                        ov_errbuf,            -- エラー・メッセージ           --# 固定 #
                        ov_retcode,           -- リターン・コード             --# 固定 #
                        ov_errmsg);           -- ユーザー・エラー・メッセージ --# 固定 #
      -- エラーならば中止
      IF (ov_retcode = gv_status_error) THEN
        gn_error_cnt := gn_error_cnt + 1;
        RAISE global_process_expt;
      END IF;
    END IF;
--
    -- ===============================
    -- A-1-5 開始日付・終了日付の取得
    -- ===============================
    get_keikaku_start_end_day(ov_errbuf,            -- エラー・メッセージ           --# 固定 #
                              ov_retcode,           -- リターン・コード             --# 固定 #
                              ov_errmsg);           -- ユーザー・エラー・メッセージ --# 固定 #
    -- エラーならば中止
    IF (ov_retcode = gv_status_error) THEN
      gn_error_cnt := gn_error_cnt + 1;
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- A-1-6 部署情報の取得
    -- ===============================
    get_dept_inf(ov_errbuf,            -- エラー・メッセージ           --# 固定 #
                 ov_retcode,           -- リターン・コード             --# 固定 #
                 ov_errmsg);           -- ユーザー・エラー・メッセージ --# 固定 #
    -- エラーならば中止
    IF (ov_retcode = gv_status_error) THEN
      gn_error_cnt := gn_error_cnt + 1;
      RAISE global_process_expt;
    END IF;
--
    -- ===============================================
    -- Forecast分類による振分処理
    -- ===============================================
    IF (iv_forecast_designator = gv_cons_fc_type_hikitori) THEN
      -- 引取計画
      forecast_hikitori(ov_errbuf,            -- エラー・メッセージ           --# 固定 #
                        ov_retcode,           -- リターン・コード             --# 固定 #
                        ov_errmsg);           -- ユーザー・エラー・メッセージ --# 固定 #
      -- エラーならば中止
      IF (ov_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      ELSIF (ov_retcode = gv_status_warn) THEN
        RAISE warn_expt;
      END IF;
    ELSIF (iv_forecast_designator = gv_cons_fc_type_keikaku) THEN
      -- 計画商品
      forecast_keikaku(ov_errbuf,            -- エラー・メッセージ           --# 固定 #
                       ov_retcode,           -- リターン・コード             --# 固定 #
                       ov_errmsg);           -- ユーザー・エラー・メッセージ --# 固定 #
      -- エラーならば中止
      IF (ov_retcode = gv_status_error) THEN
        RAISE global_process_expt;
--add start 1.9
      ELSIF (ov_retcode = gv_status_warn) THEN
        RAISE warn_expt;
--add end 1.9
      END IF;
    ELSIF (iv_forecast_designator = gv_cons_fc_type_seigen_a) THEN
      -- 出荷数制限A
      forecast_seigen_a(ov_errbuf,            -- エラー・メッセージ           --# 固定 #
                        ov_retcode,           -- リターン・コード             --# 固定 #
                        ov_errmsg);           -- ユーザー・エラー・メッセージ --# 固定 #
      -- エラーならば中止
      IF (ov_retcode = gv_status_error) THEN
        RAISE global_process_expt;
--add start 1.9
      ELSIF (ov_retcode = gv_status_warn) THEN
        RAISE warn_expt;
--add end 1.9
      END IF;
    ELSIF (iv_forecast_designator = gv_cons_fc_type_seigen_b) THEN
      -- 出荷数制限B
      forecast_seigen_b(ov_errbuf,            -- エラー・メッセージ           --# 固定 #
                        ov_retcode,           -- リターン・コード             --# 固定 #
                        ov_errmsg);           -- ユーザー・エラー・メッセージ --# 固定 #
      -- エラーならば中止
      IF (ov_retcode = gv_status_error) THEN
        RAISE global_process_expt;
--add start 1.9
      ELSIF (ov_retcode = gv_status_warn) THEN
        RAISE warn_expt;
--add end 1.9
      END IF;
    ELSIF (iv_forecast_designator = gv_cons_fc_type_hanbai) THEN
      -- 販売計画
      forecast_hanbai(ov_errbuf,            -- エラー・メッセージ           --# 固定 #
                      ov_retcode,           -- リターン・コード             --# 固定 #
                      ov_errmsg);           -- ユーザー・エラー・メッセージ --# 固定 #
      -- エラーならば中止
      IF (ov_retcode = gv_status_error) THEN
        RAISE global_process_expt;
--add start 1.9
      ELSIF (ov_retcode = gv_status_warn) THEN
        RAISE warn_expt;
--add end 1.9
      END IF;
    END IF;
--
  EXCEPTION
      -- *** 任意で例外処理を記述する ****
    WHEN warn_expt THEN
--del start 1.9
--      ov_errmsg  := lv_errmsg;
--del end 1.9
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_warn;
--
--#################################  固定例外処理部 START   ###################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
--del start 1.7
--      ov_errmsg  := lv_errmsg;
--del end 1.7
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||ov_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
      gn_error_cnt := gn_error_cnt + 1;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
      gn_error_cnt := gn_error_cnt + 1;
--
--####################################  固定部 END   ##########################################
--
  END submain;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : コンカレント実行ファイル登録プロシージャ
   **********************************************************************************/
--
  PROCEDURE main(
    errbuf                 OUT NOCOPY VARCHAR2,  -- エラー・メッセージ  --# 固定 #
    retcode                OUT NOCOPY VARCHAR2,  -- リターン・コード    --# 固定 #
    iv_forecast_designator IN  VARCHAR2,         -- Forecast区分
    iv_forecast_yyyymm     IN  VARCHAR2,         -- 年月('YYYYMM')
    iv_forecast_year       IN  VARCHAR2,         -- 年度('YYYY')
    iv_forecast_version    IN  VARCHAR2,         -- 世代
    iv_forecast_date       IN  VARCHAR2,         -- 開始日付('YYYYMMDD')
    iv_forecast_end_date   IN  VARCHAR2,         -- 終了日付('YYYYMMDD')
    iv_item_no             IN  VARCHAR2,         -- 品目
    iv_location_code       IN  VARCHAR2,         -- 出庫倉庫
    iv_account_number      IN  VARCHAR2,         -- 拠点
    iv_dept_code           IN  VARCHAR2)         -- 取込部署
IS
--
--###########################  固定ローカル定数変数宣言部 START   ###########################
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'main';  -- プログラム名
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--#####################################  固定部 END   #######################################
--
  BEGIN
--
--#########################  固定ステータス初期化部 START  ########################################
--
    -- ======================
    -- 固定出力用変数セット
    -- ======================
    --実行ユーザ名取得
    gv_exec_user := FND_GLOBAL.USER_NAME;
    -- 商品区分取得
    gv_item_div := SUBSTR(FND_PROFILE.VALUE(gv_prf_item_div),1,10);
    -- 品目区分取得
    gv_article_div := SUBSTR(FND_PROFILE.VALUE(gv_prf_article_div),1,10);
--
    --実行コンカレント名取得
    SELECT  fcp.concurrent_program_name
    INTO    gv_conc_name
    FROM    fnd_concurrent_programs fcp
    WHERE   fcp.application_id        = FND_GLOBAL.PROG_APPL_ID
      AND   fcp.concurrent_program_id = FND_GLOBAL.CONC_PROGRAM_ID
      AND   ROWNUM                    = 1;
--
    -- ======================
    -- 固定出力
    -- ======================
    --実行ユーザ名出力
    gv_out_msg := xxcmn_common_pkg.get_msg(gv_msg_kbn_cmn, gv_msg_10a_001, gv_tkn_user,
                                           gv_exec_user);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --実行コンカレント名出力
    gv_out_msg := xxcmn_common_pkg.get_msg(gv_msg_kbn_cmn, gv_msg_10a_002, gv_tkn_conc,
                                           gv_conc_name);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --起動時間出力
    gv_out_msg := xxcmn_common_pkg.get_msg(gv_msg_kbn_cmn, gv_msg_10a_046,
                                           gv_tkn_time, TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS'));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_out_msg);
--
    --区切り文字出力
    gv_sep_msg := xxcmn_common_pkg.get_msg(gv_msg_kbn_cmn, gv_msg_10a_003);
--
--###########################  固定部 END   #######################################################
--
    -- グローバル変数の初期化
    gn_target_cnt := 0;   -- 対象件数
    gn_normal_cnt := 0;   -- 正常件数
    gn_warn_cnt   := 0;   -- 警告件数
    gn_error_cnt  := 0;   -- エラー件数
--
    -- ログインID、ユーザIDの取得
    gn_login_user := FND_GLOBAL.LOGIN_ID;
    gn_created_by := FND_GLOBAL.USER_ID;
--
-- 2008/08/01 Add ↓
-- WHOカラムセット
    gn_last_updated_by         := FND_GLOBAL.USER_ID;
    gn_request_id              := FND_GLOBAL.CONC_REQUEST_ID;
    gn_program_application_id  := FND_GLOBAL.QUEUE_APPL_ID;
    gn_program_id              := FND_GLOBAL.CONC_PROGRAM_ID;
    gd_who_sysdate             := SYSDATE;
-- 2008/08/01 Add ↑
--
    -- ===============================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ===============================================
    submain(iv_forecast_designator, -- Forecast区分
            iv_forecast_yyyymm,     -- 年月('YYYYMM')
            iv_forecast_year,       -- 年度('YYYY')
            iv_forecast_version,    -- 世代
            iv_forecast_date,       -- 開始日付('YYYYMMDD')
            iv_forecast_end_date,   -- 終了日付('YYYYMMDD')
            iv_item_no,             -- 品目
            iv_location_code,       -- 出庫倉庫
            iv_account_number,      -- 拠点
            iv_dept_code,           -- 取込部署
            lv_errbuf,              -- エラー・メッセージ           --# 固定 #
            lv_retcode,             -- リターン・コード             --# 固定 #
            lv_errmsg);             -- ユーザー・エラー・メッセージ --# 固定 #
--
--###########################  固定部 START   #####################################################
--
    -- ======================
    -- エラー・メッセージ出力
    -- ======================
    IF ((lv_retcode = gv_status_error) OR (lv_retcode = gv_status_warn)) THEN
      IF (lv_errmsg IS NULL) THEN
        --定型メッセージ・セット
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_cmn, gv_msg_10a_047);
      END IF;
      IF ( gn_no_msg_disp = 0 ) THEN
        FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf);
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      END IF;
    END IF;
--
    -- ==================================
    -- リターン・コードのセット、終了処理
    -- ==================================
    --区切り文字列出力
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_sep_msg);
--
    --処理件数出力
    IF (gn_error_cnt > 0) THEN
      gn_normal_cnt := 0;
-- 2008/11/07 Y.Kawano Del Start
----add start 1.5
--      gn_error_cnt := gn_target_cnt;
----add end 1.5
-- 2008/11/07 Y.Kawano Del End
    ELSE
      gn_normal_cnt := gn_target_cnt;
--add start 1.5
      gn_error_cnt := 0;
--add end 1.5
    END IF;
    gv_out_msg := xxcmn_common_pkg.get_msg(gv_msg_kbn_cmn, gv_msg_10a_007, gv_tkn_cnt,
                                           TO_CHAR(gn_target_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --成功件数出力
    gv_out_msg := xxcmn_common_pkg.get_msg(gv_msg_kbn_cmn, gv_msg_10a_008, gv_tkn_cnt,
                                           TO_CHAR(gn_normal_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --エラー件数出力
    gv_out_msg := xxcmn_common_pkg.get_msg(gv_msg_kbn_cmn, gv_msg_10a_009, gv_tkn_cnt,
                                           TO_CHAR(gn_error_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --スキップ件数出力
    gv_out_msg := xxcmn_common_pkg.get_msg(gv_msg_kbn_cmn, gv_msg_10a_010, gv_tkn_cnt,
                                           TO_CHAR(gn_warn_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --ステータス出力
    SELECT flv.meaning
    INTO   gv_conc_status
    FROM   fnd_lookup_values flv
    WHERE  flv.language              = userenv('LANG')
      AND    flv.view_application_id = 0
      AND    flv.security_group_id   = FND_GLOBAL.LOOKUP_SECURITY_GROUP(flv.lookup_type,
                                                                        flv.view_application_id)
      AND    flv.lookup_type         = 'CP_STATUS_CODE'
      AND    flv.lookup_code         = DECODE(lv_retcode,
                                              gv_status_normal,gv_sts_cd_normal,
                                              gv_status_warn,gv_sts_cd_warn,
                                              gv_sts_cd_error)
      AND    ROWNUM                  = 1;
--
    --処理ステータス出力
    gv_out_msg := xxcmn_common_pkg.get_msg(gv_msg_kbn_cmn,
                                           gv_msg_10a_011,
                                           gv_tkn_status,
                                           gv_conc_status);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --ステータスセット
    retcode := lv_retcode;
--
  EXCEPTION
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      retcode := gv_status_error;
      FND_FILE.PUT_LINE(FND_FILE.LOG,errbuf);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,errbuf);
  END main;
--
--###########################  固定部 END   #######################################################
--
END XXINV100001C;
/
