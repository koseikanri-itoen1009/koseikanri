CREATE OR REPLACE PACKAGE BODY XXINV550003C
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : XXINV550003C(body)
 * Description      : 計画・移動・在庫：在庫(帳票)
 * MD.050/070       : T_MD050_BPO_550_在庫(帳票)Issue1.0 (T_MD050_BPO_550)
 *                  : 振替明細表                         (T_MD070_BPO_55C)
 * Version          : 1.0
 * Program List
 * --------------------------- ----------------------------------------------------------
 *  Name                        Description
 * --------------------------- ----------------------------------------------------------
 *  prc_check_param_info        パラメータチェック(C-1)
 *  funk_item_ctl_chk           品目のパラメータ相関チェック (C1)
 *  prc_get_prod_pay_data       PROD:生産払出データ取得プロシージャ(C2)
 *  prc_get_prod_rcv_data       PROD:生産受入データ取得プロシージャ(C2)
 *  prc_get_adji_data           ADJI:在庫調整(受払)データ取得プロシージャ(C2)
 *  prc_get_omso_porc_data      OSMO:見本出庫/廃棄 PORC･RMA:見本出庫取消/廃棄取消(C2)
 *  prc_get_data_to_tmp_table   データ加工・中間テーブル更新プロシージャ(C2)
 *  prc_get_data_from_tmp_table データ取得(最終出力データ)プロシージャ(C2)
 *  prc_create_xml_data         ＸＭＬデータ作成(C-3/C-4)
 *  convert_into_xml            XMLデータ変換
 *  submain                     メイン処理プロシージャ
 *  main                        コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/2/18     1.0  Yusuke Tabata    新規作成
 *  2008/5/06     1.1  Yusuke Tabata    変更要求対応(Seq7/31)
 *                                      内部変更要求対応(Seq)
 *  2008/6/03     1.2  Takao Ohashi     結合テスト不具合
 *  2008/6/06     1.3  Takao Ohashi     結合テスト不具合
 *  2008/6/17     1.4  Kazuo Kumamoto   結合テスト不具合(ソート順変更・受入だけの伝票は先に出力)
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
  -- ======================================================
  -- ユーザー宣言部
  -- ======================================================
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
--
  gv_pkg_name               CONSTANT VARCHAR2(20) := 'XXINV550003C' ;   -- パッケージ名
  gc_report_id              CONSTANT VARCHAR2(12) := 'XXINV550003T' ;   -- 帳票ID
  gc_language_code          CONSTANT VARCHAR2(2)  := 'JA' ;             -- 共通LANGUAGE_CODE
--
  -- OPM品目カテゴリ割当：品目区分
  gc_item_ctl_mtl           CONSTANT VARCHAR2(1)  := '1';               -- 原料
  gc_item_ctl_haif_prd      CONSTANT VARCHAR2(1)  := '4';               -- 半製品
  gc_item_ctl_prd           CONSTANT VARCHAR2(1)  := '5';               -- 製品
  -- OPM品目カテゴリ割当：カテゴリ名
  gc_category_name_item_ctl CONSTANT VARCHAR2(8)  := '品目区分' ;       -- 品目区分
  -- OPM保留在庫トランザクション：ラインタイプ
  gc_line_type_pay          CONSTANT NUMBER       := -1 ;               -- 払
  gc_line_type_rcv          CONSTANT NUMBER       :=  1 ;               -- 受
  -- OPM保留在庫トランザクション：完了フラグ
  gc_comp_ind_on            CONSTANT NUMBER       :=  1 ;               -- 完了
  -- 受払区分アドオンマスタ：文書タイプ
  gc_doc_type_prod          CONSTANT VARCHAR2(4)  :='PROD' ;            -- 生産
  gc_doc_type_adji          CONSTANT VARCHAR2(4)  :='ADJI' ;            -- 在庫調整
  gc_doc_type_omso          CONSTANT VARCHAR2(4)  :='OMSO' ;            -- 見本出庫
  gc_doc_type_porc          CONSTANT VARCHAR2(4)  :='PORC' ;            -- 廃棄(出荷)
  -- 受払区分アドオンマスタ：ソース文書タイプ
  gc_source_doc_type_rma    CONSTANT VARCHAR2(4)  :='RMA' ;             -- 生産
  -- 受払区分アドオンマスタ：払出品目区分
  gc_item_class_code_1      CONSTANT VARCHAR2(1)  := '1' ;              -- 原料
  gc_item_class_code_4      CONSTANT VARCHAR2(1)  := '4' ;              -- 半製品
  gc_item_class_code_5      CONSTANT VARCHAR2(1)  := '5' ;              -- 製品
  -- 受払区分アドオンマスタ：在庫帳票使用区分
  gc_use_div_invent_rep     CONSTANT VARCHAR2(1)  := 'Y' ;              -- 使用
  -- 受払区分アドオンマスタ：在庫調整区分
  gc_stock_adjst_div_sa     CONSTANT VARCHAR2(1)  := '2' ;              -- 在庫調整
  -- GME生産バッチヘッダ：バッチステータス
  gc_batch_status_close     CONSTANT VARCHAR2(1)  := '4' ;              -- クローズ済
  -- 工順マスタ：工順区分
  gc_routing_class_61       CONSTANT VARCHAR2(2)  :='61' ;              -- 返品原料
  gc_routing_class_62       CONSTANT VARCHAR2(2)  :='62' ;              -- 解体半製品
  gc_routing_class_70       CONSTANT VARCHAR2(2)  :='70' ;              -- 品目振替
  -- OPM品目情報VIEW2：原価管理区分
  gc_cost_manage_code_n     CONSTANT VARCHAR2(1)  := '1' ;              -- 原価管理:標準
  gc_cost_manage_code_j     CONSTANT VARCHAR2(1)  := '0' ;              -- 原価管理:実勢
  -- 標準原価VIEW：原価0
  gc_cost_0                 CONSTANT NUMBER       := 0 ;                -- 出力用：0円
  -- クイックコード:参照タイプコード
  gc_lookup_type_new_div    CONSTANT VARCHAR2(18) := 'XXCMN_NEW_DIVISION' ; -- 新区分
  gc_apl_code               CONSTANT VARCHAR2(3)  := 'FND' ;                -- クイックコード用
  -- 日付型マスク
  gc_date_mask              CONSTANT VARCHAR2(21) := 'YYYY/MM/DD HH24:MI:SS' ; -- 日付型マスク
  gc_date_mask_s            CONSTANT VARCHAR2(21) := 'YYYY/MM/DD' ;            -- 日付型マスク
  gc_date_mask_jp           CONSTANT VARCHAR2(19) := 'YYYY"年"MM"月"DD"日' ;   -- 日付型マスク(年月日)
  -- メッセージ
  gc_application_cmn        CONSTANT VARCHAR2(5)  := 'XXCMN' ;           -- アドオン：マスタ・経理・共通
  gc_err_code_data_0        CONSTANT VARCHAR2(15) := 'APP-XXCMN-10122' ; -- データ０件メッセージ
  gc_application_inv        CONSTANT VARCHAR2(5)  := 'XXINV' ;           -- アドオン：計画・移動・在庫
  gc_err_code_unt_valid     CONSTANT VARCHAR2(15) := 'APP-XXINV-10155' ; -- 品目区分指定エラー
  gc_err_code_dpnd_valid    CONSTANT VARCHAR2(15) := 'APP-XXINV-10156' ; -- 品目区分相関エラー
  -- 出力
  gc_tag_type_t           CONSTANT VARCHAR2(1)  := 'T' ;
  gc_tag_type_d           CONSTANT VARCHAR2(1)  := 'D' ;
  -- プロファイル
  gc_routing_class          CONSTANT VARCHAR2(19) := 'XXINV_DUMMY_ROUTING' ;          -- 品目振替
  gc_routing_class_ret      CONSTANT VARCHAR2(23) := 'XXINV_DUMMY_ROUTING_RET' ;      -- 返品原料
  gc_routing_class_separate CONSTANT VARCHAR2(29) := 'XXINV_DUMMY_ROUTING_SEPARATE' ; -- 解体半製品
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
--
  -- 入力パラメータ格納用レコード変数
  TYPE rec_param_data  IS RECORD 
    (
       date_from           gme_batch_header.actual_cmplt_date%TYPE            -- 01 : 年月日_FROM
      ,date_to             gme_batch_header.actual_cmplt_date%TYPE            -- 02 : 年月日_TO
      ,out_item_ctl        xxcmn_lookup_values_v.lookup_code%TYPE             -- 03 : 払出品目区分
      ,item1               xxcmn_item_mst_v.item_id%TYPE                      -- 04 : 品目コード1
      ,item2               xxcmn_item_mst_v.item_id%TYPE                      -- 05 : 品目コード2
      ,item3               xxcmn_item_mst_v.item_id%TYPE                      -- 06 : 品目コード3
      ,reason_code         xxcmn_lookup_values_v.lookup_code%TYPE             -- 07 : 事由コード
      ,item_location_id    xxcmn_item_locations_v.inventory_location_id%TYPE  -- 08 : 保管倉庫ID
      ,dept_id             xxcmn_locations_v.location_id%TYPE                 -- 09 : 担当部署ID
      ,entry_no1           gme_batch_header.batch_no%TYPE                     -- 10 : 伝票No1
      ,entry_no2           gme_batch_header.batch_no%TYPE                     -- 11 : 伝票No2
      ,entry_no3           gme_batch_header.batch_no%TYPE                     -- 12 : 伝票No3
      ,entry_no4           gme_batch_header.batch_no%TYPE                     -- 13 : 伝票No4
      ,entry_no5           gme_batch_header.batch_no%TYPE                     -- 14 : 伝票No5
      ,price_ctl_flg       VARCHAR2(1)                                        -- 15 : 金額表示
      ,emp_no              per_all_people_f.employee_number%TYPE              -- 16 : 担当者
      ,creation_date_from  DATE                                               -- 17 : 更新時間FROM
      ,creation_date_to    DATE                                               -- 18 : 更新時間TO
    ) ;
  -- 明細情報データ
  TYPE rec_data_type_dtl IS RECORD
    (
       batch_id            gme_batch_header.batch_id%TYPE                -- 生産バッチID
      ,dept_code           xxcmn_locations2_v.location_code%TYPE         -- 部署コード
      ,dept_name           xxcmn_locations2_v.description%TYPE           -- 部署名称
      ,item_location_code  xxcmn_item_locations2_v.segment1%TYPE         -- 保管倉庫コード
      ,item_location_name  xxcmn_item_locations2_v.description%TYPE      -- 保管倉庫名
      ,item_div_type       xxcmn_item_categories4_v.item_class_code%TYPE -- 品目区分コード
      ,item_div_value      xxcmn_item_categories4_v.item_class_name%TYPE -- 品目区分名称
      ,entry_no            gme_batch_header.batch_no%TYPE                -- 伝票NO
      ,entry_date          gme_batch_header.actual_cmplt_date%TYPE       -- 入出庫日
      ,pay_reason_code     xxcmn_rcv_pay_mst.new_div_invent%TYPE         -- 払出事由コード
      ,pay_reason_name     fnd_lookup_values.meaning%TYPE                -- 払出事由名称
      ,pay_item_no         xxcmn_item_mst2_v.item_no%TYPE                -- 払出品目コード
--mod start 1.2
--      ,pay_item_name       xxcmn_item_mst2_v.item_desc1%TYPE             -- 払出品目名称
      ,pay_item_name       xxcmn_item_mst2_v.item_short_name%TYPE        -- 払出品目名称
--mod end 1.2
      ,pay_lot_no          ic_lots_mst.lot_no%TYPE                       -- 払出ロットNO
      ,pay_quant           NUMBER                                        -- 払出総数
      ,pay_unt_price       ic_lots_mst.attribute7%TYPE                   -- 払出単価
      ,rcv_reason_code     xxcmn_rcv_pay_mst.new_div_invent%TYPE         -- 受入事由コード
      ,rcv_reason_name     fnd_lookup_values.meaning%TYPE                -- 受入事由名称
      ,rcv_item_no         xxcmn_item_mst2_v.item_no%TYPE                -- 受入品目コード
--mod start 1.2
--      ,rcv_item_name       xxcmn_item_mst2_v.item_desc1%TYPE             -- 受入品目名称
      ,rcv_item_name       xxcmn_item_mst2_v.item_short_name%TYPE        -- 受入品目名称
--mod end 1.2
      ,rcv_lot_no          ic_lots_mst.lot_no%TYPE                       -- 受入ロットNO
      ,rcv_quant           NUMBER                                        -- 受入総数
      ,rcv_unt_price       ic_lots_mst.attribute7%TYPE                   -- 受入単価
    ) ;
  TYPE tab_data_type_dtl IS TABLE OF rec_data_type_dtl INDEX BY BINARY_INTEGER ;
--
  gt_main_data              tab_data_type_dtl ;       -- 取得レコード表
  gt_xml_data_table         XML_DATA ;                -- ＸＭＬデータタグ表
  gl_xml_idx                NUMBER ;                  -- ＸＭＬデータタグ表のインデックス
--
  gr_param                  rec_param_data ;          -- 入力パラメータ
--
    gv_sql_date_from VARCHAR2(140) ; -- SQL文：パラメータDATE_FROM部
--
  -- ===============================
  -- ユーザー定義例外
  -- ===============================
  parameter_check_expt     EXCEPTION;     -- パラメータチェック例外
--
  /**********************************************************************************
   * Function Name    : funk_item_ctl_chk
   * Description      : 品目のパラメータの相関チェック (C1)
   *                    (IN払出品目区分)入力有：(IN品目ID)(IN品目区分)の相関精査
   *                    (IN払出品目区分)入力無：(IN品目ID)の単体精査
   *                    (OUT)エラー：TRUE
   *                    (OUT)正常：FALSE
   ***********************************************************************************/
  FUNCTION funk_item_ctl_chk
    (
      iv_item_id   IN NUMBER     -- 品目ID
     ,iv_item_ctl  IN VARCHAR2   -- 品目区分
    )RETURN BOOLEAN
  IS
    -- =====================================================
    -- 固定ローカル定数
    -- =====================================================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'funk_item_ctl_chk' ;   -- プログラム名
--
    -- =====================================================
    -- ユーザー宣言部
    -- =====================================================
    -- *** ローカル変数 ***
    lv_str1 VARCHAR2(1) ;
    lv_str2 VARCHAR2(1) ;
    lv_str3 VARCHAR2(1) ;
    ln_work NUMBER;
--
  BEGIN
--
    -- パラメータ：品目カテゴリの入力有無チェック
    IF (iv_item_ctl IS NULL) THEN
      -- 標準カテゴリをセット
      lv_str1 := gc_item_ctl_mtl;
      lv_str2 := gc_item_ctl_haif_prd;
      lv_str3 := gc_item_ctl_prd;
    ELSE
      -- 指定カテゴリをセット
      lv_str1 := iv_item_ctl;
      lv_str2 := iv_item_ctl;
      lv_str3 := iv_item_ctl;
    END IF;
--
    -- データ有無チェック
    SELECT COUNT(item_id) INTO ln_work
    FROM xxcmn_item_categories4_v
    WHERE item_class_code IN(lv_str1,lv_str2,lv_str3)
    AND item_id = iv_item_id
    AND ROWNUM = 1 ;
--
    -- 結果判定:SQL結果より戻値を生成
    IF (ln_work = 0) THEN
      RETURN TRUE ;
    ELSE 
      RETURN FALSE ;
    END IF ;
--
  END funk_item_ctl_chk ;
--
  /**********************************************************************************
   * Procedure Name   : prc_check_param_info
   * Description      : パラメータチェック(C-1)
   ***********************************************************************************/
  PROCEDURE prc_check_param_info
    (
      ov_errbuf     OUT NOCOPY VARCHAR2         -- エラー・メッセージ
     ,ov_retcode    OUT NOCOPY VARCHAR2         -- リターン・コード
     ,ov_errmsg     OUT NOCOPY VARCHAR2         -- ユーザー・エラー・メッセージ
    )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_param_info' ; -- プログラム名
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
    lv_err_code               VARCHAR2(100) ; -- エラーコード格納用
--
    -- *** ローカル・例外処理 ***
    parameter_dpnd_check_expt     EXCEPTION ;     -- パラメータチェック(相関)例外
    parameter_unt_check_expt      EXCEPTION ;     -- パラメータチェック(単体)例外
--
  BEGIN
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- パラメータ：品目1の入力有無
    IF (gr_param.item1 IS NOT NULL ) THEN
      -- 品目のパラメータの相関チェック
      IF (funk_item_ctl_chk(gr_param.item1,gr_param.out_item_ctl)) THEN
        -- パラメータ：払出品目区分の入力有無
        IF (gr_param.out_item_ctl IS NULL) THEN
          -- 単体例外
          RAISE parameter_unt_check_expt ;
        ELSE
          -- 相関例外
          RAISE parameter_dpnd_check_expt ;
        END IF ;
      END IF ;
    END IF ;
    -- パラメータ：品目2の入力有無
    IF (gr_param.item2 IS NOT NULL ) THEN
      -- 品目のパラメータの相関チェック
      IF (funk_item_ctl_chk(gr_param.item2,gr_param.out_item_ctl)) THEN
        -- パラメータ：払出品目区分の入力有無
        IF (gr_param.out_item_ctl IS NULL) THEN
          -- 単体例外
          RAISE parameter_unt_check_expt ;
        ELSE
          -- 相関例外
          RAISE parameter_dpnd_check_expt ;
        END IF ;
      END IF ;
    END IF;
    -- パラメータ：品目3の入力有無
    IF (gr_param.item3 IS NOT NULL ) THEN
      -- 品目のパラメータの相関チェック
      IF (funk_item_ctl_chk(gr_param.item3,gr_param.out_item_ctl)) THEN
        -- パラメータ：払出品目区分の入力有無
        IF (gr_param.out_item_ctl IS NULL) THEN
          -- 単体例外
          RAISE parameter_unt_check_expt ;
        ELSE
          -- 相関例外
          RAISE parameter_dpnd_check_expt ;
        END IF ;
      END IF ;
    END IF ;
