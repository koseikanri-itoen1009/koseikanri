CREATE OR REPLACE PACKAGE BODY APPS.XXCFF017A02C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name     : XXCFF017A02C (body)
 * Description      : 自販機物件CSV出力
 * MD.050           : 自販機物件CSV出力 (MD050_CFF_017A02)
 * Version          : 1.0
 *
 * Program List
 * -------------------- ------------------------------------------------------------
 *  Name                 Description
 * -------------------- ------------------------------------------------------------
 *  init                   初期処理(A-1)
 *  output_csv             自販機物件情報抽出処理(A-2)、自販機物件CSV出力処理(A-3)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ(A-4)
 *
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2014/06/23    1.0   T.Kobori         main新規作成
 *  2014/06/30    1.1   T.Kobori         項目削除  1.月額リース料 2.再リース料
 *  2014/07/04    1.2   T.Kobori         項目追加  1.仕入先コード(出力ファイル)
 *  2014/07/09    1.3   T.Kobori         項目追加  1.仕入先コード(入力パラメータ)
 *
 *****************************************************************************************/
--
--#######################  固定グローバル定数宣言部 START   #######################
--
  --ステータス・コード
  cv_status_normal          CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal; -- 正常:0
  cv_status_warn            CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_warn;   -- 警告:1
  cv_status_error           CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;  -- 異常:2
  --WHOカラム
  cn_created_by             CONSTANT NUMBER      := fnd_global.user_id;         -- CREATED_BY
  cd_creation_date          CONSTANT DATE        := SYSDATE;                    -- CREATION_DATE
  cn_last_updated_by        CONSTANT NUMBER      := fnd_global.user_id;         -- LAST_UPDATED_BY
  cd_last_update_date       CONSTANT DATE        := SYSDATE;                    -- LAST_UPDATE_DATE
  cn_last_update_login      CONSTANT NUMBER      := fnd_global.login_id;        -- LAST_UPDATE_LOGIN
  cn_request_id             CONSTANT NUMBER      := fnd_global.conc_request_id; -- REQUEST_ID
  cn_program_application_id CONSTANT NUMBER      := fnd_global.prog_appl_id;    -- PROGRAM_APPLICATION_ID
  cn_program_id             CONSTANT NUMBER      := fnd_global.conc_program_id; -- PROGRAM_ID
  cd_program_update_date    CONSTANT DATE        := SYSDATE;                    -- PROGRAM_UPDATE_DATE
--
  cv_msg_part      CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont      CONSTANT VARCHAR2(3) := '.';
--
--################################  固定部 END   ##################################
--
--#######################  固定グローバル変数宣言部 START   #######################
--
  gv_out_msg       VARCHAR2(2000);
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
  init_err_expt               EXCEPTION;      -- 初期処理エラー
  no_data_warn_expt           EXCEPTION;      -- 対象データなし
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name                 CONSTANT VARCHAR2(100) := 'XXCFF017A02C';              -- パッケージ名
--
  -- アプリケーション短縮名
  cv_appl_name_xxccp          CONSTANT VARCHAR2(10)  := 'XXCCP';                     -- XXCCP
  cv_appl_name_xxcff          CONSTANT VARCHAR2(10)  := 'XXCFF';                     -- XXCFF
  -- 日付書式
  cv_format_YMD               CONSTANT VARCHAR2(50)  := 'YYYY/MM/DD';
  cv_format_std               CONSTANT VARCHAR2(50)  := 'yyyy/mm/dd hh24:mi:ss';
  -- 括り文字
  cv_dqu                      CONSTANT VARCHAR2(1)   := '"';                         -- 文字列括り
  cv_comma                    CONSTANT VARCHAR2(1)   := ',';                         -- カンマ
  -- メッセージコード
  cv_msg_cff_00062            CONSTANT VARCHAR2(50)  := 'APP-XXCFF1-00062';          -- 対象データ無し
  cv_msg_cff_00220            CONSTANT VARCHAR2(50)  := 'APP-XXCFF1-00220';          -- 入力パラメータ
  cv_msg_cff_00226            CONSTANT VARCHAR2(50)  := 'APP-XXCFF1-00226';          -- 必須チェックエラー(物件コード)
  cv_msg_cff_50239            CONSTANT VARCHAR2(50)  := 'APP-XXCFF1-50239';          -- メッセージ用文字列(検索区分)
  cv_msg_cff_50240            CONSTANT VARCHAR2(50)  := 'APP-XXCFF1-50240';          -- メッセージ用文字列(機器区分)
  cv_msg_cff_50010            CONSTANT VARCHAR2(50)  := 'APP-XXCFF1-50010';          -- メッセージ用文字列(物件コード)
  cv_msg_cff_50013            CONSTANT VARCHAR2(50)  := 'APP-XXCFF1-50013';          -- メッセージ用文字列(物件ステータス)
  cv_msg_cff_50243            CONSTANT VARCHAR2(50)  := 'APP-XXCFF1-50243';          -- メッセージ用文字列(管理部門)
  cv_msg_cff_50177            CONSTANT VARCHAR2(50)  := 'APP-XXCFF1-50177';          -- メッセージ用文字列(メーカ名)
  cv_msg_cff_50178            CONSTANT VARCHAR2(50)  := 'APP-XXCFF1-50178';          -- メッセージ用文字列(機種)
  cv_msg_cff_50246            CONSTANT VARCHAR2(50)  := 'APP-XXCFF1-50246';          -- メッセージ用文字列(申告地)
  cv_msg_cff_50247            CONSTANT VARCHAR2(50)  := 'APP-XXCFF1-50247';          -- メッセージ用文字列(事業供用日 FROM)
  cv_msg_cff_50248            CONSTANT VARCHAR2(50)  := 'APP-XXCFF1-50248';          -- メッセージ用文字列(事業供用日 TO)
  cv_msg_cff_50249            CONSTANT VARCHAR2(50)  := 'APP-XXCFF1-50249';          -- メッセージ用文字列(除売却日 FROM)
  cv_msg_cff_50250            CONSTANT VARCHAR2(50)  := 'APP-XXCFF1-50250';          -- メッセージ用文字列(除売却日 TO)
  cv_msg_cff_50251            CONSTANT VARCHAR2(50)  := 'APP-XXCFF1-50251';          -- メッセージ用文字列(履歴処理区分)
  cv_msg_cff_50252            CONSTANT VARCHAR2(50)  := 'APP-XXCFF1-50252';          -- メッセージ用文字列(履歴処理日 FROM)
  cv_msg_cff_50253            CONSTANT VARCHAR2(50)  := 'APP-XXCFF1-50253';          -- メッセージ用文字列(履歴処理日 TO)
  cv_msg_cff_50276            CONSTANT VARCHAR2(50)  := 'APP-XXCFF1-50276';          -- メッセージ用文字列(仕入先コード)
  cv_msg_cff_50254            CONSTANT VARCHAR2(50)  := 'APP-XXCFF1-50254';          -- 自販機物件CSV出力ヘッダノート
  cv_msg_cff_90000            CONSTANT VARCHAR2(50)  := 'APP-XXCCP1-90000';          -- 対象件数メッセージ
  cv_msg_cff_90001            CONSTANT VARCHAR2(50)  := 'APP-XXCCP1-90001';          -- 成功件数メッセージ
  cv_msg_cff_90002            CONSTANT VARCHAR2(50)  := 'APP-XXCCP1-90002';          -- エラー件数メッセージ
  cv_msg_cff_90003            CONSTANT VARCHAR2(50)  := 'APP-XXCCP1-90003';          -- スキップ件数メッセージ
  cv_msg_cff_90004            CONSTANT VARCHAR2(50)  := 'APP-XXCCP1-90004';          -- 正常終了メッセージ
  cv_msg_cff_90005            CONSTANT VARCHAR2(50)  := 'APP-XXCCP1-90005';          -- 警告メッセージ
  cv_msg_cff_90006            CONSTANT VARCHAR2(50)  := 'APP-XXCCP1-90006';          -- エラー終了全ロールバックメッセージ
  -- トークン
  cv_tkn_param_name           CONSTANT VARCHAR2(20)  := 'PARAM_NAME';                -- 入力パラメータ名
  cv_tkn_param_value          CONSTANT VARCHAR2(20)  := 'PARAM_VALUE';               -- 入力パラメータ値
  cv_tkn_count                CONSTANT VARCHAR2(20)  := 'COUNT';                     -- 件数
  -- 検索区分
  cv_search_type_1            CONSTANT VARCHAR2(1)   := '1';                         -- 最新
  cv_search_type_2            CONSTANT VARCHAR2(1)   := '2';                         -- 履歴
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gv_search_type                     VARCHAR2(1);                                       -- 検索区分
  gt_machine_type                    PO_HAZARD_CLASSES_TL.HAZARD_CLASS%TYPE;            -- 機器区分
  gt_object_code                     XXCFF_VD_OBJECT_HEADERS.OBJECT_CODE%TYPE;          -- 物件コード
  gv_object_status                   VARCHAR2(3);                                       -- 物件ステータス
  gt_department_code                 FND_FLEX_VALUES.FLEX_VALUE%TYPE;                   -- 管理部門
  gt_manufacturer_name               XXCFF_VD_OBJECT_HEADERS.MANUFACTURER_NAME%TYPE;    -- メーカ名
  gt_model                           PO_UN_NUMBERS_TL.UN_NUMBER%TYPE;                   -- 機種
  gt_dclr_place                      FND_FLEX_VALUES.FLEX_VALUE%TYPE;                   -- 申告地
  gd_date_placed_in_service_from     DATE;                                              -- 事業供用日 FROM
  gd_date_placed_in_service_to       DATE;                                              -- 事業供用日 TO
  gd_date_retired_from               DATE;                                              -- 除売却日 FROM
  gd_date_retired_to                 DATE;                                              -- 除売却日 TO
  gv_process_type                    VARCHAR2(3);                                       -- 履歴処理区分
  gd_process_date_from               DATE;                                              -- 履歴処理日 FROM
  gd_process_date_to                 DATE;                                              -- 履歴処理日 TO
  gt_vendor_code                     PO_VENDORS.SEGMENT1%TYPE;                          -- 仕入先コード
