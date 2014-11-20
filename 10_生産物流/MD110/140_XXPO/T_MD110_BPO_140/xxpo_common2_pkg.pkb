CREATE OR REPLACE PACKAGE BODY xxpo_common2_pkg
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name           : xxpo_common2_pkg(BODY)
 * Description            : 共通関数(有償支給用)(BODY)
 * MD.070(CMD.050)        : T_MD050_BPO_140_共通関数（補足資料）.xls
 * Version                : 1.2
 *
 * Program List
 *  ------------------------- ---- ----- --------------------------------------------------
 *   Name                     Type  Ret   Description
 *  ------------------------- ---- ----- --------------------------------------------------
 *  update_order_data         F    N     全数入出庫 入出庫実績登録処理
 *  get_unit_price            F    N     価格表単価取得処理
 *  update_order_unit_price   P    -     受注明細アドオン単価更新処理
 *
 * Change Record
 * ------------ ----- ---------------- -----------------------------------------------
 *  Date         Ver.  Editor           Description
 * ------------ ----- ---------------- -----------------------------------------------
 *  2008/03/12   1.0   D.Nihei         新規作成
 *  2008/05/29   1.0   D.Nihei         結合テスト不具合対応(全数出庫時ステータス更新誤り)
 *  2008/07/18   1.1   D.Nihei         ST#445対応
 *  2010/09/22   1.2   H.Sasaki        [E_本稼動_02515]出荷日、着荷日の更新条件追加
 *****************************************************************************************/
--
--#######################  固定グローバル定数宣言部 START   #######################
--
  gv_status_normal CONSTANT VARCHAR2(1) := '0';
  gv_status_warn   CONSTANT VARCHAR2(1) := '1';
  gv_status_error  CONSTANT VARCHAR2(1) := '2';
  gv_sts_cd_normal CONSTANT VARCHAR2(1) := 'C';
  gv_sts_cd_warn   CONSTANT VARCHAR2(1) := 'G';
  gv_sts_cd_error  CONSTANT VARCHAR2(1) := 'E';
  gv_msg_part      CONSTANT VARCHAR2(3) := ' : ';
  gv_msg_cont      CONSTANT VARCHAR2(3) := '.';
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
  gv_pkg_name      CONSTANT VARCHAR2(100) := 'xxpo_common2_pkg'; -- パッケージ名
--
  gn_ret_nomal     CONSTANT NUMBER := 0; -- 正常
  gn_ret_error     CONSTANT NUMBER := 1; -- エラー
--
  gc_application_po    CONSTANT VARCHAR2(4)  := 'XXPO'; -- アプリケーション（XXPO）
  gv_xxpo_10200        CONSTANT VARCHAR2(14) := 'APP-XXPO-10200'; --単価取得エラー
  gv_xxpo_10201        CONSTANT VARCHAR2(14) := 'APP-XXPO-10201'; --明細更新エラー
  gv_tkn_item          CONSTANT VARCHAR2(4) := 'ITEM'; --トークン名
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
--
   /**********************************************************************************
   * Function Name    : update_order_data
   * Description      : 全数入出庫 入出庫実績登録処理
   ***********************************************************************************/
  FUNCTION update_order_data(
       in_order_header_id    IN  NUMBER         -- 受注ヘッダアドオンID
      ,iv_record_type_code   IN  VARCHAR2       -- レコードタイプ(20：出庫実績、30：入庫実績)
      ,id_actual_date        IN  DATE           -- 実績日(入庫日・出庫日)
      ,in_created_by         IN  NUMBER         -- 作成者
      ,id_creation_date      IN  DATE           -- 作成日
      ,in_last_updated_by    IN  NUMBER         -- 最終更新者
      ,id_last_update_date   IN  DATE           -- 最終更新日
      ,in_last_update_login  IN  NUMBER         -- 最終更新ログイン
   ) 
  RETURN NUMBER
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100) := 'update_order_data'; --プログラム名
  BEGIN
