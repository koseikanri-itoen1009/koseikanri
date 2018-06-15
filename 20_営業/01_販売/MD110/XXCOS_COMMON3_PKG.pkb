CREATE OR REPLACE PACKAGE BODY XXCOS_COMMON3_PKG
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2018. All rights reserved.
 *
 * Package Name     : XXCOS_COMMON3_PKG(body)
 * Description      : 共通関数パッケージ3(販売)
 * MD.070           : 共通関数    MD070_IPO_COS
 * Version          : 1.1
 *
 * Program List
 * --------------------------- ------ ---------- -----------------------------------------
 *  Name                        Type   Return     Description
 * --------------------------- ------ ---------- -----------------------------------------
 *  process_order               P                 oe_order_pubの実行
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2018/04/18    1.0   H.Sasaki         新規作成
 *  2018/06/11    1.1   H.Sasaki         販売単価が初期化されないよう対応[E_本稼動_14886]
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
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name               CONSTANT VARCHAR2(100)  :=  'XXCOS_COMMON3_PKG';                --  パッケージ名
  --  アプリケーション短縮名
  cv_appl_short_name_xxcos  CONSTANT VARCHAR2(5)    :=  'XXCOS';                            --  アドオン：販物・販売OM領域
  --  メッセージ名
  cv_msg_name_xxcos11202    CONSTANT VARCHAR2(30)   :=  'APP-XXCOS1-11202';                 --  ヘッダID必須エラー
  cv_msg_name_xxcos11203    CONSTANT VARCHAR2(30)   :=  'APP-XXCOS1-11203';                 --  納品予定日必須エラー
  cv_msg_name_xxcos11204    CONSTANT VARCHAR2(30)   :=  'APP-XXCOS1-11204';                 --  明細情報必須エラー
  cv_msg_name_xxcos11223    CONSTANT VARCHAR2(30)   :=  'APP-XXCOS1-11223';                 --  必須フラグ設定エラー
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
--
  /**********************************************************************************
   * Procedure Name   : process_order
   * Description      : oe_order_pubの実行
   ***********************************************************************************/
  PROCEDURE process_order(
      iv_upd_status_booked    IN  VARCHAR2                                              --  ステータス更新フラグ（記帳）
    , iv_upd_request_date     IN  VARCHAR2                                              --  着日更新フラグ
--  2018/06/12 V1.1 Added START
    , iv_upd_item_code        IN  VARCHAR2                                              --  品目更新フラグ
--  2018/06/12 V1.1 Added END
    , it_header_id            IN  oe_order_headers_all.header_id%TYPE                   --  ヘッダID
    , it_line_id              IN  oe_order_lines_all.line_id%TYPE                       --  明細ID                          #必須#
    , it_inventory_item_id    IN  oe_order_lines_all.inventory_item_id%TYPE             --  品目ID                          #必須#
    , it_ordered_quantity     IN  oe_order_lines_all.ordered_quantity%TYPE              --  受注数量                        #必須#
    , it_reason_code          IN  oe_reasons.reason_code%TYPE                           --  事由コード
    , it_request_date         IN  oe_order_lines_all.request_date%TYPE                  --  納品予定日(着日)
    , it_subinv_code          IN  oe_order_lines_all.subinventory%TYPE                  --  保管場所                        #必須#
    , ov_errbuf               OUT NOCOPY VARCHAR2                                       --  エラー・メッセージエラー        #固定#
    , ov_retcode              OUT NOCOPY VARCHAR2                                       --  リターン・コード                #固定#
    , ov_errmsg               OUT NOCOPY VARCHAR2                                       --  ユーザー・エラー・メッセージ    #固定#
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'process_order'; -- プログラム名
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
    cv_separate                         CONSTANT VARCHAR2(1)  :=  '/';  --  エラーメッセージ生成用
    cv_encoded                          CONSTANT VARCHAR2(1)  :=  'F';  --  エラーメッセージ生成用
    -- *** ローカル変数 ***
    --  API用変数
    lv_return_status                    VARCHAR2(1);                    --  APIの終了ステータス
    ln_msg_count                        NUMBER  := 0;                   --  APIのエラーメッセージ件数
    lv_msg_data                         VARCHAR2(2000);                 --  APIのエラーメッセージ
    lv_out_message                      VARCHAR2(4000);                 --  OUT用のメッセージ
    lr_header_rec                       oe_order_pub.header_rec_type;   --  oe_order_pub用変数
    lt_line_tbl                         oe_order_pub.line_tbl_type;     --  oe_order_pub用変数
    lt_action_request_tbl               oe_order_pub.request_tbl_type;  --  oe_order_pub用変数
--  2018/06/12 V1.1 Added START
    lt_line_adj_tbl                     oe_order_pub.line_adj_tbl_type; --  oe_order_pub用変数
    lt_unit_selling_price               oe_order_lines_all.unit_selling_price%TYPE;       --  販売単価
    lt_calculate_price_flag             oe_order_lines_all.calculate_price_flag%TYPE;     --  価格計算フラグ
--  2018/06/12 V1.1 Added END
    --  APIのOUT用変数（戻り値の受けにのみ使用）
    lt_out_header_rec                   oe_order_pub.header_rec_type;
    lt_out_header_val_rec               oe_order_pub.header_val_rec_type;
    lt_out_header_adj_tbl               oe_order_pub.header_adj_tbl_type;
    lt_out_header_adj_val_tbl           oe_order_pub.header_adj_val_tbl_type;
    lt_out_header_price_att_tbl         oe_order_pub.header_price_att_tbl_type;
    lt_out_header_adj_att_tbl           oe_order_pub.header_adj_att_tbl_type;
    lt_out_header_adj_assoc_tbl         oe_order_pub.header_adj_assoc_tbl_type;
    lt_out_header_scredit_tbl           oe_order_pub.header_scredit_tbl_type;
    lt_out_header_scredit_val_tbl       oe_order_pub.header_scredit_val_tbl_type;
    lt_out_line_tbl                     oe_order_pub.line_tbl_type;
    lt_out_line_val_tbl                 oe_order_pub.line_val_tbl_type;
    lt_out_line_adj_tbl                 oe_order_pub.line_adj_tbl_type;
    lt_out_line_adj_val_tbl             oe_order_pub.line_adj_val_tbl_type;
    lt_out_line_price_att_tbl           oe_order_pub.line_price_att_tbl_type;
    lt_out_line_adj_att_tbl             oe_order_pub.line_adj_att_tbl_type;
    lt_out_line_adj_assoc_tbl           oe_order_pub.line_adj_assoc_tbl_type;
    lt_out_line_scredit_tbl             oe_order_pub.line_scredit_tbl_type;
    lt_out_line_scredit_val_tbl         oe_order_pub.line_scredit_val_tbl_type;
    lt_out_lot_serial_tbl               oe_order_pub.lot_serial_tbl_type;
    lt_out_lot_serial_val_tbl           oe_order_pub.lot_serial_val_tbl_type;
    lt_out_action_request_tbl           oe_order_pub.request_tbl_type;
    -- *** ローカル・カーソル ***
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    --==============================================================
    --  パラメータチェック
    --==============================================================
    IF  ( NVL( iv_upd_status_booked, '*' ) NOT IN( 'Y', 'N' )
          OR
          NVL( iv_upd_request_date,  '*' ) NOT IN( 'Y', 'N' )
        )
    THEN
      --  ステータス更新フラグと着日更新フラグは、必須でYまたはNのみ可
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                        iv_application  =>  cv_appl_short_name_xxcos
                      , iv_name         =>  cv_msg_name_xxcos11223
                    );
      lv_errbuf :=  lv_errmsg;
      RAISE global_api_expt;
    END IF;
    --
    IF  ( ( iv_upd_status_booked = 'Y'
            OR
            iv_upd_request_date  = 'Y'
          )
          AND it_header_id          IS NULL   --  ヘッダID
        )
    THEN
      --  ステータス更新フラグY, または 着日更新フラグY の場合、ヘッダID必須
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                        iv_application  =>  cv_appl_short_name_xxcos
                      , iv_name         =>  cv_msg_name_xxcos11202
                    );
      lv_errbuf :=  lv_errmsg;
      RAISE global_api_expt;
    END IF;
    --
    IF  (     iv_upd_request_date = 'Y'
          AND it_request_date       IS NULL   --  納品予定日
        )
    THEN
      --  着日更新フラグY の場合、納品予定日（着日）必須
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                        iv_application  =>  cv_appl_short_name_xxcos
                      , iv_name         =>  cv_msg_name_xxcos11203
                    );
      lv_errbuf :=  lv_errmsg;
      RAISE global_api_expt;
    END IF;
    --
    IF  ( iv_upd_status_booked = 'N'
          AND
          (     it_line_id            IS NULL   --  明細ID
            OR  it_inventory_item_id  IS NULL   --  品目ID
            OR  it_ordered_quantity   IS NULL   --  受注数量
            OR  it_subinv_code        IS NULL   --  保管場所
          )
        )
    THEN
      --  ステータス更新フラグNの場合、明細関連のパラメータは設定必須
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                        iv_application  =>  cv_appl_short_name_xxcos
                      , iv_name         =>  cv_msg_name_xxcos11204
                    );
      lv_errbuf :=  lv_errmsg;
      RAISE global_api_expt;
    END IF;
    --
    --==============================================================
    --  受注更新処理
    --==============================================================
    --  初期化
    lv_errbuf                   :=  NULL;
    lv_errmsg                   :=  NULL;
    OE_MSG_PUB.INITIALIZE;
    --
    IF ( iv_upd_status_booked = 'Y' ) THEN
      --  ステータス更新フラグYの場合、記帳処理のみを実施
      --  本処理で記帳可能かの判定は行いません。呼び出し元でのチェック必須
      lt_action_request_tbl(1)                :=  OE_ORDER_PUB.G_MISS_REQUEST_REC;
      lt_action_request_tbl(1).entity_code    :=  OE_GLOBALS.G_ENTITY_HEADER;
      lt_action_request_tbl(1).request_type   :=  OE_GLOBALS.G_BOOK_ORDER;
      lt_action_request_tbl(1).entity_id      :=  it_header_id;
      --  更新処理実行
      oe_order_pub.process_order(
          p_api_version_number            =>  1.0
        , x_return_status                 =>  lv_return_status
        , x_msg_count                     =>  ln_msg_count
        , x_msg_data                      =>  lv_msg_data
        , p_header_rec                    =>  lr_header_rec                   --  ヘッダ情報
        , p_line_tbl                      =>  lt_line_tbl                     --  明細情報
        , p_action_request_tbl            =>  lt_action_request_tbl           --  アクションリクエスト
        , x_header_rec                    =>  lt_out_header_rec
        , x_header_val_rec                =>  lt_out_header_val_rec
        , x_header_adj_tbl                =>  lt_out_header_adj_tbl
        , x_header_adj_val_tbl            =>  lt_out_header_adj_val_tbl
        , x_header_price_att_tbl          =>  lt_out_header_price_att_tbl
        , x_header_adj_att_tbl            =>  lt_out_header_adj_att_tbl
        , x_header_adj_assoc_tbl          =>  lt_out_header_adj_assoc_tbl
        , x_header_scredit_tbl            =>  lt_out_header_scredit_tbl
        , x_header_scredit_val_tbl        =>  lt_out_header_scredit_val_tbl
        , x_line_tbl                      =>  lt_out_line_tbl
        , x_line_val_tbl                  =>  lt_out_line_val_tbl
        , x_line_adj_tbl                  =>  lt_out_line_adj_tbl
        , x_line_adj_val_tbl              =>  lt_out_line_adj_val_tbl
        , x_line_price_att_tbl            =>  lt_out_line_price_att_tbl
        , x_line_adj_att_tbl              =>  lt_out_line_adj_att_tbl
        , x_line_adj_assoc_tbl            =>  lt_out_line_adj_assoc_tbl
        , x_line_scredit_tbl              =>  lt_out_line_scredit_tbl
        , x_line_scredit_val_tbl          =>  lt_out_line_scredit_val_tbl
        , x_lot_serial_tbl                =>  lt_out_lot_serial_tbl
        , x_lot_serial_val_tbl            =>  lt_out_lot_serial_val_tbl
        , x_action_request_tbl            =>  lt_out_action_request_tbl
      );
      --  実行結果判定
      IF ( lv_return_status <> FND_API.G_RET_STS_SUCCESS ) THEN
        --  ステータス正常以外の場合、メッセージを生成
        FOR ln_count IN 1 .. ln_msg_count LOOP
          lv_errmsg :=    lv_out_message
                      ||  cv_separate
                      ||  oe_msg_pub.get(
                              p_msg_index   =>  ln_count
                            , p_encoded     =>  cv_encoded
                          );
        END LOOP;
        --
        lv_errbuf :=  lv_errmsg;
        RAISE global_api_expt;
      END IF;
    ELSIF ( iv_upd_status_booked = 'N' ) THEN
      --  ステータス更新フラグNの場合、項目更新のみを実施（本機能コール1回に対し、明細1行のみ更新）
      --  本機能で更新可能かの判定は行いません。呼び出し元でのチェック必須
      lt_line_tbl(1)                      :=  OE_ORDER_PUB.G_MISS_LINE_REC;
      lt_line_tbl(1).operation            :=  OE_GLOBALS.G_OPR_UPDATE;      --  UPDATE
      lt_line_tbl(1).line_id              :=  it_line_id;                   --  明細ID
      lt_line_tbl(1).inventory_item_id    :=  it_inventory_item_id;         --  品目ID
      lt_line_tbl(1).ordered_item_id      :=  it_inventory_item_id;         --  受注品目ID
      lt_line_tbl(1).ordered_quantity     :=  it_ordered_quantity;          --  受注数量
      lt_line_tbl(1).subinventory         :=  it_subinv_code;               --  保管場所
      --  変更事由設定
      IF ( it_reason_code IS NOT NULL ) THEN
        lt_line_tbl(1).change_reason        :=  it_reason_code;               --  事由
      END IF;
      --  着日更新
      IF ( iv_upd_request_date = 'Y' ) THEN
        lr_header_rec               :=  OE_ORDER_PUB.G_MISS_HEADER_REC;
        lr_header_rec.operation     :=  OE_GLOBALS.G_OPR_UPDATE;
        lr_header_rec.header_id     :=  it_header_id;
        lr_header_rec.request_date  :=  it_request_date;                      --  ヘッダ着日
        lt_line_tbl(1).request_date :=  it_request_date;                      --  明細着日
      END IF;
      --