--
  -- ===============================
  -- ユーザー定義グローバルカーソル
  -- ===============================
  -- 自販機物件情報取得カーソル
  CURSOR get_vd_object_info_cur
  IS
    SELECT
        vohd.object_code                              AS  object_code             -- 物件コード
       ,NULL                                          AS  history_num             -- 履歴番号
       ,NULL                                          AS  process_type            -- 処理区分
       ,NULL                                          AS  process_date            -- 処理日
       ,vohd.object_status                            AS  object_status           -- 物件ステータス
       ,vohd.owner_company_type                       AS  owner_company_type      -- 本社/工場区分
       ,vohd.department_code                          AS  department_code         -- 管理部門
       ,vohd.machine_type                             AS  machine_type            -- 機器区分
 -- 2014/07/04 ADD START
       ,vohd.vendor_code                              AS  vendor_code             -- 仕入先コード
 -- 2014/07/04 ADD END
       ,vohd.manufacturer_name                        AS  manufacturer_name       -- メーカ名
       ,vohd.model                                    AS  model                   -- 機種
       ,vohd.age_type                                 AS  age_type                -- 年式
       ,vohd.customer_code                            AS  customer_code           -- 顧客コード
       ,vohd.quantity                                 AS  quantity                -- 数量
       ,vohd.date_placed_in_service                   AS  date_placed_in_service  -- 事業供用日
       ,vohd.assets_cost                              AS  assets_cost             -- 取得価格
 -- 2014/06/30 DEL START
 --      ,vohd.month_lease_charge                       AS  month_lease_charge      -- 月額リース料
 --      ,vohd.re_lease_charge                          AS  re_lease_charge         -- 再リース料
 -- 2014/06/30 DEL END
       ,NVL(vohd.assets_date,vohd.date_placed_in_service)  AS  assets_date        -- NVL(取得日,事業供用日)
       ,vohd.moved_date                               AS  moved_date              -- 移動日
       ,vohd.installation_place                       AS  installation_place      -- 設置先
       ,vohd.installation_address                     AS  installation_address    -- 設置場所
       ,vohd.dclr_place                               AS  dclr_place              -- 申告地
       ,vohd.location                                 AS  location                -- 事業所
       ,vohd.date_retired                             AS  date_retired            -- 除･売却日
       ,vohd.proceeds_of_sale                         AS  proceeds_of_sale        -- 売却価額
       ,vohd.cost_of_removal                          AS  cost_of_removal         -- 撤去費用
       ,vohd.retired_flag                             AS  retired_flag            -- 除売却確定フラグ
       ,vohd.ib_if_date                               AS  ib_if_date              -- 設置ベース情報連携日
       ,NULL                                          AS  fa_if_date              -- FA情報連携日
       ,vohd.last_updated_by                          AS  last_updated_by         -- 最終更新者
    FROM
        xxcff_vd_object_headers vohd  --自販機物件管理
    WHERE vohd.machine_type           = gt_machine_type                                                  -- 機器区分
    AND vohd.object_code              = NVL(gt_object_code,vohd.object_code)                             -- 物件コード
    AND vohd.object_status            = NVL(gv_object_status,vohd.object_status)                         -- 物件ステータス
    AND vohd.department_code          = NVL(gt_department_code,vohd.department_code)                     -- 管理部門
    AND vohd.manufacturer_name        = NVL(gt_manufacturer_name,vohd.manufacturer_name)                 -- メーカ名
    AND vohd.model                    = NVL(gt_model,vohd.model)                                         -- 機種
    AND vohd.dclr_place               = NVL(gt_dclr_place,vohd.dclr_place)                               -- 申告地
    AND (  (gd_date_placed_in_service_from IS NULL
        AND gd_date_placed_in_service_to IS NULL)                                              -- 事業供用日未入力
        OR (vohd.date_placed_in_service     >= NVL(gd_date_placed_in_service_from,vohd.date_placed_in_service)   -- 事業供用日 FROM
        AND vohd.date_placed_in_service     <= NVL(gd_date_placed_in_service_to,vohd.date_placed_in_service))    -- 事業供用日 TO
        )
    AND (  (gd_date_retired_from IS NULL
        AND gd_date_retired_to IS NULL)                                                        -- 除売却日未入力
        OR (vohd.date_retired             >= NVL(gd_date_retired_from,vohd.date_retired)                 -- 除売却日 FROM
        AND vohd.date_retired             <= NVL(gd_date_retired_to,vohd.date_retired))                  -- 除売却日 TO
        )
 -- 2014/07/09 ADD START
    AND (  gt_vendor_code IS NULL
        OR vohd.vendor_code           = gt_vendor_code                                                   -- 仕入先コード
        )
 -- 2014/07/09 ADD END
    AND gv_search_type           = cv_search_type_1                                            -- 検索区分(最新)
    UNION
    SELECT
        vohi.object_code                              AS  object_code             -- 物件コード
       ,vohi.history_num                              AS  history_num             -- 履歴番号
       ,vohi.process_type                             AS  process_type            -- 処理区分
       ,vohi.process_date                             AS  process_date            -- 処理日
       ,vohi.object_status                            AS  object_status           -- 物件ステータス
       ,vohi.owner_company_type                       AS  owner_company_type      -- 本社/工場区分
       ,vohi.department_code                          AS  department_code         -- 管理部門
       ,vohi.machine_type                             AS  machine_type            -- 機器区分
 -- 2014/07/04 ADD START
       ,NULL                                          AS  vendor_code             -- 仕入先コード
 -- 2014/07/04 ADD END
       ,vohi.manufacturer_name                        AS  manufacturer_name       -- メーカ名
       ,vohi.model                                    AS  model                   -- 機種
       ,vohi.age_type                                 AS  age_type                -- 年式
       ,vohi.customer_code                            AS  customer_code           -- 顧客コード
       ,vohi.quantity                                 AS  quantity                -- 数量
       ,vohi.date_placed_in_service                   AS  date_placed_in_service  -- 事業供用日
       ,vohi.assets_cost                              AS  assets_cost             -- 取得価格
 -- 2014/06/30 DEL START
 --      ,vohi.month_lease_charge                       AS  month_lease_charge      -- 月額リース料
 --      ,vohi.re_lease_charge                          AS  re_lease_charge         -- 再リース料
 -- 2014/06/30 DEL END
       ,NVL(vohi.assets_date,vohi.date_placed_in_service)  AS  assets_date             -- NVL(取得日,事業供用日)
       ,vohi.moved_date                               AS  moved_date              -- 移動日
       ,vohi.installation_place                       AS  installation_place      -- 設置先
       ,vohi.installation_address                     AS  installation_address    -- 設置場所
       ,vohi.dclr_place                               AS  dclr_place              -- 申告地
       ,vohi.location                                 AS  location                -- 事業所
       ,vohi.date_retired                             AS  date_retired            -- 除･売却日
       ,vohi.proceeds_of_sale                         AS  proceeds_of_sale        -- 売却価額
       ,vohi.cost_of_removal                          AS  cost_of_removal         -- 撤去費用
       ,vohi.retired_flag                             AS  retired_flag            -- 除売却確定フラグ
       ,vohi.ib_if_date                               AS  ib_if_date              -- 設置ベース情報連携日
       ,vohi.fa_if_date                               AS  fa_if_date              -- FA情報連携日
       ,vohi.last_updated_by                          AS  last_updated_by         -- 最終更新者
    FROM
        xxcff_vd_object_histories vohi  --自販機物件履歴
    WHERE vohi.machine_type           = gt_machine_type                                             -- 機器区分
    AND vohi.object_code              = gt_object_code                                              -- 物件コード
    AND vohi.object_status            = NVL(gv_object_status,vohi.object_status)                         -- 物件ステータス
    AND vohi.department_code          = NVL(gt_department_code,vohi.department_code)                     -- 管理部門
    AND vohi.manufacturer_name        = NVL(gt_manufacturer_name,vohi.manufacturer_name)                 -- メーカ名
    AND vohi.model                    = NVL(gt_model,vohi.model)                                         -- 機種
    AND vohi.dclr_place               = NVL(gt_dclr_place,vohi.dclr_place)                               -- 申告地
    AND (  (gd_date_placed_in_service_from IS NULL
        AND gd_date_placed_in_service_to IS NULL)                                              -- 事業供用日未入力
        OR (vohi.date_placed_in_service     >= NVL(gd_date_placed_in_service_from,vohi.date_placed_in_service)   -- 事業供用日 FROM
        AND vohi.date_placed_in_service     <= NVL(gd_date_placed_in_service_to,vohi.date_placed_in_service))    -- 事業供用日 TO
        )
    AND (  (gd_date_retired_from IS NULL
        AND gd_date_retired_to IS NULL)                                                        -- 除売却日未入力
        OR (vohi.date_retired             >= NVL(gd_date_retired_from,vohi.date_retired)                 -- 除売却日 FROM
        AND vohi.date_retired             <= NVL(gd_date_retired_to,vohi.date_retired))                  -- 除売却日 TO
        )
    AND vohi.process_type             = NVL(gv_process_type,vohi.process_type)                           -- 履歴処理区分
    AND (  (gd_process_date_from IS NULL
        AND gd_process_date_to IS NULL)                                                        -- 履歴処理日未入力
        OR (vohi.process_date             >= NVL(gd_process_date_from,vohi.process_date)                 -- 履歴処理日 FROM
        AND vohi.process_date             <= NVL(gd_process_date_to,vohi.process_date))                  -- 履歴処理日 TO
        )
    AND gv_search_type           = cv_search_type_2                                            -- 検索区分(履歴)
    ORDER BY object_code         -- 物件コード
            ,history_num         -- 履歴番号
    ;
    -- 自販機物件情報カーソルレコード型
    get_vd_object_info_rec get_vd_object_info_cur%ROWTYPE;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    iv_search_type                  IN  VARCHAR2      -- 1.検索区分 
   ,iv_machine_type                 IN  VARCHAR2      -- 2.機器区分
   ,iv_object_code                  IN  VARCHAR2      -- 3.物件コード
   ,iv_object_status                IN  VARCHAR2      -- 4.物件ステータス
   ,iv_department_code              IN  VARCHAR2      -- 5.管理部門
   ,iv_manufacturer_name            IN  VARCHAR2      -- 6.メーカ名
   ,iv_model                        IN  VARCHAR2      -- 7.機種
   ,iv_dclr_place                   IN  VARCHAR2      -- 8.申告地
   ,iv_date_placed_in_service_from  IN  DATE          -- 9.事業供用日 FROM
   ,iv_date_placed_in_service_to    IN  DATE          -- 10.事業供用日 TO
   ,iv_date_retired_from            IN  DATE          -- 11.除売却日 FROM
   ,iv_date_retired_to              IN  DATE          -- 12.除売却日 TO
   ,iv_process_type                 IN  VARCHAR2      -- 13.履歴処理区分
   ,iv_process_date_from            IN  DATE          -- 14.履歴処理日 FROM
   ,iv_process_date_to              IN  DATE          -- 15.履歴処理日 TO
 -- 2014/07/09 ADD START
   ,iv_vendor_code                  IN  VARCHAR2      -- 16.仕入先コード
 -- 2014/07/09 ADD END
   ,ov_errbuf                       OUT VARCHAR2      --   エラー・メッセージ           --# 固定 #
   ,ov_retcode                      OUT VARCHAR2      --   リターン・コード             --# 固定 #
   ,ov_errmsg                       OUT VARCHAR2      --   ユーザー・エラー・メッセージ --# 固定 #
  )
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
    lv_param_name1                  VARCHAR2(1000);  -- 入力パラメータ名1
    lv_param_name2                  VARCHAR2(1000);  -- 入力パラメータ名2
    lv_param_name3                  VARCHAR2(1000);  -- 入力パラメータ名3
    lv_param_name4                  VARCHAR2(1000);  -- 入力パラメータ名4
    lv_param_name5                  VARCHAR2(1000);  -- 入力パラメータ名5
    lv_param_name6                  VARCHAR2(1000);  -- 入力パラメータ名6
    lv_param_name7                  VARCHAR2(1000);  -- 入力パラメータ名7
    lv_param_name8                  VARCHAR2(1000);  -- 入力パラメータ名8
    lv_param_name9                  VARCHAR2(1000);  -- 入力パラメータ名9
    lv_param_name10                 VARCHAR2(1000);  -- 入力パラメータ名10
    lv_param_name11                 VARCHAR2(1000);  -- 入力パラメータ名11
    lv_param_name12                 VARCHAR2(1000);  -- 入力パラメータ名12
    lv_param_name13                 VARCHAR2(1000);  -- 入力パラメータ名13
    lv_param_name14                 VARCHAR2(1000);  -- 入力パラメータ名14
    lv_param_name15                 VARCHAR2(1000);  -- 入力パラメータ名15
 -- 2014/07/09 ADD START
    lv_param_name16                 VARCHAR2(1000);  -- 入力パラメータ名16
 -- 2014/07/09 ADD END
    lv_search_type                  VARCHAR2(1000);  -- 1.検索区分 
    lv_machine_type                 VARCHAR2(1000);  -- 2.機器区分
    lv_object_code                  VARCHAR2(1000);  -- 3.物件コード
    lv_object_status                VARCHAR2(1000);  -- 4.物件ステータス
    lv_department_code              VARCHAR2(1000);  -- 5.管理部門
    lv_manufacturer_name            VARCHAR2(1000);  -- 6.メーカ名
    lv_model                        VARCHAR2(1000);  -- 7.機種
    lv_dclr_place                   VARCHAR2(1000);  -- 8.申告地
    lv_date_placed_in_service_from  VARCHAR2(1000);  -- 9.事業供用日 FROM
    lv_date_placed_in_service_to    VARCHAR2(1000);  -- 10.事業供用日 TO
    lv_date_retired_from            VARCHAR2(1000);  -- 11.除売却日 FROM
    lv_date_retired_to              VARCHAR2(1000);  -- 12.除売却日 TO
    lv_process_type                 VARCHAR2(1000);  -- 13.履歴処理区分
    lv_process_date_from            VARCHAR2(1000);  -- 14.履歴処理日 FROM
    lv_process_date_to              VARCHAR2(1000);  -- 15.履歴処理日 TO
 -- 2014/07/09 ADD START
    lv_vendor_code                  VARCHAR2(1000);  -- 16.仕入先コード
 -- 2014/07/09 ADD END
    lv_csv_header                   VARCHAR2(5000);  -- CSVヘッダ項目出力用
