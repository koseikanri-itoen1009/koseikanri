CREATE OR REPLACE PACKAGE BODY xxpo440005c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxpo440005(body)
 * Description      : 有償明細表
 * MD.050/070       : 有償支給帳票Issue1.0(T_MD050_BPO_444)
 *                    有償支給帳票Issue1.0(T_MD070_BPO_44M)
 * Version          : 1.5
 *
 * Program List
 * ---------------------------- ----------------------------------------------------------
 *  Name                        Description
 * ---------------------------- ----------------------------------------------------------
 *  prc_create_xml_data_user    PROCEDURE : タグ出力 - ユーザー情報 (M-1)
 *  prc_create_sql              PROCEDURE : データ取得ＳＱＬ生成 (M-2)
 *  prc_create_xml_data         PROCEDURE : ＸＭＬデータ編集 (M-3)
 *  convert_into_xml            FUNCTION  : ＸＭＬタグに変換する。
 *  submain                     PROCEDURE : メイン処理プロシージャ
 *  main                        PROCEDURE : コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/04/19    1.0   Yusuke Tabata   新規作成
 *  2008/05/20    1.1   Yusuke Tabata   内部変更要求Seq95(日付型パラメータ型変換)対応
 *  2008/06/03    1.2   Yohei  Takayama 結合テスト不具合#440_46対応
 *  2008/06/04    1.3 Yasuhisa Yamamoto 結合テスト不具合ログ#440_54
 *  2008/06/19    1.4   Kazuo Kumamoto  結合テストレビュー指摘事項#18対応
 *  2008/07/02    1.5   Satoshi Yunba   禁則文字「'」「"」「<」「>」「&」対応
 *
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
  -- ===============================================================================================
  -- ユーザー宣言部
  -- ===============================================================================================
  -- ==================================================
  -- グローバル定数
  -- ==================================================
-- 2008/06/04 UPD START Y.Yamamoto
--  gc_pkg_name             CONSTANT VARCHAR2(20) := 'xxpo440005C' ;      -- パッケージ名
--  gc_report_id            CONSTANT VARCHAR2(20) := 'xxpo440005T' ;      -- 帳票ID
  gc_pkg_name             CONSTANT VARCHAR2(20) := 'XXPO440005C' ;      -- パッケージ名
  gc_report_id            CONSTANT VARCHAR2(20) := 'XXPO440005T' ;      -- 帳票ID
-- 2008/06/04 UPD END Y.Yamamoto
  gc_application          CONSTANT VARCHAR2(5)  := 'XXCMN' ;            -- アプリケーション
  gc_application_po       CONSTANT VARCHAR2(5)  := 'XXPO' ;             -- アプリケーション
  gc_err_code_no_data     CONSTANT VARCHAR2(15) := 'APP-XXCMN-10122';   -- データ０件メッセージ
  gc_err_code_no_prof     CONSTANT VARCHAR2(15) := 'APP-XXPO-10005' ;   -- プロファイル取得エラー
--
  ------------------------------
  -- プロファイル名
  ------------------------------
  gc_prof_org_id          CONSTANT VARCHAR2(20) := 'ORG_ID' ;   -- 営業単位
  gn_prof_org_id          oe_transaction_types_all.org_id%TYPE ;
--
  ------------------------------
  -- 参照コード
  ------------------------------
  -- 受注カテゴリ：受注カテゴリコード
  gc_order_cat_r          CONSTANT VARCHAR2(10) := 'RETURN' ; -- 返品
  gc_order_cat_o          CONSTANT VARCHAR2(10) := 'ORDER'  ; -- 受注
  -- 受注カテゴリ：出荷支給区分
  gc_sp_class_prov        CONSTANT VARCHAR2(1)  := '2' ;    -- 支給依頼
  -- 受注カテゴリ：出荷支給受払カテゴリ
  gc_sp_category_s        CONSTANT VARCHAR2(2)  := '05' ;   -- 有償出荷
--add start 1.4
  gc_sp_category_r        CONSTANT VARCHAR2(2)  := '06' ;   -- 有償返品
--add end 1.4
  -- 受注ヘッダアドオン：最新フラグ（YesNo区分）
  gc_yn_div_y             CONSTANT VARCHAR2(1)  := 'Y' ;    -- YES
  gc_yn_div_n             CONSTANT VARCHAR2(1)  := 'N' ;    -- NO
  -- 受注ヘッダアドオン：ステータス
  gc_req_status_p_ccl     CONSTANT VARCHAR2(2)  := '99';    -- 取消
  -- 受注ヘッダアドオン：有償金額確定区分
  gc_amount_fix_cmpc      CONSTANT VARCHAR2(1)  := '1' ;    -- 確定済
  -- 移動ロット詳細アドオン：文書タイプ
  gc_doc_type_prov        CONSTANT VARCHAR2(2)  := '30';    -- 支給指示
  -- 移動ロット詳細アドオン：レコードタイプ
  gc_rec_type_stck        CONSTANT VARCHAR2(2)  := '20';    -- 出庫実績
  -- ＯＰＭ品目マスタ：ロット管理区分
  gc_lot_ctl_y            CONSTANT NUMBER(1)    := 1 ;      -- ロット管理あり
  gc_lot_ctl_n            CONSTANT NUMBER(1)    := 0 ;      -- ロット管理なし
  -- ＯＰＭ品目カテゴリ：品目区分
  gc_item_div_prod        CONSTANT VARCHAR2(1)  := '5' ;    -- 製品
  ------------------------------
  -- その他
  ------------------------------
  -- 返品訂正判定
  gc_rtn_sign_y     CONSTANT VARCHAR2(1)  := '1' ;   -- 返品or返品訂正
  gc_rtn_sign_n     CONSTANT VARCHAR2(1)  := '0' ;   -- 返品or返品訂正外
  -- 最大日付
  gc_max_date_char  CONSTANT VARCHAR2(10) := '4712/12/31' ;
  -- 日付マスク
  gc_date_mask      CONSTANT VARCHAR2(21) := 'YYYY/MM/DD HH24:MI:SS' ; -- 年月日時分秒マスク
  gc_date_mask_m    CONSTANT VARCHAR2(8)  := 'YY/MM/DD' ;              -- 年月日(YY/MM/DD)マスク
  gc_date_mask_s    CONSTANT VARCHAR2(21) := 'MM/DD' ;                 -- 月日マスク
  gc_date_mask_ja   CONSTANT VARCHAR2(19) := 'YYYY"年"MM"月"DD"日' ;   -- 年月日(JA)マスク
  -- 出力
  gc_tag_type_t     CONSTANT VARCHAR2(1)  := 'T' ;
  gc_tag_type_d     CONSTANT VARCHAR2(1)  := 'D' ;
--
  -- ==================================================
  -- ユーザー定義グローバル型
  -- ==================================================
--
  -- 入力パラメータ格納用レコード変数
  TYPE rec_param_data  IS RECORD
    (
      date_from          VARCHAR2(10) -- 01 : 出庫日From
     ,date_to            VARCHAR2(10) -- 02 : 出庫日To
     ,prod_div           VARCHAR2(1)  -- 03 : 商品区分
     ,dept_code          VARCHAR2(4)  -- 04 : 担当部署
     ,vendor_code_01     VARCHAR2(4)  -- 05 : 取引先１
     ,vendor_code_02     VARCHAR2(4)  -- 06 : 取引先２
     ,vendor_code_03     VARCHAR2(4)  -- 07 : 取引先３
     ,vendor_code_04     VARCHAR2(4)  -- 08 : 取引先４
     ,vendor_code_05     VARCHAR2(4)  -- 09 : 取引先５
     ,item_div           VARCHAR2(1)  -- 10 : 品目区分
     ,crowd_code_01      VARCHAR2(4)  -- 11 : 群１
     ,crowd_code_02      VARCHAR2(4)  -- 12 : 群２
     ,crowd_code_03      VARCHAR2(4)  -- 13 : 群３
     ,item_code_01       VARCHAR2(7)  -- 14 : 品目１
     ,item_code_02       VARCHAR2(7)  -- 15 : 品目２
     ,item_code_03       VARCHAR2(7)  -- 16 : 品目３
     ,security_div       VARCHAR2(1)  -- 17 : 有償セキュリティ区分
    ) ;
