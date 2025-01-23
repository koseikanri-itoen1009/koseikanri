create or replace PACKAGE BODY APPS.XXSCP001A02C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2024. All rights reserved.
 *
 * Package Name     : XXSCP001A02C(body)
 * Description      : 転送オーダーメジャー生産計画FBDI連携
 *                    移動予定数量をCSV出力する。
 * Version          : 1.0
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
 *  2024/12/13     1.0  SCSK M.Sato      [E_本稼動_20298]新規作成
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
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name      CONSTANT VARCHAR2(100) := 'XXSCP001A02C'; -- パッケージ名
--
  --プロファイル
  cv_file_name_enter    CONSTANT VARCHAR2(50)  := 'XXSCP1_FILE_NAME_TRANSFER_ORDER';    -- XXSCP:転送オーダーファイル名称
  cv_file_dir_enter     CONSTANT VARCHAR2(100) := 'XXSCP1_FILE_DIR_SUPPLY_PLANNING';    -- XXSCP:生産計画ファイル格納パス
  cv_scaling_number     CONSTANT VARCHAR2(50)  := 'XXSCP1_SCALING_NUMBER';              -- XXSCP:スケール値
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gd_process_date       DATE;             -- 業務日付
  gv_file_name_enter    VARCHAR2(100) ;   -- XXSCP:転送オーダーファイル名称
  gv_file_dir_enter     VARCHAR2(500) ;   -- XXSCP:転送オーダーファイル格納パス
  gn_scaling_number     NUMBER  ;         -- XXSCP:スケール値
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf       OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode      OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg       OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
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
    cv_open_mode_w      CONSTANT VARCHAR2(10) := 'w';     -- ファイルオープンモード（上書き）
--
    -- *** ローカル変数 ***
--
    -- 変数型の宣言
    ln_transaction_count           NUMBER; 
    ln_transaction_value           NUMBER(10,3);
    ln_transaction_version         NUMBER;
    lv_no_data_flg                 VARCHAR2(1);
    lv_csv_text_h                  VARCHAR2(3000);
    lv_csv_text_l                  VARCHAR2(3000);
    lf_file_hand                   UTL_FILE.FILE_TYPE ;  -- ファイル・ハンドルの宣言
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    -- 品目倉庫マスタ出庫元組織取得用カーソル
    CURSOR warehouse_mst_from_cur
      IS
        SELECT DISTINCT
              xwmf.item_code       item_code     -- 品目コード
             ,xwmf.rep_org_code    rep_org_code  -- 代表組織FROM
        FROM  xxscp_warehouse_mst xwmf
        WHERE xwmf.rep_org_code <> 'DUMMY'
        ORDER BY xwmf.item_code     -- 品目コード
                ,xwmf.rep_org_code  -- 代表組織
        ;
--
    -- レコード型の宣言
    TYPE warehouse_mst_from_rec IS RECORD (
     item_code    VARCHAR2(7)         -- 品目コード
    ,rep_org_code VARCHAR2(13)        -- 代表組織コード
    );
    warehouse_mst_from_record warehouse_mst_from_rec; 
--
    -- 品目倉庫マスタ入庫先組織取得用カーソル
    CURSOR warehouse_mst_to_cur
      IS
        SELECT DISTINCT
              xwmt.rep_org_code    rep_org_code  -- 代表組織TO
        FROM  xxscp_warehouse_mst xwmt
        WHERE xwmt.rep_org_code <> 'DUMMY'
        AND   xwmt.item_code     = warehouse_mst_from_record.item_code
        ORDER BY xwmt.rep_org_code  -- 代表組織TO
        ;
--
    -- レコード型の宣言
    TYPE warehouse_mst_to_rec IS RECORD (
     rep_org_code VARCHAR2(13)        -- 代表組織コード
    );
    warehouse_mst_to_record warehouse_mst_to_rec; 
