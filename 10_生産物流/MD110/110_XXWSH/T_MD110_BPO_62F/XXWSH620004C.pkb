CREATE OR REPLACE PACKAGE BODY xxwsh620004c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxwsh620004c(body)
 * Description      : 倉庫払出指示書
 * MD.050           : 引当/配車(帳票) T_MD050_BPO_621
 * MD.070           : 倉庫払出指示書  T_MD070_BPO_62F
 * Version          : 1.5
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  prc_initialize         PROCEDURE : 初期処理
 *  prc_get_report_data    PROCEDURE : 帳票データ取得処理
 *  prc_create_xml_data    PROCEDURE : XML生成処理
 *  fnc_convert_into_xml   FUNCTION  : XMLデータ変換
 *  submain                PROCEDURE : メイン処理プロシージャ
 *  main                   PROCEDURE : コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/05/02    1.0   Yuki Komikado    新規作成
 *  2008/06/24    1.1   Masayoshi Uehara   支給の場合、パラメータ配送先/入庫先のリレーションを
 *                                         vendor_site_codeに変更。
 *  2008/07/02    1.2   Satoshi Yunba    禁則文字対応
 *  2008/07/18    1.3   Hitomi Itou      ST不具合#465対応 出庫元・ブロックの抽出条件を変更
 *  2008/08/07    1.4   Akiyoshi Shiina  内部変更要求#168,#183対応
 *  2008/10/20    1.5   Masayoshi Uehara T_TE080_BPO_620 指摘44(品目、ロット単位に合計して算出)
 *                                       課題#62変更#168 指示無し実績の帳票出力制御
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
  no_data_expt       EXCEPTION;
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  gv_pkg_name                CONSTANT  VARCHAR2(100) := 'xxwsh620004c' ;     -- パッケージ名
  gc_report_id               CONSTANT  VARCHAR2(12) := 'XXWSH620004T' ;      -- 帳票ID
  -- ステータス
  gc_req_status_shimezumi    CONSTANT  VARCHAR2(2)  := '03' ;                 -- 締め済み
  gc_req_status_juryozumi    CONSTANT  VARCHAR2(2)  := '07' ;                 -- 受領済
  gc_req_status_torikeshi    CONSTANT  VARCHAR2(2)  := '99' ;                 -- 取消
  -- 最新フラグ
  gc_latest_external_flag    CONSTANT  VARCHAR2(1)  := 'Y' ;
  -- 出荷支給区分 
  gc_shipping_shikyu_syukka  CONSTANT  VARCHAR2(1)  := '1' ;                  -- 出荷依頼
  gc_shipping_shikyu_shikyu  CONSTANT  VARCHAR2(1)  := '2' ;                  -- 支給依頼
  -- 受注カテゴリ
  gc_order_category_code     CONSTANT  VARCHAR2(6)  := 'RETURN' ;             -- 返品
  -- 削除フラグ
  gc_delete_flag             CONSTANT  VARCHAR2(1)  := 'Y' ;
-- ADD START 2008/10/20 1.5
  -- 指示なし実績区分
  gc_no_instr_actual_class   CONSTANT  VARCHAR2(1)  := 'Y' ;                 -- 指示なし実績
-- ADD END 2008/10/20 1.5
  -- 文書タイプ
  gc_doc_type_code_mv        CONSTANT  VARCHAR2(2)  := '20' ;                -- 移動
  gc_doc_type_code_syukka    CONSTANT  VARCHAR2(2)  := '10' ;                -- 出荷依頼
  gc_doc_type_code_shikyu    CONSTANT  VARCHAR2(2)  := '30' ;                -- 支給指示
  -- レコードタイプ
  gc_rec_type_code_ins       CONSTANT  VARCHAR2(2)  := '10' ;                -- 指示
  -- クイックコード
  gc_lookup_type_621b_int    CONSTANT  VARCHAR2(30) := 'XXWSH_621B_INT_EXT_CLASS' ;
  -- 移動タイプ
  gc_mov_type_not_ship       CONSTANT  VARCHAR2(5)  := '2' ;                 -- 積送なし
  -- 移動ステータス
  gc_status_reqed            CONSTANT  VARCHAR2(2)  := '02' ;                -- 依頼済
  gc_status_not              CONSTANT  VARCHAR2(2)  := '99' ;                -- 取消
  -- 商品区分
  gc_item_cd_prdct           CONSTANT  VARCHAR2(1)  := '5' ;                 -- 製品
  -- 日付フォーマット
  gc_date_fmt_all            CONSTANT  VARCHAR2(21) := 'YYYY/MM/DD HH24:MI:SS' ; -- 年月日時分秒
  gc_date_fmt_ymd            CONSTANT  VARCHAR2(10) := 'YYYY/MM/DD' ;            -- 年月日
  -- 出力タグ
  gc_tag_type_tag            CONSTANT  VARCHAR2(1)  := 'T' ;                 -- グループタグ
  gc_tag_type_data           CONSTANT  VARCHAR2(1)  := 'D' ;                 -- データタグ
  -- 業務種別
  gc_biz_type_cd_ship        CONSTANT  VARCHAR2(1)  := '1' ;        -- 出荷
  gc_biz_type_cd_shikyu      CONSTANT  VARCHAR2(1)  := '2' ;        -- 支給
  gc_biz_type_cd_move        CONSTANT  VARCHAR2(1)  := '3' ;        -- 移動
  gc_biz_type_nm_ship        CONSTANT  VARCHAR2(4)  := '出荷' ;     -- 出荷
  gc_biz_type_nm_shik        CONSTANT  VARCHAR2(4)  := '支給' ;     -- 支給
  gc_biz_type_nm_move        CONSTANT  VARCHAR2(4)  := '移動' ;     -- 移動
--
  ------------------------------
  -- エラーメッセージ関連
  ------------------------------
  --アプリケーション名
  gc_application_wsh         CONSTANT VARCHAR2(5)   := 'XXWSH' ;             -- ｱﾄﾞｵﾝ:出荷･引当･配車
  gc_application_cmn         CONSTANT VARCHAR2(5)   := 'XXCMN' ;             -- ｱﾄﾞｵﾝ:出荷･引当･配車
  --メッセージID
  gc_msg_id_required         CONSTANT  VARCHAR2(15) := 'APP-XXWSH-12452' ;   -- ﾊﾟﾗﾒｰﾀﾁｪｯｸｴﾗｰ
  gc_msg_id_no_data          CONSTANT  VARCHAR2(15) := 'APP-XXCMN-10122' ;   -- 帳票0件エラー
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  ------------------------------
  -- 入力パラメータ関連
  ------------------------------
  -- 入力パラメータ格納用レコード
  TYPE rec_param_data IS RECORD(
     business_typ       VARCHAR2(4)     -- 01 : 業務種別
    ,deliver_type       NUMBER          -- 02 : 出庫形態
    ,block              VARCHAR2(6)     -- 03 : ブロック
    ,deliver_from       VARCHAR2(9)     -- 04 : 出庫元
    ,deliver_to         VARCHAR2(9)     -- 05 : 配送先／入庫先
    ,prod_div           VARCHAR2(2)     -- 06 : 商品区分
    ,item_div           VARCHAR2(2)     -- 07 : 品目区分
    ,date_from          DATE            -- 08 : 出庫日
  );
  type_rec_param_data   rec_param_data ;
--
  ------------------------------
  -- 出力データ関連
  ------------------------------
  -- レコード宣言用
  xoha    xxwsh_order_headers_all%ROWTYPE ;         -- 受注ヘッダアドオン
  xott2v  xxwsh_oe_transaction_types2_v%ROWTYPE ;   -- 受注タイプ情報VIEW2
  xola    xxwsh_order_lines_all%ROWTYPE ;           -- 受注明細アドオン
  xim2v   xxcmn_item_mst2_v%ROWTYPE ;               -- OPM品目情報VIEW2
-- 2008/08/07 v1.4 UPDATE START
--  xic3v   xxcmn_item_categories3_v%ROWTYPE ;        -- OPM品目カテゴリ割当情報VIEW3
  xic2v   xxcmn_item_categories2_v%ROWTYPE ;        -- OPM品目カテゴリ割当情報VIEW2
-- 2008/08/07 v1.4 UPDATE END
  xmld    xxinv_mov_lot_details%ROWTYPE ;           -- 移動ロット詳細(アドオン)
  ilm     ic_lots_mst%ROWTYPE ;                     -- OPMロットマスタ
  xil2v   xxcmn_item_locations2_v%ROWTYPE ;         -- OPM保管場所情報VIEW2
  xlv2v   xxcmn_lookup_values2_v%ROWTYPE ;          -- クイックコード情報VIEW2
  xcas2v  xxcmn_cust_acct_sites2_v%ROWTYPE ;        -- 顧客サイト情報VIEW2
