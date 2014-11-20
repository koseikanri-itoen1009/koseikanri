CREATE OR REPLACE PACKAGE BODY xxwsh620007c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxwsh620007c(body)
 * Description      : 倉庫払出指示書（配送先明細）
 * MD.050           : 引当/配車(帳票) T_MD050_BPO_621
 * MD.070           : 倉庫払出指示書（配送先明細） T_MD070_BPO_62I
 * Version          : 1.4
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  fnc_chgdt_d            FUNCTION  : 日付型変換(YYYY/MM/DD形式の文字列 → 日付型)
 *  fnc_chgdt_c            FUNCTION  : 日付型変換(日付型 → YYYY/MM/DD形式の文字列)
 *  prc_set_tag_data       PROCEDURE : タグ情報設定処理
 *  prc_set_tag_data       PROCEDURE : タグ情報設定処理(開始・終了タグ用)
 *  prc_initialize         PROCEDURE : 初期処理
 *  prc_get_report_data    PROCEDURE : 帳票データ取得処理
 *  prc_create_xml_data    PROCEDURE : XML生成処理
 *  fnc_convert_into_xml   FUNCTION  : XMLデータ変換
 *  submain                PROCEDURE : メイン処理プロシージャ
 *  main                   PROCEDURE : コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ------------------ -----------------------------------------------
 *  Date          Ver.  Editor             Description
 * ------------- ----- ------------------ -----------------------------------------------
 *  2008/05/14    1.0   Nozomi Kashiwagi   新規作成
 *  2008/06/24    1.1   Masayoshi Uehara   支給の場合、パラメータ配送先/入庫先のリレーションを
 *                                         vendor_site_codeに変更。
 *  2008/07/04    1.2   Satoshi Yunba      禁則文字対応
 *  2008/07/10    1.3   Naoki Fukuda       ロットNo.がNULLだと品目が違っても一括りで出力される
 *  2008/08/05    1.4   Akiyoshi Shiina    ST不具合#519対応
 *
 *****************************************************************************************/
--
--#######################  固定グローバル定数宣言部 START   #######################
--
  gv_status_normal CONSTANT VARCHAR2(1) := '0';
  gv_status_warn   CONSTANT VARCHAR2(1) := '1';
  gv_status_error  CONSTANT VARCHAR2(1) := '2';
  gv_msg_part      CONSTANT VARCHAR2(3) := ' : ';
  gv_msg_cont      CONSTANT VARCHAR2(3) := '.';
--
--################################  固定部 END   ###############################
--
--#######################  固定グローバル変数宣言部 START   #######################
--
--################################  固定部 END   ###############################
--
--#####################  固定共通例外宣言部 START   ####################
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
--###########################  固定部 END   ############################
--
  -- ===============================
  -- ユーザー定義例外
  -- ===============================
  --*** 処理部共通例外 ***
  no_data_expt       EXCEPTION;  -- 帳票0件例外
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  -- 帳票情報
  gc_pkg_name                CONSTANT  VARCHAR2(12) := 'xxwsh620007c' ;  -- パッケージ名
  gc_report_id               CONSTANT  VARCHAR2(12) := 'XXWSH620007T' ;  -- 帳票ID
  -- 日付フォーマット
  gc_date_fmt_all            CONSTANT  VARCHAR2(21) := 'YYYY/MM/DD HH24:MI:SS' ; -- 年月日時分秒
  gc_date_fmt_ymd            CONSTANT  VARCHAR2(10) := 'YYYY/MM/DD' ;            -- 年月日
  -- 出力タグ
  gc_tag_type_tag            CONSTANT  VARCHAR2(1)  := 'T' ;                 -- グループタグ
  gc_tag_type_data           CONSTANT  VARCHAR2(1)  := 'D' ;                 -- データタグ
  ------------------------------
  -- 出荷・支給・移動共通
  ------------------------------
  -- 業務種別
  gc_biz_type_cd_ship        CONSTANT  VARCHAR2(1)  := '1' ;
  gc_biz_type_cd_supply      CONSTANT  VARCHAR2(1)  := '2' ;
  gc_biz_type_cd_move        CONSTANT  VARCHAR2(1)  := '3' ;
  gc_biz_type_nm_ship        CONSTANT  VARCHAR2(4)  := '出荷' ;
  gc_biz_type_nm_supply      CONSTANT  VARCHAR2(4)  := '支給' ;
  gc_biz_type_nm_move        CONSTANT  VARCHAR2(4)  := '移動' ;
  -- 削除・取消フラグ
  gc_delete_flg              CONSTANT  VARCHAR2(1)  := 'Y' ;
  -- 文書タイプ
  gc_doc_type_ship           CONSTANT  VARCHAR2(2)  := '10' ;       -- 出荷依頼
  gc_doc_type_supply         CONSTANT  VARCHAR2(2)  := '30' ;       -- 支給指示
  gc_doc_type_move           CONSTANT  VARCHAR2(2)  := '20' ;       -- 移動
  -- レコードタイプ
  gc_rec_type_shiji          CONSTANT  VARCHAR2(2)  := '10' ;       -- 指示
  -- 品目区分
  gc_item_cd_prod            CONSTANT  VARCHAR2(1)  := '5' ;        -- 製品
  -- 商品区分
  gc_prod_cd_drink           CONSTANT  VARCHAR2(1)  := '2' ;        -- ドリンク
  ------------------------------
  -- 出荷・ 支給関連
  ------------------------------
  -- 出荷支給区分
  gc_req_kbn_ship            CONSTANT  VARCHAR2(1)  := '1' ;        -- 出荷依頼
  gc_req_kbn_supply          CONSTANT  VARCHAR2(1)  := '2' ;        -- 支給依頼
  -- 受注カテゴリ
  gc_order_cate_ret          CONSTANT  VARCHAR2(10) := 'RETURN' ;   -- 返品(受注のみ)
  -- 最新フラグ
  gc_new_flg                 CONSTANT  VARCHAR2(1)  := 'Y' ;        -- 最新フラグ
  -- 出荷依頼ステータス
  gc_ship_status_close       CONSTANT  VARCHAR2(2)  := '03' ;       -- 締め済み
  gc_ship_status_delete      CONSTANT  VARCHAR2(2)  := '99' ;       -- 取消
  gc_ship_status_receipt     CONSTANT  VARCHAR2(2)  := '07' ;       -- 受領済
  ------------------------------
  -- 移動関連
  ------------------------------
  -- 移動タイプ
  gc_mov_type_not_ship       CONSTANT  VARCHAR2(5)  := '2' ;        -- 積送なし
  -- 移動ステータス
  gc_move_status_ordered     CONSTANT  VARCHAR2(2)  := '02' ;       -- 依頼済
  gc_move_status_delete      CONSTANT  VARCHAR2(2)  := '99' ;       -- 取消
  ------------------------------
  -- クイックコード関連
  ------------------------------
  -- 自社他社区分
  gc_lookup_cd_int_ext       CONSTANT  VARCHAR2(30)  := 'XXWSH_621B_INT_EXT_CLASS' ;
  ------------------------------
  -- メッセージ関連
  ------------------------------
  --アプリケーション名
  gc_application_wsh         CONSTANT VARCHAR2(5)   := 'XXWSH' ;            -- ｱﾄﾞｵﾝ:出荷･引当･配車
  gc_application_cmn         CONSTANT VARCHAR2(5)   := 'XXCMN' ;            -- ｱﾄﾞｵﾝ:ﾏｽﾀ･経理･共通
  --メッセージID
  gc_msg_id_prm_chk          CONSTANT  VARCHAR2(15) := 'APP-XXWSH-12452' ;  -- ﾊﾟﾗﾒｰﾀﾁｪｯｸｴﾗｰ
  gc_msg_id_no_data          CONSTANT  VARCHAR2(15) := 'APP-XXCMN-10122' ;  -- 帳票0件エラー
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  -- レコード型宣言用テーブル別名宣言
  xoha    xxwsh_order_headers_all%ROWTYPE ;        -- 受注ヘッダアドオン
  xola    xxwsh_order_lines_all%ROWTYPE ;          -- 受注明細アドオン
  xott2v  xxwsh_oe_transaction_types2_v%ROWTYPE ;  -- 受注タイプ情報VIEW2
  xim2v   xxcmn_item_mst2_v%ROWTYPE ;              -- OPM品目情報VIEW2
  xic3v   xxcmn_item_categories3_v%ROWTYPE ;       -- OPM品目カテゴリ割当情報VIEW3
  xmld    xxinv_mov_lot_details%ROWTYPE ;          -- 移動ロット詳細(アドオン)
  ilm     ic_lots_mst%ROWTYPE ;                    -- OPMロットマスタ
  xil2v   xxcmn_item_locations2_v%ROWTYPE ;        -- OPM保管場所情報VIEW2
  xcas2v  xxcmn_cust_acct_sites2_v%ROWTYPE ;       -- 顧客サイト情報VIEW2
  xca2v   xxcmn_cust_accounts2_v%ROWTYPE ;         -- 顧客情報VIEW2
  xlv2v   xxcmn_lookup_values2_v%ROWTYPE ;         -- クイックコード情報VIEW2
