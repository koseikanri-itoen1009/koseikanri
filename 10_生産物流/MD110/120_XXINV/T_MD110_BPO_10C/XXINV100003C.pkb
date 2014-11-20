CREATE OR REPLACE PACKAGE BODY xxinv100003c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : XXINV100003C(body)
 * Description      : 販売計画時系列表
 * MD.050/070       : 販売計画・引取計画 (T_MD050_BPO_100)
 *                    販売計画時系列表   (T_MD070_BPO_10C)
 * Version          : 1.8
 *
 * Program List
 * ---------------------------- ----------------------------------------------------------------
 *  Name                         Description
 * ---------------------------- ----------------------------------------------------------------
 *  pro_get_cus_option           P データ取得    - カスタムオプション取得             (C-1-0)
 *  prc_sale_plan                P データ抽出    - 販売計画時系列表情報抽出(全拠点時) (C-1-1)
 *  prc_sale_plan_1              P データ抽出    - 販売計画時系列表情報抽出(拠点時)   (C-1-2)
 *  prc_create_xml_data_user     P XMLデータ変換 - ユーザー情報部分    (user_info)
 *  prc_create_xml_data_param    P XMLデータ変換 - パラメータ情報部分  (param_info)
 *  prc_create_xml_data          P XMLデータ作成 - 帳票データ出力
 *  prc_create_xml_data_dtl      P XMLデータ作成 - 帳票データ出力 明細行 データ有
 *  prc_create_xml_data_dtl_n    P XMLデータ作成 - 帳票データ出力 明細行 データ無
 *  prc_create_xml_data_st_lt    P XMLデータ作成 - 帳票データ出力 小群計/大群計用
 *  prc_create_xml_data_s_k_t    P XMLデータ作成 - 帳票データ出力 拠点計/商品区分計/総合計用
 *  submain                      P メイン処理プロシージャ
 *  main                         P コンカレント実行ファイル登録プロシージャ
 *
 *  convert_into_xml             F XMLデータ変換
 *
 * Change Record
 * ------------- ----- ---------------- --------------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- --------------------------------------------------------
 *  2008/02/15   1.0   Tatsuya Kurata   新規作成
 *  2008/04/23   1.1   Masanobu Kimura  内部変更要求#27
 *  2008/04/28   1.2   Sumie Nakamura   仕入･標準単価ヘッダ(アドオン)抽出条件漏れ対応
 *  2008/04/30   1.3   Yuko Kawano      内部変更要求#62,76
 *  2008/05/28   1.4   Kazuo Kumamoto   規約違反(varchar使用)対応
 *  2008/07/02   1.5   Satoshi Yunba    禁則文字対応
 *  2009/04/16   1.6   吉元 強樹        本番障害対応(No.1410)
 *  2009/05/29   1.7   吉元 強樹        本番障害対応(No.1509)
 *  2009/10/05   1.8   吉元 強樹        本番障害対応(No.1648)
 *****************************************************************************************/
--
--#######################  固定グローバル定数宣言部 START  #######################
--
  gv_status_normal CONSTANT VARCHAR2(1) := '0';
  gv_status_warn   CONSTANT VARCHAR2(1) := '1';
  gv_status_error  CONSTANT VARCHAR2(1) := '2';
  gv_msg_part      CONSTANT VARCHAR2(3) := ' : ';
  gv_msg_cont      CONSTANT VARCHAR2(3) := '.';
--
--##################################  固定部 END  ################################
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
     ,output_unit      VARCHAR2(6)    -- 出力単位
--2008.04.30 Y.Kawano modify start
--     ,output_type      VARCHAR2(6)    -- 出力種別
     ,output_type      VARCHAR2(8)    -- 出力種別
--2008.04.30 Y.Kawano modify end
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
  -- 販売計画時系列表情報取得データ格納用レコード変数(全拠点用)
  TYPE rec_sale_plan IS RECORD 
    (
       skbn              xxcmn_item_categories2_v.segment1%TYPE      -- 商品区分
      ,skbn_name         xxcmn_item_categories2_v.description%TYPE   -- 商品区分(名称)
      ,gun               xxcmn_item_categories2_v.segment1%TYPE      -- 群コード
      ,item_no           xxcmn_item_mst2_v.item_no%TYPE              -- 品目(コード)
      ,item_short_name   xxcmn_item_mst2_v.item_short_name%TYPE      -- 品目(名称)
      ,case_quant        xxcmn_item_mst2_v.num_of_cases%TYPE         -- 入数
      ,quant             mrp_forecast_dates.attribute4%TYPE          -- 数量
      ,amount            mrp_forecast_dates.attribute2%TYPE          -- 金額
      ,total_amount      xxpo_price_headers.total_amount%TYPE        -- 内訳合計
      ,o_amount          xxcmn_item_mst2_v.old_price%TYPE            -- 旧・定価
      ,n_amount          xxcmn_item_mst2_v.new_price%TYPE            -- 新・定価
      ,price_st          xxcmn_item_mst2_v.price_start_date%TYPE     -- 定価適用開始日
      ,month             VARCHAR2(10)                                -- Forecast日付(月のみ)
    );
  TYPE tab_data_sale_plan IS TABLE OF rec_sale_plan INDEX BY BINARY_INTEGER;
--
  -- 販売計画時系列表情報取得データ格納用レコード変数(拠点用)
  TYPE rec_sale_plan_1 IS RECORD 
    (
       skbn              xxcmn_item_categories2_v.segment1%TYPE      -- 商品区分
      ,skbn_name         xxcmn_item_categories2_v.description%TYPE   -- 商品区分(名称)
      ,gun               xxcmn_item_categories2_v.segment1%TYPE      -- 群コード
      ,item_no           xxcmn_item_mst2_v.item_no%TYPE              -- 品目(コード)
      ,item_short_name   xxcmn_item_mst2_v.item_short_name%TYPE      -- 品目(名称)
      ,case_quant        xxcmn_item_mst2_v.num_of_cases%TYPE         -- 入数
      ,quant             mrp_forecast_dates.attribute4%TYPE          -- 数量
      ,amount            mrp_forecast_dates.attribute2%TYPE          -- 金額
      ,ktn_code          mrp_forecast_dates.attribute5%TYPE          -- 拠点コード
      ,party_short_name  xxcmn_parties_v.party_short_name%TYPE       -- 拠点名称
      ,total_amount      xxpo_price_headers.total_amount%TYPE        -- 内訳合計
      ,o_amount          xxcmn_item_mst2_v.old_price%TYPE            -- 旧・定価
      ,n_amount          xxcmn_item_mst2_v.new_price%TYPE            -- 新・定価
      ,price_st          xxcmn_item_mst2_v.price_start_date%TYPE     -- 定価適用開始日
      ,month             VARCHAR2(10)                                -- Forecast日付(月のみ)
    );
  TYPE tab_data_sale_plan_1 IS TABLE OF rec_sale_plan_1 INDEX BY BINARY_INTEGER;
--
  -- 各集計項目用
  TYPE add_total IS RECORD
    (
      may_quant      NUMBER     -- ５月 数量
     ,may_amount     NUMBER     -- ５月 金額
     ,may_price      NUMBER     -- ５月 品目定価
     ,may_to_amount  NUMBER     -- ５月 内訳合計
     ,may_quant_t    NUMBER     -- ５月 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
     ,may_s_cost     NUMBER     -- ５月 標準原価(計算用)
     ,may_calc       NUMBER     -- ５月 品目定価*数量(計算用)
     ,may_minus_flg   VARCHAR2(1)  -- ５月 数量マイナス値存在フラグ(計算用)
     ,may_ht_zero_flg VARCHAR2(1)  -- ５月 品目定価0値存在フラグ(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
     ,jun_quant      NUMBER     -- ６月 数量
     ,jun_amount     NUMBER     -- ６月 金額
     ,jun_price      NUMBER     -- ６月 品目定価
     ,jun_to_amount  NUMBER     -- ６月 内訳合計
     ,jun_quant_t    NUMBER     -- ６月 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
     ,jun_s_cost     NUMBER     -- ６月 標準原価(計算用)
     ,jun_calc       NUMBER     -- ６月 品目定価*数量(計算用)
     ,jun_minus_flg   VARCHAR2(1)  -- ６月 数量マイナス値存在フラグ(計算用)
     ,jun_ht_zero_flg VARCHAR2(1)  -- ６月 品目定価0値存在フラグ(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
     ,jul_quant      NUMBER     -- ７月 数量
     ,jul_amount     NUMBER     -- ７月 金額
     ,jul_price      NUMBER     -- ７月 品目定価
     ,jul_to_amount  NUMBER     -- ７月 内訳合計
     ,jul_quant_t    NUMBER     -- ７月 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
     ,jul_s_cost     NUMBER     -- ７月 標準原価(計算用)
     ,jul_calc       NUMBER     -- ７月 品目定価*数量(計算用)
     ,jul_minus_flg   VARCHAR2(1)  -- ７月 数量マイナス値存在フラグ(計算用)
     ,jul_ht_zero_flg VARCHAR2(1)  -- ７月 品目定価0値存在フラグ(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
     ,aug_quant      NUMBER     -- ８月 数量
     ,aug_amount     NUMBER     -- ８月 金額
     ,aug_price      NUMBER     -- ８月 品目定価
     ,aug_to_amount  NUMBER     -- ８月 内訳合計
     ,aug_quant_t    NUMBER     -- ８月 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
     ,aug_s_cost     NUMBER     -- ８月  標準原価(計算用)
     ,aug_calc       NUMBER     -- ８月 品目定価*数量(計算用)
     ,aug_minus_flg   VARCHAR2(1)  -- ８月 数量マイナス値存在フラグ(計算用)
     ,aug_ht_zero_flg VARCHAR2(1)  -- ８月 品目定価0値存在フラグ(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
     ,sep_quant      NUMBER     -- ９月 数量
     ,sep_amount     NUMBER     -- ９月 金額
     ,sep_price      NUMBER     -- ９月 品目定価
     ,sep_to_amount  NUMBER     -- ９月 内訳合計
     ,sep_quant_t    NUMBER     -- ９月 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
     ,sep_s_cost     NUMBER     -- ９月 標準原価(計算用)
     ,sep_calc       NUMBER     -- ９月 品目定価*数量(計算用)
     ,sep_minus_flg   VARCHAR2(1)  -- ９月 数量マイナス値存在フラグ(計算用)
     ,sep_ht_zero_flg VARCHAR2(1)  -- ９月 品目定価0値存在フラグ(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
     ,oct_quant      NUMBER     -- １０月 数量
     ,oct_amount     NUMBER     -- １０月 金額
     ,oct_price      NUMBER     -- １０月 品目定価
     ,oct_to_amount  NUMBER     -- １０月 内訳合計
     ,oct_quant_t    NUMBER     -- １０月 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
     ,oct_s_cost     NUMBER     -- １０月 標準原価(計算用)
     ,oct_calc       NUMBER     -- １０月 品目定価*数量(計算用)
     ,oct_minus_flg   VARCHAR2(1)  -- １０月 数量マイナス値存在フラグ(計算用)
     ,oct_ht_zero_flg VARCHAR2(1)  -- １０月 品目定価0値存在フラグ(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
     ,nov_quant      NUMBER     -- １１月 数量
     ,nov_amount     NUMBER     -- １１月 金額
     ,nov_price      NUMBER     -- １１月 品目定価
     ,nov_to_amount  NUMBER     -- １１月 内訳合計
     ,nov_quant_t    NUMBER     -- １１月 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
     ,nov_s_cost     NUMBER     -- １１月 標準原価(計算用)
     ,nov_calc       NUMBER     -- １１月 品目定価*数量(計算用)
     ,nov_minus_flg   VARCHAR2(1)  -- １１月 数量マイナス値存在フラグ(計算用)
     ,nov_ht_zero_flg VARCHAR2(1)  -- １１月 品目定価0値存在フラグ(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
     ,dec_quant      NUMBER     -- １２月 数量
     ,dec_amount     NUMBER     -- １２月 金額
     ,dec_price      NUMBER     -- １２月 品目定価
     ,dec_to_amount  NUMBER     -- １２月 内訳合計
     ,dec_quant_t    NUMBER     -- １２月 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
     ,dec_s_cost     NUMBER     -- １２月 標準原価(計算用)
     ,dec_calc       NUMBER     -- １２月 品目定価*数量(計算用)
     ,dec_minus_flg   VARCHAR2(1)  -- １２月 数量マイナス値存在フラグ(計算用)
     ,dec_ht_zero_flg VARCHAR2(1)  -- １２月 品目定価0値存在フラグ(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
     ,jan_quant      NUMBER     -- １月 数量
     ,jan_amount     NUMBER     -- １月 金額
     ,jan_price      NUMBER     -- １月 品目定価
     ,jan_to_amount  NUMBER     -- １月 内訳合計
     ,jan_quant_t    NUMBER     -- １月 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
     ,jan_s_cost     NUMBER     -- １月 標準原価(計算用)
     ,jan_calc       NUMBER     -- １月 品目定価*数量(計算用)
     ,jan_minus_flg   VARCHAR2(1)  -- １月 数量マイナス値存在フラグ(計算用)
     ,jan_ht_zero_flg VARCHAR2(1)  -- １月 品目定価0値存在フラグ(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
     ,feb_quant      NUMBER     -- ２月 数量
     ,feb_amount     NUMBER     -- ２月 金額
     ,feb_price      NUMBER     -- ２月 品目定価
     ,feb_to_amount  NUMBER     -- ２月 内訳合計
     ,feb_quant_t    NUMBER     -- ２月 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
     ,feb_s_cost     NUMBER     -- ２月 標準原価(計算用)
     ,feb_calc       NUMBER     -- ２月 品目定価*数量(計算用)
     ,feb_minus_flg   VARCHAR2(1)  -- ２月 数量マイナス値存在フラグ(計算用)
     ,feb_ht_zero_flg VARCHAR2(1)  -- ２月 品目定価0値存在フラグ(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
     ,mar_quant      NUMBER     -- ３月 数量
     ,mar_amount     NUMBER     -- ３月 金額
     ,mar_price      NUMBER     -- ３月 品目定価
     ,mar_to_amount  NUMBER     -- ３月 内訳合計
     ,mar_quant_t    NUMBER     -- ３月 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
     ,mar_s_cost     NUMBER     -- ３月 標準原価(計算用)
     ,mar_calc       NUMBER     -- ３月 品目定価*数量(計算用)
     ,mar_minus_flg   VARCHAR2(1)  -- ３月 数量マイナス値存在フラグ(計算用)
     ,mar_ht_zero_flg VARCHAR2(1)  -- ３月 品目定価0値存在フラグ(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
     ,apr_quant      NUMBER     -- ４月 数量
     ,apr_amount     NUMBER     -- ４月 金額
     ,apr_price      NUMBER     -- ４月 品目定価
     ,apr_to_amount  NUMBER     -- ４月 売上合計
     ,apr_quant_t    NUMBER     -- ４月 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
     ,apr_s_cost     NUMBER     -- ４月 標準原価(計算用)
     ,apr_calc       NUMBER     -- ４月 品目定価*数量(計算用)
     ,apr_minus_flg   VARCHAR2(1)  -- ４月 数量マイナス値存在フラグ(計算用)
     ,apr_ht_zero_flg VARCHAR2(1)  -- ４月 品目定価0値存在フラグ(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
     ,year_quant     NUMBER     -- 年計 数量
     ,year_amount    NUMBER     -- 年計 金額
     ,year_price     NUMBER     -- 年計 品目定価
     ,year_to_amount NUMBER     -- 年計 内訳合計
     ,year_quant_t   NUMBER     -- 年計 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
     ,year_s_cost    NUMBER     -- 年計 標準原価(計算用)
     ,year_calc      NUMBER     -- 年計 品目定価*数量(計算用)
     ,year_minus_flg   VARCHAR2(1)  -- 年計 数量マイナス値存在フラグ(計算用)
     ,year_ht_zero_flg VARCHAR2(1)  -- 年計 品目定価0値存在フラグ(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
    );
  TYPE tab_add_total IS TABLE OF add_total INDEX BY PLS_INTEGER;
--
  -- XML出力判定
  TYPE xml_out IS RECORD
    (
--mod start 1.4
--      tag_name       VARCHAR(5)     -- タグネーム
--     ,out_fg         VARCHAR(1)     -- 出力判定用
      tag_name       VARCHAR2(5)     -- タグネーム
     ,out_fg         VARCHAR2(1)     -- 出力判定用
--mod end 1.4
    );
  TYPE tab_xml_out IS TABLE OF xml_out INDEX BY PLS_INTEGER;
  
  -- ==================================================
  -- ユーザー定義グローバル定数
  -- ==================================================
  gv_pkg_name         CONSTANT VARCHAR2(20) := 'XXINV100003C';           -- パッケージ名
  gv_prf_start_day    CONSTANT VARCHAR2(30) := 'XXCMN_PERIOD_START_DAY'; -- XXCMN:年度開始月日
  gv_prf_prod         CONSTANT VARCHAR2(50) := 'XXCMN_ITEM_DIV';         -- XXCMN:商品区分
  gv_prf_crowd        CONSTANT VARCHAR2(50) := 'XXCMN_CATEGORY_NAME_OTGUN';
                                                           -- XXCMN:カテゴリセット名(群コード)
--2008.04.30 Y.Kawano add start
  gv_master_org_id    CONSTANT VARCHAR2(30)  := 'XXCMN_MASTER_ORG_ID';    --XXCMN:マスタ組織ID
--2008.04.30 Y.Kawano add end
  gv_name_sale_plan   CONSTANT VARCHAR2(2)  := '05';                     -- '販売計画'
  gv_prod_div_leaf    CONSTANT VARCHAR2(1)  := '1';                      -- 'リーフ'
  gv_prod_div_drink   CONSTANT VARCHAR2(1)  := '2';                      -- 'ドリンク'
  gv_output_unit      CONSTANT VARCHAR2(1)  := '0';                      -- '本数'
-- ＳＱＬ作成用
  gv_sql_l_block      CONSTANT VARCHAR2(2)  := ' (';                     -- 左括弧'('
  gv_sql_r_block      CONSTANT VARCHAR2(2)  := ') ';                     -- 右括弧')'
  gv_sql_dot          CONSTANT VARCHAR2(3)  := ' , ';                    -- カンマ','
-- 帳票表示用
  gv_report_id        CONSTANT VARCHAR2(12) := 'XXINV100003T';           -- 帳票ID
  gv_name_year        CONSTANT VARCHAR2(10) := '年度';
  gv_name_all_ktn     CONSTANT VARCHAR2(10) := '全拠点';
  gv_output_unit_0    CONSTANT VARCHAR2(10) := '本数';                   -- 出力単位 '0'
  gv_output_unit_1    CONSTANT VARCHAR2(10) := 'ケース';                 -- 出力単位 '1'
  gv_label_st         CONSTANT VARCHAR2(10) := '【小群計】';
  gv_label_lt         CONSTANT VARCHAR2(10) := '【大群計】';
-- エラーコード
  gv_application      CONSTANT VARCHAR2(5)  := 'XXCMN';                  -- アプリケーション
  gv_tkn_pro          CONSTANT VARCHAR2(15) := 'PROFILE';                -- プロファイル名
  gv_err_code_no_data CONSTANT VARCHAR2(20) := 'APP-XXCMN-10122';        -- 帳票０件メッセージ
  gv_err_pro          CONSTANT VARCHAR2(20) := 'APP-XXCMN-10002';
                                                           -- プロファイル取得エラーメッセージ
-- 出力タグネーム
  gv_name_may         CONSTANT VARCHAR2(4)  := 'may_';                   -- ５月
  gv_name_jun         CONSTANT VARCHAR2(4)  := 'jun_';                   -- ６月
  gv_name_jul         CONSTANT VARCHAR2(4)  := 'jul_';                   -- ７月
  gv_name_aug         CONSTANT VARCHAR2(4)  := 'aug_';                   -- ８月
  gv_name_sep         CONSTANT VARCHAR2(4)  := 'sep_';                   -- ９月
  gv_name_oct         CONSTANT VARCHAR2(4)  := 'oct_';                   -- １０月
  gv_name_nov         CONSTANT VARCHAR2(4)  := 'nov_';                   -- １１月
  gv_name_dec         CONSTANT VARCHAR2(4)  := 'dec_';                   -- １２月
  gv_name_jan         CONSTANT VARCHAR2(4)  := 'jan_';                   -- １月
  gv_name_feb         CONSTANT VARCHAR2(4)  := 'feb_';                   -- ２月
  gv_name_mar         CONSTANT VARCHAR2(4)  := 'mar_';                   -- ３月
  gv_name_apr         CONSTANT VARCHAR2(4)  := 'apr_';                   -- ４月
  gv_name_st          CONSTANT VARCHAR2(3)  := 'st_';                    -- 小群計用
  gv_name_lt          CONSTANT VARCHAR2(3)  := 'lt_';                    -- 大群計用
  gv_name_ktn         CONSTANT VARCHAR2(4)  := 'ktn_';                   -- 拠点用
  gv_name_skbn        CONSTANT VARCHAR2(5)  := 'skbn_';                  -- 商品区分用
  gv_name_ttl         CONSTANT VARCHAR2(4)  := 'ttl_';                   -- 総合計用
--
  gn_0                NUMBER                := 0;                        -- 0
  gn_kotei_70         NUMBER(6,2)           := 70.00;                    -- 固定値(掛率％)
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gd_start_day          DATE;                 -- 年度開始月日
  gv_name_prod          VARCHAR2(10);         -- 商品区分
  gv_name_crowd         VARCHAR2(10);         -- 群コード
--2008.04.30 Y.Kawano add start
  gn_org_id             NUMBER;            -- マスタ組織ID
--2008.04.30 Y.Kawano add end
-- ＳＱＬ作成用
  gv_sql_sel            VARCHAR2(9000);       -- SQL組合せ用
  gv_sql_select         VARCHAR2(5000);       -- SELECT句
  gv_sql_from           VARCHAR2(5000);       -- FROM句
  gv_sql_where          VARCHAR2(6000);       -- WHERE句
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
  gv_sql_group_by       VARCHAR2(5000);       -- GROUP BY句
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
  gv_sql_order_by       VARCHAR2(5000);       -- ORDER BY句
  gv_sql_prod_div       VARCHAR2(5000);       -- 商品区分(入力Ｐ有)
  gv_sql_prod_div_n     VARCHAR2(5000);       -- 商品区分(入力Ｐ無)
  gv_sql_crowd_code     VARCHAR2(5000);       -- 群コード(入力Ｐ有)
-- 群コード入力Ｐ用
  gv_sql_crowd_code_01  VARCHAR2(50);         -- 群コード１
  gv_sql_crowd_code_02  VARCHAR2(50);         -- 群コード２
  gv_sql_crowd_code_03  VARCHAR2(50);         -- 群コード３
  gv_sql_crowd_code_04  VARCHAR2(50);         -- 群コード４
  gv_sql_crowd_code_05  VARCHAR2(50);         -- 群コード５
  gv_sql_crowd_code_06  VARCHAR2(50);         -- 群コード６
  gv_sql_crowd_code_07  VARCHAR2(50);         -- 群コード７
  gv_sql_crowd_code_08  VARCHAR2(50);         -- 群コード８
  gv_sql_crowd_code_09  VARCHAR2(50);         -- 群コード９
  gv_sql_crowd_code_10  VARCHAR2(50);         -- 群コード１０
--
  gl_xml_idx            NUMBER;               -- ＸＭＬデータタグ表のインデックス
  gt_xml_data_table     XML_DATA;             -- ＸＭＬデータタグ表
  gr_param              rec_param_data ;      -- 入力パラメータ
  gr_sale_plan          tab_data_sale_plan;   -- 全拠点用
  gr_sale_plan_1        tab_data_sale_plan_1; -- 拠点用
  gr_add_total          tab_add_total;        -- 集計用項目
  gr_xml_out            tab_xml_out;          -- XML出力判定用
--
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
   * Description      : カスタムオプション取得  (C-1-0)
   ***********************************************************************************/
  PROCEDURE pro_get_cus_option
    (
      ov_errbuf     OUT VARCHAR2     -- エラー・メッセージ           --# 固定 #
     ,ov_retcode    OUT VARCHAR2     -- リターン・コード             --# 固定 #
     ,ov_errmsg     OUT VARCHAR2     -- ユーザー・エラー・メッセージ --# 固定 #
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
    --------------------------------------
    -- プロファイルから年度開始月日取得
    --------------------------------------
    lv_start_day := SUBSTRB(FND_PROFILE.VALUE(gv_prf_start_day),1,5);
    -- 取得エラー時
    IF (lv_start_day IS NULL) THEN
      lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg(gv_application     -- 'XXCMN'
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
    --------------------------------------
    -- プロファイルから商品区分取得
    --------------------------------------
    gv_name_prod := SUBSTRB(FND_PROFILE.VALUE(gv_prf_prod),1,30);
    -- 取得エラー時
    IF (gv_name_prod IS NULL) THEN
      lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg(gv_application    -- 'XXCMN'
                                                    ,gv_err_pro        -- プロファイル取得エラー
                                                    ,gv_tkn_pro        -- トークン'PROFILE'
                                                    ,gv_prf_prod)      -- XXCMN:商品区分
                                                    ,1
                                                    ,5000);
      RAISE global_api_expt;
    END IF;
--
    --------------------------------------
    -- プロファイルから群コード取得
    --------------------------------------
    gv_name_crowd := SUBSTRB(FND_PROFILE.VALUE(gv_prf_crowd),1,30);
    -- 取得エラー時
    IF (gv_name_crowd IS NULL) THEN
      lv_errmsg   := SUBSTRB(xxcmn_common_pkg.get_msg(gv_application    -- 'XXCMN'
                                                     ,gv_err_pro        -- プロファイル取得エラー
                                                     ,gv_tkn_pro        -- トークン'PROFILE'
                                                     ,gv_prf_crowd)
                                                              -- XXCMN:カテゴリセット名(群コード)
                                                     ,1
                                                     ,5000);
      RAISE global_api_expt;
    END IF;
--
--2008.04.30 Y.Kawano add start
--FND_FILE.PUT_LINE(FND_FILE.LOG,'プロファイル取得');
    -- プロファイルからXXCMN:マスタ組織ID取得
    gn_org_id := TO_NUMBER(FND_PROFILE.VALUE(gv_master_org_id));
--FND_FILE.PUT_LINE(FND_FILE.LOG,'プロファイル取得後：org_id='|| gn_org_id);
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
--2008.04.30 Y.Kawano add end
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
   * Description      : データ抽出 - 販売計画時系列表情報抽出(全拠点時) (C-1-1)
   ***********************************************************************************/
  PROCEDURE prc_sale_plan
    (
      ot_sale_plan  OUT NOCOPY tab_data_sale_plan -- 取得レコード群
     ,ov_errbuf     OUT VARCHAR2                  -- エラー・メッセージ           --# 固定 #
     ,ov_retcode    OUT VARCHAR2                  -- リターン・コード             --# 固定 #
     ,ov_errmsg     OUT VARCHAR2                  -- ユーザー・エラー・メッセージ --# 固定 #
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
    gv_sql_select := 'SELECT xicv1.segment1                 AS skbn            -- 商品区分
                            ,xicv1.description              AS skbn_name       -- 商品区分(名称)
                            ,xicv.segment1                  AS gun             -- 群コード
                            ,ximv.item_no                   AS item_no         -- 品目(コード)
                            ,ximv.item_short_name           AS item_short_name -- 品目(名称)
                            ,ximv.num_of_cases              AS case_quant      -- 入数
-- 2009/04/16 v1.6 T.Yoshimoto Mod Start 本番#1410
                            --,mfd.attribute4                 AS quant           -- 数量
                            --,mfd.attribute2                 AS amount          -- 金額
                            ,SUM(mfd.attribute4)            AS quant           -- 数量
                            ,SUM(mfd.attribute2)            AS amount          -- 金額
-- 2009/04/16 v1.6 T.Yoshimoto Mod End 本番#1410
                            ,xph.total_amount               AS total_amount    -- 内訳合計
                            ,ximv.old_price                 AS o_amount        -- 旧・定価
                            ,ximv.new_price                 AS n_amount        -- 新・定価
                            ,ximv.price_start_date          AS price_st        -- 定価適用開始日
                            ,SUBSTRB(mfd.forecast_date,4,3) AS month      -- forecast日付(月のみ)
                     ';
--
    -- FROM句
    gv_sql_from   := ' FROM mrp_forecast_designators  mfds    -- Forecast名
                           ,mrp_forecast_dates        mfd     -- Forecast日付
                           ,xxpo_price_headers        xph     -- 仕入/標準単価ヘッダ(アドオン)
                           ,xxcmn_item_categories2_v  xicv    -- OPM品目カテゴリ割当情報VIEW
                           ,xxcmn_item_categories2_v  xicv1   -- OPM品目カテゴリ割当情報VIEW(商)
                           ,xxcmn_item_mst2_v         ximv    -- OPM品目情報VIEW
                     ';
--
    -- WHERE句
    gv_sql_where  := ' WHERE mfds.attribute1          = :para_name_sale_plan      -- 販売計画
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
                       AND   ximv.item_no             = xicv.item_no
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
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
    -- GROUP BY句
    gv_sql_group_by      := ' GROUP BY xicv1.segment1                    -- 商品区分
                                     ,xicv1.description                 -- 商品区分(名称)
                                     ,xicv.segment1                     -- 群コード
                                     ,ximv.item_no                      -- 品目(コード)
                                     ,ximv.item_short_name              -- 品目(名称)
                                     ,ximv.num_of_cases                 -- 入数
                                     ,xph.total_amount                  -- 内訳合計
                                     ,ximv.old_price                    -- 旧・定価
                                     ,ximv.new_price                    -- 新・定価
                                     ,ximv.price_start_date             -- 定価適用開始日
                                     ,mfd.forecast_date ';  -- forecast日付(月のみ)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
--
    -- ORDER BY句
    gv_sql_order_by      := ' ORDER BY xicv1.segment1       -- 商品区分
                                      ,xicv.segment1        -- 群コード
                                      ,ximv.item_no         -- 品目
                                      ,mfd.forecast_date';  -- forecast日付
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
    IF ((gr_param.crowd_code_01 IS NOT NULL)
      OR (gr_param.crowd_code_02 IS NOT NULL)
        OR (gr_param.crowd_code_03 IS NOT NULL)
          OR (gr_param.crowd_code_04 IS NOT NULL)
            OR (gr_param.crowd_code_05 IS NOT NULL)
              OR (gr_param.crowd_code_06 IS NOT NULL)
                OR (gr_param.crowd_code_07 IS NOT NULL)
                  OR (gr_param.crowd_code_08 IS NOT NULL)
                    OR (gr_param.crowd_code_09 IS NOT NULL)
                      OR (gr_param.crowd_code_10 IS NOT NULL)) THEN
      -- 群コード抽出条件 + 左括弧
      gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_l_block;
      -- 入力Ｐ 群コード１に入力有
      IF (gr_param.crowd_code_01 IS NOT NULL) THEN
        gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_crowd_code_01;
      END IF;
      -- 入力Ｐ 群コード２に入力有
      IF ((gr_param.crowd_code_02 IS NOT NULL)
        AND (gr_param.crowd_code_01 IS NULL)) THEN
        gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_crowd_code_02;
      ELSIF (gr_param.crowd_code_02 IS NOT NULL) THEN
        gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_dot || gv_sql_crowd_code_02;
      END IF;
      -- 入力Ｐ 群コード３に入力有
      IF ((gr_param.crowd_code_03 IS NOT NULL)
        AND (gr_param.crowd_code_01 IS NULL)
          AND (gr_param.crowd_code_02 IS NULL)) THEN
        gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_crowd_code_03;
      ELSIF (gr_param.crowd_code_03 IS NOT NULL) THEN
        gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_dot || gv_sql_crowd_code_03;
      END IF;
      -- 入力Ｐ 群コード４に入力有
      IF ((gr_param.crowd_code_04 IS NOT NULL)
        AND (gr_param.crowd_code_01 IS NULL)
          AND (gr_param.crowd_code_02 IS NULL)
            AND (gr_param.crowd_code_03 IS NULL)) THEN
        gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_crowd_code_04;
      ELSIF (gr_param.crowd_code_04 IS NOT NULL) THEN
        gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_dot || gv_sql_crowd_code_04;
      END IF;
      -- 入力Ｐ 群コード５に入力有
      IF ((gr_param.crowd_code_05 IS NOT NULL)
        AND (gr_param.crowd_code_01 IS NULL)
          AND (gr_param.crowd_code_02 IS NULL)
            AND (gr_param.crowd_code_03 IS NULL)
              AND (gr_param.crowd_code_04 IS NULL)) THEN
        gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_crowd_code_05;
      ELSIF (gr_param.crowd_code_05 IS NOT NULL) THEN
        gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_dot || gv_sql_crowd_code_05;
      END IF;
      -- 入力Ｐ 群コード６に入力有
      IF ((gr_param.crowd_code_06 IS NOT NULL)
        AND (gr_param.crowd_code_01 IS NULL)
          AND (gr_param.crowd_code_02 IS NULL)
            AND (gr_param.crowd_code_03 IS NULL)
              AND (gr_param.crowd_code_04 IS NULL)
                AND (gr_param.crowd_code_05 IS NULL)) THEN
        gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_crowd_code_06;
      ELSIF (gr_param.crowd_code_06 IS NOT NULL) THEN
        gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_dot || gv_sql_crowd_code_06;
      END IF;
      -- 入力Ｐ 群コード７に入力有
      IF ((gr_param.crowd_code_07 IS NOT NULL)
        AND (gr_param.crowd_code_01 IS NULL)
          AND (gr_param.crowd_code_02 IS NULL)
            AND (gr_param.crowd_code_03 IS NULL)
              AND (gr_param.crowd_code_04 IS NULL)
                AND (gr_param.crowd_code_05 IS NULL)
                  AND (gr_param.crowd_code_06 IS NULL)) THEN
        gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_crowd_code_07;
      ELSIF (gr_param.crowd_code_07 IS NOT NULL) THEN
        gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_dot || gv_sql_crowd_code_07;
      END IF;
      -- 入力Ｐ 群コード８に入力有
      IF ((gr_param.crowd_code_08 IS NOT NULL)
        AND (gr_param.crowd_code_01 IS NULL)
          AND (gr_param.crowd_code_02 IS NULL)
            AND (gr_param.crowd_code_03 IS NULL)
              AND (gr_param.crowd_code_04 IS NULL)
                AND (gr_param.crowd_code_05 IS NULL)
                  AND (gr_param.crowd_code_06 IS NULL)
                    AND (gr_param.crowd_code_07 IS NULL)) THEN
        gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_crowd_code_08;
      ELSIF (gr_param.crowd_code_08 IS NOT NULL) THEN
        gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_dot || gv_sql_crowd_code_08;
      END IF;
      -- 入力Ｐ 群コード９に入力有
      IF ((gr_param.crowd_code_09 IS NOT NULL)
        AND (gr_param.crowd_code_01 IS NULL)
          AND (gr_param.crowd_code_02 IS NULL)
            AND (gr_param.crowd_code_03 IS NULL)
              AND (gr_param.crowd_code_04 IS NULL)
                AND (gr_param.crowd_code_05 IS NULL)
                  AND (gr_param.crowd_code_06 IS NULL)
                    AND (gr_param.crowd_code_07 IS NULL)
                      AND (gr_param.crowd_code_08 IS NULL)) THEN
        gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_crowd_code_09;
      ELSIF (gr_param.crowd_code_09 IS NOT NULL) THEN
        gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_dot || gv_sql_crowd_code_09;
      END IF;
      -- 入力Ｐ 群コード１０に入力有
      IF ((gr_param.crowd_code_10 IS NOT NULL)
        AND (gr_param.crowd_code_01 IS NULL)
          AND (gr_param.crowd_code_02 IS NULL)
            AND (gr_param.crowd_code_03 IS NULL)
              AND (gr_param.crowd_code_04 IS NULL)
                AND (gr_param.crowd_code_05 IS NULL)
                  AND (gr_param.crowd_code_06 IS NULL)
                    AND (gr_param.crowd_code_07 IS NULL)
                      AND (gr_param.crowd_code_08 IS NULL)
                        AND (gr_param.crowd_code_09 IS NULL)) THEN
        gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_crowd_code_10;
      ELSIF (gr_param.crowd_code_10 IS NOT NULL) THEN
        gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_dot || gv_sql_crowd_code_10;
      END IF;
      -- 群コード抽出条件 + 右括弧
      gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_r_block;
      -- 作成ＳＱＬ文に群コード抽出条件結合
      gv_sql_sel        := gv_sql_sel || gv_sql_crowd_code;
    END IF;
--
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
    -- GROUP BY句結合
    gv_sql_sel := gv_sql_sel || gv_sql_group_by;
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
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
  END prc_sale_plan;
--
  /**********************************************************************************
   * Procedure Name   : prc_sale_plan_1
   * Description      : データ抽出 - 販売計画時系列表情報抽出(拠点時) (C-1-2)
   ***********************************************************************************/
  PROCEDURE prc_sale_plan_1
    (
      ot_sale_plan_1 OUT NOCOPY tab_data_sale_plan_1 -- 取得レコード群
     ,ov_errbuf      OUT VARCHAR2                    -- エラー・メッセージ           --# 固定 #
     ,ov_retcode     OUT VARCHAR2                    -- リターン・コード             --# 固定 #
     ,ov_errmsg      OUT VARCHAR2                    -- ユーザー・エラー・メッセージ --# 固定 #
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
    lv_sql_base       VARCHAR2(5000);  -- 拠点(入力Ｐ有)
    -- 拠点入力Ｐ用
    lv_sql_base_01    VARCHAR2(100);   -- 拠点１
    lv_sql_base_02    VARCHAR2(100);   -- 拠点２
    lv_sql_base_03    VARCHAR2(100);   -- 拠点３
    lv_sql_base_04    VARCHAR2(100);   -- 拠点４
    lv_sql_base_05    VARCHAR2(100);   -- 拠点５
    lv_sql_base_06    VARCHAR2(100);   -- 拠点６
    lv_sql_base_07    VARCHAR2(100);   -- 拠点７
    lv_sql_base_08    VARCHAR2(100);   -- 拠点８
    lv_sql_base_09    VARCHAR2(100);   -- 拠点９
    lv_sql_base_10    VARCHAR2(100);   -- 拠点１０
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
    gv_sql_select := 'SELECT xicv1.segment1                 AS skbn             -- 商品区分
                            ,xicv1.description              AS skbn_name        -- 商品区分(名称)
                            ,xicv.segment1                  AS gun              -- 群コード
                            ,ximv.item_no                   AS item_no          -- 品目(コード)
                            ,ximv.item_short_name           AS item_short_name  -- 品目(名称)
                            ,ximv.num_of_cases              AS case_quant       -- 入数
                            ,mfd.attribute4                 AS quant            -- 数量
                            ,mfd.attribute2                 AS amount           -- 金額
                            ,mfd.attribute5                 AS ktn_code         -- 拠点コード
                            ,xpv.party_short_name           AS party_short_name -- 拠点名
                            ,xph.total_amount               AS total_amount     -- 内訳合計
                            ,ximv.old_price                 AS o_amount         -- 旧・定価
                            ,ximv.new_price                 AS n_amount         -- 新・定価
                            ,ximv.price_start_date          AS price_st         -- 定価適用開始日
                            ,SUBSTRB(mfd.forecast_date,4,3) AS month      -- forecast日付(月のみ)
                     ';
--
    -- FROM句
    gv_sql_from   := ' FROM mrp_forecast_designators  mfds    -- Forecast名
                           ,mrp_forecast_dates        mfd     -- Forecast日付
                           ,xxpo_price_headers        xph     -- 仕入/標準単価ヘッダ(アドオン)
                           ,xxcmn_item_categories2_v  xicv    -- OPM品目カテゴリ割当情報VIEW
                           ,xxcmn_item_categories2_v  xicv1   -- OPM品目カテゴリ割当情報VIEW(商)
                           ,xxcmn_item_mst2_v         ximv    -- OPM品目情報VIEW
-- 2009/10/5 v1.8 T.Yoshimoto Mod Start 本番#1648
                           --,xxcmn_parties_v           xpv     -- パーティ情報VIEW
                           ,xxcmn_parties3_v          xpv     -- パーティ情報VIEW2
-- 2009/10/5 v1.8 T.Yoshimoto Mod End 本番#1648
                     ';
--
    -- WHERE句
    gv_sql_where  := ' WHERE mfds.attribute1          = :para_name_sale_plan      -- 販売計画
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
                       AND   ximv.item_no             = xicv.item_no
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
    gv_sql_prod_div      := ' AND xicv1.segment1 = ''' || gr_param.prod_div || '''
                            ';
    -- 商品区分抽出条件 (入力Ｐ NULL)
    gv_sql_prod_div_n    := ' AND xicv1.segment1 IN (''' || gv_prod_div_leaf  || '''
                                                       ' || gv_sql_dot        || '
                                                     ''' || gv_prod_div_drink || ''') -- 1,2の両方抽出
                            ';
--
    -- 拠点抽出条件 (1･･･10の入力パラメータ)
    lv_sql_base          := ' AND mfd.attribute5 IN ';
    lv_sql_base_01       := '''' || gr_param.base_01 || '''';
    lv_sql_base_02       := '''' || gr_param.base_02 || '''';
    lv_sql_base_03       := '''' || gr_param.base_03 || '''';
    lv_sql_base_04       := '''' || gr_param.base_04 || '''';
    lv_sql_base_05       := '''' || gr_param.base_05 || '''';
    lv_sql_base_06       := '''' || gr_param.base_06 || '''';
    lv_sql_base_07       := '''' || gr_param.base_07 || '''';
    lv_sql_base_08       := '''' || gr_param.base_08 || '''';
    lv_sql_base_09       := '''' || gr_param.base_09 || '''';
    lv_sql_base_10       := '''' || gr_param.base_10 || '''';
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
    -- ORDER BY句
    gv_sql_order_by      := ' ORDER BY xicv1.segment1       -- 商品区分
                                      ,mfd.attribute5       -- 拠点
                                      ,xicv.segment1        -- 群コード
                                      ,ximv.item_no         -- 品目
                                      ,mfd.forecast_date';  -- forecast日付
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
    IF ((gr_param.base_01 IS NOT NULL)
      OR (gr_param.base_02 IS NOT NULL)
        OR (gr_param.base_03 IS NOT NULL)
          OR (gr_param.base_04 IS NOT NULL)
            OR (gr_param.base_05 IS NOT NULL)
              OR (gr_param.base_06 IS NOT NULL)
                OR (gr_param.base_07 IS NOT NULL)
                  OR (gr_param.base_08 IS NOT NULL)
                    OR (gr_param.base_09 IS NOT NULL)
                      OR (gr_param.base_10 IS NOT NULL)) THEN
      -- 拠点抽出条件 + 左括弧
      lv_sql_base   := lv_sql_base || gv_sql_l_block;
      -- 入力Ｐ 拠点１に入力有
      IF (gr_param.base_01 IS NOT NULL) THEN
        lv_sql_base := lv_sql_base || lv_sql_base_01;
      END IF;
      -- 入力Ｐ 拠点２に入力有
      IF ((gr_param.base_02 IS NOT NULL)
        AND (gr_param.base_01 IS NULL)) THEN
        lv_sql_base := lv_sql_base || lv_sql_base_02;
      ELSIF (gr_param.base_02 IS NOT NULL) THEN
        lv_sql_base := lv_sql_base || gv_sql_dot || lv_sql_base_02;
      END IF;
      -- 入力Ｐ 拠点３に入力有
      IF ((gr_param.base_03 IS NOT NULL)
        AND (gr_param.base_01 IS NULL)
          AND (gr_param.base_02 IS NULL)) THEN
        lv_sql_base := lv_sql_base || lv_sql_base_03;
      ELSIF (gr_param.base_03 IS NOT NULL) THEN
        lv_sql_base := lv_sql_base || gv_sql_dot || lv_sql_base_03;
      END IF;
      -- 入力Ｐ 拠点４に入力有
      IF ((gr_param.base_04 IS NOT NULL)
        AND (gr_param.base_01 IS NULL)
          AND (gr_param.base_02 IS NULL)
            AND (gr_param.base_03 IS NULL)) THEN
        lv_sql_base := lv_sql_base || lv_sql_base_04;
      ELSIF (gr_param.base_04 IS NOT NULL) THEN
        lv_sql_base := lv_sql_base || gv_sql_dot || lv_sql_base_04;
      END IF;
      -- 入力Ｐ 拠点５に入力有
      IF ((gr_param.base_05 IS NOT NULL)
        AND (gr_param.base_01 IS NULL)
          AND (gr_param.base_02 IS NULL)
            AND (gr_param.base_03 IS NULL)
              AND (gr_param.base_04 IS NULL)) THEN
        lv_sql_base := lv_sql_base || lv_sql_base_05;
      ELSIF (gr_param.base_05 IS NOT NULL) THEN
        lv_sql_base := lv_sql_base || gv_sql_dot || lv_sql_base_05;
      END IF;
      -- 入力Ｐ 拠点６に入力有
      IF ((gr_param.base_06 IS NOT NULL)
        AND (gr_param.base_01 IS NULL)
          AND (gr_param.base_02 IS NULL)
            AND (gr_param.base_03 IS NULL)
              AND (gr_param.base_04 IS NULL)
                AND (gr_param.base_05 IS NULL)) THEN
        lv_sql_base := lv_sql_base || lv_sql_base_06;
      ELSIF (gr_param.base_06 IS NOT NULL) THEN
        lv_sql_base := lv_sql_base || gv_sql_dot || lv_sql_base_06;
      END IF;
      -- 入力Ｐ 拠点７に入力有
      IF ((gr_param.base_07 IS NOT NULL)
        AND (gr_param.base_01 IS NULL)
          AND (gr_param.base_02 IS NULL)
            AND (gr_param.base_03 IS NULL)
              AND (gr_param.base_04 IS NULL)
                AND (gr_param.base_05 IS NULL)
                  AND (gr_param.base_06 IS NULL)) THEN
        lv_sql_base := lv_sql_base || lv_sql_base_07;
      ELSIF (gr_param.base_07 IS NOT NULL) THEN
        lv_sql_base := lv_sql_base || gv_sql_dot || lv_sql_base_07;
      END IF;
      -- 入力Ｐ 拠点８に入力有
      IF ((gr_param.base_08 IS NOT NULL)
        AND (gr_param.base_01 IS NULL)
          AND (gr_param.base_02 IS NULL)
            AND (gr_param.base_03 IS NULL)
              AND (gr_param.base_04 IS NULL)
                AND (gr_param.base_05 IS NULL)
                  AND (gr_param.base_06 IS NULL)
                    AND (gr_param.base_07 IS NULL)) THEN
        lv_sql_base := lv_sql_base || lv_sql_base_08;
      ELSIF (gr_param.base_08 IS NOT NULL) THEN
        lv_sql_base := lv_sql_base || gv_sql_dot || lv_sql_base_08;
      END IF;
      -- 入力Ｐ 拠点９に入力有
      IF ((gr_param.base_09 IS NOT NULL)
        AND (gr_param.base_01 IS NULL)
          AND (gr_param.base_02 IS NULL)
            AND (gr_param.base_03 IS NULL)
              AND (gr_param.base_04 IS NULL)
                AND (gr_param.base_05 IS NULL)
                  AND (gr_param.base_06 IS NULL)
                    AND (gr_param.base_07 IS NULL)
                      AND (gr_param.base_08 IS NULL)) THEN
        lv_sql_base := lv_sql_base || lv_sql_base_09;
      ELSIF (gr_param.base_09 IS NOT NULL) THEN
        lv_sql_base := lv_sql_base || gv_sql_dot || lv_sql_base_09;
      END IF;
      -- 入力Ｐ 拠点１０に入力有
      IF ((gr_param.base_10 IS NOT NULL)
        AND (gr_param.base_01 IS NULL)
          AND (gr_param.base_02 IS NULL)
            AND (gr_param.base_03 IS NULL)
              AND (gr_param.base_04 IS NULL)
                AND (gr_param.base_05 IS NULL)
                  AND (gr_param.base_06 IS NULL)
                    AND (gr_param.base_07 IS NULL)
                      AND (gr_param.base_08 IS NULL)
                        AND (gr_param.base_09 IS NULL)) THEN
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
      IF ((gr_param.crowd_code_01 IS NOT NULL)
        OR (gr_param.crowd_code_02 IS NOT NULL)
          OR (gr_param.crowd_code_03 IS NOT NULL)
            OR (gr_param.crowd_code_04 IS NOT NULL)
              OR (gr_param.crowd_code_05 IS NOT NULL)
                OR (gr_param.crowd_code_06 IS NOT NULL)
                  OR (gr_param.crowd_code_07 IS NOT NULL)
                    OR (gr_param.crowd_code_08 IS NOT NULL)
                      OR (gr_param.crowd_code_09 IS NOT NULL)
                        OR (gr_param.crowd_code_10 IS NOT NULL)) THEN
        -- 群コード抽出条件 + 左括弧
        gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_l_block;
        -- 入力Ｐ 群コード１に入力有
        IF (gr_param.crowd_code_01 IS NOT NULL) THEN
          gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_crowd_code_01;
        END IF;
        -- 入力Ｐ 群コード２に入力有
        IF ((gr_param.crowd_code_02 IS NOT NULL)
          AND (gr_param.crowd_code_01 IS NULL)) THEN
          gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_crowd_code_02;
        ELSIF (gr_param.crowd_code_02 IS NOT NULL) THEN
          gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_dot || gv_sql_crowd_code_02;
        END IF;
        -- 入力Ｐ 群コード３に入力有
        IF ((gr_param.crowd_code_03 IS NOT NULL)
          AND (gr_param.crowd_code_01 IS NULL)
            AND (gr_param.crowd_code_02 IS NULL)) THEN
          gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_crowd_code_03;
        ELSIF (gr_param.crowd_code_03 IS NOT NULL) THEN
          gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_dot || gv_sql_crowd_code_03;
        END IF;
        -- 入力Ｐ 群コード４に入力有
        IF ((gr_param.crowd_code_04 IS NOT NULL)
          AND (gr_param.crowd_code_01 IS NULL)
            AND (gr_param.crowd_code_02 IS NULL)
              AND (gr_param.crowd_code_03 IS NULL)) THEN
          gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_crowd_code_04;
        ELSIF (gr_param.crowd_code_04 IS NOT NULL) THEN
          gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_dot || gv_sql_crowd_code_04;
        END IF;
        -- 入力Ｐ 群コード５に入力有
        IF ((gr_param.crowd_code_05 IS NOT NULL)
          AND (gr_param.crowd_code_01 IS NULL)
            AND (gr_param.crowd_code_02 IS NULL)
              AND (gr_param.crowd_code_03 IS NULL)
                AND (gr_param.crowd_code_04 IS NULL)) THEN
          gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_crowd_code_05;
        ELSIF (gr_param.crowd_code_05 IS NOT NULL) THEN
          gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_dot || gv_sql_crowd_code_05;
        END IF;
        -- 入力Ｐ 群コード６に入力有
        IF ((gr_param.crowd_code_06 IS NOT NULL)
          AND (gr_param.crowd_code_01 IS NULL)
            AND (gr_param.crowd_code_02 IS NULL)
              AND (gr_param.crowd_code_03 IS NULL)
                AND (gr_param.crowd_code_04 IS NULL)
                  AND (gr_param.crowd_code_05 IS NULL)) THEN
          gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_crowd_code_06;
        ELSIF (gr_param.crowd_code_06 IS NOT NULL) THEN
          gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_dot || gv_sql_crowd_code_06;
        END IF;
        -- 入力Ｐ 群コード７に入力有
        IF ((gr_param.crowd_code_07 IS NOT NULL)
          AND (gr_param.crowd_code_01 IS NULL)
            AND (gr_param.crowd_code_02 IS NULL)
              AND (gr_param.crowd_code_03 IS NULL)
                AND (gr_param.crowd_code_04 IS NULL)
                  AND (gr_param.crowd_code_05 IS NULL)
                    AND (gr_param.crowd_code_06 IS NULL)) THEN
          gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_crowd_code_07;
        ELSIF (gr_param.crowd_code_07 IS NOT NULL) THEN
          gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_dot || gv_sql_crowd_code_07;
        END IF;
        -- 入力Ｐ 群コード８に入力有
        IF ((gr_param.crowd_code_08 IS NOT NULL)
          AND (gr_param.crowd_code_01 IS NULL)
            AND (gr_param.crowd_code_02 IS NULL)
              AND (gr_param.crowd_code_03 IS NULL)
                AND (gr_param.crowd_code_04 IS NULL)
                  AND (gr_param.crowd_code_05 IS NULL)
                    AND (gr_param.crowd_code_06 IS NULL)
                      AND (gr_param.crowd_code_07 IS NULL)) THEN
          gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_crowd_code_08;
        ELSIF (gr_param.crowd_code_08 IS NOT NULL) THEN
          gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_dot || gv_sql_crowd_code_08;
        END IF;
        -- 入力Ｐ 群コード９に入力有
        IF ((gr_param.crowd_code_09 IS NOT NULL)
          AND (gr_param.crowd_code_01 IS NULL)
            AND (gr_param.crowd_code_02 IS NULL)
              AND (gr_param.crowd_code_03 IS NULL)
                AND (gr_param.crowd_code_04 IS NULL)
                  AND (gr_param.crowd_code_05 IS NULL)
                    AND (gr_param.crowd_code_06 IS NULL)
                      AND (gr_param.crowd_code_07 IS NULL)
                        AND (gr_param.crowd_code_08 IS NULL)) THEN
          gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_crowd_code_09;
        ELSIF (gr_param.crowd_code_09 IS NOT NULL) THEN
          gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_dot || gv_sql_crowd_code_09;
        END IF;
        -- 入力Ｐ 群コード１０に入力有
        IF ((gr_param.crowd_code_10 IS NOT NULL)
          AND (gr_param.crowd_code_01 IS NULL)
            AND (gr_param.crowd_code_02 IS NULL)
              AND (gr_param.crowd_code_03 IS NULL)
                AND (gr_param.crowd_code_04 IS NULL)
                  AND (gr_param.crowd_code_05 IS NULL)
                    AND (gr_param.crowd_code_06 IS NULL)
                      AND (gr_param.crowd_code_07 IS NULL)
                        AND (gr_param.crowd_code_08 IS NULL)
                          AND (gr_param.crowd_code_09 IS NULL)) THEN
          gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_crowd_code_10;
        ELSIF (gr_param.crowd_code_10 IS NOT NULL) THEN
          gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_dot || gv_sql_crowd_code_10;
        END IF;
        -- 群コード抽出条件 + 右括弧
        gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_r_block;
        -- 作成ＳＱＬ文に群コード抽出条件結合
        gv_sql_sel        := gv_sql_sel || gv_sql_crowd_code;
      END IF;
--
    -- 入力Ｐ「拠点１･･･１０」に入力無の場合
    ELSE
      -- 入力Ｐ「群コード１･･･１０」に入力有の場合
      IF ((gr_param.crowd_code_01 IS NOT NULL)
        OR (gr_param.crowd_code_02 IS NOT NULL)
          OR (gr_param.crowd_code_03 IS NOT NULL)
            OR (gr_param.crowd_code_04 IS NOT NULL)
              OR (gr_param.crowd_code_05 IS NOT NULL)
                OR (gr_param.crowd_code_06 IS NOT NULL)
                  OR (gr_param.crowd_code_07 IS NOT NULL)
                    OR (gr_param.crowd_code_08 IS NOT NULL)
                      OR (gr_param.crowd_code_09 IS NOT NULL)
                        OR (gr_param.crowd_code_10 IS NOT NULL)) THEN
        -- 群コード抽出条件 + 左括弧
        gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_l_block;
        -- 入力Ｐ 群コード１に入力有
        IF (gr_param.crowd_code_01 IS NOT NULL) THEN
          gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_crowd_code_01;
        END IF;
        -- 入力Ｐ 群コード２に入力有
        IF ((gr_param.crowd_code_02 IS NOT NULL)
          AND (gr_param.crowd_code_01 IS NULL)) THEN
          gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_crowd_code_02;
        ELSIF (gr_param.crowd_code_02 IS NOT NULL) THEN
          gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_dot || gv_sql_crowd_code_02;
        END IF;
        -- 入力Ｐ 群コード３に入力有
        IF ((gr_param.crowd_code_03 IS NOT NULL)
          AND (gr_param.crowd_code_01 IS NULL)
            AND (gr_param.crowd_code_02 IS NULL)) THEN
          gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_crowd_code_03;
        ELSIF (gr_param.crowd_code_03 IS NOT NULL) THEN
          gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_dot || gv_sql_crowd_code_03;
        END IF;
        -- 入力Ｐ 群コード４に入力有
        IF ((gr_param.crowd_code_04 IS NOT NULL)
          AND (gr_param.crowd_code_01 IS NULL)
            AND (gr_param.crowd_code_02 IS NULL)
              AND (gr_param.crowd_code_03 IS NULL)) THEN
          gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_crowd_code_04;
        ELSIF (gr_param.crowd_code_04 IS NOT NULL) THEN
          gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_dot || gv_sql_crowd_code_04;
        END IF;
        -- 入力Ｐ 群コード５に入力有
        IF ((gr_param.crowd_code_05 IS NOT NULL)
          AND (gr_param.crowd_code_01 IS NULL)
            AND (gr_param.crowd_code_02 IS NULL)
              AND (gr_param.crowd_code_03 IS NULL)
                AND (gr_param.crowd_code_04 IS NULL)) THEN
          gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_crowd_code_05;
        ELSIF (gr_param.crowd_code_05 IS NOT NULL) THEN
          gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_dot || gv_sql_crowd_code_05;
        END IF;
        -- 入力Ｐ 群コード６に入力有
        IF ((gr_param.crowd_code_06 IS NOT NULL)
          AND (gr_param.crowd_code_01 IS NULL)
            AND (gr_param.crowd_code_02 IS NULL)
              AND (gr_param.crowd_code_03 IS NULL)
                AND (gr_param.crowd_code_04 IS NULL)
                  AND (gr_param.crowd_code_05 IS NULL)) THEN
          gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_crowd_code_06;
        ELSIF (gr_param.crowd_code_06 IS NOT NULL) THEN
          gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_dot || gv_sql_crowd_code_06;
        END IF;
        -- 入力Ｐ 群コード７に入力有
        IF ((gr_param.crowd_code_07 IS NOT NULL)
          AND (gr_param.crowd_code_01 IS NULL)
            AND (gr_param.crowd_code_02 IS NULL)
              AND (gr_param.crowd_code_03 IS NULL)
                AND (gr_param.crowd_code_04 IS NULL)
                  AND (gr_param.crowd_code_05 IS NULL)
                    AND (gr_param.crowd_code_06 IS NULL)) THEN
          gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_crowd_code_07;
        ELSIF (gr_param.crowd_code_07 IS NOT NULL) THEN
          gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_dot || gv_sql_crowd_code_07;
        END IF;
        -- 入力Ｐ 群コード８に入力有
        IF ((gr_param.crowd_code_08 IS NOT NULL)
          AND (gr_param.crowd_code_01 IS NULL)
            AND (gr_param.crowd_code_02 IS NULL)
              AND (gr_param.crowd_code_03 IS NULL)
                AND (gr_param.crowd_code_04 IS NULL)
                  AND (gr_param.crowd_code_05 IS NULL)
                    AND (gr_param.crowd_code_06 IS NULL)
                      AND (gr_param.crowd_code_07 IS NULL)) THEN
          gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_crowd_code_08;
        ELSIF (gr_param.crowd_code_08 IS NOT NULL) THEN
          gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_dot || gv_sql_crowd_code_08;
        END IF;
        -- 入力Ｐ 群コード９に入力有
        IF ((gr_param.crowd_code_09 IS NOT NULL)
          AND (gr_param.crowd_code_01 IS NULL)
            AND (gr_param.crowd_code_02 IS NULL)
              AND (gr_param.crowd_code_03 IS NULL)
                AND (gr_param.crowd_code_04 IS NULL)
                  AND (gr_param.crowd_code_05 IS NULL)
                    AND (gr_param.crowd_code_06 IS NULL)
                      AND (gr_param.crowd_code_07 IS NULL)
                        AND (gr_param.crowd_code_08 IS NULL)) THEN
          gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_crowd_code_09;
        ELSIF (gr_param.crowd_code_09 IS NOT NULL) THEN
          gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_dot || gv_sql_crowd_code_09;
        END IF;
        -- 入力Ｐ 群コード１０に入力有
        IF ((gr_param.crowd_code_10 IS NOT NULL)
          AND (gr_param.crowd_code_01 IS NULL)
            AND (gr_param.crowd_code_02 IS NULL)
              AND (gr_param.crowd_code_03 IS NULL)
                AND (gr_param.crowd_code_04 IS NULL)
                  AND (gr_param.crowd_code_05 IS NULL)
                    AND (gr_param.crowd_code_06 IS NULL)
                      AND (gr_param.crowd_code_07 IS NULL)
                        AND (gr_param.crowd_code_08 IS NULL)
                          AND (gr_param.crowd_code_09 IS NULL)) THEN
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
                                                                       ,gv_price_type  -- add 2008/04/28
                                                                       ,gd_start_day
                                                                       ,gd_start_day 
                                                                       ;
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
  END prc_sale_plan_1;
--
  /************************************************************************************************
   * Procedure Name   : prc_create_xml_data_user
   * Description      : XMLデータ変換 - ユーザー情報部分(user_info)
   ************************************************************************************************/
  PROCEDURE prc_create_xml_data_user
    (
      ov_errbuf     OUT VARCHAR2     -- エラー・メッセージ           --# 固定 #
     ,ov_retcode    OUT VARCHAR2     -- リターン・コード             --# 固定 #
     ,ov_errmsg     OUT VARCHAR2     -- ユーザー・エラー・メッセージ --# 固定 #
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
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
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
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'report_id';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    gt_xml_data_table(gl_xml_idx).tag_value := gv_report_id;
--
    -- 実行日
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'exec_date';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    gt_xml_data_table(gl_xml_idx).tag_value := TO_CHAR(SYSDATE, 'YYYY/MM/DD HH24:MI:SS');
--
    -- ログインユーザー：所属部署
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'exec_user_dept';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    gt_xml_data_table(gl_xml_idx).tag_value
        := xxcmn_common_pkg.get_user_dept(FND_GLOBAL.USER_ID);
--
    -- ログインユーザー：ユーザー名
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'exec_user_name';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    gt_xml_data_table(gl_xml_idx).tag_value
        := xxcmn_common_pkg.get_user_name(FND_GLOBAL.USER_ID);
--
    -- ====================================================
    -- 終了タグ
    -- ====================================================
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/user_info';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
  EXCEPTION
--
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
--
  END prc_create_xml_data_user ;
--
  /************************************************************************************************
   * Procedure Name   : prc_create_xml_data_param
   * Description      : XMLデータ変換 - パラメータ情報部分(param_info)
   ************************************************************************************************/
  PROCEDURE prc_create_xml_data_param
    (
      ov_errbuf     OUT VARCHAR2     -- エラー・メッセージ           --# 固定 #
     ,ov_retcode    OUT VARCHAR2     -- リターン・コード             --# 固定 #
     ,ov_errmsg     OUT VARCHAR2     -- ユーザー・エラー・メッセージ --# 固定 #
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
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'param_info';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
    -- ====================================================
    -- データタグ
    -- ====================================================
    -- 年度
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'year';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    gt_xml_data_table(gl_xml_idx).tag_value := gr_param.year || gv_name_year;
--
    -- 世代
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'sdi_num';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    gt_xml_data_table(gl_xml_idx).tag_value := gr_param.gen;
--
    -- 出力単位
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'out_unit';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    --------------------------------------
    -- 入力パラメータ判定               --
    --------------------------------------
    -- [0]の場合
    IF (gr_param.output_unit = gv_output_unit) THEN
      gt_xml_data_table(gl_xml_idx).tag_value := gv_output_unit_0;  -- '本数'
    ELSE
      gt_xml_data_table(gl_xml_idx).tag_value := gv_output_unit_1;  -- 'ケース'
    END IF;
--
    -- ====================================================
    -- 終了タグ
    -- ====================================================
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/param_info';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
  EXCEPTION
--
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
--
  END prc_create_xml_data_param ;
--
  /**********************************************************************************
   * Procedure Name   : prc_create_xml_data_dtl
   * Description      : XMLデータ作成 - 帳票データ出力 明細行 データ有
   ***********************************************************************************/
  PROCEDURE prc_create_xml_data_dtl
    (
      iv_label_name     IN VARCHAR2  -- 出力タグ名
     ,in_quant          IN NUMBER    -- 数量
     ,in_case_quant     IN NUMBER    -- 入数
     ,in_amount         IN NUMBER    -- 金額
     ,in_total_amount   IN NUMBER    -- 内訳合計
     ,iv_price_st       IN VARCHAR2  -- 定価適用開始日
     ,in_n_amount       IN NUMBER    -- 新定価
     ,in_o_amount       IN NUMBER    -- 旧定価
     ,on_quant         OUT NUMBER    -- 年計用 数量
     ,on_price         OUT NUMBER    -- 年計用 品目定価
     ,ov_errbuf        OUT VARCHAR2  -- エラー・メッセージ           --# 固定 #
     ,ov_retcode       OUT VARCHAR2  -- リターン・コード             --# 固定 #
     ,ov_errmsg        OUT VARCHAR2  -- ユーザー・エラー・メッセージ --# 固定 #
    )
  IS
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_create_xml_data_dtl'; -- プログラム名
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
    ln_chk_0          NUMBER;     -- ０除算判定項目
    ln_kake_par       NUMBER;     -- 計算結果判定
    ln_arari          NUMBER;     -- 粗利用
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
    -- 数量データ
    -- -----------------------------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'quant';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
--
    -- 入力Ｐ『出力単位』が「本数」の場合
    IF (gr_param.output_unit = gv_output_unit) THEN
      on_quant := in_quant;
--
      gt_xml_data_table(gl_xml_idx).tag_value := on_quant;
    -- 入力Ｐ『出力単位』が「ケース」の場合
    ELSE
      -- ０除算回避判定
      IF (in_case_quant <> gn_0) THEN
        -- 値が[0]出なければ、数量計算  (数量 / 入数)  小数以下1位切上
        on_quant := CEIL(in_quant / in_case_quant);
      ELSE
        -- 値が[0]の場合は、一律[0]設定
        on_quant :=  gn_0;
      END IF;
        gt_xml_data_table(gl_xml_idx).tag_value := on_quant;
    END IF;
--
    -- -----------------------------------------------------
    -- 金額データ
    -- -----------------------------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'amount';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    gt_xml_data_table(gl_xml_idx).tag_value := ROUND(in_amount / 1000,0);
--
    -- -----------------------------------------------------
    -- 粗利率データ
    -- -----------------------------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'arari_par';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
--
    -- 粗利計算 (金額－内訳合計＊数量)
    ln_arari := in_amount - in_total_amount * in_quant;
    -- ０除算回避判定
    IF (in_amount <> gn_0) THEN
      -- 値が[0]出なければ計算
      gt_xml_data_table(gl_xml_idx).tag_value := ROUND((ln_arari / in_amount * 100),2);
    ELSE
      -- 値が[0]の場合は、一律[0]設定
      gt_xml_data_table(gl_xml_idx).tag_value := gn_0;
    END IF;
--
    -- -----------------------------------------------------
    -- 掛率データ
    -- -----------------------------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'kake_par';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
--
    -- 品目定価判定  定価適用開始日にて旧定価・新定価の使用判断
    -- 年度開始月日がOPM品目マスタ定価適用開始日以上の場合
    IF (FND_DATE.STRING_TO_DATE(iv_price_st,'YYYY/MM/DD')   <= gd_start_day) THEN
      -- 新定価を使用
      on_price := in_n_amount;
    -- 年度開始月日がOPM品目マスタ定価適用開始日未満の場合
    ELSIF (FND_DATE.STRING_TO_DATE(iv_price_st,'YYYY/MM/DD') > gd_start_day) THEN
      -- 旧定価を使用
      on_price := in_o_amount;
    END IF;
--
    -- ０除算判定項目へ判定値を挿入
--2008.04.30 Y.Kawano modify start
--    ln_chk_0 := on_price * in_quant * 100;
    ln_chk_0 := on_price * in_quant;
--2008.04.30 Y.Kawano modify end
    -- ０除算回避判定
    IF (ln_chk_0 <> gn_0) THEN
      -- 値が[0]出なければ計算
--2008.04.30 Y.Kawano modify start
--      ln_kake_par := ROUND(in_amount / ln_chk_0,2);
      ln_kake_par := ROUND((in_amount * 100) / ln_chk_0,2);
--2008.04.30 Y.Kawano modify end
    ELSE
      -- 値が[0]の場合は、一律[0]設定
      ln_kake_par := gn_0;
    END IF;
--
    -- 品目定価 = ０か、計算結果がマイナスの場合、固定値[70.00]を登録
    IF ((on_price = 0)
      OR (ln_kake_par < 0)) THEN
      ln_kake_par := gn_kotei_70; -- 固定値[70.00]
    END IF;
--
    gt_xml_data_table(gl_xml_idx).tag_value := ln_kake_par;
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
  END prc_create_xml_data_dtl;
--
  /**********************************************************************************
   * Procedure Name   : prc_create_xml_data_dtl_n
   * Description      : XMLデータ作成 - 帳票データ出力 明細行 データ無
   ***********************************************************************************/
  PROCEDURE prc_create_xml_data_dtl_n
    (
      iv_label_name     IN VARCHAR2 -- 出力タグ名
     ,ov_errbuf        OUT VARCHAR2 -- エラー・メッセージ           --# 固定 #
     ,ov_retcode       OUT VARCHAR2 -- リターン・コード             --# 固定 #
     ,ov_errmsg        OUT VARCHAR2 -- ユーザー・エラー・メッセージ --# 固定 #
    )
  IS
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_create_xml_data_dtl_n'; -- プログラム名
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
    -- 数量データ
    -- -----------------------------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'quant';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    gt_xml_data_table(gl_xml_idx).tag_value := gn_0;
--
    -- -----------------------------------------------------
    -- 金額データ
    -- -----------------------------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'amount';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    gt_xml_data_table(gl_xml_idx).tag_value := gn_0;
--
    -- -----------------------------------------------------
    -- 粗利率データ
    -- -----------------------------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'arari_par';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    gt_xml_data_table(gl_xml_idx).tag_value := gn_0;
--
    -- -----------------------------------------------------
    -- 掛率データ
    -- -----------------------------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'kake_par';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    gt_xml_data_table(gl_xml_idx).tag_value := gn_0;
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
  END prc_create_xml_data_dtl_n;
--
  /**********************************************************************************
   * Procedure Name   : prc_create_xml_data_st_lt
   * Description      : XMLデータ作成 - 帳票データ出力 小群計/大群計
   ***********************************************************************************/
  PROCEDURE prc_create_xml_data_st_lt
    (
      iv_label_name     IN VARCHAR2 -- 群計用タグ名
     ,iv_name           IN VARCHAR2 -- 群計タイトル
     ,in_may_quant      IN NUMBER   -- ５月 数量
     ,in_may_amount     IN NUMBER   -- ５月 金額
     ,in_may_price      IN NUMBER   -- ５月 品目定価
     ,in_may_to_amount  IN NUMBER   -- ５月 内訳合計
     ,in_may_quant_t    IN NUMBER   -- ５月 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
     ,in_may_s_cost     IN NUMBER   -- ５月 標準原価(計算用)
     ,in_may_calc       IN NUMBER   -- ５月 品目定価*数量(計算用)
     ,in_may_minus_flg   IN VARCHAR2 -- ５月 マイナス値存在フラグ(計算用)
     ,in_may_ht_zero_flg IN VARCHAR2 -- ５月 品目定価0値存在フラグ(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
     ,in_jun_quant      IN NUMBER   -- ６月 数量
     ,in_jun_amount     IN NUMBER   -- ６月 金額
     ,in_jun_price      IN NUMBER   -- ６月 品目定価
     ,in_jun_to_amount  IN NUMBER   -- ６月 内訳合計
     ,in_jun_quant_t    IN NUMBER   -- ６月 数量(計算用)
 -- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
     ,in_jun_s_cost     IN NUMBER   -- ６月 標準原価(計算用)
     ,in_jun_calc       IN NUMBER   -- ６月 品目定価*数量(計算用)
     ,in_jun_minus_flg   IN VARCHAR2 -- ６月 マイナス値存在フラグ(計算用)
     ,in_jun_ht_zero_flg IN VARCHAR2 -- ６月 品目定価0値存在フラグ(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
     ,in_jul_quant      IN NUMBER   -- ７月 数量
     ,in_jul_amount     IN NUMBER   -- ７月 金額
     ,in_jul_price      IN NUMBER   -- ７月 品目定価
     ,in_jul_to_amount  IN NUMBER   -- ７月 内訳合計
     ,in_jul_quant_t    IN NUMBER   -- ７月 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
     ,in_jul_s_cost     IN NUMBER   -- ７月 標準原価(計算用)
     ,in_jul_calc       IN NUMBER   -- ７月 品目定価*数量(計算用)
     ,in_jul_minus_flg   IN VARCHAR2 -- ７月 マイナス値存在フラグ(計算用)
     ,in_jul_ht_zero_flg IN VARCHAR2 -- ７月 品目定価0値存在フラグ(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
     ,in_aug_quant      IN NUMBER   -- ８月 数量
     ,in_aug_amount     IN NUMBER   -- ８月 金額
     ,in_aug_price      IN NUMBER   -- ８月 品目定価
     ,in_aug_to_amount  IN NUMBER   -- ８月 内訳合計
     ,in_aug_quant_t    IN NUMBER   -- ８月 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
     ,in_aug_s_cost     IN NUMBER   -- ８月 標準原価(計算用)
     ,in_aug_calc       IN NUMBER   -- ８月 品目定価*数量(計算用)
     ,in_aug_minus_flg   IN VARCHAR2 -- ８月 マイナス値存在フラグ(計算用)
     ,in_aug_ht_zero_flg IN VARCHAR2 -- ８月 品目定価0値存在フラグ(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
     ,in_sep_quant      IN NUMBER   -- ９月 数量
     ,in_sep_amount     IN NUMBER   -- ９月 金額
     ,in_sep_price      IN NUMBER   -- ９月 品目定価
     ,in_sep_to_amount  IN NUMBER   -- ９月 内訳合計
     ,in_sep_quant_t    IN NUMBER   -- ９月 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
     ,in_sep_s_cost     IN NUMBER   -- ９月 標準原価(計算用)
     ,in_sep_calc       IN NUMBER   -- ９月 品目定価*数量(計算用)
     ,in_sep_minus_flg   IN VARCHAR2 -- ９月 マイナス値存在フラグ(計算用)
     ,in_sep_ht_zero_flg IN VARCHAR2 -- ９月 品目定価0値存在フラグ(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
     ,in_oct_quant      IN NUMBER   -- １０月 数量
     ,in_oct_amount     IN NUMBER   -- １０月 金額
     ,in_oct_price      IN NUMBER   -- １０月 品目定価
     ,in_oct_to_amount  IN NUMBER   -- １０月 内訳合計
     ,in_oct_quant_t    IN NUMBER   -- １０月 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
     ,in_oct_s_cost     IN NUMBER   -- １０月 標準原価(計算用)
     ,in_oct_calc       IN NUMBER   -- １０月 品目定価*数量(計算用)
     ,in_oct_minus_flg   IN VARCHAR2 -- １０月 マイナス値存在フラグ(計算用)
     ,in_oct_ht_zero_flg IN VARCHAR2 -- １０月 品目定価0値存在フラグ(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
     ,in_nov_quant      IN NUMBER   -- １１月 数量
     ,in_nov_amount     IN NUMBER   -- １１月 金額
     ,in_nov_price      IN NUMBER   -- １１月 品目定価
     ,in_nov_to_amount  IN NUMBER   -- １１月 内訳合計
     ,in_nov_quant_t    IN NUMBER   -- １１月 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
     ,in_nov_s_cost     IN NUMBER   -- １１月 標準原価(計算用)
     ,in_nov_calc       IN NUMBER   -- １１月 品目定価*数量(計算用)
     ,in_nov_minus_flg   IN VARCHAR2 -- １１月 マイナス値存在フラグ(計算用)
     ,in_nov_ht_zero_flg IN VARCHAR2 -- １１月 品目定価0値存在フラグ(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
     ,in_dec_quant      IN NUMBER   -- １２月 数量
     ,in_dec_amount     IN NUMBER   -- １２月 金額
     ,in_dec_price      IN NUMBER   -- １２月 品目定価
     ,in_dec_to_amount  IN NUMBER   -- １２月 内訳合計
     ,in_dec_quant_t    IN NUMBER   -- １２月 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
     ,in_dec_s_cost     IN NUMBER   -- １２月 標準原価(計算用)
     ,in_dec_calc       IN NUMBER   -- １２月 品目定価*数量(計算用)
     ,in_dec_minus_flg   IN VARCHAR2 -- １２月 マイナス値存在フラグ(計算用)
     ,in_dec_ht_zero_flg IN VARCHAR2 -- １２月 品目定価0値存在フラグ(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
     ,in_jan_quant      IN NUMBER   -- １月 数量
     ,in_jan_amount     IN NUMBER   -- １月 金額
     ,in_jan_price      IN NUMBER   -- １月 品目定価
     ,in_jan_to_amount  IN NUMBER   -- １月 内訳合計
     ,in_jan_quant_t    IN NUMBER   -- １月 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
     ,in_jan_s_cost     IN NUMBER   -- １月 標準原価(計算用)
     ,in_jan_calc       IN NUMBER   -- １月 品目定価*数量(計算用)
     ,in_jan_minus_flg   IN VARCHAR2 -- １月 マイナス値存在フラグ(計算用)
     ,in_jan_ht_zero_flg IN VARCHAR2 -- １月 品目定価0値存在フラグ(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
     ,in_feb_quant      IN NUMBER   -- ２月 数量
     ,in_feb_amount     IN NUMBER   -- ２月 金額
     ,in_feb_price      IN NUMBER   -- ２月 品目定価
     ,in_feb_to_amount  IN NUMBER   -- ２月 内訳合計
     ,in_feb_quant_t    IN NUMBER   -- ２月 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
     ,in_feb_s_cost     IN NUMBER   -- ２月 標準原価(計算用)
     ,in_feb_calc       IN NUMBER   -- ２月 品目定価*数量(計算用)
     ,in_feb_minus_flg   IN VARCHAR2 -- ２月 マイナス値存在フラグ(計算用)
     ,in_feb_ht_zero_flg IN VARCHAR2 -- ２月 品目定価0値存在フラグ(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
     ,in_mar_quant      IN NUMBER   -- ３月 数量
     ,in_mar_amount     IN NUMBER   -- ３月 金額
     ,in_mar_price      IN NUMBER   -- ３月 品目定価
     ,in_mar_to_amount  IN NUMBER   -- ３月 内訳合計
     ,in_mar_quant_t    IN NUMBER   -- ３月 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
     ,in_mar_s_cost     IN NUMBER   -- ３月 標準原価(計算用)
     ,in_mar_calc       IN NUMBER   -- ３月 品目定価*数量(計算用)
     ,in_mar_minus_flg   IN VARCHAR2 -- ３月 マイナス値存在フラグ(計算用)
     ,in_mar_ht_zero_flg IN VARCHAR2 -- ３月 品目定価0値存在フラグ(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
     ,in_apr_quant      IN NUMBER   -- ４月 数量
     ,in_apr_amount     IN NUMBER   -- ４月 金額
     ,in_apr_price      IN NUMBER   -- ４月 品目定価
     ,in_apr_to_amount  IN NUMBER   -- ４月 内訳合計
     ,in_apr_quant_t    IN NUMBER   -- ４月 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
     ,in_apr_s_cost     IN NUMBER   -- ４月 標準原価(計算用)
     ,in_apr_calc       IN NUMBER   -- ４月 品目定価*数量(計算用)
     ,in_apr_minus_flg   IN VARCHAR2 -- ４月 マイナス値存在フラグ(計算用)
     ,in_apr_ht_zero_flg IN VARCHAR2 -- ４月 品目定価0値存在フラグ(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
     ,in_year_quant     IN NUMBER   -- 年計 数量
     ,in_year_amount    IN NUMBER   -- 年計 金額
     ,in_year_price     IN NUMBER   -- 年計 品目定価
     ,in_year_to_amount IN NUMBER   -- 年計 内訳合計
     ,in_year_quant_t   IN NUMBER   -- 年計 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
     ,in_year_s_cost    IN NUMBER   -- 年計 標準原価(計算用)
     ,in_year_calc      IN NUMBER   -- 年計 品目定価*数量(計算用)
     ,in_year_minus_flg   IN VARCHAR2 -- 年計月 マイナス値存在フラグ(計算用)
     ,in_year_ht_zero_flg IN VARCHAR2 -- 年計月 品目定価0値存在フラグ(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
     ,ov_errbuf        OUT VARCHAR2 -- エラー・メッセージ           --# 固定 #
     ,ov_retcode       OUT VARCHAR2 -- リターン・コード             --# 固定 #
     ,ov_errmsg        OUT VARCHAR2 -- ユーザー・エラー・メッセージ --# 固定 #
    )
  IS
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_create_xml_data_st_lt'; -- プログラム名
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
    ln_chk_0          NUMBER;     -- ０除算判定項目
    ln_kake_par       NUMBER;     -- 計算結果判定
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
    -- データタグ
    -- ====================================================
    -- 群計タイトル
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'label';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    gt_xml_data_table(gl_xml_idx).tag_value := iv_name;
--
    -- ５月 数量データ
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'may_quant';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    gt_xml_data_table(gl_xml_idx).tag_value := in_may_quant_t;
--
    -- ５月 金額データ
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'may_amount';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    gt_xml_data_table(gl_xml_idx).tag_value := ROUND((in_may_amount / 1000),0);
--
    -- ５月 粗利率データ
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'may_arari_par';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    --------------------------------
    -- ０除算回避判定             --
    --------------------------------
    IF (in_may_amount <> 0) THEN
      -- 値が[0]出なければ計算
      gt_xml_data_table(gl_xml_idx).tag_value := 
-- 2009/04/16 v1.6 T.Yoshimoto Mod Start 本番#1410
--            ROUND(((in_may_amount - in_may_to_amount * in_may_quant) / in_may_amount) * 100,2);
        ROUND(((in_may_amount - in_may_s_cost) / in_may_amount) * 100,2);
-- 2009/04/16 v1.6 T.Yoshimoto Mod End 本番#1410
    ELSE
      -- 値が[0]の場合は、一律[0]設定
      gt_xml_data_table(gl_xml_idx).tag_value := gn_0;
    END IF;
--
    -- ５月 掛率データ
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'may_kake_par';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    --------------------------------------
    -- ０除算判定項目へ判定値を挿入     --
    --------------------------------------
-- 2009/04/16 v1.6 T.Yoshimoto Mod Start 本番#1410
--    ln_chk_0 := in_may_price * in_may_quant;
    ln_chk_0 := in_may_calc;
-- 2009/04/16 v1.6 T.Yoshimoto Mod End 本番#1410
    -- ０除算回避判定
    IF (ln_chk_0 <> gn_0) THEN
      -- 値が[0]出なければ計算
      ln_kake_par := ROUND((in_may_amount * 100) / ln_chk_0,2);
    ELSE
      -- 値が[0]の場合は、一律[0]設定
      ln_kake_par := gn_0;
    END IF;
--
-- 2009/04/16 v1.6 T.Yoshimoto Mod Star 本番#1410
/*
    -- 品目定価 = ０か、計算結果がマイナスの場合、固定値[70.00]を登録
    IF ((in_may_amount = 0)
      AND (in_may_price = 0)) THEN
      ln_kake_par := gn_0;
    ELSIF ((in_may_price = 0)
      OR (ln_kake_par < 0)) THEN
        ln_kake_par := gn_kotei_70; -- 固定値[70.00]
    END IF;
*/
    -- 品目定価 = ０が存在している、または数量にマイナス値が存在している
    -- または計算結果がマイナスの場合、固定値[70.00]を登録
    IF (( in_may_minus_flg = 'Y' ) OR ( in_may_ht_zero_flg = 'Y' ) OR ( ln_kake_par < 0 ) ) THEN
--
      ln_kake_par := gn_kotei_70; -- 固定値[70.00]
--
    END IF;
-- 2009/04/16 v1.6 T.Yoshimoto Mod Star 本番#1410
--
    gt_xml_data_table(gl_xml_idx).tag_value := ln_kake_par;
--
    -- ６月 数量データ
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'jun_quant';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    gt_xml_data_table(gl_xml_idx).tag_value := in_jun_quant_t;
--
    -- ６月 金額データ
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'jun_amount';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    gt_xml_data_table(gl_xml_idx).tag_value := ROUND((in_jun_amount / 1000),0);
--
    -- ６月 粗利率データ
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'jun_arari_par';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    --------------------------------
    -- ０除算回避判定             --
    --------------------------------
    IF (in_jun_amount <> 0) THEN
      -- 値が[0]出なければ計算
      gt_xml_data_table(gl_xml_idx).tag_value := 
-- 2009/04/16 v1.6 T.Yoshimoto Mod Start 本番#1410
--            ROUND(((in_jun_amount - in_jun_to_amount * in_jun_quant) / in_jun_amount) * 100,2);
        ROUND(((in_jun_amount - in_jun_s_cost) / in_jun_amount) * 100,2);
-- 2009/04/16 v1.6 T.Yoshimoto Mod End 本番#1410
    ELSE
      -- 値が[0]の場合は、一律[0]設定
      gt_xml_data_table(gl_xml_idx).tag_value := gn_0;
    END IF;
--
    -- ６月 掛率データ
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'jun_kake_par';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    --------------------------------------
    -- ０除算判定項目へ判定値を挿入     --
    --------------------------------------
-- 2009/04/16 v1.6 T.Yoshimoto Mod Start 本番#1410
--    ln_chk_0 := in_jun_price * in_jun_quant;
    ln_chk_0 := in_jun_calc;
-- 2009/04/16 v1.6 T.Yoshimoto Mod End 本番#1410
    -- ０除算回避判定
    IF (ln_chk_0 <> gn_0) THEN
      -- 値が[0]出なければ計算
      ln_kake_par := ROUND((in_jun_amount * 100) / ln_chk_0,2);
    ELSE
      -- 値が[0]の場合は、一律[0]設定
      ln_kake_par := gn_0;
    END IF;
--
-- 2009/04/16 v1.6 T.Yoshimoto Mod Star 本番#1410
/*
    -- 品目定価 = ０か、計算結果がマイナスの場合、固定値[70.00]を登録
    IF ((in_jun_amount = 0)
      AND (in_jun_price = 0)) THEN
      ln_kake_par := gn_0;
    ELSIF ((in_jun_price = 0)
      OR (ln_kake_par < 0)) THEN
      ln_kake_par := gn_kotei_70; -- 固定値[70.00]
    END IF;
*/
    -- 品目定価 = ０が存在している、または数量にマイナス値が存在している
    -- または計算結果がマイナスの場合、固定値[70.00]を登録
    IF (( in_jun_minus_flg = 'Y' ) OR ( in_jun_ht_zero_flg = 'Y' ) OR ( ln_kake_par < 0 ) ) THEN
--
      ln_kake_par := gn_kotei_70; -- 固定値[70.00]
--
    END IF;
-- 2009/04/16 v1.6 T.Yoshimoto Mod Star 本番#1410
--
    gt_xml_data_table(gl_xml_idx).tag_value := ln_kake_par;
--
    -- ７月 数量データ
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'jul_quant';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    gt_xml_data_table(gl_xml_idx).tag_value := in_jul_quant_t;
--
    -- ７月 金額データ
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'jul_amount';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    gt_xml_data_table(gl_xml_idx).tag_value := ROUND((in_jul_amount / 1000),0);
--
    -- ７月 粗利率データ
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'jul_arari_par';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    --------------------------------
    -- ０除算回避判定             --
    --------------------------------
    IF (in_jul_amount <> 0) THEN
      -- 値が[0]出なければ計算
      gt_xml_data_table(gl_xml_idx).tag_value := 
-- 2009/04/16 v1.6 T.Yoshimoto Mod Start 本番#1410
--            ROUND(((in_jul_amount - in_jul_to_amount * in_jul_quant) / in_jul_amount) * 100,2);
        ROUND(((in_jul_amount - in_jul_s_cost) / in_jul_amount) * 100,2);
-- 2009/04/16 v1.6 T.Yoshimoto Mod End 本番#1410
    ELSE
      -- 値が[0]の場合は、一律[0]設定
      gt_xml_data_table(gl_xml_idx).tag_value := gn_0;
    END IF;
--
    -- ７月 掛率データ
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'jul_kake_par';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    --------------------------------------
    -- ０除算判定項目へ判定値を挿入     --
    --------------------------------------
-- 2009/04/16 v1.6 T.Yoshimoto Mod Start 本番#1410
--    ln_chk_0 := in_jul_price * in_jul_quant;
    ln_chk_0 := in_jul_calc;
-- 2009/04/16 v1.6 T.Yoshimoto Mod End 本番#1410
    -- ０除算回避判定
    IF (ln_chk_0 <> gn_0) THEN
      -- 値が[0]出なければ計算
      ln_kake_par := ROUND((in_jul_amount * 100) / ln_chk_0,2);
    ELSE
      -- 値が[0]の場合は、一律[0]設定
      ln_kake_par := gn_0;
    END IF;
--
-- 2009/04/16 v1.6 T.Yoshimoto Mod Star 本番#1410
/*
    -- 品目定価 = ０か、計算結果がマイナスの場合、固定値[70.00]を登録
    IF ((in_jul_amount = 0)
      AND (in_jul_price = 0)) THEN
      ln_kake_par := gn_0;
    ELSIF ((in_jul_price = 0)
      OR (ln_kake_par < 0)) THEN
      ln_kake_par := gn_kotei_70; -- 固定値[70.00]
    END IF;
*/
    -- 品目定価 = ０が存在している、または数量にマイナス値が存在している
    -- または計算結果がマイナスの場合、固定値[70.00]を登録
    IF (( in_jul_minus_flg = 'Y' ) OR ( in_jul_ht_zero_flg = 'Y' ) OR ( ln_kake_par < 0 ) ) THEN
--
      ln_kake_par := gn_kotei_70; -- 固定値[70.00]
--
    END IF;
-- 2009/04/16 v1.6 T.Yoshimoto Mod Star 本番#1410
--
    gt_xml_data_table(gl_xml_idx).tag_value := ln_kake_par;
--
    -- ８月 数量データ
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'aug_quant';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    gt_xml_data_table(gl_xml_idx).tag_value := in_aug_quant_t;
--
    -- ８月 金額データ
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'aug_amount';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    gt_xml_data_table(gl_xml_idx).tag_value := ROUND((in_aug_amount / 1000),0);
--
    -- ８月 粗利率データ
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'aug_arari_par';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    --------------------------------
    -- ０除算回避判定             --
    --------------------------------
    IF (in_aug_amount <> 0) THEN
      -- 値が[0]出なければ計算
      gt_xml_data_table(gl_xml_idx).tag_value := 
-- 2009/04/16 v1.6 T.Yoshimoto Mod Start 本番#1410
--            ROUND(((in_aug_amount - in_aug_to_amount * in_aug_quant) / in_aug_amount) * 100,2);
        ROUND(((in_aug_amount - in_aug_s_cost) / in_aug_amount) * 100,2);
-- 2009/04/16 v1.6 T.Yoshimoto Mod End 本番#1410
    ELSE
      -- 値が[0]の場合は、一律[0]設定
      gt_xml_data_table(gl_xml_idx).tag_value := gn_0;
    END IF;
--
    -- ８月 掛率データ
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'aug_kake_par';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    --------------------------------------
    -- ０除算判定項目へ判定値を挿入     --
    --------------------------------------
-- 2009/04/16 v1.6 T.Yoshimoto Mod Start 本番#1410
--    ln_chk_0 := in_aug_price * in_aug_quant;
    ln_chk_0 := in_aug_calc;
-- 2009/04/16 v1.6 T.Yoshimoto Mod End 本番#1410
    -- ０除算回避判定
    IF (ln_chk_0 <> gn_0) THEN
      -- 値が[0]出なければ計算
      ln_kake_par := ROUND((in_aug_amount * 100) / ln_chk_0,2);
    ELSE
      -- 値が[0]の場合は、一律[0]設定
      ln_kake_par := gn_0;
    END IF;
--
-- 2009/04/16 v1.6 T.Yoshimoto Mod Star 本番#1410
/*
    -- 品目定価 = ０か、計算結果がマイナスの場合、固定値[70.00]を登録
    IF ((in_aug_amount = 0)
      AND (in_aug_price = 0)) THEN
      ln_kake_par := gn_0;
    ELSIF ((in_aug_price = 0)
      OR (ln_kake_par < 0)) THEN
      ln_kake_par := gn_kotei_70; -- 固定値[70.00]
    END IF;
*/
    -- 品目定価 = ０が存在している、または数量にマイナス値が存在している
    -- または計算結果がマイナスの場合、固定値[70.00]を登録
    IF (( in_aug_minus_flg = 'Y' ) OR ( in_aug_ht_zero_flg = 'Y' ) OR ( ln_kake_par < 0 ) ) THEN
--
      ln_kake_par := gn_kotei_70; -- 固定値[70.00]
--
    END IF;
-- 2009/04/16 v1.6 T.Yoshimoto Mod Star 本番#1410
--
    gt_xml_data_table(gl_xml_idx).tag_value := ln_kake_par;
--
    -- ９月 数量データ
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'sep_quant';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    gt_xml_data_table(gl_xml_idx).tag_value := in_sep_quant_t;
--
    -- ９月 金額データ
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'sep_amount';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    gt_xml_data_table(gl_xml_idx).tag_value := ROUND((in_sep_amount / 1000),0);
--
    -- ９月 粗利率データ
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'sep_arari_par';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    --------------------------------
    -- ０除算回避判定             --
    --------------------------------
    IF (in_sep_amount <> 0) THEN
      -- 値が[0]出なければ計算
      gt_xml_data_table(gl_xml_idx).tag_value := 
-- 2009/04/16 v1.6 T.Yoshimoto Mod Start 本番#1410
--            ROUND(((in_sep_amount - in_sep_to_amount * in_sep_quant) / in_sep_amount) * 100,2);
        ROUND(((in_sep_amount - in_sep_s_cost) / in_sep_amount) * 100,2);
-- 2009/04/16 v1.6 T.Yoshimoto Mod End 本番#1410
    ELSE
      -- 値が[0]の場合は、一律[0]設定
      gt_xml_data_table(gl_xml_idx).tag_value := gn_0;
    END IF;
--
    -- ９月 掛率データ
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'sep_kake_par';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    --------------------------------------
    -- ０除算判定項目へ判定値を挿入     --
    --------------------------------------
-- 2009/04/16 v1.6 T.Yoshimoto Mod Start 本番#1410
--    ln_chk_0 := in_sep_price * in_sep_quant;
    ln_chk_0 := in_sep_calc;
-- 2009/04/16 v1.6 T.Yoshimoto Mod End 本番#1410
    -- ０除算回避判定
    IF (ln_chk_0 <> gn_0) THEN
      -- 値が[0]出なければ計算
      ln_kake_par := ROUND((in_sep_amount * 100) / ln_chk_0,2);
    ELSE
      -- 値が[0]の場合は、一律[0]設定
      ln_kake_par := gn_0;
    END IF;
--
-- 2009/04/16 v1.6F T.Yoshimoto Mod Star 本番#1410
/*
    -- 品目定価 = ０か、計算結果がマイナスの場合、固定値[70.00]を登録
    IF ((in_sep_amount = 0)
      AND (in_sep_price = 0)) THEN
      ln_kake_par := gn_0;
    ELSIF ((in_sep_price = 0)
      OR (ln_kake_par < 0)) THEN
      ln_kake_par := gn_kotei_70; -- 固定値[70.00]
    END IF;
*/
    -- 品目定価 = ０が存在している、または数量にマイナス値が存在している
    -- または計算結果がマイナスの場合、固定値[70.00]を登録
    IF (( in_sep_minus_flg = 'Y' ) OR ( in_sep_ht_zero_flg = 'Y' ) OR ( ln_kake_par < 0 ) ) THEN
--
      ln_kake_par := gn_kotei_70; -- 固定値[70.00]
--
    END IF;
-- 2009/04/16 v1.6 T.Yoshimoto Mod Star 本番#1410
--
    gt_xml_data_table(gl_xml_idx).tag_value := ln_kake_par;
--
    -- １０月 数量データ
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'oct_quant';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    gt_xml_data_table(gl_xml_idx).tag_value := in_oct_quant_t;
--
    -- １０月 金額データ
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'oct_amount';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    gt_xml_data_table(gl_xml_idx).tag_value := ROUND((in_oct_amount / 1000),0);
--
    -- １０月 粗利率データ
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'oct_arari_par';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    --------------------------------
    -- ０除算回避判定             --
    --------------------------------
    IF (in_oct_amount <> 0) THEN
      -- 値が[0]出なければ計算
      gt_xml_data_table(gl_xml_idx).tag_value := 
-- 2009/04/16 v1.6 T.Yoshimoto Mod Start 本番#1410
--            ROUND(((in_oct_amount - in_oct_to_amount * in_oct_quant) / in_oct_amount) * 100,2);
        ROUND(((in_oct_amount - in_oct_s_cost) / in_oct_amount) * 100,2);
-- 2009/04/16 v1.6 T.Yoshimoto Mod End 本番#1410
    ELSE
      -- 値が[0]の場合は、一律[0]設定
      gt_xml_data_table(gl_xml_idx).tag_value := gn_0;
    END IF;
--
    -- １０月 掛率データ
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'oct_kake_par';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    --------------------------------------
    -- ０除算判定項目へ判定値を挿入     --
    --------------------------------------
-- 2009/04/16 v1.6 T.Yoshimoto Mod Start 本番#1410
--    ln_chk_0 := in_oct_price * in_oct_quant;
    ln_chk_0 := in_oct_calc;
-- 2009/04/16 v1.6 T.Yoshimoto Mod End 本番#1410
    -- ０除算回避判定
    IF (ln_chk_0 <> gn_0) THEN
      -- 値が[0]出なければ計算
      ln_kake_par := ROUND((in_oct_amount * 100) / ln_chk_0,2);
    ELSE
      -- 値が[0]の場合は、一律[0]設定
      ln_kake_par := gn_0;
    END IF;
--
-- 2009/04/16 v1.6 T.Yoshimoto Mod Star 本番#1410
/*
    -- 品目定価 = ０か、計算結果がマイナスの場合、固定値[70.00]を登録
    IF ((in_oct_amount = 0)
      AND (in_oct_price = 0)) THEN
      ln_kake_par := gn_0;
    ELSIF ((in_oct_price = 0)
      OR (ln_kake_par < 0)) THEN
      ln_kake_par := gn_kotei_70; -- 固定値[70.00]
    END IF;
*/
    -- 品目定価 = ０が存在している、または数量にマイナス値が存在している
    -- または計算結果がマイナスの場合、固定値[70.00]を登録
    IF (( in_oct_minus_flg = 'Y' ) OR ( in_oct_ht_zero_flg = 'Y' ) OR ( ln_kake_par < 0 ) ) THEN
--
      ln_kake_par := gn_kotei_70; -- 固定値[70.00]
--
    END IF;
-- 2009/04/16 v1.6 T.Yoshimoto Mod Star 本番#1410
--
    gt_xml_data_table(gl_xml_idx).tag_value := ln_kake_par;
--
    -- １１月 数量データ
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'nov_quant';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    gt_xml_data_table(gl_xml_idx).tag_value := in_nov_quant_t;
--
    -- １１月 金額データ
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'nov_amount';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    gt_xml_data_table(gl_xml_idx).tag_value := ROUND((in_nov_amount / 1000),0);
--
    -- １１月 粗利率データ
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'nov_arari_par';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    --------------------------------
    -- ０除算回避判定             --
    --------------------------------
    IF (in_nov_amount <> 0) THEN
      -- 値が[0]出なければ計算
      gt_xml_data_table(gl_xml_idx).tag_value := 
-- 2009/04/16 v1.6 T.Yoshimoto Mod Start 本番#1410
--            ROUND(((in_nov_amount - in_nov_to_amount * in_nov_quant) / in_nov_amount) * 100,2);
        ROUND(((in_nov_amount - in_nov_s_cost) / in_nov_amount) * 100,2);
-- 2009/04/16 v1.6 T.Yoshimoto Mod End 本番#1410
    ELSE
      -- 値が[0]の場合は、一律[0]設定
      gt_xml_data_table(gl_xml_idx).tag_value := gn_0;
    END IF;
--
    -- １１月 掛率データ
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'nov_kake_par';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    --------------------------------------
    -- ０除算判定項目へ判定値を挿入     --
    --------------------------------------
-- 2009/04/16 v1.6 T.Yoshimoto Mod Start 本番#1410
--    ln_chk_0 := in_nov_price * in_nov_quant;
    ln_chk_0 := in_nov_calc;
-- 2009/04/16 v1.6 T.Yoshimoto Mod End 本番#1410
    -- ０除算回避判定
    IF (ln_chk_0 <> gn_0) THEN
      -- 値が[0]出なければ計算
      ln_kake_par := ROUND((in_nov_amount * 100) / ln_chk_0,2);
    ELSE
      -- 値が[0]の場合は、一律[0]設定
      ln_kake_par := gn_0;
    END IF;
--
-- 2009/04/16 v1.6 T.Yoshimoto Mod Star 本番#1410
/*
    -- 品目定価 = ０か、計算結果がマイナスの場合、固定値[70.00]を登録
    IF ((in_nov_amount = 0)
      AND (in_nov_price = 0)) THEN
      ln_kake_par := gn_0;
    ELSIF ((in_nov_price = 0)
      OR (ln_kake_par < 0)) THEN
      ln_kake_par := gn_kotei_70; -- 固定値[70.00]
    END IF;
*/
    -- 品目定価 = ０が存在している、または数量にマイナス値が存在している
    -- または計算結果がマイナスの場合、固定値[70.00]を登録
    IF (( in_nov_minus_flg = 'Y' ) OR ( in_nov_ht_zero_flg = 'Y' ) OR ( ln_kake_par < 0 ) ) THEN
--
      ln_kake_par := gn_kotei_70; -- 固定値[70.00]
--
    END IF;
-- 2009/04/16 v1.6 T.Yoshimoto Mod Star 本番#1410
--
    gt_xml_data_table(gl_xml_idx).tag_value := ln_kake_par;
--
    -- １２月 数量データ
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'dec_quant';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    gt_xml_data_table(gl_xml_idx).tag_value := in_dec_quant_t;
--
    -- １２月 金額データ
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'dec_amount';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    gt_xml_data_table(gl_xml_idx).tag_value := ROUND((in_dec_amount / 1000),0);
--
    -- １２月 粗利率データ
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'dec_arari_par';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    --------------------------------
    -- ０除算回避判定             --
    --------------------------------
    IF (in_dec_amount <> 0) THEN
      -- 値が[0]出なければ計算
      gt_xml_data_table(gl_xml_idx).tag_value := 
-- 2009/04/16 v1.6 T.Yoshimoto Mod Start 本番#1410
--            ROUND(((in_dec_amount - in_dec_to_amount * in_dec_quant) / in_dec_amount) * 100,2);
        ROUND(((in_dec_amount - in_dec_s_cost) / in_dec_amount) * 100,2);
-- 2009/04/16 v1.6 T.Yoshimoto Mod End 本番#1410
    ELSE
      -- 値が[0]の場合は、一律[0]設定
      gt_xml_data_table(gl_xml_idx).tag_value := gn_0;
    END IF;
--
    -- １２月 掛率データ
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'dec_kake_par';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    --------------------------------------
    -- ０除算判定項目へ判定値を挿入     --
    --------------------------------------
-- 2009/04/16 v1.6 T.Yoshimoto Mod Start 本番#1410
--    ln_chk_0 := in_dec_price * in_dec_quant;
    ln_chk_0 := in_dec_calc;
-- 2009/04/16 v1.6 T.Yoshimoto Mod End 本番#1410
    -- ０除算回避判定
    IF (ln_chk_0 <> gn_0) THEN
      -- 値が[0]出なければ計算
      ln_kake_par := ROUND((in_dec_amount * 100) / ln_chk_0,2);
    ELSE
      -- 値が[0]の場合は、一律[0]設定
      ln_kake_par := gn_0;
    END IF;
--
-- 2009/04/16 v1.6 T.Yoshimoto Mod Star 本番#1410
/*
    -- 品目定価 = ０か、計算結果がマイナスの場合、固定値[70.00]を登録
    IF ((in_dec_amount = 0)
      AND (in_dec_price = 0)) THEN
      ln_kake_par := gn_0;
    ELSIF ((in_dec_price = 0)
      OR (ln_kake_par < 0)) THEN
      ln_kake_par := gn_kotei_70; -- 固定値[70.00]
    END IF;
*/
    -- 品目定価 = ０が存在している、または数量にマイナス値が存在している
    -- または計算結果がマイナスの場合、固定値[70.00]を登録
    IF (( in_dec_minus_flg = 'Y' ) OR ( in_dec_ht_zero_flg = 'Y' ) OR ( ln_kake_par < 0 ) ) THEN
--
      ln_kake_par := gn_kotei_70; -- 固定値[70.00]
--
    END IF;
-- 2009/04/16 v1.6 T.Yoshimoto Mod Star 本番#1410
--
    gt_xml_data_table(gl_xml_idx).tag_value := ln_kake_par;
--
    -- １月 数量データ
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'jan_quant';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    gt_xml_data_table(gl_xml_idx).tag_value := in_jan_quant_t;
--
    -- １月 金額データ
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'jan_amount';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    gt_xml_data_table(gl_xml_idx).tag_value := ROUND((in_jan_amount / 1000),0);
--
    -- １月 粗利率データ
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'jan_arari_par';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    --------------------------------
    -- ０除算回避判定             --
    --------------------------------
    IF (in_jan_amount <> 0) THEN
      -- 値が[0]出なければ計算
      gt_xml_data_table(gl_xml_idx).tag_value := 
-- 2009/04/16 v1.6 T.Yoshimoto Mod Start 本番#1410
--            ROUND(((in_jan_amount - in_jan_to_amount * in_jan_quant) / in_jan_amount) * 100,2);
        ROUND(((in_jan_amount - in_jan_s_cost) / in_jan_amount) * 100,2);
-- 2009/04/16 v1.6 T.Yoshimoto Mod End 本番#1410
    ELSE
      -- 値が[0]の場合は、一律[0]設定
      gt_xml_data_table(gl_xml_idx).tag_value := gn_0;
    END IF;
--
    -- １月 掛率データ
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'jan_kake_par';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    --------------------------------------
    -- ０除算判定項目へ判定値を挿入     --
    --------------------------------------
-- 2009/04/16 v1.6 T.Yoshimoto Mod Start 本番#1410
--    ln_chk_0 := in_jan_price * in_jan_quant;
    ln_chk_0 := in_jan_calc;
-- 2009/04/16 v1.6 T.Yoshimoto Mod End 本番#1410
    -- ０除算回避判定
    IF (ln_chk_0 <> gn_0) THEN
      -- 値が[0]出なければ計算
      ln_kake_par := ROUND((in_jan_amount * 100) / ln_chk_0,2);
    ELSE
      -- 値が[0]の場合は、一律[0]設定
      ln_kake_par := gn_0;
    END IF;
--
-- 2009/04/16 v1.6 T.Yoshimoto Mod Star 本番#1410
/*
    -- 品目定価 = ０か、計算結果がマイナスの場合、固定値[70.00]を登録
    IF ((in_jan_amount = 0)
      AND (in_jan_price = 0)) THEN
      ln_kake_par := gn_0;
    ELSIF ((in_jan_price = 0)
      OR (ln_kake_par < 0)) THEN
      ln_kake_par := gn_kotei_70; -- 固定値[70.00]
    END IF;
*/
    -- 品目定価 = ０が存在している、または数量にマイナス値が存在している
    -- または計算結果がマイナスの場合、固定値[70.00]を登録
    IF (( in_jan_minus_flg = 'Y' ) OR ( in_jan_ht_zero_flg = 'Y' ) OR ( ln_kake_par < 0 ) ) THEN
--
      ln_kake_par := gn_kotei_70; -- 固定値[70.00]
--
    END IF;
-- 2009/04/16 v1.6 T.Yoshimoto Mod Star 本番#1410
--
    gt_xml_data_table(gl_xml_idx).tag_value := ln_kake_par;
--
    -- ２月 数量データ
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'feb_quant';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    gt_xml_data_table(gl_xml_idx).tag_value := in_feb_quant_t;
--
    -- ２月 金額データ
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'feb_amount';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    gt_xml_data_table(gl_xml_idx).tag_value := ROUND((in_feb_amount / 1000),0);
--
    -- ２月 粗利率データ
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'feb_arari_par';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    --------------------------------
    -- ０除算回避判定             --
    --------------------------------
    IF (in_feb_amount <> 0) THEN
      -- 値が[0]出なければ計算
      gt_xml_data_table(gl_xml_idx).tag_value := 
-- 2009/04/16 v1.6 T.Yoshimoto Mod Start 本番#1410
--            ROUND(((in_feb_amount - in_feb_to_amount * in_feb_quant) / in_feb_amount) * 100,2);
        ROUND(((in_feb_amount - in_feb_s_cost) / in_feb_amount) * 100,2);
-- 2009/04/16 v1.6 T.Yoshimoto Mod End 本番#1410
    ELSE
      -- 値が[0]の場合は、一律[0]設定
      gt_xml_data_table(gl_xml_idx).tag_value := gn_0;
    END IF;
--
    -- ２月 掛率データ
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'feb_kake_par';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    --------------------------------------
    -- ０除算判定項目へ判定値を挿入     --
    --------------------------------------
-- 2009/04/16 v1.6 T.Yoshimoto Mod Start 本番#1410
--    ln_chk_0 := in_feb_price * in_feb_quant;
    ln_chk_0 := in_feb_calc;
-- 2009/04/16 v1.6 T.Yoshimoto Mod End 本番#1410
    -- ０除算回避判定
    IF (ln_chk_0 <> gn_0) THEN
      -- 値が[0]出なければ計算
      ln_kake_par := ROUND((in_feb_amount * 100) / ln_chk_0,2);
    ELSE
      -- 値が[0]の場合は、一律[0]設定
      ln_kake_par := gn_0;
    END IF;
--
-- 2009/04/16 v1.6 T.Yoshimoto Mod Star 本番#1410
/*
    -- 品目定価 = ０か、計算結果がマイナスの場合、固定値[70.00]を登録
    IF ((in_feb_amount = 0)
      AND (in_feb_price = 0)) THEN
      ln_kake_par := gn_0;
    ELSIF ((in_feb_price = 0)
      OR (ln_kake_par < 0)) THEN
      ln_kake_par := gn_kotei_70; -- 固定値[70.00]
    END IF;
*/
    -- 品目定価 = ０が存在している、または数量にマイナス値が存在している
    -- または計算結果がマイナスの場合、固定値[70.00]を登録
    IF (( in_feb_minus_flg = 'Y' ) OR ( in_feb_ht_zero_flg = 'Y' ) OR ( ln_kake_par < 0 ) ) THEN
--
      ln_kake_par := gn_kotei_70; -- 固定値[70.00]
--
    END IF;
-- 2009/04/16 v1.6 T.Yoshimoto Mod Star 本番#1410
--
    gt_xml_data_table(gl_xml_idx).tag_value := ln_kake_par;
--
    -- ３月 数量データ
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'mar_quant';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    gt_xml_data_table(gl_xml_idx).tag_value := in_mar_quant_t;
--
    -- ３月 金額データ
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'mar_amount';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    gt_xml_data_table(gl_xml_idx).tag_value := ROUND((in_mar_amount / 1000),0);
--
    -- ３月 粗利率データ
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'mar_arari_par';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    --------------------------------
    -- ０除算回避判定             --
    --------------------------------
    IF (in_mar_amount <> 0) THEN
      -- 値が[0]出なければ計算
      gt_xml_data_table(gl_xml_idx).tag_value := 
-- 2009/04/16 v1.6 T.Yoshimoto Mod Start 本番#1410
--            ROUND(((in_mar_amount - in_mar_to_amount * in_mar_quant) / in_mar_amount) * 100,2);
        ROUND(((in_mar_amount - in_mar_s_cost) / in_mar_amount) * 100,2);
-- 2009/04/16 v1.6 T.Yoshimoto Mod End 本番#1410
    ELSE
      -- 値が[0]の場合は、一律[0]設定
      gt_xml_data_table(gl_xml_idx).tag_value := gn_0;
    END IF;
--
    -- ３月 掛率データ
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'mar_kake_par';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    --------------------------------------
    -- ０除算判定項目へ判定値を挿入     --
    --------------------------------------
-- 2009/04/16 v1.6 T.Yoshimoto Mod Start 本番#1410
--    ln_chk_0 := in_mar_price * in_mar_quant;
    ln_chk_0 := in_mar_calc;
-- 2009/04/16 v1.6 T.Yoshimoto Mod End 本番#1410
    -- ０除算回避判定
    IF (ln_chk_0 <> gn_0) THEN
      -- 値が[0]出なければ計算
      ln_kake_par := ROUND((in_mar_amount * 100) / ln_chk_0,2);
    ELSE
      -- 値が[0]の場合は、一律[0]設定
      ln_kake_par := gn_0;
    END IF;
--
-- 2009/04/16 v1.6 T.Yoshimoto Mod Star 本番#1410
/*
    -- 品目定価 = ０か、計算結果がマイナスの場合、固定値[70.00]を登録
    IF ((in_mar_amount = 0)
      AND (in_mar_price = 0)) THEN
      ln_kake_par := gn_0;
    ELSIF ((in_mar_price = 0)
      OR (ln_kake_par < 0)) THEN
      ln_kake_par := gn_kotei_70; -- 固定値[70.00]
    END IF;
*/
    -- 品目定価 = ０が存在している、または数量にマイナス値が存在している
    -- または計算結果がマイナスの場合、固定値[70.00]を登録
    IF (( in_mar_minus_flg = 'Y' ) OR ( in_mar_ht_zero_flg = 'Y' ) OR ( ln_kake_par < 0 ) ) THEN
--
      ln_kake_par := gn_kotei_70; -- 固定値[70.00]
--
    END IF;
-- 2009/04/16 v1.6 T.Yoshimoto Mod Star 本番#1410
--
    gt_xml_data_table(gl_xml_idx).tag_value := ln_kake_par;
--
    -- ４月 数量データ
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'apr_quant';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    gt_xml_data_table(gl_xml_idx).tag_value := in_apr_quant_t;
--
    -- ４月 金額データ
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'apr_amount';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    gt_xml_data_table(gl_xml_idx).tag_value := ROUND((in_apr_amount / 1000),0);
--
    -- ４月 粗利率データ
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'apr_arari_par';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    --------------------------------
    -- ０除算回避判定             --
    --------------------------------
    IF (in_apr_amount <> 0) THEN
      -- 値が[0]出なければ計算
      gt_xml_data_table(gl_xml_idx).tag_value := 
-- 2009/04/16 v1.6 T.Yoshimoto Mod Start 本番#1410
--            ROUND(((in_apr_amount - in_apr_to_amount * in_apr_quant) / in_apr_amount) * 100,2);
        ROUND(((in_apr_amount - in_apr_s_cost) / in_apr_amount) * 100,2);
-- 2009/04/16 v1.6 T.Yoshimoto Mod End 本番#1410
    ELSE
      -- 値が[0]の場合は、一律[0]設定
      gt_xml_data_table(gl_xml_idx).tag_value := gn_0;
    END IF;
--
    -- ４月 掛率データ
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'apr_kake_par';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    --------------------------------------
    -- ０除算判定項目へ判定値を挿入     --
    --------------------------------------
-- 2009/04/16 v1.6 T.Yoshimoto Mod Start 本番#1410
--    ln_chk_0 := in_apr_price * in_apr_quant;
    ln_chk_0 := in_apr_calc;
-- 2009/04/16 v1.6 T.Yoshimoto Mod End 本番#1410
    -- ０除算回避判定
    IF (ln_chk_0 <> gn_0) THEN
      -- 値が[0]出なければ計算
      ln_kake_par := ROUND((in_apr_amount * 100) / ln_chk_0,2);
    ELSE
      -- 値が[0]の場合は、一律[0]設定
      ln_kake_par := gn_0;
    END IF;
--
-- 2009/04/16 v1.6 T.Yoshimoto Mod Star 本番#1410
/*
    -- 品目定価 = ０か、計算結果がマイナスの場合、固定値[70.00]を登録
    IF ((in_apr_amount = 0)
      AND (in_apr_price = 0)) THEN
      ln_kake_par := gn_0;
    ELSIF ((in_apr_price = 0)
      OR (ln_kake_par < 0)) THEN
      ln_kake_par := gn_kotei_70; -- 固定値[70.00]
    END IF;
*/
    -- 品目定価 = ０が存在している、または数量にマイナス値が存在している
    -- または計算結果がマイナスの場合、固定値[70.00]を登録
    IF (( in_apr_minus_flg = 'Y' ) OR ( in_apr_ht_zero_flg = 'Y' ) OR ( ln_kake_par < 0 ) ) THEN
--
      ln_kake_par := gn_kotei_70; -- 固定値[70.00]
--
    END IF;
-- 2009/04/16 v1.6 T.Yoshimoto Mod Star 本番#1410
--
    gt_xml_data_table(gl_xml_idx).tag_value := ln_kake_par;
--
    -- 年計 数量データ
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'year_quant';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    gt_xml_data_table(gl_xml_idx).tag_value := in_year_quant_t;
--
    -- 年計 金額データ
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'year_amount';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    gt_xml_data_table(gl_xml_idx).tag_value := ROUND((in_year_amount / 1000),0);
--
    -- 年計 粗利率データ
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'year_arari_par';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    --------------------------------
    -- ０除算回避判定             --
    --------------------------------
    IF (in_year_amount <> 0) THEN
      -- 値が[0]出なければ計算
      gt_xml_data_table(gl_xml_idx).tag_value := 
-- 2009/04/16 v1.6 T.Yoshimoto Mod Start 本番#1410
--          ROUND(((in_year_amount - in_year_to_amount * in_year_quant) / in_year_amount) * 100,2);
        ROUND(((in_year_amount - in_year_s_cost) / in_year_amount) * 100,2);
-- 2009/04/16 v1.6 T.Yoshimoto Mod End 本番#1410
    ELSE
      -- 値が[0]の場合は、一律[0]設定
      gt_xml_data_table(gl_xml_idx).tag_value := gn_0;
    END IF;
--
    -- 年計 掛率データ
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'year_kake_par';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    --------------------------------------
    -- ０除算判定項目へ判定値を挿入     --
    --------------------------------------
-- 2009/04/16 v1.6 T.Yoshimoto Mod Start 本番#1410
--    ln_chk_0 := in_year_price * in_year_quant;
    ln_chk_0 := in_year_calc;
-- 2009/04/16 v1.6 T.Yoshimoto Mod End 本番#1410
    -- ０除算回避判定
    IF (ln_chk_0 <> gn_0) THEN
      -- 値が[0]出なければ計算
      ln_kake_par := ROUND((in_year_amount * 100) / ln_chk_0,2);
    ELSE
      -- 値が[0]の場合は、一律[0]設定
      ln_kake_par := gn_0;
    END IF;
--
-- 2009/04/16 v1.6 T.Yoshimoto Mod Star 本番#1410
/*
    -- 品目定価 = ０か、計算結果がマイナスの場合、固定値[70.00]を登録
    IF ((in_year_price = 0)
      OR (ln_kake_par < 0)) THEN
      ln_kake_par := gn_kotei_70; -- 固定値[70.00]
    END IF;
*/
    -- 品目定価 = ０が存在している、または数量にマイナス値が存在している
    -- または計算結果がマイナスの場合、固定値[70.00]を登録
    IF (( in_year_minus_flg = 'Y' ) OR ( in_year_ht_zero_flg = 'Y' ) OR ( ln_kake_par < 0 ) ) THEN
--
      ln_kake_par := gn_kotei_70; -- 固定値[70.00]
--
    END IF;
-- 2009/04/16 v1.6 T.Yoshimoto Mod Star 本番#1410
--
    gt_xml_data_table(gl_xml_idx).tag_value := ln_kake_par;
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
  END prc_create_xml_data_st_lt;
--
  /**********************************************************************************
   * Procedure Name   : prc_create_xml_data_s_k_t
   * Description      : XMLデータ作成 - 帳票データ出力 拠点計/商品区分計/総合計用
   ***********************************************************************************/
  PROCEDURE prc_create_xml_data_s_k_t
    (
      iv_label_name     IN VARCHAR2 -- 計タイトル
     ,in_may_quant      IN NUMBER   -- ５月 数量
     ,in_may_amount     IN NUMBER   -- ５月 金額
     ,in_may_price      IN NUMBER   -- ５月 品目定価
     ,in_may_to_amount  IN NUMBER   -- ５月 内訳合計
     ,in_may_quant_t    IN NUMBER   -- ５月 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
     ,in_may_s_cost     IN NUMBER   -- ５月 標準原価(計算用)
     ,in_may_calc       IN NUMBER   -- ５月 品目定価*数量(計算用)
     ,in_may_minus_flg   IN VARCHAR2 -- ５月 マイナス値存在フラグ(計算用)
     ,in_may_ht_zero_flg IN VARCHAR2 -- ５月 品目定価0値存在フラグ(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
     ,in_jun_quant      IN NUMBER   -- ６月 数量
     ,in_jun_amount     IN NUMBER   -- ６月 金額
     ,in_jun_price      IN NUMBER   -- ６月 品目定価
     ,in_jun_to_amount  IN NUMBER   -- ６月 内訳合計
     ,in_jun_quant_t    IN NUMBER   -- ６月 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
     ,in_jun_s_cost     IN NUMBER   -- ６月 標準原価(計算用)
     ,in_jun_calc       IN NUMBER   -- ６月 品目定価*数量(計算用)
     ,in_jun_minus_flg   IN VARCHAR2 -- ６月 マイナス値存在フラグ(計算用)
     ,in_jun_ht_zero_flg IN VARCHAR2 -- ６月 品目定価0値存在フラグ(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
     ,in_jul_quant      IN NUMBER   -- ７月 数量
     ,in_jul_amount     IN NUMBER   -- ７月 金額
     ,in_jul_price      IN NUMBER   -- ７月 品目定価
     ,in_jul_to_amount  IN NUMBER   -- ７月 内訳合計
     ,in_jul_quant_t    IN NUMBER   -- ７月 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
     ,in_jul_s_cost     IN NUMBER   -- ７月 標準原価(計算用)
     ,in_jul_calc       IN NUMBER   -- ７月 品目定価*数量(計算用)
     ,in_jul_minus_flg   IN VARCHAR2 -- ７月 マイナス値存在フラグ(計算用)
     ,in_jul_ht_zero_flg IN VARCHAR2 -- ７月 品目定価0値存在フラグ(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
     ,in_aug_quant      IN NUMBER   -- ８月 数量
     ,in_aug_amount     IN NUMBER   -- ８月 金額
     ,in_aug_price      IN NUMBER   -- ８月 品目定価
     ,in_aug_to_amount  IN NUMBER   -- ８月 内訳合計
     ,in_aug_quant_t    IN NUMBER   -- ８月 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
     ,in_aug_s_cost     IN NUMBER   -- ８月 標準原価(計算用)
     ,in_aug_calc       IN NUMBER   -- ８月 品目定価*数量(計算用)
     ,in_aug_minus_flg   IN VARCHAR2 -- ８月 マイナス値存在フラグ(計算用)
     ,in_aug_ht_zero_flg IN VARCHAR2 -- ８月 品目定価0値存在フラグ(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
     ,in_sep_quant      IN NUMBER   -- ９月 数量
     ,in_sep_amount     IN NUMBER   -- ９月 金額
     ,in_sep_price      IN NUMBER   -- ９月 品目定価
     ,in_sep_to_amount  IN NUMBER   -- ９月 内訳合計
     ,in_sep_quant_t    IN NUMBER   -- ９月 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
     ,in_sep_s_cost     IN NUMBER   -- ９月 標準原価(計算用)
     ,in_sep_calc       IN NUMBER   -- ９月 品目定価*数量(計算用)
     ,in_sep_minus_flg   IN VARCHAR2 -- ９月 マイナス値存在フラグ(計算用)
     ,in_sep_ht_zero_flg IN VARCHAR2 -- ９月 品目定価0値存在フラグ(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
     ,in_oct_quant      IN NUMBER   -- １０月 数量
     ,in_oct_amount     IN NUMBER   -- １０月 金額
     ,in_oct_price      IN NUMBER   -- １０月 品目定価
     ,in_oct_to_amount  IN NUMBER   -- １０月 内訳合計
     ,in_oct_quant_t    IN NUMBER   -- １０月 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
     ,in_oct_s_cost     IN NUMBER   -- １０月 標準原価(計算用)
     ,in_oct_calc       IN NUMBER   -- １０月 品目定価*数量(計算用)
     ,in_oct_minus_flg   IN VARCHAR2 -- １０月 マイナス値存在フラグ(計算用)
     ,in_oct_ht_zero_flg IN VARCHAR2 -- １０月 品目定価0値存在フラグ(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
     ,in_nov_quant      IN NUMBER   -- １１月 数量
     ,in_nov_amount     IN NUMBER   -- １１月 金額
     ,in_nov_price      IN NUMBER   -- １１月 品目定価
     ,in_nov_to_amount  IN NUMBER   -- １１月 内訳合計
     ,in_nov_quant_t    IN NUMBER   -- １１月 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
     ,in_nov_s_cost     IN NUMBER   -- １１月 標準原価(計算用)
     ,in_nov_calc       IN NUMBER   -- １１月 品目定価*数量(計算用)
     ,in_nov_minus_flg   IN VARCHAR2 -- １１月 マイナス値存在フラグ(計算用)
     ,in_nov_ht_zero_flg IN VARCHAR2 -- １１月 品目定価0値存在フラグ(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
     ,in_dec_quant      IN NUMBER   -- １２月 数量
     ,in_dec_amount     IN NUMBER   -- １２月 金額
     ,in_dec_price      IN NUMBER   -- １２月 品目定価
     ,in_dec_to_amount  IN NUMBER   -- １２月 内訳合計
     ,in_dec_quant_t    IN NUMBER   -- １２月 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
     ,in_dec_s_cost     IN NUMBER   -- １２月 標準原価(計算用)
     ,in_dec_calc       IN NUMBER   -- １２月 品目定価*数量(計算用)
     ,in_dec_minus_flg   IN VARCHAR2 -- １２月 マイナス値存在フラグ(計算用)
     ,in_dec_ht_zero_flg IN VARCHAR2 -- １２月 品目定価0値存在フラグ(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
     ,in_jan_quant      IN NUMBER   -- １月 数量
     ,in_jan_amount     IN NUMBER   -- １月 金額
     ,in_jan_price      IN NUMBER   -- １月 品目定価
     ,in_jan_to_amount  IN NUMBER   -- １月 内訳合計
     ,in_jan_quant_t    IN NUMBER   -- １月 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
     ,in_jan_s_cost     IN NUMBER   -- １月 標準原価(計算用)
     ,in_jan_calc       IN NUMBER   -- １月 品目定価*数量(計算用)
     ,in_jan_minus_flg   IN VARCHAR2 -- １月 マイナス値存在フラグ(計算用)
     ,in_jan_ht_zero_flg IN VARCHAR2 -- １月 品目定価0値存在フラグ(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
     ,in_feb_quant      IN NUMBER   -- ２月 数量
     ,in_feb_amount     IN NUMBER   -- ２月 金額
     ,in_feb_price      IN NUMBER   -- ２月 品目定価
     ,in_feb_to_amount  IN NUMBER   -- ２月 内訳合計
     ,in_feb_quant_t    IN NUMBER   -- ２月 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
     ,in_feb_s_cost     IN NUMBER   -- ２月 標準原価(計算用)
     ,in_feb_calc       IN NUMBER   -- ２月 品目定価*数量(計算用)
     ,in_feb_minus_flg   IN VARCHAR2 -- ２月 マイナス値存在フラグ(計算用)
     ,in_feb_ht_zero_flg IN VARCHAR2 -- ２月 品目定価0値存在フラグ(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
     ,in_mar_quant      IN NUMBER   -- ３月 数量
     ,in_mar_amount     IN NUMBER   -- ３月 金額
     ,in_mar_price      IN NUMBER   -- ３月 品目定価
     ,in_mar_to_amount  IN NUMBER   -- ３月 内訳合計
     ,in_mar_quant_t    IN NUMBER   -- ３月 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
     ,in_mar_s_cost     IN NUMBER   -- ３月 標準原価(計算用)
     ,in_mar_calc       IN NUMBER   -- ３月 品目定価*数量(計算用)
     ,in_mar_minus_flg   IN VARCHAR2 -- ３月 マイナス値存在フラグ(計算用)
     ,in_mar_ht_zero_flg IN VARCHAR2 -- ３月 品目定価0値存在フラグ(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
     ,in_apr_quant      IN NUMBER   -- ４月 数量
     ,in_apr_amount     IN NUMBER   -- ４月 金額
     ,in_apr_price      IN NUMBER   -- ４月 品目定価
     ,in_apr_to_amount  IN NUMBER   -- ４月 内訳合計
     ,in_apr_quant_t    IN NUMBER   -- ４月 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
     ,in_apr_s_cost     IN NUMBER   -- ４月 標準原価(計算用)
     ,in_apr_calc       IN NUMBER   -- ４月 品目定価*数量(計算用)
     ,in_apr_minus_flg   IN VARCHAR2 -- ４月 マイナス値存在フラグ(計算用)
     ,in_apr_ht_zero_flg IN VARCHAR2 -- ４月 品目定価0値存在フラグ(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
     ,in_year_quant     IN NUMBER   -- 年計 数量
     ,in_year_amount    IN NUMBER   -- 年計 金額
     ,in_year_price     IN NUMBER   -- 年計 品目定価
     ,in_year_to_amount IN NUMBER   -- 年計 内訳合計
     ,in_year_quant_t   IN NUMBER   -- 年計 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
     ,in_year_s_cost    IN NUMBER   -- 年計 標準原価(計算用)
     ,in_year_calc      IN NUMBER   -- 年計 品目定価*数量(計算用)
     ,in_year_minus_flg   IN VARCHAR2 -- 年計 マイナス値存在フラグ(計算用)
     ,in_year_ht_zero_flg IN VARCHAR2 -- 年計 品目定価0値存在フラグ(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
     ,ov_errbuf        OUT VARCHAR2 -- エラー・メッセージ           --# 固定 #
     ,ov_retcode       OUT VARCHAR2 -- リターン・コード             --# 固定 #
     ,ov_errmsg        OUT VARCHAR2 -- ユーザー・エラー・メッセージ --# 固定 #
    )
  IS
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_create_xml_data_s_k_t'; -- プログラム名
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
    ln_chk_0          NUMBER;     -- ０除算判定項目
    ln_kake_par       NUMBER;     -- 計算結果判定
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
    -- データタグ
    -- ====================================================
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
    -- ５月 数量データ
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'may_quant';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
-- 2009/05/29 v1.7 T.Yoshimoto Mod Start 本番#1509
--    gt_xml_data_table(gl_xml_idx).tag_value := in_may_quant;
    gt_xml_data_table(gl_xml_idx).tag_value := in_may_quant_t;
-- 2009/05/29 v1.7 T.Yoshimoto Mod End 本番#1509
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
--
    -- ５月 金額データ
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'may_amount';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    gt_xml_data_table(gl_xml_idx).tag_value := ROUND((in_may_amount / 1000),0);
--
    -- ５月 粗利率データ
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'may_arari_par';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    --------------------------------
    -- ０除算回避判定             --
    --------------------------------
    IF (in_may_amount <> 0) THEN
      -- 値が[0]出なければ計算
      gt_xml_data_table(gl_xml_idx).tag_value := 
-- 2009/04/16 v1.6 T.Yoshimoto Mod Start 本番#1410
--            ROUND(((in_may_amount - in_may_to_amount * in_may_quant) / in_may_amount) * 100,2);
        ROUND(((in_may_amount - in_may_s_cost) / in_may_amount) * 100,2);
-- 2009/04/16 v1.6 T.Yoshimoto Mod End 本番#1410
    ELSE
      -- 値が[0]の場合は、一律[0]設定
      gt_xml_data_table(gl_xml_idx).tag_value := gn_0;
    END IF;
--
    -- ５月 掛率データ
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'may_kake_par';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    --------------------------------------
    -- ０除算判定項目へ判定値を挿入     --
    --------------------------------------
-- 2009/04/16 v1.6 T.Yoshimoto Mod Start 本番#1410
--    ln_chk_0 := in_may_price * in_may_quant;
    ln_chk_0 := in_may_calc;
-- 2009/04/16 v1.6 T.Yoshimoto Mod End 本番#1410
    -- ０除算回避判定
    IF (ln_chk_0 <> gn_0) THEN
      -- 値が[0]出なければ計算
      ln_kake_par := ROUND((in_may_amount * 100) / ln_chk_0,2);
    ELSE
      -- 値が[0]の場合は、一律[0]設定
      ln_kake_par := gn_0;
    END IF;
--
-- 2009/04/16 v1.6 T.Yoshimoto Mod Star 本番#1410
/*
    -- 品目定価 = ０か、計算結果がマイナスの場合、固定値[70.00]を登録
    IF ((in_may_amount = 0)
      AND (in_may_price = 0)) THEN
      ln_kake_par := gn_0;
    ELSIF ((in_may_price = 0)
      OR (ln_kake_par < 0)) THEN
      ln_kake_par := gn_kotei_70; -- 固定値[70.00]
    END IF;
*/
    -- 品目定価 = ０が存在している、または数量にマイナス値が存在している
    -- または計算結果がマイナスの場合、固定値[70.00]を登録
    IF (( in_may_minus_flg = 'Y' ) OR ( in_may_ht_zero_flg = 'Y' ) OR ( ln_kake_par < 0 ) ) THEN
--
      ln_kake_par := gn_kotei_70; -- 固定値[70.00]
--
    END IF;
-- 2009/04/16 v1.6 T.Yoshimoto Mod Star 本番#1410
    gt_xml_data_table(gl_xml_idx).tag_value := ln_kake_par;
--
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
    -- ６月 数量データ
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'jun_quant';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
-- 2009/05/29 v1.7 T.Yoshimoto Mod Start 本番#1509
--    gt_xml_data_table(gl_xml_idx).tag_value := in_jun_quant;
    gt_xml_data_table(gl_xml_idx).tag_value := in_jun_quant_t;
-- 2009/05/29 v1.7 T.Yoshimoto Mod End 本番#1509
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
--
    -- ６月 金額データ
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'jun_amount';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    gt_xml_data_table(gl_xml_idx).tag_value := ROUND((in_jun_amount / 1000),0);
--
    -- ６月 粗利率データ
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'jun_arari_par';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    --------------------------------
    -- ０除算回避判定             --
    --------------------------------
    IF (in_jun_amount <> 0) THEN
      -- 値が[0]出なければ計算
      gt_xml_data_table(gl_xml_idx).tag_value := 
-- 2009/04/16 v1.6 T.Yoshimoto Mod Start 本番#1410
--            ROUND(((in_jun_amount - in_jun_to_amount * in_jun_quant) / in_jun_amount) * 100,2);
        ROUND(((in_jun_amount - in_jun_s_cost) / in_jun_amount) * 100,2);
-- 2009/04/16 v1.6 T.Yoshimoto Mod End 本番#1410
    ELSE
      -- 値が[0]の場合は、一律[0]設定
      gt_xml_data_table(gl_xml_idx).tag_value := gn_0;
    END IF;
--
    -- ６月 掛率データ
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'jun_kake_par';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    --------------------------------------
    -- ０除算判定項目へ判定値を挿入     --
    --------------------------------------
-- 2009/04/16 v1.6 T.Yoshimoto Mod Start 本番#1410
--    ln_chk_0 := in_jun_price * in_jun_quant;
    ln_chk_0 := in_jun_calc;
-- 2009/04/16 v1.6 T.Yoshimoto Mod End 本番#1410
    -- ０除算回避判定
    IF (ln_chk_0 <> gn_0) THEN
      -- 値が[0]出なければ計算
      ln_kake_par := ROUND((in_jun_amount * 100) / ln_chk_0,2);
    ELSE
      -- 値が[0]の場合は、一律[0]設定
      ln_kake_par := gn_0;
    END IF;
--
-- 2009/04/16 v1.6 T.Yoshimoto Mod Star 本番#1410
/*
    -- 品目定価 = ０か、計算結果がマイナスの場合、固定値[70.00]を登録
    IF ((in_jun_amount = 0)
      AND (in_jun_price = 0)) THEN
      ln_kake_par := gn_0;
    ELSIF ((in_jun_price = 0)
      OR (ln_kake_par < 0)) THEN
      ln_kake_par := gn_kotei_70; -- 固定値[70.00]
    END IF;
*/
    -- 品目定価 = ０が存在している、または数量にマイナス値が存在している
    -- または計算結果がマイナスの場合、固定値[70.00]を登録
    IF (( in_jun_minus_flg = 'Y' ) OR ( in_jun_ht_zero_flg = 'Y' ) OR ( ln_kake_par < 0 ) ) THEN
--
      ln_kake_par := gn_kotei_70; -- 固定値[70.00]
--
    END IF;
-- 2009/04/16 v1.6 T.Yoshimoto Mod Star 本番#1410
    gt_xml_data_table(gl_xml_idx).tag_value := ln_kake_par;
--
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
    -- ７月 数量データ
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'jul_quant';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
-- 2009/05/29 v1.7 T.Yoshimoto Mod Start 本番#1509
--    gt_xml_data_table(gl_xml_idx).tag_value := in_jul_quant;
    gt_xml_data_table(gl_xml_idx).tag_value := in_jul_quant_t;
-- 2009/05/29 v1.7 T.Yoshimoto Mod End 本番#1509
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
--
    -- ７月 金額データ
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'jul_amount';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    gt_xml_data_table(gl_xml_idx).tag_value := ROUND((in_jul_amount / 1000),0);
--
    -- ７月 粗利率データ
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'jul_arari_par';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    --------------------------------
    -- ０除算回避判定             --
    --------------------------------
    IF (in_jul_amount <> 0) THEN
      -- 値が[0]出なければ計算
      gt_xml_data_table(gl_xml_idx).tag_value := 
-- 2009/04/16 v1.6 T.Yoshimoto Mod Start 本番#1410
--            ROUND(((in_jul_amount - in_jul_to_amount * in_jul_quant) / in_jul_amount) * 100,2);
        ROUND(((in_jul_amount - in_jul_s_cost) / in_jul_amount) * 100,2);
-- 2009/04/16 v1.6 T.Yoshimoto Mod End 本番#1410
    ELSE
      -- 値が[0]の場合は、一律[0]設定
      gt_xml_data_table(gl_xml_idx).tag_value := gn_0;
    END IF;
--
    -- ７月 掛率データ
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'jul_kake_par';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    --------------------------------------
    -- ０除算判定項目へ判定値を挿入     --
    --------------------------------------
-- 2009/04/16 v1.6 T.Yoshimoto Mod Start 本番#1410
--    ln_chk_0 := in_jul_price * in_jul_quant;
    ln_chk_0 := in_jul_calc;
-- 2009/04/16 v1.6 T.Yoshimoto Mod End 本番#1410
    -- ０除算回避判定
    IF (ln_chk_0 <> gn_0) THEN
      -- 値が[0]出なければ計算
      ln_kake_par := ROUND((in_jul_amount * 100) / ln_chk_0,2);
    ELSE
      -- 値が[0]の場合は、一律[0]設定
      ln_kake_par := gn_0;
    END IF;
--
-- 2009/04/16 v1.6 T.Yoshimoto Mod Star 本番#1410
/*
    -- 品目定価 = ０か、計算結果がマイナスの場合、固定値[70.00]を登録
    IF ((in_jul_amount = 0)
      AND (in_jul_price = 0)) THEN
      ln_kake_par := gn_0;
    ELSIF ((in_jul_price = 0)
      OR (ln_kake_par < 0)) THEN
      ln_kake_par := gn_kotei_70; -- 固定値[70.00]
    END IF;
*/
    -- 品目定価 = ０が存在している、または数量にマイナス値が存在している
    -- または計算結果がマイナスの場合、固定値[70.00]を登録
    IF (( in_jul_minus_flg = 'Y' ) OR ( in_jul_ht_zero_flg = 'Y' ) OR ( ln_kake_par < 0 ) ) THEN
--
      ln_kake_par := gn_kotei_70; -- 固定値[70.00]
--
    END IF;
-- 2009/04/16 v1.6 T.Yoshimoto Mod Star 本番#1410
    gt_xml_data_table(gl_xml_idx).tag_value := ln_kake_par;
--
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
    -- ８月 数量データ
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'aug_quant';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
-- 2009/05/29 v1.7 T.Yoshimoto Mod Start 本番#1509
--    gt_xml_data_table(gl_xml_idx).tag_value := in_aug_quant;
    gt_xml_data_table(gl_xml_idx).tag_value := in_aug_quant_t;
-- 2009/05/29 v1.7 T.Yoshimoto Mod End 本番#1509
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
--
    -- ８月 金額データ
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'aug_amount';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    gt_xml_data_table(gl_xml_idx).tag_value := ROUND((in_aug_amount / 1000),0);
--
    -- ８月 粗利率データ
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'aug_arari_par';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    --------------------------------
    -- ０除算回避判定             --
    --------------------------------
    IF (in_aug_amount <> 0) THEN
      -- 値が[0]出なければ計算
      gt_xml_data_table(gl_xml_idx).tag_value := 
-- 2009/04/16 v1.6 T.Yoshimoto Mod Start 本番#1410
--            ROUND(((in_aug_amount - in_aug_to_amount * in_aug_quant) / in_aug_amount) * 100,2);
        ROUND(((in_aug_amount - in_aug_s_cost) / in_aug_amount) * 100,2);
-- 2009/04/16 v1.6 T.Yoshimoto Mod End 本番#1410
    ELSE
      -- 値が[0]の場合は、一律[0]設定
      gt_xml_data_table(gl_xml_idx).tag_value := gn_0;
    END IF;
--
    -- ８月 掛率データ
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'aug_kake_par';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    --------------------------------------
    -- ０除算判定項目へ判定値を挿入     --
    --------------------------------------
-- 2009/04/16 v1.6 T.Yoshimoto Mod Start 本番#1410
--    ln_chk_0 := in_aug_price * in_aug_quant;
    ln_chk_0 := in_aug_calc;
-- 2009/04/16 v1.6 T.Yoshimoto Mod End 本番#1410
    -- ０除算回避判定
    IF (ln_chk_0 <> gn_0) THEN
      -- 値が[0]出なければ計算
      ln_kake_par := ROUND((in_aug_amount * 100) / ln_chk_0,2);
    ELSE
      -- 値が[0]の場合は、一律[0]設定
      ln_kake_par := gn_0;
    END IF;
--
-- 2009/04/16 v1.6 T.Yoshimoto Mod Star 本番#1410
/*
    -- 品目定価 = ０か、計算結果がマイナスの場合、固定値[70.00]を登録
    IF ((in_aug_amount = 0)
      AND (in_aug_price = 0)) THEN
      ln_kake_par := gn_0;
    ELSIF ((in_aug_price = 0)
      OR (ln_kake_par < 0)) THEN
      ln_kake_par := gn_kotei_70; -- 固定値[70.00]
    END IF;
*/
    -- 品目定価 = ０が存在している、または数量にマイナス値が存在している
    -- または計算結果がマイナスの場合、固定値[70.00]を登録
    IF (( in_aug_minus_flg = 'Y' ) OR ( in_aug_ht_zero_flg = 'Y' ) OR ( ln_kake_par < 0 ) ) THEN
--
      ln_kake_par := gn_kotei_70; -- 固定値[70.00]
--
    END IF;
-- 2009/04/16 v1.6 T.Yoshimoto Mod Star 本番#1410
    gt_xml_data_table(gl_xml_idx).tag_value := ln_kake_par;
--
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
    -- ９月 数量データ
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'sep_quant';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
-- 2009/05/29 v1.7 T.Yoshimoto Mod Start 本番#1509
--    gt_xml_data_table(gl_xml_idx).tag_value := in_sep_quant;
    gt_xml_data_table(gl_xml_idx).tag_value := in_sep_quant_t;
-- 2009/05/29 v1.7 T.Yoshimoto Mod End 本番#1509
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
--
    -- ９月 金額データ
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'sep_amount';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    gt_xml_data_table(gl_xml_idx).tag_value := ROUND((in_sep_amount / 1000),0);
--
    -- ９月 粗利率データ
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'sep_arari_par';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    --------------------------------
    -- ０除算回避判定             --
    --------------------------------
    IF (in_sep_amount <> 0) THEN
      -- 値が[0]出なければ計算
      gt_xml_data_table(gl_xml_idx).tag_value := 
-- 2009/04/16 v1.6 T.Yoshimoto Mod Start 本番#1410
--            ROUND(((in_sep_amount - in_sep_to_amount * in_sep_quant) / in_sep_amount) * 100,2);
        ROUND(((in_sep_amount - in_sep_s_cost) / in_sep_amount) * 100,2);
-- 2009/04/16 v1.6 T.Yoshimoto Mod End 本番#1410
    ELSE
      -- 値が[0]の場合は、一律[0]設定
      gt_xml_data_table(gl_xml_idx).tag_value := gn_0;
    END IF;
--
    -- ９月 掛率データ
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'sep_kake_par';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    --------------------------------------
    -- ０除算判定項目へ判定値を挿入     --
    --------------------------------------
-- 2009/04/16 v1.6 T.Yoshimoto Mod Start 本番#1410
--    ln_chk_0 := in_sep_price * in_sep_quant;
    ln_chk_0 := in_sep_calc;
-- 2009/04/16 v1.6 T.Yoshimoto Mod End 本番#1410
    -- ０除算回避判定
    IF (ln_chk_0 <> gn_0) THEN
      -- 値が[0]出なければ計算
      ln_kake_par := ROUND((in_sep_amount * 100) / ln_chk_0,2);
    ELSE
      -- 値が[0]の場合は、一律[0]設定
      ln_kake_par := gn_0;
    END IF;
--
-- 2009/04/16 v1.6 T.Yoshimoto Mod Star 本番#1410
/*
    -- 品目定価 = ０か、計算結果がマイナスの場合、固定値[70.00]を登録
    IF ((in_sep_amount = 0)
      AND (in_sep_price = 0)) THEN
      ln_kake_par := gn_0;
    ELSIF ((in_sep_price = 0)
      OR (ln_kake_par < 0)) THEN
      ln_kake_par := gn_kotei_70; -- 固定値[70.00]
    END IF;
*/
    -- 品目定価 = ０が存在している、または数量にマイナス値が存在している
    -- または計算結果がマイナスの場合、固定値[70.00]を登録
    IF (( in_sep_minus_flg = 'Y' ) OR ( in_sep_ht_zero_flg = 'Y' ) OR ( ln_kake_par < 0 ) ) THEN
--
      ln_kake_par := gn_kotei_70; -- 固定値[70.00]
--
    END IF;
-- 2009/04/16 v1.6 T.Yoshimoto Mod Star 本番#1410
    gt_xml_data_table(gl_xml_idx).tag_value := ln_kake_par;
--
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
    -- １０月 数量データ
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'oct_quant';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
-- 2009/05/29 v1.7 T.Yoshimoto Mod Start 本番#1509
--    gt_xml_data_table(gl_xml_idx).tag_value := in_oct_quant;
    gt_xml_data_table(gl_xml_idx).tag_value := in_oct_quant_t;
-- 2009/05/29 v1.7 T.Yoshimoto Mod End 本番#1509
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
--
    -- １０月 金額データ
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'oct_amount';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    gt_xml_data_table(gl_xml_idx).tag_value := ROUND((in_oct_amount / 1000),0);
--
    -- １０月 粗利率データ
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'oct_arari_par';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    --------------------------------
    -- ０除算回避判定             --
    --------------------------------
    IF (in_oct_amount <> 0) THEN
      -- 値が[0]出なければ計算
      gt_xml_data_table(gl_xml_idx).tag_value := 
-- 2009/04/16 v1.6 T.Yoshimoto Mod Start 本番#1410
--            ROUND(((in_oct_amount - in_oct_to_amount * in_oct_quant) / in_oct_amount) * 100,2);
        ROUND(((in_oct_amount - in_oct_s_cost) / in_oct_amount) * 100,2);
-- 2009/04/16 v1.6 T.Yoshimoto Mod End 本番#1410
    ELSE
      -- 値が[0]の場合は、一律[0]設定
      gt_xml_data_table(gl_xml_idx).tag_value := gn_0;
    END IF;
--
    -- １０月 掛率データ
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'oct_kake_par';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    --------------------------------------
    -- ０除算判定項目へ判定値を挿入     --
    --------------------------------------
-- 2009/04/16 v1.6 T.Yoshimoto Mod Start 本番#1410
--    ln_chk_0 := in_oct_price * in_oct_quant;
    ln_chk_0 := in_oct_calc;
-- 2009/04/16 v1.6 T.Yoshimoto Mod End 本番#1410
    -- ０除算回避判定
    IF (ln_chk_0 <> gn_0) THEN
      -- 値が[0]出なければ計算
      ln_kake_par := ROUND((in_oct_amount * 100) / ln_chk_0,2);
    ELSE
      -- 値が[0]の場合は、一律[0]設定
      ln_kake_par := gn_0;
    END IF;
--
-- 2009/04/16 v1.6 T.Yoshimoto Mod Star 本番#1410
/*
    -- 品目定価 = ０か、計算結果がマイナスの場合、固定値[70.00]を登録
    IF ((in_oct_amount = 0)
      AND (in_oct_price = 0)) THEN
      ln_kake_par := gn_0;
    ELSIF ((in_oct_price = 0)
      OR (ln_kake_par < 0)) THEN
      ln_kake_par := gn_kotei_70; -- 固定値[70.00]
    END IF;
*/
    -- 品目定価 = ０が存在している、または数量にマイナス値が存在している
    -- または計算結果がマイナスの場合、固定値[70.00]を登録
    IF (( in_oct_minus_flg = 'Y' ) OR ( in_oct_ht_zero_flg = 'Y' ) OR ( ln_kake_par < 0 ) ) THEN
--
      ln_kake_par := gn_kotei_70; -- 固定値[70.00]
--
    END IF;
-- 2009/04/16 v1.6 T.Yoshimoto Mod Star 本番#1410
    gt_xml_data_table(gl_xml_idx).tag_value := ln_kake_par;
--
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
    -- １１月 数量データ
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'nov_quant';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
-- 2009/05/29 v1.7 T.Yoshimoto Mod Start 本番#1509
--    gt_xml_data_table(gl_xml_idx).tag_value := in_nov_quant;
    gt_xml_data_table(gl_xml_idx).tag_value := in_nov_quant_t;
-- 2009/05/29 v1.7 T.Yoshimoto Mod End 本番#1509
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
--
    -- １１月 金額データ
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'nov_amount';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    gt_xml_data_table(gl_xml_idx).tag_value := ROUND((in_nov_amount / 1000),0);
--
    -- １１月 粗利率データ
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'nov_arari_par';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    --------------------------------
    -- ０除算回避判定             --
    --------------------------------
    IF (in_nov_amount <> 0) THEN
      -- 値が[0]出なければ計算
      gt_xml_data_table(gl_xml_idx).tag_value := 
-- 2009/04/16 v1.6 T.Yoshimoto Mod Start 本番#1410
--            ROUND(((in_nov_amount - in_nov_to_amount * in_nov_quant) / in_nov_amount) * 100,2);
        ROUND(((in_nov_amount - in_nov_s_cost) / in_nov_amount) * 100,2);
-- 2009/04/16 v1.6 T.Yoshimoto Mod End 本番#1410
    ELSE
      -- 値が[0]の場合は、一律[0]設定
      gt_xml_data_table(gl_xml_idx).tag_value := gn_0;
    END IF;
--
    -- １１月 掛率データ
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'nov_kake_par';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    --------------------------------------
    -- ０除算判定項目へ判定値を挿入     --
    --------------------------------------
-- 2009/04/16 v1.6 T.Yoshimoto Mod Start 本番#1410
--    ln_chk_0 := in_nov_price * in_nov_quant;
    ln_chk_0 := in_nov_calc;
-- 2009/04/16 v1.6 T.Yoshimoto Mod End 本番#1410
    -- ０除算回避判定
    IF (ln_chk_0 <> gn_0) THEN
      -- 値が[0]出なければ計算
      ln_kake_par := ROUND((in_nov_amount * 100) / ln_chk_0,2);
    ELSE
      -- 値が[0]の場合は、一律[0]設定
      ln_kake_par := gn_0;
    END IF;
--
-- 2009/04/16 v1.6 T.Yoshimoto Mod Star 本番#1410
/*
    -- 品目定価 = ０か、計算結果がマイナスの場合、固定値[70.00]を登録
    IF ((in_nov_amount = 0)
      AND (in_nov_price = 0)) THEN
      ln_kake_par := gn_0;
    ELSIF ((in_nov_price = 0)
      OR (ln_kake_par < 0)) THEN
      ln_kake_par := gn_kotei_70; -- 固定値[70.00]
    END IF;
*/
    -- 品目定価 = ０が存在している、または数量にマイナス値が存在している
    -- または計算結果がマイナスの場合、固定値[70.00]を登録
    IF (( in_nov_minus_flg = 'Y' ) OR ( in_nov_ht_zero_flg = 'Y' ) OR ( ln_kake_par < 0 ) ) THEN
--
      ln_kake_par := gn_kotei_70; -- 固定値[70.00]
--
    END IF;
-- 2009/04/16 v1.6 T.Yoshimoto Mod Star 本番#1410
    gt_xml_data_table(gl_xml_idx).tag_value := ln_kake_par;
--
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
    -- １２月 数量データ
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'dec_quant';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
-- 2009/05/29 v1.7 T.Yoshimoto Mod Start 本番#1509
--    gt_xml_data_table(gl_xml_idx).tag_value := in_dec_quant;
    gt_xml_data_table(gl_xml_idx).tag_value := in_dec_quant_t;
-- 2009/05/29 v1.7 T.Yoshimoto Mod End 本番#1509
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
--
    -- １２月 金額データ
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'dec_amount';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    gt_xml_data_table(gl_xml_idx).tag_value := ROUND((in_dec_amount / 1000),0);
--
    -- １２月 粗利率データ
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'dec_arari_par';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    --------------------------------
    -- ０除算回避判定             --
    --------------------------------
    IF (in_dec_amount <> 0) THEN
      -- 値が[0]出なければ計算
      gt_xml_data_table(gl_xml_idx).tag_value := 
-- 2009/04/16 v1.6 T.Yoshimoto Mod Start 本番#1410
--            ROUND(((in_dec_amount - in_dec_to_amount * in_dec_quant) / in_dec_amount) * 100,2);
            ROUND(((in_dec_amount - in_dec_s_cost) / in_dec_amount) * 100,2);
-- 2009/04/16 v1.6 T.Yoshimoto Mod End 本番#1410

    ELSE
      -- 値が[0]の場合は、一律[0]設定
      gt_xml_data_table(gl_xml_idx).tag_value := gn_0;
    END IF;
--
    -- １２月 掛率データ
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'dec_kake_par';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    --------------------------------------
    -- ０除算判定項目へ判定値を挿入     --
    --------------------------------------
-- 2009/04/16 v1.6 T.Yoshimoto Mod Start 本番#1410
--    ln_chk_0 := in_dec_price * in_dec_quant;
    ln_chk_0 := in_dec_calc;
-- 2009/04/16 v1.6 T.Yoshimoto Mod End 本番#1410
    -- ０除算回避判定
    IF (ln_chk_0 <> gn_0) THEN
      -- 値が[0]出なければ計算
      ln_kake_par := ROUND((in_dec_amount * 100) / ln_chk_0,2);
    ELSE
      -- 値が[0]の場合は、一律[0]設定
      ln_kake_par := gn_0;
    END IF;
--
-- 2009/04/16 v1.6 T.Yoshimoto Mod Star 本番#1410
/*
    -- 品目定価 = ０か、計算結果がマイナスの場合、固定値[70.00]を登録
    IF ((in_dec_amount = 0)
      AND (in_dec_price = 0)) THEN
      ln_kake_par := gn_0;
    ELSIF ((in_dec_price = 0)
      OR (ln_kake_par < 0)) THEN
      ln_kake_par := gn_kotei_70; -- 固定値[70.00]
    END IF;
*/
    -- 品目定価 = ０が存在している、または数量にマイナス値が存在している
    -- または計算結果がマイナスの場合、固定値[70.00]を登録
    IF (( in_dec_minus_flg = 'Y' ) OR ( in_dec_ht_zero_flg = 'Y' ) OR ( ln_kake_par < 0 ) ) THEN
--
      ln_kake_par := gn_kotei_70; -- 固定値[70.00]
--
    END IF;
-- 2009/04/16 v1.6 T.Yoshimoto Mod Star 本番#1410
    gt_xml_data_table(gl_xml_idx).tag_value := ln_kake_par;
--
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
    -- １月 数量データ
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'jan_quant';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
-- 2009/05/29 v1.7 T.Yoshimoto Mod Start 本番#1509
--    gt_xml_data_table(gl_xml_idx).tag_value := in_jan_quant;
    gt_xml_data_table(gl_xml_idx).tag_value := in_jan_quant_T;
-- 2009/05/29 v1.7 T.Yoshimoto Mod End 本番#1509
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
--
    -- １月 金額データ
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'jan_amount';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    gt_xml_data_table(gl_xml_idx).tag_value := ROUND((in_jan_amount / 1000),0);
--
    -- １月 粗利率データ
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'jan_arari_par';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    --------------------------------
    -- ０除算回避判定             --
    --------------------------------
    IF (in_jan_amount <> 0) THEN
      -- 値が[0]出なければ計算
      gt_xml_data_table(gl_xml_idx).tag_value := 
-- 2009/04/16 v1.6 T.Yoshimoto Mod Start 本番#1410
--            ROUND(((in_jan_amount - in_jan_to_amount * in_jan_quant) / in_jan_amount) * 100,2);
        ROUND(((in_jan_amount - in_jan_s_cost) / in_jan_amount) * 100,2);
-- 2009/04/16 v1.6 T.Yoshimoto Mod End 本番#1410
    ELSE
      -- 値が[0]の場合は、一律[0]設定
      gt_xml_data_table(gl_xml_idx).tag_value := gn_0;
    END IF;
--
    -- １月 掛率データ
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'jan_kake_par';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    --------------------------------------
    -- ０除算判定項目へ判定値を挿入     --
    --------------------------------------
-- 2009/04/16 v1.6 T.Yoshimoto Mod Start 本番#1410
--    ln_chk_0 := in_jan_price * in_jan_quant;
    ln_chk_0 := in_jan_calc;
-- 2009/04/16 v1.6 T.Yoshimoto Mod End 本番#1410
    -- ０除算回避判定
    IF (ln_chk_0 <> gn_0) THEN
      -- 値が[0]出なければ計算
      ln_kake_par := ROUND((in_jan_amount * 100) / ln_chk_0,2);
    ELSE
      -- 値が[0]の場合は、一律[0]設定
      ln_kake_par := gn_0;
    END IF;
--
-- 2009/04/16 v1.6 T.Yoshimoto Mod Star 本番#1410
/*
    -- 品目定価 = ０か、計算結果がマイナスの場合、固定値[70.00]を登録
    IF ((in_jan_amount = 0)
      AND (in_jan_price = 0)) THEN
      ln_kake_par := gn_0;
    ELSIF ((in_jan_price = 0)
      OR (ln_kake_par < 0)) THEN
      ln_kake_par := gn_kotei_70; -- 固定値[70.00]
    END IF;
*/
    -- 品目定価 = ０が存在している、または数量にマイナス値が存在している
    -- または計算結果がマイナスの場合、固定値[70.00]を登録
    IF (( in_jan_minus_flg = 'Y' ) OR ( in_jan_ht_zero_flg = 'Y' ) OR ( ln_kake_par < 0 ) ) THEN
--
      ln_kake_par := gn_kotei_70; -- 固定値[70.00]
--
    END IF;
-- 2009/04/16 v1.6 T.Yoshimoto Mod Star 本番#1410
    gt_xml_data_table(gl_xml_idx).tag_value := ln_kake_par;
--
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
    -- ２月 数量データ
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'feb_quant';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
-- 2009/05/29 v1.7 T.Yoshimoto Mod Start 本番#1509
--    gt_xml_data_table(gl_xml_idx).tag_value := in_feb_quant;
    gt_xml_data_table(gl_xml_idx).tag_value := in_feb_quant_t;
-- 2009/05/29 v1.7 T.Yoshimoto Mod End 本番#1509
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
--
    -- ２月 金額データ
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'feb_amount';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    gt_xml_data_table(gl_xml_idx).tag_value := ROUND((in_feb_amount / 1000),0);
--
    -- ２月 粗利率データ
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'feb_arari_par';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    --------------------------------
    -- ０除算回避判定             --
    --------------------------------
    IF (in_feb_amount <> 0) THEN
      -- 値が[0]出なければ計算
      gt_xml_data_table(gl_xml_idx).tag_value := 
-- 2009/04/16 v1.6 T.Yoshimoto Mod Start 本番#1410
--            ROUND(((in_feb_amount - in_feb_to_amount * in_feb_quant) / in_feb_amount) * 100,2);
        ROUND(((in_feb_amount - in_feb_s_cost) / in_feb_amount) * 100,2);
-- 2009/04/16 v1.6 T.Yoshimoto Mod End 本番#1410
    ELSE
      -- 値が[0]の場合は、一律[0]設定
      gt_xml_data_table(gl_xml_idx).tag_value := gn_0;
    END IF;
--
    -- ２月 掛率データ
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'feb_kake_par';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    --------------------------------------
    -- ０除算判定項目へ判定値を挿入     --
    --------------------------------------
-- 2009/04/16 v1.6 T.Yoshimoto Mod Start 本番#1410
--    ln_chk_0 := in_feb_price * in_feb_quant;
    ln_chk_0 := in_feb_calc;
    -- ０除算回避判定
    IF (ln_chk_0 <> gn_0) THEN
      -- 値が[0]出なければ計算
      ln_kake_par := ROUND((in_feb_amount * 100) / ln_chk_0,2);
    ELSE
      -- 値が[0]の場合は、一律[0]設定
      ln_kake_par := gn_0;
    END IF;
--
-- 2009/04/16 v1.6 T.Yoshimoto Mod Star 本番#1410
/*
    -- 品目定価 = ０か、計算結果がマイナスの場合、固定値[70.00]を登録
    IF ((in_feb_amount = 0)
      AND (in_feb_price = 0)) THEN
      ln_kake_par := gn_0;
    ELSIF ((in_feb_price = 0)
      OR (ln_kake_par < 0)) THEN
      ln_kake_par := gn_kotei_70; -- 固定値[70.00]
    END IF;
*/
    -- 品目定価 = ０が存在している、または数量にマイナス値が存在している
    -- または計算結果がマイナスの場合、固定値[70.00]を登録
    IF (( in_feb_minus_flg = 'Y' ) OR ( in_feb_ht_zero_flg = 'Y' ) OR ( ln_kake_par < 0 ) ) THEN
--
      ln_kake_par := gn_kotei_70; -- 固定値[70.00]
--
    END IF;
-- 2009/04/16 v1.6 T.Yoshimoto Mod Star 本番#1410
    gt_xml_data_table(gl_xml_idx).tag_value := ln_kake_par;
--
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
    -- ３月 数量データ
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'mar_quant';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
-- 2009/05/29 v1.7 T.Yoshimoto Mod Start 本番#1509
--    gt_xml_data_table(gl_xml_idx).tag_value := in_mar_quant;
    gt_xml_data_table(gl_xml_idx).tag_value := in_mar_quant_t;
-- 2009/05/29 v1.7 T.Yoshimoto Mod end 本番#1509
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
--
    -- ３月 金額データ
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'mar_amount';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    gt_xml_data_table(gl_xml_idx).tag_value := ROUND((in_mar_amount / 1000),0);
--
    -- ３月 粗利率データ
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'mar_arari_par';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    --------------------------------
    -- ０除算回避判定             --
    --------------------------------
    IF (in_mar_amount <> 0) THEN
      -- 値が[0]出なければ計算
      gt_xml_data_table(gl_xml_idx).tag_value := 
-- 2009/04/16 v1.6 T.Yoshimoto Mod Start 本番#1410
--            ROUND(((in_mar_amount - in_mar_to_amount * in_mar_quant) / in_mar_amount) * 100,2);
        ROUND(((in_mar_amount - in_mar_s_cost) / in_mar_amount) * 100,2);
-- 2009/04/16 v1.6 T.Yoshimoto Mod End 本番#1410
    ELSE
      -- 値が[0]の場合は、一律[0]設定
      gt_xml_data_table(gl_xml_idx).tag_value := gn_0;
    END IF;
--
    -- ３月 掛率データ
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'mar_kake_par';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    --------------------------------------
    -- ０除算判定項目へ判定値を挿入     --
    --------------------------------------
-- 2009/04/16 v1.6 T.Yoshimoto Mod Start 本番#1410
--    ln_chk_0 := in_mar_price * in_mar_quant;
    ln_chk_0 := in_mar_calc;
    -- ０除算回避判定
    IF (ln_chk_0 <> gn_0) THEN
      -- 値が[0]出なければ計算
      ln_kake_par := ROUND((in_mar_amount * 100) / ln_chk_0,2);
    ELSE
      -- 値が[0]の場合は、一律[0]設定
      ln_kake_par := gn_0;
    END IF;
--
-- 2009/04/16 v1.6 T.Yoshimoto Mod Star 本番#1410
/*
    -- 品目定価 = ０か、計算結果がマイナスの場合、固定値[70.00]を登録
    IF ((in_mar_amount = 0)
      AND (in_mar_price = 0)) THEN
      ln_kake_par := gn_0;
    ELSIF ((in_mar_price = 0)
      OR (ln_kake_par < 0)) THEN
      ln_kake_par := gn_kotei_70; -- 固定値[70.00]
    END IF;
*/
    -- 品目定価 = ０が存在している、または数量にマイナス値が存在している
    -- または計算結果がマイナスの場合、固定値[70.00]を登録
    IF (( in_mar_minus_flg = 'Y' ) OR ( in_mar_ht_zero_flg = 'Y' ) OR ( ln_kake_par < 0 ) ) THEN
--
      ln_kake_par := gn_kotei_70; -- 固定値[70.00]
--
    END IF;
-- 2009/04/16 v1.6 T.Yoshimoto Mod Star 本番#1410
    gt_xml_data_table(gl_xml_idx).tag_value := ln_kake_par;
--
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
    -- ４月 数量データ
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'apr_quant';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
-- 2009/05/29 v1.7 T.Yoshimoto Mod Start 本番#1509
--    gt_xml_data_table(gl_xml_idx).tag_value := in_apr_quant;
    gt_xml_data_table(gl_xml_idx).tag_value := in_apr_quant_t;
-- 2009/05/29 v1.7 T.Yoshimoto Mod End 本番#1509
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
--
    -- ４月 金額データ
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'apr_amount';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    gt_xml_data_table(gl_xml_idx).tag_value := ROUND((in_apr_amount / 1000),0);
--
    -- ４月 粗利率データ
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'apr_arari_par';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    --------------------------------
    -- ０除算回避判定             --
    --------------------------------
    IF (in_apr_amount <> 0) THEN
      -- 値が[0]出なければ計算
      gt_xml_data_table(gl_xml_idx).tag_value := 
-- 2009/04/16 v1.6 T.Yoshimoto Mod Start 本番#1410
--            ROUND(((in_apr_amount - in_apr_to_amount * in_apr_quant) / in_apr_amount) * 100,2);
        ROUND(((in_apr_amount - in_apr_s_cost) / in_apr_amount) * 100,2);
-- 2009/04/16 v1.6 T.Yoshimoto Mod End 本番#1410
    ELSE
      -- 値が[0]の場合は、一律[0]設定
      gt_xml_data_table(gl_xml_idx).tag_value := gn_0;
    END IF;
--
    -- ４月 掛率データ
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'apr_kake_par';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    --------------------------------------
    -- ０除算判定項目へ判定値を挿入     --
    --------------------------------------
-- 2009/04/16 v1.6 T.Yoshimoto Mod Start 本番#1410
--    ln_chk_0 := in_apr_price * in_apr_quant;
    ln_chk_0 := in_apr_calc;
    -- ０除算回避判定
    IF (ln_chk_0 <> gn_0) THEN
      -- 値が[0]出なければ計算
      ln_kake_par := ROUND((in_apr_amount * 100) / ln_chk_0,2);
    ELSE
      -- 値が[0]の場合は、一律[0]設定
      ln_kake_par := gn_0;
    END IF;
--
-- 2009/04/16 v1.6 T.Yoshimoto Mod Star 本番#1410
/*
    -- 品目定価 = ０か、計算結果がマイナスの場合、固定値[70.00]を登録
    IF ((in_apr_amount = 0)
      AND (in_apr_price = 0)) THEN
      ln_kake_par := gn_0;
    ELSIF ((in_apr_price = 0)
      OR (ln_kake_par < 0)) THEN
      ln_kake_par := gn_kotei_70; -- 固定値[70.00]
    END IF;
*/
    -- 品目定価 = ０が存在している、または数量にマイナス値が存在している
    -- または計算結果がマイナスの場合、固定値[70.00]を登録
    IF (( in_apr_minus_flg = 'Y' ) OR ( in_apr_ht_zero_flg = 'Y' ) OR ( ln_kake_par < 0 ) ) THEN
--
      ln_kake_par := gn_kotei_70; -- 固定値[70.00]
--
    END IF;
-- 2009/04/16 v1.6 T.Yoshimoto Mod Star 本番#1410
    gt_xml_data_table(gl_xml_idx).tag_value := ln_kake_par;
--
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
    -- 年計 数量データ
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'year_quant';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    gt_xml_data_table(gl_xml_idx).tag_value := in_year_quant;
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
--
    -- 年計 金額データ
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'year_amount';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    gt_xml_data_table(gl_xml_idx).tag_value := ROUND((in_year_amount / 1000),0);
--
    -- 年計 粗利率データ
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'year_arari_par';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    --------------------------------
    -- ０除算回避判定             --
    --------------------------------
    IF (in_year_amount <> 0) THEN
      -- 値が[0]出なければ計算
      gt_xml_data_table(gl_xml_idx).tag_value := 
-- 2009/04/16 v1.6 T.Yoshimoto Mod Start 本番#1410
--          ROUND(((in_year_amount - in_year_to_amount * in_year_quant) / in_year_amount) * 100,2);
        ROUND(((in_year_amount - in_year_s_cost) / in_year_amount) * 100,2);
-- 2009/04/16 v1.6 T.Yoshimoto Mod End 本番#1410
    ELSE
      -- 値が[0]の場合は、一律[0]設定
      gt_xml_data_table(gl_xml_idx).tag_value := gn_0;
    END IF;
--
    -- 年計 掛率データ
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'year_kake_par';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    --------------------------------------
    -- ０除算判定項目へ判定値を挿入     --
    --------------------------------------
-- 2009/04/16 v1.6 T.Yoshimoto Mod Start 本番#1410
--    ln_chk_0 := in_year_price * in_year_quant;
    ln_chk_0 := in_year_calc;
-- 2009/04/16 v1.6 T.Yoshimoto Mod End 本番#1410
    -- ０除算回避判定
    IF (ln_chk_0 <> gn_0) THEN
      -- 値が[0]出なければ計算
      ln_kake_par := ROUND((in_year_amount * 100) / ln_chk_0,2);
    ELSE
      -- 値が[0]の場合は、一律[0]設定
      ln_kake_par := gn_0;
    END IF;
--
-- 2009/04/16 v1.6 T.Yoshimoto Mod Star 本番#1410
/*
    -- 品目定価 = ０か、計算結果がマイナスの場合、固定値[70.00]を登録
    IF ((in_year_price = 0)
      OR (ln_kake_par < 0)) THEN
      ln_kake_par := gn_kotei_70; -- 固定値[70.00]
    END IF;
*/
    -- 品目定価 = ０が存在している、または数量にマイナス値が存在している
    -- または計算結果がマイナスの場合、固定値[70.00]を登録
    IF (( in_year_minus_flg = 'Y' ) OR ( in_year_ht_zero_flg = 'Y' ) OR ( ln_kake_par < 0 ) ) THEN
--
      ln_kake_par := gn_kotei_70; -- 固定値[70.00]
--
    END IF;
-- 2009/04/16 v1.6 T.Yoshimoto Mod Star 本番#1410
    gt_xml_data_table(gl_xml_idx).tag_value := ln_kake_par;
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
  END prc_create_xml_data_s_k_t;
--
  /**********************************************************************************
   * Procedure Name   : prc_create_xml_data
   * Description      : XMLデータ作成 - 帳票データ出力
   ***********************************************************************************/
  PROCEDURE prc_create_xml_data
    (
      ov_errbuf     OUT     VARCHAR2   -- エラー・メッセージ           --# 固定 #
     ,ov_retcode    OUT     VARCHAR2   -- リターン・コード             --# 固定 #
     ,ov_errmsg     OUT     VARCHAR2   -- ユーザー・エラー・メッセージ --# 固定 #
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
    lv_break_init        VARCHAR2(5)           := '*****';
--
    lv_name_leaf         CONSTANT VARCHAR2(10) := 'リーフ';
    lv_name_drink        CONSTANT VARCHAR2(10) := 'ドリンク';
--
    -- 月判定用定数
    lv_jan_name          CONSTANT VARCHAR2(3)  := 'JAN';   -- １月
    lv_feb_name          CONSTANT VARCHAR2(3)  := 'FEB';   -- ２月
    lv_mar_name          CONSTANT VARCHAR2(3)  := 'MAR';   -- ３月
    lv_apr_name          CONSTANT VARCHAR2(3)  := 'APR';   -- ４月
    lv_may_name          CONSTANT VARCHAR2(3)  := 'MAY';   -- ５月
    lv_jun_name          CONSTANT VARCHAR2(3)  := 'JUN';   -- ６月
    lv_jul_name          CONSTANT VARCHAR2(3)  := 'JUL';   -- ７月
    lv_aug_name          CONSTANT VARCHAR2(3)  := 'AUG';   -- ８月
    lv_sep_name          CONSTANT VARCHAR2(3)  := 'SEP';   -- ９月
    lv_oct_name          CONSTANT VARCHAR2(3)  := 'OCT';   -- １０月
    lv_nov_name          CONSTANT VARCHAR2(3)  := 'NOV';   -- １１月
    lv_dec_name          CONSTANT VARCHAR2(3)  := 'DEC';   -- １２月
--
    -- XML出力判定用定数
    lv_yes               CONSTANT VARCHAR2(1)  := 'Y';    -- XML出力済
    lv_no                CONSTANT VARCHAR2(1)  := 'N';    -- XML出力未
--
    -- ブレイクキー判断用変数
    lv_skbn_break        xxcmn_item_categories2_v.segment1%TYPE;
                                                   -- 商品区分判定用
    lv_ktn_break         VARCHAR2(10);             -- 拠点判断用
    lv_gun_break         VARCHAR2(10);             -- 群コード判断用
    lv_dtl_break         VARCHAR2(10);             -- 品目判断用
    lv_sttl_break        VARCHAR2(10);             -- 小群計判断用
    lv_lttl_break        VARCHAR2(10);             -- 大群計判断用
--
    ln_chk_0             NUMBER;                   -- ０除算判定項目
    ln_arari             NUMBER;                   -- 粗利計算用
    ln_kake_par          NUMBER(8,2);              -- 掛率判定項目
--
    -- 各項目集計変数
    ln_quant             NUMBER := 0;              -- 年計用 数量
    ln_price             NUMBER := 0;              -- 年計用 品目定価
    ln_year_quant_sum    NUMBER := 0;              -- 年計 数量
    ln_year_amount_sum   NUMBER := 0;              -- 年計 金額
    ln_year_to_am_sum    NUMBER := 0;              -- 年計 内訳合計
    ln_year_price_sum    NUMBER := 0;              -- 年計 品目定価
--
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
    lv_param_name        VARCHAR2(100);            -- タグ出力処理用タグ名
    lv_param_label       VARCHAR2(100);            -- タグ出力処理用ラベル
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
--
    -- *** ローカル・例外処理 ***
    no_data_expt         EXCEPTION;                -- 取得レコード０件時
--
  BEGIN
--
    -- =====================================================
    -- ブレイクキー初期化
    -- =====================================================
    lv_skbn_break  := lv_break_init;   -- 商品区分判定用BK
    lv_ktn_break   := lv_break_init;   -- 拠点判定用BK
    lv_gun_break   := lv_break_init;   -- 群コード判定用BK
    lv_dtl_break   := lv_break_init;   -- 品目コード判定用BK
    lv_sttl_break  := lv_break_init;   -- 小群計判定用BK
    lv_lttl_break  := lv_break_init;   -- 大群計判定用BK
--
--  ==========================================================
--  -- 入力Ｐ『出力種別』が「全拠点」の場合                 --
--  ==========================================================
    IF (gr_param.output_type = gv_name_all_ktn) THEN
      -- =====================================================
      -- (全拠点)データ抽出 - 販売計画時系列表情報抽出 (C-1-1)
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
      -- 取得データが０件の場合
      ELSIF (gr_sale_plan.COUNT = 0) THEN
        RAISE no_data_expt;
      END IF;
--
      -- =====================================================
      -- (全拠点)項目データ抽出・タグ出力処理
      -- =====================================================
      -- -----------------------------------------------------
      -- (全拠点)データ開始タグ出力
      -- -----------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'data_info';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
      -- -----------------------------------------------------
      -- (全拠点)商品区分開始ＬＧタグ出力
      -- -----------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_skbn_info';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
      -- =====================================================
      -- (全拠点)項目データ抽出・出力処理
      -- =====================================================
      <<main_data_loop>>
      FOR i IN 1..gr_sale_plan.COUNT LOOP
        -- ====================================================
        --  (全拠点)商品区分ブレイク
        -- ====================================================
        -- 商品区分が切り替わったとき
        IF (gr_sale_plan(i).skbn <> lv_skbn_break) THEN
          -- ====================================================
          -- (全拠点) 商品区分終了Ｇタグ出力判定
          -- ====================================================
          -- 最初のレコードの時は出力せず
          IF (lv_skbn_break <> lv_break_init) THEN
            ---------------------------------------------------------------
            -- (全拠点)各月抽出データが存在しない場合、0表示にてXML出力  --
            ---------------------------------------------------------------
            <<xml_out_0_loop>>
            FOR m IN 1..12 LOOP
              IF (gr_xml_out(m).out_fg = lv_no) THEN
                prc_create_xml_data_dtl_n
                  (
                    iv_label_name     => gr_xml_out(m).tag_name                      -- 出力タグ名
                   ,ov_errbuf         => lv_errbuf   -- エラー・メッセージ           --# 固定 #
                   ,ov_retcode        => lv_retcode  -- リターン・コード             --# 固定 #
                   ,ov_errmsg         => lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
                  );
                IF (lv_retcode = gv_status_error) THEN
                  RAISE global_process_expt;
                END IF;
              END IF;
            END LOOP xml_out_0_loop;
--
            -- -----------------------------------------------------
            -- (全拠点)年計 数量データ
            -- -----------------------------------------------------
            gl_xml_idx := gt_xml_data_table.COUNT + 1;
            gt_xml_data_table(gl_xml_idx).tag_name  := 'year_quant';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
            gt_xml_data_table(gl_xml_idx).tag_value := ln_year_quant_sum;
--
            -- -----------------------------------------------------
            -- (全拠点)年計 金額データ
            -- -----------------------------------------------------
            gl_xml_idx := gt_xml_data_table.COUNT + 1;
            gt_xml_data_table(gl_xml_idx).tag_name  := 'year_amount';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
            gt_xml_data_table(gl_xml_idx).tag_value := ROUND(ln_year_amount_sum / 1000,0);
--
            -- -----------------------------------------------------
            -- (全拠点)年計 粗利率データ
            -- -----------------------------------------------------
            gl_xml_idx := gt_xml_data_table.COUNT + 1;
            gt_xml_data_table(gl_xml_idx).tag_name  := 'year_arari_par';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
--
            ----------------------------------------------
            -- (全拠点)粗利計算 (金額－内訳合計＊数量)  --
            ----------------------------------------------
            ln_arari := ln_year_amount_sum - ln_year_to_am_sum * ln_year_quant_sum;
            -- ０除算回避判定
            IF (ln_year_amount_sum <> gn_0) THEN
            -- 値が[0]出なければ計算
            gt_xml_data_table(gl_xml_idx).tag_value := 
                      ROUND((ln_arari / ln_year_amount_sum * 100),2);
            ELSE
              -- 値が[0]の場合は、一律[0]設定
              gt_xml_data_table(gl_xml_idx).tag_value := gn_0;
            END IF;
--
            -- -----------------------------------------------------
            -- (全拠点)年計 掛率データ
            -- -----------------------------------------------------
            gl_xml_idx := gt_xml_data_table.COUNT + 1;
            gt_xml_data_table(gl_xml_idx).tag_name  := 'year_kake_par';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
--
            --------------------------------------
            -- ０除算判定項目へ判定値を挿入     --
            --------------------------------------
            ln_chk_0 := ln_year_price_sum * ln_year_quant_sum;
            -- ０除算回避判定
            IF (ln_chk_0 <> gn_0) THEN
            -- 値が[0]出なければ計算
            ln_kake_par := ROUND((ln_year_amount_sum * 100) / ln_chk_0,2);
            ELSE
              -- 値が[0]の場合は、一律[0]設定
              ln_kake_par := gn_0;
            END IF;
--
            -- 品目定価 = ０か、計算結果がマイナスの場合、固定値[70.00]を登録
            IF ((ln_year_price_sum = 0)
              OR (ln_kake_par < 0)) THEN
              ln_kake_par := gn_kotei_70; -- 固定値[70.00]
            END IF;
            gt_xml_data_table(gl_xml_idx).tag_value := ln_kake_par;
--
            -- 各集計項目へデータ挿入
            <<add_total_loop>>
            FOR r IN 1..5 LOOP                     -- 小群計/大群計/拠点計/商品区分計/総合計
              gr_add_total(r).year_quant     :=
                 gr_add_total(r).year_quant     + ln_year_quant_sum;        -- 数量
              gr_add_total(r).year_amount    :=
                 gr_add_total(r).year_amount    + ln_year_amount_sum;       -- 金額
              gr_add_total(r).year_price     :=
                 gr_add_total(r).year_price     + ln_year_price_sum;        -- 品目定価
              gr_add_total(r).year_to_amount :=
                 gr_add_total(r).year_to_amount + ln_year_to_am_sum;        -- 内訳合計
              gr_add_total(r).year_quant_t   :=
                 gr_add_total(r).year_quant_t   + ln_year_quant_sum;        -- 数量(計)
            END LOOP add_total_loop;
--
            -- -----------------------------------------------------
            --  (全拠点)品目終了Ｇタグ出力
            -- -----------------------------------------------------
            gl_xml_idx := gt_xml_data_table.COUNT + 1;
            gt_xml_data_table(gl_xml_idx).tag_name  := '/g_dtl';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
            -- -----------------------------------------------------
            --  (全拠点)品目終了ＬＧタグ出力
            -- -----------------------------------------------------
            gl_xml_idx := gt_xml_data_table.COUNT + 1;
            gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_dtl_info';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
-- 2009/04/16 v1.6 T.Yoshimoto Mod Start
/*
            --------------------------------------------------------
            -- 小群計データ出力 
            --------------------------------------------------------
            prc_create_xml_data_st_lt
            (
               iv_label_name     => gv_name_st                     -- 小群計用タグ名
              ,iv_name           => gv_label_st                    -- 小群計タイトル
              ,in_may_quant      => gr_add_total(1).may_quant      -- ５月 数量
              ,in_may_amount     => gr_add_total(1).may_amount     -- ５月 金額
              ,in_may_price      => gr_add_total(1).may_price      -- ５月 品目定価
              ,in_may_to_amount  => gr_add_total(1).may_to_amount  -- ５月 内訳合計
              ,in_may_quant_t    => gr_add_total(1).may_quant_t    -- ５月 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
              ,in_may_s_cost     => gr_add_total(1).may_s_cost     -- ５月 標準原価(計算用)
              ,in_may_calc       => gr_add_total(1).may_calc       -- ５月 品目定価*数量(計算用)
              ,in_may_minus_flg   => gr_add_total(1).may_minus_flg   -- ５月 数量マイナス値存在フラグ(計算用)
              ,in_may_ht_zero_flg => gr_add_total(1).may_ht_zero_flg -- ５月 品目定価0値存在フラグ(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
              ,in_jun_quant      => gr_add_total(1).jun_quant      -- ６月 数量
              ,in_jun_amount     => gr_add_total(1).jun_amount     -- ６月 金額
              ,in_jun_price      => gr_add_total(1).jun_price      -- ６月 品目定価
              ,in_jun_to_amount  => gr_add_total(1).jun_to_amount  -- ６月 内訳合計
              ,in_jun_quant_t    => gr_add_total(1).jun_quant_t    -- ６月 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
              ,in_jun_s_cost     => gr_add_total(1).jun_s_cost     -- ６月 標準原価(計算用)
              ,in_jun_calc       => gr_add_total(1).jun_calc       -- ６月 品目定価*数量(計算用)
              ,in_jun_minus_flg   => gr_add_total(1).jun_minus_flg   -- ６月 数量マイナス値存在フラグ(計算用)
              ,in_jun_ht_zero_flg => gr_add_total(1).jun_ht_zero_flg -- ６月 品目定価0値存在フラグ(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
              ,in_jul_quant      => gr_add_total(1).jul_quant      -- ７月 数量
              ,in_jul_amount     => gr_add_total(1).jul_amount     -- ７月 金額
              ,in_jul_price      => gr_add_total(1).jul_price      -- ７月 品目定価
              ,in_jul_to_amount  => gr_add_total(1).jul_to_amount  -- ７月 内訳合計
              ,in_jul_quant_t    => gr_add_total(1).jul_quant_t    -- ７月 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
              ,in_jul_s_cost     => gr_add_total(1).jul_s_cost     -- ７月 標準原価(計算用)
              ,in_jul_calc       => gr_add_total(1).jul_calc       -- ７月 品目定価*数量(計算用)
              ,in_jul_minus_flg   => gr_add_total(1).jul_minus_flg   -- ７月 数量マイナス値存在フラグ(計算用)
              ,in_jul_ht_zero_flg => gr_add_total(1).jul_ht_zero_flg -- ７月 品目定価0値存在フラグ(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
              ,in_aug_quant      => gr_add_total(1).aug_quant      -- ８月 数量
              ,in_aug_amount     => gr_add_total(1).aug_amount     -- ８月 金額
              ,in_aug_price      => gr_add_total(1).aug_price      -- ８月 品目定価
              ,in_aug_to_amount  => gr_add_total(1).aug_to_amount  -- ８月 内訳合計
              ,in_aug_quant_t    => gr_add_total(1).aug_quant_t    -- ８月 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
              ,in_aug_s_cost     => gr_add_total(1).aug_s_cost     -- ８月 標準原価(計算用)
              ,in_aug_calc       => gr_add_total(1).aug_calc       -- ８月 品目定価*数量(計算用)
              ,in_aug_minus_flg   => gr_add_total(1).aug_minus_flg   -- ８月 数量マイナス値存在フラグ(計算用)
              ,in_aug_ht_zero_flg => gr_add_total(1).aug_ht_zero_flg -- ８月 品目定価0値存在フラグ(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
              ,in_sep_quant      => gr_add_total(1).sep_quant      -- ９月 数量
              ,in_sep_amount     => gr_add_total(1).sep_amount     -- ９月 金額
              ,in_sep_price      => gr_add_total(1).sep_price      -- ９月 品目定価
              ,in_sep_to_amount  => gr_add_total(1).sep_to_amount  -- ９月 内訳合計
              ,in_sep_quant_t    => gr_add_total(1).sep_quant_t    -- ９月 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
              ,in_sep_s_cost     => gr_add_total(1).sep_s_cost     -- ９月 標準原価(計算用)
              ,in_sep_calc       => gr_add_total(1).sep_calc       -- ９月 品目定価*数量(計算用)
              ,in_sep_minus_flg   => gr_add_total(1).sep_minus_flg   -- ９月 数量マイナス値存在フラグ(計算用)
              ,in_sep_ht_zero_flg => gr_add_total(1).sep_ht_zero_flg -- ９月 品目定価0値存在フラグ(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
              ,in_oct_quant      => gr_add_total(1).oct_quant      -- １０月 数量
              ,in_oct_amount     => gr_add_total(1).oct_amount     -- １０月 金額
              ,in_oct_price      => gr_add_total(1).oct_price      -- １０月 品目定価
              ,in_oct_to_amount  => gr_add_total(1).oct_to_amount  -- １０月 内訳合計
              ,in_oct_quant_t    => gr_add_total(1).oct_quant_t    -- １０月 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
              ,in_oct_s_cost     => gr_add_total(1).oct_s_cost     -- １０月 標準原価(計算用)
              ,in_oct_calc       => gr_add_total(1).oct_calc       -- １０月 品目定価*数量(計算用)
              ,in_oct_minus_flg   => gr_add_total(1).oct_minus_flg   -- １０月 数量マイナス値存在フラグ(計算用)
              ,in_oct_ht_zero_flg => gr_add_total(1).oct_ht_zero_flg -- １０月 品目定価0値存在フラグ(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
              ,in_nov_quant      => gr_add_total(1).nov_quant      -- １１月 数量
              ,in_nov_amount     => gr_add_total(1).nov_amount     -- １１月 金額
              ,in_nov_price      => gr_add_total(1).nov_price      -- １１月 品目定価
              ,in_nov_to_amount  => gr_add_total(1).nov_to_amount  -- １１月 内訳合計
              ,in_nov_quant_t    => gr_add_total(1).nov_quant_t    -- １１月 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
              ,in_nov_s_cost     => gr_add_total(1).nov_s_cost     -- １１月 標準原価(計算用)
              ,in_nov_calc       => gr_add_total(1).nov_calc       -- １１月 品目定価*数量(計算用)
              ,in_nov_minus_flg   => gr_add_total(1).nov_minus_flg   -- １１月 数量マイナス値存在フラグ(計算用)
              ,in_nov_ht_zero_flg => gr_add_total(1).nov_ht_zero_flg -- １１月 品目定価0値存在フラグ(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
              ,in_dec_quant      => gr_add_total(1).dec_quant      -- １２月 数量
              ,in_dec_amount     => gr_add_total(1).dec_amount     -- １２月 金額
              ,in_dec_price      => gr_add_total(1).dec_price      -- １２月 品目定価
              ,in_dec_to_amount  => gr_add_total(1).dec_to_amount  -- １２月 内訳合計
              ,in_dec_quant_t    => gr_add_total(1).dec_quant_t    -- １２月 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
              ,in_dec_s_cost     => gr_add_total(1).dec_s_cost     -- １２月 標準原価(計算用)
              ,in_dec_calc       => gr_add_total(1).dec_calc       -- １２月 品目定価*数量(計算用)
              ,in_dec_minus_flg   => gr_add_total(1).dec_minus_flg   -- １２月 数量マイナス値存在フラグ(計算用)
              ,in_dec_ht_zero_flg => gr_add_total(1).dec_ht_zero_flg -- １２月 品目定価0値存在フラグ(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
              ,in_jan_quant      => gr_add_total(1).jan_quant      -- １月 数量
              ,in_jan_amount     => gr_add_total(1).jan_amount     -- １月 金額
              ,in_jan_price      => gr_add_total(1).jan_price      -- １月 品目定価
              ,in_jan_to_amount  => gr_add_total(1).jan_to_amount  -- １月 内訳合計
              ,in_jan_quant_t    => gr_add_total(1).jan_quant_t    -- １月 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
              ,in_jan_s_cost     => gr_add_total(1).jan_s_cost     -- １月 標準原価(計算用)
              ,in_jan_calc       => gr_add_total(1).jan_calc       -- １月 品目定価*数量(計算用)
              ,in_jan_minus_flg   => gr_add_total(1).jan_minus_flg   -- １月 数量マイナス値存在フラグ(計算用)
              ,in_jan_ht_zero_flg => gr_add_total(1).jan_ht_zero_flg -- １月 品目定価0値存在フラグ(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
              ,in_feb_quant      => gr_add_total(1).feb_quant      -- ２月 数量
              ,in_feb_amount     => gr_add_total(1).feb_amount     -- ２月 金額
              ,in_feb_price      => gr_add_total(1).feb_price      -- ２月 品目定価
              ,in_feb_to_amount  => gr_add_total(1).feb_to_amount  -- ２月 内訳合計
              ,in_feb_quant_t    => gr_add_total(1).feb_quant_t    -- ２月 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
              ,in_feb_s_cost     => gr_add_total(1).feb_s_cost     -- ２月 標準原価(計算用)
              ,in_feb_calc       => gr_add_total(1).feb_calc       -- ２月 品目定価*数量(計算用)
              ,in_feb_minus_flg   => gr_add_total(1).feb_minus_flg   -- ２月 数量マイナス値存在フラグ(計算用)
              ,in_feb_ht_zero_flg => gr_add_total(1).feb_ht_zero_flg -- ２月 品目定価0値存在フラグ(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
              ,in_mar_quant      => gr_add_total(1).mar_quant      -- ３月 数量
              ,in_mar_amount     => gr_add_total(1).mar_amount     -- ３月 金額
              ,in_mar_price      => gr_add_total(1).mar_price      -- ３月 品目定価
              ,in_mar_to_amount  => gr_add_total(1).mar_to_amount  -- ３月 内訳合計
              ,in_mar_quant_t    => gr_add_total(1).mar_quant_t    -- ３月 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
              ,in_mar_s_cost     => gr_add_total(1).mar_s_cost     -- ３月 標準原価(計算用)
              ,in_mar_calc       => gr_add_total(1).mar_calc       -- ３月 品目定価*数量(計算用)
              ,in_mar_minus_flg   => gr_add_total(1).mar_minus_flg   -- ３月 数量マイナス値存在フラグ(計算用)
              ,in_mar_ht_zero_flg => gr_add_total(1).mar_ht_zero_flg -- ３月 品目定価0値存在フラグ(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
              ,in_apr_quant      => gr_add_total(1).apr_quant      -- ４月 数量
              ,in_apr_amount     => gr_add_total(1).apr_amount     -- ４月 金額
              ,in_apr_price      => gr_add_total(1).apr_price      -- ４月 品目定価
              ,in_apr_to_amount  => gr_add_total(1).apr_to_amount  -- ４月 内訳合計
              ,in_apr_quant_t    => gr_add_total(1).apr_quant_t    -- ４月 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
              ,in_apr_s_cost     => gr_add_total(1).apr_s_cost     -- ４月 標準原価(計算用)
              ,in_apr_calc       => gr_add_total(1).apr_calc       -- ４月 品目定価*数量(計算用)
              ,in_apr_minus_flg   => gr_add_total(1).apr_minus_flg   -- ４月 数量マイナス値存在フラグ(計算用)
              ,in_apr_ht_zero_flg => gr_add_total(1).apr_ht_zero_flg -- ４月 品目定価0値存在フラグ(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
              ,in_year_quant     => gr_add_total(1).year_quant     -- 年計 数量
              ,in_year_amount    => gr_add_total(1).year_amount    -- 年計 金額
              ,in_year_price     => gr_add_total(1).year_price     -- 年計 品目定価
              ,in_year_to_amount => gr_add_total(1).year_to_amount -- 年計 内訳合計
              ,in_year_quant_t   => gr_add_total(1).year_quant_t   -- 年計 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
              ,in_year_s_cost    => gr_add_total(1).year_s_cost    -- 年計 標準原価(計算用)
              ,in_year_calc      => gr_add_total(1).year_calc      -- 年計 品目定価*数量(計算用)
              ,in_year_minus_flg   => gr_add_total(1).year_minus_flg   -- 年計 数量マイナス値存在フラグ(計算用)
              ,in_year_ht_zero_flg => gr_add_total(1).year_ht_zero_flg -- 年計 品目定価0値存在フラグ(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
              ,ov_errbuf         => lv_errbuf   -- エラー・メッセージ           --# 固定 #
              ,ov_retcode        => lv_retcode  -- リターン・コード             --# 固定 #
              ,ov_errmsg         => lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
            );
            IF (lv_retcode = gv_status_error) THEN
              RAISE global_process_expt;
            END IF;
--
            --------------------------------------------------------
            -- 大群計データ出力 
            --------------------------------------------------------
            prc_create_xml_data_st_lt
            (
               iv_label_name     => gv_name_lt                     -- 大群計用タグ名
              ,iv_name           => gv_label_lt                    -- 大群計タイトル
              ,in_may_quant      => gr_add_total(2).may_quant      -- ５月 数量
              ,in_may_amount     => gr_add_total(2).may_amount     -- ５月 金額
              ,in_may_price      => gr_add_total(2).may_price      -- ５月 品目定価
              ,in_may_to_amount  => gr_add_total(2).may_to_amount  -- ５月 内訳合計
              ,in_may_quant_t    => gr_add_total(2).may_quant_t    -- ５月 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
              ,in_may_s_cost     => gr_add_total(2).may_s_cost     -- ５月 標準原価(計算用)
              ,in_may_calc       => gr_add_total(2).may_calc       -- ５月 品目定価*数量(計算用)
              ,in_may_minus_flg   => gr_add_total(2).may_minus_flg   -- ５月 数量マイナス値存在フラグ(計算用)
              ,in_may_ht_zero_flg => gr_add_total(2).may_ht_zero_flg -- ５月 品目定価*数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
              ,in_jun_quant      => gr_add_total(2).jun_quant      -- ６月 数量
              ,in_jun_amount     => gr_add_total(2).jun_amount     -- ６月 金額
              ,in_jun_price      => gr_add_total(2).jun_price      -- ６月 品目定価
              ,in_jun_to_amount  => gr_add_total(2).jun_to_amount  -- ６月 内訳合計
              ,in_jun_quant_t    => gr_add_total(2).jun_quant_t    -- ６月 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
              ,in_jun_s_cost     => gr_add_total(2).jun_s_cost     -- ６月 標準原価(計算用)
              ,in_jun_calc       => gr_add_total(2).jun_calc       -- ６月 数量マイナス値存在フラグ(計算用)
              ,in_jun_minus_flg   => gr_add_total(2).jun_minus_flg   -- ６月 品目定価*数量(計)
              ,in_jun_ht_zero_flg => gr_add_total(2).jun_ht_zero_flg -- ６月 品目定価*数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
              ,in_jul_quant      => gr_add_total(2).jul_quant      -- ７月 数量
              ,in_jul_amount     => gr_add_total(2).jul_amount     -- ７月 金額
              ,in_jul_price      => gr_add_total(2).jul_price      -- ７月 品目定価
              ,in_jul_to_amount  => gr_add_total(2).jul_to_amount  -- ７月 内訳合計
              ,in_jul_quant_t    => gr_add_total(2).jul_quant_t    -- ７月 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
              ,in_jul_s_cost     => gr_add_total(2).jul_s_cost     -- ７月 標準原価(計算用)
              ,in_jul_calc       => gr_add_total(2).jul_calc       -- ７月 品目定価*数量(計算用)
              ,in_jul_minus_flg   => gr_add_total(2).jul_minus_flg   -- ７月 数量マイナス値存在フラグ(計算用)
              ,in_jul_ht_zero_flg => gr_add_total(2).jul_ht_zero_flg -- ７月 品目定価*数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
              ,in_aug_quant      => gr_add_total(2).aug_quant      -- ８月 数量
              ,in_aug_amount     => gr_add_total(2).aug_amount     -- ８月 金額
              ,in_aug_price      => gr_add_total(2).aug_price      -- ８月 品目定価
              ,in_aug_to_amount  => gr_add_total(2).aug_to_amount  -- ８月 内訳合計
              ,in_aug_quant_t    => gr_add_total(2).aug_quant_t    -- ８月 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
              ,in_aug_s_cost     => gr_add_total(2).aug_s_cost     -- ８月 標準原価(計算用)
              ,in_aug_calc       => gr_add_total(2).aug_calc       -- ８月 品目定価*数量(計算用)
              ,in_aug_minus_flg   => gr_add_total(2).aug_minus_flg   -- ８月 数量マイナス値存在フラグ(計算用)
              ,in_aug_ht_zero_flg => gr_add_total(2).aug_ht_zero_flg -- ８月 品目定価*数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
              ,in_sep_quant      => gr_add_total(2).sep_quant      -- ９月 数量
              ,in_sep_amount     => gr_add_total(2).sep_amount     -- ９月 金額
              ,in_sep_price      => gr_add_total(2).sep_price      -- ９月 品目定価
              ,in_sep_to_amount  => gr_add_total(2).sep_to_amount  -- ９月 内訳合計
              ,in_sep_quant_t    => gr_add_total(2).sep_quant_t    -- ９月 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
              ,in_sep_s_cost     => gr_add_total(2).sep_s_cost     -- ９月 標準原価(計算用)
              ,in_sep_calc       => gr_add_total(2).sep_calc       -- ９月 品目定価*数量(計算用)
              ,in_sep_minus_flg   => gr_add_total(2).sep_minus_flg   -- ９月 数量マイナス値存在フラグ(計算用)
              ,in_sep_ht_zero_flg => gr_add_total(2).sep_ht_zero_flg -- ９月 品目定価*数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
              ,in_oct_quant      => gr_add_total(2).oct_quant      -- １０月 数量
              ,in_oct_amount     => gr_add_total(2).oct_amount     -- １０月 金額
              ,in_oct_price      => gr_add_total(2).oct_price      -- １０月 品目定価
              ,in_oct_to_amount  => gr_add_total(2).oct_to_amount  -- １０月 内訳合計
              ,in_oct_quant_t    => gr_add_total(2).oct_quant_t    -- １０月 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
              ,in_oct_s_cost     => gr_add_total(2).oct_s_cost     -- １０月 標準原価(計算用)
              ,in_oct_calc       => gr_add_total(2).oct_calc       -- １０月 品目定価*数量(計算用)
              ,in_oct_minus_flg   => gr_add_total(2).oct_minus_flg   -- １０月 数量マイナス値存在フラグ(計算用)
              ,in_oct_ht_zero_flg => gr_add_total(2).oct_ht_zero_flg -- １０月 品目定価*数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
              ,in_nov_quant      => gr_add_total(2).nov_quant      -- １１月 数量
              ,in_nov_amount     => gr_add_total(2).nov_amount     -- １１月 金額
              ,in_nov_price      => gr_add_total(2).nov_price      -- １１月 品目定価
              ,in_nov_to_amount  => gr_add_total(2).nov_to_amount  -- １１月 内訳合計
              ,in_nov_quant_t    => gr_add_total(2).nov_quant_t    -- １１月 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
              ,in_nov_s_cost     => gr_add_total(2).nov_s_cost     -- １１月 標準原価(計算用)
              ,in_nov_calc       => gr_add_total(2).nov_calc       -- １１月 品目定価*数量(計算用)
              ,in_nov_minus_flg   => gr_add_total(2).nov_minus_flg   -- １１月 数量マイナス値存在フラグ(計算用)
              ,in_nov_ht_zero_flg => gr_add_total(2).nov_ht_zero_flg -- １１月 品目定価*数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
              ,in_dec_quant      => gr_add_total(2).dec_quant      -- １２月 数量
              ,in_dec_amount     => gr_add_total(2).dec_amount     -- １２月 金額
              ,in_dec_price      => gr_add_total(2).dec_price      -- １２月 品目定価
              ,in_dec_to_amount  => gr_add_total(2).dec_to_amount  -- １２月 内訳合計
              ,in_dec_quant_t    => gr_add_total(2).dec_quant_t    -- １２月 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
              ,in_dec_s_cost     => gr_add_total(2).dec_s_cost     -- １２月 標準原価(計算用)
              ,in_dec_calc       => gr_add_total(2).dec_calc       -- １２月 品目定価*数量(計算用)
              ,in_dec_minus_flg   => gr_add_total(2).dec_minus_flg   -- １２月 数量マイナス値存在フラグ(計算用)
              ,in_dec_ht_zero_flg => gr_add_total(2).dec_ht_zero_flg -- １２月 品目定価*数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
              ,in_jan_quant      => gr_add_total(2).jan_quant      -- １月 数量
              ,in_jan_amount     => gr_add_total(2).jan_amount     -- １月 金額
              ,in_jan_price      => gr_add_total(2).jan_price      -- １月 品目定価
              ,in_jan_to_amount  => gr_add_total(2).jan_to_amount  -- １月 内訳合計
              ,in_jan_quant_t    => gr_add_total(2).jan_quant_t    -- １月 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
              ,in_jan_s_cost     => gr_add_total(2).jan_s_cost     -- １月 標準原価(計算用)
              ,in_jan_calc       => gr_add_total(2).jan_calc       -- １月 品目定価*数量(計算用)
              ,in_jan_minus_flg   => gr_add_total(2).jan_minus_flg   -- １月 数量マイナス値存在フラグ(計算用)
              ,in_jan_ht_zero_flg => gr_add_total(2).jan_ht_zero_flg -- １月 品目定価*数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
              ,in_feb_quant      => gr_add_total(2).feb_quant      -- ２月 数量
              ,in_feb_amount     => gr_add_total(2).feb_amount     -- ２月 金額
              ,in_feb_price      => gr_add_total(2).feb_price      -- ２月 品目定価
              ,in_feb_to_amount  => gr_add_total(2).feb_to_amount  -- ２月 内訳合計
              ,in_feb_quant_t    => gr_add_total(2).feb_quant_t    -- ２月 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
              ,in_feb_s_cost     => gr_add_total(2).feb_s_cost     -- ２月 標準原価(計算用)
              ,in_feb_calc       => gr_add_total(2).feb_calc       -- ２月 品目定価*数量(計算用)
              ,in_feb_minus_flg   => gr_add_total(2).feb_minus_flg   -- ２月 数量マイナス値存在フラグ(計算用)
              ,in_feb_ht_zero_flg => gr_add_total(2).feb_ht_zero_flg -- ２月 品目定価*数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
              ,in_mar_quant      => gr_add_total(2).mar_quant      -- ３月 数量
              ,in_mar_amount     => gr_add_total(2).mar_amount     -- ３月 金額
              ,in_mar_price      => gr_add_total(2).mar_price      -- ３月 品目定価
              ,in_mar_to_amount  => gr_add_total(2).mar_to_amount  -- ３月 内訳合計
              ,in_mar_quant_t    => gr_add_total(2).mar_quant_t    -- ３月 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
              ,in_mar_s_cost     => gr_add_total(2).mar_s_cost     -- ３月 標準原価(計算用)
              ,in_mar_calc       => gr_add_total(2).mar_calc       -- ３月 品目定価*数量(計算用)
              ,in_mar_minus_flg   => gr_add_total(2).mar_minus_flg   -- ３月 数量マイナス値存在フラグ(計算用)
              ,in_mar_ht_zero_flg => gr_add_total(2).mar_ht_zero_flg -- ３月 品目定価*数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
              ,in_apr_quant      => gr_add_total(2).apr_quant      -- ４月 数量
              ,in_apr_amount     => gr_add_total(2).apr_amount     -- ４月 金額
              ,in_apr_price      => gr_add_total(2).apr_price      -- ４月 品目定価
              ,in_apr_to_amount  => gr_add_total(2).apr_to_amount  -- ４月 内訳合計
              ,in_apr_quant_t    => gr_add_total(2).apr_quant_t    -- ４月 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
              ,in_apr_s_cost     => gr_add_total(2).apr_s_cost     -- ４月 標準原価(計算用)
              ,in_apr_calc       => gr_add_total(2).apr_calc       -- ４月 品目定価*数量(計算用)
              ,in_apr_minus_flg   => gr_add_total(2).apr_minus_flg   -- ４月 数量マイナス値存在フラグ(計算用)
              ,in_apr_ht_zero_flg => gr_add_total(2).apr_ht_zero_flg -- ４月 品目定価*数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
              ,in_year_quant     => gr_add_total(2).year_quant     -- 年計 数量
              ,in_year_amount    => gr_add_total(2).year_amount    -- 年計 金額
              ,in_year_price     => gr_add_total(2).year_price     -- 年計 品目定価
              ,in_year_to_amount => gr_add_total(2).year_to_amount -- 年計 内訳合計
              ,in_year_quant_t   => gr_add_total(2).year_quant_t   -- 年計 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
              ,in_year_s_cost    => gr_add_total(2).year_s_cost    -- 年計 標準原価(計算用)
              ,in_year_calc      => gr_add_total(2).year_calc      -- 年計 品目定価*数量(計算用)
              ,in_year_minus_flg   => gr_add_total(2).year_minus_flg   -- 年計 数量マイナス値存在フラグ(計算用)
              ,in_year_ht_zero_flg => gr_add_total(2).year_ht_zero_flg -- 年計 品目定価*数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
              ,ov_errbuf         => lv_errbuf   -- エラー・メッセージ           --# 固定 #
              ,ov_retcode        => lv_retcode  -- リターン・コード             --# 固定 #
              ,ov_errmsg         => lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
            );
            IF (lv_retcode = gv_status_error) THEN
              RAISE global_process_expt;
            END IF;
*/
            --------------------------------------------------------
            -- (全拠点)(1)小群計/(2)大群計データ出力 
            --------------------------------------------------------
            <<gun_loop>>
            FOR n IN 1..2 LOOP        -- 小群計/大群計
--
              -- 小群計の場合
              IF ( n = 1) THEN
                lv_param_name  := gv_name_st;
                lv_param_label := gv_label_st;
              -- 大群計の場合
              ELSE
                lv_param_name  := gv_name_lt;
                lv_param_label := gv_label_lt;
              END IF;
--
              prc_create_xml_data_st_lt
              (
                 iv_label_name      => lv_param_name                   -- 大群計用タグ名
                ,iv_name            => lv_param_label                  -- 大群計タイトル
                ,in_may_quant       => gr_add_total(n).may_quant       -- ５月 数量
                ,in_may_amount      => gr_add_total(n).may_amount      -- ５月 金額
                ,in_may_price       => gr_add_total(n).may_price       -- ５月 品目定価
                ,in_may_to_amount   => gr_add_total(n).may_to_amount   -- ５月 内訳合計
                ,in_may_quant_t     => gr_add_total(n).may_quant_t     -- ５月 数量(計算用)
                ,in_may_s_cost      => gr_add_total(n).may_s_cost      -- ５月 標準原価(計算用)
                ,in_may_calc        => gr_add_total(n).may_calc        -- ５月 品目定価*数量(計算用)
                ,in_may_minus_flg   => gr_add_total(n).may_minus_flg   -- ５月 数量マイナス値存在フラグ(計算用)
                ,in_may_ht_zero_flg => gr_add_total(n).may_ht_zero_flg -- ５月 品目定価*数量(計)
                ,in_jun_quant       => gr_add_total(n).jun_quant       -- ６月 数量
                ,in_jun_amount      => gr_add_total(n).jun_amount      -- ６月 金額
                ,in_jun_price       => gr_add_total(n).jun_price       -- ６月 品目定価
                ,in_jun_to_amount   => gr_add_total(n).jun_to_amount   -- ６月 内訳合計
                ,in_jun_quant_t     => gr_add_total(n).jun_quant_t     -- ６月 数量(計算用)
                ,in_jun_s_cost      => gr_add_total(n).jun_s_cost      -- ６月 標準原価(計算用)
                ,in_jun_calc        => gr_add_total(n).jun_calc        -- ６月 品目定価*数量(計算用)
                ,in_jun_minus_flg   => gr_add_total(n).jun_minus_flg   -- ６月 数量マイナス値存在フラグ(計算用)
                ,in_jun_ht_zero_flg => gr_add_total(n).jun_ht_zero_flg -- ６月 品目定価*数量(計)
                ,in_jul_quant       => gr_add_total(n).jul_quant       -- ７月 数量
                ,in_jul_amount      => gr_add_total(n).jul_amount      -- ７月 金額
                ,in_jul_price       => gr_add_total(n).jul_price       -- ７月 品目定価
                ,in_jul_to_amount   => gr_add_total(n).jul_to_amount   -- ７月 内訳合計
                ,in_jul_quant_t     => gr_add_total(n).jul_quant_t     -- ７月 数量(計算用)
                ,in_jul_s_cost      => gr_add_total(n).jul_s_cost      -- ７月 標準原価(計算用)
                ,in_jul_calc        => gr_add_total(n).jul_calc        -- ７月 品目定価*数量(計算用)
                ,in_jul_minus_flg   => gr_add_total(n).jul_minus_flg   -- ７月 数量マイナス値存在フラグ(計算用)
                ,in_jul_ht_zero_flg => gr_add_total(n).jul_ht_zero_flg -- ７月 品目定価*数量(計)
                ,in_aug_quant       => gr_add_total(n).aug_quant       -- ８月 数量
                ,in_aug_amount      => gr_add_total(n).aug_amount      -- ８月 金額
                ,in_aug_price       => gr_add_total(n).aug_price       -- ８月 品目定価
                ,in_aug_to_amount   => gr_add_total(n).aug_to_amount   -- ８月 内訳合計
                ,in_aug_quant_t     => gr_add_total(n).aug_quant_t     -- ８月 数量(計算用)
                ,in_aug_s_cost      => gr_add_total(n).aug_s_cost      -- ８月 標準原価(計算用)
                ,in_aug_calc        => gr_add_total(n).aug_calc        -- ８月 品目定価*数量(計算用)
                ,in_aug_minus_flg   => gr_add_total(n).aug_minus_flg   -- ８月 数量マイナス値存在フラグ(計算用)
                ,in_aug_ht_zero_flg => gr_add_total(n).aug_ht_zero_flg -- ８月 品目定価*数量(計)
                ,in_sep_quant       => gr_add_total(n).sep_quant       -- ９月 数量
                ,in_sep_amount      => gr_add_total(n).sep_amount      -- ９月 金額
                ,in_sep_price       => gr_add_total(n).sep_price       -- ９月 品目定価
                ,in_sep_to_amount   => gr_add_total(n).sep_to_amount   -- ９月 内訳合計
                ,in_sep_quant_t     => gr_add_total(n).sep_quant_t     -- ９月 数量(計算用)
                ,in_sep_s_cost      => gr_add_total(n).sep_s_cost      -- ９月 標準原価(計算用)
                ,in_sep_calc        => gr_add_total(n).sep_calc        -- ９月 品目定価*数量(計算用)
                ,in_sep_minus_flg   => gr_add_total(n).sep_minus_flg   -- ９月 数量マイナス値存在フラグ(計算用)
                ,in_sep_ht_zero_flg => gr_add_total(n).sep_ht_zero_flg -- ９月 品目定価*数量(計)
                ,in_oct_quant       => gr_add_total(n).oct_quant       -- １０月 数量
                ,in_oct_amount      => gr_add_total(n).oct_amount      -- １０月 金額
                ,in_oct_price       => gr_add_total(n).oct_price       -- １０月 品目定価
                ,in_oct_to_amount   => gr_add_total(n).oct_to_amount   -- １０月 内訳合計
                ,in_oct_quant_t     => gr_add_total(n).oct_quant_t     -- １０月 数量(計算用)
                ,in_oct_s_cost      => gr_add_total(n).oct_s_cost      -- １０月 標準原価(計算用)
                ,in_oct_calc        => gr_add_total(n).oct_calc        -- １０月 品目定価*数量(計算用)
                ,in_oct_minus_flg   => gr_add_total(n).oct_minus_flg   -- １０月 数量マイナス値存在フラグ(計算用)
                ,in_oct_ht_zero_flg => gr_add_total(n).oct_ht_zero_flg -- １０月 品目定価*数量(計)
                ,in_nov_quant       => gr_add_total(n).nov_quant       -- １１月 数量
                ,in_nov_amount      => gr_add_total(n).nov_amount      -- １１月 金額
                ,in_nov_price       => gr_add_total(n).nov_price       -- １１月 品目定価
                ,in_nov_to_amount   => gr_add_total(n).nov_to_amount   -- １１月 内訳合計
                ,in_nov_quant_t     => gr_add_total(n).nov_quant_t     -- １１月 数量(計算用)
                ,in_nov_s_cost      => gr_add_total(n).nov_s_cost      -- １１月 標準原価(計算用)
                ,in_nov_calc        => gr_add_total(n).nov_calc        -- １１月 品目定価*数量(計算用)
                ,in_nov_minus_flg   => gr_add_total(n).nov_minus_flg   -- １１月 数量マイナス値存在フラグ(計算用)
                ,in_nov_ht_zero_flg => gr_add_total(n).nov_ht_zero_flg -- １１月 品目定価*数量(計)
                ,in_dec_quant       => gr_add_total(n).dec_quant       -- １２月 数量
                ,in_dec_amount      => gr_add_total(n).dec_amount      -- １２月 金額
                ,in_dec_price       => gr_add_total(n).dec_price       -- １２月 品目定価
                ,in_dec_to_amount   => gr_add_total(n).dec_to_amount   -- １２月 内訳合計
                ,in_dec_quant_t     => gr_add_total(n).dec_quant_t     -- １２月 数量(計算用)
                ,in_dec_s_cost      => gr_add_total(n).dec_s_cost      -- １２月 標準原価(計算用)
                ,in_dec_calc        => gr_add_total(n).dec_calc        -- １２月 品目定価*数量(計算用)
                ,in_dec_minus_flg   => gr_add_total(n).dec_minus_flg   -- １２月 数量マイナス値存在フラグ(計算用)
                ,in_dec_ht_zero_flg => gr_add_total(n).dec_ht_zero_flg -- １２月 品目定価*数量(計)
                ,in_jan_quant       => gr_add_total(n).jan_quant       -- １月 数量
                ,in_jan_amount      => gr_add_total(n).jan_amount      -- １月 金額
                ,in_jan_price       => gr_add_total(n).jan_price       -- １月 品目定価
                ,in_jan_to_amount   => gr_add_total(n).jan_to_amount   -- １月 内訳合計
                ,in_jan_quant_t     => gr_add_total(n).jan_quant_t     -- １月 数量(計算用)
                ,in_jan_s_cost      => gr_add_total(n).jan_s_cost      -- １月 標準原価(計算用)
                ,in_jan_calc        => gr_add_total(n).jan_calc        -- １月 品目定価*数量(計算用)
                ,in_jan_minus_flg   => gr_add_total(n).jan_minus_flg   -- １月 数量マイナス値存在フラグ(計算用)
                ,in_jan_ht_zero_flg => gr_add_total(n).jan_ht_zero_flg -- １月 品目定価*数量(計)
                ,in_feb_quant       => gr_add_total(n).feb_quant       -- ２月 数量
                ,in_feb_amount      => gr_add_total(n).feb_amount      -- ２月 金額
                ,in_feb_price       => gr_add_total(n).feb_price       -- ２月 品目定価
                ,in_feb_to_amount   => gr_add_total(n).feb_to_amount   -- ２月 内訳合計
                ,in_feb_quant_t     => gr_add_total(n).feb_quant_t     -- ２月 数量(計算用)
                ,in_feb_s_cost      => gr_add_total(n).feb_s_cost      -- ２月 標準原価(計算用)
                ,in_feb_calc        => gr_add_total(n).feb_calc        -- ２月 品目定価*数量(計算用)
                ,in_feb_minus_flg   => gr_add_total(n).feb_minus_flg   -- ２月 数量マイナス値存在フラグ(計算用)
                ,in_feb_ht_zero_flg => gr_add_total(n).feb_ht_zero_flg -- ２月 品目定価*数量(計)
                ,in_mar_quant       => gr_add_total(n).mar_quant       -- ３月 数量
                ,in_mar_amount      => gr_add_total(n).mar_amount      -- ３月 金額
                ,in_mar_price       => gr_add_total(n).mar_price       -- ３月 品目定価
                ,in_mar_to_amount   => gr_add_total(n).mar_to_amount   -- ３月 内訳合計
                ,in_mar_quant_t     => gr_add_total(n).mar_quant_t     -- ３月 数量(計算用)
                ,in_mar_s_cost      => gr_add_total(n).mar_s_cost      -- ３月 標準原価(計算用)
                ,in_mar_calc        => gr_add_total(n).mar_calc        -- ３月 品目定価*数量(計算用)
                ,in_mar_minus_flg   => gr_add_total(n).mar_minus_flg   -- ３月 数量マイナス値存在フラグ(計算用)
                ,in_mar_ht_zero_flg => gr_add_total(n).mar_ht_zero_flg -- ３月 品目定価*数量(計)
                ,in_apr_quant       => gr_add_total(n).apr_quant       -- ４月 数量
                ,in_apr_amount      => gr_add_total(n).apr_amount      -- ４月 金額
                ,in_apr_price       => gr_add_total(n).apr_price       -- ４月 品目定価
                ,in_apr_to_amount   => gr_add_total(n).apr_to_amount   -- ４月 内訳合計
                ,in_apr_quant_t     => gr_add_total(n).apr_quant_t     -- ４月 数量(計算用)
                ,in_apr_s_cost      => gr_add_total(n).apr_s_cost      -- ４月 標準原価(計算用)
                ,in_apr_calc        => gr_add_total(n).apr_calc        -- ４月 品目定価*数量(計算用)
                ,in_apr_minus_flg   => gr_add_total(n).apr_minus_flg   -- ４月 数量マイナス値存在フラグ(計算用)
                ,in_apr_ht_zero_flg => gr_add_total(n).apr_ht_zero_flg -- ４月 品目定価*数量(計)
                ,in_year_quant      => gr_add_total(n).year_quant        -- 年計 数量
                ,in_year_amount     => gr_add_total(n).year_amount       -- 年計 金額
                ,in_year_price      => gr_add_total(n).year_price        -- 年計 品目定価
                ,in_year_to_amount  => gr_add_total(n).year_to_amount    -- 年計 内訳合計
                ,in_year_quant_t    => gr_add_total(n).year_quant_t      -- 年計 数量(計算用)
                ,in_year_s_cost     => gr_add_total(n).year_s_cost       -- 年計 標準原価(計算用)
                ,in_year_calc       => gr_add_total(n).year_calc         -- 年計 品目定価*数量(計算用)
                ,in_year_minus_flg   => gr_add_total(n).year_minus_flg   -- 年計 数量マイナス値存在フラグ(計算用)
                ,in_year_ht_zero_flg => gr_add_total(n).year_ht_zero_flg -- 年計 品目定価*数量(計)
                ,ov_errbuf         => lv_errbuf   -- エラー・メッセージ           --# 固定 #
                ,ov_retcode        => lv_retcode  -- リターン・コード             --# 固定 #
                ,ov_errmsg         => lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
              );
              IF (lv_retcode = gv_status_error) THEN
                RAISE global_process_expt;
              END IF;
--
            END LOOP gun_loop;
--
-- 2009/04/16 v1.6 T.Yoshimoto Mod End
--
            -- -----------------------------------------------------
            --  (全拠点)群コード終了Ｇタグ出力
            -- -----------------------------------------------------
            gl_xml_idx := gt_xml_data_table.COUNT + 1;
            gt_xml_data_table(gl_xml_idx).tag_name  := '/g_gun';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
            -- -----------------------------------------------------
            --  (全拠点)群コード終了ＬＧタグ出力
            -- -----------------------------------------------------
            gl_xml_idx := gt_xml_data_table.COUNT + 1;
            gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_gun_info';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
-- 2009/04/16 v1.6 T.Yoshimoto Mod Start
/*
            --------------------------------------------------------
            -- 拠点計データタグ出力 
            --------------------------------------------------------
            prc_create_xml_data_s_k_t
            (
              iv_label_name     => gv_name_ktn                    -- 拠点計用タグ名
              ,in_may_quant      => gr_add_total(3).may_quant      -- ５月 数量
              ,in_may_amount     => gr_add_total(3).may_amount     -- ５月 金額
              ,in_may_price      => gr_add_total(3).may_price      -- ５月 品目定価
              ,in_may_to_amount  => gr_add_total(3).may_to_amount  -- ５月 内訳合計
              ,in_may_quant_t    => gr_add_total(3).may_quant_t    -- ５月 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
              ,in_may_s_cost     => gr_add_total(3).may_s_cost     -- ５月 標準原価(計算用)
              ,in_may_calc       => gr_add_total(3).may_calc       -- ５月 品目定価*数量(計算用)
              ,in_may_minus_flg   => gr_add_total(3).may_minus_flg   -- ５月 数量マイナス値存在フラグ(計算用)
              ,in_may_ht_zero_flg => gr_add_total(3).may_ht_zero_flg -- ５月 品目定価*数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
              ,in_jun_quant      => gr_add_total(3).jun_quant      -- ６月 数量
              ,in_jun_amount     => gr_add_total(3).jun_amount     -- ６月 金額
              ,in_jun_price      => gr_add_total(3).jun_price      -- ６月 品目定価
              ,in_jun_to_amount  => gr_add_total(3).jun_to_amount  -- ６月 内訳合計
              ,in_jun_quant_t    => gr_add_total(3).jun_quant_t    -- ６月 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
              ,in_jun_s_cost     => gr_add_total(3).jun_s_cost     -- ６月 標準原価(計算用)
              ,in_jun_calc       => gr_add_total(3).jun_calc       -- ６月 品目定価*数量(計算用)
              ,in_jun_minus_flg   => gr_add_total(3).jun_minus_flg   -- ６月 数量マイナス値存在フラグ(計算用)
              ,in_jun_ht_zero_flg => gr_add_total(3).jun_ht_zero_flg -- ６月 品目定価*数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
              ,in_jul_quant      => gr_add_total(3).jul_quant      -- ７月 数量
              ,in_jul_amount     => gr_add_total(3).jul_amount     -- ７月 金額
              ,in_jul_price      => gr_add_total(3).jul_price      -- ７月 品目定価
              ,in_jul_to_amount  => gr_add_total(3).jul_to_amount  -- ７月 内訳合計
              ,in_jul_quant_t    => gr_add_total(3).jul_quant_t    -- ７月 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
              ,in_jul_s_cost     => gr_add_total(3).jul_s_cost     -- ７月 標準原価(計算用)
              ,in_jul_calc       => gr_add_total(3).jul_calc       -- ７月 品目定価*数量(計算用)
              ,in_jul_minus_flg   => gr_add_total(3).jul_minus_flg   -- ７月 数量マイナス値存在フラグ(計算用)
              ,in_jul_ht_zero_flg => gr_add_total(3).jul_ht_zero_flg -- ７月 品目定価*数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
              ,in_aug_quant      => gr_add_total(3).aug_quant      -- ８月 数量
              ,in_aug_amount     => gr_add_total(3).aug_amount     -- ８月 金額
              ,in_aug_price      => gr_add_total(3).aug_price      -- ８月 品目定価
              ,in_aug_to_amount  => gr_add_total(3).aug_to_amount  -- ８月 内訳合計
              ,in_aug_quant_t    => gr_add_total(3).aug_quant_t    -- ８月 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
              ,in_aug_s_cost     => gr_add_total(3).aug_s_cost     -- ８月 標準原価(計算用)
              ,in_aug_calc       => gr_add_total(3).aug_calc       -- ８月 品目定価*数量(計算用)
              ,in_aug_minus_flg   => gr_add_total(3).aug_minus_flg   -- ８月 数量マイナス値存在フラグ(計算用)
              ,in_aug_ht_zero_flg => gr_add_total(3).aug_ht_zero_flg -- ８月 品目定価*数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
              ,in_sep_quant      => gr_add_total(3).sep_quant      -- ９月 数量
              ,in_sep_amount     => gr_add_total(3).sep_amount     -- ９月 金額
              ,in_sep_price      => gr_add_total(3).sep_price      -- ９月 品目定価
              ,in_sep_to_amount  => gr_add_total(3).sep_to_amount  -- ９月 内訳合計
              ,in_sep_quant_t    => gr_add_total(3).sep_quant_t    -- ９月 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
              ,in_sep_s_cost     => gr_add_total(3).sep_s_cost     -- ９月 標準原価(計算用)
              ,in_sep_calc       => gr_add_total(3).sep_calc       -- ９月 品目定価*数量(計算用)
              ,in_sep_minus_flg   => gr_add_total(3).sep_minus_flg   -- ９月 数量マイナス値存在フラグ(計算用)
              ,in_sep_ht_zero_flg => gr_add_total(3).sep_ht_zero_flg -- ９月 品目定価*数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
              ,in_oct_quant      => gr_add_total(3).oct_quant      -- １０月 数量
              ,in_oct_amount     => gr_add_total(3).oct_amount     -- １０月 金額
              ,in_oct_price      => gr_add_total(3).oct_price      -- １０月 品目定価
              ,in_oct_to_amount  => gr_add_total(3).oct_to_amount  -- １０月 内訳合計
              ,in_oct_quant_t    => gr_add_total(3).oct_quant_t    -- １０月 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
              ,in_oct_s_cost     => gr_add_total(3).oct_s_cost     -- １０月 標準原価(計算用)
              ,in_oct_calc       => gr_add_total(3).oct_calc       -- １０月 品目定価*数量(計算用)
              ,in_oct_minus_flg   => gr_add_total(3).oct_minus_flg   -- １０月 数量マイナス値存在フラグ(計算用)
              ,in_oct_ht_zero_flg => gr_add_total(3).oct_ht_zero_flg -- １０月 品目定価*数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
              ,in_nov_quant      => gr_add_total(3).nov_quant      -- １１月 数量
              ,in_nov_amount     => gr_add_total(3).nov_amount     -- １１月 金額
              ,in_nov_price      => gr_add_total(3).nov_price      -- １１月 品目定価
              ,in_nov_to_amount  => gr_add_total(3).nov_to_amount  -- １１月 内訳合計
              ,in_nov_quant_t    => gr_add_total(3).nov_quant_t    -- １１月 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
              ,in_nov_s_cost     => gr_add_total(3).nov_s_cost     -- １１月 標準原価(計算用)
              ,in_nov_calc       => gr_add_total(3).nov_calc       -- １１月 品目定価*数量(計算用)
              ,in_nov_minus_flg   => gr_add_total(3).nov_minus_flg   -- １１月 数量マイナス値存在フラグ(計算用)
              ,in_nov_ht_zero_flg => gr_add_total(3).nov_ht_zero_flg -- １１月 品目定価*数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
              ,in_dec_quant      => gr_add_total(3).dec_quant      -- １２月 数量
              ,in_dec_amount     => gr_add_total(3).dec_amount     -- １２月 金額
              ,in_dec_price      => gr_add_total(3).dec_price      -- １２月 品目定価
              ,in_dec_to_amount  => gr_add_total(3).dec_to_amount  -- １２月 内訳合計
              ,in_dec_quant_t    => gr_add_total(3).dec_quant_t    -- １２月 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
              ,in_dec_s_cost     => gr_add_total(3).dec_s_cost     -- １２月 標準原価(計算用)
              ,in_dec_calc       => gr_add_total(3).dec_calc       -- １２月 品目定価*数量(計算用)
              ,in_dec_minus_flg   => gr_add_total(3).dec_minus_flg   -- １２月 数量マイナス値存在フラグ(計算用)
              ,in_dec_ht_zero_flg => gr_add_total(3).dec_ht_zero_flg -- １２月 品目定価*数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
              ,in_jan_quant      => gr_add_total(3).jan_quant      -- １月 数量
              ,in_jan_amount     => gr_add_total(3).jan_amount     -- １月 金額
              ,in_jan_price      => gr_add_total(3).jan_price      -- １月 品目定価
              ,in_jan_to_amount  => gr_add_total(3).jan_to_amount  -- １月 内訳合計
              ,in_jan_quant_t    => gr_add_total(3).jan_quant_t    -- １月 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
              ,in_jan_s_cost     => gr_add_total(3).jan_s_cost     -- １月 標準原価(計算用)
              ,in_jan_calc       => gr_add_total(3).jan_calc       -- １月 品目定価*数量(計算用)
              ,in_jan_minus_flg   => gr_add_total(3).jan_minus_flg   -- １月 数量マイナス値存在フラグ(計算用)
              ,in_jan_ht_zero_flg => gr_add_total(3).jan_ht_zero_flg -- １月 品目定価*数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
              ,in_feb_quant      => gr_add_total(3).feb_quant      -- ２月 数量
              ,in_feb_amount     => gr_add_total(3).feb_amount     -- ２月 金額
              ,in_feb_price      => gr_add_total(3).feb_price      -- ２月 品目定価
              ,in_feb_to_amount  => gr_add_total(3).feb_to_amount  -- ２月 内訳合計
              ,in_feb_quant_t    => gr_add_total(3).feb_quant_t    -- ２月 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
              ,in_feb_s_cost     => gr_add_total(3).feb_s_cost     -- ２月 標準原価(計算用)
              ,in_feb_calc       => gr_add_total(3).feb_calc       -- ２月 品目定価*数量(計算用)
              ,in_feb_minus_flg   => gr_add_total(3).feb_minus_flg   -- ２月 数量マイナス値存在フラグ(計算用)
              ,in_feb_ht_zero_flg => gr_add_total(3).feb_ht_zero_flg -- ２月 品目定価*数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
              ,in_mar_quant      => gr_add_total(3).mar_quant      -- ３月 数量
              ,in_mar_amount     => gr_add_total(3).mar_amount     -- ３月 金額
              ,in_mar_price      => gr_add_total(3).mar_price      -- ３月 品目定価
              ,in_mar_to_amount  => gr_add_total(3).mar_to_amount  -- ３月 内訳合計
              ,in_mar_quant_t    => gr_add_total(3).mar_quant_t    -- ３月 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
              ,in_mar_s_cost     => gr_add_total(3).mar_s_cost     -- ３月 標準原価(計算用)
              ,in_mar_calc       => gr_add_total(3).mar_calc       -- ３月 品目定価*数量(計算用)
              ,in_mar_minus_flg   => gr_add_total(3).mar_minus_flg   -- ３月 数量マイナス値存在フラグ(計算用)
              ,in_mar_ht_zero_flg => gr_add_total(3).mar_ht_zero_flg -- ３月 品目定価*数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
              ,in_apr_quant      => gr_add_total(3).apr_quant      -- ４月 数量
              ,in_apr_amount     => gr_add_total(3).apr_amount     -- ４月 金額
              ,in_apr_price      => gr_add_total(3).apr_price      -- ４月 品目定価
              ,in_apr_to_amount  => gr_add_total(3).apr_to_amount  -- ４月 内訳合計
              ,in_apr_quant_t    => gr_add_total(3).apr_quant_t    -- ４月 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
              ,in_apr_s_cost     => gr_add_total(3).apr_s_cost     -- ４月 標準原価(計算用)
              ,in_apr_calc       => gr_add_total(3).apr_calc       -- ４月 品目定価*数量(計算用)
              ,in_apr_minus_flg   => gr_add_total(3).apr_minus_flg   -- ４月 数量マイナス値存在フラグ(計算用)
              ,in_apr_ht_zero_flg => gr_add_total(3).apr_ht_zero_flg -- ４月 品目定価*数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
              ,in_year_quant     => gr_add_total(3).year_quant     -- 年計 数量
              ,in_year_amount    => gr_add_total(3).year_amount    -- 年計 金額
              ,in_year_price     => gr_add_total(3).year_price     -- 年計 品目定価
              ,in_year_to_amount => gr_add_total(3).year_to_amount -- 年計 内訳合計
              ,in_year_quant_t   => gr_add_total(3).year_quant_t   -- 年計 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
              ,in_year_s_cost    => gr_add_total(3).year_s_cost    -- 年計 標準原価(計算用)
              ,in_year_calc      => gr_add_total(3).year_calc      -- 年計 品目定価*数量(計算用)
              ,in_year_minus_flg   => gr_add_total(3).year_minus_flg   -- 年計 数量マイナス値存在フラグ(計算用)
              ,in_year_ht_zero_flg => gr_add_total(3).year_ht_zero_flg -- 年計 品目定価*数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
              ,ov_errbuf         => lv_errbuf   -- エラー・メッセージ           --# 固定 #
              ,ov_retcode        => lv_retcode  -- リターン・コード             --# 固定 #
              ,ov_errmsg         => lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
            );
            IF (lv_retcode = gv_status_error) THEN
              RAISE global_process_expt;
            END IF;
--
            -- -----------------------------------------------------
            --  拠点終了Ｇタグ出力
            -- -----------------------------------------------------
            gl_xml_idx := gt_xml_data_table.COUNT + 1;
            gt_xml_data_table(gl_xml_idx).tag_name  := '/g_ktn';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
            -- -----------------------------------------------------
            --  拠点終了ＬＧタグ出力
            -- -----------------------------------------------------
            gl_xml_idx := gt_xml_data_table.COUNT + 1;
            gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_ktn_info';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
            --------------------------------------------------------
            -- 商品区分計データタグ出力 
            --------------------------------------------------------
            prc_create_xml_data_s_k_t
            (
              iv_label_name     => gv_name_skbn                   -- 商品区分計用タグ名
              ,in_may_quant      => gr_add_total(4).may_quant      -- ５月 数量
              ,in_may_amount     => gr_add_total(4).may_amount     -- ５月 金額
              ,in_may_price      => gr_add_total(4).may_price      -- ５月 品目定価
              ,in_may_to_amount  => gr_add_total(4).may_to_amount  -- ５月 内訳合計
              ,in_may_quant_t    => gr_add_total(4).may_quant_t    -- ５月 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
              ,in_may_s_cost     => gr_add_total(4).may_s_cost     -- ５月 標準原価(計算用)
              ,in_may_calc       => gr_add_total(4).may_calc       -- ５月 品目定価*数量(計算用)
              ,in_may_minus_flg   => gr_add_total(4).may_minus_flg   -- ５月 数量マイナス値存在フラグ(計算用)
              ,in_may_ht_zero_flg => gr_add_total(4).may_ht_zero_flg -- ５月 品目定価*数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
              ,in_jun_quant      => gr_add_total(4).jun_quant      -- ６月 数量
              ,in_jun_amount     => gr_add_total(4).jun_amount     -- ６月 金額
              ,in_jun_price      => gr_add_total(4).jun_price      -- ６月 品目定価
              ,in_jun_to_amount  => gr_add_total(4).jun_to_amount  -- ６月 内訳合計
              ,in_jun_quant_t    => gr_add_total(4).jun_quant_t    -- ６月 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
              ,in_jun_s_cost     => gr_add_total(4).jun_s_cost     -- ６月 標準原価(計算用)
              ,in_jun_calc       => gr_add_total(4).jun_calc       -- ６月 品目定価*数量(計算用)
              ,in_jun_minus_flg   => gr_add_total(4).jun_minus_flg   -- ６月 数量マイナス値存在フラグ(計算用)
              ,in_jun_ht_zero_flg => gr_add_total(4).jun_ht_zero_flg -- ６月 品目定価*数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
              ,in_jul_quant      => gr_add_total(4).jul_quant      -- ７月 数量
              ,in_jul_amount     => gr_add_total(4).jul_amount     -- ７月 金額
              ,in_jul_price      => gr_add_total(4).jul_price      -- ７月 品目定価
              ,in_jul_to_amount  => gr_add_total(4).jul_to_amount  -- ７月 内訳合計
              ,in_jul_quant_t    => gr_add_total(4).jul_quant_t    -- ７月 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
              ,in_jul_s_cost     => gr_add_total(4).jul_s_cost     -- ７月 標準原価(計算用)
              ,in_jul_calc       => gr_add_total(4).jul_calc       -- ７月 品目定価*数量(計算用)
              ,in_jul_minus_flg   => gr_add_total(4).jul_minus_flg   -- ７月 数量マイナス値存在フラグ(計算用)
              ,in_jul_ht_zero_flg => gr_add_total(4).jul_ht_zero_flg -- ７月 品目定価*数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
              ,in_aug_quant      => gr_add_total(4).aug_quant      -- ８月 数量
              ,in_aug_amount     => gr_add_total(4).aug_amount     -- ８月 金額
              ,in_aug_price      => gr_add_total(4).aug_price      -- ８月 品目定価
              ,in_aug_to_amount  => gr_add_total(4).aug_to_amount  -- ８月 内訳合計
              ,in_aug_quant_t    => gr_add_total(4).aug_quant_t    -- ８月 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
              ,in_aug_s_cost     => gr_add_total(4).aug_s_cost     -- ８月 標準原価(計算用)
              ,in_aug_calc       => gr_add_total(4).aug_calc       -- ８月 品目定価*数量(計算用)
              ,in_aug_minus_flg   => gr_add_total(4).aug_minus_flg   -- ８月 数量マイナス値存在フラグ(計算用)
              ,in_aug_ht_zero_flg => gr_add_total(4).aug_ht_zero_flg -- ８月 品目定価*数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
              ,in_sep_quant      => gr_add_total(4).sep_quant      -- ９月 数量
              ,in_sep_amount     => gr_add_total(4).sep_amount     -- ９月 金額
              ,in_sep_price      => gr_add_total(4).sep_price      -- ９月 品目定価
              ,in_sep_to_amount  => gr_add_total(4).sep_to_amount  -- ９月 内訳合計
              ,in_sep_quant_t    => gr_add_total(4).sep_quant_t    -- ９月 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
              ,in_sep_s_cost     => gr_add_total(4).sep_s_cost     -- ９月 標準原価(計算用)
              ,in_sep_calc       => gr_add_total(4).sep_calc       -- ９月 品目定価*数量(計算用)
              ,in_sep_minus_flg   => gr_add_total(4).sep_minus_flg   -- ９月 数量マイナス値存在フラグ(計算用)
              ,in_sep_ht_zero_flg => gr_add_total(4).sep_ht_zero_flg -- ９月 品目定価*数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
              ,in_oct_quant      => gr_add_total(4).oct_quant      -- １０月 数量
              ,in_oct_amount     => gr_add_total(4).oct_amount     -- １０月 金額
              ,in_oct_price      => gr_add_total(4).oct_price      -- １０月 品目定価
              ,in_oct_to_amount  => gr_add_total(4).oct_to_amount  -- １０月 内訳合計
              ,in_oct_quant_t    => gr_add_total(4).oct_quant_t    -- １０月 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
              ,in_oct_s_cost     => gr_add_total(4).oct_s_cost     -- １０月 標準原価(計算用)
              ,in_oct_calc       => gr_add_total(4).oct_calc       -- １０月 品目定価*数量(計算用)
              ,in_oct_minus_flg   => gr_add_total(4).oct_minus_flg   -- １０月 数量マイナス値存在フラグ(計算用)
              ,in_oct_ht_zero_flg => gr_add_total(4).oct_ht_zero_flg -- １０月 品目定価*数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
              ,in_nov_quant      => gr_add_total(4).nov_quant      -- １１月 数量
              ,in_nov_amount     => gr_add_total(4).nov_amount     -- １１月 金額
              ,in_nov_price      => gr_add_total(4).nov_price      -- １１月 品目定価
              ,in_nov_to_amount  => gr_add_total(4).nov_to_amount  -- １１月 内訳合計
              ,in_nov_quant_t    => gr_add_total(4).nov_quant_t    -- １１月 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
              ,in_nov_s_cost     => gr_add_total(4).nov_s_cost     -- １１月 標準原価(計算用)
              ,in_nov_calc       => gr_add_total(4).nov_calc       -- １１月 品目定価*数量(計算用)
              ,in_nov_minus_flg   => gr_add_total(4).nov_minus_flg   -- １１月 数量マイナス値存在フラグ(計算用)
              ,in_nov_ht_zero_flg => gr_add_total(4).nov_ht_zero_flg -- １１月 品目定価*数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
              ,in_dec_quant      => gr_add_total(4).dec_quant      -- １２月 数量
              ,in_dec_amount     => gr_add_total(4).dec_amount     -- １２月 金額
              ,in_dec_price      => gr_add_total(4).dec_price      -- １２月 品目定価
              ,in_dec_to_amount  => gr_add_total(4).dec_to_amount  -- １２月 内訳合計
              ,in_dec_quant_t    => gr_add_total(4).dec_quant_t    -- １２月 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
              ,in_dec_s_cost     => gr_add_total(4).dec_s_cost     -- １２月 標準原価(計算用)
              ,in_dec_calc       => gr_add_total(4).dec_calc       -- １２月 品目定価*数量(計算用)
              ,in_dec_minus_flg   => gr_add_total(4).dec_minus_flg   -- １２月 数量マイナス値存在フラグ(計算用)
              ,in_dec_ht_zero_flg => gr_add_total(4).dec_ht_zero_flg -- １２月 品目定価*数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
              ,in_jan_quant      => gr_add_total(4).jan_quant      -- １月 数量
              ,in_jan_amount     => gr_add_total(4).jan_amount     -- １月 金額
              ,in_jan_price      => gr_add_total(4).jan_price      -- １月 品目定価
              ,in_jan_to_amount  => gr_add_total(4).jan_to_amount  -- １月 内訳合計
              ,in_jan_quant_t    => gr_add_total(4).jan_quant_t    -- １月 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
              ,in_jan_s_cost     => gr_add_total(4).jan_s_cost     -- １月 標準原価(計算用)
              ,in_jan_calc       => gr_add_total(4).jan_calc       -- １月 品目定価*数量(計算用)
              ,in_jan_minus_flg   => gr_add_total(4).jan_minus_flg   -- １月 数量マイナス値存在フラグ(計算用)
              ,in_jan_ht_zero_flg => gr_add_total(4).jan_ht_zero_flg -- １月 品目定価*数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
              ,in_feb_quant      => gr_add_total(4).feb_quant      -- ２月 数量
              ,in_feb_amount     => gr_add_total(4).feb_amount     -- ２月 金額
              ,in_feb_price      => gr_add_total(4).feb_price      -- ２月 品目定価
              ,in_feb_to_amount  => gr_add_total(4).feb_to_amount  -- ２月 内訳合計
              ,in_feb_quant_t    => gr_add_total(4).feb_quant_t    -- ２月 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
              ,in_feb_s_cost     => gr_add_total(4).feb_s_cost     -- ２月 標準原価(計算用)
              ,in_feb_calc       => gr_add_total(4).feb_calc       -- ２月 品目定価*数量(計算用)
              ,in_feb_minus_flg   => gr_add_total(4).feb_minus_flg   -- ２月 数量マイナス値存在フラグ(計算用)
              ,in_feb_ht_zero_flg => gr_add_total(4).feb_ht_zero_flg -- ２月 品目定価*数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
              ,in_mar_quant      => gr_add_total(4).mar_quant      -- ３月 数量
              ,in_mar_amount     => gr_add_total(4).mar_amount     -- ３月 金額
              ,in_mar_price      => gr_add_total(4).mar_price      -- ３月 品目定価
              ,in_mar_to_amount  => gr_add_total(4).mar_to_amount  -- ３月 内訳合計
              ,in_mar_quant_t    => gr_add_total(4).mar_quant_t    -- ３月 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
              ,in_mar_s_cost     => gr_add_total(4).mar_s_cost     -- ３月 標準原価(計算用)
              ,in_mar_calc       => gr_add_total(4).mar_calc       -- ３月 品目定価*数量(計算用)
              ,in_mar_minus_flg   => gr_add_total(4).mar_minus_flg   -- ３月 数量マイナス値存在フラグ(計算用)
              ,in_mar_ht_zero_flg => gr_add_total(4).mar_ht_zero_flg -- ３月 品目定価*数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
              ,in_apr_quant      => gr_add_total(4).apr_quant      -- ４月 数量
              ,in_apr_amount     => gr_add_total(4).apr_amount     -- ４月 金額
              ,in_apr_price      => gr_add_total(4).apr_price      -- ４月 品目定価
              ,in_apr_to_amount  => gr_add_total(4).apr_to_amount  -- ４月 内訳合計
              ,in_apr_quant_t    => gr_add_total(4).apr_quant_t    -- ４月 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
              ,in_apr_s_cost     => gr_add_total(4).apr_s_cost     -- ４月 標準原価(計算用)
              ,in_apr_calc       => gr_add_total(4).apr_calc       -- ４月 品目定価*数量(計算用)
              ,in_apr_minus_flg   => gr_add_total(4).apr_minus_flg   -- ４月 数量マイナス値存在フラグ(計算用)
              ,in_apr_ht_zero_flg => gr_add_total(4).apr_ht_zero_flg -- ４月 品目定価*数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
              ,in_year_quant     => gr_add_total(4).year_quant     -- 年計 数量
              ,in_year_amount    => gr_add_total(4).year_amount    -- 年計 金額
              ,in_year_price     => gr_add_total(4).year_price     -- 年計 品目定価
              ,in_year_to_amount => gr_add_total(4).year_to_amount -- 年計 内訳合計
              ,in_year_quant_t   => gr_add_total(4).year_quant_t   -- 年計 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
              ,in_year_s_cost    => gr_add_total(4).year_s_cost    -- 年計 標準原価(計算用)
              ,in_year_calc      => gr_add_total(4).year_calc      -- 年計 品目定価*数量(計算用)
              ,in_year_minus_flg   => gr_add_total(4).year_minus_flg   -- 年計 数量マイナス値存在フラグ(計算用)
              ,in_year_ht_zero_flg => gr_add_total(4).year_ht_zero_flg -- 年計 品目定価*数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
              ,ov_errbuf         => lv_errbuf   -- エラー・メッセージ           --# 固定 #
              ,ov_retcode        => lv_retcode  -- リターン・コード             --# 固定 #
              ,ov_errmsg         => lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
            );
            IF (lv_retcode = gv_status_error) THEN
              RAISE global_process_expt;
            END IF;
--
            -- -----------------------------------------------------
            --  商品区分終了Ｇタグ出力
            -- -----------------------------------------------------
            gl_xml_idx := gt_xml_data_table.COUNT + 1;
            gt_xml_data_table(gl_xml_idx).tag_name  := '/g_skbn';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
*/
--
            --------------------------------------------------------
            -- (全拠点)(3)拠点計/(4)商品区分計データタグ出力 
            --------------------------------------------------------
            <<kyoten_skbn_loop>>
            FOR n IN 3..4 LOOP        -- 拠点計/商品区分計
--
              -- 拠点計の場合
              IF ( n = 3) THEN
                lv_param_label := gv_name_ktn;
              -- 商品区分計の場合
              ELSE
                lv_param_label := gv_name_skbn;
              END IF;
--
              prc_create_xml_data_s_k_t
              (
                iv_label_name       => lv_param_label                   -- 商品区分計用タグ名
                ,in_may_quant       => gr_add_total(n).may_quant      -- ５月 数量
                ,in_may_amount      => gr_add_total(n).may_amount     -- ５月 金額
                ,in_may_price       => gr_add_total(n).may_price      -- ５月 品目定価
                ,in_may_to_amount   => gr_add_total(n).may_to_amount  -- ５月 内訳合計
                ,in_may_quant_t     => gr_add_total(n).may_quant_t    -- ５月 数量(計算用)
                ,in_may_s_cost      => gr_add_total(n).may_s_cost     -- ５月 標準原価(計算用)
                ,in_may_calc        => gr_add_total(n).may_calc       -- ５月 品目定価*数量(計算用)
                ,in_may_minus_flg   => gr_add_total(n).may_minus_flg   -- ５月 数量マイナス値存在フラグ(計算用)
                ,in_may_ht_zero_flg => gr_add_total(n).may_ht_zero_flg -- ５月 品目定価*数量(計)
                ,in_jun_quant       => gr_add_total(n).jun_quant      -- ６月 数量
                ,in_jun_amount      => gr_add_total(n).jun_amount     -- ６月 金額
                ,in_jun_price       => gr_add_total(n).jun_price      -- ６月 品目定価
                ,in_jun_to_amount   => gr_add_total(n).jun_to_amount  -- ６月 内訳合計
                ,in_jun_quant_t     => gr_add_total(n).jun_quant_t    -- ６月 数量(計算用)
                ,in_jun_s_cost      => gr_add_total(n).jun_s_cost     -- ６月 標準原価(計算用)
                ,in_jun_calc        => gr_add_total(n).jun_calc       -- ６月 品目定価*数量(計算用)
                ,in_jun_minus_flg   => gr_add_total(n).jun_minus_flg   -- ６月 数量マイナス値存在フラグ(計算用)
                ,in_jun_ht_zero_flg => gr_add_total(n).jun_ht_zero_flg -- ６月 品目定価*数量(計)
                ,in_jul_quant       => gr_add_total(n).jul_quant      -- ７月 数量
                ,in_jul_amount      => gr_add_total(n).jul_amount     -- ７月 金額
                ,in_jul_price       => gr_add_total(n).jul_price      -- ７月 品目定価
                ,in_jul_to_amount   => gr_add_total(n).jul_to_amount  -- ７月 内訳合計
                ,in_jul_quant_t     => gr_add_total(n).jul_quant_t    -- ７月 数量(計算用)
                ,in_jul_s_cost      => gr_add_total(n).jul_s_cost     -- ７月 標準原価(計算用)
                ,in_jul_calc        => gr_add_total(n).jul_calc       -- ７月 品目定価*数量(計算用)
                ,in_jul_minus_flg   => gr_add_total(n).jul_minus_flg   -- ７月 数量マイナス値存在フラグ(計算用)
                ,in_jul_ht_zero_flg => gr_add_total(n).jul_ht_zero_flg -- ７月 品目定価*数量(計)
                ,in_aug_quant       => gr_add_total(n).aug_quant      -- ８月 数量
                ,in_aug_amount      => gr_add_total(n).aug_amount     -- ８月 金額
                ,in_aug_price       => gr_add_total(n).aug_price      -- ８月 品目定価
                ,in_aug_to_amount   => gr_add_total(n).aug_to_amount  -- ８月 内訳合計
                ,in_aug_quant_t     => gr_add_total(n).aug_quant_t    -- ８月 数量(計算用)
                ,in_aug_s_cost      => gr_add_total(n).aug_s_cost     -- ８月 標準原価(計算用)
                ,in_aug_calc        => gr_add_total(n).aug_calc       -- ８月 品目定価*数量(計算用)
                ,in_aug_minus_flg   => gr_add_total(n).aug_minus_flg   -- ８月 数量マイナス値存在フラグ(計算用)
                ,in_aug_ht_zero_flg => gr_add_total(n).aug_ht_zero_flg -- ８月 品目定価*数量(計)
                ,in_sep_quant       => gr_add_total(n).sep_quant      -- ９月 数量
                ,in_sep_amount      => gr_add_total(n).sep_amount     -- ９月 金額
                ,in_sep_price       => gr_add_total(n).sep_price      -- ９月 品目定価
                ,in_sep_to_amount   => gr_add_total(n).sep_to_amount  -- ９月 内訳合計
                ,in_sep_quant_t     => gr_add_total(n).sep_quant_t    -- ９月 数量(計算用)
                ,in_sep_s_cost      => gr_add_total(n).sep_s_cost     -- ９月 標準原価(計算用)
                ,in_sep_calc        => gr_add_total(n).sep_calc       -- ９月 品目定価*数量(計算用)
                ,in_sep_minus_flg   => gr_add_total(n).sep_minus_flg   -- ９月 数量マイナス値存在フラグ(計算用)
                ,in_sep_ht_zero_flg => gr_add_total(n).sep_ht_zero_flg -- ９月 品目定価*数量(計)
                ,in_oct_quant       => gr_add_total(n).oct_quant      -- １０月 数量
                ,in_oct_amount      => gr_add_total(n).oct_amount     -- １０月 金額
                ,in_oct_price       => gr_add_total(n).oct_price      -- １０月 品目定価
                ,in_oct_to_amount   => gr_add_total(n).oct_to_amount  -- １０月 内訳合計
                ,in_oct_quant_t     => gr_add_total(n).oct_quant_t    -- １０月 数量(計算用)
                ,in_oct_s_cost      => gr_add_total(n).oct_s_cost     -- １０月 標準原価(計算用)
                ,in_oct_calc        => gr_add_total(n).oct_calc       -- １０月 品目定価*数量(計算用)
                ,in_oct_minus_flg   => gr_add_total(n).oct_minus_flg   -- １０月 数量マイナス値存在フラグ(計算用)
                ,in_oct_ht_zero_flg => gr_add_total(n).oct_ht_zero_flg -- １０月 品目定価*数量(計)
                ,in_nov_quant       => gr_add_total(n).nov_quant      -- １１月 数量
                ,in_nov_amount      => gr_add_total(n).nov_amount     -- １１月 金額
                ,in_nov_price       => gr_add_total(n).nov_price      -- １１月 品目定価
                ,in_nov_to_amount   => gr_add_total(n).nov_to_amount  -- １１月 内訳合計
                ,in_nov_quant_t     => gr_add_total(n).nov_quant_t    -- １１月 数量(計算用)
                ,in_nov_s_cost      => gr_add_total(n).nov_s_cost     -- １１月 標準原価(計算用)
                ,in_nov_calc        => gr_add_total(n).nov_calc       -- １１月 品目定価*数量(計算用)
                ,in_nov_minus_flg   => gr_add_total(n).nov_minus_flg   -- １１月 数量マイナス値存在フラグ(計算用)
                ,in_nov_ht_zero_flg => gr_add_total(n).nov_ht_zero_flg -- １１月 品目定価*数量(計)
                ,in_dec_quant       => gr_add_total(n).dec_quant      -- １２月 数量
                ,in_dec_amount      => gr_add_total(n).dec_amount     -- １２月 金額
                ,in_dec_price       => gr_add_total(n).dec_price      -- １２月 品目定価
                ,in_dec_to_amount   => gr_add_total(n).dec_to_amount  -- １２月 内訳合計
                ,in_dec_quant_t     => gr_add_total(n).dec_quant_t    -- １２月 数量(計算用)
                ,in_dec_s_cost      => gr_add_total(n).dec_s_cost     -- １２月 標準原価(計算用)
                ,in_dec_calc        => gr_add_total(n).dec_calc       -- １２月 品目定価*数量(計算用)
                ,in_dec_minus_flg   => gr_add_total(n).dec_minus_flg   -- １２月 数量マイナス値存在フラグ(計算用)
                ,in_dec_ht_zero_flg => gr_add_total(n).dec_ht_zero_flg -- １２月 品目定価*数量(計)
                ,in_jan_quant       => gr_add_total(n).jan_quant      -- １月 数量
                ,in_jan_amount      => gr_add_total(n).jan_amount     -- １月 金額
                ,in_jan_price       => gr_add_total(n).jan_price      -- １月 品目定価
                ,in_jan_to_amount   => gr_add_total(n).jan_to_amount  -- １月 内訳合計
                ,in_jan_quant_t     => gr_add_total(n).jan_quant_t    -- １月 数量(計算用)
                ,in_jan_s_cost      => gr_add_total(n).jan_s_cost     -- １月 標準原価(計算用)
                ,in_jan_calc        => gr_add_total(n).jan_calc       -- １月 品目定価*数量(計算用)
                ,in_jan_minus_flg   => gr_add_total(n).jan_minus_flg   -- １月 数量マイナス値存在フラグ(計算用)
                ,in_jan_ht_zero_flg => gr_add_total(n).jan_ht_zero_flg -- １月 品目定価*数量(計)
                ,in_feb_quant       => gr_add_total(n).feb_quant      -- ２月 数量
                ,in_feb_amount      => gr_add_total(n).feb_amount     -- ２月 金額
                ,in_feb_price       => gr_add_total(n).feb_price      -- ２月 品目定価
                ,in_feb_to_amount   => gr_add_total(n).feb_to_amount  -- ２月 内訳合計
                ,in_feb_quant_t     => gr_add_total(n).feb_quant_t    -- ２月 数量(計算用)
                ,in_feb_s_cost      => gr_add_total(n).feb_s_cost     -- ２月 標準原価(計算用)
                ,in_feb_calc        => gr_add_total(n).feb_calc       -- ２月 品目定価*数量(計算用)
                ,in_feb_minus_flg   => gr_add_total(n).feb_minus_flg   -- ２月 数量マイナス値存在フラグ(計算用)
                ,in_feb_ht_zero_flg => gr_add_total(n).feb_ht_zero_flg -- ２月 品目定価*数量(計)
                ,in_mar_quant       => gr_add_total(n).mar_quant      -- ３月 数量
                ,in_mar_amount      => gr_add_total(n).mar_amount     -- ３月 金額
                ,in_mar_price       => gr_add_total(n).mar_price      -- ３月 品目定価
                ,in_mar_to_amount   => gr_add_total(n).mar_to_amount  -- ３月 内訳合計
                ,in_mar_quant_t     => gr_add_total(n).mar_quant_t    -- ３月 数量(計算用)
                ,in_mar_s_cost      => gr_add_total(n).mar_s_cost     -- ３月 標準原価(計算用)
                ,in_mar_calc        => gr_add_total(n).mar_calc       -- ３月 品目定価*数量(計算用)
                ,in_mar_minus_flg   => gr_add_total(n).mar_minus_flg   -- ３月 数量マイナス値存在フラグ(計算用)
                ,in_mar_ht_zero_flg => gr_add_total(n).mar_ht_zero_flg -- ３月 品目定価*数量(計)
                ,in_apr_quant       => gr_add_total(n).apr_quant      -- ４月 数量
                ,in_apr_amount      => gr_add_total(n).apr_amount     -- ４月 金額
                ,in_apr_price       => gr_add_total(n).apr_price      -- ４月 品目定価
                ,in_apr_to_amount   => gr_add_total(n).apr_to_amount  -- ４月 内訳合計
                ,in_apr_quant_t     => gr_add_total(n).apr_quant_t    -- ４月 数量(計算用)
                ,in_apr_s_cost      => gr_add_total(n).apr_s_cost     -- ４月 標準原価(計算用)
                ,in_apr_calc        => gr_add_total(n).apr_calc       -- ４月 品目定価*数量(計算用)
                ,in_apr_minus_flg   => gr_add_total(n).apr_minus_flg   -- ４月 数量マイナス値存在フラグ(計算用)
                ,in_apr_ht_zero_flg => gr_add_total(n).apr_ht_zero_flg -- ４月 品目定価*数量(計)
                ,in_year_quant      => gr_add_total(n).year_quant     -- 年計 数量
                ,in_year_amount     => gr_add_total(n).year_amount    -- 年計 金額
                ,in_year_price      => gr_add_total(n).year_price     -- 年計 品目定価
                ,in_year_to_amount  => gr_add_total(n).year_to_amount -- 年計 内訳合計
                ,in_year_quant_t    => gr_add_total(n).year_quant_t   -- 年計 数量(計算用)
                ,in_year_s_cost     => gr_add_total(n).year_s_cost    -- 年計 標準原価(計算用)
                ,in_year_calc       => gr_add_total(n).year_calc      -- 年計 品目定価*数量(計算用)
                ,in_year_minus_flg   => gr_add_total(n).year_minus_flg   -- 年計 数量マイナス値存在フラグ(計算用)
                ,in_year_ht_zero_flg => gr_add_total(n).year_ht_zero_flg -- 年計 品目定価*数量(計)
                ,ov_errbuf         => lv_errbuf   -- エラー・メッセージ           --# 固定 #
                ,ov_retcode        => lv_retcode  -- リターン・コード             --# 固定 #
                ,ov_errmsg         => lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
              );
              IF (lv_retcode = gv_status_error) THEN
                RAISE global_process_expt;
              END IF;
--
              -- 拠点計の場合
              IF ( n = 3) THEN
                -- -----------------------------------------------------
                --  拠点終了Ｇタグ出力
                -- -----------------------------------------------------
                gl_xml_idx := gt_xml_data_table.COUNT + 1;
                gt_xml_data_table(gl_xml_idx).tag_name  := '/g_ktn';
                gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
    --
                -- -----------------------------------------------------
                --  拠点終了ＬＧタグ出力
                -- -----------------------------------------------------
                gl_xml_idx := gt_xml_data_table.COUNT + 1;
                gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_ktn_info';
                gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
              -- 商品区分計の場合
              ELSE
                -- -----------------------------------------------------
                --  商品区分終了Ｇタグ出力
                -- -----------------------------------------------------
                gl_xml_idx := gt_xml_data_table.COUNT + 1;
                gt_xml_data_table(gl_xml_idx).tag_name  := '/g_skbn';
                gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
              END IF;
--
            END LOOP kyoten_skbn_loop;
-- 2009/04/16 v1.6 T.Yoshimoto Mod End
--
          END IF;
--
          -- -----------------------------------------------------
          --  (全拠点)商品区分開始Ｇタグ出力
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'g_skbn';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
          -- -----------------------------------------------------
          -- (全拠点)商品区分(コード) タグ
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'skbn_code';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          gt_xml_data_table(gl_xml_idx).tag_value := gr_sale_plan(i).skbn;
--
          -- -----------------------------------------------------
          -- (全拠点)商品区分(名称) タグ
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'skbn_name';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
--
          ----------------------------------------------
          -- (全拠点)入力Ｐ『商品区分』がNULLの場合   --
          ----------------------------------------------
          IF (gr_param.prod_div IS NULL) THEN
            -- 抽出データが'1'の場合
            IF (gr_sale_plan(i).skbn = gv_prod_div_leaf) THEN
              gt_xml_data_table(gl_xml_idx).tag_value := lv_name_leaf;  -- 'リーフ'
            -- 抽出データが'2'の場合
            ELSIF (gr_sale_plan(i).skbn = gv_prod_div_drink) THEN
              gt_xml_data_table(gl_xml_idx).tag_value := lv_name_drink; -- 'ドリンク'
            END IF;
          -- 入力Ｐ『商品区分』が指定されている場合
          ELSE
            gt_xml_data_table(gl_xml_idx).tag_value := gr_sale_plan(i).skbn_name;
          END IF;
--
          -- -----------------------------------------------------
          -- (全拠点)拠点区分開始ＬＧタグ出力
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_ktn_info';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
          -- -----------------------------------------------------
          -- (全拠点)拠点区分開始Ｇタグ出力
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'g_ktn';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
          -- -----------------------------------------------------
          -- (全拠点)拠点区分(拠点コード) タグ
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'ktn_code';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          gt_xml_data_table(gl_xml_idx).tag_value := '';              -- NULL表示
--
          -- -----------------------------------------------------
          -- (全拠点)拠点区分(拠点略称) タグ
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'ktn_name';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          gt_xml_data_table(gl_xml_idx).tag_value := gv_name_all_ktn; -- '全拠点'
--
          -- -----------------------------------------------------
          -- (全拠点)群コード開始LＧタグ出力
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_gun_info';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
          -- -----------------------------------------------------
          -- (全拠点)群コード開始Ｇタグ出力
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'g_gun';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
          -- -----------------------------------------------------
          -- (全拠点)品目開始ＬＧタグ出力
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_dtl_info';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
          -- 各ブレイクキー更新
          lv_skbn_break := gr_sale_plan(i).skbn;              -- 商品区分
          lv_gun_break  := gr_sale_plan(i).gun;               -- 群コード
          lv_dtl_break  := lv_break_init;                     -- 品目コード
          lv_sttl_break := SUBSTRB(gr_sale_plan(i).gun,1,3);  -- 小群計
          lv_lttl_break := SUBSTRB(gr_sale_plan(i).gun,1,1);  -- 大群計
--
          ----------------------------------------
          -- (全拠点)各集計項目初期化                   --
          ----------------------------------------
          -- データが１件目の場合
          IF (i = 1) THEN 
            <<add_total_loop>>
            FOR l IN 1..5 LOOP        -- 小群計/大群計/拠点計/商品区分計/総合計
              gr_add_total(l).may_quant       := gn_0; -- ５月 数量
              gr_add_total(l).may_amount      := gn_0; -- ５月 金額
              gr_add_total(l).may_price       := gn_0; -- ５月 品目定価
              gr_add_total(l).may_to_amount   := gn_0; -- ５月 内訳合計
              gr_add_total(l).may_quant_t     := gn_0; -- ５月 数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
              gr_add_total(l).may_s_cost      := gn_0; -- ５月 標準原価(計)
              gr_add_total(l).may_calc        := gn_0; -- ５月 品目定価*数量(計)
              gr_add_total(l).may_minus_flg   := 'N';  -- ５月 数量マイナス値存在フラグ(計)
              gr_add_total(l).may_ht_zero_flg := 'N';  -- ５月 品目定価0値存在フラグ(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
              gr_add_total(l).jun_quant       := gn_0; -- ６月 数量
              gr_add_total(l).jun_amount      := gn_0; -- ６月 金額
              gr_add_total(l).jun_price       := gn_0; -- ６月 品目定価
              gr_add_total(l).jun_to_amount   := gn_0; -- ６月 内訳合計
              gr_add_total(l).jun_quant_t     := gn_0; -- ６月 数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
              gr_add_total(l).jun_s_cost      := gn_0; -- ６月 標準原価(計)
              gr_add_total(l).jun_calc        := gn_0; -- ６月 品目定価*数量(計)
              gr_add_total(l).jun_minus_flg   := 'N';  -- ６月 数量マイナス値存在フラグ(計)
              gr_add_total(l).jun_ht_zero_flg := 'N';  -- ６月 品目定価0値存在フラグ(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
              gr_add_total(l).jul_quant       := gn_0; -- ７月 数量
              gr_add_total(l).jul_amount      := gn_0; -- ７月 金額
              gr_add_total(l).jul_price       := gn_0; -- ７月 品目定価
              gr_add_total(l).jul_to_amount   := gn_0; -- ７月 内訳合計
              gr_add_total(l).jul_quant_t     := gn_0; -- ７月 数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
              gr_add_total(l).jul_s_cost      := gn_0; -- ７月 標準原価(計)
              gr_add_total(l).jul_calc        := gn_0; -- ７月 品目定価*数量(計)
              gr_add_total(l).jul_minus_flg   := 'N';  -- ７月 数量マイナス値存在フラグ(計)
              gr_add_total(l).jul_ht_zero_flg := 'N';  -- ７月 品目定価0値存在フラグ(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
              gr_add_total(l).aug_quant       := gn_0; -- ８月 数量
              gr_add_total(l).aug_amount      := gn_0; -- ８月 金額
              gr_add_total(l).aug_price       := gn_0; -- ８月 品目定価
              gr_add_total(l).aug_to_amount   := gn_0; -- ８月 内訳合計
              gr_add_total(l).aug_quant_t     := gn_0; -- ８月 数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
              gr_add_total(l).aug_s_cost      := gn_0; -- ８月 標準原価(計)
              gr_add_total(l).aug_calc        := gn_0; -- ８月 品目定価*数量(計)
              gr_add_total(l).aug_minus_flg   := 'N';  -- ８月 数量マイナス値存在フラグ(計)
              gr_add_total(l).aug_ht_zero_flg := 'N';  -- ８月 品目定価0値存在フラグ(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
              gr_add_total(l).sep_quant       := gn_0; -- ９月 数量
              gr_add_total(l).sep_amount      := gn_0; -- ９月 金額
              gr_add_total(l).sep_price       := gn_0; -- ９月 品目定価
              gr_add_total(l).sep_to_amount   := gn_0; -- ９月 内訳合計
              gr_add_total(l).sep_quant_t     := gn_0; -- ９月 数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
              gr_add_total(l).sep_s_cost      := gn_0; -- ９月 標準原価(計)
              gr_add_total(l).sep_calc        := gn_0; -- ９月 品目定価*数量(計)
              gr_add_total(l).sep_minus_flg   := 'N';  -- ９月 数量マイナス値存在フラグ(計)
              gr_add_total(l).sep_ht_zero_flg := 'N';  -- ９月 品目定価0値存在フラグ(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
              gr_add_total(l).oct_quant       := gn_0; -- １０月 数量
              gr_add_total(l).oct_amount      := gn_0; -- １０月 金額
              gr_add_total(l).oct_price       := gn_0; -- １０月 品目定価
              gr_add_total(l).oct_to_amount   := gn_0; -- １０月 内訳合計
              gr_add_total(l).oct_quant_t     := gn_0; -- １０月 数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
              gr_add_total(l).oct_s_cost      := gn_0; -- １０月 標準原価(計)
              gr_add_total(l).oct_calc        := gn_0; -- １０月 品目定価*数量(計)
              gr_add_total(l).oct_minus_flg   := 'N';  -- １０月 数量マイナス値存在フラグ(計)
              gr_add_total(l).oct_ht_zero_flg := 'N';  -- １０月 品目定価0値存在フラグ(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
              gr_add_total(l).nov_quant       := gn_0; -- １１月 数量
              gr_add_total(l).nov_amount      := gn_0; -- １１月 金額
              gr_add_total(l).nov_price       := gn_0; -- １１月 品目定価
              gr_add_total(l).nov_to_amount   := gn_0; -- １１月 内訳合計
              gr_add_total(l).nov_quant_t     := gn_0; -- １１月 数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
              gr_add_total(l).nov_s_cost      := gn_0; -- １１月 標準原価(計)
              gr_add_total(l).nov_calc        := gn_0; -- １１月 品目定価*数量(計)
              gr_add_total(l).nov_minus_flg   := 'N';  -- １１月 数量マイナス値存在フラグ(計)
              gr_add_total(l).nov_ht_zero_flg := 'N';  -- １１月 品目定価0値存在フラグ(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
              gr_add_total(l).dec_quant       := gn_0; -- １２月 数量
              gr_add_total(l).dec_amount      := gn_0; -- １２月 金額
              gr_add_total(l).dec_price       := gn_0; -- １２月 品目定価
              gr_add_total(l).dec_to_amount   := gn_0; -- １２月 内訳合計
              gr_add_total(l).dec_quant_t     := gn_0; -- １２月 数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
              gr_add_total(l).dec_s_cost      := gn_0; -- １２月 標準原価(計)
              gr_add_total(l).dec_calc        := gn_0; -- １２月 品目定価*数量(計)
              gr_add_total(l).dec_minus_flg   := 'N';  -- １２月 数量マイナス値存在フラグ(計)
              gr_add_total(l).dec_ht_zero_flg := 'N';  -- １２月 品目定価0値存在フラグ(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
              gr_add_total(l).jan_quant       := gn_0; -- １月 数量
              gr_add_total(l).jan_amount      := gn_0; -- １月 金額
              gr_add_total(l).jan_price       := gn_0; -- １月 品目定価
              gr_add_total(l).jan_to_amount   := gn_0; -- １月 内訳合計
              gr_add_total(l).jan_quant_t     := gn_0; -- １月 数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
              gr_add_total(l).jan_s_cost      := gn_0; -- １月 標準原価(計)
              gr_add_total(l).jan_calc        := gn_0; -- １月 品目定価*数量(計)
              gr_add_total(l).jan_minus_flg   := 'N';  -- １月 数量マイナス値存在フラグ(計)
              gr_add_total(l).jan_ht_zero_flg := 'N';  -- １月 品目定価0値存在フラグ(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
              gr_add_total(l).feb_quant       := gn_0; -- ２月 数量
              gr_add_total(l).feb_amount      := gn_0; -- ２月 金額
              gr_add_total(l).feb_price       := gn_0; -- ２月 品目定価
              gr_add_total(l).feb_to_amount   := gn_0; -- ２月 内訳合計
              gr_add_total(l).feb_quant_t     := gn_0; -- ２月 数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
              gr_add_total(l).feb_s_cost      := gn_0; -- ２月 標準原価(計)
              gr_add_total(l).feb_calc        := gn_0; -- ２月 品目定価*数量(計)
              gr_add_total(l).feb_minus_flg   := 'N';  -- ２月 数量マイナス値存在フラグ(計)
              gr_add_total(l).feb_ht_zero_flg := 'N';  -- ２月 品目定価0値存在フラグ(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
              gr_add_total(l).mar_quant       := gn_0; -- ３月 数量
              gr_add_total(l).mar_amount      := gn_0; -- ３月 金額
              gr_add_total(l).mar_price       := gn_0; -- ３月 品目定価
              gr_add_total(l).mar_to_amount   := gn_0; -- ３月 内訳合計
              gr_add_total(l).mar_quant_t     := gn_0; -- ３月 数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
              gr_add_total(l).mar_s_cost      := gn_0; -- ３月 標準原価(計)
              gr_add_total(l).mar_calc        := gn_0; -- ３月 品目定価*数量(計)
              gr_add_total(l).mar_minus_flg   := 'N';  -- ３月 数量マイナス値存在フラグ(計)
              gr_add_total(l).mar_ht_zero_flg := 'N';  -- ３月 品目定価0値存在フラグ(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
              gr_add_total(l).apr_quant       := gn_0; -- ４月 数量
              gr_add_total(l).apr_amount      := gn_0; -- ４月 金額
              gr_add_total(l).apr_price       := gn_0; -- ４月 品目定価
              gr_add_total(l).apr_to_amount   := gn_0; -- ４月 内訳合計
              gr_add_total(l).apr_quant_t     := gn_0; -- ４月 数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
              gr_add_total(l).apr_s_cost      := gn_0; -- ４月 標準原価(計)
              gr_add_total(l).apr_calc        := gn_0; -- ４月 品目定価*数量(計)
              gr_add_total(l).apr_minus_flg   := 'N';  -- ４月 数量マイナス値存在フラグ(計)
              gr_add_total(l).apr_ht_zero_flg := 'N';  -- ４月 品目定価0値存在フラグ(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
              gr_add_total(l).year_quant      := gn_0; -- 年計 数量
              gr_add_total(l).year_amount     := gn_0; -- 年計 金額
              gr_add_total(l).year_price      := gn_0; -- 年計 品目定価
              gr_add_total(l).year_to_amount  := gn_0; -- 年計 内訳合計
              gr_add_total(l).year_quant_t    := gn_0; -- 年計 数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
              gr_add_total(l).year_s_cost     := gn_0; -- 年計 標準原価(計)
              gr_add_total(l).year_calc       := gn_0; -- 年計 品目定価*数量(計)
              gr_add_total(l).year_minus_flg   := 'N'; -- 年計 数量マイナス値存在フラグ(計)
              gr_add_total(l).year_ht_zero_flg := 'N'; -- 年計 品目定価0値存在フラグ(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
            END LOOP add_total_loop;
          -- データ２件目以降の場合
          ELSE
            <<add_total_loop>>
            FOR l IN 1..4 LOOP        -- 小群計/大群計/拠点計/商品区分計
              gr_add_total(l).may_quant       := gn_0; -- ５月 数量
              gr_add_total(l).may_amount      := gn_0; -- ５月 金額
              gr_add_total(l).may_price       := gn_0; -- ５月 品目定価
              gr_add_total(l).may_to_amount   := gn_0; -- ５月 内訳合計
              gr_add_total(l).may_quant_t     := gn_0; -- ５月 数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
              gr_add_total(l).may_s_cost      := gn_0; -- ５月 標準原価(計)
              gr_add_total(l).may_calc        := gn_0; -- ５月 品目定価*数量(計)
              gr_add_total(l).may_minus_flg   := 'N';  -- ５月 数量マイナス値存在フラグ(計)
              gr_add_total(l).may_ht_zero_flg := 'N';  -- ５月 品目定価0値存在フラグ(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
              gr_add_total(l).jun_quant       := gn_0; -- ６月 数量
              gr_add_total(l).jun_amount      := gn_0; -- ６月 金額
              gr_add_total(l).jun_price       := gn_0; -- ６月 品目定価
              gr_add_total(l).jun_to_amount   := gn_0; -- ６月 内訳合計
              gr_add_total(l).jun_quant_t     := gn_0; -- ６月 数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
              gr_add_total(l).jun_s_cost      := gn_0; -- ６月 標準原価(計)
              gr_add_total(l).jun_calc        := gn_0; -- ６月 品目定価*数量(計)
              gr_add_total(l).jun_minus_flg   := 'N';  -- ６月 数量マイナス値存在フラグ(計)
              gr_add_total(l).jun_ht_zero_flg := 'N';  -- ６月 品目定価0値存在フラグ(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
              gr_add_total(l).jul_quant       := gn_0; -- ７月 数量
              gr_add_total(l).jul_amount      := gn_0; -- ７月 金額
              gr_add_total(l).jul_price       := gn_0; -- ７月 品目定価
              gr_add_total(l).jul_to_amount   := gn_0; -- ７月 内訳合計
              gr_add_total(l).jul_quant_t     := gn_0; -- ７月 数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
              gr_add_total(l).jul_s_cost      := gn_0; -- ７月 標準原価(計)
              gr_add_total(l).jul_calc        := gn_0; -- ７月 品目定価*数量(計)
              gr_add_total(l).jul_minus_flg   := 'N';  -- ７月 数量マイナス値存在フラグ(計)
              gr_add_total(l).jul_ht_zero_flg := 'N';  -- ７月 品目定価0値存在フラグ(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
              gr_add_total(l).aug_quant       := gn_0; -- ８月 数量
              gr_add_total(l).aug_amount      := gn_0; -- ８月 金額
              gr_add_total(l).aug_price       := gn_0; -- ８月 品目定価
              gr_add_total(l).aug_to_amount   := gn_0; -- ８月 内訳合計
              gr_add_total(l).aug_quant_t     := gn_0; -- ８月 数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
              gr_add_total(l).aug_s_cost      := gn_0; -- ８月 標準原価(計)
              gr_add_total(l).aug_calc        := gn_0; -- ８月 品目定価*数量(計)
              gr_add_total(l).aug_minus_flg   := 'N';  -- ８月 数量マイナス値存在フラグ(計)
              gr_add_total(l).aug_ht_zero_flg := 'N';  -- ８月 品目定価0値存在フラグ(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
              gr_add_total(l).sep_quant       := gn_0; -- ９月 数量
              gr_add_total(l).sep_amount      := gn_0; -- ９月 金額
              gr_add_total(l).sep_price       := gn_0; -- ９月 品目定価
              gr_add_total(l).sep_to_amount   := gn_0; -- ９月 内訳合計
              gr_add_total(l).sep_quant_t     := gn_0; -- ９月 数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
              gr_add_total(l).sep_s_cost      := gn_0; -- ９月 標準原価(計)
              gr_add_total(l).sep_calc        := gn_0; -- ９月 品目定価*数量(計)
              gr_add_total(l).sep_minus_flg   := 'N';  -- ９月 数量マイナス値存在フラグ(計)
              gr_add_total(l).sep_ht_zero_flg := 'N';  -- ９月 品目定価0値存在フラグ(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
              gr_add_total(l).oct_quant       := gn_0; -- １０月 数量
              gr_add_total(l).oct_amount      := gn_0; -- １０月 金額
              gr_add_total(l).oct_price       := gn_0; -- １０月 品目定価
              gr_add_total(l).oct_to_amount   := gn_0; -- １０月 内訳合計
              gr_add_total(l).oct_quant_t     := gn_0; -- １０月 数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
              gr_add_total(l).oct_s_cost      := gn_0; -- １０月 標準原価(計)
              gr_add_total(l).oct_calc        := gn_0; -- １０月 品目定価*数量(計)
              gr_add_total(l).oct_minus_flg   := 'N';  -- １０月 数量マイナス値存在フラグ(計)
              gr_add_total(l).oct_ht_zero_flg := 'N';  -- １０月 品目定価0値存在フラグ(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
              gr_add_total(l).nov_quant       := gn_0; -- １１月 数量
              gr_add_total(l).nov_amount      := gn_0; -- １１月 金額
              gr_add_total(l).nov_price       := gn_0; -- １１月 品目定価
              gr_add_total(l).nov_to_amount   := gn_0; -- １１月 内訳合計
              gr_add_total(l).nov_quant_t     := gn_0; -- １１月 数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
              gr_add_total(l).nov_s_cost      := gn_0; -- １１月 標準原価(計)
              gr_add_total(l).nov_calc        := gn_0; -- １１月 品目定価*数量(計)
              gr_add_total(l).nov_minus_flg   := 'N';  -- １１月 数量マイナス値存在フラグ(計)
              gr_add_total(l).nov_ht_zero_flg := 'N';  -- １１月 品目定価0値存在フラグ(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
              gr_add_total(l).dec_quant       := gn_0; -- １２月 数量
              gr_add_total(l).dec_amount      := gn_0; -- １２月 金額
              gr_add_total(l).dec_price       := gn_0; -- １２月 品目定価
              gr_add_total(l).dec_to_amount   := gn_0; -- １２月 内訳合計
              gr_add_total(l).dec_quant_t     := gn_0; -- １２月 数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
              gr_add_total(l).dec_s_cost      := gn_0; -- １２月 標準原価(計)
              gr_add_total(l).dec_calc        := gn_0; -- １２月 品目定価*数量(計)
              gr_add_total(l).dec_minus_flg   := 'N';  -- １２月 数量マイナス値存在フラグ(計)
              gr_add_total(l).dec_ht_zero_flg := 'N';  -- １２月 品目定価0値存在フラグ(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
              gr_add_total(l).jan_quant       := gn_0; -- １月 数量
              gr_add_total(l).jan_amount      := gn_0; -- １月 金額
              gr_add_total(l).jan_price       := gn_0; -- １月 品目定価
              gr_add_total(l).jan_to_amount   := gn_0; -- １月 内訳合計
              gr_add_total(l).jan_quant_t     := gn_0; -- １月 数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
              gr_add_total(l).jan_s_cost      := gn_0; -- １月 標準原価(計)
              gr_add_total(l).jan_calc        := gn_0; -- １月 品目定価*数量(計)
              gr_add_total(l).jan_minus_flg   := 'N';  -- １月 数量マイナス値存在フラグ(計)
              gr_add_total(l).jan_ht_zero_flg := 'N';  -- １月 品目定価0値存在フラグ(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
              gr_add_total(l).feb_quant       := gn_0; -- ２月 数量
              gr_add_total(l).feb_amount      := gn_0; -- ２月 金額
              gr_add_total(l).feb_price       := gn_0; -- ２月 品目定価
              gr_add_total(l).feb_to_amount   := gn_0; -- ２月 内訳合計
              gr_add_total(l).feb_quant_t     := gn_0; -- ２月 数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
              gr_add_total(l).feb_s_cost      := gn_0; -- ２月 標準原価(計)
              gr_add_total(l).feb_calc        := gn_0; -- ２月 品目定価*数量(計)
              gr_add_total(l).feb_minus_flg   := 'N';  -- ２月 数量マイナス値存在フラグ(計)
              gr_add_total(l).feb_ht_zero_flg := 'N';  -- ２月 品目定価0値存在フラグ(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
              gr_add_total(l).mar_quant       := gn_0; -- ３月 数量
              gr_add_total(l).mar_amount      := gn_0; -- ３月 金額
              gr_add_total(l).mar_price       := gn_0; -- ３月 品目定価
              gr_add_total(l).mar_to_amount   := gn_0; -- ３月 内訳合計
              gr_add_total(l).mar_quant_t     := gn_0; -- ３月 数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
              gr_add_total(l).mar_s_cost      := gn_0; -- ３月 標準原価(計)
              gr_add_total(l).mar_calc        := gn_0; -- ３月 品目定価*数量(計)
              gr_add_total(l).mar_minus_flg   := 'N';  -- ３月 数量マイナス値存在フラグ(計)
              gr_add_total(l).mar_ht_zero_flg := 'N';  -- ３月 品目定価0値存在フラグ(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
              gr_add_total(l).apr_quant       := gn_0; -- ４月 数量
              gr_add_total(l).apr_amount      := gn_0; -- ４月 金額
              gr_add_total(l).apr_price       := gn_0; -- ４月 品目定価
              gr_add_total(l).apr_to_amount   := gn_0; -- ４月 内訳合計
              gr_add_total(l).apr_quant_t     := gn_0; -- ４月 数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
              gr_add_total(l).apr_s_cost      := gn_0; -- ４月 標準原価(計)
              gr_add_total(l).apr_calc        := gn_0; -- ４月 品目定価*数量(計)
              gr_add_total(l).apr_minus_flg   := 'N';  -- ４月 数量マイナス値存在フラグ(計)
              gr_add_total(l).apr_ht_zero_flg := 'N';  -- ４月 品目定価0値存在フラグ(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
              gr_add_total(l).year_quant      := gn_0; -- 年計 数量
              gr_add_total(l).year_amount     := gn_0; -- 年計 金額
              gr_add_total(l).year_price      := gn_0; -- 年計 品目定価
              gr_add_total(l).year_to_amount  := gn_0; -- 年計 内訳合計
              gr_add_total(l).year_quant_t    := gn_0; -- 年計 数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
              gr_add_total(l).year_s_cost     := gn_0; -- 年計 標準原価(計)
              gr_add_total(l).year_calc       := gn_0; -- 年計 品目定価*数量(計)
              gr_add_total(l).year_minus_flg   := 'N'; -- 年計 数量マイナス値存在フラグ(計)
              gr_add_total(l).year_ht_zero_flg := 'N'; -- 年計 品目定価0値存在フラグ(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
            END LOOP add_total_loop;
          END IF;
--
          -- 年計初期化
          ln_year_quant_sum  := gn_0;           -- 数量
          ln_year_amount_sum := gn_0;           -- 金額
          ln_year_to_am_sum  := gn_0;           -- 内訳合計
          ln_year_price_sum  := gn_0;           -- 品目定価
--
          -- XML出力フラグ初期化
          <<xml_out_loop>>
          FOR n IN 1..12 LOOP
            gr_xml_out(n).out_fg   := lv_no;
          END LOOP xml_out_loop;
--
        END IF;
--
        -- ====================================================
        -- (全拠点)群コードブレイク
        -- ====================================================
        -- 群コードが切り替わったとき
        IF (gr_sale_plan(i).gun <> lv_gun_break) THEN
          ---------------------------------------------------------------
          -- (全拠点)各月抽出データが存在しない場合、0表示にてXML出力  --
          ---------------------------------------------------------------
          <<xml_out_0_loop>>
          FOR m IN 1..12 LOOP
            IF (gr_xml_out(m).out_fg = lv_no) THEN
              prc_create_xml_data_dtl_n
                (
                  iv_label_name     => gr_xml_out(m).tag_name                      -- 出力タグ名
                 ,ov_errbuf         => lv_errbuf   -- エラー・メッセージ           --# 固定 #
                 ,ov_retcode        => lv_retcode  -- リターン・コード             --# 固定 #
                 ,ov_errmsg         => lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
                );
              IF (lv_retcode = gv_status_error) THEN
                RAISE global_process_expt;
              END IF;
            END IF;
          END LOOP xml_out_0_loop;
--
          -- -----------------------------------------------------
          -- (全拠点)年計 数量データ
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'year_quant';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          gt_xml_data_table(gl_xml_idx).tag_value := ln_year_quant_sum;
--
          -- -----------------------------------------------------
          -- (全拠点)年計 金額データ
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'year_amount';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          gt_xml_data_table(gl_xml_idx).tag_value := ROUND(ln_year_amount_sum / 1000,0);
--
          -- -----------------------------------------------------
          -- (全拠点)年計 粗利率データ
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'year_arari_par';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
--
          ----------------------------------------------
          -- (全拠点)粗利計算 (金額－内訳合計＊数量)  --
          ----------------------------------------------
          ln_arari := ln_year_amount_sum - ln_year_to_am_sum * ln_year_quant_sum;
          -- ０除算回避判定
          IF (ln_year_amount_sum <> gn_0) THEN
          -- 値が[0]出なければ計算
          gt_xml_data_table(gl_xml_idx).tag_value := 
                    ROUND((ln_arari / ln_year_amount_sum * 100),2);
          ELSE
            -- 値が[0]の場合は、一律[0]設定
            gt_xml_data_table(gl_xml_idx).tag_value := gn_0;
          END IF;
--
          -- -----------------------------------------------------
          -- (全拠点)年計 掛率データ
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'year_kake_par';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
--
          --------------------------------------
          -- ０除算判定項目へ判定値を挿入     --
          --------------------------------------
          ln_chk_0 := ln_year_price_sum * ln_year_quant_sum;
          -- ０除算回避判定
          IF (ln_chk_0 <> gn_0) THEN
          -- 値が[0]出なければ計算
          ln_kake_par := ROUND((ln_year_amount_sum * 100) / ln_chk_0,2);
          ELSE
            -- 値が[0]の場合は、一律[0]設定
            ln_kake_par := gn_0;
          END IF;
--
          -- 品目定価 = ０か、計算結果がマイナスの場合、固定値[70.00]を登録
          IF ((ln_year_price_sum = 0)
            OR (ln_kake_par < 0)) THEN
            ln_kake_par := gn_kotei_70; -- 固定値[70.00]
          END IF;
          gt_xml_data_table(gl_xml_idx).tag_value := ln_kake_par;
--
          -- 各集計項目へデータ挿入
          <<add_total_loop>>
          FOR r IN 1..5 LOOP                     -- 小群計/大群計/拠点計/商品区分計/総合計
            gr_add_total(r).year_quant     :=
               gr_add_total(r).year_quant     + ln_year_quant_sum;        -- 数量
            gr_add_total(r).year_amount    :=
               gr_add_total(r).year_amount    + ln_year_amount_sum;       -- 金額
            gr_add_total(r).year_price     :=
               gr_add_total(r).year_price     + ln_year_price_sum;        -- 品目定価
            gr_add_total(r).year_to_amount :=
               gr_add_total(r).year_to_amount + ln_year_to_am_sum;        -- 内訳合計
            gr_add_total(r).year_quant_t   :=
               gr_add_total(r).year_quant_t   + ln_year_quant_sum;        -- 数量(計)
          END LOOP add_total_loop;
--
          -- -----------------------------------------------------
          -- (全拠点)品目終了Ｇタグ出力
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_dtl';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
          -- -----------------------------------------------------
          -- (全拠点)品目終了ＬＧタグ出力
          -- ----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_dtl_info';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
          -- ====================================================
          -- (全拠点)小群計ブレイク
          -- ====================================================
          IF (SUBSTRB(gr_sale_plan(i).gun,1,3) <> lv_sttl_break) THEN
            --------------------------------------------------------
            -- (全拠点)XMLデータ作成 - 帳票データ出力 小群計
            --------------------------------------------------------
            prc_create_xml_data_st_lt
            (
               iv_label_name     => gv_name_st                     -- 小群計用タグ名
              ,iv_name           => gv_label_st                    -- 小群計タイトル
              ,in_may_quant      => gr_add_total(1).may_quant      -- ５月 数量
              ,in_may_amount     => gr_add_total(1).may_amount     -- ５月 金額
              ,in_may_price      => gr_add_total(1).may_price      -- ５月 品目定価
              ,in_may_to_amount  => gr_add_total(1).may_to_amount  -- ５月 内訳合計
              ,in_may_quant_t    => gr_add_total(1).may_quant_t    -- ５月 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
              ,in_may_s_cost     => gr_add_total(1).may_s_cost     -- ５月 標準原価(計算用)
              ,in_may_calc       => gr_add_total(1).may_calc       -- ５月 品目定価*数量(計算用)
              ,in_may_minus_flg   => gr_add_total(1).may_minus_flg   -- ５月 数量マイナス値存在フラグ(計算用)
              ,in_may_ht_zero_flg => gr_add_total(1).may_ht_zero_flg -- ５月 品目定価0値存在フラグ(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
              ,in_jun_quant      => gr_add_total(1).jun_quant      -- ６月 数量
              ,in_jun_amount     => gr_add_total(1).jun_amount     -- ６月 金額
              ,in_jun_price      => gr_add_total(1).jun_price      -- ６月 品目定価
              ,in_jun_to_amount  => gr_add_total(1).jun_to_amount  -- ６月 内訳合計
              ,in_jun_quant_t    => gr_add_total(1).jun_quant_t    -- ６月 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
              ,in_jun_s_cost     => gr_add_total(1).jun_s_cost     -- ６月 標準原価(計算用)
              ,in_jun_calc       => gr_add_total(1).jun_calc       -- ６月 品目定価*数量(計算用)
              ,in_jun_minus_flg   => gr_add_total(1).jun_minus_flg   -- ６月 数量マイナス値存在フラグ(計算用)
              ,in_jun_ht_zero_flg => gr_add_total(1).jun_ht_zero_flg -- ６月 品目定価0値存在フラグ(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
              ,in_jul_quant      => gr_add_total(1).jul_quant      -- ７月 数量
              ,in_jul_amount     => gr_add_total(1).jul_amount     -- ７月 金額
              ,in_jul_price      => gr_add_total(1).jul_price      -- ７月 品目定価
              ,in_jul_to_amount  => gr_add_total(1).jul_to_amount  -- ７月 内訳合計
              ,in_jul_quant_t    => gr_add_total(1).jul_quant_t    -- ７月 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
              ,in_jul_s_cost     => gr_add_total(1).jul_s_cost     -- ７月 標準原価(計算用)
              ,in_jul_calc       => gr_add_total(1).jul_calc       -- ７月 品目定価*数量(計算用)
              ,in_jul_minus_flg   => gr_add_total(1).jul_minus_flg   -- ７月 数量マイナス値存在フラグ(計算用)
              ,in_jul_ht_zero_flg => gr_add_total(1).jul_ht_zero_flg -- ７月 品目定価0値存在フラグ(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
              ,in_aug_quant      => gr_add_total(1).aug_quant      -- ８月 数量
              ,in_aug_amount     => gr_add_total(1).aug_amount     -- ８月 金額
              ,in_aug_price      => gr_add_total(1).aug_price      -- ８月 品目定価
              ,in_aug_to_amount  => gr_add_total(1).aug_to_amount  -- ８月 内訳合計
              ,in_aug_quant_t    => gr_add_total(1).aug_quant_t    -- ８月 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
              ,in_aug_s_cost     => gr_add_total(1).aug_s_cost     -- ８月 標準原価(計算用)
              ,in_aug_calc       => gr_add_total(1).aug_calc       -- ８月 品目定価*数量(計算用)
              ,in_aug_minus_flg   => gr_add_total(1).aug_minus_flg   -- ８月 数量マイナス値存在フラグ(計算用)
              ,in_aug_ht_zero_flg => gr_add_total(1).aug_ht_zero_flg -- ８月 品目定価0値存在フラグ(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
              ,in_sep_quant      => gr_add_total(1).sep_quant      -- ９月 数量
              ,in_sep_amount     => gr_add_total(1).sep_amount     -- ９月 金額
              ,in_sep_price      => gr_add_total(1).sep_price      -- ９月 品目定価
              ,in_sep_to_amount  => gr_add_total(1).sep_to_amount  -- ９月 内訳合計
              ,in_sep_quant_t    => gr_add_total(1).sep_quant_t    -- ９月 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
              ,in_sep_s_cost     => gr_add_total(1).sep_s_cost     -- ９月 標準原価(計算用)
              ,in_sep_calc       => gr_add_total(1).sep_calc       -- ９月 品目定価*数量(計算用)
              ,in_sep_minus_flg   => gr_add_total(1).sep_minus_flg   -- ９月 数量マイナス値存在フラグ(計算用)
              ,in_sep_ht_zero_flg => gr_add_total(1).sep_ht_zero_flg -- ９月 品目定価0値存在フラグ(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
              ,in_oct_quant      => gr_add_total(1).oct_quant      -- １０月 数量
              ,in_oct_amount     => gr_add_total(1).oct_amount     -- １０月 金額
              ,in_oct_price      => gr_add_total(1).oct_price      -- １０月 品目定価
              ,in_oct_to_amount  => gr_add_total(1).oct_to_amount  -- １０月 内訳合計
              ,in_oct_quant_t    => gr_add_total(1).oct_quant_t    -- １０月 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
              ,in_oct_s_cost     => gr_add_total(1).oct_s_cost     -- １０月 標準原価(計算用)
              ,in_oct_calc       => gr_add_total(1).oct_calc       -- １０月 品目定価*数量(計算用)
              ,in_oct_minus_flg   => gr_add_total(1).oct_minus_flg   -- １０月 数量マイナス値存在フラグ(計算用)
              ,in_oct_ht_zero_flg => gr_add_total(1).oct_ht_zero_flg -- １０月 品目定価0値存在フラグ(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
              ,in_nov_quant      => gr_add_total(1).nov_quant      -- １１月 数量
              ,in_nov_amount     => gr_add_total(1).nov_amount     -- １１月 金額
              ,in_nov_price      => gr_add_total(1).nov_price      -- １１月 品目定価
              ,in_nov_to_amount  => gr_add_total(1).nov_to_amount  -- １１月 内訳合計
              ,in_nov_quant_t    => gr_add_total(1).nov_quant_t    -- １１月 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
              ,in_nov_s_cost     => gr_add_total(1).nov_s_cost     -- １１月 標準原価(計算用)
              ,in_nov_calc       => gr_add_total(1).nov_calc       -- １１月 品目定価*数量(計算用)
              ,in_nov_minus_flg   => gr_add_total(1).nov_minus_flg   -- １１月 数量マイナス値存在フラグ(計算用)
              ,in_nov_ht_zero_flg => gr_add_total(1).nov_ht_zero_flg -- １１月 品目定価0値存在フラグ(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
              ,in_dec_quant      => gr_add_total(1).dec_quant      -- １２月 数量
              ,in_dec_amount     => gr_add_total(1).dec_amount     -- １２月 金額
              ,in_dec_price      => gr_add_total(1).dec_price      -- １２月 品目定価
              ,in_dec_to_amount  => gr_add_total(1).dec_to_amount  -- １２月 内訳合計
              ,in_dec_quant_t    => gr_add_total(1).dec_quant_t    -- １２月 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
              ,in_dec_s_cost     => gr_add_total(1).dec_s_cost     -- １２月 標準原価(計算用)
              ,in_dec_calc       => gr_add_total(1).dec_calc       -- １２月 品目定価*数量(計算用)
              ,in_dec_minus_flg   => gr_add_total(1).dec_minus_flg   -- １２月 数量マイナス値存在フラグ(計算用)
              ,in_dec_ht_zero_flg => gr_add_total(1).dec_ht_zero_flg -- １２月 品目定価0値存在フラグ(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
              ,in_jan_quant      => gr_add_total(1).jan_quant      -- １月 数量
              ,in_jan_amount     => gr_add_total(1).jan_amount     -- １月 金額
              ,in_jan_price      => gr_add_total(1).jan_price      -- １月 品目定価
              ,in_jan_to_amount  => gr_add_total(1).jan_to_amount  -- １月 内訳合計
              ,in_jan_quant_t    => gr_add_total(1).jan_quant_t    -- １月 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
              ,in_jan_s_cost     => gr_add_total(1).jan_s_cost     -- １月 標準原価(計算用)
              ,in_jan_calc       => gr_add_total(1).jan_calc       -- １月 品目定価*数量(計算用)
              ,in_jan_minus_flg   => gr_add_total(1).jan_minus_flg   -- １月 数量マイナス値存在フラグ(計算用)
              ,in_jan_ht_zero_flg => gr_add_total(1).jan_ht_zero_flg -- １月 品目定価0値存在フラグ(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
              ,in_feb_quant      => gr_add_total(1).feb_quant      -- ２月 数量
              ,in_feb_amount     => gr_add_total(1).feb_amount     -- ２月 金額
              ,in_feb_price      => gr_add_total(1).feb_price      -- ２月 品目定価
              ,in_feb_to_amount  => gr_add_total(1).feb_to_amount  -- ２月 内訳合計
              ,in_feb_quant_t    => gr_add_total(1).feb_quant_t    -- ２月 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
              ,in_feb_s_cost     => gr_add_total(1).feb_s_cost     -- ２月 標準原価(計算用)
              ,in_feb_calc       => gr_add_total(1).feb_calc       -- ２月 品目定価*数量(計算用)
              ,in_feb_minus_flg   => gr_add_total(1).feb_minus_flg   -- ２月 数量マイナス値存在フラグ(計算用)
              ,in_feb_ht_zero_flg => gr_add_total(1).feb_ht_zero_flg -- ２月 品目定価0値存在フラグ(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
              ,in_mar_quant      => gr_add_total(1).mar_quant      -- ３月 数量
              ,in_mar_amount     => gr_add_total(1).mar_amount     -- ３月 金額
              ,in_mar_price      => gr_add_total(1).mar_price      -- ３月 品目定価
              ,in_mar_to_amount  => gr_add_total(1).mar_to_amount  -- ３月 内訳合計
              ,in_mar_quant_t    => gr_add_total(1).mar_quant_t    -- ３月 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
              ,in_mar_s_cost     => gr_add_total(1).mar_s_cost     -- ３月 標準原価(計算用)
              ,in_mar_calc       => gr_add_total(1).mar_calc       -- ３月 品目定価*数量(計算用)
              ,in_mar_minus_flg   => gr_add_total(1).mar_minus_flg   -- ３月 数量マイナス値存在フラグ(計算用)
              ,in_mar_ht_zero_flg => gr_add_total(1).mar_ht_zero_flg -- ３月 品目定価0値存在フラグ(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
              ,in_apr_quant      => gr_add_total(1).apr_quant      -- ４月 数量
              ,in_apr_amount     => gr_add_total(1).apr_amount     -- ４月 金額
              ,in_apr_price      => gr_add_total(1).apr_price      -- ４月 品目定価
              ,in_apr_to_amount  => gr_add_total(1).apr_to_amount  -- ４月 内訳合計
              ,in_apr_quant_t    => gr_add_total(1).apr_quant_t    -- ４月 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
              ,in_apr_s_cost     => gr_add_total(1).apr_s_cost     -- ４月 標準原価(計算用)
              ,in_apr_calc       => gr_add_total(1).apr_calc       -- ４月 品目定価*数量(計算用)
              ,in_apr_minus_flg   => gr_add_total(1).apr_minus_flg   -- ４月 数量マイナス値存在フラグ(計算用)
              ,in_apr_ht_zero_flg => gr_add_total(1).apr_ht_zero_flg -- ４月 品目定価0値存在フラグ(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
              ,in_year_quant     => gr_add_total(1).year_quant     -- 年計 数量
              ,in_year_amount    => gr_add_total(1).year_amount    -- 年計 金額
              ,in_year_price     => gr_add_total(1).year_price     -- 年計 品目定価
              ,in_year_to_amount => gr_add_total(1).year_to_amount -- 年計 内訳合計
              ,in_year_quant_t   => gr_add_total(1).year_quant_t   -- 年計 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
              ,in_year_s_cost    => gr_add_total(1).year_s_cost    -- 年計 標準原価(計算用)
              ,in_year_calc      => gr_add_total(1).year_calc      -- 年計 品目定価*数量(計算用)
              ,in_year_minus_flg   => gr_add_total(1).year_minus_flg   -- 年計 数量マイナス値存在フラグ(計算用)
              ,in_year_ht_zero_flg => gr_add_total(1).year_ht_zero_flg -- 年計 品目定価0値存在フラグ(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
              ,ov_errbuf         => lv_errbuf   -- エラー・メッセージ           --# 固定 #
              ,ov_retcode        => lv_retcode  -- リターン・コード             --# 固定 #
              ,ov_errmsg         => lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
            );
            IF (lv_retcode = gv_status_error) THEN
              RAISE global_process_expt;
            END IF;
--
            -- 小群計ブレイクキー更新
            lv_sttl_break := SUBSTRB(gr_sale_plan(i).gun,1,3);
--
            -- 小群計集計項目初期化
            gr_add_total(1).may_quant       := gn_0; -- ５月 数量
            gr_add_total(1).may_amount      := gn_0; -- ５月 金額
            gr_add_total(1).may_price       := gn_0; -- ５月 品目定価
            gr_add_total(1).may_to_amount   := gn_0; -- ５月 内訳合計
            gr_add_total(1).may_quant_t     := gn_0; -- ５月 数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
            gr_add_total(1).may_s_cost      := gn_0; -- ５月 標準原価(計)
            gr_add_total(1).may_calc        := gn_0; -- ５月 品目定価*数量(計)
            gr_add_total(1).may_minus_flg   := 'N';  -- ５月 数量マイナス値存在フラグ(計算用)
            gr_add_total(1).may_ht_zero_flg := 'N';  -- ５月 品目定価0値存在フラグ(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
            gr_add_total(1).jun_quant       := gn_0; -- ６月 数量
            gr_add_total(1).jun_amount      := gn_0; -- ６月 金額
            gr_add_total(1).jun_price       := gn_0; -- ６月 品目定価
            gr_add_total(1).jun_to_amount   := gn_0; -- ６月 内訳合計
            gr_add_total(1).jun_quant_t     := gn_0; -- ６月 数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
            gr_add_total(1).jun_s_cost      := gn_0; -- ６月 標準原価(計)
            gr_add_total(1).jun_calc        := gn_0; -- ６月 品目定価*数量(計)
            gr_add_total(1).jun_minus_flg   := 'N';  -- ６月 数量マイナス値存在フラグ(計算用)
            gr_add_total(1).jun_ht_zero_flg := 'N';  -- ６月 品目定価0値存在フラグ(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
            gr_add_total(1).jul_quant       := gn_0; -- ７月 数量
            gr_add_total(1).jul_amount      := gn_0; -- ７月 金額
            gr_add_total(1).jul_price       := gn_0; -- ７月 品目定価
            gr_add_total(1).jul_to_amount   := gn_0; -- ７月 内訳合計
            gr_add_total(1).jul_quant_t     := gn_0; -- ７月 数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
            gr_add_total(1).jul_s_cost      := gn_0; -- ７月 標準原価(計)
            gr_add_total(1).jul_calc        := gn_0; -- ７月 品目定価*数量(計)
            gr_add_total(1).jul_minus_flg   := 'N';  -- ７月 数量マイナス値存在フラグ(計算用)
            gr_add_total(1).jul_ht_zero_flg := 'N';  -- ７月 品目定価0値存在フラグ(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
            gr_add_total(1).aug_quant       := gn_0; -- ８月 数量
            gr_add_total(1).aug_amount      := gn_0; -- ８月 金額
            gr_add_total(1).aug_price       := gn_0; -- ８月 品目定価
            gr_add_total(1).aug_to_amount   := gn_0; -- ８月 内訳合計
            gr_add_total(1).aug_quant_t     := gn_0; -- ８月 数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
            gr_add_total(1).aug_s_cost      := gn_0; -- ８月 標準原価(計)
            gr_add_total(1).aug_calc        := gn_0; -- ８月 品目定価*数量(計)
            gr_add_total(1).aug_minus_flg   := 'N';  -- ８月 数量マイナス値存在フラグ(計算用)
            gr_add_total(1).aug_ht_zero_flg := 'N';  -- ８月 品目定価0値存在フラグ(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
            gr_add_total(1).sep_quant       := gn_0; -- ９月 数量
            gr_add_total(1).sep_amount      := gn_0; -- ９月 金額
            gr_add_total(1).sep_price       := gn_0; -- ９月 品目定価
            gr_add_total(1).sep_to_amount   := gn_0; -- ９月 内訳合計
            gr_add_total(1).sep_quant_t     := gn_0; -- ９月 数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
            gr_add_total(1).sep_s_cost      := gn_0; -- ９月 標準原価(計)
            gr_add_total(1).sep_calc        := gn_0; -- ９月 品目定価*数量(計)
            gr_add_total(1).sep_minus_flg   := 'N';  -- ９月 数量マイナス値存在フラグ(計算用)
            gr_add_total(1).sep_ht_zero_flg := 'N';  -- ９月 品目定価0値存在フラグ(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
            gr_add_total(1).oct_quant       := gn_0; -- １０月 数量
            gr_add_total(1).oct_amount      := gn_0; -- １０月 金額
            gr_add_total(1).oct_price       := gn_0; -- １０月 品目定価
            gr_add_total(1).oct_to_amount   := gn_0; -- １０月 内訳合計
            gr_add_total(1).oct_quant_t     := gn_0; -- １０月 数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
            gr_add_total(1).oct_s_cost      := gn_0; -- １０月 標準原価(計)
            gr_add_total(1).oct_calc        := gn_0; -- １０月 品目定価*数量(計)
            gr_add_total(1).oct_minus_flg   := 'N';  -- １０月 数量マイナス値存在フラグ(計算用)
            gr_add_total(1).oct_ht_zero_flg := 'N';  -- １０月 品目定価0値存在フラグ(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
            gr_add_total(1).nov_quant       := gn_0; -- １１月 数量
            gr_add_total(1).nov_amount      := gn_0; -- １１月 金額
            gr_add_total(1).nov_price       := gn_0; -- １１月 品目定価
            gr_add_total(1).nov_to_amount   := gn_0; -- １１月 内訳合計
            gr_add_total(1).nov_quant_t     := gn_0; -- １１月 数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
            gr_add_total(1).nov_s_cost      := gn_0; -- １１月 標準原価(計)
            gr_add_total(1).nov_calc        := gn_0; -- １１月 品目定価*数量(計)
            gr_add_total(1).nov_minus_flg   := 'N';  -- １１月 数量マイナス値存在フラグ(計算用)
            gr_add_total(1).nov_ht_zero_flg := 'N';  -- １１月 品目定価0値存在フラグ(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
            gr_add_total(1).dec_quant       := gn_0; -- １２月 数量
            gr_add_total(1).dec_amount      := gn_0; -- １２月 金額
            gr_add_total(1).dec_price       := gn_0; -- １２月 品目定価
            gr_add_total(1).dec_to_amount   := gn_0; -- １２月 内訳合計
            gr_add_total(1).dec_quant_t     := gn_0; -- １２月 数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
            gr_add_total(1).dec_s_cost      := gn_0; -- １２月 標準原価(計)
            gr_add_total(1).dec_calc        := gn_0; -- １２月 品目定価*数量(計)
            gr_add_total(1).dec_minus_flg   := 'N';  -- １２月 数量マイナス値存在フラグ(計算用)
            gr_add_total(1).dec_ht_zero_flg := 'N';  -- １２月 品目定価0値存在フラグ(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
            gr_add_total(1).jan_quant       := gn_0; -- １月 数量
            gr_add_total(1).jan_amount      := gn_0; -- １月 金額
            gr_add_total(1).jan_price       := gn_0; -- １月 品目定価
            gr_add_total(1).jan_to_amount   := gn_0; -- １月 内訳合計
            gr_add_total(1).jan_quant_t     := gn_0; -- １月 数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
            gr_add_total(1).jan_s_cost      := gn_0; -- １月 標準原価(計)
            gr_add_total(1).jan_calc        := gn_0; -- １月 品目定価*数量(計)
            gr_add_total(1).jan_minus_flg   := 'N';  -- １月 数量マイナス値存在フラグ(計算用)
            gr_add_total(1).jan_ht_zero_flg := 'N';  -- １月 品目定価0値存在フラグ(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
            gr_add_total(1).feb_quant       := gn_0; -- ２月 数量
            gr_add_total(1).feb_amount      := gn_0; -- ２月 金額
            gr_add_total(1).feb_price       := gn_0; -- ２月 品目定価
            gr_add_total(1).feb_to_amount   := gn_0; -- ２月 内訳合計
            gr_add_total(1).feb_quant_t     := gn_0; -- ２月 数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
            gr_add_total(1).feb_s_cost      := gn_0; -- ２月 標準原価(計)
            gr_add_total(1).feb_calc        := gn_0; -- ２月 品目定価*数量(計)
            gr_add_total(1).feb_minus_flg   := 'N';  -- ２月 数量マイナス値存在フラグ(計算用)
            gr_add_total(1).feb_ht_zero_flg := 'N';  -- ２月 品目定価0値存在フラグ(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
            gr_add_total(1).mar_quant       := gn_0; -- ３月 数量
            gr_add_total(1).mar_amount      := gn_0; -- ３月 金額
            gr_add_total(1).mar_price       := gn_0; -- ３月 品目定価
            gr_add_total(1).mar_to_amount   := gn_0; -- ３月 内訳合計
            gr_add_total(1).mar_quant_t     := gn_0; -- ３月 数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
            gr_add_total(1).mar_s_cost      := gn_0; -- ３月 標準原価(計)
            gr_add_total(1).mar_calc        := gn_0; -- ３月 品目定価*数量(計)
            gr_add_total(1).mar_minus_flg   := 'N';  -- ３月 数量マイナス値存在フラグ(計算用)
            gr_add_total(1).mar_ht_zero_flg := 'N';  -- ３月 品目定価0値存在フラグ(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
            gr_add_total(1).apr_quant       := gn_0; -- ４月 数量
            gr_add_total(1).apr_amount      := gn_0; -- ４月 金額
            gr_add_total(1).apr_price       := gn_0; -- ４月 品目定価
            gr_add_total(1).apr_to_amount   := gn_0; -- ４月 内訳合計
            gr_add_total(1).apr_quant_t     := gn_0; -- ４月 数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
            gr_add_total(1).apr_s_cost      := gn_0; -- ４月 標準原価(計)
            gr_add_total(1).apr_calc        := gn_0; -- ４月 品目定価*数量(計)
            gr_add_total(1).apr_minus_flg   := 'N';  -- ４月 数量マイナス値存在フラグ(計算用)
            gr_add_total(1).apr_ht_zero_flg := 'N';  -- ４月 品目定価0値存在フラグ(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
            gr_add_total(1).year_quant      := gn_0; -- 年計 数量
            gr_add_total(1).year_amount     := gn_0; -- 年計 金額
            gr_add_total(1).year_price      := gn_0; -- 年計 品目定価
            gr_add_total(1).year_to_amount  := gn_0; -- 年計 内訳合計
            gr_add_total(1).year_quant_t    := gn_0; -- 年計 数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
            gr_add_total(1).year_s_cost     := gn_0; -- 年計 標準原価(計)
            gr_add_total(1).year_calc       := gn_0; -- 年計 品目定価*数量(計)
            gr_add_total(1).year_minus_flg   := 'N'; -- 年計 数量マイナス値存在フラグ(計算用)
            gr_add_total(1).year_ht_zero_flg := 'N'; -- 年計 品目定価0値存在フラグ(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
          END IF;
--
          -- ====================================================
          -- (全拠点)大群計ブレイク
          -- ====================================================
          IF (SUBSTRB(gr_sale_plan(i).gun,1,1) <> lv_lttl_break) THEN
            --------------------------------------------------------
            -- (全拠点)大群計データ出力 
            --------------------------------------------------------
            prc_create_xml_data_st_lt
            (
               iv_label_name     => gv_name_lt                     -- 大群計用タグ名
              ,iv_name           => gv_label_lt                    -- 大群計タイトル
              ,in_may_quant      => gr_add_total(2).may_quant      -- ５月 数量
              ,in_may_amount     => gr_add_total(2).may_amount     -- ５月 金額
              ,in_may_price      => gr_add_total(2).may_price      -- ５月 品目定価
              ,in_may_to_amount  => gr_add_total(2).may_to_amount  -- ５月 内訳合計
              ,in_may_quant_t    => gr_add_total(2).may_quant_t    -- ５月 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
              ,in_may_s_cost     => gr_add_total(2).may_s_cost     -- ５月 標準原価(計算用)
              ,in_may_calc       => gr_add_total(2).may_calc       -- ５月 品目定価*数量(計算用)
              ,in_may_minus_flg   => gr_add_total(2).may_minus_flg   -- ５月 数量マイナス値存在フラグ(計算用)
              ,in_may_ht_zero_flg => gr_add_total(2).may_ht_zero_flg -- ５月 品目定価*数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
              ,in_jun_quant      => gr_add_total(2).jun_quant      -- ６月 数量
              ,in_jun_amount     => gr_add_total(2).jun_amount     -- ６月 金額
              ,in_jun_price      => gr_add_total(2).jun_price      -- ６月 品目定価
              ,in_jun_to_amount  => gr_add_total(2).jun_to_amount  -- ６月 内訳合計
              ,in_jun_quant_t    => gr_add_total(2).jun_quant_t    -- ６月 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
              ,in_jun_s_cost     => gr_add_total(2).jun_s_cost     -- ６月 標準原価(計算用)
              ,in_jun_calc       => gr_add_total(2).jun_calc       -- ６月 品目定価*数量(計算用)
              ,in_jun_minus_flg   => gr_add_total(2).jun_minus_flg   -- ６月 数量マイナス値存在フラグ(計算用)
              ,in_jun_ht_zero_flg => gr_add_total(2).jun_ht_zero_flg -- ６月 品目定価*数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
              ,in_jul_quant      => gr_add_total(2).jul_quant      -- ７月 数量
              ,in_jul_amount     => gr_add_total(2).jul_amount     -- ７月 金額
              ,in_jul_price      => gr_add_total(2).jul_price      -- ７月 品目定価
              ,in_jul_to_amount  => gr_add_total(2).jul_to_amount  -- ７月 内訳合計
              ,in_jul_quant_t    => gr_add_total(2).jul_quant_t    -- ７月 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
              ,in_jul_s_cost     => gr_add_total(2).jul_s_cost     -- ７月 標準原価(計算用)
              ,in_jul_calc       => gr_add_total(2).jul_calc       -- ７月 品目定価*数量(計算用)
              ,in_jul_minus_flg   => gr_add_total(2).jul_minus_flg   -- ７月 数量マイナス値存在フラグ(計算用)
              ,in_jul_ht_zero_flg => gr_add_total(2).jul_ht_zero_flg -- ７月 品目定価*数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
              ,in_aug_quant      => gr_add_total(2).aug_quant      -- ８月 数量
              ,in_aug_amount     => gr_add_total(2).aug_amount     -- ８月 金額
              ,in_aug_price      => gr_add_total(2).aug_price      -- ８月 品目定価
              ,in_aug_to_amount  => gr_add_total(2).aug_to_amount  -- ８月 内訳合計
              ,in_aug_quant_t    => gr_add_total(2).aug_quant_t    -- ８月 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
              ,in_aug_s_cost     => gr_add_total(2).aug_s_cost     -- ８月 標準原価(計算用)
              ,in_aug_calc       => gr_add_total(2).aug_calc       -- ８月 品目定価*数量(計算用)
              ,in_aug_minus_flg   => gr_add_total(2).aug_minus_flg   -- ８月 数量マイナス値存在フラグ(計算用)
              ,in_aug_ht_zero_flg => gr_add_total(2).aug_ht_zero_flg -- ８月 品目定価*数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
              ,in_sep_quant      => gr_add_total(2).sep_quant      -- ９月 数量
              ,in_sep_amount     => gr_add_total(2).sep_amount     -- ９月 金額
              ,in_sep_price      => gr_add_total(2).sep_price      -- ９月 品目定価
              ,in_sep_to_amount  => gr_add_total(2).sep_to_amount  -- ９月 内訳合計
              ,in_sep_quant_t    => gr_add_total(2).sep_quant_t    -- ９月 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
              ,in_sep_s_cost     => gr_add_total(2).sep_s_cost     -- ９月 標準原価(計算用)
              ,in_sep_calc       => gr_add_total(2).sep_calc       -- ９月 品目定価*数量(計算用)
              ,in_sep_minus_flg   => gr_add_total(2).sep_minus_flg   -- ９月 数量マイナス値存在フラグ(計算用)
              ,in_sep_ht_zero_flg => gr_add_total(2).sep_ht_zero_flg -- ９月 品目定価*数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
              ,in_oct_quant      => gr_add_total(2).oct_quant      -- １０月 数量
              ,in_oct_amount     => gr_add_total(2).oct_amount     -- １０月 金額
              ,in_oct_price      => gr_add_total(2).oct_price      -- １０月 品目定価
              ,in_oct_to_amount  => gr_add_total(2).oct_to_amount  -- １０月 内訳合計
              ,in_oct_quant_t    => gr_add_total(2).oct_quant_t    -- １０月 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
              ,in_oct_s_cost     => gr_add_total(2).oct_s_cost     -- １０月 標準原価(計算用)
              ,in_oct_calc       => gr_add_total(2).oct_calc       -- １０月 品目定価*数量(計算用)
              ,in_oct_minus_flg   => gr_add_total(2).oct_minus_flg   -- １０月 数量マイナス値存在フラグ(計算用)
              ,in_oct_ht_zero_flg => gr_add_total(2).oct_ht_zero_flg -- １０月 品目定価*数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
              ,in_nov_quant      => gr_add_total(2).nov_quant      -- １１月 数量
              ,in_nov_amount     => gr_add_total(2).nov_amount     -- １１月 金額
              ,in_nov_price      => gr_add_total(2).nov_price      -- １１月 品目定価
              ,in_nov_to_amount  => gr_add_total(2).nov_to_amount  -- １１月 内訳合計
              ,in_nov_quant_t    => gr_add_total(2).nov_quant_t    -- １１月 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
              ,in_nov_s_cost     => gr_add_total(2).nov_s_cost     -- １１月 標準原価(計算用)
              ,in_nov_calc       => gr_add_total(2).nov_calc       -- １１月 品目定価*数量(計算用)
              ,in_nov_minus_flg   => gr_add_total(2).nov_minus_flg   -- １１月 数量マイナス値存在フラグ(計算用)
              ,in_nov_ht_zero_flg => gr_add_total(2).nov_ht_zero_flg -- １１月 品目定価*数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
              ,in_dec_quant      => gr_add_total(2).dec_quant      -- １２月 数量
              ,in_dec_amount     => gr_add_total(2).dec_amount     -- １２月 金額
              ,in_dec_price      => gr_add_total(2).dec_price      -- １２月 品目定価
              ,in_dec_to_amount  => gr_add_total(2).dec_to_amount  -- １２月 内訳合計
              ,in_dec_quant_t    => gr_add_total(2).dec_quant_t    -- １２月 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
              ,in_dec_s_cost     => gr_add_total(2).dec_s_cost     -- １２月 標準原価(計算用)
              ,in_dec_calc       => gr_add_total(2).dec_calc       -- １２月 品目定価*数量(計算用)
              ,in_dec_minus_flg   => gr_add_total(2).dec_minus_flg   -- １２月 数量マイナス値存在フラグ(計算用)
              ,in_dec_ht_zero_flg => gr_add_total(2).dec_ht_zero_flg -- １２月 品目定価*数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
              ,in_jan_quant      => gr_add_total(2).jan_quant      -- １月 数量
              ,in_jan_amount     => gr_add_total(2).jan_amount     -- １月 金額
              ,in_jan_price      => gr_add_total(2).jan_price      -- １月 品目定価
              ,in_jan_to_amount  => gr_add_total(2).jan_to_amount  -- １月 内訳合計
              ,in_jan_quant_t    => gr_add_total(2).jan_quant_t    -- １月 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
              ,in_jan_s_cost     => gr_add_total(2).jan_s_cost     -- １月 標準原価(計算用)
              ,in_jan_calc       => gr_add_total(2).jan_calc       -- １月 品目定価*数量(計算用)
              ,in_jan_minus_flg   => gr_add_total(2).jan_minus_flg   -- １月 数量マイナス値存在フラグ(計算用)
              ,in_jan_ht_zero_flg => gr_add_total(2).jan_ht_zero_flg -- １月 品目定価*数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
              ,in_feb_quant      => gr_add_total(2).feb_quant      -- ２月 数量
              ,in_feb_amount     => gr_add_total(2).feb_amount     -- ２月 金額
              ,in_feb_price      => gr_add_total(2).feb_price      -- ２月 品目定価
              ,in_feb_to_amount  => gr_add_total(2).feb_to_amount  -- ２月 内訳合計
              ,in_feb_quant_t    => gr_add_total(2).feb_quant_t    -- ２月 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
              ,in_feb_s_cost     => gr_add_total(2).feb_s_cost     -- ２月 標準原価(計算用)
              ,in_feb_calc       => gr_add_total(2).feb_calc       -- ２月 品目定価*数量(計算用)
              ,in_feb_minus_flg   => gr_add_total(2).feb_minus_flg   -- ２月 数量マイナス値存在フラグ(計算用)
              ,in_feb_ht_zero_flg => gr_add_total(2).feb_ht_zero_flg -- ２月 品目定価*数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
              ,in_mar_quant      => gr_add_total(2).mar_quant      -- ３月 数量
              ,in_mar_amount     => gr_add_total(2).mar_amount     -- ３月 金額
              ,in_mar_price      => gr_add_total(2).mar_price      -- ３月 品目定価
              ,in_mar_to_amount  => gr_add_total(2).mar_to_amount  -- ３月 内訳合計
              ,in_mar_quant_t    => gr_add_total(2).mar_quant_t    -- ３月 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
              ,in_mar_s_cost     => gr_add_total(2).mar_s_cost     -- ３月 標準原価(計算用)
              ,in_mar_calc       => gr_add_total(2).mar_calc       -- ３月 品目定価*数量(計算用)
              ,in_mar_minus_flg   => gr_add_total(2).mar_minus_flg   -- ３月 数量マイナス値存在フラグ(計算用)
              ,in_mar_ht_zero_flg => gr_add_total(2).mar_ht_zero_flg -- ３月 品目定価*数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
              ,in_apr_quant      => gr_add_total(2).apr_quant      -- ４月 数量
              ,in_apr_amount     => gr_add_total(2).apr_amount     -- ４月 金額
              ,in_apr_price      => gr_add_total(2).apr_price      -- ４月 品目定価
              ,in_apr_to_amount  => gr_add_total(2).apr_to_amount  -- ４月 内訳合計
              ,in_apr_quant_t    => gr_add_total(2).apr_quant_t    -- ４月 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
              ,in_apr_s_cost     => gr_add_total(2).apr_s_cost     -- ４月 標準原価(計算用)
              ,in_apr_calc       => gr_add_total(2).apr_calc       -- ４月 品目定価*数量(計算用)
              ,in_apr_minus_flg   => gr_add_total(2).apr_minus_flg   -- ４月 数量マイナス値存在フラグ(計算用)
              ,in_apr_ht_zero_flg => gr_add_total(2).apr_ht_zero_flg -- ４月 品目定価*数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
              ,in_year_quant     => gr_add_total(2).year_quant     -- 年計 数量
              ,in_year_amount    => gr_add_total(2).year_amount    -- 年計 金額
              ,in_year_price     => gr_add_total(2).year_price     -- 年計 品目定価
              ,in_year_to_amount => gr_add_total(2).year_to_amount -- 年計 内訳合計
              ,in_year_quant_t   => gr_add_total(2).year_quant_t   -- 年計 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
              ,in_year_s_cost    => gr_add_total(2).year_s_cost    -- 年計 標準原価(計算用)
              ,in_year_calc      => gr_add_total(2).year_calc      -- 年計 品目定価*数量(計算用)
              ,in_year_minus_flg   => gr_add_total(2).year_minus_flg   -- 年計 数量マイナス値存在フラグ(計算用)
              ,in_year_ht_zero_flg => gr_add_total(2).year_ht_zero_flg -- 年計 品目定価*数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
              ,ov_errbuf         => lv_errbuf   -- エラー・メッセージ           --# 固定 #
              ,ov_retcode        => lv_retcode  -- リターン・コード             --# 固定 #
              ,ov_errmsg         => lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
            );
--
            IF (lv_retcode = gv_status_error) THEN
              RAISE global_process_expt;
            END IF;
--
            -- 大群計ブレイクキー更新
            lv_lttl_break := SUBSTRB(gr_sale_plan(i).gun,1,1);
--
            -- 大群計集計用項目初期化
            gr_add_total(2).may_quant       := gn_0; -- ５月 数量
            gr_add_total(2).may_amount      := gn_0; -- ５月 金額
            gr_add_total(2).may_price       := gn_0; -- ５月 品目定価
            gr_add_total(2).may_to_amount   := gn_0; -- ５月 内訳合計
            gr_add_total(2).may_quant_t     := gn_0; -- ５月 数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
            gr_add_total(2).may_s_cost      := gn_0; -- ５月 標準原価(計)
            gr_add_total(2).may_calc        := gn_0; -- ５月 品目定価*数量(計)
            gr_add_total(2).may_minus_flg   := 'N';  -- ５月 数量マイナス値存在フラグ(計算用)
            gr_add_total(2).may_ht_zero_flg := 'N';  -- ５月 品目定価0値存在フラグ(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
            gr_add_total(2).jun_quant       := gn_0; -- ６月 数量
            gr_add_total(2).jun_amount      := gn_0; -- ６月 金額
            gr_add_total(2).jun_price       := gn_0; -- ６月 品目定価
            gr_add_total(2).jun_to_amount   := gn_0; -- ６月 内訳合計
            gr_add_total(2).jun_quant_t     := gn_0; -- ６月 数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
            gr_add_total(2).jun_s_cost      := gn_0; -- ６月 標準原価(計)
            gr_add_total(2).jun_calc        := gn_0; -- ６月 品目定価*数量(計)
            gr_add_total(2).jun_minus_flg   := 'N';  -- ６月 数量マイナス値存在フラグ(計算用)
            gr_add_total(2).jun_ht_zero_flg := 'N';  -- ６月 品目定価0値存在フラグ(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
            gr_add_total(2).jul_quant       := gn_0; -- ７月 数量
            gr_add_total(2).jul_amount      := gn_0; -- ７月 金額
            gr_add_total(2).jul_price       := gn_0; -- ７月 品目定価
            gr_add_total(2).jul_to_amount   := gn_0; -- ７月 内訳合計
            gr_add_total(2).jul_quant_t     := gn_0; -- ７月 数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
            gr_add_total(2).jul_s_cost      := gn_0; -- ７月 標準原価(計)
            gr_add_total(2).jul_calc        := gn_0; -- ７月 品目定価*数量(計)
            gr_add_total(2).jul_minus_flg   := 'N';  -- ７月 数量マイナス値存在フラグ(計算用)
            gr_add_total(2).jul_ht_zero_flg := 'N';  -- ７月 品目定価0値存在フラグ(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
            gr_add_total(2).aug_quant       := gn_0; -- ８月 数量
            gr_add_total(2).aug_amount      := gn_0; -- ８月 金額
            gr_add_total(2).aug_price       := gn_0; -- ８月 品目定価
            gr_add_total(2).aug_to_amount   := gn_0; -- ８月 内訳合計
            gr_add_total(2).aug_quant_t     := gn_0; -- ８月 数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
            gr_add_total(2).aug_s_cost      := gn_0; -- ８月 標準原価(計)
            gr_add_total(2).aug_calc        := gn_0; -- ８月 品目定価*数量(計)
            gr_add_total(2).aug_minus_flg   := 'N';  -- ８月 数量マイナス値存在フラグ(計算用)
            gr_add_total(2).aug_ht_zero_flg := 'N';  -- ８月 品目定価0値存在フラグ(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
            gr_add_total(2).sep_quant       := gn_0; -- ９月 数量
            gr_add_total(2).sep_amount      := gn_0; -- ９月 金額
            gr_add_total(2).sep_price       := gn_0; -- ９月 品目定価
            gr_add_total(2).sep_to_amount   := gn_0; -- ９月 内訳合計
            gr_add_total(2).sep_quant_t     := gn_0; -- ９月 数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
            gr_add_total(2).sep_s_cost      := gn_0; -- ９月 標準原価(計)
            gr_add_total(2).sep_calc        := gn_0; -- ９月 品目定価*数量(計)
            gr_add_total(2).sep_minus_flg   := 'N';  -- ９月 数量マイナス値存在フラグ(計算用)
            gr_add_total(2).sep_ht_zero_flg := 'N';  -- ９月 品目定価0値存在フラグ(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
            gr_add_total(2).oct_quant       := gn_0; -- １０月 数量
            gr_add_total(2).oct_amount      := gn_0; -- １０月 金額
            gr_add_total(2).oct_price       := gn_0; -- １０月 品目定価
            gr_add_total(2).oct_to_amount   := gn_0; -- １０月 内訳合計
            gr_add_total(2).oct_quant_t     := gn_0; -- １０月 数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
            gr_add_total(2).oct_s_cost      := gn_0; -- １０月 標準原価(計)
            gr_add_total(2).oct_calc        := gn_0; -- １０月 品目定価*数量(計)
            gr_add_total(2).oct_minus_flg   := 'N';  -- １０月 数量マイナス値存在フラグ(計算用)
            gr_add_total(2).oct_ht_zero_flg := 'N';  -- １０月 品目定価0値存在フラグ(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
            gr_add_total(2).nov_quant       := gn_0; -- １１月 数量
            gr_add_total(2).nov_amount      := gn_0; -- １１月 金額
            gr_add_total(2).nov_price       := gn_0; -- １１月 品目定価
            gr_add_total(2).nov_to_amount   := gn_0; -- １１月 内訳合計
            gr_add_total(2).nov_quant_t     := gn_0; -- １１月 数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
            gr_add_total(2).nov_s_cost      := gn_0; -- １１月 標準原価(計)
            gr_add_total(2).nov_calc        := gn_0; -- １１月 品目定価*数量(計)
            gr_add_total(2).nov_minus_flg   := 'N';  -- １１月 数量マイナス値存在フラグ(計算用)
            gr_add_total(2).nov_ht_zero_flg := 'N';  -- １１月 品目定価0値存在フラグ(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
            gr_add_total(2).dec_quant       := gn_0; -- １２月 数量
            gr_add_total(2).dec_amount      := gn_0; -- １２月 金額
            gr_add_total(2).dec_price       := gn_0; -- １２月 品目定価
            gr_add_total(2).dec_to_amount   := gn_0; -- １２月 内訳合計
            gr_add_total(2).dec_quant_t     := gn_0; -- １２月 数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
            gr_add_total(2).dec_s_cost      := gn_0; -- １２月 標準原価(計)
            gr_add_total(2).dec_calc        := gn_0; -- １２月 品目定価*数量(計)
            gr_add_total(2).dec_minus_flg   := 'N';  -- １２月 数量マイナス値存在フラグ(計算用)
            gr_add_total(2).dec_ht_zero_flg := 'N';  -- １２月 品目定価0値存在フラグ(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
            gr_add_total(2).jan_quant       := gn_0; -- １月 数量
            gr_add_total(2).jan_amount      := gn_0; -- １月 金額
            gr_add_total(2).jan_price       := gn_0; -- １月 品目定価
            gr_add_total(2).jan_to_amount   := gn_0; -- １月 内訳合計
            gr_add_total(2).jan_quant_t     := gn_0; -- １月 数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
            gr_add_total(2).jan_s_cost      := gn_0; -- １月 標準原価(計)
            gr_add_total(2).jan_calc        := gn_0; -- １月 品目定価*数量(計)
            gr_add_total(2).jan_minus_flg   := 'N';  -- １月 数量マイナス値存在フラグ(計算用)
            gr_add_total(2).jan_ht_zero_flg := 'N';  -- １月 品目定価0値存在フラグ(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
            gr_add_total(2).feb_quant       := gn_0; -- ２月 数量
            gr_add_total(2).feb_amount      := gn_0; -- ２月 金額
            gr_add_total(2).feb_price       := gn_0; -- ２月 品目定価
            gr_add_total(2).feb_to_amount   := gn_0; -- ２月 内訳合計
            gr_add_total(2).feb_quant_t     := gn_0; -- ２月 数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
            gr_add_total(2).feb_s_cost      := gn_0; -- ２月 標準原価(計)
            gr_add_total(2).feb_calc        := gn_0; -- ２月 品目定価*数量(計)
            gr_add_total(2).feb_minus_flg   := 'N';  -- ２月 数量マイナス値存在フラグ(計算用)
            gr_add_total(2).feb_ht_zero_flg := 'N';  -- ２月 品目定価0値存在フラグ(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
            gr_add_total(2).mar_quant       := gn_0; -- ３月 数量
            gr_add_total(2).mar_amount      := gn_0; -- ３月 金額
            gr_add_total(2).mar_price       := gn_0; -- ３月 品目定価
            gr_add_total(2).mar_to_amount   := gn_0; -- ３月 内訳合計
            gr_add_total(2).mar_quant_t     := gn_0; -- ３月 数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
            gr_add_total(2).mar_s_cost      := gn_0; -- ３月 標準原価(計)
            gr_add_total(2).mar_calc        := gn_0; -- ３月 品目定価*数量(計)
            gr_add_total(2).mar_minus_flg   := 'N';  -- ３月 数量マイナス値存在フラグ(計算用)
            gr_add_total(2).mar_ht_zero_flg := 'N';  -- ３月 品目定価0値存在フラグ(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
            gr_add_total(2).apr_quant       := gn_0; -- ４月 数量
            gr_add_total(2).apr_amount      := gn_0; -- ４月 金額
            gr_add_total(2).apr_price       := gn_0; -- ４月 品目定価
            gr_add_total(2).apr_to_amount   := gn_0; -- ４月 内訳合計
            gr_add_total(2).apr_quant_t     := gn_0; -- ４月 数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
            gr_add_total(2).apr_s_cost      := gn_0; -- ４月 標準原価(計)
            gr_add_total(2).apr_calc        := gn_0; -- ４月 品目定価*数量(計)
            gr_add_total(2).apr_minus_flg   := 'N';  -- ４月 数量マイナス値存在フラグ(計算用)
            gr_add_total(2).apr_ht_zero_flg := 'N';  -- ４月 品目定価0値存在フラグ(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
            gr_add_total(2).year_quant      := gn_0; -- 年計 数量
            gr_add_total(2).year_amount     := gn_0; -- 年計 金額
            gr_add_total(2).year_price      := gn_0; -- 年計 品目定価
            gr_add_total(2).year_to_amount  := gn_0; -- 年計 内訳合計
            gr_add_total(2).year_quant_t    := gn_0; -- 年計 数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
            gr_add_total(2).year_s_cost     := gn_0; -- 年計 標準原価(計)
            gr_add_total(2).year_calc       := gn_0; -- 年計 品目定価*数量(計)
            gr_add_total(2).year_minus_flg   := 'N'; -- 年計 数量マイナス値存在フラグ(計算用)
            gr_add_total(2).year_ht_zero_flg := 'N'; -- 年計 品目定価0値存在フラグ(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
          END IF;
--
          -- -----------------------------------------------------
          -- (全拠点)群コード終了Ｇタグ出力
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_gun';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
          -- -----------------------------------------------------
          -- (全拠点)群コード終了LＧタグ出力
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_gun_info';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
          -- -----------------------------------------------------
          -- (全拠点)群コード開始LＧタグ出力
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_gun_info';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
          -- -----------------------------------------------------
          -- (全拠点)群コード開始Ｇタグ出力
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'g_gun';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
          -- -----------------------------------------------------
          -- (全拠点)品目開始ＬＧタグ出力
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_dtl_info';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
          --  ブレイクキー更新
          lv_gun_break  := gr_sale_plan(i).gun;  -- 群コード
          lv_dtl_break  := lv_break_init;        -- 品目コード
--
          -- 年計初期化
          ln_year_quant_sum  := gn_0;            -- 数量
          ln_year_amount_sum := gn_0;            -- 金額
          ln_year_to_am_sum  := gn_0;            -- 内訳合計
          ln_year_price_sum  := gn_0;            -- 品目定価
--
          -- XML出力フラグ初期化
          <<xml_out_loop>>
          FOR n IN 1..12 LOOP
            gr_xml_out(n).out_fg   := lv_no;
          END LOOP xml_out_loop;
--
        END IF;
--
        -- ====================================================
        -- (全拠点)品目コードブレイク
        -- ====================================================
        -- 最初のレコードの時と、品目が切り替わったとき表示
        IF ((lv_dtl_break = lv_break_init)
          OR (lv_dtl_break <> gr_sale_plan(i).item_no)) THEN
          -- 最初のレコードでは、終了タグは表示しない。
          IF (lv_dtl_break <> lv_break_init) THEN
            ---------------------------------------------------------------
            -- (全拠点)各月抽出データが存在しない場合、0表示にてXML出力  --
            ---------------------------------------------------------------
            <<xml_out_0_loop>>
            FOR m IN 1..12 LOOP
              IF (gr_xml_out(m).out_fg = lv_no) THEN
                prc_create_xml_data_dtl_n
                  (
                    iv_label_name     => gr_xml_out(m).tag_name                      -- 出力タグ名
                   ,ov_errbuf         => lv_errbuf   -- エラー・メッセージ           --# 固定 #
                   ,ov_retcode        => lv_retcode  -- リターン・コード             --# 固定 #
                   ,ov_errmsg         => lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
                  );
                IF (lv_retcode = gv_status_error) THEN
                  RAISE global_process_expt;
                END IF;
              END IF;
            END LOOP xml_out_0_loop;
--
            -- -----------------------------------------------------
            -- (全拠点)年計 数量データ
            -- -----------------------------------------------------
            gl_xml_idx := gt_xml_data_table.COUNT + 1;
            gt_xml_data_table(gl_xml_idx).tag_name  := 'year_quant';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
            gt_xml_data_table(gl_xml_idx).tag_value := ln_year_quant_sum;
--
            -- -----------------------------------------------------
            -- (全拠点)年計 金額データ
            -- -----------------------------------------------------
            gl_xml_idx := gt_xml_data_table.COUNT + 1;
            gt_xml_data_table(gl_xml_idx).tag_name  := 'year_amount';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
            gt_xml_data_table(gl_xml_idx).tag_value := ROUND(ln_year_amount_sum / 1000,0);
--
            -- -----------------------------------------------------
            -- (全拠点)年計 粗利率データ
            -- -----------------------------------------------------
            gl_xml_idx := gt_xml_data_table.COUNT + 1;
            gt_xml_data_table(gl_xml_idx).tag_name  := 'year_arari_par';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
--
            --------------------------------------
            -- (全拠点)粗利計算 (金額－内訳合計＊数量)  --
            --------------------------------------
            ln_arari := ln_year_amount_sum - ln_year_to_am_sum * ln_year_quant_sum;
            -- ０除算回避判定
            IF (ln_year_amount_sum <> gn_0) THEN
            -- 値が[0]出なければ計算
            gt_xml_data_table(gl_xml_idx).tag_value := 
                      ROUND((ln_arari / ln_year_amount_sum * 100),2);
            ELSE
              -- 値が[0]の場合は、一律[0]設定
              gt_xml_data_table(gl_xml_idx).tag_value := gn_0;
            END IF;
--
            -- -----------------------------------------------------
            -- (全拠点)年計 掛率データ
            -- -----------------------------------------------------
            gl_xml_idx := gt_xml_data_table.COUNT + 1;
            gt_xml_data_table(gl_xml_idx).tag_name  := 'year_kake_par';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
--
            --------------------------------------
            -- ０除算判定項目へ判定値を挿入     --
            --------------------------------------
            ln_chk_0 := ln_year_price_sum * ln_year_quant_sum;
            -- ０除算回避判定
            IF (ln_chk_0 <> gn_0) THEN
            -- 値が[0]出なければ計算
            ln_kake_par := ROUND((ln_year_amount_sum * 100) / ln_chk_0,2);
            ELSE
              -- 値が[0]の場合は、一律[0]設定
              ln_kake_par := gn_0;
            END IF;
--
            -- 品目定価 = ０か、計算結果がマイナスの場合、固定値[70.00]を登録
            IF ((ln_year_price_sum = 0)
              OR (ln_kake_par < 0)) THEN
              ln_kake_par := gn_kotei_70; -- 固定値[70.00]
            END IF;
            gt_xml_data_table(gl_xml_idx).tag_value := ln_kake_par;
--
            -- 各集計項目へデータ挿入
            <<add_total_loop>>
            FOR r IN 1..5 LOOP                     -- 小群計/大群計/拠点計/商品区分計/総合計
              gr_add_total(r).year_quant     :=
                 gr_add_total(r).year_quant     + ln_year_quant_sum;        -- 数量
              gr_add_total(r).year_amount    :=
                 gr_add_total(r).year_amount    + ln_year_amount_sum;       -- 金額
              gr_add_total(r).year_price     :=
                 gr_add_total(r).year_price     + ln_year_price_sum;        -- 品目定価
              gr_add_total(r).year_to_amount :=
                 gr_add_total(r).year_to_amount + ln_year_to_am_sum;        -- 内訳合計
              gr_add_total(r).year_quant_t   :=
                 gr_add_total(r).year_quant_t   + ln_year_quant_sum;        -- 数量(計)
            END LOOP add_total_loop;
--
            -- -----------------------------------------------------
            -- (全拠点)品目終了Ｇタグ出力
            -- -----------------------------------------------------
            gl_xml_idx := gt_xml_data_table.COUNT + 1;
            gt_xml_data_table(gl_xml_idx).tag_name  := '/g_dtl';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
            -- 年計初期化
            ln_year_quant_sum  := gn_0;           -- 数量
            ln_year_amount_sum := gn_0;           -- 金額
            ln_year_to_am_sum  := gn_0;           -- 内訳合計
            ln_year_price_sum  := gn_0;           -- 品目定価
--
          END IF;
          -- -----------------------------------------------------
          -- (全拠点)品目開始Ｇタグ出力
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'g_dtl';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
          -- -----------------------------------------------------
          -- (全拠点)群コードデータ
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'gun_code';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          gt_xml_data_table(gl_xml_idx).tag_value := gr_sale_plan(i).gun;
--
          -- -----------------------------------------------------
          -- (全拠点)品目(コード)データ
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'item_code';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          gt_xml_data_table(gl_xml_idx).tag_value := gr_sale_plan(i).item_no;
--
          -- -----------------------------------------------------
          -- (全拠点)品目(名称)データ
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'item_name';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          gt_xml_data_table(gl_xml_idx).tag_value := gr_sale_plan(i).item_short_name;
--
          -- XML出力フラグ初期化
          <<xml_out_loop>>
          FOR n IN 1..12 LOOP
            gr_xml_out(n).out_fg   := lv_no;
          END LOOP xml_out_loop;
--
        END IF;
--
        -- ====================================================
        -- (全拠点)明細データ出力
        -- ====================================================
        ------------------------------------
        -- (全拠点)抽出データが５月の場合 --
        ------------------------------------
        IF (gr_sale_plan(i).month = lv_may_name) THEN
          -- 抽出データ 有
          prc_create_xml_data_dtl
            (
              iv_label_name     => gv_name_may                             -- 出力タグ名
             ,in_quant          => TO_NUMBER(gr_sale_plan(i).quant)        -- 数量
             ,in_case_quant     => TO_NUMBER(gr_sale_plan(i).case_quant)   -- 入数
             ,in_amount         => TO_NUMBER(gr_sale_plan(i).amount)       -- 金額
             ,in_total_amount   => TO_NUMBER(gr_sale_plan(i).total_amount) -- 内訳合計
             ,iv_price_st       => gr_sale_plan(i).price_st                -- 定価適用開始日
             ,in_n_amount       => TO_NUMBER(gr_sale_plan(i).n_amount)     -- 新定価
             ,in_o_amount       => TO_NUMBER(gr_sale_plan(i).o_amount)     -- 旧定価
             ,on_quant          => ln_quant                                -- 年計用 数量
             ,on_price          => ln_price                                -- 年計用 品目定価
             ,ov_errbuf         => lv_errbuf   -- エラー・メッセージ           --# 固定 #
             ,ov_retcode        => lv_retcode  -- リターン・コード             --# 固定 #
             ,ov_errmsg         => lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
              );
          IF (lv_retcode = gv_status_error) THEN
            RAISE global_process_expt;
          END IF;
--
          -- 年計集計項目計算
          ln_year_quant_sum  := ln_year_quant_sum  + ln_quant;             -- 数量
          ln_year_amount_sum := ln_year_amount_sum + TO_NUMBER(gr_sale_plan(i).amount);
                                                                           -- 金額
-- 2009/04/16 v1.6 T.Yoshimoto Mod Start 本番#1410
/*
          ln_year_to_am_sum  := ln_year_to_am_sum  + TO_NUMBER(gr_sale_plan(i).total_amount);
                                                                           -- 内訳合計
          ln_year_price_sum  := ln_year_price_sum  + ln_price;             -- 品目定価
*/
          ln_year_to_am_sum  := TO_NUMBER(gr_sale_plan(i).total_amount);   -- 内訳合計
          ln_year_price_sum  := ln_price;                                  -- 品目定価
-- 2009/04/16 v1.6 T.Yoshimoto Mod End 本番#1410
--
          -- 各集計項目へデータ挿入
          <<add_total_loop_5>>
          FOR r IN 1..5 LOOP                     -- 小群計/大群計/拠点計/商品区分計/総合計
            gr_add_total(r).may_quant     :=
               gr_add_total(r).may_quant     + TO_NUMBER(gr_sale_plan(i).quant);        -- 数量
            gr_add_total(r).may_amount    :=
               gr_add_total(r).may_amount    + TO_NUMBER(gr_sale_plan(i).amount);       -- 金額
            gr_add_total(r).may_price     :=
               gr_add_total(r).may_price     + ln_price;                                -- 品目定価
            gr_add_total(r).may_to_amount :=
               gr_add_total(r).may_to_amount + TO_NUMBER(gr_sale_plan(i).total_amount); -- 内訳合計
            gr_add_total(r).may_quant_t   :=
               gr_add_total(r).may_quant_t   + ln_quant;                                -- 数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
            gr_add_total(r).may_s_cost    :=                                            -- 標準原価(計)
                gr_add_total(r).may_s_cost   + (TO_NUMBER(gr_sale_plan(i).total_amount) * TO_NUMBER(gr_sale_plan(i).quant));
            gr_add_total(r).may_calc      :=                                            -- 品目定価*数量(計)
                gr_add_total(r).may_calc     + (ln_price * TO_NUMBER(gr_sale_plan(i).quant));
--
            gr_add_total(r).year_s_cost    :=                                            -- 年間.標準原価(計)
                gr_add_total(r).year_s_cost   + (TO_NUMBER(gr_sale_plan(i).total_amount) * TO_NUMBER(gr_sale_plan(i).quant));
            gr_add_total(r).year_calc      :=                                             -- 年間.品目定価*数量(計)
                gr_add_total(r).year_calc     + (ln_price * TO_NUMBER(gr_sale_plan(i).quant));
--
            -- 数量がマイナスの場合(月間での存在チェック)
            IF ( TO_NUMBER(gr_sale_plan(i).quant) < 0 ) THEN
              gr_add_total(r).may_minus_flg := 'Y';
            END IF;
--
            -- 品目定価が0の場合(月間での存在チェック)
            IF ( ln_price = 0 ) THEN
              gr_add_total(r).may_ht_zero_flg := 'Y';
            END IF;
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
          END LOOP add_total_loop_5;
--
          -- XML出力フラグ更新
          gr_xml_out(1).tag_name := gv_name_may;
          gr_xml_out(1).out_fg   := lv_yes;
        ELSE
          -- XML出力フラグ更新
          gr_xml_out(1).tag_name := gv_name_may;
        END IF;
--
        ------------------------------------
        -- (全拠点)抽出データが６月の場合 --
        ------------------------------------
        IF (gr_sale_plan(i).month = lv_jun_name) THEN
          -- 抽出データ 有
          prc_create_xml_data_dtl
            (
              iv_label_name     => gv_name_jun                             -- 出力タグ名
             ,in_quant          => TO_NUMBER(gr_sale_plan(i).quant)        -- 数量
             ,in_case_quant     => TO_NUMBER(gr_sale_plan(i).case_quant)   -- 入数
             ,in_amount         => TO_NUMBER(gr_sale_plan(i).amount)       -- 金額
             ,in_total_amount   => TO_NUMBER(gr_sale_plan(i).total_amount) -- 内訳合計
             ,iv_price_st       => gr_sale_plan(i).price_st                -- 定価適用開始日
             ,in_n_amount       => TO_NUMBER(gr_sale_plan(i).n_amount)     -- 新定価
             ,in_o_amount       => TO_NUMBER(gr_sale_plan(i).o_amount)     -- 旧定価
             ,on_quant          => ln_quant                                -- 年計用 数量
             ,on_price          => ln_price                                -- 年計用 品目定価
             ,ov_errbuf         => lv_errbuf   -- エラー・メッセージ           --# 固定 #
             ,ov_retcode        => lv_retcode  -- リターン・コード             --# 固定 #
             ,ov_errmsg         => lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
            );
          IF (lv_retcode = gv_status_error) THEN
            RAISE global_process_expt;
          END IF;
--
          -- 年計集計項目計算
          ln_year_quant_sum  := ln_year_quant_sum  + ln_quant;             -- 数量
          ln_year_amount_sum := ln_year_amount_sum + TO_NUMBER(gr_sale_plan(i).amount);
                                                                           -- 金額
-- 2009/04/16 v1.6 T.Yoshimoto Mod Start 本番#1410
/*
          ln_year_to_am_sum  := ln_year_to_am_sum  + TO_NUMBER(gr_sale_plan(i).total_amount);
                                                                             -- 内訳合計
          ln_year_price_sum  := ln_year_price_sum  + ln_price;             -- 品目定価
*/
          ln_year_to_am_sum  := TO_NUMBER(gr_sale_plan(i).total_amount);     -- 内訳合計
          ln_year_price_sum  := ln_price;                                    -- 品目定価
-- 2009/04/16 v1.6 T.Yoshimoto Mod End 本番#1410
--
          -- 各集計項目へデータ挿入
          <<add_total_loop_6>>
          FOR r IN 1..5 LOOP                     -- 小群計/大群計/拠点計/商品区分計/総合計
            gr_add_total(r).jun_quant     :=
               gr_add_total(r).jun_quant     + TO_NUMBER(gr_sale_plan(i).quant);        -- 数量
            gr_add_total(r).jun_amount    :=
               gr_add_total(r).jun_amount    + TO_NUMBER(gr_sale_plan(i).amount);       -- 金額
            gr_add_total(r).jun_price     :=
               gr_add_total(r).jun_price     + ln_price;                                -- 品目定価
            gr_add_total(r).jun_to_amount :=
               gr_add_total(r).jun_to_amount + TO_NUMBER(gr_sale_plan(i).total_amount); -- 内訳合計
            gr_add_total(r).jun_quant_t   :=
               gr_add_total(r).jun_quant_t   + ln_quant;                                -- 数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
            gr_add_total(r).jun_s_cost    :=                                            -- 標準原価(計)
                gr_add_total(r).jun_s_cost   + (TO_NUMBER(gr_sale_plan(i).total_amount) * TO_NUMBER(gr_sale_plan(i).quant));
            gr_add_total(r).jun_calc      :=                                            -- 品目定価*数量(計)
                gr_add_total(r).jun_calc     + (ln_price * TO_NUMBER(gr_sale_plan(i).quant));
--
            gr_add_total(r).year_s_cost    :=                                            -- 年間.標準原価(計)
                gr_add_total(r).year_s_cost   + (TO_NUMBER(gr_sale_plan(i).total_amount) * TO_NUMBER(gr_sale_plan(i).quant));
            gr_add_total(r).year_calc      :=                                             -- 年間.品目定価*数量(計)
                gr_add_total(r).year_calc     + (ln_price * TO_NUMBER(gr_sale_plan(i).quant));
--
            -- 数量がマイナスの場合(月間での存在チェック)
            IF ( TO_NUMBER(gr_sale_plan(i).quant) < 0 ) THEN
              gr_add_total(r).jun_minus_flg := 'Y';
            END IF;
--
            -- 品目定価が0の場合(月間での存在チェック)
            IF ( ln_price = 0 ) THEN
              gr_add_total(r).jun_ht_zero_flg := 'Y';
            END IF;
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
          END LOOP add_total_loop_6;
--
          -- XML出力フラグ更新
          gr_xml_out(2).tag_name := gv_name_jun;
          gr_xml_out(2).out_fg   := lv_yes;
        ELSE
          -- XML出力フラグ更新
          gr_xml_out(2).tag_name := gv_name_jun;
        END IF;
--
        ------------------------------------
        -- (全拠点)抽出データが７月の場合 --
        ------------------------------------
        IF (gr_sale_plan(i).month = lv_jul_name) THEN
          -- 抽出データ 有
          prc_create_xml_data_dtl
            (
              iv_label_name     => gv_name_jul                             -- 出力タグ名
             ,in_quant          => TO_NUMBER(gr_sale_plan(i).quant)        -- 数量
             ,in_case_quant     => TO_NUMBER(gr_sale_plan(i).case_quant)   -- 入数
             ,in_amount         => TO_NUMBER(gr_sale_plan(i).amount)       -- 金額
             ,in_total_amount   => TO_NUMBER(gr_sale_plan(i).total_amount) -- 内訳合計
             ,iv_price_st       => gr_sale_plan(i).price_st                -- 定価適用開始日
             ,in_n_amount       => TO_NUMBER(gr_sale_plan(i).n_amount)     -- 新定価
             ,in_o_amount       => TO_NUMBER(gr_sale_plan(i).o_amount)     -- 旧定価
             ,on_quant          => ln_quant                                -- 年計用 数量
             ,on_price          => ln_price                                -- 年計用 品目定価
             ,ov_errbuf         => lv_errbuf   -- エラー・メッセージ           --# 固定 #
             ,ov_retcode        => lv_retcode  -- リターン・コード             --# 固定 #
             ,ov_errmsg         => lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
            );
          IF (lv_retcode = gv_status_error) THEN
            RAISE global_process_expt;
          END IF;
--
          -- 年計集計項目計算
          ln_year_quant_sum  := ln_year_quant_sum  + ln_quant;             -- 数量
          ln_year_amount_sum := ln_year_amount_sum + TO_NUMBER(gr_sale_plan(i).amount);
                                                                           -- 金額
-- 2009/04/16 v1.6 T.Yoshimoto Mod Start 本番#1410
/*
          ln_year_to_am_sum  := ln_year_to_am_sum  + TO_NUMBER(gr_sale_plan(i).total_amount);
                                                                           -- 内訳合計
          ln_year_price_sum  := ln_year_price_sum  + ln_price;             -- 品目定価
*/
          ln_year_to_am_sum  := TO_NUMBER(gr_sale_plan(i).total_amount);   -- 内訳合計
          ln_year_price_sum  := ln_price;                                  -- 品目定価
-- 2009/04/16 v1.6 T.Yoshimoto Mod End 本番#1410
--
          -- 各集計項目へデータ挿入
          <<add_total_loop_7>>
          FOR r IN 1..5 LOOP                     -- 小群計/大群計/拠点計/商品区分計/総合計
            gr_add_total(r).jul_quant     :=
               gr_add_total(r).jul_quant     + TO_NUMBER(gr_sale_plan(i).quant);        -- 数量
            gr_add_total(r).jul_amount    :=
               gr_add_total(r).jul_amount    + TO_NUMBER(gr_sale_plan(i).amount);       -- 金額
            gr_add_total(r).jul_price     :=
               gr_add_total(r).jul_price     + ln_price;                                -- 品目定価
            gr_add_total(r).jul_to_amount :=
               gr_add_total(r).jul_to_amount + TO_NUMBER(gr_sale_plan(i).total_amount); -- 内訳合計
            gr_add_total(r).jul_quant_t   :=
               gr_add_total(r).jul_quant_t   + ln_quant;                                -- 数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
            gr_add_total(r).jul_s_cost    :=                                            -- 標準原価(計)
                gr_add_total(r).jul_s_cost   + (TO_NUMBER(gr_sale_plan(i).total_amount) * TO_NUMBER(gr_sale_plan(i).quant));
            gr_add_total(r).jul_calc      :=                                            -- 品目定価*数量(計)
                gr_add_total(r).jul_calc     + (ln_price * TO_NUMBER(gr_sale_plan(i).quant));
--
            gr_add_total(r).year_s_cost    :=                                            -- 年間.標準原価(計)
                gr_add_total(r).year_s_cost   + (TO_NUMBER(gr_sale_plan(i).total_amount) * TO_NUMBER(gr_sale_plan(i).quant));
            gr_add_total(r).year_calc      :=                                             -- 年間.品目定価*数量(計)
                gr_add_total(r).year_calc     + (ln_price * TO_NUMBER(gr_sale_plan(i).quant));
--
            -- 数量がマイナスの場合(月間での存在チェック)
            IF ( TO_NUMBER(gr_sale_plan(i).quant) < 0 ) THEN
              gr_add_total(r).jul_minus_flg := 'Y';
            END IF;
--
            -- 品目定価が0の場合(月間での存在チェック)
            IF ( ln_price = 0 ) THEN
              gr_add_total(r).jul_ht_zero_flg := 'Y';
            END IF;
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
          END LOOP add_total_loop_7;
--
          -- XML出力フラグ更新
          gr_xml_out(3).tag_name := gv_name_jul;
          gr_xml_out(3).out_fg   := lv_yes;
        ELSE
          -- XML出力フラグ更新
          gr_xml_out(3).tag_name := gv_name_jul;
        END IF;
--
        ------------------------------------
        -- (全拠点)抽出データが８月の場合 --
        ------------------------------------
        IF (gr_sale_plan(i).month = lv_aug_name) THEN
          -- 抽出データ 有
          prc_create_xml_data_dtl
            (
              iv_label_name     => gv_name_aug                             -- 出力タグ名
             ,in_quant          => TO_NUMBER(gr_sale_plan(i).quant)        -- 数量
             ,in_case_quant     => TO_NUMBER(gr_sale_plan(i).case_quant)   -- 入数
             ,in_amount         => TO_NUMBER(gr_sale_plan(i).amount)       -- 金額
             ,in_total_amount   => TO_NUMBER(gr_sale_plan(i).total_amount) -- 内訳合計
             ,iv_price_st       => gr_sale_plan(i).price_st                -- 定価適用開始日
             ,in_n_amount       => TO_NUMBER(gr_sale_plan(i).n_amount)     -- 新定価
             ,in_o_amount       => TO_NUMBER(gr_sale_plan(i).o_amount)     -- 旧定価
             ,on_quant          => ln_quant                                -- 年計用 数量
             ,on_price          => ln_price                                -- 年計用 品目定価
             ,ov_errbuf         => lv_errbuf   -- エラー・メッセージ           --# 固定 #
             ,ov_retcode        => lv_retcode  -- リターン・コード             --# 固定 #
             ,ov_errmsg         => lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
            );
          IF (lv_retcode = gv_status_error) THEN
            RAISE global_process_expt;
          END IF;
--
          -- 年計集計項目計算
          ln_year_quant_sum  := ln_year_quant_sum  + ln_quant;             -- 数量
          ln_year_amount_sum := ln_year_amount_sum + TO_NUMBER(gr_sale_plan(i).amount);
                                                                           -- 金額
-- 2009/04/16 v1.6 T.Yoshimoto Mod Start 本番#1410
/*
          ln_year_to_am_sum  := ln_year_to_am_sum  + TO_NUMBER(gr_sale_plan(i).total_amount);
                                                                           -- 内訳合計
          ln_year_price_sum  := ln_year_price_sum  + ln_price;             -- 品目定価
*/
          ln_year_to_am_sum  := TO_NUMBER(gr_sale_plan(i).total_amount);   -- 内訳合計
          ln_year_price_sum  := ln_price;                                  -- 品目定価
-- 2009/04/16 v1.6 T.Yoshimoto Mod End 本番#1410
--
          -- 各集計項目へデータ挿入
          <<add_total_loop_8>>
          FOR r IN 1..5 LOOP                     -- 小群計/大群計/拠点計/商品区分計/総合計
            gr_add_total(r).aug_quant     :=
               gr_add_total(r).aug_quant     + TO_NUMBER(gr_sale_plan(i).quant);        -- 数量
            gr_add_total(r).aug_amount    :=
               gr_add_total(r).aug_amount    + TO_NUMBER(gr_sale_plan(i).amount);       -- 金額
            gr_add_total(r).aug_price     :=
               gr_add_total(r).aug_price     + ln_price;                                -- 品目定価
            gr_add_total(r).aug_to_amount :=
               gr_add_total(r).aug_to_amount + TO_NUMBER(gr_sale_plan(i).total_amount); -- 内訳合計
            gr_add_total(r).aug_quant_t   :=
               gr_add_total(r).aug_quant_t   + ln_quant;                                -- 数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
            gr_add_total(r).aug_s_cost    :=                                            -- 標準原価(計)
                gr_add_total(r).aug_s_cost   + (TO_NUMBER(gr_sale_plan(i).total_amount) * TO_NUMBER(gr_sale_plan(i).quant));
            gr_add_total(r).aug_calc      :=                                            -- 品目定価*数量(計)
                gr_add_total(r).aug_calc     + (ln_price * TO_NUMBER(gr_sale_plan(i).quant));
--
            gr_add_total(r).year_s_cost    :=                                            -- 年間.標準原価(計)
                gr_add_total(r).year_s_cost   + (TO_NUMBER(gr_sale_plan(i).total_amount) * TO_NUMBER(gr_sale_plan(i).quant));
            gr_add_total(r).year_calc      :=                                             -- 年間.品目定価*数量(計)
                gr_add_total(r).year_calc     + (ln_price * TO_NUMBER(gr_sale_plan(i).quant));
--
            -- 数量がマイナスの場合(月間での存在チェック)
            IF ( TO_NUMBER(gr_sale_plan(i).quant) < 0 ) THEN
              gr_add_total(r).aug_minus_flg := 'Y';
            END IF;
--
            -- 品目定価が0の場合(月間での存在チェック)
            IF ( ln_price = 0 ) THEN
              gr_add_total(r).aug_ht_zero_flg := 'Y';
            END IF;
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
          END LOOP add_total_loop_8;
--
          -- XML出力フラグ更新
          gr_xml_out(4).tag_name := gv_name_aug;
          gr_xml_out(4).out_fg   := lv_yes;
        ELSE
          -- XML出力フラグ更新
          gr_xml_out(4).tag_name := gv_name_aug;
        END IF;
--
        ------------------------------------
        -- (全拠点)抽出データが９月の場合 --
        ------------------------------------
        IF (gr_sale_plan(i).month = lv_sep_name) THEN
          -- 抽出データ 有
          prc_create_xml_data_dtl
            (
              iv_label_name     => gv_name_sep                             -- 出力タグ名
             ,in_quant          => TO_NUMBER(gr_sale_plan(i).quant)        -- 数量
             ,in_case_quant     => TO_NUMBER(gr_sale_plan(i).case_quant)   -- 入数
             ,in_amount         => TO_NUMBER(gr_sale_plan(i).amount)       -- 金額
             ,in_total_amount   => TO_NUMBER(gr_sale_plan(i).total_amount) -- 内訳合計
             ,iv_price_st       => gr_sale_plan(i).price_st                -- 定価適用開始日
             ,in_n_amount       => TO_NUMBER(gr_sale_plan(i).n_amount)     -- 新定価
             ,in_o_amount       => TO_NUMBER(gr_sale_plan(i).o_amount)     -- 旧定価
             ,on_quant          => ln_quant                                -- 年計用 数量
             ,on_price          => ln_price                                -- 年計用 品目定価
             ,ov_errbuf         => lv_errbuf   -- エラー・メッセージ           --# 固定 #
             ,ov_retcode        => lv_retcode  -- リターン・コード             --# 固定 #
             ,ov_errmsg         => lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
            );
          IF (lv_retcode = gv_status_error) THEN
            RAISE global_process_expt;
          END IF;
--
          -- 年計集計項目計算
          ln_year_quant_sum  := ln_year_quant_sum  + ln_quant;             -- 数量
          ln_year_amount_sum := ln_year_amount_sum + TO_NUMBER(gr_sale_plan(i).amount);
                                                                           -- 金額
-- 2009/04/16 v1.6 T.Yoshimoto Mod Start 本番#1410
/*
          ln_year_to_am_sum  := ln_year_to_am_sum  + TO_NUMBER(gr_sale_plan(i).total_amount);
                                                                           -- 内訳合計
          ln_year_price_sum  := ln_year_price_sum  + ln_price;             -- 品目定価
*/
          ln_year_to_am_sum  := TO_NUMBER(gr_sale_plan(i).total_amount);   -- 内訳合計
          ln_year_price_sum  := ln_price;                                  -- 品目定価
-- 2009/04/16 v1.6 T.Yoshimoto Mod End 本番#1410
--
          -- 各集計項目へデータ挿入
          <<add_total_loop_9>>
          FOR r IN 1..5 LOOP                     -- 小群計/大群計/拠点計/商品区分計/総合計
            gr_add_total(r).sep_quant     :=
               gr_add_total(r).sep_quant     + TO_NUMBER(gr_sale_plan(i).quant);        -- 数量
            gr_add_total(r).sep_amount    :=
               gr_add_total(r).sep_amount    + TO_NUMBER(gr_sale_plan(i).amount);       -- 金額
            gr_add_total(r).sep_price     :=
               gr_add_total(r).sep_price     + ln_price;                                -- 品目定価
            gr_add_total(r).sep_to_amount :=
               gr_add_total(r).sep_to_amount + TO_NUMBER(gr_sale_plan(i).total_amount); -- 内訳合計
            gr_add_total(r).sep_quant_t   :=
               gr_add_total(r).sep_quant_t   + ln_quant;                                -- 数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
            gr_add_total(r).sep_s_cost    :=                                            -- 標準原価(計)
                gr_add_total(r).sep_s_cost   + (TO_NUMBER(gr_sale_plan(i).total_amount) * TO_NUMBER(gr_sale_plan(i).quant));
            gr_add_total(r).sep_calc      :=                                            -- 品目定価*数量(計)
                gr_add_total(r).sep_calc     + (ln_price * TO_NUMBER(gr_sale_plan(i).quant));
--
            gr_add_total(r).year_s_cost    :=                                            -- 年間.標準原価(計)
                gr_add_total(r).year_s_cost   + (TO_NUMBER(gr_sale_plan(i).total_amount) * TO_NUMBER(gr_sale_plan(i).quant));
            gr_add_total(r).year_calc      :=                                            -- 年間.品目定価*数量(計)
                gr_add_total(r).year_calc     + (ln_price * TO_NUMBER(gr_sale_plan(i).quant));
--
            -- 数量がマイナスの場合(月間での存在チェック)
            IF ( TO_NUMBER(gr_sale_plan(i).quant) < 0 ) THEN
              gr_add_total(r).sep_minus_flg := 'Y';
            END IF;
--
            -- 品目定価が0の場合(月間での存在チェック)
            IF ( ln_price = 0 ) THEN
              gr_add_total(r).sep_ht_zero_flg := 'Y';
            END IF;
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
          END LOOP add_total_loop_9;
--
          -- XML出力フラグ更新
          gr_xml_out(5).tag_name := gv_name_sep;
          gr_xml_out(5).out_fg   := lv_yes;
        ELSE
          -- XML出力フラグ更新
          gr_xml_out(5).tag_name := gv_name_sep;
        END IF;
--
        --------------------------------------
        -- (全拠点)抽出データが１０月の場合 --
        --------------------------------------
        IF (gr_sale_plan(i).month = lv_oct_name) THEN
          -- 抽出データ 有
          prc_create_xml_data_dtl
            (
              iv_label_name     => gv_name_oct                             -- 出力タグ名
             ,in_quant          => TO_NUMBER(gr_sale_plan(i).quant)        -- 数量
             ,in_case_quant     => TO_NUMBER(gr_sale_plan(i).case_quant)   -- 入数
             ,in_amount         => TO_NUMBER(gr_sale_plan(i).amount)       -- 金額
             ,in_total_amount   => TO_NUMBER(gr_sale_plan(i).total_amount) -- 内訳合計
             ,iv_price_st       => gr_sale_plan(i).price_st                -- 定価適用開始日
             ,in_n_amount       => TO_NUMBER(gr_sale_plan(i).n_amount)     -- 新定価
             ,in_o_amount       => TO_NUMBER(gr_sale_plan(i).o_amount)     -- 旧定価
             ,on_quant          => ln_quant                                -- 年計用 数量
             ,on_price          => ln_price                                -- 年計用 品目定価
             ,ov_errbuf         => lv_errbuf   -- エラー・メッセージ           --# 固定 #
             ,ov_retcode        => lv_retcode  -- リターン・コード             --# 固定 #
             ,ov_errmsg         => lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
            );
          IF (lv_retcode = gv_status_error) THEN
            RAISE global_process_expt;
          END IF;
--
          -- 年計集計項目計算
          ln_year_quant_sum  := ln_year_quant_sum  + ln_quant;             -- 数量
          ln_year_amount_sum := ln_year_amount_sum + TO_NUMBER(gr_sale_plan(i).amount);
                                                                           -- 金額
-- 2009/04/16 v1.6 T.Yoshimoto Mod Start 本番#1410
/*
          ln_year_to_am_sum  := ln_year_to_am_sum  + TO_NUMBER(gr_sale_plan(i).total_amount);
                                                                           -- 内訳合計
          ln_year_price_sum  := ln_year_price_sum  + ln_price;             -- 品目定価
*/
          ln_year_to_am_sum  := TO_NUMBER(gr_sale_plan(i).total_amount);   -- 内訳合計
          ln_year_price_sum  := ln_price;                                  -- 品目定価
-- 2009/04/16 v1.6 T.Yoshimoto Mod End 本番#1410
--
          -- 各集計項目へデータ挿入
          <<add_total_loop_10>>
          FOR r IN 1..5 LOOP                     -- 小群計/大群計/拠点計/商品区分計/総合計
            gr_add_total(r).oct_quant     :=
               gr_add_total(r).oct_quant     + TO_NUMBER(gr_sale_plan(i).quant);        -- 数量
            gr_add_total(r).oct_amount    :=
               gr_add_total(r).oct_amount    + TO_NUMBER(gr_sale_plan(i).amount);       -- 金額
            gr_add_total(r).oct_price     :=
               gr_add_total(r).oct_price     + ln_price;                                -- 品目定価
            gr_add_total(r).oct_to_amount :=
               gr_add_total(r).oct_to_amount + TO_NUMBER(gr_sale_plan(i).total_amount); -- 内訳合計
            gr_add_total(r).oct_quant_t   :=
               gr_add_total(r).oct_quant_t   + ln_quant;                                -- 数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
            gr_add_total(r).oct_s_cost    :=                                            -- 標準原価(計)
                gr_add_total(r).oct_s_cost   + (TO_NUMBER(gr_sale_plan(i).total_amount) * TO_NUMBER(gr_sale_plan(i).quant));
            gr_add_total(r).oct_calc      :=                                            -- 品目定価*数量(計)
                gr_add_total(r).oct_calc     + (ln_price * TO_NUMBER(gr_sale_plan(i).quant));
--
            gr_add_total(r).year_s_cost    :=                                            -- 年間.標準原価(計)
                gr_add_total(r).year_s_cost   + (TO_NUMBER(gr_sale_plan(i).total_amount) * TO_NUMBER(gr_sale_plan(i).quant));
            gr_add_total(r).year_calc      :=                                            -- 年間.品目定価*数量(計)
                gr_add_total(r).year_calc     + (ln_price * TO_NUMBER(gr_sale_plan(i).quant));
--
            -- 数量がマイナスの場合(月間での存在チェック)
            IF ( TO_NUMBER(gr_sale_plan(i).quant) < 0 ) THEN
              gr_add_total(r).oct_minus_flg := 'Y';
            END IF;
--
            -- 品目定価が0の場合(月間での存在チェック)
            IF ( ln_price = 0 ) THEN
              gr_add_total(r).oct_ht_zero_flg := 'Y';
            END IF;
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
          END LOOP add_total_loop_10;
--
          -- XML出力フラグ更新
          gr_xml_out(6).tag_name := gv_name_oct;
          gr_xml_out(6).out_fg   := lv_yes;
        ELSE
          -- XML出力フラグ更新
          gr_xml_out(6).tag_name := gv_name_oct;
        END IF;
--
        --------------------------------------
        -- (全拠点)抽出データが１１月の場合 --
        --------------------------------------
        IF (gr_sale_plan(i).month = lv_nov_name) THEN
          -- 抽出データ 有
          prc_create_xml_data_dtl
            (
              iv_label_name     => gv_name_nov                             -- 出力タグ名
             ,in_quant          => TO_NUMBER(gr_sale_plan(i).quant)        -- 数量
             ,in_case_quant     => TO_NUMBER(gr_sale_plan(i).case_quant)   -- 入数
             ,in_amount         => TO_NUMBER(gr_sale_plan(i).amount)       -- 金額
             ,in_total_amount   => TO_NUMBER(gr_sale_plan(i).total_amount) -- 内訳合計
             ,iv_price_st       => gr_sale_plan(i).price_st                -- 定価適用開始日
             ,in_n_amount       => TO_NUMBER(gr_sale_plan(i).n_amount)     -- 新定価
             ,in_o_amount       => TO_NUMBER(gr_sale_plan(i).o_amount)     -- 旧定価
             ,on_quant          => ln_quant                                -- 年計用 数量
             ,on_price          => ln_price                                -- 年計用 品目定価
             ,ov_errbuf         => lv_errbuf   -- エラー・メッセージ           --# 固定 #
             ,ov_retcode        => lv_retcode  -- リターン・コード             --# 固定 #
             ,ov_errmsg         => lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
            );
          IF (lv_retcode = gv_status_error) THEN
            RAISE global_process_expt;
          END IF;
--
          -- 年計集計項目計算
          ln_year_quant_sum  := ln_year_quant_sum  + ln_quant;             -- 数量
          ln_year_amount_sum := ln_year_amount_sum + TO_NUMBER(gr_sale_plan(i).amount);
                                                                           -- 金額
-- 2009/04/16 v1.6 T.Yoshimoto Mod Start 本番#1410
/*
          ln_year_to_am_sum  := ln_year_to_am_sum  + TO_NUMBER(gr_sale_plan(i).total_amount);
                                                                           -- 内訳合計
          ln_year_price_sum  := ln_year_price_sum  + ln_price;             -- 品目定価
*/
          ln_year_to_am_sum  := TO_NUMBER(gr_sale_plan(i).total_amount);   -- 内訳合計
          ln_year_price_sum  := ln_price;                                  -- 品目定価
-- 2009/04/16 v1.6 T.Yoshimoto Mod End 本番#1410
--
          -- 各集計項目へデータ挿入
          <<add_total_loop_11>>
          FOR r IN 1..5 LOOP                     -- 小群計/大群計/拠点計/商品区分計/総合計
            gr_add_total(r).nov_quant     :=
               gr_add_total(r).nov_quant     + TO_NUMBER(gr_sale_plan(i).quant);        -- 数量
            gr_add_total(r).nov_amount    :=
               gr_add_total(r).nov_amount    + TO_NUMBER(gr_sale_plan(i).amount);       -- 金額
            gr_add_total(r).nov_price     :=
               gr_add_total(r).nov_price     + ln_price;                                -- 品目定価
            gr_add_total(r).nov_to_amount :=
               gr_add_total(r).nov_to_amount + TO_NUMBER(gr_sale_plan(i).total_amount); -- 内訳合計
            gr_add_total(r).nov_quant_t   :=
               gr_add_total(r).nov_quant_t   + ln_quant;                                -- 数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
            gr_add_total(r).nov_s_cost    :=                                            -- 標準原価(計)
                gr_add_total(r).nov_s_cost   + (TO_NUMBER(gr_sale_plan(i).total_amount) * TO_NUMBER(gr_sale_plan(i).quant));
            gr_add_total(r).nov_calc      :=                                            -- 品目定価*数量(計)
                gr_add_total(r).nov_calc     + (ln_price * TO_NUMBER(gr_sale_plan(i).quant));
--
            gr_add_total(r).year_s_cost    :=                                            -- 年間.標準原価(計)
                gr_add_total(r).year_s_cost   + (TO_NUMBER(gr_sale_plan(i).total_amount) * TO_NUMBER(gr_sale_plan(i).quant));
            gr_add_total(r).year_calc      :=                                            -- 年間.品目定価*数量(計)
                gr_add_total(r).year_calc     + (ln_price * TO_NUMBER(gr_sale_plan(i).quant));
--
            -- 数量がマイナスの場合(月間での存在チェック)
            IF ( TO_NUMBER(gr_sale_plan(i).quant) < 0 ) THEN
              gr_add_total(r).nov_minus_flg := 'Y';
            END IF;
--
            -- 品目定価が0の場合(月間での存在チェック)
            IF ( ln_price = 0 ) THEN
              gr_add_total(r).nov_ht_zero_flg := 'Y';
            END IF;
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
          END LOOP add_total_loop_11;
--
          -- XML出力フラグ更新
          gr_xml_out(7).tag_name := gv_name_nov;
          gr_xml_out(7).out_fg   := lv_yes;
        ELSE
          -- XML出力フラグ更新
          gr_xml_out(7).tag_name := gv_name_nov;
        END IF;
--
        --------------------------------------
        -- (全拠点)抽出データが１２月の場合 --
        --------------------------------------
        IF (gr_sale_plan(i).month = lv_dec_name) THEN
          -- 抽出データ 有
          prc_create_xml_data_dtl
            (
              iv_label_name     => gv_name_dec                             -- 出力タグ名
             ,in_quant          => TO_NUMBER(gr_sale_plan(i).quant)        -- 数量
             ,in_case_quant     => TO_NUMBER(gr_sale_plan(i).case_quant)   -- 入数
             ,in_amount         => TO_NUMBER(gr_sale_plan(i).amount)       -- 金額
             ,in_total_amount   => TO_NUMBER(gr_sale_plan(i).total_amount) -- 内訳合計
             ,iv_price_st       => gr_sale_plan(i).price_st                -- 定価適用開始日
             ,in_n_amount       => TO_NUMBER(gr_sale_plan(i).n_amount)     -- 新定価
             ,in_o_amount       => TO_NUMBER(gr_sale_plan(i).o_amount)     -- 旧定価
             ,on_quant          => ln_quant                                -- 年計用 数量
             ,on_price          => ln_price                                -- 年計用 品目定価
             ,ov_errbuf         => lv_errbuf   -- エラー・メッセージ           --# 固定 #
             ,ov_retcode        => lv_retcode  -- リターン・コード             --# 固定 #
             ,ov_errmsg         => lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
            );
          IF (lv_retcode = gv_status_error) THEN
            RAISE global_process_expt;
          END IF;
--
          -- 年計集計項目計算
          ln_year_quant_sum  := ln_year_quant_sum  + ln_quant;             -- 数量
          ln_year_amount_sum := ln_year_amount_sum + TO_NUMBER(gr_sale_plan(i).amount);
                                                                           -- 金額
-- 2009/04/16 v1.6 T.Yoshimoto Mod Start 本番#1410
/*
          ln_year_to_am_sum  := ln_year_to_am_sum  + TO_NUMBER(gr_sale_plan(i).total_amount);
                                                                           -- 内訳合計
          ln_year_price_sum  := ln_year_price_sum  + ln_price;             -- 品目定価
*/
          ln_year_to_am_sum  := TO_NUMBER(gr_sale_plan(i).total_amount);   -- 内訳合計
          ln_year_price_sum  := ln_price;                                  -- 品目定価
-- 2009/04/16 v1.6 T.Yoshimoto Mod End 本番#1410
--
          -- 各集計項目へデータ挿入
          <<add_total_loop_12>>
          FOR r IN 1..5 LOOP                     -- 小群計/大群計/拠点計/商品区分計/総合計
            gr_add_total(r).dec_quant     :=
               gr_add_total(r).dec_quant     + TO_NUMBER(gr_sale_plan(i).quant);        -- 数量
            gr_add_total(r).dec_amount    :=
               gr_add_total(r).dec_amount    + TO_NUMBER(gr_sale_plan(i).amount);       -- 金額
            gr_add_total(r).dec_price     :=
               gr_add_total(r).dec_price     + ln_price;                                -- 品目定価
            gr_add_total(r).dec_to_amount :=
               gr_add_total(r).dec_to_amount + TO_NUMBER(gr_sale_plan(i).total_amount); -- 内訳合計
            gr_add_total(r).dec_quant_t   :=
               gr_add_total(r).dec_quant_t   + ln_quant;                                -- 数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
            gr_add_total(r).dec_s_cost    :=                                            -- 標準原価(計)
                gr_add_total(r).dec_s_cost   + (TO_NUMBER(gr_sale_plan(i).total_amount) * TO_NUMBER(gr_sale_plan(i).quant));
            gr_add_total(r).dec_calc      :=                                            -- 品目定価*数量(計)
                gr_add_total(r).dec_calc     + (ln_price * TO_NUMBER(gr_sale_plan(i).quant));
--
            gr_add_total(r).year_s_cost    :=                                            -- 年間.標準原価(計)
                gr_add_total(r).year_s_cost   + (TO_NUMBER(gr_sale_plan(i).total_amount) * TO_NUMBER(gr_sale_plan(i).quant));
            gr_add_total(r).year_calc      :=                                            -- 年間.品目定価*数量(計)
                gr_add_total(r).year_calc     + (ln_price * TO_NUMBER(gr_sale_plan(i).quant));
--
            -- 数量がマイナスの場合(月間での存在チェック)
            IF ( TO_NUMBER(gr_sale_plan(i).quant) < 0 ) THEN
              gr_add_total(r).dec_minus_flg := 'Y';
            END IF;
--
            -- 品目定価が0の場合(月間での存在チェック)
            IF ( ln_price = 0 ) THEN
              gr_add_total(r).dec_ht_zero_flg := 'Y';
            END IF;
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
          END LOOP add_total_loop_12;
--
          -- XML出力フラグ更新
          gr_xml_out(8).tag_name := gv_name_dec;
          gr_xml_out(8).out_fg   := lv_yes;
        ELSE
          -- XML出力フラグ更新
          gr_xml_out(8).tag_name := gv_name_dec;
        END IF;
--
        ------------------------------------
        -- (全拠点)抽出データが１月の場合 --
        ------------------------------------
        IF (gr_sale_plan(i).month = lv_jan_name) THEN
          -- 抽出データ 有
          prc_create_xml_data_dtl
            (
              iv_label_name     => gv_name_jan                             -- 出力タグ名
             ,in_quant          => TO_NUMBER(gr_sale_plan(i).quant)        -- 数量
             ,in_case_quant     => TO_NUMBER(gr_sale_plan(i).case_quant)   -- 入数
             ,in_amount         => TO_NUMBER(gr_sale_plan(i).amount)       -- 金額
             ,in_total_amount   => TO_NUMBER(gr_sale_plan(i).total_amount) -- 内訳合計
             ,iv_price_st       => gr_sale_plan(i).price_st                -- 定価適用開始日
             ,in_n_amount       => TO_NUMBER(gr_sale_plan(i).n_amount)     -- 新定価
             ,in_o_amount       => TO_NUMBER(gr_sale_plan(i).o_amount)     -- 旧定価
             ,on_quant          => ln_quant                                -- 年計用 数量
             ,on_price          => ln_price                                -- 年計用 品目定価
             ,ov_errbuf         => lv_errbuf   -- エラー・メッセージ           --# 固定 #
             ,ov_retcode        => lv_retcode  -- リターン・コード             --# 固定 #
             ,ov_errmsg         => lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
            );
          IF (lv_retcode = gv_status_error) THEN
            RAISE global_process_expt;
          END IF;
--
          -- 年計集計項目計算
          ln_year_quant_sum  := ln_year_quant_sum  + ln_quant;             -- 数量
          ln_year_amount_sum := ln_year_amount_sum + TO_NUMBER(gr_sale_plan(i).amount);
                                                                           -- 金額
-- 2009/04/16 v1.6 T.Yoshimoto Mod Start 本番#1410
/*
          ln_year_to_am_sum  := ln_year_to_am_sum  + TO_NUMBER(gr_sale_plan(i).total_amount);
                                                                           -- 内訳合計
          ln_year_price_sum  := ln_year_price_sum  + ln_price;             -- 品目定価
*/
          ln_year_to_am_sum  := TO_NUMBER(gr_sale_plan(i).total_amount);   -- 内訳合計
          ln_year_price_sum  := ln_price;                                  -- 品目定価
-- 2009/04/16 v1.6 T.Yoshimoto Mod End 本番#1410
--
          -- 各集計項目へデータ挿入
          <<add_total_loop_1>>
          FOR r IN 1..5 LOOP                     -- 小群計/大群計/拠点計/商品区分計/総合計
            gr_add_total(r).jan_quant     :=
               gr_add_total(r).jan_quant     + TO_NUMBER(gr_sale_plan(i).quant);        -- 数量
            gr_add_total(r).jan_amount    :=
               gr_add_total(r).jan_amount    + TO_NUMBER(gr_sale_plan(i).amount);       -- 金額
            gr_add_total(r).jan_price     :=
               gr_add_total(r).jan_price     + ln_price;                                -- 品目定価
            gr_add_total(r).jan_to_amount :=
               gr_add_total(r).jan_to_amount + TO_NUMBER(gr_sale_plan(i).total_amount); -- 内訳合計
            gr_add_total(r).jan_quant_t   :=
               gr_add_total(r).jan_quant_t   + ln_quant;                                -- 数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
            gr_add_total(r).jan_s_cost    :=                                            -- 標準原価(計)
                gr_add_total(r).jan_s_cost   + (TO_NUMBER(gr_sale_plan(i).total_amount) * TO_NUMBER(gr_sale_plan(i).quant));
            gr_add_total(r).jan_calc      :=                                            -- 品目定価*数量(計)
                gr_add_total(r).jan_calc     + (ln_price * TO_NUMBER(gr_sale_plan(i).quant));
--
            gr_add_total(r).year_s_cost    :=                                            -- 年間.標準原価(計)
                gr_add_total(r).year_s_cost   + (TO_NUMBER(gr_sale_plan(i).total_amount) * TO_NUMBER(gr_sale_plan(i).quant));
            gr_add_total(r).year_calc      :=                                            -- 年間.品目定価*数量(計)
                gr_add_total(r).year_calc     + (ln_price * TO_NUMBER(gr_sale_plan(i).quant));
--
            -- 数量がマイナスの場合(月間での存在チェック)
            IF ( TO_NUMBER(gr_sale_plan(i).quant) < 0 ) THEN
              gr_add_total(r).jan_minus_flg := 'Y';
            END IF;
--
            -- 品目定価が0の場合(月間での存在チェック)
            IF ( ln_price = 0 ) THEN
              gr_add_total(r).jan_ht_zero_flg := 'Y';
            END IF;
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
          END LOOP add_total_loop_1;
--
          -- XML出力フラグ更新
          gr_xml_out(9).tag_name := gv_name_jan;
          gr_xml_out(9).out_fg   := lv_yes;
        ELSE
          -- XML出力フラグ更新
          gr_xml_out(9).tag_name := gv_name_jan;
        END IF;
--
        ------------------------------------
        -- (全拠点)抽出データが２月の場合 --
        ------------------------------------
        IF (gr_sale_plan(i).month = lv_feb_name) THEN
          -- 抽出データ 有
          prc_create_xml_data_dtl
            (
              iv_label_name     => gv_name_feb                             -- 出力タグ名
             ,in_quant          => TO_NUMBER(gr_sale_plan(i).quant)        -- 数量
             ,in_case_quant     => TO_NUMBER(gr_sale_plan(i).case_quant)   -- 入数
             ,in_amount         => TO_NUMBER(gr_sale_plan(i).amount)       -- 金額
             ,in_total_amount   => TO_NUMBER(gr_sale_plan(i).total_amount) -- 内訳合計
             ,iv_price_st       => gr_sale_plan(i).price_st                -- 定価適用開始日
             ,in_n_amount       => TO_NUMBER(gr_sale_plan(i).n_amount)     -- 新定価
             ,in_o_amount       => TO_NUMBER(gr_sale_plan(i).o_amount)     -- 旧定価
             ,on_quant          => ln_quant                                -- 年計用 数量
             ,on_price          => ln_price                                -- 年計用 品目定価
             ,ov_errbuf         => lv_errbuf   -- エラー・メッセージ           --# 固定 #
             ,ov_retcode        => lv_retcode  -- リターン・コード             --# 固定 #
             ,ov_errmsg         => lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
            );
          IF (lv_retcode = gv_status_error) THEN
            RAISE global_process_expt;
          END IF;
--
          -- 年計集計項目計算
          ln_year_quant_sum  := ln_year_quant_sum  + ln_quant;             -- 数量
          ln_year_amount_sum := ln_year_amount_sum + TO_NUMBER(gr_sale_plan(i).amount);
                                                                           -- 金額
-- 2009/04/16 v1.6 T.Yoshimoto Mod Start 本番#1410
/*
          ln_year_to_am_sum  := ln_year_to_am_sum  + TO_NUMBER(gr_sale_plan(i).total_amount);
                                                                           -- 内訳合計
          ln_year_price_sum  := ln_year_price_sum  + ln_price;             -- 品目定価
*/
          ln_year_to_am_sum  := TO_NUMBER(gr_sale_plan(i).total_amount);   -- 内訳合計
          ln_year_price_sum  := ln_price;                                  -- 品目定価
-- 2009/04/16 v1.6 T.Yoshimoto Mod End 本番#1410
--
          -- 各集計項目へデータ挿入
          <<add_total_loop_2>>
          FOR r IN 1..5 LOOP                     -- 小群計/大群計/拠点計/商品区分計/総合計
            gr_add_total(r).feb_quant     :=
               gr_add_total(r).feb_quant     + TO_NUMBER(gr_sale_plan(i).quant);        -- 数量
            gr_add_total(r).feb_amount    :=
               gr_add_total(r).feb_amount    + TO_NUMBER(gr_sale_plan(i).amount);       -- 金額
            gr_add_total(r).feb_price     :=
               gr_add_total(r).feb_price     + ln_price;                                -- 品目定価
            gr_add_total(r).feb_to_amount :=
               gr_add_total(r).feb_to_amount + TO_NUMBER(gr_sale_plan(i).total_amount); -- 内訳合計
            gr_add_total(r).feb_quant_t   :=
               gr_add_total(r).feb_quant_t   + ln_quant;                                -- 数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
            gr_add_total(r).feb_s_cost    :=                                            -- 標準原価(計)
                gr_add_total(r).feb_s_cost   + (TO_NUMBER(gr_sale_plan(i).total_amount) * TO_NUMBER(gr_sale_plan(i).quant));
            gr_add_total(r).feb_calc      :=                                            -- 品目定価*数量(計)
                gr_add_total(r).feb_calc     + (ln_price * TO_NUMBER(gr_sale_plan(i).quant));
--
            gr_add_total(r).year_s_cost    :=                                            -- 年間.標準原価(計)
                gr_add_total(r).year_s_cost   + (TO_NUMBER(gr_sale_plan(i).total_amount) * TO_NUMBER(gr_sale_plan(i).quant));
            gr_add_total(r).year_calc      :=                                            -- 年間.品目定価*数量(計)
                gr_add_total(r).year_calc     + (ln_price * TO_NUMBER(gr_sale_plan(i).quant));
--
            -- 数量がマイナスの場合(月間での存在チェック)
            IF ( TO_NUMBER(gr_sale_plan(i).quant) < 0 ) THEN
              gr_add_total(r).feb_minus_flg := 'Y';
            END IF;
--
            -- 品目定価が0の場合(月間での存在チェック)
            IF ( ln_price = 0 ) THEN
              gr_add_total(r).feb_ht_zero_flg := 'Y';
            END IF;
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
          END LOOP add_total_loop_2;
--
          -- XML出力フラグ更新
          gr_xml_out(10).tag_name := gv_name_feb;
          gr_xml_out(10).out_fg   := lv_yes;
        ELSE
          -- XML出力フラグ更新
          gr_xml_out(10).tag_name := gv_name_feb;
        END IF;
--
        ------------------------------------
        -- (全拠点)抽出データが３月の場合 --
        ------------------------------------
        IF (gr_sale_plan(i).month = lv_mar_name) THEN
          -- 抽出データ 有
          prc_create_xml_data_dtl
            (
              iv_label_name     => gv_name_mar                             -- 出力タグ名
             ,in_quant          => TO_NUMBER(gr_sale_plan(i).quant)        -- 数量
             ,in_case_quant     => TO_NUMBER(gr_sale_plan(i).case_quant)   -- 入数
             ,in_amount         => TO_NUMBER(gr_sale_plan(i).amount)       -- 金額
             ,in_total_amount   => TO_NUMBER(gr_sale_plan(i).total_amount) -- 内訳合計
             ,iv_price_st       => gr_sale_plan(i).price_st                -- 定価適用開始日
             ,in_n_amount       => TO_NUMBER(gr_sale_plan(i).n_amount)     -- 新定価
             ,in_o_amount       => TO_NUMBER(gr_sale_plan(i).o_amount)     -- 旧定価
             ,on_quant          => ln_quant                                -- 年計用 数量
             ,on_price          => ln_price                                -- 年計用 品目定価
             ,ov_errbuf         => lv_errbuf   -- エラー・メッセージ           --# 固定 #
             ,ov_retcode        => lv_retcode  -- リターン・コード             --# 固定 #
             ,ov_errmsg         => lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
            );
          IF (lv_retcode = gv_status_error) THEN
            RAISE global_process_expt;
          END IF;
--
          -- 年計集計項目計算
          ln_year_quant_sum  := ln_year_quant_sum  + ln_quant;             -- 数量
          ln_year_amount_sum := ln_year_amount_sum + TO_NUMBER(gr_sale_plan(i).amount);
                                                                           -- 金額
-- 2009/04/16 v1.6 T.Yoshimoto Mod Start 本番#1410
/*
          ln_year_to_am_sum  := ln_year_to_am_sum  + TO_NUMBER(gr_sale_plan(i).total_amount);
                                                                           -- 内訳合計
          ln_year_price_sum  := ln_year_price_sum  + ln_price;             -- 品目定価
*/
          ln_year_to_am_sum  := TO_NUMBER(gr_sale_plan(i).total_amount);   -- 内訳合計
          ln_year_price_sum  := ln_price;                                  -- 品目定価
-- 2009/04/16 v1.6 T.Yoshimoto Mod End 本番#1410
--
          -- 各集計項目へデータ挿入
          <<add_total_loop_3>>
          FOR r IN 1..5 LOOP                     -- 小群計/大群計/拠点計/商品区分計/総合計
            gr_add_total(r).mar_quant     :=
               gr_add_total(r).mar_quant     + TO_NUMBER(gr_sale_plan(i).quant);        -- 数量
            gr_add_total(r).mar_amount    :=
               gr_add_total(r).mar_amount    + TO_NUMBER(gr_sale_plan(i).amount);       -- 金額
            gr_add_total(r).mar_price     :=
               gr_add_total(r).mar_price     + ln_price;                                -- 品目定価
            gr_add_total(r).mar_to_amount :=
               gr_add_total(r).mar_to_amount + TO_NUMBER(gr_sale_plan(i).total_amount); -- 内訳合計
            gr_add_total(r).mar_quant_t   :=
               gr_add_total(r).mar_quant_t   + ln_quant;                                -- 数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
            gr_add_total(r).mar_s_cost    :=                                            -- 標準原価(計)
                gr_add_total(r).mar_s_cost   + (TO_NUMBER(gr_sale_plan(i).total_amount) * TO_NUMBER(gr_sale_plan(i).quant));
            gr_add_total(r).mar_calc      :=                                            -- 品目定価*数量(計)
                gr_add_total(r).mar_calc     + (ln_price * TO_NUMBER(gr_sale_plan(i).quant));
--
            gr_add_total(r).year_s_cost    :=                                            -- 年間.標準原価(計)
                gr_add_total(r).year_s_cost   + (TO_NUMBER(gr_sale_plan(i).total_amount) * TO_NUMBER(gr_sale_plan(i).quant));
            gr_add_total(r).year_calc      :=                                            -- 年間.品目定価*数量(計)
                gr_add_total(r).year_calc     + (ln_price * TO_NUMBER(gr_sale_plan(i).quant));
--
            -- 数量がマイナスの場合(月間での存在チェック)
            IF ( TO_NUMBER(gr_sale_plan(i).quant) < 0 ) THEN
              gr_add_total(r).mar_minus_flg := 'Y';
            END IF;
--
            -- 品目定価が0の場合(月間での存在チェック)
            IF ( ln_price = 0 ) THEN
              gr_add_total(r).mar_ht_zero_flg := 'Y';
            END IF;
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
          END LOOP add_total_loop_3;
--
          -- XML出力フラグ更新
          gr_xml_out(11).tag_name := gv_name_mar;
          gr_xml_out(11).out_fg   := lv_yes;
        ELSE
          -- XML出力フラグ更新
          gr_xml_out(11).tag_name := gv_name_mar;
        END IF;
--
        ------------------------------------
        -- (全拠点)抽出データが４月の場合 --
        ------------------------------------
        IF (gr_sale_plan(i).month = lv_apr_name) THEN
          -- 抽出データ 有
          prc_create_xml_data_dtl
            (
              iv_label_name     => gv_name_apr                             -- 出力タグ名
             ,in_quant          => TO_NUMBER(gr_sale_plan(i).quant)        -- 数量
             ,in_case_quant     => TO_NUMBER(gr_sale_plan(i).case_quant)   -- 入数
             ,in_amount         => TO_NUMBER(gr_sale_plan(i).amount)       -- 金額
             ,in_total_amount   => TO_NUMBER(gr_sale_plan(i).total_amount) -- 内訳合計
             ,iv_price_st       => gr_sale_plan(i).price_st                -- 定価適用開始日
             ,in_n_amount       => TO_NUMBER(gr_sale_plan(i).n_amount)     -- 新定価
             ,in_o_amount       => TO_NUMBER(gr_sale_plan(i).o_amount)     -- 旧定価
             ,on_quant          => ln_quant                                -- 年計用 数量
             ,on_price          => ln_price                                -- 年計用 品目定価
             ,ov_errbuf         => lv_errbuf   -- エラー・メッセージ           --# 固定 #
             ,ov_retcode        => lv_retcode  -- リターン・コード             --# 固定 #
             ,ov_errmsg         => lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
            );
          IF (lv_retcode = gv_status_error) THEN
            RAISE global_process_expt;
          END IF;
--
          -- 年計集計項目計算
          ln_year_quant_sum  := ln_year_quant_sum  + ln_quant;             -- 数量
          ln_year_amount_sum := ln_year_amount_sum + TO_NUMBER(gr_sale_plan(i).amount);
                                                                           -- 金額
-- 2009/04/16 v1.6 T.Yoshimoto Mod Start 本番#1410
/*
          ln_year_to_am_sum  := ln_year_to_am_sum  + TO_NUMBER(gr_sale_plan(i).total_amount);
                                                                           -- 内訳合計
          ln_year_price_sum  := ln_year_price_sum  + ln_price;             -- 品目定価
*/
          ln_year_to_am_sum  := TO_NUMBER(gr_sale_plan(i).total_amount);   -- 内訳合計
          ln_year_price_sum  := ln_price;                                  -- 品目定価
-- 2009/04/16 v1.6 T.Yoshimoto Mod End 本番#1410
--
          -- 各集計項目へデータ挿入
          <<add_total_loop_4>>
          FOR r IN 1..5 LOOP                     -- 小群計/大群計/拠点計/商品区分計/総合計
            gr_add_total(r).apr_quant     :=
               gr_add_total(r).apr_quant     + TO_NUMBER(gr_sale_plan(i).quant);        -- 数量
            gr_add_total(r).apr_amount    :=
               gr_add_total(r).apr_amount    + TO_NUMBER(gr_sale_plan(i).amount);       -- 金額
            gr_add_total(r).apr_price     :=
               gr_add_total(r).apr_price     + ln_price;                                -- 品目定価
            gr_add_total(r).apr_to_amount :=
               gr_add_total(r).apr_to_amount + TO_NUMBER(gr_sale_plan(i).total_amount); -- 内訳合計
            gr_add_total(r).apr_quant_t   :=
               gr_add_total(r).apr_quant_t   + ln_quant;                                -- 数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
            gr_add_total(r).apr_s_cost    :=                                            -- 標準原価(計)
                gr_add_total(r).apr_s_cost   + (TO_NUMBER(gr_sale_plan(i).total_amount) * TO_NUMBER(gr_sale_plan(i).quant));
            gr_add_total(r).apr_calc      :=                                            -- 品目定価*数量(計)
                gr_add_total(r).apr_calc     + (ln_price * TO_NUMBER(gr_sale_plan(i).quant));
--
            gr_add_total(r).year_s_cost    :=                                            -- 年間.標準原価(計)
                gr_add_total(r).year_s_cost   + (TO_NUMBER(gr_sale_plan(i).total_amount) * TO_NUMBER(gr_sale_plan(i).quant));
            gr_add_total(r).year_calc      :=                                            -- 年間.品目定価*数量(計)
                gr_add_total(r).year_calc     + (ln_price * TO_NUMBER(gr_sale_plan(i).quant));
--
            -- 数量がマイナスの場合(月間での存在チェック)
            IF ( TO_NUMBER(gr_sale_plan(i).quant) < 0 ) THEN
              gr_add_total(r).apr_minus_flg := 'Y';
            END IF;
--
            -- 品目定価が0の場合(月間での存在チェック)
            IF ( ln_price = 0 ) THEN
              gr_add_total(r).apr_ht_zero_flg := 'Y';
            END IF;
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
          END LOOP add_total_loop_4;
--
          -- XML出力フラグ更新
          gr_xml_out(12).tag_name := gv_name_apr;
          gr_xml_out(12).out_fg   := lv_yes;
        ELSE
          -- XML出力フラグ更新
          gr_xml_out(12).tag_name := gv_name_apr;
        END IF;
--
        ----------------------------------------------
        -- (全拠点)ブレイクキー更新                 --
        ----------------------------------------------
        lv_dtl_break := gr_sale_plan(i).item_no;
--
      END LOOP main_data_loop;
--
      -- =====================================================
      -- (全拠点)終了処理
      -- =====================================================
      ---------------------------------------------------------------
      -- (全拠点)各月抽出データが存在しない場合、0表示にてXML出力  --
      ---------------------------------------------------------------
      <<xml_out_0_loop>>
      FOR m IN 1..12 LOOP
        IF (gr_xml_out(m).out_fg = lv_no) THEN
          prc_create_xml_data_dtl_n
            (
              iv_label_name     => gr_xml_out(m).tag_name                      -- 出力タグ名
             ,ov_errbuf         => lv_errbuf   -- エラー・メッセージ           --# 固定 #
             ,ov_retcode        => lv_retcode  -- リターン・コード             --# 固定 #
             ,ov_errmsg         => lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
            );
          IF (lv_retcode = gv_status_error) THEN
            RAISE global_process_expt;
          END IF;
        END IF;
      END LOOP xml_out_0_loop;
--
      -- -----------------------------------------------------
      -- (全拠点)年計 数量データ
      -- -----------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'year_quant';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
      gt_xml_data_table(gl_xml_idx).tag_value := ln_year_quant_sum;
--
      -- -----------------------------------------------------
      -- (全拠点)年計 金額データ
      -- -----------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'year_amount';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
      gt_xml_data_table(gl_xml_idx).tag_value := ROUND(ln_year_amount_sum / 1000,0);
--
      -- -----------------------------------------------------
      -- (全拠点)年計 粗利率データ
      -- -----------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'year_arari_par';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
--
      ----------------------------------------------
      -- (全拠点)粗利計算 (金額－内訳合計＊数量)  --
      ----------------------------------------------
      ln_arari := ln_year_amount_sum - ln_year_to_am_sum * ln_year_quant_sum;
      -- ０除算回避判定
      IF (ln_year_amount_sum <> gn_0) THEN
        -- 値が[0]出なければ計算
        gt_xml_data_table(gl_xml_idx).tag_value := 
                  ROUND((ln_arari / ln_year_amount_sum * 100),2);
      ELSE
        -- 値が[0]の場合は、一律[0]設定
        gt_xml_data_table(gl_xml_idx).tag_value := gn_0;
      END IF;
--
      -- -----------------------------------------------------
      -- (全拠点)年計 掛率データ
      -- -----------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'year_kake_par';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
--
      --------------------------------------
      -- ０除算判定項目へ判定値を挿入     --
      --------------------------------------
      ln_chk_0 := ln_year_price_sum * ln_year_quant_sum;
      -- ０除算回避判定
      IF (ln_chk_0 <> gn_0) THEN
      -- 値が[0]出なければ計算
      ln_kake_par := ROUND((ln_year_amount_sum * 100) / ln_chk_0,2);
      ELSE
        -- 値が[0]の場合は、一律[0]設定
        ln_kake_par := gn_0;
      END IF;
--
      -- 品目定価 = ０か、計算結果がマイナスの場合、固定値[70.00]を登録
      IF ((ln_year_price_sum = 0)
        OR (ln_kake_par < 0)) THEN
        ln_kake_par := gn_kotei_70; -- 固定値[70.00]
      END IF;
      gt_xml_data_table(gl_xml_idx).tag_value := ln_kake_par;
--
      -- 各集計項目へデータ挿入
      <<add_total_loop>>
      FOR r IN 1..5 LOOP                     -- 小群計/大群計/拠点計/商品区分計/総合計
        gr_add_total(r).year_quant     :=
           gr_add_total(r).year_quant     + ln_year_quant_sum;        -- 数量
        gr_add_total(r).year_amount    :=
           gr_add_total(r).year_amount    + ln_year_amount_sum;       -- 金額
        gr_add_total(r).year_price     :=
           gr_add_total(r).year_price     + ln_year_price_sum;        -- 品目定価
        gr_add_total(r).year_to_amount :=
           gr_add_total(r).year_to_amount + ln_year_to_am_sum;        -- 内訳合計
        gr_add_total(r).year_quant_t   :=
           gr_add_total(r).year_quant_t   + ln_year_quant_sum;        -- 数量(計)
--
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
        -- 数量がマイナスの場合(年間での存在チェック)
        IF ( ln_year_quant_sum < 0 ) THEN
          gr_add_total(r).year_minus_flg := 'Y';
        END IF;
--
        -- 品目定価が0の場合(年間での存在チェック)
        IF ( ln_year_price_sum = 0 ) THEN
          gr_add_total(r).year_ht_zero_flg := 'Y';
        END IF;
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
      END LOOP add_total_loop;
--
      -- -----------------------------------------------------
      -- (全拠点)品目終了Ｇタグ出力
      -- -----------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1;
      gt_xml_data_table(gl_xml_idx).tag_name  := '/g_dtl';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
      -- -----------------------------------------------------
      -- (全拠点)品目終了ＬＧタグ出力
      -- -----------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1;
      gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_dtl_info';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
-- 2009/04/16 v1.6 T.Yoshimoto Mod Start 本番#1410
/*
      --------------------------------------------------------
      -- 小群計データタグ出力 
      --------------------------------------------------------
      prc_create_xml_data_st_lt
      (
        iv_label_name     => gv_name_st                     -- 小群計用タグ名
        ,iv_name           => gv_label_st                    -- 小群計タイトル
        ,in_may_quant      => gr_add_total(1).may_quant      -- ５月 数量
        ,in_may_amount     => gr_add_total(1).may_amount     -- ５月 金額
        ,in_may_price      => gr_add_total(1).may_price      -- ５月 品目定価
        ,in_may_to_amount  => gr_add_total(1).may_to_amount  -- ５月 内訳合計
        ,in_may_quant_t    => gr_add_total(1).may_quant_t    -- ５月 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
        ,in_may_s_cost     => gr_add_total(1).may_s_cost     -- ５月 標準原価(計算用)
        ,in_may_calc       => gr_add_total(1).may_calc       -- ５月 品目定価*数量(計算用)
        ,in_may_minus_flg   => gr_add_total(1).may_minus_flg   -- ５月 数量マイナス値存在フラグ(計算用)
        ,in_may_ht_zero_flg => gr_add_total(1).may_ht_zero_flg -- ５月 品目定価*数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
        ,in_jun_quant      => gr_add_total(1).jun_quant      -- ６月 数量
        ,in_jun_amount     => gr_add_total(1).jun_amount     -- ６月 金額
        ,in_jun_price      => gr_add_total(1).jun_price      -- ６月 品目定価
        ,in_jun_to_amount  => gr_add_total(1).jun_to_amount  -- ６月 内訳合計
        ,in_jun_quant_t    => gr_add_total(1).jun_quant_t    -- ６月 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
        ,in_jun_s_cost     => gr_add_total(1).jun_s_cost     -- ６月 標準原価(計算用)
        ,in_jun_calc       => gr_add_total(1).jun_calc       -- ６月 品目定価*数量(計算用)
        ,in_jun_minus_flg   => gr_add_total(1).jun_minus_flg   -- ６月 数量マイナス値存在フラグ(計算用)
        ,in_jun_ht_zero_flg => gr_add_total(1).jun_ht_zero_flg -- ６月 品目定価*数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
        ,in_jul_quant      => gr_add_total(1).jul_quant      -- ７月 数量
        ,in_jul_amount     => gr_add_total(1).jul_amount     -- ７月 金額
        ,in_jul_price      => gr_add_total(1).jul_price      -- ７月 品目定価
        ,in_jul_to_amount  => gr_add_total(1).jul_to_amount  -- ７月 内訳合計
        ,in_jul_quant_t    => gr_add_total(1).jul_quant_t    -- ７月 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
        ,in_jul_s_cost     => gr_add_total(1).jul_s_cost     -- ７月 標準原価(計算用)
        ,in_jul_calc       => gr_add_total(1).jul_calc       -- ７月 品目定価*数量(計算用)
        ,in_jul_minus_flg   => gr_add_total(1).jul_minus_flg   -- ７月 数量マイナス値存在フラグ(計算用)
        ,in_jul_ht_zero_flg => gr_add_total(1).jul_ht_zero_flg -- ７月 品目定価*数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
        ,in_aug_quant      => gr_add_total(1).aug_quant      -- ８月 数量
        ,in_aug_amount     => gr_add_total(1).aug_amount     -- ８月 金額
        ,in_aug_price      => gr_add_total(1).aug_price      -- ８月 品目定価
        ,in_aug_to_amount  => gr_add_total(1).aug_to_amount  -- ８月 内訳合計
        ,in_aug_quant_t    => gr_add_total(1).aug_quant_t    -- ８月 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
        ,in_aug_s_cost     => gr_add_total(1).aug_s_cost     -- ８月 標準原価(計算用)
        ,in_aug_calc       => gr_add_total(1).aug_calc       -- ８月 品目定価*数量(計算用)
        ,in_aug_minus_flg   => gr_add_total(1).aug_minus_flg   -- ８月 数量マイナス値存在フラグ(計算用)
        ,in_aug_ht_zero_flg => gr_add_total(1).aug_ht_zero_flg -- ８月 品目定価*数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
        ,in_sep_quant      => gr_add_total(1).sep_quant      -- ９月 数量
        ,in_sep_amount     => gr_add_total(1).sep_amount     -- ９月 金額
        ,in_sep_price      => gr_add_total(1).sep_price      -- ９月 品目定価
        ,in_sep_to_amount  => gr_add_total(1).sep_to_amount  -- ９月 内訳合計
        ,in_sep_quant_t    => gr_add_total(1).sep_quant_t    -- ９月 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
        ,in_sep_s_cost     => gr_add_total(1).sep_s_cost     -- ９月 標準原価(計算用)
        ,in_sep_calc       => gr_add_total(1).sep_calc       -- ９月 品目定価*数量(計算用)
        ,in_sep_minus_flg   => gr_add_total(1).sep_minus_flg   -- ９月 数量マイナス値存在フラグ(計算用)
        ,in_sep_ht_zero_flg => gr_add_total(1).sep_ht_zero_flg -- ９月 品目定価*数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
        ,in_oct_quant      => gr_add_total(1).oct_quant      -- １０月 数量
        ,in_oct_amount     => gr_add_total(1).oct_amount     -- １０月 金額
        ,in_oct_price      => gr_add_total(1).oct_price      -- １０月 品目定価
        ,in_oct_to_amount  => gr_add_total(1).oct_to_amount  -- １０月 内訳合計
        ,in_oct_quant_t    => gr_add_total(1).oct_quant_t    -- １０月 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
        ,in_oct_s_cost     => gr_add_total(1).oct_s_cost     -- １０月 標準原価(計算用)
        ,in_oct_calc       => gr_add_total(1).oct_calc       -- １０月 品目定価*数量(計算用)
        ,in_oct_minus_flg   => gr_add_total(1).oct_minus_flg   -- １０月 数量マイナス値存在フラグ(計算用)
        ,in_oct_ht_zero_flg => gr_add_total(1).oct_ht_zero_flg -- １０月 品目定価*数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
        ,in_nov_quant      => gr_add_total(1).nov_quant      -- １１月 数量
        ,in_nov_amount     => gr_add_total(1).nov_amount     -- １１月 金額
        ,in_nov_price      => gr_add_total(1).nov_price      -- １１月 品目定価
        ,in_nov_to_amount  => gr_add_total(1).nov_to_amount  -- １１月 内訳合計
        ,in_nov_quant_t    => gr_add_total(1).nov_quant_t    -- １１月 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
        ,in_nov_s_cost     => gr_add_total(1).nov_s_cost     -- １１月 標準原価(計算用)
        ,in_nov_calc       => gr_add_total(1).nov_calc       -- １１月 品目定価*数量(計算用)
        ,in_nov_minus_flg   => gr_add_total(1).nov_minus_flg   -- １１月 数量マイナス値存在フラグ(計算用)
        ,in_nov_ht_zero_flg => gr_add_total(1).nov_ht_zero_flg -- １１月 品目定価*数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
        ,in_dec_quant      => gr_add_total(1).dec_quant      -- １２月 数量
        ,in_dec_amount     => gr_add_total(1).dec_amount     -- １２月 金額
        ,in_dec_price      => gr_add_total(1).dec_price      -- １２月 品目定価
        ,in_dec_to_amount  => gr_add_total(1).dec_to_amount  -- １２月 内訳合計
        ,in_dec_quant_t    => gr_add_total(1).dec_quant_t    -- １２月 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
        ,in_dec_s_cost     => gr_add_total(1).dec_s_cost     -- １２月 標準原価(計算用)
        ,in_dec_calc       => gr_add_total(1).dec_calc       -- １２月 品目定価*数量(計算用)
        ,in_dec_minus_flg   => gr_add_total(1).dec_minus_flg   -- １２月 数量マイナス値存在フラグ(計算用)
        ,in_dec_ht_zero_flg => gr_add_total(1).dec_ht_zero_flg -- １２月 品目定価*数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
        ,in_jan_quant      => gr_add_total(1).jan_quant      -- １月 数量
        ,in_jan_amount     => gr_add_total(1).jan_amount     -- １月 金額
        ,in_jan_price      => gr_add_total(1).jan_price      -- １月 品目定価
        ,in_jan_to_amount  => gr_add_total(1).jan_to_amount  -- １月 内訳合計
        ,in_jan_quant_t    => gr_add_total(1).jan_quant_t    -- １月 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
        ,in_jan_s_cost     => gr_add_total(1).jan_s_cost     -- １月 標準原価(計算用)
        ,in_jan_calc       => gr_add_total(1).jan_calc       -- １月 品目定価*数量(計算用)
        ,in_jan_minus_flg   => gr_add_total(1).jan_minus_flg   -- １月 数量マイナス値存在フラグ(計算用)
        ,in_jan_ht_zero_flg => gr_add_total(1).jan_ht_zero_flg -- １月 品目定価*数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
        ,in_feb_quant      => gr_add_total(1).feb_quant      -- ２月 数量
        ,in_feb_amount     => gr_add_total(1).feb_amount     -- ２月 金額
        ,in_feb_price      => gr_add_total(1).feb_price      -- ２月 品目定価
        ,in_feb_to_amount  => gr_add_total(1).feb_to_amount  -- ２月 内訳合計
        ,in_feb_quant_t    => gr_add_total(1).feb_quant_t    -- ２月 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
        ,in_feb_s_cost     => gr_add_total(1).feb_s_cost     -- ２月 標準原価(計算用)
        ,in_feb_calc       => gr_add_total(1).feb_calc       -- ２月 品目定価*数量(計算用)
        ,in_feb_minus_flg   => gr_add_total(1).feb_minus_flg   -- ２月 数量マイナス値存在フラグ(計算用)
        ,in_feb_ht_zero_flg => gr_add_total(1).feb_ht_zero_flg -- ２月 品目定価*数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
        ,in_mar_quant      => gr_add_total(1).mar_quant      -- ３月 数量
        ,in_mar_amount     => gr_add_total(1).mar_amount     -- ３月 金額
        ,in_mar_price      => gr_add_total(1).mar_price      -- ３月 品目定価
        ,in_mar_to_amount  => gr_add_total(1).mar_to_amount  -- ３月 内訳合計
        ,in_mar_quant_t    => gr_add_total(1).mar_quant_t    -- ３月 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
        ,in_mar_s_cost     => gr_add_total(1).mar_s_cost     -- ３月 標準原価(計算用)
        ,in_mar_calc       => gr_add_total(1).mar_calc       -- ３月 品目定価*数量(計算用)
        ,in_mar_minus_flg   => gr_add_total(1).mar_minus_flg   -- ３月 数量マイナス値存在フラグ(計算用)
        ,in_mar_ht_zero_flg => gr_add_total(1).mar_ht_zero_flg -- ３月 品目定価*数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
        ,in_apr_quant      => gr_add_total(1).apr_quant      -- ４月 数量
        ,in_apr_amount     => gr_add_total(1).apr_amount     -- ４月 金額
        ,in_apr_price      => gr_add_total(1).apr_price      -- ４月 品目定価
        ,in_apr_to_amount  => gr_add_total(1).apr_to_amount  -- ４月 内訳合計
        ,in_apr_quant_t    => gr_add_total(1).apr_quant_t    -- ４月 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
        ,in_apr_s_cost     => gr_add_total(1).apr_s_cost     -- ４月 標準原価(計算用)
        ,in_apr_calc       => gr_add_total(1).apr_calc       -- ４月 品目定価*数量(計算用)
        ,in_apr_minus_flg   => gr_add_total(1).apr_minus_flg   -- ４月 数量マイナス値存在フラグ(計算用)
        ,in_apr_ht_zero_flg => gr_add_total(1).apr_ht_zero_flg -- ４月 品目定価*数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
        ,in_year_quant     => gr_add_total(1).year_quant     -- 年計 数量
        ,in_year_amount    => gr_add_total(1).year_amount    -- 年計 金額
        ,in_year_price     => gr_add_total(1).year_price     -- 年計 品目定価
        ,in_year_to_amount => gr_add_total(1).year_to_amount -- 年計 内訳合計
        ,in_year_quant_t   => gr_add_total(1).year_quant_t   -- 年計 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
        ,in_year_s_cost    => gr_add_total(1).year_s_cost    -- 年計 標準原価(計算用)
        ,in_year_calc      => gr_add_total(1).year_calc      -- 年計 品目定価*数量(計算用)
        ,in_year_minus_flg   => gr_add_total(1).year_minus_flg   -- 年計 数量マイナス値存在フラグ(計算用)
        ,in_year_ht_zero_flg => gr_add_total(1).year_ht_zero_flg -- 年計 品目定価*数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
        ,ov_errbuf         => lv_errbuf   -- エラー・メッセージ           --# 固定 #
        ,ov_retcode        => lv_retcode  -- リターン・コード             --# 固定 #
        ,ov_errmsg         => lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
      );
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
      --------------------------------------------------------
      -- 大群計データタグ出力 
      --------------------------------------------------------
      prc_create_xml_data_st_lt
      (
         iv_label_name     => gv_name_lt                     -- 大群計用タグ名
        ,iv_name           => gv_label_lt                    -- 大群計タイトル
        ,in_may_quant      => gr_add_total(2).may_quant      -- ５月 数量
        ,in_may_amount     => gr_add_total(2).may_amount     -- ５月 金額
        ,in_may_price      => gr_add_total(2).may_price      -- ５月 品目定価
        ,in_may_to_amount  => gr_add_total(2).may_to_amount  -- ５月 内訳合計
        ,in_may_quant_t    => gr_add_total(2).may_quant_t    -- ５月 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
        ,in_may_s_cost     => gr_add_total(2).may_s_cost     -- ５月 標準原価(計算用)
        ,in_may_calc       => gr_add_total(2).may_calc       -- ５月 品目定価*数量(計算用)
        ,in_may_minus_flg   => gr_add_total(2).may_minus_flg   -- ５月 数量マイナス値存在フラグ(計算用)
        ,in_may_ht_zero_flg => gr_add_total(2).may_ht_zero_flg -- ５月 品目定価*数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
        ,in_jun_quant      => gr_add_total(2).jun_quant      -- ６月 数量
        ,in_jun_amount     => gr_add_total(2).jun_amount     -- ６月 金額
        ,in_jun_price      => gr_add_total(2).jun_price      -- ６月 品目定価
        ,in_jun_to_amount  => gr_add_total(2).jun_to_amount  -- ６月 内訳合計
        ,in_jun_quant_t    => gr_add_total(2).jun_quant_t    -- ６月 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
        ,in_jun_s_cost     => gr_add_total(2).jun_s_cost     -- ６月 標準原価(計算用)
        ,in_jun_calc       => gr_add_total(2).jun_calc       -- ６月 品目定価*数量(計算用)
        ,in_jun_minus_flg   => gr_add_total(2).jun_minus_flg   -- ６月 数量マイナス値存在フラグ(計算用)
        ,in_jun_ht_zero_flg => gr_add_total(2).jun_ht_zero_flg -- ６月 品目定価*数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
        ,in_jul_quant      => gr_add_total(2).jul_quant      -- ７月 数量
        ,in_jul_amount     => gr_add_total(2).jul_amount     -- ７月 金額
        ,in_jul_price      => gr_add_total(2).jul_price      -- ７月 品目定価
        ,in_jul_to_amount  => gr_add_total(2).jul_to_amount  -- ７月 内訳合計
        ,in_jul_quant_t    => gr_add_total(2).jul_quant_t    -- ７月 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
        ,in_jul_s_cost     => gr_add_total(2).jul_s_cost     -- ７月 標準原価(計算用)
        ,in_jul_calc       => gr_add_total(2).jul_calc       -- ７月 品目定価*数量(計算用)
        ,in_jul_minus_flg   => gr_add_total(2).jul_minus_flg   -- ７月 数量マイナス値存在フラグ(計算用)
        ,in_jul_ht_zero_flg => gr_add_total(2).jul_ht_zero_flg -- ７月 品目定価*数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
        ,in_aug_quant      => gr_add_total(2).aug_quant      -- ８月 数量
        ,in_aug_amount     => gr_add_total(2).aug_amount     -- ８月 金額
        ,in_aug_price      => gr_add_total(2).aug_price      -- ８月 品目定価
        ,in_aug_to_amount  => gr_add_total(2).aug_to_amount  -- ８月 内訳合計
        ,in_aug_quant_t    => gr_add_total(2).aug_quant_t    -- ８月 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
        ,in_aug_s_cost     => gr_add_total(2).aug_s_cost     -- ８月 標準原価(計算用)
        ,in_aug_calc       => gr_add_total(2).aug_calc       -- ８月 品目定価*数量(計算用)
        ,in_aug_minus_flg   => gr_add_total(2).aug_minus_flg   -- ８月 数量マイナス値存在フラグ(計算用)
        ,in_aug_ht_zero_flg => gr_add_total(2).aug_ht_zero_flg -- ８月 品目定価*数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
        ,in_sep_quant      => gr_add_total(2).sep_quant      -- ９月 数量
        ,in_sep_amount     => gr_add_total(2).sep_amount     -- ９月 金額
        ,in_sep_price      => gr_add_total(2).sep_price      -- ９月 品目定価
        ,in_sep_to_amount  => gr_add_total(2).sep_to_amount  -- ９月 内訳合計
        ,in_sep_quant_t    => gr_add_total(2).sep_quant_t    -- ９月 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
        ,in_sep_s_cost     => gr_add_total(2).sep_s_cost     -- ９月 標準原価(計算用)
        ,in_sep_calc       => gr_add_total(2).sep_calc       -- ９月 品目定価*数量(計算用)
        ,in_sep_minus_flg   => gr_add_total(2).sep_minus_flg   -- ９月 数量マイナス値存在フラグ(計算用)
        ,in_sep_ht_zero_flg => gr_add_total(2).sep_ht_zero_flg -- ９月 品目定価*数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
        ,in_oct_quant      => gr_add_total(2).oct_quant      -- １０月 数量
        ,in_oct_amount     => gr_add_total(2).oct_amount     -- １０月 金額
        ,in_oct_price      => gr_add_total(2).oct_price      -- １０月 品目定価
        ,in_oct_to_amount  => gr_add_total(2).oct_to_amount  -- １０月 内訳合計
        ,in_oct_quant_t    => gr_add_total(2).oct_quant_t    -- １０月 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
        ,in_oct_s_cost     => gr_add_total(2).oct_s_cost     -- １０月 標準原価(計算用)
        ,in_oct_calc       => gr_add_total(2).oct_calc       -- １０月 品目定価*数量(計算用)
        ,in_oct_minus_flg   => gr_add_total(2).oct_minus_flg   -- １０月 数量マイナス値存在フラグ(計算用)
        ,in_oct_ht_zero_flg => gr_add_total(2).oct_ht_zero_flg -- １０月 品目定価*数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
        ,in_nov_quant      => gr_add_total(2).nov_quant      -- １１月 数量
        ,in_nov_amount     => gr_add_total(2).nov_amount     -- １１月 金額
        ,in_nov_price      => gr_add_total(2).nov_price      -- １１月 品目定価
        ,in_nov_to_amount  => gr_add_total(2).nov_to_amount  -- １１月 内訳合計
        ,in_nov_quant_t    => gr_add_total(2).nov_quant_t    -- １１月 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
        ,in_nov_s_cost     => gr_add_total(2).nov_s_cost     -- １１月 標準原価(計算用)
        ,in_nov_calc       => gr_add_total(2).nov_calc       -- １１月 品目定価*数量(計算用)
        ,in_nov_minus_flg   => gr_add_total(2).nov_minus_flg   -- １１月 数量マイナス値存在フラグ(計算用)
        ,in_nov_ht_zero_flg => gr_add_total(2).nov_ht_zero_flg -- １１月 品目定価*数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
        ,in_dec_quant      => gr_add_total(2).dec_quant      -- １２月 数量
        ,in_dec_amount     => gr_add_total(2).dec_amount     -- １２月 金額
        ,in_dec_price      => gr_add_total(2).dec_price      -- １２月 品目定価
        ,in_dec_to_amount  => gr_add_total(2).dec_to_amount  -- １２月 内訳合計
        ,in_dec_quant_t    => gr_add_total(2).dec_quant_t    -- １２月 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
        ,in_dec_s_cost     => gr_add_total(2).dec_s_cost     -- １２月 標準原価(計算用)
        ,in_dec_calc       => gr_add_total(2).dec_calc       -- １２月 品目定価*数量(計算用)
        ,in_dec_minus_flg   => gr_add_total(2).dec_minus_flg   -- １２月 数量マイナス値存在フラグ(計算用)
        ,in_dec_ht_zero_flg => gr_add_total(2).dec_ht_zero_flg -- １２月 品目定価*数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
        ,in_jan_quant      => gr_add_total(2).jan_quant      -- １月 数量
        ,in_jan_amount     => gr_add_total(2).jan_amount     -- １月 金額
        ,in_jan_price      => gr_add_total(2).jan_price      -- １月 品目定価
        ,in_jan_to_amount  => gr_add_total(2).jan_to_amount  -- １月 内訳合計
        ,in_jan_quant_t    => gr_add_total(2).jan_quant_t    -- １月 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
        ,in_jan_s_cost     => gr_add_total(2).jan_s_cost     -- １月 標準原価(計算用)
        ,in_jan_calc       => gr_add_total(2).jan_calc       -- １月 品目定価*数量(計算用)
        ,in_jan_minus_flg   => gr_add_total(2).jan_minus_flg   -- １月 数量マイナス値存在フラグ(計算用)
        ,in_jan_ht_zero_flg => gr_add_total(2).jan_ht_zero_flg -- １月 品目定価*数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
        ,in_feb_quant      => gr_add_total(2).feb_quant      -- ２月 数量
        ,in_feb_amount     => gr_add_total(2).feb_amount     -- ２月 金額
        ,in_feb_price      => gr_add_total(2).feb_price      -- ２月 品目定価
        ,in_feb_to_amount  => gr_add_total(2).feb_to_amount  -- ２月 内訳合計
        ,in_feb_quant_t    => gr_add_total(2).feb_quant_t    -- ２月 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
        ,in_feb_s_cost     => gr_add_total(2).feb_s_cost     -- ２月 標準原価(計算用)
        ,in_feb_calc       => gr_add_total(2).feb_calc       -- ２月 品目定価*数量(計算用)
        ,in_feb_minus_flg   => gr_add_total(2).feb_minus_flg   -- ２月 数量マイナス値存在フラグ(計算用)
        ,in_feb_ht_zero_flg => gr_add_total(2).feb_ht_zero_flg -- ２月 品目定価*数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
        ,in_mar_quant      => gr_add_total(2).mar_quant      -- ３月 数量
        ,in_mar_amount     => gr_add_total(2).mar_amount     -- ３月 金額
        ,in_mar_price      => gr_add_total(2).mar_price      -- ３月 品目定価
        ,in_mar_to_amount  => gr_add_total(2).mar_to_amount  -- ３月 内訳合計
        ,in_mar_quant_t    => gr_add_total(2).mar_quant_t    -- ３月 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
        ,in_mar_s_cost     => gr_add_total(2).mar_s_cost     -- ３月 標準原価(計算用)
        ,in_mar_calc       => gr_add_total(2).mar_calc       -- ３月 品目定価*数量(計算用)
        ,in_mar_minus_flg   => gr_add_total(2).mar_minus_flg   -- ３月 数量マイナス値存在フラグ(計算用)
        ,in_mar_ht_zero_flg => gr_add_total(2).mar_ht_zero_flg -- ３月 品目定価*数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
        ,in_apr_quant      => gr_add_total(2).apr_quant      -- ４月 数量
        ,in_apr_amount     => gr_add_total(2).apr_amount     -- ４月 金額
        ,in_apr_price      => gr_add_total(2).apr_price      -- ４月 品目定価
        ,in_apr_to_amount  => gr_add_total(2).apr_to_amount  -- ４月 内訳合計
        ,in_apr_quant_t    => gr_add_total(2).apr_quant_t    -- ４月 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
        ,in_apr_s_cost     => gr_add_total(2).apr_s_cost     -- ４月 標準原価(計算用)
        ,in_apr_calc       => gr_add_total(2).apr_calc       -- ４月 品目定価*数量(計算用)
        ,in_apr_minus_flg   => gr_add_total(2).apr_minus_flg   -- ４月 数量マイナス値存在フラグ(計算用)
        ,in_apr_ht_zero_flg => gr_add_total(2).apr_ht_zero_flg -- ４月 品目定価*数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
        ,in_year_quant     => gr_add_total(2).year_quant     -- 年計 数量
        ,in_year_amount    => gr_add_total(2).year_amount    -- 年計 金額
        ,in_year_price     => gr_add_total(2).year_price     -- 年計 品目定価
        ,in_year_to_amount => gr_add_total(2).year_to_amount -- 年計 内訳合計
        ,in_year_quant_t   => gr_add_total(2).year_quant_t   -- 年計 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
        ,in_year_s_cost    => gr_add_total(2).year_s_cost    -- 年計 標準原価(計算用)
        ,in_year_calc      => gr_add_total(2).year_calc      -- 年計 品目定価*数量(計算用)
        ,in_year_minus_flg   => gr_add_total(2).year_minus_flg   -- 年計 数量マイナス値存在フラグ(計算用)
        ,in_year_ht_zero_flg => gr_add_total(2).year_ht_zero_flg -- 年計 品目定価*数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
        ,ov_errbuf         => lv_errbuf   -- エラー・メッセージ           --# 固定 #
        ,ov_retcode        => lv_retcode  -- リターン・コード             --# 固定 #
        ,ov_errmsg         => lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
      );
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
*/
--
      --------------------------------------------------------
      -- (全拠点)(1)小群計/(2)大群計データ出力 
      --------------------------------------------------------
      <<gun_loop>>
      FOR n IN 1..2 LOOP        -- 小群計/大群計
--
        -- 小群計の場合
        IF ( n = 1) THEN
          lv_param_name  := gv_name_st;
          lv_param_label := gv_label_st;
        -- 大群計の場合
        ELSE
          lv_param_name  := gv_name_lt;
          lv_param_label := gv_label_lt;
        END IF;
--
        prc_create_xml_data_st_lt
        (
            iv_label_name      => lv_param_name                   -- 大群計用タグ名
          ,iv_name            => lv_param_label                  -- 大群計タイトル
          ,in_may_quant       => gr_add_total(n).may_quant       -- ５月 数量
          ,in_may_amount      => gr_add_total(n).may_amount      -- ５月 金額
          ,in_may_price       => gr_add_total(n).may_price       -- ５月 品目定価
          ,in_may_to_amount   => gr_add_total(n).may_to_amount   -- ５月 内訳合計
          ,in_may_quant_t     => gr_add_total(n).may_quant_t     -- ５月 数量(計算用)
          ,in_may_s_cost      => gr_add_total(n).may_s_cost      -- ５月 標準原価(計算用)
          ,in_may_calc        => gr_add_total(n).may_calc        -- ５月 品目定価*数量(計算用)
          ,in_may_minus_flg   => gr_add_total(n).may_minus_flg   -- ５月 数量マイナス値存在フラグ(計算用)
          ,in_may_ht_zero_flg => gr_add_total(n).may_ht_zero_flg -- ５月 品目定価*数量(計)
          ,in_jun_quant       => gr_add_total(n).jun_quant       -- ６月 数量
          ,in_jun_amount      => gr_add_total(n).jun_amount      -- ６月 金額
          ,in_jun_price       => gr_add_total(n).jun_price       -- ６月 品目定価
          ,in_jun_to_amount   => gr_add_total(n).jun_to_amount   -- ６月 内訳合計
          ,in_jun_quant_t     => gr_add_total(n).jun_quant_t     -- ６月 数量(計算用)
          ,in_jun_s_cost      => gr_add_total(n).jun_s_cost      -- ６月 標準原価(計算用)
          ,in_jun_calc        => gr_add_total(n).jun_calc        -- ６月 品目定価*数量(計算用)
          ,in_jun_minus_flg   => gr_add_total(n).jun_minus_flg   -- ６月 数量マイナス値存在フラグ(計算用)
          ,in_jun_ht_zero_flg => gr_add_total(n).jun_ht_zero_flg -- ６月 品目定価*数量(計)
          ,in_jul_quant       => gr_add_total(n).jul_quant       -- ７月 数量
          ,in_jul_amount      => gr_add_total(n).jul_amount      -- ７月 金額
          ,in_jul_price       => gr_add_total(n).jul_price       -- ７月 品目定価
          ,in_jul_to_amount   => gr_add_total(n).jul_to_amount   -- ７月 内訳合計
          ,in_jul_quant_t     => gr_add_total(n).jul_quant_t     -- ７月 数量(計算用)
          ,in_jul_s_cost      => gr_add_total(n).jul_s_cost      -- ７月 標準原価(計算用)
          ,in_jul_calc        => gr_add_total(n).jul_calc        -- ７月 品目定価*数量(計算用)
          ,in_jul_minus_flg   => gr_add_total(n).jul_minus_flg   -- ７月 数量マイナス値存在フラグ(計算用)
          ,in_jul_ht_zero_flg => gr_add_total(n).jul_ht_zero_flg -- ７月 品目定価*数量(計)
          ,in_aug_quant       => gr_add_total(n).aug_quant       -- ８月 数量
          ,in_aug_amount      => gr_add_total(n).aug_amount      -- ８月 金額
          ,in_aug_price       => gr_add_total(n).aug_price       -- ８月 品目定価
          ,in_aug_to_amount   => gr_add_total(n).aug_to_amount   -- ８月 内訳合計
          ,in_aug_quant_t     => gr_add_total(n).aug_quant_t     -- ８月 数量(計算用)
          ,in_aug_s_cost      => gr_add_total(n).aug_s_cost      -- ８月 標準原価(計算用)
          ,in_aug_calc        => gr_add_total(n).aug_calc        -- ８月 品目定価*数量(計算用)
          ,in_aug_minus_flg   => gr_add_total(n).aug_minus_flg   -- ８月 数量マイナス値存在フラグ(計算用)
          ,in_aug_ht_zero_flg => gr_add_total(n).aug_ht_zero_flg -- ８月 品目定価*数量(計)
          ,in_sep_quant       => gr_add_total(n).sep_quant       -- ９月 数量
          ,in_sep_amount      => gr_add_total(n).sep_amount      -- ９月 金額
          ,in_sep_price       => gr_add_total(n).sep_price       -- ９月 品目定価
          ,in_sep_to_amount   => gr_add_total(n).sep_to_amount   -- ９月 内訳合計
          ,in_sep_quant_t     => gr_add_total(n).sep_quant_t     -- ９月 数量(計算用)
          ,in_sep_s_cost      => gr_add_total(n).sep_s_cost      -- ９月 標準原価(計算用)
          ,in_sep_calc        => gr_add_total(n).sep_calc        -- ９月 品目定価*数量(計算用)
          ,in_sep_minus_flg   => gr_add_total(n).sep_minus_flg   -- ９月 数量マイナス値存在フラグ(計算用)
          ,in_sep_ht_zero_flg => gr_add_total(n).sep_ht_zero_flg -- ９月 品目定価*数量(計)
          ,in_oct_quant       => gr_add_total(n).oct_quant       -- １０月 数量
          ,in_oct_amount      => gr_add_total(n).oct_amount      -- １０月 金額
          ,in_oct_price       => gr_add_total(n).oct_price       -- １０月 品目定価
          ,in_oct_to_amount   => gr_add_total(n).oct_to_amount   -- １０月 内訳合計
          ,in_oct_quant_t     => gr_add_total(n).oct_quant_t     -- １０月 数量(計算用)
          ,in_oct_s_cost      => gr_add_total(n).oct_s_cost      -- １０月 標準原価(計算用)
          ,in_oct_calc        => gr_add_total(n).oct_calc        -- １０月 品目定価*数量(計算用)
          ,in_oct_minus_flg   => gr_add_total(n).oct_minus_flg   -- １０月 数量マイナス値存在フラグ(計算用)
          ,in_oct_ht_zero_flg => gr_add_total(n).oct_ht_zero_flg -- １０月 品目定価*数量(計)
          ,in_nov_quant       => gr_add_total(n).nov_quant       -- １１月 数量
          ,in_nov_amount      => gr_add_total(n).nov_amount      -- １１月 金額
          ,in_nov_price       => gr_add_total(n).nov_price       -- １１月 品目定価
          ,in_nov_to_amount   => gr_add_total(n).nov_to_amount   -- １１月 内訳合計
          ,in_nov_quant_t     => gr_add_total(n).nov_quant_t     -- １１月 数量(計算用)
          ,in_nov_s_cost      => gr_add_total(n).nov_s_cost      -- １１月 標準原価(計算用)
          ,in_nov_calc        => gr_add_total(n).nov_calc        -- １１月 品目定価*数量(計算用)
          ,in_nov_minus_flg   => gr_add_total(n).nov_minus_flg   -- １１月 数量マイナス値存在フラグ(計算用)
          ,in_nov_ht_zero_flg => gr_add_total(n).nov_ht_zero_flg -- １１月 品目定価*数量(計)
          ,in_dec_quant       => gr_add_total(n).dec_quant       -- １２月 数量
          ,in_dec_amount      => gr_add_total(n).dec_amount      -- １２月 金額
          ,in_dec_price       => gr_add_total(n).dec_price       -- １２月 品目定価
          ,in_dec_to_amount   => gr_add_total(n).dec_to_amount   -- １２月 内訳合計
          ,in_dec_quant_t     => gr_add_total(n).dec_quant_t     -- １２月 数量(計算用)
          ,in_dec_s_cost      => gr_add_total(n).dec_s_cost      -- １２月 標準原価(計算用)
          ,in_dec_calc        => gr_add_total(n).dec_calc        -- １２月 品目定価*数量(計算用)
          ,in_dec_minus_flg   => gr_add_total(n).dec_minus_flg   -- １２月 数量マイナス値存在フラグ(計算用)
          ,in_dec_ht_zero_flg => gr_add_total(n).dec_ht_zero_flg -- １２月 品目定価*数量(計)
          ,in_jan_quant       => gr_add_total(n).jan_quant       -- １月 数量
          ,in_jan_amount      => gr_add_total(n).jan_amount      -- １月 金額
          ,in_jan_price       => gr_add_total(n).jan_price       -- １月 品目定価
          ,in_jan_to_amount   => gr_add_total(n).jan_to_amount   -- １月 内訳合計
          ,in_jan_quant_t     => gr_add_total(n).jan_quant_t     -- １月 数量(計算用)
          ,in_jan_s_cost      => gr_add_total(n).jan_s_cost      -- １月 標準原価(計算用)
          ,in_jan_calc        => gr_add_total(n).jan_calc        -- １月 品目定価*数量(計算用)
          ,in_jan_minus_flg   => gr_add_total(n).jan_minus_flg   -- １月 数量マイナス値存在フラグ(計算用)
          ,in_jan_ht_zero_flg => gr_add_total(n).jan_ht_zero_flg -- １月 品目定価*数量(計)
          ,in_feb_quant       => gr_add_total(n).feb_quant       -- ２月 数量
          ,in_feb_amount      => gr_add_total(n).feb_amount      -- ２月 金額
          ,in_feb_price       => gr_add_total(n).feb_price       -- ２月 品目定価
          ,in_feb_to_amount   => gr_add_total(n).feb_to_amount   -- ２月 内訳合計
          ,in_feb_quant_t     => gr_add_total(n).feb_quant_t     -- ２月 数量(計算用)
          ,in_feb_s_cost      => gr_add_total(n).feb_s_cost      -- ２月 標準原価(計算用)
          ,in_feb_calc        => gr_add_total(n).feb_calc        -- ２月 品目定価*数量(計算用)
          ,in_feb_minus_flg   => gr_add_total(n).feb_minus_flg   -- ２月 数量マイナス値存在フラグ(計算用)
          ,in_feb_ht_zero_flg => gr_add_total(n).feb_ht_zero_flg -- ２月 品目定価*数量(計)
          ,in_mar_quant       => gr_add_total(n).mar_quant       -- ３月 数量
          ,in_mar_amount      => gr_add_total(n).mar_amount      -- ３月 金額
          ,in_mar_price       => gr_add_total(n).mar_price       -- ３月 品目定価
          ,in_mar_to_amount   => gr_add_total(n).mar_to_amount   -- ３月 内訳合計
          ,in_mar_quant_t     => gr_add_total(n).mar_quant_t     -- ３月 数量(計算用)
          ,in_mar_s_cost      => gr_add_total(n).mar_s_cost      -- ３月 標準原価(計算用)
          ,in_mar_calc        => gr_add_total(n).mar_calc        -- ３月 品目定価*数量(計算用)
          ,in_mar_minus_flg   => gr_add_total(n).mar_minus_flg   -- ３月 数量マイナス値存在フラグ(計算用)
          ,in_mar_ht_zero_flg => gr_add_total(n).mar_ht_zero_flg -- ３月 品目定価*数量(計)
          ,in_apr_quant       => gr_add_total(n).apr_quant       -- ４月 数量
          ,in_apr_amount      => gr_add_total(n).apr_amount      -- ４月 金額
          ,in_apr_price       => gr_add_total(n).apr_price       -- ４月 品目定価
          ,in_apr_to_amount   => gr_add_total(n).apr_to_amount   -- ４月 内訳合計
          ,in_apr_quant_t     => gr_add_total(n).apr_quant_t     -- ４月 数量(計算用)
          ,in_apr_s_cost      => gr_add_total(n).apr_s_cost      -- ４月 標準原価(計算用)
          ,in_apr_calc        => gr_add_total(n).apr_calc        -- ４月 品目定価*数量(計算用)
          ,in_apr_minus_flg   => gr_add_total(n).apr_minus_flg   -- ４月 数量マイナス値存在フラグ(計算用)
          ,in_apr_ht_zero_flg => gr_add_total(n).apr_ht_zero_flg -- ４月 品目定価*数量(計)
          ,in_year_quant      => gr_add_total(n).year_quant        -- 年計 数量
          ,in_year_amount     => gr_add_total(n).year_amount       -- 年計 金額
          ,in_year_price      => gr_add_total(n).year_price        -- 年計 品目定価
          ,in_year_to_amount  => gr_add_total(n).year_to_amount    -- 年計 内訳合計
          ,in_year_quant_t    => gr_add_total(n).year_quant_t      -- 年計 数量(計算用)
          ,in_year_s_cost     => gr_add_total(n).year_s_cost       -- 年計 標準原価(計算用)
          ,in_year_calc       => gr_add_total(n).year_calc         -- 年計 品目定価*数量(計算用)
          ,in_year_minus_flg   => gr_add_total(n).year_minus_flg   -- 年計 数量マイナス値存在フラグ(計算用)
          ,in_year_ht_zero_flg => gr_add_total(n).year_ht_zero_flg -- 年計 品目定価*数量(計)
          ,ov_errbuf         => lv_errbuf   -- エラー・メッセージ           --# 固定 #
          ,ov_retcode        => lv_retcode  -- リターン・コード             --# 固定 #
          ,ov_errmsg         => lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
        );
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_process_expt;
        END IF;
--
      END LOOP gun_loop;
--
-- 2009/04/16 v1.6 T.Yoshimoto Mod End 本番#1410
--
      -- -----------------------------------------------------
      -- (全拠点)群コード終了Ｇタグ出力
      -- -----------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1;
      gt_xml_data_table(gl_xml_idx).tag_name  := '/g_gun';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
      -- -----------------------------------------------------
      -- (全拠点)群コード終了ＬＧタグ出力
      -- -----------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1;
      gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_gun_info';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
-- 2009/04/16 v1.6 T.Yoshimoto Mod Start 本番#1410
/*
      --------------------------------------------------------
      -- 拠点計データタグ出力 
      --------------------------------------------------------
      prc_create_xml_data_s_k_t
      (
         iv_label_name     => gv_name_ktn                    -- 拠点計用タグ名
        ,in_may_quant      => gr_add_total(3).may_quant      -- ５月 数量
        ,in_may_amount     => gr_add_total(3).may_amount     -- ５月 金額
        ,in_may_price      => gr_add_total(3).may_price      -- ５月 品目定価
        ,in_may_to_amount  => gr_add_total(3).may_to_amount  -- ５月 内訳合計
        ,in_may_quant_t    => gr_add_total(3).may_quant_t    -- ５月 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
        ,in_may_s_cost     => gr_add_total(3).may_s_cost     -- ５月 標準原価(計算用)
        ,in_may_calc       => gr_add_total(3).may_calc       -- ５月 品目定価*数量(計算用)
        ,in_may_minus_flg   => gr_add_total(3).may_minus_flg   -- ５月 数量マイナス値存在フラグ(計算用)
        ,in_may_ht_zero_flg => gr_add_total(3).may_ht_zero_flg -- ５月 品目定価*数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
        ,in_jun_quant      => gr_add_total(3).jun_quant      -- ６月 数量
        ,in_jun_amount     => gr_add_total(3).jun_amount     -- ６月 金額
        ,in_jun_price      => gr_add_total(3).jun_price      -- ６月 品目定価
        ,in_jun_to_amount  => gr_add_total(3).jun_to_amount  -- ６月 内訳合計
        ,in_jun_quant_t    => gr_add_total(3).jun_quant_t    -- ６月 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
        ,in_jun_s_cost     => gr_add_total(3).jun_s_cost     -- ６月 標準原価(計算用)
        ,in_jun_calc       => gr_add_total(3).jun_calc       -- ６月 品目定価*数量(計算用)
        ,in_jun_minus_flg   => gr_add_total(3).jun_minus_flg   -- ６月 数量マイナス値存在フラグ(計算用)
        ,in_jun_ht_zero_flg => gr_add_total(3).jun_ht_zero_flg -- ６月 品目定価*数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
        ,in_jul_quant      => gr_add_total(3).jul_quant      -- ７月 数量
        ,in_jul_amount     => gr_add_total(3).jul_amount     -- ７月 金額
        ,in_jul_price      => gr_add_total(3).jul_price      -- ７月 品目定価
        ,in_jul_to_amount  => gr_add_total(3).jul_to_amount  -- ７月 内訳合計
        ,in_jul_quant_t    => gr_add_total(3).jul_quant_t    -- ７月 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
        ,in_jul_s_cost     => gr_add_total(3).jul_s_cost     -- ７月 標準原価(計算用)
        ,in_jul_calc       => gr_add_total(3).jul_calc       -- ７月 品目定価*数量(計算用)
        ,in_jul_minus_flg   => gr_add_total(3).jul_minus_flg   -- ７月 数量マイナス値存在フラグ(計算用)
        ,in_jul_ht_zero_flg => gr_add_total(3).jul_ht_zero_flg -- ７月 品目定価*数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
        ,in_aug_quant      => gr_add_total(3).aug_quant      -- ８月 数量
        ,in_aug_amount     => gr_add_total(3).aug_amount     -- ８月 金額
        ,in_aug_price      => gr_add_total(3).aug_price      -- ８月 品目定価
        ,in_aug_to_amount  => gr_add_total(3).aug_to_amount  -- ８月 内訳合計
        ,in_aug_quant_t    => gr_add_total(3).aug_quant_t    -- ８月 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
        ,in_aug_s_cost     => gr_add_total(3).aug_s_cost     -- ８月 標準原価(計算用)
        ,in_aug_calc       => gr_add_total(3).aug_calc       -- ８月 品目定価*数量(計算用)
        ,in_aug_minus_flg   => gr_add_total(3).aug_minus_flg   -- ８月 数量マイナス値存在フラグ(計算用)
        ,in_aug_ht_zero_flg => gr_add_total(3).aug_ht_zero_flg -- ８月 品目定価*数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
        ,in_sep_quant      => gr_add_total(3).sep_quant      -- ９月 数量
        ,in_sep_amount     => gr_add_total(3).sep_amount     -- ９月 金額
        ,in_sep_price      => gr_add_total(3).sep_price      -- ９月 品目定価
        ,in_sep_to_amount  => gr_add_total(3).sep_to_amount  -- ９月 内訳合計
        ,in_sep_quant_t    => gr_add_total(3).sep_quant_t    -- ９月 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
        ,in_sep_s_cost     => gr_add_total(3).sep_s_cost     -- ９月 標準原価(計算用)
        ,in_sep_calc       => gr_add_total(3).sep_calc       -- ９月 品目定価*数量(計算用)
        ,in_sep_minus_flg   => gr_add_total(3).sep_minus_flg   -- ９月 数量マイナス値存在フラグ(計算用)
        ,in_sep_ht_zero_flg => gr_add_total(3).sep_ht_zero_flg -- ９月 品目定価*数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
        ,in_oct_quant      => gr_add_total(3).oct_quant      -- １０月 数量
        ,in_oct_amount     => gr_add_total(3).oct_amount     -- １０月 金額
        ,in_oct_price      => gr_add_total(3).oct_price      -- １０月 品目定価
        ,in_oct_to_amount  => gr_add_total(3).oct_to_amount  -- １０月 内訳合計
        ,in_oct_quant_t    => gr_add_total(3).oct_quant_t    -- １０月 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
        ,in_oct_s_cost     => gr_add_total(3).oct_s_cost     -- １０月 標準原価(計算用)
        ,in_oct_calc       => gr_add_total(3).oct_calc       -- １０月 品目定価*数量(計算用)
        ,in_oct_minus_flg   => gr_add_total(3).oct_minus_flg   -- １０月 数量マイナス値存在フラグ(計算用)
        ,in_oct_ht_zero_flg => gr_add_total(3).oct_ht_zero_flg -- １０月 品目定価*数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
        ,in_nov_quant      => gr_add_total(3).nov_quant      -- １１月 数量
        ,in_nov_amount     => gr_add_total(3).nov_amount     -- １１月 金額
        ,in_nov_price      => gr_add_total(3).nov_price      -- １１月 品目定価
        ,in_nov_to_amount  => gr_add_total(3).nov_to_amount  -- １１月 内訳合計
        ,in_nov_quant_t    => gr_add_total(3).nov_quant_t    -- １１月 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
        ,in_nov_s_cost     => gr_add_total(3).nov_s_cost     -- １１月 標準原価(計算用)
        ,in_nov_calc       => gr_add_total(3).nov_calc       -- １１月 品目定価*数量(計算用)
        ,in_nov_minus_flg   => gr_add_total(3).nov_minus_flg   -- １１月 数量マイナス値存在フラグ(計算用)
        ,in_nov_ht_zero_flg => gr_add_total(3).nov_ht_zero_flg -- １１月 品目定価*数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
        ,in_dec_quant      => gr_add_total(3).dec_quant      -- １２月 数量
        ,in_dec_amount     => gr_add_total(3).dec_amount     -- １２月 金額
        ,in_dec_price      => gr_add_total(3).dec_price      -- １２月 品目定価
        ,in_dec_to_amount  => gr_add_total(3).dec_to_amount  -- １２月 内訳合計
        ,in_dec_quant_t    => gr_add_total(3).dec_quant_t    -- １２月 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
        ,in_dec_s_cost     => gr_add_total(3).dec_s_cost     -- １２月 標準原価(計算用)
        ,in_dec_calc       => gr_add_total(3).dec_calc       -- １２月 品目定価*数量(計算用)
        ,in_dec_minus_flg   => gr_add_total(3).dec_minus_flg   -- １２月 数量マイナス値存在フラグ(計算用)
        ,in_dec_ht_zero_flg => gr_add_total(3).dec_ht_zero_flg -- １２月 品目定価*数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
        ,in_jan_quant      => gr_add_total(3).jan_quant      -- １月 数量
        ,in_jan_amount     => gr_add_total(3).jan_amount     -- １月 金額
        ,in_jan_price      => gr_add_total(3).jan_price      -- １月 品目定価
        ,in_jan_to_amount  => gr_add_total(3).jan_to_amount  -- １月 内訳合計
        ,in_jan_quant_t    => gr_add_total(3).jan_quant_t    -- １月 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
        ,in_jan_s_cost     => gr_add_total(3).jan_s_cost     -- １月 標準原価(計算用)
        ,in_jan_calc       => gr_add_total(3).jan_calc       -- １月 品目定価*数量(計算用)
        ,in_jan_minus_flg   => gr_add_total(3).jan_minus_flg   -- １月 数量マイナス値存在フラグ(計算用)
        ,in_jan_ht_zero_flg => gr_add_total(3).jan_ht_zero_flg -- １月 品目定価*数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
        ,in_feb_quant      => gr_add_total(3).feb_quant      -- ２月 数量
        ,in_feb_amount     => gr_add_total(3).feb_amount     -- ２月 金額
        ,in_feb_price      => gr_add_total(3).feb_price      -- ２月 品目定価
        ,in_feb_to_amount  => gr_add_total(3).feb_to_amount  -- ２月 内訳合計
        ,in_feb_quant_t    => gr_add_total(3).feb_quant_t    -- ２月 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
        ,in_feb_s_cost     => gr_add_total(3).feb_s_cost     -- ２月 標準原価(計算用)
        ,in_feb_calc       => gr_add_total(3).feb_calc       -- ２月 品目定価*数量(計算用)
        ,in_feb_minus_flg   => gr_add_total(3).feb_minus_flg   -- ２月 数量マイナス値存在フラグ(計算用)
        ,in_feb_ht_zero_flg => gr_add_total(3).feb_ht_zero_flg -- ２月 品目定価*数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
        ,in_mar_quant      => gr_add_total(3).mar_quant      -- ３月 数量
        ,in_mar_amount     => gr_add_total(3).mar_amount     -- ３月 金額
        ,in_mar_price      => gr_add_total(3).mar_price      -- ３月 品目定価
        ,in_mar_to_amount  => gr_add_total(3).mar_to_amount  -- ３月 内訳合計
        ,in_mar_quant_t    => gr_add_total(3).mar_quant_t    -- ３月 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
        ,in_mar_s_cost     => gr_add_total(3).mar_s_cost     -- ３月 標準原価(計算用)
        ,in_mar_calc       => gr_add_total(3).mar_calc       -- ３月 品目定価*数量(計算用)
        ,in_mar_minus_flg   => gr_add_total(3).mar_minus_flg   -- ３月 数量マイナス値存在フラグ(計算用)
        ,in_mar_ht_zero_flg => gr_add_total(3).mar_ht_zero_flg -- ３月 品目定価*数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
        ,in_apr_quant      => gr_add_total(3).apr_quant      -- ４月 数量
        ,in_apr_amount     => gr_add_total(3).apr_amount     -- ４月 金額
        ,in_apr_price      => gr_add_total(3).apr_price      -- ４月 品目定価
        ,in_apr_to_amount  => gr_add_total(3).apr_to_amount  -- ４月 内訳合計
        ,in_apr_quant_t    => gr_add_total(3).apr_quant_t    -- ４月 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
        ,in_apr_s_cost     => gr_add_total(3).apr_s_cost     -- ４月 標準原価(計算用)
        ,in_apr_calc       => gr_add_total(3).apr_calc       -- ４月 品目定価*数量(計算用)
        ,in_apr_minus_flg   => gr_add_total(3).apr_minus_flg   -- ４月 数量マイナス値存在フラグ(計算用)
        ,in_apr_ht_zero_flg => gr_add_total(3).apr_ht_zero_flg -- ４月 品目定価*数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
        ,in_year_quant     => gr_add_total(3).year_quant     -- 年計 数量
        ,in_year_amount    => gr_add_total(3).year_amount    -- 年計 金額
        ,in_year_price     => gr_add_total(3).year_price     -- 年計 品目定価
        ,in_year_to_amount => gr_add_total(3).year_to_amount -- 年計 内訳合計
        ,in_year_quant_t   => gr_add_total(3).year_quant_t   -- 年計 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
        ,in_year_s_cost    => gr_add_total(3).year_s_cost    -- 年計 標準原価(計算用)
        ,in_year_calc      => gr_add_total(3).year_calc      -- 年計 品目定価*数量(計算用)
        ,in_year_minus_flg   => gr_add_total(3).year_minus_flg   -- 年計 数量マイナス値存在フラグ(計算用)
        ,in_year_ht_zero_flg => gr_add_total(3).year_ht_zero_flg -- 年計 品目定価*数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
        ,ov_errbuf         => lv_errbuf   -- エラー・メッセージ           --# 固定 #
        ,ov_retcode        => lv_retcode  -- リターン・コード             --# 固定 #
        ,ov_errmsg         => lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
      );
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
      -- -----------------------------------------------------
      --  拠点終了Ｇタグ出力
      -- -----------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1;
      gt_xml_data_table(gl_xml_idx).tag_name  := '/g_ktn';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
      -- -----------------------------------------------------
      --  拠点終了ＬＧタグ出力
      -- -----------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1;
      gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_ktn_info';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
      --------------------------------------------------------
      -- 商品区分計データタグ出力 
      --------------------------------------------------------
      prc_create_xml_data_s_k_t
      (
          iv_label_name     => gv_name_skbn                   -- 商品区分計用タグ名
        ,in_may_quant      => gr_add_total(4).may_quant      -- ５月 数量
        ,in_may_amount     => gr_add_total(4).may_amount     -- ５月 金額
        ,in_may_price      => gr_add_total(4).may_price      -- ５月 品目定価
        ,in_may_to_amount  => gr_add_total(4).may_to_amount  -- ５月 内訳合計
        ,in_may_quant_t    => gr_add_total(4).may_quant_t    -- ５月 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
        ,in_may_s_cost     => gr_add_total(4).may_s_cost     -- ５月 標準原価(計算用)
        ,in_may_calc       => gr_add_total(4).may_calc       -- ５月 品目定価*数量(計算用)
        ,in_may_minus_flg   => gr_add_total(4).may_minus_flg   -- ５月 数量マイナス値存在フラグ(計算用)
        ,in_may_ht_zero_flg => gr_add_total(4).may_ht_zero_flg -- ５月 品目定価*数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
        ,in_jun_quant      => gr_add_total(4).jun_quant      -- ６月 数量
        ,in_jun_amount     => gr_add_total(4).jun_amount     -- ６月 金額
        ,in_jun_price      => gr_add_total(4).jun_price      -- ６月 品目定価
        ,in_jun_to_amount  => gr_add_total(4).jun_to_amount  -- ６月 内訳合計
        ,in_jun_quant_t    => gr_add_total(4).jun_quant_t    -- ６月 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
        ,in_jun_s_cost     => gr_add_total(4).jun_s_cost     -- ６月 標準原価(計算用)
        ,in_jun_calc       => gr_add_total(4).jun_calc       -- ６月 品目定価*数量(計算用)
        ,in_jun_minus_flg   => gr_add_total(4).jun_minus_flg   -- ６月 数量マイナス値存在フラグ(計算用)
        ,in_jun_ht_zero_flg => gr_add_total(4).jun_ht_zero_flg -- ６月 品目定価*数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
        ,in_jul_quant      => gr_add_total(4).jul_quant      -- ７月 数量
        ,in_jul_amount     => gr_add_total(4).jul_amount     -- ７月 金額
        ,in_jul_price      => gr_add_total(4).jul_price      -- ７月 品目定価
        ,in_jul_to_amount  => gr_add_total(4).jul_to_amount  -- ７月 内訳合計
        ,in_jul_quant_t    => gr_add_total(4).jul_quant_t    -- ７月 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
        ,in_jul_s_cost     => gr_add_total(4).jul_s_cost     -- ７月 標準原価(計算用)
        ,in_jul_calc       => gr_add_total(4).jul_calc       -- ７月 品目定価*数量(計算用)
        ,in_jul_minus_flg   => gr_add_total(4).jul_minus_flg   -- ７月 数量マイナス値存在フラグ(計算用)
        ,in_jul_ht_zero_flg => gr_add_total(4).jul_ht_zero_flg -- ７月 品目定価*数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
        ,in_aug_quant      => gr_add_total(4).aug_quant      -- ８月 数量
        ,in_aug_amount     => gr_add_total(4).aug_amount     -- ８月 金額
        ,in_aug_price      => gr_add_total(4).aug_price      -- ８月 品目定価
        ,in_aug_to_amount  => gr_add_total(4).aug_to_amount  -- ８月 内訳合計
        ,in_aug_quant_t    => gr_add_total(4).aug_quant_t    -- ８月 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
        ,in_aug_s_cost     => gr_add_total(4).aug_s_cost     -- ８月 標準原価(計算用)
        ,in_aug_calc       => gr_add_total(4).aug_calc       -- ８月 品目定価*数量(計算用)
        ,in_aug_minus_flg   => gr_add_total(4).aug_minus_flg   -- ８月 数量マイナス値存在フラグ(計算用)
        ,in_aug_ht_zero_flg => gr_add_total(4).aug_ht_zero_flg -- ８月 品目定価*数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
        ,in_sep_quant      => gr_add_total(4).sep_quant      -- ９月 数量
        ,in_sep_amount     => gr_add_total(4).sep_amount     -- ９月 金額
        ,in_sep_price      => gr_add_total(4).sep_price      -- ９月 品目定価
        ,in_sep_to_amount  => gr_add_total(4).sep_to_amount  -- ９月 内訳合計
        ,in_sep_quant_t    => gr_add_total(4).sep_quant_t    -- ９月 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
        ,in_sep_s_cost     => gr_add_total(4).sep_s_cost     -- ９月 標準原価(計算用)
        ,in_sep_calc       => gr_add_total(4).sep_calc       -- ９月 品目定価*数量(計算用)
        ,in_sep_minus_flg   => gr_add_total(4).sep_minus_flg   -- ９月 数量マイナス値存在フラグ(計算用)
        ,in_sep_ht_zero_flg => gr_add_total(4).sep_ht_zero_flg -- ９月 品目定価*数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
        ,in_oct_quant      => gr_add_total(4).oct_quant      -- １０月 数量
        ,in_oct_amount     => gr_add_total(4).oct_amount     -- １０月 金額
        ,in_oct_price      => gr_add_total(4).oct_price      -- １０月 品目定価
        ,in_oct_to_amount  => gr_add_total(4).oct_to_amount  -- １０月 内訳合計
        ,in_oct_quant_t    => gr_add_total(4).oct_quant_t    -- １０月 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
        ,in_oct_s_cost     => gr_add_total(4).oct_s_cost     -- １０月 標準原価(計算用)
        ,in_oct_calc       => gr_add_total(4).oct_calc       -- １０月 品目定価*数量(計算用)
        ,in_oct_minus_flg   => gr_add_total(4).oct_minus_flg   -- １０月 数量マイナス値存在フラグ(計算用)
        ,in_oct_ht_zero_flg => gr_add_total(4).oct_ht_zero_flg -- １０月 品目定価*数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
        ,in_nov_quant      => gr_add_total(4).nov_quant      -- １１月 数量
        ,in_nov_amount     => gr_add_total(4).nov_amount     -- １１月 金額
        ,in_nov_price      => gr_add_total(4).nov_price      -- １１月 品目定価
        ,in_nov_to_amount  => gr_add_total(4).nov_to_amount  -- １１月 内訳合計
        ,in_nov_quant_t    => gr_add_total(4).nov_quant_t    -- １１月 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
        ,in_nov_s_cost     => gr_add_total(4).nov_s_cost     -- １１月 標準原価(計算用)
        ,in_nov_calc       => gr_add_total(4).nov_calc       -- １１月 品目定価*数量(計算用)
        ,in_nov_minus_flg   => gr_add_total(4).nov_minus_flg   -- １１月 数量マイナス値存在フラグ(計算用)
        ,in_nov_ht_zero_flg => gr_add_total(4).nov_ht_zero_flg -- １１月 品目定価*数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
        ,in_dec_quant      => gr_add_total(4).dec_quant      -- １２月 数量
        ,in_dec_amount     => gr_add_total(4).dec_amount     -- １２月 金額
        ,in_dec_price      => gr_add_total(4).dec_price      -- １２月 品目定価
        ,in_dec_to_amount  => gr_add_total(4).dec_to_amount  -- １２月 内訳合計
        ,in_dec_quant_t    => gr_add_total(4).dec_quant_t    -- １２月 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
        ,in_dec_s_cost     => gr_add_total(4).dec_s_cost     -- １２月 標準原価(計算用)
        ,in_dec_calc       => gr_add_total(4).dec_calc       -- １２月 品目定価*数量(計算用)
        ,in_dec_minus_flg   => gr_add_total(4).dec_minus_flg   -- １２月 数量マイナス値存在フラグ(計算用)
        ,in_dec_ht_zero_flg => gr_add_total(4).dec_ht_zero_flg -- １２月 品目定価*数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
        ,in_jan_quant      => gr_add_total(4).jan_quant      -- １月 数量
        ,in_jan_amount     => gr_add_total(4).jan_amount     -- １月 金額
        ,in_jan_price      => gr_add_total(4).jan_price      -- １月 品目定価
        ,in_jan_to_amount  => gr_add_total(4).jan_to_amount  -- １月 内訳合計
        ,in_jan_quant_t    => gr_add_total(4).jan_quant_t    -- １月 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
        ,in_jan_s_cost     => gr_add_total(4).jan_s_cost     -- １月 標準原価(計算用)
        ,in_jan_calc       => gr_add_total(4).jan_calc       -- １月 品目定価*数量(計算用)
        ,in_jan_minus_flg   => gr_add_total(4).jan_minus_flg   -- １月 数量マイナス値存在フラグ(計算用)
        ,in_jan_ht_zero_flg => gr_add_total(4).jan_ht_zero_flg -- １月 品目定価*数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
        ,in_feb_quant      => gr_add_total(4).feb_quant      -- ２月 数量
        ,in_feb_amount     => gr_add_total(4).feb_amount     -- ２月 金額
        ,in_feb_price      => gr_add_total(4).feb_price      -- ２月 品目定価
        ,in_feb_to_amount  => gr_add_total(4).feb_to_amount  -- ２月 内訳合計
        ,in_feb_quant_t    => gr_add_total(4).feb_quant_t    -- ２月 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
        ,in_feb_s_cost     => gr_add_total(4).feb_s_cost     -- ２月 標準原価(計算用)
        ,in_feb_calc       => gr_add_total(4).feb_calc       -- ２月 品目定価*数量(計算用)
        ,in_feb_minus_flg   => gr_add_total(4).feb_minus_flg   -- ２月 数量マイナス値存在フラグ(計算用)
        ,in_feb_ht_zero_flg => gr_add_total(4).feb_ht_zero_flg -- ２月 品目定価*数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
        ,in_mar_quant      => gr_add_total(4).mar_quant      -- ３月 数量
        ,in_mar_amount     => gr_add_total(4).mar_amount     -- ３月 金額
        ,in_mar_price      => gr_add_total(4).mar_price      -- ３月 品目定価
        ,in_mar_to_amount  => gr_add_total(4).mar_to_amount  -- ３月 内訳合計
        ,in_mar_quant_t    => gr_add_total(4).mar_quant_t    -- ３月 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
        ,in_mar_s_cost     => gr_add_total(4).mar_s_cost     -- ３月 標準原価(計算用)
        ,in_mar_calc       => gr_add_total(4).mar_calc       -- ３月 品目定価*数量(計算用)
        ,in_mar_minus_flg   => gr_add_total(4).mar_minus_flg   -- ３月 数量マイナス値存在フラグ(計算用)
        ,in_mar_ht_zero_flg => gr_add_total(4).mar_ht_zero_flg -- ３月 品目定価*数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
        ,in_apr_quant      => gr_add_total(4).apr_quant      -- ４月 数量
        ,in_apr_amount     => gr_add_total(4).apr_amount     -- ４月 金額
        ,in_apr_price      => gr_add_total(4).apr_price      -- ４月 品目定価
        ,in_apr_to_amount  => gr_add_total(4).apr_to_amount  -- ４月 内訳合計
        ,in_apr_quant_t    => gr_add_total(4).apr_quant_t    -- ４月 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
        ,in_apr_s_cost     => gr_add_total(4).apr_s_cost     -- ４月 標準原価(計算用)
        ,in_apr_calc       => gr_add_total(4).apr_calc       -- ４月 品目定価*数量(計算用)
        ,in_apr_minus_flg   => gr_add_total(4).apr_minus_flg   -- ４月 数量マイナス値存在フラグ(計算用)
        ,in_apr_ht_zero_flg => gr_add_total(4).apr_ht_zero_flg -- ４月 品目定価*数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
        ,in_year_quant     => gr_add_total(4).year_quant     -- 年計 数量
        ,in_year_amount    => gr_add_total(4).year_amount    -- 年計 金額
        ,in_year_price     => gr_add_total(4).year_price     -- 年計 品目定価
        ,in_year_to_amount => gr_add_total(4).year_to_amount -- 年計 内訳合計
        ,in_year_quant_t   => gr_add_total(4).year_quant_t   -- 年計 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
        ,in_year_s_cost    => gr_add_total(4).year_s_cost    -- 年計 標準原価(計算用)
        ,in_year_calc      => gr_add_total(4).year_calc      -- 年計 品目定価*数量(計算用)
        ,in_year_minus_flg   => gr_add_total(4).year_minus_flg   -- 年計 数量マイナス値存在フラグ(計算用)
        ,in_year_ht_zero_flg => gr_add_total(4).year_ht_zero_flg -- 年計 品目定価*数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
        ,ov_errbuf         => lv_errbuf   -- エラー・メッセージ           --# 固定 #
        ,ov_retcode        => lv_retcode  -- リターン・コード             --# 固定 #
        ,ov_errmsg         => lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
      );
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
      --------------------------------------------------------
      -- 総合計データタグ出力 
      --------------------------------------------------------
      prc_create_xml_data_s_k_t
      (
        iv_label_name     => gv_name_ttl                    -- 総合計用タグ名
        ,in_may_quant      => gr_add_total(5).may_quant      -- ５月 数量
        ,in_may_amount     => gr_add_total(5).may_amount     -- ５月 金額
        ,in_may_price      => gr_add_total(5).may_price      -- ５月 品目定価
        ,in_may_to_amount  => gr_add_total(5).may_to_amount  -- ５月 内訳合計
        ,in_may_quant_t    => gr_add_total(5).may_quant_t    -- ５月 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
        ,in_may_s_cost     => gr_add_total(5).may_s_cost     -- ５月 標準原価(計算用)
        ,in_may_calc       => gr_add_total(5).may_calc       -- ５月 品目定価*数量(計算用)
        ,in_may_minus_flg   => gr_add_total(5).may_minus_flg   -- ５月 数量マイナス値存在フラグ(計算用)
        ,in_may_ht_zero_flg => gr_add_total(5).may_ht_zero_flg -- ５月 品目定価*数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
        ,in_jun_quant      => gr_add_total(5).jun_quant      -- ６月 数量
        ,in_jun_amount     => gr_add_total(5).jun_amount     -- ６月 金額
        ,in_jun_price      => gr_add_total(5).jun_price      -- ６月 品目定価
        ,in_jun_to_amount  => gr_add_total(5).jun_to_amount  -- ６月 内訳合計
        ,in_jun_quant_t    => gr_add_total(5).jun_quant_t    -- ６月 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
        ,in_jun_s_cost     => gr_add_total(5).jun_s_cost     -- ６月 標準原価(計算用)
        ,in_jun_calc       => gr_add_total(5).jun_calc       -- ６月 品目定価*数量(計算用)
        ,in_jun_minus_flg   => gr_add_total(5).jun_minus_flg   -- ６月 数量マイナス値存在フラグ(計算用)
        ,in_jun_ht_zero_flg => gr_add_total(5).jun_ht_zero_flg -- ６月 品目定価*数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
        ,in_jul_quant      => gr_add_total(5).jul_quant      -- ７月 数量
        ,in_jul_amount     => gr_add_total(5).jul_amount     -- ７月 金額
        ,in_jul_price      => gr_add_total(5).jul_price      -- ７月 品目定価
        ,in_jul_to_amount  => gr_add_total(5).jul_to_amount  -- ７月 内訳合計
        ,in_jul_quant_t    => gr_add_total(5).jul_quant_t    -- ７月 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
        ,in_jul_s_cost     => gr_add_total(5).jul_s_cost     -- ７月 標準原価(計算用)
        ,in_jul_calc       => gr_add_total(5).jul_calc       -- ７月 品目定価*数量(計算用)
        ,in_jul_minus_flg   => gr_add_total(5).jul_minus_flg   -- ７月 数量マイナス値存在フラグ(計算用)
        ,in_jul_ht_zero_flg => gr_add_total(5).jul_ht_zero_flg -- ７月 品目定価*数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
        ,in_aug_quant      => gr_add_total(5).aug_quant      -- ８月 数量
        ,in_aug_amount     => gr_add_total(5).aug_amount     -- ８月 金額
        ,in_aug_price      => gr_add_total(5).aug_price      -- ８月 品目定価
        ,in_aug_to_amount  => gr_add_total(5).aug_to_amount  -- ８月 内訳合計
        ,in_aug_quant_t    => gr_add_total(5).aug_quant_t    -- ８月 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
        ,in_aug_s_cost     => gr_add_total(5).aug_s_cost     -- ８月 標準原価(計算用)
        ,in_aug_calc       => gr_add_total(5).aug_calc       -- ８月 品目定価*数量(計算用)
        ,in_aug_minus_flg   => gr_add_total(5).aug_minus_flg   -- ８月 数量マイナス値存在フラグ(計算用)
        ,in_aug_ht_zero_flg => gr_add_total(5).aug_ht_zero_flg -- ８月 品目定価*数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
        ,in_sep_quant      => gr_add_total(5).sep_quant      -- ９月 数量
        ,in_sep_amount     => gr_add_total(5).sep_amount     -- ９月 金額
        ,in_sep_price      => gr_add_total(5).sep_price      -- ９月 品目定価
        ,in_sep_to_amount  => gr_add_total(5).sep_to_amount  -- ９月 内訳合計
        ,in_sep_quant_t    => gr_add_total(5).sep_quant_t    -- ９月 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
        ,in_sep_s_cost     => gr_add_total(5).sep_s_cost     -- ９月 標準原価(計算用)
        ,in_sep_calc       => gr_add_total(5).sep_calc       -- ９月 品目定価*数量(計算用)
        ,in_sep_minus_flg   => gr_add_total(5).sep_minus_flg   -- ９月 数量マイナス値存在フラグ(計算用)
        ,in_sep_ht_zero_flg => gr_add_total(5).sep_ht_zero_flg -- ９月 品目定価*数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
        ,in_oct_quant      => gr_add_total(5).oct_quant      -- １０月 数量
        ,in_oct_amount     => gr_add_total(5).oct_amount     -- １０月 金額
        ,in_oct_price      => gr_add_total(5).oct_price      -- １０月 品目定価
        ,in_oct_to_amount  => gr_add_total(5).oct_to_amount  -- １０月 内訳合計
        ,in_oct_quant_t    => gr_add_total(5).oct_quant_t    -- １０月 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
        ,in_oct_s_cost     => gr_add_total(5).oct_s_cost     -- １０月 標準原価(計算用)
        ,in_oct_calc       => gr_add_total(5).oct_calc       -- １０月 品目定価*数量(計算用)
        ,in_oct_minus_flg   => gr_add_total(5).oct_minus_flg   -- １０月 数量マイナス値存在フラグ(計算用)
        ,in_oct_ht_zero_flg => gr_add_total(5).oct_ht_zero_flg -- １０月 品目定価*数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
        ,in_nov_quant      => gr_add_total(5).nov_quant      -- １１月 数量
        ,in_nov_amount     => gr_add_total(5).nov_amount     -- １１月 金額
        ,in_nov_price      => gr_add_total(5).nov_price      -- １１月 品目定価
        ,in_nov_to_amount  => gr_add_total(5).nov_to_amount  -- １１月 内訳合計
        ,in_nov_quant_t    => gr_add_total(5).nov_quant_t    -- １１月 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
        ,in_nov_s_cost     => gr_add_total(5).nov_s_cost     -- １１月 標準原価(計算用)
        ,in_nov_calc       => gr_add_total(5).nov_calc       -- １１月 品目定価*数量(計算用)
        ,in_nov_minus_flg   => gr_add_total(5).nov_minus_flg   -- １１月 数量マイナス値存在フラグ(計算用)
        ,in_nov_ht_zero_flg => gr_add_total(5).nov_ht_zero_flg -- １１月 品目定価*数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
        ,in_dec_quant      => gr_add_total(5).dec_quant      -- １２月 数量
        ,in_dec_amount     => gr_add_total(5).dec_amount     -- １２月 金額
        ,in_dec_price      => gr_add_total(5).dec_price      -- １２月 品目定価
        ,in_dec_to_amount  => gr_add_total(5).dec_to_amount  -- １２月 内訳合計
        ,in_dec_quant_t    => gr_add_total(5).dec_quant_t    -- １２月 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
        ,in_dec_s_cost     => gr_add_total(5).dec_s_cost     -- １２月 標準原価(計算用)
        ,in_dec_calc       => gr_add_total(5).dec_calc       -- １２月 品目定価*数量(計算用)
        ,in_dec_minus_flg   => gr_add_total(5).dec_minus_flg   -- １２月 数量マイナス値存在フラグ(計算用)
        ,in_dec_ht_zero_flg => gr_add_total(5).dec_ht_zero_flg -- １２月 品目定価*数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
        ,in_jan_quant      => gr_add_total(5).jan_quant      -- １月 数量
        ,in_jan_amount     => gr_add_total(5).jan_amount     -- １月 金額
        ,in_jan_price      => gr_add_total(5).jan_price      -- １月 品目定価
        ,in_jan_to_amount  => gr_add_total(5).jan_to_amount  -- １月 内訳合計
        ,in_jan_quant_t    => gr_add_total(5).jan_quant_t    -- １月 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
        ,in_jan_s_cost     => gr_add_total(5).jan_s_cost     -- １月 標準原価(計算用)
        ,in_jan_calc       => gr_add_total(5).jan_calc       -- １月 品目定価*数量(計算用)
        ,in_jan_minus_flg   => gr_add_total(5).jan_minus_flg   -- １月 数量マイナス値存在フラグ(計算用)
        ,in_jan_ht_zero_flg => gr_add_total(5).jan_ht_zero_flg -- １月 品目定価*数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
        ,in_feb_quant      => gr_add_total(5).feb_quant      -- ２月 数量
        ,in_feb_amount     => gr_add_total(5).feb_amount     -- ２月 金額
        ,in_feb_price      => gr_add_total(5).feb_price      -- ２月 品目定価
        ,in_feb_to_amount  => gr_add_total(5).feb_to_amount  -- ２月 内訳合計
        ,in_feb_quant_t    => gr_add_total(5).feb_quant_t    -- ２月 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
        ,in_feb_s_cost     => gr_add_total(5).feb_s_cost     -- ２月 標準原価(計算用)
        ,in_feb_calc       => gr_add_total(5).feb_calc       -- ２月 品目定価*数量(計算用)
        ,in_feb_minus_flg   => gr_add_total(5).feb_minus_flg   -- ２月 数量マイナス値存在フラグ(計算用)
        ,in_feb_ht_zero_flg => gr_add_total(5).feb_ht_zero_flg -- ２月 品目定価*数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
        ,in_mar_quant      => gr_add_total(5).mar_quant      -- ３月 数量
        ,in_mar_amount     => gr_add_total(5).mar_amount     -- ３月 金額
        ,in_mar_price      => gr_add_total(5).mar_price      -- ３月 品目定価
        ,in_mar_to_amount  => gr_add_total(5).mar_to_amount  -- ３月 内訳合計
        ,in_mar_quant_t    => gr_add_total(5).mar_quant_t    -- ３月 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
        ,in_mar_s_cost     => gr_add_total(5).mar_s_cost     -- ３月 標準原価(計算用)
        ,in_mar_calc       => gr_add_total(5).mar_calc       -- ３月 品目定価*数量(計算用)
        ,in_mar_minus_flg   => gr_add_total(5).mar_minus_flg   -- ３月 数量マイナス値存在フラグ(計算用)
        ,in_mar_ht_zero_flg => gr_add_total(5).mar_ht_zero_flg -- ３月 品目定価*数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
        ,in_apr_quant      => gr_add_total(5).apr_quant      -- ４月 数量
        ,in_apr_amount     => gr_add_total(5).apr_amount     -- ４月 金額
        ,in_apr_price      => gr_add_total(5).apr_price      -- ４月 品目定価
        ,in_apr_to_amount  => gr_add_total(5).apr_to_amount  -- ４月 内訳合計
        ,in_apr_quant_t    => gr_add_total(5).apr_quant_t    -- ４月 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
        ,in_apr_s_cost     => gr_add_total(5).apr_s_cost     -- ４月 標準原価(計算用)
        ,in_apr_calc       => gr_add_total(5).apr_calc       -- ４月 品目定価*数量(計算用)
        ,in_apr_minus_flg   => gr_add_total(5).apr_minus_flg   -- ４月 数量マイナス値存在フラグ(計算用)
        ,in_apr_ht_zero_flg => gr_add_total(5).apr_ht_zero_flg -- ４月 品目定価*数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
        ,in_year_quant     => gr_add_total(5).year_quant     -- 年計 数量
        ,in_year_amount    => gr_add_total(5).year_amount    -- 年計 金額
        ,in_year_price     => gr_add_total(5).year_price     -- 年計 品目定価
        ,in_year_to_amount => gr_add_total(5).year_to_amount -- 年計 内訳合計
        ,in_year_quant_t   => gr_add_total(5).year_quant_t   -- 年計 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
        ,in_year_s_cost    => gr_add_total(5).year_s_cost    -- 年計 標準原価(計算用)
        ,in_year_calc      => gr_add_total(5).year_calc      -- 年計 品目定価*数量(計算用)
        ,in_year_minus_flg   => gr_add_total(5).year_minus_flg   -- 年計 数量マイナス値存在フラグ(計算用)
        ,in_year_ht_zero_flg => gr_add_total(5).year_ht_zero_flg -- 年計 品目定価*数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
        ,ov_errbuf         => lv_errbuf   -- エラー・メッセージ           --# 固定 #
        ,ov_retcode        => lv_retcode  -- リターン・コード             --# 固定 #
        ,ov_errmsg         => lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
      );
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
*/
      -----------------------------------------------------------
      -- (全拠点)(3)拠点計/(4)商品区分計/(5)総合計データタグ出力 
      -----------------------------------------------------------
      <<kyoten_skbn_total_loop>>
      FOR n IN 3..5 LOOP        -- 拠点計/商品区分計/総合計
--
        -- 拠点計の場合
        IF ( n = 3 ) THEN
          lv_param_label := gv_name_ktn;
--
        -- 商品区分計の場合
        ELSIF ( n = 4 ) THEn
          lv_param_label := gv_name_skbn;
--
        -- 総合計
        ELSE
          lv_param_label := gv_name_ttl;
--
        END IF;
--
        prc_create_xml_data_s_k_t
        (
          iv_label_name       => lv_param_label                   -- 商品区分計用タグ名
          ,in_may_quant       => gr_add_total(n).may_quant      -- ５月 数量
          ,in_may_amount      => gr_add_total(n).may_amount     -- ５月 金額
          ,in_may_price       => gr_add_total(n).may_price      -- ５月 品目定価
          ,in_may_to_amount   => gr_add_total(n).may_to_amount  -- ５月 内訳合計
          ,in_may_quant_t     => gr_add_total(n).may_quant_t    -- ５月 数量(計算用)
          ,in_may_s_cost      => gr_add_total(n).may_s_cost     -- ５月 標準原価(計算用)
          ,in_may_calc        => gr_add_total(n).may_calc       -- ５月 品目定価*数量(計算用)
          ,in_may_minus_flg   => gr_add_total(n).may_minus_flg   -- ５月 数量マイナス値存在フラグ(計算用)
          ,in_may_ht_zero_flg => gr_add_total(n).may_ht_zero_flg -- ５月 品目定価*数量(計)
          ,in_jun_quant       => gr_add_total(n).jun_quant      -- ６月 数量
          ,in_jun_amount      => gr_add_total(n).jun_amount     -- ６月 金額
          ,in_jun_price       => gr_add_total(n).jun_price      -- ６月 品目定価
          ,in_jun_to_amount   => gr_add_total(n).jun_to_amount  -- ６月 内訳合計
          ,in_jun_quant_t     => gr_add_total(n).jun_quant_t    -- ６月 数量(計算用)
          ,in_jun_s_cost      => gr_add_total(n).jun_s_cost     -- ６月 標準原価(計算用)
          ,in_jun_calc        => gr_add_total(n).jun_calc       -- ６月 品目定価*数量(計算用)
          ,in_jun_minus_flg   => gr_add_total(n).jun_minus_flg   -- ６月 数量マイナス値存在フラグ(計算用)
          ,in_jun_ht_zero_flg => gr_add_total(n).jun_ht_zero_flg -- ６月 品目定価*数量(計)
          ,in_jul_quant       => gr_add_total(n).jul_quant      -- ７月 数量
          ,in_jul_amount      => gr_add_total(n).jul_amount     -- ７月 金額
          ,in_jul_price       => gr_add_total(n).jul_price      -- ７月 品目定価
          ,in_jul_to_amount   => gr_add_total(n).jul_to_amount  -- ７月 内訳合計
          ,in_jul_quant_t     => gr_add_total(n).jul_quant_t    -- ７月 数量(計算用)
          ,in_jul_s_cost      => gr_add_total(n).jul_s_cost     -- ７月 標準原価(計算用)
          ,in_jul_calc        => gr_add_total(n).jul_calc       -- ７月 品目定価*数量(計算用)
          ,in_jul_minus_flg   => gr_add_total(n).jul_minus_flg   -- ７月 数量マイナス値存在フラグ(計算用)
          ,in_jul_ht_zero_flg => gr_add_total(n).jul_ht_zero_flg -- ７月 品目定価*数量(計)
          ,in_aug_quant       => gr_add_total(n).aug_quant      -- ８月 数量
          ,in_aug_amount      => gr_add_total(n).aug_amount     -- ８月 金額
          ,in_aug_price       => gr_add_total(n).aug_price      -- ８月 品目定価
          ,in_aug_to_amount   => gr_add_total(n).aug_to_amount  -- ８月 内訳合計
          ,in_aug_quant_t     => gr_add_total(n).aug_quant_t    -- ８月 数量(計算用)
          ,in_aug_s_cost      => gr_add_total(n).aug_s_cost     -- ８月 標準原価(計算用)
          ,in_aug_calc        => gr_add_total(n).aug_calc       -- ８月 品目定価*数量(計算用)
          ,in_aug_minus_flg   => gr_add_total(n).aug_minus_flg   -- ８月 数量マイナス値存在フラグ(計算用)
          ,in_aug_ht_zero_flg => gr_add_total(n).aug_ht_zero_flg -- ８月 品目定価*数量(計)
          ,in_sep_quant       => gr_add_total(n).sep_quant      -- ９月 数量
          ,in_sep_amount      => gr_add_total(n).sep_amount     -- ９月 金額
          ,in_sep_price       => gr_add_total(n).sep_price      -- ９月 品目定価
          ,in_sep_to_amount   => gr_add_total(n).sep_to_amount  -- ９月 内訳合計
          ,in_sep_quant_t     => gr_add_total(n).sep_quant_t    -- ９月 数量(計算用)
          ,in_sep_s_cost      => gr_add_total(n).sep_s_cost     -- ９月 標準原価(計算用)
          ,in_sep_calc        => gr_add_total(n).sep_calc       -- ９月 品目定価*数量(計算用)
          ,in_sep_minus_flg   => gr_add_total(n).sep_minus_flg   -- ９月 数量マイナス値存在フラグ(計算用)
          ,in_sep_ht_zero_flg => gr_add_total(n).sep_ht_zero_flg -- ９月 品目定価*数量(計)
          ,in_oct_quant       => gr_add_total(n).oct_quant      -- １０月 数量
          ,in_oct_amount      => gr_add_total(n).oct_amount     -- １０月 金額
          ,in_oct_price       => gr_add_total(n).oct_price      -- １０月 品目定価
          ,in_oct_to_amount   => gr_add_total(n).oct_to_amount  -- １０月 内訳合計
          ,in_oct_quant_t     => gr_add_total(n).oct_quant_t    -- １０月 数量(計算用)
          ,in_oct_s_cost      => gr_add_total(n).oct_s_cost     -- １０月 標準原価(計算用)
          ,in_oct_calc        => gr_add_total(n).oct_calc       -- １０月 品目定価*数量(計算用)
          ,in_oct_minus_flg   => gr_add_total(n).oct_minus_flg   -- １０月 数量マイナス値存在フラグ(計算用)
          ,in_oct_ht_zero_flg => gr_add_total(n).oct_ht_zero_flg -- １０月 品目定価*数量(計)
          ,in_nov_quant       => gr_add_total(n).nov_quant      -- １１月 数量
          ,in_nov_amount      => gr_add_total(n).nov_amount     -- １１月 金額
          ,in_nov_price       => gr_add_total(n).nov_price      -- １１月 品目定価
          ,in_nov_to_amount   => gr_add_total(n).nov_to_amount  -- １１月 内訳合計
          ,in_nov_quant_t     => gr_add_total(n).nov_quant_t    -- １１月 数量(計算用)
          ,in_nov_s_cost      => gr_add_total(n).nov_s_cost     -- １１月 標準原価(計算用)
          ,in_nov_calc        => gr_add_total(n).nov_calc       -- １１月 品目定価*数量(計算用)
          ,in_nov_minus_flg   => gr_add_total(n).nov_minus_flg   -- １１月 数量マイナス値存在フラグ(計算用)
          ,in_nov_ht_zero_flg => gr_add_total(n).nov_ht_zero_flg -- １１月 品目定価*数量(計)
          ,in_dec_quant       => gr_add_total(n).dec_quant      -- １２月 数量
          ,in_dec_amount      => gr_add_total(n).dec_amount     -- １２月 金額
          ,in_dec_price       => gr_add_total(n).dec_price      -- １２月 品目定価
          ,in_dec_to_amount   => gr_add_total(n).dec_to_amount  -- １２月 内訳合計
          ,in_dec_quant_t     => gr_add_total(n).dec_quant_t    -- １２月 数量(計算用)
          ,in_dec_s_cost      => gr_add_total(n).dec_s_cost     -- １２月 標準原価(計算用)
          ,in_dec_calc        => gr_add_total(n).dec_calc       -- １２月 品目定価*数量(計算用)
          ,in_dec_minus_flg   => gr_add_total(n).dec_minus_flg   -- １２月 数量マイナス値存在フラグ(計算用)
          ,in_dec_ht_zero_flg => gr_add_total(n).dec_ht_zero_flg -- １２月 品目定価*数量(計)
          ,in_jan_quant       => gr_add_total(n).jan_quant      -- １月 数量
          ,in_jan_amount      => gr_add_total(n).jan_amount     -- １月 金額
          ,in_jan_price       => gr_add_total(n).jan_price      -- １月 品目定価
          ,in_jan_to_amount   => gr_add_total(n).jan_to_amount  -- １月 内訳合計
          ,in_jan_quant_t     => gr_add_total(n).jan_quant_t    -- １月 数量(計算用)
          ,in_jan_s_cost      => gr_add_total(n).jan_s_cost     -- １月 標準原価(計算用)
          ,in_jan_calc        => gr_add_total(n).jan_calc       -- １月 品目定価*数量(計算用)
          ,in_jan_minus_flg   => gr_add_total(n).jan_minus_flg   -- １月 数量マイナス値存在フラグ(計算用)
          ,in_jan_ht_zero_flg => gr_add_total(n).jan_ht_zero_flg -- １月 品目定価*数量(計)
          ,in_feb_quant       => gr_add_total(n).feb_quant      -- ２月 数量
          ,in_feb_amount      => gr_add_total(n).feb_amount     -- ２月 金額
          ,in_feb_price       => gr_add_total(n).feb_price      -- ２月 品目定価
          ,in_feb_to_amount   => gr_add_total(n).feb_to_amount  -- ２月 内訳合計
          ,in_feb_quant_t     => gr_add_total(n).feb_quant_t    -- ２月 数量(計算用)
          ,in_feb_s_cost      => gr_add_total(n).feb_s_cost     -- ２月 標準原価(計算用)
          ,in_feb_calc        => gr_add_total(n).feb_calc       -- ２月 品目定価*数量(計算用)
          ,in_feb_minus_flg   => gr_add_total(n).feb_minus_flg   -- ２月 数量マイナス値存在フラグ(計算用)
          ,in_feb_ht_zero_flg => gr_add_total(n).feb_ht_zero_flg -- ２月 品目定価*数量(計)
          ,in_mar_quant       => gr_add_total(n).mar_quant      -- ３月 数量
          ,in_mar_amount      => gr_add_total(n).mar_amount     -- ３月 金額
          ,in_mar_price       => gr_add_total(n).mar_price      -- ３月 品目定価
          ,in_mar_to_amount   => gr_add_total(n).mar_to_amount  -- ３月 内訳合計
          ,in_mar_quant_t     => gr_add_total(n).mar_quant_t    -- ３月 数量(計算用)
          ,in_mar_s_cost      => gr_add_total(n).mar_s_cost     -- ３月 標準原価(計算用)
          ,in_mar_calc        => gr_add_total(n).mar_calc       -- ３月 品目定価*数量(計算用)
          ,in_mar_minus_flg   => gr_add_total(n).mar_minus_flg   -- ３月 数量マイナス値存在フラグ(計算用)
          ,in_mar_ht_zero_flg => gr_add_total(n).mar_ht_zero_flg -- ３月 品目定価*数量(計)
          ,in_apr_quant       => gr_add_total(n).apr_quant      -- ４月 数量
          ,in_apr_amount      => gr_add_total(n).apr_amount     -- ４月 金額
          ,in_apr_price       => gr_add_total(n).apr_price      -- ４月 品目定価
          ,in_apr_to_amount   => gr_add_total(n).apr_to_amount  -- ４月 内訳合計
          ,in_apr_quant_t     => gr_add_total(n).apr_quant_t    -- ４月 数量(計算用)
          ,in_apr_s_cost      => gr_add_total(n).apr_s_cost     -- ４月 標準原価(計算用)
          ,in_apr_calc        => gr_add_total(n).apr_calc       -- ４月 品目定価*数量(計算用)
          ,in_apr_minus_flg   => gr_add_total(n).apr_minus_flg   -- ４月 数量マイナス値存在フラグ(計算用)
          ,in_apr_ht_zero_flg => gr_add_total(n).apr_ht_zero_flg -- ４月 品目定価*数量(計)
          ,in_year_quant      => gr_add_total(n).year_quant     -- 年計 数量
          ,in_year_amount     => gr_add_total(n).year_amount    -- 年計 金額
          ,in_year_price      => gr_add_total(n).year_price     -- 年計 品目定価
          ,in_year_to_amount  => gr_add_total(n).year_to_amount -- 年計 内訳合計
          ,in_year_quant_t    => gr_add_total(n).year_quant_t   -- 年計 数量(計算用)
          ,in_year_s_cost     => gr_add_total(n).year_s_cost    -- 年計 標準原価(計算用)
          ,in_year_calc       => gr_add_total(n).year_calc      -- 年計 品目定価*数量(計算用)
          ,in_year_minus_flg   => gr_add_total(n).year_minus_flg   -- 年計 数量マイナス値存在フラグ(計算用)
          ,in_year_ht_zero_flg => gr_add_total(n).year_ht_zero_flg -- 年計 品目定価*数量(計)
          ,ov_errbuf         => lv_errbuf   -- エラー・メッセージ           --# 固定 #
          ,ov_retcode        => lv_retcode  -- リターン・コード             --# 固定 #
          ,ov_errmsg         => lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
        );
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_process_expt;
        END IF;
--
        -- 拠点計の場合
        IF ( n = 3) THEN
          -- -----------------------------------------------------
          -- (全拠点)拠点終了Ｇタグ出力
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_ktn';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
          -- -----------------------------------------------------
          -- (全拠点)拠点終了ＬＧタグ出力
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_ktn_info';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
        END IF;
    --
      END LOOP kyoten_skbn_total_loop;
-- 2009/04/16 v1.6 T.Yoshimoto Mod End
--
      -- -----------------------------------------------------
      -- (全拠点)商品区分終了Ｇタグ出力
      -- -----------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1;
      gt_xml_data_table(gl_xml_idx).tag_name  := '/g_skbn';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
      -- -----------------------------------------------------
      -- (全拠点)商品区分終了ＬＧタグ出力
      -- -----------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1;
      gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_skbn_info';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
      -- -----------------------------------------------------
      -- (全拠点)データ終了タグ出力
      -- -----------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1;
      gt_xml_data_table(gl_xml_idx).tag_name  := '/data_info';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
      -- -----------------------------------------------------
      -- (全拠点)ルート終了タグ出力
      -- -----------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1;
      gt_xml_data_table(gl_xml_idx).tag_name  := '/root';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
--     ==========================================================
--     -- 入力Ｐ『出力種別』が「拠点ごと」の場合               --
--     ==========================================================
    ELSE
      -- ========================================================
      -- (拠点ごと)データ抽出 - 販売計画時系列表情報抽出 (C-1-2) 
      -- ========================================================
      prc_sale_plan_1
        (
          ot_sale_plan_1    => gr_sale_plan_1     -- 取得レコード群
         ,ov_errbuf         => lv_errbuf          -- エラー・メッセージ           --# 固定 #
         ,ov_retcode        => lv_retcode         -- リターン・コード             --# 固定 #
         ,ov_errmsg         => lv_errmsg          -- ユーザー・エラー・メッセージ --# 固定 #
        );
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      -- 取得データが０件の場合
      ELSIF (gr_sale_plan_1.COUNT = 0) THEN
        RAISE no_data_expt;
      END IF;
--
      -- =====================================================
      -- (拠点ごと)項目データ抽出・タグ出力処理
      -- =====================================================
      -- -----------------------------------------------------
      -- データ開始タグ出力
      -- -----------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'data_info';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
      -- -----------------------------------------------------
      -- 商品区分開始ＬＧタグ出力
      -- -----------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_skbn_info';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--

      -- =====================================================
      -- (拠点ごと)項目データ抽出・出力処理
      -- =====================================================
      <<main_data_loop_1>>
      FOR i IN 1..gr_sale_plan_1.COUNT LOOP
        -- ====================================================
        --  (拠点ごと)商品区分ブレイク
        -- ====================================================
        -- 商品区分が切り替わったとき
        IF (gr_sale_plan_1(i).skbn <> lv_skbn_break) THEN
          -- ====================================================
          --  (拠点ごと)商品区分終了Ｇタグ出力判定
          -- ====================================================
          -- 最初のレコードの時は出力せず
          IF (lv_skbn_break <> lv_break_init) THEN
            -----------------------------------------------------------------
            -- (拠点ごと)各月抽出データが存在しない場合、0表示にてXML出力  --
            -----------------------------------------------------------------
            <<xml_out_0_loop>>
            FOR m IN 1..12 LOOP
              IF (gr_xml_out(m).out_fg = lv_no) THEN
                prc_create_xml_data_dtl_n
                  (
                    iv_label_name     => gr_xml_out(m).tag_name                      -- 出力タグ名
                   ,ov_errbuf         => lv_errbuf   -- エラー・メッセージ           --# 固定 #
                   ,ov_retcode        => lv_retcode  -- リターン・コード             --# 固定 #
                   ,ov_errmsg         => lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
                  );
                IF (lv_retcode = gv_status_error) THEN
                  RAISE global_process_expt;
                END IF;
              END IF;
            END LOOP xml_out_0_loop;
--
            -- -----------------------------------------------------
            -- (拠点ごと)年計 数量データ
            -- -----------------------------------------------------
            gl_xml_idx := gt_xml_data_table.COUNT + 1;
            gt_xml_data_table(gl_xml_idx).tag_name  := 'year_quant';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
            gt_xml_data_table(gl_xml_idx).tag_value := ln_year_quant_sum;
--
            -- -----------------------------------------------------
            -- (拠点ごと)年計 金額データ
            -- -----------------------------------------------------
            gl_xml_idx := gt_xml_data_table.COUNT + 1;
            gt_xml_data_table(gl_xml_idx).tag_name  := 'year_amount';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
            gt_xml_data_table(gl_xml_idx).tag_value := ROUND(ln_year_amount_sum / 1000,0);
--
            -- -----------------------------------------------------
            -- (拠点ごと)年計 粗利率データ
            -- -----------------------------------------------------
            gl_xml_idx := gt_xml_data_table.COUNT + 1;
            gt_xml_data_table(gl_xml_idx).tag_name  := 'year_arari_par';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
--
            ------------------------------------------------
            -- (拠点ごと)粗利計算 (金額－内訳合計＊数量)  --
            ------------------------------------------------
            ln_arari := ln_year_amount_sum - ln_year_to_am_sum * ln_year_quant_sum;
            -- ０除算回避判定
            IF (ln_year_amount_sum <> gn_0) THEN
            -- 値が[0]出なければ計算
            gt_xml_data_table(gl_xml_idx).tag_value := 
                      ROUND((ln_arari / ln_year_amount_sum * 100),2);
            ELSE
              -- 値が[0]の場合は、一律[0]設定
              gt_xml_data_table(gl_xml_idx).tag_value := gn_0;
            END IF;
--
            -- -----------------------------------------------------
            -- (拠点ごと)年計 掛率データ
            -- -----------------------------------------------------
            gl_xml_idx := gt_xml_data_table.COUNT + 1;
            gt_xml_data_table(gl_xml_idx).tag_name  := 'year_kake_par';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
--
            --------------------------------------
            -- ０除算判定項目へ判定値を挿入     --
            --------------------------------------
            ln_chk_0 := ln_year_price_sum * ln_year_quant_sum;
            -- ０除算回避判定
            IF (ln_chk_0 <> gn_0) THEN
            -- 値が[0]出なければ計算
            ln_kake_par := ROUND((ln_year_amount_sum * 100) / ln_chk_0,2);
            ELSE
              -- 値が[0]の場合は、一律[0]設定
              ln_kake_par := gn_0;
            END IF;
--
            -- 品目定価 = ０か、計算結果がマイナスの場合、固定値[70.00]を登録
            IF ((ln_year_price_sum = 0)
              OR (ln_kake_par < 0)) THEN
              ln_kake_par := gn_kotei_70; -- 固定値[70.00]
            END IF;
            gt_xml_data_table(gl_xml_idx).tag_value := ln_kake_par;
--
            -- 各集計項目へデータ挿入
            <<add_total_loop>>
            FOR r IN 1..5 LOOP                     -- 小群計/大群計/拠点計/商品区分計/総合計
              gr_add_total(r).year_quant     :=
                 gr_add_total(r).year_quant     + ln_year_quant_sum;        -- 数量
              gr_add_total(r).year_amount    :=
                 gr_add_total(r).year_amount    + ln_year_amount_sum;       -- 金額
              gr_add_total(r).year_price     :=
                 gr_add_total(r).year_price     + ln_year_price_sum;        -- 品目定価
              gr_add_total(r).year_to_amount :=
                 gr_add_total(r).year_to_amount + ln_year_to_am_sum;        -- 内訳合計
              gr_add_total(r).year_quant_t   :=
                 gr_add_total(r).year_quant_t   + ln_year_quant_sum;        -- 数量(計)
            END LOOP add_total_loop;
--
            -- -----------------------------------------------------
            --  (拠点ごと)品目終了Ｇタグ出力
            -- -----------------------------------------------------
            gl_xml_idx := gt_xml_data_table.COUNT + 1;
            gt_xml_data_table(gl_xml_idx).tag_name  := '/g_dtl';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
            -- -----------------------------------------------------
            --  (拠点ごと)品目終了ＬＧタグ出力
            -- -----------------------------------------------------
            gl_xml_idx := gt_xml_data_table.COUNT + 1;
            gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_dtl_info';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
-- 2009/04/16 v1.6 T.Yoshimoto Mod Start
/*
            --------------------------------------------------------
            -- 小群計データ出力 
            --------------------------------------------------------
            prc_create_xml_data_st_lt
              (
                iv_label_name     => gv_name_st                     -- 小群計用タグ名
               ,iv_name           => gv_label_st                    -- 小群計タイトル
               ,in_may_quant      => gr_add_total(1).may_quant      -- ５月 数量
               ,in_may_amount     => gr_add_total(1).may_amount     -- ５月 金額
               ,in_may_price      => gr_add_total(1).may_price      -- ５月 品目定価
               ,in_may_to_amount  => gr_add_total(1).may_to_amount  -- ５月 内訳合計
               ,in_may_quant_t    => gr_add_total(1).may_quant_t    -- ５月 数量(計算用)
               ,in_jun_quant      => gr_add_total(1).jun_quant      -- ６月 数量
               ,in_jun_amount     => gr_add_total(1).jun_amount     -- ６月 金額
               ,in_jun_price      => gr_add_total(1).jun_price      -- ６月 品目定価
               ,in_jun_to_amount  => gr_add_total(1).jun_to_amount  -- ６月 内訳合計
               ,in_jun_quant_t    => gr_add_total(1).jun_quant_t    -- ６月 数量(計算用)
               ,in_jul_quant      => gr_add_total(1).jul_quant      -- ７月 数量
               ,in_jul_amount     => gr_add_total(1).jul_amount     -- ７月 金額
               ,in_jul_price      => gr_add_total(1).jul_price      -- ７月 品目定価
               ,in_jul_to_amount  => gr_add_total(1).jul_to_amount  -- ７月 内訳合計
               ,in_jul_quant_t    => gr_add_total(1).jul_quant_t    -- ７月 数量(計算用)
               ,in_aug_quant      => gr_add_total(1).aug_quant      -- ８月 数量
               ,in_aug_amount     => gr_add_total(1).aug_amount     -- ８月 金額
               ,in_aug_price      => gr_add_total(1).aug_price      -- ８月 品目定価
               ,in_aug_to_amount  => gr_add_total(1).aug_to_amount  -- ８月 内訳合計
               ,in_aug_quant_t    => gr_add_total(1).aug_quant_t    -- ８月 数量(計算用)
               ,in_sep_quant      => gr_add_total(1).sep_quant      -- ９月 数量
               ,in_sep_amount     => gr_add_total(1).sep_amount     -- ９月 金額
               ,in_sep_price      => gr_add_total(1).sep_price      -- ９月 品目定価
               ,in_sep_to_amount  => gr_add_total(1).sep_to_amount  -- ９月 内訳合計
               ,in_sep_quant_t    => gr_add_total(1).sep_quant_t    -- ９月 数量(計算用)
               ,in_oct_quant      => gr_add_total(1).oct_quant      -- １０月 数量
               ,in_oct_amount     => gr_add_total(1).oct_amount     -- １０月 金額
               ,in_oct_price      => gr_add_total(1).oct_price      -- １０月 品目定価
               ,in_oct_to_amount  => gr_add_total(1).oct_to_amount  -- １０月 内訳合計
               ,in_oct_quant_t    => gr_add_total(1).oct_quant_t    -- １０月 数量(計算用)
               ,in_nov_quant      => gr_add_total(1).nov_quant      -- １１月 数量
               ,in_nov_amount     => gr_add_total(1).nov_amount     -- １１月 金額
               ,in_nov_price      => gr_add_total(1).nov_price      -- １１月 品目定価
               ,in_nov_to_amount  => gr_add_total(1).nov_to_amount  -- １１月 内訳合計
               ,in_nov_quant_t    => gr_add_total(1).nov_quant_t    -- １１月 数量(計算用)
               ,in_dec_quant      => gr_add_total(1).dec_quant      -- １２月 数量
               ,in_dec_amount     => gr_add_total(1).dec_amount     -- １２月 金額
               ,in_dec_price      => gr_add_total(1).dec_price      -- １２月 品目定価
               ,in_dec_to_amount  => gr_add_total(1).dec_to_amount  -- １２月 内訳合計
               ,in_dec_quant_t    => gr_add_total(1).dec_quant_t    -- １２月 数量(計算用)
               ,in_jan_quant      => gr_add_total(1).jan_quant      -- １月 数量
               ,in_jan_amount     => gr_add_total(1).jan_amount     -- １月 金額
               ,in_jan_price      => gr_add_total(1).jan_price      -- １月 品目定価
               ,in_jan_to_amount  => gr_add_total(1).jan_to_amount  -- １月 内訳合計
               ,in_jan_quant_t    => gr_add_total(1).jan_quant_t    -- １月 数量(計算用)
               ,in_feb_quant      => gr_add_total(1).feb_quant      -- ２月 数量
               ,in_feb_amount     => gr_add_total(1).feb_amount     -- ２月 金額
               ,in_feb_price      => gr_add_total(1).feb_price      -- ２月 品目定価
               ,in_feb_to_amount  => gr_add_total(1).feb_to_amount  -- ２月 内訳合計
               ,in_feb_quant_t    => gr_add_total(1).feb_quant_t    -- ２月 数量(計算用)
               ,in_mar_quant      => gr_add_total(1).mar_quant      -- ３月 数量
               ,in_mar_amount     => gr_add_total(1).mar_amount     -- ３月 金額
               ,in_mar_price      => gr_add_total(1).mar_price      -- ３月 品目定価
               ,in_mar_to_amount  => gr_add_total(1).mar_to_amount  -- ３月 内訳合計
               ,in_mar_quant_t    => gr_add_total(1).mar_quant_t    -- ３月 数量(計算用)
               ,in_apr_quant      => gr_add_total(1).apr_quant      -- ４月 数量
               ,in_apr_amount     => gr_add_total(1).apr_amount     -- ４月 金額
               ,in_apr_price      => gr_add_total(1).apr_price      -- ４月 品目定価
               ,in_apr_to_amount  => gr_add_total(1).apr_to_amount  -- ４月 内訳合計
               ,in_apr_quant_t    => gr_add_total(1).apr_quant_t    -- ４月 数量(計算用)
               ,in_year_quant     => gr_add_total(1).year_quant     -- 年計 数量
               ,in_year_amount    => gr_add_total(1).year_amount    -- 年計 金額
               ,in_year_price     => gr_add_total(1).year_price     -- 年計 品目定価
               ,in_year_to_amount => gr_add_total(1).year_to_amount -- 年計 内訳合計
               ,in_year_quant_t   => gr_add_total(1).year_quant_t   -- 年計 数量(計算用)
               ,ov_errbuf         => lv_errbuf   -- エラー・メッセージ           --# 固定 #
               ,ov_retcode        => lv_retcode  -- リターン・コード             --# 固定 #
               ,ov_errmsg         => lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
              );
            IF (lv_retcode = gv_status_error) THEN
              RAISE global_process_expt;
            END IF;
--
            --------------------------------------------------------
            -- 大群計データ出力 
            --------------------------------------------------------
            prc_create_xml_data_st_lt
              (
                iv_label_name     => gv_name_lt                     -- 大群計用タグ名
               ,iv_name           => gv_label_lt                    -- 大群計タイトル
               ,in_may_quant      => gr_add_total(2).may_quant      -- ５月 数量
               ,in_may_amount     => gr_add_total(2).may_amount     -- ５月 金額
               ,in_may_price      => gr_add_total(2).may_price      -- ５月 品目定価
               ,in_may_to_amount  => gr_add_total(2).may_to_amount  -- ５月 内訳合計
               ,in_may_quant_t    => gr_add_total(2).may_quant_t    -- ５月 数量(計算用)
               ,in_jun_quant      => gr_add_total(2).jun_quant      -- ６月 数量
               ,in_jun_amount     => gr_add_total(2).jun_amount     -- ６月 金額
               ,in_jun_price      => gr_add_total(2).jun_price      -- ６月 品目定価
               ,in_jun_to_amount  => gr_add_total(2).jun_to_amount  -- ６月 内訳合計
               ,in_jun_quant_t    => gr_add_total(2).jun_quant_t    -- ６月 数量(計算用)
               ,in_jul_quant      => gr_add_total(2).jul_quant      -- ７月 数量
               ,in_jul_amount     => gr_add_total(2).jul_amount     -- ７月 金額
               ,in_jul_price      => gr_add_total(2).jul_price      -- ７月 品目定価
               ,in_jul_to_amount  => gr_add_total(2).jul_to_amount  -- ７月 内訳合計
               ,in_jul_quant_t    => gr_add_total(2).jul_quant_t    -- ７月 数量(計算用)
               ,in_aug_quant      => gr_add_total(2).aug_quant      -- ８月 数量
               ,in_aug_amount     => gr_add_total(2).aug_amount     -- ８月 金額
               ,in_aug_price      => gr_add_total(2).aug_price      -- ８月 品目定価
               ,in_aug_to_amount  => gr_add_total(2).aug_to_amount  -- ８月 内訳合計
               ,in_aug_quant_t    => gr_add_total(2).aug_quant_t    -- ８月 数量(計算用)
               ,in_sep_quant      => gr_add_total(2).sep_quant      -- ９月 数量
               ,in_sep_amount     => gr_add_total(2).sep_amount     -- ９月 金額
               ,in_sep_price      => gr_add_total(2).sep_price      -- ９月 品目定価
               ,in_sep_to_amount  => gr_add_total(2).sep_to_amount  -- ９月 内訳合計
               ,in_sep_quant_t    => gr_add_total(2).sep_quant_t    -- ９月 数量(計算用)
               ,in_oct_quant      => gr_add_total(2).oct_quant      -- １０月 数量
               ,in_oct_amount     => gr_add_total(2).oct_amount     -- １０月 金額
               ,in_oct_price      => gr_add_total(2).oct_price      -- １０月 品目定価
               ,in_oct_to_amount  => gr_add_total(2).oct_to_amount  -- １０月 内訳合計
               ,in_oct_quant_t    => gr_add_total(2).oct_quant_t    -- １０月 数量(計算用)
               ,in_nov_quant      => gr_add_total(2).nov_quant      -- １１月 数量
               ,in_nov_amount     => gr_add_total(2).nov_amount     -- １１月 金額
               ,in_nov_price      => gr_add_total(2).nov_price      -- １１月 品目定価
               ,in_nov_to_amount  => gr_add_total(2).nov_to_amount  -- １１月 内訳合計
               ,in_nov_quant_t    => gr_add_total(2).nov_quant_t    -- １１月 数量(計算用)
               ,in_dec_quant      => gr_add_total(2).dec_quant      -- １２月 数量
               ,in_dec_amount     => gr_add_total(2).dec_amount     -- １２月 金額
               ,in_dec_price      => gr_add_total(2).dec_price      -- １２月 品目定価
               ,in_dec_to_amount  => gr_add_total(2).dec_to_amount  -- １２月 内訳合計
               ,in_dec_quant_t    => gr_add_total(2).dec_quant_t    -- １２月 数量(計算用)
               ,in_jan_quant      => gr_add_total(2).jan_quant      -- １月 数量
               ,in_jan_amount     => gr_add_total(2).jan_amount     -- １月 金額
               ,in_jan_price      => gr_add_total(2).jan_price      -- １月 品目定価
               ,in_jan_to_amount  => gr_add_total(2).jan_to_amount  -- １月 内訳合計
               ,in_jan_quant_t    => gr_add_total(2).jan_quant_t    -- １月 数量(計算用)
               ,in_feb_quant      => gr_add_total(2).feb_quant      -- ２月 数量
               ,in_feb_amount     => gr_add_total(2).feb_amount     -- ２月 金額
               ,in_feb_price      => gr_add_total(2).feb_price      -- ２月 品目定価
               ,in_feb_to_amount  => gr_add_total(2).feb_to_amount  -- ２月 内訳合計
               ,in_feb_quant_t    => gr_add_total(2).feb_quant_t    -- ２月 数量(計算用)
               ,in_mar_quant      => gr_add_total(2).mar_quant      -- ３月 数量
               ,in_mar_amount     => gr_add_total(2).mar_amount     -- ３月 金額
               ,in_mar_price      => gr_add_total(2).mar_price      -- ３月 品目定価
               ,in_mar_to_amount  => gr_add_total(2).mar_to_amount  -- ３月 内訳合計
               ,in_mar_quant_t    => gr_add_total(2).mar_quant_t    -- ３月 数量(計算用)
               ,in_apr_quant      => gr_add_total(2).apr_quant      -- ４月 数量
               ,in_apr_amount     => gr_add_total(2).apr_amount     -- ４月 金額
               ,in_apr_price      => gr_add_total(2).apr_price      -- ４月 品目定価
               ,in_apr_to_amount  => gr_add_total(2).apr_to_amount  -- ４月 内訳合計
               ,in_apr_quant_t    => gr_add_total(2).apr_quant_t    -- ４月 数量(計算用)
               ,in_year_quant     => gr_add_total(2).year_quant     -- 年計 数量
               ,in_year_amount    => gr_add_total(2).year_amount    -- 年計 金額
               ,in_year_price     => gr_add_total(2).year_price     -- 年計 品目定価
               ,in_year_to_amount => gr_add_total(2).year_to_amount -- 年計 内訳合計
               ,in_year_quant_t   => gr_add_total(2).year_quant_t   -- 年計 数量(計算用)
               ,ov_errbuf         => lv_errbuf   -- エラー・メッセージ           --# 固定 #
               ,ov_retcode        => lv_retcode  -- リターン・コード             --# 固定 #
               ,ov_errmsg         => lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
              );
            IF (lv_retcode = gv_status_error) THEN
              RAISE global_process_expt;
            END IF;
--
*/
            --------------------------------------------------------
            -- (拠点ごと)(1)小群計/(2)大群計データ出力 
            --------------------------------------------------------
            <<gun_loop>>
            FOR n IN 1..2 LOOP        -- 小群計/大群計
--
              -- 小群計の場合
              IF ( n = 1) THEN
                lv_param_name  := gv_name_st;
                lv_param_label := gv_label_st;
              -- 大群計の場合
              ELSE
                lv_param_name  := gv_name_lt;
                lv_param_label := gv_label_lt;
              END IF;
--
              prc_create_xml_data_st_lt
              (
                 iv_label_name      => lv_param_name                   -- 大群計用タグ名
                ,iv_name            => lv_param_label                  -- 大群計タイトル
                ,in_may_quant       => gr_add_total(n).may_quant       -- ５月 数量
                ,in_may_amount      => gr_add_total(n).may_amount      -- ５月 金額
                ,in_may_price       => gr_add_total(n).may_price       -- ５月 品目定価
                ,in_may_to_amount   => gr_add_total(n).may_to_amount   -- ５月 内訳合計
                ,in_may_quant_t     => gr_add_total(n).may_quant_t     -- ５月 数量(計算用)
                ,in_may_s_cost      => gr_add_total(n).may_s_cost      -- ５月 標準原価(計算用)
                ,in_may_calc        => gr_add_total(n).may_calc        -- ５月 品目定価*数量(計算用)
                ,in_may_minus_flg   => gr_add_total(n).may_minus_flg   -- ５月 数量マイナス値存在フラグ(計算用)
                ,in_may_ht_zero_flg => gr_add_total(n).may_ht_zero_flg -- ５月 品目定価*数量(計)
                ,in_jun_quant       => gr_add_total(n).jun_quant       -- ６月 数量
                ,in_jun_amount      => gr_add_total(n).jun_amount      -- ６月 金額
                ,in_jun_price       => gr_add_total(n).jun_price       -- ６月 品目定価
                ,in_jun_to_amount   => gr_add_total(n).jun_to_amount   -- ６月 内訳合計
                ,in_jun_quant_t     => gr_add_total(n).jun_quant_t     -- ６月 数量(計算用)
                ,in_jun_s_cost      => gr_add_total(n).jun_s_cost      -- ６月 標準原価(計算用)
                ,in_jun_calc        => gr_add_total(n).jun_calc        -- ６月 品目定価*数量(計算用)
                ,in_jun_minus_flg   => gr_add_total(n).jun_minus_flg   -- ６月 数量マイナス値存在フラグ(計算用)
                ,in_jun_ht_zero_flg => gr_add_total(n).jun_ht_zero_flg -- ６月 品目定価*数量(計)
                ,in_jul_quant       => gr_add_total(n).jul_quant       -- ７月 数量
                ,in_jul_amount      => gr_add_total(n).jul_amount      -- ７月 金額
                ,in_jul_price       => gr_add_total(n).jul_price       -- ７月 品目定価
                ,in_jul_to_amount   => gr_add_total(n).jul_to_amount   -- ７月 内訳合計
                ,in_jul_quant_t     => gr_add_total(n).jul_quant_t     -- ７月 数量(計算用)
                ,in_jul_s_cost      => gr_add_total(n).jul_s_cost      -- ７月 標準原価(計算用)
                ,in_jul_calc        => gr_add_total(n).jul_calc        -- ７月 品目定価*数量(計算用)
                ,in_jul_minus_flg   => gr_add_total(n).jul_minus_flg   -- ７月 数量マイナス値存在フラグ(計算用)
                ,in_jul_ht_zero_flg => gr_add_total(n).jul_ht_zero_flg -- ７月 品目定価*数量(計)
                ,in_aug_quant       => gr_add_total(n).aug_quant       -- ８月 数量
                ,in_aug_amount      => gr_add_total(n).aug_amount      -- ８月 金額
                ,in_aug_price       => gr_add_total(n).aug_price       -- ８月 品目定価
                ,in_aug_to_amount   => gr_add_total(n).aug_to_amount   -- ８月 内訳合計
                ,in_aug_quant_t     => gr_add_total(n).aug_quant_t     -- ８月 数量(計算用)
                ,in_aug_s_cost      => gr_add_total(n).aug_s_cost      -- ８月 標準原価(計算用)
                ,in_aug_calc        => gr_add_total(n).aug_calc        -- ８月 品目定価*数量(計算用)
                ,in_aug_minus_flg   => gr_add_total(n).aug_minus_flg   -- ８月 数量マイナス値存在フラグ(計算用)
                ,in_aug_ht_zero_flg => gr_add_total(n).aug_ht_zero_flg -- ８月 品目定価*数量(計)
                ,in_sep_quant       => gr_add_total(n).sep_quant       -- ９月 数量
                ,in_sep_amount      => gr_add_total(n).sep_amount      -- ９月 金額
                ,in_sep_price       => gr_add_total(n).sep_price       -- ９月 品目定価
                ,in_sep_to_amount   => gr_add_total(n).sep_to_amount   -- ９月 内訳合計
                ,in_sep_quant_t     => gr_add_total(n).sep_quant_t     -- ９月 数量(計算用)
                ,in_sep_s_cost      => gr_add_total(n).sep_s_cost      -- ９月 標準原価(計算用)
                ,in_sep_calc        => gr_add_total(n).sep_calc        -- ９月 品目定価*数量(計算用)
                ,in_sep_minus_flg   => gr_add_total(n).sep_minus_flg   -- ９月 数量マイナス値存在フラグ(計算用)
                ,in_sep_ht_zero_flg => gr_add_total(n).sep_ht_zero_flg -- ９月 品目定価*数量(計)
                ,in_oct_quant       => gr_add_total(n).oct_quant       -- １０月 数量
                ,in_oct_amount      => gr_add_total(n).oct_amount      -- １０月 金額
                ,in_oct_price       => gr_add_total(n).oct_price       -- １０月 品目定価
                ,in_oct_to_amount   => gr_add_total(n).oct_to_amount   -- １０月 内訳合計
                ,in_oct_quant_t     => gr_add_total(n).oct_quant_t     -- １０月 数量(計算用)
                ,in_oct_s_cost      => gr_add_total(n).oct_s_cost      -- １０月 標準原価(計算用)
                ,in_oct_calc        => gr_add_total(n).oct_calc        -- １０月 品目定価*数量(計算用)
                ,in_oct_minus_flg   => gr_add_total(n).oct_minus_flg   -- １０月 数量マイナス値存在フラグ(計算用)
                ,in_oct_ht_zero_flg => gr_add_total(n).oct_ht_zero_flg -- １０月 品目定価*数量(計)
                ,in_nov_quant       => gr_add_total(n).nov_quant       -- １１月 数量
                ,in_nov_amount      => gr_add_total(n).nov_amount      -- １１月 金額
                ,in_nov_price       => gr_add_total(n).nov_price       -- １１月 品目定価
                ,in_nov_to_amount   => gr_add_total(n).nov_to_amount   -- １１月 内訳合計
                ,in_nov_quant_t     => gr_add_total(n).nov_quant_t     -- １１月 数量(計算用)
                ,in_nov_s_cost      => gr_add_total(n).nov_s_cost      -- １１月 標準原価(計算用)
                ,in_nov_calc        => gr_add_total(n).nov_calc        -- １１月 品目定価*数量(計算用)
                ,in_nov_minus_flg   => gr_add_total(n).nov_minus_flg   -- １１月 数量マイナス値存在フラグ(計算用)
                ,in_nov_ht_zero_flg => gr_add_total(n).nov_ht_zero_flg -- １１月 品目定価*数量(計)
                ,in_dec_quant       => gr_add_total(n).dec_quant       -- １２月 数量
                ,in_dec_amount      => gr_add_total(n).dec_amount      -- １２月 金額
                ,in_dec_price       => gr_add_total(n).dec_price       -- １２月 品目定価
                ,in_dec_to_amount   => gr_add_total(n).dec_to_amount   -- １２月 内訳合計
                ,in_dec_quant_t     => gr_add_total(n).dec_quant_t     -- １２月 数量(計算用)
                ,in_dec_s_cost      => gr_add_total(n).dec_s_cost      -- １２月 標準原価(計算用)
                ,in_dec_calc        => gr_add_total(n).dec_calc        -- １２月 品目定価*数量(計算用)
                ,in_dec_minus_flg   => gr_add_total(n).dec_minus_flg   -- １２月 数量マイナス値存在フラグ(計算用)
                ,in_dec_ht_zero_flg => gr_add_total(n).dec_ht_zero_flg -- １２月 品目定価*数量(計)
                ,in_jan_quant       => gr_add_total(n).jan_quant       -- １月 数量
                ,in_jan_amount      => gr_add_total(n).jan_amount      -- １月 金額
                ,in_jan_price       => gr_add_total(n).jan_price       -- １月 品目定価
                ,in_jan_to_amount   => gr_add_total(n).jan_to_amount   -- １月 内訳合計
                ,in_jan_quant_t     => gr_add_total(n).jan_quant_t     -- １月 数量(計算用)
                ,in_jan_s_cost      => gr_add_total(n).jan_s_cost      -- １月 標準原価(計算用)
                ,in_jan_calc        => gr_add_total(n).jan_calc        -- １月 品目定価*数量(計算用)
                ,in_jan_minus_flg   => gr_add_total(n).jan_minus_flg   -- １月 数量マイナス値存在フラグ(計算用)
                ,in_jan_ht_zero_flg => gr_add_total(n).jan_ht_zero_flg -- １月 品目定価*数量(計)
                ,in_feb_quant       => gr_add_total(n).feb_quant       -- ２月 数量
                ,in_feb_amount      => gr_add_total(n).feb_amount      -- ２月 金額
                ,in_feb_price       => gr_add_total(n).feb_price       -- ２月 品目定価
                ,in_feb_to_amount   => gr_add_total(n).feb_to_amount   -- ２月 内訳合計
                ,in_feb_quant_t     => gr_add_total(n).feb_quant_t     -- ２月 数量(計算用)
                ,in_feb_s_cost      => gr_add_total(n).feb_s_cost      -- ２月 標準原価(計算用)
                ,in_feb_calc        => gr_add_total(n).feb_calc        -- ２月 品目定価*数量(計算用)
                ,in_feb_minus_flg   => gr_add_total(n).feb_minus_flg   -- ２月 数量マイナス値存在フラグ(計算用)
                ,in_feb_ht_zero_flg => gr_add_total(n).feb_ht_zero_flg -- ２月 品目定価*数量(計)
                ,in_mar_quant       => gr_add_total(n).mar_quant       -- ３月 数量
                ,in_mar_amount      => gr_add_total(n).mar_amount      -- ３月 金額
                ,in_mar_price       => gr_add_total(n).mar_price       -- ３月 品目定価
                ,in_mar_to_amount   => gr_add_total(n).mar_to_amount   -- ３月 内訳合計
                ,in_mar_quant_t     => gr_add_total(n).mar_quant_t     -- ３月 数量(計算用)
                ,in_mar_s_cost      => gr_add_total(n).mar_s_cost      -- ３月 標準原価(計算用)
                ,in_mar_calc        => gr_add_total(n).mar_calc        -- ３月 品目定価*数量(計算用)
                ,in_mar_minus_flg   => gr_add_total(n).mar_minus_flg   -- ３月 数量マイナス値存在フラグ(計算用)
                ,in_mar_ht_zero_flg => gr_add_total(n).mar_ht_zero_flg -- ３月 品目定価*数量(計)
                ,in_apr_quant       => gr_add_total(n).apr_quant       -- ４月 数量
                ,in_apr_amount      => gr_add_total(n).apr_amount      -- ４月 金額
                ,in_apr_price       => gr_add_total(n).apr_price       -- ４月 品目定価
                ,in_apr_to_amount   => gr_add_total(n).apr_to_amount   -- ４月 内訳合計
                ,in_apr_quant_t     => gr_add_total(n).apr_quant_t     -- ４月 数量(計算用)
                ,in_apr_s_cost      => gr_add_total(n).apr_s_cost      -- ４月 標準原価(計算用)
                ,in_apr_calc        => gr_add_total(n).apr_calc        -- ４月 品目定価*数量(計算用)
                ,in_apr_minus_flg   => gr_add_total(n).apr_minus_flg   -- ４月 数量マイナス値存在フラグ(計算用)
                ,in_apr_ht_zero_flg => gr_add_total(n).apr_ht_zero_flg -- ４月 品目定価*数量(計)
                ,in_year_quant      => gr_add_total(n).year_quant        -- 年計 数量
                ,in_year_amount     => gr_add_total(n).year_amount       -- 年計 金額
                ,in_year_price      => gr_add_total(n).year_price        -- 年計 品目定価
                ,in_year_to_amount  => gr_add_total(n).year_to_amount    -- 年計 内訳合計
                ,in_year_quant_t    => gr_add_total(n).year_quant_t      -- 年計 数量(計算用)
                ,in_year_s_cost     => gr_add_total(n).year_s_cost       -- 年計 標準原価(計算用)
                ,in_year_calc       => gr_add_total(n).year_calc         -- 年計 品目定価*数量(計算用)
                ,in_year_minus_flg   => gr_add_total(n).year_minus_flg   -- 年計 数量マイナス値存在フラグ(計算用)
                ,in_year_ht_zero_flg => gr_add_total(n).year_ht_zero_flg -- 年計 品目定価*数量(計)
                ,ov_errbuf         => lv_errbuf   -- エラー・メッセージ           --# 固定 #
                ,ov_retcode        => lv_retcode  -- リターン・コード             --# 固定 #
                ,ov_errmsg         => lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
              );
              IF (lv_retcode = gv_status_error) THEN
                RAISE global_process_expt;
              END IF;
--
            END LOOP gun_loop;
--
-- 2009/04/16 v1.6 T.Yoshimoto Mod End
            -- -----------------------------------------------------
            --  群コード終了Ｇタグ出力
            -- -----------------------------------------------------
            gl_xml_idx := gt_xml_data_table.COUNT + 1;
            gt_xml_data_table(gl_xml_idx).tag_name  := '/g_gun';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
-- 
            -- -----------------------------------------------------
            --  群コード終了ＬＧタグ出力
            -- -----------------------------------------------------
            gl_xml_idx := gt_xml_data_table.COUNT + 1;
            gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_gun_info';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
-- 2009/04/16 v1.6 T.Yoshimoto Mod Start
/*
            --------------------------------------------------------
            -- 拠点計データタグ出力 
            --------------------------------------------------------
            prc_create_xml_data_s_k_t
              (
                iv_label_name     => gv_name_ktn                    -- 拠点計用タグ名
               ,in_may_quant      => gr_add_total(3).may_quant      -- ５月 数量
               ,in_may_amount     => gr_add_total(3).may_amount     -- ５月 金額
               ,in_may_price      => gr_add_total(3).may_price      -- ５月 品目定価
               ,in_may_to_amount  => gr_add_total(3).may_to_amount  -- ５月 内訳合計
               ,in_jun_quant      => gr_add_total(3).jun_quant      -- ６月 数量
               ,in_jun_amount     => gr_add_total(3).jun_amount     -- ６月 金額
               ,in_jun_price      => gr_add_total(3).jun_price      -- ６月 品目定価
               ,in_jun_to_amount  => gr_add_total(3).jun_to_amount  -- ６月 内訳合計
               ,in_jul_quant      => gr_add_total(3).jul_quant      -- ７月 数量
               ,in_jul_amount     => gr_add_total(3).jul_amount     -- ７月 金額
               ,in_jul_price      => gr_add_total(3).jul_price      -- ７月 品目定価
               ,in_jul_to_amount  => gr_add_total(3).jul_to_amount  -- ７月 内訳合計
               ,in_aug_quant      => gr_add_total(3).aug_quant      -- ８月 数量
               ,in_aug_amount     => gr_add_total(3).aug_amount     -- ８月 金額
               ,in_aug_price      => gr_add_total(3).aug_price      -- ８月 品目定価
               ,in_aug_to_amount  => gr_add_total(3).aug_to_amount  -- ８月 内訳合計
               ,in_sep_quant      => gr_add_total(3).sep_quant      -- ９月 数量
               ,in_sep_amount     => gr_add_total(3).sep_amount     -- ９月 金額
               ,in_sep_price      => gr_add_total(3).sep_price      -- ９月 品目定価
               ,in_sep_to_amount  => gr_add_total(3).sep_to_amount  -- ９月 内訳合計
               ,in_oct_quant      => gr_add_total(3).oct_quant      -- １０月 数量
               ,in_oct_amount     => gr_add_total(3).oct_amount     -- １０月 金額
               ,in_oct_price      => gr_add_total(3).oct_price      -- １０月 品目定価
               ,in_oct_to_amount  => gr_add_total(3).oct_to_amount  -- １０月 内訳合計
               ,in_nov_quant      => gr_add_total(3).nov_quant      -- １１月 数量
               ,in_nov_amount     => gr_add_total(3).nov_amount     -- １１月 金額
               ,in_nov_price      => gr_add_total(3).nov_price      -- １１月 品目定価
               ,in_nov_to_amount  => gr_add_total(3).nov_to_amount  -- １１月 内訳合計
               ,in_dec_quant      => gr_add_total(3).dec_quant      -- １２月 数量
               ,in_dec_amount     => gr_add_total(3).dec_amount     -- １２月 金額
               ,in_dec_price      => gr_add_total(3).dec_price      -- １２月 品目定価
               ,in_dec_to_amount  => gr_add_total(3).dec_to_amount  -- １２月 内訳合計
               ,in_jan_quant      => gr_add_total(3).jan_quant      -- １月 数量
               ,in_jan_amount     => gr_add_total(3).jan_amount     -- １月 金額
               ,in_jan_price      => gr_add_total(3).jan_price      -- １月 品目定価
               ,in_jan_to_amount  => gr_add_total(3).jan_to_amount  -- １月 内訳合計
               ,in_feb_quant      => gr_add_total(3).feb_quant      -- ２月 数量
               ,in_feb_amount     => gr_add_total(3).feb_amount     -- ２月 金額
               ,in_feb_price      => gr_add_total(3).feb_price      -- ２月 品目定価
               ,in_feb_to_amount  => gr_add_total(3).feb_to_amount  -- ２月 内訳合計
               ,in_mar_quant      => gr_add_total(3).mar_quant      -- ３月 数量
               ,in_mar_amount     => gr_add_total(3).mar_amount     -- ３月 金額
               ,in_mar_price      => gr_add_total(3).mar_price      -- ３月 品目定価
               ,in_mar_to_amount  => gr_add_total(3).mar_to_amount  -- ３月 内訳合計
               ,in_apr_quant      => gr_add_total(3).apr_quant      -- ４月 数量
               ,in_apr_amount     => gr_add_total(3).apr_amount     -- ４月 金額
               ,in_apr_price      => gr_add_total(3).apr_price      -- ４月 品目定価
               ,in_apr_to_amount  => gr_add_total(3).apr_to_amount  -- ４月 内訳合計
               ,in_year_quant     => gr_add_total(3).year_quant     -- 年計 数量
               ,in_year_amount    => gr_add_total(3).year_amount    -- 年計 金額
               ,in_year_price     => gr_add_total(3).year_price     -- 年計 品目定価
               ,in_year_to_amount => gr_add_total(3).year_to_amount -- 年計 内訳合計
               ,ov_errbuf         => lv_errbuf   -- エラー・メッセージ           --# 固定 #
               ,ov_retcode        => lv_retcode  -- リターン・コード             --# 固定 #
               ,ov_errmsg         => lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
              );
            IF (lv_retcode = gv_status_error) THEN
              RAISE global_process_expt;
            END IF;
--
            -- -----------------------------------------------------
            --  拠点終了Ｇタグ出力
            -- -----------------------------------------------------
            gl_xml_idx := gt_xml_data_table.COUNT + 1;
            gt_xml_data_table(gl_xml_idx).tag_name  := '/g_ktn';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
            -- -----------------------------------------------------
            --  拠点終了ＬＧタグ出力
            -- -----------------------------------------------------
            gl_xml_idx := gt_xml_data_table.COUNT + 1;
            gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_ktn_info';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
            --------------------------------------------------------
            -- 商品区分計データタグ出力 
            --------------------------------------------------------
            prc_create_xml_data_s_k_t
              (
                iv_label_name     => gv_name_skbn                   -- 商品区分計用タグ名
               ,in_may_quant      => gr_add_total(4).may_quant      -- ５月 数量
               ,in_may_amount     => gr_add_total(4).may_amount     -- ５月 金額
               ,in_may_price      => gr_add_total(4).may_price      -- ５月 品目定価
               ,in_may_to_amount  => gr_add_total(4).may_to_amount  -- ５月 内訳合計
               ,in_jun_quant      => gr_add_total(4).jun_quant      -- ６月 数量
               ,in_jun_amount     => gr_add_total(4).jun_amount     -- ６月 金額
               ,in_jun_price      => gr_add_total(4).jun_price      -- ６月 品目定価
               ,in_jun_to_amount  => gr_add_total(4).jun_to_amount  -- ６月 内訳合計
               ,in_jul_quant      => gr_add_total(4).jul_quant      -- ７月 数量
               ,in_jul_amount     => gr_add_total(4).jul_amount     -- ７月 金額
               ,in_jul_price      => gr_add_total(4).jul_price      -- ７月 品目定価
               ,in_jul_to_amount  => gr_add_total(4).jul_to_amount  -- ７月 内訳合計
               ,in_aug_quant      => gr_add_total(4).aug_quant      -- ８月 数量
               ,in_aug_amount     => gr_add_total(4).aug_amount     -- ８月 金額
               ,in_aug_price      => gr_add_total(4).aug_price      -- ８月 品目定価
               ,in_aug_to_amount  => gr_add_total(4).aug_to_amount  -- ８月 内訳合計
               ,in_sep_quant      => gr_add_total(4).sep_quant      -- ９月 数量
               ,in_sep_amount     => gr_add_total(4).sep_amount     -- ９月 金額
               ,in_sep_price      => gr_add_total(4).sep_price      -- ９月 品目定価
               ,in_sep_to_amount  => gr_add_total(4).sep_to_amount  -- ９月 内訳合計
               ,in_oct_quant      => gr_add_total(4).oct_quant      -- １０月 数量
               ,in_oct_amount     => gr_add_total(4).oct_amount     -- １０月 金額
               ,in_oct_price      => gr_add_total(4).oct_price      -- １０月 品目定価
               ,in_oct_to_amount  => gr_add_total(4).oct_to_amount  -- １０月 内訳合計
               ,in_nov_quant      => gr_add_total(4).nov_quant      -- １１月 数量
               ,in_nov_amount     => gr_add_total(4).nov_amount     -- １１月 金額
               ,in_nov_price      => gr_add_total(4).nov_price      -- １１月 品目定価
               ,in_nov_to_amount  => gr_add_total(4).nov_to_amount  -- １１月 内訳合計
               ,in_dec_quant      => gr_add_total(4).dec_quant      -- １２月 数量
               ,in_dec_amount     => gr_add_total(4).dec_amount     -- １２月 金額
               ,in_dec_price      => gr_add_total(4).dec_price      -- １２月 品目定価
               ,in_dec_to_amount  => gr_add_total(4).dec_to_amount  -- １２月 内訳合計
               ,in_jan_quant      => gr_add_total(4).jan_quant      -- １月 数量
               ,in_jan_amount     => gr_add_total(4).jan_amount     -- １月 金額
               ,in_jan_price      => gr_add_total(4).jan_price      -- １月 品目定価
               ,in_jan_to_amount  => gr_add_total(4).jan_to_amount  -- １月 内訳合計
               ,in_feb_quant      => gr_add_total(4).feb_quant      -- ２月 数量
               ,in_feb_amount     => gr_add_total(4).feb_amount     -- ２月 金額
               ,in_feb_price      => gr_add_total(4).feb_price      -- ２月 品目定価
               ,in_feb_to_amount  => gr_add_total(4).feb_to_amount  -- ２月 内訳合計
               ,in_mar_quant      => gr_add_total(4).mar_quant      -- ３月 数量
               ,in_mar_amount     => gr_add_total(4).mar_amount     -- ３月 金額
               ,in_mar_price      => gr_add_total(4).mar_price      -- ３月 品目定価
               ,in_mar_to_amount  => gr_add_total(4).mar_to_amount  -- ３月 内訳合計
               ,in_apr_quant      => gr_add_total(4).apr_quant      -- ４月 数量
               ,in_apr_amount     => gr_add_total(4).apr_amount     -- ４月 金額
               ,in_apr_price      => gr_add_total(4).apr_price      -- ４月 品目定価
               ,in_apr_to_amount  => gr_add_total(4).apr_to_amount  -- ４月 内訳合計
               ,in_year_quant     => gr_add_total(4).year_quant     -- 年計 数量
               ,in_year_amount    => gr_add_total(4).year_amount    -- 年計 金額
               ,in_year_price     => gr_add_total(4).year_price     -- 年計 品目定価
               ,in_year_to_amount => gr_add_total(4).year_to_amount -- 年計 内訳合計
               ,ov_errbuf         => lv_errbuf   -- エラー・メッセージ           --# 固定 #
               ,ov_retcode        => lv_retcode  -- リターン・コード             --# 固定 #
               ,ov_errmsg         => lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
              );
            IF (lv_retcode = gv_status_error) THEN
              RAISE global_process_expt;
            END IF;
--
            -- -----------------------------------------------------
            --  商品区分終了Ｇタグ出力
            -- -----------------------------------------------------
            gl_xml_idx := gt_xml_data_table.COUNT + 1;
            gt_xml_data_table(gl_xml_idx).tag_name  := '/g_skbn';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
*/
--
            --------------------------------------------------------
            -- (拠点ごと)(3)拠点計/(4)商品区分計データタグ出力 
            --------------------------------------------------------
            <<kyoten_skbn_loop>>
            FOR n IN 3..4 LOOP        -- 拠点計/商品区分計
--
              -- 拠点計の場合
              IF ( n = 3) THEN
                lv_param_label := gv_name_ktn;
              -- 商品区分計の場合
              ELSE
                lv_param_label := gv_name_skbn;
              END IF;
--
              prc_create_xml_data_s_k_t
              (
                iv_label_name       => lv_param_label                   -- 商品区分計用タグ名
                ,in_may_quant       => gr_add_total(n).may_quant      -- ５月 数量
                ,in_may_amount      => gr_add_total(n).may_amount     -- ５月 金額
                ,in_may_price       => gr_add_total(n).may_price      -- ５月 品目定価
                ,in_may_to_amount   => gr_add_total(n).may_to_amount  -- ５月 内訳合計
                ,in_may_quant_t     => gr_add_total(n).may_quant_t    -- ５月 数量(計算用)
                ,in_may_s_cost      => gr_add_total(n).may_s_cost     -- ５月 標準原価(計算用)
                ,in_may_calc        => gr_add_total(n).may_calc       -- ５月 品目定価*数量(計算用)
                ,in_may_minus_flg   => gr_add_total(n).may_minus_flg   -- ５月 数量マイナス値存在フラグ(計算用)
                ,in_may_ht_zero_flg => gr_add_total(n).may_ht_zero_flg -- ５月 品目定価*数量(計)
                ,in_jun_quant       => gr_add_total(n).jun_quant      -- ６月 数量
                ,in_jun_amount      => gr_add_total(n).jun_amount     -- ６月 金額
                ,in_jun_price       => gr_add_total(n).jun_price      -- ６月 品目定価
                ,in_jun_to_amount   => gr_add_total(n).jun_to_amount  -- ６月 内訳合計
                ,in_jun_quant_t     => gr_add_total(n).jun_quant_t    -- ６月 数量(計算用)
                ,in_jun_s_cost      => gr_add_total(n).jun_s_cost     -- ６月 標準原価(計算用)
                ,in_jun_calc        => gr_add_total(n).jun_calc       -- ６月 品目定価*数量(計算用)
                ,in_jun_minus_flg   => gr_add_total(n).jun_minus_flg   -- ６月 数量マイナス値存在フラグ(計算用)
                ,in_jun_ht_zero_flg => gr_add_total(n).jun_ht_zero_flg -- ６月 品目定価*数量(計)
                ,in_jul_quant       => gr_add_total(n).jul_quant      -- ７月 数量
                ,in_jul_amount      => gr_add_total(n).jul_amount     -- ７月 金額
                ,in_jul_price       => gr_add_total(n).jul_price      -- ７月 品目定価
                ,in_jul_to_amount   => gr_add_total(n).jul_to_amount  -- ７月 内訳合計
                ,in_jul_quant_t     => gr_add_total(n).jul_quant_t    -- ７月 数量(計算用)
                ,in_jul_s_cost      => gr_add_total(n).jul_s_cost     -- ７月 標準原価(計算用)
                ,in_jul_calc        => gr_add_total(n).jul_calc       -- ７月 品目定価*数量(計算用)
                ,in_jul_minus_flg   => gr_add_total(n).jul_minus_flg   -- ７月 数量マイナス値存在フラグ(計算用)
                ,in_jul_ht_zero_flg => gr_add_total(n).jul_ht_zero_flg -- ７月 品目定価*数量(計)
                ,in_aug_quant       => gr_add_total(n).aug_quant      -- ８月 数量
                ,in_aug_amount      => gr_add_total(n).aug_amount     -- ８月 金額
                ,in_aug_price       => gr_add_total(n).aug_price      -- ８月 品目定価
                ,in_aug_to_amount   => gr_add_total(n).aug_to_amount  -- ８月 内訳合計
                ,in_aug_quant_t     => gr_add_total(n).aug_quant_t    -- ８月 数量(計算用)
                ,in_aug_s_cost      => gr_add_total(n).aug_s_cost     -- ８月 標準原価(計算用)
                ,in_aug_calc        => gr_add_total(n).aug_calc       -- ８月 品目定価*数量(計算用)
                ,in_aug_minus_flg   => gr_add_total(n).aug_minus_flg   -- ８月 数量マイナス値存在フラグ(計算用)
                ,in_aug_ht_zero_flg => gr_add_total(n).aug_ht_zero_flg -- ８月 品目定価*数量(計)
                ,in_sep_quant       => gr_add_total(n).sep_quant      -- ９月 数量
                ,in_sep_amount      => gr_add_total(n).sep_amount     -- ９月 金額
                ,in_sep_price       => gr_add_total(n).sep_price      -- ９月 品目定価
                ,in_sep_to_amount   => gr_add_total(n).sep_to_amount  -- ９月 内訳合計
                ,in_sep_quant_t     => gr_add_total(n).sep_quant_t    -- ９月 数量(計算用)
                ,in_sep_s_cost      => gr_add_total(n).sep_s_cost     -- ９月 標準原価(計算用)
                ,in_sep_calc        => gr_add_total(n).sep_calc       -- ９月 品目定価*数量(計算用)
                ,in_sep_minus_flg   => gr_add_total(n).sep_minus_flg   -- ９月 数量マイナス値存在フラグ(計算用)
                ,in_sep_ht_zero_flg => gr_add_total(n).sep_ht_zero_flg -- ９月 品目定価*数量(計)
                ,in_oct_quant       => gr_add_total(n).oct_quant      -- １０月 数量
                ,in_oct_amount      => gr_add_total(n).oct_amount     -- １０月 金額
                ,in_oct_price       => gr_add_total(n).oct_price      -- １０月 品目定価
                ,in_oct_to_amount   => gr_add_total(n).oct_to_amount  -- １０月 内訳合計
                ,in_oct_quant_t     => gr_add_total(n).oct_quant_t    -- １０月 数量(計算用)
                ,in_oct_s_cost      => gr_add_total(n).oct_s_cost     -- １０月 標準原価(計算用)
                ,in_oct_calc        => gr_add_total(n).oct_calc       -- １０月 品目定価*数量(計算用)
                ,in_oct_minus_flg   => gr_add_total(n).oct_minus_flg   -- １０月 数量マイナス値存在フラグ(計算用)
                ,in_oct_ht_zero_flg => gr_add_total(n).oct_ht_zero_flg -- １０月 品目定価*数量(計)
                ,in_nov_quant       => gr_add_total(n).nov_quant      -- １１月 数量
                ,in_nov_amount      => gr_add_total(n).nov_amount     -- １１月 金額
                ,in_nov_price       => gr_add_total(n).nov_price      -- １１月 品目定価
                ,in_nov_to_amount   => gr_add_total(n).nov_to_amount  -- １１月 内訳合計
                ,in_nov_quant_t     => gr_add_total(n).nov_quant_t    -- １１月 数量(計算用)
                ,in_nov_s_cost      => gr_add_total(n).nov_s_cost     -- １１月 標準原価(計算用)
                ,in_nov_calc        => gr_add_total(n).nov_calc       -- １１月 品目定価*数量(計算用)
                ,in_nov_minus_flg   => gr_add_total(n).nov_minus_flg   -- １１月 数量マイナス値存在フラグ(計算用)
                ,in_nov_ht_zero_flg => gr_add_total(n).nov_ht_zero_flg -- １１月 品目定価*数量(計)
                ,in_dec_quant       => gr_add_total(n).dec_quant      -- １２月 数量
                ,in_dec_amount      => gr_add_total(n).dec_amount     -- １２月 金額
                ,in_dec_price       => gr_add_total(n).dec_price      -- １２月 品目定価
                ,in_dec_to_amount   => gr_add_total(n).dec_to_amount  -- １２月 内訳合計
                ,in_dec_quant_t     => gr_add_total(n).dec_quant_t    -- １２月 数量(計算用)
                ,in_dec_s_cost      => gr_add_total(n).dec_s_cost     -- １２月 標準原価(計算用)
                ,in_dec_calc        => gr_add_total(n).dec_calc       -- １２月 品目定価*数量(計算用)
                ,in_dec_minus_flg   => gr_add_total(n).dec_minus_flg   -- １２月 数量マイナス値存在フラグ(計算用)
                ,in_dec_ht_zero_flg => gr_add_total(n).dec_ht_zero_flg -- １２月 品目定価*数量(計)
                ,in_jan_quant       => gr_add_total(n).jan_quant      -- １月 数量
                ,in_jan_amount      => gr_add_total(n).jan_amount     -- １月 金額
                ,in_jan_price       => gr_add_total(n).jan_price      -- １月 品目定価
                ,in_jan_to_amount   => gr_add_total(n).jan_to_amount  -- １月 内訳合計
                ,in_jan_quant_t     => gr_add_total(n).jan_quant_t    -- １月 数量(計算用)
                ,in_jan_s_cost      => gr_add_total(n).jan_s_cost     -- １月 標準原価(計算用)
                ,in_jan_calc        => gr_add_total(n).jan_calc       -- １月 品目定価*数量(計算用)
                ,in_jan_minus_flg   => gr_add_total(n).jan_minus_flg   -- １月 数量マイナス値存在フラグ(計算用)
                ,in_jan_ht_zero_flg => gr_add_total(n).jan_ht_zero_flg -- １月 品目定価*数量(計)
                ,in_feb_quant       => gr_add_total(n).feb_quant      -- ２月 数量
                ,in_feb_amount      => gr_add_total(n).feb_amount     -- ２月 金額
                ,in_feb_price       => gr_add_total(n).feb_price      -- ２月 品目定価
                ,in_feb_to_amount   => gr_add_total(n).feb_to_amount  -- ２月 内訳合計
                ,in_feb_quant_t     => gr_add_total(n).feb_quant_t    -- ２月 数量(計算用)
                ,in_feb_s_cost      => gr_add_total(n).feb_s_cost     -- ２月 標準原価(計算用)
                ,in_feb_calc        => gr_add_total(n).feb_calc       -- ２月 品目定価*数量(計算用)
                ,in_feb_minus_flg   => gr_add_total(n).feb_minus_flg   -- ２月 数量マイナス値存在フラグ(計算用)
                ,in_feb_ht_zero_flg => gr_add_total(n).feb_ht_zero_flg -- ２月 品目定価*数量(計)
                ,in_mar_quant       => gr_add_total(n).mar_quant      -- ３月 数量
                ,in_mar_amount      => gr_add_total(n).mar_amount     -- ３月 金額
                ,in_mar_price       => gr_add_total(n).mar_price      -- ３月 品目定価
                ,in_mar_to_amount   => gr_add_total(n).mar_to_amount  -- ３月 内訳合計
                ,in_mar_quant_t     => gr_add_total(n).mar_quant_t    -- ３月 数量(計算用)
                ,in_mar_s_cost      => gr_add_total(n).mar_s_cost     -- ３月 標準原価(計算用)
                ,in_mar_calc        => gr_add_total(n).mar_calc       -- ３月 品目定価*数量(計算用)
                ,in_mar_minus_flg   => gr_add_total(n).mar_minus_flg   -- ３月 数量マイナス値存在フラグ(計算用)
                ,in_mar_ht_zero_flg => gr_add_total(n).mar_ht_zero_flg -- ３月 品目定価*数量(計)
                ,in_apr_quant       => gr_add_total(n).apr_quant      -- ４月 数量
                ,in_apr_amount      => gr_add_total(n).apr_amount     -- ４月 金額
                ,in_apr_price       => gr_add_total(n).apr_price      -- ４月 品目定価
                ,in_apr_to_amount   => gr_add_total(n).apr_to_amount  -- ４月 内訳合計
                ,in_apr_quant_t     => gr_add_total(n).apr_quant_t    -- ４月 数量(計算用)
                ,in_apr_s_cost      => gr_add_total(n).apr_s_cost     -- ４月 標準原価(計算用)
                ,in_apr_calc        => gr_add_total(n).apr_calc       -- ４月 品目定価*数量(計算用)
                ,in_apr_minus_flg   => gr_add_total(n).apr_minus_flg   -- ４月 数量マイナス値存在フラグ(計算用)
                ,in_apr_ht_zero_flg => gr_add_total(n).apr_ht_zero_flg -- ４月 品目定価*数量(計)
                ,in_year_quant      => gr_add_total(n).year_quant     -- 年計 数量
                ,in_year_amount     => gr_add_total(n).year_amount    -- 年計 金額
                ,in_year_price      => gr_add_total(n).year_price     -- 年計 品目定価
                ,in_year_to_amount  => gr_add_total(n).year_to_amount -- 年計 内訳合計
                ,in_year_quant_t    => gr_add_total(n).year_quant_t   -- 年計 数量(計算用)
                ,in_year_s_cost     => gr_add_total(n).year_s_cost    -- 年計 標準原価(計算用)
                ,in_year_calc       => gr_add_total(n).year_calc      -- 年計 品目定価*数量(計算用)
                ,in_year_minus_flg   => gr_add_total(n).year_minus_flg   -- 年計 数量マイナス値存在フラグ(計算用)
                ,in_year_ht_zero_flg => gr_add_total(n).year_ht_zero_flg -- 年計 品目定価*数量(計)
                ,ov_errbuf         => lv_errbuf   -- エラー・メッセージ           --# 固定 #
                ,ov_retcode        => lv_retcode  -- リターン・コード             --# 固定 #
                ,ov_errmsg         => lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
              );
              IF (lv_retcode = gv_status_error) THEN
                RAISE global_process_expt;
              END IF;
--
              -- 拠点計の場合
              IF ( n = 3) THEN
                -- -----------------------------------------------------
                --  (拠点ごと)拠点終了Ｇタグ出力
                -- -----------------------------------------------------
                gl_xml_idx := gt_xml_data_table.COUNT + 1;
                gt_xml_data_table(gl_xml_idx).tag_name  := '/g_ktn';
                gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
    --
                -- -----------------------------------------------------
                --  (拠点ごと)拠点終了ＬＧタグ出力
                -- -----------------------------------------------------
                gl_xml_idx := gt_xml_data_table.COUNT + 1;
                gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_ktn_info';
                gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
              -- 商品区分計の場合
              ELSE
                -- -----------------------------------------------------
                --  (拠点ごと)商品区分終了Ｇタグ出力
                -- -----------------------------------------------------
                gl_xml_idx := gt_xml_data_table.COUNT + 1;
                gt_xml_data_table(gl_xml_idx).tag_name  := '/g_skbn';
                gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
              END IF;
--
            END LOOP kyoten_skbn_loop;
-- 2009/04/16 v1.6 T.Yoshimoto Mod End
--
          END IF;
--
          -- -----------------------------------------------------
          --  (拠点ごと)商品区分開始Ｇタグ出力
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'g_skbn';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
          -- -----------------------------------------------------
          -- (拠点ごと)商品区分(コード) タグ
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'skbn_code';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          gt_xml_data_table(gl_xml_idx).tag_value := gr_sale_plan_1(i).skbn;
--
          -- -----------------------------------------------------
          -- (拠点ごと)商品区分(名称) タグ
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'skbn_name';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
--
          ------------------------------------------------
          -- (拠点ごと)入力Ｐ『商品区分』がNULLの場合   --
          ------------------------------------------------
          IF (gr_param.prod_div IS NULL) THEN
            -- 抽出データが'1'の場合
            IF (gr_sale_plan_1(i).skbn = gv_prod_div_leaf) THEN
             gt_xml_data_table(gl_xml_idx).tag_value := lv_name_leaf;  -- 'リーフ'
            -- 抽出データが'2'の場合
            ELSIF (gr_sale_plan_1(i).skbn = gv_prod_div_drink) THEN
              gt_xml_data_table(gl_xml_idx).tag_value := lv_name_drink; -- 'ドリンク'
            END IF;
          -- 入力Ｐ『商品区分』が指定されている場合
          ELSE
            gt_xml_data_table(gl_xml_idx).tag_value := gr_sale_plan_1(i).skbn_name;
          END IF;
--
          -- -----------------------------------------------------
          --  (拠点ごと)拠点区分開始ＬＧタグ出力
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_ktn_info';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
          -- -----------------------------------------------------
          --  (拠点ごと)拠点区分開始Ｇタグ出力
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'g_ktn';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
          -- -----------------------------------------------------
          --  (拠点ごと)拠点区分(拠点コード) タグ
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'ktn_code';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          gt_xml_data_table(gl_xml_idx).tag_value := gr_sale_plan_1(i).ktn_code;
--
          -- -----------------------------------------------------
          --  (拠点ごと)拠点区分(拠点略称) タグ
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'ktn_name';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          gt_xml_data_table(gl_xml_idx).tag_value := gr_sale_plan_1(i).party_short_name;
--
          -- -----------------------------------------------------
          --  (拠点ごと)群コード開始LＧタグ出力
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_gun_info';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
          -- -----------------------------------------------------
          --  (拠点ごと)群コード開始Ｇタグ出力
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'g_gun';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
          -- -----------------------------------------------------
          --  (拠点ごと)品目開始ＬＧタグ出力
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_dtl_info';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
          -- 各ブレイクキー更新
          lv_skbn_break := gr_sale_plan_1(i).skbn;              -- 商品区分
          lv_ktn_break  := gr_sale_plan_1(i).ktn_code;          -- 拠点
          lv_gun_break  := gr_sale_plan_1(i).gun;               -- 群コード
          lv_dtl_break  := lv_break_init;                       -- 品目コード
          lv_sttl_break := SUBSTRB(gr_sale_plan_1(i).gun,1,3);  -- 小群計
          lv_lttl_break := SUBSTRB(gr_sale_plan_1(i).gun,1,1);  -- 大群計
--
          ----------------------------------------
          --  (拠点ごと)各集計項目初期化
          ----------------------------------------
          -- データが１件目の場合
          IF (i = 1) THEN 
            <<add_total_loop>>
            FOR l IN 1..5 LOOP        -- 小群計/大群計/拠点計/商品区分計/総合計
              gr_add_total(l).may_quant       := gn_0; -- ５月 数量
              gr_add_total(l).may_amount      := gn_0; -- ５月 金額
              gr_add_total(l).may_price       := gn_0; -- ５月 品目定価
              gr_add_total(l).may_to_amount   := gn_0; -- ５月 内訳合計
              gr_add_total(l).may_quant_t     := gn_0; -- ５月 数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
              gr_add_total(l).may_s_cost      := gn_0; -- ５月 標準原価(計)
              gr_add_total(l).may_calc        := gn_0; -- ５月 品目定価*数量(計)
              gr_add_total(l).may_minus_flg   := 'N';  -- ５月 数量マイナス値存在フラグ(計)
              gr_add_total(l).may_ht_zero_flg := 'N';  -- ５月 品目定価0値存在フラグ(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
              gr_add_total(l).jun_quant       := gn_0; -- ６月 数量
              gr_add_total(l).jun_amount      := gn_0; -- ６月 金額
              gr_add_total(l).jun_price       := gn_0; -- ６月 品目定価
              gr_add_total(l).jun_to_amount   := gn_0; -- ６月 内訳合計
              gr_add_total(l).jun_quant_t     := gn_0; -- ６月 数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
              gr_add_total(l).jun_s_cost      := gn_0; -- ６月 標準原価(計)
              gr_add_total(l).jun_calc        := gn_0; -- ６月 品目定価*数量(計)
              gr_add_total(l).jun_minus_flg   := 'N';  -- ６月 数量マイナス値存在フラグ(計)
              gr_add_total(l).jun_ht_zero_flg := 'N';  -- ６月 品目定価0値存在フラグ(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
              gr_add_total(l).jul_quant       := gn_0; -- ７月 数量
              gr_add_total(l).jul_amount      := gn_0; -- ７月 金額
              gr_add_total(l).jul_price       := gn_0; -- ７月 品目定価
              gr_add_total(l).jul_to_amount   := gn_0; -- ７月 内訳合計
              gr_add_total(l).jul_quant_t     := gn_0; -- ７月 数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
              gr_add_total(l).jul_s_cost      := gn_0; -- ７月 標準原価(計)
              gr_add_total(l).jul_calc        := gn_0; -- ７月 品目定価*数量(計)
              gr_add_total(l).jul_minus_flg   := 'N';  -- ７月 数量マイナス値存在フラグ(計)
              gr_add_total(l).jul_ht_zero_flg := 'N';  -- ７月 品目定価0値存在フラグ(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
              gr_add_total(l).aug_quant       := gn_0; -- ８月 数量
              gr_add_total(l).aug_amount      := gn_0; -- ８月 金額
              gr_add_total(l).aug_price       := gn_0; -- ８月 品目定価
              gr_add_total(l).aug_to_amount   := gn_0; -- ８月 内訳合計
              gr_add_total(l).aug_quant_t     := gn_0; -- ８月 数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
              gr_add_total(l).aug_s_cost      := gn_0; -- ８月 標準原価(計)
              gr_add_total(l).aug_calc        := gn_0; -- ８月 品目定価*数量(計)
              gr_add_total(l).aug_minus_flg   := 'N';  -- ８月 数量マイナス値存在フラグ(計)
              gr_add_total(l).aug_ht_zero_flg := 'N';  -- ８月 品目定価0値存在フラグ(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
              gr_add_total(l).sep_quant       := gn_0; -- ９月 数量
              gr_add_total(l).sep_amount      := gn_0; -- ９月 金額
              gr_add_total(l).sep_price       := gn_0; -- ９月 品目定価
              gr_add_total(l).sep_to_amount   := gn_0; -- ９月 内訳合計
              gr_add_total(l).sep_quant_t     := gn_0; -- ９月 数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
              gr_add_total(l).sep_s_cost      := gn_0; -- ９月 標準原価(計)
              gr_add_total(l).sep_calc        := gn_0; -- ９月 品目定価*数量(計)
              gr_add_total(l).sep_minus_flg   := 'N';  -- ９月 数量マイナス値存在フラグ(計)
              gr_add_total(l).sep_ht_zero_flg := 'N';  -- ９月 品目定価0値存在フラグ(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
              gr_add_total(l).oct_quant       := gn_0; -- １０月 数量
              gr_add_total(l).oct_amount      := gn_0; -- １０月 金額
              gr_add_total(l).oct_price       := gn_0; -- １０月 品目定価
              gr_add_total(l).oct_to_amount   := gn_0; -- １０月 内訳合計
              gr_add_total(l).oct_quant_t     := gn_0; -- １０月 数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
              gr_add_total(l).oct_s_cost      := gn_0; -- １０月 標準原価(計)
              gr_add_total(l).oct_calc        := gn_0; -- １０月 品目定価*数量(計)
              gr_add_total(l).oct_minus_flg   := 'N';  -- １０月 数量マイナス値存在フラグ(計)
              gr_add_total(l).oct_ht_zero_flg := 'N';  -- １０月 品目定価0値存在フラグ(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
              gr_add_total(l).nov_quant       := gn_0; -- １１月 数量
              gr_add_total(l).nov_amount      := gn_0; -- １１月 金額
              gr_add_total(l).nov_price       := gn_0; -- １１月 品目定価
              gr_add_total(l).nov_to_amount   := gn_0; -- １１月 内訳合計
              gr_add_total(l).nov_quant_t     := gn_0; -- １１月 数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
              gr_add_total(l).nov_s_cost      := gn_0; -- １１月 標準原価(計)
              gr_add_total(l).nov_calc        := gn_0; -- １１月 品目定価*数量(計)
              gr_add_total(l).nov_minus_flg   := 'N';  -- １１月 数量マイナス値存在フラグ(計)
              gr_add_total(l).nov_ht_zero_flg := 'N';  -- １１月 品目定価0値存在フラグ(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
              gr_add_total(l).dec_quant       := gn_0; -- １２月 数量
              gr_add_total(l).dec_amount      := gn_0; -- １２月 金額
              gr_add_total(l).dec_price       := gn_0; -- １２月 品目定価
              gr_add_total(l).dec_to_amount   := gn_0; -- １２月 内訳合計
              gr_add_total(l).dec_quant_t     := gn_0; -- １２月 数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
              gr_add_total(l).dec_s_cost      := gn_0; -- １２月 標準原価(計)
              gr_add_total(l).dec_calc        := gn_0; -- １２月 品目定価*数量(計)
              gr_add_total(l).dec_minus_flg   := 'N';  -- １２月 数量マイナス値存在フラグ(計)
              gr_add_total(l).dec_ht_zero_flg := 'N';  -- １２月 品目定価0値存在フラグ(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
              gr_add_total(l).jan_quant       := gn_0; -- １月 数量
              gr_add_total(l).jan_amount      := gn_0; -- １月 金額
              gr_add_total(l).jan_price       := gn_0; -- １月 品目定価
              gr_add_total(l).jan_to_amount   := gn_0; -- １月 内訳合計
              gr_add_total(l).jan_quant_t     := gn_0; -- １月 数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
              gr_add_total(l).jan_s_cost      := gn_0; -- １月 標準原価(計)
              gr_add_total(l).jan_calc        := gn_0; -- １月 品目定価*数量(計)
              gr_add_total(l).jan_minus_flg   := 'N';  -- １月 数量マイナス値存在フラグ(計)
              gr_add_total(l).jan_ht_zero_flg := 'N';  -- １月 品目定価0値存在フラグ(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
              gr_add_total(l).feb_quant       := gn_0; -- ２月 数量
              gr_add_total(l).feb_amount      := gn_0; -- ２月 金額
              gr_add_total(l).feb_price       := gn_0; -- ２月 品目定価
              gr_add_total(l).feb_to_amount   := gn_0; -- ２月 内訳合計
              gr_add_total(l).feb_quant_t     := gn_0; -- ２月 数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
              gr_add_total(l).feb_s_cost      := gn_0; -- ２月 標準原価(計)
              gr_add_total(l).feb_calc        := gn_0; -- ２月 品目定価*数量(計)
              gr_add_total(l).feb_minus_flg   := 'N';  -- ２月 数量マイナス値存在フラグ(計)
              gr_add_total(l).feb_ht_zero_flg := 'N';  -- ２月 品目定価0値存在フラグ(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
              gr_add_total(l).mar_quant       := gn_0; -- ３月 数量
              gr_add_total(l).mar_amount      := gn_0; -- ３月 金額
              gr_add_total(l).mar_price       := gn_0; -- ３月 品目定価
              gr_add_total(l).mar_to_amount   := gn_0; -- ３月 内訳合計
              gr_add_total(l).mar_quant_t     := gn_0; -- ３月 数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
              gr_add_total(l).mar_s_cost      := gn_0; -- ３月 標準原価(計)
              gr_add_total(l).mar_calc        := gn_0; -- ３月 品目定価*数量(計)
              gr_add_total(l).mar_minus_flg   := 'N';  -- ３月 数量マイナス値存在フラグ(計)
              gr_add_total(l).mar_ht_zero_flg := 'N';  -- ３月 品目定価0値存在フラグ(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
              gr_add_total(l).apr_quant       := gn_0; -- ４月 数量
              gr_add_total(l).apr_amount      := gn_0; -- ４月 金額
              gr_add_total(l).apr_price       := gn_0; -- ４月 品目定価
              gr_add_total(l).apr_to_amount   := gn_0; -- ４月 内訳合計
              gr_add_total(l).apr_quant_t     := gn_0; -- ４月 数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
              gr_add_total(l).apr_s_cost      := gn_0; -- ４月 標準原価(計)
              gr_add_total(l).apr_calc        := gn_0; -- ４月 品目定価*数量(計)
              gr_add_total(l).apr_minus_flg   := 'N';  -- ４月 数量マイナス値存在フラグ(計)
              gr_add_total(l).apr_ht_zero_flg := 'N';  -- ４月 品目定価0値存在フラグ(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
              gr_add_total(l).year_quant      := gn_0; -- 年計 数量
              gr_add_total(l).year_amount     := gn_0; -- 年計 金額
              gr_add_total(l).year_price      := gn_0; -- 年計 品目定価
              gr_add_total(l).year_to_amount  := gn_0; -- 年計 内訳合計
              gr_add_total(l).year_quant_t    := gn_0; -- 年計 数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
              gr_add_total(l).year_s_cost     := gn_0; -- 年計 標準原価(計)
              gr_add_total(l).year_calc       := gn_0; -- 年計 品目定価*数量(計)
              gr_add_total(l).year_minus_flg   := 'N'; -- 年計 数量マイナス値存在フラグ(計)
              gr_add_total(l).year_ht_zero_flg := 'N'; -- 年計 品目定価0値存在フラグ(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
            END LOOP add_total_loop;
          -- データ２件目以降の場合
          ELSE
            <<add_total_loop>>
            FOR l IN 1..4 LOOP        -- 小群計/大群計/拠点計/商品区分計
              gr_add_total(l).may_quant       := gn_0; -- ５月 数量
              gr_add_total(l).may_amount      := gn_0; -- ５月 金額
              gr_add_total(l).may_price       := gn_0; -- ５月 品目定価
              gr_add_total(l).may_to_amount   := gn_0; -- ５月 内訳合計
              gr_add_total(l).may_quant_t     := gn_0; -- ５月 数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
              gr_add_total(l).may_s_cost      := gn_0; -- ５月 標準原価(計)
              gr_add_total(l).may_calc        := gn_0; -- ５月 品目定価*数量(計)
              gr_add_total(l).may_minus_flg   := 'N';  -- ５月 数量マイナス値存在フラグ(計)
              gr_add_total(l).may_ht_zero_flg := 'N';  -- ５月 品目定価0値存在フラグ(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
              gr_add_total(l).jun_quant       := gn_0; -- ６月 数量
              gr_add_total(l).jun_amount      := gn_0; -- ６月 金額
              gr_add_total(l).jun_price       := gn_0; -- ６月 品目定価
              gr_add_total(l).jun_to_amount   := gn_0; -- ６月 内訳合計
              gr_add_total(l).jun_quant_t     := gn_0; -- ６月 数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
              gr_add_total(l).jun_s_cost      := gn_0; -- ６月 標準原価(計)
              gr_add_total(l).jun_calc        := gn_0; -- ６月 品目定価*数量(計)
              gr_add_total(l).jun_minus_flg   := 'N';  -- ６月 数量マイナス値存在フラグ(計)
              gr_add_total(l).jun_ht_zero_flg := 'N';  -- ６月 品目定価0値存在フラグ(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
              gr_add_total(l).jul_quant       := gn_0; -- ７月 数量
              gr_add_total(l).jul_amount      := gn_0; -- ７月 金額
              gr_add_total(l).jul_price       := gn_0; -- ７月 品目定価
              gr_add_total(l).jul_to_amount   := gn_0; -- ７月 内訳合計
              gr_add_total(l).jul_quant_t     := gn_0; -- ７月 数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
              gr_add_total(l).jul_s_cost      := gn_0; -- ７月 標準原価(計)
              gr_add_total(l).jul_calc        := gn_0; -- ７月 品目定価*数量(計)
              gr_add_total(l).jul_minus_flg   := 'N';  -- ７月 数量マイナス値存在フラグ(計)
              gr_add_total(l).jul_ht_zero_flg := 'N';  -- ７月 品目定価0値存在フラグ(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
              gr_add_total(l).aug_quant       := gn_0; -- ８月 数量
              gr_add_total(l).aug_amount      := gn_0; -- ８月 金額
              gr_add_total(l).aug_price       := gn_0; -- ８月 品目定価
              gr_add_total(l).aug_to_amount   := gn_0; -- ８月 内訳合計
              gr_add_total(l).aug_quant_t     := gn_0; -- ８月 数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
              gr_add_total(l).aug_s_cost      := gn_0; -- ８月 標準原価(計)
              gr_add_total(l).aug_calc        := gn_0; -- ８月 品目定価*数量(計)
              gr_add_total(l).aug_minus_flg   := 'N';  -- ８月 数量マイナス値存在フラグ(計)
              gr_add_total(l).aug_ht_zero_flg := 'N';  -- ８月 品目定価0値存在フラグ(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
              gr_add_total(l).sep_quant       := gn_0; -- ９月 数量
              gr_add_total(l).sep_amount      := gn_0; -- ９月 金額
              gr_add_total(l).sep_price       := gn_0; -- ９月 品目定価
              gr_add_total(l).sep_to_amount   := gn_0; -- ９月 内訳合計
              gr_add_total(l).sep_quant_t     := gn_0; -- ９月 数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
              gr_add_total(l).sep_s_cost      := gn_0; -- ９月 標準原価(計)
              gr_add_total(l).sep_calc        := gn_0; -- ９月 品目定価*数量(計)
              gr_add_total(l).sep_minus_flg   := 'N';  -- ９月 数量マイナス値存在フラグ(計)
              gr_add_total(l).sep_ht_zero_flg := 'N';  -- ９月 品目定価0値存在フラグ(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
              gr_add_total(l).oct_quant       := gn_0; -- １０月 数量
              gr_add_total(l).oct_amount      := gn_0; -- １０月 金額
              gr_add_total(l).oct_price       := gn_0; -- １０月 品目定価
              gr_add_total(l).oct_to_amount   := gn_0; -- １０月 内訳合計
              gr_add_total(l).oct_quant_t     := gn_0; -- １０月 数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
              gr_add_total(l).oct_s_cost      := gn_0; -- １０月 標準原価(計)
              gr_add_total(l).oct_calc        := gn_0; -- １０月 品目定価*数量(計)
              gr_add_total(l).oct_minus_flg   := 'N';  -- １０月 数量マイナス値存在フラグ(計)
              gr_add_total(l).oct_ht_zero_flg := 'N';  -- １０月 品目定価0値存在フラグ(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
              gr_add_total(l).nov_quant       := gn_0; -- １１月 数量
              gr_add_total(l).nov_amount      := gn_0; -- １１月 金額
              gr_add_total(l).nov_price       := gn_0; -- １１月 品目定価
              gr_add_total(l).nov_to_amount   := gn_0; -- １１月 内訳合計
              gr_add_total(l).nov_quant_t     := gn_0; -- １１月 数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
              gr_add_total(l).nov_s_cost      := gn_0; -- １１月 標準原価(計)
              gr_add_total(l).nov_calc        := gn_0; -- １１月 品目定価*数量(計)
              gr_add_total(l).nov_minus_flg   := 'N';  -- １１月 数量マイナス値存在フラグ(計)
              gr_add_total(l).nov_ht_zero_flg := 'N';  -- １１月 品目定価0値存在フラグ(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
              gr_add_total(l).dec_quant       := gn_0; -- １２月 数量
              gr_add_total(l).dec_amount      := gn_0; -- １２月 金額
              gr_add_total(l).dec_price       := gn_0; -- １２月 品目定価
              gr_add_total(l).dec_to_amount   := gn_0; -- １２月 内訳合計
              gr_add_total(l).dec_quant_t     := gn_0; -- １２月 数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
              gr_add_total(l).dec_s_cost      := gn_0; -- １２月 標準原価(計)
              gr_add_total(l).dec_calc        := gn_0; -- １２月 品目定価*数量(計)
              gr_add_total(l).dec_minus_flg   := 'N';  -- １２月 数量マイナス値存在フラグ(計)
              gr_add_total(l).dec_ht_zero_flg := 'N';  -- １２月 品目定価0値存在フラグ(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
              gr_add_total(l).jan_quant       := gn_0; -- １月 数量
              gr_add_total(l).jan_amount      := gn_0; -- １月 金額
              gr_add_total(l).jan_price       := gn_0; -- １月 品目定価
              gr_add_total(l).jan_to_amount   := gn_0; -- １月 内訳合計
              gr_add_total(l).jan_quant_t     := gn_0; -- １月 数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
              gr_add_total(l).jan_s_cost      := gn_0; -- １月 標準原価(計)
              gr_add_total(l).jan_calc        := gn_0; -- １月 品目定価*数量(計)
              gr_add_total(l).jan_minus_flg   := 'N';  -- １月 数量マイナス値存在フラグ(計)
              gr_add_total(l).jan_ht_zero_flg := 'N';  -- １月 品目定価0値存在フラグ(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
              gr_add_total(l).feb_quant       := gn_0; -- ２月 数量
              gr_add_total(l).feb_amount      := gn_0; -- ２月 金額
              gr_add_total(l).feb_price       := gn_0; -- ２月 品目定価
              gr_add_total(l).feb_to_amount   := gn_0; -- ２月 内訳合計
              gr_add_total(l).feb_quant_t     := gn_0; -- ２月 数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
              gr_add_total(l).feb_s_cost      := gn_0; -- ２月 標準原価(計)
              gr_add_total(l).feb_calc        := gn_0; -- ２月 品目定価*数量(計)
              gr_add_total(l).feb_minus_flg   := 'N';  -- ２月 数量マイナス値存在フラグ(計)
              gr_add_total(l).feb_ht_zero_flg := 'N';  -- ２月 品目定価0値存在フラグ(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
              gr_add_total(l).mar_quant       := gn_0; -- ３月 数量
              gr_add_total(l).mar_amount      := gn_0; -- ３月 金額
              gr_add_total(l).mar_price       := gn_0; -- ３月 品目定価
              gr_add_total(l).mar_to_amount   := gn_0; -- ３月 内訳合計
              gr_add_total(l).mar_quant_t     := gn_0; -- ３月 数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
              gr_add_total(l).mar_s_cost      := gn_0; -- ３月 標準原価(計)
              gr_add_total(l).mar_calc        := gn_0; -- ３月 品目定価*数量(計)
              gr_add_total(l).mar_minus_flg   := 'N';  -- ３月 数量マイナス値存在フラグ(計)
              gr_add_total(l).mar_ht_zero_flg := 'N';  -- ３月 品目定価0値存在フラグ(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
              gr_add_total(l).apr_quant       := gn_0; -- ４月 数量
              gr_add_total(l).apr_amount      := gn_0; -- ４月 金額
              gr_add_total(l).apr_price       := gn_0; -- ４月 品目定価
              gr_add_total(l).apr_to_amount   := gn_0; -- ４月 内訳合計
              gr_add_total(l).apr_quant_t     := gn_0; -- ４月 数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
              gr_add_total(l).apr_s_cost      := gn_0; -- ４月 標準原価(計)
              gr_add_total(l).apr_calc        := gn_0; -- ４月 品目定価*数量(計)
              gr_add_total(l).apr_minus_flg   := 'N';  -- ４月 数量マイナス値存在フラグ(計)
              gr_add_total(l).apr_ht_zero_flg := 'N';  -- ４月 品目定価0値存在フラグ(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
              gr_add_total(l).year_quant      := gn_0; -- 年計 数量
              gr_add_total(l).year_amount     := gn_0; -- 年計 金額
              gr_add_total(l).year_price      := gn_0; -- 年計 品目定価
              gr_add_total(l).year_to_amount  := gn_0; -- 年計 内訳合計
              gr_add_total(l).year_quant_t    := gn_0; -- 年計 数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
              gr_add_total(l).year_s_cost     := gn_0; -- 年計 標準原価(計)
              gr_add_total(l).year_calc       := gn_0; -- 年計 品目定価*数量(計)
              gr_add_total(l).year_minus_flg   := 'N'; -- 年計 数量マイナス値存在フラグ(計)
              gr_add_total(l).year_ht_zero_flg := 'N'; -- 年計 品目定価0値存在フラグ(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
            END LOOP add_total_loop;
          END IF;
--
          -- 年計初期化
          ln_year_quant_sum  := gn_0;           -- 数量
          ln_year_amount_sum := gn_0;           -- 金額
          ln_year_to_am_sum  := gn_0;           -- 内訳合計
          ln_year_price_sum  := gn_0;           -- 品目定価
--
          -- XML出力フラグ初期化
          <<xml_out_loop>>
          FOR n IN 1..12 LOOP
            gr_xml_out(n).out_fg   := lv_no;
          END LOOP xml_out_loop;
--
        END IF;
--
        -- ====================================================
        --  (拠点ごと)拠点ブレイク
        -- ====================================================
        -- 拠点が切り替わったとき
        IF (gr_sale_plan_1(i).ktn_code <> lv_ktn_break) THEN
          -------------------------------------------------------
          -- 各月抽出データが存在しない場合、0表示にてXML出力  --
          -------------------------------------------------------
          <<xml_out_0_loop>>
          FOR m IN 1..12 LOOP
            IF (gr_xml_out(m).out_fg = lv_no) THEN
              prc_create_xml_data_dtl_n
                (
                  iv_label_name     => gr_xml_out(m).tag_name                      -- 出力タグ名
                 ,ov_errbuf         => lv_errbuf   -- エラー・メッセージ           --# 固定 #
                 ,ov_retcode        => lv_retcode  -- リターン・コード             --# 固定 #
                 ,ov_errmsg         => lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
                );
              IF (lv_retcode = gv_status_error) THEN
                RAISE global_process_expt;
              END IF;
            END IF;
          END LOOP xml_out_0_loop;
--
          -- -----------------------------------------------------
          -- (拠点ごと)年計 数量データ
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'year_quant';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          gt_xml_data_table(gl_xml_idx).tag_value := ln_year_quant_sum;
--
          -- -----------------------------------------------------
          -- (拠点ごと)年計 金額データ
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'year_amount';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          gt_xml_data_table(gl_xml_idx).tag_value := ROUND(ln_year_amount_sum / 1000,0);
--
          -- -----------------------------------------------------
          -- (拠点ごと)年計 粗利率データ
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'year_arari_par';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
--
          ------------------------------------------------
          -- (拠点ごと)粗利計算 (金額－内訳合計＊数量)  --
          ------------------------------------------------
          ln_arari := ln_year_amount_sum - ln_year_to_am_sum * ln_year_quant_sum;
          -- ０除算回避判定
          IF (ln_year_amount_sum <> gn_0) THEN
          -- 値が[0]出なければ計算
          gt_xml_data_table(gl_xml_idx).tag_value := 
                    ROUND((ln_arari / ln_year_amount_sum * 100),2);
          ELSE
            -- 値が[0]の場合は、一律[0]設定
            gt_xml_data_table(gl_xml_idx).tag_value := gn_0;
          END IF;
--
          -- -----------------------------------------------------
          -- (拠点ごと)年計 掛率データ
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'year_kake_par';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
--
          --------------------------------------
          -- ０除算判定項目へ判定値を挿入     --
          --------------------------------------
          ln_chk_0 := ln_year_price_sum * ln_year_quant_sum;
          -- ０除算回避判定
          IF (ln_chk_0 <> gn_0) THEN
          -- 値が[0]出なければ計算
          ln_kake_par := ROUND((ln_year_amount_sum * 100) / ln_chk_0,2);
          ELSE
            -- 値が[0]の場合は、一律[0]設定
            ln_kake_par := gn_0;
          END IF;
--
          -- 品目定価 = ０か、計算結果がマイナスの場合、固定値[70.00]を登録
          IF ((ln_year_price_sum = 0)
            OR (ln_kake_par < 0)) THEN
            ln_kake_par := gn_kotei_70; -- 固定値[70.00]
          END IF;
          gt_xml_data_table(gl_xml_idx).tag_value := ln_kake_par;
--
          -- 各集計項目へデータ挿入
          <<add_total_loop>>
          FOR r IN 1..5 LOOP                     -- 小群計/大群計/拠点計/商品区分計/総合計
            gr_add_total(r).year_quant     :=
               gr_add_total(r).year_quant     + ln_year_quant_sum;        -- 数量
            gr_add_total(r).year_amount    :=
               gr_add_total(r).year_amount    + ln_year_amount_sum;       -- 金額
            gr_add_total(r).year_price     :=
               gr_add_total(r).year_price     + ln_year_price_sum;        -- 品目定価
            gr_add_total(r).year_to_amount :=
               gr_add_total(r).year_to_amount + ln_year_to_am_sum;        -- 内訳合計
            gr_add_total(r).year_quant_t   :=
               gr_add_total(r).year_quant_t   + ln_year_quant_sum;        -- 数量(計)
          END LOOP add_total_loop;
--
          -- -----------------------------------------------------
          --  (拠点ごと)品目終了Ｇタグ出力
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_dtl';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
          -- ----------------------------------------------------
          --  (拠点ごと)品目終了ＬＧタグ出力
          -- ----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_dtl_info';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
-- 2009/04/16 v1.6 T.Yoshimoto Mod Start
/*
          --------------------------------------------------------
          -- XMLデータ作成 - 帳票データ出力 小群計
          --------------------------------------------------------
          prc_create_xml_data_st_lt
            (
              iv_label_name     => gv_name_st                     -- 小群計用タグ名
             ,iv_name           => gv_label_st                    -- 小群計タイトル
             ,in_may_quant      => gr_add_total(1).may_quant      -- ５月 数量
             ,in_may_amount     => gr_add_total(1).may_amount     -- ５月 金額
             ,in_may_price      => gr_add_total(1).may_price      -- ５月 品目定価
             ,in_may_to_amount  => gr_add_total(1).may_to_amount  -- ５月 内訳合計
             ,in_may_quant_t    => gr_add_total(1).may_quant_t    -- ５月 数量(計算用)
             ,in_jun_quant      => gr_add_total(1).jun_quant      -- ６月 数量
             ,in_jun_amount     => gr_add_total(1).jun_amount     -- ６月 金額
             ,in_jun_price      => gr_add_total(1).jun_price      -- ６月 品目定価
             ,in_jun_to_amount  => gr_add_total(1).jun_to_amount  -- ６月 内訳合計
             ,in_jun_quant_t    => gr_add_total(1).jun_quant_t    -- ６月 数量(計算用)
             ,in_jul_quant      => gr_add_total(1).jul_quant      -- ７月 数量
             ,in_jul_amount     => gr_add_total(1).jul_amount     -- ７月 金額
             ,in_jul_price      => gr_add_total(1).jul_price      -- ７月 品目定価
             ,in_jul_to_amount  => gr_add_total(1).jul_to_amount  -- ７月 内訳合計
             ,in_jul_quant_t    => gr_add_total(1).jul_quant_t    -- ７月 数量(計算用)
             ,in_aug_quant      => gr_add_total(1).aug_quant      -- ８月 数量
             ,in_aug_amount     => gr_add_total(1).aug_amount     -- ８月 金額
             ,in_aug_price      => gr_add_total(1).aug_price      -- ８月 品目定価
             ,in_aug_to_amount  => gr_add_total(1).aug_to_amount  -- ８月 内訳合計
             ,in_aug_quant_t    => gr_add_total(1).aug_quant_t    -- ８月 数量(計算用)
             ,in_sep_quant      => gr_add_total(1).sep_quant      -- ９月 数量
             ,in_sep_amount     => gr_add_total(1).sep_amount     -- ９月 金額
             ,in_sep_price      => gr_add_total(1).sep_price      -- ９月 品目定価
             ,in_sep_to_amount  => gr_add_total(1).sep_to_amount  -- ９月 内訳合計
             ,in_sep_quant_t    => gr_add_total(1).sep_quant_t    -- ９月 数量(計算用)
             ,in_oct_quant      => gr_add_total(1).oct_quant      -- １０月 数量
             ,in_oct_amount     => gr_add_total(1).oct_amount     -- １０月 金額
             ,in_oct_price      => gr_add_total(1).oct_price      -- １０月 品目定価
             ,in_oct_to_amount  => gr_add_total(1).oct_to_amount  -- １０月 内訳合計
             ,in_oct_quant_t    => gr_add_total(1).oct_quant_t    -- １０月 数量(計算用)
             ,in_nov_quant      => gr_add_total(1).nov_quant      -- １１月 数量
             ,in_nov_amount     => gr_add_total(1).nov_amount     -- １１月 金額
             ,in_nov_price      => gr_add_total(1).nov_price      -- １１月 品目定価
             ,in_nov_to_amount  => gr_add_total(1).nov_to_amount  -- １１月 内訳合計
             ,in_nov_quant_t    => gr_add_total(1).nov_quant_t    -- １１月 数量(計算用)
             ,in_dec_quant      => gr_add_total(1).dec_quant      -- １２月 数量
             ,in_dec_amount     => gr_add_total(1).dec_amount     -- １２月 金額
             ,in_dec_price      => gr_add_total(1).dec_price      -- １２月 品目定価
             ,in_dec_to_amount  => gr_add_total(1).dec_to_amount  -- １２月 内訳合計
             ,in_dec_quant_t    => gr_add_total(1).dec_quant_t    -- １２月 数量(計算用)
             ,in_jan_quant      => gr_add_total(1).jan_quant      -- １月 数量
             ,in_jan_amount     => gr_add_total(1).jan_amount     -- １月 金額
             ,in_jan_price      => gr_add_total(1).jan_price      -- １月 品目定価
             ,in_jan_to_amount  => gr_add_total(1).jan_to_amount  -- １月 内訳合計
             ,in_jan_quant_t    => gr_add_total(1).jan_quant_t    -- １月 数量(計算用)
             ,in_feb_quant      => gr_add_total(1).feb_quant      -- ２月 数量
             ,in_feb_amount     => gr_add_total(1).feb_amount     -- ２月 金額
             ,in_feb_price      => gr_add_total(1).feb_price      -- ２月 品目定価
             ,in_feb_to_amount  => gr_add_total(1).feb_to_amount  -- ２月 内訳合計
             ,in_feb_quant_t    => gr_add_total(1).feb_quant_t    -- ２月 数量(計算用)
             ,in_mar_quant      => gr_add_total(1).mar_quant      -- ３月 数量
             ,in_mar_amount     => gr_add_total(1).mar_amount     -- ３月 金額
             ,in_mar_price      => gr_add_total(1).mar_price      -- ３月 品目定価
             ,in_mar_to_amount  => gr_add_total(1).mar_to_amount  -- ３月 内訳合計
             ,in_mar_quant_t    => gr_add_total(1).mar_quant_t    -- ３月 数量(計算用)
             ,in_apr_quant      => gr_add_total(1).apr_quant      -- ４月 数量
             ,in_apr_amount     => gr_add_total(1).apr_amount     -- ４月 金額
             ,in_apr_price      => gr_add_total(1).apr_price      -- ４月 品目定価
             ,in_apr_to_amount  => gr_add_total(1).apr_to_amount  -- ４月 内訳合計
             ,in_apr_quant_t    => gr_add_total(1).apr_quant_t    -- ４月 数量(計算用)
             ,in_year_quant     => gr_add_total(1).year_quant     -- 年計 数量
             ,in_year_amount    => gr_add_total(1).year_amount    -- 年計 金額
             ,in_year_price     => gr_add_total(1).year_price     -- 年計 品目定価
             ,in_year_to_amount => gr_add_total(1).year_to_amount -- 年計 内訳合計
             ,in_year_quant_t   => gr_add_total(1).year_quant_t   -- 年計 数量(計算用)
             ,ov_errbuf         => lv_errbuf   -- エラー・メッセージ           --# 固定 #
             ,ov_retcode        => lv_retcode  -- リターン・コード             --# 固定 #
             ,ov_errmsg         => lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
             );
          IF (lv_retcode = gv_status_error) THEN
            RAISE global_process_expt;
          END IF;
--
          --------------------------------------------------------
          -- 大群計データ出力 
          --------------------------------------------------------
          prc_create_xml_data_st_lt
            (
              iv_label_name     => gv_name_lt                     -- 大群計用タグ名
             ,iv_name           => gv_label_lt                    -- 大群計タイトル
             ,in_may_quant      => gr_add_total(2).may_quant      -- ５月 数量
             ,in_may_amount     => gr_add_total(2).may_amount     -- ５月 金額
             ,in_may_price      => gr_add_total(2).may_price      -- ５月 品目定価
             ,in_may_to_amount  => gr_add_total(2).may_to_amount  -- ５月 内訳合計
             ,in_may_quant_t    => gr_add_total(2).may_quant_t    -- ５月 数量(計算用)
             ,in_jun_quant      => gr_add_total(2).jun_quant      -- ６月 数量
             ,in_jun_amount     => gr_add_total(2).jun_amount     -- ６月 金額
             ,in_jun_price      => gr_add_total(2).jun_price      -- ６月 品目定価
             ,in_jun_to_amount  => gr_add_total(2).jun_to_amount  -- ６月 内訳合計
             ,in_jun_quant_t    => gr_add_total(2).jun_quant_t    -- ６月 数量(計算用)
             ,in_jul_quant      => gr_add_total(2).jul_quant      -- ７月 数量
             ,in_jul_amount     => gr_add_total(2).jul_amount     -- ７月 金額
             ,in_jul_price      => gr_add_total(2).jul_price      -- ７月 品目定価
             ,in_jul_to_amount  => gr_add_total(2).jul_to_amount  -- ７月 内訳合計
             ,in_jul_quant_t    => gr_add_total(2).jul_quant_t    -- ７月 数量(計算用)
             ,in_aug_quant      => gr_add_total(2).aug_quant      -- ８月 数量
             ,in_aug_amount     => gr_add_total(2).aug_amount     -- ８月 金額
             ,in_aug_price      => gr_add_total(2).aug_price      -- ８月 品目定価
             ,in_aug_to_amount  => gr_add_total(2).aug_to_amount  -- ８月 内訳合計
             ,in_aug_quant_t    => gr_add_total(2).aug_quant_t    -- ８月 数量(計算用)
             ,in_sep_quant      => gr_add_total(2).sep_quant      -- ９月 数量
             ,in_sep_amount     => gr_add_total(2).sep_amount     -- ９月 金額
             ,in_sep_price      => gr_add_total(2).sep_price      -- ９月 品目定価
             ,in_sep_to_amount  => gr_add_total(2).sep_to_amount  -- ９月 内訳合計
             ,in_sep_quant_t    => gr_add_total(2).sep_quant_t    -- ９月 数量(計算用)
             ,in_oct_quant      => gr_add_total(2).oct_quant      -- １０月 数量
             ,in_oct_amount     => gr_add_total(2).oct_amount     -- １０月 金額
             ,in_oct_price      => gr_add_total(2).oct_price      -- １０月 品目定価
             ,in_oct_to_amount  => gr_add_total(2).oct_to_amount  -- １０月 内訳合計
             ,in_oct_quant_t    => gr_add_total(2).oct_quant_t    -- １０月 数量(計算用)
             ,in_nov_quant      => gr_add_total(2).nov_quant      -- １１月 数量
             ,in_nov_amount     => gr_add_total(2).nov_amount     -- １１月 金額
             ,in_nov_price      => gr_add_total(2).nov_price      -- １１月 品目定価
             ,in_nov_to_amount  => gr_add_total(2).nov_to_amount  -- １１月 内訳合計
             ,in_nov_quant_t    => gr_add_total(2).nov_quant_t    -- １１月 数量(計算用)
             ,in_dec_quant      => gr_add_total(2).dec_quant      -- １２月 数量
             ,in_dec_amount     => gr_add_total(2).dec_amount     -- １２月 金額
             ,in_dec_price      => gr_add_total(2).dec_price      -- １２月 品目定価
             ,in_dec_to_amount  => gr_add_total(2).dec_to_amount  -- １２月 内訳合計
             ,in_dec_quant_t    => gr_add_total(2).dec_quant_t    -- １２月 数量(計算用)
             ,in_jan_quant      => gr_add_total(2).jan_quant      -- １月 数量
             ,in_jan_amount     => gr_add_total(2).jan_amount     -- １月 金額
             ,in_jan_price      => gr_add_total(2).jan_price      -- １月 品目定価
             ,in_jan_to_amount  => gr_add_total(2).jan_to_amount  -- １月 内訳合計
             ,in_jan_quant_t    => gr_add_total(2).jan_quant_t    -- １月 数量(計算用)
             ,in_feb_quant      => gr_add_total(2).feb_quant      -- ２月 数量
             ,in_feb_amount     => gr_add_total(2).feb_amount     -- ２月 金額
             ,in_feb_price      => gr_add_total(2).feb_price      -- ２月 品目定価
             ,in_feb_to_amount  => gr_add_total(2).feb_to_amount  -- ２月 内訳合計
             ,in_feb_quant_t    => gr_add_total(2).feb_quant_t    -- ２月 数量(計算用)
             ,in_mar_quant      => gr_add_total(2).mar_quant      -- ３月 数量
             ,in_mar_amount     => gr_add_total(2).mar_amount     -- ３月 金額
             ,in_mar_price      => gr_add_total(2).mar_price      -- ３月 品目定価
             ,in_mar_to_amount  => gr_add_total(2).mar_to_amount  -- ３月 内訳合計
             ,in_mar_quant_t    => gr_add_total(2).mar_quant_t    -- ３月 数量(計算用)
             ,in_apr_quant      => gr_add_total(2).apr_quant      -- ４月 数量
             ,in_apr_amount     => gr_add_total(2).apr_amount     -- ４月 金額
             ,in_apr_price      => gr_add_total(2).apr_price      -- ４月 品目定価
             ,in_apr_to_amount  => gr_add_total(2).apr_to_amount  -- ４月 内訳合計
             ,in_apr_quant_t    => gr_add_total(2).apr_quant_t    -- ４月 数量(計算用)
             ,in_year_quant     => gr_add_total(2).year_quant     -- 年計 数量
             ,in_year_amount    => gr_add_total(2).year_amount    -- 年計 金額
             ,in_year_price     => gr_add_total(2).year_price     -- 年計 品目定価
             ,in_year_to_amount => gr_add_total(2).year_to_amount -- 年計 内訳合計
             ,in_year_quant_t   => gr_add_total(2).year_quant_t   -- 年計 数量(計算用)
             ,ov_errbuf         => lv_errbuf   -- エラー・メッセージ           --# 固定 #
             ,ov_retcode        => lv_retcode  -- リターン・コード             --# 固定 #
             ,ov_errmsg         => lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
            );
          IF (lv_retcode = gv_status_error) THEN
            RAISE global_process_expt;
          END IF;
--
*/
          --------------------------------------------------------
          -- (拠点ごと)(1)小群計/(2)大群計データ出力 
          --------------------------------------------------------
          <<gun_loop>>
          FOR n IN 1..2 LOOP        -- 小群計/大群計
--
            -- 小群計の場合
            IF ( n = 1) THEN
              lv_param_name  := gv_name_st;
              lv_param_label := gv_label_st;
            -- 大群計の場合
            ELSE
              lv_param_name  := gv_name_lt;
              lv_param_label := gv_label_lt;
            END IF;
--
            prc_create_xml_data_st_lt
            (
                iv_label_name      => lv_param_name                   -- 大群計用タグ名
              ,iv_name            => lv_param_label                  -- 大群計タイトル
              ,in_may_quant       => gr_add_total(n).may_quant       -- ５月 数量
              ,in_may_amount      => gr_add_total(n).may_amount      -- ５月 金額
              ,in_may_price       => gr_add_total(n).may_price       -- ５月 品目定価
              ,in_may_to_amount   => gr_add_total(n).may_to_amount   -- ５月 内訳合計
              ,in_may_quant_t     => gr_add_total(n).may_quant_t     -- ５月 数量(計算用)
              ,in_may_s_cost      => gr_add_total(n).may_s_cost      -- ５月 標準原価(計算用)
              ,in_may_calc        => gr_add_total(n).may_calc        -- ５月 品目定価*数量(計算用)
              ,in_may_minus_flg   => gr_add_total(n).may_minus_flg   -- ５月 数量マイナス値存在フラグ(計算用)
              ,in_may_ht_zero_flg => gr_add_total(n).may_ht_zero_flg -- ５月 品目定価*数量(計)
              ,in_jun_quant       => gr_add_total(n).jun_quant       -- ６月 数量
              ,in_jun_amount      => gr_add_total(n).jun_amount      -- ６月 金額
              ,in_jun_price       => gr_add_total(n).jun_price       -- ６月 品目定価
              ,in_jun_to_amount   => gr_add_total(n).jun_to_amount   -- ６月 内訳合計
              ,in_jun_quant_t     => gr_add_total(n).jun_quant_t     -- ６月 数量(計算用)
              ,in_jun_s_cost      => gr_add_total(n).jun_s_cost      -- ６月 標準原価(計算用)
              ,in_jun_calc        => gr_add_total(n).jun_calc        -- ６月 品目定価*数量(計算用)
              ,in_jun_minus_flg   => gr_add_total(n).jun_minus_flg   -- ６月 数量マイナス値存在フラグ(計算用)
              ,in_jun_ht_zero_flg => gr_add_total(n).jun_ht_zero_flg -- ６月 品目定価*数量(計)
              ,in_jul_quant       => gr_add_total(n).jul_quant       -- ７月 数量
              ,in_jul_amount      => gr_add_total(n).jul_amount      -- ７月 金額
              ,in_jul_price       => gr_add_total(n).jul_price       -- ７月 品目定価
              ,in_jul_to_amount   => gr_add_total(n).jul_to_amount   -- ７月 内訳合計
              ,in_jul_quant_t     => gr_add_total(n).jul_quant_t     -- ７月 数量(計算用)
              ,in_jul_s_cost      => gr_add_total(n).jul_s_cost      -- ７月 標準原価(計算用)
              ,in_jul_calc        => gr_add_total(n).jul_calc        -- ７月 品目定価*数量(計算用)
              ,in_jul_minus_flg   => gr_add_total(n).jul_minus_flg   -- ７月 数量マイナス値存在フラグ(計算用)
              ,in_jul_ht_zero_flg => gr_add_total(n).jul_ht_zero_flg -- ７月 品目定価*数量(計)
              ,in_aug_quant       => gr_add_total(n).aug_quant       -- ８月 数量
              ,in_aug_amount      => gr_add_total(n).aug_amount      -- ８月 金額
              ,in_aug_price       => gr_add_total(n).aug_price       -- ８月 品目定価
              ,in_aug_to_amount   => gr_add_total(n).aug_to_amount   -- ８月 内訳合計
              ,in_aug_quant_t     => gr_add_total(n).aug_quant_t     -- ８月 数量(計算用)
              ,in_aug_s_cost      => gr_add_total(n).aug_s_cost      -- ８月 標準原価(計算用)
              ,in_aug_calc        => gr_add_total(n).aug_calc        -- ８月 品目定価*数量(計算用)
              ,in_aug_minus_flg   => gr_add_total(n).aug_minus_flg   -- ８月 数量マイナス値存在フラグ(計算用)
              ,in_aug_ht_zero_flg => gr_add_total(n).aug_ht_zero_flg -- ８月 品目定価*数量(計)
              ,in_sep_quant       => gr_add_total(n).sep_quant       -- ９月 数量
              ,in_sep_amount      => gr_add_total(n).sep_amount      -- ９月 金額
              ,in_sep_price       => gr_add_total(n).sep_price       -- ９月 品目定価
              ,in_sep_to_amount   => gr_add_total(n).sep_to_amount   -- ９月 内訳合計
              ,in_sep_quant_t     => gr_add_total(n).sep_quant_t     -- ９月 数量(計算用)
              ,in_sep_s_cost      => gr_add_total(n).sep_s_cost      -- ９月 標準原価(計算用)
              ,in_sep_calc        => gr_add_total(n).sep_calc        -- ９月 品目定価*数量(計算用)
              ,in_sep_minus_flg   => gr_add_total(n).sep_minus_flg   -- ９月 数量マイナス値存在フラグ(計算用)
              ,in_sep_ht_zero_flg => gr_add_total(n).sep_ht_zero_flg -- ９月 品目定価*数量(計)
              ,in_oct_quant       => gr_add_total(n).oct_quant       -- １０月 数量
              ,in_oct_amount      => gr_add_total(n).oct_amount      -- １０月 金額
              ,in_oct_price       => gr_add_total(n).oct_price       -- １０月 品目定価
              ,in_oct_to_amount   => gr_add_total(n).oct_to_amount   -- １０月 内訳合計
              ,in_oct_quant_t     => gr_add_total(n).oct_quant_t     -- １０月 数量(計算用)
              ,in_oct_s_cost      => gr_add_total(n).oct_s_cost      -- １０月 標準原価(計算用)
              ,in_oct_calc        => gr_add_total(n).oct_calc        -- １０月 品目定価*数量(計算用)
              ,in_oct_minus_flg   => gr_add_total(n).oct_minus_flg   -- １０月 数量マイナス値存在フラグ(計算用)
              ,in_oct_ht_zero_flg => gr_add_total(n).oct_ht_zero_flg -- １０月 品目定価*数量(計)
              ,in_nov_quant       => gr_add_total(n).nov_quant       -- １１月 数量
              ,in_nov_amount      => gr_add_total(n).nov_amount      -- １１月 金額
              ,in_nov_price       => gr_add_total(n).nov_price       -- １１月 品目定価
              ,in_nov_to_amount   => gr_add_total(n).nov_to_amount   -- １１月 内訳合計
              ,in_nov_quant_t     => gr_add_total(n).nov_quant_t     -- １１月 数量(計算用)
              ,in_nov_s_cost      => gr_add_total(n).nov_s_cost      -- １１月 標準原価(計算用)
              ,in_nov_calc        => gr_add_total(n).nov_calc        -- １１月 品目定価*数量(計算用)
              ,in_nov_minus_flg   => gr_add_total(n).nov_minus_flg   -- １１月 数量マイナス値存在フラグ(計算用)
              ,in_nov_ht_zero_flg => gr_add_total(n).nov_ht_zero_flg -- １１月 品目定価*数量(計)
              ,in_dec_quant       => gr_add_total(n).dec_quant       -- １２月 数量
              ,in_dec_amount      => gr_add_total(n).dec_amount      -- １２月 金額
              ,in_dec_price       => gr_add_total(n).dec_price       -- １２月 品目定価
              ,in_dec_to_amount   => gr_add_total(n).dec_to_amount   -- １２月 内訳合計
              ,in_dec_quant_t     => gr_add_total(n).dec_quant_t     -- １２月 数量(計算用)
              ,in_dec_s_cost      => gr_add_total(n).dec_s_cost      -- １２月 標準原価(計算用)
              ,in_dec_calc        => gr_add_total(n).dec_calc        -- １２月 品目定価*数量(計算用)
              ,in_dec_minus_flg   => gr_add_total(n).dec_minus_flg   -- １２月 数量マイナス値存在フラグ(計算用)
              ,in_dec_ht_zero_flg => gr_add_total(n).dec_ht_zero_flg -- １２月 品目定価*数量(計)
              ,in_jan_quant       => gr_add_total(n).jan_quant       -- １月 数量
              ,in_jan_amount      => gr_add_total(n).jan_amount      -- １月 金額
              ,in_jan_price       => gr_add_total(n).jan_price       -- １月 品目定価
              ,in_jan_to_amount   => gr_add_total(n).jan_to_amount   -- １月 内訳合計
              ,in_jan_quant_t     => gr_add_total(n).jan_quant_t     -- １月 数量(計算用)
              ,in_jan_s_cost      => gr_add_total(n).jan_s_cost      -- １月 標準原価(計算用)
              ,in_jan_calc        => gr_add_total(n).jan_calc        -- １月 品目定価*数量(計算用)
              ,in_jan_minus_flg   => gr_add_total(n).jan_minus_flg   -- １月 数量マイナス値存在フラグ(計算用)
              ,in_jan_ht_zero_flg => gr_add_total(n).jan_ht_zero_flg -- １月 品目定価*数量(計)
              ,in_feb_quant       => gr_add_total(n).feb_quant       -- ２月 数量
              ,in_feb_amount      => gr_add_total(n).feb_amount      -- ２月 金額
              ,in_feb_price       => gr_add_total(n).feb_price       -- ２月 品目定価
              ,in_feb_to_amount   => gr_add_total(n).feb_to_amount   -- ２月 内訳合計
              ,in_feb_quant_t     => gr_add_total(n).feb_quant_t     -- ２月 数量(計算用)
              ,in_feb_s_cost      => gr_add_total(n).feb_s_cost      -- ２月 標準原価(計算用)
              ,in_feb_calc        => gr_add_total(n).feb_calc        -- ２月 品目定価*数量(計算用)
              ,in_feb_minus_flg   => gr_add_total(n).feb_minus_flg   -- ２月 数量マイナス値存在フラグ(計算用)
              ,in_feb_ht_zero_flg => gr_add_total(n).feb_ht_zero_flg -- ２月 品目定価*数量(計)
              ,in_mar_quant       => gr_add_total(n).mar_quant       -- ３月 数量
              ,in_mar_amount      => gr_add_total(n).mar_amount      -- ３月 金額
              ,in_mar_price       => gr_add_total(n).mar_price       -- ３月 品目定価
              ,in_mar_to_amount   => gr_add_total(n).mar_to_amount   -- ３月 内訳合計
              ,in_mar_quant_t     => gr_add_total(n).mar_quant_t     -- ３月 数量(計算用)
              ,in_mar_s_cost      => gr_add_total(n).mar_s_cost      -- ３月 標準原価(計算用)
              ,in_mar_calc        => gr_add_total(n).mar_calc        -- ３月 品目定価*数量(計算用)
              ,in_mar_minus_flg   => gr_add_total(n).mar_minus_flg   -- ３月 数量マイナス値存在フラグ(計算用)
              ,in_mar_ht_zero_flg => gr_add_total(n).mar_ht_zero_flg -- ３月 品目定価*数量(計)
              ,in_apr_quant       => gr_add_total(n).apr_quant       -- ４月 数量
              ,in_apr_amount      => gr_add_total(n).apr_amount      -- ４月 金額
              ,in_apr_price       => gr_add_total(n).apr_price       -- ４月 品目定価
              ,in_apr_to_amount   => gr_add_total(n).apr_to_amount   -- ４月 内訳合計
              ,in_apr_quant_t     => gr_add_total(n).apr_quant_t     -- ４月 数量(計算用)
              ,in_apr_s_cost      => gr_add_total(n).apr_s_cost      -- ４月 標準原価(計算用)
              ,in_apr_calc        => gr_add_total(n).apr_calc        -- ４月 品目定価*数量(計算用)
              ,in_apr_minus_flg   => gr_add_total(n).apr_minus_flg   -- ４月 数量マイナス値存在フラグ(計算用)
              ,in_apr_ht_zero_flg => gr_add_total(n).apr_ht_zero_flg -- ４月 品目定価*数量(計)
              ,in_year_quant      => gr_add_total(n).year_quant        -- 年計 数量
              ,in_year_amount     => gr_add_total(n).year_amount       -- 年計 金額
              ,in_year_price      => gr_add_total(n).year_price        -- 年計 品目定価
              ,in_year_to_amount  => gr_add_total(n).year_to_amount    -- 年計 内訳合計
              ,in_year_quant_t    => gr_add_total(n).year_quant_t      -- 年計 数量(計算用)
              ,in_year_s_cost     => gr_add_total(n).year_s_cost       -- 年計 標準原価(計算用)
              ,in_year_calc       => gr_add_total(n).year_calc         -- 年計 品目定価*数量(計算用)
              ,in_year_minus_flg   => gr_add_total(n).year_minus_flg   -- 年計 数量マイナス値存在フラグ(計算用)
              ,in_year_ht_zero_flg => gr_add_total(n).year_ht_zero_flg -- 年計 品目定価*数量(計)
              ,ov_errbuf         => lv_errbuf   -- エラー・メッセージ           --# 固定 #
              ,ov_retcode        => lv_retcode  -- リターン・コード             --# 固定 #
              ,ov_errmsg         => lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
            );
            IF (lv_retcode = gv_status_error) THEN
              RAISE global_process_expt;
            END IF;
--
          END LOOP gun_loop;
-- 2009/04/16 v1.6 T.Yoshimoto Mod End
--
          -- -----------------------------------------------------
          --  (拠点ごと)群コード終了Ｇタグ出力
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_gun';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
          -- -----------------------------------------------------
          --  (拠点ごと)群コード終了ＬＧタグ出力
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_gun_info';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
          --------------------------------------------------------
          -- (拠点ごと)拠点計データタグ出力 
          --------------------------------------------------------
          prc_create_xml_data_s_k_t
          (
             iv_label_name     => gv_name_ktn                    -- 拠点計用タグ名
            ,in_may_quant      => gr_add_total(3).may_quant      -- ５月 数量
            ,in_may_amount     => gr_add_total(3).may_amount     -- ５月 金額
            ,in_may_price      => gr_add_total(3).may_price      -- ５月 品目定価
            ,in_may_to_amount  => gr_add_total(3).may_to_amount  -- ５月 内訳合計
            ,in_may_quant_t    => gr_add_total(3).may_quant_t    -- ５月 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
            ,in_may_s_cost     => gr_add_total(3).may_s_cost     -- ５月 標準原価(計算用)
            ,in_may_calc       => gr_add_total(3).may_calc       -- ５月 品目定価*数量(計算用)
            ,in_may_minus_flg   => gr_add_total(3).may_minus_flg   -- ５月 数量マイナス値存在フラグ(計算用)
            ,in_may_ht_zero_flg => gr_add_total(3).may_ht_zero_flg -- ５月 品目定価*数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
            ,in_jun_quant      => gr_add_total(3).jun_quant      -- ６月 数量
            ,in_jun_amount     => gr_add_total(3).jun_amount     -- ６月 金額
            ,in_jun_price      => gr_add_total(3).jun_price      -- ６月 品目定価
            ,in_jun_to_amount  => gr_add_total(3).jun_to_amount  -- ６月 内訳合計
            ,in_jun_quant_t    => gr_add_total(3).jun_quant_t    -- ６月 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
            ,in_jun_s_cost     => gr_add_total(3).jun_s_cost     -- ６月 標準原価(計算用)
            ,in_jun_calc       => gr_add_total(3).jun_calc       -- ６月 品目定価*数量(計算用)
            ,in_jun_minus_flg   => gr_add_total(3).jun_minus_flg   -- ６月 数量マイナス値存在フラグ(計算用)
            ,in_jun_ht_zero_flg => gr_add_total(3).jun_ht_zero_flg -- ６月 品目定価*数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
            ,in_jul_quant      => gr_add_total(3).jul_quant      -- ７月 数量
            ,in_jul_amount     => gr_add_total(3).jul_amount     -- ７月 金額
            ,in_jul_price      => gr_add_total(3).jul_price      -- ７月 品目定価
            ,in_jul_to_amount  => gr_add_total(3).jul_to_amount  -- ７月 内訳合計
            ,in_jul_quant_t    => gr_add_total(3).jul_quant_t    -- ７月 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
            ,in_jul_s_cost     => gr_add_total(3).jul_s_cost     -- ７月 標準原価(計算用)
            ,in_jul_calc       => gr_add_total(3).jul_calc       -- ７月 品目定価*数量(計算用)
            ,in_jul_minus_flg   => gr_add_total(3).jul_minus_flg   -- ７月 数量マイナス値存在フラグ(計算用)
            ,in_jul_ht_zero_flg => gr_add_total(3).jul_ht_zero_flg -- ７月 品目定価*数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
            ,in_aug_quant      => gr_add_total(3).aug_quant      -- ８月 数量
            ,in_aug_amount     => gr_add_total(3).aug_amount     -- ８月 金額
            ,in_aug_price      => gr_add_total(3).aug_price      -- ８月 品目定価
            ,in_aug_to_amount  => gr_add_total(3).aug_to_amount  -- ８月 内訳合計
            ,in_aug_quant_t    => gr_add_total(3).aug_quant_t    -- ８月 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
            ,in_aug_s_cost     => gr_add_total(3).aug_s_cost     -- ８月 標準原価(計算用)
            ,in_aug_calc       => gr_add_total(3).aug_calc       -- ８月 品目定価*数量(計算用)
            ,in_aug_minus_flg   => gr_add_total(3).aug_minus_flg   -- ８月 数量マイナス値存在フラグ(計算用)
            ,in_aug_ht_zero_flg => gr_add_total(3).aug_ht_zero_flg -- ８月 品目定価*数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
            ,in_sep_quant      => gr_add_total(3).sep_quant      -- ９月 数量
            ,in_sep_amount     => gr_add_total(3).sep_amount     -- ９月 金額
            ,in_sep_price      => gr_add_total(3).sep_price      -- ９月 品目定価
            ,in_sep_to_amount  => gr_add_total(3).sep_to_amount  -- ９月 内訳合計
            ,in_sep_quant_t    => gr_add_total(3).sep_quant_t    -- ９月 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
            ,in_sep_s_cost     => gr_add_total(3).sep_s_cost     -- ９月 標準原価(計算用)
            ,in_sep_calc       => gr_add_total(3).sep_calc       -- ９月 品目定価*数量(計算用)
            ,in_sep_minus_flg   => gr_add_total(3).sep_minus_flg   -- ９月 数量マイナス値存在フラグ(計算用)
            ,in_sep_ht_zero_flg => gr_add_total(3).sep_ht_zero_flg -- ９月 品目定価*数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
            ,in_oct_quant      => gr_add_total(3).oct_quant      -- １０月 数量
            ,in_oct_amount     => gr_add_total(3).oct_amount     -- １０月 金額
            ,in_oct_price      => gr_add_total(3).oct_price      -- １０月 品目定価
            ,in_oct_to_amount  => gr_add_total(3).oct_to_amount  -- １０月 内訳合計
            ,in_oct_quant_t    => gr_add_total(3).oct_quant_t    -- １０月 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
            ,in_oct_s_cost     => gr_add_total(3).oct_s_cost     -- １０月 標準原価(計算用)
            ,in_oct_calc       => gr_add_total(3).oct_calc       -- １０月 品目定価*数量(計算用)
            ,in_oct_minus_flg   => gr_add_total(3).oct_minus_flg   -- １０月 数量マイナス値存在フラグ(計算用)
            ,in_oct_ht_zero_flg => gr_add_total(3).oct_ht_zero_flg -- １０月 品目定価*数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
            ,in_nov_quant      => gr_add_total(3).nov_quant      -- １１月 数量
            ,in_nov_amount     => gr_add_total(3).nov_amount     -- １１月 金額
            ,in_nov_price      => gr_add_total(3).nov_price      -- １１月 品目定価
            ,in_nov_to_amount  => gr_add_total(3).nov_to_amount  -- １１月 内訳合計
            ,in_nov_quant_t    => gr_add_total(3).nov_quant_t    -- １１月 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
            ,in_nov_s_cost     => gr_add_total(3).nov_s_cost     -- １１月 標準原価(計算用)
            ,in_nov_calc       => gr_add_total(3).nov_calc       -- １１月 品目定価*数量(計算用)
            ,in_nov_minus_flg   => gr_add_total(3).nov_minus_flg   -- １１月 数量マイナス値存在フラグ(計算用)
            ,in_nov_ht_zero_flg => gr_add_total(3).nov_ht_zero_flg -- １１月 品目定価*数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
            ,in_dec_quant      => gr_add_total(3).dec_quant      -- １２月 数量
            ,in_dec_amount     => gr_add_total(3).dec_amount     -- １２月 金額
            ,in_dec_price      => gr_add_total(3).dec_price      -- １２月 品目定価
            ,in_dec_to_amount  => gr_add_total(3).dec_to_amount  -- １２月 内訳合計
            ,in_dec_quant_t    => gr_add_total(3).dec_quant_t    -- １２月 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
            ,in_dec_s_cost     => gr_add_total(3).dec_s_cost     -- １２月 標準原価(計算用)
            ,in_dec_calc       => gr_add_total(3).dec_calc       -- １２月 品目定価*数量(計算用)
            ,in_dec_minus_flg   => gr_add_total(3).dec_minus_flg   -- １２月 数量マイナス値存在フラグ(計算用)
            ,in_dec_ht_zero_flg => gr_add_total(3).dec_ht_zero_flg -- １２月 品目定価*数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
            ,in_jan_quant      => gr_add_total(3).jan_quant      -- １月 数量
            ,in_jan_amount     => gr_add_total(3).jan_amount     -- １月 金額
            ,in_jan_price      => gr_add_total(3).jan_price      -- １月 品目定価
            ,in_jan_to_amount  => gr_add_total(3).jan_to_amount  -- １月 内訳合計
            ,in_jan_quant_t    => gr_add_total(3).jan_quant_t    -- １月 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
            ,in_jan_s_cost     => gr_add_total(3).jan_s_cost     -- １月 標準原価(計算用)
            ,in_jan_calc       => gr_add_total(3).jan_calc       -- １月 品目定価*数量(計算用)
            ,in_jan_minus_flg   => gr_add_total(3).jan_minus_flg   -- １月 数量マイナス値存在フラグ(計算用)
            ,in_jan_ht_zero_flg => gr_add_total(3).jan_ht_zero_flg -- １月 品目定価*数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
            ,in_feb_quant      => gr_add_total(3).feb_quant      -- ２月 数量
            ,in_feb_amount     => gr_add_total(3).feb_amount     -- ２月 金額
            ,in_feb_price      => gr_add_total(3).feb_price      -- ２月 品目定価
            ,in_feb_to_amount  => gr_add_total(3).feb_to_amount  -- ２月 内訳合計
            ,in_feb_quant_t    => gr_add_total(3).feb_quant_t    -- ２月 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
            ,in_feb_s_cost     => gr_add_total(3).feb_s_cost     -- ２月 標準原価(計算用)
            ,in_feb_calc       => gr_add_total(3).feb_calc       -- ２月 品目定価*数量(計算用)
            ,in_feb_minus_flg   => gr_add_total(3).feb_minus_flg   -- ２月 数量マイナス値存在フラグ(計算用)
            ,in_feb_ht_zero_flg => gr_add_total(3).feb_ht_zero_flg -- ２月 品目定価*数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
            ,in_mar_quant      => gr_add_total(3).mar_quant      -- ３月 数量
            ,in_mar_amount     => gr_add_total(3).mar_amount     -- ３月 金額
            ,in_mar_price      => gr_add_total(3).mar_price      -- ３月 品目定価
            ,in_mar_to_amount  => gr_add_total(3).mar_to_amount  -- ３月 内訳合計
            ,in_mar_quant_t    => gr_add_total(3).mar_quant_t    -- ３月 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
            ,in_mar_s_cost     => gr_add_total(3).mar_s_cost     -- ３月 標準原価(計算用)
            ,in_mar_calc       => gr_add_total(3).mar_calc       -- ３月 品目定価*数量(計算用)
            ,in_mar_minus_flg   => gr_add_total(3).mar_minus_flg   -- ３月 数量マイナス値存在フラグ(計算用)
            ,in_mar_ht_zero_flg => gr_add_total(3).mar_ht_zero_flg -- ３月 品目定価*数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
            ,in_apr_quant      => gr_add_total(3).apr_quant      -- ４月 数量
            ,in_apr_amount     => gr_add_total(3).apr_amount     -- ４月 金額
            ,in_apr_price      => gr_add_total(3).apr_price      -- ４月 品目定価
            ,in_apr_to_amount  => gr_add_total(3).apr_to_amount  -- ４月 内訳合計
            ,in_apr_quant_t    => gr_add_total(3).apr_quant_t    -- ４月 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
            ,in_apr_s_cost     => gr_add_total(3).apr_s_cost     -- ４月 標準原価(計算用)
            ,in_apr_calc       => gr_add_total(3).apr_calc       -- ４月 品目定価*数量(計算用)
            ,in_apr_minus_flg   => gr_add_total(3).apr_minus_flg   -- ４月 数量マイナス値存在フラグ(計算用)
            ,in_apr_ht_zero_flg => gr_add_total(3).apr_ht_zero_flg -- ４月 品目定価*数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
            ,in_year_quant     => gr_add_total(3).year_quant     -- 年計 数量
            ,in_year_amount    => gr_add_total(3).year_amount    -- 年計 金額
            ,in_year_price     => gr_add_total(3).year_price     -- 年計 品目定価
            ,in_year_to_amount => gr_add_total(3).year_to_amount -- 年計 内訳合計
            ,in_year_quant_t   => gr_add_total(3).year_quant_t   -- 年計 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
            ,in_year_s_cost    => gr_add_total(3).year_s_cost    -- 年計 標準原価(計算用)
            ,in_year_calc      => gr_add_total(3).year_calc      -- 年計 品目定価*数量(計算用)
            ,in_year_minus_flg   => gr_add_total(3).year_minus_flg   -- 年計 数量マイナス値存在フラグ(計算用)
            ,in_year_ht_zero_flg => gr_add_total(3).year_ht_zero_flg -- 年計 品目定価*数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
            ,ov_errbuf         => lv_errbuf   -- エラー・メッセージ           --# 固定 #
            ,ov_retcode        => lv_retcode  -- リターン・コード             --# 固定 #
            ,ov_errmsg         => lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
          );
          IF (lv_retcode = gv_status_error) THEN
            RAISE global_process_expt;
          END IF;
--
          -- -----------------------------------------------------
          --  (拠点ごと)拠点終了Ｇタグ出力
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_ktn';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
          -- -----------------------------------------------------
          --  (拠点ごと)拠点開始Ｇタグ出力
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'g_ktn';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
          ----------------------------------------------------------------
          -- (拠点ごと)拠点区分(拠点コード) タグ
          ----------------------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'ktn_code';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          gt_xml_data_table(gl_xml_idx).tag_value := gr_sale_plan_1(i).ktn_code;
--
          ----------------------------------------------------------------
          -- (拠点ごと)拠点区分(拠点略称) タグ
          ----------------------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'ktn_name';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          gt_xml_data_table(gl_xml_idx).tag_value := gr_sale_plan_1(i).party_short_name;
--
          -- -----------------------------------------------------
          --  (拠点ごと)群コード開始LＧタグ出力
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_gun_info';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
          -- -----------------------------------------------------
          --  (拠点ごと)群コード開始Ｇタグ出力
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'g_gun';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
          -- -----------------------------------------------------
          --  (拠点ごと)品目開始ＬＧタグ出力
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_dtl_info';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
          -- 各ブレイクキー更新
          lv_ktn_break  := gr_sale_plan_1(i).ktn_code;          -- 拠点
          lv_gun_break  := gr_sale_plan_1(i).gun;               -- 群コード
          lv_dtl_break  := lv_break_init;                       -- 品目コード
          lv_sttl_break := SUBSTRB(gr_sale_plan_1(i).gun,1,3);  -- 小群計
          lv_lttl_break := SUBSTRB(gr_sale_plan_1(i).gun,1,1);  -- 大群計
--
          ----------------------------------------
          -- (拠点ごと)各集計項目初期化         --
          ----------------------------------------
          <<add_total_loop>>
          FOR r IN 1..3 LOOP           -- 小群計/大群計/拠点計
            gr_add_total(r).may_quant       := gn_0; -- ５月 数量
            gr_add_total(r).may_amount      := gn_0; -- ５月 金額
            gr_add_total(r).may_price       := gn_0; -- ５月 品目定価
            gr_add_total(r).may_to_amount   := gn_0; -- ５月 内訳合計
            gr_add_total(r).may_quant_t     := gn_0; -- ５月 数量(計)
            gr_add_total(r).jun_quant       := gn_0; -- ６月 数量
            gr_add_total(r).jun_amount      := gn_0; -- ６月 金額
            gr_add_total(r).jun_price       := gn_0; -- ６月 品目定価
            gr_add_total(r).jun_to_amount   := gn_0; -- ６月 内訳合計
            gr_add_total(r).jun_quant_t     := gn_0; -- ６月 数量(計)
            gr_add_total(r).jul_quant       := gn_0; -- ７月 数量
            gr_add_total(r).jul_amount      := gn_0; -- ７月 金額
            gr_add_total(r).jul_price       := gn_0; -- ７月 品目定価
            gr_add_total(r).jul_to_amount   := gn_0; -- ７月 内訳合計
            gr_add_total(r).jul_quant_t     := gn_0; -- ７月 数量(計)
            gr_add_total(r).aug_quant       := gn_0; -- ８月 数量
            gr_add_total(r).aug_amount      := gn_0; -- ８月 金額
            gr_add_total(r).aug_price       := gn_0; -- ８月 品目定価
            gr_add_total(r).aug_to_amount   := gn_0; -- ８月 内訳合計
            gr_add_total(r).aug_quant_t     := gn_0; -- ８月 数量(計)
            gr_add_total(r).sep_quant       := gn_0; -- ９月 数量
            gr_add_total(r).sep_amount      := gn_0; -- ９月 金額
            gr_add_total(r).sep_price       := gn_0; -- ９月 品目定価
            gr_add_total(r).sep_to_amount   := gn_0; -- ９月 内訳合計
            gr_add_total(r).sep_quant_t     := gn_0; -- ９月 数量(計)
            gr_add_total(r).oct_quant       := gn_0; -- １０月 数量
            gr_add_total(r).oct_amount      := gn_0; -- １０月 金額
            gr_add_total(r).oct_price       := gn_0; -- １０月 品目定価
            gr_add_total(r).oct_to_amount   := gn_0; -- １０月 内訳合計
            gr_add_total(r).oct_quant_t     := gn_0; -- １０月 数量(計)
            gr_add_total(r).nov_quant       := gn_0; -- １１月 数量
            gr_add_total(r).nov_amount      := gn_0; -- １１月 金額
            gr_add_total(r).nov_price       := gn_0; -- １１月 品目定価
            gr_add_total(r).nov_to_amount   := gn_0; -- １１月 内訳合計
            gr_add_total(r).nov_quant_t     := gn_0; -- １１月 数量(計)
            gr_add_total(r).dec_quant       := gn_0; -- １２月 数量
            gr_add_total(r).dec_amount      := gn_0; -- １２月 金額
            gr_add_total(r).dec_price       := gn_0; -- １２月 品目定価
            gr_add_total(r).dec_to_amount   := gn_0; -- １２月 内訳合計
            gr_add_total(r).dec_quant_t     := gn_0; -- １２月 数量(計)
            gr_add_total(r).jan_quant       := gn_0; -- １２月 数量
            gr_add_total(r).jan_amount      := gn_0; -- １月 金額
            gr_add_total(r).jan_price       := gn_0; -- １月 品目定価
            gr_add_total(r).jan_to_amount   := gn_0; -- １月 内訳合計
            gr_add_total(r).jan_quant_t     := gn_0; -- １月 数量(計)
            gr_add_total(r).feb_quant       := gn_0; -- ２月 数量
            gr_add_total(r).feb_amount      := gn_0; -- ２月 金額
            gr_add_total(r).feb_price       := gn_0; -- ２月 品目定価
            gr_add_total(r).feb_to_amount   := gn_0; -- ２月 内訳合計
            gr_add_total(r).feb_quant_t     := gn_0; -- ２月 数量(計)
            gr_add_total(r).mar_quant       := gn_0; -- ３月 数量
            gr_add_total(r).mar_amount      := gn_0; -- ３月 金額
            gr_add_total(r).mar_price       := gn_0; -- ３月 品目定価
            gr_add_total(r).mar_to_amount   := gn_0; -- ３月 内訳合計
            gr_add_total(r).mar_quant_t     := gn_0; -- ３月 数量(計)
            gr_add_total(r).apr_quant       := gn_0; -- ４月 数量
            gr_add_total(r).apr_amount      := gn_0; -- ４月 金額
            gr_add_total(r).apr_price       := gn_0; -- ４月 品目定価
            gr_add_total(r).apr_to_amount   := gn_0; -- ４月 内訳合計
            gr_add_total(r).apr_quant_t     := gn_0; -- ４月 数量(計)
            gr_add_total(r).year_quant      := gn_0; -- 年計 数量
            gr_add_total(r).year_amount     := gn_0; -- 年計 金額
            gr_add_total(r).year_price      := gn_0; -- 年計 品目定価
            gr_add_total(r).year_to_amount  := gn_0; -- 年計 内訳合計
            gr_add_total(r).year_quant_t    := gn_0; -- 年計 数量(計)
          END LOOP add_total_loop;
--
          -- 年計初期化
          ln_year_quant_sum  := gn_0;           -- 数量
          ln_year_amount_sum := gn_0;           -- 金額
          ln_year_to_am_sum  := gn_0;           -- 内訳合計
          ln_year_price_sum  := gn_0;           -- 品目定価
--
          -- XML出力フラグ初期化
          <<xml_out_loop>>
          FOR n IN 1..12 LOOP
            gr_xml_out(n).out_fg   := lv_no;
          END LOOP xml_out_loop;
--
        END IF;
--
        -- ====================================================
        --  (拠点ごと)群コードブレイク
        -- ====================================================
        -- 群コードが切り替わったとき
        IF (gr_sale_plan_1(i).gun <> lv_gun_break) THEN
          -------------------------------------------------------
          -- 各月抽出データが存在しない場合、0表示にてXML出力  --
          -------------------------------------------------------
          <<xml_out_0_loop>>
          FOR m IN 1..12 LOOP
            IF (gr_xml_out(m).out_fg = lv_no) THEN
              prc_create_xml_data_dtl_n
                (
                  iv_label_name     => gr_xml_out(m).tag_name                      -- 出力タグ名
                 ,ov_errbuf         => lv_errbuf   -- エラー・メッセージ           --# 固定 #
                 ,ov_retcode        => lv_retcode  -- リターン・コード             --# 固定 #
                 ,ov_errmsg         => lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
                );
              IF (lv_retcode = gv_status_error) THEN
                RAISE global_process_expt;
              END IF;
            END IF;
          END LOOP xml_out_0_loop;
--
          -- -----------------------------------------------------
          -- (拠点ごと)年計 数量データ
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'year_quant';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          gt_xml_data_table(gl_xml_idx).tag_value := ln_year_quant_sum;
--
          -- -----------------------------------------------------
          -- (拠点ごと)年計 金額データ
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'year_amount';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          gt_xml_data_table(gl_xml_idx).tag_value := ROUND(ln_year_amount_sum / 1000,0);
--
          -- -----------------------------------------------------
          -- (拠点ごと)年計 粗利率データ
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'year_arari_par';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
--
          ------------------------------------------------
          -- (拠点ごと)粗利計算 (金額－内訳合計＊数量)  --
          ------------------------------------------------
          ln_arari := ln_year_amount_sum - ln_year_to_am_sum * ln_year_quant_sum;
          -- ０除算回避判定
          IF (ln_year_amount_sum <> gn_0) THEN
          -- 値が[0]出なければ計算
          gt_xml_data_table(gl_xml_idx).tag_value := 
                    ROUND((ln_arari / ln_year_amount_sum * 100),2);
          ELSE
            -- 値が[0]の場合は、一律[0]設定
            gt_xml_data_table(gl_xml_idx).tag_value := gn_0;
          END IF;
--
          -- -----------------------------------------------------
          -- (拠点ごと)年計 掛率データ
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'year_kake_par';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
--
          --------------------------------------
          -- ０除算判定項目へ判定値を挿入     --
          --------------------------------------
          ln_chk_0 := ln_year_price_sum * ln_year_quant_sum;
          -- ０除算回避判定
          IF (ln_chk_0 <> gn_0) THEN
          -- 値が[0]出なければ計算
          ln_kake_par := ROUND((ln_year_amount_sum * 100) / ln_chk_0,2);
          ELSE
            -- 値が[0]の場合は、一律[0]設定
            ln_kake_par := gn_0;
          END IF;
--
          -- 品目定価 = ０か、計算結果がマイナスの場合、固定値[70.00]を登録
          IF ((ln_year_price_sum = 0)
            OR (ln_kake_par < 0)) THEN
            ln_kake_par := gn_kotei_70; -- 固定値[70.00]
          END IF;
          gt_xml_data_table(gl_xml_idx).tag_value := ln_kake_par;
--
          -- 各集計項目へデータ挿入
          <<add_total_loop>>
          FOR r IN 1..5 LOOP                     -- 小群計/大群計/拠点計/商品区分計/総合計
            gr_add_total(r).year_quant     :=
               gr_add_total(r).year_quant     + ln_year_quant_sum;        -- 数量
            gr_add_total(r).year_amount    :=
               gr_add_total(r).year_amount    + ln_year_amount_sum;       -- 金額
            gr_add_total(r).year_price     :=
               gr_add_total(r).year_price     + ln_year_price_sum;        -- 品目定価
            gr_add_total(r).year_to_amount :=
               gr_add_total(r).year_to_amount + ln_year_to_am_sum;        -- 内訳合計
            gr_add_total(r).year_quant_t   :=
               gr_add_total(r).year_quant_t   + ln_year_quant_sum;        -- 数量(計)
          END LOOP add_total_loop;
--
          -- -----------------------------------------------------
          --  (拠点ごと)品目終了Ｇタグ出力
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_dtl';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
          -- -----------------------------------------------------
          --  (拠点ごと)品目終了ＬＧタグ出力
          -- ----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_dtl_info';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
          -- ====================================================
          --  (拠点ごと)小群計ブレイク
          -- ====================================================
          IF (SUBSTRB(gr_sale_plan_1(i).gun,1,3) <> lv_sttl_break) THEN
            --------------------------------------------------------
            -- XMLデータ作成 - 帳票データ出力 小群計
            --------------------------------------------------------
            prc_create_xml_data_st_lt
            (
               iv_label_name     => gv_name_st                     -- 小群計用タグ名
              ,iv_name           => gv_label_st                    -- 小群計タイトル
              ,in_may_quant      => gr_add_total(1).may_quant      -- ５月 数量
              ,in_may_amount     => gr_add_total(1).may_amount     -- ５月 金額
              ,in_may_price      => gr_add_total(1).may_price      -- ５月 品目定価
              ,in_may_to_amount  => gr_add_total(1).may_to_amount  -- ５月 内訳合計
              ,in_may_quant_t    => gr_add_total(1).may_quant_t    -- ５月 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
              ,in_may_s_cost     => gr_add_total(1).may_s_cost     -- ５月 標準原価(計算用)
              ,in_may_calc       => gr_add_total(1).may_calc       -- ５月 品目定価*数量(計算用)
              ,in_may_minus_flg   => gr_add_total(1).may_minus_flg   -- ５月 数量マイナス値存在フラグ(計算用)
              ,in_may_ht_zero_flg => gr_add_total(1).may_ht_zero_flg -- ５月 品目定価0値存在フラグ(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
              ,in_jun_quant      => gr_add_total(1).jun_quant      -- ６月 数量
              ,in_jun_amount     => gr_add_total(1).jun_amount     -- ６月 金額
              ,in_jun_price      => gr_add_total(1).jun_price      -- ６月 品目定価
              ,in_jun_to_amount  => gr_add_total(1).jun_to_amount  -- ６月 内訳合計
              ,in_jun_quant_t    => gr_add_total(1).jun_quant_t    -- ６月 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
              ,in_jun_s_cost     => gr_add_total(1).jun_s_cost     -- ６月 標準原価(計算用)
              ,in_jun_calc       => gr_add_total(1).jun_calc       -- ６月 品目定価*数量(計算用)
              ,in_jun_minus_flg   => gr_add_total(1).jun_minus_flg   -- ６月 数量マイナス値存在フラグ(計算用)
              ,in_jun_ht_zero_flg => gr_add_total(1).jun_ht_zero_flg -- ６月 品目定価0値存在フラグ(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
              ,in_jul_quant      => gr_add_total(1).jul_quant      -- ７月 数量
              ,in_jul_amount     => gr_add_total(1).jul_amount     -- ７月 金額
              ,in_jul_price      => gr_add_total(1).jul_price      -- ７月 品目定価
              ,in_jul_to_amount  => gr_add_total(1).jul_to_amount  -- ７月 内訳合計
              ,in_jul_quant_t    => gr_add_total(1).jul_quant_t    -- ７月 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
              ,in_jul_s_cost     => gr_add_total(1).jul_s_cost     -- ７月 標準原価(計算用)
              ,in_jul_calc       => gr_add_total(1).jul_calc       -- ７月 品目定価*数量(計算用)
              ,in_jul_minus_flg   => gr_add_total(1).jul_minus_flg   -- ７月 数量マイナス値存在フラグ(計算用)
              ,in_jul_ht_zero_flg => gr_add_total(1).jul_ht_zero_flg -- ７月 品目定価0値存在フラグ(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
              ,in_aug_quant      => gr_add_total(1).aug_quant      -- ８月 数量
              ,in_aug_amount     => gr_add_total(1).aug_amount     -- ８月 金額
              ,in_aug_price      => gr_add_total(1).aug_price      -- ８月 品目定価
              ,in_aug_to_amount  => gr_add_total(1).aug_to_amount  -- ８月 内訳合計
              ,in_aug_quant_t    => gr_add_total(1).aug_quant_t    -- ８月 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
              ,in_aug_s_cost     => gr_add_total(1).aug_s_cost     -- ８月 標準原価(計算用)
              ,in_aug_calc       => gr_add_total(1).aug_calc       -- ８月 品目定価*数量(計算用)
              ,in_aug_minus_flg   => gr_add_total(1).aug_minus_flg   -- ８月 数量マイナス値存在フラグ(計算用)
              ,in_aug_ht_zero_flg => gr_add_total(1).aug_ht_zero_flg -- ８月 品目定価0値存在フラグ(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
              ,in_sep_quant      => gr_add_total(1).sep_quant      -- ９月 数量
              ,in_sep_amount     => gr_add_total(1).sep_amount     -- ９月 金額
              ,in_sep_price      => gr_add_total(1).sep_price      -- ９月 品目定価
              ,in_sep_to_amount  => gr_add_total(1).sep_to_amount  -- ９月 内訳合計
              ,in_sep_quant_t    => gr_add_total(1).sep_quant_t    -- ９月 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
              ,in_sep_s_cost     => gr_add_total(1).sep_s_cost     -- ９月 標準原価(計算用)
              ,in_sep_calc       => gr_add_total(1).sep_calc       -- ９月 品目定価*数量(計算用)
              ,in_sep_minus_flg   => gr_add_total(1).sep_minus_flg   -- ９月 数量マイナス値存在フラグ(計算用)
              ,in_sep_ht_zero_flg => gr_add_total(1).sep_ht_zero_flg -- ９月 品目定価0値存在フラグ(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
              ,in_oct_quant      => gr_add_total(1).oct_quant      -- １０月 数量
              ,in_oct_amount     => gr_add_total(1).oct_amount     -- １０月 金額
              ,in_oct_price      => gr_add_total(1).oct_price      -- １０月 品目定価
              ,in_oct_to_amount  => gr_add_total(1).oct_to_amount  -- １０月 内訳合計
              ,in_oct_quant_t    => gr_add_total(1).oct_quant_t    -- １０月 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
              ,in_oct_s_cost     => gr_add_total(1).oct_s_cost     -- １０月 標準原価(計算用)
              ,in_oct_calc       => gr_add_total(1).oct_calc       -- １０月 品目定価*数量(計算用)
              ,in_oct_minus_flg   => gr_add_total(1).oct_minus_flg   -- １０月 数量マイナス値存在フラグ(計算用)
              ,in_oct_ht_zero_flg => gr_add_total(1).oct_ht_zero_flg -- １０月 品目定価0値存在フラグ(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
              ,in_nov_quant      => gr_add_total(1).nov_quant      -- １１月 数量
              ,in_nov_amount     => gr_add_total(1).nov_amount     -- １１月 金額
              ,in_nov_price      => gr_add_total(1).nov_price      -- １１月 品目定価
              ,in_nov_to_amount  => gr_add_total(1).nov_to_amount  -- １１月 内訳合計
              ,in_nov_quant_t    => gr_add_total(1).nov_quant_t    -- １１月 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
              ,in_nov_s_cost     => gr_add_total(1).nov_s_cost     -- １１月 標準原価(計算用)
              ,in_nov_calc       => gr_add_total(1).nov_calc       -- １１月 品目定価*数量(計算用)
              ,in_nov_minus_flg   => gr_add_total(1).nov_minus_flg   -- １１月 数量マイナス値存在フラグ(計算用)
              ,in_nov_ht_zero_flg => gr_add_total(1).nov_ht_zero_flg -- １１月 品目定価0値存在フラグ(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
              ,in_dec_quant      => gr_add_total(1).dec_quant      -- １２月 数量
              ,in_dec_amount     => gr_add_total(1).dec_amount     -- １２月 金額
              ,in_dec_price      => gr_add_total(1).dec_price      -- １２月 品目定価
              ,in_dec_to_amount  => gr_add_total(1).dec_to_amount  -- １２月 内訳合計
              ,in_dec_quant_t    => gr_add_total(1).dec_quant_t    -- １２月 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
              ,in_dec_s_cost     => gr_add_total(1).dec_s_cost     -- １２月 標準原価(計算用)
              ,in_dec_calc       => gr_add_total(1).dec_calc       -- １２月 品目定価*数量(計算用)
              ,in_dec_minus_flg   => gr_add_total(1).dec_minus_flg   -- １２月 数量マイナス値存在フラグ(計算用)
              ,in_dec_ht_zero_flg => gr_add_total(1).dec_ht_zero_flg -- １２月 品目定価0値存在フラグ(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
              ,in_jan_quant      => gr_add_total(1).jan_quant      -- １月 数量
              ,in_jan_amount     => gr_add_total(1).jan_amount     -- １月 金額
              ,in_jan_price      => gr_add_total(1).jan_price      -- １月 品目定価
              ,in_jan_to_amount  => gr_add_total(1).jan_to_amount  -- １月 内訳合計
              ,in_jan_quant_t    => gr_add_total(1).jan_quant_t    -- １月 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
              ,in_jan_s_cost     => gr_add_total(1).jan_s_cost     -- １月 標準原価(計算用)
              ,in_jan_calc       => gr_add_total(1).jan_calc       -- １月 品目定価*数量(計算用)
              ,in_jan_minus_flg   => gr_add_total(1).jan_minus_flg   -- １月 数量マイナス値存在フラグ(計算用)
              ,in_jan_ht_zero_flg => gr_add_total(1).jan_ht_zero_flg -- １月 品目定価0値存在フラグ(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
              ,in_feb_quant      => gr_add_total(1).feb_quant      -- ２月 数量
              ,in_feb_amount     => gr_add_total(1).feb_amount     -- ２月 金額
              ,in_feb_price      => gr_add_total(1).feb_price      -- ２月 品目定価
              ,in_feb_to_amount  => gr_add_total(1).feb_to_amount  -- ２月 内訳合計
              ,in_feb_quant_t    => gr_add_total(1).feb_quant_t    -- ２月 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
              ,in_feb_s_cost     => gr_add_total(1).feb_s_cost     -- ２月 標準原価(計算用)
              ,in_feb_calc       => gr_add_total(1).feb_calc       -- ２月 品目定価*数量(計算用)
              ,in_feb_minus_flg   => gr_add_total(1).feb_minus_flg   -- ２月 数量マイナス値存在フラグ(計算用)
              ,in_feb_ht_zero_flg => gr_add_total(1).feb_ht_zero_flg -- ２月 品目定価0値存在フラグ(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
              ,in_mar_quant      => gr_add_total(1).mar_quant      -- ３月 数量
              ,in_mar_amount     => gr_add_total(1).mar_amount     -- ３月 金額
              ,in_mar_price      => gr_add_total(1).mar_price      -- ３月 品目定価
              ,in_mar_to_amount  => gr_add_total(1).mar_to_amount  -- ３月 内訳合計
              ,in_mar_quant_t    => gr_add_total(1).mar_quant_t    -- ３月 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
              ,in_mar_s_cost     => gr_add_total(1).mar_s_cost     -- ３月 標準原価(計算用)
              ,in_mar_calc       => gr_add_total(1).mar_calc       -- ３月 品目定価*数量(計算用)
              ,in_mar_minus_flg   => gr_add_total(1).mar_minus_flg   -- ３月 数量マイナス値存在フラグ(計算用)
              ,in_mar_ht_zero_flg => gr_add_total(1).mar_ht_zero_flg -- ３月 品目定価0値存在フラグ(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
              ,in_apr_quant      => gr_add_total(1).apr_quant      -- ４月 数量
              ,in_apr_amount     => gr_add_total(1).apr_amount     -- ４月 金額
              ,in_apr_price      => gr_add_total(1).apr_price      -- ４月 品目定価
              ,in_apr_to_amount  => gr_add_total(1).apr_to_amount  -- ４月 内訳合計
              ,in_apr_quant_t    => gr_add_total(1).apr_quant_t    -- ４月 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
              ,in_apr_s_cost     => gr_add_total(1).apr_s_cost     -- ４月 標準原価(計算用)
              ,in_apr_calc       => gr_add_total(1).apr_calc       -- ４月 品目定価*数量(計算用)
              ,in_apr_minus_flg   => gr_add_total(1).apr_minus_flg   -- ４月 数量マイナス値存在フラグ(計算用)
              ,in_apr_ht_zero_flg => gr_add_total(1).apr_ht_zero_flg -- ４月 品目定価0値存在フラグ(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
              ,in_year_quant     => gr_add_total(1).year_quant     -- 年計 数量
              ,in_year_amount    => gr_add_total(1).year_amount    -- 年計 金額
              ,in_year_price     => gr_add_total(1).year_price     -- 年計 品目定価
              ,in_year_to_amount => gr_add_total(1).year_to_amount -- 年計 内訳合計
              ,in_year_quant_t   => gr_add_total(1).year_quant_t   -- 年計 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
              ,in_year_s_cost    => gr_add_total(1).year_s_cost    -- 年計 標準原価(計算用)
              ,in_year_calc      => gr_add_total(1).year_calc      -- 年計 品目定価*数量(計算用)
              ,in_year_minus_flg   => gr_add_total(1).year_minus_flg   -- 年計 数量マイナス値存在フラグ(計算用)
              ,in_year_ht_zero_flg => gr_add_total(1).year_ht_zero_flg -- 年計 品目定価0値存在フラグ(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
              ,ov_errbuf         => lv_errbuf   -- エラー・メッセージ           --# 固定 #
              ,ov_retcode        => lv_retcode  -- リターン・コード             --# 固定 #
              ,ov_errmsg         => lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
            );
            IF (lv_retcode = gv_status_error) THEN
              RAISE global_process_expt;
            END IF;
--
            -- 小群計ブレイクキー更新
            lv_sttl_break := SUBSTRB(gr_sale_plan_1(i).gun,1,3);
--
            -- 小群計集計項目初期化
            gr_add_total(1).may_quant       := gn_0; -- ５月 数量
            gr_add_total(1).may_amount      := gn_0; -- ５月 金額
            gr_add_total(1).may_price       := gn_0; -- ５月 品目定価
            gr_add_total(1).may_to_amount   := gn_0; -- ５月 内訳合計
            gr_add_total(1).may_quant_t     := gn_0; -- ５月 数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
            gr_add_total(1).may_s_cost      := gn_0; -- ５月 標準原価(計)
            gr_add_total(1).may_calc        := gn_0; -- ５月 品目定価*数量(計)
            gr_add_total(1).may_minus_flg   := 'N';  -- ５月 数量マイナス値存在フラグ(計算用)
            gr_add_total(1).may_ht_zero_flg := 'N';  -- ５月 品目定価0値存在フラグ(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
            gr_add_total(1).jun_quant       := gn_0; -- ６月 数量
            gr_add_total(1).jun_amount      := gn_0; -- ６月 金額
            gr_add_total(1).jun_price       := gn_0; -- ６月 品目定価
            gr_add_total(1).jun_to_amount   := gn_0; -- ６月 内訳合計
            gr_add_total(1).jun_quant_t     := gn_0; -- ６月 数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
            gr_add_total(1).jun_s_cost      := gn_0; -- ６月 標準原価(計)
            gr_add_total(1).jun_calc        := gn_0; -- ６月 品目定価*数量(計)
            gr_add_total(1).jun_minus_flg   := 'N';  -- ６月 数量マイナス値存在フラグ(計算用)
            gr_add_total(1).jun_ht_zero_flg := 'N';  -- ６月 品目定価0値存在フラグ(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
            gr_add_total(1).jul_quant       := gn_0; -- ７月 数量
            gr_add_total(1).jul_amount      := gn_0; -- ７月 金額
            gr_add_total(1).jul_price       := gn_0; -- ７月 品目定価
            gr_add_total(1).jul_to_amount   := gn_0; -- ７月 内訳合計
            gr_add_total(1).jul_quant_t     := gn_0; -- ７月 数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
            gr_add_total(1).jul_s_cost      := gn_0; -- ７月 標準原価(計)
            gr_add_total(1).jul_calc        := gn_0; -- ７月 品目定価*数量(計)
            gr_add_total(1).jul_minus_flg   := 'N';  -- ７月 数量マイナス値存在フラグ(計算用)
            gr_add_total(1).jul_ht_zero_flg := 'N';  -- ７月 品目定価0値存在フラグ(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
            gr_add_total(1).aug_quant       := gn_0; -- ８月 数量
            gr_add_total(1).aug_amount      := gn_0; -- ８月 金額
            gr_add_total(1).aug_price       := gn_0; -- ８月 品目定価
            gr_add_total(1).aug_to_amount   := gn_0; -- ８月 内訳合計
            gr_add_total(1).aug_quant_t     := gn_0; -- ８月 数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
            gr_add_total(1).aug_s_cost      := gn_0; -- ８月 標準原価(計)
            gr_add_total(1).aug_calc        := gn_0; -- ８月 品目定価*数量(計)
            gr_add_total(1).aug_minus_flg   := 'N';  -- ８月 数量マイナス値存在フラグ(計算用)
            gr_add_total(1).aug_ht_zero_flg := 'N';  -- ８月 品目定価0値存在フラグ(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
            gr_add_total(1).sep_quant       := gn_0; -- ９月 数量
            gr_add_total(1).sep_amount      := gn_0; -- ９月 金額
            gr_add_total(1).sep_price       := gn_0; -- ９月 品目定価
            gr_add_total(1).sep_to_amount   := gn_0; -- ９月 内訳合計
            gr_add_total(1).sep_quant_t     := gn_0; -- ９月 数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
            gr_add_total(1).sep_s_cost      := gn_0; -- ９月 標準原価(計)
            gr_add_total(1).sep_calc        := gn_0; -- ９月 品目定価*数量(計)
            gr_add_total(1).sep_minus_flg   := 'N';  -- ９月 数量マイナス値存在フラグ(計算用)
            gr_add_total(1).sep_ht_zero_flg := 'N';  -- ９月 品目定価0値存在フラグ(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
            gr_add_total(1).oct_quant       := gn_0; -- １０月 数量
            gr_add_total(1).oct_amount      := gn_0; -- １０月 金額
            gr_add_total(1).oct_price       := gn_0; -- １０月 品目定価
            gr_add_total(1).oct_to_amount   := gn_0; -- １０月 内訳合計
            gr_add_total(1).oct_quant_t     := gn_0; -- １０月 数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
            gr_add_total(1).oct_s_cost      := gn_0; -- １０月 標準原価(計)
            gr_add_total(1).oct_calc        := gn_0; -- １０月 品目定価*数量(計)
            gr_add_total(1).oct_minus_flg   := 'N';  -- １０月 数量マイナス値存在フラグ(計算用)
            gr_add_total(1).oct_ht_zero_flg := 'N';  -- １０月 品目定価0値存在フラグ(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
            gr_add_total(1).nov_quant       := gn_0; -- １１月 数量
            gr_add_total(1).nov_amount      := gn_0; -- １１月 金額
            gr_add_total(1).nov_price       := gn_0; -- １１月 品目定価
            gr_add_total(1).nov_to_amount   := gn_0; -- １１月 内訳合計
            gr_add_total(1).nov_quant_t     := gn_0; -- １１月 数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
            gr_add_total(1).nov_s_cost      := gn_0; -- １１月 標準原価(計)
            gr_add_total(1).nov_calc        := gn_0; -- １１月 品目定価*数量(計)
            gr_add_total(1).nov_minus_flg   := 'N';  -- １１月 数量マイナス値存在フラグ(計算用)
            gr_add_total(1).nov_ht_zero_flg := 'N';  -- １１月 品目定価0値存在フラグ(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
            gr_add_total(1).dec_quant       := gn_0; -- １２月 数量
            gr_add_total(1).dec_amount      := gn_0; -- １２月 金額
            gr_add_total(1).dec_price       := gn_0; -- １２月 品目定価
            gr_add_total(1).dec_to_amount   := gn_0; -- １２月 内訳合計
            gr_add_total(1).dec_quant_t     := gn_0; -- １２月 数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
            gr_add_total(1).dec_s_cost      := gn_0; -- １２月 標準原価(計)
            gr_add_total(1).dec_calc        := gn_0; -- １２月 品目定価*数量(計)
            gr_add_total(1).dec_minus_flg   := 'N';  -- １２月 数量マイナス値存在フラグ(計算用)
            gr_add_total(1).dec_ht_zero_flg := 'N';  -- １２月 品目定価0値存在フラグ(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
            gr_add_total(1).jan_quant       := gn_0; -- １月 数量
            gr_add_total(1).jan_amount      := gn_0; -- １月 金額
            gr_add_total(1).jan_price       := gn_0; -- １月 品目定価
            gr_add_total(1).jan_to_amount   := gn_0; -- １月 内訳合計
            gr_add_total(1).jan_quant_t     := gn_0; -- １月 数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
            gr_add_total(1).jan_s_cost      := gn_0; -- １月 標準原価(計)
            gr_add_total(1).jan_calc        := gn_0; -- １月 品目定価*数量(計)
            gr_add_total(1).jan_minus_flg   := 'N';  -- １月 数量マイナス値存在フラグ(計算用)
            gr_add_total(1).jan_ht_zero_flg := 'N';  -- １月 品目定価0値存在フラグ(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
            gr_add_total(1).feb_quant       := gn_0; -- ２月 数量
            gr_add_total(1).feb_amount      := gn_0; -- ２月 金額
            gr_add_total(1).feb_price       := gn_0; -- ２月 品目定価
            gr_add_total(1).feb_to_amount   := gn_0; -- ２月 内訳合計
            gr_add_total(1).feb_quant_t     := gn_0; -- ２月 数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
            gr_add_total(1).feb_s_cost      := gn_0; -- ２月 標準原価(計)
            gr_add_total(1).feb_calc        := gn_0; -- ２月 品目定価*数量(計)
            gr_add_total(1).feb_minus_flg   := 'N';  -- ２月 数量マイナス値存在フラグ(計算用)
            gr_add_total(1).feb_ht_zero_flg := 'N';  -- ２月 品目定価0値存在フラグ(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
            gr_add_total(1).mar_quant       := gn_0; -- ３月 数量
            gr_add_total(1).mar_amount      := gn_0; -- ３月 金額
            gr_add_total(1).mar_price       := gn_0; -- ３月 品目定価
            gr_add_total(1).mar_to_amount   := gn_0; -- ３月 内訳合計
            gr_add_total(1).mar_quant_t     := gn_0; -- ３月 数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
            gr_add_total(1).mar_s_cost      := gn_0; -- ３月 標準原価(計)
            gr_add_total(1).mar_calc        := gn_0; -- ３月 品目定価*数量(計)
            gr_add_total(1).mar_minus_flg   := 'N';  -- ３月 数量マイナス値存在フラグ(計算用)
            gr_add_total(1).mar_ht_zero_flg := 'N';  -- ３月 品目定価0値存在フラグ(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
            gr_add_total(1).apr_quant       := gn_0; -- ４月 数量
            gr_add_total(1).apr_amount      := gn_0; -- ４月 金額
            gr_add_total(1).apr_price       := gn_0; -- ４月 品目定価
            gr_add_total(1).apr_to_amount   := gn_0; -- ４月 内訳合計
            gr_add_total(1).apr_quant_t     := gn_0; -- ４月 数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
            gr_add_total(1).apr_s_cost      := gn_0; -- ４月 標準原価(計)
            gr_add_total(1).apr_calc        := gn_0; -- ４月 品目定価*数量(計)
            gr_add_total(1).apr_minus_flg   := 'N';  -- ４月 数量マイナス値存在フラグ(計算用)
            gr_add_total(1).apr_ht_zero_flg := 'N';  -- ４月 品目定価0値存在フラグ(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
            gr_add_total(1).year_quant      := gn_0; -- 年計 数量
            gr_add_total(1).year_amount     := gn_0; -- 年計 金額
            gr_add_total(1).year_price      := gn_0; -- 年計 品目定価
            gr_add_total(1).year_to_amount  := gn_0; -- 年計 内訳合計
            gr_add_total(1).year_quant_t    := gn_0; -- 年計 数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
            gr_add_total(1).year_s_cost     := gn_0; -- 年計 標準原価(計)
            gr_add_total(1).year_calc       := gn_0; -- 年計 品目定価*数量(計)
            gr_add_total(1).year_minus_flg   := 'N'; -- 年計 数量マイナス値存在フラグ(計算用)
            gr_add_total(1).year_ht_zero_flg := 'N'; -- 年計 品目定価0値存在フラグ(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
          END IF;
--
          -- ====================================================
          --  (拠点ごと)大群計ブレイク
          -- ====================================================
          IF (SUBSTRB(gr_sale_plan_1(i).gun,1,1) <> lv_lttl_break) THEN
            --------------------------------------------------------
            -- 大群計データ出力 
            --------------------------------------------------------
            prc_create_xml_data_st_lt
            (
               iv_label_name     => gv_name_lt                     -- 大群計用タグ名
              ,iv_name           => gv_label_lt                    -- 大群計タイトル
              ,in_may_quant      => gr_add_total(2).may_quant      -- ５月 数量
              ,in_may_amount     => gr_add_total(2).may_amount     -- ５月 金額
              ,in_may_price      => gr_add_total(2).may_price      -- ５月 品目定価
              ,in_may_to_amount  => gr_add_total(2).may_to_amount  -- ５月 内訳合計
              ,in_may_quant_t    => gr_add_total(2).may_quant_t    -- ５月 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
              ,in_may_s_cost     => gr_add_total(2).may_s_cost     -- ５月 標準原価(計算用)
              ,in_may_calc       => gr_add_total(2).may_calc       -- ５月 品目定価*数量(計算用)
              ,in_may_minus_flg   => gr_add_total(2).may_minus_flg   -- ５月 数量マイナス値存在フラグ(計算用)
              ,in_may_ht_zero_flg => gr_add_total(2).may_ht_zero_flg -- ５月 品目定価*数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
              ,in_jun_quant      => gr_add_total(2).jun_quant      -- ６月 数量
              ,in_jun_amount     => gr_add_total(2).jun_amount     -- ６月 金額
              ,in_jun_price      => gr_add_total(2).jun_price      -- ６月 品目定価
              ,in_jun_to_amount  => gr_add_total(2).jun_to_amount  -- ６月 内訳合計
              ,in_jun_quant_t    => gr_add_total(2).jun_quant_t    -- ６月 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
              ,in_jun_s_cost     => gr_add_total(2).jun_s_cost     -- ６月 標準原価(計算用)
              ,in_jun_calc       => gr_add_total(2).jun_calc       -- ６月 品目定価*数量(計算用)
              ,in_jun_minus_flg   => gr_add_total(2).jun_minus_flg   -- ６月 数量マイナス値存在フラグ(計算用)
              ,in_jun_ht_zero_flg => gr_add_total(2).jun_ht_zero_flg -- ６月 品目定価*数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
              ,in_jul_quant      => gr_add_total(2).jul_quant      -- ７月 数量
              ,in_jul_amount     => gr_add_total(2).jul_amount     -- ７月 金額
              ,in_jul_price      => gr_add_total(2).jul_price      -- ７月 品目定価
              ,in_jul_to_amount  => gr_add_total(2).jul_to_amount  -- ７月 内訳合計
              ,in_jul_quant_t    => gr_add_total(2).jul_quant_t    -- ７月 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
              ,in_jul_s_cost     => gr_add_total(2).jul_s_cost     -- ７月 標準原価(計算用)
              ,in_jul_calc       => gr_add_total(2).jul_calc       -- ７月 品目定価*数量(計算用)
              ,in_jul_minus_flg   => gr_add_total(2).jul_minus_flg   -- ７月 数量マイナス値存在フラグ(計算用)
              ,in_jul_ht_zero_flg => gr_add_total(2).jul_ht_zero_flg -- ７月 品目定価*数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
              ,in_aug_quant      => gr_add_total(2).aug_quant      -- ８月 数量
              ,in_aug_amount     => gr_add_total(2).aug_amount     -- ８月 金額
              ,in_aug_price      => gr_add_total(2).aug_price      -- ８月 品目定価
              ,in_aug_to_amount  => gr_add_total(2).aug_to_amount  -- ８月 内訳合計
              ,in_aug_quant_t    => gr_add_total(2).aug_quant_t    -- ８月 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
              ,in_aug_s_cost     => gr_add_total(2).aug_s_cost     -- ８月 標準原価(計算用)
              ,in_aug_calc       => gr_add_total(2).aug_calc       -- ８月 品目定価*数量(計算用)
              ,in_aug_minus_flg   => gr_add_total(2).aug_minus_flg   -- ８月 数量マイナス値存在フラグ(計算用)
              ,in_aug_ht_zero_flg => gr_add_total(2).aug_ht_zero_flg -- ８月 品目定価*数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
              ,in_sep_quant      => gr_add_total(2).sep_quant      -- ９月 数量
              ,in_sep_amount     => gr_add_total(2).sep_amount     -- ９月 金額
              ,in_sep_price      => gr_add_total(2).sep_price      -- ９月 品目定価
              ,in_sep_to_amount  => gr_add_total(2).sep_to_amount  -- ９月 内訳合計
              ,in_sep_quant_t    => gr_add_total(2).sep_quant_t    -- ９月 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
              ,in_sep_s_cost     => gr_add_total(2).sep_s_cost     -- ９月 標準原価(計算用)
              ,in_sep_calc       => gr_add_total(2).sep_calc       -- ９月 品目定価*数量(計算用)
              ,in_sep_minus_flg   => gr_add_total(2).sep_minus_flg   -- ９月 数量マイナス値存在フラグ(計算用)
              ,in_sep_ht_zero_flg => gr_add_total(2).sep_ht_zero_flg -- ９月 品目定価*数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
              ,in_oct_quant      => gr_add_total(2).oct_quant      -- １０月 数量
              ,in_oct_amount     => gr_add_total(2).oct_amount     -- １０月 金額
              ,in_oct_price      => gr_add_total(2).oct_price      -- １０月 品目定価
              ,in_oct_to_amount  => gr_add_total(2).oct_to_amount  -- １０月 内訳合計
              ,in_oct_quant_t    => gr_add_total(2).oct_quant_t    -- １０月 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
              ,in_oct_s_cost     => gr_add_total(2).oct_s_cost     -- １０月 標準原価(計算用)
              ,in_oct_calc       => gr_add_total(2).oct_calc       -- １０月 品目定価*数量(計算用)
              ,in_oct_minus_flg   => gr_add_total(2).oct_minus_flg   -- １０月 数量マイナス値存在フラグ(計算用)
              ,in_oct_ht_zero_flg => gr_add_total(2).oct_ht_zero_flg -- １０月 品目定価*数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
              ,in_nov_quant      => gr_add_total(2).nov_quant      -- １１月 数量
              ,in_nov_amount     => gr_add_total(2).nov_amount     -- １１月 金額
              ,in_nov_price      => gr_add_total(2).nov_price      -- １１月 品目定価
              ,in_nov_to_amount  => gr_add_total(2).nov_to_amount  -- １１月 内訳合計
              ,in_nov_quant_t    => gr_add_total(2).nov_quant_t    -- １１月 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
              ,in_nov_s_cost     => gr_add_total(2).nov_s_cost     -- １１月 標準原価(計算用)
              ,in_nov_calc       => gr_add_total(2).nov_calc       -- １１月 品目定価*数量(計算用)
              ,in_nov_minus_flg   => gr_add_total(2).nov_minus_flg   -- １１月 数量マイナス値存在フラグ(計算用)
              ,in_nov_ht_zero_flg => gr_add_total(2).nov_ht_zero_flg -- １１月 品目定価*数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
              ,in_dec_quant      => gr_add_total(2).dec_quant      -- １２月 数量
              ,in_dec_amount     => gr_add_total(2).dec_amount     -- １２月 金額
              ,in_dec_price      => gr_add_total(2).dec_price      -- １２月 品目定価
              ,in_dec_to_amount  => gr_add_total(2).dec_to_amount  -- １２月 内訳合計
              ,in_dec_quant_t    => gr_add_total(2).dec_quant_t    -- １２月 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
              ,in_dec_s_cost     => gr_add_total(2).dec_s_cost     -- １２月 標準原価(計算用)
              ,in_dec_calc       => gr_add_total(2).dec_calc       -- １２月 品目定価*数量(計算用)
              ,in_dec_minus_flg   => gr_add_total(2).dec_minus_flg   -- １２月 数量マイナス値存在フラグ(計算用)
              ,in_dec_ht_zero_flg => gr_add_total(2).dec_ht_zero_flg -- １２月 品目定価*数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
              ,in_jan_quant      => gr_add_total(2).jan_quant      -- １月 数量
              ,in_jan_amount     => gr_add_total(2).jan_amount     -- １月 金額
              ,in_jan_price      => gr_add_total(2).jan_price      -- １月 品目定価
              ,in_jan_to_amount  => gr_add_total(2).jan_to_amount  -- １月 内訳合計
              ,in_jan_quant_t    => gr_add_total(2).jan_quant_t    -- １月 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
              ,in_jan_s_cost     => gr_add_total(2).jan_s_cost     -- １月 標準原価(計算用)
              ,in_jan_calc       => gr_add_total(2).jan_calc       -- １月 品目定価*数量(計算用)
              ,in_jan_minus_flg   => gr_add_total(2).jan_minus_flg   -- １月 数量マイナス値存在フラグ(計算用)
              ,in_jan_ht_zero_flg => gr_add_total(2).jan_ht_zero_flg -- １月 品目定価*数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
              ,in_feb_quant      => gr_add_total(2).feb_quant      -- ２月 数量
              ,in_feb_amount     => gr_add_total(2).feb_amount     -- ２月 金額
              ,in_feb_price      => gr_add_total(2).feb_price      -- ２月 品目定価
              ,in_feb_to_amount  => gr_add_total(2).feb_to_amount  -- ２月 内訳合計
              ,in_feb_quant_t    => gr_add_total(2).feb_quant_t    -- ２月 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
              ,in_feb_s_cost     => gr_add_total(2).feb_s_cost     -- ２月 標準原価(計算用)
              ,in_feb_calc       => gr_add_total(2).feb_calc       -- ２月 品目定価*数量(計算用)
              ,in_feb_minus_flg   => gr_add_total(2).feb_minus_flg   -- ２月 数量マイナス値存在フラグ(計算用)
              ,in_feb_ht_zero_flg => gr_add_total(2).feb_ht_zero_flg -- ２月 品目定価*数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
              ,in_mar_quant      => gr_add_total(2).mar_quant      -- ３月 数量
              ,in_mar_amount     => gr_add_total(2).mar_amount     -- ３月 金額
              ,in_mar_price      => gr_add_total(2).mar_price      -- ３月 品目定価
              ,in_mar_to_amount  => gr_add_total(2).mar_to_amount  -- ３月 内訳合計
              ,in_mar_quant_t    => gr_add_total(2).mar_quant_t    -- ３月 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
              ,in_mar_s_cost     => gr_add_total(2).mar_s_cost     -- ３月 標準原価(計算用)
              ,in_mar_calc       => gr_add_total(2).mar_calc       -- ３月 品目定価*数量(計算用)
              ,in_mar_minus_flg   => gr_add_total(2).mar_minus_flg   -- ３月 数量マイナス値存在フラグ(計算用)
              ,in_mar_ht_zero_flg => gr_add_total(2).mar_ht_zero_flg -- ３月 品目定価*数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
              ,in_apr_quant      => gr_add_total(2).apr_quant      -- ４月 数量
              ,in_apr_amount     => gr_add_total(2).apr_amount     -- ４月 金額
              ,in_apr_price      => gr_add_total(2).apr_price      -- ４月 品目定価
              ,in_apr_to_amount  => gr_add_total(2).apr_to_amount  -- ４月 内訳合計
              ,in_apr_quant_t    => gr_add_total(2).apr_quant_t    -- ４月 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
              ,in_apr_s_cost     => gr_add_total(2).apr_s_cost     -- ４月 標準原価(計算用)
              ,in_apr_calc       => gr_add_total(2).apr_calc       -- ４月 品目定価*数量(計算用)
              ,in_apr_minus_flg   => gr_add_total(2).apr_minus_flg   -- ４月 数量マイナス値存在フラグ(計算用)
              ,in_apr_ht_zero_flg => gr_add_total(2).apr_ht_zero_flg -- ４月 品目定価*数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
              ,in_year_quant     => gr_add_total(2).year_quant     -- 年計 数量
              ,in_year_amount    => gr_add_total(2).year_amount    -- 年計 金額
              ,in_year_price     => gr_add_total(2).year_price     -- 年計 品目定価
              ,in_year_to_amount => gr_add_total(2).year_to_amount -- 年計 内訳合計
              ,in_year_quant_t   => gr_add_total(2).year_quant_t   -- 年計 数量(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
              ,in_year_s_cost    => gr_add_total(2).year_s_cost    -- 年計 標準原価(計算用)
              ,in_year_calc      => gr_add_total(2).year_calc      -- 年計 品目定価*数量(計算用)
              ,in_year_minus_flg   => gr_add_total(2).year_minus_flg   -- 年計 数量マイナス値存在フラグ(計算用)
              ,in_year_ht_zero_flg => gr_add_total(2).year_ht_zero_flg -- 年計 品目定価*数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
              ,ov_errbuf         => lv_errbuf   -- エラー・メッセージ           --# 固定 #
              ,ov_retcode        => lv_retcode  -- リターン・コード             --# 固定 #
              ,ov_errmsg         => lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
            );
            IF (lv_retcode = gv_status_error) THEN
              RAISE global_process_expt;
            END IF;
--
            -- 大群計ブレイクキー更新
            lv_lttl_break := SUBSTRB(gr_sale_plan_1(i).gun,1,1);
--
            -- 大群計集計用項目初期化
            gr_add_total(2).may_quant       := gn_0; -- ５月 数量
            gr_add_total(2).may_amount      := gn_0; -- ５月 金額
            gr_add_total(2).may_price       := gn_0; -- ５月 品目定価
            gr_add_total(2).may_to_amount   := gn_0; -- ５月 内訳合計
            gr_add_total(2).may_quant_t     := gn_0; -- ５月 数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
            gr_add_total(2).may_s_cost      := gn_0; -- ５月 標準原価(計)
            gr_add_total(2).may_calc        := gn_0; -- ５月 品目定価*数量(計)
            gr_add_total(2).may_minus_flg   := 'N';  -- ５月 数量マイナス値存在フラグ(計算用)
            gr_add_total(2).may_ht_zero_flg := 'N';  -- ５月 品目定価0値存在フラグ(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
            gr_add_total(2).jun_quant       := gn_0; -- ６月 数量
            gr_add_total(2).jun_amount      := gn_0; -- ６月 金額
            gr_add_total(2).jun_price       := gn_0; -- ６月 品目定価
            gr_add_total(2).jun_to_amount   := gn_0; -- ６月 内訳合計
            gr_add_total(2).jun_quant_t     := gn_0; -- ６月 数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
            gr_add_total(2).jun_s_cost      := gn_0; -- ６月 標準原価(計)
            gr_add_total(2).jun_calc        := gn_0; -- ６月 品目定価*数量(計)
            gr_add_total(2).jun_minus_flg   := 'N';  -- ６月 数量マイナス値存在フラグ(計算用)
            gr_add_total(2).jun_ht_zero_flg := 'N';  -- ６月 品目定価0値存在フラグ(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
            gr_add_total(2).jul_quant       := gn_0; -- ７月 数量
            gr_add_total(2).jul_amount      := gn_0; -- ７月 金額
            gr_add_total(2).jul_price       := gn_0; -- ７月 品目定価
            gr_add_total(2).jul_to_amount   := gn_0; -- ７月 内訳合計
            gr_add_total(2).jul_quant_t     := gn_0; -- ７月 数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
            gr_add_total(2).jul_s_cost      := gn_0; -- ７月 標準原価(計)
            gr_add_total(2).jul_calc        := gn_0; -- ７月 品目定価*数量(計)
            gr_add_total(2).jul_minus_flg   := 'N';  -- ７月 数量マイナス値存在フラグ(計算用)
            gr_add_total(2).jul_ht_zero_flg := 'N';  -- ７月 品目定価0値存在フラグ(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
            gr_add_total(2).aug_quant       := gn_0; -- ８月 数量
            gr_add_total(2).aug_amount      := gn_0; -- ８月 金額
            gr_add_total(2).aug_price       := gn_0; -- ８月 品目定価
            gr_add_total(2).aug_to_amount   := gn_0; -- ８月 内訳合計
            gr_add_total(2).aug_quant_t     := gn_0; -- ８月 数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
            gr_add_total(2).aug_s_cost      := gn_0; -- ８月 標準原価(計)
            gr_add_total(2).aug_calc        := gn_0; -- ８月 品目定価*数量(計)
            gr_add_total(2).aug_minus_flg   := 'N';  -- ８月 数量マイナス値存在フラグ(計算用)
            gr_add_total(2).aug_ht_zero_flg := 'N';  -- ８月 品目定価0値存在フラグ(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
            gr_add_total(2).sep_quant       := gn_0; -- ９月 数量
            gr_add_total(2).sep_amount      := gn_0; -- ９月 金額
            gr_add_total(2).sep_price       := gn_0; -- ９月 品目定価
            gr_add_total(2).sep_to_amount   := gn_0; -- ９月 内訳合計
            gr_add_total(2).sep_quant_t     := gn_0; -- ９月 数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
            gr_add_total(2).sep_s_cost      := gn_0; -- ９月 標準原価(計)
            gr_add_total(2).sep_calc        := gn_0; -- ９月 品目定価*数量(計)
            gr_add_total(2).sep_minus_flg   := 'N';  -- ９月 数量マイナス値存在フラグ(計算用)
            gr_add_total(2).sep_ht_zero_flg := 'N';  -- ９月 品目定価0値存在フラグ(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
            gr_add_total(2).oct_quant       := gn_0; -- １０月 数量
            gr_add_total(2).oct_amount      := gn_0; -- １０月 金額
            gr_add_total(2).oct_price       := gn_0; -- １０月 品目定価
            gr_add_total(2).oct_to_amount   := gn_0; -- １０月 内訳合計
            gr_add_total(2).oct_quant_t     := gn_0; -- １０月 数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
            gr_add_total(2).oct_s_cost      := gn_0; -- １０月 標準原価(計)
            gr_add_total(2).oct_calc        := gn_0; -- １０月 品目定価*数量(計)
            gr_add_total(2).oct_minus_flg   := 'N';  -- １０月 数量マイナス値存在フラグ(計算用)
            gr_add_total(2).oct_ht_zero_flg := 'N';  -- １０月 品目定価0値存在フラグ(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
            gr_add_total(2).nov_quant       := gn_0; -- １１月 数量
            gr_add_total(2).nov_amount      := gn_0; -- １１月 金額
            gr_add_total(2).nov_price       := gn_0; -- １１月 品目定価
            gr_add_total(2).nov_to_amount   := gn_0; -- １１月 内訳合計
            gr_add_total(2).nov_quant_t     := gn_0; -- １１月 数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
            gr_add_total(2).nov_s_cost      := gn_0; -- １１月 標準原価(計)
            gr_add_total(2).nov_calc        := gn_0; -- １１月 品目定価*数量(計)
            gr_add_total(2).nov_minus_flg   := 'N';  -- １１月 数量マイナス値存在フラグ(計算用)
            gr_add_total(2).nov_ht_zero_flg := 'N';  -- １１月 品目定価0値存在フラグ(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
            gr_add_total(2).dec_quant       := gn_0; -- １２月 数量
            gr_add_total(2).dec_amount      := gn_0; -- １２月 金額
            gr_add_total(2).dec_price       := gn_0; -- １２月 品目定価
            gr_add_total(2).dec_to_amount   := gn_0; -- １２月 内訳合計
            gr_add_total(2).dec_quant_t     := gn_0; -- １２月 数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
            gr_add_total(2).dec_s_cost      := gn_0; -- １２月 標準原価(計)
            gr_add_total(2).dec_calc        := gn_0; -- １２月 品目定価*数量(計)
            gr_add_total(2).dec_minus_flg   := 'N';  -- １２月 数量マイナス値存在フラグ(計算用)
            gr_add_total(2).dec_ht_zero_flg := 'N';  -- １２月 品目定価0値存在フラグ(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
            gr_add_total(2).jan_quant       := gn_0; -- １月 数量
            gr_add_total(2).jan_amount      := gn_0; -- １月 金額
            gr_add_total(2).jan_price       := gn_0; -- １月 品目定価
            gr_add_total(2).jan_to_amount   := gn_0; -- １月 内訳合計
            gr_add_total(2).jan_quant_t     := gn_0; -- １月 数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
            gr_add_total(2).jan_s_cost      := gn_0; -- １月 標準原価(計)
            gr_add_total(2).jan_calc        := gn_0; -- １月 品目定価*数量(計)
            gr_add_total(2).jan_minus_flg   := 'N';  -- １月 数量マイナス値存在フラグ(計算用)
            gr_add_total(2).jan_ht_zero_flg := 'N';  -- １月 品目定価0値存在フラグ(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
            gr_add_total(2).feb_quant       := gn_0; -- ２月 数量
            gr_add_total(2).feb_amount      := gn_0; -- ２月 金額
            gr_add_total(2).feb_price       := gn_0; -- ２月 品目定価
            gr_add_total(2).feb_to_amount   := gn_0; -- ２月 内訳合計
            gr_add_total(2).feb_quant_t     := gn_0; -- ２月 数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
            gr_add_total(2).feb_s_cost      := gn_0; -- ２月 標準原価(計)
            gr_add_total(2).feb_calc        := gn_0; -- ２月 品目定価*数量(計)
            gr_add_total(2).feb_minus_flg   := 'N';  -- ２月 数量マイナス値存在フラグ(計算用)
            gr_add_total(2).feb_ht_zero_flg := 'N';  -- ２月 品目定価0値存在フラグ(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
            gr_add_total(2).mar_quant       := gn_0; -- ３月 数量
            gr_add_total(2).mar_amount      := gn_0; -- ３月 金額
            gr_add_total(2).mar_price       := gn_0; -- ３月 品目定価
            gr_add_total(2).mar_to_amount   := gn_0; -- ３月 内訳合計
            gr_add_total(2).mar_quant_t     := gn_0; -- ３月 数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
            gr_add_total(2).mar_s_cost      := gn_0; -- ３月 標準原価(計)
            gr_add_total(2).mar_calc        := gn_0; -- ３月 品目定価*数量(計)
            gr_add_total(2).mar_minus_flg   := 'N';  -- ３月 数量マイナス値存在フラグ(計算用)
            gr_add_total(2).mar_ht_zero_flg := 'N';  -- ３月 品目定価0値存在フラグ(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
            gr_add_total(2).apr_quant       := gn_0; -- ４月 数量
            gr_add_total(2).apr_amount      := gn_0; -- ４月 金額
            gr_add_total(2).apr_price       := gn_0; -- ４月 品目定価
            gr_add_total(2).apr_to_amount   := gn_0; -- ４月 内訳合計
            gr_add_total(2).apr_quant_t     := gn_0; -- ４月 数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
            gr_add_total(2).apr_s_cost      := gn_0; -- ４月 標準原価(計)
            gr_add_total(2).apr_calc        := gn_0; -- ４月 品目定価*数量(計)
            gr_add_total(2).apr_minus_flg   := 'N';  -- ４月 数量マイナス値存在フラグ(計算用)
            gr_add_total(2).apr_ht_zero_flg := 'N';  -- ４月 品目定価0値存在フラグ(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
            gr_add_total(2).year_quant      := gn_0; -- 年計 数量
            gr_add_total(2).year_amount     := gn_0; -- 年計 金額
            gr_add_total(2).year_price      := gn_0; -- 年計 品目定価
            gr_add_total(2).year_to_amount  := gn_0; -- 年計 内訳合計
            gr_add_total(2).year_quant_t    := gn_0; -- 年計 数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
            gr_add_total(2).year_s_cost     := gn_0; -- 年計 標準原価(計)
            gr_add_total(2).year_calc       := gn_0; -- 年計 品目定価*数量(計)
            gr_add_total(2).year_minus_flg   := 'N'; -- 年計 数量マイナス値存在フラグ(計算用)
            gr_add_total(2).year_ht_zero_flg := 'N'; -- 年計 品目定価0値存在フラグ(計算用)
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
          END IF;
--
          -- -----------------------------------------------------
          --  (拠点ごと)群コード終了Ｇタグ出力
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_gun';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
          -- -----------------------------------------------------
          --  (拠点ごと)群コード終了LＧタグ出力
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_gun_info';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
          -- -----------------------------------------------------
          --  (拠点ごと)群コード開始LＧタグ出力
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_gun_info';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
          -- -----------------------------------------------------
          --  (拠点ごと)群コード開始Ｇタグ出力
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'g_gun';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
          -- -----------------------------------------------------
          --  (拠点ごと)品目開始ＬＧタグ出力
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_dtl_info';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
          --  ブレイクキー更新
          lv_gun_break  := gr_sale_plan_1(i).gun;           -- 群コード
          lv_dtl_break  := lv_break_init;                   -- 品目コード
--
          -- 年計初期化
          ln_year_quant_sum  := gn_0;           -- 数量
          ln_year_amount_sum := gn_0;           -- 金額
          ln_year_to_am_sum  := gn_0;           -- 内訳合計
          ln_year_price_sum  := gn_0;           -- 品目定価
--
          -- XML出力フラグ初期化
          <<xml_out_loop>>
          FOR n IN 1..12 LOOP
            gr_xml_out(n).out_fg   := lv_no;
          END LOOP xml_out_loop;
--
        END IF;
--
        -- ====================================================
        --  (拠点ごと)品目コードブレイク
        -- ====================================================
        -- 最初のレコードの時と、品目が切り替わったとき表示
        IF ((lv_dtl_break = lv_break_init)
          OR (lv_dtl_break <> gr_sale_plan_1(i).item_no)) THEN
          -- 最初のレコードでは、終了タグは表示しない。
          IF (lv_dtl_break <> lv_break_init) THEN
            -------------------------------------------------------
            -- 各月抽出データが存在しない場合、0表示にてXML出力  --
            -------------------------------------------------------
            <<xml_out_0_loop>>
            FOR m IN 1..12 LOOP
              IF (gr_xml_out(m).out_fg = lv_no) THEN
                prc_create_xml_data_dtl_n
                  (
                    iv_label_name     => gr_xml_out(m).tag_name                      -- 出力タグ名
                   ,ov_errbuf         => lv_errbuf   -- エラー・メッセージ           --# 固定 #
                   ,ov_retcode        => lv_retcode  -- リターン・コード             --# 固定 #
                   ,ov_errmsg         => lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
                  );
                IF (lv_retcode = gv_status_error) THEN
                  RAISE global_process_expt;
                END IF;
              END IF;
            END LOOP xml_out_0_loop;
--
            -- -----------------------------------------------------
            -- (拠点ごと)年計 数量データ
            -- -----------------------------------------------------
            gl_xml_idx := gt_xml_data_table.COUNT + 1;
            gt_xml_data_table(gl_xml_idx).tag_name  := 'year_quant';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
            gt_xml_data_table(gl_xml_idx).tag_value := ln_year_quant_sum;
--
            -- -----------------------------------------------------
            -- (拠点ごと)年計 金額データ
            -- -----------------------------------------------------
            gl_xml_idx := gt_xml_data_table.COUNT + 1;
            gt_xml_data_table(gl_xml_idx).tag_name  := 'year_amount';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
            gt_xml_data_table(gl_xml_idx).tag_value := ROUND(ln_year_amount_sum / 1000,0);
--
            -- -----------------------------------------------------
            -- (拠点ごと)年計 粗利率データ
            -- -----------------------------------------------------
            gl_xml_idx := gt_xml_data_table.COUNT + 1;
            gt_xml_data_table(gl_xml_idx).tag_name  := 'year_arari_par';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
--
            ------------------------------------------------
            -- (拠点ごと)粗利計算 (金額－内訳合計＊数量)  --
            ------------------------------------------------
            ln_arari := ln_year_amount_sum - ln_year_to_am_sum * ln_year_quant_sum;
            -- ０除算回避判定
            IF (ln_year_amount_sum <> gn_0) THEN
              -- 値が[0]出なければ計算
              gt_xml_data_table(gl_xml_idx).tag_value := 
                      ROUND((ln_arari / ln_year_amount_sum * 100),2);
            ELSE
              -- 値が[0]の場合は、一律[0]設定
              gt_xml_data_table(gl_xml_idx).tag_value := gn_0;
            END IF;
--
            -- -----------------------------------------------------
            -- (拠点ごと)年計 掛率データ
            -- -----------------------------------------------------
            gl_xml_idx := gt_xml_data_table.COUNT + 1;
            gt_xml_data_table(gl_xml_idx).tag_name  := 'year_kake_par';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
--
            --------------------------------------
            -- ０除算判定項目へ判定値を挿入     --
            --------------------------------------
            ln_chk_0 := ln_year_price_sum * ln_year_quant_sum;
            -- ０除算回避判定
            IF (ln_chk_0 <> gn_0) THEN
              -- 値が[0]出なければ計算
              ln_kake_par := ROUND((ln_year_amount_sum * 100) / ln_chk_0,2);
            ELSE
             -- 値が[0]の場合は、一律[0]設定
             ln_kake_par := gn_0;
            END IF;
--
            -- 品目定価 = ０か、計算結果がマイナスの場合、固定値[70.00]を登録
            IF ((ln_year_price_sum = 0)
              OR (ln_kake_par < 0)) THEN
              ln_kake_par := gn_kotei_70; -- 固定値[70.00]
            END IF;
            gt_xml_data_table(gl_xml_idx).tag_value := ln_kake_par;
--
            -- 各集計項目へデータ挿入
            <<add_total_loop>>
            FOR r IN 1..5 LOOP                     -- 小群計/大群計/拠点計/商品区分計/総合計
              gr_add_total(r).year_quant     :=
                 gr_add_total(r).year_quant     + ln_year_quant_sum;        -- 数量
              gr_add_total(r).year_amount    :=
                 gr_add_total(r).year_amount    + ln_year_amount_sum;       -- 金額
              gr_add_total(r).year_price     :=
                 gr_add_total(r).year_price     + ln_year_price_sum;        -- 品目定価
              gr_add_total(r).year_to_amount :=
                 gr_add_total(r).year_to_amount + ln_year_to_am_sum;        -- 内訳合計
              gr_add_total(r).year_quant_t   :=
                 gr_add_total(r).year_quant_t   + ln_year_quant_sum;        -- 数量(計)
            END LOOP add_total_loop;
--
            -- -----------------------------------------------------
            --  (拠点ごと)品目終了Ｇタグ出力
            -- -----------------------------------------------------
            gl_xml_idx := gt_xml_data_table.COUNT + 1;
            gt_xml_data_table(gl_xml_idx).tag_name  := '/g_dtl';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
            -- 年計初期化
            ln_year_quant_sum  := gn_0;           -- 数量
            ln_year_amount_sum := gn_0;           -- 金額
            ln_year_to_am_sum  := gn_0;           -- 内訳合計
            ln_year_price_sum  := gn_0;           -- 品目定価
--
          END IF;
          -- -----------------------------------------------------
          --  (拠点ごと)品目開始Ｇタグ出力
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'g_dtl';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
          -- -----------------------------------------------------
          -- (拠点ごと)群コードデータ
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'gun_code';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          gt_xml_data_table(gl_xml_idx).tag_value := gr_sale_plan_1(i).gun;
--
          -- -----------------------------------------------------
          -- (拠点ごと)品目(コード)データ
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'item_code';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          gt_xml_data_table(gl_xml_idx).tag_value := gr_sale_plan_1(i).item_no;
--
          -- -----------------------------------------------------
          -- (拠点ごと)品目(名称)データ
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'item_name';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          gt_xml_data_table(gl_xml_idx).tag_value := gr_sale_plan_1(i).item_short_name;
        END IF;
--
        -- ====================================================
        --  (拠点ごと)明細データ出力
        -- ====================================================
        --------------------------------------
        -- (拠点ごと)抽出データが５月の場合 --
        --------------------------------------
        IF (gr_sale_plan_1(i).month = lv_may_name) THEN
          -- 抽出データ 有
          prc_create_xml_data_dtl
            (
              iv_label_name     => gv_name_may                               -- 出力タグ名
             ,in_quant          => TO_NUMBER(gr_sale_plan_1(i).quant)        -- 数量
             ,in_case_quant     => TO_NUMBER(gr_sale_plan_1(i).case_quant)   -- 入数
             ,in_amount         => TO_NUMBER(gr_sale_plan_1(i).amount)       -- 金額
             ,in_total_amount   => TO_NUMBER(gr_sale_plan_1(i).total_amount) -- 内訳合計
             ,iv_price_st       => gr_sale_plan_1(i).price_st                -- 定価適用開始日
             ,in_n_amount       => TO_NUMBER(gr_sale_plan_1(i).n_amount)     -- 新定価
             ,in_o_amount       => TO_NUMBER(gr_sale_plan_1(i).o_amount)     -- 旧定価
             ,on_quant          => ln_quant                                  -- 年計用 数量
             ,on_price          => ln_price                                  -- 年計用 品目定価
             ,ov_errbuf         => lv_errbuf   -- エラー・メッセージ           --# 固定 #
             ,ov_retcode        => lv_retcode  -- リターン・コード             --# 固定 #
             ,ov_errmsg         => lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
            );
          IF (lv_retcode = gv_status_error) THEN
            RAISE global_process_expt;
          END IF;
--
          -- 年計集計項目計算
          ln_year_quant_sum  := ln_year_quant_sum  + ln_quant;             -- 数量
          ln_year_amount_sum := ln_year_amount_sum + TO_NUMBER(gr_sale_plan_1(i).amount);
                                                                            -- 金額
-- 2009/04/16 v1.6 T.Yoshimoto Mod Start 本番#1410
/*
          ln_year_to_am_sum  := ln_year_to_am_sum  + TO_NUMBER(gr_sale_plan_1(i).total_amount);
                                                                           -- 内訳合計
          ln_year_price_sum  := ln_year_price_sum  + ln_price;             -- 品目定価
*/
          ln_year_to_am_sum  := TO_NUMBER(gr_sale_plan_1(i).total_amount);   -- 内訳合計
          ln_year_price_sum  := ln_price;                                  -- 品目定価
-- 2009/04/16 v1.6 T.Yoshimoto Mod End 本番#1410
--
          -- 各集計項目へデータ挿入
          <<add_total_loop_5>>
          FOR r IN 1..5 LOOP                     -- 小群計/大群計/拠点計/商品区分計/総合計
            gr_add_total(r).may_quant     :=
               gr_add_total(r).may_quant     + TO_NUMBER(gr_sale_plan_1(i).quant);        -- 数量
            gr_add_total(r).may_amount    :=
               gr_add_total(r).may_amount    + TO_NUMBER(gr_sale_plan_1(i).amount);       -- 金額
            gr_add_total(r).may_price     :=
               gr_add_total(r).may_price     + ln_price;                                  -- 品目定価
            gr_add_total(r).may_to_amount :=
               gr_add_total(r).may_to_amount + TO_NUMBER(gr_sale_plan_1(i).total_amount); -- 内訳合計
            gr_add_total(r).may_quant_t   :=
               gr_add_total(r).may_quant_t   + ln_quant;                                  -- 数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
            gr_add_total(r).may_s_cost    :=                                            -- 標準原価(計)
                gr_add_total(r).may_s_cost   + (TO_NUMBER(gr_sale_plan_1(i).total_amount) * TO_NUMBER(gr_sale_plan_1(i).quant));
            gr_add_total(r).may_calc      :=                                            -- 品目定価*数量(計)
                gr_add_total(r).may_calc     + (ln_price * TO_NUMBER(gr_sale_plan_1(i).quant));
--
            gr_add_total(r).year_s_cost    :=                                            -- 年間.標準原価(計)
                gr_add_total(r).year_s_cost   + (TO_NUMBER(gr_sale_plan_1(i).total_amount) * TO_NUMBER(gr_sale_plan_1(i).quant));
            gr_add_total(r).year_calc      :=                                             -- 年間.品目定価*数量(計)
                gr_add_total(r).year_calc     + (ln_price * TO_NUMBER(gr_sale_plan_1(i).quant));
--
            -- 数量がマイナスの場合(月間での存在チェック)
            IF ( TO_NUMBER(gr_sale_plan_1(i).quant) < 0 ) THEN
              gr_add_total(r).may_minus_flg := 'Y';
            END IF;
--
            -- 品目定価が0の場合(月間での存在チェック)
            IF ( ln_price = 0 ) THEN
              gr_add_total(r).may_ht_zero_flg := 'Y';
            END IF;
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410

          END LOOP add_total_loop_5;
--
          -- XML出力フラグ更新
          gr_xml_out(1).tag_name := gv_name_may;
          gr_xml_out(1).out_fg   := lv_yes;
        ELSE
          -- XML出力フラグ更新
          gr_xml_out(1).tag_name := gv_name_may;
          gr_xml_out(1).out_fg   := lv_no;
        END IF;
--
        --------------------------------------
        -- (拠点ごと)抽出データが６月の場合 --
        --------------------------------------
        IF (gr_sale_plan_1(i).month = lv_jun_name) THEN
          -- 抽出データ 有
          prc_create_xml_data_dtl
            (
              iv_label_name     => gv_name_jun                               -- 出力タグ名
             ,in_quant          => TO_NUMBER(gr_sale_plan_1(i).quant)        -- 数量
             ,in_case_quant     => TO_NUMBER(gr_sale_plan_1(i).case_quant)   -- 入数
             ,in_amount         => TO_NUMBER(gr_sale_plan_1(i).amount)       -- 金額
             ,in_total_amount   => TO_NUMBER(gr_sale_plan_1(i).total_amount) -- 内訳合計
             ,iv_price_st       => gr_sale_plan_1(i).price_st                -- 定価適用開始日
             ,in_n_amount       => TO_NUMBER(gr_sale_plan_1(i).n_amount)     -- 新定価
             ,in_o_amount       => TO_NUMBER(gr_sale_plan_1(i).o_amount)     -- 旧定価
             ,on_quant          => ln_quant                                  -- 年計用 数量
             ,on_price          => ln_price                                  -- 年計用 品目定価
             ,ov_errbuf         => lv_errbuf   -- エラー・メッセージ           --# 固定 #
             ,ov_retcode        => lv_retcode  -- リターン・コード             --# 固定 #
             ,ov_errmsg         => lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
            );
          IF (lv_retcode = gv_status_error) THEN
            RAISE global_process_expt;
          END IF;
--
          -- 年計集計項目計算
          ln_year_quant_sum  := ln_year_quant_sum  + ln_quant;             -- 数量
          ln_year_amount_sum := ln_year_amount_sum + TO_NUMBER(gr_sale_plan_1(i).amount);
                                                                           -- 金額
-- 2009/04/16 v1.6 T.Yoshimoto Mod Start 本番#1410
/*
          ln_year_to_am_sum  := ln_year_to_am_sum  + TO_NUMBER(gr_sale_plan_1(i).total_amount);
                                                                           -- 内訳合計
          ln_year_price_sum  := ln_year_price_sum  + ln_price;             -- 品目定価
*/
          ln_year_to_am_sum  := TO_NUMBER(gr_sale_plan_1(i).total_amount);   -- 内訳合計
          ln_year_price_sum  := ln_price;                                  -- 品目定価
-- 2009/04/16 v1.6 T.Yoshimoto Mod End 本番#1410
--
          -- 各集計項目へデータ挿入
          <<add_total_loop_6>>
          FOR r IN 1..5 LOOP                     -- 小群計/大群計/拠点計/商品区分計/総合計
            gr_add_total(r).jun_quant     :=
               gr_add_total(r).jun_quant     + TO_NUMBER(gr_sale_plan_1(i).quant);        -- 数量
            gr_add_total(r).jun_amount    :=
               gr_add_total(r).jun_amount    + TO_NUMBER(gr_sale_plan_1(i).amount);       -- 金額
            gr_add_total(r).jun_price     :=
               gr_add_total(r).jun_price     + ln_price;                                  -- 品目定価
            gr_add_total(r).jun_to_amount :=
               gr_add_total(r).jun_to_amount + TO_NUMBER(gr_sale_plan_1(i).total_amount); -- 内訳合計
            gr_add_total(r).jun_quant_t   :=
               gr_add_total(r).jun_quant_t   + ln_quant;                                  -- 数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
            gr_add_total(r).jun_s_cost    :=                                            -- 標準原価(計)
                gr_add_total(r).jun_s_cost   + (TO_NUMBER(gr_sale_plan_1(i).total_amount) * TO_NUMBER(gr_sale_plan_1(i).quant));
            gr_add_total(r).jun_calc      :=                                            -- 品目定価*数量(計)
                gr_add_total(r).jun_calc     + (ln_price * TO_NUMBER(gr_sale_plan_1(i).quant));
--
            gr_add_total(r).year_s_cost    :=                                            -- 年間.標準原価(計)
                gr_add_total(r).year_s_cost   + (TO_NUMBER(gr_sale_plan_1(i).total_amount) * TO_NUMBER(gr_sale_plan_1(i).quant));
            gr_add_total(r).year_calc      :=                                             -- 年間.品目定価*数量(計)
                gr_add_total(r).year_calc     + (ln_price * TO_NUMBER(gr_sale_plan_1(i).quant));
--
            -- 数量がマイナスの場合(月間での存在チェック)
            IF ( TO_NUMBER(gr_sale_plan_1(i).quant) < 0 ) THEN
              gr_add_total(r).jun_minus_flg := 'Y';
            END IF;
--
            -- 品目定価が0の場合(月間での存在チェック)
            IF ( ln_price = 0 ) THEN
              gr_add_total(r).jun_ht_zero_flg := 'Y';
            END IF;
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
          END LOOP add_total_loop_6;
--
          -- XML出力フラグ更新
          gr_xml_out(2).tag_name := gv_name_jun;
          gr_xml_out(2).out_fg   := lv_yes;
        ELSE
          -- XML出力フラグ更新
          gr_xml_out(2).tag_name := gv_name_jun;
          gr_xml_out(2).out_fg   := lv_no;
        END IF;
--
        --------------------------------------
        -- (拠点ごと)抽出データが７月の場合 --
        --------------------------------------
        IF (gr_sale_plan_1(i).month = lv_jul_name) THEN
          -- 抽出データ 有
          prc_create_xml_data_dtl
            (
              iv_label_name     => gv_name_jul                               -- 出力タグ名
             ,in_quant          => TO_NUMBER(gr_sale_plan_1(i).quant)        -- 数量
             ,in_case_quant     => TO_NUMBER(gr_sale_plan_1(i).case_quant)   -- 入数
             ,in_amount         => TO_NUMBER(gr_sale_plan_1(i).amount)       -- 金額
             ,in_total_amount   => TO_NUMBER(gr_sale_plan_1(i).total_amount) -- 内訳合計
             ,iv_price_st       => gr_sale_plan_1(i).price_st                -- 定価適用開始日
             ,in_n_amount       => TO_NUMBER(gr_sale_plan_1(i).n_amount)     -- 新定価
             ,in_o_amount       => TO_NUMBER(gr_sale_plan_1(i).o_amount)     -- 旧定価
             ,on_quant          => ln_quant                                  -- 年計用 数量
             ,on_price          => ln_price                                  -- 年計用 品目定価
             ,ov_errbuf         => lv_errbuf   -- エラー・メッセージ           --# 固定 #
             ,ov_retcode        => lv_retcode  -- リターン・コード             --# 固定 #
             ,ov_errmsg         => lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
            );
          IF (lv_retcode = gv_status_error) THEN
            RAISE global_process_expt;
          END IF;
--
          -- 年計集計項目計算
          ln_year_quant_sum  := ln_year_quant_sum  + ln_quant;             -- 数量
          ln_year_amount_sum := ln_year_amount_sum + TO_NUMBER(gr_sale_plan_1(i).amount);
                                                                           -- 金額
-- 2009/04/16 v1.6 T.Yoshimoto Mod Start 本番#1410
/*
          ln_year_to_am_sum  := ln_year_to_am_sum  + TO_NUMBER(gr_sale_plan_1(i).total_amount);
                                                                           -- 内訳合計
          ln_year_price_sum  := ln_year_price_sum  + ln_price;             -- 品目定価
*/
          ln_year_to_am_sum  := TO_NUMBER(gr_sale_plan_1(i).total_amount);   -- 内訳合計
          ln_year_price_sum  := ln_price;                                  -- 品目定価
-- 2009/04/16 v1.6 T.Yoshimoto Mod End 本番#1410
--
          -- 各集計項目へデータ挿入
          <<add_total_loop_7>>
          FOR r IN 1..5 LOOP                     -- 小群計/大群計/拠点計/商品区分計/総合計
            gr_add_total(r).jul_quant     :=
               gr_add_total(r).jul_quant     + TO_NUMBER(gr_sale_plan_1(i).quant);        -- 数量
            gr_add_total(r).jul_amount    :=
               gr_add_total(r).jul_amount    + TO_NUMBER(gr_sale_plan_1(i).amount);       -- 金額
            gr_add_total(r).jul_price     :=
               gr_add_total(r).jul_price     + ln_price;                                  -- 品目定価
            gr_add_total(r).jul_to_amount :=
               gr_add_total(r).jul_to_amount + TO_NUMBER(gr_sale_plan_1(i).total_amount); -- 内訳合計
            gr_add_total(r).jul_quant_t   :=
               gr_add_total(r).jul_quant_t   + ln_quant;                                  -- 数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
            gr_add_total(r).jul_s_cost    :=                                            -- 標準原価(計)
                gr_add_total(r).jul_s_cost   + (TO_NUMBER(gr_sale_plan_1(i).total_amount) * TO_NUMBER(gr_sale_plan_1(i).quant));
            gr_add_total(r).jul_calc      :=                                            -- 品目定価*数量(計)
                gr_add_total(r).jul_calc     + (ln_price * TO_NUMBER(gr_sale_plan_1(i).quant));
--
            gr_add_total(r).year_s_cost    :=                                            -- 年間.標準原価(計)
                gr_add_total(r).year_s_cost   + (TO_NUMBER(gr_sale_plan_1(i).total_amount) * TO_NUMBER(gr_sale_plan_1(i).quant));
            gr_add_total(r).year_calc      :=                                             -- 年間.品目定価*数量(計)
                gr_add_total(r).year_calc     + (ln_price * TO_NUMBER(gr_sale_plan_1(i).quant));
--
            -- 数量がマイナスの場合(月間での存在チェック)
            IF ( TO_NUMBER(gr_sale_plan_1(i).quant) < 0 ) THEN
              gr_add_total(r).jul_minus_flg := 'Y';
            END IF;
--
            -- 品目定価が0の場合(月間での存在チェック)
            IF ( ln_price = 0 ) THEN
              gr_add_total(r).jul_ht_zero_flg := 'Y';
            END IF;
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
          END LOOP add_total_loop_7;
--
          -- XML出力フラグ更新
          gr_xml_out(3).tag_name := gv_name_jul;
          gr_xml_out(3).out_fg   := lv_yes;
        ELSE
          -- XML出力フラグ更新
          gr_xml_out(3).tag_name := gv_name_jul;
          gr_xml_out(3).out_fg   := lv_no;
        END IF;
--
        --------------------------------------
        -- (拠点ごと)抽出データが８月の場合 --
        --------------------------------------
        IF (gr_sale_plan_1(i).month = lv_aug_name) THEN
          -- 抽出データ 有
          prc_create_xml_data_dtl
            (
              iv_label_name     => gv_name_aug                               -- 出力タグ名
             ,in_quant          => TO_NUMBER(gr_sale_plan_1(i).quant)        -- 数量
             ,in_case_quant     => TO_NUMBER(gr_sale_plan_1(i).case_quant)   -- 入数
             ,in_amount         => TO_NUMBER(gr_sale_plan_1(i).amount)       -- 金額
             ,in_total_amount   => TO_NUMBER(gr_sale_plan_1(i).total_amount) -- 内訳合計
             ,iv_price_st       => gr_sale_plan_1(i).price_st                -- 定価適用開始日
             ,in_n_amount       => TO_NUMBER(gr_sale_plan_1(i).n_amount)     -- 新定価
             ,in_o_amount       => TO_NUMBER(gr_sale_plan_1(i).o_amount)     -- 旧定価
             ,on_quant          => ln_quant                                  -- 年計用 数量
             ,on_price          => ln_price                                  -- 年計用 品目定価
             ,ov_errbuf         => lv_errbuf   -- エラー・メッセージ           --# 固定 #
             ,ov_retcode        => lv_retcode  -- リターン・コード             --# 固定 #
             ,ov_errmsg         => lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
            );
          IF (lv_retcode = gv_status_error) THEN
            RAISE global_process_expt;
          END IF;
--
          -- 年計集計項目計算
          ln_year_quant_sum  := ln_year_quant_sum  + ln_quant;             -- 数量
          ln_year_amount_sum := ln_year_amount_sum + TO_NUMBER(gr_sale_plan_1(i).amount);
                                                                           -- 金額
-- 2009/04/16 v1.6 T.Yoshimoto Mod Start 本番#1410
/*
          ln_year_to_am_sum  := ln_year_to_am_sum  + TO_NUMBER(gr_sale_plan_1(i).total_amount);
                                                                           -- 内訳合計
          ln_year_price_sum  := ln_year_price_sum  + ln_price;             -- 品目定価
*/
          ln_year_to_am_sum  := TO_NUMBER(gr_sale_plan_1(i).total_amount);   -- 内訳合計
          ln_year_price_sum  := ln_price;                                  -- 品目定価
-- 2009/04/16 v1.6 T.Yoshimoto Mod End 本番#1410
--
          -- 各集計項目へデータ挿入
          <<add_total_loop_8>>
          FOR r IN 1..5 LOOP                     -- 小群計/大群計/拠点計/商品区分計/総合計
            gr_add_total(r).aug_quant     :=
               gr_add_total(r).aug_quant     + TO_NUMBER(gr_sale_plan_1(i).quant);        -- 数量
            gr_add_total(r).aug_amount    :=
               gr_add_total(r).aug_amount    + TO_NUMBER(gr_sale_plan_1(i).amount);       -- 金額
            gr_add_total(r).aug_price     :=
               gr_add_total(r).aug_price     + ln_price;                                  -- 品目定価
            gr_add_total(r).aug_to_amount :=
               gr_add_total(r).aug_to_amount + TO_NUMBER(gr_sale_plan_1(i).total_amount); -- 内訳合計
            gr_add_total(r).aug_quant_t   :=
               gr_add_total(r).aug_quant_t   + ln_quant;                                  -- 数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
            gr_add_total(r).aug_s_cost    :=                                            -- 標準原価(計)
                gr_add_total(r).aug_s_cost   + (TO_NUMBER(gr_sale_plan_1(i).total_amount) * TO_NUMBER(gr_sale_plan_1(i).quant));
            gr_add_total(r).aug_calc      :=                                            -- 品目定価*数量(計)
                gr_add_total(r).aug_calc     + (ln_price * TO_NUMBER(gr_sale_plan_1(i).quant));
--
            gr_add_total(r).year_s_cost    :=                                            -- 年間.標準原価(計)
                gr_add_total(r).year_s_cost   + (TO_NUMBER(gr_sale_plan_1(i).total_amount) * TO_NUMBER(gr_sale_plan_1(i).quant));
            gr_add_total(r).year_calc      :=                                             -- 年間.品目定価*数量(計)
                gr_add_total(r).year_calc     + (ln_price * TO_NUMBER(gr_sale_plan_1(i).quant));
--
            -- 数量がマイナスの場合(月間での存在チェック)
            IF ( TO_NUMBER(gr_sale_plan_1(i).quant) < 0 ) THEN
              gr_add_total(r).aug_minus_flg := 'Y';
            END IF;
--
            -- 品目定価が0の場合(月間での存在チェック)
            IF ( ln_price = 0 ) THEN
              gr_add_total(r).aug_ht_zero_flg := 'Y';
            END IF;
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
          END LOOP add_total_loop_8;
--
          -- XML出力フラグ更新
          gr_xml_out(4).tag_name := gv_name_aug;
          gr_xml_out(4).out_fg   := lv_yes;
        ELSE
          -- XML出力フラグ更新
          gr_xml_out(4).tag_name := gv_name_aug;
          gr_xml_out(4).out_fg   := lv_no;
        END IF;
--
        --------------------------------------
        -- (拠点ごと)抽出データが９月の場合 --
        --------------------------------------
        IF (gr_sale_plan_1(i).month = lv_sep_name) THEN
          -- 抽出データ 有
          prc_create_xml_data_dtl
            (
              iv_label_name     => gv_name_sep                               -- 出力タグ名
             ,in_quant          => TO_NUMBER(gr_sale_plan_1(i).quant)        -- 数量
             ,in_case_quant     => TO_NUMBER(gr_sale_plan_1(i).case_quant)   -- 入数
             ,in_amount         => TO_NUMBER(gr_sale_plan_1(i).amount)       -- 金額
             ,in_total_amount   => TO_NUMBER(gr_sale_plan_1(i).total_amount) -- 内訳合計
             ,iv_price_st       => gr_sale_plan_1(i).price_st                -- 定価適用開始日
             ,in_n_amount       => TO_NUMBER(gr_sale_plan_1(i).n_amount)     -- 新定価
             ,in_o_amount       => TO_NUMBER(gr_sale_plan_1(i).o_amount)     -- 旧定価
             ,on_quant          => ln_quant                                  -- 年計用 数量
             ,on_price          => ln_price                                  -- 年計用 品目定価
             ,ov_errbuf         => lv_errbuf   -- エラー・メッセージ           --# 固定 #
             ,ov_retcode        => lv_retcode  -- リターン・コード             --# 固定 #
             ,ov_errmsg         => lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
            );
          IF (lv_retcode = gv_status_error) THEN
            RAISE global_process_expt;
          END IF;
--
          -- 年計集計項目計算
          ln_year_quant_sum  := ln_year_quant_sum  + ln_quant;             -- 数量
          ln_year_amount_sum := ln_year_amount_sum + TO_NUMBER(gr_sale_plan_1(i).amount);
                                                                           -- 金額
-- 2009/04/16 v1.6 T.Yoshimoto Mod Start 本番#1410
/*
          ln_year_to_am_sum  := ln_year_to_am_sum  + TO_NUMBER(gr_sale_plan_1(i).total_amount);
                                                                           -- 内訳合計
          ln_year_price_sum  := ln_year_price_sum  + ln_price;             -- 品目定価
*/
          ln_year_to_am_sum  := TO_NUMBER(gr_sale_plan_1(i).total_amount);   -- 内訳合計
          ln_year_price_sum  := ln_price;                                  -- 品目定価
-- 2009/04/16 v1.6 T.Yoshimoto Mod End 本番#1410
--
          -- 各集計項目へデータ挿入
          <<add_total_loop_9>>
          FOR r IN 1..5 LOOP                     -- 小群計/大群計/拠点計/商品区分計/総合計
            gr_add_total(r).sep_quant     :=
               gr_add_total(r).sep_quant     + TO_NUMBER(gr_sale_plan_1(i).quant);        -- 数量
            gr_add_total(r).sep_amount    :=
               gr_add_total(r).sep_amount    + TO_NUMBER(gr_sale_plan_1(i).amount);       -- 金額
            gr_add_total(r).sep_price     :=
               gr_add_total(r).sep_price     + ln_price;                                  -- 品目定価
            gr_add_total(r).sep_to_amount :=
               gr_add_total(r).sep_to_amount + TO_NUMBER(gr_sale_plan_1(i).total_amount); -- 内訳合計
            gr_add_total(r).sep_quant_t   :=
               gr_add_total(r).sep_quant_t   + ln_quant;                                  -- 数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
            gr_add_total(r).sep_s_cost    :=                                            -- 標準原価(計)
                gr_add_total(r).sep_s_cost   + (TO_NUMBER(gr_sale_plan_1(i).total_amount) * TO_NUMBER(gr_sale_plan_1(i).quant));
            gr_add_total(r).sep_calc      :=                                            -- 品目定価*数量(計)
                gr_add_total(r).sep_calc     + (ln_price * TO_NUMBER(gr_sale_plan_1(i).quant));
--
            gr_add_total(r).year_s_cost    :=                                            -- 年間.標準原価(計)
                gr_add_total(r).year_s_cost   + (TO_NUMBER(gr_sale_plan_1(i).total_amount) * TO_NUMBER(gr_sale_plan_1(i).quant));
            gr_add_total(r).year_calc      :=                                            -- 年間.品目定価*数量(計)
                gr_add_total(r).year_calc     + (ln_price * TO_NUMBER(gr_sale_plan_1(i).quant));
--
            -- 数量がマイナスの場合(月間での存在チェック)
            IF ( TO_NUMBER(gr_sale_plan_1(i).quant) < 0 ) THEN
              gr_add_total(r).sep_minus_flg := 'Y';
            END IF;
--
            -- 品目定価が0の場合(月間での存在チェック)
            IF ( ln_price = 0 ) THEN
              gr_add_total(r).sep_ht_zero_flg := 'Y';
            END IF;
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
          END LOOP add_total_loop_9;
--
          -- XML出力フラグ更新
          gr_xml_out(5).tag_name := gv_name_sep;
          gr_xml_out(5).out_fg   := lv_yes;
        ELSE
          -- XML出力フラグ更新
          gr_xml_out(5).tag_name := gv_name_sep;
          gr_xml_out(5).out_fg   := lv_no;
        END IF;
--
        ----------------------------------------
        -- (拠点ごと)抽出データが１０月の場合 --
        ----------------------------------------
        IF (gr_sale_plan_1(i).month = lv_oct_name) THEN
          -- 抽出データ 有
          prc_create_xml_data_dtl
            (
              iv_label_name     => gv_name_oct                               -- 出力タグ名
             ,in_quant          => TO_NUMBER(gr_sale_plan_1(i).quant)        -- 数量
             ,in_case_quant     => TO_NUMBER(gr_sale_plan_1(i).case_quant)   -- 入数
             ,in_amount         => TO_NUMBER(gr_sale_plan_1(i).amount)       -- 金額
             ,in_total_amount   => TO_NUMBER(gr_sale_plan_1(i).total_amount) -- 内訳合計
             ,iv_price_st       => gr_sale_plan_1(i).price_st                -- 定価適用開始日
             ,in_n_amount       => TO_NUMBER(gr_sale_plan_1(i).n_amount)     -- 新定価
             ,in_o_amount       => TO_NUMBER(gr_sale_plan_1(i).o_amount)     -- 旧定価
             ,on_quant          => ln_quant                                  -- 年計用 数量
             ,on_price          => ln_price                                  -- 年計用 品目定価
             ,ov_errbuf         => lv_errbuf   -- エラー・メッセージ           --# 固定 #
             ,ov_retcode        => lv_retcode  -- リターン・コード             --# 固定 #
             ,ov_errmsg         => lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
            );
          IF (lv_retcode = gv_status_error) THEN
            RAISE global_process_expt;
          END IF;
--
          -- 年計集計項目計算
          ln_year_quant_sum  := ln_year_quant_sum  + ln_quant;             -- 数量
          ln_year_amount_sum := ln_year_amount_sum + TO_NUMBER(gr_sale_plan_1(i).amount);
                                                                           -- 金額
-- 2009/04/16 v1.6 T.Yoshimoto Mod Start 本番#1410
/*
          ln_year_to_am_sum  := ln_year_to_am_sum  + TO_NUMBER(gr_sale_plan_1(i).total_amount);
                                                                           -- 内訳合計
          ln_year_price_sum  := ln_year_price_sum  + ln_price;             -- 品目定価
*/
          ln_year_to_am_sum  := TO_NUMBER(gr_sale_plan_1(i).total_amount);   -- 内訳合計
          ln_year_price_sum  := ln_price;                                  -- 品目定価
-- 2009/04/16 v1.6 T.Yoshimoto Mod End 本番#1410
--
          -- 各集計項目へデータ挿入
          <<add_total_loop_10>>
          FOR r IN 1..5 LOOP                     -- 小群計/大群計/拠点計/商品区分計/総合計
            gr_add_total(r).oct_quant     :=
               gr_add_total(r).oct_quant     + TO_NUMBER(gr_sale_plan_1(i).quant);        -- 数量
            gr_add_total(r).oct_amount    :=
               gr_add_total(r).oct_amount    + TO_NUMBER(gr_sale_plan_1(i).amount);       -- 金額
            gr_add_total(r).oct_price     :=
               gr_add_total(r).oct_price     + ln_price;                                  -- 品目定価
            gr_add_total(r).oct_to_amount :=
               gr_add_total(r).oct_to_amount + TO_NUMBER(gr_sale_plan_1(i).total_amount); -- 内訳合計
            gr_add_total(r).oct_quant_t   :=
               gr_add_total(r).oct_quant_t   + ln_quant;                                  -- 数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
            gr_add_total(r).oct_s_cost    :=                                            -- 標準原価(計)
                gr_add_total(r).oct_s_cost   + (TO_NUMBER(gr_sale_plan_1(i).total_amount) * TO_NUMBER(gr_sale_plan_1(i).quant));
            gr_add_total(r).oct_calc      :=                                            -- 品目定価*数量(計)
                gr_add_total(r).oct_calc     + (ln_price * TO_NUMBER(gr_sale_plan_1(i).quant));
--
            gr_add_total(r).year_s_cost    :=                                            -- 年間.標準原価(計)
                gr_add_total(r).year_s_cost   + (TO_NUMBER(gr_sale_plan_1(i).total_amount) * TO_NUMBER(gr_sale_plan_1(i).quant));
            gr_add_total(r).year_calc      :=                                            -- 年間.品目定価*数量(計)
                gr_add_total(r).year_calc     + (ln_price * TO_NUMBER(gr_sale_plan_1(i).quant));
--
            -- 数量がマイナスの場合(月間での存在チェック)
            IF ( TO_NUMBER(gr_sale_plan_1(i).quant) < 0 ) THEN
              gr_add_total(r).oct_minus_flg := 'Y';
            END IF;
--
            -- 品目定価が0の場合(月間での存在チェック)
            IF ( ln_price = 0 ) THEN
              gr_add_total(r).oct_ht_zero_flg := 'Y';
            END IF;
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
          END LOOP add_total_loop_10;
--
          -- XML出力フラグ更新
          gr_xml_out(6).tag_name := gv_name_oct;
          gr_xml_out(6).out_fg   := lv_yes;
        ELSE
          -- XML出力フラグ更新
          gr_xml_out(6).tag_name := gv_name_oct;
          gr_xml_out(6).out_fg   := lv_no;
        END IF;
--
        ----------------------------------------
        -- (拠点ごと)抽出データが１１月の場合 --
        ----------------------------------------
        IF (gr_sale_plan_1(i).month = lv_nov_name) THEN
          -- 抽出データ 有
          prc_create_xml_data_dtl
            (
              iv_label_name     => gv_name_nov                               -- 出力タグ名
             ,in_quant          => TO_NUMBER(gr_sale_plan_1(i).quant)        -- 数量
             ,in_case_quant     => TO_NUMBER(gr_sale_plan_1(i).case_quant)   -- 入数
             ,in_amount         => TO_NUMBER(gr_sale_plan_1(i).amount)       -- 金額
             ,in_total_amount   => TO_NUMBER(gr_sale_plan_1(i).total_amount) -- 内訳合計
             ,iv_price_st       => gr_sale_plan_1(i).price_st                -- 定価適用開始日
             ,in_n_amount       => TO_NUMBER(gr_sale_plan_1(i).n_amount)     -- 新定価
             ,in_o_amount       => TO_NUMBER(gr_sale_plan_1(i).o_amount)     -- 旧定価
             ,on_quant          => ln_quant                                  -- 年計用 数量
             ,on_price          => ln_price                                  -- 年計用 品目定価
             ,ov_errbuf         => lv_errbuf   -- エラー・メッセージ           --# 固定 #
             ,ov_retcode        => lv_retcode  -- リターン・コード             --# 固定 #
             ,ov_errmsg         => lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
            );
          IF (lv_retcode = gv_status_error) THEN
            RAISE global_process_expt;
          END IF;
--
          -- 年計集計項目計算
          ln_year_quant_sum  := ln_year_quant_sum  + ln_quant;             -- 数量
          ln_year_amount_sum := ln_year_amount_sum + TO_NUMBER(gr_sale_plan_1(i).amount);
                                                                           -- 金額
-- 2009/04/16 v1.6 T.Yoshimoto Mod Start 本番#1410
/*
          ln_year_to_am_sum  := ln_year_to_am_sum  + TO_NUMBER(gr_sale_plan_1(i).total_amount);
                                                                           -- 内訳合計
          ln_year_price_sum  := ln_year_price_sum  + ln_price;             -- 品目定価
*/
          ln_year_to_am_sum  := TO_NUMBER(gr_sale_plan_1(i).total_amount);   -- 内訳合計
          ln_year_price_sum  := ln_price;                                  -- 品目定価
-- 2009/04/16 v1.6 T.Yoshimoto Mod End 本番#1410
--
          -- 各集計項目へデータ挿入
          <<add_total_loop_11>>
          FOR r IN 1..5 LOOP                     -- 小群計/大群計/拠点計/商品区分計/総合計
            gr_add_total(r).nov_quant     :=
              gr_add_total(r).nov_quant     + TO_NUMBER(gr_sale_plan_1(i).quant);        -- 数量
            gr_add_total(r).nov_amount    :=
              gr_add_total(r).nov_amount    + TO_NUMBER(gr_sale_plan_1(i).amount);       -- 金額
            gr_add_total(r).nov_price     :=
              gr_add_total(r).nov_price     + ln_price;                                  -- 品目定価
            gr_add_total(r).nov_to_amount :=
              gr_add_total(r).nov_to_amount + TO_NUMBER(gr_sale_plan_1(i).total_amount); -- 内訳合計
            gr_add_total(r).nov_quant_t   :=
              gr_add_total(r).nov_quant_t   + ln_quant;                                  -- 数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
            gr_add_total(r).nov_s_cost    :=                                            -- 標準原価(計)
                gr_add_total(r).nov_s_cost   + (TO_NUMBER(gr_sale_plan_1(i).total_amount) * TO_NUMBER(gr_sale_plan_1(i).quant));
            gr_add_total(r).nov_calc      :=                                            -- 品目定価*数量(計)
                gr_add_total(r).nov_calc     + (ln_price * TO_NUMBER(gr_sale_plan_1(i).quant));
--
            gr_add_total(r).year_s_cost    :=                                            -- 年間.標準原価(計)
                gr_add_total(r).year_s_cost   + (TO_NUMBER(gr_sale_plan_1(i).total_amount) * TO_NUMBER(gr_sale_plan_1(i).quant));
            gr_add_total(r).year_calc      :=                                            -- 年間.品目定価*数量(計)
                gr_add_total(r).year_calc     + (ln_price * TO_NUMBER(gr_sale_plan_1(i).quant));
--
            -- 数量がマイナスの場合(月間での存在チェック)
            IF ( TO_NUMBER(gr_sale_plan_1(i).quant) < 0 ) THEN
              gr_add_total(r).nov_minus_flg := 'Y';
            END IF;
--
            -- 品目定価が0の場合(月間での存在チェック)
            IF ( ln_price = 0 ) THEN
              gr_add_total(r).nov_ht_zero_flg := 'Y';
            END IF;
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
          END LOOP add_total_loop_11;
--
          -- XML出力フラグ更新
          gr_xml_out(7).tag_name := gv_name_nov;
          gr_xml_out(7).out_fg   := lv_yes;
        ELSE
          -- XML出力フラグ更新
          gr_xml_out(7).tag_name := gv_name_nov;
          gr_xml_out(7).out_fg   := lv_no;
        END IF;
--
        ----------------------------------------
        -- (拠点ごと)抽出データが１２月の場合 --
        ----------------------------------------
        IF (gr_sale_plan_1(i).month = lv_dec_name) THEN
          -- 抽出データ 有
          prc_create_xml_data_dtl
            (
              iv_label_name     => gv_name_dec                               -- 出力タグ名
             ,in_quant          => TO_NUMBER(gr_sale_plan_1(i).quant)        -- 数量
             ,in_case_quant     => TO_NUMBER(gr_sale_plan_1(i).case_quant)   -- 入数
             ,in_amount         => TO_NUMBER(gr_sale_plan_1(i).amount)       -- 金額
             ,in_total_amount   => TO_NUMBER(gr_sale_plan_1(i).total_amount) -- 内訳合計
             ,iv_price_st       => gr_sale_plan_1(i).price_st                -- 定価適用開始日
             ,in_n_amount       => TO_NUMBER(gr_sale_plan_1(i).n_amount)     -- 新定価
             ,in_o_amount       => TO_NUMBER(gr_sale_plan_1(i).o_amount)     -- 旧定価
             ,on_quant          => ln_quant                                  -- 年計用 数量
             ,on_price          => ln_price                                  -- 年計用 品目定価
             ,ov_errbuf         => lv_errbuf   -- エラー・メッセージ           --# 固定 #
             ,ov_retcode        => lv_retcode  -- リターン・コード             --# 固定 #
             ,ov_errmsg         => lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
            );
          IF (lv_retcode = gv_status_error) THEN
            RAISE global_process_expt;
          END IF;
--
          -- 年計集計項目計算
          ln_year_quant_sum  := ln_year_quant_sum  + ln_quant;             -- 数量
          ln_year_amount_sum := ln_year_amount_sum + TO_NUMBER(gr_sale_plan_1(i).amount);
                                                                           -- 金額
-- 2009/04/16 v1.6 T.Yoshimoto Mod Start 本番#1410
/*
          ln_year_to_am_sum  := ln_year_to_am_sum  + TO_NUMBER(gr_sale_plan_1(i).total_amount);
                                                                           -- 内訳合計
          ln_year_price_sum  := ln_year_price_sum  + ln_price;             -- 品目定価
*/
          ln_year_to_am_sum  := TO_NUMBER(gr_sale_plan_1(i).total_amount);   -- 内訳合計
          ln_year_price_sum  := ln_price;                                  -- 品目定価
-- 2009/04/16 v1.6 T.Yoshimoto Mod End 本番#1410
--
          -- 各集計項目へデータ挿入
          <<add_total_loop_12>>
          FOR r IN 1..5 LOOP                     -- 小群計/大群計/拠点計/商品区分計/総合計
            gr_add_total(r).dec_quant     :=
              gr_add_total(r).dec_quant     + TO_NUMBER(gr_sale_plan_1(i).quant);        -- 数量
            gr_add_total(r).dec_amount    :=
              gr_add_total(r).dec_amount    + TO_NUMBER(gr_sale_plan_1(i).amount);       -- 金額
            gr_add_total(r).dec_price     :=
              gr_add_total(r).dec_price     + ln_price;                                  -- 品目定価
            gr_add_total(r).dec_to_amount :=
              gr_add_total(r).dec_to_amount + TO_NUMBER(gr_sale_plan_1(i).total_amount); -- 内訳合計
            gr_add_total(r).dec_quant_t   :=
              gr_add_total(r).dec_quant_t   + ln_quant;                                  -- 数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
            gr_add_total(r).dec_s_cost    :=                                            -- 標準原価(計)
                gr_add_total(r).dec_s_cost   + (TO_NUMBER(gr_sale_plan_1(i).total_amount) * TO_NUMBER(gr_sale_plan_1(i).quant));
            gr_add_total(r).dec_calc      :=                                            -- 品目定価*数量(計)
                gr_add_total(r).dec_calc     + (ln_price * TO_NUMBER(gr_sale_plan_1(i).quant));
--
            gr_add_total(r).year_s_cost    :=                                            -- 年間.標準原価(計)
                gr_add_total(r).year_s_cost   + (TO_NUMBER(gr_sale_plan_1(i).total_amount) * TO_NUMBER(gr_sale_plan_1(i).quant));
            gr_add_total(r).year_calc      :=                                            -- 年間.品目定価*数量(計)
                gr_add_total(r).year_calc     + (ln_price * TO_NUMBER(gr_sale_plan_1(i).quant));
--
            -- 数量がマイナスの場合(月間での存在チェック)
            IF ( TO_NUMBER(gr_sale_plan_1(i).quant) < 0 ) THEN
              gr_add_total(r).dec_minus_flg := 'Y';
            END IF;
--
            -- 品目定価が0の場合(月間での存在チェック)
            IF ( ln_price = 0 ) THEN
              gr_add_total(r).dec_ht_zero_flg := 'Y';
            END IF;
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
          END LOOP add_total_loop_12;
--
          -- XML出力フラグ更新
          gr_xml_out(8).tag_name := gv_name_dec;
          gr_xml_out(8).out_fg   := lv_yes;
        ELSE
          -- XML出力フラグ更新
          gr_xml_out(8).tag_name := gv_name_dec;
          gr_xml_out(8).out_fg   := lv_no;
        END IF;
--
        --------------------------------------
        -- (拠点ごと)抽出データが１月の場合 --
        --------------------------------------
        IF (gr_sale_plan_1(i).month = lv_jan_name) THEN
          -- 抽出データ 有
          prc_create_xml_data_dtl
            (
              iv_label_name     => gv_name_jan                               -- 出力タグ名
             ,in_quant          => TO_NUMBER(gr_sale_plan_1(i).quant)        -- 数量
             ,in_case_quant     => TO_NUMBER(gr_sale_plan_1(i).case_quant)   -- 入数
             ,in_amount         => TO_NUMBER(gr_sale_plan_1(i).amount)       -- 金額
             ,in_total_amount   => TO_NUMBER(gr_sale_plan_1(i).total_amount) -- 内訳合計
             ,iv_price_st       => gr_sale_plan_1(i).price_st                -- 定価適用開始日
             ,in_n_amount       => TO_NUMBER(gr_sale_plan_1(i).n_amount)     -- 新定価
             ,in_o_amount       => TO_NUMBER(gr_sale_plan_1(i).o_amount)     -- 旧定価
             ,on_quant          => ln_quant                                  -- 年計用 数量
             ,on_price          => ln_price                                  -- 年計用 品目定価
             ,ov_errbuf         => lv_errbuf   -- エラー・メッセージ           --# 固定 #
             ,ov_retcode        => lv_retcode  -- リターン・コード             --# 固定 #
             ,ov_errmsg         => lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
            );
          IF (lv_retcode = gv_status_error) THEN
            RAISE global_process_expt;
          END IF;
--
          -- 年計集計項目計算
          ln_year_quant_sum  := ln_year_quant_sum  + ln_quant;             -- 数量
          ln_year_amount_sum := ln_year_amount_sum + TO_NUMBER(gr_sale_plan_1(i).amount);
                                                                           -- 金額
-- 2009/04/16 v1.6 T.Yoshimoto Mod Start 本番#1410
/*
          ln_year_to_am_sum  := ln_year_to_am_sum  + TO_NUMBER(gr_sale_plan_1(i).total_amount);
                                                                           -- 内訳合計
          ln_year_price_sum  := ln_year_price_sum  + ln_price;             -- 品目定価
*/
          ln_year_to_am_sum  := TO_NUMBER(gr_sale_plan_1(i).total_amount);   -- 内訳合計
          ln_year_price_sum  := ln_price;                                  -- 品目定価
-- 2009/04/16 v1.6 T.Yoshimoto Mod End 本番#1410
--
          -- 各集計項目へデータ挿入
          <<add_total_loop_1>>
          FOR r IN 1..5 LOOP                     -- 小群計/大群計/拠点計/商品区分計/総合計
            gr_add_total(r).jan_quant     :=
              gr_add_total(r).jan_quant     + TO_NUMBER(gr_sale_plan_1(i).quant);        -- 数量
            gr_add_total(r).jan_amount    :=
              gr_add_total(r).jan_amount    + TO_NUMBER(gr_sale_plan_1(i).amount);       -- 金額
            gr_add_total(r).jan_price     :=
              gr_add_total(r).jan_price     + ln_price;                                  -- 品目定価
            gr_add_total(r).jan_to_amount :=
              gr_add_total(r).jan_to_amount + TO_NUMBER(gr_sale_plan_1(i).total_amount); -- 内訳合計
            gr_add_total(r).jan_quant_t   :=
              gr_add_total(r).jan_quant_t   + ln_quant;                                  -- 数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
            gr_add_total(r).jan_s_cost    :=                                            -- 標準原価(計)
                gr_add_total(r).jan_s_cost   + (TO_NUMBER(gr_sale_plan_1(i).total_amount) * TO_NUMBER(gr_sale_plan_1(i).quant));
            gr_add_total(r).jan_calc      :=                                            -- 品目定価*数量(計)
                gr_add_total(r).jan_calc     + (ln_price * TO_NUMBER(gr_sale_plan_1(i).quant));
--
            gr_add_total(r).year_s_cost    :=                                            -- 年間.標準原価(計)
                gr_add_total(r).year_s_cost   + (TO_NUMBER(gr_sale_plan_1(i).total_amount) * TO_NUMBER(gr_sale_plan_1(i).quant));
            gr_add_total(r).year_calc      :=                                            -- 年間.品目定価*数量(計)
                gr_add_total(r).year_calc     + (ln_price * TO_NUMBER(gr_sale_plan_1(i).quant));
--
            -- 数量がマイナスの場合(月間での存在チェック)
            IF ( TO_NUMBER(gr_sale_plan_1(i).quant) < 0 ) THEN
              gr_add_total(r).jan_minus_flg := 'Y';
            END IF;
--
            -- 品目定価が0の場合(月間での存在チェック)
            IF ( ln_price = 0 ) THEN
              gr_add_total(r).jan_ht_zero_flg := 'Y';
            END IF;
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
          END LOOP add_total_loop_1;
--
          -- XML出力フラグ更新
          gr_xml_out(9).tag_name := gv_name_jan;
          gr_xml_out(9).out_fg   := lv_yes;
        ELSE
          -- XML出力フラグ更新
          gr_xml_out(9).tag_name := gv_name_jan;
          gr_xml_out(9).out_fg   := lv_no;
        END IF;
--
        --------------------------------------
        -- (拠点ごと)抽出データが２月の場合 --
        --------------------------------------
        IF (gr_sale_plan_1(i).month = lv_feb_name) THEN
          -- 抽出データ 有
          prc_create_xml_data_dtl
            (
              iv_label_name     => gv_name_feb                               -- 出力タグ名
             ,in_quant          => TO_NUMBER(gr_sale_plan_1(i).quant)        -- 数量
             ,in_case_quant     => TO_NUMBER(gr_sale_plan_1(i).case_quant)   -- 入数
             ,in_amount         => TO_NUMBER(gr_sale_plan_1(i).amount)       -- 金額
             ,in_total_amount   => TO_NUMBER(gr_sale_plan_1(i).total_amount) -- 内訳合計
             ,iv_price_st       => gr_sale_plan_1(i).price_st                -- 定価適用開始日
             ,in_n_amount       => TO_NUMBER(gr_sale_plan_1(i).n_amount)     -- 新定価
             ,in_o_amount       => TO_NUMBER(gr_sale_plan_1(i).o_amount)     -- 旧定価
             ,on_quant          => ln_quant                                  -- 年計用 数量
             ,on_price          => ln_price                                  -- 年計用 品目定価
             ,ov_errbuf         => lv_errbuf   -- エラー・メッセージ           --# 固定 #
             ,ov_retcode        => lv_retcode  -- リターン・コード             --# 固定 #
             ,ov_errmsg         => lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
            );
          IF (lv_retcode = gv_status_error) THEN
            RAISE global_process_expt;
          END IF;
--
          -- 年計集計項目計算
          ln_year_quant_sum  := ln_year_quant_sum  + ln_quant;             -- 数量
          ln_year_amount_sum := ln_year_amount_sum + TO_NUMBER(gr_sale_plan_1(i).amount);
                                                                           -- 金額
-- 2009/04/16 v1.6 T.Yoshimoto Mod Start 本番#1410
/*
          ln_year_to_am_sum  := ln_year_to_am_sum  + TO_NUMBER(gr_sale_plan_1(i).total_amount);
                                                                           -- 内訳合計
          ln_year_price_sum  := ln_year_price_sum  + ln_price;             -- 品目定価
*/
          ln_year_to_am_sum  := TO_NUMBER(gr_sale_plan_1(i).total_amount);   -- 内訳合計
          ln_year_price_sum  := ln_price;                                  -- 品目定価
-- 2009/04/16 v1.6 T.Yoshimoto Mod End 本番#1410
--
          -- 各集計項目へデータ挿入
          <<add_total_loop_2>>
          FOR r IN 1..5 LOOP                     -- 小群計/大群計/拠点計/商品区分計/総合計
            gr_add_total(r).feb_quant     :=
              gr_add_total(r).feb_quant     + TO_NUMBER(gr_sale_plan_1(i).quant);        -- 数量
            gr_add_total(r).feb_amount    :=
              gr_add_total(r).feb_amount    + TO_NUMBER(gr_sale_plan_1(i).amount);       -- 金額
            gr_add_total(r).feb_price     :=
              gr_add_total(r).feb_price     + ln_price;                                  -- 品目定価
            gr_add_total(r).feb_to_amount :=
              gr_add_total(r).feb_to_amount + TO_NUMBER(gr_sale_plan_1(i).total_amount); -- 内訳合計
            gr_add_total(r).feb_quant_t   :=
              gr_add_total(r).feb_quant_t   + ln_quant;                                  -- 数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
            gr_add_total(r).feb_s_cost    :=                                            -- 標準原価(計)
                gr_add_total(r).feb_s_cost   + (TO_NUMBER(gr_sale_plan_1(i).total_amount) * TO_NUMBER(gr_sale_plan_1(i).quant));
            gr_add_total(r).feb_calc      :=                                            -- 品目定価*数量(計)
                gr_add_total(r).feb_calc     + (ln_price * TO_NUMBER(gr_sale_plan_1(i).quant));
--
            gr_add_total(r).year_s_cost    :=                                            -- 年間.標準原価(計)
                gr_add_total(r).year_s_cost   + (TO_NUMBER(gr_sale_plan_1(i).total_amount) * TO_NUMBER(gr_sale_plan_1(i).quant));
            gr_add_total(r).year_calc      :=                                            -- 年間.品目定価*数量(計)
                gr_add_total(r).year_calc     + (ln_price * TO_NUMBER(gr_sale_plan_1(i).quant));
--
            -- 数量がマイナスの場合(月間での存在チェック)
            IF ( TO_NUMBER(gr_sale_plan_1(i).quant) < 0 ) THEN
              gr_add_total(r).feb_minus_flg := 'Y';
            END IF;
--
            -- 品目定価が0の場合(月間での存在チェック)
            IF ( ln_price = 0 ) THEN
              gr_add_total(r).feb_ht_zero_flg := 'Y';
            END IF;
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
          END LOOP add_total_loop_2;
          -- XML出力フラグ更新
          gr_xml_out(10).tag_name := gv_name_feb;
          gr_xml_out(10).out_fg   := lv_yes;
        ELSE
          -- XML出力フラグ更新
          gr_xml_out(10).tag_name := gv_name_feb;
          gr_xml_out(10).out_fg   := lv_no;
        END IF;
--
        --------------------------------------
        -- (拠点ごと)抽出データが３月の場合 --
        --------------------------------------
        IF (gr_sale_plan_1(i).month = lv_mar_name) THEN
          -- 抽出データ 有
          prc_create_xml_data_dtl
           (
             iv_label_name     => gv_name_mar                               -- 出力タグ名
            ,in_quant          => TO_NUMBER(gr_sale_plan_1(i).quant)        -- 数量
            ,in_case_quant     => TO_NUMBER(gr_sale_plan_1(i).case_quant)   -- 入数
            ,in_amount         => TO_NUMBER(gr_sale_plan_1(i).amount)       -- 金額
            ,in_total_amount   => TO_NUMBER(gr_sale_plan_1(i).total_amount) -- 内訳合計
            ,iv_price_st       => gr_sale_plan_1(i).price_st                -- 定価適用開始日
            ,in_n_amount       => TO_NUMBER(gr_sale_plan_1(i).n_amount)     -- 新定価
            ,in_o_amount       => TO_NUMBER(gr_sale_plan_1(i).o_amount)     -- 旧定価
            ,on_quant          => ln_quant                                  -- 年計用 数量
            ,on_price          => ln_price                                  -- 年計用 品目定価
            ,ov_errbuf         => lv_errbuf   -- エラー・メッセージ           --# 固定 #
            ,ov_retcode        => lv_retcode  -- リターン・コード             --# 固定 #
            ,ov_errmsg         => lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
           );
          IF (lv_retcode = gv_status_error) THEN
            RAISE global_process_expt;
          END IF;
--
          -- 年計集計項目計算
          ln_year_quant_sum  := ln_year_quant_sum  + ln_quant;             -- 数量
          ln_year_amount_sum := ln_year_amount_sum + TO_NUMBER(gr_sale_plan_1(i).amount);
                                                                           -- 金額
-- 2009/04/16 v1.6 T.Yoshimoto Mod Start 本番#1410
/*
          ln_year_to_am_sum  := ln_year_to_am_sum  + TO_NUMBER(gr_sale_plan_1(i).total_amount);
                                                                           -- 内訳合計
          ln_year_price_sum  := ln_year_price_sum  + ln_price;             -- 品目定価
*/
          ln_year_to_am_sum  := TO_NUMBER(gr_sale_plan_1(i).total_amount);   -- 内訳合計
          ln_year_price_sum  := ln_price;                                  -- 品目定価
-- 2009/04/16 v1.6 T.Yoshimoto Mod End 本番#1410
--
          -- 各集計項目へデータ挿入
          <<add_total_loop_3>>
          FOR r IN 1..5 LOOP                     -- 小群計/大群計/拠点計/商品区分計/総合計
            gr_add_total(r).mar_quant     :=
              gr_add_total(r).mar_quant     + TO_NUMBER(gr_sale_plan_1(i).quant);        -- 数量
            gr_add_total(r).mar_amount    :=
              gr_add_total(r).mar_amount    + TO_NUMBER(gr_sale_plan_1(i).amount);       -- 金額
            gr_add_total(r).mar_price     :=
              gr_add_total(r).mar_price     + ln_price;                                  -- 品目定価
            gr_add_total(r).mar_to_amount :=
              gr_add_total(r).mar_to_amount + TO_NUMBER(gr_sale_plan_1(i).total_amount); -- 内訳合計
            gr_add_total(r).mar_quant_t   :=
              gr_add_total(r).mar_quant_t   + ln_quant;                                  -- 数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
            gr_add_total(r).mar_s_cost    :=                                            -- 標準原価(計)
                gr_add_total(r).mar_s_cost   + (TO_NUMBER(gr_sale_plan_1(i).total_amount) * TO_NUMBER(gr_sale_plan_1(i).quant));
            gr_add_total(r).mar_calc      :=                                            -- 品目定価*数量(計)
                gr_add_total(r).mar_calc     + (ln_price * TO_NUMBER(gr_sale_plan_1(i).quant));
--
            gr_add_total(r).year_s_cost    :=                                            -- 年間.標準原価(計)
                gr_add_total(r).year_s_cost   + (TO_NUMBER(gr_sale_plan_1(i).total_amount) * TO_NUMBER(gr_sale_plan_1(i).quant));
            gr_add_total(r).year_calc      :=                                            -- 年間.品目定価*数量(計)
                gr_add_total(r).year_calc     + (ln_price * TO_NUMBER(gr_sale_plan_1(i).quant));
--
            -- 数量がマイナスの場合(月間での存在チェック)
            IF ( TO_NUMBER(gr_sale_plan_1(i).quant) < 0 ) THEN
              gr_add_total(r).mar_minus_flg := 'Y';
            END IF;
--
            -- 品目定価が0の場合(月間での存在チェック)
            IF ( ln_price = 0 ) THEN
              gr_add_total(r).mar_ht_zero_flg := 'Y';
            END IF;
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
          END LOOP add_total_loop_3;
--
          -- XML出力フラグ更新
          gr_xml_out(11).tag_name := gv_name_mar;
          gr_xml_out(11).out_fg   := lv_yes;
        ELSE
          -- XML出力フラグ更新
          gr_xml_out(11).tag_name := gv_name_mar;
          gr_xml_out(11).out_fg   := lv_no;
        END IF;
--
        --------------------------------------
        -- (拠点ごと)抽出データが４月の場合 --
        --------------------------------------
        IF (gr_sale_plan_1(i).month = lv_apr_name) THEN
          -- 抽出データ 有
          prc_create_xml_data_dtl
            (
              iv_label_name     => gv_name_apr                               -- 出力タグ名
             ,in_quant          => TO_NUMBER(gr_sale_plan_1(i).quant)        -- 数量
             ,in_case_quant     => TO_NUMBER(gr_sale_plan_1(i).case_quant)   -- 入数
             ,in_amount         => TO_NUMBER(gr_sale_plan_1(i).amount)       -- 金額
             ,in_total_amount   => TO_NUMBER(gr_sale_plan_1(i).total_amount) -- 内訳合計
             ,iv_price_st       => gr_sale_plan_1(i).price_st                -- 定価適用開始日
             ,in_n_amount       => TO_NUMBER(gr_sale_plan_1(i).n_amount)     -- 新定価
             ,in_o_amount       => TO_NUMBER(gr_sale_plan_1(i).o_amount)     -- 旧定価
             ,on_quant          => ln_quant                                  -- 年計用 数量
             ,on_price          => ln_price                                  -- 年計用 品目定価
             ,ov_errbuf         => lv_errbuf   -- エラー・メッセージ           --# 固定 #
             ,ov_retcode        => lv_retcode  -- リターン・コード             --# 固定 #
             ,ov_errmsg         => lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
            );
          IF (lv_retcode = gv_status_error) THEN
            RAISE global_process_expt;
          END IF;
--
          -- 年計集計項目計算
          ln_year_quant_sum  := ln_year_quant_sum  + ln_quant;             -- 数量
          ln_year_amount_sum := ln_year_amount_sum + TO_NUMBER(gr_sale_plan_1(i).amount);
                                                                           -- 金額
-- 2009/04/16 v1.6 T.Yoshimoto Mod Start 本番#1410
/*
          ln_year_to_am_sum  := ln_year_to_am_sum  + TO_NUMBER(gr_sale_plan_1(i).total_amount);
                                                                           -- 内訳合計
          ln_year_price_sum  := ln_year_price_sum  + ln_price;             -- 品目定価
*/
          ln_year_to_am_sum  := TO_NUMBER(gr_sale_plan_1(i).total_amount);   -- 内訳合計
          ln_year_price_sum  := ln_price;                                  -- 品目定価
-- 2009/04/16 v1.6 T.Yoshimoto Mod End 本番#1410
--
          -- 各集計項目へデータ挿入
          <<add_total_loop_4>>
          FOR r IN 1..5 LOOP                     -- 小群計/大群計/拠点計/商品区分計/総合計
            gr_add_total(r).apr_quant     :=
              gr_add_total(r).apr_quant     + TO_NUMBER(gr_sale_plan_1(i).quant);        -- 数量
            gr_add_total(r).apr_amount    :=
              gr_add_total(r).apr_amount    + TO_NUMBER(gr_sale_plan_1(i).amount);       -- 金額
            gr_add_total(r).apr_price     :=
              gr_add_total(r).apr_price     + ln_price;                                  -- 品目定価
            gr_add_total(r).apr_to_amount :=
              gr_add_total(r).apr_to_amount + TO_NUMBER(gr_sale_plan_1(i).total_amount); -- 内訳合計
            gr_add_total(r).apr_quant_t   :=
              gr_add_total(r).apr_quant_t   + ln_quant;                                  -- 数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
            gr_add_total(r).apr_s_cost    :=                                            -- 標準原価(計)
                gr_add_total(r).apr_s_cost   + (TO_NUMBER(gr_sale_plan_1(i).total_amount) * TO_NUMBER(gr_sale_plan_1(i).quant));
            gr_add_total(r).apr_calc      :=                                            -- 品目定価*数量(計)
                gr_add_total(r).apr_calc     + (ln_price * TO_NUMBER(gr_sale_plan_1(i).quant));
--
            gr_add_total(r).year_s_cost    :=                                            -- 年間.標準原価(計)
                gr_add_total(r).year_s_cost   + (TO_NUMBER(gr_sale_plan_1(i).total_amount) * TO_NUMBER(gr_sale_plan_1(i).quant));
            gr_add_total(r).year_calc      :=                                            -- 年間.品目定価*数量(計)
                gr_add_total(r).year_calc     + (ln_price * TO_NUMBER(gr_sale_plan_1(i).quant));
--
            -- 数量がマイナスの場合(月間での存在チェック)
            IF ( TO_NUMBER(gr_sale_plan_1(i).quant) < 0 ) THEN
              gr_add_total(r).apr_minus_flg := 'Y';
            END IF;
--
            -- 品目定価が0の場合(月間での存在チェック)
            IF ( ln_price = 0 ) THEN
              gr_add_total(r).apr_ht_zero_flg := 'Y';
            END IF;
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
          END LOOP add_total_loop_4;
--
          -- XML出力フラグ更新
          gr_xml_out(12).tag_name := gv_name_apr;
          gr_xml_out(12).out_fg   := lv_yes;
        ELSE
          -- XML出力フラグ更新
          gr_xml_out(12).tag_name := gv_name_apr;
          gr_xml_out(12).out_fg   := lv_no;
        END IF;
--
        ------------------------------------------------
        -- (拠点ごと)ブレイクキー更新                 --
        ------------------------------------------------
        lv_dtl_break := gr_sale_plan_1(i).item_no;
--
      END LOOP main_data_loop_1;
--
      -- =====================================================
      -- (拠点ごと)終了処理
      -- =====================================================
      -----------------------------------------------------------------
      -- (拠点ごと)各月抽出データが存在しない場合、0表示にてXML出力  --
      -----------------------------------------------------------------
      <<xml_out_0_loop>>
      FOR m IN 1..12 LOOP
        IF (gr_xml_out(m).out_fg = lv_no) THEN
          prc_create_xml_data_dtl_n
            (
              iv_label_name     => gr_xml_out(m).tag_name                      -- 出力タグ名
             ,ov_errbuf         => lv_errbuf   -- エラー・メッセージ           --# 固定 #
             ,ov_retcode        => lv_retcode  -- リターン・コード             --# 固定 #
             ,ov_errmsg         => lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
            );
          IF (lv_retcode = gv_status_error) THEN
            RAISE global_process_expt;
          END IF;
        END IF;
      END LOOP xml_out_0_loop;
--
      -- -----------------------------------------------------
      -- (拠点ごと)年計 数量データ
      -- -----------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'year_quant';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
      gt_xml_data_table(gl_xml_idx).tag_value := ln_year_quant_sum;
--
      -- -----------------------------------------------------
      -- (拠点ごと)年計 金額データ
      -- -----------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'year_amount';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
      gt_xml_data_table(gl_xml_idx).tag_value := ROUND(ln_year_amount_sum / 1000,0);
--
      -- -----------------------------------------------------
      -- (拠点ごと)年計 粗利率データ
      -- -----------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'year_arari_par';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
--
      ------------------------------------------------
      -- (拠点ごと)粗利計算 (金額－内訳合計＊数量)  --
      ------------------------------------------------
      ln_arari := ln_year_amount_sum - ln_year_to_am_sum * ln_year_quant_sum;
      -- ０除算回避判定
      IF (ln_year_amount_sum <> gn_0) THEN
        -- 値が[0]出なければ計算
        gt_xml_data_table(gl_xml_idx).tag_value := 
                ROUND((ln_arari / ln_year_amount_sum * 100),2);
      ELSE
        -- 値が[0]の場合は、一律[0]設定
        gt_xml_data_table(gl_xml_idx).tag_value := gn_0;
      END IF;
--
      -- -----------------------------------------------------
      -- (拠点ごと)年計 掛率データ
      -- -----------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'year_kake_par';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
--
      --------------------------------------
      -- ０除算判定項目へ判定値を挿入     --
      --------------------------------------
      ln_chk_0 := ln_year_price_sum * ln_year_quant_sum;
      -- ０除算回避判定
      IF (ln_chk_0 <> gn_0) THEN
        -- 値が[0]出なければ計算
        ln_kake_par := ROUND((ln_year_amount_sum * 100) / ln_chk_0,2);
      ELSE
        -- 値が[0]の場合は、一律[0]設定
        ln_kake_par := gn_0;
      END IF;
--
      -- 品目定価 = ０か、計算結果がマイナスの場合、固定値[70.00]を登録
      IF ((ln_year_price_sum = 0)
        OR (ln_kake_par < 0)) THEN
        ln_kake_par := gn_kotei_70; -- 固定値[70.00]
      END IF;
      gt_xml_data_table(gl_xml_idx).tag_value := ln_kake_par;
--
      -- 各集計項目へデータ挿入
      <<add_total_loop>>
      FOR r IN 1..5 LOOP                     -- 小群計/大群計/拠点計/商品区分計/総合計
        gr_add_total(r).year_quant     :=
           gr_add_total(r).year_quant     + ln_year_quant_sum;        -- 数量
        gr_add_total(r).year_amount    :=
           gr_add_total(r).year_amount    + ln_year_amount_sum;       -- 金額
        gr_add_total(r).year_price     :=
           gr_add_total(r).year_price     + ln_year_price_sum;        -- 品目定価
        gr_add_total(r).year_to_amount :=
           gr_add_total(r).year_to_amount + ln_year_to_am_sum;        -- 内訳合計
        gr_add_total(r).year_quant_t   :=
           gr_add_total(r).year_quant_t   + ln_year_quant_sum;        -- 数量(計)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start 本番#1410
        -- 数量がマイナスの場合(年間での存在チェック)
        IF ( ln_year_quant_sum < 0 ) THEN
          gr_add_total(r).year_minus_flg := 'Y';
        END IF;
--
        -- 品目定価が0の場合(年間での存在チェック)
        IF ( ln_year_price_sum = 0 ) THEN
          gr_add_total(r).year_ht_zero_flg := 'Y';
        END IF;
-- 2009/04/16 v1.6 T.Yoshimoto Add End 本番#1410
      END LOOP add_total_loop;
--
      -- -----------------------------------------------------
      --  (拠点ごと)品目終了Ｇタグ出力
      -- -----------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1;
      gt_xml_data_table(gl_xml_idx).tag_name  := '/g_dtl';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
      -- -----------------------------------------------------
      --  (拠点ごと)品目終了ＬＧタグ出力
      -- -----------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1;
      gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_dtl_info';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
-- 2009/04/16 v1.6 T.Yoshimoto Mod Start 本番#1410
/*
      --------------------------------------------------------
      -- 小群計データタグ出力 
      --------------------------------------------------------
      prc_create_xml_data_st_lt
        (
          iv_label_name     => gv_name_st                     -- 小群計用タグ名
         ,iv_name           => gv_label_st                    -- 小群計タイトル
         ,in_may_quant      => gr_add_total(1).may_quant      -- ５月 数量
         ,in_may_amount     => gr_add_total(1).may_amount     -- ５月 金額
         ,in_may_price      => gr_add_total(1).may_price      -- ５月 品目定価
         ,in_may_to_amount  => gr_add_total(1).may_to_amount  -- ５月 内訳合計
         ,in_may_quant_t    => gr_add_total(1).may_quant_t    -- ５月 数量(計算用)
         ,in_jun_quant      => gr_add_total(1).jun_quant      -- ６月 数量
         ,in_jun_amount     => gr_add_total(1).jun_amount     -- ６月 金額
         ,in_jun_price      => gr_add_total(1).jun_price      -- ６月 品目定価
         ,in_jun_to_amount  => gr_add_total(1).jun_to_amount  -- ６月 内訳合計
         ,in_jun_quant_t    => gr_add_total(1).jun_quant_t    -- ６月 数量(計算用)
         ,in_jul_quant      => gr_add_total(1).jul_quant      -- ７月 数量
         ,in_jul_amount     => gr_add_total(1).jul_amount     -- ７月 金額
         ,in_jul_price      => gr_add_total(1).jul_price      -- ７月 品目定価
         ,in_jul_to_amount  => gr_add_total(1).jul_to_amount  -- ７月 内訳合計
         ,in_jul_quant_t    => gr_add_total(1).jul_quant_t    -- ７月 数量(計算用)
         ,in_aug_quant      => gr_add_total(1).aug_quant      -- ８月 数量
         ,in_aug_amount     => gr_add_total(1).aug_amount     -- ８月 金額
         ,in_aug_price      => gr_add_total(1).aug_price      -- ８月 品目定価
         ,in_aug_to_amount  => gr_add_total(1).aug_to_amount  -- ８月 内訳合計
         ,in_aug_quant_t    => gr_add_total(1).aug_quant_t    -- ８月 数量(計算用)
         ,in_sep_quant      => gr_add_total(1).sep_quant      -- ９月 数量
         ,in_sep_amount     => gr_add_total(1).sep_amount     -- ９月 金額
         ,in_sep_price      => gr_add_total(1).sep_price      -- ９月 品目定価
         ,in_sep_to_amount  => gr_add_total(1).sep_to_amount  -- ９月 内訳合計
         ,in_sep_quant_t    => gr_add_total(1).sep_quant_t    -- ９月 数量(計算用)
         ,in_oct_quant      => gr_add_total(1).oct_quant      -- １０月 数量
         ,in_oct_amount     => gr_add_total(1).oct_amount     -- １０月 金額
         ,in_oct_price      => gr_add_total(1).oct_price      -- １０月 品目定価
         ,in_oct_to_amount  => gr_add_total(1).oct_to_amount  -- １０月 内訳合計
         ,in_oct_quant_t    => gr_add_total(1).oct_quant_t    -- １０月 数量(計算用)
         ,in_nov_quant      => gr_add_total(1).nov_quant      -- １１月 数量
         ,in_nov_amount     => gr_add_total(1).nov_amount     -- １１月 金額
         ,in_nov_price      => gr_add_total(1).nov_price      -- １１月 品目定価
         ,in_nov_to_amount  => gr_add_total(1).nov_to_amount  -- １１月 内訳合計
         ,in_nov_quant_t    => gr_add_total(1).nov_quant_t    -- １１月 数量(計算用)
         ,in_dec_quant      => gr_add_total(1).dec_quant      -- １２月 数量
         ,in_dec_amount     => gr_add_total(1).dec_amount     -- １２月 金額
         ,in_dec_price      => gr_add_total(1).dec_price      -- １２月 品目定価
         ,in_dec_to_amount  => gr_add_total(1).dec_to_amount  -- １２月 内訳合計
         ,in_dec_quant_t    => gr_add_total(1).dec_quant_t    -- １２月 数量(計算用)
         ,in_jan_quant      => gr_add_total(1).jan_quant      -- １月 数量
         ,in_jan_amount     => gr_add_total(1).jan_amount     -- １月 金額
         ,in_jan_price      => gr_add_total(1).jan_price      -- １月 品目定価
         ,in_jan_to_amount  => gr_add_total(1).jan_to_amount  -- １月 内訳合計
         ,in_jan_quant_t    => gr_add_total(1).jan_quant_t    -- １月 数量(計算用)
         ,in_feb_quant      => gr_add_total(1).feb_quant      -- ２月 数量
         ,in_feb_amount     => gr_add_total(1).feb_amount     -- ２月 金額
         ,in_feb_price      => gr_add_total(1).feb_price      -- ２月 品目定価
         ,in_feb_to_amount  => gr_add_total(1).feb_to_amount  -- ２月 内訳合計
         ,in_feb_quant_t    => gr_add_total(1).feb_quant_t    -- ２月 数量(計算用)
         ,in_mar_quant      => gr_add_total(1).mar_quant      -- ３月 数量
         ,in_mar_amount     => gr_add_total(1).mar_amount     -- ３月 金額
         ,in_mar_price      => gr_add_total(1).mar_price      -- ３月 品目定価
         ,in_mar_to_amount  => gr_add_total(1).mar_to_amount  -- ３月 内訳合計
         ,in_mar_quant_t    => gr_add_total(1).mar_quant_t    -- ３月 数量(計算用)
         ,in_apr_quant      => gr_add_total(1).apr_quant      -- ４月 数量
         ,in_apr_amount     => gr_add_total(1).apr_amount     -- ４月 金額
         ,in_apr_price      => gr_add_total(1).apr_price      -- ４月 品目定価
         ,in_apr_to_amount  => gr_add_total(1).apr_to_amount  -- ４月 内訳合計
         ,in_apr_quant_t    => gr_add_total(1).apr_quant_t    -- ４月 数量(計算用)
         ,in_year_quant     => gr_add_total(1).year_quant     -- 年計 数量
         ,in_year_amount    => gr_add_total(1).year_amount    -- 年計 金額
         ,in_year_price     => gr_add_total(1).year_price     -- 年計 品目定価
         ,in_year_to_amount => gr_add_total(1).year_to_amount -- 年計 内訳合計
         ,in_year_quant_t   => gr_add_total(1).year_quant_t   -- 年計 数量(計算用)
         ,ov_errbuf         => lv_errbuf   -- エラー・メッセージ           --# 固定 #
         ,ov_retcode        => lv_retcode  -- リターン・コード             --# 固定 #
         ,ov_errmsg         => lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
        );
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
      --------------------------------------------------------
      -- 大群計データタグ出力 
      --------------------------------------------------------
      prc_create_xml_data_st_lt
        (
          iv_label_name     => gv_name_lt                     -- 大群計用タグ名
         ,iv_name           => gv_label_lt                    -- 大群計タイトル
         ,in_may_quant      => gr_add_total(2).may_quant      -- ５月 数量
         ,in_may_amount     => gr_add_total(2).may_amount     -- ５月 金額
         ,in_may_price      => gr_add_total(2).may_price      -- ５月 品目定価
         ,in_may_to_amount  => gr_add_total(2).may_to_amount  -- ５月 内訳合計
         ,in_may_quant_t    => gr_add_total(2).may_quant_t    -- ５月 数量(計算用)
         ,in_jun_quant      => gr_add_total(2).jun_quant      -- ６月 数量
         ,in_jun_amount     => gr_add_total(2).jun_amount     -- ６月 金額
         ,in_jun_price      => gr_add_total(2).jun_price      -- ６月 品目定価
         ,in_jun_to_amount  => gr_add_total(2).jun_to_amount  -- ６月 内訳合計
         ,in_jun_quant_t    => gr_add_total(2).jun_quant_t    -- ６月 数量(計算用)
         ,in_jul_quant      => gr_add_total(2).jul_quant      -- ７月 数量
         ,in_jul_amount     => gr_add_total(2).jul_amount     -- ７月 金額
         ,in_jul_price      => gr_add_total(2).jul_price      -- ７月 品目定価
         ,in_jul_to_amount  => gr_add_total(2).jul_to_amount  -- ７月 内訳合計
         ,in_jul_quant_t    => gr_add_total(2).jul_quant_t    -- ７月 数量(計算用)
         ,in_aug_quant      => gr_add_total(2).aug_quant      -- ８月 数量
         ,in_aug_amount     => gr_add_total(2).aug_amount     -- ８月 金額
         ,in_aug_price      => gr_add_total(2).aug_price      -- ８月 品目定価
         ,in_aug_to_amount  => gr_add_total(2).aug_to_amount  -- ８月 内訳合計
         ,in_aug_quant_t    => gr_add_total(2).aug_quant_t    -- ８月 数量(計算用)
         ,in_sep_quant      => gr_add_total(2).sep_quant      -- ９月 数量
         ,in_sep_amount     => gr_add_total(2).sep_amount     -- ９月 金額
         ,in_sep_price      => gr_add_total(2).sep_price      -- ９月 品目定価
         ,in_sep_to_amount  => gr_add_total(2).sep_to_amount  -- ９月 内訳合計
         ,in_sep_quant_t    => gr_add_total(2).sep_quant_t    -- ９月 数量(計算用)
         ,in_oct_quant      => gr_add_total(2).oct_quant      -- １０月 数量
         ,in_oct_amount     => gr_add_total(2).oct_amount     -- １０月 金額
         ,in_oct_price      => gr_add_total(2).oct_price      -- １０月 品目定価
         ,in_oct_to_amount  => gr_add_total(2).oct_to_amount  -- １０月 内訳合計
         ,in_oct_quant_t    => gr_add_total(2).oct_quant_t    -- １０月 数量(計算用)
         ,in_nov_quant      => gr_add_total(2).nov_quant      -- １１月 数量
         ,in_nov_amount     => gr_add_total(2).nov_amount     -- １１月 金額
         ,in_nov_price      => gr_add_total(2).nov_price      -- １１月 品目定価
         ,in_nov_to_amount  => gr_add_total(2).nov_to_amount  -- １１月 内訳合計
         ,in_nov_quant_t    => gr_add_total(2).nov_quant_t    -- １１月 数量(計算用)
         ,in_dec_quant      => gr_add_total(2).dec_quant      -- １２月 数量
         ,in_dec_amount     => gr_add_total(2).dec_amount     -- １２月 金額
         ,in_dec_price      => gr_add_total(2).dec_price      -- １２月 品目定価
         ,in_dec_to_amount  => gr_add_total(2).dec_to_amount  -- １２月 内訳合計
         ,in_dec_quant_t    => gr_add_total(2).dec_quant_t    -- １２月 数量(計算用)
         ,in_jan_quant      => gr_add_total(2).jan_quant      -- １月 数量
         ,in_jan_amount     => gr_add_total(2).jan_amount     -- １月 金額
         ,in_jan_price      => gr_add_total(2).jan_price      -- １月 品目定価
         ,in_jan_to_amount  => gr_add_total(2).jan_to_amount  -- １月 内訳合計
         ,in_jan_quant_t    => gr_add_total(2).jan_quant_t    -- １月 数量(計算用)
         ,in_feb_quant      => gr_add_total(2).feb_quant      -- ２月 数量
         ,in_feb_amount     => gr_add_total(2).feb_amount     -- ２月 金額
         ,in_feb_price      => gr_add_total(2).feb_price      -- ２月 品目定価
         ,in_feb_to_amount  => gr_add_total(2).feb_to_amount  -- ２月 内訳合計
         ,in_feb_quant_t    => gr_add_total(2).feb_quant_t    -- ２月 数量(計算用)
         ,in_mar_quant      => gr_add_total(2).mar_quant      -- ３月 数量
         ,in_mar_amount     => gr_add_total(2).mar_amount     -- ３月 金額
         ,in_mar_price      => gr_add_total(2).mar_price      -- ３月 品目定価
         ,in_mar_to_amount  => gr_add_total(2).mar_to_amount  -- ３月 内訳合計
         ,in_mar_quant_t    => gr_add_total(2).mar_quant_t    -- ３月 数量(計算用)
         ,in_apr_quant      => gr_add_total(2).apr_quant      -- ４月 数量
         ,in_apr_amount     => gr_add_total(2).apr_amount     -- ４月 金額
         ,in_apr_price      => gr_add_total(2).apr_price      -- ４月 品目定価
         ,in_apr_to_amount  => gr_add_total(2).apr_to_amount  -- ４月 内訳合計
         ,in_apr_quant_t    => gr_add_total(2).apr_quant_t    -- ４月 数量(計算用)
         ,in_year_quant     => gr_add_total(2).year_quant     -- 年計 数量
         ,in_year_amount    => gr_add_total(2).year_amount    -- 年計 金額
         ,in_year_price     => gr_add_total(2).year_price     -- 年計 品目定価
         ,in_year_to_amount => gr_add_total(2).year_to_amount -- 年計 内訳合計
         ,in_year_quant_t   => gr_add_total(2).year_quant_t   -- 年計 数量(計算用)
         ,ov_errbuf         => lv_errbuf   -- エラー・メッセージ           --# 固定 #
         ,ov_retcode        => lv_retcode  -- リターン・コード             --# 固定 #
         ,ov_errmsg         => lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
        );
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
*/
--
      --------------------------------------------------------
      -- (拠点ごと)(1)小群計/(2)大群計データ出力 
      --------------------------------------------------------
      <<gun_loop>>
      FOR n IN 1..2 LOOP        -- 小群計/大群計
--
        -- 小群計の場合
        IF ( n = 1) THEN
          lv_param_name  := gv_name_st;
          lv_param_label := gv_label_st;
        -- 大群計の場合
        ELSE
          lv_param_name  := gv_name_lt;
          lv_param_label := gv_label_lt;
        END IF;
--
        prc_create_xml_data_st_lt
        (
            iv_label_name      => lv_param_name                   -- 大群計用タグ名
          ,iv_name            => lv_param_label                  -- 大群計タイトル
          ,in_may_quant       => gr_add_total(n).may_quant       -- ５月 数量
          ,in_may_amount      => gr_add_total(n).may_amount      -- ５月 金額
          ,in_may_price       => gr_add_total(n).may_price       -- ５月 品目定価
          ,in_may_to_amount   => gr_add_total(n).may_to_amount   -- ５月 内訳合計
          ,in_may_quant_t     => gr_add_total(n).may_quant_t     -- ５月 数量(計算用)
          ,in_may_s_cost      => gr_add_total(n).may_s_cost      -- ５月 標準原価(計算用)
          ,in_may_calc        => gr_add_total(n).may_calc        -- ５月 品目定価*数量(計算用)
          ,in_may_minus_flg   => gr_add_total(n).may_minus_flg   -- ５月 数量マイナス値存在フラグ(計算用)
          ,in_may_ht_zero_flg => gr_add_total(n).may_ht_zero_flg -- ５月 品目定価*数量(計)
          ,in_jun_quant       => gr_add_total(n).jun_quant       -- ６月 数量
          ,in_jun_amount      => gr_add_total(n).jun_amount      -- ６月 金額
          ,in_jun_price       => gr_add_total(n).jun_price       -- ６月 品目定価
          ,in_jun_to_amount   => gr_add_total(n).jun_to_amount   -- ６月 内訳合計
          ,in_jun_quant_t     => gr_add_total(n).jun_quant_t     -- ６月 数量(計算用)
          ,in_jun_s_cost      => gr_add_total(n).jun_s_cost      -- ６月 標準原価(計算用)
          ,in_jun_calc        => gr_add_total(n).jun_calc        -- ６月 品目定価*数量(計算用)
          ,in_jun_minus_flg   => gr_add_total(n).jun_minus_flg   -- ６月 数量マイナス値存在フラグ(計算用)
          ,in_jun_ht_zero_flg => gr_add_total(n).jun_ht_zero_flg -- ６月 品目定価*数量(計)
          ,in_jul_quant       => gr_add_total(n).jul_quant       -- ７月 数量
          ,in_jul_amount      => gr_add_total(n).jul_amount      -- ７月 金額
          ,in_jul_price       => gr_add_total(n).jul_price       -- ７月 品目定価
          ,in_jul_to_amount   => gr_add_total(n).jul_to_amount   -- ７月 内訳合計
          ,in_jul_quant_t     => gr_add_total(n).jul_quant_t     -- ７月 数量(計算用)
          ,in_jul_s_cost      => gr_add_total(n).jul_s_cost      -- ７月 標準原価(計算用)
          ,in_jul_calc        => gr_add_total(n).jul_calc        -- ７月 品目定価*数量(計算用)
          ,in_jul_minus_flg   => gr_add_total(n).jul_minus_flg   -- ７月 数量マイナス値存在フラグ(計算用)
          ,in_jul_ht_zero_flg => gr_add_total(n).jul_ht_zero_flg -- ７月 品目定価*数量(計)
          ,in_aug_quant       => gr_add_total(n).aug_quant       -- ８月 数量
          ,in_aug_amount      => gr_add_total(n).aug_amount      -- ８月 金額
          ,in_aug_price       => gr_add_total(n).aug_price       -- ８月 品目定価
          ,in_aug_to_amount   => gr_add_total(n).aug_to_amount   -- ８月 内訳合計
          ,in_aug_quant_t     => gr_add_total(n).aug_quant_t     -- ８月 数量(計算用)
          ,in_aug_s_cost      => gr_add_total(n).aug_s_cost      -- ８月 標準原価(計算用)
          ,in_aug_calc        => gr_add_total(n).aug_calc        -- ８月 品目定価*数量(計算用)
          ,in_aug_minus_flg   => gr_add_total(n).aug_minus_flg   -- ８月 数量マイナス値存在フラグ(計算用)
          ,in_aug_ht_zero_flg => gr_add_total(n).aug_ht_zero_flg -- ８月 品目定価*数量(計)
          ,in_sep_quant       => gr_add_total(n).sep_quant       -- ９月 数量
          ,in_sep_amount      => gr_add_total(n).sep_amount      -- ９月 金額
          ,in_sep_price       => gr_add_total(n).sep_price       -- ９月 品目定価
          ,in_sep_to_amount   => gr_add_total(n).sep_to_amount   -- ９月 内訳合計
          ,in_sep_quant_t     => gr_add_total(n).sep_quant_t     -- ９月 数量(計算用)
          ,in_sep_s_cost      => gr_add_total(n).sep_s_cost      -- ９月 標準原価(計算用)
          ,in_sep_calc        => gr_add_total(n).sep_calc        -- ９月 品目定価*数量(計算用)
          ,in_sep_minus_flg   => gr_add_total(n).sep_minus_flg   -- ９月 数量マイナス値存在フラグ(計算用)
          ,in_sep_ht_zero_flg => gr_add_total(n).sep_ht_zero_flg -- ９月 品目定価*数量(計)
          ,in_oct_quant       => gr_add_total(n).oct_quant       -- １０月 数量
          ,in_oct_amount      => gr_add_total(n).oct_amount      -- １０月 金額
          ,in_oct_price       => gr_add_total(n).oct_price       -- １０月 品目定価
          ,in_oct_to_amount   => gr_add_total(n).oct_to_amount   -- １０月 内訳合計
          ,in_oct_quant_t     => gr_add_total(n).oct_quant_t     -- １０月 数量(計算用)
          ,in_oct_s_cost      => gr_add_total(n).oct_s_cost      -- １０月 標準原価(計算用)
          ,in_oct_calc        => gr_add_total(n).oct_calc        -- １０月 品目定価*数量(計算用)
          ,in_oct_minus_flg   => gr_add_total(n).oct_minus_flg   -- １０月 数量マイナス値存在フラグ(計算用)
          ,in_oct_ht_zero_flg => gr_add_total(n).oct_ht_zero_flg -- １０月 品目定価*数量(計)
          ,in_nov_quant       => gr_add_total(n).nov_quant       -- １１月 数量
          ,in_nov_amount      => gr_add_total(n).nov_amount      -- １１月 金額
          ,in_nov_price       => gr_add_total(n).nov_price       -- １１月 品目定価
          ,in_nov_to_amount   => gr_add_total(n).nov_to_amount   -- １１月 内訳合計
          ,in_nov_quant_t     => gr_add_total(n).nov_quant_t     -- １１月 数量(計算用)
          ,in_nov_s_cost      => gr_add_total(n).nov_s_cost      -- １１月 標準原価(計算用)
          ,in_nov_calc        => gr_add_total(n).nov_calc        -- １１月 品目定価*数量(計算用)
          ,in_nov_minus_flg   => gr_add_total(n).nov_minus_flg   -- １１月 数量マイナス値存在フラグ(計算用)
          ,in_nov_ht_zero_flg => gr_add_total(n).nov_ht_zero_flg -- １１月 品目定価*数量(計)
          ,in_dec_quant       => gr_add_total(n).dec_quant       -- １２月 数量
          ,in_dec_amount      => gr_add_total(n).dec_amount      -- １２月 金額
          ,in_dec_price       => gr_add_total(n).dec_price       -- １２月 品目定価
          ,in_dec_to_amount   => gr_add_total(n).dec_to_amount   -- １２月 内訳合計
          ,in_dec_quant_t     => gr_add_total(n).dec_quant_t     -- １２月 数量(計算用)
          ,in_dec_s_cost      => gr_add_total(n).dec_s_cost      -- １２月 標準原価(計算用)
          ,in_dec_calc        => gr_add_total(n).dec_calc        -- １２月 品目定価*数量(計算用)
          ,in_dec_minus_flg   => gr_add_total(n).dec_minus_flg   -- １２月 数量マイナス値存在フラグ(計算用)
          ,in_dec_ht_zero_flg => gr_add_total(n).dec_ht_zero_flg -- １２月 品目定価*数量(計)
          ,in_jan_quant       => gr_add_total(n).jan_quant       -- １月 数量
          ,in_jan_amount      => gr_add_total(n).jan_amount      -- １月 金額
          ,in_jan_price       => gr_add_total(n).jan_price       -- １月 品目定価
          ,in_jan_to_amount   => gr_add_total(n).jan_to_amount   -- １月 内訳合計
          ,in_jan_quant_t     => gr_add_total(n).jan_quant_t     -- １月 数量(計算用)
          ,in_jan_s_cost      => gr_add_total(n).jan_s_cost      -- １月 標準原価(計算用)
          ,in_jan_calc        => gr_add_total(n).jan_calc        -- １月 品目定価*数量(計算用)
          ,in_jan_minus_flg   => gr_add_total(n).jan_minus_flg   -- １月 数量マイナス値存在フラグ(計算用)
          ,in_jan_ht_zero_flg => gr_add_total(n).jan_ht_zero_flg -- １月 品目定価*数量(計)
          ,in_feb_quant       => gr_add_total(n).feb_quant       -- ２月 数量
          ,in_feb_amount      => gr_add_total(n).feb_amount      -- ２月 金額
          ,in_feb_price       => gr_add_total(n).feb_price       -- ２月 品目定価
          ,in_feb_to_amount   => gr_add_total(n).feb_to_amount   -- ２月 内訳合計
          ,in_feb_quant_t     => gr_add_total(n).feb_quant_t     -- ２月 数量(計算用)
          ,in_feb_s_cost      => gr_add_total(n).feb_s_cost      -- ２月 標準原価(計算用)
          ,in_feb_calc        => gr_add_total(n).feb_calc        -- ２月 品目定価*数量(計算用)
          ,in_feb_minus_flg   => gr_add_total(n).feb_minus_flg   -- ２月 数量マイナス値存在フラグ(計算用)
          ,in_feb_ht_zero_flg => gr_add_total(n).feb_ht_zero_flg -- ２月 品目定価*数量(計)
          ,in_mar_quant       => gr_add_total(n).mar_quant       -- ３月 数量
          ,in_mar_amount      => gr_add_total(n).mar_amount      -- ３月 金額
          ,in_mar_price       => gr_add_total(n).mar_price       -- ３月 品目定価
          ,in_mar_to_amount   => gr_add_total(n).mar_to_amount   -- ３月 内訳合計
          ,in_mar_quant_t     => gr_add_total(n).mar_quant_t     -- ３月 数量(計算用)
          ,in_mar_s_cost      => gr_add_total(n).mar_s_cost      -- ３月 標準原価(計算用)
          ,in_mar_calc        => gr_add_total(n).mar_calc        -- ３月 品目定価*数量(計算用)
          ,in_mar_minus_flg   => gr_add_total(n).mar_minus_flg   -- ３月 数量マイナス値存在フラグ(計算用)
          ,in_mar_ht_zero_flg => gr_add_total(n).mar_ht_zero_flg -- ３月 品目定価*数量(計)
          ,in_apr_quant       => gr_add_total(n).apr_quant       -- ４月 数量
          ,in_apr_amount      => gr_add_total(n).apr_amount      -- ４月 金額
          ,in_apr_price       => gr_add_total(n).apr_price       -- ４月 品目定価
          ,in_apr_to_amount   => gr_add_total(n).apr_to_amount   -- ４月 内訳合計
          ,in_apr_quant_t     => gr_add_total(n).apr_quant_t     -- ４月 数量(計算用)
          ,in_apr_s_cost      => gr_add_total(n).apr_s_cost      -- ４月 標準原価(計算用)
          ,in_apr_calc        => gr_add_total(n).apr_calc        -- ４月 品目定価*数量(計算用)
          ,in_apr_minus_flg   => gr_add_total(n).apr_minus_flg   -- ４月 数量マイナス値存在フラグ(計算用)
          ,in_apr_ht_zero_flg => gr_add_total(n).apr_ht_zero_flg -- ４月 品目定価*数量(計)
          ,in_year_quant      => gr_add_total(n).year_quant        -- 年計 数量
          ,in_year_amount     => gr_add_total(n).year_amount       -- 年計 金額
          ,in_year_price      => gr_add_total(n).year_price        -- 年計 品目定価
          ,in_year_to_amount  => gr_add_total(n).year_to_amount    -- 年計 内訳合計
          ,in_year_quant_t    => gr_add_total(n).year_quant_t      -- 年計 数量(計算用)
          ,in_year_s_cost     => gr_add_total(n).year_s_cost       -- 年計 標準原価(計算用)
          ,in_year_calc       => gr_add_total(n).year_calc         -- 年計 品目定価*数量(計算用)
          ,in_year_minus_flg   => gr_add_total(n).year_minus_flg   -- 年計 数量マイナス値存在フラグ(計算用)
          ,in_year_ht_zero_flg => gr_add_total(n).year_ht_zero_flg -- 年計 品目定価*数量(計)
          ,ov_errbuf         => lv_errbuf   -- エラー・メッセージ           --# 固定 #
          ,ov_retcode        => lv_retcode  -- リターン・コード             --# 固定 #
          ,ov_errmsg         => lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
        );
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_process_expt;
        END IF;
--
      END LOOP gun_loop;
--
-- 2009/04/16 v1.6 T.Yoshimoto Mod End 本番#1410
--
      -- -----------------------------------------------------
      --  (拠点ごと)群コード終了Ｇタグ出力
      -- -----------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1;
      gt_xml_data_table(gl_xml_idx).tag_name  := '/g_gun';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
      -- -----------------------------------------------------
      --  (拠点ごと)群コード終了ＬＧタグ出力
      -- -----------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1;
      gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_gun_info';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
-- 2009/04/16 v1.6 T.Yoshimoto Mod Start 本番#1410
/*
      --------------------------------------------------------
      -- 拠点計データタグ出力 
      --------------------------------------------------------
      prc_create_xml_data_s_k_t
        (
          iv_label_name     => gv_name_ktn                    -- 拠点計用タグ名
         ,in_may_quant      => gr_add_total(3).may_quant      -- ５月 数量
         ,in_may_amount     => gr_add_total(3).may_amount     -- ５月 金額
         ,in_may_price      => gr_add_total(3).may_price      -- ５月 品目定価
         ,in_may_to_amount  => gr_add_total(3).may_to_amount  -- ５月 内訳合計
         ,in_jun_quant      => gr_add_total(3).jun_quant      -- ６月 数量
         ,in_jun_amount     => gr_add_total(3).jun_amount     -- ６月 金額
         ,in_jun_price      => gr_add_total(3).jun_price      -- ６月 品目定価
         ,in_jun_to_amount  => gr_add_total(3).jun_to_amount  -- ６月 内訳合計
         ,in_jul_quant      => gr_add_total(3).jul_quant      -- ７月 数量
         ,in_jul_amount     => gr_add_total(3).jul_amount     -- ７月 金額
         ,in_jul_price      => gr_add_total(3).jul_price      -- ７月 品目定価
         ,in_jul_to_amount  => gr_add_total(3).jul_to_amount  -- ７月 内訳合計
         ,in_aug_quant      => gr_add_total(3).aug_quant      -- ８月 数量
         ,in_aug_amount     => gr_add_total(3).aug_amount     -- ８月 金額
         ,in_aug_price      => gr_add_total(3).aug_price      -- ８月 品目定価
         ,in_aug_to_amount  => gr_add_total(3).aug_to_amount  -- ８月 内訳合計
         ,in_sep_quant      => gr_add_total(3).sep_quant      -- ９月 数量
         ,in_sep_amount     => gr_add_total(3).sep_amount     -- ９月 金額
         ,in_sep_price      => gr_add_total(3).sep_price      -- ９月 品目定価
         ,in_sep_to_amount  => gr_add_total(3).sep_to_amount  -- ９月 内訳合計
         ,in_oct_quant      => gr_add_total(3).oct_quant      -- １０月 数量
         ,in_oct_amount     => gr_add_total(3).oct_amount     -- １０月 金額
         ,in_oct_price      => gr_add_total(3).oct_price      -- １０月 品目定価
         ,in_oct_to_amount  => gr_add_total(3).oct_to_amount  -- １０月 内訳合計
         ,in_nov_quant      => gr_add_total(3).nov_quant      -- １１月 数量
         ,in_nov_amount     => gr_add_total(3).nov_amount     -- １１月 金額
         ,in_nov_price      => gr_add_total(3).nov_price      -- １１月 品目定価
         ,in_nov_to_amount  => gr_add_total(3).nov_to_amount  -- １１月 内訳合計
         ,in_dec_quant      => gr_add_total(3).dec_quant      -- １２月 数量
         ,in_dec_amount     => gr_add_total(3).dec_amount     -- １２月 金額
         ,in_dec_price      => gr_add_total(3).dec_price      -- １２月 品目定価
         ,in_dec_to_amount  => gr_add_total(3).dec_to_amount  -- １２月 内訳合計
         ,in_jan_quant      => gr_add_total(3).jan_quant      -- １月 数量
         ,in_jan_amount     => gr_add_total(3).jan_amount     -- １月 金額
         ,in_jan_price      => gr_add_total(3).jan_price      -- １月 品目定価
         ,in_jan_to_amount  => gr_add_total(3).jan_to_amount  -- １月 内訳合計
         ,in_feb_quant      => gr_add_total(3).feb_quant      -- ２月 数量
         ,in_feb_amount     => gr_add_total(3).feb_amount     -- ２月 金額
         ,in_feb_price      => gr_add_total(3).feb_price      -- ２月 品目定価
         ,in_feb_to_amount  => gr_add_total(3).feb_to_amount  -- ２月 内訳合計
         ,in_mar_quant      => gr_add_total(3).mar_quant      -- ３月 数量
         ,in_mar_amount     => gr_add_total(3).mar_amount     -- ３月 金額
         ,in_mar_price      => gr_add_total(3).mar_price      -- ３月 品目定価
         ,in_mar_to_amount  => gr_add_total(3).mar_to_amount  -- ３月 内訳合計
         ,in_apr_quant      => gr_add_total(3).apr_quant      -- ４月 数量
         ,in_apr_amount     => gr_add_total(3).apr_amount     -- ４月 金額
         ,in_apr_price      => gr_add_total(3).apr_price      -- ４月 品目定価
         ,in_apr_to_amount  => gr_add_total(3).apr_to_amount  -- ４月 内訳合計
         ,in_year_quant     => gr_add_total(3).year_quant     -- 年計 数量
         ,in_year_amount    => gr_add_total(3).year_amount    -- 年計 金額
         ,in_year_price     => gr_add_total(3).year_price     -- 年計 品目定価
         ,in_year_to_amount => gr_add_total(3).year_to_amount -- 年計 内訳合計
         ,ov_errbuf         => lv_errbuf   -- エラー・メッセージ           --# 固定 #
         ,ov_retcode        => lv_retcode  -- リターン・コード             --# 固定 #
         ,ov_errmsg         => lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
        );
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
      -- -----------------------------------------------------
      --  拠点終了Ｇタグ出力
      -- -----------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1;
      gt_xml_data_table(gl_xml_idx).tag_name  := '/g_ktn';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
      -- -----------------------------------------------------
      --  拠点終了ＬＧタグ出力
      -- -----------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1;
      gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_ktn_info';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
      --------------------------------------------------------
      -- 商品区分計データタグ出力 
      --------------------------------------------------------
      prc_create_xml_data_s_k_t
        (
          iv_label_name     => gv_name_skbn                   -- 商品区分計用タグ名
         ,in_may_quant      => gr_add_total(4).may_quant      -- ５月 数量
         ,in_may_amount     => gr_add_total(4).may_amount     -- ５月 金額
         ,in_may_price      => gr_add_total(4).may_price      -- ５月 品目定価
         ,in_may_to_amount  => gr_add_total(4).may_to_amount  -- ５月 内訳合計
         ,in_jun_quant      => gr_add_total(4).jun_quant      -- ６月 数量
         ,in_jun_amount     => gr_add_total(4).jun_amount     -- ６月 金額
         ,in_jun_price      => gr_add_total(4).jun_price      -- ６月 品目定価
         ,in_jun_to_amount  => gr_add_total(4).jun_to_amount  -- ６月 内訳合計
         ,in_jul_quant      => gr_add_total(4).jul_quant      -- ７月 数量
         ,in_jul_amount     => gr_add_total(4).jul_amount     -- ７月 金額
         ,in_jul_price      => gr_add_total(4).jul_price      -- ７月 品目定価
         ,in_jul_to_amount  => gr_add_total(4).jul_to_amount  -- ７月 内訳合計
         ,in_aug_quant      => gr_add_total(4).aug_quant      -- ８月 数量
         ,in_aug_amount     => gr_add_total(4).aug_amount     -- ８月 金額
         ,in_aug_price      => gr_add_total(4).aug_price      -- ８月 品目定価
         ,in_aug_to_amount  => gr_add_total(4).aug_to_amount  -- ８月 内訳合計
         ,in_sep_quant      => gr_add_total(4).sep_quant      -- ９月 数量
         ,in_sep_amount     => gr_add_total(4).sep_amount     -- ９月 金額
         ,in_sep_price      => gr_add_total(4).sep_price      -- ９月 品目定価
         ,in_sep_to_amount  => gr_add_total(4).sep_to_amount  -- ９月 内訳合計
         ,in_oct_quant      => gr_add_total(4).oct_quant      -- １０月 数量
         ,in_oct_amount     => gr_add_total(4).oct_amount     -- １０月 金額
         ,in_oct_price      => gr_add_total(4).oct_price      -- １０月 品目定価
         ,in_oct_to_amount  => gr_add_total(4).oct_to_amount  -- １０月 内訳合計
         ,in_nov_quant      => gr_add_total(4).nov_quant      -- １１月 数量
         ,in_nov_amount     => gr_add_total(4).nov_amount     -- １１月 金額
         ,in_nov_price      => gr_add_total(4).nov_price      -- １１月 品目定価
         ,in_nov_to_amount  => gr_add_total(4).nov_to_amount  -- １１月 内訳合計
         ,in_dec_quant      => gr_add_total(4).dec_quant      -- １２月 数量
         ,in_dec_amount     => gr_add_total(4).dec_amount     -- １２月 金額
         ,in_dec_price      => gr_add_total(4).dec_price      -- １２月 品目定価
         ,in_dec_to_amount  => gr_add_total(4).dec_to_amount  -- １２月 内訳合計
         ,in_jan_quant      => gr_add_total(4).jan_quant      -- １月 数量
         ,in_jan_amount     => gr_add_total(4).jan_amount     -- １月 金額
         ,in_jan_price      => gr_add_total(4).jan_price      -- １月 品目定価
         ,in_jan_to_amount  => gr_add_total(4).jan_to_amount  -- １月 内訳合計
         ,in_feb_quant      => gr_add_total(4).feb_quant      -- ２月 数量
         ,in_feb_amount     => gr_add_total(4).feb_amount     -- ２月 金額
         ,in_feb_price      => gr_add_total(4).feb_price      -- ２月 品目定価
         ,in_feb_to_amount  => gr_add_total(4).feb_to_amount  -- ２月 内訳合計
         ,in_mar_quant      => gr_add_total(4).mar_quant      -- ３月 数量
         ,in_mar_amount     => gr_add_total(4).mar_amount     -- ３月 金額
         ,in_mar_price      => gr_add_total(4).mar_price      -- ３月 品目定価
         ,in_mar_to_amount  => gr_add_total(4).mar_to_amount  -- ３月 内訳合計
         ,in_apr_quant      => gr_add_total(4).apr_quant      -- ４月 数量
         ,in_apr_amount     => gr_add_total(4).apr_amount     -- ４月 金額
         ,in_apr_price      => gr_add_total(4).apr_price      -- ４月 品目定価
         ,in_apr_to_amount  => gr_add_total(4).apr_to_amount  -- ４月 内訳合計
         ,in_year_quant     => gr_add_total(4).year_quant     -- 年計 数量
         ,in_year_amount    => gr_add_total(4).year_amount    -- 年計 金額
         ,in_year_price     => gr_add_total(4).year_price     -- 年計 品目定価
         ,in_year_to_amount => gr_add_total(4).year_to_amount -- 年計 内訳合計
         ,ov_errbuf         => lv_errbuf   -- エラー・メッセージ           --# 固定 #
         ,ov_retcode        => lv_retcode  -- リターン・コード             --# 固定 #
         ,ov_errmsg         => lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
        );
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
      --------------------------------------------------------
      -- 総合計データタグ出力 
      --------------------------------------------------------
      prc_create_xml_data_s_k_t
        (
          iv_label_name     => gv_name_ttl                    -- 総合計用タグ名
         ,in_may_quant      => gr_add_total(5).may_quant      -- ５月 数量
         ,in_may_amount     => gr_add_total(5).may_amount     -- ５月 金額
         ,in_may_price      => gr_add_total(5).may_price      -- ５月 品目定価
         ,in_may_to_amount  => gr_add_total(5).may_to_amount  -- ５月 内訳合計
         ,in_jun_quant      => gr_add_total(5).jun_quant      -- ６月 数量
         ,in_jun_amount     => gr_add_total(5).jun_amount     -- ６月 金額
         ,in_jun_price      => gr_add_total(5).jun_price      -- ６月 品目定価
         ,in_jun_to_amount  => gr_add_total(5).jun_to_amount  -- ６月 内訳合計
         ,in_jul_quant      => gr_add_total(5).jul_quant      -- ７月 数量
         ,in_jul_amount     => gr_add_total(5).jul_amount     -- ７月 金額
         ,in_jul_price      => gr_add_total(5).jul_price      -- ７月 品目定価
         ,in_jul_to_amount  => gr_add_total(5).jul_to_amount  -- ７月 内訳合計
         ,in_aug_quant      => gr_add_total(5).aug_quant      -- ８月 数量
         ,in_aug_amount     => gr_add_total(5).aug_amount     -- ８月 金額
         ,in_aug_price      => gr_add_total(5).aug_price      -- ８月 品目定価
         ,in_aug_to_amount  => gr_add_total(5).aug_to_amount  -- ８月 内訳合計
         ,in_sep_quant      => gr_add_total(5).sep_quant      -- ９月 数量
         ,in_sep_amount     => gr_add_total(5).sep_amount     -- ９月 金額
         ,in_sep_price      => gr_add_total(5).sep_price      -- ９月 品目定価
         ,in_sep_to_amount  => gr_add_total(5).sep_to_amount  -- ９月 内訳合計
         ,in_oct_quant      => gr_add_total(5).oct_quant      -- １０月 数量
         ,in_oct_amount     => gr_add_total(5).oct_amount     -- １０月 金額
         ,in_oct_price      => gr_add_total(5).oct_price      -- １０月 品目定価
         ,in_oct_to_amount  => gr_add_total(5).oct_to_amount  -- １０月 内訳合計
         ,in_nov_quant      => gr_add_total(5).nov_quant      -- １１月 数量
         ,in_nov_amount     => gr_add_total(5).nov_amount     -- １１月 金額
         ,in_nov_price      => gr_add_total(5).nov_price      -- １１月 品目定価
         ,in_nov_to_amount  => gr_add_total(5).nov_to_amount  -- １１月 内訳合計
         ,in_dec_quant      => gr_add_total(5).dec_quant      -- １２月 数量
         ,in_dec_amount     => gr_add_total(5).dec_amount     -- １２月 金額
         ,in_dec_price      => gr_add_total(5).dec_price      -- １２月 品目定価
         ,in_dec_to_amount  => gr_add_total(5).dec_to_amount  -- １２月 内訳合計
         ,in_jan_quant      => gr_add_total(5).jan_quant      -- １月 数量
         ,in_jan_amount     => gr_add_total(5).jan_amount     -- １月 金額
         ,in_jan_price      => gr_add_total(5).jan_price      -- １月 品目定価
         ,in_jan_to_amount  => gr_add_total(5).jan_to_amount  -- １月 内訳合計
         ,in_feb_quant      => gr_add_total(5).feb_quant      -- ２月 数量
         ,in_feb_amount     => gr_add_total(5).feb_amount     -- ２月 金額
         ,in_feb_price      => gr_add_total(5).feb_price      -- ２月 品目定価
         ,in_feb_to_amount  => gr_add_total(5).feb_to_amount  -- ２月 内訳合計
         ,in_mar_quant      => gr_add_total(5).mar_quant      -- ３月 数量
         ,in_mar_amount     => gr_add_total(5).mar_amount     -- ３月 金額
         ,in_mar_price      => gr_add_total(5).mar_price      -- ３月 品目定価
         ,in_mar_to_amount  => gr_add_total(5).mar_to_amount  -- ３月 内訳合計
         ,in_apr_quant      => gr_add_total(5).apr_quant      -- ４月 数量
         ,in_apr_amount     => gr_add_total(5).apr_amount     -- ４月 金額
         ,in_apr_price      => gr_add_total(5).apr_price      -- ４月 品目定価
         ,in_apr_to_amount  => gr_add_total(5).apr_to_amount  -- ４月 内訳合計
         ,in_year_quant     => gr_add_total(5).year_quant     -- 年計 数量
         ,in_year_amount    => gr_add_total(5).year_amount    -- 年計 金額
         ,in_year_price     => gr_add_total(5).year_price     -- 年計 品目定価
         ,in_year_to_amount => gr_add_total(5).year_to_amount -- 年計 内訳合計
         ,ov_errbuf         => lv_errbuf   -- エラー・メッセージ           --# 固定 #
         ,ov_retcode        => lv_retcode  -- リターン・コード             --# 固定 #
         ,ov_errmsg         => lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
        );
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
*/
--
      -------------------------------------------------------------
      -- (拠点ごと)(3)拠点計/(4)商品区分計/(5)総合計データタグ出力 
      -------------------------------------------------------------
      <<kyoten_skbn_total_loop>>
      FOR n IN 3..5 LOOP        -- 拠点計/商品区分計/総合計
--
        -- 拠点計の場合
        IF ( n = 3 ) THEN
          lv_param_label := gv_name_ktn;
--
        -- 商品区分計の場合
        ELSIF ( n = 4 ) THEn
          lv_param_label := gv_name_skbn;
--
        -- 総合計
        ELSE
          lv_param_label := gv_name_ttl;
--
        END IF;
--
        prc_create_xml_data_s_k_t
        (
          iv_label_name       => lv_param_label                   -- 商品区分計用タグ名
          ,in_may_quant       => gr_add_total(n).may_quant      -- ５月 数量
          ,in_may_amount      => gr_add_total(n).may_amount     -- ５月 金額
          ,in_may_price       => gr_add_total(n).may_price      -- ５月 品目定価
          ,in_may_to_amount   => gr_add_total(n).may_to_amount  -- ５月 内訳合計
          ,in_may_quant_t     => gr_add_total(n).may_quant_t    -- ５月 数量(計算用)
          ,in_may_s_cost      => gr_add_total(n).may_s_cost     -- ５月 標準原価(計算用)
          ,in_may_calc        => gr_add_total(n).may_calc       -- ５月 品目定価*数量(計算用)
          ,in_may_minus_flg   => gr_add_total(n).may_minus_flg   -- ５月 数量マイナス値存在フラグ(計算用)
          ,in_may_ht_zero_flg => gr_add_total(n).may_ht_zero_flg -- ５月 品目定価*数量(計)
          ,in_jun_quant       => gr_add_total(n).jun_quant      -- ６月 数量
          ,in_jun_amount      => gr_add_total(n).jun_amount     -- ６月 金額
          ,in_jun_price       => gr_add_total(n).jun_price      -- ６月 品目定価
          ,in_jun_to_amount   => gr_add_total(n).jun_to_amount  -- ６月 内訳合計
          ,in_jun_quant_t     => gr_add_total(n).jun_quant_t    -- ６月 数量(計算用)
          ,in_jun_s_cost      => gr_add_total(n).jun_s_cost     -- ６月 標準原価(計算用)
          ,in_jun_calc        => gr_add_total(n).jun_calc       -- ６月 品目定価*数量(計算用)
          ,in_jun_minus_flg   => gr_add_total(n).jun_minus_flg   -- ６月 数量マイナス値存在フラグ(計算用)
          ,in_jun_ht_zero_flg => gr_add_total(n).jun_ht_zero_flg -- ６月 品目定価*数量(計)
          ,in_jul_quant       => gr_add_total(n).jul_quant      -- ７月 数量
          ,in_jul_amount      => gr_add_total(n).jul_amount     -- ７月 金額
          ,in_jul_price       => gr_add_total(n).jul_price      -- ７月 品目定価
          ,in_jul_to_amount   => gr_add_total(n).jul_to_amount  -- ７月 内訳合計
          ,in_jul_quant_t     => gr_add_total(n).jul_quant_t    -- ７月 数量(計算用)
          ,in_jul_s_cost      => gr_add_total(n).jul_s_cost     -- ７月 標準原価(計算用)
          ,in_jul_calc        => gr_add_total(n).jul_calc       -- ７月 品目定価*数量(計算用)
          ,in_jul_minus_flg   => gr_add_total(n).jul_minus_flg   -- ７月 数量マイナス値存在フラグ(計算用)
          ,in_jul_ht_zero_flg => gr_add_total(n).jul_ht_zero_flg -- ７月 品目定価*数量(計)
          ,in_aug_quant       => gr_add_total(n).aug_quant      -- ８月 数量
          ,in_aug_amount      => gr_add_total(n).aug_amount     -- ８月 金額
          ,in_aug_price       => gr_add_total(n).aug_price      -- ８月 品目定価
          ,in_aug_to_amount   => gr_add_total(n).aug_to_amount  -- ８月 内訳合計
          ,in_aug_quant_t     => gr_add_total(n).aug_quant_t    -- ８月 数量(計算用)
          ,in_aug_s_cost      => gr_add_total(n).aug_s_cost     -- ８月 標準原価(計算用)
          ,in_aug_calc        => gr_add_total(n).aug_calc       -- ８月 品目定価*数量(計算用)
          ,in_aug_minus_flg   => gr_add_total(n).aug_minus_flg   -- ８月 数量マイナス値存在フラグ(計算用)
          ,in_aug_ht_zero_flg => gr_add_total(n).aug_ht_zero_flg -- ８月 品目定価*数量(計)
          ,in_sep_quant       => gr_add_total(n).sep_quant      -- ９月 数量
          ,in_sep_amount      => gr_add_total(n).sep_amount     -- ９月 金額
          ,in_sep_price       => gr_add_total(n).sep_price      -- ９月 品目定価
          ,in_sep_to_amount   => gr_add_total(n).sep_to_amount  -- ９月 内訳合計
          ,in_sep_quant_t     => gr_add_total(n).sep_quant_t    -- ９月 数量(計算用)
          ,in_sep_s_cost      => gr_add_total(n).sep_s_cost     -- ９月 標準原価(計算用)
          ,in_sep_calc        => gr_add_total(n).sep_calc       -- ９月 品目定価*数量(計算用)
          ,in_sep_minus_flg   => gr_add_total(n).sep_minus_flg   -- ９月 数量マイナス値存在フラグ(計算用)
          ,in_sep_ht_zero_flg => gr_add_total(n).sep_ht_zero_flg -- ９月 品目定価*数量(計)
          ,in_oct_quant       => gr_add_total(n).oct_quant      -- １０月 数量
          ,in_oct_amount      => gr_add_total(n).oct_amount     -- １０月 金額
          ,in_oct_price       => gr_add_total(n).oct_price      -- １０月 品目定価
          ,in_oct_to_amount   => gr_add_total(n).oct_to_amount  -- １０月 内訳合計
          ,in_oct_quant_t     => gr_add_total(n).oct_quant_t    -- １０月 数量(計算用)
          ,in_oct_s_cost      => gr_add_total(n).oct_s_cost     -- １０月 標準原価(計算用)
          ,in_oct_calc        => gr_add_total(n).oct_calc       -- １０月 品目定価*数量(計算用)
          ,in_oct_minus_flg   => gr_add_total(n).oct_minus_flg   -- １０月 数量マイナス値存在フラグ(計算用)
          ,in_oct_ht_zero_flg => gr_add_total(n).oct_ht_zero_flg -- １０月 品目定価*数量(計)
          ,in_nov_quant       => gr_add_total(n).nov_quant      -- １１月 数量
          ,in_nov_amount      => gr_add_total(n).nov_amount     -- １１月 金額
          ,in_nov_price       => gr_add_total(n).nov_price      -- １１月 品目定価
          ,in_nov_to_amount   => gr_add_total(n).nov_to_amount  -- １１月 内訳合計
          ,in_nov_quant_t     => gr_add_total(n).nov_quant_t    -- １１月 数量(計算用)
          ,in_nov_s_cost      => gr_add_total(n).nov_s_cost     -- １１月 標準原価(計算用)
          ,in_nov_calc        => gr_add_total(n).nov_calc       -- １１月 品目定価*数量(計算用)
          ,in_nov_minus_flg   => gr_add_total(n).nov_minus_flg   -- １１月 数量マイナス値存在フラグ(計算用)
          ,in_nov_ht_zero_flg => gr_add_total(n).nov_ht_zero_flg -- １１月 品目定価*数量(計)
          ,in_dec_quant       => gr_add_total(n).dec_quant      -- １２月 数量
          ,in_dec_amount      => gr_add_total(n).dec_amount     -- １２月 金額
          ,in_dec_price       => gr_add_total(n).dec_price      -- １２月 品目定価
          ,in_dec_to_amount   => gr_add_total(n).dec_to_amount  -- １２月 内訳合計
          ,in_dec_quant_t     => gr_add_total(n).dec_quant_t    -- １２月 数量(計算用)
          ,in_dec_s_cost      => gr_add_total(n).dec_s_cost     -- １２月 標準原価(計算用)
          ,in_dec_calc        => gr_add_total(n).dec_calc       -- １２月 品目定価*数量(計算用)
          ,in_dec_minus_flg   => gr_add_total(n).dec_minus_flg   -- １２月 数量マイナス値存在フラグ(計算用)
          ,in_dec_ht_zero_flg => gr_add_total(n).dec_ht_zero_flg -- １２月 品目定価*数量(計)
          ,in_jan_quant       => gr_add_total(n).jan_quant      -- １月 数量
          ,in_jan_amount      => gr_add_total(n).jan_amount     -- １月 金額
          ,in_jan_price       => gr_add_total(n).jan_price      -- １月 品目定価
          ,in_jan_to_amount   => gr_add_total(n).jan_to_amount  -- １月 内訳合計
          ,in_jan_quant_t     => gr_add_total(n).jan_quant_t    -- １月 数量(計算用)
          ,in_jan_s_cost      => gr_add_total(n).jan_s_cost     -- １月 標準原価(計算用)
          ,in_jan_calc        => gr_add_total(n).jan_calc       -- １月 品目定価*数量(計算用)
          ,in_jan_minus_flg   => gr_add_total(n).jan_minus_flg   -- １月 数量マイナス値存在フラグ(計算用)
          ,in_jan_ht_zero_flg => gr_add_total(n).jan_ht_zero_flg -- １月 品目定価*数量(計)
          ,in_feb_quant       => gr_add_total(n).feb_quant      -- ２月 数量
          ,in_feb_amount      => gr_add_total(n).feb_amount     -- ２月 金額
          ,in_feb_price       => gr_add_total(n).feb_price      -- ２月 品目定価
          ,in_feb_to_amount   => gr_add_total(n).feb_to_amount  -- ２月 内訳合計
          ,in_feb_quant_t     => gr_add_total(n).feb_quant_t    -- ２月 数量(計算用)
          ,in_feb_s_cost      => gr_add_total(n).feb_s_cost     -- ２月 標準原価(計算用)
          ,in_feb_calc        => gr_add_total(n).feb_calc       -- ２月 品目定価*数量(計算用)
          ,in_feb_minus_flg   => gr_add_total(n).feb_minus_flg   -- ２月 数量マイナス値存在フラグ(計算用)
          ,in_feb_ht_zero_flg => gr_add_total(n).feb_ht_zero_flg -- ２月 品目定価*数量(計)
          ,in_mar_quant       => gr_add_total(n).mar_quant      -- ３月 数量
          ,in_mar_amount      => gr_add_total(n).mar_amount     -- ３月 金額
          ,in_mar_price       => gr_add_total(n).mar_price      -- ３月 品目定価
          ,in_mar_to_amount   => gr_add_total(n).mar_to_amount  -- ３月 内訳合計
          ,in_mar_quant_t     => gr_add_total(n).mar_quant_t    -- ３月 数量(計算用)
          ,in_mar_s_cost      => gr_add_total(n).mar_s_cost     -- ３月 標準原価(計算用)
          ,in_mar_calc        => gr_add_total(n).mar_calc       -- ３月 品目定価*数量(計算用)
          ,in_mar_minus_flg   => gr_add_total(n).mar_minus_flg   -- ３月 数量マイナス値存在フラグ(計算用)
          ,in_mar_ht_zero_flg => gr_add_total(n).mar_ht_zero_flg -- ３月 品目定価*数量(計)
          ,in_apr_quant       => gr_add_total(n).apr_quant      -- ４月 数量
          ,in_apr_amount      => gr_add_total(n).apr_amount     -- ４月 金額
          ,in_apr_price       => gr_add_total(n).apr_price      -- ４月 品目定価
          ,in_apr_to_amount   => gr_add_total(n).apr_to_amount  -- ４月 内訳合計
          ,in_apr_quant_t     => gr_add_total(n).apr_quant_t    -- ４月 数量(計算用)
          ,in_apr_s_cost      => gr_add_total(n).apr_s_cost     -- ４月 標準原価(計算用)
          ,in_apr_calc        => gr_add_total(n).apr_calc       -- ４月 品目定価*数量(計算用)
          ,in_apr_minus_flg   => gr_add_total(n).apr_minus_flg   -- ４月 数量マイナス値存在フラグ(計算用)
          ,in_apr_ht_zero_flg => gr_add_total(n).apr_ht_zero_flg -- ４月 品目定価*数量(計)
          ,in_year_quant      => gr_add_total(n).year_quant     -- 年計 数量
          ,in_year_amount     => gr_add_total(n).year_amount    -- 年計 金額
          ,in_year_price      => gr_add_total(n).year_price     -- 年計 品目定価
          ,in_year_to_amount  => gr_add_total(n).year_to_amount -- 年計 内訳合計
          ,in_year_quant_t    => gr_add_total(n).year_quant_t   -- 年計 数量(計算用)
          ,in_year_s_cost     => gr_add_total(n).year_s_cost    -- 年計 標準原価(計算用)
          ,in_year_calc       => gr_add_total(n).year_calc      -- 年計 品目定価*数量(計算用)
          ,in_year_minus_flg   => gr_add_total(n).year_minus_flg   -- 年計 数量マイナス値存在フラグ(計算用)
          ,in_year_ht_zero_flg => gr_add_total(n).year_ht_zero_flg -- 年計 品目定価*数量(計)
          ,ov_errbuf         => lv_errbuf   -- エラー・メッセージ           --# 固定 #
          ,ov_retcode        => lv_retcode  -- リターン・コード             --# 固定 #
          ,ov_errmsg         => lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
        );
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_process_expt;
        END IF;
--
        -- 拠点計の場合
        IF ( n = 3) THEN
          -- -----------------------------------------------------
          --  拠点終了Ｇタグ出力
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_ktn';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
          -- -----------------------------------------------------
          --  拠点終了ＬＧタグ出力
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_ktn_info';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
        END IF;
    --
      END LOOP kyoten_skbn_total_loop;
-- 2009/04/16 v1.6 T.Yoshimoto Mod End
--
      -- -----------------------------------------------------
      -- (拠点ごと)商品区分終了Ｇタグ出力
      -- -----------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1;
      gt_xml_data_table(gl_xml_idx).tag_name  := '/g_skbn';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
      -- -----------------------------------------------------
      -- (拠点ごと)商品区分終了ＬＧタグ出力
      -- -----------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1;
      gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_skbn_info';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
      -- -----------------------------------------------------
      -- (拠点ごと)データ終了タグ出力
      -- -----------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1;
      gt_xml_data_table(gl_xml_idx).tag_name  := '/data_info';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
      -- -----------------------------------------------------
      -- (拠点ごと)ルート終了タグ出力
      -- -----------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1;
      gt_xml_data_table(gl_xml_idx).tag_name  := '/root';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
    END IF;
--
  EXCEPTION
    -- *** 取得データ０件 ***
    WHEN no_data_expt THEN
      ov_retcode := gv_status_warn;
      ov_errmsg  := xxcmn_common_pkg.get_msg(
                                              gv_application
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
    xml_data_table   XML_DATA;
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
    -- データ取得 - カスタムオプション取得  (C-1-0)
    -- =====================================================
    pro_get_cus_option
      (
        ov_errbuf   => lv_errbuf     -- エラー・メッセージ           --# 固定 #
       ,ov_retcode  => lv_retcode    -- リターン・コード             --# 固定 #
       ,ov_errmsg   => lv_errmsg     -- ユーザー・エラー・メッセージ --# 固定 #
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
        ov_errbuf   => lv_errbuf      -- エラー・メッセージ           --# 固定 #
       ,ov_retcode  => lv_retcode     -- リターン・コード             --# 固定 #
       ,ov_errmsg   => lv_errmsg      -- ユーザー・エラー・メッセージ --# 固定 #
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
        ov_errbuf   => lv_errbuf      -- エラー・メッセージ           --# 固定 #
       ,ov_retcode  => lv_retcode     -- リターン・コード             --# 固定 #
       ,ov_errmsg   => lv_errmsg      -- ユーザー・エラー・メッセージ --# 固定 #
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
        ov_errbuf   => lv_errbuf      -- エラー・メッセージ           --# 固定 #
       ,ov_retcode  => lv_retcode     -- リターン・コード             --# 固定 #
       ,ov_errmsg   => lv_errmsg      -- ユーザー・エラー・メッセージ --# 固定 #
      );
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ==================================================
    -- XMLタグ出力
    -- ==================================================
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<?xml version="1.0" encoding="shift_jis" ?>');
--
    -- --------------------------------------------------
    -- 抽出データが０件の場合
    -- --------------------------------------------------
    IF ((lv_errmsg IS NOT NULL)
      AND (lv_retcode = gv_status_warn)) THEN
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
    -- 抽出データが１件以上の場合
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
--
--###########################  固定部 START   ###########################
--
  IS
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
    IF ( lv_retcode = gv_status_error ) THEN
      errbuf := lv_errmsg;
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf);
--
    ELSIF ( lv_retcode = gv_status_warn ) THEN
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
END xxinv100003c;
/