--  2018/06/12 V1.1 Added START
      --  単価自動更新制御
      IF ( iv_upd_item_code = 'Y' ) THEN
        --  品目更新を行う場合で、受注の価格計算フラグがNの場合、制御を実施
        BEGIN
          SELECT  oola.unit_selling_price
                , oola.calculate_price_flag
          INTO    lt_unit_selling_price           --  販売単価
                , lt_calculate_price_flag         --  価格計算フラグ
          FROM    oe_order_lines_all      oola
          WHERE   oola.line_id    =   it_line_id
          ;
        END;
        IF ( lt_calculate_price_flag = 'N' ) THEN
          --  価格計算フラグがNの場合実施
          --  ORDER LINE
          lt_line_tbl(1).calculate_price_flag     :=  'Y';
          --  PRICE ADJUSTMENT
          lt_line_adj_tbl(1)                      :=  OE_ORDER_PUB.G_MISS_LINE_ADJ_REC;
          lt_line_adj_tbl(1).operation            :=  OE_GLOBALS.G_OPR_CREATE;
          lt_line_adj_tbl(1).automatic_flag       :=  'N';
          lt_line_adj_tbl(1).line_index           :=  1;
          lt_line_adj_tbl(1).arithmetic_operator  :=  'NEWPRICE';
          lt_line_adj_tbl(1).applied_flag         :=  'Y';
          lt_line_adj_tbl(1).modifier_level_code  :=  'LINE';
          lt_line_adj_tbl(1).updated_flag         :=  'Y';
          lt_line_adj_tbl(1).operand              :=  lt_unit_selling_price;
          --
          BEGIN
            --  手動モディファイア
            SELECT  qmv.list_header_id
                  , qmv.list_line_id
                  , qmv.list_line_type_code
            INTO    lt_line_adj_tbl(1).list_header_id               --  リストヘッダID
                  , lt_line_adj_tbl(1).list_line_id                 --  リスト明細ID
                  , lt_line_adj_tbl(1).list_line_type_code          --  リスト明細タイプ
            FROM    qp_modifier_summary_v     qmv
                  , qp_secu_list_headers_vl   qhv
            WHERE   qmv.list_header_id  =   qhv.list_header_id
            AND     qhv.name            =   'XXOM_MOD1'
            ;
          END;
          --
        END IF;
      END IF;
