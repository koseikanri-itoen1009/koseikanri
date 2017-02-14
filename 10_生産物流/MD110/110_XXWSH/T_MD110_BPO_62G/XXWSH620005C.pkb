CREATE OR REPLACE PACKAGE BODY xxwsh620005c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxwsh620005c(body)
 * Description      : 出庫指示確認表
 * MD.050           : 引当/配車(帳票) T_MD050_BPO_621
 * MD.070           : 出庫指示確認表 T_MD070_BPO_62G
 * Version          : 1.12
 *
 * Program List
 * ---------------------------- ----------------------------------------------------------
 *  Name                         Description
 * ---------------------------- ----------------------------------------------------------
 *  fnc_conv_xml                   FUNCTION   : ＸＭＬタグに変換する。
 *  prc_out_xml_data               PROCEDURE  : ＸＭＬ出力処理
 *  prc_create_zeroken_xml_data    PROCEDURE  : ＸＭＬデータ作成処理（０件）
 *  prc_create_xml_data            PROCEDURE  : ＸＭＬデータ作成処理
 *  prc_get_report_data            PROCEDURE  : 帳票情報取得処理
 *  prc_get_profile                PROCEDURE  : プロファイル取得処理
 *  prc_chk_input_param            PROCEDURE  : 入力パラメータチェック処理
 *  submain                        PROCEDURE  : メイン処理プロシージャ
 *  main                           PROCEDURE  : コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- --------------------- -------------------------------------------------
 *  Date          Ver.  Editor                Description
 * ------------- ----- --------------------- -------------------------------------------------
 *  2008/05/12    1.0   Masakazu Yamashita    新規作成
 *  2008/06/04    1.1   Jun Nakada            クイックコード警告区分の結合を外部結合に変更(出荷移動)
 *  2008/06/17    1.2   Masao Hokkanji        システムテスト不具合No150対応
 *  2008/06/18    1.3   Kazuo Kumamoto        事業所情報VIEWの結合を外部結合に変更
 *  2008/06/19    1.4   SCS yamane            配車配送情報VIEWの結合を外部結合に変更
 *  2008/07/02    1.5   Akiyoshi Shiina       変更要求対応#92
 *                                            禁則文字「'」「"」「<」「>」「＆」対応
 *  2008/07/11    1.6   Kazuo Kumamoto        結合テスト障害対応(単位出力制御)
 *  2008/08/05    1.7   Yasuhisa Yamamoto     内部変更要求対応
 *  2008/09/25    1.8   Yasuhisa Yamamoto     T_TE080_BPO_620 #36,41、使用不備障害T_S_479,501
 *  2008/11/14    1.9   Naoki Fukuda          課題#62(内部変更#168)対応(指示無し実績を除外する)
 *  2009/05/28    1.10  Hitomi Itou           本番障害#1398
 *  2009/09/14    1.11  Hitomi Itou           本番障害#1632
 *  2017/01/27    1.12  Shigeto Niki          E_本稼動_14014
 *****************************************************************************************/
--
--#######################  固定グローバル定数宣言部 START   #######################
--
  gv_status_normal CONSTANT VARCHAR2(1) := '0' ;
  gv_status_warn   CONSTANT VARCHAR2(1) := '1' ;
  gv_status_error  CONSTANT VARCHAR2(1) := '2' ;
  gv_msg_part      CONSTANT VARCHAR2(3) := ' : ' ;
  gv_msg_cont      CONSTANT VARCHAR2(3) := '.';
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
  gv_pkg_name                CONSTANT  VARCHAR2(12) := 'xxwsh620005c' ;  -- パッケージ名
  gv_report_id               CONSTANT  VARCHAR2(12) := 'XXWSH620005T' ;  -- 帳票ID
  -- 日付フォーマット
  gv_date_fmt_mi             CONSTANT  VARCHAR2(10) := 'MI' ;
  gv_date_fmt_hh24mi         CONSTANT  VARCHAR2(10) := 'HH24:MI' ;
  gv_date_fmt_ymd            CONSTANT  VARCHAR2(10) := 'YYYY/MM/DD' ;
  gv_date_fmt_ymdhm          CONSTANT  VARCHAR2(30) := 'YYYY/MM/DD HH24:MI' ;
  gv_date_fmt_ymdhm_ja       CONSTANT  VARCHAR2(40) := 'YYYY"年"MM"月"DD"日"HH24"時"MI"分' ;
  gv_date_fmt_all            CONSTANT  VARCHAR2(30) := 'YYYY/MM/DD HH24:MI:SS' ;
  gv_min_time                CONSTANT  VARCHAR2(10) := '0000' ;
  gv_max_time                CONSTANT  VARCHAR2(10) := '2359' ;
--
  ------------------------------
  -- メッセージ関連
  ------------------------------
  --アプリケーション名
  gv_application_wsh         CONSTANT  VARCHAR2(5)  := 'XXWSH' ;
  gv_application_cmn         CONSTANT  VARCHAR2(10) := 'XXCMN' ;
  --メッセージID（プロファイル取得エラー）
  gv_msg_id_not_get_prof     CONSTANT  VARCHAR2(15) := 'APP-XXWSH-12251' ;
  --メッセージID（データなしエラー）
  gv_msg_not_data_found      CONSTANT  VARCHAR2(50) := 'APP-XXCMN-10122';
  --メッセージID（パラメータチェックエラー）
  gv_msg_err_param           CONSTANT  VARCHAR2(50) := 'APP-XXWSH-12256';
  --メッセージ-トークン名（プロファイル名）
  gv_msg_tkn_nm_prof         CONSTANT  VARCHAR2(10) := 'PROF_NAME' ;
  --メッセージ-トークン値
  gv_msg_tkn_val_prof_wei    CONSTANT  VARCHAR2(30) := 'XXWSH:出荷重量単位' ;
  gv_msg_tkn_val_prof_cap    CONSTANT  VARCHAR2(30) := 'XXWSH:出荷容積単位' ;
  gv_msg_tkn_val_prof_prod   CONSTANT  VARCHAR2(30) := 'XXCMN：商品区分(セキュリティ)' ;
  ------------------------------
  -- プロファイル関連
  ------------------------------
  gv_prof_name_weight        CONSTANT  VARCHAR2(30) := 'XXWSH_WEIGHT_UOM' ;        -- 出荷重量単位
  gv_prof_name_capacity      CONSTANT  VARCHAR2(30) := 'XXWSH_CAPACITY_UOM' ;      -- 出荷容積単位
  gv_prof_name_item_div      CONSTANT  VARCHAR2(30) := 'XXCMN_ITEM_DIV_SECURITY' ; -- 商品区分
    ------------------------------
  -- 出荷・移動共通
  ------------------------------
  -- 業務種別
  gv_biz_type_cd_ship        CONSTANT  VARCHAR2(1)  := '1' ;        -- 出荷
  gv_biz_type_cd_move        CONSTANT  VARCHAR2(1)  := '3' ;        -- 移動
  gv_biz_type_nm_ship        CONSTANT  VARCHAR2(4)  := '出荷' ;     -- 出荷
  gv_biz_type_nm_move        CONSTANT  VARCHAR2(4)  := '移動' ;     -- 移動
  -- 契約外運賃区分
  gv_no_cont_freight_kbn_obj CONSTANT  VARCHAR2(1)  := '1' ;        -- 対象
  -- 品目・商品区分
  gv_prod_cd_drink           CONSTANT  VARCHAR2(1)  := '2' ;        -- 商品区分:ドリンク
  gv_item_cd_prdct           CONSTANT  VARCHAR2(1)  := '5' ;        -- 品目区分:製品
-- 2008/09/29 Y.Yamamoto v1.8 ADD Start
  gv_item_cd_genryo          CONSTANT  VARCHAR2(1)  := '1' ;        -- 品目区分:原料
  gv_item_cd_sizai           CONSTANT  VARCHAR2(1)  := '2' ;        -- 品目区分:資材
  gv_item_cd_hanseihin       CONSTANT  VARCHAR2(1)  := '4' ;        -- 品目区分:半製品
-- 2008/09/29 Y.Yamamoto v1.8 ADD End
  -- 自動手動引当区分
  gv_auto_manual_kbn_a       CONSTANT  VARCHAR2(10) := '10' ;       -- 自動
-- v1.12 ADD Start
  gv_auto_manual_kbn_m       CONSTANT  VARCHAR2(10) := '20' ;       -- 手動
-- v1.12 ADD End
  -- 小口区分
  gv_small_kbn_obj           CONSTANT  VARCHAR2(1)  := '1' ;        -- 対象
  gv_small_kbn_not_obj       CONSTANT  VARCHAR2(1)  := '0' ;        -- 対象外
  -- 重量容積区分
  gv_wei_cap_kbn_w           CONSTANT  VARCHAR2(1)  := '1' ;        -- 重量
  gv_wei_cap_kbn_c           CONSTANT  VARCHAR2(1)  := '2' ;        -- 容積
-- v1.12 ADD Start
  -- 手動のみ
  gv_reserve_class_y         CONSTANT  VARCHAR2(1)  := 'Y' ;        -- 手動
-- v1.12 ADD End
  ------------------------------
  -- 出荷関連
  ------------------------------
  -- 出荷依頼ステータス
  gv_ship_status_close       CONSTANT  VARCHAR2(2)  := '03' ;       -- 締め済み
  gv_ship_status_delete      CONSTANT  VARCHAR2(2)  := '99' ;       -- 取消
  -- 出荷支給区分
  gv_ship_pro_kbn_s          CONSTANT  VARCHAR2(1)  := '1' ;        -- 出荷依頼
  -- 受注カテゴリ
  gv_order_cate_ret          CONSTANT  VARCHAR2(10) := 'RETURN' ;   -- 返品（受注のみ）
  -- 文書タイプ
  gv_document_type_ship_req  CONSTANT  VARCHAR2(10) := '10' ;       -- 出荷依頼
  -- レコードタイプ
  record_type_siji           CONSTANT  VARCHAR2(10) := '10' ;       -- 指示
  ------------------------------
  -- 移動関連
  ------------------------------
  -- 文書タイプ
  gv_document_type_move      CONSTANT  VARCHAR2(10) := '20' ;       -- 移動
  ------------------------------
  -- クイックコード関連
  ------------------------------
  -- 運賃区分
  gv_lookup_cd_freight       CONSTANT  VARCHAR2(30)  := 'XXWSH_FREIGHT_CLASS' ;
  -- 契約外運賃区分
  gv_lookup_cd_no_freight    CONSTANT  VARCHAR2(30)  := 'XXCMN_INCLUDE_EXCLUDE' ;
  -- 確認依頼
  gv_lookup_cd_conreq        CONSTANT  VARCHAR2(30)  := 'XXWSH_LG_CONFIRM_REQ_CLASS' ;
  -- ロットステータス区分
  gv_lookup_cd_lot_status    CONSTANT  VARCHAR2(30)  := 'XXCMN_LOT_STATUS' ;
  -- 警告区分
  gv_lookup_cd_warn          CONSTANT  VARCHAR2(30)  := 'XXWSH_WARNING_CLASS' ;
  -- 引当区分
  gv_lookup_cd_reserve       CONSTANT  VARCHAR2(30)  := 'XXINV_AM_RESERVE_CLASS' ;
  -- 引当区分
  gv_lookup_cd_move_type     CONSTANT  VARCHAR2(30)  := 'XXINV_MOVE_TYPE' ;
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  ------------------------------
  -- 入力パラメータ関連
  ------------------------------
  -- 入力パラメータ格納用レコード
  TYPE rec_param_data IS RECORD(
     gyoumu_kbn            VARCHAR2(10)    -- 01:業務種別
    ,block1                VARCHAR2(10)    -- 02:ブロック1
    ,block2                VARCHAR2(10)    -- 03:ブロック2 
    ,block3                VARCHAR2(10)    -- 04:ブロック3
    ,deliver_from_code     VARCHAR2(10)    -- 05:出庫元
    ,tanto_code            VARCHAR2(50)    -- 06:担当者コード
    ,input_date_time_from  VARCHAR2(30)    -- 07:入力日時FROM
    ,input_date_time_to    VARCHAR2(30)    -- 08:入力日時TO
-- v1.12 ADD Start
    ,reserve_class         VARCHAR2(1)     -- 09:手動のみ
-- v1.12 ADD End
  );
