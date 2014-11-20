CREATE OR REPLACE
PACKAGE BODY xxwip230002c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxwip230002c(body)
 * Description      : 生産帳票機能（生産日報）
 * MD.050/070       : 生産帳票機能（生産日報）Issue1.0  (T_MD050_BPO_230)
 *                    生産帳票機能（生産日報）          (T_MD070_BPO_23B)
 * Version          : 1.11
 *
 * Program List
 * ---------------------------- ----------------------------------------------------------
 *  Name                         Description
 * ---------------------------- ----------------------------------------------------------
 *  validate_date_format           PROCEDURE  : 日付フォーマットチェック関数
 *  fnc_conv_xml                   FUNCTION   : ＸＭＬタグに変換する。
 *  prc_out_xml_data               PROCEDURE  : ＸＭＬ出力処理
 *  prc_get_busho_data             PROCEDURE  : 部署情報取得
 *  prc_get_mei_title_data         PROCEDURE  : 明細タイトル取得
 *  prc_create_xml_data            PROCEDURE  : ＸＭＬデータ作成
 *  prc_create_zeroken_xml_data    PROCEDURE  : 取得件数０件時ＸＭＬデータ作成
 *  prc_get_head_data              PROCEDURE  : ヘッダー情報取得
 *  prc_get_tonyu_data             PROCEDURE  : 明細-投入情報抽出
 *  prc_get_reinyu_tonyu_data      PROCEDURE  : 明細-戻入（投入分）情報抽出処理
 *  prc_get_fsanbutu_data          PROCEDURE  : 明細-副産物情報抽出処理
 *  prc_get_utikomi_data           PROCEDURE  : 明細-打込情報抽出処理
 *  prc_get_reinyu_utikomi_data    PROCEDURE  : 明細-戻入（打込分）情報抽出処理
 *  prc_get_tonyu_sizai_data       PROCEDURE  : 明細-投入資材情報抽出処理
 *  prc_get_reinyu_sizai_data      PROCEDURE  : 明細-戻入資材情報抽出処理
 *  prc_get_seizou_furyo_data      PROCEDURE  : 明細-製造不良情報抽出処理
 *  prc_get_gyousha_furyo_data     PROCEDURE  : 明細-業者不良情報抽出処理
 *  prc_check_param_data           PROCEDURE  : パラメータチェック処理
 *  submain                        PROCEDURE  : メイン処理プロシージャ
 *  main                           PROCEDURE  : コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ------------------- -------------------------------------------------
 *  Date          Ver.  Editor              Description
 * ------------- ----- ------------------- -------------------------------------------------
 *  2008/02/06    1.0   Ryouhei Fujii       新規作成
 *  2008/05/20    1.1   Yusuke  Tabata      内部変更要求(Seq95)日付型パラメータ型変換対応
 *  2008/05/29    1.2   Ryouhei Fujii       結合テスト不具合対応　NET換算パターン障害
 *  2008/06/04    1.3   Daisuke Nihei       結合テスト不具合対応　切／計込計算式不備対応
 *                                          結合テスト不具合対応　パーセント計算式不備対応
 *  2008/07/02    1.4   Satoshi Yunba       禁則文字対応
 *  2008/10/28    1.5   Daisuke  Nihei      T_TE080_BPO_230 No15対応 入力日時の結合先を作成日から更新日に変更する
 *  2008/12/02    1.6   Daisuke  Nihei      本番障害#325対応
 *  2008/12/17    1.7   Daisuke  Nihei      本番障害#709対応
 *  2008/12/24    1.8   Akiyoshi Shiina     本番障害#849,#823対応
 *  2008/12/25    1.9   Akiyoshi Shiina     本番障害#823再対応
 *  2009/02/04    1.10  Yasuhisa Yamamoto   本番障害#4対応 ランク３出力対応
 *  2009/11/24    1.11  Hitomi Itou         本番障害#1696対応 入力パラメータFROM-TO片方のみは不可
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
--
  -- パッケージ名
  gv_pkg_name                   CONSTANT VARCHAR2(20) := 'XXWIP230002' ;
--
  -- 帳票ID
  gc_report_id                  CONSTANT VARCHAR2(12) := 'XXWIP230002T' ;                      -- 帳票ID
--
  -- 日付フォーマット
  gv_date_format1               CONSTANT VARCHAR2(21) := 'YYYY/MM/DD HH24:MI:SS';              -- 年月日時分秒
  gv_date_format2               CONSTANT VARCHAR2(18) := 'YYYY/MM/DD HH24:MI';                 -- 年月日時分
  gv_date_format3               CONSTANT VARCHAR2(10) := 'YYYY/MM/DD';                         -- 年月日
--
  -- 数値フォーマット
  gv_num_format1               CONSTANT VARCHAR2(15) := 'FM999999990D000';      -- 99999999Z.ZZZ
  gv_num_format2               CONSTANT VARCHAR2(9)  := 'FM990D000';            -- 99Z.ZZZ
  gv_num_format3               CONSTANT VARCHAR2(8)  := 'FM990D00';             -- 99Z.ZZ
--
  /*明細タイトル定数*/
  -- 明細行固定タイトル
  gv_title_header               CONSTANT VARCHAR2(2)  := '＜';            -- タイトルタイトル編集時の先頭用
  -- 投入明細用
  gv_tonyu_title                CONSTANT VARCHAR2(10) := '＜投　入＞';    -- 通常投入品タイトル
  gv_shinkansen_title_tonyu     CONSTANT VARCHAR2(10) := '投入＞';        -- 新缶煎ライン時投入品タイトル
  -- 戻入明細用
  gv_reinyu_title               CONSTANT VARCHAR2(10) := '＜戻　入＞';    -- 通常投戻入品タイトル
  gv_shinkansen_title_reinyu    CONSTANT VARCHAR2(10) := '戻入＞';        -- 新缶煎ライン時戻入品タイトル
  -- 副産物用
  gv_fukusanbutu_title          CONSTANT VARCHAR2(10) := '＜副産物＞';    -- 副産物タイトル
  -- 打込用
  gv_utikomi_title              CONSTANT VARCHAR2(10) := '＜打　込＞';
  -- 資材タイトル
  gv_sizai_title_tounyu         CONSTANT VARCHAR2(12) := '＜投入資材＞';  -- 投入資材
  gv_sizai_title_reinyu         CONSTANT VARCHAR2(12) := '＜戻入資材＞';  -- 戻入資材
  gv_sizai_title_seizofuryo     CONSTANT VARCHAR2(12) := '＜製造不良＞';  -- 製造不良
  gv_sizai_title_gyoshafuryo    CONSTANT VARCHAR2(12) := '＜業者不良＞';  -- 業者不良
--
  /*メッセージ系定数*/
  -- タイトル取得エラーメッセージ
  gv_err_mei_title_no_data      CONSTANT VARCHAR2(100) := '投入口名称を取得できませんでした。';
--
  gv_err_make_date_from         CONSTANT VARCHAR2(20) := '生産日（FROM）';         -- 生産日（FROM）
  gv_err_make_date_to           CONSTANT VARCHAR2(20) := '生産日（TO）';           -- 生産日（TO）
  gv_err_input_date_from        CONSTANT VARCHAR2(20) := '入力日時（FROM）';       -- 入力日時（FROM）
  gv_err_input_date_to          CONSTANT VARCHAR2(20) := '入力日時（TO）';         -- 入力日時（TO）
-- 2009/11/24 H.Itou Add Start 本番障害#1696
  gv_err_tehai_no_from          CONSTANT VARCHAR2(20) := '手配No（FROM）';         -- 手配No（FROM）
  gv_err_tehai_no_to            CONSTANT VARCHAR2(20) := '手配No（TO）';           -- 手配No（TO）
  gv_err_make_date              CONSTANT VARCHAR2(20) := '生産日';                 -- 生産日
  gv_err_tehai_no               CONSTANT VARCHAR2(20) := '手配No';                 -- 手配No
-- 2009/11/24 H.Itou End
  -- メッセージアプリケーション
  gc_application_cmn            CONSTANT fnd_application.application_short_name%TYPE  := 'XXCMN' ;
  gc_application_wip            CONSTANT fnd_application.application_short_name%TYPE  := 'XXWIP' ;
  -- トークン
  gv_tkn_date                   CONSTANT VARCHAR2(10) := 'DATE';
  gv_tkn_param1                 CONSTANT VARCHAR2(10) := 'PARAM1';
  gv_tkn_param2                 CONSTANT VARCHAR2(10) := 'PARAM2';
  gv_tkn_item                   CONSTANT VARCHAR2(10) := 'ITEM';
  gv_tkn_value                  CONSTANT VARCHAR2(10) := 'VALUE';
-- 2009/11/24 H.Itou Add Start 本番障害#1696
  gv_tkn_from                   CONSTANT VARCHAR2(10) := 'FROM';
  gv_tkn_to                     CONSTANT VARCHAR2(10) := 'TO';
-- 2009/11/24 H.Itou End
--
  -- 「OPM品目マスタ.NET」未入力時のデフォルト値
  gv_net_default_val            CONSTANT NUMBER := NULL;
--
  -- 業務ステータス
  gv_status_comp                CONSTANT gme_batch_header.attribute4%TYPE := '7';                     -- 完了
-- 2008/12/24 v1.8 ADD START
  gv_status_close               CONSTANT gme_batch_header.attribute4%TYPE := '8';                     -- クロ－ズ
-- 2008/12/24 v1.8 ADD END
--
  -- 生産原料詳細ラインタイプ
  gv_line_type_kbn_genryou      CONSTANT gme_material_details.line_type%TYPE := -1;       -- 原料
  gv_line_type_kbn_seizouhin    CONSTANT gme_material_details.line_type%TYPE := 1;        -- 製造品
  gv_line_type_kbn_fukusanbutu  CONSTANT gme_material_details.line_type%TYPE := 2;        -- 副産物
--
  -- LOOKUPタイプ名
  gv_lookup_type_den_kbn        CONSTANT xxcmn_lookup_values_v.lookup_type%TYPE := 'XXCMN_L03';     -- 伝票区分
  gv_lookup_type_knri_bsho      CONSTANT xxcmn_lookup_values_v.lookup_type%TYPE := 'XXCMN_L10';     -- 成績管理部署
  gv_lookup_type_item_type      CONSTANT xxcmn_lookup_values_v.lookup_type%TYPE := 'XXCMN_L08';     -- タイプ
--
  -- 品目カテゴリセット名称
  gv_item_cat_name_item_kbn     CONSTANT xxcmn_item_categories_v.category_set_name%TYPE := '品目区分';
--
  -- 品目区分
  gv_hinmoku_kbn_genryou        CONSTANT xxcmn_item_categories5_v.item_class_code%TYPE := '1';     -- 原料
  gv_hinmoku_kbn_sizai          CONSTANT xxcmn_item_categories5_v.item_class_code%TYPE := '2';     -- 資材
  gv_hinmoku_kbn_hanseihin      CONSTANT xxcmn_item_categories5_v.item_class_code%TYPE := '4';     -- 半製品
  gv_hinmoku_kbn_seihin         CONSTANT xxcmn_item_categories5_v.item_class_code%TYPE := '5';     -- 製品
--
  -- 予定区分
  gv_yotei_kbn_tonyu            CONSTANT xxwip_material_detail.plan_type%TYPE := '4';              -- 投入
--
  -- 打込区分
  gv_utikomi_kbn_utikomi        CONSTANT gme_material_details.attribute5%TYPE := 'Y';
--
  -- 保留トラン完了フラグ
  gv_comp_flag                  CONSTANT ic_tran_pnd.completed_ind%TYPE := 1;    -- 完了
--
  -- 固定単位
  gv_unit_siage                 CONSTANT xxcmn_item_mst_v.item_um%TYPE := 'kg';  -- 仕上数単位
  gv_unit_kirikeikomi           CONSTANT xxcmn_item_mst_v.item_um%TYPE := 'kg';  -- 切/計込単位
--
--
  -- デフォルト投入口区分
  gv_tounyuguchi_kbn_default    CONSTANT gme_material_details.attribute8%TYPE := 'XXXXXX';
--
-- 追加 START 2008/05/20 YTabata
  gv_min_date_char              CONSTANT VARCHAR2(10) := '1900/01/01' ;    -- 最小日付
  gv_max_date_char              CONSTANT VARCHAR2(10) := '4712/12/31' ;    -- 最大日付
-- 追加 END 2008/05/20 YTabata
-- 2008/10/28 v1.5 D.Nihei ADD START 統合障害#499
  gv_doc_type_prod              CONSTANT VARCHAR2(4)   := 'PROD';          -- PROD (生産)
-- 2008/10/28 v1.5 D.Nihei ADD END
-- 2008/12/02 v1.6 D.Nihei ADD START 本番障害#325
  gv_um_hon                     CONSTANT VARCHAR2(2)   := '本';            -- 本(単位)
-- 2008/12/02 v1.6 D.Nihei ADD END
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
--
  -- 入力パラメータ格納用レコード変数
  TYPE type_param_rec IS RECORD (
      iv_den_kbn          gmd_routings_vl.attribute13%TYPE              -- 伝票区分
     ,iv_plant            gme_batch_header.plant_code%TYPE              -- プラントコード
     ,iv_line_no          gmd_routings_vl.routing_no%TYPE               -- ラインNo
     ,id_make_date_from   gme_batch_header.plan_start_date%TYPE         -- 生産日(FROM)
     ,id_make_date_to     gme_batch_header.plan_start_date%TYPE         -- 生産日(TO)
     ,id_tehai_no_from    gme_batch_header.batch_no%TYPE                -- 手配No(FROM)
     ,id_tehai_no_to      gme_batch_header.batch_no%TYPE                -- 手配No(TO)
     ,iv_hinmoku_cd       xxcmn_item_mst2_v.item_no%TYPE                -- 品目コード
-- 2008/10/28 v1.5 D.Nihei MOD START
--     ,id_input_date_from  gme_batch_header.creation_date%TYPE           -- 入力日時(FROM)
--     ,id_input_date_to    gme_batch_header.creation_date%TYPE           -- 入力日時(TO)
     ,id_input_date_from  gme_batch_header.last_update_date%TYPE           -- 入力日時(FROM)
     ,id_input_date_to    gme_batch_header.last_update_date%TYPE           -- 入力日時(TO)
-- 2008/10/28 v1.5 D.Nihei MOD END
    ) ;
--
  -- ヘッダーデータ格納用レコード変数
  TYPE type_head_data_rec IS RECORD (
       l_batch_id         gme_batch_header.batch_id%TYPE              -- 生産バッチヘッダ.バッチID
      ,l_last_updated_by  gme_batch_header.last_updated_by%TYPE       -- 生産バッチヘッダ.最終更新者ID
      ,l_shinkansen_kbn   gmd_routings_vl.attribute17%TYPE            -- 工順マスタVIEW.DFF17（新缶煎区分）
      ,l_item_id          gme_material_details.item_id%TYPE           -- 生産原料詳細.品目ID
      ,l_item_unit        xxcmn_item_mst2_v.item_um%TYPE              -- OPM品目情報VIEW2.単位
      ,l_net              NUMBER                                      -- OPM品目情報VIEW2.NET(NULL時の対応込み)
-- Add 2008/05/29
      ,l_item_class       xxcmn_item_categories2_v.segment1%TYPE      -- 品目区分
-- Add 2008/05/29
      ,l_tehai_no         gme_batch_header.batch_no%TYPE              -- 生産バッチヘッダ.バッチNO
      ,l_den_kbn          xxcmn_lookup_values_v.meaning%TYPE          -- 参照コード.摘要
      ,l_knri_bsho        xxcmn_lookup_values_v.meaning%TYPE          -- 参照コード.摘要
      ,l_hinmk_cd         xxcmn_item_mst2_v.item_no%TYPE              -- OPM品目情報VIEW2.品目コード
      ,l_hinmk_nm         xxcmn_item_mst2_v.item_desc1%TYPE           -- OPM品目情報VIEW2.摘要
      ,l_line_no          gmd_routings_vl.routing_no%TYPE             -- 工順マスタVIEW.工順NO
      ,l_line_nm          gmd_routings_vl.routing_desc%TYPE           -- 工順マスタVIEW.工順摘要
      ,l_set_cd           gmd_routings_vl.attribute9%TYPE             -- 工順マスタVIEW.DFF9（納品場所コード）
      ,l_set_nm           xxcmn_item_locations_v.description%TYPE     -- OPM保管場所情報VIEW.保管倉庫名
      ,l_make_start_date  DATE                                        -- 生産原料詳細.DFF11(生産日)
      ,l_make_end_date    DATE                                        -- 生産原料詳細.DFF11(生産日)
      ,l_shoumikigen      DATE                                        -- 生産原料詳細.DFF10(賞味期限日)
      ,l_item_type        xxcmn_lookup_values_v.meaning%TYPE          -- 参照コード.摘要
      ,l_item_rank1       gme_material_details.attribute2%TYPE        -- 生産原料詳細.DFF2(ランク1)
      ,l_item_rank2       gme_material_details.attribute3%TYPE        -- 生産原料詳細.DFF3(ランク2)
-- 2009/02/04 v1.10 Y.Yamamoto #4 add start
      ,l_item_rank3       gme_material_details.attribute26%TYPE       -- 生産原料詳細.DFF26(ランク3)
-- 2009/02/04 v1.10 Y.Yamamoto #4 add end
      ,l_item_tekiyo      gme_material_details.attribute4%TYPE        -- 生産原料詳細.DFF4(摘要)
      ,l_lot_no           ic_lots_mst.lot_no%TYPE                     -- OPMロットマスタ.ロットNO
      ,l_move_cd          gme_material_details.attribute12%TYPE       -- 生産原料詳細.DFF12(移動場所コード)
      ,l_move_nm          xxcmn_item_locations_v.description%TYPE     -- OPM保管場所情報VIEW.保管倉庫名
      ,l_stock_num        gme_material_details.attribute6%TYPE        -- 生産原料詳細.DFF6(在庫入数)
      ,l_dekidaka         NUMBER                                      -- 生産原料詳細.実績数量の換算結果
    ) ;
  TYPE type_head_data_tbl IS TABLE OF type_head_data_rec INDEX BY PLS_INTEGER ;
--
  -- 明細-投入データ/戻入（投入）データ/副産物データ/打込データ/戻入（打込分）データ
  -- 投入資材データ/戻入資材データ/製造不良データ/業者不良データ
  -- 格納用レコード変数
  TYPE type_tounyu_data_rec IS RECORD 
    (
      l_material_detail_id    gme_material_details.material_detail_id%TYPE  -- 生産原料詳細ID
     ,l_tounyuguchi_kbn       gme_material_details.attribute8%TYPE          -- 投入口区分
     ,l_hinmk_cd              xxcmn_item_mst_v.item_no%TYPE                 -- 品目コード
     ,l_hinmk_nm              xxcmn_item_mst_v.item_short_name%TYPE         -- 品名・略称
     ,l_lot_no                ic_lots_mst.lot_no%TYPE                       -- ロットNo
     ,l_make_date             DATE                                          -- 製造年月日
     ,l_stock                 NUMBER                                        -- 在庫入数
     ,l_total                 xxwip_material_detail.invested_qty%TYPE       -- 総数量
     ,l_unit                  xxcmn_item_mst_v.item_um%TYPE                 -- 単位
-- 2008/12/17 v1.7 D.Nihei ADD START
     ,l_net                   xxcmn_item_mst_v.net%TYPE                     -- NET
-- 2008/12/17 v1.7 D.Nihei ADD END
    ) ;
  TYPE type_tounyu_data_tbl IS TABLE OF type_tounyu_data_rec INDEX BY BINARY_INTEGER ;
--
  -- 部署情報格納用レコード変数
  TYPE rec_busho_data  IS RECORD 
    (
      yubin_no   xxcmn_locations_all.zip%TYPE               -- 郵便番号
     ,address    xxcmn_locations_all.address_line1%TYPE     -- 住所
     ,tel        xxcmn_locations_all.phone%TYPE             -- 電話番号
     ,fax        xxcmn_locations_all.fax%TYPE               -- FAX番号
     ,busho_nm   xxcmn_locations_all.location_name%TYPE     -- 部署名称
    ) ;
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
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
--
  /**********************************************************************************
   * Procedure Name   : validate_date_format
   * Description      : 日付フォーマットチェック関数
   ***********************************************************************************/
  PROCEDURE validate_date_format
    (
      iv_validate_date    IN         VARCHAR2       -- チェック対象日付（文字）
     ,iv_err_item_val     IN         VARCHAR2       -- エラー項目名称
     ,iv_date_format      IN         VARCHAR2       -- 変換フォーマット
     ,od_change_date      OUT NOCOPY DATE           -- 変換後日付
     ,ov_errbuf           OUT NOCOPY VARCHAR2       -- エラー・メッセージ           --# 固定 #
     ,ov_retcode          OUT NOCOPY VARCHAR2       -- リターン・コード             --# 固定 #
     ,ov_errmsg           OUT NOCOPY VARCHAR2       -- ユーザー・エラー・メッセージ --# 固定 #
    )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'validate_date_format'; -- プログラム名
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
    -- *** ローカル・例外処理 ***
    date_format_expt     EXCEPTION ;     -- 日付フォーマット不正例外
    -- *** ローカル変数 ***
    lv_validate_date_tmp VARCHAR2(20) DEFAULT NULL ;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- 指定フォーマットへの変換