--
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
    --==============================================================
    -- 0.入力パラメータ格納
    --==============================================================
    gv_search_type                  := iv_search_type;                                         --1.検索区分
    gt_machine_type                 := iv_machine_type;                                        --2.機器区分
    --3.物件コード
    BEGIN
    gt_object_code := iv_object_code;
    EXCEPTION
      WHEN OTHERS THEN
        -- エラーメッセージ取得
        lv_errmsg := xxccp_common_pkg.get_msg(
            iv_application  => cv_appl_name_xxcff   -- アプリケーション短縮名
           ,iv_name         => cv_msg_cff_50010     -- メッセージコード
        );
        lv_errbuf  := lv_errmsg;
      RAISE init_err_expt;
    END;
    gv_object_status                := iv_object_status;                                       --4.物件ステータス
    gt_department_code              := iv_department_code;                                     --5.管理部門
    gt_manufacturer_name            := iv_manufacturer_name;                                   --6.メーカ名
    gt_model                        := iv_model;                                               --7.機種
    gt_dclr_place                   := iv_dclr_place;                                          --8.申告地
    gd_date_placed_in_service_from  := iv_date_placed_in_service_from;                         --9.事業供用日 FROM
    gd_date_placed_in_service_to    := iv_date_placed_in_service_to;                           --10.事業供用日 TO
    gd_date_retired_from            := iv_date_retired_from;                                   --11.除売却日 FROM
    gd_date_retired_to              := iv_date_retired_to;                                     --12.除売却日 TO
    gv_process_type                 := iv_process_type;                                        --13.履歴処理区分
    gd_process_date_from            := iv_process_date_from;                                   --14.履歴処理日 FROM
    gd_process_date_to              := iv_process_date_to;                                     --15.履歴処理日 TO
 -- 2014/07/09 ADD START
    gt_vendor_code                  := iv_vendor_code;                                         --16.仕入先コード
 -- 2014/07/09 ADD END
