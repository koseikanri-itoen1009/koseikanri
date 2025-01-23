create or replace PACKAGE BODY APPS.XXSCP001A01C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2024. All rights reserved.
 *
 * Package Name     : XXSCP001A01C(body)
 * Description      : 販売オーダーメジャー生産計画FBDI連携
 *                    出荷予定数量をCSV出力する。
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
 *  2024/12/05     1.0  SCSK M.Sato      [E_本稼動_20298]新規作成
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
  cv_pkg_name      CONSTANT VARCHAR2(100) := 'XXSCP001A01C'; -- パッケージ名
--
  --プロファイル
  cv_file_name_enter    CONSTANT VARCHAR2(30) := 'XXSCP1_FILE_NAME_SALES_ORDER';     -- XXSCP:販売オーダーファイル名称
  cv_file_dir_enter     CONSTANT VARCHAR2(100) := 'XXSCP1_FILE_DIR_SUPPLY_PLANNING';  -- XXSCP:生産計画ファイル格納パス
  cv_scaling_number     CONSTANT VARCHAR2(50)  := 'XXSCP1_SCALING_NUMBER';            -- XXSCP:スケール値
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gd_process_date       DATE;             -- 業務日付
  gv_file_name_enter    VARCHAR2(100) ;   -- XXSCP:販売オーダーファイル名称
  gv_file_dir_enter     VARCHAR2(500) ;   -- XXSCP:販売オーダーファイル格納パス
  gn_scaling_number     NUMBER  ;         -- XXSCP:スケール値
--
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
    ln_transaction_value           NUMBER;
    ln_transaction_version         NUMBER;
    lv_no_data_flg                 VARCHAR2(1);
    lv_csv_text_h                  VARCHAR2(3000);
    lv_csv_text_l                  VARCHAR2(3000);
    lf_file_hand                   UTL_FILE.FILE_TYPE ;  -- ファイル・ハンドルの宣言
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    -- 品目倉庫マスタ取得用カーソル
    CURSOR warehouse_mst_cur
      IS
        SELECT DISTINCT
              xwm.item_code       item_code     -- 品目コード
             ,xwm.rep_org_code    rep_org_code  -- 代表組織
        FROM  xxscp_warehouse_mst xwm
        WHERE xwm.rep_org_code <> 'DUMMY'
        ORDER BY xwm.item_code     -- 品目コード
                ,xwm.rep_org_code  -- 代表組織
        ;
--
    -- レコード型の宣言
    TYPE warehouse_mst_rec IS RECORD (
     item_code    VARCHAR2(7)         -- 品目コード
    ,rep_org_code VARCHAR2(13)        -- 代表組織コード
    );
    warehouse_mst_record warehouse_mst_rec; 
--
    -- CSV出力用カーソル
    CURSOR history_sales_order_cur
      IS
        SELECT xhso1.sr_instance_code            sr_instance_code            -- 
              ,xhso1.item_name                   item_name                   -- 
              ,xhso1.organization_code           organization_code           -- 
              ,xhso1.using_requirement_quantity  using_requirement_quantity  -- 
              ,xhso1.sales_order_number          sales_order_number          -- 
              ,xhso1.so_line_num                 so_line_num                 -- 
              ,xhso1.using_assembly_demand_date  using_assembly_demand_date  -- 
              ,xhso1.customer_name               customer_name               -- 
              ,xhso1.ship_to_site_code           ship_to_site_code           -- 
              ,xhso1.ordered_uom                 ordered_uom                 -- 
              ,xhso1.deleted_flag                deleted_flag                -- 
              ,xhso1.end_value                   end_value                   -- 
        FROM   xxscp_his_sales_order xhso1
        WHERE  xhso1.version = ln_transaction_version
        ORDER BY xhso1.item_name
                ,xhso1.organization_code
                ,xhso1.using_assembly_demand_date
        ;
