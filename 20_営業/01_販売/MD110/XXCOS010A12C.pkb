CREATE OR REPLACE PACKAGE BODY XXCOS010A12C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2024. All rights reserved.
 *
 * Package Name     : XXCOS010A12C(body)
 * Description      : 最新状態のアドオン受注マテビューを参照し、標準受注OIFを作成します。
 * MD.050           : PaaSからの受注取込(MD050_COS_010_A12)
 * Version          : 1.3
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   初期処理(A-1)
 *  get_order_headers      アドオン受注ヘッダデータ抽出(A-2)
 *  ins_oif_order_header   受注ヘッダOIFテーブル登録(A-3)
 *  ins_oif_order_process  受注処理OIFテーブル登録(A-4)
 *  ins_upd_order_process  EBS受注処理情報登録と更新(A-5)
 *  get_order_lines        アドオン受注明細データ抽出(A-6)
 *  ins_oif_order_line     受注明細OIFテーブル登録(A-7)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2024/06/20    1.0   Y.Ryu            新規作成
 *  2024/12/16    1.1   A.Igimi          [ST0017]EBS受注処理情報登録と更新方法の修正
 *  2024/01/15    1.2   A.Igimi          [ST0017]受注インポートエラー対応
 *  2025/02/14    1.3   Y.Ooyama         STEP3システム統合テスト不具合対応(No.25)
 *
 *****************************************************************************************/
--
--#######################  固定グローバル定数宣言部 START   #######################
--
  --ステータス・コード
  cv_status_normal          CONSTANT VARCHAR2(1)  := xxccp_common_pkg.set_status_normal; --正常:0
  cv_status_warn            CONSTANT VARCHAR2(1)  := xxccp_common_pkg.set_status_warn;   --警告:1
  cv_status_error           CONSTANT VARCHAR2(1)  := xxccp_common_pkg.set_status_error;  --異常:2
  --WHOカラム
  cn_created_by             CONSTANT NUMBER       := fnd_global.user_id;           --CREATED_BY
  cd_creation_date          CONSTANT DATE         := SYSDATE;                      --CREATION_DATE
  cn_last_updated_by        CONSTANT NUMBER       := fnd_global.user_id;           --LAST_UPDATED_BY
  cd_last_update_date       CONSTANT DATE         := SYSDATE;                      --LAST_UPDATE_DATE
  cn_last_update_login      CONSTANT NUMBER       := fnd_global.login_id;          --LAST_UPDATE_LOGIN
  cn_request_id             CONSTANT NUMBER       := fnd_global.conc_request_id;   --REQUEST_ID
  cn_program_application_id CONSTANT NUMBER       := fnd_global.prog_appl_id;      --PROGRAM_APPLICATION_ID
  cn_program_id             CONSTANT NUMBER       := fnd_global.conc_program_id;   --PROGRAM_ID
  cd_program_update_date    CONSTANT DATE         := SYSDATE;                      --PROGRAM_UPDATE_DATE
--
  cv_msg_part               CONSTANT VARCHAR2(3)  := ' : ';
  cv_msg_cont               CONSTANT VARCHAR2(3)  := '.';
--
--################################  固定部 END   ##################################
--
--#######################  固定グローバル変数宣言部 START   #######################
--
  gv_out_msg                VARCHAR2(2000);
  gn_target_cnt             NUMBER;                    -- 対象件数
  gn_normal_cnt             NUMBER;                    -- 正常件数
  gn_error_cnt              NUMBER;                    -- エラー件数
  gn_warn_cnt               NUMBER;                    -- 警告件数
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
  cv_pkg_name               CONSTANT VARCHAR2(20)  := 'XXCOS010A12C';                 -- パッケージ名
  cv_appl_cos               CONSTANT VARCHAR2(10)  := 'XXCOS';                        -- アドオン：販物・販売OM領域
  cv_appl_ccp               CONSTANT VARCHAR2(10)  := 'XXCCP';                        -- アドオン：共通・IF領域
  -- メッセージコード
  cv_msg_00003              CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00003';             -- 対象データなしメッセージ
  cv_msg_00010              CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00010';             -- データ登録エラー
  cv_msg_00011              CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00011';             -- データ更新エラーメッセージ
  cv_msg_00013              CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00013';             -- データ抽出エラーメッセージ
  cv_msg_00069              CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00069';             -- 受注ヘッダ情報テーブル（文言）
  cv_msg_00070              CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00070';             -- 受注明細情報テーブル（文言）
  cv_msg_00132              CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00132';             -- 受注ヘッダーOIF（文言）
  cv_msg_00133              CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00133';             -- 受注明細OIF（文言）
  cv_msg_00134              CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00134';             -- 受注処理OIF（文言）
  cv_msg_16003              CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-16003';             -- 受注ヘッダスキップメッセージ
  cv_msg_16004              CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-16004';             -- 受注明細スキップメッセージ
  cv_msg_16005              CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-16005';             -- 受注ヘッダエラーメッセージ
  cv_msg_16006              CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-16006';             -- 受注明細エラーメッセージ
  cv_msg_16007              CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-16007';             -- アドオン受注ヘッダマテライズドビュー（文言）
  cv_msg_16008              CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-16008';             -- アドオン受注明細マテライズドビュー（文言）
  cv_msg_16009              CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-16009';             -- EBS受注処理情報（文言）
  cv_msg_16011              CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-16011';             -- 受注ヘッダクローズ済メッセージ
  cv_msg_16012              CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-16012';             -- 受注明細クローズ済メッセージ
  cv_msg_16013              CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-16013';             -- 受注明細番号取得エラーメッセージ
  --
  cv_msg_90000              CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-90000';             -- 対象件数メッセージ
  cv_msg_90001              CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-90001';             -- 成功件数メッセージ
  cv_msg_90002              CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-90002';             -- エラー件数メッセージ
  cv_msg_90008              CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-90008';             -- コンカレント入力パラメータなし
  cv_normal_msg             CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-90004';             -- 正常終了メッセージ
  cv_warn_msg               CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-90005';             -- 警告終了メッセージ
  cv_error_msg              CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-90006';             -- エラー終了全ロールバックメッセージ
--
  -- トークン
  cv_tkn_table_name         CONSTANT VARCHAR2(20)  := 'TABLE_NAME';                   -- テーブル名
  cv_tkn_key_data           CONSTANT VARCHAR2(20)  := 'KEY_DATA';                     -- キー情報
  cv_tkn_count              CONSTANT VARCHAR2(20)  := 'COUNT';                        -- 対象件数
  cv_tkn_header_id          CONSTANT VARCHAR2(20)  := 'HEADER_ID';                    -- アドオンヘッダID
  cv_tkn_header_status      CONSTANT VARCHAR2(20)  := 'HEADER_STATUS';                -- 受注ステータス（ヘッダ）
  cv_tkn_line_id            CONSTANT VARCHAR2(20)  := 'LINE_ID';                      -- アドオン明細ID
  cv_tkn_line_status        CONSTANT VARCHAR2(20)  := 'LINE_STATUS';                  -- 受注ステータス（明細）
--
  -- その他定数
  cv_trans_order            CONSTANT VARCHAR2(50)  := 'ORDER';                        -- 取引タイプコード
  cv_trans_line             CONSTANT VARCHAR2(50)  := 'LINE';                         -- 取引タイプコード(明細)
  cv_ctgry_mixed            CONSTANT VARCHAR2(50)  := 'MIXED';                        -- 受注カテゴリ
  cv_ctgry_order            CONSTANT VARCHAR2(50)  := 'ORDER';                        -- 受注カテゴリ
  cv_op_insert              CONSTANT VARCHAR2(50)  := 'INSERT';                       -- オペレーション：新規
  cv_op_update              CONSTANT VARCHAR2(50)  := 'UPDATE';                       -- オペレーション：更新
  cv_sts_booked             CONSTANT VARCHAR2(50)  := 'BOOKED';                       -- 受注ステータス：記帳済
  cv_sts_cancelled          CONSTANT VARCHAR2(50)  := 'CANCELLED';                    -- 受注ステータス：取消済
  cv_sts_closed             CONSTANT VARCHAR2(50)  := 'CLOSED';                       -- 受注ステータス：クローズ済
  cv_book_order             CONSTANT VARCHAR2(10)  := 'BOOK_ORDER';                   -- オペレーション：記帳
--
  cn_zero                   CONSTANT NUMBER        :=  0;                             -- 抽出対象データ0件
  cv_flg_y                  CONSTANT VARCHAR2(1)   := 'Y';                            -- 'Y'
  cv_flg_n                  CONSTANT VARCHAR2(1)   := 'N';                            -- 'N'
  cv_flg_1                  CONSTANT VARCHAR2(1)   := '1';                            -- 1：登録
  cv_flg_2                  CONSTANT VARCHAR2(1)   := '2';                            -- 2：更新
-- Ver1.3 Add Start
  cv_flg_3                  CONSTANT VARCHAR2(1)   := '3';                            -- 3：ヘッダ取消
-- Ver1.3 Add End
  cv_stand_date             CONSTANT VARCHAR(25)   := 'YYYY/MM/DD HH24:MI:SS';
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
--
  gn_l_target_cnt           NUMBER;                             -- 対象件数（明細用）
  gn_line_number            NUMBER;                             -- 受注明細番号変数
  --
  gv_skip_flg               VARCHAR2(1);                        -- 受注スキップフラグ