--
    -- ===============================
    -- 移動ロット詳細登録
    -- ===============================
    -- パラメータの受注ヘッダアドオンIDに紐付く移動ロット詳細のレコードタイプ「10：指示」のデータを
    -- 入庫・出庫実績として登録する。
    INSERT INTO xxinv_mov_lot_details                                              -- 移動ロット詳細
              ( mov_lot_dtl_id                                                     -- ロット詳細ID
               ,mov_line_id                                                        -- 明細ID
               ,document_type_code                                                 -- 文書タイプ
               ,record_type_code                                                   -- レコードタイプ
               ,item_id                                                            -- OPM品目ID
               ,item_code                                                          -- 品目
               ,lot_id                                                             -- ロットID
               ,lot_no                                                             -- ロットNo
               ,actual_date                                                        -- 実績日
               ,actual_quantity                                                    -- 実績数量
               ,created_by                                                         -- 作成者
               ,creation_date                                                      -- 作成日
               ,last_updated_by                                                    -- 最終更新者
               ,last_update_date                                                   -- 最終更新日
               ,last_update_login )                                                -- 最終更新ログイン
        SELECT  xxinv_mov_lot_s1.NEXTVAL                                           -- 移動ロット詳細識別用
               ,xola.order_line_id                                                 -- 受注明細アドオンID
               ,xmld.document_type_code                                            -- 文書タイプ
               ,iv_record_type_code                                                -- レコードタイプ
               ,xmld.item_id                                                       -- OPM品目ID
               ,xmld.item_code                                                     -- 品目
               ,xmld.lot_id                                                        -- ロットID
               ,xmld.lot_no                                                        -- ロットNo
               ,id_actual_date                                                     -- 実績日
               ,xmld.actual_quantity                                               -- 実績数量
               ,in_created_by                                                      -- 作成者
               ,id_creation_date                                                   -- 作成日
               ,in_last_updated_by                                                 -- 最終更新者
               ,id_last_update_date                                                -- 最終更新日
               ,in_last_update_login                                               -- 最終更新ログイン
        FROM    xxinv_mov_lot_details     xmld                                     -- 移動ロット詳細
               ,xxwsh_order_headers_all   xoha                                     -- 受注ヘッダアドオン
               ,xxwsh_order_lines_all     xola                                     -- 受注明細アドオン
        WHERE   xoha.order_header_id    = in_order_header_id
        AND     xola.order_header_id    = xoha.order_header_id
        AND     xmld.mov_line_id        = xola.order_line_id
        AND     xmld.document_type_code = '30'                                     -- 支給指示
        AND     xmld.record_type_code   = '10'                                     -- 指示
    ;
--
    -- ===============================
    -- 受注明細アドオン更新
    -- ===============================
    -- パラメータの受注ヘッダアドオンIDに紐付く受注明細アドオンの出荷実績数量を更新する。
    UPDATE xxwsh_order_lines_all          xola                                     -- 受注明細アドオン
    SET    xola.shipped_quantity        = DECODE( iv_record_type_code
                                                 ,'20', xola.quantity              -- 出荷実績数量を数量で更新(出庫時)
                                                 ,xola.shipped_quantity )          -- 入庫時は出荷実績数量そのまま
          ,xola.ship_to_quantity        = DECODE( iv_record_type_code
                                                 ,'30', xola.quantity              -- 入庫実績数量を数量で更新(入庫時)
                                                 ,xola.ship_to_quantity )          -- 出庫時は出荷実績数量そのまま
          ,xola.last_updated_by         = in_last_updated_by                       -- 最終更新者
          ,xola.last_update_date        = id_last_update_date                      -- 最終更新日
          ,xola.last_update_login       = in_last_update_login                     -- 最終更新ログイン
    WHERE  xola.order_header_id         = in_order_header_id
-- 2008/07/18 D.Nihei MOD START
--    AND    NVL( xola.delete_flag, 'N' ) = 'N'                                      -- 削除フラグOFF
    AND    xola.delete_flag = 'N'                                      -- 削除フラグOFF
-- 2008/07/18 D.Nihei MOD END
    ;