--
  EXCEPTION
    --*** パラメータチェック(相関)例外 ***
    WHEN parameter_dpnd_check_expt THEN
      -- メッセージセット
      lv_errmsg := xxcmn_common_pkg.get_msg( gc_application_inv,gc_err_code_dpnd_valid ) ;
      ov_errmsg  := lv_errmsg ;
      ov_errbuf  := lv_errmsg ;
      ov_retcode := gv_status_error ;
    --*** パラメータチェック(単体)例外 ***
    WHEN parameter_unt_check_expt THEN
      -- メッセージセット
      lv_errmsg := xxcmn_common_pkg.get_msg( gc_application_inv,gc_err_code_unt_valid ) ;
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
  END prc_check_param_info ;
--
  /**********************************************************************************
   * Function Name    : convert_into_xml
   * Description      : XMLデータ変換
   ***********************************************************************************/
  FUNCTION convert_into_xml(
    iv_name  IN VARCHAR2,
    iv_value IN VARCHAR2,
    ic_type  IN CHAR
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
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    lv_convert_data VARCHAR2(2000);
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
    --データの場合
    IF (ic_type = 'D') THEN
      lv_convert_data := '<'||iv_name||'>'||iv_value||'</'||iv_name||'>';
    ELSE
      lv_convert_data := '<'||iv_name||'>';
    END IF;
--
    RETURN(lv_convert_data);
--
  END convert_into_xml;
--
   /**********************************************************************************
   * Procedure Name   : prc_get_prod_pay_data
   * Description      : PROD:生産払出データ取得プロシージャ(C2)
   ***********************************************************************************/

  PROCEDURE prc_get_prod_pay_data
    (
      ot_data_rec   OUT tab_data_type_dtl  -- 取得レコード
     ,ov_errbuf     OUT NOCOPY VARCHAR2    -- エラー・メッセージ
     ,ov_retcode    OUT NOCOPY VARCHAR2    -- リターン・コード
     ,ov_errmsg     OUT NOCOPY VARCHAR2    -- ユーザー・エラー・メッセージ
    )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_get_prod_pay_data'; -- プログラム名
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
    cv_sc CONSTANT VARCHAR2(2) := '''';
    -- *** ローカル・変数 ***
    lv_sql_body    VARCHAR2(10000);  -- SQL文：本体
    lv_work_str    VARCHAR2(100) ;   -- 作業用変数:伝票No絞込
    lv_work_str_2  VARCHAR2(100) ;   -- 作業用変数:品目絞込
    -- 工順マスタ：工順区分
    lv_routing_class          gmd_routings_b.routing_class%TYPE ;
    lv_routing_class_ret      gmd_routings_b.routing_class%TYPE ;
    lv_routing_class_separate gmd_routings_b.routing_class%TYPE ;
--
  BEGIN
--
    -- ------------------------------------------------------------------------------
    -- 初期処理
    -- ------------------------------------------------------------------------------
--
    -- 工順区分取得
--
    -- 品目振替
    SELECT grct.routing_class          -- 工順区分
    INTO   lv_routing_class
    FROM   gmd_routing_class_tl grct   -- 工順区分マスタ日本語
    WHERE  grct.routing_class_desc = FND_PROFILE.VALUE(gc_routing_class)
    AND    grct.language           = 'JA'
    ;
--
    -- 返品原料
    SELECT grct.routing_class          -- 工順区分
    INTO   lv_routing_class_ret
    FROM   gmd_routing_class_tl grct   -- 工順区分マスタ日本語
    WHERE  grct.routing_class_desc = FND_PROFILE.VALUE(gc_routing_class_ret)
    AND    grct.language           = 'JA'
    ;
--
    -- 解体半製品
    SELECT grct.routing_class          -- 工順区分
    INTO   lv_routing_class_separate
    FROM   gmd_routing_class_tl grct   -- 工順区分マスタ日本語
    WHERE  grct.routing_class_desc = FND_PROFILE.VALUE(gc_routing_class_separate)
    AND    grct.language           = 'JA'
    ;
--
    -- ------------------------------------------------------------------------------
    -- メインSQL
    -- ------------------------------------------------------------------------------
    -- SQL本体
    lv_sql_body := lv_sql_body || ' SELECT ' ;
    lv_sql_body := lv_sql_body || '  gbh.batch_id                AS batch_id' ;
    lv_sql_body := lv_sql_body || ' ,xlv.location_code           AS dept_code' ;
    lv_sql_body := lv_sql_body || ' ,xlv.description             AS dept_name' ;
    lv_sql_body := lv_sql_body || ' ,xilv.segment1               AS item_location_code' ;
    lv_sql_body := lv_sql_body || ' ,xilv.description            AS item_location_name' ;
    lv_sql_body := lv_sql_body || ' ,xicv.item_class_code        AS item_div_type' ;
    lv_sql_body := lv_sql_body || ' ,xicv.item_class_name        AS item_div_value' ;
    lv_sql_body := lv_sql_body || ' ,gbh.batch_no                AS entry_no' ;
    lv_sql_body := lv_sql_body || ' ,gbh.actual_cmplt_date       AS entry_date' ;
    lv_sql_body := lv_sql_body || ' ,xrpm.new_div_invent         AS pay_reason_code' ;
    lv_sql_body := lv_sql_body || ' ,flv.meaning                 AS pay_reason_name' ;
    lv_sql_body := lv_sql_body || ' ,ximv.item_no                AS pay_item_no' ;
--mod start 1.2
--    lv_sql_body := lv_sql_body || ' ,ximv.item_desc1             AS pay_item_name' ;
    lv_sql_body := lv_sql_body || ' ,ximv.item_short_name        AS pay_item_name' ;
--mod end 1.2
    lv_sql_body := lv_sql_body || ' ,ilm.lot_no                  AS pay_lot_no' ;
    lv_sql_body := lv_sql_body || ' ,ROUND(ABS(itp.trans_qty),4) AS pay_quant' ;
    lv_sql_body := lv_sql_body || ' ,CASE ximv.cost_manage_code' ;
    lv_sql_body := lv_sql_body || '    WHEN '|| cv_sc || gc_cost_manage_code_n || cv_sc ||' THEN' ;
    lv_sql_body := lv_sql_body || '      ROUND(xsupv.stnd_unit_price,3)' ;
    lv_sql_body := lv_sql_body || '    WHEN '|| cv_sc || gc_cost_manage_code_j || cv_sc ||' THEN' ;
--mod start 1.2
--    lv_sql_body := lv_sql_body || '      ROUND(TO_NUMBER(ilm.attribute7),3)' ;
    lv_sql_body := lv_sql_body || '      ROUND(TO_NUMBER(NVL(ilm.attribute7,0)),3)' ;
--mod end 1.2
    lv_sql_body := lv_sql_body || '    ELSE ' ;
    lv_sql_body := lv_sql_body || '      ' || gc_cost_0 ;
    lv_sql_body := lv_sql_body || '  END                         AS pay_unt_price' ;
    lv_sql_body := lv_sql_body || ' ,NULL                        AS rcv_reason_code' ;
    lv_sql_body := lv_sql_body || ' ,NULL                        AS rcv_reason_name' ;
    lv_sql_body := lv_sql_body || ' ,NULL                        AS rcv_item_no' ;
    lv_sql_body := lv_sql_body || ' ,NULL                        AS rcv_item_name' ;
    lv_sql_body := lv_sql_body || ' ,NULL                        AS rcv_lot_no' ;
    lv_sql_body := lv_sql_body || ' ,0                           AS rcv_quant' ;
    lv_sql_body := lv_sql_body || ' ,0                           AS rcv_unt_price' ;
    ---------------------------------------------------------------------------------------
    -- FROM句
    lv_sql_body := lv_sql_body || ' FROM xxcmn_item_mst2_v    ximv' ;
    lv_sql_body := lv_sql_body || ' ,xxcmn_item_categories4_v xicv' ;
    lv_sql_body := lv_sql_body || ' ,ic_lots_mst               ilm' ;
    lv_sql_body := lv_sql_body || ' ,xxinv_rcv_pay_mst2_v     xrpm' ;
    lv_sql_body := lv_sql_body || ' ,gme_batch_header          gbh' ;
    lv_sql_body := lv_sql_body || ' ,ic_tran_pnd               itp' ;
    lv_sql_body := lv_sql_body || ' ,xxcmn_item_locations2_v  xilv' ;
    lv_sql_body := lv_sql_body || ' ,xxcmn_locations2_v        xlv' ;
    lv_sql_body := lv_sql_body || ' ,fnd_lookup_values         flv' ;
    lv_sql_body := lv_sql_body || ' ,xxcmn_stnd_unit_price_v xsupv' ;
    lv_sql_body := lv_sql_body || ' ,fnd_user                   fu' ;
    lv_sql_body := lv_sql_body || ' ,per_all_assignments_f    paaf' ;
    lv_sql_body := lv_sql_body || ' ,per_all_people_f         papf' ;
    ------------------------------------------------------------
    -- WHERE句
    -- OPM保留在庫トランザクション絞込
    lv_sql_body := lv_sql_body || ' WHERE itp.line_type            = ''' || gc_line_type_pay || '''';
    lv_sql_body := lv_sql_body || ' AND itp.doc_type               = ''' || gc_doc_type_prod || '''';
    lv_sql_body := lv_sql_body || ' AND itp.completed_ind          = ''' || gc_comp_ind_on   || '''';
    lv_sql_body := lv_sql_body || ' AND itp.reverse_id             IS NULL' ;
    -- 受払区分アドオンマスタ結合
    lv_sql_body := lv_sql_body || ' AND xrpm.doc_id                = itp.doc_id';
    lv_sql_body := lv_sql_body || ' AND xrpm.doc_line              = itp.doc_line';
    lv_sql_body := lv_sql_body || ' AND xrpm.line_type             = itp.line_type';
    lv_sql_body := lv_sql_body || ' AND xrpm.use_div_invent_rep    = ''' || gc_use_div_invent_rep ||'''';
    -- 工順=返品原料/解体半製品/品目振替
    lv_sql_body := lv_sql_body || ' AND xrpm.routing_class IN(' ;
    lv_sql_body := lv_sql_body ||  '''' || lv_routing_class          || ''',' ;
    lv_sql_body := lv_sql_body ||  '''' || lv_routing_class_ret      || ''',' ;
    lv_sql_body := lv_sql_body ||  '''' || lv_routing_class_separate || ''')' ;
    -- 生産バッチ結合
    lv_sql_body := lv_sql_body || ' AND itp.doc_id                 = gbh.batch_id' ;
    lv_sql_body := lv_sql_body || ' AND gbh.batch_status           = ' || cv_sc || gc_batch_status_close ||cv_sc ;
    -- OPM品目情報VIEW結合
    lv_sql_body := lv_sql_body || ' AND itp.item_id                = ximv.item_id' ;
    lv_sql_body := lv_sql_body || ' AND ' || gv_sql_date_from || ' BETWEEN ximv.start_date_active' ;
    lv_sql_body := lv_sql_body || '                                    AND NVL(ximv.end_date_active,' || gv_sql_date_from || ')' ;
    -- OPM品目カテゴリ割当情報VIEW結合
    lv_sql_body := lv_sql_body || ' AND ximv.item_id  = xicv.item_id' ;
    lv_sql_body := lv_sql_body || ' AND xicv.item_class_code       IN (' ;
    lv_sql_body := lv_sql_body ||  '''' || gc_item_class_code_1 || ''',' ;
    lv_sql_body := lv_sql_body ||  '''' || gc_item_class_code_4 || ''',' ;
    lv_sql_body := lv_sql_body ||  '''' || gc_item_class_code_5 || ''')' ;
    -- 標準原価情報VIEW結合
    lv_sql_body := lv_sql_body || ' AND xsupv.item_id              = itp.item_id ' ;
    lv_sql_body := lv_sql_body || ' AND ' || gv_sql_date_from || ' BETWEEN NVL(xsupv.start_date_active,'|| gv_sql_date_from || ')' ;
    lv_sql_body := lv_sql_body || '                                    AND NVL(xsupv.end_date_active,'  || gv_sql_date_from || ')' ;
    -- OPMロットマスタ結合
    lv_sql_body := lv_sql_body || ' AND itp.lot_id                 = ilm.lot_id' ;
--add start 1.2
    lv_sql_body := lv_sql_body || ' AND itp.item_id                = ilm.item_id' ;
