CREATE OR REPLACE PACKAGE BODY xxwsh620006c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxwsh620006c(body)
 * Description      : 出庫調整表
 * MD.050           : 引当/配車(帳票) T_MD050_BPO_621
 * MD.070           : 出庫調整表 T_MD070_BPO_62H
 * Version          : 1.4
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  fnc_chg_date           FUNCTION  : 日付型変換
 *  fnc_warning_judg       FUNCTION  : 警告判定
 *  prc_set_tag_data       PROCEDURE : タグ情報設定処理
 *  prc_set_tag_data       PROCEDURE : タグ情報設定処理(開始・終了タグ用)
 *  prc_initialize         PROCEDURE : 初期処理
 *  prc_get_report_data    PROCEDURE : 帳票データ取得処理
 *  prc_set_xml_data_cmn   PROCEDURE : XMLデータ設定(出荷・移動共通)
 *  prc_create_xml_data    PROCEDURE : XML生成処理
 *  fnc_convert_into_xml   FUNCTION  : XMLデータ変換
 *  submain                PROCEDURE : メイン処理プロシージャ
 *  main                   PROCEDURE : コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/04/18    1.0   Nozomi Kashiwagi 新規作成
 *  2008/06/04    1.1   Jun Nakada       クイックコード警告区分の結合を外部結合に変更(出荷移動)
 *  2008/6/20     1.2   Y.Shindo         配送区分情報VIEW2の結合を外部結合に変更
 *  2008/07/03    1.3   Akiyoshi Shiina  変更要求対応#92
 *                                       禁則文字「'」「"」「<」「>」「＆」対応
 *  2008/07/10    1.4   Naoki Fukuda     移動の換算単位不具合対応
 *  2008/07/16    1.5   Kazuo Kumamoto   結合テスト障害対応(配送No未設定時は依頼No毎に運送業者情報を出力)
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
  gc_pkg_name                CONSTANT  VARCHAR2(12) := 'xxwsh620006c' ;  -- パッケージ名
  gc_report_id               CONSTANT  VARCHAR2(12) := 'XXWSH620006T' ;  -- 帳票ID
  ------------------------------
  -- 出荷・移動共通
  ------------------------------
  -- 業務種別
  gc_biz_type_cd_ship        CONSTANT  VARCHAR2(1)  := '1' ;        -- 出荷
  gc_biz_type_cd_move        CONSTANT  VARCHAR2(1)  := '3' ;        -- 移動
  gc_biz_type_nm_ship        CONSTANT  VARCHAR2(4)  := '出荷' ;     -- 出荷
  gc_biz_type_nm_move        CONSTANT  VARCHAR2(4)  := '移動' ;     -- 移動
  -- 小口区分
  gc_small_kbn_obj           CONSTANT  VARCHAR2(1)  := '1' ;        -- 対象
  gc_small_kbn_not_obj       CONSTANT  VARCHAR2(1)  := '0' ;        -- 対象外
  -- 締め後修正区分
  gc_modify_kbn_new          CONSTANT  VARCHAR2(1)  := 'N' ;        -- 新規
  gc_modify_kbn_mod          CONSTANT  VARCHAR2(1)  := 'Y' ;        -- 修正
  gc_modify_kbn_nm_new       CONSTANT  VARCHAR2(12) := '新規' ;     -- 新規
  gc_modify_kbn_nm_mod       CONSTANT  VARCHAR2(12) := '修正' ;     -- 修正
  -- 重量容積区分
  gc_wei_cap_kbn_w           CONSTANT  VARCHAR2(1)  := '1' ;        -- 重量
  gc_wei_cap_kbn_c           CONSTANT  VARCHAR2(1)  := '2' ;        -- 容積
  -- 削除・取消フラグ
  gc_delete_flg              CONSTANT  VARCHAR2(1)  := 'Y' ;        -- 鮮度不備
  -- 警告区分
  gc_warn_kbn_over           CONSTANT  VARCHAR2(2)  := '10' ;       -- 積載(OVER)
  gc_warn_kbn_low            CONSTANT  VARCHAR2(2)  := '20' ;       -- 積載(LOW)
  gc_warn_kbn_lot            CONSTANT  VARCHAR2(2)  := '30' ;       -- ロット逆転
  gc_warn_kbn_fresh          CONSTANT  VARCHAR2(2)  := '40' ;       -- 鮮度不備
  -- 品目・商品区分
  gc_prod_cd_drink           CONSTANT  VARCHAR2(1)  := '2' ;        -- 商品区分:ドリンク
  gc_prod_cd_leaf            CONSTANT  VARCHAR2(1)  := '1' ;        -- 商品区分:リーフ
  gc_item_cd_prdct           CONSTANT  VARCHAR2(1)  := '5' ;        -- 品目区分:製品
  -- 日付フォーマット
  gc_date_fmt_all            CONSTANT  VARCHAR2(21) := 'YYYY/MM/DD HH24:MI:SS' ; -- 年月日時分秒
  gc_date_fmt_ymd            CONSTANT  VARCHAR2(10) := 'YYYY/MM/DD' ;            -- 年月日
  gc_date_fmt_ymd_ja         CONSTANT  VARCHAR2(20) := 'YYYY"年"MM"月"DD"日' ;   -- 時分
  -- 出力タグ
  gc_tag_type_tag            CONSTANT  VARCHAR2(1)  := 'T' ;                 -- グループタグ
  gc_tag_type_data           CONSTANT  VARCHAR2(1)  := 'D' ;                 -- データタグ
  ------------------------------
  -- 出荷関連
  ------------------------------
  -- 出荷支給区分
  gc_ship_pro_kbn_s          CONSTANT  VARCHAR2(1)  := '1' ;        -- 出荷依頼
  -- 受注カテゴリ
  gc_order_cate_ret          CONSTANT  VARCHAR2(10) := 'RETURN' ;   -- 返品（受注のみ）
  -- 最新フラグ
  gc_new_flg                 CONSTANT  VARCHAR2(1)  := 'Y' ;        -- 最新フラグ
  -- 出荷依頼ステータス
  gc_ship_status_close       CONSTANT  VARCHAR2(2)  := '03' ;       -- 締め済み
  gc_ship_status_delete      CONSTANT  VARCHAR2(2)  := '99' ;       -- 取消
  ------------------------------
  -- 移動関連
  ------------------------------
  -- 移動タイプ
  gc_mov_type_not_ship       CONSTANT  VARCHAR2(5)  := '2' ;        -- 積送なし
  -- 移動ステータス
  gc_move_status_ordered     CONSTANT  VARCHAR2(2)  := '02' ;       -- 依頼済
  gc_move_status_not         CONSTANT  VARCHAR2(2)  := '99' ;       -- 取消
  ------------------------------
  -- クイックコード関連
  ------------------------------
  gc_lookup_cd_freight       CONSTANT  VARCHAR2(30)  := 'XXWSH_FREIGHT_CLASS' ;        -- 運賃区分
  gc_lookup_cd_warn          CONSTANT  VARCHAR2(30)  := 'XXWSH_WARNING_CLASS' ;        -- 警告区分
  gc_lookup_cd_conreq        CONSTANT  VARCHAR2(30)  := 'XXWSH_LG_CONFIRM_REQ_CLASS' ; -- 確認依頼
  ------------------------------
  -- プロファイル関連
  ------------------------------
  gc_prof_name_weight        CONSTANT VARCHAR2(30)  := 'XXWSH_WEIGHT_UOM' ;   -- 出荷重量単位
  gc_prof_name_capacity      CONSTANT VARCHAR2(30)  := 'XXWSH_CAPACITY_UOM' ; -- 出荷容積単位
  gc_prof_name_threshold     CONSTANT VARCHAR2(30)  := 'XXWSH_LE_THRESHOLD' ; -- 積載効率のしきい値
  gc_prof_name_item_div      CONSTANT VARCHAR2(30)  := 'XXCMN_ITEM_DIV_SECURITY' ; -- 商品区分
  ------------------------------
  -- メッセージ関連
  ------------------------------
  --アプリケーション名
  gc_application_wsh         CONSTANT VARCHAR2(5)   := 'XXWSH' ;             -- ｱﾄﾞｵﾝ:出荷･引当･配車
  gc_application_cmn         CONSTANT VARCHAR2(5)   := 'XXCMN' ;             -- ｱﾄﾞｵﾝ:ﾏｽﾀ･経理･共通
  --メッセージID
  gc_msg_id_not_get_prof     CONSTANT  VARCHAR2(15) := 'APP-XXWSH-12301' ;   -- ﾌﾟﾛﾌｧｲﾙ取得ｴﾗｰ
  gc_msg_id_no_data          CONSTANT  VARCHAR2(15) := 'APP-XXCMN-10122' ;   -- 帳票0件エラー
  --メッセージ-トークン名
  gc_msg_tkn_nm_prof         CONSTANT  VARCHAR2(10) := 'PROF_NAME' ;         -- プロファイル名
  --メッセージ-トークン値
  gc_msg_tkn_val_prof_wei    CONSTANT  VARCHAR2(30) := 'XXWSH:出荷重量単位' ;
  gc_msg_tkn_val_prof_cap    CONSTANT  VARCHAR2(30) := 'XXWSH:出荷容積単位' ;
  gc_msg_tkn_val_prof_thr    CONSTANT  VARCHAR2(30) := 'XXWSH:積載効率のしきい値' ;
  gc_msg_tkn_val_prof_user   CONSTANT  VARCHAR2(30) := 'ユーザーID' ;
  gc_msg_tkn_val_prof_prod   CONSTANT  VARCHAR2(30) := 'XXCMN：商品区分(セキュリティ)' ;
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  -- レコード型宣言用テーブル別名宣言
  xoha   xxwsh_order_headers_all%ROWTYPE ;        -- 受注ヘッダアドオン
  xola   xxwsh_order_lines_all%ROWTYPE ;          -- 受注明細アドオン
  xottv  xxwsh_oe_transaction_types2_v%ROWTYPE ;  -- 受注タイプ情報VIEW2
  xtc    xxwsh_tightening_control%ROWTYPE ;       -- 出荷依頼締め管理(アドオン)
  xilv   xxcmn_item_locations2_v%ROWTYPE ;        -- OPM保管場所情報(出庫元)
  xcv    xxcmn_carriers2_v%ROWTYPE ;              -- 運送業者情報
  xcs    xxwsh_carriers_schedule%ROWTYPE ;        -- 配車配送計画(アドオン)
  xcav   xxcmn_cust_accounts2_v%ROWTYPE ;         -- 顧客情報
  xcasv  xxcmn_cust_acct_sites2_v%ROWTYPE ;       -- 顧客サイト情報
  ximv   xxcmn_item_mst2_v%ROWTYPE ;              -- OPM品目情報
  xicv   xxcmn_item_categories4_v%ROWTYPE ;       -- OPM品目カテゴリ割当情報
  xsmv   xxwsh_ship_method2_v%ROWTYPE ;           -- 配送区分情報
  xlv    xxcmn_lookup_values2_v%ROWTYPE ;         -- クイックコード
  xmrih  xxinv_mov_req_instr_headers%ROWTYPE ;    -- 移動依頼/指示ヘッダ(アドオン)
  xmril  xxinv_mov_req_instr_lines%ROWTYPE ;      -- 移動依頼/指示明細(アドオン)
