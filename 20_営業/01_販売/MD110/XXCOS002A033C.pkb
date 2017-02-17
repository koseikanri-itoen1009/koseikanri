CREATE OR REPLACE PACKAGE BODY APPS.XXCOS002A033C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2016. All rights reserved.
 *
 * Package Name     : XXCOS002A033C (body)
 * Description      : 営業成績表集計(前年)
 * MD.050           : 営業成績表集計(前年) MD050_COS_002_A03
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   初期処理(C-1)
 *  count_delete_inv_py    期限切れ集計データ削除処理(C-4)
 *  bus_s_group_sum_sales  販売実績情報集計(前年)処理(C-2)
 *  bus_s_group_sum_trans  実績振替情報集計(前年)処理(C-3)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *                         終了処理(C-5)
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2016/05/10    1.0   S.Niki           main新規作成
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
  -- *** プロファイル取得例外ハンドラ ***
  global_get_profile_expt       EXCEPTION;
  -- *** ロックエラー例外ハンドラ ***
  global_data_lock_expt         EXCEPTION;
  -- *** データ登録エラー例外ハンドラ ***
  global_insert_data_expt       EXCEPTION;
  -- *** データ更新エラー例外ハンドラ ***
  global_update_data_expt       EXCEPTION;
  -- *** データ削除エラー例外ハンドラ ***
  global_delete_data_expt       EXCEPTION;
--
  PRAGMA EXCEPTION_INIT(global_data_lock_expt, -54);
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  -- パッケージ名
  cv_pkg_name                   CONSTANT VARCHAR2(100) := 'XXCOS002A033C';
  -- アプリケーション短縮名
  ct_xxcos_appl_short_name      CONSTANT  fnd_application.application_short_name%TYPE := 'XXCOS';
--
  -- ■販物メッセージ
  -- 業務日付取得エラー
  ct_msg_process_date_err       CONSTANT  fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00014';
  -- プロファイル取得エラー
  ct_msg_get_profile_err        CONSTANT  fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00004';
  -- ロックエラー
  ct_msg_lock_err               CONSTANT  fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00001';
  -- データ登録エラーメッセージ
  ct_msg_insert_data_err        CONSTANT  fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00010';
  -- データ更新エラーメッセージ
  ct_msg_update_data_err        CONSTANT  fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00011';
  -- データ削除エラーメッセージ
  ct_msg_delete_data_err        CONSTANT  fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00012';
  -- 未来日チェックエラー
  ct_msg_future_date_err        CONSTANT  fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00205';
--
  -- ■機能固有メッセージ
  -- 営業成績表集計(前年)パラメータ出力
  ct_msg_parameter_note         CONSTANT  fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-10594';
  -- XXCOS:変動電気料品目コード
  ct_msg_electric_fee_item_cd   CONSTANT  fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-10572';
  -- XXCOS:営業成績集約情報保存期間
  ct_msg_002a03_keeping_period  CONSTANT  fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-10574';
  -- XXCOS:カレンダコード
  ct_msg_business_calendar_code CONSTANT  fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-15054';
  -- 営業成績表 政策群別実績集計（前年）テーブル
  ct_msg_s_group_sum_py_tbl     CONSTANT  fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-10595';
  -- 販売実績情報集計(前年)処理件数
  ct_msg_count_s_group_sales    CONSTANT  fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-10597';
  -- 実績振替情報集計(前年)処理件数
  ct_msg_count_s_group_trans    CONSTANT  fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-10598';
  -- 期限切れ集計情報（前年）削除件数
  ct_msg_delete_invalidity      CONSTANT  fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-10599';
  -- 対象年月稼働日
  ct_msg_target_param_note      CONSTANT  fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-10600';
  -- 処理対象外メッセージ
  ct_msg_not_excute             CONSTANT  fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-15051';
  -- 処理済みスキップメッセージ
  ct_msg_skip_excute            CONSTANT  fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-15052';
  -- 一部処理後エラーメッセージ
  ct_msg_part_comp_err          CONSTANT  fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-15053';
--
  -- ■クイックコード
  -- 売上区分
  ct_qct_sale_type              CONSTANT  fnd_lookup_types.lookup_type%TYPE  := 'XXCOS1_SALE_CLASS';
--
  -- ■Yes/No
  cv_yes                        CONSTANT  VARCHAR2(1)  := 'Y';
  cv_no                         CONSTANT  VARCHAR2(1)  := 'N';
  -- ■日付指定書式
  cv_fmt_date                   CONSTANT  VARCHAR2(10) := 'YYYY/MM/DD';
  cv_fmt_years                  CONSTANT  VARCHAR2(6)  := 'YYYYMM';
--
  -- ■プロファイル名称
  -- XXCOS:変動電気料品目コード
  ct_prof_electric_fee_item_cd
    CONSTANT  fnd_profile_options.profile_option_name%TYPE := 'XXCOS1_ELECTRIC_FEE_ITEM_CODE';
  -- XXCOS:営業成績集約情報保存期間
  ct_prof_002a03_keeping_period
    CONSTANT  fnd_profile_options.profile_option_name%TYPE := 'XXCOS1_002A03_KEEPING_PERIOD';
  -- XXCOS:カレンダコード
  ct_prof_business_calendar_code
    CONSTANT  fnd_profile_options.profile_option_name%TYPE := 'XXCOS1_BUSINESS_CALENDAR_CODE';
--
  -- ■トークン
  -- 納品日
  cv_tkn_para_delivery_date     CONSTANT  VARCHAR2(20) := 'PARAM1';
  -- 処理区分
  cv_tkn_para_processing_class  CONSTANT  VARCHAR2(20) := 'PARAM2';
  -- プロファイル名
  cv_tkn_profile                CONSTANT  VARCHAR2(20) := 'PROFILE';
  -- キー情報
  cv_tkn_key_data               CONSTANT  VARCHAR2(20) := 'KEY_DATA';
  -- テーブル名称
  cv_tkn_table                  CONSTANT  VARCHAR2(20) := 'TABLE';
  -- テーブル名称
  cv_tkn_table_name             CONSTANT  VARCHAR2(20) := 'TABLE_NAME';
  -- 保存期間
  cv_tkn_keeping_period         CONSTANT  VARCHAR2(20) := 'KEEPING_PERIOD';
  -- 削除対象年月
  cv_tkn_deletion_object        CONSTANT  VARCHAR2(20) := 'DELETION_OBJECT';
  -- 対象年月
  cv_tkn_target_month           CONSTANT  VARCHAR2(20) := 'TARGET_MONTH';
  -- 対象稼働日
  cv_tkn_target_work_days       CONSTANT  VARCHAR2(20) := 'TARGET_WORK_DAYS';
  -- 作成日
  cv_tkn_creation_date          CONSTANT  VARCHAR2(20) := 'CREATION_DATE';
  -- 販売実績情報（前年）削除件数
  cv_tkn_delete_sales           CONSTANT  VARCHAR2(20) := 'DELETE_SALES';
  -- 実績振替情報（前年）削除件数
  cv_tkn_delete_trans           CONSTANT  VARCHAR2(20) := 'DELETE_TRANS';
--
  -- ■パラメータ識別用
  -- 全て
  cv_para_cls_all               CONSTANT  VARCHAR2(1)  := '0';
  -- 営業員別・政策群別販売実績情報集計＆登録処理(前年)
  cv_para_cls_s_group_sum_sales CONSTANT  VARCHAR2(1)  := '1';
  -- 営業員別・政策群別実績振替情報集計＆登録処理(前年)
  cv_para_cls_s_group_sum_trans CONSTANT  VARCHAR2(1)  := '2';