--
    -- レコード型の宣言
    TYPE history_sales_order_rec IS RECORD (
     sr_instance_code             VARCHAR2(30)     -- ソース・システム・コード
    ,item_name                    VARCHAR2(250)    -- 品目コード
    ,organization_code            VARCHAR2(13)     -- 代表組織コード
    ,using_requirement_quantity   NUMBER           -- 出荷数量
    ,sales_order_number           VARCHAR2(250)    -- YYYYMMDD_代表組織
    ,so_line_num                  VARCHAR2(150)    -- 品目コード
    ,using_assembly_demand_date   DATE             -- 出荷日予実
    ,customer_name                VARCHAR2(255)    -- 固定値「C」
    ,ship_to_site_code            VARCHAR2(255)    -- 固定値「KI_S」
    ,ordered_uom                  VARCHAR2(30)     -- 単位(固定値「CS」)
    ,deleted_flag                 VARCHAR2(30)     -- 削除フラグ
    ,end_value                    VARCHAR2(3)      -- 終端記号
    );
    history_sales_order_record history_sales_order_rec; 
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
    -- XXSCP:販売オーダーファイル名称の取得
    gv_file_name_enter      := FND_PROFILE.VALUE(cv_file_name_enter);
    IF (gv_file_name_enter IS NULL) THEN
      lv_errmsg := 'XXSCP:販売オーダーファイル名称の取得に失敗しました。';
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
    SELECT xxscp_sales_order_ver_s1.NEXTVAL
    INTO   ln_transaction_version
    FROM   dual
    ;
--
    -- カーソルのオープン
    OPEN warehouse_mst_cur;
    -- 取得分ループ①開始
    LOOP FETCH warehouse_mst_cur INTO warehouse_mst_record;
    EXIT WHEN warehouse_mst_cur%NOTFOUND;
--
      -- 日付ループ②開始
      FOR ln_day_offset IN 0..6 LOOP
--
        -- 初期化
        lv_no_data_flg := 'N';
--
        BEGIN
        -- 販売オーダーのトランザクションを取得
          SELECT
                SUM(v1.case_num / v1.uom_case)/gn_scaling_number                 AS case_num_total
          INTO  ln_transaction_value
          FROM (-- xoha.req_status = '04'と'03'をそれぞれ取得し結合
                -- xoha.req_status = '04'開始
                SELECT xola.shipping_item_code                                   AS item_code
                      ,xwm.rep_org_code                                          AS rep_org_code
                      ,NVL(xola.shipped_quantity, 0)                             AS case_num
                      ,iimb.attribute11                                          AS uom_case
                FROM   xxwsh_order_headers_all   xoha   -- 受注ヘッダアドオン
                      ,xxwsh_order_lines_all     xola   -- 受注明細アドオン
                      ,oe_transaction_types_all  otta   -- トランザクションタイプ取得用
                      ,ic_item_mst_b             iimb   -- OPM品目マスタ
                      ,xxscp_warehouse_mst       xwm    -- 品目倉庫マスタ
                WHERE  xoha.order_header_id                                = xola.order_header_id
                AND    xoha.order_type_id                                  = otta.transaction_type_id
                AND    otta.attribute1                                     = '1'                             -- トランザクションタイプ 1:出荷
                AND    xoha.req_status                                     = '04'                            -- 03:締め済み,04:出荷実績計上済
                AND    xoha.arrival_date                                   = gd_process_date + ln_day_offset -- 業務日付+0D~+6Dの日付を指定
                AND    xola.shipping_item_code                             = iimb.item_no
                AND    xoha.deliver_from                                   = xwm.whse_code
                AND    xola.shipping_item_code                             = xwm.item_code
                AND    xoha.latest_external_flag                           = 'Y'
                AND    xola.delete_flag                                    = 'N'                             -- 無効明細以外
                -- ループ条件
                AND    xwm.item_code                                       = warehouse_mst_record.item_code
                AND    xwm.rep_org_code                                    = warehouse_mst_record.rep_org_code
                -- xoha.req_status = '04'終了
                UNION ALL
                -- xoha.req_status = '03'開始
                SELECT xola.shipping_item_code                                   AS item_code
                      ,xwm.rep_org_code                                          AS rep_org_code
                      ,NVL(xola.quantity, 0)                                     AS case_num
                      ,iimb.attribute11                                          AS uom_case
                FROM   xxwsh_order_headers_all   xoha   -- 受注ヘッダアドオン
                      ,xxwsh_order_lines_all     xola   -- 受注明細アドオン
                      ,oe_transaction_types_all  otta   -- トランザクションタイプ取得用
                      ,ic_item_mst_b             iimb   -- OPM品目マスタ
                      ,xxscp_warehouse_mst       xwm    -- 品目倉庫マスタ
                WHERE  xoha.order_header_id                                = xola.order_header_id
                AND    xoha.order_type_id                                  = otta.transaction_type_id
                AND    otta.attribute1                                     = '1'                             -- トランザクションタイプ 1:出荷
                AND    xoha.req_status                                     = '03'                            -- 03:締め済み,04:出荷実績計上済
                AND    xoha.schedule_arrival_date                          = gd_process_date + ln_day_offset -- 業務日付+0D~+6Dの日付を指定
                AND    xola.shipping_item_code                             = iimb.item_no
                AND    xoha.deliver_from                                   = xwm.whse_code
                AND    xola.shipping_item_code                             = xwm.item_code
                AND    xoha.latest_external_flag                           = 'Y'
                AND    xola.delete_flag                                    = 'N'                             -- 無効明細以外
                -- ループ条件
                AND    xwm.item_code                                       = warehouse_mst_record.item_code
                AND    xwm.rep_org_code                                    = warehouse_mst_record.rep_org_code
                -- xoha.req_status = '03'終了
                )v1
           GROUP BY v1.item_code,
                    v1.rep_org_code
           ;
