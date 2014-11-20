CREATE OR REPLACE PACKAGE BODY APPS.XXCSO016A05C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCSO016A05C(bosy)
 * Description      : 物件情報(自販機情報)データを情報系システムへ連携するためのＣＳＶファイルを作成します。
 *
 * MD.050           : MD050_CSO_016_A05_情報系-EBSインターフェース：(OUT)什器マスタ
 *
 * Version          : 1.19
 *
 * Program List
 * ---------------------------- ----------------------------------------------------------
 *  Name                        Description
 * ---------------------------- ----------------------------------------------------------
 *  init                        初期処理 (A-1)
 *  get_profile_info            プロファイル値取得 (A-2)
 *  open_csv_file               CSVファイルオープン (A-3)
 *  get_csv_data                CSVファイルに出力する関連情報取得 (A-6)
 *  create_csv_rec              什器マスタデータCSV出力 (A-7)
 *  close_csv_file              CSVファイルクローズ処理 (A-8)
 *  submain                     メイン処理プロシージャ
 *                                物件データ抽出処理 (A-4)
 *  main                        コンカレント実行ファイル登録プロシージャ
 *                                  終了処理 (A-9)
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009-01-05    1.0   Syoei.Kin        新規作成
 *  2009-02-20    1.1   K.Sai            レビュー後対応
 *  2009-03-11    1.1   M.Maruyama       物件マスタ項目追加(先月末設置先顧客コード・先月末
 *                                       機器状態・先月末年月)による変更対応
 *                                         先月末顧客コード・先月末拠点(部門)コード導出追加
 *                                         顧客コード・拠点(部門)コード取得方法変更
 *                                           プロファイルオプション引揚拠点コード取得処理削除
 *                                         滞留開始日導出条件変更
 *                                         日付書式チェックメッセージ変更
 *  2009-03-11    1.1   M.Maruyama       【不具合対応054】物件マスタ関連情報取得時に
 *                                       機器状態2(滞留)かつインスタンスタイプ1(自販機)の
 *                                       場合の取得拠点コードの間違いを修正
 *  2009-03-27    1.2   N.Yabuki         【ST障害管理T1_0191_T1_0192_T1_0193_T1_0194】
 *                                        (※障害管理番号、障害内容は障害管理番号採番後に記入)
 *  2009-04-08    1.3   K.Satomura       ＳＴ障害対応(T1_0365)
 *  2009-04-15    1.4   M.Maruyama       ＳＴ障害対応(T1_0550) メインカーソルのWHERE句を修正
 *  2009-05-01    1.5   Tomoko.Mori      T1_0897対応
 *  2009-05-18    1.6   K.Satomura       ＳＴ障害対応(T1_1049)
 *  2009-05-25    1.7   M.Maruyama       ＳＴ障害対応(T1_1154)
 *  2009-06-09    1.8   K.Hosoi          ＳＴ障害対応(T1_1154) 再修正
 *  2009-07-09    1.9   K.Hosoi          SCS障害管理番号(0000518) 対応
 *  2009-07-21    1.10  K.Hosoi          SCS障害管理番号(0000475) 対応
 *  2009-08-06    1.11  K.Satomura       SCS障害管理番号(0000935) 対応
 *  2009-09-03    1.12  M.Maruyama       SCS障害管理番号(0001192) 対応
 *  2009-11-27    1.13  K.Satomura       E_本稼動_00118対応
 *  2009-12-09    1.14  T.Maruyama       E_本稼動_00117対応
 *  2010-02-26    1.15  K.Hosoi          E_本稼動_01568対応
 *  2010-03-17    1.16  K.Hosoi          E_本稼動_01881対応
 *  2010-04-21    1.17  T.Maruyama       E_本稼動_02391対応 INSTANCE_NUMBERはEBSで7桁以上となるため固定値をセット
 *  2010-05-19    1.18  T.Maruyama       E_本稼動_02787対応 先月末拠点CDの導出項目を売上拠点から前月売上拠点へ変更
 *  2011-10-14    1.19  T.Yoshimoto      E_本稼動_05929対応 書式・桁数チェックを追加
 *****************************************************************************************/
--
--#######################  固定グローバル定数宣言部 START   #######################
--
  --ステータス・コード
  cv_status_normal          CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal; --正常:0
  cv_status_warn            CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_warn;   --警告:1
  cv_status_error           CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;  --異常:2
  --WHOカラム
  cn_created_by             CONSTANT NUMBER      := fnd_global.user_id;         --CREATED_BY
  cd_creation_date          CONSTANT DATE        := SYSDATE;                    --CREATION_DATE
  cn_last_updated_by        CONSTANT NUMBER      := fnd_global.user_id;         --LAST_UPDATED_BY
  cd_last_update_date       CONSTANT DATE        := SYSDATE;                    --LAST_UPDATE_DATE
  cn_last_update_login      CONSTANT NUMBER      := fnd_global.login_id;        --LAST_UPDATE_LOGIN
  cn_request_id             CONSTANT NUMBER      := fnd_global.conc_request_id; --REQUEST_ID
  cn_program_application_id CONSTANT NUMBER      := fnd_global.prog_appl_id;    --PROGRAM_APPLICATION_ID
  cn_program_id             CONSTANT NUMBER      := fnd_global.conc_program_id; --PROGRAM_ID
  cd_program_update_date    CONSTANT DATE        := SYSDATE;                    --PROGRAM_UPDATE_DATE
--
  cv_msg_part               CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont               CONSTANT VARCHAR2(3) := '.';
--
--################################  固定部 END   ##################################
--
--#######################  固定グローバル変数宣言部 START   #######################
--
  gv_out_msg                VARCHAR2(2000);
  gn_target_cnt             NUMBER;                    -- 対象件数
  gn_normal_cnt             NUMBER;                    -- 正常件数
  gn_error_cnt              NUMBER;                    -- エラー件数
-- 2011/10/14 v1.19 T.Yoshimto Add Start E_本稼動_05929(コメントアウト解除)
  gn_skip_cnt               NUMBER;                    -- スキップ件数
-- 2011/10/14 v1.19 T.Yoshimto Add End E_本稼動_05929
  gv_company_cd             VARCHAR2(2000);            -- 会社コード(固定値001)
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
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name            CONSTANT VARCHAR2(100) := 'XXCSO016A05C';  -- パッケージ名
  cv_app_name            CONSTANT VARCHAR2(10)  := 'XXCSO';         -- アプリケーション短縮名
  cv_appl_short_name     CONSTANT VARCHAR2(10)  := 'XXCCP';         -- アドオン：共通・IF領域
--
  cv_active_status       CONSTANT VARCHAR2(1)   := 'A';             -- アクティブ
  cv_houmon_kbn_taget    CONSTANT VARCHAR2(1)   := '1';             -- 訪問対象区分（訪問対象：1）
  cv_source_obj_type_cd  CONSTANT VARCHAR2(10)  := 'PARTY';         -- ソースオブジェクトタイプコード
  cv_delete_flg          CONSTANT VARCHAR2(10)  := 'N';             -- 削除フラグ
  cn_job_kbn             CONSTANT NUMBER        := 5;               -- 作業テーブルの作業区分(引揚:5)
/*20090327_yabuki_T1_0193 START*/
  cn_job_kbn_new_replace CONSTANT NUMBER        := 3;               -- 作業テーブルの作業区分(新台代替:3)
  cn_job_kbn_old_replace CONSTANT NUMBER        := 4;               -- 作業テーブルの作業区分(旧台代替:4)
/*20090327_yabuki_T1_0193 END*/
  cn_completion_kbn      CONSTANT NUMBER        := 1;               -- 作業テーブルの完了区分(完了:1)
  cv_category_kbn        CONSTANT VARCHAR2(10)  := '50';            -- 発注依頼明細情報ビューの引揚情報(引揚情報:50)
/*20090327_yabuki_T1_0193 START*/
  cv_category_kbn_new_rplc  CONSTANT VARCHAR2(10)  := '20';            -- 発注依頼明細情報ビューの新台代替情報(新台代替情報:20)
  cv_category_kbn_old_rplc  CONSTANT VARCHAR2(10)  := '40';            -- 発注依頼明細情報ビューの旧台代替情報(旧台代替情報:40)
/*20090327_yabuki_T1_0193 END*/
/* 2009.06.09 K.Hosoi T1_1154(再修正) 対応 START */
  cv_withdrawal_type_1   CONSTANT VARCHAR2(10)  := '1:引揚';        -- 発注依頼明細情報ビューの引揚(引揚:1)
  cv_withdrawal_type_2   CONSTANT VARCHAR2(10)  := '2:一時引揚';    -- 発注依頼明細情報ビューの引揚(一時引揚:2)
/* 2009.06.09 K.Hosoi T1_1154(再修正) 対応 END */
  cv_instance_status     CONSTANT VARCHAR2(50)  := 'XXCSO1_INSTANCE_STATUS';  -- クイックコードのルックアップタイプ
  cv_enabled_flag        CONSTANT VARCHAR2(50)  := 'Y';             -- クイックコードの有効フラグ
  cv_jotai_kbn1_1        CONSTANT VARCHAR2(1)   := '1';             -- 機器状態１（1:稼働中）
  cv_jotai_kbn1_2        CONSTANT VARCHAR2(2)   := '2';             -- 機器状態１（2:滞留）
  cv_jotai_kbn1_3        CONSTANT VARCHAR2(2)   := '3';             -- 機器状態１（3:廃棄済）
  cv_instance_type_cd_1  CONSTANT VARCHAR2(1)   := '1';             -- インスタンスタイプが「1:自動販売機」
  cv_lease_kbn_1         CONSTANT VARCHAR2(1)   := '1';             -- リース区分「1:自社リース」
  cv_lease_kbn_2         CONSTANT VARCHAR2(1)   := '2';             -- リース区分「2:お客様リース」
/* 2009.04.08 K.Satomura T1_0365対応 START */
  cv_flag_yes            CONSTANT VARCHAR2(1)   := 'Y';
/* 2009.04.08 K.Satomura T1_0365対応 END */
-- 2011/10/14 v1.19 T.Yoshimto Add Start E_本稼動_05929
  cv_comma               CONSTANT VARCHAR2(2)   := '、';            -- カンマ
-- 2011/10/14 v1.19 T.Yoshimto Add End E_本稼動_05929
--
  -- メッセージコード
  cv_tkn_number_01    CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90008';     -- コンカレント入力パラメータなし
  cv_tkn_number_02    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00014';     -- プロファイル取得エラー
  cv_tkn_number_03    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00123';     -- CSVファイル残存エラー
  cv_tkn_number_04    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00015';     -- CSVファイルオープンエラー
  cv_tkn_number_05    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00016';     -- データ抽出エラー
  cv_tkn_number_06    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00492';     -- クイックコード抽出エラー
  cv_tkn_number_07    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00279';     -- 顧客アドオンマスタデータ抽出警告
  cv_tkn_number_08    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00280';     -- 国連番号マスタデータ抽出警告
  cv_tkn_number_09    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00281';     -- リース契約データ抽出警告
  /* 2009.05.25 M.Maruyama T1_1154対応 START */
  -- cv_tkn_number_10    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00282';     -- 作業データテーブルデータ抽出警告
  cv_tkn_number_10    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00564';     -- 抽出エラー
  /* 2009.05.25 M.Maruyama T1_1154対応 END */
  cv_tkn_number_11    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00283';     -- CSVファイル出力エラー
  cv_tkn_number_12    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00224';     -- CSVファイル出力0件エラー
  cv_tkn_number_13    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00018';     -- CSVファイルクローズエラー
  cv_tkn_number_14    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00152';     -- インターフェースファイル名
  cv_tkn_number_15    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00029';     -- 日付書式チェック
  cv_tkn_number_16    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00011';     -- 業務処理日付取得エラー
  /* 2009.04.09 K.Satomura T1_0441対応 START */
  cv_tkn_number_17    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00560';     -- 値未設定メッセージ
  /* 2009.04.09 K.Satomura T1_0441対応 END */
  /* 2009.06.09 K.Hosoi T1_1154(再修正) 対応 START */
  cv_tkn_number_18    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00104';     -- 値未設定メッセージ
  /* 2009.06.09 K.Hosoi T1_1154(再修正) 対応 END */
  /* 2009.11.27 K.Satomura E_本稼動_00118対応 START */
  cv_tkn_number_19    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00581';
  /* 2009.11.27 K.Satomura E_本稼動_00118対応 END */
-- 2011/10/14 v1.19 T.Yoshimto Add Start E_本稼動_05929
  cv_tkn_number_20    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00616';     -- CSV出力エラー
-- 2011/10/14 v1.19 T.Yoshimto Add End E_本稼動_05929
--
  -- トークンコード
  cv_tkn_err_msg         CONSTANT VARCHAR2(20) := 'ERR_MSG';            -- SQLエラーメッセージ
  cv_tkn_err_msg2        CONSTANT VARCHAR2(20) := 'ERR_MESSAGE';        -- SQLエラーメッセージ2
  cv_tkn_prof_name       CONSTANT VARCHAR2(20) := 'PROF_NAME';          -- プロファイル名
  cv_tkn_csv_location    CONSTANT VARCHAR2(20) := 'CSV_LOCATION';       -- CSVファイル出力先
  cv_tkn_csv_file_name   CONSTANT VARCHAR2(20) := 'CSV_FILE_NAME';      -- CSVファイル名
  cv_tkn_proc_name       CONSTANT VARCHAR2(20) := 'PROCESSING_NAME';    -- 抽出処理名
  cv_tkn_object_cd       CONSTANT VARCHAR2(20) := 'OBJECT_CD';          -- 外部参照(物件コード)
  cv_tkn_account_id      CONSTANT VARCHAR2(20) := 'ACCOUNT_ID';         -- 所有者アカウントID
  cv_tkn_location_cd     CONSTANT VARCHAR2(20) := 'LOCATION_CD';        -- 拠点コード
  cv_tkn_customer_cd     CONSTANT VARCHAR2(20) := 'CUSTOMER_CD';        -- 顧客コード
  cv_tkn_un_number       CONSTANT VARCHAR2(20) := 'UN_NUMBER';          -- 機種コード
  cv_tkn_maker_cd        CONSTANT VARCHAR2(20) := 'MAKER_CD';           -- メーカーコード
  cv_tkn_special1        CONSTANT VARCHAR2(20) := 'SPECIAL1';           -- 特殊機区分1
  cv_tkn_special2        CONSTANT VARCHAR2(20) := 'SPECIAL2';           -- 特殊機区分2
  cv_tkn_special3        CONSTANT VARCHAR2(20) := 'SPECIAL3';           -- 特殊機区分3
  cv_tkn_column          CONSTANT VARCHAR2(20) := 'COLUMN';             -- コラム数
  cv_tkn_lease_kbn       CONSTANT VARCHAR2(20) := 'LEASE_KBN';          -- リース区分
  cv_tkn_lease_price     CONSTANT VARCHAR2(20) := 'LEASE_PRICE';        -- リース料
  cv_tkn_work_date       CONSTANT VARCHAR2(20) := 'WORK_DATE';          -- 実作業日
  cv_tkn_count           CONSTANT VARCHAR2(20) := 'COUNT';              -- 処理件数
  cv_tkn_status_id       CONSTANT VARCHAR2(20) := 'STATUS_ID';          -- ステータスID
  cv_tkn_item            CONSTANT VARCHAR2(20) := 'ITEM';               -- 項目名
  cv_tkn_value           CONSTANT VARCHAR2(20) := 'BASE_VALUE';         -- 値
  /* 2009.05.25 M.Maruyama T1_1154対応 START */
  cv_tkn_tsk_nm          CONSTANT VARCHAR2(20) := 'TASK_NAME';          -- 値
  cv_tkn_vl              CONSTANT VARCHAR2(20) := 'VALUE';              -- 値
  /* 2009.05.25 M.Maruyama T1_1154対応 END */
  /* 2009.06.09 K.Hosoi T1_1154(再修正) 対応 START */
  cv_tkn_bukken          CONSTANT VARCHAR2(20) := 'BUKKEN';             -- 値
  /* 2009.06.09 K.Hosoi T1_1154(再修正) 対応 END */
  /* 2009.11.27 K.Satomura E_本稼動_00118対応 START */
  cv_tkn_param           CONSTANT VARCHAR2(20) := 'PARAM';
  /* 2009.11.27 K.Satomura E_本稼動_00118対応 END */
-- 2011/10/14 v1.19 T.Yoshimto Add Start E_本稼動_05929
  cv_tkn_message         CONSTANT VARCHAR2(20) := 'message';            -- メッセージ
-- 2011/10/14 v1.19 T.Yoshimto Add End E_本稼動_05929
--
  cb_true                CONSTANT BOOLEAN := TRUE;
  cb_false               CONSTANT BOOLEAN := FALSE;
--
  -- DEBUG_LOG用メッセージ
  cv_debug_msg1           CONSTANT VARCHAR2(200) := '<< システム日付取得処理 >>';
  cv_debug_msg2           CONSTANT VARCHAR2(200) := 'lv_sysdate          = ';
  cv_debug_msg3           CONSTANT VARCHAR2(200) := '<< プロファイル値取得処理 >>';
  cv_debug_msg4           CONSTANT VARCHAR2(200) := 'lv_file_dir         = ';
  cv_debug_msg5           CONSTANT VARCHAR2(200) := 'lv_file_name        = ';
  cv_debug_msg6           CONSTANT VARCHAR2(200) := 'lv_company_cd       = ';
  cv_debug_msg9           CONSTANT VARCHAR2(200) := '<< CSVファイルをオープンしました >>' ;
  cv_debug_msg10          CONSTANT VARCHAR2(200) := '<< CSVファイルをクローズしました >>' ;
  cv_debug_msg11          CONSTANT VARCHAR2(200) := '<< ロールバックしました >>' ;
  cv_debug_msg12          CONSTANT VARCHAR2(200) := '<< ステータスのコード抽出処理 >>' ;
  cv_debug_msg13          CONSTANT VARCHAR2(200) := 'ステータス          = ';
  cv_debug_msg14          CONSTANT VARCHAR2(200) := '<< 拠点コード、顧客コード抽出処理 >>' ;
  cv_debug_msg15          CONSTANT VARCHAR2(200) := '拠点(部門)コード    = ';
  cv_debug_msg16          CONSTANT VARCHAR2(200) := '顧客コード          = ';
  cv_debug_msg17          CONSTANT VARCHAR2(200) := '<< 製造メーカー、特殊機区分、コラム数抽出処理 >>' ;
  cv_debug_msg18          CONSTANT VARCHAR2(200) := '製造メーカー        = ';
  cv_debug_msg19          CONSTANT VARCHAR2(200) := '特殊機区分1         = ';
  cv_debug_msg20          CONSTANT VARCHAR2(200) := '特殊機区分2         = ';
  cv_debug_msg21          CONSTANT VARCHAR2(200) := '特殊機区分3         = ';
  cv_debug_msg22          CONSTANT VARCHAR2(200) := 'コラム数            = ';
  cv_debug_msg23          CONSTANT VARCHAR2(200) := '<< リース区分、リース料抽出処理 >>' ;
  cv_debug_msg24          CONSTANT VARCHAR2(200) := '再リース区分        = ';
  cv_debug_msg25          CONSTANT VARCHAR2(200) := 'リース料            = ';
  cv_debug_msg26          CONSTANT VARCHAR2(200) := '<< 滞留開始日、拠点(部門)抽出処理 >>' ;
  cv_debug_msg27          CONSTANT VARCHAR2(200) := '滞留開始日          = ';
  cv_debug_msg28          CONSTANT VARCHAR2(200) := '拠点(部門)          = ';
  cv_debug_msg29          CONSTANT VARCHAR2(200) := '<< 拠点(部門)抽出処理 >>' ;
  cv_debug_msg30          CONSTANT VARCHAR2(200) := '拠点(部門)          = ';
  cv_debug_msg31          CONSTANT VARCHAR2(200) := '<< 業務処理年月取得処理 >>';
  cv_debug_msg32          CONSTANT VARCHAR2(200) := '業務処理年月        = ';
  /*20090709_hosoi_0000518 START*/
  cv_debug_msg33          CONSTANT VARCHAR2(200) := 'lv_attribute_level  = ';
  /*20090709_hosoi_0000518 END*/
--
  cv_debug_msg_fnm        CONSTANT VARCHAR2(200) := 'filename = ';
  cv_debug_msg_fcls       CONSTANT VARCHAR2(200) := '<< 例外処理内でCSVファイルをクローズしました >>';
  cv_debug_msg_copn       CONSTANT VARCHAR2(200) := '<< カーソルをオープンしました >>';
  cv_debug_msg_ccls1      CONSTANT VARCHAR2(200) := '<< カーソルをクローズしました >>';
  cv_debug_msg_ccls2      CONSTANT VARCHAR2(200) := '<< 例外処理内でカーソルをクローズしました >>';
  cv_debug_msg_err1       CONSTANT VARCHAR2(200) := 'file_err_expt';
  cv_debug_msg_err2       CONSTANT VARCHAR2(200) := 'global_api_expt';
  cv_debug_msg_err3       CONSTANT VARCHAR2(200) := 'global_api_others_expt';
  cv_debug_msg_err4       CONSTANT VARCHAR2(200) := 'others例外';
  cv_debug_msg_err5       CONSTANT VARCHAR2(200) := 'no_data_expt';
  cv_debug_msg_err6       CONSTANT VARCHAR2(200) := 'global_process_expt';
--
-- 2011/10/14 v1.19 T.Yoshimto Add Start E_本稼動_05929
  cv_kiban_ja                CONSTANT VARCHAR2(100) := '機番';                     --  機番(DFF2)
  cv_count_no_ja             CONSTANT VARCHAR2(100) := 'カウンターNo';             --  カウンターNo
  cv_chiku_cd_ja             CONSTANT VARCHAR2(100) := '地区コード';               --  地区コード
  cv_sagyougaisya_cd_ja      CONSTANT VARCHAR2(100) := '作業会社コード';           --  作業会社コード
  cv_jigyousyo_cd_ja         CONSTANT VARCHAR2(100) := '事業所コード';             --  事業所コード
  cv_den_no_ja               CONSTANT VARCHAR2(100) := '最終作業伝票No';           --  最終作業伝票No
  cv_job_kbn_ja              CONSTANT VARCHAR2(100) := '最終作業区分';             --  最終作業区分
  cv_sintyoku_kbn_ja         CONSTANT VARCHAR2(100) := '最終作業進捗';             --  最終作業進捗
  cv_yotei_dt_ja             CONSTANT VARCHAR2(100) := '最終作業完了予定日';       --  最終作業完了予定日
  cv_kanryo_dt_ja            CONSTANT VARCHAR2(100) := '最終作業完了日';           --  最終作業完了日
  cv_sagyo_level_ja          CONSTANT VARCHAR2(100) := '最終整備内容';             --  最終整備内容
  cv_den_no2_ja              CONSTANT VARCHAR2(100) := '最終設置伝票No';           --  最終設置伝票No
  cv_job_kbn2_ja             CONSTANT VARCHAR2(100) := '最終設置区分';             --  最終設置区分
  cv_sintyoku_kbn2_ja        CONSTANT VARCHAR2(100) := '最終設置進捗';             --  最終設置進捗
  cv_jotai_kbn1_ja           CONSTANT VARCHAR2(100) := '機器状態1';                --  機器状態1（稼動状態）
  cv_jotai_kbn2_ja           CONSTANT VARCHAR2(100) := '機器状態2';                --  機器状態2（状態詳細）
  cv_jotai_kbn3_ja           CONSTANT VARCHAR2(100) := '機器状態3';                --  機器状態3（廃棄情報）
  cv_nyuko_dt_ja             CONSTANT VARCHAR2(100) := '入庫日';                   --  入庫日
  cv_hikisakigaisya_cd_ja    CONSTANT VARCHAR2(100) := '引揚会社コード';           --  引揚会社コード
  cv_hikisakijigyosyo_cd_ja  CONSTANT VARCHAR2(100) := '引揚事業所コード';         --  引揚事業所コード
  cv_setti_tanto_ja          CONSTANT VARCHAR2(100) := '設置先担当者名';           --  設置先担当者名
  cv_setti_tel1_ja           CONSTANT VARCHAR2(100) := '設置先TEL1';               --  設置先TEL1
  cv_setti_tel2_ja           CONSTANT VARCHAR2(100) := '設置先TEL2';               --  設置先TEL2
  cv_setti_tel3_ja           CONSTANT VARCHAR2(100) := '設置先TEL3';               --  設置先TEL3
  cv_haikikessai_dt_ja       CONSTANT VARCHAR2(100) := '廃棄決裁日';               --  廃棄決裁日
  cv_tenhai_tanto_ja         CONSTANT VARCHAR2(100) := '転売廃棄業者';             --  転売廃棄業者
  cv_tenhai_den_no_ja        CONSTANT VARCHAR2(100) := '転売廃棄伝票No';           --  転売廃棄伝票No
  cv_syoyu_cd_ja             CONSTANT VARCHAR2(100) := '所有者';                   --  所有者
  cv_tenhai_flg_ja           CONSTANT VARCHAR2(100) := '転売廃棄状況フラグ';       --  転売廃棄状況フラグ
  cv_kanryo_kbn_ja           CONSTANT VARCHAR2(100) := '転売完了区分';             --  転売完了区分
  cv_sakujo_flg_ja           CONSTANT VARCHAR2(100) := '削除フラグ';               --  削除フラグ
  cv_ven_kyaku_last_ja       CONSTANT VARCHAR2(100) := '最終顧客コード';           --  最終顧客コード
  cv_ven_tasya_cd01_ja       CONSTANT VARCHAR2(100) := '他社コード1';              --  他社コード１
  cv_ven_tasya_daisu01_ja    CONSTANT VARCHAR2(100) := '他社台数1';                --  他社台数１
  cv_ven_tasya_cd02_ja       CONSTANT VARCHAR2(100) := '他社コード2';              --  他社コード２
  cv_ven_tasya_daisu02_ja    CONSTANT VARCHAR2(100) := '他社台数2';                --  他社台数２
  cv_ven_tasya_cd03_ja       CONSTANT VARCHAR2(100) := '他社コード3';              --  他社コード３
  cv_ven_tasya_daisu03_ja    CONSTANT VARCHAR2(100) := '他社台数3';                --  他社台数３
  cv_ven_tasya_cd04_ja       CONSTANT VARCHAR2(100) := '他社コード4';              --  他社コード４
  cv_ven_tasya_daisu04_ja    CONSTANT VARCHAR2(100) := '他社台数4';                --  他社台数４
  cv_ven_tasya_cd05_ja       CONSTANT VARCHAR2(100) := '他社コード5';              --  他社コード５
  cv_ven_tasya_daisu05_ja    CONSTANT VARCHAR2(100) := '他社台数5';                --  他社台数５
  cv_ven_haiki_flg_ja        CONSTANT VARCHAR2(100) := '廃棄フラグ';               --  廃棄フラグ
  cv_ven_sisan_kbn_ja        CONSTANT VARCHAR2(100) := '資産区分';                 --  資産区分
  cv_ven_kobai_ymd_ja        CONSTANT VARCHAR2(100) := '購買日付';                 --  購買日付
  cv_ven_kobai_kg_ja         CONSTANT VARCHAR2(100) := '購買金額';                 --  購買金額
  cv_safty_level_ja          CONSTANT VARCHAR2(100) := '安全設置基準';             --  安全設置基準
  cv_lease_kbn_ja            CONSTANT VARCHAR2(100) := 'リース区分';               --  リース区分
  cv_last_inst_cust_code_ja  CONSTANT VARCHAR2(100) := '先月末設置先顧客コード';   --  先月末設置先顧客コード                            