--
  ------------------------------
  -- 入力パラメータ関連
  ------------------------------
  -- 入力パラメータ格納用レコード
  TYPE rec_param_data IS RECORD(
     biz_type      xlv2v.lookup_code%TYPE            -- 01:業務種別  ※必須
    ,ship_type     xott2v.transaction_type_id%TYPE   -- 02:出庫形態
    ,block         xil2v.distribution_block%TYPE     -- 03:ブロック
    ,shipped_cd    xil2v.segment1%TYPE               -- 04:出庫元
    ,delivery_to   xil2v.segment1%TYPE               -- 05:配送先／入庫先
    ,prod_class    xic3v.prod_class_code%TYPE        -- 06:商品区分  ※必須
    ,item_class    xic3v.item_class_code%TYPE        -- 07:品目区分
    ,shipped_date  DATE                              -- 08:出庫日    ※必須
  );
--
  ------------------------------
  -- 出力データ関連
  ------------------------------
  -- 出力データ格納用レコード
  TYPE rec_report_data IS RECORD(
     biz_kind            VARCHAR2(4)                          -- 業務種別
    ,trans_type_id       xoha.order_type_id%TYPE              -- 出庫形態
    ,trans_type_name     xott2v.transaction_type_name%TYPE    -- 出庫形態名
    ,shipped_code        xoha.deliver_from%TYPE               -- 出庫元コード
    ,shipped_name        xil2v.description%TYPE               -- 出庫元名称
    ,item_class_code     xic3v.item_class_code%TYPE           -- 品目区分コード
    ,item_class_name     xic3v.item_class_name%TYPE           -- 品目区分名称
    ,shipped_date        xoha.schedule_ship_date%TYPE         -- 出庫日
    ,int_ext_class_code  xic3v.int_ext_class%TYPE             -- 内外区分コード
    ,int_ext_class_name  xlv2v.meaning%TYPE                   -- 内外区分名
    ,item_code           xola.shipping_item_code%TYPE         -- 品目コード
    ,item_name           xim2v.item_short_name%TYPE           -- 品目名称
    ,lot_no              xmld.lot_no%TYPE                     -- ロットNo
    ,prod_date           ilm.attribute1%TYPE                  -- 製造日
    ,best_before_date    ilm.attribute3%TYPE                  -- 賞味期限
    ,native_sign         ilm.attribute2%TYPE                  -- 固有記号
    ,base_cd             xoha.head_sales_branch%TYPE          -- 管轄拠点コード
    ,base_nm             xca2v.party_short_name%TYPE          -- 管轄拠点名称
    ,delivery_to_code    xoha.deliver_to%TYPE                 -- 配送先/入庫先コード
    ,delivery_to_name    VARCHAR2(60)                         -- 配送先/入庫先名称
    ,req_move_no         xoha.request_no%TYPE                 -- 依頼No
    ,arrive_date         xoha.schedule_arrival_date%TYPE      -- 着日
    ,description         VARCHAR2(30)                         -- 摘要
    ,qty                 NUMBER                               -- 数量
    ,qty_tani            VARCHAR2(3)                          -- 単位
  );
  type_report_data       rec_report_data;
  TYPE list_report_data  IS TABLE OF rec_report_data INDEX BY BINARY_INTEGER ;
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gt_param               rec_param_data ;         -- 入力パラメータ情報
  gt_report_data         list_report_data ;       -- 出力データ
  gt_xml_data_table      xml_data ;               -- XMLデータ
  gv_dept_cd             VARCHAR2(10) ;           -- 担当部署
  gv_dept_nm             VARCHAR2(14) ;           -- 担当者
  gv_biz_type_nm         VARCHAR2(4) ;            -- 業務種別名
  gv_user_id             fnd_user.user_id%TYPE ;  -- ユーザID
--
  /**********************************************************************************
   * Function Name    : fnc_chgdt_d
   * Description      : 日付型変換(YYYY/MM/DD形式の文字列 → 日付型)
   *                  文字列の日付(YYYY/MM/DD形式)を日付型に変換して返却
   *                  (例：2008/04/01 → 01-APR-08)
   ***********************************************************************************/
  FUNCTION fnc_chgdt_d(
    iv_date  IN  VARCHAR2  -- YYYY/MM/DD形式の日付
  )RETURN DATE
  IS
  BEGIN
    RETURN( FND_DATE.STRING_TO_DATE(iv_date, gc_date_fmt_ymd) ) ;
  END fnc_chgdt_d;
--
  /**********************************************************************************
   * Function Name    : fnc_chgdt_c
   * Description      : 日付型変換(日付型 → YYYY/MM/DD形式の文字列)
   *                  日付型を「YYYY/MM/DD形式」の文字列に変換して返却
   *                  (例：01-APR-08 → 2008/04/01 )
   ***********************************************************************************/
  FUNCTION fnc_chgdt_c(
    id_date  IN  DATE
  )RETURN VARCHAR2
  IS
  BEGIN
    RETURN( TO_CHAR(id_date, gc_date_fmt_ymd) ) ;
  END fnc_chgdt_c;
--
  /**********************************************************************************
   * Procedure Name   : prc_set_tag_data
   * Description      : タグ情報設定処理
   ***********************************************************************************/
  PROCEDURE prc_set_tag_data(
     iv_tag_name       IN  VARCHAR2                 -- タグ名
    ,iv_tag_value      IN  VARCHAR2                 -- データ
    ,iv_tag_type       IN  VARCHAR2  DEFAULT NULL   -- データ
  )
  IS
    ln_data_index  NUMBER ;    -- XMLデータのインデックス
  BEGIN
    ln_data_index := gt_xml_data_table.COUNT + 1 ;
--
    -- タグ名を設定
    gt_xml_data_table(ln_data_index).tag_name := iv_tag_name ;
--
    IF ((iv_tag_value IS NULL) AND (iv_tag_type = gc_tag_type_tag)) THEN
      -- グループタグ設定
      gt_xml_data_table(ln_data_index).tag_type := gc_tag_type_tag;
    ELSE
      -- データタグ設定
      gt_xml_data_table(ln_data_index).tag_type := gc_tag_type_data;
      gt_xml_data_table(ln_data_index).tag_value := iv_tag_value;
    END IF;
  END prc_set_tag_data ;
--
  /**********************************************************************************
   * Procedure Name   : prc_set_tag_data
   * Description      : タグ情報設定処理(開始・終了タグ用)
   ***********************************************************************************/
  PROCEDURE prc_set_tag_data(
     iv_tag_name       IN  VARCHAR2  -- タグ名
  )
  IS
  BEGIN
    prc_set_tag_data(iv_tag_name, NULL, gc_tag_type_tag);
  END prc_set_tag_data ;