--
    --==============================================================
    -- 1.入力パラメータ出力
    --==============================================================
    -- 1.検索区分
    lv_param_name1 := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcff             -- アプリケーション短縮名
                       ,iv_name         => cv_msg_cff_50239               -- メッセージコード
                      );
    lv_search_type := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcff             -- アプリケーション短縮名
                       ,iv_name         => cv_msg_cff_00220               -- メッセージコード
                       ,iv_token_name1  => cv_tkn_param_name              -- トークンコード1
                       ,iv_token_value1 => lv_param_name1                 -- トークン値1
                       ,iv_token_name2  => cv_tkn_param_value             -- トークンコード2
                       ,iv_token_value2 => iv_search_type                 -- トークン値2
                      );
--
    -- 2.機器区分
    lv_param_name2 := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcff             -- アプリケーション短縮名
                       ,iv_name         => cv_msg_cff_50240               -- メッセージコード
                      );
    lv_machine_type := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcff             -- アプリケーション短縮名
                       ,iv_name         => cv_msg_cff_00220               -- メッセージコード
                       ,iv_token_name1  => cv_tkn_param_name              -- トークンコード1
                       ,iv_token_value1 => lv_param_name2                 -- トークン値1
                       ,iv_token_name2  => cv_tkn_param_value             -- トークンコード2
                       ,iv_token_value2 => iv_machine_type                -- トークン値2
                      );
--
    -- 3.物件コード
    lv_param_name3 := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcff             -- アプリケーション短縮名
                       ,iv_name         => cv_msg_cff_50010               -- メッセージコード
                      );
    lv_object_code := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcff             -- アプリケーション短縮名
                       ,iv_name         => cv_msg_cff_00220               -- メッセージコード
                       ,iv_token_name1  => cv_tkn_param_name              -- トークンコード1
                       ,iv_token_value1 => lv_param_name3                 -- トークン値1
                       ,iv_token_name2  => cv_tkn_param_value             -- トークンコード2
                       ,iv_token_value2 => iv_object_code                 -- トークン値2
                      );
