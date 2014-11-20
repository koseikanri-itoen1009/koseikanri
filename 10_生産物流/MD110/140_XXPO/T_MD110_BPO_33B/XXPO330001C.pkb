CREATE OR REPLACE PACKAGE BODY xxpo330001c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxpo330001c(BODY)
 * Description      : 仕入・有償支給（仕入先返品）
 * MD.050/070       : 仕入・有償支給（仕入先返品）Issue2.0  (T_MD050_BPO_330)
 *                    返品指示書                            (T_MD070_BPO_33B)
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  prc_check_param_info   パラメータチェック(B-1)
 *  prc_get_report_data    明細データ取得(B-3)
 *  func_dtl_cnt           明細データ件数取得
 *  prc_create_xml_data    ＸＭＬデータ作成(B-5)
 *  convert_into_xml       XMLデータ変換
 *  func_rank_edit         ランク１・ランク２・ランク３を編集・結合 (B-4)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/01/21    1.0   Yusuke Tabata   新規作成
 *  2008/04/28    1.1   Yusuke Tabata   内部変更#43／TE080不具合対応
 *  2008/05/01    1.2   Yasuhisa Yamamoto TE080不具合対応(330_8)
 *  2008/05/02    1.3   Yasuhisa Yamamoto TE080不具合対応(330_10)
 *  2008/05/02    1.4   Yasuhisa Yamamoto TE080不具合対応(330_11)
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
  -- ======================================================
  -- ユーザー宣言部
  -- ======================================================
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  gv_pkg_name               CONSTANT VARCHAR2(20) := 'xxpo330001c' ;   -- パッケージ名
  gc_report_id              CONSTANT VARCHAR2(12) := 'XXPO330001T' ;   -- 帳票ID
  gc_language_code          CONSTANT VARCHAR2(2)  := 'JA' ;            -- 共通LANGUAGE_CODE
  --SQL用
  gc_category_name_prod     CONSTANT VARCHAR2(8)  := '商品区分' ;     -- カテゴリセット名：商品区分
  gc_category_name_item     CONSTANT VARCHAR2(8)  := '品目区分' ;     -- カテゴリセット名：品目区分
  gc_txns_type_rtn_order    CONSTANT VARCHAR2(1)  := '2' ;            -- 実績区分:仕入先返品
  gc_txns_type_rtn_noorder  CONSTANT VARCHAR2(1)  := '3' ;            -- 実績区分:発注無仕入先返品
  gc_drop_ship_type_normal  CONSTANT VARCHAR2(1)  := '1' ;            -- 直送区分:通常
  gc_drop_ship_type_sup_req CONSTANT VARCHAR2(1)  := '3' ;            -- 直送区分:支給依頼
  gc_rtn_quant_0            CONSTANT NUMBER       :=  0  ;            -- 件数:0件
  gc_creation_date_format   CONSTANT VARCHAR2(21) := 'YYYY/MM/DD HH24:MI:SS' ; -- 作成日時日付型フォーマット
  gc_rtn_date_format        CONSTANT VARCHAR2(19) := 'YYYY/MM/DD' ;            -- 返品日時日付型フォーマット
  -- エラーコード
  gc_application          CONSTANT VARCHAR2(5)  := 'XXPO' ;            -- アプリケーション
  gc_err_code_data_0      CONSTANT VARCHAR2(15) := 'APP-XXPO-00009' ;  -- データ０件メッセージ
  gc_err_code_no_data     CONSTANT VARCHAR2(15) := 'APP-XXPO-10026' ;  -- データ未取得メッセージ
  gc_err_code_type_chk    CONSTANT VARCHAR2(15) := 'APP-XXPO-10034' ;  -- 型チェックエラーメッセージ
  gc_note_code_in_param   CONSTANT VARCHAR2(15) := 'APP-XXPO-30022' ;  -- パラメータ受取
  gc_note_code_tax_info   CONSTANT VARCHAR2(15) := 'APP-XXPO-30034' ;  -- 単価消費税文言
  --パラメータ出力用
  gc_rtn_number           CONSTANT VARCHAR2(15) := '返品番号' ;
  gc_dept_code            CONSTANT VARCHAR2(15) := '担当部署' ;
  gc_tantousya_code       CONSTANT VARCHAR2(15) := '担当者' ;
  gc_creation_date_from   CONSTANT VARCHAR2(15) := '作成日時FROM' ;
  gc_creation_date_to     CONSTANT VARCHAR2(15) := '作成日時TO' ;
  gc_vendor_code          CONSTANT VARCHAR2(15) := '取引先' ;
  gc_assen_code           CONSTANT VARCHAR2(15) := '斡旋者' ;
  gc_location_code        CONSTANT VARCHAR2(15) := '納入先' ;
  gc_rtn_date_from        CONSTANT VARCHAR2(15) := '返品日FROM' ;
  gc_rtn_date_to          CONSTANT VARCHAR2(15) := '返品日TO' ;
  gc_prod_div             CONSTANT VARCHAR2(15) := '商品区分' ;
  gc_item_div             CONSTANT VARCHAR2(15) := '品目区分' ;
  gc_tag_type_t           CONSTANT VARCHAR2(1)  := 'T' ;
  gc_tag_type_d           CONSTANT VARCHAR2(1)  := 'D' ;
  --メッセージ用
  gc_msg_param            CONSTANT VARCHAR2(5)  := 'PARAM' ;
  gc_msg_format           CONSTANT VARCHAR2(6)  := 'FORMAT' ;
  gc_msg_table            CONSTANT VARCHAR2(5)  := 'TABLE' ;
  gc_msg_data             CONSTANT VARCHAR2(4)  := 'DATA';
  gc_table_name           CONSTANT VARCHAR2(20) := '受入返品実績';
-- 08/05/02 Y.Yamamoto ADD v1.3 Start
  --クイックコード用
  gc_kousen_type          CONSTANT VARCHAR2(16) := 'XXPO_KOUSEN_TYPE';  -- クイックコード(口銭区分)
  gc_fukakin_type         CONSTANT VARCHAR2(17) := 'XXPO_FUKAKIN_TYPE'; -- クイックコード(賦課金区分)