--
  -- ■販売振替区分
  -- 販売実績
  cv_dlv_sales                  CONSTANT  VARCHAR2(1)  := '0';
  -- 実績振替
  cv_dlv_trans                  CONSTANT  VARCHAR2(1)  := '1';
--
  -- ■数値
  cn_0                          CONSTANT  NUMBER       := 0;
  cn_1                          CONSTANT  NUMBER       := 1;
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  -- 対象日付を格納するレコード
  TYPE g_target_date_rtype IS RECORD(
    target_date                 DATE     -- 対象日付
  );
  -- 対象日付を格納する配列
  TYPE g_target_date_ttype  IS TABLE OF g_target_date_rtype   INDEX BY BINARY_INTEGER;
  gt_target_date_tab        g_target_date_ttype;
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  -- 業務日付
  gd_process_date               DATE;
  -- 対象日付
  gd_target_date                DATE;
  -- 対象年月
  gv_target_month               VARCHAR2(6);
  -- 期限切れ基準年月年月
  gv_invalidity_month           VARCHAR2(6);
  -- 現在稼働日数
  gn_target_work_days           NUMBER;
  -- 処理区分
  gv_processing_class           VARCHAR2(1);
  -- 随時実行フラグ
  gv_any_time_flag              VARCHAR2(1);
  -- 一部処理後エラーフラグ
  gv_part_comp_err_flag         VARCHAR2(1);
--
  -- ■プロファイル格納用
  -- XXCOS:変動電気料品目コード
  gt_prof_electric_fee_item_cd      fnd_profile_option_values.profile_option_value%TYPE;
  -- XXCOS:営業成績集約情報保存期間
  gt_prof_002a03_keeping_period     fnd_profile_option_values.profile_option_value%TYPE;
  -- XXCOS:カレンダコード
  gt_prof_business_calendar_code    fnd_profile_option_values.profile_option_value%TYPE;
--
  -- ■カウント用
  -- 販売実績登録件数
  gn_ins_sales_cnt              NUMBER;
  -- 実績振替登録件数
  gn_ins_trans_cnt              NUMBER;
  -- 期限切れ販売実績削除件数
  gn_del_sales_cnt              NUMBER;
  -- 期限切れ実績振替削除件数
  gn_del_trans_cnt              NUMBER;
--
  --  ===============================
  --  ユーザー定義グローバルカーソル
  --  ===============================
--
  -- 作成済みデータロック取得用
  CURSOR  lock_bus_s_group_sum_cur(
                                   icp_sales_trans_div  VARCHAR2   -- 販売振替区分
                                  )
  IS
    SELECT  /*+ INDEX(xp XXCOS_REP_BUS_S_SUM_PY_N01) */
            xp.rowid    AS  xp_rowid
    FROM    xxcos_rep_bus_s_group_sum_py  xp
    WHERE   xp.dlv_month            = gv_target_month
    AND     xp.work_days            = gn_target_work_days
    AND     xp.sales_transfer_div   = icp_sales_trans_div
        -- 随時実行の場合は上記条件
    AND ( ( gv_any_time_flag        = cv_yes )
      OR
        -- 定期実行の場合は、実行日=作成日の条件付与
        ( ( gv_any_time_flag        = cv_no )
        AND
          ( TRUNC(xp.creation_date) = TRUNC(SYSDATE) ) )
        )
    FOR UPDATE NOWAIT
    ;
--
  -- 期限切れ情報ロック取得用
  CURSOR  lock_count_sum_invalidity_cur(
                                        icp_dlv_month        VARCHAR2   -- 期限切れ基準年月
                                       ,icp_sales_trans_div  VARCHAR2   -- 販売振替区分
                                       )
  IS
    SELECT /*+ INDEX(xp XXCOS_REP_BUS_S_SUM_PY_N01) */
           xp.rowid    AS  xp_rowid
    FROM   xxcos_rep_bus_s_group_sum_py  xp
    WHERE  xp.dlv_month          <=  icp_dlv_month
    AND    xp.sales_transfer_div  =  icp_sales_trans_div
    FOR UPDATE NOWAIT
    ;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(C-1)
   ***********************************************************************************/
  PROCEDURE init(
    iv_delivery_date    IN  VARCHAR2,     -- 1.納品日
    iv_processing_class IN  VARCHAR2,     -- 2.処理区分
    ov_errbuf           OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode          OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg           OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
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
    ld_process_date             DATE;            -- 現在日付
    lv_process_month            VARCHAR2(6);     -- 現在年月
    --パラメータ出力用
    lv_para_msg                 VARCHAR2(5000);
    lv_profile_name             VARCHAR2(5000);
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
--
    --==================================
    -- 1.入力パラメータ出力
    --==================================
    lv_para_msg := xxccp_common_pkg.get_msg(
      iv_application   =>  ct_xxcos_appl_short_name,
      iv_name          =>  ct_msg_parameter_note,
      iv_token_name1   =>  cv_tkn_para_delivery_date,
      iv_token_value1  =>  iv_delivery_date,
      iv_token_name2   =>  cv_tkn_para_processing_class,
      iv_token_value2  =>  iv_processing_class
    );
--
    FND_FILE.PUT_LINE(
       which  =>  FND_FILE.OUTPUT
      ,buff   =>  lv_para_msg
    );
--
    -- 空行出力
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => NULL
    );
--
    -- メッセージログ
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => lv_para_msg
    );
--
    --==================================
    -- 2.業務日付取得
    --==================================
    gd_process_date := xxccp_common_pkg2.get_process_date;
    --
    -- 取得結果確認
    IF ( gd_process_date IS NULL ) THEN
      ov_errmsg := xxccp_common_pkg.get_msg(
        iv_application        => ct_xxcos_appl_short_name,
        iv_name               => ct_msg_process_date_err
      );
      lv_errbuf := ov_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==================================
    -- 3.変数セット
    --==================================
    -- 現在日付
    -- 定時実行の場合
    IF ( iv_delivery_date IS NULL) THEN
      -- 業務日付をセット
      ld_process_date  := gd_process_date;
    -- 随時実行の場合
    ELSE
      -- パラメータ.納品日をセット
      ld_process_date  := TO_DATE(iv_delivery_date ,cv_fmt_date);
      -- 随時実行フラグに'Y'をセット
      gv_any_time_flag := cv_yes;
    END IF;
--
    -- 現在日付 >= システム日付の場合エラー
    IF ( ld_process_date >= TRUNC(SYSDATE) ) THEN
      ov_errmsg := xxccp_common_pkg.get_msg(
        iv_application        => ct_xxcos_appl_short_name,
        iv_name               => ct_msg_future_date_err
      );
      lv_errbuf := ov_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- 現在年月
    lv_process_month    := TO_CHAR(ld_process_date ,cv_fmt_years);
    -- 対象日付(前年同月日)をセット
    gd_target_date      := ADD_MONTHS(ld_process_date, -12);
    -- 対象年月(前年同月)をセット
    gv_target_month     := TO_CHAR(gd_target_date ,cv_fmt_years);
    -- 処理区分をセット
    gv_processing_class := iv_processing_class;
