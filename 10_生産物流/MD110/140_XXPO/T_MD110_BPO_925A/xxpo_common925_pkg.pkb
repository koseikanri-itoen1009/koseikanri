CREATE OR REPLACE PACKAGE BODY xxpo_common925_pkg
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxpo_common925_pkg(body)
 * Description      : 共通関数
 * MD.050/070       : 支給指示からの発注自動作成 Issue1.0  (T_MD050_BPO_925)
 * Version          : 1.5
 *
 * Program List
 * -------------------------- ----------------------------------------------------------
 *  Name                       Description
 * -------------------------- ----------------------------------------------------------
 *  create_reserve_data       FUNCTION  : 引当情報作成処理
 *  prc_check_param_info      PROCEDURE : パラメータチェック(A-1)
 *  prc_get_order_info        PROCEDURE : 受注情報抽出(A-2)
 *  prc_get_vendor_info       PROCEDURE : 仕入先情報取得(A-3)
 *  prc_get_item_info         PROCEDURE : 品目情報取得(A-4)
 *  prc_get_price             PROCEDURE : 単価取得(A-6)
 *  prc_ins_interface_header  PROCEDURE : 発注ヘッダ登録(A-7)
 *  prc_ins_interface_lines   PROCEDURE : 発注(搬送)明細登録(A-8)
 *  prc_regist_all            PROCEDURE : 登録更新処理(A-9)
 *  prc_end                   PROCEDURE : 後処理(A-10)
 *  submain                   PROCEDURE : メイン処理プロシージャ
 *  auto_purchase_orders      PROCEDURE : 支給指示からの発注自動作成
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/03/12    1.0   M.Imazeki        新規作成
 *  2008/05/01    1.1   I.Higa           指摘事項修正
 *                                        ・PO_HEADERS_INTERFACEの設定値を変更
 *                                        ・PO_LINES_INTERFACEの設定値を変更
 *  2008/05/07    1.2   M.Imazeki        引当情報作成処理(create_reserve_data)追加
 *  2008/05/22    1.3   Y.Majikina       発注ヘッダのAttribute1に設定値を変更
 *                                       発注ヘッダ（アドオン）への登録を追加
 *  2008/06/16    1.4   I.Higa           指摘事項修正
 *                                        ・従業員番号の型をNUMBER型からTYPE型へ変更
 *                                        ・ヘッダ摘要に受注ヘッダアドオンの出荷指示を設定
 *  2008/07/03    1.5   I.Higa           入庫予定日(着荷予定日)を発注の納入日にしているが
 *                                       出庫予定日を発注の納入日とするように変更する。
 *
 *****************************************************************************************/
--
--#######################  固定グローバル定数宣言部 START   #######################
--
  gv_status_normal        CONSTANT VARCHAR2(1)  := '0' ;
  gv_status_error         CONSTANT VARCHAR2(1)  := '2' ;
  gv_msg_part             CONSTANT VARCHAR2(3)  := ' : ' ;
  gv_msg_cont             CONSTANT VARCHAR2(3)  := '.';
--
--################################  固定部 END   ###############################
--
--#######################  固定グローバル変数宣言部 START   #######################
--
--################################  固定部 END   ###############################
--
  -- ======================================================
  -- ユーザー宣言部
  -- ======================================================
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  gv_pkg_name             CONSTANT VARCHAR2(20) := 'xxpo_common925_pkg' ; --  パッケージ名
  gv_provision_request    CONSTANT VARCHAR2(1)  := '2' ;                  -- '支給依頼'
  gv_object               CONSTANT VARCHAR2(1)  := '1' ;                  -- '対象'
  gv_zero                 CONSTANT VARCHAR2(1)  := '0' ;                  -- 半角ゼロ文字列
  gv_received             CONSTANT VARCHAR2(2)  := '07' ;                 -- '受領済み'
  gv_attribute3           CONSTANT VARCHAR2(1)  := '3' ;                  -- 口銭区分
  gv_attribute6           CONSTANT VARCHAR2(1)  := '3' ;                  -- 賦課金区分
  gv_no                   CONSTANT VARCHAR2(3)  := 'N' ;                  -- NO
--
  ------------------------------
  -- エラーメッセージ関連
  ------------------------------
  gc_application_cmn      CONSTANT VARCHAR2(5)  := 'XXCMN' ;           -- アプリケーション（XXCMN）
  gc_application_po       CONSTANT VARCHAR2(5)  := 'XXPO' ;            -- アプリケーション（XXPO）
--
  ------------------------------
  -- 項目編集関連
  ------------------------------
  gc_char_d_format        CONSTANT VARCHAR2(30) := 'YYYY/MM/DD' ;
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  -- 受注情報データ格納用レコード変数
  TYPE rec_order_info  IS RECORD(
      order_header_id       xxwsh_order_headers_all.order_header_id%TYPE         -- 受注ﾍｯﾀﾞｱﾄﾞｵﾝID
     ,shipping_instructions xxwsh_order_headers_all.shipping_instructions%TYPE    -- 出荷指示
     ,schedule_ship_date    xxwsh_order_headers_all.schedule_ship_date%TYPE       -- 出荷予定日
     ,deliver_from          xxwsh_order_headers_all.deliver_from%TYPE             -- 出荷元保管場所
     ,vendor_id             xxwsh_order_headers_all.vendor_id%TYPE                -- 取引先ID
     ,vendor_site_code      xxwsh_order_headers_all.vendor_site_code%TYPE         -- 取引先サイト
     ,shipping_inv_item_id  xxwsh_order_lines_all.shipping_inventory_item_id%TYPE -- 出荷品目ID
     ,shipping_item_code    xxwsh_order_lines_all.shipping_item_code%TYPE         -- 出荷品目
     ,quantity              xxwsh_order_lines_all.quantity%TYPE                   -- 数量
     ,futai_code            xxwsh_order_lines_all.futai_code%TYPE                 -- 付帯コード
     ,line_description      xxwsh_order_lines_all.line_description%TYPE           -- 摘要
     ) ;
--
  -- 仕入先情報格納用レコード変数
  TYPE rec_vendor_info  IS RECORD(
      vendor_site_id        po_vendor_sites_all.vendor_site_id%TYPE               -- 仕入先ｻｲﾄID
     ,vendor_site_code      po_vendor_sites_all.vendor_site_code%TYPE             -- 仕入先ｻｲﾄｺｰﾄﾞ
     ,vendor_id             xxcmn_vendors2_v.vendor_id%TYPE                       -- 仕入先ID
     ,department            xxcmn_vendors2_v.department%TYPE                      -- 部署
     ,location_id           hr_all_organization_units.location_id%TYPE            -- 納入先事業所
     ,mtl_organization_id   xxcmn_item_locations_v.mtl_organization_id%TYPE       -- 在庫組織ID
    ) ;
--
  -- 品目情報格納用レコード変数
  TYPE rec_item_info  IS RECORD(
      item_no               xxcmn_item_mst_v.item_no%TYPE                         -- 品目コード
     ,frequent_qty          xxcmn_item_mst_v.frequent_qty%TYPE                    -- 代表在庫入数
     ,item_um               xxcmn_item_mst_v.item_um%TYPE                         -- 単位
     ,lot_ctl               xxcmn_item_mst_v.lot_ctl%TYPE                         -- ロット
    ) ;
--
  -- 発注ヘッダオープンインターフェース登録用レコード変数
  TYPE rec_po_headers_if  IS RECORD(
      if_header_id         po_headers_interface.interface_header_id%TYPE          -- ｲﾝﾀｰﾌｪｲｽﾍｯﾀﾞID
     ,batch_id             po_headers_interface.batch_id%TYPE                     -- バッチID
     ,document_num         po_headers_interface.document_num%TYPE                 -- 発注番号
     ,agent_id             po_headers_interface.agent_id%TYPE                     -- 購買担当者ID
     ,vendor_id            po_headers_interface.vendor_id%TYPE                    -- 仕入先ID
     ,vendor_site_id       po_headers_interface.vendor_site_id%TYPE               -- 仕入先サイトID
     ,ship_to_location_id  po_headers_interface.ship_to_location_id%TYPE          -- 納入先事業所ID
     ,bill_to_location_id  po_headers_interface.bill_to_location_id%TYPE          -- 請求先事業所ID
     ,delivery_date        po_headers_interface.attribute4%TYPE                   -- 納入日
     ,delivery_to_code     po_headers_interface.attribute5%TYPE                   -- 納入先コード
     ,shipping_to_code     po_headers_interface.attribute7%TYPE                   -- 配送先コード
     ,dept_code            po_headers_interface.attribute10%TYPE                  -- 部署コード
     ,header_descript      po_headers_interface.attribute10%TYPE                  -- ヘッダ摘要
    ) ;
--
  -- 発注ヘッダアドオン登録用レコード変数
  TYPE rec_xxpo_headers_if  IS RECORD(
      xxpo_header_id   xxpo_headers_all.xxpo_header_id%TYPE          -- 発注ヘッダ(アドオンID)
  ) ;
--
  -- 受注情報データ格納用PL/SQL表型
  TYPE tab_order_info     IS TABLE OF rec_order_info    INDEX BY BINARY_INTEGER ;
