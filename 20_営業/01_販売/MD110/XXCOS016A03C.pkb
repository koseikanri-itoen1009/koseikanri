CREATE OR REPLACE PACKAGE BODY XXCOS016A03C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOS016A03C(body)
 * Description      : 人事システム向け、販売実績賞与データ(I/F)作成処理
 * MD.050           : A03_人事システム向け販売実績データの作成（月次・賞与） COS_016_A03
 * Version          : 1.9
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   初期処理(A-0)
 *  pra_chk                パラメータチェック(A-1)
 *  get_common_data        共通データ取得(A-2)
 *  lock_table             ロックテーブル(A-3)
 *  delete_table           テーブルデータ削除(A-3)
 *  get_sales_results_data 当月販売実績集計処理(A-5)
 *  get_noruma_data        当月ノルマ集計処理(A-6)
 *  get_point_data         当月獲得ポイント集計処理(A-7)
 *  get_vender_data        当月獲得ベンダー集計処理(A-8)
 *  get_visit_data         当月訪問件数集計処理(A-9)
 *  set_insert_data        月次・賞与中間テーブル登録処理(A-10)
 *  small_group_total      小グループ集計処理(A-11)
 *  base_total             拠点集計処理(A-12)
 *  area_total             地区集計処理(A-13)
 *  div_total              本部集計処理(A-14)
 *  sum_total              全社集計処理(A-15)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/11/20    1.0   T.kitajima       新規作成
 *  2009/02/05    1.1   T.kitajima       [COS_031]連携項目の本部コードを6桁対応
 *  2009/02/17    1.2   T.kitajima       get_msgのパッケージ名修正
 *  2009/02/24    1.3   T.kitajima       パラメータのログファイル出力対応
 *  2009/02/26    1.4   T.kitajima       従業員ビューの適用日条件設定
 *  2009/10/16    1.5   S.Miyakoshi      [0001397]二重計上の対応
 *  2010/01/22    1.6   S.Miyakoshi      [E_本稼動_01234](A-15)異常終了時のログ出力内容の変更
 *  2010/04/20    1.7   K.Atsushiba      [E_本稼動_02151]本部コード対応
 *  2010/05/26    1.8   S.Miyakoshi      [E_本稼動_02774]月中退職者が未計上の対応
 *  2013/08/12    1.9   K.Kiriu          [E_本稼動_02011]実績振替の入金値引の対応
 *
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
  cv_msg_part      CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont      CONSTANT VARCHAR2(3) := '.';
--
--################################  固定部 END   ##################################
--
--#######################  固定グローバル変数宣言部 START   #######################
--
  gv_out_msg       VARCHAR2(2000);
  gv_sep_msg       VARCHAR2(2000);
  gv_exec_user     VARCHAR2(100);
  gv_conc_name     VARCHAR2(30);
  gv_conc_status   VARCHAR2(30);
  gn_target_cnt    NUMBER;                    -- 対象件数
  gn_normal_cnt    NUMBER;                    -- 正常件数
  gn_error_cnt     NUMBER;                    -- エラー件数
  gn_warn_cnt      NUMBER;                    -- スキップ件数
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
--
  global_chk_make_date_expt EXCEPTION;  --
  global_get_per_date_expt  EXCEPTION;  --
  global_lock_expt          EXCEPTION;  --ロック
  global_delete_expt        EXCEPTION;  --削除
  global_select_expt        EXCEPTION;  --抽出
  global_common_expt        EXCEPTION;  --共通
  global_insert_expt        EXCEPTION;  --登録
  global_update_expt        EXCEPTION;  --更新
  global_no_data_expt       EXCEPTION;  --対象データ０件エラー
-- == 2013/08/12 1.9 Add START ===============================================================
  global_get_profile_expt   EXCEPTION;  --プロファイル取得例外
-- == 2013/08/12 1.9 Add END   ===============================================================
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name               CONSTANT VARCHAR2(100) := 'XXCOS016A03C';       -- パッケージ名
  --アプリケーション短縮名
  cv_current_appl_short_nm           fnd_application.application_short_name%TYPE
                                     :=  'XXCOS';                    --販物短縮アプリ名
  --販物メッセージ
  cv_msg_table_lock_err     CONSTANT fnd_new_messages.message_name%TYPE
                                     := 'APP-XXCOS1-00001';   --テーブルロックエラーメッセージ
-- == 2013/08/12 1.9 Add START ===============================================================
  cv_msg_get_profile_err    CONSTANT  fnd_new_messages.message_name%TYPE
                                     := 'APP-XXCOS1-00004';   --プロファイル取得エラー
-- == 2013/08/12 1.9 Add END   ===============================================================
  cv_msg_insert_data_err    CONSTANT fnd_new_messages.message_name%TYPE
                                     := 'APP-XXCOS1-00010';   --データ登録エラーメッセージ
  cv_msg_get_update_err     CONSTANT fnd_new_messages.message_name%TYPE
                                     := 'APP-XXCOS1-00011';   --データ更新エラーメッセージ
  cv_msg_get_delete_err     CONSTANT fnd_new_messages.message_name%TYPE
                                     := 'APP-XXCOS1-00012';   --データ削除エラーメッセージ
  cv_msg_select_data_err    CONSTANT fnd_new_messages.message_name%TYPE
                                     := 'APP-XXCOS1-00013';   --データ取得エラーメッセージ
  cv_msg_nodata_err         CONSTANT fnd_new_messages.message_name%TYPE
                                     := 'APP-XXCOS1-00018';   --明細0件用メッセージ
  cv_msg_chk_make_date_err  CONSTANT fnd_new_messages.message_name%TYPE
                                     := 'APP-XXCOS1-13451';   --作成年月の型違いメッセージ
  cv_msg_get_per_date_err   CONSTANT fnd_new_messages.message_name%TYPE
                                     := 'APP-XXCOS1-13452';   --会計期間取得エラー
  cv_msg_pram_date          CONSTANT fnd_new_messages.message_name%TYPE
                                     := 'APP-XXCOS1-13453';   --パラメータメッセージ
  cv_msg_mem1_data          CONSTANT fnd_new_messages.message_name%TYPE
                                     := 'APP-XXCOS1-13454';   --成績者コード
  cv_msg_mem2_data          CONSTANT fnd_new_messages.message_name%TYPE
                                     := 'APP-XXCOS1-13455';   --本部コード
  cv_msg_mem3_data          CONSTANT fnd_new_messages.message_name%TYPE
                                     := 'APP-XXCOS1-13456';   --エリアコード
  cv_msg_mem4_data          CONSTANT fnd_new_messages.message_name%TYPE
                                     := 'APP-XXCOS1-13457';   --拠点コード
  cv_msg_mem5_data          CONSTANT fnd_new_messages.message_name%TYPE
                                     := 'APP-XXCOS1-13458';   --小グループコード
  cv_msg_mem6_data          CONSTANT fnd_new_messages.message_name%TYPE
                                     := 'APP-XXCOS1-13459';   --販売実績テーブル
  cv_msg_mem7_data          CONSTANT fnd_new_messages.message_name%TYPE
                                     := 'APP-XXCOS1-13460';   --営業員別月別計画管理テーブル
  cv_msg_mem8_data          CONSTANT fnd_new_messages.message_name%TYPE
                                     := 'APP-XXCOS1-13461';   --新規獲得ポイント顧客別履歴テーブル
  cv_msg_mem9_data          CONSTANT fnd_new_messages.message_name%TYPE
                                     := 'APP-XXCOS1-13462';   --顧客マスタテーブル
  cv_msg_mem10_data         CONSTANT fnd_new_messages.message_name%TYPE
                                     := 'APP-XXCOS1-13463';   --営業成績表 売上実績集計テーブル
  cv_msg_mem11_data         CONSTANT fnd_new_messages.message_name%TYPE
                                     := 'APP-XXCOS1-13464';   --営業成績表 新規貢献売上集計テーブル
  cv_msg_mem12_data         CONSTANT fnd_new_messages.message_name%TYPE
                                     := 'APP-XXCOS1-13465';   --営業成績表 政策群別実績集計テーブル
  cv_msg_mem13_data         CONSTANT fnd_new_messages.message_name%TYPE
                                     := 'APP-XXCOS1-13466';   --営業成績表 営業件数集計テーブル
  cv_msg_mem14_data         CONSTANT fnd_new_messages.message_name%TYPE
                                     := 'APP-XXCOS1-13467';   --人事システム向け販売実績（月次）テーブル
  cv_msg_mem15_data         CONSTANT fnd_new_messages.message_name%TYPE
                                     := 'APP-XXCOS1-13468';   --人事システム向け販売実績（賞与）テーブル
  cv_msg_mem16_data         CONSTANT fnd_new_messages.message_name%TYPE
                                     := 'APP-XXCOS1-13469';   --従業員view
-- == 2013/08/12 1.9 Add START ===============================================================
  cv_msg_mem17_data         CONSTANT fnd_new_messages.message_name%TYPE
                                     := 'APP-XXCOS1-13470';   --プロファイル名
-- == 2013/08/12 1.9 Add END   ===============================================================
  --トークン
  cv_tkn_table              CONSTANT VARCHAR2(10)  :=  'TABLE_NAME';       --テーブル名称
  cb_tkn_table_on           CONSTANT VARCHAR2(10)  :=  'TABLE';            --テーブル名称
  cv_tkn_key_data           CONSTANT VARCHAR2(10)  :=  'KEY_DATA';         --キーデータ
  cv_tkn_parm_data          CONSTANT VARCHAR2(10)  :=  'PARAME1';          --パラメータ1
-- == 2013/08/12 1.9 Add START ===============================================================
  cv_tkn_profile            CONSTANT VARCHAR2(10)  :=  'PROFILE';           --プロファイル
-- == 2013/08/12 1.9 Add END   ===============================================================
  --メッセージ用文字列
  cv_str_result_cd          CONSTANT VARCHAR2(50)  := xxccp_common_pkg.get_msg(
                                                         iv_application        =>  cv_current_appl_short_nm
                                                        ,iv_name               =>  cv_msg_mem1_data
                                                      ); --成績者コード
  cv_str_div_nm             CONSTANT VARCHAR2(50)  := xxccp_common_pkg.get_msg(
                                                         iv_application        =>  cv_current_appl_short_nm
                                                        ,iv_name               =>  cv_msg_mem2_data
                                                      ); --本部コード
  cv_str_area_nm            CONSTANT VARCHAR2(50)  := xxccp_common_pkg.get_msg(
                                                         iv_application        =>  cv_current_appl_short_nm
                                                        ,iv_name               =>  cv_msg_mem3_data
                                                      ); --エリアコード
  cv_str_base_nm            CONSTANT VARCHAR2(50)  := xxccp_common_pkg.get_msg(
                                                         iv_application        =>  cv_current_appl_short_nm
                                                        ,iv_name               =>  cv_msg_mem4_data
                                                      ); --拠点コード
  cv_str_group_nm           CONSTANT VARCHAR2(50)  := xxccp_common_pkg.get_msg(
                                                         iv_application        =>  cv_current_appl_short_nm
                                                        ,iv_name               =>  cv_msg_mem5_data
                                                      ); --小グループコード
  cv_str_sales_tbl          CONSTANT VARCHAR2(50)  := xxccp_common_pkg.get_msg(
                                                         iv_application        =>  cv_current_appl_short_nm
                                                        ,iv_name               =>  cv_msg_mem6_data
                                                      ); --販売実績テーブル
  cv_str_noruma_tbl         CONSTANT VARCHAR2(50)  := xxccp_common_pkg.get_msg(
                                                         iv_application        =>  cv_current_appl_short_nm
                                                        ,iv_name               =>  cv_msg_mem7_data
                                                      ); --営業員別月別計画管理テーブル
  cv_str_point_tbl          CONSTANT VARCHAR2(50)  := xxccp_common_pkg.get_msg(
                                                         iv_application        =>  cv_current_appl_short_nm
                                                        ,iv_name               =>  cv_msg_mem8_data
                                                      ); --新規獲得ポイント顧客別履歴テーブル
  cv_str_customer_tbl       CONSTANT VARCHAR2(50)  := xxccp_common_pkg.get_msg(
                                                         iv_application        =>  cv_current_appl_short_nm
                                                        ,iv_name               =>  cv_msg_mem9_data
                                                      ); --顧客マスタテーブル
  cv_str_bus_sales_tbl      CONSTANT VARCHAR2(50)  := xxccp_common_pkg.get_msg(
                                                         iv_application        =>  cv_current_appl_short_nm
                                                        ,iv_name               =>  cv_msg_mem10_data
                                                      ); --営業成績表 売上実績集計テーブル
  cv_str_bus_new_tbl        CONSTANT VARCHAR2(50)  := xxccp_common_pkg.get_msg(
                                                         iv_application        =>  cv_current_appl_short_nm
                                                        ,iv_name               =>  cv_msg_mem11_data
                                                      ); --営業成績表 新規貢献売上集計テーブル
  cv_str_bus_Pol_tbl        CONSTANT VARCHAR2(50)  := xxccp_common_pkg.get_msg(
                                                         iv_application        =>  cv_current_appl_short_nm
                                                        ,iv_name               =>  cv_msg_mem12_data
                                                      ); --営業成績表 政策群別実績集計テーブル
  cv_str_bus_count_tbl      CONSTANT VARCHAR2(50)  := xxccp_common_pkg.get_msg(
                                                         iv_application        =>  cv_current_appl_short_nm
                                                        ,iv_name               =>  cv_msg_mem13_data
                                                      ); --営業成績表 営業件数集計テーブル
  cv_month_tbl              CONSTANT VARCHAR2(50)  := xxccp_common_pkg.get_msg(
                                                         iv_application        =>  cv_current_appl_short_nm
                                                        ,iv_name               =>  cv_msg_mem14_data
                                                      ); --人事システム向け販売実績（月次）テーブル
  cv_bonus_tbl              CONSTANT VARCHAR2(50)  := xxccp_common_pkg.get_msg(
                                                         iv_application        =>  cv_current_appl_short_nm
                                                        ,iv_name               =>  cv_msg_mem15_data
                                                      ); --人事システム向け販売実績（賞与）テーブル
  cv_employee_view          CONSTANT VARCHAR2(50)  := xxccp_common_pkg.get_msg(
                                                         iv_application        =>  cv_current_appl_short_nm
                                                        ,iv_name               =>  cv_msg_mem16_data
                                                      ); --従業員VIEW
-- == 2013/08/12 1.9 Add START ===============================================================
  cv_str_profile_nm         CONSTANT  VARCHAR2(50)  := xxccp_common_pkg.get_msg(
                                                         iv_application        =>  cv_current_appl_short_nm
                                                        ,iv_name               =>  cv_msg_mem17_data
                                                      ); --プロファイル名