--
    --==================================
    -- 4.プロファイル取得
    --==================================
    -- (1)変動電気料品目コード
    gt_prof_electric_fee_item_cd := FND_PROFILE.VALUE( ct_prof_electric_fee_item_cd );
    --
    -- プロファイルが取得できない場合はエラー
    IF ( gt_prof_electric_fee_item_cd IS NULL ) THEN
      --プロファイル名文字列取得
      lv_profile_name := xxccp_common_pkg.get_msg(
        iv_application        => ct_xxcos_appl_short_name,
        iv_name               => ct_msg_electric_fee_item_cd
      );
      --
      lv_profile_name :=  NVL(lv_profile_name, ct_prof_electric_fee_item_cd);
      RAISE global_get_profile_expt;
    END IF;
--
    -- (2)営業成績集約情報保存期間
    gt_prof_002a03_keeping_period := FND_PROFILE.VALUE( ct_prof_002a03_keeping_period );
    --
    -- プロファイルが取得できない場合はエラー
    IF ( gt_prof_002a03_keeping_period IS NULL ) THEN
      --プロファイル名文字列取得
      lv_profile_name := xxccp_common_pkg.get_msg(
        iv_application        => ct_xxcos_appl_short_name,
        iv_name               => ct_msg_002a03_keeping_period
      );
      lv_profile_name :=  NVL(lv_profile_name, ct_prof_002a03_keeping_period);
      RAISE global_get_profile_expt;
    END IF;
--
    -- (3)カレンダコード
    gt_prof_business_calendar_code := FND_PROFILE.VALUE( ct_prof_business_calendar_code );
    --
    -- プロファイルが取得できない場合はエラー
    IF ( gt_prof_business_calendar_code IS NULL ) THEN
      --プロファイル名文字列取得
      lv_profile_name := xxccp_common_pkg.get_msg(
        iv_application        => ct_xxcos_appl_short_name,
        iv_name               => ct_msg_business_calendar_code
      );
      lv_profile_name :=  NVL(lv_profile_name, ct_prof_business_calendar_code);
      RAISE global_get_profile_expt;
    END IF;
--
    --==================================
    -- 5.現在稼働日数取得
    --==================================
    BEGIN
      SELECT COUNT(1)                AS work_days
      INTO   gn_target_work_days
      FROM   bom_calendar_dates bcd
           ,(SELECT bcd.calendar_date  AS calendar_date
             FROM   bom_calendar_dates bcd
             WHERE  TO_CHAR(bcd.calendar_date ,cv_fmt_years) = lv_process_month               -- 現在年月
             AND    bcd.calendar_code                        = gt_prof_business_calendar_code -- カレンダコード
             ) cal_work
      WHERE  bcd.calendar_date                        <= cal_work.calendar_date
      AND    TO_CHAR(bcd.calendar_date ,cv_fmt_years)  = lv_process_month                     -- 現在年月
      AND    bcd.calendar_code                         = gt_prof_business_calendar_code       -- カレンダコード
      AND    bcd.seq_num                               IS NOT NULL
      AND    cal_work.calendar_date                    = ld_process_date                      -- 現在日付
      GROUP BY
             cal_work.calendar_date
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- 取得できない場合は「稼働日数ゼロ」と判定
        gn_target_work_days := 0;
    END;
--
    -- 対象年月稼働日を出力
    lv_para_msg := xxccp_common_pkg.get_msg(
      iv_application   =>  ct_xxcos_appl_short_name,
      iv_name          =>  ct_msg_target_param_note,
      iv_token_name1   =>  cv_tkn_target_month,
      iv_token_value1  =>  gv_target_month,
      iv_token_name2   =>  cv_tkn_target_work_days,
      iv_token_value2  =>  gn_target_work_days
    );
--
    FND_FILE.PUT_LINE(
       which  =>  FND_FILE.OUTPUT
      ,buff   =>  lv_para_msg
    );
--
    FND_FILE.PUT_LINE(
       which  =>  FND_FILE.LOG
      ,buff   =>  lv_para_msg
    );
--
    -- 空行出力
    FND_FILE.PUT_LINE(
       which  =>  FND_FILE.OUTPUT
      ,buff   =>  NULL
    );
--
    -- 空行出力
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => NULL
    );
--
    -- 初期化
    gt_target_date_tab.DELETE;
--
    -- 「稼働日数ゼロ」以外の場合、対象日付を取得
    IF ( gn_target_work_days <> 0 ) THEN
      --==================================
      -- 6.対象日付取得
      --==================================
      SELECT cal.calendar_date  AS target_date
      BULK COLLECT INTO gt_target_date_tab
      FROM  (SELECT cal_work.calendar_date1    AS calendar_date
                   ,COUNT(1)                   AS work_days
             FROM   bom_calendar_dates bcd
                   ,(SELECT bcd1.calendar_date AS calendar_date1
                           ,bcd2.calendar_date AS calendar_date2
                     FROM   bom_calendar_dates bcd1
                           ,bom_calendar_dates bcd2
                     WHERE  TO_CHAR(bcd1.calendar_date ,cv_fmt_years) = gv_target_month
                     AND    bcd1.calendar_code                        = gt_prof_business_calendar_code
                     AND    bcd1.next_seq_num                         = bcd2.seq_num
                     AND    bcd2.calendar_code                        = gt_prof_business_calendar_code
                    ) cal_work
             WHERE  bcd.calendar_date                        <= cal_work.calendar_date2
             AND    TO_CHAR(bcd.calendar_date ,cv_fmt_years)  = gv_target_month
             AND    bcd.calendar_code                         = gt_prof_business_calendar_code
             AND    bcd.seq_num                               IS NOT NULL
             GROUP BY
                    cal_work.calendar_date1
                   ,cal_work.calendar_date2
      ) cal
      WHERE  cal.work_days    =   gn_target_work_days
      ORDER BY
             cal.calendar_date
      ;
    END IF;
--
    -- 対象日付が取得できない場合は「処理対象外」と判定
    IF ( gt_target_date_tab.COUNT = 0 ) THEN
      -- 処理対象外メッセージを出力
      lv_para_msg := xxccp_common_pkg.get_msg(
        iv_application   =>  ct_xxcos_appl_short_name,
        iv_name          =>  ct_msg_not_excute
      );
--
      FND_FILE.PUT_LINE(
         which  =>  FND_FILE.OUTPUT
        ,buff   =>  lv_para_msg
      );
    END IF;
--
  EXCEPTION
    -- *** プロファイル例外ハンドラ ***
    WHEN global_get_profile_expt    THEN
      ov_errmsg               :=  xxccp_common_pkg.get_msg(
        iv_application        =>  ct_xxcos_appl_short_name,
        iv_name               =>  ct_msg_get_profile_err,
        iv_token_name1        =>  cv_tkn_profile,
        iv_token_value1       =>  lv_profile_name
      );
      ov_errbuf := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
    WHEN global_api_expt THEN
    -- *** 共通関数例外 ***
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
   * Procedure Name   : count_delete_inv_py
   * Description      : 期限切れ集計データ削除処理(C-4)
   ***********************************************************************************/
  PROCEDURE count_delete_inv_py(
    iv_sales_trans_div    IN  VARCHAR2,        --  1.販売振替区分
    ov_errbuf             OUT VARCHAR2,        --  エラー・メッセージ           --# 固定 #
    ov_retcode            OUT VARCHAR2,        --  リターン・コード             --# 固定 #
    ov_errmsg             OUT VARCHAR2)        --  ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'count_delete_inv_py'; -- プログラム名
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
    lt_table_name                         dba_tab_comments.comments%TYPE;   -- テーブル名
    ld_invalidity_date                    DATE;                             -- 期限切れ基準年月日
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
--
    --==================================
    -- (1)期限切れ基準年月算出
    --==================================
    -- 期限切れ基準年月日算出
    ld_invalidity_date
      := LAST_DAY(ADD_MONTHS(gd_target_date ,TO_NUMBER(gt_prof_002a03_keeping_period) * -1));