--add end 1.2
    -- クイックコード(新区分)結合
    lv_sql_body := lv_sql_body || ' AND flv.lookup_type            = ''' || gc_lookup_type_new_div || '''' ;
    lv_sql_body := lv_sql_body || ' AND flv.language               = ''' || gc_language_code       || '''';
    lv_sql_body := lv_sql_body || ' AND flv.lookup_code            = xrpm.new_div_invent ';
    -- ユーザマスタ結合
    lv_sql_body := lv_sql_body || ' AND fu.user_id                 = gbh.created_by' ;
    -- 従業員マスタ結合
    lv_sql_body := lv_sql_body || ' AND fu.employee_id             = paaf.person_id' ;
    lv_sql_body := lv_sql_body || ' AND '|| gv_sql_date_from || '  BETWEEN paaf.effective_start_date' ;
    lv_sql_body := lv_sql_body || '                                    AND paaf.effective_end_date' ;
    lv_sql_body := lv_sql_body || ' AND papf.person_id             = paaf.person_id' ;
--add start 1.2
    lv_sql_body := lv_sql_body || ' AND '|| gv_sql_date_from || '  BETWEEN papf.effective_start_date' ;
    lv_sql_body := lv_sql_body || '                                    AND papf.effective_end_date' ;
--add end 1.2
    -- 事業所情報VIEW結合
    lv_sql_body := lv_sql_body || ' AND xlv.location_id            = paaf.location_id' ;
    lv_sql_body := lv_sql_body || ' AND ' || gv_sql_date_from || ' BETWEEN NVL(xlv.start_date_active,'|| gv_sql_date_from || ')' ;
    lv_sql_body := lv_sql_body || '                                    AND NVL(xlv.end_date_active,'  || gv_sql_date_from || ')' ;
    -- OPM保管場所情報VIEW結合
    lv_sql_body := lv_sql_body || ' AND xilv.whse_code             = itp.whse_code' ;
    lv_sql_body := lv_sql_body || ' AND xilv.segment1              = itp.location' ;
    -------------------------------------------------------------------------------
    --必須パラメータ絞込
    --  1．年月日_FROM
    --  2．年月日_TO
--mod start 1.3
--    lv_sql_body := lv_sql_body || ' AND gbh.actual_cmplt_date      BETWEEN FND_DATE.STRING_TO_DATE(';
    lv_sql_body := lv_sql_body || ' AND TRUNC(gbh.actual_cmplt_date) BETWEEN FND_DATE.STRING_TO_DATE(';
--mod end 1.3
    lv_sql_body := lv_sql_body || ''''  || TO_CHAR(gr_param.date_from,gc_date_mask) || '''' ;
    lv_sql_body := lv_sql_body || ',''' || gc_date_mask || ''')' ;
    lv_sql_body := lv_sql_body || '                                    AND FND_DATE.STRING_TO_DATE(';
    lv_sql_body := lv_sql_body || ''''  || TO_CHAR(gr_param.date_to,gc_date_mask) || '''' ;
    lv_sql_body := lv_sql_body || ',''' || gc_date_mask || ''')' ;
    -------------------------------------------------------------------------------
    --  3．払出品目区分
    IF (gr_param.out_item_ctl IS NOT NULL) THEN
      lv_sql_body := lv_sql_body || ' AND xicv.item_class_code =' || cv_sc || gr_param.out_item_ctl || cv_sc;
    END IF ;
    -------------------------------------------------------------------------------
    --  7．事由コード
    IF (gr_param.reason_code IS NOT NULL) THEN
      lv_sql_body := lv_sql_body || ' AND xrpm.new_div_invent ='
                                      || cv_sc || gr_param.reason_code || cv_sc;
    END IF ;
    -------------------------------------------------------------------------------
    --  8．保管倉庫コード
    IF (gr_param.item_location_id IS NOT NULL) THEN
      lv_sql_body := lv_sql_body || ' AND xilv.inventory_location_id ='
                                      || cv_sc || gr_param.item_location_id || cv_sc;
    END IF ;
    -------------------------------------------------------------------------------
    --  9．担当部署
    IF (gr_param.dept_id IS NOT NULL) THEN
      lv_sql_body := lv_sql_body || ' AND paaf.location_id ='
                                      || cv_sc || gr_param.dept_id || cv_sc;
    END IF ;
    -------------------------------------------------------------------------------
    -- 伝票No1
    IF (gr_param.entry_no1 IS NOT NULL) THEN
      lv_work_str := cv_sc || gr_param.entry_no1 || cv_sc ;
    END IF;
    -- 伝票No2
    IF (gr_param.entry_no2 IS NOT NULL) THEN
      IF (lv_work_str IS NOT NULL) THEN
        lv_work_str := lv_work_str || ',' ;
      END IF ;
      lv_work_str := lv_work_str || cv_sc || gr_param.entry_no2 || cv_sc ;
    END IF;
    -- 伝票No3
    IF (gr_param.entry_no3 IS NOT NULL) THEN
      IF (lv_work_str IS NOT NULL) THEN
        lv_work_str := lv_work_str || ',' ;
      END IF ;
      lv_work_str := lv_work_str  || cv_sc || gr_param.entry_no3 || cv_sc ;
    END IF;
    -- 伝票No4
    IF (gr_param.entry_no4 IS NOT NULL) THEN
      IF (lv_work_str IS NOT NULL) THEN
        lv_work_str := lv_work_str || ',' ;
      END IF ;
      lv_work_str := lv_work_str  || cv_sc || gr_param.entry_no4 || cv_sc ;
    END IF;
    -- 伝票No5
    IF (gr_param.entry_no5 IS NOT NULL) THEN
      IF (lv_work_str IS NOT NULL) THEN
        lv_work_str := lv_work_str || ',' ;
      END IF ;
      lv_work_str := lv_work_str  || cv_sc || gr_param.entry_no5 || cv_sc ;
    END IF;
    IF (lv_work_str IS NOT NULL) THEN
      lv_sql_body := lv_sql_body || ' AND gbh.batch_no IN('||lv_work_str || ')';
    END IF ;
    -- パラメータ絞込(品目ID)
    -- 品目1
    IF (gr_param.item1 IS NOT NULL) THEN
      lv_work_str_2 := gr_param.item1;
    END IF;
    -- 品目2
    IF (gr_param.item2 IS NOT NULL) THEN
      IF (lv_work_str_2 IS NOT NULL) THEN
        lv_work_str_2 := lv_work_str_2 || ',' ;
      END IF ;
      lv_work_str_2 := lv_work_str_2  || gr_param.item2 ;
    END IF ;
    -- 品目3
    IF (gr_param.item3 IS NOT NULL) THEN
      IF (lv_work_str_2 IS NOT NULL) THEN
        lv_work_str_2 := lv_work_str_2 || ',' ;
      END IF ;
      lv_work_str_2 := lv_work_str_2  || gr_param.item3 ;
    END IF ;
    IF (lv_work_str_2 IS NOT NULL) THEN
      lv_sql_body := lv_sql_body || ' AND itp.item_id IN('||lv_work_str_2 || ')';
    END IF ;
    -- 担当者
    IF (gr_param.emp_no IS NOT NULL) THEN
      lv_sql_body := lv_sql_body || ' AND papf.employee_number = ''' || gr_param.emp_no || '''';
    END IF ;
    -- 更新時間FROM
    IF (gr_param.creation_date_from IS NOT NULL) THEN
      lv_sql_body := lv_sql_body || ' AND gbh.creation_date >= FND_DATE.STRING_TO_DATE(';
      lv_sql_body := lv_sql_body || ''''  || TO_CHAR(gr_param.creation_date_from,gc_date_mask) || '''' ;
      lv_sql_body := lv_sql_body || ',''' || gc_date_mask || ''')' ;
    END IF ;
    -- 更新時間TO
    IF (gr_param.creation_date_to IS NOT NULL) THEN
      lv_sql_body := lv_sql_body || ' AND gbh.creation_date <= FND_DATE.STRING_TO_DATE(';
      lv_sql_body := lv_sql_body || ''''  || TO_CHAR(gr_param.creation_date_to,gc_date_mask) || '''' ;
      lv_sql_body := lv_sql_body || ',''' || gc_date_mask || ''')' ;
    END IF ;
    ---------------------------------------------------------------------------------------------
    --ORDER BY 句
    lv_sql_body := lv_sql_body || ' ORDER BY xlv.location_code' ;
    lv_sql_body := lv_sql_body || ' ,xilv.segment1' ;
    lv_sql_body := lv_sql_body || ' ,xicv.item_class_code' ;
    lv_sql_body := lv_sql_body || ' ,xrpm.new_div_invent' ;
    lv_sql_body := lv_sql_body || ' ,gbh.batch_no' ;
    lv_sql_body := lv_sql_body || ' ,gbh.actual_cmplt_date' ;
    lv_sql_body := lv_sql_body || ' ,ximv.item_no' ;
    lv_sql_body := lv_sql_body || ' ,ilm.lot_no' ;
--
    EXECUTE IMMEDIATE lv_sql_body BULK COLLECT INTO ot_data_rec ;
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
  END prc_get_prod_pay_data ;
--
   /**********************************************************************************
   * Procedure Name   : prc_get_prod_rcv_data
   * Description      : PROD:生産受入データ取得プロシージャ(C2)
   ***********************************************************************************/
--
  PROCEDURE prc_get_prod_rcv_data
    (
      in_batch_id   NUMBER                 -- バッチID
     ,ot_data_rec   OUT tab_data_type_dtl  -- 取得レコード
     ,ov_errbuf     OUT NOCOPY VARCHAR2    -- エラー・メッセージ
     ,ov_retcode    OUT NOCOPY VARCHAR2    -- リターン・コード
     ,ov_errmsg     OUT NOCOPY VARCHAR2    -- ユーザー・エラー・メッセージ
    )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_get_prod_rcv_data'; -- プログラム名
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
    cv_sc CONSTANT VARCHAR2(2) := '''';
    -- *** ローカル・変数 ***
    lv_sql_body    VARCHAR2(10000);  -- SQL文：本体
    lv_work_str    VARCHAR2(100) ;   -- 作業用変数:伝票No絞込
    lv_work_str_2  VARCHAR2(100) ;   -- 作業用変数:品目絞込
--
  BEGIN
--
    -- SQL本体
    lv_sql_body := lv_sql_body || ' SELECT ' ;
    lv_sql_body := lv_sql_body || '  gbh.batch_id                AS batch_id' ;
    lv_sql_body := lv_sql_body || ' ,NULL                        AS dept_code' ;
    lv_sql_body := lv_sql_body || ' ,NULL                        AS dept_name' ;
    lv_sql_body := lv_sql_body || ' ,NULL                        AS item_location_code' ;
    lv_sql_body := lv_sql_body || ' ,NULL                        AS item_location_name' ;
    lv_sql_body := lv_sql_body || ' ,NULL                        AS item_div_type' ;
    lv_sql_body := lv_sql_body || ' ,NULL                        AS item_div_value' ;
    lv_sql_body := lv_sql_body || ' ,NULL                        AS entry_no' ;
    lv_sql_body := lv_sql_body || ' ,NULL                        AS entry_date' ;
    lv_sql_body := lv_sql_body || ' ,NULL                        AS pay_reason_code' ;
    lv_sql_body := lv_sql_body || ' ,NULL                        AS pay_reason_name' ;
    lv_sql_body := lv_sql_body || ' ,NULL                        AS pay_item_no' ;
    lv_sql_body := lv_sql_body || ' ,NULL                        AS pay_item_name' ;
    lv_sql_body := lv_sql_body || ' ,NULL                        AS pay_lot_no' ;
    lv_sql_body := lv_sql_body || ' ,0                           AS pay_quant' ;
    lv_sql_body := lv_sql_body || ' ,0                           AS pay_unt_price' ;
    lv_sql_body := lv_sql_body || ' ,xrpm.new_div_invent         AS rcv_reason_code' ;
    lv_sql_body := lv_sql_body || ' ,flv.meaning                 AS rcv_reason_name' ;
    lv_sql_body := lv_sql_body || ' ,ximv.item_no                AS rcv_item_no' ;
--mod start 1.2
--    lv_sql_body := lv_sql_body || ' ,ximv.item_desc1             AS rcv_item_name' ;
    lv_sql_body := lv_sql_body || ' ,ximv.item_short_name        AS rcv_item_name' ;
--mod end 1.2
    lv_sql_body := lv_sql_body || ' ,ilm.lot_no                  AS rcv_lot_no' ;
    lv_sql_body := lv_sql_body || ' ,ROUND(ABS(itp.trans_qty),4) AS rcv_quant' ;
    lv_sql_body := lv_sql_body || ' ,CASE ximv.cost_manage_code' ;
    lv_sql_body := lv_sql_body || '    WHEN '|| cv_sc || gc_cost_manage_code_n || cv_sc ||' THEN' ;
    lv_sql_body := lv_sql_body || '      ROUND(xsupv.stnd_unit_price,3)' ;
    lv_sql_body := lv_sql_body || '    WHEN '|| cv_sc || gc_cost_manage_code_j || cv_sc ||' THEN' ;
--mod start 1.2
--    lv_sql_body := lv_sql_body || '      ROUND(TO_NUMBER(ilm.attribute7),3)' ;
    lv_sql_body := lv_sql_body || '      ROUND(TO_NUMBER(NVL(ilm.attribute7,0)),3)' ;
--mod end 1.2
    lv_sql_body := lv_sql_body || '    ELSE ' ;
    lv_sql_body := lv_sql_body || '      ' || gc_cost_0 ;
    lv_sql_body := lv_sql_body || ' END                          AS rcv_unt_price' ;
    ---------------------------------------------------------------------------------------
    -- FROM句
    lv_sql_body := lv_sql_body || ' FROM xxcmn_item_mst2_v    ximv' ;
    lv_sql_body := lv_sql_body || ' ,ic_lots_mst               ilm' ;
    lv_sql_body := lv_sql_body || ' ,xxinv_rcv_pay_mst2_v     xrpm' ;
    lv_sql_body := lv_sql_body || ' ,gme_batch_header          gbh' ;
    lv_sql_body := lv_sql_body || ' ,ic_tran_pnd               itp' ;
    lv_sql_body := lv_sql_body || ' ,fnd_lookup_values         flv' ;
    lv_sql_body := lv_sql_body || ' ,xxcmn_stnd_unit_price_v xsupv' ;
    ------------------------------------------------------------
    -- WHERE句
    -- OPM保留在庫トランザクション絞込
    lv_sql_body := lv_sql_body || ' WHERE itp.line_type            = ''' || gc_line_type_rcv || '''';
    lv_sql_body := lv_sql_body || ' AND itp.doc_type               = ''' || gc_doc_type_prod || '''';
    lv_sql_body := lv_sql_body || ' AND itp.completed_ind          = ''' || gc_comp_ind_on   || '''';
    lv_sql_body := lv_sql_body || ' AND itp.reverse_id             IS NULL' ;
    -- 受払区分アドオンマスタ結合
    lv_sql_body := lv_sql_body || ' AND xrpm.doc_id                = itp.doc_id';
    lv_sql_body := lv_sql_body || ' AND xrpm.doc_line              = itp.doc_line';
    lv_sql_body := lv_sql_body || ' AND xrpm.line_type             = itp.line_type';
    lv_sql_body := lv_sql_body || ' AND xrpm.use_div_invent_rep    = ''' || gc_use_div_invent_rep ||'''';
    -- 生産バッチ結合
    lv_sql_body := lv_sql_body || ' AND itp.doc_id                 = gbh.batch_id' ;
    -- OPM品目情報VIEW結合
    lv_sql_body := lv_sql_body || ' AND itp.item_id                = ximv.item_id' ;
    lv_sql_body := lv_sql_body || ' AND ' || gv_sql_date_from || ' BETWEEN ximv.start_date_active' ;
    lv_sql_body := lv_sql_body || '                                    AND NVL(ximv.end_date_active,' || gv_sql_date_from || ')' ;
    -- 標準原価情報VIEW結合
    lv_sql_body := lv_sql_body || ' AND xsupv.item_id              = itp.item_id ' ;
    lv_sql_body := lv_sql_body || ' AND ' || gv_sql_date_from || ' BETWEEN NVL(xsupv.start_date_active,'|| gv_sql_date_from || ')' ;
    lv_sql_body := lv_sql_body || '                                    AND NVL(xsupv.end_date_active,'  || gv_sql_date_from || ')' ;
    -- OPMロットマスタ結合
    lv_sql_body := lv_sql_body || ' AND itp.lot_id                 = ilm.lot_id' ;
--add start 1.2
    lv_sql_body := lv_sql_body || ' AND itp.item_id                = ilm.item_id' ;
--add end 1.2
    -- クイックコード(新区分)結合
    lv_sql_body := lv_sql_body || ' AND flv.lookup_type            = ''' || gc_lookup_type_new_div || '''' ;
    lv_sql_body := lv_sql_body || ' AND flv.language               = ''' || gc_language_code       || '''';
    lv_sql_body := lv_sql_body || ' AND flv.lookup_code            = xrpm.new_div_invent ';
    -------------------------------------------------------------------------------
    lv_sql_body := lv_sql_body || ' AND gbh.batch_id = ' || in_batch_id ;
    -------------------------------------------------------------------------------
    --ORDER BY 句
    lv_sql_body := lv_sql_body || ' ORDER BY ';
    lv_sql_body := lv_sql_body || '  xrpm.new_div_invent' ;
    lv_sql_body := lv_sql_body || ' ,gbh.batch_no' ;
    lv_sql_body := lv_sql_body || ' ,gbh.actual_cmplt_date' ;
    lv_sql_body := lv_sql_body || ' ,ximv.item_no' ;
    lv_sql_body := lv_sql_body || ' ,ilm.lot_no' ;
--
    EXECUTE IMMEDIATE lv_sql_body BULK COLLECT INTO ot_data_rec ;
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
  END prc_get_prod_rcv_data ;
--
   /**********************************************************************************
   * Procedure Name   : prc_get_adji_data
   * Description      : ADJI:在庫調整(受払)データ取得プロシージャ(C2)
   ***********************************************************************************/

  PROCEDURE prc_get_adji_data
    (
      in_line_type  IN NUMBER              -- ラインタイプ(受: 1/払:-1)
     ,ot_data_rec   OUT tab_data_type_dtl  -- 取得レコード
     ,ov_errbuf     OUT NOCOPY VARCHAR2    -- エラー・メッセージ
     ,ov_retcode    OUT NOCOPY VARCHAR2    -- リターン・コード
     ,ov_errmsg     OUT NOCOPY VARCHAR2    -- ユーザー・エラー・メッセージ
    )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_adji_data'; -- プログラム名
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
    cv_sc CONSTANT VARCHAR2(2) := '''';
    -- *** ローカル・変数 ***
    lv_sql_body    VARCHAR2(10000);  -- SQL文：本体
    lv_work_str    VARCHAR2(100) ;   -- 作業用変数:伝票No絞込
    lv_work_str_2  VARCHAR2(100) ;   -- 作業用変数:品目絞込
--
  BEGIN
--
    -- SQL本体
    IF(in_line_type = -1) THEN
      lv_sql_body := lv_sql_body || ' SELECT ' ;
      lv_sql_body := lv_sql_body || '  NULL                        AS batch_id' ;
      lv_sql_body := lv_sql_body || ' ,xlv.location_code           AS dept_code' ;
      lv_sql_body := lv_sql_body || ' ,SUBSTRB(xlv.description,1,20)             AS dept_name' ;
      lv_sql_body := lv_sql_body || ' ,xilv.segment1               AS item_location_code' ;
      lv_sql_body := lv_sql_body || ' ,xilv.description            AS item_location_name' ;
      lv_sql_body := lv_sql_body || ' ,xicv.item_class_code        AS item_div_type' ;
      lv_sql_body := lv_sql_body || ' ,xicv.item_class_name        AS item_div_value';
      lv_sql_body := lv_sql_body || ' ,ijm.journal_no              AS entry_no' ;
      lv_sql_body := lv_sql_body || ' ,itc.trans_date              AS entry_date';
      lv_sql_body := lv_sql_body || ' ,xrpm.new_div_invent         AS pay_reason_code' ;
      lv_sql_body := lv_sql_body || ' ,flv.meaning                 AS pay_reason_name' ;
      lv_sql_body := lv_sql_body || ' ,ximv.item_no                AS pay_item_no' ;
--mod start 1.2
--      lv_sql_body := lv_sql_body || ' ,ximv.item_desc1             AS pay_item_name';
--      lv_sql_body := lv_sql_body || ' ,ilm.lot_no                  AS pay_lot_no';
      lv_sql_body := lv_sql_body || ' ,ximv.item_short_name        AS pay_item_name';
      lv_sql_body := lv_sql_body || ' ,DECODE(ilm.lot_id,0,NULL,ilm.lot_no) AS pay_lot_no';
--mod end 1.2
      lv_sql_body := lv_sql_body || ' ,ROUND(ABS(itc.trans_qty),4) AS pay_quant';
      lv_sql_body := lv_sql_body || ' ,CASE ximv.cost_manage_code' ;
      lv_sql_body := lv_sql_body || '    WHEN '|| cv_sc || gc_cost_manage_code_n || cv_sc ||' THEN' ;
      lv_sql_body := lv_sql_body || '      ROUND(xsupv.stnd_unit_price,3)' ;
      lv_sql_body := lv_sql_body || '    WHEN '|| cv_sc || gc_cost_manage_code_j || cv_sc ||' THEN' ;
