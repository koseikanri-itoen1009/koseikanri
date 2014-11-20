CREATE OR REPLACE PACKAGE BODY XXCOP_COMMON_PKG2
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOP_COMMON_PKG(spec)
 * Description      : 共通関数パッケージ2(計画)
 * MD.050           : 共通関数    MD070_IPO_COP
 * Version          : 2.5
 *
 * Program List
 * ------------------------- ------------------------------------------------------------
 *  Name                      Description
 * ------------------------- -------------------------------------------------------
 * get_item_info             10.品目情報取得処理
 * get_shipment_result       11.出荷実績取得
 * get_num_of_shipped        12.鮮度条件別出荷実績取得
 * get_num_of_forecast       13.出荷予測取得処理
 * get_stock_plan            14.入庫予定取得処理
 * get_onhand_qty            15.手持在庫取得処理
 * get_deliv_lead_time       16.配送リードタイム取得処理
 * get_working_days          17.稼働日数取得処理
 * upd_assignment            18.割当セットAPI起動
 * get_loct_info             19.倉庫情報取得処理
 * get_critical_date_f       20.鮮度条件基準日取得処理
 * get_delivery_unit         21.配送単位取得処理
 * get_receipt_date          22.着日取得処理
 * get_shipment_date         23.出荷日取得処理(廃止予定)
 * get_item_category_f       24.品目カテゴリ取得
 * get_last_arrival_date_f   25.最終入庫日取得
 * get_last_purchase_date_f  26.最終購入日取得
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009/01/20    1.0                   新規作成
 *  2009/04/08    1.1  SCS.Kikuchi      T1_0272,T1_0279,T1_0282,T1_0284対応
 *  2009/05/08    1.2  SCS.Kikuchi      T1_0918,T1_0919対応
 *  2009/07/23    1.3  SCS.Fukada       0000670対応(共通課題：I_E_479)
 *  2009/11/24    1.4  SCS.Itou         本番障害#7 計画が稼動するまで割当セットAPI起動を起動しない。
 *  2009/08/24    2.0  SCS.Fukada       0000669対応(共通課題：I_E_479)、変更履歴削除
 *  2009/11/05    2.1  SCS.Goto         I_E_479_009
 *  2009/11/05    2.2  SCS.Goto         I_E_479_008
 *  2009/12/01    2.3  SCS.Goto         I_E_479_020 アプリPT対応
 *  2009/12/01    2.4  SCS.Fukada       I_E_479_022 割当セットAPI起動修正
 *  2009/12/07    2.5  SCS.Goto         I_E_479_023 アプリPT対応
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
  cn_created_by             CONSTANT NUMBER      := fnd_global.user_id;                 --CREATED_BY
  cd_creation_date          CONSTANT DATE        := SYSDATE;                            --CREATION_DATE
  cn_last_updated_by        CONSTANT NUMBER      := fnd_global.user_id;                 --LAST_UPDATED_BY
  cd_last_update_date       CONSTANT DATE        := SYSDATE;                            --LAST_UPDATE_DATE
  cn_last_update_login      CONSTANT NUMBER      := fnd_global.login_id;                --LAST_UPDATE_LOGIN
  cn_request_id             CONSTANT NUMBER      := fnd_global.conc_request_id;         --REQUEST_ID
  cn_program_application_id CONSTANT NUMBER      := fnd_global.prog_appl_id;            --PROGRAM_APPLICATION_ID
  cn_program_id             CONSTANT NUMBER      := fnd_global.conc_program_id;         --PROGRAM_ID
  cd_program_update_date    CONSTANT DATE        := SYSDATE;                            --PROGRAM_UPDATE_DATE
  cv_msg_part               CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont               CONSTANT VARCHAR2(3) := '.';
  -- メッセージ・アプリケーション名（アドオン：販物・計画領域）
  cv_msg_application        CONSTANT VARCHAR2(100) := 'XXCOP';
  -- メッセージ名
  cv_message_00002          CONSTANT VARCHAR2(16)  := 'APP-XXCOP1-00002';
  -- メッセージトークン
  cv_message_00002_token_1  CONSTANT VARCHAR2(9)   := 'PROF_NAME';
  cv_cmn_drink_cal_cd       CONSTANT VARCHAR2(100) := 'XXCMN_DRNK_WHSE_STD_CAL';        -- ドリンク基準カレンダ
  cv_cmn_drink_cal_cd_name  CONSTANT VARCHAR2(100) := 'XXCMN:ドリンク倉庫基準カレンダ'; -- ドリンク基準カレンダ
--
--################################  固定部 END   ##################################
--
  cv_pkg_name               CONSTANT VARCHAR2(100) := 'XXCOP_COMMON_PKG2';       -- パッケージ名
  cv_lang                   CONSTANT VARCHAR2(100) := USERENV('LANG');           -- 言語
--
--
  -- ===============================
  -- ユーザー定義定数
  -- ===============================
  cd_sys_date               CONSTANT DATE        := SYSDATE;
  cn_zero                   CONSTANT NUMBER      := 0;
  -- ===============================
  -- ユーザー定義例外
  -- ===============================
  date_null_expt            EXCEPTION;
  date_from_to_expt         EXCEPTION;
  --
  /**********************************************************************************
   * Procedure Name   : get_item_info
   * Description      : 品目情報取得処理
   ***********************************************************************************/
  PROCEDURE get_item_info(
    id_target_date          IN  DATE,         -- 対象日付
    in_organization_id      IN  NUMBER,       -- 組織ID
    in_inventory_item_id    IN  NUMBER,       -- 在庫品目ID
    on_item_id              OUT NUMBER,       -- OPM品目ID
    ov_item_no              OUT VARCHAR2,     -- 品目コード
    ov_item_name            OUT VARCHAR2,     -- 品目名称
    on_num_of_case          OUT NUMBER,       -- ケース入数
    on_palette_max_cs_qty   OUT NUMBER,       -- 配数
    on_palette_max_step_qty OUT NUMBER,       -- 段数
    ov_errbuf               OUT VARCHAR2,     -- エラー・メッセージ
    ov_retcode              OUT VARCHAR2,     -- リターン・コード
    ov_errmsg               OUT VARCHAR2)     -- ユーザー・エラー・メッセージ
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name               CONSTANT VARCHAR2(100) := 'get_item_info'; -- プログラム名
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    --品目カテゴリ
    cv_category_prod_class    CONSTANT VARCHAR2(100) := '本社商品区分';
    cv_category_item_class    CONSTANT VARCHAR2(100) := '品目区分';
    cv_category_article_class CONSTANT VARCHAR2(100) := '商品製品区分';
    --品目カテゴリ値
    cv_prod_class_leaf        CONSTANT VARCHAR2(100) := '1';  -- リーフ
    cv_prod_class_drink       CONSTANT VARCHAR2(100) := '2';  -- ドリンク
    cv_item_class_product     CONSTANT VARCHAR2(100) := '5';  -- 製品
    cv_article_class_product  CONSTANT VARCHAR2(100) := '2';  -- 製品
    --品目マスタ
    cn_iimb_status_active     CONSTANT NUMBER := 0;           -- ステータス
    cn_ximb_status_active     CONSTANT NUMBER := 0;           -- ステータス
    cv_shipping_enable        CONSTANT NUMBER := '1';         -- ステータス
--
    -- *** ローカル変数 ***
    lt_prod_class             mtl_categories_b.segment1%TYPE;  -- 本社商品区分
    lt_article_class          mtl_categories_b.segment1%TYPE;  -- 商品製品区分
    lt_item_category          mtl_categories_b.segment1%TYPE;  -- 品目カテゴリ
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
    --例外定義
    outside_scope_expt        EXCEPTION;
    --
  BEGIN
    --==============================================================
    --ステータス初期化
    --==============================================================
    ov_retcode := cv_status_normal;
--
    --==============================================================
    --品目取得
    --==============================================================
    SELECT iimb.item_id                        item_id               -- OPM品目ID
          ,iimb.item_no                        item_no               -- 品目コード
          ,ximb.item_short_name                item_name             -- 品目名称
          ,NVL(TO_NUMBER(iimb.attribute11), 1) num_of_case           -- ケース入数
          ,DECODE(ximb.palette_max_cs_qty , NULL , 1
                                          , 0    , 1
                                                 , ximb.palette_max_cs_qty
                 )                             palette_max_cs_qty    -- 配数
          ,DECODE(ximb.palette_max_step_qty, NULL , 1
                                           , 0    , 1
                                                  , ximb.palette_max_step_qty
                 )                             palette_max_step_qty  -- 段数
    INTO   on_item_id
          ,ov_item_no
          ,ov_item_name
          ,on_num_of_case
          ,on_palette_max_cs_qty
          ,on_palette_max_step_qty
    FROM   ic_item_mst_b         iimb                                -- OPM品目マスタ
          ,xxcmn_item_mst_b      ximb                                -- OPM品目アドオンマスタ
          ,mtl_system_items_b    msib                                -- DISC品目マスタ
    WHERE iimb.inactive_ind      = cn_iimb_status_active
      AND iimb.attribute18       = cv_shipping_enable
      AND ximb.item_id           = iimb.item_id
      AND ximb.obsolete_class    = cn_ximb_status_active
      AND id_target_date         BETWEEN NVL(ximb.start_date_active, id_target_date)
                                     AND NVL(ximb.end_date_active  , id_target_date)
      AND msib.segment1          = iimb.item_no
      AND msib.organization_id   = in_organization_id
      AND msib.inventory_item_id = in_inventory_item_id
    ;
--
    -- 本社商品区分を取得
    lt_prod_class := XXCOP_COMMON_PKG2.get_item_category_f(
                       cv_category_prod_class
                      ,on_item_id
                       );
    -- 本社商品区分がドリンク以外は対象外
    IF   ( lt_prod_class IS NULL )
      OR ( lt_prod_class <> cv_prod_class_drink )THEN
      --
      RAISE outside_scope_expt;
      --
    END IF;
    --
    -- 商品製品区分を取得
    lt_article_class := XXCOP_COMMON_PKG2.get_item_category_f(
                         cv_category_article_class
                        ,on_item_id
                       );
    -- 商品製品区分が製品以外は対象外
    IF   ( lt_article_class IS NULL )
      OR ( lt_article_class <> cv_article_class_product ) THEN
      --
      RAISE outside_scope_expt;
      --
    END IF;
    --
    --品目区分を取得
    lt_item_category := XXCOP_COMMON_PKG2.get_item_category_f(
                          cv_category_item_class
                          ,on_item_id
                        );
    --品目区分が製品以外は対象外(品目区分が未登録(NULL)は対象)
    IF ( lt_item_category <> cv_item_class_product ) THEN
      --
      RAISE outside_scope_expt;
      --
    END IF;
    --
  EXCEPTION
    WHEN outside_scope_expt THEN
      ov_retcode := cv_status_warn;
      ov_errbuf  := NULL;
      ov_errmsg  := NULL;
    WHEN NO_DATA_FOUND THEN
      ov_retcode := cv_status_error;
      ov_errbuf  := NULL;
      ov_errmsg  := NULL;
    WHEN OTHERS THEN
      ov_retcode := cv_status_error;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_errmsg  := NULL;
  END get_item_info;
  --
  /**********************************************************************************
   * Procedure Name   : get_shipment_result
   * Description      : 出荷実績取得
   ***********************************************************************************/
  PROCEDURE get_shipment_result(
     in_deliver_from_id        IN     NUMBER      -- OPM保管場所ID
    ,in_item_id                IN     NUMBER      -- OPM品目ID
    ,id_shipment_date_from     IN     DATE        -- 出荷実績期間FROM
    ,id_shipment_date_to       IN     DATE        -- 出荷実績期間TO
    ,iv_freshness_condition    IN     VARCHAR2    -- 鮮度条件
--20091201_Ver2.3_I_E_479_020_SCS.Goto_ADD_START
    ,in_inventory_item_id      IN     NUMBER      -- INV品目ID
--20091201_Ver2.3_I_E_479_020_SCS.Goto_ADD_END
    ,on_shipped_quantity       OUT    NUMBER      -- 出荷実績数
    ,ov_errbuf                 OUT    VARCHAR2    --   エラー・メッセージ           --# 固定 #
    ,ov_retcode                OUT    VARCHAR2    --   リターン・コード             --# 固定 #
    ,ov_errmsg                 OUT    VARCHAR2    --   ユーザー・エラー・メッセージ --# 固定 #
  ) IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name                CONSTANT VARCHAR2(100) := 'get_shipment_result'; -- プログラム名
    --
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    --
    cv_order_category_order    CONSTANT VARCHAR2(5) := 'ORDER';  -- 受注タイプ：ORDER
    cv_order_category_return   CONSTANT VARCHAR2(6) := 'RETURN'; -- 受注タイプ：RETURN
    cv_req_status_03           CONSTANT VARCHAR2(2) := '03';     -- 出荷依頼ステータス：締め済み
    cv_req_status_04           CONSTANT VARCHAR2(2) := '04';     -- 出荷依頼ステータス：出荷実績計上済
    cv_notif_status_40         CONSTANT VARCHAR2(2) := '40';     -- 通知ステータス：確定通知済
    cv_doc_type                CONSTANT VARCHAR2(2) := '10';     -- 文書タイプ：出荷
    cv_rec_type_10             CONSTANT VARCHAR2(2) := '10';     -- レコードタイプ：指示
    cv_rec_type_20             CONSTANT VARCHAR2(2) := '20';     -- レコードタイプ：出庫実績
    cv_shipping_shikyu_cls     CONSTANT VARCHAR2(1) := '1';      -- 出荷支給区分：出荷依頼
    cv_shipping_shikyu_cls_rtn CONSTANT VARCHAR2(1) := '3';      -- 出荷支給区分：倉替返品
    cv_adjs_class_1            CONSTANT VARCHAR2(1) := '1';      -- 在庫調整区分：在庫調整以外
    cv_adjs_class_2            CONSTANT VARCHAR2(1) := '2';      -- 在庫調整区分：在庫調整
    cv_yes                     CONSTANT VARCHAR2(1) := 'Y';      -- 固定値：YES
    cv_no                      CONSTANT VARCHAR2(1) := 'N';      -- 固定値：NO
    --
--
    -- *** ローカル変数 ***
    ln_critical_value           NUMBER;         -- 基準値
    lv_expt_value               VARCHAR2(100);  -- 例外パラメータ
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
    --例外定義
--
  BEGIN
    --==============================================================
    --ステータス初期化
    --==============================================================
    ov_retcode := cv_status_normal;