-- 2011/10/14 v1.19 T.Yoshimto Add End E_本稼動_05929
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  -- ファイル・ハンドルの宣言
  gf_file_hand    UTL_FILE.FILE_TYPE;
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  -- 什器マスタ情報データ
    TYPE g_value_rtype IS RECORD(
      company_cd                VARCHAR2(100)                                    -- 会社コード
     ,install_code              xxcso_install_base_v.install_code%TYPE           -- 外部参照
     ,instance_type_code        xxcso_install_base_v.instance_type_code%TYPE     -- インスタンスタイプ
     ,lookup_code               fnd_lookup_values_vl.lookup_code%TYPE            -- ステータス
     ,install_date              xxcso_install_base_v.install_date%TYPE           -- 導入日
     ,instance_number           xxcso_install_base_v.instance_number%TYPE        -- インスタンス番号
     ,quantity                  xxcso_install_base_v.quantity%TYPE               -- 数量
     ,accounting_class_code     xxcso_install_base_v.accounting_class_code%TYPE  -- 会計分類
     ,active_start_date         xxcso_install_base_v.active_start_date%TYPE      -- 開始日
     ,inventory_item_id         xxcso_install_base_v.inventory_item_id%TYPE      -- 品名コード
     ,install_party_id          xxcso_install_base_v.install_party_id%TYPE       -- 使用者パーティID
     ,install_account_id        xxcso_install_base_v.install_account_id%TYPE     -- 使用者アカウントID
     ,vendor_model              xxcso_install_base_v.vendor_model%TYPE           -- 機種(DFF1)
     ,vendor_number             xxcso_install_base_v.vendor_number%TYPE          -- 機番(DFF2)
     ,first_install_date        xxcso_install_base_v.first_install_date%TYPE     -- 初回設置日(DFF3)
     ,op_request_flag           xxcso_install_base_v.op_request_flag%TYPE        -- 作業依頼中フラグ(DFF4)
     ,ven_kyaku_last            xxcso_install_base_v.ven_kyaku_last%TYPE         -- 最終顧客コード
     ,ven_tasya_cd01            xxcso_install_base_v.ven_tasya_cd01%TYPE         -- 他社コード１
     ,ven_tasya_daisu01         xxcso_install_base_v.ven_tasya_daisu01%TYPE      -- 他社台数１
     ,ven_tasya_cd02            xxcso_install_base_v.ven_tasya_cd02%TYPE         -- 他社コード２
     ,ven_tasya_daisu02         xxcso_install_base_v.ven_tasya_daisu02%TYPE      -- 他社台数２
     ,ven_tasya_cd03            xxcso_install_base_v.ven_tasya_cd03%TYPE         -- 他社コード３
     ,ven_tasya_daisu03         xxcso_install_base_v.ven_tasya_daisu03%TYPE      -- 他社台数３
     ,ven_tasya_cd04            xxcso_install_base_v.ven_tasya_cd04%TYPE         -- 他社コード４
     ,ven_tasya_daisu04         xxcso_install_base_v.ven_tasya_daisu04%TYPE      -- 他社台数４
     ,ven_tasya_cd05            xxcso_install_base_v.ven_tasya_cd05%TYPE         -- 他社コード５
     ,ven_tasya_daisu05         xxcso_install_base_v.ven_tasya_daisu05%TYPE      -- 他社台数５
     ,ven_haiki_flg             xxcso_install_base_v.ven_haiki_flg%TYPE          -- 廃棄フラグ
     ,haikikessai_dt            xxcso_install_base_v.haikikessai_dt%TYPE         -- 廃棄決裁日
     ,ven_sisan_kbn             xxcso_install_base_v.ven_sisan_kbn%TYPE          -- 資産区分
     ,ven_kobai_ymd             xxcso_install_base_v.ven_kobai_ymd%TYPE          -- 購買日付
     ,ven_kobai_kg              xxcso_install_base_v.ven_kobai_kg%TYPE           -- 購買金額
     ,count_no                  xxcso_install_base_v.count_no%TYPE               -- カウンターNo.
     ,chiku_cd                  xxcso_install_base_v.chiku_cd%TYPE               -- 地区コード
     ,sagyougaisya_cd           xxcso_install_base_v.sagyougaisya_cd%TYPE        -- 作業会社コード
     ,jigyousyo_cd              xxcso_install_base_v.jigyousyo_cd%TYPE           -- 事業所コード
     ,den_no                    xxcso_install_base_v.den_no%TYPE                 -- 最終作業伝票No.
     ,job_kbn                   xxcso_install_base_v.job_kbn%TYPE                -- 最終作業区分
     ,sintyoku_kbn              xxcso_install_base_v.sintyoku_kbn%TYPE           -- 最終作業進捗
     ,yotei_dt                  xxcso_install_base_v.yotei_dt%TYPE               -- 最終作業完了予定日
     ,kanryo_dt                 xxcso_install_base_v.kanryo_dt%TYPE              -- 最終作業完了日
     ,sagyo_level               xxcso_install_base_v.sagyo_level%TYPE            -- 最終整備内容
     ,den_no2                   xxcso_install_base_v.den_no2%TYPE                -- 最終設置伝票No.
     ,job_kbn2                  xxcso_install_base_v.job_kbn2%TYPE               -- 最終設置区分
     ,sintyoku_kbn2             xxcso_install_base_v.sintyoku_kbn2%TYPE          -- 最終設置進捗
     ,jotai_kbn1                xxcso_install_base_v.jotai_kbn1%TYPE             -- 機器状態1（稼動状態）
     ,jotai_kbn2                xxcso_install_base_v.jotai_kbn2%TYPE             -- 機器状態2（状態詳細）
     ,jotai_kbn3                xxcso_install_base_v.jotai_kbn3%TYPE             -- 機器状態3（廃棄情報）
     ,nyuko_dt                  xxcso_install_base_v.nyuko_dt%TYPE               -- 入庫日
     ,hikisakigaisya_cd         xxcso_install_base_v.hikisakigaisya_cd%TYPE      -- 引揚会社コード
     ,hikisakijigyosyo_cd       xxcso_install_base_v.hikisakijigyosyo_cd%TYPE    -- 引揚事業所コード
     ,setti_tanto               xxcso_install_base_v.setti_tanto%TYPE            -- 設置先担当者名
     ,setti_tel1                xxcso_install_base_v.setti_tel1%TYPE             -- 設置先TEL(連結)１
     ,setti_tel2                xxcso_install_base_v.setti_tel2%TYPE             -- 設置先TEL(連結)２
     ,setti_tel3                xxcso_install_base_v.setti_tel3%TYPE             -- 設置先TEL(連結)３
     ,tenhai_tanto              xxcso_install_base_v.tenhai_tanto%TYPE           -- 転売廃棄業者
     ,tenhai_den_no             xxcso_install_base_v.tenhai_den_no%TYPE          -- 転売廃棄伝票№
     ,syoyu_cd                  xxcso_install_base_v.syoyu_cd%TYPE               -- 所有者
     ,tenhai_flg                xxcso_install_base_v.tenhai_flg%TYPE             -- 転売廃棄状況フラグ
     ,kanryo_kbn                xxcso_install_base_v.kanryo_kbn%TYPE             -- 転売完了区分
     ,sakujo_flg                xxcso_install_base_v.sakujo_flg%TYPE             -- 削除フラグ
     ,safty_level               xxcso_install_base_v.safty_level%TYPE            -- 安全設置基準
     ,lease_kbn                 xxcso_install_base_v.lease_kbn%TYPE              -- リース区分
     ,base_code                 VARCHAR2(100)                                    -- 拠点(部門)コード
     ,account_number            xxcso_cust_accounts_v.account_number%TYPE        -- 顧客コード
     ,attribute2                po_un_numbers_vl.attribute2%TYPE                 -- 製造メーカー
     ,attribute9                po_un_numbers_vl.attribute9%TYPE                 -- 特殊機区分１
     ,attribute10               po_un_numbers_vl.attribute10%TYPE                -- 特殊機区分２
     ,attribute11               po_un_numbers_vl.attribute11%TYPE                -- 特殊機区分３
     ,lease_type                xxcff_contract_headers.lease_type%TYPE           -- 再リース区分
     ,second_charge             xxcff_contract_lines.second_charge%TYPE          -- リース料 月額リース料(税抜)
     ,attribute8                po_un_numbers_vl.attribute8%TYPE                 -- コラム数
     ,actual_work_date          xxcso_in_work_data.actual_work_date%TYPE         -- 滞留開始日
     ,last_inst_cust_code       xxcso_install_base_v.last_inst_cust_code%TYPE    -- 先月末顧客コード
     ,last_jotai_kbn            xxcso_install_base_v.last_jotai_kbn%TYPE         -- 先月末機器状態
     ,last_year_month           xxcso_install_base_v.last_year_month%TYPE        -- 先月末年月
     ,last_month_base_cd        VARCHAR2(1000)                                   -- 先月末拠点(部門)コード
     ,new_old_flag              xxcso_install_base_v.new_old_flag%TYPE           -- 新古台フラグ
     ,sysdate_now               VARCHAR2(100)                                    -- 連携日時
     ,instance_status_id        xxcso_install_base_v.instance_status_id%TYPE     -- ステータスID
    );
  --*** データ登録、更新例外 ***
  global_ins_upd_expt    EXCEPTION;
--
  PRAGMA EXCEPTION_INIT(global_ins_upd_expt,-30000);
--
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理 (A-1)
   ***********************************************************************************/
  PROCEDURE init(
    ov_sysdate          OUT NOCOPY VARCHAR2,  -- システム日付
    od_bsnss_mnth       OUT NOCOPY VARCHAR2,  -- 業務処理月
    ov_errbuf           OUT NOCOPY VARCHAR2,  -- エラー・メッセージ            --# 固定 #
    ov_retcode          OUT NOCOPY VARCHAR2,  -- リターン・コード              --# 固定 #
    ov_errmsg           OUT NOCOPY VARCHAR2   -- ユーザー・エラー・メッセージ  --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'init';             -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル変数 ***
    lv_sysdate           VARCHAR2(100);    -- システム日付
    lv_init_msg          VARCHAR2(5000);   -- エラーメッセージを格納
    lv_bsnss_mnth        VARCHAR2(10);             -- 業務処理月を格納
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- システム日付取得
    lv_sysdate := TO_CHAR(SYSDATE,'YYYYMMDDHH24MISS');
    -- 取得したシステム日付をログ出力
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => cv_debug_msg1  || CHR(10) ||
                 cv_debug_msg2  || lv_sysdate || CHR(10) ||
                 ''
    );
    -- 入力パラメータなしメッセージ出力
    lv_init_msg   := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name    --アプリケーション短縮名
                      ,iv_name         => cv_tkn_number_01      --メッセージコード
                     );
    --メッセージ出力
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => ''           || CHR(10) ||   -- 空行の挿入
                 lv_init_msg  || CHR(10) ||
                 ''                           -- 空行の挿入
    );
--
    -- 業務処理月取得
    lv_bsnss_mnth := TO_CHAR(xxcso_util_common_pkg.get_online_sysdate,'YYYYMM');
--
   -- 業務処理月取得に失敗した場合
    IF (lv_bsnss_mnth IS NULL) THEN
      -- 空行の挿入
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => ''
      );
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name                  --アプリケーション短縮名
                    ,iv_name         => cv_tkn_number_16             --メッセージコード
                   );
      lv_errbuf := lv_errmsg || SQLERRM;
      RAISE global_api_expt;
    ELSE
      -- 取得した業務処理月をログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg31  || CHR(10) ||
                   cv_debug_msg32  || lv_bsnss_mnth || CHR(10) ||
                   ''
      );
    END IF;
--
    -- 取得したシステム日付・業務処理月をOUTパラメータに設定
    ov_sysdate := lv_sysdate;
    od_bsnss_mnth := TO_DATE(lv_bsnss_mnth,'YYYYMM');
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END init;
--
  /**********************************************************************************
   * Procedure Name   : get_profile_info
   * Description      : プロファイル値を取得 (A-2)
   ***********************************************************************************/
  PROCEDURE get_profile_info(
    ov_file_dir             OUT NOCOPY VARCHAR2,        -- CSVファイル出力先
    ov_file_name            OUT NOCOPY VARCHAR2,        -- CSVファイル名
    ov_company_cd           OUT NOCOPY VARCHAR2,        -- 会社コード(固定値001)
    /*20090709_hosoi_0000518 START*/
    ov_attribute_level      OUT NOCOPY VARCHAR2,        -- IB拡張属性テンプレートアクセスレベル
    /*20090709_hosoi_0000518 END*/
    ov_errbuf               OUT NOCOPY VARCHAR2,        -- エラー・メッセージ           --# 固定 #
    ov_retcode              OUT NOCOPY VARCHAR2,        -- リターン・コード             --# 固定 #
    ov_errmsg               OUT NOCOPY VARCHAR2         -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name         CONSTANT VARCHAR2(100)  := 'get_profile_info';            -- プログラム名
--
    cv_tkn_csv_name     CONSTANT VARCHAR2(100)  := 'CSV_FILE_NAME';
      -- インターフェースファイル名トークン名
    cv_file_dir         CONSTANT VARCHAR2(100)  := 'XXCSO1_INFO_OUT_CSV_DIR';     -- CSVファイル出力先
    cv_file_name        CONSTANT VARCHAR2(100)  := 'XXCSO1_INFO_OUT_CSV_IB';      -- CSVファイル名
    cv_company_cd       CONSTANT VARCHAR2(100)  := 'XXCSO1_INFO_OUT_COMPANY_CD';  -- 会社コード(固定値001)
    /*20090709_hosoi_0000518 START*/
    cv_attribute_level  CONSTANT VARCHAR2(30)   := 'XXCSO1_IB_ATTRIBUTE_LEVEL';   -- IB拡張属性テンプレートアクセスレベル
    /*20090709_hosoi_0000518 END*/
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
    -- *** ローカル変数 ***
    lv_file_dir       VARCHAR2(2000);             -- CSVファイル出力先
    lv_file_name      VARCHAR2(2000);             -- CSVファイル名
    lv_company_cd     VARCHAR2(2000);             -- 会社コード(固定値001)
    lv_msg_set        VARCHAR2(1000);             -- メッセージ格納
    /*20090709_hosoi_0000518 START*/
    lv_attribute_level  VARCHAR2(15);
    /*20090709_hosoi_0000518 END*/
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ===============================
    -- プロファイル値を取得
    -- ===============================
--
    -- CSVファイル出力先の値取得
    FND_PROFILE.GET(
                  cv_file_dir
                 ,lv_file_dir
    );
    -- CSVファイル名の値取得
    FND_PROFILE.GET(
                  cv_file_name
                 ,lv_file_name
    );
    -- 会社コードの値取得
    FND_PROFILE.GET(
                  cv_company_cd
                 ,lv_company_cd
    );
    /*20090709_hosoi_0000518 START*/
    -- IB拡張属性テンプレートアクセスレベル
    FND_PROFILE.GET(
                  cv_attribute_level
                 ,lv_attribute_level
    );
    /*20090709_hosoi_0000518 END*/
    -- *** DEBUG_LOG ***
    -- 取得したプロファイル値をログ出力
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => cv_debug_msg3 || CHR(10) ||
                 cv_debug_msg4 || lv_file_dir    || CHR(10) ||
                 cv_debug_msg5 || lv_file_name   || CHR(10) ||
                 cv_debug_msg6 || lv_company_cd  || CHR(10) ||
                 /*20090709_hosoi_0000518 START*/
                 cv_debug_msg33|| lv_attribute_level || CHR(10) ||
                 /*20090709_hosoi_0000518 EMD*/
                 ''
    );
    --インターフェースファイル名メッセージ出力
    lv_msg_set := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name
                    ,iv_name         => cv_tkn_number_14
                    ,iv_token_name1  => cv_tkn_csv_name
                    ,iv_token_value1 => lv_file_name
                   );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_msg_set ||CHR(10) ||
                 ''                           -- 空行の挿入
    );
    -- 戻り値が「NULL」であった場合,例外処理を行う
    -- CSVファイル出力先
    IF (lv_file_dir IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_app_name              -- アプリケーション短縮名
                        ,iv_name         => cv_tkn_number_02         -- メッセージコード
                        ,iv_token_name1  => cv_tkn_prof_name         -- トークンコード1
                        ,iv_token_value1 => cv_file_dir              -- トークン値1CSVファイル出力先
      );
      lv_errbuf  := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    -- CSVファイル名
    IF (lv_file_name IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_app_name              -- アプリケーション短縮名
                        ,iv_name         => cv_tkn_number_02         -- メッセージコード
                        ,iv_token_name1  => cv_tkn_prof_name         -- トークンコード1
                        ,iv_token_value1 => cv_file_name             -- トークン値1CSVファイル名
      );
      lv_errbuf  := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    -- 会社コード(固定値001)
    IF (lv_company_cd IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_app_name              -- アプリケーション短縮名
                        ,iv_name         => cv_tkn_number_02         -- メッセージコード
                        ,iv_token_name1  => cv_tkn_prof_name         -- トークンコード1
                        ,iv_token_value1 => cv_company_cd            -- トークン値1会社コード(固定値001)
      );
      lv_errbuf  := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    -- 取得した値をOUTパラメータに設定
    ov_file_dir   := lv_file_dir;       -- CSVファイル出力先
    ov_file_name  := lv_file_name;      -- CSVファイル名
    ov_company_cd := lv_company_cd;     -- 会社コード(固定値001)
    /*20090709_hosoi_0000518 START*/
    ov_attribute_level := lv_attribute_level;  -- IB拡張属性テンプレートアクセスレベル
    /*20090709_hosoi_0000518 END*/
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_profile_info;
--
  /**********************************************************************************
   * Procedure Name   : open_csv_file
   * Description      : CSVファイルオープン (A-3)
   ***********************************************************************************/
  PROCEDURE open_csv_file(
    iv_file_dir             IN  VARCHAR2,               -- CSVファイル出力先
    iv_file_name            IN  VARCHAR2,               -- CSVファイル名
    ov_errbuf               OUT NOCOPY VARCHAR2,        -- エラー・メッセージ           --# 固定 #
    ov_retcode              OUT NOCOPY VARCHAR2,        -- リターン・コード             --# 固定 #
    ov_errmsg               OUT NOCOPY VARCHAR2         -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)  := 'open_csv_file';     -- プログラム名
--
    cv_open_writer          CONSTANT VARCHAR2(100)  := 'W';                 -- 入出力モード

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
    -- *** ローカル変数 ***
    lv_file_dir       VARCHAR2(1000);      -- CSVファイル出力先
    lv_file_name      VARCHAR2(1000);      -- CSVファイル名
    lv_exists         BOOLEAN;             -- 存在チェック結果
    lv_file_length    VARCHAR2(1000);      -- ファイルサイズ
    lv_blocksize      VARCHAR2(1000);      -- ブロックサイズ
    -- ファイルオープン確認戻り値格納
    lb_fopn_retcd   BOOLEAN;
    -- *** ローカル例外 ***
    file_err_expt   EXCEPTION;  -- ファイル処理例外
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- INパラメータをローカル変数に代入
    lv_file_dir   := iv_file_dir;       -- CSVファイル出力先
    lv_file_name  := iv_file_name;      -- CSVファイル名
    -- ========================
    -- CSVファイル存在チェック
    -- ========================
    UTL_FILE.FGETATTR(
                  location    => lv_file_dir
                 ,filename    => lv_file_name
                 ,fexists     => lv_exists
                 ,file_length => lv_file_length
                 ,block_size  => lv_blocksize
    );
    --CSVファイルが存在した場合
    IF (lv_exists = cb_true) THEN
      -- CSVファイル残存エラーメッセージ取得
      lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_app_name              -- アプリケーション短縮名
                        ,iv_name         => cv_tkn_number_03         -- メッセージコード
                        ,iv_token_name1  => cv_tkn_csv_location      -- トークンコード1
                        ,iv_token_value1 => lv_file_dir              -- トークン値1CSVファイル出力先
                        ,iv_token_name2  => cv_tkn_csv_file_name     -- トークンコード1
                        ,iv_token_value2 => lv_file_name             -- トークン値1CSVファイル名
      );
      lv_errbuf := lv_errmsg;
      RAISE file_err_expt;
    ELSIF (lv_exists = cb_false) THEN
      -- ========================
      -- CSVファイルオープン
      -- ========================
      BEGIN
  --
        -- ファイルIDを取得
        gf_file_hand := UTL_FILE.FOPEN(
                             location   => lv_file_dir
                            ,filename   => lv_file_name
                            ,open_mode  => cv_open_writer
          );
        -- *** DEBUG_LOG ***
        -- ファイルオープンしたことをログ出力
        fnd_file.put_line(
           which  => FND_FILE.LOG
          ,buff   => cv_debug_msg9    || CHR(10)   ||
                     cv_debug_msg_fnm || lv_file_name || CHR(10) ||
                     ''
        );
        EXCEPTION
          WHEN UTL_FILE.INVALID_PATH       OR       -- ファイルパス不正エラー
               UTL_FILE.INVALID_MODE       OR       -- open_modeパラメータ不正エラー
               UTL_FILE.INVALID_OPERATION  OR       -- オープン不可能エラー
               UTL_FILE.INVALID_MAXLINESIZE  THEN   -- MAX_LINESIZE値無効エラー
            -- CSVファイルオープンエラーメッセージ取得
            lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_app_name              -- アプリケーション短縮名
                          ,iv_name         => cv_tkn_number_04         -- メッセージコード
                          ,iv_token_name1  => cv_tkn_csv_location      -- トークンコード1
                          ,iv_token_value1 => lv_file_dir              -- トークン値1CSVファイル出力先
                          ,iv_token_name2  => cv_tkn_csv_file_name     -- トークンコード1
                          ,iv_token_value2 => lv_file_name             -- トークン値1CSVファイル名
            );
            lv_errbuf := lv_errmsg;
            RAISE file_err_expt;
      END;
    END IF;
--
    EXCEPTION
    -- *** ファイル処理例外ハンドラ ***
    WHEN file_err_expt THEN
      lb_fopn_retcd := UTL_FILE.IS_OPEN (
                         file =>gf_file_hand
                       );
      -- ファイルがクローズされていない場合
      IF (lb_fopn_retcd = cb_true) THEN
        -- ファイルクローズ
        UTL_FILE.FCLOSE(
          file => gf_file_hand
        );
--
      -- *** DEBUG_LOG ***
      -- ファイルクローズしたことをログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_fcls || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err1 || cv_msg_part ||
                   cv_debug_msg_fnm  || iv_file_name   || CHR(10) ||
                   ''
      );
      END IF;
--
      -- 取得した値をOUTパラメータに設定
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      lb_fopn_retcd := UTL_FILE.IS_OPEN (
                         file =>gf_file_hand
                       );
      -- ファイルがクローズされていない場合
      IF (lb_fopn_retcd = cb_true) THEN
        -- ファイルクローズ
        UTL_FILE.FCLOSE(
          file =>gf_file_hand
        );
--
      -- *** DEBUG_LOG ***
      -- ファイルクローズしたことをログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_fcls || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err2 || cv_msg_part ||
                   cv_debug_msg_fnm  || iv_file_name   || CHR(10) ||
                   ''
      );
      END IF;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      lb_fopn_retcd := UTL_FILE.IS_OPEN (
                         file =>gf_file_hand
                       );
      -- ファイルがクローズされていない場合
      IF (lb_fopn_retcd = cb_true) THEN
        -- ファイルクローズ
        UTL_FILE.FCLOSE(
          file =>gf_file_hand
        );
--
      -- *** DEBUG_LOG ***
      -- ファイルクローズしたことをログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_fcls || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err3 || cv_msg_part ||
                   cv_debug_msg_fnm  || iv_file_name   || CHR(10) ||
                   ''
      );
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      lb_fopn_retcd := UTL_FILE.IS_OPEN (
                         file =>gf_file_hand
                       );
      -- ファイルがクローズされていない場合
      IF (lb_fopn_retcd = cb_true) THEN
        -- ファイルクローズ
        UTL_FILE.FCLOSE(
          file =>gf_file_hand
        );