--mod start 1.2
--      lv_sql_body := lv_sql_body || '      ROUND(TO_NUMBER(ilm.attribute7),3)' ;
      lv_sql_body := lv_sql_body || '      ROUND(TO_NUMBER(NVL(ilm.attribute7,0)),3)' ;
--mod end 1.2
      lv_sql_body := lv_sql_body || '    ELSE ' ;
      lv_sql_body := lv_sql_body || '      ' || gc_cost_0 ;
      lv_sql_body := lv_sql_body || '  END                         AS pay_unt_price' ;
      lv_sql_body := lv_sql_body || ' ,NULL                        AS rcv_reason_code' ;
      lv_sql_body := lv_sql_body || ' ,NULL                        AS rcv_reason_name' ;
      lv_sql_body := lv_sql_body || ' ,NULL                        AS rcv_item_no' ;
      lv_sql_body := lv_sql_body || ' ,NULL                        AS rcv_item_name';
      lv_sql_body := lv_sql_body || ' ,NULL                        AS rcv_lot_no';
      lv_sql_body := lv_sql_body || ' ,0                           AS rcv_quant';
      lv_sql_body := lv_sql_body || ' ,0                           AS rcv_unt_price' ;
    ELSE
      lv_sql_body := lv_sql_body || ' SELECT ' ;
      lv_sql_body := lv_sql_body || '  NULL                        AS batch_id' ;
      lv_sql_body := lv_sql_body || ' ,xlv.location_code           AS dept_code' ;
      lv_sql_body := lv_sql_body || ' ,SUBSTRB(xlv.description,1,20)             AS dept_name' ;
      lv_sql_body := lv_sql_body || ' ,xilv.segment1               AS item_location_code' ;
      lv_sql_body := lv_sql_body || ' ,xilv.description            AS item_location_name' ;
      lv_sql_body := lv_sql_body || ' ,xicv.item_class_code        AS item_div_type' ;
      lv_sql_body := lv_sql_body || ' ,xicv.item_class_name        AS item_div_value';
      lv_sql_body := lv_sql_body || ' ,ijm.journal_no              AS entry_no' ;
      lv_sql_body := lv_sql_body || ' ,itc.trans_date              AS entry_date';
      lv_sql_body := lv_sql_body || ' ,NULL                        AS pay_reason_code' ;
      lv_sql_body := lv_sql_body || ' ,NULL                        AS pay_reason_name' ;
      lv_sql_body := lv_sql_body || ' ,NULL                        AS pay_item_no' ;
      lv_sql_body := lv_sql_body || ' ,NULL                        AS pay_item_name';
      lv_sql_body := lv_sql_body || ' ,NULL                        AS pay_lot_no';
      lv_sql_body := lv_sql_body || ' ,0                           AS pay_quant';
      lv_sql_body := lv_sql_body || ' ,0                           AS pay_unt_price' ;
      lv_sql_body := lv_sql_body || ' ,xrpm.new_div_invent         AS rcv_reason_code' ;
      lv_sql_body := lv_sql_body || ' ,flv.meaning                 AS rcv_reason_name' ;
      lv_sql_body := lv_sql_body || ' ,ximv.item_no                AS rcv_item_no' ;
--mod start 1.2
--      lv_sql_body := lv_sql_body || ' ,ximv.item_desc1             AS rcv_item_name';
--      lv_sql_body := lv_sql_body || ' ,ilm.lot_no                  AS rcv_lot_no';
      lv_sql_body := lv_sql_body || ' ,ximv.item_short_name        AS rcv_item_name';
      lv_sql_body := lv_sql_body || ' ,DECODE(ilm.lot_id,0,NULL,ilm.lot_no) AS rcv_lot_no';
--mod end 1.2
      lv_sql_body := lv_sql_body || ' ,ROUND(ABS(itc.trans_qty),4) AS rcv_quant';
      lv_sql_body := lv_sql_body || ' ,CASE ximv.cost_manage_code' ;
      lv_sql_body := lv_sql_body || '    WHEN '|| cv_sc || gc_cost_manage_code_n || cv_sc ||' THEN' ;
      lv_sql_body := lv_sql_body || '      ROUND(xsupv.stnd_unit_price,3)' ;
      lv_sql_body := lv_sql_body || '    WHEN '|| cv_sc || gc_cost_manage_code_j || cv_sc ||' THEN' ;
--mod start 1.2
--      lv_sql_body := lv_sql_body || '      ROUND(TO_NUMBER(ilm.attribute7),3)' ;
      lv_sql_body := lv_sql_body || '      ROUND(TO_NUMBER(NVL(ilm.attribute7,0)),3)' ;
--mod end 1.2
      lv_sql_body := lv_sql_body || '    ELSE ' ;
      lv_sql_body := lv_sql_body || '      ' || gc_cost_0 ;
      lv_sql_body := lv_sql_body || ' END                          AS rcv_unt_price' ;
    END IF ;
    ---------------------------------------------------------------------------------------
    -- FROM句
    lv_sql_body := lv_sql_body || ' FROM xxcmn_item_mst2_v    ximv' ;
    lv_sql_body := lv_sql_body || ' ,xxcmn_item_categories4_v xicv' ;
    lv_sql_body := lv_sql_body || ' ,ic_lots_mst               ilm' ;
    lv_sql_body := lv_sql_body || ' ,xxinv_rcv_pay_mst6_v     xrpm' ;
    lv_sql_body := lv_sql_body || ' ,ic_jrnl_mst               ijm' ;
    lv_sql_body := lv_sql_body || ' ,ic_adjs_jnl               iaj' ;
    lv_sql_body := lv_sql_body || ' ,ic_tran_cmp               itc' ;
    lv_sql_body := lv_sql_body || ' ,xxcmn_item_locations2_v  xilv' ;
    lv_sql_body := lv_sql_body || ' ,xxcmn_locations2_v        xlv' ;
    lv_sql_body := lv_sql_body || ' ,fnd_lookup_values         flv' ;
    lv_sql_body := lv_sql_body || ' ,xxcmn_stnd_unit_price_v xsupv' ;
    lv_sql_body := lv_sql_body || ' ,fnd_user                   fu' ;
    lv_sql_body := lv_sql_body || ' ,per_all_people_f         papf' ;
    lv_sql_body := lv_sql_body || ' ,per_all_assignments_f    paaf' ;
    ------------------------------------------------------------
    -- WHERE句
    -- OPMジャーナル在庫調整ジャーナル結合
    lv_sql_body := lv_sql_body || ' WHERE itc.doc_id               = iaj.doc_id';
    lv_sql_body := lv_sql_body || ' AND itc.doc_line               = iaj.doc_line';
    -- OPMジャーナルマスタ結合
    lv_sql_body := lv_sql_body || ' AND iaj.journal_id             = ijm.journal_id';
    -- 受払区分情報VIEW生産結合
    lv_sql_body := lv_sql_body || ' AND xrpm.doc_type              = itc.doc_type';
    lv_sql_body := lv_sql_body || ' AND xrpm.reason_code           = itc.reason_code';
    lv_sql_body := lv_sql_body || ' AND xrpm.use_div_invent_rep    = ''' || gc_use_div_invent_rep || '''';
    lv_sql_body := lv_sql_body || ' AND xrpm.rcv_pay_div           = TO_CHAR( SIGN( itc.trans_qty ) )';
    lv_sql_body := lv_sql_body || ' AND xrpm.rcv_pay_div           = :line_type';
    -- OPM品目情報VIEW結合
    lv_sql_body := lv_sql_body || ' AND itc.item_id                = ximv.item_id' ;
    lv_sql_body := lv_sql_body || ' AND ' || gv_sql_date_from || ' BETWEEN ximv.start_date_active' ;
    lv_sql_body := lv_sql_body || '                                    AND NVL(ximv.end_date_active,' || gv_sql_date_from || ')' ;
    -- OPM品目カテゴリ割当情報VIEW結合
    lv_sql_body := lv_sql_body || ' AND ximv.item_id  = xicv.item_id' ;
    -- 標準原価情報VIEW結合
    lv_sql_body := lv_sql_body || ' AND xsupv.item_id              = itc.item_id ' ;
    lv_sql_body := lv_sql_body || ' AND ' || gv_sql_date_from || ' BETWEEN NVL(xsupv.start_date_active,'|| gv_sql_date_from || ')' ;
    lv_sql_body := lv_sql_body || '                                    AND NVL(xsupv.end_date_active,'  || gv_sql_date_from || ')' ;
    -- OPMロットマスタ結合
    lv_sql_body := lv_sql_body || ' AND itc.lot_id                 = ilm.lot_id' ;
--add start 1.2
    lv_sql_body := lv_sql_body || ' AND itc.item_id                = ilm.item_id' ;
--add end 1.2
    -- クイックコード(新区分)結合
    lv_sql_body := lv_sql_body || ' AND flv.lookup_type            = ''' || gc_lookup_type_new_div || '''' ;
    lv_sql_body := lv_sql_body || ' AND flv.language               = ''' || gc_language_code       || '''';
    lv_sql_body := lv_sql_body || ' AND flv.lookup_code            = xrpm.new_div_invent ';
    -- ユーザマスタ結合
    lv_sql_body := lv_sql_body || ' AND fu.user_id                 = itc.created_by' ;
    -- 従業員マスタ結合
    lv_sql_body := lv_sql_body || ' AND fu.employee_id             = paaf.person_id' ;
    lv_sql_body := lv_sql_body || ' AND '|| gv_sql_date_from || '  BETWEEN paaf.effective_start_date' ;
    lv_sql_body := lv_sql_body || '                                    AND paaf.effective_end_date' ;
    lv_sql_body := lv_sql_body || ' AND papf.person_id             = paaf.person_id' ;
--add start 1.2
    lv_sql_body := lv_sql_body || ' AND '|| gv_sql_date_from || '  BETWEEN papf.effective_start_date' ;
    lv_sql_body := lv_sql_body || '                                    AND papf.effective_end_date' ;
--add end 1.2
    -- 事業所情報VIEW結合
    lv_sql_body := lv_sql_body || ' AND xlv.location_id            = paaf.location_id' ;
    lv_sql_body := lv_sql_body || ' AND ' || gv_sql_date_from || ' BETWEEN NVL(xlv.start_date_active,'|| gv_sql_date_from || ')' ;
    lv_sql_body := lv_sql_body || '                                    AND NVL(xlv.end_date_active,'  || gv_sql_date_from || ')' ;
    -- OPM保管場所情報VIEW結合
    lv_sql_body := lv_sql_body || ' AND xilv.whse_code             = itc.whse_code' ;
    lv_sql_body := lv_sql_body || ' AND xilv.segment1              = itc.location' ;
    -------------------------------------------------------------------------------
    --必須パラメータ絞込
    --  1．年月日_FROM
    --  2．年月日_TO
    lv_sql_body := lv_sql_body || ' AND itc.trans_date      BETWEEN FND_DATE.STRING_TO_DATE(';
    lv_sql_body := lv_sql_body || ''''  || TO_CHAR(gr_param.date_from,gc_date_mask) || '''' ;
    lv_sql_body := lv_sql_body || ',''' || gc_date_mask || ''')' ;
    lv_sql_body := lv_sql_body || '                                    AND FND_DATE.STRING_TO_DATE(';
    lv_sql_body := lv_sql_body || ''''  || TO_CHAR(gr_param.date_to,gc_date_mask) || '''' ;
    lv_sql_body := lv_sql_body || ',''' || gc_date_mask || ''')' ;
    --  3．払出品目区分
    IF (gr_param.out_item_ctl IS NOT NULL) THEN
      lv_sql_body := lv_sql_body || ' AND xicv.item_class_code = ' || cv_sc || gr_param.out_item_ctl || cv_sc;
    END IF ;
    -------------------------------------------------------------------------------
    --  7．事由コード
    IF (gr_param.reason_code IS NOT NULL) THEN
      lv_sql_body := lv_sql_body || ' AND xrpm.new_div_invent = '
                                      || cv_sc || gr_param.reason_code || cv_sc;
    END IF ;
    -------------------------------------------------------------------------------
    --  8．保管倉庫コード
    IF (gr_param.item_location_id IS NOT NULL) THEN
      lv_sql_body := lv_sql_body || ' AND xilv.inventory_location_id = '
                                      || cv_sc || gr_param.item_location_id || cv_sc;
    END IF ;
    -------------------------------------------------------------------------------
    --  9．担当部署
    IF (gr_param.dept_id IS NOT NULL) THEN
      lv_sql_body := lv_sql_body || ' AND paaf.location_id = '
                                      || cv_sc || gr_param.dept_id || cv_sc;
    END IF ;
    -------------------------------------------------------------------------------
    -- 伝票No1
    IF (gr_param.entry_no1 IS NOT NULL) THEN
      lv_work_str := cv_sc || gr_param.entry_no1 || cv_sc ;
    END IF;
    -- 伝票No2
    IF (gr_param.entry_no2 IS NOT NULL) THEN
      IF (lv_work_str IS NOT NULL) THEN
        lv_work_str := lv_work_str || ',' ;
      END IF ;
      lv_work_str := lv_work_str || cv_sc || gr_param.entry_no2 || cv_sc ;
    END IF;
    -- 伝票No3
    IF (gr_param.entry_no3 IS NOT NULL) THEN
      IF (lv_work_str IS NOT NULL) THEN
        lv_work_str := lv_work_str || ',' ;
      END IF ;
      lv_work_str := lv_work_str  || cv_sc || gr_param.entry_no3 || cv_sc ;
    END IF;
    -- 伝票No4
    IF (gr_param.entry_no4 IS NOT NULL) THEN
      IF (lv_work_str IS NOT NULL) THEN
        lv_work_str := lv_work_str || ',' ;
      END IF ;
      lv_work_str := lv_work_str  || cv_sc || gr_param.entry_no4 || cv_sc ;
    END IF;
    -- 伝票No5
    IF (gr_param.entry_no5 IS NOT NULL) THEN
      IF (lv_work_str IS NOT NULL) THEN
        lv_work_str := lv_work_str || ',' ;
      END IF ;
      lv_work_str := lv_work_str  || cv_sc || gr_param.entry_no5 || cv_sc ;
    END IF;
    IF (lv_work_str IS NOT NULL) THEN
      lv_sql_body := lv_sql_body || ' AND ijm.journal_no IN('||lv_work_str || ')';
    END IF ;
    -- パラメータ絞込(品目ID)
    -- 品目1
    IF (gr_param.item1 IS NOT NULL) THEN
      lv_work_str_2 := gr_param.item1;
    END IF;
    -- 品目2
    IF (gr_param.item2 IS NOT NULL) THEN
      IF (lv_work_str_2 IS NOT NULL) THEN
        lv_work_str_2 := lv_work_str_2 || ',' ;
      END IF ;
      lv_work_str_2 := lv_work_str_2  || gr_param.item2 ;
    END IF;
    -- 品目3
    IF (gr_param.item3 IS NOT NULL) THEN
      IF (lv_work_str_2 IS NOT NULL) THEN
        lv_work_str_2 := lv_work_str_2 || ',' ;
      END IF ;
      lv_work_str_2 := lv_work_str_2  || gr_param.item3 ;
    END IF;
    IF (lv_work_str_2 IS NOT NULL) THEN
      lv_sql_body := lv_sql_body || ' AND itc.item_id IN('||lv_work_str_2 || ')';
    END IF ;
    -- 担当者
    IF (gr_param.emp_no IS NOT NULL) THEN
      lv_sql_body := lv_sql_body || ' AND papf.employee_number = ''' || gr_param.emp_no || '''';
    END IF ;
    -- 更新時間FROM
    IF (gr_param.creation_date_from IS NOT NULL) THEN
      lv_sql_body := lv_sql_body || ' AND itc.creation_date >= FND_DATE.STRING_TO_DATE(';
      lv_sql_body := lv_sql_body || ''''  || TO_CHAR(gr_param.creation_date_from,gc_date_mask) || '''' ;
      lv_sql_body := lv_sql_body || ',''' || gc_date_mask || ''')' ;
    END IF ;
    -- 更新時間TO
    IF (gr_param.creation_date_to IS NOT NULL) THEN
      lv_sql_body := lv_sql_body || ' AND itc.creation_date <= FND_DATE.STRING_TO_DATE(';
      lv_sql_body := lv_sql_body || ''''  || TO_CHAR(gr_param.creation_date_to,gc_date_mask) || '''' ;
      lv_sql_body := lv_sql_body || ',''' || gc_date_mask || ''')' ;
    END IF ;
    ---------------------------------------------------------------------------------------------
    --ORDER BY 句
    lv_sql_body := lv_sql_body || ' ORDER BY xlv.location_code' ;
    lv_sql_body := lv_sql_body || ' ,xilv.segment1' ;
    lv_sql_body := lv_sql_body || ' ,xicv.item_class_code' ;
    lv_sql_body := lv_sql_body || ' ,xrpm.new_div_invent' ;
    lv_sql_body := lv_sql_body || ' ,ijm.journal_no' ;
    lv_sql_body := lv_sql_body || ' ,itc.trans_date' ;
    lv_sql_body := lv_sql_body || ' ,ximv.item_no' ;
    lv_sql_body := lv_sql_body || ' ,ilm.lot_no' ;
--
    EXECUTE IMMEDIATE lv_sql_body BULK COLLECT INTO ot_data_rec USING in_line_type ;
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
  END prc_get_adji_data ;
--
   /**********************************************************************************
   * Procedure Name   : prc_get_omso_porc_data
   * Description      : OSMO:見本出庫/廃棄 PORC･RMA:見本出庫取消/廃棄取消(C2)
   ***********************************************************************************/

  PROCEDURE prc_get_omso_porc_data
    (
      iv_doc_type   IN VARCHAR2            -- 文書タイプ
     ,ot_data_rec   OUT tab_data_type_dtl  -- 取得レコード
     ,ov_errbuf     OUT NOCOPY VARCHAR2    -- エラー・メッセージ
     ,ov_retcode    OUT NOCOPY VARCHAR2    -- リターン・コード
     ,ov_errmsg     OUT NOCOPY VARCHAR2    -- ユーザー・エラー・メッセージ
    )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_get_omso_porc_data'; -- プログラム名
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
    cv_sc CONSTANT VARCHAR2(2) := '''';
    -- *** ローカル・変数 ***
    lv_sql_body    VARCHAR2(10000);  -- SQL文：本体
    lv_work_str    VARCHAR2(100) ;   -- 作業用変数:伝票No絞込
    lv_work_str_2  VARCHAR2(100) ;   -- 作業用変数:品目絞込
  BEGIN
