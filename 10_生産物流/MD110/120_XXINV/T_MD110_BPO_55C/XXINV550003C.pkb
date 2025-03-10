create or replace
PACKAGE BODY XXINV550003C
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : XXINV550003C(body)
 * Description      : 計画・移動・在庫：在庫(帳票)
 * MD.050/070       : T_MD050_BPO_550_在庫(帳票)Issue1.0 (T_MD050_BPO_550)
 *                  : 振替明細表                         (T_MD070_BPO_55C)
 * Version          : 1.23
 * Program List
 * ---------------------------    ----------------------------------------------------------
 *  Name                           Description
 * ---------------------------    ----------------------------------------------------------
 *  prc_check_param_info           パラメータチェック(C-1)
 *  funk_item_ctl_chk              品目のパラメータ相関チェック (C1)
 *  prc_get_prod_pay_data          PROD:生産払出データ取得プロシージャ(C2)
 *  prc_get_prod_pay_schedule_data PROD:生産払出予定データ取得プロシージャ(C2-2)
 *  prc_get_prod_rcv_data          PROD:生産受入データ取得プロシージャ(C2)
 *  prc_get_prod_rcv_schedule_data PROD:生産受入予定データ取得プロシージャ(C2-2)
 *  prc_get_adji_data              ADJI:在庫調整(受払)データ取得プロシージャ(C2)
 *  prc_get_omso_porc_data         OSMO:見本出庫/廃棄 PORC･RMA:見本出庫取消/廃棄取消(C2)
 *  prc_get_data_to_tmp_table      データ加工・中間テーブル更新プロシージャ(C2)
 *  prc_get_data_to_sc_tmp_table   予定情報抽出・加工プロシージャ(C2-2)
 *  prc_get_data_from_tmp_table    データ取得(最終出力データ)プロシージャ(C2)
 *  prc_get_data_from_sc_tmp_table 予定データ取得(最終出力データ)プロシージャ(C2-2)
 *  prc_create_xml_data            ＸＭＬデータ作成(C-3/C-4)
 *  convert_into_xml               XMLデータ変換
 *  submain                        メイン処理プロシージャ
 *  main                           コンカレント実行ファイル登録プロシージャ
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
 *  2008/07/02    1.5  Satoshi Yunba    禁則文字対応
 *  2008/09/26    1.6  Akiyosi Shiina   T_S_528対応
 *  2008/10/16    1.7  Takao Ohashi     T_S_492,T_S_557,T_S_494対応
 *  2008/11/11    1.8  Takao Ohashi     指摘549対応
 *  2008/11/20    1.9  Takao Ohashi     指摘691対応
 *  2008/11/28    1.10 Akiyosi Shiina   本番#227対応
 *  2008/12/06    1.11 Takahito Miyata  本番#521対応 
 *  2008/12/10    1.12 Takao Ohashi     本番#639対応
 *  2008/12/16    1.13 Naoki Fukuda     本番#639対応
 *  2008/12/26    1.14 Takao Ohashi     本番#809,867対応
 *  2009/01/09    1.15 Takao Ohashi     I_S_50対応(履歴全削除)
 *  2009/01/15    1.16 Natsuki Yoshida  I_S_50対応(帳票タイトル対応)、本番#972対応
 *  2009/01/16    1.17 Takao Ohashi     I_S_50対応(予実区分値修正)
 *  2009/01/20    1.18 Akiyoshi Shiina  本番#263対応
 *  2009/03/06    1.19 H.Itou           本番#1283対応
 *  2009/03/12    1.20 Akiyoshi Shiina  本番#1296対応
 *  2009/03/17    1.21 Akiyoshi Shiina  本番#1325対応
 *  2009/05/12    1.22 M.Nomura         本番#1468対応
 *  2009/06/25    1.23 Marushita        本番#1346対応
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
  gc_comp_ind_off           CONSTANT NUMBER       :=  0 ;               -- 未完了
  -- OPM保留在庫トランザクション：削除フラグ
  gc_delete_mark_on         CONSTANT NUMBER       :=  1 ;               -- 完了
  gc_delete_mark_off        CONSTANT NUMBER       :=  0 ;               -- 未完了
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
  gc_batch_status_open      CONSTANT VARCHAR2(1)  := '1' ;              -- 保留
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
--
  gc_lookup_type_purpose_id CONSTANT VARCHAR2(22) := 'XXINV_ITEM_TRANS_CLASS' ; -- 品目振替目的
--
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
  gc_tag_type_t             CONSTANT VARCHAR2(1)  := 'T' ;
  gc_tag_type_d             CONSTANT VARCHAR2(1)  := 'D' ;
  -- プロファイル
  gc_routing_class          CONSTANT VARCHAR2(19) := 'XXINV_DUMMY_ROUTING' ;          -- 品目振替
  gc_routing_class_ret      CONSTANT VARCHAR2(23) := 'XXINV_DUMMY_ROUTING_RET' ;      -- 返品原料
  gc_routing_class_separate CONSTANT VARCHAR2(29) := 'XXINV_DUMMY_ROUTING_SEPARATE' ; -- 解体半製品
  gc_item_class             CONSTANT VARCHAR2(31) := 'XXCMN_ITEM_CATEGORY_ITEM_CLASS' ;
  -- 予実区分
-- mod start ver1.17
--  gc_target_schedule        CONSTANT VARCHAR2(2)  := '10'; -- 予定
  gc_target_schedule        CONSTANT VARCHAR2(2)  := '1'; -- 予定
--  gc_target_result          CONSTANT VARCHAR2(2)  := '20'; -- 実績
  gc_target_result          CONSTANT VARCHAR2(2)  := '2'; -- 実績
-- mod end ver1.17
--
  gc_ukeire                 CONSTANT VARCHAR2(1)  := 'Y' ;              -- 受入
  gc_x977                   CONSTANT VARCHAR2(4)  := 'X977' ;           -- 相手先在庫
--
-- 2009/1/15 v1.16 N.Yoshida add start
  gv_report_title       VARCHAR2(30) ;                              -- 帳票タイトル
  gc_rpt_title_result   CONSTANT  VARCHAR2(30)  := '振　替　明　細　表' ;     -- 実績用
  gc_rpt_title_schedule CONSTANT  VARCHAR2(30)  := '振　替　指　示　明　細　表' ; -- 指示用
-- 2009/1/15 v1.16 N.Yoshida add end
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
-- 2009/01/15 v1.16 N.Yoshida add start
      ,target_class        VARCHAR2(2)
-- 2009/01/15 v1.16 N.Yoshida add end
    ) ;
--
  -- 明細情報データ
  TYPE rec_data_type_dtl IS RECORD
    (
       batch_id            gme_batch_header.batch_id%TYPE                -- 生産バッチID
      ,dept_code           xxcmn_locations2_v.location_code%TYPE         -- 部署コード
      ,dept_name           xxcmn_locations2_v.description%TYPE           -- 部署名称
      ,item_location_code  xxcmn_item_locations2_v.segment1%TYPE         -- 保管倉庫コード
      ,item_location_name  xxcmn_item_locations2_v.description%TYPE      -- 保管倉庫名
      ,item_div_type       xxcmn_item_categories5_v.item_class_code%TYPE -- 品目区分コード
      ,item_div_value      xxcmn_item_categories5_v.item_class_name%TYPE -- 品目区分名称
      ,entry_no            gme_batch_header.batch_no%TYPE                -- 伝票NO
      ,entry_date          gme_batch_header.actual_cmplt_date%TYPE       -- 入出庫日
      ,pay_reason_code     xxcmn_rcv_pay_mst.new_div_invent%TYPE         -- 払出事由コード
      ,pay_reason_name     fnd_lookup_values.meaning%TYPE                -- 払出事由名称
      ,pay_purpose_name    fnd_lookup_values.attribute1%TYPE             -- 払出品目振替目的
      ,pay_item_no         xxcmn_item_mst2_v.item_no%TYPE                -- 払出品目コード
      ,pay_item_name       xxcmn_item_mst2_v.item_short_name%TYPE        -- 払出品目名称
      ,pay_lot_no          ic_lots_mst.lot_no%TYPE                       -- 払出ロットNO
-- 2009/03/12 v1.20 ADD START
      ,pay_rank1           ic_lots_mst.attribute14%TYPE                  -- 払出ランク１
-- 2009/03/12 v1.20 ADD END
      ,pay_quant           NUMBER                                        -- 払出総数
      ,pay_unt_price       ic_lots_mst.attribute7%TYPE                   -- 払出単価
      ,rcv_reason_code     xxcmn_rcv_pay_mst.new_div_invent%TYPE         -- 受入事由コード
      ,rcv_reason_name     fnd_lookup_values.meaning%TYPE                -- 受入事由名称
      ,rcv_purpose_name    fnd_lookup_values.attribute1%TYPE             -- 受入品目振替目的
      ,rcv_item_no         xxcmn_item_mst2_v.item_no%TYPE                -- 受入品目コード
      ,rcv_item_name       xxcmn_item_mst2_v.item_short_name%TYPE        -- 受入品目名称
      ,rcv_lot_no          ic_lots_mst.lot_no%TYPE                       -- 受入ロットNO
-- 2009/03/12 v1.20 ADD START
      ,rcv_rank1           ic_lots_mst.attribute14%TYPE                  -- 受入ランク１
-- 2009/03/12 v1.20 ADD END
      ,rcv_quant           NUMBER                                        -- 受入総数
      ,rcv_unt_price       ic_lots_mst.attribute7%TYPE                   -- 受入単価
-- 2009/01/20 v1.18 ADD START
      ,description         VARCHAR2(240)                                 -- 摘要
-- 2009/01/20 v1.18 ADD END
    ) ;
  TYPE tab_data_type_dtl IS TABLE OF rec_data_type_dtl INDEX BY BINARY_INTEGER ;
--
  gt_main_data              tab_data_type_dtl ;       -- 取得レコード表
  gt_xml_data_table         XML_DATA ;                -- ＸＭＬデータタグ表
  gl_xml_idx                NUMBER ;                  -- ＸＭＬデータタグ表のインデックス
--
  gr_param                  rec_param_data ;          -- 入力パラメータ
--
  gv_sql_date_from DATE ; -- SQL文：パラメータDATE_FROM部
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
    FROM xxcmn_item_categories5_v
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
    lv_sql_body    VARCHAR2(20000);  -- SQL文：本体
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
    lv_sql_body := lv_sql_body || ' SELECT /*+ leading(gbh itp xrpm iimb ximb gic mcb mct) use_nl(gbh itp xrpm iimb ximb gic mcb mct) */' ;
    lv_sql_body := lv_sql_body || '  gbh.batch_id                AS batch_id' ;
    lv_sql_body := lv_sql_body || ' ,xlv.location_code           AS dept_code' ;
    lv_sql_body := lv_sql_body || ' ,xlv.description             AS dept_name' ;
    lv_sql_body := lv_sql_body || ' ,xilv.segment1               AS item_location_code' ;
    lv_sql_body := lv_sql_body || ' ,xilv.description            AS item_location_name' ;
    lv_sql_body := lv_sql_body || ' ,mcb.segment1                AS item_div_type' ;
    lv_sql_body := lv_sql_body || ' ,mct.description             AS item_div_value' ;
    lv_sql_body := lv_sql_body || ' ,gbh.batch_no                AS entry_no' ;
    lv_sql_body := lv_sql_body || ' ,gbh.actual_cmplt_date       AS entry_date' ;
    lv_sql_body := lv_sql_body || ' ,xrpm.new_div_invent         AS pay_reason_code' ;
    lv_sql_body := lv_sql_body || ' ,flv.meaning                 AS pay_reason_name' ;
-- 2009/03/17 v1.21 UPDATE START
--    lv_sql_body := lv_sql_body || ' ,flv2.attribute1             AS pay_purpose_name' ;
    lv_sql_body := lv_sql_body || ' ,NULL                        AS pay_purpose_name' ;
-- 2009/03/17 v1.21 UPDATE END
    lv_sql_body := lv_sql_body || ' ,iimb.item_no                AS pay_item_no' ;
    lv_sql_body := lv_sql_body || ' ,ximb.item_short_name        AS pay_item_name' ;
    lv_sql_body := lv_sql_body || ' ,ilm.lot_no                  AS pay_lot_no' ;
-- 2009/03/12 v1.20 ADD START
    lv_sql_body := lv_sql_body || ' ,ilm. attribute14            AS pay_rank1' ;
-- 2009/03/12 v1.20 ADD END
    lv_sql_body := lv_sql_body || ' ,ROUND(ABS(itp.trans_qty),4) AS pay_quant' ;
    lv_sql_body := lv_sql_body || ' ,CASE iimb.attribute15' ;
    lv_sql_body := lv_sql_body || '    WHEN :para_cost_manage_code_n THEN' ;
    lv_sql_body := lv_sql_body || '      ROUND(NVL(xsupv.stnd_unit_price,0),3)' ;
    lv_sql_body := lv_sql_body || '    WHEN :para_cost_manage_code_j THEN' ;
    lv_sql_body := lv_sql_body || '      ROUND(TO_NUMBER(NVL(ilm.attribute7,0)),3)' ;
    lv_sql_body := lv_sql_body || '    ELSE ' ;
    lv_sql_body := lv_sql_body || '      ' || gc_cost_0 ;
    lv_sql_body := lv_sql_body || '  END                         AS pay_unt_price' ;
    lv_sql_body := lv_sql_body || ' ,NULL                        AS rcv_reason_code' ;
    lv_sql_body := lv_sql_body || ' ,NULL                        AS rcv_reason_name' ;
    lv_sql_body := lv_sql_body || ' ,NULL                        AS rcv_purpose_name' ;
    lv_sql_body := lv_sql_body || ' ,NULL                        AS rcv_item_no' ;
    lv_sql_body := lv_sql_body || ' ,NULL                        AS rcv_item_name' ;
    lv_sql_body := lv_sql_body || ' ,NULL                        AS rcv_lot_no' ;
-- 2009/03/12 v1.20 ADD START
    lv_sql_body := lv_sql_body || ' ,NULL                        AS rcv_rank1' ;
-- 2009/03/12 v1.20 ADD END
    lv_sql_body := lv_sql_body || ' ,0                           AS rcv_quant' ;
    lv_sql_body := lv_sql_body || ' ,0                           AS rcv_unt_price' ;
-- 2009/01/20 v1.18 ADD START
    lv_sql_body := lv_sql_body || ' ,gbh. attribute6             AS description' ;
-- 2009/01/20 v1.18 ADD END
    ---------------------------------------------------------------------------------------
    -- FROM句
    lv_sql_body := lv_sql_body || ' FROM xxcmn_item_mst_b     ximb' ;
    lv_sql_body := lv_sql_body || ' ,ic_item_mst_b            iimb' ;
    lv_sql_body := lv_sql_body || ' ,gmi_item_categories      gic' ;
    lv_sql_body := lv_sql_body || ' ,mtl_categories_b         mcb' ;
    lv_sql_body := lv_sql_body || ' ,mtl_categories_tl        mct' ;
    lv_sql_body := lv_sql_body || ' ,ic_lots_mst              ilm' ;
-- 2009/01/15 v1.16 N.Yoshida mod start
--    lv_sql_body := lv_sql_body || ' ,xxinv_rcv_pay_mst2_v     xrpm' ;
    lv_sql_body := lv_sql_body || ' ,xxcmn_rcv_pay_mst        xrpm' ;
    lv_sql_body := lv_sql_body || ' ,gme_material_details     gmd' ;
    lv_sql_body := lv_sql_body || ' ,gmd_routings_b           grb' ;
-- 2009/01/15 v1.16 N.Yoshida mod end
    lv_sql_body := lv_sql_body || ' ,gme_batch_header         gbh' ;
    lv_sql_body := lv_sql_body || ' ,ic_tran_pnd              itp' ;
    lv_sql_body := lv_sql_body || ' ,xxcmn_item_locations2_v  xilv' ;
    lv_sql_body := lv_sql_body || ' ,xxcmn_locations2_v       xlv' ;
    lv_sql_body := lv_sql_body || ' ,fnd_lookup_values        flv' ;
-- 2009/03/17 v1.21 DELETE START
--    lv_sql_body := lv_sql_body || ' ,fnd_lookup_values        flv2' ;
-- 2009/03/17 v1.21 DELETE END
    lv_sql_body := lv_sql_body || ' ,xxcmn_stnd_unit_price_v  xsupv' ;
    lv_sql_body := lv_sql_body || ' ,fnd_user                 fu' ;
    lv_sql_body := lv_sql_body || ' ,per_all_assignments_f    paaf' ;
    lv_sql_body := lv_sql_body || ' ,per_all_people_f         papf' ;
    ------------------------------------------------------------
    -- WHERE句
    -- OPM保留在庫トランザクション絞込
    lv_sql_body := lv_sql_body || ' WHERE itp.line_type            = :para_line_type_pay ';
    lv_sql_body := lv_sql_body || ' AND itp.doc_type               = :para_doc_type_prod ';
    lv_sql_body := lv_sql_body || ' AND itp.completed_ind          = :para_comp_ind_on   ';
    lv_sql_body := lv_sql_body || ' AND itp.reverse_id             IS NULL' ;
-- 2009/01/15 v1.16 N.Yoshida mod start
--    lv_sql_body := lv_sql_body || ' AND xrpm.doc_id                = itp.doc_id';
--    lv_sql_body := lv_sql_body || ' AND xrpm.doc_line              = itp.doc_line';
    lv_sql_body := lv_sql_body || ' AND gmd.batch_id                = itp.doc_id';
    lv_sql_body := lv_sql_body || ' AND gmd.line_no                 = itp.doc_line';
    -- 受払区分マスタ絞込み
    lv_sql_body := lv_sql_body || ' AND xrpm.doc_type               = ''PROD''';
    lv_sql_body := lv_sql_body || ' AND xrpm.routing_class          <> ''70''';
    lv_sql_body := lv_sql_body || ' AND gbh.batch_id                = gmd.batch_id';
    lv_sql_body := lv_sql_body || ' AND grb.routing_id              = gbh.routing_id';
    lv_sql_body := lv_sql_body || ' AND xrpm.routing_class          = grb.routing_class';
    lv_sql_body := lv_sql_body || ' AND xrpm.line_type              = gmd.line_type';
    lv_sql_body := lv_sql_body || ' AND ((( gmd.attribute5        IS NULL )';
    lv_sql_body := lv_sql_body || ' AND ( xrpm.hit_in_div       IS NULL ))';
    lv_sql_body := lv_sql_body || ' OR  (( gmd.attribute5        IS NOT NULL )';
    lv_sql_body := lv_sql_body || ' AND ( xrpm.hit_in_div       = gmd.attribute5 )))';
-- 2009/01/15 v1.16 N.Yoshida mod end
    lv_sql_body := lv_sql_body || ' AND xrpm.line_type             = itp.line_type';
    lv_sql_body := lv_sql_body || ' AND xrpm.use_div_invent_rep    = :para_use_div_invent_rep ';
    -- 工順=返品原料/解体半製品/品目振替
    lv_sql_body := lv_sql_body || ' AND xrpm.routing_class IN(' ;
    lv_sql_body := lv_sql_body ||  ' :para_routing_class          ,' ;
    lv_sql_body := lv_sql_body ||  ' :para_routing_class_ret      ,' ;
    lv_sql_body := lv_sql_body ||  ' :para_routing_class_separate )' ;
    -- 生産バッチ結合
    lv_sql_body := lv_sql_body || ' AND itp.doc_id                 = gbh.batch_id' ;
    lv_sql_body := lv_sql_body || ' AND gbh.batch_status           = :para_batch_status_close ' ;
    -- OPM品目情報VIEW結合
    lv_sql_body := lv_sql_body || ' AND itp.item_id                = iimb.item_id' ;
    lv_sql_body := lv_sql_body || ' AND :para_sql_date_from BETWEEN ximb.start_date_active' ;
    lv_sql_body := lv_sql_body || '   AND ximb.end_date_active' ;
    -- OPM品目カテゴリ割当情報VIEW結合
    lv_sql_body := lv_sql_body || ' AND ximb.item_id  = iimb.item_id' ;
    lv_sql_body := lv_sql_body || ' AND iimb.item_id  = gic.item_id' ;
    lv_sql_body := lv_sql_body || ' AND mcb.segment1       IN (' ;
    lv_sql_body := lv_sql_body ||  ' :para_item_class_code_1,' ;
    lv_sql_body := lv_sql_body ||  ' :para_item_class_code_4,' ;
    lv_sql_body := lv_sql_body ||  ' :para_item_class_code_5)' ;
    lv_sql_body := lv_sql_body || ' AND mct.source_lang        = :para_language_code ' ;
    lv_sql_body := lv_sql_body || ' AND mct.language           = :para_language_code ' ;
    lv_sql_body := lv_sql_body || ' AND mcb.category_id        = mct.category_id' ;
    lv_sql_body := lv_sql_body || ' AND gic.category_id        = mcb.category_id' ;
    lv_sql_body := lv_sql_body || ' AND gic.category_set_id    = FND_PROFILE.VALUE(:para_item_class)' ;
    -- 標準原価情報VIEW結合
    lv_sql_body := lv_sql_body || ' AND xsupv.item_id(+)           = itp.item_id ' ;
    lv_sql_body := lv_sql_body || ' AND :para_sql_date_from BETWEEN ';
    lv_sql_body := lv_sql_body || '   xsupv.start_date_active(+)' ;
    lv_sql_body := lv_sql_body || '     AND xsupv.end_date_active(+)' ;
    -- OPMロットマスタ結合
    lv_sql_body := lv_sql_body || ' AND itp.lot_id                 = ilm.lot_id' ;
    lv_sql_body := lv_sql_body || ' AND itp.item_id                = ilm.item_id' ;
    -- クイックコード(新区分)結合
    lv_sql_body := lv_sql_body || ' AND flv.lookup_type            = :para_lookup_type_new_div ' ;
    lv_sql_body := lv_sql_body || ' AND flv.language               = :para_language_code ' ;
    lv_sql_body := lv_sql_body || ' AND flv.lookup_code            = xrpm.new_div_invent ';
    -- クイックコード(品目振替目的)結合