--
      -- *** DEBUG_LOG ***
      -- ファイルクローズしたことをログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_fcls || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err4 || cv_msg_part ||
                   cv_debug_msg_fnm  || iv_file_name   || CHR(10) ||
                   ''
      );
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END open_csv_file;
--
--
  /**********************************************************************************
   * Procedure Name   : get_csv_data
   * Description      : CSVファイルに出力する関連情報取得 (A-6)
   ***********************************************************************************/
  PROCEDURE get_csv_data(
    io_get_rec      IN  OUT NOCOPY g_value_rtype,      -- 情報データ
    id_bsnss_mnth   IN  DATE,                          -- 業務日付
    ov_errbuf       OUT NOCOPY VARCHAR2,               -- エラー・メッセージ           --# 固定 #
    ov_retcode      OUT NOCOPY VARCHAR2,               -- リターン・コード             --# 固定 #
    ov_errmsg       OUT NOCOPY VARCHAR2                -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name                CONSTANT VARCHAR2(100)  := 'get_csv_data';       -- プログラム名
    cv_sep_com                 CONSTANT VARCHAR2(3)    := ',';
    cv_sep_wquot               CONSTANT VARCHAR2(3)    := '"';
    --
    cv_quick_cd                CONSTANT VARCHAR2(100)  := 'クイックコード';
    cv_base_account_cd         CONSTANT VARCHAR2(100)  := '顧客マスタビュー';
    cv_lst_bs_ccnt_cd          CONSTANT VARCHAR2(100)  := '顧客マスタビュー(前月分)';
    cv_po_un_number_vl         CONSTANT VARCHAR2(100)  := '国連番号マスタビュー';
    cv_contract_headers        CONSTANT VARCHAR2(100)  := 'リース契約データ';
    cv_work_data               CONSTANT VARCHAR2(100)  := '作業データテーブル';
    /* 2009.05.25 M.Maruyama T1_1154対応 START */
    /* 2009.04.09 K.Satomura T1_0441対応 START */
    cv_actual_work_date        CONSTANT VARCHAR2(100)  := '作業データテーブルの実作業日(滞留開始日)';
    /* 2009.04.09 K.Satomura T1_0441対応 END */
    cv_clm_nm                  CONSTANT VARCHAR2(100)  := '物件コード';
    /* 2009.05.25 M.Maruyama T1_1154対応 END */
    /* 2009.06.09 K.Hosoi T1_1154(再修正) 対応 START */
    cv_actual_work_date_2      CONSTANT VARCHAR2(100)  := '作業データテーブルの実作業日(滞留開始日)が';
    /* 2009.06.09 K.Hosoi T1_1154(再修正) 対応 END */
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--_
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cn_mnth_shft          CONSTANT NUMBER       := -1;        -- 先月業務月取得用基準値
    cv_yr_mnth_frmt       CONSTANT VARCHAR2(6)  := 'YYYYMM';  -- 年月フォーマット
    /* 2009.11.27 K.Satomura E_本稼動_00118対応 START */
    cv_lookup_code        CONSTANT fnd_lookup_values_vl.lookup_code%TYPE := '9';
    cv_tkn_val1           CONSTANT VARCHAR2(100) := 'インスタンスステータス';
    cv_tkn_val2           CONSTANT VARCHAR2(100) := '機種コード';
    cv_tkn_val3           CONSTANT VARCHAR2(100) := '先月末顧客コード';
    /* 2009.11.27 K.Satomura E_本稼動_00118対応 END */
    /* 2010.02.26 K.Hosoi E_本稼動_01568 START */
    cv_ls_tp_no_cntrct          CONSTANT VARCHAR2(1)   := '9';      -- 設置可能契約無し
    cv_obj_sts_contracted       CONSTANT VARCHAR2(3)   := '102';    -- 契約済
    cv_obj_sts_re_lease_cntrctd CONSTANT VARCHAR2(3)   := '104';    -- 再リース契約済
    cv_obj_sts_uncontract       CONSTANT VARCHAR2(3)   := '101';    -- 未契約
    cv_obj_sts_lease_wait       CONSTANT VARCHAR2(3)   := '103';    -- 再リース待
    /* 2010.02.26 K.Hosoi E_本稼動_01568 END */
    -- *** ローカル変数 ***
    ld_bsnss_mnth         DATE;
    lv_lookup_code        VARCHAR2(100);      -- ステータス
    lv_sale_base_code     VARCHAR2(100);      -- 拠点(部門)コード
    lv_account_number     VARCHAR2(100);      -- 顧客コード
    lv_lst_accnt_num      VARCHAR2(100);      -- 先月末顧客コード
    lv_install_code       VARCHAR2(100);      -- 物件コード
    lv_attribute2         VARCHAR2(150);      -- メーカーコード
    lv_attribute9         VARCHAR2(150);      -- 特殊機区分1
    lv_attribute10        VARCHAR2(150);      -- 特殊機区分2
    lv_attribute11        VARCHAR2(150);      -- 特殊機区分3
    lv_attribute8         VARCHAR2(150);      -- コラム数
    lv_lease_type         VARCHAR2(100);      -- 再リース区分
    ln_second_charge      NUMBER;             -- リース料 月額リース料(税抜)
    lv_company_cd         VARCHAR2(2000);     -- 会社コード(固定値001)
    lv_base_code          VARCHAR2(2000);     -- 拠点(部門)コード
    lv_last_month_base_cd VARCHAR2(2000);     -- 先月末拠点(部門)コード
    ln_actual_work_date   NUMBER;             -- 滞留開始日
    ld_sysdate            DATE;               -- システム日付
    /* 2010.02.26 K.Hosoi E_本稼動_01568 START */
    lt_object_status      xxcff_object_headers.object_status%TYPE; -- 物件ステータス
    /* 2010.02.26 K.Hosoi E_本稼動_01568 END */
    /* 2009.06.09 K.Hosoi T1_1154(再修正) 対応 START */
    ln_target_cnt         NUMBER;             -- カーソル抽出件数格納
     /* 2010.05.19 T.Maruyama E_本稼動_02787対応 START */
    lt_past_sale_base_code xxcmm_cust_accounts.past_sale_base_code%TYPE; --前月売上拠点CD
     /* 2010.05.19 T.Maruyama E_本稼動_02787対応 END */ 
    -- *** ローカル・カーソル ***
    CURSOR get_act_wk_dt_cur(
             it_instll_cd IN xxcso_install_base_v.install_code%TYPE
           )
    IS
      SELECT xiw.actual_work_date  actual_work_date -- 滞留開始日
            ,xrl.category_kbn      category_kbn     -- カテゴリ区分
            ,xiw.job_kbn           job_kbn          -- 作業区分
            ,xrl.withdrawal_type   withdrawal_type  -- 引揚区分
      FROM   xxcso_in_work_data        xiw -- 作業データテーブル
            ,po_requisition_headers    prh -- 発注依頼ヘッダビュー
            ,xxcso_requisition_lines_v xrl -- 発注依頼明細情報ビュー
      WHERE  xiw.install2_processed_flag = cv_flag_yes
        AND  xiw.install_code2           = it_instll_cd
        AND  xiw.completion_kbn          = cn_completion_kbn
        AND  TO_CHAR(xiw.po_req_number)  = prh.segment1
        AND  prh.requisition_header_id   = xrl.requisition_header_id
        AND  xiw.line_num                = xrl.line_num
        AND  (
               (
                     xrl.category_kbn    = cv_category_kbn
                 AND xiw.job_kbn         = cn_job_kbn
                 AND ( 
                          xrl.withdrawal_type = cv_withdrawal_type_1
                       OR xrl.withdrawal_type = cv_withdrawal_type_2
                     )
               )
             OR
               (
                     xrl.category_kbn = cv_category_kbn_new_rplc
                 AND xiw.job_kbn      = cn_job_kbn_new_replace
               )
             OR
               (
                     xrl.category_kbn = cv_category_kbn_old_rplc
                 AND xiw.job_kbn      = cn_job_kbn_old_replace
               )
             )
      ORDER BY xiw.actual_work_date  DESC
     ;
    /* 2009.06.09 K.Hosoi T1_1154(再修正) 対応 END */
    -- *** ローカル・レコード ***
    l_get_rec       g_value_rtype;            -- 訪問予定情報データ
    /* 2009.06.09 K.Hosoi T1_1154(再修正) 対応 START */
    l_get_act_wk_dt_rec   get_act_wk_dt_cur%ROWTYPE;
    /* 2009.06.09 K.Hosoi T1_1154(再修正) 対応 END */
    -- *** ローカル例外 ***
    select_error_expt     EXCEPTION;          -- データ出力処理例外
    /* 2009.05.25 M.Maruyama T1_1154対応 START */
    select_warn_expt      EXCEPTION;
    status_warn_expt      EXCEPTION;          -- データ出力処理警告例外
    /* 2009.05.25 M.Maruyama T1_1154対応 END */
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- INパラメータをローカル変数に代入
    l_get_rec     := io_get_rec;
    ld_bsnss_mnth := id_bsnss_mnth;
    --初期化
    lv_lst_accnt_num      := NULL;
    lv_account_number     := NULL;
    lv_sale_base_code     := NULL;
    lv_last_month_base_cd := NULL;
    lv_company_cd     := gv_company_cd;
    ld_sysdate        := TO_DATE(l_get_rec.sysdate_now,'YYYYMMDDHH24MISS');
    /* 2009.06.09 K.Hosoi T1_1154(再修正) 対応 START */
    ln_actual_work_date   := NULL;
    ln_target_cnt         := 0;
    /* 2009.06.09 K.Hosoi T1_1154(再修正) 対応 END */
    -- ===============================
    -- ステータスコードを抽出
    -- ===============================
    BEGIN
      SELECT flv.lookup_code  lookup_code   -- ステータス
      INTO   lv_lookup_code                 -- ステータス
      FROM   csi_instance_statuses cis      -- インスタンスステータスマスタ
            ,fnd_lookup_values_vl flv       -- クイックコード
      WHERE cis.instance_status_id = l_get_rec.instance_status_id  -- ステータスID
        AND flv.meaning = cis.name                                 -- 内容(ステータス名)
        AND flv.lookup_type = cv_instance_status                   -- ルックアップタイプ
        AND flv.enabled_flag = cv_enabled_flag                     -- 有効フラグ
        AND ld_sysdate BETWEEN flv.start_date_active AND NVL(flv.end_date_active,ld_sysdate); -- クイックコード期間
    EXCEPTION
      -- 検索結果がない場合、抽出失敗した場合
      WHEN OTHERS THEN
        /* 2009.11.27 K.Satomura E_本稼動_00118対応 START */
        --lv_errmsg := xxccp_common_pkg.get_msg(
        --                   iv_application  => cv_app_name                   -- アプリケーション短縮名
        --                  ,iv_name         => cv_tkn_number_06              -- メッセージコード
        --                  ,iv_token_name1  => cv_tkn_proc_name              -- トークンコード1
        --                  ,iv_token_value1 => cv_quick_cd                   -- トークン値1抽出処理名
        --                  ,iv_token_name2  => cv_tkn_object_cd              -- トークンコード2
        --                  ,iv_token_value2 => l_get_rec.install_code        -- トークン値2外部参照(物件コード)
        --                  ,iv_token_name3  => cv_tkn_status_id              -- トークンコード3
        --                  ,iv_token_value3 => l_get_rec.instance_status_id  -- トークン値3抽出処理名(ステータスID)
        --                  ,iv_token_name4  => cv_tkn_err_msg                -- トークンコード4
        --                  ,iv_token_value4 => SQLERRM                       -- トークン値4
        --    );
        --lv_errbuf  := lv_errmsg;
        --RAISE select_error_expt;
        lv_lookup_code := cv_lookup_code;
        ov_retcode     := cv_status_warn;
        lv_errmsg      := xxccp_common_pkg.get_msg(
                             iv_application  => cv_app_name            -- アプリケーション短縮名
                            ,iv_name         => cv_tkn_number_19       -- メッセージコード
                            ,iv_token_name1  => cv_tkn_param           -- トークンコード1
                            ,iv_token_value1 => cv_tkn_val1            -- トークン値1
                            ,iv_token_name2  => cv_tkn_object_cd       -- トークンコード2
                            ,iv_token_value2 => l_get_rec.install_code -- トークン値2外部参照(物件コード)
                          );
        --
        fnd_file.put_line(
           which  => fnd_file.log
          ,buff   => lv_errmsg
        );
        --
        fnd_file.put_line(
           which  => fnd_file.output
          ,buff   => lv_errmsg
        );
        --
        /* 2009.11.27 K.Satomura E_本稼動_00118対応 END */
    END;
--
    -- ===================================
    -- 拠点(部門)コード・顧客コードを抽出
    -- ===================================
    /* 2009.08.06 K.Satomura 0000935対応 START */
    --IF ((l_get_rec.jotai_kbn1 = cv_jotai_kbn1_3) AND (l_get_rec.install_account_id IS NULL)) THEN
    /* 2009.08.06 K.Satomura 0000935対応 END */
    lv_sale_base_code   := NULL;  -- 拠点コードにNULLをセット
    lv_account_number   := NULL;  -- 顧客コードにNULLをセット
    /* 2010.05.19 T.Maruyama E_本稼動_02787対応 START */
    lt_past_sale_base_code := NULL; --前月売上拠点CDにNULLをセット
    /* 2010.05.19 T.Maruyama E_本稼動_02787対応 END */
    /* 2009.08.06 K.Satomura 0000935対応 START */
    --ELSIF (l_get_rec.jotai_kbn1 IS NOT NULL) THEN
    /* 2009.08.06 K.Satomura 0000935対応 END */
    BEGIN
      /* 2009.11.27 K.Satomura E_本稼動_00118対応 START */
      --SELECT   (CASE
      --            WHEN l_get_rec.jotai_kbn1 = cv_jotai_kbn1_1 THEN
      --              xcav.sale_base_code       -- 拠点(部門)コード
      --            /* 2009.08.06 K.Satomura 0000935対応 START */
      --            --WHEN l_get_rec.jotai_kbn1 = cv_jotai_kbn1_2 THEN
      --            --  xcav.account_number       -- 顧客コード
      --            --WHEN l_get_rec.jotai_kbn1 = cv_jotai_kbn1_3 THEN
      --            --  NULL
      --            WHEN l_get_rec.jotai_kbn1 IN (cv_jotai_kbn1_2, cv_jotai_kbn1_3) THEN
      --              xcav.account_number       -- 顧客コード
      --            ELSE
      --              NULL
      --            /* 2009.08.06 K.Satomura 0000935対応 END */
      --          END) sale_base_code            -- 拠点(部門)コード
      SELECT   xcav.sale_base_code             -- 拠点(部門)コード
      /* 2009.11.27 K.Satomura E_本稼動_00118対応 END */
              ,xcav.account_number             -- 顧客コード
              /* 2010.05.19 T.Maruyama E_本稼動_02787対応 START */
              ,xcav.past_sale_base_code        -- 前月売上拠点
              /* 2010.05.19 T.Maruyama E_本稼動_02787対応 END */
      INTO     lv_sale_base_code               -- 拠点(部門)コード
              ,lv_account_number               -- 顧客コード
              /* 2010.05.19 T.Maruyama E_本稼動_02787対応 START */
              ,lt_past_sale_base_code          -- 前月売上拠点
              /* 2010.05.19 T.Maruyama E_本稼動_02787対応 END */
      FROM     xxcso_cust_accounts_v xcav      -- 顧客マスタビュー
      WHERE    xcav.cust_account_id = l_get_rec.install_account_id; -- アカウントID

    EXCEPTION
      -- 検索結果がない場合、抽出失敗した場合
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_app_name                   -- アプリケーション短縮名
                          ,iv_name         => cv_tkn_number_07              -- メッセージコード
                          ,iv_token_name1  => cv_tkn_proc_name              -- トークンコード1
                          ,iv_token_value1 => cv_base_account_cd            -- トークン値1抽出処理名
                          ,iv_token_name2  => cv_tkn_object_cd              -- トークンコード2
                          ,iv_token_value2 => l_get_rec.install_code        -- トークン値2外部参照(物件コード)
                          ,iv_token_name3  => cv_tkn_account_id             -- トークンコード3
                          ,iv_token_value3 => l_get_rec.install_account_id  -- トークン値3所有者アカウントID
                          ,iv_token_name4  => cv_tkn_location_cd            -- トークンコード4
                          ,iv_token_value4 => lv_sale_base_code             -- トークン値4拠点(部門)コード
                          ,iv_token_name5  => cv_tkn_customer_cd            -- トークンコード5
                          ,iv_token_value5 => lv_account_number             -- トークン値5顧客コード
                          ,iv_token_name6  => cv_tkn_err_msg                -- トークンコード6
                          ,iv_token_value6 => SQLERRM                       -- トークン値6
            );
        lv_errbuf  := lv_errmsg;
        RAISE select_error_expt;
    END;
    /* 2009.08.06 K.Satomura 0000935対応 START */
    --END IF;
    /* 2009.08.06 K.Satomura 0000935対応 END */
    -- 機器状態１が「2:滞留」の場合
    /* 2009.05.25 M.Maruyama T1_1154対応 START */
    /* 2009.04.08 K.Satomura T1_0365対応 START */
    IF ((io_get_rec.new_old_flag <> cv_flag_yes) 
       OR (io_get_rec.new_old_flag IS NULL)) THEN
    /* 2009.04.08 K.Satomura T1_0365対応 END */
    /* 2009.05.25 M.Maruyama T1_1154対応 END */
      IF (l_get_rec.jotai_kbn1 = cv_jotai_kbn1_2) THEN
        /* 2009.06.09 K.Hosoi T1_1154(再修正) 対応 START */
        --BEGIN
        /* 2009.06.09 K.Hosoi T1_1154(再修正) 対応 END */
        /* 2009.04.09 K.Satomura T1_0441対応 START */
        --  SELECT MAX(xiwd.actual_work_date) max_actual_work_date
        --  INTO   ln_actual_work_date                       -- 滞留開始日
        --  FROM   xxcso_in_work_data xiwd                   -- 作業データテーブル
        --        ,po_requisition_headers_all prha           -- 発注依頼ヘッダテーブル
        --        ,po_requisition_lines_all prla             -- 発注依頼明細テーブル
        --        ,xxcso_requisition_lines_v xrlv            -- 発注依頼明細情報ビュー
        --  WHERE  xiwd.install_code2 = l_get_rec.install_code
        --    /*20090327_yabuki_T1_0193 START*/
        --    --AND  xiwd.job_kbn = cn_job_kbn
        --    /*20090327_yabuki_T1_0193 END*/
        --    AND  xiwd.completion_kbn = cn_completion_kbn
        --    AND  TO_CHAR(xiwd.po_req_number) = prha.segment1
        --    AND  prha.requisition_header_id = prla.requisition_header_id
        --    AND  xiwd.line_num = xrlv.requisition_line_id
        --    /*20090327_yabuki_T1_0193 START*/
        --    AND  (( xiwd.job_kbn = cn_job_kbn
        --       AND xrlv.category_kbn = cv_category_kbn
        --       AND xrlv.withdrawal_type = cv_withdrawal_type )
        --    OR   ( xiwd.job_kbn = cn_job_kbn_new_replace
        --       AND xrlv.category_kbn = cv_category_kbn_new_rplc )
        --    OR   ( xiwd.job_kbn = cn_job_kbn_old_replace
        --       AND xrlv.category_kbn = cv_category_kbn_old_rplc ));
        --    --AND xrlv.category_kbn = cv_category_kbn
        --    --AND xrlv.withdrawal_type = cv_withdrawal_type;
        --    /*20090327_yabuki_T1_0193 END*/
        /* 2009.05.25 M.Maruyama T1_1154対応 START */
          --SELECT MAX(xiw.actual_work_date) max_actual_work_date -- 滞留開始日
          --INTO   ln_actual_work_date
          --FROM   xxcso_in_work_data        xiw -- 作業データテーブル
          --      ,po_requisition_headers    prh -- 発注依頼ヘッダビュー
          --      ,po_requisition_lines      prl -- 発注依頼明細ビュー
          --      ,xxcso_requisition_lines_v xrl -- 発注依頼明細情報ビュー
          --WHERE  xiw.install_code2          = l_get_rec.install_code
          --  AND  xiw.completion_kbn         = cn_completion_kbn
          --  AND  TO_CHAR(xiw.po_req_number) = prh.segment1
          --  AND  prh.requisition_header_id  = prl.requisition_header_id
          --  AND  xiw.line_num               = xrl.line_num
          --  AND  (
          --         (
          --               xrl.category_kbn    = cv_category_kbn
          --           AND xiw.job_kbn         = cn_job_kbn
          --           AND xrl.withdrawal_type = cv_withdrawal_type
          --         )
          --       OR
          --         (
          --               xrl.category_kbn = cv_category_kbn_new_rplc
          --           AND xiw.job_kbn      = cn_job_kbn_new_replace
          --         )
          --       OR
          --         (
          --               xrl.category_kbn = cv_category_kbn_old_rplc
          --           AND xiw.job_kbn      = cn_job_kbn_old_replace
          --         )
          --       )
          --  ;
          /* 2009.04.09 K.Satomura T1_0441対応 END */
        /* 2009.06.09 K.Hosoi T1_1154(再修正) 対応 START */
        --  SELECT MAX(xiw.actual_work_date) max_actual_work_date -- 滞留開始日
        --  INTO   ln_actual_work_date
        --  FROM   xxcso_in_work_data        xiw -- 作業データテーブル
        --        ,po_requisition_headers    prh -- 発注依頼ヘッダビュー
        --        ,xxcso_requisition_lines_v xrl -- 発注依頼明細情報ビュー
        --  WHERE  xiw.install2_processed_flag = cv_flag_yes
        --    AND  xiw.install_code2           = l_get_rec.install_code
        --    AND  xiw.completion_kbn          = cn_completion_kbn
        --    AND  TO_CHAR(xiw.po_req_number)  = prh.segment1
        --    AND  prh.requisition_header_id   = xrl.requisition_header_id
        --    AND  xiw.line_num                = xrl.line_num
        --    AND  (
        --           (
        --                 xrl.category_kbn    = cv_category_kbn
        --             AND xiw.job_kbn         = cn_job_kbn
        --             AND xrl.withdrawal_type = cv_withdrawal_type
        --           )
        --         OR
        --           (
        --                 xrl.category_kbn = cv_category_kbn_new_rplc
        --             AND xiw.job_kbn      = cn_job_kbn_new_replace
        --           )
        --         OR
        --           (
        --                 xrl.category_kbn = cv_category_kbn_old_rplc
        --             AND xiw.job_kbn      = cn_job_kbn_old_replace
        --           )
        --         )
        --    ;
        --
        ---- 検索結果がない場合
        --IF (ln_actual_work_date IS NULL) THEN
        --  lv_errmsg := xxccp_common_pkg.get_msg(
        --                       iv_application  => cv_app_name                   -- アプリケーション短縮名
        --                      ,iv_name         => cv_tkn_number_17              -- メッセージコード
        --                      ,iv_token_name1  => cv_tkn_item                   -- トークンコード1
        --                      ,iv_token_value1 => cv_actual_work_date           -- トークン値1抽出処理名
        --                      ,iv_token_name2  => cv_tkn_object_cd              -- トークンコード2
        --                      ,iv_token_value2 => l_get_rec.install_code        -- トークン値2外部参照(物件コード)
        --        );
        --    lv_errbuf  := lv_errmsg;
        --    RAISE select_warn_expt;
        --END IF;
        --
        --EXCEPTION
        --  -- 検索結果がない場合、警告終了例外へ
        --  WHEN select_warn_expt THEN
        --    RAISE status_warn_expt;
        --  -- 抽出失敗した場合
        --  WHEN OTHERS THEN
        --    lv_errmsg := xxccp_common_pkg.get_msg(
        --                       iv_application  => cv_app_name                   -- アプリケーション短縮名
        --                      ,iv_name         => cv_tkn_number_10              -- メッセージコード
        --                      -- ,iv_token_name1  => cv_tkn_proc_name              -- トークンコード1
        --                      -- ,iv_token_value1 => cv_work_data                  -- トークン値1抽出処理名
        --                      -- ,iv_token_name2  => cv_tkn_object_cd              -- トークンコード2
        --                      -- ,iv_token_value2 => l_get_rec.install_code        -- トークン値2外部参照(物件コード)
        --                      -- /* 2009.04.09 K.Satomura T1_0441対応 START */
        --                      -- --,iv_token_name3  => cv_tkn_work_date              -- トークンコード3
        --                      -- --,iv_token_value3 => ln_actual_work_date           -- トークン値3実作業日
        --                      -- --,iv_token_name4  => cv_tkn_location_cd            -- トークンコード4
        --                      -- --,iv_token_value4 => lv_base_code                  -- トークン値4拠点(部門)コード
        --                      -- --,iv_token_name5  => cv_tkn_err_msg                -- トークンコード5
        --                      -- --,iv_token_value5 => SQLERRM                       -- トークン値5
        --                      -- ,iv_token_name3  => cv_tkn_err_msg                -- トークンコード3
        --                      -- ,iv_token_value3 => SQLERRM                       -- トークン値3実作業日
        --                      -- /* 2009.04.09 K.Satomura T1_0441対応 END */
        --                      ,iv_token_name1  => cv_tkn_tsk_nm                 -- トークンコード1
        --                      ,iv_token_value1 => cv_actual_work_date           -- トークン値1抽出処理名
        --                      ,iv_token_name2  => cv_tkn_item                   -- トークンコード2
        --                      ,iv_token_value2 => cv_clm_nm                     -- トークン値2項目名物件コード
        --                      ,iv_token_name3  => cv_tkn_vl                     -- トークンコード3
        --                      ,iv_token_value3 => l_get_rec.install_code        -- トークン値3外部参照(物件コード)
        --                      ,iv_token_name4  => cv_tkn_err_msg                -- トークンコード4
        --                      ,iv_token_value4 => SQLERRM                       -- トークン値4SQLエラーメッセージ
        --        );
        --    lv_errbuf  := lv_errmsg;
        --    RAISE select_error_expt;
        --END;
        /* 2009.06.09 K.Hosoi T1_1154(再修正) 対応 END */
        -- -- 検索結果がない場合
        -- IF (ln_actual_work_date IS NULL) THEN
        --   lv_errmsg := xxccp_common_pkg.get_msg(
        --                        iv_application  => cv_app_name                   -- アプリケーション短縮名
        --                       /* 2009.04.09 K.Satomura T1_0441対応 START */
        --                       --,iv_name         => cv_tkn_number_10              -- メッセージコード
        --                       --,iv_token_name1  => cv_tkn_proc_name              -- トークンコード1
        --                       --,iv_token_value1 => cv_work_data                  -- トークン値1抽出処理名
        --                       --,iv_token_name2  => cv_tkn_object_cd              -- トークンコード2
        --                       --,iv_token_value2 => l_get_rec.install_code        -- トークン値2外部参照(物件コード)
        --                       ,iv_name         => cv_tkn_number_17              -- メッセージコード
        --                       ,iv_token_name1  => cv_tkn_item                   -- トークンコード1
        --                       ,iv_token_value1 => cv_actual_work_date           -- トークン値1抽出処理名
        --                       ,iv_token_name2  => cv_tkn_object_cd              -- トークンコード2
        --                       ,iv_token_value2 => l_get_rec.install_code        -- トークン値2外部参照(物件コード)
        --                       --,iv_token_name3  => cv_tkn_work_date              -- トークンコード3
        --                       --,iv_token_value3 => ln_actual_work_date           -- トークン値3実作業日
        --                       --,iv_token_name4  => cv_tkn_location_cd            -- トークンコード4
        --                       --,iv_token_value4 => lv_base_code                  -- トークン値4拠点(部門)コード
        --                       --,iv_token_name5  => cv_tkn_err_msg                -- トークンコード5
        --                       --,iv_token_value5 => SQLERRM                       -- トークン値5
        --                       /* 2009.04.09 K.Satomura T1_0441対応 END */
        --         );
        --     lv_errbuf  := lv_errmsg;
        --     RAISE select_error_expt;
        -- END IF;
        /* 2009.05.25 M.Maruyama T1_1154対応 END */
        /* 2009.06.09 K.Hosoi T1_1154(再修正) 対応 START */
        -- カーソルオープン
        OPEN get_act_wk_dt_cur(
               it_instll_cd  => l_get_rec.install_code -- 外部参照
             );
--
          BEGIN
            FETCH get_act_wk_dt_cur INTO l_get_act_wk_dt_rec;
--
          EXCEPTION
            WHEN OTHERS THEN
              lv_errmsg := xxccp_common_pkg.get_msg(
                                 iv_application  => cv_app_name                   -- アプリケーション短縮名
                                ,iv_name         => cv_tkn_number_10              -- メッセージコード
                                ,iv_token_name1  => cv_tkn_tsk_nm                 -- トークンコード1
                                ,iv_token_value1 => cv_actual_work_date           -- トークン値1抽出処理名
                                ,iv_token_name2  => cv_tkn_item                   -- トークンコード2
                                ,iv_token_value2 => cv_clm_nm                     -- トークン値2項目名物件コード
                                ,iv_token_name3  => cv_tkn_vl                     -- トークンコード3
                                ,iv_token_value3 => l_get_rec.install_code        -- トークン値3外部参照(物件コード)
                                ,iv_token_name4  => cv_tkn_err_msg                -- トークンコード4
                                ,iv_token_value4 => SQLERRM                       -- トークン値4SQLエラーメッセージ
                  );
              lv_errbuf  := lv_errmsg;
              RAISE select_error_expt;
          END;
--
        -- 処理対象件数格納
        ln_target_cnt := get_act_wk_dt_cur%ROWCOUNT;
        --抽出件数が０件の場合
        IF (ln_target_cnt = 0) THEN
        /* 2009.07.21 K.Hosoi 0000475対応 START */
--            lv_errmsg := xxccp_common_pkg.get_msg(
--                                 iv_application  => cv_app_name                   -- アプリケーション短縮名
--                                ,iv_name         => cv_tkn_number_18              -- メッセージコード
--                                ,iv_token_name1  => cv_tkn_tsk_nm                 -- トークンコード1
--                                ,iv_token_value1 => cv_actual_work_date_2         -- トークン値1抽出処理名
--                                ,iv_token_name2  => cv_tkn_bukken                 -- トークンコード2
--                                ,iv_token_value2 => l_get_rec.install_code        -- トークン値2外部参照(物件コード)
--                  );
--            lv_errbuf  := lv_errmsg;
--            RAISE status_warn_expt;
          ln_actual_work_date := NULL;
        /* 2009.07.21 K.Hosoi 0000475対応 END */
        END IF;
--
        -- 取得した実作業日がNULLの場合
        IF ( l_get_act_wk_dt_rec.actual_work_date IS NULL ) THEN
        /* 2009.07.21 K.Hosoi 0000475対応 START */
--          lv_errmsg := xxccp_common_pkg.get_msg(
--                               iv_application  => cv_app_name                   -- アプリケーション短縮名
--                              ,iv_name         => cv_tkn_number_17              -- メッセージコード
--                              ,iv_token_name1  => cv_tkn_item                   -- トークンコード1
--                              ,iv_token_value1 => cv_actual_work_date           -- トークン値1抽出処理名
--                              ,iv_token_name2  => cv_tkn_object_cd              -- トークンコード2
--                              ,iv_token_value2 => l_get_rec.install_code        -- トークン値2外部参照(物件コード)
--                );
--          lv_errbuf  := lv_errmsg;
--          RAISE status_warn_expt;
          ln_actual_work_date := NULL;
        /* 2009.07.21 K.Hosoi 0000475対応 END */
        END IF;
--
        -- カテゴリ区分 = '50'(引揚情報) 且つ 作業区分 = '5'(引揚)の場合
        IF ( l_get_act_wk_dt_rec.category_kbn = cv_category_kbn
          AND l_get_act_wk_dt_rec.job_kbn = cn_job_kbn ) THEN
--
          -- 引揚区分 = '1: 引揚'の場合
          IF ( l_get_act_wk_dt_rec.withdrawal_type = cv_withdrawal_type_1) THEN
            -- 滞留開始日に、取得した実作業日を設定
            ln_actual_work_date := l_get_act_wk_dt_rec.actual_work_date;
--
          -- 引揚区分 = '2: 一時引揚'の場合
          ELSE
            -- 滞留開始日にNULLを設定
            ln_actual_work_date := NULL;
          END IF;
        ELSE
          -- 滞留開始日に、取得した実作業日を設定
          ln_actual_work_date := l_get_act_wk_dt_rec.actual_work_date;
        END IF;
--
        -- カーソルクローズ
        CLOSE get_act_wk_dt_cur;
        /* 2009.06.09 K.Hosoi T1_1154(再修正) 対応 END */
--
      END IF;
    /* 2009.04.08 K.Satomura T1_0365対応 START */
    END IF;
    /* 2009.04.08 K.Satomura T1_0365対応 END */
--
    -- ========================================
    -- 製造メーカー、特殊機区分とコラム数を抽出
    -- ========================================
    /* 2010.03.17 K.Hosoi E_本稼動_01881対応 START */
    -- インスタンスタイプが「1:自動販売機」の場合
    --IF (l_get_rec.instance_type_code = 1) THEN
    /* 2010.03.17 K.Hosoi E_本稼動_01881対応 END */
    BEGIN
      SELECT  punv.attribute2 attribute2    -- メーカーコード
             ,punv.attribute9 attribute9    -- 特殊機区分１
             ,punv.attribute10 attribute10  -- 特殊機区分2
             ,punv.attribute11 attribute11  -- 特殊機区分3
             ,punv.attribute8 attribute8    -- コラム数
      INTO    lv_attribute2                 -- メーカーコード
             ,lv_attribute9                 -- 特殊機区分1
             ,lv_attribute10                -- 特殊機区分2
             ,lv_attribute11                -- 特殊機区分3
             ,lv_attribute8                 -- コラム数
      FROM   po_un_numbers_vl punv          -- 国連番号マスタビュー
      WHERE  punv.un_number = l_get_rec.vendor_model; -- 機種コード
      /* 2010.03.17 K.Hosoi E_本稼動_01881対応 START */
      -- インスタンスタイプが「1:自動販売機」以外の場合
      IF (l_get_rec.instance_type_code <> 1) THEN
        lv_attribute9   := NULL;             -- 特殊機区分1
        lv_attribute10  := NULL;             -- 特殊機区分2
        lv_attribute11  := NULL;             -- 特殊機区分3
        lv_attribute8   := NULL;             -- コラム数
      END IF;
      /* 2010.03.17 K.Hosoi E_本稼動_01881対応 END */
    EXCEPTION
      -- 検索結果がない場合、抽出失敗した場合
      WHEN OTHERS THEN
        /* 2009.11.27 K.Satomura E_本稼動_00118対応 START */
        --lv_errmsg := xxccp_common_pkg.get_msg(
        --                   iv_application  => cv_app_name                   -- アプリケーション短縮名
        --                  ,iv_name         => cv_tkn_number_08              -- メッセージコード
        --                  ,iv_token_name1  => cv_tkn_proc_name              -- トークンコード1
        --                  ,iv_token_value1 => cv_po_un_number_vl            -- トークン値1抽出処理名
        --                  ,iv_token_name2  => cv_tkn_object_cd              -- トークンコード2
        --                  ,iv_token_value2 => l_get_rec.install_code        -- トークン値2外部参照(物件コード)
        --                  ,iv_token_name3  => cv_tkn_un_number              -- トークンコード3
        --                  ,iv_token_value3 => l_get_rec.vendor_model        -- トークン値3機種コード
        --                  ,iv_token_name4  => cv_tkn_maker_cd               -- トークンコード4
        --                  ,iv_token_value4 => lv_attribute2                 -- トークン値4メーカーコード
        --                  ,iv_token_name5  => cv_tkn_special1               -- トークンコード5
        --                  ,iv_token_value5 => lv_attribute9                 -- トークン値5特殊機区分1
        --                  ,iv_token_name6  => cv_tkn_special2               -- トークンコード6
        --                  ,iv_token_value6 => lv_attribute10                -- トークン値6特殊機区分2
        --                  ,iv_token_name7  => cv_tkn_special3               -- トークンコード7
        --                  ,iv_token_value7 => lv_attribute11                -- トークン値7特殊機区分3
        --                  ,iv_token_name8  => cv_tkn_column                 -- トークンコード8
        --                  ,iv_token_value8 => lv_attribute8                 -- トークン値8コラム数
        --                  ,iv_token_name9  => cv_tkn_err_msg                -- トークンコード9
        --                  ,iv_token_value9 => SQLERRM                       -- トークン値9
        --    );
        --lv_errbuf  := lv_errmsg;
        --RAISE select_error_expt;
        lv_attribute2  := NULL;
        lv_attribute9  := NULL;
        lv_attribute10 := NULL;
        lv_attribute11 := NULL;
        lv_attribute8  := NULL;
        ov_retcode     := cv_status_warn;
        lv_errmsg      := xxccp_common_pkg.get_msg(
                             iv_application  => cv_app_name            -- アプリケーション短縮名
                            ,iv_name         => cv_tkn_number_19       -- メッセージコード
                            ,iv_token_name1  => cv_tkn_param           -- トークンコード1
                            ,iv_token_value1 => cv_tkn_val2            -- トークン値1
                            ,iv_token_name2  => cv_tkn_object_cd       -- トークンコード2
                            ,iv_token_value2 => l_get_rec.install_code -- トークン値2外部参照(物件コード)
                          );
        --
        fnd_file.put_line(
           which  => fnd_file.log
          ,buff   => lv_errmsg
        );
        --
        fnd_file.put_line(
           which  => fnd_file.output
          ,buff   => lv_errmsg
        );
        --
        /* 2009.11.27 K.Satomura E_本稼動_00118対応 END */
    END;
    /* 2010.03.17 K.Hosoi E_本稼動_01881対応 START */
    -- インスタンスタイプが「1:自動販売機」以外の場合
    --ELSE
    --  lv_attribute2   := NULL;             -- メーカーコード
    --  lv_attribute9   := NULL;             -- 特殊機区分1
    --  lv_attribute10  := NULL;             -- 特殊機区分2
    --  lv_attribute11  := NULL;             -- 特殊機区分3
    --  lv_attribute8   := NULL;             -- コラム数
    --END IF;
    /* 2010.03.17 K.Hosoi E_本稼動_01881対応 END */
--
    -- ==================================================
    -- 再リース区分とリース料 月額リース料(税抜)をを抽出
    -- ==================================================
    /*20090327_yabuki_T1_0191_T1_0194 START*/
    -- リース区分が「1:自社リース」の場合
    lv_install_code := l_get_rec.install_code;
    IF (l_get_rec.lease_kbn = cv_lease_kbn_1) THEN
--    -- リース区分が「1:自社リース」又は「2:お客様リース」の場合
--    lv_install_code := SUBSTR(l_get_rec.install_code,1,3) || SUBSTR(l_get_rec.install_code,5,6);
--    IF ((l_get_rec.lease_kbn = cv_lease_kbn_1) OR (l_get_rec.lease_kbn = cv_lease_kbn_2)) THEN
    /*20090327_yabuki_T1_0191_T1_0194 END*/
      BEGIN
        SELECT  xch.lease_type lease_type       -- 再リース区分
               ,xcl.second_charge second_charge -- リース料 月額リース料(税抜)
               /* 2010.02.26 K.Hosoi E_本稼動_01568 START */
               ,xoh.object_status object_status -- 物件ステータス
               /* 2010.02.26 K.Hosoi E_本稼動_01568 END */
        INTO    lv_lease_type                   -- 再リース区分
               ,ln_second_charge                -- リース料 月額リース料(税抜)
               /* 2010.02.26 K.Hosoi E_本稼動_01568 START */
               ,lt_object_status
               /* 2010.02.26 K.Hosoi E_本稼動_01568 END */
        FROM    xxcff_object_headers xoh        -- リース物件マスタ
               ,xxcff_contract_headers xch      -- リース契約テーブル
               ,xxcff_contract_lines xcl        -- リース契約明細テーブル
        WHERE   xoh.object_code = lv_install_code                 -- 物件コード
          AND   xoh.object_header_id = xcl.object_header_id       -- 物件内部ID
          AND   xcl.contract_header_id = xch.contract_header_id   -- 契約内部ID
          AND   xch.re_lease_times = xoh.re_lease_times;          -- 再リース回数
        /* 2010.02.26 K.Hosoi E_本稼動_01568 START */
        --
        -- 物件ステータスにより、設置可能契約の有無をチェック
        -- 物件ステータスがNULL以外でかつ、「契約済」「再リース契約済」「未契約」「再リース待」以外の場合
        IF ( lt_object_status IS NOT NULL
             AND lt_object_status NOT IN ( cv_obj_sts_contracted, cv_obj_sts_re_lease_cntrctd, cv_obj_sts_uncontract,
                                         cv_obj_sts_lease_wait ) ) THEN
          -- 再リース区分に'9'を設定 (※情報系には区分「9」のみ連携され、名称は連携されない)
          lv_lease_type := cv_ls_tp_no_cntrct;
          --
        END IF;
        /* 2010.02.26 K.Hosoi E_本稼動_01568 END */
      EXCEPTION
        /*20090327_yabuki_T1_0192 START*/
        -- 該当するレコードが存在しない場合
        WHEN NO_DATA_FOUND THEN
          lv_lease_type    := NULL;    -- 再リース区分
          ln_second_charge := NULL;    -- リース料 月額リース料(税抜)
        /*20090327_yabuki_T1_0192 END*/
        --
        -- 検索結果がない場合、抽出失敗した場合
        WHEN OTHERS THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_app_name                   -- アプリケーション短縮名
                          ,iv_name         => cv_tkn_number_09              -- メッセージコード
                          ,iv_token_name1  => cv_tkn_proc_name              -- トークンコード1
                          ,iv_token_value1 => cv_contract_headers           -- トークン値1抽出処理名
                          ,iv_token_name2  => cv_tkn_object_cd              -- トークンコード2
                          ,iv_token_value2 => l_get_rec.install_code        -- トークン値2外部参照(物件コード)
                          ,iv_token_name3  => cv_tkn_lease_kbn              -- トークンコード3
                          ,iv_token_value3 => lv_lease_type                 -- トークン値3リース区分
                          ,iv_token_name4  => cv_tkn_lease_price            -- トークンコード4
                          ,iv_token_value4 => TO_CHAR(ln_second_charge)     -- トークン値4リース料
                          ,iv_token_name5  => cv_tkn_err_msg                -- トークンコード5
                          ,iv_token_value5 => SQLERRM                       -- トークン値5
            );
          lv_errbuf  := lv_errmsg;
          RAISE select_error_expt;
      END;
    END IF;
--
    -- =========================================
    -- 先月末拠点コード・先月末顧客コードを抽出
    -- =========================================
    /* 2009.09.03 M.Maruyama 0001192対応 START */
    -- 先月末年月が未設定の場合
    IF (l_get_rec.last_year_month IS NULL) THEN
      -- 設置日=業務月の場合
      IF (TO_CHAR(l_get_rec.install_date,cv_yr_mnth_frmt) = TO_CHAR(ld_bsnss_mnth,cv_yr_mnth_frmt)) THEN
        lv_last_month_base_cd   := NULL;  -- 先月末拠点コードにNULLをセット
        lv_lst_accnt_num        := NULL;  -- 先月末顧客コードにNULLをセット
      -- 初回設置日<>業務月の場合
      ELSE
        /* 2010.05.19 T.Maruyama E_本稼動_02787対応 START */
        --lv_last_month_base_cd   := lv_sale_base_code;  -- 先月末拠点コードに現在の拠点コードをセット
        lv_last_month_base_cd   := lt_past_sale_base_code;  -- 先月末拠点コードに現在の顧客の前月売上拠点コードをセット
        /* 2010.05.19 T.Maruyama E_本稼動_02787対応 END */
        lv_lst_accnt_num        := lv_account_number;  -- 先月末顧客コードに現在の顧客コードをセット
      END IF;
