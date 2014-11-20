CREATE OR REPLACE PACKAGE BODY XXCMN960009C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2012. All rights reserved.
 *
 * Package Name     : XXCMN960009C(body)
 * Description      : 配車配送計画バックアップ
 * MD.050           : T_MD050_BPO_96I_配車配送計画バックアップ.xls
 * Version          : 1.00
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2012/10/29    1.00  SCSK 宮本直樹    新規作成
 *
 *****************************************************************************************/
--
--#######################  固定グローバル定数宣言部 START   #######################
--
  --ステータス・コード
  cv_status_normal   CONSTANT VARCHAR2(1)  := xxccp_common_pkg.set_status_normal; --正常:0
  cv_status_error    CONSTANT VARCHAR2(1)  := xxccp_common_pkg.set_status_error;  --異常:2
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
  local_process_expt        EXCEPTION;
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name        CONSTANT VARCHAR2(100) := 'XXCMN960009C';            -- パッケージ名
  cv_proc_date_msg   CONSTANT VARCHAR2(50)  := 'APP-XXCMN-11014';         --処理日出力
  cv_par_token       CONSTANT VARCHAR2(10)  := 'PAR';                     --処理日MSG用ﾄｰｸﾝ名
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gn_arc_cnt_carrier        NUMBER;                                       -- バックアップ件数（配車配送計画（アドオン））
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    iv_proc_date  IN  VARCHAR2,     --   1.処理日
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
    cv_prg_name            CONSTANT VARCHAR2(100) := 'submain';             -- プログラム名
    cv_appl_short_name     CONSTANT VARCHAR2(10)  := 'XXCMN';               -- アドオン：共通・IF領域
    cv_get_priod_msg       CONSTANT VARCHAR2(100) := 'APP-XXCMN-11012';     -- バックアップ期間の取得に失敗しました。
    cv_get_profile_msg     CONSTANT VARCHAR2(100) := 'APP-XXCMN-10002';     -- プロファイル[ ＆NG_PROFILE ]の取得に失敗しました。
    cv_local_others_msg    CONSTANT VARCHAR2(100) := 'APP-XXCMN-11025';     -- バックアップ処理に失敗しました。【配車配送計画】取引ID： ＆KEY
    cv_token_profile       CONSTANT VARCHAR2(10)  := 'NG_PROFILE';
    cv_token_key           CONSTANT VARCHAR2(10)  := 'KEY';
--
    cv_xxcmn_commit_range  CONSTANT VARCHAR2(100) := 'XXCMN_COMMIT_RANGE';  --XXCMN:分割コミット数
    cv_xxcmn_archive_range CONSTANT VARCHAR2(100) := 'XXCMN_ARCHIVE_RANGE'; --XXCMN:バックアップレンジ
--
    cv_date_format         CONSTANT VARCHAR2(10)  := 'YYYY/MM/DD';
--
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
    cv_purge_type   CONSTANT VARCHAR2(1)  := '1';                           -- パージタイプ（1:バックアップ処理期間）
    cv_purge_code   CONSTANT VARCHAR2(30) := '9601';                        -- パージ定義コード
--
    -- *** ローカル変数 ***
    ln_arc_cnt_carrier_yet    NUMBER DEFAULT 0;                             -- 未コミットバックアップ件数（配車配送計画（アドオン））
    ln_archive_period         NUMBER;                                       -- バックアップ期間
    ln_archive_range          NUMBER;                                       -- バックアップレンジ
    ld_standard_date          DATE;                                         -- 基準日
    ln_commit_range           NUMBER;                                       -- 分割コミット数
    lt_transaction_id         xxwsh_carriers_schedule.transaction_id%TYPE;  -- 対象トランザクションID
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    /*
        -- 配車配送計画（アドオン）
        CURSOR バックアップ対象配車配送計画（アドオン）取得
          id_基準日  IN DATE
          in_バックアップレンジ IN NUMBER
        IS
          SELECT 
                 配車配送計画（アドオン）．トランザクションＩＤ
          FROM 配車配送計画（アドオン）
          WHERE 配車配送計画（アドオン）．着荷日 IS NOT NULL
          AND 配車配送計画（アドオン）．着荷日 >= id_基準日 - in_バックアップレンジ
          AND 配車配送計画（アドオン）．着荷日 < id_基準日
          AND NOT EXISTS (
                   SELECT  1
                   FROM 配車配送計画（アドオン）バックアップ
                   WHERE 配車配送計画（アドオン）バックアップ．トランザクションＩＤ = 配車配送計画（アドオン）．トランザクションＩＤ
                   AND ROWNUM = 1
                 )
          UNION ALL
          SELECT 
                 配車配送計画（アドオン）．トランザクションＩＤ
          FROM 配車配送計画（アドオン）
          WHERE 配車配送計画（アドオン）．着荷日 IS NULL
          AND 配車配送計画（アドオン）．着荷予定日 >= id_基準日 - in_バックアップレンジ
          AND 配車配送計画（アドオン）．着荷予定日 < id_基準日
          AND NOT EXISTS (
                   SELECT  1
                   FROM 配車配送計画（アドオン）バックアップ
                   WHERE 配車配送計画（アドオン）バックアップ．トランザクションＩＤ = 配車配送計画（アドオン）．トランザクションＩＤ
                   AND ROWNUM = 1
                 )
        ;
    */
