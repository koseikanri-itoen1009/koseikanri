CREATE OR REPLACE PACKAGE BODY xxinv100002c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : XXINV100002C(body)
 * Description      : 販売計画表
 * MD.050/070       : 販売計画・引取計画 (T_MD050_BPO_100)
 *                    販売計画表         (T_MD070_BPO_10B)
 * Version          : 1.9
 *
 * Program List
 * ---------------------------- ----------------------------------------------------------
 *  Name                         Description
 * ---------------------------- ----------------------------------------------------------
 *  pro_get_cus_option           P データ取得    - カスタムオプション取得        (B-1-0)
 *  prc_sale_plan                P データ抽出    - 販売計画表情報抽出(全拠点時)  (B-1-1-1)
 *  prc_sale_plan_1              P データ抽出    - 販売計画表情x報抽出(拠点時)    (B-1-1-2)
 *  prc_create_xml_data_user     P XMLデータ変換 - ユーザー情報部分       (user_info)
 *  prc_create_xml_data_param    P XMLデータ変換 - パラメータ情報部分     (param_info)
 *  prc_create_xml_data          P XMLデータ作成 - 帳票データ出力
 *  submain                      P メイン処理プロシージャ
 *  main                         P コンカレント実行ファイル登録プロシージャ
 *
 *  convert_into_xml             F XMLデータ変換
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/01/18   1.0   Tatsuya Kurata   新規作成
 *  2008/04/22   1.1   Masanobu Kimura  内部変更要求#27
 *  2008/04/28   1.2   Sumie Nakamura   仕入･標準単価ヘッダ(アドオン)抽出条件漏れ対応
 *  2008/04/28   1.3   Yuko Kawano      内部変更要求#62,76
 *  2008/04/30   1.4   Tatsuya Kurata   内部変更要求#76
 *  2008/07/02   1.5   Satoshi Yunba    禁則文字対応
 *  2009/03/23   1.6   Hajime Iida      本番障害#1334対応
 *  2009/04/14   1.7   吉元 強樹        本番障害#1409対応
 *  2009/04/20   1.8   椎名 昭圭        本番障害#1409対応
 *  2009/10/05   1.9   吉元 強樹        本番障害#1648対応
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
  -- ==================================================
  -- ユーザー定義グローバル型
  -- ==================================================
  -- 入力Ｐ格納用レコード変数
  TYPE rec_param_data  IS RECORD 
    (
      year             VARCHAR2(4)    -- 年度
     ,prod_div         VARCHAR2(2)    -- 商品区分
     ,gen              VARCHAR2(2)    -- 世代
     ,output_unit      VARCHAR2(4)    -- 出力単位
--2008.04.28 Y.Kawano modify start
--     ,output_type      VARCHAR2(6)    -- 出力種別
     ,output_type      VARCHAR2(8)    -- 出力種別
--2008.04.28 Y.Kawano modify end
     ,base_01          VARCHAR2(4)    -- 拠点１
     ,base_02          VARCHAR2(4)    -- 拠点２
     ,base_03          VARCHAR2(4)    -- 拠点３
     ,base_04          VARCHAR2(4)    -- 拠点４
     ,base_05          VARCHAR2(4)    -- 拠点５
     ,base_06          VARCHAR2(4)    -- 拠点６
     ,base_07          VARCHAR2(4)    -- 拠点７
     ,base_08          VARCHAR2(4)    -- 拠点８
     ,base_09          VARCHAR2(4)    -- 拠点９
     ,base_10          VARCHAR2(4)    -- 拠点１０
     ,crowd_code_01    VARCHAR2(4)    -- 群コード１
     ,crowd_code_02    VARCHAR2(4)    -- 群コード２
     ,crowd_code_03    VARCHAR2(4)    -- 群コード３
     ,crowd_code_04    VARCHAR2(4)    -- 群コード４
     ,crowd_code_05    VARCHAR2(4)    -- 群コード５
     ,crowd_code_06    VARCHAR2(4)    -- 群コード６
     ,crowd_code_07    VARCHAR2(4)    -- 群コード７
     ,crowd_code_08    VARCHAR2(4)    -- 群コード８
     ,crowd_code_09    VARCHAR2(4)    -- 群コード９
     ,crowd_code_10    VARCHAR2(4)    -- 群コード１０
    );
--
  -- 販売計画表情報取得データ格納用レコード変数(全拠点用)
  TYPE rec_sale_plan IS RECORD 
    (
       skbn              xxcmn_item_categories2_v.segment1%TYPE      -- 商品区分
      ,gun               xxcmn_item_categories2_v.segment1%TYPE      -- 群コード
      ,item_no           xxcmn_item_mst2_v.item_no%TYPE              -- 品目（コード）
      ,item_short_name   xxcmn_item_mst2_v.item_short_name%TYPE      -- 品目（名称）
      ,case_quant        xxcmn_item_mst2_v.num_of_cases%TYPE         -- 入数
      ,quant             mrp_forecast_dates.attribute4%TYPE          -- 数量
      ,amount            mrp_forecast_dates.attribute2%TYPE          -- 金額
      ,total_amount      xxpo_price_headers.total_amount%TYPE        -- 内訳合計
      ,o_amount          xxcmn_item_mst2_v.old_price%TYPE            -- 旧・定価
      ,n_amount          xxcmn_item_mst2_v.new_price%TYPE            -- 新・定価
      ,price_st          xxcmn_item_mst2_v.price_start_date%TYPE     -- 定価適用開始日
    );
  TYPE tab_data_sale_plan IS TABLE OF rec_sale_plan INDEX BY BINARY_INTEGER;
--
  -- 販売計画表情報取得データ格納用レコード変数(拠点用)
  TYPE rec_sale_plan_1 IS RECORD 
    (
       skbn              xxcmn_item_categories2_v.segment1%TYPE      -- 商品区分
      ,gun               xxcmn_item_categories2_v.segment1%TYPE      -- 群コード
      ,item_no           xxcmn_item_mst2_v.item_no%TYPE              -- 品目（コード）
      ,item_short_name   xxcmn_item_mst2_v.item_short_name%TYPE      -- 品目（名称）
      ,case_quant        xxcmn_item_mst2_v.num_of_cases%TYPE         -- 入数
      ,quant             mrp_forecast_dates.attribute4%TYPE          -- 数量
      ,amount            mrp_forecast_dates.attribute2%TYPE          -- 金額
      ,ktn_code          mrp_forecast_dates.attribute5%TYPE          -- 拠点コード
      ,party_short_name  xxcmn_parties_v.party_short_name%TYPE       -- 拠点名称
      ,total_amount      xxpo_price_headers.total_amount%TYPE        -- 内訳合計
      ,o_amount          xxcmn_item_mst2_v.old_price%TYPE            -- 旧・定価
      ,n_amount          xxcmn_item_mst2_v.new_price%TYPE            -- 新・定価
      ,price_st          xxcmn_item_mst2_v.price_start_date%TYPE     -- 定価適用開始日
    );
  TYPE tab_data_sale_plan_1 IS TABLE OF rec_sale_plan_1 INDEX BY BINARY_INTEGER;
--
  -- ==================================================
  -- ユーザー定義グローバル定数
  -- ==================================================
  gv_pkg_name         CONSTANT VARCHAR2(20)  := 'XXINV100002C';           -- パッケージ名
  gv_prf_start_day    CONSTANT VARCHAR2(30)  := 'XXCMN_PERIOD_START_DAY'; -- XXCMN:年度開始月日
  gv_prf_prod         CONSTANT VARCHAR2(100) := 'XXCMN_ITEM_DIV';         -- XXCMN:商品区分
  gv_prf_crowd        CONSTANT VARCHAR2(100) := 'XXCMN_CATEGORY_NAME_OTGUN';
                                                             -- XXCMN:カテゴリセット名（群コード）
--2008.04.28 Y.Kawano add start
  gv_master_org_id    CONSTANT VARCHAR2(30)  := 'XXCMN_MASTER_ORG_ID';    --XXCMN:マスタ組織ID
--2008.04.28 Y.Kawano add end
  gv_name_sale_plan   CONSTANT VARCHAR2(2)   := '05';        -- '販売計画'
  gv_output_unit_0    CONSTANT VARCHAR2(10)  := '本数';      -- 出力単位 '0'
  gv_output_unit_1    CONSTANT VARCHAR2(10)  := 'ケース';    -- 出力単位 '1'
  gv_prod_div_leaf    CONSTANT VARCHAR2(1)   := '1';         -- 'リーフ'
  gv_prod_div_drink   CONSTANT VARCHAR2(1)   := '2';         -- 'ドリンク'
  gv_output_unit      CONSTANT VARCHAR2(1)   := '0';         -- '本数'
  -- ＳＱＬ作成用
  gv_sql_dot          CONSTANT VARCHAR2(3)   := ' , ';             -- カンマ','
  gv_sql_l_block      CONSTANT VARCHAR2(2)   := ' (';              -- 左括弧'('
  gv_sql_r_block      CONSTANT VARCHAR2(2)   := ') ';              -- 右括弧')'
  -- 帳票表示用
  gv_report_id        CONSTANT VARCHAR2(12)  := 'XXINV100002T';    -- 帳票ID
  gv_name_ktn         CONSTANT VARCHAR2(10)  := '全拠点';
  gv_name_year        CONSTANT VARCHAR2(10)  := '年度';
  gv_name_kotei       CONSTANT VARCHAR2(10)  := '70.00';           -- 固定値（掛率％）
  -- エラーコード
  gv_application      CONSTANT VARCHAR2(5)   := 'XXCMN';           -- アプリケーション
  gv_err_code_no_data CONSTANT VARCHAR2(20)  := 'APP-XXCMN-10122'; -- 帳票０件メッセージ
  gv_err_pro          CONSTANT VARCHAR2(20)  := 'APP-XXCMN-10002'; 
                                                     -- プロファイル取得エラーメッセージ
--
  gv_tkn_pro          CONSTANT VARCHAR2(15)  := 'PROFILE';         -- プロファイル名
--
  gn_0                NUMBER                 := 0;                 -- 0
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gd_start_day          DATE;              -- 年度開始月日
  gv_name_prod          VARCHAR2(10);      -- 商品区分
  gv_name_crowd         VARCHAR2(10);      -- 群コード
--2008.04.28 Y.Kawano add start
  gn_org_id             NUMBER;            -- マスタ組織ID
--2008.04.28 Y.Kawano add end
-- ＳＱＬ作成用
-- 2009/04/13 v1.7 T.Yoshimoto Mod Start 修正時のコメント増加によりバッファオーバー発生
  --gv_sql_sel            VARCHAR2(9000);    -- SQL組合せ用
  gv_sql_sel            VARCHAR2(20000);    -- SQL組合せ用
  --gv_sql_select         VARCHAR2(2000);    -- SELECT句
  gv_sql_select         VARCHAR2(5000);    -- SELECT句
-- 2009/04/13 v1.7 T.Yoshimoto Mod End 修正時のコメント増加によりバッファオーバー発生
  gv_sql_from           VARCHAR2(1000);    -- FROM句
  gv_sql_where          VARCHAR2(6000);    -- WHERE句
  gv_sql_order_by       VARCHAR2(1000);    -- ORDER BY句
--2008.04.28 Y.Kawano add start
  gv_sql_group_by       VARCHAR2(1000);    -- GROUP BY句
--2008.04.28 Y.Kawano add end
  gv_sql_prod_div       VARCHAR2(1000);    -- 商品区分(入力Ｐ有)
  gv_sql_prod_div_n     VARCHAR2(1000);    -- 商品区分(入力Ｐ無)
  gv_sql_crowd_code     VARCHAR2(5000);    -- 群コード(入力Ｐ有)
-- 群コード入力Ｐ用
  gv_sql_crowd_code_01  VARCHAR2(50);      -- 群コード１
  gv_sql_crowd_code_02  VARCHAR2(50);      -- 群コード２
  gv_sql_crowd_code_03  VARCHAR2(50);      -- 群コード３
  gv_sql_crowd_code_04  VARCHAR2(50);      -- 群コード４
  gv_sql_crowd_code_05  VARCHAR2(50);      -- 群コード５
  gv_sql_crowd_code_06  VARCHAR2(50);      -- 群コード６
  gv_sql_crowd_code_07  VARCHAR2(50);      -- 群コード７
  gv_sql_crowd_code_08  VARCHAR2(50);      -- 群コード８
  gv_sql_crowd_code_09  VARCHAR2(50);      -- 群コード９
  gv_sql_crowd_code_10  VARCHAR2(50);      -- 群コード１０
--
  gl_xml_idx            NUMBER;               -- ＸＭＬデータタグ表のインデックス
  gt_xml_data_table     XML_DATA;             -- ＸＭＬデータタグ表
  gr_param              rec_param_data ;      -- 入力パラメータ
  gr_sale_plan          tab_data_sale_plan;   -- 販売計画表からのパラメータ(全拠点)
  gr_sale_plan_1        tab_data_sale_plan_1; -- 販売計画表からのパラメータ(拠点)
  -- 2008/04/28 add
  gv_price_type       CONSTANT VARCHAR2(1)   := '2';                      -- マスタ区分 2:標準
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
  /**********************************************************************************
   * Procedure Name   : pro_get_cus_option
   * Description      : カスタムオプション取得  (B-1-0)
   ***********************************************************************************/
  PROCEDURE pro_get_cus_option
    (
      ov_errbuf     OUT VARCHAR2     --   エラー・メッセージ           --# 固定 #
     ,ov_retcode    OUT VARCHAR2     --   リターン・コード             --# 固定 #
     ,ov_errmsg     OUT VARCHAR2     --   ユーザー・エラー・メッセージ --# 固定 #
    )
  IS
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'pro_get_cus_option'; -- プログラム名
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
    lv_start_day    VARCHAR2(10);
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- プロファイルから年度開始月日取得
    lv_start_day := SUBSTRB(FND_PROFILE.VALUE(gv_prf_start_day),1,5);
    -- 取得エラー時
    IF (lv_start_day IS NULL) THEN
      lv_errmsg := SUBSTRB(xxcmn_common_pkg.get_msg( gv_application     -- 'XXCMN'
                                                    ,gv_err_pro         -- プロファイル取得エラー
                                                    ,gv_tkn_pro         -- トークン'PROFILE'
                                                    ,gv_prf_start_day)  -- XXCMN:年度開始月日
                                                   ,1
                                                   ,5000);
      RAISE global_api_expt;
    END IF;
--
    -- 入力Ｐ「年度」＋プロファイルから取得した年度開始月日 作成
    lv_start_day := gr_param.year ||'/'|| lv_start_day;
--
    gd_start_day := FND_DATE.STRING_TO_DATE(lv_start_day,'YYYY/MM/DD');
--
    -- プロファイルから商品区分取得
    gv_name_prod := SUBSTRB(FND_PROFILE.VALUE(gv_prf_prod),1,10);
    -- 取得エラー時
    IF (gv_name_prod IS NULL) THEN
      lv_errmsg := SUBSTRB(xxcmn_common_pkg.get_msg( gv_application   -- 'XXCMN'
                                                    ,gv_err_pro       -- プロファイル取得エラー
                                                    ,gv_tkn_pro       -- トークン'PROFILE'
                                                    ,gv_prf_prod)     -- XXCMN:商品区分
                                                  ,1
                                                  ,5000);
      RAISE global_api_expt;
    END IF;
    -- プロファイルから群コード取得
    gv_name_crowd := SUBSTRB(FND_PROFILE.VALUE(gv_prf_crowd),1,10);
    -- 取得エラー時
    IF (gv_name_crowd IS NULL) THEN
      lv_errmsg := SUBSTRB(xxcmn_common_pkg.get_msg( gv_application    -- 'XXCMN'
                                                    ,gv_err_pro        -- プロファイル取得エラー
                                                    ,gv_tkn_pro        -- トークン'PROFILE'
                                                    ,gv_prf_crowd)
                                                           -- XXCMN:カテゴリセット名（群コード）
                                                   ,1
                                                   ,5000);
      RAISE global_api_expt;
    END IF;
--
--2008.04.28 Y.Kawano add start
    -- プロファイルからXXCMN:マスタ組織ID取得
    gn_org_id := TO_NUMBER(FND_PROFILE.VALUE(gv_master_org_id));
    -- 取得エラー時
    IF (gn_org_id IS NULL) THEN
      lv_errmsg := SUBSTRB(xxcmn_common_pkg.get_msg( gv_application    -- 'XXCMN'
                                                    ,gv_err_pro        -- プロファイル取得エラー
                                                    ,gv_tkn_pro        -- トークン'PROFILE'
                                                    ,gv_master_org_id) -- XXCMN:マスタ組織ID
                                                   ,1
                                                   ,5000);
      RAISE global_api_expt;
    END IF;
--2008.04.28 Y.Kawano add end
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END pro_get_cus_option;
--
  /**********************************************************************************
   * Procedure Name   : prc_sale_plan
   * Description      : データ抽出 - 販売計画表情報抽出(全拠点時) (B-1-1-1)
   ***********************************************************************************/
  PROCEDURE prc_sale_plan
    (
      ot_sale_plan  OUT NOCOPY tab_data_sale_plan  --  取得レコード群
     ,ov_errbuf     OUT VARCHAR2                   --  エラー・メッセージ           --# 固定 #
     ,ov_retcode    OUT VARCHAR2                   --  リターン・コード             --# 固定 #
     ,ov_errmsg     OUT VARCHAR2                   --  ユーザー・エラー・メッセージ --# 固定 #
    )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_sale_plan'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- SELECT句
    gv_sql_select := 'SELECT xicv1.segment1         AS skbn         -- 商品区分
                            ,xicv.segment1          AS gun          -- 群コード
                            ,ximv.item_no                           -- 品目（コード）
                            ,ximv.item_short_name                   -- 品目（名称）
--2008.04.28 Y.Kawano modify start
--                            ,ximv.num_of_cases      AS case_quant   -- 入数
--                            ,mfd.attribute4         AS quant        -- 数量
--                            ,mfd.attribute2         AS amount       -- 金額
--                            ,xph.total_amount                       -- 内訳合計
--                            ,ximv.old_price         AS o_amount     -- 旧・定価
--                            ,ximv.new_price         AS n_amount     -- 新・定価
-- 2009/03/23 v1.6 H.Iida Mod Start 統合テスト指摘311
--                            ,SUM(ximv.num_of_cases) AS case_quant   -- 入数
                            ,ximv.num_of_cases      AS case_quant   -- 入数
-- 2009/03/23 v1.6 H.Iida Mod End
                            ,SUM(mfd.attribute4)    AS quant        -- 数量
                            ,SUM(mfd.attribute2)    AS amount       -- 金額
-- 2009/04/13 v1.7 T.Yoshimoto Mod Start 本番#1409
                            --,SUM(xph.total_amount)                  -- 内訳合計
                            --,SUM(ximv.old_price)    AS o_amount     -- 旧・定価
                            --,SUM(ximv.new_price)    AS n_amount     -- 新・定価
                            ,xph.total_amount                       -- 内訳合計
                            ,ximv.old_price         AS o_amount     -- 旧・定価
                            ,ximv.new_price         AS n_amount     -- 新・定価
-- 2009/04/13 v1.7 T.Yoshimoto Mod End 本番#1409
--2008.04.28 Y.Kawano modify end
                            ,ximv.price_start_date  AS price_st     -- 定価適用開始日
                            ';
--
    -- FROM句
    gv_sql_from := ' FROM mrp_forecast_designators  mfds    -- Forecast名
                         ,mrp_forecast_dates        mfd     -- Forecast日付
                         ,xxpo_price_headers        xph     -- 仕入/標準単価ヘッダ(アドオン)
                         ,xxcmn_item_categories2_v  xicv    -- OPM品目カテゴリ割当情報VIEW
                         ,xxcmn_item_categories2_v  xicv1   -- OPM品目カテゴリ割当情報VIEW(商品区分)
                         ,xxcmn_item_mst2_v         ximv    -- OPM品目情報VIEW
                         ';
--
    -- WHERE句
    gv_sql_where := ' WHERE mfds.attribute1          = :para_name_sale_plan      -- 販売計画
                      AND   mfds.attribute5          = :para_gen                 -- 入力Ｐ 世代
                      AND   mfds.attribute6          = :param_year               -- 入力Ｐ 年度
                      AND   mfds.forecast_designator = mfd.forecast_designator   -- Forecast名
--2008.04.28 Y.Kawano add start
                      AND   mfds.organization_id     = mfd.organization_id
                      AND   mfds.organization_id     = ''' || gn_org_id || '''   -- 組織ID
                      AND   mfd.organization_id      = ''' || gn_org_id || '''   -- 組織ID
--2008.04.28 Y.Kawano add start
                      AND   xicv1.category_set_name  = :para_name_prod           -- 商品区分
                      AND   mfd.inventory_item_id    = ximv.inventory_item_id    -- 品目ID
                      AND   ximv.item_no             = xicv1.item_no
                      AND   ximv.start_date_active  <= :para_start_day           -- 適用開始日  
                      AND   ximv.end_date_active    >= :para_start_day           -- 適用終了日
                      AND   xicv.item_no             = ximv.item_no
                      AND   xicv.category_set_name   = :para_name_crowd          -- 群コード
                      AND   xph.item_id              = ximv.item_id
                      -- 2008/04/28 add start
                      AND   xph.price_type           = :para_price_type          -- マスタ区分
                      -- 2008/04/28 add end 
                      AND   xph.start_date_active   <= :para_start_day           -- 適用開始日
                      AND   xph.end_date_active     >= :para_start_day           -- 適用終了日
                      ';