--
    -- ===============================
    -- 受注ヘッダアドオン更新
    -- ===============================
    -- パラメータの受注ヘッダアドオンIDの受注ヘッダアドオンのステータス・出荷日を更新する。
    UPDATE xxwsh_order_headers_all        xoha                                     -- 受注ヘッダアドオン
    SET    xoha.req_status              = DECODE( iv_record_type_code
-- 2008/05/29 D.Nihei MOD START
--                                                 ,'20', '04'                       -- 出荷実績計上済(出庫時更新)
                                                 ,'20', '08'                       -- 出荷実績計上済(出庫時更新)
-- 2008/05/29 D.Nihei MOD END
                                                 ,xoha.req_status )                -- 入庫時はそのまま
-- == 2010/09/22 V1.2 Modified START ===============================================================
--          ,xoha.shipped_date            = DECODE( iv_record_type_code
--                                                 ,'20', xoha.schedule_ship_date    -- 出荷日を出荷予定日で更新
--                                                 ,xoha.shipped_date )
--          ,xoha.arrival_date            = DECODE( iv_record_type_code
--                                                 ,'30', xoha.schedule_arrival_date -- 着荷日を着荷予定日で更新
--                                                 ,xoha.arrival_date )
          ,xoha.shipped_date            = CASE  WHEN  iv_record_type_code = '20' AND xoha.shipped_date IS NULL THEN xoha.schedule_ship_date
                                                ELSE  xoha.shipped_date
                                          END   -- 出荷日未設定の場合、出荷予定日で更新
          ,xoha.arrival_date            = CASE  WHEN  iv_record_type_code = '30' AND xoha.arrival_date IS NULL THEN xoha.schedule_arrival_date
                                                ELSE  xoha.arrival_date
                                          END   -- 着荷日未設定の場合、着荷予定日で更新
-- == 2010/09/22 V1.2 Modified END   ===============================================================
-- 2008/07/18 D.Nihei ADD START
          ,xoha.result_freight_carrier_id   = DECODE( iv_record_type_code
                                                     ,'20', xoha.career_id                      -- 全数出庫の場合、運送業者_実績IDを運送業者IDで更新
                                                     ,xoha.result_freight_carrier_id )          -- 全数入庫の場合、更新対象外
          ,xoha.result_freight_carrier_code = DECODE( iv_record_type_code
                                                     ,'20', xoha.freight_carrier_code           -- 全数出庫の場合、運送業者_実績を運送業者で更新
                                                     ,xoha.result_freight_carrier_code )        -- 全数入庫の場合、更新対象外
          ,xoha.result_shipping_method_code = DECODE( iv_record_type_code
                                                     ,'20', xoha.shipping_method_code           -- 全数出庫の場合、配送区分_実績を配送区分で更新
                                                     ,xoha.result_shipping_method_code )        -- 全数入庫の場合、更新対象外
-- 2008/07/18 D.Nihei ADD START
          ,xoha.last_updated_by         = in_last_updated_by                       -- 最終更新者
          ,xoha.last_update_date        = id_last_update_date                      -- 最終更新日
          ,xoha.last_update_login       = in_last_update_login                     -- 最終更新ログイン
    WHERE  xoha.order_header_id         = in_order_header_id
    ;
--
    --ステータスセット
    RETURN gn_ret_nomal;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
      RETURN gn_ret_error;
--
--#####################################  固定部 END   ##########################################
--
  END update_order_data;
--
   /**********************************************************************************
   * Function Name    : get_unit_price
   * Description      : 価格表単価取得処理
   ***********************************************************************************/
  FUNCTION get_unit_price(
    in_inventory_item_id  IN  NUMBER         -- INV品目ID
   ,iv_list_id_vendor     IN  VARCHAR2       -- 取引先別価格表ID
   ,iv_list_id_represent  IN  VARCHAR2       -- 代表価格表ID
   ,id_arrival_date       IN  DATE           -- 適用日(入庫日)
  )
  RETURN NUMBER
  IS
    -- ===============================
    -- ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100) := 'get_unit_price'; --プログラム名
    cv_product_attr         CONSTANT VARCHAR2(18)  := 'PRICING_ATTRIBUTE1';
    cv_product_attr_ctxt    CONSTANT VARCHAR2(4)   := 'ITEM';
    cv_tkn_item             CONSTANT VARCHAR2(4)   := 'ITEM';
--
    -- ===============================
    -- ローカル変数
    -- ===============================
    ln_unit_price           NUMBER;
    lb_get_represent        BOOLEAN;
    lb_get_vendor           BOOLEAN;