--
  -- アドオン受注ヘッダ
  CURSOR order_headers_cur
  IS
    SELECT
           xoohm.header_id                header_id                 -- アドオンヘッダID
          ,xoohm.order_number             order_number              -- アドオン受注番号
          ,xoohm.org_id                   org_id                    -- 組織ID
          ,xoohm.order_source_id          order_source_id           -- 受注ソースID
          ,xoohm.order_type_id            order_type_id             -- 受注タイプID
          ,xoohm.ordered_date             ordered_date              -- 受注日
          ,xoohm.cust_number              customer_number           -- 顧客コード
          ,xoohm.cust_po_number           customer_po_number        -- 顧客発注番号
          ,xoohm.request_date             request_date              -- 納品予定日
          ,xoohm.price_list_id            price_list_id             -- 価格表ID
          ,xoohm.flow_status_code         flow_status_code          -- 受注ステータス
          ,xoohm.salesrep_id              salesrep_id               -- 営業担当ID
          ,xoohm.sold_to_org_id           sold_to_org_id            -- 売上先顧客ID
          ,xoohm.shipping_instructions    shipping_instructions     -- 出荷指示
          ,xoohm.payment_term_id          payment_term_id           -- 支払条件ID
          ,xoohm.context                  context                   -- コンテキスト
          ,xoohm.attribute5               attribute5                -- 伝票区分
          ,xoohm.attribute12              attribute12               -- 検索用拠点
          ,xoohm.attribute13              attribute13               -- 時間指定(From)
          ,xoohm.attribute14              attribute14               -- 時間指定(To)
          ,xoohm.attribute15              attribute15               -- 伝票No
          ,xoohm.attribute16              attribute16               -- 枝番
          ,xoohm.attribute17              attribute17               -- 小口数(伊藤園)※ｶﾝﾏ区切
          ,xoohm.attribute18              attribute18               -- 小口数(橋場　)※ｶﾝﾏ区切
          ,xoohm.attribute19              attribute19               -- オーダーNo
          ,xoohm.attribute20              attribute20               -- 分類区分
          ,xoohm.global_attribute1        global_attribute1         -- 共通帳票様式用納品書発行フラグエリア
          ,xoohm.global_attribute3        global_attribute3         -- 情報区分
          ,xoohm.global_attribute4        global_attribute4         -- 受注No.(HHT)
          ,xoohm.global_attribute5        global_attribute5         -- 発生元区分
          ,xoohm.orig_sys_document_ref    orig_sys_document_ref     -- 受注関連番号(EDI)
          ,xoohm.return_reason_code       return_reason_code        -- 取消事由コード
          ,CASE WHEN
                  (SELECT COUNT(1)
                   FROM   oe_order_headers_all  ooha  -- 受注ヘッダ
                   WHERE  ooha.order_source_id       = xoohm.order_source_id
                   AND    ooha.orig_sys_document_ref = xoohm.orig_sys_document_ref
                  ) > 0
                THEN cv_op_update
                ELSE cv_op_insert
           END                            operation_code            -- オペレーション
          ,CASE WHEN xoohm.flow_status_code = cv_sts_cancelled
                THEN cv_flg_y ELSE NULL
                END                       cancelled_flag            -- 取消フラグ
    FROM   xxcos_oe_order_headers_mv xoohm        -- アドオン受注ヘッダマテライズドビュー
    WHERE  xoohm.booked_date IS NOT NULL
    ORDER BY
      xoohm.header_id;
--
  -- アドオン受注ヘッダ テーブルタイプ定義
  TYPE  g_tab_order_headers             IS TABLE OF order_headers_cur%ROWTYPE
    INDEX BY PLS_INTEGER;
--
  -- アドオン受注ヘッダテーブル用変数（カーソルレコード型）
  gt_order_headers                      g_tab_order_headers;
--
  -- アドオン受注明細
  CURSOR order_lines_cur(
    it_header_id IN xxcos_oe_order_lines_mv.header_id%TYPE
  )
  IS
    SELECT
           xoolm.line_id                  line_id                   -- アドオン明細ID
          ,xoolm.header_id                header_id                 -- アドオンヘッダID
          ,xoolm.org_id                   org_id                    -- 組織ID
          ,xoolm.line_type_id             line_type_id              -- 明細タイプID
          ,xoolm.line_number              line_number               -- 明細番号
          ,xoolm.order_source_id          order_source_id           -- 受注ソースID
          ,xoolm.ordered_item             inventory_item            -- 品目コード
          ,xoolm.request_date             request_date              -- 納品予定日
          ,CASE WHEN xoolm.flow_status_code = cv_sts_cancelled
                THEN cn_zero ELSE xoolm.ordered_quantity
                END                       ordered_quantity          -- 数量
          ,xoolm.order_quantity_uom       order_quantity_uom        -- 単位
          ,xoolm.price_list_id            price_list_id             -- 価格表ID
          ,xoolm.payment_term_id          payment_term_id           -- 支払条件ID
          ,xoolm.orig_sys_document_ref    orig_sys_document_ref     -- 受注関連番号(EDI)
          ,xoolm.orig_sys_line_ref        orig_sys_line_ref         -- 受注関連明細番号(EDI)
          ,xoolm.unit_list_price          unit_list_price           -- 単価
          ,xoolm.unit_selling_price       unit_selling_price        -- 販売単価
          ,xoolm.flow_status_code         flow_status_code          -- 受注ステータス
          ,xoolm.subinventory             subinventory              -- 保管場所
          ,xoolm.packing_instructions     packing_instructions      -- 出荷依頼番号
          ,xoolm.return_reason_code       return_reason_code        -- 取消事由コード
          ,xoolm.cust_po_number           customer_po_number        -- 顧客発注番号
          ,xoolm.customer_line_number     customer_line_number      -- 顧客明細番号
          ,xoolm.calculate_price_flag     calculate_price_flag      -- 価格計算フラグ
          ,xoolm.schedule_ship_date       schedule_ship_date        -- 予定出荷日
          ,xoolm.salesrep_id              salesrep_id               -- 営業担当ID
          ,xoolm.inventory_item_id        inventory_item_id         -- 品目ID
          ,xoolm.sold_to_org_id           sold_to_org_id            -- 売上先顧客ID
          ,xoolm.ship_from_org_id         ship_from_org_id          -- 出荷元在庫組織ID
          ,xoolm.cancelled_quantity       cancelled_quantity        -- 取消数量
          ,xoolm.context                  context                   -- コンテキスト
          ,xoolm.attribute4               attribute4                -- 検収日
          ,xoolm.attribute5               attribute5                -- 売上区分
          ,xoolm.attribute6               attribute6                -- 子コード
          ,xoolm.attribute7               attribute7                -- 備考
          ,xoolm.attribute8               attribute8                -- 明細_時間指定(From)
          ,xoolm.attribute9               attribute9                -- 明細_時間指定(To)
          ,xoolm.attribute10              attribute10               -- 売単価
          ,xoolm.attribute11              attribute11               -- 掛%
          ,xoolm.attribute12              attribute12               -- 送り状発行番号
          ,xoolm.global_attribute1        global_attribute1         -- 受注一覧出力日
          ,xoolm.global_attribute2        global_attribute2         -- 納品書発行フラグエリア
          ,xoolm.global_attribute3        global_attribute3         -- 受注明細ID(分割前)
          ,xoolm.global_attribute4        global_attribute4         -- 受注明細参照
          ,xoolm.global_attribute5        global_attribute5         -- 販売実績連携フラグ
          ,xoolm.global_attribute6        global_attribute6         -- 受注一覧ファイル出力日
          ,xoolm.global_attribute7        global_attribute7         -- HHT受注送信フラグ
          ,xoolm.global_attribute9        global_attribute9         -- 明細番号(分割前)
          ,TO_CHAR(
             xoolm.last_update_date, cv_stand_date
           )                              global_attribute10        -- PaaS明細最終更新日(UTC)
          ,CASE WHEN
                  (SELECT COUNT(1)
                   FROM   oe_order_lines_all    oola  -- 受注明細
                   WHERE  oola.order_source_id       = xoolm.order_source_id
                   AND    oola.orig_sys_document_ref = xoolm.orig_sys_document_ref
                   AND    oola.global_attribute8     = xoolm.line_number
                  ) > 0
                THEN cv_op_update
                ELSE cv_op_insert
           END                            operation_code            -- オペレーション
    FROM   xxcos_oe_order_lines_mv xoolm          -- アドオン受注明細マテライズドビュー
    WHERE  xoolm.header_id = it_header_id
    ORDER BY
      xoolm.line_number;
--
  -- アドオン受注明細 テーブルタイプ定義
  TYPE  g_tab_order_lines               IS TABLE OF order_lines_cur%ROWTYPE
    INDEX BY PLS_INTEGER;
--
  -- アドオン受注明細情報テーブル用変数（カーソルレコード型）
  gt_order_lines                        g_tab_order_lines;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100) := 'init';           -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf               VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode              VARCHAR2(1);     -- リターン・コード
    lv_errmsg               VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    lv_function_id          VARCHAR2(30);               -- 機能ID
    ld_pre_process_date     DATE;                       -- 前回処理日時
    ld_pre_process_date_utc DATE;                       -- 前回処理日時(UTC)
    lv_date1                VARCHAR2(30);
    lv_date2                VARCHAR2(30);
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ==============================================================
    -- コンカレント入力パラメータなしメッセージ出力
    -- ==============================================================
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application => cv_appl_ccp
                    , iv_name        => cv_msg_90008
                  );
    -- メッセージ出力
    fnd_file.put_line(
        which  => fnd_file.output
      , buff   => gv_out_msg
    );
    -- ログ出力
    fnd_file.put_line(
         which  => fnd_file.log
        ,buff   => gv_out_msg
    );
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
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
   * Procedure Name   : get_order_headers
   * Description      : アドオン受注ヘッダデータ抽出(A-2)
   ***********************************************************************************/
  PROCEDURE get_order_headers(
    on_target_cnt OUT NOCOPY NUMBER,       --   対象データ件数
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100) := 'get_order_headers'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf               VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode              VARCHAR2(1);     -- リターン・コード
    lv_errmsg               VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    ln_idx                  NUMBER;
    -- *** ローカル・レコード ***
    l_headers_rec  order_headers_cur%ROWTYPE;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- OUTパラメータ初期化
    on_target_cnt := 0;
    --
    ln_idx        := 0;
--
    BEGIN
      -- カーソルオープン
      OPEN order_headers_cur;
--
      <<headers_loop>>
      LOOP
--
        FETCH order_headers_cur INTO l_headers_rec;
        EXIT WHEN order_headers_cur%NOTFOUND;