--
        -- トランが取得できなかった場合
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            -- 履歴テーブルの件数を確認する
            SELECT COUNT(*)  transaction_count
            INTO   ln_transaction_count
            FROM   xxscp_his_sales_order xhso
            WHERE  xhso.using_assembly_demand_date  = gd_process_date + ln_day_offset -- 業務日付+0D~+6Dの日付を指定
            AND    xhso.item_name                   = warehouse_mst_record.item_code
            AND    xhso.organization_code           = warehouse_mst_record.rep_org_code
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
          INSERT INTO xxscp_his_sales_order(
                         his_sales_order_id               -- テーブルID
                        ,version                          -- バージョン
                        ,sr_instance_code                 -- ソース・システム・コード(固定値「KI」)
                        ,item_name                        -- 品目コード1
                        ,organization_code                -- 代表組織
                        ,using_requirement_quantity       -- 出荷数量
                        ,sales_order_number               -- YYYYMMDD_代表組織
                        ,so_line_num                      -- 品目コード2
                        ,using_assembly_demand_date       -- 着荷日_予実
                        ,customer_name                    -- 固定値「C」
                        ,ship_to_site_code                -- 固定値「KI_S」
                        ,ordered_uom                      -- 単位(固定値「CS」)
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
                         xxscp_sales_order_id_s1.NEXTVAL                                                                             -- テーブルID
                        ,ln_transaction_version                                                                                      -- バージョン
                        ,'KI'                                                                                                        -- ソース・システム・コード(固定値「KI」)
                        ,warehouse_mst_record.item_code                                                                              -- 品目コード1
                        ,warehouse_mst_record.rep_org_code                                                                           -- 代表組織
                        ,ln_transaction_value                                                                                        -- 出荷数量
                        ,to_char(gd_process_date + ln_day_offset, 'YYYYMMDD')  ||  '_'  ||  warehouse_mst_record.rep_org_code        -- YYYYMMDD_代表組織
                        ,warehouse_mst_record.item_code                                                                              -- 品目コード2
                        ,gd_process_date + ln_day_offset                                                                             -- 着荷日_予実
                        ,'C'                                                                                                         -- 固定値「C」
                        ,'KI_S'                                                                                                      -- 固定値「KI_S」
                        ,'CS'                                                                                                        -- 単位(固定値「CS」)
                        ,''                                                                                                          -- 削除フラグ
                        ,'END'                                                                                                       -- 終端記号
                        ,cn_created_by                                                                                               -- CREATED_BY
                        ,cd_creation_date                                                                                            -- CREATION_DATE
                        ,cn_last_updated_by                                                                                          -- LAST_UPDATED_BY
                        ,cd_last_update_date                                                                                         -- LAST_UPDATE_DATE
                        ,cn_last_update_login                                                                                        -- LAST_UPDATE_LOGIN
                        ,cn_request_id                                                                                               -- REQUEST_ID
                        ,cn_program_application_id                                                                                   -- PROGRAM_APPLICATION_ID
                        ,cn_program_id                                                                                               -- PROGRAM_ID
                        ,cd_program_update_date                                                                                      -- PROGRAM_UPDATE_DATE
          );
        END IF;