--
    -- 商品区分抽出条件 (入力Ｐ 入力有)
    gv_sql_prod_div   := ' AND xicv1.segment1 = ''' || gr_param.prod_div || '''
                         ';
    -- 商品区分抽出条件 (入力Ｐ NULL)
    gv_sql_prod_div_n := ' AND xicv1.segment1 IN (''' || gv_prod_div_leaf  || '''
                                                    ' || gv_sql_dot        || '
                                                  ''' || gv_prod_div_drink || ''') -- 1,2の両方抽出
                         ';
--
    -- 群コード抽出条件 (1･･･10の入力パラメータ)
    gv_sql_crowd_code    := ' AND xicv.segment1 IN ';
    gv_sql_crowd_code_01 := '''' || gr_param.crowd_code_01 || '''';
    gv_sql_crowd_code_02 := '''' || gr_param.crowd_code_02 || '''';
    gv_sql_crowd_code_03 := '''' || gr_param.crowd_code_03 || '''';
    gv_sql_crowd_code_04 := '''' || gr_param.crowd_code_04 || '''';
    gv_sql_crowd_code_05 := '''' || gr_param.crowd_code_05 || '''';
    gv_sql_crowd_code_06 := '''' || gr_param.crowd_code_06 || '''';
    gv_sql_crowd_code_07 := '''' || gr_param.crowd_code_07 || '''';
    gv_sql_crowd_code_08 := '''' || gr_param.crowd_code_08 || '''';
    gv_sql_crowd_code_09 := '''' || gr_param.crowd_code_09 || '''';
    gv_sql_crowd_code_10 := '''' || gr_param.crowd_code_10 || '''';
--
--2008.04.28 Y.Kawano add start
    -- GROUP BY句
    gv_sql_group_by      := ' GROUP BY xicv1.segment1     -- 商品区分
                                      ,xicv.segment1      -- 群コード
                                      ,ximv.item_no       -- 品目
-- 2009/03/23 v1.6 H.Iida Add Start 統合テスト指摘311
                                      ,ximv.num_of_cases  -- 入数
-- 2009/03/23 v1.6 H.Iida Add End
-- 2009/04/13 v1.7 T.Yoshimoto Mod Start 本番#1409
                                      ,xph.total_amount   -- 内訳合計
                                      ,ximv.old_price     -- 旧・定価
                                      ,ximv.new_price     -- 新・定価
-- 2009/04/13 v1.7 T.Yoshimoto Mod End 本番#1409
                                      ,ximv.item_short_name
                                      ,ximv.price_start_date';

--2008.04.28 Y.Kawano add end
--
    -- ORDER BY句
    gv_sql_order_by      := ' ORDER BY xicv1.segment1   -- 商品区分
                                      ,xicv.segment1    -- 群コード
                                      ,ximv.item_no';   -- 品目
--
    -------------------------------------------------------------
    -- データ抽出用SQL作成
    -------------------------------------------------------------
    gv_sql_sel := '';
    gv_sql_sel := gv_sql_sel || gv_sql_select;  -- SELECT句結合
    gv_sql_sel := gv_sql_sel || gv_sql_from;    -- FROM句結合
    gv_sql_sel := gv_sql_sel || gv_sql_where;   -- WHERE句結合
--
    -- 入力Ｐ「商品区分」NULL判定
    IF (gr_param.prod_div IS NOT NULL) THEN
      -- 作成ＳＱＬ文に商品区分抽出条件 (入力Ｐ 入力有)結合
      gv_sql_sel := gv_sql_sel || gv_sql_prod_div;
    ELSE
      -- 作成ＳＱＬ文に商品区分抽出条件 (入力Ｐ NULL)結合
      gv_sql_sel := gv_sql_sel || gv_sql_prod_div_n;
    END IF;
--
    -- 入力Ｐ「群コード１･･･１０」に入力有の場合
    IF (gr_param.crowd_code_01 IS NOT NULL)
      OR (gr_param.crowd_code_02 IS NOT NULL)
        OR (gr_param.crowd_code_03 IS NOT NULL)
          OR (gr_param.crowd_code_04 IS NOT NULL)
            OR (gr_param.crowd_code_05 IS NOT NULL)
              OR (gr_param.crowd_code_06 IS NOT NULL)
                OR (gr_param.crowd_code_07 IS NOT NULL)
                  OR (gr_param.crowd_code_08 IS NOT NULL)
                    OR (gr_param.crowd_code_09 IS NOT NULL)
                      OR (gr_param.crowd_code_10 IS NOT NULL)THEN
      -- 群コード抽出条件 + 左括弧
      gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_l_block;
      -- 入力Ｐ 群コード１に入力有
      IF (gr_param.crowd_code_01 IS NOT NULL) THEN
        gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_crowd_code_01;
      END IF;
      -- 入力Ｐ 群コード２に入力有
      IF (gr_param.crowd_code_02 IS NOT NULL)
        AND (gr_param.crowd_code_01 IS NULL) THEN
        gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_crowd_code_02;
      ELSIF (gr_param.crowd_code_02 IS NOT NULL) THEN
        gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_dot || gv_sql_crowd_code_02;
      END IF;
      -- 入力Ｐ 群コード３に入力有
      IF (gr_param.crowd_code_03 IS NOT NULL)
        AND (gr_param.crowd_code_01 IS NULL)
          AND (gr_param.crowd_code_02 IS NULL) THEN
        gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_crowd_code_03;
      ELSIF (gr_param.crowd_code_03 IS NOT NULL) THEN
        gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_dot || gv_sql_crowd_code_03;
      END IF;
      -- 入力Ｐ 群コード４に入力有
      IF (gr_param.crowd_code_04 IS NOT NULL)
        AND (gr_param.crowd_code_01 IS NULL)
          AND (gr_param.crowd_code_02 IS NULL)
            AND (gr_param.crowd_code_03 IS NULL) THEN
        gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_crowd_code_04;
      ELSIF (gr_param.crowd_code_04 IS NOT NULL) THEN
        gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_dot || gv_sql_crowd_code_04;
      END IF;
      -- 入力Ｐ 群コード５に入力有
      IF (gr_param.crowd_code_05 IS NOT NULL)
        AND (gr_param.crowd_code_01 IS NULL)
          AND (gr_param.crowd_code_02 IS NULL)
            AND (gr_param.crowd_code_03 IS NULL)
              AND (gr_param.crowd_code_04 IS NULL) THEN
        gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_crowd_code_05;
      ELSIF (gr_param.crowd_code_05 IS NOT NULL) THEN
        gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_dot || gv_sql_crowd_code_05;
      END IF;
      -- 入力Ｐ 群コード６に入力有
      IF (gr_param.crowd_code_06 IS NOT NULL)
        AND (gr_param.crowd_code_01 IS NULL)
          AND (gr_param.crowd_code_02 IS NULL)
            AND (gr_param.crowd_code_03 IS NULL)
              AND (gr_param.crowd_code_04 IS NULL)
                AND (gr_param.crowd_code_05 IS NULL) THEN
        gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_crowd_code_06;
      ELSIF (gr_param.crowd_code_06 IS NOT NULL) THEN
        gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_dot || gv_sql_crowd_code_06;
      END IF;
      -- 入力Ｐ 群コード７に入力有
      IF (gr_param.crowd_code_07 IS NOT NULL)
        AND (gr_param.crowd_code_01 IS NULL)
          AND (gr_param.crowd_code_02 IS NULL)
            AND (gr_param.crowd_code_03 IS NULL)
              AND (gr_param.crowd_code_04 IS NULL)
                AND (gr_param.crowd_code_05 IS NULL)
                  AND (gr_param.crowd_code_06 IS NULL) THEN
        gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_crowd_code_07;
      ELSIF (gr_param.crowd_code_07 IS NOT NULL) THEN
        gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_dot || gv_sql_crowd_code_07;
      END IF;
      -- 入力Ｐ 群コード８に入力有
      IF (gr_param.crowd_code_08 IS NOT NULL)
        AND (gr_param.crowd_code_01 IS NULL)
          AND (gr_param.crowd_code_02 IS NULL)
            AND (gr_param.crowd_code_03 IS NULL)
              AND (gr_param.crowd_code_04 IS NULL)
                AND (gr_param.crowd_code_05 IS NULL)
                  AND (gr_param.crowd_code_06 IS NULL)
                    AND (gr_param.crowd_code_07 IS NULL) THEN
        gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_crowd_code_08;
      ELSIF (gr_param.crowd_code_08 IS NOT NULL) THEN
        gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_dot || gv_sql_crowd_code_08;
      END IF;
      -- 入力Ｐ 群コード９に入力有
      IF (gr_param.crowd_code_09 IS NOT NULL)
        AND (gr_param.crowd_code_01 IS NULL)
          AND (gr_param.crowd_code_02 IS NULL)
            AND (gr_param.crowd_code_03 IS NULL)
              AND (gr_param.crowd_code_04 IS NULL)
                AND (gr_param.crowd_code_05 IS NULL)
                  AND (gr_param.crowd_code_06 IS NULL)
                    AND (gr_param.crowd_code_07 IS NULL)
                      AND (gr_param.crowd_code_08 IS NULL) THEN
        gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_crowd_code_09;
      ELSIF (gr_param.crowd_code_09 IS NOT NULL) THEN
        gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_dot || gv_sql_crowd_code_09;
      END IF;
      -- 入力Ｐ 群コード１０に入力有
      IF (gr_param.crowd_code_10 IS NOT NULL)
        AND (gr_param.crowd_code_01 IS NULL)
          AND (gr_param.crowd_code_02 IS NULL)
            AND (gr_param.crowd_code_03 IS NULL)
              AND (gr_param.crowd_code_04 IS NULL)
                AND (gr_param.crowd_code_05 IS NULL)
                  AND (gr_param.crowd_code_06 IS NULL)
                    AND (gr_param.crowd_code_07 IS NULL)
                      AND (gr_param.crowd_code_08 IS NULL)
                        AND (gr_param.crowd_code_09 IS NULL) THEN
        gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_crowd_code_10;
      ELSIF (gr_param.crowd_code_10 IS NOT NULL) THEN
        gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_dot || gv_sql_crowd_code_10;
      END IF;
      --  群コード抽出条件 + 右括弧
      gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_r_block;
      -- 作成ＳＱＬ文に群コード抽出条件結合
      gv_sql_sel        := gv_sql_sel || gv_sql_crowd_code;
    END IF;
--
--2008.04.28 Y.Kawano modify start
    -- GROUP BY句結合
    gv_sql_sel := gv_sql_sel || gv_sql_group_by;
--2008.04.28 Y.Kawano add end
--
    -- ORDER BY句結合
    gv_sql_sel := gv_sql_sel || gv_sql_order_by;
--
    -- 作成ＳＱＬ文実行
    EXECUTE IMMEDIATE gv_sql_sel BULK COLLECT INTO ot_sale_plan USING gv_name_sale_plan
                                                                      ,gr_param.gen
                                                                      ,gr_param.year
                                                                      ,gv_name_prod
                                                                      ,gd_start_day
                                                                      ,gd_start_day
                                                                      ,gv_name_crowd
                                                                      ,gv_price_type  -- add 2008/04/28
                                                                      ,gd_start_day
                                                                      ,gd_start_day 
                                                                      ;
--
  EXCEPTION
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END prc_sale_plan;
--
  /**********************************************************************************
   * Procedure Name   : prc_sale_plan_1
   * Description      : データ抽出 - 販売計画表情報抽出(拠点時) (B-1-1-2)
   ***********************************************************************************/
  PROCEDURE prc_sale_plan_1
    (
      ot_sale_plan_1  OUT NOCOPY tab_data_sale_plan_1  --  取得レコード群
     ,ov_errbuf       OUT VARCHAR2                     --  エラー・メッセージ           --# 固定 #
     ,ov_retcode      OUT VARCHAR2                     --  リターン・コード             --# 固定 #
     ,ov_errmsg       OUT VARCHAR2                     --  ユーザー・エラー・メッセージ --# 固定 #
     )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_sale_plan_1'; -- プログラム名
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
    -- ＳＱＬ作成用
    lv_sql_base       VARCHAR2(5000);    -- 拠点(入力Ｐ有)
    -- 拠点入力Ｐ用
    lv_sql_base_01    VARCHAR2(100);     -- 拠点１
    lv_sql_base_02    VARCHAR2(100);     -- 拠点２
    lv_sql_base_03    VARCHAR2(100);     -- 拠点３
    lv_sql_base_04    VARCHAR2(100);     -- 拠点４
    lv_sql_base_05    VARCHAR2(100);     -- 拠点５
    lv_sql_base_06    VARCHAR2(100);     -- 拠点６
    lv_sql_base_07    VARCHAR2(100);     -- 拠点７
    lv_sql_base_08    VARCHAR2(100);     -- 拠点８
    lv_sql_base_09    VARCHAR2(100);     -- 拠点９
    lv_sql_base_10    VARCHAR2(100);     -- 拠点１０
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- SELECT句
    gv_sql_select := 'SELECT xicv1.segment1         AS skbn         -- 商品区分
                            ,xicv.segment1          AS gun          -- 群コード
                            ,ximv.item_no                           -- 品目（コード）
                            ,ximv.item_short_name                   -- 品目（名称）
--2008.04.28 Y.Kawano modify start
--                            ,ximv.num_of_cases      AS case_quant   -- 入数
--                            ,mfd.attribute4         AS quant        -- 数量
--                            ,mfd.attribute2         AS amount       -- 金額
-- 2009/03/23 v1.6 H.Iida Mod Start 統合テスト指摘311
--                            ,SUM(ximv.num_of_cases) AS case_quant   -- 入数
                            ,ximv.num_of_cases      AS case_quant   -- 入数
-- 2009/03/23 v1.6 H.Iida Mod End
                            ,SUM(mfd.attribute4)    AS quant        -- 数量
                            ,SUM(mfd.attribute2)    AS amount       -- 金額
--2008.04.28 Y.Kawano modify end
                            ,mfd.attribute5         AS ktn_code     -- 拠点コード
                            ,xpv.party_short_name                   -- 拠点名
--2008.04.28 Y.Kawano modify start
--                            ,xph.total_amount                       -- 内訳合計
--                            ,ximv.old_price         AS o_amount     -- 旧・定価
--                            ,ximv.new_price         AS n_amount     -- 新・定価
-- 2009/04/13 v1.7 T.Yoshimoto Mod Start 本番#1409
                            --,SUM(xph.total_amount)                  -- 内訳合計
                            --,SUM(ximv.old_price)    AS o_amount     -- 旧・定価
                            --,SUM(ximv.new_price)    AS n_amount     -- 新・定価
                            ,xph.total_amount                       -- 内訳合計
                            ,ximv.old_price         AS o_amount     -- 旧・定価
                            ,ximv.new_price         AS n_amount     -- 新・定価
-- 2009/04/13 v1.7 T.Yoshimoto Mod End 本番#1409
--2008.04.28 Y.Kawano modify end
                            ,ximv.price_start_date  AS price_st     -- 定価適用開始日
                            ';
--
    -- FROM句
    gv_sql_from := ' FROM mrp_forecast_designators  mfds    -- Forecast名
                         ,mrp_forecast_dates        mfd     -- Forecast日付
                         ,xxpo_price_headers        xph     -- 仕入/標準単価ヘッダ(アドオン)
                         ,xxcmn_item_categories2_v  xicv    -- OPM品目カテゴリ割当情報VIEW
                         ,xxcmn_item_categories2_v  xicv1   -- OPM品目カテゴリ割当情報VIEW(商品区分)
                         ,xxcmn_item_mst2_v         ximv    -- OPM品目情報VIEW
-- 2009/10/05 v1.9 T.Yoshimoto Mod Start 本番#1648
                         --,xxcmn_parties_v           xpv     -- パーティ情報VIEW
                         ,xxcmn_parties3_v          xpv     -- パーティ情報VIEW2
-- 2009/10/05 v1.9 T.Yoshimoto Mod End 本番#1648
                         ';
--
    -- WHERE句
    gv_sql_where := ' WHERE mfds.attribute1          = :para_name_sale_plan      -- 販売計画
                      AND   mfds.attribute5          = :para_gen                 -- 入力Ｐ 世代
                      AND   mfds.attribute6          = :param_year               -- 入力Ｐ 年度
                      AND   mfds.forecast_designator = mfd.forecast_designator   -- Forecast名
--2008.04.28 Y.Kawano add start
                      AND   mfds.organization_id     = mfd.organization_id
                      AND   mfds.organization_id     = ''' || gn_org_id || '''   -- 組織ID
                      AND   mfd.organization_id      = ''' || gn_org_id || '''   -- 組織ID
--2008.04.28 Y.Kawano add start
                      AND   xicv1.category_set_name  = :para_name_prod           -- 商品区分
                      AND   mfd.inventory_item_id    = ximv.inventory_item_id    -- 品目ID
                      AND   ximv.item_no             = xicv1.item_no
                      AND   ximv.start_date_active  <= :para_start_day           -- 適用開始日  
                      AND   ximv.end_date_active    >= :para_start_day           -- 適用終了日
                      AND   xicv.item_no             = ximv.item_no
                      AND   xicv.category_set_name   = :para_name_crowd          -- 群コード
                      AND   xph.item_id              = ximv.item_id
                      -- 2008/04/28 add start
                      AND   xph.price_type           = :para_price_type          -- マスタ区分
                      -- 2008/04/28 add end 
                      AND   xph.start_date_active   <= :para_start_day           -- 適用開始日
                      AND   xph.end_date_active     >= :para_start_day           -- 適用終了日
                      AND   mfd.attribute5           = xpv.account_number        -- 顧客番号
                      ';
--
    -- 商品区分抽出条件 (入力Ｐ 入力有)
    gv_sql_prod_div   := ' AND xicv1.segment1 =''' || gr_param.prod_div || '''
                         ';
    -- 商品区分抽出条件 (入力Ｐ NULL)
    gv_sql_prod_div_n := ' AND xicv1.segment1 IN (''' || gv_prod_div_leaf  || '''
                                                    ' || gv_sql_dot        || '
                                                  ''' || gv_prod_div_drink || ''') -- 1,2の両方抽出
                         ';
--
    -- 拠点抽出条件 (1･･･10の入力パラメータ)
    lv_sql_base    := ' AND mfd.attribute5 IN ';
    lv_sql_base_01 := '''' || gr_param.base_01 || '''';
    lv_sql_base_02 := '''' || gr_param.base_02 || '''';
    lv_sql_base_03 := '''' || gr_param.base_03 || '''';
    lv_sql_base_04 := '''' || gr_param.base_04 || '''';
    lv_sql_base_05 := '''' || gr_param.base_05 || '''';
    lv_sql_base_06 := '''' || gr_param.base_06 || '''';
    lv_sql_base_07 := '''' || gr_param.base_07 || '''';
    lv_sql_base_08 := '''' || gr_param.base_08 || '''';
    lv_sql_base_09 := '''' || gr_param.base_09 || '''';
    lv_sql_base_10 := '''' || gr_param.base_10 || '''';
--
    -- 群コード抽出条件 (1･･･10の入力パラメータ)
    gv_sql_crowd_code    := ' AND xicv.segment1 IN ';
    gv_sql_crowd_code_01 := '''' || gr_param.crowd_code_01 || '''';
    gv_sql_crowd_code_02 := '''' || gr_param.crowd_code_02 || '''';
    gv_sql_crowd_code_03 := '''' || gr_param.crowd_code_03 || '''';
    gv_sql_crowd_code_04 := '''' || gr_param.crowd_code_04 || '''';
    gv_sql_crowd_code_05 := '''' || gr_param.crowd_code_05 || '''';
    gv_sql_crowd_code_06 := '''' || gr_param.crowd_code_06 || '''';
    gv_sql_crowd_code_07 := '''' || gr_param.crowd_code_07 || '''';
    gv_sql_crowd_code_08 := '''' || gr_param.crowd_code_08 || '''';
    gv_sql_crowd_code_09 := '''' || gr_param.crowd_code_09 || '''';
    gv_sql_crowd_code_10 := '''' || gr_param.crowd_code_10 || '''';
--
--2008.04.28 Y.Kawano add start
    -- GROUP BY句
    gv_sql_group_by      := ' GROUP BY xicv1.segment1     -- 商品区分
                                      ,mfd.attribute5
                                      ,xicv.segment1      -- 群コード
                                      ,ximv.item_no       -- 品目
-- 2009/03/23 v1.6 H.Iida Add Start 統合テスト指摘311
                                      ,ximv.num_of_cases  -- 入数
-- 2009/03/23 v1.6 H.Iida Add End
-- 2009/04/13 v1.7 T.Yoshimoto Mod Start 本番#1409
                                      ,xph.total_amount   -- 内訳合計
                                      ,ximv.old_price     -- 旧・定価
                                      ,ximv.new_price     -- 新・定価
-- 2009/04/13 v1.7 T.Yoshimoto Mod End 本番#1409
                                      ,xpv.party_short_name 
                                      ,ximv.item_short_name
                                      ,ximv.price_start_date';

--2008.04.28 Y.Kawano add end
--
    -- ORDER BY句
    gv_sql_order_by      := ' ORDER BY xicv1.segment1   -- 商品区分
                                      ,mfd.attribute5   -- 拠点
                                      ,xicv.segment1    -- 群コード
                                      ,ximv.item_no';   -- 品目
--
    -------------------------------------------------------------
    -- データ抽出用SQL作成
    -------------------------------------------------------------
    gv_sql_sel := '';
    gv_sql_sel := gv_sql_sel || gv_sql_select;  -- SELECT句結合
    gv_sql_sel := gv_sql_sel || gv_sql_from;    -- FROM句結合
    gv_sql_sel := gv_sql_sel || gv_sql_where;   -- WHERE句結合
--
    -- 入力Ｐ「商品区分」NULL判定
    IF (gr_param.prod_div IS NOT NULL) THEN
      -- 作成ＳＱＬ文に商品区分抽出条件 (入力Ｐ 入力有)結合
      gv_sql_sel := gv_sql_sel || gv_sql_prod_div;
    ELSE
      -- 作成ＳＱＬ文に商品区分抽出条件 (入力Ｐ NULL)結合
      gv_sql_sel := gv_sql_sel || gv_sql_prod_div_n;
    END IF;
--
    -- 入力Ｐ「拠点１･･･１０」に入力有の場合
    IF (gr_param.base_01 IS NOT NULL)
      OR (gr_param.base_02 IS NOT NULL)
        OR (gr_param.base_03 IS NOT NULL)
          OR (gr_param.base_04 IS NOT NULL)
            OR (gr_param.base_05 IS NOT NULL)
              OR (gr_param.base_06 IS NOT NULL)
                OR (gr_param.base_07 IS NOT NULL)
                  OR (gr_param.base_08 IS NOT NULL)
                    OR (gr_param.base_09 IS NOT NULL)
                      OR (gr_param.base_10 IS NOT NULL)THEN
      -- 拠点抽出条件 + 左括弧
      lv_sql_base   := lv_sql_base || gv_sql_l_block;
      -- 入力Ｐ 拠点１に入力有
      IF (gr_param.base_01 IS NOT NULL) THEN
        lv_sql_base := lv_sql_base || lv_sql_base_01;
      END IF;
      -- 入力Ｐ 拠点２に入力有
      IF (gr_param.base_02 IS NOT NULL)
        AND (gr_param.base_01 IS NULL) THEN
        lv_sql_base := lv_sql_base || lv_sql_base_02;
      ELSIF (gr_param.base_02 IS NOT NULL) THEN
        lv_sql_base := lv_sql_base || gv_sql_dot || lv_sql_base_02;
      END IF;
      -- 入力Ｐ 拠点３に入力有
      IF (gr_param.base_03 IS NOT NULL)
        AND (gr_param.base_01 IS NULL)
          AND (gr_param.base_02 IS NULL) THEN
        lv_sql_base := lv_sql_base || lv_sql_base_03;
      ELSIF (gr_param.base_03 IS NOT NULL) THEN
        lv_sql_base := lv_sql_base || gv_sql_dot || lv_sql_base_03;
      END IF;
      -- 入力Ｐ 拠点４に入力有
      IF (gr_param.base_04 IS NOT NULL)
        AND (gr_param.base_01 IS NULL)
          AND (gr_param.base_02 IS NULL)
            AND (gr_param.base_03 IS NULL) THEN
        lv_sql_base := lv_sql_base || lv_sql_base_04;
      ELSIF (gr_param.base_04 IS NOT NULL) THEN
        lv_sql_base := lv_sql_base || gv_sql_dot || lv_sql_base_04;
      END IF;
      -- 入力Ｐ 拠点５に入力有
      IF (gr_param.base_05 IS NOT NULL)
        AND (gr_param.base_01 IS NULL)
          AND (gr_param.base_02 IS NULL)
            AND (gr_param.base_03 IS NULL)
              AND (gr_param.base_04 IS NULL) THEN
        lv_sql_base := lv_sql_base || lv_sql_base_05;
      ELSIF (gr_param.base_05 IS NOT NULL) THEN
        lv_sql_base := lv_sql_base || gv_sql_dot || lv_sql_base_05;
      END IF;
      -- 入力Ｐ 拠点６に入力有
      IF (gr_param.base_06 IS NOT NULL)
        AND (gr_param.base_01 IS NULL)
          AND (gr_param.base_02 IS NULL)
            AND (gr_param.base_03 IS NULL)
              AND (gr_param.base_04 IS NULL)
                AND (gr_param.base_05 IS NULL) THEN
        lv_sql_base := lv_sql_base || lv_sql_base_06;
      ELSIF (gr_param.base_06 IS NOT NULL) THEN
        lv_sql_base := lv_sql_base || gv_sql_dot || lv_sql_base_06;
      END IF;
      -- 入力Ｐ 拠点７に入力有
      IF (gr_param.base_07 IS NOT NULL)
        AND (gr_param.base_01 IS NULL)
          AND (gr_param.base_02 IS NULL)
            AND (gr_param.base_03 IS NULL)
              AND (gr_param.base_04 IS NULL)
                AND (gr_param.base_05 IS NULL)
                  AND (gr_param.base_06 IS NULL) THEN
        lv_sql_base := lv_sql_base || lv_sql_base_07;
      ELSIF (gr_param.base_07 IS NOT NULL) THEN
        lv_sql_base := lv_sql_base || gv_sql_dot || lv_sql_base_07;
      END IF;
      -- 入力Ｐ 拠点８に入力有
      IF (gr_param.base_08 IS NOT NULL)
        AND (gr_param.base_01 IS NULL)
          AND (gr_param.base_02 IS NULL)
            AND (gr_param.base_03 IS NULL)
              AND (gr_param.base_04 IS NULL)
                AND (gr_param.base_05 IS NULL)
                  AND (gr_param.base_06 IS NULL)
                    AND (gr_param.base_07 IS NULL) THEN
        lv_sql_base := lv_sql_base || lv_sql_base_08;
      ELSIF (gr_param.base_08 IS NOT NULL) THEN
        lv_sql_base := lv_sql_base || gv_sql_dot || lv_sql_base_08;
      END IF;
      -- 入力Ｐ 拠点９に入力有
      IF (gr_param.base_09 IS NOT NULL)
        AND (gr_param.base_01 IS NULL)
          AND (gr_param.base_02 IS NULL)
            AND (gr_param.base_03 IS NULL)
              AND (gr_param.base_04 IS NULL)
                AND (gr_param.base_05 IS NULL)
                  AND (gr_param.base_06 IS NULL)
                    AND (gr_param.base_07 IS NULL)
                      AND (gr_param.base_08 IS NULL) THEN
        lv_sql_base := lv_sql_base || lv_sql_base_09;
      ELSIF (gr_param.base_09 IS NOT NULL) THEN
        lv_sql_base := lv_sql_base || gv_sql_dot || lv_sql_base_09;
      END IF;
      -- 入力Ｐ 拠点１０に入力有
      IF (gr_param.base_10 IS NOT NULL)
        AND (gr_param.base_01 IS NULL)
          AND (gr_param.base_02 IS NULL)
            AND (gr_param.base_03 IS NULL)
              AND (gr_param.base_04 IS NULL)
                AND (gr_param.base_05 IS NULL)
                  AND (gr_param.base_06 IS NULL)
                    AND (gr_param.base_07 IS NULL)
                      AND (gr_param.base_08 IS NULL)
                        AND (gr_param.base_09 IS NULL) THEN
        lv_sql_base := lv_sql_base || lv_sql_base_10;
      ELSIF (gr_param.base_10 IS NOT NULL) THEN
        lv_sql_base := lv_sql_base || gv_sql_dot || lv_sql_base_10;
      END IF;
      --  拠点抽出条件 + 右括弧
      lv_sql_base   := lv_sql_base || gv_sql_r_block;
      -- 作成ＳＱＬ文に拠点抽出条件結合
      gv_sql_sel    := gv_sql_sel || lv_sql_base;
--
      -- 入力Ｐ「群コード１･･･１０」に入力有の場合
      IF (gr_param.crowd_code_01 IS NOT NULL)
        OR (gr_param.crowd_code_02 IS NOT NULL)
          OR (gr_param.crowd_code_03 IS NOT NULL)
            OR (gr_param.crowd_code_04 IS NOT NULL)
              OR (gr_param.crowd_code_05 IS NOT NULL)
                OR (gr_param.crowd_code_06 IS NOT NULL)
                  OR (gr_param.crowd_code_07 IS NOT NULL)
                    OR (gr_param.crowd_code_08 IS NOT NULL)
                      OR (gr_param.crowd_code_09 IS NOT NULL)
                        OR (gr_param.crowd_code_10 IS NOT NULL)THEN
        -- 群コード抽出条件 + 左括弧
        gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_l_block;
        -- 入力Ｐ 群コード１に入力有
        IF (gr_param.crowd_code_01 IS NOT NULL) THEN
          gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_crowd_code_01;
        END IF;
        -- 入力Ｐ 群コード２に入力有
        IF (gr_param.crowd_code_02 IS NOT NULL)
          AND (gr_param.crowd_code_01 IS NULL) THEN
          gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_crowd_code_02;
        ELSIF (gr_param.crowd_code_02 IS NOT NULL) THEN
          gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_dot || gv_sql_crowd_code_02;
        END IF;
        -- 入力Ｐ 群コード３に入力有
        IF (gr_param.crowd_code_03 IS NOT NULL)
          AND (gr_param.crowd_code_01 IS NULL)
            AND (gr_param.crowd_code_02 IS NULL) THEN
          gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_crowd_code_03;
        ELSIF (gr_param.crowd_code_03 IS NOT NULL) THEN
          gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_dot || gv_sql_crowd_code_03;
        END IF;
        -- 入力Ｐ 群コード４に入力有
        IF (gr_param.crowd_code_04 IS NOT NULL)
          AND (gr_param.crowd_code_01 IS NULL)
            AND (gr_param.crowd_code_02 IS NULL)
              AND (gr_param.crowd_code_03 IS NULL) THEN
          gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_crowd_code_04;
        ELSIF (gr_param.crowd_code_04 IS NOT NULL) THEN
          gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_dot || gv_sql_crowd_code_04;
        END IF;
        -- 入力Ｐ 群コード５に入力有
        IF (gr_param.crowd_code_05 IS NOT NULL)
          AND (gr_param.crowd_code_01 IS NULL)
            AND (gr_param.crowd_code_02 IS NULL)
              AND (gr_param.crowd_code_03 IS NULL)
                AND (gr_param.crowd_code_04 IS NULL) THEN
          gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_crowd_code_05;
        ELSIF (gr_param.crowd_code_05 IS NOT NULL) THEN
          gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_dot || gv_sql_crowd_code_05;
        END IF;
        -- 入力Ｐ 群コード６に入力有
        IF (gr_param.crowd_code_06 IS NOT NULL)
          AND (gr_param.crowd_code_01 IS NULL)
            AND (gr_param.crowd_code_02 IS NULL)
              AND (gr_param.crowd_code_03 IS NULL)
                AND (gr_param.crowd_code_04 IS NULL)
                  AND (gr_param.crowd_code_05 IS NULL) THEN
          gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_crowd_code_06;
        ELSIF (gr_param.crowd_code_06 IS NOT NULL) THEN
          gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_dot || gv_sql_crowd_code_06;
        END IF;
        -- 入力Ｐ 群コード７に入力有
        IF (gr_param.crowd_code_07 IS NOT NULL)
          AND (gr_param.crowd_code_01 IS NULL)
            AND (gr_param.crowd_code_02 IS NULL)
              AND (gr_param.crowd_code_03 IS NULL)
                AND (gr_param.crowd_code_04 IS NULL)
                  AND (gr_param.crowd_code_05 IS NULL)
                    AND (gr_param.crowd_code_06 IS NULL) THEN
          gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_crowd_code_07;
        ELSIF (gr_param.crowd_code_07 IS NOT NULL) THEN
          gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_dot || gv_sql_crowd_code_07;
        END IF;
        -- 入力Ｐ 群コード８に入力有
        IF (gr_param.crowd_code_08 IS NOT NULL)
          AND (gr_param.crowd_code_01 IS NULL)
            AND (gr_param.crowd_code_02 IS NULL)
              AND (gr_param.crowd_code_03 IS NULL)
                AND (gr_param.crowd_code_04 IS NULL)
                  AND (gr_param.crowd_code_05 IS NULL)
                    AND (gr_param.crowd_code_06 IS NULL)
                      AND (gr_param.crowd_code_07 IS NULL) THEN
          gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_crowd_code_08;
        ELSIF (gr_param.crowd_code_08 IS NOT NULL) THEN
          gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_dot || gv_sql_crowd_code_08;
        END IF;
        -- 入力Ｐ 群コード９に入力有
        IF (gr_param.crowd_code_09 IS NOT NULL)
          AND (gr_param.crowd_code_01 IS NULL)
            AND (gr_param.crowd_code_02 IS NULL)
              AND (gr_param.crowd_code_03 IS NULL)
                AND (gr_param.crowd_code_04 IS NULL)
                  AND (gr_param.crowd_code_05 IS NULL)
                    AND (gr_param.crowd_code_06 IS NULL)
                      AND (gr_param.crowd_code_07 IS NULL)
                        AND (gr_param.crowd_code_08 IS NULL) THEN
          gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_crowd_code_09;
        ELSIF (gr_param.crowd_code_09 IS NOT NULL) THEN
          gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_dot || gv_sql_crowd_code_09;
        END IF;
        -- 入力Ｐ 群コード１０に入力有
        IF (gr_param.crowd_code_10 IS NOT NULL)
          AND (gr_param.crowd_code_01 IS NULL)
            AND (gr_param.crowd_code_02 IS NULL)
              AND (gr_param.crowd_code_03 IS NULL)
                AND (gr_param.crowd_code_04 IS NULL)
                  AND (gr_param.crowd_code_05 IS NULL)
                    AND (gr_param.crowd_code_06 IS NULL)
                      AND (gr_param.crowd_code_07 IS NULL)
                        AND (gr_param.crowd_code_08 IS NULL)
                          AND (gr_param.crowd_code_09 IS NULL) THEN
          gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_crowd_code_10;
        ELSIF (gr_param.crowd_code_10 IS NOT NULL) THEN
          gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_dot || gv_sql_crowd_code_10;
        END IF;
        --  群コード抽出条件 + 右括弧
        gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_r_block;
        -- 作成ＳＱＬ文に群コード抽出条件結合
        gv_sql_sel        := gv_sql_sel || gv_sql_crowd_code;
      END IF;
    ELSE
    -- 入力Ｐ「拠点１･･･１０」に入力無の場合
--
      -- 入力Ｐ「群コード１･･･１０」に入力有の場合
      IF (gr_param.crowd_code_01 IS NOT NULL)
        OR (gr_param.crowd_code_02 IS NOT NULL)
          OR (gr_param.crowd_code_03 IS NOT NULL)
            OR (gr_param.crowd_code_04 IS NOT NULL)
              OR (gr_param.crowd_code_05 IS NOT NULL)
                OR (gr_param.crowd_code_06 IS NOT NULL)
                  OR (gr_param.crowd_code_07 IS NOT NULL)
                    OR (gr_param.crowd_code_08 IS NOT NULL)
                      OR (gr_param.crowd_code_09 IS NOT NULL)
                        OR (gr_param.crowd_code_10 IS NOT NULL)THEN
        -- 群コード抽出条件 + 左括弧
        gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_l_block;
        -- 入力Ｐ 群コード１に入力有
        IF (gr_param.crowd_code_01 IS NOT NULL) THEN
          gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_crowd_code_01;
        END IF;
        -- 入力Ｐ 群コード２に入力有
        IF (gr_param.crowd_code_02 IS NOT NULL)
          AND (gr_param.crowd_code_01 IS NULL) THEN
          gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_crowd_code_02;
        ELSIF (gr_param.crowd_code_02 IS NOT NULL) THEN
          gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_dot || gv_sql_crowd_code_02;
        END IF;
        -- 入力Ｐ 群コード３に入力有
        IF (gr_param.crowd_code_03 IS NOT NULL)
          AND (gr_param.crowd_code_01 IS NULL)
            AND (gr_param.crowd_code_02 IS NULL) THEN
          gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_crowd_code_03;
        ELSIF (gr_param.crowd_code_03 IS NOT NULL) THEN
          gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_dot || gv_sql_crowd_code_03;
        END IF;
        -- 入力Ｐ 群コード４に入力有
        IF (gr_param.crowd_code_04 IS NOT NULL)
          AND (gr_param.crowd_code_01 IS NULL)
            AND (gr_param.crowd_code_02 IS NULL)
              AND (gr_param.crowd_code_03 IS NULL) THEN
          gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_crowd_code_04;
        ELSIF (gr_param.crowd_code_04 IS NOT NULL) THEN
          gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_dot || gv_sql_crowd_code_04;
        END IF;
        -- 入力Ｐ 群コード５に入力有
        IF (gr_param.crowd_code_05 IS NOT NULL)
          AND (gr_param.crowd_code_01 IS NULL)
            AND (gr_param.crowd_code_02 IS NULL)
              AND (gr_param.crowd_code_03 IS NULL)
                AND (gr_param.crowd_code_04 IS NULL) THEN
          gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_crowd_code_05;
        ELSIF (gr_param.crowd_code_05 IS NOT NULL) THEN
          gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_dot || gv_sql_crowd_code_05;
        END IF;
        -- 入力Ｐ 群コード６に入力有
        IF (gr_param.crowd_code_06 IS NOT NULL)
          AND (gr_param.crowd_code_01 IS NULL)
            AND (gr_param.crowd_code_02 IS NULL)
              AND (gr_param.crowd_code_03 IS NULL)
                AND (gr_param.crowd_code_04 IS NULL)
                  AND (gr_param.crowd_code_05 IS NULL) THEN
          gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_crowd_code_06;
        ELSIF (gr_param.crowd_code_06 IS NOT NULL) THEN
          gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_dot || gv_sql_crowd_code_06;
        END IF;
        -- 入力Ｐ 群コード７に入力有
        IF (gr_param.crowd_code_07 IS NOT NULL)
          AND (gr_param.crowd_code_01 IS NULL)
            AND (gr_param.crowd_code_02 IS NULL)
              AND (gr_param.crowd_code_03 IS NULL)
                AND (gr_param.crowd_code_04 IS NULL)
                  AND (gr_param.crowd_code_05 IS NULL)
                    AND (gr_param.crowd_code_06 IS NULL) THEN
          gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_crowd_code_07;
        ELSIF (gr_param.crowd_code_07 IS NOT NULL) THEN
          gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_dot || gv_sql_crowd_code_07;
        END IF;
        -- 入力Ｐ 群コード８に入力有
        IF (gr_param.crowd_code_08 IS NOT NULL)
          AND (gr_param.crowd_code_01 IS NULL)
            AND (gr_param.crowd_code_02 IS NULL)
              AND (gr_param.crowd_code_03 IS NULL)
                AND (gr_param.crowd_code_04 IS NULL)
                  AND (gr_param.crowd_code_05 IS NULL)
                    AND (gr_param.crowd_code_06 IS NULL)
                      AND (gr_param.crowd_code_07 IS NULL) THEN
          gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_crowd_code_08;
        ELSIF (gr_param.crowd_code_08 IS NOT NULL) THEN
          gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_dot || gv_sql_crowd_code_08;
        END IF;
        -- 入力Ｐ 群コード９に入力有
        IF (gr_param.crowd_code_09 IS NOT NULL)
          AND (gr_param.crowd_code_01 IS NULL)
            AND (gr_param.crowd_code_02 IS NULL)
              AND (gr_param.crowd_code_03 IS NULL)
                AND (gr_param.crowd_code_04 IS NULL)
                  AND (gr_param.crowd_code_05 IS NULL)
                    AND (gr_param.crowd_code_06 IS NULL)
                      AND (gr_param.crowd_code_07 IS NULL)
                        AND (gr_param.crowd_code_08 IS NULL) THEN
          gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_crowd_code_09;
        ELSIF (gr_param.crowd_code_09 IS NOT NULL) THEN
          gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_dot || gv_sql_crowd_code_09;
        END IF;
        -- 入力Ｐ 群コード１０に入力有
        IF (gr_param.crowd_code_10 IS NOT NULL)
          AND (gr_param.crowd_code_01 IS NULL)
            AND (gr_param.crowd_code_02 IS NULL)
              AND (gr_param.crowd_code_03 IS NULL)
                AND (gr_param.crowd_code_04 IS NULL)
                  AND (gr_param.crowd_code_05 IS NULL)
                    AND (gr_param.crowd_code_06 IS NULL)
                      AND (gr_param.crowd_code_07 IS NULL)
                        AND (gr_param.crowd_code_08 IS NULL)
                          AND (gr_param.crowd_code_09 IS NULL) THEN
          gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_crowd_code_10;
        ELSIF (gr_param.crowd_code_10 IS NOT NULL) THEN
          gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_dot || gv_sql_crowd_code_10;
        END IF;
        --  群コード抽出条件 + 右括弧
        gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_r_block;
        -- 作成ＳＱＬ文に群コード抽出条件結合
        gv_sql_sel        := gv_sql_sel || gv_sql_crowd_code;
      END IF;
    END IF;
--
--2008.04.28 Y.Kawano modify start
    -- GROUP BY句結合
    gv_sql_sel := gv_sql_sel || gv_sql_group_by;
--2008.04.28 Y.Kawano add end
--
    -- ORDER BY句結合
    gv_sql_sel := gv_sql_sel || gv_sql_order_by;
--
    -- 作成ＳＱＬ文実行
    EXECUTE IMMEDIATE gv_sql_sel BULK COLLECT INTO ot_sale_plan_1 USING gv_name_sale_plan
                                                                       ,gr_param.gen
                                                                       ,gr_param.year
                                                                       ,gv_name_prod
                                                                       ,gd_start_day
                                                                       ,gd_start_day
                                                                       ,gv_name_crowd
                                                                       ,gv_price_type   -- add 2008/04/28
                                                                       ,gd_start_day
                                                                       ,gd_start_day 
                                                                       ;
--
  EXCEPTION
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END prc_sale_plan_1;
--
  /************************************************************************************************
   * Procedure Name   : prc_create_xml_data_user
   * Description      : XMLデータ変換 - ユーザー情報部分(user_info)
   ************************************************************************************************/
  PROCEDURE prc_create_xml_data_user
    (
      ov_errbuf             OUT VARCHAR2          --    エラー・メッセージ           --# 固定 #
     ,ov_retcode            OUT VARCHAR2          --    リターン・コード             --# 固定 #
     ,ov_errmsg             OUT VARCHAR2          --    ユーザー・エラー・メッセージ --# 固定 #
    )
  IS
    -- ==================================================
    -- 固定ローカル定数
    -- ==================================================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_create_xml_data_user'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
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
    -- ルート開始タグ出力
    -- -----------------------------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'root';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
    -- ====================================================
    -- 開始タグ
    -- ====================================================
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'user_info';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
    -- ====================================================
    -- データタグ
    -- ====================================================
    -- 帳票ＩＤ
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'report_id';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    gt_xml_data_table(gl_xml_idx).tag_value := gv_report_id;
--
    -- 実行日
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'exec_date';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    gt_xml_data_table(gl_xml_idx).tag_value := TO_CHAR(SYSDATE, 'YYYY/MM/DD HH24:MI:SS');
--
    -- ログインユーザー：所属部署
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'exec_user_dept';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    gt_xml_data_table(gl_xml_idx).tag_value
        := xxcmn_common_pkg.get_user_dept(FND_GLOBAL.USER_ID);
--
    -- ログインユーザー：ユーザー名
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'exec_user_name';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    gt_xml_data_table(gl_xml_idx).tag_value
        := xxcmn_common_pkg.get_user_name(FND_GLOBAL.USER_ID);
--
    -- ====================================================
    -- 終了タグ
    -- ====================================================
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/user_info';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
  EXCEPTION
--###################################  固定例外処理部 START   #####################################
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
--#######################################  固定部 END   ###########################################
  END prc_create_xml_data_user ;
--
  /************************************************************************************************
   * Procedure Name   : prc_create_xml_data_param
   * Description      : XMLデータ変換 - パラメータ情報部分(param_info)
   ************************************************************************************************/
  PROCEDURE prc_create_xml_data_param
    (
      ov_errbuf             OUT VARCHAR2        --    エラー・メッセージ           --# 固定 #
     ,ov_retcode            OUT VARCHAR2        --    リターン・コード             --# 固定 #
     ,ov_errmsg             OUT VARCHAR2        --    ユーザー・エラー・メッセージ --# 固定 #
    )
  IS
    -- ==================================================
    -- 固定ローカル定数
    -- ==================================================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_create_xml_data_param'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
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
    -- 開始タグ
    -- ====================================================
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'param_info';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
    -- ====================================================
    -- データタグ
    -- ====================================================
    -- 年度
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'year';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    gt_xml_data_table(gl_xml_idx).tag_value := gr_param.year || gv_name_year;
--
    -- 世代
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'sdi_num';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    gt_xml_data_table(gl_xml_idx).tag_value := gr_param.gen;
--
    -- 出力単位
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'out_unit';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    -- 入力パラメータ判定
    -- [0]の場合
    IF (gr_param.output_unit = gv_output_unit) THEN
      gt_xml_data_table(gl_xml_idx).tag_value := gv_output_unit_0;
    ELSE
      gt_xml_data_table(gl_xml_idx).tag_value := gv_output_unit_1;
    END IF;
--
    -- ====================================================
    -- 終了タグ
    -- ====================================================
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/param_info';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
  EXCEPTION
--###################################  固定例外処理部 START   #####################################
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
--#######################################  固定部 END   ###########################################
  END prc_create_xml_data_param ;
--
  /**********************************************************************************
   * Procedure Name   : prc_create_xml_data
   * Description      : XMLデータ作成 - 帳票データ出力
   ***********************************************************************************/
  PROCEDURE prc_create_xml_data
    (
      ov_errbuf    OUT          VARCHAR2     --   エラー・メッセージ           --# 固定 #
     ,ov_retcode   OUT          VARCHAR2     --   リターン・コード             --# 固定 #
     ,ov_errmsg    OUT          VARCHAR2     --   ユーザー・エラー・メッセージ --# 固定 #
    )
  IS
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_create_xml_data'; -- プログラム名
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
    -- キーブレイク判断用定数
    lc_break_init        VARCHAR2(5)           := '*****';
--
    lc_name_leaf         CONSTANT VARCHAR2(10) := 'リーフ';
    lc_name_drink        CONSTANT VARCHAR2(10) := 'ドリンク';
--
    -- *** ローカル変数 ***
    lv_skbn_name         VARCHAR2(10);
--
    -- ブレイクキー判断用変数
    lv_skbn_break        mtl_categories_b.segment1%TYPE; -- 商品区分判定用
    lv_ktn_break         VARCHAR2(20);                   -- 拠点判断用
    lv_gun_break         VARCHAR2(10);                   -- 群コード判断用
    lv_dtl_break         VARCHAR2(10);                   -- 品目判断用
    lv_sttl_break        VARCHAR2(10);                   -- 小群計判断用
    lv_mttl_break        VARCHAR2(10);                   -- 中郡計判断用
    lv_lttl_break        VARCHAR2(10);                   -- 大群計判断用
--
    -- 計判定用
    lv_gun_s             VARCHAR2(5);                    -- 小群計用（群コード上３桁）
    lv_gun_m             VARCHAR2(5);                    -- 中群計用（群コード上２桁）
    lv_gun_l             VARCHAR2(5);                    -- 大群計用（群コード上１桁）
--
    -- ０除算判定用
    ln_chk_0             NUMBER;                         -- ０除算判定項目
--
    -- 計算用変数
    ln_output_unit       NUMBER;                         -- 数量計算（出力単位 = ケース）
    ln_s_u_price         NUMBER;                         -- 標準原価計算用
    ln_arari             NUMBER;                         -- 粗利計算用
    ln_price             NUMBER;                         -- 品目定価
    ln_arari_par         NUMBER(8,2);                    -- 粗利率用
    ln_kake_par          NUMBER(8,2);                    -- 掛率
    ln_syo_arari_par     NUMBER(8,2);                    -- 細群計(粗利率)
    ln_syo_kake_par      NUMBER(8,2);                    -- 細群計(掛率)
    ln_syo_s_unit_price  NUMBER;                         -- 細群計(標準原価)
    ln_sttl_arari_par    NUMBER(8,2);                    -- 小群計(粗利率)
    ln_sttl_kake_par     NUMBER(8,2);                    -- 小群計(掛率)
    ln_sttl_s_unit_price NUMBER;                         -- 小群計(標準原価)
    ln_mttl_arari_par    NUMBER(8,2);                    -- 中群計(粗利率)
    ln_mttl_kake_par     NUMBER(8,2);                    -- 中群計(掛率)
    ln_mttl_s_unit_price NUMBER;                         -- 中群計(標準原価)
    ln_lttl_arari_par    NUMBER(8,2);                    -- 大群計(粗利率)
    ln_lttl_kake_par     NUMBER(8,2);                    -- 大群計(掛率)
    ln_lttl_s_unit_price NUMBER;                         -- 大群計(標準原価)
    ln_ktn_arari_par     NUMBER(8,2);                    -- 拠点計(粗利率)
    ln_ktn_kake_par      NUMBER(8,2);                    -- 拠点計(掛率)
    ln_ktn_s_unit_price  NUMBER;                         -- 拠点計(標準原価)
    ln_skbn_arari_par    NUMBER(8,2);                    -- 商品区分計(粗利率)
    ln_skbn_kake_par     NUMBER(8,2);                    -- 商品区分計(掛率)
    ln_skbn_s_unit_price NUMBER;                         -- 商品区分計(標準原価)
    ln_to_arari_par      NUMBER(8,2);                    -- 総合計(粗利率)
    ln_to_kake_par       NUMBER(8,2);                    -- 総合計(掛率)
    ln_to_s_unit_price   NUMBER;                         -- 総合計(標準原価)
--
    -- 細群計計算用項目変数
    ln_arari_sum         NUMBER := 0;                    -- 粗利
    ln_s_am_sum          NUMBER := 0;                    -- 売上高
    ln_nuit_sum          NUMBER := 0;                    -- 本数
    ln_price_sum         NUMBER := 0;                    -- 品目定価
-- 2009/04/20 v1.8 UPDATE START
--    ln_to_am_sum         NUMBER := 0;                    -- 内訳合計
    ln_s_unit_price_sum  NUMBER := 0;                    -- 標準原価
    ln_ara_sum           NUMBER := 0;                    -- 粗利(集計用)
    ln_chk_0_sum         NUMBER := 0;                    -- 掛率(集計用)
-- 2009/04/20 v1.8 UPDATE END
    ln_quant_sum         NUMBER := 0;                    -- 数量
--
    -- 小群計計算用項目変数
    ln_st_quant_sum      NUMBER := 0;                    -- 数量
-- 2009/04/20 v1.8 UPDATE START
--    ln_st_s_u_price_sum  NUMBER := 0;                    -- 内訳合計
    ln_st_s_unit_price_sum  NUMBER := 0;                 -- 標準原価
    ln_st_ara_sum           NUMBER := 0;                 -- 粗利(集計用)
    ln_st_chk_0_sum         NUMBER := 0;                 -- 掛率(集計用)
-- 2009/04/20 v1.8 UPDATE END
    ln_st_arari_sum      NUMBER := 0;                    -- 粗利
    ln_st_s_am_sum       NUMBER := 0;                    -- 売上高
    ln_st_nuit_sum       NUMBER := 0;                    -- 本数
    ln_st_price_sum      NUMBER := 0;                    -- 品目定価
--
    -- 中群計計算用項目変数
    ln_mt_quant_sum      NUMBER := 0;                    -- 数量
-- 2009/04/20 v1.8 UPDATE START
--    ln_mt_s_u_price_sum  NUMBER := 0;                    -- 内訳合計
    ln_mt_s_unit_price_sum  NUMBER := 0;                 -- 標準原価
    ln_mt_ara_sum           NUMBER := 0;                 -- 粗利(集計用)
    ln_mt_chk_0_sum         NUMBER := 0;                 -- 掛率(集計用)
-- 2009/04/20 v1.8 UPDATE END
    ln_mt_arari_sum      NUMBER := 0;                    -- 粗利
    ln_mt_s_am_sum       NUMBER := 0;                    -- 売上高
    ln_mt_nuit_sum       NUMBER := 0;                    -- 本数
    ln_mt_price_sum      NUMBER := 0;                    -- 品目定価
--
    -- 大群計計算用項目変数
    ln_lt_quant_sum      NUMBER := 0;                    -- 数量
-- 2009/04/20 v1.8 UPDATE START
--    ln_lt_s_u_price_sum  NUMBER := 0;                    -- 内訳合計
    ln_lt_s_unit_price_sum  NUMBER := 0;                 -- 標準原価
    ln_lt_ara_sum           NUMBER := 0;                 -- 粗利(集計用)
    ln_lt_chk_0_sum         NUMBER := 0;                 -- 掛率(集計用)
-- 2009/04/20 v1.8 UPDATE END
    ln_lt_arari_sum      NUMBER := 0;                    -- 粗利
    ln_lt_s_am_sum       NUMBER := 0;                    -- 売上高
    ln_lt_nuit_sum       NUMBER := 0;                    -- 本数
    ln_lt_price_sum      NUMBER := 0;                    -- 品目定価
--
    -- 拠点計計算用項目変数
    ln_ktn_arari_sum     NUMBER := 0;                    -- 粗利
    ln_ktn_s_am_sum      NUMBER := 0;                    -- 売上高
    ln_ktn_nuit_sum      NUMBER := 0;                    -- 本数
    ln_ktn_price_sum     NUMBER := 0;                    -- 品目定価
-- 2009/04/20 v1.8 UPDATE START
--    ln_ktn_to_am_sum     NUMBER := 0;                    -- 内訳合計
    ln_ktn_s_unit_price_sum  NUMBER := 0;                -- 標準原価
    ln_ktn_ara_sum           NUMBER := 0;                -- 粗利(集計用)
    ln_ktn_chk_0_sum         NUMBER := 0;                -- 掛率(集計用)
-- 2009/04/20 v1.8 UPDATE END
    ln_ktn_quant_sum     NUMBER := 0;                    -- 数量
--
    -- 商品区分計計算用項目変数
    ln_skbn_arari_sum    NUMBER := 0;                    -- 粗利
    ln_skbn_s_am_sum     NUMBER := 0;                    -- 売上高
    ln_skbn_nuit_sum     NUMBER := 0;                    -- 本数
    ln_skbn_price_sum    NUMBER := 0;                    -- 品目定価
-- 2009/04/20 v1.8 UPDATE START
--    ln_skbn_to_am_sum    NUMBER := 0;                    -- 内訳合計
    ln_skbn_s_unit_price_sum  NUMBER := 0;               -- 標準原価
    ln_skbn_ara_sum           NUMBER := 0;               -- 粗利(集計用)
    ln_skbn_chk_0_sum         NUMBER := 0;               -- 掛率(集計用)
-- 2009/04/20 v1.8 UPDATE END
    ln_skbn_quant_sum    NUMBER := 0;                    -- 数量
--
    -- 総合計計算用項目変数
    ln_to_arari_sum      NUMBER := 0;                    -- 粗利
    ln_to_s_am_sum       NUMBER := 0;                    -- 売上高
    ln_to_nuit_sum       NUMBER := 0;                    -- 本数
    ln_to_price_sum      NUMBER := 0;                    -- 品目定価
-- 2009/04/20 v1.8 UPDATE START
--    ln_to_to_am_sum      NUMBER := 0;                    -- 内訳合計
    ln_to_s_unit_price_sum  NUMBER := 0;                 -- 標準原価
    ln_to_ara_sum           NUMBER := 0;                 -- 粗利(集計用)
    ln_to_chk_0_sum         NUMBER := 0;                 -- 掛率(集計用)
-- 2009/04/20 v1.8 UPDATE END
    ln_to_quant_sum      NUMBER := 0;                    -- 数量
--
    -- *** ローカル・例外処理 ***
    no_data_expt         EXCEPTION;                      -- 取得レコード０件時
--
  BEGIN
--
    -- =====================================================
    -- ブレイクキー初期化
    -- =====================================================
    lv_skbn_break  := lc_break_init;   -- 商品区分判定用BK
    lv_ktn_break   := lc_break_init;   -- 拠点区分判定用BK
    lv_gun_break   := lc_break_init;   -- 群コード判定用BK
    lv_sttl_break  := lc_break_init;   -- 小群計判定用BK
    lv_mttl_break  := lc_break_init;   -- 中群計判定用BK
    lv_lttl_break  := lc_break_init;   -- 大群計判定用BK
--
    -- 出力種別が「全拠点」の場合
    IF (gr_param.output_type = gv_name_ktn) THEN
      -- =====================================================
      -- データ抽出 - 販売計画表情報抽出 (B-1-1-1)
      -- =====================================================
      prc_sale_plan
        (
          ot_sale_plan      => gr_sale_plan       -- 取得レコード群
         ,ov_errbuf         => lv_errbuf          -- エラー・メッセージ           --# 固定 #
         ,ov_retcode        => lv_retcode         -- リターン・コード             --# 固定 #
         ,ov_errmsg         => lv_errmsg          -- ユーザー・エラー・メッセージ --# 固定 #
        ) ;
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
--
      -- 取得データが０件の場合
      ELSIF (gr_sale_plan.COUNT = 0) THEN
        RAISE no_data_expt;
--
      END IF;
--
    -- =====================================================
    -- 項目データ抽出・出力処理
    -- =====================================================
    -- -----------------------------------------------------
    -- データ開始タグ出力
    -- -----------------------------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'data_info';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
    -- -----------------------------------------------------
    -- 商品区分開始ＬＧタグ出力
    -- -----------------------------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_skbn_info';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
    -- =====================================================
    -- 項目データ抽出・出力処理
    -- =====================================================
    <<main_data_loop>>
    FOR i IN 1..gr_sale_plan.COUNT LOOP
      -- ====================================================
      --  商品区分ブレイク
      -- ====================================================
      -- 商品区分が切り替わったとき
      IF (gr_sale_plan(i).skbn <> lv_skbn_break) THEN
        -- ====================================================
        --  商品区分終了Ｇタグ出力判定
        -- ====================================================
        -- 最初のレコードの時は出力せず
        IF (lv_skbn_break <> lc_break_init) THEN
          -- -----------------------------------------------------
          --  品目終了ＬＧタグ出力
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_dtl_info';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
          ----------------------------------------------------------------
          -- 細群計(標準原価)データ
          ----------------------------------------------------------------
          -- 標準原価算出
-- 2009/04/20 v1.8 UPDATE START
--          ln_syo_s_unit_price := ln_to_am_sum * ln_quant_sum;
          ln_syo_s_unit_price := ln_s_unit_price_sum;
-- 2009/04/20 v1.8 UPDATE END
--
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'syo_s_unit_price';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          gt_xml_data_table(gl_xml_idx).tag_value := ln_syo_s_unit_price;
--
          ----------------------------------------------------------------
          -- 細群計(粗利)データ
          ----------------------------------------------------------------
          -- 粗利算出
-- 2009/04/20 v1.8 UPDATE START
--          ln_arari_sum := ln_s_am_sum - ln_syo_s_unit_price;
          ln_arari_sum := ln_ara_sum;
-- 2009/04/20 v1.8 UPDATE END
--
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'syo_arari';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          gt_xml_data_table(gl_xml_idx).tag_value := ln_arari_sum;
--
          ----------------------------------------------------------------
          -- 細群計(粗利率)データ  ((粗利/売上高)*100)
          ----------------------------------------------------------------
          -- ０除算回避判定
          IF (ln_s_am_sum <> 0) THEN
            -- 値が[0]出なければ計算
            ln_syo_arari_par := ROUND((ln_arari_sum / ln_s_am_sum) * 100,2);
          ELSE
            -- 値が[0]の場合は、一律[0]設定
            ln_syo_arari_par := gn_0;
          END IF;
--
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'syo_arari_par';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          gt_xml_data_table(gl_xml_idx).tag_value := ln_syo_arari_par;
--
          ----------------------------------------------------------------
          -- 細群計(掛率)データ  ((売上高*100)/(品目定価*本数))
          ----------------------------------------------------------------
-- 2009/04/20 v1.8 UPDATE START
/*
          -- ０除算判定項目へ判定値を挿入
          ln_chk_0 := ln_price_sum * ln_nuit_sum;
          -- ０除算回避判定
          IF (ln_chk_0 <> 0) THEN
            -- 値が[0]出なければ計算
            ln_syo_kake_par := ROUND((ln_s_am_sum * 100) / ln_chk_0,2);
          ELSE
            -- 値が[0]の場合は、一律[0]設定
            ln_syo_kake_par := gn_0;
          END IF;
*/
          -- ０除算回避判定
          IF (ln_chk_0_sum <> 0) THEN
            -- 値が[0]出なければ計算
            ln_syo_kake_par := ROUND((ln_s_am_sum * 100) / ln_chk_0_sum, 2);
          ELSE
            -- 値が[0]の場合は、一律[0]設定
            ln_syo_kake_par := gn_0;
          END IF;
-- 2009/04/20 v1.8 UPDATE END
--
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'syo_kake_par';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          -- 品目定価 = ０か、計算結果がマイナスの場合、固定値を登録
          IF (ln_price_sum = 0) 
            OR (ln_syo_kake_par < 0)THEN
            gt_xml_data_table(gl_xml_idx).tag_value := TO_NUMBER(gv_name_kotei); -- 固定値:70.00
          -- 品目定価 <> ０、計算結果がマイナスではない場合、計算結果を登録
          ELSE
            gt_xml_data_table(gl_xml_idx).tag_value := ln_syo_kake_par;
          END IF;
--
          ----------------------------------------------------------------
          -- 小群計(数量)データ
          ----------------------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'sttl_quant';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          gt_xml_data_table(gl_xml_idx).tag_value := ln_st_quant_sum;
--
          ----------------------------------------------------------------
          -- 小群計(売上高)データ
          ----------------------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'sttl_sales_amount';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          gt_xml_data_table(gl_xml_idx).tag_value := ln_st_s_am_sum;
--
          ----------------------------------------------------------------
          -- 小群計(標準原価)データ
          ----------------------------------------------------------------
          -- 標準原価算出
-- 2009/04/20 v1.8 UPDATE START
--          ln_sttl_s_unit_price := ln_st_s_u_price_sum * ln_st_quant_sum;
          ln_sttl_s_unit_price := ln_st_s_unit_price_sum;
-- 2009/04/20 v1.8 UPDATE END
--
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'sttl_s_unit_price';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          gt_xml_data_table(gl_xml_idx).tag_value := ln_sttl_s_unit_price;
--
          ----------------------------------------------------------------
          -- 小群計(粗利)データ
          ----------------------------------------------------------------
          -- 粗利算出
-- 2009/04/20 v1.8 UPDATE START
--          ln_st_arari_sum := ln_s_am_sum - ln_syo_s_unit_price;
          ln_st_arari_sum := ln_st_ara_sum;
-- 2009/04/20 v1.8 UPDATE END
--
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'sttl_arari';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          gt_xml_data_table(gl_xml_idx).tag_value := ln_st_arari_sum;
--
          ----------------------------------------------------------------
          -- 小群計(粗利率)データ  ((粗利/売上高)*100)
          ----------------------------------------------------------------
          -- ０除算回避判定
          IF (ln_st_s_am_sum <> 0) THEN
            -- 値が[0]出なければ計算
            ln_sttl_arari_par := ROUND((ln_st_arari_sum / ln_st_s_am_sum) * 100,2);
          ELSE
            -- 値が[0]の場合は、一律[0]設定
            ln_sttl_arari_par := gn_0;
          END IF;
--
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'sttl_arari_par';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          gt_xml_data_table(gl_xml_idx).tag_value := ln_sttl_arari_par;
--
          ----------------------------------------------------------------
          -- 小群計(掛率)データ  ((売上高*100)/(品目定価*本数))
          ----------------------------------------------------------------
-- 2009/04/20 v1.8 UPDATE START
/*
          -- ０除算判定項目へ判定値を挿入
          ln_chk_0 := ln_st_price_sum * ln_st_nuit_sum;
          -- ０除算回避判定
          IF (ln_chk_0 <> 0) THEN
            -- 値が[0]出なければ計算
            ln_sttl_kake_par := ROUND((ln_st_s_am_sum * 100) / ln_chk_0,2);
          ELSE
            -- 値が[0]の場合は、一律[0]設定
            ln_sttl_kake_par := gn_0;
          END IF;
*/
          -- ０除算回避判定
          IF (ln_st_chk_0_sum <> 0) THEN
            -- 値が[0]出なければ計算
            ln_sttl_kake_par := ROUND((ln_st_s_am_sum * 100) / ln_st_chk_0_sum, 2);
          ELSE
            -- 値が[0]の場合は、一律[0]設定
            ln_sttl_kake_par := gn_0;
          END IF;
-- 2009/04/20 v1.8 UPDATE END
--
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'sttl_kake_par';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          -- 品目定価 = ０か、計算結果がマイナスの場合、固定値を登録
          IF (ln_st_price_sum = 0)
            OR (ln_sttl_kake_par < 0) THEN
            gt_xml_data_table(gl_xml_idx).tag_value := TO_NUMBER(gv_name_kotei); -- 固定値:70.00
            -- 品目定価 <> ０、計算結果がマイナスではない場合、計算結果を登録
          ELSE
            gt_xml_data_table(gl_xml_idx).tag_value := ln_sttl_kake_par;
          END IF;
--
          ----------------------------------------------------------------
          -- 中群計(数量)データ
          ----------------------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'mttl_quant';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          gt_xml_data_table(gl_xml_idx).tag_value := ln_mt_quant_sum;
--
          ----------------------------------------------------------------
          -- 中群計(売上高)データ
          ----------------------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'mttl_sales_amount';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          gt_xml_data_table(gl_xml_idx).tag_value := ln_mt_s_am_sum;
--
          ----------------------------------------------------------------
          -- 中群計(標準原価)データ
          ----------------------------------------------------------------
          -- 標準原価算出
-- 2009/04/20 v1.8 UPDATE START
--          ln_mttl_s_unit_price := ln_mt_s_u_price_sum * ln_mt_quant_sum;
          ln_mttl_s_unit_price := ln_mt_s_unit_price_sum;
-- 2009/04/20 v1.8 UPDATE END
--
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'mttl_s_unit_price';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          gt_xml_data_table(gl_xml_idx).tag_value := ln_mttl_s_unit_price;
--
          ----------------------------------------------------------------
          -- 中群計(粗利)データ
          ----------------------------------------------------------------
          -- 粗利算出
-- 2009/04/20 v1.8 UPDATE START
--          ln_mt_arari_sum := ln_mt_s_am_sum - ln_mttl_s_unit_price;
          ln_mt_arari_sum := ln_mt_ara_sum;
-- 2009/04/20 v1.8 UPDATE END
--
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'mttl_arari';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          gt_xml_data_table(gl_xml_idx).tag_value := ln_mt_arari_sum;
--
          ----------------------------------------------------------------
          -- 中群計(粗利率)データ  ((粗利/売上高)*100)
          ----------------------------------------------------------------
          --  ０除算回避判定
          IF (ln_mt_s_am_sum <> 0) THEN
            -- 値が[0]出なければ計算
            ln_mttl_arari_par := ROUND((ln_mt_arari_sum / ln_mt_s_am_sum) * 100,2);
          ELSE
            -- 値が[0]の場合は、一律[0]設定
            ln_mttl_arari_par := gn_0;
          END IF;
--
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'mttl_arari_par';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          gt_xml_data_table(gl_xml_idx).tag_value := ln_mttl_arari_par;
--
          ----------------------------------------------------------------
          -- 中群計(掛率)データ  ((売上高*100)/(品目定価*本数))
          ----------------------------------------------------------------
-- 2009/04/20 v1.8 UPDATE START
/*
          -- ０除算判定項目へ判定値を挿入
          ln_chk_0 := ln_mt_price_sum * ln_mt_nuit_sum;
          -- ０除算回避判定
          IF (ln_chk_0 <> 0) THEN
            -- 値が[0]出なければ計算
            ln_mttl_kake_par := ROUND((ln_mt_s_am_sum * 100) / ln_chk_0,2);
          ELSE
            -- 値が[0]の場合は、一律[0]設定
            ln_mttl_kake_par := gn_0;
          END IF;
*/
          -- ０除算回避判定
          IF (ln_mt_chk_0_sum <> 0) THEN
            -- 値が[0]出なければ計算
            ln_mttl_kake_par := ROUND((ln_mt_s_am_sum * 100) / ln_mt_chk_0_sum, 2);
          ELSE
            -- 値が[0]の場合は、一律[0]設定
            ln_mttl_kake_par := gn_0;
          END IF;
-- 2009/04/20 v1.8 UPDATE END
--
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'mttl_kake_par';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          -- 品目定価 = ０か、計算結果がマイナスの場合、固定値を登録
          IF (ln_mt_price_sum = 0)
            OR (ln_mttl_kake_par < 0) THEN
            gt_xml_data_table(gl_xml_idx).tag_value := TO_NUMBER(gv_name_kotei); -- 固定値:70.00
          -- 品目定価 <> ０、計算結果がマイナスではない場合、計算結果を登録
          ELSE
            gt_xml_data_table(gl_xml_idx).tag_value := ln_mttl_kake_par;
          END IF;
--
          ----------------------------------------------------------------
          -- 大群計(数量)データ
          ----------------------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'lttl_quant';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          gt_xml_data_table(gl_xml_idx).tag_value := ln_lt_quant_sum;
--
          ----------------------------------------------------------------
          -- 大群計(売上高)データ
          ----------------------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'lttl_sales_amount';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          gt_xml_data_table(gl_xml_idx).tag_value := ln_lt_s_am_sum;
--
          ----------------------------------------------------------------
          -- 大群計(標準原価)データ
          ----------------------------------------------------------------
          -- 標準原価算出
-- 2009/04/20 v1.8 UPDATE START
--          ln_lttl_s_unit_price := ln_lt_s_u_price_sum * ln_lt_quant_sum;
          ln_lttl_s_unit_price := ln_lt_s_unit_price_sum;
-- 2009/04/20 v1.8 UPDATE END
--
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'lttl_s_unit_price';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          gt_xml_data_table(gl_xml_idx).tag_value := ln_lttl_s_unit_price;
--
          ----------------------------------------------------------------
          -- 大群計(粗利)データ
          ----------------------------------------------------------------
          -- 粗利算出
-- 2009/04/20 v1.8 UPDATE START
--          ln_lt_arari_sum := ln_lt_s_am_sum - ln_lttl_s_unit_price;
          ln_lt_arari_sum := ln_lt_ara_sum;
-- 2009/04/20 v1.8 UPDATE END
--
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'lttl_arari';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          gt_xml_data_table(gl_xml_idx).tag_value := ln_lt_arari_sum;
--
          ----------------------------------------------------------------
          -- 大群計(粗利率)データ  ((粗利/売上高)*100)
          ----------------------------------------------------------------
          -- ０除算回避判定
          IF (ln_lt_s_am_sum <> 0) THEN
            -- 値が[0]出なければ計算
            ln_lttl_arari_par := ROUND((ln_lt_arari_sum / ln_lt_s_am_sum) * 100,2);
          ELSE
            -- 値が[0]の場合は、一律[0]設定
            ln_lttl_arari_par := gn_0;
          END IF;
--
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'lttl_arari_par';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          gt_xml_data_table(gl_xml_idx).tag_value := ln_lttl_arari_par;
--
          ----------------------------------------------------------------
          -- 大群計(掛率)データ  ((売上高*100)/(品目定価*本数))
          ----------------------------------------------------------------
-- 2009/04/20 v1.8 UPDATE START
/*
          -- ０除算判定項目へ判定値を挿入
          ln_chk_0 := ln_lt_price_sum * ln_lt_nuit_sum;
          -- ０除算回避判定
          IF (ln_chk_0 <> 0) THEN
            -- 値が[0]出なければ計算
            ln_lttl_kake_par := ROUND((ln_lt_s_am_sum * 100) / ln_chk_0,2);
          ELSE
            -- 値が[0]の場合は、一律[0]設定
            ln_lttl_kake_par := gn_0;
          END IF;
*/
          -- ０除算回避判定
          IF (ln_lt_chk_0_sum <> 0) THEN
            -- 値が[0]出なければ計算
            ln_lttl_kake_par := ROUND((ln_lt_s_am_sum * 100) / ln_lt_chk_0_sum, 2);
          ELSE
            -- 値が[0]の場合は、一律[0]設定
            ln_lttl_kake_par := gn_0;
          END IF;
-- 2009/04/20 v1.8 UPDATE END
--
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'lttl_kake_par';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          -- 品目定価 = ０か、計算結果がマイナスの場合、固定値を登録
          IF (ln_lt_price_sum = 0)
            OR (ln_lttl_kake_par < 0) THEN
            gt_xml_data_table(gl_xml_idx).tag_value := TO_NUMBER(gv_name_kotei);  -- 固定値:70.00
          -- 品目定価 <> ０、計算結果がマイナスではない場合、計算結果を登録
          ELSE
            gt_xml_data_table(gl_xml_idx).tag_value := ln_lttl_kake_par;
          END IF;
--
          -- -----------------------------------------------------
          --  群コード終了Ｇタグ出力
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_gun';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
          -- -----------------------------------------------------
          --  群コード終了ＬＧタグ出力
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_gun_info';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
          ----------------------------------------------------------------
          -- 拠点計(標準原価)データ
          ----------------------------------------------------------------
          -- 標準原価算出
-- 2009/04/20 v1.8 UPDATE START
--          ln_ktn_s_unit_price := ln_ktn_to_am_sum * ln_ktn_quant_sum;
          ln_ktn_s_unit_price := ln_ktn_s_unit_price_sum;
-- 2009/04/20 v1.8 UPDATE END
--
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'ktn_s_unit_price';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          gt_xml_data_table(gl_xml_idx).tag_value := ln_ktn_s_unit_price;
--
          ----------------------------------------------------------------
          -- 拠点計(粗利)データ
          ----------------------------------------------------------------
          -- 粗利算出
-- 2009/04/20 v1.8 UPDATE START
--          ln_ktn_arari_sum := ln_ktn_s_am_sum - ln_ktn_s_unit_price;
          ln_ktn_arari_sum := ln_ktn_ara_sum;
-- 2009/04/20 v1.8 UPDATE END
--
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'ktn_arari';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          gt_xml_data_table(gl_xml_idx).tag_value := ln_ktn_arari_sum;
--
          ----------------------------------------------------------------
          -- 拠点計(粗利率)データ  ((粗利/売上高)*100)
          ----------------------------------------------------------------
          -- ０除算回避判定
          IF (ln_ktn_s_am_sum <> 0) THEN
            -- 値が[0]出なければ計算
            ln_ktn_arari_par := ROUND((ln_ktn_arari_sum / ln_ktn_s_am_sum) * 100,2);
          ELSE
            -- 値が[0]の場合は、一律[0]設定
            ln_ktn_arari_par := gn_0;
          END IF;
--
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'ktn_arari_par';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          gt_xml_data_table(gl_xml_idx).tag_value := ln_ktn_arari_par;
--
          ----------------------------------------------------------------
          -- 拠点計(掛率)データ  ((売上高*100)/(品目定価*本数))
          ----------------------------------------------------------------
-- 2009/04/20 v1.8 UPDATE START
/*
          -- ０除算判定項目へ判定値を挿入
          ln_chk_0 := ln_ktn_price_sum * ln_ktn_nuit_sum;
          -- ０除算回避判定
          IF (ln_chk_0 <> 0) THEN
            -- 値が[0]出なければ計算
            ln_ktn_kake_par := ROUND((ln_ktn_s_am_sum * 100) / ln_chk_0,2);
          ELSE
            -- 値が[0]の場合は、一律[0]設定
            ln_ktn_kake_par := gn_0;
          END IF;
*/
          -- ０除算回避判定
          IF (ln_ktn_chk_0_sum <> 0) THEN
            -- 値が[0]出なければ計算
            ln_ktn_kake_par := ROUND((ln_ktn_s_am_sum * 100) / ln_ktn_chk_0_sum, 2);
          ELSE
            -- 値が[0]の場合は、一律[0]設定
            ln_ktn_kake_par := gn_0;
          END IF;
-- 2009/04/20 v1.8 UPDATE END
--
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'ktn_kake_par';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          -- 品目定価 = ０か、計算結果がマイナスの場合、固定値を登録
          IF (ln_ktn_price_sum = 0)
            OR (ln_ktn_kake_par < 0) THEN
            gt_xml_data_table(gl_xml_idx).tag_value := TO_NUMBER(gv_name_kotei); -- 固定値:70.00
          -- 品目定価 <> ０、計算結果がマイナスではない場合、計算結果を登録
          ELSE
            gt_xml_data_table(gl_xml_idx).tag_value := ln_ktn_kake_par;
          END IF;
--
          -- -----------------------------------------------------
          --  拠点終了Ｇタグ出力
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_ktn';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
          -- -----------------------------------------------------
          --  拠点終了ＬＧタグ出力
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_ktn_info';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
          ----------------------------------------------------------------
          -- 商品区分計(標準原価)データ
          ----------------------------------------------------------------
          -- 標準原価算出
-- 2009/04/20 v1.8 UPDATE START
--          ln_skbn_s_unit_price := ln_skbn_to_am_sum * ln_skbn_quant_sum;
          ln_skbn_s_unit_price := ln_skbn_s_unit_price_sum;
-- 2009/04/20 v1.8 UPDATE END
--
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'skbn_s_unit_price';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          gt_xml_data_table(gl_xml_idx).tag_value := ln_skbn_s_unit_price;
--
          ----------------------------------------------------------------
          -- 商品区分計(粗利)データ
          ----------------------------------------------------------------
          -- 粗利算出
-- 2009/04/20 v1.8 UPDATE START
--          ln_skbn_arari_sum := ln_skbn_s_am_sum - ln_skbn_s_unit_price;
          ln_skbn_arari_sum := ln_skbn_ara_sum;
-- 2009/04/20 v1.8 UPDATE END
--
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'skbn_arari';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          gt_xml_data_table(gl_xml_idx).tag_value := ln_skbn_arari_sum;
--
          ----------------------------------------------------------------
          -- 商品区分計(粗利率)データ  ((粗利/売上高)*100)
          ----------------------------------------------------------------
          -- ０除算回避判定
          IF (ln_skbn_s_am_sum <> 0) THEN
            -- 値が[0]出なければ計算
            ln_skbn_arari_par := ROUND((ln_skbn_arari_sum / ln_skbn_s_am_sum) * 100,2);
          ELSE
            -- 値が[0]の場合は、一律[0]設定
            ln_skbn_arari_par := gn_0;
          END IF;
--
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'skbn_arari_par';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          gt_xml_data_table(gl_xml_idx).tag_value := ln_skbn_arari_par;
--
          ----------------------------------------------------------------
          -- 商品区分計(掛率)データ  ((売上高*100)/(品目定価*本数))
          ----------------------------------------------------------------
-- 2009/04/20 v1.8 UPDATE START
/*
          -- ０除算判定項目へ判定値を挿入
          ln_chk_0 := ln_skbn_price_sum * ln_skbn_nuit_sum;
          -- ０除算回避判定
          IF (ln_chk_0 <> 0) THEN
            -- 値が[0]出なければ計算
            ln_skbn_kake_par := ROUND((ln_skbn_s_am_sum * 100) / ln_chk_0,2);
          ELSE
            -- 値が[0]の場合は、一律[0]設定
            ln_skbn_kake_par := gn_0;
          END IF;
*/
          -- ０除算回避判定
          IF (ln_skbn_chk_0_sum <> 0) THEN
            -- 値が[0]出なければ計算
            ln_skbn_kake_par := ROUND((ln_skbn_s_am_sum * 100) / ln_skbn_chk_0_sum, 2);
          ELSE
            -- 値が[0]の場合は、一律[0]設定
            ln_skbn_kake_par := gn_0;
          END IF;
-- 2009/04/20 v1.8 UPDATE END
--
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'skbn_kake_par';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          -- 品目定価 = ０か、計算結果がマイナスの場合、固定値を登録
          IF (ln_skbn_price_sum = 0)
            OR (ln_skbn_kake_par < 0) THEN
            gt_xml_data_table(gl_xml_idx).tag_value := TO_NUMBER(gv_name_kotei); -- 固定値:70.00
          -- 品目定価 <> ０、計算結果がマイナスではない場合、計算結果を登録
          ELSE
            gt_xml_data_table(gl_xml_idx).tag_value := ln_skbn_kake_par;
          END IF;
--
          -- -----------------------------------------------------
          --  商品区分終了Ｇタグ出力
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_skbn';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
        END IF;
--
        -- -----------------------------------------------------
        --  商品区分開始Ｇタグ出力
        -- -----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'g_skbn';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
        -- 商品区分(名称)判定
        -- 入力Ｐが'1' or 入力ＰがNULLで抽出データが'1'の場合
        IF (gr_param.prod_div = gv_prod_div_leaf)
          OR (gr_param.prod_div IS NULL
            AND gr_sale_plan(i).skbn = gv_prod_div_leaf) THEN
          lv_skbn_name := lc_name_leaf;        -- 商品区分(名称)に「リーフ」を出力
        -- 入力Ｐが'2' or 入力ＰがNULLで抽出データが'2'の場合
        ELSIF (gr_param.prod_div = gv_prod_div_drink)
          OR (gr_param.prod_div IS NULL
            AND gr_sale_plan(i).skbn = gv_prod_div_drink) THEN
          lv_skbn_name := lc_name_drink;   -- 商品区分(名称)に「ドリンク」を出力
        END IF;
--
        ----------------------------------------------------------------
        -- 商品区分(コード) タグ
        ----------------------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'skbn_code';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
        gt_xml_data_table(gl_xml_idx).tag_value := gr_sale_plan(i).skbn;
--
        ----------------------------------------------------------------
        -- 商品区分(名称) タグ
        ----------------------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'skbn_name';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
        gt_xml_data_table(gl_xml_idx).tag_value := lv_skbn_name;
--
        -- -----------------------------------------------------
        --  拠点区分開始ＬＧタグ出力
        -- -----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_ktn_info';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
        -- -----------------------------------------------------
        --  拠点区分開始Ｇタグ出力
        -- -----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'g_ktn';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
        ----------------------------------------------------------------
        -- 拠点区分(拠点コード) タグ
        ----------------------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'ktn_code';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
        gt_xml_data_table(gl_xml_idx).tag_value := '';          -- 全拠点の場合、NULL表示
--
        ----------------------------------------------------------------
        -- 拠点区分(拠点略称) タグ
        ----------------------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'ktn_name';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
        gt_xml_data_table(gl_xml_idx).tag_value := gv_name_ktn; -- '全拠点'
--
        -- -----------------------------------------------------
        --  群コード開始LＧタグ出力
        -- -----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_gun_info';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
        -- -----------------------------------------------------
        --  群コード開始Ｇタグ出力
        -- -----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'g_gun';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
        -- -----------------------------------------------------
        --  品目開始ＬＧタグ出力
        -- -----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_dtl_info';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
        -- 各ブレイクキー更新
        lv_skbn_break := gr_sale_plan(i).skbn;               -- 商品区分
        lv_gun_break  := gr_sale_plan(i).gun;                -- 群コード
        lv_sttl_break := SUBSTRB(gr_sale_plan(i).gun,1,3);   -- 小群計
        lv_mttl_break := SUBSTRB(gr_sale_plan(i).gun,1,2);   -- 中群計
        lv_lttl_break := SUBSTRB(gr_sale_plan(i).gun,1,1);   -- 大群計
--
        -- 小群計集計用項目初期化
        ln_st_quant_sum     := 0;          -- 数量
-- 2009/04/20 v1.8 UPDATE START
--        ln_st_s_u_price_sum := 0;          -- 内訳合計
        ln_st_s_unit_price_sum := 0;       -- 標準原価
        ln_st_ara_sum          := 0;       -- 粗利(集計用)
        ln_st_chk_0_sum        := 0;       -- 掛率(集計用)
-- 2009/04/20 v1.8 UPDATE END
        ln_st_arari_sum     := 0;          -- 粗利
        ln_st_s_am_sum      := 0;          -- 売上高
        ln_st_nuit_sum      := 0;          -- 本数
        ln_st_price_sum     := 0;          -- 品目定価
        -- 中群計集計用項目初期化
        ln_mt_quant_sum     := 0;          -- 数量
-- 2009/04/20 v1.8 UPDATE START
--        ln_mt_s_u_price_sum := 0;          -- 内訳合計
        ln_mt_s_unit_price_sum := 0;       -- 標準原価
        ln_mt_ara_sum          := 0;       -- 粗利(集計用)
        ln_mt_chk_0_sum        := 0;       -- 掛率(集計用)
-- 2009/04/20 v1.8 UPDATE END
        ln_mt_arari_sum     := 0;          -- 粗利
        ln_mt_s_am_sum      := 0;          -- 売上高
        ln_mt_nuit_sum      := 0;          -- 本数
        ln_mt_price_sum     := 0;          -- 品目定価
        -- 大群計集計用項目初期化
        ln_lt_quant_sum     := 0;          -- 数量
-- 2009/04/20 v1.8 UPDATE START
--        ln_lt_s_u_price_sum := 0;          -- 内訳合計
        ln_lt_s_unit_price_sum := 0;       -- 標準原価
        ln_lt_ara_sum          := 0;       -- 粗利(集計用)
        ln_lt_chk_0_sum        := 0;       -- 掛率(集計用)
-- 2009/04/20 v1.8 UPDATE END
        ln_lt_arari_sum     := 0;          -- 粗利
        ln_lt_s_am_sum      := 0;          -- 売上高
        ln_lt_nuit_sum      := 0;          -- 本数
        ln_lt_price_sum     := 0;          -- 品目定価
        -- 拠点計計算用項目初期化
        ln_ktn_arari_sum    := 0;          -- 粗利
        ln_ktn_s_am_sum     := 0;          -- 売上高
        ln_ktn_nuit_sum     := 0;          -- 本数
        ln_ktn_price_sum    := 0;          -- 品目定価
-- 2009/04/20 v1.8 UPDATE START
--        ln_ktn_to_am_sum    := 0;          -- 内訳合計
        ln_ktn_s_unit_price_sum := 0;      -- 標準原価
        ln_ktn_ara_sum          := 0;      -- 粗利(集計用)
        ln_ktn_chk_0_sum        := 0;      -- 掛率(集計用)
-- 2009/04/20 v1.8 UPDATE END
        ln_ktn_quant_sum    := 0;          -- 数量
        -- 商品区分計集計用項目初期化
        ln_skbn_arari_sum   := 0;          -- 粗利
        ln_skbn_s_am_sum    := 0;          -- 売上高
        ln_skbn_nuit_sum    := 0;          -- 本数
        ln_skbn_price_sum   := 0;          -- 品目定価
-- 2009/04/20 v1.8 UPDATE START
--        ln_skbn_to_am_sum   := 0;          -- 内訳合計
        ln_skbn_s_unit_price_sum := 0;     -- 標準原価
        ln_skbn_ara_sum          := 0;     -- 粗利(集計用)
        ln_skbn_chk_0_sum        := 0;     -- 掛率(集計用)
-- 2009/04/20 v1.8 UPDATE END
        ln_skbn_quant_sum   := 0;          -- 数量
      END IF;
--
      -- ====================================================
      --  群コードブレイク
      -- ====================================================
      -- 群コードが切り替わったとき
      IF (gr_sale_plan(i).gun <> lv_gun_break) THEN
        -- -----------------------------------------------------
        --  品目終了ＬＧタグ出力
        -- ----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_dtl_info';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
        ----------------------------------------------------------------
        -- 細群計(標準原価)データ
        ----------------------------------------------------------------
        -- 標準原価算出
-- 2009/04/20 v1.8 UPDATE START
--        ln_syo_s_unit_price := ln_to_am_sum * ln_quant_sum;
        ln_syo_s_unit_price := ln_s_unit_price_sum;
-- 2009/04/20 v1.8 UPDATE END
--
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'syo_s_unit_price';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
        gt_xml_data_table(gl_xml_idx).tag_value := ln_syo_s_unit_price;
--
        ----------------------------------------------------------------
        -- 細群計(粗利)データ
        ----------------------------------------------------------------
        -- 粗利算出
-- 2009/04/20 v1.8 UPDATE START
--        ln_arari_sum := ln_s_am_sum - ln_syo_s_unit_price;
        ln_arari_sum := ln_ara_sum;
-- 2009/04/20 v1.8 UPDATE END
--
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'syo_arari';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
        gt_xml_data_table(gl_xml_idx).tag_value := ln_arari_sum;
--
        ----------------------------------------------------------------
        -- 細群計(粗利率)データ  ((粗利/売上高)*100)
        ----------------------------------------------------------------
        -- ０除算回避判定
        IF (ln_s_am_sum <> 0) THEN
          -- 値が[0]出なければ計算
          ln_syo_arari_par := ROUND((ln_arari_sum / ln_s_am_sum) * 100,2);
        ELSE
          -- 値が[0]の場合は、一律[0]設定
          ln_syo_arari_par := gn_0;
        END IF;
--
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'syo_arari_par';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
        gt_xml_data_table(gl_xml_idx).tag_value := ln_syo_arari_par;
--
        ----------------------------------------------------------------
        -- 細群計(掛率)データ  ((売上高*100)/(品目定価*本数))
        ----------------------------------------------------------------
-- 2009/04/20 v1.8 UPDATE START
/*
        -- ０除算判定項目へ判定値を挿入
        ln_chk_0 := ln_price_sum * ln_nuit_sum;
        -- ０除算回避判定
        IF (ln_chk_0 <> 0) THEN
          -- 値が[0]出なければ計算
          ln_syo_kake_par := ROUND((ln_s_am_sum * 100) / ln_chk_0,2);
        ELSE
          -- 値が[0]の場合は、一律[0]設定
          ln_syo_kake_par := gn_0;
        END IF;
*/
        -- ０除算回避判定
        IF (ln_chk_0_sum <> 0) THEN
          -- 値が[0]出なければ計算
          ln_syo_kake_par := ROUND((ln_s_am_sum * 100) / ln_chk_0_sum, 2);
        ELSE
          -- 値が[0]の場合は、一律[0]設定
          ln_syo_kake_par := gn_0;
        END IF;
-- 2009/04/20 v1.8 UPDATE END
--
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'syo_kake_par';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
        -- 品目定価 = ０か、計算結果がマイナスの場合、固定値を登録
        IF (ln_price_sum = 0) 
          OR (ln_syo_kake_par < 0)THEN
          gt_xml_data_table(gl_xml_idx).tag_value := TO_NUMBER(gv_name_kotei); -- 固定値:70.00
        -- 品目定価 <> ０、計算結果がマイナスではない場合、計算結果を登録
        ELSE
          gt_xml_data_table(gl_xml_idx).tag_value := ln_syo_kake_par;
        END IF;
--
        -- ====================================================
        --  小群計ブレイク
        -- ====================================================
        IF (SUBSTRB(gr_sale_plan(i).gun,1,3) <> lv_sttl_break) THEN
          ----------------------------------------------------------------
          -- 小群計(数量)データ
          ----------------------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'sttl_quant';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          gt_xml_data_table(gl_xml_idx).tag_value := ln_st_quant_sum;
--
          ----------------------------------------------------------------
          -- 小群計(売上高)データ
          ----------------------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'sttl_sales_amount';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          gt_xml_data_table(gl_xml_idx).tag_value := ln_st_s_am_sum;
--
          ----------------------------------------------------------------
          -- 小群計(標準原価)データ
          ----------------------------------------------------------------
          -- 標準原価算出
-- 2009/04/20 v1.8 UPDATE START
--          ln_sttl_s_unit_price := ln_st_s_u_price_sum * ln_st_quant_sum;
          ln_sttl_s_unit_price := ln_st_s_unit_price_sum;
-- 2009/04/20 v1.8 UPDATE END
--
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'sttl_s_unit_price';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          gt_xml_data_table(gl_xml_idx).tag_value := ln_sttl_s_unit_price;
--
          ----------------------------------------------------------------
          -- 小群計(粗利)データ
          ----------------------------------------------------------------
          -- 粗利算出
-- 2009/04/20 v1.8 UPDATE START
--          ln_st_arari_sum := ln_s_am_sum - ln_syo_s_unit_price;
          ln_st_arari_sum := ln_st_ara_sum;
-- 2009/04/20 v1.8 UPDATE END
--
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'sttl_arari';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          gt_xml_data_table(gl_xml_idx).tag_value := ln_st_arari_sum;
--
          ----------------------------------------------------------------
          -- 小群計(粗利率)データ  ((粗利/売上高)*100)
          ----------------------------------------------------------------
          -- ０除算回避判定
          IF (ln_st_s_am_sum <> 0) THEN
            -- 値が[0]出なければ計算
            ln_sttl_arari_par := ROUND((ln_st_arari_sum / ln_st_s_am_sum) * 100,2);
          ELSE
            -- 値が[0]の場合は、一律[0]設定
            ln_sttl_arari_par := gn_0;
          END IF;
--
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'sttl_arari_par';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          gt_xml_data_table(gl_xml_idx).tag_value := ln_sttl_arari_par;
--
          ----------------------------------------------------------------
          -- 小群計(掛率)データ  ((売上高*100)/(品目定価*本数))
          ----------------------------------------------------------------
-- 2009/04/20 v1.8 UPDATE START
/*
          -- ０除算判定項目へ判定値を挿入
          ln_chk_0 := ln_st_price_sum * ln_st_nuit_sum;
          -- ０除算回避判定
          IF (ln_chk_0 <> 0) THEN
            -- 値が[0]出なければ計算
            ln_sttl_kake_par := ROUND((ln_st_s_am_sum * 100) / ln_chk_0,2);
          ELSE
            -- 値が[0]の場合は、一律[0]設定
            ln_sttl_kake_par := gn_0;
          END IF;
*/
          -- ０除算回避判定
          IF (ln_st_chk_0_sum <> 0) THEN
            -- 値が[0]出なければ計算
            ln_sttl_kake_par := ROUND((ln_st_s_am_sum * 100) / ln_st_chk_0_sum, 2);
          ELSE
            -- 値が[0]の場合は、一律[0]設定
            ln_sttl_kake_par := gn_0;
          END IF;
-- 2009/04/20 v1.8 UPDATE END
--
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'sttl_kake_par';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          -- 品目定価 = ０か、計算結果がマイナスの場合、固定値を登録
          IF (ln_st_price_sum = 0)
            OR (ln_sttl_kake_par < 0) THEN
            gt_xml_data_table(gl_xml_idx).tag_value := TO_NUMBER(gv_name_kotei); -- 固定値:70.00
          -- 品目定価 <> ０、計算結果がマイナスではない場合、計算結果を登録
          ELSE
            gt_xml_data_table(gl_xml_idx).tag_value := ln_sttl_kake_par;
          END IF;
          -- 小群計ブレイクキー更新
          lv_sttl_break := SUBSTRB(gr_sale_plan(i).gun,1,3);
--
          -- 小群計集計用項目初期化
          ln_st_quant_sum     := 0;              -- 数量
-- 2009/04/20 v1.8 UPDATE START
--          ln_st_s_u_price_sum := 0;              -- 内訳合計
          ln_st_s_unit_price_sum := 0;           -- 標準原価
          ln_st_ara_sum          := 0;           -- 粗利(集計用)
          ln_st_chk_0_sum        := 0;           -- 掛率(集計用)
-- 2009/04/20 v1.8 UPDATE END
          ln_st_arari_sum     := 0;              -- 粗利
          ln_st_s_am_sum      := 0;              -- 売上高
          ln_st_nuit_sum      := 0;              -- 本数
          ln_st_price_sum     := 0;              -- 品目定価
        END IF;
--
        -- ====================================================
        --  中群計ブレイク
        -- ====================================================
        IF (SUBSTRB(gr_sale_plan(i).gun,1,2) <> lv_mttl_break) THEN
          ----------------------------------------------------------------
          -- 中群計(数量)データ
          ----------------------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'mttl_quant';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          gt_xml_data_table(gl_xml_idx).tag_value := ln_mt_quant_sum;
--
          ----------------------------------------------------------------
          -- 中群計(売上高)データ
          ----------------------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'mttl_sales_amount';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          gt_xml_data_table(gl_xml_idx).tag_value := ln_mt_s_am_sum;
--
          ----------------------------------------------------------------
          -- 中群計(標準原価)データ
          ----------------------------------------------------------------
          -- 標準原価算出
-- 2009/04/20 v1.8 UPDATE START
--          ln_mttl_s_unit_price := ln_mt_s_u_price_sum * ln_mt_quant_sum;
          ln_mttl_s_unit_price := ln_mt_s_unit_price_sum;
-- 2009/04/20 v1.8 UPDATE END
--
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'mttl_s_unit_price';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          gt_xml_data_table(gl_xml_idx).tag_value := ln_mttl_s_unit_price;
--
          ----------------------------------------------------------------
          -- 中群計(粗利)データ
          ----------------------------------------------------------------
          -- 粗利算出
-- 2009/04/20 v1.8 UPDATE START
--          ln_mt_arari_sum := ln_mt_s_am_sum - ln_mttl_s_unit_price;
          ln_mt_arari_sum := ln_mt_ara_sum;
-- 2009/04/20 v1.8 UPDATE END
--
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'mttl_arari';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          gt_xml_data_table(gl_xml_idx).tag_value := ln_mt_arari_sum;
--
          ----------------------------------------------------------------
          -- 中群計(粗利率)データ  ((粗利/売上高)*100)
          ----------------------------------------------------------------
          --  ０除算回避判定
          IF (ln_mt_s_am_sum <> 0) THEN
            -- 値が[0]出なければ計算
            ln_mttl_arari_par := ROUND((ln_mt_arari_sum / ln_mt_s_am_sum) * 100,2);
          ELSE
            -- 値が[0]の場合は、一律[0]設定
            ln_mttl_arari_par := gn_0;
          END IF;
--
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'mttl_arari_par';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          gt_xml_data_table(gl_xml_idx).tag_value := ln_mttl_arari_par;
--
          ----------------------------------------------------------------
          -- 中群計(掛率)データ  ((売上高*100)/(品目定価*本数))
          ----------------------------------------------------------------
-- 2009/04/20 v1.8 UPDATE START
/*
          -- ０除算判定項目へ判定値を挿入
          ln_chk_0 := ln_mt_price_sum * ln_mt_nuit_sum;
          -- ０除算回避判定
          IF (ln_chk_0 <> 0) THEN
            -- 値が[0]出なければ計算
            ln_mttl_kake_par := ROUND((ln_mt_s_am_sum * 100) / ln_chk_0,2);
          ELSE
            -- 値が[0]の場合は、一律[0]設定
            ln_mttl_kake_par := gn_0;
          END IF;
*/
          -- ０除算回避判定
          IF (ln_mt_chk_0_sum <> 0) THEN
            -- 値が[0]出なければ計算
            ln_mttl_kake_par := ROUND((ln_mt_s_am_sum * 100) / ln_mt_chk_0_sum, 2);
          ELSE
            -- 値が[0]の場合は、一律[0]設定
            ln_mttl_kake_par := gn_0;
          END IF;
-- 2009/04/20 v1.8 UPDATE END
--
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'mttl_kake_par';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          -- 品目定価 = ０か、計算結果がマイナスの場合、固定値を登録
          IF (ln_mt_price_sum = 0)
            OR (ln_mttl_kake_par < 0) THEN
            gt_xml_data_table(gl_xml_idx).tag_value := TO_NUMBER(gv_name_kotei); -- 固定値:70.00
          -- 品目定価 <> ０、計算結果がマイナスではない場合、計算結果を登録
          ELSE
            gt_xml_data_table(gl_xml_idx).tag_value := ln_mttl_kake_par;
          END IF;
--
          --  中群計ブレイクキー更新
          lv_mttl_break := SUBSTRB(gr_sale_plan(i).gun,1,2);
--
          -- 中群計集計用項目初期化
          ln_mt_quant_sum     := 0;              -- 数量
-- 2009/04/20 v1.8 UPDATE START
--          ln_mt_s_u_price_sum := 0;              -- 内訳合計
          ln_mt_s_unit_price_sum := 0;           -- 標準原価
          ln_mt_ara_sum          := 0;           -- 粗利(集計用)
          ln_mt_chk_0_sum        := 0;           -- 掛率(集計用)
-- 2009/04/20 v1.8 UPDATE END
          ln_mt_arari_sum     := 0;              -- 粗利
          ln_mt_s_am_sum      := 0;              -- 売上高
          ln_mt_nuit_sum      := 0;              -- 本数
          ln_mt_price_sum     := 0;              -- 品目定価
        END IF;
--
        -- ====================================================
        --  大群計ブレイク
        -- ====================================================
        IF (SUBSTRB(gr_sale_plan(i).gun,1,1) <> lv_lttl_break) THEN
          ----------------------------------------------------------------
          -- 大群計(数量)データ
          ----------------------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'lttl_quant';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          gt_xml_data_table(gl_xml_idx).tag_value := ln_lt_quant_sum;
--
          ----------------------------------------------------------------
          -- 大群計(売上高)データ
          ----------------------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'lttl_sales_amount';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          gt_xml_data_table(gl_xml_idx).tag_value := ln_lt_s_am_sum;
--
          ----------------------------------------------------------------
          -- 大群計(標準原価)データ
          ----------------------------------------------------------------
          -- 標準原価算出
-- 2009/04/20 v1.8 UPDATE START
--          ln_lttl_s_unit_price := ln_lt_s_u_price_sum * ln_lt_quant_sum;
          ln_lttl_s_unit_price := ln_lt_s_unit_price_sum;
-- 2009/04/20 v1.8 UPDATE END
--
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'lttl_s_unit_price';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          gt_xml_data_table(gl_xml_idx).tag_value := ln_lttl_s_unit_price;
--
          ----------------------------------------------------------------
          -- 大群計(粗利)データ
          ----------------------------------------------------------------
          -- 粗利算出
-- 2009/04/20 v1.8 UPDATE START
--          ln_lt_arari_sum := ln_lt_s_am_sum - ln_lttl_s_unit_price;
          ln_lt_arari_sum := ln_lt_ara_sum;
-- 2009/04/20 v1.8 UPDATE END
--
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'lttl_arari';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          gt_xml_data_table(gl_xml_idx).tag_value := ln_lt_arari_sum;
--
          ----------------------------------------------------------------
          -- 大群計(粗利率)データ  ((粗利/売上高)*100)
          ----------------------------------------------------------------
          -- ０除算回避判定
          IF (ln_lt_s_am_sum <> 0) THEN
            -- 値が[0]出なければ計算
            ln_lttl_arari_par := ROUND((ln_lt_arari_sum / ln_lt_s_am_sum) * 100,2);
          ELSE
            -- 値が[0]の場合は、一律[0]設定
            ln_lttl_arari_par := gn_0;
          END IF;
--
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'lttl_arari_par';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          gt_xml_data_table(gl_xml_idx).tag_value := ln_lttl_arari_par;
--
          ----------------------------------------------------------------
          -- 大群計(掛率)データ  ((売上高*100)/(品目定価*本数))
          ----------------------------------------------------------------
-- 2009/04/20 v1.8 UPDATE START
/*
          -- ０除算判定項目へ判定値を挿入
          ln_chk_0 := ln_lt_price_sum * ln_lt_nuit_sum;
          -- ０除算回避判定
          IF (ln_chk_0 <> 0) THEN
            -- 値が[0]出なければ計算
            ln_lttl_kake_par := ROUND((ln_lt_s_am_sum * 100) / ln_chk_0,2);
          ELSE
            -- 値が[0]の場合は、一律[0]設定
            ln_lttl_kake_par := gn_0;
          END IF;
*/
          -- ０除算回避判定
          IF (ln_lt_chk_0_sum <> 0) THEN
            -- 値が[0]出なければ計算
            ln_lttl_kake_par := ROUND((ln_lt_s_am_sum * 100) / ln_lt_chk_0_sum, 2);
          ELSE
            -- 値が[0]の場合は、一律[0]設定
            ln_lttl_kake_par := gn_0;
          END IF;
-- 2009/04/20 v1.8 UPDATE END
--
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'lttl_kake_par';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          -- 品目定価 = ０か、計算結果がマイナスの場合、固定値を登録
          IF (ln_lt_price_sum = 0)
            OR (ln_lttl_kake_par < 0) THEN
            gt_xml_data_table(gl_xml_idx).tag_value := TO_NUMBER(gv_name_kotei); -- 固定値:70.00
          -- 品目定価 <> ０、計算結果がマイナスではない場合、計算結果を登録
          ELSE
            gt_xml_data_table(gl_xml_idx).tag_value := ln_lttl_kake_par;
          END IF;
--
          --  大群計ブレイクキー更新
          lv_lttl_break := SUBSTRB(gr_sale_plan(i).gun,1,1);
--
          -- 大群計集計用項目初期化
          ln_lt_quant_sum     := 0;              -- 数量
-- 2009/04/20 v1.8 UPDATE START
--          ln_lt_s_u_price_sum := 0;              -- 内訳合計
          ln_lt_s_unit_price_sum := 0;           -- 標準原価
          ln_lt_ara_sum          := 0;           -- 粗利(集計用)
          ln_lt_chk_0_sum        := 0;           -- 掛率(集計用)
-- 2009/04/20 v1.8 UPDATE END
          ln_lt_arari_sum     := 0;              -- 粗利
          ln_lt_s_am_sum      := 0;              -- 売上高
          ln_lt_nuit_sum      := 0;              -- 本数
          ln_lt_price_sum     := 0;              -- 品目定価
        END IF;
--
        -- -----------------------------------------------------
        --  群コード終了Ｇタグ出力
        -- -----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := '/g_gun';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
        -- -----------------------------------------------------
        --  群コード終了LＧタグ出力
        -- -----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_gun_info';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
        -- -----------------------------------------------------
        --  群コード開始LＧタグ出力
        -- -----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_gun_info';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
        -- -----------------------------------------------------
        --  群コード開始Ｇタグ出力
        -- -----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'g_gun';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
        -- -----------------------------------------------------
        --  品目開始ＬＧタグ出力
        -- -----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_dtl_info';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
        --  群コードブレイクキー更新
        lv_gun_break  := gr_sale_plan(i).gun;
--
        -- 細群計集計用項目初期化
        ln_nuit_sum   := 0;         -- 本数
        ln_price_sum  := 0;         -- 品目定価
        ln_arari_sum  := 0;         -- 粗利
        ln_s_am_sum   := 0;         -- 売上高
-- 2009/04/20 v1.8 UPDATE START
--        ln_to_am_sum  := 0;         -- 内訳合計
        ln_s_unit_price_sum := 0;   -- 標準原価
        ln_ara_sum          := 0;   -- 粗利(集計用)
        ln_chk_0_sum        := 0;   -- 掛率(集計用)
-- 2009/04/20 v1.8 UPDATE START
        ln_quant_sum  := 0;         -- 数量
      END IF;
--
      -- -----------------------------------------------------
      --  品目開始Ｇタグ出力
      -- -----------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'g_dtl';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
      ----------------------------------------------------------------
      -- 群コードデータ
      ----------------------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'gun_code';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
      gt_xml_data_table(gl_xml_idx).tag_value := gr_sale_plan(i).gun;
--
      ----------------------------------------------------------------
      -- 品目(コード)データ
      ----------------------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'item_code';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
      gt_xml_data_table(gl_xml_idx).tag_value := gr_sale_plan(i).item_no;
--
      ----------------------------------------------------------------
      -- 品目(名称)データ
      ----------------------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'item_name';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
      gt_xml_data_table(gl_xml_idx).tag_value := gr_sale_plan(i).item_short_name;
--
      ----------------------------------------------------------------
      -- 入数データ
      ----------------------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'case_quant';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
      gt_xml_data_table(gl_xml_idx).tag_value := TO_NUMBER(gr_sale_plan(i).case_quant);
--
      ----------------------------------------------------------------
      -- 数量データ
      ----------------------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'quant';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
      -- 出力単位が「本数」の場合
      IF (gr_param.output_unit = gv_output_unit) THEN
        gt_xml_data_table(gl_xml_idx).tag_value := TO_NUMBER(gr_sale_plan(i).quant);
      -- 出力単位が「ケース」の場合
      ELSE
        -- ０除算回避判定
        IF (TO_NUMBER(gr_sale_plan(i).case_quant) <> 0) THEN
          -- 値が[0]出なければ、数量計算  (数量 / 入数)
          ln_output_unit 
                 := TO_NUMBER(gr_sale_plan(i).quant) / TO_NUMBER(gr_sale_plan(i).case_quant);
          -- 小数以下1位切上
          ln_output_unit := CEIL(ln_output_unit);
        ELSE
          -- 値が[0]の場合は、一律[0]設定
          ln_output_unit := gn_0;
        END IF;
        gt_xml_data_table(gl_xml_idx).tag_value := ln_output_unit;
      END IF;
--
      ----------------------------------------------------------------
      -- 売上高データ
      ----------------------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'sales_amount';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
      gt_xml_data_table(gl_xml_idx).tag_value := TO_NUMBER(gr_sale_plan(i).amount);
--
      ----------------------------------------------------------------
      -- 標準原価データ (内訳合計 * 数量)
      ----------------------------------------------------------------
      ln_s_u_price := TO_NUMBER(gr_sale_plan(i).total_amount) * TO_NUMBER(gr_sale_plan(i).quant);
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 's_unit_price';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
      gt_xml_data_table(gl_xml_idx).tag_value := ln_s_u_price;
--
      ----------------------------------------------------------------
      -- 粗利データ (金額 - 内訳合計 * 数量)
      ----------------------------------------------------------------
      ln_arari := TO_NUMBER(gr_sale_plan(i).amount) - ln_s_u_price;
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'arari';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
      gt_xml_data_table(gl_xml_idx).tag_value := ln_arari;
--
      ----------------------------------------------------------------
      -- 粗利率(%)データ  ((金額 - 内訳合計 * 数量) / 金額 * 100)
      ----------------------------------------------------------------
      -- ０除算回避判定
      IF (TO_NUMBER(gr_sale_plan(i).amount) <> 0) THEN
        -- 値が[0]出なければ計算
        ln_arari_par := ROUND((ln_arari / TO_NUMBER(gr_sale_plan(i).amount) * 100),2);
      ELSE
        -- 値が[0]の場合は、一律[0]設定
        ln_arari_par := gn_0;
      END IF;
--
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'arari_par';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
      gt_xml_data_table(gl_xml_idx).tag_value := ln_arari_par;
--
      ----------------------------------------------------------------
      -- 掛率(%)データ ((金額 * 100) / (品目定価 * 数量))
      ----------------------------------------------------------------
      -- 定価適用開始日にて旧定価・新定価の使用判断
      -- 年度開始月日がOPM品目マスタ定価適用開始日以上の場合
      IF (FND_DATE.STRING_TO_DATE(gr_sale_plan(i).price_st,'YYYY/MM/DD')   <= gd_start_day) THEN
        -- 新定価を使用
        ln_price := TO_NUMBER(gr_sale_plan(i).n_amount);
      -- 年度開始月日がOPM品目マスタ定価適用開始日未満の場合
      ELSIF (FND_DATE.STRING_TO_DATE(gr_sale_plan(i).price_st,'YYYY/MM/DD') > gd_start_day) THEN
        -- 旧定価を使用
        ln_price := TO_NUMBER(gr_sale_plan(i).o_amount);
      END IF;
--
      -- ０除算判定項目へ判定値を挿入
--2008.04.30 Y.Kawano modify start
--      ln_chk_0 := ln_price * TO_NUMBER(gr_sale_plan(i).quant) * 100;
      ln_chk_0 := ln_price * TO_NUMBER(gr_sale_plan(i).quant);
--2008.04.30 Y.Kawano modify end
      -- ０除算回避判定
      IF (ln_chk_0 <> 0) THEN
        -- 値が[0]出なければ計算
--2008.04.30 Y.Kawano modify start
--        ln_kake_par := ROUND(TO_NUMBER(gr_sale_plan(i).amount) / ln_chk_0,2);
        ln_kake_par := ROUND((TO_NUMBER(gr_sale_plan(i).amount) * 100) / ln_chk_0,2);
--2008.04.30 Y.Kawano modify end
      ELSE
        -- 値が[0]の場合は、一律[0]設定
        ln_kake_par := gn_0;
      END IF;
--
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'kake_par';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
      -- 品目定価 = ０か、計算結果がマイナスの場合、固定値を登録
      IF (ln_price = 0)
        OR (ln_kake_par < 0) THEN
        gt_xml_data_table(gl_xml_idx).tag_value := TO_NUMBER(gv_name_kotei); -- 固定値:70.00
      -- 品目定価 <> ０、計算結果がマイナスではない場合、計算結果を登録
      ELSE
        gt_xml_data_table(gl_xml_idx).tag_value := ln_kake_par;
      END IF;
--
      -- -----------------------------------------------------
      --  品目終了Ｇタグ出力
      -- -----------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := '/g_dtl';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
      -- 細群計に使用する項目をSUM
      ln_s_am_sum   := ln_s_am_sum   + TO_NUMBER(gr_sale_plan(i).amount);              -- 売上高
      ln_nuit_sum   := ln_nuit_sum   + TO_NUMBER(gr_sale_plan(i).quant);               -- 本数
      ln_price_sum  := ln_price_sum  + ln_price;                                       -- 品目定価
-- 2009/04/20 v1.8 UPDATE START
--      ln_to_am_sum  := ln_to_am_sum  + TO_NUMBER(gr_sale_plan(i).total_amount);        -- 内訳合計
      -- 明細ごとの計算結果を足し込む
      ln_s_unit_price_sum := ln_s_unit_price_sum + ln_s_u_price;                       -- 標準原価
      ln_ara_sum          := ln_ara_sum + ln_arari;                                    -- 粗利(集計用)
      ln_chk_0_sum        := ln_chk_0_sum + ln_chk_0;                                  -- 掛率(集計用)
-- 2009/04/20 v1.8 UPDATE END
      -- 出力単位が「本数」の場合
      IF (gr_param.output_unit = gv_output_unit) THEN
        ln_quant_sum      := ln_quant_sum        + TO_NUMBER(gr_sale_plan(i).quant);   -- 数量
      -- 出力単位が「ケース」の場合
      ELSE
        ln_quant_sum      := ln_quant_sum        + ln_output_unit;                     -- 数量
      END IF;
--
      -- 小群計に使用する項目をSUM
      -- 出力単位が「本数」の場合
      IF (gr_param.output_unit = gv_output_unit) THEN
        ln_st_quant_sum   := ln_st_quant_sum     + TO_NUMBER(gr_sale_plan(i).quant);   -- 数量
      -- 出力単位が「ケース」の場合
      ELSE
        ln_st_quant_sum   := ln_st_quant_sum     + ln_output_unit;                     -- 数量
      END IF;
-- 2009/04/20 v1.8 UPDATE START
/*
      ln_st_s_u_price_sum := ln_st_s_u_price_sum + TO_NUMBER(gr_sale_plan(i).total_amount);
                                                                                       -- 内訳合計
*/
      -- 明細ごとの計算結果を足し込む
      ln_st_s_unit_price_sum  := ln_st_s_unit_price_sum + ln_s_u_price;                -- 標準原価
      ln_st_ara_sum           := ln_st_ara_sum + ln_arari;                             -- 粗利(集計用)
      ln_st_chk_0_sum         := ln_st_chk_0_sum + ln_chk_0;                           -- 掛率(集計用)
-- 2009/04/20 v1.8 UPDATE END
      ln_st_s_am_sum      := ln_st_s_am_sum      + TO_NUMBER(gr_sale_plan(i).amount);  -- 売上高
      ln_st_nuit_sum      := ln_st_nuit_sum      + TO_NUMBER(gr_sale_plan(i).quant);   -- 本数
      ln_st_price_sum     := ln_st_price_sum     + ln_price;                           -- 品目定価
--
      -- 中群計に使用する項目をSUM
      -- 出力単位が「本数」の場合
      IF (gr_param.output_unit = gv_output_unit) THEN
        ln_mt_quant_sum   := ln_mt_quant_sum     + TO_NUMBER(gr_sale_plan(i).quant);   -- 数量
      -- 出力単位が「ケース」の場合
      ELSE
        ln_mt_quant_sum   := ln_mt_quant_sum     + ln_output_unit;                     -- 数量
      END IF;
-- 2009/04/20 v1.8 UPDATE START
/*
      ln_mt_s_u_price_sum := ln_mt_s_u_price_sum + TO_NUMBER(gr_sale_plan(i).total_amount);
                                                                                       -- 内訳合計
*/
      -- 明細ごとの計算結果を足し込む
      ln_mt_s_unit_price_sum  := ln_mt_s_unit_price_sum + ln_s_u_price;                -- 標準原価
      ln_mt_ara_sum           := ln_mt_ara_sum + ln_arari;                             -- 粗利(集計用)
      ln_mt_chk_0_sum         := ln_mt_chk_0_sum + ln_chk_0;                           -- 掛率(集計用)
-- 2009/04/20 v1.8 UPDATE END
      ln_mt_s_am_sum      := ln_mt_s_am_sum      + TO_NUMBER(gr_sale_plan(i).amount);  -- 売上高
      ln_mt_nuit_sum      := ln_mt_nuit_sum      + TO_NUMBER(gr_sale_plan(i).quant);   -- 本数
      ln_mt_price_sum     := ln_mt_price_sum     + ln_price;                           -- 品目定価
--
      -- 大群計に使用する項目をSUM
      -- 出力単位が「本数」の場合
      IF (gr_param.output_unit = gv_output_unit) THEN
        ln_lt_quant_sum   := ln_lt_quant_sum     + TO_NUMBER(gr_sale_plan(i).quant);   -- 数量
      -- 出力単位が「ケース」の場合
      ELSE
        ln_lt_quant_sum   := ln_lt_quant_sum     + ln_output_unit;                     -- 数量
      END IF;
-- 2009/04/20 v1.8 UPDATE START
/*
      ln_lt_s_u_price_sum := ln_lt_s_u_price_sum + TO_NUMBER(gr_sale_plan(i).total_amount);
                                                                                       -- 内訳合計
*/
      -- 明細ごとの計算結果を足し込む
      ln_lt_s_unit_price_sum  := ln_lt_s_unit_price_sum + ln_s_u_price;                -- 標準原価
      ln_lt_ara_sum           := ln_lt_ara_sum + ln_arari;                             -- 粗利(集計用)
      ln_lt_chk_0_sum         := ln_lt_chk_0_sum + ln_chk_0;                           -- 掛率(集計用)
-- 2009/04/20 v1.8 UPDATE END
      ln_lt_s_am_sum      := ln_lt_s_am_sum      + TO_NUMBER(gr_sale_plan(i).amount);  -- 売上高
      ln_lt_nuit_sum      := ln_lt_nuit_sum      + TO_NUMBER(gr_sale_plan(i).quant);   -- 本数
      ln_lt_price_sum     := ln_lt_price_sum     + ln_price;                           -- 品目定価
--
      -- 拠点計に使用する項目をSUM
      ln_ktn_s_am_sum     := ln_ktn_s_am_sum     + TO_NUMBER(gr_sale_plan(i).amount);  -- 売上高
      ln_ktn_nuit_sum     := ln_ktn_nuit_sum     + TO_NUMBER(gr_sale_plan(i).quant);   -- 本数
      ln_ktn_price_sum    := ln_ktn_price_sum    + ln_price;                           -- 品目定価
-- 2009/04/20 v1.8 UPDATE START
/*
      ln_ktn_to_am_sum    := ln_ktn_to_am_sum    + TO_NUMBER(gr_sale_plan(i).total_amount);
                                                                                       -- 内訳合計
*/
      -- 明細ごとの計算結果を足し込む
      ln_ktn_s_unit_price_sum  := ln_ktn_s_unit_price_sum + ln_s_u_price;              -- 標準原価
      ln_ktn_ara_sum           := ln_ktn_ara_sum + ln_arari;                           -- 粗利
      ln_ktn_chk_0_sum         := ln_ktn_chk_0_sum + ln_chk_0;                         -- 掛率(集計用)
-- 2009/04/20 v1.8 UPDATE END
      -- 出力単位が「本数」の場合
      IF (gr_param.output_unit = gv_output_unit) THEN
        ln_ktn_quant_sum   := ln_ktn_quant_sum   + TO_NUMBER(gr_sale_plan(i).quant);   -- 数量
      -- 出力単位が「ケース」の場合
      ELSE
        ln_ktn_quant_sum   := ln_ktn_quant_sum   + ln_output_unit;                     -- 数量
      END IF;
--
      -- 商品区分計に使用する項目をSUM
      ln_skbn_s_am_sum    := ln_skbn_s_am_sum    + TO_NUMBER(gr_sale_plan(i).amount);  -- 売上高
      ln_skbn_nuit_sum    := ln_skbn_nuit_sum    + TO_NUMBER(gr_sale_plan(i).quant);   -- 本数
      ln_skbn_price_sum   := ln_skbn_price_sum   + ln_price;                           -- 品目定価
-- 2009/04/20 v1.8 UPDATE START
/*
      ln_skbn_to_am_sum   := ln_skbn_to_am_sum   + TO_NUMBER(gr_sale_plan(i).total_amount);
                                                                                       -- 内訳合計
*/
      -- 明細ごとの計算結果を足し込む
      ln_skbn_s_unit_price_sum  := ln_skbn_s_unit_price_sum + ln_s_u_price;            -- 標準原価
      ln_skbn_ara_sum           := ln_skbn_ara_sum + ln_arari;                         -- 粗利(集計用)
      ln_skbn_chk_0_sum         := ln_skbn_chk_0_sum + ln_chk_0;                       -- 掛率(集計用)
-- 2009/04/20 v1.8 UPDATE END
      -- 出力単位が「本数」の場合
      IF (gr_param.output_unit = gv_output_unit) THEN
        ln_skbn_quant_sum   := ln_skbn_quant_sum + TO_NUMBER(gr_sale_plan(i).quant);   -- 数量
      -- 出力単位が「ケース」の場合
      ELSE
        ln_skbn_quant_sum   := ln_skbn_quant_sum + ln_output_unit;                     -- 数量
      END IF;
--
      -- 総合計に使用する項目をSUM
      ln_to_s_am_sum      := ln_to_s_am_sum      + TO_NUMBER(gr_sale_plan(i).amount);  -- 売上高
      ln_to_nuit_sum      := ln_to_nuit_sum      + TO_NUMBER(gr_sale_plan(i).quant);   -- 本数
      ln_to_price_sum     := ln_to_price_sum     + ln_price;                           -- 品目定価
-- 2009/04/20 v1.8 UPDATE START
/*
      ln_to_to_am_sum     := ln_to_to_am_sum     + TO_NUMBER(gr_sale_plan(i).total_amount);
                                                                                       -- 内訳合計
*/
      -- 明細ごとの計算結果を足し込む
      ln_to_s_unit_price_sum  := ln_to_s_unit_price_sum + ln_s_u_price;                -- 標準原価
      ln_to_ara_sum           := ln_to_ara_sum + ln_arari;                             -- 粗利(集計用)
      ln_to_chk_0_sum         := ln_to_chk_0_sum + ln_chk_0;                           -- 掛率(集計用)
-- 2009/04/20 v1.8 UPDATE END
      -- 出力単位が「本数」の場合
      IF (gr_param.output_unit = gv_output_unit) THEN
        ln_to_quant_sum   := ln_to_quant_sum     + TO_NUMBER(gr_sale_plan(i).quant);   -- 数量
      -- 出力単位が「ケース」の場合
      ELSE
        ln_to_quant_sum   := ln_to_quant_sum     + ln_output_unit;                     -- 数量
      END IF;
--
    END LOOP main_data_loop;
    -- =====================================================
    --    終了処理
    -- =====================================================
    -- -----------------------------------------------------
    --  品目終了ＬＧタグ出力
    -- ----------------------------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_dtl_info';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
    ----------------------------------------------------------------
    -- 細群計(標準原価)データ
    ----------------------------------------------------------------
    -- 標準原価算出
-- 2009/04/20 v1.8 UPDATE START
--    ln_syo_s_unit_price := ln_to_am_sum * ln_quant_sum;
    ln_syo_s_unit_price := ln_s_unit_price_sum;
-- 2009/04/20 v1.8 UPDATE END
--
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'syo_s_unit_price';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    gt_xml_data_table(gl_xml_idx).tag_value := ln_syo_s_unit_price;
--
    ----------------------------------------------------------------
    -- 細群計(粗利)データ
    ----------------------------------------------------------------
    -- 粗利算出
-- 2009/04/20 v1.8 UPDATE START
--    ln_arari_sum := ln_s_am_sum - ln_syo_s_unit_price;
    ln_arari_sum := ln_ara_sum;
-- 2009/04/20 v1.8 UPDATE END
--

    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'syo_arari';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    gt_xml_data_table(gl_xml_idx).tag_value := ln_arari_sum;
--
    ----------------------------------------------------------------
    -- 細群計(粗利率)データ  ((粗利/売上高)*100)
    ----------------------------------------------------------------
    -- ０除算回避判定
    IF (ln_s_am_sum <> 0) THEN
      -- 値が[0]出なければ計算
      ln_syo_arari_par := ROUND((ln_arari_sum / ln_s_am_sum) * 100,2);
    ELSE
      -- 値が[0]の場合は、一律[0]設定
      ln_syo_arari_par := gn_0;
    END IF;
--
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'syo_arari_par';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    gt_xml_data_table(gl_xml_idx).tag_value := ln_syo_arari_par;
--
    ----------------------------------------------------------------
    -- 細群計(掛率)データ  ((売上高*100)/(品目定価*本数))
    ----------------------------------------------------------------
-- 2009/04/20 v1.8 UPDATE START
/*
    -- ０除算判定項目へ判定値を挿入
    ln_chk_0 := ln_price_sum * ln_nuit_sum;
    -- ０除算回避判定
    IF (ln_chk_0 <> 0) THEN
      -- 値が[0]出なければ計算
      ln_syo_kake_par := ROUND((ln_s_am_sum * 100) / ln_chk_0,2);
    ELSE
      -- 値が[0]の場合は、一律[0]設定
      ln_syo_kake_par := gn_0;
    END IF;
*/
    -- ０除算回避判定
    IF (ln_chk_0_sum <> 0) THEN
      -- 値が[0]出なければ計算
      ln_syo_kake_par := ROUND((ln_s_am_sum * 100) / ln_chk_0_sum, 2);
    ELSE
      -- 値が[0]の場合は、一律[0]設定
      ln_syo_kake_par := gn_0;
    END IF;
-- 2009/04/20 v1.8 UPDATE END
--
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'syo_kake_par';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    -- 品目定価 = ０か、計算結果がマイナスの場合、固定値を登録
    IF (ln_price_sum = 0) 
      OR (ln_syo_kake_par < 0)THEN
      gt_xml_data_table(gl_xml_idx).tag_value := TO_NUMBER(gv_name_kotei); -- 固定値:70.00
    -- 品目定価 <> ０、計算結果がマイナスではない場合、計算結果を登録
    ELSE
      gt_xml_data_table(gl_xml_idx).tag_value := ln_syo_kake_par;
    END IF;
--
    ----------------------------------------------------------------
    -- 小群計(数量)データ
    ----------------------------------------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'sttl_quant';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    gt_xml_data_table(gl_xml_idx).tag_value := ln_st_quant_sum;
--
    ----------------------------------------------------------------
    -- 小群計(売上高)データ
    ----------------------------------------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'sttl_sales_amount';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    gt_xml_data_table(gl_xml_idx).tag_value := ln_st_s_am_sum;
--
    ----------------------------------------------------------------
    -- 小群計(標準原価)データ
    ----------------------------------------------------------------
    -- 標準原価算出
-- 2009/04/20 v1.8 UPDATE START
--    ln_sttl_s_unit_price := ln_st_s_u_price_sum * ln_st_quant_sum;
    ln_sttl_s_unit_price := ln_st_s_unit_price_sum;
-- 2009/04/20 v1.8 UPDATE END
--
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'sttl_s_unit_price';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    gt_xml_data_table(gl_xml_idx).tag_value := ln_sttl_s_unit_price;
--
    ----------------------------------------------------------------
    -- 小群計(粗利)データ
    ----------------------------------------------------------------
    -- 粗利算出
-- 2009/04/20 v1.8 UPDATE START
--    ln_st_arari_sum := ln_s_am_sum - ln_syo_s_unit_price;
    ln_st_arari_sum := ln_st_ara_sum;
-- 2009/04/20 v1.8 UPDATE END
--
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'sttl_arari';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    gt_xml_data_table(gl_xml_idx).tag_value := ln_st_arari_sum;
--
    ----------------------------------------------------------------
    -- 小群計(粗利率)データ  ((粗利/売上高)*100)
    ----------------------------------------------------------------
    -- ０除算回避判定
    IF (ln_st_s_am_sum <> 0) THEN
      -- 値が[0]出なければ計算
      ln_sttl_arari_par := ROUND((ln_st_arari_sum / ln_st_s_am_sum) * 100,2);
    ELSE
      -- 値が[0]の場合は、一律[0]設定
      ln_sttl_arari_par := gn_0;
    END IF;
--
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'sttl_arari_par';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    gt_xml_data_table(gl_xml_idx).tag_value := ln_sttl_arari_par;
--
    ----------------------------------------------------------------
    -- 小群計(掛率)データ  ((売上高*100)/(品目定価*本数))
    ----------------------------------------------------------------
-- 2009/04/20 v1.8 UPDATE START
/*
    -- ０除算判定項目へ判定値を挿入
    ln_chk_0 := ln_st_price_sum * ln_st_nuit_sum;
    -- ０除算回避判定
    IF (ln_chk_0 <> 0) THEN
      -- 値が[0]出なければ計算
      ln_sttl_kake_par := ROUND((ln_st_s_am_sum * 100) / ln_chk_0,2);
    ELSE
      -- 値が[0]の場合は、一律[0]設定
      ln_sttl_kake_par := gn_0;
    END IF;
*/
    -- ０除算回避判定
    IF (ln_st_chk_0_sum <> 0) THEN
      -- 値が[0]出なければ計算
      ln_sttl_kake_par := ROUND((ln_st_s_am_sum * 100) / ln_st_chk_0_sum, 2);
    ELSE
      -- 値が[0]の場合は、一律[0]設定
      ln_sttl_kake_par := gn_0;
    END IF;
-- 2009/04/20 v1.8 UPDATE END
--
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'sttl_kake_par';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    -- 品目定価 = ０か、計算結果がマイナスの場合、固定値を登録
    IF (ln_st_price_sum = 0)
      OR (ln_sttl_kake_par < 0) THEN
      gt_xml_data_table(gl_xml_idx).tag_value := TO_NUMBER(gv_name_kotei); -- 固定値:70.00
      -- 品目定価 <> ０、計算結果がマイナスではない場合、計算結果を登録
    ELSE
      gt_xml_data_table(gl_xml_idx).tag_value := ln_sttl_kake_par;
    END IF;
--
    ----------------------------------------------------------------
    -- 中群計(数量)データ
    ----------------------------------------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'mttl_quant';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    gt_xml_data_table(gl_xml_idx).tag_value := ln_mt_quant_sum;
--
    ----------------------------------------------------------------
    -- 中群計(売上高)データ
    ----------------------------------------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'mttl_sales_amount';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    gt_xml_data_table(gl_xml_idx).tag_value := ln_mt_s_am_sum;
--
    ----------------------------------------------------------------
    -- 中群計(標準原価)データ
    ----------------------------------------------------------------
    -- 標準原価算出
-- 2009/04/20 v1.8 UPDATE START
--    ln_mttl_s_unit_price := ln_mt_s_u_price_sum * ln_mt_quant_sum;
    ln_mttl_s_unit_price := ln_mt_s_unit_price_sum;
-- 2009/04/20 v1.8 UPDATE END
--
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'mttl_s_unit_price';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    gt_xml_data_table(gl_xml_idx).tag_value := ln_mttl_s_unit_price;
--
    ----------------------------------------------------------------
    -- 中群計(粗利)データ
    ----------------------------------------------------------------
    -- 粗利算出
-- 2009/04/20 v1.8 UPDATE START
--    ln_mt_arari_sum := ln_mt_s_am_sum - ln_mttl_s_unit_price;
    ln_mt_arari_sum := ln_mt_ara_sum;
-- 2009/04/20 v1.8 UPDATE END
--
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'mttl_arari';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    gt_xml_data_table(gl_xml_idx).tag_value := ln_mt_arari_sum;
--
    ----------------------------------------------------------------
    -- 中群計(粗利率)データ  ((粗利/売上高)*100)
    ----------------------------------------------------------------
    --  ０除算回避判定
    IF (ln_mt_s_am_sum <> 0) THEN
      -- 値が[0]出なければ計算
      ln_mttl_arari_par := ROUND((ln_mt_arari_sum / ln_mt_s_am_sum) * 100,2);
    ELSE
      -- 値が[0]の場合は、一律[0]設定
      ln_mttl_arari_par := gn_0;
    END IF;
--
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'mttl_arari_par';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    gt_xml_data_table(gl_xml_idx).tag_value := ln_mttl_arari_par;
--
    ----------------------------------------------------------------
    -- 中群計(掛率)データ  ((売上高*100)/(品目定価*本数))
    ----------------------------------------------------------------
-- 2009/04/20 v1.8 UPDATE START
/*
    -- ０除算判定項目へ判定値を挿入
    ln_chk_0 := ln_mt_price_sum * ln_mt_nuit_sum;
    -- ０除算回避判定
    IF (ln_chk_0 <> 0) THEN
      -- 値が[0]出なければ計算
      ln_mttl_kake_par := ROUND((ln_mt_s_am_sum * 100) / ln_chk_0,2);
    ELSE
      -- 値が[0]の場合は、一律[0]設定
      ln_mttl_kake_par := gn_0;
    END IF;
*/
    -- ０除算回避判定
    IF (ln_mt_chk_0_sum <> 0) THEN
      -- 値が[0]出なければ計算
      ln_mttl_kake_par := ROUND((ln_mt_s_am_sum * 100) / ln_mt_chk_0_sum, 2);
    ELSE
      -- 値が[0]の場合は、一律[0]設定
      ln_mttl_kake_par := gn_0;
    END IF;
-- 2009/04/20 v1.8 UPDATE END
--
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'mttl_kake_par';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    -- 品目定価 = ０か、計算結果がマイナスの場合、固定値を登録
    IF (ln_mt_price_sum = 0)
      OR (ln_mttl_kake_par < 0) THEN
      gt_xml_data_table(gl_xml_idx).tag_value := TO_NUMBER(gv_name_kotei); -- 固定値:70.00
    -- 品目定価 <> ０、計算結果がマイナスではない場合、計算結果を登録
    ELSE
      gt_xml_data_table(gl_xml_idx).tag_value := ln_mttl_kake_par;
    END IF;
--
    ----------------------------------------------------------------
    -- 大群計(数量)データ
    ----------------------------------------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'lttl_quant';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    gt_xml_data_table(gl_xml_idx).tag_value := ln_lt_quant_sum;
--
    ----------------------------------------------------------------
    -- 大群計(売上高)データ
    ----------------------------------------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'lttl_sales_amount';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    gt_xml_data_table(gl_xml_idx).tag_value := ln_lt_s_am_sum;
--
    ----------------------------------------------------------------
    -- 大群計(標準原価)データ
    ----------------------------------------------------------------
    -- 標準原価算出
-- 2009/04/20 v1.8 UPDATE START
--    ln_lttl_s_unit_price := ln_lt_s_u_price_sum * ln_lt_quant_sum;
    ln_lttl_s_unit_price := ln_lt_s_unit_price_sum;
-- 2009/04/20 v1.8 UPDATE END
--
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'lttl_s_unit_price';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    gt_xml_data_table(gl_xml_idx).tag_value := ln_lttl_s_unit_price;
--
    ----------------------------------------------------------------
    -- 大群計(粗利)データ
    ----------------------------------------------------------------
    -- 粗利算出
-- 2009/04/20 v1.8 UPDATE START
--    ln_lt_arari_sum := ln_lt_s_am_sum - ln_lttl_s_unit_price;
    ln_lt_arari_sum := ln_lt_ara_sum;
-- 2009/04/20 v1.8 UPDATE END
--
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'lttl_arari';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    gt_xml_data_table(gl_xml_idx).tag_value := ln_lt_arari_sum;
--
    ----------------------------------------------------------------
    -- 大群計(粗利率)データ  ((粗利/売上高)*100)
    ----------------------------------------------------------------
    -- ０除算回避判定
    IF (ln_lt_s_am_sum <> 0) THEN
      -- 値が[0]出なければ計算
      ln_lttl_arari_par := ROUND((ln_lt_arari_sum / ln_lt_s_am_sum) * 100,2);
    ELSE
      -- 値が[0]の場合は、一律[0]設定
      ln_lttl_arari_par := gn_0;
    END IF;
--
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'lttl_arari_par';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    gt_xml_data_table(gl_xml_idx).tag_value := ln_lttl_arari_par;
--
    ----------------------------------------------------------------
    -- 大群計(掛率)データ  ((売上高*100)/(品目定価*本数))
    ----------------------------------------------------------------
-- 2009/04/20 v1.8 UPDATE START
/*
    -- ０除算判定項目へ判定値を挿入
    ln_chk_0 := ln_lt_price_sum * ln_lt_nuit_sum;
    -- ０除算回避判定
    IF (ln_chk_0 <> 0) THEN
      -- 値が[0]出なければ計算
      ln_lttl_kake_par := ROUND((ln_lt_s_am_sum * 100) / ln_chk_0,2);
    ELSE
      -- 値が[0]の場合は、一律[0]設定
      ln_lttl_kake_par := gn_0;
    END IF;
*/
    -- ０除算回避判定
    IF (ln_lt_chk_0_sum <> 0) THEN
      -- 値が[0]出なければ計算
      ln_lttl_kake_par := ROUND((ln_lt_s_am_sum * 100) / ln_lt_chk_0_sum, 2);
    ELSE
      -- 値が[0]の場合は、一律[0]設定
      ln_lttl_kake_par := gn_0;
    END IF;
-- 2009/04/20 v1.8 UPDATE END
--
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'lttl_kake_par';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    -- 品目定価 = ０か、計算結果がマイナスの場合、固定値を登録
    IF (ln_lt_price_sum = 0)
      OR (ln_lttl_kake_par < 0) THEN
      gt_xml_data_table(gl_xml_idx).tag_value := TO_NUMBER(gv_name_kotei); -- 固定値:70.00
    -- 品目定価 <> ０、計算結果がマイナスではない場合、計算結果を登録
    ELSE
      gt_xml_data_table(gl_xml_idx).tag_value := ln_lttl_kake_par;
    END IF;
--
    -- -----------------------------------------------------
    --  群コード終了Ｇタグ出力
    -- -----------------------------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/g_gun';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
    -- -----------------------------------------------------
    --  群コード終了ＬＧタグ出力
    -- -----------------------------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_gun_info';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
    ----------------------------------------------------------------
    -- 拠点計(標準原価)データ
    ----------------------------------------------------------------
    -- 標準原価算出
-- 2009/04/20 v1.8 UPDATE START
--    ln_ktn_s_unit_price := ln_ktn_to_am_sum * ln_ktn_quant_sum;
    ln_ktn_s_unit_price := ln_ktn_s_unit_price_sum;
-- 2009/04/20 v1.8 UPDATE END
--
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'ktn_s_unit_price';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    gt_xml_data_table(gl_xml_idx).tag_value := ln_ktn_s_unit_price;
--
    ----------------------------------------------------------------
    -- 拠点計(粗利)データ
    ----------------------------------------------------------------
    -- 粗利算出
-- 2009/04/20 v1.8 UPDATE START
--    ln_ktn_arari_sum := ln_ktn_s_am_sum - ln_ktn_s_unit_price;
    ln_ktn_arari_sum := ln_ktn_ara_sum;
-- 2009/04/20 v1.8 UPDATE END
--
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'ktn_arari';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    gt_xml_data_table(gl_xml_idx).tag_value := ln_ktn_arari_sum;
--
    ----------------------------------------------------------------
    -- 拠点計(粗利率)データ  ((粗利/売上高)*100)
    ----------------------------------------------------------------
    -- ０除算回避判定
    IF (ln_ktn_s_am_sum <> 0) THEN
      -- 値が[0]出なければ計算
      ln_ktn_arari_par := ROUND((ln_ktn_arari_sum / ln_ktn_s_am_sum) * 100,2);
    ELSE
      -- 値が[0]の場合は、一律[0]設定
      ln_ktn_arari_par := gn_0;
    END IF;
--
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'ktn_arari_par';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    gt_xml_data_table(gl_xml_idx).tag_value := ln_ktn_arari_par;
--
    ----------------------------------------------------------------
    -- 拠点計(掛率)データ  ((売上高*100)/(品目定価*本数))
    ----------------------------------------------------------------
-- 2009/04/20 v1.8 UPDATE START
/*
    -- ０除算判定項目へ判定値を挿入
    ln_chk_0 := ln_ktn_price_sum * ln_ktn_nuit_sum;
    -- ０除算回避判定
    IF (ln_chk_0 <> 0) THEN
      -- 値が[0]出なければ計算
      ln_ktn_kake_par := ROUND((ln_ktn_s_am_sum * 100) / ln_chk_0,2);
    ELSE
      -- 値が[0]の場合は、一律[0]設定
      ln_ktn_kake_par := gn_0;
    END IF;
*/
    -- ０除算回避判定
    IF (ln_ktn_chk_0_sum <> 0) THEN
      -- 値が[0]出なければ計算
      ln_ktn_kake_par := ROUND((ln_ktn_s_am_sum * 100) / ln_ktn_chk_0_sum, 2);
    ELSE
      -- 値が[0]の場合は、一律[0]設定
      ln_ktn_kake_par := gn_0;
    END IF;
-- 2009/04/20 v1.8 UPDATE END
--
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'ktn_kake_par';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    -- 品目定価 = ０か、計算結果がマイナスの場合、固定値を登録
    IF (ln_ktn_price_sum = 0)
      OR (ln_ktn_kake_par < 0) THEN
      gt_xml_data_table(gl_xml_idx).tag_value := TO_NUMBER(gv_name_kotei); -- 固定値:70.00
    -- 品目定価 <> ０、計算結果がマイナスではない場合、計算結果を登録
    ELSE
      gt_xml_data_table(gl_xml_idx).tag_value := ln_ktn_kake_par;
    END IF;
--
    -- -----------------------------------------------------
    --  拠点終了Ｇタグ出力
    -- -----------------------------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/g_ktn';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
    -- -----------------------------------------------------
    --  拠点終了ＬＧタグ出力
    -- -----------------------------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_ktn_info';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
    ----------------------------------------------------------------
    -- 商品区分計(標準原価)データ
    ----------------------------------------------------------------
    -- 標準原価算出
-- 2009/04/20 v1.8 UPDATE START
--    ln_skbn_s_unit_price := ln_skbn_to_am_sum * ln_skbn_quant_sum;
    ln_skbn_s_unit_price := ln_skbn_s_unit_price_sum;
-- 2009/04/20 v1.8 UPDATE END
--
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'skbn_s_unit_price';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    gt_xml_data_table(gl_xml_idx).tag_value := ln_skbn_s_unit_price;
--
    ----------------------------------------------------------------
    -- 商品区分計(粗利)データ
    ----------------------------------------------------------------
    -- 粗利算出
-- 2009/04/20 v1.8 UPDATE START
--    ln_skbn_arari_sum := ln_skbn_s_am_sum - ln_skbn_s_unit_price;
    ln_skbn_arari_sum := ln_skbn_ara_sum;
-- 2009/04/20 v1.8 UPDATE END
--
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'skbn_arari';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    gt_xml_data_table(gl_xml_idx).tag_value := ln_skbn_arari_sum;
--
    ----------------------------------------------------------------
    -- 商品区分計(粗利率)データ  ((粗利/売上高)*100)
    ----------------------------------------------------------------
    -- ０除算回避判定
    IF (ln_skbn_s_am_sum <> 0) THEN
      -- 値が[0]出なければ計算
      ln_skbn_arari_par := ROUND((ln_skbn_arari_sum / ln_skbn_s_am_sum) * 100,2);
    ELSE
      -- 値が[0]の場合は、一律[0]設定
      ln_skbn_arari_par := gn_0;
    END IF;
--
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'skbn_arari_par';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    gt_xml_data_table(gl_xml_idx).tag_value := ln_skbn_arari_par;
--
    ----------------------------------------------------------------
    -- 商品区分計(掛率)データ  ((売上高*100)/(品目定価*本数))
    ----------------------------------------------------------------
-- 2009/04/20 v1.8 UPDATE START
/*
    -- ０除算判定項目へ判定値を挿入
    ln_chk_0 := ln_skbn_price_sum * ln_skbn_nuit_sum;
    -- ０除算回避判定
    IF (ln_chk_0 <> 0) THEN
      -- 値が[0]出なければ計算
      ln_skbn_kake_par := ROUND((ln_skbn_s_am_sum * 100) / ln_chk_0,2);
    ELSE
      -- 値が[0]の場合は、一律[0]設定
      ln_skbn_kake_par := gn_0;
    END IF;
*/
    -- ０除算回避判定
    IF (ln_skbn_chk_0_sum <> 0) THEN
      -- 値が[0]出なければ計算
      ln_skbn_kake_par := ROUND((ln_skbn_s_am_sum * 100) / ln_skbn_chk_0_sum, 2);
    ELSE
      -- 値が[0]の場合は、一律[0]設定
      ln_skbn_kake_par := gn_0;
    END IF;
-- 2009/04/20 v1.8 UPDATE END
--
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'skbn_kake_par';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    -- 品目定価 = ０か、計算結果がマイナスの場合、固定値を登録
    IF (ln_skbn_price_sum = 0)
      OR (ln_skbn_kake_par < 0) THEN
      gt_xml_data_table(gl_xml_idx).tag_value := TO_NUMBER(gv_name_kotei); -- 固定値:70.00
    -- 品目定価 <> ０、計算結果がマイナスではない場合、計算結果を登録
    ELSE
      gt_xml_data_table(gl_xml_idx).tag_value := ln_skbn_kake_par;
    END IF;
--
    ----------------------------------------------------------------
    -- 総合計(標準原価)データ
    ----------------------------------------------------------------
    -- 標準原価算出
-- 2009/04/20 v1.8 UPDATE START
--    ln_to_s_unit_price := ln_to_to_am_sum * ln_to_quant_sum;
    ln_to_s_unit_price := ln_to_s_unit_price_sum;
-- 2009/04/20 v1.8 UPDATE END
--
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'to_s_unit_price';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    gt_xml_data_table(gl_xml_idx).tag_value := ln_to_s_unit_price;
--
    ----------------------------------------------------------------
    -- 総合計(粗利)データ
    ----------------------------------------------------------------
    -- 粗利算出
-- 2009/04/20 v1.8 UPDATE START
--    ln_to_arari_sum := ln_to_s_am_sum - ln_to_s_unit_price;
    ln_to_arari_sum := ln_to_ara_sum;
-- 2009/04/20 v1.8 UPDATE END
--
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'to_arari';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    gt_xml_data_table(gl_xml_idx).tag_value := ln_to_arari_sum;
--
    ----------------------------------------------------------------
    -- 総合計(粗利率)データ  ((粗利/売上高)*100)
    ----------------------------------------------------------------
    -- ０除算回避判定
    IF (ln_to_s_am_sum <> 0) THEN
      -- 値が[0]出なければ計算
      ln_to_arari_par := ROUND((ln_to_arari_sum / ln_to_s_am_sum) * 100,2);
    ELSE
      -- 値が[0]の場合は、一律[0]設定
      ln_to_arari_par := gn_0;
    END IF;
--
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'to_arari_par';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    gt_xml_data_table(gl_xml_idx).tag_value := ln_to_arari_par;
--
    ----------------------------------------------------------------
    -- 総合計(掛率)データ  ((売上高*100)/(品目定価*本数))
    ----------------------------------------------------------------
-- 2009/04/20 v1.8 UPDATE START
/*
    -- ０除算判定項目へ判定値を挿入
    ln_chk_0 := ln_to_price_sum * ln_to_nuit_sum;
    -- ０除算回避判定
    IF (ln_chk_0 <> 0) THEN
      -- 値が[0]出なければ計算
      ln_to_kake_par := ROUND((ln_to_s_am_sum * 100) / ln_chk_0,2);
    ELSE
      -- 値が[0]の場合は、一律[0]設定
      ln_to_kake_par := gn_0;
    END IF;
*/
    -- ０除算回避判定
    IF (ln_to_chk_0_sum <> 0) THEN
      -- 値が[0]出なければ計算
      ln_to_kake_par := ROUND((ln_to_s_am_sum * 100) / ln_to_chk_0_sum, 2);
    ELSE
      -- 値が[0]の場合は、一律[0]設定
      ln_to_kake_par := gn_0;
    END IF;
-- 2009/04/20 v1.8 UPDATE END
--
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'to_kake_par';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    -- 品目定価 = ０か、計算結果がマイナスの場合、固定値を登録
    IF (ln_to_price_sum = 0)
      OR (ln_to_kake_par < 0) THEN
      gt_xml_data_table(gl_xml_idx).tag_value := TO_NUMBER(gv_name_kotei); -- 固定値:70.00
    -- 品目定価 <> ０、計算結果がマイナスではない場合、計算結果を登録
    ELSE
      gt_xml_data_table(gl_xml_idx).tag_value := ln_to_kake_par;
    END IF;
--
    -- -----------------------------------------------------
    --  商品区分終了Ｇタグ出力
    -- -----------------------------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/g_skbn';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
    -- -----------------------------------------------------
    --  商品区分終了ＬＧタグ出力
    -- -----------------------------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_skbn_info';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
    -- -----------------------------------------------------
    -- データ終了タグ出力
    -- -----------------------------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/data_info';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
    -- -----------------------------------------------------
    -- ルート終了タグ出力
    -- -----------------------------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/root';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
    -- 出力種別が「拠点」の場合
    ELSE
      -- =====================================================
      -- データ抽出 - 販売計画表情報抽出 (B-1-1-2)
      -- =====================================================
      prc_sale_plan_1
        (
          ot_sale_plan_1    => gr_sale_plan_1     -- 取得レコード群
         ,ov_errbuf         => lv_errbuf          -- エラー・メッセージ           --# 固定 #
         ,ov_retcode        => lv_retcode         -- リターン・コード             --# 固定 #
         ,ov_errmsg         => lv_errmsg          -- ユーザー・エラー・メッセージ --# 固定 #
        );
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
--
      -- 取得データが０件の場合
      ELSIF (gr_sale_plan_1.COUNT = 0) THEN
        RAISE no_data_expt;
--
      END IF;
--
      -- =====================================================
      -- 項目データ抽出・出力処理
      -- =====================================================
      -- -----------------------------------------------------
      -- データ開始タグ出力
      -- -----------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'data_info';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
      -- -----------------------------------------------------
      -- 商品区分開始ＬＧタグ出力
      -- -----------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_skbn_info';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
      -- =====================================================
      -- 項目データ抽出・出力処理
      -- =====================================================
      <<main_data_loop_1>>
      FOR i IN 1..gr_sale_plan_1.COUNT LOOP
        -- ====================================================
        --  商品区分ブレイク
        -- ====================================================
        -- 商品区分が切り替わったとき
        IF (gr_sale_plan_1(i).skbn <> lv_skbn_break) THEN
          -- ====================================================
          --  商品区分終了Ｇタグ出力判定
          -- ====================================================
          -- 最初のレコードの時は出力せず
          IF (lv_skbn_break <> lc_break_init) THEN
            -- -----------------------------------------------------
            --  品目終了ＬＧタグ出力
            -- -----------------------------------------------------
            gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
            gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_dtl_info';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
            ----------------------------------------------------------------
            -- 細群計(標準原価)データ
            ----------------------------------------------------------------
          -- 標準原価算出
-- 2009/04/20 v1.8 UPDATE START
--            ln_syo_s_unit_price := ln_to_am_sum * ln_quant_sum;
            ln_syo_s_unit_price := ln_s_unit_price_sum;
-- 2009/04/20 v1.8 UPDATE END
--
            gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
            gt_xml_data_table(gl_xml_idx).tag_name  := 'syo_s_unit_price';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
            gt_xml_data_table(gl_xml_idx).tag_value := ln_syo_s_unit_price;
--
            ----------------------------------------------------------------
            -- 細群計(粗利)データ
            ----------------------------------------------------------------
            -- 粗利算出
-- 2009/04/20 v1.8 UPDATE START
--            ln_arari_sum := ln_s_am_sum - ln_syo_s_unit_price;
            ln_arari_sum := ln_ara_sum;
-- 2009/04/20 v1.8 UPDATE END
--
            gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
            gt_xml_data_table(gl_xml_idx).tag_name  := 'syo_arari';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
            gt_xml_data_table(gl_xml_idx).tag_value := ln_arari_sum;
--
            ----------------------------------------------------------------
            -- 細群計(粗利率)データ  ((粗利/売上高)*100)
            ----------------------------------------------------------------
            -- ０除算回避判定
            IF (ln_s_am_sum <> 0) THEN
              -- 値が[0]出なければ計算
              ln_syo_arari_par := ROUND((ln_arari_sum / ln_s_am_sum) * 100,2);
            ELSE
              -- 値が[0]の場合は、一律[0]設定
              ln_syo_arari_par := gn_0;
            END IF;
--
            gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
            gt_xml_data_table(gl_xml_idx).tag_name  := 'syo_arari_par';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
            gt_xml_data_table(gl_xml_idx).tag_value := ln_syo_arari_par;
--
            ----------------------------------------------------------------
            -- 細群計(掛率)データ  ((売上高*100)/(品目定価*本数))
            ----------------------------------------------------------------
-- 2009/04/20 v1.8 UPDATE START
/*
            -- ０除算判定項目へ判定値を挿入
            ln_chk_0 := ln_price_sum * ln_nuit_sum;
            -- ０除算回避判定
            IF (ln_chk_0 <> 0) THEN
              -- 値が[0]出なければ計算
              ln_syo_kake_par := ROUND((ln_s_am_sum * 100) / ln_chk_0,2);
            ELSE
              -- 値が[0]の場合は、一律[0]設定
              ln_syo_kake_par := gn_0;
            END IF;
*/
            -- ０除算回避判定
            IF (ln_chk_0_sum <> 0) THEN
              -- 値が[0]出なければ計算
              ln_syo_kake_par := ROUND((ln_s_am_sum * 100) / ln_chk_0_sum, 2);
            ELSE
              -- 値が[0]の場合は、一律[0]設定
              ln_syo_kake_par := gn_0;
            END IF;
-- 2009/04/20 v1.8 UPDATE END
--
            gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
            gt_xml_data_table(gl_xml_idx).tag_name  := 'syo_kake_par';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
            -- 品目定価 = ０か、計算結果がマイナスの場合、固定値を登録
            IF (ln_price_sum = 0) 
              OR (ln_syo_kake_par < 0)THEN
              gt_xml_data_table(gl_xml_idx).tag_value := TO_NUMBER(gv_name_kotei); -- 固定値:70.00
            -- 品目定価 <> ０、計算結果がマイナスではない場合、計算結果を登録
            ELSE
              gt_xml_data_table(gl_xml_idx).tag_value := ln_syo_kake_par;
            END IF;
--
            ----------------------------------------------------------------
            -- 小群計(数量)データ
            ----------------------------------------------------------------
            gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
            gt_xml_data_table(gl_xml_idx).tag_name  := 'sttl_quant';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
            gt_xml_data_table(gl_xml_idx).tag_value := ln_st_quant_sum;
--
            ----------------------------------------------------------------
            -- 小群計(売上高)データ
            ----------------------------------------------------------------
            gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
            gt_xml_data_table(gl_xml_idx).tag_name  := 'sttl_sales_amount';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
            gt_xml_data_table(gl_xml_idx).tag_value := ln_st_s_am_sum;
--
            ----------------------------------------------------------------
            -- 小群計(標準原価)データ
            ----------------------------------------------------------------
            -- 標準原価算出
-- 2009/04/20 v1.8 UPDATE START
--            ln_sttl_s_unit_price := ln_st_s_u_price_sum * ln_st_quant_sum;
            ln_sttl_s_unit_price := ln_st_s_unit_price_sum;
-- 2009/04/20 v1.8 UPDATE END
--
            gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
            gt_xml_data_table(gl_xml_idx).tag_name  := 'sttl_s_unit_price';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
            gt_xml_data_table(gl_xml_idx).tag_value := ln_sttl_s_unit_price;
--
            ----------------------------------------------------------------
            -- 小群計(粗利)データ
            ----------------------------------------------------------------
            -- 粗利算出
-- 2009/04/20 v1.8 UPDATE START
--            ln_st_arari_sum := ln_s_am_sum - ln_syo_s_unit_price;
            ln_st_arari_sum := ln_st_ara_sum;
-- 2009/04/20 v1.8 UPDATE END
--
            gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
            gt_xml_data_table(gl_xml_idx).tag_name  := 'sttl_arari';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
            gt_xml_data_table(gl_xml_idx).tag_value := ln_st_arari_sum;
--
            ----------------------------------------------------------------
            -- 小群計(粗利率)データ  ((粗利/売上高)*100)
            ----------------------------------------------------------------
            -- ０除算回避判定
            IF (ln_st_s_am_sum <> 0) THEN
              -- 値が[0]出なければ計算
              ln_sttl_arari_par := ROUND((ln_st_arari_sum / ln_st_s_am_sum) * 100,2);
            ELSE
              -- 値が[0]の場合は、一律[0]設定
              ln_sttl_arari_par := gn_0;
            END IF;
--
            gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
            gt_xml_data_table(gl_xml_idx).tag_name  := 'sttl_arari_par';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
            gt_xml_data_table(gl_xml_idx).tag_value := ln_sttl_arari_par;
--
            ----------------------------------------------------------------
            -- 小群計(掛率)データ  ((売上高*100)/(品目定価*本数))
            ----------------------------------------------------------------
-- 2009/04/20 v1.8 UPDATE START
/*
            -- ０除算判定項目へ判定値を挿入
            ln_chk_0 := ln_st_price_sum * ln_st_nuit_sum;
            -- ０除算回避判定
            IF (ln_chk_0 <> 0) THEN
              -- 値が[0]出なければ計算
              ln_sttl_kake_par := ROUND((ln_st_s_am_sum * 100) / ln_chk_0,2);
            ELSE
              -- 値が[0]の場合は、一律[0]設定
              ln_sttl_kake_par := gn_0;
            END IF;
*/
            -- ０除算回避判定
            IF (ln_st_chk_0_sum <> 0) THEN
              -- 値が[0]出なければ計算
              ln_sttl_kake_par := ROUND((ln_st_s_am_sum * 100) / ln_st_chk_0_sum, 2);
            ELSE
              -- 値が[0]の場合は、一律[0]設定
              ln_sttl_kake_par := gn_0;
            END IF;
-- 2009/04/20 v1.8 UPDATE END
--
            gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
            gt_xml_data_table(gl_xml_idx).tag_name  := 'sttl_kake_par';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
            -- 品目定価 = ０か、計算結果がマイナスの場合、固定値を登録
            IF (ln_st_price_sum = 0)
              OR (ln_sttl_kake_par < 0) THEN
              gt_xml_data_table(gl_xml_idx).tag_value := TO_NUMBER(gv_name_kotei); -- 固定値:70.00
              -- 品目定価 <> ０、計算結果がマイナスではない場合、計算結果を登録
            ELSE
              gt_xml_data_table(gl_xml_idx).tag_value := ln_sttl_kake_par;
            END IF;
--
            ----------------------------------------------------------------
            -- 中群計(数量)データ
            ----------------------------------------------------------------
            gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
            gt_xml_data_table(gl_xml_idx).tag_name  := 'mttl_quant';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
            gt_xml_data_table(gl_xml_idx).tag_value := ln_mt_quant_sum;
--
            ----------------------------------------------------------------
            -- 中群計(売上高)データ
            ----------------------------------------------------------------
            gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
            gt_xml_data_table(gl_xml_idx).tag_name  := 'mttl_sales_amount';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
            gt_xml_data_table(gl_xml_idx).tag_value := ln_mt_s_am_sum;
--
            ----------------------------------------------------------------
            -- 中群計(標準原価)データ
            ----------------------------------------------------------------
            -- 標準原価算出
-- 2009/04/20 v1.8 UPDATE START
--            ln_mttl_s_unit_price := ln_mt_s_u_price_sum * ln_mt_quant_sum;
            ln_mttl_s_unit_price := ln_mt_s_unit_price_sum;
-- 2009/04/20 v1.8 UPDATE END
--
            gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
            gt_xml_data_table(gl_xml_idx).tag_name  := 'mttl_s_unit_price';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
            gt_xml_data_table(gl_xml_idx).tag_value := ln_mttl_s_unit_price;
--
            ----------------------------------------------------------------
            -- 中群計(粗利)データ
            ----------------------------------------------------------------
            -- 粗利算出
-- 2009/04/20 v1.8 UPDATE START
--            ln_mt_arari_sum := ln_mt_s_am_sum - ln_mttl_s_unit_price;
            ln_mt_arari_sum := ln_mt_ara_sum;
-- 2009/04/20 v1.8 UPDATE END
--
            gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
            gt_xml_data_table(gl_xml_idx).tag_name  := 'mttl_arari';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
            gt_xml_data_table(gl_xml_idx).tag_value := ln_mt_arari_sum;
--
            ----------------------------------------------------------------
            -- 中群計(粗利率)データ  ((粗利/売上高)*100)
            ----------------------------------------------------------------
            --  ０除算回避判定
            IF (ln_mt_s_am_sum <> 0) THEN
              -- 値が[0]出なければ計算
              ln_mttl_arari_par := ROUND((ln_mt_arari_sum / ln_mt_s_am_sum) * 100,2);
            ELSE
              -- 値が[0]の場合は、一律[0]設定
              ln_mttl_arari_par := gn_0;
            END IF;
--
            gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
            gt_xml_data_table(gl_xml_idx).tag_name  := 'mttl_arari_par';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
            gt_xml_data_table(gl_xml_idx).tag_value := ln_mttl_arari_par;
--
            ----------------------------------------------------------------
            -- 中群計(掛率)データ  ((売上高*100)/(品目定価*本数))
            ----------------------------------------------------------------
-- 2009/04/20 v1.8 UPDATE START
/*
            -- ０除算判定項目へ判定値を挿入
            ln_chk_0 := ln_mt_price_sum * ln_mt_nuit_sum;
            -- ０除算回避判定
            IF (ln_chk_0 <> 0) THEN
              -- 値が[0]出なければ計算
              ln_mttl_kake_par := ROUND((ln_mt_s_am_sum * 100) / ln_chk_0,2);
            ELSE
              -- 値が[0]の場合は、一律[0]設定
              ln_mttl_kake_par := gn_0;
            END IF;
*/
            -- ０除算回避判定
            IF (ln_mt_chk_0_sum <> 0) THEN
              -- 値が[0]出なければ計算
              ln_mttl_kake_par := ROUND((ln_mt_s_am_sum * 100) / ln_mt_chk_0_sum, 2);
            ELSE
              -- 値が[0]の場合は、一律[0]設定
              ln_mttl_kake_par := gn_0;
            END IF;
-- 2009/04/20 v1.8 UPDATE END
--
            gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
            gt_xml_data_table(gl_xml_idx).tag_name  := 'mttl_kake_par';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
            -- 品目定価 = ０か、計算結果がマイナスの場合、固定値を登録
            IF (ln_mt_price_sum = 0)
              OR (ln_mttl_kake_par < 0) THEN
              gt_xml_data_table(gl_xml_idx).tag_value := TO_NUMBER(gv_name_kotei); -- 固定値:70.00
            -- 品目定価 <> ０、計算結果がマイナスではない場合、計算結果を登録
            ELSE
              gt_xml_data_table(gl_xml_idx).tag_value := ln_mttl_kake_par;
            END IF;
--
            ----------------------------------------------------------------
            -- 大群計(数量)データ
            ----------------------------------------------------------------
            gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
            gt_xml_data_table(gl_xml_idx).tag_name  := 'lttl_quant';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
            gt_xml_data_table(gl_xml_idx).tag_value := ln_lt_quant_sum;
--
            ----------------------------------------------------------------
            -- 大群計(売上高)データ
            ----------------------------------------------------------------
            gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
            gt_xml_data_table(gl_xml_idx).tag_name  := 'lttl_sales_amount';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
            gt_xml_data_table(gl_xml_idx).tag_value := ln_lt_s_am_sum;
--
            ----------------------------------------------------------------
            -- 大群計(標準原価)データ
            ----------------------------------------------------------------
            -- 標準原価算出
-- 2009/04/20 v1.8 UPDATE START
--            ln_lttl_s_unit_price := ln_lt_s_u_price_sum * ln_lt_quant_sum;
            ln_lttl_s_unit_price := ln_lt_s_unit_price_sum;
-- 2009/04/20 v1.8 UPDATE END
--
            gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
            gt_xml_data_table(gl_xml_idx).tag_name  := 'lttl_s_unit_price';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
            gt_xml_data_table(gl_xml_idx).tag_value := ln_lttl_s_unit_price;
--
            ----------------------------------------------------------------
            -- 大群計(粗利)データ
            ----------------------------------------------------------------
            -- 粗利算出
-- 2009/04/20 v1.8 UPDATE START
--            ln_lt_arari_sum := ln_lt_s_am_sum - ln_lttl_s_unit_price;
            ln_lt_arari_sum := ln_lt_ara_sum;
-- 2009/04/20 v1.8 UPDATE END
--
            gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
            gt_xml_data_table(gl_xml_idx).tag_name  := 'lttl_arari';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
            gt_xml_data_table(gl_xml_idx).tag_value := ln_lt_arari_sum;
--
            ----------------------------------------------------------------
            -- 大群計(粗利率)データ  ((粗利/売上高)*100)
            ----------------------------------------------------------------
            -- ０除算回避判定
            IF (ln_lt_s_am_sum <> 0) THEN
              -- 値が[0]出なければ計算
              ln_lttl_arari_par := ROUND((ln_lt_arari_sum / ln_lt_s_am_sum) * 100,2);
            ELSE
              -- 値が[0]の場合は、一律[0]設定
              ln_lttl_arari_par := gn_0;
            END IF;
--
            gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
            gt_xml_data_table(gl_xml_idx).tag_name  := 'lttl_arari_par';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
            gt_xml_data_table(gl_xml_idx).tag_value := ln_lttl_arari_par;
--
            ----------------------------------------------------------------
            -- 大群計(掛率)データ  ((売上高*100)/(品目定価*本数))
            ----------------------------------------------------------------
-- 2009/04/20 v1.8 UPDATE START
/*
            -- ０除算判定項目へ判定値を挿入
            ln_chk_0 := ln_lt_price_sum * ln_lt_nuit_sum;
            -- ０除算回避判定
            IF (ln_chk_0 <> 0) THEN
              -- 値が[0]出なければ計算
              ln_lttl_kake_par := ROUND((ln_lt_s_am_sum * 100) / ln_chk_0,2);
            ELSE
              -- 値が[0]の場合は、一律[0]設定
              ln_lttl_kake_par := gn_0;
            END IF;
*/
            -- ０除算回避判定
            IF (ln_lt_chk_0_sum <> 0) THEN
              -- 値が[0]出なければ計算
              ln_lttl_kake_par := ROUND((ln_lt_s_am_sum * 100) / ln_lt_chk_0_sum, 2);
            ELSE
              -- 値が[0]の場合は、一律[0]設定
              ln_lttl_kake_par := gn_0;
            END IF;
-- 2009/04/20 v1.8 UPDATE END
--
            gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
            gt_xml_data_table(gl_xml_idx).tag_name  := 'lttl_kake_par';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
            -- 品目定価 = ０か、計算結果がマイナスの場合、固定値を登録
            IF (ln_lt_price_sum = 0)
              OR (ln_lttl_kake_par < 0) THEN
              gt_xml_data_table(gl_xml_idx).tag_value := TO_NUMBER(gv_name_kotei); -- 固定値:70.00
            -- 品目定価 <> ０、計算結果がマイナスではない場合、計算結果を登録
            ELSE
              gt_xml_data_table(gl_xml_idx).tag_value := ln_lttl_kake_par;
            END IF;
--
            -- -----------------------------------------------------
            --  群コード終了Ｇタグ出力
            -- -----------------------------------------------------
            gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
            gt_xml_data_table(gl_xml_idx).tag_name  := '/g_gun';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
            -- -----------------------------------------------------
            --  群コード終了ＬＧタグ出力
            -- -----------------------------------------------------
            gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
            gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_gun_info';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
            ----------------------------------------------------------------
            -- 拠点計(標準原価)データ
            ----------------------------------------------------------------
            -- 標準原価算出
-- 2009/04/20 v1.8 UPDATE START
--            ln_ktn_s_unit_price := ln_ktn_to_am_sum * ln_ktn_quant_sum;
            ln_ktn_s_unit_price := ln_ktn_s_unit_price_sum;
-- 2009/04/20 v1.8 UPDATE END
--
            gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
            gt_xml_data_table(gl_xml_idx).tag_name  := 'ktn_s_unit_price';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
            gt_xml_data_table(gl_xml_idx).tag_value := ln_ktn_s_unit_price;
--
            ----------------------------------------------------------------
            -- 拠点計(粗利)データ
            ----------------------------------------------------------------
            -- 粗利算出
-- 2009/04/20 v1.8 UPDATE START
--            ln_ktn_arari_sum := ln_ktn_s_am_sum - ln_ktn_s_unit_price;
            ln_ktn_arari_sum := ln_ktn_ara_sum;
-- 2009/04/20 v1.8 UPDATE END
--
            gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
            gt_xml_data_table(gl_xml_idx).tag_name  := 'ktn_arari';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
            gt_xml_data_table(gl_xml_idx).tag_value := ln_ktn_arari_sum;
--
            ----------------------------------------------------------------
            -- 拠点計(粗利率)データ  ((粗利/売上高)*100)
            ----------------------------------------------------------------
            -- ０除算回避判定
            IF (ln_ktn_s_am_sum <> 0) THEN
              -- 値が[0]出なければ計算
              ln_ktn_arari_par := ROUND((ln_ktn_arari_sum / ln_ktn_s_am_sum) * 100,2);
            ELSE
              -- 値が[0]の場合は、一律[0]設定
              ln_ktn_arari_par := gn_0;
            END IF;
--
            gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
            gt_xml_data_table(gl_xml_idx).tag_name  := 'ktn_arari_par';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
            gt_xml_data_table(gl_xml_idx).tag_value := ln_ktn_arari_par;
--
            ----------------------------------------------------------------
            -- 拠点計(掛率)データ  ((売上高*100)/(品目定価*本数))
            ----------------------------------------------------------------
-- 2009/04/20 v1.8 UPDATE START
/*
            -- ０除算判定項目へ判定値を挿入
            ln_chk_0 := ln_ktn_price_sum * ln_ktn_nuit_sum;
            -- ０除算回避判定
            IF (ln_chk_0 <> 0) THEN
              -- 値が[0]出なければ計算
              ln_ktn_kake_par := ROUND((ln_ktn_s_am_sum * 100) / ln_chk_0,2);
            ELSE
              -- 値が[0]の場合は、一律[0]設定
              ln_ktn_kake_par := gn_0;
            END IF;
*/
            -- ０除算回避判定
            IF (ln_ktn_chk_0_sum <> 0) THEN
              -- 値が[0]出なければ計算
              ln_ktn_kake_par := ROUND((ln_ktn_s_am_sum * 100) / ln_ktn_chk_0_sum, 2);
            ELSE
              -- 値が[0]の場合は、一律[0]設定
              ln_ktn_kake_par := gn_0;
            END IF;
-- 2009/04/20 v1.8 UPDATE END
--
            gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
            gt_xml_data_table(gl_xml_idx).tag_name  := 'ktn_kake_par';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
            -- 品目定価 = ０か、計算結果がマイナスの場合、固定値を登録
            IF (ln_ktn_price_sum = 0)
              OR (ln_ktn_kake_par < 0) THEN
              gt_xml_data_table(gl_xml_idx).tag_value := TO_NUMBER(gv_name_kotei); -- 固定値:70.00
            -- 品目定価 <> ０、計算結果がマイナスではない場合、計算結果を登録
            ELSE
              gt_xml_data_table(gl_xml_idx).tag_value := ln_ktn_kake_par;
            END IF;
--
            -- -----------------------------------------------------
            --  拠点終了Ｇタグ出力
            -- -----------------------------------------------------
            gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
            gt_xml_data_table(gl_xml_idx).tag_name  := '/g_ktn';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
            -- -----------------------------------------------------
            --  拠点終了ＬＧタグ出力
            -- -----------------------------------------------------
            gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
            gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_ktn_info';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
            ----------------------------------------------------------------
            -- 商品区分計(標準原価)データ
            ----------------------------------------------------------------
            -- 標準原価算出
-- 2009/04/20 v1.8 UPDATE START
--            ln_skbn_s_unit_price := ln_skbn_to_am_sum * ln_skbn_quant_sum;
            ln_skbn_s_unit_price := ln_skbn_s_unit_price_sum;
-- 2009/04/20 v1.8 UPDATE END
--
            gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
            gt_xml_data_table(gl_xml_idx).tag_name  := 'skbn_s_unit_price';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
            gt_xml_data_table(gl_xml_idx).tag_value := ln_skbn_s_unit_price;
--
            ----------------------------------------------------------------
            -- 商品区分計(粗利)データ
            ----------------------------------------------------------------
            -- 粗利算出
-- 2009/04/20 v1.8 UPDATE START
--            ln_skbn_arari_sum := ln_skbn_s_am_sum - ln_skbn_s_unit_price;
            ln_skbn_arari_sum := ln_skbn_ara_sum;
-- 2009/04/20 v1.8 UPDATE END
--
            gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
            gt_xml_data_table(gl_xml_idx).tag_name  := 'skbn_arari';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
            gt_xml_data_table(gl_xml_idx).tag_value := ln_skbn_arari_sum;
--
            ----------------------------------------------------------------
            -- 商品区分計(粗利率)データ  ((粗利/売上高)*100)
            ----------------------------------------------------------------
            -- ０除算回避判定
            IF (ln_skbn_s_am_sum <> 0) THEN
              -- 値が[0]出なければ計算
              ln_skbn_arari_par := ROUND((ln_skbn_arari_sum / ln_skbn_s_am_sum) * 100,2);
            ELSE
              -- 値が[0]の場合は、一律[0]設定
              ln_skbn_arari_par := gn_0;
            END IF;
--
            gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
            gt_xml_data_table(gl_xml_idx).tag_name  := 'skbn_arari_par';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
            gt_xml_data_table(gl_xml_idx).tag_value := ln_skbn_arari_par;
--
            ----------------------------------------------------------------
            -- 商品区分計(掛率)データ  ((売上高*100)/(品目定価*本数))
            ----------------------------------------------------------------
-- 2009/04/20 v1.8 UPDATE START
/*
            -- ０除算判定項目へ判定値を挿入
            ln_chk_0 := ln_skbn_price_sum * ln_skbn_nuit_sum;
            -- ０除算回避判定
            IF (ln_chk_0 <> 0) THEN
              -- 値が[0]出なければ計算
              ln_skbn_kake_par := ROUND((ln_skbn_s_am_sum * 100) / ln_chk_0,2);
            ELSE
              -- 値が[0]の場合は、一律[0]設定
              ln_skbn_kake_par := gn_0;
            END IF;
*/
            -- ０除算回避判定
            IF (ln_skbn_chk_0_sum <> 0) THEN
              -- 値が[0]出なければ計算
              ln_skbn_kake_par := ROUND((ln_skbn_s_am_sum * 100) / ln_skbn_chk_0_sum, 2);
            ELSE
              -- 値が[0]の場合は、一律[0]設定
              ln_skbn_kake_par := gn_0;
            END IF;
-- 2009/04/20 v1.8 UPDATE END
--
            gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
            gt_xml_data_table(gl_xml_idx).tag_name  := 'skbn_kake_par';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
            -- 品目定価 = ０か、計算結果がマイナスの場合、固定値を登録
            IF (ln_skbn_price_sum = 0)
              OR (ln_skbn_kake_par < 0) THEN
              gt_xml_data_table(gl_xml_idx).tag_value := TO_NUMBER(gv_name_kotei); -- 固定値:70.00
            -- 品目定価 <> ０、計算結果がマイナスではない場合、計算結果を登録
            ELSE
              gt_xml_data_table(gl_xml_idx).tag_value := ln_skbn_kake_par;
            END IF;
--
            -- -----------------------------------------------------
            --  商品区分終了Ｇタグ出力
            -- -----------------------------------------------------
            gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
            gt_xml_data_table(gl_xml_idx).tag_name  := '/g_skbn';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
          END IF;
--
          -- -----------------------------------------------------
          --  商品区分開始Ｇタグ出力
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'g_skbn';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
          -- 商品区分(名称)判定
          -- 入力Ｐが'1' or 入力ＰがNULLで抽出データが'1'の場合
          IF (gr_param.prod_div = gv_prod_div_leaf)
            OR (gr_param.prod_div IS NULL
              AND gr_sale_plan_1(i).skbn = gv_prod_div_leaf) THEN
            lv_skbn_name := lc_name_leaf;        -- 商品区分(名称)に「リーフ」を出力
          -- 入力Ｐが'2' or 入力ＰがNULLで抽出データが'2'の場合
          ELSIF (gr_param.prod_div = gv_prod_div_drink)
            OR (gr_param.prod_div IS NULL
              AND gr_sale_plan_1(i).skbn = gv_prod_div_drink) THEN
            lv_skbn_name := lc_name_drink;   -- 商品区分(名称)に「ドリンク」を出力
          END IF;
--
          ----------------------------------------------------------------
          -- 商品区分(コード) タグ
          ----------------------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'skbn_code';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          gt_xml_data_table(gl_xml_idx).tag_value := gr_sale_plan_1(i).skbn;
--
          ----------------------------------------------------------------
          -- 商品区分(名称) タグ
          ----------------------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'skbn_name';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          gt_xml_data_table(gl_xml_idx).tag_value := lv_skbn_name;
--
          -- -----------------------------------------------------
          --  拠点区分開始ＬＧタグ出力
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_ktn_info';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
          -- -----------------------------------------------------
          --  拠点区分開始Ｇタグ出力
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'g_ktn';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
          ----------------------------------------------------------------
          -- 拠点区分(拠点コード) タグ
          ----------------------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'ktn_code';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          gt_xml_data_table(gl_xml_idx).tag_value := gr_sale_plan_1(i).ktn_code;
--
          ----------------------------------------------------------------
          -- 拠点区分(拠点略称) タグ
          ----------------------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'ktn_name';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          gt_xml_data_table(gl_xml_idx).tag_value := gr_sale_plan_1(i).party_short_name;
--
          -- -----------------------------------------------------
          --  群コード開始LＧタグ出力
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_gun_info';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
          -- -----------------------------------------------------
          --  群コード開始Ｇタグ出力
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'g_gun';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
          -- -----------------------------------------------------
          --  品目開始ＬＧタグ出力
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_dtl_info';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
          -- 各ブレイクキー更新
          lv_skbn_break := gr_sale_plan_1(i).skbn;               -- 商品区分
          lv_ktn_break  := gr_sale_plan_1(i).ktn_code;           -- 拠点
          lv_gun_break  := gr_sale_plan_1(i).gun;                -- 群コード
          lv_sttl_break := SUBSTRB(gr_sale_plan_1(i).gun,1,3);   -- 小群計
          lv_mttl_break := SUBSTRB(gr_sale_plan_1(i).gun,1,2);   -- 中群計
          lv_lttl_break := SUBSTRB(gr_sale_plan_1(i).gun,1,1);   -- 大群計
--
          -- 小群計集計用項目初期化
          ln_st_quant_sum     := 0;          -- 数量
-- 2009/04/20 v1.8 UPDATE START
--          ln_st_s_u_price_sum := 0;          -- 内訳合計
          ln_st_s_unit_price_sum := 0;       -- 標準原価
          ln_st_ara_sum          := 0;       -- 粗利(集計用)
          ln_st_chk_0_sum        := 0;       -- 掛率(集計用)
-- 2009/04/20 v1.8 UPDATE END
          ln_st_arari_sum     := 0;          -- 粗利
          ln_st_s_am_sum      := 0;          -- 売上高
          ln_st_nuit_sum      := 0;          -- 本数
          ln_st_price_sum     := 0;          -- 品目定価
          -- 中群計集計用項目初期化
          ln_mt_quant_sum     := 0;          -- 数量
-- 2009/04/20 v1.8 UPDATE START
--          ln_mt_s_u_price_sum := 0;          -- 内訳合計
          ln_mt_s_unit_price_sum := 0;       -- 標準原価
          ln_mt_ara_sum          := 0;       -- 粗利(集計用)
          ln_mt_chk_0_sum        := 0;       -- 掛率(集計用)
-- 2009/04/20 v1.8 UPDATE END
          ln_mt_arari_sum     := 0;          -- 粗利
          ln_mt_s_am_sum      := 0;          -- 売上高
          ln_mt_nuit_sum      := 0;          -- 本数
          ln_mt_price_sum     := 0;          -- 品目定価
          -- 大群計集計用項目初期化
          ln_lt_quant_sum     := 0;          -- 数量
-- 2009/04/20 v1.8 UPDATE START
--          ln_lt_s_u_price_sum := 0;          -- 内訳合計
          ln_lt_s_unit_price_sum := 0;       -- 標準原価
          ln_lt_ara_sum          := 0;       -- 粗利(集計用)
          ln_lt_chk_0_sum        := 0;       -- 掛率(集計用)
-- 2009/04/20 v1.8 UPDATE END
          ln_lt_arari_sum     := 0;          -- 粗利
          ln_lt_s_am_sum      := 0;          -- 売上高
          ln_lt_nuit_sum      := 0;          -- 本数
          ln_lt_price_sum     := 0;          -- 品目定価
          -- 拠点計計算用項目初期化
          ln_ktn_arari_sum    := 0;          -- 粗利
          ln_ktn_s_am_sum     := 0;          -- 売上高
          ln_ktn_nuit_sum     := 0;          -- 本数
          ln_ktn_price_sum    := 0;          -- 品目定価
-- 2009/04/20 v1.8 UPDATE START
--          ln_ktn_to_am_sum    := 0;          -- 内訳合計
          ln_ktn_s_unit_price_sum := 0;      -- 標準原価
          ln_ktn_ara_sum          := 0;      -- 粗利(集計用)
          ln_ktn_chk_0_sum        := 0;      -- 掛率(集計用)
-- 2009/04/20 v1.8 UPDATE END
          ln_ktn_quant_sum    := 0;          -- 数量
          -- 商品区分計集計用項目初期化
          ln_skbn_arari_sum   := 0;          -- 粗利
          ln_skbn_s_am_sum    := 0;          -- 売上高
          ln_skbn_nuit_sum    := 0;          -- 本数
          ln_skbn_price_sum   := 0;          -- 品目定価
-- 2009/04/20 v1.8 UPDATE START
--          ln_skbn_to_am_sum   := 0;          -- 内訳合計
          ln_skbn_s_unit_price_sum := 0;     -- 標準原価
          ln_skbn_ara_sum          := 0;     -- 粗利(集計用)
          ln_skbn_chk_0_sum        := 0;     -- 掛率(集計用)
-- 2009/04/20 v1.8 UPDATE END
          ln_skbn_quant_sum   := 0;          -- 数量
        END IF;
--
        -- ====================================================
        --  拠点ブレイク
        -- ====================================================
        -- 拠点が切り替わったとき
        IF (gr_sale_plan_1(i).ktn_code <> lv_ktn_break) THEN
          -- -----------------------------------------------------
          --  品目終了ＬＧタグ出力
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_dtl_info';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
          ----------------------------------------------------------------
          -- 細群計(標準原価)データ
          ----------------------------------------------------------------
          -- 標準原価算出
-- 2009/04/20 v1.8 UPDATE START
--          ln_syo_s_unit_price := ln_to_am_sum * ln_quant_sum;
          ln_syo_s_unit_price := ln_s_unit_price_sum;
-- 2009/04/20 v1.8 UPDATE END
--
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'syo_s_unit_price';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          gt_xml_data_table(gl_xml_idx).tag_value := ln_syo_s_unit_price;
--
          ----------------------------------------------------------------
          -- 細群計(粗利)データ
          ----------------------------------------------------------------
          -- 粗利算出
-- 2009/04/20 v1.8 UPDATE START
--          ln_arari_sum := ln_s_am_sum - ln_syo_s_unit_price;
          ln_arari_sum := ln_ara_sum;
-- 2009/04/20 v1.8 UPDATE END
--
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'syo_arari';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          gt_xml_data_table(gl_xml_idx).tag_value := ln_arari_sum;
--
          ----------------------------------------------------------------
          -- 細群計(粗利率)データ  ((粗利/売上高)*100)
          ----------------------------------------------------------------
          -- ０除算回避判定
          IF (ln_s_am_sum <> 0) THEN
            -- 値が[0]出なければ計算
            ln_syo_arari_par := ROUND((ln_arari_sum / ln_s_am_sum) * 100,2);
          ELSE
            -- 値が[0]の場合は、一律[0]設定
            ln_syo_arari_par := gn_0;
          END IF;
--
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'syo_arari_par';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          gt_xml_data_table(gl_xml_idx).tag_value := ln_syo_arari_par;
--
          ----------------------------------------------------------------
          -- 細群計(掛率)データ  ((売上高*100)/(品目定価*本数))
          ----------------------------------------------------------------
-- 2009/04/20 v1.8 UPDATE START
/*
          -- ０除算判定項目へ判定値を挿入
          ln_chk_0 := ln_price_sum * ln_nuit_sum;
          -- ０除算回避判定
          IF (ln_chk_0 <> 0) THEN
            -- 値が[0]出なければ計算
            ln_syo_kake_par := ROUND((ln_s_am_sum * 100) / ln_chk_0,2);
          ELSE
            -- 値が[0]の場合は、一律[0]設定
            ln_syo_kake_par := gn_0;
          END IF;
*/
          -- ０除算回避判定
          IF (ln_chk_0_sum <> 0) THEN
            -- 値が[0]出なければ計算
            ln_syo_kake_par := ROUND((ln_s_am_sum * 100) / ln_chk_0_sum, 2);
          ELSE
            -- 値が[0]の場合は、一律[0]設定
            ln_syo_kake_par := gn_0;
          END IF;
-- 2009/04/20 v1.8 UPDATE END
--
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'syo_kake_par';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          -- 品目定価 = ０か、計算結果がマイナスの場合、固定値を登録
          IF (ln_price_sum = 0) 
            OR (ln_syo_kake_par < 0)THEN
            gt_xml_data_table(gl_xml_idx).tag_value := TO_NUMBER(gv_name_kotei); -- 固定値:70.00
          -- 品目定価 <> ０、計算結果がマイナスではない場合、計算結果を登録
          ELSE
            gt_xml_data_table(gl_xml_idx).tag_value := ln_syo_kake_par;
          END IF;
--
          ----------------------------------------------------------------
          -- 小群計(数量)データ
          ----------------------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'sttl_quant';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          gt_xml_data_table(gl_xml_idx).tag_value := ln_st_quant_sum;
--
          ----------------------------------------------------------------
          -- 小群計(売上高)データ
          ----------------------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'sttl_sales_amount';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          gt_xml_data_table(gl_xml_idx).tag_value := ln_st_s_am_sum;
--
          ----------------------------------------------------------------
          -- 小群計(標準原価)データ
          ----------------------------------------------------------------
          -- 標準原価算出
-- 2009/04/20 v1.8 UPDATE START
--          ln_sttl_s_unit_price := ln_st_s_u_price_sum * ln_st_quant_sum;
          ln_sttl_s_unit_price := ln_st_s_unit_price_sum;
-- 2009/04/20 v1.8 UPDATE END
--
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'sttl_s_unit_price';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          gt_xml_data_table(gl_xml_idx).tag_value := ln_sttl_s_unit_price;
--
          ----------------------------------------------------------------
          -- 小群計(粗利)データ
          ----------------------------------------------------------------
          -- 粗利算出
-- 2009/04/20 v1.8 UPDATE START
--          ln_st_arari_sum := ln_s_am_sum - ln_syo_s_unit_price;
          ln_st_arari_sum := ln_st_ara_sum;
-- 2009/04/20 v1.8 UPDATE END
--
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'sttl_arari';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          gt_xml_data_table(gl_xml_idx).tag_value := ln_st_arari_sum;
--
          ----------------------------------------------------------------
          -- 小群計(粗利率)データ  ((粗利/売上高)*100)
          ----------------------------------------------------------------
          -- ０除算回避判定
          IF (ln_st_s_am_sum <> 0) THEN
            -- 値が[0]出なければ計算
            ln_sttl_arari_par := ROUND((ln_st_arari_sum / ln_st_s_am_sum) * 100,2);
          ELSE
            -- 値が[0]の場合は、一律[0]設定
            ln_sttl_arari_par := gn_0;
          END IF;
--
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'sttl_arari_par';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          gt_xml_data_table(gl_xml_idx).tag_value := ln_sttl_arari_par;
--
          ----------------------------------------------------------------
          -- 小群計(掛率)データ  ((売上高*100)/(品目定価*本数))
          ----------------------------------------------------------------
-- 2009/04/20 v1.8 UPDATE START
/*
          -- ０除算判定項目へ判定値を挿入
          ln_chk_0 := ln_st_price_sum * ln_st_nuit_sum;
          -- ０除算回避判定
          IF (ln_chk_0 <> 0) THEN
            -- 値が[0]出なければ計算
            ln_sttl_kake_par := ROUND((ln_st_s_am_sum * 100) / ln_chk_0,2);
          ELSE
            -- 値が[0]の場合は、一律[0]設定
            ln_sttl_kake_par := gn_0;
          END IF;
*/
          -- ０除算回避判定
          IF (ln_st_chk_0_sum <> 0) THEN
            -- 値が[0]出なければ計算
            ln_sttl_kake_par := ROUND((ln_st_s_am_sum * 100) / ln_st_chk_0_sum, 2);
          ELSE
            -- 値が[0]の場合は、一律[0]設定
            ln_sttl_kake_par := gn_0;
          END IF;
-- 2009/04/20 v1.8 UPDATE END
--
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'sttl_kake_par';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          -- 品目定価 = ０か、計算結果がマイナスの場合、固定値を登録
          IF (ln_st_price_sum = 0)
            OR (ln_sttl_kake_par < 0) THEN
            gt_xml_data_table(gl_xml_idx).tag_value := TO_NUMBER(gv_name_kotei); -- 固定値:70.00
            -- 品目定価 <> ０、計算結果がマイナスではない場合、計算結果を登録
          ELSE
            gt_xml_data_table(gl_xml_idx).tag_value := ln_sttl_kake_par;
          END IF;
--
          ----------------------------------------------------------------
          -- 中群計(数量)データ
          ----------------------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'mttl_quant';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          gt_xml_data_table(gl_xml_idx).tag_value := ln_mt_quant_sum;
--
          ----------------------------------------------------------------
          -- 中群計(売上高)データ
          ----------------------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'mttl_sales_amount';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          gt_xml_data_table(gl_xml_idx).tag_value := ln_mt_s_am_sum;
--
          ----------------------------------------------------------------
          -- 中群計(標準原価)データ
          ----------------------------------------------------------------
          -- 標準原価算出
-- 2009/04/20 v1.8 UPDATE START
--          ln_mttl_s_unit_price := ln_mt_s_u_price_sum * ln_mt_quant_sum;
          ln_mttl_s_unit_price := ln_mt_s_unit_price_sum;
-- 2009/04/20 v1.8 UPDATE END
--
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'mttl_s_unit_price';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          gt_xml_data_table(gl_xml_idx).tag_value := ln_mttl_s_unit_price;
--
          ----------------------------------------------------------------
          -- 中群計(粗利)データ
          ----------------------------------------------------------------
          -- 粗利算出
-- 2009/04/20 v1.8 UPDATE START
--          ln_mt_arari_sum := ln_mt_s_am_sum - ln_mttl_s_unit_price;
          ln_mt_arari_sum := ln_mt_ara_sum;
-- 2009/04/20 v1.8 UPDATE END
--
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'mttl_arari';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          gt_xml_data_table(gl_xml_idx).tag_value := ln_mt_arari_sum;
--
          ----------------------------------------------------------------
          -- 中群計(粗利率)データ  ((粗利/売上高)*100)
          ----------------------------------------------------------------
          --  ０除算回避判定
          IF (ln_mt_s_am_sum <> 0) THEN
            -- 値が[0]出なければ計算
            ln_mttl_arari_par := ROUND((ln_mt_arari_sum / ln_mt_s_am_sum) * 100,2);
          ELSE
            -- 値が[0]の場合は、一律[0]設定
            ln_mttl_arari_par := gn_0;
          END IF;
--
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'mttl_arari_par';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          gt_xml_data_table(gl_xml_idx).tag_value := ln_mttl_arari_par;
--
          ----------------------------------------------------------------
          -- 中群計(掛率)データ  ((売上高*100)/(品目定価*本数))
          ----------------------------------------------------------------
-- 2009/04/20 v1.8 UPDATE START
/*
          -- ０除算判定項目へ判定値を挿入
          ln_chk_0 := ln_mt_price_sum * ln_mt_nuit_sum;
          -- ０除算回避判定
          IF (ln_chk_0 <> 0) THEN
            -- 値が[0]出なければ計算
            ln_mttl_kake_par := ROUND((ln_mt_s_am_sum * 100) / ln_chk_0,2);
          ELSE
            -- 値が[0]の場合は、一律[0]設定
            ln_mttl_kake_par := gn_0;
          END IF;
*/
          -- ０除算回避判定
          IF (ln_mt_chk_0_sum <> 0) THEN
            -- 値が[0]出なければ計算
            ln_mttl_kake_par := ROUND((ln_mt_s_am_sum * 100) / ln_mt_chk_0_sum, 2);
          ELSE
            -- 値が[0]の場合は、一律[0]設定
            ln_mttl_kake_par := gn_0;
          END IF;
-- 2009/04/20 v1.8 UPDATE END
--
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'mttl_kake_par';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          -- 品目定価 = ０か、計算結果がマイナスの場合、固定値を登録
          IF (ln_mt_price_sum = 0)
            OR (ln_mttl_kake_par < 0) THEN
            gt_xml_data_table(gl_xml_idx).tag_value := TO_NUMBER(gv_name_kotei); -- 固定値:70.00
          -- 品目定価 <> ０、計算結果がマイナスではない場合、計算結果を登録
          ELSE
            gt_xml_data_table(gl_xml_idx).tag_value := ln_mttl_kake_par;
          END IF;
--
          ----------------------------------------------------------------
          -- 大群計(数量)データ
          ----------------------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'lttl_quant';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          gt_xml_data_table(gl_xml_idx).tag_value := ln_lt_quant_sum;
--
          ----------------------------------------------------------------
          -- 大群計(売上高)データ
          ----------------------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'lttl_sales_amount';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          gt_xml_data_table(gl_xml_idx).tag_value := ln_lt_s_am_sum;
--
          ----------------------------------------------------------------
          -- 大群計(標準原価)データ
          ----------------------------------------------------------------
          -- 標準原価算出
-- 2009/04/20 v1.8 UPDATE START
--          ln_lttl_s_unit_price := ln_lt_s_u_price_sum * ln_lt_quant_sum;
          ln_lttl_s_unit_price := ln_lt_s_unit_price_sum;
-- 2009/04/20 v1.8 UPDATE END
--
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'lttl_s_unit_price';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
-- 2009/04/20 v1.8 UPDATE START
--          gt_xml_data_table(gl_xml_idx).tag_value := ln_lt_s_u_price_sum;
          gt_xml_data_table(gl_xml_idx).tag_value := ln_lttl_s_unit_price;
-- 2009/04/20 v1.8 UPDATE END
--
          ----------------------------------------------------------------
          -- 大群計(粗利)データ
          ----------------------------------------------------------------
          -- 粗利算出
-- 2009/04/20 v1.8 UPDATE START
--          ln_lt_arari_sum := ln_lt_s_am_sum - ln_lttl_s_unit_price;
          ln_lt_arari_sum := ln_lt_ara_sum;
-- 2009/04/20 v1.8 UPDATE END
--
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'lttl_arari';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          gt_xml_data_table(gl_xml_idx).tag_value := ln_lt_arari_sum;
--
          ----------------------------------------------------------------
          -- 大群計(粗利率)データ  ((粗利/売上高)*100)
          ----------------------------------------------------------------
          -- ０除算回避判定
          IF (ln_lt_s_am_sum <> 0) THEN
            -- 値が[0]出なければ計算
            ln_lttl_arari_par := ROUND((ln_lt_arari_sum / ln_lt_s_am_sum) * 100,2);
          ELSE
            -- 値が[0]の場合は、一律[0]設定
            ln_lttl_arari_par := gn_0;
          END IF;
--
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'lttl_arari_par';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          gt_xml_data_table(gl_xml_idx).tag_value := ln_lttl_arari_par;
--
          ----------------------------------------------------------------
          -- 大群計(掛率)データ  ((売上高*100)/(品目定価*本数))
          ----------------------------------------------------------------
-- 2009/04/20 v1.8 UPDATE START
/*
          -- ０除算判定項目へ判定値を挿入
          ln_chk_0 := ln_lt_price_sum * ln_lt_nuit_sum;
          -- ０除算回避判定
          IF (ln_chk_0 <> 0) THEN
            -- 値が[0]出なければ計算
            ln_lttl_kake_par := ROUND((ln_lt_s_am_sum * 100) / ln_chk_0,2);
          ELSE
            -- 値が[0]の場合は、一律[0]設定
            ln_lttl_kake_par := gn_0;
          END IF;
*/
          -- ０除算回避判定
          IF (ln_lt_chk_0_sum <> 0) THEN
            -- 値が[0]出なければ計算
            ln_lttl_kake_par := ROUND((ln_lt_s_am_sum * 100) / ln_lt_chk_0_sum, 2);
          ELSE
            -- 値が[0]の場合は、一律[0]設定
            ln_lttl_kake_par := gn_0;
          END IF;
-- 2009/04/20 v1.8 UPDATE END
--
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'lttl_kake_par';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          -- 品目定価 = ０か、計算結果がマイナスの場合、固定値を登録
          IF (ln_lt_price_sum = 0)
            OR (ln_lttl_kake_par < 0) THEN
            gt_xml_data_table(gl_xml_idx).tag_value := TO_NUMBER(gv_name_kotei); -- 固定値:70.00
          -- 品目定価 <> ０、計算結果がマイナスではない場合、計算結果を登録
          ELSE
            gt_xml_data_table(gl_xml_idx).tag_value := ln_lttl_kake_par;
          END IF;
--
          -- -----------------------------------------------------
          --  群コード終了Ｇタグ出力
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_gun';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
          -- -----------------------------------------------------
          --  群コード終了LＧタグ出力
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_gun_info';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
          ----------------------------------------------------------------
          -- 拠点計(標準原価)データ
          ----------------------------------------------------------------
          -- 標準原価算出
-- 2009/04/20 v1.8 UPDATE START
--          ln_ktn_s_unit_price := ln_ktn_to_am_sum * ln_ktn_quant_sum;
          ln_ktn_s_unit_price := ln_ktn_s_unit_price_sum;
-- 2009/04/20 v1.8 UPDATE END
--
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'ktn_s_unit_price';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          gt_xml_data_table(gl_xml_idx).tag_value := ln_ktn_s_unit_price;
--
          ----------------------------------------------------------------
          -- 拠点計(粗利)データ
          ----------------------------------------------------------------
          -- 粗利算出
-- 2009/04/20 v1.8 UPDATE START
--          ln_ktn_arari_sum := ln_ktn_s_am_sum - ln_ktn_s_unit_price;
          ln_ktn_arari_sum := ln_ktn_ara_sum;
-- 2009/04/20 v1.8 UPDATE END
--
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'ktn_arari';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          gt_xml_data_table(gl_xml_idx).tag_value := ln_ktn_arari_sum;
--
          ----------------------------------------------------------------
          -- 拠点計(粗利率)データ  ((粗利/売上高)*100)
          ----------------------------------------------------------------
          -- ０除算回避判定
          IF (ln_ktn_s_am_sum <> 0) THEN
            -- 値が[0]出なければ計算
            ln_ktn_arari_par := ROUND((ln_ktn_arari_sum / ln_ktn_s_am_sum) * 100,2);
          ELSE
            -- 値が[0]の場合は、一律[0]設定
            ln_ktn_arari_par := gn_0;
          END IF;
--
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'ktn_arari_par';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          gt_xml_data_table(gl_xml_idx).tag_value := ln_ktn_arari_par;
--
          ----------------------------------------------------------------
          -- 拠点計(掛率)データ  ((売上高*100)/(品目定価*本数))
          ----------------------------------------------------------------
-- 2009/04/20 v1.8 UPDATE START
/*
          -- ０除算判定項目へ判定値を挿入
          ln_chk_0 := ln_ktn_price_sum * ln_ktn_nuit_sum;
          -- ０除算回避判定
          IF (ln_chk_0 <> 0) THEN
            -- 値が[0]出なければ計算
            ln_ktn_kake_par := ROUND((ln_ktn_s_am_sum * 100) / ln_chk_0,2);
          ELSE
            -- 値が[0]の場合は、一律[0]設定
            ln_ktn_kake_par := gn_0;
          END IF;
*/
          -- ０除算回避判定
          IF (ln_ktn_chk_0_sum <> 0) THEN
            -- 値が[0]出なければ計算
            ln_ktn_kake_par := ROUND((ln_ktn_s_am_sum * 100) / ln_ktn_chk_0_sum, 2);
          ELSE
            -- 値が[0]の場合は、一律[0]設定
            ln_ktn_kake_par := gn_0;
          END IF;
-- 2009/04/20 v1.8 UPDATE END
--
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'ktn_kake_par';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          -- 品目定価 = ０か、計算結果がマイナスの場合、固定値を登録
          IF (ln_ktn_price_sum = 0)
            OR (ln_ktn_kake_par < 0) THEN
            gt_xml_data_table(gl_xml_idx).tag_value := TO_NUMBER(gv_name_kotei); -- 固定値:70.00
          -- 品目定価 <> ０、計算結果がマイナスではない場合、計算結果を登録
          ELSE
            gt_xml_data_table(gl_xml_idx).tag_value := ln_ktn_kake_par;
          END IF;
--
          -- -----------------------------------------------------
          --  拠点終了Ｇタグ出力
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_ktn';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
          -- -----------------------------------------------------
          --  拠点開始Ｇタグ出力
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'g_ktn';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
          ----------------------------------------------------------------
          -- 拠点区分(拠点コード) タグ
          ----------------------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'ktn_code';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          gt_xml_data_table(gl_xml_idx).tag_value := gr_sale_plan_1(i).ktn_code;
--
          ----------------------------------------------------------------
          -- 拠点区分(拠点略称) タグ
          ----------------------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'ktn_name';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          gt_xml_data_table(gl_xml_idx).tag_value := gr_sale_plan_1(i).party_short_name;
--
          -- -----------------------------------------------------
          --  群コード開始LＧタグ出力
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_gun_info';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
          -- -----------------------------------------------------
          --  群コード開始Ｇタグ出力
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'g_gun';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
          -- -----------------------------------------------------
          --  品目開始ＬＧタグ出力
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_dtl_info';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
          -- 各ブレイクキー更新
          lv_ktn_break  := gr_sale_plan_1(i).ktn_code;           -- 拠点
          lv_gun_break  := gr_sale_plan_1(i).gun;                -- 群コード
          lv_sttl_break := SUBSTRB(gr_sale_plan_1(i).gun,1,3);   -- 小群計
          lv_mttl_break := SUBSTRB(gr_sale_plan_1(i).gun,1,2);   -- 中群計
          lv_lttl_break := SUBSTRB(gr_sale_plan_1(i).gun,1,1);   -- 大群計
--
          -- 細群計集計用項目初期化
          ln_nuit_sum         := 0;          -- 本数
          ln_price_sum        := 0;          -- 品目定価
          ln_arari_sum        := 0;          -- 粗利
          ln_s_am_sum         := 0;          -- 売上高
-- 2009/04/20 v1.8 UPDATE START
--          ln_to_am_sum        := 0;          -- 内訳合計
          ln_s_unit_price_sum := 0;          -- 標準原価
          ln_ara_sum          := 0;          -- 粗利(集計用)
          ln_chk_0_sum        := 0;          -- 掛率(集計用)
-- 2009/04/20 v1.8 UPDATE END
          ln_quant_sum        := 0;          -- 数量
          -- 小群計集計用項目初期化
          ln_st_quant_sum     := 0;          -- 数量
-- 2009/04/20 v1.8 UPDATE START
--          ln_st_s_u_price_sum := 0;          -- 内訳合計
          ln_st_s_unit_price_sum := 0;       -- 標準原価
          ln_st_ara_sum          := 0;       -- 粗利(集計用)
          ln_st_chk_0_sum        := 0;       -- 掛率(集計用)
-- 2009/04/20 v1.8 UPDATE END
          ln_st_arari_sum     := 0;          -- 粗利
          ln_st_s_am_sum      := 0;          -- 売上高
          ln_st_nuit_sum      := 0;          -- 本数
          ln_st_price_sum     := 0;          -- 品目定価
          -- 中群計集計用項目初期化
          ln_mt_quant_sum     := 0;          -- 数量
-- 2009/04/20 v1.8 UPDATE START
--          ln_mt_s_u_price_sum := 0;          -- 内訳合計
          ln_mt_s_unit_price_sum := 0;       -- 標準原価
          ln_mt_ara_sum          := 0;       -- 粗利(集計用)
          ln_mt_chk_0_sum        := 0;       -- 掛率(集計用)
-- 2009/04/20 v1.8 UPDATE END
          ln_mt_arari_sum     := 0;          -- 粗利
          ln_mt_s_am_sum      := 0;          -- 売上高
          ln_mt_nuit_sum      := 0;          -- 本数
          ln_mt_price_sum     := 0;          -- 品目定価
          -- 大群計集計用項目初期化
          ln_lt_quant_sum     := 0;          -- 数量
-- 2009/04/20 v1.8 UPDATE START
--          ln_lt_s_u_price_sum := 0;          -- 内訳合計
          ln_lt_s_unit_price_sum := 0;       -- 標準原価
          ln_lt_ara_sum          := 0;       -- 粗利(集計用)
          ln_lt_chk_0_sum        := 0;       -- 掛率(集計用)
-- 2009/04/20 v1.8 UPDATE END
          ln_lt_arari_sum     := 0;          -- 粗利
          ln_lt_s_am_sum      := 0;          -- 売上高
          ln_lt_nuit_sum      := 0;          -- 本数
          ln_lt_price_sum     := 0;          -- 品目定価
          -- 拠点計計算用項目初期化
          ln_ktn_arari_sum    := 0;          -- 粗利
          ln_ktn_s_am_sum     := 0;          -- 売上高
          ln_ktn_nuit_sum     := 0;          -- 本数
          ln_ktn_price_sum    := 0;          -- 品目定価
-- 2009/04/20 v1.8 UPDATE START
--          ln_ktn_to_am_sum    := 0;          -- 内訳合計
          ln_ktn_s_unit_price_sum := 0;      -- 標準原価
          ln_ktn_ara_sum          := 0;      -- 粗利(集計用)
          ln_ktn_chk_0_sum        := 0;      -- 掛率(集計用)
-- 2009/04/20 v1.8 UPDATE END
          ln_ktn_quant_sum    := 0;          -- 数量
        END IF;
--
        -- ====================================================
        --  群コードブレイク
        -- ====================================================
        -- 群コードが切り替わったとき
        IF (gr_sale_plan_1(i).gun <> lv_gun_break) THEN
          -- -----------------------------------------------------
          --  品目終了ＬＧタグ出力
          -- ----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_dtl_info';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
          ----------------------------------------------------------------
          -- 細群計(標準原価)データ
          ----------------------------------------------------------------
          -- 標準原価算出
-- 2009/04/20 v1.8 UPDATE START
--          ln_syo_s_unit_price := ln_to_am_sum * ln_quant_sum;
          ln_syo_s_unit_price := ln_s_unit_price_sum;
-- 2009/04/20 v1.8 UPDATE END
--
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'syo_s_unit_price';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          gt_xml_data_table(gl_xml_idx).tag_value := ln_syo_s_unit_price;
--
          ----------------------------------------------------------------
          -- 細群計(粗利)データ
          ----------------------------------------------------------------
          -- 粗利算出
-- 2009/04/20 v1.8 UPDATE START
--          ln_arari_sum := ln_s_am_sum - ln_syo_s_unit_price;
          ln_arari_sum := ln_ara_sum;
-- 2009/04/20 v1.8 UPDATE END
--
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'syo_arari';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          gt_xml_data_table(gl_xml_idx).tag_value := ln_arari_sum;
--
          ----------------------------------------------------------------
          -- 細群計(粗利率)データ  ((粗利/売上高)*100)
          ----------------------------------------------------------------
          -- ０除算回避判定
          IF (ln_s_am_sum <> 0) THEN
            -- 値が[0]出なければ計算
            ln_syo_arari_par := ROUND((ln_arari_sum / ln_s_am_sum) * 100,2);
          ELSE
            -- 値が[0]の場合は、一律[0]設定
            ln_syo_arari_par := gn_0;
          END IF;
--
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'syo_arari_par';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          gt_xml_data_table(gl_xml_idx).tag_value := ln_syo_arari_par;
--
          ----------------------------------------------------------------
          -- 細群計(掛率)データ  ((売上高*100)/(品目定価*本数))
          ----------------------------------------------------------------
-- 2009/04/20 v1.8 UPDATE START
/*
          -- ０除算判定項目へ判定値を挿入
          ln_chk_0 := ln_price_sum * ln_nuit_sum;
          -- ０除算回避判定
          IF (ln_chk_0 <> 0) THEN
            -- 値が[0]出なければ計算
            ln_syo_kake_par := ROUND((ln_s_am_sum * 100) / ln_chk_0,2);
          ELSE
            -- 値が[0]の場合は、一律[0]設定
            ln_syo_kake_par := gn_0;
          END IF;
*/
          -- ０除算回避判定
          IF (ln_chk_0_sum <> 0) THEN
            -- 値が[0]出なければ計算
            ln_syo_kake_par := ROUND((ln_s_am_sum * 100) / ln_chk_0_sum, 2);
          ELSE
            -- 値が[0]の場合は、一律[0]設定
            ln_syo_kake_par := gn_0;
          END IF;
-- 2009/04/20 v1.8 UPDATE END
--
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'syo_kake_par';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          -- 品目定価 = ０か、計算結果がマイナスの場合、固定値を登録
          IF (ln_price_sum = 0)
            OR (ln_syo_kake_par < 0) THEN
            gt_xml_data_table(gl_xml_idx).tag_value := TO_NUMBER(gv_name_kotei); -- 固定値:70.00
          -- 品目定価 <> ０、計算結果がマイナスではない場合、計算結果を登録
          ELSE
            gt_xml_data_table(gl_xml_idx).tag_value := ln_syo_kake_par;
          END IF;
--
          -- ====================================================
          --  小群計ブレイク
          -- ====================================================
          IF (SUBSTRB(gr_sale_plan_1(i).gun,1,3) <> lv_sttl_break) THEN
            ----------------------------------------------------------------
            -- 小群計(数量)データ
            ----------------------------------------------------------------
            gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
            gt_xml_data_table(gl_xml_idx).tag_name  := 'sttl_quant';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
            gt_xml_data_table(gl_xml_idx).tag_value := ln_st_quant_sum;
--
            ----------------------------------------------------------------
            -- 小群計(売上高)データ
            ----------------------------------------------------------------
            gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
            gt_xml_data_table(gl_xml_idx).tag_name  := 'sttl_sales_amount';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
            gt_xml_data_table(gl_xml_idx).tag_value := ln_st_s_am_sum;
--
            ----------------------------------------------------------------
            -- 小群計(標準原価)データ
            ----------------------------------------------------------------
            -- 標準原価算出
-- 2009/04/20 v1.8 UPDATE START
--            ln_sttl_s_unit_price := ln_st_s_u_price_sum * ln_st_quant_sum;
            ln_sttl_s_unit_price := ln_st_s_unit_price_sum;
-- 2009/04/20 v1.8 UPDATE END
--
            gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
            gt_xml_data_table(gl_xml_idx).tag_name  := 'sttl_s_unit_price';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
            gt_xml_data_table(gl_xml_idx).tag_value := ln_sttl_s_unit_price;
--
            ----------------------------------------------------------------
            -- 小群計(粗利)データ
            ----------------------------------------------------------------
            -- 粗利算出
-- 2009/04/20 v1.8 UPDATE START
--            ln_st_arari_sum := ln_s_am_sum - ln_syo_s_unit_price;
            ln_st_arari_sum := ln_st_ara_sum;
-- 2009/04/20 v1.8 UPDATE END
--
            gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
            gt_xml_data_table(gl_xml_idx).tag_name  := 'sttl_arari';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
            gt_xml_data_table(gl_xml_idx).tag_value := ln_st_arari_sum;
--
            ----------------------------------------------------------------
            -- 小群計(粗利率)データ  ((粗利/売上高)*100)
            ----------------------------------------------------------------
            -- ０除算回避判定
            IF (ln_st_s_am_sum <> 0) THEN
              -- 値が[0]出なければ計算
              ln_sttl_arari_par := ROUND((ln_st_arari_sum / ln_st_s_am_sum) * 100,2);
            ELSE
              -- 値が[0]の場合は、一律[0]設定
              ln_sttl_arari_par := gn_0;
            END IF;
--
            gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
            gt_xml_data_table(gl_xml_idx).tag_name  := 'sttl_arari_par';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
            gt_xml_data_table(gl_xml_idx).tag_value := ln_sttl_arari_par;
--
            ----------------------------------------------------------------
            -- 小群計(掛率)データ  ((売上高*100)/(品目定価*本数))
            ----------------------------------------------------------------
-- 2009/04/20 v1.8 UPDATE START
/*
            -- ０除算判定項目へ判定値を挿入
            ln_chk_0 := ln_st_price_sum * ln_st_nuit_sum;
            -- ０除算回避判定
            IF (ln_chk_0 <> 0) THEN
              -- 値が[0]出なければ計算
              ln_sttl_kake_par := ROUND((ln_st_s_am_sum * 100) / (ln_chk_0),2);
            ELSE
              -- 値が[0]の場合は、一律[0]設定
              ln_sttl_kake_par := gn_0;
            END IF;
*/
            -- ０除算回避判定
            IF (ln_st_chk_0_sum <> 0) THEN
              -- 値が[0]出なければ計算
              ln_sttl_kake_par := ROUND((ln_st_s_am_sum * 100) / ln_st_chk_0_sum, 2);
            ELSE
              -- 値が[0]の場合は、一律[0]設定
              ln_sttl_kake_par := gn_0;
            END IF;
-- 2009/04/20 v1.8 UPDATE END
--
            gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
            gt_xml_data_table(gl_xml_idx).tag_name  := 'sttl_kake_par';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
            -- 品目定価 = ０か、計算結果がマイナスの場合、固定値を登録
            IF (ln_st_price_sum = 0)
              OR (ln_sttl_kake_par < 0) THEN
              gt_xml_data_table(gl_xml_idx).tag_value := TO_NUMBER(gv_name_kotei); -- 固定値:70.00
            -- 品目定価 <> ０、計算結果がマイナスではない場合、計算結果を登録
            ELSE
              gt_xml_data_table(gl_xml_idx).tag_value := ln_sttl_kake_par;
            END IF;
--
            --  小群計ブレイクキー更新
            lv_sttl_break := SUBSTRB(gr_sale_plan_1(i).gun,1,3);
--
            -- 小群計集計用項目初期化
            ln_st_quant_sum     := 0;          -- 数量
-- 2009/04/20 v1.8 UPDATE START
--            ln_st_s_u_price_sum := 0;          -- 内訳合計
            ln_st_s_unit_price_sum := 0;       -- 標準原価
            ln_st_ara_sum          := 0;       -- 粗利(集計用)
            ln_st_chk_0_sum        := 0;       -- 掛率(集計用)
-- 2009/04/20 v1.8 UPDATE END
            ln_st_arari_sum     := 0;          -- 粗利
            ln_st_s_am_sum      := 0;          -- 売上高
            ln_st_nuit_sum      := 0;          -- 本数
            ln_st_price_sum     := 0;          -- 品目定価
          END IF;
--
          -- ====================================================
          --  中群計ブレイク
          -- ====================================================
          IF (SUBSTRB(gr_sale_plan_1(i).gun,1,2) <> lv_mttl_break) THEN
            ----------------------------------------------------------------
            -- 中群計(数量)データ
            ----------------------------------------------------------------
            gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
            gt_xml_data_table(gl_xml_idx).tag_name  := 'mttl_quant';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
            gt_xml_data_table(gl_xml_idx).tag_value := ln_mt_quant_sum;
--
            ----------------------------------------------------------------
            -- 中群計(売上高)データ
            ----------------------------------------------------------------
            gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
            gt_xml_data_table(gl_xml_idx).tag_name  := 'mttl_sales_amount';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
            gt_xml_data_table(gl_xml_idx).tag_value := ln_mt_s_am_sum;
--
            ----------------------------------------------------------------
            -- 中群計(標準原価)データ
            ----------------------------------------------------------------
            -- 標準原価算出
-- 2009/04/20 v1.8 UPDATE START
--            ln_mttl_s_unit_price := ln_mt_s_u_price_sum * ln_mt_quant_sum;
            ln_mttl_s_unit_price := ln_mt_s_unit_price_sum;
-- 2009/04/20 v1.8 UPDATE END
--
            gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
            gt_xml_data_table(gl_xml_idx).tag_name  := 'mttl_s_unit_price';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
            gt_xml_data_table(gl_xml_idx).tag_value := ln_mttl_s_unit_price;
--
            ----------------------------------------------------------------
            -- 中群計(粗利)データ
            ----------------------------------------------------------------
            -- 粗利算出
-- 2009/04/20 v1.8 UPDATE START
--            ln_mt_arari_sum := ln_mt_s_am_sum - ln_mttl_s_unit_price;
            ln_mt_arari_sum := ln_mt_ara_sum;
-- 2009/04/20 v1.8 UPDATE END
--
            gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
            gt_xml_data_table(gl_xml_idx).tag_name  := 'mttl_arari';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
            gt_xml_data_table(gl_xml_idx).tag_value := ln_mt_arari_sum;
--
            ----------------------------------------------------------------
            -- 中群計(粗利率)データ  ((粗利/売上高)*100)
            ----------------------------------------------------------------
            -- ０除算回避判定
            IF (ln_mt_s_am_sum <> 0) THEN
              -- 値が[0]出なければ計算
              ln_mttl_arari_par := ROUND((ln_mt_arari_sum / ln_mt_s_am_sum) * 100,2);
            ELSE
              -- 値が[0]の場合は、一律[0]設定
              ln_mttl_arari_par := gn_0;
            END IF;
--
            gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
            gt_xml_data_table(gl_xml_idx).tag_name  := 'mttl_arari_par';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
            gt_xml_data_table(gl_xml_idx).tag_value := ln_mttl_arari_par;
--
            ----------------------------------------------------------------
            -- 中群計(掛率)データ  ((売上高*100)/(品目定価*本数))
            ----------------------------------------------------------------
-- 2009/04/20 v1.8 UPDATE START
/*
            -- ０除算判定項目へ判定値を挿入
            ln_chk_0 := ln_mt_price_sum * ln_mt_nuit_sum;
            -- ０除算回避判定
            IF (ln_chk_0 <> 0) THEN
              -- 値が[0]出なければ計算
              ln_mttl_kake_par := ROUND((ln_mt_s_am_sum * 100) / ln_chk_0,2);
            ELSE
              -- 値が[0]の場合は、一律[0]設定
              ln_mttl_kake_par := gn_0;
            END IF;
*/
            -- ０除算回避判定
            IF (ln_mt_chk_0_sum <> 0) THEN
              -- 値が[0]出なければ計算
              ln_mttl_kake_par := ROUND((ln_mt_s_am_sum * 100) / ln_mt_chk_0_sum, 2);
            ELSE
              -- 値が[0]の場合は、一律[0]設定
              ln_mttl_kake_par := gn_0;
            END IF;
-- 2009/04/20 v1.8 UPDATE END
--
            gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
            gt_xml_data_table(gl_xml_idx).tag_name  := 'mttl_kake_par';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
            -- 品目定価 = ０か、計算結果がマイナスの場合、固定値を登録
            IF (ln_mt_price_sum = 0)
              OR (ln_mttl_kake_par < 0) THEN
              gt_xml_data_table(gl_xml_idx).tag_value := TO_NUMBER(gv_name_kotei); -- 固定値:70.00
            -- 品目定価 <> ０、計算結果がマイナスではない場合、計算結果を登録
            ELSE
              gt_xml_data_table(gl_xml_idx).tag_value := ln_mttl_kake_par;
            END IF;
--
            --  中群計ブレイクキー更新
            lv_mttl_break := SUBSTRB(gr_sale_plan_1(i).gun,1,2);
--
            -- 中群計集計用項目初期化
            ln_mt_quant_sum     := 0;              -- 数量
-- 2009/04/20 v1.8 UPDATE START
--            ln_mt_s_u_price_sum := 0;              -- 内訳合計
            ln_mt_s_unit_price_sum := 0;           -- 標準原価
            ln_mt_ara_sum          := 0;           -- 粗利(集計用)
            ln_mt_chk_0_sum        := 0;           -- 掛率(集計用)
-- 2009/04/20 v1.8 UPDATE END
            ln_mt_arari_sum     := 0;              -- 粗利
            ln_mt_s_am_sum      := 0;              -- 売上高
            ln_mt_nuit_sum      := 0;              -- 本数
            ln_mt_price_sum     := 0;              -- 品目定価
          END IF;
--
          -- ====================================================
          --  大群計ブレイク
          -- ====================================================
          IF (SUBSTRB(gr_sale_plan_1(i).gun,1,1) <> lv_lttl_break) THEN
            ----------------------------------------------------------------
            -- 大群計(数量)データ
            ----------------------------------------------------------------
            gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
            gt_xml_data_table(gl_xml_idx).tag_name  := 'lttl_quant';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
            gt_xml_data_table(gl_xml_idx).tag_value := ln_lt_quant_sum;
--
            ----------------------------------------------------------------
            -- 大群計(売上高)データ
            ----------------------------------------------------------------
            gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
            gt_xml_data_table(gl_xml_idx).tag_name  := 'lttl_sales_amount';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
            gt_xml_data_table(gl_xml_idx).tag_value := ln_lt_s_am_sum;
--
            ----------------------------------------------------------------
            -- 大群計(標準原価)データ
            ----------------------------------------------------------------
            -- 標準原価算出
-- 2009/04/20 v1.8 UPDATE START
--            ln_lttl_s_unit_price := ln_lt_s_u_price_sum * ln_lt_quant_sum;
            ln_lttl_s_unit_price := ln_lt_s_unit_price_sum;
-- 2009/04/20 v1.8 UPDATE END
--
            gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
            gt_xml_data_table(gl_xml_idx).tag_name  := 'lttl_s_unit_price';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
            gt_xml_data_table(gl_xml_idx).tag_value := ln_lttl_s_unit_price;
--
            ----------------------------------------------------------------
            -- 大群計(粗利)データ
            ----------------------------------------------------------------
            -- 粗利算出
-- 2009/04/20 v1.8 UPDATE START
--            ln_lt_arari_sum := ln_lt_s_am_sum - ln_lttl_s_unit_price;
            ln_lt_arari_sum := ln_lt_ara_sum;
-- 2009/04/20 v1.8 UPDATE END
--
            gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
            gt_xml_data_table(gl_xml_idx).tag_name  := 'lttl_arari';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
            gt_xml_data_table(gl_xml_idx).tag_value := ln_lt_arari_sum;
--
            ----------------------------------------------------------------
            -- 大群計(粗利率)データ  ((粗利/売上高)*100)
            ----------------------------------------------------------------
            -- ０除算回避判定
            IF (ln_lt_s_am_sum <> 0) THEN
              -- 値が[0]出なければ計算
              ln_lttl_arari_par := ROUND((ln_lt_arari_sum / ln_lt_s_am_sum) * 100,2);
            ELSE
              -- 値が[0]の場合は、一律[0]設定
              ln_lttl_arari_par := gn_0;
            END IF;
--
            gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
            gt_xml_data_table(gl_xml_idx).tag_name  := 'lttl_arari_par';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
            gt_xml_data_table(gl_xml_idx).tag_value := ln_lttl_arari_par;
--
            ----------------------------------------------------------------
            -- 大群計(掛率)データ  ((売上高*100)/(品目定価*本数))
            ----------------------------------------------------------------
-- 2009/04/20 v1.8 UPDATE START
/*
            -- ０除算判定項目へ判定値を挿入
            ln_chk_0 := ln_lt_price_sum * ln_lt_nuit_sum;
            -- ０除算回避判定
            IF (ln_chk_0 <> 0) THEN
              -- 値が[0]出なければ計算
              ln_lttl_kake_par
                  := ROUND((ln_lt_s_am_sum * 100) / ln_chk_0,2);
            ELSE
              -- 値が[0]の場合は、一律[0]設定
              ln_lttl_kake_par := gn_0;
            END IF;
*/
            -- ０除算回避判定
            IF (ln_lt_chk_0_sum <> 0) THEN
              -- 値が[0]出なければ計算
              ln_lttl_kake_par := ROUND((ln_lt_s_am_sum * 100) / ln_lt_chk_0_sum, 2);
            ELSE
              -- 値が[0]の場合は、一律[0]設定
              ln_lttl_kake_par := gn_0;
            END IF;
-- 2009/04/20 v1.8 UPDATE END
--
            gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
            gt_xml_data_table(gl_xml_idx).tag_name  := 'lttl_kake_par';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
            -- 品目定価 = ０か、計算結果がマイナスの場合、固定値を登録
            IF (ln_lt_price_sum = 0)
              OR (ln_lttl_kake_par < 0) THEN
              gt_xml_data_table(gl_xml_idx).tag_value := TO_NUMBER(gv_name_kotei); -- 固定値:70.00
            -- 品目定価 <> ０、計算結果がマイナスではない場合、計算結果を登録
            ELSE
              gt_xml_data_table(gl_xml_idx).tag_value := ln_lttl_kake_par;
            END IF;
--
            --  大群計ブレイクキー更新
            lv_lttl_break := SUBSTRB(gr_sale_plan_1(i).gun,1,1);
--
            -- 大群計集計用項目初期化
            ln_lt_quant_sum     := 0;              -- 数量
-- 2009/04/20 v1.8 UPDATE START
--            ln_lt_s_u_price_sum := 0;              -- 内訳合計
            ln_lt_s_unit_price_sum := 0;           -- 標準原価
            ln_lt_ara_sum          := 0;           -- 粗利(集計用)
            ln_lt_chk_0_sum        := 0;           -- 掛率(集計用)
-- 2009/04/20 v1.8 UPDATE END
            ln_lt_arari_sum     := 0;              -- 粗利
            ln_lt_s_am_sum      := 0;              -- 売上高
            ln_lt_nuit_sum      := 0;              -- 本数
            ln_lt_price_sum     := 0;              -- 品目定価
          END IF;
--
          -- -----------------------------------------------------
          --  群コード終了Ｇタグ出力
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_gun';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
          -- -----------------------------------------------------
          --  群コード開始Ｇタグ出力
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'g_gun';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
          -- -----------------------------------------------------
          --  品目開始ＬＧタグ出力
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_dtl_info';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
          --  群コードブレイクキー更新
          lv_gun_break  := gr_sale_plan_1(i).gun;
--
          -- 細群計集計用項目初期化
          ln_nuit_sum   := 0;         -- 本数
          ln_price_sum  := 0;         -- 品目定価
          ln_arari_sum  := 0;         -- 粗利
          ln_s_am_sum   := 0;         -- 売上高
-- 2009/04/20 v1.8 UPDATE START
--          ln_to_am_sum  := 0;         -- 内訳合計
          ln_s_unit_price_sum := 0;   -- 標準原価
          ln_ara_sum          := 0;   -- 粗利(集計用)
          ln_chk_0_sum        := 0;   -- 掛率(集計用)
-- 2009/04/20 v1.8 UPDATE END
          ln_quant_sum  := 0;         -- 数量
        END IF;
--
        -- -----------------------------------------------------
        --  品目開始Ｇタグ出力
        -- -----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'g_dtl';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
        ----------------------------------------------------------------
        -- 群コードデータ
        ----------------------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'gun_code';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
        gt_xml_data_table(gl_xml_idx).tag_value := gr_sale_plan_1(i).gun;
--
        ----------------------------------------------------------------
        -- 品目(コード)データ
        ----------------------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'item_code';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
        gt_xml_data_table(gl_xml_idx).tag_value := gr_sale_plan_1(i).item_no;
--
        ----------------------------------------------------------------
        -- 品目(名称)データ
        ----------------------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'item_name';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
        gt_xml_data_table(gl_xml_idx).tag_value := gr_sale_plan_1(i).item_short_name;
--
        ----------------------------------------------------------------
        -- 入数データ
        ----------------------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'case_quant';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
        gt_xml_data_table(gl_xml_idx).tag_value := TO_NUMBER(gr_sale_plan_1(i).case_quant);
--
        ----------------------------------------------------------------
        -- 数量データ
        ----------------------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'quant';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
        -- 出力単位が「本数」の場合
        IF (gr_param.output_unit = gv_output_unit) THEN
          gt_xml_data_table(gl_xml_idx).tag_value := TO_NUMBER(gr_sale_plan_1(i).quant);
        -- 出力単位が「ケース」の場合
        ELSE
          -- ０除算回避判定
          IF (TO_NUMBER(gr_sale_plan_1(i).case_quant) <> 0) THEN
            -- 値が[0]出なければ、数量計算  (数量 / 入数)
            ln_output_unit 
                   := TO_NUMBER(gr_sale_plan_1(i).quant) / TO_NUMBER(gr_sale_plan_1(i).case_quant);
            ln_output_unit := CEIL(ln_output_unit);
          ELSE
            -- 値が[0]の場合は、一律[0]設定
            ln_output_unit := gn_0;
          END IF;
          gt_xml_data_table(gl_xml_idx).tag_value := ln_output_unit;
        END IF;
--
        ----------------------------------------------------------------
        -- 売上高データ
        ----------------------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'sales_amount';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
        gt_xml_data_table(gl_xml_idx).tag_value := TO_NUMBER(gr_sale_plan_1(i).amount);
--
        ----------------------------------------------------------------
        -- 標準原価データ (内訳合計 * 数量)
        ----------------------------------------------------------------
        ln_s_u_price 
            := TO_NUMBER(gr_sale_plan_1(i).total_amount) * TO_NUMBER(gr_sale_plan_1(i).quant);
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 's_unit_price';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
        gt_xml_data_table(gl_xml_idx).tag_value := ln_s_u_price;
--
        ----------------------------------------------------------------
        -- 粗利データ (金額 - 内訳合計 * 数量)
        ----------------------------------------------------------------
        ln_arari := TO_NUMBER(gr_sale_plan_1(i).amount) - ln_s_u_price;
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'arari';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
        gt_xml_data_table(gl_xml_idx).tag_value := ln_arari;
--
        ----------------------------------------------------------------
        -- 粗利率(%)データ  ((金額 - 内訳合計 * 数量) / 金額 * 100)
        ----------------------------------------------------------------
        -- ０除算回避判定
        IF (TO_NUMBER(gr_sale_plan_1(i).amount) <> 0) THEN
          -- 値が[0]出なければ計算
          ln_arari_par := ROUND((ln_arari / TO_NUMBER(gr_sale_plan_1(i).amount) * 100),2);
        ELSE
          -- 値が[0]の場合は、一律[0]設定
          ln_skbn_arari_par := gn_0;
        END IF;
--
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'arari_par';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
        gt_xml_data_table(gl_xml_idx).tag_value := ln_arari_par;
--
        ----------------------------------------------------------------
        -- 掛率(%)データ ((金額 * 100) / (品目定価 * 数量))
        ----------------------------------------------------------------
        -- 定価適用開始日にて旧定価・新定価の使用判断
        -- 年度開始月日がOPM品目マスタ定価適用開始日以上の場合
        IF (FND_DATE.STRING_TO_DATE(gr_sale_plan_1(i).price_st,'YYYY/MM/DD')   <= gd_start_day) THEN
          -- 新定価を使用
          ln_price := TO_NUMBER(gr_sale_plan_1(i).n_amount);
        -- 年度開始月日がOPM品目マスタ定価適用開始日未満の場合
        ELSIF (FND_DATE.STRING_TO_DATE(gr_sale_plan_1(i).price_st,'YYYY/MM/DD') > gd_start_day) THEN
          -- 旧定価を使用
          ln_price := TO_NUMBER(gr_sale_plan_1(i).o_amount);
        END IF;
--
        -- ０除算判定項目へ判定値を挿入
--2008.04.30 Y.Kawano modify start
--        ln_chk_0 := ln_price * TO_NUMBER(gr_sale_plan_1(i).quant) * 100;
        ln_chk_0 := ln_price * TO_NUMBER(gr_sale_plan_1(i).quant);
--2008.04.30 Y.Kawano modify end
        -- ０除算回避判定
        IF (ln_chk_0 <> 0) THEN
          -- 値が[0]出なければ計算
--2008.04.30 Y.Kawano modify start
--          ln_kake_par := ROUND(TO_NUMBER(gr_sale_plan_1(i).amount) / ln_chk_0,2);
          ln_kake_par := ROUND((TO_NUMBER(gr_sale_plan_1(i).amount) * 100) / ln_chk_0,2);
--2008.04.30 Y.Kawano modify end
        ELSE
          -- 値が[0]の場合は、一律[0]設定
          ln_kake_par := gn_0;
        END IF;
--
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'kake_par';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
        -- 品目定価 = ０か、計算結果がマイナスの場合、固定値を登録
        IF (ln_price = 0)
          OR (ln_kake_par < 0) THEN
          gt_xml_data_table(gl_xml_idx).tag_value := TO_NUMBER(gv_name_kotei); -- 固定値:70.00
        -- 品目定価 <> ０、計算結果がマイナスではない場合、計算結果を登録
        ELSE
          gt_xml_data_table(gl_xml_idx).tag_value := ln_kake_par;
        END IF;
--
        -- -----------------------------------------------------
        --  品目終了Ｇタグ出力
        -- -----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := '/g_dtl';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
        -- 細群計に使用する項目をSUM
        ln_s_am_sum   := ln_s_am_sum  + TO_NUMBER(gr_sale_plan_1(i).amount);   -- 売上高
        ln_nuit_sum   := ln_nuit_sum  + TO_NUMBER(gr_sale_plan_1(i).quant);    -- 本数
        ln_price_sum  := ln_price_sum + ln_price;                              -- 品目定価
-- 2009/04/20 v1.8 UPDATE START
/*
        ln_to_am_sum  := ln_to_am_sum + TO_NUMBER(gr_sale_plan_1(i).total_amount);
                                                                               -- 内訳合計
*/
        -- 明細ごとの計算結果を足し込む
        ln_s_unit_price_sum := ln_s_unit_price_sum + ln_s_u_price;             -- 標準原価
        ln_ara_sum          := ln_ara_sum + ln_arari;                          -- 粗利(集計用)
        ln_chk_0_sum        := ln_chk_0_sum + ln_chk_0;                        -- 掛率(集計用)
-- 2009/04/20 v1.8 UPDATE END
        -- 出力単位が「本数」の場合
        IF (gr_param.output_unit = gv_output_unit) THEN
          ln_quant_sum    := ln_quant_sum    + TO_NUMBER(gr_sale_plan_1(i).quant);
                                                                               -- 数量
        -- 出力単位が「ケース」の場合
        ELSE
          ln_quant_sum    := ln_quant_sum    + ln_output_unit;                 -- 数量
        END IF;
--
        -- 小群計に使用する項目をSUM
        -- 出力単位が「本数」の場合
        IF (gr_param.output_unit = gv_output_unit) THEN
          ln_st_quant_sum   := ln_st_quant_sum     + TO_NUMBER(gr_sale_plan_1(i).quant);
                                                                               -- 数量
        -- 出力単位が「ケース」の場合
        ELSE
          ln_st_quant_sum   := ln_st_quant_sum     + ln_output_unit;           -- 数量
        END IF;
-- 2009/04/20 v1.8 UPDATE START
/*
        ln_st_s_u_price_sum := ln_st_s_u_price_sum + TO_NUMBER(gr_sale_plan_1(i).total_amount);
                                                                               -- 内訳合計
*/
        -- 明細ごとの計算結果を足し込む
        ln_st_s_unit_price_sum  := ln_st_s_unit_price_sum + ln_s_u_price;      -- 標準原価
        ln_st_ara_sum           := ln_st_ara_sum + ln_arari;                   -- 粗利(集計用)
        ln_st_chk_0_sum         := ln_st_chk_0_sum + ln_chk_0;                 -- 掛率(集計用)
-- 2009/04/20 v1.8 UPDATE END
        ln_st_s_am_sum      := ln_st_s_am_sum      + TO_NUMBER(gr_sale_plan_1(i).amount);
                                                                               -- 売上高
        ln_st_nuit_sum      := ln_st_nuit_sum      + TO_NUMBER(gr_sale_plan_1(i).quant);
                                                                               -- 本数
        ln_st_price_sum     := ln_st_price_sum     + ln_price;                 -- 品目定価
--
        -- 中群計に使用する項目をSUM
        -- 出力単位が「本数」の場合
        IF (gr_param.output_unit = gv_output_unit) THEN
          ln_mt_quant_sum   := ln_mt_quant_sum     + TO_NUMBER(gr_sale_plan_1(i).quant);
                                                                               -- 数量
        -- 出力単位が「ケース」の場合
        ELSE
          ln_mt_quant_sum   := ln_mt_quant_sum     + ln_output_unit;           -- 数量
        END IF;
-- 2009/04/20 v1.8 UPDATE START
/*
        ln_mt_s_u_price_sum := ln_mt_s_u_price_sum + TO_NUMBER(gr_sale_plan_1(i).total_amount);
                                                                               -- 内訳合計
*/
        -- 明細ごとの計算結果を足し込む
        ln_mt_s_unit_price_sum  := ln_mt_s_unit_price_sum + ln_s_u_price;      -- 標準原価
        ln_mt_ara_sum           := ln_mt_ara_sum + ln_arari;                   -- 粗利(集計用)
        ln_mt_chk_0_sum         := ln_mt_chk_0_sum + ln_chk_0;                 -- 掛率(集計用)
-- 2009/04/20 v1.8 UPDATE END
        ln_mt_s_am_sum      := ln_mt_s_am_sum      + TO_NUMBER(gr_sale_plan_1(i).amount);
                                                                               -- 売上高
        ln_mt_nuit_sum      := ln_mt_nuit_sum      + TO_NUMBER(gr_sale_plan_1(i).quant);
                                                                               -- 本数
        ln_mt_price_sum     := ln_mt_price_sum     + ln_price;                 -- 品目定価
--
        -- 大群計に使用する項目をSUM
        -- 出力単位が「本数」の場合
        IF (gr_param.output_unit = gv_output_unit) THEN
          ln_lt_quant_sum   := ln_lt_quant_sum     + TO_NUMBER(gr_sale_plan_1(i).quant);
                                                                               -- 数量
        -- 出力単位が「ケース」の場合
        ELSE
          ln_lt_quant_sum   := ln_lt_quant_sum     + ln_output_unit;           -- 数量
        END IF;
-- 2009/04/20 v1.8 UPDATE START
/*
        ln_lt_s_u_price_sum := ln_lt_s_u_price_sum + TO_NUMBER(gr_sale_plan_1(i).total_amount);
                                                                               -- 内訳合計
*/
        -- 明細ごとの計算結果を足し込む
        ln_lt_s_unit_price_sum  := ln_lt_s_unit_price_sum + ln_s_u_price;      -- 標準原価
        ln_lt_ara_sum           := ln_lt_ara_sum + ln_arari;                   -- 粗利(集計用)
        ln_lt_chk_0_sum         := ln_lt_chk_0_sum + ln_chk_0;                 -- 掛率(集計用)-- 2009/04/20 v1.8 UPDATE END
-- 2009/04/20 v1.8 UPDATE END
        ln_lt_s_am_sum      := ln_lt_s_am_sum      + TO_NUMBER(gr_sale_plan_1(i).amount);
                                                                               -- 売上高
        ln_lt_nuit_sum      := ln_lt_nuit_sum      + TO_NUMBER(gr_sale_plan_1(i).quant);
                                                                               -- 本数
        ln_lt_price_sum     := ln_lt_price_sum     + ln_price;                 -- 品目定価
--
        -- 商品区分計に使用する項目をSUM
        ln_skbn_s_am_sum    := ln_skbn_s_am_sum    + TO_NUMBER(gr_sale_plan_1(i).amount);
                                                                               -- 売上高
        ln_skbn_nuit_sum    := ln_skbn_nuit_sum    + TO_NUMBER(gr_sale_plan_1(i).quant);
                                                                               -- 本数
        ln_skbn_price_sum   := ln_skbn_price_sum   + ln_price;                 -- 品目定価
-- 2009/04/20 v1.8 UPDATE START
/*
        ln_ktn_to_am_sum    := ln_ktn_to_am_sum    + TO_NUMBER(gr_sale_plan_1(i).total_amount);
                                                                               -- 内訳合計
*/
        -- 明細ごとの計算結果を足し込む
        ln_skbn_s_unit_price_sum  := ln_skbn_s_unit_price_sum + ln_s_u_price;  -- 標準原価
        ln_skbn_ara_sum           := ln_skbn_ara_sum + ln_arari;               -- 粗利(集計用)
        ln_skbn_chk_0_sum         := ln_skbn_chk_0_sum + ln_chk_0;             -- 掛率(集計用)
-- 2009/04/20 v1.8 UPDATE END
        -- 出力単位が「本数」の場合
        IF (gr_param.output_unit = gv_output_unit) THEN
          ln_ktn_quant_sum   := ln_ktn_quant_sum   + TO_NUMBER(gr_sale_plan_1(i).quant);
                                                                               -- 数量
        -- 出力単位が「ケース」の場合
        ELSE
          ln_ktn_quant_sum   := ln_ktn_quant_sum   + ln_output_unit;           -- 数量
        END IF;
--
        -- 拠点計に使用する項目をSUM
        ln_ktn_s_am_sum     := ln_ktn_s_am_sum     + TO_NUMBER(gr_sale_plan_1(i).amount);
                                                                               -- 売上高
        ln_ktn_nuit_sum     := ln_ktn_nuit_sum     + TO_NUMBER(gr_sale_plan_1(i).quant);
                                                                               -- 本数
        ln_ktn_price_sum    := ln_ktn_price_sum    + ln_price;                 -- 品目定価
-- 2009/04/20 v1.8 UPDATE START
/*
        ln_skbn_to_am_sum   := ln_skbn_to_am_sum   + TO_NUMBER(gr_sale_plan_1(i).total_amount);
                                                                               -- 内訳合計
*/
        -- 明細ごとの計算結果を足し込む
        ln_ktn_s_unit_price_sum := ln_ktn_s_unit_price_sum + ln_s_u_price;    -- 標準原価
        ln_ktn_ara_sum          := ln_ktn_ara_sum + ln_arari;                 -- 粗利
        ln_ktn_chk_0_sum        := ln_ktn_chk_0_sum + ln_chk_0;               -- 掛率(集計用)
-- 2009/04/20 v1.8 UPDATE END
        -- 出力単位が「本数」の場合
        IF (gr_param.output_unit = gv_output_unit) THEN
          ln_skbn_quant_sum   := ln_skbn_quant_sum + TO_NUMBER(gr_sale_plan_1(i).quant);
                                                                               -- 数量
        -- 出力単位が「ケース」の場合
        ELSE
          ln_skbn_quant_sum   := ln_skbn_quant_sum + ln_output_unit;           -- 数量
        END IF;
--
        -- 総合計に使用する項目をSUM
        ln_to_s_am_sum      := ln_to_s_am_sum      + TO_NUMBER(gr_sale_plan_1(i).amount);
                                                                               -- 売上高
        ln_to_nuit_sum      := ln_to_nuit_sum      + TO_NUMBER(gr_sale_plan_1(i).quant);
                                                                               -- 本数
        ln_to_price_sum     := ln_to_price_sum     + ln_price;                 -- 品目定価
-- 2009/04/20 v1.8 UPDATE START
/*
        ln_to_to_am_sum     := ln_to_to_am_sum     + TO_NUMBER(gr_sale_plan_1(i).total_amount);
                                                                               -- 内訳合計
*/
        -- 明細ごとの計算結果を足し込む
        ln_to_s_unit_price_sum  := ln_to_s_unit_price_sum + ln_s_u_price;      -- 標準原価
        ln_to_ara_sum           := ln_to_ara_sum + ln_arari;                   -- 粗利(集計用)
        ln_to_chk_0_sum         := ln_to_chk_0_sum + ln_chk_0;                 -- 掛率(集計用)
-- 2009/04/20 v1.8 UPDATE END
        -- 出力単位が「本数」の場合
        IF (gr_param.output_unit = gv_output_unit) THEN
          ln_to_quant_sum   := ln_to_quant_sum     + TO_NUMBER(gr_sale_plan_1(i).quant);
                                                                               -- 数量
        -- 出力単位が「ケース」の場合
        ELSE
          ln_to_quant_sum   := ln_to_quant_sum     + ln_output_unit;           -- 数量
        END IF;
--
      END LOOP main_data_loop_1;
--
      -- =====================================================
      --    終了処理
      -- =====================================================
      -- -----------------------------------------------------
      --  品目終了ＬＧタグ出力
      -- ----------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_dtl_info';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
      ----------------------------------------------------------------
      -- 細群計(標準原価)データ
      ----------------------------------------------------------------
      -- 標準原価算出
-- 2009/04/20 v1.8 UPDATE START
--      ln_syo_s_unit_price := ln_to_am_sum * ln_quant_sum;
      ln_syo_s_unit_price := ln_s_unit_price_sum;
-- 2009/04/20 v1.8 UPDATE END
--
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'syo_s_unit_price';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
      gt_xml_data_table(gl_xml_idx).tag_value := ln_syo_s_unit_price;
--
      ----------------------------------------------------------------
      -- 細群計(粗利)データ
      ----------------------------------------------------------------
      -- 粗利算出
-- 2009/04/20 v1.8 UPDATE START
--      ln_arari_sum := ln_s_am_sum - ln_syo_s_unit_price;
      ln_arari_sum := ln_ara_sum;
-- 2009/04/20 v1.8 UPDATE END
--
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'syo_arari';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
      gt_xml_data_table(gl_xml_idx).tag_value := ln_arari_sum;
--
      ----------------------------------------------------------------
      -- 細群計(粗利率)データ  ((粗利/売上高)*100)
      ----------------------------------------------------------------
      -- ０除算回避判定
      IF (ln_s_am_sum <> 0) THEN
        -- 値が[0]出なければ計算
        ln_syo_arari_par := ROUND((ln_arari_sum / ln_s_am_sum) * 100,2);
      ELSE
        -- 値が[0]の場合は、一律[0]設定
        ln_syo_arari_par := gn_0;
      END IF;
--
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'syo_arari_par';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
      gt_xml_data_table(gl_xml_idx).tag_value := ln_syo_arari_par;
--
      ----------------------------------------------------------------
      -- 細群計(掛率)データ  ((売上高*100)/(品目定価*本数))
      ----------------------------------------------------------------
-- 2009/04/20 v1.8 UPDATE START
/*
      -- ０除算判定項目へ判定値を挿入
      ln_chk_0 := ln_price_sum * ln_nuit_sum;
      -- ０除算回避判定
      IF (ln_chk_0 <> 0) THEN
        -- 値が[0]出なければ計算
        ln_syo_kake_par := ROUND((ln_s_am_sum * 100) / ln_chk_0,2);
      ELSE
        -- 値が[0]の場合は、一律[0]設定
        ln_syo_arari_par := gn_0;
      END IF;
*/
      -- ０除算回避判定
      IF (ln_chk_0_sum <> 0) THEN
        -- 値が[0]出なければ計算
        ln_syo_kake_par := ROUND((ln_s_am_sum * 100) / ln_chk_0_sum, 2);
      ELSE
        -- 値が[0]の場合は、一律[0]設定
        ln_syo_kake_par := gn_0;
      END IF;
-- 2009/04/20 v1.8 UPDATE END
--
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'syo_kake_par';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
      -- 品目定価 = ０か、計算結果がマイナスの場合、固定値を登録
      IF (ln_price_sum = 0) 
        OR (ln_syo_kake_par < 0)THEN
        gt_xml_data_table(gl_xml_idx).tag_value := TO_NUMBER(gv_name_kotei); -- 固定値:70.00
      -- 品目定価 <> ０、計算結果がマイナスではない場合、計算結果を登録
      ELSE
        gt_xml_data_table(gl_xml_idx).tag_value := ln_syo_kake_par;
      END IF;
--
      ----------------------------------------------------------------
      -- 小群計(数量)データ
      ----------------------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'sttl_quant';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
      gt_xml_data_table(gl_xml_idx).tag_value := ln_st_quant_sum;
--
      ----------------------------------------------------------------
      -- 小群計(売上高)データ
      ----------------------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'sttl_sales_amount';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
      gt_xml_data_table(gl_xml_idx).tag_value := ln_st_s_am_sum;
--
      ----------------------------------------------------------------
      -- 小群計(標準原価)データ
      ----------------------------------------------------------------
      -- 標準原価算出
-- 2009/04/20 v1.8 UPDATE START
--      ln_sttl_s_unit_price := ln_st_s_u_price_sum * ln_st_quant_sum;
      ln_sttl_s_unit_price := ln_st_s_unit_price_sum;
-- 2009/04/20 v1.8 UPDATE END
--
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'sttl_s_unit_price';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
      gt_xml_data_table(gl_xml_idx).tag_value := ln_sttl_s_unit_price;
--
      ----------------------------------------------------------------
      -- 小群計(粗利)データ
      ----------------------------------------------------------------
      -- 粗利算出
-- 2009/04/20 v1.8 UPDATE START
--      ln_st_arari_sum := ln_s_am_sum - ln_syo_s_unit_price;
      ln_st_arari_sum := ln_st_ara_sum;
-- 2009/04/20 v1.8 UPDATE END
--
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'sttl_arari';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
      gt_xml_data_table(gl_xml_idx).tag_value := ln_st_arari_sum;
--
      ----------------------------------------------------------------
      -- 小群計(粗利率)データ  ((粗利/売上高)*100)
      ----------------------------------------------------------------
      -- ０除算回避判定
      IF (ln_st_s_am_sum <> 0) THEN
        -- 値が[0]出なければ計算
        ln_sttl_arari_par := ROUND((ln_st_arari_sum / ln_st_s_am_sum) * 100,2);
      ELSE
        -- 値が[0]の場合は、一律[0]設定
        ln_sttl_arari_par := gn_0;
      END IF;
--
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'sttl_arari_par';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
      gt_xml_data_table(gl_xml_idx).tag_value := ln_sttl_arari_par;
--
      ----------------------------------------------------------------
      -- 小群計(掛率)データ  ((売上高*100)/(品目定価*本数))
      ----------------------------------------------------------------
-- 2009/04/20 v1.8 UPDATE START
/*
      -- ０除算判定項目へ判定値を挿入
      ln_chk_0 := ln_st_price_sum * ln_st_nuit_sum;
      -- ０除算回避判定
      IF (ln_chk_0 <> 0) THEN
        -- 値が[0]出なければ計算
        ln_sttl_kake_par := ROUND((ln_st_s_am_sum * 100) / ln_chk_0,2);
      ELSE
        -- 値が[0]の場合は、一律[0]設定
        ln_sttl_kake_par := gn_0;
      END IF;
*/
      -- ０除算回避判定
      IF (ln_st_chk_0_sum <> 0) THEN
        -- 値が[0]出なければ計算
        ln_sttl_kake_par := ROUND((ln_st_s_am_sum * 100) / ln_st_chk_0_sum, 2);
      ELSE
        -- 値が[0]の場合は、一律[0]設定
        ln_sttl_kake_par := gn_0;
      END IF;
-- 2009/04/20 v1.8 UPDATE END
--
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'sttl_kake_par';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
      -- 品目定価 = ０か、計算結果がマイナスの場合、固定値を登録
      IF (ln_st_price_sum = 0)
        OR (ln_sttl_kake_par < 0) THEN
        gt_xml_data_table(gl_xml_idx).tag_value := TO_NUMBER(gv_name_kotei); -- 固定値:70.00
        -- 品目定価 <> ０、計算結果がマイナスではない場合、計算結果を登録
      ELSE
        gt_xml_data_table(gl_xml_idx).tag_value := ln_sttl_kake_par;
      END IF;
--
      ----------------------------------------------------------------
      -- 中群計(数量)データ
      ----------------------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'mttl_quant';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
      gt_xml_data_table(gl_xml_idx).tag_value := ln_mt_quant_sum;
--
      ----------------------------------------------------------------
      -- 中群計(売上高)データ
      ----------------------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'mttl_sales_amount';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
      gt_xml_data_table(gl_xml_idx).tag_value := ln_mt_s_am_sum;
--
      ----------------------------------------------------------------
      -- 中群計(標準原価)データ
      ----------------------------------------------------------------
      -- 標準原価算出
-- 2009/04/20 v1.8 UPDATE START
--      ln_mttl_s_unit_price := ln_mt_s_u_price_sum * ln_mt_quant_sum;
      ln_mttl_s_unit_price := ln_mt_s_unit_price_sum;
-- 2009/04/20 v1.8 UPDATE END
--
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'mttl_s_unit_price';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
      gt_xml_data_table(gl_xml_idx).tag_value := ln_mttl_s_unit_price;
--
      ----------------------------------------------------------------
      -- 中群計(粗利)データ
      ----------------------------------------------------------------
      -- 粗利算出
-- 2009/04/20 v1.8 UPDATE START
--      ln_mt_arari_sum := ln_mt_s_am_sum - ln_mttl_s_unit_price;
      ln_mt_arari_sum := ln_mt_ara_sum;
-- 2009/04/20 v1.8 UPDATE END
--
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'mttl_arari';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
      gt_xml_data_table(gl_xml_idx).tag_value := ln_mt_arari_sum;
--
      ----------------------------------------------------------------
      -- 中群計(粗利率)データ  ((粗利/売上高)*100)
      ----------------------------------------------------------------
      --  ０除算回避判定
      IF (ln_mt_s_am_sum <> 0) THEN
        -- 値が[0]出なければ計算
        ln_mttl_arari_par := ROUND((ln_mt_arari_sum / ln_mt_s_am_sum) * 100,2);
      ELSE
        -- 値が[0]の場合は、一律[0]設定
        ln_mttl_arari_par := gn_0;
      END IF;
--
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'mttl_arari_par';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
      gt_xml_data_table(gl_xml_idx).tag_value := ln_mttl_arari_par;
--
      ----------------------------------------------------------------
      -- 中群計(掛率)データ  ((売上高*100)/(品目定価*本数))
      ----------------------------------------------------------------
-- 2009/04/20 v1.8 UPDATE START
/*
      -- ０除算判定項目へ判定値を挿入
      ln_chk_0 := ln_mt_price_sum * ln_mt_nuit_sum;
      -- ０除算回避判定
      IF (ln_chk_0 <> 0) THEN
        -- 値が[0]出なければ計算
        ln_mttl_kake_par := ROUND((ln_mt_s_am_sum * 100) / ln_chk_0,2);
      ELSE
        -- 値が[0]の場合は、一律[0]設定
        ln_mttl_kake_par := gn_0;
      END IF;
*/
      -- ０除算回避判定
      IF (ln_mt_chk_0_sum <> 0) THEN
        -- 値が[0]出なければ計算
        ln_mttl_kake_par := ROUND((ln_mt_s_am_sum * 100) / ln_mt_chk_0_sum, 2);
      ELSE
        -- 値が[0]の場合は、一律[0]設定
        ln_mttl_kake_par := gn_0;
      END IF;
-- 2009/04/20 v1.8 UPDATE END
--
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'mttl_kake_par';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
      -- 品目定価 = ０か、計算結果がマイナスの場合、固定値を登録
      IF (ln_mt_price_sum = 0)
        OR (ln_mttl_kake_par < 0) THEN
        gt_xml_data_table(gl_xml_idx).tag_value := TO_NUMBER(gv_name_kotei); -- 固定値:70.00
      -- 品目定価 <> ０、計算結果がマイナスではない場合、計算結果を登録
      ELSE
        gt_xml_data_table(gl_xml_idx).tag_value := ln_mttl_kake_par;
      END IF;
--
      ----------------------------------------------------------------
      -- 大群計(数量)データ
      ----------------------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'lttl_quant';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
      gt_xml_data_table(gl_xml_idx).tag_value := ln_lt_quant_sum;
--
      ----------------------------------------------------------------
      -- 大群計(売上高)データ
      ----------------------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'lttl_sales_amount';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
      gt_xml_data_table(gl_xml_idx).tag_value := ln_lt_s_am_sum;
--
      ----------------------------------------------------------------
      -- 大群計(標準原価)データ
      ----------------------------------------------------------------
      -- 標準原価算出
-- 2009/04/20 v1.8 UPDATE START
--      ln_lttl_s_unit_price := ln_lt_s_u_price_sum * ln_lt_quant_sum;
      ln_lttl_s_unit_price := ln_lt_s_unit_price_sum;
-- 2009/04/20 v1.8 UPDATE END
--
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'lttl_s_unit_price';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
      gt_xml_data_table(gl_xml_idx).tag_value := ln_lttl_s_unit_price;
--
      ----------------------------------------------------------------
      -- 大群計(粗利)データ
      ----------------------------------------------------------------
      -- 粗利算出
-- 2009/04/20 v1.8 UPDATE START
--      ln_lt_arari_sum := ln_lt_s_am_sum - ln_lttl_s_unit_price;
      ln_lt_arari_sum := ln_lt_ara_sum;
-- 2009/04/20 v1.8 UPDATE END
--
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'lttl_arari';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
      gt_xml_data_table(gl_xml_idx).tag_value := ln_lt_arari_sum;
--
      ----------------------------------------------------------------
      -- 大群計(粗利率)データ  ((粗利/売上高)*100)
      ----------------------------------------------------------------
      -- ０除算回避判定
      IF (ln_lt_s_am_sum <> 0) THEN
        -- 値が[0]出なければ計算
        ln_lttl_arari_par := ROUND((ln_lt_arari_sum / ln_lt_s_am_sum) * 100,2);
      ELSE
        -- 値が[0]の場合は、一律[0]設定
        ln_lttl_arari_par := gn_0;
      END IF;
--
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'lttl_arari_par';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
      gt_xml_data_table(gl_xml_idx).tag_value := ln_lttl_arari_par;
--
      ----------------------------------------------------------------
      -- 大群計(掛率)データ  ((売上高*100)/(品目定価*本数))
      ----------------------------------------------------------------
-- 2009/04/20 v1.8 UPDATE START
/*
      -- ０除算判定項目へ判定値を挿入
      ln_chk_0 := ln_lt_price_sum * ln_lt_nuit_sum;
      -- ０除算回避判定
      IF (ln_chk_0 <> 0) THEN
        -- 値が[0]出なければ計算
        ln_lttl_kake_par := ROUND((ln_lt_s_am_sum * 100) / ln_chk_0,2);
      ELSE
        -- 値が[0]の場合は、一律[0]設定
        ln_lttl_kake_par := gn_0;
      END IF;
*/
      -- ０除算回避判定
      IF (ln_lt_chk_0_sum <> 0) THEN
        -- 値が[0]出なければ計算
        ln_lttl_kake_par := ROUND((ln_lt_s_am_sum * 100) / ln_lt_chk_0_sum, 2);
      ELSE
        -- 値が[0]の場合は、一律[0]設定
        ln_lttl_kake_par := gn_0;
      END IF;
-- 2009/04/20 v1.8 UPDATE END
--
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'lttl_kake_par';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
      -- 品目定価 = ０か、計算結果がマイナスの場合、固定値を登録
      IF (ln_lt_price_sum = 0)
        OR (ln_lttl_kake_par < 0) THEN
        gt_xml_data_table(gl_xml_idx).tag_value := TO_NUMBER(gv_name_kotei); -- 固定値:70.00
      -- 品目定価 <> ０、計算結果がマイナスではない場合、計算結果を登録
      ELSE
        gt_xml_data_table(gl_xml_idx).tag_value := ln_lttl_kake_par;
      END IF;
--
      -- -----------------------------------------------------
      --  群コード終了Ｇタグ出力
      -- -----------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := '/g_gun';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
      -- -----------------------------------------------------
      --  群コード終了ＬＧタグ出力
      -- -----------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_gun_info';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
      ----------------------------------------------------------------
      -- 拠点計(標準原価)データ
      ----------------------------------------------------------------
      -- 標準原価算出
-- 2009/04/20 v1.8 UPDATE START
--      ln_ktn_s_unit_price := ln_ktn_to_am_sum * ln_ktn_quant_sum;
      ln_ktn_s_unit_price := ln_ktn_s_unit_price_sum;
-- 2009/04/20 v1.8 UPDATE END
--
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'ktn_s_unit_price';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
      gt_xml_data_table(gl_xml_idx).tag_value := ln_ktn_s_unit_price;
--
      ----------------------------------------------------------------
      -- 拠点計(粗利)データ
      ----------------------------------------------------------------
      -- 粗利算出
-- 2009/04/20 v1.8 UPDATE START
--      ln_ktn_arari_sum := ln_ktn_s_am_sum - ln_ktn_s_unit_price;
      ln_ktn_arari_sum := ln_ktn_ara_sum;
-- 2009/04/20 v1.8 UPDATE END
--
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'ktn_arari';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
      gt_xml_data_table(gl_xml_idx).tag_value := ln_ktn_arari_sum;
--
      ----------------------------------------------------------------
      -- 拠点計(粗利率)データ  ((粗利/売上高)*100)
      ----------------------------------------------------------------
      -- ０除算回避判定
      IF (ln_ktn_s_am_sum <> 0) THEN
        -- 値が[0]出なければ計算
        ln_ktn_arari_par := ROUND((ln_ktn_arari_sum / ln_ktn_s_am_sum) * 100,2);
      ELSE
        -- 値が[0]の場合は、一律[0]設定
        ln_ktn_arari_par := gn_0;
      END IF;
--
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'ktn_arari_par';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
      gt_xml_data_table(gl_xml_idx).tag_value := ln_ktn_arari_par;
--
      ----------------------------------------------------------------
      -- 拠点計(掛率)データ  ((売上高*100)/(品目定価*本数))
      ----------------------------------------------------------------
-- 2009/04/20 v1.8 UPDATE START
/*
      -- ０除算判定項目へ判定値を挿入
      ln_chk_0 := ln_ktn_price_sum * ln_ktn_nuit_sum;
      -- ０除算回避判定
      IF (ln_chk_0 <> 0) THEN
        -- 値が[0]出なければ計算
        ln_ktn_kake_par := ROUND((ln_ktn_s_am_sum * 100) / ln_chk_0,2);
      ELSE
        -- 値が[0]の場合は、一律[0]設定
        ln_ktn_kake_par := gn_0;
      END IF;
*/
      -- ０除算回避判定
      IF (ln_ktn_chk_0_sum <> 0) THEN
        -- 値が[0]出なければ計算
        ln_ktn_kake_par := ROUND((ln_ktn_s_am_sum * 100) / ln_ktn_chk_0_sum, 2);
      ELSE
        -- 値が[0]の場合は、一律[0]設定
        ln_ktn_kake_par := gn_0;
      END IF;
-- 2009/04/20 v1.8 UPDATE END
--
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'ktn_kake_par';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
      -- 品目定価 = ０か、計算結果がマイナスの場合、固定値を登録
      IF (ln_ktn_price_sum = 0)
        OR (ln_ktn_kake_par < 0) THEN
        gt_xml_data_table(gl_xml_idx).tag_value := TO_NUMBER(gv_name_kotei); -- 固定値:70.00
      -- 品目定価 <> ０、計算結果がマイナスではない場合、計算結果を登録
      ELSE
        gt_xml_data_table(gl_xml_idx).tag_value := ln_ktn_kake_par;
      END IF;
--
      -- -----------------------------------------------------
      --  拠点終了Ｇタグ出力
      -- -----------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := '/g_ktn';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
      -- -----------------------------------------------------
      --  拠点終了ＬＧタグ出力
      -- -----------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_ktn_info';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
      ----------------------------------------------------------------
      -- 商品区分計(標準原価)データ
      ----------------------------------------------------------------
      -- 標準原価算出
-- 2009/04/20 v1.8 UPDATE START
--      ln_skbn_s_unit_price := ln_skbn_to_am_sum * ln_skbn_quant_sum;
      ln_skbn_s_unit_price := ln_skbn_s_unit_price_sum;
-- 2009/04/20 v1.8 UPDATE END
--
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'skbn_s_unit_price';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
      gt_xml_data_table(gl_xml_idx).tag_value := ln_skbn_s_unit_price;
--
      ----------------------------------------------------------------
      -- 商品区分計(粗利)データ
      ----------------------------------------------------------------
      -- 粗利算出
-- 2009/04/20 v1.8 UPDATE START
--      ln_skbn_arari_sum := ln_skbn_s_am_sum - ln_skbn_s_unit_price;
      ln_skbn_arari_sum := ln_skbn_ara_sum;
-- 2009/04/20 v1.8 UPDATE END
--
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'skbn_arari';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
      gt_xml_data_table(gl_xml_idx).tag_value := ln_skbn_arari_sum;
--
      ----------------------------------------------------------------
      -- 商品区分計(粗利率)データ  ((粗利/売上高)*100)
      ----------------------------------------------------------------
      -- ０除算回避判定
      IF (ln_skbn_s_am_sum <> 0) THEN
        -- 値が[0]出なければ計算
        ln_skbn_arari_par := ROUND((ln_skbn_arari_sum / ln_skbn_s_am_sum) * 100,2);
      ELSE
        -- 値が[0]の場合は、一律[0]設定
        ln_skbn_arari_par := gn_0;
      END IF;
--
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'skbn_arari_par';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
      gt_xml_data_table(gl_xml_idx).tag_value := ln_skbn_arari_par;
--
      ----------------------------------------------------------------
      -- 商品区分計(掛率)データ  ((売上高*100)/(品目定価*本数))
      ----------------------------------------------------------------
-- 2009/04/20 v1.8 UPDATE START
/*
      -- ０除算判定項目へ判定値を挿入
      ln_chk_0 := ln_skbn_price_sum * ln_skbn_nuit_sum;
      -- ０除算回避判定
      IF (ln_chk_0 <> 0) THEN
        -- 値が[0]出なければ計算
        ln_skbn_kake_par := ROUND((ln_skbn_s_am_sum * 100) / ln_chk_0,2);
      ELSE
        -- 値が[0]の場合は、一律[0]設定
        ln_skbn_kake_par := gn_0;
      END IF;
*/
      -- ０除算回避判定
      IF (ln_skbn_chk_0_sum <> 0) THEN
        -- 値が[0]出なければ計算
        ln_skbn_kake_par := ROUND((ln_skbn_s_am_sum * 100) / ln_skbn_chk_0_sum, 2);
      ELSE
        -- 値が[0]の場合は、一律[0]設定
        ln_skbn_kake_par := gn_0;
          END IF;
-- 2009/04/20 v1.8 UPDATE END
--
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'skbn_kake_par';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
      -- 品目定価 = ０か、計算結果がマイナスの場合、固定値を登録
      IF (ln_skbn_price_sum = 0)
        OR (ln_skbn_kake_par < 0) THEN
        gt_xml_data_table(gl_xml_idx).tag_value := TO_NUMBER(gv_name_kotei); -- 固定値:70.00
      -- 品目定価 <> ０、計算結果がマイナスではない場合、計算結果を登録
      ELSE
        gt_xml_data_table(gl_xml_idx).tag_value := ln_skbn_kake_par;
      END IF;
--
      ----------------------------------------------------------------
      -- 総合計(標準原価)データ
      ----------------------------------------------------------------
      -- 標準原価算出
-- 2009/04/20 v1.8 UPDATE START
--      ln_to_s_unit_price := ln_to_to_am_sum * ln_to_quant_sum;
      ln_to_s_unit_price := ln_to_s_unit_price_sum;
-- 2009/04/20 v1.8 UPDATE END
--
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'to_s_unit_price';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
      gt_xml_data_table(gl_xml_idx).tag_value := ln_to_s_unit_price;
--
      ----------------------------------------------------------------
      -- 総合計(粗利)データ
      ----------------------------------------------------------------
      -- 粗利算出
-- 2009/04/20 v1.8 UPDATE START
--      ln_to_arari_sum := ln_to_s_am_sum - ln_to_s_unit_price;
      ln_to_arari_sum := ln_to_ara_sum;
-- 2009/04/20 v1.8 UPDATE END
--
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'to_arari';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
      gt_xml_data_table(gl_xml_idx).tag_value := ln_to_arari_sum;
--
      ----------------------------------------------------------------
      -- 総合計(粗利率)データ  ((粗利/売上高)*100)
      ----------------------------------------------------------------
      -- ０除算回避判定
      IF (ln_to_s_am_sum <> 0) THEN
        -- 値が[0]出なければ計算
        ln_to_arari_par := ROUND((ln_to_arari_sum / ln_to_s_am_sum) * 100,2);
      ELSE
        -- 値が[0]の場合は、一律[0]設定
        ln_to_arari_par := gn_0;
      END IF;
--
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'to_arari_par';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
      gt_xml_data_table(gl_xml_idx).tag_value := ln_to_arari_par;
--
      ----------------------------------------------------------------
      -- 総合計(掛率)データ  ((売上高*100)/(品目定価*本数))
      ----------------------------------------------------------------
-- 2009/04/20 v1.8 UPDATE START
/*
      -- ０除算判定項目へ判定値を挿入
      ln_chk_0 := ln_to_price_sum * ln_to_nuit_sum;
      -- ０除算回避判定
      IF (ln_chk_0 <> 0) THEN
        -- 値が[0]出なければ計算
        ln_to_kake_par := ROUND((ln_to_s_am_sum * 100) / ln_chk_0,2);
      ELSE
        -- 値が[0]の場合は、一律[0]設定
        ln_to_kake_par := gn_0;
      END IF;
*/
      -- ０除算回避判定
      IF (ln_to_chk_0_sum <> 0) THEN
        -- 値が[0]出なければ計算
        ln_to_kake_par := ROUND((ln_to_s_am_sum * 100) / ln_to_chk_0_sum, 2);
      ELSE
        -- 値が[0]の場合は、一律[0]設定
        ln_to_kake_par := gn_0;
      END IF;
-- 2009/04/20 v1.8 UPDATE END
--
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'to_kake_par';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
      -- 品目定価 = ０か、計算結果がマイナスの場合、固定値を登録
      IF (ln_to_price_sum = 0)
        OR (ln_to_kake_par < 0) THEN
          gt_xml_data_table(gl_xml_idx).tag_value := TO_NUMBER(gv_name_kotei); -- 固定値:70.00
      -- 品目定価 <> ０、計算結果がマイナスではない場合、計算結果を登録
      ELSE
        gt_xml_data_table(gl_xml_idx).tag_value := ln_to_kake_par;
      END IF;
--
      -- -----------------------------------------------------
      --  商品区分終了Ｇタグ出力
      -- -----------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := '/g_skbn';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
      -- -----------------------------------------------------
      --  商品区分終了ＬＧタグ出力
      -- -----------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_skbn_info';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
      -- -----------------------------------------------------
      -- データ終了タグ出力
      -- -----------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := '/data_info';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
      -- -----------------------------------------------------
      -- ルート終了タグ出力
      -- -----------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := '/root';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
    END IF;
--
  EXCEPTION
    -- *** 取得データ０件 ***
    WHEN no_data_expt THEN
      ov_retcode := gv_status_warn;
      ov_errmsg  := xxcmn_common_pkg.get_msg( gv_application
                                             ,gv_err_code_no_data
                                            );
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
  END prc_create_xml_data;
--
  /**********************************************************************************
   * Function Name    : convert_into_xml
   * Description      : XMLデータ変換
   ***********************************************************************************/
  FUNCTION convert_into_xml
    (
      iv_name    IN   VARCHAR2
     ,iv_value   IN   VARCHAR2
     ,ic_type    IN   CHAR
    ) RETURN VARCHAR2
  IS
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'convert_into_xml'; -- プログラム名
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル変数 ***
    lv_convert_data   VARCHAR2(2000);
--
  BEGIN
--
    --データの場合
    IF (ic_type = 'D') THEN
      lv_convert_data := '<'||iv_name||'><![CDATA['||iv_value||']]></'||iv_name||'>';
    ELSE
      lv_convert_data := '<'||iv_name||'>';
    END IF;
--
    RETURN(lv_convert_data);
--
  END convert_into_xml;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain
    (
      iv_year           IN    VARCHAR2     --   01.年度
     ,iv_prod_div       IN    VARCHAR2     --   02.商品区分
     ,iv_gen            IN    VARCHAR2     --   03.世代
     ,iv_output_unit    IN    VARCHAR2     --   04.出力単位
     ,iv_output_type    IN    VARCHAR2     --   05.出力種別
     ,iv_base_01        IN    VARCHAR2     --   06.拠点１
     ,iv_base_02        IN    VARCHAR2     --   07.拠点２
     ,iv_base_03        IN    VARCHAR2     --   08.拠点３
     ,iv_base_04        IN    VARCHAR2     --   09.拠点４
     ,iv_base_05        IN    VARCHAR2     --   10.拠点５
     ,iv_base_06        IN    VARCHAR2     --   11.拠点６
     ,iv_base_07        IN    VARCHAR2     --   12.拠点７
     ,iv_base_08        IN    VARCHAR2     --   13.拠点８
     ,iv_base_09        IN    VARCHAR2     --   14.拠点９
     ,iv_base_10        IN    VARCHAR2     --   15.拠点１０
     ,iv_crowd_code_01  IN    VARCHAR2     --   16.群コード１
     ,iv_crowd_code_02  IN    VARCHAR2     --   17.群コード２
     ,iv_crowd_code_03  IN    VARCHAR2     --   18.群コード３
     ,iv_crowd_code_04  IN    VARCHAR2     --   19.群コード４
     ,iv_crowd_code_05  IN    VARCHAR2     --   20.群コード５
     ,iv_crowd_code_06  IN    VARCHAR2     --   21.群コード６
     ,iv_crowd_code_07  IN    VARCHAR2     --   22.群コード７
     ,iv_crowd_code_08  IN    VARCHAR2     --   23.群コード８
     ,iv_crowd_code_09  IN    VARCHAR2     --   24.群コード９
     ,iv_crowd_code_10  IN    VARCHAR2     --   25.群コード１０
     ,ov_errbuf         OUT   VARCHAR2     --   エラー・メッセージ           --# 固定 #
     ,ov_retcode        OUT   VARCHAR2     --   リターン・コード             --# 固定 #
     ,ov_errmsg         OUT   VARCHAR2     --   ユーザー・エラー・メッセージ --# 固定 #
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
    lv_xml_string    VARCHAR2(32000);
    ln_retcode       NUMBER;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- =====================================================
    -- 初期処理
    -- =====================================================
    -- -----------------------------------------------------
    -- パラメータ格納
    -- -----------------------------------------------------
    gr_param.year          := iv_year;          -- 年度
    gr_param.prod_div      := iv_prod_div;      -- 商品区分
    gr_param.gen           := iv_gen;           -- 世代
    gr_param.output_unit   := iv_output_unit;   -- 出力単位
    gr_param.output_type   := iv_output_type;   -- 出力種別
    gr_param.base_01       := iv_base_01;       -- 拠点１
    gr_param.base_02       := iv_base_02;       -- 拠点２
    gr_param.base_03       := iv_base_03;       -- 拠点３
    gr_param.base_04       := iv_base_04;       -- 拠点４
    gr_param.base_05       := iv_base_05;       -- 拠点５
    gr_param.base_06       := iv_base_06;       -- 拠点６
    gr_param.base_07       := iv_base_07;       -- 拠点７
    gr_param.base_08       := iv_base_08;       -- 拠点８
    gr_param.base_09       := iv_base_09;       -- 拠点９
    gr_param.base_10       := iv_base_10;       -- 拠点１０
    gr_param.crowd_code_01 := iv_crowd_code_01; -- 群コード１
    gr_param.crowd_code_02 := iv_crowd_code_02; -- 群コード２
    gr_param.crowd_code_03 := iv_crowd_code_03; -- 群コード３
    gr_param.crowd_code_04 := iv_crowd_code_04; -- 群コード４
    gr_param.crowd_code_05 := iv_crowd_code_05; -- 群コード５
    gr_param.crowd_code_06 := iv_crowd_code_06; -- 群コード６
    gr_param.crowd_code_07 := iv_crowd_code_07; -- 群コード７
    gr_param.crowd_code_08 := iv_crowd_code_08; -- 群コード８
    gr_param.crowd_code_09 := iv_crowd_code_09; -- 群コード９
    gr_param.crowd_code_10 := iv_crowd_code_10; -- 群コード１０
--
    -- =====================================================
    -- データ取得 - カスタムオプション取得  (B-1-0)
    -- =====================================================
    pro_get_cus_option
      (
        ov_errbuf         => lv_errbuf          -- エラー・メッセージ           --# 固定 #
       ,ov_retcode        => lv_retcode         -- リターン・コード             --# 固定 #
       ,ov_errmsg         => lv_errmsg          -- ユーザー・エラー・メッセージ --# 固定 #
      );
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- =====================================================
    -- XML タグ出力 - ユーザ情報部分(user_info)
    -- =====================================================
    prc_create_xml_data_user
      (
        ov_errbuf        => lv_errbuf          -- エラー・メッセージ           --# 固定 #
       ,ov_retcode       => lv_retcode         -- リターン・コード             --# 固定 #
       ,ov_errmsg        => lv_errmsg          -- ユーザー・エラー・メッセージ --# 固定 #
      );
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- =====================================================
    -- XML タグ出力 - パラメータ情報部分(param_info)
    -- =====================================================
    prc_create_xml_data_param
      (
        ov_errbuf        => lv_errbuf          -- エラー・メッセージ           --# 固定 #
       ,ov_retcode       => lv_retcode         -- リターン・コード             --# 固定 #
       ,ov_errmsg        => lv_errmsg          -- ユーザー・エラー・メッセージ --# 固定 #
      );
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- =====================================================
    -- XMLデータ作成 - 帳票データ出力
    -- =====================================================
    prc_create_xml_data
      (
        ov_errbuf         => lv_errbuf          -- エラー・メッセージ           --# 固定 #
       ,ov_retcode        => lv_retcode         -- リターン・コード             --# 固定 #
       ,ov_errmsg         => lv_errmsg          -- ユーザー・エラー・メッセージ --# 固定 #
      );
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ==================================================
    -- XML出力
    -- ==================================================
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<?xml version="1.0" encoding="shift_jis" ?>');
--
    -- --------------------------------------------------
    -- 抽出データが０件の場合
    -- --------------------------------------------------
    IF (lv_errmsg IS NOT NULL)
      AND (lv_retcode = gv_status_warn)THEN
      -- --------------------------------------------------
      -- メッセージの設定
      -- --------------------------------------------------
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '<root>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '  <data_info>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '    <lg_skbn_info>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '      <g_skbn>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '        <lg_ktn_info>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '          <g_ktn>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '            <lg_gun_info>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '              <g_gun>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '                <msg>' || lv_errmsg || '</msg>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '              </g_gun>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '            </lg_gun_info>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '          </g_ktn>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '        </lg_ktn_info>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '      </g_skbn>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '    </lg_skbn_info>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '  </data_info>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '</root>');
--
    -- --------------------------------------------------
    -- 帳票データが出力できた場合
    -- --------------------------------------------------
    ELSE
      -- XMLデータ部出力
      <<xml_data_table>>
      FOR i IN 1 .. gt_xml_data_table.COUNT LOOP
        lv_xml_string := convert_into_xml
                           (
                             iv_name   =>  gt_xml_data_table(i).tag_name
                            ,iv_value  =>  gt_xml_data_table(i).tag_value
                            ,ic_type   =>  gt_xml_data_table(i).tag_type
                           );
        -- XMLタグ出力
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_xml_string);
      END LOOP xml_data_table;
--
    END IF;
--
    -- ==================================================
    -- 終了ステータス設定
    -- ==================================================
    ov_retcode := lv_retcode;
    ov_errmsg  := lv_errmsg;
    ov_errbuf  := lv_errbuf;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ###################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
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
  PROCEDURE main
    (
      errbuf           OUT    VARCHAR2      --   エラーメッセージ
     ,retcode          OUT    VARCHAR2      --   エラーコード
     ,iv_year          IN     VARCHAR2      --   01.年度
     ,iv_prod_div      IN     VARCHAR2      --   02.商品区分
     ,iv_gen           IN     VARCHAR2      --   03.世代
     ,iv_output_unit   IN     VARCHAR2      --   04.出力単位
     ,iv_output_type   IN     VARCHAR2      --   05.出力種別
     ,iv_base_01       IN     VARCHAR2      --   06.拠点１
     ,iv_base_02       IN     VARCHAR2      --   07.拠点２
     ,iv_base_03       IN     VARCHAR2      --   08.拠点３
     ,iv_base_04       IN     VARCHAR2      --   09.拠点４
     ,iv_base_05       IN     VARCHAR2      --   10.拠点５
     ,iv_base_06       IN     VARCHAR2      --   11.拠点６
     ,iv_base_07       IN     VARCHAR2      --   12.拠点７
     ,iv_base_08       IN     VARCHAR2      --   13.拠点８
     ,iv_base_09       IN     VARCHAR2      --   14.拠点９
     ,iv_base_10       IN     VARCHAR2      --   15.拠点１０
     ,iv_crowd_code_01 IN     VARCHAR2      --   16.群コード１
     ,iv_crowd_code_02 IN     VARCHAR2      --   17.群コード２
     ,iv_crowd_code_03 IN     VARCHAR2      --   18.群コード３
     ,iv_crowd_code_04 IN     VARCHAR2      --   19.群コード４
     ,iv_crowd_code_05 IN     VARCHAR2      --   20.群コード５
     ,iv_crowd_code_06 IN     VARCHAR2      --   21.群コード６
     ,iv_crowd_code_07 IN     VARCHAR2      --   22.群コード７
     ,iv_crowd_code_08 IN     VARCHAR2      --   23.群コード８
     ,iv_crowd_code_09 IN     VARCHAR2      --   24.群コード９
     ,iv_crowd_code_10 IN     VARCHAR2      --   25.群コード１０
    )
  IS
--
--###########################  固定部 START   ###########################
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'main';  -- プログラム名
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
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ===============================================
    submain
    (
      iv_year          => iv_year           -- 01.年度
     ,iv_prod_div      => iv_prod_div       -- 02.商品区分
     ,iv_gen           => iv_gen            -- 03.世代
     ,iv_output_unit   => iv_output_unit    -- 04.出力単位
     ,iv_output_type   => iv_output_type    -- 05.出力種別
     ,iv_base_01       => iv_base_01        -- 06.拠点１
     ,iv_base_02       => iv_base_02        -- 07.拠点２
     ,iv_base_03       => iv_base_03        -- 08.拠点３
     ,iv_base_04       => iv_base_04        -- 09.拠点４
     ,iv_base_05       => iv_base_05        -- 10.拠点５
     ,iv_base_06       => iv_base_06        -- 11.拠点６
     ,iv_base_07       => iv_base_07        -- 12.拠点７
     ,iv_base_08       => iv_base_08        -- 13.拠点８
     ,iv_base_09       => iv_base_09        -- 14.拠点９
     ,iv_base_10       => iv_base_10        -- 15.拠点１０
     ,iv_crowd_code_01 => iv_crowd_code_01  -- 16.群コード１
     ,iv_crowd_code_02 => iv_crowd_code_02  -- 17.群コード２
     ,iv_crowd_code_03 => iv_crowd_code_03  -- 18.群コード３
     ,iv_crowd_code_04 => iv_crowd_code_04  -- 19.群コード４
     ,iv_crowd_code_05 => iv_crowd_code_05  -- 20.群コード５
     ,iv_crowd_code_06 => iv_crowd_code_06  -- 21.群コード６
     ,iv_crowd_code_07 => iv_crowd_code_07  -- 22.群コード７
     ,iv_crowd_code_08 => iv_crowd_code_08  -- 23.群コード８
     ,iv_crowd_code_09 => iv_crowd_code_09  -- 24.群コード９
     ,iv_crowd_code_10 => iv_crowd_code_10  -- 25.群コード１０
     ,ov_errbuf        => lv_errbuf         -- エラー・メッセージ           --# 固定 #
     ,ov_retcode       => lv_retcode        -- リターン・コード             --# 固定 #
     ,ov_errmsg        => lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
--###########################  固定部 START   #####################################################
--
    -- ======================
    -- エラー・メッセージ出力
    -- ======================
    IF (lv_retcode = gv_status_error) THEN
      errbuf := lv_errmsg;
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf);
--
    ELSIF (lv_retcode = gv_status_warn) THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf);
--
    END IF;
--
    --ステータスセット
    retcode := lv_retcode;
--
  EXCEPTION
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
      retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
      retcode := gv_status_error;
  END main;
--
--###########################  固定部 END   #######################################################
--
END xxinv100002c;
/