--
        -- カウントアップ
        ln_idx := ln_idx + 1;
        ------------------------------------
        -- アドオン受注ヘッダデータ配列設定
        ------------------------------------
        gt_order_headers(ln_idx).header_id                := l_headers_rec.header_id;                 -- ヘッダID
        gt_order_headers(ln_idx).order_number             := l_headers_rec.order_number;              -- アドオン受注番号
        gt_order_headers(ln_idx).org_id                   := l_headers_rec.org_id;                    -- 組織ID
        gt_order_headers(ln_idx).order_source_id          := l_headers_rec.order_source_id;           -- 受注ソースID
        gt_order_headers(ln_idx).order_type_id            := l_headers_rec.order_type_id;             -- 受注タイプID
        gt_order_headers(ln_idx).ordered_date             := l_headers_rec.ordered_date;              -- 受注日
        gt_order_headers(ln_idx).customer_number          := l_headers_rec.customer_number;           -- 顧客コード
        gt_order_headers(ln_idx).customer_po_number       := l_headers_rec.customer_po_number;        -- 顧客発注番号
        gt_order_headers(ln_idx).request_date             := l_headers_rec.request_date;              -- 納品予定日
        gt_order_headers(ln_idx).price_list_id            := l_headers_rec.price_list_id;             -- 価格表ID
        gt_order_headers(ln_idx).flow_status_code         := l_headers_rec.flow_status_code;          -- 受注ステータス
        gt_order_headers(ln_idx).salesrep_id              := l_headers_rec.salesrep_id;               -- 営業担当ID
        gt_order_headers(ln_idx).sold_to_org_id           := l_headers_rec.sold_to_org_id;            -- 売上先顧客ID
        gt_order_headers(ln_idx).shipping_instructions    := l_headers_rec.shipping_instructions;     -- 出荷指示
        gt_order_headers(ln_idx).payment_term_id          := l_headers_rec.payment_term_id;           -- 支払条件ID
        gt_order_headers(ln_idx).context                  := l_headers_rec.context;                   -- コンテキスト
        gt_order_headers(ln_idx).attribute5               := l_headers_rec.attribute5;                -- 伝票区分
        gt_order_headers(ln_idx).attribute12              := l_headers_rec.attribute12;               -- 検索用拠点
        gt_order_headers(ln_idx).attribute13              := l_headers_rec.attribute13;               -- 時間指定(From)
        gt_order_headers(ln_idx).attribute14              := l_headers_rec.attribute14;               -- 時間指定(To)
        gt_order_headers(ln_idx).attribute15              := l_headers_rec.attribute15;               -- 伝票No
        gt_order_headers(ln_idx).attribute16              := l_headers_rec.attribute16;               -- 枝番
        gt_order_headers(ln_idx).attribute17              := l_headers_rec.attribute17;               -- 小口数(伊藤園)※ｶﾝﾏ区切
        gt_order_headers(ln_idx).attribute18              := l_headers_rec.attribute18;               -- 小口数(橋場　)※ｶﾝﾏ区切
        gt_order_headers(ln_idx).attribute19              := l_headers_rec.attribute19;               -- オーダーNo
        gt_order_headers(ln_idx).attribute20              := l_headers_rec.attribute20;               -- 分類区分
        gt_order_headers(ln_idx).global_attribute1        := l_headers_rec.global_attribute1;         -- 共通帳票様式用納品書発行フラグエリア
        gt_order_headers(ln_idx).global_attribute3        := l_headers_rec.global_attribute3;         -- 情報区分
        gt_order_headers(ln_idx).global_attribute4        := l_headers_rec.global_attribute4;         -- 受注No.(HHT)
        gt_order_headers(ln_idx).global_attribute5        := l_headers_rec.global_attribute5;         -- 発生元区分
        gt_order_headers(ln_idx).orig_sys_document_ref    := l_headers_rec.orig_sys_document_ref;     -- 受注関連番号(EDI)
        gt_order_headers(ln_idx).return_reason_code       := l_headers_rec.return_reason_code;        -- 取消事由コード
        gt_order_headers(ln_idx).operation_code           := l_headers_rec.operation_code;            -- オペレーション
        gt_order_headers(ln_idx).cancelled_flag           := l_headers_rec.cancelled_flag;            -- 取消フラグ
--
      END LOOP headers_loop;
--
      -- カーソルクローズ
      CLOSE order_headers_cur;
--
    EXCEPTION
      -- データ抽出エラー
      WHEN OTHERS THEN
        lv_errmsg  := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appl_cos
                       , iv_name         => cv_msg_00013
                       , iv_token_name1  => cv_tkn_table_name
                       , iv_token_value1 => cv_msg_16007
                       , iv_token_name2  => cv_tkn_key_data
                       , iv_token_value2 => cv_msg_part||SQLERRM
                      );
        lv_errbuf  := lv_errmsg;
        RAISE global_process_expt;
    END;
--
    -- OUTパラメータ設定
    on_target_cnt := ln_idx;
--
    -- 対象データなしの場合
    IF ( on_target_cnt = cn_zero )
    THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_cos
                     , iv_name         => cv_msg_00003
                    );
      lv_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg, 1, 5000);
      -- メッセージ出力
      fnd_file.put_line(
        which  => fnd_file.output,
        buff   => lv_errmsg
      );
      -- ログ出力
      fnd_file.put_line(
        which  => fnd_file.log,
        buff   => lv_errbuf
      );
    END IF;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      -- カーソルクローズ
      IF ( order_headers_cur%ISOPEN ) THEN
        CLOSE order_headers_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      -- カーソルクローズ
      IF ( order_headers_cur%ISOPEN ) THEN
        CLOSE order_headers_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      -- カーソルクローズ
      IF ( order_headers_cur%ISOPEN ) THEN
        CLOSE order_headers_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_order_headers;
--
  /**********************************************************************************
   * Procedure Name   : ins_oif_order_header
   * Description      : 受注ヘッダOIFテーブル登録(A-3)
   ***********************************************************************************/
  PROCEDURE ins_oif_order_header(
     in_h_idx      IN  NUMBER       --   受注ヘッダデータインデクス
    ,ov_errbuf     OUT VARCHAR2     --   エラー・メッセージ                  --# 固定 #
    ,ov_retcode    OUT VARCHAR2     --   リターン・コード                    --# 固定 #
    ,ov_errmsg     OUT VARCHAR2     --   ユーザー・エラー・メッセージ        --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_oif_order_header'; -- プログラム名
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
    lt_flow_status_code  oe_order_headers_all.flow_status_code%TYPE; -- ステータス（受注ヘッダ）
    lt_line_number_max   oe_order_lines_all.line_number%TYPE;        -- 明細番号マックス
-- ************** Ver1.2 A.Igimi ADD START *************** --
    ln_headers_iface_count  NUMBER;  -- 受注ヘッダOIF存在チェック
    ln_lines_iface_count    NUMBER;  -- 受注明細OIF存在チェック
    ln_actions_iface_count  NUMBER;  -- 受注処理OIF存在チェック
-- ************** Ver1.2 A.Igimi ADD  END  *************** --
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- 受注ステータスが「BOOKED：記帳済」、「CANCELLED：取消済」以外の場合
    IF ( gt_order_headers(in_h_idx).flow_status_code <> cv_sts_booked )
      AND ( gt_order_headers(in_h_idx).flow_status_code <> cv_sts_cancelled )
    THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_cos
                     , iv_name         => cv_msg_16005
                     , iv_token_name1  => cv_tkn_header_id        -- アドオンヘッダID
                     , iv_token_value1 => gt_order_headers(in_h_idx).header_id
                     , iv_token_name2  => cv_tkn_header_status    -- 受注ステータス
                     , iv_token_value2 => gt_order_headers(in_h_idx).flow_status_code
                    );
      lv_errbuf  := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- 取消済受注データの新規登録スキップ
    IF ( gt_order_headers(in_h_idx).operation_code = cv_op_insert )
      AND ( gt_order_headers(in_h_idx).flow_status_code = cv_sts_cancelled )
    THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_cos
                     , iv_name         => cv_msg_16003
                     , iv_token_name1  => cv_tkn_header_id        -- アドオンヘッダID
                     , iv_token_value1 => gt_order_headers(in_h_idx).header_id
                    );
      -- メッセージ出力
      fnd_file.put_line(
          which  => fnd_file.output
        , buff   => lv_errmsg
      );
      -- ログ出力
      fnd_file.put_line(
           which  => fnd_file.log
          ,buff   => lv_errmsg
      );
      -- 受注スキップフラグを設定
      gv_skip_flg := cv_flg_y;
-- Ver1.3 Del Start
--      gn_warn_cnt := gn_warn_cnt + 1;
-- Ver1.3 Del End
      RETURN;
    END IF;
--
    -- クローズ済受注データの更新スキップ
    IF ( gt_order_headers(in_h_idx).operation_code = cv_op_update )
    THEN
      -- 受注ヘッダのステータス取得
      BEGIN
--
        SELECT
               ooha.flow_status_code               flow_status_code     -- ステータス
              ,(SELECT MAX(line_number)
                FROM   oe_order_lines_all
                WHERE  header_id = ooha.header_id) line_number_max      -- 明細番号マックス
        INTO   lt_flow_status_code
              ,lt_line_number_max
        FROM   oe_order_headers_all    ooha         -- 受注ヘッダテーブル
        WHERE  ooha.order_source_id       = gt_order_headers(in_h_idx).order_source_id
        AND    ooha.orig_sys_document_ref = gt_order_headers(in_h_idx).orig_sys_document_ref;
--
      EXCEPTION
        -- 存在しない場合
        WHEN NO_DATA_FOUND THEN
          lt_flow_status_code  := NULL;
--
      END;
      -- ステータス変数がNULL以外かつステータス変数が「CLOSED：クローズ済」の場合
      IF ( lt_flow_status_code IS NOT NULL )
        AND ( lt_flow_status_code = cv_sts_closed )
      THEN
          lv_errmsg    := xxccp_common_pkg.get_msg(
                           iv_application  => cv_appl_cos
                         , iv_name         => cv_msg_16011
                         , iv_token_name1  => cv_tkn_header_id        -- アドオンヘッダID
                         , iv_token_value1 => gt_order_headers(in_h_idx).header_id
                        );
        -- メッセージ出力
        fnd_file.put_line(
            which  => fnd_file.output
          , buff   => lv_errmsg
        );
        -- ログ出力
        fnd_file.put_line(
             which  => fnd_file.log
            ,buff   => lv_errmsg
        );
        -- 受注スキップフラグを設定
        gv_skip_flg := cv_flg_y;
        gn_warn_cnt := gn_warn_cnt + 1;
        RETURN;
      END IF;
    END IF;