--
    CURSOR arc_carriers_schedule_cur(
      id_standard_date           DATE
     ,in_archive_range           NUMBER
    )
    IS
      SELECT   xcs.transaction_id               AS transaction_id
              ,xcs.transaction_type             AS transaction_type
              ,xcs.mixed_type                   AS mixed_type
              ,xcs.delivery_no                  AS delivery_no
              ,xcs.default_line_number          AS default_line_number
              ,xcs.carrier_id                   AS carrier_id
              ,xcs.carrier_code                 AS carrier_code
              ,xcs.deliver_from_id              AS deliver_from_id
              ,xcs.deliver_from                 AS deliver_from
              ,xcs.deliver_to_id                AS deliver_to_id
              ,xcs.deliver_to                   AS deliver_to
              ,xcs.deliver_to_code_class        AS deliver_to_code_class
              ,xcs.delivery_type                AS delivery_type
              ,xcs.order_type_id                AS order_type_id
              ,xcs.auto_process_type            AS auto_process_type
              ,xcs.schedule_ship_date           AS schedule_ship_date
              ,xcs.schedule_arrival_date        AS schedule_arrival_date
              ,xcs.description                  AS description
              ,xcs.payment_freight_flag         AS payment_freight_flag
              ,xcs.demand_freight_flag          AS demand_freight_flag
              ,xcs.sum_loading_weight           AS sum_loading_weight
              ,xcs.sum_loading_capacity         AS sum_loading_capacity
              ,xcs.loading_efficiency_weight    AS loading_efficiency_weight
              ,xcs.loading_efficiency_capacity  AS loading_efficiency_capacity
              ,xcs.based_weight                 AS based_weight
              ,xcs.based_capacity               AS based_capacity
              ,xcs.result_freight_carrier_id    AS result_freight_carrier_id
              ,xcs.result_freight_carrier_code  AS result_freight_carrier_code
              ,xcs.result_shipping_method_code  AS result_shipping_method_code
              ,xcs.shipped_date                 AS shipped_date
              ,xcs.arrival_date                 AS arrival_date
              ,xcs.weight_capacity_class        AS weight_capacity_class
              ,xcs.freight_charge_type          AS freight_charge_type
              ,xcs.slip_number                  AS slip_number
              ,xcs.small_quantity               AS small_quantity
              ,xcs.label_quantity               AS label_quantity
              ,xcs.prod_class                   AS prod_class
              ,xcs.non_slip_class               AS non_slip_class
              ,xcs.created_by                   AS created_by
              ,xcs.creation_date                AS creation_date
              ,xcs.last_updated_by              AS last_updated_by
              ,xcs.last_update_date             AS last_update_date
              ,xcs.last_update_login            AS last_update_login
              ,xcs.request_id                   AS request_id
              ,xcs.program_application_id       AS program_application_id
              ,xcs.program_id                   AS program_id
              ,xcs.program_update_date          AS program_update_date
      FROM    xxwsh_carriers_schedule xcs
      WHERE   xcs.arrival_date IS NOT NULL
      AND     xcs.arrival_date >= id_standard_date - in_archive_range
      AND     xcs.arrival_date <  id_standard_date
      AND     NOT EXISTS (
                SELECT  1
                FROM    xxcmn_carriers_schedule_arc  xcsa
                WHERE   xcsa.transaction_id = xcs.transaction_id
                AND     ROWNUM                = 1
              )
      UNION ALL
      SELECT   xcs.transaction_id               AS transaction_id
              ,xcs.transaction_type             AS transaction_type
              ,xcs.mixed_type                   AS mixed_type
              ,xcs.delivery_no                  AS delivery_no
              ,xcs.default_line_number          AS default_line_number
              ,xcs.carrier_id                   AS carrier_id
              ,xcs.carrier_code                 AS carrier_code
              ,xcs.deliver_from_id              AS deliver_from_id
              ,xcs.deliver_from                 AS deliver_from
              ,xcs.deliver_to_id                AS deliver_to_id
              ,xcs.deliver_to                   AS deliver_to
              ,xcs.deliver_to_code_class        AS deliver_to_code_class
              ,xcs.delivery_type                AS delivery_type
              ,xcs.order_type_id                AS order_type_id
              ,xcs.auto_process_type            AS auto_process_type
              ,xcs.schedule_ship_date           AS schedule_ship_date
              ,xcs.schedule_arrival_date        AS schedule_arrival_date
              ,xcs.description                  AS description
              ,xcs.payment_freight_flag         AS payment_freight_flag
              ,xcs.demand_freight_flag          AS demand_freight_flag
              ,xcs.sum_loading_weight           AS sum_loading_weight
              ,xcs.sum_loading_capacity         AS sum_loading_capacity
              ,xcs.loading_efficiency_weight    AS loading_efficiency_weight
              ,xcs.loading_efficiency_capacity  AS loading_efficiency_capacity
              ,xcs.based_weight                 AS based_weight
              ,xcs.based_capacity               AS based_capacity
              ,xcs.result_freight_carrier_id    AS result_freight_carrier_id
              ,xcs.result_freight_carrier_code  AS result_freight_carrier_code
              ,xcs.result_shipping_method_code  AS result_shipping_method_code
              ,xcs.shipped_date                 AS shipped_date
              ,xcs.arrival_date                 AS arrival_date
              ,xcs.weight_capacity_class        AS weight_capacity_class
              ,xcs.freight_charge_type          AS freight_charge_type
              ,xcs.slip_number                  AS slip_number
              ,xcs.small_quantity               AS small_quantity
              ,xcs.label_quantity               AS label_quantity
              ,xcs.prod_class                   AS prod_class
              ,xcs.non_slip_class               AS non_slip_class
              ,xcs.created_by                   AS created_by
              ,xcs.creation_date                AS creation_date
              ,xcs.last_updated_by              AS last_updated_by
              ,xcs.last_update_date             AS last_update_date
              ,xcs.last_update_login            AS last_update_login
              ,xcs.request_id                   AS request_id
              ,xcs.program_application_id       AS program_application_id
              ,xcs.program_id                   AS program_id
              ,xcs.program_update_date          AS program_update_date
      FROM    xxwsh_carriers_schedule xcs
      WHERE   xcs.arrival_date IS NULL
      AND     xcs.schedule_arrival_date >= id_standard_date - in_archive_range
      AND     xcs.schedule_arrival_date <  id_standard_date
      AND     NOT EXISTS (
                SELECT  1
                FROM    xxcmn_carriers_schedule_arc  xcsa
                WHERE   xcsa.transaction_id = xcs.transaction_id
                AND     ROWNUM                = 1
              )
    ;
    -- <カーソル名>レコード型

    --メインカーソルで取得したデータを格納するテーブル
    TYPE arc_carriers_schedule_ttype IS TABLE OF xxwsh_carriers_schedule%ROWTYPE INDEX BY BINARY_INTEGER;
    lt_arc_carrier_schedule_tbl       arc_carriers_schedule_ttype;

    --バックアップテーブルにセットする値を格納するテーブル
    TYPE carriers_schedule_ttype IS TABLE OF xxcmn_carriers_schedule_arc%ROWTYPE INDEX BY BINARY_INTEGER;
    lt_carrier_schedule_tbl       carriers_schedule_ttype;                               -- 配車配送計画(アドオン)テーブル
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
    gn_arc_cnt_carrier := 0;