--
  -- 帳票出力データ格納用レコード変数
  TYPE type_report_data_rec IS RECORD (
    -- 依頼No/移動No
     req_mov_no                       xxwsh_order_headers_all.request_no%TYPE
    -- 配送No
    ,delivery_no                      xxwsh_order_headers_all.delivery_no%TYPE
    -- 出庫日
    ,schedule_ship_date               xxwsh_order_headers_all.schedule_ship_date%TYPE
    -- 着日
    ,schedule_arrival_date            xxwsh_order_headers_all.schedule_arrival_date%TYPE
    -- 出庫元（コード）
    ,deliver_from_code                xxwsh_order_headers_all.deliver_from%TYPE
    -- 出庫元（名称）
    ,deliver_from_name                xxcmn_item_locations2_v.description%TYPE
    -- 配送区分
    ,shipping_method_code             xxwsh_order_headers_all.shipping_method_code%TYPE
    -- 配送区分（名称）
    ,shipping_method_name             xxwsh_ship_method2_v.ship_method_meaning%TYPE
    -- 運送業者
    ,freight_carrier_code             xxwsh_order_headers_all.freight_carrier_code%TYPE
    -- 運送業者（名称）
    ,freight_carrier_name             xxcmn_carriers2_v.party_short_name%TYPE
    -- 運賃区分
    ,freight_charge_kbn               xxcmn_lookup_values2_v.meaning%TYPE
    -- 業務種別
    ,gyoumu_shubetsu                  VARCHAR(10)
    -- 管轄拠点
    ,head_sales_branch                xxwsh_order_headers_all.head_sales_branch%TYPE
    -- 管轄拠点（名称）
    ,head_sales_branch_name           xxcmn_cust_accounts2_v.party_short_name%TYPE
    -- 出庫形態
    ,transaction_type_name            xxwsh_oe_transaction_types2_v.transaction_type_name%TYPE
    -- 混載元No
    ,mixed_no                         xxwsh_order_headers_all.mixed_no%TYPE
    -- パレット回収枚数
    ,collected_pallet_qty             xxwsh_order_headers_all.collected_pallet_qty%TYPE
    -- PO#
    ,cust_po_number                   xxwsh_order_headers_all.cust_po_number%TYPE
    -- 配送先/入庫先（コード）
    ,deliver_to_code                  xxwsh_order_headers_all.deliver_to%TYPE
    -- 配送先/入庫先（名称）
    ,deliver_to_name                  xxcmn_cust_acct_sites2_v.party_site_full_name%TYPE
    -- 契約外運賃区分
    ,keyaku_gai_freight_charge_kbn    xxcmn_lookup_values2_v.meaning%TYPE
    -- 振替先部署
    ,frkae_busho_name                 xxcmn_locations2_v.location_short_name%TYPE
    -- 確認依頼
    ,check_irai_kbn                   xxcmn_lookup_values2_v.meaning%TYPE
    -- 摘要
    ,tekiyou                          xxwsh_order_headers_all.shipping_instructions%TYPE
    -- 着荷時間FROM
    ,arrival_time_from                xxwsh_order_headers_all.arrival_time_from%TYPE
    -- 着荷時間TO
    ,arrival_time_to                  xxwsh_order_headers_all.arrival_time_to%TYPE
    -- 担当者コード
    ,tanto_code                       per_all_people_f.employee_number%TYPE
    -- 画面更新日時
    ,screen_update_date               xxwsh_order_headers_all.screen_update_date%TYPE
    -- 明細番号
    ,meisai_number                    xxwsh_order_lines_all.order_line_number%TYPE
    -- 品名（コード）
    ,item_code                        xxwsh_order_lines_all.shipping_item_code%TYPE
    -- 品名（名称）
    ,item_name                        xxcmn_item_mst2_v.item_short_name%TYPE
    -- 依頼数量
    ,request_quantity                 xxwsh_order_lines_all.based_request_quantity%TYPE
    -- 依頼数量_単位
    ,request_quantity_unit            xxcmn_item_mst2_v.conv_unit%TYPE
    -- 数量
    ,quantity                         xxwsh_order_lines_all.quantity%TYPE
    -- パレット数量
    ,pallet_quantity                  xxwsh_order_lines_all.pallet_quantity%TYPE
    -- 段数
    ,layer_quantity                   xxwsh_order_lines_all.layer_quantity%TYPE
    -- ケース数
    ,case_quantity                    xxwsh_order_lines_all.case_quantity%TYPE
    -- 製造日
    ,make_date                        ic_lots_mst.attribute1%TYPE
    -- 賞味期限
    ,shomi_kigen                      ic_lots_mst.attribute3%TYPE
    -- 固有記号
    ,koyu_kigou                       ic_lots_mst.attribute2%TYPE
    -- ロットNo
    ,lot_no                           xxinv_mov_lot_details.lot_no%TYPE
    -- 品質
    ,lot_status_name                  xxcmn_lookup_values2_v.meaning%TYPE
    -- ロット分割数量
    ,actual_quantity                  xxinv_mov_lot_details.actual_quantity%TYPE
    -- 警告
    ,warrning_name                    xxcmn_lookup_values2_v.meaning%TYPE
    -- パレット合計枚数
    ,pallet_sum_quantity              xxwsh_order_headers_all.pallet_sum_quantity%TYPE
    -- 依頼重量体積合計
    ,req_weight_volume_total          NUMBER
    -- 依頼重量体積（単位）
    ,req_weight_volume_unit           VARCHAR(10)
    -- 積載効率
    ,loading_efficiency               NUMBER
    -- 引当区分
    ,reserved_kbn                     xxcmn_lookup_values2_v.meaning%TYPE
-- 2008/07/02 A.Shiina v1.5 ADD Start
    -- 運賃区分(コード)
    ,freight_charge_code              xxcmn_lookup_values2_v.lookup_code%TYPE
    -- 強制出力区分
    ,complusion_output_kbn            xxcmn_carriers2_v.complusion_output_code%TYPE
-- 2008/07/02 A.Shiina v1.5 ADD End
-- 2008/09/25 Y.Yamamoto v1.8 ADD Start
    -- ロットID
    ,lot_id                       ic_lots_mst.lot_id%TYPE
    -- 品目区分
    ,item_class_code            xxcmn_item_categories5_v.item_class_code%TYPE
-- 2008/09/25 Y.Yamamoto v1.8 ADD End
  );
  TYPE type_report_data_tbl IS TABLE OF type_report_data_rec INDEX BY PLS_INTEGER ;
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gr_param              rec_param_data ;        -- 入力パラメータ情報
--
  -- プロファイル値取得結果格納用
  gv_weight_uom         VARCHAR2(3);            -- 出荷重量単位
  gv_capacity_uom       VARCHAR2(3);            -- 出荷容積単位
  gv_prod_kbn           VARCHAR2(1);            -- 商品区分
--
  ------------------------------
  -- ＸＭＬ用
  ------------------------------
  gt_xml_data_table         XML_DATA ;                -- ＸＭＬデータタグ表
  gl_xml_idx                NUMBER ;                  -- ＸＭＬデータタグ表のインデックス
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
--
  /**********************************************************************************
   * Function Name    : fnc_conv_xml
   * Description      : ＸＭＬタグに変換する。
   ***********************************************************************************/
  FUNCTION fnc_conv_xml
    (
      iv_name              IN        VARCHAR2   --   タグネーム
     ,iv_value             IN        VARCHAR2   --   タグデータ
     ,ic_type              IN        CHAR       --   タグタイプ
    ) RETURN VARCHAR2
  IS
    -- =====================================================
    -- 固定ローカル定数
    -- =====================================================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'fnc_conv_xml' ;   -- プログラム名
--
    -- =====================================================
    -- ユーザー宣言部
    -- =====================================================
    -- *** ローカル変数 ***
    lv_convert_data         VARCHAR2(2000) ;
--
  BEGIN
--
    --データの場合
    IF (ic_type = 'D') THEN
      lv_convert_data := '<'||iv_name||'><![CDATA['||iv_value||']]></'||iv_name||'>' ;
    ELSE
      lv_convert_data := '<'||iv_name||'>' ;
    END IF ;
--
    RETURN(lv_convert_data) ;
--
  END fnc_conv_xml ;
--
--
  /**********************************************************************************
   * Procedure Name   : prc_out_xml_data
   * Description      : ＸＭＬ出力処理
   ***********************************************************************************/
  PROCEDURE prc_out_xml_data
    (
      ov_errbuf     OUT NOCOPY VARCHAR2             --    エラー・メッセージ           --# 固定 #
     ,ov_retcode    OUT NOCOPY VARCHAR2             --    リターン・コード             --# 固定 #
     ,ov_errmsg     OUT NOCOPY VARCHAR2             --    ユーザー・エラー・メッセージ --# 固定 #
    )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_out_xml_data'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    lv_xml_string           VARCHAR2(32000) ;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ==================================================
    -- ＸＭＬ出力処理
    -- ==================================================
    -- 開始タグ出力
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<?xml version="1.0" encoding="shift_jis" ?>' ) ;
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<root>' ) ;
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<data_info>' ) ;
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<lg_chohyo_info>' ) ;
--
    <<xml_data_table>>
    FOR i IN 1 .. gt_xml_data_table.COUNT LOOP
      -- 編集したデータをタグに変換
      lv_xml_string := fnc_conv_xml
                        (
                          iv_name   => gt_xml_data_table(i).tag_name    -- タグネーム
                         ,iv_value  => gt_xml_data_table(i).tag_value   -- タグデータ
                         ,ic_type   => gt_xml_data_table(i).tag_type    -- タグタイプ
                        ) ;
      -- ＸＭＬタグ出力
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, lv_xml_string ) ;
    END LOOP xml_data_table ;
--
    -- 終了タグ出力
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '</lg_chohyo_info>' ) ;
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '</data_info>' ) ;
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '</root>' ) ;
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
  END prc_out_xml_data ;
--
--
  /**********************************************************************************
   * Procedure Name   : prc_create_zeroken_xml_data
   * Description      : 取得件数０件時ＸＭＬデータ作成
   ***********************************************************************************/
  PROCEDURE prc_create_zeroken_xml_data
    (
      ov_errbuf         OUT NOCOPY VARCHAR2          -- エラー・メッセージ           --# 固定 #
     ,ov_retcode        OUT NOCOPY VARCHAR2          -- リターン・コード             --# 固定 #
     ,ov_errmsg         OUT NOCOPY VARCHAR2          -- ユーザー・エラー・メッセージ  --# 固定 #
    )
  IS
--
    -- =====================================================
    -- 固定ローカル定数
    -- =====================================================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'prc_create_zeroken_xml_data' ; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000) ;  -- エラー・メッセージ
    lv_retcode VARCHAR2(1) ;     -- リターン・コード
    lv_errmsg  VARCHAR2(5000) ;  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- =====================================================
    -- ユーザー宣言部
    -- =====================================================
--
  BEGIN
--
    -- =====================================================
    -- 項目データ抽出・出力処理
    -- =====================================================
    -- -----------------------------------------------------
    -- Ｇ開始タグ出力
    -- -----------------------------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'g_chohyo_info' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
    -- ----------------------------
    -- メッセージ出力タグ
    -- ----------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'msg';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := xxcmn_common_pkg.get_msg( gv_application_cmn
                                                                        ,gv_msg_not_data_found ) ;
--
    -- -----------------------------------------------------
    -- 調整Ｇ開始タグ出力
    -- -----------------------------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/g_chohyo_info' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
  EXCEPTION
--
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
  END prc_create_zeroken_xml_data ;
--
--
  /**********************************************************************************
   * Procedure Name   : prc_create_xml_data
   * Description      : ＸＭＬデータ作成処理
   ***********************************************************************************/
  PROCEDURE prc_create_xml_data
    (
      it_report_data    IN  type_report_data_tbl     -- 出荷調整表情報
     ,ov_errbuf         OUT NOCOPY VARCHAR2          -- エラー・メッセージ           --# 固定 #
     ,ov_retcode        OUT NOCOPY VARCHAR2          -- リターン・コード             --# 固定 #
     ,ov_errmsg         OUT NOCOPY VARCHAR2          -- ユーザー・エラー・メッセージ  --# 固定 #
    )
  IS
--
    -- =====================================================
    -- 固定ローカル定数
    -- =====================================================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'prc_create_xml_data' ; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000) ;  -- エラー・メッセージ
    lv_retcode VARCHAR2(1) ;     -- リターン・コード
    lv_errmsg  VARCHAR2(5000) ;  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- =====================================================
    -- ユーザー宣言部
    -- =====================================================
    -- 依頼No/移動Noブレイク用変数
    lv_req_mov_no_break             VARCHAR2(20) DEFAULT '*';
    -- 品目ブレイク用変数
    lv_item_code_break              VARCHAR2(20) DEFAULT '*';
    -- 実行日付
    ld_now_date                     DATE DEFAULT SYSDATE;
    -- 依頼数量（合計）
    ln_request_quantity_total       NUMBER DEFAULT 0;
    -- 数量（合計）
    ln_quantity_total               NUMBER DEFAULT 0;
--
  BEGIN
--
    -- -----------------------------------------------------
    -- ヘッダー情報G開始タグ出力
    -- -----------------------------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'g_chohyo_info' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
    -- 【データ】帳票ID
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'report_id';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := gv_report_id ;
--
    -- 【データ】出力日付
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'exec_time';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := TO_CHAR(ld_now_date, gv_date_fmt_all);
--
    -- 【データ】担当（部署）
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'dep_busho_name';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value
      := SUBSTRB(xxcmn_common_pkg.get_user_dept(FND_GLOBAL.USER_ID), 1, 10);
--
    -- 【データ】担当（氏名）
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'dep_name';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value
      := SUBSTRB(xxcmn_common_pkg.get_user_name(FND_GLOBAL.USER_ID), 1, 14);
--
    -- 【データ】入力日時FROM
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'input_time_from';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value
      := TO_CHAR(FND_DATE.STRING_TO_DATE( gr_param.input_date_time_from
                                         ,gv_date_fmt_ymdhm)
                                         ,gv_date_fmt_ymdhm_ja);
--
    -- 【データ】入力日時TO
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'input_time_to';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value
      := TO_CHAR(FND_DATE.STRING_TO_DATE( gr_param.input_date_time_to
                                         ,gv_date_fmt_ymdhm)
                                         ,gv_date_fmt_ymdhm_ja);
--
    -- -----------------------------------------------------
    -- 明細情報LG開始タグ出力
    -- -----------------------------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_mei_info' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
    -- -----------------------------------------------------
    -- 出庫指示確認表ループ
    -- -----------------------------------------------------
    <<report_data_loop>>
    FOR l_cnt IN 1..it_report_data.COUNT LOOP
--
      -- ブレイク判定
      IF (lv_req_mov_no_break <> it_report_data(l_cnt).req_mov_no) THEN
--
        -- -----------------------------------------------------
        -- 明細情報Ｇ開始タグ出力
        -- -----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'g_mei_info' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
        -- 【データ】依頼No/移動No
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'req_mov_no';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := it_report_data(l_cnt).req_mov_no ;
--
        -- 【データ】配送No
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'delivery_no';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := it_report_data(l_cnt).delivery_no;
--
        -- 【データ】出庫日
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'schedule_ship_date';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value
          := TO_CHAR(it_report_data(l_cnt).schedule_ship_date, gv_date_fmt_ymd);
--
        -- 【データ】着日
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'schedule_arrival_date';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value
          := TO_CHAR(it_report_data(l_cnt).schedule_arrival_date, gv_date_fmt_ymd);