--
    -- 先月末年月<>業務月-１の場合
    --IF ((l_get_rec.last_year_month <> TO_CHAR(ADD_MONTHS(ld_bsnss_mnth,cn_mnth_shft),cv_yr_mnth_frmt))
    --  OR (l_get_rec.last_year_month IS NULL))
    ELSIF (l_get_rec.last_year_month <> TO_CHAR(ADD_MONTHS(ld_bsnss_mnth,cn_mnth_shft),cv_yr_mnth_frmt))
    /* 2009.09.03 M.Maruyama 0001192対応 END */
    THEN
      /* 2010.05.19 T.Maruyama E_本稼動_02787対応 START */
      --lv_last_month_base_cd   := lv_sale_base_code;  -- 先月末拠点コードに現在の拠点コードをセット
      lv_last_month_base_cd   := lt_past_sale_base_code;  -- 先月末拠点コードに現在の顧客の前月売上拠点コードをセット
      /* 2010.05.19 T.Maruyama E_本稼動_02787対応 END */
      lv_lst_accnt_num        := lv_account_number;  -- 先月末顧客コードに現在の顧客コードをセット
--
    -- 先月末年月=業務月-１の場合
    ELSIF (l_get_rec.last_year_month = TO_CHAR(ADD_MONTHS(ld_bsnss_mnth,cn_mnth_shft),cv_yr_mnth_frmt)) THEN
      -- 先月末機器状態が3の場合
      /* 2009.08.06 K.Satomura 0000935対応 START */
      --IF (l_get_rec.last_jotai_kbn = cv_jotai_kbn1_3) THEN
      --  lv_last_month_base_cd   := NULL;                           -- 先月末拠点コードにNULLをセット
      --  lv_lst_accnt_num        := l_get_rec.last_inst_cust_code;  -- 先月末顧客コードに先月末顧客コードをセット
      --ELSIF (l_get_rec.last_jotai_kbn IN (cv_jotai_kbn1_1,cv_jotai_kbn1_2)) THEN
      /* 2009.08.06 K.Satomura 0000935対応 END */
      BEGIN
        /* 2010.05.19 T.Maruyama E_本稼動_02787対応 START */
         SELECT xcav.past_sale_base_code  last_month_base_cd-- 前月売上拠点(部門)コード 
               ,l_get_rec.last_inst_cust_code  -- 先月末顧客コード
          INTO  lv_last_month_base_cd           -- 先月末売上拠点コード
               ,lv_lst_accnt_num                -- 先月末顧客コード
          FROM  xxcso_cust_accounts_v xcav      -- 顧客マスタビュー
         WHERE  xcav.account_number = l_get_rec.last_inst_cust_code; -- 顧客コード
         
        --SELECT (CASE
        --          WHEN l_get_rec.last_jotai_kbn = cv_jotai_kbn1_1 THEN
        --            xcav.past_sale_base_code  -- 前月売上拠点(部門)コード
        --          /* 2009.08.06 K.Satomura 0000935対応 START */
        --          --WHEN l_get_rec.last_jotai_kbn = cv_jotai_kbn1_2 THEN
        --          WHEN l_get_rec.last_jotai_kbn IN (cv_jotai_kbn1_2, cv_jotai_kbn1_3) THEN
        --          /* 2009.08.06 K.Satomura 0000935対応 END */
        --            /* 2009.12.09 T.Maruyama E_本稼動_00117 START */
        --            --xcav.account_number       -- 顧客コード
        --            xcav.sale_base_code       -- 売上担当拠点コード
        --          ELSE
        --            xcav.sale_base_code       -- 売上担当拠点コード
        --            /* 2009.12.09 T.Maruyama E_本稼動_00117 END */
        --          END) last_month_base_cd
        --       ,l_get_rec.last_inst_cust_code  -- 先月末顧客コード
        --  INTO  lv_last_month_base_cd           -- 先月末売上拠点コード
        --       ,lv_lst_accnt_num                -- 先月末顧客コード
        --  FROM  xxcso_cust_accounts_v xcav      -- 顧客マスタビュー
        -- WHERE  xcav.account_number = l_get_rec.last_inst_cust_code; -- 顧客コード
        /* 2010.05.19 T.Maruyama E_本稼動_02787対応 END */
      EXCEPTION
        -- 検索結果がない場合、抽出失敗した場合
        WHEN OTHERS THEN
          /* 2009.11.27 K.Satomura E_本稼動_00118対応 START */
          --lv_errmsg := xxccp_common_pkg.get_msg(
          --                   iv_application  => cv_app_name                    -- アプリケーション短縮名
          --                  ,iv_name         => cv_tkn_number_07               -- メッセージコード
          --                  ,iv_token_name1  => cv_tkn_proc_name               -- トークンコード1
          --                  ,iv_token_value1 => cv_lst_bs_ccnt_cd              -- トークン値1抽出処理名
          --                  ,iv_token_name2  => cv_tkn_object_cd               -- トークンコード2
          --                  ,iv_token_value2 => l_get_rec.install_code         -- トークン値2外部参照(物件コード)
          --                  ,iv_token_name3  => cv_tkn_account_id              -- トークンコード3
          --                  ,iv_token_value3 => l_get_rec.install_account_id   -- トークン値3所有者アカウントID
          --                  ,iv_token_name4  => cv_tkn_location_cd             -- トークンコード4
          --                  ,iv_token_value4 => lv_last_month_base_cd          -- トークン値4拠点(部門)コード
          --                  ,iv_token_name5  => cv_tkn_customer_cd             -- トークンコード5
          --                  ,iv_token_value5 => l_get_rec.last_inst_cust_code  -- トークン値5先月末顧客コード
          --                  ,iv_token_name6  => cv_tkn_err_msg                 -- トークンコード6
          --                  ,iv_token_value6 => SQLERRM                        -- トークン値6
          --    );
          --lv_errbuf  := lv_errmsg;
          --RAISE select_error_expt;
          /* 2010.05.19 T.Maruyama E_本稼動_02787対応 START */
          --lv_last_month_base_cd := lv_sale_base_code;
          lv_last_month_base_cd := lt_past_sale_base_code;
          /* 2010.05.19 T.Maruyama E_本稼動_02787対応 END */
          lv_lst_accnt_num      := lv_account_number;
          ov_retcode            := cv_status_warn;
          lv_errmsg             := xxccp_common_pkg.get_msg(
                                      iv_application  => cv_app_name            -- アプリケーション短縮名
                                     ,iv_name         => cv_tkn_number_19       -- メッセージコード
                                     ,iv_token_name1  => cv_tkn_param           -- トークンコード1
                                     ,iv_token_value1 => cv_tkn_val3            -- トークン値1
                                     ,iv_token_name2  => cv_tkn_object_cd       -- トークンコード2
                                     ,iv_token_value2 => l_get_rec.install_code -- トークン値2外部参照(物件コード)
                                   );
          --
          fnd_file.put_line(
             which  => fnd_file.log
            ,buff   => lv_errmsg
          );
          --
          fnd_file.put_line(
             which  => fnd_file.output
            ,buff   => lv_errmsg
          );
          --
          /* 2009.11.27 K.Satomura E_本稼動_00118対応 END */
      END;
      /* 2009.08.06 K.Satomura 0000935対応 START */
      --END IF;
      /* 2009.08.06 K.Satomura 0000935対応 END */
    END IF;
--
    -- 取得した値をOUTパラメータに設定
    l_get_rec.lookup_code         := lv_lookup_code;         -- ステータス
    l_get_rec.base_code           := lv_sale_base_code;      -- 拠点(部門)コード
    l_get_rec.account_number      := lv_account_number;      -- 顧客コード
    l_get_rec.attribute2          := lv_attribute2;          -- 製造メーカー
    l_get_rec.attribute9          := lv_attribute9;          -- 特殊機区分１
    l_get_rec.attribute10         := lv_attribute10;         -- 特殊機区分２
    l_get_rec.attribute11         := lv_attribute11;         -- 特殊機区分３
    l_get_rec.lease_type          := lv_lease_type;          -- 再リース区分
    l_get_rec.second_charge       := ln_second_charge;       -- リース料 月額リース料(税抜)
    l_get_rec.attribute8          := lv_attribute8;          -- コラム数
    l_get_rec.actual_work_date    := ln_actual_work_date;    -- 滞留開始日
    l_get_rec.last_month_base_cd  := lv_last_month_base_cd;  -- 先月末拠点コード
    l_get_rec.last_inst_cust_code := lv_lst_accnt_num;       -- 先月末顧客コード
--
    io_get_rec := l_get_rec;
--
  EXCEPTION
    -- *** ファイル処理例外ハンドラ ***
    WHEN select_error_expt THEN
      /* 2009.04.09 K.Satomura T1_0441対応 START */
      gn_error_cnt  := gn_error_cnt + 1;
      /* 2009.04.09 K.Satomura T1_0441対応 END */
      /* 2009.06.09 K.Hosoi T1_1154(再修正) 対応 START */
      -- カーソルがクローズされていない場合
      IF (get_act_wk_dt_cur%ISOPEN) THEN
        -- カーソルクローズ
        CLOSE get_act_wk_dt_cur;
      END IF;
      /* 2009.06.09 K.Hosoi T1_1154(再修正) 対応 START */
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
      /* 2009.05.25 M.Maruyama T1_1154対応 START */
    WHEN status_warn_expt THEN
      /* 2009.06.09 K.Hosoi T1_1154(再修正) 対応 START */
      -- カーソルがクローズされていない場合
      IF (get_act_wk_dt_cur%ISOPEN) THEN
        -- カーソルクローズ
        CLOSE get_act_wk_dt_cur;
      END IF;
      /* 2009.06.09 K.Hosoi T1_1154(再修正) 対応 START */
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;
      /* 2009.05.25 M.Maruyama T1_1154対応 END */
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      /* 2009.06.09 K.Hosoi T1_1154(再修正) 対応 START */
      -- カーソルがクローズされていない場合
      IF (get_act_wk_dt_cur%ISOPEN) THEN
        -- カーソルクローズ
        CLOSE get_act_wk_dt_cur;
      END IF;
      /* 2009.06.09 K.Hosoi T1_1154(再修正) 対応 START */
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      /* 2009.06.09 K.Hosoi T1_1154(再修正) 対応 START */
      -- カーソルがクローズされていない場合
      IF (get_act_wk_dt_cur%ISOPEN) THEN
        -- カーソルクローズ
        CLOSE get_act_wk_dt_cur;
      END IF;
      /* 2009.06.09 K.Hosoi T1_1154(再修正) 対応 START */
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      /* 2009.06.09 K.Hosoi T1_1154(再修正) 対応 START */
      -- カーソルがクローズされていない場合
      IF (get_act_wk_dt_cur%ISOPEN) THEN
        -- カーソルクローズ
        CLOSE get_act_wk_dt_cur;
      END IF;
      /* 2009.06.09 K.Hosoi T1_1154(再修正) 対応 START */
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_csv_data;
--
--
  /**********************************************************************************
   * Procedure Name   : create_csv_rec
   * Description      : CSVファイル出力 (A-7)
   ***********************************************************************************/
  PROCEDURE create_csv_rec(
    i_get_rec   IN g_value_rtype,                  -- 什器マスタデータ
    ov_errbuf   OUT NOCOPY VARCHAR2,               -- エラー・メッセージ           --# 固定 #
    ov_retcode  OUT NOCOPY VARCHAR2,               -- リターン・コード             --# 固定 #
    ov_errmsg   OUT NOCOPY VARCHAR2                -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)  := 'create_csv_rec';       -- プログラム名
    cv_sep_com              CONSTANT VARCHAR2(3)    := ',';
    cv_sep_wquot            CONSTANT VARCHAR2(3)    := '"';
    /* 2010.04.21 T.Maruyama E_本稼動_02391対応 start*/
    cv_dummy_instance_num   CONSTANT VARCHAR2(6)    := '000000';
    /* 2010.04.21 T.Maruyama E_本稼動_02391対応 end*/
    
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--_
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル変数 ***
    lv_data          VARCHAR2(5000);                -- 編集データ
    -- *** ローカル・レコード ***
    l_get_rec       g_value_rtype;                  -- 什器マスタデータ
    -- *** ローカル例外 ***
    file_put_line_expt             EXCEPTION;       -- データ出力処理例外
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- INパラメータをローカル変数に代入
    l_get_rec  := i_get_rec;               -- 什器マスタデータを格納するレコード
--
    BEGIN
--
      --データ作成
      lv_data := cv_sep_wquot || l_get_rec.company_cd || cv_sep_wquot                         -- 会社コード
        || cv_sep_com || cv_sep_wquot || l_get_rec.install_code || cv_sep_wquot               -- 外部参照
        || cv_sep_com || NVL(l_get_rec.instance_type_code,0)                                  -- インスタンスタイプ
        || cv_sep_com || l_get_rec.lookup_code                                                -- ステータス
        || cv_sep_com || TO_CHAR(l_get_rec.install_date,'YYYYMMDD')                           -- 導入日
        /* 2010.04.21 T.Maruyama E_本稼動_02391対応 start*/
        --|| cv_sep_com || l_get_rec.instance_number                                            -- インスタンス番号
        || cv_sep_com || cv_dummy_instance_num                                                -- インスタンス番号
        /* 2010.04.21 T.Maruyama E_本稼動_02391対応 start*/
        || cv_sep_com || TO_CHAR(l_get_rec.quantity)                                          -- 数量
        || cv_sep_com || cv_sep_wquot || l_get_rec.accounting_class_code || cv_sep_wquot      -- 会計分類
        || cv_sep_com || TO_CHAR(l_get_rec.active_start_date,'YYYYMMDD')                      -- 開始日
        || cv_sep_com || cv_sep_wquot || TO_CHAR(l_get_rec.inventory_item_id) || cv_sep_wquot -- 品名コード
        || cv_sep_com || NVL(TO_CHAR(l_get_rec.install_party_id),0)                           -- 使用者パーティID
        || cv_sep_com || NVL(TO_CHAR(l_get_rec.install_account_id),0)                         -- 使用者アカウントID
        || cv_sep_com || cv_sep_wquot || l_get_rec.vendor_model || cv_sep_wquot               -- 機種(DFF1)
        || cv_sep_com || cv_sep_wquot || l_get_rec.vendor_number || cv_sep_wquot              -- 機番(DFF2)
        || cv_sep_com || TO_CHAR(TO_DATE(l_get_rec.first_install_date,'YY/MM/DD HH24:MI:SS'),'YYYYMMDD')
          -- 初回設置日(DFF3)
        || cv_sep_com || cv_sep_wquot || l_get_rec.op_request_flag || cv_sep_wquot            -- 作業依頼中フラグ(DFF4)
        || cv_sep_com || cv_sep_wquot || l_get_rec.ven_kyaku_last || cv_sep_wquot             -- 最終顧客コード
        || cv_sep_com || NVL(l_get_rec.ven_tasya_cd01,0)                                      -- 他社コード１
        || cv_sep_com || NVL(l_get_rec.ven_tasya_daisu01,0)                                   -- 他社台数１
        || cv_sep_com || NVL(l_get_rec.ven_tasya_cd02,0)                                      -- 他社コード２
        || cv_sep_com || NVL(l_get_rec.ven_tasya_daisu02,0)                                   -- 他社台数２
        || cv_sep_com || NVL(l_get_rec.ven_tasya_cd03,0)                                      -- 他社コード３
        || cv_sep_com || NVL(l_get_rec.ven_tasya_daisu03,0)                                   -- 他社台数３
        || cv_sep_com || NVL(l_get_rec.ven_tasya_cd04,0)                                      -- 他社コード４
        || cv_sep_com || NVL(l_get_rec.ven_tasya_daisu04,0)                                   -- 他社台数４
        || cv_sep_com || NVL(l_get_rec.ven_tasya_cd05,0)                                      -- 他社コード５
        || cv_sep_com || NVL(l_get_rec.ven_tasya_daisu05,0)                                   -- 他社台数５
        || cv_sep_com || cv_sep_wquot || l_get_rec.ven_haiki_flg || cv_sep_wquot              -- 廃棄フラグ
        /* 2009.05.18 K.Satomura T1_1049対応 START */
        --|| cv_sep_com || l_get_rec.haikikessai_dt                                             -- 廃棄決裁日
        || cv_sep_com || TO_CHAR(TO_DATE(l_get_rec.haikikessai_dt, 'YYYY/MM/DD'), 'YYYYMMDD')  -- 廃棄決裁日
        /* 2009.05.18 K.Satomura T1_1049対応 END */
        || cv_sep_com || cv_sep_wquot ||l_get_rec.ven_sisan_kbn || cv_sep_wquot               -- 資産区分
        /* 2009.07.21 K.Hosoi 0000475対応 START */
        --|| cv_sep_com || l_get_rec.ven_kobai_ymd                                              -- 購買日付
        || cv_sep_com || TO_CHAR(TO_DATE(l_get_rec.ven_kobai_ymd, 'YYYY/MM/DD'), 'YYYYMMDD')  -- 購買日付
        /* 2009.07.21 K.Hosoi 0000475対応 END */
        || cv_sep_com || NVL(l_get_rec.ven_kobai_kg,0)                                        -- 購買金額
        || cv_sep_com || NVL(l_get_rec.count_no,0)                                            -- カウンターNo.
        || cv_sep_com || cv_sep_wquot || l_get_rec.chiku_cd || cv_sep_wquot                   -- 地区コード
        || cv_sep_com || cv_sep_wquot || l_get_rec.sagyougaisya_cd || cv_sep_wquot            -- 作業会社コード
        || cv_sep_com || cv_sep_wquot || l_get_rec.jigyousyo_cd || cv_sep_wquot               -- 事業所コード
        || cv_sep_com || NVL(l_get_rec.den_no,0)                                              -- 最終作業伝票No.
        || cv_sep_com || NVL(l_get_rec.job_kbn,0)                                             -- 最終作業区分
        || cv_sep_com || NVL(l_get_rec.sintyoku_kbn,0)                                        -- 最終作業進捗
        /* 2009.05.18 K.Satomura T1_1049対応 START */
        --|| cv_sep_com || l_get_rec.yotei_dt                                                   -- 最終作業完了予定日
        --|| cv_sep_com || l_get_rec.kanryo_dt                                                  -- 最終作業完了日
        || cv_sep_com || TO_CHAR(TO_DATE(l_get_rec.yotei_dt, 'YYYY/MM/DD'), 'YYYYMMDD')       -- 最終作業完了予定日
        || cv_sep_com || TO_CHAR(TO_DATE(l_get_rec.kanryo_dt, 'YYYY/MM/DD'), 'YYYYMMDD')      -- 最終作業完了日
        /* 2009.05.18 K.Satomura T1_1049対応 END */
        || cv_sep_com || NVL(l_get_rec.sagyo_level,0)                                         -- 最終整備内容
        || cv_sep_com || NVL(l_get_rec.den_no2,0)                                             -- 最終設置伝票No.
        || cv_sep_com || NVL(l_get_rec.job_kbn2,0)                                            -- 最終設置区分
        || cv_sep_com || NVL(l_get_rec.sintyoku_kbn2,0)                                       -- 最終設置進捗
        || cv_sep_com || NVL(l_get_rec.jotai_kbn1,0)                                          -- 機器状態1（稼動状態）
        || cv_sep_com || NVL(l_get_rec.jotai_kbn2,0)                                          -- 機器状態2（状態詳細）
        || cv_sep_com || NVL(l_get_rec.jotai_kbn3,0)                                          -- 機器状態3（廃棄情報）
        || cv_sep_com || TO_CHAR(TO_DATE(l_get_rec.nyuko_dt,'YY/MM/DD HH24:MI:SS'),'YYYYMMDD')
          -- 入庫日
        || cv_sep_com || cv_sep_wquot || l_get_rec.hikisakigaisya_cd || cv_sep_wquot          -- 引揚会社コード
        || cv_sep_com || cv_sep_wquot || l_get_rec.hikisakijigyosyo_cd || cv_sep_wquot        -- 引揚事業所コード
        || cv_sep_com || cv_sep_wquot || l_get_rec.setti_tanto || cv_sep_wquot                -- 設置先担当者名
        || cv_sep_com || cv_sep_wquot || l_get_rec.setti_tel1 || cv_sep_wquot                 -- 設置先TEL(連結)１
        || cv_sep_com || cv_sep_wquot || l_get_rec.setti_tel2 || cv_sep_wquot                 -- 設置先TEL(連結)２
        || cv_sep_com || cv_sep_wquot || l_get_rec.setti_tel3 || cv_sep_wquot                 -- 設置先TEL(連結)３
        || cv_sep_com || cv_sep_wquot || l_get_rec.tenhai_tanto || cv_sep_wquot               -- 転売廃棄業者
        || cv_sep_com || NVL(l_get_rec.tenhai_den_no,0)                                       -- 転売廃棄伝票№
        || cv_sep_com || cv_sep_wquot || l_get_rec.syoyu_cd || cv_sep_wquot                   -- 所有者
        || cv_sep_com || NVL(l_get_rec.tenhai_flg,0)                                          -- 転売廃棄状況フラグ
        || cv_sep_com || NVL(l_get_rec.kanryo_kbn,0)                                          -- 転売完了区分
        || cv_sep_com || NVL(l_get_rec.sakujo_flg,0)                                          -- 削除フラグ
        || cv_sep_com || cv_sep_wquot || l_get_rec.safty_level || cv_sep_wquot                -- 安全設置基準
        || cv_sep_com || cv_sep_wquot || l_get_rec.lease_kbn || cv_sep_wquot                  -- リース区分
        || cv_sep_com || cv_sep_wquot || l_get_rec.base_code || cv_sep_wquot                  -- 拠点(部門)コード
        || cv_sep_com || cv_sep_wquot || l_get_rec.account_number || cv_sep_wquot             -- 顧客コード
        || cv_sep_com || cv_sep_wquot || l_get_rec.attribute2 || cv_sep_wquot                 -- 製造メーカー
        || cv_sep_com || cv_sep_wquot || l_get_rec.attribute9 || cv_sep_wquot                 -- 特殊機区分１
        || cv_sep_com || cv_sep_wquot || l_get_rec.attribute10 || cv_sep_wquot                -- 特殊機区分２
        || cv_sep_com || cv_sep_wquot || l_get_rec.attribute11 || cv_sep_wquot                -- 特殊機区分３
        || cv_sep_com || cv_sep_wquot || l_get_rec.lease_type || cv_sep_wquot                 -- 再リース区分
        || cv_sep_com || NVL(TO_CHAR(l_get_rec.second_charge),0)                              -- リース料 月額リース料(税抜)
        || cv_sep_com || NVL(l_get_rec.attribute8,0)                                          -- コラム数
        || cv_sep_com || TO_CHAR(l_get_rec.actual_work_date)                                  -- 滞留開始日
        || cv_sep_com || cv_sep_wquot || l_get_rec.last_inst_cust_code || cv_sep_wquot        -- 先月末顧客コード
        || cv_sep_com || cv_sep_wquot || l_get_rec.last_month_base_cd  || cv_sep_wquot        -- 先月末拠点（部門）コード
        || cv_sep_com || cv_sep_wquot || l_get_rec.new_old_flag || cv_sep_wquot               -- 新古台フラグ
        || cv_sep_com || l_get_rec.sysdate_now;                                               -- 連携時間
      -- データ出力
      UTL_FILE.PUT_LINE(
         file   => gf_file_hand
        ,buffer => lv_data
      );
    EXCEPTION
      WHEN UTL_FILE.INVALID_FILEHANDLE OR     -- ファイル・ハンドル無効エラー
           UTL_FILE.INVALID_OPERATION  OR     -- オープン不可能エラー
           UTL_FILE.WRITE_ERROR  THEN         -- 書込み操作中オペレーティングエラー
        -- エラーメッセージ取得
        lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                       --アプリケーション短縮名
                     ,iv_name         => cv_tkn_number_11                  --メッセージコード
                     ,iv_token_name1  => cv_tkn_object_cd                  --トークンコード1
                     ,iv_token_value1 => l_get_rec.install_code            --トークン値1顧客コード
                     ,iv_token_name2  => cv_tkn_err_msg                    --トークンコード2
                     ,iv_token_value2 => SQLERRM                           --トークン値2
                    );
        lv_errbuf := lv_errmsg;
      RAISE file_put_line_expt;
    END;
--
  EXCEPTION
    -- *** ファイル処理例外ハンドラ ***
    WHEN file_put_line_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END create_csv_rec;
--
  /**********************************************************************************
   * Procedure Name   : close_csv_file
   * Description      : CSVファイルクローズ処理 (A-8)
   ***********************************************************************************/
  PROCEDURE close_csv_file(
     iv_file_dir       IN  VARCHAR2         -- CSVファイル出力先
    ,iv_file_name      IN  VARCHAR2         -- CSVファイル名
    ,ov_errbuf         OUT NOCOPY VARCHAR2  -- エラー・メッセージ              --# 固定 #
    ,ov_retcode        OUT NOCOPY VARCHAR2  -- リターン・コード                --# 固定 #
    ,ov_errmsg         OUT NOCOPY VARCHAR2  -- ユーザー・エラー・メッセージ    --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name         CONSTANT VARCHAR2(100) := 'close_csv_file';    -- プログラム名
--
--#######################  固定ローカル変数宣言部 START   ######################
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
    -- *** ローカル変数 ***
    -- ファイルオープン確認戻り値格納
    lb_fopn_retcd   BOOLEAN;
    -- *** ローカル例外 ***
    file_err_expt   EXCEPTION;  -- ファイル処理例外
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ====================
    -- CSVファイルクローズ
    -- ====================
    BEGIN
      UTL_FILE.FCLOSE(
        file => gf_file_hand
      );
      -- *** DEBUG_LOG ***
      -- ファイルクローズしたことをログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg10   || CHR(10)   ||
                   cv_debug_msg_fnm || iv_file_name || CHR(10) ||
                   ''
      );
      EXCEPTION
        WHEN UTL_FILE.WRITE_ERROR          OR     -- オペレーティングシステムエラー
             UTL_FILE.INVALID_FILEHANDLE   THEN   -- ファイル・ハンドル無効エラー
          -- エラーメッセージ取得
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_app_name                  --アプリケーション短縮名
                        ,iv_name         => cv_tkn_number_13             --メッセージコード
                        ,iv_token_name1  => cv_tkn_csv_location          --トークンコード1
                        ,iv_token_value1 => iv_file_dir                  --トークン値1
                        ,iv_token_name2  => cv_tkn_csv_file_name         --トークンコード1
                        ,iv_token_value2 => iv_file_name                 --トークン値1
                       );
          lv_errbuf := lv_errmsg;
          RAISE file_err_expt;
    END;
  EXCEPTION
    -- *** ファイル処理例外ハンドラ ***
    WHEN file_err_expt THEN
      lb_fopn_retcd := UTL_FILE.IS_OPEN (
                         file =>gf_file_hand
                       );
      -- ファイルがクローズされていない場合
      IF (lb_fopn_retcd = cb_true) THEN
        -- ファイルクローズ
        UTL_FILE.FCLOSE(
          file =>gf_file_hand
        );
--
      -- *** DEBUG_LOG ***
      -- ファイルクローズしたことをログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_fcls || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err1 || cv_msg_part ||
                   cv_debug_msg_fnm  || iv_file_name   || CHR(10) ||
                   ''
      );
      END IF;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      lb_fopn_retcd := UTL_FILE.IS_OPEN (
                         file =>gf_file_hand
                       );
      -- ファイルがクローズされていない場合
      IF (lb_fopn_retcd = cb_true) THEN
        -- ファイルクローズ
        UTL_FILE.FCLOSE(
          file =>gf_file_hand
        );
--
      -- *** DEBUG_LOG ***
      -- ファイルクローズしたことをログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_fcls || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err2 || cv_msg_part ||
                   cv_debug_msg_fnm  || iv_file_name   || CHR(10) ||
                   ''
      );
      END IF;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      lb_fopn_retcd := UTL_FILE.IS_OPEN (
                         file =>gf_file_hand
                       );
      -- ファイルがクローズされていない場合
      IF (lb_fopn_retcd = cb_true) THEN
        -- ファイルクローズ
        UTL_FILE.FCLOSE(
          file =>gf_file_hand
        );