--
    --*********************************************
    --***      MD.050のフロー図を表す           ***
    --***      分岐と処理部の呼び出しを行う     ***
    --*********************************************
--
    -- ===============================================
    -- 89バックアップ期間取得
    -- ===============================================
    /*
    ln_バックアップ期間 := バックアップ期間取得共通関数（cv_パージ定義コード）;
     */
    ln_archive_period := xxcmn_common4_pkg.get_purge_period(cv_purge_type, cv_purge_code);
    IF ( ln_archive_period IS NULL ) THEN
--
      ov_errmsg := xxcmn_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_get_priod_msg
                   );
      ov_retcode := cv_status_error;
      RAISE local_process_expt;
--
    END IF;
    FND_FILE.PUT_LINE (FND_FILE.LOG, 'バックアップ期間:' || TO_CHAR(ln_archive_period));
--
    -- ===============================================
    -- ＩＮパラメータの確認
    -- ===============================================
    /*96
    iv_proc_dateがNULLの場合
--
      ld_基準日 := 処理日取得共通関数から取得した処理日 - ln_バックアップ期間;
--
    iv_proc_dateがNULLでないの場合
--
      ld_基準日 := TO_DATE(iv_proc_date) - ln_バックアップ期間;
     */
    IF ( iv_proc_date IS NULL ) THEN