--
    -- 受注明細番号変数の初期化
    IF ( gt_order_headers(in_h_idx).operation_code = cv_op_update )
    THEN
      gn_line_number := lt_line_number_max;
    ELSE
      gn_line_number := cn_zero;
    END IF;
--
-- ************** Ver1.2 A.Igimi ADD START *************** --
    ------------------------------------
    -- 受注ヘッダOIF 重複レコード削除
    ------------------------------------
    -- 受注ヘッダOIF 存在チェック
    BEGIN
      SELECT count(*)
      INTO   ln_headers_iface_count
      FROM   oe_headers_iface_all
      WHERE  orig_sys_document_ref = gt_order_headers(in_h_idx).orig_sys_document_ref;     -- 外部システム受注番号
--
    -- 受注ヘッダOIF 重複レコード削除
      IF ln_headers_iface_count = cn_zero THEN
        NULL;
      ELSE 
        DELETE FROM oe_headers_iface_all
        WHERE  orig_sys_document_ref = gt_order_headers(in_h_idx).orig_sys_document_ref;     -- 外部システム受注番号
      END IF;
--
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := SQLERRM;
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
    ------------------------------------
    -- 受注明細OIF 重複レコード削除
    ------------------------------------
    -- 受注明細OIF 存在チェック
    BEGIN
      SELECT count(*)
      INTO   ln_lines_iface_count
      FROM   oe_lines_iface_all
      WHERE  orig_sys_document_ref = gt_order_headers(in_h_idx).orig_sys_document_ref;     -- 外部システム受注番号
--
    -- 受注明細OIF 重複レコード削除
      IF ln_lines_iface_count = cn_zero THEN
        NULL;
      ELSE 
        DELETE FROM oe_lines_iface_all
        WHERE  orig_sys_document_ref = gt_order_headers(in_h_idx).orig_sys_document_ref;     -- 外部システム受注番号
      END IF;
--
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := SQLERRM;
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
    ------------------------------------
    -- 受注処理OIF 重複レコード削除
    ------------------------------------
    -- 受注処理OIF 存在チェック
    BEGIN
      SELECT count(*)
      INTO   ln_actions_iface_count
      FROM   oe_actions_iface_all
      WHERE  orig_sys_document_ref = gt_order_headers(in_h_idx).orig_sys_document_ref;     -- 外部システム受注番号
--
    -- 受注処理OIF 重複レコード削除
      IF ln_actions_iface_count = cn_zero THEN
        NULL;
      ELSE 
        DELETE FROM oe_actions_iface_all
        WHERE  orig_sys_document_ref = gt_order_headers(in_h_idx).orig_sys_document_ref;     -- 外部システム受注番号
      END IF;
--
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := SQLERRM;
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
-- ************** Ver1.2 A.Igimi ADD  END  *************** --
--
    BEGIN
--
      -- 受注ヘッダOIFテーブル登録
      INSERT INTO oe_headers_iface_all(
        org_id                    -- 組織ID
       ,order_source_id           -- 受注ソースID
       ,order_type_id             -- 受注タイプID
       ,ordered_date              -- 受注日
       ,customer_number           -- 顧客コード
       ,customer_po_number        -- 顧客発注番号
       ,request_date              -- 納品予定日
       ,price_list_id             -- 価格表ID
       ,salesrep_id               -- 営業担当ID
       ,sold_to_org_id            -- 売上先顧客ID
       ,shipping_instructions     -- 出荷指示
       ,payment_term_id           -- 支払条件ID
       ,context                   -- コンテキスト
       ,attribute5                -- 伝票区分
       ,attribute12               -- 検索用拠点
       ,attribute13               -- 時間指定(From)
       ,attribute14               -- 時間指定(To)
       ,attribute15               -- 伝票No
       ,attribute16               -- 枝番
       ,attribute17               -- 小口数(伊藤園)※ｶﾝﾏ区切
       ,attribute18               -- 小口数(橋場　)※ｶﾝﾏ区切
       ,attribute19               -- オーダーNo
       ,attribute20               -- 分類区分
       ,global_attribute1         -- 共通帳票様式用納品書発行フラグエリア
       ,global_attribute3         -- 情報区分
       ,global_attribute4         -- 受注No.(HHT)
       ,global_attribute5         -- 発生元区分
       ,orig_sys_document_ref     -- 外部システム受注番号
       ,change_reason             -- 変更事由
       ,global_attribute6         -- PaaS側受注番号
       ,operation_code            -- オペレーション
       ,cancelled_flag            -- 取消フラグ
       ,created_by                -- 作成者
       ,creation_date             -- 作成日
       ,last_updated_by           -- 最終更新者
       ,last_update_date          -- 最終更新日
       ,last_update_login         -- 最終更新ログイン
       ,request_id                -- 要求ID
       ,program_application_id    -- コンカレント・プログラム・アプリケーションID
       ,program_id                -- コンカレント・プログラムID
       ,program_update_date       -- プログラム更新日
      )
      VALUES
      (
        gt_order_headers(in_h_idx).org_id                    -- 組織ID
       ,gt_order_headers(in_h_idx).order_source_id           -- 受注ソースID
       ,gt_order_headers(in_h_idx).order_type_id             -- 受注タイプID
       ,gt_order_headers(in_h_idx).ordered_date              -- 受注日
       ,gt_order_headers(in_h_idx).customer_number           -- 顧客コード
       ,gt_order_headers(in_h_idx).customer_po_number        -- 顧客発注番号
       ,gt_order_headers(in_h_idx).request_date              -- 納品予定日
       ,gt_order_headers(in_h_idx).price_list_id             -- 価格表ID
       ,gt_order_headers(in_h_idx).salesrep_id               -- 営業担当ID
       ,gt_order_headers(in_h_idx).sold_to_org_id            -- 売上先顧客ID
       ,gt_order_headers(in_h_idx).shipping_instructions     -- 出荷指示
       ,gt_order_headers(in_h_idx).payment_term_id           -- 支払条件ID
       ,gt_order_headers(in_h_idx).context                   -- コンテキスト
       ,gt_order_headers(in_h_idx).attribute5                -- 伝票区分
       ,gt_order_headers(in_h_idx).attribute12               -- 検索用拠点
       ,gt_order_headers(in_h_idx).attribute13               -- 時間指定(From)
       ,gt_order_headers(in_h_idx).attribute14               -- 時間指定(To)
       ,gt_order_headers(in_h_idx).attribute15               -- 伝票No
       ,gt_order_headers(in_h_idx).attribute16               -- 枝番
       ,gt_order_headers(in_h_idx).attribute17               -- 小口数(伊藤園)※ｶﾝﾏ区切
       ,gt_order_headers(in_h_idx).attribute18               -- 小口数(橋場　)※ｶﾝﾏ区切
       ,gt_order_headers(in_h_idx).attribute19               -- オーダーNo
       ,gt_order_headers(in_h_idx).attribute20               -- 分類区分
       ,gt_order_headers(in_h_idx).global_attribute1         -- 共通帳票様式用納品書発行フラグエリア
       ,gt_order_headers(in_h_idx).global_attribute3         -- 情報区分
       ,gt_order_headers(in_h_idx).global_attribute4         -- 受注No.(HHT)
       ,gt_order_headers(in_h_idx).global_attribute5         -- 発生元区分
       ,gt_order_headers(in_h_idx).orig_sys_document_ref     -- 受注関連番号(EDI)
       ,gt_order_headers(in_h_idx).return_reason_code        -- 取消事由コード
       ,gt_order_headers(in_h_idx).order_number              -- アドオン受注番号
       ,gt_order_headers(in_h_idx).operation_code            -- オペレーション
       ,gt_order_headers(in_h_idx).cancelled_flag            -- 取消フラグ
       ,cn_created_by                                        -- 作成者
       ,cd_creation_date                                     -- 作成日
       ,cn_last_updated_by                                   -- 最終更新者
       ,cd_last_update_date                                  -- 最終更新日
       ,cn_last_update_login                                 -- 最終更新ログイン
       ,NULL                                                 -- 要求ID
       ,cn_program_application_id                            -- コンカレント・プログラム・アプリケーションID
       ,cn_program_id                                        -- コンカレント・プログラムID
       ,cd_program_update_date                               -- プログラム更新日
      );
--
    EXCEPTION
      WHEN OTHERS THEN
        --メッセージ編集
        lv_errmsg  := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appl_cos
                       , iv_name         => cv_msg_00010
                       , iv_token_name1  => cv_tkn_table_name  -- テーブル
                       , iv_token_value1 => cv_msg_00132       -- テーブル名
                       , iv_token_name2  => cv_tkn_key_data    -- キーデータ
                       , iv_token_value2 => SQLERRM            -- SQLエラーメッセージ
                      );
        lv_errbuf  := lv_errmsg;
        RAISE global_process_expt;
    END;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
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
--#####################################  固定部 END   ##########################################
--
  END ins_oif_order_header;