--
    -- CSV出力用カーソル
    CURSOR history_transfer_order_cur
      IS
        SELECT xhto.sr_instance_code        sr_instance_code       -- ソース・システム・コード(固定値「KI」)
              ,xhto.organization_code       organization_code      -- 代表組織コード(TO)
              ,xhto.from_organization_code  from_organization_code -- 代表組織コード(FROM)
              ,xhto.order_type              order_type             -- 固定値「94」
              ,xhto.new_order_quantity      new_order_quantity     -- エリア間移動数量
              ,xhto.to_line_number          to_line_number         -- 品目コード1
              ,xhto.item_name               item_name              -- 品目コード2
              ,xhto.order_number            order_number           -- YYYYMMDD_代表組織FROM_代表組織TO
              ,xhto.firm_planned_type       firm_planned_type      -- 固定値「Yes」
              ,xhto.need_by_date            need_by_date           -- 移動日予実
              ,xhto.deleted_flag            deleted_flag           -- 削除フラグ
              ,xhto.end_value               end_value              -- 終端記号
        FROM   xxscp_his_transfer_order     xhto
        WHERE  xhto.version = ln_transaction_version
        ORDER BY xhto.to_line_number
                ,xhto.from_organization_code
                ,xhto.organization_code
                ,xhto.need_by_date
        ;
--
    -- レコード型の宣言
    TYPE history_transfer_order_rec IS RECORD (
     sr_instance_code         VARCHAR2(30)     -- ソース・システム・コード
    ,organization_code        VARCHAR2(13)     -- 代表組織コード(TO)
    ,from_organization_code   VARCHAR2(13)     -- 代表組織コード(FROM)
    ,order_type               NUMBER           -- 固定値「94」
    ,new_order_quantity       NUMBER(10,3)     -- エリア間移動数量
    ,to_line_number           VARCHAR2(20)     -- 品目コード1
    ,item_name                VARCHAR2(250)    -- 品目コード2
    ,order_number             VARCHAR2(240)    -- YYYYMMDD_代表組織FROM_代表組織TO
    ,firm_planned_type        VARCHAR2(3)      -- 固定値「Yes」
    ,need_by_date             DATE             -- 移動日予実
    ,deleted_flag             VARCHAR2(30)     -- 削除フラグ
    ,end_value                VARCHAR2(3)      -- 終端記号
    );
    history_transfer_order_record history_transfer_order_rec; 
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
    -- 処理部
    -- ===============================
--
    -- グローバル変数の初期化
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    gn_warn_cnt   := 0;
--
    --==============================================================
    -- 業務日付取得
    --==============================================================
    gd_process_date := xxccp_common_pkg2.get_process_date;
    IF ( gd_process_date IS NULL ) THEN
      lv_errmsg := '業務日付の取得に失敗しました。';
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF
    ;
--
    --==============================================================
    -- プロファイル取得
    --==============================================================
    -- XXSCP:生産計画ファイル格納パスの取得
    gv_file_dir_enter := FND_PROFILE.VALUE(cv_file_dir_enter);
    IF (gv_file_dir_enter IS NULL) THEN
      lv_errmsg := 'XXSCP:生産計画ファイル格納パスの取得に失敗しました。';
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- XXSCP:転送オーダーファイル名称の取得
    gv_file_name_enter      := FND_PROFILE.VALUE(cv_file_name_enter);
    IF (gv_file_name_enter IS NULL) THEN
      lv_errmsg := 'XXSCP:転送オーダーファイル名称の取得に失敗しました。';
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- XXSCP:スケール値の取得
    gn_scaling_number       := TO_NUMBER(FND_PROFILE.VALUE(cv_scaling_number));
    IF (gn_scaling_number  IS NULL) THEN
      lv_errmsg := 'XXSCP:スケール値の取得に失敗しました。';
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- 最新バージョンの取得
    SELECT xxscp_transfer_order_ver_s1.NEXTVAL
    INTO   ln_transaction_version
    FROM   dual
    ;
--
    -- カーソルのオープン
    OPEN warehouse_mst_from_cur;
    -- 取得分ループ①開始
    LOOP FETCH warehouse_mst_from_cur INTO warehouse_mst_from_record;
    EXIT WHEN warehouse_mst_from_cur%NOTFOUND;
--
       -- カーソルのオープン
      OPEN warehouse_mst_to_cur;
      -- 取得分ループ②開始
      LOOP FETCH warehouse_mst_to_cur INTO warehouse_mst_to_record;
      EXIT WHEN warehouse_mst_to_cur%NOTFOUND;