--
      ld_standard_date := xxcmn_common4_pkg.get_syori_date - ln_archive_period;
--
    ELSE
--
      ld_standard_date := TO_DATE(iv_proc_date, cv_date_format) - ln_archive_period;
--
    END IF;
    FND_FILE.PUT_LINE (FND_FILE.LOG, '基準日:' || TO_CHAR(ld_standard_date,'YYYY/MM/DD'));
--
    -- ===============================================
    -- プロファイル・オプション値取得
    -- ===============================================
    /*107
    ln_分割コミット数 := TO_NUMBER(プロファイル・オプション取得(XXCMN:バックアップ分割コミット数));
    ln_バックアップレンジ := TO_NUMBER(プロファイル・オプション取得(XXCMN:バックアップレンジ));
     */
    BEGIN
      ln_commit_range  := TO_NUMBER(fnd_profile.value(cv_xxcmn_commit_range));
      IF ( ln_commit_range IS NULL ) THEN
--
        ov_errmsg := xxcmn_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name
                      ,iv_name         => cv_get_profile_msg
                      ,iv_token_name1  => cv_token_profile
                      ,iv_token_value1 => cv_xxcmn_commit_range
                     );
        ov_retcode := cv_status_error;
        RAISE local_process_expt;
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        ov_errmsg := xxcmn_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name
                      ,iv_name         => cv_get_profile_msg
                      ,iv_token_name1  => cv_token_profile
                      ,iv_token_value1 => cv_xxcmn_commit_range
                     );
        ov_retcode := cv_status_error;
        RAISE local_process_expt;
    END;
    FND_FILE.PUT_LINE (FND_FILE.LOG, '分割コミット数:' || TO_CHAR(ln_commit_range));
--
    BEGIN
      ln_archive_range := TO_NUMBER(fnd_profile.value(cv_xxcmn_archive_range));
      IF ( ln_archive_range IS NULL ) THEN
--
        ov_errmsg := xxcmn_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name
                      ,iv_name         => cv_get_profile_msg
                      ,iv_token_name1  => cv_token_profile
                      ,iv_token_value1 => cv_xxcmn_archive_range
                     );
        ov_retcode := cv_status_error;
        RAISE local_process_expt;
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        ov_errmsg := xxcmn_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name
                      ,iv_name         => cv_get_profile_msg
                      ,iv_token_name1  => cv_token_profile
                      ,iv_token_value1 => cv_xxcmn_archive_range
                     );
        ov_retcode := cv_status_error;
        RAISE local_process_expt;
    END;
    FND_FILE.PUT_LINE (FND_FILE.LOG, 'バックアップレンジ:' || TO_CHAR(ln_archive_range));
    FND_FILE.PUT_LINE (FND_FILE.LOG, 'バックアップFrom:' || TO_CHAR(ld_standard_date-ln_archive_range,'YYYY/MM/DD'));
--
    -- ===============================================
    -- バックアップ対象配車配送計画（アドオン）取得
    -- ===============================================
    /*
      OPEN バックアップ対象配車配送計画（アドオン）取得（ld_基準日，ln_バックアップレンジ);
      FETCH バックアップ対象配車配送計画（アドオン）取得 BULK COLLECT INTO lt_対象データフェッチテーブル;
      フェッチ行が存在した場合は
      FOR ln_main_idx in 1 .. lt_対象データフェッチテーブル.COUNT  LOOP
    */
    OPEN arc_carriers_schedule_cur(ld_standard_date,ln_archive_range);
    FETCH arc_carriers_schedule_cur BULK COLLECT INTO lt_arc_carrier_schedule_tbl;