--
      -- *** DEBUG_LOG ***
      -- ファイルクローズしたことをログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_fcls || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err3 || cv_msg_part ||
                   cv_debug_msg_fnm  || iv_file_name   || CHR(10) ||
                   ''
      );
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      lb_fopn_retcd := UTL_FILE.IS_OPEN (
                         file =>gf_file_hand
                       );
      -- ファイルがクローズされていない場合
      IF (lb_fopn_retcd = cb_true) THEN
        -- ファイルクローズ
        UTL_FILE.FCLOSE(
          file =>gf_file_hand
        );
      -- *** DEBUG_LOG ***
      -- ファイルクローズしたことをログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_fcls || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err4 || cv_msg_part ||
                   cv_debug_msg_fnm  || iv_file_name   || CHR(10) ||
                   ''
      );
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END close_csv_file;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   ***********************************************************************************/
  PROCEDURE submain(
     ov_errbuf           OUT NOCOPY VARCHAR2   -- エラー・メッセージ            --# 固定 #
    ,ov_retcode          OUT NOCOPY VARCHAR2   -- リターン・コード              --# 固定 #
    ,ov_errmsg           OUT NOCOPY VARCHAR2   -- ユーザー・エラー・メッセージ    --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name            CONSTANT VARCHAR2(100) := 'submain';           -- プログラム名
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
---- *** ローカル定数 ***
    cv_sep_com              CONSTANT VARCHAR2(3)     := ',';
    cv_sep_wquot            CONSTANT VARCHAR2(3)     := '"';
    /*20090709_hosoi_0000518 START*/
--    cv_install_cd_tkn       CONSTANT VARCHAR2(100)   := '物件マスタビュー';
    cv_install_cd_tkn       CONSTANT VARCHAR2(100)   := '物件マスタ';
    /*20090709_hosoi_0000518 END*/
    cv_fist_install_dt_tkn  CONSTANT VARCHAR2(100)   := '初回設置日';
    cv_nyuko_date_tkn       CONSTANT VARCHAR2(100)   := '入庫日';
    cv_lst_yr_mnth_tkn      CONSTANT VARCHAR2(100)   := '先月末年月';
    /* 2009.07.21 K.Hosoi 0000475対応 START */
    cv_haikikessai_dt_tkn   CONSTANT VARCHAR2(100)   := '廃棄決済日';
    cv_ven_kobai_ymd_tkn    CONSTANT VARCHAR2(100)   := '購買日付';
    cv_yotei_dt_tkn         CONSTANT VARCHAR2(100)   := '最終作業完了予定日';
    cv_kanryo_dt_tkn        CONSTANT VARCHAR2(100)   := '最終作業完了日';
    cv_msg_bkn_cd           CONSTANT VARCHAR2(100)   := '、物件コード( ';
    cv_prnthss              CONSTANT VARCHAR2(100)   := ' )';
    /* 2009.07.21 K.Hosoi 0000475対応 END */
    cn_lst_yr_mnth_num      CONSTANT NUMBER(1)       := 6;
    /*20090709_hosoi_0000518 START*/
    cv_count_no             CONSTANT VARCHAR2(100)   := 'COUNT_NO';
    cv_chiku_cd             CONSTANT VARCHAR2(100)   := 'CHIKU_CD';
    cv_sagyougaisya_cd      CONSTANT VARCHAR2(100)   := 'SAGYOUGAISYA_CD';
    cv_jigyousyo_cd         CONSTANT VARCHAR2(100)   := 'JIGYOUSYO_CD';
    cv_den_no               CONSTANT VARCHAR2(100)   := 'DEN_NO';
    cv_job_kbn              CONSTANT VARCHAR2(100)   := 'JOB_KBN';
    cv_sintyoku_kbn         CONSTANT VARCHAR2(100)   := 'SINTYOKU_KBN';
    cv_yotei_dt             CONSTANT VARCHAR2(100)   := 'YOTEI_DT';
    cv_kanryo_dt            CONSTANT VARCHAR2(100)   := 'KANRYO_DT';
    cv_sagyo_level          CONSTANT VARCHAR2(100)   := 'SAGYO_LEVEL';
    cv_den_no2              CONSTANT VARCHAR2(100)   := 'DEN_NO2';
    cv_job_kbn2             CONSTANT VARCHAR2(100)   := 'JOB_KBN2';
    cv_sintyoku_kbn2        CONSTANT VARCHAR2(100)   := 'SINTYOKU_KBN2';
    cv_jotai_kbn1           CONSTANT VARCHAR2(100)   := 'JOTAI_KBN1';
    cv_jotai_kbn2           CONSTANT VARCHAR2(100)   := 'JOTAI_KBN2';
    cv_jotai_kbn3           CONSTANT VARCHAR2(100)   := 'JOTAI_KBN3';
    cv_nyuko_dt             CONSTANT VARCHAR2(100)   := 'NYUKO_DT';
    cv_hikisakigaisya_cd    CONSTANT VARCHAR2(100)   := 'HIKISAKIGAISYA_CD';
    cv_hikisakijigyosyo_cd  CONSTANT VARCHAR2(100)   := 'HIKISAKIJIGYOSYO_CD';
    cv_setti_tanto          CONSTANT VARCHAR2(100)   := 'SETTI_TANTO';
    cv_setti_tel1           CONSTANT VARCHAR2(100)   := 'SETTI_TEL1';
    cv_setti_tel2           CONSTANT VARCHAR2(100)   := 'SETTI_TEL2';
    cv_setti_tel3           CONSTANT VARCHAR2(100)   := 'SETTI_TEL3';
    cv_haikikessai_dt       CONSTANT VARCHAR2(100)   := 'HAIKIKESSAI_DT';
    cv_tenhai_tanto         CONSTANT VARCHAR2(100)   := 'TENHAI_TANTO';
    cv_tenhai_den_no        CONSTANT VARCHAR2(100)   := 'TENHAI_DEN_NO';
    cv_syoyu_cd             CONSTANT VARCHAR2(100)   := 'SYOYU_CD';
    cv_tenhai_flg           CONSTANT VARCHAR2(100)   := 'TENHAI_FLG';
    cv_kanryo_kbn           CONSTANT VARCHAR2(100)   := 'KANRYO_KBN';
    cv_sakujo_flg           CONSTANT VARCHAR2(100)   := 'SAKUJO_FLG';
    cv_ven_kyaku_last       CONSTANT VARCHAR2(100)   := 'VEN_KYAKU_LAST';
    cv_ven_tasya_cd01       CONSTANT VARCHAR2(100)   := 'VEN_TASYA_CD01';
    cv_ven_tasya_daisu01    CONSTANT VARCHAR2(100)   := 'VEN_TASYA_DAISU01';
    cv_ven_tasya_cd02       CONSTANT VARCHAR2(100)   := 'VEN_TASYA_CD02';
    cv_ven_tasya_daisu02    CONSTANT VARCHAR2(100)   := 'VEN_TASYA_DAISU02';
    cv_ven_tasya_cd03       CONSTANT VARCHAR2(100)   := 'VEN_TASYA_CD03';
    cv_ven_tasya_daisu03    CONSTANT VARCHAR2(100)   := 'VEN_TASYA_DAISU03';
    cv_ven_tasya_cd04       CONSTANT VARCHAR2(100)   := 'VEN_TASYA_CD04';
    cv_ven_tasya_daisu04    CONSTANT VARCHAR2(100)   := 'VEN_TASYA_DAISU04';
    cv_ven_tasya_cd05       CONSTANT VARCHAR2(100)   := 'VEN_TASYA_CD05';
    cv_ven_tasya_daisu05    CONSTANT VARCHAR2(100)   := 'VEN_TASYA_DAISU05';
    cv_ven_haiki_flg        CONSTANT VARCHAR2(100)   := 'VEN_HAIKI_FLG';
    cv_ven_sisan_kbn        CONSTANT VARCHAR2(100)   := 'VEN_SISAN_KBN';
    cv_ven_kobai_ymd        CONSTANT VARCHAR2(100)   := 'VEN_KOBAI_YMD';
    cv_ven_kobai_kg         CONSTANT VARCHAR2(100)   := 'VEN_KOBAI_KG';
    cv_safty_level          CONSTANT VARCHAR2(100)   := 'SAFTY_LEVEL';
    cv_lease_kbn            CONSTANT VARCHAR2(100)   := 'LEASE_KBN';
    cv_last_inst_cust_code  CONSTANT VARCHAR2(100)   := 'LAST_INST_CUST_CODE';
    cv_last_jotai_kbn       CONSTANT VARCHAR2(100)   := 'LAST_JOTAI_KBN';
    cv_last_year_month      CONSTANT VARCHAR2(100)   := 'LAST_YEAR_MONTH';
-- 2011/10/14 v1.19 T.Yoshimoto Add Start E_本稼動_05929
    cv_yymmddhhmiss         CONSTANT VARCHAR2(100)   := 'YY/MM/DD HH24:MI:SS';
    cv_yymmdd               CONSTANT VARCHAR2(100)   := 'YY/MM/DD';
-- 2011/10/14 v1.19 T.Yoshimoto Add End E_本稼動_05929
--
    /*20090709_hosoi_0000518 END*/
    -- *** ローカル変数 ***
    lv_sub_retcode         VARCHAR2(1);                -- サブメイン用リターン・コード
    lv_sub_msg             VARCHAR2(5000);             -- 警告用メッセージ
    lv_sub_buf             VARCHAR2(5000);             -- 警告用エラー・メッセージ
    lv_sysdate             VARCHAR2(100);              -- システム日付
    ld_bsnss_mnth          DATE;                       -- 業務月
    lv_file_dir            VARCHAR2(2000);             -- CSVファイル出力先
    lv_file_name           VARCHAR2(2000);             -- CSVファイル名
    lv_company_cd          VARCHAR2(2000);             -- 会社コード(固定値001)
    lb_check_date          BOOLEAN;                    -- 日付の書式であるかを確認
    -- ファイルオープン確認戻り値格納
    lb_fopn_retcd   BOOLEAN;
    -- メッセージ出力用
    lv_msg          VARCHAR2(2000);
    /*20090709_hosoi_0000518 START*/
    lv_attribute_level     VARCHAR2(15);               -- IB拡張属性テンプレートアクセスレベル格納用
    ld_date                DATE;                       -- TRUNC(SYSDATE)格納用
    /*20090709_hosoi_0000518 END*/
    /* 2009.11.27 K.Satomura E_本稼動_00118対応 START */
    lv_warn_flag           VARCHAR2(1) := 'N';
    /* 2009.11.27 K.Satomura E_本稼動_00118対応 END */
-- 2011/10/14 v1.19 T.Yoshimoto Add Start E_本稼動_05929
    lv_token_msg           VARCHAR2(1000);             -- 書式・桁数チェックエラー項目名格納用
    lv_msg2                VARCHAR2(2000);             -- 書式・桁数チェックエラーMSG納用
-- 2011/10/14 v1.19 T.Yoshimoto Add End E_本稼動_05929
    -- *** ローカル・カーソル ***
    /*20090709_hosoi_0000518 START*/
--    CURSOR xibv_data_cur
--    IS
--      SELECT xibv.install_code           install_code             -- 外部参照
--            ,xibv.instance_type_code     instance_type_code       -- インスタンスタイプ
--            ,xibv.instance_status_id     instance_status_id       -- ステータスID
--            ,xibv.install_date           install_date             -- 導入日
--            ,xibv.instance_number        instance_number          -- インスタンス番号
--            ,xibv.quantity               quantity                 -- 数量
--            ,xibv.accounting_class_code  accounting_class_code    -- 会計分類
--            ,xibv.active_start_date      active_start_date        -- 開始日
--            ,xibv.inventory_item_id      inventory_item_id        -- 品名コード
--            ,xibv.install_party_id       install_party_id         -- 使用者パーティID
--            ,xibv.install_account_id     install_account_id       -- 使用者アカウントID
--            ,xibv.vendor_model           vendor_model             -- 機種(DFF1)
--            ,xibv.vendor_number          vendor_number            -- 機番(DFF2)
--            ,xibv.first_install_date     first_install_date       -- 初回設置日(DFF3)
--            ,xibv.op_request_flag        op_request_flag          -- 作業依頼中フラグ(DFF4)
--            ,xibv.ven_kyaku_last         ven_kyaku_last           -- 最終顧客コード
--            ,xibv.ven_tasya_cd01         ven_tasya_cd01           -- 他社コード１
--            ,xibv.ven_tasya_daisu01      ven_tasya_daisu01        -- 他社台数１
--            ,xibv.ven_tasya_cd02         ven_tasya_cd02           -- 他社コード２
--            ,xibv.ven_tasya_daisu02      ven_tasya_daisu02        -- 他社台数２
--            ,xibv.ven_tasya_cd03         ven_tasya_cd03           -- 他社コード３
--            ,xibv.ven_tasya_daisu03      ven_tasya_daisu03        -- 他社台数３
--            ,xibv.ven_tasya_cd04         ven_tasya_cd04           -- 他社コード４
--            ,xibv.ven_tasya_daisu04      ven_tasya_daisu04        -- 他社台数４
--            ,xibv.ven_tasya_cd05         ven_tasya_cd05           -- 他社コード５
--            ,xibv.ven_tasya_daisu05      ven_tasya_daisu05        -- 他社台数５
--            ,xibv.ven_haiki_flg          ven_haiki_flg            -- 廃棄フラグ
--            ,xibv.haikikessai_dt         haikikessai_dt           -- 廃棄決裁日
--            ,xibv.ven_sisan_kbn          ven_sisan_kbn            -- 資産区分
--            ,xibv.ven_kobai_ymd          ven_kobai_ymd            -- 購買日付
--            ,xibv.ven_kobai_kg           ven_kobai_kg             -- 購買金額
--            ,xibv.count_no               count_no                 -- カウンターNo.
--            ,xibv.chiku_cd               chiku_cd                 -- 地区コード
--            ,xibv.sagyougaisya_cd        sagyougaisya_cd          -- 作業会社コード
--            ,xibv.jigyousyo_cd           jigyousyo_cd             -- 事業所コード
--            ,xibv.den_no                 den_no                   -- 最終作業伝票No.
--            ,xibv.job_kbn                job_kbn                  -- 最終作業区分
--            ,xibv.sintyoku_kbn           sintyoku_kbn             -- 最終作業進捗
--            ,xibv.yotei_dt               yotei_dt                 -- 最終作業完了予定日
--            ,xibv.kanryo_dt              kanryo_dt                -- 最終作業完了日
--            ,xibv.sagyo_level            sagyo_level              -- 最終整備内容
--            ,xibv.den_no2                den_no2                  -- 最終設置伝票No.
--            ,xibv.job_kbn2               job_kbn2                 -- 最終設置区分
--            ,xibv.sintyoku_kbn2          sintyoku_kbn2            -- 最終設置進捗
--            ,xibv.jotai_kbn1             jotai_kbn1               -- 機器状態1（稼動状態）
--            ,xibv.jotai_kbn2             jotai_kbn2               -- 機器状態2（状態詳細）
--            ,xibv.jotai_kbn3             jotai_kbn3               -- 機器状態3（廃棄情報）
--            ,xibv.nyuko_dt               nyuko_dt                 -- 入庫日
--            ,xibv.hikisakigaisya_cd      hikisakigaisya_cd        -- 引揚会社コード
--            ,xibv.hikisakijigyosyo_cd    hikisakijigyosyo_cd      -- 引揚事業所コード
--            ,xibv.setti_tanto            setti_tanto              -- 設置先担当者名
--            ,xibv.setti_tel1             setti_tel1               -- 設置先TEL(連結)１
--            ,xibv.setti_tel2             setti_tel2               -- 設置先TEL(連結)２
--            ,xibv.setti_tel3             setti_tel3               -- 設置先TEL(連結)３
--            ,xibv.tenhai_tanto           tenhai_tanto             -- 転売廃棄業者
--            ,xibv.tenhai_den_no          tenhai_den_no            -- 転売廃棄伝票№
--            ,xibv.syoyu_cd               syoyu_cd                 -- 所有者
--            ,xibv.tenhai_flg             tenhai_flg               -- 転売廃棄状況フラグ
--            ,xibv.kanryo_kbn             kanryo_kbn               -- 転売完了区分
--            ,xibv.sakujo_flg             sakujo_flg               -- 削除フラグ
--            ,xibv.safty_level            safty_level              -- 安全設置基準
--            ,xibv.lease_kbn              lease_kbn                -- リース区分
--            ,xibv.new_old_flag           new_old_flag             -- 新古台フラグ
--            ,xibv.last_inst_cust_code    last_inst_cust_code      -- 先月末設置先顧客コード
--            ,xibv.last_jotai_kbn         last_jotai_kbn           -- 先月末機器状態
--            ,xibv.last_year_month        last_year_month          -- 先月末年月
--      /*20090415_maruyama_T1_0550 START*/
--      FROM   xxcso_install_base_v xibv;
----      where instance_id IN(104039,90043,90045);                           -- 物件マスタビュー
--      /*20090415_maruyama_T1_0550 END*/
    CURSOR xibv_data_cur(
              iv_attribute_level IN VARCHAR2      -- IB拡張属性テンプレートアクセスレベル
             ,id_date            IN DATE          -- SYSDATE(yyyymmdd)
           )
    IS
      SELECT cii.EXTERNAL_REFERENCE           install_code             -- 外部参照
            ,cii.INSTANCE_TYPE_CODE           instance_type_code       -- インスタンスタイプ
            ,cii.INSTANCE_STATUS_ID           instance_status_id       -- ステータスID
            ,cii.INSTALL_DATE                 install_date             -- 導入日
            ,cii.INSTANCE_NUMBER              instance_number          -- インスタンス番号
            ,cii.QUANTITY                     quantity                 -- 数量
            ,cii.ACCOUNTING_CLASS_CODE        accounting_class_code    -- 会計分類
            ,cii.ACTIVE_START_DATE            active_start_date        -- 開始日
            ,cii.INVENTORY_ITEM_ID            inventory_item_id        -- 品名コード
            ,cii.OWNER_PARTY_ID               install_party_id         -- 使用者パーティID
            ,cii.OWNER_PARTY_ACCOUNT_ID       install_account_id       -- 使用者アカウントID
            ,cii.ATTRIBUTE1                   vendor_model             -- 機種(DFF1)
            ,cii.ATTRIBUTE2                   vendor_number            -- 機番(DFF2)
            ,cii.ATTRIBUTE3                   first_install_date       -- 初回設置日(DFF3)
            ,cii.ATTRIBUTE4                   op_request_flag          -- 作業依頼中フラグ(DFF4)
            ,( SELECT  civ.attribute_value       attribute_value
               FROM    csi_i_extended_attribs    ciea  -- 設置機器拡張属性定義情報テーブル
                     , csi_iea_values            civ   -- 設置機器拡張属性値情報テーブル
               WHERE   ciea.attribute_level = iv_attribute_level
                 AND   ciea.attribute_code  = cv_ven_kyaku_last
                 AND   civ.instance_id      = cii.instance_id
                 AND   ciea.attribute_id    = civ.attribute_id
                 AND   NVL( ciea.active_start_date, id_date ) <= id_date
                 AND   NVL( ciea.active_end_date, id_date )   >= id_date
             )                                ven_kyaku_last           -- 最終顧客コード
            ,( SELECT  civ.attribute_value       attribute_value
               FROM    csi_i_extended_attribs    ciea  -- 設置機器拡張属性定義情報テーブル
                     , csi_iea_values            civ   -- 設置機器拡張属性値情報テーブル
               WHERE   ciea.attribute_level = iv_attribute_level
                 AND   ciea.attribute_code  = cv_ven_tasya_cd01
                 AND   civ.instance_id      = cii.instance_id
                 AND   ciea.attribute_id    = civ.attribute_id
                 AND   NVL( ciea.active_start_date, id_date ) <= id_date
                 AND   NVL( ciea.active_end_date, id_date )   >= id_date
             )                                ven_tasya_cd01           -- 他社コード１
            ,( SELECT  civ.attribute_value       attribute_value
               FROM    csi_i_extended_attribs    ciea  -- 設置機器拡張属性定義情報テーブル
                     , csi_iea_values            civ   -- 設置機器拡張属性値情報テーブル
               WHERE   ciea.attribute_level = iv_attribute_level
                 AND   ciea.attribute_code  = cv_ven_tasya_daisu01
                 AND   civ.instance_id      = cii.instance_id
                 AND   ciea.attribute_id    = civ.attribute_id
                 AND   NVL( ciea.active_start_date, id_date ) <= id_date
                 AND   NVL( ciea.active_end_date, id_date )   >= id_date
             )                                ven_tasya_daisu01        -- 他社台数１
            ,( SELECT  civ.attribute_value       attribute_value
               FROM    csi_i_extended_attribs    ciea  -- 設置機器拡張属性定義情報テーブル
                     , csi_iea_values            civ   -- 設置機器拡張属性値情報テーブル
               WHERE   ciea.attribute_level = iv_attribute_level
                 AND   ciea.attribute_code  = cv_ven_tasya_cd02
                 AND   civ.instance_id      = cii.instance_id
                 AND   ciea.attribute_id    = civ.attribute_id
                 AND   NVL( ciea.active_start_date, id_date ) <= id_date
                 AND   NVL( ciea.active_end_date, id_date )   >= id_date
             )                                ven_tasya_cd02           -- 他社コード２
            ,( SELECT  civ.attribute_value       attribute_value
               FROM    csi_i_extended_attribs    ciea  -- 設置機器拡張属性定義情報テーブル
                     , csi_iea_values            civ   -- 設置機器拡張属性値情報テーブル
               WHERE   ciea.attribute_level = iv_attribute_level
                 AND   ciea.attribute_code  = cv_ven_tasya_daisu02
                 AND   civ.instance_id      = cii.instance_id
                 AND   ciea.attribute_id    = civ.attribute_id
                 AND   NVL( ciea.active_start_date, id_date ) <= id_date
                 AND   NVL( ciea.active_end_date, id_date )   >= id_date
             )                                ven_tasya_daisu02        -- 他社台数２
            ,( SELECT  civ.attribute_value       attribute_value
               FROM    csi_i_extended_attribs    ciea  -- 設置機器拡張属性定義情報テーブル
                     , csi_iea_values            civ   -- 設置機器拡張属性値情報テーブル
               WHERE   ciea.attribute_level = iv_attribute_level
                 AND   ciea.attribute_code  = cv_ven_tasya_cd03
                 AND   civ.instance_id      = cii.instance_id
                 AND   ciea.attribute_id    = civ.attribute_id
                 AND   NVL( ciea.active_start_date, id_date ) <= id_date
                 AND   NVL( ciea.active_end_date, id_date )   >= id_date
             )                                ven_tasya_cd03           -- 他社コード３
            ,( SELECT  civ.attribute_value       attribute_value
               FROM    csi_i_extended_attribs    ciea  -- 設置機器拡張属性定義情報テーブル
                     , csi_iea_values            civ   -- 設置機器拡張属性値情報テーブル
               WHERE   ciea.attribute_level = iv_attribute_level
                 AND   ciea.attribute_code  = cv_ven_tasya_daisu03
                 AND   civ.instance_id      = cii.instance_id
                 AND   ciea.attribute_id    = civ.attribute_id
                 AND   NVL( ciea.active_start_date, id_date ) <= id_date
                 AND   NVL( ciea.active_end_date, id_date )   >= id_date
             )                                ven_tasya_daisu03        -- 他社台数３
            ,( SELECT  civ.attribute_value       attribute_value
               FROM    csi_i_extended_attribs    ciea  -- 設置機器拡張属性定義情報テーブル
                     , csi_iea_values            civ   -- 設置機器拡張属性値情報テーブル
               WHERE   ciea.attribute_level = iv_attribute_level
                 AND   ciea.attribute_code  = cv_ven_tasya_cd04
                 AND   civ.instance_id      = cii.instance_id
                 AND   ciea.attribute_id    = civ.attribute_id
                 AND   NVL( ciea.active_start_date, id_date ) <= id_date
                 AND   NVL( ciea.active_end_date, id_date )   >= id_date
             )                                ven_tasya_cd04           -- 他社コード４
            ,( SELECT  civ.attribute_value       attribute_value
               FROM    csi_i_extended_attribs    ciea  -- 設置機器拡張属性定義情報テーブル
                     , csi_iea_values            civ   -- 設置機器拡張属性値情報テーブル
               WHERE   ciea.attribute_level = iv_attribute_level
                 AND   ciea.attribute_code  = cv_ven_tasya_daisu04
                 AND   civ.instance_id      = cii.instance_id
                 AND   ciea.attribute_id    = civ.attribute_id
                 AND   NVL( ciea.active_start_date, id_date ) <= id_date
                 AND   NVL( ciea.active_end_date, id_date )   >= id_date
             )                                ven_tasya_daisu04        -- 他社台数４
            ,( SELECT  civ.attribute_value       attribute_value
               FROM    csi_i_extended_attribs    ciea  -- 設置機器拡張属性定義情報テーブル
                     , csi_iea_values            civ   -- 設置機器拡張属性値情報テーブル
               WHERE   ciea.attribute_level = iv_attribute_level
                 AND   ciea.attribute_code  = cv_ven_tasya_cd05
                 AND   civ.instance_id      = cii.instance_id
                 AND   ciea.attribute_id    = civ.attribute_id
                 AND   NVL( ciea.active_start_date, id_date ) <= id_date
                 AND   NVL( ciea.active_end_date, id_date )   >= id_date
             )                                ven_tasya_cd05           -- 他社コード５
            ,( SELECT  civ.attribute_value       attribute_value
               FROM    csi_i_extended_attribs    ciea  -- 設置機器拡張属性定義情報テーブル
                     , csi_iea_values            civ   -- 設置機器拡張属性値情報テーブル
               WHERE   ciea.attribute_level = iv_attribute_level
                 AND   ciea.attribute_code  = cv_ven_tasya_daisu05
                 AND   civ.instance_id      = cii.instance_id
                 AND   ciea.attribute_id    = civ.attribute_id
                 AND   NVL( ciea.active_start_date, id_date ) <= id_date
                 AND   NVL( ciea.active_end_date, id_date )   >= id_date
             )                                ven_tasya_daisu05        -- 他社台数５
            ,( SELECT  civ.attribute_value       attribute_value
               FROM    csi_i_extended_attribs    ciea  -- 設置機器拡張属性定義情報テーブル
                     , csi_iea_values            civ   -- 設置機器拡張属性値情報テーブル
               WHERE   ciea.attribute_level = iv_attribute_level
                 AND   ciea.attribute_code  = cv_ven_haiki_flg
                 AND   civ.instance_id      = cii.instance_id
                 AND   ciea.attribute_id    = civ.attribute_id
                 AND   NVL( ciea.active_start_date, id_date ) <= id_date
                 AND   NVL( ciea.active_end_date, id_date )   >= id_date
             )                                ven_haiki_flg            -- 廃棄フラグ
            ,( SELECT  civ.attribute_value       attribute_value
               FROM    csi_i_extended_attribs    ciea  -- 設置機器拡張属性定義情報テーブル
                     , csi_iea_values            civ   -- 設置機器拡張属性値情報テーブル
               WHERE   ciea.attribute_level = iv_attribute_level
                 AND   ciea.attribute_code  = cv_haikikessai_dt
                 AND   civ.instance_id      = cii.instance_id
                 AND   ciea.attribute_id    = civ.attribute_id
                 AND   NVL( ciea.active_start_date, id_date ) <= id_date
                 AND   NVL( ciea.active_end_date, id_date )   >= id_date
             )                                haikikessai_dt           -- 廃棄決裁日
            ,( SELECT  civ.attribute_value       attribute_value
               FROM    csi_i_extended_attribs    ciea  -- 設置機器拡張属性定義情報テーブル
                     , csi_iea_values            civ   -- 設置機器拡張属性値情報テーブル
               WHERE   ciea.attribute_level = iv_attribute_level
                 AND   ciea.attribute_code  = cv_ven_sisan_kbn
                 AND   civ.instance_id      = cii.instance_id
                 AND   ciea.attribute_id    = civ.attribute_id
                 AND   NVL( ciea.active_start_date, id_date ) <= id_date
                 AND   NVL( ciea.active_end_date, id_date )   >= id_date
             )                                ven_sisan_kbn            -- 資産区分
            ,( SELECT  civ.attribute_value       attribute_value
               FROM    csi_i_extended_attribs    ciea  -- 設置機器拡張属性定義情報テーブル
                     , csi_iea_values            civ   -- 設置機器拡張属性値情報テーブル
               WHERE   ciea.attribute_level = iv_attribute_level
                 AND   ciea.attribute_code  = cv_ven_kobai_ymd
                 AND   civ.instance_id      = cii.instance_id
                 AND   ciea.attribute_id    = civ.attribute_id
                 AND   NVL( ciea.active_start_date, id_date ) <= id_date
                 AND   NVL( ciea.active_end_date, id_date )   >= id_date
             )                                ven_kobai_ymd            -- 購買日付
            ,( SELECT  civ.attribute_value       attribute_value
               FROM    csi_i_extended_attribs    ciea  -- 設置機器拡張属性定義情報テーブル
                     , csi_iea_values            civ   -- 設置機器拡張属性値情報テーブル
               WHERE   ciea.attribute_level = iv_attribute_level
                 AND   ciea.attribute_code  = cv_ven_kobai_kg
                 AND   civ.instance_id      = cii.instance_id
                 AND   ciea.attribute_id    = civ.attribute_id
                 AND   NVL( ciea.active_start_date, id_date ) <= id_date
                 AND   NVL( ciea.active_end_date, id_date )   >= id_date
             )                                ven_kobai_kg             -- 購買金額
            ,( SELECT  civ.attribute_value       attribute_value
               FROM    csi_i_extended_attribs    ciea  -- 設置機器拡張属性定義情報テーブル
                     , csi_iea_values            civ   -- 設置機器拡張属性値情報テーブル
               WHERE   ciea.attribute_level = iv_attribute_level
                 AND   ciea.attribute_code  = cv_count_no
                 AND   civ.instance_id      = cii.instance_id
                 AND   ciea.attribute_id    = civ.attribute_id
                 AND   NVL( ciea.active_start_date, id_date ) <= id_date
                 AND   NVL( ciea.active_end_date, id_date )   >= id_date
             )                                count_no                 -- カウンターNo.
            ,( SELECT  civ.attribute_value       attribute_value
               FROM    csi_i_extended_attribs    ciea  -- 設置機器拡張属性定義情報テーブル
                     , csi_iea_values            civ   -- 設置機器拡張属性値情報テーブル
               WHERE   ciea.attribute_level = iv_attribute_level
                 AND   ciea.attribute_code  = cv_chiku_cd
                 AND   civ.instance_id      = cii.instance_id
                 AND   ciea.attribute_id    = civ.attribute_id
                 AND   NVL( ciea.active_start_date, id_date ) <= id_date
                 AND   NVL( ciea.active_end_date, id_date )   >= id_date
             )                                chiku_cd                 -- 地区コード
            ,( SELECT  civ.attribute_value       attribute_value
               FROM    csi_i_extended_attribs    ciea  -- 設置機器拡張属性定義情報テーブル
                     , csi_iea_values            civ   -- 設置機器拡張属性値情報テーブル
               WHERE   ciea.attribute_level = iv_attribute_level
                 AND   ciea.attribute_code  = cv_sagyougaisya_cd
                 AND   civ.instance_id      = cii.instance_id
                 AND   ciea.attribute_id    = civ.attribute_id
                 AND   NVL( ciea.active_start_date, id_date ) <= id_date
                 AND   NVL( ciea.active_end_date, id_date )   >= id_date
             )                                sagyougaisya_cd          -- 作業会社コード
            ,( SELECT  civ.attribute_value       attribute_value
               FROM    csi_i_extended_attribs    ciea  -- 設置機器拡張属性定義情報テーブル
                     , csi_iea_values            civ   -- 設置機器拡張属性値情報テーブル
               WHERE   ciea.attribute_level = iv_attribute_level
                 AND   ciea.attribute_code  = cv_jigyousyo_cd
                 AND   civ.instance_id      = cii.instance_id
                 AND   ciea.attribute_id    = civ.attribute_id
                 AND   NVL( ciea.active_start_date, id_date ) <= id_date
                 AND   NVL( ciea.active_end_date, id_date )   >= id_date
             )                                jigyousyo_cd             -- 事業所コード
            ,( SELECT  civ.attribute_value       attribute_value
               FROM    csi_i_extended_attribs    ciea  -- 設置機器拡張属性定義情報テーブル
                     , csi_iea_values            civ   -- 設置機器拡張属性値情報テーブル
               WHERE   ciea.attribute_level = iv_attribute_level
                 AND   ciea.attribute_code  = cv_den_no
                 AND   civ.instance_id      = cii.instance_id
                 AND   ciea.attribute_id    = civ.attribute_id
                 AND   NVL( ciea.active_start_date, id_date ) <= id_date
                 AND   NVL( ciea.active_end_date, id_date )   >= id_date
             )                                den_no                   -- 最終作業伝票No.
            ,( SELECT  civ.attribute_value       attribute_value
               FROM    csi_i_extended_attribs    ciea  -- 設置機器拡張属性定義情報テーブル
                     , csi_iea_values            civ   -- 設置機器拡張属性値情報テーブル
               WHERE   ciea.attribute_level = iv_attribute_level
                 AND   ciea.attribute_code  = cv_job_kbn
                 AND   civ.instance_id      = cii.instance_id
                 AND   ciea.attribute_id    = civ.attribute_id
                 AND   NVL( ciea.active_start_date, id_date ) <= id_date
                 AND   NVL( ciea.active_end_date, id_date )   >= id_date
             )                                job_kbn                  -- 最終作業区分
            ,( SELECT  civ.attribute_value       attribute_value
               FROM    csi_i_extended_attribs    ciea  -- 設置機器拡張属性定義情報テーブル
                     , csi_iea_values            civ   -- 設置機器拡張属性値情報テーブル
               WHERE   ciea.attribute_level = iv_attribute_level
                 AND   ciea.attribute_code  = cv_sintyoku_kbn
                 AND   civ.instance_id      = cii.instance_id
                 AND   ciea.attribute_id    = civ.attribute_id
                 AND   NVL( ciea.active_start_date, id_date ) <= id_date
                 AND   NVL( ciea.active_end_date, id_date )   >= id_date
             )                                sintyoku_kbn             -- 最終作業進捗
            ,( SELECT  civ.attribute_value       attribute_value
               FROM    csi_i_extended_attribs    ciea  -- 設置機器拡張属性定義情報テーブル
                     , csi_iea_values            civ   -- 設置機器拡張属性値情報テーブル
               WHERE   ciea.attribute_level = iv_attribute_level
                 AND   ciea.attribute_code  = cv_yotei_dt
                 AND   civ.instance_id      = cii.instance_id
                 AND   ciea.attribute_id    = civ.attribute_id
                 AND   NVL( ciea.active_start_date, id_date ) <= id_date
                 AND   NVL( ciea.active_end_date, id_date )   >= id_date
             )                                yotei_dt                 -- 最終作業完了予定日
            ,( SELECT  civ.attribute_value       attribute_value
               FROM    csi_i_extended_attribs    ciea  -- 設置機器拡張属性定義情報テーブル
                     , csi_iea_values            civ   -- 設置機器拡張属性値情報テーブル
               WHERE   ciea.attribute_level = iv_attribute_level
                 AND   ciea.attribute_code  = cv_kanryo_dt
                 AND   civ.instance_id      = cii.instance_id
                 AND   ciea.attribute_id    = civ.attribute_id
                 AND   NVL( ciea.active_start_date, id_date ) <= id_date
                 AND   NVL( ciea.active_end_date, id_date )   >= id_date
             )                                kanryo_dt                -- 最終作業完了日
            ,( SELECT  civ.attribute_value       attribute_value
               FROM    csi_i_extended_attribs    ciea  -- 設置機器拡張属性定義情報テーブル
                     , csi_iea_values            civ   -- 設置機器拡張属性値情報テーブル
               WHERE   ciea.attribute_level = iv_attribute_level
                 AND   ciea.attribute_code  = cv_sagyo_level
                 AND   civ.instance_id      = cii.instance_id
                 AND   ciea.attribute_id    = civ.attribute_id
                 AND   NVL( ciea.active_start_date, id_date ) <= id_date
                 AND   NVL( ciea.active_end_date, id_date )   >= id_date
             )                                sagyo_level              -- 最終整備内容
            ,( SELECT  civ.attribute_value       attribute_value
               FROM    csi_i_extended_attribs    ciea  -- 設置機器拡張属性定義情報テーブル
                     , csi_iea_values            civ   -- 設置機器拡張属性値情報テーブル
               WHERE   ciea.attribute_level = iv_attribute_level
                 AND   ciea.attribute_code  = cv_den_no2
                 AND   civ.instance_id      = cii.instance_id
                 AND   ciea.attribute_id    = civ.attribute_id
                 AND   NVL( ciea.active_start_date, id_date ) <= id_date
                 AND   NVL( ciea.active_end_date, id_date )   >= id_date
             )                                den_no2                  -- 最終設置伝票No.
            ,( SELECT  civ.attribute_value       attribute_value
               FROM    csi_i_extended_attribs    ciea  -- 設置機器拡張属性定義情報テーブル
                     , csi_iea_values            civ   -- 設置機器拡張属性値情報テーブル
               WHERE   ciea.attribute_level = iv_attribute_level
                 AND   ciea.attribute_code  = cv_job_kbn2
                 AND   civ.instance_id      = cii.instance_id
                 AND   ciea.attribute_id    = civ.attribute_id
                 AND   NVL( ciea.active_start_date, id_date ) <= id_date
                 AND   NVL( ciea.active_end_date, id_date )   >= id_date
             )                                job_kbn2                 -- 最終設置区分
            ,( SELECT  civ.attribute_value       attribute_value
               FROM    csi_i_extended_attribs    ciea  -- 設置機器拡張属性定義情報テーブル
                     , csi_iea_values            civ   -- 設置機器拡張属性値情報テーブル
               WHERE   ciea.attribute_level = iv_attribute_level
                 AND   ciea.attribute_code  = cv_sintyoku_kbn2
                 AND   civ.instance_id      = cii.instance_id
                 AND   ciea.attribute_id    = civ.attribute_id
                 AND   NVL( ciea.active_start_date, id_date ) <= id_date
                 AND   NVL( ciea.active_end_date, id_date )   >= id_date
             )                                sintyoku_kbn2            -- 最終設置進捗
            ,( SELECT  civ.attribute_value       attribute_value
               FROM    csi_i_extended_attribs    ciea  -- 設置機器拡張属性定義情報テーブル
                     , csi_iea_values            civ   -- 設置機器拡張属性値情報テーブル
               WHERE   ciea.attribute_level = iv_attribute_level
                 AND   ciea.attribute_code  = cv_jotai_kbn1
                 AND   civ.instance_id      = cii.instance_id
                 AND   ciea.attribute_id    = civ.attribute_id
                 AND   NVL( ciea.active_start_date, id_date ) <= id_date
                 AND   NVL( ciea.active_end_date, id_date )   >= id_date
             )                                jotai_kbn1               -- 機器状態1（稼動状態）
            ,( SELECT  civ.attribute_value       attribute_value
               FROM    csi_i_extended_attribs    ciea  -- 設置機器拡張属性定義情報テーブル
                     , csi_iea_values            civ   -- 設置機器拡張属性値情報テーブル
               WHERE   ciea.attribute_level = iv_attribute_level
                 AND   ciea.attribute_code  = cv_jotai_kbn2
                 AND   civ.instance_id      = cii.instance_id
                 AND   ciea.attribute_id    = civ.attribute_id
                 AND   NVL( ciea.active_start_date, id_date ) <= id_date
                 AND   NVL( ciea.active_end_date, id_date )   >= id_date
             )                                jotai_kbn2               -- 機器状態2（状態詳細）
            ,( SELECT  civ.attribute_value       attribute_value
               FROM    csi_i_extended_attribs    ciea  -- 設置機器拡張属性定義情報テーブル
                     , csi_iea_values            civ   -- 設置機器拡張属性値情報テーブル
               WHERE   ciea.attribute_level = iv_attribute_level
                 AND   ciea.attribute_code  = cv_jotai_kbn3
                 AND   civ.instance_id      = cii.instance_id
                 AND   ciea.attribute_id    = civ.attribute_id
                 AND   NVL( ciea.active_start_date, id_date ) <= id_date
                 AND   NVL( ciea.active_end_date, id_date )   >= id_date
             )                                jotai_kbn3               -- 機器状態3（廃棄情報）
            ,( SELECT  civ.attribute_value       attribute_value
               FROM    csi_i_extended_attribs    ciea  -- 設置機器拡張属性定義情報テーブル
                     , csi_iea_values            civ   -- 設置機器拡張属性値情報テーブル
               WHERE   ciea.attribute_level = iv_attribute_level
                 AND   ciea.attribute_code  = cv_nyuko_dt
                 AND   civ.instance_id      = cii.instance_id
                 AND   ciea.attribute_id    = civ.attribute_id
                 AND   NVL( ciea.active_start_date, id_date ) <= id_date
                 AND   NVL( ciea.active_end_date, id_date )   >= id_date
             )                                nyuko_dt                 -- 入庫日
            ,( SELECT  civ.attribute_value       attribute_value
               FROM    csi_i_extended_attribs    ciea  -- 設置機器拡張属性定義情報テーブル
                     , csi_iea_values            civ   -- 設置機器拡張属性値情報テーブル
               WHERE   ciea.attribute_level = iv_attribute_level
                 AND   ciea.attribute_code  = cv_hikisakigaisya_cd
                 AND   civ.instance_id      = cii.instance_id
                 AND   ciea.attribute_id    = civ.attribute_id
                 AND   NVL( ciea.active_start_date, id_date ) <= id_date
                 AND   NVL( ciea.active_end_date, id_date )   >= id_date
             )                                hikisakigaisya_cd        -- 引揚会社コード
            ,( SELECT  civ.attribute_value       attribute_value
               FROM    csi_i_extended_attribs    ciea  -- 設置機器拡張属性定義情報テーブル
                     , csi_iea_values            civ   -- 設置機器拡張属性値情報テーブル
               WHERE   ciea.attribute_level = iv_attribute_level
                 AND   ciea.attribute_code  = cv_hikisakijigyosyo_cd
                 AND   civ.instance_id      = cii.instance_id
                 AND   ciea.attribute_id    = civ.attribute_id
                 AND   NVL( ciea.active_start_date, id_date ) <= id_date
                 AND   NVL( ciea.active_end_date, id_date )   >= id_date
             )                                hikisakijigyosyo_cd      -- 引揚事業所コード
            ,( SELECT  civ.attribute_value       attribute_value
               FROM    csi_i_extended_attribs    ciea  -- 設置機器拡張属性定義情報テーブル
                     , csi_iea_values            civ   -- 設置機器拡張属性値情報テーブル
               WHERE   ciea.attribute_level = iv_attribute_level
                 AND   ciea.attribute_code  = cv_setti_tanto
                 AND   civ.instance_id      = cii.instance_id
                 AND   ciea.attribute_id    = civ.attribute_id
                 AND   NVL( ciea.active_start_date, id_date ) <= id_date
                 AND   NVL( ciea.active_end_date, id_date )   >= id_date
             )                                setti_tanto              -- 設置先担当者名
            ,( SELECT  civ.attribute_value       attribute_value
               FROM    csi_i_extended_attribs    ciea  -- 設置機器拡張属性定義情報テーブル
                     , csi_iea_values            civ   -- 設置機器拡張属性値情報テーブル
               WHERE   ciea.attribute_level = iv_attribute_level
                 AND   ciea.attribute_code  = cv_setti_tel1
                 AND   civ.instance_id      = cii.instance_id
                 AND   ciea.attribute_id    = civ.attribute_id
                 AND   NVL( ciea.active_start_date, id_date ) <= id_date
                 AND   NVL( ciea.active_end_date, id_date )   >= id_date
             )                                setti_tel1               -- 設置先TEL(連結)１
            ,( SELECT  civ.attribute_value       attribute_value
               FROM    csi_i_extended_attribs    ciea  -- 設置機器拡張属性定義情報テーブル
                     , csi_iea_values            civ   -- 設置機器拡張属性値情報テーブル
               WHERE   ciea.attribute_level = iv_attribute_level
                 AND   ciea.attribute_code  = cv_setti_tel2
                 AND   civ.instance_id      = cii.instance_id
                 AND   ciea.attribute_id    = civ.attribute_id
                 AND   NVL( ciea.active_start_date, id_date ) <= id_date
                 AND   NVL( ciea.active_end_date, id_date )   >= id_date
             )                                setti_tel2               -- 設置先TEL(連結)２
            ,( SELECT  civ.attribute_value       attribute_value
               FROM    csi_i_extended_attribs    ciea  -- 設置機器拡張属性定義情報テーブル
                     , csi_iea_values            civ   -- 設置機器拡張属性値情報テーブル
               WHERE   ciea.attribute_level = iv_attribute_level
                 AND   ciea.attribute_code  = cv_setti_tel3
                 AND   civ.instance_id      = cii.instance_id
                 AND   ciea.attribute_id    = civ.attribute_id
                 AND   NVL( ciea.active_start_date, id_date ) <= id_date
                 AND   NVL( ciea.active_end_date, id_date )   >= id_date
             )                                setti_tel3               -- 設置先TEL(連結)３
            ,( SELECT  civ.attribute_value       attribute_value
               FROM    csi_i_extended_attribs    ciea  -- 設置機器拡張属性定義情報テーブル
                     , csi_iea_values            civ   -- 設置機器拡張属性値情報テーブル
               WHERE   ciea.attribute_level = iv_attribute_level
                 AND   ciea.attribute_code  = cv_tenhai_tanto
                 AND   civ.instance_id      = cii.instance_id
                 AND   ciea.attribute_id    = civ.attribute_id
                 AND   NVL( ciea.active_start_date, id_date ) <= id_date
                 AND   NVL( ciea.active_end_date, id_date )   >= id_date
             )                                tenhai_tanto             -- 転売廃棄業者
            ,( SELECT  civ.attribute_value       attribute_value
               FROM    csi_i_extended_attribs    ciea  -- 設置機器拡張属性定義情報テーブル
                     , csi_iea_values            civ   -- 設置機器拡張属性値情報テーブル
               WHERE   ciea.attribute_level = iv_attribute_level
                 AND   ciea.attribute_code  = cv_tenhai_den_no
                 AND   civ.instance_id      = cii.instance_id
                 AND   ciea.attribute_id    = civ.attribute_id
                 AND   NVL( ciea.active_start_date, id_date ) <= id_date
                 AND   NVL( ciea.active_end_date, id_date )   >= id_date
             )                                tenhai_den_no            -- 転売廃棄伝票№
            ,( SELECT  civ.attribute_value       attribute_value
               FROM    csi_i_extended_attribs    ciea  -- 設置機器拡張属性定義情報テーブル
                     , csi_iea_values            civ   -- 設置機器拡張属性値情報テーブル
               WHERE   ciea.attribute_level = iv_attribute_level
                 AND   ciea.attribute_code  = cv_syoyu_cd
                 AND   civ.instance_id      = cii.instance_id
                 AND   ciea.attribute_id    = civ.attribute_id
                 AND   NVL( ciea.active_start_date, id_date ) <= id_date
                 AND   NVL( ciea.active_end_date, id_date )   >= id_date
             )                                syoyu_cd                 -- 所有者
            ,( SELECT  civ.attribute_value       attribute_value
               FROM    csi_i_extended_attribs    ciea  -- 設置機器拡張属性定義情報テーブル
                     , csi_iea_values            civ   -- 設置機器拡張属性値情報テーブル
               WHERE   ciea.attribute_level = iv_attribute_level
                 AND   ciea.attribute_code  = cv_tenhai_flg
                 AND   civ.instance_id      = cii.instance_id
                 AND   ciea.attribute_id    = civ.attribute_id
                 AND   NVL( ciea.active_start_date, id_date ) <= id_date
                 AND   NVL( ciea.active_end_date, id_date )   >= id_date
             )                                tenhai_flg               -- 転売廃棄状況フラグ
            ,( SELECT  civ.attribute_value       attribute_value
               FROM    csi_i_extended_attribs    ciea  -- 設置機器拡張属性定義情報テーブル
                     , csi_iea_values            civ   -- 設置機器拡張属性値情報テーブル
               WHERE   ciea.attribute_level = iv_attribute_level
                 AND   ciea.attribute_code  = cv_kanryo_kbn
                 AND   civ.instance_id      = cii.instance_id
                 AND   ciea.attribute_id    = civ.attribute_id
                 AND   NVL( ciea.active_start_date, id_date ) <= id_date
                 AND   NVL( ciea.active_end_date, id_date )   >= id_date
             )                                kanryo_kbn               -- 転売完了区分
            ,( SELECT  civ.attribute_value       attribute_value
               FROM    csi_i_extended_attribs    ciea  -- 設置機器拡張属性定義情報テーブル
                     , csi_iea_values            civ   -- 設置機器拡張属性値情報テーブル
               WHERE   ciea.attribute_level = iv_attribute_level
                 AND   ciea.attribute_code  = cv_sakujo_flg
                 AND   civ.instance_id      = cii.instance_id
                 AND   ciea.attribute_id    = civ.attribute_id
                 AND   NVL( ciea.active_start_date, id_date ) <= id_date
                 AND   NVL( ciea.active_end_date, id_date )   >= id_date
             )                                sakujo_flg               -- 削除フラグ
            ,( SELECT  civ.attribute_value       attribute_value
               FROM    csi_i_extended_attribs    ciea  -- 設置機器拡張属性定義情報テーブル
                     , csi_iea_values            civ   -- 設置機器拡張属性値情報テーブル
               WHERE   ciea.attribute_level = iv_attribute_level
                 AND   ciea.attribute_code  = cv_safty_level
                 AND   civ.instance_id      = cii.instance_id
                 AND   ciea.attribute_id    = civ.attribute_id
                 AND   NVL( ciea.active_start_date, id_date ) <= id_date
                 AND   NVL( ciea.active_end_date, id_date )   >= id_date
             )                                safty_level              -- 安全設置基準
            ,( SELECT  civ.attribute_value       attribute_value
               FROM    csi_i_extended_attribs    ciea  -- 設置機器拡張属性定義情報テーブル
                     , csi_iea_values            civ   -- 設置機器拡張属性値情報テーブル
               WHERE   ciea.attribute_level = iv_attribute_level
                 AND   ciea.attribute_code  = cv_lease_kbn
                 AND   civ.instance_id      = cii.instance_id
                 AND   ciea.attribute_id    = civ.attribute_id
                 AND   NVL( ciea.active_start_date, id_date ) <= id_date
                 AND   NVL( ciea.active_end_date, id_date )   >= id_date
             )                                lease_kbn                -- リース区分
            ,cii.ATTRIBUTE5                   new_old_flag             -- 新古台フラグ
            ,( SELECT  civ.attribute_value       attribute_value
               FROM    csi_i_extended_attribs    ciea  -- 設置機器拡張属性定義情報テーブル
                     , csi_iea_values            civ   -- 設置機器拡張属性値情報テーブル
               WHERE   ciea.attribute_level = iv_attribute_level
                 AND   ciea.attribute_code  = cv_last_inst_cust_code
                 AND   civ.instance_id      = cii.instance_id
                 AND   ciea.attribute_id    = civ.attribute_id
                 AND   NVL( ciea.active_start_date, id_date ) <= id_date
                 AND   NVL( ciea.active_end_date, id_date )   >= id_date
             )                                last_inst_cust_code      -- 先月末設置先顧客コード
            ,( SELECT  civ.attribute_value       attribute_value
               FROM    csi_i_extended_attribs    ciea  -- 設置機器拡張属性定義情報テーブル
                     , csi_iea_values            civ   -- 設置機器拡張属性値情報テーブル
               WHERE   ciea.attribute_level = iv_attribute_level
                 AND   ciea.attribute_code  = cv_last_jotai_kbn
                 AND   civ.instance_id      = cii.instance_id
                 AND   ciea.attribute_id    = civ.attribute_id
                 AND   NVL( ciea.active_start_date, id_date ) <= id_date
                 AND   NVL( ciea.active_end_date, id_date )   >= id_date
             )                                last_jotai_kbn           -- 先月末機器状態
            ,( SELECT  civ.attribute_value       attribute_value
               FROM    csi_i_extended_attribs    ciea  -- 設置機器拡張属性定義情報テーブル
                     , csi_iea_values            civ   -- 設置機器拡張属性値情報テーブル
               WHERE   ciea.attribute_level = iv_attribute_level
                 AND   ciea.attribute_code  = cv_last_year_month
                 AND   civ.instance_id      = cii.instance_id
                 AND   ciea.attribute_id    = civ.attribute_id
                 AND   NVL( ciea.active_start_date, id_date ) <= id_date
                 AND   NVL( ciea.active_end_date, id_date )   >= id_date
             )                                last_year_month          -- 先月末年月
      FROM   csi_item_instances cii;
    /*20090709_hosoi_0000518 END*/
    -- *** ローカル・レコード ***
    l_xibv_data_rec        xibv_data_cur%ROWTYPE;
    l_get_rec              g_value_rtype;                        -- 什器マスタデータ
    -- *** ローカル・例外 ***
    select_error_expt EXCEPTION;
    lv_process_expt   EXCEPTION;
    no_data_expt      EXCEPTION;
-- 2011/10/14 v1.19 T.Yoshimoto Add Start E_本稼動_05929
    validation_expt   EXCEPTION;                                 -- 書式・桁数チェック例外
-- 2011/10/14 v1.19 T.Yoshimoto Add End E_本稼動_05929
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- グローバル変数の初期化
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
-- 2011/10/14 v1.19 T.Yoshimto Add Start E_本稼動_05929(コメントアウト解除)
    gn_skip_cnt   :=0;
-- 2011/10/14 v1.19 T.Yoshimto Add End E_本稼動_05929
--
    -- ================================
    -- A-1.初期処理
    -- ================================
    init(
      ov_sysdate          => lv_sysdate,       -- システム日付
      od_bsnss_mnth       => ld_bsnss_mnth,    -- 業務月
      ov_errbuf           => lv_errbuf,        -- エラー・メッセージ            --# 固定 #
      ov_retcode          => lv_retcode,       -- リターン・コード              --# 固定 #
      ov_errmsg           => lv_errmsg         -- ユーザー・エラー・メッセージ  --# 固定 #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- =================================================
    -- A-2.プロファイル値を取得
    -- =================================================
    get_profile_info(
       ov_file_dir    => lv_file_dir    -- CSVファイル出力先
      ,ov_file_name   => lv_file_name   -- CSVファイル名
      ,ov_company_cd  => lv_company_cd  -- 会社コード(固定値001)
      /*20090709_hosoi_0000518 START*/
      ,ov_attribute_level => lv_attribute_level  -- IB拡張属性テンプレートアクセスレベル
      /*20090709_hosoi_0000518 END*/
      ,ov_errbuf      => lv_errbuf      -- エラー・メッセージ            --# 固定 #
      ,ov_retcode     => lv_retcode     -- リターン・コード              --# 固定 #
      ,ov_errmsg      => lv_errmsg      -- ユーザー・エラー・メッセージ  --# 固定 #
    );
    gv_company_cd     := lv_company_cd;  -- 会社コード(固定値001)
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- =================================================
    -- A-3.CSVファイルオープン
    -- =================================================
--
    open_csv_file(
       iv_file_dir  => lv_file_dir   -- CSVファイル出力先
      ,iv_file_name => lv_file_name  -- CSVファイル名
      ,ov_errbuf    => lv_errbuf     -- エラー・メッセージ            --# 固定 #
      ,ov_retcode   => lv_retcode    -- リターン・コード              --# 固定 #
      ,ov_errmsg    => lv_errmsg     -- ユーザー・エラー・メッセージ  --# 固定 #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- =================================================
    -- A-4.物件データ抽出処理
    -- =================================================
--
    /*20090709_hosoi_0000518 START*/
    -- システム日付取得（時分秒は切り捨て）
    ld_date := TRUNC(SYSDATE);
    /*20090709_hosoi_0000518 END*/
    /*20090709_hosoi_0000518 START*/
    -- カーソルオープン
--    OPEN xibv_data_cur;
    OPEN xibv_data_cur(
            iv_attribute_level =>  lv_attribute_level  -- IB拡張属性テンプレートアクセスレベル
           ,id_date            =>  ld_date             -- SYSDATE(yyyymmdd)
         );
    /*20090709_hosoi_0000518 END*/
    -- *** DEBUG_LOG ***
    -- カーソルオープンしたことをログ出力
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => cv_debug_msg_copn || CHR(10) ||
                 ''
    );
--
    <<get_data_loop>>
    LOOP
--
      BEGIN
        FETCH xibv_data_cur INTO l_xibv_data_rec;
--
      EXCEPTION
        WHEN OTHERS THEN
          -- 什器マスタデータ抽出エラーメッセージ
          lv_errmsg := xxccp_common_pkg.get_msg(
                               iv_application  => cv_app_name               -- アプリケーション短縮名
                              ,iv_name         => cv_tkn_number_05          -- メッセージコード
                              ,iv_token_name1  => cv_tkn_proc_name          -- トークンコード1
                              ,iv_token_value1 => cv_install_cd_tkn         -- トークン値1
                              ,iv_token_name2  => cv_tkn_err_msg2           -- トークンコード2
                              ,iv_token_value2 => SQLERRM                   -- トークン値2
              );
          lv_errbuf  := lv_errmsg;
        RAISE global_process_expt;
      END;
--
      BEGIN
        -- データ初期化
        lv_sub_msg := NULL;
        lv_sub_buf := NULL;
-- 2011/10/14 v1.19 T.Yoshimoto Add Start E_本稼動_05929
        lv_token_msg := NULL;
-- 2011/10/14 v1.19 T.Yoshimoto Add End E_本稼動_05929
--
        -- レコード変数初期化
        l_get_rec         := NULL;    -- 什器マスタデータ格納
        -- 処理対象件数格納
        gn_target_cnt := xibv_data_cur%ROWCOUNT;
        -- 対象件数がO件の場合
        EXIT WHEN xibv_data_cur%NOTFOUND
        OR  xibv_data_cur%ROWCOUNT = 0;
--
        -- 取得データを格納
        l_get_rec.install_code           := l_xibv_data_rec.install_code;           -- 外部参照
        l_get_rec.instance_type_code     := l_xibv_data_rec.instance_type_code;     -- インスタンスタイプ
        l_get_rec.instance_status_id     := l_xibv_data_rec.instance_status_id;     -- ステータスID
        l_get_rec.install_date           := l_xibv_data_rec.install_date;           -- 導入日
        l_get_rec.instance_number        := l_xibv_data_rec.instance_number;        -- インスタンス番号
        l_get_rec.quantity               := l_xibv_data_rec.quantity;               -- 数量
        l_get_rec.accounting_class_code  := l_xibv_data_rec.accounting_class_code;  -- 会計分類
        l_get_rec.active_start_date      := l_xibv_data_rec.active_start_date;      -- 開始日
        l_get_rec.inventory_item_id      := l_xibv_data_rec.inventory_item_id;      -- 品名コード
        l_get_rec.install_party_id       := l_xibv_data_rec.install_party_id;       -- 使用者パーティID
        l_get_rec.install_account_id     := l_xibv_data_rec.install_account_id;     -- 使用者アカウントID
        l_get_rec.vendor_model           := l_xibv_data_rec.vendor_model;           -- 機種(DFF1)
        l_get_rec.vendor_number          := l_xibv_data_rec.vendor_number;          -- 機番(DFF2)
        l_get_rec.first_install_date     := l_xibv_data_rec.first_install_date;     -- 初回設置日(DFF3)
        l_get_rec.op_request_flag        := l_xibv_data_rec.op_request_flag;        -- 作業依頼中フラグ(DFF4)
        l_get_rec.ven_kyaku_last         := l_xibv_data_rec.ven_kyaku_last;         -- 最終顧客コード
        l_get_rec.ven_tasya_cd01         := l_xibv_data_rec.ven_tasya_cd01;         -- 他社コード１
        l_get_rec.ven_tasya_daisu01      := l_xibv_data_rec.ven_tasya_daisu01;      -- 他社台数１
        l_get_rec.ven_tasya_cd02         := l_xibv_data_rec.ven_tasya_cd02;         -- 他社コード２
        l_get_rec.ven_tasya_daisu02      := l_xibv_data_rec.ven_tasya_daisu02;      -- 他社台数２
        l_get_rec.ven_tasya_cd03         := l_xibv_data_rec.ven_tasya_cd03;         -- 他社コード３
        l_get_rec.ven_tasya_daisu03      := l_xibv_data_rec.ven_tasya_daisu03;      -- 他社台数３
        l_get_rec.ven_tasya_cd04         := l_xibv_data_rec.ven_tasya_cd04;         -- 他社コード４
        l_get_rec.ven_tasya_daisu04      := l_xibv_data_rec.ven_tasya_daisu04;      -- 他社台数４
        l_get_rec.ven_tasya_cd05         := l_xibv_data_rec.ven_tasya_cd05;         -- 他社コード５
        l_get_rec.ven_tasya_daisu05      := l_xibv_data_rec.ven_tasya_daisu05;      -- 他社台数５
        l_get_rec.ven_haiki_flg          := l_xibv_data_rec.ven_haiki_flg;          -- 廃棄フラグ
        l_get_rec.haikikessai_dt         := l_xibv_data_rec.haikikessai_dt;         -- 廃棄決裁日
        l_get_rec.ven_sisan_kbn          := l_xibv_data_rec.ven_sisan_kbn;          -- 資産区分
        l_get_rec.ven_kobai_ymd          := l_xibv_data_rec.ven_kobai_ymd;          -- 購買日付
        l_get_rec.ven_kobai_kg           := l_xibv_data_rec.ven_kobai_kg;           -- 購買金額
        l_get_rec.count_no               := l_xibv_data_rec.count_no;               -- カウンターNo.
        l_get_rec.chiku_cd               := l_xibv_data_rec.chiku_cd;               -- 地区コード
        l_get_rec.sagyougaisya_cd        := l_xibv_data_rec.sagyougaisya_cd;        -- 作業会社コード
        l_get_rec.jigyousyo_cd           := l_xibv_data_rec.jigyousyo_cd;           -- 事業所コード
        l_get_rec.den_no                 := l_xibv_data_rec.den_no;                 -- 最終作業伝票No.
        l_get_rec.job_kbn                := l_xibv_data_rec.job_kbn;                -- 最終作業区分
        l_get_rec.sintyoku_kbn           := l_xibv_data_rec.sintyoku_kbn;           -- 最終作業進捗
        l_get_rec.yotei_dt               := l_xibv_data_rec.yotei_dt;               -- 最終作業完了予定日
        l_get_rec.kanryo_dt              := l_xibv_data_rec.kanryo_dt;              -- 最終作業完了日
        l_get_rec.sagyo_level            := l_xibv_data_rec.sagyo_level;            -- 最終整備内容
        l_get_rec.den_no2                := l_xibv_data_rec.den_no2;                -- 最終設置伝票No.
        l_get_rec.job_kbn2               := l_xibv_data_rec.job_kbn2;               -- 最終設置区分
        l_get_rec.sintyoku_kbn2          := l_xibv_data_rec.sintyoku_kbn2;          -- 最終設置進捗
        l_get_rec.jotai_kbn1             := l_xibv_data_rec.jotai_kbn1;             -- 機器状態1（稼動状態）
        l_get_rec.jotai_kbn2             := l_xibv_data_rec.jotai_kbn2;             -- 機器状態2（状態詳細）
        l_get_rec.jotai_kbn3             := l_xibv_data_rec.jotai_kbn3;             -- 機器状態3（廃棄情報）
        l_get_rec.nyuko_dt               := l_xibv_data_rec.nyuko_dt;               -- 入庫日
        l_get_rec.hikisakigaisya_cd      := l_xibv_data_rec.hikisakigaisya_cd;      -- 引揚会社コード
        l_get_rec.hikisakijigyosyo_cd    := l_xibv_data_rec.hikisakijigyosyo_cd;    -- 引揚事業所コード
        l_get_rec.setti_tanto            := l_xibv_data_rec.setti_tanto;            -- 設置先担当者名
        l_get_rec.setti_tel1             := l_xibv_data_rec.setti_tel1;             -- 設置先TEL(連結)１
        l_get_rec.setti_tel2             := l_xibv_data_rec.setti_tel2;             -- 設置先TEL(連結)２
        l_get_rec.setti_tel3             := l_xibv_data_rec.setti_tel3;             -- 設置先TEL(連結)３
        l_get_rec.tenhai_tanto           := l_xibv_data_rec.tenhai_tanto;           -- 転売廃棄業者
        l_get_rec.tenhai_den_no          := l_xibv_data_rec.tenhai_den_no;          -- 転売廃棄伝票№
        l_get_rec.syoyu_cd               := l_xibv_data_rec.syoyu_cd;               -- 所有者
        l_get_rec.tenhai_flg             := l_xibv_data_rec.tenhai_flg;             -- 転売廃棄状況フラグ
        l_get_rec.kanryo_kbn             := l_xibv_data_rec.kanryo_kbn;             -- 転売完了区分
        l_get_rec.sakujo_flg             := l_xibv_data_rec.sakujo_flg;             -- 削除フラグ
        l_get_rec.safty_level            := l_xibv_data_rec.safty_level;            -- 安全設置基準
        l_get_rec.lease_kbn              := l_xibv_data_rec.lease_kbn;              -- リース区分
        l_get_rec.sysdate_now            := lv_sysdate;                             -- 連携時間
        l_get_rec.company_cd             := gv_company_cd;                          -- 会社コード(固定値001)
        l_get_rec.new_old_flag           := l_xibv_data_rec.new_old_flag;           -- 新古台フラグ
        l_get_rec.last_inst_cust_code    := l_xibv_data_rec.last_inst_cust_code;    -- 先月末顧客コード
        l_get_rec.last_jotai_kbn         := l_xibv_data_rec.last_jotai_kbn;         -- 先月末機器状態
        l_get_rec.last_year_month        := l_xibv_data_rec.last_year_month;        -- 先月末年月
--
-- 2011/10/14 v1.19 T.Yoshimoto Add Start E_本稼動_05929
        -- =================================================
        -- A-5.書式・桁数チェック処理
        -- =================================================
-- 2011/10/14 v1.19 T.Yoshimoto Add End E_本稼動_05929
        -- 日付書式チェック
        -- 初回設置日(DFF3)
        lb_check_date := xxcso_util_common_pkg.check_date(
                                      iv_date         => l_get_rec.first_install_date
-- 2011/10/14 v1.19 T.Yoshimoto Add Start E_本稼動_05929
--                                    ,iv_date_format  => 'YY/MM/DD HH24:MI:SS'
                                    ,iv_date_format  => cv_yymmddhhmiss
-- 2011/10/14 v1.19 T.Yoshimoto Add End E_本稼動_05929
        );
        --リターンステータスが「FALSE」の場合,例外処理を行う
        IF (lb_check_date = cb_false) THEN
          /* 2009.11.27 K.Satomura E_本稼動_00118 START */
          --lv_sub_msg := xxccp_common_pkg.get_msg(
          --                       iv_application  => cv_app_name                   -- アプリケーション短縮名
          --                      ,iv_name         => cv_tkn_number_15              -- メッセージコード
          --                      ,iv_token_name1  => cv_tkn_item                   -- トークンコード1
          --                      ,iv_token_value1 => cv_fist_install_dt_tkn        -- トークン値1項目名
          --                      ,iv_token_name2  => cv_tkn_value                  -- トークンコード2
          --                      ,iv_token_value2 => l_get_rec.first_install_date  -- トークン値2値
          --);
          --lv_sub_buf  := lv_sub_msg;
          --RAISE select_error_expt;
          l_get_rec.first_install_date := NULL;
          /* 2009.11.27 K.Satomura E_本稼動_00118 END */
        END IF;
-- 2011/10/14 v1.19 T.Yoshimoto Del Start E_本稼動_05929
--        -- 入庫日
--        lb_check_date := xxcso_util_common_pkg.check_date(
--                                      iv_date         => l_get_rec.nyuko_dt
--                                     ,iv_date_format  => 'YY/MM/DD HH24:MI:SS'
--        );
--        --リターンステータスが「FALSE」の場合,例外処理を行う
--        IF (lb_check_date = cb_false) THEN
--          /* 2009.11.27 K.Satomura E_本稼動_00118 START */
--          --lv_sub_msg := xxccp_common_pkg.get_msg(
--          --                       iv_application  => cv_app_name                   -- アプリケーション短縮名
--          --                      ,iv_name         => cv_tkn_number_15              -- メッセージコード
--          --                      ,iv_token_name1  => cv_tkn_item                   -- トークンコード1
--          --                      ,iv_token_value1 => cv_nyuko_date_tkn             -- トークン値1項目名
--          --                      ,iv_token_name2  => cv_tkn_value                  -- トークンコード2
--          --                      ,iv_token_value2 => l_get_rec.nyuko_dt            -- トークン値2値
--          --);
--          --lv_sub_buf  := lv_sub_msg;
--          --RAISE select_error_expt;
--          l_get_rec.nyuko_dt := NULL;
--          /* 2009.11.27 K.Satomura E_本稼動_00118 END */
--        END IF;
--        -- 先月末年月
--        lb_check_date := xxcso_util_common_pkg.check_date(
--                                      iv_date         => l_get_rec.last_year_month
--                                     ,iv_date_format  => 'YY/MM'
--        );
--        --リターンステータスが「FALSE」の場合,例外処理を行う
--        IF (lb_check_date = cb_false) THEN
--          /* 2009.11.27 K.Satomura E_本稼動_00118 START */
--          --lv_sub_msg := xxccp_common_pkg.get_msg(
--          --                       iv_application  => cv_app_name                   -- アプリケーション短縮名
--          --                      ,iv_name         => cv_tkn_number_15              -- メッセージコード
--          --                      ,iv_token_name1  => cv_tkn_item                   -- トークンコード1
--          --                      ,iv_token_value1 => cv_lst_yr_mnth_tkn            -- トークン値1項目名
--          --                      ,iv_token_name2  => cv_tkn_value                  -- トークンコード2
--          --                      ,iv_token_value2 => l_get_rec.last_year_month     -- トークン値2値
--          --);
--          --lv_sub_buf  := lv_sub_msg;
--          --RAISE select_error_expt;
--          l_get_rec.last_year_month := NULL;
--          /* 2009.11.27 K.Satomura E_本稼動_00118 END */
--        END IF;
--        /* 2009.05.18 K.Satomura T1_1049対応 START */
--        -- 廃棄決裁日
--        lb_check_date := xxcso_util_common_pkg.check_date(
--                                      iv_date         => l_get_rec.haikikessai_dt
--                                     ,iv_date_format  => 'YYYY/MM/DD'
--        );
--        --リターンステータスが「FALSE」の場合,例外処理を行う
--        IF (lb_check_date = cb_false) THEN
--          /* 2009.11.27 K.Satomura E_本稼動_00118 START */
--          --lv_sub_msg := xxccp_common_pkg.get_msg(
--          --                       iv_application  => cv_app_name              -- アプリケーション短縮名
--          --                      ,iv_name         => cv_tkn_number_15         -- メッセージコード
--          --                      ,iv_token_name1  => cv_tkn_item              -- トークンコード1
--          --                      /* 2009.07.21 K.Hosoi 0000475対応 START */
--        --                        ,iv_token_value1 => cv_lst_yr_mnth_tkn       -- トークン値1項目名
--          --                      ,iv_token_value1 => cv_haikikessai_dt_tkn    -- トークン値1項目名
--          --                      /* 2009.07.21 K.Hosoi 0000475対応 END */
--          --                      ,iv_token_name2  => cv_tkn_value             -- トークンコード2
--          --                      ,iv_token_value2 => l_get_rec.haikikessai_dt -- トークン値2値
--          --);
--          --lv_sub_buf  := lv_sub_msg;
--          --RAISE select_error_expt;
--          l_get_rec.haikikessai_dt := NULL;
--          /* 2009.11.27 K.Satomura E_本稼動_00118 END */
--        END IF;
--        /* 2009.07.21 K.Hosoi 0000475対応 START */
--        -- 購買日付
--        lb_check_date := xxcso_util_common_pkg.check_date(
--                                      iv_date         => l_get_rec.ven_kobai_ymd
--                                     ,iv_date_format  => 'YYYY/MM/DD'
--        );
--        --リターンステータスが「FALSE」の場合,例外処理を行う
--        IF (lb_check_date = cb_false) THEN
--          /* 2009.11.27 K.Satomura E_本稼動_00118 START */
--          --lv_sub_msg := xxccp_common_pkg.get_msg(
--          --                       iv_application  => cv_app_name              -- アプリケーション短縮名
--          --                      ,iv_name         => cv_tkn_number_15         -- メッセージコード
--          --                      ,iv_token_name1  => cv_tkn_item              -- トークンコード1
--          --                      ,iv_token_value1 => cv_ven_kobai_ymd_tkn     -- トークン値1項目名
--          --                      ,iv_token_name2  => cv_tkn_value             -- トークンコード2
--          --                      ,iv_token_value2 => l_get_rec.ven_kobai_ymd -- トークン値2値
--          --);
--          --lv_sub_buf  := lv_sub_msg;
--          --RAISE select_error_expt;
--          l_get_rec.ven_kobai_ymd := NULL;
--          /* 2009.11.27 K.Satomura E_本稼動_00118 END */
--        END IF;
--        /* 2009.07.21 K.Hosoi 0000475対応 END */
--        -- 最終作業完了予定日
--        lb_check_date := xxcso_util_common_pkg.check_date(
--                                      iv_date         => l_get_rec.yotei_dt
--                                     ,iv_date_format  => 'YYYY/MM/DD'
--        );
--        --リターンステータスが「FALSE」の場合,例外処理を行う
--        IF (lb_check_date = cb_false) THEN
--          /* 2009.11.27 K.Satomura E_本稼動_00118 START */
--          --lv_sub_msg := xxccp_common_pkg.get_msg(
--          --                       iv_application  => cv_app_name        -- アプリケーション短縮名
--          --                      ,iv_name         => cv_tkn_number_15   -- メッセージコード
--          --                      ,iv_token_name1  => cv_tkn_item        -- トークンコード1
--          --                      /* 2009.07.21 K.Hosoi 0000475対応 START */
----        --                        ,iv_token_value1 => cv_lst_yr_mnth_tkn -- トークン値1項目名
--          --                      ,iv_token_value1 => cv_yotei_dt_tkn -- トークン値1項目名
--          --                      /* 2009.07.21 K.Hosoi 0000475対応 END */
--          --                      ,iv_token_name2  => cv_tkn_value       -- トークンコード2
--          --                      ,iv_token_value2 => l_get_rec.yotei_dt -- トークン値2値
--          --);
--          --lv_sub_buf  := lv_sub_msg;
--          --RAISE select_error_expt;
--          l_get_rec.yotei_dt := NULL;
--          /* 2009.11.27 K.Satomura E_本稼動_00118 END */
--        END IF;
--        --
--        -- 最終作業完了日
--        lb_check_date := xxcso_util_common_pkg.check_date(
--                                      iv_date         => l_get_rec.kanryo_dt
--                                     ,iv_date_format  => 'YYYY/MM/DD'
--        );
--        --リターンステータスが「FALSE」の場合,例外処理を行う
--        IF (lb_check_date = cb_false) THEN
--          /* 2009.11.27 K.Satomura E_本稼動_00118 START */
--          --lv_sub_msg := xxccp_common_pkg.get_msg(
--          --                       iv_application  => cv_app_name         -- アプリケーション短縮名
--          --                      ,iv_name         => cv_tkn_number_15    -- メッセージコード
--          --                      ,iv_token_name1  => cv_tkn_item         -- トークンコード1
--          --                      /* 2009.07.21 K.Hosoi 0000475対応 START */
----        --                        ,iv_token_value1 => cv_lst_yr_mnth_tkn  -- トークン値1項目名
--          --                      ,iv_token_value1 => cv_kanryo_dt_tkn    -- トークン値1項目名
--          --                      /* 2009.07.21 K.Hosoi 0000475対応 START */
--          --                      ,iv_token_name2  => cv_tkn_value        -- トークンコード2
--          --                      ,iv_token_value2 => l_get_rec.kanryo_dt -- トークン値2値
--          --);
--          --lv_sub_buf  := lv_sub_msg;
--          --RAISE select_error_expt;
--          l_get_rec.kanryo_dt := NULL;
--          /* 2009.11.27 K.Satomura E_本稼動_00118 END */
--        END IF;
--        --
--        /* 2009.05.18 K.Satomura T1_1049対応 END */
--
-- 2011/10/14 v1.19 T.Yoshimoto Del End E_本稼動_05929
--
-- 2011/10/14 v1.19 T.Yoshimoto Add Start E_本稼動_05929
        -- ==========================
        -- == 機番
        -- ==========================
        -- 書式チェック
        lb_check_date := xxccp_common_pkg.chk_single_byte(
                                 iv_chk_char => l_get_rec.vendor_number
                                 );
        -- 書式チェックがOK且つ、桁数チェックがNGの場合
        IF (( lb_check_date = cb_true)
          AND ( LENGTHB(l_get_rec.vendor_number) > 14 ) ) THEN
--
          lb_check_date := cb_false;
--
        END IF;
--
        -- トークン(message)に項目名を設定
        IF ( lb_check_date = cb_false ) THEN
--
          IF lv_token_msg IS NOT NULL THEN
            lv_token_msg := lv_token_msg || cv_comma;
          END IF;
--
          lv_token_msg := lv_token_msg || cv_kiban_ja;
--
        END IF;
--
        -- ==========================
        -- == カウンターNo
        -- ==========================
        -- 書式チェック
        lb_check_date := xxccp_common_pkg.chk_number(
                                 iv_check_char => l_get_rec.count_no
                                 );
        -- 書式チェックがOK且つ、桁数チェックがNGの場合
        IF (( lb_check_date = cb_true)
          AND ( LENGTHB(l_get_rec.count_no) > 6 ) ) THEN
--
          lb_check_date := cb_false;
--
        END IF;
--
        -- トークン(message)に項目名を設定
        IF ( lb_check_date = cb_false ) THEN
--
          IF lv_token_msg IS NOT NULL THEN
            lv_token_msg := lv_token_msg || cv_comma;
          END IF;
--
          lv_token_msg := lv_token_msg || cv_count_no_ja;
--
        END IF;
--
        -- ==========================
        -- == 地区コード
        -- ==========================
        -- 書式チェック
        lb_check_date := xxccp_common_pkg.chk_single_byte(
                                 iv_chk_char => l_get_rec.chiku_cd
                                 );
        -- 書式チェックがOK且つ、桁数チェックがNGの場合
        IF (( lb_check_date = cb_true)
          AND ( LENGTHB(l_get_rec.chiku_cd) > 6 ) ) THEN
--
          lb_check_date := cb_false;
--
        END IF;
--
        -- トークン(message)に項目名を設定
        IF ( lb_check_date = cb_false ) THEN
--
          IF lv_token_msg IS NOT NULL THEN
            lv_token_msg := lv_token_msg || cv_comma;
          END IF;
--
          lv_token_msg := lv_token_msg || cv_chiku_cd_ja;
--
        END IF;
--
        -- ==========================
        -- == 作業会社コード
        -- ==========================
        -- 書式チェック
        lb_check_date := xxccp_common_pkg.chk_single_byte(
                                 iv_chk_char => l_get_rec.sagyougaisya_cd
                                 );
        -- 書式チェックがOK且つ、桁数チェックがNGの場合
        IF (( lb_check_date = cb_true)
          AND ( LENGTHB(l_get_rec.sagyougaisya_cd) > 6 ) ) THEN
--
          lb_check_date := cb_false;
--
        END IF;
--
        -- トークン(message)に項目名を設定
        IF ( lb_check_date = cb_false ) THEN
--
          IF lv_token_msg IS NOT NULL THEN
            lv_token_msg := lv_token_msg || cv_comma;
          END IF;
--
          lv_token_msg := lv_token_msg || cv_sagyougaisya_cd_ja;
--
        END IF;
--
        -- ==========================
        -- == 事業所コード
        -- ==========================
        -- 書式チェック
        lb_check_date := xxccp_common_pkg.chk_single_byte(
                                 iv_chk_char => l_get_rec.jigyousyo_cd
                                 );
        -- 書式チェックがOK且つ、桁数チェックがNGの場合
        IF (( lb_check_date = cb_true)
          AND ( LENGTHB(l_get_rec.jigyousyo_cd) > 4 ) ) THEN
--
          lb_check_date := cb_false;
--
        END IF;
--
        -- トークン(message)に項目名を設定
        IF ( lb_check_date = cb_false ) THEN
--
          IF lv_token_msg IS NOT NULL THEN
            lv_token_msg := lv_token_msg || cv_comma;
          END IF;
--
          lv_token_msg := lv_token_msg || cv_jigyousyo_cd_ja;
--
        END IF;
--
        -- ==========================
        -- == 最終作業伝票No
        -- ==========================
        -- 書式チェック
        lb_check_date := xxccp_common_pkg.chk_number(
                                 iv_check_char => l_get_rec.den_no
                                 );
        -- 書式チェックがOK且つ、桁数チェックがNGの場合
        IF (( lb_check_date = cb_true)
          AND ( LENGTHB(l_get_rec.den_no) > 12 ) ) THEN
--
          lb_check_date := cb_false;
--
        END IF;
--
        -- トークン(message)に項目名を設定
        IF ( lb_check_date = cb_false ) THEN
--
          IF lv_token_msg IS NOT NULL THEN
            lv_token_msg := lv_token_msg || cv_comma;
          END IF;
--
          lv_token_msg := lv_token_msg || cv_den_no_ja;
--
        END IF;
--
        -- ==========================
        -- == 最終作業区分
        -- ==========================
        -- 書式チェック
        lb_check_date := xxccp_common_pkg.chk_number(
                                 iv_check_char => l_get_rec.job_kbn
                                 );
        -- 書式チェックがOK且つ、桁数チェックがNGの場合
        IF (( lb_check_date = cb_true)
          AND ( LENGTHB(l_get_rec.job_kbn) > 2 ) ) THEN
--
          lb_check_date := cb_false;
--
        END IF;
--
        -- トークン(message)に項目名を設定
        IF ( lb_check_date = cb_false ) THEN
--
          IF lv_token_msg IS NOT NULL THEN
            lv_token_msg := lv_token_msg || cv_comma;
          END IF;
--
          lv_token_msg := lv_token_msg || cv_job_kbn_ja;
--
        END IF;
--
        -- ==========================
        -- == 最終作業進捗
        -- ==========================
        -- 書式チェック
        lb_check_date := xxccp_common_pkg.chk_number(
                                 iv_check_char => l_get_rec.sintyoku_kbn
                                 );
        -- 書式チェックがOK且つ、桁数チェックがNGの場合
        IF (( lb_check_date = cb_true)
          AND ( LENGTHB(l_get_rec.sintyoku_kbn) > 1 ) ) THEN
--
          lb_check_date := cb_false;
--
        END IF;
--
        -- トークン(message)に項目名を設定
        IF ( lb_check_date = cb_false ) THEN
--
          IF lv_token_msg IS NOT NULL THEN
            lv_token_msg := lv_token_msg || cv_comma;
          END IF;
--
          lv_token_msg := lv_token_msg || cv_sintyoku_kbn_ja;
--
        END IF;
--
        -- ==========================
        -- == 最終作業完了予定日
        -- ==========================
        -- 書式チェック
        lb_check_date := xxcso_util_common_pkg.check_date(
                                        iv_date         => l_get_rec.yotei_dt
                                       ,iv_date_format  => 'YYYY/MM/DD'
                                       );
        -- トークン(message)に項目名を設定
        IF ( lb_check_date = cb_false ) THEN
--
          IF lv_token_msg IS NOT NULL THEN
            lv_token_msg := lv_token_msg || cv_comma;
          END IF;
--
          lv_token_msg := lv_token_msg || cv_yotei_dt_ja;
--
        END IF;
--
        -- ==========================
        -- == 最終作業完了日
        -- ==========================
        -- 書式チェック
        lb_check_date := xxcso_util_common_pkg.check_date(
                                        iv_date         => l_get_rec.kanryo_dt
                                       ,iv_date_format  => 'YYYY/MM/DD'
                                       );
        -- トークン(message)に項目名を設定
        IF ( lb_check_date = cb_false ) THEN
--
          IF lv_token_msg IS NOT NULL THEN
            lv_token_msg := lv_token_msg || cv_comma;
          END IF;
--
          lv_token_msg := lv_token_msg || cv_kanryo_dt_ja;
--
        END IF;
--
        -- ==========================
        -- == 最終整備内容
        -- ==========================
        -- 書式チェック
        lb_check_date := xxccp_common_pkg.chk_number(
                                 iv_check_char => l_get_rec.sagyo_level
                                 );
        -- 書式チェックがOK且つ、桁数チェックがNGの場合
        IF (( lb_check_date = cb_true)
          AND ( LENGTHB(l_get_rec.sagyo_level) > 1 ) ) THEN
--
          lb_check_date := cb_false;
--
        END IF;
--
        -- トークン(message)に項目名を設定
        IF ( lb_check_date = cb_false ) THEN
--
          IF lv_token_msg IS NOT NULL THEN
            lv_token_msg := lv_token_msg || cv_comma;
          END IF;
--
          lv_token_msg := lv_token_msg || cv_sagyo_level_ja;
--
        END IF;
--
        -- ==========================
        -- == 最終設置伝票No
        -- ==========================
        -- 書式チェック
        lb_check_date := xxccp_common_pkg.chk_number(
                                 iv_check_char => l_get_rec.den_no2
                                 );
        -- 書式チェックがOK且つ、桁数チェックがNGの場合
        IF (( lb_check_date = cb_true)
          AND ( LENGTHB(l_get_rec.den_no2) > 12 ) ) THEN
--
          lb_check_date := cb_false;
--
        END IF;
--
        -- トークン(message)に項目名を設定
        IF ( lb_check_date = cb_false ) THEN
--
          IF lv_token_msg IS NOT NULL THEN
            lv_token_msg := lv_token_msg || cv_comma;
          END IF;
--
          lv_token_msg := lv_token_msg || cv_den_no2_ja;
--
        END IF;
--
        -- ==========================
        -- == 最終設置区分
        -- ==========================
        -- 書式チェック
        lb_check_date := xxccp_common_pkg.chk_number(
                                 iv_check_char => l_get_rec.job_kbn2
                                 );
        -- 書式チェックがOK且つ、桁数チェックがNGの場合
        IF (( lb_check_date = cb_true)
          AND ( LENGTHB(l_get_rec.job_kbn2) > 2 ) ) THEN
--
          lb_check_date := cb_false;
--
        END IF;
--
        -- トークン(message)に項目名を設定
        IF ( lb_check_date = cb_false ) THEN
--
          IF lv_token_msg IS NOT NULL THEN
            lv_token_msg := lv_token_msg || cv_comma;
          END IF;
--
          lv_token_msg := lv_token_msg || cv_job_kbn2_ja;
--
        END IF;
--
        -- ==========================
        -- == 最終設置進捗
        -- ==========================
        -- 書式チェック
        lb_check_date := xxccp_common_pkg.chk_number(
                                 iv_check_char => l_get_rec.sintyoku_kbn2
                                 );
        -- 書式チェックがOK且つ、桁数チェックがNGの場合
        IF (( lb_check_date = cb_true)
          AND ( LENGTHB(l_get_rec.sintyoku_kbn2) > 1 ) ) THEN
--
          lb_check_date := cb_false;
--
        END IF;
--
        -- トークン(message)に項目名を設定
        IF ( lb_check_date = cb_false ) THEN
--
          IF lv_token_msg IS NOT NULL THEN
            lv_token_msg := lv_token_msg || cv_comma;
          END IF;
--
          lv_token_msg := lv_token_msg || cv_sintyoku_kbn2_ja;
--
        END IF;
--
        -- ==========================
        -- == 機器状態1
        -- ==========================
        -- 書式チェック
        lb_check_date := xxccp_common_pkg.chk_number(
                                 iv_check_char => l_get_rec.jotai_kbn1
                                 );
        -- 書式チェックがOK且つ、桁数チェックがNGの場合
        IF (( lb_check_date = cb_true)
          AND ( LENGTHB(l_get_rec.jotai_kbn1) > 2 ) ) THEN
--
          lb_check_date := cb_false;
--
        END IF;
--
        -- トークン(message)に項目名を設定
        IF ( lb_check_date = cb_false ) THEN
--
          IF lv_token_msg IS NOT NULL THEN
            lv_token_msg := lv_token_msg || cv_comma;
          END IF;
--
          lv_token_msg := lv_token_msg || cv_jotai_kbn1_ja;
--
        END IF;
--
        -- ==========================
        -- == 機器状態2
        -- ==========================
        -- 書式チェック
        lb_check_date := xxccp_common_pkg.chk_number(
                                 iv_check_char => l_get_rec.jotai_kbn2
                                 );
        -- 書式チェックがOK且つ、桁数チェックがNGの場合
        IF (( lb_check_date = cb_true)
          AND ( LENGTHB(l_get_rec.jotai_kbn2) > 2 ) ) THEN
--
          lb_check_date := cb_false;
--
        END IF;
--
        -- トークン(message)に項目名を設定
        IF ( lb_check_date = cb_false ) THEN
--
          IF lv_token_msg IS NOT NULL THEN
            lv_token_msg := lv_token_msg || cv_comma;
          END IF;
--
          lv_token_msg := lv_token_msg || cv_jotai_kbn2_ja;
--
        END IF;
--
        -- ==========================
        -- == 機器状態3
        -- ==========================
        -- 書式チェック
        lb_check_date := xxccp_common_pkg.chk_number(
                                 iv_check_char => l_get_rec.jotai_kbn3
                                 );
        -- 書式チェックがOK且つ、桁数チェックがNGの場合
        IF (( lb_check_date = cb_true)
          AND ( LENGTHB(l_get_rec.jotai_kbn3) > 2 ) ) THEN
--
          lb_check_date := cb_false;
--
        END IF;
--
        -- トークン(message)に項目名を設定
        IF ( lb_check_date = cb_false ) THEN
--
          IF lv_token_msg IS NOT NULL THEN
            lv_token_msg := lv_token_msg || cv_comma;
          END IF;
--
          lv_token_msg := lv_token_msg || cv_jotai_kbn3_ja;
--
        END IF;
--
        -- ==========================
        -- == 入庫日
        -- ==========================
        -- 書式チェック
        lb_check_date := xxcso_util_common_pkg.check_date(
                                        iv_date         => l_get_rec.nyuko_dt
                                       ,iv_date_format  => cv_yymmddhhmiss
                                       );
        -- トークン(message)に項目名を設定
        IF ( lb_check_date = cb_false ) THEN
--
          IF lv_token_msg IS NOT NULL THEN
            lv_token_msg := lv_token_msg || cv_comma;
          END IF;
--
          lv_token_msg := lv_token_msg || cv_nyuko_dt_ja;
--
        END IF;
--
        -- ==========================
        -- == 引揚会社コード
        -- ==========================
        -- 書式チェック
        lb_check_date := xxccp_common_pkg.chk_single_byte(
                                 iv_chk_char => l_get_rec.hikisakigaisya_cd
                                 );
        -- 書式チェックがOK且つ、桁数チェックがNGの場合
        IF (( lb_check_date = cb_true)
          AND ( LENGTHB(l_get_rec.hikisakigaisya_cd) > 6 ) ) THEN
--
          lb_check_date := cb_false;
--
        END IF;
--
        -- トークン(message)に項目名を設定
        IF ( lb_check_date = cb_false ) THEN
--
          IF lv_token_msg IS NOT NULL THEN
            lv_token_msg := lv_token_msg || cv_comma;
          END IF;
--
          lv_token_msg := lv_token_msg || cv_hikisakigaisya_cd_ja;
--
        END IF;
--
        -- ==========================
        -- == 引揚事業所コード
        -- ==========================
        -- 書式チェック
        lb_check_date := xxccp_common_pkg.chk_single_byte(
                                 iv_chk_char => l_get_rec.hikisakijigyosyo_cd
                                 );
        -- 書式チェックがOK且つ、桁数チェックがNGの場合
        IF (( lb_check_date = cb_true)
          AND ( LENGTHB(l_get_rec.hikisakijigyosyo_cd) > 4 ) ) THEN
--
          lb_check_date := cb_false;
--
        END IF;
--
        -- トークン(message)に項目名を設定
        IF ( lb_check_date = cb_false ) THEN
--
          IF lv_token_msg IS NOT NULL THEN
            lv_token_msg := lv_token_msg || cv_comma;
          END IF;
--
          lv_token_msg := lv_token_msg || cv_hikisakijigyosyo_cd_ja;
--
        END IF;
--
        -- ==========================
        -- == 設置先担当者名
        -- ==========================
        lb_check_date := cb_true;    -- 初期化
        -- 桁数チェック
        IF ( LENGTHB(l_get_rec.setti_tanto) > 20 ) THEN
--
          lb_check_date := cb_false;
--
        END IF;
--
        -- トークン(message)に項目名を設定
        IF ( lb_check_date = cb_false ) THEN
--
          IF lv_token_msg IS NOT NULL THEN
            lv_token_msg := lv_token_msg || cv_comma;
          END IF;
--
          lv_token_msg := lv_token_msg || cv_setti_tanto_ja;
--
        END IF;
--
        -- ==========================
        -- == 設置先TEL1
        -- ==========================
        -- 書式チェック
        lb_check_date := xxccp_common_pkg.chk_single_byte(
                                 iv_chk_char => l_get_rec.setti_tel1
                                 );
        -- 書式チェックがOK且つ、桁数チェックがNGの場合
        IF (( lb_check_date = cb_true)
          AND ( LENGTHB(l_get_rec.setti_tel1) > 6 ) ) THEN
--
          lb_check_date := cb_false;
--
        END IF;
--
        -- トークン(message)に項目名を設定
        IF ( lb_check_date = cb_false ) THEN
--
          IF lv_token_msg IS NOT NULL THEN
            lv_token_msg := lv_token_msg || cv_comma;
          END IF;
--
          lv_token_msg := lv_token_msg || cv_setti_tel1_ja;
--
        END IF;
--
        -- ==========================
        -- == 設置先TEL2
        -- ==========================
        -- 書式チェック
        lb_check_date := xxccp_common_pkg.chk_single_byte(
                                 iv_chk_char => l_get_rec.setti_tel2
                                 );
        -- 書式チェックがOK且つ、桁数チェックがNGの場合
        IF (( lb_check_date = cb_true)
          AND ( LENGTHB(l_get_rec.setti_tel2) > 6 ) ) THEN
--
          lb_check_date := cb_false;
--
        END IF;
--
        -- トークン(message)に項目名を設定
        IF ( lb_check_date = cb_false ) THEN
--
          IF lv_token_msg IS NOT NULL THEN
            lv_token_msg := lv_token_msg || cv_comma;
          END IF;
--
          lv_token_msg := lv_token_msg || cv_setti_tel2_ja;
--
        END IF;
--
        -- ==========================
        -- == 設置先TEL3
        -- ==========================
        -- 書式チェック
        lb_check_date := xxccp_common_pkg.chk_single_byte(
                                 iv_chk_char => l_get_rec.setti_tel3
                                 );
        -- 書式チェックがOK且つ、桁数チェックがNGの場合
        IF (( lb_check_date = cb_true)
          AND ( LENGTHB(l_get_rec.setti_tel3) > 6 ) ) THEN
--
          lb_check_date := cb_false;
--
        END IF;
--
        -- トークン(message)に項目名を設定
        IF ( lb_check_date = cb_false ) THEN
--
          IF lv_token_msg IS NOT NULL THEN
            lv_token_msg := lv_token_msg || cv_comma;
          END IF;
--
          lv_token_msg := lv_token_msg || cv_setti_tel3_ja;
--
        END IF;
--
        -- ==========================
        -- == 廃棄決裁日
        -- ==========================
        -- 書式チェック
        lb_check_date := xxcso_util_common_pkg.check_date(
                                        iv_date         => l_get_rec.haikikessai_dt
                                       ,iv_date_format  => cv_yymmdd
                                       );
        -- トークン(message)に項目名を設定
        IF ( lb_check_date = cb_false ) THEN
--
          IF lv_token_msg IS NOT NULL THEN
            lv_token_msg := lv_token_msg || cv_comma;
          END IF;
--
          lv_token_msg := lv_token_msg || cv_haikikessai_dt_ja;
--
        END IF;
--
        -- ==========================
        -- == 転売廃棄業者
        -- ==========================
        -- 書式チェック
        lb_check_date := xxccp_common_pkg.chk_single_byte(
                                 iv_chk_char => l_get_rec.tenhai_tanto
                                 );
        -- 書式チェックがOK且つ、桁数チェックがNGの場合
        IF (( lb_check_date = cb_true)
          AND ( LENGTHB(l_get_rec.tenhai_tanto) > 6 ) ) THEN
--
          lb_check_date := cb_false;
--
        END IF;
--
        -- トークン(message)に項目名を設定
        IF ( lb_check_date = cb_false ) THEN
--
          IF lv_token_msg IS NOT NULL THEN
            lv_token_msg := lv_token_msg || cv_comma;
          END IF;
--
          lv_token_msg := lv_token_msg || cv_tenhai_tanto_ja;
--
        END IF;
--
        -- ==========================
        -- == 転売廃棄伝票No
        -- ==========================
        -- 書式チェック
        lb_check_date := xxccp_common_pkg.chk_number(
                                 iv_check_char => l_get_rec.tenhai_den_no
                                 );
        -- 書式チェックがOK且つ、桁数チェックがNGの場合
        IF (( lb_check_date = cb_true)
          AND ( LENGTHB(l_get_rec.tenhai_den_no) > 12 ) ) THEN
--
          lb_check_date := cb_false;
--
        END IF;
--
        -- トークン(message)に項目名を設定
        IF ( lb_check_date = cb_false ) THEN
--
          IF lv_token_msg IS NOT NULL THEN
            lv_token_msg := lv_token_msg || cv_comma;
          END IF;
--
          lv_token_msg := lv_token_msg || cv_tenhai_den_no_ja;
--
        END IF;
--
        -- ==========================
        -- == 所有者
        -- ==========================
        -- 書式チェック
        lb_check_date := xxccp_common_pkg.chk_single_byte(
                                 iv_chk_char => l_get_rec.syoyu_cd
                                 );
        -- 書式チェックがOK且つ、桁数チェックがNGの場合
        IF (( lb_check_date = cb_true)
          AND ( LENGTHB(l_get_rec.syoyu_cd) > 4 ) ) THEN
--
          lb_check_date := cb_false;
--
        END IF;
--
        -- トークン(message)に項目名を設定
        IF ( lb_check_date = cb_false ) THEN
--
          IF lv_token_msg IS NOT NULL THEN
            lv_token_msg := lv_token_msg || cv_comma;
          END IF;
--
          lv_token_msg := lv_token_msg || cv_syoyu_cd_ja;
--
        END IF;
--
        -- ==========================
        -- == 転売廃棄状況フラグ
        -- ==========================
        -- 書式チェック
        lb_check_date := xxccp_common_pkg.chk_number(
                                 iv_check_char => l_get_rec.tenhai_flg
                                 );
        -- 書式チェックがOK且つ、桁数チェックがNGの場合
        IF (( lb_check_date = cb_true)
          AND ( LENGTHB(l_get_rec.tenhai_flg) > 1 ) ) THEN
--
          lb_check_date := cb_false;
--
        END IF;
--
        -- トークン(message)に項目名を設定
        IF ( lb_check_date = cb_false ) THEN
--
          IF lv_token_msg IS NOT NULL THEN
            lv_token_msg := lv_token_msg || cv_comma;
          END IF;
--
          lv_token_msg := lv_token_msg || cv_tenhai_flg_ja;
--
        END IF;
--
        -- ==========================
        -- == 転売完了区分
        -- ==========================
        -- 書式チェック
        lb_check_date := xxccp_common_pkg.chk_number(
                                 iv_check_char => l_get_rec.kanryo_kbn
                                 );
        -- 書式チェックがOK且つ、桁数チェックがNGの場合
        IF (( lb_check_date = cb_true)
          AND ( LENGTHB(l_get_rec.kanryo_kbn) > 1 ) ) THEN
--
          lb_check_date := cb_false;
--
        END IF;
--
        -- トークン(message)に項目名を設定
        IF ( lb_check_date = cb_false ) THEN
--
          IF lv_token_msg IS NOT NULL THEN
            lv_token_msg := lv_token_msg || cv_comma;
          END IF;
--
          lv_token_msg := lv_token_msg || cv_kanryo_kbn_ja;
--
        END IF;
--
        -- ==========================
        -- == 削除フラグ
        -- ==========================
        -- 書式チェック
        lb_check_date := xxccp_common_pkg.chk_number(
                                 iv_check_char => l_get_rec.sakujo_flg
                                 );
        -- 書式チェックがOK且つ、桁数チェックがNGの場合
        IF (( lb_check_date = cb_true)
          AND ( LENGTHB(l_get_rec.sakujo_flg) > 1 ) ) THEN
--
          lb_check_date := cb_false;
--
        END IF;
--
        -- トークン(message)に項目名を設定
        IF ( lb_check_date = cb_false ) THEN
--
          IF lv_token_msg IS NOT NULL THEN
            lv_token_msg := lv_token_msg || cv_comma;
          END IF;
--
          lv_token_msg := lv_token_msg || cv_sakujo_flg_ja;
--
        END IF;
--
        -- ==========================
        -- == 最終顧客コード
        -- ==========================
        -- 書式チェック
        lb_check_date := xxccp_common_pkg.chk_single_byte(
                                 iv_chk_char => l_get_rec.ven_kyaku_last
                                 );
        -- 書式チェックがOK且つ、桁数チェックがNGの場合
        IF (( lb_check_date = cb_true)
          AND ( LENGTHB(l_get_rec.ven_kyaku_last) > 9 ) ) THEN
--
          lb_check_date := cb_false;
--
        END IF;
--
        -- トークン(message)に項目名を設定
        IF ( lb_check_date = cb_false ) THEN
--
          IF lv_token_msg IS NOT NULL THEN
            lv_token_msg := lv_token_msg || cv_comma;
          END IF;
--
          lv_token_msg := lv_token_msg || cv_ven_kyaku_last_ja;
--
        END IF;
--
        -- ==========================
        -- == 他社コード1
        -- ==========================
        -- 書式チェック
        lb_check_date := xxccp_common_pkg.chk_number(
                                 iv_check_char => l_get_rec.ven_tasya_cd01
                                 );
        -- 書式チェックがOK且つ、桁数チェックがNGの場合
        IF (( lb_check_date = cb_true)
          AND ( LENGTHB(l_get_rec.ven_tasya_cd01) > 2 ) ) THEN
--
          lb_check_date := cb_false;
--
        END IF;
--
        -- トークン(message)に項目名を設定
        IF ( lb_check_date = cb_false ) THEN
--
          IF lv_token_msg IS NOT NULL THEN
            lv_token_msg := lv_token_msg || cv_comma;
          END IF;
--
          lv_token_msg := lv_token_msg || cv_ven_tasya_cd01_ja;
--
        END IF;
--
        -- ==========================
        -- == 他社台数1
        -- ==========================
        -- 書式チェック
        lb_check_date := xxccp_common_pkg.chk_number(
                                 iv_check_char => l_get_rec.ven_tasya_daisu01
                                 );
        -- 書式チェックがOK且つ、桁数チェックがNGの場合
        IF (( lb_check_date = cb_true)
          AND ( LENGTHB(l_get_rec.ven_tasya_daisu01) > 1 ) ) THEN
--
          lb_check_date := cb_false;
--
        END IF;
--
        -- トークン(message)に項目名を設定
        IF ( lb_check_date = cb_false ) THEN
--
          IF lv_token_msg IS NOT NULL THEN
            lv_token_msg := lv_token_msg || cv_comma;
          END IF;
--
          lv_token_msg := lv_token_msg || cv_ven_tasya_daisu01_ja;
--
        END IF;
--
        -- ==========================
        -- == 他社コード2
        -- ==========================
        -- 書式チェック
        lb_check_date := xxccp_common_pkg.chk_number(
                                 iv_check_char => l_get_rec.ven_tasya_cd02
                                 );
        -- 書式チェックがOK且つ、桁数チェックがNGの場合
        IF (( lb_check_date = cb_true)
          AND ( LENGTHB(l_get_rec.ven_tasya_cd02) > 2 ) ) THEN
--
          lb_check_date := cb_false;
--
        END IF;
--
        -- トークン(message)に項目名を設定
        IF ( lb_check_date = cb_false ) THEN
--
          IF lv_token_msg IS NOT NULL THEN
            lv_token_msg := lv_token_msg || cv_comma;
          END IF;
--
          lv_token_msg := lv_token_msg || cv_ven_tasya_cd02_ja;
--
        END IF;
--
        -- ==========================
        -- == 他社台数2
        -- ==========================
        -- 書式チェック
        lb_check_date := xxccp_common_pkg.chk_number(
                                 iv_check_char => l_get_rec.ven_tasya_daisu02
                                 );
        -- 書式チェックがOK且つ、桁数チェックがNGの場合
        IF (( lb_check_date = cb_true)
          AND ( LENGTHB(l_get_rec.ven_tasya_daisu02) > 1 ) ) THEN
--
          lb_check_date := cb_false;
--
        END IF;
--
        -- トークン(message)に項目名を設定
        IF ( lb_check_date = cb_false ) THEN
--
          IF lv_token_msg IS NOT NULL THEN
            lv_token_msg := lv_token_msg || cv_comma;
          END IF;
--
          lv_token_msg := lv_token_msg || cv_ven_tasya_daisu02_ja;
--
        END IF;
--
        -- ==========================
        -- == 他社コード3
        -- ==========================
        -- 書式チェック
        lb_check_date := xxccp_common_pkg.chk_number(
                                 iv_check_char => l_get_rec.ven_tasya_cd03
                                 );
        -- 書式チェックがOK且つ、桁数チェックがNGの場合
        IF (( lb_check_date = cb_true)
          AND ( LENGTHB(l_get_rec.ven_tasya_cd03) > 2 ) ) THEN
--
          lb_check_date := cb_false;
--
        END IF;
--
        -- トークン(message)に項目名を設定
        IF ( lb_check_date = cb_false ) THEN
--
          IF lv_token_msg IS NOT NULL THEN
            lv_token_msg := lv_token_msg || cv_comma;
          END IF;
--
          lv_token_msg := lv_token_msg || cv_ven_tasya_cd03_ja;
--
        END IF;
--
        -- ==========================
        -- == 他社台数3
        -- ==========================
        -- 書式チェック
        lb_check_date := xxccp_common_pkg.chk_number(
                                 iv_check_char => l_get_rec.ven_tasya_daisu03
                                 );
        -- 書式チェックがOK且つ、桁数チェックがNGの場合
        IF (( lb_check_date = cb_true)
          AND ( LENGTHB(l_get_rec.ven_tasya_daisu03) > 1 ) ) THEN
--
          lb_check_date := cb_false;
--
        END IF;
--
        -- トークン(message)に項目名を設定
        IF ( lb_check_date = cb_false ) THEN
--
          IF lv_token_msg IS NOT NULL THEN
            lv_token_msg := lv_token_msg || cv_comma;
          END IF;
--
          lv_token_msg := lv_token_msg || cv_ven_tasya_daisu03_ja;
--
        END IF;
--
        -- ==========================
        -- == 他社コード4
        -- ==========================
        -- 書式チェック
        lb_check_date := xxccp_common_pkg.chk_number(
                                 iv_check_char => l_get_rec.ven_tasya_cd04
                                 );
        -- 書式チェックがOK且つ、桁数チェックがNGの場合
        IF (( lb_check_date = cb_true)
          AND ( LENGTHB(l_get_rec.ven_tasya_cd04) > 2 ) ) THEN
--
          lb_check_date := cb_false;
--
        END IF;
--
        -- トークン(message)に項目名を設定
        IF ( lb_check_date = cb_false ) THEN
--
          IF lv_token_msg IS NOT NULL THEN
            lv_token_msg := lv_token_msg || cv_comma;
          END IF;
--
          lv_token_msg := lv_token_msg || cv_ven_tasya_cd04_ja;
--
        END IF;
--
        -- ==========================
        -- == 他社台数4
        -- ==========================
        -- 書式チェック
        lb_check_date := xxccp_common_pkg.chk_number(
                                 iv_check_char => l_get_rec.ven_tasya_daisu04
                                 );
        -- 書式チェックがOK且つ、桁数チェックがNGの場合
        IF (( lb_check_date = cb_true)
          AND ( LENGTHB(l_get_rec.ven_tasya_daisu04) > 1 ) ) THEN
--
          lb_check_date := cb_false;
--
        END IF;
--
        -- トークン(message)に項目名を設定
        IF ( lb_check_date = cb_false ) THEN
--
          IF lv_token_msg IS NOT NULL THEN
            lv_token_msg := lv_token_msg || cv_comma;
          END IF;
--
          lv_token_msg := lv_token_msg || cv_ven_tasya_daisu04_ja;
--
        END IF;
--
        -- ==========================
        -- == 他社コード5
        -- ==========================
        -- 書式チェック
        lb_check_date := xxccp_common_pkg.chk_number(
                                 iv_check_char => l_get_rec.ven_tasya_cd05
                                 );
        -- 書式チェックがOK且つ、桁数チェックがNGの場合
        IF (( lb_check_date = cb_true)
          AND ( LENGTHB(l_get_rec.ven_tasya_cd05) > 2 ) ) THEN
--
          lb_check_date := cb_false;
--
        END IF;
--
        -- トークン(message)に項目名を設定
        IF ( lb_check_date = cb_false ) THEN
--
          IF lv_token_msg IS NOT NULL THEN
            lv_token_msg := lv_token_msg || cv_comma;
          END IF;
--
          lv_token_msg := lv_token_msg || cv_ven_tasya_cd05_ja;
--
        END IF;
--
        -- ==========================
        -- == 他社台数5
        -- ==========================
        -- 書式チェック
        lb_check_date := xxccp_common_pkg.chk_number(
                                 iv_check_char => l_get_rec.ven_tasya_daisu05
                                 );
        -- 書式チェックがOK且つ、桁数チェックがNGの場合
        IF (( lb_check_date = cb_true)
          AND ( LENGTHB(l_get_rec.ven_tasya_daisu05) > 1 ) ) THEN
--
          lb_check_date := cb_false;
--
        END IF;
--
        -- トークン(message)に項目名を設定
        IF ( lb_check_date = cb_false ) THEN
--
          IF lv_token_msg IS NOT NULL THEN
            lv_token_msg := lv_token_msg || cv_comma;
          END IF;
--
          lv_token_msg := lv_token_msg || cv_ven_tasya_daisu05_ja;
--
        END IF;
--
        -- ==========================
        -- == 廃棄フラグ
        -- ==========================
        -- 書式チェック
        lb_check_date := xxccp_common_pkg.chk_single_byte(
                                 iv_chk_char => l_get_rec.ven_haiki_flg
                                 );
        -- 書式チェックがOK且つ、桁数チェックがNGの場合
        IF (( lb_check_date = cb_true)
          AND ( LENGTHB(l_get_rec.ven_haiki_flg) > 1 ) ) THEN
--
          lb_check_date := cb_false;
--
        END IF;
--
        -- トークン(message)に項目名を設定
        IF ( lb_check_date = cb_false ) THEN
--
          IF lv_token_msg IS NOT NULL THEN
            lv_token_msg := lv_token_msg || cv_comma;
          END IF;
--
          lv_token_msg := lv_token_msg || cv_ven_haiki_flg_ja;
--
        END IF;
--
        -- ==========================
        -- == 資産区分
        -- ==========================
        -- 書式チェック
        lb_check_date := xxccp_common_pkg.chk_single_byte(
                                 iv_chk_char => l_get_rec.ven_sisan_kbn
                                 );
        -- 書式チェックがOK且つ、桁数チェックがNGの場合
        IF (( lb_check_date = cb_true)
          AND ( LENGTHB(l_get_rec.ven_sisan_kbn) > 1 ) ) THEN
--
          lb_check_date := cb_false;
--
        END IF;
--
        -- トークン(message)に項目名を設定
        IF ( lb_check_date = cb_false ) THEN
--
          IF lv_token_msg IS NOT NULL THEN
            lv_token_msg := lv_token_msg || cv_comma;
          END IF;
--
          lv_token_msg := lv_token_msg || cv_ven_sisan_kbn_ja;
--
        END IF;
--
        -- ==========================
        -- == 購買日付
        -- ==========================
        -- 書式チェック
        lb_check_date := xxcso_util_common_pkg.check_date(
                                        iv_date         => l_get_rec.ven_kobai_ymd
                                       ,iv_date_format  => cv_yymmddhhmiss
                                       );
        -- トークン(message)に項目名を設定
        IF ( lb_check_date = cb_false ) THEN
--
          IF lv_token_msg IS NOT NULL THEN
            lv_token_msg := lv_token_msg || cv_comma;
          END IF;
--
          lv_token_msg := lv_token_msg || cv_ven_kobai_ymd_ja;
--
        END IF;
--
        -- ==========================
        -- == 購買金額
        -- ==========================
        -- 書式チェック
        lb_check_date := xxccp_common_pkg.chk_number(
                                 iv_check_char => l_get_rec.ven_kobai_kg
                                 );
        -- 書式チェックがOK且つ、桁数チェックがNGの場合
        IF (( lb_check_date = cb_true)
          AND ( LENGTHB(l_get_rec.ven_kobai_kg) > 9 ) ) THEN
--
          lb_check_date := cb_false;
--
        END IF;
--
        -- トークン(message)に項目名を設定
        IF ( lb_check_date = cb_false ) THEN
--
          IF lv_token_msg IS NOT NULL THEN
            lv_token_msg := lv_token_msg || cv_comma;
          END IF;
--
          lv_token_msg := lv_token_msg || cv_ven_kobai_kg_ja;
--
        END IF;
--


        -- ==========================
        -- == 安全設置基準
        -- ==========================
        -- 書式チェック
        lb_check_date := xxccp_common_pkg.chk_single_byte(
                                 iv_chk_char => l_get_rec.safty_level
                                 );
        -- 書式チェックがOK且つ、桁数チェックがNGの場合
        IF (( lb_check_date = cb_true)
          AND ( LENGTHB(l_get_rec.safty_level) > 1 ) ) THEN
--
          lb_check_date := cb_false;
--
        END IF;
--
        -- トークン(message)に項目名を設定
        IF ( lb_check_date = cb_false ) THEN
--
          IF lv_token_msg IS NOT NULL THEN
            lv_token_msg := lv_token_msg || cv_comma;
          END IF;
--
          lv_token_msg := lv_token_msg || cv_safty_level_ja;
--
        END IF;
--
        -- ==========================
        -- == リース区分
        -- ==========================
        -- 書式チェック
        lb_check_date := xxccp_common_pkg.chk_single_byte(
                                 iv_chk_char => l_get_rec.lease_kbn
                                 );
        -- 書式チェックがOK且つ、桁数チェックがNGの場合
        IF (( lb_check_date = cb_true)
          AND ( LENGTHB(l_get_rec.lease_kbn) > 1 ) ) THEN
--
          lb_check_date := cb_false;
--
        END IF;
--
        -- トークン(message)に項目名を設定
        IF ( lb_check_date = cb_false ) THEN
--
          IF lv_token_msg IS NOT NULL THEN
            lv_token_msg := lv_token_msg || cv_comma;
          END IF;
--
          lv_token_msg := lv_token_msg || cv_lease_kbn_ja;
--
        END IF;
--
        -- ==========================
        -- == 先月末設置先顧客コード
        -- ==========================
        -- 書式チェック
        lb_check_date := xxccp_common_pkg.chk_single_byte(
                                 iv_chk_char => l_get_rec.last_inst_cust_code
                                 );
        -- 書式チェックがOK且つ、桁数チェックがNGの場合
        IF (( lb_check_date = cb_true)
          AND ( LENGTHB(l_get_rec.last_inst_cust_code) > 9 ) ) THEN
--
          lb_check_date := cb_false;
--
        END IF;
--
        -- トークン(message)に項目名を設定
        IF ( lb_check_date = cb_false ) THEN
--
          IF lv_token_msg IS NOT NULL THEN
            lv_token_msg := lv_token_msg || cv_comma;
          END IF;
--
          lv_token_msg := lv_token_msg || cv_last_inst_cust_code_ja;
--
        END IF;
--
        -- ==================================
        -- == 書式・桁数チェック結果出力
        -- ==================================
        IF ( lv_token_msg IS NOT NULL ) THEN
--
          -- スキップ件数をカウントアップ
          gn_skip_cnt  := gn_skip_cnt + 1;
--
          RAISE validation_expt;
--
        END IF;
-- 2011/10/14 v1.19 T.Yoshimoto Add End E_本稼動_05929
--
        -- ================================================================
        -- A-6 CSVファイルに出力する関連情報取得
        -- ================================================================
--
-- UPD 20090220 Sai 関連情報抽出失敗時、警告スキップ⇒エラー中断に変更 START
--      get_csv_data(
--         io_get_rec       => l_get_rec        -- 什器マスタデータ
--        ,ov_errbuf        => lv_sub_buf       -- エラー・メッセージ            --# 固定 #
--        ,ov_retcode       => lv_sub_retcode   -- リターン・コード              --# 固定 #
--        ,ov_errmsg        => lv_sub_msg       -- ユーザー・エラー・メッセージ  --# 固定 #
--      );
--      IF (lv_sub_retcode = cv_status_error) THEN
--        RAISE select_error_expt;
--      END IF;
        get_csv_data(
           io_get_rec       => l_get_rec        -- 什器マスタデータ
          ,id_bsnss_mnth    => ld_bsnss_mnth    -- 業務月
          ,ov_errbuf        => lv_errbuf        -- エラー・メッセージ            --# 固定 #
          ,ov_retcode       => lv_retcode       -- リターン・コード              --# 固定 #
          ,ov_errmsg        => lv_errmsg        -- ユーザー・エラー・メッセージ  --# 固定 #
        );
        IF (lv_retcode = cv_status_error) THEN
          RAISE global_process_expt;
        /* 2009.05.25 M.Maruyama T1_1154対応 START */
        ELSIF (lv_retcode = cv_status_warn) THEN
          /* 2009.11.27 K.Satomura E_本稼動_00118対応 START */
          --lv_sub_msg := lv_errmsg;
          --lv_sub_buf := lv_errmsg;
          --RAISE select_error_expt;
          lv_warn_flag := cv_flag_yes;
          --
          /* 2009.11.27 K.Satomura E_本稼動_00118対応 END */
        /* 2009.05.25 M.Maruyama T1_1154対応 START */
        END IF;
-- UPD 20090220 Sai 関連情報抽出失敗時、警告スキップ⇒エラー中断　に変更　END
--
        -- ========================================
        -- A-7. 什器マスタデータCSVファイル出力
        -- ========================================
        create_csv_rec(
          i_get_rec        =>  l_get_rec         -- 什器マスタデータ
         ,ov_errbuf        =>  lv_errbuf         -- エラー・メッセージ
         ,ov_retcode       =>  lv_retcode        -- リターン・コード
         ,ov_errmsg        =>  lv_errmsg         -- ユーザー・エラー・メッセージ
        );
        IF (lv_retcode = cv_status_error) THEN
          RAISE lv_process_expt;
        END IF;
        --成功件数カウント
        gn_normal_cnt := gn_normal_cnt + 1;
--
      EXCEPTION
-- 2011/10/14 v1.19 T.Yoshimoto Add Start E_本稼動_05929
        -- *** 書式・桁数チェックのエラー例外ハンドラ ***
        WHEN validation_expt THEN
--
          lv_msg2 := xxccp_common_pkg.get_msg(
                              iv_application  => cv_app_name                    -- アプリケーション短縮名
                             ,iv_name         => cv_tkn_number_20               -- メッセージコード
                             ,iv_token_name1  => cv_tkn_bukken                  -- トークン
                             ,iv_token_value1 => l_get_rec.install_code         -- 値
                             ,iv_token_name2  => cv_tkn_message                 -- トークン
                             ,iv_token_value2 => lv_token_msg                   -- 値
                            );
--
          fnd_file.put_line(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_msg2
          );
--
          -- ステータスに警告を設定
          ov_retcode     := cv_status_warn;
-- 2011/10/14 v1.19 T.Yoshimoto Add End E_本稼動_05929
--
        -- *** データ抽出時のエラー例外ハンドラ ***
        WHEN lv_process_expt THEN
          RAISE global_process_expt;
        -- *** データ抽出時の警告例外ハンドラ ***
        WHEN select_error_expt THEN
          --エラー件数カウント
          gn_error_cnt  := gn_error_cnt + 1;
          --
          lv_sub_retcode := cv_status_warn;
          ov_retcode     := lv_sub_retcode;
          --警告出力
          fnd_file.put_line(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_sub_msg                  --ユーザー・エラーメッセージ
          );
          fnd_file.put_line(
             which  => FND_FILE.LOG
            ,buff   => cv_pkg_name||cv_msg_cont||
                       cv_prg_name||cv_msg_part||
                       /* 2009.07.21 K.Hosoi 0000475対応 START */
                       --lv_sub_buf
                       lv_sub_buf ||cv_msg_bkn_cd||
                       l_get_rec.install_code || cv_prnthss
                       /* 2009.07.21 K.Hosoi 0000475対応 START */
          );
      END;
--
    END LOOP get_data_loop;
--
    --出力件数が０件の場合
    IF (gn_target_cnt = 0) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name                  --アプリケーション短縮名
                    ,iv_name         => cv_tkn_number_12             --メッセージコード
                   );
      lv_errbuf := lv_errmsg || SQLERRM;
      RAISE no_data_expt;
    END IF;
--
    -- カーソルクローズ
    CLOSE xibv_data_cur;
    -- *** DEBUG_LOG ***
    -- カーソルクローズしたことをログ出力
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => cv_debug_msg_ccls1 || CHR(10) ||
                 ''
    );