-- 2009/03/17 v1.21 DELETE START
--    lv_sql_body := lv_sql_body || ' AND flv2.lookup_type(+)           = :para_lookup_type_purpose_id ' ;
--    lv_sql_body := lv_sql_body || ' AND flv2.language(+)              = :para_language_code ' ;
--    lv_sql_body := lv_sql_body || ' AND flv2.lookup_code(+)           = gbh.attribute7 ';
-- 2009/03/17 v1.21 DELETE END
    -- ユーザマスタ結合
    lv_sql_body := lv_sql_body || ' AND fu.user_id                 = gbh.created_by' ;
    -- 従業員マスタ結合
    lv_sql_body := lv_sql_body || ' AND fu.employee_id             = paaf.person_id' ;
    lv_sql_body := lv_sql_body || ' AND :para_sql_date_from BETWEEN paaf.effective_start_date' ;
    lv_sql_body := lv_sql_body || '                                    AND paaf.effective_end_date' ;
    lv_sql_body := lv_sql_body || ' AND papf.person_id             = paaf.person_id' ;
    lv_sql_body := lv_sql_body || ' AND :para_sql_date_from BETWEEN papf.effective_start_date' ;
    lv_sql_body := lv_sql_body || '                                    AND papf.effective_end_date' ;
    -- 事業所情報VIEW結合
    lv_sql_body := lv_sql_body || ' AND xlv.location_id            = paaf.location_id' ;
    lv_sql_body := lv_sql_body || ' AND :para_sql_date_from BETWEEN ';
    lv_sql_body := lv_sql_body || '   xlv.start_date_active' ;
    lv_sql_body := lv_sql_body || '     AND xlv.end_date_active' ;
    -- OPM保管場所情報VIEW結合
    lv_sql_body := lv_sql_body || ' AND xilv.whse_code             = itp.whse_code' ;
    lv_sql_body := lv_sql_body || ' AND xilv.segment1              = itp.location' ;
    -------------------------------------------------------------------------------
    --必須パラメータ絞込
    --  1．年月日_FROM
    --  2．年月日_TO
    lv_sql_body := lv_sql_body || ' AND gbh.actual_cmplt_date BETWEEN FND_DATE.STRING_TO_DATE(';
    lv_sql_body := lv_sql_body || ' TO_CHAR(:para_param_date_from, :para_date_mask) ' ;
    lv_sql_body := lv_sql_body || ', :para_date_mask)' ;
    lv_sql_body := lv_sql_body || '                                    AND FND_DATE.STRING_TO_DATE(';
    lv_sql_body := lv_sql_body || ' TO_CHAR(:para_param_date_to, :para_date_mask) ' ;
    lv_sql_body := lv_sql_body || ', :para_date_mask)' ;
    -------------------------------------------------------------------------------
    --  3．払出品目区分
    IF (gr_param.out_item_ctl IS NOT NULL) THEN
      lv_sql_body := lv_sql_body || ' AND mcb.segment1 =' || cv_sc || gr_param.out_item_ctl || cv_sc;
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
-- mod start ver1.17
--      lv_sql_body := lv_sql_body || ' AND gbh.creation_date >= FND_DATE.STRING_TO_DATE(';
      lv_sql_body := lv_sql_body || ' AND itp.last_update_date >= FND_DATE.STRING_TO_DATE(';
-- mod end ver1.17
      lv_sql_body := lv_sql_body || ''''  || TO_CHAR(gr_param.creation_date_from,gc_date_mask) || '''' ;
      lv_sql_body := lv_sql_body || ',''' || gc_date_mask || ''')' ;
    END IF ;
    -- 更新時間TO
    IF (gr_param.creation_date_to IS NOT NULL) THEN
-- mod start ver1.17
--      lv_sql_body := lv_sql_body || ' AND gbh.creation_date <= FND_DATE.STRING_TO_DATE(';
      lv_sql_body := lv_sql_body || ' AND itp.last_update_date <= FND_DATE.STRING_TO_DATE(';
-- mod end ver1.17
      lv_sql_body := lv_sql_body || ''''  || TO_CHAR(gr_param.creation_date_to,gc_date_mask) || '''' ;
      lv_sql_body := lv_sql_body || ',''' || gc_date_mask || ''')' ;
    END IF ;
--
    -- SQL本体
    lv_sql_body := lv_sql_body || ' UNION ALL ' ;
    lv_sql_body := lv_sql_body || ' SELECT /*+ leading(gbh itp xrpm iimb ximb gic mcb mct) use_nl(gbh itp xrpm iimb ximb gic mcb mct) */' ;
    lv_sql_body := lv_sql_body || '  gbh.batch_id                AS batch_id' ;
    lv_sql_body := lv_sql_body || ' ,xlv.location_code           AS dept_code' ;
    lv_sql_body := lv_sql_body || ' ,xlv.description             AS dept_name' ;
    lv_sql_body := lv_sql_body || ' ,xilv.segment1               AS item_location_code' ;
    lv_sql_body := lv_sql_body || ' ,xilv.description            AS item_location_name' ;
    lv_sql_body := lv_sql_body || ' ,mcb.segment1                AS item_div_type' ;
    lv_sql_body := lv_sql_body || ' ,mct.description             AS item_div_value' ;
    lv_sql_body := lv_sql_body || ' ,gbh.batch_no                AS entry_no' ;
    lv_sql_body := lv_sql_body || ' ,gbh.actual_cmplt_date       AS entry_date' ;
    lv_sql_body := lv_sql_body || ' ,xrpm.new_div_invent         AS pay_reason_code' ;
    lv_sql_body := lv_sql_body || ' ,flv.meaning                 AS pay_reason_name' ;
    lv_sql_body := lv_sql_body || ' ,flv2.attribute1             AS pay_purpose_name' ;
    lv_sql_body := lv_sql_body || ' ,iimb.item_no                AS pay_item_no' ;
    lv_sql_body := lv_sql_body || ' ,ximb.item_short_name        AS pay_item_name' ;
    lv_sql_body := lv_sql_body || ' ,ilm.lot_no                  AS pay_lot_no' ;
-- 2009/03/12 v1.20 ADD START
    lv_sql_body := lv_sql_body || ' ,ilm. attribute14            AS pay_rank1' ;
-- 2009/03/12 v1.20 ADD END
    lv_sql_body := lv_sql_body || ' ,ROUND(ABS(itp.trans_qty),4) AS pay_quant' ;
    lv_sql_body := lv_sql_body || ' ,CASE iimb.attribute15' ;
    lv_sql_body := lv_sql_body || '    WHEN :para_cost_manage_code_n THEN' ;
    lv_sql_body := lv_sql_body || '      ROUND(NVL(xsupv.stnd_unit_price,0),3)' ;
    lv_sql_body := lv_sql_body || '    WHEN :para_cost_manage_code_j THEN' ;
    lv_sql_body := lv_sql_body || '      ROUND(TO_NUMBER(NVL(ilm.attribute7,0)),3)' ;
    lv_sql_body := lv_sql_body || '    ELSE ' ;
    lv_sql_body := lv_sql_body || '      ' || gc_cost_0 ;
    lv_sql_body := lv_sql_body || '  END                         AS pay_unt_price' ;
    lv_sql_body := lv_sql_body || ' ,NULL                        AS rcv_reason_code' ;
    lv_sql_body := lv_sql_body || ' ,NULL                        AS rcv_reason_name' ;
    lv_sql_body := lv_sql_body || ' ,NULL                        AS rcv_purpose_name' ;
    lv_sql_body := lv_sql_body || ' ,NULL                        AS rcv_item_no' ;
    lv_sql_body := lv_sql_body || ' ,NULL                        AS rcv_item_name' ;
    lv_sql_body := lv_sql_body || ' ,NULL                        AS rcv_lot_no' ;
-- 2009/03/12 v1.20 ADD START
    lv_sql_body := lv_sql_body || ' ,NULL                        AS rcv_rank1' ;
-- 2009/03/12 v1.20 ADD END
    lv_sql_body := lv_sql_body || ' ,0                           AS rcv_quant' ;
    lv_sql_body := lv_sql_body || ' ,0                           AS rcv_unt_price' ;
-- 2009/01/20 v1.18 ADD START
    lv_sql_body := lv_sql_body || ' ,gbh. attribute6             AS description' ;
-- 2009/01/20 v1.18 ADD END
    ---------------------------------------------------------------------------------------
    -- FROM句
    lv_sql_body := lv_sql_body || ' FROM xxcmn_item_mst_b     ximb' ;
    lv_sql_body := lv_sql_body || ' ,ic_item_mst_b            iimb' ;
    lv_sql_body := lv_sql_body || ' ,gmi_item_categories      gic' ;
    lv_sql_body := lv_sql_body || ' ,mtl_categories_b         mcb' ;
    lv_sql_body := lv_sql_body || ' ,mtl_categories_tl        mct' ;
    lv_sql_body := lv_sql_body || ' ,ic_lots_mst              ilm' ;
-- 2009/01/15 v1.16 N.Yoshida mod start
--    lv_sql_body := lv_sql_body || ' ,xxinv_rcv_pay_mst2_v     xrpm' ;
    lv_sql_body := lv_sql_body || ' ,xxcmn_rcv_pay_mst        xrpm' ;
    lv_sql_body := lv_sql_body || ' ,gme_material_details     gmd' ;
    lv_sql_body := lv_sql_body || ' ,gmd_routings_b           grb' ;
-- 2009/01/15 v1.16 N.Yoshida mod end
    lv_sql_body := lv_sql_body || ' ,gme_batch_header         gbh' ;
    lv_sql_body := lv_sql_body || ' ,ic_tran_pnd              itp' ;
    lv_sql_body := lv_sql_body || ' ,xxcmn_item_locations2_v  xilv' ;
    lv_sql_body := lv_sql_body || ' ,xxcmn_locations2_v       xlv' ;
    lv_sql_body := lv_sql_body || ' ,fnd_lookup_values        flv' ;
    lv_sql_body := lv_sql_body || ' ,fnd_lookup_values        flv2' ;
    lv_sql_body := lv_sql_body || ' ,xxcmn_stnd_unit_price_v  xsupv' ;
    lv_sql_body := lv_sql_body || ' ,fnd_user                 fu' ;
    lv_sql_body := lv_sql_body || ' ,per_all_assignments_f    paaf' ;
    lv_sql_body := lv_sql_body || ' ,per_all_people_f         papf' ;
    ------------------------------------------------------------
    -- WHERE句
    -- OPM保留在庫トランザクション絞込
    lv_sql_body := lv_sql_body || ' WHERE itp.line_type            = :para_line_type_pay ';
    lv_sql_body := lv_sql_body || ' AND itp.doc_type               = :para_doc_type_prod ';
    lv_sql_body := lv_sql_body || ' AND itp.completed_ind          = :para_comp_ind_on   ';
    lv_sql_body := lv_sql_body || ' AND itp.reverse_id             IS NULL' ;
-- 2009/01/15 v1.16 N.Yoshida mod start
--    lv_sql_body := lv_sql_body || ' AND xrpm.doc_id                = itp.doc_id';
--    lv_sql_body := lv_sql_body || ' AND xrpm.doc_line              = itp.doc_line';
    lv_sql_body := lv_sql_body || ' AND gmd.batch_id                = itp.doc_id';
    lv_sql_body := lv_sql_body || ' AND gmd.line_no                 = itp.doc_line';
    -- 受払区分マスタ絞込み
    lv_sql_body := lv_sql_body || ' AND xrpm.doc_type               = ''PROD''';
    lv_sql_body := lv_sql_body || ' AND xrpm.routing_class          = ''70''';
    lv_sql_body := lv_sql_body || ' AND gbh.batch_id                = gmd.batch_id';
    lv_sql_body := lv_sql_body || ' AND grb.routing_id              = gbh.routing_id';
    lv_sql_body := lv_sql_body || ' AND xrpm.routing_class          = grb.routing_class';
    lv_sql_body := lv_sql_body || ' AND xrpm.line_type              = gmd.line_type';
    lv_sql_body := lv_sql_body || ' AND ((( gmd.attribute5        IS NULL )';
    lv_sql_body := lv_sql_body || ' AND ( xrpm.hit_in_div       IS NULL ))';
    lv_sql_body := lv_sql_body || ' OR  (( gmd.attribute5        IS NOT NULL )';
    lv_sql_body := lv_sql_body || ' AND ( xrpm.hit_in_div       = gmd.attribute5 )))';
    lv_sql_body := lv_sql_body || ' AND    EXISTS';
    lv_sql_body := lv_sql_body || ' ( SELECT 1';
    lv_sql_body := lv_sql_body || '   FROM  gme_batch_header         gbh_item';
    lv_sql_body := lv_sql_body || '        ,gme_material_details     gmd_item';
    lv_sql_body := lv_sql_body || '        ,gmd_routings_b           grb_item';
    lv_sql_body := lv_sql_body || '        ,xxcmn_item_categories4_v xicv';
    lv_sql_body := lv_sql_body || '   WHERE gbh_item.batch_id      = gmd_item.batch_id';
    lv_sql_body := lv_sql_body || '   AND   gbh_item.routing_id    = grb_item.routing_id';
    lv_sql_body := lv_sql_body || '   AND   grb_item.routing_class = ''70''';
    lv_sql_body := lv_sql_body || '   AND   gmd_item.item_id       = xicv.item_id';
    lv_sql_body := lv_sql_body || '   AND   gmd_item.batch_id      = gmd.batch_id';
    lv_sql_body := lv_sql_body || '   AND   gmd_item.line_no       = gmd.line_no';
    lv_sql_body := lv_sql_body || '   GROUP BY gbh_item.batch_id';
    lv_sql_body := lv_sql_body || '           ,gmd_item.line_no';
    lv_sql_body := lv_sql_body || '   HAVING xrpm.item_div_origin = MAX(DECODE(gmd_item.line_type,-1,xicv.item_class_code,NULL))';
    lv_sql_body := lv_sql_body || '   AND    xrpm.item_div_ahead  = MAX(DECODE(gmd_item.line_type, 1,xicv.item_class_code,NULL)))';