--
  ------------------------------
  -- 入力パラメータ関連
  ------------------------------
  -- 入力パラメータ格納用レコード
  TYPE rec_param_data IS RECORD(
     concurrent_id        VARCHAR2(15)                      -- 01:コンカレントID
    ,biz_type             VARCHAR2(1)                       -- 02:業務種別
    ,block1               xilv.distribution_block%TYPE      -- 03:ブロック1
    ,block2               xilv.distribution_block%TYPE      -- 04:ブロック2
    ,block3               xilv.distribution_block%TYPE      -- 05:ブロック3
    ,shiped_code          VARCHAR2(4)                       -- 06:出庫元
    ,shiped_date_from     DATE                              -- 07:出庫日From
    ,shiped_date_to       DATE                              -- 08:出庫日To
    ,shiped_form          xoha.order_type_id%TYPE           -- 09:出庫形態
    ,confirm_request      xoha.confirm_request_class%TYPE   -- 10:確認依頼
    ,warning              VARCHAR2(15)                      -- 11:警告
  );
  type_rec_param_data   rec_param_data ;
--
  ------------------------------
  -- 出力データ関連
  ------------------------------
  -- 出力データ格納用レコード
  TYPE rec_report_data IS RECORD(
     biz_type                       VARCHAR2(10)                          -- 業務種別
    ,shiped_code                    xoha.deliver_from%TYPE                -- 出庫元(コード)
    ,shiped_name                    xilv.description%TYPE                 -- 出庫元（名称）
    ,shiped_date                    xoha.schedule_ship_date%TYPE          -- 出庫日
    -- 明細部(配送Noグループ)
    ,delivery_no                    xoha.delivery_no%TYPE                 -- 配送No
    ,arrive_date                    xoha.schedule_arrival_date%TYPE       -- 着日
    ,shipping_method_code           xoha.shipping_method_code%TYPE        -- 配送区分(コード)
    ,shipping_method_name           xsmv.ship_method_meaning%TYPE         -- 配送区分(名称)
    ,career_code                    xoha.freight_carrier_code%TYPE        -- 運送業者(コード)
    ,career_name                    xcv.party_short_name%TYPE             -- 運送業者(名称)
    ,freight_charge_name            xlv.meaning%TYPE                      -- 運賃区分(名称)
    -- 明細部(依頼No/移動Noグループ)
    ,req_move_no                    xoha.request_no%TYPE                  -- 依頼No/移動No
    ,modify_flg                     VARCHAR2(10)                          -- 締め後修正区分
    ,shiped_form                    xottv.transaction_type_name%TYPE      -- 出庫形態
    ,time_from                      xoha.arrival_time_from%TYPE           -- 時間指定FROM
    ,time_to                        xoha.arrival_time_to%TYPE             -- 時間指定TO
    ,mixed_no                       xoha.mixed_no%TYPE                    -- 混載元No
    ,collected_pallet_qty           xoha.collected_pallet_qty%TYPE        -- パレット回収枚数
    ,po_number                      xoha.cust_po_number%TYPE              -- PO#
    ,confirm_request                xlv.meaning%TYPE                      -- 確認依頼
    ,description                    xoha.shipping_instructions%TYPE       -- 摘要
    ,base_code                      xoha.head_sales_branch%TYPE           -- 管轄拠点(コード)
    ,base_name                      xcav.party_short_name%TYPE            -- 管轄拠点(名称)
    ,delivery_to_code               xoha.deliver_to%TYPE                  -- 配送先／入庫先(コード)
    ,delivery_to_name               xcasv.party_site_full_name%TYPE       -- 配送先／入庫先(名称)
    ,delivery_to_address            VARCHAR2(60)                          -- 配送先住所
    ,delivery_to_phone              xcasv.phone%TYPE                      -- 電話番号
    -- 明細部(品目コード)
    ,item_code                      xola.shipping_item_code%TYPE          -- 品名(コード)
    ,item_name                      ximv.item_short_name%TYPE             -- 品名(名称)
    ,qty                            NUMBER                                -- 数量
    ,qty_tani                       VARCHAR2(3)                           -- 数量_単位
    ,pallet_quantity                xola.pallet_quantity%TYPE             -- パレット枚数
    ,layer_quantity                 xola.layer_quantity%TYPE              -- 段数
    ,case_quantity                  xola.case_quantity%TYPE               -- ケース数
    ,warning                        xlv .meaning%TYPE                     -- 警告
    -- 明細部(依頼No単位合計項目)
    ,wei_cap_kbn                    xoha.weight_capacity_class%TYPE       -- 重量容積区分
    ,req_sum_pallet_qty             xoha.pallet_sum_quantity%TYPE         -- パレット合計枚数
    ,req_sum_weight                 xoha.sum_weight%TYPE                  -- 積載重量合計
    ,req_sum_capacity               xoha.sum_capacity%TYPE                -- 積載容積合計
    ,req_eff_weight                 xoha.loading_efficiency_weight%TYPE   -- 重量積載効率
    ,req_eff_capacity               xoha.loading_efficiency_capacity%TYPE -- 容積積載効率
    -- 明細部(配送No単位合計項目)
    ,deli_eff_weight                xcs.loading_efficiency_weight%TYPE    -- 重量積載効率
    ,deli_eff_capacity              xcs.loading_efficiency_capacity%TYPE  -- 容積積載効率
-- 2008/07/03 A.Shiina v1.3 ADD Start
    ,freight_charge_code            xlv.lookup_code%TYPE                  -- 運賃区分(コード)
    ,complusion_output_kbn          xcv.complusion_output_code%TYPE       -- 強制出力区分
-- 2008/07/03 A.Shiina v1.3 ADD Start
  );
  type_report_data      rec_report_data;
  TYPE list_report_data IS TABLE OF rec_report_data INDEX BY BINARY_INTEGER ;
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gt_param              rec_param_data ;        -- 入力パラメータ情報
  gt_report_data_ship   list_report_data ;      -- 出力データ(出荷用)
  gt_report_data_move   list_report_data ;      -- 出力データ(移動用)
  gt_xml_data_table     xml_data ;              -- XMLデータ
  gv_dept_cd            VARCHAR2(10) ;          -- 担当部署
  gv_dept_nm            VARCHAR2(14) ;          -- 担当者
--
  -- プロファイル値取得結果格納用
  gv_weight_uom         VARCHAR2(3);            -- 出荷重量単位
  gv_capacity_uom       VARCHAR2(3);            -- 出荷容積単位
  gv_le_threshold       NUMBER;                 -- 積載効率のしきい値
  gv_user_id            fnd_user.user_id%TYPE;  -- ユーザID
  gv_prod_kbn           VARCHAR2(1);            -- 商品区分
--
  -- 警告区分名称
  gv_warning_over       xlv.meaning%TYPE ;   -- 積載(OVER)
  gv_warning_low        xlv.meaning%TYPE ;   -- 積載(LOW)
--
  /**********************************************************************************
   * Function Name    : fnc_chg_date
   * Description      : 日付型変換(例：2008/04/01 → 01-APR-08)
   ***********************************************************************************/
  FUNCTION fnc_chg_date(
    iv_date     IN  VARCHAR2  -- YYYY/MM/DD形式の日付
  )RETURN DATE
  IS
  BEGIN
    -- 文字列の日付(YYYY/MM/DD形式)を日付型に変換して返却
    RETURN( FND_DATE.STRING_TO_DATE(iv_date, gc_date_fmt_ymd) ) ;
  END fnc_chg_date;