--
    -- ========================================
    -- A-8.CSVファイルクローズ
    -- ========================================
--
    close_csv_file(
       iv_file_dir   => lv_file_dir   -- CSVファイル出力先
      ,iv_file_name  => lv_file_name  -- CSVファイル名
      ,ov_errbuf     => lv_errbuf     -- エラー・メッセージ            --# 固定 #
      ,ov_retcode    => lv_retcode    -- リターン・コード              --# 固定 #
      ,ov_errmsg     => lv_errmsg     -- ユーザー・エラー・メッセージ  --# 固定 #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    /* 2009.11.27 K.Satomura E_本稼動_00118対応 START */
    IF (lv_warn_flag = cv_flag_yes) THEN
       ov_retcode := cv_status_warn;
       --
    END IF;
    /* 2009.11.27 K.Satomura E_本稼動_00118対応 END */
  EXCEPTION
    -- *** 処理対象データ0件例外ハンドラ ***
    WHEN no_data_expt THEN
      lb_fopn_retcd := UTL_FILE.IS_OPEN (
                         file =>gf_file_hand
                       );
      -- ファイルがクローズされていない場合
      IF (lb_fopn_retcd = cb_true) THEN
        -- ファイルクローズ
        UTL_FILE.FCLOSE(
          file =>gf_file_hand
        );
      -- *** DEBUG_LOG ***
      -- ファイルクローズしたことをログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_fcls || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err5 || cv_msg_part ||
                   cv_debug_msg_fnm  || lv_file_name   || CHR(10) ||
                   ''
      );
      END IF;