--
  -- 発注明細オープンインターフェース登録用PL/SQL表型
  TYPE if_line_id_ttype       IS TABLE OF   po_lines_interface.interface_line_id%TYPE
                                              INDEX BY BINARY_INTEGER;            -- ｲﾝﾀｰﾌｪｲｽ明細ID
  TYPE line_num_ttype         IS TABLE OF   po_lines_interface.line_num%TYPE
                                              INDEX BY BINARY_INTEGER;            -- 明細番号
  TYPE item_ttype             IS TABLE OF   po_lines_interface.item%TYPE
                                              INDEX BY BINARY_INTEGER;            -- 品目
  TYPE unit_price_ttype       IS TABLE OF   po_lines_interface.unit_price%TYPE
                                              INDEX BY BINARY_INTEGER;            -- 単価
  TYPE quantity_ttype         IS TABLE OF   po_lines_interface.quantity%TYPE
                                              INDEX BY BINARY_INTEGER;            -- 数量
  TYPE uom_code_ttype         IS TABLE OF   po_lines_interface.uom_code%TYPE
                                              INDEX BY BINARY_INTEGER;            -- 単位
  TYPE factory_code_ttype     IS TABLE OF   po_lines_interface.line_attribute2%TYPE
                                              INDEX BY BINARY_INTEGER;            -- 工場コード
  TYPE futai_code_ttype       IS TABLE OF   po_lines_interface.line_attribute3%TYPE
                                              INDEX BY BINARY_INTEGER;            -- 付帯コード
  TYPE frequent_qty_ttype     IS TABLE OF   po_lines_interface.line_attribute4%TYPE
                                              INDEX BY BINARY_INTEGER;            -- 在庫入数
  TYPE stocking_price_ttype   IS TABLE OF   po_lines_interface.line_attribute8%TYPE
                                              INDEX BY BINARY_INTEGER;            -- 仕入定価
  TYPE order_unit_ttype       IS TABLE OF   po_lines_interface.line_attribute10%TYPE
                                              INDEX BY BINARY_INTEGER;            -- 発注単位
  TYPE order_quantity_ttype   IS TABLE OF   po_lines_interface.line_attribute11%TYPE
                                              INDEX BY BINARY_INTEGER;            -- 発注数量
  TYPE ship_to_org_id_ttype   IS TABLE OF   po_lines_interface.ship_to_organization_id%TYPE
                                              INDEX BY BINARY_INTEGER;            -- 納入先組織ID
  TYPE line_description_ttype IS TABLE OF   po_lines_interface.line_attribute15%TYPE
                                              INDEX BY BINARY_INTEGER;            -- 摘要
  TYPE attribute2_ttype IS TABLE OF   po_lines_interface.shipment_attribute2%TYPE
                                              INDEX BY BINARY_INTEGER;            -- 粉引後単価
  TYPE attribute9_ttype IS TABLE OF   po_lines_interface.shipment_attribute9%TYPE
                                              INDEX BY BINARY_INTEGER;            -- 粉引後金額
--
  -- 搬送明細オープンインターフェース登録用PL/SQL表型
  TYPE if_distribute_id_ttype IS TABLE OF po_distributions_interface.interface_distribution_id%TYPE
                                              INDEX BY BINARY_INTEGER;        -- ｲﾝﾀｰﾌｪｲｽ搬送明細ID
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
--
  -- 発注明細オープンインターフェース登録用PL/SQL表
  tab_if_line_id_ins                        if_line_id_ttype;                     -- ｲﾝﾀｰﾌｪｲｽ明細ID
  tab_line_num_ins                          line_num_ttype;                       -- 明細番号
  tab_item_ins                              item_ttype;                           -- 品目
  tab_unit_price_ins                        unit_price_ttype;                     -- 単価
  tab_quantity_ins                          quantity_ttype;                       -- 数量
  tab_uom_code_ins                          uom_code_ttype;                       -- 単位
  tab_factory_code_ins                      factory_code_ttype;                   -- 工場コード
  tab_futai_code_ins                        futai_code_ttype;                     -- 付帯コード
  tab_frequent_qty_ins                      frequent_qty_ttype;                   -- 在庫入数
  tab_stocking_price_ins                    stocking_price_ttype;                 -- 仕入定価
  tab_order_unit_ins                        order_unit_ttype;                     -- 発注単位
  tab_order_quantity_ins                    order_quantity_ttype;                 -- 発注数量
  tab_ship_to_org_id_ins                    ship_to_org_id_ttype;                 -- 納入先組織ID
  tab_line_description_ins                  line_description_ttype;               -- 摘要
  tab_attribute2_ins                        attribute2_ttype;                     -- 粉引後単価
  tab_attribute9_ins                        attribute9_ttype;                     -- 粉引後金額
--
  -- 搬送明細オープンインターフェース登録用PL/SQL表
  tab_if_distribute_id_ins                  if_distribute_id_ttype;           -- ｲﾝﾀｰﾌｪｲｽ搬送明細ID
--
  gv_request_no       xxwsh_order_headers_all.request_no%TYPE ;               -- 依頼No
  gi_cnt              PLS_INTEGER ;                                           -- ループカウント
--
  -- ログインユーザ従業員情報
  gn_emp_id           xxpo_per_all_people_f_v.person_id%TYPE DEFAULT FND_GLOBAL.EMPLOYEE_ID;
  -- ＷＨＯカラム情報
    -- 作成者ID
  gn_user_id          po_headers_interface.created_by%TYPE DEFAULT FND_GLOBAL.USER_ID;
    -- ログインID
  gn_login_id         po_headers_interface.last_update_login%TYPE DEFAULT FND_GLOBAL.LOGIN_ID;
    -- 要求ID
  gn_request_id       po_headers_interface.request_id%TYPE DEFAULT FND_GLOBAL.CONC_REQUEST_ID;
    -- アプリケーションID
  gn_prog_appl_id po_headers_interface.program_application_id%TYPE DEFAULT FND_GLOBAL.PROG_APPL_ID;
    -- プログラムID
  gn_conc_program_id  po_headers_interface.program_id%TYPE DEFAULT FND_GLOBAL.CONC_PROGRAM_ID;
--
  -- システム日時
  gd_sysdate          DATE DEFAULT SYSDATE;                                   -- システム日時
--
    -- 明細タイプID
  gn_line_type_id  po_lines_interface.line_type_id%TYPE;
    -- 営業担当ID
  gn_org_id        po_headers_interface.org_id%TYPE;
  -- ========================================
  -- グローバル・カーソル （ロック用カーソル)
  -- ========================================
  CURSOR cur_order_info(
      iv_request_no       xxwsh_order_headers_all.request_no%TYPE
    )
  IS
    SELECT xoha.order_header_id             AS  order_header_id           -- 受注ヘッダアドオンID
          ,xoha.shipping_instructions       AS  shipping_instructions     -- 出荷指示
          ,xoha.schedule_ship_date          AS  schedule_ship_date        -- 出荷予定日
          ,xoha.deliver_from                AS  deliver_from              -- 出荷元保管場所
          ,xoha.vendor_id                   AS  vendor_id                 -- 取引先ID
          ,xoha.vendor_site_code            AS  vendor_site_code          -- 取引先サイト
          ,xola.shipping_inventory_item_id  AS  shipping_inv_item_id      -- 出荷品目ID
          ,xola.shipping_item_code          AS  shipping_item_code        -- 出荷品目
          ,xola.quantity                    AS  quantity                  -- 数量
          ,NVL(xola.futai_code, gv_zero)    AS  futai_code                -- 付帯コード
          ,xola.line_description            AS  line_description          -- 摘要
    FROM   xxwsh_order_headers_all    xoha                                -- 受注ヘッダアドオン
          ,xxwsh_order_lines_all      xola                                -- 受注明細アドオン
          ,oe_transaction_types_all   otta                                -- 受注タイプ
    WHERE  xoha.order_type_id       = otta.transaction_type_id            -- 受注タイプID
    AND    otta.attribute1          = gv_provision_request                -- 出荷支給区分
    AND    otta.attribute3          = gv_object                           -- 自動発注作成区分
    AND    xoha.req_status          = gv_received                         -- ステータス
    AND    xoha.request_no          = iv_request_no                       -- 依頼No
    AND    xoha.order_header_id     = xola.order_header_id                -- 受注ヘッダアドオンID
    ORDER BY xola.order_line_number                                       -- 明細番号
    FOR UPDATE NOWAIT
  ;
--
--#####################  固定共通例外宣言部 START   ####################
--
  --*** 処理部共通例外 ***
  global_process_expt       EXCEPTION ;
  --*** 共通関数例外 ***
  global_api_expt           EXCEPTION ;
  --*** 共通関数OTHERS例外 ***
  global_api_others_expt    EXCEPTION ;
--
  PRAGMA EXCEPTION_INIT(global_api_others_expt,-20000) ;
--
--###########################  固定部 END   ############################
--
  -- ===============================
  -- ユーザー定義例外
  -- ===============================
  lock_expt              EXCEPTION;        -- ロック取得例外
--
  PRAGMA EXCEPTION_INIT(lock_expt, -54);   -- ロック取得例外
--
   /**********************************************************************************
   * Function Name    : create_reserve_data
   * Description      : 引当情報作成処理
   ***********************************************************************************/
  FUNCTION create_reserve_data(
       in_order_header_id    IN  NUMBER         -- 受注ヘッダアドオンID
   )
  RETURN NUMBER
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name       CONSTANT VARCHAR2(100) := 'create_reserve_data';      --プログラム名
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル・定数 ***
    cv_doc_type_code  CONSTANT  xxinv_mov_lot_details.document_type_code%TYPE := '30';  -- 支給指示
    cv_rec_type_code  CONSTANT  xxinv_mov_lot_details.record_type_code%TYPE   := '10';  -- 指示