--
  /**********************************************************************************
   * Procedure Name   : ins_oif_order_process
   * Description      : 受注処理OIFテーブル登録(A-4)
   ***********************************************************************************/
  PROCEDURE ins_oif_order_process(
     in_h_idx      IN  NUMBER       --   アドオン受注ヘッダデータインデクス
    ,ov_errbuf     OUT VARCHAR2     --   エラー・メッセージ                  --# 固定 #
    ,ov_retcode    OUT VARCHAR2     --   リターン・コード                    --# 固定 #
    ,ov_errmsg     OUT VARCHAR2     --   ユーザー・エラー・メッセージ        --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_oif_order_process'; -- プログラム名
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
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- オペレーションが「INSERT」、受注ステータスが「BOOKED：記帳済」の場合
    IF ( gt_order_headers(in_h_idx).operation_code = cv_op_insert )
      AND ( gt_order_headers(in_h_idx).flow_status_code = cv_sts_booked )
    THEN
--
      BEGIN
--
        -- 受注処理OIFテーブル登録
        INSERT INTO oe_actions_iface_all(
          order_source_id        -- インポートソースID
         ,orig_sys_document_ref  -- 外部システム受注番号
         ,operation_code         -- オペレーションコード
        )
        VALUES
        (
          gt_order_headers(in_h_idx).order_source_id        -- 受注ソースID
         ,gt_order_headers(in_h_idx).orig_sys_document_ref  -- 受注関連番号(EDI)
         ,cv_book_order                                     -- オペレーション
        );
 --
      EXCEPTION
        WHEN OTHERS THEN
          --メッセージ編集
          lv_errmsg  := xxccp_common_pkg.get_msg(
                           iv_application  => cv_appl_cos
                         , iv_name         => cv_msg_00010
                         , iv_token_name1  => cv_tkn_table_name  -- テーブル
                         , iv_token_value1 => cv_msg_00134       -- テーブル名
                         , iv_token_name2  => cv_tkn_key_data    -- キーデータ
                         , iv_token_value2 => SQLERRM            -- SQLエラーメッセージ
                        );
          lv_errbuf  := lv_errmsg;
          RAISE global_process_expt;
      END;
    END IF;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
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
--#####################################  固定部 END   ##########################################
--
  END ins_oif_order_process;
--
  /**********************************************************************************
   * Procedure Name   : ins_upd_order_process
   * Description      : EBS受注処理情報登録と更新(A-5)
   ***********************************************************************************/
  PROCEDURE ins_upd_order_process(
     in_h_idx      IN  NUMBER       --   アドオン受注ヘッダデータインデクス
    ,ov_errbuf     OUT VARCHAR2     --   エラー・メッセージ                  --# 固定 #
    ,ov_retcode    OUT VARCHAR2     --   リターン・コード                    --# 固定 #
    ,ov_errmsg     OUT VARCHAR2     --   ユーザー・エラー・メッセージ        --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_upd_order_process'; -- プログラム名
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
-- ************** Ver1.1 A.Igimi ADD START *************** --
    lv_flg VARCHAR2(1);     -- データ存在フラグ
-- ************** Ver1.1 A.Igimi ADD  END  *************** --
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
-- ************** Ver1.1 A.Igimi MOD START *************** --
--    IF ( gt_order_headers(in_h_idx).operation_code = cv_op_insert)
--
    -- XXCOS_ORDER_PROCESSのデータ存在チェック
    BEGIN
      SELECT cv_flg_y
      INTO   lv_flg
      FROM   xxcos_order_process  xop
      WHERE  xop.paas_order_number        =  gt_order_headers(in_h_idx).order_number;
--
    EXCEPTION
      -- XXCOS_ORDER_PROCESSにデータが存在しない場合
      WHEN NO_DATA_FOUND THEN
        lv_flg := cv_flg_n;
      -- その他エラー
      WHEN OTHERS THEN
        lv_errmsg := SQLERRM;
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
    IF lv_flg = cv_flg_n
-- ************** Ver1.1 A.Igimi MOD  END  *************** --
    THEN
      --
      BEGIN
        -- EBS受注処理情報登録
        INSERT INTO xxcos_order_process(
          order_process_id          -- EBS受注処理ID
         ,paas_order_number         -- アドオン受注番号
         ,order_source_id           -- 受注ソースID
         ,orig_sys_document_ref     -- 受注関連番号(EDI)
         ,process_flag              -- 処理フラグ
         ,created_by                -- 作成者
         ,creation_date             -- 作成日
         ,last_updated_by           -- 最終更新者
         ,last_update_date          -- 最終更新日
         ,last_update_login         -- 最終更新ログイン
         ,request_id                -- 要求ID
         ,program_application_id    -- コンカレント・プログラム・アプリケーションID
         ,program_id                -- コンカレント・プログラムID
         ,program_update_date       -- プログラム更新日
        )
        VALUES
        (
          xxcos_order_process_s01.NEXTVAL                      -- EBS受注処理ID
         ,gt_order_headers(in_h_idx).order_number              -- アドオン受注番号
         ,gt_order_headers(in_h_idx).order_source_id           -- 受注ソースID
         ,gt_order_headers(in_h_idx).orig_sys_document_ref     -- 受注関連番号(EDI)
         ,cv_flg_1                                             -- 処理フラグ「1：登録」
         ,cn_created_by                                        -- 作成者
         ,cd_creation_date                                     -- 作成日
         ,cn_last_updated_by                                   -- 最終更新者
         ,cd_last_update_date                                  -- 最終更新日
         ,cn_last_update_login                                 -- 最終更新ログイン
         ,cn_request_id                                        -- 要求ID
         ,cn_program_application_id                            -- コンカレント・プログラム・アプリケーションID
         ,cn_program_id                                        -- コンカレント・プログラムID
         ,cd_program_update_date                               -- プログラム更新日
        );
      EXCEPTION
        WHEN OTHERS THEN
          --メッセージ編集
          lv_errmsg  := xxccp_common_pkg.get_msg(
                           iv_application  => cv_appl_cos
                         , iv_name         => cv_msg_00010
                         , iv_token_name1  => cv_tkn_table_name  -- テーブル
                         , iv_token_value1 => cv_msg_16009       -- テーブル名
                         , iv_token_name2  => cv_tkn_key_data    -- キーデータ
                         , iv_token_value2 => SQLERRM            -- SQLエラーメッセージ
                        );
          lv_errbuf  := lv_errmsg;
          RAISE global_process_expt;
      END;
--
    ELSE
      --
      BEGIN
        -- EBS受注処理情報更新
        UPDATE  xxcos_order_process  xop
-- Ver1.3 Mod Start
--        SET     xop.process_flag             =  cv_flg_2,                          -- 処理フラグ「2：更新」
        SET     xop.process_flag             =  CASE
                                                  WHEN gt_order_headers(in_h_idx).flow_status_code = cv_sts_cancelled THEN
                                                    cv_flg_3                       -- 処理フラグ「3：ヘッダ取消」
                                                  ELSE
                                                    cv_flg_2                       -- 処理フラグ「2：更新」
                                                END,
-- Ver1.3 Mod End
                xop.last_updated_by          =  cn_last_updated_by,                -- 最終更新者
                xop.last_update_date         =  cd_last_update_date,               -- 最終更新日
                xop.last_update_login        =  cn_last_update_login,              -- 最終更新ﾛｸﾞｲﾝ
                xop.request_id               =  cn_request_id,                     -- 要求ID
                xop.program_application_id   =  cn_program_application_id,         -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑ･ｱﾌﾟﾘｹｰｼｮﾝID
                xop.program_id               =  cn_program_id,                     -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑID
                xop.program_update_date      =  cd_program_update_date             -- ﾌﾟﾛｸﾞﾗﾑ更新日
        WHERE   xop.paas_order_number        =  gt_order_headers(in_h_idx).order_number;
      EXCEPTION
        WHEN OTHERS THEN
          --メッセージ編集
          lv_errmsg  := xxccp_common_pkg.get_msg(
                           iv_application  => cv_appl_cos
                         , iv_name         => cv_msg_00011
                         , iv_token_name1  => cv_tkn_table_name  -- テーブル
                         , iv_token_value1 => cv_msg_16009       -- テーブル名
                         , iv_token_name2  => cv_tkn_key_data    -- キーデータ
                         , iv_token_value2 => SQLERRM            -- SQLエラーメッセージ
                        );
          lv_errbuf  := lv_errmsg;
          RAISE global_process_expt;
      END;
    END IF;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
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
--#####################################  固定部 END   ##########################################
--
  END ins_upd_order_process;
--
  /**********************************************************************************
   * Procedure Name   : get_order_lines
   * Description      : アドオン受注明細データ抽出(A-6)
   ***********************************************************************************/
  PROCEDURE get_order_lines(
    in_h_idx      IN  NUMBER,              --   アドオン受注ヘッダデータインデクス
    on_target_cnt OUT NOCOPY NUMBER,       --   対象データ件数
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100) := 'get_order_lines'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf               VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode              VARCHAR2(1);     -- リターン・コード
    lv_errmsg               VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    ln_idx                  NUMBER;
    -- *** ローカル・レコード ***
    l_lines_rec  order_lines_cur%ROWTYPE;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- OUTパラメータ初期化
    on_target_cnt := 0;
    --
    ln_idx        := 0;
--
    BEGIN
      -- カーソルオープン
      OPEN order_lines_cur(gt_order_headers(in_h_idx).header_id);
--
      <<lines_loop>>
      LOOP
--
        FETCH order_lines_cur INTO l_lines_rec;
        EXIT WHEN order_lines_cur%NOTFOUND;
--
        -- カウントアップ
        ln_idx := ln_idx + 1;
        ------------------------------------
        -- アドオン受注明細データ配列設定
        ------------------------------------
        gt_order_lines(ln_idx).line_id                  := l_lines_rec.line_id;                   -- アドオン明細ID
        gt_order_lines(ln_idx).header_id                := l_lines_rec.header_id;                 -- アドオンヘッダID
        gt_order_lines(ln_idx).org_id                   := l_lines_rec.org_id;                    -- 組織ID
        gt_order_lines(ln_idx).line_type_id             := l_lines_rec.line_type_id;              -- 明細タイプID
        gt_order_lines(ln_idx).line_number              := l_lines_rec.line_number;               -- 明細番号
        gt_order_lines(ln_idx).order_source_id          := l_lines_rec.order_source_id;           -- 受注ソースID
        gt_order_lines(ln_idx).inventory_item           := l_lines_rec.inventory_item;            -- 品目コード
        gt_order_lines(ln_idx).request_date             := l_lines_rec.request_date;              -- 納品予定日
        gt_order_lines(ln_idx).ordered_quantity         := l_lines_rec.ordered_quantity;          -- 数量
        gt_order_lines(ln_idx).order_quantity_uom       := l_lines_rec.order_quantity_uom;        -- 単位
        gt_order_lines(ln_idx).price_list_id            := l_lines_rec.price_list_id;             -- 価格表ID
        gt_order_lines(ln_idx).payment_term_id          := l_lines_rec.payment_term_id;           -- 支払条件ID
        gt_order_lines(ln_idx).orig_sys_document_ref    := l_lines_rec.orig_sys_document_ref;     -- 受注関連番号(EDI)
        gt_order_lines(ln_idx).orig_sys_line_ref        := l_lines_rec.orig_sys_line_ref;         -- 受注関連明細番号(EDI)
        gt_order_lines(ln_idx).unit_list_price          := l_lines_rec.unit_list_price;           -- 単価
        gt_order_lines(ln_idx).unit_selling_price       := l_lines_rec.unit_selling_price;        -- 販売単価
        gt_order_lines(ln_idx).flow_status_code         := l_lines_rec.flow_status_code;          -- 受注ステータス
        gt_order_lines(ln_idx).subinventory             := l_lines_rec.subinventory;              -- 保管場所
        gt_order_lines(ln_idx).packing_instructions     := l_lines_rec.packing_instructions;      -- 出荷依頼番号
        gt_order_lines(ln_idx).return_reason_code       := l_lines_rec.return_reason_code;        -- 取消事由コード
        gt_order_lines(ln_idx).customer_po_number       := l_lines_rec.customer_po_number;        -- 顧客発注番号
        gt_order_lines(ln_idx).customer_line_number     := l_lines_rec.customer_line_number;      -- 顧客明細番号
        gt_order_lines(ln_idx).calculate_price_flag     := l_lines_rec.calculate_price_flag;      -- 価格計算フラグ
        gt_order_lines(ln_idx).schedule_ship_date       := l_lines_rec.schedule_ship_date;        -- 予定出荷日
        gt_order_lines(ln_idx).salesrep_id              := l_lines_rec.salesrep_id;               -- 営業担当ID
        gt_order_lines(ln_idx).inventory_item_id        := l_lines_rec.inventory_item_id;         -- 品目ID
        gt_order_lines(ln_idx).sold_to_org_id           := l_lines_rec.sold_to_org_id;            -- 売上先顧客ID
        gt_order_lines(ln_idx).ship_from_org_id         := l_lines_rec.ship_from_org_id;          -- 出荷元在庫組織ID
        gt_order_lines(ln_idx).cancelled_quantity       := l_lines_rec.cancelled_quantity;        -- 取消数量
        gt_order_lines(ln_idx).context                  := l_lines_rec.context;                   -- コンテキスト
        gt_order_lines(ln_idx).attribute4               := l_lines_rec.attribute4;                -- 検収日
        gt_order_lines(ln_idx).attribute5               := l_lines_rec.attribute5;                -- 売上区分
        gt_order_lines(ln_idx).attribute6               := l_lines_rec.attribute6;                -- 子コード
        gt_order_lines(ln_idx).attribute7               := l_lines_rec.attribute7;                -- 備考
        gt_order_lines(ln_idx).attribute8               := l_lines_rec.attribute8;                -- 明細_時間指定(From)
        gt_order_lines(ln_idx).attribute9               := l_lines_rec.attribute9;                -- 明細_時間指定(To)
        gt_order_lines(ln_idx).attribute10              := l_lines_rec.attribute10;               -- 売単価
        gt_order_lines(ln_idx).attribute11              := l_lines_rec.attribute11;               -- 掛%
        gt_order_lines(ln_idx).attribute12              := l_lines_rec.attribute12;               -- 送り状発行番号
        gt_order_lines(ln_idx).global_attribute1        := l_lines_rec.global_attribute1;         -- 受注一覧出力日
        gt_order_lines(ln_idx).global_attribute2        := l_lines_rec.global_attribute2;         -- 納品書発行フラグエリア
        gt_order_lines(ln_idx).global_attribute3        := l_lines_rec.global_attribute3;         -- 受注明細ID(分割前)
        gt_order_lines(ln_idx).global_attribute4        := l_lines_rec.global_attribute4;         -- 受注明細参照
        gt_order_lines(ln_idx).global_attribute5        := l_lines_rec.global_attribute5;         -- 販売実績連携フラグ
        gt_order_lines(ln_idx).global_attribute6        := l_lines_rec.global_attribute6;         -- 受注一覧ファイル出力日
        gt_order_lines(ln_idx).global_attribute7        := l_lines_rec.global_attribute7;         -- HHT受注送信フラグ
        gt_order_lines(ln_idx).global_attribute9        := l_lines_rec.global_attribute9;         -- 明細番号(分割前)
        gt_order_lines(ln_idx).global_attribute10       := l_lines_rec.global_attribute10;        -- PaaS明細最終更新日(UTC)
        gt_order_lines(ln_idx).operation_code           := l_lines_rec.operation_code;            -- オペレーション
--
      END LOOP lines_loop;
--
      -- カーソルクローズ
      CLOSE order_lines_cur;
--
    EXCEPTION
      -- データ抽出エラー
      WHEN OTHERS THEN
        lv_errmsg  := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appl_cos
                       , iv_name         => cv_msg_00013
                       , iv_token_name1  => cv_tkn_table_name
                       , iv_token_value1 => cv_msg_16008
                       , iv_token_name2  => cv_tkn_key_data
                       , iv_token_value2 => cv_msg_part||SQLERRM
                      );
        lv_errbuf  := lv_errmsg;
        RAISE global_process_expt;
    END;
--
    -- OUTパラメータ設定
    on_target_cnt := ln_idx;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      -- カーソルクローズ
      IF ( order_lines_cur%ISOPEN ) THEN
        CLOSE order_lines_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      -- カーソルクローズ
      IF ( order_lines_cur%ISOPEN ) THEN
        CLOSE order_lines_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      -- カーソルクローズ
      IF ( order_lines_cur%ISOPEN ) THEN
        CLOSE order_lines_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_order_lines;
--
  /**********************************************************************************
   * Procedure Name   : ins_oif_order_line
   * Description      : 受注明細OIFテーブル登録(A-7)
   ***********************************************************************************/
  PROCEDURE ins_oif_order_line(
     in_h_idx      IN  NUMBER       --   アドオン受注ヘッダデータインデクス
    ,in_l_idx      IN  NUMBER       --   アドオン受注明細データインデクス
    ,ov_errbuf     OUT VARCHAR2     --   エラー・メッセージ                  --# 固定 #
    ,ov_retcode    OUT VARCHAR2     --   リターン・コード                    --# 固定 #
    ,ov_errmsg     OUT VARCHAR2     --   ユーザー・エラー・メッセージ        --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_oif_order_line'; -- プログラム名
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
    lt_flow_status_code  oe_order_lines_all.flow_status_code%TYPE;   -- ステータス（受注明細）
    lt_line_number       oe_order_lines_all.line_number%TYPE;        -- 明細番号
    lt_orig_sys_line_ref oe_order_lines_all.orig_sys_line_ref%TYPE;  -- 外部システム受注明細番号
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- 受注ステータス（明細）が「BOOKED：記帳済」、「CANCELLED：取消済」以外の場合
    IF ( gt_order_lines(in_l_idx).flow_status_code <> cv_sts_booked )
      AND ( gt_order_lines(in_l_idx).flow_status_code <> cv_sts_cancelled )
    THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_cos
                     , iv_name         => cv_msg_16006
                     , iv_token_name1  => cv_tkn_header_id        -- アドオンヘッダID
                     , iv_token_value1 => gt_order_headers(in_h_idx).header_id
                     , iv_token_name2  => cv_tkn_header_status    -- 受注ステータス
                     , iv_token_value2 => gt_order_headers(in_h_idx).flow_status_code
                     , iv_token_name3  => cv_tkn_line_id          -- アドオ明細ID
                     , iv_token_value3 => gt_order_lines(in_l_idx).line_id
                     , iv_token_name4  => cv_tkn_line_status      -- 受注ステータス（明細）
                     , iv_token_value4 => gt_order_lines(in_l_idx).flow_status_code
                    );
      lv_errbuf  := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- 受注ステータス（ヘッダ）が「CANCELLED：取消済」、受注ステータス（明細）が「CANCELLED：取消済」以外の場合
    IF ( gt_order_headers(in_h_idx).flow_status_code = cv_sts_cancelled )
      AND ( gt_order_lines(in_l_idx).flow_status_code <> cv_sts_cancelled )
    THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_cos
                     , iv_name         => cv_msg_16006
                     , iv_token_name1  => cv_tkn_header_id        -- アドオンヘッダID
                     , iv_token_value1 => gt_order_headers(in_h_idx).header_id
                     , iv_token_name2  => cv_tkn_header_status    -- 受注ステータス
                     , iv_token_value2 => gt_order_headers(in_h_idx).flow_status_code
                     , iv_token_name3  => cv_tkn_line_id          -- アドオ明細ID
                     , iv_token_value3 => gt_order_lines(in_l_idx).line_id
                     , iv_token_name4  => cv_tkn_line_status      -- 受注ステータス（明細）
                     , iv_token_value4 => gt_order_lines(in_l_idx).flow_status_code
                    );
      lv_errbuf  := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- 取消済受注明細データの新規登録スキップ
    IF ( gt_order_lines(in_l_idx).operation_code = cv_op_insert )
      AND ( gt_order_lines(in_l_idx).flow_status_code = cv_sts_cancelled )
    THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_cos
                     , iv_name         => cv_msg_16004
                     , iv_token_name1  => cv_tkn_header_id        -- アドオンヘッダID
                     , iv_token_value1 => gt_order_lines(in_l_idx).header_id
                     , iv_token_name2  => cv_tkn_line_id          -- アドオン明細ID
                     , iv_token_value2 => gt_order_lines(in_l_idx).line_id
                    );
      -- メッセージ出力
      fnd_file.put_line(
          which  => fnd_file.output
        , buff   => lv_errmsg
      );
      -- ログ出力
      fnd_file.put_line(
           which  => fnd_file.log
          ,buff   => lv_errmsg
      );