--
    -- 期限切れ基準年月算出
    gv_invalidity_month := TO_CHAR(ld_invalidity_date, cv_fmt_years);
--
    --==================================
    -- (2)ロック制御
    --==================================
    BEGIN
      -- ロック用カーソルオープン
      OPEN  lock_count_sum_invalidity_cur (
                                           gv_invalidity_month    -- 期限切れ基準年月
                                          ,iv_sales_trans_div     -- 販売振替区分
                                          );
      -- ロック用カーソルクローズ
      CLOSE lock_count_sum_invalidity_cur;
    EXCEPTION
      WHEN global_data_lock_expt THEN
        -- テーブル名取得
        lt_table_name := xxccp_common_pkg.get_msg(
          iv_application        => ct_xxcos_appl_short_name,
          iv_name               => ct_msg_s_group_sum_py_tbl
        );
        ov_errmsg := xxccp_common_pkg.get_msg(
          iv_application        => ct_xxcos_appl_short_name,
          iv_name               => ct_msg_lock_err,
          iv_token_name1        => cv_tkn_table,
          iv_token_value1       => lt_table_name
        );
        RAISE global_data_lock_expt;
    END;
--
    --==================================
    -- (3)データ削除
    --==================================
    BEGIN
      DELETE /*+ INDEX(xp XXCOS_REP_BUS_S_SUM_PY_N01) */
      FROM   xxcos_rep_bus_s_group_sum_py   xp
      WHERE  xp.dlv_month          <=  gv_invalidity_month
      AND    xp.sales_transfer_div  =  iv_sales_trans_div
      ;
--
    EXCEPTION
      WHEN OTHERS THEN
        -- テーブル名取得
        lt_table_name := xxccp_common_pkg.get_msg(
          iv_application        => ct_xxcos_appl_short_name,
          iv_name               => ct_msg_s_group_sum_py_tbl
        );
        ov_errmsg := xxccp_common_pkg.get_msg(
          iv_application        => ct_xxcos_appl_short_name,
          iv_name               => ct_msg_delete_data_err,
          iv_token_name1        => cv_tkn_table_name,
          iv_token_value1       => lt_table_name,
          iv_token_name2        => cv_tkn_key_data,
          iv_token_value2       => NULL
        );
        -- エラー内容取得
        lv_errbuf := SQLERRM;
        RAISE global_delete_data_expt;
    END;
--
    -- 削除件数カウント
    IF ( iv_sales_trans_div = cv_dlv_sales ) THEN
      -- 期限切れ販売実績削除件数
      gn_del_sales_cnt := SQL%ROWCOUNT;
    ELSE
      -- 期限切れ実績振替削除件数
      gn_del_trans_cnt := SQL%ROWCOUNT;
    END IF;
--
    -- コミット
    COMMIT;
--
  EXCEPTION
    --*** ロック例外ハンドラ ***
    WHEN global_data_lock_expt THEN
      ov_errbuf := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
    --*** データ削除例外ハンドラ ***
    WHEN global_delete_data_expt THEN
      ov_errbuf := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
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
  END count_delete_inv_py;