--
    IF ( lt_arc_carrier_schedule_tbl.COUNT ) > 0 THEN
      << archive_carriers_schedule_loop >>
      FOR ln_main_idx in 1 .. lt_arc_carrier_schedule_tbl.COUNT
      LOOP
        -- ===============================================
        -- 分割コミット
        -- ===============================================
        /*
          NVL(ln_分割コミット数, 0) <> 0の場合
        */
        IF ( NVL(ln_commit_range, 0) <> 0 ) THEN
  --
          /*
            ln_未コミットバックアップ件数（配車配送計画（アドオン）） > 0
            かつ MOD(ln_未コミットバックアップ件数（配車配送計画（アドオン））, ln_分割コミット数) = 0の場合
          */
          IF (  (ln_arc_cnt_carrier_yet > 0)
            AND (MOD(ln_arc_cnt_carrier_yet, ln_commit_range) = 0)
             )
          THEN
  --
            /*
              FORALL ln_idx IN 1..ln_未コミットバックアップ件数（配車配送計画（アドオン））
                INSERT INTO 配車配送計画（アドオン）バックアップ
                (
                    全カラム
                  , バックアップ登録日
                  , バックアップ要求ID
                )
                VALUES
                (
                    lt_配車配送計画（アドオン）テーブル（ln_idx）全カラム
                  , SYSDATE
                  , 要求ID
                )
              ;
            */
            FORALL ln_idx IN 1..ln_arc_cnt_carrier_yet
              INSERT INTO xxcmn_carriers_schedule_arc VALUES lt_carrier_schedule_tbl(ln_idx);
  --
            /*
              ln_バックアップ件数（配車配送計画（アドオン）） := ln_バックアップ件数（配車配送計画（アドオン））
                                                                          + ln_未コミットバックアップ件数（配車配送計画（アドオン））;
              ln_未コミットバックアップ件数（配車配送計画（アドオン）） := 0;
              lt_配車配送計画（アドオン）テーブル．DELETE;
            */
            gn_arc_cnt_carrier     := gn_arc_cnt_carrier + ln_arc_cnt_carrier_yet;
            ln_arc_cnt_carrier_yet := 0;
            lt_carrier_schedule_tbl.DELETE;
  --
            COMMIT;
  --
          END IF;
  --
        END IF;
  --
        /*
          ln_対象トランザクションID := lr_header_rec．トランザクションID;
          ln_未コミットバックアップ件数（配車配送計画（アドオン）） := ln_未コミットバックアップ件数（配車配送計画（アドオン）） + 1;
  --
          lt_配車配送計画（アドオン）テーブル（ln_未コミットバックアップ件数（配車配送計画（アドオン）） := lt_対象データフェッチテーブル(ln_main_idx);
        */
        ln_arc_cnt_carrier_yet := ln_arc_cnt_carrier_yet + 1;
  --
        lt_carrier_schedule_tbl(ln_arc_cnt_carrier_yet).transaction_id              := lt_arc_carrier_schedule_tbl(ln_main_idx).transaction_id;
        lt_carrier_schedule_tbl(ln_arc_cnt_carrier_yet).transaction_type            := lt_arc_carrier_schedule_tbl(ln_main_idx).transaction_type;
        lt_carrier_schedule_tbl(ln_arc_cnt_carrier_yet).mixed_type                  := lt_arc_carrier_schedule_tbl(ln_main_idx).mixed_type;
        lt_carrier_schedule_tbl(ln_arc_cnt_carrier_yet).delivery_no                 := lt_arc_carrier_schedule_tbl(ln_main_idx).delivery_no;
        lt_carrier_schedule_tbl(ln_arc_cnt_carrier_yet).default_line_number         := lt_arc_carrier_schedule_tbl(ln_main_idx).default_line_number;
        lt_carrier_schedule_tbl(ln_arc_cnt_carrier_yet).carrier_id                  := lt_arc_carrier_schedule_tbl(ln_main_idx).carrier_id;
        lt_carrier_schedule_tbl(ln_arc_cnt_carrier_yet).carrier_code                := lt_arc_carrier_schedule_tbl(ln_main_idx).carrier_code;
        lt_carrier_schedule_tbl(ln_arc_cnt_carrier_yet).deliver_from_id             := lt_arc_carrier_schedule_tbl(ln_main_idx).deliver_from_id;
        lt_carrier_schedule_tbl(ln_arc_cnt_carrier_yet).deliver_from                := lt_arc_carrier_schedule_tbl(ln_main_idx).deliver_from;
        lt_carrier_schedule_tbl(ln_arc_cnt_carrier_yet).deliver_to_id               := lt_arc_carrier_schedule_tbl(ln_main_idx).deliver_to_id;
        lt_carrier_schedule_tbl(ln_arc_cnt_carrier_yet).deliver_to                  := lt_arc_carrier_schedule_tbl(ln_main_idx).deliver_to;
        lt_carrier_schedule_tbl(ln_arc_cnt_carrier_yet).deliver_to_code_class       := lt_arc_carrier_schedule_tbl(ln_main_idx).deliver_to_code_class;
        lt_carrier_schedule_tbl(ln_arc_cnt_carrier_yet).delivery_type               := lt_arc_carrier_schedule_tbl(ln_main_idx).delivery_type;
        lt_carrier_schedule_tbl(ln_arc_cnt_carrier_yet).order_type_id               := lt_arc_carrier_schedule_tbl(ln_main_idx).order_type_id;
        lt_carrier_schedule_tbl(ln_arc_cnt_carrier_yet).auto_process_type           := lt_arc_carrier_schedule_tbl(ln_main_idx).auto_process_type;
        lt_carrier_schedule_tbl(ln_arc_cnt_carrier_yet).schedule_ship_date          := lt_arc_carrier_schedule_tbl(ln_main_idx).schedule_ship_date;
        lt_carrier_schedule_tbl(ln_arc_cnt_carrier_yet).schedule_arrival_date       := lt_arc_carrier_schedule_tbl(ln_main_idx).schedule_arrival_date;
        lt_carrier_schedule_tbl(ln_arc_cnt_carrier_yet).description                 := lt_arc_carrier_schedule_tbl(ln_main_idx).description;
        lt_carrier_schedule_tbl(ln_arc_cnt_carrier_yet).payment_freight_flag        := lt_arc_carrier_schedule_tbl(ln_main_idx).payment_freight_flag;
        lt_carrier_schedule_tbl(ln_arc_cnt_carrier_yet).demand_freight_flag         := lt_arc_carrier_schedule_tbl(ln_main_idx).demand_freight_flag;
        lt_carrier_schedule_tbl(ln_arc_cnt_carrier_yet).sum_loading_weight          := lt_arc_carrier_schedule_tbl(ln_main_idx).sum_loading_weight;
        lt_carrier_schedule_tbl(ln_arc_cnt_carrier_yet).sum_loading_capacity        := lt_arc_carrier_schedule_tbl(ln_main_idx).sum_loading_capacity;
        lt_carrier_schedule_tbl(ln_arc_cnt_carrier_yet).loading_efficiency_weight   := lt_arc_carrier_schedule_tbl(ln_main_idx).loading_efficiency_weight;
        lt_carrier_schedule_tbl(ln_arc_cnt_carrier_yet).loading_efficiency_capacity := lt_arc_carrier_schedule_tbl(ln_main_idx).loading_efficiency_capacity;
        lt_carrier_schedule_tbl(ln_arc_cnt_carrier_yet).based_weight                := lt_arc_carrier_schedule_tbl(ln_main_idx).based_weight;
        lt_carrier_schedule_tbl(ln_arc_cnt_carrier_yet).based_capacity              := lt_arc_carrier_schedule_tbl(ln_main_idx).based_capacity;
        lt_carrier_schedule_tbl(ln_arc_cnt_carrier_yet).result_freight_carrier_id   := lt_arc_carrier_schedule_tbl(ln_main_idx).result_freight_carrier_id;
        lt_carrier_schedule_tbl(ln_arc_cnt_carrier_yet).result_freight_carrier_code := lt_arc_carrier_schedule_tbl(ln_main_idx).result_freight_carrier_code;
        lt_carrier_schedule_tbl(ln_arc_cnt_carrier_yet).result_shipping_method_code := lt_arc_carrier_schedule_tbl(ln_main_idx).result_shipping_method_code;
        lt_carrier_schedule_tbl(ln_arc_cnt_carrier_yet).shipped_date                := lt_arc_carrier_schedule_tbl(ln_main_idx).shipped_date;
        lt_carrier_schedule_tbl(ln_arc_cnt_carrier_yet).arrival_date                := lt_arc_carrier_schedule_tbl(ln_main_idx).arrival_date;
        lt_carrier_schedule_tbl(ln_arc_cnt_carrier_yet).weight_capacity_class       := lt_arc_carrier_schedule_tbl(ln_main_idx).weight_capacity_class;
        lt_carrier_schedule_tbl(ln_arc_cnt_carrier_yet).freight_charge_type         := lt_arc_carrier_schedule_tbl(ln_main_idx).freight_charge_type;
        lt_carrier_schedule_tbl(ln_arc_cnt_carrier_yet).slip_number                 := lt_arc_carrier_schedule_tbl(ln_main_idx).slip_number;
        lt_carrier_schedule_tbl(ln_arc_cnt_carrier_yet).small_quantity              := lt_arc_carrier_schedule_tbl(ln_main_idx).small_quantity;
        lt_carrier_schedule_tbl(ln_arc_cnt_carrier_yet).label_quantity              := lt_arc_carrier_schedule_tbl(ln_main_idx).label_quantity;
        lt_carrier_schedule_tbl(ln_arc_cnt_carrier_yet).prod_class                  := lt_arc_carrier_schedule_tbl(ln_main_idx).prod_class;
        lt_carrier_schedule_tbl(ln_arc_cnt_carrier_yet).non_slip_class              := lt_arc_carrier_schedule_tbl(ln_main_idx).non_slip_class;
        lt_carrier_schedule_tbl(ln_arc_cnt_carrier_yet).created_by                  := lt_arc_carrier_schedule_tbl(ln_main_idx).created_by;
        lt_carrier_schedule_tbl(ln_arc_cnt_carrier_yet).creation_date               := lt_arc_carrier_schedule_tbl(ln_main_idx).creation_date;
        lt_carrier_schedule_tbl(ln_arc_cnt_carrier_yet).last_updated_by             := lt_arc_carrier_schedule_tbl(ln_main_idx).last_updated_by;
        lt_carrier_schedule_tbl(ln_arc_cnt_carrier_yet).last_update_date            := lt_arc_carrier_schedule_tbl(ln_main_idx).last_update_date;
        lt_carrier_schedule_tbl(ln_arc_cnt_carrier_yet).last_update_login           := lt_arc_carrier_schedule_tbl(ln_main_idx).last_update_login;
        lt_carrier_schedule_tbl(ln_arc_cnt_carrier_yet).request_id                  := lt_arc_carrier_schedule_tbl(ln_main_idx).request_id;
        lt_carrier_schedule_tbl(ln_arc_cnt_carrier_yet).program_application_id      := lt_arc_carrier_schedule_tbl(ln_main_idx).program_application_id;
        lt_carrier_schedule_tbl(ln_arc_cnt_carrier_yet).program_id                  := lt_arc_carrier_schedule_tbl(ln_main_idx).program_id;
        lt_carrier_schedule_tbl(ln_arc_cnt_carrier_yet).program_update_date         := lt_arc_carrier_schedule_tbl(ln_main_idx).program_update_date;
        lt_carrier_schedule_tbl(ln_arc_cnt_carrier_yet).archive_date                := SYSDATE;
        lt_carrier_schedule_tbl(ln_arc_cnt_carrier_yet).archive_request_id          := cn_request_id;