--
    --パラメータ格納用レコード
    TYPE lt_prm IS RECORD(
      inventory_item_id     NUMBER
     ,list_id_vendor        VARCHAR2(1000)
     ,list_id_represent     VARCHAR2(1000)
     ,arrival_date          DATE
    );
    lr_prm                lt_prm;
--
    -- ===============================
    -- ローカルファンクション
    -- ===============================
    FUNCTION get_operand(
      in_list_header_id  IN  NUMBER
     ,in_inventory_item_id IN NUMBER
     ,id_arrival_date IN DATE
    )
    RETURN NUMBER
    IS
      ln_list_header_id      NUMBER;
      ln_inventory_item_id   NUMBER;
      ld_arrival_date        DATE;
    BEGIN
      --パラメータ格納
      ln_list_header_id := in_list_header_id;
      ln_inventory_item_id := in_inventory_item_id;
      ld_arrival_date := id_arrival_date;
--
      --パラメータチェック
      IF (ln_list_header_id IS NOT NULL
        AND ln_inventory_item_id IS NOT NULL
        AND ld_arrival_date IS NOT NULL
      ) THEN
        NULL;
      ELSE
        --未入力のパラメータがある場合はNULLを返して終了
        RETURN NULL;
      END IF;
--
      --価格表から単価取得
      SELECT qll.operand              operand   -- 単価
      INTO ln_unit_price
      FROM   qp_list_lines            qll       -- 価格表明細
            ,qp_pricing_attributes    qpa       -- 価格表明細詳細
      -- 結合条件
      WHERE qpa.list_header_id = qll.list_header_id
      AND qpa.list_line_id = qll.list_line_id
      AND qpa.pricing_phase_id = qll.pricing_phase_id
      -- 抽出条件
      AND qll.list_header_id = ln_list_header_id                     -- 価格表ID
      AND ld_arrival_date
        BETWEEN NVL(qll.start_date_active,ld_arrival_date)           -- 適用開始日
        AND NVL(qll.end_date_active,ld_arrival_date)                 -- 適用終了日
      AND qpa.product_attr_value = TO_CHAR(ln_inventory_item_id)     -- INV品目ID
      AND qpa.product_attribute = cv_product_attr
      AND qpa.product_attribute_context = cv_product_attr_ctxt
      ;
--
      RETURN ln_unit_price;
--
    EXCEPTION
      WHEN OTHERS THEN
        RETURN NULL;
    END get_operand;
--
  BEGIN
--  
    -- 初期化
    ln_unit_price := NULL;
    lb_get_represent := FALSE;
--
    --パラメータ格納
    lr_prm.inventory_item_id := in_inventory_item_id;
    lr_prm.list_id_vendor := iv_list_id_vendor;
    lr_prm.list_id_represent := iv_list_id_represent;
    lr_prm.arrival_date := id_arrival_date;
--
    IF (lr_prm.list_id_vendor IS NULL) THEN    -- 取引先価格表IDがセットされなかった場合
      lb_get_represent := TRUE;
    ELSE                                       -- 取引先価格表IDがセットされた場合
      DECLARE
        ln_list_id  NUMBER;
      BEGIN
        -- 取引先価格表IDの値チェック
        ln_list_id := TO_NUMBER(lr_prm.list_id_vendor);
        lb_get_vendor := TRUE;
      EXCEPTION
        WHEN OTHERS THEN
          -- NUMBER型に変換できない場合は取引先価格表IDではなく代表価格表IDで検索
          lb_get_vendor := FALSE;
          lb_get_represent := TRUE;
      END;
    END IF;
--
    IF (lb_get_vendor) THEN
      --取引先価格表IDで単価を取得
      ln_unit_price := get_operand(
                         TO_NUMBER(lr_prm.list_id_vendor)
                        ,lr_prm.inventory_item_id
                        ,lr_prm.arrival_date
                       );
      IF (ln_unit_price IS NULL) THEN
        lb_get_represent := TRUE;
      END IF;
    END IF;