--
    -- SQL本体
    lv_sql_body := lv_sql_body || ' SELECT ' ;
    lv_sql_body := lv_sql_body || '  NULL                        AS batch_id' ;
    lv_sql_body := lv_sql_body || ' ,xlv.location_code           AS dept_code' ;
    lv_sql_body := lv_sql_body || ' ,SUBSTRB(xlv.description,1,20)             AS dept_name' ;
    lv_sql_body := lv_sql_body || ' ,xilv.segment1               AS item_location_code' ;
    lv_sql_body := lv_sql_body || ' ,xilv.description            AS item_location_name' ;
    lv_sql_body := lv_sql_body || ' ,xicv.item_class_code        AS item_div_type' ;
    lv_sql_body := lv_sql_body || ' ,xicv.item_class_name        AS item_div_value' ;
    lv_sql_body := lv_sql_body || ' ,xoha.request_no             AS entry_no' ;
    lv_sql_body := lv_sql_body || ' ,xoha.shipped_date           AS entry_date' ;
    lv_sql_body := lv_sql_body || ' ,xrpm.new_div_invent         AS pay_reason_code' ;
    lv_sql_body := lv_sql_body || ' ,flv.meaning                 AS pay_reason_name' ;
    lv_sql_body := lv_sql_body || ' ,ximv.item_no                AS pay_item_no' ;
--mod start 1.2
--    lv_sql_body := lv_sql_body || ' ,ximv.item_desc1             AS pay_item_name' ;
    lv_sql_body := lv_sql_body || ' ,ximv.item_short_name        AS pay_item_name' ;
--mod end 1.2
    lv_sql_body := lv_sql_body || ' ,ilm.lot_no                  AS pay_lot_no' ;
    IF (iv_doc_type = gc_doc_type_porc) THEN
      lv_sql_body := lv_sql_body || ',ROUND(itp.trans_qty*-1,4)    AS pay_quant' ;
    ELSE
      lv_sql_body := lv_sql_body || ',ABS(ROUND(itp.trans_qty,4))  AS pay_quant' ;
    END IF ;
    lv_sql_body := lv_sql_body || ' ,CASE ximv.cost_manage_code' ;
    lv_sql_body := lv_sql_body || '    WHEN '|| cv_sc || gc_cost_manage_code_n || cv_sc ||' THEN' ;
    lv_sql_body := lv_sql_body || '      ROUND(xsupv.stnd_unit_price,3)' ;
    lv_sql_body := lv_sql_body || '    WHEN '|| cv_sc || gc_cost_manage_code_j || cv_sc ||' THEN' ;
--mod start 1.2
--    lv_sql_body := lv_sql_body || '      ROUND(TO_NUMBER(ilm.attribute7),3)' ;
    lv_sql_body := lv_sql_body || '      ROUND(TO_NUMBER(NVL(ilm.attribute7,0)),3)' ;
--mod end 1.2
    lv_sql_body := lv_sql_body || '    ELSE ' ;
    lv_sql_body := lv_sql_body || '      ' || gc_cost_0 ;
    lv_sql_body := lv_sql_body || ' END                          AS pay_unt_price' ;
    lv_sql_body := lv_sql_body || ' ,NULL                        AS rcv_reason_code' ;
    lv_sql_body := lv_sql_body || ' ,NULL                        AS rcv_reason_name' ;
    lv_sql_body := lv_sql_body || ' ,NULL                        AS rcv_item_no' ;
    lv_sql_body := lv_sql_body || ' ,NULL                        AS rcv_item_name';
    lv_sql_body := lv_sql_body || ' ,NULL                        AS rcv_lot_no';
    lv_sql_body := lv_sql_body || ' ,0                           AS rcv_quant';
    lv_sql_body := lv_sql_body || ' ,0                           AS rcv_unt_price' ;
    ---------------------------------------------------------------------------------------
    -- FROM句
    lv_sql_body := lv_sql_body || ' FROM xxcmn_item_mst2_v    ximv' ;
    lv_sql_body := lv_sql_body || ' ,xxcmn_item_categories4_v xicv' ;
    lv_sql_body := lv_sql_body || ' ,ic_lots_mst               ilm' ;
    lv_sql_body := lv_sql_body || ' ,xxcmn_rcv_pay_mst        xrpm' ;
    lv_sql_body := lv_sql_body || ' ,oe_transaction_types_all otta' ;
    lv_sql_body := lv_sql_body || ' ,oe_order_headers_all     ooha' ;
    lv_sql_body := lv_sql_body || ' ,xxwsh_order_headers_all  xoha' ;
    lv_sql_body := lv_sql_body || ' ,ic_tran_pnd               itp' ;
    lv_sql_body := lv_sql_body || ' ,xxcmn_item_locations2_v  xilv' ;
    lv_sql_body := lv_sql_body || ' ,xxcmn_locations2_v        xlv' ;
    lv_sql_body := lv_sql_body || ' ,fnd_lookup_values         flv' ;
    lv_sql_body := lv_sql_body || ' ,xxcmn_stnd_unit_price_v xsupv' ;
    lv_sql_body := lv_sql_body || ' ,fnd_user                   fu' ;
    lv_sql_body := lv_sql_body || ' ,per_all_people_f         papf' ;
    lv_sql_body := lv_sql_body || ' ,per_all_assignments_f    paaf' ;
    IF (iv_doc_type = gc_doc_type_omso) THEN
      lv_sql_body := lv_sql_body || ',wsh_delivery_details     wdd' ;
    ELSE
      lv_sql_body := lv_sql_body || ',rcv_shipment_lines       rsl' ;
    END IF ;
    ---------------------------------------------------------------------------------------
    -- WHERE句
    -- OPM保留在庫トランザクション絞込
    lv_sql_body := lv_sql_body || ' WHERE itp.completed_ind             = ''' || gc_comp_ind_on   || '''';
    lv_sql_body := lv_sql_body || ' AND itp.reverse_id                  IS NULL' ;
    -- 受払区分アドオンマスタ結合
    lv_sql_body := lv_sql_body || ' AND xrpm.doc_type                   = itp.doc_type';
    lv_sql_body := lv_sql_body || ' AND xrpm.ship_prov_rcv_pay_category = otta.attribute11';
    lv_sql_body := lv_sql_body || ' AND xrpm.stock_adjustment_div       = otta.attribute4';
    lv_sql_body := lv_sql_body || ' AND xrpm.stock_adjustment_div       = '   ||  gc_stock_adjst_div_sa ;
    lv_sql_body := lv_sql_body || ' AND xrpm.use_div_invent_rep         = ''' || gc_use_div_invent_rep  || '''' ;
    lv_sql_body := lv_sql_body || ' AND xrpm.rcv_pay_div                = '   || gc_line_type_pay  ;
    -- 受注ヘッダ(アドオン)結合
    lv_sql_body := lv_sql_body || ' AND xoha.header_id                  = ooha.header_id' ;
    -- 受注タイプ結合
    lv_sql_body := lv_sql_body || ' AND otta.transaction_type_id        = xoha.order_type_id' ;
    -- OPM品目情報VIEW結合
    lv_sql_body := lv_sql_body || ' AND itp.item_id                = ximv.item_id' ;
    lv_sql_body := lv_sql_body || ' AND ' || gv_sql_date_from || ' BETWEEN ximv.start_date_active' ;
    lv_sql_body := lv_sql_body || '                                    AND NVL(ximv.end_date_active,' || gv_sql_date_from || ')' ;
    -- OPM品目カテゴリ割当情報VIEW結合
    lv_sql_body := lv_sql_body || ' AND ximv.item_id  = xicv.item_id' ;
    -- 標準原価情報VIEW結合
    lv_sql_body := lv_sql_body || ' AND xsupv.item_id              = itp.item_id ' ;
    lv_sql_body := lv_sql_body || ' AND ' || gv_sql_date_from || ' BETWEEN NVL(xsupv.start_date_active,'|| gv_sql_date_from || ')' ;
    lv_sql_body := lv_sql_body || '                                    AND NVL(xsupv.end_date_active,'  || gv_sql_date_from || ')' ;
    -- OPMロットマスタ結合
    lv_sql_body := lv_sql_body || ' AND itp.lot_id                 = ilm.lot_id' ;
--add start 1.2
    lv_sql_body := lv_sql_body || ' AND itp.item_id                = ilm.item_id' ;
--add end 1.2
    -- クイックコード(新区分)結合
    lv_sql_body := lv_sql_body || ' AND flv.lookup_type            = ''' || gc_lookup_type_new_div || '''' ;
    lv_sql_body := lv_sql_body || ' AND flv.language               = ''' || gc_language_code       || '''';
    lv_sql_body := lv_sql_body || ' AND flv.lookup_code            = xrpm.new_div_invent ';
    -- ユーザマスタ結合
    lv_sql_body := lv_sql_body || ' AND fu.user_id                 = xoha.created_by' ;
    -- 従業員マスタ結合
    lv_sql_body := lv_sql_body || ' AND fu.employee_id             = paaf.person_id' ;
    lv_sql_body := lv_sql_body || ' AND '|| gv_sql_date_from || '  BETWEEN paaf.effective_start_date' ;
    lv_sql_body := lv_sql_body || '                                    AND paaf.effective_end_date' ;
    lv_sql_body := lv_sql_body || ' AND papf.person_id             = paaf.person_id' ;
--add start 1.2
    lv_sql_body := lv_sql_body || ' AND '|| gv_sql_date_from || '  BETWEEN papf.effective_start_date' ;
    lv_sql_body := lv_sql_body || '                                    AND papf.effective_end_date' ;
--add end 1.2
    -- 事業所情報VIEW結合
    lv_sql_body := lv_sql_body || ' AND xlv.location_id            = paaf.location_id' ;
    lv_sql_body := lv_sql_body || ' AND ' || gv_sql_date_from || ' BETWEEN NVL(xlv.start_date_active,'|| gv_sql_date_from || ')' ;
    lv_sql_body := lv_sql_body || '                                    AND NVL(xlv.end_date_active,'  || gv_sql_date_from || ')' ;
    -- OPM保管場所情報VIEW結合
    lv_sql_body := lv_sql_body || ' AND xilv.whse_code             = itp.whse_code' ;
    lv_sql_body := lv_sql_body || ' AND xilv.segment1              = itp.location'  ;
--
    -- OMSO/PORC区分による結合条件分岐
    IF (iv_doc_type = gc_doc_type_omso) THEN
      -- 出荷搬送明細結合
      lv_sql_body := lv_sql_body || ' AND itp.line_id               = wdd.source_line_id' ;
      -- 受注ヘッダ結合
      lv_sql_body := lv_sql_body || ' AND ooha.org_id               = wdd.org_id' ;
      lv_sql_body := lv_sql_body || ' AND ooha.header_id            = wdd.source_header_id' ;
      -- 受払区分アドオンマスタ結合
      lv_sql_body := lv_sql_body || ' AND xrpm.doc_type             = ''' || gc_doc_type_omso || '''' ;
    ELSE
      -- 受入明細結合
      lv_sql_body := lv_sql_body || ' AND rsl.shipment_header_id    = itp.doc_id' ;
      lv_sql_body := lv_sql_body || ' AND rsl.line_num              = itp.doc_line';
      lv_sql_body := lv_sql_body || ' AND rsl.oe_order_header_id    = ooha.header_id' ;
      -- 受払区分アドオンマスタ結合
      lv_sql_body := lv_sql_body || ' AND xrpm.doc_type             = ''' || gc_doc_type_porc        || '''' ;
      lv_sql_body := lv_sql_body || ' AND xrpm.source_document_code = ''' || gc_source_doc_type_rma  || '''' ;
    END IF ;
--
    -------------------------------------------------------------------------------
    --必須パラメータ絞込
    --  1．年月日_FROM
    --  2．年月日_TO
    lv_sql_body := lv_sql_body || ' AND xoha.shipped_date      BETWEEN FND_DATE.STRING_TO_DATE(';
    lv_sql_body := lv_sql_body || ''''  || TO_CHAR(gr_param.date_from,gc_date_mask) || '''' ;
    lv_sql_body := lv_sql_body || ',''' || gc_date_mask || ''')' ;
    lv_sql_body := lv_sql_body || '                            AND FND_DATE.STRING_TO_DATE(';
    lv_sql_body := lv_sql_body || ''''  || TO_CHAR(gr_param.date_to,gc_date_mask) || '''' ;
    lv_sql_body := lv_sql_body || ',''' || gc_date_mask || ''')' ;
    -------------------------------------------------------------------------------
    --  3．払出品目区分
    IF (gr_param.out_item_ctl IS NOT NULL) THEN
      lv_sql_body := lv_sql_body || ' AND xicv.item_class_code =' || cv_sc || gr_param.out_item_ctl || cv_sc;
    END IF ;
    -------------------------------------------------------------------------------
    --  7．事由コード
    IF (gr_param.reason_code IS NOT NULL) THEN
      lv_sql_body := lv_sql_body || ' AND xrpm.new_div_invent = '
                                      || cv_sc || gr_param.reason_code || cv_sc;
    END IF ;
    -------------------------------------------------------------------------------
    --  8．保管倉庫コード
    IF (gr_param.item_location_id IS NOT NULL) THEN
      lv_sql_body := lv_sql_body || ' AND xilv.inventory_location_id ='
                                      || cv_sc || gr_param.item_location_id || cv_sc;
    END IF ;
    -------------------------------------------------------------------------------
    --  9．担当部署
    IF (gr_param.dept_id IS NOT NULL) THEN
      lv_sql_body := lv_sql_body || ' AND paaf.location_id = '
                                      || cv_sc || gr_param.dept_id || cv_sc;
    END IF ;
    -------------------------------------------------------------------------------
    -- 伝票No1
    IF (gr_param.entry_no1 IS NOT NULL) THEN
      lv_work_str := cv_sc || gr_param.entry_no1 || cv_sc ;
    END IF;
    -- 伝票No2
    IF (gr_param.entry_no2 IS NOT NULL) THEN
      IF (lv_work_str IS NOT NULL) THEN
        lv_work_str := lv_work_str || ',' ;
      END IF ;
      lv_work_str := lv_work_str || cv_sc || gr_param.entry_no2 || cv_sc ;
    END IF;
    -- 伝票No3
    IF (gr_param.entry_no3 IS NOT NULL) THEN
      IF (lv_work_str IS NOT NULL) THEN
        lv_work_str := lv_work_str || ',' ;
      END IF ;
      lv_work_str := lv_work_str  || cv_sc || gr_param.entry_no3 || cv_sc ;
    END IF;
    -- 伝票No4
    IF (gr_param.entry_no4 IS NOT NULL) THEN
      IF (lv_work_str IS NOT NULL) THEN
        lv_work_str := lv_work_str || ',' ;
      END IF ;
      lv_work_str := lv_work_str  || cv_sc || gr_param.entry_no4 || cv_sc ;
    END IF;
    -- 伝票No5
    IF (gr_param.entry_no5 IS NOT NULL) THEN
      IF (lv_work_str IS NOT NULL) THEN
        lv_work_str := lv_work_str || ',' ;
      END IF ;
      lv_work_str := lv_work_str  || cv_sc || gr_param.entry_no5 || cv_sc ;
    END IF;
    IF (lv_work_str IS NOT NULL) THEN
      lv_sql_body := lv_sql_body || ' AND xoha.request_no IN('||lv_work_str || ')';
    END IF ;
    -- パラメータ絞込(品目ID)
    -- 品目1
    IF (gr_param.item1 IS NOT NULL) THEN
      lv_work_str_2 := gr_param.item1;
    END IF;
    -- 品目2
    IF (gr_param.item2 IS NOT NULL) THEN
      IF (lv_work_str_2 IS NOT NULL) THEN
        lv_work_str_2 := lv_work_str_2 || ',' ;
      END IF ;
      lv_work_str_2 := lv_work_str_2  || gr_param.item2 ;
    END IF;
    -- 品目3
    IF (gr_param.item3 IS NOT NULL) THEN
      IF (lv_work_str_2 IS NOT NULL) THEN
        lv_work_str_2 := lv_work_str_2 || ',' ;
      END IF ;
      lv_work_str_2 := lv_work_str_2  || gr_param.item3 ;
    END IF;
    IF (lv_work_str_2 IS NOT NULL) THEN
      lv_sql_body := lv_sql_body || ' AND ximv.item_id IN('||lv_work_str_2 || ')';
    END IF ;
    -- 担当者
    IF (gr_param.emp_no IS NOT NULL) THEN
      lv_sql_body := lv_sql_body || ' AND papf.employee_number = ''' || gr_param.emp_no || '''';
    END IF ;
    -- 更新時間FROM
    IF (gr_param.creation_date_from IS NOT NULL) THEN
      lv_sql_body := lv_sql_body || ' AND xoha.creation_date >= FND_DATE.STRING_TO_DATE(';
      lv_sql_body := lv_sql_body || ''''  || TO_CHAR(gr_param.creation_date_from,gc_date_mask) || '''' ;
      lv_sql_body := lv_sql_body || ',''' || gc_date_mask || ''')' ;
    END IF ;
    -- 更新時間TO
    IF (gr_param.creation_date_to IS NOT NULL) THEN
      lv_sql_body := lv_sql_body || ' AND xoha.creation_date <= FND_DATE.STRING_TO_DATE(';
      lv_sql_body := lv_sql_body || ''''  || TO_CHAR(gr_param.creation_date_to,gc_date_mask) || '''' ;
      lv_sql_body := lv_sql_body || ',''' || gc_date_mask || ''')' ;
    END IF ;
    ---------------------------------------------------------------------------------------------
    --ORDER BY 句
    lv_sql_body := lv_sql_body || ' ORDER BY xlv.location_code' ;
    lv_sql_body := lv_sql_body || ' ,xilv.segment1' ;
    lv_sql_body := lv_sql_body || ' ,xicv.item_class_code' ;
    lv_sql_body := lv_sql_body || ' ,xrpm.new_div_invent' ;
    lv_sql_body := lv_sql_body || ' ,xoha.request_no' ;
    lv_sql_body := lv_sql_body || ' ,xoha.shipped_date' ;
    lv_sql_body := lv_sql_body || ' ,ximv.item_no' ;
    lv_sql_body := lv_sql_body || ' ,ilm.lot_no' ;
--
    EXECUTE IMMEDIATE lv_sql_body BULK COLLECT INTO ot_data_rec ;
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
  END prc_get_omso_porc_data ;
--
   /**********************************************************************************
   * Procedure Name   : prc_get_data_to_tmp_table
   * Description      : データ加工・中間テーブル更新プロシージャ(C2)
   ***********************************************************************************/

  PROCEDURE prc_get_data_to_tmp_table
    (
      ov_errbuf     OUT NOCOPY VARCHAR2    -- エラー・メッセージ
     ,ov_retcode    OUT NOCOPY VARCHAR2    -- リターン・コード
     ,ov_errmsg     OUT NOCOPY VARCHAR2    -- ユーザー・エラー・メッセージ
    )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_get_data_to_tmp_table'; -- プログラム名
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
    -- *** ローカル・変数 ***
    ln_batch_id       NUMBER  DEFAULT 0 ;
    lt_prod_all_data  tab_data_type_dtl ;
    ln_prod_cnt       NUMBER  DEFAULT 1 ;
    lt_prod_pay_data  tab_data_type_dtl ;
    lt_prod_rcv_data  tab_data_type_dtl ;
    ln_rcv_cnt        NUMBER  DEFAULT 1 ;
    lt_general_data   tab_data_type_dtl ;
--
  BEGIN
--
    -- ==========================================================
    -- 初期処理
    -- ==========================================================
    -- SQL共通文字列生成:パラメータDATE_FROM部成形
    gv_sql_date_from :=  'FND_DATE.STRING_TO_DATE(' ;
    gv_sql_date_from :=  gv_sql_date_from || '''' || TO_CHAR(gr_param.date_from,gc_date_mask) ||''',' ;
    gv_sql_date_from :=  gv_sql_date_from || '''' || gc_date_mask ||''')';
    -- ==========================================================
    -- 生産(PROD)データ取得・格納処理
    -- ==========================================================
    -- 払出データ抽出
    prc_get_prod_pay_data
     (
      ot_data_rec  => lt_prod_pay_data
     ,ov_errbuf    => lv_errbuf         -- エラー・メッセージ
     ,ov_retcode   => lv_retcode        -- リターン・コード
     ,ov_errmsg    => lv_errmsg         -- ユーザー・エラー・メッセージ
    ) ;