--
      -- カーソルがクローズされていない場合
      IF (xibv_data_cur%ISOPEN) THEN
        -- カーソルクローズ
        CLOSE xibv_data_cur;
      -- *** DEBUG_LOG ***
      -- カーソルクローズしたことをログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_ccls2|| CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err5 || CHR(10) ||
                   ''
      );
      END IF;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      lb_fopn_retcd := UTL_FILE.IS_OPEN (
                         file =>gf_file_hand
                       );
      -- ファイルがクローズされていない場合
      IF (lb_fopn_retcd = cb_true) THEN
        -- ファイルクローズ
        UTL_FILE.FCLOSE(
          file =>gf_file_hand
        );
        -- *** DEBUG_LOG ***
        -- ファイルクローズしたことをログ出力
        fnd_file.put_line(
           which  => FND_FILE.LOG
          ,buff   => cv_debug_msg_fcls || CHR(10) ||
                     cv_prg_name       || cv_msg_part ||
                     cv_debug_msg_err6 || cv_msg_part ||
                     cv_debug_msg_fnm  || lv_file_name   || CHR(10) ||
                     ''
        );
      END IF;
      -- カーソルがクローズされていない場合
      IF (xibv_data_cur%ISOPEN) THEN
        -- カーソルクローズ
        CLOSE xibv_data_cur;
        -- *** DEBUG_LOG ***
        -- カーソルクローズしたことをログ出力
        fnd_file.put_line(
           which  => FND_FILE.LOG
          ,buff   => cv_debug_msg_ccls2|| CHR(10) ||
                     cv_prg_name       || cv_msg_part ||
                     cv_debug_msg_err6 || CHR(10) ||
                     ''
        );
      END IF;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      lb_fopn_retcd := UTL_FILE.IS_OPEN (
                         file =>gf_file_hand
                       );
      -- ファイルがクローズされていない場合
      IF (lb_fopn_retcd = cb_true) THEN
        -- ファイルクローズ
        UTL_FILE.FCLOSE(
          file =>gf_file_hand
        );
        -- *** DEBUG_LOG ***
        -- ファイルクローズしたことをログ出力
        fnd_file.put_line(
           which  => FND_FILE.LOG
          ,buff   => cv_debug_msg_fcls || CHR(10) ||
                     cv_prg_name       || cv_msg_part ||
                     cv_debug_msg_err3 || cv_msg_part ||
                     cv_debug_msg_fnm  || lv_file_name   || CHR(10) ||
                     ''
        );
      END IF;
      -- カーソルがクローズされていない場合
      IF (xibv_data_cur%ISOPEN) THEN
        -- カーソルクローズ
        CLOSE xibv_data_cur;
        -- *** DEBUG_LOG ***
        -- カーソルクローズしたことをログ出力
        fnd_file.put_line(
           which  => FND_FILE.LOG
          ,buff   => cv_debug_msg_ccls2|| CHR(10) ||
                     cv_prg_name       || cv_msg_part ||
                     cv_debug_msg_err3 || CHR(10) ||
                    ''
       );
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM||lv_errbuf;
      ov_retcode := cv_status_error;
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      lb_fopn_retcd := UTL_FILE.IS_OPEN (
                         file =>gf_file_hand
                       );
      -- ファイルがクローズされていない場合
      IF (lb_fopn_retcd = cb_true) THEN
        -- ファイルクローズ
        UTL_FILE.FCLOSE(
          file =>gf_file_hand
        );
        -- *** DEBUG_LOG ***
        -- ファイルクローズしたことをログ出力
        fnd_file.put_line(
           which  => FND_FILE.LOG
          ,buff   => cv_debug_msg_fcls || CHR(10) ||
                     cv_prg_name       || cv_msg_part ||
                     cv_debug_msg_err4 || cv_msg_part ||
                     cv_debug_msg_fnm  || lv_file_name   || CHR(10) ||
                     ''
        );
      END IF;
      -- カーソルがクローズされていない場合
      IF (xibv_data_cur%ISOPEN) THEN
        -- カーソルクローズ
        CLOSE xibv_data_cur;
        -- *** DEBUG_LOG ***
        -- カーソルクローズしたことをログ出力
        fnd_file.put_line(
           which  => FND_FILE.LOG
          ,buff   => cv_debug_msg_ccls2|| CHR(10) ||
                     cv_prg_name       || cv_msg_part ||
                     cv_debug_msg_err4 || CHR(10) ||
''
       );
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM||lv_errbuf;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END submain;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : コンカレント実行ファイル登録プロシージャ
   **********************************************************************************/