--
    IF (lb_get_represent) THEN    -- 取引先価格表IDで単価を取得できなかった場合
        --代表価格表IDで単価を取得
        ln_unit_price := get_operand(
                           TO_NUMBER(lr_prm.list_id_represent)
                          ,lr_prm.inventory_item_id
                          ,lr_prm.arrival_date
                         );
    END IF;
--
    RETURN ln_unit_price;
--
  EXCEPTION
--#################################  固定例外処理部 START   ####################################
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      RETURN NULL;
--
--#####################################  固定部 END   ##########################################
--
  END get_unit_price;
--
   /**********************************************************************************
   * Procedure Name   : update_order_unit_price
   * Description      : 受注明細アドオン単価更新処理
   ***********************************************************************************/
  PROCEDURE update_order_unit_price(
    in_order_header_id    IN  xxwsh_order_lines_all.order_header_id%TYPE     -- 受注ヘッダアドオンID
   ,iv_list_id_vendor     IN  VARCHAR2                                       -- 取引先別価格表ID
   ,iv_list_id_represent  IN  VARCHAR2                                       -- 代表価格表ID
   ,id_arrival_date       IN  xxwsh_order_headers_all.arrival_date%TYPE      -- 適用日(入庫日)
   ,iv_return_flag        IN  VARCHAR2                                       -- 返品フラグ
   ,iv_item_class_code    IN  xxcmn_item_categories2_v.segment1%TYPE         -- 品目区分
   ,iv_item_no            IN  xxcmn_item_categories2_v.item_no%TYPE          -- OPM品目コード
   ,ov_retcode            OUT NOCOPY VARCHAR2                                -- エラーコード
   ,ov_errmsg             OUT NOCOPY VARCHAR2                                -- エラーメッセージ
   ,ov_system_msg         OUT NOCOPY VARCHAR2                                -- システムメッセージ
  ) IS
    -- ===============================
    -- ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100) := 'update_order_unit_price'; --プログラム名
    cv_err_id_text          CONSTANT VARCHAR2(13)  := 'ORDER_LINE_ID';
    cv_err_msg_text         CONSTANT VARCHAR2(7)   := 'SQLERRM';
    cv_text_left            CONSTANT VARCHAR2(1)   := '[';
    cv_text_right           CONSTANT VARCHAR2(1)   := ']';
    cv_text_description     CONSTANT VARCHAR2(12)  := '価格表未登録';
    cv_text_item            CONSTANT VARCHAR2(10)  := '品目コード';
    cv_text_vendor          CONSTANT VARCHAR2(14)  := '取引先価格表ID';
    cv_text_represent       CONSTANT VARCHAR2(12)  := '代表価格表ID';
    cv_text_date            CONSTANT VARCHAR2(6)   := '適用日';
--
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errmsg             VARCHAR2(5000);
    lv_systemmsg          VARCHAR2(5000);
    lb_get_unit_price     BOOLEAN;
    ln_unit_price         xxwsh_order_lines_all.unit_price%TYPE;
    lv_item_no            xxwsh_order_lines_all.shipping_item_code%TYPE;
    ln_cnt                NUMBER;
--
    --パラメータ格納用レコード
    TYPE lt_prm IS RECORD(
      order_header_id     xxwsh_order_lines_all.order_header_id%TYPE --受注ヘッダアドオンID
     ,list_id_vendor      VARCHAR2(1000) --取引先別価格表ID
     ,list_id_represent   VARCHAR2(1000) --代表価格表ID
     ,arrival_date        xxwsh_order_headers_all.arrival_date%TYPE --適用日(入庫日)
     ,return_flag         VARCHAR2(10) --返品フラグ
     ,item_class_code     xxcmn_item_categories2_v.segment1%TYPE --品目区分
     ,item_no             xxcmn_item_categories2_v.item_no%TYPE --OPM品目コード
    );
    lr_prm                lt_prm;
--
    --受注明細アドオン格納用レコード
    TYPE lt_order_line IS RECORD(
      order_line_id       xxwsh_order_lines_all.order_line_id%TYPE --受注明細アドオンID
     ,unit_price          xxwsh_order_lines_all.unit_price%TYPE --単価
     ,inventory_item_id   xxwsh_order_lines_all.shipping_inventory_item_id%TYPE --出荷品目ID
     ,item_no             xxwsh_order_lines_all.shipping_item_code%TYPE --出荷品目
    );
    lr_order_line         lt_order_line;
