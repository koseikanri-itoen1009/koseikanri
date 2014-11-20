CREATE OR REPLACE PACKAGE BODY XXINV550002C
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : XXINV550002C(body)
 * Description      : 受払台帳作成
 * MD.050/070       : 在庫(帳票)Draft2A (T_MD050_BPO_550)
 *                    受払台帳Draft1A   (T_MD070_BPO_55B)
 * Version          : 1.18
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  convert_into_xml       XMLデータ変換
 *  check_parameter        パラメータチェック
 *  insert_xml_plsql_table XMLデータ格納
 *  create_xml             XMLデータ作成
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/02/07    1.0   Kazuo Kumamoto   新規作成
 *  2008/05/07    1.1   Kazuo Kumamoto   内部変更要求#33対応
 *  2008/05/15    1.2   Kazuo Kumamoto   内部変更要求#93対応
 *  2008/05/15    1.3   Kazuo Kumamoto   SQLチューニング
 *  2008/06/04    1.4   Takao Ohashi     結合テスト不具合修正
 *  2008/06/05    1.5   Kazuo Kumamoto   結合テスト障害対応(出荷数を絶対値に変更)
 *  2008/06/05    1.6   Kazuo Kumamoto   SQLチューニング
 *  2008/06/05    1.7   Kazuo Kumamoto   結合テスト障害対応(出荷の相手先取得方法を変更)
 *  2008/06/05    1.8   Kazuo Kumamoto   結合テスト障害対応(出荷の受払区分アドオンマスタ抽出条件変更)
 *  2008/06/09    1.9   Kazuo Kumamoto   結合テスト障害対応(生産の日付条件変更)
 *  2008/06/09    1.10  Kazuo Kumamoto   結合テスト障害対応(出荷の受払区分アドオンマスタ抽出条件追加)
 *  2008/06/23    1.11  Kazuo Kumamoto   結合テスト障害対応(単位の出力内容変更)
 *  2008/07/01    1.12  Kazuo Kumamoto   結合テスト障害対応(パラメータ.品目・商品区分・品目区分組み合わせチェック)
 *  2008/07/01    1.13  Kazuo Kumamoto   結合テスト障害対応(パラメータ.物流ブロック・倉庫/保管倉庫をOR条件とする)
 *  2008/07/02    1.14  Satoshi Yunba    禁則文字対応
 *  2008/07/07    1.15 Yasuhisa Yamamoto 結合テスト障害対応(発注実績の取得数量を発注明細から取得するように変更)
 *  2008/09/16    1.16  Hitomi Itou      T_TE080_BPO_550 指摘31(積送ありの場合も同一倉庫内移動の場合、抽出しない。)
 *                                       T_TE080_BPO_550 指摘28(在庫調整実績情報の受入返品情報取得(相手先在庫)を追加)
 *                                       T_TE080_BPO_540 指摘44(同上)
 *                                       変更要求#171(同上)
 *  2008/09/22    1.17  Hitomi Itou      T_TE080_BPO_550 指摘28(在庫調整実績情報の外注出来高情報・受入返品情報取得(相手先在庫)の相手先を取引先に変更)
 *  2008/10/20    1.18  Takao Ohashi     T_S_492(出力されない処理区分と事由コートの組み合わせを出力させる)
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
  -- ユーザー定義グローバル定数
  -- ===============================
  -------------------------------------------------------
  --プログラム名
  -------------------------------------------------------
  gv_pkg_name          CONSTANT VARCHAR2(100) := 'XXINV550002C'; -- パッケージ名
  gv_report_id         CONSTANT VARCHAR2(12)  := 'XXINV550002T' ; -- プログラム名帳票出力用
--
  -------------------------------------------------------
  --エラーメッセージ関連
  -------------------------------------------------------
  gc_application_inv   CONSTANT VARCHAR2(5)  := 'XXINV'; -- アプリケーション（XXINV）
  gc_application_cmn   CONSTANT VARCHAR2(5)  := 'XXCMN'; -- アプリケーション（XXCMN）
  gv_xxinv_10096       CONSTANT VARCHAR2(15) := 'APP-XXINV-10096'; --日付大小比較エラー
  gv_xxinv_10111       CONSTANT VARCHAR2(15) := 'APP-XXINV-10111'; --品目チェックエラー
  gv_xxinv_10112       CONSTANT VARCHAR2(15) := 'APP-XXINV-10112'; --倉庫チェックエラー
  gv_xxinv_10153       CONSTANT VARCHAR2(15) := 'APP-XXINV-10153'; --保管倉庫チェックエラー
  gv_xxinv_10113       CONSTANT VARCHAR2(15) := 'APP-XXINV-10113'; --ブロックチェックエラー
  gc_xxcmn_10122       CONSTANT VARCHAR2(15) := 'APP-XXCMN-10122'; -- 明細0件用メッセージ
--
  -------------------------------------------------------
  --通常定数
  -------------------------------------------------------
  --領域名
  gv_trtry_po          CONSTANT VARCHAR2(4) := '発注'; --発注実績情報
  gv_trtry_mv          CONSTANT VARCHAR2(4) := '移動'; --移動実績情報
  gv_trtry_sh          CONSTANT VARCHAR2(4) := '出荷'; --出荷/有償出荷実績情報
  gv_trtry_rt          CONSTANT VARCHAR2(8) := '倉替返品'; --倉替返品実績情報
  gv_trtry_mf          CONSTANT VARCHAR2(4) := '生産'; --生産実績情報
  gv_trtry_ad          CONSTANT VARCHAR2(8) := '在庫調整'; --在庫調整実績情報
--
  --倉庫保管倉庫選択区分
  gv_wh_loc_ctl_wh     CONSTANT VARCHAR2(1) := '1';--倉庫保管倉庫選択区分(倉庫)
  gv_wh_loc_ctl_loc    CONSTANT VARCHAR2(1) := '2';--倉庫保管倉庫選択区分(保管倉庫)
--
  --言語
  gv_lang              CONSTANT VARCHAR2(2) := 'JA'; --language
  gv_source_lang       CONSTANT VARCHAR2(2) := 'JA'; --source_lang
--
  --XML出力モード
  gv_output_normal     CONSTANT VARCHAR2(1) := '0'; --XML出力(通常)
  gv_output_notfound   CONSTANT VARCHAR2(1) := '1'; --XML出力(０件)
--
  --書式
  gv_fmt_ymd           CONSTANT VARCHAR2(10) := 'YYYY/MM/DD'; --年月日の書式
  gv_fmt_ymd_out       CONSTANT VARCHAR2(20) := 'YYYY"年"MM"月"DD"日"'; --帳票出力時の年月日書式(年月日FROM,TO)
  gv_fmt_ymd_out2      CONSTANT VARCHAR2(21) := 'YYYY/MM/DD HH24:MI:SS'; --帳票出力時の年月日書式(出力日付)
--
  --発注ヘッダステータス
  gv_po_sts_rcv        CONSTANT VARCHAR2(2) := '25'; --受入あり
  gv_po_sts_qty_deci   CONSTANT VARCHAR2(2) := '30'; --数量確定済み
  gv_po_sts_price_deci CONSTANT VARCHAR2(2) := '35'; --金額確定済み
--
  --発注明細数量確定フラグ
  gv_po_flg_qty        CONSTANT VARCHAR2(2) := 'Y'; --数量確定済み
--
  --実績区分
  gv_txns_type_rcv     CONSTANT VARCHAR2(1) := '1'; --受入
--
  --プロファイル
  gv_prf_mst_org       CONSTANT VARCHAR2(19) := 'XXCMN_MASTER_ORG_ID'; --組織ID
  gv_prf_prod_div      CONSTANT VARCHAR2(14) := 'XXCMN_ITEM_DIV'; --商品区分
  gv_prf_item_div      CONSTANT VARCHAR2(17) := 'XXCMN_ARTICLE_DIV'; --品目区分
--
  --OPM保留在庫トランザクション完了フラグ
  gv_tran_cmp          CONSTANT VARCHAR2(1) := '1'; --完了
--
  --OPM保留在庫トランザクション削除マーク
  gn_delete_mark_no    CONSTANT NUMBER := 0; --未削除
--
  --クイックコード参照タイプ
  gv_lookup_newdiv     CONSTANT VARCHAR2(18) := 'XXCMN_NEW_DIVISION'; --新区分
  gv_lookup_basedate   CONSTANT VARCHAR2(15) := 'XXINV_BASE_DATE'; --基準日
--
  --着日/発日基準
  gv_base_date_arrival CONSTANT VARCHAR2(1) := '1'; --着日
  gv_base_date_ship    CONSTANT VARCHAR2(1) := '2'; --発日
--
  --レコードタイプ
  gv_rectype_in        CONSTANT VARCHAR2(2) := '30'; --入庫実績
  gv_rectype_out       CONSTANT VARCHAR2(2) := '20'; --出庫実績
--
  --ロット管理区分
  gn_lotctl_yes        CONSTANT NUMBER := 1; --ロット管理品
  gn_lotctl_no         CONSTANT NUMBER := 0; --非ロット管理品
--
  --移動タイプ
  gv_movetype_yes      CONSTANT VARCHAR2(1) := '1'; --積送あり
  gv_movetype_no       CONSTANT VARCHAR2(1) := '2'; --積送なし
--
  --実績計上済みフラグ
  gv_cmp_actl_yes      CONSTANT VARCHAR2(1) := 'Y'; --実績計上済み
--
  --取消フラグ
  gv_delete_no         CONSTANT VARCHAR2(1) := 'N'; --未取消
--
  --文書タイプ
  gv_dctype_move       CONSTANT VARCHAR2(2) := '20'; --移動
--
  --受払区分
  gv_rcvdiv_rcv        CONSTANT VARCHAR2(1) := '1'; --受入
  gv_rcvdiv_pay        CONSTANT VARCHAR2(2) := '-1'; --払出
--
  --出荷依頼/支給依頼ステータス
  gv_recsts_shipped    CONSTANT VARCHAR2(2) := '04'; --出荷実績計上済み(出荷依頼ステータス)
  gv_recsts_shipped2   CONSTANT VARCHAR2(2) := '08'; --出荷実績計上済み(支給依頼ステータス)
--
  --実績計上済み区分
  gv_confirm_yes       CONSTANT VARCHAR2(1) := 'Y'; --EBS計上済み
--
  --最新フラグ
  gv_latest_yes        CONSTANT VARCHAR2(1) := 'Y'; --最新
--
  --在庫使用区分
  gv_inventory         CONSTANT VARCHAR2(1) := 'Y'; --在庫
--
  --顧客区分
  gv_custclass         CONSTANT VARCHAR2(1) := '1'; --拠点
--
  --出荷支給区分
  gv_shipclass         CONSTANT VARCHAR2(1) := '3'; --倉替返品
--
  --ラインタイプ
  gn_linetype_mtrl     CONSTANT NUMBER := -1; --原料
  gn_linetype_prod     CONSTANT NUMBER := 1; --製品
--
  gv_dummy             CONSTANT VARCHAR2(5) := 'DUMMY';
--
--mod start 1.9
--  gv_item_transfer     CONSTANT VARCHAR2(8) := '品目振替';
  gv_item_transfer     CONSTANT VARCHAR2(100) := FND_PROFILE.VALUE('XXINV_DUMMY_ROUTING');           --品目振替
  gv_item_return       CONSTANT VARCHAR2(100) := FND_PROFILE.VALUE('XXINV_DUMMY_ROUTING_RET');       --返品原料
  gv_item_dissolve     CONSTANT VARCHAR2(100) := FND_PROFILE.VALUE('XXINV_DUMMY_ROUTING_SEPARATE');  --解体半製品
--mod end 1.9
--
  --事由コード
  gv_reason_other      CONSTANT VARCHAR2(4) := 'X977'; --相手先在庫
--
  --入出庫区分
  gv_inout_ctl_all     CONSTANT VARCHAR2(1) := '0'; --入出庫
  gv_inout_ctl_in      CONSTANT VARCHAR2(1) := '1'; --入庫
  gv_inout_ctl_out     CONSTANT VARCHAR2(1) := '2'; --出庫
--
  --単位区分
  gv_unitctl_qty       CONSTANT VARCHAR2(1) := '0'; --本数
  gv_unitctl_case      CONSTANT VARCHAR2(1) := '1'; --ケース
--
  --無効フラグ
  gv_inactive          CONSTANT VARCHAR2(1) := '1'; --無効
--
  --カテゴリマスタ使用可能フラグ
  gv_enabled_flag      CONSTANT VARCHAR2(1) := 'Y'; --有効
--
  --品目区分
  gv_item_class_prod   CONSTANT VARCHAR2(1) := '5'; --製品
--
  --在庫調整区分
  gv_stock_adjm        CONSTANT VARCHAR2(1) := '2'; --在庫調整
--
  --在庫タイプ
  gv_adji_xrart        CONSTANT VARCHAR2(1) := '1'; --受入返品実績
  gv_adji_xnpt         CONSTANT VARCHAR2(1) := '2'; --生葉実績
  gv_adji_xvst         CONSTANT VARCHAR2(1) := '3'; --外注出来高実績
  gv_adji_xmrih        CONSTANT VARCHAR2(1) := '4'; --移動実績
  gv_adji_ijm          CONSTANT VARCHAR2(1) := '5'; --EBS標準在庫実績
--
  --出荷支給区分
  gv_spdiv_ship        CONSTANT VARCHAR2(1) := '1'; --出荷依頼
  gv_spdiv_prov        CONSTANT VARCHAR2(1) := '2'; --支給依頼
--add start 1.2
  --新区分
  gv_newdiv_pay        CONSTANT VARCHAR2(3) := '402'; --倉庫移動_出庫
  gv_newdiv_rcv        CONSTANT VARCHAR2(3) := '401'; --倉庫移動_入庫
--add end 1.2
--add start 1.3
  gv_nullvalue         CONSTANT VARCHAR2(2) := CHR(09);
--add end 1.3
--add start 1.16
  --発注区分
  po_type_inv          CONSTANT VARCHAR2(1) := '3'; --相手先在庫
--add end 1.16
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  --カテゴリセット名
  gv_category_prod              VARCHAR2(100); --カテゴリセット名
  gv_category_item              VARCHAR2(100); --カテゴリセット名
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  --入力パラメータ格納用レコードタイプ
  TYPE rec_param_data  IS RECORD (
    ymd_from           VARCHAR2(4000)
   ,ymd_to             VARCHAR2(4000)
   ,base_date          VARCHAR2(4000)
   ,inout_ctl          VARCHAR2(4000)
   ,prod_div           VARCHAR2(4000)
   ,unit_ctl           VARCHAR2(4000)
   ,wh_loc_ctl         VARCHAR2(4000)
   ,wh_code_01         VARCHAR2(4000)
   ,wh_code_02         VARCHAR2(4000)
   ,wh_code_03         VARCHAR2(4000)
   ,block_01           VARCHAR2(4000)
   ,block_02           VARCHAR2(4000)
   ,block_03           VARCHAR2(4000)
   ,item_div           VARCHAR2(4000)
   ,item_code_01       VARCHAR2(4000)
   ,item_code_02       VARCHAR2(4000)
   ,item_code_03       VARCHAR2(4000)
   ,lot_no_01          VARCHAR2(4000)
   ,lot_no_02          VARCHAR2(4000)
   ,lot_no_03          VARCHAR2(4000)
   ,mnfctr_date_01     VARCHAR2(4000)
   ,mnfctr_date_02     VARCHAR2(4000)
   ,mnfctr_date_03     VARCHAR2(4000)
   ,reason_code_01     VARCHAR2(4000)
   ,reason_code_02     VARCHAR2(4000)
   ,reason_code_03     VARCHAR2(4000)
   ,symbol             VARCHAR2(4000)
  );
--
  --抽出データ格納用レコードタイプ
  TYPE rec_main_data IS RECORD(
    wh_code        VARCHAR2(4000)                                               --倉庫コード
   ,wh_name        VARCHAR2(4000)                                               --倉庫名
   ,strg_wh_code   VARCHAR2(4000)                                               --保管倉庫コード
   ,strg_wh_name   VARCHAR2(4000)                                               --保管倉庫名
   ,item_code      VARCHAR2(4000)                                               --品目コード
   ,item_name      VARCHAR2(4000)                                               --品目名
   ,standard_date  VARCHAR2(4000)                                               --日付
   ,reason_code    VARCHAR2(4000)                                               --事由コード
   ,reason_name    VARCHAR2(4000)                                               --事由
   ,slip_no        VARCHAR2(4000)                                               --伝票番号
   ,out_date       VARCHAR2(4000)                                               --出庫日
   ,in_date        VARCHAR2(4000)                                               --着日
   ,jrsd_code      VARCHAR2(4000)                                               --管轄拠点コード
   ,jrsd_name      VARCHAR2(4000)                                               --管轄拠点名
   ,other_code     VARCHAR2(4000)                                               --相手先コード
   ,other_name     VARCHAR2(4000)                                               --相手先名
   ,lot_no         VARCHAR2(4000)                                               --ロットNo
   ,mnfctr_date    VARCHAR2(4000)                                               --製造年月日
   ,limit_date     VARCHAR2(4000)                                               --賞味期限
   ,symbol         VARCHAR2(4000)                                               --固有記号
   ,unit           VARCHAR2(4000)                                               --単位
   ,num_of_cases   VARCHAR2(4000)                                               --ケース入り数
   ,in_qty         NUMBER                                                       --入庫数
   ,out_qty        NUMBER                                                       --出庫数
   ,item_div_name  VARCHAR2(4000)                                               --品目区分名称
  );
--
  --抽出データ格納用テーブル
  TYPE tab_main_data IS TABLE OF rec_main_data INDEX BY BINARY_INTEGER;
--
  /**********************************************************************************
   * Procedure Name   : put_line
   * Description      : FND_FILE.PUT_LINE実行
   ***********************************************************************************/
  PROCEDURE put_line(
    in_which IN NUMBER
   ,iv_msg   IN VARCHAR2
  )
  IS
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'put_line'; -- プログラム名
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
    FND_FILE.PUT_LINE(in_which,iv_msg);