--
        -- 同エリア間の移動の場合はスキップ
        IF (warehouse_mst_from_record.rep_org_code = warehouse_mst_to_record.rep_org_code) THEN
          CONTINUE;
        END IF;
        -- 日付ループ開始
        FOR ln_day_offset IN 0..6 LOOP
--
          -- 初期化
          lv_no_data_flg := 'N';
--
          BEGIN
          -- 転送オーダーのトランザクションを取得
          SELECT SUM(v1.case_num/v1.CASE_UOM)/gn_scaling_number                      AS CASE_NUM_TOTAL
          INTO   ln_transaction_value
          FROM
              (-- xmrih.status = '03''04''05''06'をそれぞれ取得し結合
               -- xmrih.status = '03'開始
               SELECT xmril.item_code               AS ITEM_CODE
                     ,xmrih.schedule_arrival_date   AS WAREHOUSING_DATE
                     ,xwm1.rep_org_code             AS REP_ORG_FROM
                     ,xwm2.rep_org_code             AS REP_ORG_TO
                     ,xmril.instruct_qty            AS CASE_NUM
                     ,iimb.attribute11              AS CASE_UOM
               FROM   xxinv_mov_req_instr_headers  xmrih
                     ,xxinv_mov_req_instr_lines    xmril
                     ,ic_item_mst_b                iimb
                     ,xxcmn_item_locations_v       xilv1
                     ,xxcmn_item_locations_v       xilv2
                     ,xxscp_warehouse_mst          xwm1
                     ,xxscp_warehouse_mst          xwm2
               WHERE  xmril.mov_hdr_id                    = xmrih.mov_hdr_id
               AND    xmril.item_code                     = iimb.item_no
               AND    xmrih.shipped_locat_id              = xilv1.inventory_location_id
               AND    xmrih.ship_to_locat_id              = xilv2.inventory_location_id
               AND    xmrih.status                        = '03'                         -- 03調整中
               AND    xmrih.comp_actual_flg               = 'N'                          -- 実績計上済フラグ
               AND    xmrih.schedule_arrival_date         = gd_process_date + ln_day_offset
               AND    xilv1.description            NOT LIKE '取置%'
               AND    xilv2.description            NOT LIKE '取置%'
               AND    xmrih.shipped_locat_code            = xwm1.whse_code
               AND    xmril.item_code                     = xwm1.item_code
               AND    xmrih.ship_to_locat_code            = xwm2.whse_code
               AND    xmril.item_code                     = xwm2.item_code
               AND    NVL( xmril.delete_flg, 'N' )       <> 'Y'
               -- ループ条件
               AND    xwm1.item_code                      = warehouse_mst_from_record.item_code
               AND    xwm1.rep_org_code                   = warehouse_mst_from_record.rep_org_code
               AND    xwm2.rep_org_code                   = warehouse_mst_to_record.rep_org_code
               -- xmrih.status = '03'終了
               UNION ALL
               -- xmrih.status = '04'開始
               SELECT xmril.item_code               AS ITEM_CODE
                     ,xmrih.schedule_arrival_date   AS WAREHOUSING_DATE
                     ,xwm1.rep_org_code             AS REP_ORG_FROM
                     ,xwm2.rep_org_code             AS REP_ORG_TO
                     ,XMRIL.shipped_quantity        AS CASE_NUM
                     ,iimb.attribute11              AS CASE_UOM
               FROM   xxinv_mov_req_instr_headers  xmrih
                     ,xxinv_mov_req_instr_lines    xmril
                     ,ic_item_mst_b                iimb
                     ,xxcmn_item_locations_v       xilv1
                     ,xxcmn_item_locations_v       xilv2
                     ,xxscp_warehouse_mst          xwm1
                     ,xxscp_warehouse_mst          xwm2
               WHERE  xmril.mov_hdr_id                   = xmrih.mov_hdr_id
               AND    xmril.item_code                    = iimb.item_no
               AND    xmrih.shipped_locat_id             = xilv1.inventory_location_id
               AND    xmrih.ship_to_locat_id             = xilv2.inventory_location_id
               AND    xmrih.status                       = '04'                              -- 04出庫報告済
               AND    xmrih.comp_actual_flg              = 'N'                               -- 実績計上済フラグ
               AND    xmrih.schedule_arrival_date        = gd_process_date + ln_day_offset   -- 入庫日予実が当日以降
               AND    xilv1.description           NOT LIKE '取置%'
               AND    xilv2.description           NOT LIKE '取置%'
               AND    xmrih.shipped_locat_code           = xwm1.whse_code
               AND    xmril.item_code                    = xwm1.item_code
               AND    xmrih.ship_to_locat_code           = xwm2.whse_code
               AND    xmril.item_code                    = xwm2.item_code
               AND    NVL( xmril.delete_flg, 'N' )      <> 'Y'
               -- ループ条件
               AND    xwm1.item_code                     = warehouse_mst_from_record.item_code
               AND    xwm1.rep_org_code                  = warehouse_mst_from_record.rep_org_code
               AND    xwm2.rep_org_code                  = warehouse_mst_to_record.rep_org_code
               -- xmrih.status = '04'終了
               UNION ALL
               -- xmrih.status = '05'開始
               SELECT xmril.item_code               AS ITEM_CODE
                     ,xmrih.actual_arrival_date     AS WAREHOUSING_DATE
                     ,xwm1.rep_org_code             AS REP_ORG_FROM
                     ,xwm2.rep_org_code             AS REP_ORG_TO
                     ,XMRIL.ship_to_quantity        AS CASE_NUM
                     ,iimb.attribute11              AS CASE_UOM
               FROM   xxinv_mov_req_instr_headers  xmrih
                     ,xxinv_mov_req_instr_lines    xmril
                     ,ic_item_mst_b                iimb
                     ,xxcmn_item_locations_v       xilv1
                     ,xxcmn_item_locations_v       xilv2
                     ,xxscp_warehouse_mst          xwm1
                     ,xxscp_warehouse_mst          xwm2
               WHERE xmril.mov_hdr_id                    = xmrih.mov_hdr_id
               AND   xmril.item_code                     = iimb.item_no
               AND   xmrih.shipped_locat_id              = xilv1.inventory_location_id
               AND   xmrih.ship_to_locat_id              = xilv2.inventory_location_id
               AND   xmrih.status                        = '05'                              -- 05入庫報告済
               AND   xmrih.comp_actual_flg               = 'N'                               -- 実績計上済フラグ
               AND   xmrih.actual_arrival_date           = gd_process_date + ln_day_offset   -- 入庫日予実が当日以降
               AND   xilv1.description            NOT LIKE '取置%'
               AND   xilv2.description            NOT LIKE '取置%'
               AND   xmrih.shipped_locat_code            = xwm1.whse_code
               AND   xmril.item_code                     = xwm1.item_code
               AND   xmrih.ship_to_locat_code            = xwm2.whse_code
               AND   xmril.item_code                     = xwm2.item_code
               AND   NVL( xmril.delete_flg, 'N' )       <> 'Y'
               -- ループ条件
               AND   xwm1.item_code                      = warehouse_mst_from_record.item_code
               AND   xwm1.rep_org_code                   = warehouse_mst_from_record.rep_org_code
               AND   xwm2.rep_org_code                   = warehouse_mst_to_record.rep_org_code
               -- xmrih.status = '05'終了
               UNION ALL
               -- xmrih.status = '06'開始
               SELECT xmril.item_code               AS ITEM_CODE
                     ,xmrih.actual_arrival_date     AS WAREHOUSING_DATE
                     ,xwm1.rep_org_code             AS REP_ORG_FROM
                     ,xwm2.rep_org_code             AS REP_ORG_TO
                     ,XMRIL.ship_to_quantity        AS CASE_NUM
                     ,iimb.attribute11              AS CASE_UOM
               FROM   xxinv_mov_req_instr_headers   xmrih
                     ,xxinv_mov_req_instr_lines     xmril
                     ,ic_item_mst_b                 iimb
                     ,xxcmn_item_locations_v        xilv1
                     ,xxcmn_item_locations_v        xilv2
                     ,xxscp_warehouse_mst           xwm1
                     ,xxscp_warehouse_mst           xwm2
               WHERE  xmril.mov_hdr_id                    = xmrih.mov_hdr_id
               AND    xmril.item_code                     = iimb.item_no
               AND    xmrih.shipped_locat_id              = xilv1.inventory_location_id
               AND    xmrih.ship_to_locat_id              = xilv2.inventory_location_id
               AND    xmrih.status                        = '06'
               AND    xmrih.actual_arrival_date           = gd_process_date + ln_day_offset   -- 入庫日予実が当日以降
               AND    xilv1.description            NOT LIKE '取置%'
               AND    xilv2.description            NOT LIKE '取置%'
               AND    xmrih.shipped_locat_code            = xwm1.whse_code
               AND    xmril.item_code                     = xwm1.item_code
               AND    xmrih.ship_to_locat_code            = xwm2.whse_code
               AND    xmril.item_code                     = xwm2.item_code
               AND    NVL( xmril.delete_flg, 'N' )       <> 'Y'
               -- ループ条件
               AND    xwm1.item_code                      = warehouse_mst_from_record.item_code
               AND    xwm1.rep_org_code                   = warehouse_mst_from_record.rep_org_code
               AND    xwm2.rep_org_code                   = warehouse_mst_to_record.rep_org_code
                -- xmrih.status = '06'終了
              )v1
          GROUP BY
                  v1.ITEM_CODE
                 ,v1.REP_ORG_FROM
                 ,v1.REP_ORG_TO
                 ,v1.WAREHOUSING_DATE
               ;