--
  -- 抽出データ格納用レコード変数
  TYPE rec_data_type_dtl IS RECORD
    (
       prod_div_type     xxcmn_item_categories4_v.prod_class_code%TYPE      -- 商品区分（商品区分コード）
      ,prod_div_name     xxcmn_item_categories4_v.prod_class_name%TYPE      -- 商品区分（商品区分名）
      ,dept_code         xxcmn_locations2_v.location_code%TYPE              -- 担当部署（部署コード）
      ,dept_name         xxcmn_locations2_v.location_name%TYPE              -- 担当部署（部署名）
      ,vendor_code       xxcmn_vendors2_v.segment1%TYPE                     -- 配送先（配送先コード）
      ,vendor_name       xxcmn_vendors2_v.vendor_short_name%TYPE            -- 配送先（配送先名）
      ,item_div_type     xxcmn_item_categories4_v.item_class_code%TYPE      -- 品目区分(品目区分コード)
      ,item_div_name     xxcmn_item_categories4_v.item_class_name%TYPE      -- 品目区分（品目区分名
      ,crowd_code        xxcmn_item_categories4_v.crowd_code%TYPE           -- 群（群コード）
      ,item_code         xxcmn_item_mst2_v.item_no%TYPE                     -- 品目（品目コード）
      -- 2008/06/03 UPD START Y.Takayama
      --,item_name         xxcmn_item_mst2_v.item_desc1%TYPE                  -- 品目（品目名）
      ,item_name         xxcmn_item_mst2_v.item_short_name%TYPE             -- 品目（品目名）
      -- 2008/06/03 UPD END   Y.Takayama
      ,futai_code        xxwsh_order_lines_all.futai_code%TYPE              -- 付帯
      ,shipped_date      VARCHAR2(5)                                        -- 出庫日(MM/DD)
      ,lot_no            ic_lots_mst.lot_no%TYPE                            -- ロットNo
      ,maked_date        ic_lots_mst.attribute1%TYPE                        -- 製造日
      ,limit_date        ic_lots_mst.attribute3%TYPE                        -- 賞味期限
      ,orgn_sign         ic_lots_mst.attribute2%TYPE                        -- 固有記号
      ,arrival_date      VARCHAR2(5)                                        -- 入庫日(MM/DD)
      ,request_no        xxwsh_order_headers_all.request_no%TYPE            -- 依頼No
      ,entry_quant       xxcmn_item_mst2_v.frequent_qty%TYPE                -- 入数
      ,quant             xxinv_mov_lot_details.actual_quantity%TYPE         -- 総数
      ,unit              xxwsh_order_lines_all.uom_code%TYPE                -- 単位
      ,unt_price         xxwsh_order_lines_all.unit_price%TYPE              -- 単価
      ,price             NUMBER                                             -- 金額
      ,rtn_sign          VARCHAR2(1)                                        -- 返品訂正
      ,deliver_to        xxcmn_vendor_sites2_v.vendor_site_code%TYPE        -- 配送先
      ,dtl_desc          xxwsh_order_lines_all.line_description%TYPE        -- 明細摘要
    ) ;
--
  TYPE tab_data_type_dtl IS TABLE OF rec_data_type_dtl INDEX BY BINARY_INTEGER ;
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gr_param              rec_param_data ;      -- パラメータ
  gn_data_cnt           NUMBER DEFAULT  0 ;         -- 処理データカウンタ
  gv_sql                VARCHAR2(32000);     -- データ取得用ＳＱＬ
--
  gt_xml_data_table     XML_DATA ;            -- ＸＭＬデータタグ表
  gl_xml_idx            NUMBER DEFAULT  0 ;        -- ＸＭＬデータタグ表のインデックス
--
  -- ログインユーザーＩＤ
  gn_user_id            fnd_user.user_id%TYPE DEFAULT FND_GLOBAL.USER_ID ;
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
  /************************************************************************************************
   * Procedure Name   : prc_create_xml_data_user
   * Description      : ユーザー情報タグ出力(M-1)
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
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_create_xml_data_user' ; -- プログラム名
--
--##### 固定ローカル変数宣言部 START #################################
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--##### 固定ローカル変数宣言部 END   #################################
--
  BEGIN
--
--##### 固定ステータス初期化部 START #################################
    ov_retcode := gv_status_normal;
--##### 固定ステータス初期化部 END   #################################
--
    -- ====================================================
    -- ユーザーＧ開始タグ
    -- ====================================================
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'user_info' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
    -- ====================================================
    -- データタグ
    -- ====================================================
    -- 帳票ＩＤ
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'report_id' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := gc_report_id ;
    -- 実行日
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'exec_date' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := TO_CHAR( SYSDATE, gc_date_mask ) ;
    -- ログインユーザー：所属部署
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'exec_user_dept' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value
        := xxcmn_common_pkg.get_user_dept( gn_user_id ) ;
    -- ログインユーザー：ユーザー名
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'exec_user_name' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value
        := xxcmn_common_pkg.get_user_name( gn_user_id ) ;
--
    -- ====================================================
    -- ユーザーＧ終了タグ
    -- ====================================================
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/user_info' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
    -- ====================================================
    -- パラメータＧ開始タグ
    -- ====================================================
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'param_info' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
    -- ====================================================
    -- データタグ
    -- ====================================================
    -- 出庫日FORM
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'date_from' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value
      := TO_CHAR(FND_DATE.CANONICAL_TO_DATE(gr_param.date_from),gc_date_mask_ja) ;
    -- 出庫日TO
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'date_to' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value
      := TO_CHAR(FND_DATE.CANONICAL_TO_DATE(gr_param.date_to),gc_date_mask_ja) ;
--
    -- ====================================================
    -- パラメータＧ終了タグ
    -- ====================================================
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/param_info' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
  EXCEPTION
--##### 固定例外処理部 START #######################################################################
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
--##### 固定例外処理部 END   #######################################################################
  END prc_create_xml_data_user ;
--
  /************************************************************************************************
   * Procedure Name   : prc_create_sql(M-2)
   * Description      : データ取得ＳＱＬ生成
   ************************************************************************************************/
  PROCEDURE prc_create_sql
    (
      ov_errbuf             OUT VARCHAR2          --    エラー・メッセージ           --# 固定 #
     ,ov_retcode            OUT VARCHAR2          --    リターン・コード             --# 固定 #
     ,ov_errmsg             OUT VARCHAR2          --    ユーザー・エラー・メッセージ --# 固定 #
    )
  IS
    -- ==================================================
    -- 固定ローカル定数
    -- ==================================================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_create_sql' ; -- プログラム名
--
--##### 固定ローカル変数宣言部 START #################################
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--##### 固定ローカル変数宣言部 END   #################################
--
    -- ==================================================
    -- 変数宣言
    -- ==================================================
    lv_select     VARCHAR2(32000) ;
    lv_from       VARCHAR2(32000) ;
    lv_where      VARCHAR2(32000) ;
    lv_order_by   VARCHAR2(32000) ;
    lv_date_from  VARCHAR2(150)   ;
    lv_work_str   VARCHAR2(1500)  ;