--
  BEGIN
    -- ===============================
    -- 移動ロット詳細登録
    -- ===============================
    -- パラメータの受注ヘッダに紐づく受注明細ごとに移動ロット詳細へレコードタイプ「10：指示」
    -- のデータを登録する。
    INSERT INTO xxinv_mov_lot_details                                       -- 移動ロット詳細
              ( mov_lot_dtl_id                                              -- ロット詳細ID
               ,mov_line_id                                                 -- 明細ID
               ,document_type_code                                          -- 文書タイプ
               ,record_type_code                                            -- レコードタイプ
               ,item_id                                                     -- OPM品目ID
               ,item_code                                                   -- 品目
               ,lot_id                                                      -- ロットID
               ,lot_no                                                      -- ロットNo
               ,actual_date                                                 -- 実績日
               ,actual_quantity                                             -- 実績数量
               ,created_by                                                  -- 作成者
               ,creation_date                                               -- 作成日
               ,last_updated_by                                             -- 最終更新者
               ,last_update_date                                            -- 最終更新日
               ,last_update_login )                                         -- 最終更新ログイン
        SELECT  xxinv_mov_lot_s1.NEXTVAL                                    -- 移動ロット詳細識別用
               ,xola.order_line_id                                          -- 受注明細アドオンID
               ,cv_doc_type_code                                            -- 文書タイプ:支給指示
               ,cv_rec_type_code                                            -- レコードタイプ:指示
               ,xitm.item_id                                                -- OPM品目ID
               ,xitm.item_no                                                -- 品目
               ,opml.lot_id                                                 -- ロットID
               ,NULL                                                        -- ロットNo
               ,NULL                                                        -- 実績日
               ,xola.quantity                                               -- 実績数量
               ,gn_user_id                                                  -- 作成者
               ,gd_sysdate                                                  -- 作成日
               ,gn_user_id                                                  -- 最終更新者
               ,gd_sysdate                                                  -- 最終更新日
               ,gn_login_id                                                 -- 最終更新ログイン
        FROM    xxwsh_order_headers_all   xoha                              -- 受注ヘッダアドオン
               ,xxwsh_order_lines_all     xola                              -- 受注明細アドオン
               ,xxcmn_item_mst_v          xitm                              -- OPM品目情報VIEW
               ,ic_lots_mst               opml                              -- OPMロットマスタ
        WHERE   xoha.order_header_id    = in_order_header_id                -- 受注ヘッダアドオンID
        AND     xola.order_header_id    = xoha.order_header_id              -- 受注ヘッダアドオンID
        AND     xitm.inventory_item_id  = xola.shipping_inventory_item_id   -- INV品目ID
        AND     opml.item_id            = xitm.item_id                      -- 品目ID
    ;
--
    -- ===============================
    -- 受注明細アドオン更新
    -- ===============================
    -- パラメータの受注ヘッダアドオンIDに紐付く受注明細アドオンの引当数を指示数で更新する。
    UPDATE xxwsh_order_lines_all          xola                            -- 受注明細アドオン
    SET    xola.reserved_quantity       = xola.quantity                   -- 引当数に指示数をセット
          ,xola.last_updated_by         = gn_user_id                      -- 最終更新者
          ,xola.last_update_date        = gd_sysdate                      -- 最終更新日
          ,xola.last_update_login       = gn_login_id                     -- 最終更新ログイン
    WHERE  xola.order_header_id         = in_order_header_id              -- 受注ヘッダアドオンID
    AND    NVL(xola.delete_flag, gv_no) = gv_no                           -- 削除フラグOFF
    ;
--
    --ステータスセット
    RETURN gv_status_normal;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
      RETURN gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END create_reserve_data;
--
  /**********************************************************************************
   * Procedure Name   : prc_check_param_info
   * Description      : パラメータチェック(A-1)
   ***********************************************************************************/
  PROCEDURE prc_check_param_info(
      iv_request_no         IN          VARCHAR2         -- 依頼No
     ,ov_retcode            OUT         VARCHAR2         -- リターン・コード
     ,ov_errmsg_code        OUT         VARCHAR2         -- エラー・メッセージ・コード
     ,ov_errmsg             OUT         VARCHAR2         -- ユーザー・エラー・メッセージ
    )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_param_info' ; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル変数 ***
    ln_ret_num                NUMBER ;        -- 共通関数戻り値：数値型
    lv_err_code               VARCHAR2(20) ;  -- エラーコード格納用
    lv_token_value1           VARCHAR2(20) ;  -- トークン格納用
--
    -- *** ローカル定数 ***
    cv_request_no             CONSTANT VARCHAR2(20) := '依頼No' ;     -- 依頼No
--
    -- *** ローカル・例外処理 ***
    parameter_check_expt      EXCEPTION ;     -- パラメータチェック例外
--
  BEGIN
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ====================================================
    -- 依頼No
    -- ====================================================
    -- 必須チェック
    IF (iv_request_no IS NULL) THEN
      lv_err_code     := 'APP-XXPO-10102' ;
      lv_token_value1 := cv_request_no ;
      RAISE parameter_check_expt ;
    END IF ;
--
    -- 明細タイプID取得
    gn_line_type_id       := FND_PROFILE.VALUE( 'XXPO_PO_LINE_TYPE_ID' ) ;
    -- 営業担当ID
    gn_org_id             := FND_PROFILE.VALUE( 'ORG_ID' ) ;
--
  EXCEPTION
    --*** パラメータチェック例外 ***
    WHEN parameter_check_expt THEN
      ov_retcode      :=  gv_status_error;
      -- メッセージセット
      lv_errmsg       :=  xxcmn_common_pkg.get_msg(
                            iv_application   => gc_application_po,
                            iv_name          => lv_err_code,
                            iv_token_name1   => 'PARAM_NAME',
                            iv_token_value1  => lv_token_value1);     -- メッセージ取得
      ov_errmsg       :=  lv_errmsg;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_retcode      :=  gv_status_error;
      ov_errmsg       :=  lv_errmsg;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_retcode      :=  gv_status_error ;
      ov_errmsg_code  :=  SQLCODE ;
      ov_errmsg       :=  SQLERRM ;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_retcode      :=  gv_status_error ;
      ov_errmsg_code  :=  SQLCODE ;
      ov_errmsg       :=  SQLERRM ;
--
--#####################################  固定部 END   ##########################################
--
  END prc_check_param_info ;
--
  /**********************************************************************************
   * Procedure Name   : prc_get_order_info
   * Description      : 受注情報抽出取得(A-2)
   ***********************************************************************************/
  PROCEDURE prc_get_order_info(
      ot_data_rec           OUT         tab_order_info   -- 取得レコード群
     ,ov_retcode            OUT         VARCHAR2         -- リターン・コード
     ,ov_errmsg_code        OUT         VARCHAR2         -- エラー・メッセージ・コード
     ,ov_errmsg             OUT         VARCHAR2         -- ユーザー・エラー・メッセージ
    )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_get_order_info'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル・定数 ***
    cv_xoha                 CONSTANT VARCHAR2(20) := '受注ヘッダアドオン' ;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ====================================================
    -- データ抽出
    -- ====================================================
    -- カーソルオープン
    OPEN cur_order_info(
      gv_request_no) ;               -- 依頼No
    -- バルクフェッチ
    FETCH cur_order_info BULK COLLECT INTO ot_data_rec ;
--
    IF ( ot_data_rec.COUNT = 0 ) THEN       -- 取得データが０件の場合
      lv_errmsg  := xxcmn_common_pkg.get_msg(
                          iv_application   => gc_application_po,
                          iv_name          => 'APP-XXPO-10026',
                          iv_token_name1   => 'TABLE',
                          iv_token_value1  => cv_xoha);         -- メッセージ取得
      ov_errmsg  := lv_errmsg ;
      ov_retcode := gv_status_error ;
    END IF ;
--
  EXCEPTION
     --*** ロック取得エラー ***
    WHEN lock_expt THEN
      IF (cur_order_info%ISOPEN) THEN
        CLOSE cur_order_info ;
      END IF ;
      lv_errmsg := xxcmn_common_pkg.get_msg(
                          iv_application   => gc_application_po,
                          iv_name          => 'APP-XXPO-10027',
                          iv_token_name1   => 'TABLE',
                          iv_token_value1  => cv_xoha);         -- メッセージ取得
      ov_errmsg  := lv_errmsg ;
      ov_retcode := gv_status_error ;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      IF (cur_order_info%ISOPEN) THEN
        CLOSE cur_order_info ;
      END IF ;
      ov_retcode      :=  gv_status_error;
      ov_errmsg       :=  lv_errmsg;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      IF (cur_order_info%ISOPEN) THEN
        CLOSE cur_order_info ;
      END IF ;
      ov_retcode      :=  gv_status_error ;
      ov_errmsg_code  :=  SQLCODE ;
      ov_errmsg       :=  SQLERRM ;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      IF (cur_order_info%ISOPEN) THEN
        CLOSE cur_order_info ;
      END IF ;
      ov_retcode      :=  gv_status_error ;
      ov_errmsg_code  :=  SQLCODE ;
      ov_errmsg       :=  SQLERRM ;
--
--#####################################  固定部 END   ##########################################
--
  END prc_get_order_info ;