--  2018/06/12 V1.1 Added END
      --  更新処理実行
      oe_order_pub.process_order(
          p_api_version_number            =>  1.0
        , x_return_status                 =>  lv_return_status
        , x_msg_count                     =>  ln_msg_count
        , x_msg_data                      =>  lv_msg_data
        , p_header_rec                    =>  lr_header_rec                   --  ヘッダ情報
        , p_line_tbl                      =>  lt_line_tbl                     --  明細情報
--  2018/06/12 V1.1 Added START
        , p_line_adj_tbl                  =>  lt_line_adj_tbl
--  2018/06/12 V1.1 Added END
        , x_header_rec                    =>  lt_out_header_rec
        , x_header_val_rec                =>  lt_out_header_val_rec
        , x_header_adj_tbl                =>  lt_out_header_adj_tbl
        , x_header_adj_val_tbl            =>  lt_out_header_adj_val_tbl
        , x_header_price_att_tbl          =>  lt_out_header_price_att_tbl
        , x_header_adj_att_tbl            =>  lt_out_header_adj_att_tbl
        , x_header_adj_assoc_tbl          =>  lt_out_header_adj_assoc_tbl
        , x_header_scredit_tbl            =>  lt_out_header_scredit_tbl
        , x_header_scredit_val_tbl        =>  lt_out_header_scredit_val_tbl
        , x_line_tbl                      =>  lt_out_line_tbl
        , x_line_val_tbl                  =>  lt_out_line_val_tbl
        , x_line_adj_tbl                  =>  lt_out_line_adj_tbl
        , x_line_adj_val_tbl              =>  lt_out_line_adj_val_tbl
        , x_line_price_att_tbl            =>  lt_out_line_price_att_tbl
        , x_line_adj_att_tbl              =>  lt_out_line_adj_att_tbl
        , x_line_adj_assoc_tbl            =>  lt_out_line_adj_assoc_tbl
        , x_line_scredit_tbl              =>  lt_out_line_scredit_tbl
        , x_line_scredit_val_tbl          =>  lt_out_line_scredit_val_tbl
        , x_lot_serial_tbl                =>  lt_out_lot_serial_tbl
        , x_lot_serial_val_tbl            =>  lt_out_lot_serial_val_tbl
        , x_action_request_tbl            =>  lt_out_action_request_tbl
      );
      --  実行結果判定
      IF ( lv_return_status <> FND_API.G_RET_STS_SUCCESS ) THEN
        --  ステータス正常以外の場合、メッセージを生成
        FOR ln_count IN 1 .. ln_msg_count LOOP
          lv_errmsg :=    lv_out_message
                      ||  cv_separate
                      ||  oe_msg_pub.get(
                              p_msg_index   =>  ln_count
                            , p_encoded     =>  cv_encoded
                          );
        END LOOP;
        --
        lv_errbuf :=  lv_errmsg;
        RAISE global_api_expt;
      END IF;
    END IF;
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
  END process_order;
--
END XXCOS_COMMON3_PKG;
/