-- 変更 START 2008/05/20 YTabata
/**
    od_change_date := FND_DATE.STRING_TO_DATE(iv_validate_date
                                             ,iv_date_format) ;
--
    IF (od_change_date IS NULL) THEN
      -- 日付の変換エラー時
      ov_errmsg := xxcmn_common_pkg.get_msg( gc_application_cmn
                                            ,'APP-XXCMN-10012'
                                            ,gv_tkn_item
                                            ,iv_err_item_val
                                            ,gv_tkn_value
                                            ,iv_validate_date) ;
--
      ov_errbuf  := ov_errmsg ;
      ov_retcode := gv_status_error;
    END IF;
--
  EXCEPTION
--
**/
    BEGIN
--
-- 2008/12/25 v1.9 UPDATE START
--      lv_validate_date_tmp := TO_CHAR(FND_DATE.CANONICAL_TO_DATE(iv_validate_date),gv_date_format1) ;
      lv_validate_date_tmp := TO_CHAR(FND_DATE.CANONICAL_TO_DATE(iv_validate_date),iv_date_format) ;
-- 2008/12/25 v1.9 UPDATE END
--
    EXCEPTION
--
      -- *** OTHERS例外ハンドラ ***
      WHEN OTHERS THEN
        RAISE date_format_expt ;
    END ;
    -- 指定フォーマットへの変換
-- 2008/12/25 v1.9 UPDATE START
/*
-- 2008/12/24 v1.8 UPDATE START
--    od_change_date := FND_DATE.STRING_TO_DATE(lv_validate_date_tmp
--                                             ,iv_date_format) ;
    od_change_date := TRUNC(TO_DATE(lv_validate_date_tmp, gv_date_format1)) ;
-- 2008/12/24 v1.8 UPDATE END
*/
    od_change_date := FND_DATE.STRING_TO_DATE(lv_validate_date_tmp, iv_date_format) ;
-- 2008/12/25 v1.9 UPDATE END
--
  EXCEPTION
--
    WHEN date_format_expt THEN
      -- 日付の変換エラー時
      ov_errmsg := xxcmn_common_pkg.get_msg( gc_application_cmn
                                            ,'APP-XXCMN-10012'
                                            ,gv_tkn_item
                                            ,iv_err_item_val
                                            ,gv_tkn_value
                                            ,iv_validate_date) ;
--
      ov_errbuf  := ov_errmsg ;
      ov_retcode := gv_status_error;
-- 変更 END 2008/05/20 YTabata
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
  END validate_date_format ;
--
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
      lv_convert_data := '<'||iv_name||'><![CDATA['||iv_value||']]></'||iv_name||'>';
    ELSE
      lv_convert_data := '<'||iv_name||'>' ;
    END IF ;
--
    RETURN(lv_convert_data) ;
--
  END fnc_conv_xml ;
--
--
--
  /**********************************************************************************
   * Procedure Name   : prc_out_xml_data
   * Description      : ＸＭＬ出力処理
   ***********************************************************************************/
  PROCEDURE prc_out_xml_data
    (
      ov_errbuf     OUT NOCOPY VARCHAR2                  --    エラー・メッセージ           --# 固定 #
     ,ov_retcode    OUT NOCOPY VARCHAR2                  --    リターン・コード             --# 固定 #
     ,ov_errmsg     OUT NOCOPY VARCHAR2                  --    ユーザー・エラー・メッセージ --# 固定 #
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
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<lg_nippo_info>' ) ;
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
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '</lg_nippo_info>' ) ;
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
--
  /**********************************************************************************
   * Procedure Name   : prc_get_busho_data
   * Description      : 部署情報取得
   ***********************************************************************************/
  PROCEDURE prc_get_busho_data
    (
      in_last_updated_user   IN         gme_batch_header.last_updated_by%TYPE       -- 最終更新者ID
     ,or_busho_data          OUT NOCOPY rec_busho_data
     ,ov_errbuf              OUT NOCOPY VARCHAR2                                    --    エラー・メッセージ           --# 固定 #
     ,ov_retcode             OUT NOCOPY VARCHAR2                                    --    リターン・コード             --# 固定 #
     ,ov_errmsg              OUT NOCOPY VARCHAR2                                    --    ユーザー・エラー・メッセージ  --# 固定 #
    )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_get_busho_data'; -- プログラム名
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
    lv_busho_cd hr_locations_all.location_code%TYPE;            -- 部署コード
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
    -- データ抽出
    -- ====================================================
    -- カーソルオープン
      SELECT hla.location_code
      INTO   lv_busho_cd
      FROM   fnd_user              fu
            ,per_all_assignments_f paaf
            ,hr_locations_all      hla
      WHERE  fu.user_id                 = in_last_updated_user
      AND    fu.employee_id             = paaf.person_id
      AND    paaf.location_id           = hla.location_id
      AND    paaf.effective_start_date <= TRUNC(SYSDATE)
      AND    paaf.effective_end_date   >= TRUNC(SYSDATE)
      AND    fu.start_date             <= TRUNC(SYSDATE)
      AND    ((fu.end_date IS NULL) OR (fu.end_date >= TRUNC(SYSDATE)))
      AND    ((hla.inactive_date IS NULL) OR (hla.inactive_date >= TRUNC(SYSDATE)))
      AND    paaf.primary_flag = 'Y'
    ;
--
    IF (lv_busho_cd IS NOT NULL) THEN
      -- =====================================================
      -- 部署情報取得プロシージャ呼び出し
      -- =====================================================
      xxcmn_common_pkg.get_dept_info
        (
          iv_dept_cd                =>    lv_busho_cd
         ,id_appl_date              =>    NULL
         ,ov_postal_code            =>    or_busho_data.yubin_no
         ,ov_address                =>    or_busho_data.address
         ,ov_tel_num                =>    or_busho_data.tel
         ,ov_fax_num                =>    or_busho_data.fax
         ,ov_dept_formal_name       =>    or_busho_data.busho_nm
         ,ov_errbuf                 =>    lv_errbuf
         ,ov_retcode                =>    lv_retcode
         ,ov_errmsg                 =>    lv_errmsg
        );
--
    END IF;
--
    IF ( lv_retcode = gv_status_error ) THEN
      RAISE global_process_expt ;
    END IF ;
--
  EXCEPTION
    WHEN NO_DATA_FOUND OR TOO_MANY_ROWS THEN
      -- データ抽出不可or複数行取得時
      NULL;     -- 何もしない
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
  END prc_get_busho_data ;
--
--
--
  /**********************************************************************************
   * Procedure Name   : prc_get_mei_title_data
   * Description      : 明細タイトル取得
   ***********************************************************************************/
  PROCEDURE prc_get_mei_title_data
    (
      in_material_detail_id IN         gme_material_details.material_detail_id%TYPE    -- 生産原料詳細ID
     ,ov_mei_title          OUT NOCOPY VARCHAR2                                        -- 明細タイトル
     ,ov_errbuf             OUT NOCOPY VARCHAR2                                        -- エラー・メッセージ           --# 固定 #
     ,ov_retcode            OUT NOCOPY VARCHAR2                                        -- リターン・コード             --# 固定 #
     ,ov_errmsg             OUT NOCOPY VARCHAR2                                        -- ユーザー・エラー・メッセージ  --# 固定 #
    )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_get_mei_title_data'; -- プログラム名
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
    -- データ抽出
    -- ====================================================
    SELECT gov.oprn_desc
    INTO   ov_mei_title
    FROM   gme_batch_steps           gbs,           -- 生産バッチステップ
           gmd_operations_vl         gov,           -- 工程マスタビュー
           gme_batch_step_items      gbsi           -- 生産バッチステップ品目
    WHERE  gbs.batchstep_id        = gbsi.batchstep_id
    AND    gov.oprn_id             = gbs.oprn_id
    AND    gbsi.material_detail_id = in_material_detail_id
    ;
--
  EXCEPTION
    WHEN NO_DATA_FOUND OR TOO_MANY_ROWS THEN
      -- データ抽出不可or複数行取得時
      NULL;     -- 何もしない
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
  END prc_get_mei_title_data ;