--
  /**********************************************************************************
   * Procedure Name   : prc_get_vendor_info
   * Description      : 仕入先情報取得(A-3)
   ***********************************************************************************/
  PROCEDURE prc_get_vendor_info(
      ir_order_info         IN          rec_order_info   -- 受注情報レコード
     ,or_vendor_info        OUT         rec_vendor_info  -- 仕入先情報レコード
     ,ov_retcode            OUT         VARCHAR2         -- リターン・コード
     ,ov_errmsg_code        OUT         VARCHAR2         -- エラー・メッセージ・コード
     ,ov_errmsg             OUT         VARCHAR2         -- ユーザー・エラー・メッセージ
    )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_get_vendor_info'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル・定数 ***
    cv_po_vendor_sites_all   CONSTANT VARCHAR2(20) := '仕入先サイトマスタ' ;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    SELECT pvsa.vendor_site_id        AS  vendor_site_id                    -- 仕入先サイトID
          ,pvsa.vendor_site_code      AS  vendor_site_code                  -- 仕入先サイトコード
          ,xv2v.vendor_id             AS  vendor_id                         -- 仕入先ID
          ,xv2v.department            AS  department                        -- 部署
          ,xilv.location_id           AS  location_id                       -- 納入先事業所
          ,xilv.mtl_organization_id   AS  mtl_organization_id               -- 在庫組織ID
    INTO   or_vendor_info.vendor_site_id
          ,or_vendor_info.vendor_site_code
          ,or_vendor_info.vendor_id
          ,or_vendor_info.department
          ,or_vendor_info.location_id
          ,or_vendor_info.mtl_organization_id
    FROM   po_vendor_sites_all            pvsa                              -- 仕入先サイトマスタ
          ,xxcmn_vendors2_v               xv2v                              -- 仕入先情報VIEW2
          ,xxcmn_item_locations_v         xilv                              -- OPM保管場所情報VIEW
    WHERE  xilv.segment1                = ir_order_info.deliver_from        -- 保管倉庫コード
    AND    xilv.purchase_code           = xv2v.segment1                     -- 仕入先コード
    AND  ((xilv.purchase_site_code IS NOT NULL
      AND  xilv.purchase_site_code      = pvsa.vendor_site_code)            -- 仕入先サイトコード
    OR    (xilv.purchase_site_code IS NULL
      AND  xv2v.frequent_factory        = pvsa.vendor_site_code))           -- 仕入先サイトコード
    AND    xv2v.vendor_id               = pvsa.vendor_id                    -- 仕入先ID
    AND    xv2v.inactive_date IS NULL                                       -- 無効日
    AND   (ir_order_info.schedule_ship_date                                 -- 出荷予定日
             BETWEEN  xv2v.start_date_active  AND  xv2v.end_date_active)    -- 適用開始・終了日
    ;
--
  EXCEPTION
    -- *** 取得データ０件 ***
    WHEN NO_DATA_FOUND THEN
      ov_retcode      :=  gv_status_error;
      lv_errmsg       :=  xxcmn_common_pkg.get_msg(
                            iv_application   => gc_application_po,
                            iv_name          => 'APP-XXPO-10026',
                            iv_token_name1   => 'TABLE',
                            iv_token_value1  => cv_po_vendor_sites_all);    -- メッセージ取得
      ov_errmsg       :=  lv_errmsg;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_retcode      :=  gv_status_error;
      ov_errmsg       :=  lv_errmsg;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_retcode      :=  gv_status_error ;
      ov_errmsg_code  :=  SQLCODE ;
      ov_errmsg       :=  SQLERRM ;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_retcode      :=  gv_status_error ;
      ov_errmsg_code  :=  SQLCODE ;
      ov_errmsg       :=  SQLERRM ;
--
--#####################################  固定部 END   ##########################################
--
  END prc_get_vendor_info ;
--
  /**********************************************************************************
   * Procedure Name   : prc_get_item_info
   * Description      : 品目情報取得(A-4)
   ***********************************************************************************/
  PROCEDURE prc_get_item_info(
      ir_order_info         IN          rec_order_info   -- 受注情報レコード
     ,or_item_info          OUT         rec_item_info    -- 品目情報レコード
     ,ov_retcode            OUT         VARCHAR2         -- リターン・コード
     ,ov_errmsg_code        OUT         VARCHAR2         -- エラー・メッセージ・コード
     ,ov_errmsg             OUT         VARCHAR2         -- ユーザー・エラー・メッセージ
    )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_get_item_info'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル・定数 ***
    cv_system_items_b       CONSTANT VARCHAR2(20) := '品目マスタ' ;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    SELECT ximv.item_no               AS  item_no                             -- 品目コード
          ,ximv.frequent_qty          AS  frequent_qty                        -- 代表在庫入数
          ,ximv.item_um               AS  item_um                             -- 単位
          ,ximv.lot_ctl               AS  lot_ctl                             -- ロット
    INTO   or_item_info.item_no
          ,or_item_info.frequent_qty
          ,or_item_info.item_um
          ,or_item_info.lot_ctl
    FROM   xxcmn_item_mst_v           ximv                                    -- OPM品目情報VIEW
    WHERE  ximv.inventory_item_id   = ir_order_info.shipping_inv_item_id      -- 出荷品目ID
    ;
--
  EXCEPTION
    -- *** 取得データ０件 ***
    WHEN NO_DATA_FOUND THEN
      ov_retcode      :=  gv_status_error;
      lv_errmsg       :=  xxcmn_common_pkg.get_msg(
                            iv_application   => gc_application_po,
                            iv_name          => 'APP-XXPO-10026',
                            iv_token_name1   => 'TABLE',
                            iv_token_value1  => cv_system_items_b);           -- メッセージ取得
      ov_errmsg       :=  lv_errmsg;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_retcode      :=  gv_status_error;
      ov_errmsg       :=  lv_errmsg;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_retcode      :=  gv_status_error ;
      ov_errmsg_code  :=  SQLCODE ;
      ov_errmsg       :=  SQLERRM ;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_retcode      :=  gv_status_error ;
      ov_errmsg_code  :=  SQLCODE ;
      ov_errmsg       :=  SQLERRM ;
--
--#####################################  固定部 END   ##########################################
--
  END prc_get_item_info ;
--
  /**********************************************************************************
   * Procedure Name   : prc_get_price
   * Description      : 単価取得(A-6)
   ***********************************************************************************/
  PROCEDURE prc_get_price(
      ir_order_info       IN          rec_order_info                          -- 受注情報レコード
     ,ir_vendor_info      IN          rec_vendor_info                         -- 仕入先情報レコード
     ,on_total_amount     OUT         XXPO_PRICE_HEADERS.total_amount%TYPE    -- 内訳合計
     ,ov_retcode          OUT         VARCHAR2                                -- リターン・コード
     ,ov_errmsg_code      OUT         VARCHAR2                                -- ｴﾗｰ・ﾒｯｾｰｼﾞ・ｺｰﾄﾞ
     ,ov_errmsg           OUT         VARCHAR2                                -- エラー・メッセージ
    )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_get_price'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル・定数 ***
    cv_price_headers        CONSTANT VARCHAR2(20) := '仕入/標準単価ヘッダ' ;
    cv_price_type           CONSTANT VARCHAR2(1)  := '1' ;                   -- 仕入単価データ
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    SELECT xph.total_amount                AS  total_amount                  -- 内訳合計
    INTO   on_total_amount
    FROM   xxpo_price_headers              xph                               -- 仕入/標準単価ヘッダ
    WHERE  xph.price_type               =  cv_price_type                     -- 仕入単価データ
    AND    xph.item_code                =  ir_order_info.shipping_item_code  -- 品目コード=出荷品目
    AND    NVL(xph.futai_code, gv_zero) =  ir_order_info.futai_code          -- 付帯コード
    AND    xph.vendor_id                =  ir_vendor_info.vendor_id          -- 取引先ID=仕入先ID
    AND    xph.factory_id               =  ir_vendor_info.vendor_site_id     -- 工場ID=仕入先ｻｲﾄID
    AND    xph.supply_to_id             =  ir_order_info.vendor_id           -- 支給先ID=取引先ID
    AND   (ir_order_info.schedule_ship_date                                  -- 出荷予定日
             BETWEEN  xph.start_date_active  AND  xph.end_date_active)       -- 適用開始・終了日
    ;
--
  EXCEPTION
    -- *** 取得データ０件 ***
    WHEN NO_DATA_FOUND THEN
      ov_retcode      :=  gv_status_error;
      lv_errmsg       :=  xxcmn_common_pkg.get_msg(
                            iv_application   => gc_application_po,
                            iv_name          => 'APP-XXPO-10026',
                            iv_token_name1   => 'TABLE',
                            iv_token_value1  => cv_price_headers);           -- メッセージ取得
      ov_errmsg       :=  lv_errmsg;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_retcode      :=  gv_status_error;
      ov_errmsg       :=  lv_errmsg;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_retcode      :=  gv_status_error ;
      ov_errmsg_code  :=  SQLCODE ;
      ov_errmsg       :=  SQLERRM ;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_retcode      :=  gv_status_error ;
      ov_errmsg_code  :=  SQLCODE ;
      ov_errmsg       :=  SQLERRM ;
--
--#####################################  固定部 END   ##########################################
--
  END prc_get_price ;
--
  /**********************************************************************************
   * Procedure Name   : prc_ins_interface_header
   * Description      : 発注ヘッダ登録(A-7)
   ***********************************************************************************/
  PROCEDURE prc_ins_interface_header(
      ir_order_info      IN       rec_order_info    -- 受注情報レコード
     ,ir_vendor_info     IN       rec_vendor_info   -- 仕入先情報レコード
     ,or_po_headers_if   OUT      rec_po_headers_if -- 発注ヘッダオープンインターフェースレコード
     ,or_xxpo_headers_if OUT      rec_xxpo_headers_if  -- 発注ヘッダアドオンレコード
     ,ov_retcode         OUT      VARCHAR2          -- リターン・コード
     ,ov_errmsg_code     OUT      VARCHAR2          -- エラー・メッセージ・コード
     ,ov_errmsg          OUT      VARCHAR2          -- ユーザー・エラー・メッセージ
    )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_ins_interface_header'; -- プログラム名
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
    -- *** ローカル・定数 ***
    cv_po_headers_interface CONSTANT VARCHAR2(30) := '発注ヘッダインターフェースID' ;
    cv_xxpo_headers_id      CONSTANT VARCHAR2(30) := '発注ヘッダ(アドオンID)';
    cv_po_no                CONSTANT VARCHAR2(10) := '発注番号' ;
    cv_seq_class            CONSTANT VARCHAR2(2)  := '2'; -- 発番区分：発注番号(xxcmn_order_no_s1)
    cv_agent_id             CONSTANT VARCHAR2(20) := '購買担当者ID';