--
      /*
        END LOOP バックアップ対象配車配送計画（アドオン）取得;
      */
      END LOOP archive_carriers_schedule_loop;
    END IF;
--
    /*
      FORALL ln_idx IN 1..ln_未コミットバックアップ件数（配車配送計画（アドオン））
        INSERT INTO 配車配送計画（アドオン）バックアップ
        (
             全カラム
          , バックアップ登録日
          , バックアップ要求ID
        )
        VALUES
        (
            lt_配車配送計画（アドオン）テーブル（ln_idx）全カラム
          , SYSDATE
          , 要求ID
        )
      ;
    */
    FORALL ln_idx IN 1..ln_arc_cnt_carrier_yet
      INSERT INTO xxcmn_carriers_schedule_arc VALUES lt_carrier_schedule_tbl(ln_idx);
--
    /*
      ln_バックアップ件数（配車配送計画（アドオン）） := ln_バックアップ件数（配車配送計画（アドオン））
                                                                  + ln_未コミットバックアップ件数（配車配送計画（アドオン））;
      ln_未コミットバックアップ件数（配車配送計画（アドオン）） := 0;
      lt_配車配送計画（アドオン）テーブル．DELETE;
    */
    gn_arc_cnt_carrier     := gn_arc_cnt_carrier + ln_arc_cnt_carrier_yet;
    ln_arc_cnt_carrier_yet := 0;
    lt_carrier_schedule_tbl.DELETE;