--
  /**********************************************************************************
   * Function Name    : fnc_warning_judg
   * Description      : 警告判定
   *                    引数の値を積載効率のしきい値と100で比較し、
   *                    比較結果を元に警告名称を返す。
   ***********************************************************************************/
  FUNCTION fnc_warning_judg(
    in_judg_val  IN  NUMBER
  )RETURN VARCHAR2
  IS
    lv_warning_nm  xxcmn_lookup_values2_v.meaning%TYPE ;
  BEGIN
    -- 積載効率のしきい値を下回った場合
    IF (in_judg_val < gv_le_threshold) THEN
      lv_warning_nm := gv_warning_low;
--
    -- 100%を上回った場合
    ELSIF (in_judg_val > 100) THEN
      lv_warning_nm := gv_warning_over;
    END IF;
--
    RETURN (lv_warning_nm);
  END fnc_warning_judg;
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
    get_prof_expt     EXCEPTION ;     -- プロファイル取得例外
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
    -- プロファイル取得
    -- ====================================================
    -- 出荷重量単位取得
    gv_weight_uom := FND_PROFILE.VALUE(gc_prof_name_weight) ;
    IF (gv_weight_uom IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg( gc_application_wsh
                                            ,gc_msg_id_not_get_prof
                                            ,gc_msg_tkn_nm_prof
                                            ,gc_msg_tkn_val_prof_wei
                                           ) ;
      RAISE get_prof_expt ;
    END IF ;
--
    -- 出荷容積単位取得
    gv_capacity_uom := FND_PROFILE.VALUE(gc_prof_name_capacity) ;
    IF (gv_capacity_uom IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg( gc_application_wsh
                                            ,gc_msg_id_not_get_prof
                                            ,gc_msg_tkn_nm_prof
                                            ,gc_msg_tkn_val_prof_cap
                                           ) ;
      RAISE get_prof_expt ;
    END IF ;
--
    -- 積載効率のしきい値取得
    gv_le_threshold := FND_PROFILE.VALUE(gc_prof_name_threshold) ;
    IF (gv_le_threshold IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg( gc_application_wsh
                                            ,gc_msg_id_not_get_prof
                                            ,gc_msg_tkn_nm_prof
                                            ,gc_msg_tkn_val_prof_thr
                                           ) ;
      RAISE get_prof_expt ;
    END IF ;
--
    -- ユーザID
    gv_user_id := FND_GLOBAL.USER_ID ;
    IF (gv_user_id IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg( gc_application_wsh
                                            ,gc_msg_id_not_get_prof
                                            ,gc_msg_tkn_nm_prof
                                            ,gc_msg_tkn_val_prof_user
                                           ) ;
      RAISE get_prof_expt ;
    END IF ;
--
    -- 職責：商品区分
    gv_prod_kbn := FND_PROFILE.VALUE(gc_prof_name_item_div) ;
    IF (gv_prod_kbn IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg( gc_application_wsh
                                            ,gc_msg_id_not_get_prof
                                            ,gc_msg_tkn_nm_prof
                                            ,gc_msg_tkn_val_prof_prod
                                           ) ;
      RAISE get_prof_expt ;
    END IF ;
--
  EXCEPTION
    --*** プロファイル取得例外ハンドラ ***
    WHEN get_prof_expt THEN
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
    -- -----------------------------------------------------
    -- 出荷依頼情報抽出
    -- -----------------------------------------------------
    CURSOR cur_ship_data
    IS
      SELECT
        ---------------------------------------------------------------------------------------
        -- ヘッダ部
         TO_CHAR(gc_biz_type_nm_ship)    AS  biz_type               -- 業務種別
        ,xoha.deliver_from               AS  shiped_code            -- 出庫元(コード)
        ,xilv.description                AS  shiped_name            -- 出庫元（名称）
        ,xoha.schedule_ship_date         AS  shiped_date            -- 出庫日
        ,xoha.delivery_no                AS  delivery_no            -- 配送No
        ,xoha.schedule_arrival_date      AS  arrive_date            -- 着日
        ,xoha.shipping_method_code       AS  shipping_method_code   -- 配送区分(コード)
        ,xsmv.ship_method_meaning        AS  shipping_method_name   -- 配送区分(名称)
        ,xoha.freight_carrier_code       AS  career_code            -- 運送業者(コード)
        ,xcv.party_short_name            AS  career_name            -- 運送業者(名称)
        ,xlv1.meaning                    AS  freight_charge_name    -- 運賃区分(名称)
        ------------------------------------------------------------------------
        -- 明細部-依頼Noグループ
        ,xoha.request_no                 AS  req_move_no            -- 依頼No/移動No
        ,CASE
          WHEN gt_param.concurrent_id IS NULL THEN  NULL
          ELSE (
            CASE
              WHEN xoha.corrected_tighten_class = gc_modify_kbn_new THEN gc_modify_kbn_nm_new
              WHEN xoha.corrected_tighten_class = gc_modify_kbn_mod THEN gc_modify_kbn_nm_mod
            END
          )
         END                             AS  modify_flg             -- 締め後修正区分
        ,xottv.transaction_type_name     AS  shiped_form            -- 出庫形態
        ,xoha.arrival_time_from          AS  time_from              -- 時間指定FROM
        ,xoha.arrival_time_to            AS  time_to                -- 時間指定TO
        ,xoha.mixed_no                   AS  mixed_no               -- 混載元No
        ,xoha.collected_pallet_qty       AS  collected_pallet_qty   -- パレット回収枚数
        ,xoha.cust_po_number             AS  po_number              -- PO#
        ,xlv3.meaning                    AS  confirm_request        -- 確認依頼
        ,xoha.shipping_instructions      AS  description            -- 摘要
        ,xoha.head_sales_branch          AS  base_code              -- 管轄拠点(コード)
        ,xcav.party_short_name           AS  base_name              -- 管轄拠点(名称)
        ,xoha.deliver_to                 AS  delivery_to_code       -- 配送先／入庫先(コード)
        ,xcasv.party_site_full_name      AS  delivery_to_name       -- 配送先／入庫先(名称)
        ,SUBSTRB(xcasv.address_line1 || xcasv.address_line2, 1, 60) 
                                         AS  delivery_to_address    -- 配送先住所
        ,xcasv.phone                     AS  delivery_to_phone      -- 電話番号
        ---------------------------------------------------
        -- 明細部-品目グループ
        ,xola.shipping_item_code         AS  item_code  --品名(コード)
        ,ximv.item_short_name            AS  item_name  --品名(名称)
        ,CASE
           -- 入出庫換算単位が設定済み かつ ドリンク製品またはリーフ製品の場合
           WHEN (ximv.conv_unit IS NOT NULL
              AND  xicv.item_class_code = gc_item_cd_prdct
              AND  ((xicv.prod_class_code = gc_prod_cd_drink) 
                OR  (xicv.prod_class_code = gc_prod_cd_leaf))
           ) THEN (xola.quantity / TO_NUMBER(CASE 
                                               WHEN ximv.num_of_cases > 0 THEN ximv.num_of_cases
                                               ELSE TO_CHAR(1)
                                             END)
           )
           ELSE xola.quantity
         END                     AS  qty -- 数量
        ,CASE
          -- 入出庫換算単位が未設定
          WHEN ximv.conv_unit IS NULL THEN  ximv.item_um
          -- 入出庫換算単位が設定済
          ELSE ximv.conv_unit
         END                     AS   qty_tani            -- 数量_単位
        ,xola.pallet_quantity    AS   pallet_quantity     -- パレット枚数
        ,xola.layer_quantity     AS   layer_quantity      -- 段数
        ,xola.case_quantity      AS   case_quantity       -- ケース数
        ,xlv2.meaning            AS   warning             -- 警告
        -------------------------------------------------------------------------------
        -- 明細部-依頼No単位合計項目
        ,xoha.weight_capacity_class        AS  wei_cap_kbn           -- 重量容積区分
        ,xoha.pallet_sum_quantity          AS  deli_sum_pallet_qty   -- パレット枚数(依頼No単位)
        ,CASE
          WHEN xsmv.small_amount_class = gc_small_kbn_obj THEN
            xoha.sum_weight
          WHEN xsmv.small_amount_class = gc_small_kbn_not_obj THEN
            xoha.sum_weight + xoha.sum_pallet_weight
          WHEN xsmv.small_amount_class IS NULL THEN   -- 6/20追加
            NULL
         END                               AS req_sum_weight         -- 積載重量合計(依頼No単位)
        ,CASE
          WHEN xsmv.small_amount_class = gc_small_kbn_obj THEN
            xoha.sum_capacity
          WHEN xsmv.small_amount_class = gc_small_kbn_not_obj THEN
            xoha.sum_capacity + xoha.sum_pallet_weight
          WHEN xsmv.small_amount_class IS NULL THEN
            NULL
         END                               AS  req_sum_capacity      -- 積載容積合計(依頼No単位)
        ,xoha.loading_efficiency_weight    AS  req_eff_weight        -- 重量積載効率(依頼No単位)
        ,xoha.loading_efficiency_capacity  AS  req_eff_capacity      -- 容積積載効率(依頼No単位)
        ,xcs.loading_efficiency_weight     AS  deli_eff_weight       -- 重量積載効率(配送No単位)
        ,xcs.loading_efficiency_capacity   AS  deli_eff_capacity     -- 容積積載効率(配送No単位)
-- 2008/07/03 A.Shiina v1.3 ADD Start
        ,xlv1.lookup_code                  AS  freight_charge_code   -- 運賃区分(コード)
        ,xcv.complusion_output_code        AS  complusion_output_kbn -- 強制出力区分
-- 2008/07/03 A.Shiina v1.3 ADD End
      FROM
         xxwsh_order_headers_all        xoha    -- 01:受注ヘッダアドオン
        ,xxwsh_order_lines_all          xola    -- 02:受注明細アドオン
        ,xxwsh_oe_transaction_types2_v  xottv   -- 03:受注タイプ情報
        ,xxwsh_tightening_control       xtc     -- 04:出荷依頼締め管理(アドオン)
        ,xxcmn_item_locations2_v        xilv    -- 05:OPM保管場所情報(出庫元)
        ,xxcmn_carriers2_v              xcv     -- 06:運送業者情報
        ,xxwsh_carriers_schedule        xcs     -- 07:配車配送計画(アドオン)
        ,xxcmn_cust_accounts2_v         xcav    -- 08:顧客情報(管轄拠点情報)
        ,xxcmn_cust_acct_sites2_v       xcasv   -- 09:顧客サイト情報(出荷先情報)
        ,xxcmn_item_mst2_v              ximv    -- 10:OPM品目情報
        ,xxcmn_item_categories4_v       xicv    -- 11:OPM品目カテゴリ割当情報
        ,xxwsh_ship_method2_v           xsmv    -- 12:配送区分情報
        ,xxcmn_lookup_values2_v         xlv1    -- 13:クイックコード(運賃区分)
        ,xxcmn_lookup_values2_v         xlv2    -- 14:クイックコード(警告区分)
        ,xxcmn_lookup_values2_v         xlv3    -- 15:クイックコード(物流担当確認依頼区分)
      WHERE
        ----------------------------------------------------------------------------------
        -- ヘッダ情報
        ----------------------------------------------------------------------------------
        -- 01:受注ヘッダアドオン
             xoha.order_type_id           = xottv.transaction_type_id
        AND  xoha.order_type_id           = NVL(gt_param.shiped_form, xoha.order_type_id)
        AND  xoha.req_status             >= gc_ship_status_close    -- ステータス:締め済み
        AND  xoha.req_status             <> gc_ship_status_delete   -- ステータス:取消
        AND  xoha.latest_external_flag    = gc_new_flg              -- 最新フラグ
        AND  (gt_param.confirm_request IS NULL
          OR  xoha.confirm_request_class  = gt_param.confirm_request
        )
        AND  ( 
               (gt_param.shiped_date_to IS NULL
               -- パラメータ.出庫日Fromのみ指定された場合
               AND  TRUNC(xoha.schedule_ship_date) >= TRUNC(gt_param.shiped_date_from)
          ) OR (gt_param.shiped_date_to IS NOT NULL
               -- パラメータ.出庫日From、パラメータ.出庫日Toの両方指定された場合
               AND  TRUNC(xoha.schedule_ship_date) >= TRUNC(gt_param.shiped_date_from)
               AND  TRUNC(xoha.schedule_ship_date) <= TRUNC(gt_param.shiped_date_to)
          )
        )
        -- 03:受注タイプ情報VIEW2
        AND  xottv.shipping_shikyu_class  = gc_ship_pro_kbn_s       -- 出荷支給区分:出荷依頼
        AND  xottv.order_category_code   <> gc_order_cate_ret       -- 受注カテゴリ:返品
        -- 04:出荷依頼締め管理(アドオン)
        AND  xoha.tightening_program_id  = xtc.concurrent_id(+)
        AND  (gt_param.concurrent_id IS NULL
          OR  xoha.tightening_program_id = gt_param.concurrent_id
        )
        -- 05:OPM保管場所情報(出庫元)
        AND  xoha.deliver_from_id = xilv.inventory_location_id
        AND  (
              xoha.deliver_from = gt_param.shiped_code
          OR  xilv.distribution_block = gt_param.block1
          OR  xilv.distribution_block = gt_param.block2
          OR  xilv.distribution_block = gt_param.block3
          OR  ((gt_param.block1 IS NULL) AND (gt_param.block2 IS NULL) AND (gt_param.block3 IS NULL)
            AND (gt_param.shiped_code IS NULL))
        )
        -- 06:運送業者情報
        AND  xoha.career_id = xcv.party_id(+)
        -- 08:顧客サイト情報(管轄拠点情報)
        AND  xoha.head_sales_branch = xcav.party_number
        -- 09:顧客サイト情報(出荷先情報)
        AND  xoha.deliver_to_id     = xcasv.party_site_id
        -- 07:配車配送計画(アドオン)
        AND  xoha.delivery_no       =  xcs.delivery_no(+)
        -- 警告区分関連
        AND  (
               (gt_param.warning IS NULL
          ) OR (gt_param.warning = gc_warn_kbn_over   --「積載(OVER)」
                -- 重量容積区分:重量
                AND  (xoha.weight_capacity_class = gc_wei_cap_kbn_w
                    AND (xoha.loading_efficiency_weight > 100
                      OR ((xcs.loading_efficiency_weight  > 100) OR (xcs.delivery_no IS NULL))
                    )
                -- 重量容積区分:容積
                ) OR (xoha.weight_capacity_class = gc_wei_cap_kbn_c
                    AND (xoha.loading_efficiency_capacity > 100 
                      OR ((xcs.loading_efficiency_capacity  > 100) OR (xcs.delivery_no IS NULL))
                    )
                )
              
          ) OR (gt_param.warning = gc_warn_kbn_low   --「積載(LOW)」
                -- 重量容積区分:重量
                AND  (xoha.weight_capacity_class = gc_wei_cap_kbn_w
                  AND (xoha.loading_efficiency_weight < gv_le_threshold
                    OR ((xcs.loading_efficiency_weight  < gv_le_threshold)
                      OR (xcs.delivery_no IS NULL))
                  )
                -- 重量容積区分:容積
                ) OR (xoha.weight_capacity_class = gc_wei_cap_kbn_c
                  AND (xoha.loading_efficiency_capacity < gv_le_threshold
                    OR ((xcs.loading_efficiency_capacity  < gv_le_threshold)
                      OR (xcs.delivery_no IS NULL))
                  )
                )
          ) OR (gt_param.warning = gc_warn_kbn_lot     --「ロット逆転」
                AND xola.warning_class = gc_warn_kbn_lot
          ) OR (gt_param.warning = gc_warn_kbn_fresh   --「鮮度不備」
                AND xola.warning_class = gc_warn_kbn_fresh
          )
        )
        -- 12:配送区分情報
        AND  xoha.shipping_method_code  =  xsmv.ship_method_code(+)   -- 6/20 外部結合追加
        ----------------------------------------------------------------------------------
        -- 明細情報
        ----------------------------------------------------------------------------------
        -- 02:受注明細アドオン
        AND  xoha.order_header_id  = xola.order_header_id
        AND  xola.delete_flag     <> gc_delete_flg
        -- 10:OPM品目情報
        AND  xola.shipping_inventory_item_id = ximv.inventory_item_id
        -- 11:OPM品目カテゴリ割当情報
        AND  ximv.item_id = xicv.item_id
        AND  xicv.prod_class_code = gv_prod_kbn
        ----------------------------------------------------------------------------------
        -- クイックコード
        ----------------------------------------------------------------------------------
        -- MOD START 2008/06/04 NAKADA クイックコードとの結合を外部結合に修正
        -- 10:クイックコード(運賃区分)
        AND  xlv1.lookup_type(+) = gc_lookup_cd_freight
        AND  xoha.freight_charge_class = xlv1.lookup_code(+)
        -- 11:クイックコード(警告区分)
        AND  xlv2.lookup_type(+) = gc_lookup_cd_warn
        AND  xola.warning_class = xlv2.lookup_code(+)
        -- 11:クイックコード(物流担当確認依頼区分)
        AND  xlv3.lookup_type(+) = gc_lookup_cd_conreq
        AND  xoha.confirm_request_class = xlv3.lookup_code(+)
        -- MOD END   2008/06/04 NAKADA 
        ----------------------------------------------------------------------------------
        -- アドオンマスタ適用日
        ----------------------------------------------------------------------------------
        -- 06:運送業者情報
        AND  (xcv.party_id IS NULL
          OR (   TRUNC(xcv.start_date_active) <= TRUNC(gt_param.shiped_date_from)
            AND  (xcv.end_date_active IS NULL
              OR  TRUNC(xcv.end_date_active) >= TRUNC(gt_param.shiped_date_from))
          )
        )
        -- 08:顧客情報(管轄拠点情報)
        AND  TRUNC(xcav.start_date_active)  <= TRUNC(gt_param.shiped_date_from)
        AND  (xcav.end_date_active IS NULL
          OR  TRUNC(xcav.end_date_active)  >= TRUNC(gt_param.shiped_date_from))
        -- 09:顧客サイト情報(出荷先情報)
        AND  TRUNC(xcasv.start_date_active) <= TRUNC(gt_param.shiped_date_from)
        AND  (xcasv.end_date_active IS NULL
          OR  TRUNC(xcasv.end_date_active) >= TRUNC(gt_param.shiped_date_from))
        -- 10:OPM品目情報
        AND  TRUNC(ximv.start_date_active)  <= TRUNC(gt_param.shiped_date_from)
        AND  (ximv.end_date_active IS NULL
          OR  TRUNC(ximv.end_date_active)  >= TRUNC(gt_param.shiped_date_from))
      ORDER BY
             shiped_code      ASC   -- 出庫元（コード）
            ,shiped_date      ASC   -- 出庫日
            ,arrive_date      ASC   -- 着日
            ,delivery_no      ASC   -- 配送No
            ,base_code        ASC   -- 管轄拠点
            ,delivery_to_code ASC   -- 配送先
            ,req_move_no      ASC   -- 依頼No/移動No
            ,item_code        ASC   -- 品目コード
      ;
--
    -- -----------------------------------------------------
    -- 移動依頼情報抽出
    -- -----------------------------------------------------
    CURSOR cur_move_data
    IS
      SELECT
        ---------------------------------------------------------------------------------------
        -- ヘッダ部
         TO_CHAR(gc_biz_type_nm_move)     AS  biz_type               --業務種別
        ,xmrih.shipped_locat_code         AS  shiped_code            --出庫元(コード)
        ,xilv1.description                AS  shiped_name            --出庫元（名称）
        ,xmrih.schedule_ship_date         AS  shiped_date            --出庫日
        ,xmrih.delivery_no                AS  delivery_no            --配送No
        ,xmrih.schedule_arrival_date      AS  arrive_date            --着日
        ,xmrih.shipping_method_code       AS  shipping_method_code   --配送区分(コード)
        ,xsmv.ship_method_meaning         AS  shipping_method_name   --配送区分(名称)
        ,xmrih.freight_carrier_code       AS  career_code            --運送業者(コード)
        ,xcv.party_short_name             AS  career_name            --運送業者(名称)
        ,xlv1.meaning                     AS  freight_charge_name    --運賃区分(名称)
        ---------------------------------------------------------------------------------------
        -- 明細部-依頼Noグループ
        ,xmrih.mov_num                    AS  req_move_no            --依頼No/移動No
        ,NULL                             AS  modify_flg             --締め後修正区分
        ,NULL                             AS  shiped_form            --出庫形態
        ,xmrih.arrival_time_from          AS  time_from              --時間指定FROM
        ,xmrih.arrival_time_to            AS  time_to                --時間指定TO
        ,NULL                             AS  mixed_no               --混載元No
        ,xmrih.collected_pallet_qty       AS  collected_pallet_qty   --パレット回収枚数
        ,NULL                             AS  po_number              --PO#
        ,NULL                             AS  confirm_request        --確認依頼
        ,xmrih.description                AS  description            --摘要
        ,NULL                             AS  base_code              --管轄拠点(コード)
        ,NULL                             AS  base_name              --管轄拠点(名称)
        ,xmrih.ship_to_locat_code         AS  delivery_to_code       --配送先／入庫先(コード)
        ,xilv2.description                AS  delivery_to_name       --配送先／入庫先(名称)
        ,NULL                             AS  delivery_to_address    --配送先住所
        ,NULL                             AS  delivery_to_phone      --電話番号
        ---------------------------------------------------
        -- 明細部-品目グループ
        ,xmril.item_code                  AS  item_code              --品名(コード)
        ,ximv.item_short_name             AS  item_name              --品名(名称)
        ,CASE
           -- 入出庫換算単位が設定済み かつ ドリンク製品の場合
           WHEN (ximv.conv_unit IS NOT NULL
              AND  xicv.item_class_code = gc_item_cd_prdct
              AND  xicv.prod_class_code = gc_prod_cd_drink
           ) THEN (xmril.instruct_qty / TO_NUMBER(
                                          CASE 
                                            WHEN ximv.num_of_cases > 0 THEN  ximv.num_of_cases
                                            ELSE TO_CHAR(1)
                                          END)
           )
           ELSE  xmril.instruct_qty
         END                     AS  qty --数量
        -- 2008/07/10 Fukuda Start --------------------------------------
        --,CASE
        --  -- 入出庫換算単位が未設定の場合
        --  WHEN ximv.conv_unit IS NULL THEN ximv.item_um
        --  -- 入出庫換算単位が設定済の場合
        --  ELSE ximv.conv_unit
        -- END                     AS  qty_tani            --数量_単位
        --
        ,CASE
           -- 入出庫換算単位が設定済み かつ ドリンク製品の場合
           WHEN (ximv.conv_unit IS NOT NULL
              AND  xicv.item_class_code = gc_item_cd_prdct
              AND  xicv.prod_class_code = gc_prod_cd_drink
           ) THEN ximv.conv_unit
           ELSE ximv.item_um
         END                     AS  qty_tani            --数量_単位
        -- 2008/07/10 Fukuda END --------------------------------------------
        --
        ,xmril.pallet_quantity   AS  pallet_quantity     --パレット枚数
        ,xmril.layer_quantity    AS  layer_quantity      --段数
        ,xmril.case_quantity     AS  case_quantity       --ケース数
        ,xlv2.meaning            AS  warning             --警告
        -------------------------------------------------------------------------------
        -- 明細部-依頼No単位合計
        ,xmrih.weight_capacity_class        AS  wei_cap_kbn          -- 重量容積区分
        ,xmrih.pallet_sum_quantity          AS  deli_sum_pallet_qty  -- パレット枚数(依頼No単位)
        ,CASE
          -- 小口区分が対象の場合
          WHEN xsmv.small_amount_class = gc_small_kbn_obj THEN
            xmrih.sum_weight
          -- 小口区分が対象外の場合
          WHEN xsmv.small_amount_class = gc_small_kbn_not_obj THEN
            xmrih.sum_weight + xmrih.sum_pallet_weight
          -- 小口区分がNULLの場合
          WHEN xsmv.small_amount_class IS NULL THEN   -- 6/20追加
            NULL
         END                                AS req_sum_weight         -- 積載重量合計(依頼No単位)
        ,CASE
          -- 小口区分が対象の場合
          WHEN xsmv.small_amount_class = gc_small_kbn_obj THEN
            xmrih.sum_capacity
          -- 小口区分が対象外の場合
          WHEN xsmv.small_amount_class = gc_small_kbn_not_obj THEN
            xmrih.sum_capacity + xmrih.sum_pallet_weight
          -- 小口区分がNULLの場合
          WHEN xsmv.small_amount_class IS NULL THEN   -- 6/20追加
            NULL
         END                                AS  req_sum_capacity      -- 積載容積合計(依頼No単位)
        ,xmrih.loading_efficiency_weight    AS  req_eff_weight        -- 重量積載効率(依頼No単位)
        ,xmrih.loading_efficiency_capacity  AS  req_eff_capacity      -- 容積積載効率(依頼No単位)
        ,xcs.loading_efficiency_weight      AS  deli_eff_weight       -- 重量積載効率(配送No単位)
        ,xcs.loading_efficiency_capacity    AS  deli_eff_capacity     -- 容積積載効率(配送No単位)
-- 2008/07/03 A.Shiina v1.3 ADD Start
        ,xlv1.lookup_code                   AS  freight_charge_code   -- 運賃区分(コード)
        ,xcv.complusion_output_code         AS  complusion_output_kbn -- 強制出力区分
-- 2008/07/03 A.Shiina v1.3 ADD End
      FROM
             xxinv_mov_req_instr_headers    xmrih     -- 01:移動依頼/指示ヘッダ(アドオン)
            ,xxinv_mov_req_instr_lines      xmril     -- 02:移動依頼/指示明細(アドオン)
            ,xxwsh_carriers_schedule        xcs       -- 03:配車配送計画(アドオン)
            ,xxcmn_item_locations2_v        xilv1     -- 04:OPM保管場所情報(出庫元)
            ,xxcmn_item_locations2_v        xilv2     -- 05:OPM保管場所情報(入庫先)
            ,xxcmn_carriers2_v              xcv       -- 06:運送業者情報
            ,xxcmn_item_mst2_v              ximv      -- 07:OPM品目情報
            ,xxcmn_item_categories4_v       xicv      -- 08:OPM品目カテゴリ割当情報
            ,xxwsh_ship_method2_v           xsmv      -- 09:配送区分情報
            ,xxcmn_lookup_values2_v         xlv1      -- 10:クイックコード(運賃区分)
            ,xxcmn_lookup_values2_v         xlv2      -- 11:クイックコード(警告区分)
      WHERE
        ----------------------------------------------------------------------------------
        -- ヘッダ情報
        ----------------------------------------------------------------------------------
        -- 01:移動依頼/指示ヘッダ(アドオン)
             xmrih.mov_type   <>  gc_mov_type_not_ship   --移動タイプ:積送なし
        AND  xmrih.status     >=  gc_move_status_ordered --ステータス:依頼済
        AND  xmrih.status     <>  gc_move_status_not     --ステータス:取消
        -- 03:配車配送計画(アドオン)
        AND  xmrih.delivery_no      =  xcs.delivery_no(+)
        -- 04:OPM保管場所情報(出庫元)
        AND  xmrih.shipped_locat_id  = xilv1.inventory_location_id
        AND  (
              xmrih.shipped_locat_code = gt_param.shiped_code
          OR  xilv1.distribution_block = gt_param.block1
          OR  xilv1.distribution_block = gt_param.block2
          OR  xilv1.distribution_block = gt_param.block3
          OR  (gt_param.block1 IS NULL) AND (gt_param.block2 IS NULL) AND (gt_param.block3 IS NULL)
            AND (gt_param.shiped_code IS NULL)
        )
        -- 出庫日関連
        AND  ( (gt_param.shiped_date_to IS NULL
                -- パラメータ.出庫日Fromのみ指定された場合
               AND  xmrih.schedule_ship_date >= TRUNC(gt_param.shiped_date_from)
          ) OR (gt_param.shiped_date_to IS NOT NULL
                -- パラメータ.出庫日From、パラメータ.出庫日Toの両方指定された場合
               AND  xmrih.schedule_ship_date >= TRUNC(gt_param.shiped_date_from)
               AND  xmrih.schedule_ship_date <= TRUNC(gt_param.shiped_date_to)
          )
        )
        -- 06:運送業者情報
        AND  xmrih.career_id         =  xcv.party_id(+)
        -- 05:OPM保管場所情報(入庫先)
        AND  xmrih.ship_to_locat_id  =  xilv2.inventory_location_id
        -- 警告区分関連
        AND  (
               (gt_param.warning IS NULL
          ) OR (gt_param.warning = gc_warn_kbn_over   --「積載(OVER)」
                --重量容積区分:重量
                AND  (xmrih.weight_capacity_class = gc_wei_cap_kbn_w
                    AND (xmrih.loading_efficiency_weight > 100
                      OR ((xcs.loading_efficiency_weight > 100) OR (xcs.delivery_no IS NULL))
                    )
                --重量容積区分:容積
                ) OR (xmrih.weight_capacity_class = gc_wei_cap_kbn_c
                    AND (xmrih.loading_efficiency_capacity > 100
                      OR ((xcs.loading_efficiency_capacity > 100) OR (xcs.delivery_no IS NULL))
                    )
                )
              
          ) OR (gt_param.warning = gc_warn_kbn_low   --「積載(LOW)」
                --重量容積区分:重量
                AND  (xmrih.weight_capacity_class = gc_wei_cap_kbn_w
                  AND (xmrih.loading_efficiency_weight < gv_le_threshold
                    OR ((xcs.loading_efficiency_weight < gv_le_threshold)
                      OR (xcs.delivery_no IS NULL))
                  )
                --重量容積区分:容積
                ) OR (xmrih.weight_capacity_class = gc_wei_cap_kbn_c
                  AND (xmrih.loading_efficiency_capacity < gv_le_threshold
                    OR ((xcs.loading_efficiency_capacity < gv_le_threshold)
                      OR (xcs.delivery_no IS NULL))
                  )
                )
          ) OR (gt_param.warning = gc_warn_kbn_lot   --「ロット逆転」
                AND xmril.warning_class = gc_warn_kbn_lot
          ) OR (gt_param.warning = gc_warn_kbn_fresh--「鮮度不備」
                AND xmril.warning_class = gc_warn_kbn_fresh
          )
        )
        -- 09:配送区分情報
        AND  xmrih.shipping_method_code  =  xsmv.ship_method_code(+)  -- 6/20 外部結合追加
        ----------------------------------------------------------------------------------
        -- 明細情報
        ----------------------------------------------------------------------------------
        -- 02:移動依頼/指示明細(アドオン)
        AND  xmrih.mov_hdr_id   = xmril.mov_hdr_id
        AND  xmril.delete_flg  <> gc_delete_flg    --取消フラグ
        -- 07:OPM品目情報
        AND  xmril.item_id = ximv.item_id
        -- 08:OPM品目カテゴリ割当情報
        AND  xmril.item_id = xicv.item_id
        AND  xicv.prod_class_code = gv_prod_kbn
        ----------------------------------------------------------------------------------
        -- クイックコード
        ----------------------------------------------------------------------------------
        -- 10:クイックコード(運賃区分)
        -- MOD START 2008/06/04 NAKADA クイックコードとの結合を外部結合に修正
        AND  xlv1.lookup_type(+) = gc_lookup_cd_freight
        AND  xmrih.freight_charge_class = xlv1.lookup_code(+)
        -- 11:クイックコード(警告区分)
        AND  xlv2.lookup_type(+) = gc_lookup_cd_warn
        AND  xmril.warning_class = xlv2.lookup_code(+)
        -- MOD END   2008/06/04 NAKADA 
        ----------------------------------------------------------------------------------
        -- アドオンマスタ適用日
        ----------------------------------------------------------------------------------
        -- 06:運送業者情報
        AND  (xcv.party_id IS NULL
          OR (   TRUNC(xcv.start_date_active)  <= TRUNC(gt_param.shiped_date_from)
            AND  (xcv.end_date_active IS NULL
              OR  TRUNC(xcv.end_date_active) >= TRUNC(gt_param.shiped_date_from))
          )
        )
        -- 07:OPM品目情報
        AND  TRUNC(ximv.start_date_active) <= TRUNC(gt_param.shiped_date_from)
        AND  (ximv.start_date_active IS NULL
          OR  TRUNC(ximv.end_date_active) >= TRUNC(gt_param.shiped_date_from))
      ORDER BY
             shiped_code      ASC   -- 出庫元（コード）
            ,shiped_date      ASC   -- 出庫日
            ,arrive_date      ASC   -- 着日
            ,delivery_no      ASC   -- 配送No
            ,base_code        ASC   -- 管轄拠点
            ,delivery_to_code ASC   -- 配送先
            ,req_move_no      ASC   -- 依頼No/移動No
            ,item_code        ASC   -- 品目コード
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
    gv_dept_cd := SUBSTRB(xxcmn_common_pkg.get_user_dept(gv_user_id), 1, 10) ;
    -- 担当者
    gv_dept_nm := SUBSTRB(xxcmn_common_pkg.get_user_name(gv_user_id), 1, 14) ;
--
    -- ====================================================
    -- 警告区分名称取得
    -- ====================================================
    -- 積載(OVER)の名称を取得
    SELECT xlvv.meaning
    INTO   gv_warning_over
    FROM   xxcmn_lookup_values2_v xlvv
    WHERE  xlvv.lookup_type = gc_lookup_cd_warn
      AND  xlvv.lookup_code = gc_warn_kbn_over ;
--
    -- 積載(LOW)の名称を取得
    SELECT xlvv.meaning
    INTO   gv_warning_low
    FROM   xxcmn_lookup_values2_v xlvv
    WHERE  xlvv.lookup_type = gc_lookup_cd_warn
      AND  xlvv.lookup_code = gc_warn_kbn_low ;
--
    -- ====================================================
    -- 帳票データ取得
    -- ====================================================
    -- 「出荷」が指定された場合
    IF ((gt_param.biz_type = gc_biz_type_cd_ship) OR (gt_param.biz_type IS NULL)) THEN
      -- 出荷依頼情報取得
      OPEN cur_ship_data ;
      FETCH cur_ship_data BULK COLLECT INTO gt_report_data_ship ;
      CLOSE cur_ship_data ;
    END IF;
--
    -- 「移動」が指定された場合
    IF ((gt_param.biz_type = gc_biz_type_cd_move) OR (gt_param.biz_type IS NULL)) THEN
      -- 移動依頼情報取得
      OPEN cur_move_data ;
      FETCH cur_move_data BULK COLLECT INTO gt_report_data_move ;
      CLOSE cur_move_data ;
    END IF;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      IF ( cur_ship_data%ISOPEN ) THEN
        CLOSE cur_ship_data ;
      END IF ;
      IF ( cur_move_data%ISOPEN ) THEN
        CLOSE cur_move_data ;
      END IF ;
      ov_errbuf  := SUBSTRB(gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      IF ( cur_ship_data%ISOPEN ) THEN
        CLOSE cur_ship_data ;
      END IF ;
      IF ( cur_move_data%ISOPEN ) THEN
        CLOSE cur_move_data ;
      END IF ;
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      IF ( cur_ship_data%ISOPEN ) THEN
        CLOSE cur_ship_data ;
      END IF ;
      IF ( cur_move_data%ISOPEN ) THEN
        CLOSE cur_move_data ;
      END IF ;
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END prc_get_report_data;
--
  /**********************************************************************************
   * Procedure Name   : prc_set_xml_data_cmn
   * Description      : XMLデータ設定(出荷・移動共通)
   ***********************************************************************************/
  PROCEDURE prc_set_xml_data_cmn(
     it_data    IN  list_report_data
  )
  IS
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル変数 ***
    -- 前回レコード格納用
    lv_tmp_biz_type         type_report_data.biz_type%TYPE DEFAULT NULL ;        -- 業務種別
    lv_tmp_shiped_cd        type_report_data.shiped_code%TYPE DEFAULT NULL ;     -- 出庫元コード
    lv_tmp_shiped_date      type_report_data.shiped_date%TYPE DEFAULT NULL ;     -- 出庫日
    lv_tmp_delivery_no      type_report_data.delivery_no%TYPE DEFAULT NULL ;     -- 配送No
    lv_tmp_req_move_no      type_report_data.req_move_no%TYPE DEFAULT NULL ;     -- 依頼No/移動No
    lv_tmp_base_code        type_report_data.base_code%TYPE DEFAULT NULL ;       -- 管轄拠点コード
    lv_tmp_deli_to_code     type_report_data.delivery_to_code%TYPE DEFAULT NULL ;-- 配送先
--
    -- タグ出力判定フラグ
    lb_dispflg_biz_type     BOOLEAN DEFAULT TRUE ;       -- 業務種別
    lb_dispflg_shiped_cd    BOOLEAN DEFAULT TRUE ;       -- 出庫元コード
    lb_dispflg_shiped_date  BOOLEAN DEFAULT TRUE ;       -- 出庫日
    lb_dispflg_delivery_no  BOOLEAN DEFAULT TRUE ;       -- 配送No
    lb_dispflg_req_move_no  BOOLEAN DEFAULT TRUE ;       -- 依頼No/移動No
--
    -- 合計算出用
    ln_sum_qty              NUMBER DEFAULT 0 ;      -- 数量合計
    ln_sum_pallet_qty       NUMBER DEFAULT 0 ;      -- パレット枚数合計
    ln_sum_weight           NUMBER DEFAULT 0 ;      -- 積載重量合計
    ln_sum_capacity         NUMBER DEFAULT 0 ;      -- 積載容積合計
--
  BEGIN
--
    -- -----------------------------------------------------
    -- XMLデータ作成
    -- -----------------------------------------------------
    <<set_data_loop>>
    FOR i IN 1..it_data.COUNT LOOP
--
      -- ====================================================
      -- XMLデータ設定
      -- ====================================================
      -- ヘッダ部(業務種別グループ)
      IF (lb_dispflg_biz_type) THEN
        prc_set_tag_data('g_business_info') ;
        prc_set_tag_data('report_id'       , gc_report_id);
        prc_set_tag_data('exec_time'       , TO_CHAR(SYSDATE, gc_date_fmt_all));
        prc_set_tag_data('dep_cd'          , gv_dept_cd);
        prc_set_tag_data('dep_nm'          , gv_dept_nm);
        prc_set_tag_data('shiped_date_from', TO_CHAR(gt_param.shiped_date_from,gc_date_fmt_ymd_ja));
        prc_set_tag_data('shiped_date_to'  , TO_CHAR(gt_param.shiped_date_to,gc_date_fmt_ymd_ja));
        prc_set_tag_data('business_type'   , it_data(i).biz_type);
        prc_set_tag_data('lg_shiped_cd_info') ;
      END IF ;
--
      -- ヘッダ部(出庫元グループ)
      IF (lb_dispflg_shiped_cd) THEN
        prc_set_tag_data('g_shiped_cd_info');
        prc_set_tag_data('shiped_cd', it_data(i).shiped_code);
        prc_set_tag_data('shiped_nm', it_data(i).shiped_name);
        prc_set_tag_data('lg_shiped_date_info');
      END IF ;
--
      -- ヘッダ部(出庫日グループ)
      IF (lb_dispflg_shiped_date) THEN
        prc_set_tag_data('g_shiped_date_info');
        prc_set_tag_data('shiped_date', TO_CHAR(it_data(i).shiped_date, gc_date_fmt_ymd));
        prc_set_tag_data('lg_delivery_info');
      END IF ;
--
      -- 明細部(配送Noグループ)
      IF (lb_dispflg_delivery_no) THEN
        prc_set_tag_data('g_delivery_info');
        prc_set_tag_data('delivery_no'    , it_data(i).delivery_no);
        prc_set_tag_data('arrive_date'    , TO_CHAR(it_data(i).arrive_date, gc_date_fmt_ymd));
        prc_set_tag_data('delivery_kbn'   , it_data(i).shipping_method_code);
        prc_set_tag_data('delivery_nm'    , it_data(i).shipping_method_name);
-- 2008/07/03 A.Shiina v1.3 Update Start
       IF  ((it_data(i).freight_charge_code  = '1')
        OR (it_data(i).complusion_output_kbn = '1')) THEN
        prc_set_tag_data('carrier_cd'     , it_data(i).career_code);
        prc_set_tag_data('carrier_nm'     , it_data(i).career_name);
       END IF;
-- 2008/07/03 A.Shiina v1.3 Update End
        prc_set_tag_data('freight_kbn_nm' , it_data(i).freight_charge_name);
        prc_set_tag_data('lg_req_move_info');
      END IF ;
--
      -- 明細部(依頼No/移動Noグループ)
      IF (lb_dispflg_req_move_no) THEN
        prc_set_tag_data('g_req_move_info');
        prc_set_tag_data('req_move_no'         , it_data(i).req_move_no);
        prc_set_tag_data('modify_kbn'          , it_data(i).modify_flg);
        prc_set_tag_data('shiped_type'         , it_data(i).shiped_form);
        prc_set_tag_data('time_from'           , it_data(i).time_from);
        prc_set_tag_data('time_to'             , it_data(i).time_to);
        prc_set_tag_data('mixed_no'            , it_data(i).mixed_no);
        prc_set_tag_data('collected_pallet_qty', it_data(i).collected_pallet_qty);
        prc_set_tag_data('po_number'           , it_data(i).po_number);
        prc_set_tag_data('confirm_request'     , it_data(i).confirm_request);
        prc_set_tag_data('tekiyo'              , it_data(i).description);
--
        -- 管轄拠点情報が前回レコードと異なる場合のみ出力
        IF ((lv_tmp_base_code != it_data(i).base_code) OR lb_dispflg_delivery_no)  THEN
          prc_set_tag_data('sales_branch_cd'    , it_data(i).base_code);
          prc_set_tag_data('sales_branch_nm'    , it_data(i).base_name);
        END IF;
--
        -- 配送先情報が前回レコードと異なる場合のみ出力
        IF ((lv_tmp_deli_to_code != it_data(i).delivery_to_code) OR lb_dispflg_delivery_no)  THEN
          prc_set_tag_data('delivery_to_cd'     , it_data(i).delivery_to_code);
          prc_set_tag_data('delivery_to_nm'     , it_data(i).delivery_to_name);
          prc_set_tag_data('delivery_to_address', it_data(i).delivery_to_address);
          prc_set_tag_data('delivery_to_phone'  , it_data(i).delivery_to_phone);
        END IF;
--
        prc_set_tag_data('lg_item_info');
      END IF ;
--
      -- 明細部(品目コードグループ)
      prc_set_tag_data('g_item_info');
      prc_set_tag_data('item_cd'   , it_data(i).item_code);
      prc_set_tag_data('item_nm'   , it_data(i).item_name);
      prc_set_tag_data('qty'       , it_data(i).qty);
      prc_set_tag_data('qty_tani'  , it_data(i).qty_tani);
      prc_set_tag_data('pallet_qty', it_data(i).pallet_quantity);
      prc_set_tag_data('layer_qty' , it_data(i).layer_quantity);
      prc_set_tag_data('case_qty'  , it_data(i).case_quantity);
      prc_set_tag_data('warning'   , it_data(i).warning);
      prc_set_tag_data('/g_item_info');
--
      -- ====================================================
      -- 現在処理中のデータを保持
      -- ====================================================
      lv_tmp_biz_type     := it_data(i).biz_type ;
      lv_tmp_shiped_cd    := it_data(i).shiped_code ;
      lv_tmp_shiped_date  := it_data(i).shiped_date ;
      lv_tmp_delivery_no  := it_data(i).delivery_no ;
      lv_tmp_req_move_no  := it_data(i).req_move_no ;
      lv_tmp_base_code    := it_data(i).base_code ;
      lv_tmp_deli_to_code := it_data(i).delivery_to_code ;
--
      -- ====================================================
      -- 出力判定
      -- ====================================================
      IF (i < it_data.COUNT) THEN
--
        -- 依頼No/移動No
        IF (lv_tmp_req_move_no = it_data(i + 1).req_move_no) THEN
          lb_dispflg_req_move_no := FALSE ;
        ELSE
          lb_dispflg_req_move_no := TRUE ;
        END IF ;
--
        -- 配送No
--mod start 1.5
--        IF (NVL(lv_tmp_delivery_no,'NULL') = NVL(it_data(i + 1).delivery_no,'NULL')) THEN
        IF (lv_tmp_delivery_no = it_data(i + 1).delivery_no) THEN
--mod end 1.5
          --配送Noが設定されており、前レコードと同じ場合は同一グループ
          lb_dispflg_delivery_no := FALSE ;
--add start 1.5
        ELSIF (it_data(i + 1).delivery_no IS NULL AND lb_dispflg_req_move_no = FALSE) THEN
          --配送Noが未設定で、依頼Noが前レコードと同じ場合は同一グループ
          lb_dispflg_delivery_no := FALSE ;
--add end 1.5
        ELSE
          --上記以外(配送Noが異なる、配送Noが未設定で依頼Noが前レコードと同じ)は別グループ
          lb_dispflg_delivery_no := TRUE ;
          lb_dispflg_req_move_no := TRUE ;
        END IF ;
--
        -- 出庫日
        IF (lv_tmp_shiped_date = it_data(i + 1).shiped_date) THEN
          lb_dispflg_shiped_date := FALSE ;
        ELSE
          lb_dispflg_shiped_date := TRUE ;
          lb_dispflg_delivery_no := TRUE ;
          lb_dispflg_req_move_no := TRUE ;
        END IF ;
--
        -- 出庫元コード
        IF (lv_tmp_shiped_cd = it_data(i + 1).shiped_code) THEN
          lb_dispflg_shiped_cd   := FALSE ;
        ELSE
          lb_dispflg_shiped_cd   := TRUE ;
          lb_dispflg_shiped_date := TRUE ;
          lb_dispflg_delivery_no := TRUE ;
          lb_dispflg_req_move_no := TRUE ;
        END IF ;
--
        -- 業務種別
        IF (lv_tmp_biz_type = it_data(i + 1).biz_type) THEN
          lb_dispflg_biz_type    := FALSE ;
        ELSE
          lb_dispflg_biz_type    := TRUE ;
          lb_dispflg_shiped_cd   := TRUE ;
          lb_dispflg_shiped_date := TRUE ;
          lb_dispflg_delivery_no := TRUE ;
          lb_dispflg_req_move_no := TRUE ;
        END IF ;
--
      ELSE
          lb_dispflg_biz_type    := TRUE ;
          lb_dispflg_shiped_cd   := TRUE ;
          lb_dispflg_shiped_date := TRUE ;
          lb_dispflg_delivery_no := TRUE ;
          lb_dispflg_req_move_no := TRUE ;
      END IF;
--
      -- ====================================================
      -- 終了タグ設定
      -- ====================================================
      IF (lb_dispflg_req_move_no) THEN
--
        prc_set_tag_data('/lg_item_info') ;
        prc_set_tag_data('req_sum_pallet_qty'  , it_data(i).req_sum_pallet_qty);
--
        -- -----------------------------------------------------
        -- 依頼No単位合計項目設定
        -- -----------------------------------------------------
        -- 重量の場合
        IF (it_data(i).wei_cap_kbn = gc_wei_cap_kbn_w) THEN
          prc_set_tag_data('req_sum_wei_cap'     , it_data(i).req_sum_weight);
          prc_set_tag_data('req_sum_wei_cap_tani', gv_weight_uom);
          prc_set_tag_data('req_sum_efficiency'  , it_data(i).req_eff_weight);
          prc_set_tag_data('req_warning'         , fnc_warning_judg(it_data(i).req_eff_weight));
--
          -- 配送No合計項目加算
          ln_sum_weight := ln_sum_weight + it_data(i).req_sum_weight ;
--
        -- 容積の場合
        ELSIF (it_data(i).wei_cap_kbn = gc_wei_cap_kbn_c) THEN
          prc_set_tag_data('req_sum_wei_cap'     , it_data(i).req_sum_capacity);
          prc_set_tag_data('req_sum_wei_cap_tani', gv_capacity_uom);
          prc_set_tag_data('req_sum_efficiency'  , it_data(i).req_eff_capacity);
          prc_set_tag_data('req_warning'         , fnc_warning_judg(it_data(i).req_eff_capacity) );
--
          -- 配送No合計項目加算
          ln_sum_capacity := ln_sum_capacity + it_data(i).req_sum_capacity ;
--
        END IF;
--
        -- パレット枚数合計項目加算
        ln_sum_pallet_qty := ln_sum_pallet_qty + it_data(i).req_sum_pallet_qty ;
--
        prc_set_tag_data('/g_req_move_info') ;
      END IF;
--
      IF (lb_dispflg_delivery_no) THEN
        prc_set_tag_data('/lg_req_move_info') ;
--
        -- -----------------------------------------------------
        -- 配送No単位合計項目設定
        -- -----------------------------------------------------
        prc_set_tag_data('deli_sum_pallet_qty'    , ln_sum_pallet_qty);
        prc_set_tag_data('deli_sum_weight'        , ln_sum_weight);
        prc_set_tag_data('deli_sum_weight_tani'   , gv_weight_uom);
        prc_set_tag_data('deli_sum_capacity'      , ln_sum_capacity);
        prc_set_tag_data('deli_sum_capacity_tani' , gv_capacity_uom);
        prc_set_tag_data('deli_sum_eff_weight'    , it_data(i).deli_eff_weight);
        prc_set_tag_data('deli_sum_eff_capacity'  , it_data(i).deli_eff_capacity);
        prc_set_tag_data('deli_warning'
          ,fnc_warning_judg(it_data(i).deli_eff_weight + it_data(i).deli_eff_capacity) );
        prc_set_tag_data('/g_delivery_info') ;
--
        -- -----------------------------------------------------
        -- 合計変数初期化
        -- -----------------------------------------------------
        ln_sum_qty        := 0 ;
        ln_sum_pallet_qty := 0 ;
        ln_sum_weight     := 0 ;
        ln_sum_capacity   := 0 ;
--
      END IF;
--
      IF (lb_dispflg_shiped_date) THEN
        prc_set_tag_data('/lg_delivery_info') ;
        prc_set_tag_data('/g_shiped_date_info') ;
      END IF;
--
      IF (lb_dispflg_shiped_cd) THEN
        prc_set_tag_data('/lg_shiped_date_info') ;
        prc_set_tag_data('/g_shiped_cd_info') ;
      END IF;
--
      IF (lb_dispflg_biz_type) THEN
        prc_set_tag_data('/lg_shiped_cd_info') ;
        prc_set_tag_data('/g_business_info') ;
      END IF;
--
    END LOOP set_data_loop;
--
  END prc_set_xml_data_cmn ;
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
    prc_set_tag_data('lg_business_info') ;
--
    -- -----------------------------------------------------
    -- 帳票0件用XMLデータ作成
    -- -----------------------------------------------------
    IF ((gt_report_data_ship.COUNT = 0) AND (gt_report_data_move.COUNT = 0)) THEN
      ov_retcode := gv_status_warn ;
      ov_errmsg  := xxcmn_common_pkg.get_msg(gc_application_cmn, gc_msg_id_no_data) ;
--
      prc_set_tag_data('g_business_info') ;
      prc_set_tag_data('lg_shiped_cd_info') ;
      prc_set_tag_data('g_shiped_cd_info') ;
      prc_set_tag_data('lg_shiped_date_info') ;
      prc_set_tag_data('g_shiped_date_info') ;
      prc_set_tag_data('msg' , ov_errmsg) ;
      prc_set_tag_data('/g_shiped_date_info') ;
      prc_set_tag_data('/lg_shiped_date_info') ;
      prc_set_tag_data('/g_shiped_cd_info') ;
      prc_set_tag_data('/lg_shiped_cd_info') ;
      prc_set_tag_data('/g_business_info');
    END IF ;
--
    -- -----------------------------------------------------
    -- XMLデータ作成
    -- -----------------------------------------------------
    -- 出荷依頼情報設定
    prc_set_xml_data_cmn(gt_report_data_ship);
    -- 移動依頼情報設定
    prc_set_xml_data_cmn(gt_report_data_move);
--
    -- ====================================================
    -- 終了タグ設定
    -- ====================================================
    prc_set_tag_data('/lg_business_info') ;
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
    ir_xml  IN xml_rec
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
      lv_data :=
    '<'|| ir_xml.tag_name || '><![CDATA[' || ir_xml.tag_value || ']]></' || ir_xml.tag_name || '>';
    ELSE
      lv_data := '<' || ir_xml.tag_name || '>';
    END IF ;
--
    RETURN(lv_data);
--
  END fnc_convert_into_xml;
--
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
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '<?xml version="1.0" encoding="shift_jis" ?>' ) ;
--
    -- XMLデータ部出力
    <<xml_loop>>
    FOR i IN 1 .. gt_xml_data_table.COUNT LOOP
      -- XMLデータ出力
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, fnc_convert_into_xml(gt_xml_data_table(i)) ) ;
    END LOOP xml_loop ;
--
    --XMLデータ削除
    gt_xml_data_table.DELETE ;
--
    IF ((lv_retcode = gv_status_warn)
      AND (gt_report_data_ship.COUNT = 0) AND (gt_report_data_move.COUNT = 0)) THEN
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
    ,iv_concurrent_id       IN     VARCHAR2      -- 01:コンカレントID
    ,iv_biz_type            IN     VARCHAR2      -- 02:業務種別
    ,iv_block1              IN     VARCHAR2      -- 03:ブロック1
    ,iv_block2              IN     VARCHAR2      -- 04:ブロック2
    ,iv_block3              IN     VARCHAR2      -- 05:ブロック3
    ,iv_shiped_code         IN     VARCHAR2      -- 06:出庫元
    ,iv_shiped_date_from    IN     VARCHAR2      -- 07:出庫日From  ※必須
    ,iv_shiped_date_to      IN     VARCHAR2      -- 08:出庫日To
    ,iv_shiped_form         IN     VARCHAR2      -- 09:出庫形態
    ,iv_confirm_request     IN     VARCHAR2      -- 10:確認依頼
    ,iv_warning             IN     VARCHAR2      -- 11:警告
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
    gt_param.concurrent_id     :=  iv_concurrent_id ;                  -- 01:コンカレントID
    gt_param.biz_type          :=  iv_biz_type ;                       -- 02:業務種別
    gt_param.block1            :=  iv_block1 ;                         -- 03:ブロック1
    gt_param.block2            :=  iv_block2 ;                         -- 04:ブロック2
    gt_param.block3            :=  iv_block3 ;                         -- 05:ブロック3
    gt_param.shiped_code       :=  iv_shiped_code ;                    -- 06:出庫元
    gt_param.shiped_date_from  :=  fnc_chg_date(iv_shiped_date_from) ; -- 07:出庫日From
    gt_param.shiped_date_to    :=  fnc_chg_date(SUBSTR(iv_shiped_date_to, 1, 10)) ; -- 08:出庫日To
    gt_param.shiped_form       :=  iv_shiped_form ;                    -- 09:出庫形態
    gt_param.confirm_request   :=  iv_confirm_request ;                -- 10:確認依頼
    gt_param.warning           :=  iv_warning ;                        -- 11:警告
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
END xxwsh620006c;
/
