create or replace
PACKAGE BODY xxwip230001c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2007,2008. All rights reserved.
 *
 * Package Name     : xxwip230001c(body)
 * Description      : 生産帳票機能（生産依頼書兼生産指図書）
 * MD.050/070       : 生産帳票機能（生産依頼書兼生産指図書）Issue1.1  (T_MD050_BPO_230)
 *                    生産帳票機能（生産依頼書兼生産指図書）          (T_MD070_BPO_23A)
 * Version          : 1.11
 *
 * Program List
 * ---------------------------- ----------------------------------------------------------
 *  Name                         Description
 * ---------------------------- ----------------------------------------------------------
 *  fnc_conv_xml                 FUNCTION  : ＸＭＬタグに変換する。
 *  prc_out_xml_data             PROCEDURE : タグ情報出力処理
 *  prc_create_xml_data          PROCEDURE : ＸＭＬタグ情報設定処理
 *  prc_get_sizai_data           PROCEDURE : 明細（資材）情報取得処理
 *  prc_get_mei_title_data       PROCEDURE : 明細タイトル取得処理
 *  prc_get_tonyu_utikomi_data   PROCEDURE : 明細（投入・打込）情報取得処理
 *  prc_get_busho_data           PROCEDURE : 部署情報取得処理
 *  prc_get_head_data            PROCEDURE : ヘッダー情報取得処理
 *  prc_get_head_data            PROCEDURE : パラメータチェック処理
 *  submain                      PROCEDURE : メイン処理プロシージャ
 *  main                         PROCEDURE : コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ------------------- -------------------------------------------------
 *  Date          Ver.  Editor              Description
 * ------------- ----- ------------------- -------------------------------------------------
 *  2007/12/13    1.0   Masakazu Yamashita  新規作成
 *  2008/05/20    1.1   Yusuke   Tabata     内部変更要求Seq95(日付型パラメータ型変換)対応
 *  2008/05/20    1.2   Daisuke  Nihei      結合テスト不具合対応（資材：依頼数が表示されない）
 *  2008/05/30    1.3   Daisuke  Nihei      結合テスト不具合対応（条件：予定区分不備)
 *  2008/06/04    1.4   Daisuke  Nihei      結合テスト不具合対応（生産指示書表示不正)
 *  2008/07/02    1.5   Satoshi  Yunba      禁則文字対応
 *  2008/07/18    1.6   Hitomi   Itou       結合テスト 指摘23対応 生産依頼書の時、保留中・手配済も対象とする
 *  2008/10/28    1.7   Daisuke  Nihei      統合障害#183対応 入力日時の結合先を作成日から更新日に変更する
 *                                          統合障害#196対応 一度引き当ててある品目のデフォルトロットを表示しない
 *                                          T_TE080_BPO_230 No15対応 生産指図書の時、手配済も対象とする
 *                                          統合障害#499対応 製造日、在庫入数の参照先変更
 *  2009/01/16    1.8   Daisuke  Nihei      本番障害#1032対応 生産指図書を「確定済」でも出力する
 *  2009/02/02    1.9   Daisuke  Nihei      本番障害#1111対応
 *  2009/02/04    1.10  Yasuhisa Yamamoto   本番障害#4対応 ランク３出力対応
 *  2014/10/27    1.11  Naoki    Miyamoto   本番障害#12524改善対応　生産指図書の明細に本数、端数を追加
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
  gv_pkg_name                   CONSTANT VARCHAR2(20) := 'XXWIP230001' ;                       -- パッケージ名
  gc_report_id                  CONSTANT VARCHAR2(12) := 'XXWIP230001T' ;                      -- 帳票ID
--
  -- 業務ステータス
-- 2008/07/18 H.Itou ADD START
  gv_status_horyu               CONSTANT VARCHAR2(10) := '1';                                  -- 保留中
  gv_status_tehai_zumi          CONSTANT VARCHAR2(10) := '3';                                  -- 手配済
  gv_status_kanryou             CONSTANT VARCHAR2(10) := '7';                                  -- 完了
  gv_status_close               CONSTANT VARCHAR2(10) := '8';                                  -- クローズ
  gv_status_cancel              CONSTANT VARCHAR2(10) := '-1';                                 -- 取消
-- 2008/07/18 H.Itou ADD END
  gv_status_irai_zumi           CONSTANT VARCHAR2(10) := '2';                                  -- 依頼済
  gv_status_kakunin_zumi        CONSTANT VARCHAR2(10) := '5';                                  -- 確認済
  gv_status_sasizu_zumi         CONSTANT VARCHAR2(10) := '4';                                  -- 指図済
  gv_status_uketuke_zumi        CONSTANT VARCHAR2(10) := '6';                                  -- 受付済
--
  -- 品目区分
  gv_hinmoku_kbn_genryou        CONSTANT VARCHAR2(10) := '1';                                  -- 原料
  gv_hinmoku_kbn_sizai          CONSTANT VARCHAR2(10) := '2';                                  -- 資材
  gv_hinmoku_kbn_hanseihin      CONSTANT VARCHAR2(10) := '4';                                  -- 半製品
  gv_hinmoku_kbn_seihin         CONSTANT VARCHAR2(10) := '5';                                  -- 製品
  gv_chohyo_title_irai          CONSTANT VARCHAR2(10) := '生産依頼書';                         -- 生産依頼書
  gv_chohyo_title_sasizu        CONSTANT VARCHAR2(10) := '生産指図書';                         -- 生産指図書
  gv_chohyo_kbn_irai            CONSTANT VARCHAR2(10) := '1';
  gv_chohyo_kbn_sasizu          CONSTANT VARCHAR2(10) := '2';
  gv_date_format1               CONSTANT VARCHAR2(50) := 'YYYY/MM/DD HH24:MI:SS';              -- 日付フォーマット
  gv_date_format2               CONSTANT VARCHAR2(50) := 'YYYY/MM/DD HH24:MI';                 -- 日付フォーマット
  gv_date_format3               CONSTANT VARCHAR2(50) := 'YYYY/MM/DD';                         -- 日付フォーマット
  gv_line_type_kbn_genryou      CONSTANT VARCHAR2(10) := '-1';
  gv_line_type_kbn_seizouhin    CONSTANT VARCHAR2(10) := '1';
-- 2014/10/27 v1.11 N.Miyamoto MOD START
--  gv_tonyu_title                CONSTANT VARCHAR2(50) := '投　入';
--  gv_utikomi_title              CONSTANT VARCHAR2(50) := '＜打　込＞';
  gv_tonyu_title                CONSTANT VARCHAR2(50) := '投入';
  gv_utikomi_title              CONSTANT VARCHAR2(50) := '＜打込＞';
-- 2014/10/27 v1.11 N.Miyamoto MOD END
  gv_sizai_title                CONSTANT VARCHAR2(50) := '＜投入資材＞';
  gv_utikomi_kbn_utikomi        CONSTANT VARCHAR2(1)  := 'Y';
  gv_seizouhin_kbn_drink        CONSTANT VARCHAR2(1)  := '3';
  gv_yotei_kbn_mov              CONSTANT VARCHAR2(1)  := '1';                                      -- 予定区分（移動）
  gv_yotei_kbn_tonyu            CONSTANT VARCHAR2(1)  := '4';                                      -- 予定区分（投入）
  gv_ontyu                      CONSTANT VARCHAR2(10) := '御中';
-- 2014/10/27 v1.11 N.Miyamoto ADD START
  gv_hasuu_ari                  CONSTANT VARCHAR2(2)  := '○';              --総数/入数に端数がある
  gv_hasuu_nashi                CONSTANT VARCHAR2(2)  := '　';              --総数/入数に端数がない
-- 2014/10/27 v1.11 N.Miyamoto ADD END
--
  gv_err_input_date_from        CONSTANT VARCHAR2(20) := '入力日時（FROM）';                       -- 入力日時（FROM）
  gv_err_input_date_to          CONSTANT VARCHAR2(20) := '入力日時（TO）';                         -- 入力日時（TO）
  gv_err_make_plan_from         CONSTANT VARCHAR2(20) := '生産予定日（FROM）';                     -- 生産予定日（FROM）
  gv_err_make_plan_to           CONSTANT VARCHAR2(20) := '生産予定日（TO）';                       -- 生産予定日（TO）
  gv_err_mei_title_no_data      CONSTANT VARCHAR2(100) := '投入口名称を取得できませんでした。';
  gc_application_cmn            CONSTANT VARCHAR2(5)  := 'XXCMN' ;                                 -- アプリケーション（XXCMN）
  gc_application_wip            CONSTANT VARCHAR2(5)  := 'XXWIP' ;                                 -- アプリケーション（XXWIP）
  gv_tkn_date                   CONSTANT VARCHAR2(100) := 'DATE';                                  -- トークン：DATE
  gv_tkn_param1                 CONSTANT VARCHAR2(100) := 'PARAM1';                                -- トークン：PARAM1
  gv_tkn_param2                 CONSTANT VARCHAR2(100) := 'PARAM2';                                -- トークン：PARAM2
  gv_tkn_item                   CONSTANT VARCHAR2(100) := 'ITEM';                                  -- トークン：ITEM
  gv_tkn_value                  CONSTANT VARCHAR2(100) := 'VALUE';                                 -- トークン：VALUE
-- 2008/10/28 v1.7 D.Nihei ADD START 統合障害#499
  gv_doc_type_prod              CONSTANT VARCHAR2(4)   := 'PROD';                                  -- PROD (生産)
-- 2008/10/28 v1.7 D.Nihei ADD END
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
--
  -- 入力パラメータ格納用レコード変数
  TYPE rec_param_data IS RECORD 
    (
      iv_den_kbn          gmd_routings_vl.attribute13%TYPE              -- 伝票区分
     ,iv_chohyo_kbn       VARCHAR2(1)                                   -- 帳票区分
     ,iv_plant            gme_batch_header.plant_code%TYPE              -- プラントコード
     ,iv_line_no          gmd_routings_vl.routing_no%TYPE               -- ラインNo
     ,id_make_plan_from   gme_batch_header.plan_start_date%TYPE         -- 生産予定日(FROM)
     ,id_make_plan_to     gme_batch_header.plan_start_date%TYPE         -- 生産予定日(TO)
     ,id_tehai_no_from    gme_batch_header.batch_no%TYPE                -- 手配No(FROM)
     ,id_tehai_no_to      gme_batch_header.batch_no%TYPE                -- 手配No(TO)
     ,iv_hinmoku_cd       xxcmn_item_mst2_v.item_no%TYPE                -- 品目コード
-- 2008/10/28 v1.7 D.Nihei MOD START
--     ,id_input_date_from  gme_batch_header.creation_date%TYPE           -- 入力日時(FROM)
--     ,id_input_date_to    gme_batch_header.creation_date%TYPE           -- 入力日時(TO)
     ,id_input_date_from  gme_batch_header.last_update_date%TYPE           -- 入力日時(FROM)
     ,id_input_date_to    gme_batch_header.last_update_date%TYPE           -- 入力日時(TO)
-- 2008/10/28 v1.7 D.Nihei MOD END
    ) ;