--
    -- ===============================
    -- ローカルカーソル
    -- ===============================
    TYPE lt_ref IS REF CURSOR;
    cur_order_line     lt_ref;
--
    -- ===============================
    -- ローカル例外
    -- ===============================
    get_unit_price_exception   EXCEPTION;
--
  BEGIN
    --初期処理
    ov_errmsg := NULL;
    ov_system_msg := NULL;
    lr_prm.order_header_id := in_order_header_id;                              --受注ヘッダアドオンID
    lr_prm.list_id_vendor := iv_list_id_vendor;                                --取引先別価格表ID
    lr_prm.list_id_represent := iv_list_id_represent;                          --代表価格表ID
    lr_prm.arrival_date := id_arrival_date;                                    --適用日(入庫日)
    lr_prm.return_flag := iv_return_flag;                                      --返品フラグ
    lr_prm.item_class_code := iv_item_class_code;                              --品目区分
    lr_prm.item_no := iv_item_no;                                              --OPM品目コード
--
    --品目区分、OPM品目コードの指定が無い場合
    IF (lr_prm.item_class_code IS NULL AND lr_prm.item_no IS NULL) THEN
      OPEN cur_order_line FOR
        SELECT xola.order_line_id                                              --受注明細アドオンID
              ,xola.unit_price                                                 --単価
              ,xola.shipping_inventory_item_id                                 --出荷品目ID
              ,xola.shipping_item_code                                         --出荷品目
        FROM   xxwsh_order_lines_all xola                                      --受注明細アドオン
        WHERE  xola.order_header_id = lr_prm.order_header_id                   --受注ヘッダアドオンID
        AND    NVL(xola.delete_flag,'N') = 'N'                                 --削除フラグ
        ORDER BY xola.order_line_number                                        --受注明細番号
        ;
--
    --OPM品目コードが指定された場合
    ELSIF (lr_prm.item_no IS NOT NULL) THEN
      OPEN cur_order_line FOR
        SELECT xola.order_line_id                                              --受注明細アドオンID
              ,xola.unit_price                                                 --単価
              ,xola.shipping_inventory_item_id                                 --出荷品目ID
              ,xola.shipping_item_code                                         --出荷品目
        FROM   xxwsh_order_lines_all xola                                      --受注明細アドオン
        WHERE  xola.order_header_id = lr_prm.order_header_id                   --受注ヘッダアドオンID
        AND    NVL(xola.delete_flag,'N') = 'N'                                 --削除フラグ
        AND    xola.shipping_item_code = lr_prm.item_no                        --出荷品目
        ORDER BY xola.order_line_number                                        --受注明細番号
        ;
--
    --OPM品目コードが指定されず、品目区分が指定された場合
    ELSIF (lr_prm.item_class_code IS NOT NULL) THEN
      OPEN cur_order_line FOR
        SELECT xola.order_line_id                                              --受注明細アドオンID
              ,xola.unit_price                                                 --単価
              ,xola.shipping_inventory_item_id                                 --出荷品目ID
              ,xola.shipping_item_code                                         --出荷品目
        FROM   xxwsh_order_lines_all xola                                      --受注明細アドオン
              ,xxcmn_item_categories2_v xicv                                   --品目カテゴリ情報view2
        WHERE  xola.order_header_id = lr_prm.order_header_id                   --受注ヘッダアドオンID
        AND    NVL(xola.delete_flag,'N') = 'N'                                 --削除フラグ
        AND    xicv.item_no = xola.shipping_item_code                          --品目コード
        AND    xicv.category_set_name = '品目区分'                             --カテゴリセット名
        AND    xicv.segment1 = lr_prm.item_class_code                          --品目区分
        ORDER BY xola.order_line_number                                        --受注明細番号
        ;
    END IF;
--
    ln_cnt := 0;
--
    <<line_loop>>
    LOOP
      FETCH cur_order_line INTO lr_order_line;
      EXIT WHEN cur_order_line%NOTFOUND;
--
      --初期化処理
      lb_get_unit_price := FALSE;
      ln_cnt := ln_cnt + 1;