--
    -- *** ローカル・変数 ***
    lv_agent_id             fnd_profile_option_values.profile_option_value%TYPE ; -- 購買担当者ID
--
    -- *** ローカル・例外処理 ***
    get_user_error_expt       EXCEPTION ;  -- 採番エラー・プロファイル取得エラー
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ==============================================================
    -- 発注ヘッダインタフェースシーケンスから値を取得
    -- ==============================================================
    BEGIN
      SELECT po_headers_interface_s.NEXTVAL
      INTO or_po_headers_if.if_header_id                                   -- ｲﾝﾀｰﾌｪｲｽﾍｯﾀﾞID
      FROM dual;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(
                          iv_application   => gc_application_cmn,
                          iv_name          => 'APP-XXCMN-10029',
                          iv_token_name1   => 'SEQ_NAME',
                          iv_token_value1  => cv_po_headers_interface);    -- メッセージ取得
        RAISE get_user_error_expt;
    END;
--
    -- ==============================================================
    -- 発注ヘッダ（アドオン）シーケンスから値を取得
    -- ==============================================================
    BEGIN
      SELECT xxpo_headers_all_s1.NEXTVAL
      INTO or_xxpo_headers_if.xxpo_header_id               -- 発注アドオンID
      FROM dual;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(
                          iv_application   => gc_application_cmn,
                          iv_name          => 'APP-XXCMN-10029',
                          iv_token_name1   => 'SEQ_NAME',
                          iv_token_value1  => cv_xxpo_headers_id); -- メッセージ取得
        RAISE get_user_error_expt;
    END;