--
  EXCEPTION
      -- *** 任意で例外処理を記述する ****
      -- カーソルのクローズをここに記述する
--
--#################################  固定例外処理部 START   ###################################
--
    WHEN local_process_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
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
      lt_transaction_id := lt_carrier_schedule_tbl(SQL%BULK_EXCEPTIONS(1).ERROR_INDEX).transaction_id;
      IF ( lt_transaction_id IS NOT NULL ) THEN
        ov_errmsg := xxcmn_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name
                      ,iv_name         => cv_local_others_msg
                      ,iv_token_name1  => cv_token_key
                      ,iv_token_value1 => TO_CHAR(lt_transaction_id)
                     );
      END IF;
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
    iv_proc_date  IN  VARCHAR2       --   1.処理日
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
    cv_prg_name         CONSTANT VARCHAR2(100) := 'main';             -- プログラム名
--
    cv_appl_short_name  CONSTANT VARCHAR2(10)  := 'XXCMN';            -- アドオン：共通・IF領域
    cv_cnt_msg          CONSTANT VARCHAR2(100) := 'APP-XXCMN-11040';             -- ＆TBL_NAME ＆SHORI 件数： ＆CNT 件
    cv_token_cnt        CONSTANT VARCHAR2(100) := 'CNT';                         -- 件数メッセージ用トークン名（件数）
    cv_token_cnt_table  CONSTANT VARCHAR2(100) := 'TBL_NAME';                    -- 件数メッセージ用トークン名（テーブル名）
    cv_token_cnt_shori  CONSTANT VARCHAR2(100) := 'SHORI';                       -- 件数メッセージ用トークン名（処理名）
    cv_table_cnt_xcs    CONSTANT VARCHAR2(100) := '配車配送計画';                -- 件数メッセージ用テーブル名
    cv_shori_cnt_arc    CONSTANT VARCHAR2(100) := 'バックアップ';                -- 件数メッセージ用処理名
    cv_shori_cnt_normal CONSTANT VARCHAR2(100) := '正常';                -- 件数メッセージ用処理名
    cv_shori_cnt_error  CONSTANT VARCHAR2(100) := 'エラー';                -- 件数メッセージ用処理名
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
    -- ===============================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ===============================================
    submain(
       iv_proc_date -- 1.処理日
      ,lv_errbuf   -- エラー・メッセージ           --# 固定 #
      ,lv_retcode  -- リターン・コード             --# 固定 #
      ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    -- ===============================================
    -- ログ出力処理
    -- ===============================================
    --パラメータ(処理日： PAR)
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_proc_date_msg
                    ,iv_token_name1  => cv_par_token
                    ,iv_token_value1 => iv_proc_date
                   );
--
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    --バックアップ件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_cnt_msg
                    ,iv_token_name1  => cv_token_cnt_table
                    ,iv_token_value1 => cv_table_cnt_xcs
                    ,iv_token_name2  => cv_token_cnt_shori
                    ,iv_token_value2 => cv_shori_cnt_arc
                    ,iv_token_name3  => cv_token_cnt
                    ,iv_token_value3 => TO_CHAR(gn_arc_cnt_carrier)
                   );
--
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    --正常件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_cnt_msg
                    ,iv_token_name1  => cv_token_cnt_table
                    ,iv_token_value1 => cv_table_cnt_xcs
                    ,iv_token_name2  => cv_token_cnt_shori
                    ,iv_token_value2 => cv_shori_cnt_normal
                    ,iv_token_name3  => cv_token_cnt
                    ,iv_token_value3 => TO_CHAR(gn_arc_cnt_carrier)
                   );
--
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    --エラー出力
    IF (lv_retcode = cv_status_error) THEN
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg --ユーザー・エラーメッセージ
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errbuf --エラーメッセージ
      );
    END IF;
    --
    --ステータスセット
    retcode := lv_retcode;
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
END XXCMN960009C;
/