--
  /**********************************************************************************
   * Procedure Name   : bus_s_group_sum_sales
   * Description      : 販売実績情報集計(前年)処理(C-2)
   ***********************************************************************************/
  PROCEDURE bus_s_group_sum_sales(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'bus_s_group_sum_sales'; -- プログラム名
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
    ln_dummy             NUMBER;                            -- カウント用ダミー変数
    lt_table_name        dba_tab_comments.comments%TYPE;    -- テーブル名
    lv_creation_date     VARCHAR2(10);                      -- 作成日
    lv_skip_msg          VARCHAR2(5000);                    -- 処理スキップメッセージ
--
    -- *** ローカル・カーソル ***
    -- 販売実績情報(前年)取得カーソル
    CURSOR bus_s_group_sum_sales_cur (
      id_delivery_date DATE
    ) IS
       SELECT
           /*+ USE_NL(xseh xsel iimb) */
           TO_CHAR(xseh.delivery_date ,cv_fmt_years)      AS dlv_month             -- 納品月
          ,xseh.ship_to_customer_code                     AS customer_code         -- 顧客コード
          ,iimb.attribute2                                AS policy_group_code     -- 政策群コード
          ,SUM(xsel.pure_amount)                          AS sale_amount           -- 本体金額
          ,SUM(
               CASE xlvs.attribute3  -- 営業原価算入対象
                 WHEN cv_yes THEN
                   xsel.business_cost * xsel.standard_qty
                 ELSE
                   cn_0
               END
           )                                              AS business_cost         -- 営業原価
       FROM    xxcos_sales_exp_headers   xseh
              ,xxcos_sales_exp_lines     xsel
              ,xxcos_lookup_values_v     xlvs
              ,ic_item_mst_b             iimb
       WHERE   xseh.delivery_date           =       id_delivery_date
       AND     xseh.sales_exp_header_id     =       xsel.sales_exp_header_id
       AND     xsel.item_code               <>      gt_prof_electric_fee_item_cd   -- 変動電気代は除く
       AND     xlvs.lookup_type             =       ct_qct_sale_type               -- 売上区分
       AND     xlvs.lookup_code             =       xsel.sales_class
       AND     gd_process_date              BETWEEN NVL(xlvs.start_date_active, gd_process_date)
                                            AND     NVL(xlvs.end_date_active,   gd_process_date)
       AND     iimb.item_no                 =       xsel.item_code
       GROUP BY
               TO_CHAR(xseh.delivery_date ,cv_fmt_years)     -- 納品月
              ,xseh.ship_to_customer_code                    -- 顧客コード
              ,iimb.attribute2                               -- 政策群コード
       ;
--
    -- *** ローカル・レコード ***
    bus_s_group_sum_sales_rec  bus_s_group_sum_sales_cur%ROWTYPE;
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
    -- 初期化
    ln_dummy := 0;
--
    --==================================
    -- 1.作成済みデータ削除
    --==================================
    BEGIN
      -- ロック用カーソルオープン
      OPEN  lock_bus_s_group_sum_cur(
                                    cv_dlv_sales      -- 販売実績
                                    );
      -- ロック用カーソルクローズ
      CLOSE lock_bus_s_group_sum_cur;
    --
    EXCEPTION
      WHEN global_data_lock_expt THEN
        -- テーブル名取得
        lt_table_name := xxccp_common_pkg.get_msg(
          iv_application        => ct_xxcos_appl_short_name,
          iv_name               => ct_msg_s_group_sum_py_tbl
        );
        ov_errmsg := xxccp_common_pkg.get_msg(
          iv_application        => ct_xxcos_appl_short_name,
          iv_name               => ct_msg_lock_err,
          iv_token_name1        => cv_tkn_table,
          iv_token_value1       => lt_table_name
        );
        RAISE global_data_lock_expt;
    END;
--
    BEGIN
      DELETE  /*+ INDEX(xp XXCOS_REP_BUS_S_SUM_PY_N01) */
      FROM    xxcos_rep_bus_s_group_sum_py xp
      WHERE   xp.dlv_month            =  gv_target_month
      AND     xp.work_days            =  gn_target_work_days
      AND     xp.sales_transfer_div   =  cv_dlv_sales             -- 販売実績
          -- 随時実行の場合は上記条件
      AND ( ( gv_any_time_flag        = cv_yes )
        OR
          -- 定期実行の場合は、実行日=作成日の条件付与
          ( ( gv_any_time_flag        = cv_no )
          AND
            ( TRUNC(xp.creation_date) = TRUNC(SYSDATE) ) )
          )
      ;
    EXCEPTION
      WHEN OTHERS THEN
        -- テーブル名取得
        lt_table_name := xxccp_common_pkg.get_msg(
          iv_application        => ct_xxcos_appl_short_name,
          iv_name               => ct_msg_s_group_sum_py_tbl
        );
        ov_errmsg := xxccp_common_pkg.get_msg(
          iv_application        => ct_xxcos_appl_short_name,
          iv_name               => ct_msg_delete_data_err,
          iv_token_name1        => cv_tkn_table_name,
          iv_token_value1       => lt_table_name,
          iv_token_name2        => cv_tkn_key_data,
          iv_token_value2       => NULL
        );
        -- エラー内容取得
        lv_errbuf := SQLERRM;
        RAISE global_delete_data_expt;
    END;
--
    -- コミット
    COMMIT;
--
    -- 定期実行の場合
    IF ( gv_any_time_flag = cv_no ) THEN
--
      -- ===============================
      -- 2.期限切れ集計データ削除処理(C-4)
      -- ===============================
      count_delete_inv_py(
        cv_dlv_sales,      -- 販売実績
        lv_errbuf,         -- エラー・メッセージ           --# 固定 #
        lv_retcode,        -- リターン・コード             --# 固定 #
        lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
      --
      IF (lv_retcode <> cv_status_normal) THEN
        RAISE global_api_expt;
      END IF;
--
      --==================================
      -- 3.作成済みデータ確認(販売実績)
      --==================================
      BEGIN
        SELECT /*+ INDEX(xp XXCOS_REP_BUS_S_SUM_PY_N01) */
               TO_CHAR(xp.creation_date ,cv_fmt_date) AS creation_date
        INTO   lv_creation_date
        FROM   xxcos_rep_bus_s_group_sum_py xp
        WHERE  xp.dlv_month          = gv_target_month
        AND    xp.work_days          = gn_target_work_days
        AND    xp.sales_transfer_div = cv_dlv_sales           -- 販売実績
        AND    ROWNUM                = cn_1
        ;
--
        -- データが存在する場合は本処理をスキップ
        lv_skip_msg := xxccp_common_pkg.get_msg(
          iv_application   =>  ct_xxcos_appl_short_name,
          iv_name          =>  ct_msg_skip_excute,
          iv_token_name1   =>  cv_tkn_creation_date,
          iv_token_value1  =>  lv_creation_date
        );
--
        FND_FILE.PUT_LINE(
           which  =>  FND_FILE.OUTPUT
          ,buff   =>  lv_skip_msg
        );
        RETURN;
      EXCEPTION
        -- データが存在しない場合は継続
        WHEN NO_DATA_FOUND THEN
          NULL;
      END;
--
    END IF;
--
    --==================================
    -- 4.販売実績情報登録／更新処理
    --==================================
    -- 対象日付ループ
    <<cal_loop>>
    FOR i IN 1 .. gt_target_date_tab.COUNT LOOP
--
      -- ##### debug log #####
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => '【C-2】target_date '|| TO_CHAR(gt_target_date_tab(i).target_date,'YYYY/MM/DD') ||' '||'start '|| TO_CHAR(SYSDATE ,'HH24:MI:SS')
      );
--
      -- 販売実績ループ
      OPEN bus_s_group_sum_sales_cur(
        gt_target_date_tab(i).target_date
      );
      <<sales_loop>>
      LOOP
        FETCH bus_s_group_sum_sales_cur INTO bus_s_group_sum_sales_rec;
        EXIT WHEN bus_s_group_sum_sales_cur%NOTFOUND;
--
          -- 初期化
          ln_dummy := 0;
--
          -- 同一年月／稼働日／顧客／政策群データ確認
          SELECT /*+ INDEX(xp XXCOS_REP_BUS_S_SUM_PY_N02) */
                 COUNT(1)  AS dummy
          INTO   ln_dummy
          FROM   xxcos_rep_bus_s_group_sum_py xp
          WHERE  xp.dlv_month          = gv_target_month
          AND    xp.work_days          = gn_target_work_days
          AND    xp.customer_code      = bus_s_group_sum_sales_rec.customer_code
          AND    xp.policy_group_code  = bus_s_group_sum_sales_rec.policy_group_code
          AND    xp.sales_transfer_div = cv_dlv_sales                               -- 販売実績
          ;
--
        -- データが存在しない場合は登録
        IF ( ln_dummy = 0 ) THEN
--
          -- 対象件数カウント
          gn_target_cnt := gn_target_cnt + 1;
--
          BEGIN
            INSERT INTO xxcos_rep_bus_s_group_sum_py(
               sales_transfer_div
              ,dlv_month
              ,work_days
              ,customer_code
              ,policy_group_code
              ,sale_amount
              ,business_cost
              ,created_by
              ,creation_date
              ,last_updated_by
              ,last_update_date
              ,last_update_login
              ,request_id
              ,program_application_id
              ,program_id
              ,program_update_date
            ) VALUES
            (
               cv_dlv_sales                                       -- 販売振替区分(販売実績)
              ,bus_s_group_sum_sales_rec.dlv_month                -- 納品月
              ,gn_target_work_days                                -- 営業日
              ,bus_s_group_sum_sales_rec.customer_code            -- 顧客コード
              ,bus_s_group_sum_sales_rec.policy_group_code        -- 政策群コード
              ,bus_s_group_sum_sales_rec.sale_amount              -- 純売上金額
              ,bus_s_group_sum_sales_rec.business_cost            -- 営業原価
              ,cn_created_by
              ,cd_creation_date
              ,cn_last_updated_by
              ,cd_last_update_date
              ,cn_last_update_login
              ,cn_request_id
              ,cn_program_application_id
              ,cn_program_id
              ,cd_program_update_date
            );
--
            -- 正常件数カウント
            gn_normal_cnt    := gn_normal_cnt + 1;
            gn_ins_sales_cnt := gn_ins_sales_cnt + 1;
--
          EXCEPTION
            WHEN OTHERS THEN
              -- テーブル名取得
              lt_table_name := xxccp_common_pkg.get_msg(
                iv_application        => ct_xxcos_appl_short_name,
                iv_name               => ct_msg_s_group_sum_py_tbl
              );
              lv_errmsg := xxccp_common_pkg.get_msg(
                iv_application        => ct_xxcos_appl_short_name,
                iv_name               => ct_msg_insert_data_err,
                iv_token_name1        => cv_tkn_table_name,
                iv_token_value1       => lt_table_name,
                iv_token_name2        => cv_tkn_key_data,
                iv_token_value2       => NULL
              );
              -- エラー内容取得
              lv_errbuf := SQLERRM;
              RAISE global_api_expt;
          END;
--
        -- データが存在する場合は更新(加算)
        ELSE
--
          BEGIN
            UPDATE /*+ INDEX(xp XXCOS_REP_BUS_S_SUM_PY_N02) */
                   xxcos_rep_bus_s_group_sum_py xp
            SET    xp.sale_amount        = xp.sale_amount   + bus_s_group_sum_sales_rec.sale_amount
                  ,xp.business_cost      = xp.business_cost + bus_s_group_sum_sales_rec.business_cost
            WHERE  xp.dlv_month          = gv_target_month
            AND    xp.work_days          = gn_target_work_days
            AND    xp.customer_code      = bus_s_group_sum_sales_rec.customer_code
            AND    xp.policy_group_code  = bus_s_group_sum_sales_rec.policy_group_code
            AND    xp.sales_transfer_div = cv_dlv_sales                                -- 販売実績
            ;
          EXCEPTION
            WHEN OTHERS THEN
              -- テーブル名取得
              lt_table_name := xxccp_common_pkg.get_msg(
                iv_application        => ct_xxcos_appl_short_name,
                iv_name               => ct_msg_s_group_sum_py_tbl
              );
              lv_errmsg := xxccp_common_pkg.get_msg(
                iv_application        => ct_xxcos_appl_short_name,
                iv_name               => ct_msg_update_data_err,
                iv_token_name1        => cv_tkn_table_name,
                iv_token_value1       => lt_table_name,
                iv_token_name2        => cv_tkn_key_data,
                iv_token_value2       => NULL
              );
              -- エラー内容取得
              lv_errbuf := SQLERRM;
              RAISE global_api_expt;
          END;
        END IF;
      END LOOP sales_loop;
      CLOSE bus_s_group_sum_sales_cur;
--
      -- 納品日単位でコミット
      COMMIT;
--
    END LOOP cal_loop;
--
  EXCEPTION
    --*** ロック例外ハンドラ ***
    WHEN global_data_lock_expt THEN
      ov_errbuf := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
    --*** データ削除例外ハンドラ ***
    WHEN global_delete_data_expt THEN
      ov_errbuf := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    --*** データ登録例外ハンドラ ***
    WHEN global_insert_data_expt THEN
      ov_errbuf := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
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
  END bus_s_group_sum_sales;
--
  /**********************************************************************************
   * Procedure Name   : bus_s_group_sum_trans
   * Description      : 実績振替情報集計(前年)処理(C-3)
   ***********************************************************************************/
  PROCEDURE bus_s_group_sum_trans(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'bus_s_group_sum_trans'; -- プログラム名
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
    ln_dummy             NUMBER;                            -- カウント用ダミー変数
    lt_table_name        dba_tab_comments.comments%TYPE;    -- テーブル名
    lv_creation_date     VARCHAR2(10);                      -- 作成日
    lv_skip_msg          VARCHAR2(5000);                    -- 処理スキップメッセージ
--
    -- *** ローカル・カーソル ***
    -- 実績振替情報(前年)取得カーソル
    CURSOR bus_s_group_sum_trans_cur (
      id_delivery_date DATE
    ) IS
       SELECT
           /*+ USE_NL(xsti iimb) */
           TO_CHAR(xsti.registration_date ,cv_fmt_years)  AS dlv_month             -- 納品月
          ,xsti.cust_code                                 AS customer_code         -- 顧客コード
          ,iimb.attribute2                                AS policy_group_code     -- 政策群コード
          ,SUM(xsti.selling_amt_no_tax)                   AS sale_amount           -- 本体金額
          ,SUM(
               CASE xlvs.attribute3  -- 営業原価算入対象
                 WHEN cv_yes THEN
                   xsti.trading_cost
                 ELSE
                   cn_0
               END
           )                                              AS business_cost         -- 営業原価
       FROM    xxcok_selling_trns_info   xsti
              ,xxcos_lookup_values_v     xlvs
              ,ic_item_mst_b             iimb
       WHERE   xsti.registration_date       =       id_delivery_date
       AND     xsti.item_code               <>      gt_prof_electric_fee_item_cd   -- 変動電気代は除く
       AND     xlvs.lookup_type             =       ct_qct_sale_type               -- 売上区分
       AND     xlvs.lookup_code             =       xsti.selling_type
       AND     gd_process_date              BETWEEN NVL(xlvs.start_date_active, gd_process_date)
                                            AND     NVL(xlvs.end_date_active,   gd_process_date)
       AND     iimb.item_no                 =       xsti.item_code
       GROUP BY
               TO_CHAR(xsti.registration_date ,cv_fmt_years) -- 納品月
              ,xsti.cust_code                                -- 顧客コード
              ,iimb.attribute2                               -- 政策群コード
       ;
--
    -- *** ローカル・レコード ***
    bus_s_group_sum_trans_rec  bus_s_group_sum_trans_cur%ROWTYPE;
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
    -- 初期化
    ln_dummy := 0;
--
    --==================================
    -- 1.作成済みデータ削除
    --==================================
    BEGIN
      -- ロック用カーソルオープン
      OPEN  lock_bus_s_group_sum_cur(
                                    cv_dlv_trans  -- 実績振替
                                    );
      -- ロック用カーソルクローズ
      CLOSE lock_bus_s_group_sum_cur;
    --
    EXCEPTION
      WHEN global_data_lock_expt THEN
        -- テーブル名取得
        lt_table_name := xxccp_common_pkg.get_msg(
          iv_application        => ct_xxcos_appl_short_name,
          iv_name               => ct_msg_s_group_sum_py_tbl
        );
        ov_errmsg := xxccp_common_pkg.get_msg(
          iv_application        => ct_xxcos_appl_short_name,
          iv_name               => ct_msg_lock_err,
          iv_token_name1        => cv_tkn_table,
          iv_token_value1       => lt_table_name
        );
        RAISE global_data_lock_expt;
    END;
--
    BEGIN
      DELETE  /*+ INDEX(xp XXCOS_REP_BUS_S_SUM_PY_N01) */
      FROM    xxcos_rep_bus_s_group_sum_py xp
      WHERE   xp.dlv_month            =  gv_target_month
      AND     xp.work_days            =  gn_target_work_days
      AND     xp.sales_transfer_div   =  cv_dlv_trans             -- 実績振替
          -- 随時実行の場合は上記条件
      AND ( ( gv_any_time_flag        = cv_yes )
        OR
          -- 定期実行の場合は、実行日=作成日の条件付与
          ( ( gv_any_time_flag        = cv_no )
          AND
            ( TRUNC(xp.creation_date) = TRUNC(SYSDATE) ) )
          )
      ;
    EXCEPTION
      WHEN OTHERS THEN
        -- テーブル名取得
        lt_table_name := xxccp_common_pkg.get_msg(
          iv_application        => ct_xxcos_appl_short_name,
          iv_name               => ct_msg_s_group_sum_py_tbl
        );
        ov_errmsg := xxccp_common_pkg.get_msg(
          iv_application        => ct_xxcos_appl_short_name,
          iv_name               => ct_msg_delete_data_err,
          iv_token_name1        => cv_tkn_table_name,
          iv_token_value1       => lt_table_name,
          iv_token_name2        => cv_tkn_key_data,
          iv_token_value2       => NULL
        );
        -- エラー内容取得
        lv_errbuf := SQLERRM;
        RAISE global_delete_data_expt;
    END;
--
    -- コミット
    COMMIT;
--
    -- 定期実行の場合
    IF ( gv_any_time_flag = cv_no ) THEN
--
      -- ===============================
      -- 2.期限切れ集計データ削除処理(C-4)
      -- ===============================
      count_delete_inv_py(
        cv_dlv_trans,      -- 実績振替
        lv_errbuf,         -- エラー・メッセージ           --# 固定 #
        lv_retcode,        -- リターン・コード             --# 固定 #
        lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
      --
      IF (lv_retcode <> cv_status_normal) THEN
        RAISE global_api_expt;
      END IF;
--
      --==================================
      -- 3.作成済みデータ確認(実績振替)
      --==================================
      BEGIN
        SELECT /*+ INDEX(xp XXCOS_REP_BUS_S_SUM_PY_N01) */
               TO_CHAR(xp.creation_date ,cv_fmt_date) AS creation_date
        INTO   lv_creation_date
        FROM   xxcos_rep_bus_s_group_sum_py xp
        WHERE  xp.dlv_month          = gv_target_month
        AND    xp.work_days          = gn_target_work_days
        AND    xp.sales_transfer_div = cv_dlv_trans           -- 実績振替
        AND    ROWNUM                = cn_1
        ;
--
        -- データが存在する場合は本処理をスキップ
        lv_skip_msg := xxccp_common_pkg.get_msg(
          iv_application   =>  ct_xxcos_appl_short_name,
          iv_name          =>  ct_msg_skip_excute,
          iv_token_name1   =>  cv_tkn_creation_date,
          iv_token_value1  =>  lv_creation_date
        );
--
        FND_FILE.PUT_LINE(
           which  =>  FND_FILE.OUTPUT
          ,buff   =>  lv_skip_msg
        );
--
        RETURN;
      EXCEPTION
        -- データが存在しない場合は継続
        WHEN NO_DATA_FOUND THEN
          NULL;
      END;
    END IF;
--
    --==================================
    -- 4.実績振替情報登録／更新処理
    --==================================
    -- 対象日付ループ
    <<cal_loop>>
    FOR i IN 1 .. gt_target_date_tab.COUNT LOOP
      -- 実績振替ループ
      OPEN bus_s_group_sum_trans_cur(
        gt_target_date_tab(i).target_date
      );
--
      -- ##### debug log #####
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => '【C-3】target_date '|| TO_CHAR(gt_target_date_tab(i).target_date,'YYYY/MM/DD') ||' '||'start '|| TO_CHAR(SYSDATE ,'HH24:MI:SS')
      );
--
      <<sales_loop>>
      LOOP
        FETCH bus_s_group_sum_trans_cur INTO bus_s_group_sum_trans_rec;
        EXIT WHEN bus_s_group_sum_trans_cur%NOTFOUND;
--
          -- 初期化
          ln_dummy := 0;
--
          -- 同一年月／稼働日／顧客／政策群データ確認
          SELECT /*+ INDEX(xp XXCOS_REP_BUS_S_SUM_PY_N02) */
                 COUNT(1)  AS dummy
          INTO   ln_dummy
          FROM   xxcos_rep_bus_s_group_sum_py xp
          WHERE  xp.dlv_month          = gv_target_month
          AND    xp.work_days          = gn_target_work_days
          AND    xp.customer_code      = bus_s_group_sum_trans_rec.customer_code
          AND    xp.policy_group_code  = bus_s_group_sum_trans_rec.policy_group_code
          AND    xp.sales_transfer_div = cv_dlv_trans                               -- 実績振替
          ;
--
        -- データが存在しない場合は登録
        IF ( ln_dummy = 0 ) THEN
--
          -- 対象件数カウント
          gn_target_cnt := gn_target_cnt + 1;
--
          BEGIN
            INSERT INTO xxcos_rep_bus_s_group_sum_py(
               sales_transfer_div
              ,dlv_month
              ,work_days
              ,customer_code
              ,policy_group_code
              ,sale_amount
              ,business_cost
              ,created_by
              ,creation_date
              ,last_updated_by
              ,last_update_date
              ,last_update_login
              ,request_id
              ,program_application_id
              ,program_id
              ,program_update_date
            ) VALUES
            (
               cv_dlv_trans                                       -- 販売振替区分(実績振替)
              ,bus_s_group_sum_trans_rec.dlv_month                -- 納品月
              ,gn_target_work_days                                -- 営業日
              ,bus_s_group_sum_trans_rec.customer_code            -- 顧客コード
              ,bus_s_group_sum_trans_rec.policy_group_code        -- 政策群コード
              ,bus_s_group_sum_trans_rec.sale_amount              -- 純売上金額
              ,bus_s_group_sum_trans_rec.business_cost            -- 営業原価
              ,cn_created_by
              ,cd_creation_date
              ,cn_last_updated_by
              ,cd_last_update_date
              ,cn_last_update_login
              ,cn_request_id
              ,cn_program_application_id
              ,cn_program_id
              ,cd_program_update_date
            );
--
            -- 正常件数カウント
            gn_normal_cnt    := gn_normal_cnt + 1;
            gn_ins_trans_cnt := gn_ins_trans_cnt + 1;
--
          EXCEPTION
            WHEN OTHERS THEN
              -- テーブル名取得
              lt_table_name := xxccp_common_pkg.get_msg(
                iv_application        => ct_xxcos_appl_short_name,
                iv_name               => ct_msg_s_group_sum_py_tbl
              );
              lv_errmsg := xxccp_common_pkg.get_msg(
                iv_application        => ct_xxcos_appl_short_name,
                iv_name               => ct_msg_insert_data_err,
                iv_token_name1        => cv_tkn_table_name,
                iv_token_value1       => lt_table_name,
                iv_token_name2        => cv_tkn_key_data,
                iv_token_value2       => NULL
              );
              -- エラー内容取得
              lv_errbuf := SQLERRM;
              RAISE global_api_expt;
          END;
--
        -- データが存在する場合は更新(加算)
        ELSE
--
          BEGIN
            UPDATE /*+ INDEX(xp XXCOS_REP_BUS_S_SUM_PY_N02) */
                   xxcos_rep_bus_s_group_sum_py xp
            SET    xp.sale_amount        = xp.sale_amount   + bus_s_group_sum_trans_rec.sale_amount
                  ,xp.business_cost      = xp.business_cost + bus_s_group_sum_trans_rec.business_cost
            WHERE  xp.dlv_month          = gv_target_month
            AND    xp.work_days          = gn_target_work_days
            AND    xp.customer_code      = bus_s_group_sum_trans_rec.customer_code
            AND    xp.policy_group_code  = bus_s_group_sum_trans_rec.policy_group_code
            AND    xp.sales_transfer_div = cv_dlv_trans                                -- 実績振替
            ;
          EXCEPTION
            WHEN OTHERS THEN
              -- テーブル名取得
              lt_table_name := xxccp_common_pkg.get_msg(
                iv_application        => ct_xxcos_appl_short_name,
                iv_name               => ct_msg_s_group_sum_py_tbl
              );
              lv_errmsg := xxccp_common_pkg.get_msg(
                iv_application        => ct_xxcos_appl_short_name,
                iv_name               => ct_msg_update_data_err,
                iv_token_name1        => cv_tkn_table_name,
                iv_token_value1       => lt_table_name,
                iv_token_name2        => cv_tkn_key_data,
                iv_token_value2       => NULL
              );
              -- エラー内容取得
              lv_errbuf := SQLERRM;
              RAISE global_api_expt;
          END;
        END IF;
      END LOOP sales_loop;
      CLOSE bus_s_group_sum_trans_cur;
--
      -- 稼働日単位でコミット
      COMMIT;
--
    END LOOP cal_loop;
--
  EXCEPTION
    --*** ロック例外ハンドラ ***
    WHEN global_data_lock_expt THEN
      ov_errbuf := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
    --*** データ削除例外ハンドラ ***
    WHEN global_delete_data_expt THEN
      ov_errbuf := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    --*** データ登録例外ハンドラ ***
    WHEN global_insert_data_expt THEN
      ov_errbuf := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
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
  END bus_s_group_sum_trans;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    iv_delivery_date       IN  VARCHAR2,     -- 1.納品日
    iv_processing_class    IN  VARCHAR2,     -- 2.処理区分
    ov_errbuf              OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode             OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg              OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
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
    lt_table_name        dba_tab_comments.comments%TYPE;    -- テーブル名
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
--
    -- グローバル変数の初期化
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    gn_warn_cnt   := 0;
--
    -- 処理フラグ
    gv_any_time_flag       := cv_no;
    gv_part_comp_err_flag  := cv_no;
    -- 各処理件数
    gn_ins_sales_cnt := 0;
    gn_ins_trans_cnt := 0;
    gn_del_sales_cnt := 0;
    gn_del_trans_cnt := 0;
--
    --*********************************************
    --***      MD.050のフロー図を表す           ***
    --***      分岐と処理部の呼び出しを行う     ***
    --*********************************************
--
    -- ===============================
    -- 初期処理(C-1)
    -- ===============================
    init(
      iv_delivery_date,     -- 1.納品日
      iv_processing_class,  -- 2.処理区分
      lv_errbuf,         -- エラー・メッセージ           --# 固定 #
      lv_retcode,        -- リターン・コード             --# 固定 #
      lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
    --
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
--
    -- 処理区分が'0'(全て)、または'1'(販売実績情報集計(前年))の場合
    IF ( gv_processing_class IN ( cv_para_cls_all, cv_para_cls_s_group_sum_sales ) ) THEN
      -- ===============================
      -- 販売実績情報集計(前年)処理(C-2)
      --   期限切れ集計データ削除処理(C-4)
      -- ===============================
      bus_s_group_sum_sales(
        lv_errbuf,         -- エラー・メッセージ           --# 固定 #
        lv_retcode,        -- リターン・コード             --# 固定 #
        lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
      --
      IF (lv_retcode <> cv_status_normal) THEN
        -- 一部処理後エラーフラグに'Y'をセット
        gv_part_comp_err_flag := cv_yes;
        RAISE global_process_expt;
      END IF;
    END IF;
--
    -- 処理区分が'0'(全て)、または'2'(実績振替情報集計(前年))の場合
    IF ( gv_processing_class IN ( cv_para_cls_all, cv_para_cls_s_group_sum_trans ) ) THEN
      -- ===============================
      -- 実績振替情報集計(前年)処理(C-3)
      --   期限切れ集計データ削除処理(C-4)
      -- ===============================
      bus_s_group_sum_trans(
        lv_errbuf,         -- エラー・メッセージ           --# 固定 #
        lv_retcode,        -- リターン・コード             --# 固定 #
        lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
      --
      IF (lv_retcode <> cv_status_normal) THEN
        -- 一部処理後エラーフラグに'Y'をセット
        gv_part_comp_err_flag := cv_yes;
        RAISE global_process_expt;
      END IF;
    END IF;
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    ELSIF (lv_retcode = cv_status_warn) THEN
      NULL;
    END IF;
--
  EXCEPTION
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
    errbuf                 OUT  VARCHAR2,      --   エラー・メッセージ  --# 固定 #
    retcode                OUT  VARCHAR2,      --   リターン・コード    --# 固定 #
    iv_delivery_date       IN   VARCHAR2,      -- 1.納品日
    iv_processing_class    IN   VARCHAR2       -- 2.処理区分
  )
--
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
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf          VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode         VARCHAR2(1);     -- リターン・コード
    lv_errmsg          VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
    lv_message_code    VARCHAR2(100);   -- 終了メッセージコード
--
    lt_table_name      dba_tab_comments.comments%TYPE;    -- テーブル名
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
       iv_delivery_date
      ,iv_processing_class
      ,lv_errbuf   -- エラー・メッセージ           --# 固定 #
      ,lv_retcode  -- リターン・コード             --# 固定 #
      ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    -- ===============================
    -- 終了処理(C-5)
    -- ===============================
    -- エラー出力
    IF (lv_retcode = cv_status_error) THEN
      -- エラー件数セット
      -- ※途中でコミットするので他件数をクリアしない
      gn_error_cnt := 1;
--
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg -- ユーザー・エラーメッセージ
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf -- エラーメッセージ
      );
      -- 空行出力
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => ''
      );
    END IF;
--
    -- 処理区分が'0'(全て)、または'1'(販売実績情報集計(前年))の場合
    IF ( gv_processing_class IN ( cv_para_cls_all, cv_para_cls_s_group_sum_sales ) ) THEN
      -- 販売実績情報集計(前年)処理件数出力
      gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => ct_xxcos_appl_short_name
                      ,iv_name         => ct_msg_count_s_group_sales
                      ,iv_token_name1  => cv_cnt_token
                      ,iv_token_value1 => TO_CHAR(gn_ins_sales_cnt)
                     );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => gv_out_msg
      );
    END IF;