--
    --
    --  出荷実績未計上は出荷先_実績(RESULT_DELIVER_TO_ID)、出荷日(shipped_date)が
    --  NULLのため、出荷先ID(DELIVER_TO)、出荷予定日(SCHEDULE_SHIP_DATE)で集計する
    --  鮮度条件がNULLは全ての鮮度条件の出荷実績を集計する
    --
    --出荷実績集計
    SELECT SUM(shipped_quantity)
    INTO   on_shipped_quantity
    FROM   (
            -- 実績未計上
--20091201_Ver2.3_I_E_479_020_SCS.Goto_MOD_START
            SELECT /*+ LEADING(otta) */
                   NVL(SUM(CASE
--            SELECT NVL(SUM(CASE
--20091201_Ver2.3_I_E_479_020_SCS.Goto_MOD_END
                             WHEN (xmld.order_category_code = cv_order_category_order) THEN
                               xmld.actual_quantity - xmld.before_actual_quantity
                             WHEN (xmld.order_category_code = cv_order_category_return) THEN
                              (xmld.actual_quantity - xmld.before_actual_quantity) * -1
                           END), 0) shipped_quantity
            FROM xxcmn_party_sites          xps
                ,(
                  SELECT NVL(oha.shipped_date, oha.schedule_ship_date)    shipped_date
                        ,NVL(oha.result_deliver_to_id, oha.deliver_to_id) deliver_to_id
                        ,otta.order_category_code                         order_category_code
                        ,NVL(mld.actual_quantity, 0)                      actual_quantity
                        ,NVL(mld.before_actual_quantity, 0)               before_actual_quantity
                  FROM
                     xxwsh_order_headers_all    oha
                    ,xxwsh_order_lines_all      ola
                    ,xxinv_mov_lot_details      mld
                    ,oe_transaction_types_all   otta
                  WHERE oha.deliver_from_id       = in_deliver_from_id
--20091201_Ver2.3_I_E_479_020_SCS.Goto_MOD_START
                    AND oha.req_status            = cv_req_status_03
--                    AND oha.req_status           IN (cv_req_status_03,cv_req_status_04)
--20091201_Ver2.3_I_E_479_020_SCS.Goto_MOD_END
                    AND oha.notif_status          = cv_notif_status_40
                    AND oha.latest_external_flag  = cv_yes
                    --
                    AND oha.actual_confirm_class  = cv_no
                    --
                    AND oha.order_header_id       = ola.order_header_id
--20091201_Ver2.3_I_E_479_020_SCS.Goto_ADD_START
                    AND ola.shipping_inventory_item_id = in_inventory_item_id
--20091201_Ver2.3_I_E_479_020_SCS.Goto_ADD_END
                    AND ola.delete_flag           = cv_no
                    AND ola.order_line_id         = mld.mov_line_id
                    AND mld.item_id               = in_item_id
                    AND mld.document_type_code    = cv_doc_type
--20091201_Ver2.3_I_E_479_020_SCS.Goto_MOD_START
                    AND mld.record_type_code      = cv_rec_type_10
--                    AND mld.record_type_code     IN (cv_rec_type_10,cv_rec_type_20)
--20091201_Ver2.3_I_E_479_020_SCS.Goto_MOD_END
                    AND otta.attribute1          IN (cv_shipping_shikyu_cls,cv_shipping_shikyu_cls_rtn)
                    AND NVL( otta.attribute4, cv_adjs_class_1 ) <> cv_adjs_class_2
                    AND otta.transaction_type_id  = oha.order_type_id
                    AND otta.org_id               = FND_PROFILE.VALUE('ORG_ID')
                 ) xmld
            WHERE xmld.shipped_date  BETWEEN id_shipment_date_from
                                         AND id_shipment_date_to
              AND xmld.deliver_to_id       = xps.party_site_id
              AND xmld.shipped_date  BETWEEN NVL( xps.start_date_active, xmld.shipped_date )
                                         AND NVL( xps.end_date_active  , xmld.shipped_date )
              AND xps.freshness_condition   LIKE NVL(iv_freshness_condition, '%')
            UNION ALL
            -- 実績計上済
            SELECT NVL(SUM(CASE
                             WHEN (xmld.order_category_code = cv_order_category_order) THEN
                               xmld.actual_quantity - xmld.before_actual_quantity
                             WHEN (xmld.order_category_code = cv_order_category_return) THEN
                              (xmld.actual_quantity - xmld.before_actual_quantity) * -1
                           END), 0) shipped_quantity
            FROM xxcmn_party_sites          xps
                ,(
--20091201_Ver2.3_I_E_479_020_SCS.Goto_MOD_START
                  SELECT /*+ LEADING(otta) */
                         NVL(oha.shipped_date, oha.schedule_ship_date)    shipped_date
--                  SELECT NVL(oha.shipped_date, oha.schedule_ship_date)    shipped_date
--20091201_Ver2.3_I_E_479_020_SCS.Goto_MOD_END
                        ,NVL(oha.result_deliver_to_id, oha.deliver_to_id) deliver_to_id
                        ,otta.order_category_code                         order_category_code
                        ,NVL(mld.actual_quantity, 0)                      actual_quantity
                        ,NVL(mld.before_actual_quantity, 0)               before_actual_quantity
                  FROM
                     xxwsh_order_headers_all    oha
                    ,xxwsh_order_lines_all      ola
                    ,xxinv_mov_lot_details      mld
                    ,oe_transaction_types_all   otta
                  WHERE oha.deliver_from_id       = in_deliver_from_id
                    AND oha.req_status            = cv_req_status_04
                    AND oha.notif_status          = cv_notif_status_40
                    AND oha.latest_external_flag  = cv_yes
                    --
--20091201_Ver2.3_I_E_479_020_SCS.Goto_DEL_START
--                    AND oha.actual_confirm_class  = cv_yes
--20091201_Ver2.3_I_E_479_020_SCS.Goto_DEL_START
                    --
                    AND oha.order_header_id       = ola.order_header_id
--20091201_Ver2.3_I_E_479_020_SCS.Goto_ADD_START
                    AND ola.shipping_inventory_item_id = in_inventory_item_id
--20091201_Ver2.3_I_E_479_020_SCS.Goto_ADD_END
                    AND ola.delete_flag           = cv_no
                    AND ola.order_line_id         = mld.mov_line_id
                    AND mld.item_id               = in_item_id
                    AND mld.document_type_code    = cv_doc_type
                    AND mld.record_type_code      = cv_rec_type_20
                    AND otta.attribute1          IN (cv_shipping_shikyu_cls,cv_shipping_shikyu_cls_rtn)
                    AND NVL( otta.attribute4, cv_adjs_class_1 ) <> cv_adjs_class_2
                    AND otta.transaction_type_id  = oha.order_type_id
                    AND otta.org_id               = FND_PROFILE.VALUE('ORG_ID')
                 ) xmld
            WHERE xmld.shipped_date  BETWEEN id_shipment_date_from
                                         AND id_shipment_date_to
              AND xmld.deliver_to_id       = xps.party_site_id
              AND xmld.shipped_date  BETWEEN NVL( xps.start_date_active, xmld.shipped_date )
                                         AND NVL( xps.end_date_active  , xmld.shipped_date )
              AND xps.freshness_condition   LIKE NVL(iv_freshness_condition, '%')
           );
  --
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      ov_retcode   := cv_status_warn;
      ov_errbuf    := NULL;
      ov_errmsg    := NULL;
    WHEN OTHERS THEN
      ov_retcode   := cv_status_error;
      ov_errbuf    := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_errmsg    := NULL;
  --
  END get_shipment_result;
  --
  /**********************************************************************************
   * Procedure Name   : get_num_of_shipped
   * Description      : 鮮度条件別出荷実績取得
   ***********************************************************************************/
  PROCEDURE get_num_of_shipped(
     in_deliver_from_id        IN  NUMBER      -- OPM保管場所ID
    ,in_item_id                IN  NUMBER      -- OPM品目ID
    ,id_shipment_date_from     IN  DATE        -- 出荷実績期間FROM
    ,id_shipment_date_to       IN  DATE        -- 出荷実績期間TO
    ,iv_freshness_condition    IN  VARCHAR2    -- 鮮度条件
--20091201_Ver2.3_I_E_479_020_SCS.Goto_ADD_START
    ,in_inventory_item_id      IN  NUMBER      -- INV品目ID
--20091201_Ver2.3_I_E_479_020_SCS.Goto_ADD_END
    ,on_shipped_quantity       OUT NUMBER      -- 出荷実績数
    ,ov_errbuf                 OUT VARCHAR2    --   エラー・メッセージ           --# 固定 #
    ,ov_retcode                OUT VARCHAR2    --   リターン・コード             --# 固定 #
    ,ov_errmsg                 OUT VARCHAR2    --   ユーザー・エラー・メッセージ --# 固定 #
  ) IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name                CONSTANT VARCHAR2(100) := 'get_num_of_shipped'; -- プログラム名
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_dummy_frequent_whse     CONSTANT VARCHAR2(100) := 'XXCMN_DUMMY_FREQUENT_WHSE';  -- ダミー代表倉庫プロファイル
--
    -- *** ローカル変数 ***
    lv_errbuf                  VARCHAR2(5000);                                 -- エラー・メッセージ
    lv_retcode                 VARCHAR2(1);                                    -- リターン・コード
    lv_errmsg                  VARCHAR2(5000);                                 -- ユーザー・エラー・メッセージ
--
    lt_frq_loct_code           mtl_item_locations.segment1%TYPE;               -- ダミー代表倉庫
    lt_whse_code               mtl_item_locations.segment1%type;               -- 保管場所コード
    lt_rep_whse_code           mtl_item_locations.segment1%type;               -- 代表倉庫コード
    lt_rep_whse_id             mtl_item_locations.inventory_location_id%type;  -- 代表倉庫ID
    ln_shipped_quantity        NUMBER DEFAULT 0;                               -- 出荷実績数(自倉庫)
    ln_shipped_quantity_rep    NUMBER DEFAULT 0;                               -- 出荷実績数(代表倉庫)
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
    --例外定義
    profile_exp               EXCEPTION;     -- プロファイル取得失敗
    api_expt                  EXCEPTION;     -- 共通関数例外
--
  BEGIN
    --==============================================================
    --ステータス初期化
    --==============================================================
    ov_retcode := cv_status_normal;
    -- ダミー代表倉庫を取得
    lt_frq_loct_code := FND_PROFILE.VALUE(cv_dummy_frequent_whse);
    -- 取得に失敗した場合
    IF (lt_frq_loct_code IS NULL) THEN
      RAISE profile_exp;
    END IF ;
    --
    -- 自倉庫単独出荷実績取得
    XXCOP_COMMON_PKG2.get_shipment_result(
      in_deliver_from_id      => in_deliver_from_id      -- OPM保管場所ID
     ,in_item_id              => in_item_id              -- OPM品目ID
     ,id_shipment_date_from   => id_shipment_date_from   -- 出荷実績期間FROM
     ,id_shipment_date_to     => id_shipment_date_to     -- 出荷実績期間TO
     ,iv_freshness_condition  => iv_freshness_condition  -- 鮮度条件
--20091201_Ver2.3_I_E_479_020_SCS.Goto_ADD_START
     ,in_inventory_item_id    => in_inventory_item_id    -- INV品目ID
--20091201_Ver2.3_I_E_479_020_SCS.Goto_ADD_END
     ,on_shipped_quantity     => ln_shipped_quantity     -- 出荷実績数
     ,ov_errbuf               => lv_errbuf               -- エラー・メッセージ
     ,ov_retcode              => lv_retcode              -- リターン・コード
     ,ov_errmsg               => lv_errmsg               -- ユーザー・エラー・メッセージ
      );
  --
    IF (lv_retcode = cv_status_error) THEN
      RAISE api_expt;
    END IF;
--
    -- 代表倉庫取得
    BEGIN
      SELECT mil1.segment1              whse_code       -- 保管場所コード
            ,mil1.attribute5            rep_whse_code   -- 代表倉庫コード
            ,mil2.inventory_location_id rep_whse_id     -- 代表倉庫ID
      INTO   lt_whse_code
            ,lt_rep_whse_code
            ,lt_rep_whse_id
      FROM   mtl_item_locations         mil1            -- OPM保管場所(通常倉庫)
            ,mtl_item_locations         mil2            -- OPM保管場所(代表倉庫)
      WHERE  mil1.attribute5            = mil2.segment1(+)
      AND    mil1.inventory_location_id = in_deliver_from_id
      ORDER BY mil1.segment1
      ;
      --
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RAISE NO_DATA_FOUND;
    END;
    --
    -- 代表倉庫が自倉庫と同一、またはNULLの場合
    IF (  ( lt_whse_code     = lt_rep_whse_code ) 
       OR ( lt_rep_whse_code IS NULL            ) ) THEN
      -- 自倉庫が代表倉庫となるので出荷実績数(代表倉庫)に0を設定
      ln_shipped_quantity_rep := 0;
      --
    ELSE
      -- 代表倉庫がZZZZの場合
      IF ( lt_rep_whse_code = lt_frq_loct_code ) THEN
        -- 倉庫品目アドオンマスタより代表倉庫取得
        BEGIN
          SELECT frq_item_location_code   rep_whse_code  -- 代表倉庫コード
                ,frq_item_location_id     rep_whse_id    -- 代表倉庫ID
          INTO   lt_rep_whse_code
                ,lt_rep_whse_id
          FROM   xxwsh_frq_item_locations xfil           -- 倉庫品目アドオンマスタ
          WHERE  xfil.item_location_id = in_deliver_from_id
          AND    xfil.item_id          = in_item_id
          ;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            -- 品目別代表倉庫が取得できなかった場合は自倉庫が
            -- 代表倉庫となるのでで出荷実績数(代表倉庫)に0を設定
            ln_shipped_quantity_rep := 0;
            --
        END;
      END IF;
      --
      -- 取得した品目別代表倉庫の出荷実績取得
      XXCOP_COMMON_PKG2.get_shipment_result(
        in_deliver_from_id      => lt_rep_whse_id          -- OPM保管場所ID
       ,in_item_id              => in_item_id              -- OPM品目ID
       ,id_shipment_date_from   => id_shipment_date_from   -- 出荷実績期間FROM
       ,id_shipment_date_to     => id_shipment_date_to     -- 出荷実績期間TO
       ,iv_freshness_condition  => iv_freshness_condition  -- 鮮度条件
--20091201_Ver2.3_I_E_479_020_SCS.Goto_ADD_START
       ,in_inventory_item_id    => in_inventory_item_id    -- INV品目ID
--20091201_Ver2.3_I_E_479_020_SCS.Goto_ADD_END
       ,on_shipped_quantity     => ln_shipped_quantity_rep -- 出荷実績数
       ,ov_errbuf               => lv_errbuf               -- エラー・メッセージ
       ,ov_retcode              => lv_retcode              -- リターン・コード
       ,ov_errmsg               => lv_errmsg               -- ユーザー・エラー・メッセージ
        );
      --
      IF (lv_retcode = cv_status_error) THEN
        RAISE api_expt;
      END IF;
      --
    END IF;
    --
    -- 自倉庫と代表倉庫の出荷実績を合計
    on_shipped_quantity := ln_shipped_quantity + ln_shipped_quantity_rep;
    --
  EXCEPTION
    WHEN api_expt THEN
      ov_retcode          := cv_status_error;
      ov_errbuf           := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part|| lv_errbuf,1,5000);
      ov_errmsg           := lv_errmsg;
      on_shipped_quantity := 0;
    WHEN profile_exp THEN
      ov_retcode          := cv_status_error;
      ov_errbuf           := NULL;
      ov_errmsg           := NULL;
      on_shipped_quantity := 0;
    WHEN NO_DATA_FOUND THEN
      ov_retcode          := cv_status_warn;
      ov_errbuf           := NULL;
      ov_errmsg           := NULL;
      on_shipped_quantity := 0;
    WHEN OTHERS THEN
      ov_retcode          := cv_status_error;
      ov_errbuf           := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_errmsg           := NULL;
      on_shipped_quantity := 0;
  --
  END get_num_of_shipped;
  --
  /**********************************************************************************
   * Procedure Name   : get_num_of_forecast
   * Description      : 出荷予測取得処理
   ***********************************************************************************/
  PROCEDURE get_num_of_forecast(
    in_organization_id   IN  NUMBER       -- 在庫組織ID
   ,in_inventory_item_id IN  NUMBER       -- 在庫品目ID
   ,id_plan_date_from    IN  DATE         -- 出荷予測取得期間FROM
   ,id_plan_date_to      IN  DATE         -- 出荷予測取得期間TO
   ,in_loct_id           IN  NUMBER       -- OPM保管場所ID
   ,on_quantity          OUT  NUMBER      -- 出荷予測数量
   ,ov_errbuf            OUT  VARCHAR2    -- エラー・メッセージ
   ,ov_retcode           OUT  VARCHAR2    -- リターン・コード
   ,ov_errmsg            OUT  VARCHAR2)   -- ユーザー・エラー・メッセージ
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_num_of_forecast'; -- プログラム名
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    -- *** ローカル定数 ***
    cv_dummy_frequent_whse    CONSTANT VARCHAR2(100) := 'XXCMN_DUMMY_FREQUENT_WHSE';  -- ダミー代表倉庫プロファイル
    --
    cn_del_mark_n             CONSTANT NUMBER        := 0;   -- 有効
    cv_ship_plan_type         CONSTANT VARCHAR2(1)   := '1'; -- 基準計画分類（出荷予測）
    cn_schedule_level         CONSTANT NUMBER        := 2;   -- 基準計画レベル（レベル２）
    --
--
    -- *** ローカル変数 ***
    lt_frq_loct_code           mtl_item_locations.segment1%TYPE;               -- ダミー代表倉庫
    lt_whse_code               mtl_item_locations.segment1%type;               -- 保管場所コード
    lt_rep_whse_code           mtl_item_locations.segment1%type;               -- 代表倉庫コード
    lt_rep_whse_id             mtl_item_locations.inventory_location_id%type;  -- 代表倉庫ID
    lt_rep_org_id              mtl_item_locations.organization_id%type;        -- 代表倉庫組織ID
    ln_schedule_quantity       NUMBER DEFAULT 0;                               -- 出荷実績数(自倉庫)
    ln_schedule_quantity_rep   NUMBER DEFAULT 0;                               -- 出荷実績数(代表倉庫)
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
    --例外定義
    profile_exp               EXCEPTION;     -- プロファイル取得失敗
--
  BEGIN
    --==============================================================
    --ステータス初期化
    --==============================================================
    ov_retcode := cv_status_normal;
    --
    -- ダミー代表倉庫を取得
    lt_frq_loct_code := FND_PROFILE.VALUE(cv_dummy_frequent_whse);
    -- 取得に失敗した場合
    IF (lt_frq_loct_code IS NULL) THEN
      RAISE profile_exp;
    END IF ;
    --
     --==============================================================
    --自倉庫単独出荷予測取得
    --==============================================================
    SELECT NVL(SUM(msdd.schedule_quantity),0) stock_qty
    INTO   ln_schedule_quantity
    FROM   mrp_schedule_dates       msdd
          ,mrp_schedule_designators msdh
    WHERE  msdh.schedule_designator = msdd.schedule_designator
    AND    msdh.organization_id     = in_organization_id
    AND    msdh.organization_id     = msdd.organization_id
    AND    msdh.attribute1          = cv_ship_plan_type
    AND    msdd.schedule_date BETWEEN id_plan_date_from
                                  AND id_plan_date_to
    AND    msdd.inventory_item_id   = in_inventory_item_id
    AND    msdd.schedule_level      = cn_schedule_level
    ;
    --
    -- 代表倉庫取得
    BEGIN
      SELECT mil1.segment1              whse_code       -- 保管場所コード
            ,mil1.attribute5            rep_whse_code   -- 代表倉庫コード
            ,mil2.inventory_location_id rep_whse_id     -- 代表倉庫ID
            ,mil2.organization_id       rep_org_id      -- 代表倉庫組織ID
      INTO   lt_whse_code
            ,lt_rep_whse_code
            ,lt_rep_whse_id
            ,lt_rep_org_id
      FROM   mtl_item_locations         mil1            -- OPM保管場所(通常倉庫)
            ,mtl_item_locations         mil2            -- OPM保管場所(代表倉庫)
      WHERE  mil1.attribute5            = mil2.segment1(+)
      AND    mil1.organization_id       = in_organization_id
      AND    mil1.inventory_location_id = in_loct_id
      ORDER BY mil1.segment1
      ;
      --
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RAISE NO_DATA_FOUND;
    END;
    --
    -- 代表倉庫が自倉庫と同一、またはNULLまたは同一組織の場合
    IF (  ( lt_whse_code     = lt_rep_whse_code   )
       OR ( lt_rep_whse_code IS NULL              )
       OR ( lt_rep_org_id    = in_organization_id ) ) THEN
      -- 自倉庫が代表倉庫となるので出荷実績数(代表倉庫)に0を設定
      ln_schedule_quantity_rep := 0;
      --
    ELSE
      -- 代表倉庫がZZZZの場合
      IF ( lt_rep_whse_code = lt_frq_loct_code ) THEN
        -- 倉庫品目アドオンマスタより代表倉庫取得
        BEGIN
          SELECT frq_item_location_code   rep_whse_code  -- 代表倉庫コード
                ,frq_item_location_id     rep_whse_id    -- 代表倉庫ID
                ,mil.organization_id      rep_org_id     -- 代表倉庫組織ID
          INTO   lt_rep_whse_code
                ,lt_rep_whse_id
                ,lt_rep_org_id
          FROM   xxwsh_frq_item_locations xfil           -- 倉庫品目アドオンマスタ
                ,mtl_item_locations       mil            -- OPM保管場所マスタ
          WHERE  xfil.frq_item_location_id = mil.inventory_location_id
          AND    xfil.item_location_id     = in_loct_id
          AND    xfil.item_id              = in_inventory_item_id
          ;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            -- 品目別代表倉庫が取得できなかった場合は自倉庫が
            -- 代表倉庫となるのでで出荷実績数(代表倉庫)に0を設定
            ln_schedule_quantity_rep := 0;
            --
        END;
      END IF;
      --
      -- 取得した品目別代表倉庫の出荷実績取得
      SELECT NVL(SUM(msdd.schedule_quantity),0) stock_qty
      INTO   ln_schedule_quantity_rep
      FROM   mrp_schedule_dates       msdd
            ,mrp_schedule_designators msdh
      WHERE  msdh.schedule_designator = msdd.schedule_designator
      AND    msdh.organization_id     = lt_rep_org_id
      AND    msdh.organization_id     = msdd.organization_id
      AND    msdh.attribute1          = cv_ship_plan_type
      AND    msdd.schedule_date BETWEEN id_plan_date_from
                                    AND id_plan_date_to
      AND    msdd.inventory_item_id   = in_inventory_item_id
      AND    msdd.schedule_level      = cn_schedule_level
      ;
      --
    END IF;
    --
    -- 自倉庫と代表倉庫の出荷実績を合計
    on_quantity := ln_schedule_quantity + ln_schedule_quantity_rep;
    --
  EXCEPTION
    WHEN profile_exp THEN
      ov_retcode          := cv_status_error;
      ov_errbuf           := NULL;
      ov_errmsg           := NULL;
      on_quantity := 0;
    WHEN NO_DATA_FOUND THEN
      ov_retcode       := cv_status_warn;
      ov_errbuf        := NULL;
      ov_errmsg        := NULL;
      on_quantity      := cn_zero;
    WHEN OTHERS THEN
      ov_retcode       := cv_status_error;
      ov_errbuf        := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_errmsg        := NULL;
      on_quantity      := NULL;
  END get_num_of_forecast;
  --
  /**********************************************************************************
   * Procedure Name   : get_stock_plan
   * Description      : 入庫予定取得処理
   ***********************************************************************************/
  PROCEDURE get_stock_plan(
    in_loct_id           IN   NUMBER       -- 保管場所ID
   ,in_item_id           IN   NUMBER       -- 品目ID
   ,id_plan_date_from    IN   DATE         -- 計画期間From
   ,id_plan_date_to      IN   DATE         -- 計画期間To
   ,on_quantity          OUT  NUMBER       -- 計画数
   ,ov_errbuf            OUT  VARCHAR2     -- エラー・メッセージ          
   ,ov_retcode           OUT  VARCHAR2     -- リターン・コード            
   ,ov_errmsg            OUT  VARCHAR2)    -- ユーザー・エラー・メッセージ
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name       CONSTANT VARCHAR2(100) := 'get_stock_plan'; -- プログラム名
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_dummy_frequent_whse     CONSTANT VARCHAR2(100) := 'XXCMN_DUMMY_FREQUENT_WHSE';  -- ダミー代表倉庫プロファイル
--
    -- *** ローカル変数 ***
    lt_frq_loct_code           mtl_item_locations.segment1%TYPE;  -- ダミー代表倉庫
    lt_whse_code               mtl_item_locations.segment1%type;  -- 保管場所コード
    lt_rep_whse_code           mtl_item_locations.segment1%type;  -- 代表倉庫コード
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
    --例外定義
    profile_exp               EXCEPTION;     -- プロファイル取得失敗
--
  BEGIN
    --==============================================================
    --ステータス初期化
    --==============================================================
    ov_retcode := cv_status_normal;
    --
    -- ダミー代表倉庫を取得
    lt_frq_loct_code := FND_PROFILE.VALUE(cv_dummy_frequent_whse);
    -- 取得に失敗した場合
    IF (lt_frq_loct_code IS NULL) THEN
      RAISE profile_exp;
    END IF;
    --
    -- 代表倉庫を取得
    SELECT mil.segment1    whse_code      -- 保管場所コード
          ,mil.attribute5  rep_whse_code  -- 代表倉庫コード
    INTO   lt_whse_code
          ,lt_rep_whse_code
    FROM   mtl_item_locations mil         -- OPM保管場所
    WHERE  mil.inventory_location_id = in_loct_id
    ;
    --==============================================================
    --入庫予定取得処理
    --==============================================================
    -- 代表倉庫が自倉庫と同一の場合
    IF ( lt_whse_code = lt_rep_whse_code ) THEN
      SELECT NVL(SUM(TRUNC(xliv.loct_onhand)), 0) supplies_quantity
      INTO   on_quantity
      FROM   (
        SELECT xliv.lot_id                                lot_id
              ,xliv.lot_no                                lot_no
              ,xliv.manufacture_date                      manufacture_date
              ,xliv.expiration_date                       expiration_date
              ,xliv.unique_sign                           unique_sign
              ,xliv.lot_status                            lot_status
              ,CASE 
                 WHEN SUM(xliv.unlimited_loct_onhand) < SUM(xliv.limited_loct_onhand)
                   THEN SUM(xliv.unlimited_loct_onhand)
                 ELSE SUM(xliv.limited_loct_onhand)
               END loct_onhand
        FROM   ( 
          SELECT xliv.lot_id            lot_id
                ,xliv.lot_no            lot_no
                ,xliv.manufacture_date  manufacture_date
                ,xliv.expiration_date   expiration_date
                ,xliv.unique_sign        unique_sign
                ,xliv.lot_status        lot_status
                ,xliv.loct_onhand       unlimited_loct_onhand
                ,CASE 
                   WHEN xliv.schedule_date <= id_plan_date_to
                     THEN xliv.loct_onhand
                   ELSE 0
                 END limited_loct_onhand
          FROM   xxcop_loct_inv_v xliv  -- 手持在庫ビュー
          WHERE  (   xliv.schedule_date >  id_plan_date_from
                 AND xliv.schedule_date <= id_plan_date_to   )
--20091201_Ver2.3_I_E_479_020_SCS.Goto_MOD_START
          AND EXISTS (
                   SELECT mil.segment1
                   FROM   mtl_item_locations mil  -- OPM保管場所
                   WHERE  mil.attribute5 = lt_rep_whse_code
                   AND    mil.segment1 = xliv.loct_code
                   UNION ALL
                   SELECT xfil.item_location_code
                   FROM   xxwsh_frq_item_locations xfil  -- 倉庫品目アドオン
                   WHERE  xfil.frq_item_location_code = lt_rep_whse_code
                   AND    xfil.item_id                = in_item_id
                   AND    xfil.item_location_code     = xliv.loct_code
          )
--          AND    xliv.loct_code IN (
--                   SELECT mil.segment1
--                   FROM   mtl_item_locations mil  -- OPM保管場所
--                   WHERE  mil.attribute5 = lt_rep_whse_code
--                   UNION
--                   SELECT xfil.item_location_code
--                   FROM   xxwsh_frq_item_locations xfil  -- 倉庫品目アドオン
--                   WHERE  xfil.frq_item_location_code = lt_rep_whse_code
--                   AND    xfil.item_id                = in_item_id
--                   )
--20091201_Ver2.3_I_E_479_020_SCS.Goto_MOD_END
          AND    xliv.item_id        = in_item_id
          ) xliv
        GROUP BY xliv.lot_id
                ,xliv.lot_no
                ,xliv.manufacture_date
                ,xliv.expiration_date
                ,xliv.unique_sign
                ,xliv.lot_status
        )xliv
      ;
      -- 正常に取得できた場合は処理を終了
      RETURN;
      --
    ELSE
      -- 自倉庫が配下倉庫の場合
      -- 代表倉庫がダミー代表倉庫の場合
      IF ( lt_rep_whse_code = lt_frq_loct_code ) THEN
        -- 倉庫品目アドオンを参照し代表倉庫を取得
        -- その手持在庫数が0未満の場合は自倉庫手持在庫より減算
        SELECT NVL(SUM(TRUNC(xliv.loct_onhand)), 0) supplies_quantity
        INTO   on_quantity
        FROM   (
          SELECT xliv.lot_id                   lot_id
                ,xliv.lot_no                   lot_no
                ,xliv.manufacture_date         manufacture_date
                ,xliv.expiration_date          expiration_date
                ,xliv.unique_sign              unique_sign
                ,xliv.lot_status               lot_status
                ,CASE
                   WHEN SUM(xliv.unlimited_loct_onhand) < SUM(xliv.limited_loct_onhand)
                     THEN SUM(xliv.unlimited_loct_onhand)
                   ELSE SUM(xliv.limited_loct_onhand)
                 END                           loct_onhand
          FROM ( 
            SELECT xliv.lot_id            lot_id
                  ,xliv.lot_no            lot_no
                  ,xliv.manufacture_date  manufacture_date
                  ,xliv.expiration_date   expiration_date
                  ,xliv.unique_sign       unique_sign
                  ,xliv.lot_status        lot_status
                  ,xliv.loct_onhand       unlimited_loct_onhand
                  ,CASE 
                     WHEN xliv.schedule_date <= id_plan_date_to
                       THEN xliv.loct_onhand
                     ELSE 0
                   END                    limited_loct_onhand
            FROM   xxcop_loct_inv_v         xliv
            WHERE  xliv.item_id        = in_item_id
            AND    (   xliv.schedule_date >  id_plan_date_from
                   AND xliv.schedule_date <= id_plan_date_to   )
            AND    xliv.loct_code      = lt_whse_code
            --
            UNION ALL
            SELECT xliv.lot_id                 lot_id
                  ,xliv.lot_no                 lot_no
                  ,xliv.manufacture_date       manufacture_date
                  ,xliv.expiration_date        expiration_date
                  ,xliv.unique_sign            unique_sign
                  ,xliv.lot_status             lot_status
                  ,LEAST(xliv.loct_onhand, 0)  unlimited_loct_onhand
                  ,CASE 
                     WHEN xliv.schedule_date <= id_plan_date_to
                       THEN LEAST(xliv.loct_onhand, 0)
                     ELSE 0
                   END                         limited_loct_onhand
            FROM   (
              SELECT xliv.lot_id            lot_id
                    ,xliv.lot_no            lot_no
                    ,xliv.manufacture_date  manufacture_date
                    ,xliv.expiration_date   expiration_date
                    ,xliv.unique_sign       unique_sign
                    ,xliv.lot_status        lot_status
                    ,xliv.schedule_date     schedule_date
                    ,SUM(xliv.loct_onhand)  loct_onhand
              FROM   xxcop_loct_inv_v              xliv
              WHERE  xliv.item_id            = in_item_id
              AND    (   xliv.schedule_date >  id_plan_date_from
                     AND xliv.schedule_date <= id_plan_date_to   )
              AND    xliv.loct_code IN ( 
                       SELECT xfil.frq_item_location_code    -- 代表倉庫
                       FROM   xxwsh_frq_item_locations xfil  -- 倉庫品目アドオン
                       WHERE  xfil.item_location_code = lt_whse_code
                       AND    xfil.item_id            = in_item_id
                       )
              GROUP BY xliv.lot_id
                      ,xliv.lot_no
                      ,xliv.manufacture_date
                      ,xliv.expiration_date
                      ,xliv.unique_sign
                      ,xliv.lot_status
                      ,xliv.schedule_date
              ) xliv
            )xliv
          GROUP BY xliv.lot_id
                  ,xliv.lot_no
                  ,xliv.manufacture_date
                  ,xliv.expiration_date
                  ,xliv.unique_sign
                  ,xliv.lot_status
          ) xliv
        ;
        --
      -- 代表倉庫設定が未設定(NULL)の場合
      ELSIF ( lt_rep_whse_code IS NULL ) THEN
        -- 自倉庫単独の在庫数量取得
        SELECT NVL(SUM(TRUNC(xliv.loct_onhand)), 0) supplies_quantity
        INTO   on_quantity
        FROM   (
          SELECT xliv.lot_id              lot_id
                ,xliv.lot_no              lot_no
                ,xliv.manufacture_date    manufacture_date
                ,xliv.expiration_date     expiration_date
                ,xliv.unique_sign         unique_sign
                ,xliv.lot_status          lot_status
                ,CASE 
                   WHEN SUM(xliv.unlimited_loct_onhand) < SUM(xliv.limited_loct_onhand)
                     THEN SUM(xliv.unlimited_loct_onhand)
                   ELSE SUM(xliv.limited_loct_onhand)
                 END                      loct_onhand
          FROM ( 
            SELECT xliv.lot_id            lot_id
                  ,xliv.lot_no            lot_no
                  ,xliv.manufacture_date  manufacture_date
                  ,xliv.expiration_date   expiration_date
                  ,xliv.unique_sign        unique_sign
                  ,xliv.lot_status        lot_status
                  ,xliv.loct_onhand       unlimited_loct_onhand
                  ,CASE 
                     WHEN xliv.schedule_date <= id_plan_date_to
                       THEN xliv.loct_onhand
                     ELSE 0
                   END                    limited_loct_onhand
            FROM   xxcop_loct_inv_v         xliv
            WHERE  xliv.item_id        = in_item_id
            AND    (   xliv.schedule_date >  id_plan_date_from
                   AND xliv.schedule_date <= id_plan_date_to   )
            AND    xliv.loct_code      = lt_whse_code
            ) xliv
          GROUP BY xliv.lot_id
                  ,xliv.lot_no
                  ,xliv.manufacture_date
                  ,xliv.expiration_date
                  ,xliv.unique_sign
                  ,xliv.lot_status
          ) xliv
        ;
        --
      ELSE
        -- 代表倉庫に自倉庫以外の倉庫の設定がある場合
        SELECT NVL(SUM(TRUNC(xliv.loct_onhand)), 0) supplies_quantity
        INTO   on_quantity
        FROM   (
          SELECT xliv.lot_id              lot_id
                ,xliv.lot_no              lot_no
                ,xliv.manufacture_date    manufacture_date
                ,xliv.expiration_date     expiration_date
                 ,xliv.unique_sign        unique_sign
                ,xliv.lot_status          lot_status
                ,CASE 
                   WHEN SUM(xliv.unlimited_loct_onhand) < SUM(xliv.limited_loct_onhand)
                     THEN SUM(xliv.unlimited_loct_onhand)
                   ELSE SUM(xliv.limited_loct_onhand)
                 END                      loct_onhand
          FROM ( 
            SELECT xliv.lot_id            lot_id
                  ,xliv.lot_no            lot_no
                  ,xliv.manufacture_date  manufacture_date
                  ,xliv.expiration_date   expiration_date
                  ,xliv.unique_sign        unique_sign
                  ,xliv.lot_status        lot_status
                  ,xliv.loct_onhand       unlimited_loct_onhand
                  ,CASE 
                     WHEN xliv.schedule_date <= id_plan_date_to
                       THEN xliv.loct_onhand
                     ELSE 0
                   END                    limited_loct_onhand
            FROM   xxcop_loct_inv_v         xliv
            WHERE  xliv.item_id        = in_item_id
            AND    (   xliv.schedule_date >  id_plan_date_from
                   AND xliv.schedule_date <= id_plan_date_to   )
            AND    xliv.loct_code      = lt_whse_code
             --
            UNION ALL
            SELECT xliv.lot_id                 lot_id
                  ,xliv.lot_no                 lot_no
                  ,xliv.manufacture_date       manufacture_date
                  ,xliv.expiration_date        expiration_date
                  ,xliv.unique_sign            unique_sign
                  ,xliv.lot_status             lot_status
                  ,LEAST(xliv.loct_onhand, 0)  unlimited_loct_onhand
                  ,CASE 
                     WHEN xliv.schedule_date <= id_plan_date_to
                       THEN LEAST(xliv.loct_onhand, 0)
                     ELSE 0
                   END                         limited_loct_onhand
            FROM   (
              SELECT xliv.lot_id                               lot_id
                    ,xliv.lot_no                               lot_no
                    ,xliv.manufacture_date                     manufacture_date
                    ,xliv.expiration_date                      expiration_date
                    ,xliv.unique_sign                          unique_sign
                    ,xliv.lot_status                           lot_status
                    ,xliv.schedule_date                        schedule_date
                    ,SUM(xliv.loct_onhand)                     loct_onhand
              FROM   xxcop_loct_inv_v          xliv
              WHERE  xliv.item_id        = in_item_id
              AND    (   xliv.schedule_date >  id_plan_date_from
                     AND xliv.schedule_date <= id_plan_date_to   )
              AND    xliv.loct_code      = lt_rep_whse_code
              GROUP BY xliv.lot_id
                  ,xliv.lot_no
                  ,xliv.manufacture_date
                  ,xliv.expiration_date
                  ,xliv.unique_sign
                  ,xliv.lot_status
                  ,xliv.schedule_date
              ) xliv
            ) xliv
          GROUP BY xliv.lot_id
                  ,xliv.lot_no
                  ,xliv.manufacture_date
                  ,xliv.expiration_date
                  ,xliv.unique_sign
                  ,xliv.lot_status
          ) xliv
        ;
        --
      END IF;
      --
    END IF;
    --
  EXCEPTION
    WHEN profile_exp THEN
      ov_retcode          := cv_status_error;
      ov_errbuf           := NULL;
      ov_errmsg           := NULL;
      on_quantity := 0;
      --
    WHEN OTHERS THEN
      ov_retcode       := cv_status_error;
      ov_errbuf        := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_errmsg        := NULL;
      on_quantity      := NULL;
  END get_stock_plan;
  --
  /**********************************************************************************
   * Procedure Name   : get_onhand_qty
   * Description      : 手持在庫取得処理
   ***********************************************************************************/
  PROCEDURE get_onhand_qty(
    in_loct_id           IN   NUMBER       -- 保管場所ID
   ,in_item_id           IN   NUMBER       -- 品目ID
   ,id_target_date       IN   DATE         -- 対象日付
   ,id_allocated_date    IN   DATE         -- 引当済日
   ,on_quantity          OUT  NUMBER       -- 手持在庫数量
   ,ov_errbuf            OUT  VARCHAR2     -- エラー・メッセージ          
   ,ov_retcode           OUT  VARCHAR2     -- リターン・コード            
   ,ov_errmsg            OUT  VARCHAR2)    -- ユーザー・エラー・メッセージ
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name       CONSTANT VARCHAR2(100) := 'get_onhand_qty'; -- プログラム名
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_dummy_frequent_whse     CONSTANT VARCHAR2(100) := 'XXCMN_DUMMY_FREQUENT_WHSE';  -- ダミー代表倉庫プロファイル
--
    -- *** ローカル変数 ***
    lt_frq_loct_code           mtl_item_locations.segment1%TYPE;  -- ダミー代表倉庫
    lt_whse_code               mtl_item_locations.segment1%type;  -- 保管場所コード
    lt_rep_whse_code           mtl_item_locations.segment1%type;  -- 代表倉庫コード
    --
    ln_onhand_qty              NUMBER;                            -- 手持在庫数量(自倉庫単独)
    ln_rep_onhand_qty          NUMBER;                            -- 手持在庫数量(代表倉庫単独)
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
    --例外定義
    profile_exp               EXCEPTION;     -- プロファイル取得失敗
--
  BEGIN
    --==============================================================
    --ステータス初期化
    --==============================================================
    ov_retcode := cv_status_normal;
    --
    -- ダミー代表倉庫を取得
    lt_frq_loct_code := FND_PROFILE.VALUE(cv_dummy_frequent_whse);
    -- 取得に失敗した場合
    IF (lt_frq_loct_code IS NULL) THEN
      RAISE profile_exp;
    END IF ;
    --
    -- 代表倉庫を取得
    SELECT mil.segment1    whse_code      -- 保管場所コード
          ,mil.attribute5  rep_whse_code  -- 代表倉庫コード
    INTO   lt_whse_code
          ,lt_rep_whse_code
    FROM   mtl_item_locations mil         -- OPM保管場所
    WHERE  mil.inventory_location_id = in_loct_id
    ;
    --
    --==============================================================
    --手持在庫取得
    --==============================================================
    -- 代表倉庫が自倉庫と同一の場合
    IF( lt_whse_code = lt_rep_whse_code ) THEN
      -- 代表倉庫をキーに手持在庫数を集計(自倉庫+配下倉庫)
      SELECT NVL(SUM(xliv.loct_onhand), 0) supplies_quantity
      INTO   on_quantity
      FROM   (
        SELECT xliv.lot_id                                lot_id
              ,xliv.lot_no                                lot_no
              ,xliv.manufacture_date                      manufacture_date
              ,xliv.expiration_date                       expiration_date
              ,xliv.unique_sign                           unique_sign
              ,xliv.lot_status                            lot_status
              ,CASE 
                 WHEN SUM(xliv.unlimited_loct_onhand) < SUM(xliv.limited_loct_onhand)
                   THEN SUM(xliv.unlimited_loct_onhand)
                 ELSE SUM(xliv.limited_loct_onhand)
               END loct_onhand
        FROM   ( 
          SELECT xliv.lot_id            lot_id
                ,xliv.lot_no            lot_no
                ,xliv.manufacture_date  manufacture_date
                ,xliv.expiration_date   expiration_date
                ,xliv.unique_sign        unique_sign
                ,xliv.lot_status        lot_status
                ,xliv.loct_onhand       unlimited_loct_onhand
                ,CASE 
                   WHEN xliv.schedule_date <= id_target_date
                     THEN xliv.loct_onhand
                   ELSE 0
                 END limited_loct_onhand
          FROM   xxcop_loct_inv_v xliv  -- 手持在庫ビュー
          WHERE  xliv.shipment_date <= id_allocated_date
--20091201_Ver2.3_I_E_479_020_SCS.Goto_MOD_START
          AND EXISTS (
                   SELECT mil.segment1
                   FROM   mtl_item_locations mil  -- OPM保管場所
                   WHERE  mil.attribute5 = lt_rep_whse_code
                   AND    mil.segment1 = xliv.loct_code
                   UNION ALL
                   SELECT xfil.item_location_code
                   FROM   xxwsh_frq_item_locations xfil  -- 倉庫品目アドオン
                   WHERE  xfil.frq_item_location_code = lt_rep_whse_code
                   AND    xfil.item_id                = in_item_id
                   AND    xfil.item_location_code     = xliv.loct_code
          )
--          AND    xliv.loct_code IN (
--                   SELECT mil.segment1
--                   FROM   mtl_item_locations mil  -- OPM保管場所
--                   WHERE  mil.attribute5 = lt_rep_whse_code
--                   UNION
--                   SELECT xfil.item_location_code
--                   FROM   xxwsh_frq_item_locations xfil  -- 倉庫品目アドオン
--                   WHERE  xfil.frq_item_location_code = lt_rep_whse_code
--                   AND    xfil.item_id                = in_item_id
--                   )
--20091201_Ver2.3_I_E_479_020_SCS.Goto_MOD_END
          AND    xliv.item_id        = in_item_id
          ) xliv
        GROUP BY xliv.lot_id
                ,xliv.lot_no
                ,xliv.manufacture_date
                ,xliv.expiration_date
                ,xliv.unique_sign
                ,xliv.lot_status
        )xliv
      ;
      -- 正常に取得できた場合は処理を終了
      RETURN;
      --
    ELSE
      -- 配下倉庫の手持在庫数量算出
      -- 代表倉庫がダミー代表倉庫の場合
      IF (lt_rep_whse_code = lt_frq_loct_code ) THEN
        -- 倉庫品目アドオンを参照し代表倉庫を取得し、
        -- その手持在庫数が0未満の場合は自倉庫手持在庫から減算
        SELECT NVL(SUM(xliv.loct_onhand), 0) supplies_quantity
        INTO   on_quantity
        FROM   (
          SELECT xliv.lot_id                   lot_id
                ,xliv.lot_no                   lot_no
                ,xliv.manufacture_date         manufacture_date
                ,xliv.expiration_date          expiration_date
                ,xliv.unique_sign              unique_sign
                ,xliv.lot_status               lot_status
                ,CASE
                   WHEN SUM(xliv.unlimited_loct_onhand) < SUM(xliv.limited_loct_onhand)
                     THEN SUM(xliv.unlimited_loct_onhand)
                   ELSE SUM(xliv.limited_loct_onhand)
                 END                           loct_onhand
          FROM ( 
            SELECT xliv.lot_id            lot_id
                  ,xliv.lot_no            lot_no
                  ,xliv.manufacture_date  manufacture_date
                  ,xliv.expiration_date   expiration_date
                  ,xliv.unique_sign       unique_sign
                  ,xliv.lot_status        lot_status
                  ,xliv.loct_onhand       unlimited_loct_onhand
                  ,CASE 
                     WHEN xliv.schedule_date <= id_target_date
                       THEN xliv.loct_onhand
                     ELSE 0
                   END                    limited_loct_onhand
            FROM   xxcop_loct_inv_v         xliv
            WHERE  xliv.item_id        = in_item_id
            AND    xliv.shipment_date <= id_allocated_date
            AND    xliv.loct_code      = lt_whse_code
             --
            UNION ALL
            SELECT xliv.lot_id                 lot_id
                  ,xliv.lot_no                 lot_no
                  ,xliv.manufacture_date       manufacture_date
                  ,xliv.expiration_date        expiration_date
                  ,xliv.unique_sign            unique_sign
                  ,xliv.lot_status             lot_status
                  ,LEAST(xliv.loct_onhand, 0)  unlimited_loct_onhand
                  ,CASE 
                     WHEN xliv.schedule_date <= id_target_date
                       THEN LEAST(xliv.loct_onhand, 0)
                     ELSE 0
                   END                         limited_loct_onhand
            FROM   (
              SELECT xliv.lot_id            lot_id
                    ,xliv.lot_no            lot_no
                    ,xliv.manufacture_date  manufacture_date
                    ,xliv.expiration_date   expiration_date
                    ,xliv.unique_sign       unique_sign
                    ,xliv.lot_status        lot_status
                    ,xliv.schedule_date     schedule_date
                    ,SUM(xliv.loct_onhand)  loct_onhand
              FROM   xxcop_loct_inv_v              xliv
              WHERE  xliv.item_id            = in_item_id
              AND    xliv.shipment_date     <= id_allocated_date
              AND    xliv.loct_code IN ( 
                       SELECT xfil.frq_item_location_code    -- 代表倉庫
                       FROM   xxwsh_frq_item_locations xfil  -- 倉庫品目アドオン
                       WHERE  xfil.item_location_code = lt_whse_code
                       AND    xfil.item_id            = in_item_id
                       )
              GROUP BY xliv.lot_id
                      ,xliv.lot_no
                      ,xliv.manufacture_date
                      ,xliv.expiration_date
                      ,xliv.unique_sign
                      ,xliv.lot_status
                      ,xliv.schedule_date
              ) xliv
            )xliv
          GROUP BY xliv.lot_id
                  ,xliv.lot_no
                  ,xliv.manufacture_date
                  ,xliv.expiration_date
                  ,xliv.unique_sign
                  ,xliv.lot_status
          ) xliv
        ;
        --
      -- 代表倉庫設定が未設定(NULL)の場合
      ELSIF ( lt_rep_whse_code IS NULL ) THEN
        -- 自倉庫単独の在庫数量取得
        SELECT NVL(SUM(xliv.loct_onhand), 0) supplies_quantity
        INTO   on_quantity
        FROM   (
          SELECT xliv.lot_id              lot_id
                ,xliv.lot_no              lot_no
                ,xliv.manufacture_date    manufacture_date
                ,xliv.expiration_date     expiration_date
                ,xliv.unique_sign         unique_sign
                ,xliv.lot_status          lot_status
                ,CASE 
                   WHEN SUM(xliv.unlimited_loct_onhand) < SUM(xliv.limited_loct_onhand)
                     THEN SUM(xliv.unlimited_loct_onhand)
                   ELSE SUM(xliv.limited_loct_onhand)
                 END                      loct_onhand
          FROM ( 
            SELECT xliv.lot_id            lot_id
                  ,xliv.lot_no            lot_no
                  ,xliv.manufacture_date  manufacture_date
                  ,xliv.expiration_date   expiration_date
                  ,xliv.unique_sign        unique_sign
                  ,xliv.lot_status        lot_status
                  ,xliv.loct_onhand       unlimited_loct_onhand
                  ,CASE 
                     WHEN xliv.schedule_date <= id_target_date
                       THEN xliv.loct_onhand
                     ELSE 0
                   END                    limited_loct_onhand
            FROM   xxcop_loct_inv_v         xliv
            WHERE  xliv.item_id        = in_item_id
            AND    xliv.shipment_date <= id_allocated_date
            AND    xliv.loct_code      = lt_whse_code
            ) xliv
          GROUP BY xliv.lot_id
                  ,xliv.lot_no
                  ,xliv.manufacture_date
                  ,xliv.expiration_date
                  ,xliv.unique_sign
                  ,xliv.lot_status
          ) xliv
        ;
        --
      ELSE
        -- 代表倉庫に自倉庫以外の倉庫の設定がある場合
        SELECT NVL(SUM(xliv.loct_onhand), 0) supplies_quantity
        INTO   on_quantity
        FROM   (
          SELECT xliv.lot_id              lot_id
                ,xliv.lot_no              lot_no
                ,xliv.manufacture_date    manufacture_date
                ,xliv.expiration_date     expiration_date
                 ,xliv.unique_sign        unique_sign
                ,xliv.lot_status          lot_status
                ,CASE 
                   WHEN SUM(xliv.unlimited_loct_onhand) < SUM(xliv.limited_loct_onhand)
                     THEN SUM(xliv.unlimited_loct_onhand)
                   ELSE SUM(xliv.limited_loct_onhand)
                 END                      loct_onhand
          FROM ( 
            SELECT xliv.lot_id            lot_id
                  ,xliv.lot_no            lot_no
                  ,xliv.manufacture_date  manufacture_date
                  ,xliv.expiration_date   expiration_date
                  ,xliv.unique_sign        unique_sign
                  ,xliv.lot_status        lot_status
                  ,xliv.loct_onhand       unlimited_loct_onhand
                  ,CASE 
                     WHEN xliv.schedule_date <= id_target_date
                       THEN xliv.loct_onhand
                     ELSE 0
                   END                    limited_loct_onhand
            FROM   xxcop_loct_inv_v         xliv
            WHERE  xliv.item_id        = in_item_id
            AND    xliv.shipment_date <= id_allocated_date
            AND    xliv.loct_code      = lt_whse_code
             --
            UNION ALL
            SELECT xliv.lot_id                 lot_id
                  ,xliv.lot_no                 lot_no
                  ,xliv.manufacture_date       manufacture_date
                  ,xliv.expiration_date        expiration_date
                  ,xliv.unique_sign            unique_sign
                  ,xliv.lot_status             lot_status
                  ,LEAST(xliv.loct_onhand, 0)  unlimited_loct_onhand
                  ,CASE 
                     WHEN xliv.schedule_date <= id_target_date
                       THEN LEAST(xliv.loct_onhand, 0)
                     ELSE 0
                   END                         limited_loct_onhand
            FROM   (
              SELECT xliv.lot_id                               lot_id
                    ,xliv.lot_no                               lot_no
                    ,xliv.manufacture_date                     manufacture_date
                    ,xliv.expiration_date                      expiration_date
                    ,xliv.unique_sign                          unique_sign
                    ,xliv.lot_status                           lot_status
                    ,xliv.schedule_date                        schedule_date
                    ,SUM(xliv.loct_onhand)                     loct_onhand
              FROM   xxcop_loct_inv_v          xliv
              WHERE  xliv.item_id        = in_item_id
              AND    xliv.shipment_date <= id_allocated_date
              AND    xliv.loct_code      = lt_rep_whse_code
              GROUP BY xliv.lot_id
                  ,xliv.lot_no
                  ,xliv.manufacture_date
                  ,xliv.expiration_date
                  ,xliv.unique_sign
                  ,xliv.lot_status
                  ,xliv.schedule_date
              ) xliv
            ) xliv
          GROUP BY xliv.lot_id
                  ,xliv.lot_no
                  ,xliv.manufacture_date
                  ,xliv.expiration_date
                  ,xliv.unique_sign
                  ,xliv.lot_status
          ) xliv
        ;
        --
      END IF;
      --
    END IF;
    --
  EXCEPTION
    WHEN profile_exp THEN
      ov_retcode          := cv_status_error;
      ov_errbuf           := NULL;
      ov_errmsg           := NULL;
      on_quantity := 0;
      --
    WHEN OTHERS THEN
      ov_retcode       := cv_status_error;
      ov_errbuf        := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_errmsg        := NULL;
      on_quantity      := NULL;
  END get_onhand_qty;
  --
  /**********************************************************************************
   * Procedure Name   : get_deliv_lead_time
   * Description      : 配送リードタイム取得処理
   ***********************************************************************************/
  PROCEDURE get_deliv_lead_time(
     id_target_date     IN  DATE         -- 対象日付
    ,iv_from_loct_code  IN  VARCHAR2     -- 出荷保管倉庫コード
    ,iv_to_loct_code    IN  VARCHAR2     -- 受入保管倉庫コード
    ,on_delivery_lt     OUT NUMBER       -- リードタイム(日)
    ,ov_errbuf          OUT VARCHAR2     --   エラー・メッセージ           --# 固定 #
    ,ov_retcode         OUT VARCHAR2     --   リターン・コード             --# 固定 #
    ,ov_errmsg          OUT VARCHAR2     --   ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_deliv_lead_time'; -- プログラム名
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_code_class   CONSTANT VARCHAR2(1) := '4';  -- 倉庫
    cv_na_loct_code CONSTANT VARCHAR2(4) := 'ZZZZ';  -- 指定なし
--
    -- *** ローカル変数 ***
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
    --==============================================================
    --ステータス初期化
    --==============================================================
    ov_retcode := cv_status_normal;
--
    --==============================================================
    --配送リードタイム取得１(入出庫場所指定)
    --==============================================================
    BEGIN
      SELECT xdl.delivery_lead_time
      INTO   on_delivery_lt
      FROM   xxcmn_delivery_lt xdl
      WHERE  xdl.code_class1       = cv_code_class
        AND  xdl.code_class2       = cv_code_class
        AND  id_target_date BETWEEN NVL(xdl.start_date_active, id_target_date)
                                AND NVL(xdl.end_date_active  , id_target_date)
        AND  xdl.entering_despatching_code1 = iv_from_loct_code
        AND  xdl.entering_despatching_code2 = iv_to_loct_code
      ;
      IF (on_delivery_lt IS NOT NULL) THEN
        RETURN;
      END IF;
      --
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        NULL;
    END;
--
    --==============================================================
    --配送リードタイム取得２(入出庫場所2指定なし)
    --==============================================================
    BEGIN
      SELECT xdl.delivery_lead_time delivery_lt
      INTO   on_delivery_lt
      FROM   xxcmn_delivery_lt xdl
      WHERE  xdl.code_class1       = cv_code_class
        AND  xdl.code_class2       = cv_code_class
        AND  id_target_date BETWEEN NVL(xdl.start_date_active, id_target_date)
                                AND NVL(xdl.end_date_active  , id_target_date)
        AND  xdl.entering_despatching_code1 = iv_from_loct_code
        AND  xdl.entering_despatching_code2 = cv_na_loct_code
      ;
      IF (on_delivery_lt IS NOT NULL) THEN
        RETURN;
      END IF;
      --
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        NULL;
    END;
--
    --==============================================================
    --配送リードタイム取得３(入出庫場所1指定なし)
    --==============================================================
    BEGIN
      SELECT xdl.delivery_lead_time delivery_lt
      INTO   on_delivery_lt
      FROM   xxcmn_delivery_lt xdl
      WHERE  xdl.code_class1       = cv_code_class
        AND  xdl.code_class2       = cv_code_class
        AND  id_target_date BETWEEN NVL(xdl.start_date_active, id_target_date)
                                AND NVL(xdl.end_date_active  , id_target_date)
        AND  xdl.entering_despatching_code1 = cv_na_loct_code
        AND  xdl.entering_despatching_code2 = iv_to_loct_code
      ;
      IF (on_delivery_lt IS NOT NULL) THEN
        RETURN;
      END IF;
      --
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        NULL;
    END;
--
    --==============================================================
    --配送リードタイム取得４(指定なし)
    --==============================================================
    BEGIN
      SELECT xdl.delivery_lead_time delivery_lt
      INTO   on_delivery_lt
      FROM   xxcmn_delivery_lt xdl
      WHERE  xdl.code_class1       = cv_code_class
        AND  xdl.code_class2       = cv_code_class
        AND  id_target_date BETWEEN NVL(xdl.start_date_active, id_target_date)
                                AND NVL(xdl.end_date_active  , id_target_date)
        AND  xdl.entering_despatching_code1 = cv_na_loct_code
        AND  xdl.entering_despatching_code2 = cv_na_loct_code
      ;
      IF (on_delivery_lt IS NOT NULL) THEN
        RETURN;
      END IF;
      --
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RAISE NO_DATA_FOUND;
    END;
--
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      ov_retcode       := cv_status_warn;
      ov_errbuf        := NULL;
      ov_errmsg        := NULL;
      on_delivery_lt   := NULL;
    WHEN OTHERS THEN
      ov_retcode       := cv_status_error;
      ov_errbuf        := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_errmsg        := NULL;
      on_delivery_lt   := NULL;
  END get_deliv_lead_time;
--
  /**********************************************************************************
   * Function Name   : get_working_days
   * Description      : 稼働日数取得処理
   ***********************************************************************************/
  PROCEDURE get_working_days(
    iv_calendar_code   IN  VARCHAR2,  -- 製造カレンダコード
    in_organization_id IN  NUMBER,    -- 組織ID
    in_loct_id         IN  NUMBER,    -- 保管倉庫ID
    id_from_date       IN  DATE,      -- 基点日付
    id_to_date         IN  DATE,      -- 終点日付
    on_working_days    OUT NUMBER,    -- 稼働日
    ov_errbuf          OUT VARCHAR2,  --   エラー・メッセージ           --# 固定 #
    ov_retcode         OUT VARCHAR2,  --   リターン・コード             --# 固定 #
    ov_errmsg          OUT VARCHAR2)  --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_working_days'; -- プログラム名
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
    cn_active     NUMBER := 0;
--
    -- *** ローカル変数 ***
    ld_work_date     DATE   DEFAULT NULL;
    ld_from_date     DATE   DEFAULT NULL;
    ln_cnt_days      NUMBER DEFAULT 0;
    lt_calendar_code mtl_parameters.calendar_code%TYPE DEFAULT NULL;
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
    -- 製造カレンダコード未設定の場合は取得する
    IF ( iv_calendar_code IS NULL ) THEN
      -- ===============================
      -- カレンダーコード取得
      -- ===============================
      BEGIN
        SELECT mil.attribute10 calendar_code
        INTO   lt_calendar_code
        FROM   mtl_item_locations mil
        WHERE  mil.organization_id        = in_organization_id
          AND  mil.inventory_location_id  = in_loct_id
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lt_calendar_code := NULL;
        --
      END;
      --
      -- カレンダコードが取得できなかった場合はプロファイルのドリンク基準カレンダを設定する。
      IF ( lt_calendar_code IS NULL ) THEN
        lt_calendar_code := FND_PROFILE.VALUE( cv_cmn_drink_cal_cd );
        --
        IF ( lt_calendar_code IS NULL ) THEN
          ov_errbuf        := NULL;
          ov_errmsg        := xxccp_common_pkg.get_msg(
                                 iv_application  => cv_msg_application
                                ,iv_name         => cv_message_00002
                                ,iv_token_name1  => cv_message_00002_token_1
                                ,iv_token_value1 => cv_cmn_drink_cal_cd_name
                                );
          on_working_days  := NULL;
          ov_retcode       := cv_status_error;
          RETURN;
        END IF;
        --
      END IF;
    ELSE
      lt_calendar_code := iv_calendar_code;
    END IF;
--
    -- ===============================
    -- 稼働日数取得
    -- ===============================
    SELECT COUNT(*)
    INTO   on_working_days
    FROM   mr_shcl_hdr msh    -- 製造カレンダヘッダ
          ,mr_shcl_dtl msd    -- 製造カレンダ明細
    WHERE  msh.calendar_no = lt_calendar_code
      AND  msh.calendar_id = msd.calendar_id
      AND  msd.delete_mark = cn_active
      AND  msd.calendar_date BETWEEN id_from_date
                                 AND id_to_date
    ;
--
  EXCEPTION
--
    WHEN OTHERS THEN
      ov_retcode       := cv_status_error;
      ov_errbuf        := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_errmsg        := NULL;
      on_working_days  := NULL;
--
  END get_working_days;
--
  /**********************************************************************************
   * Procedure Name   : upd_assignment
   * Description      : 割当セットAPI起動
   ***********************************************************************************/
  PROCEDURE upd_assignment(
    iv_mov_num              IN  VARCHAR2,     -- 移動ヘッダID
    iv_process_type         IN  VARCHAR2,     -- 処理区分(0：加算、1：減算)
    ov_errbuf               OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode              OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg               OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name               CONSTANT VARCHAR2(100) := 'upd_assignment';   -- プロシージャ名
    -- メッセージ名
    cv_message_00003          CONSTANT VARCHAR2(16)  := 'APP-XXCOP1-00003';
-- 20091201 Ver.2.4 I_E_479_022 SCS_Fukada ADD START
    cv_message_00048          CONSTANT VARCHAR2(16)  := 'APP-XXCOP1-00048';
    cv_message_00048_token_1  CONSTANT VARCHAR2(9)   := 'ITEM_NAME';
-- 20091201 Ver.2.4 I_E_479_022 SCS_Fukada ADD END
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ユーザー定義例外 ***
    api_expt                  EXCEPTION;
    internal_process_expt     EXCEPTION;     -- 内部PROCEDURE/FUNCTIONエラーハンドリング用
--
    -- *** ローカル定数 ***
    cv_doc_type               CONSTANT VARCHAR2(2) := '20';    -- 文書タイプ(20：移動)
    cv_rec_type               CONSTANT VARCHAR2(2) := '10';    -- レコードタイプ(10：指示)
    cv_attribute_category     CONSTANT VARCHAR2(1) := '2';     -- 割当セット区分(2:特別横持)
    cv_assignment_type        CONSTANT VARCHAR2(1) := '6';     -- 割当先タイプ(6:品目・組織)
    cv_sourcing_rule_type     CONSTANT VARCHAR2(1) := '1';     -- 物流構成表/ソースルールタイプ(1:ソースルール)
    cv_lookup_type            CONSTANT VARCHAR2(22) := 'XXCOP1_ASSIGNMENT_NAME';  -- クイックコードタイプ名
    --
    cv_api_version            CONSTANT VARCHAR2(4) := '1.0';      -- バージョン
    cv_operation_update       CONSTANT VARCHAR2(6) := 'UPDATE';   -- 更新
--20091105_Ver2.2_I_E_479_008_SCS.Goto_ADD_START
    gv_msg_encoded            CONSTANT VARCHAR2(1)   := 'F';      -- エラーメッセージエンコード
--20091105_Ver2.2_I_E_479_008_SCS.Goto_ADD_END
-- 20091201 Ver.2.4 I_E_479_022 SCS_Fukada ADD START
    cv_category_prod_class    CONSTANT VARCHAR2(100) := '本社商品区分';
    --品目カテゴリ値
    cv_prod_class_leaf        CONSTANT VARCHAR2(100) := '1';  -- リーフ
    cv_prod_class_drink       CONSTANT VARCHAR2(100) := '2';  -- ドリンク
-- 20091201 Ver.2.4 I_E_479_022 SCS_Fukada ADD END
    --
    cv_process_type_plus      CONSTANT VARCHAR2(1) := '0';     -- 処理区分 0：加算
    cv_process_type_minus     CONSTANT VARCHAR2(1) := '1';     -- 処理区分 1：減算
--
    -- *** ローカル変数 ***
    lv_errbuf                          VARCHAR2(5000);         -- エラー・メッセージ
    lv_retcode                         VARCHAR2(1);            -- リターン・コード
    lv_errmsg                          VARCHAR2(5000);         -- ユーザー・エラー・メッセージ
    --
    ln_quantity                        NUMBER;                 -- 移動数量
    ln_quantity_before                 NUMBER;                 -- 変更前移動数量
    --
    ln_case_qty                        NUMBER;                 -- ケース換算数量
    --
    ln_loop_cnt                        NUMBER DEFAULT 0;       -- ループカウンタ
    lv_rowid                           ROWID;                  -- ロック取得用
    --
-- 20091201 Ver.2.4 I_E_479_022 SCS_Fukada MOD START
    lv_category_value                  mtl_categories_b.segment1%TYPE;  -- 品目カテゴリ値
-- 20091201 Ver.2.4 I_E_479_022 SCS_Fukada MOD START
    lv_message_code                    VARCHAR2(100);
    lv_param                           VARCHAR2(256);          -- パラメータ
    lv_return_status                   VARCHAR2(1);
    ln_msg_count                       NUMBER;
    lv_msg_data                        VARCHAR2(3000);
    ln_msg_index_out                   NUMBER;
--
    -- *** ローカル・カーソル ***
    -- 移動関連情報の取得
    CURSOR l_move_info_cur
    IS
      SELECT xmrih.shipped_locat_code    ship_from_code      -- 出荷元倉庫(出庫元保管場所)
            ,xmrih.ship_to_locat_code    ship_to_code        -- 入庫先倉庫(入庫先保管場所)
            ,TO_CHAR(xmrih.schedule_arrival_date,'YYYY/MM/DD') arrival_date        -- 着日(入庫予定日)
            ,xmril.item_code             item_code           -- 品目
            ,xmld.actual_quantity        quantity            -- 移動数量
            ,ilm.attribute1              prod_start_date     -- 製造年月日
            --
            ,xmrih.mov_hdr_id            mov_hdr_id          -- 移動ヘッダID
            ,xmrih.mov_num               mov_num             -- 移動番号
            ,xmril.mov_line_id           mov_line_id         -- 移動明細ID
            ,xmril.line_number           line_number         -- 明細番号
            ,xmril.delete_flg            delete_flg          -- 明細削除フラグ
-- 20091201 Ver.2.4 I_E_479_022 SCS_Fukada MOD START
            ,xmril.item_id               item_id             -- 品目ID
-- 20091201 Ver.2.4 I_E_479_022 SCS_Fukada MOD END
            ,xmld.lot_id                 lot_id              -- ロットID
            ,xmld.lot_no                 lot_no              -- ロットNo
      FROM   xxinv_mov_req_instr_headers xmrih               -- 移動依頼/指示ヘッダ
            ,xxinv_mov_req_instr_lines   xmril               -- 移動依頼/指示明細
            ,xxinv_mov_lot_details       xmld                -- 移動ロット詳細
            ,ic_lots_mst                 ilm                 -- OPMロットマスタ
      WHERE
      -- テーブル結合条件
             xmrih.mov_hdr_id        = xmril.mov_hdr_id
      AND    xmril.mov_line_id       = xmld.mov_line_id
      AND    xmld.document_type_code = cv_doc_type
      AND    xmld.record_type_code   = cv_rec_type
      AND    xmld.item_id            = ilm.item_id
      AND    xmld.lot_id             = ilm.lot_id
      -- 抽出条件
      AND    xmrih.mov_num           = iv_mov_num
      ;
    --
--20091105_Ver2.2_I_E_479_008_SCS.Goto_ADD_START
    CURSOR l_remove_info_cur
    IS
-- 20091201 Ver.2.4 I_E_479_022 SCS_Fukada MOD START
--      SELECT xac.ROWID                   xac_rowid           -- 特別横持制御マスタコントロールROWID
--            ,xmrih.shipped_locat_code    ship_from_code      -- 出荷元倉庫(出庫元保管場所)
--            ,xmrih.ship_to_locat_code    ship_to_code        -- 入庫先倉庫(入庫先保管場所)
--            ,TO_CHAR(xac.arrival_date,'YYYY/MM/DD') arrival_date        -- 着日(入庫予定日)
--            ,xac.item_code               item_code           -- 品目
--            ,xac.mov_qty                 quantity            -- 移動数量
--            ,ilm.attribute1              prod_start_date     -- 製造年月日
--            --
--            ,xac.mov_hdr_id              mov_hdr_id          -- 移動ヘッダID
--            ,xac.mov_num                 mov_num             -- 移動番号
--            ,xac.mov_line_id             mov_line_id         -- 移動明細ID
--            ,xac.line_number             line_number         -- 明細番号
--            ,xac.lot_id                  lot_id              -- ロットID
--            ,xac.lot_no                  lot_no              -- ロットNo
--      FROM   xxinv_mov_req_instr_headers xmrih               -- 移動依頼/指示ヘッダ
--            ,xxcop_assignment_controls   xac                 -- 特別横持制御マスタコントロール
--            ,ic_item_mst_b               iimb                -- OPM品目マスタ
--            ,ic_lots_mst                 ilm                 -- OPMロットマスタ
--      WHERE
--      -- テーブル結合条件
--             xmrih.mov_hdr_id        = xac.mov_hdr_id
--      AND    iimb.item_no            = xac.item_code
--      AND    iimb.item_id            = ilm.item_id
--      AND    xac.lot_id              = ilm.lot_id
--      -- 抽出条件
--      AND    xmrih.mov_num           = iv_mov_num
--      FOR UPDATE OF xac.mov_hdr_id NOWAIT
--      ;
--
      SELECT xac.ROWID                   xac_rowid                       -- 特別横持制御マスタコントロールROWID
            ,xac.ship_from_code          ship_from_code                  -- 出荷元倉庫(出庫元保管場所)
            ,xac.ship_to_code            ship_to_code                    -- 入庫先倉庫(入庫先保管場所)
            ,TO_CHAR(xac.arrival_date,'YYYY/MM/DD')     arrival_date     -- 着日(入庫予定日)
            ,xac.item_code               item_code                       -- 品目
            ,xac.mov_qty                 quantity                        -- 移動数量
            ,TO_CHAR(xac.prod_start_date,'YYYY/MM/DD')  prod_start_date  -- 製造年月日
            ,xac.mov_hdr_id              mov_hdr_id                      -- 移動ヘッダID
            ,xac.mov_num                 mov_num                         -- 移動番号
            ,xac.mov_line_id             mov_line_id                     -- 移動明細ID
            ,xac.line_number             line_number                     -- 明細番号
            ,xac.lot_id                  lot_id                          -- ロットID
            ,xac.lot_no                  lot_no                          -- ロットNo
      FROM   xxcop_assignment_controls   xac                             -- 特別横持制御マスタコントロール
      -- 抽出条件
      WHERE  xac.mov_num = iv_mov_num
      FOR UPDATE OF xac.mov_hdr_id NOWAIT
      ;
    --
-- 20091201 Ver.2.4 I_E_479_022 SCS_Fukada MOD END
--20091105_Ver2.2_I_E_479_008_SCS.Goto_ADD_END
    -- 特別横持制御マスタ関連情報の取得
    CURSOR l_assignments_info_cur(
      prm_ship_from_code   VARCHAR2  -- 出荷元倉庫(出庫元保管場所)
     ,prm_ship_to_code     VARCHAR2  -- 入庫先倉庫(入庫先保管場所)
     ,prm_arrival_date     VARCHAR2  -- 着日(入庫予定日)
     ,prm_item_code        VARCHAR2  -- 品目
     ,prm_quantity         NUMBER    -- 移動数量
     ,prm_prod_start_date  VARCHAR2) -- 製造年月日
    IS
      SELECT mas.assignment_set_id    mas_assignment_set_id      -- 割当セットヘッダ.割当セットヘッダID
            ,mas.assignment_set_name  mas_assignment_set_name    -- 割当セットヘッダ.割当セット名
            ,mas.creation_date        mas_creation_date          -- 割当セットヘッダ.作成日
            ,mas.created_by           mas_created_by             -- 割当セットヘッダ.作成者
            ,mas.description          mas_desctiption            -- 割当セットヘッダ.割当セット摘要
            ,mas.attribute_category   mas_attribute_category     -- 割当セットヘッダ.Attribute_Category
            ,mas.attribute1           mas_attribute1             -- 割当セットヘッダ.割当セット区分(DFF1)
            ,mas.attribute2           mas_attribute2             -- 割当セットヘッダ.DFF2
            ,mas.attribute3           mas_attribute3             -- 割当セットヘッダ.DFF3
            ,mas.attribute4           mas_attribute4             -- 割当セットヘッダ.DFF4
            ,mas.attribute5           mas_attribute5             -- 割当セットヘッダ.DFF5
            ,mas.attribute6           mas_attribute6             -- 割当セットヘッダ.DFF6
            ,mas.attribute7           mas_attribute7             -- 割当セットヘッダ.DFF7
            ,mas.attribute8           mas_attribute8             -- 割当セットヘッダ.DFF8
            ,mas.attribute9           mas_attribute9             -- 割当セットヘッダ.DFF9
            ,mas.attribute10          mas_attribute10            -- 割当セットヘッダ.DFF10
            ,mas.attribute11          mas_attribute11            -- 割当セットヘッダ.DFF11
            ,mas.attribute12          mas_attribute12            -- 割当セットヘッダ.DFF12
            ,mas.attribute13          mas_attribute13            -- 割当セットヘッダ.DFF13
            ,mas.attribute14          mas_attribute14            -- 割当セットヘッダ.DFF14
            ,mas.attribute15          mas_attribute15            -- 割当セットヘッダ.DFF15
             --
            ,msa.assignment_id        msa_assignment_id          -- 割当セット明細.割当セット明細ID
            ,msa.assignment_type      msa_assignment_type        -- 割当セット明細.割当先タイプ
            ,msa.sourcing_rule_id     msa_sourcing_rule_id       -- 割当セット明細.ソースルールID
            ,msa.sourcing_rule_type   msa_sourcing_rule_type     -- 割当セット明細.物流構成表/ソースルールタイプ
            ,msa.assignment_set_id    msa_assignment_set_id      -- 割当セット明細.割当セットヘッダID
            ,msa.creation_date        msa_creation_date          -- 割当セット明細.作成日
            ,msa.created_by           msa_created_by             -- 割当セット明細.作成者
            ,msa.organization_id      msa_organization_id        -- 割当セット明細.組織ID
            ,msa.customer_id          msa_cutomer_id             -- 割当セット明細.Customer_Id
            ,msa.ship_to_site_id      msa_ship_to_site_id        -- 割当セット明細.Ship_To_Site_Id
            ,msa.category_id          msa_category_id            -- 割当セット明細.Category_Id
            ,msa.category_set_id      msa_category_set_id        -- 割当セット明細.Category_Set_Id
            ,msa.inventory_item_id    msa_inventory_item_id      -- 割当セット明細.品目ID
            ,msa.secondary_inventory  msa_secondary_inventory    -- 割当セット明細.Secondary_Inventory
            ,msa.attribute_category   msa_attribute_category     -- 割当セット明細.割当セット区分
            ,msa.attribute1           msa_attribute1             -- 割当セット明細.開始製造年月日(DFF1)
            ,msa.attribute2           msa_attribute2             -- 割当セット明細.有効開始日(DFF2)
            ,msa.attribute3           msa_attribute3             -- 割当セット明細.有効終了日(DFF3)
            ,msa.attribute4           msa_attribute4             -- 割当セット明細.設定数量(DFF4)
            ,msa.attribute5           msa_attribute5             -- 割当セット明細.移動数(DFF5)
            ,msa.attribute6           msa_attribute6             -- 割当セット明細.DFF6
            ,msa.attribute7           msa_attribute7             -- 割当セット明細.DFF7
            ,msa.attribute8           msa_attribute8             -- 割当セット明細.DFF8
            ,msa.attribute9           msa_attribute9             -- 割当セット明細.DFF9
            ,msa.attribute10          msa_attribute10            -- 割当セット明細.DFF10
            ,msa.attribute11          msa_attribute11            -- 割当セット明細.DFF11
            ,msa.attribute12          msa_attribute12            -- 割当セット明細.DFF12
            ,msa.attribute13          msa_attribute13            -- 割当セット明細.DFF13
            ,msa.attribute14          msa_attribute14            -- 割当セット明細.DFF14
            ,msa.attribute15          msa_attribute15            -- 割当セット明細.DFF15
      FROM   mrp_assignment_sets      mas                        -- 割当セットヘッダ
            ,mrp_sr_assignments       msa                        -- 割当セット明細
            ,mrp_sourcing_rules       msr                        -- ソースルール
            ,mrp_sr_receipt_org       msro                       --
            ,mtl_item_locations       mil_to                     -- OPM保管場所
            ,mrp_sr_source_org        msso                       --
            ,mtl_item_locations       mil_from                   -- OPM保管場所
            ,xxcop_item_categories1_v xicv                       -- 計画領域：品目マスタ
            ,fnd_lookup_values        flv                        -- クイックコード
      WHERE
      -- テーブル結合条件
            mas.assignment_set_id                = msa.assignment_set_id
      AND   msa.sourcing_rule_id                  = msr.sourcing_rule_id
      AND   msr.sourcing_rule_id                  = msro.sourcing_rule_id
      AND   SYSDATE                               BETWEEN NVL(msro.effective_date,SYSDATE)
                                                  AND     NVL(msro.disable_date  ,SYSDATE)
      AND   msro.receipt_organization_id          = mil_to.organization_id
      AND   msro.sr_receipt_id                    = msso.sr_receipt_id
      AND   msso.source_organization_id           = mil_from.organization_id
      AND   msa.inventory_item_id                 = xicv.inventory_item_id
      AND   flv.lookup_type                       = cv_lookup_type
      AND   flv.language                          = USERENV('LANG')
      AND   flv.enabled_flag                      = 'Y'
      AND   flv.lookup_code                       = mas.assignment_set_name
      -- データ抽出条件(特別横持のみ抽出)
      AND   msa.attribute_category                = cv_attribute_category
      AND   msa.assignment_type                   = cv_assignment_type
      AND   msa.sourcing_rule_type                = cv_sourcing_rule_type
      -- 抽出条件
      AND   mil_from.segment1                     = prm_ship_from_code
      AND   mil_to.segment1                       = prm_ship_to_code
      AND   xicv.item_no                          = prm_item_code
            -- 抽出条件：特別横持取得パターン１
      AND   (   (   prm_prod_start_date >= msa.attribute1
                AND prm_arrival_date    <= msa.attribute3
                AND (  (   iv_process_type            = cv_process_type_plus 
--20091105_Ver2.1_I_E_479_009_SCS.Goto_MOD_START
--                       AND TO_NUMBER(msa.attribute4) >= TO_NUMBER(msa.attribute5)
                       AND TO_NUMBER(msa.attribute4) >= NVL(TO_NUMBER(msa.attribute5), 0)
--20091105_Ver2.1_I_E_479_009_SCS.Goto_MOD_END
                       )
                    OR iv_process_type                = cv_process_type_minus
                    )
                )
            -- 抽出条件：特別横持取得パターン２
            OR  (   msa.attribute1                IS NULL
                AND prm_arrival_date     BETWEEN msa.attribute2
                                         AND     msa.attribute3
                AND (  (   iv_process_type            = cv_process_type_plus 
--20091105_Ver2.1_I_E_479_009_SCS.Goto_MOD_START
--                       AND TO_NUMBER(msa.attribute4) >= TO_NUMBER(msa.attribute5)
                       AND TO_NUMBER(msa.attribute4) >= NVL(TO_NUMBER(msa.attribute5), 0)
--20091105_Ver2.1_I_E_479_009_SCS.Goto_MOD_END
                       )
                    OR iv_process_type                = cv_process_type_minus
                    )
                )
            -- 抽出条件：特別横持取得パターン３
            OR  (   prm_prod_start_date >= msa.attribute1
                AND msa.attribute3                IS NULL
                AND (  (   iv_process_type            = cv_process_type_plus 
--20091105_Ver2.1_I_E_479_009_SCS.Goto_MOD_START
--                       AND TO_NUMBER(msa.attribute4) >= TO_NUMBER(msa.attribute5)
                       AND TO_NUMBER(msa.attribute4) >= NVL(TO_NUMBER(msa.attribute5), 0)
--20091105_Ver2.1_I_E_479_009_SCS.Goto_MOD_END
                       )
                    OR iv_process_type                = cv_process_type_minus
                    )
                )
            -- 抽出条件：特別横持取得パターン４
            OR  (   prm_prod_start_date >= msa.attribute1
                AND msa.attribute2                IS NULL
                AND prm_arrival_date    <= msa.attribute3
                AND msa.attribute4                IS NULL
                )
            -- 抽出条件：特別横持取得パターン５
            OR  (   msa.attribute1                IS NULL
                AND prm_arrival_date     BETWEEN msa.attribute2
                                         AND     msa.attribute3
                AND msa.attribute4                IS NULL
                )
            -- 抽出条件：特別横持取得パターン６
            OR  (   msa.attribute1                IS NULL
                AND prm_arrival_date    >= msa.attribute2
                AND msa.attribute3                IS NULL
                AND (  (   iv_process_type            = cv_process_type_plus 
--20091105_Ver2.1_I_E_479_009_SCS.Goto_MOD_START
--                       AND TO_NUMBER(msa.attribute4) >= TO_NUMBER(msa.attribute5)
                       AND TO_NUMBER(msa.attribute4) >= NVL(TO_NUMBER(msa.attribute5), 0)
--20091105_Ver2.1_I_E_479_009_SCS.Goto_MOD_END
                       )
                    OR iv_process_type                = cv_process_type_minus
                    )
                )
             )
      ;
--
    -- *** ローカル・レコード ***
    l_move_info_rec           l_move_info_cur%ROWTYPE;          -- 移動関連情報取得
--20091105_Ver2.2_I_E_479_008_SCS.Goto_ADD_START
    l_remove_info_rec         l_remove_info_cur%ROWTYPE;        -- 移動関連情報取得
--20091105_Ver2.2_I_E_479_008_SCS.Goto_ADD_END
    --
    l_in_mas_rec              mrp_src_assignment_pub.assignment_set_rec_type;        -- 割当セットヘッダー
    l_mas_val_rec             mrp_src_assignment_pub.assignment_set_val_rec_type;
    l_out_mas_rec             mrp_src_assignment_pub.assignment_set_rec_type;
    l_out_mas_val_rec         mrp_src_assignment_pub.assignment_set_val_rec_type;
--
    -- *** ローカル・PL/SQL表 ***
    l_in_msa_tab              mrp_src_assignment_pub.assignment_tbl_type;            -- 割当セット明細
    l_msa_val_tab             mrp_src_assignment_pub.assignment_val_tbl_type;
    l_out_msa_tab             mrp_src_assignment_pub.assignment_tbl_type;
    l_out_msa_val_tab         mrp_src_assignment_pub.assignment_val_tbl_type;
--
    -- *** ローカル・PL/SQL表 ***
--
  BEGIN
    --==============================================================
    -- ステータス初期化
    --==============================================================
    ov_retcode := cv_status_normal;
--
--20091105_Ver2.2_I_E_479_008_SCS.Goto_ADD_START
    -- 確定通知時(加算)の場合
    IF ( iv_process_type = cv_process_type_plus ) THEN
--20091105_Ver2.2_I_E_479_008_SCS.Goto_ADD_END
      --==============================================================
      -- 関連移動情報の取得
      --==============================================================
      OPEN l_move_info_cur;
      << assignment_loop >>
      LOOP
        FETCH l_move_info_cur INTO l_move_info_rec;
        EXIT WHEN l_move_info_cur%NOTFOUND;
        --
-- 20091201 Ver.2.4 I_E_479_022 SCS_Fukada DEL START
--        -- カウントアップ
--        ln_loop_cnt := ln_loop_cnt + 1;
--        --
-- 20091201 Ver.2.4 I_E_479_022 SCS_Fukada DEL END
-- 20091201 Ver.2.4 I_E_479_022 SCS_Fukada ADD START
        -- 対象品目の本社商品区分取得
        lv_category_value := xxcop_common_pkg2.get_item_category_f(
                               iv_category_set  => cv_category_prod_class   -- 品目カテゴリ名
                              ,in_item_id       => l_move_info_rec.item_id  -- 品目ID
                              );
        -- 商品区分の取得に失敗した場合
        IF ( lv_category_value IS NULL ) THEN
          ov_errbuf        := NULL;
          ov_errmsg        := xxccp_common_pkg.get_msg(
                                 iv_application  => cv_msg_application
                                ,iv_name         => cv_message_00048
                                ,iv_token_name1  => cv_message_00048_token_1
                                ,iv_token_value1 => cv_category_prod_class
                                );
          ov_retcode       := cv_status_error;
          -- カーソルクローズ
          CLOSE l_move_info_cur;
          --
          RETURN;
          --
        END IF;
        --
        -- ドリンク製品のみを処理対象とする(リーフの場合は処理をスキップ)
        IF ( lv_category_value = cv_prod_class_drink ) THEN
-- 20091201 Ver.2.4 I_E_479_022 SCS_Fukada ADD END
        --
        -- 確定通知時(加算)の場合は移動明細削除を考慮しないので処理をスキップ
        IF ( ( iv_process_type = cv_process_type_plus ) AND ( l_move_info_rec.delete_flg = 'Y' ) ) THEN
          NULL;
        ELSE
          --
--
      --==============================================================
      -- 特別横持制御マスタ情報の取得
      --==============================================================
          OPEN l_assignments_info_cur (
             l_move_info_rec.ship_from_code
            ,l_move_info_rec.ship_to_code
            ,l_move_info_rec.arrival_date
            ,l_move_info_rec.item_code
            ,l_move_info_rec.quantity
            ,l_move_info_rec.prod_start_date
            );
          FETCH l_assignments_info_cur INTO 
            l_in_mas_rec.assignment_set_id          -- 割当セットヘッダ.割当セットヘッダID
           ,l_in_mas_rec.assignment_set_name        -- 割当セットヘッダ.割当セット名
           ,l_in_mas_rec.creation_date              -- 割当セットヘッダ.作成日
           ,l_in_mas_rec.created_by                 -- 割当セットヘッダ.作成者
           ,l_in_mas_rec.description                -- 割当セットヘッダ.割当セット摘要
           ,l_in_mas_rec.attribute_category         -- 割当セットヘッダ.Attribute_Category
           ,l_in_mas_rec.attribute1                 -- 割当セットヘッダ.割当セット区分(DFF1)
           ,l_in_mas_rec.attribute2                 -- 割当セットヘッダ.DFF2
           ,l_in_mas_rec.attribute3                 -- 割当セットヘッダ.DFF3
           ,l_in_mas_rec.attribute4                 -- 割当セットヘッダ.DFF4
           ,l_in_mas_rec.attribute5                 -- 割当セットヘッダ.DFF5
           ,l_in_mas_rec.attribute6                 -- 割当セットヘッダ.DFF6
           ,l_in_mas_rec.attribute7                 -- 割当セットヘッダ.DFF7
           ,l_in_mas_rec.attribute8                 -- 割当セットヘッダ.DFF8
           ,l_in_mas_rec.attribute9                 -- 割当セットヘッダ.DFF9
           ,l_in_mas_rec.attribute10                -- 割当セットヘッダ.DFF10
           ,l_in_mas_rec.attribute11                -- 割当セットヘッダ.DFF11
           ,l_in_mas_rec.attribute12                -- 割当セットヘッダ.DFF12
           ,l_in_mas_rec.attribute13                -- 割当セットヘッダ.DFF13
           ,l_in_mas_rec.attribute14                -- 割当セットヘッダ.DFF14
           ,l_in_mas_rec.attribute15                -- 割当セットヘッダ.DFF15
           ,l_in_msa_tab(1).assignment_id           -- 割当セット明細.割当セット明細ID
           ,l_in_msa_tab(1).assignment_type         -- 割当セット明細.割当先タイプ
           ,l_in_msa_tab(1).sourcing_rule_id        -- 割当セット明細.ソースルールID
           ,l_in_msa_tab(1).sourcing_rule_type      -- 割当セット明細.物流構成表/ソースルールタイプ
           ,l_in_msa_tab(1).assignment_set_id       -- 割当セット明細.割当セットヘッダID
           ,l_in_msa_tab(1).creation_date           -- 割当セット明細.作成日
           ,l_in_msa_tab(1).created_by              -- 割当セット明細.作成者
           ,l_in_msa_tab(1).organization_id         -- 割当セット明細.組織ID
           ,l_in_msa_tab(1).customer_id             -- 割当セット明細.Customer_Id
           ,l_in_msa_tab(1).ship_to_site_id         -- 割当セット明細.Ship_To_Site_Id
           ,l_in_msa_tab(1).category_id             -- 割当セット明細.Category_Id
           ,l_in_msa_tab(1).category_set_id         -- 割当セット明細.Category_Set_Id
           ,l_in_msa_tab(1).inventory_item_id       -- 割当セット明細.品目ID
           ,l_in_msa_tab(1).secondary_inventory     -- 割当セット明細.Secondary_Inventory
           ,l_in_msa_tab(1).attribute_category      -- 割当セット明細.割当セット区分
           ,l_in_msa_tab(1).attribute1              -- 割当セット明細.開始製造年月日(DFF1)
           ,l_in_msa_tab(1).attribute2              -- 割当セット明細.有効開始日(DFF2)
           ,l_in_msa_tab(1).attribute3              -- 割当セット明細.有効終了日(DFF3)
           ,l_in_msa_tab(1).attribute4              -- 割当セット明細.設定数量(DFF4)
           ,l_in_msa_tab(1).attribute5              -- 割当セット明細.移動数(DFF5)
           ,l_in_msa_tab(1).attribute6              -- 割当セット明細.DFF6
           ,l_in_msa_tab(1).attribute7              -- 割当セット明細.DFF7
           ,l_in_msa_tab(1).attribute8              -- 割当セット明細.DFF8
           ,l_in_msa_tab(1).attribute9              -- 割当セット明細.DFF9
           ,l_in_msa_tab(1).attribute10             -- 割当セット明細.DFF10
           ,l_in_msa_tab(1).attribute11             -- 割当セット明細.DFF11
           ,l_in_msa_tab(1).attribute12             -- 割当セット明細.DFF12
           ,l_in_msa_tab(1).attribute13             -- 割当セット明細.DFF13
           ,l_in_msa_tab(1).attribute14             -- 割当セット明細.DFF14
           ,l_in_msa_tab(1).attribute15             -- 割当セット明細.DFF15
           ;
          --
          -- 対象データが存在する場合
          IF ( l_assignments_info_cur%FOUND ) THEN
            -- 割当セット・API標準レコードタイプの準備
            l_in_mas_rec.operation         := cv_operation_update;      -- 割当セットヘッダ.処理区分(UPDATE)
            l_in_mas_rec.last_update_date  := cd_last_update_date;      -- 割当セットヘッダ.最終更新者
            l_in_mas_rec.last_updated_by   := cn_last_updated_by;       -- 割当セットヘッダ.最終更新日
            l_in_mas_rec.last_update_login := cn_last_update_login;     -- 割当セットヘッダ.最終更新ログイン
            --
      --==============================================================
      -- 移動数量の計算
      --==============================================================
--20091105_Ver2.2_I_E_479_008_SCS.Goto_DEL_START
--            --
--            -- 処理区分によって加算、減算を制御
--            IF ( iv_process_type = cv_process_type_plus ) THEN
--20091105_Ver2.2_I_E_479_008_SCS.Goto_DEL_END
            -- 加算の場合
            -- ケース換算
            xxcop_common_pkg.get_case_quantity(
              iv_item_no               => l_move_info_rec.item_code  -- 品目コード
             ,in_individual_quantity   => l_move_info_rec.quantity   -- バラ数量
             ,in_trunc_digits          => 0                          -- 切捨て桁数
             ,on_case_quantity         => ln_case_qty                -- ケース数量
             ,ov_retcode               => lv_retcode                 -- リターンコード
             ,ov_errbuf                => lv_errbuf                  -- エラー・メッセージ
             ,ov_errmsg                => lv_errmsg                  -- ユーザー・エラー・メッセージ
            );
            IF ( lv_retcode = cv_status_error ) THEN
              RAISE internal_process_expt;
            END IF;
            --
--20091105_Ver2.1_I_E_479_009_SCS.Goto_MOD_START
--            ln_quantity := TO_NUMBER( l_in_msa_tab(1).attribute5 ) + ln_case_qty;
            ln_quantity := NVL(TO_NUMBER( l_in_msa_tab(1).attribute5 ), 0) + ln_case_qty;
--20091105_Ver2.1_I_E_479_009_SCS.Goto_MOD_END
            --
--20091105_Ver2.2_I_E_479_008_SCS.Goto_DEL_START
--            ELSIF ( iv_process_type = cv_process_type_minus ) THEN
--              -- 減算の場合は特別横持制御マスタコントロールアドオンテーブルより変更前数量を取得
--              BEGIN
--                SELECT xac.mov_qty mov_qty
--                INTO   ln_quantity_before
--                FROM   xxcop_assignment_controls xac    -- 特別横持制御マスタコントロール
--                WHERE  xac.mov_hdr_id  = l_move_info_rec.mov_hdr_id
--                AND    xac.mov_line_id = l_move_info_rec.mov_line_id
--                AND    xac.lot_id      = l_move_info_rec.lot_id
--                ;
--                -- ケース換算
--                xxcop_common_pkg.get_case_quantity(
--                  iv_item_no               => l_move_info_rec.item_code  -- 品目コード
--                 ,in_individual_quantity   => ln_quantity_before         -- バラ数量
--                 ,in_trunc_digits          => 0                          -- 切捨て桁数
--                 ,on_case_quantity         => ln_case_qty                -- ケース数量
--                 ,ov_retcode               => lv_retcode                 -- リターンコード
--                 ,ov_errbuf                => lv_errbuf                  -- エラー・メッセージ
--                 ,ov_errmsg                => lv_errmsg                  -- ユーザー・エラー・メッセージ
--                );
--                IF ( lv_retcode = cv_status_error ) THEN
--                  RAISE internal_process_expt;
--                END IF;
--                --
--              EXCEPTION
--                WHEN NO_DATA_FOUND THEN
--                  ln_quantity_before := 0;
--                  ln_case_qty := 0;
--                  --
--              END;
--              -- 移動数量を減算
--              ln_quantity := TO_NUMBER( l_in_msa_tab(1).attribute5 ) - ln_case_qty;
--              --
--            END IF;
--            --
--20091105_Ver2.2_I_E_479_008_SCS.Goto_DEL_END
      --==============================================================
      -- 割当セットAPI起動
      --==============================================================
            -- 割当セット明細PLSQL表の準備
            l_in_msa_tab(1).attribute5         := TO_CHAR( ln_quantity );    -- 割当セット明細.移動数(DFF5)
            l_in_msa_tab(1).operation          := cv_operation_update;       -- 割当セット明細.処理区分(UPDATE)
            l_in_msa_tab(1).last_update_date   := cd_last_update_date;       -- 割当セット明細.最終更新者
            l_in_msa_tab(1).last_updated_by    := cn_last_updated_by;        -- 割当セット明細.最終更新日
            l_in_msa_tab(1).last_update_login  := cn_last_update_login;      -- 割当セット明細.最終更新ログイン
            --
            -- 割当セットヘッダ/明細の更新（API起動）
            mrp_src_assignment_pub.process_assignment(
               p_api_version_number     => cv_api_version
              ,p_init_msg_list          => FND_API.G_TRUE
              ,p_return_values          => FND_API.G_TRUE
              ,p_commit                 => FND_API.G_FALSE
              ,x_return_status          => lv_return_status
              ,x_msg_count              => ln_msg_count
              ,x_msg_data               => lv_msg_data
              ,p_Assignment_Set_rec     => l_in_mas_rec
              ,p_Assignment_Set_val_rec => l_mas_val_rec
              ,p_Assignment_tbl         => l_in_msa_tab
              ,p_Assignment_val_tbl     => l_msa_val_tab
              ,x_Assignment_Set_rec     => l_out_mas_rec
              ,x_Assignment_Set_val_rec => l_out_mas_val_rec
              ,x_Assignment_tbl         => l_out_msa_tab
              ,x_Assignment_val_tbl     => l_out_msa_val_tab
            );
            --
            -- エラーが発生した場合
            IF ( lv_return_status <> FND_API.G_RET_STS_SUCCESS ) THEN
--20091105_Ver2.2_I_E_479_008_SCS.Goto_MOD_START
--              ov_errmsg := lv_msg_data;
              IF ( ln_msg_count = 1 ) THEN
                ov_errmsg := lv_msg_data;
              ELSE
                <<errmsg_loop>>
                FOR ln_err_idx IN 1 .. ln_msg_count LOOP
                  fnd_msg_pub.get(
                     p_msg_index     => ln_err_idx
                    ,p_encoded       => gv_msg_encoded
                    ,p_data          => lv_msg_data
                    ,p_msg_index_out => ln_msg_index_out
                  );
                  ov_errmsg := ov_errmsg || lv_msg_data || CHR(10) ;
                END LOOP errmsg_loop;
              END IF;
--20091105_Ver2.2_I_E_479_008_SCS.Goto_MOD_END
              RAISE api_expt;
            END IF;
            --

      --==============================================================
      -- 特別横持制御マスタコントロールテーブル反映
      --==============================================================
--20091105_Ver2.2_I_E_479_008_SCS.Goto_DEL_START
--            -- 処理区分によって挿入、削除を制御
--            IF ( iv_process_type = cv_process_type_plus ) THEN
--20091105_Ver2.2_I_E_479_008_SCS.Goto_DEL_END
            -- 処理区分が加算の場合はデータ登録
            INSERT INTO xxcop_assignment_controls (
              mov_hdr_id                -- 移動ヘッダID
             ,mov_num                   -- 移動番号
-- 20091201 Ver.2.4 I_E_479_022 SCS_Fukada ADD START
             ,ship_from_code            -- 出荷元倉庫
             ,ship_to_code              -- 入庫先倉庫
-- 20091201 Ver.2.4 I_E_479_022 SCS_Fukada ADD END
             ,mov_line_id               -- 移動明細ID
             ,line_number               -- 明細番号
             ,lot_id                    -- ロットID
             ,lot_no                    -- ロットNo
             ,item_code                 -- 品目コード
-- 20091201 Ver.2.4 I_E_479_022 SCS_Fukada ADD START
             ,prod_start_date           -- 製造開始年月日
-- 20091201 Ver.2.4 I_E_479_022 SCS_Fukada ADD START
             ,arrival_date              -- 着日
             ,mov_qty                   -- 移動数量
             ,created_by                -- 作成者
             ,creation_date             -- 作成日
             ,last_updated_by           -- 最終更新者
             ,last_update_date          -- 最終更新日時
             ,last_update_login         -- 最終更新ログイン
             ,request_id                -- 要求ID
             ,program_application_id    -- コンカレント・プログラム・アプリケーションID
             ,program_id                -- コンカレント・プログラムID
             ,program_update_date       -- プログラム更新日
            )VALUES(
              l_move_info_rec.mov_hdr_id    -- 移動ヘッダID
             ,l_move_info_rec.mov_num       -- 移動番号
-- 20091201 Ver.2.4 I_E_479_022 SCS_Fukada ADD START
             ,l_move_info_rec.ship_from_code  -- 出荷元倉庫
             ,l_move_info_rec.ship_to_code    -- 入庫先倉庫
-- 20091201 Ver.2.4 I_E_479_022 SCS_Fukada ADD END
             ,l_move_info_rec.mov_line_id   -- 移動明細ID
             ,l_move_info_rec.line_number   -- 明細番号
             ,l_move_info_rec.lot_id        -- ロットID
             ,l_move_info_rec.lot_no        -- ロットNo
             ,l_move_info_rec.item_code     -- 品目コード
-- 20091201 Ver.2.4 I_E_479_022 SCS_Fukada ADD START
             ,TO_DATE(l_move_info_rec.prod_start_date, 'YYYY/MM/DD')  -- 製造開始年月日
-- 20091201 Ver.2.4 I_E_479_022 SCS_Fukada ADD START
             ,TO_DATE(l_move_info_rec.arrival_date, 'YYYY/MM/DD')  -- 着日
             ,l_move_info_rec.quantity      -- 移動数量
             ,cn_created_by                 -- 作成者
             ,cd_creation_date              -- 作成日
             ,cn_last_updated_by            -- 最終更新者
             ,cd_last_update_date           -- 最終更新日時
             ,cn_last_update_login          -- 最終更新ログイン
             ,cn_request_id                 -- 要求ID
             ,cn_program_application_id     -- コンカレント・プログラム・アプリケーションID
             ,cn_program_id                 -- コンカレント・プログラムID
             ,cd_program_update_date        -- プログラム更新日
            );
            --
--20091105_Ver2.2_I_E_479_008_SCS.Goto_DEL_START
--            ELSIF ( iv_process_type = cv_process_type_minus ) THEN
--              -- 処理区分が減算の場合はデータ削除
--              BEGIN
--                SELECT xac.ROWID xac_rowid
--                INTO   lv_rowid
--                FROM   xxcop_assignment_controls xac
--                WHERE  xac.mov_hdr_id  = l_move_info_rec.mov_hdr_id
--                AND    xac.mov_line_id = l_move_info_rec.mov_line_id
--                AND    xac.lot_id      = l_move_info_rec.lot_id
--                FOR UPDATE NOWAIT
--                ;
--              EXCEPTION
--                WHEN NO_DATA_FOUND THEN
--                  NULL;
--                  --
--              END;
--              --
--              DELETE xxcop_assignment_controls xac
--              WHERE  xac.mov_hdr_id  = l_move_info_rec.mov_hdr_id
--              AND    xac.mov_line_id = l_move_info_rec.mov_line_id
--              AND    xac.lot_id      = l_move_info_rec.lot_id
--              ;
--            END IF;
--            --
--20091105_Ver2.2_I_E_479_008_SCS.Goto_DEL_END
          END IF;
          --
          -- カーソルクローズ
          CLOSE l_assignments_info_cur;
        --
        END IF;
        --
-- 20091201 Ver.2.4 I_E_479_022 SCS_Fukada ADD START
        END IF;
        --
-- 20091201 Ver.2.4 I_E_479_022 SCS_Fukada ADD END
        END LOOP assignment_loop;
-- 20091201 Ver.2.4 I_E_479_022 SCS_Fukada DEL START
--        --
--        IF ( ln_loop_cnt < 1 ) THEN
--          ov_errbuf        := NULL;
--          ov_errmsg        := xxccp_common_pkg.get_msg(
--                                 iv_application  => cv_msg_application
--                                ,iv_name         => cv_message_00003
--                                );
--          ov_retcode       := cv_status_error;
--          RETURN;
--          -- カーソルクローズ
--          CLOSE l_move_info_cur;
--          --
--        END IF;
-- 20091201 Ver.2.4 I_E_479_022 SCS_Fukada DEL END
      -- カーソルクローズ
      CLOSE l_move_info_cur;
--20091105_Ver2.2_I_E_479_008_SCS.Goto_ADD_START
    ELSIF ( iv_process_type = cv_process_type_minus ) THEN
      OPEN l_remove_info_cur;
      << remove_assignment_loop >>
      LOOP
        FETCH l_remove_info_cur INTO l_remove_info_rec;
        EXIT WHEN l_remove_info_cur%NOTFOUND;
--
      --==============================================================
      -- 特別横持制御マスタ情報の取得
      --==============================================================
        OPEN l_assignments_info_cur (
           l_remove_info_rec.ship_from_code
          ,l_remove_info_rec.ship_to_code
          ,l_remove_info_rec.arrival_date
          ,l_remove_info_rec.item_code
          ,l_remove_info_rec.quantity
          ,l_remove_info_rec.prod_start_date
          );
        FETCH l_assignments_info_cur INTO 
          l_in_mas_rec.assignment_set_id          -- 割当セットヘッダ.割当セットヘッダID
         ,l_in_mas_rec.assignment_set_name        -- 割当セットヘッダ.割当セット名
         ,l_in_mas_rec.creation_date              -- 割当セットヘッダ.作成日
         ,l_in_mas_rec.created_by                 -- 割当セットヘッダ.作成者
         ,l_in_mas_rec.description                -- 割当セットヘッダ.割当セット摘要
         ,l_in_mas_rec.attribute_category         -- 割当セットヘッダ.Attribute_Category
         ,l_in_mas_rec.attribute1                 -- 割当セットヘッダ.割当セット区分(DFF1)
         ,l_in_mas_rec.attribute2                 -- 割当セットヘッダ.DFF2
         ,l_in_mas_rec.attribute3                 -- 割当セットヘッダ.DFF3
         ,l_in_mas_rec.attribute4                 -- 割当セットヘッダ.DFF4
         ,l_in_mas_rec.attribute5                 -- 割当セットヘッダ.DFF5
         ,l_in_mas_rec.attribute6                 -- 割当セットヘッダ.DFF6
         ,l_in_mas_rec.attribute7                 -- 割当セットヘッダ.DFF7
         ,l_in_mas_rec.attribute8                 -- 割当セットヘッダ.DFF8
         ,l_in_mas_rec.attribute9                 -- 割当セットヘッダ.DFF9
         ,l_in_mas_rec.attribute10                -- 割当セットヘッダ.DFF10
         ,l_in_mas_rec.attribute11                -- 割当セットヘッダ.DFF11
         ,l_in_mas_rec.attribute12                -- 割当セットヘッダ.DFF12
         ,l_in_mas_rec.attribute13                -- 割当セットヘッダ.DFF13
         ,l_in_mas_rec.attribute14                -- 割当セットヘッダ.DFF14
         ,l_in_mas_rec.attribute15                -- 割当セットヘッダ.DFF15
         ,l_in_msa_tab(1).assignment_id           -- 割当セット明細.割当セット明細ID
         ,l_in_msa_tab(1).assignment_type         -- 割当セット明細.割当先タイプ
         ,l_in_msa_tab(1).sourcing_rule_id        -- 割当セット明細.ソースルールID
         ,l_in_msa_tab(1).sourcing_rule_type      -- 割当セット明細.物流構成表/ソースルールタイプ
         ,l_in_msa_tab(1).assignment_set_id       -- 割当セット明細.割当セットヘッダID
         ,l_in_msa_tab(1).creation_date           -- 割当セット明細.作成日
         ,l_in_msa_tab(1).created_by              -- 割当セット明細.作成者
         ,l_in_msa_tab(1).organization_id         -- 割当セット明細.組織ID
         ,l_in_msa_tab(1).customer_id             -- 割当セット明細.Customer_Id
         ,l_in_msa_tab(1).ship_to_site_id         -- 割当セット明細.Ship_To_Site_Id
         ,l_in_msa_tab(1).category_id             -- 割当セット明細.Category_Id
         ,l_in_msa_tab(1).category_set_id         -- 割当セット明細.Category_Set_Id
         ,l_in_msa_tab(1).inventory_item_id       -- 割当セット明細.品目ID
         ,l_in_msa_tab(1).secondary_inventory     -- 割当セット明細.Secondary_Inventory
         ,l_in_msa_tab(1).attribute_category      -- 割当セット明細.割当セット区分
         ,l_in_msa_tab(1).attribute1              -- 割当セット明細.開始製造年月日(DFF1)
         ,l_in_msa_tab(1).attribute2              -- 割当セット明細.有効開始日(DFF2)
         ,l_in_msa_tab(1).attribute3              -- 割当セット明細.有効終了日(DFF3)
         ,l_in_msa_tab(1).attribute4              -- 割当セット明細.設定数量(DFF4)
         ,l_in_msa_tab(1).attribute5              -- 割当セット明細.移動数(DFF5)
         ,l_in_msa_tab(1).attribute6              -- 割当セット明細.DFF6
         ,l_in_msa_tab(1).attribute7              -- 割当セット明細.DFF7
         ,l_in_msa_tab(1).attribute8              -- 割当セット明細.DFF8
         ,l_in_msa_tab(1).attribute9              -- 割当セット明細.DFF9
         ,l_in_msa_tab(1).attribute10             -- 割当セット明細.DFF10
         ,l_in_msa_tab(1).attribute11             -- 割当セット明細.DFF11
         ,l_in_msa_tab(1).attribute12             -- 割当セット明細.DFF12
         ,l_in_msa_tab(1).attribute13             -- 割当セット明細.DFF13
         ,l_in_msa_tab(1).attribute14             -- 割当セット明細.DFF14
         ,l_in_msa_tab(1).attribute15             -- 割当セット明細.DFF15
         ;
        --
        -- 対象データが存在する場合
        IF ( l_assignments_info_cur%FOUND ) THEN
          -- 割当セット・API標準レコードタイプの準備
          l_in_mas_rec.operation         := cv_operation_update;      -- 割当セットヘッダ.処理区分(UPDATE)
          l_in_mas_rec.last_update_date  := cd_last_update_date;      -- 割当セットヘッダ.最終更新者
          l_in_mas_rec.last_updated_by   := cn_last_updated_by;       -- 割当セットヘッダ.最終更新日
          l_in_mas_rec.last_update_login := cn_last_update_login;     -- 割当セットヘッダ.最終更新ログイン
          -- ケース換算
          xxcop_common_pkg.get_case_quantity(
            iv_item_no               => l_remove_info_rec.item_code   -- 品目コード
           ,in_individual_quantity   => l_remove_info_rec.quantity    -- バラ数量
           ,in_trunc_digits          => 0                             -- 切捨て桁数
           ,on_case_quantity         => ln_case_qty                   -- ケース数量
           ,ov_retcode               => lv_retcode                    -- リターンコード
           ,ov_errbuf                => lv_errbuf                     -- エラー・メッセージ
           ,ov_errmsg                => lv_errmsg                     -- ユーザー・エラー・メッセージ
          );
          IF ( lv_retcode = cv_status_error ) THEN
            RAISE internal_process_expt;
          END IF;
          -- 移動数量を減算
          ln_quantity := NVL(TO_NUMBER( l_in_msa_tab(1).attribute5 ), 0) - ln_case_qty;
          --
      --==============================================================
      -- 割当セットAPI起動
      --==============================================================
          -- 割当セット明細PLSQL表の準備
          l_in_msa_tab(1).attribute5         := TO_CHAR( ln_quantity );    -- 割当セット明細.移動数(DFF5)
          l_in_msa_tab(1).operation          := cv_operation_update;       -- 割当セット明細.処理区分(UPDATE)
          l_in_msa_tab(1).last_update_date   := cd_last_update_date;       -- 割当セット明細.最終更新者
          l_in_msa_tab(1).last_updated_by    := cn_last_updated_by;        -- 割当セット明細.最終更新日
          l_in_msa_tab(1).last_update_login  := cn_last_update_login;      -- 割当セット明細.最終更新ログイン
          --
          -- 割当セットヘッダ/明細の更新（API起動）
          mrp_src_assignment_pub.process_assignment(
             p_api_version_number     => cv_api_version
            ,p_init_msg_list          => FND_API.G_TRUE
            ,p_return_values          => FND_API.G_TRUE
            ,p_commit                 => FND_API.G_FALSE
            ,x_return_status          => lv_return_status
            ,x_msg_count              => ln_msg_count
            ,x_msg_data               => lv_msg_data
            ,p_Assignment_Set_rec     => l_in_mas_rec
            ,p_Assignment_Set_val_rec => l_mas_val_rec
            ,p_Assignment_tbl         => l_in_msa_tab
            ,p_Assignment_val_tbl     => l_msa_val_tab
            ,x_Assignment_Set_rec     => l_out_mas_rec
            ,x_Assignment_Set_val_rec => l_out_mas_val_rec
            ,x_Assignment_tbl         => l_out_msa_tab
            ,x_Assignment_val_tbl     => l_out_msa_val_tab
          );
          --
          -- エラーが発生した場合
          IF ( lv_return_status <> FND_API.G_RET_STS_SUCCESS ) THEN
            IF ( ln_msg_count = 1 ) THEN
              ov_errmsg := lv_msg_data;
            ELSE
              <<errmsg_loop>>
              FOR ln_err_idx IN 1 .. ln_msg_count LOOP
                fnd_msg_pub.get(
                   p_msg_index     => ln_err_idx
                  ,p_encoded       => gv_msg_encoded
                  ,p_data          => lv_msg_data
                  ,p_msg_index_out => ln_msg_index_out
                );
                ov_errmsg := ov_errmsg || lv_msg_data || CHR(10) ;
              END LOOP errmsg_loop;
            END IF;
            RAISE api_expt;
          END IF;
          --
          DELETE xxcop_assignment_controls xac
          WHERE  xac.ROWID  = l_remove_info_rec.xac_rowid
          ;
        END IF;
        --
        -- カーソルクローズ
        CLOSE l_assignments_info_cur;
      END LOOP remove_assignment_loop;
      --
      -- カーソルクローズ
      CLOSE l_remove_info_cur;
    END IF;
--20091105_Ver2.2_I_E_479_008_SCS.Goto_ADD_END
--
  EXCEPTION
    WHEN internal_process_expt THEN
      IF ( l_move_info_cur%ISOPEN ) THEN
        CLOSE l_move_info_cur;
      END IF;
--20091105_Ver2.2_I_E_479_008_SCS.Goto_ADD_START
      IF ( l_remove_info_cur%ISOPEN ) THEN
        CLOSE l_remove_info_cur;
      END IF;
--20091105_Ver2.2_I_E_479_008_SCS.Goto_ADD_END
      IF ( l_assignments_info_cur%ISOPEN ) THEN
        CLOSE l_assignments_info_cur;
      END IF;
      ov_errmsg  := NULL;
      ov_errbuf  := NVL(lv_errbuf,lv_errmsg);
      ov_retcode := cv_status_error;
      --
    -- API起動でエラー
    WHEN api_expt THEN
      IF ( l_move_info_cur%ISOPEN ) THEN
        CLOSE l_move_info_cur;
      END IF;
--20091105_Ver2.2_I_E_479_008_SCS.Goto_ADD_START
      IF ( l_remove_info_cur%ISOPEN ) THEN
        CLOSE l_remove_info_cur;
      END IF;
--20091105_Ver2.2_I_E_479_008_SCS.Goto_ADD_END
      IF ( l_assignments_info_cur%ISOPEN ) THEN
        CLOSE l_assignments_info_cur;
      END IF;
      ov_retcode       := cv_status_error;
      --
    -- その他例外エラー
    WHEN OTHERS THEN
      IF ( l_move_info_cur%ISOPEN ) THEN
        CLOSE l_move_info_cur;
      END IF;
--20091105_Ver2.2_I_E_479_008_SCS.Goto_ADD_START
      IF ( l_remove_info_cur%ISOPEN ) THEN
        CLOSE l_remove_info_cur;
      END IF;
--20091105_Ver2.2_I_E_479_008_SCS.Goto_ADD_END
      IF ( l_assignments_info_cur%ISOPEN ) THEN
        CLOSE l_assignments_info_cur;
      END IF;
      ov_retcode       := cv_status_error;
      ov_errbuf        := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      --
  END upd_assignment;
  --
  /**********************************************************************************
   * Procedure Name   : get_loct_info
   * Description      : 倉庫情報取得処理
   ***********************************************************************************/
  PROCEDURE get_loct_info(
    id_target_date          IN  DATE,         -- 対象日付
    in_organization_id      IN  NUMBER,       -- 組織ID
    ov_organization_code    OUT VARCHAR2,     -- 組織コード
    ov_organization_name    OUT VARCHAR2,     -- 組織名称
    on_loct_id              OUT NUMBER,       -- 保管倉庫ID
    ov_loct_code            OUT VARCHAR2,     -- 保管倉庫コード
    ov_loct_name            OUT VARCHAR2,     -- 保管倉庫名称
    ov_calendar_code        OUT VARCHAR2,     -- カレンダコード
    ov_errbuf               OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode              OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg               OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'get_loct_info'; -- プログラム名
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ユーザー定義例外 ***
    no_loct_info            EXCEPTION;                        -- 保管場所取得エラー
--
    -- *** ローカル定数 ***
    cn_del_mark_n  CONSTANT NUMBER       := 0;                -- 有効
--
    -- *** ローカル変数 ***
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
    --==============================================================
    --ステータス初期化
    --==============================================================
    ov_retcode := cv_status_normal;
--
    --======================================================
    -- 倉庫コード取得
    --======================================================
    BEGIN
      SELECT mp.organization_code  -- 組織コード
            ,haou.name             -- 組織名
      INTO   ov_organization_code
            ,ov_organization_name
      FROM   hr_all_organization_units haou  -- 組織マスタ
            ,mtl_parameters            mp    -- 組織パラメータ
      WHERE  id_target_date       BETWEEN NVL( haou.date_from, id_target_date )
                                  AND     NVL( haou.date_to  , id_target_date )
      AND    mp.organization_id   = haou.organization_id
      AND    haou.organization_id = in_organization_id
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RAISE NO_DATA_FOUND;
    END;
    --
    --======================================================
    -- 保管場所コード取得
    --======================================================
    BEGIN
      SELECT location_id
            ,location_code
            ,location_name
            ,calendar_code
      INTO   on_loct_id
            ,ov_loct_code
            ,ov_loct_name
            ,ov_calendar_code
      FROM   (SELECT mil.inventory_location_id  location_id
                    ,mil.segment1               location_code
                    ,ilm.loct_desc              location_name
                    ,mil.attribute10            calendar_code
                    ,RANK() OVER(PARTITION BY ilm.whse_code
                                 ORDER BY     NVL(mil.attribute4,0) DESC  -- 出荷引当対象フラグ
                                             ,ilm.location                -- 保管場所コード
                                )               frequent_rank             -- ランク
              FROM   mtl_item_locations  mil  -- OPM保管場所マスタ
                    ,ic_loct_mst         ilm  -- OPM保管倉庫マスタ
                    ,ic_whse_mst         iwm  -- OPM倉庫マスタ
              WHERE  iwm.mtl_organization_id   = mil.organization_id
              AND    iwm.delete_mark           = cn_del_mark_n
              AND    mil.inventory_location_id = ilm.inventory_location_id
              AND    ilm.delete_mark           = cn_del_mark_n
              AND    id_target_date           <= NVL( mil.disable_date, id_target_date )
              AND    mil.organization_id       = in_organization_id
             ) loct_info
      WHERE  loct_info.frequent_rank = '1'
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RAISE no_loct_info;
    END;
    --
  EXCEPTION
    WHEN no_loct_info THEN
      ov_retcode       := cv_status_warn;
      ov_errbuf        := NULL;
      ov_errmsg        := NULL;
      on_loct_id       := NULL;
      ov_loct_code     := NULL;
      ov_loct_name     := NULL;
      ov_calendar_code := NULL;
    WHEN NO_DATA_FOUND THEN
      ov_retcode            := cv_status_error;
      ov_errbuf             := NULL;
      ov_errmsg             := NULL;
      ov_organization_code  := NULL;
      ov_organization_name  := NULL;
      on_loct_id            := NULL;
      ov_loct_code          := NULL;
      ov_loct_name          := NULL;
      ov_calendar_code      := NULL;
    WHEN OTHERS THEN
      ov_retcode   := cv_status_error;
      ov_errbuf    := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_errmsg    := NULL;
  END get_loct_info;
  --
  /**********************************************************************************
   * Procedure Name   : get_critical_date_f
   * Description      : 鮮度条件基準日取得処理
   ***********************************************************************************/
  FUNCTION get_critical_date_f(
     iv_freshness_class        IN     VARCHAR2    -- 鮮度条件分類
    ,in_freshness_check_value  IN     NUMBER      -- 鮮度条件チェック値
    ,in_freshness_adjust_value IN     NUMBER      -- 鮮度条件調整値
    ,in_max_stock_days         IN     NUMBER      -- 最大在庫日数
    ,in_freshness_buffer_days  IN     NUMBER      -- 鮮度条件バッファ日数
    ,id_manufacture_date       IN     DATE        -- 製造年月日
    ,id_expiration_date        IN     DATE        -- 賞味期限
  ) RETURN DATE IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_critical_date_f'; -- プログラム名
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_general                  CONSTANT VARCHAR2(1)   := '0';     -- 一般
    cv_expiration               CONSTANT VARCHAR2(1)   := '1';     -- 賞味期限基準
    cv_manufacture              CONSTANT VARCHAR2(1)   := '2';     -- 製造日基準
    cd_max_date                 CONSTANT DATE          := TO_DATE('9999/12/31', 'YYYY/MM/DD');
--
    -- *** ローカル変数 ***
    ln_critical_value                    NUMBER;                   -- 基準値
    lv_expt_value                        VARCHAR2(100);            -- 例外パラメータ
    ld_critical_date                     DATE;                     -- 基準日
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
    --例外定義
--
  BEGIN
  --
    --
    IF ( id_expiration_date IS NULL ) THEN
      --賞味期限がNULLは購入計画、工場出荷計画ロットのため最大値を戻す
      ld_critical_date := cd_max_date;
    ELSE
      --鮮度条件分類:一般
      IF ( iv_freshness_class = cv_general ) THEN
        --基準値の計算
        ln_critical_value := in_freshness_check_value;
        --基準日の計算
        ld_critical_date := id_expiration_date
                          + NVL(ln_critical_value,0)
                          + NVL(in_freshness_adjust_value, 0)
                          - ( in_max_stock_days + in_freshness_buffer_days )
        ;
      END IF;
  --
      --鮮度条件分類:賞味期限基準
      IF ( iv_freshness_class = cv_expiration ) THEN
        --基準値の計算
        ln_critical_value := TRUNC(( id_expiration_date - id_manufacture_date )
                                   / in_freshness_check_value);
        --基準日の計算
        ld_critical_date := id_manufacture_date
                          + NVL(ln_critical_value,0)
                          + NVL(in_freshness_adjust_value, 0)
                          - ( in_max_stock_days + in_freshness_buffer_days )
        ;
      END IF;
  --
      --鮮度条件分類:製造日基準
      IF ( iv_freshness_class = cv_manufacture ) THEN
        --基準値の計算
        ln_critical_value := in_freshness_check_value;
        --基準日の計算
        ld_critical_date := id_manufacture_date
                          + NVL(ln_critical_value,0)
                          + NVL(in_freshness_adjust_value, 0)
                          - ( in_max_stock_days + in_freshness_buffer_days )
        ;
      END IF;
    END IF;
  --
    RETURN ld_critical_date;
--
  END get_critical_date_f;
  --
  /**********************************************************************************
   * Procedure Name   : get_delivery_unit
   * Description      : 配送単位取得処理
   ***********************************************************************************/
  PROCEDURE get_delivery_unit(
     in_shipping_pace          IN     NUMBER      -- 出荷ペース
    ,in_palette_max_cs_qty     IN     NUMBER      -- 配数
    ,in_palette_max_step_qty   IN     NUMBER      -- 段数
    ,ov_unit_delivery          OUT    VARCHAR2    -- 配送単位
    ,ov_errbuf                 OUT    VARCHAR2    --   エラー・メッセージ           --# 固定 #
    ,ov_retcode                OUT    VARCHAR2    --   リターン・コード             --# 固定 #
    ,ov_errmsg                 OUT    VARCHAR2    --   ユーザー・エラー・メッセージ --# 固定 #
  ) IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_delivery_unit'; -- プログラム名
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_unit_delivery            CONSTANT VARCHAR2(100) := 'XXCOP1_UNIT_DELIVERY';   -- クイックコード名
    cv_enable                   CONSTANT VARCHAR2(100) := 'Y';                      -- 有効フラグ
    --配送単位
    cv_unit_palette             CONSTANT VARCHAR2(10)  := '1';                      -- パレット
    cv_unit_step                CONSTANT VARCHAR2(10)  := '2';                      -- 段
    cv_unit_case                CONSTANT VARCHAR2(10)  := '3';                      -- ケース
--
    -- *** ローカル変数 ***
    ld_process_date             DATE;
    ln_unit_quantity            NUMBER;
--
    -- *** ローカル・カーソル ***
    --配送単位の基準数
    CURSOR flv_cur IS
      SELECT flv.lookup_code  lookup_code       -- コード
            ,flv.meaning      meaning           -- 内容
            ,flv.description  description       -- 摘要
      FROM fnd_lookup_values  flv               -- クイックコード
      WHERE flv.lookup_type            = cv_unit_delivery
        AND flv.language               = cv_lang
        AND flv.source_lang            = cv_lang
        AND flv.enabled_flag           = cv_enable
        AND ld_process_date BETWEEN NVL(flv.start_date_active, ld_process_date)
                                AND NVL(flv.end_date_active, ld_process_date)
      ORDER BY flv.lookup_code ASC;
--
    -- *** ローカル・レコード ***
--
  BEGIN
    --==============================================================
    --ステータス初期化
    --==============================================================
    ov_retcode := cv_status_normal;
    --
    --業務日付の取得
    ld_process_date  :=  xxccp_common_pkg2.get_process_date;
--
    <<unit_loop>>
    FOR flv_rec IN flv_cur LOOP
      CASE
        WHEN flv_rec.lookup_code = cv_unit_palette THEN
          --パレットの基準数で判定
          ln_unit_quantity := in_shipping_pace / ( in_palette_max_cs_qty * in_palette_max_step_qty );
        WHEN flv_rec.lookup_code = cv_unit_step THEN
          --段の基準数で判定
          ln_unit_quantity := in_shipping_pace / in_palette_max_cs_qty;
        WHEN flv_rec.lookup_code = cv_unit_case THEN
          --ケースの基準数で判定
          ln_unit_quantity := in_shipping_pace;
      END CASE;
      IF ( ln_unit_quantity > TO_NUMBER(flv_rec.description) ) THEN
        ov_unit_delivery := flv_rec.meaning;
        EXIT unit_loop;
      END IF;
    END LOOP unit_loop;
--
  EXCEPTION
    WHEN OTHERS THEN
      ov_retcode       := cv_status_error;
      ov_errbuf        := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_errmsg        := NULL;
      ov_unit_delivery := NULL;
  END get_delivery_unit;
--
  /**********************************************************************************
   * Function Name   : get_receipt_date
   * Description      : 着日取得処理
   ***********************************************************************************/
  PROCEDURE get_receipt_date(
    iv_calendar_code   IN     VARCHAR2       --   製造ｶﾚﾝﾀﾞｺｰﾄﾞ
   ,in_organization_id IN     NUMBER         --   組織ID
   ,in_loct_id         IN     NUMBER         --   保管倉庫ID
   ,id_shipment_date   IN     DATE           --   出荷日
   ,in_lead_time       IN     NUMBER         --   配送ﾘｰﾄﾞﾀｲﾑ
   ,od_receipt_date    OUT    DATE           --   着日
   ,ov_errbuf          OUT    VARCHAR2       --   ｴﾗｰ･ﾒｯｾｰｼﾞ           --# 固定 #
   ,ov_retcode         OUT    VARCHAR2       --   ﾘﾀｰﾝ･ｺｰﾄﾞ             --# 固定 #
   ,ov_errmsg          OUT    VARCHAR2       --   ﾕｰｻﾞｰ･ｴﾗｰ･ﾒｯｾｰｼﾞ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ﾛｰｶﾙ定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_receipt_date'; -- ﾌﾟﾛｸﾞﾗﾑ名
--
--#####################  固定ﾛｰｶﾙ変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- ｴﾗｰ･ﾒｯｾｰｼﾞ
    lv_retcode VARCHAR2(1);     -- ﾘﾀｰﾝ･ｺｰﾄﾞ
    lv_errmsg  VARCHAR2(5000);  -- ﾕｰｻﾞｰ･ｴﾗｰ･ﾒｯｾｰｼﾞ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ﾕｰｻﾞｰ宣言部
    -- ===============================
    -- *** ﾛｰｶﾙ定数 ***
    cn_active     CONSTANT NUMBER := 0;
--
    -- *** ﾛｰｶﾙ変数 ***
    lt_calendar_code mtl_parameters.calendar_code%TYPE := NULL;
--
    -- *** ﾛｰｶﾙ･ｶｰｿﾙ ***
--
    -- *** ﾛｰｶﾙ･ﾚｺｰﾄﾞ ***
--
--
  BEGIN
--
--##################  固定ｽﾃｰﾀｽ初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
    IF ( iv_calendar_code IS NULL ) THEN
      -- ===============================
      -- カレンダーコード取得
      -- ===============================
      BEGIN
        SELECT mil.attribute10
        INTO   lt_calendar_code
        FROM   mtl_item_locations mil
        WHERE  mil.organization_id        = in_organization_id
          AND  mil.inventory_location_id  = in_loct_id
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lt_calendar_code := NULL;
        --
      END;
      --
      -- カレンダコードが取得できなかった場合はプロファイルのドリンク基準カレンダを設定する。
      IF lt_calendar_code IS NULL THEN
        lt_calendar_code := FND_PROFILE.VALUE( cv_cmn_drink_cal_cd );
        --
        IF ( lt_calendar_code IS NULL ) THEN
          ov_errbuf        := NULL;
          ov_errmsg        := xxccp_common_pkg.get_msg(
                                 iv_application  => cv_msg_application
                                ,iv_name         => cv_message_00002
                                ,iv_token_name1  => cv_message_00002_token_1
                                ,iv_token_value1 => cv_cmn_drink_cal_cd_name
                                );
          od_receipt_date  := NULL;
          ov_retcode       := cv_status_error;
          RETURN;
        END IF;
        --
      END IF;
    ELSE
      lt_calendar_code := iv_calendar_code;
    END IF;
--
    -- ===============================
    -- 稼働日ｶﾚﾝﾀﾞ参照
    -- ===============================
    IF (in_lead_time = 0 ) THEN
      --配送ﾘｰﾄﾞﾀｲﾑが0日
      SELECT calendar_date
      INTO   od_receipt_date
      FROM (
        SELECT msd.calendar_date
        FROM   mr_shcl_hdr msh    -- 製造ｶﾚﾝﾀﾞﾍｯﾀﾞ
              ,mr_shcl_dtl msd    -- 製造ｶﾚﾝﾀﾞ明細
        WHERE  msh.calendar_no    = lt_calendar_code
          AND  msh.calendar_id    = msd.calendar_id
          AND  msd.delete_mark    = cn_active
          AND  msd.calendar_date >= id_shipment_date
          AND  msd.calendar_date  < ADD_MONTHS(id_shipment_date, 1)
        ORDER BY msd.calendar_date
      )
      WHERE ROWNUM <= 1
      ;
    ELSE
      --配送ﾘｰﾄﾞﾀｲﾑが1日以上
      SELECT MAX(calendar_date)
      INTO   od_receipt_date
      FROM (
        SELECT msd.calendar_date
        FROM   mr_shcl_hdr msh    -- 製造ｶﾚﾝﾀﾞﾍｯﾀﾞ
              ,mr_shcl_dtl msd    -- 製造ｶﾚﾝﾀﾞ明細
        WHERE  msh.calendar_no    =  lt_calendar_code
          AND  msh.calendar_id    =  msd.calendar_id
          AND  msd.delete_mark    =  cn_active
          AND  msd.calendar_date  > id_shipment_date
          AND  msd.calendar_date  < ADD_MONTHS(id_shipment_date, 1)
        ORDER BY msd.calendar_date
      )
      WHERE ROWNUM <= in_lead_time
      ;
    END IF;
--
  EXCEPTION
    WHEN OTHERS THEN
      ov_retcode       := cv_status_error;
      ov_errbuf        := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_errmsg        := NULL;
      od_receipt_date  := NULL;
--
  END get_receipt_date;
--
  /**********************************************************************************
   * Function Name   : get_shipment_date
   * Description      : 出荷日取得処理
   ***********************************************************************************/
  PROCEDURE get_shipment_date(
    iv_calendar_code   IN     VARCHAR2   --   製造カレンダコード
   ,in_organization_id IN     NUMBER     --   組織ID
   ,in_loct_id         IN     NUMBER     --   保管倉庫ID
   ,id_receipt_date    IN     DATE       --   着日
   ,in_lead_time       IN     NUMBER     --   配送リードタイム
   ,od_shipment_date   OUT    DATE       --   出荷日
   ,ov_errbuf          OUT    VARCHAR2   --   エラー・メッセージ           --# 固定 #
   ,ov_retcode         OUT    VARCHAR2   --   リターン・コード             --# 固定 #
   ,ov_errmsg          OUT    VARCHAR2   --   ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_shipment_date'; -- プログラム名
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
    cn_active     CONSTANT NUMBER := 0;
--
    -- *** ローカル変数 ***
    lt_calendar_code mtl_parameters.calendar_code%TYPE DEFAULT NULL;
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
    IF ( iv_calendar_code IS NULL ) THEN
      -- ===============================
      -- カレンダーコード取得
      -- ===============================
      BEGIN
        SELECT mil.attribute10
        INTO   lt_calendar_code
        FROM   mtl_item_locations mil
        WHERE  mil.organization_id        = in_organization_id
          AND  mil.inventory_location_id  = in_loct_id
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lt_calendar_code := NULL;
        --
      END;
      --
      -- カレンダコードが取得できなかった場合はプロファイルのドリンク基準カレンダを設定する。
      IF ( lt_calendar_code IS NULL ) THEN
        lt_calendar_code := FND_PROFILE.VALUE( cv_cmn_drink_cal_cd );
        --
        IF ( lt_calendar_code IS NULL ) THEN
          ov_errbuf        := NULL;
          ov_errmsg        := xxccp_common_pkg.get_msg(
                                 iv_application  => cv_msg_application
                                ,iv_name         => cv_message_00002
                                ,iv_token_name1  => cv_message_00002_token_1
                                ,iv_token_value1 => cv_cmn_drink_cal_cd_name
                                );
          od_shipment_date := NULL;
          ov_retcode       := cv_status_error;
          RETURN;
        END IF;
        --
      END IF;
    ELSE
      lt_calendar_code := iv_calendar_code;
    END IF;
--
    -- ===============================
    -- 稼働日カレンダ参照
    -- ===============================
    IF (in_lead_time = 0 ) THEN
      --配送リードタイムが0日
      SELECT calendar_date
      INTO   od_shipment_date
      FROM (
        SELECT msd.calendar_date
        FROM   mr_shcl_hdr msh    -- 製造カレンダヘッダ
              ,mr_shcl_dtl msd    -- 製造カレンダ明細
        WHERE  msh.calendar_no    = lt_calendar_code
          AND  msh.calendar_id    = msd.calendar_id
          AND  msd.delete_mark    = cn_active
          AND  msd.calendar_date <= id_receipt_date
        ORDER BY msd.calendar_date DESC
      )
      WHERE ROWNUM <= 1
      ;
    ELSE
      --配送リードタイムが1日以上
      SELECT MIN(calendar_date)
      INTO   od_shipment_date
      FROM (
        SELECT msd.calendar_date
        FROM   mr_shcl_hdr msh    -- 製造カレンダヘッダ
              ,mr_shcl_dtl msd    -- 製造カレンダ明細
        WHERE  msh.calendar_no    = lt_calendar_code
          AND  msh.calendar_id    = msd.calendar_id
          AND  msd.delete_mark    = cn_active
          AND  msd.calendar_date  < id_receipt_date
        ORDER BY msd.calendar_date DESC
      )
      WHERE ROWNUM <= in_lead_time
      ;
    END IF;
  EXCEPTION
--
    WHEN OTHERS THEN
      ov_retcode       := cv_status_error;
      ov_errbuf        := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_errmsg        := NULL;
      od_shipment_date := NULL;
--
  END get_shipment_date;
--
  /**********************************************************************************
   * Function Name   : get_item_category_f
   * Description      : 品目カテゴリ取得
   ***********************************************************************************/
  FUNCTION get_item_category_f(
     iv_category_set           IN     VARCHAR2    -- 品目カテゴリ名
    ,in_item_id                IN     NUMBER      -- 品目ID
  ) RETURN VARCHAR2 IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_item_category_f'; -- プログラム名
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    lv_category_value      VARCHAR2(100);                          -- 品目カテゴリ値
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
  --
    SELECT mcb.segment1            -- 品目カテゴリ値
    INTO   lv_category_value
    FROM   gmi_item_categories       gic
          ,mtl_categories_b          mcb
          ,mtl_category_sets_tl      mcst
    WHERE  gic.category_id        = mcb.category_id
      AND  gic.category_set_id    = mcst.category_set_id
      AND  mcst.source_lang       = cv_lang
      AND  mcst.language          = cv_lang
      AND  mcst.category_set_name = iv_category_set
      AND  gic.item_id            = in_item_id
    ;
--
    RETURN lv_category_value;
--
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RETURN NULL;
  END get_item_category_f;
--
  /**********************************************************************************
   * Function Name   : get_last_arrival_date_f
   * Description      : 最終入庫日取得
   ***********************************************************************************/
  FUNCTION get_last_arrival_date_f(
    in_rcpt_loct_id         IN     NUMBER,     --   移動先保管倉庫ID
    in_ship_loct_id         IN     NUMBER,     --   移動元保管倉庫ID
    in_item_id              IN     NUMBER      --   品目ID
  ) RETURN DATE IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_last_arrival_date_f'; -- プログラム名
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_mov_status_receipt  CONSTANT VARCHAR2(2) := '05';  -- 移動ステータス：入庫報告有
    cv_mov_status_ship     CONSTANT VARCHAR2(2) := '06';  -- 移動ステータス：入出庫報告有
    cv_doc_type            CONSTANT VARCHAR2(2) := '20';  -- 文書タイプ：移動
    cv_rec_type            CONSTANT VARCHAR2(2) := '30';  -- レコードタイプ：入庫実績
    cv_yes                 CONSTANT VARCHAR2(1) := 'Y';
    cv_no                  CONSTANT VARCHAR2(1) := 'N';
    cd_min_date            CONSTANT DATE        := TO_DATE('1900/01/01','YYYY/MM/DD');
--
    -- *** ローカル変数 ***
    ld_actual_arrival_date          DATE;      -- 入庫日
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
  --
    SELECT MAX(actual_arrival_date)       actual_arrival_date
    INTO   ld_actual_arrival_date
    FROM (
      SELECT mrih.actual_arrival_date     actual_arrival_date  -- 入庫実績日
      FROM   ic_item_mst_b               iimb                  -- OPM品目マスタ
            ,mtl_item_locations          mil_r                 -- OPM保管場所マスタ(入庫)
            ,ic_whse_mst                 iwm_r                 -- OPM倉庫マスタ(入庫)
            ,mtl_item_locations          mil_s                 -- OPM保管場所マスタ(出庫)
            ,ic_whse_mst                 iwm_s                 -- OPM倉庫マスタ(出庫)
            ,ic_lots_mst                 ilm                   -- OPMロットマスタ
            ,xxinv_mov_req_instr_headers mrih                  -- 移動依頼/指示ヘッダ
            ,xxinv_mov_req_instr_lines   mril                  -- 移動依頼/指示明細
            ,xxinv_mov_lot_details       mld                   -- 移動ロット詳細
      WHERE  ilm.item_id                 = iimb.item_id
        AND  ilm.lot_id                 <> 0
        AND  iwm_r.mtl_organization_id   = mil_r.organization_id
        AND  mrih.ship_to_locat_id       = mil_r.inventory_location_id
        AND  iwm_s.mtl_organization_id   = mil_s.organization_id
        AND  mrih.shipped_locat_id       = mil_s.inventory_location_id
        AND  mrih.correct_actual_flg     = cv_no
        AND  mrih.status                IN (cv_mov_status_receipt,cv_mov_status_ship)
        AND  mrih.mov_hdr_id             = mril.mov_hdr_id
        AND  mril.mov_line_id            = mld.mov_line_id
        AND  mril.delete_flg             = cv_no
        AND  mld.item_id                 = iimb.item_id
        AND  mld.lot_id                  = ilm.lot_id
        AND  mld.document_type_code      = cv_doc_type
        AND  mld.record_type_code        = cv_rec_type
        AND  mil_r.inventory_location_id = in_rcpt_loct_id
        AND  mil_s.inventory_location_id = in_ship_loct_id
        AND  iimb.item_id                = in_item_id
      UNION ALL
      SELECT mrih.actual_arrival_date     actual_arrival_date  -- 入庫実績日
      FROM   ic_item_mst_b               iimb                  -- OPM品目マスタ
            ,mtl_item_locations          mil_r                 -- OPM保管場所マスタ(入庫)
            ,ic_whse_mst                 iwm_r                 -- OPM倉庫マスタ(入庫)
            ,mtl_item_locations          mil_s                 -- OPM保管場所マスタ(出庫)
            ,ic_whse_mst                 iwm_s                 -- OPM倉庫マスタ(出庫)
            ,ic_lots_mst                 ilm                   -- OPMロットマスタ
            ,xxinv_mov_req_instr_headers mrih                  -- 移動依頼/指示ヘッダ
            ,xxinv_mov_req_instr_lines   mril                  -- 移動依頼/指示明細
            ,xxinv_mov_lot_details       mld                   -- 移動ロット詳細
      WHERE  ilm.item_id                 = iimb.item_id
        AND  ilm.lot_id                 <> 0
        AND  iwm_r.mtl_organization_id   = mil_r.organization_id
        AND  mrih.ship_to_locat_id       = mil_r.inventory_location_id
        AND  iwm_s.mtl_organization_id   = mil_s.organization_id
        AND  mrih.shipped_locat_id       = mil_s.inventory_location_id
        AND  mrih.correct_actual_flg     = cv_yes
        AND  mrih.status                 = cv_mov_status_ship
        AND  mrih.mov_hdr_id             = mril.mov_hdr_id
        AND  mril.mov_line_id            = mld.mov_line_id
        AND  mril.delete_flg             = cv_no
        AND  mld.item_id                 = iimb.item_id
        AND  mld.lot_id                  = ilm.lot_id
        AND  mld.document_type_code      = cv_doc_type
        AND  mld.record_type_code        = cv_rec_type
        AND  mil_r.inventory_location_id = in_rcpt_loct_id
        AND  mil_s.inventory_location_id = in_ship_loct_id
        AND  iimb.item_id                = in_item_id
    );
--
    -- 取得できなかった場合は最小日付を設定
    IF ( ld_actual_arrival_date IS NULL ) THEN
      ld_actual_arrival_date := cd_min_date;
    END IF;
    --
    RETURN ld_actual_arrival_date;
--
  END get_last_arrival_date_f;
--
  /**********************************************************************************
   * Function Name   : get_last_purchase_date_f
   * Description      : 最終購入日取得
   ***********************************************************************************/
  FUNCTION get_last_purchase_date_f(
    in_loct_id              IN     NUMBER,     --   保管倉庫ID
    in_item_id              IN     NUMBER      --   品目ID
  ) RETURN DATE IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name           CONSTANT VARCHAR2(100) := 'get_last_purchase_date_f'; -- プログラム名
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cd_min_date           CONSTANT DATE          := TO_DATE('1900/01/01','YYYY/MM/DD');  -- 最小日付
    cv_lot_status_reject  CONSTANT VARCHAR2(2)   := '60';          -- ロットステータス：不合格
    cv_duty_status_finish CONSTANT VARCHAR2(1)   := '7';           -- 業務ステータス：完了
    cv_duty_status_close  CONSTANT VARCHAR2(1)   := '8';           -- 業務ステータス：クローズ
    cv_doc_type           CONSTANT VARCHAR2(4)   := 'PROD';        -- 文書タイプ
    cv_po_status_receive  CONSTANT VARCHAR2(2)   := '25';          -- 発注アドオンステータス：受入あり
    cv_po_status_fix_qty  CONSTANT VARCHAR2(2)   := '30';          -- 発注アドオンステータス：数量確定済
    cv_po_status_fix_amt  CONSTANT VARCHAR2(2)   := '35';          -- 発注アドオンステータス：金額確定済
    cv_txn_type_receive   CONSTANT VARCHAR2(1)   := '1';           -- 実績区分：受入
--
    -- *** ローカル変数 ***
    ld_actual_txn_date             DATE;                           -- 最終購入日
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
    --
    SELECT MAX(actual_txn_date)
    INTO   ld_actual_txn_date
    FROM   (
      -- 最終生産日取得
      SELECT TO_DATE(gmd.attribute11,'YYYY/MM/DD')  actual_txn_date
             --
      FROM   gme_batch_header gbh            -- 生産バッチヘッダ
            ,gme_material_details gmd        -- 生産原料詳細
            ,gmd_routings_vl grv             -- 工順マスタ
            ,mtl_item_locations mil          -- OPM保管場所マスタ
            ,hr_all_organization_units haou  -- 組織マスタ
            ,ic_whse_mst iwm                 -- OPM倉庫マスタ
            ,ic_tran_pnd itp                 -- OPM保留在庫トランザクション
            ,ic_lots_mst ilm                 -- OPMロット
            ,ic_item_mst_b iimb              -- OPM品目マスタ
      WHERE
             gbh.routing_id            = grv.routing_id
      AND    grv.attribute9            = mil.segment1
      AND    mil.organization_id       = iwm.mtl_organization_id
      AND    iwm.mtl_organization_id   = haou.organization_id
      AND    gbh.batch_id              = gmd.batch_id
      AND    gmd.material_detail_id    = itp.line_id
--20091207_Ver2.5_I_E_479_023_SCS.Goto_ADD_START
      AND    gmd.item_id               = iimb.item_id
--20091207_Ver2.5_I_E_479_023_SCS.Goto_ADD_END
      AND    itp.lot_id                = ilm.lot_id
      AND    itp.item_id               = ilm.item_id
      AND    ilm.item_id               = iimb.item_id
      AND    ilm.attribute23           NOT IN (cv_lot_status_reject)
      AND    ilm.lot_id                <> 0
      AND    gbh.attribute4            IN (cv_duty_status_finish,cv_duty_status_close)
      AND    gmd.line_type             = 1
      AND    itp.reverse_id (+)        IS NULL
      AND    itp.doc_type              = cv_doc_type
      AND    itp.delete_mark           = 0
      AND    mil.inventory_location_id = in_loct_id
      AND    iimb.item_id              = in_item_id
      --
      UNION ALL
      -- 最終購入(受入)日付
      SELECT xrart.txns_date  actual_txn_date
      FROM   po_headers_all            pha    -- 発注ヘッダ
            ,po_lines_all              pla    -- 発注明細
            ,xxpo_rcv_and_rtn_txns     xrart  -- 受入返品実績
            ,ic_lots_mst               ilm    -- OPMロットマスタ
            ,ic_item_mst_b             iimb   -- OPM品目マスタ
            ,hr_all_organization_units haou   -- 組織マスタ
            ,ic_whse_mst               iwm    -- OPM倉庫マスタ
            ,mtl_item_locations        mil    -- OPM保管場所マスタ
      WHERE  
             pha.attribute1            IN (cv_po_status_receive,cv_po_status_fix_qty,cv_po_status_fix_amt)
      AND    pha.org_id                = FND_PROFILE.VALUE('ORG_ID')
      AND    pha.po_header_id          = pla.po_header_id
      AND    pha.segment1              = xrart.source_document_number
      AND    pla.line_num              = xrart.source_document_line_num
      AND    xrart.txns_type           = cv_txn_type_receive
      AND    xrart.lot_id              = ilm.lot_id
--20091207_Ver2.5_I_E_479_023_SCS.Goto_ADD_START
      AND    xrart.item_id             = iimb.item_id
--20091207_Ver2.5_I_E_479_023_SCS.Goto_ADD_END
      AND    ilm.lot_id                <> 0
      AND    ilm.attribute23           NOT IN (cv_lot_status_reject)
      AND    ilm.item_id               = iimb.item_id
      AND    haou.organization_id      = iwm.mtl_organization_id
      AND    iwm.mtl_organization_id   = mil.organization_id
      AND    mil.segment1              = xrart.location_code
      AND    mil.inventory_location_id = in_loct_id
      AND    iimb.item_id              = in_item_id
    );
--
    -- 取得できなかった場合は最小日付を設定
    IF ( ld_actual_txn_date IS NULL ) THEN
      ld_actual_txn_date := cd_min_date;
    END IF;
    --
    RETURN ld_actual_txn_date;
--
  END get_last_purchase_date_f;
--
END XXCOP_COMMON_PKG2;
/