--
    -- 4.物件ステータス
    lv_param_name4 := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcff             -- アプリケーション短縮名
                       ,iv_name         => cv_msg_cff_50013               -- メッセージコード
                      );
    lv_object_status := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcff             -- アプリケーション短縮名
                       ,iv_name         => cv_msg_cff_00220               -- メッセージコード
                       ,iv_token_name1  => cv_tkn_param_name              -- トークンコード1
                       ,iv_token_value1 => lv_param_name4                 -- トークン値1
                       ,iv_token_name2  => cv_tkn_param_value             -- トークンコード2
                       ,iv_token_value2 => iv_object_status               -- トークン値2
                      );
--
    -- 5.管理部門
    lv_param_name5 := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcff             -- アプリケーション短縮名
                       ,iv_name         => cv_msg_cff_50243               -- メッセージコード
                      );
    lv_department_code := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcff             -- アプリケーション短縮名
                       ,iv_name         => cv_msg_cff_00220               -- メッセージコード
                       ,iv_token_name1  => cv_tkn_param_name              -- トークンコード1
                       ,iv_token_value1 => lv_param_name5                 -- トークン値1
                       ,iv_token_name2  => cv_tkn_param_value             -- トークンコード2
                       ,iv_token_value2 => iv_department_code             -- トークン値2
                      );
--
    -- 6.メーカ名
    lv_param_name6 := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcff             -- アプリケーション短縮名
                       ,iv_name         => cv_msg_cff_50177               -- メッセージコード
                      );
    lv_manufacturer_name := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcff             -- アプリケーション短縮名
                       ,iv_name         => cv_msg_cff_00220               -- メッセージコード
                       ,iv_token_name1  => cv_tkn_param_name              -- トークンコード1
                       ,iv_token_value1 => lv_param_name6                 -- トークン値1
                       ,iv_token_name2  => cv_tkn_param_value             -- トークンコード2
                       ,iv_token_value2 => iv_manufacturer_name           -- トークン値2
                      );
--
    -- 7.機種
    lv_param_name7 := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcff             -- アプリケーション短縮名
                       ,iv_name         => cv_msg_cff_50178               -- メッセージコード
                      );
    lv_model := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcff             -- アプリケーション短縮名
                       ,iv_name         => cv_msg_cff_00220               -- メッセージコード
                       ,iv_token_name1  => cv_tkn_param_name              -- トークンコード1
                       ,iv_token_value1 => lv_param_name7                 -- トークン値1
                       ,iv_token_name2  => cv_tkn_param_value             -- トークンコード2
                       ,iv_token_value2 => iv_model                       -- ト ークン値2
                      );
--
    -- 8.申告地
    lv_param_name8 := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcff             -- アプリケーション短縮名
                       ,iv_name         => cv_msg_cff_50246               -- メッセージコード
                      );
    lv_dclr_place := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcff             -- アプリケーション短縮名
                       ,iv_name         => cv_msg_cff_00220               -- メッセージコード
                       ,iv_token_name1  => cv_tkn_param_name              -- トークンコード1
                       ,iv_token_value1 => lv_param_name8                 -- トークン値1
                       ,iv_token_name2  => cv_tkn_param_value             -- トークンコード2
                       ,iv_token_value2 => iv_dclr_place                  -- トークン値2
                      );
--
    -- 9.事業供用日 FROM
    lv_param_name9 := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcff             -- アプリケーション短縮名
                       ,iv_name         => cv_msg_cff_50247               -- メッセージコード
                      );
    lv_date_placed_in_service_from := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcff             -- アプリケーション短縮名
                       ,iv_name         => cv_msg_cff_00220               -- メッセージコード
                       ,iv_token_name1  => cv_tkn_param_name              -- トークンコード1
                       ,iv_token_value1 => lv_param_name9                 -- トークン値1
                       ,iv_token_name2  => cv_tkn_param_value             -- トークンコード2
                       ,iv_token_value2 => TO_DATE(iv_date_placed_in_service_from,cv_format_YMD) -- トークン値2
                      );
--
    -- 10.事業供用日 TO
    lv_param_name10 := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcff             -- アプリケーション短縮名
                       ,iv_name         => cv_msg_cff_50248               -- メッセージコード
                      );
    lv_date_placed_in_service_to := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcff             -- アプリケーション短縮名
                       ,iv_name         => cv_msg_cff_00220               -- メッセージコード
                       ,iv_token_name1  => cv_tkn_param_name              -- トークンコード1
                       ,iv_token_value1 => lv_param_name10                -- トークン値1
                       ,iv_token_name2  => cv_tkn_param_value             -- トークンコード2
                       ,iv_token_value2 => TO_DATE(iv_date_placed_in_service_to,cv_format_YMD)   -- トークン値2
                      );
--
    -- 11.除売却日 FROM
    lv_param_name11 := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcff             -- アプリケーション短縮名
                       ,iv_name         => cv_msg_cff_50249               -- メッセージコード
                      );
    lv_date_retired_from := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcff             -- アプリケーション短縮名
                       ,iv_name         => cv_msg_cff_00220               -- メッセージコード
                       ,iv_token_name1  => cv_tkn_param_name              -- トークンコード1
                       ,iv_token_value1 => lv_param_name11                -- トークン値1
                       ,iv_token_name2  => cv_tkn_param_value             -- トークンコード2
                       ,iv_token_value2 => TO_DATE(iv_date_retired_from,cv_format_YMD)           -- トークン値2
                      );
--
    -- 12.除売却日 TO
    lv_param_name12 := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcff             -- アプリケーション短縮名
                       ,iv_name         => cv_msg_cff_50250               -- メッセージコード
                      );
    lv_date_retired_to := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcff             -- アプリケーション短縮名
                       ,iv_name         => cv_msg_cff_00220               -- メッセージコード
                       ,iv_token_name1  => cv_tkn_param_name              -- トークンコード1
                       ,iv_token_value1 => lv_param_name12                -- トークン値1
                       ,iv_token_name2  => cv_tkn_param_value             -- トークンコード2
                       ,iv_token_value2 => TO_DATE(iv_date_retired_to,cv_format_YMD)             -- トークン値2
                      );
--
    -- 13.履歴処理区分
    lv_param_name13 := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcff             -- アプリケーション短縮名
                       ,iv_name         => cv_msg_cff_50251               -- メッセージコード
                      );
    lv_process_type := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcff             -- アプリケーション短縮名
                       ,iv_name         => cv_msg_cff_00220               -- メッセージコード
                       ,iv_token_name1  => cv_tkn_param_name              -- トークンコード1
                       ,iv_token_value1 => lv_param_name13                -- トークン値1
                       ,iv_token_name2  => cv_tkn_param_value             -- トークンコード2
                       ,iv_token_value2 => iv_process_type                -- トークン値2
                      );
--
    -- 14.履歴処理日 FROM
    lv_param_name14 := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcff             -- アプリケーション短縮名
                       ,iv_name         => cv_msg_cff_50252               -- メッセージコード
                      );
    lv_process_date_from := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcff             -- アプリケーション短縮名
                       ,iv_name         => cv_msg_cff_00220               -- メッセージコード
                       ,iv_token_name1  => cv_tkn_param_name              -- トークンコード1
                       ,iv_token_value1 => lv_param_name14                -- トークン値1
                       ,iv_token_name2  => cv_tkn_param_value             -- トークンコード2
                       ,iv_token_value2 => TO_DATE(iv_process_date_from,cv_format_YMD)           -- トークン値2
                      );