--
      <<lt_prod_pay_data_LOOP>>
      FOR i IN 1..lt_prod_pay_data.count LOOP
--
        -- 初回レコード／払データブレイク
        IF ( ( i =1 )
          OR (lt_prod_pay_data(i).batch_id <> ln_batch_id )) THEN
--
          -- 受＞払時の受差分出力
          <<RCV_BREAK_LOOP>>
          WHILE(lt_prod_rcv_data.EXISTS(ln_rcv_cnt)) LOOP
--
            lt_prod_all_data(ln_prod_cnt). batch_id           := lt_prod_pay_data(i-1).batch_id ;
            lt_prod_all_data(ln_prod_cnt). dept_code          := lt_prod_pay_data(i-1).dept_code ;
            lt_prod_all_data(ln_prod_cnt). dept_name          := SUBSTRB(lt_prod_pay_data(i-1).dept_name,1,20);
            lt_prod_all_data(ln_prod_cnt). item_location_code := lt_prod_pay_data(i-1).item_location_code ;
            lt_prod_all_data(ln_prod_cnt). item_location_name := lt_prod_pay_data(i-1).item_location_name ;
            lt_prod_all_data(ln_prod_cnt). item_div_type      := lt_prod_pay_data(i-1).item_div_type ;
            lt_prod_all_data(ln_prod_cnt). item_div_value     := lt_prod_pay_data(i-1).item_div_value ;
            lt_prod_all_data(ln_prod_cnt). entry_no           := lt_prod_pay_data(i-1).entry_no ;
            lt_prod_all_data(ln_prod_cnt). entry_date         := lt_prod_pay_data(i-1).entry_date ;
            lt_prod_all_data(ln_prod_cnt). pay_reason_code    := lt_prod_pay_data(i-1).pay_reason_code ;
            lt_prod_all_data(ln_prod_cnt). pay_reason_name    := NULL ;
            lt_prod_all_data(ln_prod_cnt). pay_item_no        := NULL ;
            lt_prod_all_data(ln_prod_cnt). pay_item_name      := NULL ;
            lt_prod_all_data(ln_prod_cnt). pay_lot_no         := NULL ;
            lt_prod_all_data(ln_prod_cnt). pay_quant          := 0 ;
            lt_prod_all_data(ln_prod_cnt). pay_unt_price      := 0 ;
            lt_prod_all_data(ln_prod_cnt). rcv_reason_code    := lt_prod_rcv_data(ln_rcv_cnt).rcv_reason_code ;
            lt_prod_all_data(ln_prod_cnt). rcv_reason_name    := lt_prod_rcv_data(ln_rcv_cnt).rcv_reason_name ;
            lt_prod_all_data(ln_prod_cnt). rcv_item_no        := lt_prod_rcv_data(ln_rcv_cnt).rcv_item_no ;
            lt_prod_all_data(ln_prod_cnt). rcv_item_name      := lt_prod_rcv_data(ln_rcv_cnt).rcv_item_name ;
            lt_prod_all_data(ln_prod_cnt). rcv_lot_no         := lt_prod_rcv_data(ln_rcv_cnt).rcv_lot_no ;
            lt_prod_all_data(ln_prod_cnt). rcv_quant          := lt_prod_rcv_data(ln_rcv_cnt).rcv_quant ;
            lt_prod_all_data(ln_prod_cnt). rcv_unt_price      := lt_prod_rcv_data(ln_rcv_cnt).rcv_unt_price ;
--
            -- カウンタインクリメント
            ln_prod_cnt := ln_prod_cnt + 1 ;
            ln_rcv_cnt  := ln_rcv_cnt  + 1 ;
--
          END LOOP RCV_BREAK_LOOP ;
--
          -- 受データ取得
          prc_get_prod_rcv_data
          (
           in_batch_id  => lt_prod_pay_data(i).batch_id
          ,ot_data_rec  => lt_prod_rcv_data
          ,ov_errbuf    => lv_errbuf         -- エラー・メッセージ
          ,ov_retcode   => lv_retcode        -- リターン・コード
          ,ov_errmsg    => lv_errmsg         -- ユーザー・エラー・メッセージ
         ) ;
          -- 受カウンタ初期化
          ln_rcv_cnt := 1 ;
          -- 払ブレイクキーセット
          ln_batch_id := lt_prod_pay_data(i).batch_id ;
--
      END IF;
--
      -- 受存在チェック
      -- 受有：受払出力／受無：払出力
      IF (lt_prod_rcv_data.EXISTS(ln_rcv_cnt)) THEN
--
        lt_prod_all_data(ln_prod_cnt). batch_id           := lt_prod_pay_data(i).batch_id ;
        lt_prod_all_data(ln_prod_cnt). dept_code          := lt_prod_pay_data(i).dept_code ;
        lt_prod_all_data(ln_prod_cnt). dept_name          := SUBSTRB(lt_prod_pay_data(i).dept_name,1,20);
        lt_prod_all_data(ln_prod_cnt). item_location_code := lt_prod_pay_data(i).item_location_code ;
        lt_prod_all_data(ln_prod_cnt). item_location_name := lt_prod_pay_data(i).item_location_name ;
        lt_prod_all_data(ln_prod_cnt). item_div_type      := lt_prod_pay_data(i).item_div_type ;
        lt_prod_all_data(ln_prod_cnt). item_div_value     := lt_prod_pay_data(i).item_div_value ;
        lt_prod_all_data(ln_prod_cnt). entry_no           := lt_prod_pay_data(i).entry_no ;
        lt_prod_all_data(ln_prod_cnt). entry_date         := lt_prod_pay_data(i).entry_date ;
        lt_prod_all_data(ln_prod_cnt). pay_reason_code    := lt_prod_pay_data(i).pay_reason_code ;
        lt_prod_all_data(ln_prod_cnt). pay_reason_name    := lt_prod_pay_data(i).pay_reason_name ;
        lt_prod_all_data(ln_prod_cnt). pay_item_no        := lt_prod_pay_data(i).pay_item_no ;
        lt_prod_all_data(ln_prod_cnt). pay_item_name      := lt_prod_pay_data(i).pay_item_name ;
        lt_prod_all_data(ln_prod_cnt). pay_lot_no         := lt_prod_pay_data(i).pay_lot_no ;
        lt_prod_all_data(ln_prod_cnt). pay_quant          := lt_prod_pay_data(i).pay_quant ;
        lt_prod_all_data(ln_prod_cnt). pay_unt_price      := lt_prod_pay_data(i).pay_unt_price ;
        lt_prod_all_data(ln_prod_cnt). rcv_reason_code    := lt_prod_rcv_data(ln_rcv_cnt).rcv_reason_code ;
        lt_prod_all_data(ln_prod_cnt). rcv_reason_name    := lt_prod_rcv_data(ln_rcv_cnt).rcv_reason_name ;
        lt_prod_all_data(ln_prod_cnt). rcv_item_no        := lt_prod_rcv_data(ln_rcv_cnt).rcv_item_no ;
        lt_prod_all_data(ln_prod_cnt). rcv_item_name      := lt_prod_rcv_data(ln_rcv_cnt).rcv_item_name ;
        lt_prod_all_data(ln_prod_cnt). rcv_lot_no         := lt_prod_rcv_data(ln_rcv_cnt).rcv_lot_no ;
        lt_prod_all_data(ln_prod_cnt). rcv_quant          := lt_prod_rcv_data(ln_rcv_cnt).rcv_quant ;
        lt_prod_all_data(ln_prod_cnt). rcv_unt_price      := lt_prod_rcv_data(ln_rcv_cnt).rcv_unt_price ;
--
        -- カウンタインクリメント
        ln_prod_cnt := ln_prod_cnt + 1 ;
        ln_rcv_cnt  := ln_rcv_cnt  + 1 ;
--
      ELSE
--
        lt_prod_all_data(ln_prod_cnt). batch_id           := lt_prod_pay_data(i).batch_id;
        lt_prod_all_data(ln_prod_cnt). dept_code          := lt_prod_pay_data(i).dept_code ;
        lt_prod_all_data(ln_prod_cnt). dept_name          := SUBSTRB(lt_prod_pay_data(i).dept_name,1,20);
        lt_prod_all_data(ln_prod_cnt). item_location_code := lt_prod_pay_data(i).item_location_code ;
        lt_prod_all_data(ln_prod_cnt). item_location_name := lt_prod_pay_data(i).item_location_name ;
        lt_prod_all_data(ln_prod_cnt). item_div_type      := lt_prod_pay_data(i).item_div_type ;
        lt_prod_all_data(ln_prod_cnt). item_div_value     := lt_prod_pay_data(i).item_div_value ;
        lt_prod_all_data(ln_prod_cnt). entry_no           := lt_prod_pay_data(i).entry_no ;
        lt_prod_all_data(ln_prod_cnt). entry_date         := lt_prod_pay_data(i).entry_date ;
        lt_prod_all_data(ln_prod_cnt). pay_reason_code    := lt_prod_pay_data(i).pay_reason_code ;
        lt_prod_all_data(ln_prod_cnt). pay_reason_name    := lt_prod_pay_data(i).pay_reason_name ;
        lt_prod_all_data(ln_prod_cnt). pay_item_no        := lt_prod_pay_data(i).pay_item_no ;
        lt_prod_all_data(ln_prod_cnt). pay_item_name      := lt_prod_pay_data(i).pay_item_name ;
        lt_prod_all_data(ln_prod_cnt). pay_lot_no         := lt_prod_pay_data(i).pay_lot_no ;
        lt_prod_all_data(ln_prod_cnt). pay_quant          := lt_prod_pay_data(i).pay_quant ;
        lt_prod_all_data(ln_prod_cnt). pay_unt_price      := lt_prod_pay_data(i).pay_unt_price ;
        lt_prod_all_data(ln_prod_cnt). rcv_reason_code    := NULL ;
        lt_prod_all_data(ln_prod_cnt). rcv_reason_name    := NULL ;
        lt_prod_all_data(ln_prod_cnt). rcv_item_no        := NULL ;
        lt_prod_all_data(ln_prod_cnt). rcv_item_name      := NULL ;
        lt_prod_all_data(ln_prod_cnt). rcv_lot_no         := NULL ;
        lt_prod_all_data(ln_prod_cnt). rcv_quant          := 0 ;
        lt_prod_all_data(ln_prod_cnt). rcv_unt_price      := 0 ;
--
        -- カウンタインクリメント
        ln_prod_cnt := ln_prod_cnt + 1 ;
--
      END IF ;
--
      -- 払フェッチ：最終レコード⇒ 受＞払時の受差分出力
      IF NOT(lt_prod_pay_data.EXISTS(i+1)) THEN
--
        <<RCV_BREAK_LOOP>>
        WHILE(lt_prod_rcv_data.EXISTS(ln_rcv_cnt)) LOOP
--
          lt_prod_all_data(ln_prod_cnt). batch_id           := lt_prod_pay_data(i).batch_id ;
          lt_prod_all_data(ln_prod_cnt). dept_code          := lt_prod_pay_data(i).dept_code ;
          lt_prod_all_data(ln_prod_cnt). dept_name          := SUBSTRB(lt_prod_pay_data(i).dept_name,1,20);
          lt_prod_all_data(ln_prod_cnt). item_location_code := lt_prod_pay_data(i).item_location_code ;
          lt_prod_all_data(ln_prod_cnt). item_location_name := lt_prod_pay_data(i).item_location_name ;
          lt_prod_all_data(ln_prod_cnt). item_div_type      := lt_prod_pay_data(i).item_div_type ;
          lt_prod_all_data(ln_prod_cnt). item_div_value     := lt_prod_pay_data(i).item_div_value ;
          lt_prod_all_data(ln_prod_cnt). entry_no           := lt_prod_pay_data(i).entry_no ;
          lt_prod_all_data(ln_prod_cnt). entry_date         := lt_prod_pay_data(i).entry_date ;NULL ;
          lt_prod_all_data(ln_prod_cnt). pay_reason_code    := NULL ;
          lt_prod_all_data(ln_prod_cnt). pay_reason_name    := NULL ;
          lt_prod_all_data(ln_prod_cnt). pay_item_no        := NULL ;
          lt_prod_all_data(ln_prod_cnt). pay_item_name      := NULL ;
          lt_prod_all_data(ln_prod_cnt). pay_lot_no         := NULL ;
          lt_prod_all_data(ln_prod_cnt). pay_quant          := 0 ;
          lt_prod_all_data(ln_prod_cnt). pay_unt_price      := 0 ;
          lt_prod_all_data(ln_prod_cnt). rcv_reason_code    := lt_prod_rcv_data(ln_rcv_cnt).rcv_reason_code ;
          lt_prod_all_data(ln_prod_cnt). rcv_reason_name    := lt_prod_rcv_data(ln_rcv_cnt).rcv_reason_name ;
          lt_prod_all_data(ln_prod_cnt). rcv_item_no        := lt_prod_rcv_data(ln_rcv_cnt).rcv_item_no ;
          lt_prod_all_data(ln_prod_cnt). rcv_item_name      := lt_prod_rcv_data(ln_rcv_cnt).rcv_item_name ;
          lt_prod_all_data(ln_prod_cnt). rcv_lot_no         := lt_prod_rcv_data(ln_rcv_cnt).rcv_lot_no ;
          lt_prod_all_data(ln_prod_cnt). rcv_quant          := lt_prod_rcv_data(ln_rcv_cnt).rcv_quant ;
          lt_prod_all_data(ln_prod_cnt). rcv_unt_price      := lt_prod_rcv_data(ln_rcv_cnt).rcv_unt_price ;