--
      -- 日付ループ②終了
      END LOOP;
    -- 取得分ループ①終了
    END LOOP;
    -- コミット処理
    COMMIT;
--
    CLOSE warehouse_mst_cur;
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
    lv_csv_text_h := 'SR_INSTANCE_CODE,ITEM_NAME,ORIGINAL_ITEM_NAME,ORGANIZATION_CODE,RECEIVING_ORG_CODE,USING_REQUIREMENT_QUANTITY,COMPLETED_QUANTITY,'    ||
                     'SALES_ORDER_NUMBER,SO_LINE_NUM,USING_ASSEMBLY_DEMAND_DATE,SCHEDULE_ARRIVAL_DATE,REQUEST_DATE,PROMISE_SHIP_DATE,PROMISE_ARRIVAL_DATE,' ||
                     'LATEST_ACCEPTABLE_SHIP_DATE,LATEST_ACCEPTABLE_ARRIVAL_DATE,EARLIEST_ACCEPT_SHIP_DATE,EARLIEST_ACCEPT_ARRIVAL_DATE,'                   ||
                     'ORDER_DATE_TYPE_CODE,SHIPPING_METHOD_CODE,CARRIER_NAME,SERVICE_LEVEL,MODE_OF_TRANSPORT,CUSTOMER_NAME,SHIP_TO_SITE_CODE,'              ||
                     'BILL_TO_SITE_CODE,SHIP_SET_NAME,ARRIVAL_SET_NAME,DEMAND_PRIORITY,DEMAND_CLASS,ORDERED_UOM,SUPPLIER_NAME,SUPPLIER_SITE_CODE,'          ||
                     'DEMAND_SOURCE_TYPE,SHIPPING_PREFERENCE,ROOT_FULFILLMENT_LINE,PARENT_FULFILLMENT_LINE,CONFIGURED_ITEM_NAME,INCLUDED_ITEMS_FLAG,'       ||
                     'SELLING_PRICE,SALESREP_CONTACT,CUSTOMER_PO_NUMBER,CUSTOMER_PO_LINE_NUMBER,MIN_REM_SHELF_LIFE_DAYS,ALLOW_SPLITS,ALLOW_SUBSTITUTION,'   ||
                     'FULFILLMENT_COST,SOURCE_SCHEDULE_NUMBER,ORDERED_DATE,ITEM_TYPE_CODE,ITEM_SUB_TYPE_CODE,ORDER_MARGIN,PROMISING_SYSTEM,DELIVERY_COST,'  ||
                     'DELIVERY_LEAD_TIME,MIN_PERCENTAGE_FOR_SPLIT,MIN_QUANTITY_FOR_SPLIT,SUPPLIER_SITE_SOURCE_SYSTEM,DROPSHIP_PO_NUMBER,'                   ||
                     'DROPSHIP_PO_LINE_NUM,DROPSHIP_PO_SCHEDULE_LINE_NUM,PO_DELETED_FLAG,CUSTOMER_PO_SCHEDULE_NUMBER,DELETED_FLAG,ATTRIBUTE_CHAR1,'         ||
                     'ATTRIBUTE_CHAR2,ATTRIBUTE_CHAR3,ATTRIBUTE_CHAR4,ATTRIBUTE_CHAR5,ATTRIBUTE_CHAR6,ATTRIBUTE_CHAR7,ATTRIBUTE_CHAR8,ATTRIBUTE_CHAR9,'     ||
                     'ATTRIBUTE_CHAR10,ATTRIBUTE_CHAR11,ATTRIBUTE_CHAR12,ATTRIBUTE_CHAR13,ATTRIBUTE_CHAR14,ATTRIBUTE_CHAR15,ATTRIBUTE_CHAR16,'              ||
                     'ATTRIBUTE_CHAR17,ATTRIBUTE_CHAR18,ATTRIBUTE_CHAR19,ATTRIBUTE_CHAR20,ATTRIBUTE_NUMBER1,ATTRIBUTE_NUMBER2,ATTRIBUTE_NUMBER3,'           ||
                     'ATTRIBUTE_NUMBER4,ATTRIBUTE_NUMBER5,ATTRIBUTE_NUMBER6,ATTRIBUTE_NUMBER7,ATTRIBUTE_NUMBER8,ATTRIBUTE_NUMBER9,ATTRIBUTE_NUMBER10,'      ||
                     'ATTRIBUTE_DATE1,ATTRIBUTE_DATE2,ATTRIBUTE_DATE3,ATTRIBUTE_DATE4,ATTRIBUTE_DATE5,ATTRIBUTE_DATE6,ATTRIBUTE_DATE7,ATTRIBUTE_DATE8,'     ||
                     'ATTRIBUTE_DATE9,ATTRIBUTE_DATE10,ATTRIBUTE_DATE11,ATTRIBUTE_DATE12,ATTRIBUTE_DATE13,ATTRIBUTE_DATE14,ATTRIBUTE_DATE15,'               ||
                     'ATTRIBUTE_DATE16,ATTRIBUTE_DATE17,ATTRIBUTE_DATE18,ATTRIBUTE_DATE19,ATTRIBUTE_DATE20,INQUIRY_DEMAND,GLOBAL_ATTRIBUTE_NUMBER11,'       ||
                     'GLOBAL_ATTRIBUTE_NUMBER12,GLOBAL_ATTRIBUTE_NUMBER13,GLOBAL_ATTRIBUTE_NUMBER14,GLOBAL_ATTRIBUTE_NUMBER15,GLOBAL_ATTRIBUTE_NUMBER16,'   ||
                     'GLOBAL_ATTRIBUTE_NUMBER17,GLOBAL_ATTRIBUTE_NUMBER18,GLOBAL_ATTRIBUTE_NUMBER19,GLOBAL_ATTRIBUTE_NUMBER20,GLOBAL_ATTRIBUTE_NUMBER21,'   ||
                     'GLOBAL_ATTRIBUTE_NUMBER22,GLOBAL_ATTRIBUTE_NUMBER23,GLOBAL_ATTRIBUTE_NUMBER24,GLOBAL_ATTRIBUTE_NUMBER25,GOP_REFERENCE_ID,'            ||
                     'SOURCE_DOCUMENT_NUMBER,SOURCE_DOCUMENT_LINE_NUMBER,GLOBAL_ATTRIBUTE_CHAR21,GLOBAL_ATTRIBUTE_CHAR22,GLOBAL_ATTRIBUTE_CHAR23,END'
    ;
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
    OPEN history_sales_order_cur;