--
    -- 15.履歴処理日 TO
    lv_param_name15 := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcff             -- アプリケーション短縮名
                       ,iv_name         => cv_msg_cff_50253               -- メッセージコード
                      );
    lv_process_date_to := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcff             -- アプリケーション短縮名
                       ,iv_name         => cv_msg_cff_00220               -- メッセージコード
                       ,iv_token_name1  => cv_tkn_param_name              -- トークンコード1
                       ,iv_token_value1 => lv_param_name15                -- トークン値1
                       ,iv_token_name2  => cv_tkn_param_value             -- トークンコード2
                       ,iv_token_value2 => TO_DATE(iv_process_date_to,cv_format_YMD)             -- トークン値2
                      );
 -- 2014/07/09 ADD START
    -- 16.仕入先コード
    lv_param_name16 := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcff             -- アプリケーション短縮名
                       ,iv_name         => cv_msg_cff_50276               -- メッセージコード
                      );
    lv_vendor_code := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcff             -- アプリケーション短縮名
                       ,iv_name         => cv_msg_cff_00220               -- メッセージコード
                       ,iv_token_name1  => cv_tkn_param_name              -- トークンコード1
                       ,iv_token_value1 => lv_param_name16                -- トークン値1
                       ,iv_token_name2  => cv_tkn_param_value             -- トークンコード2
                       ,iv_token_value2 => iv_vendor_code                 -- トークン値2
                      );
 -- 2014/07/09 ADD END
--
    -- ログに出力
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''                             || CHR(10) ||
                 lv_search_type                 || CHR(10) ||      -- 1.検索区分
                 lv_machine_type                || CHR(10) ||      -- 2.機器区分
                 lv_object_code                 || CHR(10) ||      -- 3.物件コード
                 lv_object_status               || CHR(10) ||      -- 4.物件ステータス
                 lv_department_code             || CHR(10) ||      -- 5.管理部門
                 lv_manufacturer_name           || CHR(10) ||      -- 6.メーカ名
                 lv_model                       || CHR(10) ||      -- 7.機種
                 lv_dclr_place                  || CHR(10) ||      -- 8.申告地
                 lv_date_placed_in_service_from || CHR(10) ||      -- 9.事業供用日 FROM
                 lv_date_placed_in_service_to   || CHR(10) ||      -- 10.事業供用日 TO
                 lv_date_retired_from           || CHR(10) ||      -- 11.除売却日 FROM
                 lv_date_retired_to             || CHR(10) ||      -- 12.除売却日 TO
                 lv_process_type                || CHR(10) ||      -- 13.履歴処理区分
                 lv_process_date_from           || CHR(10) ||      -- 14.履歴処理日 FROM
 -- 2014/07/09 MOD START
 --                lv_process_date_to             || CHR(10)         -- 15.履歴処理日 TO
                 lv_process_date_to             || CHR(10) ||      -- 15.履歴処理日 TO
                 lv_vendor_code                 || CHR(10)         -- 16.仕入先コード
 -- 2014/07/09 ADD END
    );
--
    --==================================================
    -- 2.入力パラメータ必須チェック
    --==================================================
    -- 履歴指定時に、物件コードが未入力の場合はエラー
    IF( gv_search_type = cv_search_type_2 AND gt_object_code IS NULL )
    THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
          iv_application  => cv_appl_name_xxcff   -- アプリケーション短縮名
         ,iv_name         => cv_msg_cff_00226     -- メッセージコード
      );
      lv_errbuf  := lv_errmsg;
      RAISE init_err_expt;
    END IF;
--
    --==================================================
    -- 3.CSVヘッダ項目出力
    --==================================================
    lv_csv_header := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxcff   -- アプリケーション短縮名
                    ,iv_name         => cv_msg_cff_50254     -- メッセージコード
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_csv_header
    );
--
  EXCEPTION
    -- *** エラー終了 ***
    WHEN init_err_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errmsg, 1, 5000 );
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
  END init;