--
  BEGIN
--
--##### 固定ステータス初期化部 START #################################
    ov_retcode := gv_status_normal;
--##### 固定ステータス初期化部 END   #################################
--
    -- ====================================================
    -- 初期処理
    -- ====================================================
    -- パラメータDATE_FROM部成形
    lv_date_from :=  'FND_DATE.STRING_TO_DATE('
    || ''''  || gr_param.date_from  ||''''
    || ',''' || gc_date_mask ||''''
    || ')'
    ;
    -- ====================================================
    -- ＳＥＬＥＣＴ句生成
    -- ====================================================
    lv_select := ' SELECT'
    || ' xic.prod_class_code           AS prod_div_type' -- 商品区分（商品区分コード）
    || ',xic.prod_class_name           AS prod_div_name' -- 商品区分（商品区分名）
    || ',xlv.location_code             AS dept_code'     -- 担当部署（部署コード）
    || ',xlv.location_name             AS dept_name'     -- 担当部署（部署名）
    || ',xvv.segment1                  AS vendor_code'   -- 取引先（取引先コード）
    || ',xvv.vendor_short_name         AS vendor_name'   -- 取引先（取引先名）
    || ',xic.item_class_code           AS item_div_type' -- 品目区分(品目区分コード)
    || ',xic.item_class_name           AS item_div_name' -- 品目区分（品目区分名)
    || ',xic.crowd_code                AS crowd_code'    -- 群（群コード）
    || ',xim.item_no                   AS item_code'     -- 品目（品目コード）
    -- 2008/06/03 UPD START Y.Takayama
    --|| ',xim.item_desc1                AS item_name'     -- 品目（品目名）
    || ',xim.item_short_name           AS item_name'     -- 品目（品目名）
    -- 2008/06/03 UPD END   Y.Takayama
    || ',xola.futai_code               AS futai_code'    -- 付帯
    || ',TO_CHAR(xoha.shipped_date,'
    || '''' || gc_date_mask_s || ''' ) AS shipped_date'  -- 出庫日(MN/DD)
    -- ロット情報出力:ロット管理品判定
    || ',CASE xim.lot_ctl'
    || '   WHEN '  || gc_lot_ctl_y || ' THEN'
    || '     ilm.lot_no'
    || '   ELSE '
    || '     NULL'
    || ' END                           AS lot_no'        -- ロットNo
    || ',CASE xim.lot_ctl'
    || '   WHEN '  || gc_lot_ctl_y || ' THEN'
    || '     TO_CHAR(FND_DATE.CANONICAL_TO_DATE(ilm.attribute1)'
    || '             ,''' || gc_date_mask_m || ''')'
    || '   ELSE'
    || '     NULL'
    || ' END                           AS maked_date'    -- 製造日
    || ',CASE xim.lot_ctl'
    || '   WHEN '  || gc_lot_ctl_y || ' THEN'
    || '     TO_CHAR(FND_DATE.CANONICAL_TO_DATE(ilm.attribute3)'
    || '             ,''' || gc_date_mask_m || ''')'
    || '   ELSE'
    || '     NULL'
    || ' END                           AS limit_date'    -- 賞味期限
    || ',CASE xim.lot_ctl'
    || '   WHEN '  || gc_lot_ctl_y || ' THEN'
    || '     ilm.attribute2'
    || '   ELSE'
    || '     NULL'
    || ' END                           AS orgn_sign'     -- 固有記号
    || ',TO_CHAR(xoha.arrival_date,'
    || '''' || gc_date_mask_s || ''' ) AS arrival_date'  -- 入庫日(MM/DD)
    || ',xoha.request_no               AS request_no'    -- 依頼No
    -- 入数出力:ロット管理品判定
    || ',CASE xim.lot_ctl'
    || '   WHEN '  || gc_lot_ctl_y || ' THEN'
    || '     ilm.attribute6'
    || '   ELSE'
    || '     xim.frequent_qty'
    || ' END                           AS entry_quant'   -- 入数
    -- 総数出力:返品判定
    || ',CASE'
    || '   WHEN otta.order_category_code = ''' || gc_order_cat_r || ''' THEN'
    || '     (xmld.actual_quantity * -1)'
    || '   ELSE'
    || '     xmld.actual_quantity'
    || '   END                         AS quant'         -- 総数
    || ',xola.uom_code                 AS unit'          -- 単位
    || ',xola.unit_price               AS unt_price'     -- 単価
    || ',CASE'
    || '   WHEN otta.order_category_code = ''' || gc_order_cat_r || ''' THEN'
    || '     ROUND(xmld.actual_quantity * xola.unit_price * -1)'
    || '   ELSE'
    || '     ROUND(xmld.actual_quantity * xola.unit_price)'
    || ' END                          AS price'         -- 金額
    -- 返品訂正判定フラグ
    || ',CASE'
--mod start 1.4
--    || '   WHEN otta.attribute11 = ''' || gc_order_cat_o || '''' || ' THEN'
    || '   WHEN otta.attribute11 = ''' || gc_sp_category_r || '''' || ' THEN'
--mod end 1.4
    || '     '''  || gc_rtn_sign_y || ''''
    || '   ELSE'
    || '     '''  || gc_rtn_sign_n || ''''
    || ' END                           AS rtn_sign'     -- 返品訂正
    || ',xoha.vendor_site_code         AS deliver_to'   -- 配送先
    || ',xola.line_description         AS dtl_desc'     -- 明細摘要
    ;
--
    -- ====================================================
    -- ＦＲＯＭ句生成
    -- ====================================================
    lv_from := ' FROM'
    || ' xxwsh_order_headers_all    xoha'   -- 受注ヘッダアドオン
    || ',oe_transaction_types_all   otta'   -- 受注タイプ
    || ',xxwsh_order_lines_all      xola'   -- 受注明細アドオン
    || ',xxinv_mov_lot_details      xmld'   -- 移動ロット詳細アドオン
    || ',ic_lots_mst                ilm'    -- OPMロットマスタ
    || ',xxcmn_item_mst2_v          xim'    -- OPM品目情報View
    || ',xxcmn_item_categories4_v   xic'    -- OPM品目カテゴリ割当View
    || ',xxcmn_vendors2_v           xvv'    -- 仕入先情報View
    || ',xxcmn_locations2_v         xlv'    -- 事業所情報View
    || ',xxpo_security_supply_v    xssv'    -- 有償支給セキュリティView
    ;
--
    -- ====================================================
    -- ＷＨＥＲＥ句生成
    -- ====================================================
    lv_where := ' WHERE'
    -- 受注ヘッダアドオン絞込
    || '     xoha.latest_external_flag     = ''' || gc_yn_div_y         || ''''
    || ' AND xoha.amount_fix_class         = ''' || gc_amount_fix_cmpc  || ''''
    || ' AND xoha.req_status              <> ''' || gc_req_status_p_ccl || ''''
    || ' AND xoha.shipped_date            >=  '  || lv_date_from
     -- 受注タイプ結合
    || ' AND otta.org_id                   = '   || gn_prof_org_id
    || ' AND otta.attribute1               = ''' || gc_sp_class_prov || ''''
    || ' AND xoha.order_type_id            = otta.transaction_type_id'
    -- 受注明細アドオン結合
    || ' AND NVL( xola.delete_flag, ''' || gc_yn_div_n || ''')'
    ||                                '    = ''' || gc_yn_div_n || ''''
    || ' AND xoha.order_header_id          = xola.order_header_id'
    -- 移動ロット詳細アドオン結合
    || ' AND xmld.document_type_code       = ''' || gc_doc_type_prov || ''''
    || ' AND xmld.record_type_code         = ''' || gc_rec_type_stck || ''''
    || ' AND xola.order_line_id            = xmld.mov_line_id'
    -- OPMロットマスタ結合
    || ' AND xmld.item_id                  = ilm.item_id'
    || ' AND xmld.lot_id                   = ilm.lot_id'
    -- OPM品目情報VIEW結合
    || ' AND ' || lv_date_from || ' BETWEEN xim.start_date_active'
    || '                            AND NVL(xim.end_date_active'
    || ',FND_DATE.CANONICAL_TO_DATE(''' || gc_max_date_char || '''))'
    || ' AND xola.shipping_inventory_item_id = xim.inventory_item_id'
    -- OPM品目カテゴリ割当情報VIEW結合
    || ' AND xim.item_id                   = xic.item_id'
    -- 仕入先情報VIEW結合
    || ' AND ' || lv_date_from || '  BETWEEN xvv.start_date_active'
    || '                             AND NVL(xvv.end_date_active'
    || ',FND_DATE.CANONICAL_TO_DATE(''' || gc_max_date_char || '''))'
    || ' AND xoha.vendor_id                = xvv.vendor_id'
    -- 事業所情報VIEW結合
    || ' AND ' || lv_date_from || '  BETWEEN xlv.start_date_active'
    || '                             AND NVL(xlv.end_date_active'
    || ',FND_DATE.CANONICAL_TO_DATE(''' || gc_max_date_char || '''))'
    || ' AND xoha.performance_management_dept = xlv.location_code'
    -- 有償支給セキュリティVIEW結合
    || ' AND xssv.user_id                  = ''' || gn_user_id || ''''
    || ' AND xssv.security_class           = ''' || gr_param.security_div || ''''
    || ' AND xoha.vendor_code              = NVL(xssv.vendor_code,xoha.vendor_code)'
    || ' AND xoha.vendor_site_code         = NVL(xssv.vendor_site_code,xoha.vendor_site_code)'
    ;
--
    -- ----------------------------------------------------
    -- 任意パラメータによる条件
    -- ----------------------------------------------------
--
    -- 商品区分
    IF (gr_param.prod_div IS NOT NULL) THEN
      lv_where := lv_where
      || ' AND xic.prod_class_code = ''' || gr_param.prod_div || ''''
      ;
    END IF ;
--
    -- 担当部署
    IF (gr_param.dept_code IS NOT NULL) THEN
      lv_where := lv_where
      || ' AND xoha.performance_management_dept = ''' || gr_param.dept_code || ''''
      ;
    END IF ;
--
    -- 取引先01
    IF (gr_param.vendor_code_01 IS NOT NULL) THEN
      lv_work_str := gr_param.vendor_code_01;
    END IF;
    -- 取引先02
    IF (gr_param.vendor_code_02 IS NOT NULL) THEN
      IF (lv_work_str IS NOT NULL) THEN
        lv_work_str := lv_work_str || ',' ;
      END IF ;
      lv_work_str := lv_work_str  || gr_param.vendor_code_02 ;
    END IF;
    -- 取引先03
    IF (gr_param.vendor_code_03 IS NOT NULL) THEN
      IF (lv_work_str IS NOT NULL) THEN
        lv_work_str := lv_work_str || ',' ;
      END IF ;
      lv_work_str := lv_work_str  || gr_param.vendor_code_03 ;
    END IF;
    -- 取引先04
    IF (gr_param.vendor_code_04 IS NOT NULL) THEN
      IF (lv_work_str IS NOT NULL) THEN
        lv_work_str := lv_work_str || ',' ;
      END IF ;
      lv_work_str := lv_work_str  || gr_param.vendor_code_04 ;
    END IF ;
    -- 取引先05
    IF (gr_param.vendor_code_05 IS NOT NULL) THEN
      IF (lv_work_str IS NOT NULL) THEN
        lv_work_str := lv_work_str || ',' ;
      END IF ;
      lv_work_str := lv_work_str  || gr_param.vendor_code_05 ;
    END IF;
    IF (lv_work_str IS NOT NULL) THEN
      lv_where := lv_where
      || ' AND xoha.vendor_code IN('||lv_work_str || ')';
      lv_work_str := NULL ;
    END IF ;
--
    -- 品目区分
    IF (gr_param.item_div IS NOT NULL) THEN
      lv_where := lv_where
      || ' AND xic.item_class_code = ''' || gr_param.item_div || ''''
      ;
    END IF ;
--
    -- 群01
    IF (gr_param.crowd_code_01 IS NOT NULL) THEN
      lv_work_str := lv_work_str
      || 'AND ((xic.crowd_code like '''|| gr_param.crowd_code_01 || '%'')'
      ;
    END IF;
    -- 群02
    IF (gr_param.crowd_code_02 IS NOT NULL) THEN
      IF (lv_work_str IS NOT NULL) THEN
        lv_work_str := lv_work_str || ' OR' ;
      ELSE
        lv_work_str := lv_work_str || ' AND(' ;
      END IF;
      lv_work_str := lv_work_str
      || '  (xic.crowd_code like '''|| gr_param.crowd_code_02 || '%'')';
    END IF;
    -- 群03
    IF (gr_param.crowd_code_03 IS NOT NULL) THEN
      IF (lv_work_str IS NOT NULL) THEN
        lv_work_str := lv_work_str || ' OR' ;
      ELSE
        lv_work_str := lv_work_str || ' AND(' ;
      END IF;
      lv_work_str := lv_work_str
      || '  (xic.crowd_code like '''|| gr_param.crowd_code_03 || '%'')';
    END IF;
    IF (lv_work_str IS NOT NULL) THEN
      lv_where := lv_where
      || lv_work_str  || ')' ;
      lv_work_str := NULL;
    END IF;