--
          -- トランが取得できなかった場合
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              -- 履歴テーブルの件数を確認する
              SELECT COUNT(*)  transaction_count
              INTO   ln_transaction_count
              FROM   xxscp_his_transfer_order xhto
              WHERE  xhto.need_by_date                = gd_process_date + ln_day_offset -- 業務日付+0D~+6Dの日付を指定
              AND    xhto.to_line_number              = warehouse_mst_from_record.item_code
              AND    xhto.organization_code           = warehouse_mst_to_record.rep_org_code
              AND    xhto.from_organization_code      = warehouse_mst_from_record.rep_org_code
              ;
--
              -- 履歴テーブルにトランザクションが存在する場合
              IF ln_transaction_count <> 0 THEN
                -- 値を0で最新化する
                ln_transaction_value := 0;
              ELSE
                lv_no_data_flg := 'Y';
              END IF;
          -- 例外処理終了
          END;
--
          -- 履歴テーブルを更新する
          IF lv_no_data_flg = 'N' THEN
            INSERT INTO xxscp_his_transfer_order(
                           his_transfer_order_id            -- テーブルID
                          ,version                          -- バージョン
                          ,sr_instance_code                 -- ソース・システム・コード(固定値「KI」)
                          ,organization_code                -- 代表組織コード(TO)
                          ,from_organization_code           -- 代表組織コード(FROM)
                          ,order_type                       -- 固定値「94」
                          ,new_order_quantity               -- エリア間移動数量
                          ,to_line_number                   -- 品目コード1
                          ,item_name                        -- 品目コード2
                          ,order_number                     -- YYYYMMDD_代表組織FROM_代表組織TO
                          ,firm_planned_type                -- 固定値「Yes」
                          ,need_by_date                     -- 移動日予実
                          ,deleted_flag                     -- 削除フラグ
                          ,end_value                        -- 終端記号
                          ,created_by                       -- CREATED_BY
                          ,creation_date                    -- CREATION_DATE
                          ,last_updated_by                  -- LAST_UPDATED_BY
                          ,last_update_date                 -- LAST_UPDATE_DATE
                          ,last_update_login                -- LAST_UPDATE_LOGIN
                          ,request_id                       -- REQUEST_ID
                          ,program_application_id           -- PROGRAM_APPLICATION_ID
                          ,program_id                       -- PROGRAM_ID
                          ,program_update_date              -- PROGRAM_UPDATE_DATE
            )VALUES(
                           xxscp_transfer_order_id_s1.NEXTVAL
                          ,ln_transaction_version
                          ,'KI'
                          ,warehouse_mst_to_record.rep_org_code
                          ,warehouse_mst_from_record.rep_org_code
                          ,94
                          ,ln_transaction_value
                          ,warehouse_mst_from_record.item_code
                          ,warehouse_mst_from_record.item_code
                          ,to_char(gd_process_date + ln_day_offset, 'YYYYMMDD')  ||  '_'  ||  warehouse_mst_from_record.rep_org_code  ||  '_'  ||  warehouse_mst_to_record.rep_org_code
                          ,'Yes'
                          ,gd_process_date + ln_day_offset
                          ,''
                          ,'END'
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
          END IF;
--
        -- 日付ループ終了
        END LOOP;
--
     -- 取得分ループ②終了
     END LOOP;
     CLOSE warehouse_mst_to_cur;
--
    -- 取得分ループ①終了
    END LOOP;
    CLOSE warehouse_mst_from_cur;
--
    -- コミット処理
    COMMIT;
--
    -- ====================================================
    -- ＵＴＬファイルオープン
    -- ====================================================
    lf_file_hand := UTL_FILE.FOPEN(gv_file_dir_enter,
                                   gv_file_name_enter,
                                   cv_open_mode_w,
                                   32767
                                  );
--
    -- ===============================
    -- CSVヘッダ部処理
    -- ===============================
--
    -- ヘッダー部設定
    lv_csv_text_h := 'SR_INSTANCE_CODE,ORGANIZATION_CODE,FROM_ORGANIZATION_CODE,SOURCE_SUBINVENTORY_CODE,SUBINVENTORY_CODE,ORDER_TYPE,NEW_ORDER_QUANTITY,TO_LINE_NUMBER,ITEM_NAME,ORDER_NUMBER,CARRIER_NAME,MODE_OF_TRANSPORT,SERVICE_LEVEL,FIRM_PLANNED_TYPE,NEED_BY_DATE,NEW_SHIP_DATE,NEW_DOCK_DATE,REVISION,SHIP_METHOD,SHIPMENT_HEADER_NUM,SHIPMENT_LINE_NUM ,RECEIPT_NUM,EXPENSE_TRANSFER,NEW_ORDER_PLACEMENT_DATE,UOM_CODE,DELETED_FLAG,ATTRIBUTE_CHAR1,ATTRIBUTE_CHAR2,ATTRIBUTE_CHAR3,ATTRIBUTE_CHAR4,ATTRIBUTE_CHAR5,ATTRIBUTE_CHAR6,ATTRIBUTE_CHAR7,ATTRIBUTE_CHAR8,ATTRIBUTE_CHAR9,ATTRIBUTE_CHAR10,ATTRIBUTE_CHAR11,ATTRIBUTE_CHAR12,ATTRIBUTE_CHAR13,ATTRIBUTE_CHAR14,ATTRIBUTE_CHAR15,ATTRIBUTE_CHAR16,ATTRIBUTE_CHAR17,ATTRIBUTE_CHAR18,ATTRIBUTE_CHAR19,ATTRIBUTE_CHAR20,ATTRIBUTE_NUMBER1,ATTRIBUTE_NUMBER2,ATTRIBUTE_NUMBER3,ATTRIBUTE_NUMBER4,ATTRIBUTE_NUMBER5,ATTRIBUTE_NUMBER6,ATTRIBUTE_NUMBER7,ATTRIBUTE_NUMBER8,ATTRIBUTE_NUMBER9,ATTRIBUTE_NUMBER10,ATTRIBUTE_DATE1,ATTRIBUTE_DATE2,ATTRIBUTE_DATE3,ATTRIBUTE_DATE4,ATTRIBUTE_DATE5,ATTRIBUTE_DATE6,ATTRIBUTE_DATE7,ATTRIBUTE_DATE8,ATTRIBUTE_DATE9,ATTRIBUTE_DATE10,ATTRIBUTE_DATE11,ATTRIBUTE_DATE12,ATTRIBUTE_DATE13,ATTRIBUTE_DATE14,ATTRIBUTE_DATE15,ATTRIBUTE_DATE16,ATTRIBUTE_DATE17,ATTRIBUTE_DATE18,ATTRIBUTE_DATE19,ATTRIBUTE_DATE20,QTY_COMPLETED,GLOBAL_ATTRIBUTE_NUMBER11,GLOBAL_ATTRIBUTE_NUMBER12,GLOBAL_ATTRIBUTE_NUMBER13,GLOBAL_ATTRIBUTE_NUMBER14,GLOBAL_ATTRIBUTE_NUMBER15,GLOBAL_ATTRIBUTE_NUMBER16,GLOBAL_ATTRIBUTE_NUMBER17,GLOBAL_ATTRIBUTE_NUMBER18,GLOBAL_ATTRIBUTE_NUMBER19,GLOBAL_ATTRIBUTE_NUMBER20,GLOBAL_ATTRIBUTE_NUMBER21,GLOBAL_ATTRIBUTE_NUMBER22,GLOBAL_ATTRIBUTE_NUMBER23,GLOBAL_ATTRIBUTE_NUMBER24,GLOBAL_ATTRIBUTE_NUMBER25,FULFILL_ORCHESTRATION_REQUIRED,GLOBAL_ATTRIBUTE_CHAR21,GLOBAL_ATTRIBUTE_CHAR22,GLOBAL_ATTRIBUTE_CHAR23,MATURITY_DATE,END';
--
    -- ヘッダー部設定ログ出力
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_csv_text_h
    );