--
    -- 処理区分が'0'(全て)、または'2'(実績振替情報集計(前年))の場合
    IF ( gv_processing_class IN ( cv_para_cls_all, cv_para_cls_s_group_sum_trans ) ) THEN
      -- 実績振替情報集計(前年)処理件数出力
      gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => ct_xxcos_appl_short_name
                      ,iv_name         => ct_msg_count_s_group_trans
                      ,iv_token_name1  => cv_cnt_token
                      ,iv_token_value1 => TO_CHAR(gn_ins_trans_cnt)
                     );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => gv_out_msg
      );
    END IF;
--
    -- 空行出力
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
--
    -- 定期実行の場合
    IF ( gv_any_time_flag = cv_no ) THEN
      -- 期限切れ集計情報（前年）削除件数出力
      gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => ct_xxcos_appl_short_name
                      ,iv_name         => ct_msg_delete_invalidity
                      ,iv_token_name1  => cv_tkn_keeping_period
                      ,iv_token_value1 => gt_prof_002a03_keeping_period
                      ,iv_token_name2  => cv_tkn_deletion_object
                      ,iv_token_value2 => gv_invalidity_month
                      ,iv_token_name3  => cv_tkn_delete_sales
                      ,iv_token_value3 => TO_CHAR(gn_del_sales_cnt)
                      ,iv_token_name4  => cv_tkn_delete_trans
                      ,iv_token_value4 => TO_CHAR(gn_del_trans_cnt)
                     );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => gv_out_msg
      );
      -- 空行出力
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => ''
      );
    END IF;