-- 2009/01/15 v1.16 N.Yoshida mod end
    lv_sql_body := lv_sql_body || ' AND xrpm.line_type             = itp.line_type';
    lv_sql_body := lv_sql_body || ' AND xrpm.use_div_invent_rep    = :para_use_div_invent_rep ';
    -- 工順=返品原料/解体半製品/品目振替
    lv_sql_body := lv_sql_body || ' AND xrpm.routing_class IN(' ;
    lv_sql_body := lv_sql_body ||  ' :para_routing_class          ,' ;
    lv_sql_body := lv_sql_body ||  ' :para_routing_class_ret      ,' ;
    lv_sql_body := lv_sql_body ||  ' :para_routing_class_separate )' ;
    -- 生産バッチ結合
    lv_sql_body := lv_sql_body || ' AND itp.doc_id                 = gbh.batch_id' ;
    lv_sql_body := lv_sql_body || ' AND gbh.batch_status           = :para_batch_status_close ' ;
    -- OPM品目情報VIEW結合
    lv_sql_body := lv_sql_body || ' AND itp.item_id                = iimb.item_id' ;
    lv_sql_body := lv_sql_body || ' AND :para_sql_date_from BETWEEN ximb.start_date_active' ;
    lv_sql_body := lv_sql_body || '   AND ximb.end_date_active' ;
    -- OPM品目カテゴリ割当情報VIEW結合
    lv_sql_body := lv_sql_body || ' AND ximb.item_id  = iimb.item_id' ;
    lv_sql_body := lv_sql_body || ' AND iimb.item_id  = gic.item_id' ;
    lv_sql_body := lv_sql_body || ' AND mcb.segment1       IN (' ;
    lv_sql_body := lv_sql_body ||  ' :para_item_class_code_1,' ;
    lv_sql_body := lv_sql_body ||  ' :para_item_class_code_4,' ;
    lv_sql_body := lv_sql_body ||  ' :para_item_class_code_5)' ;
    lv_sql_body := lv_sql_body || ' AND mct.source_lang        = :para_language_code ' ;
    lv_sql_body := lv_sql_body || ' AND mct.language           = :para_language_code ' ;
    lv_sql_body := lv_sql_body || ' AND mcb.category_id        = mct.category_id' ;
    lv_sql_body := lv_sql_body || ' AND gic.category_id        = mcb.category_id' ;
    lv_sql_body := lv_sql_body || ' AND gic.category_set_id    = FND_PROFILE.VALUE(:para_item_class)' ;
    -- 標準原価情報VIEW結合
    lv_sql_body := lv_sql_body || ' AND xsupv.item_id(+)           = itp.item_id ' ;
    lv_sql_body := lv_sql_body || ' AND :para_sql_date_from BETWEEN ';
    lv_sql_body := lv_sql_body || '   xsupv.start_date_active(+)' ;
    lv_sql_body := lv_sql_body || '     AND xsupv.end_date_active(+)' ;
    -- OPMロットマスタ結合
    lv_sql_body := lv_sql_body || ' AND itp.lot_id                 = ilm.lot_id' ;
    lv_sql_body := lv_sql_body || ' AND itp.item_id                = ilm.item_id' ;
    -- クイックコード(新区分)結合
    lv_sql_body := lv_sql_body || ' AND flv.lookup_type            = :para_lookup_type_new_div ' ;
    lv_sql_body := lv_sql_body || ' AND flv.language               = :para_language_code ' ;
    lv_sql_body := lv_sql_body || ' AND flv.lookup_code            = xrpm.new_div_invent ';
    -- クイックコード(品目振替目的)結合
    lv_sql_body := lv_sql_body || ' AND flv2.lookup_type           = :para_lookup_type_purpose_id ' ;
    lv_sql_body := lv_sql_body || ' AND flv2.language              = :para_language_code ' ;
    lv_sql_body := lv_sql_body || ' AND flv2.lookup_code           = gbh.attribute7 ';
    -- ユーザマスタ結合
    lv_sql_body := lv_sql_body || ' AND fu.user_id                 = gbh.created_by' ;
    -- 従業員マスタ結合
    lv_sql_body := lv_sql_body || ' AND fu.employee_id             = paaf.person_id' ;
    lv_sql_body := lv_sql_body || ' AND :para_sql_date_from BETWEEN paaf.effective_start_date' ;
    lv_sql_body := lv_sql_body || '                                    AND paaf.effective_end_date' ;
    lv_sql_body := lv_sql_body || ' AND papf.person_id             = paaf.person_id' ;
    lv_sql_body := lv_sql_body || ' AND :para_sql_date_from BETWEEN papf.effective_start_date' ;
    lv_sql_body := lv_sql_body || '                                    AND papf.effective_end_date' ;
    -- 事業所情報VIEW結合
    lv_sql_body := lv_sql_body || ' AND xlv.location_id            = paaf.location_id' ;
    lv_sql_body := lv_sql_body || ' AND :para_sql_date_from BETWEEN ';
    lv_sql_body := lv_sql_body || '   xlv.start_date_active' ;
    lv_sql_body := lv_sql_body || '     AND xlv.end_date_active' ;
    -- OPM保管場所情報VIEW結合
    lv_sql_body := lv_sql_body || ' AND xilv.whse_code             = itp.whse_code' ;
    lv_sql_body := lv_sql_body || ' AND xilv.segment1              = itp.location' ;
    -------------------------------------------------------------------------------
    --必須パラメータ絞込
    --  1．年月日_FROM
    --  2．年月日_TO
    lv_sql_body := lv_sql_body || ' AND gbh.actual_cmplt_date BETWEEN FND_DATE.STRING_TO_DATE(';
    lv_sql_body := lv_sql_body || ' TO_CHAR(:para_param_date_from, :para_date_mask) ' ;
    lv_sql_body := lv_sql_body || ', :para_date_mask)' ;
    lv_sql_body := lv_sql_body || '                                    AND FND_DATE.STRING_TO_DATE(';
    lv_sql_body := lv_sql_body || ' TO_CHAR(:para_param_date_to, :para_date_mask) ' ;
    lv_sql_body := lv_sql_body || ', :para_date_mask)' ;
    -------------------------------------------------------------------------------
    --  3．払出品目区分
    IF (gr_param.out_item_ctl IS NOT NULL) THEN
      lv_sql_body := lv_sql_body || ' AND mcb.segment1 =' || cv_sc || gr_param.out_item_ctl || cv_sc;
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
    -- 伝票No
    IF (lv_work_str IS NOT NULL) THEN
      lv_sql_body := lv_sql_body || ' AND gbh.batch_no IN('||lv_work_str || ')';
    END IF ;
    -- パラメータ絞込(品目ID)
    -- 品目
    IF (lv_work_str_2 IS NOT NULL) THEN
      lv_sql_body := lv_sql_body || ' AND itp.item_id IN('||lv_work_str_2 || ')';
    END IF ;
    -- 担当者
    IF (gr_param.emp_no IS NOT NULL) THEN
      lv_sql_body := lv_sql_body || ' AND papf.employee_number = ''' || gr_param.emp_no || '''';
    END IF ;
    -- 更新時間FROM
    IF (gr_param.creation_date_from IS NOT NULL) THEN
-- mod start ver1.17
--      lv_sql_body := lv_sql_body || ' AND gbh.creation_date >= FND_DATE.STRING_TO_DATE(';
      lv_sql_body := lv_sql_body || ' AND itp.last_update_date >= FND_DATE.STRING_TO_DATE(';
-- mod end ver1.17
      lv_sql_body := lv_sql_body || ''''  || TO_CHAR(gr_param.creation_date_from,gc_date_mask) || '''' ;
      lv_sql_body := lv_sql_body || ',''' || gc_date_mask || ''')' ;
    END IF ;
    -- 更新時間TO
    IF (gr_param.creation_date_to IS NOT NULL) THEN
-- mod start ver1.17
--      lv_sql_body := lv_sql_body || ' AND gbh.creation_date <= FND_DATE.STRING_TO_DATE(';
      lv_sql_body := lv_sql_body || ' AND itp.last_update_date <= FND_DATE.STRING_TO_DATE(';
-- mod end ver1.17
      lv_sql_body := lv_sql_body || ''''  || TO_CHAR(gr_param.creation_date_to,gc_date_mask) || '''' ;
      lv_sql_body := lv_sql_body || ',''' || gc_date_mask || ''')' ;
    END IF ;
    ---------------------------------------------------------------------------------------------
    --ORDER BY 句
-- 2009/01/15 v1.16 N.Yoshida mod start
--    lv_sql_body := lv_sql_body || ' ORDER BY xlv.location_code' ;
--    lv_sql_body := lv_sql_body || ' ,xilv.segment1' ;
--    lv_sql_body := lv_sql_body || ' ,mcb.segment1' ;
--    lv_sql_body := lv_sql_body || ' ,xrpm.new_div_invent' ;
--    lv_sql_body := lv_sql_body || ' ,gbh.batch_no' ;
--    lv_sql_body := lv_sql_body || ' ,gbh.actual_cmplt_date' ;
--    lv_sql_body := lv_sql_body || ' ,iimb.item_no' ;
--    lv_sql_body := lv_sql_body || ' ,ilm.lot_no' ;
    lv_sql_body := lv_sql_body || ' ORDER BY dept_code' ;
    lv_sql_body := lv_sql_body || ' ,item_location_code' ;
    lv_sql_body := lv_sql_body || ' ,item_div_type' ;
    lv_sql_body := lv_sql_body || ' ,pay_reason_code' ;
    lv_sql_body := lv_sql_body || ' ,entry_no' ;
    lv_sql_body := lv_sql_body || ' ,entry_date' ;
    lv_sql_body := lv_sql_body || ' ,pay_item_no' ;
    lv_sql_body := lv_sql_body || ' ,pay_lot_no' ;
-- 2009/01/15 v1.16 N.Yoshida mod end
--
    EXECUTE IMMEDIATE lv_sql_body BULK COLLECT INTO ot_data_rec USING  gc_cost_manage_code_n
                                                                      ,gc_cost_manage_code_j
                                                                      ,gc_line_type_pay
                                                                      ,gc_doc_type_prod
                                                                      ,gc_comp_ind_on
                                                                      ,gc_use_div_invent_rep
                                                                      ,lv_routing_class
                                                                      ,lv_routing_class_ret
                                                                      ,lv_routing_class_separate
                                                                      ,gc_batch_status_close
                                                                      ,gv_sql_date_from
                                                                      ,gc_item_class_code_1
                                                                      ,gc_item_class_code_4
                                                                      ,gc_item_class_code_5
                                                                      ,gc_language_code
                                                                      ,gc_language_code
                                                                      ,gc_item_class
                                                                      ,gv_sql_date_from
                                                                      ,gc_lookup_type_new_div
                                                                      ,gc_language_code
-- 2009/03/17 v1.21 DELETE START
--                                                                      ,gc_lookup_type_purpose_id
--                                                                      ,gc_language_code
-- 2009/03/17 v1.21 DELETE END
                                                                      ,gv_sql_date_from
                                                                      ,gv_sql_date_from
                                                                      ,gv_sql_date_from
                                                                      ,gr_param.date_from
                                                                      ,gc_date_mask
                                                                      ,gc_date_mask
                                                                      ,gr_param.date_to
                                                                      ,gc_date_mask
                                                                      ,gc_date_mask
-- 2009/01/15 v1.16 N.Yoshida mod start
                                                                      ,gc_cost_manage_code_n
                                                                      ,gc_cost_manage_code_j
                                                                      ,gc_line_type_pay
                                                                      ,gc_doc_type_prod
                                                                      ,gc_comp_ind_on
                                                                      ,gc_use_div_invent_rep
                                                                      ,lv_routing_class
                                                                      ,lv_routing_class_ret
                                                                      ,lv_routing_class_separate
                                                                      ,gc_batch_status_close
                                                                      ,gv_sql_date_from
                                                                      ,gc_item_class_code_1
                                                                      ,gc_item_class_code_4
                                                                      ,gc_item_class_code_5
                                                                      ,gc_language_code
                                                                      ,gc_language_code
                                                                      ,gc_item_class
                                                                      ,gv_sql_date_from
                                                                      ,gc_lookup_type_new_div
                                                                      ,gc_language_code
                                                                      ,gc_lookup_type_purpose_id
                                                                      ,gc_language_code
                                                                      ,gv_sql_date_from
                                                                      ,gv_sql_date_from
                                                                      ,gv_sql_date_from
                                                                      ,gr_param.date_from
                                                                      ,gc_date_mask
                                                                      ,gc_date_mask
                                                                      ,gr_param.date_to
                                                                      ,gc_date_mask
                                                                      ,gc_date_mask
-- 2009/01/15 v1.16 N.Yoshida mod end
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
  END prc_get_prod_pay_data ;
--
   /**********************************************************************************
   * Procedure Name   : prc_get_prod_pay_schedule_data
   * Description      : PROD:生産払出予定データ取得プロシージャ(C2-2)
   ***********************************************************************************/

  PROCEDURE prc_get_prod_pay_schedule_data
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
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_get_prod_pay_schedule_data'; -- プログラム名
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
    lv_sql_body    VARCHAR2(20000);  -- SQL文：本体
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
    -- ------------------------------------------------------------------------------
    -- メインSQL
    -- ------------------------------------------------------------------------------
    -- SQL本体 UNION ALLの上のSQLはいらない可能性あり(工順<>70 かつ 工順＝70の条件があるので)
    lv_sql_body := lv_sql_body || ' SELECT /*+ leading(gbh itp xrpm iimb ximb gic mcb mct) use_nl(gbh itp xrpm iimb ximb gic mcb mct) */' ;
    lv_sql_body := lv_sql_body || '  gbh.batch_id                AS batch_id' ;
    lv_sql_body := lv_sql_body || ' ,xlv.location_code           AS dept_code' ;
    lv_sql_body := lv_sql_body || ' ,xlv.description             AS dept_name' ;
    lv_sql_body := lv_sql_body || ' ,xilv.segment1               AS item_location_code' ;
    lv_sql_body := lv_sql_body || ' ,xilv.description            AS item_location_name' ;
    lv_sql_body := lv_sql_body || ' ,mcb.segment1                AS item_div_type' ;
    lv_sql_body := lv_sql_body || ' ,mct.description             AS item_div_value' ;
    lv_sql_body := lv_sql_body || ' ,gbh.batch_no                AS entry_no' ;
-- 2009/03/06 H.Itou Add Start 本番障害#1283 予定なので、予定日を出力
--    lv_sql_body := lv_sql_body || ' ,gbh.actual_cmplt_date       AS entry_date' ;
    lv_sql_body := lv_sql_body || ' ,gbh.plan_cmplt_date       AS entry_date' ;
-- 2009/03/06 H.Itou Add End
    lv_sql_body := lv_sql_body || ' ,xrpm.new_div_invent         AS pay_reason_code' ;
    lv_sql_body := lv_sql_body || ' ,flv.meaning                 AS pay_reason_name' ;
    lv_sql_body := lv_sql_body || ' ,flv2.attribute1             AS pay_purpose_name' ;
    lv_sql_body := lv_sql_body || ' ,iimb.item_no                AS pay_item_no' ;
    lv_sql_body := lv_sql_body || ' ,ximb.item_short_name        AS pay_item_name' ;
    lv_sql_body := lv_sql_body || ' ,ilm.lot_no                  AS pay_lot_no' ;
-- 2009/03/12 v1.20 ADD START
    lv_sql_body := lv_sql_body || ' ,ilm. attribute14            AS pay_rank1' ;
-- 2009/03/12 v1.20 ADD END
    lv_sql_body := lv_sql_body || ' ,ROUND(ABS(itp.trans_qty),4) AS pay_quant' ;
    lv_sql_body := lv_sql_body || ' ,CASE iimb.attribute15' ;
    lv_sql_body := lv_sql_body || '    WHEN :para_cost_manage_code_n THEN' ;
    lv_sql_body := lv_sql_body || '      ROUND(NVL(xsupv.stnd_unit_price,0),3)' ;
    lv_sql_body := lv_sql_body || '    WHEN :para_cost_manage_code_j THEN' ;
    lv_sql_body := lv_sql_body || '      ROUND(TO_NUMBER(NVL(ilm.attribute7,0)),3)' ;
    lv_sql_body := lv_sql_body || '    ELSE ' ;
    lv_sql_body := lv_sql_body || '      ' || gc_cost_0 ;
    lv_sql_body := lv_sql_body || '  END                         AS pay_unt_price' ;
    lv_sql_body := lv_sql_body || ' ,NULL                        AS rcv_reason_code' ;
    lv_sql_body := lv_sql_body || ' ,NULL                        AS rcv_reason_name' ;
    lv_sql_body := lv_sql_body || ' ,NULL                        AS rcv_purpose_name' ;
    lv_sql_body := lv_sql_body || ' ,NULL                        AS rcv_item_no' ;
    lv_sql_body := lv_sql_body || ' ,NULL                        AS rcv_item_name' ;
    lv_sql_body := lv_sql_body || ' ,NULL                        AS rcv_lot_no' ;
-- 2009/03/12 v1.20 ADD START
    lv_sql_body := lv_sql_body || ' ,NULL                        AS rcv_rank1' ;
-- 2009/03/12 v1.20 ADD END
    lv_sql_body := lv_sql_body || ' ,0                           AS rcv_quant' ;
    lv_sql_body := lv_sql_body || ' ,0                           AS rcv_unt_price' ;
-- 2009/01/20 v1.18 ADD START
    lv_sql_body := lv_sql_body || ' ,gbh. attribute6             AS description' ;
-- 2009/01/20 v1.18 ADD END
    ---------------------------------------------------------------------------------------
    -- FROM句
    lv_sql_body := lv_sql_body || ' FROM xxcmn_item_mst_b     ximb' ;
    lv_sql_body := lv_sql_body || ' ,ic_item_mst_b            iimb' ;
    lv_sql_body := lv_sql_body || ' ,gmi_item_categories      gic' ;
    lv_sql_body := lv_sql_body || ' ,mtl_categories_b         mcb' ;
    lv_sql_body := lv_sql_body || ' ,mtl_categories_tl        mct' ;
    lv_sql_body := lv_sql_body || ' ,ic_lots_mst              ilm' ;
-- 2009/01/15 v1.16 N.Yoshida mod start
--    lv_sql_body := lv_sql_body || ' ,xxinv_rcv_pay_mst2_v     xrpm' ;
    lv_sql_body := lv_sql_body || ' ,xxcmn_rcv_pay_mst        xrpm' ;
    lv_sql_body := lv_sql_body || ' ,gme_material_details     gmd' ;
    lv_sql_body := lv_sql_body || ' ,gmd_routings_b           grb' ;
-- 2009/01/15 v1.16 N.Yoshida mod end
    lv_sql_body := lv_sql_body || ' ,gme_batch_header         gbh' ;
    lv_sql_body := lv_sql_body || ' ,ic_tran_pnd              itp' ;
    lv_sql_body := lv_sql_body || ' ,xxcmn_item_locations2_v  xilv' ;
    lv_sql_body := lv_sql_body || ' ,xxcmn_locations2_v       xlv' ;
    lv_sql_body := lv_sql_body || ' ,fnd_lookup_values        flv' ;
    lv_sql_body := lv_sql_body || ' ,fnd_lookup_values        flv2' ;
    lv_sql_body := lv_sql_body || ' ,xxcmn_stnd_unit_price_v  xsupv' ;
    lv_sql_body := lv_sql_body || ' ,fnd_user                 fu' ;
    lv_sql_body := lv_sql_body || ' ,per_all_assignments_f    paaf' ;
    lv_sql_body := lv_sql_body || ' ,per_all_people_f         papf' ;
    ------------------------------------------------------------
    -- WHERE句
    -- OPM保留在庫トランザクション絞込
    lv_sql_body := lv_sql_body || ' WHERE itp.line_type            = :para_line_type_pay ';
    lv_sql_body := lv_sql_body || ' AND itp.doc_type               = :para_doc_type_prod ';
    lv_sql_body := lv_sql_body || ' AND itp.completed_ind          = :para_comp_ind_off  ';
    lv_sql_body := lv_sql_body || ' AND itp.delete_mark            = :para_delete_mark_off  ';
    lv_sql_body := lv_sql_body || ' AND itp.reverse_id             IS NULL' ;
-- 2009/01/15 v1.16 N.Yoshida mod start
--    lv_sql_body := lv_sql_body || ' AND xrpm.doc_id                = itp.doc_id';
--    lv_sql_body := lv_sql_body || ' AND xrpm.doc_line              = itp.doc_line';
    lv_sql_body := lv_sql_body || ' AND gmd.batch_id                = itp.doc_id';
    lv_sql_body := lv_sql_body || ' AND gmd.line_no                 = itp.doc_line';
    -- 受払区分マスタ絞込み
    lv_sql_body := lv_sql_body || ' AND xrpm.doc_type               = ''PROD''';
    lv_sql_body := lv_sql_body || ' AND xrpm.routing_class          <> ''70''';
    lv_sql_body := lv_sql_body || ' AND gbh.batch_id                = gmd.batch_id';
    lv_sql_body := lv_sql_body || ' AND grb.routing_id              = gbh.routing_id';
    lv_sql_body := lv_sql_body || ' AND xrpm.routing_class          = grb.routing_class';
    lv_sql_body := lv_sql_body || ' AND xrpm.line_type              = gmd.line_type';
    lv_sql_body := lv_sql_body || ' AND ((( gmd.attribute5        IS NULL )';
    lv_sql_body := lv_sql_body || ' AND ( xrpm.hit_in_div       IS NULL ))';
    lv_sql_body := lv_sql_body || ' OR  (( gmd.attribute5        IS NOT NULL )';
    lv_sql_body := lv_sql_body || ' AND ( xrpm.hit_in_div       = gmd.attribute5 )))';
-- 2009/01/15 v1.16 N.Yoshida mod end
    lv_sql_body := lv_sql_body || ' AND xrpm.line_type             = itp.line_type';
    lv_sql_body := lv_sql_body || ' AND xrpm.use_div_invent_rep    = :para_use_div_invent_rep ';
    -- 工順=品目振替
    lv_sql_body := lv_sql_body || ' AND xrpm.routing_class         = :para_routing_class' ;
    -- 生産バッチ結合
    lv_sql_body := lv_sql_body || ' AND itp.doc_id                 = gbh.batch_id' ;
    lv_sql_body := lv_sql_body || ' AND gbh.batch_status           = :para_batch_status_open ' ;
    -- OPM品目情報VIEW結合
    lv_sql_body := lv_sql_body || ' AND itp.item_id                = iimb.item_id' ;
    lv_sql_body := lv_sql_body || ' AND :para_sql_date_from BETWEEN ximb.start_date_active' ;
    lv_sql_body := lv_sql_body || '   AND ximb.end_date_active' ;
    -- OPM品目カテゴリ割当情報VIEW結合
    lv_sql_body := lv_sql_body || ' AND ximb.item_id  = iimb.item_id' ;
    lv_sql_body := lv_sql_body || ' AND iimb.item_id  = gic.item_id' ;
    lv_sql_body := lv_sql_body || ' AND mcb.segment1       IN (' ;
    lv_sql_body := lv_sql_body ||  ' :para_item_class_code_1,' ;
    lv_sql_body := lv_sql_body ||  ' :para_item_class_code_4,' ;
    lv_sql_body := lv_sql_body ||  ' :para_item_class_code_5)' ;
    lv_sql_body := lv_sql_body || ' AND mct.source_lang  = :para_language_code ' ;
    lv_sql_body := lv_sql_body || ' AND mct.language     = :para_language_code ' ;
    lv_sql_body := lv_sql_body || ' AND mcb.category_id        = mct.category_id' ;
    lv_sql_body := lv_sql_body || ' AND gic.category_id        = mcb.category_id' ;
    lv_sql_body := lv_sql_body || ' AND gic.category_set_id    = FND_PROFILE.VALUE(:para_item_class)' ;
    -- 標準原価情報VIEW結合
    lv_sql_body := lv_sql_body || ' AND xsupv.item_id(+)           = itp.item_id ' ;
    lv_sql_body := lv_sql_body || ' AND :para_sql_date_from BETWEEN ';
    lv_sql_body := lv_sql_body || '   xsupv.start_date_active(+)' ;
    lv_sql_body := lv_sql_body || '     AND xsupv.end_date_active(+)' ;
    -- OPMロットマスタ結合
    lv_sql_body := lv_sql_body || ' AND itp.lot_id                 = ilm.lot_id' ;
    lv_sql_body := lv_sql_body || ' AND itp.item_id                = ilm.item_id' ;
    -- クイックコード(新区分)結合
    lv_sql_body := lv_sql_body || ' AND flv.lookup_type            = :para_lookup_type_new_div ' ;
    lv_sql_body := lv_sql_body || ' AND flv.language               = :para_language_code ' ;
    lv_sql_body := lv_sql_body || ' AND flv.lookup_code            = xrpm.new_div_invent ';
    -- クイックコード(品目振替目的)結合
    lv_sql_body := lv_sql_body || ' AND flv2.lookup_type           = :para_lookup_type_purpose_id ' ;
    lv_sql_body := lv_sql_body || ' AND flv2.language              = :para_language_code ' ;
    lv_sql_body := lv_sql_body || ' AND flv2.lookup_code           = gbh.attribute7 ';
    -- ユーザマスタ結合
    lv_sql_body := lv_sql_body || ' AND fu.user_id                 = gbh.created_by' ;
    -- 従業員マスタ結合
    lv_sql_body := lv_sql_body || ' AND fu.employee_id             = paaf.person_id' ;
    lv_sql_body := lv_sql_body || ' AND :para_sql_date_from BETWEEN paaf.effective_start_date' ;
    lv_sql_body := lv_sql_body || '                                    AND paaf.effective_end_date' ;
    lv_sql_body := lv_sql_body || ' AND papf.person_id             = paaf.person_id' ;
    lv_sql_body := lv_sql_body || ' AND :para_sql_date_from BETWEEN papf.effective_start_date' ;
    lv_sql_body := lv_sql_body || '                                    AND papf.effective_end_date' ;
    -- 事業所情報VIEW結合
    lv_sql_body := lv_sql_body || ' AND xlv.location_id            = paaf.location_id' ;
    lv_sql_body := lv_sql_body || ' AND :para_sql_date_from BETWEEN ';
    lv_sql_body := lv_sql_body || '   xlv.start_date_active' ;
    lv_sql_body := lv_sql_body || '     AND xlv.end_date_active' ;
    -- OPM保管場所情報VIEW結合
    lv_sql_body := lv_sql_body || ' AND xilv.whse_code             = itp.whse_code' ;
    lv_sql_body := lv_sql_body || ' AND xilv.segment1              = itp.location' ;
    -------------------------------------------------------------------------------
    --必須パラメータ絞込
    --  1．年月日_FROM
    --  2．年月日_TO
    lv_sql_body := lv_sql_body || ' AND gbh.plan_cmplt_date BETWEEN FND_DATE.STRING_TO_DATE(';
    lv_sql_body := lv_sql_body || ' TO_CHAR(:para_param_date_from, :para_date_mask) ' ;
    lv_sql_body := lv_sql_body || ', :para_date_mask)' ;
    lv_sql_body := lv_sql_body || '                                    AND FND_DATE.STRING_TO_DATE(';
    lv_sql_body := lv_sql_body || ' TO_CHAR(:para_param_date_to, :para_date_mask) ' ;
    lv_sql_body := lv_sql_body || ', :para_date_mask)' ;
    -------------------------------------------------------------------------------
    --  3．払出品目区分
    IF (gr_param.out_item_ctl IS NOT NULL) THEN
      lv_sql_body := lv_sql_body || ' AND mcb.segment1 =' || cv_sc || gr_param.out_item_ctl || cv_sc;
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
-- mod start ver1.17
--      lv_sql_body := lv_sql_body || ' AND gbh.creation_date >= FND_DATE.STRING_TO_DATE(';
      lv_sql_body := lv_sql_body || ' AND itp.last_update_date >= FND_DATE.STRING_TO_DATE(';