--
        -- 【データ】出庫元（コード）
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'deliver_from_code';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := it_report_data(l_cnt).deliver_from_code;
--
        -- 【データ】出庫元（名称）
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'deliver_from_name';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := it_report_data(l_cnt).deliver_from_name;
--
        -- 【データ】配送区分（コード）
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'shipping_method_code';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := it_report_data(l_cnt).shipping_method_code;
--
        -- 【データ】配送区分（名称）
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'shipping_method_name';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := it_report_data(l_cnt).shipping_method_name;
--
-- 2008/07/02 A.Shiina v1.5 Update Start
   -- 運賃区分もしくは、強制出力区分が「対象」のときに、運送会社情報を出力する。
   IF  (it_report_data(l_cnt).freight_charge_code   = '1')
    OR (it_report_data(l_cnt).complusion_output_kbn = '1') THEN
        -- 【データ】運送業者（コード）
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'freight_carrier_code';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := it_report_data(l_cnt).freight_carrier_code;
--
        -- 【データ】運送業者（名称）
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'freight_carrier_name';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := it_report_data(l_cnt).freight_carrier_name;
   END IF;
-- 2008/07/02 A.Shiina v1.5 Update End
--
        -- 【データ】運賃区分（名称）
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'freight_charge_kbn';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := it_report_data(l_cnt).freight_charge_kbn;
--
        -- 【データ】業務種別
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'gyoumu_shubetsu';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := it_report_data(l_cnt).gyoumu_shubetsu;
--
        -- 【データ】管轄拠点（コード）
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'head_sales_branch';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := it_report_data(l_cnt).head_sales_branch;
--
        -- 【データ】管轄拠点（名称）
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'head_sales_branch_name';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := it_report_data(l_cnt).head_sales_branch_name;
--
        -- 【データ】出庫形態
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'transaction_type_name';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := it_report_data(l_cnt).transaction_type_name;
--
        -- 【データ】混載元No
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'mixed_no';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := it_report_data(l_cnt).mixed_no;
--
        -- 【データ】パレット回収枚数
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'collected_pallet_qty';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := it_report_data(l_cnt).collected_pallet_qty;
--
        -- 【データ】PO#
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'cust_po_number';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := it_report_data(l_cnt).cust_po_number;
--
        -- 【データ】配送先/入庫先（コード）
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'haisou_nyuko_code';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := it_report_data(l_cnt).deliver_to_code;
--
        -- 【データ】配送先/入庫先（名称）
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'haisou_nyuko_name';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := it_report_data(l_cnt).deliver_to_name;
--
        -- 【データ】契約外運賃区分
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'freight_charge_kbn_gai';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value
          := it_report_data(l_cnt).keyaku_gai_freight_charge_kbn;
--
        -- 【データ】振替先部署
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'frkae_busho_name';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := it_report_data(l_cnt).frkae_busho_name ;
--
        -- 【データ】確認依頼
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'check_irai_kbn';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := it_report_data(l_cnt).check_irai_kbn;
--
        -- 【データ】摘要
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'tekiyou';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := it_report_data(l_cnt).tekiyou;
--
        -- 【データ】時間指定
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'arrival_time';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value
          :=    it_report_data(l_cnt).arrival_time_from
             || '-'
             || it_report_data(l_cnt).arrival_time_to;
--
        -- 【データ】担当者コード
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'tanto_code';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := it_report_data(l_cnt).tanto_code;
--
        -- -----------------------------------------------------
        -- 明細詳細情報Ｇ開始タグ出力
        -- -----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_dtl_info';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
        -- ブレイクキー更新
        lv_req_mov_no_break := it_report_data(l_cnt).req_mov_no;
--
      END IF;
--
      -- -----------------------------------------------------
      -- 明細詳細情報データ開始タグ出力
      -- -----------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'g_dtl_info' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
      IF (lv_item_code_break <> it_report_data(l_cnt).item_code) THEN
--
        -- 【データ】品名（コード）
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'item_code';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := it_report_data(l_cnt).item_code ;
--
        -- 【データ】品名（名称）
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'item_name';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := it_report_data(l_cnt).item_name;
--
        -- 【データ】依頼数量
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'request_quantity';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := it_report_data(l_cnt).request_quantity;
--
        -- 【データ】依頼数量単位
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'request_quantity_unit';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
--mod start 1.5
--        gt_xml_data_table(gl_xml_idx).tag_value := it_report_data(l_cnt).request_quantity_unit;
        IF (it_report_data(l_cnt).request_quantity IS NOT NULL) THEN
          gt_xml_data_table(gl_xml_idx).tag_value := it_report_data(l_cnt).request_quantity_unit;
        ELSE
          gt_xml_data_table(gl_xml_idx).tag_value := NULL;
        END IF;
--mod end 1.5
--
        IF (it_report_data(l_cnt).request_quantity = it_report_data(l_cnt).quantity) THEN
          NULL;
        ELSIF ((it_report_data(l_cnt).request_quantity IS NULL) AND
               (it_report_data(l_cnt).quantity IS NULL)) THEN
          NULL;
        ELSE
          -- 【データ】数量
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'quantity';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
          gt_xml_data_table(gl_xml_idx).tag_value := it_report_data(l_cnt).quantity;
--
          -- 【データ】数量単位
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'quantity_unit';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
--mod start 1.5
--          gt_xml_data_table(gl_xml_idx).tag_value := it_report_data(l_cnt).request_quantity_unit;
          IF (it_report_data(l_cnt).quantity IS NOT NULL) THEN
            gt_xml_data_table(gl_xml_idx).tag_value := it_report_data(l_cnt).request_quantity_unit;
          ELSE
            gt_xml_data_table(gl_xml_idx).tag_value := NULL;
          END IF;
--mod end 1.5
--
        END IF;
--
        -- 【データ】パレット枚数
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'pallet_quantity';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := it_report_data(l_cnt).pallet_quantity;
--
        -- 【データ】段数
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'layer_quantity';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := it_report_data(l_cnt).layer_quantity;
--
        -- 【データ】ケース数
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'case_quantity';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := it_report_data(l_cnt).case_quantity;
--
        -- -----------------------------------------------------
        -- 合計値算出
        -- -----------------------------------------------------
        -- 依頼数量（合計）
        ln_request_quantity_total
                      := ln_request_quantity_total + it_report_data(l_cnt).request_quantity;
        -- 数量（合計）
        ln_quantity_total
                      := ln_quantity_total + it_report_data(l_cnt).quantity;
--
        -- ブレイクキー更新
        lv_item_code_break := it_report_data(l_cnt).item_code;
--
      END IF;
--
      -- 【データ】製造日
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'make_date';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := it_report_data(l_cnt).make_date ;
--
      -- 【データ】賞味期限
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'shomi_kigen';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := it_report_data(l_cnt).shomi_kigen;
--
      -- 【データ】固有記号
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'koyu_kigou';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := it_report_data(l_cnt).koyu_kigou;
--
      -- 【データ】ロットNo
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'lot_no';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := it_report_data(l_cnt).lot_no;
--
      -- 【データ】品質
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'lot_status_name';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := it_report_data(l_cnt).lot_status_name;
--
      -- 【データ】ロット分割数量
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'actual_quantity';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := it_report_data(l_cnt).actual_quantity;
--
      -- 【データ】引当区分
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'reserved_kbn';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := it_report_data(l_cnt).reserved_kbn;
--
      -- 【データ】警告
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'warrning';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := it_report_data(l_cnt).warrning_name;
--
      -- -----------------------------------------------------
      -- 明細詳細情報データ終了タグ出力
      -- -----------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := '/g_dtl_info' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
      -- -----------------------------------------------------
      -- フッター情報タグ出力
      -- -----------------------------------------------------
      -- 最終レコードまたは、次レコードがブレイクする場合
      IF (   l_cnt = it_report_data.COUNT
          OR lv_req_mov_no_break <> it_report_data(l_cnt + 1).req_mov_no) THEN
--
        --------------------------------------------------------
        -- 明細詳細情報ＬＧ終了タグ
        --------------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_dtl_info' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
        --------------------------------------------------------
        -- フッター情報LG開始タグ
        --------------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_dtl_total_info' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
        --------------------------------------------------------
        -- フッター情報G開始タグ
        --------------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'g_dtl_total_info' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
        --------------------------------------------------------
        -- フッター情報出力
        --------------------------------------------------------
        -- 【データ】依頼数量合計（依頼No単位）
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'request_quantity_total' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := ln_request_quantity_total ;
--
        -- 【データ】数量合計（依頼No単位）
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'quantity_total' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := ln_quantity_total ;
--
        -- 【データ】パレット枚数（依頼No単位）
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'pallet_quantity_total' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := it_report_data(l_cnt).pallet_sum_quantity ;
--
        -- 【データ】依頼重量体積合計（依頼No単位）
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'req_weight_volume_total' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := it_report_data(l_cnt).req_weight_volume_total ;
--
        -- 【データ】依頼重量体積単位（依頼No単位）
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'req_weight_volume_unit' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
--mod start 1.5
--        gt_xml_data_table(gl_xml_idx).tag_value := it_report_data(l_cnt).req_weight_volume_unit ;
        IF (it_report_data(l_cnt).req_weight_volume_total IS NOT NULL) THEN
          gt_xml_data_table(gl_xml_idx).tag_value := it_report_data(l_cnt).req_weight_volume_unit ;
        ELSE
          gt_xml_data_table(gl_xml_idx).tag_value := NULL ;
        END IF;
--mod end 1.5
--
        -- 【データ】積載効率（依頼No単位）
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'loading_efficiency' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := it_report_data(l_cnt).loading_efficiency ;
--
        --------------------------------------------------------
        -- フッター情報G終了タグ
        --------------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := '/g_dtl_total_info' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
        --------------------------------------------------------
        -- フッター情報LG終了タグ
        --------------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_dtl_total_info' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
        --------------------------------------------------------
        -- 明細情報G終了タグ
        --------------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := '/g_mei_info' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
        -- -----------------------------------------------------
        -- クリア処理
        -- -----------------------------------------------------
        -- 品目ブレイクキー
        lv_item_code_break                  := '*';
        -- 依頼数量合計
        ln_request_quantity_total           := 0;
        -- 数量合計
        ln_quantity_total                   := 0;
--
      END IF;
--
    END LOOP report_data_loop;
--
    -- -----------------------------------------------------
    -- 明細情報LG終了タグ出力
    -- -----------------------------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_mei_info' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
    -- -----------------------------------------------------
    -- 帳票情報G終了タグ出力
    -- -----------------------------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/g_chohyo_info' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
  EXCEPTION
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg ;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000) ;
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
  END prc_create_xml_data ;