--
  -- 出力データ格納用レコード
  TYPE rec_report_data IS RECORD(
       trans_type            xott2v.transaction_type_name%TYPE  -- 出庫形態
      ,ship_cd               xoha.deliver_from%TYPE             -- 出庫元
      ,ship_nm               xil2v.description%TYPE             -- 出庫元(名称)
      ,delivery_to_cd        xoha.deliver_to%TYPE               -- 配送先/入庫先（コード）
      ,delivery_to_nm        xcas2v.party_site_full_name%TYPE   -- 配送先/入庫先（名称）
-- 2008/08/07 v1.4 UPDATE START
--      ,item_class            xic3v.item_class_name%TYPE         -- 品目区分名
      ,item_class            xic2v.description%TYPE             -- 品目区分名
-- 2008/08/07 v1.4 UPDATE END
      ,ship_date             xoha.schedule_ship_date%TYPE       -- 出庫日
-- 2008/08/07 v1.4 UPDATE START
--      ,in_out_class_code     xic3v.int_ext_class%TYPE           -- 内外区分（自社他社区分コード）
      ,in_out_class_code     xic2v.segment1%TYPE                -- 内外区分（自社他社区分コード）
-- 2008/08/07 v1.4 UPDATE END
      ,int_ext_class         xlv2v.meaning%TYPE                 -- 内外区分
      ,item_cd               xola.shipping_item_code%TYPE       -- 品目（コード）
      ,item_nm               xim2v.item_short_name%TYPE         -- 品目（名称）
      ,qty                   xola.quantity%TYPE                 -- 合計数
      ,qty_tani              xim2v.item_um%TYPE                 -- 入出庫換算単位
      ,lot_no                xmld.lot_no%TYPE                   -- ロットNo
      ,prod_date             ilm.attribute1%TYPE                -- 製造日
      ,best_before_date      ilm.attribute3%TYPE                -- 賞味期限
      ,native_sign           ilm.attribute2%TYPE                -- 固有記号
      ,trans_type_id         xoha.order_type_id%TYPE            -- 出庫形態(ID)
-- 2008/08/07 v1.4 UPDATE START
--      ,item_class_code       xic3v.item_class_code%TYPE         -- 品目区分コード
      ,item_class_code       xic2v.segment1%TYPE                -- 品目区分コード
-- 2008/08/07 v1.4 UPDATE END
  );
  type_report_data      rec_report_data;
  TYPE list_report_data IS TABLE OF rec_report_data INDEX BY BINARY_INTEGER ;
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gt_param              rec_param_data ;      -- 入力パラメータ情報
  gt_report_data        list_report_data ;    -- 出力データ
  gt_xml_data_table     XML_DATA ;            -- XMLデータ
  gv_dept_cd            VARCHAR2(10) ;        -- 担当部署
  gv_dept_nm            VARCHAR2(14) ;        -- 担当者
  gv_biz_kind           VARCHAR2(10) ;        -- 業務種別
  gd_common_sysdate     DATE;                 -- システム日付
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
    prm_check_expt     EXCEPTION ;     -- パラメータチェック例外
    get_prof_expt      EXCEPTION ;     -- プロファイル取得例外
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
    -- 変数初期設定
    -- ===============================================
    gd_common_sysdate := SYSDATE ;    -- システム日付
--
    -- ====================================================
    -- パラメータチェック
    -- ====================================================
    IF (( gt_param.deliver_from IS NULL ) AND ( gt_param.block IS NULL )) THEN
      -- メッセージセット
      lv_errmsg := xxcmn_common_pkg.get_msg( gc_application_wsh
                                            ,gc_msg_id_required
                                           ) ;
      RAISE prm_check_expt ;
    END IF ;
--
  EXCEPTION
    --*** パラメータチェック例外ハンドラ ***
    WHEN prm_check_expt THEN
      ov_errmsg  := lv_errmsg ;
      ov_errbuf  := lv_errmsg ;
      ov_retcode := gv_status_error ;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
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
    CURSOR cur_ship_data
    IS
    SELECT
       xott2v.transaction_type_name         AS  trans_type        -- 出庫形態
      ,xoha.deliver_from                    AS  ship_cd           -- 出庫元
      ,xil2v.description                    AS  ship_nm           -- 出庫元(名称)
--MOD START 2008/10/20 1.5 
--      ,xoha.deliver_to                      AS  delivery_to_cd    -- 配送先/入庫先（コード）
--      ,xcas2v.party_site_full_name          AS  delivery_to_nm    -- 配送先/入庫先（名称）
      ,DECODE(gt_param.deliver_to
        ,NULL,NULL
        ,xoha.deliver_to)                  AS  delivery_to_cd    -- 配送先/入庫先（コード）
      ,DECODE(gt_param.deliver_to
        ,NULL,NULL
        ,xcas2v.party_site_full_name)       AS  delivery_to_nm    -- 配送先/入庫先（名称）
--MOD END 2008/10/20 1.5 
-- 2008/08/07 v1.4 UPDATE START
--      ,xic3v.item_class_name                AS  item_class        -- 品目区分名
      ,xic5v.item_class_name                AS  item_class        -- 品目区分名
-- 2008/08/07 v1.4 UPDATE END
      ,xoha.schedule_ship_date              AS  ship_date         -- 出庫日
-- 2008/08/07 v1.4 UPDATE START
--     ,xic3v.int_ext_class                  AS  in_out_class_code -- 内外区分（自社他社区分コード）
      ,mcb.attribute1                       AS  in_out_class_code -- 内外区分（自社他社区分コード）
-- 2008/08/07 v1.4 UPDATE END
      ,xlv2v.meaning                        AS  int_ext_class     -- 内外区分
      ,xola.shipping_item_code              AS  item_cd           -- 品目（コード）
      ,xim2v.item_short_name                AS  item_nm           -- 品目（名称）
      ,CASE                                     
        -- 引当されている場合
        WHEN ( SUM(xola.reserved_quantity) > 0 ) THEN
          CASE 