--
  -- ヘッダーデータ格納用レコード変数
  TYPE rec_head_data_type_dtl IS RECORD 
    (
      l_itaku_saki        sy_orgn_mst_vl.orgn_name%TYPE                 -- 委託先
     ,l_tehai_no          gme_batch_header.batch_no%TYPE                -- 手配no
     ,l_den_kbn           xxcmn_lookup_values_v.meaning%TYPE            -- 伝票区分
     ,l_kanri_bsho        xxcmn_lookup_values_v.meaning%TYPE            -- 成績管理部署
     ,l_item_cd           xxcmn_item_mst2_v.item_no%TYPE                -- 品目コード
     ,l_item_nm           xxcmn_item_mst2_v.item_short_name%TYPE        -- 品目名称
     ,l_line_no           gmd_routings_vl.routing_no%TYPE               -- ラインno
     ,l_line_nm           gmd_routings_vl.routing_desc%TYPE             -- ライン名称
     ,l_set_cd            gmd_routings_vl.attribute9%TYPE               -- 納品場所コード
     ,l_set_nm            xxcmn_item_locations_v.description%TYPE       -- 納品場所名称
     ,l_make_plan         gme_batch_header.plan_start_date%TYPE         -- 生産予定日
     ,l_stock_plan        gme_material_details.attribute22%TYPE         -- 原料入庫予定日
     ,l_type              xxcmn_lookup_values_v.meaning%TYPE            -- タイプ
     ,l_rank1             gme_material_details.attribute2%TYPE          -- ランク１
     ,l_rank2             gme_material_details.attribute3%TYPE          -- ランク２
-- 2009/02/04 v1.10 Y.Yamamoto #4 add start
     ,l_rank3             gme_material_details.attribute26%TYPE         -- ランク３
-- 2009/02/04 v1.10 Y.Yamamoto #4 add end
     ,l_description       gme_material_details.attribute4%TYPE          -- 摘要
     ,l_lot_no            ic_lots_mst.lot_no%TYPE                       -- ロットno
     ,l_move_place_cd     gme_material_details.attribute12%TYPE         -- 移動場所コード
     ,l_move_place_nm     xxcmn_item_locations_v.description%TYPE       -- 移動場所名称
     ,l_irai_total        gme_material_details.attribute7%TYPE          -- 依頼総数
     ,l_plan_qty          gme_material_details.plan_qty%TYPE            -- 計画数
-- 2009/02/02 v1.9 D.Nihei ADD START
     ,l_inst_qty          gme_material_details.attribute23%TYPE         -- 指図総数
-- 2009/02/02 v1.9 D.Nihei ADD END
     ,l_seizouhin_kbn     gmd_routings_vl.attribute16%TYPE              -- 製造品区分
     ,l_batch_id          gme_batch_header.batch_id%TYPE                -- バッチID
     ,l_last_updated_user gme_batch_header.last_updated_by%TYPE         -- 最終更新者
     ,l_item_id           xxcmn_item_mst2_v.item_id%TYPE                -- 品目ID
    ) ;
  TYPE tab_head_data_type_dtl IS TABLE OF rec_head_data_type_dtl INDEX BY BINARY_INTEGER ;
--
  -- 明細（投入・打込）データ格納用レコード変数
  TYPE rec_tonyu_utikmi_type_dtl IS RECORD 
    (
      l_item_cd               xxcmn_item_mst2_v.item_no%TYPE                -- 品目コード
     ,l_item_nm               xxcmn_item_mst2_v.item_short_name%TYPE        -- 品目名称
     ,l_lot_no                ic_lots_mst.lot_no%TYPE                       -- ロットno
     ,l_monve_no              xxwip_material_detail.plan_number%TYPE        -- 移動番号
     ,l_souko                 xxwip_material_detail.location_code%TYPE      -- 倉庫
-- 2008/10/28 v1.7 D.Nihei MOD START 統合障害#499
--     ,l_make_date             gme_material_details.attribute11%TYPE         -- 製造日
--     ,l_stock                 gme_material_details.attribute6%TYPE          -- 在庫入数
     ,l_make_date             ic_lots_mst.attribute1%TYPE                   -- 製造日
     ,l_stock                 ic_lots_mst.attribute6%TYPE                   -- 在庫入数
-- 2008/10/28 v1.7 D.Nihei MOD END
     ,l_total                 ic_tran_pnd.trans_qty%TYPE                    -- 総数
     ,l_unit                  ic_tran_pnd.trans_um%TYPE                     -- 単位
     ,l_material_detail_id    gme_material_details.material_detail_id%TYPE  -- 生産原料詳細ID
     ,l_shinkansen_kbn        gmd_routings_vl.attribute17%TYPE              -- 新缶煎区分
    ) ;
  TYPE tab_tonyu_utikomi_type_dtl IS TABLE OF rec_tonyu_utikmi_type_dtl INDEX BY BINARY_INTEGER ;
--
  -- 明細（資材）データ格納用レコード変数
  TYPE rec_sizai_data_type_dtl IS RECORD 
    (
      l_item_cd               xxcmn_item_mst2_v.item_no%TYPE                -- 品目コード
     ,l_item_nm               xxcmn_item_mst2_v.item_short_name%TYPE        -- 品目名称
-- 2008/10/28 v1.7 D.Nihei MOD START 統合障害#499
--     ,l_stock                 gme_material_details.attribute6%TYPE          -- 在庫入数
     ,l_stock                 ic_lots_mst.attribute6%TYPE                   -- 在庫入数
-- 2008/10/28 v1.7 D.Nihei MOD END
     ,l_total                 xxwip_material_detail.instructions_qty%TYPE   -- 総数
     ,l_unit                  xxcmn_item_mst2_v.item_um%TYPE                -- 単位
    ) ;
  TYPE tab_sizai_data_type_dtl IS TABLE OF rec_sizai_data_type_dtl INDEX BY BINARY_INTEGER ;
--
  -- 部署情報格納用レコード変数
  TYPE rec_busho_data  IS RECORD 
    (
      yubin_no   xxcmn_locations_all.zip%TYPE       -- 郵便番号
     ,address    xxcmn_locations_all.address_line1%TYPE     -- 住所
     ,tel        xxcmn_locations_all.phone%TYPE             -- 電話番号
     ,fax        xxcmn_locations_all.fax%TYPE               -- FAX番号
     ,busho_nm   xxcmn_locations_all.location_name%TYPE     -- 部署名称
    ) ;