--
    -- 対象件数出力
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
    -- 成功件数出力
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
    -- エラー件数出力
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
    -- メッセージコード設定
    IF (lv_retcode = cv_status_normal) THEN
      lv_message_code := cv_normal_msg;
    ELSIF(lv_retcode = cv_status_warn) THEN
      lv_message_code := cv_warn_msg;
    ELSIF(lv_retcode = cv_status_error) THEN
      lv_message_code := cv_error_msg;
    END IF;
--
    -- C-2以降でエラー発生の場合はメッセージ変更
    IF ( gv_part_comp_err_flag = cv_yes ) THEN
      -- テーブル名取得
      lt_table_name := xxccp_common_pkg.get_msg(
        iv_application        => ct_xxcos_appl_short_name,
        iv_name               => ct_msg_s_group_sum_py_tbl
      );
      gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => ct_xxcos_appl_short_name
                      ,iv_name         => ct_msg_part_comp_err
                      ,iv_token_name1  => cv_tkn_table_name
                      ,iv_token_value1 => lt_table_name
                     );
    -- 通常メッセージ
    ELSE
      gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name
                      ,iv_name         => lv_message_code
                     );
    END IF;
--
    -- 終了メッセージ出力
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    -- ステータスセット
    retcode := lv_retcode;
    -- 終了ステータスがエラーの場合はROLLBACKする
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
END XXCOS002A033C;
/