--
  /**********************************************************************************
   * Procedure Name   : output_csv
   * Description      : 自販機物件情報抽出処理(A-2)、自販機物件CSV出力処理(A-3)
   ***********************************************************************************/
  PROCEDURE output_csv(
    ov_errbuf          OUT NOCOPY VARCHAR2      -- エラー・メッセージ                  --# 固定 #
   ,ov_retcode         OUT NOCOPY VARCHAR2      -- リターン・コード                    --# 固定 #
   ,ov_errmsg          OUT NOCOPY VARCHAR2      -- ユーザー・エラー・メッセージ        --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'output_csv'; -- プログラム名
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
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    lv_op_str            VARCHAR2(5000)  := NULL;   -- 出力文字列格納用変数
--
    -- ===============================
    -- ユーザー定義例外
    -- ===============================
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
    -- 自販機物件情報抽出処理(A-2)
    -- ===============================
    << vd_object_info_loop >>
    FOR get_vd_object_info_rec IN get_vd_object_info_cur
    LOOP
      -- ===============================
      -- CSVファイル出力(A-3)
      -- ===============================
      -- 対象件数
      gn_target_cnt := gn_target_cnt + 1;
--
      --出力文字列作成
      lv_op_str :=                          cv_dqu || NULL                                          || cv_dqu ;   -- 変更区分
      lv_op_str := lv_op_str || cv_comma || cv_dqu || get_vd_object_info_rec.object_code            || cv_dqu ;   -- 物件コード
      lv_op_str := lv_op_str || cv_comma || cv_dqu || get_vd_object_info_rec.history_num            || cv_dqu ;   -- 履歴番号
      lv_op_str := lv_op_str || cv_comma || cv_dqu || get_vd_object_info_rec.process_type           || cv_dqu ;   -- 処理区分
      lv_op_str := lv_op_str || cv_comma || cv_dqu || get_vd_object_info_rec.process_date           || cv_dqu ;   -- 処理日
      lv_op_str := lv_op_str || cv_comma || cv_dqu || get_vd_object_info_rec.object_status          || cv_dqu ;   -- 物件ステータス
      lv_op_str := lv_op_str || cv_comma || cv_dqu || get_vd_object_info_rec.owner_company_type     || cv_dqu ;   -- 本社/工場区分
      lv_op_str := lv_op_str || cv_comma || cv_dqu || get_vd_object_info_rec.department_code        || cv_dqu ;   -- 管理部門
      lv_op_str := lv_op_str || cv_comma || cv_dqu || get_vd_object_info_rec.machine_type           || cv_dqu ;   -- 機器区分
 -- 2014/07/04 ADD START
      lv_op_str := lv_op_str || cv_comma || cv_dqu || get_vd_object_info_rec.vendor_code            || cv_dqu ;   -- 仕入先コード
 -- 2014/07/04 ADD END
      lv_op_str := lv_op_str || cv_comma || cv_dqu || get_vd_object_info_rec.manufacturer_name      || cv_dqu ;   -- メーカ名
      lv_op_str := lv_op_str || cv_comma || cv_dqu || get_vd_object_info_rec.model                  || cv_dqu ;   -- 機種
      lv_op_str := lv_op_str || cv_comma || cv_dqu || get_vd_object_info_rec.age_type               || cv_dqu ;   -- 年式
      lv_op_str := lv_op_str || cv_comma || cv_dqu || get_vd_object_info_rec.customer_code          || cv_dqu ;   -- 顧客コード
      lv_op_str := lv_op_str || cv_comma || cv_dqu || get_vd_object_info_rec.quantity               || cv_dqu ;   -- 数量
      lv_op_str := lv_op_str || cv_comma || cv_dqu || get_vd_object_info_rec.date_placed_in_service || cv_dqu ;   -- 事業供用日
      lv_op_str := lv_op_str || cv_comma || cv_dqu || get_vd_object_info_rec.assets_cost            || cv_dqu ;   -- 取得価格
 -- 2014/06/30 DEL START
 --     lv_op_str := lv_op_str || cv_comma || cv_dqu || get_vd_object_info_rec.month_lease_charge     || cv_dqu ;   -- 月額リース料
 --     lv_op_str := lv_op_str || cv_comma || cv_dqu || get_vd_object_info_rec.re_lease_charge        || cv_dqu ;   -- 再リース料
 -- 2014/06/30 DEL END
      lv_op_str := lv_op_str || cv_comma || cv_dqu || get_vd_object_info_rec.assets_date            || cv_dqu ;   -- 取得日
      lv_op_str := lv_op_str || cv_comma || cv_dqu || get_vd_object_info_rec.moved_date             || cv_dqu ;   -- 移動日
      lv_op_str := lv_op_str || cv_comma || cv_dqu || get_vd_object_info_rec.installation_place     || cv_dqu ;   -- 設置先
      lv_op_str := lv_op_str || cv_comma || cv_dqu || get_vd_object_info_rec.installation_address   || cv_dqu ;   -- 設置場所
      lv_op_str := lv_op_str || cv_comma || cv_dqu || get_vd_object_info_rec.dclr_place             || cv_dqu ;   -- 申告地
      lv_op_str := lv_op_str || cv_comma || cv_dqu || get_vd_object_info_rec.location               || cv_dqu ;   -- 事業所
      lv_op_str := lv_op_str || cv_comma || cv_dqu || get_vd_object_info_rec.date_retired           || cv_dqu ;   -- 除･売却日
      lv_op_str := lv_op_str || cv_comma || cv_dqu || get_vd_object_info_rec.proceeds_of_sale       || cv_dqu ;   -- 売却価額
      lv_op_str := lv_op_str || cv_comma || cv_dqu || get_vd_object_info_rec.cost_of_removal        || cv_dqu ;   -- 撤去費用
      lv_op_str := lv_op_str || cv_comma || cv_dqu || get_vd_object_info_rec.retired_flag           || cv_dqu ;   -- 除売却確定フラグ
      lv_op_str := lv_op_str || cv_comma || cv_dqu || get_vd_object_info_rec.ib_if_date             || cv_dqu ;   -- 設置ベース情報連携日
      lv_op_str := lv_op_str || cv_comma || cv_dqu || get_vd_object_info_rec.fa_if_date             || cv_dqu ;   -- FA情報連携日
      lv_op_str := lv_op_str || cv_comma || cv_dqu || get_vd_object_info_rec.last_updated_by        || cv_dqu ;   -- 従業員番号
--
      -- ===============================
      -- 2.CSVファイル出力
      -- ===============================
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_op_str
      );
      -- 成功件数
      gn_normal_cnt := gn_normal_cnt + 1;
--
    END LOOP vd_object_info_loop;
--
    -- 対象データなし警告
    IF ( gn_target_cnt = 0 ) THEN
      gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_name_xxcff
                      ,iv_name         => cv_msg_cff_00062
                     );
      ov_errbuf  := gv_out_msg;
      ov_retcode := cv_status_warn;
    END IF;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      -- エラー件数
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END output_csv;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    iv_search_type                  IN  VARCHAR2     -- 1.検索区分 
   ,iv_machine_type                 IN  VARCHAR2     -- 2.機器区分
   ,iv_object_code                  IN  VARCHAR2     -- 3.物件コード
   ,iv_object_status                IN  VARCHAR2     -- 4.物件ステータス
   ,iv_department_code              IN  VARCHAR2     -- 5.管理部門
   ,iv_manufacturer_name            IN  VARCHAR2     -- 6.メーカ名
   ,iv_model                        IN  VARCHAR2     -- 7.機種
   ,iv_dclr_place                   IN  VARCHAR2     -- 8.申告地
   ,iv_date_placed_in_service_from  IN  DATE         -- 9.事業供用日 FROM
   ,iv_date_placed_in_service_to    IN  DATE         -- 10.事業供用日 TO
   ,iv_date_retired_from            IN  DATE         -- 11.除売却日 FROM
   ,iv_date_retired_to              IN  DATE         -- 12.除売却日 TO
   ,iv_process_type                 IN  VARCHAR2     -- 13.履歴処理区分
   ,iv_process_date_from            IN  DATE         -- 14.履歴処理日 FROM
   ,iv_process_date_to              IN  DATE         -- 15.履歴処理日 TO
 -- 2014/07/09 ADD START
   ,iv_vendor_code                  IN  VARCHAR2     -- 16.仕入先コード
 -- 2014/07/09 ADD END
   ,ov_errbuf                       OUT VARCHAR2     -- エラー・メッセージ           --# 固定 #
   ,ov_retcode                      OUT VARCHAR2     -- リターン・コード             --# 固定 #
   ,ov_errmsg                       OUT VARCHAR2     -- ユーザー・エラー・メッセージ --# 固定 #
  )
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
--
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
    --*********************************************
    --***      MD.050のフロー図を表す           ***
    --***      分岐と処理部の呼び出しを行う     ***
    --*********************************************