-- 08/05/02 Y.Yamamoto ADD v1.3 End
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  -- 入力パラメータ格納用レコード変数
  TYPE rec_param_data  IS RECORD
    (
     rtn_number          xxpo_rcv_and_rtn_txns.rcv_rtn_number%TYPE    -- 返品番号
     ,dept_code          xxcmn_locations_v.location_code%TYPE         -- 担当部署
     ,tantousya_code     per_all_people_f.employee_number%TYPE        -- 担当者
     ,creation_date_from VARCHAR2(19)                                 -- 作成日時FROM
     ,creation_date_to   VARCHAR2(19)                                 -- 作成日時TO
     ,vendor_code        xxpo_rcv_and_rtn_txns.vendor_code%TYPE       -- 取引先
     ,assen_code         xxpo_rcv_and_rtn_txns.assen_vendor_code%TYPE -- 斡旋者
     ,location_code      xxpo_rcv_and_rtn_txns.location_code%TYPE     -- 納入先
     ,rtn_date_from      VARCHAR2(19)                                 -- 返品日FROM
     ,rtn_date_to        VARCHAR2(19)                                 -- 返品日TO
     ,prod_div           xxpo_categories_v.category_code%TYPE         -- 商品区分
     ,item_div           xxpo_categories_v.category_code%TYPE         -- 品目区分
    ) ;
  -- 返品指示書データ格納用レコード変数
  TYPE rec_data_type_dtl  IS RECORD
    (
    rtn_number              xxpo_rcv_and_rtn_txns.rcv_rtn_number%TYPE               --受入返品番号
    ,vendor_code            xxpo_rcv_and_rtn_txns.vendor_code%TYPE                  --取引先コード
    ,vendor_id              xxpo_rcv_and_rtn_txns.vendor_id%TYPE                    --取引先ID
    ,verndor_name           xxcmn_vendors2_v.vendor_full_name%TYPE                  --取引先名称(正式名)
    ,assen_code             xxpo_rcv_and_rtn_txns.assen_vendor_code%TYPE            --斡旋者コード
    ,assen_name             xxcmn_vendors2_v.vendor_full_name%TYPE                  --斡旋者名称(正式名)
    ,location_code          xxpo_rcv_and_rtn_txns.location_code%TYPE                --入出庫先コード
    ,location_name          xxcmn_item_locations2_V.description%TYPE                --保管場所名
    ,rtn_date               xxpo_rcv_and_rtn_txns.txns_date%TYPE                    --取引日
    ,header_desc            xxpo_rcv_and_rtn_txns.header_description%TYPE           --ヘッダ摘要
    ,dept_code              xxpo_rcv_and_rtn_txns.department_code%TYPE              --担当部署コード
    ,item_code              xxpo_rcv_and_rtn_txns.item_code%TYPE                    --品目
    ,futai_code             xxpo_rcv_and_rtn_txns.futai_code%TYPE                   --付帯コード
    ,item_name              xxcmn_item_mst2_v.item_name%TYPE                        --品目名
    ,stock_quant            ic_lots_mst.attribute6%TYPE                             --在庫入数
-- 08/05/02 Y.Yamamoto ADD v1.4 Start
    ,quantity               xxpo_rcv_and_rtn_txns.quantity%TYPE                     --数量
-- 08/05/02 Y.Yamamoto ADD v1.4 End
    ,rtn_quant              xxpo_rcv_and_rtn_txns.rcv_rtn_quantity%TYPE             --受入返品数量
    ,rtn_uom                xxpo_rcv_and_rtn_txns.rcv_rtn_uom%TYPE                  --受入返品単位
    ,rtn_unit_price         xxpo_rcv_and_rtn_txns.unit_price%TYPE                   --単価
    ,lot_number             xxpo_rcv_and_rtn_txns.lot_number%TYPE                   --ロットNo
    ,make_date              ic_lots_mst.attribute1%TYPE                             --製造年月日
    ,limit_date             ic_lots_mst.attribute3%TYPE                             --賞味期限
    ,lot_sign               ic_lots_mst.attribute2%TYPE                             --固有記号
    ,factory_code           xxpo_rcv_and_rtn_txns.factory_code%TYPE                 --工場コード
    ,delivery_code          xxpo_rcv_and_rtn_txns.delivery_code%TYPE                --配送先コード
    ,factory_name           xxcmn_vendors2_v.vendor_short_name%TYPE                 --工場名
    ,delivery_name          xxcmn_vendors2_v.vendor_short_name%TYPE                 --配送先名
    ,stocking_type          ic_lots_mst.attribute9%TYPE                             --仕入形態
    ,nendo                  ic_lots_mst.attribute11%TYPE                            --年度
    ,reaf_devision          ic_lots_mst.attribute10%TYPE                            --茶期区分
    ,home                   ic_lots_mst.attribute12%TYPE                            --産地
    ,pack_type              ic_lots_mst.attribute13%TYPE                            --タイプ
    ,rank1                  ic_lots_mst.attribute14%TYPE                            --ランク１
    ,rank2                  ic_lots_mst.attribute15%TYPE                            --ランク２
    ,rank3                  ic_lots_mst.attribute19%TYPE                            --ランク３
    ,line_desc              xxpo_rcv_and_rtn_txns.line_description%TYPE             --明細摘要
    ,kobiki_rate            xxpo_rcv_and_rtn_txns.kobiki_rate%TYPE                  --粉引率
    ,kousen_type            xxpo_rcv_and_rtn_txns.kousen_type%TYPE                  --口銭区分
    ,fukakin_type           xxpo_rcv_and_rtn_txns.fukakin_type%TYPE                 --賦課金区分
    ,kobiki_unt_price       xxpo_rcv_and_rtn_txns.kobki_converted_unit_price%TYPE   --粉引後単価
    ,kousen_unt_price       xxpo_rcv_and_rtn_txns.kousen_rate_or_unit_price%TYPE    --口銭
    ,fukakin_unt_price      xxpo_rcv_and_rtn_txns.fukakin_rate_or_unit_price%TYPE   --賦課金
    ,kobiki_price           xxpo_rcv_and_rtn_txns.kobki_converted_price%TYPE        --粉引後金額
    ,kousen_price           xxpo_rcv_and_rtn_txns.kousen_price%TYPE                 --預り口銭金額
    ,fukakin_price          xxpo_rcv_and_rtn_txns.fukakin_price%TYPE                --賦課金額
    ,drop_ship_type         xxpo_rcv_and_rtn_txns.drop_ship_type%TYPE               --直送区分
    ) ;
  TYPE tab_data_type_dtl IS TABLE OF rec_data_type_dtl INDEX BY BINARY_INTEGER ;
  TYPE dtl_cnt_map IS TABLE OF NUMBER INDEX BY VARCHAR2(30) ;  -- 作業用数値型配列
--
  gt_main_data              tab_data_type_dtl ;       -- 取得レコード表
  gt_xml_data_table         XML_DATA ;                -- ＸＭＬデータタグ表
  gl_xml_idx                NUMBER ;                  -- ＸＭＬデータタグ表のインデックス
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
  /**********************************************************************************
   * Function Name    : func_rank_edit
   * Description      : ランク１・ランク２・ランク３を編集・結合 B-4
   *                    EX ) R1(ランク１)－R2(ランク２）－R3（ランク３)
   ***********************************************************************************/
  FUNCTION func_rank_edit
    (
      iv_rank1         IN VARCHAR2   -- ランク１
     ,iv_rank2         IN VARCHAR2   -- ランク２
     ,iv_rank3         IN VARCHAR2   -- ランク３
    ) RETURN VARCHAR2
  IS
    -- =====================================================
    -- 固定ローカル定数
    -- =====================================================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'func_rank_edit' ;   -- プログラム名
--
    -- =====================================================
    -- ユーザー宣言部
    -- =====================================================
    -- *** ローカル定数 ***
    cv_blank       CONSTANT VARCHAR2(1) :=' ';
    cv_hyphen      CONSTANT VARCHAR2(1) :='-';
    -- *** ローカル変数 ***
    ov_edit_data         VARCHAR2(32) ;
--
  BEGIN
--
    -- ランク１:NULLの場合：半角ﾌﾞﾗﾝｸ
    IF (iv_rank1 IS NULL) THEN
      ov_edit_data := cv_blank ;
    ELSE
      ov_edit_data := iv_rank1 ;
    END IF ;
    -- ﾊｲﾌﾝ挿入
    ov_edit_data := ov_edit_data || cv_hyphen ;
    -- ランク２:NULLの場合：半角ﾌﾞﾗﾝｸ
    IF (iv_rank2 IS NULL) THEN
      ov_edit_data := ov_edit_data || cv_blank ;
    ELSE
      ov_edit_data := ov_edit_data || iv_rank2 ;
    END IF ;
    -- ﾊｲﾌﾝ挿入
    ov_edit_data   := ov_edit_data || cv_hyphen ;
    -- ランク３:NULLの場合：半角ﾌﾞﾗﾝｸ
    IF (iv_rank3 IS NULL) THEN
      ov_edit_data := ov_edit_data || cv_blank ;
    ELSE
      ov_edit_data := ov_edit_data || iv_rank3 ;
    END IF ;
    RETURN(ov_edit_data) ;
--
  END func_rank_edit ;
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
    -- *** ローカル変数 ***
    lv_convert_data VARCHAR2(2000);
--
  BEGIN
--
    --データの場合
    IF (ic_type = gc_tag_type_d) THEN
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
   * Function Name    : func_dtl_cnt
   * Description      : 明細件数配列作成
   ***********************************************************************************/
  FUNCTION func_dtl_cnt(
    it_dtl_data  IN tab_data_type_dtl
  )RETURN dtl_cnt_map
  IS
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'func_dtl_cnt'; -- プログラム名
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル変数 ***
    -- 明細件数カウンタ
    lv_dtl_cnt NUMBER := 1;
    -- カウンタ格納用テーブル型変数
    ot_dtl_cnt_map dtl_cnt_map ;
--
  BEGIN
--
    -- 引数読込処理
    <<dtl_data_loop>>
    FOR i in 1..it_dtl_data.count LOOP
      IF (NOT(it_dtl_data.EXISTS(i+1))) THEN
        -- 明細件数カウンタ値をインデックス：返品Noの構造体へ格納
        ot_dtl_cnt_map(it_dtl_data(i).rtn_number) := lv_dtl_cnt;
      ELSIF (it_dtl_data(i).rtn_number <> it_dtl_data(i+1).rtn_number) THEN
        -- 明細件数カウンタ値をインデックス：返品Noの構造体へ格納
        ot_dtl_cnt_map(it_dtl_data(i).rtn_number) := lv_dtl_cnt;
        -- 明細件数カウンタ初期化
        lv_dtl_cnt := 1 ;
      ELSE
        -- 明細件数インクリメント
        lv_dtl_cnt := lv_dtl_cnt + 1;
      END IF ;
    END LOOP dtl_data_loop;
--
    RETURN ot_dtl_cnt_map ;
--
  END func_dtl_cnt;