--
      --返品の場合
      IF (lr_prm.return_flag = 'Y') THEN
        --単価が未入力の場合
        IF (lr_order_line.unit_price IS NULL) THEN
          --単価取得処理を行う
          lb_get_unit_price := TRUE;
        END IF;
      --返品ではない場合
      ELSE
        --単価取得処理を行う
        lb_get_unit_price := TRUE;
      END IF;
--
      IF (lb_get_unit_price) THEN
        --価格表から単価取得
        ln_unit_price := get_unit_price(
                           lr_order_line.inventory_item_id                     --品目ID
                          ,lr_prm.list_id_vendor                               --取引先別価格表ID
                          ,lr_prm.list_id_represent                            --代表価格表ID
                          ,lr_prm.arrival_date                                 --適用日(入庫日)
                         );
--
        --単価がNULLの場合
        IF (ln_unit_price IS NULL) THEN
          --単価取得エラー
          lv_item_no := lr_order_line.item_no;
          CLOSE cur_order_line;
--
          RAISE get_unit_price_exception;
        --単価が返された場合
        ELSE
          --現在の単価と価格表の単価が同じ場合は更新をスキップする
          --⇒品目コードをエラーメッセージにセット
          IF (lr_order_line.unit_price = ln_unit_price) THEN
            ov_errmsg := lr_order_line.item_no;
          --現在の単価と価格表の単価が異なる場合は更新する
          ELSE
            UPDATE xxwsh_order_lines_all xola                                --受注明細アドオン
            SET xola.unit_price = ln_unit_price                              --単価=価格表の単価
               ,xola.last_updated_by = fnd_global.user_id                    --最終更新者
               ,xola.last_update_date = SYSDATE                              --最終更新日
               ,xola.last_update_login = fnd_global.login_id                 --最終更新ログイン
               --以下、コンカレントから実行された場合はFND_GLOBALの値で更新
               ,xola.request_id                                              --要求ID
                = DECODE(fnd_global.conc_request_id
                           ,-1,xola.request_id
                              ,fnd_global.conc_request_id)
               ,xola.program_application_id                                  --プログラムアプリケーションID
                = DECODE(fnd_global.conc_request_id
                           ,-1,xola.program_application_id
                              ,fnd_global.prog_appl_id)
               ,xola.program_id                                              --プログラムID
                 = DECODE(fnd_global.conc_request_id
                           ,-1,xola.program_id
                              ,fnd_global.conc_program_id)
               ,xola.program_update_date                                     --プログラム更新日
                = DECODE(fnd_global.conc_request_id
                           ,-1,xola.program_update_date
                           ,SYSDATE)
            WHERE xola.order_line_id = lr_order_line.order_line_id           --受注明細アドオンID
            ;
          END IF;
        END IF;
      END IF;
    END LOOP line_loop;
    CLOSE cur_order_line;
--
    --正常終了
    IF (ln_cnt > 0) THEN
      ov_retcode := gv_status_normal;
    ELSE
      ov_retcode := gv_status_warn;
    END IF;
--
  EXCEPTION
    -- *** 単価取得例外ハンドラ ***
    WHEN get_unit_price_exception THEN
      ov_retcode := gv_status_error;
      ov_errmsg := lv_item_no;
      ov_system_msg := SUBSTRB(gv_pkg_name || gv_msg_cont || cv_prg_name || gv_msg_part || 
                               cv_text_description || ' ' ||
                               cv_text_item || cv_text_left || ov_errmsg  || cv_text_right || ' ' ||
                               cv_text_vendor || cv_text_left || iv_list_id_vendor  || cv_text_right || ' ' ||
                               cv_text_represent || cv_text_left || iv_list_id_represent  || cv_text_right || ' ' ||
                               cv_text_date || cv_text_left || TO_CHAR(id_arrival_date,'YYYY/MM/DD')  || cv_text_right
                               , 1, 5000);
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      IF cur_order_line%ISOPEN THEN
        CLOSE cur_order_line;
      END IF;
--
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
--#####################################  固定部 END   ##########################################
--
  END update_order_unit_price;
--
END xxpo_common2_pkg;
/