--
    -- ===============================
    -- 初期処理(A-1)
    -- ===============================
    init(
      iv_search_type                 => iv_search_type                 -- 1.検索区分 
     ,iv_machine_type                => iv_machine_type                -- 2.機器区分
     ,iv_object_code                 => iv_object_code                 -- 3.物件コード
     ,iv_object_status               => iv_object_status               -- 4.物件ステータス
     ,iv_department_code             => iv_department_code             -- 5.管理部門
     ,iv_manufacturer_name           => iv_manufacturer_name           -- 6.メーカ名
     ,iv_model                       => iv_model                       -- 7.機種
     ,iv_dclr_place                  => iv_dclr_place                  -- 8.申告地
     ,iv_date_placed_in_service_from => iv_date_placed_in_service_from -- 9.事業供用日 FROM
     ,iv_date_placed_in_service_to   => iv_date_placed_in_service_to   -- 10.事業供用日 TO
     ,iv_date_retired_from           => iv_date_retired_from           -- 11.除売却日 FROM
     ,iv_date_retired_to             => iv_date_retired_to             -- 12.除売却日 TO
     ,iv_process_type                => iv_process_type                -- 13.履歴処理区分
     ,iv_process_date_from           => iv_process_date_from           -- 14.履歴処理日 FROM
     ,iv_process_date_to             => iv_process_date_to             -- 15.履歴処理日 TO
 -- 2014/07/09 ADD START
     ,iv_vendor_code                 => iv_vendor_code                 -- 16.仕入先コード
 -- 2014/07/09 ADD END
     ,ov_errbuf                      => lv_errbuf                      -- エラー・メッセージ           --# 固定 #
     ,ov_retcode                     => lv_retcode                     -- リターン・コード             --# 固定 #
     ,ov_errmsg                      => lv_errmsg                      -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF (lv_retcode = cv_status_error)
    THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- 自販機物件情報抽出処理(A-2)、自販機物件CSV出力処理(A-3)
    -- ===============================
    output_csv(
      ov_errbuf          => lv_errbuf        -- エラー・メッセージ           --# 固定 #
     ,ov_retcode         => lv_retcode       -- リターン・コード             --# 固定 #
     ,ov_errmsg          => lv_errmsg        -- ユーザー・エラー・メッセージ --# 固定 #
    );
    -- 
    IF (lv_retcode = cv_status_error)
    THEN
      RAISE global_process_expt;
    ELSIF (lv_retcode = cv_status_warn)
    THEN
      RAISE no_data_warn_expt;
    END IF;
--
  EXCEPTION
    -- 対象データなし警告
    WHEN no_data_warn_expt THEN
      -- *** 任意で例外処理を記述する ****
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := lv_errbuf;
      ov_retcode := lv_retcode;
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
    errbuf                          OUT VARCHAR2     -- エラー・メッセージ  --# 固定 #
   ,retcode                         OUT VARCHAR2     -- リターン・コード    --# 固定 #
   ,iv_search_type                  IN  VARCHAR2     -- 1.検索区分 
   ,iv_machine_type                 IN  VARCHAR2     -- 2.機器区分
   ,iv_object_code                  IN  VARCHAR2     -- 3.物件コード
   ,iv_object_status                IN  VARCHAR2     -- 4.物件ステータス
   ,iv_department_code              IN  VARCHAR2     -- 5.管理部門
   ,iv_manufacturer_name            IN  VARCHAR2     -- 6.メーカ名
   ,iv_model                        IN  VARCHAR2     -- 7.機種
   ,iv_dclr_place                   IN  VARCHAR2     -- 8.申告地
   ,iv_date_placed_in_service_from  IN  VARCHAR2     -- 9.事業供用日 FROM
   ,iv_date_placed_in_service_to    IN  VARCHAR2     -- 10.事業供用日 TO
   ,iv_date_retired_from            IN  VARCHAR2     -- 11.除売却日 FROM
   ,iv_date_retired_to              IN  VARCHAR2     -- 12.除売却日 TO
   ,iv_process_type                 IN  VARCHAR2     -- 13.履歴処理区分
   ,iv_process_date_from            IN  VARCHAR2     -- 14.履歴処理日 FROM
   ,iv_process_date_to              IN  VARCHAR2     -- 15.履歴処理日 TO
 -- 2014/07/09 ADD START
   ,iv_vendor_code                  IN  VARCHAR2     -- 16.仕入先コード
 -- 2014/07/09 ADD END
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
    IF (lv_retcode = cv_status_error)
    THEN
      RAISE global_api_others_expt;
    END IF;
    --
--###########################  固定部 END   #############################
--
    -- ===============================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ===============================================
    submain(
       iv_search_type                 => iv_search_type                 -- 1.検索区分 
      ,iv_machine_type                => iv_machine_type                -- 2.機器区分
      ,iv_object_code                 => iv_object_code                 -- 3.物件コード
      ,iv_object_status               => iv_object_status               -- 4.物件ステータス
      ,iv_department_code             => iv_department_code             -- 5.管理部門
      ,iv_manufacturer_name           => iv_manufacturer_name           -- 6.メーカ名
      ,iv_model                       => iv_model                       -- 7.機種
      ,iv_dclr_place                  => iv_dclr_place                  -- 8.申告地
      ,iv_date_placed_in_service_from => TO_DATE(iv_date_placed_in_service_from,cv_format_std) -- 9.事業供用日 FROM
      ,iv_date_placed_in_service_to   => TO_DATE(iv_date_placed_in_service_to,cv_format_std)   -- 10.事業供用日 TO
      ,iv_date_retired_from           => TO_DATE(iv_date_retired_from,cv_format_std)           -- 11.除売却日 FROM
      ,iv_date_retired_to             => TO_DATE(iv_date_retired_to,cv_format_std)             -- 12.除売却日 TO
      ,iv_process_type                => iv_process_type                -- 13.履歴処理区分
      ,iv_process_date_from           => TO_DATE(iv_process_date_from,cv_format_std)           -- 14.履歴処理日 FROM
      ,iv_process_date_to             => TO_DATE(iv_process_date_to,cv_format_std)             -- 15.履歴処理日 TO
 -- 2014/07/09 ADD START
      ,iv_vendor_code                 => iv_vendor_code                 -- 16.仕入先コード
 -- 2014/07/09 ADD END
      ,ov_errbuf                      => lv_errbuf                      -- エラー・メッセージ           --# 固定 #
      ,ov_retcode                     => lv_retcode                     -- リターン・コード             --# 固定 #
      ,ov_errmsg                      => lv_errmsg                      -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    -- エラー出力
    IF (lv_retcode = cv_status_error)
    THEN
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errmsg --ユーザー・エラーメッセージ
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --エラーメッセージ
      );
    ELSIF (lv_retcode = cv_status_warn)
    THEN
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --エラーメッセージ
      );
    END IF;
--
    -- 空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
--
    --==================================================
    -- 対象件数出力
    --==================================================
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxccp
                    ,iv_name         => cv_msg_cff_90000
                    ,iv_token_name1  => cv_tkn_count
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
--
    --==================================================
    -- 成功件数出力
    --==================================================
    IF( lv_retcode = cv_status_error )
    THEN
      gn_normal_cnt := 0;
      gn_error_cnt  := 1;
    END IF;
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxccp
                    ,iv_name         => cv_msg_cff_90001
                    ,iv_token_name1  => cv_tkn_count
                    ,iv_token_value1 => TO_CHAR(gn_normal_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
--
    --==================================================
    -- エラー件数出力
    --==================================================
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxccp
                    ,iv_name         => cv_msg_cff_90002
                    ,iv_token_name1  => cv_tkn_count
                    ,iv_token_value1 => TO_CHAR(gn_error_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
--
    -- 空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
    --
    -- 終了メッセージ
    IF (lv_retcode = cv_status_normal)
    THEN
      lv_message_code := cv_msg_cff_90004;
    ELSIF(lv_retcode = cv_status_warn)
    THEN
      lv_message_code := cv_msg_cff_90005;
    ELSIF(lv_retcode = cv_status_error)
    THEN
      lv_message_code := cv_msg_cff_90006;
    END IF;
    --
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxccp
                    ,iv_name         => lv_message_code
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    -- ステータスセット
    retcode := lv_retcode;
    -- 終了ステータスがエラーの場合はROLLBACKする
    IF (retcode = cv_status_error)
    THEN
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
END XXCFF017A02C;
/