-- 2008/08/07 v1.4 UPDATE START
--            WHEN  ( ( xic3v.item_class_code = gc_item_cd_prdct )
            WHEN  ( ( xic5v.item_class_code = gc_item_cd_prdct )
-- 2008/08/07 v1.4 UPDATE END
            AND     ( xim2v.conv_unit IS NOT NULL  ) ) THEN
-- 2008/10/20 1.5 MOD START 品目/ロット単位に数量を合計
--              xmld.actual_quantity / TO_NUMBER(
              SUM(xmld.actual_quantity) / TO_NUMBER(
-- 2008/10/20 1.5 MOD END
                                                CASE
                                                  WHEN ( xim2v.num_of_cases > 0 ) THEN
                                                    xim2v.num_of_cases
                                                  ELSE
                                                    TO_CHAR(1)
                                                END
-- 2008/10/20 1.5 MOD START 品目/ロット単位に数量を合計
--                                              )
                                              )
-- 2008/10/20 1.5 MOD END
            ELSE
-- 2008/10/20 1.5 MOD START 品目/ロット単位に数量を合計
--              xmld.actual_quantity
              SUM(xmld.actual_quantity)
-- 2008/10/20 1.5 MOD END
            END
        -- 引当されていない場合
        WHEN  ( ( SUM(xola.reserved_quantity) IS NULL ) OR ( SUM(xola.reserved_quantity) = 0 ) ) THEN
          CASE 
-- 2008/08/07 v1.4 UPDATE START
--            WHEN  ( ( xic3v.item_class_code = gc_item_cd_prdct )
            WHEN  ( ( xic5v.item_class_code = gc_item_cd_prdct )
-- 2008/08/07 v1.4 UPDATE END
            AND     ( xim2v.conv_unit IS NOT NULL  ) ) THEN
-- 2008/10/20 1.5 MOD START 品目/ロット単位に数量を合計
--              xola.quantity / TO_NUMBER(
              SUM(xola.quantity) / TO_NUMBER(
-- 2008/10/20 1.5 MOD END
                                        CASE
                                          WHEN ( xim2v.num_of_cases > 0 ) THEN
                                            xim2v.num_of_cases
                                          ELSE
                                            TO_CHAR(1)
                                        END
-- 2008/10/20 1.5 MOD START 品目/ロット単位に数量を合計
--                                       )
                                       )
-- 2008/10/20 1.5 MOD END
            ELSE
-- 2008/10/20 1.5 MOD START 品目/ロット単位に数量を合計
--              xola.quantity
              SUM(xola.quantity)
-- 2008/10/20 1.5 MOD END
            END
        END                                 AS  qty               -- 合計数
      ,CASE
       -- 条件①
-- 2008/08/07 v1.4 UPDATE START
--       WHEN (    xic3v.item_class_code = gc_item_cd_prdct
       WHEN (    xic5v.item_class_code = gc_item_cd_prdct
-- 2008/08/07 v1.4 UPDATE END
             AND xim2v.conv_unit IS NOT NULL) THEN
         xim2v.conv_unit
       ELSE
         -- 条件②
         xim2v.item_um
       END                                  AS  qty_tani          -- 入出庫換算単位
      ,xmld.lot_no                          AS  lot_no            -- ロットNo
      ,ilm.attribute1                       AS  prod_date         -- 製造日
      ,ilm.attribute3                       AS  best_before_date  -- 賞味期限
      ,ilm.attribute2                       AS  native_sign       -- 固有記号
      ,xoha.order_type_id                   AS  order_type_id     -- 出庫形態（ID）
-- 2008/08/07 v1.4 UPDATE START
--      ,xic3v.item_class_code                AS  item_class_code   -- 品目区分コード
      ,xic5v.item_class_code                AS  item_class_code   -- 品目区分コード
-- 2008/08/07 v1.4 UPDATE END
    FROM
       xxwsh_order_headers_all                xoha                  -- 受注ヘッダアドオン
      ,xxwsh_oe_transaction_types2_v          xott2v                -- 受注タイプ情報VIEW2
      ,xxwsh_order_lines_all                  xola                  -- 受注明細アドオン
      ,xxcmn_item_mst2_v                      xim2v                 -- OPM品目情報VIEW2
-- 2008/08/07 v1.4 UPDATE START
--     ,xxcmn_item_categories3_v               xic3v                 -- OPM品目カテゴリ割当情報VIEW3
      ,xxcmn_item_categories5_v               xic5v                 -- OPM品目カテゴリ割当情報VIEW5
      ,gmi_item_categories                    gic
      ,mtl_categories_b                       mcb
      ,mtl_categories_tl                      mct
      ,mtl_category_sets_b                    mcsb
      ,mtl_category_sets_tl                   mcst
-- 2008/08/07 v1.4 UPDATE END
      ,xxinv_mov_lot_details                  xmld                  -- 移動ロット詳細(アドオン)
      ,ic_lots_mst                            ilm                   -- OPMロットマスタ
      ,xxcmn_item_locations2_v                xil2v                 -- OPM保管場所情報VIEW2
      ,xxcmn_cust_acct_sites2_v               xcas2v                -- 顧客サイト情報VIEW2
      ,xxcmn_lookup_values2_v                 xlv2v                 -- クイックコード情報VIEW2
    WHERE
      -------------------------------------------------------------------------------
      -- 受注ヘッダアドオン
      -------------------------------------------------------------------------------
            xoha.req_status                   >= gc_req_status_shimezumi  -- 締め済み
      AND   xoha.req_status                   <> gc_req_status_torikeshi  -- 取消
      AND   (gt_param.deliver_to IS NULL
             OR
             xoha.deliver_to                   = gt_param.deliver_to )
                                                                      -- パラメータ：配送先/入庫先
--Mod start 2008/07/18 H.Itou
--      AND (
--             (gt_param.deliver_from IS NULL
--              OR
--              xoha.deliver_from                = gt_param.deliver_from )  -- パラメータ：出庫元
--          OR
--             (gt_param.block IS NULL
--              OR
--              xil2v.distribution_block         = gt_param.block )         -- パラメータ：ブロック
--          )
      AND  (((gt_param.deliver_from IS NULL) AND  (gt_param.block IS NULL))  -- パラメータ：出庫元、パラメータ：ブロックがNULLの場合、条件としない。
        OR  xoha.deliver_from         =  gt_param.deliver_from               -- パラメータ：出庫元がNULLでない場合、条件に追加
        OR  xil2v.distribution_block  =  gt_param.block)                     -- パラメータ：ブロックがNULLでない場合、条件に追加
--Mod end 2008/07/18 H.Itou
      AND   TRUNC( xoha.schedule_ship_date )   = TRUNC( gt_param.date_from )  -- パラメータ：出庫日
-- 2008/10/20 v1.5 ADD START
      AND   xoha.schedule_ship_date IS NOT NULL
-- 2008/10/20 v1.5 ADD END
      AND   xoha.latest_external_flag          = gc_latest_external_flag
      -------------------------------------------------------------------------------
      -- 受注タイプ情報VIEW2
      -------------------------------------------------------------------------------
      AND   xoha.order_type_id                 = xott2v.transaction_type_id
      AND   xott2v.shipping_shikyu_class       = gc_shipping_shikyu_syukka    
                                                                          -- 出荷支給区分'出荷依頼'
      AND   xott2v.order_category_code        <> gc_order_category_code       -- 返品
      AND   (gt_param.deliver_type IS NULL
             OR
             xott2v.transaction_type_id        = gt_param.deliver_type )
                                                                            -- パラメータ：出庫形態
      -------------------------------------------------------------------------------
      -- 受注明細アドオン
      -------------------------------------------------------------------------------
      AND   xoha.order_header_id               = xola.order_header_id
      AND   xola.delete_flag                  <> gc_delete_flag
-- 2008/10/20 v1.5 DEL START
-- 2008/08/07 v1.4 ADD START
--      AND   xola.quantity                      > 0
-- 2008/08/07 v1.4 ADD END
-- 2008/10/20 v1.5 DEL END
      -------------------------------------------------------------------------------
      -- OPM品目情報VIEW2
      -------------------------------------------------------------------------------
      AND  xola.shipping_inventory_item_id     = xim2v.inventory_item_id
      AND xim2v.start_date_active             <= xoha.schedule_ship_date
      AND (
             (xim2v.end_date_active           >= xoha.schedule_ship_date)
          OR
             (xim2v.end_date_active IS NULL)
          )
-- 2008/08/07 v1.4 UPDATE START
--      -------------------------------------------------------------------------------
--      -- OPM品目カテゴリ割当情報VIEW3
--      -------------------------------------------------------------------------------
      -------------------------------------------------------------------------------
      -- OPM品目カテゴリ割当情報VIEW
      -------------------------------------------------------------------------------
--      AND xim2v.item_id                        = xic3v.item_id
      AND xim2v.item_id                        = xic5v.item_id
      AND mct.source_lang                      = 'JA'
      AND mct.language                         = 'JA'
      AND mcb.category_id                      = mct.category_id
      AND mcsb.structure_id                    = mcb.structure_id
      AND gic.category_id                      = mcb.category_id
      AND mcst.source_lang                     = 'JA'
      AND mcst.language                        = 'JA'
      AND mcst.category_set_name               = '内外区分'
      AND mcsb.category_set_id                 = mcst.category_set_id
      AND gic.category_set_id                  = mcsb.category_set_id
      AND xim2v.item_id                        = gic.item_id
-- 2008/08/07 v1.4 UPDATE END
      AND (gt_param.item_div IS NULL
           OR
-- 2008/08/07 v1.4 UPDATE START
--           xic3v.item_class_code               = gt_param.item_div )       -- パラメータ：品目区分
           xic5v.item_class_code               = gt_param.item_div )       -- パラメータ：品目区分
--      AND xic3v.prod_class_code                = gt_param.prod_div         -- パラメータ：商品区分
      AND xic5v.prod_class_code                = gt_param.prod_div         -- パラメータ：商品区分
-- 2008/08/07 v1.4 UPDATE END
      -------------------------------------------------------------------------------
      -- 移動ロット詳細(アドオン)
      -------------------------------------------------------------------------------
      AND   xola.order_line_id                 = xmld.mov_line_id(+)
      AND   xmld.document_type_code(+)         = gc_doc_type_code_syukka         -- 出荷依頼
      AND   xmld.record_type_code(+)           = gc_rec_type_code_ins            -- 指示
      -------------------------------------------------------------------------------
      -- OPMロットマスタ
      -------------------------------------------------------------------------------
      AND   xmld.lot_id                        = ilm.lot_id(+)
      AND   xmld.item_id                       = ilm.item_id(+)
      -------------------------------------------------------------------------------
      -- OPM保管場所情報VIEW2
      -------------------------------------------------------------------------------
      AND   xoha.deliver_from_id               = xil2v.inventory_location_id
      -------------------------------------------------------------------------------
      -- 顧客サイト情報VIEW2
      -------------------------------------------------------------------------------
      AND   xoha.deliver_to_id                 = xcas2v.party_site_id
      AND   xcas2v.start_date_active          <= xoha.schedule_ship_date
      AND   (
              xcas2v.end_date_active          >= xoha.schedule_ship_date
            OR
              xcas2v.end_date_active IS NULL
            )
      -------------------------------------------------------------------------------
      -- クイックコード情報VIEW2
      -------------------------------------------------------------------------------
      AND xlv2v.lookup_type = gc_lookup_type_621b_int
-- 2008/08/07 v1.4 UPDATE START
--     AND xlv2v.lookup_code = xic3v.int_ext_class                  -- 自社他社区分(1:自社、2:他社）
      AND xlv2v.lookup_code = mcb.attribute1                       -- 自社他社区分(1:自社、2:他社）
-- 2008/10/20 1.5 ADD START 品目/ロット単位に数量を合計
      GROUP BY
       xott2v.transaction_type_name    -- 出庫形態
        , xoha.order_type_id    
        ,xoha.deliver_from             -- 出庫元
        ,xil2v.description             -- 出庫元(名称)
        ,DECODE(gt_param.deliver_to
          ,NULL,NULL
          ,xoha.deliver_to)                 -- 配送先/入庫先（コード）
        ,DECODE(gt_param.deliver_to
          ,NULL,NULL
          ,xcas2v.party_site_full_name)       -- 配送先/入庫先（名称）
        ,xic5v.item_class_name          -- 品目区分名
        ,xoha.schedule_ship_date        -- 出庫日
        ,mcb.attribute1                 -- 内外区分（自社他社区分コード）
        ,xlv2v.meaning                  -- 内外区分
        ,xola.shipping_item_code        -- 品目（コード）
        ,xim2v.item_short_name          -- 品目（名称）
        ,xim2v.conv_unit                -- 入出庫換算単位
        ,xmld.lot_no                    -- ロットNo
        ,ilm.attribute1                 -- 製造日
        ,ilm.attribute3                 -- 賞味期限
        ,ilm.attribute2                 -- 固有記号
        ,xic5v.item_class_code          -- 品目クラスコード
        ,xim2v.num_of_cases             -- 入数
        ,xim2v.item_um                  -- 合計数_単位
-- 2008/10/20 1.5 ADD END
-- 2008/08/07 v1.4 UPDATE END
      ORDER BY
         xoha.order_type_id           ASC
        ,xoha.deliver_from            ASC
-- 2008/08/07 v1.4 UPDATE START
--        ,xic3v.item_class_code        ASC
--        ,xic3v.int_ext_class          ASC
        ,xic5v.item_class_code        ASC
        ,mcb.attribute1               ASC
-- 2008/08/07 v1.4 UPDATE END
        ,xola.shipping_item_code      ASC
        ,xmld.lot_no                  ASC
      ;
--
    CURSOR cur_shikyu_data
    IS
    SELECT
       xott2v.transaction_type_name         AS  trans_type        -- 出庫形態
      ,xoha.deliver_from                    AS  ship_cd           -- 出庫元
      ,xil2v.description                    AS  ship_nm           -- 出庫元(名称)
--MOD START 2008/10/20 1.5 
--      ,xoha.vendor_site_code                AS  delivery_to_cd    -- 配送先/入庫先（コード）
--      ,xvs2v.vendor_site_name               AS  delivery_to_nm    -- 配送先/入庫先（名称）
      ,DECODE(gt_param.deliver_to
        ,NULL,NULL
        ,xoha.vendor_site_code)             AS  delivery_to_cd    -- 配送先/入庫先（コード）
      ,DECODE(gt_param.deliver_to
        ,NULL,NULL
        ,xvs2v.vendor_site_name)            AS  delivery_to_nm   -- 配送先/入庫先（名称）
--MOD START 2008/10/20 1.5 
-- 2008/08/07 v1.4 UPDATE START
--      ,xic3v.item_class_name                AS  item_class        -- 品目区分名
      ,xic5v.item_class_name                AS  item_class        -- 品目区分名
-- 2008/08/07 v1.4 UPDATE END
      ,xoha.schedule_ship_date              AS  ship_date         -- 出庫日
-- 2008/08/07 v1.4 UPDATE START
--     ,xic3v.int_ext_class                  AS  in_out_class_code -- 内外区分（自社他社区分コード）
      ,mcb.attribute1                       AS  in_out_class_code -- 内外区分（自社他社区分コード）
-- 2008/08/07 v1.4 UPDATE END
      ,xlv2v.meaning                        AS  int_ext_class     -- 内外区分
      ,xola.shipping_item_code              AS  item_cd           -- 品目（コード）
      ,xim2v.item_short_name                AS  item_nm           -- 品目（名称）
-- 2008/10/20 1.5 MOD START 品目/ロット単位に数量を合計
--      ,CASE                                     
--        -- 引当されている場合
--        WHEN ( xola.reserved_quantity > 0 ) THEN
--            xmld.actual_quantity
--        -- 引当されていない場合
--        WHEN  ( ( xola.reserved_quantity IS NULL ) OR ( xola.reserved_quantity = 0 ) ) THEN
--            xola.quantity
--        END                                 AS  qty               -- 合計数
      ,CASE                                     
        -- 引当されている場合
        WHEN ( SUM(xola.reserved_quantity) > 0 ) THEN
            SUM(xmld.actual_quantity)
        -- 引当されていない場合
        WHEN  ( ( SUM(xola.reserved_quantity) IS NULL ) OR ( SUM(xola.reserved_quantity) = 0 ) ) THEN
            SUM(xola.quantity)
        END                                 AS  qty               -- 合計数
-- 2008/10/20 1.5 MOD END
      ,xim2v.item_um                        AS  qty_tani          -- 合計数_単位
      ,xmld.lot_no                          AS  lot_no            -- ロットNo
      ,ilm.attribute1                       AS  prod_date         -- 製造日
      ,ilm.attribute3                       AS  best_before_date  -- 賞味期限
      ,ilm.attribute2                       AS  native_sign       -- 固有記号
      ,xoha.order_type_id                   AS  trans_type_id     -- 出庫形態（ID）
-- 2008/08/07 v1.4 UPDATE START
--      ,xic3v.item_class_code                AS  item_class_code   -- 品目区分コード
      ,xic5v.item_class_code                AS  item_class_code   -- 品目区分コード
-- 2008/08/07 v1.4 UPDATE END
    FROM
       xxwsh_order_headers_all                xoha       -- 受注ヘッダアドオン
      ,xxwsh_oe_transaction_types2_v          xott2v     -- 受注タイプ情報VIEW2
      ,xxwsh_order_lines_all                  xola       -- 受注明細アドオン
      ,xxcmn_item_mst2_v                      xim2v      -- OPM品目情報VIEW2
-- 2008/08/07 v1.4 UPDATE START
--     ,xxcmn_item_categories3_v               xic3v                 -- OPM品目カテゴリ割当情報VIEW3
      ,xxcmn_item_categories5_v               xic5v                 -- OPM品目カテゴリ割当情報VIEW5
      ,gmi_item_categories                    gic
      ,mtl_categories_b                       mcb
      ,mtl_categories_tl                      mct
      ,mtl_category_sets_b                    mcsb
      ,mtl_category_sets_tl                   mcst
-- 2008/08/07 v1.4 UPDATE END
      ,xxinv_mov_lot_details                  xmld       -- 移動ロット詳細(アドオン)
      ,ic_lots_mst                            ilm        -- OPMロットマスタ
      ,xxcmn_item_locations2_v                xil2v      -- OPM保管場所情報VIEW2
      ,xxcmn_vendor_sites2_v                  xvs2v      -- 仕入先サイト情報VIEW2
      ,xxcmn_lookup_values2_v                 xlv2v      -- クイックコード情報VIEW2
    WHERE
      -------------------------------------------------------------------------------
      -- 受注ヘッダアドオン
      -------------------------------------------------------------------------------
            xoha.req_status                    >= gc_req_status_juryozumi  -- 受領済
      AND   (gt_param.deliver_to IS NULL
             OR
             --Mod start 2008/06/24 uehara
--             xoha.deliver_to                    = gt_param.deliver_to )
             xoha.vendor_site_code                    = gt_param.deliver_to )
             --Mod end 2008/06/24 uehara
                                                                       -- パラメータ：配送先/入庫先
      AND   xoha.req_status                    <> gc_req_status_torikeshi  -- 取消
--Mod start 2008/07/18 H.Itou
--      AND (
--             (gt_param.deliver_from IS NULL
--              OR
--              xoha.deliver_from                = gt_param.deliver_from )  -- パラメータ：出庫元
--          OR
--             (gt_param.block IS NULL
--              OR
--              xil2v.distribution_block         = gt_param.block )         -- パラメータ：ブロック
--          )
      AND  (((gt_param.deliver_from IS NULL) AND  (gt_param.block IS NULL))  -- パラメータ：出庫元、パラメータ：ブロックがNULLの場合、条件としない。
        OR  xoha.deliver_from         =  gt_param.deliver_from               -- パラメータ：出庫元がNULLでない場合、条件に追加
        OR  xil2v.distribution_block  =  gt_param.block)                     -- パラメータ：ブロックがNULLでない場合、条件に追加
--Mod end 2008/07/18 H.Itou
      AND   xoha.schedule_ship_date             = gt_param.date_from       -- パラメータ：出庫日
      AND   xoha.latest_external_flag           = gc_latest_external_flag
      -------------------------------------------------------------------------------
      -- 受注タイプ情報VIEW2
      -------------------------------------------------------------------------------
      AND   xoha.order_type_id                  = xott2v.transaction_type_id
      AND   xott2v.shipping_shikyu_class        = gc_shipping_shikyu_shikyu
                                                                          -- 出荷支給区分'支給依頼'
      AND   xott2v.order_category_code         <> gc_order_category_code  -- 返品
      AND   (gt_param.deliver_type IS NULL
             OR
             xott2v.transaction_type_id         = gt_param.deliver_type )   -- パラメータ：出庫形態
      -------------------------------------------------------------------------------
      -- 受注明細アドオン
      -------------------------------------------------------------------------------
      AND   xoha.order_header_id                = xola.order_header_id
      AND   xola.delete_flag                   <> gc_delete_flag
      -------------------------------------------------------------------------------
      -- OPM品目情報VIEW2
      -------------------------------------------------------------------------------
      AND  xola.shipping_inventory_item_id      = xim2v.inventory_item_id
      AND xim2v.start_date_active              <= xoha.schedule_ship_date
      AND (
             (xim2v.end_date_active            >= xoha.schedule_ship_date)
          OR
             (xim2v.end_date_active IS NULL)
          )
-- 2008/08/07 v1.4 UPDATE START
--      -------------------------------------------------------------------------------
--      -- OPM品目カテゴリ割当情報VIEW3
--      -------------------------------------------------------------------------------
      -------------------------------------------------------------------------------
      -- OPM品目カテゴリ割当情報VIEW
      -------------------------------------------------------------------------------
--      AND xim2v.item_id                        = xic3v.item_id
      AND xim2v.item_id                        = xic5v.item_id
      AND mct.source_lang                      = 'JA'
      AND mct.language                         = 'JA'
      AND mcb.category_id                      = mct.category_id
      AND mcsb.structure_id                    = mcb.structure_id
      AND gic.category_id                      = mcb.category_id
      AND mcst.source_lang                     = 'JA'
      AND mcst.language                        = 'JA'
      AND mcst.category_set_name               = '内外区分'
      AND mcsb.category_set_id                 = mcst.category_set_id
      AND gic.category_set_id                  = mcsb.category_set_id
      AND xim2v.item_id                        = gic.item_id
-- 2008/08/07 v1.4 UPDATE END
      AND (gt_param.item_div IS NULL
           OR
-- 2008/08/07 v1.4 UPDATE START
--           xic3v.item_class_code               = gt_param.item_div )       -- パラメータ：品目区分
           xic5v.item_class_code               = gt_param.item_div )       -- パラメータ：品目区分
--      AND xic3v.prod_class_code                = gt_param.prod_div         -- パラメータ：商品区分
      AND xic5v.prod_class_code                = gt_param.prod_div         -- パラメータ：商品区分
-- 2008/08/07 v1.4 UPDATE END
      -------------------------------------------------------------------------------
      -- 移動ロット詳細(アドオン)
      -------------------------------------------------------------------------------
      AND   xola.order_line_id                  = xmld.mov_line_id(+)
      AND   xmld.document_type_code(+)          = gc_doc_type_code_shikyu          -- 支給指示
      AND   xmld.record_type_code(+)            = gc_rec_type_code_ins             -- 指示
      -------------------------------------------------------------------------------
      -- OPMロットマスタ
      -------------------------------------------------------------------------------
      AND   xmld.lot_id                         = ilm.lot_id(+)
      AND   xmld.item_id                        = ilm.item_id(+)
      -------------------------------------------------------------------------------
      -- OPM保管場所情報VIEW2
      -------------------------------------------------------------------------------
      AND   xoha.deliver_from_id                = xil2v.inventory_location_id
      -------------------------------------------------------------------------------
      -- 仕入先サイト情報VIEW2
      -------------------------------------------------------------------------------
      AND xoha.vendor_site_id                   = xvs2v.vendor_site_id
      AND xvs2v.start_date_active              <= xoha.schedule_ship_date
      AND (
             xvs2v.end_date_active             >= xoha.schedule_ship_date
          OR
             xvs2v.end_date_active IS NULL
          )
      -------------------------------------------------------------------------------
      -- クイックコード情報VIEW2
      -------------------------------------------------------------------------------
      AND xlv2v.lookup_type                     = gc_lookup_type_621b_int
-- 2008/08/07 v1.4 UPDATE START
--      AND xlv2v.lookup_code                     = xic3v.int_ext_class
      AND xlv2v.lookup_code                     = mcb.attribute1
-- 2008/08/07 v1.4 UPDATE END
                                                             -- 自社他社区分(1:自社、2:他社）
-- 2008/10/20 1.5 ADD START 品目/ロット単位に数量を合計
      GROUP BY
        xott2v.transaction_type_name   -- 出庫形態
        ,xoha.deliver_from              -- 出庫元
        ,xil2v.description              -- 出庫元(名称)
        ,DECODE(gt_param.deliver_to
          ,NULL,NULL
          ,xoha.vendor_site_code)       -- 配送先/入庫先（コード）
        ,DECODE(gt_param.deliver_to
          ,NULL,NULL
          ,xvs2v.vendor_site_name)      -- 配送先/入庫先（名称）
        ,xic5v.item_class_name          -- 品目区分名
        ,xoha.schedule_ship_date        -- 出庫日
        ,mcb.attribute1                 -- 内外区分（自社他社区分コード）
        ,xlv2v.meaning                  -- 内外区分
        ,xola.shipping_item_code        -- 品目（コード）
        ,xim2v.item_short_name          -- 品目（名称）
        ,xim2v.item_um                  -- 合計数_単位
        ,xmld.lot_no                    -- ロットNo
        ,ilm.attribute1                 -- 製造日
        ,ilm.attribute3                 -- 賞味期限
        ,ilm.attribute2                 -- 固有記号
        ,xoha.order_type_id             -- 出庫形態（ID）
        ,xic5v.item_class_code          -- 品目区分コード
-- 2008/10/20 1.5 ADD END
      ORDER BY
         xoha.order_type_id           ASC
        ,xoha.deliver_from            ASC
-- 2008/08/07 v1.4 UPDATE START
--        ,xic3v.item_class_code        ASC
--        ,xic3v.int_ext_class          ASC
        ,xic5v.item_class_code        ASC
        ,mcb.attribute1               ASC
-- 2008/08/07 v1.4 UPDATE END
        ,xola.shipping_item_code      ASC
        ,xmld.lot_no                  ASC
      ;
--
    CURSOR cur_move_data
    IS
    SELECT
       NULL                                AS  trans_type        -- 出庫形態
      ,xmrih.shipped_locat_code            AS  ship_cd           -- 出庫元
      ,xil2v1.description                  AS  ship_nm           -- 出庫元(名称)
--MOD START 2008/10/20 1.5 
--      ,xmrih.ship_to_locat_code            AS  delivery_to_cd    -- 配送先/入庫先（コード）
--      ,xil2v2.description                  AS  delivery_to_nm    -- 配送先/入庫先（名称）
      ,DECODE(gt_param.deliver_to
        ,NULL,NULL
        ,xmrih.ship_to_locat_code)         AS  delivery_to_cd    -- 配送先/入庫先（コード）
      ,DECODE(gt_param.deliver_to
        ,NULL,NULL
        ,xil2v2.description)               AS  delivery_to_nm   -- 配送先/入庫先（名称）
--MOD END 2008/10/20 1.5 
-- 2008/08/07 v1.4 UPDATE START
--      ,xic3v.item_class_name                AS  item_class        -- 品目区分名
      ,xic5v.item_class_name                AS  item_class        -- 品目区分名
-- 2008/08/07 v1.4 UPDATE END
      ,xmrih.schedule_ship_date            AS  ship_date         -- 出庫日
-- 2008/08/07 v1.4 UPDATE START
--     ,xic3v.int_ext_class                  AS  in_out_class_code -- 内外区分（自社他社区分コード）
      ,mcb.attribute1                       AS  in_out_class_code -- 内外区分（自社他社区分コード）
-- 2008/08/07 v1.4 UPDATE END
      ,xlv2v.meaning                       AS  int_ext_class     -- 内外区分
      ,xmril.item_code                     AS  item_cd           -- 品目（コード）
      ,xim2v.item_short_name               AS  item_nm           -- 品目（名称）
-- 2008/10/20 1.5 MOD START 品目/ロット単位に数量を合計
--      ,CASE
--        -- 引当されている場合
--        WHEN ( xmril.reserved_quantity > 0 ) THEN
--          CASE 
---- 2008/08/07 v1.4 UPDATE START
----            WHEN  ( ( xic3v.item_class_code = gc_item_cd_prdct )
--            WHEN  ( ( xic5v.item_class_code = gc_item_cd_prdct )
---- 2008/08/07 v1.4 UPDATE END
--            AND     ( xim2v.conv_unit IS NOT NULL  ) ) THEN
--              xmld.actual_quantity / TO_NUMBER(
--                                                CASE
--                                                  WHEN ( xim2v.num_of_cases > 0 ) THEN
--                                                    xim2v.num_of_cases
--                                                  ELSE
--                                                    TO_CHAR(1)
--                                                END
--                                              )
--            ELSE
--              xmld.actual_quantity
--            END
--        -- 引当されていない場合
--        WHEN  ( ( xmril.reserved_quantity IS NULL ) OR ( xmril.reserved_quantity = 0 ) ) THEN
--          CASE 
---- 2008/08/07 v1.4 UPDATE START
----            WHEN  ( ( xic3v.item_class_code = gc_item_cd_prdct )
--            WHEN  ( ( xic5v.item_class_code = gc_item_cd_prdct )
---- 2008/08/07 v1.4 UPDATE END
--            AND     ( xim2v.conv_unit IS NOT NULL  ) ) THEN
--              xmril.instruct_qty / TO_NUMBER(
--                                        CASE
--                                          WHEN ( xim2v.num_of_cases > 0 ) THEN
--                                            xim2v.num_of_cases
--                                          ELSE
--                                            TO_CHAR(1)
--                                        END
--                                       )
----            ELSE
----              xmril.instruct_qty
----            END
----        END                                AS  qty               -- 合計数      
      ,CASE
        -- 引当されている場合
        WHEN ( SUM(xmril.reserved_quantity) > 0 ) THEN
          CASE 
-- 2008/08/07 v1.4 UPDATE START
--            WHEN  ( ( xic3v.item_class_code = gc_item_cd_prdct )
            WHEN  ( ( xic5v.item_class_code = gc_item_cd_prdct )
-- 2008/08/07 v1.4 UPDATE END
            AND     ( xim2v.conv_unit IS NOT NULL  ) ) THEN
              SUM(xmld.actual_quantity) / TO_NUMBER(
                                                CASE
                                                  WHEN ( xim2v.num_of_cases > 0 ) THEN
                                                    xim2v.num_of_cases
                                                  ELSE
                                                    TO_CHAR(1)
                                                END
                                              )
            ELSE
              SUM(xmld.actual_quantity)
            END
        -- 引当されていない場合
        WHEN  ( ( SUM(xmril.reserved_quantity) IS NULL ) OR ( SUM(xmril.reserved_quantity) = 0 ) ) THEN
          CASE 
-- 2008/08/07 v1.4 UPDATE START
--            WHEN  ( ( xic3v.item_class_code = gc_item_cd_prdct )
            WHEN  ( ( xic5v.item_class_code = gc_item_cd_prdct )
-- 2008/08/07 v1.4 UPDATE END
            AND     ( xim2v.conv_unit IS NOT NULL  ) ) THEN
              SUM(xmril.instruct_qty) / TO_NUMBER(
                                        CASE
                                          WHEN ( xim2v.num_of_cases > 0 ) THEN
                                            xim2v.num_of_cases
                                          ELSE
                                            TO_CHAR(1)
                                        END
                                       )
            ELSE
              SUM(xmril.instruct_qty)
            END
        END                                AS  qty               -- 合計数
-- 2008/10/20 1.5 MOD END
      ,CASE
       -- 条件①
-- 2008/08/07 v1.4 UPDATE START
--       WHEN (    xic3v.item_class_code = gc_item_cd_prdct
       WHEN (    xic5v.item_class_code = gc_item_cd_prdct
-- 2008/08/07 v1.4 UPDATE END
             AND xim2v.conv_unit IS NOT NULL) THEN
         xim2v.conv_unit
       ELSE
         -- 条件②
         xim2v.item_um
       END                                 AS  qty_tani          -- 合計数_単位
      ,xmld.lot_no                         AS  lot_no            -- ロットNo
      ,ilm.attribute1                      AS  prod_date         -- 製造日
      ,ilm.attribute3                      AS  best_before_date  -- 賞味期限
      ,ilm.attribute2                      AS  native_sign       -- 固有記号
      ,NULL                                AS  order_type_id     -- 出庫形態(ID)
-- 2008/08/07 v1.4 UPDATE START
--      ,xic3v.item_class_code                AS  item_class_code   -- 品目区分コード
      ,xic5v.item_class_code                AS  item_class_code   -- 品目区分コード
-- 2008/08/07 v1.4 UPDATE END
    FROM
       xxinv_mov_req_instr_headers            xmrih            -- 移動依頼/指示ヘッダアドオン
      ,xxinv_mov_req_instr_lines              xmril            -- 移動依頼/指示明細(アドオン)
      ,xxcmn_item_mst2_v                      xim2v            -- OPM品目情報VIEW2
-- 2008/08/07 v1.4 UPDATE START
--     ,xxcmn_item_categories3_v               xic3v                 -- OPM品目カテゴリ割当情報VIEW3
      ,xxcmn_item_categories5_v               xic5v                 -- OPM品目カテゴリ割当情報VIEW5
      ,gmi_item_categories                    gic
      ,mtl_categories_b                       mcb
      ,mtl_categories_tl                      mct
      ,mtl_category_sets_b                    mcsb
      ,mtl_category_sets_tl                   mcst
-- 2008/08/07 v1.4 UPDATE END
      ,xxinv_mov_lot_details                  xmld             -- 移動ロット詳細(アドオン)
      ,ic_lots_mst                            ilm              -- OPMロットマスタ
      ,xxcmn_item_locations2_v                xil2v1           -- OPM保管場所情報VIEW2-1
      ,xxcmn_item_locations2_v                xil2v2           -- OPM保管場所情報VIEW2-2
      ,xxcmn_lookup_values2_v                 xlv2v            -- クイックコード情報VIEW2
    WHERE
      -------------------------------------------------------------------------------
      -- 移動依頼/指示ヘッダアドオン
      -------------------------------------------------------------------------------
          xmrih.mov_type                       <> gc_mov_type_not_ship      -- 積送無しでない
      AND xmrih.status                         >= gc_status_reqed           -- 依頼済以上
      AND xmrih.status                         <> gc_status_not             -- 取消を含まない
      AND (gt_param.deliver_to IS NULL
           OR
           xmrih.ship_to_locat_code             = gt_param.deliver_to )
                                                                      -- パラメータ：配送先/入庫先
--Mod start 2008/07/18 H.Itou
--      AND (
--             (gt_param.deliver_from IS NULL
--              OR
--              xmrih.shipped_locat_code          = gt_param.deliver_from )   -- パラメータ：出庫元
--          OR
--             (gt_param.block IS NULL
--              OR
--              xil2v1.distribution_block         = gt_param.block )          -- パラメータ：ブロック
--          )
      AND  (((gt_param.deliver_from IS NULL) AND  (gt_param.block IS NULL))  -- パラメータ：出庫元、パラメータ：ブロックがNULLの場合、条件としない。
        OR  xmrih.shipped_locat_code   =  gt_param.deliver_from               -- パラメータ：出庫元がNULLでない場合、条件に追加
        OR  xil2v1.distribution_block  =  gt_param.block)                     -- パラメータ：ブロックがNULLでない場合、条件に追加
--Mod end 2008/07/18 H.Itou
      AND xmrih.schedule_ship_date              = gt_param.date_from        -- パラメータ：出庫日
--ADD START 2008/10/20 1.5 指示なし実績を除外
      AND (xmrih.no_instr_actual_class IS NULL
        OR xmrih.no_instr_actual_class  <> gc_no_instr_actual_class)            -- 指示なし実績以外
--ADD END 2008/10/20 1.5
      -------------------------------------------------------------------------------
      -- 移動依頼/指示明細(アドオン)
      -------------------------------------------------------------------------------
      AND xmrih.mov_hdr_id                      =  xmril.mov_hdr_id
      AND xmril.delete_flg                     <>  gc_delete_flag
--DEL START 2008/10/20 1.5 指示なし実績を除外
-- 2008/08/07 v1.4 ADD START
--      AND xmril.instruct_qty                    > 0
-- 2008/08/07 v1.4 ADD END
--DEL END 2008/10/20 1.5
      -------------------------------------------------------------------------------
      -- OPM品目情報VIEW2
      -------------------------------------------------------------------------------
      AND xmril.item_id                         =  xim2v.item_id
      AND xim2v.start_date_active              <=  xmrih.schedule_ship_date
      AND (
             xim2v.end_date_active IS NULL
          OR
             xim2v.end_date_active             >=  xmrih.schedule_ship_date
          )
-- 2008/08/07 v1.4 UPDATE START
--      -------------------------------------------------------------------------------
--      -- OPM品目カテゴリ割当情報VIEW3
--      -------------------------------------------------------------------------------
      -------------------------------------------------------------------------------
      -- OPM品目カテゴリ割当情報VIEW
      -------------------------------------------------------------------------------
--      AND xim2v.item_id                        = xic3v.item_id
      AND xim2v.item_id                        = xic5v.item_id
      AND mct.source_lang                      = 'JA'
      AND mct.language                         = 'JA'
      AND mcb.category_id                      = mct.category_id
      AND mcsb.structure_id                    = mcb.structure_id
      AND gic.category_id                      = mcb.category_id
      AND mcst.source_lang                     = 'JA'
      AND mcst.language                        = 'JA'
      AND mcst.category_set_name               = '内外区分'
      AND mcsb.category_set_id                 = mcst.category_set_id
      AND gic.category_set_id                  = mcsb.category_set_id
      AND xim2v.item_id                        = gic.item_id
--     AND xic3v.prod_class_code                 = gt_param.prod_div         -- パラメータ：商品区分
      AND xic5v.prod_class_code                 = gt_param.prod_div         -- パラメータ：商品区分
-- 2008/08/07 v1.4 UPDATE END
      AND (gt_param.item_div IS NULL
           OR
-- 2008/08/07 v1.4 UPDATE START
--          xic3v.item_class_code                = gt_param.item_div )       -- パラメータ：品目区分
           xic5v.item_class_code                = gt_param.item_div )       -- パラメータ：品目区分
-- 2008/08/07 v1.4 UPDATE END
      -------------------------------------------------------------------------------
      -- 移動ロット詳細(アドオン)
      -------------------------------------------------------------------------------
      AND xmril.mov_line_id                     = xmld.mov_line_id(+)
      AND xmld.document_type_code(+)            = gc_doc_type_code_mv       -- 文章タイプ「移動」
      AND xmld.record_type_code(+)              = gc_rec_type_code_ins    -- レコードタイプ「指示」
      -------------------------------------------------------------------------------
      -- OPMロットマスタ
      -------------------------------------------------------------------------------
      AND   xmld.lot_id                         =  ilm.lot_id(+)
      AND   xmld.item_id                        =  ilm.item_id(+)
      -------------------------------------------------------------------------------
      -- OPM保管場所情報VIEW2-1
      -------------------------------------------------------------------------------
      AND xmrih.shipped_locat_id                =  xil2v1.inventory_location_id
      -------------------------------------------------------------------------------
      -- OPM保管場所情報VIEW2-2
      -------------------------------------------------------------------------------
      AND xmrih.ship_to_locat_id                =  xil2v2.inventory_location_id
      -------------------------------------------------------------------------------
      -- クイックコード情報VIEW2
      -------------------------------------------------------------------------------
      AND xlv2v.lookup_type = gc_lookup_type_621b_int
-- 2008/08/07 v1.4 UPDATE START
--     AND xlv2v.lookup_code = xic3v.int_ext_class                  -- 自社他社区分(1:自社、2:他社）
      AND xlv2v.lookup_code = mcb.attribute1                       -- 自社他社区分(1:自社、2:他社）
-- 2008/10/20 1.5 ADD START 品目/ロット単位に数量を合計
      GROUP BY
        xmrih.shipped_locat_code     -- 出庫元
        ,xil2v1.description          -- 出庫元(名称)
        ,DECODE(gt_param.deliver_to
          ,NULL,NULL
          ,xmrih.ship_to_locat_code) -- 配送先/入庫先（コード）
        ,DECODE(gt_param.deliver_to
          ,NULL,NULL
          ,xil2v2.description)       -- 配送先/入庫先（名称）
        ,xic5v.item_class_name       -- 品目区分名
        ,xmrih.schedule_ship_date    -- 出庫日
        ,mcb.attribute1              -- 内外区分（自社他社区分コード）
        ,xlv2v.meaning               -- 内外区分
        ,xmril.item_code             -- 品目（コード）
        ,xim2v.item_short_name       -- 品目（名称）
        ,xim2v.conv_unit             -- 単位
        ,xic5v.item_class_code       -- 品目区分コード
        ,xim2v.num_of_cases          -- 入数
        ,xim2v.item_um               -- 入出庫換算単位
        ,xmld.lot_no                 -- ロットNo
        ,ilm.attribute1              -- 製造日
        ,ilm.attribute3              -- 賞味期限
        ,ilm.attribute2              -- 固有記号
        ,xic5v.item_class_code       -- 品目区分コード
-- 2008/10/20 1.5 ADD END
-- 2008/08/07 v1.4 UPDATE END
      ORDER BY
         xmrih.shipped_locat_code ASC
-- 2008/08/07 v1.4 UPDATE START
--        ,xic3v.item_class_code        ASC
--        ,xic3v.int_ext_class          ASC
        ,xic5v.item_class_code        ASC
        ,mcb.attribute1               ASC
-- 2008/08/07 v1.4 UPDATE END
        ,xmril.item_code          ASC
        ,xmld.lot_no              ASC
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
    -- ====================================================
    -- 担当者情報取得
    -- ====================================================
    -- 担当部署
    gv_dept_cd := SUBSTRB(xxcmn_common_pkg.get_user_dept(FND_GLOBAL.USER_ID), 1, 10) ;
    -- 担当者
    gv_dept_nm := SUBSTRB(xxcmn_common_pkg.get_user_name(FND_GLOBAL.USER_ID), 1, 14) ;
--
    -- ====================================================
    -- 帳票データ取得
    -- ====================================================
    -- 「出荷」が指定された場合
    IF (gt_param.business_typ = gc_biz_type_cd_ship) THEN
      gv_biz_kind := gc_biz_type_nm_ship ;
      -- 出荷依頼情報取得
      OPEN cur_ship_data ;
      FETCH cur_ship_data BULK COLLECT INTO gt_report_data ;
      CLOSE cur_ship_data ;
    END IF;
--
    -- 「支給」が指定された場合
    IF (gt_param.business_typ = gc_biz_type_cd_shikyu) THEN
      gv_biz_kind := gc_biz_type_nm_shik ;
      -- 支給依頼情報取得
      OPEN cur_shikyu_data ;
      FETCH cur_shikyu_data BULK COLLECT INTO gt_report_data ;
      CLOSE cur_shikyu_data ;
    END IF;
--
    -- 「移動」が指定された場合
    IF (gt_param.business_typ = gc_biz_type_cd_move) THEN
      gv_biz_kind := gc_biz_type_nm_move ;
      -- 移動依頼情報取得
      OPEN cur_move_data ;
      FETCH cur_move_data BULK COLLECT INTO gt_report_data ;
      CLOSE cur_move_data ;
    END IF;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
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
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル変数 ***
    -- 前回レコード格納用
    lv_tmp_trans_type           type_report_data.trans_type_id%TYPE ;      -- 出庫形態毎情報
    lv_tmp_ship_cd              type_report_data.ship_cd%TYPE ;            -- 出庫元毎情報
    lv_tmp_item_class           type_report_data.item_class_code%TYPE ;    -- 品目区分毎情報
    -- タグ出力判定フラグ
    lb_dispflg_trans_type_cd    BOOLEAN := TRUE ;       -- 出庫形態毎情報
    lb_dispflg_ship_cd          BOOLEAN := TRUE ;       -- 出庫元毎情報
    lb_dispflg_item_class       BOOLEAN := TRUE ;       -- 品目区分毎情報
    lb_dispflg_dtl              BOOLEAN := TRUE ;       -- 明細情報
--
    /**********************************************************************************
     * Procedure Name   : prcsub_set_xml_data
     * Description      : タグ情報設定処理
     ***********************************************************************************/
    PROCEDURE prcsub_set_xml_data(
       ivsub_tag_name       IN  VARCHAR2                 -- タグ名
      ,ivsub_tag_value      IN  VARCHAR2                 -- データ
      ,ivsub_tag_type       IN  VARCHAR2  DEFAULT NULL   -- データ
    )IS
      ln_data_index  NUMBER ;    -- XMLデータを設定するインデックス
    BEGIN
      ln_data_index := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(ln_data_index).tag_name := ivsub_tag_name ;
      IF ((ivsub_tag_value IS NULL) AND (ivsub_tag_type = gc_tag_type_tag)) THEN
        -- タグ出力
        gt_xml_data_table(ln_data_index).tag_type := gc_tag_type_tag;
      ELSE
        -- データ出力
        gt_xml_data_table(ln_data_index).tag_type := gc_tag_type_data;
        gt_xml_data_table(ln_data_index).tag_value := ivsub_tag_value;
      END IF;
    END prcsub_set_xml_data ;
--
    /**********************************************************************************
     * Procedure Name   : prcsub_set_xml_data
     * Description      : タグ情報設定処理(開始・終了タグ用)
     ***********************************************************************************/
    PROCEDURE prcsub_set_xml_data(
       ivsub_tag_name       IN  VARCHAR2  -- タグ名
    )IS
    BEGIN
      prcsub_set_xml_data(ivsub_tag_name, NULL, gc_tag_type_tag);
    END prcsub_set_xml_data ;
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
    -- 変数初期設定
    -- -----------------------------------------------------
    gt_xml_data_table.DELETE ;
    lv_tmp_trans_type := NULL ;
    lv_tmp_ship_cd    := NULL ;
    lv_tmp_item_class := NULL ;
--
    -- -----------------------------------------------------
    -- ヘッダ情報設定
    -- -----------------------------------------------------
    prcsub_set_xml_data('root') ;
    prcsub_set_xml_data('data_info') ;
    prcsub_set_xml_data('report_id', gc_report_id) ;
    prcsub_set_xml_data('exec_time', TO_CHAR(gd_common_sysdate, gc_date_fmt_all )) ;
    prcsub_set_xml_data('dep_cd'   , gv_dept_cd) ;
    prcsub_set_xml_data('dep_nm'   , gv_dept_nm) ;
    prcsub_set_xml_data('biz_kind' , gv_biz_kind) ;
    prcsub_set_xml_data('lg_trans_type_info') ;
--
    -- -----------------------------------------------------
    -- 帳票0件用XMLデータ作成
    -- -----------------------------------------------------
    IF (gt_report_data.COUNT = 0) THEN
      ov_retcode := gv_status_warn ;
      ov_errmsg  := xxcmn_common_pkg.get_msg( gc_application_cmn, gc_msg_id_no_data ) ;
--
      prcsub_set_xml_data('g_trans_type_info') ;
      prcsub_set_xml_data('lg_ship_cd_info') ;
      prcsub_set_xml_data('g_ship_cd_info') ;
      prcsub_set_xml_data('lg_item_class_info') ;
      prcsub_set_xml_data('g_item_class_info') ;
      prcsub_set_xml_data('lg_ship_date_info') ;
      prcsub_set_xml_data('g_ship_date_info') ;
      prcsub_set_xml_data('msg' , ov_errmsg) ;
      prcsub_set_xml_data('/g_ship_date_info') ;
      prcsub_set_xml_data('/lg_ship_date_info') ;
      prcsub_set_xml_data('/g_item_class_info');
      prcsub_set_xml_data('/lg_item_class_info') ;
      prcsub_set_xml_data('/g_ship_cd_info') ;
      prcsub_set_xml_data('/lg_ship_cd_info');
      prcsub_set_xml_data('/g_trans_type_info') ;
    END IF ;
--
    -- -----------------------------------------------------
    -- XMLデータ作成
    -- -----------------------------------------------------
    <<detail_data_loop>>
    FOR i IN 1..gt_report_data.COUNT LOOP
--
      -- ====================================================
      -- XMLデータ設定
      -- ====================================================
--
      IF ( lb_dispflg_trans_type_cd OR lb_dispflg_ship_cd OR lb_dispflg_item_class ) THEN
        prcsub_set_xml_data('g_trans_type_info') ;
        prcsub_set_xml_data('trans_type'         , gt_report_data(i).trans_type ) ;
        prcsub_set_xml_data('lg_ship_cd_info') ;
        prcsub_set_xml_data('g_ship_cd_info') ;
        prcsub_set_xml_data('ship_cd', gt_report_data(i).ship_cd ) ;
        prcsub_set_xml_data('ship_nm', gt_report_data(i).ship_nm ) ;
        prcsub_set_xml_data('delivery_to_cd', gt_report_data(i).delivery_to_cd ) ;
        prcsub_set_xml_data('delivery_to_nm', gt_report_data(i).delivery_to_nm ) ;
        prcsub_set_xml_data('lg_item_class_info') ;
        prcsub_set_xml_data('g_item_class_info') ;
        prcsub_set_xml_data('item_class', gt_report_data(i).item_class ) ;
        prcsub_set_xml_data('lg_ship_date_info') ;
        prcsub_set_xml_data('g_ship_date_info') ;
        prcsub_set_xml_data('ship_date'
          , TO_CHAR(gt_report_data(i).ship_date, gc_date_fmt_ymd)) ;
        prcsub_set_xml_data('lg_dtl_info') ;
      END IF ;
--
      prcsub_set_xml_data('g_dtl_info') ;
      prcsub_set_xml_data('int_ext_class', gt_report_data(i).int_ext_class ) ;
      prcsub_set_xml_data('item_cd', gt_report_data(i).item_cd ) ;
      prcsub_set_xml_data('item_nm', gt_report_data(i).item_nm ) ;
      prcsub_set_xml_data('qty', gt_report_data(i).qty ) ;
      prcsub_set_xml_data('qty_tani', gt_report_data(i).qty_tani ) ;
      prcsub_set_xml_data('lot_no', gt_report_data(i).lot_no ) ;
      prcsub_set_xml_data('prod_date', gt_report_data(i).prod_date ) ;
      prcsub_set_xml_data('best_before_date', gt_report_data(i).best_before_date ) ;
      prcsub_set_xml_data('native_sign', gt_report_data(i).native_sign) ;
      prcsub_set_xml_data('/g_dtl_info') ;
--
      -- ====================================================
      -- 現在処理中のデータを保持
      -- ====================================================
      lv_tmp_trans_type  := gt_report_data(i).trans_type_id ;
      lv_tmp_ship_cd     := gt_report_data(i).ship_cd ;
      lv_tmp_item_class  := gt_report_data(i).item_class_code ;
--
      -- ====================================================
      -- 出力判定
      -- ====================================================
      IF (i < gt_report_data.COUNT) THEN
        -- 出庫形態
        IF ( NVL(lv_tmp_trans_type, 0) = NVL(gt_report_data(i+1).trans_type_id,0) ) THEN
          lb_dispflg_trans_type_cd := FALSE ;
        ELSE
          lb_dispflg_trans_type_cd := TRUE ;
        END IF ;
--
        -- 出庫元
        IF ( NVL(lv_tmp_ship_cd, 0) = NVL(gt_report_data(i+1).ship_cd, 0) ) THEN
          lb_dispflg_ship_cd := FALSE ;
        ELSE
          lb_dispflg_trans_type_cd := TRUE ;
          lb_dispflg_ship_cd       := TRUE ;
        END IF ;
--
        -- 品目区分
        IF ( NVL(lv_tmp_item_class, 0) = NVL(gt_report_data(i+1).item_class_code, 0) ) THEN
          lb_dispflg_item_class := FALSE ;
        ELSE
          lb_dispflg_trans_type_cd := TRUE ;
          lb_dispflg_ship_cd       := TRUE ;
          lb_dispflg_item_class    := TRUE ;
        END IF ;
--
      ELSE
          lb_dispflg_trans_type_cd := TRUE ;
          lb_dispflg_ship_cd       := TRUE ;
          lb_dispflg_item_class    := TRUE ;
      END IF;
--
      -- ====================================================
      -- 終了タグ設定
      -- ====================================================
--      
      IF ( lb_dispflg_item_class OR lb_dispflg_ship_cd OR lb_dispflg_trans_type_cd ) THEN
        prcsub_set_xml_data('/lg_dtl_info') ;
        prcsub_set_xml_data('/g_ship_date_info') ;
        prcsub_set_xml_data('/lg_ship_date_info') ;
        prcsub_set_xml_data('/g_item_class_info') ;
        prcsub_set_xml_data('/lg_item_class_info') ;
        prcsub_set_xml_data('/g_ship_cd_info') ;
        prcsub_set_xml_data('/lg_ship_cd_info') ;
        prcsub_set_xml_data('/g_trans_type_info') ;
      END IF;
    END LOOP detail_data_loop;
--
    -- ====================================================
    -- 終了タグ設定
    -- ====================================================
    prcsub_set_xml_data('/lg_trans_type_info') ;
    prcsub_set_xml_data('/data_info') ;
    prcsub_set_xml_data('/root') ;
--
  EXCEPTION
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
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
    iv_name  IN VARCHAR2
   ,iv_value IN VARCHAR2
   ,ic_type  IN CHAR
  ) RETURN VARCHAR2
  IS
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル変数 ***
    lv_convert_data VARCHAR2(2000);
--
  BEGIN
--
    --データの場合
    IF (ic_type = 'D') THEN
      lv_convert_data := '<'||iv_name||'><![CDATA['||iv_value||']]></'||iv_name||'>';
    ELSE
      lv_convert_data := '<'||iv_name||'>';
    END IF ;
--
    RETURN(lv_convert_data);
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
    lv_xml_string    VARCHAR2(32000) ;
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
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<?xml version="1.0" encoding="shift_jis" ?>' ) ;
--
    -- XMLデータ部出力
    <<xml_loop>>
    FOR i IN 1 .. gt_xml_data_table.COUNT LOOP
      lv_xml_string := fnc_convert_into_xml(
                         gt_xml_data_table(i).tag_name
                        ,gt_xml_data_table(i).tag_value
                        ,gt_xml_data_table(i).tag_type
                       ) ;
      -- XMLデータ出力
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, lv_xml_string) ;
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
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
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
    errbuf                  OUT    VARCHAR2       -- エラー・メッセージ  --# 固定 #
   ,retcode                 OUT    VARCHAR2       -- リターン・コード    --# 固定 #
   ,iv_biz_type             IN     VARCHAR2       -- 01 : 業務種別
   ,iv_deliver_type         IN     VARCHAR2       -- 02 : 出庫形態
   ,iv_block                IN     VARCHAR2       -- 03 : ブロック
   ,iv_deliver_from         IN     VARCHAR2       -- 04 : 出庫元
   ,iv_deliver_to           IN     VARCHAR2       -- 05 : 配送先／入庫先
   ,iv_prod_div             IN     VARCHAR2       -- 06 : 商品区分
   ,iv_item_div             IN     VARCHAR2       -- 07 : 品目区分
   ,iv_date                 IN     VARCHAR2       -- 08 : 出庫日
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
    gt_param.business_typ  := iv_biz_type ;                 -- 01 : 業務種別
    gt_param.deliver_type  := TO_NUMBER( iv_deliver_type ) ;  -- 02 : 出庫形態
    gt_param.block         := iv_block ;                    -- 03 : ブロック
    gt_param.deliver_from  := iv_deliver_from ;             -- 04 : 出庫元
    gt_param.deliver_to    := iv_deliver_to ;               -- 05 : 配送先／入庫先
    gt_param.prod_div      := iv_prod_div ;                 -- 06 : 商品区分
    gt_param.item_div      := iv_item_div ;                 -- 07 : 品目区分
    gt_param.date_from
              := FND_DATE.STRING_TO_DATE(iv_date, gc_date_fmt_ymd) ;
                                                      -- 08 : 出庫日
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
      errbuf  := gv_pkg_name || gv_msg_cont || cv_prg_name || gv_msg_part|| SQLERRM ;
      retcode := gv_status_error ;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      errbuf  := gv_pkg_name || gv_msg_cont || cv_prg_name || gv_msg_part || SQLERRM ;
      retcode := gv_status_error ;
  END main;
--
--###########################  固定部 END   #######################################################
--
END xxwsh620004c;
/