--
    -- ====================================================
    -- ヘッダー部CSV出力
    -- ====================================================
    UTL_FILE.PUT_LINE( lf_file_hand, lv_csv_text_h ) ;
--
    -- ===============================
    -- CSV明細部処理
    -- ===============================
--
    -- カーソルのオープン
    OPEN history_transfer_order_cur;
--
    -- データ部出力
    LOOP
      FETCH history_transfer_order_cur INTO history_transfer_order_record;
      EXIT WHEN history_transfer_order_cur%NOTFOUND;
--
      --件数セット
      gn_target_cnt := gn_target_cnt + 1;
--
      -- 明細部設定
      lv_csv_text_l :=    history_transfer_order_record.sr_instance_code                              || ','
                       || history_transfer_order_record.organization_code                             || ','
                       || history_transfer_order_record.from_organization_code                        || ','
                       || ''                                                                          || ','
                       || ''                                                                          || ','
                       || history_transfer_order_record.order_type                                    || ','
                       || RTRIM(TO_CHAR(history_transfer_order_record.new_order_quantity, 'FM9999990.999'), '.')  || ','
                       || history_transfer_order_record.to_line_number                                || ','
                       || history_transfer_order_record.item_name                                     || ','
                       || history_transfer_order_record.order_number                                  || ','
                       || ''                                                                          || ','
                       || ''                                                                          || ','
                       || ''                                                                          || ','
                       || history_transfer_order_record.firm_planned_type                             || ','
                       || TO_CHAR(history_transfer_order_record.need_by_date,'YYYY/MM/DD')            || ','
                       || ''                                                                          || ','
                       || ''                                                                          || ','
                       || ''                                                                          || ','
                       || ''                                                                          || ','
                       || ''                                                                          || ','
                       || ''                                                                          || ','
                       || ''                                                                          || ','
                       || ''                                                                          || ','
                       || ''                                                                          || ','
                       || ''                                                                          || ','
                       || history_transfer_order_record.deleted_flag                                  || ','
                       || ''                                                                          || ','
                       || ''                                                                          || ','
                       || ''                                                                          || ','
                       || ''                                                                          || ','
                       || ''                                                                          || ','
                       || ''                                                                          || ','
                       || ''                                                                          || ','
                       || ''                                                                          || ','
                       || ''                                                                          || ','
                       || ''                                                                          || ','
                       || ''                                                                          || ','
                       || ''                                                                          || ','
                       || ''                                                                          || ','
                       || ''                                                                          || ','
                       || ''                                                                          || ','
                       || ''                                                                          || ','
                       || ''                                                                          || ','
                       || ''                                                                          || ','
                       || ''                                                                          || ','
                       || ''                                                                          || ','
                       || ''                                                                          || ','
                       || ''                                                                          || ','
                       || ''                                                                          || ','
                       || ''                                                                          || ','
                       || ''                                                                          || ','
                       || ''                                                                          || ','
                       || ''                                                                          || ','
                       || ''                                                                          || ','
                       || ''                                                                          || ','
                       || ''                                                                          || ','
                       || ''                                                                          || ','
                       || ''                                                                          || ','
                       || ''                                                                          || ','
                       || ''                                                                          || ','
                       || ''                                                                          || ','
                       || ''                                                                          || ','
                       || ''                                                                          || ','
                       || ''                                                                          || ','
                       || ''                                                                          || ','
                       || ''                                                                          || ','
                       || ''                                                                          || ','
                       || ''                                                                          || ','
                       || ''                                                                          || ','
                       || ''                                                                          || ','
                       || ''                                                                          || ','
                       || ''                                                                          || ','
                       || ''                                                                          || ','
                       || ''                                                                          || ','
                       || ''                                                                          || ','
                       || ''                                                                          || ','
                       || ''                                                                          || ','
                       || ''                                                                          || ','
                       || ''                                                                          || ','
                       || ''                                                                          || ','
                       || ''                                                                          || ','
                       || ''                                                                          || ','
                       || ''                                                                          || ','
                       || ''                                                                          || ','
                       || ''                                                                          || ','
                       || ''                                                                          || ','
                       || ''                                                                          || ','
                       || ''                                                                          || ','
                       || ''                                                                          || ','
                       || ''                                                                          || ','
                       || ''                                                                          || ','
                       || ''                                                                          || ','
                       || ''                                                                          || ','
                       || ''                                                                          || ','
                       || ''                                                                          || ','
                       || ''                                                                          || ','
                       || ''                                                                          || ','
                       || history_transfer_order_record.end_value
                       ;