--
  /**********************************************************************************
   * Procedure Name   : prc_initialize
   * Description      : 初期処理
   ***********************************************************************************/
  PROCEDURE prc_initialize(
    ov_errbuf     OUT  VARCHAR2         -- エラー・メッセージ           --# 固定 #
   ,ov_retcode    OUT  VARCHAR2         -- リターン・コード             --# 固定 #
   ,ov_errmsg     OUT  VARCHAR2         -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT  VARCHAR2(100) := 'prc_initialize' ;  -- プログラム名
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
    -- *** ローカル・例外処理 ***
    prm_chk_expt       EXCEPTION;  -- パラメータチェック例外
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
    -- パラメータチェック
    -- ====================================================
    IF ((gt_param.shipped_cd IS NULL) AND (gt_param.block IS NULL)) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg( gc_application_wsh
                                            ,gc_msg_id_prm_chk
                                           ) ;
      RAISE prm_chk_expt ;
    END IF;
--
  EXCEPTION
    --*** パラメータチェック例外ハンドラ ***
    WHEN prm_chk_expt THEN
      ov_errmsg  := lv_errmsg ;
      ov_errbuf  := lv_errmsg ;
      ov_retcode := gv_status_error ;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END prc_initialize;
--
  /**********************************************************************************
   * Procedure Name   : prc_get_report_data
   * Description      : 帳票データ取得処理
   ***********************************************************************************/
  PROCEDURE prc_get_report_data(
    ov_errbuf      OUT   VARCHAR2     --   エラー・メッセージ           --# 固定 #
   ,ov_retcode     OUT   VARCHAR2     --   リターン・コード             --# 固定 #
   ,ov_errmsg      OUT   VARCHAR2     --   ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_get_report_data' ;  -- プログラム名
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
    -- *** ローカル・カーソル ***
    ----------------------------------------------------------------------------------
    -- 出荷情報
    ----------------------------------------------------------------------------------
    CURSOR cur_data_ship
    IS
      SELECT
         TO_CHAR(gc_biz_type_nm_ship)      AS  biz_kind               -- 業務種別
        ,xoha.order_type_id                AS  trans_type_id          -- 出庫形態
        ,xott2v.transaction_type_name      AS  trans_type_name        -- 出庫形態名
        ,xoha.deliver_from                 AS  shipped_code           -- 出庫元コード
        ,xil2v.description                 AS  shipped_name           -- 出庫元名称
        ,xic3v.item_class_code             AS  item_class_code        -- 品目区分コード
        ,xic3v.item_class_name             AS  item_class_name        -- 品目区分名称
        ,xoha.schedule_ship_date           AS  shipped_date           -- 出庫日
        ,xic3v.int_ext_class               AS  int_ext_class_code     -- 内外区分コード
        ,xlv2v.meaning                     AS  int_ext_class_name     -- 内外区分名
        ,xola.shipping_item_code           AS  item_code              -- 品目コード
        ,xim2v.item_short_name             AS  item_name              -- 品目名称
        ,xmld.lot_no                       AS  lot_no                 -- ロットNo
        ,ilm.attribute1                    AS  prod_date              -- 製造日
        ,ilm.attribute3                    AS  best_before_date       -- 賞味期限
        ,ilm.attribute2                    AS  native_sign            -- 固有記号
        ,xoha.head_sales_branch            AS  base_cd                -- 管轄拠点コード
        ,xca2v.party_short_name            AS  base_nm                -- 管轄拠点名称
        ,xoha.deliver_to                   AS  delivery_to_code       -- 配送先/入庫先コード
        ,xcas2v.party_site_full_name       AS  delivery_to_name       -- 配送先/入庫先名称
        ,xoha.request_no                   AS  req_move_no            -- 依頼No
        ,xoha.schedule_arrival_date        AS  arrive_date            -- 着日
        ,SUBSTRB(xoha.shipping_instructions, 1, 30) AS  description   -- 摘要
        ,CASE
         -- 引当されている場合
         WHEN ( xola.reserved_quantity > 0 ) THEN
           CASE 
             WHEN  ((xic3v.item_class_code = gc_item_cd_prod)
               AND  (xim2v.conv_unit IS NOT NULL)) THEN
               xmld.actual_quantity / TO_NUMBER(
                                        CASE
                                          WHEN ( xim2v.num_of_cases > 0 ) THEN
                                            xim2v.num_of_cases
                                          ELSE
                                            TO_CHAR(1)
                                        END
                                      )
             ELSE
               xmld.actual_quantity
             END
         -- 引当されていない場合
         WHEN  ( (xola.reserved_quantity IS NULL) OR (xola.reserved_quantity = 0) ) THEN
           CASE 
             WHEN  ((xic3v.item_class_code = gc_item_cd_prod)
               AND  (xim2v.conv_unit IS NOT NULL) ) THEN
               xola.quantity / TO_NUMBER(
                                 CASE
                                   WHEN ( xim2v.num_of_cases > 0 ) THEN xim2v.num_of_cases
                                   ELSE TO_CHAR(1)
                                 END
                                )
             ELSE
               xola.quantity
             END
         END                               AS  qty            -- 数量
        ,CASE
          WHEN ( (xic3v.item_class_code = gc_item_cd_prod) AND (xim2v.conv_unit IS NOT NULL) ) THEN
            xim2v.conv_unit
          ELSE
            xim2v.item_um
          END                              AS  qty_tani       -- 単位
      FROM
         xxwsh_order_headers_all          xoha      -- 受注ヘッダアドオン
        ,xxwsh_oe_transaction_types2_v    xott2v    -- 受注タイプ情報VIEW2
        ,xxwsh_order_lines_all            xola      -- 受注明細アドオン
        ,xxcmn_item_mst2_v                xim2v     -- OPM品目情報VIEW2
        ,xxcmn_item_categories3_v         xic3v     -- OPM品目カテゴリ割当情報VIEW3
        ,xxinv_mov_lot_details            xmld      -- 移動ロット詳細(アドオン)
        ,ic_lots_mst                      ilm       -- OPMロットマスタ
        ,xxcmn_item_locations2_v          xil2v     -- OPM保管場所情報VIEW2
        ,xxcmn_cust_acct_sites2_v         xcas2v    -- 顧客サイト情報VIEW2
        ,xxcmn_cust_accounts2_v           xca2v     -- 顧客情報VIEW2
        ,xxcmn_lookup_values2_v           xlv2v     -- クイックコード情報VIEW2
      WHERE
      -------------------------------------------------------------------------------
      -- 受注ヘッダアドオン
      -------------------------------------------------------------------------------
             xoha.req_status  >=  gc_ship_status_close     -- 締め済み
        AND  xoha.req_status  <>  gc_ship_status_delete    -- 取消
        AND  (gt_param.delivery_to IS NULL
          OR  xoha.deliver_to  =  gt_param.delivery_to
        )
        AND  (((gt_param.shipped_cd IS NULL) AND (gt_param.block IS NULL))
          OR  xoha.deliver_from         =  gt_param.shipped_cd
          OR  xil2v.distribution_block  =  gt_param.block
        )
        AND  xoha.schedule_ship_date    =  gt_param.shipped_date
        AND  xoha.latest_external_flag  =  gc_new_flg
        ------------------------------------------------
        -- 受注タイプ情報VIEW2
        ------------------------------------------------
        AND  xoha.order_type_id            =  xott2v.transaction_type_id
        AND  xott2v.shipping_shikyu_class  =  gc_req_kbn_ship     -- 出荷支給区分'出荷依頼'
        AND  xott2v.order_category_code   <>  gc_order_cate_ret   -- 受注カテゴリ'返品'
        AND  (gt_param.ship_type IS NULL
          OR  xott2v.transaction_type_id   =  gt_param.ship_type
        )
        -------------------------------------------------------------------------------
        -- 受注明細アドオン
        -------------------------------------------------------------------------------
        AND  xoha.order_header_id   =  xola.order_header_id
        AND  xola.delete_flag      <>  gc_delete_flg
        -------------------------------------------------------------------------------
        -- OPM品目情報VIEW2
        -------------------------------------------------------------------------------
        AND  xola.shipping_inventory_item_id   = xim2v.inventory_item_id
        AND  xim2v.start_date_active          <= xoha.schedule_ship_date
        AND  (xim2v.end_date_active           >= xoha.schedule_ship_date
          OR  xim2v.end_date_active IS NULL
        )
        -------------------------------------------------------------------------------
        -- OPM品目カテゴリ割当情報VIEW3
        -------------------------------------------------------------------------------
        AND  xim2v.item_id            =  xic3v.item_id
        AND  (gt_param.item_class IS NULL
          OR  xic3v.item_class_code   =  gt_param.item_class
        )
        AND  xic3v.prod_class_code    =  gt_param.prod_class
        -------------------------------------------------------------------------------
        -- 移動ロット詳細(アドオン)
        -------------------------------------------------------------------------------
        AND  xola.order_line_id          =  xmld.mov_line_id(+)
        AND  xmld.document_type_code(+)  =  gc_doc_type_ship   -- 出荷依頼
        AND  xmld.record_type_code(+)    =  gc_rec_type_shiji  -- 指示
        -------------------------------------------------------------------------------
        -- OPMロットマスタ
        -------------------------------------------------------------------------------
        AND  xmld.lot_id   =  ilm.lot_id(+)
        AND  xmld.item_id  =  ilm.item_id(+)
        -------------------------------------------------------------------------------
        -- 顧客サイト情報VIEW2
        -------------------------------------------------------------------------------
        AND  xoha.deliver_to_id         =  xcas2v.party_site_id
        AND  xcas2v.start_date_active  <=  xoha.schedule_ship_date
        AND  (xcas2v.end_date_active   >=  xoha.schedule_ship_date
          OR  xcas2v.end_date_active IS NULL
        )
        -------------------------------------------------------------------------------
        -- 顧客情報VIEW2
        -------------------------------------------------------------------------------
        AND  xoha.head_sales_branch    =  xca2v.party_number
        AND  xca2v.start_date_active  <=  xoha.schedule_ship_date
        AND  (xca2v.end_date_active   >=  xoha.schedule_ship_date
          OR  xca2v.end_date_active IS NULL
        )
        -------------------------------------------------------------------------------
        -- OPM保管場所情報VIEW2
        -------------------------------------------------------------------------------
        AND  xoha.deliver_from_id  =  xil2v.inventory_location_id
        -------------------------------------------------------------------------------
        -- クイックコード情報VIEW2
        -------------------------------------------------------------------------------
        AND  xlv2v.lookup_type  =  gc_lookup_cd_int_ext
        AND  xlv2v.lookup_code  =  xic3v.int_ext_class   -- 自社他社区分(1:自社、2:他社）
      ORDER BY
         trans_type_id       ASC   -- 出庫形態
        ,shipped_code        ASC   -- 出庫元(コード)
        ,item_class_code     ASC   -- 品目区分
        ,shipped_date        ASC   -- 出庫日
        ,int_ext_class_code  ASC   -- 内外区分コード
        ,item_code           ASC   -- 品目コード
        ,lot_no              ASC   -- ロットNo
        ,base_cd             ASC   -- 管轄拠点コード
        ,delivery_to_code    ASC   -- 配送先／入庫先コード
        ,req_move_no         ASC   -- 依頼No／移動No
      ;
--
    ----------------------------------------------------------------------------------
    -- 支給情報
    ----------------------------------------------------------------------------------
    CURSOR cur_data_supply
    IS
      SELECT
         TO_CHAR(gc_biz_type_nm_supply)    AS  biz_kind               -- 業務種別
        ,xoha.order_type_id                AS  trans_type_id          -- 出庫形態
        ,xott2v.transaction_type_name      AS  trans_type_name        -- 出庫形態名
        ,xoha.deliver_from                 AS  shipped_code           -- 出庫元コード
        ,xil2v.description                 AS  shipped_name           -- 出庫元名称
        ,xic3v.item_class_code             AS  item_class_code        -- 品目区分コード
        ,xic3v.item_class_name             AS  item_class_name        -- 品目区分名称
        ,xoha.schedule_ship_date           AS  shipped_date           -- 出庫日
        ,xic3v.int_ext_class               AS  int_ext_class_code     -- 内外区分コード
        ,xlv2v.meaning                     AS  int_ext_class_name     -- 内外区分名
        ,xola.shipping_item_code           AS  item_code              -- 品目コード
        ,xim2v.item_short_name             AS  item_name              -- 品目名称
        ,xmld.lot_no                       AS  lot_no                 -- ロットNo
        ,ilm.attribute1                    AS  prod_date              -- 製造日
        ,ilm.attribute3                    AS  best_before_date       -- 賞味期限
        ,ilm.attribute2                    AS  native_sign            -- 固有記号
        ,xoha.vendor_code                  AS  base_cd                -- 管轄拠点コード
        ,xv2v.vendor_short_name            AS  base_nm                -- 管轄拠点名称
        ,xoha.vendor_site_code             AS  delivery_to_code       -- 配送先/入庫先コード
        ,xvs2v.vendor_site_name            AS  delivery_to_name       -- 配送先/入庫先名称
        ,xoha.request_no                   AS  req_move_no            -- 依頼No
        ,xoha.schedule_arrival_date        AS  arrive_date            -- 着日
        ,SUBSTRB(xoha.shipping_instructions, 1, 30) AS  description   -- 摘要
        ,CASE                                     
         -- 引当されている場合
         WHEN ( xola.reserved_quantity > 0 ) THEN
           xmld.actual_quantity
         -- 引当されていない場合
         WHEN  ( ( xola.reserved_quantity IS NULL ) OR ( xola.reserved_quantity = 0 ) ) THEN
           xola.quantity
         END                               AS  qty            -- 数量
        ,xim2v.item_um                     AS  qty_tani       -- 単位
      FROM
         xxwsh_order_headers_all         xoha       -- 受注ヘッダアドオン
        ,xxwsh_oe_transaction_types2_v   xott2v     -- 受注タイプ情報VIEW2
        ,xxwsh_order_lines_all           xola       -- 受注明細アドオン
        ,xxcmn_item_mst2_v               xim2v      -- OPM品目情報VIEW2
        ,xxcmn_item_categories3_v        xic3v      -- OPM品目カテゴリ割当情報VIEW3
        ,xxinv_mov_lot_details           xmld       -- 移動ロット詳細(アドオン)
        ,ic_lots_mst                     ilm        -- OPMロットマスタ
        ,xxcmn_item_locations2_v         xil2v      -- OPM保管場所情報VIEW2
        ,xxcmn_vendor_sites2_v           xvs2v      -- 仕入先サイト情報VIEW2
        ,xxcmn_vendors2_v                xv2v       -- 仕入先情報VIEW2
        ,xxcmn_lookup_values2_v          xlv2v      -- クイックコード情報VIEW2
      WHERE
        -------------------------------------------------------------------------------
        -- 受注ヘッダアドオン
        -------------------------------------------------------------------------------
             xoha.req_status  >=  gc_ship_status_receipt  -- 受領済
        AND  xoha.req_status  <>  gc_ship_status_delete   -- 取消
        AND  (gt_param.delivery_to IS NULL
             --Mod start 2008/06/24 uehara
--          OR  xoha.deliver_to = gt_param.delivery_to
          OR  xoha.vendor_site_code = gt_param.delivery_to
             --Mod end 2008/06/24 uehara
        )
        AND  ((gt_param.shipped_cd IS NULL) AND  (gt_param.block IS NULL)
          OR  xoha.deliver_from         =  gt_param.shipped_cd
          OR  xil2v.distribution_block  =  gt_param.block
        )
        AND  xoha.schedule_ship_date    = gt_param.shipped_date
        AND  xoha.latest_external_flag  = gc_new_flg
        ------------------------------------------------
        -- 受注タイプ情報VIEW2
        ------------------------------------------------
        AND  xoha.order_type_id            =  xott2v.transaction_type_id
        AND  xott2v.shipping_shikyu_class  =  gc_req_kbn_supply    -- 出荷支給区分'支給依頼'
        AND  xott2v.order_category_code   <>  gc_order_cate_ret    -- 受注カテゴリ'返品'
        AND  (gt_param.ship_type IS NULL
          OR  xott2v.transaction_type_id  =  gt_param.ship_type
        )
        -------------------------------------------------------------------------------
        -- 受注明細アドオン
        -------------------------------------------------------------------------------
        AND  xoha.order_header_id   =  xola.order_header_id
        AND  xola.delete_flag      <>  gc_delete_flg
        -------------------------------------------------------------------------------
        -- OPM品目情報VIEW2
        -------------------------------------------------------------------------------
        AND  xola.shipping_inventory_item_id  =  xim2v.inventory_item_id
        AND  xim2v.start_date_active  <=  xoha.schedule_ship_date
        AND  (xim2v.end_date_active   >=  xoha.schedule_ship_date
          OR  xim2v.end_date_active IS NULL
        )
        -------------------------------------------------------------------------------
        -- OPM品目カテゴリ割当情報VIEW3
        -------------------------------------------------------------------------------
        AND  xim2v.item_id           =  xic3v.item_id
        AND  xic3v.prod_class_code   =  gt_param.prod_class
        AND  (gt_param.item_class IS NULL
          OR  xic3v.item_class_code  =  gt_param.item_class
        )
        -------------------------------------------------------------------------------
        -- 移動ロット詳細(アドオン)
        -------------------------------------------------------------------------------
        AND  xola.order_line_id          =  xmld.mov_line_id(+)
        AND  xmld.document_type_code(+)  =  gc_doc_type_supply  -- 支給指示
        AND  xmld.record_type_code(+)    =  gc_rec_type_shiji   -- 指示
        -------------------------------------------------------------------------------
        -- OPMロットマスタ
        -------------------------------------------------------------------------------
        AND  xmld.lot_id   =  ilm.lot_id(+)
        AND  xmld.item_id  =  ilm.item_id(+)
        -------------------------------------------------------------------------------
        -- 仕入先サイト情報VIEW2
        -------------------------------------------------------------------------------
        AND  xoha.vendor_site_id       = xvs2v.vendor_site_id
        AND  xvs2v.start_date_active  <= xoha.schedule_ship_date
        AND  (xvs2v.end_date_active   >= xoha.schedule_ship_date
          OR  xvs2v.end_date_active IS NULL
        )
        -------------------------------------------------------------------------------
        -- 仕入先情報VIEW2
        -------------------------------------------------------------------------------
        AND  xoha.vendor_id           = xv2v.vendor_id
        AND  xv2v.start_date_active  <= xoha.schedule_ship_date
        AND  (xv2v.end_date_active   >= xoha.schedule_ship_date
          OR  xv2v.end_date_active IS NULL
        )
        -------------------------------------------------------------------------------
        -- OPM保管場所情報VIEW2
        -------------------------------------------------------------------------------
        AND  xoha.deliver_from_id  =  xil2v.inventory_location_id
        -------------------------------------------------------------------------------
        -- クイックコード情報VIEW2
        -------------------------------------------------------------------------------
        AND  xlv2v.lookup_type  =  gc_lookup_cd_int_ext
        AND  xlv2v.lookup_code  =  xic3v.int_ext_class    -- 自社他社区分(1:自社、2:他社）
      ORDER BY
         trans_type_id       ASC   -- 出庫形態
        ,shipped_code        ASC   -- 出庫元(コード)
        ,item_class_code     ASC   -- 品目区分
        ,shipped_date        ASC   -- 出庫日
        ,int_ext_class_code  ASC   -- 内外区分コード
        ,item_code           ASC   -- 品目コード
        ,lot_no              ASC   -- ロットNo
        ,base_cd             ASC   -- 管轄拠点コード
        ,delivery_to_code    ASC   -- 配送先／入庫先コード
        ,req_move_no         ASC   -- 依頼No／移動No
      ;
--
    ----------------------------------------------------------------------------------
    -- 移動情報
    ----------------------------------------------------------------------------------
    CURSOR cur_data_move
    IS
      SELECT
         TO_CHAR(gc_biz_type_nm_move)      AS  biz_kind               -- 業務種別
        ,NULL                              AS  trans_type_id          -- 出庫形態
        ,NULL                              AS  trans_type_name        -- 出庫形態名
        ,xmrih.shipped_locat_code          AS  shipped_code           -- 出庫元コード
        ,xil2v1.description                AS  shipped_name           -- 出庫元名称
        ,xic3v.item_class_code             AS  item_class_code        -- 品目区分コード
        ,xic3v.item_class_name             AS  item_class_name        -- 品目区分名称
        ,xmrih.schedule_ship_date          AS  shipped_date           -- 出庫日
        ,xic3v.int_ext_class               AS  int_ext_class_code     -- 内外区分コード
        ,xlv2v.meaning                     AS  int_ext_class_name     -- 内外区分名
        ,xmril.item_code                   AS  item_code              -- 品目コード
        ,xim2v.item_short_name             AS  item_name              -- 品目名称
        ,xmld.lot_no                       AS  lot_no                 -- ロットNo
        ,ilm.attribute1                    AS  prod_date              -- 製造日
        ,ilm.attribute3                    AS  best_before_date       -- 賞味期限
        ,ilm.attribute2                    AS  native_sign            -- 固有記号
        ,NULL                              AS  base_cd                -- 管轄拠点コード
        ,NULL                              AS  base_nm                -- 管轄拠点名称
        ,xmrih.ship_to_locat_code          AS  delivery_to_code       -- 配送先/入庫先コード
        ,xil2v2.description                AS  delivery_to_name       -- 配送先/入庫先名称
        ,xmrih.mov_num                     AS  req_move_no            -- 依頼No
        ,xmrih.schedule_arrival_date       AS  arrive_date            -- 着日
        ,SUBSTRB(xmrih.description, 1, 30) AS  description            -- 摘要
        ,CASE
         -- 引当されている場合
         WHEN ( xmril.reserved_quantity > 0 ) THEN
           CASE 
             WHEN  (xic3v.prod_class_code = gc_prod_cd_drink
               AND  xic3v.item_class_code = gc_item_cd_prod
               AND  xim2v.conv_unit IS NOT NULL ) THEN
               xmld.actual_quantity / TO_NUMBER(
                                        CASE
                                          WHEN ( xim2v.num_of_cases > 0 ) THEN
                                            xim2v.num_of_cases
                                          ELSE
                                            TO_CHAR(1)
                                        END
                                      )
             ELSE
               xmld.actual_quantity
             END
         -- 引当されていない場合
         WHEN  ( (xmril.reserved_quantity IS NULL) OR (xmril.reserved_quantity = 0) ) THEN
           CASE 
             WHEN  (xic3v.prod_class_code = gc_prod_cd_drink
               AND  xic3v.item_class_code = gc_item_cd_prod
               AND  xim2v.conv_unit IS NOT NULL ) THEN
               xmril.instruct_qty / TO_NUMBER(
                                      CASE
                                        WHEN ( xim2v.num_of_cases > 0 ) THEN
                                          xim2v.num_of_cases
                                        ELSE
                                          TO_CHAR(1)
                                      END
                                    )
             ELSE
               xmril.instruct_qty
             END
         END                               AS  qty            -- 数量
        ,CASE
          WHEN  (xic3v.prod_class_code = gc_prod_cd_drink
            AND  xic3v.item_class_code = gc_item_cd_prod
            AND  xim2v.conv_unit IS NOT NULL ) THEN
            xim2v.conv_unit
          ELSE
            xim2v.item_um
          END                              AS  qty_tani       -- 単位
      FROM
         xxinv_mov_req_instr_headers   xmrih      -- 移動依頼/指示ヘッダアドオン
        ,xxinv_mov_req_instr_lines     xmril      -- 移動依頼/指示明細(アドオン)
        ,xxcmn_item_mst2_v             xim2v      -- OPM品目情報VIEW2
        ,xxcmn_item_categories3_v      xic3v      -- OPM品目カテゴリ割当情報VIEW3
        ,xxinv_mov_lot_details         xmld       -- 移動ロット詳細(アドオン)
        ,ic_lots_mst                   ilm        -- OPMロットマスタ
        ,xxcmn_item_locations2_v       xil2v1     -- OPM保管場所情報VIEW2-1
        ,xxcmn_item_locations2_v       xil2v2     -- OPM保管場所情報VIEW2-2
        ,xxcmn_lookup_values2_v        xlv2v      -- クイックコード情報VIEW2
      WHERE
        -------------------------------------------------------------------------------
        -- 移動依頼/指示ヘッダアドオン
        -------------------------------------------------------------------------------
             xmrih.mov_type  <>  gc_mov_type_not_ship      -- 積送なし
        AND  xmrih.status    >=  gc_move_status_ordered    -- 依頼済
        AND  xmrih.status    <>  gc_move_status_delete     -- 取消
        AND  (gt_param.delivery_to IS NULL
          OR  xmrih.ship_to_locat_code  =  gt_param.delivery_to
        )
        AND  ( ((gt_param.shipped_cd IS NULL) AND (gt_param.block IS NULL))
          OR  xmrih.shipped_locat_code   =  gt_param.shipped_cd
          OR  xil2v1.distribution_block  =  gt_param.block
        )
        AND  xmrih.schedule_ship_date  =  gt_param.shipped_date
        -------------------------------------------------------------------------------
        -- 移動依頼/指示明細(アドオン)
        -------------------------------------------------------------------------------
        AND  xmrih.mov_hdr_id   =  xmril.mov_hdr_id
        AND  xmril.delete_flg  <>  gc_delete_flg
        -------------------------------------------------------------------------------
        -- OPM品目情報VIEW2
        -------------------------------------------------------------------------------
        AND  xmril.item_id             =  xim2v.item_id
        AND  xim2v.start_date_active  <=  xmrih.schedule_ship_date
        AND  (xim2v.end_date_active IS NULL
          OR  xim2v.end_date_active   >=  xmrih.schedule_ship_date
        )
        -------------------------------------------------------------------------------
        -- OPM品目カテゴリ割当情報VIEW3
        -------------------------------------------------------------------------------
        AND  xim2v.item_id           =  xic3v.item_id
        AND  xic3v.prod_class_code   =  gt_param.prod_class
        AND  (gt_param.item_class IS NULL
          OR  xic3v.item_class_code  =  gt_param.item_class
        )
        -------------------------------------------------------------------------------
        -- 移動ロット詳細(アドオン)
        -------------------------------------------------------------------------------
        AND  xmril.mov_line_id           =  xmld.mov_line_id(+)
        AND  xmld.document_type_code(+)  =  gc_doc_type_move   -- 文章タイプ:移動
        AND  xmld.record_type_code(+)    =  gc_rec_type_shiji  -- レコードタイプ:指示
        -------------------------------------------------------------------------------
        -- OPMロットマスタ
        -------------------------------------------------------------------------------
        AND  xmld.lot_id   = ilm.lot_id(+)
        AND  xmld.item_id  = ilm.item_id(+)
        -------------------------------------------------------------------------------
        -- OPM保管場所情報VIEW2-1
        -------------------------------------------------------------------------------
        AND  xmrih.shipped_locat_id  =  xil2v1.inventory_location_id
        -------------------------------------------------------------------------------
        -- OPM保管場所情報VIEW2-2
        -------------------------------------------------------------------------------
        AND  xmrih.ship_to_locat_id  =  xil2v2.inventory_location_id
        -------------------------------------------------------------------------------
        -- クイックコード情報VIEW2
        -------------------------------------------------------------------------------
        AND  xlv2v.lookup_type  =  gc_lookup_cd_int_ext
        AND  xlv2v.lookup_code  =  xic3v.int_ext_class       -- 自社他社区分(1:自社、2:他社）
      ORDER BY
         shipped_code        ASC   -- 出庫元(コード)
        ,item_class_code     ASC   -- 品目区分
        ,shipped_date        ASC   -- 出庫日
        ,int_ext_class_code  ASC   -- 内外区分コード
        ,item_code           ASC   -- 品目コード
        ,lot_no              ASC   -- ロットNo
        ,base_cd             ASC   -- 管轄拠点コード
        ,delivery_to_code    ASC   -- 配送先／入庫先コード
        ,req_move_no         ASC   -- 依頼No／移動No
      ;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ユーザIDを取得し、変数に格納
    gv_user_id := FND_GLOBAL.USER_ID ;
--
    -- ====================================================
    -- 担当者情報取得
    -- ====================================================
    -- 担当部署
    gv_dept_cd := SUBSTRB(xxcmn_common_pkg.get_user_dept(gv_user_id), 1, 10) ;
    -- 担当者
    gv_dept_nm := SUBSTRB(xxcmn_common_pkg.get_user_name(gv_user_id), 1, 14) ;
--
    -- ====================================================
    -- 帳票データ取得
    -- ====================================================
    ------------------------------
    -- 業務種別が「出荷」の場合
    ------------------------------
    IF (gt_param.biz_type = gc_biz_type_cd_ship) THEN
      -- 帳票データ取得
      OPEN  cur_data_ship ;
      FETCH cur_data_ship BULK COLLECT INTO gt_report_data ;
      CLOSE cur_data_ship ;
--
      -- 業務種別名を設定
      gv_biz_type_nm := gc_biz_type_nm_ship ;
--
    ------------------------------
    -- 業務種別が「支給」の場合
    ------------------------------
    ELSIF (gt_param.biz_type = gc_biz_type_cd_supply) THEN
      -- 帳票データ取得
      OPEN  cur_data_supply ;
      FETCH cur_data_supply BULK COLLECT INTO gt_report_data ;
      CLOSE cur_data_supply ;
--
      -- 業務種別名を設定
      gv_biz_type_nm := gc_biz_type_nm_supply ;
--
    ------------------------------
    -- 業務種別が「移動」の場合
    ------------------------------
    ELSIF (gt_param.biz_type = gc_biz_type_cd_move) THEN
      -- 帳票データ取得
      OPEN  cur_data_move ;
      FETCH cur_data_move BULK COLLECT INTO gt_report_data ;
      CLOSE cur_data_move ;
--
      -- 業務種別名を設定
      gv_biz_type_nm := gc_biz_type_nm_move ;
    END IF;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      IF ( cur_data_ship%ISOPEN ) THEN
        CLOSE cur_data_ship ;
      END IF ;
      IF ( cur_data_supply%ISOPEN ) THEN
        CLOSE cur_data_supply ;
      END IF ;
      IF ( cur_data_move%ISOPEN ) THEN
        CLOSE cur_data_move ;
      END IF ;
      ov_errbuf  := SUBSTRB(gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      IF ( cur_data_ship%ISOPEN ) THEN
        CLOSE cur_data_ship ;
      END IF ;
      IF ( cur_data_supply%ISOPEN ) THEN
        CLOSE cur_data_supply ;
      END IF ;
      IF ( cur_data_move%ISOPEN ) THEN
        CLOSE cur_data_move ;
      END IF ;
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      IF ( cur_data_ship%ISOPEN ) THEN
        CLOSE cur_data_ship ;
      END IF ;
      IF ( cur_data_supply%ISOPEN ) THEN
        CLOSE cur_data_supply ;
      END IF ;
      IF ( cur_data_move%ISOPEN ) THEN
        CLOSE cur_data_move ;
      END IF ;
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END prc_get_report_data;
--
  /**********************************************************************************
   * Procedure Name   : prc_create_xml_data
   * Description      : XML生成処理
   ***********************************************************************************/
  PROCEDURE prc_create_xml_data(
    ov_errbuf     OUT  VARCHAR2     --   エラー・メッセージ           --# 固定 #
   ,ov_retcode    OUT  VARCHAR2     --   リターン・コード             --# 固定 #
   ,ov_errmsg     OUT  VARCHAR2     --   ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_create_xml_data' ;   -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- *** ローカル変数 ***
    -- 前回レコード格納用
    lv_tmp_trans_type      type_report_data.trans_type_id%TYPE DEFAULT NULL ;   -- 出庫形態
    lv_tmp_ship_cd         type_report_data.shipped_code%TYPE DEFAULT NULL ;    -- 出庫元
    lv_tmp_item_class      type_report_data.item_class_code%TYPE DEFAULT NULL ; -- 品目区分
    lv_tmp_ship_date       type_report_data.shipped_date%TYPE DEFAULT NULL ;    -- 出庫日
    lv_tmp_lot_no          type_report_data.lot_no%TYPE DEFAULT NULL ;          -- ロットNo
    lv_tmp_item_code       type_report_data.item_code%TYPE DEFAULT NULL ;       -- 品目コード 2008/07/10 Fukuda Add
--
    -- タグ出力判定フラグ
    lb_dispflg_trans_type  BOOLEAN DEFAULT TRUE ;       -- 出庫形態
    lb_dispflg_ship_cd     BOOLEAN DEFAULT TRUE ;       -- 出庫元
    lb_dispflg_item_class  BOOLEAN DEFAULT TRUE ;       -- 品目区分
    lb_dispflg_ship_date   BOOLEAN DEFAULT TRUE ;       -- 出庫日
    lb_dispflg_lot_no      BOOLEAN DEFAULT TRUE ;       -- ロットNo
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- -----------------------------------------------------
    -- ヘッダ情報設定
    -- -----------------------------------------------------
    prc_set_tag_data('root') ;
    prc_set_tag_data('data_info') ;
    prc_set_tag_data('report_id', gc_report_id);
    prc_set_tag_data('exec_time', TO_CHAR(SYSDATE, gc_date_fmt_all));
    prc_set_tag_data('dep_cd', gv_dept_cd);
    prc_set_tag_data('dep_nm', gv_dept_nm);
    prc_set_tag_data('biz_kind', gv_biz_type_nm);
    prc_set_tag_data('lg_trans_type_info') ;
--
    -- -----------------------------------------------------
    -- 帳票0件用XMLデータ作成
    -- -----------------------------------------------------
    IF (gt_report_data.COUNT = 0) THEN
      ov_retcode := gv_status_warn ;
      ov_errmsg  := xxcmn_common_pkg.get_msg(gc_application_cmn, gc_msg_id_no_data) ;
--
      prc_set_tag_data('g_trans_type_info') ;
      prc_set_tag_data('lg_ship_cd_info') ;
      prc_set_tag_data('g_ship_cd_info') ;
      prc_set_tag_data('lg_item_class_info') ;
      prc_set_tag_data('g_item_class_info') ;
      prc_set_tag_data('lg_ship_date_info') ;
      prc_set_tag_data('g_ship_date_info') ;
      prc_set_tag_data('lg_lot_no_info') ;
      prc_set_tag_data('g_lot_no_info') ;
      prc_set_tag_data('msg', ov_errmsg) ;
      prc_set_tag_data('/g_lot_no_info') ;
      prc_set_tag_data('/lg_lot_no_info') ;
      prc_set_tag_data('/g_ship_date_info') ;
      prc_set_tag_data('/lg_ship_date_info') ;
      prc_set_tag_data('/g_item_class_info') ;
      prc_set_tag_data('/lg_item_class_info') ;
      prc_set_tag_data('/g_ship_cd_info') ;
      prc_set_tag_data('/lg_ship_cd_info') ;
      prc_set_tag_data('/g_trans_type_info') ;
    END IF ;
--
    -- -----------------------------------------------------
    -- XMLデータ作成
    -- -----------------------------------------------------
    <<set_data_loop>>
    FOR i IN 1..gt_report_data.COUNT LOOP
--
      -- ====================================================
      -- XMLデータ設定
      -- ====================================================
      -- 出庫形態グループ
      IF (lb_dispflg_trans_type) THEN
        prc_set_tag_data('g_trans_type_info') ;
        prc_set_tag_data('trans_type', gt_report_data(i).trans_type_name) ;
        prc_set_tag_data('lg_ship_cd_info') ;
      END IF ;
--
      -- 出庫元グループ
      IF (lb_dispflg_ship_cd) THEN
        prc_set_tag_data('g_ship_cd_info') ;
        prc_set_tag_data('ship_cd', gt_report_data(i).shipped_code) ;
        prc_set_tag_data('ship_nm', gt_report_data(i).shipped_name) ;
        prc_set_tag_data('lg_item_class_info') ;
      END IF ;
--
      -- 品目区分グループ
      IF (lb_dispflg_item_class) THEN
        prc_set_tag_data('g_item_class_info') ;
        prc_set_tag_data('item_class', gt_report_data(i).item_class_name) ;
        prc_set_tag_data('lg_ship_date_info') ;
      END IF ;
--
      -- 出庫日グループ
      IF (lb_dispflg_ship_date) THEN
        prc_set_tag_data('g_ship_date_info') ;
        prc_set_tag_data('ship_date', fnc_chgdt_c(gt_report_data(i).shipped_date)) ;
        prc_set_tag_data('lg_lot_no_info') ;
      END IF ;
--
      -- ロットNoグループ
      IF (lb_dispflg_lot_no) THEN
        prc_set_tag_data('g_lot_no_info') ;
        prc_set_tag_data('int_ext_class', gt_report_data(i).int_ext_class_name) ;
        prc_set_tag_data('item_cd', gt_report_data(i).item_code) ;
        prc_set_tag_data('item_nm', gt_report_data(i).item_name) ;
        prc_set_tag_data('lot_no', gt_report_data(i).lot_no) ;
        prc_set_tag_data('prod_date', gt_report_data(i).prod_date) ;
        prc_set_tag_data('best_before_date', gt_report_data(i).best_before_date) ;
        prc_set_tag_data('native_sign', gt_report_data(i).native_sign) ;
        prc_set_tag_data('lg_dtl_info') ;
      END IF ;
--
      -- 明細グループ
      prc_set_tag_data('g_dtl_info') ;
      prc_set_tag_data('base_nm', gt_report_data(i).base_nm) ;
      prc_set_tag_data('delivery_to_nm', gt_report_data(i).delivery_to_name) ;
      prc_set_tag_data('req_move_no', gt_report_data(i).req_move_no) ;
      prc_set_tag_data('arrive_date', fnc_chgdt_c(gt_report_data(i).arrive_date)) ;
      prc_set_tag_data('description', gt_report_data(i).description) ;
      prc_set_tag_data('qty', gt_report_data(i).qty) ;
      prc_set_tag_data('qty_tani', gt_report_data(i).qty_tani) ;
      prc_set_tag_data('/g_dtl_info') ;
--
      -- ====================================================
      -- 現在処理中のデータを保持
      -- ====================================================
      lv_tmp_trans_type   :=  gt_report_data(i).trans_type_id ;     -- 出庫形態
      lv_tmp_ship_cd      :=  gt_report_data(i).shipped_code ;      -- 出庫元
      lv_tmp_item_class   :=  gt_report_data(i).item_class_code ;   -- 品目区分
      lv_tmp_ship_date    :=  gt_report_data(i).shipped_date ;      -- 出庫日
      lv_tmp_lot_no       :=  gt_report_data(i).lot_no ;            -- ロットNo
      lv_tmp_item_code    :=  gt_report_data(i).item_code ;         -- 品目コード 2008/07/10 Fukuda Add
--
      -- ====================================================
      -- 出力判定
      -- ====================================================
      IF (i < gt_report_data.COUNT) THEN
        -- ロットNo
  -- 2008/08/05 v1.4 UPDATE START
/*        -- 2008/07/10 Fukuda Start 品目が違ってもロットNo.がNULLだと一括りで出力されてしまう
        --IF ( (lv_tmp_lot_no = gt_report_data(i + 1).lot_no)
        --  OR ((lv_tmp_lot_no IS NULL) AND (gt_report_data(i + 1).lot_no IS NULL)) ) THEN
        IF (lv_tmp_lot_no = gt_report_data(i + 1).lot_no)
          AND (lv_tmp_item_code = gt_report_data(i + 1).item_code) THEN
*/        -- 2008/07/10 Fukuda End
        -- 品目コードが同じ、かつロットNo.が同じか互いにNULLの場合
        IF (
             (lv_tmp_item_code = gt_report_data(i + 1).item_code)
               AND (
                     (lv_tmp_lot_no = gt_report_data(i + 1).lot_no)
                     OR
                     (
                       (lv_tmp_lot_no IS NULL)
                         AND (gt_report_data(i + 1).lot_no IS NULL)
                     )
                   )
           ) THEN
-- 2008/08/05 v1.4 UPDATE END
          lb_dispflg_lot_no := FALSE ;
        ELSE
          lb_dispflg_lot_no := TRUE ;
        END IF ;
--
        -- 出庫日
        IF (lv_tmp_ship_date = gt_report_data(i + 1).shipped_date) THEN
          lb_dispflg_ship_date := FALSE ;
        ELSE
          lb_dispflg_ship_date := TRUE ;
          lb_dispflg_lot_no    := TRUE ;
        END IF ;
--
        -- 品目区分
        IF (lv_tmp_item_class = gt_report_data(i + 1).item_class_code) THEN
          lb_dispflg_item_class := FALSE ;
        ELSE
          lb_dispflg_item_class := TRUE ;
          lb_dispflg_ship_date  := TRUE ;
          lb_dispflg_lot_no     := TRUE ;
        END IF ;
--
        -- 出庫元
        IF (lv_tmp_ship_cd = gt_report_data(i + 1).shipped_code) THEN
          lb_dispflg_ship_cd := FALSE ;
        ELSE
          lb_dispflg_ship_cd    := TRUE ;
          lb_dispflg_item_class := TRUE ;
          lb_dispflg_ship_date  := TRUE ;
          lb_dispflg_lot_no     := TRUE ;
        END IF ;
--
        -- 出庫形態
        IF ( (lv_tmp_trans_type = gt_report_data(i + 1).trans_type_id)
          OR ((lv_tmp_trans_type IS NULL) AND (gt_report_data(i + 1).trans_type_id IS NULL)) ) THEN
          lb_dispflg_trans_type := FALSE ;
        ELSE
          lb_dispflg_trans_type := TRUE ;
          lb_dispflg_ship_cd    := TRUE ;
          lb_dispflg_item_class := TRUE ;
          lb_dispflg_ship_date  := TRUE ;
          lb_dispflg_lot_no     := TRUE ;
        END IF ;
--
      ELSE
          lb_dispflg_trans_type := TRUE ;
          lb_dispflg_ship_cd    := TRUE ;
          lb_dispflg_item_class := TRUE ;
          lb_dispflg_ship_date  := TRUE ;
          lb_dispflg_lot_no     := TRUE ;
      END IF;
--
      -- ====================================================
      -- 終了タグ設定
      -- ====================================================
      -- ロットNo
      IF (lb_dispflg_lot_no) THEN
        prc_set_tag_data('/lg_dtl_info') ;
        prc_set_tag_data('/g_lot_no_info') ;
      END IF;
--
      -- 出庫日
      IF (lb_dispflg_ship_date) THEN
        prc_set_tag_data('/lg_lot_no_info') ;
        prc_set_tag_data('/g_ship_date_info') ;
      END IF;
--
      -- 品目区分
      IF (lb_dispflg_item_class) THEN
        prc_set_tag_data('/lg_ship_date_info') ;
        prc_set_tag_data('/g_item_class_info') ;
      END IF;
--
      -- 出庫元
      IF (lb_dispflg_ship_cd) THEN
        prc_set_tag_data('/lg_item_class_info') ;
        prc_set_tag_data('/g_ship_cd_info') ;
      END IF;
--
      -- 出庫形態
      IF (lb_dispflg_trans_type) THEN
        prc_set_tag_data('/lg_ship_cd_info') ;
        prc_set_tag_data('/g_trans_type_info') ;
      END IF;
--
    END LOOP set_data_loop;
--
    -- ====================================================
    -- 終了タグ設定
    -- ====================================================
    prc_set_tag_data('/lg_trans_type_info') ;
    prc_set_tag_data('/data_info') ;
    prc_set_tag_data('/root') ;
--
  EXCEPTION
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END prc_create_xml_data;
--
  /**********************************************************************************
   * Function Name    : fnc_convert_into_xml
   * Description      : XMLデータ変換
   ***********************************************************************************/
  FUNCTION fnc_convert_into_xml(
    ir_xml  IN  xml_rec
  ) RETURN VARCHAR2
  IS
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル変数 ***
    lv_data VARCHAR2(2000);
--
  BEGIN
--
    --データの場合
    IF (ir_xml.tag_type = 'D') THEN
      lv_data := '<'|| ir_xml.tag_name || '><![CDATA[' || ir_xml.tag_value || ']]></' || ir_xml.tag_name || '>';
    ELSE
      lv_data := '<' || ir_xml.tag_name || '>';
    END IF ;
--
    RETURN(lv_data);
--
  END fnc_convert_into_xml;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf     OUT   VARCHAR2      -- エラー・メッセージ           --# 固定 #
   ,ov_retcode    OUT   VARCHAR2      -- リターン・コード             --# 固定 #
   ,ov_errmsg     OUT   VARCHAR2      -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
--
--#####################  固定ローカル定数変数宣言部 START   ####################
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'submain' ;  -- プログラム名
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
    -- *** ローカル変数 ***
    ln_retcode       NUMBER ;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ===============================================
    -- 初期処理
    -- ===============================================
    prc_initialize(
      ov_errbuf     => lv_errbuf       -- エラー・メッセージ           --# 固定 #
     ,ov_retcode    => lv_retcode      -- リターン・コード             --# 固定 #
     ,ov_errmsg     => lv_errmsg       -- ユーザー・エラー・メッセージ --# 固定 #
    ) ;
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt ;
    END IF ;
--
    -- ===============================================
    -- 帳票データ取得処理
    -- ===============================================
    prc_get_report_data(
      ov_errbuf        => lv_errbuf       --エラー・メッセージ           --# 固定 #
     ,ov_retcode       => lv_retcode      --リターン・コード             --# 固定 #
     ,ov_errmsg        => lv_errmsg       --ユーザー・エラー・メッセージ --# 固定 #
    );
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt ;
    END IF ;
--
    -- ==================================================
    -- XML生成処理
    -- ==================================================
    prc_create_xml_data(
      ov_errbuf        => lv_errbuf       --エラー・メッセージ           --# 固定 #
     ,ov_retcode       => lv_retcode      --リターン・コード             --# 固定 #
     ,ov_errmsg        => lv_errmsg       --ユーザー・エラー・メッセージ --# 固定 #
    );
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt ;
    END IF ;
--
    -- ==================================================
    -- XML出力処理
    -- ==================================================
    -- XMLヘッダ部出力
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '<?xml version="1.0" encoding="shift_jis" ?>') ;
--
    -- XMLデータ部出力
    <<xml_loop>>
    FOR i IN 1 .. gt_xml_data_table.COUNT LOOP
      -- XMLデータ出力
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, fnc_convert_into_xml(gt_xml_data_table(i))) ;
    END LOOP xml_loop ;
--
    --XMLデータ削除
    gt_xml_data_table.DELETE ;
--
    IF ((lv_retcode = gv_status_warn) AND (gt_report_data.COUNT = 0)) THEN
      RAISE no_data_expt ;
    END IF ;
--
  EXCEPTION
    -- *** 帳票0件例外ハンドラ ***
    WHEN no_data_expt THEN
      ov_errmsg  := lv_errmsg ;
      ov_errbuf  := lv_errmsg ;
      ov_retcode := gv_status_warn;
--
--#################################  固定例外処理部 START   ###################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
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
     errbuf                 OUT    VARCHAR2      -- エラー・メッセージ  --# 固定 #
    ,retcode                OUT    VARCHAR2      -- リターン・コード    --# 固定 #
    ,iv_biz_type            IN     VARCHAR2      -- 01:業務種別  ※必須
    ,iv_ship_type           IN     VARCHAR2      -- 02:出庫形態
    ,iv_block               IN     VARCHAR2      -- 03:ブロック
    ,iv_shipped_cd          IN     VARCHAR2      -- 04:出庫元
    ,iv_delivery_to         IN     VARCHAR2      -- 05:配送先／入庫先
    ,iv_prod_class          IN     VARCHAR2      -- 06:商品区分  ※必須
    ,iv_item_class          IN     VARCHAR2      -- 07:品目区分
    ,iv_shipped_date        IN     VARCHAR2      -- 08:出庫日    ※必須
  )
--
--###########################  固定部 START   ###########################
--
  IS
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'main' ; -- プログラム名
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
  BEGIN
--
--###########################  固定部 END   #############################
--
    -- ===============================================
    -- 変数初期設定
    -- ===============================================
    -- 入力パラメータをグローバル変数に保持
    gt_param.biz_type      :=  iv_biz_type ;                      -- 01:業務種別  ※必須
    gt_param.ship_type     :=  iv_ship_type ;                     -- 02:出庫形態
    gt_param.block         :=  iv_block ;                         -- 03:ブロック
    gt_param.shipped_cd    :=  iv_shipped_cd ;                    -- 04:出庫元
    gt_param.delivery_to   :=  iv_delivery_to ;                   -- 05:配送先／入庫先
    gt_param.prod_class    :=  iv_prod_class ;                    -- 06:商品区分  ※必須
    gt_param.item_class    :=  iv_item_class ;                    -- 07:品目区分
    gt_param.shipped_date  :=  fnc_chgdt_d(iv_shipped_date) ;     -- 08:出庫日    ※必須
--
    -- ===============================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ===============================================
    submain(
      ov_errbuf    => lv_errbuf       -- エラー・メッセージ           --# 固定 #
     ,ov_retcode   => lv_retcode      -- リターン・コード             --# 固定 #
     ,ov_errmsg    => lv_errmsg       -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
--###########################  固定部 START   #####################################################
--
    -- ======================
    -- エラー・メッセージ出力
    -- ======================
    IF ( lv_retcode = gv_status_error ) THEN
      errbuf := lv_errmsg ;
      FND_FILE.PUT_LINE(FND_FILE.LOG, lv_errbuf) ;
--
    ELSIF ( lv_retcode = gv_status_warn ) THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG, lv_errbuf) ;
--
    END IF ;
--
    --ステータスセット
    retcode := lv_retcode ;
--
  EXCEPTION
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      errbuf  := gc_pkg_name || gv_msg_cont || cv_prg_name || gv_msg_part|| SQLERRM ;
      retcode := gv_status_error ;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      errbuf  := gc_pkg_name || gv_msg_cont || cv_prg_name || gv_msg_part || SQLERRM ;
      retcode := gv_status_error ;
  END main;
--
--###########################  固定部 END   #######################################################
--
END xxwsh620007c;
/