--
          -- カウンタインクリメント
          ln_prod_cnt := ln_prod_cnt + 1 ;
          ln_rcv_cnt  := ln_rcv_cnt  + 1 ;
--
        END LOOP RCV_BREAK_LOOP ;
--
      END IF;
--
    END LOOP lt_prod_pay_data_LOOP ;
--
    FORALL i in 1 .. lt_prod_all_data.COUNT 
      INSERT INTO XXINV_550C_TMP VALUES lt_prod_all_data(i) ;
--
    -- =========================================================
    -- 在庫調整(ADJI)データ取得・格納処理
    -- =========================================================
--
    -- ---------------------------------------------------------
    -- 払出
    -- ---------------------------------------------------------
    prc_get_adji_data
    (
       in_line_type => gc_line_type_rcv  -- ラインタイプ(受: 1/払:-1)
      ,ot_data_rec  => lt_general_data   -- 取得レコード
      ,ov_errbuf    => lv_errbuf         -- エラー・メッセージ
      ,ov_retcode   => lv_retcode        -- リターン・コード
      ,ov_errmsg    => lv_errmsg         -- ユーザー・エラー・メッセージ
    )
    ;
--
      -- 在庫調整(ADJI)：払
      FORALL i in 1..lt_general_data.COUNT
        INSERT INTO XXINV_550C_TMP VALUES lt_general_data(i) ;
--
    -- XXINV55C中間テーブル型変数初期化
    lt_general_data.DELETE ;
--
    prc_get_adji_data
    (
       in_line_type => gc_line_type_pay   -- ラインタイプ(受: 1/払:-1)
      ,ot_data_rec  => lt_general_data    -- 取得レコード
      ,ov_errbuf    => lv_errbuf          -- エラー・メッセージ
      ,ov_retcode   => lv_retcode         -- リターン・コード
      ,ov_errmsg    => lv_errmsg          -- ユーザー・エラー・メッセージ
    )
    ;
--
      -- 在庫調整(ADJI)：受
      FORALL i in 1..lt_general_data.COUNT
        INSERT INTO XXINV_550C_TMP VALUES lt_general_data(i) ;
--
    -- XXINV55C中間テーブル型変数初期化
    lt_general_data.DELETE ;
--
    -- =========================================================
    -- 見本出庫(OMSO) データ取得・格納処理
    -- =========================================================
    prc_get_omso_porc_data
    (
       iv_doc_type  => gc_doc_type_omso  -- 文書タイプ：OMSO(見本出庫)
      ,ot_data_rec  => lt_general_data   -- 取得レコード
      ,ov_errbuf    => lv_errbuf         -- エラー・メッセージ
      ,ov_retcode   => lv_retcode        -- リターン・コード
      ,ov_errmsg    => lv_errmsg         -- ユーザー・エラー・メッセージ
    )
    ;
--
      -- 見本出庫(OMSO)：払
      FORALL i in 1..lt_general_data.COUNT
        INSERT INTO XXINV_550C_TMP VALUES lt_general_data(i) ;
--
    -- XXINV55C中間テーブル型変数初期化
    lt_general_data.DELETE ;
--
    -- =========================================================
    -- 廃棄(出荷)PROC･RMA データ取得・格納処理
    -- =========================================================
    prc_get_omso_porc_data
    (
       iv_doc_type  => gc_doc_type_porc  -- 文書タイプ：OMSO(見本出庫)
      ,ot_data_rec  => lt_general_data   -- 取得レコード
      ,ov_errbuf    => lv_errbuf         -- エラー・メッセージ
      ,ov_retcode   => lv_retcode        -- リターン・コード
      ,ov_errmsg    => lv_errmsg         -- ユーザー・エラー・メッセージ
    )
    ;
--
      -- 廃棄(出荷)PROC･RMA ：払
      FORALL i in 1..lt_general_data.COUNT
        INSERT INTO XXINV_550C_TMP VALUES lt_general_data(i) ;
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
  END prc_get_data_to_tmp_table ;
--
--
   /**********************************************************************************
   * Procedure Name   : prc_get_data_from_tmp_table
   * Description      :データ取得(最終出力データ)プロシージャ(C2)
   ***********************************************************************************/

  PROCEDURE prc_get_data_from_tmp_table
    (
      ot_out_data   OUT tab_data_type_dtl  -- 取得レコード
     ,ov_errbuf     OUT NOCOPY VARCHAR2    -- エラー・メッセージ
     ,ov_retcode    OUT NOCOPY VARCHAR2    -- リターン・コード
     ,ov_errmsg     OUT NOCOPY VARCHAR2    -- ユーザー・エラー・メッセージ
    )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_get_data_from_tmp_table'; -- プログラム名
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
    SELECT
     batch_id            -- バッチID
    ,dept_code           -- 部署コード
    ,dept_name           -- 部署名称
    ,item_location_code  -- 保管倉庫コード
    ,item_location_name  -- 保管倉庫名
    ,item_div_type       -- 品目区分コード
    ,item_div_value      -- 品目区分名称
    ,entry_no            -- 伝票NO
    ,entry_date          -- 入出庫日
    ,pay_reason_code     -- 払出事由コード
    ,pay_reason_name     -- 払出事由名称
    ,pay_item_no         -- 払出品目コード
    ,pay_item_name       -- 払出品目名称
    ,pay_lot_no          -- 払出ロットNO
    ,pay_quant           -- 払出総数
    ,pay_unt_price       -- 払出単価
    ,rcv_reason_code     -- 受入事由コード
    ,rcv_reason_name     -- 受入事由名称
    ,rcv_item_no         -- 受入品目コード
    ,rcv_item_name       -- 受入品目名称
    ,rcv_lot_no          -- 受入ロットNO
    ,rcv_quant           -- 受入総数
    ,rcv_unt_price       -- 受入単価
    BULK COLLECT INTO ot_out_data
    FROM
    XXINV_550C_TMP
    ORDER BY
     dept_code
    ,item_location_code
    ,item_div_type
--add start 1.4
    ,CASE
       WHEN rcv_item_no IS NOT NULL AND pay_item_no IS NULL
         THEN 1
         ELSE 2
     END
--add end 1.4
--mod start 1.3
    ,pay_reason_code
    ,entry_no
    ,entry_date
--    ,pay_reason_code
--mod end 1.3
    ,pay_item_no
    ,pay_lot_no
    ;
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
  END prc_get_data_from_tmp_table ;
--
   /**********************************************************************************
   * Procedure Name   : prc_create_xml_data
   * Description      : ＸＭＬデータ作成(C-3/C-4)
   ***********************************************************************************/
  PROCEDURE prc_create_xml_data
    (
      it_out_data       IN  tab_data_type_dtl       -- 01.取得レコード
     ,ov_errbuf         OUT NOCOPY VARCHAR2         -- エラー・メッセージ
     ,ov_retcode        OUT NOCOPY VARCHAR2         -- リターン・コード
     ,ov_errmsg         OUT NOCOPY VARCHAR2         -- ユーザー・エラー・メッセージ
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
    -- *** ローカル・例外処理 ***
    dtldata_notfound_expt      EXCEPTION ;     -- 対象データ0件例外
    -- *** ローカル変数 ***
    ln_exec_user_id NUMBER ;
  BEGIN
--
    -- ----------------------------------------------------
    -- 開始タグ
    -- ----------------------------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'root' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
    -- データ未取得の場合
    IF (it_out_data.count = 0) THEN
      ------------------------------
      -- データ開始タグ
      ------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'datainfo' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
      ------------------------------
      -- 部署LＧ開始タグ
      ------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_dept_info' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
      ------------------------------
      -- 部署Ｇ開始タグ
      ------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'g_dept' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
      ------------------------------
      -- 保管倉庫LＧ開始タグ
      ------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_item_location_info' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
      ------------------------------
      -- 保管倉庫Ｇ開始タグ
      ------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'g_item_location' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
      ------------------------------
      -- 品目区分LＧ開始タグ
      ------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_item_div_info' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
      ------------------------------
      -- 品目区分Ｇ開始タグ
      ------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'g_item_div' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
       -- データなしメッセージ
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'msg' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
      gt_xml_data_table(gl_xml_idx).tag_value := xxcmn_common_pkg.get_msg( gc_application_cmn
                                                 ,gc_err_code_data_0 ) ;
      ------------------------------
      -- 品目区分Ｇ終了タグ
      ------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := '/g_item_div' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
      ------------------------------
      -- 品目区分LＧ終了タグ
      ------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_item_div_info' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
      ------------------------------
      -- 保管倉庫Ｇ終了タグ
      ------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := '/g_item_location' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
      ------------------------------
      -- 保管倉庫LＧ終了タグ
      ------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_item_location_info' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
      ------------------------------
      -- 部署Ｇ終了タグ
      ------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := '/g_dept' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
      ------------------------------
      -- 部署LＧ終了タグ
      ------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_dept_info' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
      ------------------------------
      -- データＧ終了タグ
      ------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := '/datainfo' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
      ------------------------------
      -- 終了タグ
      ------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := '/root' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
--
      RAISE dtldata_notfound_expt ;
--
    ELSE
      ln_exec_user_id := FND_GLOBAL.USER_ID;
      <<param_data_loop>>
      FOR i IN 1..it_out_data.count LOOP
        -- 初期処理
        IF ( i = 1 ) THEN
          ------------------------------
          -- ユーザデータ開始タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'user_info' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
          -- 帳票ID
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'report_id' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
          gt_xml_data_table(gl_xml_idx).tag_value := gc_report_id;
          -- 出力日時
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'exec_date' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
          gt_xml_data_table(gl_xml_idx).tag_value := TO_CHAR(SYSDATE,gc_date_mask);
          -- 担当(部署名)
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'exec_user_dept' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
          gt_xml_data_table(gl_xml_idx).tag_value 
                := xxcmn_common_pkg.get_user_dept(ln_exec_user_id);
          -- 担当(名称)
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'exec_user_name' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
          gt_xml_data_table(gl_xml_idx).tag_value 
                := xxcmn_common_pkg.get_user_name(ln_exec_user_id);
          ------------------------------
          -- ユーザデータ終了タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/user_info' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
          ------------------------------
          -- パラメータデータ開始タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'param_info' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
          -- 期間(FROM)
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'date_from' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
          gt_xml_data_table(gl_xml_idx).tag_value := TO_CHAR(gr_param.date_from,gc_date_mask_jp);
          -- 期間(TO)
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'date_to' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
          gt_xml_data_table(gl_xml_idx).tag_value := TO_CHAR(gr_param.date_to,gc_date_mask_jp);
          -- 金額表示フラグ
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'price_flg' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
          gt_xml_data_table(gl_xml_idx).tag_value := gr_param.price_ctl_flg ;
          ------------------------------
          -- パラメータデータ終了タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/param_info' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
          ------------------------------
          -- データ開始タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'datainfo' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
          ------------------------------
          -- 部署LＧ開始タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_dept_info' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
          ------------------------------
          -- 部署Ｇ開始タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'g_dept' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
          -- 担当部署コード
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'dept_code' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
          gt_xml_data_table(gl_xml_idx).tag_value := it_out_data(i).dept_code;
          -- 担当部署名
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'dept_name' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
          gt_xml_data_table(gl_xml_idx).tag_value := it_out_data(i).dept_name;
          ------------------------------
          -- 保管倉庫LＧ開始タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_item_location_info' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
          ------------------------------
          -- 保管倉庫Ｇ開始タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'g_item_location' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
          -- 保管倉庫コード
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'item_location_code' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
          gt_xml_data_table(gl_xml_idx).tag_value := it_out_data(i).item_location_code ;
          -- 保管倉庫名
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'item_location_name' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
          gt_xml_data_table(gl_xml_idx).tag_value := it_out_data(i).item_location_name ;
          ------------------------------
          -- 品目区分LＧ開始タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_item_div_info' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
          ------------------------------
          -- 品目区分Ｇ開始タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'g_item_div' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
          -- 品目区分コード
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'item_div_type' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
          gt_xml_data_table(gl_xml_idx).tag_value := it_out_data(i).item_div_type;
          -- 品目区分名称
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'item_div_value' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
          gt_xml_data_table(gl_xml_idx).tag_value := it_out_data(i).item_div_value;
          ------------------------------
          -- 事由LＧ開始タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_reason_info' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
          ------------------------------
          -- 事由Ｇ開始タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'g_reason' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
          ------------------------------
          -- 明細LＧ開始タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_dtl_info' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
        -- カレントレコードと前レコードの事由が不一致
--mod start 1.3
--        ELSIF (it_out_data(i-1).pay_reason_code <> it_out_data(i).pay_reason_code)
        ELSIF (NVL(it_out_data(i-1).pay_reason_code,'dummy') <> NVL(it_out_data(i).pay_reason_code,'dummy'))
--mod end 1.3
        AND   (it_out_data(i-1).item_div_type      = it_out_data(i).item_div_type)
        AND   (it_out_data(i-1).item_location_code = it_out_data(i).item_location_code)
        AND   (it_out_data(i-1).dept_code          = it_out_data(i).dept_code) THEN
          ------------------------------
          -- 明細LＧ終了タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_dtl_info' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
          ------------------------------
          -- 事由Ｇ終了タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_reason' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
          ------------------------------
          -- 事由Ｇ開始タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'g_reason' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
          ------------------------------
          -- 明細LＧ開始タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_dtl_info' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
        -- カレントレコードと前レコードの品目区分が不一致
        ELSIF (it_out_data(i-1).item_div_type     <> it_out_data(i).item_div_type)
        AND   (it_out_data(i-1).item_location_code = it_out_data(i).item_location_code)
        AND   (it_out_data(i-1).dept_code          = it_out_data(i).dept_code) THEN
          ------------------------------
          -- 明細LＧ終了タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_dtl_info' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
          ------------------------------
          -- 事由Ｇ終了タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_reason' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
          ------------------------------
          -- 事由LＧ終了タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_reason_info' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
          ------------------------------
          -- 品目区分Ｇ終了タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_item_div' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
          ------------------------------
          -- 品目区分Ｇ開始タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'g_item_div' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
          -- 品目区分コード
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'item_div_type' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
          gt_xml_data_table(gl_xml_idx).tag_value := it_out_data(i).item_div_type;
          -- 品目区分名称
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'item_div_value' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
          gt_xml_data_table(gl_xml_idx).tag_value := it_out_data(i).item_div_value;
          ------------------------------
          -- 事由LＧ開始タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_reason_info' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
          ------------------------------
          -- 事由Ｇ開始タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'g_reason' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
          ------------------------------
          -- 明細LＧ開始タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_dtl_info' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
        -- カレントレコードと前レコードの保管倉庫が不一致
        ELSIF (it_out_data(i-1).item_location_code <> it_out_data(i).item_location_code)
        AND   (it_out_data(i-1).dept_code           = it_out_data(i).dept_code)THEN
          ------------------------------
          -- 明細LＧ終了タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_dtl_info' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
          ------------------------------
          -- 事由Ｇ終了タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_reason' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
          ------------------------------
          -- 事由LＧ終了タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_reason_info' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
          ------------------------------
          -- 品目区分Ｇ終了タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_item_div' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
          ------------------------------
          -- 品目区分LＧ終了タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_item_div_info' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
          ------------------------------
          -- 保管倉庫Ｇ終了タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_item_location' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
          ------------------------------
          -- 保管倉庫Ｇ開始タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'g_item_location' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
          -- 保管倉庫コード
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'item_location_code' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
          gt_xml_data_table(gl_xml_idx).tag_value := it_out_data(i).item_location_code;
          -- 保管倉庫名
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'item_location_name' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
          gt_xml_data_table(gl_xml_idx).tag_value := it_out_data(i).item_location_name;
          ------------------------------
          -- 品目区分LＧ開始タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_item_div_info' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
          ------------------------------
          -- 品目区分Ｇ開始タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'g_item_div' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
          -- 品目区分コード
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'item_div_type' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
          gt_xml_data_table(gl_xml_idx).tag_value := it_out_data(i).item_div_type;
          -- 品目区分名称
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'item_div_value' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
          gt_xml_data_table(gl_xml_idx).tag_value := it_out_data(i).item_div_value;
          ------------------------------
          -- 事由LＧ開始タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_reason_info' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
          ------------------------------
          -- 事由Ｇ開始タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'g_reason' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
          ------------------------------
          -- 明細LＧ開始タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_dtl_info' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
        -- カレントレコードと前レコードの部署が不一致
        ELSIF (it_out_data(i-1).dept_code <> it_out_data(i).dept_code) THEN
          ------------------------------
          -- 明細LＧ終了タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_dtl_info' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
          ------------------------------
          -- 事由Ｇ終了タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_reason' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
          ------------------------------
          -- 事由LＧ終了タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_reason_info' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
          ------------------------------
          -- 品目区分Ｇ終了タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_item_div' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
          ------------------------------
          -- 品目区分LＧ終了タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_item_div_info' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
          ------------------------------
          -- 保管倉庫Ｇ終了タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_item_location' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
          ------------------------------
          -- 保管倉庫LＧ終了タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_item_location_info' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
          ------------------------------
          -- 部署Ｇ終了タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_dept' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
          ------------------------------
          -- 部署Ｇ開始タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'g_dept' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
          -- 担当部署コード
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'dept_code' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
          gt_xml_data_table(gl_xml_idx).tag_value := it_out_data(i).dept_code;
          -- 担当部署名
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'dept_name' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
          gt_xml_data_table(gl_xml_idx).tag_value := it_out_data(i).dept_name;
          ------------------------------
          -- 保管倉庫LＧ開始タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_item_location_info' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
          ------------------------------
          -- 保管倉庫Ｇ開始タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'g_item_location' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
          -- 保管倉庫コード
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'item_location_code' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
          gt_xml_data_table(gl_xml_idx).tag_value := it_out_data(i).item_location_code;
          -- 保管倉庫名
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'item_location_name' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
          gt_xml_data_table(gl_xml_idx).tag_value := it_out_data(i).item_location_name;
          ------------------------------
          -- 品目区分LＧ開始タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_item_div_info' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
          ------------------------------
          -- 品目区分Ｇ開始タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'g_item_div' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
          -- 品目区分コード
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'item_div_type' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
          gt_xml_data_table(gl_xml_idx).tag_value := it_out_data(i).item_div_type;
          -- 品目区分名称
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'item_div_value' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
          gt_xml_data_table(gl_xml_idx).tag_value := it_out_data(i).item_div_value;
          ------------------------------
          -- 事由LＧ開始タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_reason_info' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
          ------------------------------
          -- 事由Ｇ開始タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'g_reason' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
          ------------------------------
          -- 明細LＧ開始タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_dtl_info' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
        END IF ;
--
        ------------------------------
        -- 明細Ｇ開始タグ
        ------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'g_dtl' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
--
        -- 伝票No
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'entry_no' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
        gt_xml_data_table(gl_xml_idx).tag_value := it_out_data(i).entry_no;
        -- 入出庫日
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'entry_date' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
        gt_xml_data_table(gl_xml_idx).tag_value := TO_CHAR(it_out_data(i).entry_date,gc_date_mask_s);
--
        IF (it_out_data(i).pay_reason_code IS NOT NULL)
        AND(it_out_data(i).pay_reason_name IS NOT NULL) THEN
          -- 払出事由コード
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'pay_reason_type' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
          gt_xml_data_table(gl_xml_idx).tag_value := it_out_data(i).pay_reason_code;
          -- 払出事由名称
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'pay_reason_value' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
          gt_xml_data_table(gl_xml_idx).tag_value := it_out_data(i).pay_reason_name;
        ELSE
          -- 払出事由コード
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'pay_reason_type' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
          -- 払出事由名称
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'pay_reason_value' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
        END IF ;
--
        -- 払出品目コード
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'pay_item_code' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
        gt_xml_data_table(gl_xml_idx).tag_value := it_out_data(i).pay_item_no;
        -- 払出品目名
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'pay_item_name' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
        gt_xml_data_table(gl_xml_idx).tag_value := it_out_data(i).pay_item_name;
        -- 払出ロットNo
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'pay_lot_num' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
        gt_xml_data_table(gl_xml_idx).tag_value := it_out_data(i).pay_lot_no;
        -- 払出総数
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'pay_quant' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
        gt_xml_data_table(gl_xml_idx).tag_value := it_out_data(i).pay_quant;
        -- 払出単価
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'pay_unt_price' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
        gt_xml_data_table(gl_xml_idx).tag_value := it_out_data(i).pay_unt_price;
        -- 払出金額
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'pay_price' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
        gt_xml_data_table(gl_xml_idx).tag_value 
              := ROUND( it_out_data(i).pay_unt_price * it_out_data(i).pay_quant ) ;
        -- 受入事由コード
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'rcv_reason_type' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
        gt_xml_data_table(gl_xml_idx).tag_value := it_out_data(i).rcv_reason_code;
        -- 受入事由名称
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'rcv_reason_value' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
        gt_xml_data_table(gl_xml_idx).tag_value := it_out_data(i).rcv_reason_name;
        -- 受入品目コード
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'rcv_item_code' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
        gt_xml_data_table(gl_xml_idx).tag_value := it_out_data(i).rcv_item_no;
        -- 受入品目名
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'rcv_item_name' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
        gt_xml_data_table(gl_xml_idx).tag_value := it_out_data(i).rcv_item_name;
        -- 受入ロットNo
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'rcv_lot_num' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
        gt_xml_data_table(gl_xml_idx).tag_value := it_out_data(i).rcv_lot_no;
        -- 受入総数
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'rcv_quant' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
        gt_xml_data_table(gl_xml_idx).tag_value := it_out_data(i).rcv_quant;
        -- 受入単価
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'rcv_unt_price' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
        gt_xml_data_table(gl_xml_idx).tag_value := it_out_data(i).rcv_unt_price;
        -- 受入金額
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'rcv_price' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
        gt_xml_data_table(gl_xml_idx).tag_value 
              := ROUND( it_out_data(i).rcv_unt_price * it_out_data(i).rcv_quant );
--
        ------------------------------
        -- 明細Ｇ終了タグ
        ------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := '/g_dtl' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
--
      END LOOP param_data_loop ;
    END IF ;
--
    --終了処理
    ------------------------------
    -- 明細LＧ終了タグ
    ------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_dtl_info' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
    ------------------------------
    -- 事由Ｇ終了タグ
    ------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/g_reason' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
    ------------------------------
    -- 事由LＧ終了タグ
    ------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_reason_info' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
    ------------------------------
    -- 品目区分Ｇ終了タグ
    ------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/g_item_div' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
    ------------------------------
    -- 品目区分LＧ終了タグ
    ------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_item_div_info' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
    ------------------------------
    -- 保管倉庫Ｇ終了タグ
    ------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/g_item_location' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
    ------------------------------
    -- 保管倉庫LＧ終了タグ
    ------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_item_location_info' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
    ------------------------------
    -- 部署Ｇ終了タグ
    ------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/g_dept' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
    ------------------------------
    -- 部署LＧ終了タグ
    ------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_dept_info' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
    ------------------------------
    -- データ終了タグ
    ------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/datainfo' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
    -- ----------------------------------------------------
    -- 終了タグ
    -- ----------------------------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/root' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
--
  EXCEPTION
--
    -- *** 対象データ0件例外ハンドラ ***
    WHEN dtldata_notfound_expt THEN
      ov_retcode := gv_status_warn ;
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
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
     iv_date_from             IN  VARCHAR2     -- 01 : 年月日_FROM
    ,iv_date_to               IN  VARCHAR2     -- 02 : 年月日_TO
    ,iv_out_item_ctl          IN  VARCHAR2     -- 03 : 払出品目区分
    ,iv_item1                 IN  VARCHAR2     -- 04 : 品目ID1
    ,iv_item2                 IN  VARCHAR2     -- 05 : 品目ID2
    ,iv_item3                 IN  VARCHAR2     -- 06 : 品目ID3
    ,iv_reason_code           IN  VARCHAR2     -- 07 : 事由コード
    ,iv_item_location_id      IN  VARCHAR2     -- 08 : 保管倉庫ID
    ,iv_dept_id               IN  VARCHAR2     -- 09 : 担当部署ID
    ,iv_entry_no1             IN  VARCHAR2     -- 10 : 伝票No1
    ,iv_entry_no2             IN  VARCHAR2     -- 11 : 伝票No2
    ,iv_entry_no3             IN  VARCHAR2     -- 12 : 伝票No3
    ,iv_entry_no4             IN  VARCHAR2     -- 13 : 伝票No4
    ,iv_entry_no5             IN  VARCHAR2     -- 14 : 伝票No5
    ,iv_price_ctl_flg         IN  VARCHAR2     -- 15 : 金額表示
    ,iv_emp_no                IN  VARCHAR2     -- 16 : 担当者
    ,iv_creation_date_from    IN  VARCHAR2     -- 17 : 更新時間FROM
    ,iv_creation_date_to      IN  VARCHAR2     -- 18 : 更新時間TO
    ,ov_errbuf                OUT VARCHAR2     -- エラー・メッセージ
    ,ov_retcode               OUT VARCHAR2     -- リターン・コード
    ,ov_errmsg                OUT VARCHAR2     -- ユーザー・エラー・メッセージ
    )