--
--
  /**********************************************************************************
   * Procedure Name   : prc_get_report_data
   * Description      : 帳票情報取得処理
   ***********************************************************************************/
  PROCEDURE prc_get_report_data(
      ot_report_data  OUT NOCOPY type_report_data_tbl    -- 取得レコード
     ,ov_errbuf       OUT NOCOPY VARCHAR2                -- エラー・メッセージ           --# 固定 #
     ,ov_retcode      OUT NOCOPY VARCHAR2                -- リターン・コード             --# 固定 #
     ,ov_errmsg       OUT NOCOPY VARCHAR2                -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_get_report_data'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- =====================================================
    -- ユーザー宣言部
    -- =====================================================
    lv_select          VARCHAR2(32000) DEFAULT NULL;
    lv_ship_select     VARCHAR2(32000) DEFAULT NULL;
    lv_ship_from       VARCHAR2(32000) DEFAULT NULL;
    lv_ship_where      VARCHAR2(32000) DEFAULT NULL;
    lv_move_select     VARCHAR2(32000) DEFAULT NULL;
    lv_move_from       VARCHAR2(32000) DEFAULT NULL;
    lv_move_where      VARCHAR2(32000) DEFAULT NULL;
    lv_order_by        VARCHAR2(32000) DEFAULT NULL;
    lv_sql             VARCHAR2(32000) DEFAULT NULL;
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
    -- SQL文生成
    -- ====================================================
    -- ----------------------------------------------------
    -- SELECT句生成
    -- ----------------------------------------------------
    lv_select := ' SELECT '
    || '  req_mov_no '                      -- 依頼No/移動No
    || ' ,delivery_no '                     -- 配送No
    || ' ,schedule_ship_date '              -- 出庫日
    || ' ,schedule_arrival_date '           -- 着日
    || ' ,deliver_from_code '               -- 出庫元（コード）
    || ' ,deliver_from_name '               -- 出庫元（名称）
    || ' ,shipping_method_code '            -- 配送区分
    || ' ,shipping_method_name '            -- 配送区分（名称）
    || ' ,freight_carrier_code '            -- 運送業者
    || ' ,freight_carrier_name '            -- 運送業者（名称）
    || ' ,freight_charge_kbn '              -- 運賃区分
    || ' ,gyoumu_shubetsu '                 -- 業務種別
    || ' ,head_sales_branch '               -- 管轄拠点
    || ' ,head_sales_branch_name '          -- 管轄拠点（名称）
    || ' ,transaction_type_name '           -- 出庫形態
    || ' ,mixed_no '                        -- 混載元No
    || ' ,collected_pallet_qty '            -- パレット回収枚数
    || ' ,cust_po_number '                  -- PO#
    || ' ,deliver_to_code '                 -- 配送先/入庫先（コード）
    || ' ,deliver_to_name '                 -- 配送先/入庫先（名称）
    || ' ,keyaku_gai_freight_charge_kbn '   -- 契約外運賃区分
    || ' ,frkae_busho_name '                -- 振替先部署
    || ' ,check_irai_kbn '                  -- 確認依頼
    || ' ,tekiyou '                         -- 摘要
    || ' ,arrival_time_from '               -- 着荷時間FROM
    || ' ,arrival_time_to '                 -- 着荷時間TO
    || ' ,tanto_code '                      -- 担当者コード
    || ' ,screen_update_date '              -- 画面更新日時
    || ' ,meisai_number '                   -- 明細番号
    || ' ,item_code '                       -- 品名（コード）
    || ' ,item_name '                       -- 品名（名称）
    || ' ,request_quantity '                -- 依頼数量
    || ' ,request_quantity_unit '           -- 依頼数量_単位
    || ' ,quantity '                        -- 数量
    || ' ,pallet_quantity '                 -- パレット数量
    || ' ,layer_quantity '                  -- 段数
    || ' ,case_quantity '                   -- ケース数
    || ' ,make_date '                       -- 製造日
    || ' ,shomi_kigen '                     -- 賞味期限
    || ' ,koyu_kigou '                      -- 固有記号
    || ' ,lot_no '                          -- ロットNo
    || ' ,lot_status_name '                 -- 品質
    || ' ,actual_quantity '                 -- ロット分割数量
    || ' ,warrning_name '                   -- 警告
    || ' ,pallet_sum_quantity '             -- パレット合計枚数
    || ' ,req_weight_volume_total '         -- 依頼重量体積合計
    || ' ,req_weight_volume_unit '          -- 依頼重量体積（単位）
    || ' ,loading_efficiency '              -- 積載効率
    || ' ,reserved_kbn '                    -- 引当区分
-- 2008/07/02 A.Shiina v1.5 ADD Start
    || ' ,freight_charge_code '             -- 運賃区分(コード)
    || ' ,complusion_output_kbn '           -- 強制出力区分
-- 2008/07/02 A.Shiina v1.5 ADD End
-- 2008/09/25 Y.Yamamoto v1.8 ADD Start
    || ' ,lot_id '                          -- ロットID
    || ' ,item_class_code '                 -- 品目区分
-- 2008/09/25 Y.Yamamoto v1.8 ADD End
    ;
--
    IF ( gr_param.gyoumu_kbn = gv_biz_type_cd_ship OR gr_param.gyoumu_kbn IS NULL ) THEN
      -- ================================================================================
      -- 【出荷】SELECT句生成
      -- ================================================================================
      lv_ship_select := ' SELECT '
      || '  xoha.request_no                  AS  req_mov_no'              -- 依頼No/移動No
      || ' ,xoha.delivery_no                 AS  delivery_no'             -- 配送No
      || ' ,xoha.schedule_ship_date          AS  schedule_ship_date'      -- 出庫日
      || ' ,xoha.schedule_arrival_date       AS  schedule_arrival_date'   -- 着日
      || ' ,xoha.deliver_from                AS  deliver_from_code'       -- 出庫元（コード）
      || ' ,xil2v.description                AS  deliver_from_name'       -- 出庫元（名称）
      || ' ,xoha.shipping_method_code        AS  shipping_method_code'    -- 配送区分
      || ' ,xsm2v.ship_method_meaning        AS  shipping_method_name'    -- 配送区分（名称）
      || ' ,xoha.freight_carrier_code        AS  freight_carrier_code'    -- 運送業者
      || ' ,xc2v.party_short_name            AS  freight_carrier_name'    -- 運送業者（名称）
      || ' ,xlv2v1.meaning                   AS  freight_charge_kbn'      -- 運賃区分
      || ' ,''' || gv_biz_type_nm_ship || '''AS  gyoumu_shubetsu'         -- 業務種別
      || ' ,xoha.head_sales_branch           AS  head_sales_branch'       -- 管轄拠点
      || ' ,xca2v.party_short_name           AS  head_sales_branch_name'  -- 管轄拠点（名称）
      || ' ,xott2v.transaction_type_name     AS  transaction_type_name'   -- 出庫形態
      || ' ,xoha.mixed_no                    AS  mixed_no'                -- 混載元No
      || ' ,xoha.collected_pallet_qty        AS  collected_pallet_qty'    -- パレット回収枚数
      || ' ,xoha.cust_po_number              AS  cust_po_number'          -- PO#
      || ' ,xoha.deliver_to                  AS  deliver_to_code'         -- 配送先/入庫先(コード)
      || ' ,xcas2v.party_site_full_name      AS  deliver_to_name'         -- 配送先/入庫先（名称）
      || ' ,xlv2v2.meaning                   AS  keyaku_gai_freight_charge_kbn'   -- 契約外運賃区分
      || ' ,CASE'
      || '    WHEN xoha.no_cont_freight_class = ''' || gv_no_cont_freight_kbn_obj || ''' THEN'
      || '      xl2v.location_short_name'
      || '    ELSE'
      || '      NULL'
      || '    END                            AS  frkae_busho_name'        -- 振替先部署
      || ' ,xlv2v3.meaning                   AS  check_irai_kbn'          -- 確認依頼
      || ' ,xoha.shipping_instructions       AS  tekiyou'                 -- 摘要
      || ' ,xoha.arrival_time_from           AS  arrival_time_from'       -- 着荷時間FROM
      || ' ,xoha.arrival_time_to             AS  arrival_time_to'         -- 着荷時間TO
      || ' ,papf.employee_number             AS  tanto_code'              -- 担当者コード
      || ' ,xoha.screen_update_date          AS  screen_update_date'      -- 画面更新日時
      || ' ,xola.order_line_number           AS  meisai_number'           -- 明細番号
      || ' ,xola.shipping_item_code          AS  item_code'               -- 品名（コード）
      || ' ,xim2v.item_short_name            AS  item_name'               -- 品名（名称）
      || ' ,CASE'
      || '    WHEN  ( ( xic4v.item_class_code = ''' || gv_item_cd_prdct || ''' )'
      || '    AND     ( xim2v.conv_unit IS NOT NULL  ) ) THEN'
      || '      TRUNC(xola.based_request_quantity / TO_NUMBER('
      || '                                        CASE'
      || '                                          WHEN ( xim2v.num_of_cases > 0 ) THEN'
      || '                                            xim2v.num_of_cases'
      || '                                          ELSE'
      || '                                            TO_CHAR(1)'
      || '                                        END'
      || '                                      ), 3)'
      || '    ELSE'
      || '      xola.based_request_quantity'
      || '    END                              AS  request_quantity'      -- 依頼数量
      || ' ,CASE'
      || '    WHEN  ( ( xic4v.item_class_code = ''' || gv_item_cd_prdct || ''' )'
      || '    AND     ( xim2v.conv_unit IS NOT NULL  ) ) THEN'
      || '      xim2v.conv_unit'
      || '    ELSE'
      || '      xim2v.item_um'
      || '    END                            AS  request_quantity_unit'   -- 依頼数量_単位
      || ' ,CASE'
      || '    WHEN  ( ( xic4v.item_class_code = ''' || gv_item_cd_prdct || ''' )'
      || '    AND     ( xim2v.conv_unit IS NOT NULL  ) ) THEN'
      || '      TRUNC(xola.quantity / TO_NUMBER('
      || '                                        CASE'
      || '                                          WHEN ( xim2v.num_of_cases > 0 ) THEN'
      || '                                            xim2v.num_of_cases'
      || '                                          ELSE'
      || '                                            TO_CHAR(1)'
      || '                                        END'
      || '                                      ), 3)'
      || '    ELSE'
      || '      xola.quantity'
      || '    END                            AS  quantity'                 -- 数量
      || ' ,xola.pallet_quantity             AS  pallet_quantity'          -- パレット数量
      || ' ,xola.layer_quantity              AS  layer_quantity'           -- 段数
      || ' ,xola.case_quantity               AS  case_quantity'            -- ケース数
      || ' ,CASE'
      || '    WHEN ((xmld.automanual_reserve_class = ''' || gv_auto_manual_kbn_a || ''' )'
      || '    AND   (xmld.lot_no IS NULL)                 ) THEN'
      || '      TO_CHAR(xola.designated_production_date, ''' || gv_date_fmt_ymd || ''')'
      || '    ELSE'
      || '      ilm.attribute1'
      || '    END                            AS  make_date'               -- 製造日
      || ' ,CASE'
      || '    WHEN ((xmld.automanual_reserve_class = ''' || gv_auto_manual_kbn_a || ''' )'
      || '    AND   (xmld.lot_no IS NULL)                 ) THEN'
      || '      NULL'
      || '    ELSE'
      || '      ilm.attribute3'
      || '    END                            AS  shomi_kigen'             -- 賞味期限
      || ' ,CASE'
      || '    WHEN ((xmld.automanual_reserve_class = ''' || gv_auto_manual_kbn_a || ''' )'
      || '    AND   (xmld.lot_no IS NULL)                 ) THEN'
      || '      NULL'
      || '    ELSE'
      || '      ilm.attribute2'
      || '    END                            AS  koyu_kigou'              -- 固有記号
      || ' ,CASE'
      || '    WHEN ((xmld.automanual_reserve_class = ''' || gv_auto_manual_kbn_a || ''' )'
      || '    AND   (xmld.lot_no IS NULL)                 ) THEN'
      || '      NULL'
      || '    ELSE'
      || '      xmld.lot_no'
      || '    END                            AS  lot_no'                  -- ロットNo
      || ' ,xlv2v4.meaning                   AS  lot_status_name'         -- 品質
      || ' ,CASE'
              -- 引当されている場合
      || '    WHEN ( xola.reserved_quantity > 0 ) THEN'
      || '      CASE'
      || '        WHEN  ( ( xic4v.item_class_code = ''' || gv_item_cd_prdct || ''' )'
      || '        AND     ( xim2v.conv_unit IS NOT NULL  ) ) THEN'
      || '          TRUNC(xmld.actual_quantity / TO_NUMBER('
      || '                                            CASE'
      || '                                              WHEN ( xim2v.num_of_cases > 0 ) THEN'
      || '                                                xim2v.num_of_cases'
      || '                                              ELSE'
      || '                                                TO_CHAR(1)'
      || '                                            END'
      || '                                          ), 3)'
      || '        ELSE'
      || '          xmld.actual_quantity'
      || '        END'
              -- 引当されていない場合
      || '    WHEN  ( ( xola.reserved_quantity IS NULL ) OR ( xola.reserved_quantity = 0 ) ) THEN'
      || '      NULL'
      || '    END                            AS  actual_quantity'         -- ロット分割数量
      || ' ,xlv2v5.meaning                   AS  warrning_name'           -- 警告
      || ' ,xoha.pallet_sum_quantity         AS  pallet_sum_quantity'     -- パレット合計枚数
      || ' ,CASE'
      || '    WHEN xsm2v.small_amount_class = ''' || gv_small_kbn_obj || ''' THEN'
      || '      CASE'
      || '        WHEN xoha.weight_capacity_class = ''' || gv_wei_cap_kbn_w || ''''
-- 2008/08/05 Y.Yamamoto v1.7 Update Start
--      || '        THEN xoha.sum_weight'
      || '        THEN CEIL(TRUNC(xoha.sum_weight,1))'
-- 2008/08/05 Y.Yamamoto v1.7 Update End
      || '        WHEN xoha.weight_capacity_class = ''' || gv_wei_cap_kbn_c || ''''
-- 2008/08/05 Y.Yamamoto v1.7 Update Start
--      || '        THEN xoha.sum_capacity'
      || '        THEN CEIL(TRUNC(xoha.sum_capacity,1))'
-- 2008/08/05 Y.Yamamoto v1.7 Update End
      || '      END'
      || '    WHEN xsm2v.small_amount_class = ''' || gv_small_kbn_not_obj || ''' THEN'
      || '      CASE'
      || '        WHEN xoha.weight_capacity_class = ''' || gv_wei_cap_kbn_w || ''' THEN'
-- 2008/08/05 Y.Yamamoto v1.7 Update Start
--      || '          xoha.sum_pallet_weight + xoha.sum_weight'
      || '          CEIL(TRUNC(xoha.sum_pallet_weight + xoha.sum_weight,1))'
-- 2008/08/05 Y.Yamamoto v1.7 Update End
      || '        WHEN xoha.weight_capacity_class = ''' || gv_wei_cap_kbn_c || ''' THEN'
-- 2008/08/05 Y.Yamamoto v1.7 Update Start
--      || '          xoha.sum_pallet_weight + xoha.sum_capacity'
      || '          CEIL(TRUNC(xoha.sum_pallet_weight + xoha.sum_capacity,1))'
-- 2008/08/05 Y.Yamamoto v1.7 Update End
      || '      END'
      || '    WHEN xsm2v.small_amount_class IS NULL THEN'
      || '      NULL '
      || '    END                            AS  req_weight_volume_total' -- 依頼重量体積（合計）
      || ' ,CASE'
      || '    WHEN xoha.weight_capacity_class = ''' || gv_wei_cap_kbn_w || ''''
      || '    THEN ''' || gv_weight_uom || ''''
      || '    WHEN xoha.weight_capacity_class = ''' || gv_wei_cap_kbn_c || ''''
      || '    THEN ''' || gv_capacity_uom || ''''
      || '    END                            AS  req_weight_volume_unit'  -- 依頼重量体積（単位）
      || ' ,CASE'
      || '    WHEN xoha.weight_capacity_class = ''' || gv_wei_cap_kbn_w || ''''
      || '    THEN xoha.loading_efficiency_weight'
      || '    WHEN xoha.weight_capacity_class = ''' || gv_wei_cap_kbn_c || ''''
      || '    THEN xoha.loading_efficiency_capacity'
      || '    END                            AS  loading_efficiency'      -- 積載効率
      || ' ,xlv2v6.attribute1                AS  reserved_kbn'            -- 引当区分
-- 2008/07/02 A.Shiina v1.5 ADD Start
      || ' ,xlv2v1.lookup_code               AS  freight_charge_code'     -- 運賃区分(コード)
      || ' ,xc2v.complusion_output_code      AS  complusion_output_kbn'   -- 強制出力区分
-- 2008/07/02 A.Shiina v1.5 ADD End
-- 2008/09/25 Y.Yamamoto v1.8 ADD Start
      || ' ,NVL(ilm.lot_id, 0)               AS  lot_id '                 -- ロットID
      || ' ,xic4v.item_class_code            AS  item_class_code'         -- 品目区分
-- 2008/09/25 Y.Yamamoto v1.8 ADD End
      ;
--
      -- ================================================================================
      -- 【出荷】FROM句生成
      -- ================================================================================
      lv_ship_from := ' FROM '
      || '  xxwsh_order_headers_all           xoha'       -- 受注ヘッダアドオン
      || ' ,xxwsh_oe_transaction_types2_v     xott2v'     -- 受注タイプ情報VIEW2
      || ' ,xxcmn_item_locations2_v           xil2v'      -- OPM保管場所情報VIEW2
      || ' ,xxcmn_carriers2_v                 xc2v'       -- 運送業者情報VIEW2
      || ' ,xxcmn_cust_accounts2_v            xca2v'      -- 顧客情報VIEW2
      || ' ,xxcmn_cust_acct_sites2_v          xcas2v'     -- 顧客サイト情報VIEW2
      || ' ,fnd_user                          fu'         -- ユーザーマスタ
      || ' ,per_all_people_f                  papf'       -- 従業員マスタ
      || ' ,xxcmn_locations2_v                xl2v'       -- 事業所情報VIEW2
      || ' ,xxwsh_order_lines_all             xola'       -- 受注明細アドオン
      || ' ,xxcmn_item_mst2_v                 xim2v'      -- OPM品目情報VIEW2
-- 2008/08/05 Y.Yamamoto v1.7 Update Start
--      || ' ,xxcmn_item_categories4_v          xic4v'      -- OPM品目カテゴリ割当情報VIEW4
      || ' ,xxcmn_item_categories5_v          xic4v'      -- OPM品目カテゴリ割当情報VIEW5
-- 2008/08/05 Y.Yamamoto v1.7 Update End
      || ' ,xxinv_mov_lot_details             xmld'       -- 移動ロット詳細(アドオン)
      || ' ,ic_lots_mst                       ilm'        -- OPMロットマスタ
      || ' ,xxwsh_ship_method2_v              xsm2v'      -- 配送区分情報VIEW2
      || ' ,xxcmn_lookup_values2_v            xlv2v1'     -- クイックコード(運賃区分)
      || ' ,xxcmn_lookup_values2_v            xlv2v2'     -- クイックコード(契約外運賃区分)
      || ' ,xxcmn_lookup_values2_v            xlv2v3'     -- クイックコード(物流担当確認依頼区分)
      || ' ,xxcmn_lookup_values2_v            xlv2v4'     -- クイックコード(ロットステータス)
      || ' ,xxcmn_lookup_values2_v            xlv2v5'     -- クイックコード(警告区分)
      || ' ,xxcmn_lookup_values2_v            xlv2v6'     -- クイックコード(引当区分)
      ;
--
      -- ================================================================================
      -- 【出荷】WHERE句生成
      -- ================================================================================
      lv_ship_where := ' WHERE '
           -------------------------------------------------------------------------------
           -- 受注ヘッダアドオン
           -------------------------------------------------------------------------------
      || '     xoha.req_status                   >= ''' || gv_ship_status_close || '''' -- 締め済み
      || ' AND xoha.req_status                   <> ''' || gv_ship_status_delete || ''''-- 取消
      || ' AND   xoha.latest_external_flag = ''Y'''
-- 2008/11/14 N.Fukuda v1.9 Add Start
      || ' AND   xoha.schedule_ship_date IS NOT NULL'
-- 2008/11/14 N.Fukuda v1.9 Add End
           -------------------------------------------------------------------------------
           -- 受注タイプ情報VIEW2
           -------------------------------------------------------------------------------
      || ' AND   xoha.order_type_id               = xott2v.transaction_type_id'
      || ' AND   xott2v.shipping_shikyu_class     = ''' || gv_ship_pro_kbn_s || '''' --'出荷依頼'
      || ' AND   xott2v.order_category_code      <> ''' || gv_order_cate_ret || '''' -- 返品
      || ' AND   xott2v.start_date_active        <=  xoha.schedule_ship_date'
      || ' AND   ('
      || '         xott2v.end_date_active        >=  xoha.schedule_ship_date'
      || '       OR'
      || '         xott2v.end_date_active IS NULL'
      || '       )'
           -------------------------------------------------------------------------------
           -- OPM保管場所情報VIEW2
           -------------------------------------------------------------------------------
      || ' AND   xoha.deliver_from_id               =   xil2v.inventory_location_id'
           -------------------------------------------------------------------------------
           -- 運送業者情報VIEW2
           -------------------------------------------------------------------------------
      || ' AND   xoha.career_id                     =   xc2v.party_id(+)'
      || ' AND   ('
      || '         xc2v.start_date_active IS NULL'
      || '       OR'
      || '         xc2v.start_date_active          <=  xoha.schedule_ship_date'
      || '       )'
      || ' AND   ('
      || '         xc2v.end_date_active IS NULL'
      || '       OR'
      || '         xc2v.end_date_active            >=  xoha.schedule_ship_date'
      || '       )'
           -------------------------------------------------------------------------------
           -- 顧客情報VIEW2
           -------------------------------------------------------------------------------
      || ' AND   xoha.head_sales_branch              =   xca2v.party_number'
      || ' AND   xca2v.start_date_active            <=  xoha.schedule_ship_date'
      || ' AND   ('
      || '         xca2v.end_date_active            >=  xoha.schedule_ship_date'
      || '       OR'
      || '         xca2v.end_date_active IS NULL'
      || '       )'
           -------------------------------------------------------------------------------
           -- 顧客サイト情報VIEW2
           -------------------------------------------------------------------------------
-- 2009/05/28 H.Itou Mod Start 本番障害#1398
--      || ' AND   xoha.deliver_to_id                  =   xcas2v.party_site_id'
      || ' AND   xoha.deliver_to                     =   xcas2v.party_site_number'
-- 2009/05/28 H.Itou Mod End
-- 2009/05/28 H.Itou Add Start 本番障害#1398
      || ' AND   xcas2v.party_site_status            = ''A'' '  -- 有効な出荷先
      || ' AND   xcas2v.cust_acct_site_status        = ''A'' '  -- 有効な出荷先
-- 2009/05/28 H.Itou Add End
      || ' AND   xcas2v.start_date_active           <=  xoha.schedule_ship_date'
      || ' AND   ('
      || '         xcas2v.end_date_active           >=  xoha.schedule_ship_date'
      || '       OR'
      || '         xcas2v.end_date_active IS NULL'
      || '       )'
           -------------------------------------------------------------------------------
           -- ユーザ情報
           -------------------------------------------------------------------------------
      || ' AND   xoha.screen_update_by = fu.user_id'
      || ' AND   fu.employee_id = papf.person_id'
-- 2009/09/14 H.Itou Add Start 本番障害#1632
      || ' AND   xoha.schedule_ship_date BETWEEN papf.effective_start_date '
      || '                               AND     NVL(papf.effective_end_date,xoha.schedule_ship_date) '
-- 2009/09/14 H.Itou Add End
           -------------------------------------------------------------------------------
           -- 事業所情報VIEW2
           -------------------------------------------------------------------------------
--mod start 1.3
--      || ' AND   xoha.transfer_location_id          = xl2v.location_id'
--      || ' AND   xl2v.start_date_active            <=  xoha.schedule_ship_date'
--      || '     AND   ('
--      || '         xl2v.end_date_active            >=  xoha.schedule_ship_date'
--      || '       OR'
--      || '         xl2v.end_date_active IS NULL'
--      || '       )'
      || ' AND   xoha.transfer_location_id          = xl2v.location_id(+)'
      || ' AND   xoha.schedule_ship_date'
      || '   BETWEEN xl2v.start_date_active(+)'
      || '   AND NVL(xl2v.end_date_active(+),xoha.schedule_ship_date)'
--mod end 1.3
           -------------------------------------------------------------------------------
           -- 受注明細アドオン
           -------------------------------------------------------------------------------
      || ' AND   xoha.order_header_id               =   xola.order_header_id'
      || ' AND   (  xola.delete_flag IS NULL'
      || '       OR'
      || '          xola.delete_flag               <>  ''Y'''
      || '       )'
-- 2008/08/05 Y.Yamamoto v1.7 ADD Start
--      || ' AND   xola.quantity                      >   0'     -- 2008/11/14 N.Fukuda v1.9 Del
-- 2008/08/05 Y.Yamamoto v1.7 ADD End
           -------------------------------------------------------------------------------
           -- OPM品目情報VIEW2
           -------------------------------------------------------------------------------
      || ' AND   xola.shipping_inventory_item_id    =   xim2v.inventory_item_id'
      || ' AND   xim2v.start_date_active   <=  xoha.schedule_ship_date'
      || ' AND   ('
      || '         xim2v.end_date_active IS NULL'
      || '       OR'
      || '         xim2v.end_date_active    >=  xoha.schedule_ship_date'
      || '       )'
           -------------------------------------------------------------------------------
           -- OPM品目カテゴリ割当情報VIEW4
           -------------------------------------------------------------------------------
      || ' AND   xim2v.item_id               =   xic4v.item_id'
      || ' AND   xic4v.prod_class_code       =   ''' || gv_prod_kbn || ''''
           -------------------------------------------------------------------------------
           -- 移動ロット詳細(アドオン)
           -------------------------------------------------------------------------------
      || ' AND   xola.order_line_id          = xmld.mov_line_id(+)'
      || ' AND   xmld.document_type_code(+)  = ''' || gv_document_type_ship_req || ''''-- 出荷依頼
      || ' AND   xmld.record_type_code(+)    = ''' || record_type_siji || ''''         -- 指示
           -------------------------------------------------------------------------------
           -- OPMロットマスタ
           -------------------------------------------------------------------------------
      || ' AND   xmld.lot_id                        =   ilm.lot_id(+)'
      || ' AND   xmld.item_id                       =   ilm.item_id(+)'
           -------------------------------------------------------------------------------
           -- 配送区分情報VIEW2
           -------------------------------------------------------------------------------
      || ' AND xoha.shipping_method_code            = xsm2v.ship_method_code(+)'
           -------------------------------------------------------------------------------
           -- クイックコード（運賃区分）-- 1:対象、2:対象外
           -------------------------------------------------------------------------------
      || ' AND xlv2v1.lookup_type                   = ''' || gv_lookup_cd_freight || ''''
      || ' AND xoha.freight_charge_class            = xlv2v1.lookup_code'
           -------------------------------------------------------------------------------
           -- クイックコード（契約外運賃区分）-- 1:対象、0:対象外
           -------------------------------------------------------------------------------
      || ' AND xlv2v2.lookup_type                   = ''' || gv_lookup_cd_no_freight || ''''
      || ' AND xoha.no_cont_freight_class           = xlv2v2.lookup_code'
           -------------------------------------------------------------------------------
           -- クイックコード（物流担当確認依頼区分）-- 1:要、2:不要
           -------------------------------------------------------------------------------
      || ' AND xlv2v3.lookup_type                   = ''' || gv_lookup_cd_conreq || ''''
      || ' AND xoha.confirm_request_class           = xlv2v3.lookup_code'
           -------------------------------------------------------------------------------
           -- クイックコード（ﾛｯﾄｽﾃｰﾀｽ）-- 10:未判定、30:条件付良品、50:合格、60:不合格、70:保留
           -------------------------------------------------------------------------------
      || ' AND xlv2v4.lookup_type(+)                = ''' || gv_lookup_cd_lot_status || ''''
      || ' AND ilm.attribute23                      = xlv2v4.lookup_code(+)'
           -------------------------------------------------------------------------------
           -- クイックコード（警告区分）
           -------------------------------------------------------------------------------
      --MOD START 2008/06/04 NAKADA
      || ' AND xlv2v5.lookup_type(+)               = ''' || gv_lookup_cd_warn || ''''
      || ' AND xola.warning_class                  = xlv2v5.lookup_code(+)'
      --MOD END   2008/06/04 NAKADA
           -------------------------------------------------------------------------------
           -- クイックコード（引当区分）
           -------------------------------------------------------------------------------
      || ' AND xlv2v6.lookup_type(+)               = ''' || gv_lookup_cd_reserve || ''''
      || ' AND xmld.automanual_reserve_class       = xlv2v6.lookup_code(+)'
      ;
--
      -- 入力パラメータによる条件
           -------------------------------------------------------------------------------
           -- 受注ヘッダアドオン
           -------------------------------------------------------------------------------
      IF (  gr_param.block1 IS NOT NULL
         OR gr_param.block2 IS NOT NULL
         OR gr_param.block3 IS NOT NULL
         OR gr_param.deliver_from_code IS NOT NULL ) THEN
        lv_ship_where := lv_ship_where
        || ' AND ('
        || '         xil2v.distribution_block IN ('
        || '                                      ''' || gr_param.block1 || ''''
        || '                                     ,''' || gr_param.block2 || ''''
        || '                                     ,''' || gr_param.block3 || ''''
        || '                                     )'                               -- 入力P.ブロック
        || '       OR'
        || '         xoha.deliver_from = ''' || gr_param.deliver_from_code || ''''-- 入力P.出庫元'
        || '       )'
        ;
      END IF;
--
      IF (   gr_param.input_date_time_from IS NOT NULL
         AND gr_param.input_date_time_to IS NOT NULL ) THEN
        lv_ship_where := lv_ship_where
        || ' AND   ('
        || '         TRUNC( xoha.screen_update_date, ''' || gv_date_fmt_mi || ''' ) '
        || '           >= FND_DATE.STRING_TO_DATE( ''' || gr_param.input_date_time_from || ''''
        || '                                      ,''' || gv_date_fmt_ymdhm || ''' ) '
        || '       AND'
        || '         TRUNC( xoha.screen_update_date, ''' || gv_date_fmt_mi || ''' ) '
        || '           <= FND_DATE.STRING_TO_DATE( ''' || gr_param.input_date_time_to || ''''
        || '                                      ,''' || gv_date_fmt_ymdhm || ''' ) '
        || '       )'
        ;
      END IF;
--
           -------------------------------------------------------------------------------
           -- ユーザ情報
           -------------------------------------------------------------------------------
      IF ( gr_param.tanto_code IS NOT NULL ) THEN
        lv_ship_where := lv_ship_where
        || ' AND papf.employee_number         = ''' || gr_param.tanto_code || ''''
        ;
      END IF;
-- v1.12 ADD Start
      -- パラメータ「手動のみ」が'Y'の場合、自動手動引当区分が「手動」のみ
      IF ( gr_param.reserve_class = gv_reserve_class_y ) THEN
        lv_ship_where := lv_ship_where
        || ' AND xmld.automanual_reserve_class = ''' || gv_auto_manual_kbn_m || ''''
        ;
      END IF;
-- v1.12 ADD End
--
    END IF;
--
    IF ( gr_param.gyoumu_kbn = gv_biz_type_cd_move OR gr_param.gyoumu_kbn IS NULL ) THEN
      -- ================================================================================
      -- 【移動】SELECT句生成
      -- ================================================================================
      lv_move_select := ' SELECT '
      || '  xmrih.mov_num                         AS  req_mov_no'              -- 依頼No/移動No
      || ' ,xmrih.delivery_no                     AS  delivery_no'             -- 配送No
      || ' ,xmrih.schedule_ship_date              AS  schedule_ship_date'      -- 出庫日
      || ' ,xmrih.schedule_arrival_date           AS  schedule_arrival_date'   -- 着日
      || ' ,xmrih.shipped_locat_code              AS  deliver_from_code'       -- 出庫元（コード）
      || ' ,xil2v1.description                    AS  deliver_from_name'       -- 出庫元（名称）
      || ' ,xmrih.shipping_method_code            AS  shipping_method_code'    -- 配送区分(コード)
      || ' ,xsm2v.ship_method_meaning             AS  shipping_method_name'    -- 配送区分（名称）
      || ' ,xmrih.freight_carrier_code            AS  freight_carrier_code'    -- 運送業者(コード)
      || ' ,xc2v.party_short_name                 AS  freight_carrier_name'    -- 運送業者（名称）
      || ' ,xlv2v1.meaning                        AS  freight_charge_kbn'      -- 運賃区分（名称）
      || ' ,''' || gv_biz_type_nm_move || '''     AS  gyoumu_shubetsu'         -- 業務種別
      || ' ,NULL                                  AS  head_sales_branch'       -- 管轄拠点(コード)
      || ' ,NULL                                  AS  head_sales_branch_name'  -- 管轄拠点（名称）
      || ' ,xlv2v2.meaning                        AS  transaction_type_name'   -- 出庫形態
      || ' ,NULL                                  AS  mixed_no'                -- 混載元No
      || ' ,xmrih.collected_pallet_qty            AS  collected_pallet_qty'    -- パレット回収枚数
      || ' ,NULL                                  AS  cust_po_number'          -- PO#
      || ' ,xmrih.ship_to_locat_code              AS  deliver_to_code'   -- 配送先/入庫先（コード）
      || ' ,xil2v2.description                    AS  deliver_to_name'   -- 配送先/入庫先（名称）
      || ' ,CASE'
      || '    WHEN (xmrih.no_cont_freight_class = ''' || gv_no_cont_freight_kbn_obj || ''' ) THEN'
      || '      xlv2v3.meaning'
      || '    ELSE'
      || '      NULL'
      || '    END                               AS  keyaku_gai_freight_charge_kbn'-- 契約外運賃区分
      || ' ,NULL                                  AS  frkae_busho_name'        -- 振替先部署
      || ' ,NULL                                  AS  check_irai_kbn'          -- 確認依頼
      || ' ,xmrih.description                     AS  tekiyou'                 -- 摘要
      || ' ,xmrih.arrival_time_from               AS  arrival_time_from'       -- 着荷時間FROM
      || ' ,xmrih.arrival_time_to                 AS  arrival_time_to'         -- 着荷時間TO
      || ' ,papf.employee_number                  AS  tanto_code'              -- 担当者コード
      || ' ,xmrih.screen_update_date              AS  screen_update_date'      -- 画面更新日時
      || ' ,xmril.line_number                     AS  meisai_number'           -- 明細番号
      || ' ,xmril.item_code                       AS  item_code'               -- 品名（コード）
      || ' ,xim2v.item_short_name                 AS  item_name'               -- 品名（略称）
      || ' ,CASE'
      || '    WHEN  (   ( xic4v.item_class_code = ''' || gv_item_cd_prdct || ''' )'
      || '          AND ( xic4v.prod_class_code  = ''' || gv_prod_cd_drink || ''' )'
      || '          AND     ( xim2v.conv_unit IS NOT NULL  ) ) THEN'
-- 2008/09/25 Y.Yamamoto v1.8 Update Start
--      || '      TRUNC(xmril.request_qty / TO_NUMBER('
      || '      TRUNC(xmril.first_instruct_qty / TO_NUMBER('
-- 2008/09/25 Y.Yamamoto v1.8 Update End
      || '                                        CASE'
      || '                                          WHEN ( xim2v.num_of_cases > 0 ) THEN'
      || '                                            xim2v.num_of_cases'
      || '                                          ELSE'
      || '                                            TO_CHAR(1)'
      || '                                        END'
      || '                                      ), 3)'
      || '    ELSE'
-- 2008/09/29 Y.Yamamoto v1.8 Update Start
--      || '      xmril.request_qty'
      || '      xmril.first_instruct_qty'
-- 2008/09/29 Y.Yamamoto v1.8 Update End
      || '    END                                 AS  request_quantity'        -- 依頼数量
      || ' ,CASE'
      || '    WHEN  (   ( xic4v.item_class_code = ''' || gv_item_cd_prdct || ''' )'
      || '          AND ( xic4v.prod_class_code  = ''' || gv_prod_cd_drink || ''' )'
      || '          AND     ( xim2v.conv_unit IS NOT NULL  ) ) THEN'
      || '      xim2v.conv_unit'
      || '    ELSE'
      || '      xim2v.item_um'
      || '    END                                 AS  request_quantity_unit'   -- 依頼数量_単位
      || ' ,CASE'
      || '    WHEN  (   ( xic4v.item_class_code = ''' || gv_item_cd_prdct || ''' )'
      || '          AND ( xic4v.prod_class_code  = ''' || gv_prod_cd_drink || ''' )'
      || '          AND     ( xim2v.conv_unit IS NOT NULL  ) ) THEN'
      || '      TRUNC(xmril.instruct_qty / TO_NUMBER('
      || '                                        CASE'
      || '                                          WHEN ( xim2v.num_of_cases > 0 ) THEN'
      || '                                            xim2v.num_of_cases'
      || '                                          ELSE'
      || '                                            TO_CHAR(1)'
      || '                                        END'
      || '                                      ), 3)'
      || '    ELSE'
      || '      xmril.instruct_qty'
      || '    END                                 AS  quantity'                -- 数量
      || ' ,xmril.pallet_quantity                 AS  pallet_quantity'         -- パレット数量
      || ' ,xmril.layer_quantity                  AS  layer_quantity'          -- 段数
      || ' ,xmril.case_quantity'                                               -- ケース数
      || ' ,CASE'
      || '    WHEN ((xmld.automanual_reserve_class = ''' || gv_auto_manual_kbn_a || ''' )'
      || '    AND   (xmld.lot_no IS NULL)                 ) THEN'
      || '      TO_CHAR(xmril.designated_production_date, ''' || gv_date_fmt_ymd || ''' )'
      || '    ELSE'
      || '      ilm.attribute1'
      || '    END                                 AS  make_date'               -- 製造日
      || ' ,CASE'
      || '    WHEN ((xmld.automanual_reserve_class = ''' || gv_auto_manual_kbn_a || ''' )'
      || '    AND   (xmld.lot_no IS NULL)                 ) THEN'
      || '      NULL'
      || '    ELSE'
      || '      ilm.attribute3'
      || '    END                                 AS  shomi_kigen'             -- 賞味期限
      || ' ,CASE'
      || '    WHEN ((xmld.automanual_reserve_class = ''' || gv_auto_manual_kbn_a || ''' )'
      || '    AND   (xmld.lot_no IS NULL)                 ) THEN'
      || '      NULL'
      || '    ELSE'
      || '      ilm.attribute2'
      || '    END                                 AS  koyu_kigou'              -- 固有記号
      || ' ,CASE'
      || '    WHEN ((xmld.automanual_reserve_class = ''' || gv_auto_manual_kbn_a || ''')'
      || '    AND   (xmld.lot_no IS NULL)                 ) THEN'
      || '      NULL'
      || '    ELSE'
      || '      xmld.lot_no'
      || '    END                                 AS  lot_no'                  -- ロットNo
      || ' ,xlv2v4.meaning                        AS  lot_status_name'         -- 品質
      || ' ,CASE'
              -- 引当されている場合
      || '    WHEN ( xmril.reserved_quantity > 0 ) THEN'
      || '      CASE'
      || '        WHEN  ( ( xic4v.item_class_code = ''' || gv_item_cd_prdct || ''' )'
      || '        AND     ( xim2v.conv_unit IS NOT NULL  ) ) THEN'
      || '          TRUNC(xmld.actual_quantity / TO_NUMBER('
      || '                                            CASE'
      || '                                              WHEN ( xim2v.num_of_cases > 0 ) THEN'
      || '                                                xim2v.num_of_cases'
      || '                                              ELSE'
      || '                                                TO_CHAR(1)'
      || '                                            END'
      || '                                          ), 3)'
      || '        ELSE'
      || '          xmld.actual_quantity'
      || '        END'
              -- 引当されていない場合
      || '    WHEN  (( xmril.reserved_quantity IS NULL ) OR ( xmril.reserved_quantity = 0 )) THEN'
      || '      NULL'
      || '    END                                 AS  actual_quantity'         -- ロット分割数量
      || ' ,xlv2v5.meaning                        AS  warrning_name'           -- 警告
      || ' ,xmrih.pallet_sum_quantity             AS  pallet_sum_quantity'     -- パレット合計枚数
      || ' ,CASE'
      || '    WHEN xsm2v.small_amount_class = ''' || gv_small_kbn_obj || ''' THEN'
      || '      CASE'
      || '        WHEN xmrih.weight_capacity_class = ''' || gv_wei_cap_kbn_w || ''''
-- 2008/08/05 Y.Yamamoto v1.7 Update Start
--      || '        THEN xmrih.sum_weight'
      || '        THEN CEIL(TRUNC(xmrih.sum_weight,1))'
-- 2008/08/05 Y.Yamamoto v1.7 Update End
      || '        WHEN xmrih.weight_capacity_class = ''' || gv_wei_cap_kbn_c || ''''
-- 2008/08/05 Y.Yamamoto v1.7 Update Start
--      || '        THEN xmrih.sum_capacity'
      || '        THEN CEIL(TRUNC(xmrih.sum_capacity,1))'
-- 2008/08/05 Y.Yamamoto v1.7 Update End
      || '      END'
      || '    WHEN xsm2v.small_amount_class = ''' || gv_small_kbn_not_obj || ''' THEN'
      || '      CASE'
      || '        WHEN xmrih.weight_capacity_class = ''' || gv_wei_cap_kbn_w || ''' THEN'
-- 2008/08/05 Y.Yamamoto v1.7 Update Start
--      || '          xmrih.sum_pallet_weight + xmrih.sum_weight'
      || '          CEIL(TRUNC(xmrih.sum_pallet_weight + xmrih.sum_weight,1))'
-- 2008/08/05 Y.Yamamoto v1.7 Update End
      || '        WHEN xmrih.weight_capacity_class = ''' || gv_wei_cap_kbn_c || ''' THEN'
-- 2008/08/05 Y.Yamamoto v1.7 Update Start
--      || '          xmrih.sum_pallet_weight + xmrih.sum_capacity'
      || '          CEIL(TRUNC(xmrih.sum_pallet_weight + xmrih.sum_capacity,1))'
-- 2008/08/05 Y.Yamamoto v1.7 Update End
      || '      END'
      || '    WHEN xsm2v.small_amount_class IS NULL THEN'
      || '      NULL '
      || '    END                                 AS  req_weight_volume_total' -- 依頼重量体積_合計
      || ' ,CASE'
      || '    WHEN xmrih.weight_capacity_class = ''' || gv_wei_cap_kbn_w || ''''
      || '    THEN ''' || gv_weight_uom || ''''
      || '    WHEN xmrih.weight_capacity_class = ''' || gv_wei_cap_kbn_c || ''''
      || '    THEN ''' || gv_capacity_uom || ''''
      || '    END                                 AS  req_weight_volume_unit'  -- 依頼重量体積_単位
      || ' ,CASE'
      || '    WHEN xmrih.weight_capacity_class = ''' || gv_wei_cap_kbn_w || ''''
      || '    THEN xmrih.loading_efficiency_weight'
      || '    WHEN xmrih.weight_capacity_class = ''' || gv_wei_cap_kbn_c || ''''
      || '    THEN xmrih.loading_efficiency_capacity'
      || '    END                                 AS loading_efficiency'       -- 積載効率
      || ' ,xlv2v6.attribute1                     AS reserved_kbn'             -- 引当区分
-- 2008/07/02 A.Shiina v1.5 ADD Start
      || ' ,xlv2v1.lookup_code                    AS  freight_charge_code'     -- 運賃区分(コード)
      || ' ,xc2v.complusion_output_code           AS complusion_output_kbn'    -- 強制出力区分
-- 2008/07/02 A.Shiina v1.5 ADD End
-- 2008/09/25 Y.Yamamoto v1.8 ADD Start
      || ' ,NVL(ilm.lot_id, 0)                    AS  lot_id '                 -- ロットID
      || ' ,xic4v.item_class_code                 AS  item_class_code'         -- 品目区分
-- 2008/09/25 Y.Yamamoto v1.8 ADD End
      ;
--
      -- ================================================================================
      -- 【移動】FROM句生成
      -- ================================================================================
      lv_move_from := ' FROM '
      || '  xxinv_mov_req_instr_headers          xmrih'        -- 移動依頼/指示ヘッダアドオン
      || ' ,xxcmn_item_locations2_v              xil2v1'       -- OPM保管場所情報VIEW2
      || ' ,xxcmn_item_locations2_v              xil2v2'       -- OPM保管場所情報VIEW2
      || ' ,xxcmn_carriers2_v                    xc2v'         -- 運送業者情報VIEW2
      || ' ,fnd_user                             fu'           -- ユーザーマスタ
      || ' ,per_all_people_f                     papf'         -- 従業員マスタ
      || ' ,xxinv_mov_req_instr_lines            xmril'        -- 移動依頼/指示明細(アドオン)
      || ' ,xxcmn_item_mst2_v                    xim2v'        -- OPM品目情報VIEW2
-- 2008/08/05 Y.Yamamoto v1.7 Update Start
--      || ' ,xxcmn_item_categories4_v             xic4v'        -- OPM品目カテゴリ割当情報VIEW4
      || ' ,xxcmn_item_categories5_v             xic4v'        -- OPM品目カテゴリ割当情報VIEW5
-- 2008/08/05 Y.Yamamoto v1.7 Update End
      || ' ,xxinv_mov_lot_details                xmld'         -- 移動ロット詳細(アドオン)
      || ' ,ic_lots_mst                          ilm'          -- OPMロットマスタ
      || ' ,xxwsh_ship_method2_v                 xsm2v'        -- 配送区分情報VIEW2
      || ' ,xxcmn_lookup_values2_v               xlv2v1'       -- クイックコード(運賃区分)
      || ' ,xxcmn_lookup_values2_v               xlv2v2'       -- クイックコード(移動タイプ)
      || ' ,xxcmn_lookup_values2_v               xlv2v3'       -- クイックコード(契約外運賃区分)
      || ' ,xxcmn_lookup_values2_v               xlv2v4'       -- クイックコード(ロットステータス)
      || ' ,xxcmn_lookup_values2_v               xlv2v5'       -- クイックコード(警告区分)
      || ' ,xxcmn_lookup_values2_v               xlv2v6'       -- クイックコード(引当区分)
      ;
--
      -- ================================================================================
      -- 【移動】WHERE句生成
      -- ================================================================================
      lv_move_where := ' WHERE '
           -------------------------------------------------------------------------------
           -- OPM保管場所情報VIEW2-1
           -------------------------------------------------------------------------------
      || '       xmrih.shipped_locat_id          =   xil2v1.inventory_location_id'
           -------------------------------------------------------------------------------
           -- OPM保管場所情報VIEW2-2
           -------------------------------------------------------------------------------
      || ' AND   xmrih.ship_to_locat_id          =   xil2v2.inventory_location_id'
           -------------------------------------------------------------------------------
           -- 運送業者情報VIEW2
           -------------------------------------------------------------------------------
      || ' AND   xmrih.career_id                 =   xc2v.party_id(+)'
      || ' AND   ('
      || '         xc2v.start_date_active IS NULL'
      || '       OR'
      || '         xc2v.start_date_active       <=  xmrih.schedule_ship_date'
      || '       )'
      || ' AND   ('
      || '         xc2v.end_date_active IS NULL'
      || '       OR'
      || '         xc2v.end_date_active         >=  xmrih.schedule_ship_date'
      || '       )'
           -------------------------------------------------------------------------------
           -- ユーザ情報
           -------------------------------------------------------------------------------
      || ' AND   xmrih.screen_update_by          = fu.user_id'
      || ' AND   fu.employee_id                  = papf.person_id'
-- 2009/09/14 H.Itou Add Start 本番障害#1632
      || ' AND   xmrih.schedule_ship_date BETWEEN papf.effective_start_date '
      || '                                AND     NVL(papf.effective_end_date,xmrih.schedule_ship_date) '
-- 2009/09/14 H.Itou Add End
           -------------------------------------------------------------------------------
           -- 移動依頼/指示ヘッダ（アドオン）
           -------------------------------------------------------------------------------
-- 2008/11/14 N.Fukuda v1.9 Add Start
      || ' AND   ('
      || '          xmrih.no_instr_actual_class IS NULL'
      || '       OR'
      || '          xmrih.no_instr_actual_class            <>  ''Y'''
      || '       )'
-- 2008/11/14 N.Fukuda v1.9 Add End
           -------------------------------------------------------------------------------
           -- 移動依頼/指示明細アドオン
           -------------------------------------------------------------------------------
      || ' AND   xmrih.mov_hdr_id                =   xmril.mov_hdr_id'
      || ' AND   ('
      || '          xmril.delete_flg IS NULL'
      || '       OR'
      || '          xmril.delete_flg            <>  ''Y'''
      || '       )'
-- 2008/08/05 Y.Yamamoto v1.7 ADD Start
--      || ' AND   xmril.instruct_qty              >   0'     -- 2008/11/14 N.Fukuda v1.9 Del
-- 2008/08/05 Y.Yamamoto v1.7 ADD End
           -------------------------------------------------------------------------------
           -- OPM品目情報VIEW2
           -------------------------------------------------------------------------------
      || ' AND   xmril.item_id                   =   xim2v.item_id'
      || ' AND   xim2v.start_date_active        <=  xmrih.schedule_ship_date'
      || ' AND   ('
      || '         xim2v.end_date_active IS NULL'
      || '       OR'
      || '         xim2v.end_date_active        >=  xmrih.schedule_ship_date'
      || '       )'
           -------------------------------------------------------------------------------
           -- OPM品目カテゴリ割当情報VIEW4
           -------------------------------------------------------------------------------
      || ' AND   xim2v.item_id              =   xic4v.item_id'
      || ' AND   xic4v.prod_class_code      =   ''' || gv_prod_kbn || ''''
           -------------------------------------------------------------------------------
           -- 移動ロット詳細(アドオン)
           -------------------------------------------------------------------------------
      || ' AND   xmril.mov_line_id          = xmld.mov_line_id(+)'
      || ' AND   xmld.document_type_code(+) = ''' || gv_document_type_move || ''''    -- 移動
      || ' AND   xmld.record_type_code(+)   = ''' || record_type_siji || ''''         -- 指示
           -------------------------------------------------------------------------------
           -- OPMロットマスタ
           -------------------------------------------------------------------------------
      || ' AND   xmld.lot_id                     =   ilm.lot_id(+)'
      || ' AND   xmld.item_id                    =   ilm.item_id(+)'
           -------------------------------------------------------------------------------
           -- 配送区分情報VIEW2
           -------------------------------------------------------------------------------
      || ' AND xmrih.shipping_method_code        = xsm2v.ship_method_code(+)'
           -------------------------------------------------------------------------------
           -- クイックコード（運賃区分）-- 1:対象、2:対象外
           -------------------------------------------------------------------------------
      || ' AND xlv2v1.lookup_type                = ''' || gv_lookup_cd_freight || ''''
      || ' AND xmrih.freight_charge_class        = xlv2v1.lookup_code'
           -------------------------------------------------------------------------------
           -- クイックコード（移動タイプ）-- 1:積送あり、2:積送なし
           -------------------------------------------------------------------------------
      || ' AND xlv2v2.lookup_type                = ''' || gv_lookup_cd_move_type || ''''
      || ' AND xmrih.mov_type                    = xlv2v2.lookup_code'
           -------------------------------------------------------------------------------
           -- クイックコード（契約外運賃区分）-- 1:対象、0:対象外
           -------------------------------------------------------------------------------
      || ' AND xlv2v3.lookup_type                = ''' || gv_lookup_cd_no_freight || ''''
      || ' AND xmrih.no_cont_freight_class       = xlv2v3.lookup_code'
           -------------------------------------------------------------------------------
           -- クイックコード（ﾛｯﾄｽﾃｰﾀｽ）-- 10:未判定、30:条件付良品、50:合格、60:不合格、70:保留
           -------------------------------------------------------------------------------
      || ' AND xlv2v4.lookup_type(+)             = ''' || gv_lookup_cd_lot_status || ''''
      || ' AND ilm.attribute23                   = xlv2v4.lookup_code(+)'
           -------------------------------------------------------------------------------
           -- クイックコード（警告区分）-- 10:積載(OVER)、20:積載(LOW)、30:ロット逆転、40:鮮度不備
           -------------------------------------------------------------------------------
      --MOD START 2008/06/04 NAKADA  クイックコードの結合を外部結合に修正
      || ' AND xlv2v5.lookup_type(+)             = ''' || gv_lookup_cd_warn || ''''
      || ' AND xmril.warning_class               = xlv2v5.lookup_code(+)'
      --MOD END   2008/06/04 NAKADA
           -------------------------------------------------------------------------------
           -- クイックコード（引当区分）
           -------------------------------------------------------------------------------
      || ' AND xlv2v6.lookup_type(+)             = ''' || gv_lookup_cd_reserve || ''''
      || ' AND xmld.automanual_reserve_class     = xlv2v6.lookup_code(+)'
      ;
--
      -- 入力パラメータによる条件
          -------------------------------------------------------------------------------
          -- 移動依頼/指示ヘッダ（アドオン）
          -------------------------------------------------------------------------------
      IF (   gr_param.block1 IS NOT NULL
          OR gr_param.block2 IS NOT NULL
          OR gr_param.block3 IS NOT NULL
          OR gr_param.deliver_from_code IS NOT NULL ) THEN
        lv_move_where := lv_move_where
        || ' AND ('
        || '       xil2v1.distribution_block IN (  ''' || gr_param.block1 || ''''
        || '                                     , ''' || gr_param.block2 || ''''
        || '                                     , ''' || gr_param.block3 || ''''
        || '                                     )'                             -- 入力P.ブロック
        || '     OR'
        || '       xmrih.shipped_locat_code  = ''' || gr_param.deliver_from_code || ''''
        || '     )'
        ;
      END IF;
--
      IF (    gr_param.input_date_time_from IS NOT NULL
          AND gr_param.input_date_time_to IS NOT NULL ) THEN
        lv_move_where := lv_move_where
        || ' AND   ('
        || '         TRUNC( xmrih.screen_update_date, ''' || gv_date_fmt_mi || ''' ) '
        || '           >= FND_DATE.STRING_TO_DATE( ''' || gr_param.input_date_time_from || ''''
        || '                                      ,''' || gv_date_fmt_ymdhm || ''' ) '
        || '       AND'
        || '         TRUNC( xmrih.screen_update_date, ''' || gv_date_fmt_mi || ''' ) '
        || '           <= FND_DATE.STRING_TO_DATE( ''' || gr_param.input_date_time_to || ''''
        || '                                      ,''' || gv_date_fmt_ymdhm || ''' ) '
        || '       )'
        ;
      END IF;
--
          -------------------------------------------------------------------------------
          -- ユーザ情報
          -------------------------------------------------------------------------------
      IF (   gr_param.tanto_code IS NOT NULL ) THEN
        lv_move_where := lv_move_where
        || ' AND papf.employee_number      = ''' || gr_param.tanto_code || ''''
        ;
      END IF;
-- v1.12 ADD Start
      -- パラメータ「手動のみ」が'Y'の場合、自動手動引当区分が「手動」のみ
      IF ( gr_param.reserve_class = gv_reserve_class_y ) THEN
        lv_move_where := lv_move_where
        || ' AND xmld.automanual_reserve_class = ''' || gv_auto_manual_kbn_m || ''''
        ;
      END IF;
-- v1.12 ADD End
--
    END IF;
--
    -- ====================================================
    -- ORDER BY句生成
    -- ====================================================
    lv_order_by := ' ORDER BY '
    || '  screen_update_date'
    || ' ,req_mov_no'
    || ' ,meisai_number'
-- 2008/09/25 Y.Yamamoto v1.8 ADD Start
    || ' ,DECODE(item_class_code, ''' || gv_item_cd_prdct     || ''', make_date )'
    || ' ,DECODE(item_class_code, ''' || gv_item_cd_prdct     || ''', koyu_kigou )'
    || ' ,DECODE(item_class_code, ''' || gv_item_cd_genryo    || ''', TO_NUMBER( DECODE( lot_id, 0 , ''0'', lot_no) )'
    || '                        , ''' || gv_item_cd_sizai     || ''', TO_NUMBER( DECODE( lot_id, 0 , ''0'', lot_no) )'
    || '                        , ''' || gv_item_cd_hanseihin || ''', TO_NUMBER( DECODE( lot_id, 0 , ''0'', lot_no) ) )'
-- 2008/09/25 Y.Yamamoto v1.8 ADD End
    ;
--
    -- ====================================================
    -- SQL文生成
    -- ====================================================
    lv_sql :=   lv_select 
             || ' FROM ('
             -- 出荷情報
             || lv_ship_select
             || lv_ship_from
             || lv_ship_where
             ;
             IF ( gr_param.gyoumu_kbn IS NULL ) THEN
               lv_sql := lv_sql
               || ' UNION '
               ;
             END IF;
             -- 移動情報
             lv_sql := lv_sql
             || lv_move_select
             || lv_move_from
             || lv_move_where
             || ' ) '
             || lv_order_by
             ;
--
    -- ====================================================
    -- SQL実行
    -- ====================================================
    EXECUTE IMMEDIATE lv_sql BULK COLLECT INTO ot_report_data ;
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
      ov_errmsg  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_errbuf  := ov_errmsg;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END prc_get_report_data;
--
--
  /***********************************************************************************
   * Procedure Name   : prc_get_profile
   * Description      : プロファイル取得処理
   ***********************************************************************************/
  PROCEDURE prc_get_profile
    (
      ov_errbuf         OUT NOCOPY VARCHAR2     -- エラー・メッセージ           --# 固定 #
     ,ov_retcode        OUT NOCOPY VARCHAR2     -- リターン・コード             --# 固定 #
     ,ov_errmsg         OUT NOCOPY VARCHAR2     -- ユーザー・エラー・メッセージ --# 固定 #
    )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_get_profile'; -- プログラム名
--
--##############################  固定ローカル変数宣言部 START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--#####################################  固定部 END   #############################################
--
  BEGIN
--
--################################  固定ステータス初期化部 START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  固定部 END   #############################################
--
    -- =====================================================
    -- ユーザー宣言部
    -- =====================================================
--
    -- ====================================================
    -- 出荷重量単位取得
    -- ====================================================
    gv_weight_uom := FND_PROFILE.VALUE(gv_prof_name_weight) ;
--
    -- プロファイルが取得できない場合はエラー
    IF (gv_weight_uom IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg( gv_application_wsh
                                            ,gv_msg_id_not_get_prof
                                            ,gv_msg_tkn_nm_prof
                                            ,gv_msg_tkn_val_prof_wei
                                           ) ;
      RAISE global_api_expt ;
    END IF ;
--
    -- ====================================================
    -- 出荷容積単位取得
    -- ====================================================
    gv_capacity_uom := FND_PROFILE.VALUE(gv_prof_name_capacity) ;
--
    -- プロファイルが取得できない場合はエラー
    IF (gv_capacity_uom IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg( gv_application_wsh
                                            ,gv_msg_id_not_get_prof
                                            ,gv_msg_tkn_nm_prof
                                            ,gv_msg_tkn_val_prof_cap
                                           ) ;
      RAISE global_api_expt ;
    END IF ;
--
    -- ====================================================
    -- 商品区分取得
    -- ====================================================
--
    gv_prod_kbn := FND_PROFILE.VALUE(gv_prof_name_item_div) ;
--
    -- プロファイルが取得できない場合はエラー
    IF (gv_prod_kbn IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg( gv_application_wsh
                                            ,gv_msg_id_not_get_prof
                                            ,gv_msg_tkn_nm_prof
                                            ,gv_msg_tkn_val_prof_prod
                                           ) ;
      RAISE global_api_expt ;
    END IF ;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   #######################################
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
--#####################################  固定部 END   #############################################
--
  END prc_get_profile;
--
--
  /**********************************************************************************
   * Procedure Name   : prc_chk_input_param
   * Description      : 入力パラメータチェック処理
   ***********************************************************************************/
  PROCEDURE prc_chk_input_param
    (
      iv_gyoumu_kbn         IN         VARCHAR2       -- 01:業務種別
     ,iv_block1             IN         VARCHAR2       -- 02:ブロック1
     ,iv_block2             IN         VARCHAR2       -- 03:ブロック2 
     ,iv_block3             IN         VARCHAR2       -- 04:ブロック3
     ,iv_deliver_from_code  IN         VARCHAR2       -- 05:出庫元
     ,iv_tanto_code         IN         VARCHAR2       -- 06:担当者コード
     ,iv_input_date         IN         VARCHAR2       -- 07:入力日付
     ,iv_input_time_from    IN         VARCHAR2       -- 08:入力時間FROM
     ,iv_input_time_to      IN         VARCHAR2       -- 09:入力時間TO
-- v1.12 ADD Start
     ,iv_reserve_class      IN         VARCHAR2       -- 10:手動のみ
-- v1.12 ADD End
     ,ov_errbuf             OUT NOCOPY VARCHAR2       -- エラー・メッセージ           --# 固定 #
     ,ov_retcode            OUT NOCOPY VARCHAR2       -- リターン・コード             --# 固定 #
     ,ov_errmsg             OUT NOCOPY VARCHAR2       -- ユーザー・エラー・メッセージ --# 固定 #
    )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_chk_input_param'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ======================================================
    -- ユーザー宣言部
    -- ======================================================
    -- 入力時間FROM
    lv_input_time_from VARCHAR(10) DEFAULT NULL;
    -- 入力時間TO
    lv_input_time_to VARCHAR(10) DEFAULT NULL;
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
    -- 必須チェック
    -- -----------------------------------------------------
    IF (
         (    iv_input_time_from IS NOT NULL
           OR iv_input_time_to IS NOT NULL
         )
         AND iv_input_date IS NULL) THEN
--
       -- エラーメッセージ出力
      ov_errmsg := xxcmn_common_pkg.get_msg( gv_application_wsh
                                            ,gv_msg_err_param) ;
--
      ov_errbuf  := ov_errmsg ;
      ov_retcode := gv_status_error;
--
    ELSE
--
      -- -----------------------------------------------------
      -- 入力パラメータ格納処理
      -- -----------------------------------------------------
      gr_param.gyoumu_kbn            := iv_gyoumu_kbn;                 -- 01:業務種別
      gr_param.block1                := iv_block1;                     -- 02:ブロック1
      gr_param.block2                := iv_block2;                     -- 03:ブロック2 
      gr_param.block3                := iv_block3;                     -- 04:ブロック3
      gr_param.deliver_from_code     := iv_deliver_from_code;          -- 05:出庫元
      gr_param.tanto_code            := iv_tanto_code;                 -- 06:担当者コード
-- v1.12 ADD Start
      gr_param.reserve_class         := iv_reserve_class;              -- 09:手動のみ
-- v1.12 ADD End
--
      IF (iv_input_date IS NOT NULL) THEN
--
        -- 入力時間FROM
        IF (iv_input_time_from IS NULL) THEN
          lv_input_time_from := gv_min_time;
        ELSE
          lv_input_time_from := iv_input_time_from;
        END IF;
--
        -- 入力時間TO
        IF (iv_input_time_to IS NULL) THEN
          lv_input_time_to := gv_max_time;
        ELSE
          lv_input_time_to := iv_input_time_to;
        END IF;
--
        -- 07:入力日時FROM
        gr_param.input_date_time_from
          := iv_input_date || TO_CHAR(FND_DATE.STRING_TO_DATE(  lv_input_time_from
                                                              , gv_date_fmt_hh24mi)
                                                              , gv_date_fmt_hh24mi);
        -- 08:入力日時TO
        gr_param.input_date_time_to
          := iv_input_date || TO_CHAR(FND_DATE.STRING_TO_DATE(  lv_input_time_to
                                                              , gv_date_fmt_hh24mi)
                                                              , gv_date_fmt_hh24mi);
      END IF;
--
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
      ov_errmsg  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_errbuf  := ov_errmsg;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END prc_chk_input_param ;
--
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
      iv_gyoumu_kbn        IN      VARCHAR2         -- 01:業務種別
     ,iv_block1            IN      VARCHAR2         -- 02:ブロック1
     ,iv_block2            IN      VARCHAR2         -- 03:ブロック2 
     ,iv_block3            IN      VARCHAR2         -- 04:ブロック3
     ,iv_deliver_from_code IN      VARCHAR2         -- 05:出庫元
     ,iv_tanto_code        IN      VARCHAR2         -- 06:担当者コード
     ,iv_input_date        IN      VARCHAR2         -- 07:入力日付
     ,iv_input_time_from   IN      VARCHAR2         -- 08:入力時間FROM
     ,iv_input_time_to     IN      VARCHAR2         -- 09:入力時間TO
-- v1.12 ADD Start
     ,iv_reserve_class     IN      VARCHAR2         -- 10:手動のみ
-- v1.12 ADD End
     ,ov_errbuf            OUT     VARCHAR2         -- エラー・メッセージ           --# 固定 #
     ,ov_retcode           OUT     VARCHAR2         -- リターン・コード            --# 固定 #
     ,ov_errmsg            OUT     VARCHAR2         -- ユーザー・エラー・メッセージ  --# 固定 #
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
    lv_errbuf  VARCHAR2(5000) ;                   --   エラー・メッセージ
    lv_retcode VARCHAR2(1) ;                      --   リターン・コード
    lv_errmsg  VARCHAR2(5000) ;                   --   ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ======================================================
    -- ユーザー宣言部
    -- ======================================================
    -- 出庫指示確認表データ
    lt_report_data           type_report_data_tbl;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal ;
--
--###########################  固定部 END   ############################
--
    -- ====================================================
    -- 入力パラメータチェック処理
    -- ====================================================
    prc_chk_input_param(
        iv_gyoumu_kbn           => iv_gyoumu_kbn          -- 01:業務種別
       ,iv_block1               => iv_block1              -- 02:ブロック1
       ,iv_block2               => iv_block2              -- 03:ブロック2 
       ,iv_block3               => iv_block3              -- 04:ブロック3
       ,iv_deliver_from_code    => iv_deliver_from_code   -- 05:出庫元
       ,iv_tanto_code           => iv_tanto_code          -- 06:担当者コード
       ,iv_input_date           => iv_input_date          -- 07:入力日付
       ,iv_input_time_from      => iv_input_time_from     -- 08:入力時間FROM
       ,iv_input_time_to        => iv_input_time_to       -- 09:入力時間TO
-- v1.12 ADD Start
       ,iv_reserve_class        => iv_reserve_class       -- 10:手動のみ
-- v1.12 ADD End
       ,ov_errbuf               => lv_errbuf              -- エラー・メッセージ
       ,ov_retcode              => lv_retcode             -- リターン・コード
       ,ov_errmsg               => lv_errmsg              -- ユーザー・エラー・メッセージ
    );
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt ;
    END IF ;
--
    -- ====================================================
    -- プロファイル取得処理
    -- ====================================================
    prc_get_profile(
        ov_errbuf          => lv_errbuf           -- エラー・メッセージ
       ,ov_retcode         => lv_retcode          -- リターン・コード
       ,ov_errmsg          => lv_errmsg           -- ユーザー・エラー・メッセージ
    );
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt ;
    END IF ;
--
    -- ====================================================
    -- 帳票情報取得処理
    -- ====================================================
    prc_get_report_data(
        ot_report_data     => lt_report_data      -- 取得データ
       ,ov_errbuf          => lv_errbuf           -- エラー・メッセージ
       ,ov_retcode         => lv_retcode          -- リターン・コード
       ,ov_errmsg          => lv_errmsg           -- ユーザー・エラー・メッセージ
    );
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt ;
    END IF ;
--
    IF (lt_report_data.COUNT <> 0) THEN
      -- ====================================================
      -- ＸＭＬデータ作成処理
      -- ====================================================
      prc_create_xml_data(
          it_report_data       =>     lt_report_data     -- 出荷調整表データ
         ,ov_errbuf            =>     lv_errbuf          -- エラー・メッセージ
         ,ov_retcode           =>     lv_retcode         -- リターン・コード
         ,ov_errmsg            =>     lv_errmsg          -- ユーザー・エラー・メッセージ
      );
--
    ELSE
--
      -- ====================================================
      -- ＸＭＬデータ作成処理（０件）
      -- ====================================================
      prc_create_zeroken_xml_data(
          ov_errbuf            =>     lv_errbuf          -- エラー・メッセージ
         ,ov_retcode           =>     lv_retcode         -- リターン・コード
         ,ov_errmsg            =>     lv_errmsg          -- ユーザー・エラー・メッセージ
      );
--
    END IF;
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt ;
    END IF ;
      
    -- ====================================================
    -- ＸＭＬ出力処理
    -- ====================================================
    prc_out_xml_data(
        ov_errbuf            =>     lv_errbuf            -- エラー・メッセージ
       ,ov_retcode           =>     lv_retcode           -- リターン・コード
       ,ov_errmsg            =>     lv_errmsg            -- ユーザー・エラー・メッセージ
    );
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt ;
    END IF ;
--
    -- ====================================================
    -- データなし時、ワーニングセット
    -- ====================================================
    IF (lt_report_data.COUNT = 0) THEN
      ov_retcode := gv_status_warn ;
    END IF;
--
  EXCEPTION
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg ;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000) ;
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
  END submain ;
--
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : コンカレント実行ファイル登録プロシージャ
   **********************************************************************************/
  PROCEDURE main(
      errbuf                OUT    VARCHAR2         -- エラーメッセージ
     ,retcode               OUT    VARCHAR2         -- エラーコード
     ,iv_gyoumu_kbn         IN     VARCHAR2         -- 01:業務種別
     ,iv_block1             IN     VARCHAR2         -- 02:ブロック1
     ,iv_block2             IN     VARCHAR2         -- 03:ブロック2 
     ,iv_block3             IN     VARCHAR2         -- 04:ブロック3
     ,iv_deliver_from_code  IN     VARCHAR2         -- 05:出庫元
     ,iv_tanto_code         IN     VARCHAR2         -- 06:担当者コード
     ,iv_input_date         IN     VARCHAR2         -- 07:入力日付
     ,iv_input_time_from    IN     VARCHAR2         -- 08:入力時間FROM
     ,iv_input_time_to      IN     VARCHAR2         -- 09:入力時間TO
-- v1.12 ADD Start
     ,iv_reserve_class      IN     VARCHAR2         -- 10:手動のみ
-- v1.12 ADD End
  )
--
--###########################  固定部 START   ###########################
--
  IS
--
    -- ======================================================
    -- 固定ローカル定数
    -- ======================================================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'main' ; -- プログラム名
    -- ======================================================
    -- ローカル変数
    -- ======================================================
    lv_errbuf               VARCHAR2(5000) ;      --   エラー・メッセージ
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
        iv_gyoumu_kbn          => iv_gyoumu_kbn         -- 01:業務種別
       ,iv_block1              => iv_block1             -- 02:ブロック1
       ,iv_block2              => iv_block2             -- 03:ブロック2 
       ,iv_block3              => iv_block3             -- 04:ブロック3
       ,iv_deliver_from_code   => iv_deliver_from_code  -- 05:出庫元
       ,iv_tanto_code          => iv_tanto_code         -- 06:担当者コード
       ,iv_input_date          => iv_input_date         -- 07:入力日付
       ,iv_input_time_from     => iv_input_time_from    -- 08:入力時間FROM
       ,iv_input_time_to       => iv_input_time_to      -- 09:入力時間TO
-- v1.12 ADD Start
       ,iv_reserve_class       => iv_reserve_class      -- 10:手動のみ
-- v1.12 ADD End
       ,ov_errbuf              => lv_errbuf             -- エラー・メッセージ           --# 固定 #
       ,ov_retcode             => lv_retcode            -- リターン・コード             --# 固定 #
       ,ov_errmsg              => lv_errmsg             -- ユーザー・エラー・メッセージ --# 固定 #
    ) ;
--
--###########################  固定部 START   #####################################################
--
    -- ======================================================
    -- エラー・メッセージ出力
    -- ======================================================
    IF ( lv_retcode = gv_status_error ) THEN
      errbuf := lv_errmsg ;
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf) ;
    END IF ;
--
    --ステータスセット
    retcode := lv_retcode ;
--
  EXCEPTION
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM ;
      retcode := gv_status_error ;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM ;
      retcode := gv_status_error ;
  END main ;
--
--###########################  固定部 END   #######################################################
--
END xxwsh620005c ;
/