--
    -- ==============================================================
    -- 発注番号を取得(採番関数)
    -- ==============================================================
    xxcmn_common_pkg.get_seq_no(
        iv_seq_class      => cv_seq_class                   -- 採番する番号を表す区分
       ,ov_seq_no         => or_po_headers_if.document_num  -- 発注番号(採番した固定長12桁の番号)
       ,ov_errbuf         => lv_errbuf                      -- エラー・メッセージ
       ,ov_retcode        => lv_retcode                     -- リターン・コード
       ,ov_errmsg         => lv_errmsg                      -- ユーザー・エラー・メッセージ
      ) ;
    IF (lv_retcode = gv_status_error OR or_po_headers_if.document_num IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(
                        iv_application   => gc_application_cmn,
                        iv_name          => 'APP-XXCMN-10029',
                        iv_token_name1   => 'SEQ_NAME',
                        iv_token_value1  => cv_po_no);                     -- メッセージ取得
      RAISE get_user_error_expt;
    END IF ;
--
    -- ====================================================
    -- 購買担当者ID
    -- ====================================================
    lv_agent_id       := FND_PROFILE.VALUE( 'XXPO_PURCHASE_EMP_ID' ) ;
    IF ( lv_agent_id IS NULL ) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(
      iv_application   => gc_application_cmn,
        iv_name          => 'APP-XXCMN-10002',
        iv_token_name1   => 'NG_PROFILE',
        iv_token_value1  => cv_agent_id);                                  -- メッセージ取得
      RAISE get_user_error_expt;
    END IF ;
--
    -- ==============================================================
    -- 発注ヘッダインターフェイス登録データ作成
    -- ==============================================================
    or_po_headers_if.batch_id   :=  TO_NUMBER(TO_CHAR(or_po_headers_if.if_header_id)
                                 || TO_CHAR(or_po_headers_if.document_num));      -- バッチID
    or_po_headers_if.agent_id         :=  TO_NUMBER(lv_agent_id);                 -- 購買担当者ID
    or_po_headers_if.vendor_id        :=  ir_vendor_info.vendor_id;               -- 仕入先ID
    or_po_headers_if.vendor_site_id   :=  ir_vendor_info.vendor_site_id;          -- 仕入先サイトID
    or_po_headers_if.ship_to_location_id  :=  ir_vendor_info.location_id;         -- 納入先事業所ID
    or_po_headers_if.bill_to_location_id  :=  ir_vendor_info.location_id;         -- 請求先事業所ID
    or_po_headers_if.delivery_date    :=  ir_order_info.schedule_ship_date;       -- 出荷予定日
    or_po_headers_if.delivery_to_code :=  ir_order_info.deliver_from;             -- 出荷元保管場所
    or_po_headers_if.shipping_to_code :=  ir_order_info.vendor_site_code;         -- 取引先サイト
    or_po_headers_if.dept_code        :=  ir_vendor_info.department;              -- 部署コード
    or_po_headers_if.header_descript  :=  ir_order_info.shipping_instructions;    -- ヘッダ摘要
--
  EXCEPTION
    --*** 採番エラー・プロファイル取得エラー ***
    WHEN get_user_error_expt THEN
      -- メッセージセット
      ov_retcode      :=  gv_status_error;
      ov_errmsg       :=  lv_errmsg;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_retcode      :=  gv_status_error;
      ov_errmsg       :=  lv_errmsg;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_retcode      :=  gv_status_error ;
      ov_errmsg_code  :=  SQLCODE ;
      ov_errmsg       :=  SQLERRM ;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_retcode      :=  gv_status_error ;
      ov_errmsg_code  :=  SQLCODE ;
      ov_errmsg       :=  SQLERRM ;
--
--#####################################  固定部 END   ##########################################
--
  END prc_ins_interface_header ;
--
  /**********************************************************************************
   * Procedure Name   : prc_ins_interface_lines
   * Description      : 発注(搬送)明細登録(A-8)
   ***********************************************************************************/
  PROCEDURE prc_ins_interface_lines(
      ir_order_info         IN          rec_order_info                        -- 受注情報レコード
     ,ir_vendor_info        IN          rec_vendor_info                       -- 仕入先情報レコード
     ,ir_item_info          IN          rec_item_info                         -- 品目情報レコード
     ,in_total_amount       IN          XXPO_PRICE_HEADERS.total_amount%TYPE  -- 内訳合計
     ,ov_retcode            OUT         VARCHAR2                              -- リターン・コード
     ,ov_errmsg_code        OUT         VARCHAR2                              -- ｴﾗｰ・ﾒｯｾｰｼﾞ・ｺｰﾄﾞ
     ,ov_errmsg             OUT         VARCHAR2                              -- エラー・メッセージ
    )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_ins_interface_lines'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル・定数 ***
    cv_po_lines_interface         CONSTANT VARCHAR2(30) := '発注明細インターフェースID' ;
    cv_po_distributions_interface CONSTANT VARCHAR2(30) := '搬送明細インターフェースID' ;
--
    -- *** ローカル・例外処理 ***
    get_sequence_expt      EXCEPTION ;     -- 採番エラー
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ==============================================================
    -- 発注明細インタフェースシーケンスから値を取得
    -- ==============================================================
    BEGIN
      SELECT po_lines_interface_s.NEXTVAL
      INTO tab_if_line_id_ins(gi_cnt)                                         -- ｲﾝﾀｰﾌｪｲｽ明細ID
      FROM dual;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(
                          iv_application   => gc_application_cmn,
                          iv_name          => 'APP-XXCMN-10029',
                          iv_token_name1   => 'SEQ_NAME',
                          iv_token_value1  => cv_po_lines_interface);         -- メッセージ取得
        RAISE get_sequence_expt;
    END;
--
    -- ==============================================================
    -- 発注明細インターフェイス登録データ作成
    -- ==============================================================
    tab_line_num_ins(gi_cnt)          :=  gi_cnt;                             -- 明細番号
    tab_item_ins(gi_cnt)              :=  ir_item_info.item_no;               -- 品目
    tab_unit_price_ins(gi_cnt)        :=  in_total_amount;                    -- 単価
    tab_quantity_ins(gi_cnt)          :=  ir_order_info.quantity;             -- 数量
    tab_uom_code_ins(gi_cnt)          :=  ir_item_info.item_um;               -- 単位
    tab_factory_code_ins(gi_cnt)      :=  ir_vendor_info.vendor_site_code;    -- 工場コード
    tab_futai_code_ins(gi_cnt)        :=  ir_order_info.futai_code;           -- 付帯コード
    tab_frequent_qty_ins(gi_cnt)      :=  ir_item_info.frequent_qty;          -- 在庫入数
    tab_stocking_price_ins(gi_cnt)    :=  in_total_amount;                    -- 仕入定価
    tab_order_unit_ins(gi_cnt)        :=  ir_item_info.item_um;               -- 発注単位
    tab_order_quantity_ins(gi_cnt)    :=  ir_order_info.quantity;             -- 発注数量
    tab_ship_to_org_id_ins(gi_cnt)    :=  ir_vendor_info.mtl_organization_id; -- 納入先組織ID
    tab_line_description_ins(gi_cnt)  :=  ir_order_info.line_description;     -- 摘要
    tab_attribute2_ins(gi_cnt)        :=  in_total_amount;                    -- 粉引後単価
    tab_attribute9_ins(gi_cnt)        :=  in_total_amount * ir_order_info.quantity;   -- 粉引後金額
--
    -- ==============================================================
    -- 搬送明細インタフェースシーケンスから値を取得
    -- ==============================================================
    BEGIN
      SELECT po_distributions_interface_s.NEXTVAL
      INTO tab_if_distribute_id_ins(gi_cnt)                                   -- ｲﾝﾀｰﾌｪｲｽ搬送明細ID
      FROM dual;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(
                          iv_application   => gc_application_cmn,
                          iv_name          => 'APP-XXCMN-10029',
                          iv_token_name1   => 'SEQ_NAME',
                          iv_token_value1  => cv_po_distributions_interface); -- メッセージ取得
        RAISE get_sequence_expt;
    END;
--
  EXCEPTION
    --*** 採番エラー ***
    WHEN get_sequence_expt THEN
      -- メッセージセット
      ov_retcode      :=  gv_status_error;
      ov_errmsg       :=  lv_errmsg;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_retcode      :=  gv_status_error;
      ov_errmsg       :=  lv_errmsg;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_retcode      :=  gv_status_error ;
      ov_errmsg_code  :=  SQLCODE ;
      ov_errmsg       :=  SQLERRM ;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_retcode      :=  gv_status_error ;
      ov_errmsg_code  :=  SQLCODE ;
      ov_errmsg       :=  SQLERRM ;
--
--#####################################  固定部 END   ##########################################
--
  END prc_ins_interface_lines ;
--
  /**********************************************************************************
   * Procedure Name   : prc_regist_all
   * Description      : 登録更新処理(A-9)
   ***********************************************************************************/
  PROCEDURE prc_regist_all(
      ir_po_headers_if      IN  rec_po_headers_if     -- 発注ヘッダオープンインターフェースレコード
     ,ir_xxpo_headers_if    IN  rec_xxpo_headers_if
     ,in_order_header_id    IN  xxwsh_order_headers_all.order_header_id%TYPE     -- 受注ﾍｯﾀﾞｱﾄﾞｵﾝID
     ,ov_retcode            OUT VARCHAR2              -- リターン・コード
     ,ov_errmsg_code        OUT VARCHAR2              -- エラー・メッセージ・コード
     ,ov_errmsg             OUT VARCHAR2              -- ユーザー・エラー・メッセージ
    )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_regist_all'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_retcode    VARCHAR2(1);     -- リターン・コード
    lv_errmsg     VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル・定数 ***
    cv_process_code   CONSTANT po_headers_interface.process_code%TYPE    := 'PENDING';  -- 処理ｺｰﾄﾞ
    cv_action         CONSTANT po_headers_interface.action%TYPE          := 'ORIGINAL'; -- 処理区分
    cv_standard    CONSTANT po_headers_interface.document_type_code%TYPE := 'STANDARD'; -- 標準発注
    cv_approval_sts   CONSTANT po_headers_interface.approval_status%TYPE := 'APPROVED';-- 承認ｽﾃｰﾀｽ
    cv_po_add_status  CONSTANT po_headers_interface.attribute1%TYPE    := '20';-- ｽﾃｰﾀｽ(発注作成済)
    cv_drop_ship_type CONSTANT po_headers_interface.attribute6%TYPE    := '3'; -- 直送区分(支給)
    cv_po_type        CONSTANT po_headers_interface.attribute11%TYPE   := '1'; -- 発注区分(新規)
    cn_recovery_rate  CONSTANT po_distributions_interface.recovery_rate%TYPE := 100;
--
    -- *** ローカル・変数 ***
    cn_emp_num        per_all_people_f.employee_number%TYPE;
    li_cnt            PLS_INTEGER ;                                      -- ループカウント
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ==============================
    -- ログインユーザ情報取得
    -- ==============================
    BEGIN
      SELECT  xpav.employee_number
        INTO  cn_emp_num
        FROM  xxpo_per_all_people_f_v  xpav
       WHERE  person_id = gn_emp_id;
    EXCEPTION
      WHEN OTHERS THEN
        RAISE;
    END;
--
    -- ==============================================================
    -- 発注ヘッダインタフェースに追加
    -- ==============================================================
    BEGIN
      INSERT INTO po_headers_interface(
        interface_header_id,                                      -- インターフェースヘッダID
        batch_id,                                                 -- バッチID
        process_code,                                             -- 処理コード
        action,                                                   -- 処理区分
        org_id,                                                   -- 営業担当ID
        document_type_code,                                       -- 文書タイプコード
        document_num,                                             -- 文書番号(発注番号)
        agent_id,                                                 -- 購買担当者ID
        vendor_id,                                                -- 仕入先ID
        vendor_site_id,                                           -- 仕入先サイトID
        ship_to_location_id,                                      -- 納入先事業所ID
        bill_to_location_id,                                      -- 請求先事業所ID
        approval_status,                                          -- 承認ステータス
        attribute1,                                               -- ステータス
        attribute2,                                               -- 仕入先承諾要フラグ
        attribute4,                                               -- 納入日
        attribute5,                                               -- 納入先コード
        attribute6,                                               -- 直送区分
        attribute7,                                               -- 配送先コード
        attribute9,                                               -- 依頼番号
        attribute10,                                              -- 部署コード
        attribute11,                                              -- 発注区分
        attribute15,                                              -- ヘッダ摘要
        creation_date,                                            -- 作成日
        created_by,                                               -- 作成者ID
        last_update_date,                                         -- 最終更新日
        last_updated_by,                                          -- 最終更新者ID
        last_update_login,                                        -- 最終更新ログインID
        request_id,                                               -- 要求ID
        program_application_id,                                   -- プログラムアプリケーションID
        program_id,                                               -- プログラムID
        program_update_date,                                      -- プログラム更新日
        load_sourcing_rules_flag
        )
      VALUES
        (
        ir_po_headers_if.if_header_id,                            -- インターフェースヘッダID
        ir_po_headers_if.batch_id,                                -- バッチID
        cv_process_code,                                          -- 処理コード
        cv_action,                                                -- 処理区分
        gn_org_id,                                                -- 営業担当ID
        cv_standard,                                              -- 文書タイプコード
        ir_po_headers_if.document_num,                            -- 文書番号(発注番号)
        ir_po_headers_if.agent_id,                                -- 購買担当者ID
        ir_po_headers_if.vendor_id,                               -- 仕入先ID
        ir_po_headers_if.vendor_site_id,                          -- 仕入先サイトID
        ir_po_headers_if.ship_to_location_id,                     -- 納入先事業所ID
        ir_po_headers_if.bill_to_location_id,                     -- 請求先事業所ID
        cv_approval_sts,                                          -- 承認ステータス
        cv_po_add_status,                                         -- ステータス
        gv_no,                                                    -- 仕入先承諾要フラグ
        ir_po_headers_if.delivery_date,                           -- 納入日
        ir_po_headers_if.delivery_to_code,                        -- 納入先コード
        cv_drop_ship_type,                                        -- 直送区分
        ir_po_headers_if.shipping_to_code,                        -- 配送先コード
        gv_request_no,                                            -- 依頼番号
        ir_po_headers_if.dept_code,                               -- 部署コード
        cv_po_type,                                               -- 発注区分
        ir_po_headers_if.header_descript,                         -- ヘッダ摘要
        gd_sysdate,                                               -- 作成日
        gn_user_id,                                               -- 作成者ID
        gd_sysdate,                                               -- 最終更新日
        gn_user_id,                                               -- 最終更新者ID
        gn_login_id,                                              -- 最終更新ログインID
        gn_request_id,                                            -- 要求ID
        gn_prog_appl_id,                                          -- プログラムアプリケーションID
        gn_conc_program_id,                                       -- プログラムID
        gd_sysdate,                                               -- プログラム更新日
        gv_no
        );
    EXCEPTION
      WHEN OTHERS THEN
        RAISE;
    END;
--
    -- ===============================
    -- 発注ヘッダアドオンに追加
    -- ===============================
    BEGIN
      INSERT INTO xxpo_headers_all(
          xxpo_header_id,                                           -- 発注ヘッダ(アドオンID)
          po_header_number,                                         -- 発注番号
          requested_by_code,                                        -- 依頼者コード
          requested_department_code,                                -- 依頼部署コード
          requested_date,                                           -- 依頼日
          order_created_by_code,                                    -- 作成者コード
          order_created_date,                                       -- 作成日
          order_approved_flg,                                       -- 発注承諾フラグ
          order_approved_by,                                        -- 発注承諾者ユーザーID
          order_approved_date,                                      -- 発注承諾日付
          purchase_approved_flg,                                    -- 仕入承諾フラグ
          purchase_approved_by,                                     -- 仕入承諾ユーザーID
          purchase_approved_date,                                   -- 仕入承諾日付
          creation_date,                                            -- 作成日
          created_by,                                               -- 作成者ID
          last_update_date,                                         -- 最終更新日
          last_updated_by,                                          -- 最終更新者ID
          last_update_login,                                        -- 最終更新ログインID
          request_id,                                               -- 要求ID
          program_application_id,                                   -- プログラムアプリケーションID
          program_id,                                               -- プログラムID
          program_update_date                                       -- プログラム更新日
          )
        VALUES
          (
          ir_xxpo_headers_if.xxpo_header_id,                        -- 発注ヘッダ(アドオンID)
          ir_po_headers_if.document_num,                            -- 発注番号
          NULL,                                                     -- 依頼者コード
          NULL,                                                     -- 依頼部署コード
          NULL,                                                     -- 依頼日
          cn_emp_num,                                               -- 作成者コード
          gd_sysdate,                                               -- 作成日
          gv_no,                                                    -- 発注承諾フラグ
          NULL,                                                     -- 発注承諾者ユーザーID
          NULL,                                                     -- 発注承諾日付
          gv_no,                                                    -- 仕入承諾フラグ
          NULL,                                                     -- 仕入承諾ユーザーID
          NULL,                                                     -- 仕入承諾日付
          gd_sysdate,                                               -- 作成日
          gn_user_id,                                               -- 作成者ID
          gd_sysdate,                                               -- 最終更新日
          gn_user_id,                                               -- 最終更新者ID
          gn_login_id,                                              -- 最終更新ログインID
          gn_request_id,                                            -- 要求ID
          gn_prog_appl_id,                                          -- プログラムアプリケーションID
          gn_conc_program_id,                                       -- プログラムID
          gd_sysdate                                                -- プログラム更新日
          );
    EXCEPTION
      WHEN OTHERS THEN
        RAISE;
    END;
--
    BEGIN
      -- ==============================================================
      -- 発注明細インタフェースに追加
      -- ==============================================================
      <<ins_po_lines_loop>>
      FORALL li_cnt IN 1 .. tab_if_line_id_ins.COUNT
        INSERT INTO po_lines_interface(
          interface_line_id,                                        -- インターフェース明細ID
          interface_header_id,                                      -- インターフェースヘッダID
          line_num,                                                 -- 明細番号
          shipment_num,                                             -- 納入明細番号
          line_type_id,                                             -- 明細タイプID
          item,                                                     -- 品目ID
          uom_code,                                                 -- 単位
          quantity,                                                 -- 数量
          unit_price,                                               -- 単価
          ship_to_organization_id,                                  -- 納入先組織ID
          promised_date,                                            -- 納期
          line_attribute2,                                          -- 工場コード
          line_attribute3,                                          -- 付帯コード
          line_attribute4,                                          -- 在庫入数
          line_attribute8,                                          -- 仕入定価
          line_attribute10,                                         -- 発注単位
          line_attribute11,                                         -- 発注数量
          line_attribute13,                                         -- 数量確定フラグ
          line_attribute14,                                         -- 金額確定フラグ
          line_attribute15,                                         -- 摘要
          shipment_attribute2,                                      -- 粉引後単価
          shipment_attribute3,                                      -- 口銭区分
          shipment_attribute6,                                      -- 賦課金区分
          shipment_attribute9,                                      -- 粉引後金額
          creation_date,                                            -- 作成日
          created_by,                                               -- 作成者ID
          last_update_date,                                         -- 最終更新日
          last_updated_by,                                          -- 最終更新者ID
          last_update_login,                                        -- 最終更新ログインID
          request_id,                                               -- 要求ID
          program_application_id,                                   -- プログラムアプリケーションID
          program_id,                                               -- プログラムID
          program_update_date                                       -- プログラム更新日
          )
        VALUES
          (
          tab_if_line_id_ins(li_cnt),                               -- インターフェース明細ID
          ir_po_headers_if.if_header_id,                            -- インターフェースヘッダID
          tab_line_num_ins(li_cnt),                                 -- 明細番号
          tab_line_num_ins(li_cnt),                                 -- 納入明細番号
          gn_line_type_id,                                          -- 明細タイプID
          tab_item_ins(li_cnt),                                     -- 品目
          tab_uom_code_ins(li_cnt),                                 -- 単位
          tab_quantity_ins(li_cnt),                                 -- 数量
          tab_unit_price_ins(li_cnt),                               -- 単価
          tab_ship_to_org_id_ins(li_cnt),                           -- 納入先組織ID
          ir_po_headers_if.delivery_date,                           -- 納期
          tab_factory_code_ins(li_cnt),                             -- 工場コード
          tab_futai_code_ins(li_cnt),                               -- 付帯コード
          tab_frequent_qty_ins(li_cnt),                             -- 在庫入数
          tab_stocking_price_ins(li_cnt),                           -- 仕入定価
          tab_order_unit_ins(li_cnt),                               -- 発注単位
          tab_order_quantity_ins(li_cnt),                           -- 発注数量
          gv_no,                                                    -- 数量確定フラグ
          gv_no,                                                    -- 金額確定フラグ
          tab_line_description_ins(li_cnt),                         -- 摘要
          tab_attribute2_ins(li_cnt),                               -- 粉引後単価
          gv_attribute3,                                            -- 口銭区分
          gv_attribute6,                                            -- 賦課金区分
          tab_attribute9_ins(li_cnt),                               -- 粉引後金額
          gd_sysdate,                                               -- 作成日
          gn_user_id,                                               -- 作成者ID
          gd_sysdate,                                               -- 最終更新日
          gn_user_id,                                               -- 最終更新者ID
          gn_login_id,                                              -- 最終更新ログインID
          gn_request_id,                                            -- 要求ID
          gn_prog_appl_id,                                          -- プログラムアプリケーションID
          gn_conc_program_id,                                       -- プログラムID
          gd_sysdate                                                -- プログラム更新日
          );
    EXCEPTION
      WHEN OTHERS THEN
        RAISE;
    END;
--
    -- ==============================================================
    -- 搬送明細インタフェースに追加
    -- ==============================================================
    BEGIN
      <<ins_po_distributions_loop>>
      FORALL li_cnt IN 1 .. tab_if_line_id_ins.COUNT
        INSERT INTO po_distributions_interface(
          interface_header_id,                                      -- インターフェースヘッダID
          interface_line_id,                                        -- インターフェース明細ID
          interface_distribution_id,                                -- インタフェース搬送明細ID
          distribution_num,                                         -- 搬送明細番号
          quantity_ordered,                                         -- 受注数量
          recovery_rate,                                            -- RECOVERY_RATE
          creation_date,                                            -- 作成日
          created_by,                                               -- 作成者ID
          last_update_date,                                         -- 最終更新日
          last_updated_by,                                          -- 最終更新者ID
          last_update_login,                                        -- 最終更新ログインID
          request_id,                                               -- 要求ID
          program_application_id,                                   -- プログラムアプリケーションID
          program_id,                                               -- プログラムID
          program_update_date                                       -- プログラム更新日
          )
        VALUES
          (
          ir_po_headers_if.if_header_id,                            -- インターフェースヘッダID
          tab_if_line_id_ins(li_cnt),                               -- インターフェース明細ID
          tab_if_distribute_id_ins(li_cnt),                         -- インタフェース搬送明細ID
          tab_line_num_ins(li_cnt),                                 -- 搬送明細番号
          tab_quantity_ins(li_cnt),                                 -- 受注数量
          cn_recovery_rate,                                         -- RECOVERY_RATE
          gd_sysdate,                                               -- 作成日
          gn_user_id,                                               -- 作成者ID
          gd_sysdate,                                               -- 最終更新日
          gn_user_id,                                               -- 最終更新者ID
          gn_login_id,                                              -- 最終更新ログインID
          gn_request_id,                                            -- 要求ID
          gn_prog_appl_id,                                          -- プログラムアプリケーションID
          gn_conc_program_id,                                       -- プログラムID
          gd_sysdate                                                -- プログラム更新日
          );
    EXCEPTION
      WHEN OTHERS THEN
        RAISE;
    END;
--
    -- ===============================
    -- 受注ヘッダアドオン更新処理
    -- ===============================
    BEGIN
      UPDATE xxwsh_order_headers_all       xoha                             -- 受注ヘッダアドオン
      SET   xoha.po_no                   = ir_po_headers_if.document_num    -- 発注No
           ,xoha.last_updated_by         = gn_user_id                       -- 最終更新者
           ,xoha.last_update_date        = gd_sysdate                       -- 最終更新日
           ,xoha.last_update_login       = gn_login_id                      -- 最終更新ログイン
           ,xoha.request_id              = gn_request_id                    -- 要求ID
           ,xoha.program_application_id  = gn_prog_appl_id                  -- ﾌﾟﾛｸﾞﾗﾑｱﾌﾟﾘｹｰｼｮﾝID
           ,xoha.program_id              = gn_conc_program_id               -- プログラムID
           ,xoha.program_update_date     = gd_sysdate                       -- プログラム更新日
      WHERE xoha.order_header_id         = in_order_header_id               -- 受注ヘッダアドオンID
      ;
    EXCEPTION
      WHEN OTHERS THEN
        RAISE;
    END;
--
    -- ===============================
    -- 引当情報作成処理
    -- ===============================
    IF (create_reserve_data(in_order_header_id) = gv_status_error) THEN
        RAISE global_api_others_expt;
    END IF;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_retcode      :=  gv_status_error;
      ov_errmsg       :=  lv_errmsg;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_retcode      :=  gv_status_error ;
      ov_errmsg_code  :=  SQLCODE ;
      ov_errmsg       :=  SQLERRM ;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_retcode      :=  gv_status_error ;
      ov_errmsg_code  :=  SQLCODE ;
      ov_errmsg       :=  SQLERRM ;
--
--#####################################  固定部 END   ##########################################
--
  END prc_regist_all ;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
      iv_request_no        IN          VARCHAR2         -- 01 : 依頼No
     ,ov_retcode           OUT         VARCHAR2         -- リターン・コード
     ,on_batch_id          OUT         NUMBER           -- バッチID
     ,ov_errmsg_code       OUT         VARCHAR2         -- エラー・メッセージ・コード
     ,ov_errmsg            OUT         VARCHAR2         -- ユーザー・エラー・メッセージ
    )
  IS