--
  PROCEDURE main(
     errbuf              OUT NOCOPY VARCHAR2     -- エラー・メッセージ  --# 固定 #
    ,retcode             OUT NOCOPY VARCHAR2     -- リターン・コード    --# 固定 #
    )
--
--###########################  固定部 START   ###########################
--
  IS
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'main';  -- プログラム名
--
    cv_appl_short_name CONSTANT VARCHAR2(10)  := 'XXCCP';            -- アドオン：共通・IF領域
    cv_target_rec_msg  CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90000'; -- 対象件数メッセージ
    cv_success_rec_msg CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90001'; -- 成功件数メッセージ
    cv_error_rec_msg   CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002'; -- エラー件数メッセージ
    cv_skip_rec_msg    CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90003'; -- スキップ件数メッセージ
    cv_cnt_token       CONSTANT VARCHAR2(10)  := 'COUNT';            -- 件数メッセージ用トークン名
    cv_normal_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; -- 正常終了メッセージ
    cv_warn_msg        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005'; -- 警告終了メッセージ
    cv_error_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006'; -- エラー終了
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf          VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode         VARCHAR2(1);     -- リターン・コード
    lv_errmsg          VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
    lv_message_code    VARCHAR2(100);   -- 終了メッセージコード
--
  BEGIN
--
--###########################  固定部 START   #####################################################
--
    -- 固定出力
    -- コンカレントヘッダメッセージ出力関数の呼び出し
    xxccp_common_pkg.put_log_header(
       ov_retcode => lv_retcode
      ,ov_errbuf  => lv_errbuf
      ,ov_errmsg  => lv_errmsg
    );
    --
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_api_others_expt;
    END IF;
--
--###########################  固定部 END   #############################
--
    -- ===============================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ===============================================
    submain(
       ov_errbuf   => lv_errbuf          -- エラー・メッセージ            --# 固定 #
      ,ov_retcode  => lv_retcode         -- リターン・コード              --# 固定 #
      ,ov_errmsg   => lv_errmsg          -- ユーザー・エラー・メッセージ  --# 固定 #
    );
--
    IF (lv_retcode = cv_status_error) THEN
       --エラー出力
       fnd_file.put_line(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_errmsg                  --ユーザー・エラーメッセージ
       );
       fnd_file.put_line(
          which  => FND_FILE.LOG
         ,buff   => cv_pkg_name||cv_msg_cont||
                    cv_prg_name||cv_msg_part||
                    lv_errbuf                  --エラーメッセージ
       );
    END IF;
--
    -- =======================
    -- A-9.終了処理
    -- =======================
    --空行の出力
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    --対象件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                   );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --成功件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_success_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_normal_cnt)
                   );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --エラー件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_error_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_error_cnt)
                   );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
-- 2011/10/14 v1.19 T.Yoshimoto Add Start E_本稼動_05929(コメントアウト解除)
    --スキップ件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_skip_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_skip_cnt)
                   );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
-- 2011/10/14 v1.19 T.Yoshimoto Add End E_本稼動_05929
    --
    --終了メッセージ
    IF (lv_retcode = cv_status_normal) THEN
      lv_message_code := cv_normal_msg;
    ELSIF(lv_retcode = cv_status_error) THEN
      lv_message_code := cv_error_msg;
    ELSIF(lv_retcode = cv_status_warn) THEN
      lv_message_code := cv_warn_msg;
    END IF;
    --
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => lv_message_code
                   );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    --ステータスセット
    retcode := lv_retcode;
    --終了ステータスがエラーの場合はROLLBACKする
    IF (retcode = cv_status_error) THEN
      ROLLBACK;
      -- *** DEBUG_LOG ***
      -- ロールバックしたことをログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg11 || CHR(10) ||
                   ''
      );
    END IF;
--
  EXCEPTION
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM||lv_errbuf;
      retcode := cv_status_error;
      ROLLBACK;
      -- *** DEBUG_LOG ***
      -- ロールバックしたことをログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg11 || CHR(10) ||
                   ''
      );
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
      -- *** DEBUG_LOG ***
      -- ロールバックしたことをログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg11 || CHR(10) ||
                   ''
      );
  END main;
--
--###########################  固定部 END   #######################################################
--
END XXCSO016A05C;
/