-- Ver1.3 Del Start
--      gn_warn_cnt := gn_warn_cnt + 1;
-- Ver1.3 Del End
      RETURN;
    END IF;
--
    -- クローズ済受注明細データの更新スキップ
    IF ( gt_order_lines(in_l_idx).operation_code = cv_op_update )
    THEN
      -- 受注明細のステータス取得
      BEGIN
--
        SELECT
               oola.flow_status_code         flow_status_code           -- ステータス
              ,oola.line_number              line_number                -- 明細番号
              ,oola.orig_sys_line_ref        orig_sys_line_ref          -- 外部システム受注明細番号
        INTO   lt_flow_status_code
              ,lt_line_number
              ,lt_orig_sys_line_ref
        FROM   oe_order_lines_all      oola         -- 受注明細テーブル
        WHERE  oola.order_source_id       = gt_order_lines(in_l_idx).order_source_id
        AND    oola.orig_sys_document_ref = gt_order_lines(in_l_idx).orig_sys_document_ref
        AND    oola.global_attribute8     = gt_order_lines(in_l_idx).line_number;
--
      EXCEPTION
        -- 存在しない場合
        WHEN NO_DATA_FOUND THEN
        -- 受注明細番号取得エラー
        lv_errmsg  := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appl_cos
                       , iv_name         => cv_msg_16013
                       , iv_token_name1  => cv_tkn_header_id        -- アドオンヘッダID
                       , iv_token_value1 => gt_order_lines(in_l_idx).header_id
                       , iv_token_name2  => cv_tkn_line_id          -- アドオン明細ID
                       , iv_token_value2 => gt_order_lines(in_l_idx).line_id
                      );
        lv_errbuf  := lv_errmsg;
        RAISE global_process_expt;