-- mod end ver1.17
      lv_sql_body := lv_sql_body || ''''  || TO_CHAR(gr_param.creation_date_from,gc_date_mask) || '''' ;
      lv_sql_body := lv_sql_body || ',''' || gc_date_mask || ''')' ;
    END IF ;
    -- 更新時間TO
    IF (gr_param.creation_date_to IS NOT NULL) THEN
-- mod start ver1.17
--      lv_sql_body := lv_sql_body || ' AND gbh.creation_date <= FND_DATE.STRING_TO_DATE(';
      lv_sql_body := lv_sql_body || ' AND itp.last_update_date <= FND_DATE.STRING_TO_DATE(';
-- mod end ver1.17
      lv_sql_body := lv_sql_body || ''''  || TO_CHAR(gr_param.creation_date_to,gc_date_mask) || '''' ;
      lv_sql_body := lv_sql_body || ',''' || gc_date_mask || ''')' ;
    END IF ;
--
    -- SQL本体
    lv_sql_body := lv_sql_body || ' UNION ALL ' ;
    lv_sql_body := lv_sql_body || ' SELECT /*+ leading(gbh itp xrpm iimb ximb gic mcb mct) use_nl(gbh itp xrpm iimb ximb gic mcb mct) */' ;
    lv_sql_body := lv_sql_body || '  gbh.batch_id                AS batch_id' ;
    lv_sql_body := lv_sql_body || ' ,xlv.location_code           AS dept_code' ;
    lv_sql_body := lv_sql_body || ' ,xlv.description             AS dept_name' ;
    lv_sql_body := lv_sql_body || ' ,xilv.segment1               AS item_location_code' ;
    lv_sql_body := lv_sql_body || ' ,xilv.description            AS item_location_name' ;
    lv_sql_body := lv_sql_body || ' ,mcb.segment1                AS item_div_type' ;
    lv_sql_body := lv_sql_body || ' ,mct.description             AS item_div_value' ;
    lv_sql_body := lv_sql_body || ' ,gbh.batch_no                AS entry_no' ;
-- 2009/03/06 H.Itou Add Start 本番障害#1283 予定なので、予定日を出力
--    lv_sql_body := lv_sql_body || ' ,gbh.actual_cmplt_date       AS entry_date' ;
    lv_sql_body := lv_sql_body || ' ,gbh.plan_cmplt_date       AS entry_date' ;
-- 2009/03/06 H.Itou Add End
    lv_sql_body := lv_sql_body || ' ,xrpm.new_div_invent         AS pay_reason_code' ;
    lv_sql_body := lv_sql_body || ' ,flv.meaning                 AS pay_reason_name' ;
    lv_sql_body := lv_sql_body || ' ,flv2.attribute1             AS pay_purpose_name' ;
    lv_sql_body := lv_sql_body || ' ,iimb.item_no                AS pay_item_no' ;
    lv_sql_body := lv_sql_body || ' ,ximb.item_short_name        AS pay_item_name' ;
    lv_sql_body := lv_sql_body || ' ,ilm.lot_no                  AS pay_lot_no' ;
-- 2009/03/12 v1.20 ADD START
    lv_sql_body := lv_sql_body || ' ,ilm. attribute14            AS pay_rank1' ;
-- 2009/03/12 v1.20 ADD END
    lv_sql_body := lv_sql_body || ' ,ROUND(ABS(itp.trans_qty),4) AS pay_quant' ;
    lv_sql_body := lv_sql_body || ' ,CASE iimb.attribute15' ;
    lv_sql_body := lv_sql_body || '    WHEN :para_cost_manage_code_n THEN' ;
    lv_sql_body := lv_sql_body || '      ROUND(NVL(xsupv.stnd_unit_price,0),3)' ;
    lv_sql_body := lv_sql_body || '    WHEN :para_cost_manage_code_j THEN' ;
    lv_sql_body := lv_sql_body || '      ROUND(TO_NUMBER(NVL(ilm.attribute7,0)),3)' ;
    lv_sql_body := lv_sql_body || '    ELSE ' ;
    lv_sql_body := lv_sql_body || '      ' || gc_cost_0 ;
    lv_sql_body := lv_sql_body || '  END                         AS pay_unt_price' ;
    lv_sql_body := lv_sql_body || ' ,NULL                        AS rcv_reason_code' ;
    lv_sql_body := lv_sql_body || ' ,NULL                        AS rcv_reason_name' ;
    lv_sql_body := lv_sql_body || ' ,NULL                        AS rcv_purpose_name' ;
    lv_sql_body := lv_sql_body || ' ,NULL                        AS rcv_item_no' ;
    lv_sql_body := lv_sql_body || ' ,NULL                        AS rcv_item_name' ;
    lv_sql_body := lv_sql_body || ' ,NULL                        AS rcv_lot_no' ;
-- 2009/03/12 v1.20 ADD START
    lv_sql_body := lv_sql_body || ' ,NULL                        AS rcv_rank1' ;
-- 2009/03/12 v1.20 ADD END
    lv_sql_body := lv_sql_body || ' ,0                           AS rcv_quant' ;
    lv_sql_body := lv_sql_body || ' ,0                           AS rcv_unt_price' ;
-- 2009/01/20 v1.18 ADD START
    lv_sql_body := lv_sql_body || ' ,gbh. attribute6             AS description' ;
-- 2009/01/20 v1.18 ADD END
    ---------------------------------------------------------------------------------------
    -- FROM句
    lv_sql_body := lv_sql_body || ' FROM xxcmn_item_mst_b     ximb' ;
    lv_sql_body := lv_sql_body || ' ,ic_item_mst_b            iimb' ;
    lv_sql_body := lv_sql_body || ' ,gmi_item_categories      gic' ;
    lv_sql_body := lv_sql_body || ' ,mtl_categories_b         mcb' ;
    lv_sql_body := lv_sql_body || ' ,mtl_categories_tl        mct' ;
    lv_sql_body := lv_sql_body || ' ,ic_lots_mst              ilm' ;
-- 2009/01/15 v1.16 N.Yoshida mod start
--    lv_sql_body := lv_sql_body || ' ,xxinv_rcv_pay_mst2_v     xrpm' ;
    lv_sql_body := lv_sql_body || ' ,xxcmn_rcv_pay_mst        xrpm' ;
    lv_sql_body := lv_sql_body || ' ,gme_material_details     gmd' ;
    lv_sql_body := lv_sql_body || ' ,gmd_routings_b           grb' ;
-- 2009/01/15 v1.16 N.Yoshida mod end
    lv_sql_body := lv_sql_body || ' ,gme_batch_header         gbh' ;
    lv_sql_body := lv_sql_body || ' ,ic_tran_pnd              itp' ;
    lv_sql_body := lv_sql_body || ' ,xxcmn_item_locations2_v  xilv' ;
    lv_sql_body := lv_sql_body || ' ,xxcmn_locations2_v       xlv' ;
    lv_sql_body := lv_sql_body || ' ,fnd_lookup_values        flv' ;
    lv_sql_body := lv_sql_body || ' ,fnd_lookup_values        flv2' ;
    lv_sql_body := lv_sql_body || ' ,xxcmn_stnd_unit_price_v  xsupv' ;
    lv_sql_body := lv_sql_body || ' ,fnd_user                 fu' ;
    lv_sql_body := lv_sql_body || ' ,per_all_assignments_f    paaf' ;
    lv_sql_body := lv_sql_body || ' ,per_all_people_f         papf' ;
    ------------------------------------------------------------
    -- WHERE句
    -- OPM保留在庫トランザクション絞込
    lv_sql_body := lv_sql_body || ' WHERE itp.line_type            = :para_line_type_pay ';
    lv_sql_body := lv_sql_body || ' AND itp.doc_type               = :para_doc_type_prod ';
    lv_sql_body := lv_sql_body || ' AND itp.completed_ind          = :para_comp_ind_off  ';
    lv_sql_body := lv_sql_body || ' AND itp.delete_mark            = :para_delete_mark_off  ';
    lv_sql_body := lv_sql_body || ' AND itp.reverse_id             IS NULL' ;
-- 2009/01/15 v1.16 N.Yoshida mod start
--    lv_sql_body := lv_sql_body || ' AND xrpm.doc_id                = itp.doc_id';
--    lv_sql_body := lv_sql_body || ' AND xrpm.doc_line              = itp.doc_line';
    lv_sql_body := lv_sql_body || ' AND gmd.batch_id                = itp.doc_id';
    lv_sql_body := lv_sql_body || ' AND gmd.line_no                 = itp.doc_line';
    -- 受払区分マスタ絞込み
    lv_sql_body := lv_sql_body || ' AND xrpm.doc_type               = ''PROD''';
    lv_sql_body := lv_sql_body || ' AND xrpm.routing_class          = ''70''';
    lv_sql_body := lv_sql_body || ' AND gbh.batch_id                = gmd.batch_id';
    lv_sql_body := lv_sql_body || ' AND grb.routing_id              = gbh.routing_id';
    lv_sql_body := lv_sql_body || ' AND xrpm.routing_class          = grb.routing_class';
    lv_sql_body := lv_sql_body || ' AND xrpm.line_type              = gmd.line_type';
    lv_sql_body := lv_sql_body || ' AND ((( gmd.attribute5        IS NULL )';
    lv_sql_body := lv_sql_body || ' AND ( xrpm.hit_in_div       IS NULL ))';
    lv_sql_body := lv_sql_body || ' OR  (( gmd.attribute5        IS NOT NULL )';
    lv_sql_body := lv_sql_body || ' AND ( xrpm.hit_in_div       = gmd.attribute5 )))';
    lv_sql_body := lv_sql_body || ' AND    EXISTS';
    lv_sql_body := lv_sql_body || ' ( SELECT 1';
    lv_sql_body := lv_sql_body || '   FROM  gme_batch_header         gbh_item';
    lv_sql_body := lv_sql_body || '        ,gme_material_details     gmd_item';
    lv_sql_body := lv_sql_body || '        ,gmd_routings_b           grb_item';
    lv_sql_body := lv_sql_body || '        ,xxcmn_item_categories4_v xicv';
    lv_sql_body := lv_sql_body || '   WHERE gbh_item.batch_id      = gmd_item.batch_id';
    lv_sql_body := lv_sql_body || '   AND   gbh_item.routing_id    = grb_item.routing_id';
    lv_sql_body := lv_sql_body || '   AND   grb_item.routing_class = ''70''';
    lv_sql_body := lv_sql_body || '   AND   gmd_item.item_id       = xicv.item_id';
    lv_sql_body := lv_sql_body || '   AND   gmd_item.batch_id      = gmd.batch_id';
    lv_sql_body := lv_sql_body || '   AND   gmd_item.line_no       = gmd.line_no';
    lv_sql_body := lv_sql_body || '   GROUP BY gbh_item.batch_id';
    lv_sql_body := lv_sql_body || '           ,gmd_item.line_no';
    lv_sql_body := lv_sql_body || '   HAVING xrpm.item_div_origin = MAX(DECODE(gmd_item.line_type,-1,xicv.item_class_code,NULL))';
    lv_sql_body := lv_sql_body || '   AND    xrpm.item_div_ahead  = MAX(DECODE(gmd_item.line_type, 1,xicv.item_class_code,NULL)))';