--
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
--
    -- *** ローカル変数 ***
    lt_out_data      tab_data_type_dtl ;
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
    -- 入力パラメータ格納
    -- ===============================================
    gr_param.date_from
      := FND_DATE.CANONICAL_TO_DATE(iv_date_from) ;                     -- 01 : 年月日_FROM
    gr_param.date_to
      := FND_DATE.CANONICAL_TO_DATE(iv_date_to) ;                       -- 02 : 年月日_TO
    gr_param.out_item_ctl        := iv_out_item_ctl ;                   -- 03 : 払出品目区分
    gr_param.item1               := TO_NUMBER(iv_item1) ;               -- 04 : 品目ID1
    gr_param.item2               := TO_NUMBER(iv_item2) ;               -- 05 : 品目ID2
    gr_param.item3               := TO_NUMBER(iv_item3) ;               -- 06 : 品目ID3
    gr_param.reason_code         := iv_reason_code ;                    -- 07 : 事由コード
    gr_param.item_location_id    := TO_NUMBER(iv_item_location_id) ;    -- 08 : 保管倉庫コード
    gr_param.dept_id             := TO_NUMBER(iv_dept_id) ;             -- 09 : 担当部署
    gr_param.entry_no1           := iv_entry_no1 ;                      -- 10 : 伝票No1
    gr_param.entry_no2           := iv_entry_no2 ;                      -- 11 : 伝票No2
    gr_param.entry_no3           := iv_entry_no3 ;                      -- 12 : 伝票No3
    gr_param.entry_no4           := iv_entry_no4 ;                      -- 13 : 伝票No4
    gr_param.entry_no5           := iv_entry_no5 ;                      -- 14 : 伝票No5
    gr_param.price_ctl_flg       := iv_price_ctl_flg ;                  -- 15 : 金額表示
    gr_param.emp_no              := iv_emp_no ;                         -- 16 : 担当者
    gr_param.creation_date_from
      := FND_DATE.CANONICAL_TO_DATE(iv_creation_date_from) ;            -- 17 : 更新時間FROM
    gr_param.creation_date_to
      := FND_DATE.CANONICAL_TO_DATE(iv_creation_date_to) ;              -- 18 : 更新時間TO
    -- ===============================================
    -- 入力パラメータチェック(C-1)
    -- ===============================================
    prc_check_param_info
    (
      ov_errbuf  => lv_errbuf  -- エラー・メッセージ
     ,ov_retcode => lv_retcode -- リターン・コード
     ,ov_errmsg  => lv_errmsg  -- ユーザー・エラー・メッセージ
    ) ;
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF ;
--
    -- ===============================================
    -- データ抽出(C-2)
    -- ===============================================
    -- 抽出データを中間テーブルへ格納
    prc_get_data_to_tmp_table
    (
      ov_errbuf  => lv_errbuf  -- エラー・メッセージ
     ,ov_retcode => lv_retcode -- リターン・コード
     ,ov_errmsg  => lv_errmsg  -- ユーザー・エラー・メッセージ
    );
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF ;
--
    -- 中間テーブルよりデータ取得
    prc_get_data_from_tmp_table
    (
      ot_out_data   => lt_out_data        -- 取得レコード群
     ,ov_errbuf     => lv_errbuf          -- エラー・メッセージ
     ,ov_retcode    => lv_retcode         -- リターン・コード
     ,ov_errmsg     => lv_errmsg          -- ユーザー・エラー・メッセージ
    );
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF ;
--
    -- ===============================================
    -- ＸＭＬデータ作成(C-3/C-4)
    -- ===============================================
    prc_create_xml_data
    (
      it_out_data  => lt_out_data  -- 01.出力対象レコード群
     ,ov_errbuf    => lv_errbuf    -- エラー・メッセージ
     ,ov_retcode   => lv_retcode   -- リターン・コード
     ,ov_errmsg    => lv_errmsg    -- ユーザー・エラー・メッセージ
    ) ;
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF ;
--
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<?xml version="1.0" encoding="shift_jis" ?>' ) ;
    --XMLデータ部出力
    <<xml_loop>>
    FOR i IN 1 .. gt_xml_data_table.COUNT LOOP
      -- 編集したデータをタグに変換
      lv_xml_string := convert_into_xml
                       (
                           iv_name   => gt_xml_data_table(i).tag_name    -- タグネーム
                          ,iv_value  => gt_xml_data_table(i).tag_value   -- タグデータ
                          ,ic_type   => gt_xml_data_table(i).tag_type    -- タグタイプ
                        ) ;
      -- ＸＭＬタグ出力
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, lv_xml_string ) ;
    END LOOP xml_loop ;
--
    -- 中間テーブル登録データの廃棄処理
    ROLLBACK;
--
    -- ==================================================
    -- 終了ステータス設定
    -- ==================================================
    ov_retcode := lv_retcode ;
    ov_errmsg  := lv_errmsg  ;
    ov_errbuf  := lv_errbuf  ;
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
      errbuf                  OUT  VARCHAR2     -- エラーメッセージ
     ,retcode                 OUT  VARCHAR2     -- エラーコード
     ,iv_date_from            IN   VARCHAR2     -- 01 : 年月日_FROM
     ,iv_date_to              IN   VARCHAR2     -- 02 : 年月日_TO
     ,iv_out_item_ctl         IN   VARCHAR2     -- 03 : 払出品目区分
     ,iv_item1                IN   VARCHAR2     -- 04 : 品目ID1
     ,iv_item2                IN   VARCHAR2     -- 05 : 品目ID2
     ,iv_item3                IN   VARCHAR2     -- 06 : 品目ID3
     ,iv_reason_code          IN   VARCHAR2     -- 07 : 事由コード
     ,iv_item_location_id     IN   VARCHAR2     -- 08 : 保管倉庫ID
     ,iv_dept_id              IN   VARCHAR2     -- 09 : 担当部署ID
     ,iv_entry_no1            IN   VARCHAR2     -- 10 : 伝票No1
     ,iv_entry_no2            IN   VARCHAR2     -- 11 : 伝票No2
     ,iv_entry_no3            IN   VARCHAR2     -- 12 : 伝票No3
     ,iv_entry_no4            IN   VARCHAR2     -- 13 : 伝票No4
     ,iv_entry_no5            IN   VARCHAR2     -- 14 : 伝票No5
     ,iv_price_ctl_flg        IN   VARCHAR2     -- 15 : 金額表示
     ,iv_emp_no               IN   VARCHAR2     -- 16 : 担当者
     ,iv_creation_date_from   IN   VARCHAR2     -- 17 : 更新時間FROM
     ,iv_creation_date_to     IN   VARCHAR2     -- 18 : 更新時間TO
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
    submain(
       iv_date_from           -- 01 : 年月日_FROM
      ,iv_date_to             -- 02 : 年月日_TO
      ,iv_out_item_ctl        -- 03 : 払出品目区分
      ,iv_item1               -- 04 : 品目ID1
      ,iv_item2               -- 05 : 品目ID2
      ,iv_item3               -- 06 : 品目ID3
      ,iv_reason_code         -- 07 : 事由コード	
      ,iv_item_location_id    -- 08 : 保管倉庫ID
      ,iv_dept_id             -- 09 : 担当部署ID
      ,iv_entry_no1           -- 10 : 伝票No1
      ,iv_entry_no2           -- 11 : 伝票No2
      ,iv_entry_no3           -- 12 : 伝票No3
      ,iv_entry_no4           -- 13 : 伝票No4
      ,iv_entry_no5           -- 14 : 伝票No5
      ,iv_price_ctl_flg       -- 15 : 金額表示
      ,iv_emp_no              -- 16 : 担当者
      ,iv_creation_date_from  -- 17 : 更新時間FROM
      ,iv_creation_date_to    -- 18 : 更新時間TO
      ,lv_errbuf              -- エラー・メッセージ
      ,lv_retcode             -- リターン・コード
      ,lv_errmsg);            -- ユーザー・エラー・メッセージ
--
--###########################  固定部 START   #####################################################
--
    -- ======================
    -- エラー・メッセージ出力
    -- ======================
    IF ( lv_retcode = gv_status_error ) THEN
      errbuf := lv_errmsg ;
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf) ;
    END IF ;
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
END XXINV550003C;
/