--
      END;
      -- ステータス変数がNULL以外かつステータス変数が「CLOSED：クローズ済」の場合
      IF ( lt_flow_status_code IS NOT NULL )
        AND ( lt_flow_status_code = cv_sts_closed )
      THEN
          lv_errmsg    := xxccp_common_pkg.get_msg(
                           iv_application  => cv_appl_cos
                         , iv_name         => cv_msg_16012
                         , iv_token_name1  => cv_tkn_header_id        -- アドオンヘッダID
                         , iv_token_value1 => gt_order_lines(in_l_idx).header_id
                         , iv_token_name2  => cv_tkn_line_id          -- アドオン明細ID
                         , iv_token_value2 => gt_order_lines(in_l_idx).line_id
                        );
        -- メッセージ出力
        fnd_file.put_line(
            which  => fnd_file.output
          , buff   => lv_errmsg
        );
        -- ログ出力
        fnd_file.put_line(
             which  => fnd_file.log
            ,buff   => lv_errmsg
        );
        gn_warn_cnt := gn_warn_cnt + 1;
        RETURN;
      END IF;
    END IF;
--
    -- オペレーションが「INSERT」」の場合、受注明細番号変数をカウントアップ
     IF ( gt_order_lines(in_l_idx).operation_code = cv_op_insert )
    THEN
      gn_line_number := gn_line_number + 1;
    END IF;
--
    BEGIN
--
      -- 受注明細OIFテーブル登録
      INSERT INTO oe_lines_iface_all(
        org_id                    -- 組織ID
       ,line_type_id              -- 明細タイプID
       ,line_number               -- 明細番号
       ,order_source_id           -- 受注ソースID
       ,inventory_item            -- 品目コード
       ,request_date              -- 納品予定日
       ,ordered_quantity          -- 数量
       ,order_quantity_uom        -- 単位
       ,price_list_id             -- 価格表ID
       ,payment_term_id           -- 支払条件ID
       ,orig_sys_document_ref     -- 外部システム受注番号
       ,orig_sys_line_ref         -- 外部システム受注明細番号
       ,unit_list_price           -- 単価
       ,unit_selling_price        -- 販売単価
       ,subinventory              -- 保管場所
       ,packing_instructions      -- 出荷依頼番号
       ,change_reason             -- 変更事由
       ,customer_po_number        -- 顧客発注番号
       ,customer_line_number      -- 顧客明細番号
       ,calculate_price_flag      -- 価格計算フラグ
       ,schedule_ship_date        -- 予定出荷日
       ,salesrep_id               -- 営業担当ID
       ,inventory_item_id         -- 品目ID
       ,sold_to_org_id            -- 売上先顧客ID
       ,ship_from_org_id          -- 出荷元在庫組織ID
       ,cancelled_quantity        -- 取消数量
       ,context                   -- コンテキスト
       ,attribute4                -- 検収日
       ,attribute5                -- 売上区分
       ,attribute6                -- 子コード
       ,attribute7                -- 備考
       ,attribute8                -- 明細_時間指定(From)
       ,attribute9                -- 明細_時間指定(To)
       ,attribute10               -- 売単価
       ,attribute11               -- 掛%
       ,attribute12               -- 送り状発行番号
       ,global_attribute1         -- 受注一覧出力日
       ,global_attribute2         -- 納品書発行フラグエリア
       ,global_attribute3         -- 受注明細ID(分割前)
       ,global_attribute4         -- 受注明細参照
       ,global_attribute5         -- 販売実績連携フラグ
       ,global_attribute6         -- 受注一覧ファイル出力日
       ,global_attribute7         -- HHT受注送信フラグ
       ,global_attribute8         -- 明細番号
       ,global_attribute9         -- 明細番号(分割前)
       ,global_attribute10        -- PaaS明細最終更新日(UTC)
       ,operation_code            -- オペレーション
       ,created_by                -- 作成者
       ,creation_date             -- 作成日
       ,last_updated_by           -- 最終更新者
       ,last_update_date          -- 最終更新日
       ,last_update_login         -- 最終更新ログイン
       ,request_id                -- 要求ID
       ,program_application_id    -- コンカレント・プログラム・アプリケーションID
       ,program_id                -- コンカレント・プログラムID
       ,program_update_date       -- プログラム更新日
      )
      VALUES
      (
        gt_order_lines(in_l_idx).org_id                    -- 組織ID
       ,gt_order_lines(in_l_idx).line_type_id              -- 明細タイプID
       ,CASE WHEN ( gt_order_headers(in_h_idx).operation_code = cv_op_insert )
               THEN gt_order_lines(in_l_idx).line_number
             WHEN ( gt_order_lines(in_l_idx).operation_code = cv_op_insert )
               THEN gn_line_number
             ELSE lt_line_number
        END                                                -- 明細番号
       ,gt_order_lines(in_l_idx).order_source_id           -- 受注ソースID
       ,gt_order_lines(in_l_idx).inventory_item            -- 品目コード
       ,gt_order_lines(in_l_idx).request_date              -- 納品予定日
       ,gt_order_lines(in_l_idx).ordered_quantity          -- 数量
       ,gt_order_lines(in_l_idx).order_quantity_uom        -- 単位
       ,gt_order_lines(in_l_idx).price_list_id             -- 価格表ID
       ,gt_order_lines(in_l_idx).payment_term_id           -- 支払条件ID
       ,gt_order_lines(in_l_idx).orig_sys_document_ref     -- 受注関連番号(EDI)
       ,CASE WHEN ( gt_order_headers(in_h_idx).operation_code = cv_op_insert )
               THEN TO_CHAR(gt_order_lines(in_l_idx).line_number)
             WHEN ( gt_order_lines(in_l_idx).operation_code = cv_op_insert )
               THEN TO_CHAR(gn_line_number)
             ELSE lt_orig_sys_line_ref
        END                                                -- 受注関連明細番号(EDI)
       ,NVL(gt_order_lines(in_l_idx).unit_list_price,
            gt_order_lines(in_l_idx).unit_selling_price)   -- 単価
       ,gt_order_lines(in_l_idx).unit_selling_price        -- 販売単価
       ,gt_order_lines(in_l_idx).subinventory              -- 保管場所
       ,gt_order_lines(in_l_idx).packing_instructions      -- 出荷依頼番号
       ,gt_order_lines(in_l_idx).return_reason_code        -- 取消事由コード
       ,gt_order_lines(in_l_idx).customer_po_number        -- 顧客発注番号
       ,gt_order_lines(in_l_idx).customer_line_number      -- 顧客明細番号
       ,gt_order_lines(in_l_idx).calculate_price_flag      -- 価格計算フラグ
       ,gt_order_lines(in_l_idx).schedule_ship_date        -- 予定出荷日
       ,gt_order_lines(in_l_idx).salesrep_id               -- 営業担当ID
       ,gt_order_lines(in_l_idx).inventory_item_id         -- 品目ID
       ,gt_order_lines(in_l_idx).sold_to_org_id            -- 売上先顧客ID
       ,gt_order_lines(in_l_idx).ship_from_org_id          -- 出荷元在庫組織ID
       ,NULL                                                -- 取消数量
       ,gt_order_lines(in_l_idx).context                   -- コンテキスト
       ,gt_order_lines(in_l_idx).attribute4                -- 検収日
       ,gt_order_lines(in_l_idx).attribute5                -- 売上区分
       ,gt_order_lines(in_l_idx).attribute6                -- 子コード
       ,gt_order_lines(in_l_idx).attribute7                -- 備考
       ,gt_order_lines(in_l_idx).attribute8                -- 明細_時間指定(From)
       ,gt_order_lines(in_l_idx).attribute9                -- 明細_時間指定(To)
       ,gt_order_lines(in_l_idx).attribute10               -- 売単価
       ,gt_order_lines(in_l_idx).attribute11               -- 掛%
       ,gt_order_lines(in_l_idx).attribute12               -- 送り状発行番号
       ,gt_order_lines(in_l_idx).global_attribute1         -- 受注一覧出力日
       ,gt_order_lines(in_l_idx).global_attribute2         -- 納品書発行フラグエリア
       ,gt_order_lines(in_l_idx).global_attribute3         -- 受注明細ID(分割前)
       ,gt_order_lines(in_l_idx).global_attribute4         -- 受注明細参照
       ,gt_order_lines(in_l_idx).global_attribute5         -- 販売実績連携フラグ
       ,gt_order_lines(in_l_idx).global_attribute6         -- 受注一覧ファイル出力日
       ,gt_order_lines(in_l_idx).global_attribute7         -- HHT受注送信フラグ
       ,gt_order_lines(in_l_idx).line_number               -- 明細番号
       ,gt_order_lines(in_l_idx).global_attribute9         -- 明細番号(分割前)
       ,gt_order_lines(in_l_idx).global_attribute10        -- PaaS明細最終更新日(UTC)
       ,gt_order_lines(in_l_idx).operation_code            -- オペレーション
       ,cn_created_by                                      -- 作成者
       ,cd_creation_date                                   -- 作成日
       ,cn_last_updated_by                                 -- 最終更新者
       ,cd_last_update_date                                -- 最終更新日
       ,cn_last_update_login                               -- 最終更新ログイン
       ,NULL                                               -- 要求ID
       ,cn_program_application_id                          -- コンカレント・プログラム・アプリケーションID
       ,cn_program_id                                      -- コンカレント・プログラムID
       ,cd_program_update_date                             -- プログラム更新日
      );