--
      -- 明細部設定ログ出力
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_csv_text_l)
      ;
--
      -- ====================================================
      -- 明細部CSV出力
      -- ====================================================
      UTL_FILE.PUT_LINE( lf_file_hand, lv_csv_text_l ) ;
--
    END LOOP;
    CLOSE history_transfer_order_cur;
--
    -- ====================================================
    -- ＵＴＬファイルクローズ
    -- ====================================================
    UTL_FILE.FCLOSE( lf_file_hand );
--
    -- 成功件数＝対象件数
    gn_normal_cnt  := gn_target_cnt;
--
    -- 対象件数=0であれば警告
    IF (gn_target_cnt = 0) THEN
      ov_retcode     := cv_status_warn;
    END IF;
--
  EXCEPTION
      -- *** 任意で例外処理を記述する ****
      -- カーソルのクローズをここに記述する
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
      IF UTL_FILE.IS_OPEN  ( lf_file_hand ) THEN
         UTL_FILE.FCLOSE   ( lf_file_hand );
      END IF;
--
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
    ov_errbuf       OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode      OUT VARCHAR2      --   リターン・コード             --# 固定 #
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
  BEGIN
--
--###########################  固定部 START   #####################################################
--
    -- 固定出力
    -- コンカレントヘッダメッセージ出力関数の呼び出し
    xxccp_common_pkg.put_log_header(
       iv_which   => 'LOG'
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
       lv_errbuf   -- エラー・メッセージ           --# 固定 #
      ,lv_retcode  -- リターン・コード             --# 固定 #
      ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    --エラー出力
    IF (lv_retcode = cv_status_error) THEN
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errmsg --ユーザー・エラーメッセージ
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --エラーメッセージ
      );
      gn_error_cnt := 1;
    END IF;
    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
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
       which  => FND_FILE.LOG
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
       which  => FND_FILE.LOG
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
       which  => FND_FILE.LOG
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
       which  => FND_FILE.LOG
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
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --終了ステータスがエラーの場合はROLLBACKする
    IF (lv_retcode = cv_status_error) THEN
      ROLLBACK;
    END IF;
--
    --ステータスセット
    ov_retcode := lv_retcode;
--
  EXCEPTION
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      lv_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      lv_retcode := cv_status_error;
      ROLLBACK;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      lv_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      lv_retcode := cv_status_error;
      ROLLBACK;
  END main;
--
--###########################  固定部 END   #######################################################
--
END XXSCP001A02C;
/