--
--#####################  固定ローカル定数変数宣言部 START   ####################
--
    -- ======================================================
    -- 固定ローカル定数
    -- ======================================================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'submain' ; -- プログラム名
    -- ======================================================
    -- ローカル変数
    -- ======================================================
    lv_retcode      VARCHAR2(1) ;                       --   リターン・コード
    lv_errmsg_code  VARCHAR2(5000) ;                    --   エラー・メッセージ・コード
    lv_errmsg       VARCHAR2(5000) ;                    --   ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ======================================================
    -- ユーザー宣言部
    -- ======================================================
    -- *** ローカル変数 ***
    lt_order_info           tab_order_info ;                        -- 受注情報取得レコード表
    lr_vendor_info          rec_vendor_info ;                       -- 仕入先情報レコード
    lr_item_info            rec_item_info ;                         -- 品目情報レコード
    lr_po_headers_if        rec_po_headers_if ;                     -- 発注ﾍｯﾀﾞｵｰﾌﾟﾝｲﾝﾀｰﾌｪｰｽﾚｺｰﾄﾞ
    lr_xxpo_headers_if      rec_xxpo_headers_if;
    ln_total_amount         XXPO_PRICE_HEADERS.total_amount%TYPE ;  -- 内訳合計
    ln_retcode              NUMBER ;
    li_cnt                  PLS_INTEGER ;                           -- ループカウント
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal ;
--
--###########################  固定部 END   ############################
--
    -- =====================================================
    -- パラメータチェック(A-1)
    -- =====================================================
    prc_check_param_info(
        iv_request_no       => iv_request_no      -- 依頼No
       ,ov_retcode          => lv_retcode         -- リターン・コード
       ,ov_errmsg_code      => lv_errmsg_code     -- エラー・メッセージ・コード
       ,ov_errmsg           => lv_errmsg          -- ユーザー・エラー・メッセージ
      ) ;
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt ;
    END IF ;