--
  -- *** ローカル変数 ***
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
  /**********************************************************************************
   * Procedure Name   : prc_out_xml_data
   * Description      : ＸＭＬ出力処理
   ***********************************************************************************/
  PROCEDURE prc_out_xml_data
    (
      ov_errbuf     OUT VARCHAR2                  --    エラー・メッセージ           --# 固定 #
     ,ov_retcode    OUT VARCHAR2                  --    リターン・コード             --# 固定 #
     ,ov_errmsg     OUT VARCHAR2                  --    ユーザー・エラー・メッセージ --# 固定 #
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
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<lg_irai_info>' ) ;
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
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '</lg_irai_info>' ) ;
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
  /**********************************************************************************
   * Procedure Name   : prc_get_busho_data
   * Description      : 部署情報取得
   ***********************************************************************************/
  PROCEDURE prc_get_busho_data
    (
      iv_last_updated_user   IN  gme_batch_header.last_updated_by%TYPE           -- 最終更新者
     ,or_busho_data     OUT rec_busho_data
     ,ov_errbuf         OUT VARCHAR2          --    エラー・メッセージ           --# 固定 #
     ,ov_retcode        OUT VARCHAR2          --    リターン・コード             --# 固定 #
     ,ov_errmsg         OUT VARCHAR2          --    ユーザー・エラー・メッセージ  --# 固定 #
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
    -- *** ローカル・カーソル ***
    CURSOR cur_busho_data
      (
        iv_last_updated_user gme_batch_header.last_updated_by%TYPE
      )
    IS
      SELECT hla.location_code
      FROM fnd_user              fu
          ,per_all_assignments_f paaf
          ,hr_locations_all      hla
      WHERE fu.user_id           = iv_last_updated_user
      AND   fu.employee_id             = paaf.person_id
      AND   paaf.location_id           = hla.location_id
      AND   paaf.effective_start_date <= TRUNC(SYSDATE)
      AND   ((paaf.effective_end_date IS NULL) OR (paaf.effective_end_date   >= TRUNC(SYSDATE)))
      AND   fu.start_date             <= TRUNC(SYSDATE)
      AND   ((fu.end_date is NULL) OR (fu.end_date >= TRUNC(SYSDATE)))
      AND   hla.inactive_date           IS NULL
      AND   paaf.primary_flag = 'Y'
      
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
    -- データ抽出
    -- ====================================================
    -- カーソルオープン
    OPEN cur_busho_data
      (
        iv_last_updated_user
      ) ;
    -- フェッチ
    FETCH cur_busho_data INTO lv_busho_cd;
    -- カーソルクローズ
    CLOSE cur_busho_data ;
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
      IF cur_busho_data%ISOPEN THEN
        CLOSE cur_busho_data ;
      END IF ;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      IF cur_busho_data%ISOPEN THEN
        CLOSE cur_busho_data ;
      END IF ;
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      IF cur_busho_data%ISOPEN THEN
        CLOSE cur_busho_data ;
      END IF ;
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END prc_get_busho_data ;
--
  /**********************************************************************************
   * Procedure Name   : prc_get_mei_title_data
   * Description      : 投入明細タイトル取得
   ***********************************************************************************/
  PROCEDURE prc_get_mei_title_data
    (
      iv_material_detail_id IN VARCHAR2              -- 生産原料詳細ID
     ,ov_mei_title          OUT VARCHAR2             -- 明細タイトル
     ,ov_errbuf             OUT VARCHAR2             -- エラー・メッセージ           --# 固定 #
     ,ov_retcode            OUT VARCHAR2             -- リターン・コード             --# 固定 #
     ,ov_errmsg             OUT VARCHAR2             -- ユーザー・エラー・メッセージ  --# 固定 #
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
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル・定数 ***
--
    -- *** ローカル・カーソル ***
    CURSOR cur_mei_title_data
      (
        iv_material_detail_id gme_material_details.material_detail_id%TYPE
      )
    IS
      SELECT gov.oprn_desc
      FROM   gme_batch_steps           gbs,           -- 生産バッチステップ
             gmd_operations_vl         gov,           -- 工程マスタビュー
             gme_batch_step_items      gbsi           -- 生産バッチステップ品目
      WHERE  gbs.batchstep_id        = gbsi.batchstep_id
      AND    gov.oprn_id             = gbs.oprn_id
      AND    gbsi.material_detail_id = iv_material_detail_id
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
    -- データ抽出
    -- ====================================================
    -- カーソルオープン
    OPEN cur_mei_title_data
      (
        iv_material_detail_id
      ) ;
    -- フェッチ
    FETCH cur_mei_title_data INTO ov_mei_title ;
    -- カーソルクローズ
    CLOSE cur_mei_title_data ;
--
  EXCEPTION
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      IF cur_mei_title_data%ISOPEN THEN
        CLOSE cur_mei_title_data ;
      END IF ;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      IF cur_mei_title_data%ISOPEN THEN
        CLOSE cur_mei_title_data ;
      END IF ;
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      IF cur_mei_title_data%ISOPEN THEN
        CLOSE cur_mei_title_data ;
      END IF ;
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END prc_get_mei_title_data ;
--
  /**********************************************************************************
   * Procedure Name   : prc_create_xml_data
   * Description      : ＸＭＬデータ作成
   ***********************************************************************************/
  PROCEDURE prc_create_xml_data
    (
      ir_param          IN  rec_param_data    -- 01.レコード  ：パラメータ
     ,in_head_index     IN  NUMBER
     ,it_head_data      IN  tab_head_data_type_dtl
     ,it_tonyu_data     IN  tab_tonyu_utikomi_type_dtl
     ,it_utikomi_data   IN  tab_tonyu_utikomi_type_dtl
     ,it_sizai_data     IN  tab_sizai_data_type_dtl
     ,id_now_date       IN  DATE
     ,ov_errbuf         OUT VARCHAR2          --    エラー・メッセージ           --# 固定 #
     ,ov_retcode        OUT VARCHAR2          --    リターン・コード             --# 固定 #
     ,ov_errmsg         OUT VARCHAR2          --    ユーザー・エラー・メッセージ  --# 固定 #
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
    -- 帳票タイトル
    lv_chohyo_title           VARCHAR2(10) DEFAULT NULL;
    -- 明細タイトル
    lv_mei_title              VARCHAR2(20) DEFAULT NULL;
    -- 明細タイトルブレーク用
    lv_break_mei_title        VARCHAR2(20) DEFAULT '*';
    -- 部署情報
    lr_busho_data             rec_busho_data;
    -- ケース入数計算Function戻値
    ln_return_num             NUMBER DEFAULT 0;
    -- 委託先
    lv_itaku_saki             VARCHAR2(100) DEFAULT NULL;
    -- 指図総数
    ln_sasizu_total           NUMBER DEFAULT 0;
-- 2008/10/28 v1.7 D.Nihei ADD START
    lt_material_detail_id     gme_material_details.material_detail_id%TYPE;  -- 退避用生産原料詳細ID
-- 2008/10/28 v1.7 D.Nihei ADD END
-- 2014/10/27 v1.11 N.Miyamoto ADD START
    ln_honsu_wk               NUMBER DEFAULT 0;
-- 2014/10/27 v1.11 N.Miyamoto ADD END
--
    -- *** ローカル・例外処理 ***
    no_data_expt            EXCEPTION ;           -- 取得レコードなし
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
    gt_xml_data_table(gl_xml_idx).tag_name  := 'g_irai' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
    -- -----------------------------------------------------
    -- 依頼先Ｇデータタグ出力
    -- -----------------------------------------------------
    -- =====================================================
    -- 部署情報取得処理
    -- =====================================================
    prc_get_busho_data
      (
        iv_last_updated_user  =>   it_head_data(in_head_index).l_last_updated_user
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
    -- 帳票タイトル
    IF (ir_param.iv_chohyo_kbn = gv_chohyo_kbn_irai) THEN
      lv_chohyo_title := gv_chohyo_title_irai;
--
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'irai_sasizu_flg' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := gv_chohyo_kbn_irai;
--
    ELSE
      lv_chohyo_title := gv_chohyo_title_sasizu;
--
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'irai_sasizu_flg' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := gv_chohyo_kbn_sasizu;
--
    END IF;
--
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'head_title';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := lv_chohyo_title;
    -- 帳票ID
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'chohyo_id';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := gc_report_id ;
    -- 発行日
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'exec_time';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := TO_CHAR(id_now_date, gv_date_format2);
    -- 委託先
    IF (it_head_data(in_head_index).l_itaku_saki IS NOT NULL) THEN
      lv_itaku_saki := it_head_data(in_head_index).l_itaku_saki || gv_ontyu;
    ELSE
      lv_itaku_saki := NULL;
    END IF;
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'itaku_saki';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := lv_itaku_saki;
    -- 住所
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'dep_address';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := lr_busho_data.address;
    -- 手配No
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'tehai_no';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := it_head_data(in_head_index).l_tehai_no;
    -- TEL
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'dep_tel';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := lr_busho_data.tel;
    -- FAX
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'dep_fax';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := lr_busho_data.fax;
    -- 伝票区分
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'den_kbn';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := it_head_data(in_head_index).l_den_kbn;
    -- 担当部署
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'dep_nm';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := lr_busho_data.busho_nm;
    -- 成績管理部署
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'knri_bsho';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := it_head_data(in_head_index).l_kanri_bsho;
    -- 品目コード
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'hinmk_cd';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := it_head_data(in_head_index).l_item_cd;
    -- 品目名称
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'hinmk_nm';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := it_head_data(in_head_index).l_item_nm;
    -- ラインNo
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'line_no';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := it_head_data(in_head_index).l_line_no;
    -- ライン名称
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'line_nm';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := it_head_data(in_head_index).l_line_nm;
    -- 納品場所コード
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'set_cd';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := it_head_data(in_head_index).l_set_cd;
    -- 納品場所名称
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'set_nm';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := it_head_data(in_head_index).l_set_nm;
    -- 生産予定日
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'make_plan';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := TO_CHAR(it_head_data(in_head_index).l_make_plan, gv_date_format3);
    -- 原料入庫予定日
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'stock_plan';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := it_head_data(in_head_index).l_stock_plan;
    -- ロットNo
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'lot_no';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := it_head_data(in_head_index).l_lot_no;
    -- 移動場所コード
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'move_cd';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := it_head_data(in_head_index).l_move_place_cd;
    -- 移動場所名称
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'move_nm';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := it_head_data(in_head_index).l_move_place_nm;
    -- 指図総数
    IF (ir_param.iv_chohyo_kbn = gv_chohyo_kbn_irai) THEN
      ln_sasizu_total := it_head_data(in_head_index).l_irai_total;
    ELSE
-- 2009/02/02 v1.9 D.Nihei MOD START
--      ln_sasizu_total := it_head_data(in_head_index).l_plan_qty;
      ln_sasizu_total := it_head_data(in_head_index).l_inst_qty;
-- 2009/02/02 v1.9 D.Nihei MOD END
    END IF;
--
    IF (it_head_data(in_head_index).l_seizouhin_kbn = gv_seizouhin_kbn_drink) THEN
      ln_return_num := xxcmn_common_pkg.rcv_ship_conv_qty('2'
                                                          ,it_head_data(in_head_index).l_item_id
                                                          ,ln_sasizu_total);
    ELSE
      ln_return_num := ln_sasizu_total;
    END IF;
--
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'sashizu_total';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := ln_return_num;
    -- タイプ
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'item_type';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := it_head_data(in_head_index).l_type;
    -- ランク１
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'item_rank1';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := it_head_data(in_head_index).l_rank1;
    -- ランク２
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'item_rank2';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := it_head_data(in_head_index).l_rank2;
-- 2009/02/04 v1.10 Y.Yamamoto #4 add start
    -- ランク３
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'item_rank3';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := it_head_data(in_head_index).l_rank3;
-- 2009/02/04 v1.10 Y.Yamamoto #4 add end
    -- 摘要
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'item_tekiyo';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := it_head_data(in_head_index).l_description;
--
    -- -----------------------------------------------------
    -- 明細Ｇ開始タグ出力
    -- -----------------------------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_meisai_info';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
-- 2008/10/28 v1.7 D.Nihei ADD START
    lt_material_detail_id := -1;
-- 2008/10/28 v1.7 D.Nihei ADD END
    <<tonyu_data_loop>>
    FOR i IN 1..it_tonyu_data.COUNT LOOP
--
      -- 明細情報１件目の出力の場合
      IF (i = 1) THEN
        -- -----------------------------------------------------
        -- 明細（投入）Ｇ開始タグ出力
        -- -----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_mei_tonyu';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
      END IF;
-- 2008/10/28 v1.7 D.Nihei ADD START
      IF ( ( lt_material_detail_id <> it_tonyu_data(i).l_material_detail_id ) OR ( it_tonyu_data(i).l_lot_no IS NOT NULL ) ) THEN
-- 2008/10/28 v1.7 D.Nihei ADD END
        -- -----------------------------------------------------
        -- 投入Ｇデータタグ出力
        -- -----------------------------------------------------
        -- 行開始タグ
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'g_mei_tonyu';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
        -- =====================================================
        -- 明細（投入）タイトル取得処理
        -- =====================================================
        -- 新缶煎ラインの場合
        IF (it_tonyu_data(i).l_shinkansen_kbn = 'Y') THEN
          prc_get_mei_title_data
            (
              iv_material_detail_id  =>   it_tonyu_data(i).l_material_detail_id
             ,ov_mei_title           =>   lv_mei_title
             ,ov_errbuf              =>   lv_errbuf          -- エラー・メッセージ           --# 固定 #
             ,ov_retcode             =>   lv_retcode         -- リターン・コード             --# 固定 #
             ,ov_errmsg              =>   lv_errmsg          -- ユーザー・エラー・メッセージ  --# 固定 #
            );
--
          IF (lv_retcode = gv_status_error) THEN
            RAISE global_process_expt ;
          END IF ;
--
          IF (lv_mei_title IS NULL) THEN
            RAISE no_data_expt ;
          END IF;
--
          lv_mei_title := lv_mei_title || '投入';
        ELSE
          lv_mei_title := gv_tonyu_title;
        END IF;
--
        IF (lv_break_mei_title <> lv_mei_title) THEN
          -- 明細タイトル
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'tonyu_title';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
          gt_xml_data_table(gl_xml_idx).tag_value := '＜' || lv_mei_title || '＞';
--
          lv_break_mei_title := lv_mei_title;
--
        END IF;
--
        -- 品目コード
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'tonyu_hinmk_cd';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := it_tonyu_data(i).l_item_cd ;
        -- 品目名称
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'tonyu_hinmk_nm';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := it_tonyu_data(i).l_item_nm ;
        -- ロットNo
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'tonyu_lot_no';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := it_tonyu_data(i).l_lot_no ;
        -- 移動番号
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'tonyu_move_no';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := it_tonyu_data(i).l_monve_no ;
        -- 倉庫
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'tonyu_souko';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := it_tonyu_data(i).l_souko ;
        -- 製造日
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'tonyu_make_day';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := it_tonyu_data(i).l_make_date ;
        -- 在庫入数
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'tonyu_stock';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := it_tonyu_data(i).l_stock ;
-- 2014/10/27 v1.11 N.Miyamoto ADD START
        -- 端数
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'tonyu_frac';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        --在庫入数が0ではない、かつ総数÷在庫入数の余りが0
        IF ( NVL(it_tonyu_data(i).l_stock, 0) <> 0 ) THEN
          IF ( MOD(it_tonyu_data(i).l_total, TO_NUMBER(it_tonyu_data(i).l_stock)) <> 0 ) THEN
             gt_xml_data_table(gl_xml_idx).tag_value := gv_hasuu_ari ;
          ELSE
           gt_xml_data_table(gl_xml_idx).tag_value := gv_hasuu_nashi ;
          END IF;
        ELSE
         gt_xml_data_table(gl_xml_idx).tag_value := gv_hasuu_nashi ;
        END IF;
        -- 本数
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'tonyu_qty';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        IF ( NVL(it_tonyu_data(i).l_stock, 0) <> 0 ) THEN         --在庫入数が0またはNULLでない場合のみ計算を行う
          ln_honsu_wk := TRUNC(it_tonyu_data(i).l_total / TO_NUMBER(it_tonyu_data(i).l_stock), 3);  --総数÷在庫入数
        ELSE
          ln_honsu_wk := 0;                                       --在庫入数が0またはNULLの場合は本数0で出力
        END IF;
        gt_xml_data_table(gl_xml_idx).tag_value := TO_CHAR(ln_honsu_wk) ;
-- 2014/10/27 v1.11 N.Miyamoto ADD END
        -- 総数
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'tonyu_total';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
-- 2009/02/02 v1.9 D.Nihei MOD START
--        gt_xml_data_table(gl_xml_idx).tag_value := it_tonyu_data(i).l_total * -1;
        gt_xml_data_table(gl_xml_idx).tag_value := it_tonyu_data(i).l_total;
-- 2009/02/02 v1.9 D.Nihei MOD END
        -- 単位
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'tonyu_unit';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := it_tonyu_data(i).l_unit ;
        -- 行終了タグ
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := '/g_mei_tonyu';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
-- 2008/10/28 v1.7 D.Nihei ADD START
      END IF;
      lt_material_detail_id := it_tonyu_data(i).l_material_detail_id;
-- 2008/10/28 v1.7 D.Nihei ADD END
      -- 明細情報を出力した場合
      IF (i = it_tonyu_data.COUNT) THEN
        -- -----------------------------------------------------
        -- 明細（投入）Ｇ終了タグ出力
        -- -----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_mei_tonyu';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
      END IF;
--
    END LOOP tonyu_data_loop ;
--
-- 2008/10/28 v1.7 D.Nihei ADD START
    lt_material_detail_id := -1;
-- 2008/10/28 v1.7 D.Nihei ADD END
    <<utikomi_data_loop>>
    FOR i IN 1..it_utikomi_data.COUNT LOOP
--
      IF (i = 1) THEN
        -- -----------------------------------------------------
        -- 明細（打込）Ｇ開始タグ出力
        -- -----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_mei_utikomi';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
      END IF;
-- 2008/10/28 v1.7 D.Nihei ADD START
      IF ( ( lt_material_detail_id <> it_utikomi_data(i).l_material_detail_id ) OR ( it_utikomi_data(i).l_lot_no IS NOT NULL ) ) THEN
-- 2008/10/28 v1.7 D.Nihei ADD END
        -- -----------------------------------------------------
        -- 打込Ｇデータタグ出力
        -- -----------------------------------------------------
        -- 行開始タグ
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'g_mei_utikomi';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
        -- 明細タイトル
        IF (i = 1) THEN
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'utikomi_title';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
          gt_xml_data_table(gl_xml_idx).tag_value := gv_utikomi_title ;
        END IF;
        -- 品目コード
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'utikomi_hinmk_cd';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := it_utikomi_data(i).l_item_cd;
        -- 品目名称
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'utikomi_hinmk_nm';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := it_utikomi_data(i).l_item_nm;
        -- ロットNo
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'utikomi_lot_no';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := it_utikomi_data(i).l_lot_no;
        -- 移動番号
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'utikomi_move_no';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := it_utikomi_data(i).l_monve_no;
        -- 倉庫
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'utikomi_souko';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := it_utikomi_data(i).l_souko;
        -- 製造日
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'utikomi_make_day';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := it_utikomi_data(i).l_make_date;
        -- 在庫入数
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'utikomi_stock';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := it_utikomi_data(i).l_stock;
-- 2014/10/27 v1.11 N.Miyamoto ADD START
        -- 端数
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'utikomi_frac';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        --在庫入数が0ではない、かつ総数÷在庫入数の余りが0
        IF ( NVL(it_utikomi_data(i).l_stock, 0) <> 0 ) THEN
          IF ( MOD(it_utikomi_data(i).l_total, TO_NUMBER(it_utikomi_data(i).l_stock)) <> 0 ) THEN
             gt_xml_data_table(gl_xml_idx).tag_value := gv_hasuu_ari ;
          ELSE
           gt_xml_data_table(gl_xml_idx).tag_value := gv_hasuu_nashi ;
          END IF;
        ELSE
         gt_xml_data_table(gl_xml_idx).tag_value := gv_hasuu_nashi ;
        END IF;
        -- 本数
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'utikomi_qty';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        IF ( NVL(it_utikomi_data(i).l_stock, 0) <> 0 ) THEN         --在庫入数が0またはNULLでない場合のみ計算を行う
          ln_honsu_wk := TRUNC(it_utikomi_data(i).l_total / TO_NUMBER(it_utikomi_data(i).l_stock), 3);
        ELSE
          ln_honsu_wk := 0;                                         --在庫入数が0またはNULLの場合は本数0で出力
        END IF;
        gt_xml_data_table(gl_xml_idx).tag_value := TO_CHAR(ln_honsu_wk) ;
-- 2014/10/27 v1.11 N.Miyamoto ADD END
        -- 総数
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'utikomi_total';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
-- 2009/02/02 v1.9 D.Nihei MOD START
--        gt_xml_data_table(gl_xml_idx).tag_value := it_utikomi_data(i).l_total * -1;
        gt_xml_data_table(gl_xml_idx).tag_value := it_utikomi_data(i).l_total;
-- 2009/02/02 v1.9 D.Nihei MOD END
        -- 単位
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'utikomi_unit';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := it_utikomi_data(i).l_unit;
        -- 行終了タグ
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := '/g_mei_utikomi';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
-- 2008/10/28 v1.7 D.Nihei ADD START
      END IF;
      lt_material_detail_id := it_utikomi_data(i).l_material_detail_id;
-- 2008/10/28 v1.7 D.Nihei ADD END
      IF (i = it_utikomi_data.COUNT) THEN
        -- -----------------------------------------------------
        -- 明細（投入）Ｇ終了タグ出力
        -- -----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_mei_utikomi';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
      END IF;
--
    END LOOP utikomi_data_loop ;
--
    <<sizai_data_loop>>
    FOR i IN 1..it_sizai_data.COUNT LOOP
--
      IF (i = 1) THEN
        -- -----------------------------------------------------
        -- 明細（資材）Ｇ開始タグ出力
        -- -----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_mei_sizai';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
      END IF;
      -- -----------------------------------------------------
      -- 資材Ｇデータタグ出力
      -- -----------------------------------------------------
      -- 行開始タグ
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'g_mei_sizai';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
      -- 明細タイトル
      IF (i = 1) THEN
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'sizai_title';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := gv_sizai_title;
      END IF;
      -- 品目コード
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'sizai_hinmk_cd';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := it_sizai_data(i).l_item_cd;
      -- 品目名称
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'sizai_hinmk_nm';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := it_sizai_data(i).l_item_nm;
-- 2014/10/27 v1.11 N.Miyamoto ADD START
        -- 端数
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'sizai_frac';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        --在庫入数が0ではない、かつ総数÷在庫入数の余りが0
        IF ( NVL(it_sizai_data(i).l_stock, 0) <> 0 ) THEN
          IF ( MOD(it_sizai_data(i).l_total, TO_NUMBER(it_sizai_data(i).l_stock)) <> 0 ) THEN
             gt_xml_data_table(gl_xml_idx).tag_value := gv_hasuu_ari ;
          ELSE
           gt_xml_data_table(gl_xml_idx).tag_value := gv_hasuu_nashi ;
          END IF;
        ELSE
         gt_xml_data_table(gl_xml_idx).tag_value := gv_hasuu_nashi ;
        END IF;
        -- 本数
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'sizai_qty';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        IF ( NVL(it_sizai_data(i).l_stock, 0) <> 0 ) THEN         --在庫入数が0またはNULLでない場合のみ計算を行う
          ln_honsu_wk := TRUNC(it_sizai_data(i).l_total / TO_NUMBER(it_sizai_data(i).l_stock), 3);
        ELSE
          ln_honsu_wk := 0;                                       --在庫入数が0またはNULLの場合は本数0で出力
        END IF;
        gt_xml_data_table(gl_xml_idx).tag_value := TO_CHAR(ln_honsu_wk) ;
-- 2014/10/27 v1.11 N.Miyamoto ADD END
      -- 総数
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'sizai_total';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := it_sizai_data(i).l_total;
      -- 単位
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'sizai_unit';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := it_sizai_data(i).l_unit;
      -- 行終了タグ
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := '/g_mei_sizai';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
      IF (i = it_sizai_data.COUNT) THEN
        -- -----------------------------------------------------
        -- 明細（投入）Ｇ終了タグ出力
        -- -----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_mei_sizai';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
      END IF;
--
    END LOOP sizai_data_loop ;
--
    -- =====================================================
    -- 依頼情報出力終了処理
    -- =====================================================
    ------------------------------
    -- 明細ＬＧ終了タグ
    ------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_meisai_info' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
    ------------------------------
    -- 依頼先Ｇ終了タグ
    ------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/g_irai' ;
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
    -- *** 明細タイトル取得データ０件 ***
    WHEN no_data_expt THEN
      ov_errmsg  := gv_err_mei_title_no_data ;
      ov_errbuf  := gv_err_mei_title_no_data ;
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
  /**********************************************************************************
   * Procedure Name   : prc_create_zeroken_xml_data
   * Description      : 取得件数０件時ＸＭＬデータ作成
   ***********************************************************************************/
  PROCEDURE prc_create_zeroken_xml_data
    (
      ir_param          IN  rec_param_data    -- レコード  ：パラメータ
     ,ov_errbuf         OUT VARCHAR2          -- エラー・メッセージ           --# 固定 #
     ,ov_retcode        OUT VARCHAR2          -- リターン・コード             --# 固定 #
     ,ov_errmsg         OUT VARCHAR2          -- ユーザー・エラー・メッセージ  --# 固定 #
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
    gt_xml_data_table(gl_xml_idx).tag_name  := 'g_irai' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
    -- 帳票タイトル
    IF (ir_param.iv_chohyo_kbn = gv_chohyo_kbn_irai) THEN
      lv_chohyo_title := gv_chohyo_title_irai;
    ELSE
      lv_chohyo_title := gv_chohyo_title_sasizu;
    END IF;
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'head_title';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := lv_chohyo_title;
--
    -- -----------------------------------------------------
    -- 明細Ｇ開始タグ出力
    -- -----------------------------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_meisai_info';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
    ------------------------------
    -- 明細ＬＧ終了タグ
    ------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_meisai_info' ;
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
    gt_xml_data_table(gl_xml_idx).tag_name  := '/g_irai' ;
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
  /**********************************************************************************
   * Procedure Name   : prc_get_sizai_data
   * Description      : 資材情報取得
   ***********************************************************************************/
  PROCEDURE prc_get_sizai_data
    (
      iv_batch_id      IN  VARCHAR2                        -- バッチID
     ,ot_data_rec      OUT NOCOPY tab_sizai_data_type_dtl  -- 取得レコード群
     ,ov_errbuf        OUT VARCHAR2                        -- エラー・メッセージ           --# 固定 #
     ,ov_retcode       OUT VARCHAR2                        -- リターン・コード             --# 固定 #
     ,ov_errmsg        OUT VARCHAR2                        -- ユーザー・エラー・メッセージ --# 固定 #
    )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_get_sizai_data'; -- プログラム名
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
--
    -- *** ローカル・カーソル ***
    CURSOR cur_sizai_data
      (
        iv_batch_id            gme_batch_header.batch_id%TYPE
      )
    IS
      SELECT ximv.item_no             AS item_no            -- 品目コード
            ,ximv.item_short_name     AS item_desc1         -- 品目名称
-- 2008/10/28 v1.7 D.Nihei MOD START 統合障害#499
--            ,gmd.attribute6           AS attribute6         -- 在庫入数
-- 2014/10/27 v1.11 N.Miyamoto MOD START
--            ,ilm.attribute6           AS attribute6         -- 在庫入数
            ,NVL(ilm.attribute6, ximv.num_of_cases)
                                      AS num_of_cases       -- 在庫入数
-- 2014/10/27 v1.11 N.Miyamoto MOD END
-- 2008/10/28 v1.7 D.Nihei MOD END
-- 2008/05/23 D.Nihei MOD START
--            ,xmd.instructions_qty     AS trans_qty          -- 総数
            ,NVL(xmd.instructions_qty, gmd.attribute7) 
                                      AS trans_qty          -- 総数
-- 2008/05/23 D.Nihei MOD END
            ,ximv.item_um             AS trans_um           -- 単位
      FROM gme_batch_header           gbh                   -- 生産バッチヘッダ
          ,gme_material_details       gmd                   -- 生産原料詳細
          ,xxwip_material_detail      xmd                   -- 生産原料詳細アドオン
          ,ic_lots_mst                ilm                   -- OPMロットマスタ
          ,xxcmn_item_mst2_v          ximv                  -- OPM品目マスタビュー
          ,gmd_routings_vl            grv                   -- 工順マスタビュー
          ,xxcmn_item_categories3_v   xicv                  -- 品目カテゴリービュー
      WHERE gbh.batch_id              = gmd.batch_id
      AND   gmd.material_detail_id    = xmd.material_detail_id(+)
-- 2008/05/30 D.Nihei INS START
      AND   xmd.item_id               = ilm.item_id(+)
-- 2008/05/30 D.Nihei INS START
      AND   xmd.lot_id                = ilm.lot_id(+)
      AND   xmd.plan_type(+)          = gv_yotei_kbn_tonyu
      AND   gmd.item_id               = ximv.item_id
      AND   TRUNC(gbh.plan_start_date)    BETWEEN   TRUNC(ximv.start_date_active)
                                          AND       TRUNC(ximv.end_date_active)
      AND   gbh.routing_id            = grv.routing_id
      AND   gmd.item_id               = xicv.item_id
      --------------------------------------------------------------------------------------
      -- 絞込み条件
      AND gmd.line_type               = gv_line_type_kbn_genryou
      AND gmd.attribute5              IS NULL
      AND xicv.item_class_code        = gv_hinmoku_kbn_sizai
      AND gbh.batch_id                = iv_batch_id
      ORDER BY TO_NUMBER(ximv.item_no)
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
    -- データ抽出
    -- ====================================================
    -- カーソルオープン
    OPEN cur_sizai_data
      (
        iv_batch_id                    -- バッチID
      ) ;
    -- バルクフェッチ
    FETCH cur_sizai_data BULK COLLECT INTO ot_data_rec ;
    -- カーソルクローズ
    CLOSE cur_sizai_data ;
--
  EXCEPTION
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      IF cur_sizai_data%ISOPEN THEN
        CLOSE cur_sizai_data ;
      END IF ;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      IF cur_sizai_data%ISOPEN THEN
        CLOSE cur_sizai_data ;
      END IF ;
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      IF cur_sizai_data%ISOPEN THEN
        CLOSE cur_sizai_data ;
      END IF ;
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END prc_get_sizai_data ;
--
  /**********************************************************************************
   * Procedure Name   : prc_get_tonyu_utikomi_data
   * Description      : 投入情報取得
   ***********************************************************************************/
  PROCEDURE prc_get_tonyu_utikomi_data
    (
      iv_utikomi_kbn         IN  VARCHAR2                             -- 打込区分
     ,iv_batch_id            IN  VARCHAR2                             -- バッチID
     ,ot_data_rec            OUT NOCOPY tab_tonyu_utikomi_type_dtl    -- 取得レコード
     ,ov_errbuf              OUT VARCHAR2                             -- エラー・メッセージ           --# 固定 #
     ,ov_retcode             OUT VARCHAR2                             -- リターン・コード             --# 固定 #
     ,ov_errmsg              OUT VARCHAR2                             -- ユーザー・エラー・メッセージ --# 固定 #
    )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_get_tonyu_utikomi_data'; -- プログラム名
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
--
    -- *** ローカル・カーソル ***
    CURSOR cur_tonyu_utikomi_data
      (
        iv_utikomi_kbn           VARCHAR
       ,iv_batch_id              gme_batch_header.batch_id%TYPE
      )
    IS
      SELECT ximv.item_no             AS item_no            -- 品目コード
            ,ximv.item_short_name     AS item_desc1         -- 品目名称
            ,DECODE(ilm.lot_id, 0, NULL,ilm.lot_no)
                                      AS lot_no             -- ロットno
-- 2008/05/30 D.Nihei MOD START
--            ,xmd.plan_number          AS plan_number        -- 移動番号
            ,DECODE(xmd.plan_type, gv_yotei_kbn_mov, xmd.plan_number, NULL)
                                      AS plan_number        -- 移動番号
-- 2008/05/30 D.Nihei MOD END
            ,xmd.location_code        AS location_code      -- 出庫元倉庫
-- 2008/10/28 v1.7 D.Nihei MOD START 統合障害#499
--            ,gmd.attribute11          AS attribute11        -- 製造日
--            ,gmd.attribute6           AS attribute6         -- 在庫入数
            ,ilm.attribute1           AS attribute1         -- 製造日
-- 2014/10/27 v1.11 N.Miyamoto MOD START
--            ,ilm.attribute6           AS attribute6         -- 在庫入数
            ,NVL(ilm.attribute6, ximv.num_of_cases)
                                      AS num_of_cases       -- 在庫入数
-- 2014/10/27 v1.11 N.Miyamoto MOD END
-- 2008/10/28 v1.7 D.Nihei MOD END
-- 2009/02/02 v1.9 D.Nihei MOD START 
--            ,itp.trans_qty            AS trans_qty          -- 総数
            ,NVL(xmd.instructions_qty, gmd.attribute7) 
                                      AS trans_qty          -- 総数
-- 2009/02/02 v1.9 D.Nihei MOD END
            ,itp.trans_um             AS trans_um           -- 単位
            ,gmd.material_detail_id   AS material_detail_id -- 生産原料詳細ID
            ,grv.attribute17          AS shinkansen_kbn     -- 新缶煎区分
      FROM gme_batch_header           gbh                   -- 生産バッチヘッダ
          ,gme_material_details       gmd                   -- 生産原料詳細
          ,xxwip_material_detail      xmd                   -- 生産原料詳細アドオン
          ,ic_tran_pnd                itp                   -- 保留在庫トランザクション
          ,ic_lots_mst                ilm                   -- OPMロットマスタ
          ,xxcmn_item_mst2_v          ximv                  -- OPM品目マスタビュー
          ,gmd_routings_vl            grv                   -- 工順マスタビュー
          ,xxcmn_item_categories3_v   xicv                  -- 品目カテゴリービュー
      WHERE gbh.batch_id              = gmd.batch_id
-- 2008/06/04 D.Nihei MOD START
--      AND   gmd.material_detail_id    = xmd.material_detail_id(+)
      AND   itp.line_id               = xmd.material_detail_id(+)
      AND   itp.item_id               = xmd.item_id(+)
      AND   itp.lot_id                = xmd.lot_id(+)
-- 2008/06/04 D.Nihei MOD END
-- 2008/05/30 D.Nihei MOD START
--      AND   xmd.plan_type(+)          = gv_yotei_kbn_tonyu
      AND   xmd.plan_type(+)         <> gv_yotei_kbn_tonyu
-- 2008/05/30 D.Nihei MOD END
      AND   gmd.material_detail_id    = itp.line_id
      AND   itp.lot_id                = ilm.lot_id
      AND   itp.item_id               = ilm.item_id
      AND   gmd.item_id               = ximv.item_id
      AND   TRUNC(gbh.plan_start_date)     BETWEEN   TRUNC(ximv.start_date_active)
                                           AND       TRUNC(ximv.end_date_active)
      AND   gbh.routing_id            = grv.routing_id
      AND   gmd.item_id               = xicv.item_id
      --------------------------------------------------------------------------------------
      -- 絞込み条件
      AND gmd.line_type     = gv_line_type_kbn_genryou
      AND (
            (iv_utikomi_kbn IS NOT NULL AND gmd.attribute5    = iv_utikomi_kbn)
          OR
            (iv_utikomi_kbn IS NULL AND gmd.attribute5 IS NULL)
          )
      AND xicv.item_class_code IN (gv_hinmoku_kbn_genryou
                                  ,gv_hinmoku_kbn_hanseihin
                                  ,gv_hinmoku_kbn_seihin)
      AND itp.reverse_id          IS NULL
      AND ABS(itp.trans_qty)      > 0
      AND itp.delete_mark         = 0
      AND gbh.batch_id            = iv_batch_id
-- 2008/10/28 v1.7 D.Nihei ADD START 統合障害#499
      AND itp.doc_type            = gv_doc_type_prod
-- 2008/10/28 v1.7 D.Nihei ADD END
      ORDER BY  DECODE (iv_utikomi_kbn,
                        NULL, gmd.attribute8)
               ,xicv.item_class_code
               ,TO_NUMBER(ximv.item_no)
               ,TO_NUMBER(lot_no)
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
    -- データ抽出
    -- ====================================================
    -- カーソルオープン
    OPEN cur_tonyu_utikomi_data
      (
        iv_utikomi_kbn                 -- 打込区分
       ,iv_batch_id                    -- バッチID
      ) ;
    -- バルクフェッチ
    FETCH cur_tonyu_utikomi_data BULK COLLECT INTO ot_data_rec ;
    -- カーソルクローズ
    CLOSE cur_tonyu_utikomi_data ;
--
  EXCEPTION
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      IF cur_tonyu_utikomi_data%ISOPEN THEN
        CLOSE cur_tonyu_utikomi_data ;
      END IF ;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      IF cur_tonyu_utikomi_data%ISOPEN THEN
        CLOSE cur_tonyu_utikomi_data ;
      END IF ;
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      IF cur_tonyu_utikomi_data%ISOPEN THEN
        CLOSE cur_tonyu_utikomi_data ;
      END IF ;
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END prc_get_tonyu_utikomi_data ;
--
  /**********************************************************************************
   * Procedure Name   : prc_get_head_data
   * Description      : ヘッダー情報取得
   ***********************************************************************************/
  PROCEDURE prc_get_head_data
    (
      ir_param      IN  rec_param_data                     -- 入力パラメータ
     ,ot_data_rec   OUT NOCOPY tab_head_data_type_dtl      -- 取得レコード
     ,ov_errbuf     OUT VARCHAR2                           -- エラー・メッセージ           --# 固定 #
     ,ov_retcode    OUT VARCHAR2                           -- リターン・コード             --# 固定 #
     ,ov_errmsg     OUT VARCHAR2                           -- ユーザー・エラー・メッセージ   --# 固定 #
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
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル・定数 ***
--
    -- *** ローカル・カーソル ***
    CURSOR cur_head_data
      (
        iv_den_kbn              gmd_routings_vl.attribute13%TYPE
       ,iv_chohyo_kbn           VARCHAR
       ,iv_plant                gme_batch_header.plant_code%TYPE
       ,iv_line_no              gmd_routings_vl.routing_no%TYPE
       ,id_make_plan_from       gme_batch_header.plan_start_date%TYPE
       ,id_make_plan_to         gme_batch_header.plan_start_date%TYPE
       ,id_tehai_no_from        gme_batch_header.batch_no%TYPE
       ,id_tehai_no_to          gme_batch_header.batch_no%TYPE
       ,iv_hinmoku_cd           ic_item_mst_vl.item_no%TYPE
-- 2008/10/28 v1.7 D.Nihei MOD START
--       ,id_input_date_from      gmd_routings_vl.creation_date%TYPE
--       ,id_input_date_to        gmd_routings_vl.creation_date%TYPE
       ,id_input_date_from      gmd_routings_vl.last_update_date%TYPE
       ,id_input_date_to        gmd_routings_vl.last_update_date%TYPE
-- 2008/10/28 v1.7 D.Nihei MOD END
      )
    IS
      SELECT somv.orgn_name           AS l_itaku_saki             -- 委託先
            ,gbh.batch_no             AS l_tehai_no               -- 手配no
            ,xlvv1.meaning            AS l_den_kbn                -- 伝票区分
            ,xlvv2.meaning            AS l_kanri_bsho             -- 成績管理部署
            ,ximv.item_no             AS l_item_cd                -- 品目コード
            ,ximv.item_short_name     AS l_item_nm                -- 品目名称
            ,grv.routing_no           AS l_line_no                -- ラインno
            ,grv.routing_desc         AS l_line_nm                -- ライン名称
            ,grv.attribute9           AS l_set_cd                 -- 納品場所コード
            ,xilv1.description        AS l_set_nm                 -- 納品場所名称
            ,gbh.plan_start_date      AS l_make_plan              -- 生産予定日
            ,gmd.attribute22          AS l_stock_plan             -- 原料入庫予定日
            ,xlvv3.meaning            AS l_type                   -- タイプ
            ,gmd.attribute2           AS l_rank1                  -- ランク１
            ,gmd.attribute3           AS l_rank2                  -- ランク２
-- 2009/02/04 v1.10 Y.Yamamoto #4 add start
            ,gmd.attribute26          AS l_rank3                  -- ランク３
-- 2009/02/04 v1.10 Y.Yamamoto #4 add end
            ,gmd.attribute4           AS l_description            -- 摘要
            ,ilm.lot_no               AS l_lot_no                 -- ロットno
            ,gmd.attribute12          AS l_move_place_cd          -- 移動場所コード
            ,xilv2.description        AS l_move_place_nm          -- 移動場所名称
            ,gmd.attribute7           AS l_irai_total             -- 依頼総数
            ,gmd.plan_qty             AS l_plan_qty               -- 計画数
-- 2009/02/02 v1.9 D.Nihei ADD START
            ,gmd.attribute23          AS l_inst_qty               -- 指図総数
-- 2009/02/02 v1.9 D.Nihei ADD END
            ,grv.attribute16          AS l_seizouhin_kbn          -- 製造品区分
            ,gbh.batch_id             AS l_batch_id               -- バッチID
            ,gbh.last_updated_by      AS l_last_updated_user      -- 最終更新者
            ,ximv.item_id             AS l_hinmoku_id             -- 品目ID
      FROM gme_batch_header           gbh                         -- 生産バッチヘッダ
          ,gme_material_details       gmd                         -- 生産原料詳細
          ,ic_tran_pnd                itp                         -- 保留在庫トランザクション
          ,ic_lots_mst                ilm                         -- OPMロットマスタ
          ,xxcmn_item_mst2_v          ximv                        -- OPM品目マスタビュー
          ,sy_orgn_mst_vl             somv                        -- OPMプラントマスタビュー
          ,xxcmn_item_locations_v     xilv1                       -- OPM保管場所マスタ
          ,xxcmn_item_locations_v     xilv2                       -- OPM保管場所マスタ
          ,gmd_routings_vl            grv                         -- 工順マスタビュー
          ,xxcmn_lookup_values_v      xlvv1                       -- クイックコード（伝票区分）
          ,xxcmn_lookup_values_v      xlvv2                       -- クイックコード（成績管理部署）
          ,xxcmn_lookup_values_v      xlvv3                       -- クイックコード（タイプ）
      WHERE gbh.batch_id              = gmd.batch_id
      AND   gmd.material_detail_id    = itp.line_id(+)
      AND   itp.lot_id                = ilm.lot_id(+)
      AND   gmd.item_id               = ximv.item_id
      AND   TRUNC(gbh.plan_start_date)  BETWEEN   TRUNC(ximv.start_date_active)
                                        AND       TRUNC(ximv.end_date_active)
      AND    grv.attribute3           = somv.orgn_code(+)
      AND    grv.attribute9           = xilv1.segment1(+)
      AND    gmd.attribute12          = xilv2.segment1(+)
      AND    gbh.routing_id           = grv.routing_id
      AND    xlvv1.lookup_type(+)     = 'XXCMN_L03'
      AND    xlvv1.lookup_code(+)     = grv.attribute13
      AND    xlvv2.lookup_type(+)     = 'XXCMN_L10'
      AND    xlvv2.lookup_code(+)     = grv.attribute14
      AND    xlvv3.lookup_type(+)     = 'XXCMN_L08'
      AND    xlvv3.lookup_code(+)     = gmd.attribute1
      --------------------------------------------------------------------------------------
      -- 絞込み条件
      AND grv.attribute13             = NVL(iv_den_kbn, grv.attribute13)
      AND gbh.plant_code              = iv_plant
      AND grv.routing_no              = NVL(iv_line_no, grv.routing_no)
-- 2008/10/28 v1.7 D.Nihei MOD START
--      AND TRUNC(gbh.creation_date, 'MI') BETWEEN TRUNC(id_input_date_from, 'MI')
      AND TRUNC(gbh.last_update_date, 'MI') BETWEEN TRUNC(id_input_date_from, 'MI')
-- 2008/10/28 v1.7 D.Nihei MOD END
                                            AND     TRUNC(id_input_date_to, 'MI')
      AND gbh.batch_no                >= NVL(id_tehai_no_from, gbh.batch_no)
      AND gbh.batch_no                <= NVL(id_tehai_no_to, gbh.batch_no)
      AND TRUNC(gbh.plan_start_date)  >= NVL(id_make_plan_from, TRUNC(gbh.plan_start_date))
      AND TRUNC(gbh.plan_start_date)  <= NVL(id_make_plan_to, TRUNC(gbh.plan_start_date))
      AND ximv.item_no                = NVL(iv_hinmoku_cd, ximv.item_no)
      AND (
            (    iv_chohyo_kbn        = gv_chohyo_kbn_irai
             AND gbh.attribute4         IN( gv_status_irai_zumi     -- 依頼済
-- 2008/07/18 H.Itou ADD START  帳票区分が依頼書の場合、保留中・手配済も対象とする。
                                           ,gv_status_horyu         -- 保留中
                                           ,gv_status_tehai_zumi    -- 手配済
-- 2008/07/18 H.Itou ADD END
                                           ,gv_status_kakunin_zumi  -- 確認済
                                           ,gv_status_uketuke_zumi )-- 受付済
            )
           OR
            (    iv_chohyo_kbn        = gv_chohyo_kbn_sasizu
             AND gbh.attribute4         IN( gv_status_sasizu_zumi
-- 2008/10/28 v1.7 D.Nihei ADD START
                                           ,gv_status_tehai_zumi    -- 手配済
-- 2008/10/28 v1.7 D.Nihei ADD END
-- 2009/01/16 v1.8 D.Nihei ADD START
                                           ,gv_status_kakunin_zumi  -- 確認済
-- 2009/01/16 v1.8 D.Nihei ADD END
                                           ,gv_status_uketuke_zumi )
            )
          )
      AND gmd.line_type               = gv_line_type_kbn_seizouhin
      AND itp.reverse_id(+)           IS NULL
      AND itp.lot_id(+)               > 0
      AND itp.delete_mark(+)          = 0
-- 2008/10/28 v1.7 D.Nihei ADD START
      AND itp.doc_type(+)             = gv_doc_type_prod
-- 2008/10/28 v1.7 D.Nihei ADD END
      ORDER BY gbh.batch_no
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
    -- データ抽出
    -- ====================================================
    -- カーソルオープン
    OPEN cur_head_data
      (
        ir_param.iv_den_kbn            -- 伝票区分
       ,ir_param.iv_chohyo_kbn         -- 帳票区分
       ,ir_param.iv_plant              -- プラント
       ,ir_param.iv_line_no            -- ラインNo
       ,ir_param.id_make_plan_from     -- 生産予定日(FROM)
       ,ir_param.id_make_plan_to       -- 生産予定日(TO)
       ,ir_param.id_tehai_no_from      -- 手配No(FROM)
       ,ir_param.id_tehai_no_to        -- 手配No(TO)
       ,ir_param.iv_hinmoku_cd         -- 品目コード
       ,ir_param.id_input_date_from    -- 入力日時(FROM)
       ,ir_param.id_input_date_to      -- 入力日時(TO)
      ) ;
    -- バルクフェッチ
    FETCH cur_head_data BULK COLLECT INTO ot_data_rec ;
    -- カーソルクローズ
    CLOSE cur_head_data ;
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
      IF cur_head_data%ISOPEN THEN
        CLOSE cur_head_data ;
      END IF ;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      IF cur_head_data%ISOPEN THEN
        CLOSE cur_head_data ;
      END IF ;
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      IF cur_head_data%ISOPEN THEN
        CLOSE cur_head_data ;
      END IF ;
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END prc_get_head_data ;
--
  /**********************************************************************************
   * Procedure Name   : prc_check_param_data
   * Description      : パラメータチェック処理
   ***********************************************************************************/
  PROCEDURE prc_check_param_data
    (
      iv_make_plan_from      IN  VARCHAR2                     -- 生産予定日(FROM)
     ,iv_make_plan_to        IN  VARCHAR2                     -- 生産予定日(TO)
     ,iv_input_date_from     IN  VARCHAR2                     -- 入力日時(FROM)
     ,iv_input_date_to       IN  VARCHAR2                     -- 入力日時(TO)
     ,id_now_date            IN  DATE                         -- 現在日付
     ,od_make_plan_from      OUT DATE                         -- 生産予定日(FROM)
     ,od_make_plan_to        OUT DATE                         -- 生産予定日(TO)
     ,od_input_date_from     OUT DATE                         -- 入力日時(FROM)
     ,od_input_date_to       OUT DATE                         -- 入力日時(TO)
     ,ov_errbuf              OUT VARCHAR2                     -- エラー・メッセージ           --# 固定 #
     ,ov_retcode             OUT VARCHAR2                     -- リターン・コード             --# 固定 #
     ,ov_errmsg              OUT VARCHAR2                     -- ユーザー・エラー・メッセージ   --# 固定 #
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
    -- 共通関数戻り値：数値型
    ln_ret_num              NUMBER ;
--
    -- *** ローカル・例外処理 ***
    parameter_check_expt      EXCEPTION ;     -- パラメータチェック例外
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
    -- 日付チェック
    -- ====================================================
    IF (iv_make_plan_from IS NOT NULL) THEN
      ln_ret_num := xxcmn_common_pkg.check_param_date_yyyymmdd(iv_make_plan_from) ;
      IF ( ln_ret_num = 1 ) THEN
        lv_errmsg := xxcmn_common_pkg.get_msg( gc_application_cmn
                                              ,'APP-XXCMN-10012'
                                              ,gv_tkn_item
                                              ,gv_err_make_plan_from
                                              ,gv_tkn_value
                                              ,iv_make_plan_from) ;
        RAISE parameter_check_expt ;
      ELSE
-- 変更 START 2008/05/20 YTabata
/**
        od_make_plan_from := FND_DATE.STRING_TO_DATE(iv_make_plan_from
                                                    ,gv_date_format1);
**/
-- 変更 END 2008/05/20 YTabata
        od_make_plan_from := FND_DATE.CANONICAL_TO_DATE(iv_make_plan_from) ;
      END IF ;
    END IF;
--
    IF (iv_make_plan_to IS NOT NULL) THEN
      ln_ret_num := xxcmn_common_pkg.check_param_date_yyyymmdd(iv_make_plan_to) ;
      IF ( ln_ret_num = 1 ) THEN
        lv_errmsg := xxcmn_common_pkg.get_msg( gc_application_cmn
                                            ,'APP-XXCMN-10012'
                                            ,gv_tkn_item
                                            ,gv_err_make_plan_to
                                            ,gv_tkn_value
                                            ,iv_make_plan_to) ;
        RAISE parameter_check_expt ;
      ELSE
-- 変更 START 2008/05/20 YTabata
/**
        od_make_plan_to := FND_DATE.STRING_TO_DATE(iv_make_plan_to
                                                  ,gv_date_format1);
**/
-- 変更 END 2008/05/20 YTabata
        od_make_plan_to := FND_DATE.CANONICAL_TO_DATE(iv_make_plan_to) ;
      END IF ;
    END IF;
--
    ln_ret_num := xxcmn_common_pkg.check_param_date_yyyymmdd(iv_input_date_from) ;
    IF ( ln_ret_num = 1 ) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg( gc_application_cmn
                                            ,'APP-XXCMN-10012'
                                            ,gv_tkn_item
                                            ,gv_err_input_date_from
                                            ,gv_tkn_value
                                            ,iv_input_date_from) ;
      RAISE parameter_check_expt ;
    ELSE
-- 変更 START 2008/05/20 YTabata
/**
        od_make_plan_to := FND_DATE.STRING_TO_DATE(iv_input_date_from
                                                  ,gv_date_format1);
**/
-- 変更 END 2008/05/20 YTabata
      od_input_date_from := FND_DATE.CANONICAL_TO_DATE(iv_input_date_from);
    END IF ;
--
    ln_ret_num := xxcmn_common_pkg.check_param_date_yyyymmdd(iv_input_date_to) ;
    IF ( ln_ret_num = 1 ) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg( gc_application_cmn
                                            ,'APP-XXCMN-10012'
                                            ,gv_tkn_item
                                            ,gv_err_input_date_to
                                            ,gv_tkn_value
                                            ,iv_input_date_to) ;
      RAISE parameter_check_expt ;
    ELSE
-- 変更 START 2008/05/20 YTabata
/**
        od_make_plan_to := FND_DATE.STRING_TO_DATE(iv_input_date_to
                                                  ,gv_date_format1);
**/
-- 変更 END 2008/05/20 YTabata
      od_input_date_to := FND_DATE.CANONICAL_TO_DATE(iv_input_date_to);
    END IF ;
--
    -- ====================================================
    -- 未来日チェック
    -- ====================================================
    IF (TRUNC(od_input_date_from, 'DD') > TRUNC(id_now_date, 'DD')) THEN
      -- メッセージセット
      lv_errmsg := xxcmn_common_pkg.get_msg( gc_application_wip
                                            ,'APP-XXWIP-10001'
                                            ,gv_tkn_date
                                            ,gv_err_input_date_from
                                            ,gv_tkn_value
                                            ,TO_CHAR(od_input_date_from, gv_date_format2)) ;
      RAISE parameter_check_expt ;
    END IF;
--    
    IF (TRUNC(od_input_date_to, 'DD') > TRUNC(id_now_date, 'DD')) THEN
      -- メッセージセット
      lv_errmsg := xxcmn_common_pkg.get_msg( gc_application_wip
                                            ,'APP-XXWIP-10001'
                                            ,gv_tkn_date
                                            ,gv_err_input_date_to
                                            ,gv_tkn_value
                                            ,TO_CHAR(od_input_date_to, gv_date_format2)) ;
      RAISE parameter_check_expt ;
    END IF;
--
    -- ====================================================
    -- 妥当性チェック
    -- ====================================================
    IF (od_input_date_from > od_input_date_to) THEN
      -- メッセージセット
      lv_errmsg := xxcmn_common_pkg.get_msg( gc_application_wip
                                            ,'APP-XXWIP-10016'
                                            ,gv_tkn_param1
                                            ,gv_err_input_date_from
                                            ,gv_tkn_param2
                                            ,gv_err_input_date_to) ;
      RAISE parameter_check_expt ;
    END IF;
--
    IF (od_make_plan_from > od_make_plan_to) THEN
      -- メッセージセット
      lv_errmsg := xxcmn_common_pkg.get_msg( gc_application_wip
                                            ,'APP-XXWIP-10016'
                                            ,gv_tkn_param1
                                            ,gv_err_make_plan_from
                                            ,gv_tkn_param2
                                            ,gv_err_make_plan_to) ;
      RAISE parameter_check_expt ;
    END IF;
--
  EXCEPTION
    --*** パラメータチェック例外 ***
    WHEN parameter_check_expt THEN
--
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
  END prc_check_param_data ;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain
    (
      iv_den_kbn            IN     VARCHAR2         -- 01 : 伝票区分
     ,iv_chohyo_kbn         IN     VARCHAR2         -- 02 : 帳票区分
     ,iv_plant              IN     VARCHAR2         -- 03 : プラント
     ,iv_line_no            IN     VARCHAR2         -- 04 : ラインNo
     ,iv_make_plan_from     IN     VARCHAR2         -- 05 : 生産予定日(FROM)
     ,iv_make_plan_to       IN     VARCHAR2         -- 06 : 生産予定日(TO)
     ,iv_tehai_no_from      IN     VARCHAR2         -- 07 : 手配No(FROM)
     ,iv_tehai_no_to        IN     VARCHAR2         -- 08 : 手配No(TO)
     ,iv_hinmoku_cd         IN     VARCHAR2         -- 09 : 品目コード
     ,iv_input_date_from    IN     VARCHAR2         -- 10 : 入力日時(FROM)
     ,iv_input_date_to      IN     VARCHAR2         -- 11 : 入力日時(TO)
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
    lr_param_rec            rec_param_data ;               -- パラメータ受渡し用
    lt_head_data            tab_head_data_type_dtl ;       -- 取得レコード表（ヘッダー情報）
    lt_tonyu_data           tab_tonyu_utikomi_type_dtl ;   -- 取得レコード表（投入情報）
    lt_utikomi_data         tab_tonyu_utikomi_type_dtl ;   -- 取得レコード表（打込情報）
    lt_sizai_data           tab_sizai_data_type_dtl ;      -- 取得レコード表（資材情報）
    lr_busho_data           rec_busho_data;                -- 取得レコード表（部署情報）
    ld_make_plan_from       DATE DEFAULT NULL;
    ld_make_plan_to         DATE DEFAULT NULL;
    ld_input_date_from      DATE DEFAULT NULL;
    ld_input_date_to        DATE DEFAULT NULL;
--
    -- システム日付
    ld_now_date             DATE DEFAULT SYSDATE;
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
    prc_check_param_data
      (
        iv_make_plan_from       =>   iv_make_plan_from     -- 生産予定日(FROM)
       ,iv_make_plan_to         =>   iv_make_plan_to       -- 生産予定日(TO)
       ,iv_input_date_from      =>   iv_input_date_from    -- 入力日時(TROM)
       ,iv_input_date_to        =>   iv_input_date_to      -- 入力日時(TO)
       ,id_now_date             =>   ld_now_date           -- 現在日付
       ,od_make_plan_from       =>   ld_make_plan_from     -- 生産予定日(FROM)
       ,od_make_plan_to         =>   ld_make_plan_to       -- 生産予定日(TO)
       ,od_input_date_from      =>   ld_input_date_from    -- 入力日時(TROM)
       ,od_input_date_to        =>   ld_input_date_to      -- 入力日時(TO)
       ,ov_errbuf               =>   lv_errbuf             -- エラー・メッセージ           --# 固定 #
       ,ov_retcode              =>   lv_retcode            -- リターン・コード             --# 固定 #
       ,ov_errmsg               =>   lv_errmsg             -- ユーザー・エラー・メッセージ --# 固定 #
      ) ;
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt ;
    END IF ;
--
    -- =====================================================
    -- パラメータ格納処理
    -- =====================================================
    lr_param_rec.iv_den_kbn          := iv_den_kbn;                                  -- 01 : 伝票区分
    lr_param_rec.iv_chohyo_kbn       := iv_chohyo_kbn;                               -- 02 : 帳票区分
    lr_param_rec.iv_plant            := iv_plant;                                    -- 03 : プラント
    lr_param_rec.iv_line_no          := iv_line_no;                                  -- 04 : ラインNo
    lr_param_rec.id_make_plan_from   := ld_make_plan_from;                           -- 05 : 生産予定日(FROM)
    lr_param_rec.id_make_plan_to     := ld_make_plan_to;                             -- 06 : 生産予定日(TO)
    lr_param_rec.id_tehai_no_from    := iv_tehai_no_from;                            -- 07 : 手配No(FROM)
    lr_param_rec.id_tehai_no_to      := iv_tehai_no_to;                              -- 08 : 手配No(TO)
    lr_param_rec.iv_hinmoku_cd       := iv_hinmoku_cd;                               -- 09 : 品目コード
    lr_param_rec.id_input_date_from  := ld_input_date_from;                          -- 10 : 入力日時(FROM)
    lr_param_rec.id_input_date_to    := ld_input_date_to;                            -- 11 : 入力日時(TO)
--
    -- =====================================================
    -- ヘッダー情報取得処理
    -- =====================================================
    prc_get_head_data
      (
        ir_param          =>   lr_param_rec       -- 入力パラメータレコード
       ,ot_data_rec       =>   lt_head_data       -- 取得レコード群
       ,ov_errbuf         =>   lv_errbuf          -- エラー・メッセージ           --# 固定 #
       ,ov_retcode        =>   lv_retcode         -- リターン・コード             --# 固定 #
       ,ov_errmsg         =>   lv_errmsg          -- ユーザー・エラー・メッセージ --# 固定 #
      );
--
    IF ( lv_retcode = gv_status_error ) THEN
      RAISE global_process_expt ;
    END IF ;
--
    <<head_data_loop>>
    FOR i IN 1..lt_head_data.COUNT LOOP
      -- =====================================================
      -- 明細（投入）情報取得処理
      -- =====================================================
      prc_get_tonyu_utikomi_data
        (
          iv_utikomi_kbn         =>   NULL                         -- 打込区分
         ,iv_batch_id            =>   lt_head_data(i).l_batch_id   -- バッチID
         ,ot_data_rec            =>   lt_tonyu_data                -- 取得レコード群
         ,ov_errbuf              =>   lv_errbuf                    -- エラー・メッセージ           --# 固定 #
         ,ov_retcode             =>   lv_retcode                   -- リターン・コード             --# 固定 #
         ,ov_errmsg              =>   lv_errmsg                    -- ユーザー・エラー・メッセージ  --# 固定 #
        );
--
      IF ( lv_retcode = gv_status_error ) THEN
        RAISE global_process_expt ;
      END IF ;
--
      -- =====================================================
      -- 明細（打込）情報取得処理
      -- =====================================================
      prc_get_tonyu_utikomi_data
        (
          iv_utikomi_kbn         =>   gv_utikomi_kbn_utikomi       -- 打込区分
         ,iv_batch_id            =>   lt_head_data(i).l_batch_id   -- バッチID
         ,ot_data_rec            =>   lt_utikomi_data              -- 02.取得レコード群
         ,ov_errbuf              =>   lv_errbuf                    -- エラー・メッセージ           --# 固定 #
         ,ov_retcode             =>   lv_retcode                   -- リターン・コード             --# 固定 #
         ,ov_errmsg              =>   lv_errmsg                    -- ユーザー・エラー・メッセージ  --# 固定 #
        );
--
      IF ( lv_retcode = gv_status_error ) THEN
        RAISE global_process_expt ;
      END IF ;
--
      -- =====================================================
      -- 明細（投入資材）情報取得処理
      -- =====================================================
      prc_get_sizai_data
        (
          iv_batch_id       =>   lt_head_data(i).l_batch_id   -- バッチID
         ,ot_data_rec       =>   lt_sizai_data                -- 取得レコード群
         ,ov_errbuf         =>   lv_errbuf                    -- エラー・メッセージ          --# 固定 #
         ,ov_retcode        =>   lv_retcode                   -- リターン・コード            --# 固定 #
         ,ov_errmsg         =>   lv_errmsg                    -- ユーザー・エラー・メッセージ --# 固定 #
        );
--
      IF ( lv_retcode = gv_status_error ) THEN
        RAISE global_process_expt ;
      END IF ;
--
      -- =====================================================
      -- XMLデータ作成処理
      -- =====================================================
      prc_create_xml_data
        (
          ir_param          =>   lr_param_rec       -- 入力パラメータレコード
         ,in_head_index     =>   i                  -- ヘッダー情報index
         ,it_head_data      =>   lt_head_data       -- ヘッダー情報
         ,it_tonyu_data     =>   lt_tonyu_data      -- 投入情報
         ,it_utikomi_data   =>   lt_utikomi_data    -- 打込情報
         ,it_sizai_data     =>   lt_sizai_data      -- 資材情報
         ,id_now_date       =>   ld_now_date        -- 現在日付
         ,ov_errbuf         =>   lv_errbuf          -- エラー・メッセージ           --# 固定 #
         ,ov_retcode        =>   lv_retcode         -- リターン・コード             --# 固定 #
         ,ov_errmsg         =>   lv_errmsg          -- ユーザー・エラー・メッセージ  --# 固定 #
        );
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt ;
      END IF ;
--
      -- =====================================================
      -- 初期化処理
      -- =====================================================
      lt_tonyu_data.delete;
      lt_utikomi_data.delete;
      lt_sizai_data.delete;
--
    END LOOP head_data_loop ;
--
    IF (lt_head_data.COUNT = 0) THEN
--
      -- =====================================================
      -- 取得データ０件時XMLデータ作成処理
      -- =====================================================
      prc_create_zeroken_xml_data
        (
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
    prc_out_xml_data
      (
        ov_errbuf         =>   lv_errbuf          -- エラー・メッセージ           --# 固定 #
       ,ov_retcode        =>   lv_retcode         -- リターン・コード             --# 固定 #
       ,ov_errmsg         =>   lv_errmsg          -- ユーザー・エラー・メッセージ  --# 固定 #
      );
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt ;
    END IF ;
--
    IF (lv_retcode = gv_status_normal AND lt_head_data.COUNT = 0) THEN
      lv_retcode := gv_status_warn;
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
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : コンカレント実行ファイル登録プロシージャ
   **********************************************************************************/
  PROCEDURE main
    (
      errbuf                OUT    VARCHAR2         -- エラーメッセージ
     ,retcode               OUT    VARCHAR2         -- エラーコード
     ,iv_den_kbn            IN     VARCHAR2         -- 01 : 伝票区分
     ,iv_chohyo_kbn         IN     VARCHAR2         -- 02 : 帳票区分
     ,iv_plant              IN     VARCHAR2         -- 03 : プラント
     ,iv_line_no            IN     VARCHAR2         -- 04 : ラインNo
     ,iv_make_plan_from     IN     VARCHAR2         -- 05 : 生産予定日(FROM)
     ,iv_make_plan_to       IN     VARCHAR2         -- 06 : 生産予定日(TO)
     ,iv_tehai_no_from      IN     VARCHAR2         -- 07 : 手配No(FROM)
     ,iv_tehai_no_to        IN     VARCHAR2         -- 08 : 手配No(TO)
     ,iv_hinmoku_cd         IN     VARCHAR2         -- 09 : 品目コード
     ,iv_input_date_from    IN     VARCHAR2         -- 10 : 入力日時(FROM)
     ,iv_input_date_to      IN     VARCHAR2         -- 11 : 入力日時(TO)
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
    submain
      (
        iv_den_kbn            => iv_den_kbn           -- 01 : 伝票区分
       ,iv_chohyo_kbn         => iv_chohyo_kbn        -- 02 : 帳票区分
       ,iv_plant              => iv_plant             -- 03 : プラント
       ,iv_line_no            => iv_line_no           -- 04 : ラインNo
       ,iv_make_plan_from     => iv_make_plan_from    -- 05 : 生産予定日(FROM)
       ,iv_make_plan_to       => iv_make_plan_to      -- 06 : 生産予定日(TO)
       ,iv_tehai_no_from      => iv_tehai_no_from     -- 07 : 手配No(FROM)
       ,iv_tehai_no_to        => iv_tehai_no_to       -- 08 : 手配No(TO)
       ,iv_hinmoku_cd         => iv_hinmoku_cd        -- 09 : 品目コード
       ,iv_input_date_from    => iv_input_date_from   -- 10 : 入力日時(FROM)
       ,iv_input_date_to      => iv_input_date_to     -- 11 : 入力日時(TO)
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
END xxwip230001c ;
/