--
    EXCEPTION
      WHEN OTHERS THEN
        --メッセージ編集
        lv_errmsg  := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appl_cos
                       , iv_name         => cv_msg_00010
                       , iv_token_name1  => cv_tkn_table_name  -- テーブル
                       , iv_token_value1 => cv_msg_00133       -- テーブル名
                       , iv_token_name2  => cv_tkn_key_data    -- キーデータ
                       , iv_token_value2 => SQLERRM            -- SQLエラーメッセージ
                      );
        lv_errbuf  := lv_errmsg;
        RAISE global_process_expt;
    END;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
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
--#####################################  固定部 END   ##########################################
--
  END ins_oif_order_line;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf     OUT  VARCHAR2,  -- エラー・メッセージ           --# 固定 #
    ov_retcode    OUT  VARCHAR2,  -- リターン・コード             --# 固定 #
    ov_errmsg     OUT  VARCHAR2)  -- ユーザー・エラー・メッセージ --# 固定 #
  IS
--
--#####################  固定ローカル定数変数宣言部 START   ####################
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100) := 'submain'; -- プログラム名
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf               VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode              VARCHAR2(1);     -- リターン・コード
    lv_errmsg               VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
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
    -- グローバル変数の初期化
    gn_target_cnt           := 0;
    gn_l_target_cnt         := 0;
    gn_normal_cnt           := 0;
    gn_warn_cnt             := 0;
    gn_error_cnt            := 0;
--
    -- ============================================
    -- 初期処理(A-1)
    -- ============================================
    init(
      ov_errbuf   => lv_errbuf,
      ov_retcode  => lv_retcode,
      ov_errmsg   => lv_errmsg
    );
--
    -- エラーの場合
    IF ( lv_retcode = cv_status_error )
    THEN
      ov_errbuf  := lv_errbuf;
      ov_retcode := lv_retcode;
      ov_errmsg  := lv_errmsg;
      RETURN;
    END IF;
--
    -- ============================================
    -- アドオン受注ヘッダ情報テーブルデータ抽出(A-2)
    -- ============================================
    get_order_headers(
      on_target_cnt => gn_target_cnt,
      ov_errbuf     => lv_errbuf,
      ov_retcode    => lv_retcode,
      ov_errmsg     => lv_errmsg
    );
--
    -- エラーの場合
    IF ( lv_retcode = cv_status_error )
    THEN
      ov_errbuf  := lv_errbuf;
      ov_retcode := lv_retcode;
      ov_errmsg  := lv_errmsg;
      RETURN;
    END IF;
--
    <<order_headers_loop>>
    FOR ln_i IN 1..gn_target_cnt LOOP
--
      -- 受注スキップフラグ初期化
      gv_skip_flg := cv_flg_n;
--
      -- ============================================
      -- 受注ヘッダOIFテーブル登録(A-3)
      -- ============================================
--
        ins_oif_order_header(
          in_h_idx       => ln_i,
          ov_errbuf      => lv_errbuf,
          ov_retcode     => lv_retcode,
          ov_errmsg      => lv_errmsg
        );
        -- エラーの場合
        IF ( lv_retcode = cv_status_error )
        THEN
          ov_errbuf  := lv_errbuf;
          ov_retcode := lv_retcode;
          ov_errmsg  := lv_errmsg;
          -- エラー件数
          gn_error_cnt := gn_error_cnt + 1;
          RETURN;
        END IF;
--
      -- 受注スキップフラグがNの場合
      IF ( gv_skip_flg = cv_flg_n )
      THEN
        -- ============================================
        -- 受注処理OIFテーブル登録(A-4)
        -- ============================================
--
        ins_oif_order_process(
          in_h_idx       => ln_i,
          ov_errbuf      => lv_errbuf,
          ov_retcode     => lv_retcode,
          ov_errmsg      => lv_errmsg
        );
        -- エラーの場合
        IF ( lv_retcode = cv_status_error ) THEN
          ov_errbuf  := lv_errbuf;
          ov_retcode := lv_retcode;
          ov_errmsg  := lv_errmsg;
          -- エラー件数
          gn_error_cnt := gn_error_cnt + 1;
          RETURN;
        END IF;
--
        -- ============================================
        -- EBS受注処理情報登録と更新(A-5)
        -- ============================================
-- 
        ins_upd_order_process(
          in_h_idx       => ln_i,
          ov_errbuf      => lv_errbuf,
          ov_retcode     => lv_retcode,
          ov_errmsg      => lv_errmsg
        );
        -- エラーの場合
        IF ( lv_retcode = cv_status_error )
        THEN
          ov_errbuf  := lv_errbuf;
          ov_retcode := lv_retcode;
          ov_errmsg  := lv_errmsg;
          -- エラー件数
          gn_error_cnt := gn_error_cnt + 1;
          RETURN;
        END IF;
--
        -- オペレーションが「UPDATE」、受注ステータスが「CANCELLED：取消済」の場合、スキップ
        IF ( gt_order_headers(ln_i).operation_code <> cv_op_update )
          OR ( gt_order_headers(ln_i).flow_status_code <> cv_sts_cancelled )
        THEN
          -- ============================================
          -- アドオン受注明細データ抽出(A-6)
          -- ============================================
--
          get_order_lines(
            in_h_idx       => ln_i,
            on_target_cnt  => gn_l_target_cnt,
            ov_errbuf      => lv_errbuf,
            ov_retcode     => lv_retcode,
            ov_errmsg      => lv_errmsg
          );
          -- エラーの場合
          IF ( lv_retcode = cv_status_error )
          THEN
            ov_errbuf  := lv_errbuf;
            ov_retcode := lv_retcode;
            ov_errmsg  := lv_errmsg;
            -- エラー件数
            gn_error_cnt := gn_error_cnt + 1;
            RETURN;
          END IF;
--
          <<order_lines_loop>>
          FOR ln_j IN 1..gn_l_target_cnt LOOP
--
            -- ============================================
            -- 受注明細OIFテーブル登録(A-7)
            -- ============================================
--
            ins_oif_order_line(
              in_h_idx       => ln_i,
              in_l_idx       => ln_j,
              ov_errbuf      => lv_errbuf,
              ov_retcode     => lv_retcode,
              ov_errmsg      => lv_errmsg
            );
            -- エラーの場合
            IF ( lv_retcode = cv_status_error )
            THEN
              ov_errbuf  := lv_errbuf;
              ov_retcode := lv_retcode;
              ov_errmsg  := lv_errmsg;
              -- エラー件数
              gn_error_cnt := gn_error_cnt + 1;
              RETURN;
            END IF;
--
          END LOOP order_lines_loop;
--
        END IF;
        -- 成功件数
        gn_normal_cnt := gn_normal_cnt + 1;
--
      END IF;
--
    END LOOP order_headers_loop;
--
    -- エラーの場合
    IF ( lv_retcode = cv_status_error )
    THEN
      ov_errbuf  := lv_errbuf;
      ov_retcode := lv_retcode;
      ov_errmsg  := lv_errmsg;
      RETURN;
    END IF;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
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
  END submain;
--
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : コンカレント実行ファイル登録プロシージャ
   **********************************************************************************/
--
  PROCEDURE main(
    errbuf        OUT VARCHAR2,              --   エラー・メッセージ  --# 固定 #
    retcode       OUT VARCHAR2               --   リターン・コード    --# 固定 #
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
    cv_prg_name             CONSTANT VARCHAR2(100) := 'main';             -- プログラム名
--
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf               VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode              VARCHAR2(1);     -- リターン・コード
    lv_errmsg               VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
    lv_message_code         VARCHAR2(100);   -- 終了メッセージコード
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
       lv_errbuf   -- エラー・メッセージ           --# 固定 #
      ,lv_retcode  -- リターン・コード             --# 固定 #
      ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    --エラー出力
    IF (lv_retcode = cv_status_error) THEN
      -- メッセージ出力
      fnd_file.put_line(
        which  => fnd_file.output,
        buff   => lv_errmsg
      );
      -- ログ出力
      fnd_file.put_line(
        which  => fnd_file.log,
        buff   => lv_errbuf
      );
      gn_normal_cnt := 0;
      gn_error_cnt  := 1;
    END IF;
    --空行挿入
    fnd_file.put_line(
       which  => fnd_file.output
      ,buff   => ''
    );
    --対象件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_ccp
                    ,iv_name         => cv_msg_90000
                    ,iv_token_name1  => cv_tkn_count
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                   );
    fnd_file.put_line(
       which  => fnd_file.output
      ,buff   => gv_out_msg
    );
    --
    --成功件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_ccp
                    ,iv_name         => cv_msg_90001
                    ,iv_token_name1  => cv_tkn_count
                    ,iv_token_value1 => TO_CHAR(gn_normal_cnt)
                   );
    fnd_file.put_line(
       which  => fnd_file.output
      ,buff   => gv_out_msg
    );
    --
    --エラー件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_ccp
                    ,iv_name         => cv_msg_90002
                    ,iv_token_name1  => cv_tkn_count
                    ,iv_token_value1 => TO_CHAR(gn_error_cnt)
                   );
    fnd_file.put_line(
       which  => fnd_file.output
      ,buff   => gv_out_msg
    );
--
    -- 警告件数が1件以上ある場合、終了ステータスを警告に設定
    IF ( gn_warn_cnt != 0 )
      AND (lv_retcode = cv_status_normal)THEN
      lv_retcode  := cv_status_warn;
    END IF;
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
                     iv_application  => cv_appl_ccp
                    ,iv_name         => lv_message_code
                   );
    fnd_file.put_line(
       which  => fnd_file.output
      ,buff   => gv_out_msg
    );
    --ステータスセット
    retcode := lv_retcode;
    --終了ステータスがエラーの場合はROLLBACKする
    IF (retcode = cv_status_error) THEN
      ROLLBACK;
    END IF;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
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
--
--#####################################  固定部 END   ##########################################
--
  END main;
--
END XXCOS010A12C;
/