--
   /**********************************************************************************
   * Procedure Name   : prc_check_param_info
   * Description      : パラメータチェック(B-1)
   ***********************************************************************************/
  PROCEDURE prc_check_param_info
    (
      ir_param      IN     rec_param_data       -- 01.入力パラメータ群
     ,ov_errbuf     OUT NOCOPY VARCHAR2         -- エラー・メッセージ
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
    ln_ret_date                DATE ;        -- 共通関数戻り値：数値型
    lv_err_code               VARCHAR2(100) ; -- エラーコード格納用
    lv_msg_param_value        VARCHAR2(15);
    lv_msg_format_value       VARCHAR2(21);
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
    -- パラメータ受取出力
    -- ====================================================
    --パラメータ出力
    -- 返品番号
    FND_FILE.PUT_LINE(FND_FILE.LOG
                      ,xxcmn_common_pkg.get_msg(
                               gc_application
                               ,gc_note_code_in_param
                               ,gc_msg_param
                               ,gc_rtn_number
                               ,gc_msg_data
                               ,ir_param.rtn_number));
    -- 担当部署
    FND_FILE.PUT_LINE(FND_FILE.LOG
                      ,xxcmn_common_pkg.get_msg(
                               gc_application
                               ,gc_note_code_in_param
                               ,gc_msg_param
                               ,gc_dept_code
                               ,gc_msg_data
                               ,ir_param.dept_code));
    -- 担当者
    FND_FILE.PUT_LINE(FND_FILE.LOG
                      ,xxcmn_common_pkg.get_msg(
                               gc_application
                               ,gc_note_code_in_param
                               ,gc_msg_param
                               ,gc_tantousya_code
                               ,gc_msg_data
                               ,ir_param.tantousya_code));
     -- 作成日時FROM
    FND_FILE.PUT_LINE(FND_FILE.LOG
                      ,xxcmn_common_pkg.get_msg(
                               gc_application
                               ,gc_note_code_in_param
                               ,gc_msg_param
                               ,gc_creation_date_from
                               ,gc_msg_data
                               ,ir_param.creation_date_from));
    -- 作成日時TO
    FND_FILE.PUT_LINE(FND_FILE.LOG
                      ,xxcmn_common_pkg.get_msg(
                               gc_application
                               ,gc_note_code_in_param
                               ,gc_msg_param
                               ,gc_creation_date_to
                               ,gc_msg_data
                               ,ir_param.creation_date_to));
    -- 取引先
    FND_FILE.PUT_LINE(FND_FILE.LOG
                      ,xxcmn_common_pkg.get_msg(
                               gc_application
                               ,gc_note_code_in_param
                               ,gc_msg_param
                               ,gc_vendor_code
                               ,gc_msg_data
                               ,ir_param.vendor_code));
    -- 斡旋者
    FND_FILE.PUT_LINE(FND_FILE.LOG
                      ,xxcmn_common_pkg.get_msg(
                               gc_application
                               ,gc_note_code_in_param
                               ,gc_msg_param
                               ,gc_assen_code
                               ,gc_msg_data
                               ,ir_param.assen_code));
    -- 納入先
    FND_FILE.PUT_LINE(FND_FILE.LOG
                      ,xxcmn_common_pkg.get_msg(
                               gc_application
                               ,gc_note_code_in_param
                               ,gc_msg_param
                               ,gc_location_code
                               ,gc_msg_data
                               ,ir_param.location_code));
    -- 返品日FROM
    FND_FILE.PUT_LINE(FND_FILE.LOG
                      ,xxcmn_common_pkg.get_msg(
                               gc_application
                               ,gc_note_code_in_param
                               ,gc_msg_param
                               ,gc_rtn_date_from
                               ,gc_msg_data
                               ,ir_param.rtn_date_from));
    -- 返品日TO
    FND_FILE.PUT_LINE(FND_FILE.LOG
                      ,xxcmn_common_pkg.get_msg(
                               gc_application
                               ,gc_note_code_in_param
                               ,gc_msg_param
                               ,gc_rtn_date_to
                               ,gc_msg_data
                               ,ir_param.rtn_date_to));
    -- 商品区分
    FND_FILE.PUT_LINE(FND_FILE.LOG
                      ,xxcmn_common_pkg.get_msg(
                               gc_application
                               ,gc_note_code_in_param
                               ,gc_msg_param
                               ,gc_prod_div
                               ,gc_msg_data
                               ,ir_param.prod_div));
    -- 品目区分
    FND_FILE.PUT_LINE(FND_FILE.LOG
                      ,xxcmn_common_pkg.get_msg(
                               gc_application
                               ,gc_note_code_in_param
                               ,gc_msg_param
                               ,gc_item_div
                               ,gc_msg_data
                               ,ir_param.item_div));
    -- ====================================================
    -- 日付変換チェック
    -- ====================================================
    -- 日付変換(YYYY/MM/DD)チェック
    -- 返品日FROM
    IF ( ir_param.rtn_date_from IS NOT NULL ) THEN
      ln_ret_date := FND_DATE.STRING_TO_DATE(
                                         ir_param.rtn_date_from
                                         ,gc_rtn_date_format
                                         );
      IF ( ln_ret_date IS NULL ) THEN
        lv_err_code := gc_err_code_type_chk ;
        lv_msg_param_value  := gc_rtn_date_from ;
        lv_msg_format_value := gc_rtn_date_format;
        RAISE parameter_check_expt ;
      END IF ;
    END IF;
    -- 返品日TO
    IF ( ir_param.rtn_date_to IS NOT NULL ) THEN
      ln_ret_date := FND_DATE.STRING_TO_DATE(
                                            ir_param.rtn_date_to
                                            ,gc_rtn_date_format
                                            );
      IF ( ln_ret_date IS NULL ) THEN
        lv_err_code := gc_err_code_type_chk ;
        lv_msg_param_value  := gc_rtn_date_to ;
        lv_msg_format_value := gc_rtn_date_format;
        RAISE parameter_check_expt ;
      END IF ;
    END IF ;
    -- 日付変換(YYYY/MM/DD HH24:MI:SS)チェック
    -- 作成日時FROM
    IF ( ir_param.creation_date_from IS NOT NULL ) THEN
      ln_ret_date := FND_DATE.STRING_TO_DATE(
                                            ir_param.creation_date_from
                                            ,gc_creation_date_format
                                           );
      IF ( ln_ret_date IS NULL ) THEN
        lv_err_code := gc_err_code_type_chk ;
        lv_msg_param_value  := gc_creation_date_from ;
        lv_msg_format_value := gc_creation_date_format;
        RAISE parameter_check_expt ;
      END IF ;
    END IF;
    -- 作成日時TO
    IF ( ir_param.creation_date_to IS NOT NULL ) THEN
      ln_ret_date := FND_DATE.STRING_TO_DATE(
                                            ir_param.creation_date_to
                                            ,gc_creation_date_format
                                           );
      IF ( ln_ret_date IS NULL ) THEN
        lv_err_code := gc_err_code_type_chk ;
        lv_msg_param_value  := gc_creation_date_to ;
        lv_msg_format_value := gc_creation_date_format;
        RAISE parameter_check_expt ;
      END IF ;
    END IF ;
--
  EXCEPTION
    --*** パラメータチェック例外 ***
    WHEN parameter_check_expt THEN
      -- メッセージセット
      lv_errmsg := xxcmn_common_pkg.get_msg( gc_application
                                            ,lv_err_code
                                            ,gc_msg_param
                                            ,lv_msg_param_value
                                            ,gc_msg_format
                                            ,lv_msg_format_value
                                            ) ;
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
   * Procedure Name   : prc_get_report_data
   * Description      : 明細データ取得(B-3)
   ***********************************************************************************/
  PROCEDURE prc_get_report_data
    (
      ir_param      IN  rec_param_data            -- 01.入力パラメータ群
     ,ot_data_rec   OUT NOCOPY tab_data_type_dtl  -- 02.取得レコード群
     ,ov_errbuf     OUT NOCOPY VARCHAR2           -- エラー・メッセージ
     ,ov_retcode    OUT NOCOPY VARCHAR2           -- リターン・コード
     ,ov_errmsg     OUT NOCOPY VARCHAR2           -- ユーザー・エラー・メッセージ
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
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル・定数 ***
    cv_sc CONSTANT VARCHAR2(2) := '''';
    -- *** ローカル・変数 ***
    lv_sql_body    VARCHAR2(10000);
--
  BEGIN
--
    lv_sql_body := lv_sql_body || 'SELECT xrcart.rcv_rtn_number AS rtn_number';  -- 受入返品番号
    lv_sql_body := lv_sql_body || ',xrcart.vendor_code AS vendor_code';          -- 取引先コード
    lv_sql_body := lv_sql_body || ',xrcart.vendor_id AS vendor_id';              -- 取引先ID
    lv_sql_body := lv_sql_body || ',xvv1.vendor_full_name AS verndor_name';      -- 取引先名称(正式名)
    lv_sql_body := lv_sql_body || ',xrcart.assen_vendor_code AS assen_code';     -- 斡旋者コード
    lv_sql_body := lv_sql_body || ',xvv2.vendor_full_name AS assen_name';        -- 斡旋者名称(正式名)
    lv_sql_body := lv_sql_body || ',xrcart.location_code AS location_code';      -- 入出庫先コード
    lv_sql_body := lv_sql_body || ',xilv.description AS location_name';          -- 保管場所名
    lv_sql_body := lv_sql_body || ',xrcart.txns_date AS rtn_date';               -- 取引日
    lv_sql_body := lv_sql_body || ',xrcart.header_description AS header_desc';   -- ヘッダ摘要
    lv_sql_body := lv_sql_body || ',xrcart.department_code AS dept_code';        -- 担当部署コード
    lv_sql_body := lv_sql_body || ',xrcart.item_code AS item_code';              -- 品目
    lv_sql_body := lv_sql_body || ',xrcart.futai_code AS futai_code';            -- 付帯コード
    lv_sql_body := lv_sql_body || ',ximv.item_name AS item_name';                -- 正式名
    lv_sql_body := lv_sql_body || ',xrcart.conversion_factor AS stock_quant';    -- 在庫入数(換算入数)
-- 08/05/02 Y.Yamamoto ADD v1.4 Start
    lv_sql_body := lv_sql_body || ',xrcart.quantity AS quantity';                -- 数量
-- 08/05/02 Y.Yamamoto ADD v1.4 End
    lv_sql_body := lv_sql_body || ',xrcart.rcv_rtn_quantity AS rtn_quant';       -- 受入返品数量
    lv_sql_body := lv_sql_body || ',xrcart.rcv_rtn_uom AS rtn_uom';              -- 受入返品単位
    lv_sql_body := lv_sql_body || ',xrcart.unit_price AS rtn_unit_price';        -- 単価
    lv_sql_body := lv_sql_body || ',xrcart.lot_number AS lot_number';            -- ロットNo
    lv_sql_body := lv_sql_body || ',ilm.attribute1 AS make_date';                -- 製造年月日
    lv_sql_body := lv_sql_body || ',ilm.attribute3 AS limit_date';               -- 賞味期限
    lv_sql_body := lv_sql_body || ',ilm.attribute2 AS lot_sign';                 -- 固有記号
    lv_sql_body := lv_sql_body || ',xrcart.factory_code  AS factory_code';       -- 工場コード
    lv_sql_body := lv_sql_body || ',xrcart.delivery_code AS delivery_code';      -- 配送先コード
    lv_sql_body := lv_sql_body || ',xvsv1.vendor_site_short_name AS factory_name';     -- 略称
    lv_sql_body := lv_sql_body || ',xvsv2.vendor_site_short_name AS delivery_name';    -- 略称
    lv_sql_body := lv_sql_body || ',ilm.attribute9 AS stocking_type';      -- 仕入形態
    lv_sql_body := lv_sql_body || ',ilm.attribute11 AS nendo';             -- 年度
    lv_sql_body := lv_sql_body || ',ilm.attribute10 AS reaf_devision';     -- 茶期区分
    lv_sql_body := lv_sql_body || ',ilm.attribute12 AS home';              -- 産地
    lv_sql_body := lv_sql_body || ',ilm.attribute13 AS pack_type';         -- タイプ
    lv_sql_body := lv_sql_body || ',ilm.attribute14 AS rank1';             -- ランク１
    lv_sql_body := lv_sql_body || ',ilm.attribute15 AS rank2';             -- ランク２
    lv_sql_body := lv_sql_body || ',ilm.attribute19 AS rank3';             -- ランク３
    lv_sql_body := lv_sql_body || ',xrcart.line_description AS line_desc'; -- 明細摘要
    lv_sql_body := lv_sql_body || ',xrcart.kobiki_rate AS kobiki_rate';    -- 粉引率
-- 08/05/02 Y.Yamamoto Update v1.3 Start
--    lv_sql_body := lv_sql_body || ',xrcart.kousen_type AS kousen_type';    -- 口銭区分
--    lv_sql_body := lv_sql_body || ',xrcart.fukakin_type AS fukakin_type';  -- 賦課金区分
    lv_sql_body := lv_sql_body || ',xlvv1.meaning AS kousen_type';         -- 口銭区分名称
    lv_sql_body := lv_sql_body || ',xlvv2.meaning AS fukakin_type';        -- 賦課金区分名称
-- 08/05/02 Y.Yamamoto Update v1.3 End
    lv_sql_body := lv_sql_body || ',xrcart.kobki_converted_unit_price AS kobiki_unt_price';     -- 粉引後単価
    lv_sql_body := lv_sql_body || ',xrcart.kousen_rate_or_unit_price AS kousen_unt_price';      -- 口銭
    lv_sql_body := lv_sql_body || ',xrcart.fukakin_rate_or_unit_price AS fukakin_unt_price';    -- 賦課金
    lv_sql_body := lv_sql_body || ',xrcart.kobki_converted_price AS kobiki_price';  -- 粉引後金額
    lv_sql_body := lv_sql_body || ',xrcart.kousen_price AS kousen_price';           -- 預り口銭金額
    lv_sql_body := lv_sql_body || ',xrcart.fukakin_price AS fukakin_price';         -- 賦課金額
    lv_sql_body := lv_sql_body || ',xrcart.drop_ship_type AS drop_ship_type';       -- 直送区分
    ---------------------------------------------------------------------------------------
    -- FROM句
    lv_sql_body := lv_sql_body || ' FROM xxpo_rcv_and_rtn_txns xrcart'; -- 受入返品実績（アドオン）
    lv_sql_body := lv_sql_body || ',xxpo_categories_v xcv1';            -- XXPOカテゴリ情報VIEW(商品分類)
    lv_sql_body := lv_sql_body || ',xxpo_categories_v xcv2';            -- XXPOカテゴリ情報VIEW(品目分類)
    lv_sql_body := lv_sql_body || ',gmi_item_categories gic1';         -- OPM品目カテゴリ割当(商品分類)
    lv_sql_body := lv_sql_body || ',gmi_item_categories gic2';         -- OPM品目カテゴリ割当(品目分類)
    lv_sql_body := lv_sql_body || ',ic_lots_mst ilm';                  -- OPMロットマスタ
    lv_sql_body := lv_sql_body || ',xxcmn_item_mst2_v ximv';           -- OPM品目情報VIEW
    lv_sql_body := lv_sql_body || ',xxcmn_item_locations2_v xilv';     -- OPM保管場所情報VIEW
    lv_sql_body := lv_sql_body || ',xxcmn_vendors2_v xvv1';            -- 仕入先情報VIEW(取引先名称)
    lv_sql_body := lv_sql_body || ',xxcmn_vendors2_v xvv2';            -- 仕入先情報VIEW(斡旋者名称)
    lv_sql_body := lv_sql_body || ',xxcmn_vendor_sites2_v xvsv1';      -- 仕入先サイト情報VIEW(工場名称)
    lv_sql_body := lv_sql_body || ',xxcmn_vendor_sites2_v xvsv2';      -- 仕入先サイト情報VIEW(配送先名称)
    lv_sql_body := lv_sql_body || ',per_all_people_f papf';            -- 従業員マスタ
    lv_sql_body := lv_sql_body || ',fnd_user fu';                      -- ログインユーザマスタ
-- 08/05/02 Y.Yamamoto ADD v1.3 Start
    lv_sql_body := lv_sql_body || ',xxcmn_lookup_values2_v xlvv1';     -- クイックコード(口銭区分)
    lv_sql_body := lv_sql_body || ',xxcmn_lookup_values2_v xlvv2';     -- クイックコード(賦課金区分)
-- 08/05/02 Y.Yamamoto ADD v1.3 End
    ---------------------------------------------------------------------------------------
    -- WHERE句
    -- OPMロットマスタ結合
    lv_sql_body := lv_sql_body || ' WHERE ilm.item_id(+) = xrcart.item_id';
    lv_sql_body := lv_sql_body || ' AND ilm.lot_id(+) = xrcart.lot_id';
    -- OPM品目情報VIEW2結合
    lv_sql_body := lv_sql_body || ' AND ximv.item_id = xrcart.item_id';
    lv_sql_body := lv_sql_body || ' AND xrcart.txns_date BETWEEN ximv.start_date_active
                                                         AND ximv.end_date_active';
    -- OPM保管場所情報VIEW2結合
    lv_sql_body := lv_sql_body || ' AND xilv.inventory_location_id = xrcart.location_id';
    lv_sql_body := lv_sql_body || ' AND xrcart.txns_date >= xilv.date_from';
    lv_sql_body := lv_sql_body || ' AND xrcart.txns_date <= NVL(xilv.date_to,xrcart.txns_date )';
    lv_sql_body := lv_sql_body || ' AND xrcart.txns_date <= NVL(xilv.disable_date,xrcart.txns_date)';
    -- OPM品目カテゴリ割当(品目区分)結合
    lv_sql_body := lv_sql_body || ' AND xrcart.item_id         = gic2.item_id';
    lv_sql_body := lv_sql_body || ' AND xcv2.category_set_id   = gic2.category_set_id';
    lv_sql_body := lv_sql_body || ' AND xcv2.category_id       = gic2.category_id';
    lv_sql_body := lv_sql_body || ' AND xcv2.category_set_name =' || cv_sc || gc_category_name_item || cv_sc;
    lv_sql_body := lv_sql_body || ' AND xrcart.txns_date <= NVL(xcv2.disable_date, xrcart.txns_date )';
    -- OPM品目カテゴリ割当(商品区分)結合
    lv_sql_body := lv_sql_body || ' AND xrcart.item_id         = gic1.item_id';
    lv_sql_body := lv_sql_body || ' AND xcv1.category_set_id   = gic1.category_set_id';
    lv_sql_body := lv_sql_body || ' AND xcv1.category_id       = gic1.category_id';
    lv_sql_body := lv_sql_body || ' AND xcv1.category_set_name ='|| cv_sc || gc_category_name_prod || cv_sc ;
    lv_sql_body := lv_sql_body || ' AND xrcart.txns_date <= NVL(xcv1.disable_date, xrcart.txns_date )';
    -- 取引先名称取得結合
    lv_sql_body := lv_sql_body || ' AND xvv1.vendor_id = xrcart.vendor_id';
    lv_sql_body := lv_sql_body || ' AND xrcart.txns_date >= xvv1.start_date_active';
    lv_sql_body := lv_sql_body || ' AND xrcart.txns_date <= NVL(xvv1.end_date_active, xrcart.txns_date )';
    -- 斡旋者名称取得結合
-- 08/05/01 Y.Yamamoto Update v1.2 Start
--    lv_sql_body := lv_sql_body || ' AND xvv2.vendor_id = xrcart.assen_vendor_id';
--    lv_sql_body := lv_sql_body || ' AND xrcart.txns_date >= xvv2.start_date_active';
--    lv_sql_body := lv_sql_body || ' AND xrcart.txns_date <= NVL(xvv2.end_date_active, xrcart.txns_date )';
    lv_sql_body := lv_sql_body || ' AND xvv2.vendor_id(+) = xrcart.assen_vendor_id';
    lv_sql_body := lv_sql_body || ' AND xrcart.txns_date >= xvv2.start_date_active(+)';
    lv_sql_body := lv_sql_body || ' AND xrcart.txns_date <= NVL(xvv2.end_date_active(+), xrcart.txns_date )';
-- 08/05/01 Y.Yamamoto Update v1.2 End
    -- 工場名称取得結合
    lv_sql_body := lv_sql_body || ' AND xvsv1.vendor_id = xrcart.vendor_id';
    lv_sql_body := lv_sql_body || ' AND xvsv1.vendor_site_code = xrcart.factory_code';
    lv_sql_body := lv_sql_body || ' AND xrcart.txns_date >= xvsv1.start_date_active';
    lv_sql_body := lv_sql_body || ' AND xrcart.txns_date <= NVL(xvsv1.end_date_active, xrcart.txns_date )';
    -- 配送先名称取得結合
    lv_sql_body := lv_sql_body || ' AND xvsv2.vendor_id(+) = xrcart.vendor_id';
    lv_sql_body := lv_sql_body || ' AND xvsv2.vendor_site_code(+) = xrcart.delivery_code';
    lv_sql_body := lv_sql_body || ' AND xrcart.txns_date >= xvsv2.start_date_active(+)';
    lv_sql_body := lv_sql_body || ' AND xrcart.txns_date <= NVL(xvsv2.end_date_active(+), xrcart.txns_date)';
    -- 従業員マスタ結合
    lv_sql_body := lv_sql_body || ' AND papf.person_id    = fu.employee_id';
    lv_sql_body := lv_sql_body || ' AND xrcart.txns_date >= papf.effective_start_date';
    lv_sql_body := lv_sql_body || ' AND xrcart.txns_date <= papf.effective_end_date';
    -- 受入返品実績アドオン絞込
    lv_sql_body := lv_sql_body || ' AND xrcart.txns_type IN ('|| cv_sc || gc_txns_type_rtn_order  || cv_sc ||
                                                           ','|| cv_sc || gc_txns_type_rtn_noorder|| cv_sc || ')';
    lv_sql_body := lv_sql_body || ' AND xrcart.drop_ship_type IN ('|| cv_sc || gc_drop_ship_type_normal  || cv_sc ||
                                                                ','|| cv_sc || gc_drop_ship_type_sup_req || cv_sc ||')';
    lv_sql_body := lv_sql_body || ' AND xrcart.quantity <> ' || gc_rtn_quant_0;
    -- ユーザマスタ結合
    lv_sql_body := lv_sql_body || ' AND xrcart.created_by = fu.user_id';
-- 08/05/02 Y.Yamamoto ADD v1.3 Start
    -- クイックコード結合
    lv_sql_body := lv_sql_body || ' AND xlvv1.lookup_type = '|| cv_sc || gc_kousen_type|| cv_sc;
    lv_sql_body := lv_sql_body || ' AND xlvv1.lookup_code = xrcart.kousen_type';
    lv_sql_body := lv_sql_body || ' AND xrcart.txns_date >= xlvv1.start_date_active';
    lv_sql_body := lv_sql_body || ' AND xrcart.txns_date <= NVL(xlvv1.end_date_active, xrcart.txns_date )';
    lv_sql_body := lv_sql_body || ' AND xlvv2.lookup_type = '|| cv_sc || gc_fukakin_type|| cv_sc;
    lv_sql_body := lv_sql_body || ' AND xlvv2.lookup_code = xrcart.fukakin_type';
    lv_sql_body := lv_sql_body || ' AND xrcart.txns_date >= xlvv2.start_date_active';
    lv_sql_body := lv_sql_body || ' AND xrcart.txns_date <= NVL(xlvv2.end_date_active, xrcart.txns_date )';
-- 08/05/02 Y.Yamamoto ADD v1.3 End
    ---------------------------------------------------------------------------------------
    -- 受入返品実績（アドオン）のパラメーターによる絞込み条件
    -- 返品No
    IF (ir_param.rtn_number  IS NOT NULL) THEN
       lv_sql_body := lv_sql_body || ' AND xrcart.rcv_rtn_number = '
                                       || cv_sc || ir_param.rtn_number  || cv_sc;
    END IF ;
    -- 担当部署
    IF (ir_param.dept_code IS NOT NULL) THEN
      lv_sql_body := lv_sql_body || ' AND xrcart.department_code = '
                                      || cv_sc || ir_param.dept_code || cv_sc;
    END IF ;
    -- 担当者
    IF (ir_param.tantousya_code IS NOT NULL) THEN
      lv_sql_body := lv_sql_body || ' AND papf.employee_number= '
                                      || cv_sc || ir_param.tantousya_code || cv_sc;
    END IF ;
    -- 取引先
    IF (ir_param.vendor_code IS NOT NULL) THEN
      lv_sql_body := lv_sql_body || ' AND xrcart.vendor_code = '
                                      || cv_sc || ir_param.vendor_code || cv_sc;
    END IF ;
    -- 斡旋者
    IF (ir_param.assen_code IS NOT NULL) THEN
      lv_sql_body := lv_sql_body || ' AND xrcart.assen_vendor_code = '
                                      || cv_sc || ir_param.assen_code || cv_sc;
    END IF;
    -- 納入先
    IF (ir_param.location_code IS NOT NULL) THEN
      lv_sql_body := lv_sql_body || ' AND xrcart.location_code = '
                                      || cv_sc || ir_param.location_code || cv_sc;
    END IF ;
    -- 作成日TO
    IF (ir_param.creation_date_from  IS NOT NULL) THEN
      lv_sql_body := lv_sql_body || ' AND xrcart.creation_date >=
                                      (FND_DATE.STRING_TO_DATE('
                                      || cv_sc || ir_param.creation_date_from || cv_sc
                                      ||  ','
                                      || cv_sc ||gc_creation_date_format || cv_sc || '))';
    END IF ;
    -- 作成日TO
    IF (ir_param.creation_date_to IS NOT NULL) THEN
      lv_sql_body := lv_sql_body || ' AND xrcart.creation_date <=
                                      (FND_DATE.STRING_TO_DATE('
                                      || cv_sc || ir_param.creation_date_to || cv_sc
                                      ||  ','
                                      || cv_sc ||gc_creation_date_format || cv_sc || '))';
    END IF ;
    -- 返品日FROM
    IF (ir_param.rtn_date_from IS NOT NULL) THEN
      lv_sql_body := lv_sql_body || ' AND xrcart.txns_date >=
                                      (FND_DATE.STRING_TO_DATE('
                                      || cv_sc || ir_param.rtn_date_from || cv_sc
                                      ||  ','
                                      || cv_sc || gc_rtn_date_format || cv_sc ||'))';
    END IF ;
    -- 返品日TO
    IF (ir_param.rtn_date_to IS NOT NULL) THEN
      lv_sql_body := lv_sql_body || ' AND xrcart.txns_date <=
                                     FND_DATE.STRING_TO_DATE('
                                     || cv_sc || ir_param.rtn_date_to|| cv_sc
                                     ||  ','
                                     || cv_sc ||gc_rtn_date_format || cv_sc || ')';
    END IF ;
     -- 品目カテゴリ(商品区分)の絞込み条件の追加
    IF (ir_param.prod_div IS NOT NULL) THEN
      lv_sql_body := lv_sql_body || ' AND xcv1.category_code = '|| cv_sc || ir_param.prod_div || cv_sc;
    END IF ;
    -- 品目カテゴリ(品目区分)の絞込み条件の追加
    IF (ir_param.item_div IS NOT NULL) THEN
      lv_sql_body := lv_sql_body || ' AND xcv2.category_code = '|| cv_sc || ir_param.item_div || cv_sc;
    END IF ;
    -- ソート順
    lv_sql_body := lv_sql_body || ' ORDER BY rtn_number';          -- 受入返品番号
    lv_sql_body := lv_sql_body || ' ,vendor_code';                 -- 取引先コード
    lv_sql_body := lv_sql_body || ' ,assen_code';                  -- 斡旋者コード
    lv_sql_body := lv_sql_body || ' ,rtn_date';                    -- 取引日
    lv_sql_body := lv_sql_body || ' ,location_code';               -- 入出庫先コード
    lv_sql_body := lv_sql_body || ' ,xrcart.rcv_rtn_line_number';  -- 明細番号
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
  END prc_get_report_data ;
--
   /**********************************************************************************
   * Procedure Name   : prc_create_xml_data
   * Description      : ＸＭＬデータ作成(B-4)
   ***********************************************************************************/
  PROCEDURE prc_create_xml_data
    (
      iox_xml_data      IN OUT NOCOPY XML_DATA
     ,it_param_data     IN  tab_data_type_dtl -- 02.取得レコード群
     ,ov_errbuf         OUT NOCOPY VARCHAR2   -- エラー・メッセージ
     ,ov_retcode        OUT NOCOPY VARCHAR2   -- リターン・コード
     ,ov_errmsg         OUT NOCOPY VARCHAR2   -- ユーザー・エラー・メッセージ
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
    lv_rtn_price     NUMBER := 0 ;  -- 返品金額算7出用
    lv_sum_rtn_quant NUMBER := 0 ;  -- 合計返品数足し込み
    lv_sum_price     NUMBER := 0 ;  -- 合計金額足し込み
    lv_dtl_cnt       NUMBER := 0 ;  -- 返品No毎の明細件数
    lv_cnt           NUMBER := 1 ;  -- カウンタ
    -- 部署情報格納変数
    lv_dept_postal_code VARCHAR2(8)  ;  -- 郵便番号
    lv_dept_address     VARCHAR2(60) ;  -- 住所
    lv_dept_tel_num     VARCHAR2(15) ;  -- 電話番号
    lv_dept_fax_num     VARCHAR2(15) ;  -- FAX番号
    lv_dept_formal_name VARCHAR2(60) ;  -- 部署名
    -- 単価消費税文言格納
    lv_tax_info         VARCHAR2(150) ;
    -- 明細件数格納用
    lt_dtl_cnt_map      dtl_cnt_map ;
--
  BEGIN
--
    -- ----------------------------------------------------
    -- 初期処理
    -- ----------------------------------------------------
    -- 単価消費税文言取得
    lv_tax_info := xxcmn_common_pkg.get_msg(gc_application,gc_note_code_tax_info) ;
    -- 明細件数取得
    lt_dtl_cnt_map := func_dtl_cnt(it_param_data) ;
--
    -- ----------------------------------------------------
    -- 開始タグ
    -- ----------------------------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'root' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
    ------------------------------
    -- データ開始タグ
    ------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'datainfo' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
    ------------------------------
    -- 返品LＧ開始タグ
    ------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_rtn_info' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
    -- データ未取得の場合
    IF (it_param_data.count = 0) THEN
      ------------------------------
      -- 返品Ｇ開始タグ
      ------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'g_rtn' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
      -- 帳票ＩＤ
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'report_id' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
      gt_xml_data_table(gl_xml_idx).tag_value :=gc_report_id ;
      ------------------------------
      -- 明細ページLＧ開始タグ
      ------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_dtl_class_info' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
      ------------------------------
      -- 明細ページＧ開始タグ
      ------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'g_dtl_class' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
       -- データなしメッセージ
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'msg' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
      gt_xml_data_table(gl_xml_idx).tag_value := xxcmn_common_pkg.get_msg( gc_application
                                                 ,gc_err_code_data_0 ) ;
      ------------------------------
      -- 明細ページＧ終了タグ
      ------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := '/g_dtl_class' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
      ------------------------------
      -- 明細ページLＧ終了タグ
      ------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_dtl_class_info' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
      ------------------------------
      -- 返品Ｇ終了タグ
      ------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := '/g_rtn' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
      ------------------------------
      -- 返品LＧ終了タグ
      ------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_rtn_info' ;
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
      <<param_data_loop>>
      FOR i IN 1..it_param_data.count LOOP
        -- ----------------------------------------------------
        -- 算出処理
        -- ----------------------------------------------------
        -- 返品金額計算
        -- 粉引後単価設定有の場合
-- 08/05/02 Y.Yamamoto Update v1.4 Start
        IF (it_param_data(i).kobiki_unt_price IS NOT NULL ) THEN
--          lv_rtn_price := TRUNC((it_param_data(i).kobiki_unt_price * it_param_data(i).rtn_quant)
--                            -it_param_data(i).kousen_price -it_param_data(i).fukakin_price) ;
          lv_rtn_price := TRUNC((it_param_data(i).kobiki_unt_price * it_param_data(i).quantity)
                            -it_param_data(i).kousen_price -it_param_data(i).fukakin_price) ;
         -- 粉引後単価設定無の場合
        ELSE
--          lv_rtn_price := TRUNC((it_param_data(i).rtn_unit_price   * it_param_data(i).rtn_quant)
--                            -it_param_data(i).kousen_price -it_param_data(i).fukakin_price) ;
          lv_rtn_price := TRUNC((it_param_data(i).rtn_unit_price   * it_param_data(i).quantity)
                            -it_param_data(i).kousen_price -it_param_data(i).fukakin_price) ;
        END IF;
-- 08/05/02 Y.Yamamoto Update v1.4 End
        -- 合計返品数足し込み
        lv_sum_rtn_quant := lv_sum_rtn_quant + it_param_data(i).rtn_quant ;
        -- 合計金額足し込み
        lv_sum_price := lv_sum_price + lv_rtn_price ;
        -- セクション開始
        IF (lv_cnt = 1 )THEN
          -- セクション内への出力件数を取得
          lv_dtl_cnt := lt_dtl_cnt_map(it_param_data(i).rtn_number);
          -----------------------------------------
          -- セクション初期処理
          -----------------------------------------
          ------------------------------
          -- 返品Ｇ開始タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'g_rtn' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
          -- 帳票ＩＤ
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'report_id' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
          gt_xml_data_table(gl_xml_idx).tag_value :=gc_report_id ;
          -- 実行日
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'exec_date' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
          gt_xml_data_table(gl_xml_idx).tag_value :=TO_CHAR( SYSDATE, gc_creation_date_format ) ;
          -- 返品番号
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'rtn_num' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
          gt_xml_data_table(gl_xml_idx).tag_value :=it_param_data(i).rtn_number ;
          -- 取引先CD
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'ven_cd' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
          gt_xml_data_table(gl_xml_idx).tag_value := it_param_data(i).vendor_code ;
          -- 取引先名
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'ven_name' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
          gt_xml_data_table(gl_xml_idx).tag_value := it_param_data(i).verndor_name ;
          -- 斡旋者CD
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'assen_cd' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
          gt_xml_data_table(gl_xml_idx).tag_value := it_param_data(i).assen_code ;
          -- 斡旋社名
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'assen_name' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
          gt_xml_data_table(gl_xml_idx).tag_value := it_param_data(i).assen_name ;
          -- 出庫元CD
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'loc_id' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
          gt_xml_data_table(gl_xml_idx).tag_value := it_param_data(i).location_code ;
          -- 出庫元名
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'loc_name' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
          gt_xml_data_table(gl_xml_idx).tag_value := it_param_data(i).location_name ;
          -- 支払条件
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'pay_cond' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
          gt_xml_data_table(gl_xml_idx).tag_value := xxcmn_common_pkg.get_term_of_payment( it_param_data(i).vendor_id, '') ;
          -- 返品日
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'rtn_date' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
          gt_xml_data_table(gl_xml_idx).tag_value := TO_CHAR(it_param_data(i).rtn_date,gc_rtn_date_format) ;
          -- 摘要
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'rtn_desc' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
          gt_xml_data_table(gl_xml_idx).tag_value := it_param_data(i).header_desc ;
          --部署情報取得
          xxcmn_common_pkg.get_dept_info(
                        iv_dept_cd           => it_param_data(i).dept_code   -- 部署コード(事業所CD)
                        ,id_appl_date        => it_param_data(i).rtn_date    -- 返品日(基準日)
                        ,ov_postal_code      => lv_dept_postal_code          -- 郵便番号
                        ,ov_address          => lv_dept_address              -- 住所
                        ,ov_tel_num          => lv_dept_tel_num              -- 電話番号
                        ,ov_fax_num          => lv_dept_fax_num              -- FAX番号
                        ,ov_dept_formal_name => lv_dept_formal_name          -- 部署正式名
                        ,ov_errbuf           => lv_errbuf                    -- エラー・メッセージ
                        ,ov_retcode          => lv_retcode                   -- リターン・コード
                        ,ov_errmsg           => lv_errmsg                    -- ユーザー・エラー・メッセージ
                        );
--
          IF (lv_retcode = gv_status_error) THEN
            RAISE global_api_expt ;
          END IF ;
--
          -- 送付元住所
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'dep_addr' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
          gt_xml_data_table(gl_xml_idx).tag_value := lv_dept_address ;
          -- 送付元電話番号
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'dep_tel' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
          gt_xml_data_table(gl_xml_idx).tag_value := lv_dept_tel_num ;
          -- 送付元FAX番号
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'dep_fax' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
          gt_xml_data_table(gl_xml_idx).tag_value := lv_dept_fax_num ;
          -- 送付元部署名
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'dep_name' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
          gt_xml_data_table(gl_xml_idx).tag_value := lv_dept_formal_name;
          ------------------------------
          -- 明細ページLＧ開始タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_dtl_class_info' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
        END IF ;
        -- 明細のページ先頭データの場合
        IF (MOD(lv_cnt,6)=1) THEN
          ------------------------------
          -- 明細ページＧ開始タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'g_dtl_class' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
          ------------------------------
          -- 明細リストＧ開始タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_dtl_info' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
        END IF ;
        ------------------------------
        -- 明細Ｇ開始タグ
        ------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'g_dtl' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
        -- 品目（品目コード）
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'item_cd' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
        gt_xml_data_table(gl_xml_idx).tag_value := it_param_data(i).item_code ;
        -- 付帯
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'futai_cd' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
        gt_xml_data_table(gl_xml_idx).tag_value := it_param_data(i).futai_code ;
        -- 品目（品目名称）
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'item_name' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
        gt_xml_data_table(gl_xml_idx).tag_value := it_param_data(i).item_name ;
        -- 在庫入数
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'stock_quant' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
        gt_xml_data_table(gl_xml_idx).tag_value := it_param_data(i).stock_quant ;
        -- 返品数
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'rtn_quant' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
        gt_xml_data_table(gl_xml_idx).tag_value := it_param_data(i).rtn_quant ;
        -- 単位
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'rtn_uom' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
        gt_xml_data_table(gl_xml_idx).tag_value := it_param_data(i).rtn_uom ;
        -- 単価
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'rtn_unt_price' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
        gt_xml_data_table(gl_xml_idx).tag_value := it_param_data(i).rtn_unit_price ;
        -- 返品金額
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'rtn_price' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
        gt_xml_data_table(gl_xml_idx).tag_value := lv_rtn_price ;
        -- ロットNo.
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'lot_num' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
        gt_xml_data_table(gl_xml_idx).tag_value := it_param_data(i).lot_number ;
        -- 製造日
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'make_date' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
        gt_xml_data_table(gl_xml_idx).tag_value := it_param_data(i).make_date ;
        -- 賞味期限
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'limit_date' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
        gt_xml_data_table(gl_xml_idx).tag_value := it_param_data(i).limit_date ;
        -- 固有記号
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'sign' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
        gt_xml_data_table(gl_xml_idx).tag_value := it_param_data(i).lot_sign ;
        -- 直送区分が３の場合は配送先を指定
        IF (it_param_data(i).drop_ship_type = 3) THEN
          -- 配送先（配送先コード）
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'fac_del_cd' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
          gt_xml_data_table(gl_xml_idx).tag_value := it_param_data(i).delivery_code ;
          -- 配送先（配送先名称）
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'fac_del_name' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
          gt_xml_data_table(gl_xml_idx).tag_value := it_param_data(i).delivery_name ;
        -- それ以外の場合は工場を指定
        ELSE
          -- 工場（工場コード）
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'fac_del_cd' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
          gt_xml_data_table(gl_xml_idx).tag_value := it_param_data(i).factory_code ;
          -- 工場（工場名称）
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'fac_del_name' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
          gt_xml_data_table(gl_xml_idx).tag_value := it_param_data(i).factory_name ;
        END IF ;
        -- 仕入形態
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'stocking_type' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
        gt_xml_data_table(gl_xml_idx).tag_value := it_param_data(i).stocking_type ;
        -- 年度
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'year' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
        gt_xml_data_table(gl_xml_idx).tag_value := it_param_data(i).nendo ;
        -- 茶期区分
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'reaf_div' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
        gt_xml_data_table(gl_xml_idx).tag_value := it_param_data(i).reaf_devision ;
        -- 産地
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'home' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
        gt_xml_data_table(gl_xml_idx).tag_value := it_param_data(i).home ;
        -- タイプ
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'type' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
        gt_xml_data_table(gl_xml_idx).tag_value := it_param_data(i).pack_type ;
        -- ランク
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'rank' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
        gt_xml_data_table(gl_xml_idx).tag_value := func_rank_edit(it_param_data(i).rank1
                                                     ,it_param_data(i).rank2
                                                     ,it_param_data(i).rank3) ;
        -- 摘要（明細摘要）
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'dtl_desc' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
        gt_xml_data_table(gl_xml_idx).tag_value := it_param_data(i).line_desc ;
        -- ％／区分（粉引）
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'kobiki_rate' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
        gt_xml_data_table(gl_xml_idx).tag_value := it_param_data(i).kobiki_rate ;
        -- ％／区分（口銭）
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'kousen_type' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
        gt_xml_data_table(gl_xml_idx).tag_value := it_param_data(i).kousen_type ;
        -- ％／区分（賦課金）
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'fukakin_type' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
        gt_xml_data_table(gl_xml_idx).tag_value := it_param_data(i).fukakin_type ;
        -- 単価／掛率（粉引）
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'kobiki_unt_price' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
        gt_xml_data_table(gl_xml_idx).tag_value := it_param_data(i).kobiki_unt_price ;
        -- 単価／掛率（口銭）
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'kousen_unt_price' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
        gt_xml_data_table(gl_xml_idx).tag_value := it_param_data(i).kousen_unt_price ;
        -- 単価／掛率（賦課金）
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'fukakin_unt_price' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
        gt_xml_data_table(gl_xml_idx).tag_value := it_param_data(i).fukakin_unt_price ;
        -- 金額（粉引）
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'kobiki_price' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
        gt_xml_data_table(gl_xml_idx).tag_value := it_param_data(i).kobiki_price ;
        -- 金額（口銭）
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'kosen_price' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
        gt_xml_data_table(gl_xml_idx).tag_value := it_param_data(i).kousen_price ;
        -- 金額（賦課金）
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'fukakin_price' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
        gt_xml_data_table(gl_xml_idx).tag_value := it_param_data(i).fukakin_price ;
        ------------------------------
        -- 明細Ｇ終了タグ
        ------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := '/g_dtl' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
        -- ６明細毎にグループ化
        -- セクション最終レコードの場合
        IF ((MOD(lv_cnt,6)=0) OR (lv_cnt = lv_dtl_cnt)) THEN
          ------------------------------
          -- 明細LＧ終了タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_dtl_info' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
          -- セクション最終ページの場合
          IF (CEIL(lv_cnt/6) = CEIL(lv_dtl_cnt/6)) THEN
            -- 合計返品数を出力
            gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
            gt_xml_data_table(gl_xml_idx).tag_name  := 'sum_rtn_quant' ;
            gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
            gt_xml_data_table(gl_xml_idx).tag_value := lv_sum_rtn_quant ;
            -- 合計金額を出力
            gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
            gt_xml_data_table(gl_xml_idx).tag_name  := 'sum_price' ;
            gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
            gt_xml_data_table(gl_xml_idx).tag_value := lv_sum_price ;
          ELSE
            -- 合計返品数にNULLを出力
            gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
            gt_xml_data_table(gl_xml_idx).tag_name  := 'sum_rtn_quant' ;
            gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
            gt_xml_data_table(gl_xml_idx).tag_value := NULL ;
            -- 合計金額にNULLを出力
            gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
            gt_xml_data_table(gl_xml_idx).tag_name  := 'sum_price' ;
            gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
            gt_xml_data_table(gl_xml_idx).tag_value := NULL ;
          END IF ;
          -- 単価消費税文言出力
          -- １行目
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'tax_info_01' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
          gt_xml_data_table(gl_xml_idx).tag_value := SUBSTRB(lv_tax_info, 0 , 48) ;
          -- ２行目
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'tax_info_02' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
          gt_xml_data_table(gl_xml_idx).tag_value := SUBSTRB(lv_tax_info, 49 , 150) ;
          ------------------------------
          -- 明細ページＧ終了タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_dtl_class' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
        END IF ;
        -- セクション（返品No毎）内最終レコード時グループタグを閉じる。
        IF (lv_cnt = lv_dtl_cnt) THEN
         ------------------------------
         -- 明細ページLＧ終了タグ
         ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_dtl_class_info' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
          ------------------------------
          -- 返品Ｇ終了タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_rtn' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
          gt_xml_data_table(gl_xml_idx).tag_value :=gc_report_id ;
          -- カウンタ初期化
          lv_cnt := 1;
          -- 合計返品数初期化
          lv_sum_rtn_quant := 0;
          -- 合計金額足し込み
          lv_sum_price := 0 ;
        ELSE
          -- カウンタインクリメント
          lv_cnt    := lv_cnt + 1 ;
        END IF ;
      END LOOP param_data_loop ;
    END IF ;
--
    -- =====================================================
    -- 終了処理
    -- =====================================================
    ------------------------------
    -- 返品LＧ終了タグ
    ------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_rtn_info' ;
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
  EXCEPTION
--
  -- *** 対象データ0件例外ハンドラ ***
  WHEN dtldata_notfound_expt THEN
    ov_retcode := gv_status_warn ;
    ov_errmsg  := xxcmn_common_pkg.get_msg( gc_application
                                           ,gc_err_code_no_data
                                           ,gc_msg_table
                                           ,gc_table_name ) ;
    FND_FILE.PUT_LINE(FND_FILE.LOG,ov_errmsg) ;
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
     iv_rtn_number          IN     VARCHAR2     -- 01 : 返品番号
     ,iv_dept_code          IN     VARCHAR2     -- 02 : 担当部署
     ,iv_tantousya_code     IN     VARCHAR2     -- 03 : 担当者
     ,iv_creation_date_from IN     VARCHAR2     -- 04 : 作成日時FROM
     ,iv_creation_date_to   IN     VARCHAR2     -- 05 : 作成日時TO
     ,iv_vendor_code        IN     VARCHAR2     -- 06 : 取引先
     ,iv_assen_code         IN     VARCHAR2     -- 07 : 斡旋者
     ,iv_location_code      IN     VARCHAR2     -- 08 : 納入先
     ,iv_rtn_date_from      IN     VARCHAR2     -- 09 : 返品日FROM
     ,iv_rtn_date_to        IN     VARCHAR2     -- 10 : 返品日TO
     ,iv_prod_div           IN     VARCHAR2     -- 11 : 商品区分
     ,iv_item_div           IN     VARCHAR2     -- 12 : 品目区分
     ,ov_errbuf     OUT NOCOPY VARCHAR2         -- エラー・メッセージ
     ,ov_retcode    OUT NOCOPY VARCHAR2         -- リターン・コード
     ,ov_errmsg     OUT NOCOPY VARCHAR2)        -- ユーザー・エラー・メッセージ
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
    -- *** ローカル変数 ***
    lr_param rec_param_data ;
    lr_data_rec tab_data_type_dtl ;
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
     lr_param.rtn_number         := iv_rtn_number ;         -- 返品番号
     lr_param.dept_code          := iv_dept_code ;          -- 担当部署
     lr_param.tantousya_code     := iv_tantousya_code ;     -- 担当者
     lr_param.creation_date_from := iv_creation_date_from ; -- 作成日時FROM
     lr_param.creation_date_to   := iv_creation_date_to ;   -- 作成日時TO
     lr_param.vendor_code        := iv_vendor_code ;        -- 取引先
     lr_param.assen_code         := iv_assen_code ;         -- 斡旋者
     lr_param.location_code      := iv_location_code ;      -- 納入先
     lr_param.rtn_date_from      := iv_rtn_date_from ;      -- 返品日FROM
     lr_param.rtn_date_to        := iv_rtn_date_to ;        -- 返品日TO
     lr_param.prod_div           := iv_prod_div ;           -- 商品区分
     lr_param.item_div           := iv_item_div ;           -- 品目区分
    -- ===============================================
    -- 入力パラメータチェック B-1
    -- ===============================================
    prc_check_param_info(
      lr_param,          -- 入力パラメータ群
      lv_errbuf,         -- エラー・メッセージ
      lv_retcode,        -- リターン・コード
      lv_errmsg);        -- ユーザー・エラー・メッセージ
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF ;
--
    -- ===============================================
    -- データ抽出/データ加工B-3,4
    -- ===============================================
    prc_get_report_data(
      lr_param                      -- 01.入力パラメータ群
     ,ot_data_rec  => lr_data_rec   -- 02.取得レコード群
     ,ov_errbuf    => lv_errbuf     -- エラー・メッセージ
     ,ov_retcode   => lv_retcode    -- リターン・コード
     ,ov_errmsg    => lv_errmsg     -- ユーザー・エラー・メッセージ
    );
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF ;
--
    -- ===============================================
    -- データ出力 B-5
    -- ===============================================
    prc_create_xml_data(
     xml_data_table
     ,lr_data_rec  -- 取得レコード群
     ,lv_errbuf    -- エラー・メッセージ
     ,lv_retcode   -- リターン・コード
     ,lv_errmsg    -- ユーザー・エラー・メッセージ
    );
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
  PROCEDURE main    (
      errbuf                OUT    VARCHAR2 -- エラーメッセージ
     ,retcode               OUT    VARCHAR2 -- エラーコード
     ,iv_rtn_number         IN     VARCHAR2 -- 01 : 返品番号
     ,iv_dept_code          IN     VARCHAR2 -- 02 : 担当部署
     ,iv_tantousya_code     IN     VARCHAR2 -- 03 : 担当者
     ,iv_creation_date_from IN     VARCHAR2 -- 04 : 作成日時FROM
     ,iv_creation_date_to   IN     VARCHAR2 -- 05 : 作成日時TO
     ,iv_vendor_code        IN     VARCHAR2 -- 06 : 取引先
     ,iv_assen_code         IN     VARCHAR2 -- 07 : 斡旋者
     ,iv_location_code      IN     VARCHAR2 -- 08 : 納入先
     ,iv_rtn_date_from      IN     VARCHAR2 -- 09 : 返品日FROM
     ,iv_rtn_date_to        IN     VARCHAR2 -- 10 : 返品日TO
     ,iv_prod_div           IN     VARCHAR2 -- 11 : 商品区分
     ,iv_item_div           IN     VARCHAR2 -- 12 : 品目区分
    )
--
--###########################  固定部 START   ###########################
--
  IS
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'xxpo330001c.main';  -- プログラム名
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
     iv_rtn_number            -- 01 : 返品番号
     ,iv_dept_code            -- 02 : 担当部署
     ,iv_tantousya_code       -- 03 : 担当者
     ,iv_creation_date_from   -- 04 : 作成日時FROM
     ,iv_creation_date_to     -- 05 : 作成日時TO
     ,iv_vendor_code          -- 06 : 取引先
     ,iv_assen_code           -- 07 : 斡旋者
     ,iv_location_code        -- 08 : 納入先
     ,iv_rtn_date_from        -- 09 : 返品日FROM
     ,iv_rtn_date_to          -- 10 : 返品日TO
     ,iv_prod_div             -- 11 : 商品区分
     ,iv_item_div             -- 12 : 品目区分
     ,lv_errbuf               -- エラー・メッセージ
     ,lv_retcode              -- リターン・コード
     ,lv_errmsg);             -- ユーザー・エラー・メッセージ
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
    -- ステータスセット
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
END xxpo330001c;
/