--
    -- 品目01
    IF (gr_param.item_code_01 IS NOT NULL) THEN
      lv_work_str := gr_param.item_code_01;
    END IF;
    -- 品目02
    IF (gr_param.item_code_02 IS NOT NULL) THEN
      IF (lv_work_str IS NOT NULL) THEN
        lv_work_str := lv_work_str || ',' ;
      END IF ;
      lv_work_str := lv_work_str  || gr_param.item_code_02 ;
    END IF;
    -- 品目03
    IF (gr_param.item_code_03 IS NOT NULL) THEN
      IF (lv_work_str IS NOT NULL) THEN
        lv_work_str := lv_work_str || ',' ;
      END IF ;
      lv_work_str := lv_work_str  || gr_param.item_code_03 ;
    END IF;
    IF (lv_work_str IS NOT NULL) THEN
      lv_where := lv_where
      || ' AND xim.item_no IN('||lv_work_str || ')';
      lv_work_str := NULL ;
    END IF ;
--
    -- 出庫日TO
    IF (gr_param.date_to IS NOT NULL) THEN
      lv_where := lv_where
      || ' AND xoha.shipped_date'
      || '     <= FND_DATE.STRING_TO_DATE(''' || gr_param.date_to || '''' || ',''' || gc_date_mask || ''')'
      ;
    END IF ;
--
    -- ====================================================
    -- ＯＲＤＥＲ  ＢＹ句生成
    -- ====================================================
    lv_order_by := ' ORDER BY'
    || ' xic.prod_class_code'
    || ',xoha.performance_management_dept'
    || ',xoha.vendor_code'
    || ',xic.item_class_code'
    || ',xic.crowd_code'
    || ',xola.shipping_item_code'
    || ',xola.futai_code'
    || ',xoha.shipped_date'
    -- 品目区分が製品の場合は「製造年月日+固有記号」それ以外「ロットNo」
    || ',DECODE(xic.item_class_code,''' || gc_item_div_prod || ''''
    || '       ,CONCAT(ilm.attribute1,ilm.attribute2),ilm.lot_no)'
    || ',xoha.request_no'
    ;
--
    -- ====================================================
    -- ＳＱＬ生成
    -- ====================================================
    gv_sql := lv_select || lv_from || lv_where || lv_order_by ;
--
  EXCEPTION
--##### 固定例外処理部 START #######################################################################
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
--##### 固定例外処理部 END   #######################################################################
  END prc_create_sql ;
--
   /**********************************************************************************
   * Procedure Name   : prc_create_xml_data
   * Description      : ＸＭＬデータ作成(M-3)
   ***********************************************************************************/
  PROCEDURE prc_create_xml_data
    (
      ov_errbuf         OUT NOCOPY VARCHAR2         -- エラー・メッセージ
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
    -- *** ローカル定数 ***
    lc_init                 CONSTANT  VARCHAR2(1) := '*' ;
    -- *** ローカル変数 ***
    lt_data_rec        tab_data_type_dtl ;
    -- ブレイク判断用変数
    lv_prod_div_type     VARCHAR2(1)  DEFAULT lc_init ;
    ln_prod_div_count    NUMBER       DEFAULT 0;
    lv_dept_code         VARCHAR2(4)  DEFAULT lc_init ;
    ln_dept_code_count   NUMBER       DEFAULT 0;
    lv_vendor_code       VARCHAR2(4)  DEFAULT lc_init ;
    ln_vendor_code_count NUMBER       DEFAULT 0;
    lv_item_div_type     VARCHAR2(1)  DEFAULT lc_init ;
    ln_item_div_count    NUMBER       DEFAULT 0;
    lv_crowd_code        VARCHAR2(4)  DEFAULT lc_init ;
    lv_item_code         VARCHAR2(7)  DEFAULT lc_init ;
--
  BEGIN
--
    EXECUTE IMMEDIATE gv_sql BULK COLLECT INTO lt_data_rec ;
    gn_data_cnt := lt_data_rec.count ;
--
    -- ==================================
    -- 初期処理
    -- ==================================
    -- 商品区分リストグループ
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_prod_div_info';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;	
--
    <<main_data_loop>>
    FOR i IN 1..lt_data_rec.count LOOP
      -- ====================================================
      -- ブレイク判定：商品区分グループ
      -- ====================================================
      IF ( lt_data_rec(i).prod_div_type <> lv_prod_div_type ) THEN
        IF ( lv_prod_div_type <> lc_init ) THEN
          -- ----------------------------------------------------
          -- 下層グループ終了タグ出力
          -- ----------------------------------------------------
          -- 明細リストグループ
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_dtl';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- 品目グループ
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_item';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- 品目リストグループ
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_item_info';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- 群グループ
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_crowd';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- 群リストグループ
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_crowd_info';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- ノードポジション
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'in_g_cnt';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
          gt_xml_data_table(gl_xml_idx).tag_value := ln_item_div_count;
          -- 品目区分グループ
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_item_div';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- 品目区分リストグループ
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_item_div_info';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- ノードポジション
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'in_g_cnt';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
          gt_xml_data_table(gl_xml_idx).tag_value := ln_vendor_code_count;
          -- 取引先グループ
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_vendor';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- 取引先リストグループ
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_vendor_info';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- ノードポジション
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'in_g_cnt';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
          gt_xml_data_table(gl_xml_idx).tag_value := ln_dept_code_count;
          -- 担当部署グループ
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_dept';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- 担当部署リストグループ
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_dept_info';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- ノードポジション
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'in_g_cnt';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
          gt_xml_data_table(gl_xml_idx).tag_value := ln_prod_div_count;
          -- 商品区分グループ
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_prod_div';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
        END IF ;
--
        -- ----------------------------------------------------
        -- グループ開始タグ出力
        -- ----------------------------------------------------
        -- 商品区分グループ
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'g_prod_div';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
        -- 商品区分
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'prod_div_type';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := lt_data_rec(i).prod_div_type;
        -- 商品区分名
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'prod_div_name';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := lt_data_rec(i).prod_div_name;
        -- 担当部署リストグループ
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_dept_info';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
        -- TMP商品区分：セット
        lv_prod_div_type     := lt_data_rec(i).prod_div_type ;
        -- 下層G：ブレイク判定条件セット
        lv_dept_code         := lc_init ;
        lv_vendor_code       := lc_init ;
        lv_item_div_type     := lc_init ;
        lv_crowd_code        := lc_init ;
        lv_item_code         := lc_init ;
--
        -- 商品区分カウント：インクリメント
        ln_prod_div_count    := ln_prod_div_count + 1 ;
        -- 下層G内カウント ：初期化
        ln_dept_code_count   := 0 ;
        ln_vendor_code_count := 0 ;
        ln_item_div_count    := 0 ;
      END IF;
--
      -- ====================================================
      -- ブレイク判定：担当部署グループ
      -- ====================================================
      IF ( lt_data_rec(i).dept_code <> lv_dept_code ) THEN
        IF ( lv_dept_code <> lc_init ) THEN
          -- ----------------------------------------------------
          -- 下層グループ終了タグ出力
          -- ----------------------------------------------------
          -- 明細リストグループ
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_dtl';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- 品目グループ
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_item';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- 品目リストグループ
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_item_info';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- 群グループ
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_crowd';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- 群リストグループ
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_crowd_info';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- ノードポジション
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'in_g_cnt';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
          gt_xml_data_table(gl_xml_idx).tag_value := ln_item_div_count;
          -- 品目区分グループ
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_item_div';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- 品目区分リストグループ
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_item_div_info';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- ノードポジション
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'in_g_cnt';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
          gt_xml_data_table(gl_xml_idx).tag_value := ln_vendor_code_count;
          -- 取引先グループ
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_vendor';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- 取引先リストグループ
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_vendor_info';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- ノードポジション
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'in_g_cnt';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
          gt_xml_data_table(gl_xml_idx).tag_value := ln_dept_code_count;
          -- 担当部署グループ
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_dept';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
        END IF ;
        -- ----------------------------------------------------
        -- グループ開始タグ出力
        -- ----------------------------------------------------
        -- 担当部署グループ
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'g_dept';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
        -- 担当部署コード
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'dept_code';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := lt_data_rec(i).dept_code;
        -- 担当部署名
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'dept_name';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := lt_data_rec(i).dept_name;
        -- 取引先リストグループ
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_vendor_info';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
        -- TMP担当部署：セット
        lv_dept_code         := lt_data_rec(i).dept_code ;
        -- 下層G：ブレイク判定条件セット
        lv_vendor_code       := lc_init ;
        lv_item_div_type     := lc_init ;
        lv_crowd_code        := lc_init ;
        lv_item_code         := lc_init ;
--
        -- 担当部署カウント：インクリメント
        ln_dept_code_count   := ln_dept_code_count + 1 ;
        -- 下層G内カウント ：初期化
        ln_vendor_code_count := 0 ;
        ln_item_div_count    := 0 ;
      END IF ;
--
      -- ====================================================
      -- ブレイク判定：取引先グループ
      -- ====================================================
      IF ( lt_data_rec(i).vendor_code <> lv_vendor_code ) THEN
        IF ( lv_vendor_code <> lc_init ) THEN
          -- ----------------------------------------------------
          -- 下層グループ終了タグ出力
          -- ----------------------------------------------------
          -- 明細リストグループ
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_dtl';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- 品目グループ
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_item';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- 品目リストグループ
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_item_info';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- 群グループ
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_crowd';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- 群リストグループ
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_crowd_info';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- ノードポジション
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'in_g_cnt';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
          gt_xml_data_table(gl_xml_idx).tag_value := ln_item_div_count;
          -- 品目区分グループ
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_item_div';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- 品目区分リストグループ
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_item_div_info';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- ノードポジション
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'in_g_cnt';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
          gt_xml_data_table(gl_xml_idx).tag_value := ln_vendor_code_count;
          -- 取引先グループ
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_vendor';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
        END IF ;
        -- ----------------------------------------------------
        -- グループ開始タグ出力
        -- ----------------------------------------------------
        -- 取引先グループ
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'g_vendor';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
        -- 取引先コード
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'vendor_code';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := lt_data_rec(i).vendor_code;
        -- 取引先名
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'vendor_name';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := lt_data_rec(i).vendor_name;
        -- 品目区分リストグループ
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_item_div_info';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
        -- TMP取引先：セット
        lv_vendor_code       := lt_data_rec(i).vendor_code ;
        -- 下層G：ブレイク判定条件セット
        lv_item_div_type     := lc_init ;
        lv_crowd_code        := lc_init ;
        lv_item_code         := lc_init ;
--
        -- 取引先カウント：インクリメント
        ln_vendor_code_count := ln_vendor_code_count + 1 ;
        -- 下層G内カウント ：初期化
        ln_item_div_count    := 0 ;
      END IF ;
--
      -- ====================================================
      -- ブレイク判定：品目区分グループ
      -- ====================================================
      IF ( lt_data_rec(i).item_div_type <> lv_item_div_type ) THEN
        IF ( lv_item_div_type <> lc_init ) THEN
          -- ----------------------------------------------------
          -- 下層グループ終了タグ出力
          -- ----------------------------------------------------
          -- 明細リストグループ
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_dtl';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- 品目グループ
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_item';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- 品目リストグループ
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_item_info';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- 群グループ
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_crowd';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- 群リストグループ
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_crowd_info';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- ノードポジション
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'in_g_cnt';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
          gt_xml_data_table(gl_xml_idx).tag_value := ln_item_div_count;
          -- 品目区分グループ
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_item_div';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
        END IF ;
        -- ----------------------------------------------------
        -- グループ開始タグ出力
        -- ----------------------------------------------------
        -- 品目区分グループ
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'g_item_div';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
        -- 品目区分コード
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'item_div_type';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := lt_data_rec(i).item_div_type;
        -- 品目区分名
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'item_div_name';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := lt_data_rec(i).item_div_name;
        -- 群リストグループ
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_crowd_info';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
        -- TMP品目区分：セット
        lv_item_div_type     := lt_data_rec(i).item_div_type ;
        -- 下層G：ブレイク判定条件セット
        lv_crowd_code        := lc_init ;
        lv_item_code         := lc_init ;
--
        -- 品目区分カウント：インクリメント
        ln_item_div_count := ln_item_div_count + 1 ;
      END IF ;
--
      -- ====================================================
      -- ブレイク判定：群グループ
      -- ====================================================
      IF ( lt_data_rec(i).crowd_code <> lv_crowd_code ) THEN
        IF ( lv_crowd_code <> lc_init ) THEN
          -- ----------------------------------------------------
          -- 下層グループ終了タグ出力
          -- ----------------------------------------------------
          -- 明細リストグループ
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_dtl';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- 品目グループ
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_item';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- 品目リストグループ
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_item_info';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- 群グループ
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_crowd';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
        END IF ;
        -- ----------------------------------------------------
        -- グループ開始タグ出力
        -- ----------------------------------------------------
        -- 群グループ
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'g_crowd';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
        -- 群コード
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'crowd_code';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := lt_data_rec(i).crowd_code;
        -- 品目リストグループ
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_item_info';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
        -- TMP群：セット
        lv_crowd_code     := lt_data_rec(i).crowd_code ;
        -- 下層G：ブレイク判定条件セット
        lv_item_code         := lc_init ;
      END IF ;
--
      -- ====================================================
      -- ブレイク判定：品目グループ
      -- ====================================================
      IF ( lt_data_rec(i).item_code <> lv_item_code ) THEN
        IF ( lv_item_code <> lc_init ) THEN
          -- ----------------------------------------------------
          -- 下層グループ終了タグ出力
          -- ----------------------------------------------------
          -- 明細リストグループ
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_dtl';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- 品目グループ
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_item';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
        END IF ;
        -- ----------------------------------------------------
        -- グループ開始タグ出力
        -- ----------------------------------------------------
        -- 品目グループ
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'g_item';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
        -- 品目コード
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'item_code';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := lt_data_rec(i).item_code;
        -- 品目コード
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'item_name';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := lt_data_rec(i).item_name;
        -- 品目リストグループ
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_dtl';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
        -- TMP品目：セット
        lv_item_code     := lt_data_rec(i).item_code ;
      END IF ;
--
      -- ====================================================
      -- 明細出力：明細グループ
      -- ====================================================
      -- 明細グループ
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'g_dtl' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
		-- 付帯
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'futai_code' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := lt_data_rec(i).futai_code;
      -- 出庫日
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'shipped_date' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := lt_data_rec(i).shipped_date;
      -- ロットNo
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'lot_no' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := lt_data_rec(i).lot_no;
      -- 製造日
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'maked_date' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := lt_data_rec(i).maked_date;
      -- 賞味期限
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'limit_date' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := lt_data_rec(i).limit_date;
      -- 固有記号
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'orgn_sign' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := lt_data_rec(i).orgn_sign;
      -- 入庫日
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'arrival_date' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := lt_data_rec(i).arrival_date;
      -- 依頼No
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'request_no' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := lt_data_rec(i).request_no;
      -- 入数
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'entry_quant' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := lt_data_rec(i).entry_quant;
      -- 総数
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'quant' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := lt_data_rec(i).quant;
      -- 単位
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'unit' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := lt_data_rec(i).unit;
      -- 単価
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'unt_price' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := lt_data_rec(i).unt_price;
      -- 金額
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'price' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := lt_data_rec(i).price;
      -- 返品訂正
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'rtn_sign' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      -- 返品訂正  有(1)：「*」無(0)：「」
      IF (lt_data_rec(i).rtn_sign = gc_rtn_sign_y ) THEN
        gt_xml_data_table(gl_xml_idx).tag_value := '*' ;
      ELSE
        gt_xml_data_table(gl_xml_idx).tag_value := NULL ;
      END IF ;
		-- 配送先
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'deliver_to' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := lt_data_rec(i).deliver_to;
      -- 明細摘要
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'dtl_desc' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := lt_data_rec(i).dtl_desc;
      -- 明細グループ
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := '/g_dtl' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
--
    END LOOP main_data_loop ;
--
    -- ==================================
    -- 終了処理
    -- ==================================
    -- 明細リストグループ
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_dtl';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
    -- 品目グループ
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/g_item';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
    -- 品目リストグループ
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_item_info';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
    -- 群グループ
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/g_crowd';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
    -- 群リストグループ
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_crowd_info';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
    -- ノードポジション
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'in_g_cnt';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := ln_item_div_count;
    -- 品目区分グループ
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/g_item_div';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
    -- 品目区分リストグループ
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_item_div_info';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
    -- ノードポジション
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'in_g_cnt';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := ln_vendor_code_count;
    -- 取引先グループ
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/g_vendor';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
    -- 取引先リストグループ
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_vendor_info';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
    -- ノードポジション
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'in_g_cnt';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := ln_dept_code_count;
    -- 担当部署グループ
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/g_dept';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
    -- 担当部署リストグループ
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_dept_info';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
    -- ノードポジション
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'in_g_cnt';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := ln_prod_div_count;
    -- 商品区分グループ
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/g_prod_div';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
    -- 商品区分リストグループ
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_prod_div_info';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
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
  END prc_create_xml_data ;
--
  /**********************************************************************************
   * Function Name    : convert_into_xml
   * Description      : ＸＭＬタグに変換する。
   ***********************************************************************************/
  FUNCTION convert_into_xml
    (
      iv_name              IN        VARCHAR2   --   タグネーム
     ,iv_value             IN        VARCHAR2   --   タグデータ
     ,ic_type              IN        CHAR       --   タグタイプ
    ) RETURN VARCHAR2
  IS
    -- =====================================================
    -- 固定ローカル定数
    -- =====================================================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'convert_into_xml' ;   -- プログラム名
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
    IF ( ic_type = 'D' ) THEN
      lv_convert_data := '<'||iv_name||'><![CDATA['||iv_value||']]></'||iv_name||'>';
    ELSE
      lv_convert_data := '<'||iv_name||'>' ;
    END IF ;
--
    RETURN(lv_convert_data) ;
--
  END convert_into_xml ;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain
    (
      iv_date_from           IN   VARCHAR2  -- 01 : 出庫日From
     ,iv_date_to             IN   VARCHAR2  -- 02 : 出庫日To
     ,iv_prod_div            IN   VARCHAR2  -- 03 : 商品区分
     ,iv_dept_code           IN   VARCHAR2  -- 04 : 担当部署
     ,iv_vendor_code_01      IN   VARCHAR2  -- 05 : 取引先１
     ,iv_vendor_code_02      IN   VARCHAR2  -- 06 : 取引先２
     ,iv_vendor_code_03      IN   VARCHAR2  -- 07 : 取引先３
     ,iv_vendor_code_04      IN   VARCHAR2  -- 08 : 取引先４
     ,iv_vendor_code_05      IN   VARCHAR2  -- 09 : 取引先５
     ,iv_item_div            IN   VARCHAR2  -- 10 : 品目区分
     ,iv_crowd_code_01       IN   VARCHAR2  -- 11 : 群１
     ,iv_crowd_code_02       IN   VARCHAR2  -- 12 : 群２
     ,iv_crowd_code_03       IN   VARCHAR2  -- 13 : 群３
     ,iv_item_code_01        IN   VARCHAR2  -- 14 : 品目１
     ,iv_item_code_02        IN   VARCHAR2  -- 15 : 品目２
     ,iv_item_code_03        IN   VARCHAR2  -- 16 : 品目３
     ,iv_security_div        IN   VARCHAR2  -- 17 : 有償セキュリティ区分
     ,ov_errbuf              OUT  VARCHAR2  -- エラー・メッセージ           --# 固定 #
     ,ov_retcode             OUT  VARCHAR2  -- リターン・コード             --# 固定 #
     ,ov_errmsg              OUT  VARCHAR2  -- ユーザー・エラー・メッセージ --# 固定 #
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
    lv_xml_string           VARCHAR2(32000) ;
    lv_err_code             VARCHAR2(10) ;
    ln_retcode              VARCHAR2(1) ;
--
    get_value_expt        EXCEPTION ;     -- 値取得エラー
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
    -- 初期処理
    -- =====================================================
    -- -----------------------------------------------------
    -- パラメータ格納
    -- -----------------------------------------------------
-- UPDATE START 2008/5/20 YTabata --
    gr_param.date_from                                   -- 01 : 出庫日From
      :=  TO_CHAR(FND_DATE.CANONICAL_TO_DATE(iv_date_from ),'YYYY/MM/DD');
    gr_param.date_to                                     -- 02 : 出庫日To
      :=  TO_CHAR(FND_DATE.CANONICAL_TO_DATE(iv_date_to ),'YYYY/MM/DD');
/**
    gr_param.date_from       :=  iv_date_from ;          -- 01 : 出庫日From
    gr_param.date_to         :=  iv_date_to ;            -- 02 : 出庫日To
**/
-- UPDATE END 2008/5/20 YTabata --
    gr_param.prod_div        :=  iv_prod_div ;           -- 03 : 商品区分
    gr_param.dept_code       :=  iv_dept_code ;          -- 04 : 担当部署
    gr_param.vendor_code_01  :=  iv_vendor_code_01 ;     -- 05 : 取引先１
    gr_param.vendor_code_02  :=  iv_vendor_code_02 ;     -- 06 : 取引先２
    gr_param.vendor_code_03  :=  iv_vendor_code_03 ;     -- 07 : 取引先３
    gr_param.vendor_code_04  :=  iv_vendor_code_04 ;     -- 08 : 取引先４
    gr_param.vendor_code_05  :=  iv_vendor_code_05 ;     -- 09 : 取引先５
    gr_param.item_div        :=  iv_item_div ;           -- 10 : 品目区分
    gr_param.crowd_code_01   :=  iv_crowd_code_01 ;      -- 11 : 群１
    gr_param.crowd_code_02   :=  iv_crowd_code_02 ;      -- 12 : 群２
    gr_param.crowd_code_03   :=  iv_crowd_code_03 ;      -- 13 : 群３
    gr_param.item_code_01    :=  iv_item_code_01 ;       -- 14 : 品目１
    gr_param.item_code_02    :=  iv_item_code_02 ;       -- 15 : 品目２
    gr_param.item_code_03    :=  iv_item_code_03 ;       -- 16 : 品目３
    gr_param.security_div    :=  iv_security_div ;       -- 17 : 有償セキュリティ区分
--
    -- -----------------------------------------------------
    -- 営業単位取得
    -- -----------------------------------------------------
    gn_prof_org_id := FND_PROFILE.VALUE( gc_prof_org_id ) ;	
    IF ( gn_prof_org_id IS NULL ) THEN
      lv_err_code := gc_err_code_no_prof ;
      RAISE get_value_expt ;
    END IF ;
--
    -- =====================================================
    -- データ取得ＳＱＬ生成
    -- =====================================================
    prc_create_sql
      (
        ov_errbuf         => lv_errbuf          -- エラー・メッセージ           --# 固定 #
       ,ov_retcode        => lv_retcode         -- リターン・コード             --# 固定 #
       ,ov_errmsg         => lv_errmsg          -- ユーザー・エラー・メッセージ --# 固定 #
      ) ;
    IF ( lv_retcode = gv_status_error ) THEN
      RAISE global_process_expt ;
    END IF ;
--
    -- =====================================================
    -- ログインユーザー情報出力
    -- =====================================================
    prc_create_xml_data_user
      (
        ov_errbuf         => lv_errbuf          -- エラー・メッセージ           --# 固定 #
       ,ov_retcode        => lv_retcode         -- リターン・コード             --# 固定 #
       ,ov_errmsg         => lv_errmsg          -- ユーザー・エラー・メッセージ --# 固定 #
      ) ;
    IF ( lv_retcode = gv_status_error ) THEN
      RAISE global_process_expt ;
    END IF ;
--
    -- =====================================================
    -- ＸＭＬファイルデータ編集
    -- =====================================================
    -- --------------------------------------------------
    -- リストグループ開始タグ
    -- --------------------------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'data_info' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
    -- --------------------------------------------------
    -- ＸＭＬデータ編集処理を呼び出す。
    -- --------------------------------------------------
    prc_create_xml_data
      (
        ov_errbuf         => lv_errbuf          -- エラー・メッセージ           --# 固定 #
       ,ov_retcode        => lv_retcode         -- リターン・コード             --# 固定 #
       ,ov_errmsg         => lv_errmsg          -- ユーザー・エラー・メッセージ --# 固定 #
      ) ;
    IF ( lv_retcode = gv_status_error ) THEN
      RAISE global_process_expt ;
    END IF ;
--
    -- --------------------------------------------------
    -- リストグループ終了タグ
    -- --------------------------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/data_info' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
    -- ==================================================
    -- 帳票出力
    -- ==================================================
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<?xml version="1.0" encoding="shift_jis" ?>' ) ;
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<root>' ) ;
--
    -- --------------------------------------------------
    -- 抽出データが０件の場合
    -- --------------------------------------------------
    IF ( gn_data_cnt = 0 ) THEN
--
      -- --------------------------------------------------
      -- ０件メッセージの取得
      -- --------------------------------------------------
      ov_retcode := gv_status_warn ;
      lv_errmsg  := xxcmn_common_pkg.get_msg( gc_application
                                             ,gc_err_code_no_data ) ;
--
      -- --------------------------------------------------
      -- メッセージの設定
      -- --------------------------------------------------
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '  <data_info>' ) ;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '    <lg_prod_div_info>' ) ;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '      <g_prod_div>' ) ;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '        <lg_dept_info>' ) ;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '          <g_dept>' ) ;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '            <lg_vendor_info>' ) ;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '              <g_vendor>' ) ;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '                <lg_item_div_info>' ) ;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '                  <g_item_div>' ) ;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '                    <msg>' || lv_errmsg || '</msg>' ) ;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '                  </g_item_div>' ) ;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '                </lg_item_div_info>' ) ;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '              </g_vendor>' ) ;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '            </lg_vendor_info>' ) ;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '          </g_dept>' ) ;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '        </lg_dept_info>' ) ;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '      </g_prod_div>' ) ;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '    </lg_prod_div_info>' ) ;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '  </data_info>' ) ;
--
    -- --------------------------------------------------
    -- 帳票データが出力できた場合
    -- --------------------------------------------------
    ELSE
      -- --------------------------------------------------
      -- ＸＭＬ出力
      -- --------------------------------------------------
      -- ＸＭＬデータ部出力
      <<xml_data_table>>
      FOR i IN 1 .. gt_xml_data_table.COUNT LOOP
        -- 編集したデータをタグに変換
        lv_xml_string := convert_into_xml
                          (
                            iv_name   => gt_xml_data_table(i).tag_name  -- タグネーム
                           ,iv_value  => gt_xml_data_table(i).tag_value  -- タグデータ
                           ,ic_type   => gt_xml_data_table(i).tag_type  -- タグタイプ
                          ) ;
        -- ＸＭＬタグ出力
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_xml_string) ;
      END LOOP xml_data_table ;
--
    END IF ;
--
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '</root>' ) ;
--
    -- ==================================================
    -- 終了ステータス設定
    -- ==================================================
    ov_errmsg  := lv_errmsg ;
    ov_errbuf  := lv_errbuf ;
--
  EXCEPTION
    --*** 値取得エラー例外 ***
    WHEN get_value_expt THEN
      -- メッセージセット
      lv_errmsg := xxcmn_common_pkg.get_msg
                    ( iv_application    => gc_application_po
                     ,iv_name           => lv_err_code
                    ) ;
      ov_errmsg  := lv_errmsg ;
      ov_errbuf  := lv_errmsg ;
      ov_retcode := gv_status_error ;
--
--#################################  固定例外処理部 START   ###################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg ;
      ov_errbuf  := SUBSTRB(gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000) ;
      ov_retcode := gv_status_error ;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM ;
      ov_retcode := gv_status_error ;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM ;
      ov_retcode := gv_status_error ;
--
--####################################  固定部 END   ##########################################
  END submain ;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : コンカレント実行ファイル登録プロシージャ
   **********************************************************************************/
--
  PROCEDURE main
    (
      errbuf                OUT    VARCHAR2         -- エラーメッセージ
     ,retcode               OUT    VARCHAR2         -- エラーコード
     ,iv_date_from          IN     VARCHAR2         -- 01 : 出庫日From
     ,iv_date_to            IN     VARCHAR2         -- 02 : 出庫日To
     ,iv_prod_div           IN     VARCHAR2         -- 03 : 商品区分
     ,iv_dept_code          IN     VARCHAR2         -- 04 : 担当部署
     ,iv_vendor_code_01     IN     VARCHAR2         -- 05 : 取引先１
     ,iv_vendor_code_02     IN     VARCHAR2         -- 06 : 取引先２
     ,iv_vendor_code_03     IN     VARCHAR2         -- 07 : 取引先３
     ,iv_vendor_code_04     IN     VARCHAR2         -- 08 : 取引先４
     ,iv_vendor_code_05     IN     VARCHAR2         -- 09 : 取引先５
     ,iv_item_div           IN     VARCHAR2         -- 10 : 品目区分
     ,iv_crowd_code_01      IN     VARCHAR2         -- 11 : 群１
     ,iv_crowd_code_02      IN     VARCHAR2         -- 12 : 群２
     ,iv_crowd_code_03      IN     VARCHAR2         -- 13 : 群３
     ,iv_item_code_01       IN     VARCHAR2         -- 14 : 品目１
     ,iv_item_code_02       IN     VARCHAR2         -- 15 : 品目２
     ,iv_item_code_03       IN     VARCHAR2         -- 16 : 品目３
     ,iv_security_div       IN     VARCHAR2         -- 17 : 有償セキュリティ区分
    )
--
--###########################  固定部 START   ###########################
--
  IS
--
    -- ======================================================
    -- 固定ローカル定数
    -- ======================================================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'main' ;  -- プログラム名
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
        iv_date_from           -- 01 : 出庫日From
       ,iv_date_to             -- 02 : 出庫日To
       ,iv_prod_div            -- 03 : 商品区分
       ,iv_dept_code           -- 04 : 担当部署
       ,iv_vendor_code_01      -- 05 : 取引先１
       ,iv_vendor_code_02      -- 06 : 取引先２
       ,iv_vendor_code_03      -- 07 : 取引先３
       ,iv_vendor_code_04      -- 08 : 取引先４
       ,iv_vendor_code_05      -- 09 : 取引先５
       ,iv_item_div            -- 10 : 品目区分
       ,iv_crowd_code_01       -- 11 : 群１
       ,iv_crowd_code_02       -- 12 : 群２
       ,iv_crowd_code_03       -- 13 : 群３
       ,iv_item_code_01        -- 14 : 品目１
       ,iv_item_code_02        -- 15 : 品目２
       ,iv_item_code_03        -- 16 : 品目３
       ,iv_security_div        -- 17 : 有償セキュリティ区分
       ,lv_errbuf              -- エラー・メッセージ
       ,lv_retcode             -- リターン・コード
       ,lv_errmsg              -- ユーザー・エラー・メッセージ
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
--
    ELSIF ( lv_retcode = gv_status_warn ) THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf) ;
--
    END IF ;
--
    --ステータスセット
    retcode := lv_retcode ;
--
  EXCEPTION
--
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM ;
      retcode := gv_status_error ;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM ;
      retcode := gv_status_error ;
--
  END main ;
--
--###########################  固定部 END   #######################################################
--
END xxpo440005c ;
/