--    DBMS_OUTPUT.PUT_LINE(iv_msg);
--
  END put_line;
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
   * Procedure Name   : output_xml
   * Description      : XMLデータ出力処理プロシージャ
   ***********************************************************************************/
  PROCEDURE output_xml(
    iox_xml_data         IN OUT    NOCOPY XML_DATA -- XMLデータ
   ,iv_output_mode       IN        VARCHAR2        -- 出力モード
   ,ov_errbuf            OUT       VARCHAR2        -- エラー・メッセージ           --# 固定 #
   ,ov_retcode           OUT       VARCHAR2        -- リターン・コード             --# 固定 #
   ,ov_errmsg            OUT       VARCHAR2        -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
    -- =====================================================
    -- 固定ローカル定数
    -- =====================================================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'output_xml' ;  --  プログラム名
--
    -- =====================================================
    -- ユーザー宣言部
    -- =====================================================
    -- *** ローカル変数 ***
    lv_xml_string  VARCHAR2(32000) ;
--
  BEGIN
    -- XMLヘッダ出力
    put_line(FND_FILE.OUTPUT,'<?xml version="1.0" encoding="shift_jis" ?>') ;
--
    IF (iv_output_mode = gv_output_normal) THEN
      --対象データがある場合
      <<xml_loop>>
      FOR i IN 1 .. iox_xml_data.COUNT LOOP
        lv_xml_string := convert_into_xml(
                           iox_xml_data(i).tag_name
                          ,iox_xml_data(i).tag_value
                          ,iox_xml_data(i).tag_type) ;
        put_line(FND_FILE.OUTPUT,lv_xml_string) ;
      END LOOP xml_loop ;
--
      -- XMLデータ(Temp)削除
      iox_xml_data.DELETE ;
--
    ELSE
      --対象データ0件の場合
      put_line( FND_FILE.OUTPUT, '<root>');
      put_line( FND_FILE.OUTPUT, '  <data_info>');
      put_line( FND_FILE.OUTPUT, '    <lg_strg_wh>');
      put_line( FND_FILE.OUTPUT, '      <g_strg_wh>');
      put_line( FND_FILE.OUTPUT, '        <lg_item>');
      put_line( FND_FILE.OUTPUT, '          <g_item>');
      put_line( FND_FILE.OUTPUT, '            <lg_date>');
      put_line( FND_FILE.OUTPUT, '              <g_date>');
      put_line( FND_FILE.OUTPUT, '                <msg>***　データはありません　***</msg>');
      put_line( FND_FILE.OUTPUT, '              </g_date>');
      put_line( FND_FILE.OUTPUT, '            </lg_date>');
      put_line( FND_FILE.OUTPUT, '          </g_item>');
      put_line( FND_FILE.OUTPUT, '        </lg_item>');
      put_line( FND_FILE.OUTPUT, '      </g_strg_wh>');
      put_line( FND_FILE.OUTPUT, '    </lg_strg_wh>');
      put_line( FND_FILE.OUTPUT, '  </data_info>');
      put_line( FND_FILE.OUTPUT, '</root>');
--
      --ステータスを警告にセット
      ov_retcode := gv_status_warn;
      --0件メッセージをセット
      ov_errmsg  := xxcmn_common_pkg.get_msg(gc_application_cmn,gc_xxcmn_10122) ;
    END IF;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg ;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error ;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM ;
      ov_retcode := gv_status_error ;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM ;
      ov_retcode := gv_status_error ;
--
--####################################  固定部 END   ##########################################
--
  END output_xml ;
--
  /**********************************************************************************
   * Procedure Name   : create_xml
   * Description      : XMLデータ作成
   ***********************************************************************************/
  PROCEDURE create_xml (
    iox_xml_data IN OUT NOCOPY XML_DATA
   ,ir_prm       IN            rec_param_data    --入力パラメータ
   ,it_main_data IN            tab_main_data     --抽出データセット
   ,ov_errbuf    OUT           VARCHAR2          --エラー・メッセージ           --# 固定 #
   ,ov_retcode   OUT           VARCHAR2          --リターン・コード             --# 固定 #
   ,ov_errmsg    OUT           VARCHAR2          --ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'create_xml'; -- プログラム名
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
    --前回処理データ格納用レコードタイプ
    TYPE prev_main_data IS RECORD(
      strg_wh_code           VARCHAR2(4000)
     ,item_code              VARCHAR2(4000)
     ,standard_date          VARCHAR2(4000)
    );
--
    -- *** ローカル変数 ***
    ln_idx                   NUMBER := 0;      --XMLデータINDEX
    lv_user_dept             VARCHAR2(10);     --担当部署名
    lv_user_name             VARCHAR2(14);     --担当者名
    lv_param_01_rmks         VARCHAR2(14);     --年月日_FROM
    lv_param_02_rmks         VARCHAR2(14);     --年月日_TO
    lv_param_03_rmks         VARCHAR2(16);     --着日/発日基準名称
    lv_param_14_rmks         VARCHAR2(6);      --品目区分名称
    lr_prev                  prev_main_data;   --前回処理データ
    ln_in_qty                NUMBER;           --入庫数
    ln_out_qty               NUMBER;           --出庫数
    ln_num_of_cases          NUMBER;           --ケース入り数
--
  BEGIN
--
    -- ====================================================
    -- ヘッダ出力情報の設定
    -- ====================================================
    --担当部署名取得
    BEGIN
      SELECT SUBSTRB(xxcmn_common_pkg.get_user_dept(FND_GLOBAL.USER_ID), 1, 10)
      INTO   lv_user_dept
      FROM   DUAL
      ;
    EXCEPTION
      WHEN OTHERS THEN
        NULL;
    END;
--
    --担当者名取得
    BEGIN
      SELECT SUBSTRB(xxcmn_common_pkg.get_user_name(FND_GLOBAL.USER_ID), 1, 14)
      INTO   lv_user_name
      FROM   DUAL
      ;
    EXCEPTION
      WHEN OTHERS THEN
        NULL;
    END;
--
    --年月日_FROM書式設定
    BEGIN
      SELECT TO_CHAR(TO_DATE(ir_prm.ymd_from,gv_fmt_ymd),gv_fmt_ymd_out)
      INTO   lv_param_01_rmks
      FROM DUAL
      ;
    EXCEPTION
      WHEN OTHERS THEN
        NULL;
    END;
--
    --年月日_TO書式設定
    BEGIN
      SELECT TO_CHAR(TO_DATE(ir_prm.ymd_to,gv_fmt_ymd),gv_fmt_ymd_out)
      INTO   lv_param_02_rmks
      FROM DUAL
      ;
    EXCEPTION
      WHEN OTHERS THEN
        NULL;
    END;
--
    --着日基準/発日基準名称取得
    BEGIN
      SELECT SUBSTRB(xlv.description, 1, 16)
      INTO   lv_param_03_rmks
      FROM xxcmn_lookup_values_v xlv
      WHERE xlv.lookup_type = gv_lookup_basedate
      AND xlv.lookup_code = ir_prm.base_date
      ;
    EXCEPTION
      WHEN OTHERS THEN
        NULL;
    END;
--
    --品目区分名称取得
    BEGIN
      SELECT xcv.description
      INTO lv_param_14_rmks
      FROM xxcmn_categories_v xcv
      WHERE xcv.segment1 = ir_prm.item_div
      AND xcv.category_set_name = gv_category_item
      ;
    EXCEPTION
      WHEN OTHERS THEN
        NULL;
    END;
--
    -- ====================================================
    -- USER_INFO作成
    -- ====================================================
    --root開始タグセット
    ln_idx := iox_xml_data.COUNT + 1 ;
    iox_xml_data(ln_idx).tag_name  := 'root' ;
    iox_xml_data(ln_idx).tag_type  := 'T' ;
--
    --user_info開始タグセット
    ln_idx := iox_xml_data.COUNT + 1 ;
    iox_xml_data(ln_idx).tag_name  := 'user_info' ;
    iox_xml_data(ln_idx).tag_type  := 'T' ;
--
    --report_idデータセット
    ln_idx := iox_xml_data.COUNT + 1 ;
    iox_xml_data(ln_idx).tag_name  := 'report_id' ;
    iox_xml_data(ln_idx).tag_type  := 'D' ;
    iox_xml_data(ln_idx).tag_value := gv_report_id ;
--
    --exec_dateデータセット
    ln_idx := iox_xml_data.COUNT + 1 ;
    iox_xml_data(ln_idx).tag_name  := 'exec_date' ;
    iox_xml_data(ln_idx).tag_type  := 'D' ;
    iox_xml_data(ln_idx).tag_value := TO_CHAR(SYSDATE, gv_fmt_ymd_out2);
--
    --exec_user_deptデータセット
    ln_idx := iox_xml_data.COUNT + 1 ;
    iox_xml_data(ln_idx).tag_name  := 'exec_user_dept' ;
    iox_xml_data(ln_idx).tag_type  := 'D' ;
    iox_xml_data(ln_idx).tag_value := lv_user_dept;
--
    --exec_user_nameデータセット
    ln_idx := iox_xml_data.COUNT + 1 ;
    iox_xml_data(ln_idx).tag_name  := 'exec_user_name' ;
    iox_xml_data(ln_idx).tag_type  := 'D' ;
    iox_xml_data(ln_idx).tag_value := lv_user_name;
--
    --user_info終了タグセット
    ln_idx := iox_xml_data.COUNT + 1 ;
    iox_xml_data(ln_idx).tag_name  := '/user_info' ;
    iox_xml_data(ln_idx).tag_type  := 'T' ;
--
    -- ====================================================
    -- PARAM_INFO作成
    -- ====================================================
    --param_info開始タグセット
    ln_idx := iox_xml_data.COUNT + 1 ;
    iox_xml_data(ln_idx).tag_name  := 'param_info' ;
    iox_xml_data(ln_idx).tag_type  := 'T' ;
--
    --param_01データセット
    ln_idx := iox_xml_data.COUNT + 1 ;
    iox_xml_data(ln_idx).tag_name  := 'param_01' ;
    iox_xml_data(ln_idx).tag_type  := 'D' ;
    iox_xml_data(ln_idx).tag_value := ir_prm.ymd_from;
--
    --param_01_remarksデータセット
    ln_idx := iox_xml_data.COUNT + 1 ;
    iox_xml_data(ln_idx).tag_name  := 'param_01_remarks' ;
    iox_xml_data(ln_idx).tag_type  := 'D' ;
    iox_xml_data(ln_idx).tag_value := lv_param_01_rmks;
--
    --param_02データセット
    ln_idx := iox_xml_data.COUNT + 1 ;
    iox_xml_data(ln_idx).tag_name  := 'param_02' ;
    iox_xml_data(ln_idx).tag_type  := 'D' ;
    iox_xml_data(ln_idx).tag_value := ir_prm.ymd_to;
--
    --param_02_remarksデータセット
    ln_idx := iox_xml_data.COUNT + 1 ;
    iox_xml_data(ln_idx).tag_name  := 'param_02_remarks' ;
    iox_xml_data(ln_idx).tag_type  := 'D' ;
    iox_xml_data(ln_idx).tag_value := lv_param_02_rmks;
--
    --param_03データセット
    ln_idx := iox_xml_data.COUNT + 1 ;
    iox_xml_data(ln_idx).tag_name  := 'param_03' ;
    iox_xml_data(ln_idx).tag_type  := 'D' ;
    iox_xml_data(ln_idx).tag_value := ir_prm.base_date;
--
    --param_03_remarksデータセット
    ln_idx := iox_xml_data.COUNT + 1 ;
    iox_xml_data(ln_idx).tag_name  := 'param_03_remarks' ;
    iox_xml_data(ln_idx).tag_type  := 'D' ;
    iox_xml_data(ln_idx).tag_value := lv_param_03_rmks;
--
    --param_04データセット
    ln_idx := iox_xml_data.COUNT + 1 ;
    iox_xml_data(ln_idx).tag_name  := 'param_04' ;
    iox_xml_data(ln_idx).tag_type  := 'D' ;
    iox_xml_data(ln_idx).tag_value := ir_prm.inout_ctl;
--
    --param_05データセット
    ln_idx := iox_xml_data.COUNT + 1 ;
    iox_xml_data(ln_idx).tag_name  := 'param_05' ;
    iox_xml_data(ln_idx).tag_type  := 'D' ;
    iox_xml_data(ln_idx).tag_value := ir_prm.prod_div;
--
    --param_06データセット
    ln_idx := iox_xml_data.COUNT + 1 ;
    iox_xml_data(ln_idx).tag_name  := 'param_06' ;
    iox_xml_data(ln_idx).tag_type  := 'D' ;
    iox_xml_data(ln_idx).tag_value := ir_prm.unit_ctl;
--
    --param_07データセット
    ln_idx := iox_xml_data.COUNT + 1 ;
    iox_xml_data(ln_idx).tag_name  := 'param_07' ;
    iox_xml_data(ln_idx).tag_type  := 'D' ;
    iox_xml_data(ln_idx).tag_value := ir_prm.wh_loc_ctl;
--
    --param_08データセット
    ln_idx := iox_xml_data.COUNT + 1 ;
    iox_xml_data(ln_idx).tag_name  := 'param_08' ;
    iox_xml_data(ln_idx).tag_type  := 'D' ;
    iox_xml_data(ln_idx).tag_value := ir_prm.wh_code_01;
--
    --param_09データセット
    ln_idx := iox_xml_data.COUNT + 1 ;
    iox_xml_data(ln_idx).tag_name  := 'param_09' ;
    iox_xml_data(ln_idx).tag_type  := 'D' ;
    iox_xml_data(ln_idx).tag_value := ir_prm.wh_code_02;
--
    --param_10データセット
    ln_idx := iox_xml_data.COUNT + 1 ;
    iox_xml_data(ln_idx).tag_name  := 'param_10' ;
    iox_xml_data(ln_idx).tag_type  := 'D' ;
    iox_xml_data(ln_idx).tag_value := ir_prm.wh_code_03;
--
    --param_11データセット
    ln_idx := iox_xml_data.COUNT + 1 ;
    iox_xml_data(ln_idx).tag_name  := 'param_11' ;
    iox_xml_data(ln_idx).tag_type  := 'D' ;
    iox_xml_data(ln_idx).tag_value := ir_prm.block_01;
--
    --param_12データセット
    ln_idx := iox_xml_data.COUNT + 1 ;
    iox_xml_data(ln_idx).tag_name  := 'param_12' ;
    iox_xml_data(ln_idx).tag_type  := 'D' ;
    iox_xml_data(ln_idx).tag_value := ir_prm.block_02;
--
    --param_13データセット
    ln_idx := iox_xml_data.COUNT + 1 ;
    iox_xml_data(ln_idx).tag_name  := 'param_13' ;
    iox_xml_data(ln_idx).tag_type  := 'D' ;
    iox_xml_data(ln_idx).tag_value := ir_prm.block_03;
--
    --param_14データセット
    ln_idx := iox_xml_data.COUNT + 1 ;
    iox_xml_data(ln_idx).tag_name  := 'param_14' ;
    iox_xml_data(ln_idx).tag_type  := 'D' ;
    iox_xml_data(ln_idx).tag_value := ir_prm.item_div;
--
    --param_14_remarksデータセット
    ln_idx := iox_xml_data.COUNT + 1 ;
    iox_xml_data(ln_idx).tag_name  := 'param_14_remarks' ;
    iox_xml_data(ln_idx).tag_type  := 'D' ;
    iox_xml_data(ln_idx).tag_value := lv_param_14_rmks;
--
    --param_15データセット
    ln_idx := iox_xml_data.COUNT + 1 ;
    iox_xml_data(ln_idx).tag_name  := 'param_15' ;
    iox_xml_data(ln_idx).tag_type  := 'D' ;
    iox_xml_data(ln_idx).tag_value := ir_prm.item_code_01;
--
    --param_16データセット
    ln_idx := iox_xml_data.COUNT + 1 ;
    iox_xml_data(ln_idx).tag_name  := 'param_16' ;
    iox_xml_data(ln_idx).tag_type  := 'D' ;
    iox_xml_data(ln_idx).tag_value := ir_prm.item_code_02;
--
    --param_17データセット
    ln_idx := iox_xml_data.COUNT + 1 ;
    iox_xml_data(ln_idx).tag_name  := 'param_17' ;
    iox_xml_data(ln_idx).tag_type  := 'D' ;
    iox_xml_data(ln_idx).tag_value := ir_prm.item_code_03;
--
    --param_18データセット
    ln_idx := iox_xml_data.COUNT + 1 ;
    iox_xml_data(ln_idx).tag_name  := 'param_18' ;
    iox_xml_data(ln_idx).tag_type  := 'D' ;
    iox_xml_data(ln_idx).tag_value := ir_prm.lot_no_01;
--
    --param_19データセット
    ln_idx := iox_xml_data.COUNT + 1 ;
    iox_xml_data(ln_idx).tag_name  := 'param_19' ;
    iox_xml_data(ln_idx).tag_type  := 'D' ;
    iox_xml_data(ln_idx).tag_value := ir_prm.lot_no_02;
--
    --param_20データセット
    ln_idx := iox_xml_data.COUNT + 1 ;
    iox_xml_data(ln_idx).tag_name  := 'param_20' ;
    iox_xml_data(ln_idx).tag_type  := 'D' ;
    iox_xml_data(ln_idx).tag_value := ir_prm.lot_no_03;
--
    --param_21データセット
    ln_idx := iox_xml_data.COUNT + 1 ;
    iox_xml_data(ln_idx).tag_name  := 'param_21' ;
    iox_xml_data(ln_idx).tag_type  := 'D' ;
    iox_xml_data(ln_idx).tag_value := ir_prm.mnfctr_date_01;
--
    --param_22データセット
    ln_idx := iox_xml_data.COUNT + 1 ;
    iox_xml_data(ln_idx).tag_name  := 'param_22' ;
    iox_xml_data(ln_idx).tag_type  := 'D' ;
    iox_xml_data(ln_idx).tag_value := ir_prm.mnfctr_date_02;
--
    --param_23データセット
    ln_idx := iox_xml_data.COUNT + 1 ;
    iox_xml_data(ln_idx).tag_name  := 'param_23' ;
    iox_xml_data(ln_idx).tag_type  := 'D' ;
    iox_xml_data(ln_idx).tag_value := ir_prm.mnfctr_date_03;
--
    --param_24データセット
    ln_idx := iox_xml_data.COUNT + 1 ;
    iox_xml_data(ln_idx).tag_name  := 'param_24' ;
    iox_xml_data(ln_idx).tag_type  := 'D' ;
    iox_xml_data(ln_idx).tag_value := ir_prm.reason_code_01;
--
    --param_25データセット
    ln_idx := iox_xml_data.COUNT + 1 ;
    iox_xml_data(ln_idx).tag_name  := 'param_25' ;
    iox_xml_data(ln_idx).tag_type  := 'D' ;
    iox_xml_data(ln_idx).tag_value := ir_prm.reason_code_02;
--
    --param_26データセット
    ln_idx := iox_xml_data.COUNT + 1 ;
    iox_xml_data(ln_idx).tag_name  := 'param_26' ;
    iox_xml_data(ln_idx).tag_type  := 'D' ;
    iox_xml_data(ln_idx).tag_value := ir_prm.reason_code_03;
--
    --param_27データセット
    ln_idx := iox_xml_data.COUNT + 1 ;
    iox_xml_data(ln_idx).tag_name  := 'param_27' ;
    iox_xml_data(ln_idx).tag_type  := 'D' ;
    iox_xml_data(ln_idx).tag_value := ir_prm.symbol;
--
    --param_info終了タグセット
    ln_idx := iox_xml_data.COUNT + 1 ;
    iox_xml_data(ln_idx).tag_name  := '/param_info' ;
    iox_xml_data(ln_idx).tag_type  := 'T' ;
--
    -- ====================================================
    -- DATA_INFO作成
    -- ====================================================
    --data_info開始タグセット
    ln_idx := iox_xml_data.COUNT + 1 ;
    iox_xml_data(ln_idx).tag_name  := 'data_info' ;
    iox_xml_data(ln_idx).tag_type  := 'T' ;
--
    --lg_strg_wh開始タグセット
    ln_idx := iox_xml_data.COUNT + 1 ;
    iox_xml_data(ln_idx).tag_name  := 'lg_strg_wh' ;
    iox_xml_data(ln_idx).tag_type  := 'T' ;
--
    --g_strg_wh開始タグセット
    ln_idx := iox_xml_data.COUNT + 1 ;
    iox_xml_data(ln_idx).tag_name  := 'g_strg_wh' ;
    iox_xml_data(ln_idx).tag_type  := 'T' ;
--
    <<main_data_loop>>
    FOR i IN 1..it_main_data.COUNT LOOP
--
      --初回のみ行うタグセット
      IF (i = 1) THEN
        --wh_codeデータセット
        ln_idx := iox_xml_data.COUNT + 1 ;
        iox_xml_data(ln_idx).tag_name  := 'wh_code' ;
        iox_xml_data(ln_idx).tag_type  := 'D' ;
        iox_xml_data(ln_idx).tag_value := it_main_data(i).wh_code;
--
        --wh_nameデータセット
        ln_idx := iox_xml_data.COUNT + 1 ;
        iox_xml_data(ln_idx).tag_name  := 'wh_name' ;
        iox_xml_data(ln_idx).tag_type  := 'D' ;
        iox_xml_data(ln_idx).tag_value := it_main_data(i).wh_name;
--
        --strg_wh_codeデータセット
        ln_idx := iox_xml_data.COUNT + 1 ;
        iox_xml_data(ln_idx).tag_name  := 'strg_wh_code' ;
        iox_xml_data(ln_idx).tag_type  := 'D' ;
        iox_xml_data(ln_idx).tag_value := it_main_data(i).strg_wh_code;
--
        --strg_wh_nameデータセット
        ln_idx := iox_xml_data.COUNT + 1 ;
        iox_xml_data(ln_idx).tag_name  := 'strg_wh_name' ;
        iox_xml_data(ln_idx).tag_type  := 'D' ;
        iox_xml_data(ln_idx).tag_value := it_main_data(i).strg_wh_name;
--
        --lg_item開始タグセット
        ln_idx := iox_xml_data.COUNT + 1 ;
        iox_xml_data(ln_idx).tag_name  := 'lg_item' ;
        iox_xml_data(ln_idx).tag_type  := 'T' ;
--
        --g_item開始タグセット
        ln_idx := iox_xml_data.COUNT + 1 ;
        iox_xml_data(ln_idx).tag_name  := 'g_item' ;
        iox_xml_data(ln_idx).tag_type  := 'T' ;
--
        --lg_date開始タグセット
        ln_idx := iox_xml_data.COUNT + 1 ;
        iox_xml_data(ln_idx).tag_name  := 'lg_date' ;
        iox_xml_data(ln_idx).tag_type  := 'T' ;
--
        --g_date開始タグセット
        ln_idx := iox_xml_data.COUNT + 1 ;
        iox_xml_data(ln_idx).tag_name  := 'g_date' ;
        iox_xml_data(ln_idx).tag_type  := 'T' ;
--
      --2件目以降に行うタグセット
      ELSE
--
        --保管倉庫コード、品目コード、日付のいずれかがブレイクした場合
        IF ( (lr_prev.strg_wh_code != it_main_data(i).strg_wh_code)
          OR (lr_prev.item_code != it_main_data(i).item_code)
          OR (lr_prev.standard_date != it_main_data(i).standard_date)
        ) THEN
--
          --g_date終了タグセット
          ln_idx := iox_xml_data.COUNT + 1 ;
          iox_xml_data(ln_idx).tag_name  := '/g_date' ;
          iox_xml_data(ln_idx).tag_type  := 'T' ;
--
          --保管倉庫コード、品目コードのいずれかがブレイクした場合
          IF ( (lr_prev.strg_wh_code != it_main_data(i).strg_wh_code)
            OR (lr_prev.item_code != it_main_data(i).item_code)
          ) THEN
            --lg_date終了タグセット
            ln_idx := iox_xml_data.COUNT + 1 ;
            iox_xml_data(ln_idx).tag_name  := '/lg_date' ;
            iox_xml_data(ln_idx).tag_type  := 'T' ;
--
            --g_item終了タグセット
            ln_idx := iox_xml_data.COUNT + 1 ;
            iox_xml_data(ln_idx).tag_name  := '/g_item' ;
            iox_xml_data(ln_idx).tag_type  := 'T' ;
--
            --保管倉庫コードがブレイクした場合
            IF (lr_prev.strg_wh_code != it_main_data(i).strg_wh_code) THEN
              --lg_item終了タグセット
              ln_idx := iox_xml_data.COUNT + 1 ;
              iox_xml_data(ln_idx).tag_name  := '/lg_item' ;
              iox_xml_data(ln_idx).tag_type  := 'T' ;
--
              --g_strg_wh終了タグセット
              ln_idx := iox_xml_data.COUNT + 1 ;
              iox_xml_data(ln_idx).tag_name  := '/g_strg_wh' ;
              iox_xml_data(ln_idx).tag_type  := 'T' ;
--
              --g_strg_wh開始タグセット
              ln_idx := iox_xml_data.COUNT + 1 ;
              iox_xml_data(ln_idx).tag_name  := 'g_strg_wh' ;
              iox_xml_data(ln_idx).tag_type  := 'T' ;
--
              --wh_codeデータセット
              ln_idx := iox_xml_data.COUNT + 1 ;
              iox_xml_data(ln_idx).tag_name  := 'wh_code' ;
              iox_xml_data(ln_idx).tag_type  := 'D' ;
              iox_xml_data(ln_idx).tag_value := it_main_data(i).wh_code;
--
              --wh_nameデータセット
              ln_idx := iox_xml_data.COUNT + 1 ;
              iox_xml_data(ln_idx).tag_name  := 'wh_name' ;
              iox_xml_data(ln_idx).tag_type  := 'D' ;
              iox_xml_data(ln_idx).tag_value := it_main_data(i).wh_name;
--
              --strg_wh_codeデータセット
              ln_idx := iox_xml_data.COUNT + 1 ;
              iox_xml_data(ln_idx).tag_name  := 'strg_wh_code' ;
              iox_xml_data(ln_idx).tag_type  := 'D' ;
              iox_xml_data(ln_idx).tag_value := it_main_data(i).strg_wh_code;
--
              --strg_wh_nameデータセット
              ln_idx := iox_xml_data.COUNT + 1 ;
              iox_xml_data(ln_idx).tag_name  := 'strg_wh_name' ;
              iox_xml_data(ln_idx).tag_type  := 'D' ;
              iox_xml_data(ln_idx).tag_value := it_main_data(i).strg_wh_name;
--
              --lg_item開始タグセット
              ln_idx := iox_xml_data.COUNT + 1 ;
              iox_xml_data(ln_idx).tag_name  := 'lg_item' ;
              iox_xml_data(ln_idx).tag_type  := 'T' ;
--
            END IF;
--
            --g_item開始タグセット
            ln_idx := iox_xml_data.COUNT + 1 ;
            iox_xml_data(ln_idx).tag_name  := 'g_item' ;
            iox_xml_data(ln_idx).tag_type  := 'T' ;
--
            --lg_date開始タグセット
            ln_idx := iox_xml_data.COUNT + 1 ;
            iox_xml_data(ln_idx).tag_name  := 'lg_date' ;
            iox_xml_data(ln_idx).tag_type  := 'T' ;
--
          END IF;
--
          --g_date開始タグセット
          ln_idx := iox_xml_data.COUNT + 1 ;
          iox_xml_data(ln_idx).tag_name  := 'g_date' ;
          iox_xml_data(ln_idx).tag_type  := 'T' ;
--
        END IF;
--
      END IF;
--
      --g_slip開始タグセット
      ln_idx := iox_xml_data.COUNT + 1 ;
      iox_xml_data(ln_idx).tag_name  := 'g_slip' ;
      iox_xml_data(ln_idx).tag_type  := 'T' ;
--
      --item_codeデータセット
      ln_idx := iox_xml_data.COUNT + 1 ;
      iox_xml_data(ln_idx).tag_name  := 'item_code' ;
      iox_xml_data(ln_idx).tag_type  := 'D' ;
      iox_xml_data(ln_idx).tag_value := it_main_data(i).item_code;
--
      --item_nameデータセット
      ln_idx := iox_xml_data.COUNT + 1 ;
      iox_xml_data(ln_idx).tag_name  := 'item_name' ;
      iox_xml_data(ln_idx).tag_type  := 'D' ;
      iox_xml_data(ln_idx).tag_value := it_main_data(i).item_name;
--
      --standard_dateデータセット
      ln_idx := iox_xml_data.COUNT + 1 ;
      iox_xml_data(ln_idx).tag_name  := 'standard_date' ;
      iox_xml_data(ln_idx).tag_type  := 'D' ;
      iox_xml_data(ln_idx).tag_value := it_main_data(i).standard_date;
--
      --reason_codeデータセット
      ln_idx := iox_xml_data.COUNT + 1 ;
      iox_xml_data(ln_idx).tag_name  := 'reason_code' ;
      iox_xml_data(ln_idx).tag_type  := 'D' ;
      iox_xml_data(ln_idx).tag_value := it_main_data(i).reason_code;
--
      --reason_nameデータセット
      ln_idx := iox_xml_data.COUNT + 1 ;
      iox_xml_data(ln_idx).tag_name  := 'reason_name' ;
      iox_xml_data(ln_idx).tag_type  := 'D' ;
      iox_xml_data(ln_idx).tag_value := it_main_data(i).reason_name;
--
      --slip_noデータセット
      ln_idx := iox_xml_data.COUNT + 1 ;
      iox_xml_data(ln_idx).tag_name  := 'slip_no' ;
      iox_xml_data(ln_idx).tag_type  := 'D' ;
      iox_xml_data(ln_idx).tag_value := it_main_data(i).slip_no;
--
      --out_dateデータセット
      ln_idx := iox_xml_data.COUNT + 1 ;
      iox_xml_data(ln_idx).tag_name  := 'out_date' ;
      iox_xml_data(ln_idx).tag_type  := 'D' ;
      iox_xml_data(ln_idx).tag_value := it_main_data(i).out_date;
--
      --in_dateデータセット
      ln_idx := iox_xml_data.COUNT + 1 ;
      iox_xml_data(ln_idx).tag_name  := 'in_date' ;
      iox_xml_data(ln_idx).tag_type  := 'D' ;
      iox_xml_data(ln_idx).tag_value := it_main_data(i).in_date;
--
      --jrsd_codeデータセット
      ln_idx := iox_xml_data.COUNT + 1 ;
      iox_xml_data(ln_idx).tag_name  := 'jrsd_code' ;
      iox_xml_data(ln_idx).tag_type  := 'D' ;
      iox_xml_data(ln_idx).tag_value := it_main_data(i).jrsd_code;
--
      --jrsd_nameデータセット
      ln_idx := iox_xml_data.COUNT + 1 ;
      iox_xml_data(ln_idx).tag_name  := 'jrsd_name' ;
      iox_xml_data(ln_idx).tag_type  := 'D' ;
      iox_xml_data(ln_idx).tag_value := it_main_data(i).jrsd_name;
--
      --other_codeデータセット
      ln_idx := iox_xml_data.COUNT + 1 ;
      iox_xml_data(ln_idx).tag_name  := 'other_code' ;
      iox_xml_data(ln_idx).tag_type  := 'D' ;
      iox_xml_data(ln_idx).tag_value := it_main_data(i).other_code;
--
      --other_nameデータセット
      ln_idx := iox_xml_data.COUNT + 1 ;
      iox_xml_data(ln_idx).tag_name  := 'other_name' ;
      iox_xml_data(ln_idx).tag_type  := 'D' ;
      iox_xml_data(ln_idx).tag_value := it_main_data(i).other_name;
--
      --lot_noデータセット
      ln_idx := iox_xml_data.COUNT + 1 ;
      iox_xml_data(ln_idx).tag_name  := 'lot_no' ;
      iox_xml_data(ln_idx).tag_type  := 'D' ;
      iox_xml_data(ln_idx).tag_value := it_main_data(i).lot_no;
--
      --mnfctr_dateデータセット
      ln_idx := iox_xml_data.COUNT + 1 ;
      iox_xml_data(ln_idx).tag_name  := 'mnfctr_date' ;
      iox_xml_data(ln_idx).tag_type  := 'D' ;
      iox_xml_data(ln_idx).tag_value := it_main_data(i).mnfctr_date;
--
      --limit_dateデータセット
      ln_idx := iox_xml_data.COUNT + 1 ;
      iox_xml_data(ln_idx).tag_name  := 'limit_date' ;
      iox_xml_data(ln_idx).tag_type  := 'D' ;
      iox_xml_data(ln_idx).tag_value := it_main_data(i).limit_date;
--
      --symbolデータセット
      ln_idx := iox_xml_data.COUNT + 1 ;
      iox_xml_data(ln_idx).tag_name  := 'symbol' ;
      iox_xml_data(ln_idx).tag_type  := 'D' ;
      iox_xml_data(ln_idx).tag_value := it_main_data(i).symbol;
--
      --本数(ケース数)算出
      IF (ir_prm.unit_ctl = gv_unitctl_case) THEN
        IF (NVL(it_main_data(i).num_of_cases,'0') = '0') THEN
          ln_num_of_cases := 1;
        ELSE
          ln_num_of_cases := TO_NUMBER(it_main_data(i).num_of_cases);
        END IF;
--
        ln_in_qty := ROUND(it_main_data(i).in_qty / ln_num_of_cases, 3);
        ln_out_qty := ROUND(it_main_data(i).out_qty / ln_num_of_cases, 3);
      ELSE
        ln_in_qty := it_main_data(i).in_qty;
        ln_out_qty := it_main_data(i).out_qty;
      END IF;
--
      --in_qtyデータセット
      ln_idx := iox_xml_data.COUNT + 1 ;
      iox_xml_data(ln_idx).tag_name  := 'in_qty' ;
      iox_xml_data(ln_idx).tag_type  := 'D' ;
      iox_xml_data(ln_idx).tag_value := ln_in_qty;
--
      --out_qtyデータセット
      ln_idx := iox_xml_data.COUNT + 1 ;
      iox_xml_data(ln_idx).tag_name  := 'out_qty' ;
      iox_xml_data(ln_idx).tag_type  := 'D' ;
      iox_xml_data(ln_idx).tag_value := ln_out_qty;
--
      --unitデータセット
      ln_idx := iox_xml_data.COUNT + 1 ;
      iox_xml_data(ln_idx).tag_name  := 'unit' ;
      iox_xml_data(ln_idx).tag_type  := 'D' ;
      iox_xml_data(ln_idx).tag_value := it_main_data(i).unit;
--
      --g_slip終了タグセット
      ln_idx := iox_xml_data.COUNT + 1 ;
      iox_xml_data(ln_idx).tag_name  := '/g_slip' ;
      iox_xml_data(ln_idx).tag_type  := 'T' ;
--
      --前回処理データの記憶
      lr_prev.strg_wh_code := it_main_data(i).strg_wh_code;   --保管倉庫コード
      lr_prev.item_code := it_main_data(i).item_code;         --品目コード
      lr_prev.standard_date := it_main_data(i).standard_date; --日付
--
    END LOOP main_data_loop;
--
    --g_date終了タグセット
    ln_idx := iox_xml_data.COUNT + 1 ;
    iox_xml_data(ln_idx).tag_name  := '/g_date' ;
    iox_xml_data(ln_idx).tag_type  := 'T' ;
--
    --lg_date終了タグセット
    ln_idx := iox_xml_data.COUNT + 1 ;
    iox_xml_data(ln_idx).tag_name  := '/lg_date' ;
    iox_xml_data(ln_idx).tag_type  := 'T' ;
--
    --g_item終了タグセット
    ln_idx := iox_xml_data.COUNT + 1 ;
    iox_xml_data(ln_idx).tag_name  := '/g_item' ;
    iox_xml_data(ln_idx).tag_type  := 'T' ;
--
    --lg_item終了タグセット
    ln_idx := iox_xml_data.COUNT + 1 ;
    iox_xml_data(ln_idx).tag_name  := '/lg_item' ;
    iox_xml_data(ln_idx).tag_type  := 'T' ;
--
    --g_strg_wh終了タグセット
    ln_idx := iox_xml_data.COUNT + 1 ;
    iox_xml_data(ln_idx).tag_name  := '/g_strg_wh' ;
    iox_xml_data(ln_idx).tag_type  := 'T' ;
--
    --lg_strg_wh終了タグセット
    ln_idx := iox_xml_data.COUNT + 1 ;
    iox_xml_data(ln_idx).tag_name  := '/lg_strg_wh' ;
    iox_xml_data(ln_idx).tag_type  := 'T' ;
--
    --data_info終了タグセット
    ln_idx := iox_xml_data.COUNT + 1 ;
    iox_xml_data(ln_idx).tag_name  := '/data_info' ;
    iox_xml_data(ln_idx).tag_type  := 'T' ;
--
    --root終了タグセット
    ln_idx := iox_xml_data.COUNT + 1 ;
    iox_xml_data(ln_idx).tag_name  := '/root' ;
    iox_xml_data(ln_idx).tag_type  := 'T' ;
--
  EXCEPTION
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
  END create_xml;
--
  /**********************************************************************************
   * Procedure Name   : get_record
   * Description      : データ抽出処理
   ***********************************************************************************/
  PROCEDURE get_record(
    ir_prm        IN  rec_param_data
   ,ot_main_data  OUT tab_main_data
   ,ov_errbuf     OUT VARCHAR2     --   エラー・メッセージ           --# 固定 #
   ,ov_retcode    OUT VARCHAR2     --   リターン・コード             --# 固定 #
   ,ov_errmsg     OUT VARCHAR2     --   ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_record'; -- プログラム名
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
    ln_main_data_cnt     NUMBER;
--
    -- *** ローカル・カーソル ***
    CURSOR cur_main_data(
      civ_ymd_from VARCHAR2        --年月日_FROM
     ,civ_ymd_to VARCHAR2          --年月日_TO
     ,civ_base_date VARCHAR2       --着日基準／発日基準
     ,civ_inout_ctl VARCHAR2       --入出庫区分
     ,civ_prod_div VARCHAR2        --商品区分
     ,civ_unit_ctl VARCHAR2        --単位区分
     ,civ_wh_loc_ctl VARCHAR2      --倉庫/保管倉庫選択区分
     ,civ_wh_code_01 VARCHAR2      --倉庫/保管倉庫コード1
     ,civ_wh_code_02 VARCHAR2      --倉庫/保管倉庫コード2
     ,civ_wh_code_03 VARCHAR2      --倉庫/保管倉庫コード3
     ,civ_block_01 VARCHAR2        --ブロック1
     ,civ_block_02 VARCHAR2        --ブロック2
     ,civ_block_03 VARCHAR2        --ブロック3
     ,civ_item_div VARCHAR2        --品目区分
     ,civ_item_code_01 VARCHAR2    --品目コード1
     ,civ_item_code_02 VARCHAR2    --品目コード2
     ,civ_item_code_03 VARCHAR2    --品目コード3
     ,civ_lot_no_01 VARCHAR2       --ロットNo1
     ,civ_lot_no_02 VARCHAR2       --ロットNo2
     ,civ_lot_no_03 VARCHAR2       --ロットNo3
     ,civ_mnfctr_date_01 VARCHAR2  --製造年月日1
     ,civ_mnfctr_date_02 VARCHAR2  --製造年月日2
     ,civ_mnfctr_date_03 VARCHAR2  --製造年月日3
     ,civ_reason_code_01 VARCHAR2  --事由コード1
     ,civ_reason_code_02 VARCHAR2  --事由コード2
     ,civ_reason_code_03 VARCHAR2  --事由コード3
     ,civ_symbol VARCHAR2          --固有記号
    )
    IS 
      --======================================================================================================
      SELECT
        slip.whse_code                                        whse_code           --倉庫コード
       ,slip.whse_name                                        whse_name           --倉庫名称
       ,slip.location                                         strg_wh_code        --保管倉庫コード
       ,slip.description                                      strg_wh_name        --保管倉庫名称
       ,ximv.item_no                                          item_code           --品目コード
       ,ximv.item_short_name                                  item_name           --品目名称
       ,slip.standard_date                                    standard_date       --日付
       ,slip.reason_code                                      reason_code         --事由コード
       ,xlvv.meaning                                          reason_name         --事由コード名称
       ,slip.slip_no                                          slip_no             --伝票番号
       ,slip.out_date                                         out_date            --出庫日
       ,slip.in_date                                          in_date             --着日
       ,slip.jrsd_code                                        jrsd_code           --管轄拠点コード
       ,slip.jrsd_name                                        jrsd_name           --管轄拠点名称
       ,slip.other_code                                       other_code          --相手先コード
       ,CASE slip.territory
          WHEN gv_trtry_ad THEN
            NVL(slip.other_name,xlvv.meaning)
          ELSE slip.other_name
        END                                                   other_name          --相手先名
       ,DECODE(ximv.lot_ctl
              ,gn_lotctl_yes,ilm.lot_no
              ,NULL)                                          lot_no              --ロットNo
       ,DECODE(ximv.lot_ctl
              ,gn_lotctl_yes,SUBSTRB(ilm.attribute1,1,10)
              ,NULL)                                          mnfctr_date         --製造年月日
       ,DECODE(ximv.lot_ctl
              ,gn_lotctl_yes,SUBSTRB(ilm.attribute3,1,10)
              ,NULL)                                          limit_date          --賞味期限
       ,DECODE(ximv.lot_ctl
              ,gn_lotctl_yes,SUBSTRB(ilm.attribute2,1,6)
              ,NULL)                                          symbol              --固有記号
--mod start 2.1
--       ,CASE slip.territory
--          WHEN gv_trtry_po THEN ximv.item_um                                        --発注：単位
--          WHEN gv_trtry_mv THEN ximv.item_um                                        --移動：単位
--          WHEN gv_trtry_sh THEN ximv.conv_unit                                      --出荷：入出庫換算単位
--          WHEN gv_trtry_rt THEN ximv.conv_unit                                      --倉替返品：入出庫換算単位
--          WHEN gv_trtry_mf THEN ximv.item_um                                        --生産：単位
--          WHEN gv_trtry_ad THEN ximv.item_um                                        --在庫調整：単位
--          ELSE NULL
--        END                                                   unit                --単位
       ,DECODE(civ_unit_ctl
              ,gv_unitctl_qty ,ximv.item_um
              ,gv_unitctl_case,ximv.conv_unit
              ,NULL)                                          unit                --単位
--mod end 2.1
       ,ximv.num_of_cases                                     num_of_cases        --ケース入り数
       ,NVL(slip.in_qty,0)                                    in_qty              --入庫数
-- mod start 1.18
--mod start 1.5
       ,NVL(slip.out_qty,0)                                   out_qty             --出庫数
--       ,ABS(NVL(slip.out_qty,0))                                   out_qty             --出庫数
--mod end 1.5
-- mod end 1.18
       ,xicv2.description                                     item_div_name       --品目区分名称
      FROM (
      --======================================================================================================
        ------------------------------
        -- 1.発注実績情報
        ------------------------------
        SELECT
          gv_trtry_po                                         territory           --領域(発注)
         ,ximv.item_id                                        item_id             --品目ID
         ,itp.lot_id                                          lot_id              --ロットID
         ,pha.attribute4                                      standard_date       --日付
         ,xrpm.new_div_invent                                 reason_code         --新区分
         ,pha.segment1                                        slip_no             --伝票No
         ,pha.attribute4                                      out_date            --出庫日
         ,pha.attribute4                                      in_date             --着日
         ,''                                                  jrsd_code           --管轄拠点コード
         ,''                                                  jrsd_name           --管轄拠点名
         ,xvv.segment1                                        other_code          --相手先コード
         ,xvv.vendor_name                                     other_name          --相手先名称
--mod start 1.15
--         ,SUM(TO_NUMBER(NVL(pla.attribute7,'0')))             in_qty              --入庫数
         ,SUM(NVL(pla.quantity,0))                            in_qty              --入庫数
--mod end 1.15
         ,0                                                   out_qty             --出庫数
         ,itp.whse_code                                       whse_code           --倉庫コード
         ,xilv.whse_name                                      whse_name           --倉庫名
         ,itp.location                                        location            --保管倉庫コード
         ,xilv.description                                    description         --保管倉庫名
         ,xilv.distribution_block                             distribution_block  --ブロック
         ,xrpm.rcv_pay_div                                    rcv_pay_div         --受払区分
        FROM
        ----------------------------------------------------------------------------------------
          po_headers_all                                      pha                 --発注ヘッダ
         ,po_lines_all                                        pla                 --発注明細
         ,rcv_shipment_lines                                  rsl                 --受入明細
         ,rcv_transactions                                    rt                  --受入取引
         ,ic_lots_mst                                         ilm                 --OPMロットマスタ(結合用)
         ,xxpo_rcv_and_rtn_txns                               xrart               --受入返品実績
         ,xxcmn_vendors2_v                                    xvv                 --仕入先情報VIEW2
         ,xxcmn_item_locations2_v                             xilv                --保管場所情報VIEW2
         ,mtl_system_items_b                                  msib                --品目マスタ
         ,xxcmn_item_mst_v                                    ximv                --OPM品目情報VIEW1(結合用)
         ,ic_tran_pnd                                         itp                 --OPM保留在庫トランザクション
         ,xxcmn_rcv_pay_mst                                   xrpm                --受入区分アドオンマスタ
        ----------------------------------------------------------------------------------------
        --発注ヘッダ抽出条件
        WHERE pha.attribute1 IN (gv_po_sts_rcv, gv_po_sts_qty_deci, gv_po_sts_price_deci)--ステータス
        AND pha.attribute4 BETWEEN civ_ymd_from AND civ_ymd_to                    --納入日
        --発注明細抽出条件
        AND pha.po_header_id = pla.po_header_id                                   --発注ヘッダID
        AND pla.attribute13 = gv_po_flg_qty                                       --数量確定フラグ
        --受入明細抽出条件
        AND rsl.po_header_id = pha.po_header_id                                   --発注ヘッダID
        AND rsl.po_line_id = pla.po_line_id                                       --発注明細ID
        --受入取引抽出条件
        AND rsl.shipment_line_id = rt.shipment_line_id                            --受入明細ID
        --品目マスタ抽出条件
        AND msib.organization_id = FND_PROFILE.VALUE(gv_prf_mst_org)              --組織ID
        AND pla.item_id = msib.inventory_item_id                                  --品目ID
        --OPM品目情報VIEW抽出条件
        AND msib.segment1 = ximv.item_no                                          --品目コード
        --OPMロットマスタ抽出条件
        AND ilm.item_id = ximv.item_id                                            --品目ID
        AND ( 
                pla.attribute1 = ilm.lot_no                                       --ロットNo
          OR (
                pla.attribute1 IS NULL
          )
        )
        --受入返品実績抽出条件
        AND pha.segment1 = xrart.source_document_number                           --元文書番号
        AND pla.line_num = xrart.source_document_line_num                         --元文書明細番号
        AND xrart.txns_type = gv_txns_type_rcv                                    --実績区分
        --保管場所マスタVIEW抽出条件
        AND pha.attribute5 = xilv.segment1                                        --納入場所
        AND TO_DATE(civ_ymd_from,gv_fmt_ymd)
--mod start 1.3
--          BETWEEN TRUNC(xilv.date_from) AND NVL(TRUNC(xilv.date_to),TO_DATE(civ_ymd_from,gv_fmt_ymd))
          BETWEEN xilv.date_from AND NVL(xilv.date_to,TO_DATE(civ_ymd_from,gv_fmt_ymd))
--mod end 1.3
        --仕入先情報VIEW抽出条件
        AND pha.vendor_id = xvv.vendor_id                                         --仕入先ID
        AND TO_DATE(civ_ymd_from,gv_fmt_ymd)
--mod start 1.3
--          BETWEEN TRUNC(xvv.start_date_active) AND TRUNC(xvv.end_date_active)     --適用開始日・終了日
          BETWEEN xvv.start_date_active AND xvv.end_date_active                   --適用開始日・終了日
--mod end 1.3
        --OPM保留在庫トランザクション抽出条件
        AND itp.doc_type = 'PORC'                                                 --文書タイプ
        AND rsl.shipment_header_id = itp.doc_id                                   --文書ID
        AND rsl.line_num = itp.doc_line                                           --取引明細番号
        AND rt.transaction_id = itp.line_id                                       --ラインID
        AND ximv.item_id = itp.item_id                                            --品目ID
        AND ilm.lot_id = itp.lot_id                                               --ロットID
        AND xilv.segment1 = itp.location                                          --保管倉庫コード
        AND itp.completed_ind = gv_tran_cmp                                       --完了フラグ
        --受払区分マスタアドオン抽出条件
        AND xrpm.doc_type = 'PORC'                                                --文書タイプ
        AND xrpm.source_document_code = 'PO'                                      --ソース文書
        AND xrpm.transaction_type = rt.transaction_type                           --PO取引タイプ
        AND xrpm.use_div_invent = gv_inventory                                    --在庫使用区分
        ----------------------------------------------------------------------------------------
        GROUP BY
          ximv.item_id                                                            --品目ID
         ,itp.lot_id                                                              --ロットID
         ,pha.attribute4                                                          --日付
         ,xrpm.new_div_invent                                                     --新区分
         ,pha.segment1                                                            --伝票No
         ,pha.attribute4                                                          --出庫日/着日
         ,xvv.segment1                                                            --相手先コード
         ,xvv.vendor_name                                                         --相手先名称
         ,itp.whse_code                                                           --倉庫コード
         ,xilv.whse_name                                                          --倉庫名
         ,itp.location                                                            --保管倉庫コード
         ,xilv.description                                                        --保管倉庫名
         ,xilv.distribution_block                                                 --ブロック
         ,xrpm.rcv_pay_div                                                        --受払区分
         ,xrpm.transaction_type                                                   --PO取引タイプ
        UNION ALL
        ------------------------------
        -- 2.移動実績情報
        ------------------------------
        SELECT
          gv_trtry_mv                                         territory           --領域(移動)
         ,ximv.item_id                                        item_id             --品目ID
         ,xm.lot_id                                           lot_id              --ロットID
         ,CASE civ_base_date --パラメータ.基準
            WHEN gv_base_date_arrival THEN TO_CHAR(xm.actual_arrival_date,gv_fmt_ymd) --着日基準:入庫実績日
            WHEN gv_base_date_ship THEN TO_CHAR(xm.actual_ship_date,gv_fmt_ymd)       --発日基準:出庫実績日
            ELSE NULL
          END                                                 standard_date       --日付
--mod start 1.2
--         ,xrpm.new_div_invent                                 reason_code         --新区分
         ,xm.new_div_invent                                   reason_code         --新区分
--mod end 1.2
         ,xm.mov_num                                          slip_no             --伝票No
         ,TO_CHAR(xm.actual_ship_date,gv_fmt_ymd)             out_date            --出庫日
         ,TO_CHAR(xm.actual_arrival_date,gv_fmt_ymd)          in_date             --入庫日
         ,''                                                  jrsd_code           --管轄拠点コード
         ,''                                                  jrsd_name           --管轄拠点名
         ,xm.other_code                                       other_code          --相手先コード
         ,xilv2.description                                   other_name          --相手先名称
         ,CASE xm.record_type
            WHEN gv_rectype_in THEN
--mod start 1.2
--              SUM(CASE ximv.lot_ctl --ロット管理区分
--                WHEN gn_lotctl_yes THEN xm.actual_quantity --ロット管理品
--                WHEN gn_lotctl_no THEN xm.ship_to_quantity --非ロット管理品
--                ELSE 0
--              END)
              SUM(NVL(xm.trans_qty,0))
--mod end 1.2
            ELSE 0 END                                        in_qty              --入庫数
         ,CASE xm.record_type
            WHEN gv_rectype_out THEN
--mod start 1.2
--              SUM(CASE ximv.lot_ctl --ロット管理区分
--                WHEN gn_lotctl_yes THEN xm.actual_quantity --ロット管理品
--                WHEN gn_lotctl_no THEN xm.shipped_quantity --非ロット管理品
--                ELSE 0
--              END)
-- mod start 1.18
--              SUM(NVL(xm.trans_qty,0)) * -1
              ABS(SUM(NVL(xm.trans_qty,0)) * -1)
-- mod end 1.18
--mod end 1.2
            ELSE 0 END                                                out_qty             --出庫数
         ,CASE xm.mov_type --移動タイプ
            WHEN gv_movetype_yes THEN xm.whse_code --積送あり
            WHEN gv_movetype_no THEN xm.whse_code --積送なし
            ELSE NULL
          END                                                 whse_code           --倉庫コード
         ,xilv.whse_name                                      whse_name           --倉庫名
         ,CASE xm.mov_type --移動タイプ
            WHEN gv_movetype_yes THEN xm.location --積送あり
            WHEN gv_movetype_no THEN xm.location --積送なし
            ELSE NULL
          END                                                 location            --保管倉庫コード
         ,xilv.description                                    description         --保管倉庫名
         ,xilv.distribution_block                             distribution_block  --ブロック
--mod start 1.2
--         ,xrpm.rcv_pay_div                                    rcv_pay_div         --受払区分
         ,xm.rcv_pay_div                                      rcv_pay_div         --受払区分
--mod end 1.2
       FROM
        (
-------------------------------------------------------------------------------------------------------------------
          --積送あり
          SELECT
          xmrih.mov_hdr_id                                mov_hdr_id              --移動ヘッダID
         ,xmrih.record_type                               record_type             --レコードタイプ
         ,xmrih.comp_actual_flg                           comp_actual_flg         --実績計上済フラグ
         ,xmrih.mov_type                                  mov_type                --移動タイプ
         ,xmrih.mov_num                                   mov_num                 --移動番号
         ,xmrih.arvl_ship_date                            arvl_ship_date          --実績日(出庫実績日)
         ,xmrih.locat_id                                  locat_id                --保管倉庫ID(出庫元ID)
         ,xmrih.locat_code                                locat_code              --保管倉庫コード(出庫元保管場所)
         ,xmrih.arvl_ship_date2                           arvl_ship_date2         --実績日(入庫実績日)
         ,xmrih.other_id                                  other_id                --相手先ID(入庫先ID)
         ,xmrih.other_code                                other_code              --相手先(入庫先保管場所)
         ,xmrih.actual_arrival_date                       actual_arrival_date     --入庫実績日
         ,xmrih.actual_ship_date                          actual_ship_date        --出庫実績日
         ,xmril.item_id                                   item_id                 --品目ID
         ,xmril.delete_flg                                delete_flg              --取消フラグ
         ,xmril.ship_to_quantity                          ship_to_quantity        --入庫実績数量
         ,xmril.shipped_quantity                          shipped_quantity        --出庫実績数量
         ,xmld.document_type_code                         document_type_code      --文書タイプ
         ,xmld.actual_date                                actual_date             --実績日
         ,xmld.lot_id                                     lot_id                  --ロットID
         ,xmld.actual_quantity                            actual_quantity         --実績数量
         ,xilv.segment1                                   segment1                --保管場所コード
         ,itp.doc_type                                    doc_type                --文書タイプ
         ,itp.trans_qty                                   trans_qty               --数量
         ,itp.whse_code                                   whse_code               --倉庫コード
         ,itp.location                                    location                --保管倉庫コード
--add start 1.2
         ,xmrih.new_div_invent                            new_div_invent          --新区分
         ,xmrih.rcv_pay_div                               rcv_pay_div             --受払区分
--add end 1.2
          FROM
          (
            --出庫実績情報
            SELECT
              xmrih.mov_hdr_id                                mov_hdr_id          --移動ヘッダID
             ,xmrih.comp_actual_flg                           comp_actual_flg     --実績計上済フラグ
             ,xmrih.mov_type                                  mov_type            --移動タイプ
             ,xmrih.mov_num                                   mov_num             --移動番号
             ,xmrih.actual_ship_date                          arvl_ship_date      --実績日(出庫実績日)
             ,xmrih.shipped_locat_id                          locat_id            --保管倉庫ID(出庫元ID)
             ,xmrih.shipped_locat_code                        locat_code          --保管倉庫コード(出庫元保管場所)
             ,xmrih.actual_arrival_date                       arvl_ship_date2     --実績日(入庫実績日)
             ,xmrih.ship_to_locat_id                          other_id            --相手先ID(入庫先ID)
             ,xmrih.ship_to_locat_code                        other_code          --相手先(入庫先保管場所)
             ,xmrih.actual_arrival_date                       actual_arrival_date --入庫実績日
             ,xmrih.actual_ship_date                          actual_ship_date    --出庫実績日
             ,gv_rectype_out                                  record_type         --レコードタイプ(出庫実績)
--add start 1.2
             ,gv_newdiv_pay                                   new_div_invent      --新区分
             ,gv_rcvdiv_pay                                   rcv_pay_div         --受払区分
--add end 1.2
            FROM
              xxinv_mov_req_instr_headers                     xmrih               --移動依頼/指示ヘッダ(アドオン)
            --移動依頼/指示ヘッダ(アドオン)抽出条件
            WHERE xmrih.mov_type = gv_movetype_yes                                --移動タイプ(積送あり)
            UNION ALL
            --入庫実績情報
            SELECT
              xmrih.mov_hdr_id                                mov_hdr_id          --移動ヘッダID
             ,xmrih.comp_actual_flg                           comp_actual_flg     --実績計上済フラグ
             ,xmrih.mov_type                                  mov_type            --移動タイプ
             ,xmrih.mov_num                                   mov_num             --移動番号
             ,xmrih.actual_arrival_date                       arvl_ship_date      --実績日(入庫実績日)
             ,xmrih.ship_to_locat_id                          locat_id            --保管倉庫ID(入庫先ID)
             ,xmrih.ship_to_locat_code                        locat_code          --保管倉庫コード(入庫先保管場所)
             ,xmrih.actual_ship_date                          arvl_ship_date2     --実績日(出庫実績日)
             ,xmrih.shipped_locat_id                          other_id            --相手先ID(出庫元ID)
             ,xmrih.shipped_locat_code                        other_code          --相手先(出庫元保管場所)
             ,xmrih.actual_arrival_date                       actual_arrival_date --入庫実績日
             ,xmrih.actual_ship_date                          actual_ship_date    --出庫実績日
             ,gv_rectype_in                                   record_type         --レコードタイプ(入庫実績)
--add start 1.2
             ,gv_newdiv_rcv                                   new_div_invent      --新区分
             ,gv_rcvdiv_rcv                                   rcv_pay_div         --受払区分
--add end 1.2
            FROM
              xxinv_mov_req_instr_headers                     xmrih               --移動依頼/指示ヘッダ(アドオン)
            --移動依頼/指示ヘッダ(アドオン)抽出条件
            WHERE xmrih.mov_type = gv_movetype_yes                                --移動タイプ(積送あり)
          ) xmrih
         ,xxinv_mov_req_instr_lines                           xmril               --移動依頼/指示明細(アドオン)
         ,xxinv_mov_lot_details                               xmld                --移動ロット詳細(アドオン)
         ,xxcmn_item_locations2_v                             xilv                --OPM保管場所情報VIEW2
         ,ic_xfer_mst                                         ixm                 --OPM在庫転送マスタ
         ,ic_tran_pnd                                         itp                 --OPM保留在庫トランザクション
         --移動依頼/指示明細(アドオン)抽出条件
         WHERE xmrih.mov_hdr_id = xmril.mov_hdr_id                                --移動ヘッダID
         --移動ロット詳細(アドオン)抽出条件
--mod start 1.2
--         AND xmld.mov_line_id(+) = xmril.mov_line_id                              --移動明細ID
--         AND ( xmld.mov_line_id IS NOT NULL
--           AND xmld.document_type_code = gv_dctype_move                           --文書タイプ
--         OR    xmld.mov_line_id IS NULL
--         )
--         AND  (xmld.mov_line_id IS NOT NULL
--           AND xmrih.record_type = xmld.record_type_code                          --レコードタイプ
--         OR    xmld.mov_line_id IS NULL
--         )
         AND xmld.mov_line_id = xmril.mov_line_id                                 --移動明細ID
         AND xmld.document_type_code = gv_dctype_move                             --文書タイプ
         AND xmld.record_type_code = xmrih.record_type                            --レコードタイプ
--mod end 1.2
         --OPM保管場所情報VIEW2抽出条件
         AND xmrih.locat_id = xilv.inventory_location_id                          --保管倉庫ID
         AND xmrih.arvl_ship_date
           BETWEEN xilv.date_from AND NVL(xilv.date_to,xmrih.arvl_ship_date)      --適用開始日・終了日
         --OPM在庫転送マスタ抽出条件
         AND xmril.mov_line_id = ixm.attribute1                                   --文書ソースID
         --OPM保留在庫トランザクション抽出条件
         AND itp.doc_type = 'XFER'                                                --文書タイプ
         AND ixm.transfer_id = itp.doc_id                                         --文書ID
         AND xmril.item_id = itp.item_id                                          --品目ID
         AND ( xmld.lot_id IS NOT NULL 
           AND xmld.lot_id = itp.lot_id                                           --ロットID
         OR    xmld.lot_id IS NULL
         )
         AND xilv.segment1 = itp.location                                         --保管倉庫コード
         AND itp.completed_ind = gv_tran_cmp                                      --完了フラグ　
--add start 1.2
--add start 1.16
         AND NOT EXISTS (                                                         --同一倉庫内の移動情報は対象外とする
             SELECT COUNT(*)
             FROM ic_tran_pnd itp2                                                --OPM保留在庫トランザクション
             WHERE itp.doc_id = itp2.doc_id                                       --文書ID
             AND   itp.whse_code = itp2.whse_code                                 --倉庫コード
             GROUP BY itp2.doc_id
                     ,itp2.whse_code
             HAVING COUNT(*) > 1
             )
--add end 1.16
        UNION ALL
          --積送あり(ADJI)
          SELECT
          xmrih.mov_hdr_id                                mov_hdr_id              --移動ヘッダID
         ,xmrih.record_type                               record_type             --レコードタイプ
         ,xmrih.comp_actual_flg                           comp_actual_flg         --実績計上済フラグ
         ,xmrih.mov_type                                  mov_type                --移動タイプ
         ,xmrih.mov_num                                   mov_num                 --移動番号
         ,xmrih.arvl_ship_date                            arvl_ship_date          --実績日(出庫実績日)
         ,xmrih.locat_id                                  locat_id                --保管倉庫ID(出庫元ID)
         ,xmrih.locat_code                                locat_code              --保管倉庫コード(出庫元保管場所)
         ,xmrih.arvl_ship_date2                           arvl_ship_date2         --実績日(入庫実績日)
         ,xmrih.other_id                                  other_id                --相手先ID(入庫先ID)
         ,xmrih.other_code                                other_code              --相手先(入庫先保管場所)
         ,xmrih.actual_arrival_date                       actual_arrival_date     --入庫実績日
         ,xmrih.actual_ship_date                          actual_ship_date        --出庫実績日
         ,xmril.item_id                                   item_id                 --品目ID
         ,xmril.delete_flg                                delete_flg              --取消フラグ
         ,xmril.ship_to_quantity                          ship_to_quantity        --入庫実績数量
         ,xmril.shipped_quantity                          shipped_quantity        --出庫実績数量
         ,xmld.document_type_code                         document_type_code      --文書タイプ
         ,xmld.actual_date                                actual_date             --実績日
         ,xmld.lot_id                                     lot_id                  --ロットID
         ,xmld.actual_quantity                            actual_quantity         --実績数量
         ,xilv.segment1                                   segment1                --保管場所コード
         ,itc.doc_type                                    doc_type                --文書タイプ
         ,itc.trans_qty                                   trans_qty               --数量
         ,itc.whse_code                                   whse_code               --倉庫コード
         ,itc.location                                    location                --保管倉庫コード
         ,xmrih.new_div_invent                            new_div_invent          --新区分
         ,xmrih.rcv_pay_div                               rcv_pay_div             --受払区分
          FROM
          (
            --出庫実績情報
            SELECT
              xmrih.mov_hdr_id                                mov_hdr_id          --移動ヘッダID
             ,xmrih.comp_actual_flg                           comp_actual_flg     --実績計上済フラグ
             ,xmrih.mov_type                                  mov_type            --移動タイプ
             ,xmrih.mov_num                                   mov_num             --移動番号
             ,xmrih.actual_ship_date                          arvl_ship_date      --実績日(出庫実績日)
             ,xmrih.shipped_locat_id                          locat_id            --保管倉庫ID(出庫元ID)
             ,xmrih.shipped_locat_code                        locat_code          --保管倉庫コード(出庫元保管場所)
             ,xmrih.actual_arrival_date                       arvl_ship_date2     --実績日(入庫実績日)
             ,xmrih.ship_to_locat_id                          other_id            --相手先ID(入庫先ID)
             ,xmrih.ship_to_locat_code                        other_code          --相手先(入庫先保管場所)
             ,xmrih.actual_arrival_date                       actual_arrival_date --入庫実績日
             ,xmrih.actual_ship_date                          actual_ship_date    --出庫実績日
             ,gv_rectype_out                                  record_type         --レコードタイプ(出庫実績)
             ,gv_newdiv_pay                                   new_div_invent      --新区分
             ,gv_rcvdiv_pay                                   rcv_pay_div         --受払区分
            FROM
              xxinv_mov_req_instr_headers                     xmrih               --移動依頼/指示ヘッダ(アドオン)
--add start 1.16
             ,xxcmn_item_locations2_v                         xilv_locat          --OPM保管場所情報VIEW2(保管倉庫の倉庫コード取得用)
             ,xxcmn_item_locations2_v                         xilv_other          --OPM保管場所情報VIEW2(相手先の倉庫コード取得用)
--add end 1.16
            --移動依頼/指示ヘッダ(アドオン)抽出条件
            WHERE xmrih.mov_type = gv_movetype_yes                                --移動タイプ(積送あり)
--add start 1.16
            --OPM保管場所情報VIEW2(保管倉庫)抽出条件
            AND xmrih.shipped_locat_id = xilv_locat.inventory_location_id                        --保管倉庫ID
            AND xmrih.actual_ship_date
              BETWEEN xilv_locat.date_from AND NVL(xilv_locat.date_to,xmrih.actual_ship_date)    --適用開始日・終了日
            --OPM保管場所情報VIEW2(相手先)抽出条件
            AND xmrih.ship_to_locat_id = xilv_other.inventory_location_id                        --保管倉庫ID
            AND xmrih.actual_arrival_date
              BETWEEN xilv_other.date_from AND NVL(xilv_other.date_to,xmrih.actual_arrival_date) --適用開始日・終了日
            AND xilv_locat.whse_code <> xilv_other.whse_code                      --同一倉庫内の移動情報は対象外とする
--add end 1.16
            UNION ALL
            --入庫実績情報
            SELECT
              xmrih.mov_hdr_id                                mov_hdr_id          --移動ヘッダID
             ,xmrih.comp_actual_flg                           comp_actual_flg     --実績計上済フラグ
             ,xmrih.mov_type                                  mov_type            --移動タイプ
             ,xmrih.mov_num                                   mov_num             --移動番号
             ,xmrih.actual_arrival_date                       arvl_ship_date      --実績日(入庫実績日)
             ,xmrih.ship_to_locat_id                          locat_id            --保管倉庫ID(入庫先ID)
             ,xmrih.ship_to_locat_code                        locat_code          --保管倉庫コード(入庫先保管場所)
             ,xmrih.actual_ship_date                          arvl_ship_date2     --実績日(出庫実績日)
             ,xmrih.shipped_locat_id                          other_id            --相手先ID(出庫元ID)
             ,xmrih.shipped_locat_code                        other_code          --相手先(出庫元保管場所)
             ,xmrih.actual_arrival_date                       actual_arrival_date --入庫実績日
             ,xmrih.actual_ship_date                          actual_ship_date    --出庫実績日
             ,gv_rectype_in                                   record_type         --レコードタイプ(入庫実績)
             ,gv_newdiv_rcv                                   new_div_invent      --新区分
             ,gv_rcvdiv_rcv                                   rcv_pay_div         --受払区分
            FROM
              xxinv_mov_req_instr_headers                     xmrih               --移動依頼/指示ヘッダ(アドオン)
--add start 1.16
             ,xxcmn_item_locations2_v                         xilv_locat          --OPM保管場所情報VIEW2(保管倉庫の倉庫コード取得用)
             ,xxcmn_item_locations2_v                         xilv_other          --OPM保管場所情報VIEW2(相手先の倉庫コード取得用)
--add end 1.16
            --移動依頼/指示ヘッダ(アドオン)抽出条件
            WHERE xmrih.mov_type = gv_movetype_yes                                --移動タイプ(積送あり)
--add start 1.16
            --OPM保管場所情報VIEW2(保管倉庫)抽出条件
            AND xmrih.ship_to_locat_id = xilv_locat.inventory_location_id                        --保管倉庫ID
            AND xmrih.actual_arrival_date
              BETWEEN xilv_locat.date_from AND NVL(xilv_locat.date_to,xmrih.actual_arrival_date) --適用開始日・終了日
            --OPM保管場所情報VIEW2(相手先)抽出条件
            AND xmrih.shipped_locat_id = xilv_other.inventory_location_id                        --保管倉庫ID
            AND xmrih.actual_ship_date
              BETWEEN xilv_other.date_from AND NVL(xilv_other.date_to,xmrih.actual_ship_date)    --適用開始日・終了日
            AND xilv_locat.whse_code <> xilv_other.whse_code                      --同一倉庫内の移動情報は対象外とする
--add end 1.16
          ) xmrih
         ,xxinv_mov_req_instr_lines                           xmril               --移動依頼/指示明細(アドオン)
         ,xxinv_mov_lot_details                               xmld                --移動ロット詳細(アドオン)
         ,xxcmn_item_locations2_v                             xilv                --OPM保管場所情報VIEW2
         ,ic_jrnl_mst                                         ijm                 --OPMジャーナルマスタ
         ,ic_adjs_jnl                                         iaj                 --OPM在庫調整ジャーナル
         ,ic_tran_cmp                                         itc                 --OPM完了在庫トランザクション
         --移動依頼/指示明細(アドオン)抽出条件
         WHERE xmrih.mov_hdr_id = xmril.mov_hdr_id                                --移動ヘッダID
         --移動ロット詳細(アドオン)抽出条件
--mod start 1.2
--         AND xmld.mov_line_id(+) = xmril.mov_line_id                              --移動明細ID
--         AND ( xmld.mov_line_id IS NOT NULL
--           AND xmld.document_type_code = gv_dctype_move                           --文書タイプ
--         OR    xmld.mov_line_id IS NULL
--         )
--         AND  (xmld.mov_line_id IS NOT NULL
--           AND xmrih.record_type = xmld.record_type_code                          --レコードタイプ
--         OR    xmld.mov_line_id IS NULL
--         )
         AND xmld.mov_line_id = xmril.mov_line_id                                 --移動明細ID
         AND xmld.document_type_code = gv_dctype_move                             --文書タイプ
         AND xmld.record_type_code = xmrih.record_type                            --レコードタイプ
--mod end 1.2
         --OPM保管場所情報VIEW2抽出条件
         AND xmrih.locat_id = xilv.inventory_location_id                          --保管倉庫ID
         AND xmrih.arvl_ship_date
           BETWEEN xilv.date_from AND NVL(xilv.date_to,xmrih.arvl_ship_date)      --適用開始日・終了日
         --OPMジャーナルマスタ抽出条件
         AND xmril.mov_line_id = ijm.attribute1                                   --文書ソースID
         --OPM在庫調整ジャーナル
         AND ijm.journal_id = iaj.journal_id                                      --ジャーナルID
         AND xilv.segment1 = iaj.location                                         --保管倉庫コード
         --OPM完了在庫トランザクション抽出条件
         AND itc.doc_type = 'ADJI'                                                --文書タイプ
         AND itc.doc_id = iaj.doc_id                                              --文書ID
         AND itc.doc_line = iaj.doc_line                                          --取引明細番号
         AND xmril.item_id = itc.item_id                                          --品目ID
         AND ( xmld.lot_id IS NOT NULL 
           AND xmld.lot_id = itc.lot_id                                           --ロットID
         OR    xmld.lot_id IS NULL
         )
--add end 1.2
-------------------------------------------------------------------------------------------------------------------
         UNION ALL
          --積送なし
         SELECT
          xmrih.mov_hdr_id                                mov_hdr_id              --移動ヘッダID
         ,xmrih.record_type                               record_type             --レコードタイプ
         ,xmrih.comp_actual_flg                           comp_actual_flg         --実績計上済フラグ
         ,xmrih.mov_type                                  mov_type                --移動タイプ
         ,xmrih.mov_num                                   mov_num                 --移動番号
         ,xmrih.arvl_ship_date                            arvl_ship_date          --実績日(出庫実績日)
         ,xmrih.locat_id                                  locat_id                --保管倉庫ID(出庫元ID)
         ,xmrih.locat_code                                locat_code              --保管倉庫コード(出庫元保管場所)
         ,xmrih.arvl_ship_date2                           arvl_ship_date2         --実績日(入庫実績日)
         ,xmrih.other_id                                  other_id                --相手先ID(入庫先ID)
         ,xmrih.other_code                                other_code              --相手先(入庫先保管場所)
         ,xmrih.actual_arrival_date                       actual_arrival_date     --入庫実績日
         ,xmrih.actual_ship_date                          actual_ship_date        --出庫実績日
         ,xmril.item_id                                   item_id                 --品目ID
         ,xmril.delete_flg                                delete_flg              --取消フラグ
         ,xmril.ship_to_quantity                          ship_to_quantity        --入庫実績数量
         ,xmril.shipped_quantity                          shipped_quantity        --出庫実績数量
         ,xmld.document_type_code                         document_type_code      --文書タイプ
         ,xmld.actual_date                                actual_date             --実績日
         ,xmld.lot_id                                     lot_id                  --ロットID
         ,xmld.actual_quantity                            actual_quantity         --実績数量
         ,xilv.segment1                                   segment1                --保管場所コード
         ,itc.doc_type                                    doc_type                --文書タイプ
         ,itc.trans_qty                                   trans_qty               --数量
         ,itc.whse_code                                   whse_code               --倉庫コード
         ,itc.location                                    location                --保管倉庫コード
--add start 1.2
         ,xmrih.new_div_invent                            new_div_invent          --新区分
         ,xmrih.rcv_pay_div                               rcv_pay_div             --受払区分
--add end 1.2
         FROM
          (
            --出庫実績情報
            SELECT
              xmrih.mov_hdr_id                            mov_hdr_id              --移動ヘッダID
             ,xmrih.comp_actual_flg                       comp_actual_flg         --実績計上済フラグ
             ,xmrih.mov_type                              mov_type                --移動タイプ
             ,xmrih.mov_num                               mov_num                 --移動番号
             ,xmrih.actual_ship_date                      arvl_ship_date          --実績日(出庫実績日)
             ,xmrih.shipped_locat_id                      locat_id                --保管倉庫ID(出庫元ID)
             ,xmrih.shipped_locat_code                    locat_code              --保管倉庫コード(出庫元保管場所)
             ,xmrih.actual_arrival_date                   arvl_ship_date2         --実績日(入庫実績日)
             ,xmrih.ship_to_locat_id                      other_id                --相手先ID(入庫先ID)
             ,xmrih.ship_to_locat_code                    other_code              --相手先(入庫先保管場所)
             ,xmrih.actual_arrival_date                   actual_arrival_date     --入庫実績日
             ,xmrih.actual_ship_date                      actual_ship_date        --出庫実績日
             ,gv_rectype_out                              record_type             --レコードタイプ(出庫実績)
--add start 1.2
             ,gv_newdiv_pay                               new_div_invent          --新区分
             ,gv_rcvdiv_pay                               rcv_pay_div             --受払区分
--add end 1.2
            FROM
              xxinv_mov_req_instr_headers                 xmrih                   --移動依頼/指示ヘッダ(アドオン)
            --移動依頼/指示ヘッダ(アドオン)抽出条件
            WHERE xmrih.mov_type = gv_movetype_no                                 --移動タイプ(積送なし)
            UNION ALL
            --入庫実績情報
            SELECT
              xmrih.mov_hdr_id                            mov_hdr_id              --移動ヘッダID
             ,xmrih.comp_actual_flg                       comp_actual_flg         --実績計上済フラグ
             ,xmrih.mov_type                              mov_type                --移動タイプ
             ,xmrih.mov_num                               mov_num                 --移動番号
             ,xmrih.actual_arrival_date                   arvl_ship_date          --実績日(入庫実績日)
             ,xmrih.ship_to_locat_id                      locat_id                --保管倉庫ID(入庫先ID)
             ,xmrih.ship_to_locat_code                    locat_code              --保管倉庫コード(入庫先保管場所)
             ,xmrih.actual_ship_date                      arvl_ship_date2         --実績日(出庫実績日)
             ,xmrih.shipped_locat_id                      other_id                --相手先ID(出庫元ID)
             ,xmrih.shipped_locat_code                    other_code              --相手先(出庫元保管場所)
             ,xmrih.actual_arrival_date                   actual_arrival_date     --入庫実績日
             ,xmrih.actual_ship_date                      actual_ship_date        --出庫実績日
             ,gv_rectype_in                               record_type             --レコードタイプ(入庫実績)
--add start 1.2
             ,gv_newdiv_rcv                               new_div_invent          --新区分
             ,gv_rcvdiv_rcv                               rcv_pay_div             --受払区分
--add end 1.2
            FROM
              xxinv_mov_req_instr_headers                 xmrih                   --移動依頼/指示ヘッダ(アドオン)
            --移動依頼/指示ヘッダ(アドオン)抽出条件
            WHERE xmrih.mov_type = gv_movetype_no                                 --移動タイプ(積送なし)
          ) xmrih
         ,xxinv_mov_req_instr_lines                       xmril                   --移動依頼/指示明細(アドオン)
         ,xxinv_mov_lot_details                           xmld                    --移動ロット詳細(アドオン)
         ,xxcmn_item_locations2_v                         xilv                    --OPM保管場所情報VIEW2
         ,ic_jrnl_mst                                     ijm                     --OPMジャーナルマスタ
         ,ic_adjs_jnl                                     iaj                     --OPM在庫調整ジャーナル
         ,ic_tran_cmp                                     itc                     --OPM完了在庫トランザクション
         --移動依頼/指示ヘッダ(アドオン)抽出条件
--mod start 1.3
--         WHERE TRUNC(xmrih.actual_ship_date) = TRUNC(xmrih.actual_arrival_date)   --出荷実績日＝入庫実績日
         WHERE xmrih.actual_ship_date = xmrih.actual_arrival_date                 --出荷実績日＝入庫実績日
--mod end 1.3
         --移動依頼/指示明細(アドオン)抽出条件
         AND xmrih.mov_hdr_id = xmril.mov_hdr_id                                  --移動ヘッダID
         --移動ロット詳細(アドオン)抽出条件
--mod start 1.2
--         AND xmld.mov_line_id(+) = xmril.mov_line_id                              --移動明細ID
--         AND ( xmld.mov_line_id IS NOT NULL
--           AND xmld.document_type_code = gv_dctype_move                           --文書タイプ
--         OR    xmld.mov_line_id IS NULL
--         )
--         AND  (xmld.mov_line_id IS NOT NULL
--           AND xmrih.record_type = xmld.record_type_code                          --レコードタイプ
--         OR    xmld.mov_line_id IS NULL
--         )
         AND xmld.mov_line_id = xmril.mov_line_id                                 --移動明細ID
         AND xmld.document_type_code = gv_dctype_move                             --文書タイプ
         AND xmld.record_type_code = xmrih.record_type                            --レコードタイプ
--mod end 1.2
         --OPM保管場所情報VIEW2抽出条件
         AND xmrih.locat_id = xilv.inventory_location_id                          --保管倉庫ID
         AND xmrih.arvl_ship_date
           BETWEEN xilv.date_from AND NVL(xilv.date_to,xmrih.arvl_ship_date)      --適用開始日・終了日
         --OPMジャーナルマスタ抽出条件
         AND xmril.mov_line_id = ijm.attribute1                                   --文書ソースID
         --OPM在庫調整ジャーナル
         AND ijm.journal_id = iaj.journal_id                                      --ジャーナルID
         AND xilv.segment1 = iaj.location                                         --保管倉庫コード
         --OPM完了在庫トランザクション抽出条件
--mod start 1.2
--         AND itc.doc_type = 'TRNI'                                                --文書タイプ
         AND itc.doc_type IN ('TRNI','ADJI')                                      --文書タイプ
--mod end 1.2
         AND itc.doc_id = iaj.doc_id                                              --文書ID
         AND itc.doc_line = iaj.doc_line                                          --取引明細番号
         AND xmril.item_id = itc.item_id                                          --品目ID
         AND ( xmld.lot_id IS NOT NULL 
           AND xmld.lot_id = itc.lot_id                                           --ロットID
         OR    xmld.lot_id IS NULL
         )
         AND NOT EXISTS (                                                         --同一倉庫内の移動情報は対象外とする
             SELECT COUNT(*)
             FROM ic_tran_cmp itc2                                                --OPM完了在庫トランザクション
             WHERE itc.doc_id = itc2.doc_id                                       --文書ID
             AND   itc.whse_code = itc2.whse_code                                 --倉庫コード
             GROUP BY itc2.doc_id
                     ,itc2.whse_code
             HAVING COUNT(*) > 1
             )
         )                                                    xm                  --移動情報
         ,xxcmn_item_mst2_v                                   ximv                --OPM品目情報VIEW2(結合用)
         ,xxcmn_item_locations2_v                             xilv                --OPM保管場所情報VIEW2
         ,xxcmn_item_locations2_v                             xilv2               --OPM保管場所情報VIEW2(相手先)
         ,xxcmn_rcv_pay_mst                                   xrpm                --受入区分アドオンマスタ
        --移動情報抽出条件
        WHERE xm.comp_actual_flg = gv_cmp_actl_yes                                --実績計上フラグ
        AND xm.delete_flg = gv_delete_no                                          --削除フラグ
        --OPM保管場所情報VIEW2抽出条件
        AND xm.item_id = ximv.item_id                                             --品目ID
        AND xm.arvl_ship_date 
          BETWEEN ximv.start_date_active AND ximv.end_date_active                 --実績日
        --OPM保管場所情報VIEW2抽出条件
        AND xm.locat_id = xilv.inventory_location_id                              --保管倉庫ID
        AND xm.arvl_ship_date
          BETWEEN xilv.date_from AND NVL(xilv.date_to,xm.arvl_ship_date)          --適用開始日・終了日
        --OPM保管場所情報VIEW2(相手先)抽出条件
        AND xm.other_id = xilv2.inventory_location_id                             --保管倉庫ID(相手先)
        AND xm.arvl_ship_date
          BETWEEN xilv2.date_from AND NVL(xilv2.date_to,xm.arvl_ship_date)        --適用開始日・終了日
        --受払区分アドオンマスタ抽出条件
        AND xrpm.doc_type =xm.doc_type                                            --文書タイプ
        AND TO_CHAR(SIGN(xm.trans_qty)) = xrpm.rcv_pay_div                        --受払区分
        AND xrpm.use_div_invent = gv_inventory                                    --在庫使用区分
        AND xrpm.new_div_invent IN (gv_newdiv_pay,gv_newdiv_rcv)
        ------------------着日基準-------------------------
        AND ( civ_base_date = gv_base_date_arrival                                --着日基準の場合
--mod start 1.3
--          AND TRUNC(xm.actual_arrival_date)                                       --入庫実績日
          AND xm.actual_arrival_date                                              --入庫実績日
--mod end 1.3
            BETWEEN TO_DATE(civ_ymd_from,gv_fmt_ymd)
            AND TO_DATE(civ_ymd_to,gv_fmt_ymd)
        ------------------発日基準-------------------------
        OR    civ_base_date = gv_base_date_ship                                   --発日基準の場合
--mod start 1.3
--          AND TRUNC(xm.actual_ship_date)                                          --出荷実績日
          AND xm.actual_ship_date                                                 --出荷実績日
--mod end 1.3
            BETWEEN TO_DATE(civ_ymd_from,gv_fmt_ymd)
            AND TO_DATE(civ_ymd_to,gv_fmt_ymd)
        )
        ----------------------------------------------------------------------------------------
        GROUP BY 
          ximv.item_id                                                            --品目ID
         ,xm.lot_id                                                               --ロットID
--mod start 1.2
--         ,xrpm.new_div_invent                                                     --新区分
         ,xm.new_div_invent                                                       --新区分
--mod end 1.2
         ,xm.mov_num                                                              --伝票No
         ,xilv.description                                                        --保管倉庫名
         ,xm.mov_type                                                             --移動タイプ
         ,xm.whse_code                                                            --保留.倉庫コード
         ,xm.location                                                             --保留.保管倉庫コード
         ,xm.whse_code                                                            --完了.倉庫コード
         ,xm.location                                                             --完了.保管倉庫コード
         ,xilv.whse_name                                                          --倉庫名
         ,xilv.distribution_block                                                 --ブロック
--mod start 1.2
--         ,xrpm.rcv_pay_div                                                        --受払区分
         ,xm.rcv_pay_div                                                          --受払区分
--mod end 1.2
        ,TO_CHAR(xm.actual_arrival_date,gv_fmt_ymd)
        ,TO_CHAR(xm.actual_ship_date,gv_fmt_ymd)
        ,TO_CHAR(xm.arvl_ship_date,gv_fmt_ymd)
        ,xm.other_code
        ,xilv2.description
        ,ximv.lot_ctl
        ,xm.record_type
        UNION ALL
        ------------------------------
        -- 3.出荷/有償出荷実績情報
        ------------------------------
        SELECT
          gv_trtry_sh                                         territory           --領域(出荷)
         ,sh_info.item_id                                     item_id             --品目ID
         ,sh_info.lot_id                                      lot_id              --ロットID
         ,CASE civ_base_date --パラメータ.基準
--mod start 1.6
--            WHEN gv_base_date_arrival THEN TO_CHAR(xoha.arrival_date,gv_fmt_ymd) 
--            WHEN gv_base_date_ship THEN TO_CHAR(xoha.shipped_date,gv_fmt_ymd) 
            WHEN gv_base_date_arrival THEN TO_CHAR(sh_info.arrival_date,gv_fmt_ymd) 
            WHEN gv_base_date_ship THEN TO_CHAR(sh_info.shipped_date,gv_fmt_ymd) 
--mod end 1.6
            ELSE NULL
          END                                                 standard_date       --日付
         ,sh_info.new_div_invent                              reason_code         --新区分
--mod start 1.6
--         ,xoha.request_no                                     slip_no             --伝票No
--         ,TO_CHAR(xoha.shipped_date,gv_fmt_ymd)               out_date            --出庫日
--         ,TO_CHAR(xoha.arrival_date,gv_fmt_ymd)               in_date             --着日
--         ,xoha.head_sales_branch                              jrsd_code           --管轄拠点コード
         ,sh_info.request_no                                     slip_no             --伝票No
         ,TO_CHAR(sh_info.shipped_date,gv_fmt_ymd)               out_date            --出庫日
         ,TO_CHAR(sh_info.arrival_date,gv_fmt_ymd)               in_date             --着日
         ,sh_info.head_sales_branch                              jrsd_code           --管轄拠点コード
--mod end 1.6
         ,xcav.party_short_name                               jrsd_name           --管轄拠点名
--mod start 1.6
--         ,xoha.deliver_to                                     other_code          --相手先コード
         ,sh_info.deliver_to                                     other_code          --相手先コード
--mod end 1.6
--mod start 1.7
--         ,xpsv.party_site_full_name                           other_name          --相手先名称
         ,sh_info.party_site_full_name                           other_name          --相手先名称
--mod end 1.7
         ,CASE sh_info.rcv_pay_div--受払区分
            WHEN gv_rcvdiv_rcv THEN sh_info.trans_qty_sum
            ELSE 0
          END                                                 in_qty              --入庫数
         ,CASE sh_info.rcv_pay_div--受払区分
-- mod start 1.18
--            WHEN gv_rcvdiv_pay THEN sh_info.trans_qty_sum
            WHEN gv_rcvdiv_pay THEN ABS(sh_info.trans_qty_sum)
-- mod end 1.18
            ELSE 0
          END                                                 out_qty             --出庫数
         ,sh_info.whse_code                                   whse_code           --倉庫コード
         ,sh_info.whse_name                                   whse_name           --倉庫名
         ,sh_info.location                                    location            --保管倉庫コード
         ,sh_info.description                                 description         --保管倉庫名
         ,sh_info.distribution_block                          distribution_block  --ブロック
         ,sh_info.rcv_pay_div                                 rcv_pay_div         --受払区分
        ----------------------------------------------------------------------------------------
        FROM (
          SELECT
            oe_info.doc_type                                  doc_type            --文書タイプ
           ,oe_info.item_id                                   item_id             --品目ID
           ,oe_info.whse_code                                 whse_code           --倉庫コード
           ,xilv.whse_name                                    whse_name           --倉庫名
           ,oe_info.location                                  location            --保管倉庫コード
           ,xilv.description                                  description         --保管倉庫名
           ,xilv.inventory_location_id                        inventory_location_id   --保管倉庫ID
           ,oe_info.lot_id                                    lot_id              --ロットID
           ,oe_info.doc_id                                    doc_id              --文書ID
           ,oe_info.doc_line                                  doc_line            --取引明細番号
           ,oe_info.header_id                                 header_id           --受注ヘッダID
           ,oe_info.order_type_id                             order_type_id       --受注タイプID
           ,xrpm.rcv_pay_div                                  rcv_pay_div         --受払区分
           ,xrpm.new_div_invent                               new_div_invent      --新区分
           ,SUM(oe_info.trans_qty)                            trans_qty_sum       --数量合計
           ,xilv.distribution_block                           distribution_block  --ブロック
--add start 1.6
           ,xoha.head_sales_branch                            head_sales_branch
           ,xoha.deliver_to_id                                deliver_to_id
           ,DECODE(xoha.req_status,gv_recsts_shipped,xoha.result_deliver_to
                                  ,gv_recsts_shipped2,xoha.vendor_site_code
            ) deliver_to
           ,xoha.arrival_date                                 arrival_date
           ,xoha.shipped_date                                 shipped_date
           ,xoha.request_no                                   request_no
           ,DECODE(xoha.req_status,gv_recsts_shipped,xpsv.party_site_full_name
                                  ,gv_recsts_shipped2,xvsv.vendor_site_name
            ) party_site_full_name
--add end 1.6
          FROM
            ( --OMSO関連情報
              SELECT
                itp.doc_type                                  doc_type            --文書タイプ
               ,itp.item_id                                   item_id             --品目ID
               ,itp.whse_code                                 whse_code           --倉庫コード
               ,itp.location                                  location            --保管倉庫コード
               ,itp.lot_id                                    lot_id              --ロットID
               ,itp.doc_id                                    doc_id              --文書ID
               ,itp.doc_line                                  doc_line            --取引明細番号
               ,itp.trans_qty                                 trans_qty           --数量合計
               ,itp.trans_date                                trans_date          --トランザクション日付
               ,ooha.header_id                                header_id           --受注ヘッダID
               ,ooha.order_type_id                            order_type_id       --受注タイプID
              FROM
                ic_tran_pnd                                   itp                 --OPM保留在庫トランザクション
               ,wsh_delivery_details                          wdd                 --出荷搬送明細
               ,oe_order_headers_all                          ooha                --受注ヘッダ
              WHERE itp.doc_type = 'OMSO'
              AND itp.completed_ind = gv_tran_cmp                                 --完了フラグ
              AND itp.line_id = wdd.source_line_id                                --ソース明細ID
              AND wdd.org_id = ooha.org_id                                        --組織ID
              AND wdd.source_header_id = ooha.header_id                           --受注ヘッダID
              UNION ALL
              --PORC関連情報
              SELECT
                itp.doc_type                                      doc_type        --文書タイプ
               ,itp.item_id                                       item_id         --品目ID
               ,itp.whse_code                                     whse_code       --倉庫コード
               ,itp.location                                      location        --保管倉庫コード
               ,itp.lot_id                                        lot_id          --ロットID
               ,itp.doc_id                                        doc_id          --文書ID
               ,itp.doc_line                                      doc_line        --取引明細番号
               ,itp.trans_qty                                     trans_qty       --数量合計
               ,itp.trans_date                                trans_date          --トランザクション日付
               ,ooha.header_id                                    header_id       --受注ヘッダID
               ,ooha.order_type_id                                order_type_id   --受注タイプID
              FROM
                ic_tran_pnd                                       itp             --OPM保留在庫トランザクション
               ,rcv_shipment_lines                                rsl             --受入明細
               ,oe_order_headers_all                              ooha            --受注ヘッダ
              WHERE itp.doc_type = 'PORC'                                         --文書タイプ
              AND itp.completed_ind = gv_tran_cmp                                 --完了フラグ
              AND rsl.source_document_code = 'RMA'                                --ソース文書
              AND itp.doc_id = rsl.shipment_header_id                             --受入ヘッダID
              AND itp.doc_line = rsl.line_num                                     --明細番号
              AND rsl.oe_order_header_id = ooha.header_id                         --受注ヘッダID
           ) oe_info
           ,xxwsh_order_headers_all                           xoha                --受注ヘッダ(アドオン)
--add start 1.7
           ,xxcmn_party_sites2_v                              xpsv                --パーティサイト情報VIEW2
           ,xxcmn_vendor_sites2_v                             xvsv                --仕入先サイト情報VIEW2
--add end 1.7
           ,xxwsh_order_lines_all                             xola                --受注明細(アドオン)
           ,oe_transaction_types_all                          otta                --受注タイプ
           ,xxcmn_rcv_pay_mst                                 xrpm                --受入区分アドオンマスタ
           ,xxcmn_item_mst2_v                                 ximv_s              --OPM品目情報VIEW2(出荷品目用)
           ,xxcmn_item_mst2_v                                 ximv_r              --OPM品目情報VIEW2(依頼品目用)
           ,xxcmn_item_categories5_v                          xicv_s              --OPM品目カテゴリ割当情報VIEW5(出荷品目用)
           ,xxcmn_item_categories5_v                          xicv_r              --OPM品目カテゴリ割当情報VIEW5(依頼品目用)
           ,xxcmn_item_locations2_v                           xilv                --OPM保管場所情報VIEW2
          --受注ヘッダ(アドオン)抽出条件
          WHERE oe_info.header_id = xoha.header_id                                --受注ヘッダID
--add start 1.6
          AND xoha.req_status IN (gv_recsts_shipped,gv_recsts_shipped2)             --ステータス
          AND xoha.actual_confirm_class = gv_confirm_yes                            --実績計上区分
          AND xoha.latest_external_flag = gv_latest_yes                             --最新フラグ
--add end 1.6
          --受注明細(アドオン)抽出条件
          AND xoha.order_header_id = xola.order_header_id                         --受注アドオンヘッダID
          --受注タイプ抽出条件
          AND oe_info.order_type_id = otta.transaction_type_id                    --受注タイプID
          --OPM品目情報VIEW2(出荷品目用)抽出条件
          AND xola.shipping_item_code = ximv_s.item_no                            --品目コード
          AND oe_info.trans_date
            BETWEEN ximv_s.start_date_active
            AND NVL(ximv_s.end_date_active,oe_info.trans_date)                    --適用開始日・終了日
          --OPM品目カテゴリ割当情報VIEW5(出荷品目用)抽出条件
          AND ximv_s.item_id = xicv_s.item_id                                     --品目ID
          --OPM品目情報VIEW2(依頼品目用)抽出条件
          AND xola.request_item_code = ximv_r.item_no                             --品目コード
          AND oe_info.trans_date
            BETWEEN ximv_r.start_date_active
            AND NVL(ximv_r.end_date_active,oe_info.trans_date)                    --適用開始日・終了日
          --OPM品目カテゴリ割当情報VIEW5(依頼品目用)抽出条件
          AND ximv_r.item_id = xicv_r.item_id                                     --品目ID
--add start 1.7
          --パーティサイト情報VIEW2抽出条件
          AND xoha.result_deliver_to_id = xpsv.party_site_id(+)
          AND TO_DATE(civ_ymd_from,gv_fmt_ymd)
            BETWEEN xpsv.start_date_active(+)
            AND NVL(xpsv.end_date_active(+),TO_DATE(civ_ymd_from,gv_fmt_ymd))     --適用開始日・終了日
          --仕入先サイト情報VIEW抽出条件
          AND xoha.vendor_site_id = xvsv.vendor_site_id(+)
          AND TO_DATE(civ_ymd_from,gv_fmt_ymd)
            BETWEEN xvsv.start_date_active(+)
            AND NVL(xvsv.end_date_active(+),TO_DATE(civ_ymd_from,gv_fmt_ymd))     --適用開始日・終了日
--add end 1.7
          --受払区分アドオンマスタ抽出条件
          AND oe_info.doc_type = xrpm.doc_type                                    --文書タイプ
          AND ((oe_info.doc_type = 'PORC'
             AND xrpm.source_document_code = 'RMA')                               --ソース文書
          OR 
            (oe_info.doc_type = 'OMSO')
          )
          AND ( otta.attribute1 = xrpm.shipment_provision_div                      --出荷支給区分
            AND xrpm.shipment_provision_div IN (gv_spdiv_ship,gv_spdiv_prov)
          OR    xrpm.shipment_provision_div IS NULL
          )
          AND (otta.attribute11 = xrpm.ship_prov_rcv_pay_category                 --出荷支給受払カテゴリ
          OR   xrpm.ship_prov_rcv_pay_category IS NULL
          )
--mod start 1.8
--          AND NVL(DECODE(xicv_s.item_class_code
--                        ,gv_item_class_prod
--                        ,gv_item_class_prod
--                        ,NULL),gv_dummy
----mod start 1.4
----              ) = NVL(xrpm.item_div_ahead,gv_dummy)                               --出荷品目の品目区分＝振替先品目区分
--              ) = NVL(xrpm.item_div_origin,gv_dummy)                              --出荷品目の品目区分＝振替元品目区分
----mod end 1.4
--          AND NVL(DECODE(xicv_r.item_class_code
--                        ,gv_item_class_prod
--                        ,gv_item_class_prod
--                        ,NULL),gv_dummy
----mod start 1.4
----              ) = NVL(xrpm.item_div_origin,gv_dummy)                              --依頼品目の品目区分＝振替元品目区分
--              ) = NVL(xrpm.item_div_ahead,gv_dummy)                               --依頼品目の品目区分＝振替先品目区分
----mod end 1.4
          --出荷品目区分=振替元品目区分
          AND (
                --出荷依頼・支給依頼
                xrpm.shipment_provision_div in (gv_spdiv_ship,gv_spdiv_prov)
            AND NVL(DECODE(xicv_s.item_class_code
                          ,gv_item_class_prod,gv_item_class_prod
                                             ,NULL),gv_dummy)
                = NVL(xrpm.item_div_origin,gv_dummy)
                --出荷依頼・支給依頼以外
          OR
                NVL(xrpm.shipment_provision_div,gv_dummy) NOT IN (gv_spdiv_ship,gv_spdiv_prov)
          )
          --依頼品目区分=振替先品目区分
          AND (
                --出荷依頼・支給依頼
                xrpm.shipment_provision_div in (gv_spdiv_ship,gv_spdiv_prov)
            AND NVL(DECODE(xicv_r.item_class_code
                          ,gv_item_class_prod,gv_item_class_prod
                                             ,NULL),gv_dummy)
                = NVL(xrpm.item_div_ahead,gv_dummy)
                --出荷依頼・支給依頼以外
          OR
                NVL(xrpm.shipment_provision_div,gv_dummy) NOT IN (gv_spdiv_ship,gv_spdiv_prov)
          )
--mod end 1.8
          AND NVL(DECODE(otta.attribute4
                        ,gv_stock_adjm
                        ,gv_stock_adjm
                        ,NULL),gv_dummy
              ) = NVL(DECODE(xrpm.stock_adjustment_div                            --在庫調整区分
                            ,gv_stock_adjm
                            ,gv_stock_adjm
                            ,NULL),gv_dummy
              )
          AND xrpm.use_div_invent = gv_inventory                                  --在庫使用区分
--add start 2.0
          AND (xicv_s.item_class_code = gv_item_class_prod AND xicv_r.item_class_code = gv_item_class_prod
            AND ( ximv_s.item_id = ximv_r.item_id
              AND xrpm.prod_div_origin IS NULL
              AND xrpm.prod_div_ahead IS NULL
            OR    ximv_s.item_id != ximv_r.item_id
              AND xrpm.prod_div_origin IS NOT NULL
              AND xrpm.prod_div_ahead IS NOT NULL
            )
          OR NOT( xicv_s.item_class_code = gv_item_class_prod AND xicv_r.item_class_code = gv_item_class_prod)
          )
--add end 2.0
          --OPM保管場所情報VIEW抽出条件
          AND oe_info.location = xilv.segment1                                    --保管場所コード
          AND oe_info.trans_date
            BETWEEN xilv.date_from
            AND NVL(xilv.date_to,oe_info.trans_date)                              --適用開始日・終了日
          GROUP BY 
            oe_info.doc_type                                                      --文書タイプ
           ,oe_info.item_id                                                       --品目ID
           ,oe_info.whse_code                                                     --倉庫コード
           ,xilv.whse_name                                                        --倉庫名
           ,oe_info.location                                                      --保管倉庫コード
           ,xilv.description                                                      --保管倉庫名
           ,xilv.inventory_location_id                                            --保管倉庫ID
           ,oe_info.lot_id                                                        --ロットID
           ,oe_info.doc_id                                                        --文書ID
           ,oe_info.doc_line                                                      --取引明細番号
           ,oe_info.header_id                                                     --受注ヘッダID
           ,oe_info.order_type_id                                                 --受注タイプID
           ,xrpm.rcv_pay_div                                                      --受払区分
           ,xrpm.new_div_invent                                                   --新区分
           ,xilv.distribution_block                                               --ブロック
--add start 1.6
           ,xoha.head_sales_branch
           ,xoha.deliver_to_id
           ,xoha.result_deliver_to
           ,xoha.vendor_site_code
           ,xoha.arrival_date
           ,xoha.shipped_date
           ,xoha.request_no
           ,xoha.req_status
           ,xpsv.party_site_full_name
           ,xvsv.vendor_site_name
--add end 1.6
        )                                                     sh_info             --出荷関連情報
--del start 1.6
--         ,xxwsh_order_headers_all                             xoha                --受注ヘッダ(アドオン)
--del end 1.6
         ,xxcmn_cust_accounts2_v                              xcav                --顧客情報VIEW2
--del start 1.7
--         ,xxcmn_party_sites2_v                                xpsv                --パーティサイト情報VIEW2
--del end 1.7
        ----------------------------------------------------------------------------------------
        --受注ヘッダ(アドオン)抽出条件
--del start 1.6
--        WHERE sh_info.header_id = xoha.header_id                                  --受注ヘッダID
--        AND sh_info.inventory_location_id = xoha.deliver_from_id                  --出荷元ID
--        AND xoha.req_status IN (gv_recsts_shipped,gv_recsts_shipped2)             --ステータス
--        AND xoha.actual_confirm_class = gv_confirm_yes                            --実績計上区分
--        AND xoha.latest_external_flag = gv_latest_yes                             --最新フラグ
--del end 1.6
        --顧客情報VIEW抽出条件
--mod start 1.6
--        AND xoha.head_sales_branch = xcav.account_number                          --顧客番号
        WHERE sh_info.head_sales_branch = xcav.account_number(+)                          --顧客番号
--mod end 1.6
        AND xcav.customer_class_code(+) = gv_custclass                               --顧客区分(拠点)
        AND TO_DATE(civ_ymd_from,gv_fmt_ymd)
--mod start 1.3
--          BETWEEN TRUNC(xcav.start_date_active) AND TRUNC(xcav.end_date_active)   --適用開始日・終了日
          BETWEEN xcav.start_date_active(+)
          AND NVL(xcav.end_date_active(+),TO_DATE(civ_ymd_from,gv_fmt_ymd))         --適用開始日・終了日
--mod end 1.3
        --パーティサイト情報VIEW抽出条件
--del start 1.6
--        AND xoha.deliver_to_id = xpsv.party_site_id                               --パーティサイトID
--del end 1.6
--del start 1.7
--        AND TO_DATE(civ_ymd_from,gv_fmt_ymd)
----mod start 1.3
----          BETWEEN TRUNC(xpsv.start_date_active) AND TRUNC(xpsv.end_date_active)   --適用開始日・終了日
--          BETWEEN xpsv.start_date_active AND xpsv.end_date_active                 --適用開始日・終了日
----mod end 1.3
--del end 1.7
        --着日基準の場合の条件
        AND (
          (civ_base_date = gv_base_date_arrival --着日基準の場合
--mod start 1.6
----mod start 1.3
----            AND TRUNC(xoha.arrival_date)                                          --着荷日
--            AND xoha.arrival_date                                                 --着荷日
----mod end 1.3
            AND sh_info.arrival_date                                                 --着荷日
--mod end 1.6
              BETWEEN TO_DATE(civ_ymd_from,gv_fmt_ymd) AND TO_DATE(civ_ymd_to,gv_fmt_ymd)
          )
        --発日基準の場合の条件
        OR  (
          (civ_base_date = gv_base_date_ship --発日基準の場合
--mod start 1.6
----mod start 1.3
----            AND TRUNC(xoha.shipped_date)                                          --出荷日
--            AND xoha.shipped_date                                          --出荷日
----mod end 1.3
            AND sh_info.shipped_date                                          --出荷日
--mod end 1.6
              BETWEEN TO_DATE(civ_ymd_from,gv_fmt_ymd) AND TO_DATE(civ_ymd_to,gv_fmt_ymd)
            )
          )
        )
        UNION ALL
        ------------------------------
        -- 4.倉替返品実績情報
        ------------------------------
        SELECT
          gv_trtry_rt                                         territory           --領域(倉替返品)
         ,rt_info.item_id                                     item_id             --品目ID
         ,rt_info.lot_id                                      lot_id              --ロットID
         ,CASE civ_base_date --パラメータ.基準
            WHEN gv_base_date_arrival THEN TO_CHAR(xoha.arrival_date,gv_fmt_ymd)
            WHEN gv_base_date_ship THEN TO_CHAR(xoha.shipped_date,gv_fmt_ymd)
            ELSE NULL
          END                                                 standard_date       --日付
         ,rt_info.reason_code                                 reason_code         --新区分
         ,xoha.request_no                                     slip_no             --伝票No
         ,TO_CHAR(xoha.shipped_date,gv_fmt_ymd)               out_date            --出庫日
         ,TO_CHAR(xoha.arrival_date,gv_fmt_ymd)               in_date             --着日
         ,xoha.head_sales_branch                              jrsd_code           --管轄拠点コード
         ,xcav.party_short_name                               jrsd_name           --管轄拠点名
         ,xoha.head_sales_branch                              other_code          --相手先コード
         ,xcav.party_name                                     other_name          --相手先名称
         ,rt_info.in_qty_sum                                  in_qty              --入庫数
         ,0                                                   out_qty             --出庫数
         ,rt_info.whse_code                                   whse_code           --倉庫コード
         ,rt_info.whse_name                                   whse_name           --倉庫名
         ,rt_info.location                                    location            --保管倉庫コード
         ,rt_info.description                                 description         --保管倉庫名
         ,rt_info.distribution_block                          distribution_block  --ブロック
         ,rt_info.rcv_pay_div                                 rcv_pay_div         --受払区分
        ----------------------------------------------------------------------------------------
        FROM (
          SELECT
            xoha.header_id                                    header_id           --受注ヘッダID
           ,itp.whse_code                                     whse_code           --倉庫コード
           ,xilv.whse_name                                    whse_name           --倉庫名
           ,itp.item_id                                       item_id             --品目ID
           ,itp.lot_id                                        lot_id              --ロットID
           ,itp.location                                      location            --保管倉庫コード
           ,xilv.description                                  description         --保管倉庫名
           ,xilv.inventory_location_id                        inventory_location_id --保管倉庫ID
           ,xrpm.new_div_invent                               reason_code         --新区分
           ,xilv.distribution_block                           distribution_block  --ブロック
           ,xrpm.rcv_pay_div                                  rcv_pay_div         --受払区分
           ,SUM(NVL(itp.trans_qty,0))                         in_qty_sum          --数量合計
          FROM
            ic_tran_pnd                                       itp                 --OPM保留在庫トランザクション
           ,xxcmn_item_locations2_v                           xilv                --保管場所情報VIEW2(結合用)
           ,rcv_shipment_lines                                rsl                 --受入明細
           ,oe_order_headers_all                              ooha                --受注ヘッダ
           ,xxwsh_order_headers_all                           xoha                --受注ヘッダ(アドオン)
           ,oe_transaction_types_all                          otta                --受注タイプ
           ,xxcmn_rcv_pay_mst                                 xrpm                --受払区分アドオンマスタ
          --OPM保留在庫トランザクション抽出
          WHERE itp.completed_ind = gv_tran_cmp                                   --完了フラグ
          AND itp.doc_type = 'PORC'                                               --文書タイプ
          --保管場所情報VIEW2抽出
          AND itp.location = xilv.segment1                                        --保管倉庫コード
          AND itp.trans_date
            BETWEEN xilv.date_from AND NVL(xilv.date_to,itp.trans_date)           --適用開始日・終了日
          --受入明細抽出
          AND itp.doc_id = rsl.shipment_header_id                                 --受入ヘッダID
          AND itp.doc_line = rsl.line_num                                         --明細番号
          AND rsl.source_document_code = 'RMA'                                    --ソース文書
          --受注ヘッダ抽出
          AND rsl.oe_order_header_id = ooha.header_id                             --受注ヘッダID
          --受注ヘッダアドオン抽出
          AND ooha.header_id = xoha.header_id                                     --受注ヘッダID
          --受注タイプ抽出
          AND ooha.order_type_id = otta.transaction_type_id                       --受注タイプID
          AND otta.attribute1 = gv_shipclass                                      --出荷支給区分
          --受払区分アドオンマスタ抽出
          AND otta.attribute1 = xrpm.shipment_provision_div                       --出荷支給区分
          AND otta.attribute11 = xrpm.ship_prov_rcv_pay_category                  --出荷支給受払カテゴリ
          AND xrpm.use_div_invent = gv_inventory                                  --在庫使用区分
          AND xrpm.doc_type = 'PORC'                                              --文書タイプ
          AND xrpm.source_document_code = 'RMA'                                   --ソース文書
          GROUP BY
            xoha.header_id                                                        --受注ヘッダID
           ,itp.whse_code                                                         --倉庫コード
           ,xilv.whse_name                                                        --倉庫名
           ,itp.item_id                                                           --品目ID
           ,itp.lot_id                                                            --ロットID
           ,itp.location                                                          --保管倉庫コード
           ,xilv.description                                                      --保管倉庫名
           ,xilv.inventory_location_id                                            --保管倉庫ID
           ,xrpm.new_div_invent                                                   --新区分
           ,xilv.distribution_block                                               --ブロック
           ,xrpm.rcv_pay_div                                                      --受払区分
        ) rt_info                                                                 --倉替返品関連情報
        ,xxwsh_order_headers_all                              xoha                --受注ヘッダ(アドオン)
        ,xxcmn_cust_accounts2_v                               xcav                --顧客情報VIEW2
        ----------------------------------------------------------------------------------------
        --受注ヘッダ(アドオン)抽出
        WHERE rt_info.header_id = xoha.header_id                                  --受注ヘッダID
        AND xoha.req_status IN (gv_recsts_shipped,gv_recsts_shipped2)             --ステータス
        AND xoha.actual_confirm_class = gv_confirm_yes                            --実績計上区分
        AND xoha.latest_external_flag = gv_latest_yes                             --最新フラグ
        AND xoha.deliver_from_id = rt_info.inventory_location_id                  --出荷元ID
        --顧客情報VIEW2抽出
        AND xoha.head_sales_branch = xcav.account_number                          --顧客番号
        AND xcav.customer_class_code = gv_custclass                               --顧客区分(拠点)
        AND TO_DATE(civ_ymd_from,gv_fmt_ymd)
--mod start 1.3
--          BETWEEN TRUNC(xcav.start_date_active) AND TRUNC(xcav.end_date_active)   --適用開始日・終了日
          BETWEEN xcav.start_date_active AND xcav.end_date_active                 --適用開始日・終了日
--mod end 1.3
        --着日基準の場合
        AND (
          (civ_base_date = gv_base_date_arrival                                --着日基準の場合
--mod start 1.3
--            AND TRUNC(xoha.arrival_date)                                          --着荷日
            AND xoha.arrival_date                                                 --着荷日
--mod end 1.3
              BETWEEN TO_DATE(civ_ymd_from,gv_fmt_ymd) AND TO_DATE(civ_ymd_to,gv_fmt_ymd)
          )
        --発日基準の場合
        OR  
          (civ_base_date = gv_base_date_ship                                   --発日基準の場合
--mod start 1.3
--            AND TRUNC(xoha.shipped_date)                                          --出荷日
            AND xoha.shipped_date                                                 --出荷日
--mod end 1.3
              BETWEEN TO_DATE(civ_ymd_from,gv_fmt_ymd) AND TO_DATE(civ_ymd_to,gv_fmt_ymd)
          )
        )
        UNION ALL
        ------------------------------
        -- 5.生産実績情報
        ------------------------------
        SELECT
          gv_trtry_mf                                         territory           --領域(生産)
         ,gmd.item_id                                         item_id             --品目ID
         ,itp.lot_id                                          lot_id              --ロットID
--mod start 1.9
--         ,SUBSTRB(gmd_d.attribute11,1,10)                     standard_date       --日付
         ,DECODE(grt.routing_desc                                               --工順区分
                ,gv_item_transfer      ,TO_CHAR(itp.trans_date,gv_fmt_ymd)      --品目振替
                ,gv_item_return        ,TO_CHAR(itp.trans_date,gv_fmt_ymd)      --返品原料
                ,gv_item_dissolve      ,TO_CHAR(itp.trans_date,gv_fmt_ymd)      --解体半製品
                                       ,SUBSTRB(gmd_d.attribute11,1,10)         --その他
          )
--mod end 1.9
         ,xrpm.new_div_invent                                 reason_code         --新区分
         ,gbh.batch_no                                        slip_no             --伝票No
--mod start 1.9
--         ,SUBSTRB(gmd_d.attribute11,1,10)                     out_date            --出庫日
--         ,SUBSTRB(gmd_d.attribute11,1,10)                     in_date             --着日
         ,DECODE(grt.routing_desc                                               --工順区分
                ,gv_item_transfer      ,TO_CHAR(itp.trans_date,gv_fmt_ymd)      --品目振替
                ,gv_item_return        ,TO_CHAR(itp.trans_date,gv_fmt_ymd)      --返品原料
                ,gv_item_dissolve      ,TO_CHAR(itp.trans_date,gv_fmt_ymd)      --解体半製品
                                       ,SUBSTRB(gmd_d.attribute11,1,10)         --その他
          )                                                   out_date
         ,DECODE(grt.routing_desc                                               --工順区分
                ,gv_item_transfer      ,TO_CHAR(itp.trans_date,gv_fmt_ymd)      --品目振替
                ,gv_item_return        ,TO_CHAR(itp.trans_date,gv_fmt_ymd)      --返品原料
                ,gv_item_dissolve      ,TO_CHAR(itp.trans_date,gv_fmt_ymd)      --解体半製品
                                       ,SUBSTRB(gmd_d.attribute11,1,10)         --その他
          )                                                   in_date
--mod end 1.9
         ,''                                                  jrsd_code           --管轄拠点コード
         ,''                                                  jrsd_name           --管轄拠点名
         ,grb.routing_no                                      other_code          --相手先コード
         ,grt.routing_desc                                    other_name          --相手先名称
         ,SUM(CASE gmd.line_type --ラインタイプ
            WHEN gn_linetype_mtrl THEN 0
            ELSE NVL(itp.trans_qty,0)
          END)                                                in_qty              --入庫数
-- mod start 1.18
--         ,SUM(CASE gmd.line_type --ラインタイプ
         ,ABS(SUM(CASE gmd.line_type --ラインタイプ
            WHEN gn_linetype_mtrl THEN NVL(itp.trans_qty,0)
            ELSE 0
--          END)                                                 out_qty             --出庫数
          END))                                                out_qty             --出庫数
-- mod end 1.18
         ,itp.whse_code                                       whse_code           --倉庫コード
         ,xilv.whse_name                                      whse_name           --倉庫名
         ,itp.location                                        location            --保管倉庫コード
         ,xilv.description                                    description         --保管倉庫名
         ,xilv.distribution_block                             distribution_block  --ブロック
         ,xrpm.rcv_pay_div                                    rcv_pay_div         --受払区分
        ----------------------------------------------------------------------------------------
        FROM
          gme_batch_header                                    gbh                 --生産バッチ
         ,gme_material_details                                gmd                 --生産原料詳細
         ,gme_material_details                                gmd_d               --生産原料詳細(完成品)
         ,gmd_routings_b                                      grb                 --工順マスタ
         ,gmd_routings_tl                                     grt                 --工順マスタ日本語
         ,xxcmn_item_locations2_v                             xilv                --保管場所情報VIEW2
         --生産原料詳細(振替元先品目)
         ,(
           SELECT 
             gbh.batch_id                                     batch_id            --バッチID
            ,gmd.line_no                                      line_no             --ラインNO
            ,MAX(DECODE(gmd.line_type --ラインタイプ
                       ,gn_linetype_mtrl,xicv.item_class_code
                       ,NULL
                )
             )                                                item_class_origin   --振替元品目区分
            ,MAX(DECODE(gmd.line_type --ラインタイプ
                       ,gn_linetype_prod,xicv.item_class_code
                       ,NULL
                )
             )                                                item_class_ahead    --振替先品目区分
           FROM
             gme_batch_header                                 gbh                 --生産バッチ
            ,gme_material_details                             gmd                 --生産原料詳細
            ,gmd_routings_tl                                  grt                 --工順マスタ日本語
            ,xxcmn_item_categories5_v                         xicv                --OPM品目カテゴリ割当情報VIEW5
           --生産原料詳細抽出条件
           WHERE gbh.batch_id = gmd.batch_id                                      --バッチID
           --工順マスタ日本語抽出条件
           AND gbh.routing_id = grt.routing_id                                    --工順ID
           AND grt.language = gv_lang                                             --言語
           AND grt.source_lang = gv_source_lang                                   --言語
           AND grt.routing_desc = gv_item_transfer                                --工順名
           --OPM品目カテゴリ割当情報VIEW5
           AND gmd.item_id = xicv.item_id
           GROUP BY gbh.batch_id
                   ,gmd.line_no
         ) gmd_t
         ,xxcmn_rcv_pay_mst                                   xrpm                --受払区分アドオンマスタ
         ,ic_tran_pnd                                         itp                 --OPM保留在庫トランザクション
        ----------------------------------------------------------------------------------------
        --生産原料詳細抽出条件
        WHERE gbh.batch_id = gmd.batch_id                                         --バッチID
        --生産原料詳細(完成品)
        AND gbh.batch_id = gmd_d.batch_id                                         --バッチID
        AND gmd_d.line_type = gn_linetype_prod                                    --ラインタイプ(完成品)
        --生産原料詳細(振替)
        AND gmd.batch_id = gmd_t.batch_id(+)                                      --バッチID
        AND gmd.line_no = gmd_t.line_no(+)                                        --ラインNO
        --工順マスタ抽出条件
        AND gbh.routing_id = grb.routing_id                                       --工順ID
        --工順マスタ日本語抽出条件
        AND grb.routing_id = grt.routing_id                                       --工順ID
        AND grt.language = gv_lang                                                --言語
        AND grt.source_lang = gv_source_lang                                      --言語
        --OPM保管場所マスタ抽出条件
        AND xilv.segment1 = grb.attribute9                                        --保管場所コード
--mod start 1.9
--        AND TO_DATE(gmd_d.attribute11,gv_fmt_ymd)
--          BETWEEN xilv.date_from
--          AND NVL(xilv.date_to,TO_DATE(gmd_d.attribute11,gv_fmt_ymd))             --適用開始日・終了日
        AND DECODE(grt.routing_desc                                               --工順区分
                  ,gv_item_transfer      ,itp.trans_date                          --品目振替
                  ,gv_item_return        ,itp.trans_date                          --返品原料
                  ,gv_item_dissolve      ,itp.trans_date                          --解体半製品
                                         ,TO_DATE(gmd_d.attribute11,gv_fmt_ymd)   --その他
            )
          BETWEEN xilv.date_from
          AND NVL(xilv.date_to,
                DECODE(grt.routing_desc                                               --工順区分
                      ,gv_item_transfer      ,itp.trans_date                          --品目振替
                      ,gv_item_return        ,itp.trans_date                          --返品原料
                      ,gv_item_dissolve      ,itp.trans_date                          --解体半製品
                                             ,TO_DATE(gmd_d.attribute11,gv_fmt_ymd)   --その他
                )
              )
--mod end 1.9
        --OPM保留在庫トランザクション抽出条件
        AND itp.line_id = gmd.material_detail_id                                  --ラインID
        AND itp.item_id = gmd.item_id                                             --品目ID
        AND itp.location = xilv.segment1                                          --保管倉庫コード
        AND itp.completed_ind = gv_tran_cmp                                       --完了フラグ
        AND itp.doc_type = 'PROD'                                                 --文書タイプ
        AND itp.reverse_id IS NULL                                                --リバースID
        AND itp.delete_mark = gn_delete_mark_no                                   --削除マーク
        --受払区分アドオンマスタ抽出条件
        AND xrpm.doc_type = 'PROD'                                                --文書タイプ
        AND xrpm.line_type = gmd.line_type                                        --ラインタイプ
        AND NVL(xrpm.hit_in_div,gv_dummy) = NVL(gmd.attribute5,gv_dummy)          --打込区分
        AND NVL(xrpm.routing_class,gv_dummy) = NVL(grb.routing_class,gv_dummy)    --工順区分
        AND (
          (   grt.routing_desc = gv_item_transfer                                 --品目振替の場合
          AND xrpm.item_div_ahead = gmd_t.item_class_ahead                        --振替先品目区分
          AND xrpm.item_div_origin = gmd_t.item_class_origin                      --振替元品目区分
          )
        OR
          (   grt.routing_desc != gv_item_transfer)                                --品目振替ではない場合
        )
        AND xrpm.use_div_invent = gv_inventory                                    --在庫使用区分
        --生産日
--mod start 1.9
--        AND SUBSTRB(gmd_d.attribute11,1,10) BETWEEN civ_ymd_from AND civ_ymd_to   --生産日
        AND DECODE(grt.routing_desc                                               --工順区分
                  ,gv_item_transfer      ,TO_CHAR(itp.trans_date,gv_fmt_ymd)      --品目振替
                  ,gv_item_return        ,TO_CHAR(itp.trans_date,gv_fmt_ymd)      --返品原料
                  ,gv_item_dissolve      ,TO_CHAR(itp.trans_date,gv_fmt_ymd)      --解体半製品
                                         ,SUBSTRB(gmd_d.attribute11,1,10)         --その他
            )
            BETWEEN civ_ymd_from AND civ_ymd_to
--mod end 1.9
        ----------------------------------------------------------------------------------------
        GROUP BY 
          gv_trtry_mf                                                             --領域(生産)
         ,gmd.item_id                                                             --品目ID
         ,itp.lot_id                                                              --ロットID
         ,SUBSTRB(gmd_d.attribute11,1,10)                                         --日付
--add start 1.9
         ,TO_CHAR(itp.trans_date,gv_fmt_ymd)
--add end 1.9
         ,xrpm.new_div_invent                                                     --新区分
         ,gbh.batch_no                                                            --伝票No
         ,grb.routing_no                                                          --相手先コード
         ,grt.routing_desc                                                        --相手先名称
         ,itp.whse_code                                                           --倉庫コード
         ,xilv.whse_name                                                          --倉庫名
         ,itp.location                                                            --保管倉庫コード
         ,xilv.description                                                        --保管倉庫名
         ,xilv.distribution_block                                                 --ブロック
         ,xrpm.rcv_pay_div                                                        --受払区分
        UNION ALL
        ------------------------------
        -- 6.在庫調整実績情報
        ------------------------------
        SELECT
          gv_trtry_ad                                         territory           --領域(在庫調整)
         ,itc.item_id                                         item_id             --品目ID
         ,itc.lot_id                                          lot_id              --ロットID
         ,TO_CHAR(itc.trans_date,gv_fmt_ymd)                  standard_date       --日付
         ,xrpm.new_div_invent                                 reason_code         --新区分
         ,ad_info.slip_no                                     slip_no             --伝票No
         ,TO_CHAR(itc.trans_date,gv_fmt_ymd)                  out_date            --出庫日
         ,TO_CHAR(itc.trans_date,gv_fmt_ymd)                  in_date             --着日
         ,''                                                  jrsd_code           --管轄拠点コード
         ,''                                                  jrsd_name           --管轄拠点名
         ,CASE ad_info.adji_type
            WHEN gv_adji_xrart THEN ad_info.other_code
            WHEN gv_adji_xnpt THEN xrpm.new_div_invent
            WHEN gv_adji_xvst THEN ad_info.other_code
            WHEN gv_adji_xmrih THEN ad_info.other_code
            WHEN gv_adji_ijm THEN xrpm.new_div_invent
          END                                                 other_code          --相手先コード
         ,CASE ad_info.adji_type
            WHEN gv_adji_xrart THEN ad_info.other_name
            WHEN gv_adji_xnpt THEN NULL
            WHEN gv_adji_xvst THEN ad_info.other_name
            WHEN gv_adji_xmrih THEN ad_info.other_name
            WHEN gv_adji_ijm THEN NULL
          END                                                 other_name          --相手先名称
         ,CASE xrpm.rcv_pay_div
            WHEN '1' THEN SUM(NVL(itc.trans_qty,0))
            ELSE 0
          END                                                 in_qty              --入庫数
         ,CASE xrpm.rcv_pay_div
            WHEN '-1' THEN SUM(NVL(itc.trans_qty,0) * -1)
            ELSE 0
          END                                                 out_qty             --出庫数
         ,itc.whse_code                                       whse_code           --倉庫コード
         ,xilv.whse_name                                      whse_name           --倉庫名
         ,itc.location                                        location            --保管倉庫コード
         ,xilv.description                                    description         --保管倉庫名
         ,xilv.distribution_block                             distribution_block  --ブロック
         ,xrpm.rcv_pay_div                                    rcv_pay_div         --受払区分
        FROM
          (
            -----------------------
            --受入返品実績情報(仕入先返品)
            -----------------------
            SELECT
              ijm.journal_id                                  journal_id          --ジャーナルID
             ,xrart.rcv_rtn_number                            slip_no             --伝票No
             ,xrart.vendor_code                               other_code          --取引先コード
             ,xvv.vendor_name                                 other_name          --取引先名称
             ,gv_adji_xrart                                   adji_type           --在庫タイプ
            FROM
              ic_jrnl_mst                                     ijm                 --OPMジャーナルマスタ
             ,xxpo_rcv_and_rtn_txns                           xrart               --受入返品実績アドオン
             ,xxcmn_vendors2_v                                xvv                 --仕入先情報view2
            --受入返品実績(アドオン)抽出条件
            WHERE xrart.txns_type != gv_txns_type_rcv                             --実績区分
            AND TRUNC(xrart.txns_date)                                            --取引日
              BETWEEN TO_DATE(civ_ymd_from,gv_fmt_ymd)
              AND TO_DATE(civ_ymd_to,gv_fmt_ymd)
            --OPMジャーナルマスタ抽出条件
            AND ijm.attribute1 = xrart.txns_id                                    --実績ID
            --仕入先情報view抽出条件
            AND xrart.vendor_id = xvv.vendor_id                                   --取引先ID
            AND xrart.txns_date                                                   --取引日
              BETWEEN start_date_active                                           --適用開始日
              AND NVL(end_date_active,xrart.txns_date)                            --適用終了日
--add start 1.16
            UNION ALL
            -----------------------
            --受入返品実績情報(相手先在庫)
            -----------------------
            SELECT
              ijm.journal_id                                  journal_id          --ジャーナルID
             ,xrart.source_document_number                    slip_no             --伝票No
-- mod start 1.17 相手先コードは受入返品実績アドオン.取引先コードを出力
--             ,xrart.location_code                             other_code          --入出庫先コード
              ,xrart.vendor_code                              other_code          --取引先コード(相手先)
-- mod end 1.17
-- mod start 1.17 相手先名は仕入先情報VIEW.正式名を出力
--             ,xilv.description                                other_name          --摘要（入出庫先名称）
              ,xvv.vendor_full_name                           other_name          --正式名(相手先名)
-- mod end 1.17
             ,gv_adji_xrart                                   adji_type           --在庫タイプ
            FROM
              ic_jrnl_mst                                     ijm                 --OPMジャーナルマスタ
             ,xxpo_rcv_and_rtn_txns                           xrart               --受入返品実績アドオン
-- mod start 1.17 相手先名は仕入先情報VIEW.正式名を出力
--             ,xxcmn_item_locations2_v                         xilv                --OPM保管場所マスタ
             ,xxcmn_vendors2_v                                xvv                 --仕入先情報VIEW
-- mod end 1.17
             ,po_headers_all                                  pha                 --発注ヘッダ
            --受入返品実績(アドオン)抽出条件
            WHERE xrart.txns_type  = gv_txns_type_rcv                             --実績区分
            AND TRUNC(xrart.txns_date)                                            --取引日
              BETWEEN TO_DATE(civ_ymd_from,gv_fmt_ymd)
              AND TO_DATE(civ_ymd_to,gv_fmt_ymd)
            --OPMジャーナルマスタ抽出条件
            AND ijm.attribute1 = xrart.txns_id                                    --実績ID
-- mod start 1.17 相手先名は仕入先情報VIEW.正式名を出力
--            --OPM保管場所マスタview抽出条件
--            AND xrart.location_code = xilv.segment1                               --入出庫先コード
--            AND xrart.txns_date                                                   --取引日
--              BETWEEN xilv.date_from AND NVL(xilv.date_to,xrart.txns_date)
            --仕入先情報view抽出条件
            AND xrart.vendor_id = xvv.vendor_id                                   --取引先ID
            AND xrart.txns_date                                                   --取引日
              BETWEEN xvv.start_date_active                                       --適用開始日
              AND NVL(xvv.end_date_active, xrart.txns_date)                       --適用終了日
-- mod end 1.17
            --発注ヘッダ
            AND xrart.source_document_number = pha.segment1                       --発注番号
            AND pha.attribute11 = po_type_inv                                     --発注区分(相手先在庫)
--add end 1.16
            UNION ALL
            -----------------------
            --生葉実績情報
            -----------------------
            SELECT
              ijm.journal_id                                  journal_id          --ジャーナルID
             ,xnpt.entry_number                               slip_no             --伝票No
             ,NULL                                            other_code          --相手先コード
             ,NULL                                            ohter_name          --相手先名
             ,gv_adji_xnpt                                    adji_type           --在庫タイプ
            FROM
              ic_jrnl_mst                                     ijm                 --OPMジャーナルマスタ
             ,xxpo_namaha_prod_txns                           xnpt                --生葉実績アドオン
            --生葉実績アドオン抽出条件
            WHERE TRUNC(xnpt.creation_date)                                       --作成日
              BETWEEN TO_DATE(civ_ymd_from,gv_fmt_ymd)
              AND TO_DATE(civ_ymd_to,gv_fmt_ymd)
            --OPMジャーナルマスタ抽出条件
            AND ijm.attribute1 = xnpt.entry_number                                --伝票No
            UNION ALL
            -----------------------
            --外注出来高実績(アドオン)
            -----------------------
            SELECT
              ijm.journal_id                                  journal_id          --ジャーナルID
              ,''                                             slip_no             --伝票No
-- mod start 1.17 相手先コードは外注出来高実績(アドオン).取引先コードを出力
--              ,itc.location                                   other_code          --相手先コード
              ,xvst.vendor_code                               other_code          --取引先コード(相手先)
-- mod end 1.17
-- mod start 1.17 相手先名は仕入先情報VIEW.正式名を出力
--              ,xilv.description                               other_name          --相手先名
              ,xvv.vendor_full_name                           other_name          --正式名(相手先名)
-- mod end 1.17
              ,gv_adji_xvst                                   adji_type           --在庫タイプ
            FROM
              ic_jrnl_mst                                     ijm                 --OPMジャーナルマスタ
             ,xxpo_vendor_supply_txns                         xvst                --外注出来高実績(アドオン)
             ,ic_adjs_jnl                                     iaj                 --OPM在庫調整ジャーナル
             ,ic_tran_cmp                                     itc                 --OPM完了在庫トランザクション
-- mod start 1.17 相手先名は仕入先情報VIEW.正式名を出力
--             ,xxcmn_item_locations2_v                         xilv                --OPM保管場所マスタ
               ,xxcmn_vendors2_v                                xvv                 --仕入先情報VIEW
-- mod end 1.17
            --外注出来高実績アドオン抽出条件
            WHERE ijm.attribute1 = xvst.txns_id                                   --実績ID
            --OPM在庫調整ジャーナル抽出条件
            AND ijm.journal_id = iaj.journal_id
            --OPM完了在庫トランザクション抽出条件
            AND iaj.doc_id = itc.doc_id
            AND iaj.doc_line = itc.doc_line
            AND TRUNC(itc.trans_date)
              BETWEEN TO_DATE(civ_ymd_from,gv_fmt_ymd)
              AND TO_DATE(civ_ymd_to,gv_fmt_ymd)
-- mod start 1.17 相手先名は仕入先情報VIEW.正式名を出力
--            --OPM保管場所マスタview抽出条件
--            AND itc.location = xilv.segment1
--            AND itc.trans_date
--              BETWEEN xilv.date_from AND NVL(xilv.date_to,itc.trans_date)
            --仕入先情報view抽出条件
            AND xvst.vendor_id = xvv.vendor_id                                   --取引先ID
            AND itc.trans_date                                                   --取引日
              BETWEEN xvv.start_date_active                                      --適用開始日
              AND NVL(xvv.end_date_active, itc.trans_date)                       --適用終了日
-- mod end 1.17
--del start 1.2
/*
            UNION ALL
            -----------------------
            --移動実績情報
            -----------------------
            SELECT
              ijm.journal_id                                  journal_id          --ジャーナルID
             ,xmrih.mov_num                                   slip_no             --伝票No
             ,xmrih.other_code                                other_code          --相手先コード
             ,xilv.description                                other_name          --相手先名
             ,gv_adji_xmrih                                   adji_type           --在庫タイプ
            FROM
              ic_jrnl_mst                                     ijm                 --OPMジャーナルマスタ
             ,ic_adjs_jnl                                     iaj                 --OPM在庫調整ジャーナル
                --入庫実績
             ,( SELECT
                  xmrih.mov_hdr_id                            mov_hdr_id          --移動ヘッダID
                  ,xmrih.mov_num                              mov_num             --移動No
                  ,xmrih.ship_to_locat_code                   location            --保管場所
                  ,xmrih.shipped_locat_id                     other_id            --相手先(出庫元ID)
                  ,xmrih.shipped_locat_code                   other_code          --相手先コード(出荷元保管場所)
                  ,xmrih.actual_arrival_date                  actual_date         --実績日(入庫実績日)
                FROM xxinv_mov_req_instr_headers              xmrih
                UNION ALL
                --出庫実績
                SELECT
                  xmrih.mov_hdr_id                            mov_hdr_id          --移動ヘッダID
                 ,xmrih.mov_num                               mov_num             --移動No
                 ,xmrih.shipped_locat_code                    location            --保管場所
                 ,xmrih.ship_to_locat_id                      other_id            --相手先(入庫先ID)
                 ,xmrih.ship_to_locat_code                    other_code          --相手先(入庫先保管場所)
                 ,xmrih.actual_ship_date                      actual_date         --実績日(出庫実績日)
                FROM xxinv_mov_req_instr_headers              xmrih
             )                                                xmrih               --移動依頼/指示ヘッダ(アドオン)
             ,xxinv_mov_req_instr_lines                       xmril               --移動依頼/指示明細(アドオン)
             ,xxcmn_item_locations2_v                         xilv                --保管場所情報VIEW2
            --移動依頼/指示ヘッダアドオン抽出条件
            WHERE TRUNC(xmrih.actual_date)                                        --実績日
              BETWEEN TO_DATE(civ_ymd_from,gv_fmt_ymd)
              AND TO_DATE(civ_ymd_to,gv_fmt_ymd)
            --移動依頼/指示明細アドオン抽出条件
            AND xmrih.mov_hdr_id = xmril.mov_hdr_id                               --移動ヘッダID
            --OPMジャーナルマスタ抽出条件
            AND ijm.attribute1 = xmril.mov_line_id                                --移動明細ID
            --OPM在庫調整ジャーナル抽出条件
            AND ijm.journal_id = iaj.journal_id                                   --ジャーナルID
            AND iaj.location = xmrih.location                                     --保管場所
            --OPM保管場所マスタ抽出条件
            AND xmrih.other_id = xilv.inventory_location_id
            AND xmrih.actual_date
              BETWEEN xilv.date_from AND NVL(xilv.date_to,xmrih.actual_date)      --適用開始日・終了日
*/
--del end 1.2
            UNION ALL
            -----------------------
            --EBS標準の在庫調整
            -----------------------
            SELECT
              ijm.journal_id                                  journal_id          --ジャーナルID
             ,ijm.journal_no                                  slip_no             --伝票No
             ,NULL                                            other_code          --相手先コード
             ,NULL                                            other_name          --相手先名
             ,gv_adji_ijm                                     adji_type           --在庫タイプ
            FROM
              ic_jrnl_mst                                     ijm                 --OPMジャーナルマスタ
             ,ic_adjs_jnl                                     iaj                 --OPM在庫調整ジャーナル
             ,ic_tran_cmp                                     itc                 --OPM完了在庫トランザクション
            --OPMジャーナルマスタ抽出条件
            WHERE ijm.attribute1 IS NULL
            --OPM在庫調整ジャーナル抽出条件
            AND ijm.journal_id = iaj.journal_id
            --OPM完了在庫トランザクション抽出条件
            AND iaj.doc_id = itc.doc_id
            AND iaj.doc_line = itc.doc_line
            AND TRUNC(itc.trans_date)
              BETWEEN TO_DATE(civ_ymd_from,gv_fmt_ymd)
              AND TO_DATE(civ_ymd_to,gv_fmt_ymd)
         ) ad_info
         ,ic_adjs_jnl                                         iaj                 --OPM在庫調整ジャーナル
         ,ic_tran_cmp                                         itc                 --OPM完了在庫トランザクション
         ,xxcmn_item_locations2_v                             xilv                --保管場所情報VIEW2
         ,xxcmn_rcv_pay_mst                                   xrpm                --受払区分アドオンマスタ
         ,xxcmn_lookup_values2_v                              xlvv                --クイックコード
         ,sy_reas_cds_b                                       srcb                --事由コードマスタ
        ----------------------------------------------------------------------------------------
        --OPM在庫調整ジャーナル抽出条件
        WHERE iaj.journal_id = ad_info.journal_id                                 --ジャーナルID
        AND iaj.trans_type = 'ADJI'                                               --文書タイプ
        --OPM完了在庫トランザクション抽出条件
        AND itc.doc_type = 'ADJI'                                                 --文書タイプ
        AND itc.doc_id = iaj.doc_id                                               --文書ID
        AND itc.doc_line = iaj.doc_line                                           --取引明細番号
        --保管場所情報VIEW2抽出条件
        AND itc.location = xilv.segment1                                          --保管倉庫コード
        AND itc.trans_date
          BETWEEN xilv.date_from AND NVL(xilv.date_to,itc.trans_date)             --適用開始日・終了日
        --受払区分アドオンマスタ抽出条件
        AND xrpm.doc_type = 'ADJI'                                                --文書タイプ
        AND itc.reason_code = xrpm.reason_code                                    --事由コード
        AND xrpm.use_div_invent = gv_inventory                                    --在庫使用区分
-- del start 1.18
--        AND TO_CHAR(SIGN(itc.trans_qty)) = xrpm.rcv_pay_div                       --受払区分
-- del end 1.18
        AND xrpm.reason_code = srcb.reason_code                                   --事由コード
        AND srcb.delete_mark = 0                                                  --削除マーク(未削除)
        --クイックコード抽出条件
        AND xlvv.lookup_type =  gv_lookup_newdiv                                  --参照タイプ(新区分)
        AND xrpm.new_div_invent = xlvv.lookup_code                                --参照コード
        AND itc.trans_date
          BETWEEN xlvv.start_date_active
          AND NVL(xlvv.end_date_active,itc.trans_date)                            --適用開始日・終了日
        ----------------------------------------------------------------------------------------
        GROUP BY 
          itc.doc_id                                                              --文書ID
         ,itc.item_id                                                             --品目ID
         ,itc.lot_id                                                              --ロットID
         ,TO_CHAR(itc.trans_date,gv_fmt_ymd)                                      --日付
         ,xrpm.new_div_invent                                                     --新区分
         ,ad_info.slip_no                                                         --伝票No
         ,xlvv.description                                                        --相手先名称
         ,itc.whse_code                                                           --倉庫コード
         ,xilv.whse_name                                                          --倉庫名
         ,itc.location                                                            --保管倉庫コード
         ,xilv.description                                                        --保管倉庫名
         ,xilv.distribution_block                                                 --ブロック
         ,xrpm.rcv_pay_div                                                        --受払区分
         ,ad_info.adji_type                                                       --在庫タイプ
         ,ad_info.other_name                                                      --相手先名
         ,ad_info.other_code                                                      --相手先コード
       ) slip
       ,xxcmn_item_categories2_v                               xicv1               --OPM品目カテゴリ割当情報VIEW(商品区分)
       ,xxcmn_item_categories2_v                               xicv2               --OPM品目カテゴリ割当情報VIEW(品目区分)
       ,xxcmn_lookup_values2_v                                 xlvv                --クイックコード
       ,xxcmn_item_mst2_v                                      ximv                --OPM品目情報VIEW
       ,ic_lots_mst                                            ilm                 --OPMロットマスタ(結合用)
      --======================================================================================================
      --カテゴリセットが商品区分である品目
      WHERE slip.item_id = xicv1.item_id
      AND xicv1.category_set_name = gv_category_prod
      --カテゴリセットが品目区分である品目
      AND slip.item_id = xicv2.item_id
      AND xicv2.category_set_name = gv_category_item
      --クイックコード抽出条件
      AND xlvv.lookup_type =  gv_lookup_newdiv                                    --参照タイプ(新区分)
      AND slip.reason_code = xlvv.lookup_code                                     --参照コード
      AND TO_DATE(slip.standard_date,gv_fmt_ymd)
--mod start 1.3
--        BETWEEN TRUNC(xlvv.start_date_active)
--        AND NVL(TRUNC(xlvv.end_date_active),TO_DATE(slip.standard_date,gv_fmt_ymd))      --適用開始日・終了日
        BETWEEN xlvv.start_date_active
        AND NVL(xlvv.end_date_active,TO_DATE(slip.standard_date,gv_fmt_ymd))      --適用開始日・終了日
--mod end 1.3
      --OPM品目情報VIEW2抽出条件
      AND slip.item_id = ximv.item_id                                             --品目ID
      AND TO_DATE(slip.standard_date,gv_fmt_ymd)
--mod start 1.3
--        BETWEEN TRUNC(ximv.start_date_active)
--        AND NVL(TRUNC(ximv.end_date_active),TO_DATE(slip.standard_date,gv_fmt_ymd))--適用開始日・終了日
        BETWEEN ximv.start_date_active
        AND NVL(ximv.end_date_active,TO_DATE(slip.standard_date,gv_fmt_ymd))--適用開始日・終了日
--mod end 1.3
      --OPMロットマスタ抽出条件
      AND slip.item_id = ilm.item_id
      AND slip.lot_id = ilm.lot_id
      --パラメータによる絞込み(商品区分)
      AND xicv1.segment1 = civ_prod_div
      --パラメータによる絞込み(品目区分)
      AND xicv2.segment1 = civ_item_div
      --パラメータによる絞込み(ロットNo)
      AND ( civ_lot_no_01 IS NULL
        AND civ_lot_no_02 IS NULL
        AND civ_lot_no_03 IS NULL
      OR civ_lot_no_01 = ilm.lot_no
      OR civ_lot_no_02 = ilm.lot_no
      OR civ_lot_no_03 = ilm.lot_no
      )
      --パラメータによる絞込み(製造年月日)
      AND ( civ_mnfctr_date_01 IS NULL
        AND civ_mnfctr_date_02 IS NULL
        AND civ_mnfctr_date_03 IS NULL
      OR civ_mnfctr_date_01 = ilm.attribute1
      OR civ_mnfctr_date_02 = ilm.attribute1
      OR civ_mnfctr_date_03 = ilm.attribute1
      )
      --パラメータによる絞込み(固有記号)
      AND  ( civ_symbol IS NULL
      OR  civ_symbol = ilm.attribute2
      )
--mod start 1.13
--      --パラメータによる絞込み(物流ブロック)
--      AND ( civ_block_01 IS NULL
--        AND civ_block_02 IS NULL
--        AND civ_block_03 IS NULL
--      OR  civ_block_01 = slip.distribution_block
--      OR  civ_block_02 = slip.distribution_block
--      OR  civ_block_03 = slip.distribution_block
--      )
--      --パラメータによる絞込み(保管倉庫・倉庫)
----mod start 1.3
----      AND ( civ_wh_code_01 IS NULL
----        AND civ_wh_code_02 IS NULL
----        AND civ_wh_code_03 IS NULL
----      OR (   civ_wh_loc_ctl = gv_wh_loc_ctl_loc --保管倉庫の場合
----        AND  civ_wh_code_01 = slip.location
----          OR civ_wh_code_02 = slip.location
----          OR civ_wh_code_03 = slip.location
----        )
----      OR (   civ_wh_loc_ctl = gv_wh_loc_ctl_wh --倉庫の場合
----        AND  civ_wh_code_01 = slip.whse_code
----          OR civ_wh_code_02 = slip.whse_code
----          OR civ_wh_code_03 = slip.whse_code
----        )
----     )
--      AND ( NVL(civ_wh_code_01,gv_nullvalue) = gv_nullvalue
--        AND NVL(civ_wh_code_02,gv_nullvalue) = gv_nullvalue
--        AND NVL(civ_wh_code_03,gv_nullvalue) = gv_nullvalue
--      OR (  civ_wh_loc_ctl = gv_wh_loc_ctl_loc
--        AND slip.location IN (civ_wh_code_01, civ_wh_code_02, civ_wh_code_03))
--      OR (  civ_wh_loc_ctl = gv_wh_loc_ctl_wh
--        AND  slip.whse_code IN (civ_wh_code_01, civ_wh_code_02, civ_wh_code_03)
--        )
--      )
----mod end 1.3
      AND
      (
           NVL(civ_block_01,gv_nullvalue) = gv_nullvalue
       AND NVL(civ_block_02,gv_nullvalue) = gv_nullvalue
       AND NVL(civ_block_03,gv_nullvalue) = gv_nullvalue
       AND NVL(civ_wh_code_01,gv_nullvalue) = gv_nullvalue
       AND NVL(civ_wh_code_01,gv_nullvalue) = gv_nullvalue
       AND NVL(civ_wh_code_01,gv_nullvalue) = gv_nullvalue
        --パラメータによる絞込み(物流ブロック)
        OR  slip.distribution_block IN (civ_block_01,civ_block_02,civ_block_03)
        --パラメータによる絞込み(保管倉庫)
        OR (  civ_wh_loc_ctl = gv_wh_loc_ctl_loc
          AND slip.location IN (civ_wh_code_01, civ_wh_code_02, civ_wh_code_03))
        --パラメータによる絞込み(倉庫)
        OR (  civ_wh_loc_ctl = gv_wh_loc_ctl_wh
          AND  slip.whse_code IN (civ_wh_code_01, civ_wh_code_02, civ_wh_code_03))
      )
--mod end 1.13
--mod start 1.3
--      AND ( civ_item_code_01 IS NULL
--        AND civ_item_code_02 IS NULL
--        AND civ_item_code_03 IS NULL
--      OR  civ_item_code_01 = ximv.item_no
--      OR  civ_item_code_02 = ximv.item_no
--      OR  civ_item_code_03 = ximv.item_no
--      )
      --パラメータによる絞込み(品目)
      AND ( NVL(civ_item_code_01,gv_nullvalue) = gv_nullvalue
        AND NVL(civ_item_code_02,gv_nullvalue) = gv_nullvalue
        AND NVL(civ_item_code_03,gv_nullvalue) = gv_nullvalue
      OR  ximv.item_no IN (civ_item_code_01, civ_item_code_02, civ_item_code_03)
      )
--mod end 1.3
      --パラメータによる絞込み(新区分)
--mod start 1.3
--      AND ( civ_reason_code_01 IS NULL
--        AND civ_reason_code_02 IS NULL
--        AND civ_reason_code_03 IS NULL
--      OR civ_reason_code_01 = slip.reason_code
--      OR civ_reason_code_02 = slip.reason_code
--      OR civ_reason_code_03 = slip.reason_code
--      )
      AND ( NVL(civ_reason_code_01,gv_nullvalue) = gv_nullvalue
        AND NVL(civ_reason_code_02,gv_nullvalue) = gv_nullvalue
        AND NVL(civ_reason_code_03,gv_nullvalue) = gv_nullvalue
      OR slip.reason_code IN (civ_reason_code_01, civ_reason_code_02, civ_reason_code_03)
      )
--mod end 1.3
      --パラメータによる絞込み(入出庫区分)
      AND ( civ_inout_ctl = gv_inout_ctl_all --入出庫両方を指定した場合
      OR    civ_inout_ctl = gv_inout_ctl_in  --入庫を指定した場合
        AND slip.rcv_pay_div = gv_rcvdiv_rcv   --受払区分は受入のみ対象
      OR    civ_inout_ctl = gv_inout_ctl_out --出庫を指定した場合
        AND slip.rcv_pay_div = gv_rcvdiv_pay   --受払区分は払出のみ対象
      )
      ORDER BY slip.location
              ,TO_NUMBER(ximv.item_no)
              ,slip.standard_date
              ,slip.reason_code
              ,slip.slip_no
      ;
--
  BEGIN
    -- ====================================================
    -- データ抽出
    -- ====================================================
    -- カーソルオープン
    OPEN cur_main_data(
      ir_prm.ymd_from
     ,ir_prm.ymd_to
     ,ir_prm.base_date
     ,ir_prm.inout_ctl
     ,ir_prm.prod_div
     ,ir_prm.unit_ctl
     ,ir_prm.wh_loc_ctl
     ,ir_prm.wh_code_01
     ,ir_prm.wh_code_02
     ,ir_prm.wh_code_03
     ,ir_prm.block_01
     ,ir_prm.block_02
     ,ir_prm.block_03
     ,ir_prm.item_div
     ,ir_prm.item_code_01
     ,ir_prm.item_code_02
     ,ir_prm.item_code_03
     ,ir_prm.lot_no_01
     ,ir_prm.lot_no_02
     ,ir_prm.lot_no_03
     ,ir_prm.mnfctr_date_01
     ,ir_prm.mnfctr_date_02
     ,ir_prm.mnfctr_date_03
     ,ir_prm.reason_code_01
     ,ir_prm.reason_code_02
     ,ir_prm.reason_code_03
     ,ir_prm.symbol
    );
--
    --バルクフェッチ
    FETCH cur_main_data BULK COLLECT INTO ot_main_data;
    ln_main_data_cnt := ot_main_data.count;
    --クローズ
    CLOSE cur_main_data;
--
    IF (ln_main_data_cnt > 0) THEN
      ov_retcode := gv_status_normal;
    ELSE
      ov_retcode := gv_status_warn;
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
      IF cur_main_data%ISOPEN THEN
        CLOSE cur_main_data;
      END IF;
--
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_record;
--
  /**********************************************************************************
   * Procedure Name   : check_parameter
   * Description      : パラメータチェック ==> (OPTION)
   ***********************************************************************************/
  PROCEDURE check_parameter(
    ir_prm        IN  rec_param_data
   ,ov_errbuf     OUT VARCHAR2     --   エラー・メッセージ           --# 固定 #
   ,ov_retcode    OUT VARCHAR2     --   リターン・コード             --# 固定 #
   ,ov_errmsg     OUT VARCHAR2     --   ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_parameter'; -- プログラム名
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
    lb_item_01_p   BOOLEAN;
    lb_item_01_i   BOOLEAN;
    lb_item_02_p   BOOLEAN;
    lb_item_02_i   BOOLEAN;
    lb_item_03_p   BOOLEAN;
    lb_item_03_i   BOOLEAN;
--
    lb_wh_code_01  BOOLEAN;
    lb_wh_code_02  BOOLEAN;
    lb_wh_code_03  BOOLEAN;
--
    lb_block_01    BOOLEAN;
    lb_block_02    BOOLEAN;
    lb_block_03    BOOLEAN;
--
    lv_err_code    VARCHAR2(100);
--
    -- *** ローカル・カーソル ***
    -- ===============================================
    -- OPM品目マスタチェック用カーソル
    -- ===============================================
    CURSOR cur_item(
      civ_item_01 VARCHAR2
     ,civ_item_02 VARCHAR2
     ,civ_item_03 VARCHAR2
--add start 1.12
     ,civ_prod_div VARCHAR2
     ,civ_item_div VARCHAR2
--add end 1.12
    )
    IS
      SELECT xicv.category_set_name                           category_set_name   --カテゴリセット名
            ,xicv.item_no                                     item_no             --品目コード
      FROM   xxcmn_item_categories2_v                         xicv                --OPM品目カテゴリセット割当情報
      WHERE  xicv.category_set_name IN (gv_category_prod,gv_category_item)        --カテゴリセット名(商品区分,品目区分)
      AND    xicv.item_no IN (civ_item_01,civ_item_02,civ_item_03)                --品目コード(パラメータ.品目1～3)
      AND    xicv.enabled_flag = 'Y'                                              --使用可能フラグ
      AND    xicv.disable_date IS NULL                                            --無効日
--add start 1.12
      AND   (xicv.category_set_name = gv_category_prod
        AND  xicv.segment1 = NVL(civ_prod_div,xicv.segment1)
      OR     xicv.category_set_name = gv_category_item
        AND  xicv.segment1 = NVL(civ_item_div,xicv.segment1))
--add end 1.12
      ;
--
    TYPE lr_item IS RECORD(
      category_set_name xxcmn_item_categories2_v.category_set_name%TYPE
     ,item_no xxcmn_item_categories2_v.item_no%TYPE
    );
--
    TYPE lt_item_tbl IS TABLE OF lr_item INDEX BY BINARY_INTEGER;
--
    lt_item          lt_item_tbl;
--
    -- ===============================================
    -- OPM倉庫マスタ・保管場所マスタチェック用カーソル変数
    -- ===============================================
    TYPE lref_wh IS REF CURSOR;
    cur_wh         lref_wh;
    lv_wh_code     VARCHAR2(4000);
--
    -- ===============================================
    -- OPM保管場所マスタチェック用カーソル
    -- ===============================================
    CURSOR cur_block(
      civ_block_01 VARCHAR2
     ,civ_block_02 VARCHAR2
     ,civ_block_03 VARCHAR2
    )
    IS
      SELECT xilv.distribution_block                          block_name          --ブロック
      FROM   xxcmn_item_locations2_v                          xilv                --OPM保管場所情報
      WHERE  xilv.distribution_block IN (civ_block_01,civ_block_02,civ_block_03)  --ブロック
      AND    xilv.disable_date IS NULL                                            --無効日
      ;
--
    -- *** ローカル・例外 ***
    data_check_expt              EXCEPTION ;             -- データチェックエクセプション
--
  BEGIN
--
    -- ===============================================
    -- 年月日FROM,TOチェック
    -- ===============================================
    IF (ir_prm.ymd_from > ir_prm.ymd_to) THEN
      lv_err_code := gv_xxinv_10096;
      RAISE data_check_expt;
    END IF;
--
    -- ===============================================
    -- 品目マスタチェック
    -- ===============================================
    IF ((ir_prm.item_code_01 IS NULL)
    AND (ir_prm.item_code_02 IS NULL)
    AND (ir_prm.item_code_03 IS NULL)) THEN
      --品目が何も指定されなかった場合はチェックしない
      NULL;
    ELSE
      --品目・カテゴリ取得カーソルOPEN
      OPEN cur_item (
        ir_prm.item_code_01
       ,ir_prm.item_code_02
       ,ir_prm.item_code_03
--add start 1.12
       ,ir_prm.prod_div
       ,ir_prm.item_div
--add end 1.12
      );
      --バルクフェッチ
      FETCH cur_item BULK COLLECT INTO lt_item;
      --クローズ
      CLOSE cur_item;
--
      --品目1の真偽値を初期設定
      IF (ir_prm.item_code_01 IS NULL) THEN
        lb_item_01_p := TRUE;
        lb_item_01_i := TRUE;
      ELSE
        lb_item_01_p := FALSE;
        lb_item_01_i := FALSE;
      END IF;
--
      --品目2の真偽値を初期設定
      IF (ir_prm.item_code_02 IS NULL) THEN
        lb_item_02_p := TRUE;
        lb_item_02_i := TRUE;
      ELSE
        lb_item_02_p := FALSE;
        lb_item_02_i := FALSE;
      END IF;
--
      --品目3の真偽値を初期設定
      IF (ir_prm.item_code_03 IS NULL) THEN
        lb_item_03_p := TRUE;
        lb_item_03_i := TRUE;
      ELSE
        lb_item_03_p := FALSE;
        lb_item_03_i := FALSE;
      END IF;
--
      <<item_loop>>
      FOR i IN 1..lt_item.COUNT LOOP
--
        --カテゴリセット.商品区分チェック
        IF (lt_item(i).category_set_name = gv_category_prod) THEN
          IF (lt_item(i).item_no = ir_prm.item_code_01) THEN
            lb_item_01_p := TRUE;
          ELSIF (lt_item(i).item_no = ir_prm.item_code_02) THEN
            lb_item_02_p := TRUE;
          ELSIF (lt_item(i).item_no = ir_prm.item_code_03) THEN
            lb_item_03_p := TRUE;
          END IF;
        END IF;
--
        --カテゴリセット.品目区分チェック
        IF (lt_item(i).category_set_name = gv_category_item) THEN
          IF (lt_item(i).item_no = ir_prm.item_code_01) THEN
            lb_item_01_i := TRUE;
          ELSIF (lt_item(i).item_no = ir_prm.item_code_02) THEN
            lb_item_02_i := TRUE;
          ELSIF (lt_item(i).item_no = ir_prm.item_code_03) THEN
            lb_item_03_i := TRUE;
          END IF;
        END IF;
--
      END LOOP item_loop;
--
--
      IF (lb_item_01_p AND lb_item_02_p AND lb_item_03_p
      AND lb_item_01_i AND lb_item_02_i AND lb_item_03_i) THEN
        NULL;
      ELSE
        lv_err_code := gv_xxinv_10111;
        RAISE data_check_expt;
      END IF;
    END IF;
--
    -- ===============================================
    -- 倉庫マスタチェック
    -- ===============================================
    IF ((ir_prm.wh_code_01 IS NULL)
    AND (ir_prm.wh_code_02 IS NULL)
    AND (ir_prm.wh_code_03 IS NULL)) THEN
      NULL;
    ELSE
      --倉庫保管倉庫区分=倉庫の場合
      IF (ir_prm.wh_loc_ctl = gv_wh_loc_ctl_wh) THEN
        OPEN cur_wh FOR
          SELECT xilv.whse_code                               wh_code             --倉庫コード
          FROM   xxcmn_item_locations2_v                      xilv                --倉庫マスタ
          WHERE  xilv.whse_code IN (ir_prm.wh_code_01,ir_prm.wh_code_02,ir_prm.wh_code_03)
          AND    xilv.disable_date IS NULL                                        --無効日
          ;
      --倉庫保管倉庫区分=保管倉庫の場合
      ELSIF (ir_prm.wh_loc_ctl = gv_wh_loc_ctl_loc) THEN
        OPEN cur_wh FOR
          SELECT xilv.segment1                                wh_code             --保管倉庫コード
          FROM   xxcmn_item_locations2_v                      xilv                --保管倉庫マスタ
          WHERE  xilv.segment1 IN (ir_prm.wh_code_01,ir_prm.wh_code_02,ir_prm.wh_code_03)
          AND    xilv.disable_date IS NULL                                        --無効日
          ;
      END IF;
--
      --倉庫1の真偽値を初期設定
      IF (ir_prm.wh_code_01 IS NULL) THEN
        lb_wh_code_01 := TRUE;
      ELSE
        lb_wh_code_01 := FALSE;
      END IF;
--
      --倉庫2の真偽値を初期設定
      IF (ir_prm.wh_code_02 IS NULL) THEN
        lb_wh_code_02 := TRUE;
      ELSE
        lb_wh_code_02 := FALSE;
      END IF;
--
      --倉庫3の真偽値を初期設定
      IF (ir_prm.wh_code_03 IS NULL) THEN
        lb_wh_code_03 := TRUE;
      ELSE
        lb_wh_code_03 := FALSE;
      END IF;
--
      <<wh_loop>>
      LOOP
        FETCH cur_wh INTO lv_wh_code;
        EXIT WHEN cur_wh%NOTFOUND;
--
        IF (lv_wh_code = ir_prm.wh_code_01) THEN
          lb_wh_code_01 := TRUE;
        END IF;
--
        IF (lv_wh_code = ir_prm.wh_code_02) THEN
          lb_wh_code_02 := TRUE;
        END IF;
--
        IF (lv_wh_code = ir_prm.wh_code_03) THEN
          lb_wh_code_03 := TRUE;
        END IF;
--
      END LOOP wh_loop;
--
      --カーソルクローズ
      CLOSE cur_wh;
--
      IF (lb_wh_code_01 AND lb_wh_code_02 AND lb_wh_code_03) THEN
        NULL;
      ELSE
        --倉庫保管倉庫選択区分が倉庫の場合
        IF (ir_prm.wh_loc_ctl = gv_wh_loc_ctl_wh) THEN
          lv_err_code := gv_xxinv_10112;
        --倉庫保管倉庫選択区分が保管倉庫の場合
        ELSIF (ir_prm.wh_loc_ctl = gv_wh_loc_ctl_loc) THEN
          lv_err_code := gv_xxinv_10153;
        END IF;
        RAISE data_check_expt;
      END IF;
--
    END IF;
--
    -- ===============================================
    -- 物流ブロックチェック
    -- ===============================================
    IF ((ir_prm.block_01 IS NULL)
    AND (ir_prm.block_02 IS NULL)
    AND (ir_prm.block_03 IS NULL)) THEN
      NULL;
    ELSE
      --ブロック1の真偽値を初期設定
      IF (ir_prm.block_01 IS NULL) THEN
        lb_block_01 := TRUE;
      ELSE
        lb_block_01 := FALSE;
      END IF;
--
      --ブロック2の真偽値を初期設定
      IF (ir_prm.block_02 IS NULL) THEN
        lb_block_02 := TRUE;
      ELSE
        lb_block_02 := FALSE;
      END IF;
--
      --ブロック3の真偽値を初期設定
      IF (ir_prm.block_03 IS NULL) THEN
        lb_block_03 := TRUE;
      ELSE
        lb_block_03 := FALSE;
      END IF;
--
      <<block_loop>>
      FOR rec_block IN cur_block(ir_prm.block_01, ir_prm.block_02, ir_prm.block_03) LOOP
        IF (rec_block.block_name = ir_prm.block_01) THEN
          lb_block_01 := TRUE;
        END IF;
--
        IF (rec_block.block_name = ir_prm.block_02) THEN
          lb_block_02 := TRUE;
        END IF;
--
        IF (rec_block.block_name = ir_prm.block_03) THEN
          lb_block_03 := TRUE;
        END IF;
--
      END LOOP block_loop;
--
      IF  (lb_block_01 AND lb_block_02 AND lb_block_03) THEN
        NULL;
      ELSE
        lv_err_code := gv_xxinv_10113;
        RAISE data_check_expt;
      END IF;
--
    END IF;
--
    ov_retcode := gv_status_normal;
--
  EXCEPTION
    WHEN data_check_expt THEN
      -- メッセージセット
      lv_errmsg := xxcmn_common_pkg.get_msg( gc_application_inv
                                            ,lv_err_code    ) ;
      ov_errmsg  := lv_errmsg ;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error ;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
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
      IF cur_item%ISOPEN THEN
        CLOSE cur_item;
      END IF;
--
      IF cur_wh%ISOPEN THEN
        CLOSE cur_wh;
      END IF;
--
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END check_parameter;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    iv_ymd_from          IN     VARCHAR2         --    1. 年月日_FROM
   ,iv_ymd_to            IN     VARCHAR2         --    2. 年月日_TO
   ,iv_base_date         IN     VARCHAR2         --    3. 着日基準／発日基準
   ,iv_inout_ctl         IN     VARCHAR2         --    4. 入出庫区分
   ,iv_prod_div          IN     VARCHAR2         --    5. 商品区分
   ,iv_unit_ctl          IN     VARCHAR2         --    6. 単位区分
   ,iv_wh_loc_ctl        IN     VARCHAR2         --    7. 倉庫/保管倉庫選択区分
   ,iv_wh_code_01        IN     VARCHAR2         --    8. 倉庫/保管倉庫コード1
   ,iv_wh_code_02        IN     VARCHAR2         --    9. 倉庫/保管倉庫コード2
   ,iv_wh_code_03        IN     VARCHAR2         --   10. 倉庫/保管倉庫コード3
   ,iv_block_01          IN     VARCHAR2         --   11. ブロック1
   ,iv_block_02          IN     VARCHAR2         --   12. ブロック2
   ,iv_block_03          IN     VARCHAR2         --   13. ブロック3
   ,iv_item_div          IN     VARCHAR2         --   14. 品目区分
   ,iv_item_code_01      IN     VARCHAR2         --   15. 品目コード1
   ,iv_item_code_02      IN     VARCHAR2         --   16. 品目コード2
   ,iv_item_code_03      IN     VARCHAR2         --   17. 品目コード3
   ,iv_lot_no_01         IN     VARCHAR2         --   18. ロットNo1
   ,iv_lot_no_02         IN     VARCHAR2         --   19. ロットNo2
   ,iv_lot_no_03         IN     VARCHAR2         --   20. ロットNo3
   ,iv_mnfctr_date_01    IN     VARCHAR2         --   21. 製造年月日1
   ,iv_mnfctr_date_02    IN     VARCHAR2         --   22. 製造年月日2
   ,iv_mnfctr_date_03    IN     VARCHAR2         --   23. 製造年月日3
   ,iv_reason_code_01    IN     VARCHAR2         --   24. 事由コード1
   ,iv_reason_code_02    IN     VARCHAR2         --   25. 事由コード2
   ,iv_reason_code_03    IN     VARCHAR2         --   26. 事由コード3
   ,iv_symbol            IN     VARCHAR2         --   27. 固有記号
   ,ov_errbuf            OUT    VARCHAR2         --   エラー・メッセージ           --# 固定 #
   ,ov_retcode           OUT    VARCHAR2         --   リターン・コード             --# 固定 #
   ,ov_errmsg            OUT    VARCHAR2         --   ユーザー・エラー・メッセージ --# 固定 #
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
    -- *** ローカル変数 ***
    lr_prm           rec_param_data;
    lt_main_data     tab_main_data;
    lv_output_mode   NUMBER;
--
  BEGIN
--dbms_output.put_line('submain start');
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ===============================================
    -- 入力パラメータ レコード変数セット
    -- ===============================================
    lr_prm.ymd_from        := SUBSTRB(iv_ymd_from,1,10);
    lr_prm.ymd_to          := SUBSTRB(iv_ymd_to,1,10);
    lr_prm.base_date       := iv_base_date;
    lr_prm.inout_ctl       := iv_inout_ctl;
    lr_prm.prod_div        := iv_prod_div;
    lr_prm.unit_ctl        := iv_unit_ctl;
    lr_prm.wh_loc_ctl      := iv_wh_loc_ctl;
    lr_prm.wh_code_01      := iv_wh_code_01;
    lr_prm.wh_code_02      := iv_wh_code_02;
    lr_prm.wh_code_03      := iv_wh_code_03;
    lr_prm.block_01        := iv_block_01;
    lr_prm.block_02        := iv_block_02;
    lr_prm.block_03        := iv_block_03;
    lr_prm.item_div        := iv_item_div;
    lr_prm.item_code_01    := iv_item_code_01;
    lr_prm.item_code_02    := iv_item_code_02;
    lr_prm.item_code_03    := iv_item_code_03;
    lr_prm.lot_no_01       := iv_lot_no_01;
    lr_prm.lot_no_02       := iv_lot_no_02;
    lr_prm.lot_no_03       := iv_lot_no_03;
    lr_prm.mnfctr_date_01  := SUBSTRB(iv_mnfctr_date_01,1,10);
    lr_prm.mnfctr_date_02  := SUBSTRB(iv_mnfctr_date_02,1,10);
    lr_prm.mnfctr_date_03  := SUBSTRB(iv_mnfctr_date_03,1,10);
    lr_prm.reason_code_01  := iv_reason_code_01;
    lr_prm.reason_code_02  := iv_reason_code_02;
    lr_prm.reason_code_03  := iv_reason_code_03;
    lr_prm.symbol          := iv_symbol;
--
    -- ===============================================
    -- プロファイル取得
    -- ===============================================
    BEGIN
      SELECT
        FND_PROFILE.VALUE(gv_prf_prod_div) --商品区分
       ,FND_PROFILE.VALUE(gv_prf_item_div) --品目区分
      INTO
        gv_category_prod
       ,gv_category_item
      FROM DUAL
      ;
    EXCEPTION
      WHEN OTHERS THEN
        NULL;
    END;
    -- ===============================================
    -- 入力パラメータチェック
    -- ===============================================
    check_parameter(
      lr_prm            -- 入力パラメータ
     ,lv_errbuf         -- エラー・メッセージ           --# 固定 #
     ,lv_retcode        -- リターン・コード             --# 固定 #
     ,lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================================
    -- データ抽出処理
    -- ===============================================
    get_record(
      lr_prm            -- 入力パラメータ
     ,lt_main_data      -- 抽出データ
     ,lv_errbuf         -- エラー・メッセージ           --# 固定 #
     ,lv_retcode        -- リターン・コード             --# 固定 #
     ,lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    IF (lv_retcode = gv_status_error) THEN
      --エラー発生
      RAISE global_process_expt;
    ELSIF (lv_retcode = gv_status_warn) THEN
      --対象データ0件
      lv_output_mode := gv_output_notfound;
    ELSIF (lv_retcode = gv_status_normal) THEN
      --正常
      -- ===============================================
      -- XMLデータ作成
      -- ===============================================
      create_xml(
        xml_data_table
       ,lr_prm
       ,lt_main_data
       ,lv_errbuf         -- エラー・メッセージ           --# 固定 #
       ,lv_retcode        -- リターン・コード             --# 固定 #
       ,lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
      );
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt ;
      END IF ;
--
      lv_output_mode := gv_output_normal;
--
    END IF;
--
    -- ===============================================
    -- XMLデータ出力
    -- ===============================================
    output_xml(
      iox_xml_data   => xml_data_table  -- XMLデータ
     ,iv_output_mode => lv_output_mode
     ,ov_errbuf      => lv_errbuf       -- エラー・メッセージ           --# 固定 #
     ,ov_retcode     => lv_retcode      -- リターン・コード             --# 固定 #
     ,ov_errmsg      => lv_errmsg
    ) ;
  --
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt ;
    ELSIF (lv_retcode = gv_status_warn) THEN
      ov_retcode := lv_retcode;
      ov_errmsg := lv_errmsg;
    END IF ;
--
  EXCEPTION
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
    errbuf               OUT    VARCHAR2         --   エラー・メッセージ  --# 固定 #
   ,retcode              OUT    VARCHAR2         --   リターン・コード    --# 固定 #
   ,iv_ymd_from          IN     VARCHAR2         --    1. 年月日_FROM
   ,iv_ymd_to            IN     VARCHAR2         --    2. 年月日_TO
   ,iv_base_date         IN     VARCHAR2         --    3. 着日基準／発日基準
   ,iv_inout_ctl         IN     VARCHAR2         --    4. 入出庫区分
   ,iv_prod_div          IN     VARCHAR2         --    5. 商品区分
   ,iv_unit_ctl          IN     VARCHAR2         --    6. 単位区分
   ,iv_wh_loc_ctl        IN     VARCHAR2         --    7. 倉庫/保管倉庫選択区分
   ,iv_wh_code_01        IN     VARCHAR2         --    8. 倉庫/保管倉庫コード1
   ,iv_wh_code_02        IN     VARCHAR2         --    9. 倉庫/保管倉庫コード2
   ,iv_wh_code_03        IN     VARCHAR2         --   10. 倉庫/保管倉庫コード3
   ,iv_block_01          IN     VARCHAR2         --   11. ブロック1
   ,iv_block_02          IN     VARCHAR2         --   12. ブロック2
   ,iv_block_03          IN     VARCHAR2         --   13. ブロック3
   ,iv_item_div          IN     VARCHAR2         --   14. 品目区分
   ,iv_item_code_01      IN     VARCHAR2         --   15. 品目コード1
   ,iv_item_code_02      IN     VARCHAR2         --   16. 品目コード2
   ,iv_item_code_03      IN     VARCHAR2         --   17. 品目コード3
   ,iv_lot_no_01         IN     VARCHAR2         --   18. ロットNo1
   ,iv_lot_no_02         IN     VARCHAR2         --   19. ロットNo2
   ,iv_lot_no_03         IN     VARCHAR2         --   20. ロットNo3
   ,iv_mnfctr_date_01    IN     VARCHAR2         --   21. 製造年月日1
   ,iv_mnfctr_date_02    IN     VARCHAR2         --   22. 製造年月日2
   ,iv_mnfctr_date_03    IN     VARCHAR2         --   23. 製造年月日3
   ,iv_reason_code_01    IN     VARCHAR2         --   24. 事由コード1
   ,iv_reason_code_02    IN     VARCHAR2         --   25. 事由コード2
   ,iv_reason_code_03    IN     VARCHAR2         --   26. 事由コード3
   ,iv_symbol            IN     VARCHAR2         --   27. 固有記号
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
      iv_ymd_from       
     ,iv_ymd_to         
     ,iv_base_date      
     ,iv_inout_ctl      
     ,iv_prod_div       
     ,iv_unit_ctl       
     ,iv_wh_loc_ctl     
     ,iv_wh_code_01     
     ,iv_wh_code_02     
     ,iv_wh_code_03     
     ,iv_block_01       
     ,iv_block_02       
     ,iv_block_03       
     ,iv_item_div       
     ,iv_item_code_01   
     ,iv_item_code_02   
     ,iv_item_code_03   
     ,iv_lot_no_01      
     ,iv_lot_no_02      
     ,iv_lot_no_03      
     ,iv_mnfctr_date_01 
     ,iv_mnfctr_date_02 
     ,iv_mnfctr_date_03 
     ,iv_reason_code_01 
     ,iv_reason_code_02 
     ,iv_reason_code_03 
     ,iv_symbol         
     ,lv_errbuf          -- エラー・メッセージ           --# 固定 #
     ,lv_retcode         -- リターン・コード             --# 固定 #
     ,lv_errmsg          -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
--###########################  固定部 START   #####################################################
--
    -- ======================
    -- エラー・メッセージ出力
    -- ======================
    IF ( lv_retcode = gv_status_error ) THEN
      errbuf := lv_errmsg ;
      put_line(FND_FILE.LOG,lv_errbuf) ;
    ELSIF ( lv_retcode = gv_status_warn ) THEN
      put_line(FND_FILE.LOG,lv_errmsg) ;
    END IF ;
--
    --ステータスセット
    retcode := lv_retcode;
--
  EXCEPTION
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      retcode := gv_status_error;
  END main;
--
--###########################  固定部 END   #######################################################
--
END XXINV550002C;
/