--
    -- パラメータ格納
    gv_request_no       := iv_request_no ;                                  -- 依頼No
--
    -- =====================================================
    -- 受注情報抽出(A-2)
    -- =====================================================
    prc_get_order_info(
        ot_data_rec       => lt_order_info        -- 取得レコード
       ,ov_retcode        => lv_retcode           -- リターン・コード
       ,ov_errmsg_code    => lv_errmsg_code       -- エラー・メッセージ・コード
       ,ov_errmsg         => lv_errmsg            -- ユーザー・エラー・メッセージ
      ) ;
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt ;
    END IF ;
--
    <<main_data_loop>>
    FOR li_cnt IN 1..lt_order_info.COUNT LOOP
      gi_cnt  :=  li_cnt;
--
      IF (li_cnt  = 1) THEN   -- 先頭レコード時のみ処理
        -- =====================================================
        -- 仕入先情報取得(A-3)
        -- =====================================================
        prc_get_vendor_info(
            ir_order_info     => lt_order_info(li_cnt)  -- 受注情報レコード
           ,or_vendor_info    => lr_vendor_info         -- 仕入先情報レコード
           ,ov_retcode        => lv_retcode             -- リターン・コード
           ,ov_errmsg_code    => lv_errmsg_code         -- エラー・メッセージ・コード
           ,ov_errmsg         => lv_errmsg              -- ユーザー・エラー・メッセージ
          ) ;
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_process_expt ;
        END IF ;
      END IF;
--
      -- =====================================================
      -- 品目情報取得(A-4)
      -- =====================================================
      prc_get_item_info(
          ir_order_info       => lt_order_info(li_cnt)  -- 受注情報レコード
         ,or_item_info        => lr_item_info           -- 品目情報レコード
         ,ov_retcode          => lv_retcode             -- リターン・コード
         ,ov_errmsg_code      => lv_errmsg_code         -- エラー・メッセージ・コード
         ,ov_errmsg           => lv_errmsg              -- ユーザー・エラー・メッセージ
        ) ;
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt ;
      END IF ;
--
      -- =====================================================
      -- ロット管理品目チェック(A-5)
      -- =====================================================
      IF (lr_item_info.lot_ctl != 0) THEN               -- ロットが有効の場合
        lv_errmsg  := xxcmn_common_pkg.get_msg(
                            iv_application   => gc_application_po,
                            iv_name          => 'APP-XXPO-10031');         -- メッセージ取得
        RAISE global_process_expt ;
      END IF ;
--
      -- =====================================================
      -- 単価取得(A-6)
      -- =====================================================
      prc_get_price(
          ir_order_info       => lt_order_info(li_cnt)  -- 受注情報レコード
         ,ir_vendor_info      => lr_vendor_info         -- 仕入先情報レコード
         ,on_total_amount     => ln_total_amount        -- 内訳合計
         ,ov_retcode          => lv_retcode             -- リターン・コード
         ,ov_errmsg_code      => lv_errmsg_code         -- エラー・メッセージ・コード
         ,ov_errmsg           => lv_errmsg              -- ユーザー・エラー・メッセージ
        ) ;
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt ;
      END IF ;
--
      IF (li_cnt  = 1) THEN   -- 先頭レコード時のみ処理
        -- =====================================================
        -- 発注ヘッダ登録(A-7)
        -- =====================================================
        prc_ins_interface_header(
            ir_order_info      => lt_order_info(li_cnt) -- 受注情報レコード
           ,ir_vendor_info     => lr_vendor_info        -- 仕入先情報レコード
           ,or_po_headers_if   => lr_po_headers_if    -- 発注ヘッダオープンインターフェースレコード
           ,or_xxpo_headers_if => lr_xxpo_headers_if
           ,ov_retcode         => lv_retcode            -- リターン・コード
           ,ov_errmsg_code     => lv_errmsg_code        -- エラー・メッセージ・コード
           ,ov_errmsg          => lv_errmsg             -- ユーザー・エラー・メッセージ
          ) ;
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_process_expt ;
        END IF ;
      END IF ;
--
      -- =====================================================
      -- 発注(搬送)明細登録(A-8)
      -- =====================================================
      prc_ins_interface_lines(
          ir_order_info      => lt_order_info(li_cnt) -- 受注情報レコード
         ,ir_vendor_info     => lr_vendor_info        -- 仕入先情報レコード
         ,ir_item_info       => lr_item_info          -- 品目情報レコード
         ,in_total_amount    => ln_total_amount       -- 内訳合計
         ,ov_retcode         => lv_retcode            -- リターン・コード
         ,ov_errmsg_code     => lv_errmsg_code        -- エラー・メッセージ・コード
         ,ov_errmsg          => lv_errmsg             -- ユーザー・エラー・メッセージ
        ) ;
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt ;
      END IF ;
--
    END LOOP main_data_loop ;
--
    -- =====================================================
    -- 登録更新処理(A-9)
    -- =====================================================
    prc_regist_all(
        ir_po_headers_if    => lr_po_headers_if                     -- 発注ﾍｯﾀﾞｵｰﾌﾟﾝｲﾝﾀｰﾌｪｰｽﾚｺｰﾄﾞ
       ,ir_xxpo_headers_if  => lr_xxpo_headers_if
       ,in_order_header_id  => lt_order_info(1).order_header_id     -- 受注ヘッダアドオンID
       ,ov_retcode          => lv_retcode                           -- リターン・コード
       ,ov_errmsg_code      => lv_errmsg_code                       -- エラー・メッセージ・コード
       ,ov_errmsg           => lv_errmsg                            -- ユーザー・エラー・メッセージ
      ) ;
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt ;
    END IF ;
--
    -- ==================================================
    -- 後処理(A-10)
    -- ==================================================
    on_batch_id   :=  lr_po_headers_if.batch_id ;                   -- バッチID
    ov_errmsg     :=  lv_errmsg ;
--
    -- ==================================================
    -- ロックカーソルをCLOSE
    -- ==================================================
    IF (cur_order_info%ISOPEN) THEN
      CLOSE cur_order_info ;
    END IF ;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ###################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      IF (cur_order_info%ISOPEN) THEN
        CLOSE cur_order_info ;
      END IF ;
    -- ==================================================
    -- 後処理(A-10)
    -- ==================================================
      ov_retcode      :=  gv_status_error ;
      on_batch_id     :=  lr_po_headers_if.batch_id ;               -- バッチID
      ov_errmsg       :=  lv_errmsg ;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      IF (cur_order_info%ISOPEN) THEN
        CLOSE cur_order_info ;
      END IF ;
      ov_retcode      :=  gv_status_error ;
      ov_errmsg_code  :=  SQLCODE ;
      ov_errmsg       :=  SQLERRM ;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      IF (cur_order_info%ISOPEN) THEN
        CLOSE cur_order_info ;
      END IF ;
      ov_retcode      :=  gv_status_error ;
      ov_errmsg_code  :=  SQLCODE ;
      ov_errmsg       :=  SQLERRM ;
--
--####################################  固定部 END   ##########################################
  END submain ;
--
  /**********************************************************************************
   * Procedure Name   : auto_purchase_orders
   * Description      : 支給指示からの発注自動作成
   **********************************************************************************/
--
  PROCEDURE auto_purchase_orders(
      iv_request_no         IN          VARCHAR2         -- 01 : 依頼No
     ,ov_retcode            OUT NOCOPY  VARCHAR2         -- リターン・コード
     ,on_batch_id           OUT NOCOPY  NUMBER           -- バッチID
     ,ov_errmsg_code        OUT NOCOPY  VARCHAR2         -- エラー・メッセージ・コード
     ,ov_errmsg             OUT NOCOPY  VARCHAR2         -- ユーザー・エラー・メッセージ
    )
--
--###########################  固定部 START   ###########################
--
  IS
--
    -- ======================================================
    -- 固定ローカル定数
    -- ======================================================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'auto_purchase_orders' ; -- プログラム名
    -- ======================================================
    -- ローカル変数
    -- ======================================================
    lv_retcode              VARCHAR2(1) ;         --   リターン・コード
    lv_errmsg               VARCHAR2(5000) ;      --   ユーザー・エラー・メッセージ
--
  BEGIN
--
--###########################  固定部 END   #############################
--
    -- ======================================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ======================================================
    submain(
        iv_request_no       => iv_request_no      -- 01 : 依頼No
       ,ov_retcode          => lv_retcode         -- リターン・コード
       ,on_batch_id         => on_batch_id        -- バッチID
       ,ov_errmsg_code      => ov_errmsg_code     -- エラー・メッセージ・コード
       ,ov_errmsg           => lv_errmsg          -- ユーザー・エラー・メッセージ
     ) ;
--
    -- ==================================================
    -- 終了ステータス設定
    -- ==================================================
    ov_retcode := lv_retcode ;
    ov_errmsg  := lv_errmsg ;
--
--###########################  固定部 START   #####################################################
--
  EXCEPTION
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_retcode      :=  gv_status_error ;
      ov_errmsg_code  :=  SQLCODE ;
      ov_errmsg       :=  SQLERRM ;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_retcode      :=  gv_status_error ;
      ov_errmsg_code  :=  SQLCODE ;
      ov_errmsg       :=  SQLERRM ;
  END auto_purchase_orders ;
--
--###########################  固定部 END   #######################################################
--
END xxpo_common925_pkg ;
/