-- == 2013/08/12 1.9 Add END   ===============================================================
  cv_format_yyyymm          CONSTANT VARCHAR2(7)   := 'YYYY/MM';                         -- 日付フォーマット YYYY/MM
  cv_format_yyyymmdd        CONSTANT VARCHAR2(10)  := 'YYYY/MM/DD';                      -- 日付フォーマット YYYY/MM/DD
  cv_month_tbl_name         CONSTANT VARCHAR2(36)  := 'XXCOS.XXCOS_FOR_ADPS_MONTHLY_IF';
  cv_bonus_tbl_name         CONSTANT VARCHAR2(36)  := 'XXCOS.XXCOS_FOR_ADPS_BONUS_IF';
  cv_sla                    CONSTANT VARCHAR2(1)   := '/';                               -- スラッシュ
  cv_01                     CONSTANT VARCHAR2(2)   := '01';                              -- 01
  cn_1                      CONSTANT NUMBER        := 1;                                 -- 1
  cn_counter_class_4        CONSTANT NUMBER        := 4;                                 -- 延訪問件数
  cn_counter_class_7        CONSTANT NUMBER        := 7;                                 -- 新規件数
  cn_counter_class_8        CONSTANT NUMBER        := 8;                                 -- 新規ベンダー件数
  cn_number_class_9         CONSTANT NUMBER        := 9;                                 -- 新規/什器ポイント
  cn_number_class_11        CONSTANT NUMBER        := 11;                                -- 資格ポイント
-- == 2013/08/12 1.9 Add START ===============================================================
  --プロファイル名称
  cv_profile_p_discounts    CONSTANT  fnd_profile_options.profile_option_name%TYPE
                                      :=  'XXCOS1_PAYMENT_DISCOUNTS_CODE';               -- 入金値引コード
-- == 2013/08/12 1.9 Add END   ===============================================================
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
-- == 2013/08/12 1.9 Add START ===============================================================
  gv_payment_discounts     VARCHAR2(255);                                                -- 入金値引コード
-- == 2013/08/12 1.9 Add END   ===============================================================
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
-- ************************ 2010/01/22 S.Miyakoshi Var1.6 ADD START ************************ --
    gv_sqlerrm      VARCHAR2(5000);  --SQLERRM
-- ************************ 2010/01/22 S.Miyakoshi Var1.6 ADD START ************************ --
  /**********************************************************************************
   * Procedure Name   : is_date
   * Description      : 日付チェック用(A-1)
   ***********************************************************************************/
  PROCEDURE is_date(
    iv_date     IN OUT       VARCHAR2,     -- 日付
    iv_format   IN           VARCHAR2,     -- フォーマット
    ov_errbuf   OUT NOCOPY   VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode  OUT NOCOPY   VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg   OUT NOCOPY   VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'is_date'; -- プログラム名
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
    ld_Date     DATE;  --変換用変数
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
   ld_Date := TO_DATE(iv_date, iv_format, q'{NLS_CALENDAR = 'GREGORIAN'}' );
   IF ( ld_Date IS NULL ) THEN
     RAISE global_api_others_expt;
   END IF;
--
   iv_date := TO_CHAR( ld_Date,iv_format );
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
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
  END is_date;
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-0)
   ***********************************************************************************/
  PROCEDURE init(
    iv_make_date  IN         VARCHAR2,     --   1.作成年月
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'init'; -- プログラム名
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
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
    --パラメータメッセージ
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_current_appl_short_nm
                    ,iv_name         => cv_msg_pram_date
                    ,iv_token_name1  => cv_tkn_parm_data
                    ,iv_token_value1 => iv_make_date
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    -- 空行出力
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => NULL
    );
--
    -- メッセージ出力
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
--
    -- 空行出力
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => NULL
    );
--
  EXCEPTION
--##################  固定 EXCEPTION START ##########################################
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--##################      固定部   END     ##########################################
--
  END init;
--
  /**********************************************************************************
   * Procedure Name   : pra_chk
   * Description      : パラーメータチェック(A-1)
   ***********************************************************************************/
  PROCEDURE pra_chk(
    iv_make_date  IN OUT        VARCHAR2,     --   1.作成年月
    ov_errbuf     OUT    NOCOPY VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT    NOCOPY VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT    NOCOPY VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'pra_chk'; -- プログラム名
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
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    --==============================================================
    --1.作成年月の入力チェックを行います。
    --==============================================================
    IF ( iv_make_date IS NULL ) THEN
      -- 作成年月がNULLの場合システム日付の前月を指定する。
      iv_make_date := TO_CHAR( ADD_MONTHS( SYSDATE,-1 ),cv_format_yyyymm );
        
    END IF;
    --==============================================================
    --2.作成年月入力形式のチェックを行います。
    --==============================================================
    is_date( iv_make_date
            ,cv_format_yyyymm
            ,lv_errbuf
            ,lv_retcode
            ,lv_errmsg
           );
    IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_chk_make_date_expt;
    END IF;
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    -- *** 作成年月の型違いメッセージ例外ハンドラ ***
    WHEN global_chk_make_date_expt THEN
      ov_errmsg               :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_current_appl_short_nm,
        iv_name               =>  cv_msg_chk_make_date_err
      );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;

--#################################  固定例外処理部 START   ###################################
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
  END pra_chk;
--
  /**********************************************************************************
   * Procedure Name   : get_common_data
   * Description      : 共通データ取得(A-2)
   ***********************************************************************************/
  PROCEDURE get_common_data(
    id_base_date  IN         DATE,         --   作成年月
    od_start_date OUT NOCOPY DATE,         --   会計開始日
    od_ebd_date   OUT NOCOPY DATE,         --   会計終了日
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_common_data'; -- プログラム名
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
    -- *** ローカル変数 ***
--
    lv_key_info VARCHAR2(5000);  --key情報
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
    --==============================================
    -- 1.会計期間
    --==============================================
    --
    XXCOS_COMMON_PKG.get_period_year(
       id_base_date   -- 作成年月
      ,od_start_date  -- 会計開始日
      ,od_ebd_date    -- 会計終了日
      ,lv_errbuf   -- エラー・メッセージ           --# 固定 #
      ,lv_retcode  -- リターン・コード             --# 固定 #
      ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_get_per_date_expt;
    END IF;
    
--
-- == 2013/08/12 1.9 Add START ===============================================================
    --==============================================
    -- 2.入金値引コード
    --==============================================
    gv_payment_discounts := FND_PROFILE.value(cv_profile_p_discounts);
    --入金値引コード未取得
    IF ( gv_payment_discounts IS NULL ) THEN
      --キー情報編集
      XXCOS_COMMON_PKG.makeup_key_info(
                                     ov_errbuf      =>  lv_errbuf          --エラー・メッセージ
                                    ,ov_retcode     =>  lv_retcode         --リターンコード
                                    ,ov_errmsg      =>  lv_errmsg          --ユーザ・エラー・メッセージ
                                    ,ov_key_info    =>  lv_key_info        --編集されたキー情報
                                    ,iv_item_name1  =>  cv_str_profile_nm
                                    ,iv_data_value1 =>  cv_Profile_p_discounts
                                    );
      --メッセージ
      IF ( lv_retcode = cv_status_normal ) THEN
        RAISE global_get_profile_expt;
      ELSE
        RAISE global_api_expt;
      END IF;
    END IF;
-- == 2010/08/12 1.9 Add END   ===============================================================
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    -- *** 会計期間取得エラー例外ハンドラ ***
    WHEN global_get_per_date_expt    THEN
      ov_errmsg               :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_current_appl_short_nm,
        iv_name               =>  cv_msg_get_per_date_err
      );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
--
-- == 2013/08/12 1.9 Add START ===============================================================
    -- *** プロファイル例外ハンドラ ***
    WHEN global_get_profile_expt    THEN
      ov_errmsg               :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_current_appl_short_nm,
        iv_name               =>  cv_msg_get_profile_err,
        iv_token_name1        =>  cv_tkn_profile,
        iv_token_value1       =>  lv_key_info
      );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
-- == 2010/08/12 1.9 Add END   ===============================================================
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
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
  END get_common_data;