--
--
--
  /**********************************************************************************
   * Procedure Name   : prc_create_xml_data
   * Description      : ＸＭＬデータ作成
   ***********************************************************************************/
  PROCEDURE prc_create_xml_data(
      ir_param_rec           IN         type_param_rec        -- パラメータ受渡し用
     ,ir_head_data           IN         type_head_data_rec    -- 取得レコード（ヘッダ情報）
     ,it_tonyu_data          IN         type_tounyu_data_tbl  -- 取得レコード表（明細-投入情報）
     ,it_reinyu_tonyu_data   IN         type_tounyu_data_tbl  -- 取得レコード表（明細-戻入（投入分）情報）
     ,it_fukusanbutu_data    IN         type_tounyu_data_tbl  -- 取得レコード表（明細-副産物情報）
     ,it_utikomi_data        IN         type_tounyu_data_tbl  -- 取得レコード表（明細-打込情報）
     ,it_reinyu_utikomi_data IN         type_tounyu_data_tbl  -- 取得レコード表（明細-戻入（打込分）情報）
     ,it_tonyu_sizai_data    IN         type_tounyu_data_tbl  -- 取得レコード表（明細-投入資材情報）
     ,it_reinyu_sizai_data   IN         type_tounyu_data_tbl  -- 取得レコード表（明細-戻入資材情報）
     ,it_seizou_furyo_data   IN         type_tounyu_data_tbl  -- 取得レコード表（明細-製造不良情報）
     ,it_gyousha_furyo_data  IN         type_tounyu_data_tbl  -- 取得レコード表（明細-業者不良情報）
     ,id_now_date            IN         DATE                  -- 現在日
     ,ov_errbuf              OUT NOCOPY VARCHAR2              -- エラー・メッセージ            --# 固定 #
     ,ov_retcode             OUT NOCOPY VARCHAR2              -- リターン・コード              --# 固定 #
     ,ov_errmsg              OUT NOCOPY VARCHAR2              -- ユーザー・エラー・メッセージ  --# 固定 #
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
    -- 配列カウンタ変数
    l_cnt                    PLS_INTEGER;
    -- 部署情報
    lr_busho_data            rec_busho_data;
    -- 投入口区分ブレイク用変数
    lv_tounyuguchi_kbn       gme_material_details.attribute8%TYPE DEFAULT 'ZZZZZZZZZZ';
    -- 明細タイトル
    lv_mei_title             gmd_operations_vl.oprn_desc%TYPE;
    -- 投入明細サマリ用変数
    ln_tounyu_total          NUMBER DEFAULT 0 ;
    -- 戻入（投入）明細サマリ用変数
    ln_reinyu_tounyu_total   NUMBER DEFAULT 0 ;
    -- 副産物明細サマリ用変数
    ln_fukusanbutu_total     NUMBER DEFAULT 0 ;
    -- 打込明細サマリ用変数
    ln_utikomi_total         NUMBER DEFAULT 0 ;
    -- 仕上げ数
    ln_siage_total           NUMBER DEFAULT 0;
    -- 切／計込明細合計
    ln_kirikeikomi_total     NUMBER DEFAULT 0;
    -- 戻入（打込）明細サマリ用変数
    ln_reinyu_utikomi_total  NUMBER DEFAULT 0;
-- 2008/10/28 v1.5 D.Nihei ADD START
    ln_invest_total          NUMBER DEFAULT 0;
-- 2008/10/28 v1.5 D.Nihei ADD END
-- 2008/12/17 v1.7 D.Nihei ADD START
    ln_tounyu_net_total      NUMBER DEFAULT 0;
    ln_rei_tou_net_total     NUMBER DEFAULT 0;
-- 2008/12/17 v1.7 D.Nihei ADD END
--
  BEGIN
--
    -- =====================================================
    -- 項目データ抽出・出力処理
    -- =====================================================
    -- -----------------------------------------------------
    -- 生産日報Ｇ開始タグ出力
    -- -----------------------------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'g_nippo' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
--=========================================================================
    -- 【データ】帳票ID
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'chohyo_id';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := gc_report_id ;
--
    -- 【データ】発行日
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'exec_time';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := TO_CHAR(id_now_date, gv_date_format2);
--
    -- 【データ】手配No
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'tehai_no';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := ir_head_data.l_tehai_no;
--
    -- 【データ】伝票区分名称
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'den_kbn';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := ir_head_data.l_den_kbn;
--
    -- 【データ】成績管理部署名称
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'knri_bsho';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := ir_head_data.l_knri_bsho;
--
    -- =====================================================
    -- 部署情報取得処理
    -- =====================================================
    prc_get_busho_data(
        in_last_updated_user  =>   ir_head_data.l_last_updated_by
       ,or_busho_data         =>   lr_busho_data
       ,ov_errbuf             =>   lv_errbuf          -- エラー・メッセージ           --# 固定 #
       ,ov_retcode            =>   lv_retcode         -- リターン・コード             --# 固定 #
       ,ov_errmsg             =>   lv_errmsg          -- ユーザー・エラー・メッセージ  --# 固定 #
    );
--
    IF ( lv_retcode = gv_status_error ) THEN
      RAISE global_process_expt ;
    END IF ;
--
    -- 【データ】担当部署名称
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'dep_nm';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := lr_busho_data.busho_nm;
--
    -- 【データ】完成品品目コード
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'hinmk_cd';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := ir_head_data.l_hinmk_cd;
--
    -- 【データ】完成品品目名称
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'hinmk_nm';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := ir_head_data.l_hinmk_nm;
--
    -- 【データ】ラインNo
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'line_no';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := ir_head_data.l_line_no;
--
    -- 【データ】ライン名称
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'line_nm';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := ir_head_data.l_line_nm;
--
    -- 【データ】納品場所コード
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'set_cd';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := ir_head_data.l_set_cd;
--
    -- 【データ】納品場所名称
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'set_nm';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := ir_head_data.l_set_nm;
--
    -- 【データ】生産開始日
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'make_start_date';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := TO_CHAR(ir_head_data.l_make_start_date,gv_date_format3);
--
    -- 【データ】生産終了日
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'make_end_date';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := TO_CHAR(ir_head_data.l_make_end_date,gv_date_format3);
--
    -- 【データ】賞味期限
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'shoumikigen';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := TO_CHAR(ir_head_data.l_shoumikigen,gv_date_format3);
--
    -- 【データ】タイプ
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'item_type';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := ir_head_data.l_item_type;
--
    -- 【データ】ランク１
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'item_rank1';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := ir_head_data.l_item_rank1;
--
    -- 【データ】ランク２
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'item_rank2';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := ir_head_data.l_item_rank2;
-- 2009/02/04 v1.10 Y.Yamamoto #4 add start
--
    -- 【データ】ランク３
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'item_rank3';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := ir_head_data.l_item_rank3;
-- 2009/02/04 v1.10 Y.Yamamoto #4 add end
--
    -- 【データ】摘要
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'item_tekiyo';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := ir_head_data.l_item_tekiyo;
--
    -- 【データ】ロットNo
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'lot_no';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := ir_head_data.l_lot_no;
--
    -- 【データ】移動場所コード
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'move_cd';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := ir_head_data.l_move_cd;
--
    -- 【データ】移動場所名称
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'move_nm';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := ir_head_data.l_move_nm;
--
    -- 【データ】在庫入数
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'stock_num';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := TO_CHAR(ir_head_data.l_stock_num , gv_num_format2);
--
    -- 【データ】出来高
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'dekidaka';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := TO_CHAR(ir_head_data.l_dekidaka , gv_num_format1);
--
--=========================================================================
    -- -----------------------------------------------------
    -- 明細情報Ｇ開始タグ出力
    -- -----------------------------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_mei_info';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
    -- -----------------------------------------------------
    -- 投入品明細ループ
    -- -----------------------------------------------------
    <<tonyu_data_loop>>
    FOR l_cnt IN 1..it_tonyu_data.COUNT LOOP
--
      -- 明細情報１件目の出力の場合
      IF (l_cnt = 1) THEN
        -- -----------------------------------------------------
        -- 投入品明細Ｇ開始タグ出力
        -- -----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_tonyu_mei';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
      END IF;
--
      -- -----------------------------------------------------
      -- 投入品明細データ開始タグ出力
      -- -----------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'g_tonyu_mei';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
      -- =====================================================
      -- 投入品明細タイトル生成処理
      -- =====================================================
      -- 新缶煎ラインの場合
      IF (ir_head_data.l_shinkansen_kbn = 'Y') THEN
        -- 投入口区分ブレイクチェック
        IF (lv_tounyuguchi_kbn <> it_tonyu_data(l_cnt).l_tounyuguchi_kbn) THEN
          prc_get_mei_title_data(
              in_material_detail_id  =>   it_tonyu_data(l_cnt).l_material_detail_id
             ,ov_mei_title           =>   lv_mei_title
             ,ov_errbuf              =>   lv_errbuf          -- エラー・メッセージ           --# 固定 #
             ,ov_retcode             =>   lv_retcode         -- リターン・コード             --# 固定 #
             ,ov_errmsg              =>   lv_errmsg          -- ユーザー・エラー・メッセージ  --# 固定 #
          );
--
          IF (lv_retcode = gv_status_error) THEN
            -- 関数エラーの場合は例外へ
            RAISE global_process_expt ;
          END IF ;
--
          IF (lv_mei_title IS NULL) THEN
            -- タイトル取得が出来なかった場合は例外へ
            lv_errbuf := gv_err_mei_title_no_data;
            lv_errmsg := gv_err_mei_title_no_data;
            RAISE global_process_expt ;
          END IF;
          -- 取得OKならタイトル出力
          -- 【データ】投入品タイトル
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'tonyu_title';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
          gt_xml_data_table(gl_xml_idx).tag_value := gv_title_header || lv_mei_title || gv_shinkansen_title_tonyu;
--
          -- 処理後現レコード値を保持
          lv_tounyuguchi_kbn := it_tonyu_data(l_cnt).l_tounyuguchi_kbn;
        ELSE
          -- 前レコード同じ場合は、現レコード値を保持
          lv_tounyuguchi_kbn := it_tonyu_data(l_cnt).l_tounyuguchi_kbn;
--
        END IF;
--
      ELSE
      -- 新缶煎ライン以外の場合
        -- 明細情報１件目の出力の場合
        IF (l_cnt = 1) THEN
          -- 【データ】投入品タイトル
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'tonyu_title';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
          gt_xml_data_table(gl_xml_idx).tag_value := gv_tonyu_title;
        END IF;
--
      END IF;
--
      -- 【データ】品目コード
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'tonyu_hinmk_cd';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := it_tonyu_data(l_cnt).l_hinmk_cd ;
--
      -- 【データ】品目略称
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'tonyu_hinmk_nm';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := it_tonyu_data(l_cnt).l_hinmk_nm ;
--
      -- 【データ】ロットNo
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'tonyu_lot_no';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := it_tonyu_data(l_cnt).l_lot_no ;
--
      -- 【データ】製造日
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'tonyu_make_date';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := TO_CHAR(it_tonyu_data(l_cnt).l_make_date ,gv_date_format3);
--
      -- 【データ】在庫入数
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'tonyu_stock';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := TO_CHAR(it_tonyu_data(l_cnt).l_stock ,gv_num_format2);
--
      -- 【データ】総数
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'tonyu_total';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := TO_CHAR(it_tonyu_data(l_cnt).l_total ,gv_num_format1);
      -- 投入品明細総数の合計
      ln_tounyu_total := ln_tounyu_total + it_tonyu_data(l_cnt).l_total ;
-- 2008/12/17 v1.7 D.Nihei ADD START
      IF ( it_tonyu_data(l_cnt).l_unit = gv_um_hon ) THEN
        ln_tounyu_net_total := ln_tounyu_net_total + ( it_tonyu_data(l_cnt).l_total * it_tonyu_data(l_cnt).l_net / 1000 );
      END IF;
-- 2008/12/17 v1.7 D.Nihei ADD END
--
      -- 【データ】単位
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'tonyu_unit';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := it_tonyu_data(l_cnt).l_unit ;
--
      -- 【タグ】投入品明細データ終了タグ
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := '/g_tonyu_mei';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
      -- 投入明細最終行の処理の場合
      IF (l_cnt = it_tonyu_data.COUNT) THEN
        -- -----------------------------------------------------
        -- 投入品明細Ｇ終了タグ出力
        -- -----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_tonyu_mei';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
      END IF;
--
    END LOOP tonyu_data_loop ;
--
--=========================================================================
    -- 投入明細が存在しない場合は、小計行を出力しない
    IF (it_tonyu_data.COUNT <> 0) THEN
      -- -----------------------------------------------------
      -- 投入品明細合計データ開始タグ出力
      -- -----------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'g_tonyu_sum';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
      -- 【データ】投入品明細合計数
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'tonyu_sum';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := TO_CHAR(ln_tounyu_total ,gv_num_format1);
--
      -- -----------------------------------------------------
      -- 投入品明細合計データ終了タグ出力
      -- -----------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := '/g_tonyu_sum';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
    END IF;
--
--=========================================================================
    -- -----------------------------------------------------
    -- 戻入品明細ループ
    -- -----------------------------------------------------
    <<reinyu_tonyu_data_loop>>
    FOR l_cnt IN 1..it_reinyu_tonyu_data.COUNT LOOP
--
      -- 明細情報１件目の出力の場合
      IF (l_cnt = 1) THEN
        -- -----------------------------------------------------
        -- 戻入（投入）品明細Ｇ開始タグ出力
        -- -----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_modori_mei';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
      END IF;
--
      -- -----------------------------------------------------
      -- 戻入（投入）明細データ開始タグ出力
      -- -----------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'g_modori_mei';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
      -- =====================================================
      -- 戻入品明細タイトル生成処理
      -- =====================================================
      -- 新缶煎ラインの場合
      IF (ir_head_data.l_shinkansen_kbn = 'Y') THEN
        -- 投入口区分ブレイクチェック
        IF (lv_tounyuguchi_kbn <> it_reinyu_tonyu_data(l_cnt).l_tounyuguchi_kbn) THEN
          prc_get_mei_title_data(
              in_material_detail_id  =>   it_reinyu_tonyu_data(l_cnt).l_material_detail_id
             ,ov_mei_title           =>   lv_mei_title
             ,ov_errbuf              =>   lv_errbuf          -- エラー・メッセージ            --# 固定 #
             ,ov_retcode             =>   lv_retcode         -- リターン・コード              --# 固定 #
             ,ov_errmsg              =>   lv_errmsg          -- ユーザー・エラー・メッセージ  --# 固定 #
          );
--
          IF (lv_retcode = gv_status_error) THEN
            -- 関数エラーの場合は例外へ
            RAISE global_process_expt ;
          END IF ;
--
          IF (lv_mei_title IS NULL) THEN
            -- タイトル取得が出来なかった場合は例外へ
            lv_errbuf := gv_err_mei_title_no_data;
            lv_errmsg := gv_err_mei_title_no_data;
            RAISE global_process_expt ;
          END IF;
          -- 取得OKならタイトル出力
          -- 【データ】戻入（投入）タイトル
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'modori_title';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
          gt_xml_data_table(gl_xml_idx).tag_value := gv_title_header || lv_mei_title || gv_shinkansen_title_reinyu;
--
          -- 処理後現レコード値を保持
          lv_tounyuguchi_kbn := it_reinyu_tonyu_data(l_cnt).l_tounyuguchi_kbn;
        ELSE
          -- 前レコード同じ場合は、現レコード値を保持
          lv_tounyuguchi_kbn := it_reinyu_tonyu_data(l_cnt).l_tounyuguchi_kbn;
--
        END IF;
--
      ELSE
      -- 新缶煎ライン以外の場合
        -- 明細情報１件目の出力の場合
        IF (l_cnt = 1) THEN
          -- 【データ】戻入（投入）タイトル
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'modori_title';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
          gt_xml_data_table(gl_xml_idx).tag_value := gv_reinyu_title;
        END IF;
--
      END IF;
--
      -- 【データ】品目コード
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'modori_hinmk_cd';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := it_reinyu_tonyu_data(l_cnt).l_hinmk_cd ;
--
      -- 【データ】品目略称
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'modori_hinmk_nm';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := it_reinyu_tonyu_data(l_cnt).l_hinmk_nm ;
--
      -- 【データ】ロットNo
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'modori_lot_no';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := it_reinyu_tonyu_data(l_cnt).l_lot_no ;
--
      -- 【データ】製造日
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'modori_make_date';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := TO_CHAR(it_reinyu_tonyu_data(l_cnt).l_make_date ,gv_date_format3);
--
      -- 【データ】在庫入数
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'modori_stock';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := TO_CHAR(it_reinyu_tonyu_data(l_cnt).l_stock ,gv_num_format2);
--
      -- 【データ】総数
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'modori_total';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := TO_CHAR(it_reinyu_tonyu_data(l_cnt).l_total ,gv_num_format1);
      -- 戻入品明細総数の合計
      ln_reinyu_tounyu_total := ln_reinyu_tounyu_total + it_reinyu_tonyu_data(l_cnt).l_total ;
-- 2008/12/17 v1.7 D.Nihei ADD START
      IF ( it_reinyu_tonyu_data(l_cnt).l_unit = gv_um_hon ) THEN
        ln_rei_tou_net_total := ln_rei_tou_net_total + ( it_reinyu_tonyu_data(l_cnt).l_total * it_reinyu_tonyu_data(l_cnt).l_net / 1000 );
      END IF;
-- 2008/12/17 v1.7 D.Nihei ADD END
--
      -- 【データ】単位
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'modori_unit';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := it_reinyu_tonyu_data(l_cnt).l_unit ;
--
      -- 【タグ】戻入（投入）明細データ終了タグ
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := '/g_modori_mei';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
      -- 戻入（投入）明細最終行の処理の場合
      IF (l_cnt = it_reinyu_tonyu_data.COUNT) THEN
        -- -----------------------------------------------------
        -- 戻入（投入）明細Ｇ終了タグ出力
        -- -----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_modori_mei';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
      END IF;
--
    END LOOP reinyu_tonyu_data_loop ;
--
--=========================================================================
    -- 戻入明細が存在しない場合は、小計行を出力しない
    IF (it_reinyu_tonyu_data.COUNT <> 0) THEN
      -- -----------------------------------------------------
      -- 戻入（投入）明細合計データ開始タグ出力
      -- -----------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'g_modori_sum';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
      -- 【データ】戻入（投入）明細合計数
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'modori_sum';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := TO_CHAR(ln_reinyu_tounyu_total ,gv_num_format1);
--
      -- -----------------------------------------------------
      -- 戻入（投入）明細合計データ終了タグ出力
      -- -----------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := '/g_modori_sum';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
    END IF;
-- 2008/10/28 v1.5 D.Nihei ADD START
    ln_invest_total := NVL(ln_tounyu_total, 0) - NVL(ln_reinyu_tounyu_total, 0);
-- 2008/10/28 v1.5 D.Nihei ADD END
-- 2008/12/17 v1.7 D.Nihei ADD START
    IF ( NVL(ln_tounyu_net_total, 0) > 0 ) THEN
      ln_invest_total := NVL(ln_tounyu_net_total, 0) - NVL(ln_rei_tou_net_total, 0);
    END IF;
-- 2008/12/17 v1.7 D.Nihei ADD END
--
--=========================================================================
    -- -----------------------------------------------------
    -- 副産物明細ループ
    -- -----------------------------------------------------
    <<fukusanbutu_data_loop>>
    FOR l_cnt IN 1..it_fukusanbutu_data.COUNT LOOP
--
      -- 明細情報１件目の出力の場合
      IF (l_cnt = 1) THEN
        -- -----------------------------------------------------
        -- 副産物明細Ｇ開始タグ出力
        -- -----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_fsanbutu_mei';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
      END IF;
--
      -- -----------------------------------------------------
      -- 副産物明細データ開始タグ出力
      -- -----------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'g_fsanbutu_mei';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
      -- 明細情報１件目の出力の場合
      IF (l_cnt = 1) THEN
        -- 【データ】副産物タイトル
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'fsanbutu_title';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := gv_fukusanbutu_title;
      END IF;
--
      -- 【データ】品目コード
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'fsanbutu_hinmk_cd';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := it_fukusanbutu_data(l_cnt).l_hinmk_cd ;
--
      -- 【データ】品目略称
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'fsanbutu_hinmk_nm';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := it_fukusanbutu_data(l_cnt).l_hinmk_nm ;
--
      -- 【データ】ロットNo
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'fsanbutu_lot_no';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := it_fukusanbutu_data(l_cnt).l_lot_no ;
--
      -- 【データ】製造日
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'fsanbutu_make_date';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := TO_CHAR(it_fukusanbutu_data(l_cnt).l_make_date ,gv_date_format3);
--
      -- 【データ】在庫入数
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'fsanbutu_stock';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := TO_CHAR(it_fukusanbutu_data(l_cnt).l_stock ,gv_num_format2);
--
      -- 【データ】総数
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'fsanbutu_total';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := TO_CHAR(it_fukusanbutu_data(l_cnt).l_total ,gv_num_format1);
      -- 副産物明細総数の合計
      ln_fukusanbutu_total := ln_fukusanbutu_total + it_fukusanbutu_data(l_cnt).l_total ;
--
      -- 【データ】単位
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'fsanbutu_unit';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := it_fukusanbutu_data(l_cnt).l_unit ;
--
      -- 【データ】割合
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'fsanbutu_percent';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      -- （副産物数／総投入品数）×100（少数点第3位で四捨五入）
-- 2008/10/28 v1.5 D.Nihei ADD START
--      gt_xml_data_table(gl_xml_idx).tag_value :=
---- 2008/06/04 D.Nihei MOD START
----                  TO_CHAR( ROUND( ( (it_fukusanbutu_data(l_cnt).l_total / ln_tounyu_total ) * 100 ) , 2)
--                  TO_CHAR( ROUND( ( (it_fukusanbutu_data(l_cnt).l_total / (ln_tounyu_total - ln_reinyu_tounyu_total) ) * 100 ) , 2)
---- 2008/06/04 D.Nihei MOD END
--                          ,gv_num_format3);
      IF ( ( NVL(it_fukusanbutu_data(l_cnt).l_total, 0) = 0 ) OR ( ln_invest_total = 0 ) ) THEN
        gt_xml_data_table(gl_xml_idx).tag_value := 0;
      ELSE
        gt_xml_data_table(gl_xml_idx).tag_value := TO_CHAR( ROUND( ( (it_fukusanbutu_data(l_cnt).l_total / ln_invest_total ) * 100 ) , 2), gv_num_format3);
      END IF;
-- 2008/10/28 v1.5 D.Nihei ADD END
--
      -- 【タグ】副産物明細データ終了タグ
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := '/g_fsanbutu_mei';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
      -- 副産物明細最終行の処理の場合
      IF (l_cnt = it_fukusanbutu_data.COUNT) THEN
        -- -----------------------------------------------------
        -- 副産物明細Ｇ終了タグ出力
        -- -----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_fsanbutu_mei';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
      END IF;
--
    END LOOP fukusanbutu_data_loop ;
--
--=========================================================================
    -- 副産物明細が存在しない場合は、小計行を出力しない
    IF it_fukusanbutu_data.COUNT <> 0 THEN
      -- -----------------------------------------------------
      -- 副産物明細合計データ開始タグ出力
      -- -----------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'g_fsanbutu_sum';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
      -- 【データ】副産物明細合計数
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'fsanbutu_sum';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := TO_CHAR(ln_fukusanbutu_total ,gv_num_format1);
--
      -- 【データ】合計割合
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'fsanbutu_sum_percent';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      -- （副産物明細合計数／総投入品数）×100（少数点第3位で四捨五入）
-- 2008/10/28 v1.5 D.Nihei ADD START
--      gt_xml_data_table(gl_xml_idx).tag_value :=
---- 2008/06/04 D.Nihei MOD START
----                  TO_CHAR( ROUND( ( (ln_fukusanbutu_total / ln_tounyu_total ) * 100 ) , 2)
--                  TO_CHAR( ROUND( ( (ln_fukusanbutu_total / (ln_tounyu_total - ln_reinyu_tounyu_total)) * 100 ) , 2)
---- 2008/06/04 D.Nihei MOD END
--                          ,gv_num_format3);
      IF ( ( NVL(ln_fukusanbutu_total, 0) = 0 ) OR ( ln_invest_total = 0 ) ) THEN
        gt_xml_data_table(gl_xml_idx).tag_value := 0;
      ELSE
        gt_xml_data_table(gl_xml_idx).tag_value := TO_CHAR( ROUND( ( (ln_fukusanbutu_total / ln_invest_total ) * 100 ) , 2), gv_num_format3);
      END IF;
-- 2008/10/28 v1.5 D.Nihei ADD END
--
      -- -----------------------------------------------------
      -- 副産物明細合計データ終了タグ出力
      -- -----------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := '/g_fsanbutu_sum';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
    END IF;
--
--=========================================================================
    -- -----------------------------------------------------
    -- 打込明細ループ
    -- -----------------------------------------------------
    <<utikomi_data_loop>>
    FOR l_cnt IN 1..it_utikomi_data.COUNT LOOP
--
      IF (l_cnt = 1) THEN
        -- -----------------------------------------------------
        -- 打込明細Ｇ開始タグ出力
        -- -----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_utikomi_mei';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
      END IF;
--
      -- -----------------------------------------------------
      -- 打込明細データ開始タグ出力
      -- -----------------------------------------------------
      -- 行開始タグ
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'g_utikomi_mei';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
      -- 明細情報１件目の出力の場合
      IF (l_cnt = 1) THEN
        -- 【データ】打込タイトル
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'utikomi_title';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := gv_utikomi_title ;
      END IF;
--
      -- 【データ】品目コード
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'utikomi_hinmk_cd';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := it_utikomi_data(l_cnt).l_hinmk_cd;
--
      -- 【データ】品目略称
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'utikomi_hinmk_nm';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := it_utikomi_data(l_cnt).l_hinmk_nm;
--
      -- 【データ】ロットNo
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'utikomi_lot_no';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := it_utikomi_data(l_cnt).l_lot_no;
--
      -- 【データ】製造日
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'utikomi_make_date';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := TO_CHAR(it_utikomi_data(l_cnt).l_make_date ,gv_date_format3);
--
      -- 【データ】在庫入数
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'utikomi_stock';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := TO_CHAR(it_utikomi_data(l_cnt).l_stock ,gv_num_format2);
--
      -- 【データ】総数
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'utikomi_total';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := TO_CHAR(it_utikomi_data(l_cnt).l_total ,gv_num_format1);
      -- 打込明細総数の合計
      ln_utikomi_total := ln_utikomi_total + it_utikomi_data(l_cnt).l_total ;
--
      -- 【データ】単位
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'utikomi_unit';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := it_utikomi_data(l_cnt).l_unit;
--
      -- 【タグ】打込明細データ終了タグ
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := '/g_utikomi_mei';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
      IF (l_cnt = it_utikomi_data.COUNT) THEN
        -- -----------------------------------------------------
        -- 打込明細Ｇ終了タグ出力
        -- -----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_utikomi_mei';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
      END IF;
--
    END LOOP utikomi_data_loop ;
--
--=========================================================================
    -- 打込明細が存在しない場合は、小計行を出力しない
    IF (it_utikomi_data.COUNT <> 0) THEN
      -- -----------------------------------------------------
      -- 打込明細合計データ開始タグ出力
      -- -----------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'g_utikomi_sum';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
      -- 【データ】打込明細合計数
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'utikomi_sum';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := TO_CHAR(ln_utikomi_total ,gv_num_format1);
--
      -- -----------------------------------------------------
      -- 打込明細合計データ終了タグ出力
      -- -----------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := '/g_utikomi_sum';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
    END IF;
--
--=========================================================================
    -- -----------------------------------------------------
    -- 仕上数データ開始タグ出力
    -- -----------------------------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'g_siagesuu_mei';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
    -- 【データ】仕上数
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'siagesuu_total';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    -- 仕上数計算
-- Changed 2008/05/29
--    -- （ヘッダの完成品品目の「NET」項目×ヘッダ出来高　／　1000）－　打込総数
--    ln_siage_total := ((ir_head_data.l_dekidaka * ir_head_data.l_net) / 1000) - ln_utikomi_total ;
-- 2008/12/02 v1.6 D.Nihei MOD START 本番障害#325
--    IF ir_head_data.l_item_class = gv_hinmoku_kbn_seihin THEN
--      -- 品目区分＝「製品」の時
    IF ( ( ir_head_data.l_item_class = gv_hinmoku_kbn_seihin ) AND ( ir_head_data.l_item_unit = gv_um_hon ) ) THEN
      -- 品目区分＝「製品」で単位が「本」の時
-- 2008/12/02 v1.6 D.Nihei MOD START 本番障害#325
      -- （ヘッダの完成品品目の「NET」項目×ヘッダ出来高　／　1000）－　打込総数
      ln_siage_total := ((ir_head_data.l_dekidaka * ir_head_data.l_net) / 1000) - ln_utikomi_total ;
    ELSE
      -- 品目区分＜＞「製品」の時
      ln_siage_total := ir_head_data.l_dekidaka  - ln_utikomi_total ;
    END IF;
-- Changed 2008/05/29
    gt_xml_data_table(gl_xml_idx).tag_value := TO_CHAR(ROUND(ln_siage_total , 3) ,gv_num_format1);
--
    -- 【データ】仕上数単位
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'siagesuu_unit';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := gv_unit_siage ;
--
    -- 【データ】仕上数割合
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'siagesuu_percent';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    -- （仕上数／総投入品数）×100（少数点第3位で四捨五入）
-- 2008/10/28 v1.5 D.Nihei ADD START
--    gt_xml_data_table(gl_xml_idx).tag_value :=
---- 2008/06/04 D.Nihei MOD START
----                TO_CHAR( ROUND(  (ln_siage_total / ln_tounyu_total) * 100 , 2)
--                TO_CHAR( ROUND(  (ln_siage_total / (ln_tounyu_total - ln_reinyu_tounyu_total)) * 100 , 2)
--                        ,gv_num_format3);
---- 2008/06/04 D.Nihei MOD END
      IF ( ( NVL(ln_siage_total, 0) = 0 ) OR ( ln_invest_total = 0 ) ) THEN
        gt_xml_data_table(gl_xml_idx).tag_value := 0;
      ELSE
        gt_xml_data_table(gl_xml_idx).tag_value := TO_CHAR( ROUND( ( (ln_siage_total / ln_invest_total ) * 100 ) , 2), gv_num_format3);
      END IF;
-- 2008/10/28 v1.5 D.Nihei ADD END
--
    -- -----------------------------------------------------
    -- 仕上数データ終了タグ出力
    -- -----------------------------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/g_siagesuu_mei';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
--=========================================================================
    -- -----------------------------------------------------
    -- 戻入（打込）明細ループ
    -- -----------------------------------------------------
    <<reinyu_utikomi_data_loop>>
    FOR l_cnt IN 1..it_reinyu_utikomi_data.COUNT LOOP
--
      IF (l_cnt = 1) THEN
        -- -----------------------------------------------------
        -- 戻入（打込）明細Ｇ開始タグ出力
        -- -----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_modori_utikomi_mei';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
      END IF;
--
      -- -----------------------------------------------------
      -- 戻入（打込）明細データ開始タグ出力
      -- -----------------------------------------------------
      -- 行開始タグ
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'g_modori_utikomi_mei';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
      -- 明細情報１件目の出力の場合
      IF (l_cnt = 1) THEN
        -- 【データ】戻入（打込）タイトル
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'modori_utikomi_title';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := gv_reinyu_title ;
      END IF;
--
      -- 【データ】品目コード
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'modori_utikomi_hinmk_cd';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := it_reinyu_utikomi_data(l_cnt).l_hinmk_cd;
--
      -- 【データ】品目略称
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'modori_utikomi_hinmk_nm';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := it_reinyu_utikomi_data(l_cnt).l_hinmk_nm;
--
      -- 【データ】ロットNo
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'modori_utikomi_lot_no';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := it_reinyu_utikomi_data(l_cnt).l_lot_no;
--
      -- 【データ】製造日
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'modori_utikomi_make_date';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := TO_CHAR(it_reinyu_utikomi_data(l_cnt).l_make_date
                                                        ,gv_date_format3);
--
      -- 【データ】在庫入数
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'modori_utikomi_stock';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := TO_CHAR(it_reinyu_utikomi_data(l_cnt).l_stock
                                                        ,gv_num_format2);
--
      -- 【データ】総数
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'modori_utikomi_total';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := TO_CHAR(it_reinyu_utikomi_data(l_cnt).l_total
                                                        ,gv_num_format1);
      -- 戻入（打込）明細総数の合計
      ln_reinyu_utikomi_total := ln_reinyu_utikomi_total + it_reinyu_utikomi_data(l_cnt).l_total ;
--
      -- 【データ】単位
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'modori_utikomi_unit';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := it_reinyu_utikomi_data(l_cnt).l_unit;
--
      -- 【タグ】戻入（打込）明細データ終了タグ
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := '/g_modori_utikomi_mei';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
      IF (l_cnt = it_reinyu_utikomi_data.COUNT) THEN
        -- -----------------------------------------------------
        -- 戻入（打込）明細Ｇ終了タグ出力
        -- -----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_modori_utikomi_mei';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
      END IF;
--
    END LOOP reinyu_utikomi_data_loop ;
--
--=========================================================================
--
    -- 戻入（打込）明細が存在しない場合は、小計行を出力しない
    IF (it_reinyu_utikomi_data.COUNT <> 0) THEN
      -- -----------------------------------------------------
      -- 戻入（打込）明細合計データ開始タグ出力
      -- -----------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'g_modori_utikomi_sum';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
      -- 【データ】戻入（打込）明細合計数
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'modori_utikomi_sum';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := TO_CHAR(ln_reinyu_utikomi_total ,gv_num_format1);
--
      -- -----------------------------------------------------
      -- 戻入（打込）明細合計データ終了タグ出力
      -- -----------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := '/g_modori_utikomi_sum';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
    END IF;
--
--=========================================================================
    -- -----------------------------------------------------
    -- 切／計込明細データ開始タグ出力
    -- -----------------------------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'g_kirikeikomi_mei';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
    -- 【データ】切／計込明細合計
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'kirikeikomi_total';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    -- 切／計込明細合計の計算
    -- 投入合計－（仕上数＋副産物計）の値をセット
-- 2008/12/17 D.Nihei MOD START
---- 2008/06/04 D.Nihei MOD START
----    ln_kirikeikomi_total := ln_tounyu_total - (ln_siage_total + ln_fukusanbutu_total) ;
--    ln_kirikeikomi_total := ln_tounyu_total - (ln_siage_total + ln_fukusanbutu_total) - (ln_reinyu_tounyu_total + ln_reinyu_utikomi_total);
    ln_kirikeikomi_total := ln_invest_total - (ln_siage_total + ln_fukusanbutu_total) + ln_reinyu_utikomi_total;
---- 2008/06/04 D.Nihei MOD END
-- 2008/12/17 D.Nihei MOD END
    gt_xml_data_table(gl_xml_idx).tag_value := TO_CHAR(ln_kirikeikomi_total ,gv_num_format1);
--
    -- 【データ】切／計込明細単位
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'kirikeikomi_unit';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := gv_unit_kirikeikomi ;
--
    -- 【データ】切／計込明細割合
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'kirikeikomi_percent';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      -- 切／計込明細合計　／　投入合計　＊　100（少数点第3位で四捨五入）の値を出力
-- 2008/10/28 v1.5 D.Nihei ADD START
--    gt_xml_data_table(gl_xml_idx).tag_value :=
---- 2008/06/04 D.Nihei MOD START
----                TO_CHAR( ROUND( (ln_kirikeikomi_total / ln_tounyu_total) * 100 , 2)
--                TO_CHAR( ROUND( (ln_kirikeikomi_total / (ln_tounyu_total - ln_reinyu_tounyu_total)) * 100 , 2)
---- 2008/06/04 D.Nihei MOD END
--                        ,gv_num_format3);
      IF ( ( NVL(ln_kirikeikomi_total, 0) = 0 ) OR ( ln_invest_total = 0 ) ) THEN
        gt_xml_data_table(gl_xml_idx).tag_value := 0;
      ELSE
        gt_xml_data_table(gl_xml_idx).tag_value := TO_CHAR( ROUND( ( (ln_kirikeikomi_total / ln_invest_total ) * 100 ) , 2), gv_num_format3);
      END IF;
-- 2008/10/28 v1.5 D.Nihei ADD END
--
    -- -----------------------------------------------------
    -- 切／計込明細データ終了タグ出力
    -- -----------------------------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/g_kirikeikomi_mei';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
--=========================================================================
    -- -----------------------------------------------------
    -- 切／計込合計データ開始タグ出力
    -- -----------------------------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'g_kirikeikomi_sum';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
    -- 【データ】副産物・切れ計
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'kirikeikomi_sum';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    -- 副産物計 + 切／計込明細合計をセット
    gt_xml_data_table(gl_xml_idx).tag_value := TO_CHAR(ln_fukusanbutu_total + ln_kirikeikomi_total
                                                      ,gv_num_format1);
--
    -- 【データ】切／計込合計割合
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'kirikeikomi_sum_percent';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      -- 副産物・切れ計　／　「３」の投入計　＊　100（少数点第3位で四捨五入）の値を出力
-- 2008/10/28 v1.5 D.Nihei ADD START
--    gt_xml_data_table(gl_xml_idx).tag_value := 
---- 2008/06/04 D.Nihei MOD START
----                TO_CHAR( ROUND(((ln_fukusanbutu_total + ln_kirikeikomi_total) / ln_tounyu_total) * 100 , 2)
--                TO_CHAR( ROUND(((ln_fukusanbutu_total + ln_kirikeikomi_total) / (ln_tounyu_total - ln_reinyu_tounyu_total)) * 100 , 2)
---- 2008/06/04 D.Nihei MOD END
--                        ,gv_num_format3);
      IF ( ( ln_fukusanbutu_total + ln_kirikeikomi_total = 0 ) OR ( ln_invest_total = 0 ) ) THEN
        gt_xml_data_table(gl_xml_idx).tag_value := 0;
      ELSE
        gt_xml_data_table(gl_xml_idx).tag_value := TO_CHAR( ROUND(((ln_fukusanbutu_total + ln_kirikeikomi_total) / ln_invest_total) * 100 , 2), gv_num_format3);
      END IF;
-- 2008/10/28 v1.5 D.Nihei ADD END
--
    -- -----------------------------------------------------
    -- 切／計込合計データ終了タグ出力
    -- -----------------------------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/g_kirikeikomi_sum';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
--=========================================================================
    -- -----------------------------------------------------
    -- 出来高データ開始タグ出力
    -- -----------------------------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'g_dekidaka_mei';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
    -- 【データ】出来高数
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'dekidaka_total';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := TO_CHAR(ir_head_data.l_dekidaka ,gv_num_format1);  -- ヘッダと同じ値
--
    -- 【データ】出来高単位
    -- 帳票上内部的に存在しているが、タグ出力しない。
--    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
--    gt_xml_data_table(gl_xml_idx).tag_name  := 'dekidaka_unit';
--    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
--    gt_xml_data_table(gl_xml_idx).tag_value := ir_head_data.l_item_unit ;
--
    -- -----------------------------------------------------
    -- 出来高データ終了タグ出力
    -- -----------------------------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/g_dekidaka_mei';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
--=========================================================================
    -- -----------------------------------------------------
    -- 投入資材明細ループ
    -- -----------------------------------------------------
    <<tonyu_sizai_data_loop>>
    FOR l_cnt IN 1..it_tonyu_sizai_data.COUNT LOOP
--
      -- 先頭行のみ実施
      IF (l_cnt = 1) THEN
        -- -----------------------------------------------------
        -- 投入資材明細Ｇ開始タグ出力
        -- -----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_tonyu_sizai_mei';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
      END IF;
--
      -- -----------------------------------------------------
      -- 投入資材明細データ開始タグ出力
      -- -----------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'g_tonyu_sizai_mei';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
      -- 先頭行のみ実施
      IF (l_cnt = 1) THEN
        -- 【データ】投入資材タイトル
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'tonyu_sizai_title';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := gv_sizai_title_tounyu;
      END IF;
--
      -- 【データ】品目コード
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'tonyu_sizai_hinmk_cd';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := it_tonyu_sizai_data(l_cnt).l_hinmk_cd;
--
      -- 【データ】品目略称
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'tonyu_sizai_hinmk_nm';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := it_tonyu_sizai_data(l_cnt).l_hinmk_nm;
--
      -- 【データ】総数
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'tonyu_sizai_total';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := TO_CHAR(it_tonyu_sizai_data(l_cnt).l_total ,gv_num_format1);
--
      -- 【データ】単位
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'tonyu_sizai_unit';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := it_tonyu_sizai_data(l_cnt).l_unit;
--
      -- 【タグ】投入資材明細データ終了タグ
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := '/g_tonyu_sizai_mei';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
      IF (l_cnt = it_tonyu_sizai_data.COUNT) THEN
        -- -----------------------------------------------------
        -- 投入資材明細Ｇ終了タグ出力
        -- -----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_tonyu_sizai_mei';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
      END IF;
--
    END LOOP tonyu_sizai_data_loop ;
--
--=========================================================================
    -- -----------------------------------------------------
    -- 戻入資材明細ループ
    -- -----------------------------------------------------
    <<reinyu_sizai_data_loop>>
    FOR l_cnt IN 1..it_reinyu_sizai_data.COUNT LOOP
--
      -- 先頭行のみ実施
      IF (l_cnt = 1) THEN
        -- -----------------------------------------------------
        -- 戻入資材明細Ｇ開始タグ出力
        -- -----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_modori_sizai_mei';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
      END IF;
--
      -- -----------------------------------------------------
      -- 戻入資材明細データ開始タグ出力
      -- -----------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'g_modori_sizai_mei';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
      -- 先頭行のみ実施
      IF (l_cnt = 1) THEN
        -- 【データ】戻入資材タイトル
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'modori_sizai_title';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := gv_sizai_title_reinyu;
      END IF;
--
      -- 【データ】品目コード
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'modori_sizai_hinmk_cd';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := it_reinyu_sizai_data(l_cnt).l_hinmk_cd;
--
      -- 【データ】品目略称
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'modori_sizai_hinmk_nm';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := it_reinyu_sizai_data(l_cnt).l_hinmk_nm;
--
      -- 【データ】総数
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'modori_sizai_total';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := TO_CHAR(it_reinyu_sizai_data(l_cnt).l_total ,gv_num_format1);
--
      -- 【データ】単位
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'modori_sizai_unit';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := it_reinyu_sizai_data(l_cnt).l_unit;
--
      -- 【タグ】戻入資材明細データ終了タグ
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := '/g_modori_sizai_mei';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
      IF (l_cnt = it_reinyu_sizai_data.COUNT) THEN
        -- -----------------------------------------------------
        -- 戻入資材明細Ｇ終了タグ出力
        -- -----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_modori_sizai_mei';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
      END IF;
--
    END LOOP reinyu_sizai_data_loop ;
--
--=========================================================================
    -- -----------------------------------------------------
    -- 製造不良資材明細ループ
    -- -----------------------------------------------------
    <<seizou_furyo_data_loop>>
    FOR l_cnt IN 1..it_seizou_furyo_data.COUNT LOOP
--
      -- 先頭行のみ実施
      IF (l_cnt = 1) THEN
        -- -----------------------------------------------------
        -- 製造不良資材明細Ｇ開始タグ出力
        -- -----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_make_furyou_mei';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
      END IF;
--
      -- -----------------------------------------------------
      -- 製造不良資材明細データ開始タグ出力
      -- -----------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'g_make_furyou_mei';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
      -- 先頭行のみ実施
      IF (l_cnt = 1) THEN
        -- 【データ】製造不良資材タイトル
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'make_furyou_title';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := gv_sizai_title_seizofuryo;
      END IF;
--
      -- 【データ】品目コード
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'make_furyou_hinmk_cd';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := it_seizou_furyo_data(l_cnt).l_hinmk_cd;
--
      -- 【データ】品目略称
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'make_furyou_hinmk_nm';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := it_seizou_furyo_data(l_cnt).l_hinmk_nm;
--
      -- 【データ】総数
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'make_furyou_total';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := TO_CHAR(it_seizou_furyo_data(l_cnt).l_total ,gv_num_format1);
--
      -- 【データ】単位
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'make_furyou_unit';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := it_seizou_furyo_data(l_cnt).l_unit;
--
      -- 【タグ】製造不良資材明細データ終了タグ
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := '/g_make_furyou_mei';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
      IF (l_cnt = it_seizou_furyo_data.COUNT) THEN
        -- -----------------------------------------------------
        -- 製造不良資材明細Ｇ終了タグ出力
        -- -----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_make_furyou_mei';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
      END IF;
--
    END LOOP seizou_furyo_data_loop ;
--
--=========================================================================
    -- -----------------------------------------------------
    -- 業者不良資材明細ループ
    -- -----------------------------------------------------
    <<gyousha_furyo_data_loop>>
    FOR l_cnt IN 1..it_gyousha_furyo_data.COUNT LOOP
--
      -- 先頭行のみ実施
      IF (l_cnt = 1) THEN
        -- -----------------------------------------------------
        -- 業者不良資材明細Ｇ開始タグ出力
        -- -----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_gyosya_furyou_mei';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
      END IF;
--
      -- -----------------------------------------------------
      -- 業者不良資材明細データ開始タグ出力
      -- -----------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'g_gyosya_furyou_mei';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
      -- 先頭行のみ実施
      IF (l_cnt = 1) THEN
        -- 【データ】業者不良資材タイトル
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'gyosya_furyou_title';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := gv_sizai_title_gyoshafuryo;
      END IF;
--
      -- 【データ】品目コード
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'gyosya_furyou_hinmk_cd';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := it_gyousha_furyo_data(l_cnt).l_hinmk_cd;
--
      -- 【データ】品目略称
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'gyosya_furyou_hinmk_nm';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := it_gyousha_furyo_data(l_cnt).l_hinmk_nm;
--
      -- 【データ】総数
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'gyosya_furyou_total';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := TO_CHAR(it_gyousha_furyo_data(l_cnt).l_total
                                                        ,gv_num_format1);
--
      -- 【データ】単位
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'gyosya_furyou_unit';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := it_gyousha_furyo_data(l_cnt).l_unit;
--
      -- 【タグ】業者不良資材明細データ終了タグ
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := '/g_gyosya_furyou_mei';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
      IF (l_cnt = it_gyousha_furyo_data.COUNT) THEN
        -- -----------------------------------------------------
        -- 業者不良資材明細Ｇ終了タグ出力
        -- -----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_gyosya_furyou_mei';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
      END IF;
--
    END LOOP gyousha_furyo_data_loop ;
--
--=========================================================================
--
    -- =====================================================
    -- 生産日報情報出力終了処理
    -- =====================================================
    ------------------------------
    -- 明細情報Ｇ終了タグ
    ------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_mei_info' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
    ------------------------------
    -- 生産日報Ｇ終了タグ
    ------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/g_nippo' ;
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
--
  /**********************************************************************************
   * Procedure Name   : prc_create_zeroken_xml_data
   * Description      : 取得件数０件時ＸＭＬデータ作成
   ***********************************************************************************/
  PROCEDURE prc_create_zeroken_xml_data
    (
      ir_param          IN         type_param_rec    -- レコード  ：パラメータ
     ,ov_errbuf         OUT NOCOPY VARCHAR2          -- エラー・メッセージ           --# 固定 #
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
    -- 帳票タイトル
    lv_chohyo_title           VARCHAR2(10);
--
  BEGIN
--
    -- =====================================================
    -- 項目データ抽出・出力処理
    -- =====================================================
    -- -----------------------------------------------------
    -- 依頼先Ｇ開始タグ出力
    -- -----------------------------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'g_nippo' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
    -- -----------------------------------------------------
    -- 明細Ｇ開始タグ出力
    -- -----------------------------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_mei_info';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
    ------------------------------
    -- 明細ＬＧ終了タグ
    ------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_mei_info' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
    ------------------------------
    -- メッセージ出力タグ
    ------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'message';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := xxcmn_common_pkg.get_msg( gc_application_cmn
                                                                        ,'APP-XXCMN-10122'  ) ;
--
    ------------------------------
    -- 依頼先Ｇ終了タグ
    ------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/g_nippo' ;
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
  END prc_create_zeroken_xml_data ;
--
--
--
  /**********************************************************************************
   * Procedure Name   : prc_get_head_data
   * Description      : ヘッダー情報取得
   ***********************************************************************************/
  PROCEDURE prc_get_head_data
    (
      ir_param         IN         type_param_rec         -- 入力パラメータ
     ,ot_head_data     OUT NOCOPY type_head_data_tbl     -- 取得データ配列
     ,ov_errbuf        OUT NOCOPY VARCHAR2               -- エラー・メッセージ             --# 固定 #
     ,ov_retcode       OUT NOCOPY VARCHAR2               -- リターン・コード               --# 固定 #
     ,ov_errmsg        OUT NOCOPY VARCHAR2               -- ユーザー・エラー・メッセージ   --# 固定 #
    )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_get_head_data'; -- プログラム名
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
    -- データ抽出
    -- ====================================================
    SELECT
           --以下処理用項目
           gbh.batch_id                                            AS batch_id         -- 生産バッチヘッダ.バッチID
          ,gbh.last_updated_by                                     AS last_updated_by  -- 生産バッチヘッダ.最終更新者ID
          ,grv.attribute17                                         AS shinkansen_kbn   -- 工順マスタVIEW.DFF17（新缶煎区分）
          ,gmd.item_id                                             AS item_id          -- 生産原料詳細.品目ID
          ,xim2v.item_um                                           AS item_um          -- OPM品目情報VIEW2.単位
          ,NVL(TO_NUMBER(xim2v.net) , gv_net_default_val)          AS net              -- OPM品目情報VIEW2.NET(NULL時の対応込み)
-- 2009/11/24 H.Itou Mod Start 本番障害#1696 品目カテゴリ割当情報VIEW5に変更
---- Add 2008/05/29
--          ,xic2v.segment1                                          AS item_class       -- 品目区分
---- Add 2008/05/29
          ,xic2v.item_class_code                                   AS item_class       -- 品目区分
-- 2009/11/24 H.Itou Mod End
           --以下データ用項目
          ,gbh.batch_no                                            AS tehai_no         -- 生産バッチヘッダ.バッチNO
          ,xlv1v1.meaning                                          AS den_kbn          -- 参照コード.摘要
          ,xlv1v2.meaning                                          AS knri_bsho        -- 参照コード.摘要
          ,xim2v.item_no                                           AS hinmk_cd         -- OPM品目情報VIEW2.品目コード
          ,xim2v.item_short_name                                   AS hinmk_nm         -- OPM品目情報VIEW2.品名・略称
          ,grv.routing_no                                          AS line_no          -- 工順マスタVIEW.工順NO
          ,grv.routing_desc                                        AS line_nm          -- 工順マスタVIEW.工順摘要
          ,grv.attribute9                                          AS set_cd           -- 工順マスタVIEW.DFF9（納品場所コード）
          ,xil1v1.description                                      AS set_nm           -- OPM保管場所情報VIEW.保管倉庫名
          ,FND_DATE.STRING_TO_DATE(SUBSTRB(gmd.attribute11 , 1 , 10)
                                  ,gv_date_format3)                AS make_start_date  -- 生産原料詳細.DFF11(生産日)
          ,FND_DATE.STRING_TO_DATE(SUBSTRB(gmd.attribute11 , 1 , 10)
                                  ,gv_date_format3)                AS make_end_date    -- 生産原料詳細.DFF11(生産日)
          ,FND_DATE.STRING_TO_DATE(SUBSTRB(gmd.attribute10 , 1 , 10)
                                  ,gv_date_format3)                AS shoumikigen      -- 生産原料詳細.DFF10(賞味期限日)
          ,xlv1v3.meaning                                          AS item_type        -- 参照コード.摘要
          ,gmd.attribute2                                          AS item_rank1       -- 生産原料詳細.DFF2(ランク1)
          ,gmd.attribute3                                          AS item_rank2       -- 生産原料詳細.DFF3(ランク2)
-- 2009/02/04 v1.10 Y.Yamamoto #4 add start
          ,gmd.attribute26                                         AS item_rank3       -- 生産原料詳細.DFF26(ランク3)
-- 2009/02/04 v1.10 Y.Yamamoto #4 add end
          ,RTRIM(SUBSTRB(gmd.attribute4 , 1 , 100))                AS item_tekiyo      -- 生産原料詳細.DFF4(摘要)
          ,ilm.lot_no                                              AS lot_no           -- OPMロットマスタ.ロットNO
          ,gmd.attribute12                                         AS move_cd          -- 生産原料詳細.DFF12(移動場所コード)
          ,xil1v2.description                                      AS move_nm          -- OPM保管場所情報VIEW.保管倉庫名
          ,gmd.attribute6                                          AS stock_num        -- 生産原料詳細.DFF6(在庫入数)
          ,xxcmn_common_pkg.rcv_ship_conv_qty('2'
                                             ,gmd.item_id
                                             ,gmd.actual_qty)      AS dekidaka         -- 生産原料詳細.実績数量の換算結果
    --
    BULK COLLECT INTO ot_head_data
    --
    FROM   gme_batch_header           gbh     -- 生産バッチヘッダ
          ,gmd_routings_vl            grv     -- 工順マスタVIEW
          ,gme_material_details       gmd     -- 生産原料詳細
          ,xxcmn_lookup_values_v      xlv1v1  -- クイックコード情報VIEW(伝票区分)
          ,xxcmn_lookup_values_v      xlv1v2  -- クイックコード情報VIEW(成績管理部署)
          ,xxcmn_lookup_values_v      xlv1v3  -- クイックコード情報VIEW(タイプ)
          ,xxcmn_item_locations_v     xil1v1  -- OPM保管場所情報VIEW(納品場所)
          ,xxcmn_item_locations_v     xil1v2  -- OPM保管場所情報VIEW(移動場所)
          ,ic_tran_pnd                itp     -- OPM保留在庫トランザクション
          ,ic_lots_mst                ilm     -- OPMロットマスタ
          ,xxcmn_item_mst2_v          xim2v   -- OPM品目情報VIEW2
-- 2009/11/24 H.Itou Mod Start 本番障害#1696 品目カテゴリ割当情報VIEW5に変更
---- Add 2008/05/29
--          , xxcmn_item_categories2_v  xic2v  -- OPM品目カテゴリ情報VIEW2
---- Add 2008/05/29
          , xxcmn_item_categories5_v  xic2v  -- OPM品目カテゴリ情報VIEW5
-- 2009/11/24 H.Itou Mod End
    WHERE
    -- 以下固定条件
    ------------------------------------------------------------------------
    -- 生産バッチヘッダ条件
-- 2008/12/24 v1.8 UPDATE START
--          gbh.attribute4            =  gv_status_comp                   -- 業務ステータス＝「完了」
          gbh.attribute4            IN (gv_status_comp, gv_status_close) -- 業務ステータスIN「完了、 クローズ」
-- 2008/12/24 v1.8 UPDATE END
    ------------------------------------------------------------------------
    -- 生産原料詳細条件
    AND   gbh.batch_id              =  gmd.batch_id
    AND   gmd.line_type             =  gv_line_type_kbn_seizouhin       -- ラインタイプ＝「製造品」
    ------------------------------------------------------------------------
    -- 工順マスタVIEW条件
    AND   gbh.routing_id            =  grv.routing_id
    ------------------------------------------------------------------------
    -- クイックコード情報VIEW(伝票区分)条件
    AND   grv.attribute13           =  xlv1v1.lookup_code
    AND   xlv1v1.lookup_type        =  gv_lookup_type_den_kbn
    ------------------------------------------------------------------------
    -- クイックコード情報VIEW(成績管理部署)条件
    AND   grv.attribute14           =  xlv1v2.lookup_code
    AND   xlv1v2.lookup_type        =  gv_lookup_type_knri_bsho
    ------------------------------------------------------------------------
    -- クイックコード情報VIEW(タイプ)条件
    AND   gmd.attribute1            =  xlv1v3.lookup_code(+)
    AND   xlv1v3.lookup_type(+)     =  gv_lookup_type_item_type
    ------------------------------------------------------------------------
    --  OPM保管場所情報VIEW(納品場所)条件
    AND   grv.attribute9            =  xil1v1.segment1
    ------------------------------------------------------------------------
    --  OPM保管場所情報VIEW(移動場所)条件
    AND   gmd.attribute12           =  xil1v2.segment1(+)
    ------------------------------------------------------------------------
    --  OPM保留在庫トランザクション条件
    AND   gmd.batch_id              =  itp.doc_id
    AND   gmd.material_detail_id    =  itp.line_id
    AND   gmd.line_type             =  itp.line_type
-- 2008/10/28 v1.5 D.Nihei ADD START
    AND itp.doc_type                = gv_doc_type_prod
-- 2008/10/28 v1.5 D.Nihei ADD END
-- 2009/11/24 H.Itou Mod Start 本番障害#1696 フルスキャンするので修正
--    -- 下記2条件でIS NULLの代替とする
--    AND   NOT EXISTS (SELECT 1
--                      FROM ic_tran_pnd itp2
--                      WHERE itp2.reverse_id = itp.trans_id)     -- 保留トランIDがリバースIDに存在しないもの
--    AND   NOT EXISTS (SELECT 1
--                      FROM ic_tran_pnd itp3
--                      WHERE itp3.trans_id = itp.reverse_id)     -- リバースIDが保留トランIDに存在しないもの
    AND   itp.reverse_id IS NULL
-- 2009/11/24 H.Itou Mod End
    AND   itp.completed_ind         =  gv_comp_flag             -- 完了フラグ＝「完了」
    ------------------------------------------------------------------------
    -- OPMロットマスタ条件
    AND   itp.item_id               =  ilm.item_id
    AND   itp.lot_id                =  ilm.lot_id
    ------------------------------------------------------------------------
    -- OPM品目情報view2条件
    AND   gmd.item_id               =  xim2v.item_id
    AND   FND_DATE.STRING_TO_DATE(SUBSTRB(gmd.attribute11 , 1 , 10) , gv_date_format3)
                                  BETWEEN xim2v.start_date_active
                                      AND xim2v.end_date_active
    ------------------------------------------------------------------------
-- Add 2008/05/29
    -- OPM品目カテゴリ情報view2条件
    AND   gmd.item_id               =  xic2v.item_id
-- 2009/11/24 H.Itou Del Start 本番障害#1696 品目カテゴリ割当情報VIEW5に変更
--    AND   xic2v.category_set_name = FND_PROFILE.VALUE('XXCMN_ARTICLE_DIV')
-- 2009/11/24 H.Itou Del End
-- Add 2008/05/29
    ------------------------------------------------------------------------
    ------------------------------------------------------------------------
    -- 以下変動条件
    ------------------------------------------------------------------------
    -- 工順マスタVIEWパラメータ条件
    AND   grv.attribute13           =  NVL(ir_param.iv_den_kbn , grv.attribute13)
    AND   grv.routing_no            =  NVL(ir_param.iv_line_no , grv.routing_no)
    ------------------------------------------------------------------------
    -- 生産バッチヘッダパラメータ条件
    AND   gbh.plant_code            =  NVL(ir_param.iv_plant , gbh.plant_code)
    AND   gbh.batch_no              >= NVL(ir_param.id_tehai_no_from , gbh.batch_no)
    AND   gbh.batch_no              <= NVL(ir_param.id_tehai_no_to , gbh.batch_no)
-- 変更 START 2008/05/20 YTabata
/**
    AND   TRUNC(gbh.creation_date , 'MI') BETWEEN NVL(ir_param.id_input_date_from
                                                    , TRUNC(gbh.creation_date , 'MI'))
                                              AND NVL(ir_param.id_input_date_to
                                                    , TRUNC(gbh.creation_date , 'MI'))
**/
-- 2008/10/28 v1.5 D.Nihei MOD START
--    AND   gbh.creation_date  BETWEEN NVL(ir_param.id_input_date_from, gbh.creation_date )
--                                 AND NVL(ir_param.id_input_date_to, gbh.creation_date )
    AND   gbh.last_update_date  BETWEEN NVL(ir_param.id_input_date_from, gbh.last_update_date )
                                AND     NVL(ir_param.id_input_date_to,   gbh.last_update_date )
-- 2008/10/28 v1.5 D.Nihei MOD END
    ------------------------------------------------------------------------
    -- 生産原料詳細パラメータ条件
-- 変更 START 2008/05/20 YTabata
/**
    AND   FND_DATE.STRING_TO_DATE(SUBSTRB(gmd.attribute11 , 1 , 10) , gv_date_format3)
                                    BETWEEN NVL(ir_param.id_make_date_from
                                              , FND_DATE.STRING_TO_DATE(SUBSTRB(gmd.attribute11 , 1 , 10)
                                                                       ,gv_date_format3)
                                               )
                                        AND NVL(ir_param.id_make_date_to
                                              , FND_DATE.STRING_TO_DATE(SUBSTRB(gmd.attribute11 , 1 , 10)
                                                                       ,gv_date_format3)
                                               )
**/
    AND   FND_DATE.STRING_TO_DATE(SUBSTRB(gmd.attribute11 , 1 , 10) , gv_date_format3)
                                    BETWEEN NVL(ir_param.id_make_date_from
                                              , FND_DATE.STRING_TO_DATE(gv_min_date_char
                                                                       ,gv_date_format3)
                                               )
                                        AND NVL(ir_param.id_make_date_to
                                              , FND_DATE.STRING_TO_DATE(gv_max_date_char
                                                                       ,gv_date_format3)
                                               )
-- 変更 END 2008/05/20 YTabata
    ------------------------------------------------------------------------
    -- OPM品目情報VIEW2パラメータ条件
    AND   xim2v.item_no             =  NVL(ir_param.iv_hinmoku_cd , xim2v.item_no)
    ------------------------------------------------------------------------
    ------------------------------------------------------------------------
    ORDER BY gbh.batch_no
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
      ov_errmsg  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_errbuf  := ov_errmsg;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END prc_get_head_data ;
--
--
--
  /**********************************************************************************
   * Procedure Name   : prc_get_tonyu_data
   * Description      : 明細-投入情報抽出
   ***********************************************************************************/
  PROCEDURE prc_get_tonyu_data(
      iv_batch_id      IN         gme_batch_header.batch_id%TYPE  -- バッチID
     ,ot_tonyu_data    OUT NOCOPY type_tounyu_data_tbl             -- 明細-投入情報データ
     ,ov_errbuf        OUT NOCOPY VARCHAR2                        -- エラー・メッセージ           --# 固定 #
     ,ov_retcode       OUT NOCOPY VARCHAR2                        -- リターン・コード             --# 固定 #
     ,ov_errmsg        OUT NOCOPY VARCHAR2                        -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_get_tonyu_data'; -- プログラム名
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
    -- データ抽出
    -- ====================================================
    SELECT
           --以下処理用項目
           gmd.material_detail_id                                    AS material_detail_id -- 生産原料詳細.生産原料詳細ID
          ,NVL(gmd.attribute8 , gv_tounyuguchi_kbn_default)          AS tounyuguchi_kbn    -- 生産原料詳細.DFF8(投入口区分)
           --以下データ用項目
          ,ximv.item_no                                              AS tonyu_hinmk_cd     -- OPM品目情報VIEW.品目コード
          ,ximv.item_short_name                                      AS tonyu_hinmk_nm     -- OPM品目情報VIEW.品名・略称
          ,ilm.lot_no                                                AS tonyu_lot_no       -- OPMロットマスタ.ロットNo
          ,FND_DATE.STRING_TO_DATE(SUBSTRB(ilm.attribute1 , 1 , 10)
                                  ,gv_date_format3)                  AS tonyu_make_date    -- OPMロットマスタ.DFF1(製造年月日)
          ,TO_NUMBER(ilm.attribute6)                                 AS tonyu_stock        -- OPMロットマスタ.DFF6(在庫入数)
          ,xmd.invested_qty                                          AS tonyu_total        -- 生産原料詳細アドオン.投入数量
          ,ximv.item_um                                              AS tonyu_unit         -- OPM品目情報VIEW.単位
-- 2008/12/17 v1.7 D.Nihei ADD START
          ,NVL(TO_NUMBER(ximv.net) , gv_net_default_val)             AS tonyu_net          -- OPM品目情報VIEW.NET
-- 2008/12/17 v1.7 D.Nihei ADD END
    --
    BULK COLLECT INTO ot_tonyu_data
    --
    FROM   gme_material_details       gmd     -- 生産原料詳細
          ,xxwip_material_detail      xmd     -- 生産原料詳細アドオン
          ,ic_lots_mst                ilm     -- OPMロットマスタ
          ,xxcmn_item_mst_v           ximv    -- OPM品目情報VIEW
          ,xxcmn_item_categories5_v   xicv   -- OPM品目カテゴリ割当情報VIEW
    WHERE
    --以下固定条件
    ------------------------------------------------------------------------
    --生産原料詳細条件
          gmd.line_type             =  gv_line_type_kbn_genryou       -- ラインタイプ＝「原料」
    AND   gmd.attribute5            IS NULL     -- DFF5(打込区分)が未入力
    AND   gmd.attribute24           IS NULL     -- DFF24(原料削除フラグ)が未入力
    ------------------------------------------------------------------------
    --生産原料詳細アドオン条件
    AND   gmd.material_detail_id    =  xmd.material_detail_id
    AND   xmd.plan_type             =  gv_yotei_kbn_tonyu       -- 予定区分＝「4:投入」
    ------------------------------------------------------------------------
    -- OPMロットマスタ条件
    AND   xmd.item_id               =  ilm.item_id
    AND   xmd.lot_id                =  ilm.lot_id
    ------------------------------------------------------------------------
    -- OPM品目情報VIEW条件
    AND   gmd.item_id               =  ximv.item_id
    ------------------------------------------------------------------------
    -- OPM品目カテゴリ割当情報VIEW条件
    AND   gmd.item_id               =  xicv.item_id
    AND   xicv.item_class_code     IN (gv_hinmoku_kbn_genryou
                                      ,gv_hinmoku_kbn_hanseihin
                                      ,gv_hinmoku_kbn_seihin)        -- 原材料、半製品、製品
    ------------------------------------------------------------------------
    ------------------------------------------------------------------------
    --以下変動条件
    ------------------------------------------------------------------------
    --生産原料詳細パラメータ条件
    AND   gmd.batch_id              =  iv_batch_id
    ------------------------------------------------------------------------
    ------------------------------------------------------------------------
    ORDER BY gmd.attribute8            -- 生産原料詳細.DFF8(投入口区分)
            ,xicv.item_class_code      -- OPM品目カテゴリ割当情報VIEW.品目カテゴリコード
            ,TO_NUMBER(ximv.item_no)   -- OPM品目情報VIEW.品目コード
            ,TO_NUMBER(ilm.lot_no)     -- OPMロットマスタ.ロットNO
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
      ov_errmsg  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_errbuf  := ov_errmsg;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END prc_get_tonyu_data;
--
--
--
  /**********************************************************************************
   * Procedure Name   : prc_get_reinyu_tonyu_data
   * Description      : 明細-戻入（投入分）情報抽出処理
   ***********************************************************************************/
  PROCEDURE prc_get_reinyu_tonyu_data(
      iv_batch_id             IN         gme_batch_header.batch_id%TYPE  -- バッチID
     ,ot_reinyu_tonyu_data    OUT NOCOPY type_tounyu_data_tbl             -- 明細-戻入（投入分）情報データ
     ,ov_errbuf               OUT NOCOPY VARCHAR2                        -- エラー・メッセージ           --# 固定 #
     ,ov_retcode              OUT NOCOPY VARCHAR2                        -- リターン・コード             --# 固定 #
     ,ov_errmsg               OUT NOCOPY VARCHAR2                        -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_get_reinyu_tonyu_data'; -- プログラム名
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
    -- データ抽出
    -- ====================================================
    SELECT
           --以下処理用項目
           gmd.material_detail_id                                    AS material_detail_id -- 生産原料詳細.生産原料詳細ID
          ,NVL(gmd.attribute8 , gv_tounyuguchi_kbn_default)          AS tounyuguchi_kbn    -- 生産原料詳細.DFF8(投入口区分)
           --以下データ用項目
          ,ximv.item_no                                              AS modori_hinmk_cd     -- OPM品目情報VIEW.品目コード
          ,ximv.item_short_name                                      AS modori_hinmk_nm     -- OPM品目情報VIEW.品名・略称
          ,ilm.lot_no                                                AS modori_lot_no       -- OPMロットマスタ.ロットNO
          ,FND_DATE.STRING_TO_DATE(SUBSTRB(ilm.attribute1 , 1 , 10)
                                  ,gv_date_format3)                  AS modori_make_date    -- OPMロットマスタ.DFF1(製造年月日)
          ,TO_NUMBER(ilm.attribute6)                                 AS modori_stock        -- OPMロットマスタ.DFF6(在庫入数)
          ,xmd.return_qty                                            AS modori_total        -- 生産原料詳細アドオン.戻入数量
          ,ximv.item_um                                              AS modori_unit         -- OPM品目情報VIEW.単位
-- 2008/12/17 v1.7 D.Nihei ADD START
          ,NVL(TO_NUMBER(ximv.net) , gv_net_default_val)             AS modori_net          -- OPM品目情報VIEW.NET
-- 2008/12/17 v1.7 D.Nihei ADD END
    --
    BULK COLLECT INTO ot_reinyu_tonyu_data
    --
    FROM   gme_material_details       gmd     -- 生産原料詳細
          ,xxwip_material_detail      xmd     -- 生産原料詳細アドオン
          ,ic_lots_mst                ilm     -- OPMロットマスタ
          ,xxcmn_item_mst_v           ximv    -- OPM品目情報VIEW
          ,xxcmn_item_categories5_v   xicv    -- OPM品目カテゴリ割当情報VIEW
    WHERE
    --以下固定条件
    ------------------------------------------------------------------------
    --生産原料詳細条件
          gmd.line_type             =  gv_line_type_kbn_genryou       -- ラインタイプ＝「原料」
    AND   gmd.attribute5            IS NULL     -- DFF5(打込区分)が未入力
    AND   gmd.attribute24           IS NULL     -- DFF24(原料削除フラグ)が未入力
    ------------------------------------------------------------------------
    --生産原料詳細アドオン条件
    AND   gmd.material_detail_id    =  xmd.material_detail_id
    AND   xmd.plan_type             =  gv_yotei_kbn_tonyu       -- 予定区分＝「4:投入」
    AND   NVL(xmd.return_qty,0)     <> 0         -- 戻入数量が0でない
    ------------------------------------------------------------------------
    -- OPMロットマスタ条件
    AND   xmd.item_id               =  ilm.item_id
    AND   xmd.lot_id                =  ilm.lot_id
    ------------------------------------------------------------------------
    -- OPM品目情報VIEW条件
    AND   gmd.item_id               =  ximv.item_id
    ------------------------------------------------------------------------
    -- OPM品目カテゴリ割当情報VIEW条件
    AND   gmd.item_id               =  xicv.item_id
    AND   xicv.item_class_code     IN (gv_hinmoku_kbn_genryou
                                      ,gv_hinmoku_kbn_hanseihin
                                      ,gv_hinmoku_kbn_seihin)  -- 原材料、半製品、製品
    ------------------------------------------------------------------------
    ------------------------------------------------------------------------
    --以下変動条件
    ------------------------------------------------------------------------
    --生産原料詳細パラメータ条件
    AND   gmd.batch_id              =  iv_batch_id
    ------------------------------------------------------------------------
    ORDER BY gmd.attribute8              -- 生産原料詳細.DFF8(投入口区分)
            ,xicv.item_class_code        -- OPM品目カテゴリ割当情報VIEW.品目カテゴリコード
            ,TO_NUMBER(ximv.item_no)     -- OPM品目情報VIEW.品目コード
            ,TO_NUMBER(ilm.lot_no)       -- OPMロットマスタ.ロットNO
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
      ov_errmsg  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_errbuf  := ov_errmsg;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END prc_get_reinyu_tonyu_data;
--
--
--
  /**********************************************************************************
   * Procedure Name   : prc_get_fsanbutu_data
   * Description      : 明細-副産物情報抽出処理
   ***********************************************************************************/
  PROCEDURE prc_get_fsanbutu_data(
      iv_batch_id             IN         gme_batch_header.batch_id%TYPE  -- バッチID
     ,ot_fukusanbutu_data     OUT NOCOPY type_tounyu_data_tbl             -- 明細-副産物情報データ
     ,ov_errbuf               OUT NOCOPY VARCHAR2                        -- エラー・メッセージ           --# 固定 #
     ,ov_retcode              OUT NOCOPY VARCHAR2                        -- リターン・コード             --# 固定 #
     ,ov_errmsg               OUT NOCOPY VARCHAR2                        -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_get_fsanbutu_data'; -- プログラム名
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
    -- データ抽出
    -- ====================================================
    SELECT
           --以下処理用項目
           TO_NUMBER(NULL)                                           AS material_detail_id    -- ダミーカラム
          ,TO_CHAR(NULL)                                             AS tounyuguchi_kbn       -- ダミーカラム
           --以下データ用項目
          ,ximv.item_no                                              AS fsanbutu_hinmk_cd     -- OPM品目情報VIEW.品目コード
          ,ximv.item_short_name                                      AS fsanbutu_hinmk_nm     -- OPM品目情報VIEW.品名・略称
          ,ilm.lot_no                                                AS fsanbutu_lot_no       -- OPMロットマスタ.ロットno
          ,FND_DATE.STRING_TO_DATE(SUBSTRB(ilm.attribute1 , 1 , 10)
                                  ,gv_date_format3)                  AS fsanbutu_make_date    -- OPMロットマスタ.DFF1(製造年月日)
          ,TO_NUMBER(ilm.attribute6)                                 AS fsanbutu_stock        -- OPMロットマスタ.DFF6(在庫入数)
          ,gmd.actual_qty                                            AS fsanbutu_total        -- 生産原料詳細.実績数量
          ,ximv.item_um                                              AS fsanbutu_unit         -- OPM品目情報VIEW.単位
-- 2008/12/17 v1.7 D.Nihei ADD START
          ,NVL(TO_NUMBER(ximv.net) , gv_net_default_val)             AS fsanbutu_net          -- OPM品目情報VIEW.NET
-- 2008/12/17 v1.7 D.Nihei ADD END
--
    BULK COLLECT INTO ot_fukusanbutu_data
--
    FROM   gme_material_details       gmd     -- 生産原料詳細
          ,ic_lots_mst                ilm     -- OPMロットマスタ
          ,xxcmn_item_mst_v           ximv    -- OPM品目情報VIEW
-- 2009/11/24 H.Itou Mod Start 本番障害#1696 品目カテゴリ割当情報VIEW5に変更
--          ,xxcmn_item_categories_v    xic1v   -- OPM品目カテゴリ割当情報VIEW
          ,xxcmn_item_categories5_v    xic1v   -- OPM品目カテゴリ割当情報VIEW5
-- 2009/11/24 H.Itou Mod End
          ,ic_tran_pnd                itp     -- OPM保留在庫トランザクション
    WHERE
    --以下固定条件
    ------------------------------------------------------------------------
    --生産原料詳細条件
          gmd.line_type             =  gv_line_type_kbn_fukusanbutu       -- ラインタイプ＝「副産物」
    AND   gmd.attribute24           IS NULL     -- DFF24(原料削除フラグ)が未入力
    ------------------------------------------------------------------------
    -- OPM品目情報VIEW条件
    AND   gmd.item_id               =  ximv.item_id
    ------------------------------------------------------------------------
    -- OPM品目カテゴリ割当情報VIEW条件
    AND   gmd.item_id               =  xic1v.item_id
-- 2009/11/24 H.Itou Del Start 本番障害#1696 品目カテゴリ割当情報VIEW5に変更
--    AND   xic1v.category_set_name   =  gv_item_cat_name_item_kbn
-- 2009/11/24 H.Itou Del End
    ------------------------------------------------------------------------
    --  OPM保留在庫トランザクション条件
    AND   gmd.batch_id              =  itp.doc_id
    AND   gmd.material_detail_id    =  itp.line_id
    AND   gmd.line_type             =  itp.line_type
-- 2009/11/24 H.Itou Mod Start 本番障害#1696 フルスキャンするので修正
--    --下記2条件でIS NULLの代替とする
--    AND   NOT EXISTS (SELECT 1
--                      FROM ic_tran_pnd itp2
--                      WHERE itp2.reverse_id = itp.trans_id)     -- 保留トランidがリバースidに存在しないもの
--    AND   NOT EXISTS (SELECT 1
--                      FROM ic_tran_pnd itp3
--                      WHERE itp3.trans_id = itp.reverse_id)     -- リバースidが保留トランidに存在しないもの
    AND itp.reverse_id IS NULL
-- 2009/11/24 H.Itou Mod End
    AND   itp.completed_ind    =  gv_comp_flag                  -- 完了フラグ＝「完了」
-- 2008/10/28 v1.5 D.Nihei ADD START
    AND itp.doc_type           = gv_doc_type_prod
-- 2008/10/28 v1.5 D.Nihei ADD END
    ------------------------------------------------------------------------
    -- OPMロットマスタ条件
    AND   itp.item_id               =  ilm.item_id
    AND   itp.lot_id                =  ilm.lot_id
    ------------------------------------------------------------------------
    ------------------------------------------------------------------------
    --以下変動条件
    ------------------------------------------------------------------------
    --生産原料詳細パラメータ条件
    AND   gmd.batch_id              =  iv_batch_id
    ------------------------------------------------------------------------
-- 2009/11/24 H.Itou Mod Start 本番障害#1696 品目カテゴリ割当情報VIEW5に変更
--    ORDER BY xic1v.segment1            -- OPM品目カテゴリ割当情報VIEW.品目カテゴリコード
    ORDER BY xic1v.item_class_code     -- OPM品目カテゴリ割当情報VIEW5.品目区分
-- 2009/11/24 H.Itou Mod End
            ,TO_NUMBER(ximv.item_no)   -- OPM品目情報VIEW.品目コード
            ,TO_NUMBER(ilm.lot_no)     -- OPMロットマスタ.ロットno
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
      ov_errmsg  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_errbuf  := ov_errmsg;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END prc_get_fsanbutu_data;
--
--
--
  /**********************************************************************************
   * Procedure Name   : prc_get_utikomi_data
   * Description      : 明細-打込情報抽出処理
   ***********************************************************************************/
  PROCEDURE prc_get_utikomi_data(
      iv_batch_id         IN         gme_batch_header.batch_id%TYPE  -- バッチID
     ,ot_utikomi_data     OUT NOCOPY type_tounyu_data_tbl             --  明細-打込情報データ
     ,ov_errbuf           OUT NOCOPY VARCHAR2                        -- エラー・メッセージ           --# 固定 #
     ,ov_retcode          OUT NOCOPY VARCHAR2                        -- リターン・コード             --# 固定 #
     ,ov_errmsg           OUT NOCOPY VARCHAR2                        -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_get_utikomi_data'; -- プログラム名
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
    -- データ抽出
    -- ====================================================
    SELECT
           --以下処理用項目
           TO_NUMBER(NULL)                                        AS material_detail_id   -- ダミーカラム
          ,TO_CHAR(NULL)                                          AS tounyuguchi_kbn       -- ダミーカラム
           --以下データ用項目
          ,ximv.item_no                                           AS utikomi_hinmk_cd     -- OPM品目情報VIEW.品目コード
          ,ximv.item_short_name                                   AS utikomi_hinmk_nm     -- OPM品目情報VIEW.品名・略称
          ,ilm.lot_no                                             AS utikomi_lot_no       -- OPMロットマスタ.ロットno
          ,FND_DATE.STRING_TO_DATE(SUBSTRB(ilm.attribute1 , 1 , 10)
                                  ,gv_date_format3)               AS utikomi_make_date    -- OPMロットマスタ.DFF1(製造年月日)
          ,TO_NUMBER(ilm.attribute6)                              AS utikomi_stock        -- OPMロットマスタ.DFF6(在庫入数)
          ,xmd.invested_qty                                       AS utikomi_total        -- 生産原料詳細アドオン.投入数量
          ,ximv.item_um                                           AS utikomi_unit         -- OPM品目情報VIEW.単位
-- 2008/12/17 v1.7 D.Nihei ADD START
          ,NVL(TO_NUMBER(ximv.net) , gv_net_default_val)          AS utikomi_net          -- OPM品目情報VIEW.NET
-- 2008/12/17 v1.7 D.Nihei ADD END
--
    BULK COLLECT INTO ot_utikomi_data
--
    FROM   gme_material_details       gmd     -- 生産原料詳細
          ,xxwip_material_detail      xmd     -- 生産原料詳細アドオン
          ,ic_lots_mst                ilm     -- OPMロットマスタ
          ,xxcmn_item_mst_v           ximv    -- OPM品目情報VIEW
          ,xxcmn_item_categories5_v   xicv    -- OPM品目カテゴリ割当情報VIEW
          ,ic_tran_pnd                itp     -- OPM保留在庫トランザクション
    WHERE
    --以下固定条件
    ------------------------------------------------------------------------
    --生産原料詳細条件
          gmd.line_type             =  gv_line_type_kbn_genryou       -- ラインタイプ＝「原料」
    AND   gmd.attribute5            =  gv_utikomi_kbn_utikomi         -- DFF5(打込区分)＝Ｙ
    AND   gmd.attribute24           IS NULL     -- DFF24(原料削除フラグ)が未入力
    ------------------------------------------------------------------------
    --生産原料詳細アドオン条件
    AND   gmd.material_detail_id    =  xmd.material_detail_id
    AND   xmd.plan_type             =  gv_yotei_kbn_tonyu       -- 予定区分＝「4:投入」
    ------------------------------------------------------------------------
    -- OPM品目情報VIEW条件
    AND   gmd.item_id               =  ximv.item_id
    ------------------------------------------------------------------------
    -- OPM品目カテゴリ割当情報VIEW条件
    AND   gmd.item_id               =  xicv.item_id
    AND   xicv.item_class_code     IN (gv_hinmoku_kbn_genryou
                                      ,gv_hinmoku_kbn_hanseihin
                                      ,gv_hinmoku_kbn_seihin)  -- 原材料、半製品、製品
    ------------------------------------------------------------------------
    --  OPM保留在庫トランザクション条件
    AND   gmd.batch_id              =  itp.doc_id
    AND   gmd.material_detail_id    =  itp.line_id
    AND   gmd.line_type             =  itp.line_type
--
    AND   xmd.material_detail_id    =  itp.line_id
    AND   xmd.item_id               =  itp.item_id
    AND   xmd.lot_id                =  itp.lot_id
-- 2009/11/24 H.Itou Mod Start 本番障害#1696 フルスキャンするので修正
--    -- 下記2条件でIS NULLの代替とする
--    AND   NOT EXISTS (SELECT 1
--                      FROM ic_tran_pnd itp2
--                      WHERE itp2.reverse_id = itp.trans_id)     -- 保留トランIDがリバースIDに存在しないもの
--    AND   NOT EXISTS (SELECT 1
--                      FROM ic_tran_pnd itp3
--                      WHERE itp3.trans_id = itp.reverse_id)     -- リバースIDが保留トランIDに存在しないもの
    AND   itp.reverse_id IS NULL
-- 2009/11/24 H.Itou Mod End
    AND   itp.completed_ind    =  gv_comp_flag                  -- 完了フラグ＝「完了」
-- 2008/10/28 v1.5 D.Nihei ADD START
    AND   itp.doc_type              = gv_doc_type_prod
-- 2008/10/28 v1.5 D.Nihei ADD END
    ------------------------------------------------------------------------
    -- OPMロットマスタ条件
    AND   itp.item_id               =  ilm.item_id
    AND   itp.lot_id                =  ilm.lot_id
    ------------------------------------------------------------------------
    ------------------------------------------------------------------------
    --以下変動条件
    ------------------------------------------------------------------------
    --生産原料詳細パラメータ条件
    AND   gmd.batch_id              =  iv_batch_id
    ------------------------------------------------------------------------
    ORDER BY xicv.item_class_code       -- OPM品目カテゴリ割当情報VIEW.品目カテゴリコード
            ,TO_NUMBER(ximv.item_no)    -- OPM品目情報VIEW.品目コード
            ,TO_NUMBER(ilm.lot_no)      -- OPMロットマスタ.ロットno
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
      ov_errmsg  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_errbuf  := ov_errmsg;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END prc_get_utikomi_data;
--
--
--
  /**********************************************************************************
   * Procedure Name   : prc_get_reinyu_utikomi_data
   * Description      : 明細-戻入（打込分）情報抽出処理
   ***********************************************************************************/
  PROCEDURE prc_get_reinyu_utikomi_data(
      iv_batch_id             IN         gme_batch_header.batch_id%TYPE  -- バッチID
     ,ot_reinyu_utikomi_data  OUT NOCOPY type_tounyu_data_tbl             -- 明細-戻入（打込分）情報データ
     ,ov_errbuf               OUT NOCOPY VARCHAR2                        -- エラー・メッセージ           --# 固定 #
     ,ov_retcode              OUT NOCOPY VARCHAR2                        -- リターン・コード             --# 固定 #
     ,ov_errmsg               OUT NOCOPY VARCHAR2                        -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_get_reinyu_utikomi_data'; -- プログラム名
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
    -- データ抽出
    -- ====================================================
    SELECT
           --以下処理用項目
           TO_NUMBER(NULL)                                           AS material_detail_id          -- ダミーカラム
          ,TO_CHAR(NULL)                                             AS tounyuguchi_kbn             -- ダミーカラム
           --以下データ用項目
          ,ximv.item_no                                              AS modori_utikomi_hinmk_cd     -- OPM品目情報VIEW.品目コード
          ,ximv.item_short_name                                      AS modori_utikomi_hinmk_nm     -- OPM品目情報VIEW.品名・略称
          ,ilm.lot_no                                                AS modori_utikomi_lot_no       -- OPMロットマスタ.ロットNo
          ,FND_DATE.STRING_TO_DATE(SUBSTRB(ilm.attribute1 , 1 , 10)
                                  ,gv_date_format3)                  AS modori_utikomi_make_date    -- OPMロットマスタ.DFF1(製造年月日)
          ,TO_NUMBER(ilm.attribute6)                                 AS modori_utikomi_stock        -- OPMロットマスタ.DFF6(在庫入数)
          ,xmd.return_qty                                            AS modori_utikomi_total        -- 生産原料詳細アドオン.戻入数量
          ,ximv.item_um                                              AS modori_utikomi_unit         -- OPM品目情報VIEW.単位
-- 2008/12/17 v1.7 D.Nihei ADD START
          ,NVL(TO_NUMBER(ximv.net) , gv_net_default_val)             AS modori_utikomi_net          -- OPM品目情報VIEW.NET
-- 2008/12/17 v1.7 D.Nihei ADD END
--
    BULK COLLECT INTO ot_reinyu_utikomi_data
--
    FROM   gme_material_details       gmd     -- 生産原料詳細
          ,xxwip_material_detail      xmd     -- 生産原料詳細アドオン
          ,ic_lots_mst                ilm     -- OPMロットマスタ
          ,xxcmn_item_mst_v           ximv    -- OPM品目情報VIEW
          ,xxcmn_item_categories5_v   xicv    -- OPM品目カテゴリ割当情報VIEW
          ,ic_tran_pnd                itp     -- OPM保留在庫トランザクション
    WHERE
    --以下固定条件
    ------------------------------------------------------------------------
    --生産原料詳細条件
          gmd.line_type             =  gv_line_type_kbn_genryou    -- ラインタイプ＝「原料」
    AND   gmd.attribute5            = gv_utikomi_kbn_utikomi       -- DFF5(打込区分)＝Ｙ
    AND   gmd.attribute24           IS NULL                        -- DFF24(原料削除フラグ)が未入力
    ------------------------------------------------------------------------
    --生産原料詳細アドオン条件
    AND   gmd.material_detail_id    =  xmd.material_detail_id
    AND   xmd.plan_type             =  gv_yotei_kbn_tonyu       -- 予定区分＝「4:投入」
    AND   NVL(xmd.return_qty,0)     <> 0         -- 戻入数量が0でない
    ------------------------------------------------------------------------
    -- OPMロットマスタ条件
    AND   itp.item_id               =  ilm.item_id
    AND   itp.lot_id                =  ilm.lot_id
    ------------------------------------------------------------------------
    -- OPM品目情報VIEW条件
    AND   gmd.item_id               =  ximv.item_id
    ------------------------------------------------------------------------
    --  OPM保留在庫トランザクション条件
    AND   gmd.batch_id              =  itp.doc_id
    AND   gmd.material_detail_id    =  itp.line_id
    AND   gmd.line_type             =  itp.line_type
--
    AND   xmd.material_detail_id    =  itp.line_id
    AND   xmd.item_id               =  itp.item_id
    AND   xmd.lot_id                =  itp.lot_id
-- 2008/10/28 v1.5 D.Nihei ADD START
    AND itp.doc_type                = gv_doc_type_prod
-- 2008/10/28 v1.5 D.Nihei ADD END
-- 2009/11/24 H.Itou Mod Start 本番障害#1696 フルスキャンするので修正
--    -- 下記2条件でIS NULLの代替とする
--    AND   NOT EXISTS (SELECT 1
--                      FROM ic_tran_pnd itp2
--                      WHERE itp2.reverse_id = itp.trans_id)     -- 保留トランIDがリバースIDに存在しないもの
--    AND   NOT EXISTS (SELECT 1
--                      FROM ic_tran_pnd itp3
--                      WHERE itp3.trans_id = itp.reverse_id)     -- リバースIDが保留トランIDに存在しないもの
    AND   itp.reverse_id IS NULL
-- 2009/11/24 H.Itou Mod End
    AND   itp.completed_ind    =  gv_comp_flag                  -- 完了フラグ＝「完了」
    ------------------------------------------------------------------------
    -- OPM品目カテゴリ割当情報VIEW条件
    AND   gmd.item_id               =  xicv.item_id
    AND   xicv.item_class_code     IN (gv_hinmoku_kbn_genryou
                                      ,gv_hinmoku_kbn_hanseihin
                                      ,gv_hinmoku_kbn_seihin)  -- 原材料、半製品、製品
    ------------------------------------------------------------------------
    ------------------------------------------------------------------------
    --以下変動条件
    ------------------------------------------------------------------------
    --生産原料詳細パラメータ条件
    AND   gmd.batch_id              =  iv_batch_id
    ------------------------------------------------------------------------
    ORDER BY gmd.attribute8             -- 生産原料詳細.DFF8(投入口区分)
            ,xicv.item_class_code       -- OPM品目カテゴリ割当情報VIEW.品目カテゴリコード
            ,TO_NUMBER(ximv.item_no)    -- OPM品目情報VIEW.品目コード
            ,TO_NUMBER(ilm.lot_no)      -- OPMロットマスタ.ロットNo
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
      ov_errmsg  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_errbuf  := ov_errmsg;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END prc_get_reinyu_utikomi_data;
--
--
--
  /**********************************************************************************
   * Procedure Name   : prc_get_tonyu_sizai_data
   * Description      : 明細-投入資材情報抽出処理
   ***********************************************************************************/
  PROCEDURE prc_get_tonyu_sizai_data(
      iv_batch_id             IN         gme_batch_header.batch_id%TYPE  -- バッチID
     ,ot_tonyu_sizai_data     OUT NOCOPY type_tounyu_data_tbl             -- 明細-投入資材情報データ
     ,ov_errbuf               OUT NOCOPY VARCHAR2                        -- エラー・メッセージ           --# 固定 #
     ,ov_retcode              OUT NOCOPY VARCHAR2                        -- リターン・コード             --# 固定 #
     ,ov_errmsg               OUT NOCOPY VARCHAR2                        -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_get_tonyu_sizai_data'; -- プログラム名
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
    -- データ抽出
    -- ====================================================
    SELECT
           --以下処理用項目
           TO_NUMBER(NULL)                                 AS material_detail_id       -- ダミーカラム
          ,TO_CHAR(NULL)                                   AS tounyuguchi_kbn          -- ダミーカラム
           --以下データ用項目
          ,ximv.item_no                                    AS tonyu_sizai_hinmk_cd     -- OPM品目情報VIEW.品目コード
          ,ximv.item_short_name                            AS tonyu_sizai_hinmk_nm     -- OPM品目情報VIEW.品名・略称
          ,TO_CHAR(NULL)                                   AS tonyu_sizai_lot_no       -- ダミーカラム
          ,TO_DATE(NULL)                                   AS tonyu_sizai_make_date    -- ダミーカラム
          ,TO_NUMBER(NULL)                                 AS tonyu_sizai_stock        -- ダミーカラム
          ,xmd.invested_qty                                AS tonyu_sizai_total        -- 生産原料詳細アドオン.投入数量
          ,ximv.item_um                                    AS tonyu_sizai_unit         -- OPM品目情報VIEW.単位
-- 2008/12/17 v1.7 D.Nihei ADD START
          ,NVL(TO_NUMBER(ximv.net) , gv_net_default_val)   AS tonyu_sizai_net          -- OPM品目情報VIEW.NET
-- 2008/12/17 v1.7 D.Nihei ADD END
--
    BULK COLLECT INTO ot_tonyu_sizai_data
--
    FROM   gme_material_details       gmd     -- 生産原料詳細
          ,xxwip_material_detail      xmd     -- 生産原料詳細アドオン
          ,xxcmn_item_mst_v           ximv    -- OPM品目情報VIEW
          ,xxcmn_item_categories5_v   xicv    -- OPM品目カテゴリ割当情報VIEW
    WHERE
    --以下固定条件
    ------------------------------------------------------------------------
    --生産原料詳細条件
          gmd.line_type             =  gv_line_type_kbn_genryou   -- ラインタイプ＝「原料」
    AND   gmd.attribute5            IS NULL                       -- DFF5(打込区分)が未入力
    AND   gmd.attribute24           IS NULL                       -- DFF24(原料削除フラグ)が未入力
    ------------------------------------------------------------------------
    --生産原料詳細アドオン条件
    AND   gmd.material_detail_id    =  xmd.material_detail_id
    AND   xmd.plan_type             =  gv_yotei_kbn_tonyu       -- 予定区分＝「投入」
    ------------------------------------------------------------------------
    -- OPM品目情報VIEW条件
    AND   gmd.item_id               =  ximv.item_id
    ------------------------------------------------------------------------
    -- OPM品目カテゴリ割当情報VIEW条件
    AND   gmd.item_id               =  xicv.item_id
    AND   xicv.item_class_code      =  gv_hinmoku_kbn_sizai                      -- 資材
    ------------------------------------------------------------------------
    ------------------------------------------------------------------------
    --以下変動条件
    ------------------------------------------------------------------------
    --生産原料詳細パラメータ条件
    AND   gmd.batch_id              =  iv_batch_id
    ------------------------------------------------------------------------
    ORDER BY xicv.item_class_code      -- OPM品目カテゴリ割当情報VIEW.品目カテゴリコード
            ,TO_NUMBER(ximv.item_no)   -- OPM品目情報VIEW.品目コード
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
      ov_errmsg  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_errbuf  := ov_errmsg;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END prc_get_tonyu_sizai_data;
--
--
--
  /**********************************************************************************
   * Procedure Name   : prc_get_reinyu_sizai_data
   * Description      : 明細-戻入資材情報抽出処理
   ***********************************************************************************/
  PROCEDURE prc_get_reinyu_sizai_data(
      iv_batch_id           IN         gme_batch_header.batch_id%TYPE   -- バッチID
     ,ot_reinyu_sizai_data  OUT NOCOPY type_tounyu_data_tbl              -- 明細-戻入資材情報データ
     ,ov_errbuf             OUT NOCOPY VARCHAR2                         -- エラー・メッセージ           --# 固定 #
     ,ov_retcode            OUT NOCOPY VARCHAR2                         -- リターン・コード             --# 固定 #
     ,ov_errmsg             OUT NOCOPY VARCHAR2                         -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_get_reinyu_sizai_data'; -- プログラム名
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
    -- データ抽出
    -- ====================================================
    SELECT
           --以下処理用項目
           TO_NUMBER(NULL)                                AS material_detail_id        -- ダミーカラム
          ,TO_CHAR(NULL)                                  AS tounyuguchi_kbn           -- ダミーカラム
           --以下データ用項目
          ,ximv.item_no                                   AS modori_sizai_hinmk_cd     -- OPM品目情報VIEW.品目コード
          ,ximv.item_short_name                           AS modori_sizai_hinmk_nm     -- OPM品目情報VIEW.品名・略称
          ,TO_CHAR(NULL)                                  AS modori_sizai_lot_no       -- ダミーカラム
          ,TO_DATE(NULL)                                  AS modori_sizaii_make_date   -- ダミーカラム
          ,TO_NUMBER(NULL)                                AS modori_sizai_stock        -- ダミーカラム
          ,xmd.return_qty                                 AS modori_sizai_total        -- 生産原料詳細アドオン.戻入数量
          ,ximv.item_um                                   AS modori_sizai_unit         -- OPM品目情報VIEW.単位
-- 2008/12/17 v1.7 D.Nihei ADD START
          ,NVL(TO_NUMBER(ximv.net) , gv_net_default_val) AS modori_sizai_net           -- OPM品目情報VIEW.NET
-- 2008/12/17 v1.7 D.Nihei ADD END
--
    BULK COLLECT INTO ot_reinyu_sizai_data
--
    FROM   gme_material_details       gmd     -- 生産原料詳細
          ,xxwip_material_detail      xmd     -- 生産原料詳細アドオン
          ,xxcmn_item_mst_v           ximv    -- OPM品目情報VIEW
          ,xxcmn_item_categories5_v   xicv    -- OPM品目カテゴリ割当情報VIEW
    WHERE
    --以下固定条件
    ------------------------------------------------------------------------
    --生産原料詳細条件
          gmd.line_type             =  gv_line_type_kbn_genryou       -- ラインタイプ＝「原料」
    AND   gmd.attribute5            IS NULL                           -- DFF5(打込区分)が未入力
    AND   gmd.attribute24           IS NULL                           -- DFF24(原料削除フラグ)が未入力
    ------------------------------------------------------------------------
    --生産原料詳細アドオン条件
    AND   gmd.material_detail_id    =  xmd.material_detail_id
    AND   xmd.plan_type             =  gv_yotei_kbn_tonyu       -- 予定区分＝「投入」
    AND   NVL(xmd.return_qty,0)     <> 0         -- 戻入数量が0でない
    ------------------------------------------------------------------------
    -- OPM品目情報VIEW条件
    AND   gmd.item_id               =  ximv.item_id
    ------------------------------------------------------------------------
    -- OPM品目カテゴリ割当情報VIEW条件
    AND   gmd.item_id               =  xicv.item_id
    AND   xicv.item_class_code      =  gv_hinmoku_kbn_sizai                      -- 資材
    ------------------------------------------------------------------------
    ------------------------------------------------------------------------
    --以下変動条件
    ------------------------------------------------------------------------
    --生産原料詳細パラメータ条件
    AND   gmd.batch_id              =  iv_batch_id
    ------------------------------------------------------------------------
    ORDER BY xicv.item_class_code      -- OPM品目カテゴリ割当情報VIEW.品目カテゴリコード
            ,TO_NUMBER(ximv.item_no)   -- OPM品目情報VIEW.品目コード
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
      ov_errmsg  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_errbuf  := ov_errmsg;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END prc_get_reinyu_sizai_data;
--
--
--
  /**********************************************************************************
   * Procedure Name   : prc_get_seizou_furyo_data
   * Description      : 明細-製造不良情報抽出処理
   ***********************************************************************************/
  PROCEDURE prc_get_seizou_furyo_data(
      iv_batch_id              IN         gme_batch_header.batch_id%TYPE   -- バッチID
     ,ot_seizou_furyo_data     OUT NOCOPY type_tounyu_data_tbl              -- 明細-製造不良情報データ
     ,ov_errbuf                OUT NOCOPY VARCHAR2                         -- エラー・メッセージ           --# 固定 #
     ,ov_retcode               OUT NOCOPY VARCHAR2                         -- リターン・コード             --# 固定 #
     ,ov_errmsg                OUT NOCOPY VARCHAR2                         -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_get_seizou_furyo_data'; -- プログラム名
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
    -- データ抽出
    -- ====================================================
    SELECT
           --以下処理用項目
           TO_NUMBER(NULL)                                AS material_detail_id       -- ダミーカラム
          ,TO_CHAR(NULL)                                  AS tounyuguchi_kbn          -- ダミーカラム
           --以下データ用項目
          ,ximv.item_no                                   AS make_furyou_hinmk_cd     -- OPM品目情報VIEW.品目コード
          ,ximv.item_short_name                           AS make_furyou_hinmk_nm     -- OPM品目情報VIEW.品名・略称
          ,TO_CHAR(NULL)                                  AS make_furyou_lot_no       -- ダミーカラム
          ,TO_DATE(NULL)                                  AS make_furyou_make_date    -- ダミーカラム
          ,TO_NUMBER(NULL)                                AS make_furyou_stock        -- ダミーカラム
          ,xmd.mtl_prod_qty                               AS make_furyou_total        -- 生産原料詳細アドオン.資材製造不良数
          ,ximv.item_um                                   AS make_furyou_unit         -- OPM品目情報VIEW.単位
-- 2008/12/17 v1.7 D.Nihei ADD START
          ,NVL(TO_NUMBER(ximv.net) , gv_net_default_val)  AS make_furyou_net          -- OPM品目情報VIEW.NET
-- 2008/12/17 v1.7 D.Nihei ADD END
--
    BULK COLLECT INTO ot_seizou_furyo_data
--
    FROM   gme_material_details       gmd     -- 生産原料詳細
          ,xxwip_material_detail      xmd     -- 生産原料詳細アドオン
          ,xxcmn_item_mst_v           ximv    -- OPM品目情報VIEW
          ,xxcmn_item_categories5_v   xicv    -- OPM品目カテゴリ割当情報VIEW
    WHERE
    --以下固定条件
    ------------------------------------------------------------------------
    --生産原料詳細条件
          gmd.line_type             =  gv_line_type_kbn_genryou       -- ラインタイプ＝「原料」
    AND   gmd.attribute5            IS NULL                           -- DFF5(打込区分)が未入力
    AND   gmd.attribute24           IS NULL     -- DFF24(原料削除フラグ)が未入力
    ------------------------------------------------------------------------
    --生産原料詳細アドオン条件
    AND   gmd.material_detail_id    =  xmd.material_detail_id
    AND   xmd.plan_type             =  gv_yotei_kbn_tonyu       -- 予定区分＝「投入」
    AND   NVL(xmd.mtl_prod_qty,0)   <> 0         -- 資材製造不良数が0でない
    ------------------------------------------------------------------------
    -- OPM品目情報VIEW条件
    AND   gmd.item_id               =  ximv.item_id
    ------------------------------------------------------------------------
    -- OPM品目カテゴリ割当情報VIEW条件
    AND   gmd.item_id               =  xicv.item_id
    AND   xicv.item_class_code      =  gv_hinmoku_kbn_sizai                      -- 資材
    ------------------------------------------------------------------------
    ------------------------------------------------------------------------
    --以下変動条件
    ------------------------------------------------------------------------
    --生産原料詳細パラメータ条件
    AND   gmd.batch_id              =  iv_batch_id
    ------------------------------------------------------------------------
    ORDER BY xicv.item_class_code       -- OPM品目カテゴリ割当情報VIEW.品目カテゴリコード
            ,TO_NUMBER(ximv.item_no)    -- OPM品目情報VIEW.品目コード
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
      ov_errmsg  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_errbuf  := ov_errmsg;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END prc_get_seizou_furyo_data;
--
--
--
  /**********************************************************************************
   * Procedure Name   : prc_get_gyousha_furyo_data
   * Description      : 明細-業者不良情報抽出処理
   ***********************************************************************************/
  PROCEDURE prc_get_gyousha_furyo_data(
      iv_batch_id              IN         gme_batch_header.batch_id%TYPE   -- バッチID
     ,ot_gyousha_furyo_data    OUT NOCOPY type_tounyu_data_tbl              -- 明細-業者不良情報データ
     ,ov_errbuf                OUT NOCOPY VARCHAR2                         -- エラー・メッセージ           --# 固定 #
     ,ov_retcode               OUT NOCOPY VARCHAR2                         -- リターン・コード             --# 固定 #
     ,ov_errmsg                OUT NOCOPY VARCHAR2                         -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_get_gyousha_furyo_data'; -- プログラム名
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
    -- データ抽出
    -- ====================================================
    SELECT
           --以下処理用項目
           TO_NUMBER(NULL)                                AS material_detail_id         -- ダミーカラム
          ,TO_CHAR(NULL)                                  AS tounyuguchi_kbn            -- ダミーカラム
           --以下データ用項目
          ,ximv.item_no                                   AS gyosya_furyou_hinmk_cd     -- OPM品目情報VIEW.品目コード
          ,ximv.item_short_name                           AS gyosya_furyou_hinmk_nm     -- OPM品目情報VIEW.品名・略称
          ,TO_CHAR(NULL)                                  AS gyosya_furyou_lot_no       -- ダミーカラム
          ,TO_DATE(NULL)                                  AS gyosya_furyou_make_date    -- ダミーカラム
          ,TO_NUMBER(NULL)                                AS gyosya_furyou_stock        -- ダミーカラム
          ,xmd.mtl_mfg_qty                                AS gyosya_furyou_total        -- 生産原料詳細アドオン.資材業者不良数
          ,ximv.item_um                                   AS gyosya_furyou_unit         -- OPM品目情報VIEW.単位
-- 2008/12/17 v1.7 D.Nihei ADD START
          ,NVL(TO_NUMBER(ximv.net) , gv_net_default_val)  AS gyosya_furyou_net          -- OPM品目情報VIEW.NET
-- 2008/12/17 v1.7 D.Nihei ADD END
--
    BULK COLLECT INTO ot_gyousha_furyo_data
--
    FROM   gme_material_details       gmd     -- 生産原料詳細
          ,xxwip_material_detail      xmd     -- 生産原料詳細アドオン
          ,xxcmn_item_mst_v           ximv    -- OPM品目情報VIEW
          ,xxcmn_item_categories5_v   xicv    -- OPM品目カテゴリ割当情報VIEW
    WHERE
    --以下固定条件
    ------------------------------------------------------------------------
    --生産原料詳細条件
          gmd.line_type             =  gv_line_type_kbn_genryou       -- ラインタイプ＝「原料」
    AND   gmd.attribute5            IS NULL                           -- DFF5(打込区分)が未入力
    AND   gmd.attribute24           IS NULL                           -- DFF24(原料削除フラグ)が未入力
    ------------------------------------------------------------------------
    --生産原料詳細アドオン条件
    AND   gmd.material_detail_id    =  xmd.material_detail_id
    AND   xmd.plan_type             =  gv_yotei_kbn_tonyu       -- 予定区分＝「投入」
    AND   NVL(xmd.mtl_mfg_qty,0)    <> 0         -- 資材業者不良数が0でない
    ------------------------------------------------------------------------
    -- OPM品目情報VIEW条件
    AND   gmd.item_id               =  ximv.item_id
    ------------------------------------------------------------------------
    -- OPM品目カテゴリ割当情報VIEW条件
    AND   gmd.item_id               =  xicv.item_id
    AND   xicv.item_class_code      =  gv_hinmoku_kbn_sizai                      -- 資材
    ------------------------------------------------------------------------
    ------------------------------------------------------------------------
    --以下変動条件
    ------------------------------------------------------------------------
    --生産原料詳細パラメータ条件
    AND   gmd.batch_id              =  iv_batch_id
    ------------------------------------------------------------------------
    ORDER BY xicv.item_class_code       -- OPM品目カテゴリ割当情報VIEW.品目カテゴリコード
            ,TO_NUMBER(ximv.item_no)    -- OPM品目情報VIEW.品目コード
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
      ov_errmsg  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_errbuf  := ov_errmsg;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END prc_get_gyousha_furyo_data;
--
--
--
  /**********************************************************************************
   * Procedure Name   : prc_check_param_data
   * Description      : パラメータチェック処理
   ***********************************************************************************/
  PROCEDURE prc_check_param_data(
      iv_den_kbn           IN            VARCHAR2         -- 01 : 伝票区分
     ,iv_plant             IN            VARCHAR2         -- 02 : プラント
     ,iv_line_no           IN            VARCHAR2         -- 03 : ラインNo
     ,iv_make_date_from    IN            VARCHAR2         -- 04 : 生産日(FROM)
     ,iv_make_date_to      IN            VARCHAR2         -- 05 : 生産日(TO)
     ,iv_tehai_no_from     IN            VARCHAR2         -- 06 : 手配No(FROM)
     ,iv_tehai_no_to       IN            VARCHAR2         -- 07 : 手配No(TO)
     ,iv_hinmoku_cd        IN            VARCHAR2         -- 08 : 品目コード
     ,iv_input_date_from   IN            VARCHAR2         -- 09 : 入力日時(FROM)
     ,iv_input_date_to     IN            VARCHAR2         -- 10 : 入力日時(TO)
     ,id_now_date          IN            DATE             -- 現在日付
     ,or_param             OUT NOCOPY    type_param_rec   -- 入力パラメータ
     ,ov_errbuf            OUT NOCOPY    VARCHAR2         -- エラー・メッセージ             --# 固定 #
     ,ov_retcode           OUT NOCOPY    VARCHAR2         -- リターン・コード               --# 固定 #
     ,ov_errmsg            OUT NOCOPY    VARCHAR2         -- ユーザー・エラー・メッセージ   --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_check_param_data'; -- プログラム名
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
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- チェックなしのパラメータ格納
    or_param.iv_den_kbn          := iv_den_kbn;                                  -- 01 : 伝票区分
    or_param.iv_plant            := iv_plant;                                    -- 02 : プラント
    or_param.iv_line_no          := iv_line_no;                                  -- 03 : ラインNo
    or_param.id_tehai_no_from    := iv_tehai_no_from;                            -- 06 : 手配No(FROM)
    or_param.id_tehai_no_to      := iv_tehai_no_to;                              -- 07 : 手配No(TO)
    or_param.iv_hinmoku_cd       := iv_hinmoku_cd;                               -- 08 : 品目コード
--
    -- ====================================================
    -- 生産日(FROM)フォーマットチェック
    -- ====================================================
    IF (iv_make_date_from IS NOT NULL) THEN
      -- 入力がある場合に実施
      validate_date_format(
            iv_validate_date   => iv_make_date_from                  -- チェック対象日付
           ,iv_err_item_val    => gv_err_make_date_from              -- エラー項目名称
           ,iv_date_format     => gv_date_format3                    -- 変換フォーマット
           ,od_change_date     => or_param.id_make_date_from         -- 変換後日付
           ,ov_errbuf          => lv_errbuf                          -- エラー・メッセージ           --# 固定 #
           ,ov_retcode         => lv_retcode                         -- リターン・コード             --# 固定 #
           ,ov_errmsg          => lv_errmsg                          -- ユーザー・エラー・メッセージ --# 固定 #
      );
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt ;
      END IF ;
--
    END IF;
--
    -- ====================================================
    -- 生産日(TO)フォーマットチェック
    -- ====================================================
    IF (iv_make_date_to IS NOT NULL) THEN
      -- 入力がある場合に実施
      validate_date_format(
            iv_validate_date   => iv_make_date_to                    -- チェック対象日付
           ,iv_err_item_val    => gv_err_make_date_to                -- エラー項目名称
           ,iv_date_format     => gv_date_format3                    -- 変換フォーマット
           ,od_change_date     => or_param.id_make_date_to           -- 変換後日付
           ,ov_errbuf          => lv_errbuf                          -- エラー・メッセージ           --# 固定 #
           ,ov_retcode         => lv_retcode                         -- リターン・コード             --# 固定 #
           ,ov_errmsg          => lv_errmsg                          -- ユーザー・エラー・メッセージ --# 固定 #
      );
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt ;
      END IF ;
--
    END IF;
--
    -- ====================================================
    -- 入力日時(FROM)フォーマットチェック
    -- ====================================================
    validate_date_format(
          iv_validate_date   => iv_input_date_from                 -- チェック対象日付
         ,iv_err_item_val    => gv_err_input_date_from             -- エラー項目名称
-- 変更 START 2008/05/02 Oikawa
         ,iv_date_format     => gv_date_format1                    -- 変換フォーマット
--         ,iv_date_format     => gv_date_format2                    -- 変換フォーマット
-- 変更 END
         ,od_change_date     => or_param.id_input_date_from        -- 変換後日付
         ,ov_errbuf          => lv_errbuf                          -- エラー・メッセージ           --# 固定 #
         ,ov_retcode         => lv_retcode                         -- リターン・コード             --# 固定 #
         ,ov_errmsg          => lv_errmsg                          -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt ;
    END IF ;
--
    -- ====================================================
    -- 入力日時(TO)フォーマットチェック
    -- ====================================================
    validate_date_format(
          iv_validate_date   => iv_input_date_to                   -- チェック対象日付
         ,iv_err_item_val    => gv_err_input_date_to               -- エラー項目名称
-- 変更 START 2008/05/02 Oikawa
         ,iv_date_format     => gv_date_format1                    -- 変換フォーマット
--         ,iv_date_format     => gv_date_format2                    -- 変換フォーマット
-- 変更 END
         ,od_change_date     => or_param.id_input_date_to          -- 変換後日付
         ,ov_errbuf          => lv_errbuf                          -- エラー・メッセージ           --# 固定 #
         ,ov_retcode         => lv_retcode                         -- リターン・コード             --# 固定 #
         ,ov_errmsg          => lv_errmsg                          -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt ;
    END IF ;
--
    -- ====================================================
    -- 未来日チェック　入力日時（FROM）
    -- ====================================================
    IF (TRUNC(or_param.id_input_date_from, 'DD') > TRUNC(id_now_date, 'DD')) THEN
      -- メッセージセット
      lv_errmsg := xxcmn_common_pkg.get_msg( gc_application_wip
                                            ,'APP-XXWIP-10001'
                                            ,gv_tkn_date
                                            ,gv_err_input_date_from
                                            ,gv_tkn_value
                                            ,TO_CHAR(or_param.id_input_date_from, gv_date_format2)) ;
      RAISE global_process_expt ;
    END IF;
--    
    -- ====================================================
    -- 未来日チェック　入力日時（TO）
    -- ====================================================
    IF (TRUNC(or_param.id_input_date_to, 'DD') > TRUNC(id_now_date, 'DD')) THEN
      -- メッセージセット
      lv_errmsg := xxcmn_common_pkg.get_msg( gc_application_wip
                                            ,'APP-XXWIP-10001'
                                            ,gv_tkn_date
                                            ,gv_err_input_date_to
                                            ,gv_tkn_value
                                            ,TO_CHAR(or_param.id_input_date_to, gv_date_format2)) ;
      RAISE global_process_expt ;
    END IF;
--
    -- ====================================================
    -- 妥当性チェック　生産日（FROM/TO）
    -- ====================================================
-- 2009/11/24 H.Itou Add Start 本番障害#1696
    -- FROMかTO片方の指定は不可
    IF  (((or_param.id_make_date_from IS NOT NULL)
      AND (or_param.id_make_date_to   IS NULL    )) 
      OR ((or_param.id_make_date_from IS NULL    )
      AND (or_param.id_make_date_to   IS NOT NULL))) THEN
      -- メッセージセット
      lv_errmsg := xxcmn_common_pkg.get_msg( gc_application_wip
                                            ,'APP-XXWIP-10089'
                                            ,gv_tkn_item
                                            ,gv_err_make_date) ;
      RAISE global_process_expt ;
    END IF;
-- 2009/11/24 H.Itou Add End
    IF (or_param.id_make_date_from > or_param.id_make_date_to) THEN
      -- メッセージセット
      lv_errmsg := xxcmn_common_pkg.get_msg( gc_application_wip
                                            ,'APP-XXWIP-10016'
                                            ,gv_tkn_param1
                                            ,gv_err_make_date_from
                                            ,gv_tkn_param2
                                            ,gv_err_make_date_to) ;
      RAISE global_process_expt ;
    END IF;
--
-- 2009/11/24 H.Itou Add Start 本番障害#1696
    -- ====================================================
    -- 妥当性チェック　手配No（FROM/TO）
    -- ====================================================
    -- FROMかTO片方の指定は不可
    IF  (((or_param.id_tehai_no_from IS NOT NULL)
      AND (or_param.id_tehai_no_to   IS NULL    )) 
      OR ((or_param.id_tehai_no_from IS NULL    )
      AND (or_param.id_tehai_no_to   IS NOT NULL))) THEN
      -- メッセージセット
      lv_errmsg := xxcmn_common_pkg.get_msg( gc_application_wip
                                            ,'APP-XXWIP-10089'
                                            ,gv_tkn_item
                                            ,gv_err_tehai_no) ;
      RAISE global_process_expt ;
    END IF;
--
    -- FROM>TOは不可
    IF (or_param.id_tehai_no_from > or_param.id_tehai_no_to) THEN
      -- メッセージセット
      lv_errmsg := xxcmn_common_pkg.get_msg( gc_application_wip
                                            ,'APP-XXWIP-10002'
                                            ,gv_tkn_from
                                            ,gv_err_tehai_no_from
                                            ,gv_tkn_to
                                            ,gv_err_tehai_no_to) ;
      RAISE global_process_expt ;
    END IF;
-- 2009/11/24 H.Itou Add End
    -- ====================================================
    -- 妥当性チェック　入力日時（FROM/TO）
    -- ====================================================
    IF (or_param.id_input_date_from > or_param.id_input_date_to) THEN
      -- メッセージセット
      lv_errmsg := xxcmn_common_pkg.get_msg( gc_application_wip
                                            ,'APP-XXWIP-10016'
                                            ,gv_tkn_param1
                                            ,gv_err_input_date_from
                                            ,gv_tkn_param2
                                            ,gv_err_input_date_to) ;
      RAISE global_process_expt ;
    END IF;
--
  EXCEPTION
--
      -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg ;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errmsg,1,5000) ;
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
  END prc_check_param_data ;
--
--
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
      iv_den_kbn           IN      VARCHAR2         -- 01 : 伝票区分
     ,iv_plant             IN      VARCHAR2         -- 02 : プラント
     ,iv_line_no           IN      VARCHAR2         -- 03 : ラインNo
     ,iv_make_date_from    IN      VARCHAR2         -- 04 : 生産日(FROM)
     ,iv_make_date_to      IN      VARCHAR2         -- 05 : 生産日(TO)
     ,iv_tehai_no_from     IN      VARCHAR2         -- 06 : 手配No(FROM)
     ,iv_tehai_no_to       IN      VARCHAR2         -- 07 : 手配No(TO)
     ,iv_hinmoku_cd        IN      VARCHAR2         -- 08 : 品目コード
     ,iv_input_date_from   IN      VARCHAR2         -- 09 : 入力日時(FROM)
     ,iv_input_date_to     IN      VARCHAR2         -- 10 : 入力日時(TO)
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
    lr_param_rec            type_param_rec ;         -- パラメータ受渡し用
    lt_head_data            type_head_data_tbl ;     -- 取得レコード表（ヘッダ情報）
    lt_tonyu_data           type_tounyu_data_tbl ;    -- 取得レコード表（明細-投入情報）
    lt_reinyu_tonyu_data    type_tounyu_data_tbl ;    -- 取得レコード表（明細-戻入（投入分）情報）
    lt_fukusanbutu_data     type_tounyu_data_tbl ;    -- 取得レコード表（明細-副産物情報）
    lt_utikomi_data         type_tounyu_data_tbl ;    -- 取得レコード表（明細-打込情報）
    lt_reinyu_utikomi_data  type_tounyu_data_tbl ;    -- 取得レコード表（明細-戻入（打込分）情報）
    lt_tonyu_sizai_data     type_tounyu_data_tbl ;    -- 取得レコード表（明細-投入資材情報）
    lt_reinyu_sizai_data    type_tounyu_data_tbl ;    -- 取得レコード表（明細-戻入資材情報）
    lt_seizou_furyo_data    type_tounyu_data_tbl ;    -- 取得レコード表（明細-製造不良情報）
    lt_gyousha_furyo_data   type_tounyu_data_tbl ;    -- 取得レコード表（明細-業者不良情報）
--
    -- システム日付
    ld_now_date             DATE DEFAULT SYSDATE;
    -- ループカウンタ変数
    ln_loop_cnt             PLS_INTEGER ;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal ;
--
--###########################  固定部 END   ############################
--
    -- =====================================================
    -- パラメータチェック
    -- =====================================================
    prc_check_param_data(
      iv_den_kbn           =>     iv_den_kbn           -- 01 : 伝票区分
     ,iv_plant             =>     iv_plant             -- 02 : プラント
     ,iv_line_no           =>     iv_line_no           -- 03 : ラインNo
     ,iv_make_date_from    =>     iv_make_date_from  -- 04 : 生産日(FROM)
     ,iv_make_date_to      =>     iv_make_date_to    -- 05 : 生産日(TO)
     ,iv_tehai_no_from     =>     iv_tehai_no_from     -- 06 : 手配No(FROM)
     ,iv_tehai_no_to       =>     iv_tehai_no_to       -- 07 : 手配No(TO)
     ,iv_hinmoku_cd        =>     iv_hinmoku_cd        -- 08 : 品目コード
     ,iv_input_date_from   =>     iv_input_date_from   -- 09 : 入力日時(FROM)
     ,iv_input_date_to     =>     iv_input_date_to     -- 10 : 入力日時(TO)
     ,id_now_date          =>     ld_now_date          -- 現在日付
     ,or_param             =>     lr_param_rec         -- 入力パラメータ
     ,ov_errbuf            =>     lv_errbuf            -- エラー・メッセージ             --# 固定 #
     ,ov_retcode           =>     lv_retcode           -- リターン・コード               --# 固定 #
     ,ov_errmsg            =>     lv_errmsg            -- ユーザー・エラー・メッセージ   --# 固定 #
    );
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt ;
    END IF ;
--
    -- =====================================================
    -- ヘッダー情報抽出処理
    -- =====================================================
    prc_get_head_data(
        ir_param          =>   lr_param_rec       -- 入力パラメータレコード
       ,ot_head_data      =>   lt_head_data       -- 取得レコード群
       ,ov_errbuf         =>   lv_errbuf          -- エラー・メッセージ           --# 固定 #
       ,ov_retcode        =>   lv_retcode         -- リターン・コード             --# 固定 #
       ,ov_errmsg         =>   lv_errmsg          -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    IF ( lv_retcode = gv_status_error ) THEN
      RAISE global_process_expt ;
    END IF ;
--
    --ヘッダ情報ループ
    <<head_data_loop>>
    FOR ln_loop_cnt IN 1..lt_head_data.COUNT LOOP
--
      -- =====================================================
      -- 明細-投入情報抽出処理
      -- =====================================================
      prc_get_tonyu_data(
         iv_batch_id     => lt_head_data(ln_loop_cnt).l_batch_id   -- バッチID
        ,ot_tonyu_data   => lt_tonyu_data                          -- 明細-投入情報データ
        ,ov_errbuf       => lv_errbuf                              -- エラー・メッセージ           --# 固定 #
        ,ov_retcode      => lv_retcode                             -- リターン・コード             --# 固定 #
        ,ov_errmsg       => lv_errmsg                              -- ユーザー・エラー・メッセージ --# 固定 #
      );
--
      IF ( lv_retcode = gv_status_error ) THEN
        RAISE global_process_expt ;
      END IF ;
--
      -- =====================================================
      -- 明細-戻入（投入分）情報抽出処理
      -- =====================================================
      prc_get_reinyu_tonyu_data(
           iv_batch_id             =>   lt_head_data(ln_loop_cnt).l_batch_id   -- バッチID
          ,ot_reinyu_tonyu_data    =>   lt_reinyu_tonyu_data                   -- 明細-戻入（投入分）情報データ
          ,ov_errbuf               =>   lv_errbuf                              -- エラー・メッセージ           --# 固定 #
          ,ov_retcode              =>   lv_retcode                             -- リターン・コード             --# 固定 #
          ,ov_errmsg               =>   lv_errmsg                              -- ユーザー・エラー・メッセージ  --# 固定 #
      );
--
      IF ( lv_retcode = gv_status_error ) THEN
        RAISE global_process_expt ;
      END IF ;
--
      -- =====================================================
      -- 明細-副産物情報抽出処理
      -- =====================================================
      prc_get_fsanbutu_data(
          iv_batch_id           =>   lt_head_data(ln_loop_cnt).l_batch_id   -- バッチID
         ,ot_fukusanbutu_data   =>   lt_fukusanbutu_data                    -- 取得レコード群
         ,ov_errbuf             =>   lv_errbuf                              -- エラー・メッセージ          --# 固定 #
         ,ov_retcode            =>   lv_retcode                             -- リターン・コード            --# 固定 #
         ,ov_errmsg             =>   lv_errmsg                              -- ユーザー・エラー・メッセージ --# 固定 #
      );
--
      IF ( lv_retcode = gv_status_error ) THEN
        RAISE global_process_expt ;
      END IF ;
--
--
      -- =====================================================
      -- 明細-打込情報抽出処理
      -- =====================================================
      prc_get_utikomi_data(
          iv_batch_id       =>   lt_head_data(ln_loop_cnt).l_batch_id   -- バッチID
         ,ot_utikomi_data   =>   lt_utikomi_data                        -- 明細-打込情報データ
         ,ov_errbuf         =>   lv_errbuf                              -- エラー・メッセージ          --# 固定 #
         ,ov_retcode        =>   lv_retcode                             -- リターン・コード            --# 固定 #
         ,ov_errmsg         =>   lv_errmsg                              -- ユーザー・エラー・メッセージ --# 固定 #
      );
--
      IF ( lv_retcode = gv_status_error ) THEN
        RAISE global_process_expt ;
      END IF ;
--
--
      -- =====================================================
      -- 明細-戻入（打込分）情報抽出処理
      -- =====================================================
      prc_get_reinyu_utikomi_data(
          iv_batch_id              =>   lt_head_data(ln_loop_cnt).l_batch_id   -- バッチID
         ,ot_reinyu_utikomi_data   =>   lt_reinyu_utikomi_data                 -- 明細-戻入（打込分）情報データ
         ,ov_errbuf                =>   lv_errbuf                              -- エラー・メッセージ           --# 固定 #
         ,ov_retcode               =>   lv_retcode                             -- リターン・コード             --# 固定 #
         ,ov_errmsg                =>   lv_errmsg                              -- ユーザー・エラー・メッセージ --# 固定 #
      );
--
      IF ( lv_retcode = gv_status_error ) THEN
        RAISE global_process_expt ;
      END IF ;
--
--
      -- =====================================================
      -- 明細-投入資材情報抽出処理
      -- =====================================================
      prc_get_tonyu_sizai_data(
          iv_batch_id           =>   lt_head_data(ln_loop_cnt).l_batch_id   -- バッチID
         ,ot_tonyu_sizai_data   =>   lt_tonyu_sizai_data                    -- 明細-投入資材情報データ
         ,ov_errbuf             =>   lv_errbuf                              -- エラー・メッセージ          --# 固定 #
         ,ov_retcode            =>   lv_retcode                             -- リターン・コード            --# 固定 #
         ,ov_errmsg             =>   lv_errmsg                              -- ユーザー・エラー・メッセージ --# 固定 #
      );
--
      IF ( lv_retcode = gv_status_error ) THEN
        RAISE global_process_expt ;
      END IF ;
--
--
      -- =====================================================
      -- 明細-戻入資材情報抽出処理
      -- =====================================================
      prc_get_reinyu_sizai_data(
          iv_batch_id           =>   lt_head_data(ln_loop_cnt).l_batch_id   -- バッチID
         ,ot_reinyu_sizai_data  =>   lt_reinyu_sizai_data                   -- 明細-戻入資材情報データ
         ,ov_errbuf             =>   lv_errbuf                              -- エラー・メッセージ          --# 固定 #
         ,ov_retcode            =>   lv_retcode                             -- リターン・コード            --# 固定 #
         ,ov_errmsg             =>   lv_errmsg                              -- ユーザー・エラー・メッセージ --# 固定 #
      );
--
      IF ( lv_retcode = gv_status_error ) THEN
        RAISE global_process_expt ;
      END IF ;
--
--
      -- =====================================================
      -- 明細-製造不良情報抽出処理
      -- =====================================================
      prc_get_seizou_furyo_data
        (
          iv_batch_id           =>   lt_head_data(ln_loop_cnt).l_batch_id   -- バッチID
         ,ot_seizou_furyo_data  =>   lt_seizou_furyo_data         -- 明細-製造不良情報データ
         ,ov_errbuf             =>   lv_errbuf                    -- エラー・メッセージ           --# 固定 #
         ,ov_retcode            =>   lv_retcode                   -- リターン・コード             --# 固定 #
         ,ov_errmsg             =>   lv_errmsg                    -- ユーザー・エラー・メッセージ --# 固定 #
      );
--
      IF ( lv_retcode = gv_status_error ) THEN
        RAISE global_process_expt ;
      END IF ;
--
      -- =====================================================
      -- 明細-業者不良情報抽出処理
      -- =====================================================
      prc_get_gyousha_furyo_data(
          iv_batch_id             =>   lt_head_data(ln_loop_cnt).l_batch_id   -- バッチID
         ,ot_gyousha_furyo_data   =>   lt_gyousha_furyo_data        -- 明細-業者不良情報データ
         ,ov_errbuf               =>   lv_errbuf                    -- エラー・メッセージ          --# 固定 #
         ,ov_retcode              =>   lv_retcode                   -- リターン・コード            --# 固定 #
         ,ov_errmsg               =>   lv_errmsg                    -- ユーザー・エラー・メッセージ --# 固定 #
      );
--
      IF ( lv_retcode = gv_status_error ) THEN
        RAISE global_process_expt ;
      END IF ;
--
--
      -- =====================================================
      -- XMLデータ作成処理
      -- =====================================================
      prc_create_xml_data(
          ir_param_rec           =>   lr_param_rec               -- 入力パラメータレコード
         ,ir_head_data           =>   lt_head_data(ln_loop_cnt)  -- ヘッダー情報
         ,it_tonyu_data          =>   lt_tonyu_data              -- 投入情報
         ,it_reinyu_tonyu_data   =>   lt_reinyu_tonyu_data       -- 明細-戻入（投入分）情報
         ,it_fukusanbutu_data    =>   lt_fukusanbutu_data        -- 明細-副産物情報
         ,it_utikomi_data        =>   lt_utikomi_data            -- 明細-打込情報
         ,it_reinyu_utikomi_data =>   lt_reinyu_utikomi_data     -- 明細-戻入（打込分）情報
         ,it_tonyu_sizai_data    =>   lt_tonyu_sizai_data        -- 明細-投入資材情報
         ,it_reinyu_sizai_data   =>   lt_reinyu_sizai_data       -- 明細-戻入資材情報
         ,it_seizou_furyo_data   =>   lt_seizou_furyo_data       -- 明細-製造不良情報
         ,it_gyousha_furyo_data  =>   lt_gyousha_furyo_data      -- 明細-業者不良情報
         ,id_now_date            =>   ld_now_date                -- 現在日付
         ,ov_errbuf              =>   lv_errbuf                  -- エラー・メッセージ           --# 固定 #
         ,ov_retcode             =>   lv_retcode                 -- リターン・コード             --# 固定 #
         ,ov_errmsg              =>   lv_errmsg                  -- ユーザー・エラー・メッセージ  --# 固定 #
      );
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt ;
      END IF ;
--
      -- =====================================================
      -- 明細情報初期化
      -- =====================================================
      lt_tonyu_data.DELETE;            -- 取得レコード表（明細-投入情報）
      lt_reinyu_tonyu_data.DELETE;     -- 取得レコード表（明細-戻入（投入分）情報）
      lt_fukusanbutu_data.DELETE;      -- 取得レコード表（明細-副産物情報）
      lt_utikomi_data.DELETE;          -- 取得レコード表（明細-打込情報）
      lt_reinyu_utikomi_data.DELETE;   -- 取得レコード表（明細-戻入（打込分）情報）
      lt_tonyu_sizai_data.DELETE;      -- 取得レコード表（明細-投入資材情報）
      lt_reinyu_sizai_data.DELETE;     -- 取得レコード表（明細-戻入資材情報）
      lt_seizou_furyo_data.DELETE;     -- 取得レコード表（明細-製造不良情報）
      lt_gyousha_furyo_data.DELETE;    -- 取得レコード表（明細-業者不良情報）
--
    END LOOP head_data_loop ;
--
    IF (lt_head_data.COUNT = 0) THEN
--
      -- =====================================================
      -- 取得データ０件時XMLデータ作成処理
      -- =====================================================
      prc_create_zeroken_xml_data(
          ir_param          =>   lr_param_rec       -- 入力パラメータレコード
         ,ov_errbuf         =>   lv_errbuf          -- エラー・メッセージ           --# 固定 #
         ,ov_retcode        =>   lv_retcode         -- リターン・コード             --# 固定 #
         ,ov_errmsg         =>   lv_errmsg          -- ユーザー・エラー・メッセージ  --# 固定 #
      );
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt ;
      END IF ;
--
    END IF;
--
    -- =====================================================
    -- XMLデータ出力処理
    -- =====================================================
    prc_out_xml_data(
        ov_errbuf         =>   lv_errbuf          -- エラー・メッセージ           --# 固定 #
       ,ov_retcode        =>   lv_retcode         -- リターン・コード             --# 固定 #
       ,ov_errmsg         =>   lv_errmsg          -- ユーザー・エラー・メッセージ  --# 固定 #
    );
--
    IF (lv_retcode = gv_status_error) THEN   -- リターンコード＝「エラー」
      RAISE global_process_expt ;
--
    ELSIF (    (lv_retcode = gv_status_normal)
           AND (lt_head_data.COUNT = 0)) THEN  -- リターンコード＝「正常」かつ件数が0件
      lv_retcode := gv_status_warn;
--
    END IF;
--
    -- ==================================================
    -- 終了ステータス設定
    -- ==================================================
    ov_retcode := lv_retcode ;
    ov_errmsg  := lv_errmsg ;
    ov_errbuf  := lv_errbuf ;
--
  EXCEPTION
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
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : コンカレント実行ファイル登録プロシージャ
   **********************************************************************************/
  PROCEDURE main(
      errbuf                OUT    VARCHAR2         -- エラーメッセージ
     ,retcode               OUT    VARCHAR2         -- エラーコード
     ,iv_den_kbn            IN     VARCHAR2         -- 01 : 伝票区分
     ,iv_plant              IN     VARCHAR2         -- 02 : プラント
     ,iv_line_no            IN     VARCHAR2         -- 03 : ラインNo
     ,iv_make_date_from     IN     VARCHAR2         -- 04 : 生産日(FROM)
     ,iv_make_date_to       IN     VARCHAR2         -- 05 : 生産日(TO)
     ,iv_tehai_no_from      IN     VARCHAR2         -- 06 : 手配No(FROM)
     ,iv_tehai_no_to        IN     VARCHAR2         -- 07 : 手配No(TO)
     ,iv_hinmoku_cd         IN     VARCHAR2         -- 08 : 品目コード
     ,iv_input_date_from    IN     VARCHAR2         -- 09 : 入力日時(FROM)
     ,iv_input_date_to      IN     VARCHAR2         -- 10 : 入力日時(TO)
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
        iv_den_kbn            => iv_den_kbn           -- 01 : 伝票区分
       ,iv_plant              => iv_plant             -- 02 : プラント
       ,iv_line_no            => iv_line_no           -- 03 : ラインNo
       ,iv_make_date_from     => iv_make_date_from    -- 04 : 生産日(FROM)
       ,iv_make_date_to       => iv_make_date_to      -- 05 : 生産日(TO)
       ,iv_tehai_no_from      => iv_tehai_no_from     -- 06 : 手配No(FROM)
       ,iv_tehai_no_to        => iv_tehai_no_to       -- 07 : 手配No(TO)
       ,iv_hinmoku_cd         => iv_hinmoku_cd        -- 08 : 品目コード
       ,iv_input_date_from    => iv_input_date_from   -- 09 : 入力日時(FROM)
       ,iv_input_date_to      => iv_input_date_to     -- 10 : 入力日時(TO)
       ,ov_errbuf             => lv_errbuf            -- エラー・メッセージ           --# 固定 #
       ,ov_retcode            => lv_retcode           -- リターン・コード             --# 固定 #
       ,ov_errmsg             => lv_errmsg            -- ユーザー・エラー・メッセージ --# 固定 #
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
--
--
END xxwip230002c ;
/