--
    -- データ部出力
    LOOP
      FETCH history_sales_order_cur INTO history_sales_order_record;
      EXIT WHEN history_sales_order_cur%NOTFOUND;
--
      --件数セット
      gn_target_cnt := gn_target_cnt + 1;
--
      -- 明細部設定
      lv_csv_text_l :=    history_sales_order_record.sr_instance_code                                 || ','
                       || history_sales_order_record.item_name                                        || ','
                       || ''                                                                          || ','
                       || history_sales_order_record.organization_code                                || ','
                       || ''                                                                          || ','
                       || TO_CHAR(history_sales_order_record.using_requirement_quantity)              || ','
                       || ''                                                                          || ','
                       || history_sales_order_record.sales_order_number                               || ','
                       || history_sales_order_record.so_line_num                                      || ','
                       || TO_CHAR(history_sales_order_record.using_assembly_demand_date,'YYYY/MM/DD') || ','
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
                       || history_sales_order_record.customer_name                                    || ','
                       || history_sales_order_record.ship_to_site_code                                || ','
                       || ''                                                                          || ','
                       || ''                                                                          || ','
                       || ''                                                                          || ','
                       || ''                                                                          || ','
                       || ''                                                                          || ','
                       || history_sales_order_record.ordered_uom                                      || ','
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
                       || history_sales_order_record.deleted_flag                                     || ','
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
                       || ''                                                                          || ','
                       || history_sales_order_record.end_value
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
    CLOSE history_sales_order_cur;
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
END XXSCP001A01C;
/