--
  /**********************************************************************************
   * Procedure Name   : delete_table
   * Description      : テーブルデータ削除(A-3)
   ***********************************************************************************/
  PROCEDURE delete_table(
    iv_tabel_name IN         VARCHAR2,     --   テーブル名
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'delete_table'; -- プログラム名
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
    -- *** ローカル変数 ***
--
    lv_key_info VARCHAR2(5000);  --key情報
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
    --==============================================
    -- テーブルの削除を行います。
    --==============================================
    EXECUTE IMMEDIATE 'TRUNCATE TABLE ' || iv_tabel_name;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
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
  END delete_table;
--
  /**********************************************************************************
   * Procedure Name   : lock_table
   * Description      : テーブルロック(A-3)
   ***********************************************************************************/
  PROCEDURE lock_table(
    iv_tabel_name IN         VARCHAR2,     --   テーブル名
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'lock_table'; -- プログラム名
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
    -- *** ローカル変数 ***
--
    lv_key_info VARCHAR2(5000);  --key情報
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
    --==============================================
    -- テーブルのロックを行います。
    --==============================================
    EXECUTE IMMEDIATE 'LOCK TABLE ' || iv_tabel_name || ' IN SHARE UPDATE MODE NOWAIT';
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
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
  END lock_table;
--
  /**********************************************************************************
   * Procedure Name   : get_sales_results_data
   * Description      : 当月販売実績集計処理(A-5)
   ***********************************************************************************/
  PROCEDURE get_sales_results_data(
    iv_person_code  IN          VARCHAR2,                                      --従業員コード
    iv_base_code    IN          VARCHAR2,                                      --拠点コード
    id_this_date    IN          DATE,                                          --当月1日
    id_next_date    IN          DATE,                                          --当月末日
    it_xxcos_for_adps_monthly_if IN OUT xxcos_for_adps_monthly_if%ROWTYPE,     --月次データ
    it_xxcos_for_adps_bonus_if   IN OUT xxcos_for_adps_bonus_if%ROWTYPE,       --賞与データ
    ov_errbuf       OUT NOCOPY VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode      OUT NOCOPY VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg       OUT NOCOPY VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_sales_results_data'; -- プログラム名
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
    -- *** ローカル変数 ***
--
    lv_key_info     VARCHAR2(5000);  --key情報
    ln_sales_money  NUMBER;          --個売上金額
    ln_new_sales    NUMBER;          --個新規貢献売上
    ln_gross_margin NUMBER;          --個計上粗利
    lv_table_nm     VARCHAR2(50);    -- テーブル名
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
    --==============================================
    -- 1.個売上金額を取得します。
    -- 3.個計上粗利を取得します。
    --==============================================
    --
    BEGIN
      SELECT ROUND( NVL( SUM( sale_amount ),0 )/1000 ),
             NVL( SUM( sale_amount-business_cost ),0 )
      INTO   it_xxcos_for_adps_monthly_if.p_sale_amount,
             it_xxcos_for_adps_bonus_if.p_sale_gross
-- == 2013/08/12 1.9 Mod START ===============================================================
--      FROM   xxcos_rep_bus_s_group_sum
--      WHERE  results_employee_code = iv_person_code
--        AND  sale_base_code        = iv_base_code
--        AND  dlv_date BETWEEN id_this_date AND id_next_date
      FROM   xxcos_rep_bus_s_group_sum xrbsgs
      WHERE  xrbsgs.results_employee_code = iv_person_code
        AND  xrbsgs.sale_base_code        = iv_base_code
        AND  xrbsgs.dlv_date BETWEEN id_this_date AND id_next_date
        AND  (
               ( xrbsgs.sales_transfer_div <> cn_1 )
               OR
               ( xrbsgs.policy_group_code <> (
                   SELECT CASE
                            WHEN  iimb.attribute3 <=  TO_CHAR(xrbsgs.dlv_date, cv_format_yyyymmdd)
                            OR    iimb.attribute3 IS  NULL THEN
                              iimb.attribute2
                            ELSE
                              iimb.attribute1
                          END
                   FROM   ic_item_mst_b iimb
                   WHERE  iimb.item_no = gv_payment_discounts
                 )
               )
             )  --実績振替の入金値引以外
-- == 2013/08/12 1.9 Mod END   ===============================================================
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        xxcos_common_pkg.makeup_key_info(
                                       ov_errbuf      =>  lv_errbuf      --エラー・メッセージ
                                      ,ov_retcode     =>  lv_retcode     --リターンコード
                                      ,ov_errmsg      =>  lv_errmsg      --ユーザ・エラー・メッセージ
                                      ,ov_key_info    =>  lv_key_info    --編集されたキー情報
                                      ,iv_item_name1  =>  cv_str_result_cd
                                      ,iv_item_name2  =>  cv_str_base_nm
                                      ,iv_data_value1 =>  iv_person_code
                                      ,iv_data_value2 =>  iv_base_code
                                     );
        IF ( lv_retcode = cv_status_normal ) THEN
          lv_table_nm := cv_str_bus_Pol_tbl;
          RAISE global_select_expt;
        ELSE
          RAISE global_api_expt;
        END IF;
    END;
    --==============================================
    -- 2.個新規貢献売上を取得します。
    --==============================================
    BEGIN
      SELECT ROUND( NVL( SUM( sale_amount ),0 )/1000 )
      INTO it_xxcos_for_adps_monthly_if.p_new_contribution_sale
      FROM xxcos_rep_bus_newcust_sum
      WHERE results_employee_code = iv_person_code
        AND sale_base_code        = iv_base_code
        AND dlv_date BETWEEN id_this_date AND id_next_date
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        XXCOS_COMMON_PKG.makeup_key_info(
                                       ov_errbuf      =>  lv_errbuf      --エラー・メッセージ
                                      ,ov_retcode     =>  lv_retcode     --リターンコード
                                      ,ov_errmsg      =>  lv_errmsg      --ユーザ・エラー・メッセージ
                                      ,ov_key_info    =>  lv_key_info    --編集されたキー情報
                                      ,iv_item_name1  =>  cv_str_result_cd
                                      ,iv_item_name2  =>  cv_str_base_nm
                                      ,iv_data_value1 =>  iv_person_code
                                      ,iv_data_value2 =>  iv_base_code
                                     );
        IF ( lv_retcode = cv_status_normal ) THEN
          lv_table_nm := cv_str_bus_new_tbl;
          RAISE global_select_expt;
        ELSE
          RAISE global_api_expt;
        END IF;
    END;
    --==============================================
    -- 4.個計上利益を取得します。
    --==============================================
    NULL;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    WHEN global_select_expt THEN
      ov_errmsg := xxccp_common_pkg.get_msg(
                      iv_application        =>  cv_current_appl_short_nm
                     ,iv_name               =>  cv_msg_select_data_err
                     ,iv_token_name1        =>  cv_tkn_table
                     ,iv_token_name2        =>  cv_tkn_key_data
                     ,iv_token_value1       =>  lv_table_nm
                     ,iv_token_value2       =>  lv_key_info
                   );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
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
  END get_sales_results_data;
--
  /**********************************************************************************
   * Procedure Name   : get_noruma_data
   * Description      : 当月ノルマ集計処理(A-6)
   ***********************************************************************************/
  PROCEDURE get_noruma_data(
    iv_person_code               IN            VARCHAR2,                   --従業員コード
    iv_base_code                 IN            VARCHAR2,                   --拠点コード
    it_xxcos_for_adps_monthly_if IN OUT xxcos_for_adps_monthly_if%ROWTYPE, --データ
    ov_errbuf                    OUT    NOCOPY VARCHAR2,                   --エラー・メッセージ           --# 固定 #
    ov_retcode                   OUT    NOCOPY VARCHAR2,                   --リターン・コード             --# 固定 #
    ov_errmsg                    OUT    NOCOPY VARCHAR2)                   --ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_noruma_data'; -- プログラム名
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
    -- *** ローカル変数 ***
--
    lv_key_info     VARCHAR2(5000);  --key情報
    ln_sales_money  NUMBER;          --個売上金額
    ln_new_sales    NUMBER;          --個新規貢献売上
    ln_gross_margin NUMBER;          --個計上粗利
    ln_cnt          NUMBER;          --カウント
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
    --==============================================
    -- 1.個売上ノルマ金額を取得します。
    --==============================================
    BEGIN
      SELECT NVL( bsc_sls_prsn_total_amt,0 )
      INTO   it_xxcos_for_adps_monthly_if.p_sale_norma
      FROM   xxcso_sls_prsn_mnthly_plns
      WHERE  employee_number = iv_person_code
        AND  base_code       = iv_base_code
        AND  year_month      = it_xxcos_for_adps_monthly_if.results_date
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        it_xxcos_for_adps_monthly_if.p_sale_norma := 0;
    END;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
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
  END get_noruma_data;
--
  /**********************************************************************************
   * Procedure Name   : get_point_data
   * Description      : 当月獲得ポイント集計処理(A-7)
   ***********************************************************************************/
  PROCEDURE get_point_data(
    iv_person_code               IN            VARCHAR2,                   --従業員コード
    iv_base_code                 IN            VARCHAR2,                   --拠点コード
    id_this_date                 IN            DATE,                       --当月1日
    id_next_date                 IN            DATE,                       --当月末日
    it_xxcos_for_adps_monthly_if IN OUT xxcos_for_adps_monthly_if%ROWTYPE, --データ
    ov_errbuf                    OUT    NOCOPY VARCHAR2,                   --エラー・メッセージ           --# 固定 #
    ov_retcode                   OUT    NOCOPY VARCHAR2,                   --リターン・コード             --# 固定 #
    ov_errmsg                    OUT    NOCOPY VARCHAR2)                   --ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_point_data'; -- プログラム名
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
    cv_point_1_id          CONSTANT NUMBER      := 1; -- 新規ポイント
    cv_point_0_id          CONSTANT NUMBER      := 0; -- 資格ポイント
    cv_evaluation_0_id     CONSTANT VARCHAR2(1) := 0; -- 評価達成
    -- *** ローカル変数 ***
--
    lv_key_info     VARCHAR2(5000);  --key情報
    ln_sales_money  NUMBER;          --個売上金額
    ln_new_sales    NUMBER;          --個新規貢献売上
    ln_gross_margin NUMBER;          --個計上粗利
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
    --==============================================
    -- 1.新規ポイントを取得します。
    --==============================================
    --
    BEGIN
      SELECT rbcs.counter
        INTO it_xxcos_for_adps_monthly_if.p_new_point
        FROM xxcos_rep_bus_count_sum rbcs
       WHERE rbcs.target_date   = it_xxcos_for_adps_monthly_if.results_date
         AND rbcs.base_code     = iv_base_code
         AND rbcs.employee_num  = iv_person_code
         AND rbcs.counter_class = cn_number_class_9
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        it_xxcos_for_adps_monthly_if.p_new_point := 0;
    END;
--
    --==============================================
    -- 2.資格ポイントを取得します。
    --==============================================
    BEGIN
      SELECT rbcs.counter
        INTO it_xxcos_for_adps_monthly_if.p_position_point
        FROM xxcos_rep_bus_count_sum rbcs
       WHERE rbcs.target_date   = it_xxcos_for_adps_monthly_if.results_date
         AND rbcs.base_code     = iv_base_code
         AND rbcs.employee_num  = iv_person_code
         AND rbcs.counter_class = cn_number_class_11
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        it_xxcos_for_adps_monthly_if.p_position_point := 0;
    END;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
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
  END get_point_data;
--
  /**********************************************************************************
   * Procedure Name   : get_vender_data
   * Description      : 当月獲得ベンダー集計処理(A-8)
   ***********************************************************************************/
  PROCEDURE get_vender_data(
    iv_person_code               IN     VARCHAR2,                          --従業員コード
    iv_base_code                 IN     VARCHAR2,                          --拠点コード
    it_xxcos_for_adps_monthly_if IN OUT xxcos_for_adps_monthly_if%ROWTYPE, --データ
    ov_errbuf                    OUT    VARCHAR2,                          --エラー・メッセージ           --# 固定 #
    ov_retcode                   OUT    VARCHAR2,                          --リターン・コード             --# 固定 #
    ov_errmsg                    OUT    VARCHAR2)                          --ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_vender_data'; -- プログラム名
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
    -- *** ローカル変数 ***
--
    lv_key_info     VARCHAR2(5000);  --key情報
    ln_sales_money  NUMBER;          --個売上金額
    ln_new_sales    NUMBER;          --個新規貢献売上
    ln_gross_margin NUMBER;          --個計上粗利
    ln_cnt          NUMBER;          --カウント
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
    --==============================================
    -- 1.新規件数を取得します。
    --==============================================
    BEGIN
      SELECT NVL( COUNTER,0 )
      INTO it_xxcos_for_adps_monthly_if.p_new_count_sum
      FROM xxcos_rep_bus_count_sum
      WHERE employee_num  = iv_person_code
        AND base_code     = iv_base_code
        AND target_date   = it_xxcos_for_adps_monthly_if.results_date
        AND counter_class = cn_counter_class_7
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        it_xxcos_for_adps_monthly_if.p_new_count_sum := 0;
    END;
    --==============================================
    -- 2.新規ベンダー件数を取得します。
    --==============================================
    BEGIN
      SELECT NVL( COUNTER,0 )
      INTO it_xxcos_for_adps_monthly_if.p_new_count_vd
      FROM xxcos_rep_bus_count_sum
      WHERE employee_num  = iv_person_code
        AND base_code     = iv_base_code
        AND target_date   = it_xxcos_for_adps_monthly_if.results_date
        AND counter_class = cn_counter_class_8
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        it_xxcos_for_adps_monthly_if.p_new_count_vd := 0;
    END;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
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
  END get_vender_data;
--
  /**********************************************************************************
   * Procedure Name   : get_visit_data
   * Description      : 当月訪問件数集計処理(A-9)
   ***********************************************************************************/
  PROCEDURE get_visit_data(
    iv_person_code             IN     VARCHAR2,                        --従業員コード
    iv_base_code               IN     VARCHAR2,                        --拠点コード
    it_xxcos_for_adps_bonus_if IN OUT xxcos_for_adps_bonus_if%ROWTYPE, --賞与データ
    ov_errbuf                  OUT    VARCHAR2,                        --エラー・メッセージ           --# 固定 #
    ov_retcode                 OUT    VARCHAR2,                        --リターン・コード             --# 固定 #
    ov_errmsg                  OUT    VARCHAR2)                        --ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_visit_data'; -- プログラム名
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
    -- *** ローカル変数 ***
--
    lv_key_info     VARCHAR2(5000);  --key情報
    ln_sales_money  NUMBER;          --個売上金額
    ln_new_sales    NUMBER;          --個新規貢献売上
    ln_gross_margin NUMBER;          --個計上粗利
    ln_cnt          NUMBER;          --カウント
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
    --==============================================
    -- 1.当月の訪問件数を集計します。
    --==============================================
    --
    BEGIN
      SELECT NVL( COUNTER,0 )
      INTO it_xxcos_for_adps_bonus_if.p_visit_count
      FROM xxcos_rep_bus_count_sum
      WHERE employee_num  = iv_person_code
        AND base_code     = iv_base_code
        AND target_date   = it_xxcos_for_adps_bonus_if.results_date
        AND counter_class = cn_counter_class_4
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        it_xxcos_for_adps_bonus_if.p_visit_count := 0;
    END;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
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
  END get_visit_data;
--
  /**********************************************************************************
   * Procedure Name   : set_insert_data
   * Description      : 当月販売実績集計処理(A-10)
   ***********************************************************************************/
  PROCEDURE set_insert_data(
    it_xxcos_for_adps_monthly_if IN OUT xxcos_for_adps_monthly_if%ROWTYPE, --月次データ
    it_xxcos_for_adps_bonus_if   IN OUT xxcos_for_adps_bonus_if%ROWTYPE,   --賞与データ
    ov_errbuf                    OUT    NOCOPY VARCHAR2,                   --エラー・メッセージ        -# 固定 #
    ov_retcode                   OUT    NOCOPY VARCHAR2,                   --リターン・コード          -# 固定 #
    ov_errmsg                    OUT    NOCOPY VARCHAR2)                   --ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'set_insert_data'; -- プログラム名
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
    -- *** ローカル変数 ***
--
    lv_key_info     VARCHAR2(5000);  --key情報
    ln_sales_money  NUMBER;          --個売上金額
    ln_new_sales    NUMBER;          --個新規貢献売上
    ln_gross_margin NUMBER;          --個計上粗利
    lv_table_nm     VARCHAR2(50);    -- テーブル名
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
    --==============================================
    -- 1.人事システム向け販売実績（月次）テーブルを登録します。
    --==============================================
    BEGIN
      INSERT INTO xxcos_for_adps_monthly_if
        (
          record_id,
          employee_code,
          results_date,
          group_code,
          base_code,
          area_code,
          division_code,
          p_sale_norma,
          p_sale_amount,
          p_sale_achievement_rate,
          p_new_contribution_sale,
          p_new_norma,
          p_new_achievement_rate,
          p_new_count_sum,
          p_new_count_vd,
          p_position_point,
          p_new_point,
          g_sale_norma,
          g_sale_amount,
          g_sale_achievement_rate,
          g_new_contribution_sale,
          g_new_norma,
          g_new_achievement_rate,
          g_new_count_sum,
          g_new_count_vd,
          g_position_point,
          g_new_point,
          b_sale_norma,
          b_sale_amount,
          b_sale_achievement_rate,
          b_new_contribution_sale,
          b_new_norma,
          b_new_achievement_rate,
          b_new_count_sum,
          b_new_count_vd,
          b_position_point,
          b_new_point,
          a_sale_norma,
          a_sale_amount,
          a_sale_achievement_rate,
          a_new_contribution_sale,
          a_new_norma,
          a_new_achievement_rate,
          a_new_count_sum,
          a_new_count_vd,
          a_position_point,
          a_new_point,
          d_sale_norma,
          d_sale_amount,
          d_sale_achievement_rate,
          d_new_contribution_sale,
          d_new_norma,
          d_new_achievement_rate,
          d_new_count_sum,
          d_new_count_vd,
          d_position_point,
          d_new_point,
          s_sale_norma,
          s_sale_amount,
          s_sale_achievement_rate,
          s_new_contribution_sale,
          s_new_norma,
          s_new_achievement_rate,
          s_new_count_sum,
          s_new_count_vd,
          s_position_point,
          s_new_point,
          created_by,
          creation_date,
          last_updated_by,
          last_update_date,
          last_update_login,
          request_id,
          program_application_id,
          program_id,
          program_update_date
        )
      VALUES
        (
          xxcos_for_adps_monthly_if_s01.nextval,                   -- レコードID
          it_xxcos_for_adps_monthly_if.employee_code,              -- 従業員コード
          it_xxcos_for_adps_monthly_if.results_date,               -- 年月
          it_xxcos_for_adps_monthly_if.group_code,                 -- 小グループコード
          it_xxcos_for_adps_monthly_if.base_code,                  -- 拠点ｺｰﾄﾞ
          it_xxcos_for_adps_monthly_if.area_code,                  -- 地区コード
          it_xxcos_for_adps_monthly_if.division_code,              -- 本部ｺｰﾄﾞ
          it_xxcos_for_adps_monthly_if.p_sale_norma,               -- 個売上ﾉﾙﾏ
          it_xxcos_for_adps_monthly_if.p_sale_amount,              -- 個売上金額
          it_xxcos_for_adps_monthly_if.p_sale_achievement_rate,    -- 個売上達成率
          it_xxcos_for_adps_monthly_if.p_new_contribution_sale,    -- 個新規貢献売上
          it_xxcos_for_adps_monthly_if.p_new_norma,                -- 個新規ﾉﾙﾏ
          it_xxcos_for_adps_monthly_if.p_new_achievement_rate,     -- 個新規達成率
          it_xxcos_for_adps_monthly_if.p_new_count_sum,            -- 個新規件数合計
          it_xxcos_for_adps_monthly_if.p_new_count_vd,             -- 個新規件数ﾍﾞﾝﾀﾞｰ
          it_xxcos_for_adps_monthly_if.p_position_point,           -- 個資格POINT
          it_xxcos_for_adps_monthly_if.p_new_point,                -- 個新規POINT
          it_xxcos_for_adps_monthly_if.g_sale_norma,               -- 小売上ﾉﾙﾏ
          it_xxcos_for_adps_monthly_if.g_sale_amount,              -- 小売上金額
          it_xxcos_for_adps_monthly_if.g_sale_achievement_rate,    -- 小売上達成率
          it_xxcos_for_adps_monthly_if.g_new_contribution_sale,    -- 小新規貢献売上
          it_xxcos_for_adps_monthly_if.g_new_norma,                -- 小新規ﾉﾙﾏ
          it_xxcos_for_adps_monthly_if.g_new_achievement_rate,     -- 小新規達成率
          it_xxcos_for_adps_monthly_if.g_new_count_sum,            -- 小新規件数合計
          it_xxcos_for_adps_monthly_if.g_new_count_vd,             -- 小新規件数ﾍﾞﾝﾀﾞｰ
          it_xxcos_for_adps_monthly_if.g_position_point,           -- 小資格POINT
          it_xxcos_for_adps_monthly_if.g_new_point,                -- 小新規POINT
          it_xxcos_for_adps_monthly_if.b_sale_norma,               -- 拠売上ﾉﾙﾏ
          it_xxcos_for_adps_monthly_if.b_sale_amount,              -- 拠売上金額
          it_xxcos_for_adps_monthly_if.b_sale_achievement_rate,    -- 拠売上達成率
          it_xxcos_for_adps_monthly_if.b_new_contribution_sale,    -- 拠新規貢献売上
          it_xxcos_for_adps_monthly_if.b_new_norma,                -- 拠新規達成率
          it_xxcos_for_adps_monthly_if.b_new_achievement_rate,     -- 拠新規ﾉﾙﾏ
          it_xxcos_for_adps_monthly_if.b_new_count_sum,            -- 拠新規件数合計
          it_xxcos_for_adps_monthly_if.b_new_count_vd,             -- 拠新規件数ﾍﾞﾝﾀﾞｰ
          it_xxcos_for_adps_monthly_if.b_position_point,           -- 拠資格POINT
          it_xxcos_for_adps_monthly_if.b_new_point,                -- 拠新規POINT
          it_xxcos_for_adps_monthly_if.a_sale_norma,               -- 地売上ﾉﾙﾏ
          it_xxcos_for_adps_monthly_if.a_sale_amount,              -- 地売上金額
          it_xxcos_for_adps_monthly_if.a_sale_achievement_rate,    -- 地売上達成率
          it_xxcos_for_adps_monthly_if.a_new_contribution_sale,    -- 地新規貢献売上
          it_xxcos_for_adps_monthly_if.a_new_norma,                -- 地新規達成率
          it_xxcos_for_adps_monthly_if.a_new_achievement_rate,     -- 地新規ﾉﾙﾏ
          it_xxcos_for_adps_monthly_if.a_new_count_sum,            -- 地新規件数合計
          it_xxcos_for_adps_monthly_if.a_new_count_vd,             -- 地新規件数ﾍﾞﾝﾀﾞｰ
          it_xxcos_for_adps_monthly_if.a_position_point,           -- 地資格POINT
          it_xxcos_for_adps_monthly_if.a_new_point,                -- 地新規POINT
          it_xxcos_for_adps_monthly_if.d_sale_norma,               -- 本売上ﾉﾙﾏ
          it_xxcos_for_adps_monthly_if.d_sale_amount,              -- 本売上金額
          it_xxcos_for_adps_monthly_if.d_sale_achievement_rate,    -- 本売上達成率
          it_xxcos_for_adps_monthly_if.d_new_contribution_sale,    -- 本新規貢献売上
          it_xxcos_for_adps_monthly_if.d_new_norma,                -- 本新規達成率
          it_xxcos_for_adps_monthly_if.d_new_achievement_rate,     -- 本新規ﾉﾙﾏ
          it_xxcos_for_adps_monthly_if.d_new_count_sum,            -- 本新規件数合計
          it_xxcos_for_adps_monthly_if.d_new_count_vd,             -- 本新規件数ﾍﾞﾝﾀﾞｰ
          it_xxcos_for_adps_monthly_if.d_position_point,           -- 本資格POINT
          it_xxcos_for_adps_monthly_if.d_new_point,                -- 本新規POINT
          it_xxcos_for_adps_monthly_if.s_sale_norma,               -- 全売上ﾉﾙﾏ
          it_xxcos_for_adps_monthly_if.s_sale_amount,              -- 全売上金額
          it_xxcos_for_adps_monthly_if.s_sale_achievement_rate,    -- 全売上達成率
          it_xxcos_for_adps_monthly_if.s_new_contribution_sale,    -- 全新規貢献売上
          it_xxcos_for_adps_monthly_if.s_new_norma,                -- 全新規達成率
          it_xxcos_for_adps_monthly_if.s_new_achievement_rate,     -- 全新規ﾉﾙﾏ
          it_xxcos_for_adps_monthly_if.s_new_count_sum,            -- 全新規件数合計
          it_xxcos_for_adps_monthly_if.s_new_count_vd,             -- 全新規件数ﾍﾞﾝﾀﾞｰ
          it_xxcos_for_adps_monthly_if.s_position_point,           -- 全資格POINT
          it_xxcos_for_adps_monthly_if.s_new_point,                -- 全新規POINT
          cn_created_by,                                           -- 作成者
          cd_creation_date,                                        -- 作成日
          cn_last_updated_by,                                      -- 最終更新者
          cd_last_update_date,                                     -- 最終更新日
          cn_last_update_login,                                    -- 最終更新ログイン
          cn_request_id,                                           -- 要求ID
          cn_program_application_id,                               -- コンカレント・プログラム・アプリケーションID
          cn_program_id,                                           -- コンカレント・プログラムID
          cd_program_update_date                                   -- プログラム更新日
        );
    EXCEPTION
      WHEN OTHERS THEN
-- ************************ 2010/01/22 S.Miyakoshi Var1.6 ADD START ************************ --
        gv_sqlerrm  := SQLERRM;
-- ************************ 2010/01/22 S.Miyakoshi Var1.6 ADD  END  ************************ --
        XXCOS_COMMON_PKG.makeup_key_info(
                                       ov_errbuf      =>  lv_errbuf      --エラー・メッセージ
                                      ,ov_retcode     =>  lv_retcode     --リターンコード
                                      ,ov_errmsg      =>  lv_errmsg      --ユーザ・エラー・メッセージ
                                      ,ov_key_info    =>  lv_key_info    --編集されたキー情報
                                      ,iv_item_name1  =>  cv_str_result_cd
                                      ,iv_item_name2  =>  cv_str_base_nm
                                      ,iv_data_value1 =>  it_xxcos_for_adps_monthly_if.employee_code
                                      ,iv_data_value2 =>  it_xxcos_for_adps_monthly_if.base_code
                                     );
        IF ( lv_retcode = cv_status_normal ) THEN
          lv_table_nm := cv_month_tbl;
          RAISE global_insert_expt;
        ELSE
          RAISE global_api_expt;
        END IF;
    END;
    --==============================================
    -- 2. 人事システム向け販売実績（賞与）テーブルを登録します。
    --==============================================
    BEGIN
      INSERT INTO xxcos_for_adps_bonus_if
        (
          record_id,
          employee_code,
          results_date,
          group_code,
          base_code,
          area_code,
          division_code,
          p_sale_gross,
          p_current_profit,
          p_visit_count,
          g_sale_gross,
          g_current_profit,
          g_visit_count,
          b_sale_gross,
          b_current_profit,
          b_visit_count,
          a_sale_gross,
          a_current_profit,
          a_visit_count,
          d_sale_gross,
          d_current_profit,
          d_visit_count,
          s_sale_gross,
          s_current_profit,
          s_visit_count,
          created_by,
          creation_date,
          last_updated_by,
          last_update_date,
          last_update_login,
          request_id,
          program_application_id,
          program_id,
          program_update_date
        )
      VALUES
        (
          xxcos_for_adps_monthly_if_s01.nextval,                   -- レコードID
          it_xxcos_for_adps_bonus_if.employee_code,                -- 従業員コード
          it_xxcos_for_adps_bonus_if.results_date,                 -- 年月
          it_xxcos_for_adps_bonus_if.group_code,                   -- 小グループコード
          it_xxcos_for_adps_bonus_if.base_code,                    -- 拠点ｺｰﾄﾞ
          it_xxcos_for_adps_bonus_if.area_code,                    -- 地区コード
          it_xxcos_for_adps_bonus_if.division_code,                -- 本部ｺｰﾄﾞ
          it_xxcos_for_adps_bonus_if.p_sale_gross,                 -- 個売上粗利
          it_xxcos_for_adps_bonus_if.p_current_profit,             -- 個経常利益
          it_xxcos_for_adps_bonus_if.p_visit_count,                -- 個訪問件数
          it_xxcos_for_adps_bonus_if.g_sale_gross,                 -- 小売上粗利
          it_xxcos_for_adps_bonus_if.g_current_profit,             -- 小経常利益
          it_xxcos_for_adps_bonus_if.g_visit_count,                -- 小訪問件数
          it_xxcos_for_adps_bonus_if.b_sale_gross,                 -- 拠売上粗利
          it_xxcos_for_adps_bonus_if.b_current_profit,             -- 拠経常利益
          it_xxcos_for_adps_bonus_if.b_visit_count,                -- 拠訪問件数
          it_xxcos_for_adps_bonus_if.a_sale_gross,                 -- 地売上粗利
          it_xxcos_for_adps_bonus_if.a_current_profit,             -- 地経常利益
          it_xxcos_for_adps_bonus_if.a_visit_count,                -- 地訪問件数
          it_xxcos_for_adps_bonus_if.d_sale_gross,                 -- 本売上粗利
          it_xxcos_for_adps_bonus_if.d_current_profit,             -- 本経常利益
          it_xxcos_for_adps_bonus_if.d_visit_count,                -- 本訪問件数
          it_xxcos_for_adps_bonus_if.s_sale_gross,                 -- 全売上粗利
          it_xxcos_for_adps_bonus_if.s_current_profit,             -- 全経常利益
          it_xxcos_for_adps_bonus_if.s_visit_count,                -- 全訪問件数
          cn_created_by,                                           -- 作成者
          cd_creation_date,                                        -- 作成日
          cn_last_updated_by,                                      -- 最終更新者
          cd_last_update_date,                                     -- 最終更新日
          cn_last_update_login,                                    -- 最終更新ログイン
          cn_request_id,                                           -- 要求ID
          cn_program_application_id,                               -- コンカレント・プログラム・アプリケーションID
          cn_program_id,                                           -- コンカレント・プログラムID
          cd_program_update_date                                   -- プログラム更新日
        );
    EXCEPTION
      WHEN OTHERS THEN
-- ************************ 2010/01/22 S.Miyakoshi Var1.6 ADD START ************************ --
        gv_sqlerrm  := SQLERRM;
-- ************************ 2010/01/22 S.Miyakoshi Var1.6 ADD  END  ************************ --
        XXCOS_COMMON_PKG.makeup_key_info(
                                       ov_errbuf      =>  lv_errbuf      --エラー・メッセージ
                                      ,ov_retcode     =>  lv_retcode     --リターンコード
                                      ,ov_errmsg      =>  lv_errmsg      --ユーザ・エラー・メッセージ
                                      ,ov_key_info    =>  lv_key_info    --編集されたキー情報
                                      ,iv_item_name1  =>  cv_str_result_cd
                                      ,iv_item_name2  =>  cv_str_base_nm
                                      ,iv_data_value1 =>  it_xxcos_for_adps_bonus_if.employee_code
                                      ,iv_data_value2 =>  it_xxcos_for_adps_bonus_if.base_code
                                     );
        IF ( lv_retcode = cv_status_normal ) THEN
          lv_table_nm :=cv_bonus_tbl;
          RAISE global_insert_expt;
        ELSE
          RAISE global_api_expt;
        END IF;
    END;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    --登録例外
    WHEN global_insert_expt THEN
      ov_errmsg := xxccp_common_pkg.get_msg(
                      iv_application        =>  cv_current_appl_short_nm
                     ,iv_name               =>  cv_msg_insert_data_err
                     ,iv_token_name1        =>  cv_tkn_table
                     ,iv_token_name2        =>  cv_tkn_key_data
                     ,iv_token_value1       =>  lv_table_nm
                     ,iv_token_value2       =>  lv_key_info
                   );
-- ************************ 2010/01/22 S.Miyakoshi Var1.6 MOD START ************************ --
--      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg||cv_msg_part||gv_sqlerrm,1,5000);
-- ************************ 2010/01/22 S.Miyakoshi Var1.6 MOD  END  ************************ --
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
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
  END set_insert_data;
--
  /**********************************************************************************
   * Procedure Name   : small_group_total
   * Description      : 小グループ集計処理(A-11)
   ***********************************************************************************/
  PROCEDURE small_group_total(
    ov_errbuf       OUT NOCOPY VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode      OUT NOCOPY VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg       OUT NOCOPY VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'small_group_total'; -- プログラム名
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
    -- *** ローカル変数 ***
--
    lv_key_info     VARCHAR2(5000);  --key情報
    ln_sales_money  NUMBER;          --個売上金額
    ln_new_sales    NUMBER;          --個新規貢献売上
    ln_gross_margin NUMBER;          --個計上粗利
    lv_table_nm     VARCHAR2(50);    -- テーブル名
--
    -- *** ローカル・カーソル ***
    --==============================================
    -- 1.月次テーブルの小グループを集計します。
    --==============================================
    CURSOR month_data_cur
    IS
      SELECT base_code                                             as base_code,
             group_code                                            as group_code,
             SUM( p_sale_norma )                                   as sale_norma,
             SUM( p_sale_amount )                                  as sale_amount,
             CASE SUM( p_sale_norma )
               WHEN 0 THEN
                 0
               ELSE
                 ROUND( SUM( p_sale_amount ) / SUM( p_sale_norma ) * 100 ,1 )   
             END                                                   as sale_rate,
             SUM( p_new_contribution_sale )                        as new_contribution_sale,
             SUM( p_new_norma )                                    as new_norma,
             CASE SUM( p_position_point )
               WHEN 0 THEN
                 0
               ELSE
                 ROUND( SUM( p_new_point ) / SUM( p_position_point ) * 100 ,1 )
             END                                                   as new_point_rate,
             SUM( p_new_count_sum )                                as new_count_sum,
             SUM( p_new_count_vd )                                 as new_count_vd,
             SUM( p_position_point )                               as position_point,
             SUM( p_new_point )                                    as new_point
      FROM xxcos_for_adps_monthly_if
      WHERE group_code IS NOT NULL
      GROUP BY base_code,group_code
      ;
    --==============================================
    -- 3.賞与テーブルの小グループを集計します。
    --==============================================
    CURSOR bonus_data_cur
    IS
      SELECT base_code                                             as base_code,
             group_code                                            as group_code,
             SUM( p_sale_gross )                                   as sale_gross,
             SUM( p_current_profit )                               as current_profit,
             SUM( p_visit_count )                                  as visit_count
      FROM xxcos_for_adps_bonus_if
      WHERE group_code IS NOT NULL
      GROUP BY base_code,group_code
      ;
    -- *** ローカル・レコード ***
--
    l_month_data_rec               month_data_cur%ROWTYPE;
    l_bonus_data_rec               bonus_data_cur%ROWTYPE;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    --==============================================================
    --2.月次テーブルの小グループ集計結果を更新します。
    --==============================================================
    <<for_month_loop>>
    FOR l_month_data_rec IN month_data_cur LOOP
      BEGIN
        UPDATE xxcos_for_adps_monthly_if
        SET g_sale_norma            = l_month_data_rec.sale_norma,
            g_sale_amount           = l_month_data_rec.sale_amount,
            g_sale_achievement_rate = l_month_data_rec.sale_rate,
            g_new_contribution_sale = l_month_data_rec.new_contribution_sale,
            g_new_norma             = l_month_data_rec.new_norma,
            g_new_achievement_rate  = l_month_data_rec.new_point_rate,
            g_new_count_sum         = l_month_data_rec.new_count_sum,
            g_new_count_vd          = l_month_data_rec.new_count_vd,
            g_position_point        = l_month_data_rec.position_point,
            g_new_point             = l_month_data_rec.new_point
        WHERE base_code  = l_month_data_rec.base_code
          AND group_code = l_month_data_rec.group_code
        ;
      EXCEPTION
        WHEN OTHERS THEN
-- ************************ 2010/01/22 S.Miyakoshi Var1.6 ADD START ************************ --
          gv_sqlerrm  := SQLERRM;
-- ************************ 2010/01/22 S.Miyakoshi Var1.6 ADD  END  ************************ --
          XXCOS_COMMON_PKG.makeup_key_info(
                                         ov_errbuf      =>  lv_errbuf      --エラー・メッセージ
                                        ,ov_retcode     =>  lv_retcode     --リターンコード
                                        ,ov_errmsg      =>  lv_errmsg      --ユーザ・エラー・メッセージ
                                        ,ov_key_info    =>  lv_key_info    --編集されたキー情報
                                        ,iv_item_name1  =>  cv_str_base_nm
                                        ,iv_item_name2  =>  cv_str_group_nm
                                        ,iv_data_value1 =>  l_month_data_rec.base_code
                                        ,iv_data_value2 =>  l_month_data_rec.group_code
                                       );
          IF ( lv_retcode = cv_status_normal ) THEN
            lv_table_nm := cv_month_tbl;
            RAISE global_update_expt;
          ELSE
            RAISE global_api_expt;
          END IF;
      END;
    END LOOP for_month_loop;
--  --==============================================================
    --4.賞与テーブルの小グループ集計結果を更新します。
    --==============================================================
    <<for_bonus_loop>>
    FOR l_bonus_data_rec IN bonus_data_cur LOOP
      BEGIN
        UPDATE xxcos_for_adps_bonus_if
        SET g_sale_gross            = l_bonus_data_rec.sale_gross,
            g_current_profit        = l_bonus_data_rec.current_profit,
            g_visit_count           = l_bonus_data_rec.visit_count
        WHERE base_code  = l_bonus_data_rec.base_code
          AND group_code = l_bonus_data_rec.group_code
        ;
      EXCEPTION
        WHEN OTHERS THEN
-- ************************ 2010/01/22 S.Miyakoshi Var1.6 ADD START ************************ --
          gv_sqlerrm  := SQLERRM;
-- ************************ 2010/01/22 S.Miyakoshi Var1.6 ADD  END  ************************ --
          XXCOS_COMMON_PKG.makeup_key_info(
                                         ov_errbuf      =>  lv_errbuf      --エラー・メッセージ
                                        ,ov_retcode     =>  lv_retcode     --リターンコード
                                        ,ov_errmsg      =>  lv_errmsg      --ユーザ・エラー・メッセージ
                                        ,ov_key_info    =>  lv_key_info    --編集されたキー情報
                                        ,iv_item_name1  =>  cv_str_base_nm
                                        ,iv_item_name2  =>  cv_str_group_nm
                                        ,iv_data_value1 =>  l_bonus_data_rec.base_code
                                        ,iv_data_value2 =>  l_bonus_data_rec.group_code
                                       );
          IF ( lv_retcode = cv_status_normal ) THEN
            lv_table_nm := cv_bonus_tbl;
            RAISE global_update_expt;
          ELSE
            RAISE global_api_expt;
          END IF;
      END;
    END LOOP for_bonus_loop;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    -- 更新例外
    WHEN global_update_expt THEN
      ov_errmsg := xxccp_common_pkg.get_msg(
                      iv_application        =>  cv_current_appl_short_nm
                     ,iv_name               =>  cv_msg_get_update_err
                     ,iv_token_name1        =>  cv_tkn_table
                     ,iv_token_name2        =>  cv_tkn_key_data
                     ,iv_token_value1       =>  lv_table_nm
                     ,iv_token_value2       =>  lv_key_info
                   );
-- ************************ 2010/01/22 S.Miyakoshi Var1.6 MOD START ************************ --
--      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg||cv_msg_part||gv_sqlerrm,1,5000);
-- ************************ 2010/01/22 S.Miyakoshi Var1.6 MOD  END  ************************ --
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
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
  END small_group_total;
--
  /**********************************************************************************
   * Procedure Name   : base_total
   * Description      : 拠点集計処理(A-12)
   ***********************************************************************************/
  PROCEDURE base_total(
    ov_errbuf       OUT NOCOPY VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode      OUT NOCOPY VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg       OUT NOCOPY VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'base_total'; -- プログラム名
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
    -- *** ローカル変数 ***
--
    lv_key_info     VARCHAR2(5000);  --key情報
    ln_sales_money  NUMBER;          --個売上金額
    ln_new_sales    NUMBER;          --個新規貢献売上
    ln_gross_margin NUMBER;          --個計上粗利
    lv_table_nm     VARCHAR2(50);    -- テーブル名
    -- *** ローカル・カーソル ***
--
    --==============================================
    -- 1.月次テーブルの拠点を集計します。
    --==============================================
    CURSOR month_data_cur
    IS
      SELECT base_code                                             as base_code,
             SUM( p_sale_norma )                                   as sale_norma,
             SUM( p_sale_amount )                                  as sale_amount,
             CASE SUM( p_sale_norma )
               WHEN 0 THEN
                 0
               ELSE
                 ROUND( SUM( p_sale_amount )/SUM( p_sale_norma )*100,1 )   
             END                                                   as sale_rate,
             SUM( p_new_contribution_sale )                        as new_contribution_sale,
             SUM( p_new_norma )                                    as new_norma,
             CASE SUM( p_position_point )
               WHEN 0 THEN
                 0
               ELSE
                 ROUND( SUM( p_new_point )/SUM( p_position_point )*100,1 )
             END                                                   as new_point_rate,
             SUM( p_new_count_sum )                                as new_count_sum,
             SUM( p_new_count_vd )                                 as new_count_vd,
             SUM( p_position_point )                               as position_point,
             SUM( p_new_point )                                    as new_point
      FROM xxcos_for_adps_monthly_if
      GROUP BY base_code
      ;
    --==============================================
    -- 4.賞与テーブルの拠点を集計します。
    --==============================================
    CURSOR bonus_data_cur
    IS
      SELECT base_code                                             as base_code,
             SUM( p_sale_gross )                                   as sale_gross,
             SUM( p_current_profit )                               as current_profit,
             SUM( p_visit_count )                                  as visit_count
      FROM xxcos_for_adps_bonus_if
      GROUP BY base_code
      ;
    -- *** ローカル・レコード ***
    l_month_data_rec               month_data_cur%ROWTYPE;
    l_bonus_data_rec               bonus_data_cur%ROWTYPE;
--
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
    --月次
    <<for_month_loop>>
    FOR l_month_data_rec IN month_data_cur LOOP
      BEGIN
        --==============================================================
        --2.月次テーブルの拠点集計結果を更新します。
        --==============================================================
        UPDATE xxcos_for_adps_monthly_if
        SET b_sale_norma            = l_month_data_rec.sale_norma,
            b_sale_amount           = l_month_data_rec.sale_amount,
            b_sale_achievement_rate = l_month_data_rec.sale_rate,
            b_new_contribution_sale = l_month_data_rec.new_contribution_sale,
            b_new_norma             = l_month_data_rec.new_norma,
            b_new_achievement_rate  = l_month_data_rec.new_point_rate,
            b_new_count_sum         = l_month_data_rec.new_count_sum,
            b_new_count_vd          = l_month_data_rec.new_count_vd,
            b_position_point        = l_month_data_rec.position_point,
            b_new_point             = l_month_data_rec.new_point
        WHERE base_code  = l_month_data_rec.base_code
        ;
        --保留
        --==============================================================
        --3.月次テーブルの拠点集計結果を小グループに更新します。
        --==============================================================
--        UPDATE xxcos_for_adps_monthly_if
--        SET g_sale_norma            = l_month_data_rec.sale_norma,
--            g_sale_amount           = l_month_data_rec.sale_amount,
--            g_sale_achievement_rate = l_month_data_rec.sale_rate,
--            g_new_contribution_sale = l_month_data_rec.new_contribution_sale,
--            g_new_norma             = l_month_data_rec.new_norma,
--            g_new_achievement_rate  = l_month_data_rec.new_point_rate,
--            g_new_count_sum         = l_month_data_rec.new_count_sum,
--            g_new_count_vd          = l_month_data_rec.new_count_vd,
--            g_position_point        = l_month_data_rec.position_point,
--            g_new_point             = l_month_data_rec.new_point
--        WHERE base_code  = l_month_data_rec.base_code
--          AND group_code IS NULL
--        ;
      EXCEPTION
        WHEN OTHERS THEN
-- ************************ 2010/01/22 S.Miyakoshi Var1.6 ADD START ************************ --
          gv_sqlerrm  := SQLERRM;
-- ************************ 2010/01/22 S.Miyakoshi Var1.6 ADD  END  ************************ --
          XXCOS_COMMON_PKG.makeup_key_info(
                                         ov_errbuf      =>  lv_errbuf      --エラー・メッセージ
                                        ,ov_retcode     =>  lv_retcode     --リターンコード
                                        ,ov_errmsg      =>  lv_errmsg      --ユーザ・エラー・メッセージ
                                        ,ov_key_info    =>  lv_key_info    --編集されたキー情報
                                        ,iv_item_name1  =>  cv_str_base_nm
                                        ,iv_data_value1 =>  l_month_data_rec.base_code
                                       );
          IF ( lv_retcode = cv_status_normal ) THEN
            lv_table_nm := cv_month_tbl;
            RAISE global_update_expt;
          ELSE
            RAISE global_api_expt;
          END IF;
      END;
    END LOOP for_month_loop;
    --賞与
    <<for_bonus_loop>>
    FOR l_bonus_data_rec IN bonus_data_cur LOOP
      BEGIN
        --==============================================================
        --5.賞与テーブルの拠点集計結果を更新します。
        --==============================================================
        UPDATE xxcos_for_adps_bonus_if
        SET b_sale_gross            = l_bonus_data_rec.sale_gross,
            b_current_profit        = l_bonus_data_rec.current_profit,
            b_visit_count           = l_bonus_data_rec.visit_count
        WHERE base_code  = l_bonus_data_rec.base_code
        ;
        --保留
        --==============================================================
        --6.賞与テーブルの拠点集計結果を小グループに更新します。
        --==============================================================
--        UPDATE xxcos_for_adps_bonus_if
--        SET g_sale_gross            = l_bonus_data_rec.sale_gross,
--            g_current_profit        = l_bonus_data_rec.current_profit,
--            g_visit_count           = l_bonus_data_rec.visit_count
--        WHERE base_code  = l_bonus_data_rec.base_code
--          AND group_code IS NULL
--        ;
      EXCEPTION
        WHEN OTHERS THEN
-- ************************ 2010/01/22 S.Miyakoshi Var1.6 ADD START ************************ --
          gv_sqlerrm  := SQLERRM;
-- ************************ 2010/01/22 S.Miyakoshi Var1.6 ADD  END  ************************ --
          XXCOS_COMMON_PKG.makeup_key_info(
                                         ov_errbuf      =>  lv_errbuf      --エラー・メッセージ
                                        ,ov_retcode     =>  lv_retcode     --リターンコード
                                        ,ov_errmsg      =>  lv_errmsg      --ユーザ・エラー・メッセージ
                                        ,ov_key_info    =>  lv_key_info    --編集されたキー情報
                                        ,iv_item_name1  =>  cv_str_base_nm
                                        ,iv_data_value1 =>  l_bonus_data_rec.base_code
                                       );
          IF ( lv_retcode = cv_status_normal ) THEN
            lv_table_nm :=cv_bonus_tbl;
            RAISE global_update_expt;
          ELSE
            RAISE global_api_expt;
          END IF;
      END;
    END LOOP for_bonus_loop;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    -- 更新例外
    WHEN global_update_expt THEN
      ov_errmsg := xxccp_common_pkg.get_msg(
                      iv_application        =>  cv_current_appl_short_nm
                     ,iv_name               =>  cv_msg_get_update_err
                     ,iv_token_name1        =>  cv_tkn_table
                     ,iv_token_name2        =>  cv_tkn_key_data
                     ,iv_token_value1       =>  lv_table_nm
                     ,iv_token_value2       =>  lv_key_info
                   );
-- ************************ 2010/01/22 S.Miyakoshi Var1.6 MOD START ************************ --
--      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg||cv_msg_part||gv_sqlerrm,1,5000);
-- ************************ 2010/01/22 S.Miyakoshi Var1.6 MOD  END  ************************ --
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
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
  END base_total;
--
  /**********************************************************************************
   * Procedure Name   : area_total
   * Description      : 地区集計処理(A-13)
   ***********************************************************************************/
  PROCEDURE area_total(
    ov_errbuf       OUT NOCOPY VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode      OUT NOCOPY VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg       OUT NOCOPY VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'area_total'; -- プログラム名
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
    -- *** ローカル変数 ***
--
    lv_key_info     VARCHAR2(5000);  --key情報
    ln_sales_money  NUMBER;          --個売上金額
    ln_new_sales    NUMBER;          --個新規貢献売上
    ln_gross_margin NUMBER;          --個計上粗利
    lv_table_nm     VARCHAR2(50);    -- テーブル名
    -- *** ローカル・カーソル ***
--
    --==============================================
    -- 1.月次テーブルの地区を集計します。
    --==============================================
    CURSOR month_data_cur
    IS
      SELECT area_code                                             as area_code,
             SUM( p_sale_norma )                                   as sale_norma,
             SUM( p_sale_amount )                                  as sale_amount,
             CASE SUM( p_sale_norma )
               WHEN 0 THEN
                 0
               ELSE
                 ROUND( SUM( p_sale_amount )/SUM( p_sale_norma )*100,1 )   
             END                                                   as sale_rate,
             SUM( p_new_contribution_sale )                        as new_contribution_sale,
             SUM( p_new_norma )                                    as new_norma,
             CASE SUM(p_position_point)
               WHEN 0 THEN
                 0
               ELSE
                 ROUND( SUM( p_new_point )/SUM( p_position_point )*100,1 )
             END                                                   as new_point_rate,
             SUM( p_new_count_sum )                                as new_count_sum,
             SUM( p_new_count_vd )                                 as new_count_vd,
             SUM( p_position_point )                               as position_point,
             SUM( p_new_point )                                    as new_point
      FROM xxcos_for_adps_monthly_if
      GROUP BY area_code
      ;
--
    --==============================================
    -- 3.賞与テーブルの地区を集計します。
    --==============================================
    CURSOR bonus_data_cur
    IS
      SELECT area_code                                             as area_code,
             SUM( p_sale_gross )                                   as sale_gross,
             SUM( p_current_profit )                               as current_profit,
             SUM( p_visit_count )                                  as visit_count
      FROM xxcos_for_adps_bonus_if
      GROUP BY area_code
      ;
    l_month_data_rec               month_data_cur%ROWTYPE;
    l_bonus_data_rec               bonus_data_cur%ROWTYPE;
    -- *** ローカル・レコード ***
--
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    --==============================================================
    --2.月次テーブルの地区集計結果を更新します。
    --==============================================================
    <<for_month_loop>>
    FOR l_month_data_rec IN month_data_cur LOOP
      BEGIN
        UPDATE xxcos_for_adps_monthly_if
        SET a_sale_norma            = l_month_data_rec.sale_norma,
            a_sale_amount           = l_month_data_rec.sale_amount,
            a_sale_achievement_rate = l_month_data_rec.sale_rate,
            a_new_contribution_sale = l_month_data_rec.new_contribution_sale,
            a_new_norma             = l_month_data_rec.new_norma,
            a_new_achievement_rate  = l_month_data_rec.new_point_rate,
            a_new_count_sum         = l_month_data_rec.new_count_sum,
            a_new_count_vd          = l_month_data_rec.new_count_vd,
            a_position_point        = l_month_data_rec.position_point,
            a_new_point             = l_month_data_rec.new_point
        WHERE area_code  = l_month_data_rec.area_code
        ;
      EXCEPTION
        WHEN OTHERS THEN
-- ************************ 2010/01/22 S.Miyakoshi Var1.6 ADD START ************************ --
          gv_sqlerrm  := SQLERRM;
-- ************************ 2010/01/22 S.Miyakoshi Var1.6 ADD  END  ************************ --
          XXCOS_COMMON_PKG.makeup_key_info(
                                         ov_errbuf      =>  lv_errbuf      --エラー・メッセージ
                                        ,ov_retcode     =>  lv_retcode     --リターンコード
                                        ,ov_errmsg      =>  lv_errmsg      --ユーザ・エラー・メッセージ
                                        ,ov_key_info    =>  lv_key_info    --編集されたキー情報
                                        ,iv_item_name1  =>  cv_str_area_nm
                                        ,iv_data_value1 =>  l_month_data_rec.area_code
                                       );
          IF ( lv_retcode = cv_status_normal ) THEN
            lv_table_nm := cv_month_tbl;
            RAISE global_update_expt;
          ELSE
            RAISE global_api_expt;
          END IF;
      END;
    END LOOP for_month_loop;
--
    --==============================================================
    --4.賞与テーブルの地区集計結果を更新します。
    --==============================================================
    <<for_bonus_loop>>
    FOR l_bonus_data_rec IN bonus_data_cur LOOP
      BEGIN
        UPDATE xxcos_for_adps_bonus_if
        SET a_sale_gross            = l_bonus_data_rec.sale_gross,
            a_current_profit        = l_bonus_data_rec.current_profit,
            a_visit_count           = l_bonus_data_rec.visit_count
        WHERE area_code  = l_bonus_data_rec.area_code
        ;
      EXCEPTION
        WHEN OTHERS THEN
-- ************************ 2010/01/22 S.Miyakoshi Var1.6 ADD START ************************ --
          gv_sqlerrm  := SQLERRM;
-- ************************ 2010/01/22 S.Miyakoshi Var1.6 ADD  END  ************************ --
          XXCOS_COMMON_PKG.makeup_key_info(
                                         ov_errbuf      =>  lv_errbuf      --エラー・メッセージ
                                        ,ov_retcode     =>  lv_retcode     --リターンコード
                                        ,ov_errmsg      =>  lv_errmsg      --ユーザ・エラー・メッセージ
                                        ,ov_key_info    =>  lv_key_info    --編集されたキー情報
                                        ,iv_item_name1  =>  cv_str_area_nm
                                        ,iv_data_value1 =>  l_bonus_data_rec.area_code
                                       );
          IF ( lv_retcode = cv_status_normal ) THEN
            lv_table_nm :=cv_bonus_tbl;
            RAISE global_update_expt;
          ELSE
            RAISE global_api_expt;
          END IF;
      END;
    END LOOP for_bonus_loop;
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
    -- 更新例外
    WHEN global_update_expt THEN
      ov_errmsg := xxccp_common_pkg.get_msg(
                      iv_application        =>  cv_current_appl_short_nm
                     ,iv_name               =>  cv_msg_get_update_err
                     ,iv_token_name1        =>  cv_tkn_table
                     ,iv_token_name2        =>  cv_tkn_key_data
                     ,iv_token_value1       =>  lv_table_nm
                     ,iv_token_value2       =>  lv_key_info
                   );
-- ************************ 2010/01/22 S.Miyakoshi Var1.6 MOD START ************************ --
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg||cv_msg_part||gv_sqlerrm,1,5000);
-- ************************ 2010/01/22 S.Miyakoshi Var1.6 MOD  END  ************************ --
      ov_retcode := cv_status_error;
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
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
  END area_total;
--
  /**********************************************************************************
   * Procedure Name   : div_total
   * Description      : 本部集計処理(A-14)
   ***********************************************************************************/
  PROCEDURE div_total(
    ov_errbuf       OUT NOCOPY VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode      OUT NOCOPY VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg       OUT NOCOPY VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'div_total'; -- プログラム名
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
    -- *** ローカル変数 ***
--
    lv_key_info     VARCHAR2(5000);  --key情報
    ln_sales_money  NUMBER;          --個売上金額
    ln_new_sales    NUMBER;          --個新規貢献売上
    ln_gross_margin NUMBER;          --個計上粗利
    lv_table_nm     VARCHAR2(50);    -- テーブル名
    -- *** ローカル・カーソル ***
--
    --==============================================
    -- 1.月次テーブルの本部を集計します。
    --==============================================
    CURSOR month_data_cur
    IS
      SELECT division_code                                         as division_code,
             SUM( p_sale_norma )                                   as sale_norma,
             SUM( p_sale_amount )                                  as sale_amount,
             CASE SUM( p_sale_norma )
               WHEN 0 THEN
                 0
               ELSE
                 ROUND( SUM( p_sale_amount )/SUM( p_sale_norma )*100,1 )   
             END                                                   as sale_rate,
             SUM( p_new_contribution_sale )                        as new_contribution_sale,
             SUM( p_new_norma )                                    as new_norma,
             CASE SUM( p_position_point )
               WHEN 0 THEN
                 0
               ELSE
                 ROUND( SUM( p_new_point )/SUM( p_position_point )*100,1 )
             END                                                   as new_point_rate,
             SUM( p_new_count_sum )                                as new_count_sum,
             SUM( p_new_count_vd )                                 as new_count_vd,
             SUM( p_position_point )                               as position_point,
             SUM( p_new_point )                                    as new_point
      FROM xxcos_for_adps_monthly_if
      GROUP BY division_code
      ;
--
    --==============================================
    -- 3.賞与テーブルの本部を集計します。
    --==============================================
    CURSOR bonus_data_cur
    IS
      SELECT division_code                                       as division_code,
             SUM(p_sale_gross)                                   as sale_gross,
             SUM(p_current_profit)                               as current_profit,
             SUM(p_visit_count)                                  as visit_count
      FROM xxcos_for_adps_bonus_if
      GROUP BY division_code
      ;
--
    l_month_data_rec               month_data_cur%ROWTYPE;
    l_bonus_data_rec               bonus_data_cur%ROWTYPE;
    -- *** ローカル・レコード ***
--
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    --==============================================================
    --2.月次テーブルの本部集計結果を更新します。
    --==============================================================
    <<for_month_loop>>
    FOR l_month_data_rec IN month_data_cur LOOP
      BEGIN
        UPDATE xxcos_for_adps_monthly_if
        SET d_sale_norma            = l_month_data_rec.sale_norma,
            d_sale_amount           = l_month_data_rec.sale_amount,
            d_sale_achievement_rate = l_month_data_rec.sale_rate,
            d_new_contribution_sale = l_month_data_rec.new_contribution_sale,
            d_new_norma             = l_month_data_rec.new_norma,
            d_new_achievement_rate  = l_month_data_rec.new_point_rate,
            d_new_count_sum         = l_month_data_rec.new_count_sum,
            d_new_count_vd          = l_month_data_rec.new_count_vd,
            d_position_point        = l_month_data_rec.position_point,
            d_new_point             = l_month_data_rec.new_point
        WHERE division_code  = l_month_data_rec.division_code
        ;
      EXCEPTION
        WHEN OTHERS THEN
-- ************************ 2010/01/22 S.Miyakoshi Var1.6 ADD START ************************ --
        gv_sqlerrm  := SQLERRM;
-- ************************ 2010/01/22 S.Miyakoshi Var1.6 ADD  END  ************************ --
        XXCOS_COMMON_PKG.makeup_key_info(
                                       ov_errbuf      =>  lv_errbuf      --エラー・メッセージ
                                      ,ov_retcode     =>  lv_retcode     --リターンコード
                                      ,ov_errmsg      =>  lv_errmsg      --ユーザ・エラー・メッセージ
                                      ,ov_key_info    =>  lv_key_info    --編集されたキー情報
                                      ,iv_item_name1  =>  cv_str_div_nm
                                      ,iv_data_value1 =>  l_month_data_rec.division_code
                                     );
          IF ( lv_retcode = cv_status_normal ) THEN
            lv_table_nm :=cv_month_tbl;
            RAISE global_update_expt;
          ELSE
            RAISE global_api_expt;
          END IF;
      END;
    END LOOP for_month_loop;
    --==============================================================
    --4.賞与テーブルの本部集計結果を更新します。
    --==============================================================
    <<for_bonus_loop>>
    FOR l_bonus_data_rec IN bonus_data_cur LOOP
      BEGIN
        UPDATE xxcos_for_adps_bonus_if
        SET d_sale_gross            = l_bonus_data_rec.sale_gross,
            d_current_profit        = l_bonus_data_rec.current_profit,
            d_visit_count           = l_bonus_data_rec.visit_count
        WHERE division_code         = l_bonus_data_rec.division_code
        ;
      EXCEPTION
        WHEN OTHERS THEN
-- ************************ 2010/01/22 S.Miyakoshi Var1.6 ADD START ************************ --
        gv_sqlerrm  := SQLERRM;
-- ************************ 2010/01/22 S.Miyakoshi Var1.6 ADD  END  ************************ --
        XXCOS_COMMON_PKG.makeup_key_info(
                                       ov_errbuf      =>  lv_errbuf      --エラー・メッセージ
                                      ,ov_retcode     =>  lv_retcode     --リターンコード
                                      ,ov_errmsg      =>  lv_errmsg      --ユーザ・エラー・メッセージ
                                      ,ov_key_info    =>  lv_key_info    --編集されたキー情報
                                      ,iv_item_name1  =>  cv_str_div_nm
                                      ,iv_data_value1 =>  l_bonus_data_rec.division_code
                                     );
          IF ( lv_retcode = cv_status_normal ) THEN
            lv_table_nm :=cv_bonus_tbl;
            RAISE global_update_expt;
          ELSE
            RAISE global_api_expt;
          END IF;
      END;
    END LOOP for_bonus_loop;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
    -- 更新例外
    WHEN global_update_expt THEN
      ov_errmsg := xxccp_common_pkg.get_msg(
                      iv_application        =>  cv_current_appl_short_nm
                     ,iv_name               =>  cv_msg_get_update_err
                     ,iv_token_name1        =>  cv_tkn_table
                     ,iv_token_name2        =>  cv_tkn_key_data
                     ,iv_token_value1       =>  lv_table_nm
                     ,iv_token_value2       =>  lv_key_info
                   );
-- ************************ 2010/01/22 S.Miyakoshi Var1.6 MOD START ************************ --
--      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg||cv_msg_part||gv_sqlerrm,1,5000);
-- ************************ 2010/01/22 S.Miyakoshi Var1.6 MOD  END  ************************ --
      ov_retcode := cv_status_error;
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
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
  END div_total;
--
  /**********************************************************************************
   * Procedure Name   : sum_total
   * Description      : 全社集計処理(A-15)
   ***********************************************************************************/
  PROCEDURE sum_total(
    ov_errbuf       OUT NOCOPY VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode      OUT NOCOPY VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg       OUT NOCOPY VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'sum_total'; -- プログラム名
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
    -- *** ローカル変数 ***
--
    lv_key_info     VARCHAR2(5000);  --key情報
    ln_sales_money  NUMBER;          --個売上金額
    ln_new_sales    NUMBER;          --個新規貢献売上
    ln_gross_margin NUMBER;          --個計上粗利
    lv_table_nm     VARCHAR2(50);    -- テーブル名
    -- *** ローカル・カーソル ***
--
    --==============================================
    -- 1.月次テーブルの全社を集計します。
    --==============================================
    CURSOR month_data_cur
    IS
      SELECT SUM( p_sale_norma )                                   as sale_norma,
             SUM( p_sale_amount )                                  as sale_amount,
             CASE SUM( p_sale_norma )
               WHEN 0 THEN
                 0
               ELSE
                 ROUND( SUM( p_sale_amount )/SUM( p_sale_norma )*100,1 )   
             END                                                   as sale_rate,
             SUM( p_new_contribution_sale )                        as new_contribution_sale,
             SUM( p_new_norma )                                    as new_norma,
             CASE SUM( p_position_point )
               WHEN 0 THEN
                 0
               ELSE
                 ROUND( SUM( p_new_point )/SUM( p_position_point )*100,1 )
             END                                                   as new_point_rate,
             SUM( p_new_count_sum )                                as new_count_sum,
             SUM( p_new_count_vd )                                 as new_count_vd,
             SUM( p_position_point )                               as position_point,
             SUM( p_new_point )                                    as new_point
      FROM xxcos_for_adps_monthly_if
      ;
--
    --==============================================
    -- 3.賞与テーブルの全社を集計します。
    --==============================================
    CURSOR bonus_data_cur
    IS
      SELECT SUM( p_sale_gross )                                   as sale_gross,
             SUM( p_current_profit )                               as current_profit,
             SUM( p_visit_count )                                  as visit_count
      FROM xxcos_for_adps_bonus_if
      ;
--
    l_month_data_rec               month_data_cur%ROWTYPE;
    l_bonus_data_rec               bonus_data_cur%ROWTYPE;
    -- *** ローカル・レコード ***
--
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    --==============================================================
    --2.月次テーブルの全社集計結果を更新します。
    --==============================================================
    <<for_month_loop>>
    FOR l_month_data_rec IN month_data_cur LOOP
      BEGIN
        UPDATE xxcos_for_adps_monthly_if
        SET s_sale_norma            = l_month_data_rec.sale_norma,
            s_sale_amount           = l_month_data_rec.sale_amount,
            s_sale_achievement_rate = l_month_data_rec.sale_rate,
            s_new_contribution_sale = l_month_data_rec.new_contribution_sale,
            s_new_norma             = l_month_data_rec.new_norma,
            s_new_achievement_rate  = l_month_data_rec.new_point_rate,
            s_new_count_sum         = l_month_data_rec.new_count_sum,
            s_new_count_vd          = l_month_data_rec.new_count_vd,
            s_position_point        = l_month_data_rec.position_point,
            s_new_point             = l_month_data_rec.new_point
        ;
      EXCEPTION
        WHEN OTHERS THEN
-- ************************ 2010/01/22 S.Miyakoshi Var1.6 MOD START ************************ --
--          lv_table_nm :=cv_bonus_tbl;
          gv_sqlerrm  := SQLERRM;
          lv_table_nm := cv_month_tbl;
-- ************************ 2010/01/22 S.Miyakoshi Var1.6 MOD  END  ************************ --
          RAISE global_update_expt;
      END;
    END LOOP for_month_loop;
    --==============================================================
    --4.賞与テーブルの全社集計結果を更新します。
    --==============================================================
    <<for_bonus_loop>>
    FOR l_bonus_data_rec IN bonus_data_cur LOOP
      BEGIN
        UPDATE xxcos_for_adps_bonus_if
        SET s_sale_gross            = l_bonus_data_rec.sale_gross,
            s_current_profit        = l_bonus_data_rec.current_profit,
            s_visit_count           = l_bonus_data_rec.visit_count
        ;
      EXCEPTION
        WHEN OTHERS THEN
-- ************************ 2010/01/22 S.Miyakoshi Var1.6 ADD START ************************ --
          gv_sqlerrm  := SQLERRM;
-- ************************ 2010/01/22 S.Miyakoshi Var1.6 ADD START ************************ --
          lv_table_nm :=cv_bonus_tbl;
          RAISE global_update_expt;
      END;
    END LOOP for_bonus_loop;
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    -- 更新例外
    WHEN global_update_expt THEN
      ov_errmsg := xxccp_common_pkg.get_msg(
                      iv_application        =>  cv_current_appl_short_nm
                     ,iv_name               =>  cv_msg_get_update_err
                     ,iv_token_name1        =>  cv_tkn_table
                     ,iv_token_name2        =>  cv_tkn_key_data
                     ,iv_token_value1       =>  lv_table_nm
                     ,iv_token_value2       =>  lv_key_info
                   );
-- ************************ 2010/01/22 S.Miyakoshi Var1.6 MOD START ************************ --
--      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg||cv_msg_part||gv_sqlerrm,1,5000);
-- ************************ 2010/01/22 S.Miyakoshi Var1.6 MOD  END  ************************ --
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
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
  END sum_total;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    iv_make_date  IN  VARCHAR2,     --   1.作成年月
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
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
    -- *** ローカル型   ***
    -- *** ローカル定数 ***
--
    ci_bulk_size CONSTANT PLS_INTEGER := 10;
    -- *** ローカル変数 ***
--
    lv_key_info                  VARCHAR2(5000);                      -- key情報
    lv_make_date                 VARCHAR2(7);                         -- 作成日日付
    ld_start_date                DATE;                                -- 会計開始日
    ld_end_date                  DATE;                                -- 会計終了日
    ld_month_first_date          DATE;                                -- 当月開始日
    ld_month_next_date           DATE;                                -- 当月終了日
    ln_err_flg                   NUMBER;                              -- ローカルエラーフラグ
    lv_table_nm                  VARCHAR2(50) := cv_employee_view;    -- テーブル名
    ln_snq_no                    NUMBER;                              -- シーケンスNO
    lv_group_cd                  VARCHAR2(2);                         -- グループ
    lv_base_cd                   VARCHAR2(4);                         -- 拠点コード
    lv_area_cd                   VARCHAR2(3);                         -- エリアコード
    lv_div_cd                    VARCHAR2(4);                         -- 本部コード
--
    lt_xxcos_for_adps_monthly_if xxcos_for_adps_monthly_if%ROWTYPE;
    lt_xxcos_for_adps_bonus_if   xxcos_for_adps_bonus_if%ROWTYPE;
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    -- A-4 対象従業員取得処理
    CURSOR data_cur
    IS
-- == 2010/04/20 1.7 Mod START ===============================================================
---- ************************ 2009/10/19 S.Miyakoshi Var1.5 MOD START ************************ --
----      SELECT division_code           as div_cd,             --本部コード
--      SELECT DISTINCT
--             division_code           AS div_cd,             --本部コード
---- ************************ 2009/10/19 S.Miyakoshi Var1.5 MOD  END  ************************ --
--             area_code               AS area,               --地区コード
--             base_code               AS base,               --拠点コード
--             group_cd                AS group_cd,           --グループコード
--             employee_number         AS code,               --従業員コード
--             ori_division_code       AS ori_division_code   --オリジナル本部コード
      SELECT DISTINCT
             CASE
               WHEN aff_effective_date <= ld_month_next_date  THEN
                    new_area_code
               ELSE old_area_code
             END                           AS area,               --地区コード
             CASE
               WHEN aff_effective_date <= ld_month_next_date  THEN
                    new_division_code
               ELSE old_division_code
             END                           AS div_cd,             --本部コード
             CASE
               WHEN aff_effective_date <= ld_month_next_date  THEN
                    new_ori_division_code
               ELSE old_ori_division_code
             END                           AS ori_division_code,    --オリジナル本部コード
             base_code                     AS base,                 --拠点コード
             group_cd                      AS group_cd,             --グループコード
             employee_number               AS code                  --従業員コード
-- == 2010/04/20 1.7 Mod End ===============================================================
      FROM XXCOS_EMPLOYEE_V
      WHERE (announcement_start_day <= ld_month_next_date
        AND  announcement_end_day   >= ld_month_first_date)
-- == 2010/04/20 1.7 Del START ===============================================================
--        AND ld_month_next_date BETWEEN add_on_start_date AND add_on_end_date
-- == 2010/04/20 1.7 Del END ===============================================================
-- == 2010/05/26 1.8 Mod START ===============================================================
--        AND ld_month_next_date BETWEEN effective_start_date AND effective_end_date
--        AND ld_month_next_date BETWEEN asaiment_start_date AND asaiment_end_date
        AND (effective_start_date   <= ld_month_next_date
        AND  effective_end_date     >= ld_month_first_date)
        AND (asaiment_start_date    <= ld_month_next_date
        AND  asaiment_end_date      >= ld_month_first_date)
-- == 2010/05/26 1.8 Mod End =================================================================
      ;
    TYPE t_datacur IS TABLE OF data_cur%ROWTYPE INDEX BY BINARY_INTEGER;
    l_data_rec        t_datacur;
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
    gn_warn_cnt   := 0;
--
    --*********************************************
    --***      MD.050のフロー図を表す           ***
    --***      分岐と処理部の呼び出しを行う     ***
    --*********************************************
--
    lv_make_date := iv_make_date;
--
    -- ===============================
    -- A-0.初期処理
    -- ===============================
    init(
       lv_make_date   -- 1.作成年月
      ,lv_errbuf      -- エラー・メッセージ           --# 固定 #
      ,lv_retcode     -- リターン・コード             --# 固定 #
      ,lv_errmsg      -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_common_expt;
    END IF;
--
    -- ===============================
    -- A-1.パラメータチェック
    -- ===============================
    pra_chk(
       lv_make_date   -- 1.作成年月
      ,lv_errbuf      -- エラー・メッセージ           --# 固定 #
      ,lv_retcode     -- リターン・コード             --# 固定 #
      ,lv_errmsg      -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_common_expt;
    END IF;
--
    --当月開始終了日
    ld_month_first_date := TO_DATE(lv_make_date || cv_sla || cv_01,cv_format_yyyymmdd);
    ld_month_next_date  := ADD_MONTHS(ld_month_first_date,cn_1) -1;
--
    -- ===============================
    -- A-2. 共通データ取得
    -- ===============================
    get_common_data(
       ld_month_first_date   -- 作成年月
      ,ld_start_date         -- 会計開始日
      ,ld_end_date           -- 会計終了日
      ,lv_errbuf             -- エラー・メッセージ           --# 固定 #
      ,lv_retcode            -- リターン・コード             --# 固定 #
      ,lv_errmsg             -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_common_expt;
    END IF;
--
    -- ===============================
    -- A-3. 月次・賞与中間テーブル初期化処理
    -- ===============================
    -- ===============================
    -- 1.人事システム向け販売実績（月次）テーブルの削除を行います。
    -- ===============================
    --テーブルロック
    lock_table(
       cv_month_tbl_name -- テーブル名
      ,lv_errbuf         -- エラー・メッセージ           --# 固定 #
      ,lv_retcode        -- リターン・コード             --# 固定 #
      ,lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF ( lv_retcode = cv_status_error ) THEN
       lv_errmsg := xxccp_common_pkg.get_msg( cv_current_appl_short_nm
                                             ,cv_msg_table_lock_err
                                             ,cb_tkn_table_on
                                             ,cv_month_tbl);
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END IF;
--
    --テーブルデータ削除
    delete_table(
       cv_month_tbl_name -- テーブル名
      ,lv_errbuf         -- エラー・メッセージ           --# 固定 #
      ,lv_retcode        -- リターン・コード             --# 固定 #
      ,lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF ( lv_retcode = cv_status_error ) THEN
       lv_errmsg := xxccp_common_pkg.get_msg( cv_current_appl_short_nm
                                             ,cv_msg_get_delete_err
                                             ,cv_tkn_table
                                             ,cv_month_tbl);
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- 2.人事システム向け販売実績（賞与）テーブルの削除を行います。
    -- ===============================
    --テーブルロック
    lock_table(
       cv_bonus_tbl_name -- テーブル名
      ,lv_errbuf         -- エラー・メッセージ           --# 固定 #
      ,lv_retcode        -- リターン・コード             --# 固定 #
      ,lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF ( lv_retcode = cv_status_error ) THEN
       lv_errmsg := xxccp_common_pkg.get_msg( cv_current_appl_short_nm
                                             ,cv_msg_table_lock_err
                                             ,cb_tkn_table_on
                                             ,cv_bonus_tbl_name);
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END IF;
--
    --テーブルデータ削除
    delete_table(
       cv_bonus_tbl_name -- テーブル名
      ,lv_errbuf         -- エラー・メッセージ           --# 固定 #
      ,lv_retcode        -- リターン・コード             --# 固定 #
      ,lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF ( lv_retcode = cv_status_error ) THEN
       lv_errmsg := xxccp_common_pkg.get_msg( cv_current_appl_short_nm
                                             ,cv_msg_get_delete_err
                                             ,cv_tkn_table
                                             ,cv_bonus_tbl);
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- <処理部、ループ部名> (処理結果によって後続処理を制御する場合)
    -- ===============================
   -- ===============================
    -- A-4. 対象従業員取得処理
    -- ===============================
    OPEN data_cur;
    LOOP
      FETCH data_cur BULK COLLECT INTO l_data_rec;
      --レコード0件の場合は抜ける。
      EXIT WHEN l_data_rec.COUNT = 0;
      --レコード処理
      FOR i in 1 .. l_data_rec.COUNT
      LOOP
        lt_xxcos_for_adps_monthly_if := NULL;
        lt_xxcos_for_adps_bonus_if   := NULL;
        
        --値設定
        --月次
        lt_xxcos_for_adps_monthly_if.employee_code  := LPAD(l_data_rec(i).code,6,0);               -- 従業員コード
        lt_xxcos_for_adps_monthly_if.results_date   := REPLACE(lv_make_date, cv_sla, '');          -- 年月
        lt_xxcos_for_adps_monthly_if.group_code     := l_data_rec(i).group_cd;                     -- 小グループコード
        lt_xxcos_for_adps_monthly_if.base_code      := l_data_rec(i).base;                         -- 拠点コード
        lt_xxcos_for_adps_monthly_if.area_code      := l_data_rec(i).area;                         -- 地区コード
        lt_xxcos_for_adps_monthly_if.division_code  := l_data_rec(i).ori_division_code;            -- 本部コード
        --賞与
        lt_xxcos_for_adps_bonus_if.employee_code    := LPAD(l_data_rec(i).code,6,0);               -- 従業員コード
        lt_xxcos_for_adps_bonus_if.results_date     := REPLACE(lv_make_date, cv_sla, '');          -- 年月
        lt_xxcos_for_adps_bonus_if.group_code       := l_data_rec(i).group_cd;                     -- 小グループコード
        lt_xxcos_for_adps_bonus_if.base_code        := l_data_rec(i).base;                         -- 拠点コード
        lt_xxcos_for_adps_bonus_if.area_code        := l_data_rec(i).area;                         -- 地区コード
        lt_xxcos_for_adps_bonus_if.division_code    := l_data_rec(i).ori_division_code;            -- 本部コード
        -- ===============================
        -- A-5. 当月販売実績集計処理
        -- ===============================
        get_sales_results_data(
           l_data_rec(i).code           -- 従業員コード
          ,l_data_rec(i).base           -- 拠点コード
          ,ld_month_first_date          -- 当月1日
          ,ld_month_next_date           -- 当月末日
          ,lt_xxcos_for_adps_monthly_if -- 月次テーブル
          ,lt_xxcos_for_adps_bonus_if   -- 賞与データ
          ,lv_errbuf                    -- エラー・メッセージ           --# 固定 #
          ,lv_retcode                   -- リターン・コード             --# 固定 #
          ,lv_errmsg                    -- ユーザー・エラー・メッセージ --# 固定 #
        );
        IF ( lv_retcode = cv_status_normal ) THEN
          NULL;
        ELSE
          RAISE global_common_expt;
        END IF;
--
        -- ===============================
        -- A-6．当月ノルマ集計処理
        -- ===============================
        get_noruma_data(
           l_data_rec(i).code           -- 従業員コード
          ,l_data_rec(i).base           -- 拠点コード
          ,lt_xxcos_for_adps_monthly_if -- テーブル
          ,lv_errbuf                    -- エラー・メッセージ           --# 固定 #
          ,lv_retcode                   -- リターン・コード             --# 固定 #
          ,lv_errmsg                    -- ユーザー・エラー・メッセージ --# 固定 #
        );
        IF ( lv_retcode = cv_status_normal ) THEN
          NULL;
        ELSE
          XXCOS_COMMON_PKG.makeup_key_info(
                                         ov_errbuf      =>  lv_errbuf      --エラー・メッセージ
                                        ,ov_retcode     =>  lv_retcode     --リターンコード
                                        ,ov_errmsg      =>  lv_errmsg      --ユーザ・エラー・メッセージ
                                        ,ov_key_info    =>  lv_key_info    --編集されたキー情報
                                        ,iv_item_name1  =>  cv_str_result_cd
                                        ,iv_item_name2  =>  cv_str_base_nm
                                        ,iv_data_value1 =>  l_data_rec(i).code
                                        ,iv_data_value2 =>  l_data_rec(i).base
                                       );
          lv_table_nm := cv_str_noruma_tbl;
          IF ( lv_retcode = cv_status_normal ) THEN
            RAISE global_select_expt;
          ELSE
            RAISE global_api_expt;
          END IF;
        END IF;
--
        -- ===============================
        -- A-7．当月獲得ポイント集計処理
        -- ===============================
        get_point_data(
           l_data_rec(i).code           -- 従業員コード
          ,l_data_rec(i).base           -- 拠点コード
          ,ld_month_first_date          -- 当月1日
          ,ld_month_next_date           -- 当月末日
          ,lt_xxcos_for_adps_monthly_if -- テーブル
          ,lv_errbuf                    -- エラー・メッセージ           --# 固定 #
          ,lv_retcode                   -- リターン・コード             --# 固定 #
          ,lv_errmsg                    -- ユーザー・エラー・メッセージ --# 固定 #
        );
        IF ( lv_retcode = cv_status_normal ) THEN
          NULL;
        ELSE
          XXCOS_COMMON_PKG.makeup_key_info(
                                         ov_errbuf      =>  lv_errbuf      --エラー・メッセージ
                                        ,ov_retcode     =>  lv_retcode     --リターンコード
                                        ,ov_errmsg      =>  lv_errmsg      --ユーザ・エラー・メッセージ
                                        ,ov_key_info    =>  lv_key_info    --編集されたキー情報
                                        ,iv_item_name1  =>  cv_str_result_cd
                                        ,iv_item_name2  =>  cv_str_base_nm
                                        ,iv_data_value1 =>  l_data_rec(i).code
                                        ,iv_data_value2 =>  l_data_rec(i).base
                                       );
          lv_table_nm := cv_str_point_tbl;
          IF ( lv_retcode = cv_status_normal ) THEN
            RAISE global_select_expt;
          ELSE
            RAISE global_api_expt;
          END IF;
        END IF;
--
        -- ===============================
        -- A-8．当月獲得ベンダー集計処理
        -- ===============================
        get_vender_data(
           l_data_rec(i).code              -- 従業員コード
          ,l_data_rec(i).base              -- 拠点コード
          ,lt_xxcos_for_adps_monthly_if -- テーブル
          ,lv_errbuf                    -- エラー・メッセージ           --# 固定 #
          ,lv_retcode                   -- リターン・コード             --# 固定 #
          ,lv_errmsg                    -- ユーザー・エラー・メッセージ --# 固定 #
        );
        IF ( lv_retcode = cv_status_normal ) THEN
          NULL;
        ELSE
          XXCOS_COMMON_PKG.makeup_key_info(
                                         ov_errbuf      =>  lv_errbuf      --エラー・メッセージ
                                        ,ov_retcode     =>  lv_retcode     --リターンコード
                                        ,ov_errmsg      =>  lv_errmsg      --ユーザ・エラー・メッセージ
                                        ,ov_key_info    =>  lv_key_info    --編集されたキー情報
                                        ,iv_item_name1  =>  cv_str_result_cd
                                        ,iv_item_name2  =>  cv_str_base_nm
                                        ,iv_data_value1 =>  l_data_rec(i).code
                                        ,iv_data_value2 =>  l_data_rec(i).base
                                       );
          lv_table_nm := cv_str_bus_count_tbl;
          IF ( lv_retcode = cv_status_normal ) THEN
            RAISE global_select_expt;
          ELSE
            RAISE global_api_expt;
          END IF;
        END IF;
--
        -- ===============================
        -- A-9．当月訪問件数集計処理
        -- ===============================
        get_visit_data(
           l_data_rec(i).code              -- 従業員コード
          ,l_data_rec(i).base              -- 拠点コード
          ,lt_xxcos_for_adps_bonus_if   -- テーブル
          ,lv_errbuf                    -- エラー・メッセージ           --# 固定 #
          ,lv_retcode                   -- リターン・コード             --# 固定 #
          ,lv_errmsg                    -- ユーザー・エラー・メッセージ --# 固定 #
        );
        IF ( lv_retcode = cv_status_normal ) THEN
          NULL;
        ELSE
          XXCOS_COMMON_PKG.makeup_key_info(
                                         ov_errbuf      =>  lv_errbuf      --エラー・メッセージ
                                        ,ov_retcode     =>  lv_retcode     --リターンコード
                                        ,ov_errmsg      =>  lv_errmsg      --ユーザ・エラー・メッセージ
                                        ,ov_key_info    =>  lv_key_info    --編集されたキー情報
                                        ,iv_item_name1  =>  cv_str_result_cd
                                        ,iv_item_name2  =>  cv_str_base_nm
                                        ,iv_data_value1 =>  l_data_rec(i).code
                                        ,iv_data_value2 =>  l_data_rec(i).base
                                       );
          lv_table_nm := cv_str_bus_count_tbl;
          IF ( lv_retcode = cv_status_normal ) THEN
            RAISE global_select_expt;
          ELSE
            RAISE global_api_expt;
          END IF;
        END IF;
--
        -- ===============================
        -- A-10．月次・賞与中間テーブル登録処理
        -- ===============================
        --個売上達成率
        IF ( lt_xxcos_for_adps_monthly_if.p_sale_norma = 0 ) 
          OR ( lt_xxcos_for_adps_monthly_if.p_sale_amount = 0 )
        THEN
          lt_xxcos_for_adps_monthly_if.p_sale_achievement_rate := 0;
        ELSE
          lt_xxcos_for_adps_monthly_if.p_sale_achievement_rate := 
            ROUND(lt_xxcos_for_adps_monthly_if.p_sale_amount / lt_xxcos_for_adps_monthly_if.p_sale_norma * 100,1);
        END IF;
--
        --個新規達成率
        IF ( lt_xxcos_for_adps_monthly_if.p_position_point = 0 ) 
          OR ( lt_xxcos_for_adps_monthly_if.p_new_point = 0 )
        THEN
          lt_xxcos_for_adps_monthly_if.p_new_achievement_rate := 0;
        ELSE
          lt_xxcos_for_adps_monthly_if.p_new_achievement_rate  := 
            ROUND(lt_xxcos_for_adps_monthly_if.p_new_point / lt_xxcos_for_adps_monthly_if.p_position_point * 100,1);
        END IF;
--
        set_insert_data(
           lt_xxcos_for_adps_monthly_if -- 月次テーブル
          ,lt_xxcos_for_adps_bonus_if   -- 賞与データ
          ,lv_errbuf                    -- エラー・メッセージ           --# 固定 #
          ,lv_retcode                   -- リターン・コード             --# 固定 #
          ,lv_errmsg                    -- ユーザー・エラー・メッセージ --# 固定 #
        );
        IF ( lv_retcode = cv_status_normal ) THEN
          NULL;
        ELSE
          RAISE global_common_expt;
        END IF;
        gn_target_cnt := gn_target_cnt + 1;
        gn_normal_cnt := gn_normal_cnt + 1;
--
      END LOOP;
    END LOOP;
    CLOSE data_cur;
--
    --従業員0件
    IF gn_target_cnt = 0 THEN
       RAISE global_no_data_expt;
    END IF;
    -- ===============================
    -- A-11．小グループ集計処理
    -- ===============================
    small_group_total(
       lv_errbuf    -- エラー・メッセージ           --# 固定 #
      ,lv_retcode   -- リターン・コード             --# 固定 #
      ,lv_errmsg    -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF ( lv_retcode = cv_status_normal ) THEN
      NULL;
    ELSE
      RAISE global_common_expt;
    END IF;
    -- ===============================
    -- A-12．拠点集計処理
    -- ===============================
    base_total(
       lv_errbuf    -- エラー・メッセージ           --# 固定 #
      ,lv_retcode   -- リターン・コード             --# 固定 #
      ,lv_errmsg    -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF ( lv_retcode = cv_status_normal ) THEN
      NULL;
    ELSE
      RAISE global_common_expt;
    END IF;
    -- ===============================
    -- A-13．地区集計処理
    -- ===============================
    area_total(
       lv_errbuf    -- エラー・メッセージ           --# 固定 #
      ,lv_retcode   -- リターン・コード             --# 固定 #
      ,lv_errmsg    -- ユーザー・エラー・メッセージ --# 固定 #
    );
      IF ( lv_retcode = cv_status_normal ) THEN
        NULL;
      ELSE
        RAISE global_common_expt;
      END IF;
--
    -- ===============================
    -- A-14．本部集計処理
    -- ===============================
    div_total(
       lv_errbuf    -- エラー・メッセージ           --# 固定 #
      ,lv_retcode   -- リターン・コード             --# 固定 #
      ,lv_errmsg    -- ユーザー・エラー・メッセージ --# 固定 #
    );
      IF ( lv_retcode = cv_status_normal ) THEN
        NULL;
      ELSE
        RAISE global_common_expt;
      END IF;
--
    -- ===============================
    -- A-15．全社集計処理
    -- ===============================
    sum_total(
         lv_errbuf    -- エラー・メッセージ           --# 固定 #
        ,lv_retcode   -- リターン・コード             --# 固定 #
        ,lv_errmsg    -- ユーザー・エラー・メッセージ --# 固定 #
    );
      IF ( lv_retcode = cv_status_normal ) THEN
        NULL;
      ELSE
        RAISE global_common_expt;
      END IF;
--
  EXCEPTION
      -- *** 任意で例外処理を記述する ****
    -- 抽出例外
    WHEN global_select_expt THEN
      ov_errmsg := xxccp_common_pkg.get_msg(
                      iv_application        =>  cv_current_appl_short_nm
                     ,iv_name               =>  cv_msg_select_data_err
                     ,iv_token_name1        =>  cv_tkn_table
                     ,iv_token_name2        =>  cv_tkn_key_data
                     ,iv_token_value1       =>  lv_table_nm
                     ,iv_token_value2       =>  lv_key_info
                   );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
      gn_target_cnt := 0;
      gn_normal_cnt := 0;
    -- *** 対象データ０件エラー ***
    WHEN global_no_data_expt    THEN
      ov_errmsg               :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_current_appl_short_nm,
        iv_name               =>  cv_msg_nodata_err
      );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_warn;
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_common_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := lv_errbuf;
      ov_retcode := lv_retcode;
      gn_target_cnt := 0;
      gn_normal_cnt := 0;
--
--#################################  固定例外処理部 START   ###################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
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
    errbuf        OUT VARCHAR2,      --   エラー・メッセージ  --# 固定 #
    retcode       OUT VARCHAR2,      --   リターン・コード    --# 固定 #
--    ↓IN のﾊﾟﾗﾒｰﾀがある場合は適宜編集して下さい。
    iv_make_date  IN  VARCHAR2       --   1.作成年月
  )
--
--###########################  固定部 START   ###########################
--
  IS
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name        CONSTANT VARCHAR2(100) := 'main';             -- プログラム名
--
    cv_appl_short_name CONSTANT VARCHAR2(10)  := 'XXCCP';            -- アドオン：共通・IF領域
    cv_target_rec_msg  CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90000'; -- 対象件数メッセージ
    cv_success_rec_msg CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90001'; -- 成功件数メッセージ
    cv_error_rec_msg   CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002'; -- エラー件数メッセージ
    cv_skip_rec_msg    CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90003'; -- スキップ件数メッセージ
    cv_cnt_token       CONSTANT VARCHAR2(10)  := 'COUNT';            -- 件数メッセージ用トークン名
    cv_normal_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; -- 正常終了メッセージ
    cv_warn_msg        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005'; -- 警告終了メッセージ
    cv_error_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006'; -- エラー終了全ロールバック
    cv_log_header_out  CONSTANT VARCHAR2(6)   := 'OUTPUT';           -- コンカレントヘッダメッセージ出力先：出力
    cv_log_header_log  CONSTANT VARCHAR2(6)   := 'LOG';              -- コンカレントヘッダメッセージ出力先：ログ(帳票のみ)
    
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
       iv_which   => cv_log_header_out
      ,ov_retcode => lv_retcode
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
       iv_make_date   -- 1.作成年月
      ,lv_errbuf   -- エラー・メッセージ           --# 固定 #
      ,lv_retcode  -- リターン・コード             --# 固定 #
      ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    --エラー出力
    IF (lv_retcode != cv_status_error) THEN
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg --ユーザー・エラーメッセージ
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --エラーメッセージ
      );
    END IF;
    --空行挿入
    FND_FILE.PUT_LINE(
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
    FND_FILE.PUT_LINE(
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
    FND_FILE.PUT_LINE(
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
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --スキップ件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_skip_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_warn_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --終了メッセージ
    IF (lv_retcode = cv_status_normal) THEN
      lv_message_code := cv_normal_msg;
    ELSIF(lv_retcode = cv_status_warn) THEN
      lv_message_code := cv_warn_msg;
    ELSIF(lv_retcode = cv_status_error) THEN
      lv_message_code := cv_error_msg;
    END IF;
    --
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => lv_message_code
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --ステータスセット
    retcode := lv_retcode;
    errbuf  := lv_errbuf;
    --終了ステータスがエラーの場合はROLLBACKする
    IF (retcode = cv_status_error) THEN
      ROLLBACK;
    END IF;
--
  EXCEPTION
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
  END main;
--
--###########################  固定部 END   #######################################################
--
END XXCOS016A03C;
/