-- 2009/01/15 v1.16 N.Yoshida mod end
    lv_sql_body := lv_sql_body || ' AND xrpm.line_type             = itp.line_type';
    lv_sql_body := lv_sql_body || ' AND xrpm.use_div_invent_rep    = :para_use_div_invent_rep ';
    -- 工順=品目振替
    lv_sql_body := lv_sql_body || ' AND xrpm.routing_class         = :para_routing_class' ;
    -- 生産バッチ結合
    lv_sql_body := lv_sql_body || ' AND itp.doc_id                 = gbh.batch_id' ;
    lv_sql_body := lv_sql_body || ' AND gbh.batch_status           = :para_batch_status_open ' ;
    -- OPM品目情報VIEW結合
    lv_sql_body := lv_sql_body || ' AND itp.item_id                = iimb.item_id' ;
    lv_sql_body := lv_sql_body || ' AND :para_sql_date_from BETWEEN ximb.start_date_active' ;
    lv_sql_body := lv_sql_body || '   AND ximb.end_date_active' ;
    -- OPM品目カテゴリ割当情報VIEW結合
    lv_sql_body := lv_sql_body || ' AND ximb.item_id  = iimb.item_id' ;
    lv_sql_body := lv_sql_body || ' AND iimb.item_id  = gic.item_id' ;
    lv_sql_body := lv_sql_body || ' AND mcb.segment1       IN (' ;
    lv_sql_body := lv_sql_body ||  ' :para_item_class_code_1,' ;
    lv_sql_body := lv_sql_body ||  ' :para_item_class_code_4,' ;
    lv_sql_body := lv_sql_body ||  ' :para_item_class_code_5)' ;
    lv_sql_body := lv_sql_body || ' AND mct.source_lang  = :para_language_code ' ;
    lv_sql_body := lv_sql_body || ' AND mct.language     = :para_language_code ' ;
    lv_sql_body := lv_sql_body || ' AND mcb.category_id        = mct.category_id' ;
    lv_sql_body := lv_sql_body || ' AND gic.category_id        = mcb.category_id' ;
    lv_sql_body := lv_sql_body || ' AND gic.category_set_id    = FND_PROFILE.VALUE(:para_item_class)' ;
    -- 標準原価情報VIEW結合
    lv_sql_body := lv_sql_body || ' AND xsupv.item_id(+)           = itp.item_id ' ;
    lv_sql_body := lv_sql_body || ' AND :para_sql_date_from BETWEEN ';
    lv_sql_body := lv_sql_body || '   xsupv.start_date_active(+)' ;
    lv_sql_body := lv_sql_body || '     AND xsupv.end_date_active(+)' ;
    -- OPMロットマスタ結合
    lv_sql_body := lv_sql_body || ' AND itp.lot_id                 = ilm.lot_id' ;
    lv_sql_body := lv_sql_body || ' AND itp.item_id                = ilm.item_id' ;
    -- クイックコード(新区分)結合
    lv_sql_body := lv_sql_body || ' AND flv.lookup_type            = :para_lookup_type_new_div ' ;
    lv_sql_body := lv_sql_body || ' AND flv.language               = :para_language_code ' ;
    lv_sql_body := lv_sql_body || ' AND flv.lookup_code            = xrpm.new_div_invent ';
    -- クイックコード(品目振替目的)結合
    lv_sql_body := lv_sql_body || ' AND flv2.lookup_type           = :para_lookup_type_purpose_id ' ;
    lv_sql_body := lv_sql_body || ' AND flv2.language              = :para_language_code ' ;
    lv_sql_body := lv_sql_body || ' AND flv2.lookup_code           = gbh.attribute7 ';
    -- ユーザマスタ結合
    lv_sql_body := lv_sql_body || ' AND fu.user_id                 = gbh.created_by' ;
    -- 従業員マスタ結合
    lv_sql_body := lv_sql_body || ' AND fu.employee_id             = paaf.person_id' ;
    lv_sql_body := lv_sql_body || ' AND :para_sql_date_from BETWEEN paaf.effective_start_date' ;
    lv_sql_body := lv_sql_body || '                                    AND paaf.effective_end_date' ;
    lv_sql_body := lv_sql_body || ' AND papf.person_id             = paaf.person_id' ;
    lv_sql_body := lv_sql_body || ' AND :para_sql_date_from BETWEEN papf.effective_start_date' ;
    lv_sql_body := lv_sql_body || '                                    AND papf.effective_end_date' ;
    -- 事業所情報VIEW結合
    lv_sql_body := lv_sql_body || ' AND xlv.location_id            = paaf.location_id' ;
    lv_sql_body := lv_sql_body || ' AND :para_sql_date_from BETWEEN ';
    lv_sql_body := lv_sql_body || '   xlv.start_date_active' ;
    lv_sql_body := lv_sql_body || '     AND xlv.end_date_active' ;
    -- OPM保管場所情報VIEW結合
    lv_sql_body := lv_sql_body || ' AND xilv.whse_code             = itp.whse_code' ;
    lv_sql_body := lv_sql_body || ' AND xilv.segment1              = itp.location' ;
    -------------------------------------------------------------------------------
    --必須パラメータ絞込
    --  1．年月日_FROM
    --  2．年月日_TO
    lv_sql_body := lv_sql_body || ' AND gbh.plan_cmplt_date BETWEEN FND_DATE.STRING_TO_DATE(';
    lv_sql_body := lv_sql_body || ' TO_CHAR(:para_param_date_from, :para_date_mask) ' ;
    lv_sql_body := lv_sql_body || ', :para_date_mask)' ;
    lv_sql_body := lv_sql_body || '                                    AND FND_DATE.STRING_TO_DATE(';
    lv_sql_body := lv_sql_body || ' TO_CHAR(:para_param_date_to, :para_date_mask) ' ;
    lv_sql_body := lv_sql_body || ', :para_date_mask)' ;
    -------------------------------------------------------------------------------
    --  3．払出品目区分
    IF (gr_param.out_item_ctl IS NOT NULL) THEN
      lv_sql_body := lv_sql_body || ' AND mcb.segment1 =' || cv_sc || gr_param.out_item_ctl || cv_sc;
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
    -- 伝票No
    IF (lv_work_str IS NOT NULL) THEN
      lv_sql_body := lv_sql_body || ' AND gbh.batch_no IN('||lv_work_str || ')';
    END IF ;
    -- パラメータ絞込(品目ID)
    -- 品目
    IF (lv_work_str_2 IS NOT NULL) THEN
      lv_sql_body := lv_sql_body || ' AND itp.item_id IN('||lv_work_str_2 || ')';
    END IF ;
    -- 担当者
    IF (gr_param.emp_no IS NOT NULL) THEN
      lv_sql_body := lv_sql_body || ' AND papf.employee_number = ''' || gr_param.emp_no || '''';
    END IF ;
    -- 更新時間FROM
    IF (gr_param.creation_date_from IS NOT NULL) THEN
-- mod start ver1.17
--      lv_sql_body := lv_sql_body || ' AND gbh.creation_date >= FND_DATE.STRING_TO_DATE(';
      lv_sql_body := lv_sql_body || ' AND itp.last_update_date >= FND_DATE.STRING_TO_DATE(';
-- mod end ver1.17
      lv_sql_body := lv_sql_body || ''''  || TO_CHAR(gr_param.creation_date_from,gc_date_mask) || '''' ;
      lv_sql_body := lv_sql_body || ',''' || gc_date_mask || ''')' ;
    END IF ;
    -- 更新時間TO
    IF (gr_param.creation_date_to IS NOT NULL) THEN
-- mod start ver1.17
--      lv_sql_body := lv_sql_body || ' AND gbh.creation_date <= FND_DATE.STRING_TO_DATE(';
      lv_sql_body := lv_sql_body || ' AND itp.last_update_date <= FND_DATE.STRING_TO_DATE(';
-- mod end ver1.17
      lv_sql_body := lv_sql_body || ''''  || TO_CHAR(gr_param.creation_date_to,gc_date_mask) || '''' ;
      lv_sql_body := lv_sql_body || ',''' || gc_date_mask || ''')' ;
    END IF ;
    ---------------------------------------------------------------------------------------------
    --ORDER BY 句
-- 2009/01/15 v1.16 N.Yoshida mod start
--    lv_sql_body := lv_sql_body || ' ORDER BY xlv.location_code' ;
--    lv_sql_body := lv_sql_body || ' ,xilv.segment1' ;
--    lv_sql_body := lv_sql_body || ' ,mcb.segment1' ;
--    lv_sql_body := lv_sql_body || ' ,xrpm.new_div_invent' ;
--    lv_sql_body := lv_sql_body || ' ,gbh.batch_no' ;
--    lv_sql_body := lv_sql_body || ' ,gbh.actual_cmplt_date' ;
--    lv_sql_body := lv_sql_body || ' ,iimb.item_no' ;
--    lv_sql_body := lv_sql_body || ' ,ilm.lot_no' ;
    lv_sql_body := lv_sql_body || ' ORDER BY dept_code' ;
    lv_sql_body := lv_sql_body || ' ,item_location_code' ;
    lv_sql_body := lv_sql_body || ' ,item_div_type' ;
    lv_sql_body := lv_sql_body || ' ,pay_reason_code' ;
    lv_sql_body := lv_sql_body || ' ,entry_no' ;
    lv_sql_body := lv_sql_body || ' ,entry_date' ;
    lv_sql_body := lv_sql_body || ' ,pay_item_no' ;
    lv_sql_body := lv_sql_body || ' ,pay_lot_no' ;
-- 2009/01/15 v1.16 N.Yoshida mod end
--
    EXECUTE IMMEDIATE lv_sql_body BULK COLLECT INTO ot_data_rec USING  gc_cost_manage_code_n
                                                                      ,gc_cost_manage_code_j
                                                                      ,gc_line_type_pay
                                                                      ,gc_doc_type_prod
                                                                      ,gc_comp_ind_off
                                                                      ,gc_delete_mark_off
                                                                      ,gc_use_div_invent_rep
                                                                      ,lv_routing_class
                                                                      ,gc_batch_status_open
                                                                      ,gv_sql_date_from
                                                                      ,gc_item_class_code_1
                                                                      ,gc_item_class_code_4
                                                                      ,gc_item_class_code_5
                                                                      ,gc_language_code
                                                                      ,gc_language_code
                                                                      ,gc_item_class
                                                                      ,gv_sql_date_from
                                                                      ,gc_lookup_type_new_div
                                                                      ,gc_language_code
                                                                      ,gc_lookup_type_purpose_id
                                                                      ,gc_language_code
                                                                      ,gv_sql_date_from
                                                                      ,gv_sql_date_from
                                                                      ,gv_sql_date_from
                                                                      ,gr_param.date_from
                                                                      ,gc_date_mask
                                                                      ,gc_date_mask
                                                                      ,gr_param.date_to
                                                                      ,gc_date_mask
                                                                      ,gc_date_mask
-- 2009/01/15 v1.16 N.Yoshida mod start
                                                                      ,gc_cost_manage_code_n
                                                                      ,gc_cost_manage_code_j
                                                                      ,gc_line_type_pay
                                                                      ,gc_doc_type_prod
                                                                      ,gc_comp_ind_off
                                                                      ,gc_delete_mark_off
                                                                      ,gc_use_div_invent_rep
                                                                      ,lv_routing_class
                                                                      ,gc_batch_status_open
                                                                      ,gv_sql_date_from
                                                                      ,gc_item_class_code_1
                                                                      ,gc_item_class_code_4
                                                                      ,gc_item_class_code_5
                                                                      ,gc_language_code
                                                                      ,gc_language_code
                                                                      ,gc_item_class
                                                                      ,gv_sql_date_from
                                                                      ,gc_lookup_type_new_div
                                                                      ,gc_language_code
                                                                      ,gc_lookup_type_purpose_id
                                                                      ,gc_language_code
                                                                      ,gv_sql_date_from
                                                                      ,gv_sql_date_from
                                                                      ,gv_sql_date_from
                                                                      ,gr_param.date_from
                                                                      ,gc_date_mask
                                                                      ,gc_date_mask
                                                                      ,gr_param.date_to
                                                                      ,gc_date_mask
                                                                      ,gc_date_mask
-- 2009/01/15 v1.16 N.Yoshida mod end
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
  END prc_get_prod_pay_schedule_data ;
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
    lv_sql_body := lv_sql_body || ' SELECT /*+ leading(gbh itp xrpm iimb ximb) use_nl(gbh itp xrpm iimb ximb) */' ;
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
    lv_sql_body := lv_sql_body || ' ,NULL                        AS pay_purpose_name' ;
    lv_sql_body := lv_sql_body || ' ,NULL                        AS pay_item_no' ;
    lv_sql_body := lv_sql_body || ' ,NULL                        AS pay_item_name' ;
    lv_sql_body := lv_sql_body || ' ,NULL                        AS pay_lot_no' ;
-- 2009/03/12 v1.20 ADD START
    lv_sql_body := lv_sql_body || ' ,NULL                        AS pay_rank1' ;
-- 2009/03/12 v1.20 ADD END
    lv_sql_body := lv_sql_body || ' ,0                           AS pay_quant' ;
    lv_sql_body := lv_sql_body || ' ,0                           AS pay_unt_price' ;
    lv_sql_body := lv_sql_body || ' ,xrpm.new_div_invent         AS rcv_reason_code' ;
    lv_sql_body := lv_sql_body || ' ,flv.meaning                 AS rcv_reason_name' ;
    lv_sql_body := lv_sql_body || ' ,flv2.attribute1             AS rcv_purpose_name' ;
    lv_sql_body := lv_sql_body || ' ,iimb.item_no                AS rcv_item_no' ;
    lv_sql_body := lv_sql_body || ' ,ximb.item_short_name        AS rcv_item_name' ;
    lv_sql_body := lv_sql_body || ' ,ilm.lot_no                  AS rcv_lot_no' ;
-- 2009/03/12 v1.20 ADD START
    lv_sql_body := lv_sql_body || ' ,ilm. attribute14            AS rcv_rank1' ;
-- 2009/03/12 v1.20 ADD END
    lv_sql_body := lv_sql_body || ' ,ROUND(ABS(itp.trans_qty),4) AS rcv_quant' ;
    lv_sql_body := lv_sql_body || ' ,CASE iimb.attribute15' ;
    lv_sql_body := lv_sql_body || '    WHEN :para_cost_manage_code_n THEN' ;
    lv_sql_body := lv_sql_body || '      ROUND(NVL(xsupv.stnd_unit_price,0),3)' ;
    lv_sql_body := lv_sql_body || '    WHEN :para_cost_manage_code_j THEN' ;
    lv_sql_body := lv_sql_body || '      ROUND(TO_NUMBER(NVL(ilm.attribute7,0)),3)' ;
    lv_sql_body := lv_sql_body || '    ELSE ' ;
    lv_sql_body := lv_sql_body || '      ' || gc_cost_0 ;
    lv_sql_body := lv_sql_body || ' END                          AS rcv_unt_price' ;
-- 2009/01/20 v1.18 ADD START
    lv_sql_body := lv_sql_body || ' ,gbh. attribute6             AS description' ;
-- 2009/01/20 v1.18 ADD END
    ---------------------------------------------------------------------------------------
    -- FROM句
    lv_sql_body := lv_sql_body || ' FROM xxcmn_item_mst_b      ximb' ;
    lv_sql_body := lv_sql_body || ' ,ic_item_mst_b             iimb' ;
    lv_sql_body := lv_sql_body || ' ,ic_lots_mst               ilm' ;
    lv_sql_body := lv_sql_body || ' ,xxinv_rcv_pay_mst2_v     xrpm' ;
    lv_sql_body := lv_sql_body || ' ,gme_batch_header          gbh' ;
    lv_sql_body := lv_sql_body || ' ,ic_tran_pnd               itp' ;
    lv_sql_body := lv_sql_body || ' ,fnd_lookup_values         flv' ;
    lv_sql_body := lv_sql_body || ' ,fnd_lookup_values        flv2' ;
    lv_sql_body := lv_sql_body || ' ,xxcmn_stnd_unit_price_v xsupv' ;
    ------------------------------------------------------------
    -- WHERE句
    -- OPM保留在庫トランザクション絞込
    lv_sql_body := lv_sql_body || ' WHERE itp.line_type            = :para_line_type_rcv ';
    lv_sql_body := lv_sql_body || ' AND itp.doc_type               = :para_doc_type_prod ';
    lv_sql_body := lv_sql_body || ' AND itp.completed_ind          = :para_comp_ind_on   ';
    lv_sql_body := lv_sql_body || ' AND itp.reverse_id             IS NULL' ;
    lv_sql_body := lv_sql_body || ' AND xrpm.doc_id                = itp.doc_id';
    lv_sql_body := lv_sql_body || ' AND xrpm.doc_line              = itp.doc_line';
    lv_sql_body := lv_sql_body || ' AND xrpm.line_type             = itp.line_type';
    lv_sql_body := lv_sql_body || ' AND xrpm.use_div_invent_rep    = :para_use_div_invent_rep ';
    -- 生産バッチ結合
    lv_sql_body := lv_sql_body || ' AND itp.doc_id                 = gbh.batch_id' ;
    -- OPM品目情報VIEW結合
    lv_sql_body := lv_sql_body || ' AND itp.item_id                = iimb.item_id' ;
    lv_sql_body := lv_sql_body || ' AND ximb.item_id                = iimb.item_id' ;
    lv_sql_body := lv_sql_body || ' AND :para_sql_date_from BETWEEN ximb.start_date_active' ;
    lv_sql_body := lv_sql_body || '   AND ximb.end_date_active' ;
    -- 標準原価情報VIEW結合
    lv_sql_body := lv_sql_body || ' AND xsupv.item_id(+)           = itp.item_id ' ;
    lv_sql_body := lv_sql_body || ' AND :para_sql_date_from BETWEEN ' ;
    lv_sql_body := lv_sql_body || '   xsupv.start_date_active(+)' ;
    lv_sql_body := lv_sql_body || '     AND xsupv.end_date_active(+)' ;
    -- OPMロットマスタ結合
    lv_sql_body := lv_sql_body || ' AND itp.lot_id                 = ilm.lot_id' ;
    lv_sql_body := lv_sql_body || ' AND itp.item_id                = ilm.item_id' ;
    -- クイックコード(新区分)結合
    lv_sql_body := lv_sql_body || ' AND flv.lookup_type            = :para_lookup_type_new_div' ;
    lv_sql_body := lv_sql_body || ' AND flv.language               = :para_language_code      ' ;
    lv_sql_body := lv_sql_body || ' AND flv.lookup_code            = xrpm.new_div_invent ';
    -- クイックコード(品目振替目的)結合
    lv_sql_body := lv_sql_body || ' AND flv2.lookup_type           = :para_lookup_type_purpose_id ' ;
    lv_sql_body := lv_sql_body || ' AND flv2.language              = :para_language_code ' ;
    lv_sql_body := lv_sql_body || ' AND flv2.lookup_code           = gbh.attribute7 ';
    -------------------------------------------------------------------------------
    lv_sql_body := lv_sql_body || ' AND gbh.batch_id = ' || in_batch_id ;
    -------------------------------------------------------------------------------
    --ORDER BY 句
    lv_sql_body := lv_sql_body || ' ORDER BY ';
    lv_sql_body := lv_sql_body || '  xrpm.new_div_invent' ;
    lv_sql_body := lv_sql_body || ' ,gbh.batch_no' ;
    lv_sql_body := lv_sql_body || ' ,gbh.actual_cmplt_date' ;
    lv_sql_body := lv_sql_body || ' ,iimb.item_no' ;
    lv_sql_body := lv_sql_body || ' ,ilm.lot_no' ;
--
    EXECUTE IMMEDIATE lv_sql_body BULK COLLECT INTO ot_data_rec USING  gc_cost_manage_code_n
                                                                      ,gc_cost_manage_code_j
                                                                      ,gc_line_type_rcv
                                                                      ,gc_doc_type_prod
                                                                      ,gc_comp_ind_on
                                                                      ,gc_use_div_invent_rep
                                                                      ,gv_sql_date_from
                                                                      ,gv_sql_date_from
                                                                      ,gc_lookup_type_new_div
                                                                      ,gc_language_code
                                                                      ,gc_lookup_type_purpose_id
                                                                      ,gc_language_code
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
  END prc_get_prod_rcv_data ;
--
   /**********************************************************************************
   * Procedure Name   : prc_get_prod_rcv_schedule_data
   * Description      : PROD:生産受入予定データ取得プロシージャ(C2-2)
   ***********************************************************************************/
--
  PROCEDURE prc_get_prod_rcv_schedule_data
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
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_get_prod_rcv_schedule_data'; -- プログラム名
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
    lv_sql_body := lv_sql_body || ' SELECT /*+ leading(gbh itp xrpm iimb ximb) use_nl(gbh itp xrpm iimb ximb) */' ;
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
    lv_sql_body := lv_sql_body || ' ,NULL                        AS pay_purpose_name' ;
    lv_sql_body := lv_sql_body || ' ,NULL                        AS pay_item_no' ;
    lv_sql_body := lv_sql_body || ' ,NULL                        AS pay_item_name' ;
    lv_sql_body := lv_sql_body || ' ,NULL                        AS pay_lot_no' ;
-- 2009/03/12 v1.20 ADD START
    lv_sql_body := lv_sql_body || ' ,NULL                        AS pay_rank1' ;
-- 2009/03/12 v1.20 ADD END
    lv_sql_body := lv_sql_body || ' ,0                           AS pay_quant' ;
    lv_sql_body := lv_sql_body || ' ,0                           AS pay_unt_price' ;
    lv_sql_body := lv_sql_body || ' ,xrpm.new_div_invent         AS rcv_reason_code' ;
    lv_sql_body := lv_sql_body || ' ,flv.meaning                 AS rcv_reason_name' ;
    lv_sql_body := lv_sql_body || ' ,flv2.attribute1             AS rcv_purpose_name' ;
    lv_sql_body := lv_sql_body || ' ,iimb.item_no                AS rcv_item_no' ;
    lv_sql_body := lv_sql_body || ' ,ximb.item_short_name        AS rcv_item_name' ;
    lv_sql_body := lv_sql_body || ' ,ilm.lot_no                  AS rcv_lot_no' ;
-- 2009/03/12 v1.20 ADD START
    lv_sql_body := lv_sql_body || ' ,ilm. attribute14            AS rcv_rank1' ;
-- 2009/03/12 v1.20 ADD END
    lv_sql_body := lv_sql_body || ' ,ROUND(ABS(itp.trans_qty),4) AS rcv_quant' ;
    lv_sql_body := lv_sql_body || ' ,CASE iimb.attribute15' ;
    lv_sql_body := lv_sql_body || '    WHEN :para_cost_manage_code_n THEN' ;
    lv_sql_body := lv_sql_body || '      ROUND(NVL(xsupv.stnd_unit_price,0),3)' ;
    lv_sql_body := lv_sql_body || '    WHEN :para_cost_manage_code_j THEN' ;
    lv_sql_body := lv_sql_body || '      ROUND(TO_NUMBER(NVL(ilm.attribute7,0)),3)' ;
    lv_sql_body := lv_sql_body || '    ELSE ' ;
    lv_sql_body := lv_sql_body || '      ' || gc_cost_0 ;
    lv_sql_body := lv_sql_body || ' END                          AS rcv_unt_price' ;
-- 2009/01/20 v1.18 ADD START
    lv_sql_body := lv_sql_body || ' ,gbh. attribute6             AS description' ;
-- 2009/01/20 v1.18 ADD END
    ---------------------------------------------------------------------------------------
    -- FROM句
    lv_sql_body := lv_sql_body || ' FROM xxcmn_item_mst_b      ximb' ;
    lv_sql_body := lv_sql_body || ' ,ic_item_mst_b             iimb' ;
    lv_sql_body := lv_sql_body || ' ,ic_lots_mst               ilm' ;
    lv_sql_body := lv_sql_body || ' ,xxinv_rcv_pay_mst2_v     xrpm' ;
    lv_sql_body := lv_sql_body || ' ,gme_batch_header          gbh' ;
    lv_sql_body := lv_sql_body || ' ,ic_tran_pnd               itp' ;
    lv_sql_body := lv_sql_body || ' ,fnd_lookup_values         flv' ;
    lv_sql_body := lv_sql_body || ' ,fnd_lookup_values        flv2' ;
    lv_sql_body := lv_sql_body || ' ,xxcmn_stnd_unit_price_v xsupv' ;
    ------------------------------------------------------------
    -- WHERE句
    -- OPM保留在庫トランザクション絞込
    lv_sql_body := lv_sql_body || ' WHERE itp.line_type            = :para_line_type_rcv ';
    lv_sql_body := lv_sql_body || ' AND itp.doc_type               = :para_doc_type_prod ';
    lv_sql_body := lv_sql_body || ' AND itp.completed_ind          = :para_comp_ind_off  ';
    lv_sql_body := lv_sql_body || ' AND itp.delete_mark            = :para_delete_mark_off  ';
    lv_sql_body := lv_sql_body || ' AND itp.lot_id                 <> 0  ';
    lv_sql_body := lv_sql_body || ' AND itp.reverse_id             IS NULL' ;
    lv_sql_body := lv_sql_body || ' AND xrpm.doc_id                = itp.doc_id';
    lv_sql_body := lv_sql_body || ' AND xrpm.doc_line              = itp.doc_line';
    lv_sql_body := lv_sql_body || ' AND xrpm.line_type             = itp.line_type';
    lv_sql_body := lv_sql_body || ' AND xrpm.use_div_invent_rep    = :para_use_div_invent_rep ';
    -- 生産バッチ結合
    lv_sql_body := lv_sql_body || ' AND itp.doc_id                 = gbh.batch_id' ;
    -- OPM品目情報VIEW結合
    lv_sql_body := lv_sql_body || ' AND itp.item_id                = iimb.item_id' ;
    lv_sql_body := lv_sql_body || ' AND ximb.item_id                = iimb.item_id' ;
    lv_sql_body := lv_sql_body || ' AND :para_sql_date_from BETWEEN ximb.start_date_active' ;
    lv_sql_body := lv_sql_body || '   AND ximb.end_date_active' ;
    -- 標準原価情報VIEW結合
    lv_sql_body := lv_sql_body || ' AND xsupv.item_id(+)           = itp.item_id ' ;
    lv_sql_body := lv_sql_body || ' AND :para_sql_date_from BETWEEN ' ;
    lv_sql_body := lv_sql_body || '   xsupv.start_date_active(+)' ;
    lv_sql_body := lv_sql_body || '     AND xsupv.end_date_active(+)' ;
    -- OPMロットマスタ結合
    lv_sql_body := lv_sql_body || ' AND itp.lot_id                 = ilm.lot_id' ;
    lv_sql_body := lv_sql_body || ' AND itp.item_id                = ilm.item_id' ;
    -- クイックコード(新区分)結合
    lv_sql_body := lv_sql_body || ' AND flv.lookup_type            = :para_lookup_type_new_div' ;
    lv_sql_body := lv_sql_body || ' AND flv.language               = :para_language_code      ' ;
    lv_sql_body := lv_sql_body || ' AND flv.lookup_code            = xrpm.new_div_invent ';
    -- クイックコード(品目振替目的)結合
    lv_sql_body := lv_sql_body || ' AND flv2.lookup_type           = :para_lookup_type_purpose_id ' ;
    lv_sql_body := lv_sql_body || ' AND flv2.language              = :para_language_code ' ;
    lv_sql_body := lv_sql_body || ' AND flv2.lookup_code           = gbh.attribute7 ';
    -------------------------------------------------------------------------------
    lv_sql_body := lv_sql_body || ' AND gbh.batch_id = ' || in_batch_id ;
    -------------------------------------------------------------------------------
    --ORDER BY 句
    lv_sql_body := lv_sql_body || ' ORDER BY ';
    lv_sql_body := lv_sql_body || '  xrpm.new_div_invent' ;
    lv_sql_body := lv_sql_body || ' ,gbh.batch_no' ;
    lv_sql_body := lv_sql_body || ' ,gbh.actual_cmplt_date' ;
    lv_sql_body := lv_sql_body || ' ,iimb.item_no' ;
    lv_sql_body := lv_sql_body || ' ,ilm.lot_no' ;
--
    EXECUTE IMMEDIATE lv_sql_body BULK COLLECT INTO ot_data_rec USING  gc_cost_manage_code_n
                                                                      ,gc_cost_manage_code_j
                                                                      ,gc_line_type_rcv
                                                                      ,gc_doc_type_prod
                                                                      ,gc_comp_ind_off
                                                                      ,gc_delete_mark_off
                                                                      ,gc_use_div_invent_rep
                                                                      ,gv_sql_date_from
                                                                      ,gv_sql_date_from
                                                                      ,gc_lookup_type_new_div
                                                                      ,gc_language_code
                                                                      ,gc_lookup_type_purpose_id
                                                                      ,gc_language_code
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
  END prc_get_prod_rcv_schedule_data ;
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
      IF (gr_param.reason_code IS NOT NULL)                 -- xrpm.new_div_inventに指定がある
        OR
         (
           (gr_param.out_item_ctl IS NOT NULL) AND          -- mcb.segment1に指定がある
           (gr_param.reason_code IS NULL)      AND          -- xrpm.new_div_inventに指定がない
           (gr_param.item_location_id IS NULL) AND          -- xilv.inventory_location_idに指定がない
           (gr_param.item1 IS NULL)            AND          -- itc.item_id1〜3に指定がない
           (gr_param.item2 IS NULL)            AND
           (gr_param.item3 IS NULL)
         ) THEN
        lv_sql_body := lv_sql_body || ' SELECT /*+ leading(xrpm itc iaj ijm xrpm gic mcb mct) use_nl(itc iaj ijm xrpm gic mcb mct) */' ;
      ELSE
        lv_sql_body := lv_sql_body || ' SELECT /*+ leading(itc iaj ijm xrpm gic mcb mct) use_nl(itc iaj ijm xrpm gic mcb mct) */' ;
      END IF;
      lv_sql_body := lv_sql_body || '  NULL                        AS batch_id' ;
      lv_sql_body := lv_sql_body || ' ,xlv.location_code           AS dept_code' ;
      lv_sql_body := lv_sql_body || ' ,SUBSTRB(xlv.description,1,20)             AS dept_name' ;
      lv_sql_body := lv_sql_body || ' ,xilv.segment1               AS item_location_code' ;
      lv_sql_body := lv_sql_body || ' ,xilv.description            AS item_location_name' ;
      lv_sql_body := lv_sql_body || ' ,mcb.segment1                AS item_div_type' ;
      lv_sql_body := lv_sql_body || ' ,mct.description             AS item_div_value';
      lv_sql_body := lv_sql_body || ' ,ijm.journal_no              AS entry_no' ;
      lv_sql_body := lv_sql_body || ' ,itc.trans_date              AS entry_date';
      lv_sql_body := lv_sql_body || ' ,xrpm.new_div_invent         AS pay_reason_code' ;
      lv_sql_body := lv_sql_body || ' ,flv.meaning                 AS pay_reason_name' ;
      lv_sql_body := lv_sql_body || ' ,NULL                        AS pay_purpose_name' ;
      lv_sql_body := lv_sql_body || ' ,iimb.item_no                AS pay_item_no' ;
      lv_sql_body := lv_sql_body || ' ,ximb.item_short_name        AS pay_item_name';
      lv_sql_body := lv_sql_body || ' ,DECODE(ilm.lot_id,0,NULL,ilm.lot_no) AS pay_lot_no';
-- 2009/03/12 v1.20 ADD START
      lv_sql_body := lv_sql_body || ' ,ilm. attribute14            AS pay_rank1' ;
-- 2009/03/12 v1.20 ADD END
      lv_sql_body := lv_sql_body || ' ,ROUND(itc.trans_qty,4) * -1 AS pay_quant';
      lv_sql_body := lv_sql_body || ' ,CASE iimb.attribute15' ;
      lv_sql_body := lv_sql_body || '    WHEN '|| cv_sc || gc_cost_manage_code_n || cv_sc ||' THEN' ;
      lv_sql_body := lv_sql_body || '      ROUND(NVL(xsupv.stnd_unit_price,0),3)' ;
      lv_sql_body := lv_sql_body || '    WHEN '|| cv_sc || gc_cost_manage_code_j || cv_sc ||' THEN' ;
      lv_sql_body := lv_sql_body || '      ROUND(TO_NUMBER(NVL(ilm.attribute7,0)),3)' ;
      lv_sql_body := lv_sql_body || '    ELSE ' ;
      lv_sql_body := lv_sql_body || '      ' || gc_cost_0 ;
      lv_sql_body := lv_sql_body || '  END                         AS pay_unt_price' ;
      lv_sql_body := lv_sql_body || ' ,NULL                        AS rcv_reason_code' ;
      lv_sql_body := lv_sql_body || ' ,NULL                        AS rcv_reason_name' ;
      lv_sql_body := lv_sql_body || ' ,NULL                        AS rcv_purpose_name' ;
      lv_sql_body := lv_sql_body || ' ,NULL                        AS rcv_item_no' ;
      lv_sql_body := lv_sql_body || ' ,NULL                        AS rcv_item_name';
      lv_sql_body := lv_sql_body || ' ,NULL                        AS rcv_lot_no';
-- 2009/03/12 v1.20 ADD START
      lv_sql_body := lv_sql_body || ' ,NULL                        AS rcv_rank1' ;
-- 2009/03/12 v1.20 ADD END
      lv_sql_body := lv_sql_body || ' ,0                           AS rcv_quant';
      lv_sql_body := lv_sql_body || ' ,0                           AS rcv_unt_price' ;
-- 2009/01/20 v1.18 ADD START
      lv_sql_body := lv_sql_body || ' ,ijm. attribute2             AS description' ;
-- 2009/01/20 v1.18 ADD END
    ELSE
      IF (gr_param.reason_code IS NOT NULL)                 -- xrpm.new_div_inventに指定がある
        OR
         (
           (gr_param.out_item_ctl IS NOT NULL) AND          -- mcb.segment1に指定がある
           (gr_param.reason_code IS NULL)      AND          -- xrpm.new_div_inventに指定がない
           (gr_param.item_location_id IS NULL) AND          -- xilv.inventory_location_idに指定がない
           (gr_param.item1 IS NULL)            AND          -- itc.item_id1〜3に指定がない
           (gr_param.item2 IS NULL)            AND
           (gr_param.item3 IS NULL)
         ) THEN
        lv_sql_body := lv_sql_body || ' SELECT /*+ leading(xrpm itc iaj ijm xrpm gic mcb mct) use_nl(itc iaj ijm xrpm gic mcb mct) */' ;
      ELSE
        lv_sql_body := lv_sql_body || ' SELECT /*+ leading(itc iaj ijm xrpm gic mcb mct) use_nl(itc iaj ijm xrpm gic mcb mct) */' ;
      END IF;
      lv_sql_body := lv_sql_body || '  NULL                        AS batch_id' ;
      lv_sql_body := lv_sql_body || ' ,xlv.location_code           AS dept_code' ;
      lv_sql_body := lv_sql_body || ' ,SUBSTRB(xlv.description,1,20)             AS dept_name' ;
      lv_sql_body := lv_sql_body || ' ,xilv.segment1               AS item_location_code' ;
      lv_sql_body := lv_sql_body || ' ,xilv.description            AS item_location_name' ;
      lv_sql_body := lv_sql_body || ' ,mcb.segment1                AS item_div_type' ;
      lv_sql_body := lv_sql_body || ' ,mct.description             AS item_div_value';
      lv_sql_body := lv_sql_body || ' ,ijm.journal_no              AS entry_no' ;
      lv_sql_body := lv_sql_body || ' ,itc.trans_date              AS entry_date';
      lv_sql_body := lv_sql_body || ' ,NULL                        AS pay_reason_code' ;
      lv_sql_body := lv_sql_body || ' ,NULL                        AS pay_reason_name' ;
      lv_sql_body := lv_sql_body || ' ,NULL                        AS pay_purpose_name' ;
      lv_sql_body := lv_sql_body || ' ,NULL                        AS pay_item_no' ;
      lv_sql_body := lv_sql_body || ' ,NULL                        AS pay_item_name';
      lv_sql_body := lv_sql_body || ' ,NULL                        AS pay_lot_no';
-- 2009/03/12 v1.20 ADD START
      lv_sql_body := lv_sql_body || ' ,NULL                        AS pay_rank1' ;
-- 2009/03/12 v1.20 ADD END
      lv_sql_body := lv_sql_body || ' ,0                           AS pay_quant';
      lv_sql_body := lv_sql_body || ' ,0                           AS pay_unt_price' ;
      lv_sql_body := lv_sql_body || ' ,xrpm.new_div_invent         AS rcv_reason_code' ;
      lv_sql_body := lv_sql_body || ' ,flv.meaning                 AS rcv_reason_name' ;
      lv_sql_body := lv_sql_body || ' ,NULL                        AS rcv_purpose_name' ;
      lv_sql_body := lv_sql_body || ' ,iimb.item_no                AS rcv_item_no' ;
      lv_sql_body := lv_sql_body || ' ,ximb.item_short_name        AS rcv_item_name';
      lv_sql_body := lv_sql_body || ' ,DECODE(ilm.lot_id,0,NULL,ilm.lot_no) AS rcv_lot_no';
-- 2009/03/12 v1.20 ADD START
      lv_sql_body := lv_sql_body || ' ,ilm. attribute14            AS rcv_rank1' ;
-- 2009/03/12 v1.20 ADD END
      lv_sql_body := lv_sql_body || ' ,ROUND(itc.trans_qty,4) AS rcv_quant';
      lv_sql_body := lv_sql_body || ' ,CASE iimb.attribute15' ;
      lv_sql_body := lv_sql_body || '    WHEN '|| cv_sc || gc_cost_manage_code_n || cv_sc ||' THEN' ;
      lv_sql_body := lv_sql_body || '      ROUND(NVL(xsupv.stnd_unit_price,0),3)' ;
      lv_sql_body := lv_sql_body || '    WHEN '|| cv_sc || gc_cost_manage_code_j || cv_sc ||' THEN' ;
      lv_sql_body := lv_sql_body || '      ROUND(TO_NUMBER(NVL(ilm.attribute7,0)),3)' ;
      lv_sql_body := lv_sql_body || '    ELSE ' ;
      lv_sql_body := lv_sql_body || '      ' || gc_cost_0 ;
      lv_sql_body := lv_sql_body || ' END                          AS rcv_unt_price' ;
-- 2009/01/20 v1.18 ADD START
      lv_sql_body := lv_sql_body || ' ,ijm. attribute2             AS description' ;
-- 2009/01/20 v1.18 ADD END
    END IF ;
    ---------------------------------------------------------------------------------------
    -- FROM句
    lv_sql_body := lv_sql_body || ' FROM xxcmn_item_mst_b     ximb' ;
    lv_sql_body := lv_sql_body || ' ,ic_item_mst_b            iimb' ;
    lv_sql_body := lv_sql_body || ' ,gmi_item_categories       gic' ;
    lv_sql_body := lv_sql_body || ' ,mtl_categories_b          mcb' ;
    lv_sql_body := lv_sql_body || ' ,mtl_categories_tl         mct' ;
    lv_sql_body := lv_sql_body || ' ,ic_lots_mst               ilm' ;
    lv_sql_body := lv_sql_body || ' ,xxinv_rcv_pay_mst6_v     xrpm' ;
    lv_sql_body := lv_sql_body || ' ,ic_jrnl_mst               ijm' ;
    lv_sql_body := lv_sql_body || ' ,ic_adjs_jnl               iaj' ;
    lv_sql_body := lv_sql_body || ' ,ic_tran_cmp               itc' ;
    lv_sql_body := lv_sql_body || ' ,xxcmn_item_locations2_v  xilv' ;
    lv_sql_body := lv_sql_body || ' ,xxcmn_locations2_v        xlv' ;
    lv_sql_body := lv_sql_body || ' ,fnd_lookup_values         flv' ;
-- %%%%%%%%%% 2009/5/12 v1.22 S %%%%%%%%%%
--    lv_sql_body := lv_sql_body || ' ,xxcmn_stnd_unit_price_v xsupv' ;
    lv_sql_body := lv_sql_body || ' ,xxcmn_stnd_unit_price2_v xsupv' ;
-- %%%%%%%%%% 2009/5/12 v1.22 E %%%%%%%%%%
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
    lv_sql_body := lv_sql_body || ' AND xrpm.use_div_invent_rep    = :para_use_div_invent_rep' ;
    lv_sql_body := lv_sql_body || ' AND xrpm.rcv_pay_div           = :line_type';
    lv_sql_body := lv_sql_body || ' AND ((xrpm.reason_code           = ''' || gc_x977 || '''';
    lv_sql_body := lv_sql_body || ' AND xrpm.rcv_pay_div           = 1';
    lv_sql_body := lv_sql_body || ' AND ijm.attribute4           = ''' || gc_ukeire || ''')';
    lv_sql_body := lv_sql_body || ' OR (xrpm.reason_code           = ''' || gc_x977 || '''';
    lv_sql_body := lv_sql_body || ' AND xrpm.rcv_pay_div           = -1';
    lv_sql_body := lv_sql_body || ' AND ijm.attribute4           IS NULL )';
    lv_sql_body := lv_sql_body || ' OR (xrpm.reason_code           != ''' || gc_x977 || '''))';
    -- OPM品目情報VIEW結合
    lv_sql_body := lv_sql_body || ' AND itc.item_id                = iimb.item_id' ;
    lv_sql_body := lv_sql_body || ' AND :para_sql_date_from BETWEEN ximb.start_date_active' ;
    lv_sql_body := lv_sql_body || '   AND ximb.end_date_active' ;
    -- OPM品目カテゴリ割当情報VIEW結合
    lv_sql_body := lv_sql_body || ' AND ximb.item_id  = iimb.item_id' ;
    lv_sql_body := lv_sql_body || ' AND itc.item_id  = gic.item_id' ;
    lv_sql_body := lv_sql_body || ' AND mct.source_lang  = :para_language_code ' ;
    lv_sql_body := lv_sql_body || ' AND mct.language     = :para_language_code ' ;
    lv_sql_body := lv_sql_body || ' AND mcb.category_id        = mct.category_id' ;
    lv_sql_body := lv_sql_body || ' AND gic.category_id        = mcb.category_id' ;
    lv_sql_body := lv_sql_body || ' AND gic.category_set_id    = FND_PROFILE.VALUE(:para_item_class)' ;
    -- 標準原価情報VIEW結合
    lv_sql_body := lv_sql_body || ' AND xsupv.item_id(+)           = itc.item_id ' ;
    lv_sql_body := lv_sql_body || ' AND :para_sql_date_from BETWEEN ' ;
    lv_sql_body := lv_sql_body || '   xsupv.start_date_active(+)' ;
    lv_sql_body := lv_sql_body || '     AND xsupv.end_date_active(+)' ;
    -- OPMロットマスタ結合
    lv_sql_body := lv_sql_body || ' AND itc.lot_id                 = ilm.lot_id' ;
    lv_sql_body := lv_sql_body || ' AND itc.item_id                = ilm.item_id' ;
    -- クイックコード(新区分)結合
    lv_sql_body := lv_sql_body || ' AND flv.lookup_type            = :para_lookup_type_new_div ';
    lv_sql_body := lv_sql_body || ' AND flv.language               = :para_language_code       ';
    lv_sql_body := lv_sql_body || ' AND flv.lookup_code            = xrpm.new_div_invent ';
    -- ユーザマスタ結合
    lv_sql_body := lv_sql_body || ' AND fu.user_id                 = itc.created_by' ;
    -- 従業員マスタ結合
    lv_sql_body := lv_sql_body || ' AND fu.employee_id             = paaf.person_id' ;
    lv_sql_body := lv_sql_body || ' AND :para_sql_date_from BETWEEN paaf.effective_start_date' ;
    lv_sql_body := lv_sql_body || '                                    AND paaf.effective_end_date' ;
    lv_sql_body := lv_sql_body || ' AND papf.person_id             = paaf.person_id' ;
    lv_sql_body := lv_sql_body || ' AND :para_sql_date_from BETWEEN papf.effective_start_date' ;
    lv_sql_body := lv_sql_body || '                                    AND papf.effective_end_date' ;
-- 2009/06/25 ADD START
    -- 従業員区分1,2のみ抽出
    lv_sql_body := lv_sql_body || ' AND papf.attribute3 IN (''1'', ''2'')' ;  
-- 2009/06/25 ADD END
    -- 事業所情報VIEW結合
    lv_sql_body := lv_sql_body || ' AND xlv.location_id            = paaf.location_id' ;
    lv_sql_body := lv_sql_body || ' AND :para_sql_date_from BETWEEN ' ;
    lv_sql_body := lv_sql_body || '   xlv.start_date_active' ;
    lv_sql_body := lv_sql_body || '     AND xlv.end_date_active' ;
    -- OPM保管場所情報VIEW結合
    lv_sql_body := lv_sql_body || ' AND xilv.whse_code             = itc.whse_code' ;
    lv_sql_body := lv_sql_body || ' AND xilv.segment1              = itc.location' ;
    -------------------------------------------------------------------------------
    --必須パラメータ絞込
    --  1．年月日_FROM
    --  2．年月日_TO
    lv_sql_body := lv_sql_body || ' AND itc.trans_date      BETWEEN FND_DATE.STRING_TO_DATE(';
    lv_sql_body := lv_sql_body || ' TO_CHAR(:para_param_date_from, :para_date_mask) ' ;
    lv_sql_body := lv_sql_body || ', :para_date_mask)' ;
    lv_sql_body := lv_sql_body || '                                    AND FND_DATE.STRING_TO_DATE(';
    lv_sql_body := lv_sql_body || ' TO_CHAR(:para_param_date_to, :para_date_mask) ' ;
    lv_sql_body := lv_sql_body || ', :para_date_mask)' ;
    --  3．払出品目区分
    IF (gr_param.out_item_ctl IS NOT NULL) THEN
      lv_sql_body := lv_sql_body || ' AND mcb.segment1 = ' || cv_sc || gr_param.out_item_ctl || cv_sc;
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
    lv_sql_body := lv_sql_body || ' ,mcb.segment1' ;
    lv_sql_body := lv_sql_body || ' ,xrpm.new_div_invent' ;
    lv_sql_body := lv_sql_body || ' ,ijm.journal_no' ;
    lv_sql_body := lv_sql_body || ' ,itc.trans_date' ;
    lv_sql_body := lv_sql_body || ' ,iimb.item_no' ;
    lv_sql_body := lv_sql_body || ' ,ilm.lot_no' ;
--
FND_FILE.PUT_LINE( FND_FILE.LOG, lv_sql_body);
FND_FILE.PUT_LINE( FND_FILE.LOG, gc_use_div_invent_rep );
FND_FILE.PUT_LINE( FND_FILE.LOG, in_line_type );
FND_FILE.PUT_LINE( FND_FILE.LOG, gv_sql_date_from );
FND_FILE.PUT_LINE( FND_FILE.LOG, gc_language_code );
FND_FILE.PUT_LINE( FND_FILE.LOG, gc_language_code );
FND_FILE.PUT_LINE( FND_FILE.LOG, gc_item_class );
FND_FILE.PUT_LINE( FND_FILE.LOG, gv_sql_date_from );
FND_FILE.PUT_LINE( FND_FILE.LOG, gc_lookup_type_new_div );
FND_FILE.PUT_LINE( FND_FILE.LOG, gc_language_code );
FND_FILE.PUT_LINE( FND_FILE.LOG, gv_sql_date_from );
FND_FILE.PUT_LINE( FND_FILE.LOG, gv_sql_date_from );
FND_FILE.PUT_LINE( FND_FILE.LOG, gv_sql_date_from );
FND_FILE.PUT_LINE( FND_FILE.LOG, gr_param.date_from );
FND_FILE.PUT_LINE( FND_FILE.LOG, gc_date_mask );
FND_FILE.PUT_LINE( FND_FILE.LOG, gc_date_mask );
FND_FILE.PUT_LINE( FND_FILE.LOG, gr_param.date_to );
FND_FILE.PUT_LINE( FND_FILE.LOG, gc_date_mask );
FND_FILE.PUT_LINE( FND_FILE.LOG, gc_date_mask );

    EXECUTE IMMEDIATE lv_sql_body BULK COLLECT INTO ot_data_rec USING  gc_use_div_invent_rep
                                                                      ,in_line_type
                                                                      ,gv_sql_date_from
                                                                      ,gc_language_code
                                                                      ,gc_language_code
                                                                      ,gc_item_class
                                                                      ,gv_sql_date_from
                                                                      ,gc_lookup_type_new_div
                                                                      ,gc_language_code
                                                                      ,gv_sql_date_from
                                                                      ,gv_sql_date_from
                                                                      ,gv_sql_date_from
                                                                      ,gr_param.date_from
                                                                      ,gc_date_mask
                                                                      ,gc_date_mask
                                                                      ,gr_param.date_to
                                                                      ,gc_date_mask
                                                                      ,gc_date_mask
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
    IF (iv_doc_type = gc_doc_type_omso) THEN
      lv_sql_body := lv_sql_body || ' SELECT /*+ leading(xoha ooha otta wdd itp) use_nl(xoha ooha otta wdd itp) */' ;
    ELSE
      lv_sql_body := lv_sql_body || ' SELECT /*+ leading(xoha ooha otta rsl itp) use_nl(xoha ooha otta rsl itp) */' ;
    END IF ;
    lv_sql_body := lv_sql_body || '  NULL                        AS batch_id' ;
    lv_sql_body := lv_sql_body || ' ,xlv.location_code           AS dept_code' ;
    lv_sql_body := lv_sql_body || ' ,SUBSTRB(xlv.description,1,20)             AS dept_name' ;
    lv_sql_body := lv_sql_body || ' ,xilv.segment1               AS item_location_code' ;
    lv_sql_body := lv_sql_body || ' ,xilv.description            AS item_location_name' ;
    lv_sql_body := lv_sql_body || ' ,mcb.segment1                AS item_div_type' ;
    lv_sql_body := lv_sql_body || ' ,mct.description             AS item_div_value' ;
    lv_sql_body := lv_sql_body || ' ,xoha.request_no             AS entry_no' ;
    lv_sql_body := lv_sql_body || ' ,xoha.shipped_date           AS entry_date' ;
    lv_sql_body := lv_sql_body || ' ,xrpm.new_div_invent         AS pay_reason_code' ;
    lv_sql_body := lv_sql_body || ' ,flv.meaning                 AS pay_reason_name' ;
    lv_sql_body := lv_sql_body || ' ,NULL                        AS pay_purpose_name' ;
    lv_sql_body := lv_sql_body || ' ,iimb.item_no                AS pay_item_no' ;
    lv_sql_body := lv_sql_body || ' ,ximb.item_short_name        AS pay_item_name' ;
    lv_sql_body := lv_sql_body || ' ,ilm.lot_no                  AS pay_lot_no' ;
-- 2009/03/12 v1.20 ADD START
    lv_sql_body := lv_sql_body || ' ,ilm. attribute14            AS pay_rank1' ;
-- 2009/03/12 v1.20 ADD END
    IF (iv_doc_type = gc_doc_type_porc) THEN
      lv_sql_body := lv_sql_body || ',ROUND(itp.trans_qty*-1,4)    AS pay_quant' ;
    ELSE
      lv_sql_body := lv_sql_body || ',ABS(ROUND(itp.trans_qty,4))  AS pay_quant' ;
    END IF ;
    lv_sql_body := lv_sql_body || ' ,CASE iimb.attribute15' ;
    lv_sql_body := lv_sql_body || '    WHEN :para_cost_manage_code_n THEN' ;
    lv_sql_body := lv_sql_body || '      ROUND(NVL(xsupv.stnd_unit_price,0),3)' ;
    lv_sql_body := lv_sql_body || '    WHEN :para_cost_manage_code_j THEN' ;
    lv_sql_body := lv_sql_body || '      ROUND(TO_NUMBER(NVL(ilm.attribute7,0)),3)' ;
    lv_sql_body := lv_sql_body || '    ELSE ' ;
    lv_sql_body := lv_sql_body || '      ' || gc_cost_0 ;
    lv_sql_body := lv_sql_body || ' END                          AS pay_unt_price' ;
    lv_sql_body := lv_sql_body || ' ,NULL                        AS rcv_reason_code' ;
    lv_sql_body := lv_sql_body || ' ,NULL                        AS rcv_reason_name' ;
    lv_sql_body := lv_sql_body || ' ,NULL                        AS rcv_purpose_name' ;
    lv_sql_body := lv_sql_body || ' ,NULL                        AS rcv_item_no' ;
    lv_sql_body := lv_sql_body || ' ,NULL                        AS rcv_item_name';
    lv_sql_body := lv_sql_body || ' ,NULL                        AS rcv_lot_no';
-- 2009/03/12 v1.20 ADD START
    lv_sql_body := lv_sql_body || ' ,NULL                        AS rcv_rank1' ;
-- 2009/03/12 v1.20 ADD END
    lv_sql_body := lv_sql_body || ' ,0                           AS rcv_quant';
    lv_sql_body := lv_sql_body || ' ,0                           AS rcv_unt_price' ;
-- 2009/01/20 v1.18 ADD START
    lv_sql_body := lv_sql_body || ' ,xoha. shipping_instructions AS description' ;
-- 2009/01/20 v1.18 ADD END
    ---------------------------------------------------------------------------------------
    -- FROM句
    lv_sql_body := lv_sql_body || ' FROM xxcmn_item_mst_b     ximb' ;
    lv_sql_body := lv_sql_body || ' ,ic_item_mst_b            iimb' ;
    lv_sql_body := lv_sql_body || ' ,gmi_item_categories      gic' ;
    lv_sql_body := lv_sql_body || ' ,mtl_categories_b         mcb' ;
    lv_sql_body := lv_sql_body || ' ,mtl_categories_tl        mct' ;
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
    lv_sql_body := lv_sql_body || ' WHERE itp.completed_ind             = :para_comp_ind_on ';
    lv_sql_body := lv_sql_body || ' AND itp.reverse_id                  IS NULL' ;
    -- 受払区分アドオンマスタ結合
    lv_sql_body := lv_sql_body || ' AND xrpm.doc_type                   = itp.doc_type';
    lv_sql_body := lv_sql_body || ' AND xrpm.ship_prov_rcv_pay_category = otta.attribute11';
    lv_sql_body := lv_sql_body || ' AND xrpm.stock_adjustment_div       = otta.attribute4';
    lv_sql_body := lv_sql_body || ' AND xrpm.stock_adjustment_div       = :para_stock_adjst_div_sa';
    lv_sql_body := lv_sql_body || ' AND xrpm.use_div_invent_rep         = :para_use_div_invent_rep';
    lv_sql_body := lv_sql_body || ' AND xrpm.rcv_pay_div                = :para_line_type_pay     ';
    -- 受注ヘッダ(アドオン)結合
    lv_sql_body := lv_sql_body || ' AND xoha.header_id                  = ooha.header_id' ;
    -- 受注タイプ結合
    lv_sql_body := lv_sql_body || ' AND otta.transaction_type_id        = xoha.order_type_id' ;
    -- OPM品目情報VIEW結合
    lv_sql_body := lv_sql_body || ' AND itp.item_id                = iimb.item_id' ;
    lv_sql_body := lv_sql_body || ' AND :para_sql_date_from BETWEEN ximb.start_date_active' ;
    lv_sql_body := lv_sql_body || '   AND ximb.end_date_active' ;
    -- OPM品目カテゴリ割当情報VIEW結合
    lv_sql_body := lv_sql_body || ' AND ximb.item_id  = iimb.item_id' ;
    lv_sql_body := lv_sql_body || ' AND itp.item_id  = gic.item_id' ;
    lv_sql_body := lv_sql_body || ' AND mct.source_lang  = :para_language_code ' ;
    lv_sql_body := lv_sql_body || ' AND mct.language     = :para_language_code ' ;
    lv_sql_body := lv_sql_body || ' AND mcb.category_id        = mct.category_id' ;
    lv_sql_body := lv_sql_body || ' AND gic.category_id        = mcb.category_id' ;
    lv_sql_body := lv_sql_body || ' AND gic.category_set_id    = FND_PROFILE.VALUE(:para_item_class)' ;
    -- 標準原価情報VIEW結合
    lv_sql_body := lv_sql_body || ' AND xsupv.item_id(+)           = itp.item_id ' ;
    lv_sql_body := lv_sql_body || ' AND :para_sql_date_from BETWEEN ' ;
    lv_sql_body := lv_sql_body || '   xsupv.start_date_active(+)' ;
    lv_sql_body := lv_sql_body || '     AND xsupv.end_date_active(+)' ;
    -- OPMロットマスタ結合
    lv_sql_body := lv_sql_body || ' AND itp.lot_id                 = ilm.lot_id' ;
    lv_sql_body := lv_sql_body || ' AND itp.item_id                = ilm.item_id' ;
    -- クイックコード(新区分)結合
    lv_sql_body := lv_sql_body || ' AND flv.lookup_type            = :para_lookup_type_new_div ' ;
    lv_sql_body := lv_sql_body || ' AND flv.language               = :para_language_code       ' ;
    lv_sql_body := lv_sql_body || ' AND flv.lookup_code            = xrpm.new_div_invent ';
    -- ユーザマスタ結合
    lv_sql_body := lv_sql_body || ' AND fu.user_id                 = xoha.created_by' ;
    -- 従業員マスタ結合
    lv_sql_body := lv_sql_body || ' AND fu.employee_id             = paaf.person_id' ;
    lv_sql_body := lv_sql_body || ' AND :para_sql_date_from BETWEEN paaf.effective_start_date' ;
    lv_sql_body := lv_sql_body || '                                    AND paaf.effective_end_date' ;
    lv_sql_body := lv_sql_body || ' AND papf.person_id             = paaf.person_id' ;
    lv_sql_body := lv_sql_body || ' AND :para_sql_date_from BETWEEN papf.effective_start_date' ;
    lv_sql_body := lv_sql_body || '                                    AND papf.effective_end_date' ;
-- 2009/06/25 ADD START
    -- 従業員区分1,2のみ抽出
    lv_sql_body := lv_sql_body || ' AND papf.attribute3 IN (''1'', ''2'')' ;  
-- 2009/06/25 ADD END
    -- 事業所情報VIEW結合
    lv_sql_body := lv_sql_body || ' AND xlv.location_id            = paaf.location_id' ;
    lv_sql_body := lv_sql_body || ' AND :para_sql_date_from BETWEEN ' ;
    lv_sql_body := lv_sql_body || '   xlv.start_date_active' ;
    lv_sql_body := lv_sql_body || '     AND xlv.end_date_active' ;
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
    lv_sql_body := lv_sql_body || ' TO_CHAR(:para_param_date_from, :para_date_mask)' ;
    lv_sql_body := lv_sql_body || ', :para_date_mask)' ;
    lv_sql_body := lv_sql_body || '                            AND FND_DATE.STRING_TO_DATE(';
    lv_sql_body := lv_sql_body || ' TO_CHAR(:para_param_date_to, :para_date_mask)' ;
    lv_sql_body := lv_sql_body || ', :para_date_mask)' ;
    -------------------------------------------------------------------------------
    --  3．払出品目区分
    IF (gr_param.out_item_ctl IS NOT NULL) THEN
      lv_sql_body := lv_sql_body || ' AND mcb.segment1 =' || cv_sc || gr_param.out_item_ctl || cv_sc;
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
      lv_sql_body := lv_sql_body || ' AND iimb.item_id IN('||lv_work_str_2 || ')';
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
    lv_sql_body := lv_sql_body || ' ,mcb.segment1' ;
    lv_sql_body := lv_sql_body || ' ,xrpm.new_div_invent' ;
    lv_sql_body := lv_sql_body || ' ,xoha.request_no' ;
    lv_sql_body := lv_sql_body || ' ,xoha.shipped_date' ;
    lv_sql_body := lv_sql_body || ' ,iimb.item_no' ;
    lv_sql_body := lv_sql_body || ' ,ilm.lot_no' ;
--
    EXECUTE IMMEDIATE lv_sql_body BULK COLLECT INTO ot_data_rec USING  gc_cost_manage_code_n
                                                                      ,gc_cost_manage_code_j
                                                                      ,gc_comp_ind_on
                                                                      ,gc_stock_adjst_div_sa
                                                                      ,gc_use_div_invent_rep
                                                                      ,gc_line_type_pay
                                                                      ,gv_sql_date_from
                                                                      ,gc_language_code
                                                                      ,gc_language_code
                                                                      ,gc_item_class
                                                                      ,gv_sql_date_from
                                                                      ,gc_lookup_type_new_div
                                                                      ,gc_language_code
                                                                      ,gv_sql_date_from
                                                                      ,gv_sql_date_from
                                                                      ,gv_sql_date_from
                                                                      ,gr_param.date_from
                                                                      ,gc_date_mask
                                                                      ,gc_date_mask
                                                                      ,gr_param.date_to
                                                                      ,gc_date_mask
                                                                      ,gc_date_mask
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
    gv_sql_date_from :=  gr_param.date_from;
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
            lt_prod_all_data(ln_prod_cnt). pay_purpose_name   := NULL ;
            lt_prod_all_data(ln_prod_cnt). pay_item_no        := NULL ;
            lt_prod_all_data(ln_prod_cnt). pay_item_name      := NULL ;
            lt_prod_all_data(ln_prod_cnt). pay_lot_no         := NULL ;
-- 2009/03/12 v1.20 ADD START
            lt_prod_all_data(ln_prod_cnt). pay_rank1          := NULL ;
-- 2009/03/12 v1.20 ADD END
            lt_prod_all_data(ln_prod_cnt). pay_quant          := 0 ;
            lt_prod_all_data(ln_prod_cnt). pay_unt_price      := 0 ;
            lt_prod_all_data(ln_prod_cnt). rcv_reason_code    := lt_prod_rcv_data(ln_rcv_cnt).rcv_reason_code ;
            lt_prod_all_data(ln_prod_cnt). rcv_reason_name    := lt_prod_rcv_data(ln_rcv_cnt).rcv_reason_name ;
            lt_prod_all_data(ln_prod_cnt). rcv_purpose_name   := lt_prod_rcv_data(ln_rcv_cnt).rcv_purpose_name ;
            lt_prod_all_data(ln_prod_cnt). rcv_item_no        := lt_prod_rcv_data(ln_rcv_cnt).rcv_item_no ;
            lt_prod_all_data(ln_prod_cnt). rcv_item_name      := lt_prod_rcv_data(ln_rcv_cnt).rcv_item_name ;
            lt_prod_all_data(ln_prod_cnt). rcv_lot_no         := lt_prod_rcv_data(ln_rcv_cnt).rcv_lot_no ;
-- 2009/03/12 v1.20 ADD START
            lt_prod_all_data(ln_prod_cnt). rcv_rank1          := lt_prod_rcv_data(ln_rcv_cnt).rcv_rank1 ;
-- 2009/03/12 v1.20 ADD END
            lt_prod_all_data(ln_prod_cnt). rcv_quant          := lt_prod_rcv_data(ln_rcv_cnt).rcv_quant ;
            lt_prod_all_data(ln_prod_cnt). rcv_unt_price      := lt_prod_rcv_data(ln_rcv_cnt).rcv_unt_price ;
-- 2009/01/20 v1.18 ADD START
            lt_prod_all_data(ln_prod_cnt). description        := lt_prod_rcv_data(ln_rcv_cnt).description ;
-- 2009/01/20 v1.18 ADD END
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
        lt_prod_all_data(ln_prod_cnt). pay_purpose_name   := lt_prod_pay_data(i).pay_purpose_name ;
        lt_prod_all_data(ln_prod_cnt). pay_item_no        := lt_prod_pay_data(i).pay_item_no ;
        lt_prod_all_data(ln_prod_cnt). pay_item_name      := lt_prod_pay_data(i).pay_item_name ;
        lt_prod_all_data(ln_prod_cnt). pay_lot_no         := lt_prod_pay_data(i).pay_lot_no ;
-- 2009/03/12 v1.20 ADD START
        lt_prod_all_data(ln_prod_cnt). pay_rank1          := lt_prod_pay_data(i).pay_rank1 ;
-- 2009/03/12 v1.20 ADD END
        lt_prod_all_data(ln_prod_cnt). pay_quant          := lt_prod_pay_data(i).pay_quant ;
        lt_prod_all_data(ln_prod_cnt). pay_unt_price      := lt_prod_pay_data(i).pay_unt_price ;
        lt_prod_all_data(ln_prod_cnt). rcv_reason_code    := lt_prod_rcv_data(ln_rcv_cnt).rcv_reason_code ;
        lt_prod_all_data(ln_prod_cnt). rcv_reason_name    := lt_prod_rcv_data(ln_rcv_cnt).rcv_reason_name ;
        lt_prod_all_data(ln_prod_cnt). rcv_purpose_name   := lt_prod_rcv_data(ln_rcv_cnt).rcv_purpose_name ;
        lt_prod_all_data(ln_prod_cnt). rcv_item_no        := lt_prod_rcv_data(ln_rcv_cnt).rcv_item_no ;
        lt_prod_all_data(ln_prod_cnt). rcv_item_name      := lt_prod_rcv_data(ln_rcv_cnt).rcv_item_name ;
        lt_prod_all_data(ln_prod_cnt). rcv_lot_no         := lt_prod_rcv_data(ln_rcv_cnt).rcv_lot_no ;
-- 2009/03/12 v1.20 ADD START
        lt_prod_all_data(ln_prod_cnt). rcv_rank1          := lt_prod_rcv_data(ln_rcv_cnt).rcv_rank1 ;
-- 2009/03/12 v1.20 ADD END
        lt_prod_all_data(ln_prod_cnt). rcv_quant          := lt_prod_rcv_data(ln_rcv_cnt).rcv_quant ;
        lt_prod_all_data(ln_prod_cnt). rcv_unt_price      := lt_prod_rcv_data(ln_rcv_cnt).rcv_unt_price ;
-- 2009/01/20 v1.18 ADD START
        lt_prod_all_data(ln_prod_cnt). description        := lt_prod_rcv_data(ln_rcv_cnt).description ;
-- 2009/01/20 v1.18 ADD END
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
        lt_prod_all_data(ln_prod_cnt). pay_purpose_name   := lt_prod_pay_data(i).pay_purpose_name ;
        lt_prod_all_data(ln_prod_cnt). pay_item_no        := lt_prod_pay_data(i).pay_item_no ;
        lt_prod_all_data(ln_prod_cnt). pay_item_name      := lt_prod_pay_data(i).pay_item_name ;
        lt_prod_all_data(ln_prod_cnt). pay_lot_no         := lt_prod_pay_data(i).pay_lot_no ;
-- 2009/03/12 v1.20 ADD START
        lt_prod_all_data(ln_prod_cnt). pay_rank1          := lt_prod_pay_data(i).pay_rank1 ;
-- 2009/03/12 v1.20 ADD END
        lt_prod_all_data(ln_prod_cnt). pay_quant          := lt_prod_pay_data(i).pay_quant ;
        lt_prod_all_data(ln_prod_cnt). pay_unt_price      := lt_prod_pay_data(i).pay_unt_price ;
        lt_prod_all_data(ln_prod_cnt). rcv_reason_code    := NULL ;
        lt_prod_all_data(ln_prod_cnt). rcv_reason_name    := NULL ;
        lt_prod_all_data(ln_prod_cnt). rcv_purpose_name   := NULL ;
        lt_prod_all_data(ln_prod_cnt). rcv_item_no        := NULL ;
        lt_prod_all_data(ln_prod_cnt). rcv_item_name      := NULL ;
        lt_prod_all_data(ln_prod_cnt). rcv_lot_no         := NULL ;
-- 2009/03/12 v1.20 ADD START
        lt_prod_all_data(ln_prod_cnt). rcv_rank1          := NULL ;
-- 2009/03/12 v1.20 ADD END
        lt_prod_all_data(ln_prod_cnt). rcv_quant          := 0 ;
        lt_prod_all_data(ln_prod_cnt). rcv_unt_price      := 0 ;
-- 2009/01/20 v1.18 ADD START
        lt_prod_all_data(ln_prod_cnt). description        := lt_prod_pay_data(i).description ;
-- 2009/01/20 v1.18 ADD END
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
          lt_prod_all_data(ln_prod_cnt). pay_purpose_name   := NULL ;
          lt_prod_all_data(ln_prod_cnt). pay_item_no        := NULL ;
          lt_prod_all_data(ln_prod_cnt). pay_item_name      := NULL ;
          lt_prod_all_data(ln_prod_cnt). pay_lot_no         := NULL ;
-- 2009/03/12 v1.20 ADD START
          lt_prod_all_data(ln_prod_cnt). pay_rank1          := NULL ;
-- 2009/03/12 v1.20 ADD END
          lt_prod_all_data(ln_prod_cnt). pay_quant          := 0 ;
          lt_prod_all_data(ln_prod_cnt). pay_unt_price      := 0 ;
          lt_prod_all_data(ln_prod_cnt). rcv_reason_code    := lt_prod_rcv_data(ln_rcv_cnt).rcv_reason_code ;
          lt_prod_all_data(ln_prod_cnt). rcv_reason_name    := lt_prod_rcv_data(ln_rcv_cnt).rcv_reason_name ;
          lt_prod_all_data(ln_prod_cnt). rcv_purpose_name   := lt_prod_rcv_data(ln_rcv_cnt).rcv_purpose_name ;
          lt_prod_all_data(ln_prod_cnt). rcv_item_no        := lt_prod_rcv_data(ln_rcv_cnt).rcv_item_no ;
          lt_prod_all_data(ln_prod_cnt). rcv_item_name      := lt_prod_rcv_data(ln_rcv_cnt).rcv_item_name ;
          lt_prod_all_data(ln_prod_cnt). rcv_lot_no         := lt_prod_rcv_data(ln_rcv_cnt).rcv_lot_no ;
-- 2009/03/12 v1.20 ADD START
          lt_prod_all_data(ln_prod_cnt). rcv_rank1          := lt_prod_rcv_data(ln_rcv_cnt).rcv_rank1 ;
-- 2009/03/12 v1.20 ADD END
          lt_prod_all_data(ln_prod_cnt). rcv_quant          := lt_prod_rcv_data(ln_rcv_cnt).rcv_quant ;
          lt_prod_all_data(ln_prod_cnt). rcv_unt_price      := lt_prod_rcv_data(ln_rcv_cnt).rcv_unt_price ;
-- 2009/01/20 v1.18 ADD START
          lt_prod_all_data(ln_prod_cnt). description        := lt_prod_rcv_data(ln_rcv_cnt).description ;
-- 2009/01/20 v1.18 ADD END
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
   * Procedure Name   : prc_get_data_to_sc_tmp_table
   * Description      : 予定情報抽出・加工プロシージャ(C2-2)
   ***********************************************************************************/

  PROCEDURE prc_get_data_to_sc_tmp_table
    (
      ov_errbuf     OUT NOCOPY VARCHAR2    -- エラー・メッセージ
     ,ov_retcode    OUT NOCOPY VARCHAR2    -- リターン・コード
     ,ov_errmsg     OUT NOCOPY VARCHAR2    -- ユーザー・エラー・メッセージ
    )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_get_data_to_sc_tmp_table'; -- プログラム名
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
    gv_sql_date_from :=  gr_param.date_from;
--
    -- ==========================================================
    -- 生産(PROD)データ取得・格納処理
    -- ==========================================================
    -- 払出データ抽出
    prc_get_prod_pay_schedule_data
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
            lt_prod_all_data(ln_prod_cnt). pay_purpose_name   := NULL ;
            lt_prod_all_data(ln_prod_cnt). pay_item_no        := NULL ;
            lt_prod_all_data(ln_prod_cnt). pay_item_name      := NULL ;
            lt_prod_all_data(ln_prod_cnt). pay_lot_no         := NULL ;
-- 2009/03/12 v1.20 ADD START
            lt_prod_all_data(ln_prod_cnt). pay_rank1          := NULL ;
-- 2009/03/12 v1.20 ADD END
            lt_prod_all_data(ln_prod_cnt). pay_quant          := 0 ;
            lt_prod_all_data(ln_prod_cnt). pay_unt_price      := 0 ;
            lt_prod_all_data(ln_prod_cnt). rcv_reason_code    := lt_prod_rcv_data(ln_rcv_cnt).rcv_reason_code ;
            lt_prod_all_data(ln_prod_cnt). rcv_reason_name    := lt_prod_rcv_data(ln_rcv_cnt).rcv_reason_name ;
            lt_prod_all_data(ln_prod_cnt). rcv_purpose_name   := lt_prod_rcv_data(ln_rcv_cnt).rcv_purpose_name ;
            lt_prod_all_data(ln_prod_cnt). rcv_item_no        := lt_prod_rcv_data(ln_rcv_cnt).rcv_item_no ;
            lt_prod_all_data(ln_prod_cnt). rcv_item_name      := lt_prod_rcv_data(ln_rcv_cnt).rcv_item_name ;
            lt_prod_all_data(ln_prod_cnt). rcv_lot_no         := lt_prod_rcv_data(ln_rcv_cnt).rcv_lot_no ;
-- 2009/03/12 v1.20 ADD START
            lt_prod_all_data(ln_prod_cnt). rcv_rank1          := lt_prod_rcv_data(ln_rcv_cnt).rcv_rank1 ;
-- 2009/03/12 v1.20 ADD END
            lt_prod_all_data(ln_prod_cnt). rcv_quant          := lt_prod_rcv_data(ln_rcv_cnt).rcv_quant ;
            lt_prod_all_data(ln_prod_cnt). rcv_unt_price      := lt_prod_rcv_data(ln_rcv_cnt).rcv_unt_price ;
-- 2009/01/20 v1.18 ADD START
            lt_prod_all_data(ln_prod_cnt). description        := lt_prod_rcv_data(ln_rcv_cnt).description ;
-- 2009/01/20 v1.18 ADD END
--
            -- カウンタインクリメント
            ln_prod_cnt := ln_prod_cnt + 1 ;
            ln_rcv_cnt  := ln_rcv_cnt  + 1 ;
--
          END LOOP RCV_BREAK_LOOP ;
--
          -- 受データ取得
          prc_get_prod_rcv_schedule_data
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
        lt_prod_all_data(ln_prod_cnt). pay_purpose_name   := lt_prod_pay_data(i).pay_purpose_name ;
        lt_prod_all_data(ln_prod_cnt). pay_item_no        := lt_prod_pay_data(i).pay_item_no ;
        lt_prod_all_data(ln_prod_cnt). pay_item_name      := lt_prod_pay_data(i).pay_item_name ;
        lt_prod_all_data(ln_prod_cnt). pay_lot_no         := lt_prod_pay_data(i).pay_lot_no ;
-- 2009/03/12 v1.20 ADD START
        lt_prod_all_data(ln_prod_cnt). pay_rank1          := lt_prod_pay_data(i).pay_rank1 ;
-- 2009/03/12 v1.20 ADD END
        lt_prod_all_data(ln_prod_cnt). pay_quant          := lt_prod_pay_data(i).pay_quant ;
        lt_prod_all_data(ln_prod_cnt). pay_unt_price      := lt_prod_pay_data(i).pay_unt_price ;
        lt_prod_all_data(ln_prod_cnt). rcv_reason_code    := lt_prod_rcv_data(ln_rcv_cnt).rcv_reason_code ;
        lt_prod_all_data(ln_prod_cnt). rcv_reason_name    := lt_prod_rcv_data(ln_rcv_cnt).rcv_reason_name ;
        lt_prod_all_data(ln_prod_cnt). rcv_purpose_name   := lt_prod_rcv_data(ln_rcv_cnt).rcv_purpose_name ;
        lt_prod_all_data(ln_prod_cnt). rcv_item_no        := lt_prod_rcv_data(ln_rcv_cnt).rcv_item_no ;
        lt_prod_all_data(ln_prod_cnt). rcv_item_name      := lt_prod_rcv_data(ln_rcv_cnt).rcv_item_name ;
        lt_prod_all_data(ln_prod_cnt). rcv_lot_no         := lt_prod_rcv_data(ln_rcv_cnt).rcv_lot_no ;
-- 2009/03/12 v1.20 ADD START
        lt_prod_all_data(ln_prod_cnt). rcv_rank1          := lt_prod_rcv_data(ln_rcv_cnt).rcv_rank1 ;
-- 2009/03/12 v1.20 ADD END
        lt_prod_all_data(ln_prod_cnt). rcv_quant          := lt_prod_rcv_data(ln_rcv_cnt).rcv_quant ;
        lt_prod_all_data(ln_prod_cnt). rcv_unt_price      := lt_prod_rcv_data(ln_rcv_cnt).rcv_unt_price ;
-- 2009/01/20 v1.18 ADD START
        lt_prod_all_data(ln_prod_cnt). description        := lt_prod_rcv_data(ln_rcv_cnt).description ;
-- 2009/01/20 v1.18 ADD END
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
        lt_prod_all_data(ln_prod_cnt). pay_purpose_name   := lt_prod_pay_data(i).pay_purpose_name ;
        lt_prod_all_data(ln_prod_cnt). pay_item_no        := lt_prod_pay_data(i).pay_item_no ;
        lt_prod_all_data(ln_prod_cnt). pay_item_name      := lt_prod_pay_data(i).pay_item_name ;
        lt_prod_all_data(ln_prod_cnt). pay_lot_no         := lt_prod_pay_data(i).pay_lot_no ;
-- 2009/03/12 v1.20 ADD START
        lt_prod_all_data(ln_prod_cnt). pay_rank1          := lt_prod_pay_data(i).pay_rank1 ;
-- 2009/03/12 v1.20 ADD END
        lt_prod_all_data(ln_prod_cnt). pay_quant          := lt_prod_pay_data(i).pay_quant ;
        lt_prod_all_data(ln_prod_cnt). pay_unt_price      := lt_prod_pay_data(i).pay_unt_price ;
        lt_prod_all_data(ln_prod_cnt). rcv_reason_code    := NULL ;
        lt_prod_all_data(ln_prod_cnt). rcv_reason_name    := NULL ;
        lt_prod_all_data(ln_prod_cnt). rcv_purpose_name   := NULL ;
        lt_prod_all_data(ln_prod_cnt). rcv_item_no        := NULL ;
        lt_prod_all_data(ln_prod_cnt). rcv_item_name      := NULL ;
        lt_prod_all_data(ln_prod_cnt). rcv_lot_no         := NULL ;
-- 2009/03/12 v1.20 ADD START
        lt_prod_all_data(ln_prod_cnt). rcv_rank1          := NULL ;
-- 2009/03/12 v1.20 ADD END
        lt_prod_all_data(ln_prod_cnt). rcv_quant          := 0 ;
        lt_prod_all_data(ln_prod_cnt). rcv_unt_price      := 0 ;
-- 2009/01/20 v1.18 ADD START
        lt_prod_all_data(ln_prod_cnt). description      := lt_prod_pay_data(i).description ;
-- 2009/01/20 v1.18 ADD END
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
          lt_prod_all_data(ln_prod_cnt). pay_purpose_name   := NULL ;
          lt_prod_all_data(ln_prod_cnt). pay_item_no        := NULL ;
          lt_prod_all_data(ln_prod_cnt). pay_item_name      := NULL ;
          lt_prod_all_data(ln_prod_cnt). pay_lot_no         := NULL ;
-- 2009/03/12 v1.20 ADD START
          lt_prod_all_data(ln_prod_cnt). pay_rank1          := NULL ;
-- 2009/03/12 v1.20 ADD END
          lt_prod_all_data(ln_prod_cnt). pay_quant          := 0 ;
          lt_prod_all_data(ln_prod_cnt). pay_unt_price      := 0 ;
          lt_prod_all_data(ln_prod_cnt). rcv_reason_code    := lt_prod_rcv_data(ln_rcv_cnt).rcv_reason_code ;
          lt_prod_all_data(ln_prod_cnt). rcv_reason_name    := lt_prod_rcv_data(ln_rcv_cnt).rcv_reason_name ;
          lt_prod_all_data(ln_prod_cnt). rcv_purpose_name   := lt_prod_rcv_data(ln_rcv_cnt).rcv_purpose_name ;
          lt_prod_all_data(ln_prod_cnt). rcv_item_no        := lt_prod_rcv_data(ln_rcv_cnt).rcv_item_no ;
          lt_prod_all_data(ln_prod_cnt). rcv_item_name      := lt_prod_rcv_data(ln_rcv_cnt).rcv_item_name ;
          lt_prod_all_data(ln_prod_cnt). rcv_lot_no         := lt_prod_rcv_data(ln_rcv_cnt).rcv_lot_no ;
-- 2009/03/12 v1.20 ADD START
          lt_prod_all_data(ln_prod_cnt). rcv_rank1          := lt_prod_rcv_data(ln_rcv_cnt).rcv_rank1 ;
-- 2009/03/12 v1.20 ADD END
          lt_prod_all_data(ln_prod_cnt). rcv_quant          := lt_prod_rcv_data(ln_rcv_cnt).rcv_quant ;
          lt_prod_all_data(ln_prod_cnt). rcv_unt_price      := lt_prod_rcv_data(ln_rcv_cnt).rcv_unt_price ;
-- 2009/01/20 v1.18 ADD START
          lt_prod_all_data(ln_prod_cnt). description        := lt_prod_rcv_data(ln_rcv_cnt).description ;
-- 2009/01/20 v1.18 ADD END
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
    -- 中間テーブル登録処理
    FORALL i in 1 .. lt_prod_all_data.COUNT
      INSERT INTO XXINV_550C_SCHEDULE_TMP VALUES lt_prod_all_data(i) ;
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
  END prc_get_data_to_sc_tmp_table ;
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
    ,pay_purpose_name    -- 払出品目振替目的
    ,pay_item_no         -- 払出品目コード
    ,pay_item_name       -- 払出品目名称
    ,pay_lot_no          -- 払出ロットNO
-- 2009/03/12 v1.20 ADD START
    ,pay_rank1           -- 払出ランク１
-- 2009/03/12 v1.20 ADD END
    ,pay_quant           -- 払出総数
    ,pay_unt_price       -- 払出単価
    ,rcv_reason_code     -- 受入事由コード
    ,rcv_reason_name     -- 受入事由名称
    ,rcv_purpose_name    -- 受入品目振替目的
    ,rcv_item_no         -- 受入品目コード
    ,rcv_item_name       -- 受入品目名称
    ,rcv_lot_no          -- 受入ロットNO
-- 2009/03/12 v1.20 ADD START
    ,rcv_rank1           -- 受入ランク１
-- 2009/03/12 v1.20 ADD END
    ,rcv_quant           -- 受入総数
    ,rcv_unt_price       -- 受入単価
-- 2009/01/20 ADD START
    ,description         -- 摘要
-- 2009/01/20 ADD END
    BULK COLLECT INTO ot_out_data
    FROM
    XXINV_550C_TMP
    ORDER BY
     dept_code
    ,item_location_code
    ,item_div_type
    ,CASE
       WHEN rcv_item_no IS NOT NULL AND pay_item_no IS NULL
         THEN 1
         ELSE 2
     END
    ,pay_reason_code
    ,entry_no
    ,entry_date
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
   * Procedure Name   : prc_get_data_from_sc_tmp_table
   * Description      :予定データ取得(最終出力データ)プロシージャ(C2)
   ***********************************************************************************/

  PROCEDURE prc_get_data_from_sc_tmp_table
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
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_get_data_from_sc_tmp_table'; -- プログラム名
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
    ,pay_purpose_name    -- 払出品目振替目的
    ,pay_item_no         -- 払出品目コード
    ,pay_item_name       -- 払出品目名称
    ,pay_lot_no          -- 払出ロットNO
-- 2009/03/12 v1.20 ADD START
    ,pay_rank1           -- 払出ランク１
-- 2009/03/12 v1.20 ADD END
    ,pay_quant           -- 払出総数
    ,pay_unt_price       -- 払出単価
    ,rcv_reason_code     -- 受入事由コード
    ,rcv_reason_name     -- 受入事由名称
    ,rcv_purpose_name    -- 受入品目振替目的
    ,rcv_item_no         -- 受入品目コード
    ,rcv_item_name       -- 受入品目名称
    ,rcv_lot_no          -- 受入ロットNO
-- 2009/03/12 v1.20 ADD START
    ,rcv_rank1           -- 受入ランク１
-- 2009/03/12 v1.20 ADD END
    ,rcv_quant           -- 受入総数
    ,rcv_unt_price       -- 受入単価
-- 2009/01/20 ADD START
    ,description         -- 摘要
-- 2009/01/20 ADD END
    BULK COLLECT INTO ot_out_data
    FROM
    XXINV_550C_SCHEDULE_TMP
    ORDER BY
     dept_code
    ,item_location_code
    ,item_div_type
    ,CASE
       WHEN rcv_item_no IS NOT NULL AND pay_item_no IS NULL
         THEN 1
         ELSE 2
     END
    ,pay_reason_code
    ,entry_no
    ,entry_date
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
  END prc_get_data_from_sc_tmp_table ;
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
-- 2009/01/15 v1.16 N.Yoshida add start
    -- 予実区分が「実績」の場合
    IF ( gr_param.target_class = gc_target_result ) THEN
      gv_report_title := gc_rpt_title_result;
--
    -- 予実区分が「予定」の場合
    ELSE
      gv_report_title := gc_rpt_title_schedule;
    END IF ;
-- 2009/01/15 v1.16 N.Yoshida add end
--
    -- ----------------------------------------------------
    -- 開始タグ
    -- ----------------------------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'root' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
    -- データ未取得の場合
    IF (it_out_data.count = 0) THEN
-- 2009/01/15 v1.16 N.Yoshida add start
      ------------------------------
      -- パラメータデータ開始タグ
      ------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'param_info' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
      -- 帳票タイトル
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'head_title' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
      gt_xml_data_table(gl_xml_idx).tag_value := gv_report_title ;
      ------------------------------
      -- パラメータデータ終了タグ
      ------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := '/param_info' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
-- 2009/01/15 v1.16 N.Yoshida add start
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
          -- 帳票タイトル
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'head_title' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
          gt_xml_data_table(gl_xml_idx).tag_value := gv_report_title ;
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
        ELSIF (NVL(it_out_data(i-1).pay_reason_code,'dummy') <> NVL(it_out_data(i).pay_reason_code,'dummy'))
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
        -- 払出品目振替目的
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'pay_purpose_name' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
        gt_xml_data_table(gl_xml_idx).tag_value := it_out_data(i).pay_purpose_name;
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
-- 2009/03/12 v1.20 ADD START
        -- 払出ランク１
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'pay_rank1' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
        gt_xml_data_table(gl_xml_idx).tag_value := it_out_data(i).pay_rank1;
-- 2009/03/12 v1.20 ADD END
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
        -- 受入品目振替目的
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'rcv_purpose_name' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
        gt_xml_data_table(gl_xml_idx).tag_value := it_out_data(i).rcv_purpose_name;
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
-- 2009/03/12 v1.20 ADD START
        -- 受入ランク１
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'rcv_rank1' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
        gt_xml_data_table(gl_xml_idx).tag_value := it_out_data(i).rcv_rank1;
-- 2009/03/12 v1.20 ADD END
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
-- 2009/01/20 v1.18 ADD START
        -- 摘要
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'description' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
        gt_xml_data_table(gl_xml_idx).tag_value := it_out_data(i).description;
-- 2009/01/20 v1.18 ADD END
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
     iv_target_class          IN  VARCHAR2     -- 01 : 予実区分
    ,iv_date_from             IN  VARCHAR2     -- 02 : 年月日_FROM
    ,iv_date_to               IN  VARCHAR2     -- 03 : 年月日_TO
    ,iv_out_item_ctl          IN  VARCHAR2     -- 04 : 払出品目区分
    ,iv_item1                 IN  VARCHAR2     -- 05 : 品目ID1
    ,iv_item2                 IN  VARCHAR2     -- 06 : 品目ID2
    ,iv_item3                 IN  VARCHAR2     -- 07 : 品目ID3
    ,iv_reason_code           IN  VARCHAR2     -- 08 : 事由コード
    ,iv_item_location_id      IN  VARCHAR2     -- 09 : 保管倉庫ID
    ,iv_dept_id               IN  VARCHAR2     -- 10 : 担当部署ID
    ,iv_entry_no1             IN  VARCHAR2     -- 11 : 伝票No1
    ,iv_entry_no2             IN  VARCHAR2     -- 12 : 伝票No2
    ,iv_entry_no3             IN  VARCHAR2     -- 13 : 伝票No3
    ,iv_entry_no4             IN  VARCHAR2     -- 14 : 伝票No4
    ,iv_entry_no5             IN  VARCHAR2     -- 15 : 伝票No5
    ,iv_price_ctl_flg         IN  VARCHAR2     -- 16 : 金額表示
    ,iv_emp_no                IN  VARCHAR2     -- 17 : 担当者
    ,iv_creation_date_from    IN  VARCHAR2     -- 18 : 更新時間FROM
    ,iv_creation_date_to      IN  VARCHAR2     -- 19 : 更新時間TO
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
-- 2009/01/15 v.1.16 N.Yoshida add start
    gr_param.target_class        := iv_target_class ;
-- 2009/01/15 v.1.16 N.Yoshida add end
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
    IF (iv_target_class = gc_target_result) THEN
      -- ===============================================
      -- 実績情報抽出
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
    ELSE
      -- ===============================================
      -- 予定情報抽出
      -- ===============================================
      -- 抽出データを中間テーブルへ格納
      prc_get_data_to_sc_tmp_table
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
      prc_get_data_from_sc_tmp_table
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
    END IF;
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
     ,iv_target_class         IN   VARCHAR2     -- 01 : 予実区分
     ,iv_date_from            IN   VARCHAR2     -- 02 : 年月日_FROM
     ,iv_date_to              IN   VARCHAR2     -- 03 : 年月日_TO
     ,iv_out_item_ctl         IN   VARCHAR2     -- 04 : 払出品目区分
     ,iv_item1                IN   VARCHAR2     -- 05 : 品目ID1
     ,iv_item2                IN   VARCHAR2     -- 06 : 品目ID2
     ,iv_item3                IN   VARCHAR2     -- 07 : 品目ID3
     ,iv_reason_code          IN   VARCHAR2     -- 08 : 事由コード
     ,iv_item_location_id     IN   VARCHAR2     -- 09 : 保管倉庫ID
     ,iv_dept_id              IN   VARCHAR2     -- 10 : 担当部署ID
     ,iv_entry_no1            IN   VARCHAR2     -- 11 : 伝票No1
     ,iv_entry_no2            IN   VARCHAR2     -- 12 : 伝票No2
     ,iv_entry_no3            IN   VARCHAR2     -- 13 : 伝票No3
     ,iv_entry_no4            IN   VARCHAR2     -- 14 : 伝票No4
     ,iv_entry_no5            IN   VARCHAR2     -- 15 : 伝票No5
     ,iv_price_ctl_flg        IN   VARCHAR2     -- 16 : 金額表示
     ,iv_emp_no               IN   VARCHAR2     -- 17 : 担当者
     ,iv_creation_date_from   IN   VARCHAR2     -- 18 : 更新時間FROM
     ,iv_creation_date_to     IN   VARCHAR2     -- 19 : 更新時間TO
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
       iv_target_class        -- 01 : 予実区分
      ,iv_date_from           -- 02 : 年月日_FROM
      ,iv_date_to             -- 03 : 年月日_TO
      ,iv_out_item_ctl        -- 04 : 払出品目区分
      ,iv_item1               -- 05 : 品目ID1
      ,iv_item2               -- 06 : 品目ID2
      ,iv_item3               -- 07 : 品目ID3
      ,iv_reason_code         -- 08 : 事由コード	
      ,iv_item_location_id    -- 09 : 保管倉庫ID
      ,iv_dept_id             -- 10 : 担当部署ID
      ,iv_entry_no1           -- 11 : 伝票No1
      ,iv_entry_no2           -- 12 : 伝票No2
      ,iv_entry_no3           -- 13 : 伝票No3
      ,iv_entry_no4           -- 14 : 伝票No4
      ,iv_entry_no5           -- 15 : 伝票No5
      ,iv_price_ctl_flg       -- 16 : 金額表示
      ,iv_emp_no              -- 17 : 担当者
      ,iv_creation_date_from  -- 18 : 更新時間FROM
      ,iv_creation_date_to    -- 19 : 更新時間TO
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
