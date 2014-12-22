CREATE OR REPLACE PACKAGE BODY xxcmn770001c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxcmn770001c(body)
 * Description      : 受払残高表（Ⅰ）原料・資材・半製品
 * MD.050/070       : 月次〆切処理（経理）Issue1.0(T_MD050_BPO_770)
 *                    月次〆切処理（経理）Issue1.0(T_MD070_BPO_77A)
 * Version          : 1.33
 *
 * Program List
 * -------------------------- ----------------------------------------------------------
 *  Name                       Description
 * -------------------------- ----------------------------------------------------------
 *  fnc_conv_xml              FUNCTION  : ＸＭＬタグに変換する。
 *  prc_initialize            PROCEDURE : 前処理(A-1)
 *  prc_get_report_data       PROCEDURE : 明細データ取得(A-2)
 *  prc_create_xml_data       PROCEDURE : ＸＭＬデータ作成
 *  submain                   PROCEDURE : メイン処理プロシージャ
 *  main                      PROCEDURE : コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/04/02    1.0   M.Inamine        新規作成
 *  2008/05/16    1.1   Y.Majikina       パラメータ：処理年月がYYYYMで入力されるとエラーになる
 *                                       点を修正。
 *                                       帳票種別名称、品目区分名称、商品区分名称、群種別名称の
 *                                       最大長処理を追加。
 *                                       担当部署、担当者名の最大長処理を変更。
 *                                       (SUBSTR → SUBSTRB)
 *  2008/05/30    1.2   R.Tomoyose       実際原価を抽出する時、原価管理区分が実際原価の場合、
 *                                       ロット管理の対象の場合はロット別原価テーブル
 *                                       ロット管理の対象外の場合は標準原価マスタテーブルより取得
 *  2008/06/03    1.3   T.Endou          担当部署または担当者名が未取得時は正常終了に修正
 *  2008/06/12    1.4   Y.Ishikawa       生産原料詳細(アドオン)の結合が不要の為削除。
 *                                       取引区分名 = 仕入先返品は払出だが出力位置は受入の部分に
 *                                       出力する。
 *  2008/06/24    1.5   T.Endou          数量・金額項目がNULLでも0出力する。
 *                                       数量・金額の間を詰める。
 *  2008/06/25    1.6   T.Ikehara        特定文字列を出力しようとすると、エラーとなり帳票が出力
 *                                       されない現象への対応
 *  2008/08/05    1.7   R.Tomoyose       参照ビューの変更「xxcmn_rcv_pay_mst_porc_rma_v」→
 *                                                       「xxcmn_rcv_pay_mst_porc_rma01_v」
 *  2008/08/20    1.8   A.Shiina         T_TE080_BPO_770 指摘9対応
 *  2008/08/22    1.9   A.Shiina         T_TE080_BPO_770 指摘14対応
 *  2008/10/20    1.10  A.Shiina         T_S_524対応
 *  2008/10/31    1.11  A.Shiina         振替_受入の取引数量の+-符号を修正
 *  2008/11/04    1.12  A.Shiina         移行不具合修正
 *  2008/11/06    1.13  A.Shiina         着日基準へ修正、振替のカテゴリ修正
 *  2008/11/06    1.14  A.Shiina         ヒント句の修正
 *  2008/11/07    1.15  A.Shiina         当月明細加算のIF条件修正
 *  2008/11/11    1.16  A.Shiina         移行不具合修正
 *  2008/11/13    1.16  N.Fukuda         統合指摘#634対応(移行データ検証不具合対応)
 *  2008/11/17    1.17  A.Shiina         月首･月末在庫不具合修正
 *  2008/11/19    1.18  N.Yoshida        I_S_684対応、移行データ検証不具合対応
 *  2008/11/25    1.19  A.Shiina         本番指摘52対応
 *  2008/12/03    1.20  A.Shiina         本番指摘361対応
 *  2008/12/05    1.21  H.Maru           本番障害492対応
 *  2008/12/08    1.22  N.Yoshida        本番障害数値あわせ対応(受注ヘッダの最新フラグを追加)
 *  2008/12/08    1.23  A.Shiina         本番障害565対応
 *  2008/12/09    1.24  H.Marushita      本番障害565対応
 *  2008/12/10    1.25  A.Shiina         本番障害617,636対応
 *  2008/12/11    1.26  N.Yoshida        本番障害580対応
 *  2008/12/18    1.27  N.Yoshida        本番障害773対応
 *  2008/12/22    1.28  N.Yoshida        本番障害838対応
 *  2008/12/25    1.29  A.Shiina         本番障害674対応
 *  2009/01/07    1.30  N.Yoshida        本番障害954対応
 *  2009/03/05    1.31  A.Shiina         本番障害1272対応
 *  2009/05/29    1.32  Marushita        本番障害1511対応
 *  2014/10/14    1.33  H.Itou           E_本稼動_12321対応
 *****************************************************************************************/
--
--#######################  固定グローバル定数宣言部 START   #######################
--
  gv_status_normal           CONSTANT VARCHAR2(1)  := '0';
  gv_status_warn             CONSTANT VARCHAR2(1)  := '1';
  gv_status_error            CONSTANT VARCHAR2(1)  := '2';
  gv_msg_part                CONSTANT VARCHAR2(3)  := ' : ';
  gv_msg_cont                CONSTANT VARCHAR2(3)  := '.';
  gv_hifn                    CONSTANT VARCHAR2(1)  := '-';
  gv_ja                      CONSTANT VARCHAR2(2)  := 'JA';
  gv_qty_prf                 CONSTANT VARCHAR2(4)  := '_qty';
  gv_amt_prf                 CONSTANT VARCHAR2(4)  := '_amt';
  gn_po_qty                  CONSTANT NUMBER       := 1;
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
  gv_pkg_name                CONSTANT VARCHAR2(20) := 'xxcmn770001C';   -- パッケージ名
  gv_print_name              CONSTANT VARCHAR2(50) :='受払残高表（Ⅰ）原料・資材・半製品';--帳票名
--
  ------------------------------
  -- 文書タイプ
  ------------------------------
  gv_doc_type_xfer           CONSTANT VARCHAR2(5)  := 'XFER';  --
  gv_doc_type_trni           CONSTANT VARCHAR2(5)  := 'TRNI';  --
  gv_doc_type_adji           CONSTANT VARCHAR2(5)  := 'ADJI';  --
  gv_doc_type_prod           CONSTANT VARCHAR2(5)  := 'PROD';  --
  gv_doc_type_porc           CONSTANT VARCHAR2(5)  := 'PORC';  --
  gv_doc_type_omso           CONSTANT VARCHAR2(5)  := 'OMSO';  --
  ------------------------------
  -- 事由コード
  ------------------------------
  gv_reason_code_xfer        CONSTANT VARCHAR2(5)   := 'X122';--
  gv_reason_code_trni        CONSTANT VARCHAR2(5)   := 'X122';--
  gv_reason_code_adji_po     CONSTANT VARCHAR2(5)   := 'X201';--仕入
  gv_reason_code_adji_hama   CONSTANT VARCHAR2(5)   := 'X988';--浜岡
  gv_reason_code_adji_move   CONSTANT VARCHAR2(5)   := 'X123';--移動
  gv_reason_code_adji_othr   CONSTANT VARCHAR2(5)   := 'X977';--相手先（出力対象外）
  gv_reason_code_adji_itm    CONSTANT VARCHAR2(5)   := 'X942';-- 黙視品目払出
  gv_reason_code_adji_snt    CONSTANT VARCHAR2(5)   := 'X951';-- その他払出
-- 2008/10/20 v1.10 ADD START
  gv_reason_code_adji_itm_u  CONSTANT VARCHAR2(5)   := 'X943';-- 黙視品目受入
  gv_reason_code_adji_snt_u  CONSTANT VARCHAR2(5)   := 'X950';-- その他受入
-- 2008/10/20 v1.10 ADD START
--
  ------------------------------
  -- ルックアップ　タイプ
  ------------------------------
  gc_lookup_type_print_class CONSTANT VARCHAR2(50) := 'XXCMN_MONTH_TRANS_OUTPUT_TYPE';-- 帳票種別
  gc_lookup_type_print_flg   CONSTANT VARCHAR2(50) := 'XXCMN_MONTH_TRANS_OUTPUT_FLAG';-- 印刷可否
  gc_lookup_type_crowd_kind  CONSTANT VARCHAR2(50) := 'XXCMN_MC_OUPUT_DIV';           -- 群種別
  gc_lookup_type_dealing_div CONSTANT VARCHAR2(50) := 'XXCMN_DEALINGS_DIV' ;          -- 取引区分
--
  ------------------------------
  -- 出力項目の列位置最大値
  ------------------------------
  gc_print_pos_max           CONSTANT NUMBER := 19;--項目出力位置最後
  gc_pay_pos_strt            CONSTANT NUMBER := 08;--払出先頭項目位置
  ------------------------------
  -- 処理年月の桁位置
  ------------------------------
  gc_exec_year_y             CONSTANT NUMBER := 05;--
  gc_exec_year_m             CONSTANT NUMBER := 04;--
  gc_m_pos                   CONSTANT NUMBER := 02;--
  ------------------------------
  -- 帳票種別
  ------------------------------
  gc_print_type1             CONSTANT VARCHAR2(1) := '1';--倉庫別・品目別
  gc_print_type2             CONSTANT VARCHAR2(1) := '2';--品目別
   ------------------------------
  -- 群種別
  ------------------------------
  gc_grp_type3               CONSTANT VARCHAR2(1) := '3';--群別
  gc_grp_type4               CONSTANT VARCHAR2(1) := '4';--経理群別
  ------------------------------
  ------------------------------
  -- 品目カテゴリ関連
  ------------------------------
  gc_cat_set_goods_class     CONSTANT VARCHAR2(10) := '商品区分';
  gc_cat_set_item_class      CONSTANT VARCHAR2(10) := '品目区分';
  ------------------------------
  -- 原価区分
  ------------------------------
  gc_cost_ac                 CONSTANT VARCHAR2(1) := '0';--実際原価
  gc_cost_st                 CONSTANT VARCHAR2(1) := '1';--標準原価
  gc_price_sel               CONSTANT NUMBER      :=  7; --原価別集計カウンタ
  ------------------------------
  -- ロット管理
  ------------------------------
  gc_lot_ctl_n               CONSTANT VARCHAR2(1) := '0';--対象外
  gc_lot_ctl_y               CONSTANT VARCHAR2(1) := '1';--対象
--
  ------------------------------
  -- 受払区分
  ------------------------------
  gc_rcv_pay_div_in          CONSTANT VARCHAR2(1) :=  '1' ;  --受入
  gc_rcv_pay_div_out         CONSTANT VARCHAR2(2) := '-1' ;  --払出
-- 2008/10/31 v1.11 ADD START
  gc_rcv_pay_div_adj         CONSTANT VARCHAR2(2) := '-1' ;  --調整
-- 2008/10/31 v1.11 ADD END
  ------------------------------
  -- 取引区分
  ------------------------------
  gv_dealings_div_prod1      CONSTANT VARCHAR2(10)  := '品種振替';
  gv_dealings_div_prod2      CONSTANT VARCHAR2(10)  := '品目振替';
  gv_dealings_name_po        CONSTANT xxcmn_lookup_values_v.meaning%TYPE := '仕入';
-- 2008/10/31 v1.11 ADD START
  gv_d_name_trn_rcv          CONSTANT xxcmn_lookup_values_v.meaning%TYPE := '振替有償_受入';
  gv_d_name_item_trn_rcv     CONSTANT xxcmn_lookup_values_v.meaning%TYPE := '商品振替有償_受入';
  gv_d_name_trn_ship_rcv_gen CONSTANT xxcmn_lookup_values_v.meaning%TYPE := '振替出荷_受入_原';
  gv_d_name_trn_ship_rcv_han CONSTANT xxcmn_lookup_values_v.meaning%TYPE := '振替出荷_受入_半';
-- 2008/10/31 v1.11 ADD END
  ------------------------------
  -- エラーメッセージ関連
  ------------------------------
  gc_application             CONSTANT VARCHAR2(5)  := 'XXCMN';-- アプリケーション
--
  ------------------------------
  -- 項目編集関連
  ------------------------------
  gc_char_ym_format          CONSTANT VARCHAR2(30) := 'YYYYMM';
  gc_char_d_format           CONSTANT VARCHAR2(30) := 'YYYY/MM/DD';
  gc_char_dt_format          CONSTANT VARCHAR2(30) := 'YYYY/MM/DD HH24:MI:SS';
  gc_e_time                  CONSTANT VARCHAR2(10) := ' 23:59:59';
  gv_month_edt               CONSTANT VARCHAR2(07) := 'MONTH';--処理年月の前月計算用
  gv_fdy                     CONSTANT VARCHAR2(02) :=  '01';  --月初日付
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  -- 入力パラメータ格納用レコード変数
  TYPE rec_param_data  IS RECORD(
      exec_year_month     VARCHAR2(6)                          -- 01 : 処理年月    （必須)
     ,goods_class         xxcmn_lot_each_item_v.prod_div%TYPE-- 02 : 商品区分    （必須)
     ,item_class          xxcmn_lot_each_item_v.item_div%TYPE-- 03 : 品目区分    （必須)
     ,print_kind          VARCHAR2(10)                         -- 04 : 帳票種別    （必須)
     ,locat_code          VARCHAR2(10)                         -- 05 : 倉庫コード  （任意)
     ,crowd_kind          VARCHAR2(10)                         -- 06 : 群種別      （必須)
     ,crowd_code          VARCHAR2(10)                         -- 07 : 群コード    （任意)
     ,acnt_crowd_code     VARCHAR2(10)                         -- 08 : 経理群コード（任意)
    );
--
  -- 品目明細集計レコード
  TYPE qty_array IS VARRAY(23) OF NUMBER;
  qty qty_array := qty_array(0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0);
  TYPE amt_array IS VARRAY(23) OF NUMBER;
  amt qty_array := qty_array(0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0);
--
  -- 取引区分毎のタグ名称配列設定
  TYPE tag_name_array IS VARRAY(19) OF VARCHAR2(20);
  tag_name tag_name_array := tag_name_array(
     'po'                        -- 1 仕入
    ,'remanfct'                  -- 2 再製
    ,'bld'                       -- 3 合組
    ,'remanfct_bld'              -- 4 再製合組
    ,'prdct'                     -- 5 製品より
    ,'mat_semiprdct'             -- 6 原料・半製品より
    ,'others'                    -- 7 その他
    ,'exp_remanfct'              -- 8 再製
    ,'exp_bld'                   -- 9 ブレンド合組
    ,'exp_remanfct_bld'          --10 再製合組
    ,'pak'                       --11 包装
    ,'set'                       --12 セット
    ,'okinawa'                   --13 沖縄
    ,'ons'                       --14 有償
    ,'bas'                       --15 拠点
    ,'out_trnsfr'                --16 振替出庫
    ,'out_pdrct'                 --17 製品へ
    ,'out_mat_semiprdct'         --18 原料・半製品へ
    ,'out_other');               --19 その他
--
  -- 受払残高表データ格納用レコード変数
  TYPE rec_data_type_dtl  IS RECORD(
     whse_code              ic_whse_mst.whse_code                    %TYPE-- 倉庫コード
    ,whse_name              ic_whse_mst.whse_name                    %TYPE-- 倉庫名称
    ,trns_id                ic_tran_pnd.trans_id                     %TYPE-- TRANS_ID
    ,cost_mng_clss          xxcmn_lot_each_item_v.item_attribute15   %TYPE-- 原価区分
    ,lot_ctl                xxcmn_lot_each_item_v.lot_ctl            %TYPE-- ロット管理
    ,actual_unit_price      xxcmn_lot_each_item_v.actual_unit_price  %TYPE-- 実際単価
    ,print_pos              xxcmn_lookup_values2_v.attribute1        %TYPE-- 印字位置
    ,reason_code            ic_tran_pnd.reason_code                  %TYPE-- 事由コード
    ,trans_date             ic_tran_pnd.trans_date                   %TYPE-- 取引日
    ,trans_ym               VARCHAR2(06) -- 取引年月
    ,rcv_pay_div            xxcmn_rcv_pay_mst_xfer_v.rcv_pay_div     %TYPE-- 受払区分
    ,dealings_div           xxcmn_rcv_pay_mst_xfer_v.dealings_div    %TYPE-- 取引区分
    ,doc_type               xxcmn_rcv_pay_mst_xfer_v.doc_type        %TYPE-- 文書タイプ
    ,item_div               xxcmn_lot_each_item_v.item_div           %TYPE-- 品目区分
    ,prod_div               xxcmn_lot_each_item_v.prod_div           %TYPE-- 商品区分
    ,crowd_code             xxcmn_lot_each_item_v.crowd_code         %TYPE-- 群コード
    ,crowd_low              VARCHAR2(05)--小群
    ,crowd_mid              VARCHAR2(05)--中群
    ,crowd_high             VARCHAR2(05)--大群
    ,item_id                xxcmn_lot_each_item_v.item_id            %TYPE-- 品目ＩＤ
    ,lot_id                 xxcmn_lot_each_item_v.lot_id             %TYPE-- ロットＩＤ
    ,trans_qty              ic_tran_pnd.trans_qty                    %TYPE-- 取引数量
    ,arrival_date           ic_tran_pnd.trans_date                   %TYPE-- 着荷日
    ,arrival_ym             VARCHAR2(06)                                  -- 着荷年月
    ,item_code              xxcmn_lot_each_item_v.item_code          %TYPE-- 品目コード
    ,item_name              xxcmn_lot_each_item_v.item_short_name    %TYPE-- 品目略称
    ) ;
  TYPE tab_data_type_dtl IS TABLE OF rec_data_type_dtl INDEX BY BINARY_INTEGER;
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gn_user_id                fnd_user.user_id%TYPE DEFAULT FND_GLOBAL.USER_ID; -- ユーザーＩＤ
  ------------------------------
  -- ヘッダ情報取得用
  ------------------------------
-- 帳票種別
  gv_user_dept              xxcmn_locations_all.location_short_name  %TYPE;-- 担当部署
  gv_user_name              per_all_people_f.per_information18       %TYPE;-- 担当者
  gv_goods_class_name       mtl_categories_tl.description            %TYPE;-- 商品区分名
  gv_item_class_name        mtl_categories_tl.description            %TYPE;-- 品目区分名
  gv_crowd_kind_name        mtl_categories_tl.description            %TYPE;-- 群種別名
  gv_print_class_name       mtl_categories_tl.description            %TYPE;-- 帳票種別名称
--
  ------------------------------
  -- ＸＭＬ用
  ------------------------------
  gv_report_id              VARCHAR2(12);    -- 帳票ID
  gd_exec_date              DATE        ;    -- 実施日
--
  gt_body_data              tab_data_type_dtl;       -- 取得レコード表
  gt_xml_data_table         XML_DATA;                -- ＸＭＬデータタグ表
  gl_xml_idx                NUMBER DEFAULT 0;        -- ＸＭＬデータタグ表のインデックス
--
  ------------------------------
  -- 集計期間
  ------------------------------
  gd_s_date               DATE;          -- 開始日
  gd_e_date               DATE;          -- 終了日
  gd_follow_date          DATE;          -- 翌月年月
  gd_prv1_last_date       DATE;          -- 前月の末日
  gd_prv2_last_date       DATE;          -- 前々月の末日
  gd_flw_dt_chr           VARCHAR2(20);  -- 翌月年月文字
  gd_prv1_dt_chr          VARCHAR2(20);  -- 前月の末日文字
  gd_prv2_dt_chr          VARCHAR2(20);  -- 前々月の末日文字
  ------------------------------
  --  前月集計用
  ------------------------------
  gn_fst_inv_qty          NUMBER DEFAULT 0;--数量
  gn_fst_inv_amt          NUMBER DEFAULT 0;--金額
  ------------------------------
  --  棚卸集計用
  ------------------------------
  gn_lst_inv_qty          NUMBER DEFAULT 0;--数量
  gn_lst_inv_amt          NUMBER DEFAULT 0;--金額
  ------------------------------
  --  帳票総合計カウンタ
  ------------------------------
  ln_position             NUMBER DEFAULT 0;-- ポジション
  ------------------------------
  --  標準原価評価日付
  ------------------------------
  gd_st_unit_date         DATE; -- 2009/05/29 ADD
--
--#####################  固定共通例外宣言部 START   ####################
--
  --*** 処理部共通例外 ***
  global_process_expt     EXCEPTION;
  --*** 共通関数例外 ***
  global_api_expt         EXCEPTION;
  --*** 共通関数OTHERS例外 ***
  global_api_others_expt  EXCEPTION;
--
  PRAGMA EXCEPTION_INIT(global_api_others_expt,-20000);
--
--###########################  固定部 END   ############################
--
--
  /**********************************************************************************
   * Function Name    : fnc_conv_xml
   * Description      : ＸＭＬタグに変換する。
   ***********************************************************************************/
  FUNCTION fnc_conv_xml(
      iv_name              IN        VARCHAR2   --   タグネーム
     ,iv_value             IN        VARCHAR2   --   タグデータ
     ,ic_type              IN        CHAR       --   タグタイプ
    ) RETURN VARCHAR2
  IS
    -- =====================================================
    -- 固定ローカル定数
    -- =====================================================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'fnc_conv_xml';   -- プログラム名
--
    -- =====================================================
    -- ユーザー宣言部
    -- =====================================================
    -- *** ローカル変数 ***
    lv_convert_data         VARCHAR2(2000);
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
  END fnc_conv_xml;
--
  /**********************************************************************************
   * Procedure Name   : prc_initialize
   * Description      : 前処理(A-1)
   ***********************************************************************************/
  PROCEDURE prc_initialize(
      ir_param      IN     rec_param_data   -- 01.入力パラメータ群
     ,ov_errbuf     OUT    VARCHAR2         --    エラー・メッセージ           --# 固定 #
     ,ov_retcode    OUT    VARCHAR2         --    リターン・コード             --# 固定 #
     ,ov_errmsg     OUT    VARCHAR2         --    ユーザー・エラー・メッセージ --# 固定 #
    )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_initialize'; -- プログラム名
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
    -- エラーコード
    lc_err_code        CONSTANT VARCHAR2(30) := 'APP-XXCMN-10010';
    -- トークン名
    lc_token_name_01   CONSTANT VARCHAR2(30) := 'PARAMETER';
    lc_token_name_02   CONSTANT VARCHAR2(30) := 'VALUE';
    -- トークン値
    lc_token_value     CONSTANT VARCHAR2(30) := '処理年月';
--
    -- *** ローカル変数 ***
    ld_param_date DATE;
--
    -- *** ローカル・例外処理 ***
    get_value_expt        EXCEPTION;     -- 値取得エラー
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
    -- 担当部署名取得
    -- ====================================================
    gv_user_dept := xxcmn_common_pkg.get_user_dept( gn_user_id );
    gv_user_dept := SUBSTRB(gv_user_dept, 1, 10);
--
    -- ====================================================
    -- 担当者名取得
    -- ====================================================
    gv_user_name := xxcmn_common_pkg.get_user_name( gn_user_id );
    gv_user_name := SUBSTRB(gv_user_name, 1, 14);
--
    -- ====================================================
    -- 帳票種別取得
    -- ====================================================
    BEGIN
      SELECT flv.meaning
      INTO   gv_print_class_name
      FROM   xxcmn_lookup_values_v flv
      WHERE  flv.lookup_code   = ir_param.print_kind
      AND    flv.lookup_type   = gc_lookup_type_print_class
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        NULL;
    END ;
--
    -- ====================================================
    -- 商品区分取得
    -- ====================================================
    BEGIN
-- 2008/10/20 v1.10 DELETE START
--      SELECT cat.description
--      INTO   gv_goods_class_name
--      FROM   xxcmn_categories2_v cat
--      WHERE  cat.category_set_name = gc_cat_set_goods_class
--      AND    cat.segment1          = ir_param.goods_class
--      ;
-- 2008/10/20 v1.10 DELETE END
-- 2008/10/20 v1.10 ADD START
      SELECT mct.description
      INTO   gv_goods_class_name
      FROM   mtl_category_sets_b mcsb
            ,mtl_categories_b mcb
            ,mtl_categories_tl mct
      WHERE  mcsb.structure_id    = mcb.structure_id
      AND    mcsb.category_set_id = TO_NUMBER(FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_PROD_CLASS'))
      AND    mcb.segment1         = ir_param.goods_class
      AND    mcb.category_id      = mct.category_id
      AND    mct.language         = 'JA'
      ;
-- 2008/10/20 v1.10 ADD END
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        NULL;
    END ;
--
    -- ====================================================
    -- 品目区分取得
    -- ====================================================
    BEGIN
-- 2008/10/20 v1.10 DELETE START
--      SELECT cat.description
--      INTO   gv_item_class_name
--      FROM   xxcmn_categories2_v cat
--      WHERE  cat.category_set_name = gc_cat_set_item_class
--      AND    cat.segment1          = ir_param.item_class
--      ;
-- 2008/10/20 v1.10 DELETE END
-- 2008/10/20 v1.10 ADD START
      SELECT mct.description
      INTO   gv_item_class_name
      FROM   mtl_category_sets_b mcsb
            ,mtl_categories_b mcb
            ,mtl_categories_tl mct
      WHERE  mcsb.structure_id    = mcb.structure_id
      AND    mcsb.category_set_id = TO_NUMBER(FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_ITEM_CLASS'))
      AND    mcb.segment1         = ir_param.item_class
      AND    mcb.category_id      = mct.category_id
      AND    mct.language         = 'JA'
      ;
-- 2008/10/20 v1.10 ADD END
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        NULL;
    END ;
--
    -- ====================================================
    -- 群種別取得
    -- ====================================================
    BEGIN
      SELECT flv.meaning
      INTO   gv_crowd_kind_name
      FROM   xxcmn_lookup_values_v flv
      WHERE  flv.lookup_code   = ir_param.crowd_kind
      AND    flv.lookup_type   = gc_lookup_type_crowd_kind
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        NULL;
    END ;
--
    -- ====================================================
    -- 処理年月
    -- ====================================================
    -- 日付変換チェック
    ld_param_date := FND_DATE.STRING_TO_DATE(ir_param.exec_year_month , gc_char_ym_format) ;
    IF ( ld_param_date IS NULL ) THEN
      -- メッセージセット
      lv_retcode := gv_status_error ;
      lv_errbuf  := xxcmn_common_pkg.get_msg( iv_application   => gc_application
                                             ,iv_name          => lc_err_code
                                             ,iv_token_name1   => lc_token_name_01
                                             ,iv_token_value1  => lc_token_value
                                             ,iv_token_name2   => lc_token_name_02
                                             ,iv_token_value2  => ir_param.exec_year_month ) ;
      RAISE get_value_expt ;
    END IF ;
--
  EXCEPTION
    --*** 値取得エラー例外 ***
    WHEN get_value_expt THEN
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := lv_errmsg;
      ov_retcode := lv_retcode;
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
  END prc_initialize;
--
  /**********************************************************************************
   * Procedure Name   : prc_get_report_data
   * Description      : 明細データ取得(A-2)
   ***********************************************************************************/
  PROCEDURE prc_get_report_data(
      ir_param      IN  rec_param_data            -- 01.入力パラメータ群
     ,ot_data_rec   OUT NOCOPY tab_data_type_dtl  -- 02.取得レコード群
     ,ov_errbuf     OUT VARCHAR2                  --    エラー・メッセージ           --# 固定 #
     ,ov_retcode    OUT VARCHAR2                  --    リターン・コード             --# 固定 #
     ,ov_errmsg     OUT VARCHAR2                  --    ユーザー・エラー・メッセージ --# 固定 #
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
    cn_prod_class_id          CONSTANT NUMBER := TO_NUMBER(FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_PROD_CLASS'));
    cn_item_class_id          CONSTANT NUMBER := TO_NUMBER(FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_ITEM_CLASS'));
    cn_crowd_code_id          CONSTANT NUMBER := TO_NUMBER(FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_CROWD_CODE'));
-- 2008/10/20 v1.10 ADD START
    cn_acnt_crowd_code_id     CONSTANT NUMBER := TO_NUMBER(FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_ACNT_CROWD_CODE'));
-- 2008/10/20 v1.10 ADD END
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル・変数 ***
-- 2008/11/10 v1.16 ADD START
    ln_crowd_code_id NUMBER;
    lt_crowd_code    mtl_categories_b.segment1%TYPE;
-- 2008/11/10 v1.16 ADD END
    lv_f_date     VARCHAR2(100);
    lv_select1    VARCHAR2(5000) ;
    lv_select2    VARCHAR2(5000) ;
    lv_from       VARCHAR2(5000) ;
    lv_where      VARCHAR2(5000) ;
    lv_order_by   VARCHAR2(5000) ;
    lv_sql        VARCHAR2(32000) ;     -- データ取得用ＳＱＬ
    lv_sql2       VARCHAR2(32000) ;     -- データ取得用ＳＱＬ
    lv_sql3       VARCHAR2(32000) ;     -- データ取得用ＳＱＬ
--
    lv_sql_xfer      VARCHAR2(5000);
    lv_sql_trni      VARCHAR2(5000);
    lv_sql_adji      VARCHAR2(5000);
    lv_sql_adji_po   VARCHAR2(5000);
    lv_sql_adji_hm   VARCHAR2(5000);
    lv_sql_adji_mv   VARCHAR2(5000);
    lv_sql_adji_snt  VARCHAR2(5000);
    lv_sql_prod      VARCHAR2(5000);
    lv_sql_prod_i    VARCHAR2(5000);
    lv_sql_porc      VARCHAR2(5000);
    lv_sql_porc_po   VARCHAR2(5000);
    lv_sql_omsso     VARCHAR2(5000);
    --xfer
    lv_from_xfer         VARCHAR2(5000);
    lv_where_xfer        VARCHAR2(5000);
    --trni
    lv_from_trni         VARCHAR2(5000);
    lv_where_trni        VARCHAR2(5000);
    --adji（仕入）
    lv_from_adji_po      VARCHAR2(5000);
    lv_where_adji_po     VARCHAR2(5000);
    --adji（浜岡）
    lv_from_adji_hm      VARCHAR2(5000);
    lv_where_adji_hm     VARCHAR2(5000);
    --adji（移動）
    lv_from_adji_mv      VARCHAR2(5000);
    lv_where_adji_mv     VARCHAR2(5000);
    --adji（その他払出）
    lv_from_adji_snt     VARCHAR2(5000);
    lv_where_adji_snt    VARCHAR2(5000);
    --adji（上記以外）
    lv_from_adji         VARCHAR2(5000);
    lv_where_adji        VARCHAR2(5000);
    --prod（Reverse_idなし）品種・品目振替以外
    lv_from_prod         VARCHAR2(5000);
    lv_where_prod        VARCHAR2(5000);
    --prod（Reverse_idなし）品種・品目振替
    lv_select_prod_i     VARCHAR2(5000);
    lv_from_prod_i       VARCHAR2(5000);
    lv_where_prod_i      VARCHAR2(5000);
    --porc
    lv_select_porc       VARCHAR2(5000);
    lv_from_porc         VARCHAR2(5000);
    lv_where_porc        VARCHAR2(5000);
    --porc（仕入）
    lv_from_porc_po      VARCHAR2(5000);
    lv_where_porc_po     VARCHAR2(5000);
    --omsso
    lv_select_omso       VARCHAR2(5000);
    lv_from_omsso        VARCHAR2(5000);
    lv_where_omsso       VARCHAR2(5000);
--
    -- *** ローカル・カーソル ***
    TYPE   ref_cursor IS REF CURSOR ;
    lc_ref ref_cursor ;
--
-- 2008/10/20 v1.10 ADD START
    -- ----------------------------------------------------
    -- 入力パラメータによりカーソルの選択を行う
    -- ----------------------------------------------------
    --===============================================================
    -- 検索条件.帳票種別          ⇒ 倉庫・品目別
    -- 検索条件.群種別            ⇒ 群別/経理郡別
    -- 検索条件.倉庫コード        ⇒ 入力なし
    -- 検索条件.群コード          ⇒ 入力あり
    -- 検索条件.経理群コード      ⇒ 入力なし/入力あり
    --===============================================================
    CURSOR get_data_cur01 IS
      SELECT /*+ leading (xmrh xmril ixm itp gic2 mcb2 gic1 mcb1 iimb ximb) use_nl (xmrh xmril ixm itp gic2 mcb2 gic1 mcb1 iimb ximb) */
             iwm.whse_code                        h_whse_code
            ,iwm.whse_name                        h_whse_name
            ,itp.trans_id                         trans_id
            ,iimb.attribute15                     cost_mng_clss
            ,iimb.lot_ctl                         lot_ctl
            ,xlc.unit_ploce                       actual_unit_price
            ,CASE WHEN INSTR(xrpm.break_col_01,gv_hifn) = 0
                       THEN ''
                  WHEN xrpm.rcv_pay_div = gc_rcv_pay_div_in
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  ELSE SUBSTR(xrpm.break_col_01,INSTR(xrpm.break_col_01,gv_hifn) +1)
             END                                  column_no
            ,itp.reason_code                      reason_code
            ,itp.trans_date                       trans_date
            ,TO_CHAR(itp.trans_date, 'YYYYMM')  trans_ym
            ,CASE WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN TO_CHAR(ABS(TO_NUMBER(xrpm.rcv_pay_div)))
                  ELSE xrpm.rcv_pay_div
             END                                  rcv_pay_div
            ,xrpm.dealings_div                    dealings_div
            ,itp.doc_type                         doc_type
            ,ir_param.item_class                  item_div
            ,ir_param.goods_class                 prod_div
            ,mcb3.segment1                        crowd_code
            ,SUBSTR(mcb3.segment1, 1, 3)          crowd_low
            ,SUBSTR(mcb3.segment1, 1, 2)          crowd_mid
            ,SUBSTR(mcb3.segment1, 1, 1)          crowd_high
            ,itp.item_id                          item_id
            ,itp.lot_id                           lot_id
            ,NVL(itp.trans_qty, 0)                trans_qty
            ,xmrh.actual_arrival_date             arrival_date
            ,TO_CHAR(xmrh.actual_arrival_date, gc_char_ym_format) arrival_ym
            ,iimb.item_no                         item_code
            ,ximb.item_short_name                 item_name
      FROM   ic_tran_pnd                      itp
            ,ic_xfer_mst                      ixm
            ,xxinv_mov_req_instr_headers      xmrh
            ,xxinv_mov_req_instr_lines        xmril
            ,ic_item_mst_b                    iimb
            ,xxcmn_item_mst_b                 ximb
            ,ic_lots_mst                      ilm
            ,xxcmn_lot_cost                   xlc
            ,gmi_item_categories              gic1
            ,mtl_categories_b                 mcb1
            ,gmi_item_categories              gic2
            ,mtl_categories_b                 mcb2
            ,gmi_item_categories              gic3
            ,mtl_categories_b                 mcb3
            ,xxcmn_rcv_pay_mst                xrpm
            ,ic_whse_mst                      iwm
      WHERE  itp.doc_type            = gv_doc_type_xfer
      AND    itp.reason_code         = gv_reason_code_xfer
      AND    itp.completed_ind       = 1
      AND    xmrh.actual_arrival_date > FND_DATE.STRING_TO_DATE(gd_prv1_dt_chr,gc_char_dt_format)
      AND    xmrh.actual_arrival_date < FND_DATE.STRING_TO_DATE(gd_flw_dt_chr,gc_char_dt_format)
      AND    xmrh.mov_hdr_id         = xmril.mov_hdr_id
      AND    itp.doc_id              = ixm.transfer_id
      AND    ixm.attribute1          = TO_CHAR(xmril.mov_line_id)
      AND    ilm.item_id             = itp.item_id
      AND    ilm.lot_id              = itp.lot_id
      AND    iimb.item_id            = itp.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(itp.trans_date)
      AND    ximb.end_date_active   >= TRUNC(itp.trans_date)
      AND    gic1.item_id            = itp.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = itp.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    gic3.item_id            = itp.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
      AND    xrpm.rcv_pay_div        = CASE
                                       WHEN itp.trans_qty >= 0 THEN 1
                                       ELSE -1
                                       END
      AND    xrpm.doc_type           = itp.doc_type
      AND    xrpm.reason_code        = itp.reason_code
      AND    xrpm.break_col_01       IS NOT NULL
      AND    mcb3.segment1           = lt_crowd_code
      AND    iwm.whse_code           = itp.whse_code
-- 2009/03/05 v1.31 ADD START
      AND    iwm.attribute1          = '0'
-- 2009/03/05 v1.31 ADD END
      UNION ALL --trni
      SELECT /*+ leading (xmrh xmril ijm iaj itc gic2 mcb2 gic1 mcb1 ilm iimb ximb) use_nl (xmrh xmril ijm iaj itc gic2 mcb2 gic1 mcb1 ilm iimb ximb) */
             iwm.whse_code                        h_whse_code
            ,iwm.whse_name                        h_whse_name
            ,itc.trans_id                         trans_id
            ,iimb.attribute15                     cost_mng_clss
            ,iimb.lot_ctl                         lot_ctl
            ,xlc.unit_ploce                       actual_unit_price
            ,CASE WHEN INSTR(xrpm.break_col_01,gv_hifn) = 0
                       THEN ''
                  WHEN xrpm.rcv_pay_div = gc_rcv_pay_div_in
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  ELSE SUBSTR(xrpm.break_col_01,INSTR(xrpm.break_col_01,gv_hifn) +1)
             END                                  column_no
            ,itc.reason_code                      reason_code
            ,itc.trans_date                       trans_date
            ,TO_CHAR(itc.trans_date, 'YYYYMM')  trans_ym
            ,CASE WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN TO_CHAR(ABS(TO_NUMBER(xrpm.rcv_pay_div)))
                  ELSE xrpm.rcv_pay_div
             END                                  rcv_pay_div
            ,xrpm.dealings_div                    dealings_div
            ,itc.doc_type                         doc_type
            ,ir_param.item_class                  item_div
            ,ir_param.goods_class                 prod_div
            ,mcb3.segment1                        crowd_code
            ,SUBSTR(mcb3.segment1, 1, 3)          crowd_low
            ,SUBSTR(mcb3.segment1, 1, 2)          crowd_mid
            ,SUBSTR(mcb3.segment1, 1, 1)          crowd_high
            ,itc.item_id                          item_id
            ,itc.lot_id                           lot_id
            ,NVL(itc.trans_qty, 0)                trans_qty
            ,xmrh.actual_arrival_date             arrival_date
            ,TO_CHAR(xmrh.actual_arrival_date, gc_char_ym_format) arrival_ym
            ,iimb.item_no                         item_code
            ,ximb.item_short_name                 item_name
      FROM   ic_tran_cmp                      itc
            ,ic_adjs_jnl                      iaj
            ,ic_jrnl_mst                      ijm
            ,xxinv_mov_req_instr_headers      xmrh
            ,xxinv_mov_req_instr_lines        xmril
            ,ic_item_mst_b                    iimb
            ,xxcmn_item_mst_b                 ximb
            ,ic_lots_mst                      ilm
            ,xxcmn_lot_cost                   xlc
            ,gmi_item_categories              gic1
            ,mtl_categories_b                 mcb1
            ,gmi_item_categories              gic2
            ,mtl_categories_b                 mcb2
            ,gmi_item_categories              gic3
            ,mtl_categories_b                 mcb3
            ,xxcmn_rcv_pay_mst                xrpm
            ,ic_whse_mst                      iwm
      WHERE  itc.doc_type            = gv_doc_type_trni
      AND    itc.reason_code         = gv_reason_code_trni
      AND    xmrh.actual_arrival_date > FND_DATE.STRING_TO_DATE(gd_prv1_dt_chr,gc_char_dt_format)
      AND    xmrh.actual_arrival_date < FND_DATE.STRING_TO_DATE(gd_flw_dt_chr,gc_char_dt_format)
      AND    xmrh.mov_hdr_id         = xmril.mov_hdr_id
      AND    itc.doc_type            = iaj.trans_type
      AND    itc.doc_id              = iaj.doc_id
      AND    itc.doc_line            = iaj.doc_line
      AND    ijm.journal_id          = iaj.journal_id
      AND    ijm.attribute1          = TO_CHAR(xmril.mov_line_id)
      AND    ilm.item_id             = itc.item_id
      AND    ilm.lot_id              = itc.lot_id
      AND    iimb.item_id            = ilm.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(itc.trans_date)
      AND    ximb.end_date_active   >= TRUNC(itc.trans_date)
      AND    gic1.item_id            = itc.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = itc.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    gic3.item_id            = itc.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
-- 2008/11/19 v1.18 ADD START
      AND    xrpm.rcv_pay_div        = CASE
                                       WHEN itc.trans_qty >= 0 THEN 1
                                       ELSE -1
                                       END
-- 2008/11/19 v1.18 ADD END
      AND    xrpm.doc_type           = itc.doc_type
      AND    xrpm.reason_code        = itc.reason_code
      AND    xrpm.rcv_pay_div        = itc.line_type
      AND    xrpm.break_col_01       IS NOT NULL
      AND    mcb3.segment1           = lt_crowd_code
      AND    iwm.whse_code           = itc.whse_code
-- 2009/03/05 v1.31 ADD START
      AND    iwm.attribute1          = '0'
-- 2009/03/05 v1.31 ADD END
      UNION ALL
      SELECT /*+ leading (itc gic1 mcb1 gic2 mcb2) use_nl (itc gic1 mcb1 gic2 mcb2)*/
             iwm.whse_code                        h_whse_code
            ,iwm.whse_name                        h_whse_name
            ,itc.trans_id                         trans_id
            ,iimb.attribute15                     cost_mng_clss
            ,iimb.lot_ctl                         lot_ctl
            ,xlc.unit_ploce                       actual_unit_price
            ,CASE WHEN INSTR(xrpm.break_col_01,gv_hifn) = 0
                       THEN ''
                  WHEN xrpm.rcv_pay_div = gc_rcv_pay_div_in
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  ELSE SUBSTR(xrpm.break_col_01,INSTR(xrpm.break_col_01,gv_hifn) +1)
             END                                  column_no
            ,itc.reason_code                      reason_code
            ,itc.trans_date                       trans_date
            ,TO_CHAR(itc.trans_date, 'YYYYMM')  trans_ym
            ,CASE WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN TO_CHAR(ABS(TO_NUMBER(xrpm.rcv_pay_div)))
                  ELSE xrpm.rcv_pay_div
             END                                  rcv_pay_div
            ,xrpm.dealings_div                    dealings_div
            ,itc.doc_type                         doc_type
            ,ir_param.item_class                  item_div
            ,ir_param.goods_class                 prod_div
            ,mcb3.segment1                        crowd_code
            ,SUBSTR(mcb3.segment1, 1, 3)          crowd_low
            ,SUBSTR(mcb3.segment1, 1, 2)          crowd_mid
            ,SUBSTR(mcb3.segment1, 1, 1)          crowd_high
            ,itc.item_id                          item_id
            ,itc.lot_id                           lot_id
            ,NVL(itc.trans_qty, 0)                trans_qty
            ,itc.trans_date                       arrival_date
            ,TO_CHAR(itc.trans_date, gc_char_ym_format) arrival_ym
            ,iimb.item_no                         item_code
            ,ximb.item_short_name                 item_name
      FROM   ic_tran_cmp                      itc
            ,ic_item_mst_b                    iimb
            ,xxcmn_item_mst_b                 ximb
            ,ic_lots_mst                      ilm
            ,xxcmn_lot_cost                   xlc
            ,gmi_item_categories              gic1
            ,mtl_categories_b                 mcb1
            ,gmi_item_categories              gic2
            ,mtl_categories_b                 mcb2
            ,gmi_item_categories              gic3
            ,mtl_categories_b                 mcb3
            ,xxcmn_rcv_pay_mst                xrpm
            ,ic_whse_mst                      iwm
      WHERE  itc.doc_type            = gv_doc_type_adji    --文書タイプ
      AND    itc.reason_code        IN ('X911'
                                       ,'X912'
                                       ,'X921'
                                       ,'X922'
                                       ,'X931'
                                       ,'X932'
                                       ,'X941'
                                       ,'X952'
                                       ,'X953'
                                       ,'X954'
                                       ,'X955'
                                       ,'X956'
                                       ,'X957'
                                       ,'X958'
                                       ,'X959'
                                       ,'X960'
                                       ,'X961'
                                       ,'X962'
                                       ,'X963'
-- 2008/11/19 v1.18 UPDATE START
--                                       ,'X964')
                                       ,'X964'
                                       ,'X965'
                                       ,'X966')
-- 2008/11/19 v1.18 UPDATE END
      AND    itc.trans_date > FND_DATE.STRING_TO_DATE(gd_prv1_dt_chr,gc_char_dt_format)
      AND    itc.trans_date < FND_DATE.STRING_TO_DATE(gd_flw_dt_chr,gc_char_dt_format)
      AND    ilm.item_id             = itc.item_id
      AND    ilm.lot_id              = itc.lot_id
      AND    iimb.item_id            = ilm.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(itc.trans_date)
      AND    ximb.end_date_active   >= TRUNC(itc.trans_date)
      AND    gic1.item_id            = itc.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = itc.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    gic3.item_id            = itc.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
      AND    xrpm.doc_type           = itc.doc_type
      AND    xrpm.reason_code        = itc.reason_code
      AND    xrpm.break_col_01       IS NOT NULL
      AND    mcb3.segment1           = lt_crowd_code
      AND    iwm.whse_code           = itc.whse_code
-- 2009/03/05 v1.31 ADD START
      AND    iwm.attribute1          = '0'
-- 2009/03/05 v1.31 ADD END
      UNION ALL
      SELECT /*+ leading (itc gic1 mcb1 gic2 mcb2 xrpm) use_nl (itc gic1 mcb1 gic2 mcb2 xrpm) */
             iwm.whse_code                        h_whse_code
            ,iwm.whse_name                        h_whse_name
-- v1.33 Mod Start
--            ,itc.trans_id                         trans_id
            ,NULL                                 trans_id
-- v1.33 Mod End
            ,iimb.attribute15                     cost_mng_clss
            ,iimb.lot_ctl                         lot_ctl
            ,xlc.unit_ploce                       actual_unit_price
            ,CASE WHEN INSTR(xrpm.break_col_01,gv_hifn) = 0
                       THEN ''
                  WHEN xrpm.rcv_pay_div = gc_rcv_pay_div_in
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  ELSE SUBSTR(xrpm.break_col_01,INSTR(xrpm.break_col_01,gv_hifn) +1)
             END                                  column_no
            ,itc.reason_code                      reason_code
            ,itc.trans_date                       trans_date
            ,TO_CHAR(itc.trans_date, 'YYYYMM')  trans_ym
            ,CASE WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN TO_CHAR(ABS(TO_NUMBER(xrpm.rcv_pay_div)))
                  ELSE xrpm.rcv_pay_div
             END                                  rcv_pay_div
            ,xrpm.dealings_div                    dealings_div
            ,itc.doc_type                         doc_type
            ,ir_param.item_class                  item_div
            ,ir_param.goods_class                 prod_div
            ,mcb3.segment1                        crowd_code
            ,SUBSTR(mcb3.segment1, 1, 3)          crowd_low
            ,SUBSTR(mcb3.segment1, 1, 2)          crowd_mid
            ,SUBSTR(mcb3.segment1, 1, 1)          crowd_high
            ,itc.item_id                          item_id
            ,itc.lot_id                           lot_id
-- v1.33 Mod Start
--            ,NVL(itc.trans_qty, 0)                trans_qty
            ,SUM(NVL(itc.trans_qty, 0))           trans_qty
-- v1.33 Mod End
            ,itc.trans_date                       arrival_date
            ,TO_CHAR(itc.trans_date, gc_char_ym_format) arrival_ym
            ,iimb.item_no                         item_code
            ,ximb.item_short_name                 item_name
      FROM   ic_tran_cmp                      itc
-- v1.33 Add Start
            ,ic_adjs_jnl                      iaj
            ,ic_jrnl_mst                      ijm
-- v1.33 Add End
            ,ic_item_mst_b                    iimb
            ,xxcmn_item_mst_b                 ximb
            ,ic_lots_mst                      ilm
            ,xxcmn_lot_cost                   xlc
            ,gmi_item_categories              gic1
            ,mtl_categories_b                 mcb1
            ,gmi_item_categories              gic2
            ,mtl_categories_b                 mcb2
            ,gmi_item_categories              gic3
            ,mtl_categories_b                 mcb3
            ,xxcmn_rcv_pay_mst                xrpm
            ,ic_whse_mst                      iwm
      WHERE  itc.doc_type            = gv_doc_type_adji
      AND    itc.reason_code         = gv_reason_code_adji_po
      AND    itc.trans_date > FND_DATE.STRING_TO_DATE(gd_prv1_dt_chr,gc_char_dt_format)
      AND    itc.trans_date < FND_DATE.STRING_TO_DATE(gd_flw_dt_chr,gc_char_dt_format)
-- v1.33 Add Start
      AND    iaj.trans_type          = itc.doc_type
      AND    iaj.doc_id              = itc.doc_id
      AND    iaj.doc_line            = itc.doc_line
      AND    ijm.journal_id          = iaj.journal_id
-- v1.33 Add End
      AND    ilm.item_id             = itc.item_id
      AND    ilm.lot_id              = itc.lot_id
      AND    iimb.item_id            = ilm.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(itc.trans_date)
      AND    ximb.end_date_active   >= TRUNC(itc.trans_date)
      AND    gic1.item_id            = itc.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = itc.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    gic3.item_id            = itc.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
      AND    xrpm.doc_type           = itc.doc_type
      AND    xrpm.reason_code        = itc.reason_code
      AND    xrpm.break_col_01       IS NOT NULL
      AND    mcb3.segment1           = lt_crowd_code
      AND    iwm.whse_code           = itc.whse_code
-- 2009/03/05 v1.31 ADD START
      AND    iwm.attribute1          = '0'
-- 2009/03/05 v1.31 ADD END
-- v1.33 Add Start
      GROUP BY
             iwm.whse_code                        -- h_whse_code
            ,iwm.whse_name                        -- h_whse_name
            ,iimb.attribute15                     -- cost_mng_clss
            ,iimb.lot_ctl                         -- lot_ctl
            ,xlc.unit_ploce                       -- actual_unit_price
            ,CASE WHEN INSTR(xrpm.break_col_01,gv_hifn) = 0
                       THEN ''
                  WHEN xrpm.rcv_pay_div = gc_rcv_pay_div_in
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  ELSE SUBSTR(xrpm.break_col_01,INSTR(xrpm.break_col_01,gv_hifn) +1)
             END                                  -- column_no
            ,itc.reason_code                      -- reason_code
            ,itc.trans_date                       -- trans_date
            ,TO_CHAR(itc.trans_date, 'YYYYMM')    -- trans_ym
            ,CASE WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN TO_CHAR(ABS(TO_NUMBER(xrpm.rcv_pay_div)))
                  ELSE xrpm.rcv_pay_div
             END                                  -- rcv_pay_div
            ,xrpm.dealings_div                    -- dealings_div
            ,itc.doc_type                         -- doc_type
            ,ir_param.item_class                  -- item_div
            ,ir_param.goods_class                 -- prod_div
            ,mcb3.segment1                        -- crowd_code
            ,SUBSTR(mcb3.segment1, 1, 3)          -- crowd_low
            ,SUBSTR(mcb3.segment1, 1, 2)          -- crowd_mid
            ,SUBSTR(mcb3.segment1, 1, 1)          -- crowd_high
            ,itc.item_id                          -- item_id
            ,itc.lot_id                           -- lot_id
            ,itc.trans_date                       -- arrival_date
            ,TO_CHAR(itc.trans_date, gc_char_ym_format) -- arrival_ym
            ,iimb.item_no                         -- item_code
            ,ximb.item_short_name                 -- item_name
            ,ijm.attribute1                       -- 受入返品実績アドオン.取引ID
-- v1.33 Add End
      UNION ALL
      SELECT /*+ leading (itc gic1 mcb1 gic2 mcb2 xrpm) use_nl (itc gic1 mcb1 gic2 mcb2 xrpm) */
             iwm.whse_code                        h_whse_code
            ,iwm.whse_name                        h_whse_name
            ,itc.trans_id                         trans_id
            ,iimb.attribute15                     cost_mng_clss
            ,iimb.lot_ctl                         lot_ctl
            ,xlc.unit_ploce                       actual_unit_price
            ,CASE WHEN INSTR(xrpm.break_col_01,gv_hifn) = 0
                       THEN ''
                  WHEN xrpm.rcv_pay_div = gc_rcv_pay_div_in
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  ELSE SUBSTR(xrpm.break_col_01,INSTR(xrpm.break_col_01,gv_hifn) +1)
             END                                  column_no
            ,itc.reason_code                      reason_code
            ,itc.trans_date                       trans_date
            ,TO_CHAR(itc.trans_date, 'YYYYMM')  trans_ym
            ,CASE WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN TO_CHAR(ABS(TO_NUMBER(xrpm.rcv_pay_div)))
                  ELSE xrpm.rcv_pay_div
             END                                  rcv_pay_div
            ,xrpm.dealings_div                    dealings_div
            ,itc.doc_type                         doc_type
            ,ir_param.item_class                  item_div
            ,ir_param.goods_class                 prod_div
            ,mcb3.segment1                        crowd_code
            ,SUBSTR(mcb3.segment1, 1, 3)          crowd_low
            ,SUBSTR(mcb3.segment1, 1, 2)          crowd_mid
            ,SUBSTR(mcb3.segment1, 1, 1)          crowd_high
            ,itc.item_id                          item_id
            ,itc.lot_id                           lot_id
            ,NVL(itc.trans_qty, 0)                trans_qty
            ,itc.trans_date                       arrival_date
            ,TO_CHAR(itc.trans_date, gc_char_ym_format) arrival_ym
            ,iimb.item_no                         item_code
            ,ximb.item_short_name                 item_name
      FROM   ic_tran_cmp                      itc
            ,ic_item_mst_b                    iimb
            ,xxcmn_item_mst_b                 ximb
            ,ic_lots_mst                      ilm
            ,xxcmn_lot_cost                   xlc
            ,gmi_item_categories              gic1
            ,mtl_categories_b                 mcb1
            ,gmi_item_categories              gic2
            ,mtl_categories_b                 mcb2
            ,gmi_item_categories              gic3
            ,mtl_categories_b                 mcb3
            ,xxcmn_rcv_pay_mst                xrpm
            ,ic_whse_mst                      iwm
      WHERE  itc.doc_type            = gv_doc_type_adji
      AND    itc.reason_code         = gv_reason_code_adji_hama
      AND    itc.trans_date > FND_DATE.STRING_TO_DATE(gd_prv1_dt_chr,gc_char_dt_format)
      AND    itc.trans_date < FND_DATE.STRING_TO_DATE(gd_flw_dt_chr,gc_char_dt_format)
      AND    ilm.item_id             = itc.item_id
      AND    ilm.lot_id              = itc.lot_id
      AND    iimb.item_id            = ilm.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(itc.trans_date)
      AND    ximb.end_date_active   >= TRUNC(itc.trans_date)
      AND    gic1.item_id            = itc.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = itc.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    gic3.item_id            = itc.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
      AND    xrpm.doc_type           = itc.doc_type
      AND    xrpm.reason_code        = itc.reason_code
      AND    xrpm.break_col_01       IS NOT NULL
      AND    mcb3.segment1           = lt_crowd_code
      AND    iwm.whse_code           = itc.whse_code
-- 2009/03/05 v1.31 ADD START
      AND    iwm.attribute1          = '0'
-- 2009/03/05 v1.31 ADD END
      UNION ALL --adji_mv
      SELECT /*+ leading (xmrh xmrl ijm iaj itc gic1 mcb1 gic2 mcb2) use_nl (xmrh xmrl ijm iaj itc gic1 mcb1 gic2 mcb2) */
             iwm.whse_code                        h_whse_code
            ,iwm.whse_name                        h_whse_name
            ,itc.trans_id                         trans_id
            ,iimb.attribute15                     cost_mng_clss
            ,iimb.lot_ctl                         lot_ctl
            ,xlc.unit_ploce                       actual_unit_price
            ,CASE WHEN INSTR(xrpm.break_col_01,gv_hifn) = 0
                       THEN ''
                  WHEN xrpm.rcv_pay_div = gc_rcv_pay_div_in
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  ELSE SUBSTR(xrpm.break_col_01,INSTR(xrpm.break_col_01,gv_hifn) +1)
             END                                  column_no
            ,itc.reason_code                      reason_code
            ,itc.trans_date                       trans_date
            ,TO_CHAR(itc.trans_date, 'YYYYMM')  trans_ym
-- 2008/12/11 v1.26 N.Yoshida mod start
--            ,gc_rcv_pay_div_adj                   rcv_pay_div
            ,xrpm.rcv_pay_div                     rcv_pay_div
-- 2008/12/11 v1.26 N.Yoshida mod end
            ,xrpm.dealings_div                    dealings_div
            ,itc.doc_type                         doc_type
            ,ir_param.item_class                  item_div
            ,ir_param.goods_class                 prod_div
            ,mcb3.segment1                        crowd_code
            ,SUBSTR(mcb3.segment1, 1, 3)          crowd_low
            ,SUBSTR(mcb3.segment1, 1, 2)          crowd_mid
            ,SUBSTR(mcb3.segment1, 1, 1)          crowd_high
            ,itc.item_id                          item_id
            ,itc.lot_id                           lot_id
-- 2008/12/11 v1.26 N.Yoshida mod start
--            ,ABS(NVL(itc.trans_qty, 0))           trans_qty
            ,NVL(itc.trans_qty, 0)                trans_qty
-- 2008/12/11 v1.26 N.Yoshida mod end
            ,xmrh.actual_arrival_date             arrival_date
            ,TO_CHAR(xmrh.actual_arrival_date, gc_char_ym_format) arrival_ym
            ,iimb.item_no                         item_code
            ,ximb.item_short_name                 item_name
      FROM   ic_tran_cmp                      itc
            ,ic_adjs_jnl                      iaj
            ,ic_jrnl_mst                      ijm
            ,xxinv_mov_req_instr_headers      xmrh
            ,xxinv_mov_req_instr_lines        xmrl
            ,ic_item_mst_b                    iimb
            ,xxcmn_item_mst_b                 ximb
            ,ic_lots_mst                      ilm
            ,xxcmn_lot_cost                   xlc
            ,gmi_item_categories              gic1
            ,mtl_categories_b                 mcb1
            ,gmi_item_categories              gic2
            ,mtl_categories_b                 mcb2
            ,gmi_item_categories              gic3
            ,mtl_categories_b                 mcb3
            ,xxcmn_rcv_pay_mst                xrpm
            ,ic_whse_mst                      iwm
      WHERE  itc.doc_type            = gv_doc_type_adji
      AND    itc.reason_code         = gv_reason_code_adji_move
      AND    xmrh.actual_arrival_date > FND_DATE.STRING_TO_DATE(gd_prv1_dt_chr,gc_char_dt_format)
      AND    xmrh.actual_arrival_date < FND_DATE.STRING_TO_DATE(gd_flw_dt_chr,gc_char_dt_format)
      AND    iaj.trans_type          = itc.doc_type
      AND    iaj.doc_id              = itc.doc_id
      AND    iaj.doc_line            = itc.doc_line
      AND    ijm.journal_id          = iaj.journal_id
      AND    ijm.attribute1          = TO_CHAR(xmrl.mov_line_id)
      AND    xmrh.mov_hdr_id         = xmrl.mov_hdr_id
      AND    ilm.item_id             = itc.item_id
      AND    ilm.lot_id              = itc.lot_id
      AND    iimb.item_id            = ilm.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(itc.trans_date)
      AND    ximb.end_date_active   >= TRUNC(itc.trans_date)
      AND    gic1.item_id            = itc.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = itc.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    gic3.item_id            = itc.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
-- 2008/12/11 v1.26 N.Yoshida mod start
      AND    xrpm.rcv_pay_div        = CASE
--                                       WHEN itc.trans_qty >= 0 THEN 1
--                                       ELSE -1
                                       WHEN itc.trans_qty >= 0 THEN -1
                                       ELSE 1
                                       END
-- 2008/12/11 v1.26 N.Yoshida mod end
      AND    xrpm.doc_type           = itc.doc_type
      AND    xrpm.reason_code        = itc.reason_code
      AND    xrpm.break_col_01       IS NOT NULL
      AND    mcb3.segment1           = lt_crowd_code
      AND    iwm.whse_code           = itc.whse_code
-- 2009/03/05 v1.31 ADD START
      AND    iwm.attribute1          = '0'
-- 2009/03/05 v1.31 ADD END
      UNION ALL --adji_snt
      SELECT /*+ leading (itc gic1 mcb1 gic2 mcb2) use_nl (itc gic1 mcb1 gic2 mcb2) */
             iwm.whse_code                        h_whse_code
            ,iwm.whse_name                        h_whse_name
            ,itc.trans_id                         trans_id
            ,iimb.attribute15                     cost_mng_clss
            ,iimb.lot_ctl                         lot_ctl
            ,xlc.unit_ploce                       actual_unit_price
            ,CASE WHEN INSTR(xrpm.break_col_01,gv_hifn) = 0
                       THEN ''
                  WHEN xrpm.rcv_pay_div = gc_rcv_pay_div_in
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  ELSE SUBSTR(xrpm.break_col_01,INSTR(xrpm.break_col_01,gv_hifn) +1)
             END                                  column_no
            ,itc.reason_code                      reason_code
            ,itc.trans_date                       trans_date
            ,TO_CHAR(itc.trans_date, 'YYYYMM')  trans_ym
            ,CASE WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN TO_CHAR(ABS(TO_NUMBER(xrpm.rcv_pay_div)))
                  ELSE xrpm.rcv_pay_div
             END                                  rcv_pay_div
            ,xrpm.dealings_div                    dealings_div
            ,itc.doc_type                         doc_type
            ,ir_param.item_class                  item_div
            ,ir_param.goods_class                 prod_div
            ,mcb3.segment1                        crowd_code
            ,SUBSTR(mcb3.segment1, 1, 3)          crowd_low
            ,SUBSTR(mcb3.segment1, 1, 2)          crowd_mid
            ,SUBSTR(mcb3.segment1, 1, 1)          crowd_high
            ,itc.item_id                          item_id
            ,itc.lot_id                           lot_id
            ,NVL(itc.trans_qty, 0)                trans_qty
            ,itc.trans_date                       arrival_date
            ,TO_CHAR(itc.trans_date, gc_char_ym_format) arrival_ym
            ,iimb.item_no                         item_code
            ,ximb.item_short_name                 item_name
      FROM   ic_tran_cmp                      itc
            ,ic_item_mst_b                    iimb
            ,xxcmn_item_mst_b                 ximb
            ,ic_lots_mst                      ilm
            ,xxcmn_lot_cost                   xlc
            ,gmi_item_categories              gic1
            ,mtl_categories_b                 mcb1
            ,gmi_item_categories              gic2
            ,mtl_categories_b                 mcb2
            ,gmi_item_categories              gic3
            ,mtl_categories_b                 mcb3
            ,xxcmn_rcv_pay_mst                xrpm
            ,ic_whse_mst                      iwm
      WHERE  itc.doc_type            = gv_doc_type_adji
      AND    itc.reason_code        IN (gv_reason_code_adji_itm
                                       ,gv_reason_code_adji_itm_u
                                       ,gv_reason_code_adji_snt_u
                                       ,gv_reason_code_adji_snt)
      AND    itc.trans_date > FND_DATE.STRING_TO_DATE(gd_prv1_dt_chr,gc_char_dt_format)
      AND    itc.trans_date < FND_DATE.STRING_TO_DATE(gd_flw_dt_chr,gc_char_dt_format)
      AND    ilm.item_id             = itc.item_id
      AND    ilm.lot_id              = itc.lot_id
      AND    iimb.item_id            = ilm.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(itc.trans_date)
      AND    ximb.end_date_active   >= TRUNC(itc.trans_date)
      AND    gic1.item_id            = itc.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = itc.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    gic3.item_id            = itc.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
-- 2008/11/19 v1.18 DELETE START
      --AND    xrpm.rcv_pay_div        = CASE
      --                                 WHEN itc.trans_qty >= 0 THEN 1
      --                                 ELSE -1
      --                                 END
-- 2008/11/19 v1.18 DELETE END
      AND    xrpm.doc_type           = itc.doc_type
      AND    xrpm.reason_code        = itc.reason_code
      AND    xrpm.break_col_01       IS NOT NULL
      AND    mcb3.segment1           = lt_crowd_code
      AND    iwm.whse_code           = itc.whse_code
-- 2009/03/05 v1.31 ADD START
      AND    iwm.attribute1          = '0'
-- 2009/03/05 v1.31 ADD END
      UNION ALL
      SELECT /*+ leading (itp gic1 mcb1 gic2 mcb2) use_nl (itp gic1 mcb1 gic2 mcb2)*/
             iwm.whse_code                        h_whse_code
            ,iwm.whse_name                        h_whse_name
            ,itp.trans_id                         trans_id
            ,iimb.attribute15                     cost_mng_clss
            ,iimb.lot_ctl                         lot_ctl
            ,xlc.unit_ploce                       actual_unit_price
            ,CASE WHEN INSTR(xrpm.break_col_01,gv_hifn) = 0
                       THEN ''
                  WHEN xrpm.rcv_pay_div = gc_rcv_pay_div_in
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  ELSE SUBSTR(xrpm.break_col_01,INSTR(xrpm.break_col_01,gv_hifn) +1)
             END                                  column_no
            ,itp.reason_code                      reason_code
            ,itp.trans_date                       trans_date
            ,TO_CHAR(itp.trans_date, 'YYYYMM')  trans_ym
            ,CASE WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN TO_CHAR(ABS(TO_NUMBER(xrpm.rcv_pay_div)))
                  ELSE xrpm.rcv_pay_div
             END                                  rcv_pay_div
            ,xrpm.dealings_div                    dealings_div
            ,itp.doc_type                         doc_type
            ,ir_param.item_class                  item_div
            ,ir_param.goods_class                 prod_div
            ,mcb3.segment1                        crowd_code
            ,SUBSTR(mcb3.segment1, 1, 3)          crowd_low
            ,SUBSTR(mcb3.segment1, 1, 2)          crowd_mid
            ,SUBSTR(mcb3.segment1, 1, 1)          crowd_high
            ,itp.item_id                          item_id
            ,itp.lot_id                           lot_id
            ,NVL(itp.trans_qty, 0)                trans_qty
            ,itp.trans_date                       arrival_date
            ,TO_CHAR(itp.trans_date, gc_char_ym_format) arrival_ym
            ,iimb.item_no                         item_code
            ,ximb.item_short_name                 item_name
      FROM   ic_tran_pnd                      itp
            ,ic_item_mst_b                    iimb
            ,xxcmn_item_mst_b                 ximb
            ,ic_lots_mst                      ilm
            ,xxcmn_lot_cost                   xlc
            ,gmi_item_categories              gic1
            ,mtl_categories_b                 mcb1
            ,gmi_item_categories              gic2
            ,mtl_categories_b                 mcb2
            ,gmi_item_categories              gic3
            ,mtl_categories_b                 mcb3
            ,gme_material_details             gmd
            ,gme_batch_header                 gbh
            ,gmd_routings_b                   grb
            ,xxcmn_rcv_pay_mst                xrpm
            ,ic_whse_mst                      iwm
      WHERE  itp.doc_type            = gv_doc_type_prod
      AND    itp.completed_ind       = 1
      AND    itp.trans_date > FND_DATE.STRING_TO_DATE(gd_prv1_dt_chr,gc_char_dt_format)
      AND    itp.trans_date < FND_DATE.STRING_TO_DATE(gd_flw_dt_chr,gc_char_dt_format)
      AND    itp.reverse_id          IS NULL
      AND    ilm.item_id             = itp.item_id
      AND    ilm.lot_id              = itp.lot_id
      AND    iimb.item_id            = ilm.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(itp.trans_date)
      AND    ximb.end_date_active   >= TRUNC(itp.trans_date)
      AND    gic1.item_id            = itp.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = itp.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    gic3.item_id            = itp.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
      AND    gmd.batch_id            = itp.doc_id
      AND    gmd.line_no             = itp.doc_line
      AND    gmd.line_type           = itp.line_type
      AND    gbh.batch_id            = gmd.batch_id
      AND    grb.routing_id          = gbh.routing_id
      AND    xrpm.routing_class      = grb.routing_class
      AND    xrpm.line_type          = gmd.line_type
      AND    (((gmd.attribute5 IS NULL) AND (xrpm.hit_in_div IS NULL))
             OR (xrpm.hit_in_div = gmd.attribute5))
      AND    itp.doc_type            = xrpm.doc_type
      AND    itp.line_type           = xrpm.line_type
      AND    xrpm.break_col_01       IS NOT NULL
      AND    xrpm.routing_class      <> '70'
      AND    mcb3.segment1           = lt_crowd_code
      AND    iwm.whse_code           = itp.whse_code
-- 2009/03/05 v1.31 ADD START
      AND    iwm.attribute1          = '0'
-- 2009/03/05 v1.31 ADD END
      UNION ALL
      SELECT /*+ leading (itp gic1 mcb1 gic2 mcb2 gmd gbh grb) use_nl (itp gic1 mcb1 gic2 mcb2 gmd gbh grb)*/
             iwm.whse_code                        h_whse_code
            ,iwm.whse_name                        h_whse_name
            ,itp.trans_id                         trans_id
            ,iimb.attribute15                     cost_mng_clss
            ,iimb.lot_ctl                         lot_ctl
            ,xlc.unit_ploce                       actual_unit_price
            ,CASE WHEN INSTR(xrpm.break_col_01,gv_hifn) = 0
                       THEN ''
                  WHEN xrpm.rcv_pay_div = gc_rcv_pay_div_in
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  ELSE SUBSTR(xrpm.break_col_01,INSTR(xrpm.break_col_01,gv_hifn) +1)
             END                                  column_no
            ,itp.reason_code                      reason_code
            ,itp.trans_date                       trans_date
            ,TO_CHAR(itp.trans_date, 'YYYYMM')  trans_ym
            ,CASE WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN TO_CHAR(ABS(TO_NUMBER(xrpm.rcv_pay_div)))
                  ELSE xrpm.rcv_pay_div
             END                                  rcv_pay_div
            ,xrpm.dealings_div                    dealings_div
            ,itp.doc_type                         doc_type
            ,ir_param.item_class                  item_div
            ,ir_param.goods_class                 prod_div
            ,mcb3.segment1                        crowd_code
            ,SUBSTR(mcb3.segment1, 1, 3)          crowd_low
            ,SUBSTR(mcb3.segment1, 1, 2)          crowd_mid
            ,SUBSTR(mcb3.segment1, 1, 1)          crowd_high
            ,itp.item_id                          item_id
            ,itp.lot_id                           lot_id
            ,NVL(itp.trans_qty, 0)                trans_qty
            ,itp.trans_date                       arrival_date
            ,TO_CHAR(itp.trans_date, gc_char_ym_format) arrival_ym
            ,iimb.item_no                         item_code
            ,ximb.item_short_name                 item_name
      FROM   ic_tran_pnd                      itp
            ,ic_item_mst_b                    iimb
            ,xxcmn_item_mst_b                 ximb
            ,ic_lots_mst                      ilm
            ,xxcmn_lot_cost                   xlc
            ,gmi_item_categories              gic1
            ,mtl_categories_b                 mcb1
            ,gmi_item_categories              gic2
            ,mtl_categories_b                 mcb2
            ,gmi_item_categories              gic3
            ,mtl_categories_b                 mcb3
            ,gme_material_details             gmd
            ,gme_batch_header                 gbh
            ,gmd_routings_b                   grb
            ,xxcmn_rcv_pay_mst                xrpm
            ,ic_whse_mst                      iwm
      WHERE  itp.doc_type            = gv_doc_type_prod
      AND    itp.completed_ind       = 1
      AND    itp.trans_date > FND_DATE.STRING_TO_DATE(gd_prv1_dt_chr,gc_char_dt_format)
      AND    itp.trans_date < FND_DATE.STRING_TO_DATE(gd_flw_dt_chr,gc_char_dt_format)
      AND    itp.reverse_id          IS NULL
      AND    ilm.item_id             = itp.item_id
      AND    ilm.lot_id              = itp.lot_id
      AND    iimb.item_id            = ilm.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(itp.trans_date)
      AND    ximb.end_date_active   >= TRUNC(itp.trans_date)
      AND    gic1.item_id            = itp.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = itp.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    mcb2.segment1           IN ('1','4')
      AND    gic3.item_id            = itp.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
      AND    gmd.batch_id            = itp.doc_id
      AND    gmd.line_no             = itp.doc_line
      AND    gmd.line_type           = itp.line_type
      AND    gbh.batch_id            = gmd.batch_id
      AND    grb.routing_id          = gbh.routing_id
      AND    xrpm.routing_class      = grb.routing_class
      AND    xrpm.line_type          = gmd.line_type
      AND    (((gmd.attribute5 IS NULL) AND (xrpm.hit_in_div IS NULL))
             OR (xrpm.hit_in_div = gmd.attribute5))
      AND    itp.doc_type            = xrpm.doc_type
      AND    itp.line_type           = xrpm.line_type
      AND    xrpm.break_col_01       IS NOT NULL
      AND    xrpm.routing_class      = '70'
      AND    (EXISTS (SELECT 1
                      FROM   gme_material_details gmd2
                            ,gmi_item_categories  gic
                            ,mtl_categories_b     mcb
                      WHERE  gmd2.batch_id   = gmd.batch_id
                      AND    gmd2.line_no    = gmd.line_no
                      AND    gmd2.line_type  = -1
                      AND    gic.item_id     = gmd2.item_id
                      AND    gic.category_set_id = cn_item_class_id
                      AND    gic.category_id = mcb.category_id
                      AND    mcb.segment1    = xrpm.item_div_origin))
      AND    (EXISTS (SELECT 1
                      FROM   gme_material_details gmd3
                            ,gmi_item_categories  gic
                            ,mtl_categories_b     mcb
                      WHERE  gmd3.batch_id   = gmd.batch_id
                      AND    gmd3.line_no    = gmd.line_no
                      AND    gmd3.line_type  = 1
                      AND    gic.item_id     = gmd3.item_id
                      AND    gic.category_set_id = cn_item_class_id
                      AND    gic.category_id = mcb.category_id
                      AND    mcb.segment1    = xrpm.item_div_ahead))
      AND    mcb3.segment1           = lt_crowd_code
      AND    iwm.whse_code           = itp.whse_code
-- 2009/03/05 v1.31 ADD START
      AND    iwm.attribute1          = '0'
-- 2009/03/05 v1.31 ADD END
      UNION ALL
      SELECT /*+ leading (xoha xola rsl itp gic1 mcb1 gic2 mcb2 ooha otta) use_nl (xoha xola rsl itp gic1 mcb1 gic2 mcb2 ooha otta) */
             iwm.whse_code                        h_whse_code
            ,iwm.whse_name                        h_whse_name
            ,itp.trans_id                         trans_id
            ,iimb.attribute15                     cost_mng_clss
            ,iimb.lot_ctl                         lot_ctl
            ,xlc.unit_ploce                       actual_unit_price
            ,CASE WHEN INSTR(xrpm.break_col_01,gv_hifn) = 0
                       THEN ''
                  WHEN xrpm.rcv_pay_div = gc_rcv_pay_div_in
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  ELSE SUBSTR(xrpm.break_col_01,INSTR(xrpm.break_col_01,gv_hifn) +1)
             END                                  column_no
            ,itp.reason_code                      reason_code
            ,itp.trans_date                       trans_date
            ,TO_CHAR(itp.trans_date, 'YYYYMM')  trans_ym
            ,CASE WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN TO_CHAR(ABS(TO_NUMBER(xrpm.rcv_pay_div)))
                  ELSE xrpm.rcv_pay_div
             END                                  rcv_pay_div
            ,xrpm.dealings_div                    dealings_div
            ,itp.doc_type                         doc_type
            ,ir_param.item_class                  item_div
            ,ir_param.goods_class                 prod_div
            ,mcb3.segment1                        crowd_code
            ,SUBSTR(mcb3.segment1, 1, 3)          crowd_low
            ,SUBSTR(mcb3.segment1, 1, 2)          crowd_mid
            ,SUBSTR(mcb3.segment1, 1, 1)          crowd_high
            ,itp.item_id                          item_id
            ,itp.lot_id                           lot_id
            ,NVL(itp.trans_qty, 0)                trans_qty
            ,xoha.arrival_date                    arrival_date
            ,TO_CHAR(xoha.arrival_date, gc_char_ym_format) arrival_ym
            ,iimb.item_no                         item_code
            ,ximb.item_short_name                 item_name
      FROM   ic_tran_pnd                      itp
            ,rcv_shipment_lines               rsl
            ,oe_order_headers_all             ooha
            ,oe_transaction_types_all         otta
            ,xxwsh_order_headers_all          xoha
            ,xxwsh_order_lines_all            xola
            ,ic_item_mst_b                    iimb
            ,xxcmn_item_mst_b                 ximb
            ,ic_lots_mst                      ilm
            ,xxcmn_lot_cost                   xlc
            ,gmi_item_categories              gic1
            ,mtl_categories_b                 mcb1
            ,gmi_item_categories              gic2
            ,mtl_categories_b                 mcb2
            ,gmi_item_categories              gic3
            ,mtl_categories_b                 mcb3
            ,xxcmn_rcv_pay_mst                xrpm
            ,ic_whse_mst                      iwm
      WHERE  itp.doc_type            = gv_doc_type_porc
      AND    itp.completed_ind       = 1
      AND    xoha.latest_external_flag = 'Y'
      AND    xoha.arrival_date > FND_DATE.STRING_TO_DATE(gd_prv1_dt_chr,gc_char_dt_format)
      AND    xoha.arrival_date < FND_DATE.STRING_TO_DATE(gd_flw_dt_chr,gc_char_dt_format)
      AND    xoha.req_status         IN ('04','08')
      AND    ilm.item_id             = itp.item_id
      AND    ilm.lot_id              = itp.lot_id
      AND    iimb.item_id            = itp.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(itp.trans_date)
      AND    ximb.end_date_active   >= TRUNC(itp.trans_date)
      AND    gic1.item_id            = itp.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = itp.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    gic3.item_id            = itp.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
      AND    rsl.shipment_header_id  = itp.doc_id
      AND    rsl.line_num            = itp.doc_line
      AND    rsl.oe_order_header_id  = xola.header_id
      AND    rsl.oe_order_line_id    = xola.line_id
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    ((otta.attribute4           <> '2')
             OR  (otta.attribute4       IS NULL))
      AND    otta.attribute1         IN ('1','2')
      AND    xoha.header_id          = ooha.header_id
      AND    xola.order_header_id    = xoha.order_header_id
      AND    xola.request_item_code  = xola.shipping_item_code
      AND    xrpm.doc_type           = itp.doc_type
      AND    xrpm.source_document_code = 'RMA'
      AND    xrpm.dealings_div       IN ('101','103')
      AND    xrpm.shipment_provision_div = DECODE(xoha.req_status,'04','1','08','2')
      AND    xrpm.shipment_provision_div = otta.attribute1
      AND    ((xrpm.ship_prov_rcv_pay_category IS NULL)
             OR (xrpm.ship_prov_rcv_pay_category = otta.attribute11))
      AND    xrpm.break_col_01       IS NOT NULL
      AND    xrpm.item_div_origin    IS NULL
      AND    xrpm.item_div_ahead     IS NULL
      AND    mcb3.segment1           = lt_crowd_code
      AND    iwm.whse_code           = itp.whse_code
-- 2009/03/05 v1.31 ADD START
      AND    iwm.attribute1          = '0'
-- 2009/03/05 v1.31 ADD END
      UNION ALL
      SELECT /*+ leading (xoha xola rsl itp gic1 mcb1 gic2 mcb2 ooha otta) use_nl (xoha xola rsl itp gic1 mcb1 gic2 mcb2 ooha otta) */
             iwm.whse_code                        h_whse_code
            ,iwm.whse_name                        h_whse_name
            ,itp.trans_id                         trans_id
            ,iimb.attribute15                     cost_mng_clss
            ,iimb.lot_ctl                         lot_ctl
            ,xlc.unit_ploce                       actual_unit_price
            ,CASE WHEN INSTR(xrpm.break_col_01,gv_hifn) = 0
                       THEN ''
                  WHEN xrpm.rcv_pay_div = gc_rcv_pay_div_in
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  ELSE SUBSTR(xrpm.break_col_01,INSTR(xrpm.break_col_01,gv_hifn) +1)
             END                                  column_no
            ,itp.reason_code                      reason_code
            ,itp.trans_date                       trans_date
            ,TO_CHAR(itp.trans_date, 'YYYYMM')  trans_ym
            ,CASE WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN TO_CHAR(ABS(TO_NUMBER(xrpm.rcv_pay_div)))
                  ELSE xrpm.rcv_pay_div
             END                                  rcv_pay_div
            ,xrpm.dealings_div                    dealings_div
            ,itp.doc_type                         doc_type
            ,ir_param.item_class                  item_div
            ,ir_param.goods_class                 prod_div
            ,mcb3.segment1                        crowd_code
            ,SUBSTR(mcb3.segment1, 1, 3)          crowd_low
            ,SUBSTR(mcb3.segment1, 1, 2)          crowd_mid
            ,SUBSTR(mcb3.segment1, 1, 1)          crowd_high
            ,iimb.item_id                         item_id
            ,itp.lot_id                           lot_id
            ,NVL(itp.trans_qty, 0)                trans_qty
            ,xoha.arrival_date                      arrival_date
            ,TO_CHAR(xoha.arrival_date, gc_char_ym_format) arrival_ym
            ,iimb.item_no                         item_code
            ,ximb.item_short_name                 item_name
      FROM   ic_tran_pnd                      itp
            ,rcv_shipment_lines               rsl
            ,oe_order_headers_all             ooha
            ,oe_transaction_types_all         otta
            ,xxwsh_order_headers_all          xoha
            ,xxwsh_order_lines_all            xola
            ,ic_item_mst_b                    iimb
            ,ic_item_mst_b                    iimb2
            ,xxcmn_item_mst_b                 ximb
            ,ic_lots_mst                      ilm
            ,xxcmn_lot_cost                   xlc
            ,gmi_item_categories              gic1
            ,mtl_categories_b                 mcb1
            ,gmi_item_categories              gic2
            ,mtl_categories_b                 mcb2
            ,gmi_item_categories              gic3
            ,mtl_categories_b                 mcb3
            ,gmi_item_categories              gic4
            ,mtl_categories_b                 mcb4
            ,xxcmn_rcv_pay_mst                xrpm
            ,ic_whse_mst                      iwm
      WHERE  itp.doc_type            = gv_doc_type_porc
      AND    itp.completed_ind       = 1
      AND    xoha.latest_external_flag = 'Y'
      AND    xoha.arrival_date > FND_DATE.STRING_TO_DATE(gd_prv1_dt_chr,gc_char_dt_format)
      AND    xoha.arrival_date < FND_DATE.STRING_TO_DATE(gd_flw_dt_chr,gc_char_dt_format)
      AND    xoha.req_status         IN ('04','08')
      AND    ilm.item_id             = itp.item_id
      AND    ilm.lot_id              = itp.lot_id
      AND    iimb.item_id            = itp.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    iimb2.item_no           = xola.request_item_code
      AND    ximb.start_date_active <= TRUNC(itp.trans_date)
      AND    ximb.end_date_active   >= TRUNC(itp.trans_date)
      AND    gic1.item_id            = itp.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = itp.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    gic3.item_id            = itp.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
      AND    gic4.item_id            = iimb2.item_id
      AND    gic4.category_set_id    = cn_item_class_id
      AND    gic4.category_id        = mcb4.category_id
      AND    rsl.shipment_header_id  = itp.doc_id
      AND    rsl.line_num            = itp.doc_line
      AND    rsl.oe_order_header_id  = xoha.header_id
      AND    rsl.oe_order_line_id    = xola.line_id
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    ((otta.attribute4           <> '2')
             OR  (otta.attribute4       IS NULL))
      AND    otta.attribute1         IN ('1','2')
      AND    xoha.header_id          = ooha.header_id
      AND    xola.order_header_id    = xoha.order_header_id
      AND    xrpm.doc_type           = itp.doc_type
      AND    xrpm.source_document_code = 'RMA'
      AND    xrpm.dealings_div       = '106'
      AND    xrpm.shipment_provision_div = DECODE(xoha.req_status,'04','1','08','2')
      AND    xrpm.shipment_provision_div = otta.attribute1
      AND    xrpm.ship_prov_rcv_pay_category = otta.attribute11
      AND    xrpm.item_div_ahead     = mcb4.segment1
      AND    mcb2.segment1           <> '5'
      AND    xrpm.break_col_01       IS NOT NULL
      AND    mcb3.segment1           = lt_crowd_code
      AND    iwm.whse_code           = itp.whse_code
-- 2009/03/05 v1.31 ADD START
      AND    iwm.attribute1          = '0'
-- 2009/03/05 v1.31 ADD END
      UNION ALL
      SELECT /*+ leading (xoha xola rsl itp gic1 mcb1 gic2 mcb2 ooha otta xrpm) use_nl (xoha xola rsl itp gic1 mcb1 gic2 mcb2 rsl ooha otta xrpm) */
             iwm.whse_code                        h_whse_code
            ,iwm.whse_name                        h_whse_name
            ,itp.trans_id                         trans_id
            ,iimb.attribute15                     cost_mng_clss
            ,iimb.lot_ctl                         lot_ctl
            ,xlc.unit_ploce                       actual_unit_price
            ,CASE WHEN INSTR(xrpm.break_col_01,gv_hifn) = 0
                       THEN ''
                  WHEN xrpm.rcv_pay_div = gc_rcv_pay_div_in
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  ELSE SUBSTR(xrpm.break_col_01,INSTR(xrpm.break_col_01,gv_hifn) +1)
             END                                  column_no
            ,itp.reason_code                      reason_code
            ,itp.trans_date                       trans_date
            ,TO_CHAR(itp.trans_date, 'YYYYMM')  trans_ym
            ,CASE WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN TO_CHAR(ABS(TO_NUMBER(xrpm.rcv_pay_div)))
                  ELSE xrpm.rcv_pay_div
             END                                  rcv_pay_div
            ,xrpm.dealings_div                    dealings_div
            ,itp.doc_type                         doc_type
            ,ir_param.item_class                  item_div
            ,ir_param.goods_class                 prod_div
            ,mcb3.segment1                        crowd_code
            ,SUBSTR(mcb3.segment1, 1, 3)          crowd_low
            ,SUBSTR(mcb3.segment1, 1, 2)          crowd_mid
            ,SUBSTR(mcb3.segment1, 1, 1)          crowd_high
            ,iimb.item_id                         item_id
            ,itp.lot_id                           lot_id
            ,NVL(itp.trans_qty, 0)                trans_qty
            ,xoha.arrival_date                    arrival_date
            ,TO_CHAR(xoha.arrival_date, gc_char_ym_format) arrival_ym
            ,iimb.item_no                         item_code
            ,ximb.item_short_name                 item_name
      FROM   ic_tran_pnd                      itp
            ,rcv_shipment_lines               rsl
            ,oe_order_headers_all             ooha
            ,oe_transaction_types_all         otta
            ,xxwsh_order_headers_all          xoha
            ,xxwsh_order_lines_all            xola
            ,ic_item_mst_b                    iimb
            ,ic_item_mst_b                    iimb2
            ,xxcmn_item_mst_b                 ximb
            ,ic_lots_mst                      ilm
            ,xxcmn_lot_cost                   xlc
            ,gmi_item_categories              gic1
            ,mtl_categories_b                 mcb1
            ,gmi_item_categories              gic2
            ,mtl_categories_b                 mcb2
            ,gmi_item_categories              gic3
            ,mtl_categories_b                 mcb3
            ,gmi_item_categories              gic4
            ,mtl_categories_b                 mcb4
            ,xxcmn_rcv_pay_mst                xrpm
            ,ic_whse_mst                      iwm
      WHERE  itp.doc_type            = gv_doc_type_porc
      AND    itp.completed_ind       = 1
      AND    xoha.latest_external_flag = 'Y'
      AND    xoha.arrival_date > FND_DATE.STRING_TO_DATE(gd_prv1_dt_chr,gc_char_dt_format)
      AND    xoha.arrival_date < FND_DATE.STRING_TO_DATE(gd_flw_dt_chr,gc_char_dt_format)
      AND    xoha.req_status         = '04'
      AND    ilm.item_id             = itp.item_id
      AND    ilm.lot_id              = itp.lot_id
      AND    iimb.item_id            = itp.item_id
      AND    iimb2.item_no           = xola.request_item_code
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(itp.trans_date)
      AND    ximb.end_date_active   >= TRUNC(itp.trans_date)
      AND    gic1.item_id            = itp.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = itp.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    gic3.item_id            = itp.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
      AND    gic4.item_id            = iimb2.item_id
      AND    gic4.category_set_id    = cn_item_class_id
      AND    gic4.category_id        = mcb4.category_id
      AND    rsl.shipment_header_id  = itp.doc_id
      AND    rsl.line_num            = itp.doc_line
      AND    rsl.oe_order_header_id  = xoha.header_id
      AND    rsl.oe_order_line_id    = xola.line_id
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    ((otta.attribute4           <> '2')
             OR  (otta.attribute4       IS NULL))
      AND    xoha.header_id          = ooha.header_id
      AND    xola.order_header_id    = xoha.order_header_id
      AND    xrpm.doc_type           = itp.doc_type
      AND    xrpm.source_document_code = 'RMA'
      AND    xrpm.dealings_div       = '113'
      AND    xrpm.shipment_provision_div = DECODE(xoha.req_status,'04','1','08','2')
      AND    xrpm.item_div_ahead     = mcb4.segment1
      AND    mcb2.segment1           <> '5'
      AND    xrpm.break_col_01       IS NOT NULL
      AND    mcb3.segment1           = lt_crowd_code
      AND    iwm.whse_code           = itp.whse_code
-- 2009/03/05 v1.31 ADD START
      AND    iwm.attribute1          = '0'
-- 2009/03/05 v1.31 ADD END
      UNION ALL
      SELECT /*+ leading (xoha ooha otta xola rsl itp gic1 mcb1 gic2 mcb2) use_nl (xoha ooha otta xola rsl itp gic1 mcb1 gic2 mcb2) */
             iwm.whse_code                        h_whse_code
            ,iwm.whse_name                        h_whse_name
            ,itp.trans_id                         trans_id
            ,iimb.attribute15                     cost_mng_clss
            ,iimb.lot_ctl                         lot_ctl
            ,xlc.unit_ploce                       actual_unit_price
            ,CASE WHEN INSTR(xrpm.break_col_01,gv_hifn) = 0
                       THEN ''
                  WHEN xrpm.rcv_pay_div = gc_rcv_pay_div_in
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  ELSE SUBSTR(xrpm.break_col_01,INSTR(xrpm.break_col_01,gv_hifn) +1)
             END                                  column_no
            ,itp.reason_code                      reason_code
            ,itp.trans_date                       trans_date
            ,TO_CHAR(itp.trans_date, 'YYYYMM')  trans_ym
            ,CASE WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN TO_CHAR(ABS(TO_NUMBER(xrpm.rcv_pay_div)))
                  ELSE xrpm.rcv_pay_div
             END                                  rcv_pay_div
            ,xrpm.dealings_div                    dealings_div
            ,itp.doc_type                         doc_type
            ,ir_param.item_class                  item_div
            ,ir_param.goods_class                 prod_div
            ,mcb3.segment1                        crowd_code
            ,SUBSTR(mcb3.segment1, 1, 3)          crowd_low
            ,SUBSTR(mcb3.segment1, 1, 2)          crowd_mid
            ,SUBSTR(mcb3.segment1, 1, 1)          crowd_high
            ,itp.item_id                          item_id
            ,itp.lot_id                           lot_id
            ,NVL(itp.trans_qty, 0)                trans_qty
            ,xoha.arrival_date                    arrival_date
            ,TO_CHAR(xoha.arrival_date, gc_char_ym_format) arrival_ym
            ,iimb.item_no                         item_code
            ,ximb.item_short_name                 item_name
      FROM   ic_tran_pnd                      itp
            ,rcv_shipment_lines               rsl
            ,oe_order_headers_all             ooha
            ,oe_transaction_types_all         otta
            ,xxwsh_order_headers_all          xoha
            ,xxwsh_order_lines_all            xola
            ,ic_item_mst_b                    iimb
            ,xxcmn_item_mst_b                 ximb
            ,ic_lots_mst                      ilm
            ,xxcmn_lot_cost                   xlc
            ,gmi_item_categories              gic1
            ,mtl_categories_b                 mcb1
            ,gmi_item_categories              gic2
            ,mtl_categories_b                 mcb2
            ,gmi_item_categories              gic3
            ,mtl_categories_b                 mcb3
            ,xxcmn_rcv_pay_mst                xrpm
            ,ic_whse_mst                      iwm
      WHERE  itp.doc_type            = gv_doc_type_porc
      AND    itp.completed_ind       = 1
      AND    xoha.latest_external_flag = 'Y'
      AND    xoha.arrival_date > FND_DATE.STRING_TO_DATE(gd_prv1_dt_chr,gc_char_dt_format)
      AND    xoha.arrival_date < FND_DATE.STRING_TO_DATE(gd_flw_dt_chr,gc_char_dt_format)
      AND    ilm.item_id             = itp.item_id
      AND    ilm.lot_id              = itp.lot_id
      AND    iimb.item_id            = itp.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(itp.trans_date)
      AND    ximb.end_date_active   >= TRUNC(itp.trans_date)
      AND    gic1.item_id            = itp.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = itp.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    gic3.item_id            = itp.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
      AND    rsl.shipment_header_id  = itp.doc_id
      AND    rsl.line_num            = itp.doc_line
      AND    rsl.oe_order_header_id  = xoha.header_id
      AND    rsl.oe_order_line_id    = xola.line_id
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    otta.attribute4         = '2'
      AND    xoha.header_id          = ooha.header_id
      AND    xola.order_header_id    = xoha.order_header_id
      AND    xrpm.doc_type           = itp.doc_type
      AND    xrpm.source_document_code = 'RMA'
      AND    xrpm.dealings_div       IN ('504','509')
      AND    xrpm.stock_adjustment_div = otta.attribute4
      AND    xrpm.ship_prov_rcv_pay_category = otta.attribute11
      AND    xrpm.break_col_01       IS NOT NULL
      AND    mcb3.segment1           = lt_crowd_code
      AND    iwm.whse_code           = itp.whse_code
-- 2009/03/05 v1.31 ADD START
      AND    iwm.attribute1          = '0'
-- 2009/03/05 v1.31 ADD END
      UNION ALL
      SELECT /*+ leading (itp gic1 mcb1 gic2 mcb2) use_nl (itp gic1 mcb1 gic2 mcb2) */
             iwm.whse_code                        h_whse_code
            ,iwm.whse_name                        h_whse_name
-- v1.33 Mod Start
--            ,itp.trans_id                         trans_id
            ,NULL                                 trans_id
-- v1.33 Mod End
            ,iimb.attribute15                     cost_mng_clss
            ,iimb.lot_ctl                         lot_ctl
            ,xlc.unit_ploce                       actual_unit_price
            ,CASE WHEN INSTR(xrpm.break_col_01,gv_hifn) = 0
                       THEN ''
                  WHEN xrpm.rcv_pay_div = gc_rcv_pay_div_in
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  ELSE SUBSTR(xrpm.break_col_01,INSTR(xrpm.break_col_01,gv_hifn) +1)
             END                                  column_no
            ,itp.reason_code                      reason_code
            ,itp.trans_date                       trans_date
            ,TO_CHAR(itp.trans_date, 'YYYYMM')  trans_ym
            ,CASE WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN TO_CHAR(ABS(TO_NUMBER(xrpm.rcv_pay_div)))
                  ELSE xrpm.rcv_pay_div
             END                                  rcv_pay_div
            ,xrpm.dealings_div                    dealings_div
            ,itp.doc_type                         doc_type
            ,ir_param.item_class                  item_div
            ,ir_param.goods_class                 prod_div
            ,mcb3.segment1                        crowd_code
            ,SUBSTR(mcb3.segment1, 1, 3)          crowd_low
            ,SUBSTR(mcb3.segment1, 1, 2)          crowd_mid
            ,SUBSTR(mcb3.segment1, 1, 1)          crowd_high
            ,itp.item_id                          item_id
            ,itp.lot_id                           lot_id
-- v1.33 Mod Start
--            ,NVL(itp.trans_qty, 0)                trans_qty
            ,SUM(NVL(itp.trans_qty, 0))           trans_qty
-- v1.33 Mod End
            ,itp.trans_date                       arrival_date
            ,TO_CHAR(itp.trans_date, gc_char_ym_format) arrival_ym
            ,iimb.item_no                         item_code
            ,ximb.item_short_name                 item_name
      FROM   ic_tran_pnd                      itp
            ,ic_item_mst_b                    iimb
            ,xxcmn_item_mst_b                 ximb
            ,ic_lots_mst                      ilm
            ,xxcmn_lot_cost                   xlc
            ,gmi_item_categories              gic1
            ,mtl_categories_b                 mcb1
            ,gmi_item_categories              gic2
            ,mtl_categories_b                 mcb2
            ,gmi_item_categories              gic3
            ,mtl_categories_b                 mcb3
            ,rcv_shipment_lines               rsl
            ,rcv_transactions                 rt
            ,xxcmn_rcv_pay_mst                xrpm
            ,ic_whse_mst                      iwm
      WHERE  itp.doc_type            = gv_doc_type_porc
      AND    itp.completed_ind       = 1
      AND    itp.trans_date > FND_DATE.STRING_TO_DATE(gd_prv1_dt_chr,gc_char_dt_format)
      AND    itp.trans_date < FND_DATE.STRING_TO_DATE(gd_flw_dt_chr,gc_char_dt_format)
      AND    ilm.item_id             = itp.item_id
      AND    ilm.lot_id              = itp.lot_id
      AND    iimb.item_id            = ilm.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(itp.trans_date)
      AND    ximb.end_date_active   >= TRUNC(itp.trans_date)
      AND    gic1.item_id            = itp.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = itp.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    gic3.item_id            = itp.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
      AND    rsl.shipment_header_id  = itp.doc_id
      AND    rsl.line_num            = itp.doc_line
      AND    rt.transaction_id       = itp.line_id
      AND    rt.shipment_line_id     = rsl.shipment_line_id
      AND    xrpm.doc_type           = itp.doc_type
      AND    xrpm.source_document_code = rsl.source_document_code
      AND    xrpm.transaction_type   = rt.transaction_type
      AND    xrpm.break_col_01       IS NOT NULL
      AND    mcb3.segment1           = lt_crowd_code
      AND    iwm.whse_code           = itp.whse_code
-- 2009/03/05 v1.31 ADD START
      AND    iwm.attribute1          = '0'
-- 2009/03/05 v1.31 ADD END
-- v1.33 Add Start
      GROUP BY
             iwm.whse_code                        -- h_whse_code
            ,iwm.whse_name                        -- h_whse_name
            ,iimb.attribute15                     -- cost_mng_clss
            ,iimb.lot_ctl                         -- lot_ctl
            ,xlc.unit_ploce                       -- actual_unit_price
            ,CASE WHEN INSTR(xrpm.break_col_01,gv_hifn) = 0
                       THEN ''
                  WHEN xrpm.rcv_pay_div = gc_rcv_pay_div_in
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  ELSE SUBSTR(xrpm.break_col_01,INSTR(xrpm.break_col_01,gv_hifn) +1)
             END                                  -- column_no
            ,itp.reason_code                      -- reason_code
            ,itp.trans_date                       -- trans_date
            ,TO_CHAR(itp.trans_date, 'YYYYMM')    -- trans_ym
            ,CASE WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN TO_CHAR(ABS(TO_NUMBER(xrpm.rcv_pay_div)))
                  ELSE xrpm.rcv_pay_div
             END                                  -- rcv_pay_div
            ,xrpm.dealings_div                    -- dealings_div
            ,itp.doc_type                         -- doc_type
            ,ir_param.item_class                  -- item_div
            ,ir_param.goods_class                 -- prod_div
            ,mcb3.segment1                        -- crowd_code
            ,SUBSTR(mcb3.segment1, 1, 3)          -- crowd_low
            ,SUBSTR(mcb3.segment1, 1, 2)          -- crowd_mid
            ,SUBSTR(mcb3.segment1, 1, 1)          -- crowd_high
            ,itp.item_id                          -- item_id
            ,itp.lot_id                           -- lot_id
            ,itp.trans_date                       -- arrival_date
            ,TO_CHAR(itp.trans_date, gc_char_ym_format) -- arrival_ym
            ,iimb.item_no                         -- item_code
            ,ximb.item_short_name                 -- item_name
            ,rsl.attribute1                       -- 受入返品実績アドオン.取引ID
-- v1.33 Add End
      UNION ALL
      SELECT /*+ leading (xoha xola wdd itp gic1 mcb1 gic2 mcb2 ooha otta) use_nl (xoha xola wdd itp gic1 mcb1 gic2 mcb2 ooha otta) */
             iwm.whse_code                        h_whse_code
            ,iwm.whse_name                        h_whse_name
            ,itp.trans_id                         trans_id
            ,iimb.attribute15                     cost_mng_clss
            ,iimb.lot_ctl                         lot_ctl
            ,xlc.unit_ploce                       actual_unit_price
            ,CASE WHEN INSTR(xrpm.break_col_01,gv_hifn) = 0
                       THEN ''
                  WHEN xrpm.rcv_pay_div = gc_rcv_pay_div_in
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  ELSE SUBSTR(xrpm.break_col_01,INSTR(xrpm.break_col_01,gv_hifn) +1)
             END                                  column_no
            ,itp.reason_code                      reason_code
            ,itp.trans_date                       trans_date
            ,TO_CHAR(itp.trans_date, 'YYYYMM')  trans_ym
            ,CASE WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN TO_CHAR(ABS(TO_NUMBER(xrpm.rcv_pay_div)))
                  ELSE xrpm.rcv_pay_div
             END                                  rcv_pay_div
            ,xrpm.dealings_div                    dealings_div
            ,itp.doc_type                         doc_type
            ,ir_param.item_class                  item_div
            ,ir_param.goods_class                 prod_div
            ,mcb3.segment1                        crowd_code
            ,SUBSTR(mcb3.segment1, 1, 3)          crowd_low
            ,SUBSTR(mcb3.segment1, 1, 2)          crowd_mid
            ,SUBSTR(mcb3.segment1, 1, 1)          crowd_high
            ,itp.item_id                          item_id
            ,itp.lot_id                           lot_id
            ,NVL(itp.trans_qty, 0)                trans_qty
            ,xoha.arrival_date                    arrival_date
            ,TO_CHAR(xoha.arrival_date, gc_char_ym_format) arrival_ym
            ,iimb.item_no                         item_code
            ,ximb.item_short_name                 item_name
      FROM   ic_tran_pnd                      itp
            ,wsh_delivery_details             wdd
            ,oe_order_headers_all             ooha
            ,oe_transaction_types_all         otta
            ,xxwsh_order_headers_all          xoha
            ,xxwsh_order_lines_all            xola
            ,ic_item_mst_b                    iimb
            ,xxcmn_item_mst_b                 ximb
            ,ic_lots_mst                      ilm
            ,xxcmn_lot_cost                   xlc
            ,gmi_item_categories              gic1
            ,mtl_categories_b                 mcb1
            ,gmi_item_categories              gic2
            ,mtl_categories_b                 mcb2
            ,gmi_item_categories              gic3
            ,mtl_categories_b                 mcb3
            ,xxcmn_rcv_pay_mst                xrpm
            ,ic_whse_mst                      iwm
      WHERE  itp.doc_type            = gv_doc_type_omso
      AND    itp.completed_ind       = 1
      AND    xoha.latest_external_flag = 'Y'
      AND    xoha.arrival_date > FND_DATE.STRING_TO_DATE(gd_prv2_dt_chr,gc_char_dt_format)
      AND    xoha.arrival_date < FND_DATE.STRING_TO_DATE(gd_flw_dt_chr,gc_char_dt_format)
      AND    xoha.req_status         IN ('04','08')
      AND    ilm.item_id             = itp.item_id
      AND    ilm.lot_id              = itp.lot_id
      AND    iimb.item_id            = ilm.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(itp.trans_date)
      AND    ximb.end_date_active   >= TRUNC(itp.trans_date)
      AND    gic1.item_id            = itp.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = itp.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    gic3.item_id            = itp.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
      AND    wdd.delivery_detail_id  = itp.line_detail_id
      AND    wdd.source_header_id    = xoha.header_id
      AND    wdd.source_line_id      = xola.line_id
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    ((otta.attribute4           <> '2')
             OR  (otta.attribute4       IS NULL))
      AND    otta.attribute1         IN ('1','2')
      AND    xoha.header_id          = ooha.header_id
      AND    xola.order_header_id    = xoha.order_header_id
      AND    xola.request_item_code  = xola.shipping_item_code
      AND    xrpm.doc_type           = itp.doc_type
      AND    xrpm.dealings_div       IN ('101','103')
      AND    xrpm.shipment_provision_div = DECODE(xoha.req_status,'04','1','08','2')
      AND    xrpm.shipment_provision_div = otta.attribute1
      AND    ((xrpm.ship_prov_rcv_pay_category IS NULL)
             OR (xrpm.ship_prov_rcv_pay_category = otta.attribute11))
      AND    xrpm.break_col_01       IS NOT NULL
      AND    xrpm.item_div_origin    IS NULL
      AND    xrpm.item_div_ahead     IS NULL
      AND    mcb3.segment1           = lt_crowd_code
      AND    iwm.whse_code           = itp.whse_code
-- 2009/03/05 v1.31 ADD START
      AND    iwm.attribute1          = '0'
-- 2009/03/05 v1.31 ADD END
      UNION ALL
      SELECT /*+ leading (xoha xola wdd itp gic1 mcb1 gic2 mcb2 ooha otta xrpm) use_nl (xoha xola wdd itp gic1 mcb1 gic2 mcb2 ooha otta xrpm) */
             iwm.whse_code                        h_whse_code
            ,iwm.whse_name                        h_whse_name
            ,itp.trans_id                         trans_id
            ,iimb.attribute15                     cost_mng_clss
            ,iimb.lot_ctl                         lot_ctl
            ,xlc.unit_ploce                       actual_unit_price
            ,CASE WHEN INSTR(xrpm.break_col_01,gv_hifn) = 0
                       THEN ''
                  WHEN xrpm.rcv_pay_div = gc_rcv_pay_div_in
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  ELSE SUBSTR(xrpm.break_col_01,INSTR(xrpm.break_col_01,gv_hifn) +1)
             END                                  column_no
            ,itp.reason_code                      reason_code
            ,itp.trans_date                       trans_date
            ,TO_CHAR(itp.trans_date, 'YYYYMM')  trans_ym
            ,CASE WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN TO_CHAR(ABS(TO_NUMBER(xrpm.rcv_pay_div)))
                  ELSE xrpm.rcv_pay_div
             END                                  rcv_pay_div
            ,xrpm.dealings_div                    dealings_div
            ,itp.doc_type                         doc_type
            ,ir_param.item_class                  item_div
            ,ir_param.goods_class                 prod_div
            ,mcb3.segment1                        crowd_code
            ,SUBSTR(mcb3.segment1, 1, 3)          crowd_low
            ,SUBSTR(mcb3.segment1, 1, 2)          crowd_mid
            ,SUBSTR(mcb3.segment1, 1, 1)          crowd_high
            ,iimb.item_id                         item_id
            ,itp.lot_id                           lot_id
            ,NVL(itp.trans_qty, 0)                trans_qty
            ,xoha.arrival_date                    arrival_date
            ,TO_CHAR(xoha.arrival_date, gc_char_ym_format) arrival_ym
            ,iimb.item_no                         item_code
            ,ximb.item_short_name                 item_name
      FROM   ic_tran_pnd                      itp
            ,wsh_delivery_details             wdd
            ,oe_order_headers_all             ooha
            ,oe_transaction_types_all         otta
            ,xxwsh_order_headers_all          xoha
            ,xxwsh_order_lines_all            xola
            ,ic_item_mst_b                    iimb
            ,ic_item_mst_b                    iimb2
            ,xxcmn_item_mst_b                 ximb
            ,ic_lots_mst                      ilm
            ,xxcmn_lot_cost                   xlc
            ,gmi_item_categories              gic1
            ,mtl_categories_b                 mcb1
            ,gmi_item_categories              gic2
            ,mtl_categories_b                 mcb2
            ,gmi_item_categories              gic3
            ,mtl_categories_b                 mcb3
            ,gmi_item_categories              gic4
            ,mtl_categories_b                 mcb4
            ,xxcmn_rcv_pay_mst                xrpm
            ,ic_whse_mst                      iwm
      WHERE  itp.doc_type            = gv_doc_type_omso
      AND    itp.completed_ind       = 1
      AND    xoha.latest_external_flag = 'Y'
      AND    xoha.arrival_date > FND_DATE.STRING_TO_DATE(gd_prv2_dt_chr,gc_char_dt_format)
      AND    xoha.arrival_date < FND_DATE.STRING_TO_DATE(gd_flw_dt_chr,gc_char_dt_format)
      AND    xoha.req_status         = '08'
      AND    ilm.item_id             = itp.item_id
      AND    ilm.lot_id              = itp.lot_id
      AND    iimb.item_id            = itp.item_id
      AND    iimb2.item_no           = xola.request_item_code
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(itp.trans_date)
      AND    ximb.end_date_active   >= TRUNC(itp.trans_date)
      AND    gic1.item_id            = itp.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = itp.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    gic3.item_id            = itp.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
      AND    gic4.item_id            = iimb2.item_id
      AND    gic4.category_set_id    = cn_item_class_id
      AND    gic4.category_id        = mcb4.category_id
      AND    wdd.delivery_detail_id  = itp.line_detail_id
      AND    wdd.source_header_id    = xoha.header_id
      AND    wdd.source_line_id      = xola.line_id
      AND    xola.order_header_id    = xoha.order_header_id
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    ((otta.attribute4           <> '2')
             OR  (otta.attribute4       IS NULL))
      AND    otta.attribute1         = '2'
      AND    xoha.header_id          = ooha.header_id
      AND    xrpm.doc_type           = itp.doc_type
      AND    xrpm.dealings_div       = '106'
      AND    xrpm.shipment_provision_div = DECODE(xoha.req_status,'04','1','08','2')
      AND    xrpm.shipment_provision_div = otta.attribute1
      AND    xrpm.ship_prov_rcv_pay_category = otta.attribute11
      AND    xrpm.item_div_ahead     = mcb4.segment1
      AND    mcb2.segment1           <> '5'
      AND    xrpm.break_col_01       IS NOT NULL
      AND    mcb3.segment1           = lt_crowd_code
      AND    iwm.whse_code           = itp.whse_code
-- 2009/03/05 v1.31 ADD START
      AND    iwm.attribute1          = '0'
-- 2009/03/05 v1.31 ADD END
      UNION ALL
      SELECT /*+ leading (xoha xola wdd itp gic1 mcb1 gic2 mcb2 ooha otta xrpm) use_nl (xoha xola wdd itp gic1 mcb1 gic2 mcb2 ooha otta xrpm) */
             iwm.whse_code                        h_whse_code
            ,iwm.whse_name                        h_whse_name
            ,itp.trans_id                         trans_id
            ,iimb.attribute15                     cost_mng_clss
            ,iimb.lot_ctl                         lot_ctl
            ,xlc.unit_ploce                       actual_unit_price
            ,CASE WHEN INSTR(xrpm.break_col_01,gv_hifn) = 0
                       THEN ''
                  WHEN xrpm.rcv_pay_div = gc_rcv_pay_div_in
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  ELSE SUBSTR(xrpm.break_col_01,INSTR(xrpm.break_col_01,gv_hifn) +1)
             END                                  column_no
            ,itp.reason_code                      reason_code
            ,itp.trans_date                       trans_date
            ,TO_CHAR(itp.trans_date, 'YYYYMM')  trans_ym
            ,CASE WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN TO_CHAR(ABS(TO_NUMBER(xrpm.rcv_pay_div)))
                  ELSE xrpm.rcv_pay_div
             END                                  rcv_pay_div
            ,xrpm.dealings_div                    dealings_div
            ,itp.doc_type                         doc_type
            ,ir_param.item_class                  item_div
            ,ir_param.goods_class                 prod_div
            ,mcb3.segment1                        crowd_code
            ,SUBSTR(mcb3.segment1, 1, 3)          crowd_low
            ,SUBSTR(mcb3.segment1, 1, 2)          crowd_mid
            ,SUBSTR(mcb3.segment1, 1, 1)          crowd_high
            ,iimb.item_id                         item_id
            ,itp.lot_id                           lot_id
            ,NVL(itp.trans_qty, 0)                trans_qty
            ,xoha.arrival_date                    arrival_date
            ,TO_CHAR(xoha.arrival_date, gc_char_ym_format) arrival_ym
            ,iimb.item_no                         item_code
            ,ximb.item_short_name                 item_name
      FROM   ic_tran_pnd                      itp
            ,wsh_delivery_details             wdd
            ,oe_order_headers_all             ooha
            ,oe_transaction_types_all         otta
            ,xxwsh_order_headers_all          xoha
            ,xxwsh_order_lines_all            xola
            ,ic_item_mst_b                    iimb
            ,ic_item_mst_b                    iimb2
            ,xxcmn_item_mst_b                 ximb
            ,ic_lots_mst                      ilm
            ,xxcmn_lot_cost                   xlc
            ,gmi_item_categories              gic1
            ,mtl_categories_b                 mcb1
            ,gmi_item_categories              gic2
            ,mtl_categories_b                 mcb2
            ,gmi_item_categories              gic3
            ,mtl_categories_b                 mcb3
            ,gmi_item_categories              gic4
            ,mtl_categories_b                 mcb4
            ,xxcmn_rcv_pay_mst                xrpm
            ,ic_whse_mst                      iwm
      WHERE  itp.doc_type            = gv_doc_type_omso
      AND    itp.completed_ind       = 1
      AND    xoha.latest_external_flag = 'Y'
      AND    xoha.arrival_date > FND_DATE.STRING_TO_DATE(gd_prv2_dt_chr,gc_char_dt_format)
      AND    xoha.arrival_date < FND_DATE.STRING_TO_DATE(gd_flw_dt_chr,gc_char_dt_format)
      AND    xoha.req_status         = '04'
      AND    ilm.item_id             = itp.item_id
      AND    ilm.lot_id              = itp.lot_id
      AND    iimb.item_id            = itp.item_id
      AND    iimb2.item_no           = xola.request_item_code
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(itp.trans_date)
      AND    ximb.end_date_active   >= TRUNC(itp.trans_date)
      AND    gic1.item_id            = itp.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = itp.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    gic3.item_id            = itp.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
      AND    gic4.item_id            = iimb2.item_id
      AND    gic4.category_set_id    = cn_item_class_id
      AND    gic4.category_id        = mcb4.category_id
      AND    wdd.delivery_detail_id  = itp.line_detail_id
      AND    wdd.source_header_id    = xoha.header_id
      AND    wdd.source_line_id      = xola.line_id
      AND    xola.order_header_id    = xoha.order_header_id
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    ((otta.attribute4           <> '2')
             OR  (otta.attribute4       IS NULL))
      AND    otta.attribute1         = '1'
      AND    xoha.header_id          = ooha.header_id
      AND    xrpm.doc_type           = itp.doc_type
      AND    xrpm.dealings_div       = '113'
      AND    xrpm.shipment_provision_div = DECODE(xoha.req_status,'04','1','08','2')
      AND    xrpm.item_div_ahead     = mcb4.segment1
      AND    mcb2.segment1           <> '5'
      AND    xrpm.break_col_01       IS NOT NULL
      AND    mcb3.segment1           = lt_crowd_code
      AND    iwm.whse_code           = itp.whse_code
-- 2009/03/05 v1.31 ADD START
      AND    iwm.attribute1          = '0'
-- 2009/03/05 v1.31 ADD END
      UNION ALL
      SELECT /*+ leading (xoha ooha otta xola wdd itp gic1 mcb1 gic2 mcb2) use_nl (xoha ooha otta xola wdd itp gic1 mcb1 gic2 mcb2) */
             iwm.whse_code                        h_whse_code
            ,iwm.whse_name                        h_whse_name
            ,itp.trans_id                         trans_id
            ,iimb.attribute15                     cost_mng_clss
            ,iimb.lot_ctl                         lot_ctl
            ,xlc.unit_ploce                       actual_unit_price
            ,CASE WHEN INSTR(xrpm.break_col_01,gv_hifn) = 0
                       THEN ''
                  WHEN xrpm.rcv_pay_div = gc_rcv_pay_div_in
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  ELSE SUBSTR(xrpm.break_col_01,INSTR(xrpm.break_col_01,gv_hifn) +1)
             END                                  column_no
            ,itp.reason_code                      reason_code
            ,itp.trans_date                       trans_date
            ,TO_CHAR(itp.trans_date, 'YYYYMM')  trans_ym
            ,CASE WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN TO_CHAR(ABS(TO_NUMBER(xrpm.rcv_pay_div)))
                  ELSE xrpm.rcv_pay_div
             END                                  rcv_pay_div
            ,xrpm.dealings_div                    dealings_div
            ,itp.doc_type                         doc_type
            ,ir_param.item_class                  item_div
            ,ir_param.goods_class                 prod_div
            ,mcb3.segment1                        crowd_code
            ,SUBSTR(mcb3.segment1, 1, 3)          crowd_low
            ,SUBSTR(mcb3.segment1, 1, 2)          crowd_mid
            ,SUBSTR(mcb3.segment1, 1, 1)          crowd_high
            ,itp.item_id                          item_id
            ,itp.lot_id                           lot_id
            ,NVL(itp.trans_qty, 0)                trans_qty
            ,xoha.arrival_date                    arrival_date
            ,TO_CHAR(xoha.arrival_date, gc_char_ym_format) arrival_ym
            ,iimb.item_no                         item_code
            ,ximb.item_short_name                 item_name
      FROM   ic_tran_pnd                      itp
            ,wsh_delivery_details             wdd
            ,oe_order_headers_all             ooha
            ,oe_transaction_types_all         otta
            ,xxwsh_order_headers_all          xoha
            ,xxwsh_order_lines_all            xola
            ,ic_item_mst_b                    iimb
            ,xxcmn_item_mst_b                 ximb
            ,ic_lots_mst                      ilm
            ,xxcmn_lot_cost                   xlc
            ,gmi_item_categories              gic1
            ,mtl_categories_b                 mcb1
            ,gmi_item_categories              gic2
            ,mtl_categories_b                 mcb2
            ,gmi_item_categories              gic3
            ,mtl_categories_b                 mcb3
            ,xxcmn_rcv_pay_mst                xrpm
            ,ic_whse_mst                      iwm
      WHERE  itp.doc_type            = gv_doc_type_omso
      AND    itp.completed_ind       = 1
      AND    xoha.latest_external_flag = 'Y'
      AND    xoha.arrival_date > FND_DATE.STRING_TO_DATE(gd_prv2_dt_chr,gc_char_dt_format)
      AND    xoha.arrival_date < FND_DATE.STRING_TO_DATE(gd_flw_dt_chr,gc_char_dt_format)
      AND    ilm.item_id             = itp.item_id
      AND    ilm.lot_id              = itp.lot_id
      AND    iimb.item_id            = itp.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(itp.trans_date)
      AND    ximb.end_date_active   >= TRUNC(itp.trans_date)
      AND    gic1.item_id            = itp.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = itp.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    gic3.item_id            = itp.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
      AND    wdd.delivery_detail_id  = itp.line_detail_id
      AND    wdd.source_header_id    = xoha.header_id
      AND    wdd.source_line_id      = xola.line_id
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    otta.attribute4         = '2'
      AND    xoha.header_id          = ooha.header_id
      AND    xola.order_header_id    = xoha.order_header_id
      AND    xrpm.doc_type           = itp.doc_type
      AND    xrpm.dealings_div       IN ('504','509')
      AND    xrpm.stock_adjustment_div = otta.attribute4
      AND    xrpm.ship_prov_rcv_pay_category = otta.attribute11
      AND    xrpm.break_col_01       IS NOT NULL
      AND    mcb3.segment1           = lt_crowd_code
      AND    iwm.whse_code           = itp.whse_code
-- 2009/03/05 v1.31 ADD START
      AND    iwm.attribute1          = '0'
-- 2009/03/05 v1.31 ADD END
      -- 当月受払無しデータ
      UNION ALL
      SELECT /*+ leading (xsims gic1 mcb1 gic2 mcb2 gic3 mcb3 iimb ximb xlc) use_nl (xsims gic1 mcb1 gic2 mcb2 gic3 mcb3 iimb ximb xlc) */
             iwm.whse_code                        h_whse_code
            ,iwm.whse_name                        h_whse_name
            ,NULL                                 trans_id
            ,iimb.attribute15                     cost_mng_clss
            ,iimb.lot_ctl                         lot_ctl
            ,xlc.unit_ploce                       actual_unit_price
            ,'1'                                  column_no
            ,NULL                                 reason_code
            ,gd_s_date                            trans_date
            ,TO_CHAR(gd_s_date, gc_char_ym_format)  trans_ym
            ,'1'                                  rcv_pay_div
            ,NULL                                 dealings_div
            ,NULL                                 doc_type
            ,ir_param.item_class                  item_div
            ,ir_param.goods_class                 prod_div
            ,mcb3.segment1                        crowd_code
            ,SUBSTR(mcb3.segment1, 1, 3)          crowd_low
            ,SUBSTR(mcb3.segment1, 1, 2)          crowd_mid
            ,SUBSTR(mcb3.segment1, 1, 1)          crowd_high
            ,iimb.item_id                         item_id
            ,0                                    lot_id
            ,0                                    trans_qty
            ,gd_s_date                            arrival_date
            ,TO_CHAR(gd_s_date, gc_char_ym_format)  arrival_ym
            ,iimb.item_no                         item_code
            ,ximb.item_short_name                 item_name
      FROM   xxinv_stc_inventory_month_stck   xsims
            ,ic_item_mst_b                    iimb
            ,xxcmn_item_mst_b                 ximb
            ,ic_lots_mst                      ilm
            ,xxcmn_lot_cost                   xlc
            ,gmi_item_categories              gic1
            ,mtl_categories_b                 mcb1
            ,gmi_item_categories              gic2
            ,mtl_categories_b                 mcb2
            ,gmi_item_categories              gic3
            ,mtl_categories_b                 mcb3
            ,ic_whse_mst                      iwm
      WHERE  xsims.item_id           = iimb.item_id
      AND    ximb.item_id            = iimb.item_id
      AND    ilm.item_id             = xsims.item_id
      AND    ilm.lot_id              = xsims.lot_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.start_date_active <= gd_s_date
      AND    ximb.end_date_active   >= gd_s_date
      AND    gic1.item_id            = xsims.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = xsims.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    gic3.item_id            = xsims.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
      AND    mcb3.segment1           = lt_crowd_code
      AND    iwm.whse_code           = xsims.whse_code
      AND    xsims.invent_ym         = TO_CHAR(gd_s_date, gc_char_ym_format)
-- 2008/12/10 v1.25 UPDATE START
--      AND    xsims.monthly_stock    <> 0
      AND    (
               (xsims.monthly_stock <> 0)
               OR
               (xsims.cargo_stock   <> 0)
             )
      AND    iwm.attribute1          = '0'
-- 2008/12/10 v1.25 UPDATE END
      ORDER BY h_whse_code
              ,crowd_code
              ,item_code
      ;
--
    --===============================================================
    -- 検索条件.帳票種別          ⇒ 倉庫・品目別
    -- 検索条件.群種別            ⇒ 群別
    -- 検索条件.倉庫コード        ⇒ 入力なし
    -- 検索条件.群コード          ⇒ 入力なし
    -- 検索条件.経理群コード      ⇒ 入力なし/入力あり
    --===============================================================
    CURSOR get_data_cur02 IS
      SELECT /*+ leading (xmrh xmril ixm itp gic2 mcb2 gic1 mcb1 iimb ximb) use_nl (xmrh xmril ixm itp gic2 mcb2 gic1 mcb1 iimb ximb) */
             iwm.whse_code                        h_whse_code
            ,iwm.whse_name                        h_whse_name
            ,itp.trans_id                         trans_id
            ,iimb.attribute15                     cost_mng_clss
            ,iimb.lot_ctl                         lot_ctl
            ,xlc.unit_ploce                       actual_unit_price
            ,CASE WHEN INSTR(xrpm.break_col_01,gv_hifn) = 0
                       THEN ''
                  WHEN xrpm.rcv_pay_div = gc_rcv_pay_div_in
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  ELSE SUBSTR(xrpm.break_col_01,INSTR(xrpm.break_col_01,gv_hifn) +1)
             END                                  column_no
            ,itp.reason_code                      reason_code
            ,itp.trans_date                       trans_date
            ,TO_CHAR(itp.trans_date, 'YYYYMM')  trans_ym
            ,CASE WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN TO_CHAR(ABS(TO_NUMBER(xrpm.rcv_pay_div)))
                  ELSE xrpm.rcv_pay_div
             END                                  rcv_pay_div
            ,xrpm.dealings_div                    dealings_div
            ,itp.doc_type                         doc_type
            ,ir_param.item_class                  item_div
            ,ir_param.goods_class                 prod_div
            ,mcb3.segment1                        crowd_code
            ,SUBSTR(mcb3.segment1, 1, 3)          crowd_low
            ,SUBSTR(mcb3.segment1, 1, 2)          crowd_mid
            ,SUBSTR(mcb3.segment1, 1, 1)          crowd_high
            ,itp.item_id                          item_id
            ,itp.lot_id                           lot_id
            ,NVL(itp.trans_qty, 0)                trans_qty
            ,xmrh.actual_arrival_date             arrival_date
            ,TO_CHAR(xmrh.actual_arrival_date, gc_char_ym_format) arrival_ym
            ,iimb.item_no                         item_code
            ,ximb.item_short_name                 item_name
      FROM   ic_tran_pnd                      itp
            ,ic_xfer_mst                      ixm
            ,xxinv_mov_req_instr_headers      xmrh
            ,xxinv_mov_req_instr_lines        xmril
            ,ic_item_mst_b                    iimb
            ,xxcmn_item_mst_b                 ximb
            ,ic_lots_mst                      ilm
            ,xxcmn_lot_cost                   xlc
            ,gmi_item_categories              gic1
            ,mtl_categories_b                 mcb1
            ,gmi_item_categories              gic2
            ,mtl_categories_b                 mcb2
            ,gmi_item_categories              gic3
            ,mtl_categories_b                 mcb3
            ,xxcmn_rcv_pay_mst                xrpm
            ,ic_whse_mst                      iwm
      WHERE  itp.doc_type            = gv_doc_type_xfer
      AND    itp.reason_code         = gv_reason_code_xfer
      AND    itp.completed_ind       = 1
      AND    xmrh.actual_arrival_date > FND_DATE.STRING_TO_DATE(gd_prv1_dt_chr,gc_char_dt_format)
      AND    xmrh.actual_arrival_date < FND_DATE.STRING_TO_DATE(gd_flw_dt_chr,gc_char_dt_format)
      AND    xmrh.mov_hdr_id         = xmril.mov_hdr_id
      AND    itp.doc_id              = ixm.transfer_id
      AND    ixm.attribute1          = TO_CHAR(xmril.mov_line_id)
      AND    ilm.item_id             = itp.item_id
      AND    ilm.lot_id              = itp.lot_id
      AND    iimb.item_id            = itp.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(itp.trans_date)
      AND    ximb.end_date_active   >= TRUNC(itp.trans_date)
      AND    gic1.item_id            = itp.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = itp.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    gic3.item_id            = itp.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
      AND    xrpm.rcv_pay_div        = CASE
                                       WHEN itp.trans_qty >= 0 THEN 1
                                       ELSE -1
                                       END
      AND    xrpm.doc_type           = itp.doc_type
      AND    xrpm.reason_code        = itp.reason_code
      AND    xrpm.break_col_01       IS NOT NULL
      AND   iwm.whse_code            = itp.whse_code
-- 2009/03/05 v1.31 ADD START
      AND    iwm.attribute1          = '0'
-- 2009/03/05 v1.31 ADD END
      UNION ALL
      SELECT /*+ leading (xmrh xmril ijm iaj itc gic2 mcb2 gic1 mcb1 ilm iimb ximb) use_nl (xmrh xmril ijm iaj itc gic2 mcb2 gic1 mcb1 ilm iimb ximb) */
             iwm.whse_code                        h_whse_code
            ,iwm.whse_name                        h_whse_name
            ,itc.trans_id                         trans_id
            ,iimb.attribute15                     cost_mng_clss
            ,iimb.lot_ctl                         lot_ctl
            ,xlc.unit_ploce                       actual_unit_price
            ,CASE WHEN INSTR(xrpm.break_col_01,gv_hifn) = 0
                       THEN ''
                  WHEN xrpm.rcv_pay_div = gc_rcv_pay_div_in
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  ELSE SUBSTR(xrpm.break_col_01,INSTR(xrpm.break_col_01,gv_hifn) +1)
             END                                  column_no
            ,itc.reason_code                      reason_code
            ,itc.trans_date                       trans_date
            ,TO_CHAR(itc.trans_date, 'YYYYMM')  trans_ym
            ,CASE WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN TO_CHAR(ABS(TO_NUMBER(xrpm.rcv_pay_div)))
                  ELSE xrpm.rcv_pay_div
             END                                  rcv_pay_div
            ,xrpm.dealings_div                    dealings_div
            ,itc.doc_type                         doc_type
            ,ir_param.item_class                  item_div
            ,ir_param.goods_class                 prod_div
            ,mcb3.segment1                        crowd_code
            ,SUBSTR(mcb3.segment1, 1, 3)          crowd_low
            ,SUBSTR(mcb3.segment1, 1, 2)          crowd_mid
            ,SUBSTR(mcb3.segment1, 1, 1)          crowd_high
            ,itc.item_id                          item_id
            ,itc.lot_id                           lot_id
            ,NVL(itc.trans_qty, 0)                trans_qty
            ,xmrh.actual_arrival_date             arrival_date
            ,TO_CHAR(xmrh.actual_arrival_date, gc_char_ym_format) arrival_ym
            ,iimb.item_no                         item_code
            ,ximb.item_short_name                 item_name
      FROM   ic_tran_cmp                      itc
            ,ic_adjs_jnl                      iaj
            ,ic_jrnl_mst                      ijm
            ,xxinv_mov_req_instr_headers      xmrh
            ,xxinv_mov_req_instr_lines        xmril
            ,ic_item_mst_b                    iimb
            ,xxcmn_item_mst_b                 ximb
            ,ic_lots_mst                      ilm
            ,xxcmn_lot_cost                   xlc
            ,gmi_item_categories              gic1
            ,mtl_categories_b                 mcb1
            ,gmi_item_categories              gic2
            ,mtl_categories_b                 mcb2
            ,gmi_item_categories              gic3
            ,mtl_categories_b                 mcb3
            ,xxcmn_rcv_pay_mst                xrpm
            ,ic_whse_mst                      iwm
      WHERE  itc.doc_type            = gv_doc_type_trni
      AND    itc.reason_code         = gv_reason_code_trni
      AND    xmrh.actual_arrival_date > FND_DATE.STRING_TO_DATE(gd_prv1_dt_chr,gc_char_dt_format)
      AND    xmrh.actual_arrival_date < FND_DATE.STRING_TO_DATE(gd_flw_dt_chr,gc_char_dt_format)
      AND    xmrh.mov_hdr_id         = xmril.mov_hdr_id
      AND    itc.doc_type            = iaj.trans_type
      AND    itc.doc_id              = iaj.doc_id
      AND    itc.doc_line            = iaj.doc_line
      AND    ijm.journal_id          = iaj.journal_id
      AND    ijm.attribute1          = TO_CHAR(xmril.mov_line_id)
      AND    ilm.item_id             = itc.item_id
      AND    ilm.lot_id              = itc.lot_id
      AND    iimb.item_id            = ilm.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(itc.trans_date)
      AND    ximb.end_date_active   >= TRUNC(itc.trans_date)
      AND    gic1.item_id            = itc.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = itc.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    gic3.item_id            = itc.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
-- 2008/11/19 v1.18 ADD START
      AND    xrpm.rcv_pay_div        = CASE
                                       WHEN itc.trans_qty >= 0 THEN 1
                                       ELSE -1
                                       END
-- 2008/11/19 v1.18 ADD END
      AND    xrpm.doc_type           = itc.doc_type
      AND    xrpm.reason_code        = itc.reason_code
      AND    xrpm.rcv_pay_div        = itc.line_type
      AND    xrpm.break_col_01       IS NOT NULL
      AND   iwm.whse_code            = itc.whse_code
-- 2009/03/05 v1.31 ADD START
      AND    iwm.attribute1          = '0'
-- 2009/03/05 v1.31 ADD END
      UNION ALL
      SELECT /*+ leading (itc gic1 mcb1 gic2 mcb2) use_nl (itc gic1 mcb1 gic2 mcb2)*/
             iwm.whse_code                        h_whse_code
            ,iwm.whse_name                        h_whse_name
            ,itc.trans_id                         trans_id
            ,iimb.attribute15                     cost_mng_clss
            ,iimb.lot_ctl                         lot_ctl
            ,xlc.unit_ploce                       actual_unit_price
            ,CASE WHEN INSTR(xrpm.break_col_01,gv_hifn) = 0
                       THEN ''
                  WHEN xrpm.rcv_pay_div = gc_rcv_pay_div_in
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  ELSE SUBSTR(xrpm.break_col_01,INSTR(xrpm.break_col_01,gv_hifn) +1)
             END                                  column_no
            ,itc.reason_code                      reason_code
            ,itc.trans_date                       trans_date
            ,TO_CHAR(itc.trans_date, 'YYYYMM')  trans_ym
            ,CASE WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN TO_CHAR(ABS(TO_NUMBER(xrpm.rcv_pay_div)))
                  ELSE xrpm.rcv_pay_div
             END                                  rcv_pay_div
            ,xrpm.dealings_div                    dealings_div
            ,itc.doc_type                         doc_type
            ,ir_param.item_class                  item_div
            ,ir_param.goods_class                 prod_div
            ,mcb3.segment1                        crowd_code
            ,SUBSTR(mcb3.segment1, 1, 3)          crowd_low
            ,SUBSTR(mcb3.segment1, 1, 2)          crowd_mid
            ,SUBSTR(mcb3.segment1, 1, 1)          crowd_high
            ,itc.item_id                          item_id
            ,itc.lot_id                           lot_id
            ,NVL(itc.trans_qty, 0)                trans_qty
            ,itc.trans_date                       arrival_date
            ,TO_CHAR(itc.trans_date, gc_char_ym_format) arrival_ym
            ,iimb.item_no                         item_code
            ,ximb.item_short_name                 item_name
      FROM   ic_tran_cmp                      itc
            ,ic_item_mst_b                    iimb
            ,xxcmn_item_mst_b                 ximb
            ,ic_lots_mst                      ilm
            ,xxcmn_lot_cost                   xlc
            ,gmi_item_categories              gic1
            ,mtl_categories_b                 mcb1
            ,gmi_item_categories              gic2
            ,mtl_categories_b                 mcb2
            ,gmi_item_categories              gic3
            ,mtl_categories_b                 mcb3
            ,xxcmn_rcv_pay_mst                xrpm
            ,ic_whse_mst                      iwm
      WHERE  itc.doc_type            = gv_doc_type_adji    --文書タイプ
      AND    itc.reason_code        IN ('X911'
                                       ,'X912'
                                       ,'X921'
                                       ,'X922'
                                       ,'X931'
                                       ,'X932'
                                       ,'X941'
                                       ,'X952'
                                       ,'X953'
                                       ,'X954'
                                       ,'X955'
                                       ,'X956'
                                       ,'X957'
                                       ,'X958'
                                       ,'X959'
                                       ,'X960'
                                       ,'X961'
                                       ,'X962'
                                       ,'X963'
-- 2008/11/19 v1.18 UPDATE START
--                                       ,'X964')
                                       ,'X964'
                                       ,'X965'
                                       ,'X966')
-- 2008/11/19 v1.18 UPDATE END
      AND    itc.trans_date > FND_DATE.STRING_TO_DATE(gd_prv1_dt_chr,gc_char_dt_format)
      AND    itc.trans_date < FND_DATE.STRING_TO_DATE(gd_flw_dt_chr,gc_char_dt_format)
      AND    ilm.item_id             = itc.item_id
      AND    ilm.lot_id              = itc.lot_id
      AND    iimb.item_id            = ilm.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(itc.trans_date)
      AND    ximb.end_date_active   >= TRUNC(itc.trans_date)
      AND    gic1.item_id            = itc.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = itc.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    gic3.item_id            = itc.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
      AND    xrpm.doc_type           = itc.doc_type
      AND    xrpm.reason_code        = itc.reason_code
      AND    xrpm.break_col_01       IS NOT NULL
      AND   iwm.whse_code            = itc.whse_code
-- 2009/03/05 v1.31 ADD START
      AND    iwm.attribute1          = '0'
-- 2009/03/05 v1.31 ADD END
      UNION ALL
      SELECT /*+ leading (itc gic1 mcb1 gic2 mcb2 xrpm) use_nl (itc gic1 mcb1 gic2 mcb2 xrpm) */
             iwm.whse_code                        h_whse_code
            ,iwm.whse_name                        h_whse_name
-- v1.33 Mod Start
--            ,itc.trans_id                         trans_id
            ,NULL                                 trans_id
-- v1.33 Mod End
            ,iimb.attribute15                     cost_mng_clss
            ,iimb.lot_ctl                         lot_ctl
            ,xlc.unit_ploce                       actual_unit_price
            ,CASE WHEN INSTR(xrpm.break_col_01,gv_hifn) = 0
                       THEN ''
                  WHEN xrpm.rcv_pay_div = gc_rcv_pay_div_in
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  ELSE SUBSTR(xrpm.break_col_01,INSTR(xrpm.break_col_01,gv_hifn) +1)
             END                                  column_no
            ,itc.reason_code                      reason_code
            ,itc.trans_date                       trans_date
            ,TO_CHAR(itc.trans_date, 'YYYYMM')  trans_ym
            ,CASE WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN TO_CHAR(ABS(TO_NUMBER(xrpm.rcv_pay_div)))
                  ELSE xrpm.rcv_pay_div
             END                                  rcv_pay_div
            ,xrpm.dealings_div                    dealings_div
            ,itc.doc_type                         doc_type
            ,ir_param.item_class                  item_div
            ,ir_param.goods_class                 prod_div
            ,mcb3.segment1                        crowd_code
            ,SUBSTR(mcb3.segment1, 1, 3)          crowd_low
            ,SUBSTR(mcb3.segment1, 1, 2)          crowd_mid
            ,SUBSTR(mcb3.segment1, 1, 1)          crowd_high
            ,itc.item_id                          item_id
            ,itc.lot_id                           lot_id
-- v1.33 Mod Start
--            ,NVL(itc.trans_qty, 0)                trans_qty
            ,SUM(NVL(itc.trans_qty, 0))           trans_qty
-- v1.33 Mod End
            ,itc.trans_date                       arrival_date
            ,TO_CHAR(itc.trans_date, gc_char_ym_format) arrival_ym
            ,iimb.item_no                         item_code
            ,ximb.item_short_name                 item_name
      FROM   ic_tran_cmp                      itc
-- v1.33 Add Start
            ,ic_adjs_jnl                      iaj
            ,ic_jrnl_mst                      ijm
-- v1.33 Add End
            ,ic_item_mst_b                    iimb
            ,xxcmn_item_mst_b                 ximb
            ,ic_lots_mst                      ilm
            ,xxcmn_lot_cost                   xlc
            ,gmi_item_categories              gic1
            ,mtl_categories_b                 mcb1
            ,gmi_item_categories              gic2
            ,mtl_categories_b                 mcb2
            ,gmi_item_categories              gic3
            ,mtl_categories_b                 mcb3
            ,xxcmn_rcv_pay_mst                xrpm
            ,ic_whse_mst                      iwm
      WHERE  itc.doc_type            = gv_doc_type_adji
      AND    itc.reason_code         = gv_reason_code_adji_po
      AND    itc.trans_date > FND_DATE.STRING_TO_DATE(gd_prv1_dt_chr,gc_char_dt_format)
      AND    itc.trans_date < FND_DATE.STRING_TO_DATE(gd_flw_dt_chr,gc_char_dt_format)
-- v1.33 Add Start
      AND    iaj.trans_type          = itc.doc_type
      AND    iaj.doc_id              = itc.doc_id
      AND    iaj.doc_line            = itc.doc_line
      AND    ijm.journal_id          = iaj.journal_id
-- v1.33 Add End
      AND    ilm.item_id             = itc.item_id
      AND    ilm.lot_id              = itc.lot_id
      AND    iimb.item_id            = ilm.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(itc.trans_date)
      AND    ximb.end_date_active   >= TRUNC(itc.trans_date)
      AND    gic1.item_id            = itc.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = itc.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    gic3.item_id            = itc.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
      AND    xrpm.doc_type           = itc.doc_type
      AND    xrpm.reason_code        = itc.reason_code
      AND    xrpm.break_col_01       IS NOT NULL
      AND   iwm.whse_code            = itc.whse_code
-- 2009/03/05 v1.31 ADD START
      AND    iwm.attribute1          = '0'
-- 2009/03/05 v1.31 ADD END
-- v1.33 Add Start
      GROUP BY
             iwm.whse_code                        -- h_whse_code
            ,iwm.whse_name                        -- h_whse_name
            ,iimb.attribute15                     -- cost_mng_clss
            ,iimb.lot_ctl                         -- lot_ctl
            ,xlc.unit_ploce                       -- actual_unit_price
            ,CASE WHEN INSTR(xrpm.break_col_01,gv_hifn) = 0
                       THEN ''
                  WHEN xrpm.rcv_pay_div = gc_rcv_pay_div_in
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  ELSE SUBSTR(xrpm.break_col_01,INSTR(xrpm.break_col_01,gv_hifn) +1)
             END                                  -- column_no
            ,itc.reason_code                      -- reason_code
            ,itc.trans_date                       -- trans_date
            ,TO_CHAR(itc.trans_date, 'YYYYMM')    -- trans_ym
            ,CASE WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN TO_CHAR(ABS(TO_NUMBER(xrpm.rcv_pay_div)))
                  ELSE xrpm.rcv_pay_div
             END                                  -- rcv_pay_div
            ,xrpm.dealings_div                    -- dealings_div
            ,itc.doc_type                         -- doc_type
            ,ir_param.item_class                  -- item_div
            ,ir_param.goods_class                 -- prod_div
            ,mcb3.segment1                        -- crowd_code
            ,SUBSTR(mcb3.segment1, 1, 3)          -- crowd_low
            ,SUBSTR(mcb3.segment1, 1, 2)          -- crowd_mid
            ,SUBSTR(mcb3.segment1, 1, 1)          -- crowd_high
            ,itc.item_id                          -- item_id
            ,itc.lot_id                           -- lot_id
            ,itc.trans_date                       -- arrival_date
            ,TO_CHAR(itc.trans_date, gc_char_ym_format) -- arrival_ym
            ,iimb.item_no                         -- item_code
            ,ximb.item_short_name                 -- item_name
            ,ijm.attribute1                       -- 受入返品実績アドオン.取引ID
-- v1.33 Add End
      UNION ALL
      SELECT /*+ leading (itc gic1 mcb1 gic2 mcb2 xrpm) use_nl (itc gic1 mcb1 gic2 mcb2 xrpm) */
             iwm.whse_code                        h_whse_code
            ,iwm.whse_name                        h_whse_name
            ,itc.trans_id                         trans_id
            ,iimb.attribute15                     cost_mng_clss
            ,iimb.lot_ctl                         lot_ctl
            ,xlc.unit_ploce                       actual_unit_price
            ,CASE WHEN INSTR(xrpm.break_col_01,gv_hifn) = 0
                       THEN ''
                  WHEN xrpm.rcv_pay_div = gc_rcv_pay_div_in
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  ELSE SUBSTR(xrpm.break_col_01,INSTR(xrpm.break_col_01,gv_hifn) +1)
             END                                  column_no
            ,itc.reason_code                      reason_code
            ,itc.trans_date                       trans_date
            ,TO_CHAR(itc.trans_date, 'YYYYMM')  trans_ym
            ,CASE WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN TO_CHAR(ABS(TO_NUMBER(xrpm.rcv_pay_div)))
                  ELSE xrpm.rcv_pay_div
             END                                  rcv_pay_div
            ,xrpm.dealings_div                    dealings_div
            ,itc.doc_type                         doc_type
            ,ir_param.item_class                  item_div
            ,ir_param.goods_class                 prod_div
            ,mcb3.segment1                        crowd_code
            ,SUBSTR(mcb3.segment1, 1, 3)          crowd_low
            ,SUBSTR(mcb3.segment1, 1, 2)          crowd_mid
            ,SUBSTR(mcb3.segment1, 1, 1)          crowd_high
            ,itc.item_id                          item_id
            ,itc.lot_id                           lot_id
            ,NVL(itc.trans_qty, 0)                trans_qty
            ,itc.trans_date                       arrival_date
            ,TO_CHAR(itc.trans_date, gc_char_ym_format) arrival_ym
            ,iimb.item_no                         item_code
            ,ximb.item_short_name                 item_name
      FROM   ic_tran_cmp                      itc
            ,ic_item_mst_b                    iimb
            ,xxcmn_item_mst_b                 ximb
            ,ic_lots_mst                      ilm
            ,xxcmn_lot_cost                   xlc
            ,gmi_item_categories              gic1
            ,mtl_categories_b                 mcb1
            ,gmi_item_categories              gic2
            ,mtl_categories_b                 mcb2
            ,gmi_item_categories              gic3
            ,mtl_categories_b                 mcb3
            ,xxcmn_rcv_pay_mst                xrpm
            ,ic_whse_mst                      iwm
      WHERE  itc.doc_type            = gv_doc_type_adji
      AND    itc.reason_code         = gv_reason_code_adji_hama
      AND    itc.trans_date > FND_DATE.STRING_TO_DATE(gd_prv1_dt_chr,gc_char_dt_format)
      AND    itc.trans_date < FND_DATE.STRING_TO_DATE(gd_flw_dt_chr,gc_char_dt_format)
      AND    ilm.item_id             = itc.item_id
      AND    ilm.lot_id              = itc.lot_id
      AND    iimb.item_id            = ilm.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(itc.trans_date)
      AND    ximb.end_date_active   >= TRUNC(itc.trans_date)
      AND    gic1.item_id            = itc.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = itc.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    gic3.item_id            = itc.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
      AND    xrpm.doc_type           = itc.doc_type
      AND    xrpm.reason_code        = itc.reason_code
      AND    xrpm.break_col_01       IS NOT NULL
      AND   iwm.whse_code            = itc.whse_code
-- 2009/03/05 v1.31 ADD START
      AND    iwm.attribute1          = '0'
-- 2009/03/05 v1.31 ADD END
      UNION ALL
      SELECT /*+ leading (xmrh xmrl ijm iaj itc gic1 mcb1 gic2 mcb2) use_nl (xmrh xmrl ijm iaj itc gic1 mcb1 gic2 mcb2) */
             iwm.whse_code                        h_whse_code
            ,iwm.whse_name                        h_whse_name
            ,itc.trans_id                         trans_id
            ,iimb.attribute15                     cost_mng_clss
            ,iimb.lot_ctl                         lot_ctl
            ,xlc.unit_ploce                       actual_unit_price
            ,CASE WHEN INSTR(xrpm.break_col_01,gv_hifn) = 0
                       THEN ''
                  WHEN xrpm.rcv_pay_div = gc_rcv_pay_div_in
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  ELSE SUBSTR(xrpm.break_col_01,INSTR(xrpm.break_col_01,gv_hifn) +1)
             END                                  column_no
            ,itc.reason_code                      reason_code
            ,itc.trans_date                       trans_date
            ,TO_CHAR(itc.trans_date, 'YYYYMM')  trans_ym
-- 2008/12/11 v1.26 N.Yoshida mod start
--            ,gc_rcv_pay_div_adj                   rcv_pay_div
            ,xrpm.rcv_pay_div                     rcv_pay_div
-- 2008/12/11 v1.26 N.Yoshida mod end
            ,xrpm.dealings_div                    dealings_div
            ,itc.doc_type                         doc_type
            ,ir_param.item_class                  item_div
            ,ir_param.goods_class                 prod_div
            ,mcb3.segment1                        crowd_code
            ,SUBSTR(mcb3.segment1, 1, 3)          crowd_low
            ,SUBSTR(mcb3.segment1, 1, 2)          crowd_mid
            ,SUBSTR(mcb3.segment1, 1, 1)          crowd_high
            ,itc.item_id                          item_id
            ,itc.lot_id                           lot_id
-- 2008/12/11 v1.26 N.Yoshida mod start
--            ,ABS(NVL(itc.trans_qty, 0))           trans_qty
            ,NVL(itc.trans_qty, 0)                trans_qty
-- 2008/12/11 v1.26 N.Yoshida mod end
            ,xmrh.actual_arrival_date             arrival_date
            ,TO_CHAR(xmrh.actual_arrival_date, gc_char_ym_format) arrival_ym
            ,iimb.item_no                         item_code
            ,ximb.item_short_name                 item_name
      FROM   ic_tran_cmp                      itc
            ,ic_adjs_jnl                      iaj
            ,ic_jrnl_mst                      ijm
            ,xxinv_mov_req_instr_headers      xmrh
            ,xxinv_mov_req_instr_lines        xmrl
            ,ic_item_mst_b                    iimb
            ,xxcmn_item_mst_b                 ximb
            ,ic_lots_mst                      ilm
            ,xxcmn_lot_cost                   xlc
            ,gmi_item_categories              gic1
            ,mtl_categories_b                 mcb1
            ,gmi_item_categories              gic2
            ,mtl_categories_b                 mcb2
            ,gmi_item_categories              gic3
            ,mtl_categories_b                 mcb3
            ,xxcmn_rcv_pay_mst                xrpm
            ,ic_whse_mst                      iwm
      WHERE  itc.doc_type            = gv_doc_type_adji
      AND    itc.reason_code         = gv_reason_code_adji_move
      AND    xmrh.actual_arrival_date > FND_DATE.STRING_TO_DATE(gd_prv1_dt_chr,gc_char_dt_format)
      AND    xmrh.actual_arrival_date < FND_DATE.STRING_TO_DATE(gd_flw_dt_chr,gc_char_dt_format)
      AND    iaj.trans_type          = itc.doc_type
      AND    iaj.doc_id              = itc.doc_id
      AND    iaj.doc_line            = itc.doc_line
      AND    ijm.journal_id          = iaj.journal_id
      AND    ijm.attribute1          = TO_CHAR(xmrl.mov_line_id)
      AND    xmrh.mov_hdr_id         = xmrl.mov_hdr_id
      AND    ilm.item_id             = itc.item_id
      AND    ilm.lot_id              = itc.lot_id
      AND    iimb.item_id            = ilm.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(itc.trans_date)
      AND    ximb.end_date_active   >= TRUNC(itc.trans_date)
      AND    gic1.item_id            = itc.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = itc.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    gic3.item_id            = itc.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
-- 2008/12/11 v1.26 N.Yoshida mod start
      AND    xrpm.rcv_pay_div        = CASE
--                                       WHEN itc.trans_qty >= 0 THEN 1
--                                       ELSE -1
                                       WHEN itc.trans_qty >= 0 THEN -1
                                       ELSE 1
                                       END
-- 2008/12/11 v1.26 N.Yoshida mod end
      AND    xrpm.doc_type           = itc.doc_type
      AND    xrpm.reason_code        = itc.reason_code
      AND    xrpm.break_col_01       IS NOT NULL
      AND   iwm.whse_code            = itc.whse_code
-- 2009/03/05 v1.31 ADD START
      AND    iwm.attribute1          = '0'
-- 2009/03/05 v1.31 ADD END
      UNION ALL
      SELECT /*+ leading (itc gic1 mcb1 gic2 mcb2) use_nl (itc gic1 mcb1 gic2 mcb2) */
             iwm.whse_code                        h_whse_code
            ,iwm.whse_name                        h_whse_name
            ,itc.trans_id                         trans_id
            ,iimb.attribute15                     cost_mng_clss
            ,iimb.lot_ctl                         lot_ctl
            ,xlc.unit_ploce                       actual_unit_price
            ,CASE WHEN INSTR(xrpm.break_col_01,gv_hifn) = 0
                       THEN ''
                  WHEN xrpm.rcv_pay_div = gc_rcv_pay_div_in
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  ELSE SUBSTR(xrpm.break_col_01,INSTR(xrpm.break_col_01,gv_hifn) +1)
             END                                  column_no
            ,itc.reason_code                      reason_code
            ,itc.trans_date                       trans_date
            ,TO_CHAR(itc.trans_date, 'YYYYMM')  trans_ym
            ,CASE WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN TO_CHAR(ABS(TO_NUMBER(xrpm.rcv_pay_div)))
                  ELSE xrpm.rcv_pay_div
             END                                  rcv_pay_div
            ,xrpm.dealings_div                    dealings_div
            ,itc.doc_type                         doc_type
            ,ir_param.item_class                  item_div
            ,ir_param.goods_class                 prod_div
            ,mcb3.segment1                        crowd_code
            ,SUBSTR(mcb3.segment1, 1, 3)          crowd_low
            ,SUBSTR(mcb3.segment1, 1, 2)          crowd_mid
            ,SUBSTR(mcb3.segment1, 1, 1)          crowd_high
            ,itc.item_id                          item_id
            ,itc.lot_id                           lot_id
            ,NVL(itc.trans_qty, 0)                trans_qty
            ,itc.trans_date                       arrival_date
            ,TO_CHAR(itc.trans_date, gc_char_ym_format) arrival_ym
            ,iimb.item_no                         item_code
            ,ximb.item_short_name                 item_name
      FROM   ic_tran_cmp                      itc
            ,ic_item_mst_b                    iimb
            ,xxcmn_item_mst_b                 ximb
            ,ic_lots_mst                      ilm
            ,xxcmn_lot_cost                   xlc
            ,gmi_item_categories              gic1
            ,mtl_categories_b                 mcb1
            ,gmi_item_categories              gic2
            ,mtl_categories_b                 mcb2
            ,gmi_item_categories              gic3
            ,mtl_categories_b                 mcb3
            ,xxcmn_rcv_pay_mst                xrpm
            ,ic_whse_mst                      iwm
      WHERE  itc.doc_type            = gv_doc_type_adji
      AND    itc.reason_code        IN (gv_reason_code_adji_itm
                                       ,gv_reason_code_adji_itm_u
                                       ,gv_reason_code_adji_snt_u
                                       ,gv_reason_code_adji_snt)
      AND    itc.trans_date > FND_DATE.STRING_TO_DATE(gd_prv1_dt_chr,gc_char_dt_format)
      AND    itc.trans_date < FND_DATE.STRING_TO_DATE(gd_flw_dt_chr,gc_char_dt_format)
      AND    ilm.item_id             = itc.item_id
      AND    ilm.lot_id              = itc.lot_id
      AND    iimb.item_id            = ilm.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(itc.trans_date)
      AND    ximb.end_date_active   >= TRUNC(itc.trans_date)
      AND    gic1.item_id            = itc.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = itc.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    gic3.item_id            = itc.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
-- 2008/11/19 v1.18 DELETE START
      --AND    xrpm.rcv_pay_div        = CASE
      --                                 WHEN itc.trans_qty >= 0 THEN 1
      --                                 ELSE -1
      --                                 END
-- 2008/11/19 v1.18 DELETE END
      AND    xrpm.doc_type           = itc.doc_type
      AND    xrpm.reason_code        = itc.reason_code
      AND    xrpm.break_col_01       IS NOT NULL
      AND   iwm.whse_code            = itc.whse_code
-- 2009/03/05 v1.31 ADD START
      AND    iwm.attribute1          = '0'
-- 2009/03/05 v1.31 ADD END
      UNION ALL
      SELECT /*+ leading (itp gic1 mcb1 gic2 mcb2) use_nl (itp gic1 mcb1 gic2 mcb2)*/
             iwm.whse_code                        h_whse_code
            ,iwm.whse_name                        h_whse_name
            ,itp.trans_id                         trans_id
            ,iimb.attribute15                     cost_mng_clss
            ,iimb.lot_ctl                         lot_ctl
            ,xlc.unit_ploce                       actual_unit_price
            ,CASE WHEN INSTR(xrpm.break_col_01,gv_hifn) = 0
                       THEN ''
                  WHEN xrpm.rcv_pay_div = gc_rcv_pay_div_in
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  ELSE SUBSTR(xrpm.break_col_01,INSTR(xrpm.break_col_01,gv_hifn) +1)
             END                                  column_no
            ,itp.reason_code                      reason_code
            ,itp.trans_date                       trans_date
            ,TO_CHAR(itp.trans_date, 'YYYYMM')  trans_ym
            ,CASE WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN TO_CHAR(ABS(TO_NUMBER(xrpm.rcv_pay_div)))
                  ELSE xrpm.rcv_pay_div
             END                                  rcv_pay_div
            ,xrpm.dealings_div                    dealings_div
            ,itp.doc_type                         doc_type
            ,ir_param.item_class                  item_div
            ,ir_param.goods_class                 prod_div
            ,mcb3.segment1                        crowd_code
            ,SUBSTR(mcb3.segment1, 1, 3)          crowd_low
            ,SUBSTR(mcb3.segment1, 1, 2)          crowd_mid
            ,SUBSTR(mcb3.segment1, 1, 1)          crowd_high
            ,itp.item_id                          item_id
            ,itp.lot_id                           lot_id
            ,NVL(itp.trans_qty, 0)                trans_qty
            ,itp.trans_date                       arrival_date
            ,TO_CHAR(itp.trans_date, gc_char_ym_format) arrival_ym
            ,iimb.item_no                         item_code
            ,ximb.item_short_name                 item_name
      FROM   ic_tran_pnd                      itp
            ,ic_item_mst_b                    iimb
            ,xxcmn_item_mst_b                 ximb
            ,ic_lots_mst                      ilm
            ,xxcmn_lot_cost                   xlc
            ,gmi_item_categories              gic1
            ,mtl_categories_b                 mcb1
            ,gmi_item_categories              gic2
            ,mtl_categories_b                 mcb2
            ,gmi_item_categories              gic3
            ,mtl_categories_b                 mcb3
            ,gme_material_details             gmd
            ,gme_batch_header                 gbh
            ,gmd_routings_b                   grb
            ,xxcmn_rcv_pay_mst                xrpm
            ,ic_whse_mst                      iwm
      WHERE  itp.doc_type            = gv_doc_type_prod
      AND    itp.completed_ind       = 1
      AND    itp.trans_date > FND_DATE.STRING_TO_DATE(gd_prv1_dt_chr,gc_char_dt_format)
      AND    itp.trans_date < FND_DATE.STRING_TO_DATE(gd_flw_dt_chr,gc_char_dt_format)
      AND    itp.reverse_id          IS NULL
      AND    ilm.item_id             = itp.item_id
      AND    ilm.lot_id              = itp.lot_id
      AND    iimb.item_id            = ilm.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(itp.trans_date)
      AND    ximb.end_date_active   >= TRUNC(itp.trans_date)
      AND    gic1.item_id            = itp.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = itp.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    gic3.item_id            = itp.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
      AND    gmd.batch_id            = itp.doc_id
      AND    gmd.line_no             = itp.doc_line
      AND    gmd.line_type           = itp.line_type
      AND    gbh.batch_id            = gmd.batch_id
      AND    grb.routing_id          = gbh.routing_id
      AND    xrpm.routing_class      = grb.routing_class
      AND    xrpm.line_type          = gmd.line_type
      AND    (((gmd.attribute5 IS NULL) AND (xrpm.hit_in_div IS NULL))
             OR (xrpm.hit_in_div = gmd.attribute5))
      AND    itp.doc_type            = xrpm.doc_type
      AND    itp.line_type           = xrpm.line_type
      AND    xrpm.break_col_01       IS NOT NULL
      AND    xrpm.routing_class      <> '70'
      AND   iwm.whse_code            = itp.whse_code
-- 2009/03/05 v1.31 ADD START
      AND    iwm.attribute1          = '0'
-- 2009/03/05 v1.31 ADD END
      UNION ALL
      SELECT /*+ leading (itp gic1 mcb1 gic2 mcb2 gmd gbh grb) use_nl (itp gic1 mcb1 gic2 mcb2 gmd gbh grb)*/
             iwm.whse_code                        h_whse_code
            ,iwm.whse_name                        h_whse_name
            ,itp.trans_id                         trans_id
            ,iimb.attribute15                     cost_mng_clss
            ,iimb.lot_ctl                         lot_ctl
            ,xlc.unit_ploce                       actual_unit_price
            ,CASE WHEN INSTR(xrpm.break_col_01,gv_hifn) = 0
                       THEN ''
                  WHEN xrpm.rcv_pay_div = gc_rcv_pay_div_in
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  ELSE SUBSTR(xrpm.break_col_01,INSTR(xrpm.break_col_01,gv_hifn) +1)
             END                                  column_no
            ,itp.reason_code                      reason_code
            ,itp.trans_date                       trans_date
            ,TO_CHAR(itp.trans_date, 'YYYYMM')  trans_ym
            ,CASE WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN TO_CHAR(ABS(TO_NUMBER(xrpm.rcv_pay_div)))
                  ELSE xrpm.rcv_pay_div
             END                                  rcv_pay_div
            ,xrpm.dealings_div                    dealings_div
            ,itp.doc_type                         doc_type
            ,ir_param.item_class                  item_div
            ,ir_param.goods_class                 prod_div
            ,mcb3.segment1                        crowd_code
            ,SUBSTR(mcb3.segment1, 1, 3)          crowd_low
            ,SUBSTR(mcb3.segment1, 1, 2)          crowd_mid
            ,SUBSTR(mcb3.segment1, 1, 1)          crowd_high
            ,itp.item_id                          item_id
            ,itp.lot_id                           lot_id
            ,NVL(itp.trans_qty, 0)                trans_qty
            ,itp.trans_date                       arrival_date
            ,TO_CHAR(itp.trans_date, gc_char_ym_format) arrival_ym
            ,iimb.item_no                         item_code
            ,ximb.item_short_name                 item_name
      FROM   ic_tran_pnd                      itp
            ,ic_item_mst_b                    iimb
            ,xxcmn_item_mst_b                 ximb
            ,ic_lots_mst                      ilm
            ,xxcmn_lot_cost                   xlc
            ,gmi_item_categories              gic1
            ,mtl_categories_b                 mcb1
            ,gmi_item_categories              gic2
            ,mtl_categories_b                 mcb2
            ,gmi_item_categories              gic3
            ,mtl_categories_b                 mcb3
            ,gme_material_details             gmd
            ,gme_batch_header                 gbh
            ,gmd_routings_b                   grb
            ,xxcmn_rcv_pay_mst                xrpm
            ,ic_whse_mst                      iwm
      WHERE  itp.doc_type            = gv_doc_type_prod
      AND    itp.completed_ind       = 1
      AND    itp.trans_date > FND_DATE.STRING_TO_DATE(gd_prv1_dt_chr,gc_char_dt_format)
      AND    itp.trans_date < FND_DATE.STRING_TO_DATE(gd_flw_dt_chr,gc_char_dt_format)
      AND    itp.reverse_id          IS NULL
      AND    ilm.item_id             = itp.item_id
      AND    ilm.lot_id              = itp.lot_id
      AND    iimb.item_id            = ilm.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(itp.trans_date)
      AND    ximb.end_date_active   >= TRUNC(itp.trans_date)
      AND    gic1.item_id            = itp.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = itp.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    mcb2.segment1           IN ('1','4')
      AND    gic3.item_id            = itp.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
      AND    gmd.batch_id            = itp.doc_id
      AND    gmd.line_no             = itp.doc_line
      AND    gmd.line_type           = itp.line_type
      AND    gbh.batch_id            = gmd.batch_id
      AND    grb.routing_id          = gbh.routing_id
      AND    xrpm.routing_class      = grb.routing_class
      AND    xrpm.line_type          = gmd.line_type
      AND    (((gmd.attribute5 IS NULL) AND (xrpm.hit_in_div IS NULL))
             OR (xrpm.hit_in_div = gmd.attribute5))
      AND    itp.doc_type            = xrpm.doc_type
      AND    itp.line_type           = xrpm.line_type
      AND    xrpm.break_col_01       IS NOT NULL
      AND    xrpm.routing_class      = '70'
      AND    (EXISTS (SELECT 1
                      FROM   gme_material_details gmd2
                            ,gmi_item_categories  gic
                            ,mtl_categories_b     mcb
                      WHERE  gmd2.batch_id   = gmd.batch_id
                      AND    gmd2.line_no    = gmd.line_no
                      AND    gmd2.line_type  = -1
                      AND    gic.item_id     = gmd2.item_id
                      AND    gic.category_set_id = cn_item_class_id
                      AND    gic.category_id = mcb.category_id
                      AND    mcb.segment1    = xrpm.item_div_origin))
      AND    (EXISTS (SELECT 1
                      FROM   gme_material_details gmd3
                            ,gmi_item_categories  gic
                            ,mtl_categories_b     mcb
                      WHERE  gmd3.batch_id   = gmd.batch_id
                      AND    gmd3.line_no    = gmd.line_no
                      AND    gmd3.line_type  = 1
                      AND    gic.item_id     = gmd3.item_id
                      AND    gic.category_set_id = cn_item_class_id
                      AND    gic.category_id = mcb.category_id
                      AND    mcb.segment1    = xrpm.item_div_ahead))
      AND   iwm.whse_code            = itp.whse_code
-- 2009/03/05 v1.31 ADD START
      AND    iwm.attribute1          = '0'
-- 2009/03/05 v1.31 ADD END
      UNION ALL
      SELECT /*+ leading (xoha xola rsl itp gic1 mcb1 gic2 mcb2 ooha otta) use_nl (xoha xola rsl itp gic1 mcb1 gic2 mcb2 ooha otta) */
             iwm.whse_code                        h_whse_code
            ,iwm.whse_name                        h_whse_name
            ,itp.trans_id                         trans_id
            ,iimb.attribute15                     cost_mng_clss
            ,iimb.lot_ctl                         lot_ctl
            ,xlc.unit_ploce                       actual_unit_price
            ,CASE WHEN INSTR(xrpm.break_col_01,gv_hifn) = 0
                       THEN ''
                  WHEN xrpm.rcv_pay_div = gc_rcv_pay_div_in
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  ELSE SUBSTR(xrpm.break_col_01,INSTR(xrpm.break_col_01,gv_hifn) +1)
             END                                  column_no
            ,itp.reason_code                      reason_code
            ,itp.trans_date                       trans_date
            ,TO_CHAR(itp.trans_date, 'YYYYMM')  trans_ym
            ,CASE WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN TO_CHAR(ABS(TO_NUMBER(xrpm.rcv_pay_div)))
                  ELSE xrpm.rcv_pay_div
             END                                  rcv_pay_div
            ,xrpm.dealings_div                    dealings_div
            ,itp.doc_type                         doc_type
            ,ir_param.item_class                  item_div
            ,ir_param.goods_class                 prod_div
            ,mcb3.segment1                        crowd_code
            ,SUBSTR(mcb3.segment1, 1, 3)          crowd_low
            ,SUBSTR(mcb3.segment1, 1, 2)          crowd_mid
            ,SUBSTR(mcb3.segment1, 1, 1)          crowd_high
            ,itp.item_id                          item_id
            ,itp.lot_id                           lot_id
            ,NVL(itp.trans_qty, 0)                trans_qty
            ,xoha.arrival_date                    arrival_date
            ,TO_CHAR(xoha.arrival_date, gc_char_ym_format) arrival_ym
            ,iimb.item_no                         item_code
            ,ximb.item_short_name                 item_name
      FROM   ic_tran_pnd                      itp
            ,rcv_shipment_lines               rsl
            ,oe_order_headers_all             ooha
            ,oe_transaction_types_all         otta
            ,xxwsh_order_headers_all          xoha
            ,xxwsh_order_lines_all            xola
            ,ic_item_mst_b                    iimb
            ,xxcmn_item_mst_b                 ximb
            ,ic_lots_mst                      ilm
            ,xxcmn_lot_cost                   xlc
            ,gmi_item_categories              gic1
            ,mtl_categories_b                 mcb1
            ,gmi_item_categories              gic2
            ,mtl_categories_b                 mcb2
            ,gmi_item_categories              gic3
            ,mtl_categories_b                 mcb3
            ,xxcmn_rcv_pay_mst                xrpm
            ,ic_whse_mst                      iwm
      WHERE  itp.doc_type            = gv_doc_type_porc
      AND    itp.completed_ind       = 1
      AND    xoha.latest_external_flag = 'Y'
      AND    xoha.arrival_date > FND_DATE.STRING_TO_DATE(gd_prv1_dt_chr,gc_char_dt_format)
      AND    xoha.arrival_date < FND_DATE.STRING_TO_DATE(gd_flw_dt_chr,gc_char_dt_format)
      AND    xoha.req_status         IN ('04','08')
      AND    ilm.item_id             = itp.item_id
      AND    ilm.lot_id              = itp.lot_id
      AND    iimb.item_id            = itp.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(itp.trans_date)
      AND    ximb.end_date_active   >= TRUNC(itp.trans_date)
      AND    gic1.item_id            = itp.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = itp.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    gic3.item_id            = itp.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
      AND    rsl.shipment_header_id  = itp.doc_id
      AND    rsl.line_num            = itp.doc_line
      AND    rsl.oe_order_header_id  = xola.header_id
      AND    rsl.oe_order_line_id    = xola.line_id
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    ((otta.attribute4           <> '2')
             OR  (otta.attribute4       IS NULL))
      AND    otta.attribute1         IN ('1','2')
      AND    xoha.header_id          = ooha.header_id
      AND    xola.order_header_id    = xoha.order_header_id
      AND    xola.request_item_code  = xola.shipping_item_code
      AND    xrpm.doc_type           = itp.doc_type
      AND    xrpm.source_document_code = 'RMA'
      AND    xrpm.dealings_div       IN ('101','103')
      AND    xrpm.shipment_provision_div = DECODE(xoha.req_status,'04','1','08','2')
      AND    xrpm.shipment_provision_div = otta.attribute1
      AND    ((xrpm.ship_prov_rcv_pay_category IS NULL)
             OR (xrpm.ship_prov_rcv_pay_category = otta.attribute11))
      AND    xrpm.break_col_01       IS NOT NULL
      AND    xrpm.item_div_origin    IS NULL
      AND    xrpm.item_div_ahead     IS NULL
      AND   iwm.whse_code            = itp.whse_code
-- 2009/03/05 v1.31 ADD START
      AND    iwm.attribute1          = '0'
-- 2009/03/05 v1.31 ADD END
      UNION ALL
      SELECT /*+ leading (xoha xola rsl itp gic1 mcb1 gic2 mcb2 ooha otta) use_nl (xoha xola rsl itp gic1 mcb1 gic2 mcb2 ooha otta) */
             iwm.whse_code                        h_whse_code
            ,iwm.whse_name                        h_whse_name
            ,itp.trans_id                         trans_id
            ,iimb.attribute15                     cost_mng_clss
            ,iimb.lot_ctl                         lot_ctl
            ,xlc.unit_ploce                       actual_unit_price
            ,CASE WHEN INSTR(xrpm.break_col_01,gv_hifn) = 0
                       THEN ''
                  WHEN xrpm.rcv_pay_div = gc_rcv_pay_div_in
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  ELSE SUBSTR(xrpm.break_col_01,INSTR(xrpm.break_col_01,gv_hifn) +1)
             END                                  column_no
            ,itp.reason_code                      reason_code
            ,itp.trans_date                       trans_date
            ,TO_CHAR(itp.trans_date, 'YYYYMM')  trans_ym
            ,CASE WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN TO_CHAR(ABS(TO_NUMBER(xrpm.rcv_pay_div)))
                  ELSE xrpm.rcv_pay_div
             END                                  rcv_pay_div
            ,xrpm.dealings_div                    dealings_div
            ,itp.doc_type                         doc_type
            ,ir_param.item_class                  item_div
            ,ir_param.goods_class                 prod_div
            ,mcb3.segment1                        crowd_code
            ,SUBSTR(mcb3.segment1, 1, 3)          crowd_low
            ,SUBSTR(mcb3.segment1, 1, 2)          crowd_mid
            ,SUBSTR(mcb3.segment1, 1, 1)          crowd_high
            ,iimb.item_id                         item_id
            ,itp.lot_id                           lot_id
            ,NVL(itp.trans_qty, 0)                trans_qty
            ,xoha.arrival_date                      arrival_date
            ,TO_CHAR(xoha.arrival_date, gc_char_ym_format) arrival_ym
            ,iimb.item_no                         item_code
            ,ximb.item_short_name                 item_name
      FROM   ic_tran_pnd                      itp
            ,rcv_shipment_lines               rsl
            ,oe_order_headers_all             ooha
            ,oe_transaction_types_all         otta
            ,xxwsh_order_headers_all          xoha
            ,xxwsh_order_lines_all            xola
            ,ic_item_mst_b                    iimb
            ,ic_item_mst_b                    iimb2
            ,xxcmn_item_mst_b                 ximb
            ,ic_lots_mst                      ilm
            ,xxcmn_lot_cost                   xlc
            ,gmi_item_categories              gic1
            ,mtl_categories_b                 mcb1
            ,gmi_item_categories              gic2
            ,mtl_categories_b                 mcb2
            ,gmi_item_categories              gic3
            ,mtl_categories_b                 mcb3
            ,gmi_item_categories              gic4
            ,mtl_categories_b                 mcb4
            ,xxcmn_rcv_pay_mst                xrpm
            ,ic_whse_mst                      iwm
      WHERE  itp.doc_type            = gv_doc_type_porc
      AND    itp.completed_ind       = 1
      AND    xoha.latest_external_flag = 'Y'
      AND    xoha.arrival_date > FND_DATE.STRING_TO_DATE(gd_prv1_dt_chr,gc_char_dt_format)
      AND    xoha.arrival_date < FND_DATE.STRING_TO_DATE(gd_flw_dt_chr,gc_char_dt_format)
      AND    xoha.req_status         IN ('04','08')
      AND    ilm.item_id             = itp.item_id
      AND    ilm.lot_id              = itp.lot_id
      AND    iimb.item_id            = itp.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    iimb2.item_no           = xola.request_item_code
      AND    ximb.start_date_active <= TRUNC(itp.trans_date)
      AND    ximb.end_date_active   >= TRUNC(itp.trans_date)
      AND    gic1.item_id            = itp.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = itp.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    gic3.item_id            = itp.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
      AND    gic4.item_id            = iimb2.item_id
      AND    gic4.category_set_id    = cn_item_class_id
      AND    gic4.category_id        = mcb4.category_id
      AND    rsl.shipment_header_id  = itp.doc_id
      AND    rsl.line_num            = itp.doc_line
      AND    rsl.oe_order_header_id  = xoha.header_id
      AND    rsl.oe_order_line_id    = xola.line_id
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    ((otta.attribute4           <> '2')
             OR  (otta.attribute4       IS NULL))
      AND    otta.attribute1         IN ('1','2')
      AND    xoha.header_id          = ooha.header_id
      AND    xola.order_header_id    = xoha.order_header_id
      AND    xrpm.doc_type           = itp.doc_type
      AND    xrpm.source_document_code = 'RMA'
      AND    xrpm.dealings_div       = '106'
      AND    xrpm.shipment_provision_div = DECODE(xoha.req_status,'04','1','08','2')
      AND    xrpm.shipment_provision_div = otta.attribute1
      AND    xrpm.ship_prov_rcv_pay_category = otta.attribute11
      AND    xrpm.item_div_ahead     = mcb4.segment1
      AND    mcb2.segment1           <> '5'
      AND    xrpm.break_col_01       IS NOT NULL
      AND   iwm.whse_code            = itp.whse_code
-- 2009/03/05 v1.31 ADD START
      AND    iwm.attribute1          = '0'
-- 2009/03/05 v1.31 ADD END
      UNION ALL
      SELECT /*+ leading (xoha xola rsl itp gic1 mcb1 gic2 mcb2 ooha otta xrpm) use_nl (xoha xola rsl itp gic1 mcb1 gic2 mcb2 rsl ooha otta xrpm) */
             iwm.whse_code                        h_whse_code
            ,iwm.whse_name                        h_whse_name
            ,itp.trans_id                         trans_id
            ,iimb.attribute15                     cost_mng_clss
            ,iimb.lot_ctl                         lot_ctl
            ,xlc.unit_ploce                       actual_unit_price
            ,CASE WHEN INSTR(xrpm.break_col_01,gv_hifn) = 0
                       THEN ''
                  WHEN xrpm.rcv_pay_div = gc_rcv_pay_div_in
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  ELSE SUBSTR(xrpm.break_col_01,INSTR(xrpm.break_col_01,gv_hifn) +1)
             END                                  column_no
            ,itp.reason_code                      reason_code
            ,itp.trans_date                       trans_date
            ,TO_CHAR(itp.trans_date, 'YYYYMM')  trans_ym
            ,CASE WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN TO_CHAR(ABS(TO_NUMBER(xrpm.rcv_pay_div)))
                  ELSE xrpm.rcv_pay_div
             END                                  rcv_pay_div
            ,xrpm.dealings_div                    dealings_div
            ,itp.doc_type                         doc_type
            ,ir_param.item_class                  item_div
            ,ir_param.goods_class                 prod_div
            ,mcb3.segment1                        crowd_code
            ,SUBSTR(mcb3.segment1, 1, 3)          crowd_low
            ,SUBSTR(mcb3.segment1, 1, 2)          crowd_mid
            ,SUBSTR(mcb3.segment1, 1, 1)          crowd_high
            ,iimb.item_id                         item_id
            ,itp.lot_id                           lot_id
            ,NVL(itp.trans_qty, 0)                trans_qty
            ,xoha.arrival_date                    arrival_date
            ,TO_CHAR(xoha.arrival_date, gc_char_ym_format) arrival_ym
            ,iimb.item_no                         item_code
            ,ximb.item_short_name                 item_name
      FROM   ic_tran_pnd                      itp
            ,rcv_shipment_lines               rsl
            ,oe_order_headers_all             ooha
            ,oe_transaction_types_all         otta
            ,xxwsh_order_headers_all          xoha
            ,xxwsh_order_lines_all            xola
            ,ic_item_mst_b                    iimb
            ,ic_item_mst_b                    iimb2
            ,xxcmn_item_mst_b                 ximb
            ,ic_lots_mst                      ilm
            ,xxcmn_lot_cost                   xlc
            ,gmi_item_categories              gic1
            ,mtl_categories_b                 mcb1
            ,gmi_item_categories              gic2
            ,mtl_categories_b                 mcb2
            ,gmi_item_categories              gic3
            ,mtl_categories_b                 mcb3
            ,gmi_item_categories              gic4
            ,mtl_categories_b                 mcb4
            ,xxcmn_rcv_pay_mst                xrpm
            ,ic_whse_mst                      iwm
      WHERE  itp.doc_type            = gv_doc_type_porc
      AND    itp.completed_ind       = 1
      AND    xoha.latest_external_flag = 'Y'
      AND    xoha.arrival_date > FND_DATE.STRING_TO_DATE(gd_prv1_dt_chr,gc_char_dt_format)
      AND    xoha.arrival_date < FND_DATE.STRING_TO_DATE(gd_flw_dt_chr,gc_char_dt_format)
      AND    xoha.req_status         = '04'
      AND    ilm.item_id             = itp.item_id
      AND    ilm.lot_id              = itp.lot_id
      AND    iimb.item_id            = itp.item_id
      AND    iimb2.item_no           = xola.request_item_code
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(itp.trans_date)
      AND    ximb.end_date_active   >= TRUNC(itp.trans_date)
      AND    gic1.item_id            = itp.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = itp.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    gic3.item_id            = itp.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
      AND    gic4.item_id            = iimb2.item_id
      AND    gic4.category_set_id    = cn_item_class_id
      AND    gic4.category_id        = mcb4.category_id
      AND    rsl.shipment_header_id  = itp.doc_id
      AND    rsl.line_num            = itp.doc_line
      AND    rsl.oe_order_header_id  = xoha.header_id
      AND    rsl.oe_order_line_id    = xola.line_id
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    ((otta.attribute4           <> '2')
             OR  (otta.attribute4       IS NULL))
      AND    xoha.header_id          = ooha.header_id
      AND    xola.order_header_id    = xoha.order_header_id
      AND    xrpm.doc_type           = itp.doc_type
      AND    xrpm.source_document_code = 'RMA'
      AND    xrpm.dealings_div       = '113'
      AND    xrpm.shipment_provision_div = DECODE(xoha.req_status,'04','1','08','2')
      AND    xrpm.item_div_ahead     = mcb4.segment1
      AND    mcb2.segment1           <> '5'
      AND    xrpm.break_col_01       IS NOT NULL
      AND   iwm.whse_code            = itp.whse_code
-- 2009/03/05 v1.31 ADD START
      AND    iwm.attribute1          = '0'
-- 2009/03/05 v1.31 ADD END
      UNION ALL
      SELECT /*+ leading (xoha ooha otta xola rsl itp gic1 mcb1 gic2 mcb2) use_nl (xoha ooha otta xola rsl itp gic1 mcb1 gic2 mcb2) */
             iwm.whse_code                        h_whse_code
            ,iwm.whse_name                        h_whse_name
            ,itp.trans_id                         trans_id
            ,iimb.attribute15                     cost_mng_clss
            ,iimb.lot_ctl                         lot_ctl
            ,xlc.unit_ploce                       actual_unit_price
            ,CASE WHEN INSTR(xrpm.break_col_01,gv_hifn) = 0
                       THEN ''
                  WHEN xrpm.rcv_pay_div = gc_rcv_pay_div_in
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  ELSE SUBSTR(xrpm.break_col_01,INSTR(xrpm.break_col_01,gv_hifn) +1)
             END                                  column_no
            ,itp.reason_code                      reason_code
            ,itp.trans_date                       trans_date
            ,TO_CHAR(itp.trans_date, 'YYYYMM')  trans_ym
            ,CASE WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN TO_CHAR(ABS(TO_NUMBER(xrpm.rcv_pay_div)))
                  ELSE xrpm.rcv_pay_div
             END                                  rcv_pay_div
            ,xrpm.dealings_div                    dealings_div
            ,itp.doc_type                         doc_type
            ,ir_param.item_class                  item_div
            ,ir_param.goods_class                 prod_div
            ,mcb3.segment1                        crowd_code
            ,SUBSTR(mcb3.segment1, 1, 3)          crowd_low
            ,SUBSTR(mcb3.segment1, 1, 2)          crowd_mid
            ,SUBSTR(mcb3.segment1, 1, 1)          crowd_high
            ,itp.item_id                          item_id
            ,itp.lot_id                           lot_id
            ,NVL(itp.trans_qty, 0)                trans_qty
            ,xoha.arrival_date                    arrival_date
            ,TO_CHAR(xoha.arrival_date, gc_char_ym_format) arrival_ym
            ,iimb.item_no                         item_code
            ,ximb.item_short_name                 item_name
      FROM   ic_tran_pnd                      itp
            ,rcv_shipment_lines               rsl
            ,oe_order_headers_all             ooha
            ,oe_transaction_types_all         otta
            ,xxwsh_order_headers_all          xoha
            ,xxwsh_order_lines_all            xola
            ,ic_item_mst_b                    iimb
            ,xxcmn_item_mst_b                 ximb
            ,ic_lots_mst                      ilm
            ,xxcmn_lot_cost                   xlc
            ,gmi_item_categories              gic1
            ,mtl_categories_b                 mcb1
            ,gmi_item_categories              gic2
            ,mtl_categories_b                 mcb2
            ,gmi_item_categories              gic3
            ,mtl_categories_b                 mcb3
            ,xxcmn_rcv_pay_mst                xrpm
            ,ic_whse_mst                      iwm
      WHERE  itp.doc_type            = gv_doc_type_porc
      AND    itp.completed_ind       = 1
      AND    xoha.latest_external_flag = 'Y'
      AND    xoha.arrival_date > FND_DATE.STRING_TO_DATE(gd_prv1_dt_chr,gc_char_dt_format)
      AND    xoha.arrival_date < FND_DATE.STRING_TO_DATE(gd_flw_dt_chr,gc_char_dt_format)
      AND    ilm.item_id             = itp.item_id
      AND    ilm.lot_id              = itp.lot_id
      AND    iimb.item_id            = itp.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(itp.trans_date)
      AND    ximb.end_date_active   >= TRUNC(itp.trans_date)
      AND    gic1.item_id            = itp.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = itp.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    gic3.item_id            = itp.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
      AND    rsl.shipment_header_id  = itp.doc_id
      AND    rsl.line_num            = itp.doc_line
      AND    rsl.oe_order_header_id  = xoha.header_id
      AND    rsl.oe_order_line_id    = xola.line_id
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    otta.attribute4         = '2'
      AND    xoha.header_id          = ooha.header_id
      AND    xola.order_header_id    = xoha.order_header_id
      AND    xrpm.doc_type           = itp.doc_type
      AND    xrpm.source_document_code = 'RMA'
      AND    xrpm.dealings_div       IN ('504','509')
      AND    xrpm.stock_adjustment_div = otta.attribute4
      AND    xrpm.ship_prov_rcv_pay_category = otta.attribute11
      AND    xrpm.break_col_01       IS NOT NULL
      AND   iwm.whse_code            = itp.whse_code
-- 2009/03/05 v1.31 ADD START
      AND    iwm.attribute1          = '0'
-- 2009/03/05 v1.31 ADD END
      UNION ALL
      SELECT /*+ leading (itp gic1 mcb1 gic2 mcb2) use_nl (itp gic1 mcb1 gic2 mcb2) */
             iwm.whse_code                        h_whse_code
            ,iwm.whse_name                        h_whse_name
-- v1.33 Mod Start
--            ,itp.trans_id                         trans_id
            ,NULL                                 trans_id
-- v1.33 Mod End
            ,iimb.attribute15                     cost_mng_clss
            ,iimb.lot_ctl                         lot_ctl
            ,xlc.unit_ploce                       actual_unit_price
            ,CASE WHEN INSTR(xrpm.break_col_01,gv_hifn) = 0
                       THEN ''
                  WHEN xrpm.rcv_pay_div = gc_rcv_pay_div_in
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  ELSE SUBSTR(xrpm.break_col_01,INSTR(xrpm.break_col_01,gv_hifn) +1)
             END                                  column_no
            ,itp.reason_code                      reason_code
            ,itp.trans_date                       trans_date
            ,TO_CHAR(itp.trans_date, 'YYYYMM')  trans_ym
            ,CASE WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN TO_CHAR(ABS(TO_NUMBER(xrpm.rcv_pay_div)))
                  ELSE xrpm.rcv_pay_div
             END                                  rcv_pay_div
            ,xrpm.dealings_div                    dealings_div
            ,itp.doc_type                         doc_type
            ,ir_param.item_class                  item_div
            ,ir_param.goods_class                 prod_div
            ,mcb3.segment1                        crowd_code
            ,SUBSTR(mcb3.segment1, 1, 3)          crowd_low
            ,SUBSTR(mcb3.segment1, 1, 2)          crowd_mid
            ,SUBSTR(mcb3.segment1, 1, 1)          crowd_high
            ,itp.item_id                          item_id
            ,itp.lot_id                           lot_id
-- v1.33 Mod Start
--            ,NVL(itp.trans_qty, 0)                trans_qty
            ,SUM(NVL(itp.trans_qty, 0))           trans_qty
-- v1.33 Mod End
            ,itp.trans_date                       arrival_date
            ,TO_CHAR(itp.trans_date, gc_char_ym_format) arrival_ym
            ,iimb.item_no                         item_code
            ,ximb.item_short_name                 item_name
      FROM   ic_tran_pnd                      itp
            ,ic_item_mst_b                    iimb
            ,xxcmn_item_mst_b                 ximb
            ,ic_lots_mst                      ilm
            ,xxcmn_lot_cost                   xlc
            ,gmi_item_categories              gic1
            ,mtl_categories_b                 mcb1
            ,gmi_item_categories              gic2
            ,mtl_categories_b                 mcb2
            ,gmi_item_categories              gic3
            ,mtl_categories_b                 mcb3
            ,rcv_shipment_lines               rsl
            ,rcv_transactions                 rt
            ,xxcmn_rcv_pay_mst                xrpm
            ,ic_whse_mst                      iwm
      WHERE  itp.doc_type            = gv_doc_type_porc
      AND    itp.completed_ind       = 1
      AND    itp.trans_date > FND_DATE.STRING_TO_DATE(gd_prv1_dt_chr,gc_char_dt_format)
      AND    itp.trans_date < FND_DATE.STRING_TO_DATE(gd_flw_dt_chr,gc_char_dt_format)
      AND    ilm.item_id             = itp.item_id
      AND    ilm.lot_id              = itp.lot_id
      AND    iimb.item_id            = ilm.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(itp.trans_date)
      AND    ximb.end_date_active   >= TRUNC(itp.trans_date)
      AND    gic1.item_id            = itp.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = itp.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    gic3.item_id            = itp.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
      AND    rsl.shipment_header_id  = itp.doc_id
      AND    rsl.line_num            = itp.doc_line
      AND    rt.transaction_id       = itp.line_id
      AND    rt.shipment_line_id     = rsl.shipment_line_id
      AND    xrpm.doc_type           = itp.doc_type
      AND    xrpm.source_document_code = rsl.source_document_code
      AND    xrpm.transaction_type   = rt.transaction_type
      AND    xrpm.break_col_01       IS NOT NULL
      AND   iwm.whse_code            = itp.whse_code
-- 2009/03/05 v1.31 ADD START
      AND    iwm.attribute1          = '0'
-- 2009/03/05 v1.31 ADD END
-- v1.33 Add Start
      GROUP BY
             iwm.whse_code                        -- h_whse_code
            ,iwm.whse_name                        -- h_whse_name
            ,iimb.attribute15                     -- cost_mng_clss
            ,iimb.lot_ctl                         -- lot_ctl
            ,xlc.unit_ploce                       -- actual_unit_price
            ,CASE WHEN INSTR(xrpm.break_col_01,gv_hifn) = 0
                       THEN ''
                  WHEN xrpm.rcv_pay_div = gc_rcv_pay_div_in
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  ELSE SUBSTR(xrpm.break_col_01,INSTR(xrpm.break_col_01,gv_hifn) +1)
             END                                  -- column_no
            ,itp.reason_code                      -- reason_code
            ,itp.trans_date                       -- trans_date
            ,TO_CHAR(itp.trans_date, 'YYYYMM')    -- trans_ym
            ,CASE WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN TO_CHAR(ABS(TO_NUMBER(xrpm.rcv_pay_div)))
                  ELSE xrpm.rcv_pay_div
             END                                  -- rcv_pay_div
            ,xrpm.dealings_div                    -- dealings_div
            ,itp.doc_type                         -- doc_type
            ,ir_param.item_class                  -- item_div
            ,ir_param.goods_class                 -- prod_div
            ,mcb3.segment1                        -- crowd_code
            ,SUBSTR(mcb3.segment1, 1, 3)          -- crowd_low
            ,SUBSTR(mcb3.segment1, 1, 2)          -- crowd_mid
            ,SUBSTR(mcb3.segment1, 1, 1)          -- crowd_high
            ,itp.item_id                          -- item_id
            ,itp.lot_id                           -- lot_id
            ,itp.trans_date                       -- arrival_date
            ,TO_CHAR(itp.trans_date, gc_char_ym_format) -- arrival_ym
            ,iimb.item_no                         -- item_code
            ,ximb.item_short_name                 -- item_name
            ,rsl.attribute1                       -- 受入返品実績アドオン.取引ID
-- v1.33 Add End
      UNION ALL
      SELECT /*+ leading (xoha xola wdd itp gic1 mcb1 gic2 mcb2 ooha otta) use_nl (xoha xola wdd itp gic1 mcb1 gic2 mcb2 ooha otta) */
             iwm.whse_code                        h_whse_code
            ,iwm.whse_name                        h_whse_name
            ,itp.trans_id                         trans_id
            ,iimb.attribute15                     cost_mng_clss
            ,iimb.lot_ctl                         lot_ctl
            ,xlc.unit_ploce                       actual_unit_price
            ,CASE WHEN INSTR(xrpm.break_col_01,gv_hifn) = 0
                       THEN ''
                  WHEN xrpm.rcv_pay_div = gc_rcv_pay_div_in
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  ELSE SUBSTR(xrpm.break_col_01,INSTR(xrpm.break_col_01,gv_hifn) +1)
             END                                  column_no
            ,itp.reason_code                      reason_code
            ,itp.trans_date                       trans_date
            ,TO_CHAR(itp.trans_date, 'YYYYMM')  trans_ym
            ,CASE WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN TO_CHAR(ABS(TO_NUMBER(xrpm.rcv_pay_div)))
                  ELSE xrpm.rcv_pay_div
             END                                  rcv_pay_div
            ,xrpm.dealings_div                    dealings_div
            ,itp.doc_type                         doc_type
            ,ir_param.item_class                  item_div
            ,ir_param.goods_class                 prod_div
            ,mcb3.segment1                        crowd_code
            ,SUBSTR(mcb3.segment1, 1, 3)          crowd_low
            ,SUBSTR(mcb3.segment1, 1, 2)          crowd_mid
            ,SUBSTR(mcb3.segment1, 1, 1)          crowd_high
            ,itp.item_id                          item_id
            ,itp.lot_id                           lot_id
            ,NVL(itp.trans_qty, 0)                trans_qty
            ,xoha.arrival_date                    arrival_date
            ,TO_CHAR(xoha.arrival_date, gc_char_ym_format) arrival_ym
            ,iimb.item_no                         item_code
            ,ximb.item_short_name                 item_name
      FROM   ic_tran_pnd                      itp
            ,wsh_delivery_details             wdd
            ,oe_order_headers_all             ooha
            ,oe_transaction_types_all         otta
            ,xxwsh_order_headers_all          xoha
            ,xxwsh_order_lines_all            xola
            ,ic_item_mst_b                    iimb
            ,xxcmn_item_mst_b                 ximb
            ,ic_lots_mst                      ilm
            ,xxcmn_lot_cost                   xlc
            ,gmi_item_categories              gic1
            ,mtl_categories_b                 mcb1
            ,gmi_item_categories              gic2
            ,mtl_categories_b                 mcb2
            ,gmi_item_categories              gic3
            ,mtl_categories_b                 mcb3
            ,xxcmn_rcv_pay_mst                xrpm
            ,ic_whse_mst                      iwm
      WHERE  itp.doc_type            = gv_doc_type_omso
      AND    itp.completed_ind       = 1
      AND    xoha.latest_external_flag = 'Y'
      AND    xoha.arrival_date > FND_DATE.STRING_TO_DATE(gd_prv2_dt_chr,gc_char_dt_format)
      AND    xoha.arrival_date < FND_DATE.STRING_TO_DATE(gd_flw_dt_chr,gc_char_dt_format)
      AND    xoha.req_status         IN ('04','08')
      AND    ilm.item_id             = itp.item_id
      AND    ilm.lot_id              = itp.lot_id
      AND    iimb.item_id            = ilm.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(itp.trans_date)
      AND    ximb.end_date_active   >= TRUNC(itp.trans_date)
      AND    gic1.item_id            = itp.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = itp.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    gic3.item_id            = itp.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
      AND    wdd.delivery_detail_id  = itp.line_detail_id
      AND    wdd.source_header_id    = xoha.header_id
      AND    wdd.source_line_id      = xola.line_id
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    ((otta.attribute4           <> '2')
             OR  (otta.attribute4       IS NULL))
      AND    otta.attribute1         IN ('1','2')
      AND    xoha.header_id          = ooha.header_id
      AND    xola.order_header_id    = xoha.order_header_id
      AND    xola.request_item_code  = xola.shipping_item_code
      AND    xrpm.doc_type           = itp.doc_type
      AND    xrpm.dealings_div       IN ('101','103')
      AND    xrpm.shipment_provision_div = DECODE(xoha.req_status,'04','1','08','2')
      AND    xrpm.shipment_provision_div = otta.attribute1
      AND    ((xrpm.ship_prov_rcv_pay_category IS NULL)
             OR (xrpm.ship_prov_rcv_pay_category = otta.attribute11))
      AND    xrpm.break_col_01       IS NOT NULL
      AND    xrpm.item_div_origin    IS NULL
      AND    xrpm.item_div_ahead     IS NULL
      AND   iwm.whse_code            = itp.whse_code
-- 2009/03/05 v1.31 ADD START
      AND    iwm.attribute1          = '0'
-- 2009/03/05 v1.31 ADD END
      UNION ALL
      SELECT /*+ leading (xoha xola wdd itp gic1 mcb1 gic2 mcb2 ooha otta xrpm) use_nl (xoha xola wdd itp gic1 mcb1 gic2 mcb2 ooha otta xrpm) */
             iwm.whse_code                        h_whse_code
            ,iwm.whse_name                        h_whse_name
            ,itp.trans_id                         trans_id
            ,iimb.attribute15                     cost_mng_clss
            ,iimb.lot_ctl                         lot_ctl
            ,xlc.unit_ploce                       actual_unit_price
            ,CASE WHEN INSTR(xrpm.break_col_01,gv_hifn) = 0
                       THEN ''
                  WHEN xrpm.rcv_pay_div = gc_rcv_pay_div_in
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  ELSE SUBSTR(xrpm.break_col_01,INSTR(xrpm.break_col_01,gv_hifn) +1)
             END                                  column_no
            ,itp.reason_code                      reason_code
            ,itp.trans_date                       trans_date
            ,TO_CHAR(itp.trans_date, 'YYYYMM')  trans_ym
            ,CASE WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN TO_CHAR(ABS(TO_NUMBER(xrpm.rcv_pay_div)))
                  ELSE xrpm.rcv_pay_div
             END                                  rcv_pay_div
            ,xrpm.dealings_div                    dealings_div
            ,itp.doc_type                         doc_type
            ,ir_param.item_class                  item_div
            ,ir_param.goods_class                 prod_div
            ,mcb3.segment1                        crowd_code
            ,SUBSTR(mcb3.segment1, 1, 3)          crowd_low
            ,SUBSTR(mcb3.segment1, 1, 2)          crowd_mid
            ,SUBSTR(mcb3.segment1, 1, 1)          crowd_high
            ,iimb.item_id                         item_id
            ,itp.lot_id                           lot_id
            ,NVL(itp.trans_qty, 0)                trans_qty
            ,xoha.arrival_date                    arrival_date
            ,TO_CHAR(xoha.arrival_date, gc_char_ym_format) arrival_ym
            ,iimb.item_no                         item_code
            ,ximb.item_short_name                 item_name
      FROM   ic_tran_pnd                      itp
            ,wsh_delivery_details             wdd
            ,oe_order_headers_all             ooha
            ,oe_transaction_types_all         otta
            ,xxwsh_order_headers_all          xoha
            ,xxwsh_order_lines_all            xola
            ,ic_item_mst_b                    iimb
            ,ic_item_mst_b                    iimb2
            ,xxcmn_item_mst_b                 ximb
            ,ic_lots_mst                      ilm
            ,xxcmn_lot_cost                   xlc
            ,gmi_item_categories              gic1
            ,mtl_categories_b                 mcb1
            ,gmi_item_categories              gic2
            ,mtl_categories_b                 mcb2
            ,gmi_item_categories              gic3
            ,mtl_categories_b                 mcb3
            ,gmi_item_categories              gic4
            ,mtl_categories_b                 mcb4
            ,xxcmn_rcv_pay_mst                xrpm
            ,ic_whse_mst                      iwm
      WHERE  itp.doc_type            = gv_doc_type_omso
      AND    itp.completed_ind       = 1
      AND    xoha.latest_external_flag = 'Y'
      AND    xoha.arrival_date > FND_DATE.STRING_TO_DATE(gd_prv2_dt_chr,gc_char_dt_format)
      AND    xoha.arrival_date < FND_DATE.STRING_TO_DATE(gd_flw_dt_chr,gc_char_dt_format)
      AND    xoha.req_status         = '08'
      AND    ilm.item_id             = itp.item_id
      AND    ilm.lot_id              = itp.lot_id
      AND    iimb.item_id            = itp.item_id
      AND    iimb2.item_no           = xola.request_item_code
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(itp.trans_date)
      AND    ximb.end_date_active   >= TRUNC(itp.trans_date)
      AND    gic1.item_id            = itp.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = itp.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    gic3.item_id            = itp.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
      AND    gic4.item_id            = iimb2.item_id
      AND    gic4.category_set_id    = cn_item_class_id
      AND    gic4.category_id        = mcb4.category_id
      AND    wdd.delivery_detail_id  = itp.line_detail_id
      AND    wdd.source_header_id    = xoha.header_id
      AND    wdd.source_line_id      = xola.line_id
      AND    xola.order_header_id    = xoha.order_header_id
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    ((otta.attribute4           <> '2')
             OR  (otta.attribute4       IS NULL))
      AND    otta.attribute1         = '2'
      AND    xoha.header_id          = ooha.header_id
      AND    xrpm.doc_type           = itp.doc_type
      AND    xrpm.dealings_div       = '106'
      AND    xrpm.shipment_provision_div = DECODE(xoha.req_status,'04','1','08','2')
      AND    xrpm.shipment_provision_div = otta.attribute1
      AND    xrpm.ship_prov_rcv_pay_category = otta.attribute11
      AND    xrpm.item_div_ahead     = mcb4.segment1
      AND    mcb2.segment1           <> '5'
      AND    xrpm.break_col_01       IS NOT NULL
      AND   iwm.whse_code            = itp.whse_code
-- 2009/03/05 v1.31 ADD START
      AND    iwm.attribute1          = '0'
-- 2009/03/05 v1.31 ADD END
      UNION ALL
      SELECT /*+ leading (xoha xola wdd itp gic1 mcb1 gic2 mcb2 ooha otta xrpm) use_nl (xoha xola wdd itp gic1 mcb1 gic2 mcb2 ooha otta xrpm) */
             iwm.whse_code                        h_whse_code
            ,iwm.whse_name                        h_whse_name
            ,itp.trans_id                         trans_id
            ,iimb.attribute15                     cost_mng_clss
            ,iimb.lot_ctl                         lot_ctl
            ,xlc.unit_ploce                       actual_unit_price
            ,CASE WHEN INSTR(xrpm.break_col_01,gv_hifn) = 0
                       THEN ''
                  WHEN xrpm.rcv_pay_div = gc_rcv_pay_div_in
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  ELSE SUBSTR(xrpm.break_col_01,INSTR(xrpm.break_col_01,gv_hifn) +1)
             END                                  column_no
            ,itp.reason_code                      reason_code
            ,itp.trans_date                       trans_date
            ,TO_CHAR(itp.trans_date, 'YYYYMM')  trans_ym
            ,CASE WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN TO_CHAR(ABS(TO_NUMBER(xrpm.rcv_pay_div)))
                  ELSE xrpm.rcv_pay_div
             END                                  rcv_pay_div
            ,xrpm.dealings_div                    dealings_div
            ,itp.doc_type                         doc_type
            ,ir_param.item_class                  item_div
            ,ir_param.goods_class                 prod_div
            ,mcb3.segment1                        crowd_code
            ,SUBSTR(mcb3.segment1, 1, 3)          crowd_low
            ,SUBSTR(mcb3.segment1, 1, 2)          crowd_mid
            ,SUBSTR(mcb3.segment1, 1, 1)          crowd_high
            ,iimb.item_id                         item_id
            ,itp.lot_id                           lot_id
            ,NVL(itp.trans_qty, 0)                trans_qty
            ,xoha.arrival_date                    arrival_date
            ,TO_CHAR(xoha.arrival_date, gc_char_ym_format) arrival_ym
            ,iimb.item_no                         item_code
            ,ximb.item_short_name                 item_name
      FROM   ic_tran_pnd                      itp
            ,wsh_delivery_details             wdd
            ,oe_order_headers_all             ooha
            ,oe_transaction_types_all         otta
            ,xxwsh_order_headers_all          xoha
            ,xxwsh_order_lines_all            xola
            ,ic_item_mst_b                    iimb
            ,ic_item_mst_b                    iimb2
            ,xxcmn_item_mst_b                 ximb
            ,ic_lots_mst                      ilm
            ,xxcmn_lot_cost                   xlc
            ,gmi_item_categories              gic1
            ,mtl_categories_b                 mcb1
            ,gmi_item_categories              gic2
            ,mtl_categories_b                 mcb2
            ,gmi_item_categories              gic3
            ,mtl_categories_b                 mcb3
            ,gmi_item_categories              gic4
            ,mtl_categories_b                 mcb4
            ,xxcmn_rcv_pay_mst                xrpm
            ,ic_whse_mst                      iwm
      WHERE  itp.doc_type            = gv_doc_type_omso
      AND    itp.completed_ind       = 1
      AND    xoha.latest_external_flag = 'Y'
      AND    xoha.arrival_date > FND_DATE.STRING_TO_DATE(gd_prv2_dt_chr,gc_char_dt_format)
      AND    xoha.arrival_date < FND_DATE.STRING_TO_DATE(gd_flw_dt_chr,gc_char_dt_format)
      AND    xoha.req_status         = '04'
      AND    ilm.item_id             = itp.item_id
      AND    ilm.lot_id              = itp.lot_id
      AND    iimb.item_id            = itp.item_id
      AND    iimb2.item_no           = xola.request_item_code
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(itp.trans_date)
      AND    ximb.end_date_active   >= TRUNC(itp.trans_date)
      AND    gic1.item_id            = itp.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = itp.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    gic3.item_id            = itp.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
      AND    gic4.item_id            = iimb2.item_id
      AND    gic4.category_set_id    = cn_item_class_id
      AND    gic4.category_id        = mcb4.category_id
      AND    wdd.delivery_detail_id  = itp.line_detail_id
      AND    wdd.source_header_id    = xoha.header_id
      AND    wdd.source_line_id      = xola.line_id
      AND    xola.order_header_id    = xoha.order_header_id
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    ((otta.attribute4           <> '2')
             OR  (otta.attribute4       IS NULL))
      AND    otta.attribute1         = '1'
      AND    xoha.header_id          = ooha.header_id
      AND    xrpm.doc_type           = itp.doc_type
      AND    xrpm.dealings_div       = '113'
      AND    xrpm.shipment_provision_div = DECODE(xoha.req_status,'04','1','08','2')
      AND    xrpm.item_div_ahead     = mcb4.segment1
      AND    mcb2.segment1           <> '5'
      AND    xrpm.break_col_01       IS NOT NULL
      AND   iwm.whse_code            = itp.whse_code
-- 2009/03/05 v1.31 ADD START
      AND    iwm.attribute1          = '0'
-- 2009/03/05 v1.31 ADD END
      UNION ALL
      SELECT /*+ leading (xoha ooha otta xola wdd itp gic1 mcb1 gic2 mcb2) use_nl (xoha ooha otta xola wdd itp gic1 mcb1 gic2 mcb2) */
             iwm.whse_code                        h_whse_code
            ,iwm.whse_name                        h_whse_name
            ,itp.trans_id                         trans_id
            ,iimb.attribute15                     cost_mng_clss
            ,iimb.lot_ctl                         lot_ctl
            ,xlc.unit_ploce                       actual_unit_price
            ,CASE WHEN INSTR(xrpm.break_col_01,gv_hifn) = 0
                       THEN ''
                  WHEN xrpm.rcv_pay_div = gc_rcv_pay_div_in
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  ELSE SUBSTR(xrpm.break_col_01,INSTR(xrpm.break_col_01,gv_hifn) +1)
             END                                  column_no
            ,itp.reason_code                      reason_code
            ,itp.trans_date                       trans_date
            ,TO_CHAR(itp.trans_date, 'YYYYMM')  trans_ym
            ,CASE WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN TO_CHAR(ABS(TO_NUMBER(xrpm.rcv_pay_div)))
                  ELSE xrpm.rcv_pay_div
             END                                  rcv_pay_div
            ,xrpm.dealings_div                    dealings_div
            ,itp.doc_type                         doc_type
            ,ir_param.item_class                  item_div
            ,ir_param.goods_class                 prod_div
            ,mcb3.segment1                        crowd_code
            ,SUBSTR(mcb3.segment1, 1, 3)          crowd_low
            ,SUBSTR(mcb3.segment1, 1, 2)          crowd_mid
            ,SUBSTR(mcb3.segment1, 1, 1)          crowd_high
            ,itp.item_id                          item_id
            ,itp.lot_id                           lot_id
            ,NVL(itp.trans_qty, 0)                trans_qty
            ,xoha.arrival_date                    arrival_date
            ,TO_CHAR(xoha.arrival_date, gc_char_ym_format) arrival_ym
            ,iimb.item_no                         item_code
            ,ximb.item_short_name                 item_name
      FROM   ic_tran_pnd                      itp
            ,wsh_delivery_details             wdd
            ,oe_order_headers_all             ooha
            ,oe_transaction_types_all         otta
            ,xxwsh_order_headers_all          xoha
            ,xxwsh_order_lines_all            xola
            ,ic_item_mst_b                    iimb
            ,xxcmn_item_mst_b                 ximb
            ,ic_lots_mst                      ilm
            ,xxcmn_lot_cost                   xlc
            ,gmi_item_categories              gic1
            ,mtl_categories_b                 mcb1
            ,gmi_item_categories              gic2
            ,mtl_categories_b                 mcb2
            ,gmi_item_categories              gic3
            ,mtl_categories_b                 mcb3
            ,xxcmn_rcv_pay_mst                xrpm
            ,ic_whse_mst                      iwm
      WHERE  itp.doc_type            = gv_doc_type_omso
      AND    itp.completed_ind       = 1
      AND    xoha.latest_external_flag = 'Y'
      AND    xoha.arrival_date > FND_DATE.STRING_TO_DATE(gd_prv2_dt_chr,gc_char_dt_format)
      AND    xoha.arrival_date < FND_DATE.STRING_TO_DATE(gd_flw_dt_chr,gc_char_dt_format)
      AND    ilm.item_id             = itp.item_id
      AND    ilm.lot_id              = itp.lot_id
      AND    iimb.item_id            = itp.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(itp.trans_date)
      AND    ximb.end_date_active   >= TRUNC(itp.trans_date)
      AND    gic1.item_id            = itp.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = itp.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    gic3.item_id            = itp.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
      AND    wdd.delivery_detail_id  = itp.line_detail_id
      AND    wdd.source_header_id    = xoha.header_id
      AND    wdd.source_line_id      = xola.line_id
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    otta.attribute4         = '2'
      AND    xoha.header_id          = ooha.header_id
      AND    xola.order_header_id    = xoha.order_header_id
      AND    xrpm.doc_type           = itp.doc_type
      AND    xrpm.dealings_div       IN ('504','509')
      AND    xrpm.stock_adjustment_div = otta.attribute4
      AND    xrpm.ship_prov_rcv_pay_category = otta.attribute11
      AND    xrpm.break_col_01       IS NOT NULL
      AND   iwm.whse_code            = itp.whse_code
-- 2009/03/05 v1.31 ADD START
      AND    iwm.attribute1          = '0'
-- 2009/03/05 v1.31 ADD END
      -- 当月受払無しデータ
      UNION ALL
      SELECT /*+ leading (xsims gic1 mcb1 gic2 mcb2 gic3 mcb3 iimb ximb xlc) use_nl (xsims gic1 mcb1 gic2 mcb2 gic3 mcb3 iimb ximb xlc) */
             iwm.whse_code                        h_whse_code
            ,iwm.whse_name                        h_whse_name
            ,NULL                                 trans_id
            ,iimb.attribute15                     cost_mng_clss
            ,iimb.lot_ctl                         lot_ctl
            ,xlc.unit_ploce                       actual_unit_price
            ,'1'                                  column_no
            ,NULL                                 reason_code
            ,gd_s_date                            trans_date
            ,TO_CHAR(gd_s_date, gc_char_ym_format)  trans_ym
            ,'1'                                  rcv_pay_div
            ,NULL                                 dealings_div
            ,NULL                                 doc_type
            ,ir_param.item_class                  item_div
            ,ir_param.goods_class                 prod_div
            ,mcb3.segment1                        crowd_code
            ,SUBSTR(mcb3.segment1, 1, 3)          crowd_low
            ,SUBSTR(mcb3.segment1, 1, 2)          crowd_mid
            ,SUBSTR(mcb3.segment1, 1, 1)          crowd_high
            ,iimb.item_id                         item_id
            ,0                                    lot_id
            ,0                                    trans_qty
            ,gd_s_date                            arrival_date
            ,TO_CHAR(gd_s_date, gc_char_ym_format)  arrival_ym
            ,iimb.item_no                         item_code
            ,ximb.item_short_name                 item_name
      FROM   xxinv_stc_inventory_month_stck   xsims
            ,ic_item_mst_b                    iimb
            ,xxcmn_item_mst_b                 ximb
            ,ic_lots_mst                      ilm
            ,xxcmn_lot_cost                   xlc
            ,gmi_item_categories              gic1
            ,mtl_categories_b                 mcb1
            ,gmi_item_categories              gic2
            ,mtl_categories_b                 mcb2
            ,gmi_item_categories              gic3
            ,mtl_categories_b                 mcb3
            ,ic_whse_mst                      iwm
      WHERE  xsims.item_id           = iimb.item_id
      AND    ximb.item_id            = iimb.item_id
      AND    ilm.item_id             = xsims.item_id
      AND    ilm.lot_id              = xsims.lot_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.start_date_active <= gd_s_date
      AND    ximb.end_date_active   >= gd_s_date
      AND    gic1.item_id            = xsims.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = xsims.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    gic3.item_id            = xsims.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
      AND    iwm.whse_code           = xsims.whse_code
      AND    xsims.invent_ym         = TO_CHAR(gd_s_date, gc_char_ym_format)
-- 2008/12/10 v1.25 UPDATE START
--      AND    xsims.monthly_stock    <> 0
      AND    (
               (xsims.monthly_stock <> 0)
               OR
               (xsims.cargo_stock   <> 0)
             )
      AND    iwm.attribute1          = '0'
-- 2008/12/10 v1.25 UPDATE END
      ORDER BY h_whse_code
              ,crowd_code
              ,item_code
      ;
--
    --===============================================================
    -- 検索条件.帳票種別          ⇒ 倉庫・品目別
    -- 検索条件.群種別            ⇒ 群別
    -- 検索条件.倉庫コード        ⇒ 入力あり
    -- 検索条件.群コード          ⇒ 入力あり
    -- 検索条件.経理群コード      ⇒ 入力なし/入力あり
    --===============================================================
    CURSOR get_data_cur03 IS
      SELECT /*+ leading (xmrh xmril ixm itp gic2 mcb2 gic1 mcb1 iimb ximb) use_nl (xmrh xmril ixm itp gic2 mcb2 gic1 mcb1 iimb ximb) */
             iwm.whse_code                        h_whse_code
            ,iwm.whse_name                        h_whse_name
            ,itp.trans_id                         trans_id
            ,iimb.attribute15                     cost_mng_clss
            ,iimb.lot_ctl                         lot_ctl
            ,xlc.unit_ploce                       actual_unit_price
            ,CASE WHEN INSTR(xrpm.break_col_01,gv_hifn) = 0
                       THEN ''
                  WHEN xrpm.rcv_pay_div = gc_rcv_pay_div_in
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  ELSE SUBSTR(xrpm.break_col_01,INSTR(xrpm.break_col_01,gv_hifn) +1)
             END                                  column_no
            ,itp.reason_code                      reason_code
            ,itp.trans_date                       trans_date
            ,TO_CHAR(itp.trans_date, 'YYYYMM')  trans_ym
            ,CASE WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN TO_CHAR(ABS(TO_NUMBER(xrpm.rcv_pay_div)))
                  ELSE xrpm.rcv_pay_div
             END                                  rcv_pay_div
            ,xrpm.dealings_div                    dealings_div
            ,itp.doc_type                         doc_type
            ,ir_param.item_class                  item_div
            ,ir_param.goods_class                 prod_div
            ,mcb3.segment1                        crowd_code
            ,SUBSTR(mcb3.segment1, 1, 3)          crowd_low
            ,SUBSTR(mcb3.segment1, 1, 2)          crowd_mid
            ,SUBSTR(mcb3.segment1, 1, 1)          crowd_high
            ,itp.item_id                          item_id
            ,itp.lot_id                           lot_id
            ,NVL(itp.trans_qty, 0)                trans_qty
            ,xmrh.actual_arrival_date             arrival_date
            ,TO_CHAR(xmrh.actual_arrival_date, gc_char_ym_format) arrival_ym
            ,iimb.item_no                         item_code
            ,ximb.item_short_name                 item_name
      FROM   ic_tran_pnd                      itp
            ,ic_xfer_mst                      ixm
            ,xxinv_mov_req_instr_headers      xmrh
            ,xxinv_mov_req_instr_lines        xmril
            ,ic_item_mst_b                    iimb
            ,xxcmn_item_mst_b                 ximb
            ,ic_lots_mst                      ilm
            ,xxcmn_lot_cost                   xlc
            ,gmi_item_categories              gic1
            ,mtl_categories_b                 mcb1
            ,gmi_item_categories              gic2
            ,mtl_categories_b                 mcb2
            ,gmi_item_categories              gic3
            ,mtl_categories_b                 mcb3
            ,xxcmn_rcv_pay_mst                xrpm
            ,ic_whse_mst                      iwm
      WHERE  itp.doc_type            = gv_doc_type_xfer
      AND    itp.reason_code         = gv_reason_code_xfer
      AND    itp.completed_ind       = 1
      AND    xmrh.actual_arrival_date > FND_DATE.STRING_TO_DATE(gd_prv1_dt_chr,gc_char_dt_format)
      AND    xmrh.actual_arrival_date < FND_DATE.STRING_TO_DATE(gd_flw_dt_chr,gc_char_dt_format)
      AND    xmrh.mov_hdr_id         = xmril.mov_hdr_id
      AND    itp.doc_id              = ixm.transfer_id
      AND    ixm.attribute1          = TO_CHAR(xmril.mov_line_id)
      AND    ilm.item_id             = itp.item_id
      AND    ilm.lot_id              = itp.lot_id
      AND    iimb.item_id            = itp.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(itp.trans_date)
      AND    ximb.end_date_active   >= TRUNC(itp.trans_date)
      AND    gic1.item_id            = itp.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = itp.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    gic3.item_id            = itp.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
      AND    xrpm.rcv_pay_div        = CASE
                                       WHEN itp.trans_qty >= 0 THEN 1
                                       ELSE -1
                                       END
      AND    xrpm.doc_type           = itp.doc_type
      AND    xrpm.reason_code        = itp.reason_code
      AND    xrpm.break_col_01       IS NOT NULL
      AND    iwm.whse_code           = itp.whse_code
      AND    iwm.whse_code           = ir_param.locat_code
      AND    mcb3.segment1           = lt_crowd_code
-- 2009/03/05 v1.31 ADD START
      AND    iwm.attribute1          = '0'
-- 2009/03/05 v1.31 ADD END
      UNION ALL
      SELECT /*+ leading (xmrh xmril ijm iaj itc gic2 mcb2 gic1 mcb1 ilm iimb ximb) use_nl (xmrh xmril ijm iaj itc gic2 mcb2 gic1 mcb1 ilm iimb ximb) */
             iwm.whse_code                        h_whse_code
            ,iwm.whse_name                        h_whse_name
            ,itc.trans_id                         trans_id
            ,iimb.attribute15                     cost_mng_clss
            ,iimb.lot_ctl                         lot_ctl
            ,xlc.unit_ploce                       actual_unit_price
            ,CASE WHEN INSTR(xrpm.break_col_01,gv_hifn) = 0
                       THEN ''
                  WHEN xrpm.rcv_pay_div = gc_rcv_pay_div_in
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  ELSE SUBSTR(xrpm.break_col_01,INSTR(xrpm.break_col_01,gv_hifn) +1)
             END                                  column_no
            ,itc.reason_code                      reason_code
            ,itc.trans_date                       trans_date
            ,TO_CHAR(itc.trans_date, 'YYYYMM')  trans_ym
            ,CASE WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN TO_CHAR(ABS(TO_NUMBER(xrpm.rcv_pay_div)))
                  ELSE xrpm.rcv_pay_div
             END                                  rcv_pay_div
            ,xrpm.dealings_div                    dealings_div
            ,itc.doc_type                         doc_type
            ,ir_param.item_class                  item_div
            ,ir_param.goods_class                 prod_div
            ,mcb3.segment1                        crowd_code
            ,SUBSTR(mcb3.segment1, 1, 3)          crowd_low
            ,SUBSTR(mcb3.segment1, 1, 2)          crowd_mid
            ,SUBSTR(mcb3.segment1, 1, 1)          crowd_high
            ,itc.item_id                          item_id
            ,itc.lot_id                           lot_id
            ,NVL(itc.trans_qty, 0)                trans_qty
            ,xmrh.actual_arrival_date             arrival_date
            ,TO_CHAR(xmrh.actual_arrival_date, gc_char_ym_format) arrival_ym
            ,iimb.item_no                         item_code
            ,ximb.item_short_name                 item_name
      FROM   ic_tran_cmp                      itc
            ,ic_adjs_jnl                      iaj
            ,ic_jrnl_mst                      ijm
            ,xxinv_mov_req_instr_headers      xmrh
            ,xxinv_mov_req_instr_lines        xmril
            ,ic_item_mst_b                    iimb
            ,xxcmn_item_mst_b                 ximb
            ,ic_lots_mst                      ilm
            ,xxcmn_lot_cost                   xlc
            ,gmi_item_categories              gic1
            ,mtl_categories_b                 mcb1
            ,gmi_item_categories              gic2
            ,mtl_categories_b                 mcb2
            ,gmi_item_categories              gic3
            ,mtl_categories_b                 mcb3
            ,xxcmn_rcv_pay_mst                xrpm
            ,ic_whse_mst                      iwm
      WHERE  itc.doc_type            = gv_doc_type_trni
      AND    itc.reason_code         = gv_reason_code_trni
      AND    xmrh.actual_arrival_date > FND_DATE.STRING_TO_DATE(gd_prv1_dt_chr,gc_char_dt_format)
      AND    xmrh.actual_arrival_date < FND_DATE.STRING_TO_DATE(gd_flw_dt_chr,gc_char_dt_format)
      AND    xmrh.mov_hdr_id         = xmril.mov_hdr_id
      AND    itc.doc_type            = iaj.trans_type
      AND    itc.doc_id              = iaj.doc_id
      AND    itc.doc_line            = iaj.doc_line
      AND    ijm.journal_id          = iaj.journal_id
      AND    ijm.attribute1          = TO_CHAR(xmril.mov_line_id)
      AND    ilm.item_id             = itc.item_id
      AND    ilm.lot_id              = itc.lot_id
      AND    iimb.item_id            = ilm.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(itc.trans_date)
      AND    ximb.end_date_active   >= TRUNC(itc.trans_date)
      AND    gic1.item_id            = itc.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = itc.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    gic3.item_id            = itc.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
-- 2008/11/19 v1.18 ADD START
      AND    xrpm.rcv_pay_div        = CASE
                                       WHEN itc.trans_qty >= 0 THEN 1
                                       ELSE -1
                                       END
-- 2008/11/19 v1.18 ADD END
      AND    xrpm.doc_type           = itc.doc_type
      AND    xrpm.reason_code        = itc.reason_code
      AND    xrpm.rcv_pay_div        = itc.line_type
      AND    xrpm.break_col_01       IS NOT NULL
      AND    iwm.whse_code           = itc.whse_code
      AND    iwm.whse_code           = ir_param.locat_code
      AND    mcb3.segment1           = lt_crowd_code
-- 2009/03/05 v1.31 ADD START
      AND    iwm.attribute1          = '0'
-- 2009/03/05 v1.31 ADD END
      UNION ALL
      SELECT /*+ leading (itc gic1 mcb1 gic2 mcb2) use_nl (itc gic1 mcb1 gic2 mcb2)*/
             iwm.whse_code                        h_whse_code
            ,iwm.whse_name                        h_whse_name
            ,itc.trans_id                         trans_id
            ,iimb.attribute15                     cost_mng_clss
            ,iimb.lot_ctl                         lot_ctl
            ,xlc.unit_ploce                       actual_unit_price
            ,CASE WHEN INSTR(xrpm.break_col_01,gv_hifn) = 0
                       THEN ''
                  WHEN xrpm.rcv_pay_div = gc_rcv_pay_div_in
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  ELSE SUBSTR(xrpm.break_col_01,INSTR(xrpm.break_col_01,gv_hifn) +1)
             END                                  column_no
            ,itc.reason_code                      reason_code
            ,itc.trans_date                       trans_date
            ,TO_CHAR(itc.trans_date, 'YYYYMM')  trans_ym
            ,CASE WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN TO_CHAR(ABS(TO_NUMBER(xrpm.rcv_pay_div)))
                  ELSE xrpm.rcv_pay_div
             END                                  rcv_pay_div
            ,xrpm.dealings_div                    dealings_div
            ,itc.doc_type                         doc_type
            ,ir_param.item_class                  item_div
            ,ir_param.goods_class                 prod_div
            ,mcb3.segment1                        crowd_code
            ,SUBSTR(mcb3.segment1, 1, 3)          crowd_low
            ,SUBSTR(mcb3.segment1, 1, 2)          crowd_mid
            ,SUBSTR(mcb3.segment1, 1, 1)          crowd_high
            ,itc.item_id                          item_id
            ,itc.lot_id                           lot_id
            ,NVL(itc.trans_qty, 0)                trans_qty
            ,itc.trans_date                       arrival_date
            ,TO_CHAR(itc.trans_date, gc_char_ym_format) arrival_ym
            ,iimb.item_no                         item_code
            ,ximb.item_short_name                 item_name
      FROM   ic_tran_cmp                      itc
            ,ic_item_mst_b                    iimb
            ,xxcmn_item_mst_b                 ximb
            ,ic_lots_mst                      ilm
            ,xxcmn_lot_cost                   xlc
            ,gmi_item_categories              gic1
            ,mtl_categories_b                 mcb1
            ,gmi_item_categories              gic2
            ,mtl_categories_b                 mcb2
            ,gmi_item_categories              gic3
            ,mtl_categories_b                 mcb3
            ,xxcmn_rcv_pay_mst                xrpm
            ,ic_whse_mst                      iwm
      WHERE  itc.doc_type            = gv_doc_type_adji    --文書タイプ
      AND    itc.reason_code        IN ('X911'
                                       ,'X912'
                                       ,'X921'
                                       ,'X922'
                                       ,'X931'
                                       ,'X932'
                                       ,'X941'
                                       ,'X952'
                                       ,'X953'
                                       ,'X954'
                                       ,'X955'
                                       ,'X956'
                                       ,'X957'
                                       ,'X958'
                                       ,'X959'
                                       ,'X960'
                                       ,'X961'
                                       ,'X962'
                                       ,'X963'
-- 2008/11/19 v1.18 UPDATE START
--                                       ,'X964')
                                       ,'X964'
                                       ,'X965'
                                       ,'X966')
-- 2008/11/19 v1.18 UPDATE END
      AND    itc.trans_date > FND_DATE.STRING_TO_DATE(gd_prv1_dt_chr,gc_char_dt_format)
      AND    itc.trans_date < FND_DATE.STRING_TO_DATE(gd_flw_dt_chr,gc_char_dt_format)
      AND    ilm.item_id             = itc.item_id
      AND    ilm.lot_id              = itc.lot_id
      AND    iimb.item_id            = ilm.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(itc.trans_date)
      AND    ximb.end_date_active   >= TRUNC(itc.trans_date)
      AND    gic1.item_id            = itc.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = itc.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    gic3.item_id            = itc.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
      AND    xrpm.doc_type           = itc.doc_type
      AND    xrpm.reason_code        = itc.reason_code
      AND    xrpm.break_col_01       IS NOT NULL
      AND    iwm.whse_code           = itc.whse_code
      AND    iwm.whse_code           = ir_param.locat_code
      AND    mcb3.segment1           = lt_crowd_code
-- 2009/03/05 v1.31 ADD START
      AND    iwm.attribute1          = '0'
-- 2009/03/05 v1.31 ADD END
      UNION ALL
      SELECT /*+ leading (itc gic1 mcb1 gic2 mcb2 xrpm) use_nl (itc gic1 mcb1 gic2 mcb2 xrpm) */
             iwm.whse_code                        h_whse_code
            ,iwm.whse_name                        h_whse_name
-- v1.33 Mod Start
--            ,itc.trans_id                         trans_id
            ,NULL                                 trans_id
-- v1.33 Mod End
            ,iimb.attribute15                     cost_mng_clss
            ,iimb.lot_ctl                         lot_ctl
            ,xlc.unit_ploce                       actual_unit_price
            ,CASE WHEN INSTR(xrpm.break_col_01,gv_hifn) = 0
                       THEN ''
                  WHEN xrpm.rcv_pay_div = gc_rcv_pay_div_in
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  ELSE SUBSTR(xrpm.break_col_01,INSTR(xrpm.break_col_01,gv_hifn) +1)
             END                                  column_no
            ,itc.reason_code                      reason_code
            ,itc.trans_date                       trans_date
            ,TO_CHAR(itc.trans_date, 'YYYYMM')  trans_ym
            ,CASE WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN TO_CHAR(ABS(TO_NUMBER(xrpm.rcv_pay_div)))
                  ELSE xrpm.rcv_pay_div
             END                                  rcv_pay_div
            ,xrpm.dealings_div                    dealings_div
            ,itc.doc_type                         doc_type
            ,ir_param.item_class                  item_div
            ,ir_param.goods_class                 prod_div
            ,mcb3.segment1                        crowd_code
            ,SUBSTR(mcb3.segment1, 1, 3)          crowd_low
            ,SUBSTR(mcb3.segment1, 1, 2)          crowd_mid
            ,SUBSTR(mcb3.segment1, 1, 1)          crowd_high
            ,itc.item_id                          item_id
            ,itc.lot_id                           lot_id
-- v1.33 Mod Start
--            ,NVL(itc.trans_qty, 0)                trans_qty
            ,SUM(NVL(itc.trans_qty, 0))           trans_qty
-- v1.33 Mod End
            ,itc.trans_date                       arrival_date
            ,TO_CHAR(itc.trans_date, gc_char_ym_format) arrival_ym
            ,iimb.item_no                         item_code
            ,ximb.item_short_name                 item_name
      FROM   ic_tran_cmp                      itc
-- v1.33 Add Start
            ,ic_adjs_jnl                      iaj
            ,ic_jrnl_mst                      ijm
-- v1.33 Add End
            ,ic_item_mst_b                    iimb
            ,xxcmn_item_mst_b                 ximb
            ,ic_lots_mst                      ilm
            ,xxcmn_lot_cost                   xlc
            ,gmi_item_categories              gic1
            ,mtl_categories_b                 mcb1
            ,gmi_item_categories              gic2
            ,mtl_categories_b                 mcb2
            ,gmi_item_categories              gic3
            ,mtl_categories_b                 mcb3
            ,xxcmn_rcv_pay_mst                xrpm
            ,ic_whse_mst                      iwm
      WHERE  itc.doc_type            = gv_doc_type_adji
      AND    itc.reason_code         = gv_reason_code_adji_po
      AND    itc.trans_date > FND_DATE.STRING_TO_DATE(gd_prv1_dt_chr,gc_char_dt_format)
      AND    itc.trans_date < FND_DATE.STRING_TO_DATE(gd_flw_dt_chr,gc_char_dt_format)
-- v1.33 Add Start
      AND    iaj.trans_type          = itc.doc_type
      AND    iaj.doc_id              = itc.doc_id
      AND    iaj.doc_line            = itc.doc_line
      AND    ijm.journal_id          = iaj.journal_id
-- v1.33 Add End
      AND    ilm.item_id             = itc.item_id
      AND    ilm.lot_id              = itc.lot_id
      AND    iimb.item_id            = ilm.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(itc.trans_date)
      AND    ximb.end_date_active   >= TRUNC(itc.trans_date)
      AND    gic1.item_id            = itc.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = itc.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    gic3.item_id            = itc.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
      AND    xrpm.doc_type           = itc.doc_type
      AND    xrpm.reason_code        = itc.reason_code
      AND    xrpm.break_col_01       IS NOT NULL
      AND    iwm.whse_code           = itc.whse_code
      AND    iwm.whse_code           = ir_param.locat_code
      AND    mcb3.segment1           = lt_crowd_code
-- 2009/03/05 v1.31 ADD START
      AND    iwm.attribute1          = '0'
-- 2009/03/05 v1.31 ADD END
-- v1.33 Add Start
      GROUP BY
             iwm.whse_code                        -- h_whse_code
            ,iwm.whse_name                        -- h_whse_name
            ,iimb.attribute15                     -- cost_mng_clss
            ,iimb.lot_ctl                         -- lot_ctl
            ,xlc.unit_ploce                       -- actual_unit_price
            ,CASE WHEN INSTR(xrpm.break_col_01,gv_hifn) = 0
                       THEN ''
                  WHEN xrpm.rcv_pay_div = gc_rcv_pay_div_in
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  ELSE SUBSTR(xrpm.break_col_01,INSTR(xrpm.break_col_01,gv_hifn) +1)
             END                                  -- column_no
            ,itc.reason_code                      -- reason_code
            ,itc.trans_date                       -- trans_date
            ,TO_CHAR(itc.trans_date, 'YYYYMM')    -- trans_ym
            ,CASE WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN TO_CHAR(ABS(TO_NUMBER(xrpm.rcv_pay_div)))
                  ELSE xrpm.rcv_pay_div
             END                                  -- rcv_pay_div
            ,xrpm.dealings_div                    -- dealings_div
            ,itc.doc_type                         -- doc_type
            ,ir_param.item_class                  -- item_div
            ,ir_param.goods_class                 -- prod_div
            ,mcb3.segment1                        -- crowd_code
            ,SUBSTR(mcb3.segment1, 1, 3)          -- crowd_low
            ,SUBSTR(mcb3.segment1, 1, 2)          -- crowd_mid
            ,SUBSTR(mcb3.segment1, 1, 1)          -- crowd_high
            ,itc.item_id                          -- item_id
            ,itc.lot_id                           -- lot_id
            ,itc.trans_date                       -- arrival_date
            ,TO_CHAR(itc.trans_date, gc_char_ym_format) -- arrival_ym
            ,iimb.item_no                         -- item_code
            ,ximb.item_short_name                 -- item_name
            ,ijm.attribute1                       -- 受入返品実績アドオン.取引ID
-- v1.33 Add End
      UNION ALL
      SELECT /*+ leading (itc gic1 mcb1 gic2 mcb2 xrpm) use_nl (itc gic1 mcb1 gic2 mcb2 xrpm) */
             iwm.whse_code                        h_whse_code
            ,iwm.whse_name                        h_whse_name
            ,itc.trans_id                         trans_id
            ,iimb.attribute15                     cost_mng_clss
            ,iimb.lot_ctl                         lot_ctl
            ,xlc.unit_ploce                       actual_unit_price
            ,CASE WHEN INSTR(xrpm.break_col_01,gv_hifn) = 0
                       THEN ''
                  WHEN xrpm.rcv_pay_div = gc_rcv_pay_div_in
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  ELSE SUBSTR(xrpm.break_col_01,INSTR(xrpm.break_col_01,gv_hifn) +1)
             END                                  column_no
            ,itc.reason_code                      reason_code
            ,itc.trans_date                       trans_date
            ,TO_CHAR(itc.trans_date, 'YYYYMM')  trans_ym
            ,CASE WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN TO_CHAR(ABS(TO_NUMBER(xrpm.rcv_pay_div)))
                  ELSE xrpm.rcv_pay_div
             END                                  rcv_pay_div
            ,xrpm.dealings_div                    dealings_div
            ,itc.doc_type                         doc_type
            ,ir_param.item_class                  item_div
            ,ir_param.goods_class                 prod_div
            ,mcb3.segment1                        crowd_code
            ,SUBSTR(mcb3.segment1, 1, 3)          crowd_low
            ,SUBSTR(mcb3.segment1, 1, 2)          crowd_mid
            ,SUBSTR(mcb3.segment1, 1, 1)          crowd_high
            ,itc.item_id                          item_id
            ,itc.lot_id                           lot_id
            ,NVL(itc.trans_qty, 0)                trans_qty
            ,itc.trans_date                       arrival_date
            ,TO_CHAR(itc.trans_date, gc_char_ym_format) arrival_ym
            ,iimb.item_no                         item_code
            ,ximb.item_short_name                 item_name
      FROM   ic_tran_cmp                      itc
            ,ic_item_mst_b                    iimb
            ,xxcmn_item_mst_b                 ximb
            ,ic_lots_mst                      ilm
            ,xxcmn_lot_cost                   xlc
            ,gmi_item_categories              gic1
            ,mtl_categories_b                 mcb1
            ,gmi_item_categories              gic2
            ,mtl_categories_b                 mcb2
            ,gmi_item_categories              gic3
            ,mtl_categories_b                 mcb3
            ,xxcmn_rcv_pay_mst                xrpm
            ,ic_whse_mst                      iwm
      WHERE  itc.doc_type            = gv_doc_type_adji
      AND    itc.reason_code         = gv_reason_code_adji_hama
      AND    itc.trans_date > FND_DATE.STRING_TO_DATE(gd_prv1_dt_chr,gc_char_dt_format)
      AND    itc.trans_date < FND_DATE.STRING_TO_DATE(gd_flw_dt_chr,gc_char_dt_format)
      AND    ilm.item_id             = itc.item_id
      AND    ilm.lot_id              = itc.lot_id
      AND    iimb.item_id            = ilm.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(itc.trans_date)
      AND    ximb.end_date_active   >= TRUNC(itc.trans_date)
      AND    gic1.item_id            = itc.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = itc.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    gic3.item_id            = itc.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
      AND    xrpm.doc_type           = itc.doc_type
      AND    xrpm.reason_code        = itc.reason_code
      AND    xrpm.break_col_01       IS NOT NULL
      AND    iwm.whse_code           = itc.whse_code
      AND    iwm.whse_code           = ir_param.locat_code
      AND    mcb3.segment1           = lt_crowd_code
-- 2009/03/05 v1.31 ADD START
      AND    iwm.attribute1          = '0'
-- 2009/03/05 v1.31 ADD END
      UNION ALL
      SELECT /*+ leading (xmrh xmrl ijm iaj itc gic1 mcb1 gic2 mcb2) use_nl (xmrh xmrl ijm iaj itc gic1 mcb1 gic2 mcb2) */
             iwm.whse_code                        h_whse_code
            ,iwm.whse_name                        h_whse_name
            ,itc.trans_id                         trans_id
            ,iimb.attribute15                     cost_mng_clss
            ,iimb.lot_ctl                         lot_ctl
            ,xlc.unit_ploce                       actual_unit_price
            ,CASE WHEN INSTR(xrpm.break_col_01,gv_hifn) = 0
                       THEN ''
                  WHEN xrpm.rcv_pay_div = gc_rcv_pay_div_in
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  ELSE SUBSTR(xrpm.break_col_01,INSTR(xrpm.break_col_01,gv_hifn) +1)
             END                                  column_no
            ,itc.reason_code                      reason_code
            ,itc.trans_date                       trans_date
            ,TO_CHAR(itc.trans_date, 'YYYYMM')  trans_ym
-- 2008/12/11 v1.26 N.Yoshida mod start
--            ,gc_rcv_pay_div_adj                   rcv_pay_div
            ,xrpm.rcv_pay_div                     rcv_pay_div
-- 2008/12/11 v1.26 N.Yoshida mod end
            ,xrpm.dealings_div                    dealings_div
            ,itc.doc_type                         doc_type
            ,ir_param.item_class                  item_div
            ,ir_param.goods_class                 prod_div
            ,mcb3.segment1                        crowd_code
            ,SUBSTR(mcb3.segment1, 1, 3)          crowd_low
            ,SUBSTR(mcb3.segment1, 1, 2)          crowd_mid
            ,SUBSTR(mcb3.segment1, 1, 1)          crowd_high
            ,itc.item_id                          item_id
            ,itc.lot_id                           lot_id
-- 2008/12/11 v1.26 N.Yoshida mod start
--            ,ABS(NVL(itc.trans_qty, 0))           trans_qty
            ,NVL(itc.trans_qty, 0)                trans_qty
-- 2008/12/11 v1.26 N.Yoshida mod end
            ,xmrh.actual_arrival_date             arrival_date
            ,TO_CHAR(xmrh.actual_arrival_date, gc_char_ym_format) arrival_ym
            ,iimb.item_no                         item_code
            ,ximb.item_short_name                 item_name
      FROM   ic_tran_cmp                      itc
            ,ic_adjs_jnl                      iaj
            ,ic_jrnl_mst                      ijm
            ,xxinv_mov_req_instr_headers      xmrh
            ,xxinv_mov_req_instr_lines        xmrl
            ,ic_item_mst_b                    iimb
            ,xxcmn_item_mst_b                 ximb
            ,ic_lots_mst                      ilm
            ,xxcmn_lot_cost                   xlc
            ,gmi_item_categories              gic1
            ,mtl_categories_b                 mcb1
            ,gmi_item_categories              gic2
            ,mtl_categories_b                 mcb2
            ,gmi_item_categories              gic3
            ,mtl_categories_b                 mcb3
            ,xxcmn_rcv_pay_mst                xrpm
            ,ic_whse_mst                      iwm
      WHERE  itc.doc_type            = gv_doc_type_adji
      AND    itc.reason_code         = gv_reason_code_adji_move
      AND    xmrh.actual_arrival_date > FND_DATE.STRING_TO_DATE(gd_prv1_dt_chr,gc_char_dt_format)
      AND    xmrh.actual_arrival_date < FND_DATE.STRING_TO_DATE(gd_flw_dt_chr,gc_char_dt_format)
      AND    iaj.trans_type          = itc.doc_type
      AND    iaj.doc_id              = itc.doc_id
      AND    iaj.doc_line            = itc.doc_line
      AND    ijm.journal_id          = iaj.journal_id
      AND    ijm.attribute1          = TO_CHAR(xmrl.mov_line_id)
      AND    xmrh.mov_hdr_id         = xmrl.mov_hdr_id
      AND    ilm.item_id             = itc.item_id
      AND    ilm.lot_id              = itc.lot_id
      AND    iimb.item_id            = ilm.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(itc.trans_date)
      AND    ximb.end_date_active   >= TRUNC(itc.trans_date)
      AND    gic1.item_id            = itc.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = itc.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    gic3.item_id            = itc.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
-- 2008/12/11 v1.26 N.Yoshida mod start
      AND    xrpm.rcv_pay_div        = CASE
--                                       WHEN itc.trans_qty >= 0 THEN 1
--                                       ELSE -1
                                       WHEN itc.trans_qty >= 0 THEN -1
                                       ELSE 1
                                       END
-- 2008/12/11 v1.26 N.Yoshida mod end
      AND    xrpm.doc_type           = itc.doc_type
      AND    xrpm.reason_code        = itc.reason_code
      AND    xrpm.break_col_01       IS NOT NULL
      AND    iwm.whse_code           = itc.whse_code
      AND    iwm.whse_code           = ir_param.locat_code
      AND    mcb3.segment1           = lt_crowd_code
-- 2009/03/05 v1.31 ADD START
      AND    iwm.attribute1          = '0'
-- 2009/03/05 v1.31 ADD END
      UNION ALL
      SELECT /*+ leading (itc gic1 mcb1 gic2 mcb2) use_nl (itc gic1 mcb1 gic2 mcb2) */
             iwm.whse_code                        h_whse_code
            ,iwm.whse_name                        h_whse_name
            ,itc.trans_id                         trans_id
            ,iimb.attribute15                     cost_mng_clss
            ,iimb.lot_ctl                         lot_ctl
            ,xlc.unit_ploce                       actual_unit_price
            ,CASE WHEN INSTR(xrpm.break_col_01,gv_hifn) = 0
                       THEN ''
                  WHEN xrpm.rcv_pay_div = gc_rcv_pay_div_in
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  ELSE SUBSTR(xrpm.break_col_01,INSTR(xrpm.break_col_01,gv_hifn) +1)
             END                                  column_no
            ,itc.reason_code                      reason_code
            ,itc.trans_date                       trans_date
            ,TO_CHAR(itc.trans_date, 'YYYYMM')  trans_ym
            ,CASE WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN TO_CHAR(ABS(TO_NUMBER(xrpm.rcv_pay_div)))
                  ELSE xrpm.rcv_pay_div
             END                                  rcv_pay_div
            ,xrpm.dealings_div                    dealings_div
            ,itc.doc_type                         doc_type
            ,ir_param.item_class                  item_div
            ,ir_param.goods_class                 prod_div
            ,mcb3.segment1                        crowd_code
            ,SUBSTR(mcb3.segment1, 1, 3)          crowd_low
            ,SUBSTR(mcb3.segment1, 1, 2)          crowd_mid
            ,SUBSTR(mcb3.segment1, 1, 1)          crowd_high
            ,itc.item_id                          item_id
            ,itc.lot_id                           lot_id
            ,NVL(itc.trans_qty, 0)                trans_qty
            ,itc.trans_date                       arrival_date
            ,TO_CHAR(itc.trans_date, gc_char_ym_format) arrival_ym
            ,iimb.item_no                         item_code
            ,ximb.item_short_name                 item_name
      FROM   ic_tran_cmp                      itc
            ,ic_item_mst_b                    iimb
            ,xxcmn_item_mst_b                 ximb
            ,ic_lots_mst                      ilm
            ,xxcmn_lot_cost                   xlc
            ,gmi_item_categories              gic1
            ,mtl_categories_b                 mcb1
            ,gmi_item_categories              gic2
            ,mtl_categories_b                 mcb2
            ,gmi_item_categories              gic3
            ,mtl_categories_b                 mcb3
            ,xxcmn_rcv_pay_mst                xrpm
            ,ic_whse_mst                      iwm
      WHERE  itc.doc_type            = gv_doc_type_adji
      AND    itc.reason_code        IN (gv_reason_code_adji_itm
                                       ,gv_reason_code_adji_itm_u
                                       ,gv_reason_code_adji_snt_u
                                       ,gv_reason_code_adji_snt)
      AND    itc.trans_date > FND_DATE.STRING_TO_DATE(gd_prv1_dt_chr,gc_char_dt_format)
      AND    itc.trans_date < FND_DATE.STRING_TO_DATE(gd_flw_dt_chr,gc_char_dt_format)
      AND    ilm.item_id             = itc.item_id
      AND    ilm.lot_id              = itc.lot_id
      AND    iimb.item_id            = ilm.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(itc.trans_date)
      AND    ximb.end_date_active   >= TRUNC(itc.trans_date)
      AND    gic1.item_id            = itc.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = itc.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    gic3.item_id            = itc.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
-- 2008/11/19 v1.18 DELETE START
      --AND    xrpm.rcv_pay_div        = CASE
      --                                 WHEN itc.trans_qty >= 0 THEN 1
      --                                 ELSE -1
      --                                 END
-- 2008/11/19 v1.18 DELETE END
      AND    xrpm.doc_type           = itc.doc_type
      AND    xrpm.reason_code        = itc.reason_code
      AND    xrpm.break_col_01       IS NOT NULL
      AND    iwm.whse_code           = itc.whse_code
      AND    iwm.whse_code           = ir_param.locat_code
      AND    mcb3.segment1           = lt_crowd_code
-- 2009/03/05 v1.31 ADD START
      AND    iwm.attribute1          = '0'
-- 2009/03/05 v1.31 ADD END
      UNION ALL
      SELECT /*+ leading (itp gic1 mcb1 gic2 mcb2) use_nl (itp gic1 mcb1 gic2 mcb2)*/
             iwm.whse_code                        h_whse_code
            ,iwm.whse_name                        h_whse_name
            ,itp.trans_id                         trans_id
            ,iimb.attribute15                     cost_mng_clss
            ,iimb.lot_ctl                         lot_ctl
            ,xlc.unit_ploce                       actual_unit_price
            ,CASE WHEN INSTR(xrpm.break_col_01,gv_hifn) = 0
                       THEN ''
                  WHEN xrpm.rcv_pay_div = gc_rcv_pay_div_in
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  ELSE SUBSTR(xrpm.break_col_01,INSTR(xrpm.break_col_01,gv_hifn) +1)
             END                                  column_no
            ,itp.reason_code                      reason_code
            ,itp.trans_date                       trans_date
            ,TO_CHAR(itp.trans_date, 'YYYYMM')  trans_ym
            ,CASE WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN TO_CHAR(ABS(TO_NUMBER(xrpm.rcv_pay_div)))
                  ELSE xrpm.rcv_pay_div
             END                                  rcv_pay_div
            ,xrpm.dealings_div                    dealings_div
            ,itp.doc_type                         doc_type
            ,ir_param.item_class                  item_div
            ,ir_param.goods_class                 prod_div
            ,mcb3.segment1                        crowd_code
            ,SUBSTR(mcb3.segment1, 1, 3)          crowd_low
            ,SUBSTR(mcb3.segment1, 1, 2)          crowd_mid
            ,SUBSTR(mcb3.segment1, 1, 1)          crowd_high
            ,itp.item_id                          item_id
            ,itp.lot_id                           lot_id
            ,NVL(itp.trans_qty, 0)                trans_qty
            ,itp.trans_date                       arrival_date
            ,TO_CHAR(itp.trans_date, gc_char_ym_format) arrival_ym
            ,iimb.item_no                         item_code
            ,ximb.item_short_name                 item_name
      FROM   ic_tran_pnd                      itp
            ,ic_item_mst_b                    iimb
            ,xxcmn_item_mst_b                 ximb
            ,ic_lots_mst                      ilm
            ,xxcmn_lot_cost                   xlc
            ,gmi_item_categories              gic1
            ,mtl_categories_b                 mcb1
            ,gmi_item_categories              gic2
            ,mtl_categories_b                 mcb2
            ,gmi_item_categories              gic3
            ,mtl_categories_b                 mcb3
            ,gme_material_details             gmd
            ,gme_batch_header                 gbh
            ,gmd_routings_b                   grb
            ,xxcmn_rcv_pay_mst                xrpm
            ,ic_whse_mst                      iwm
      WHERE  itp.doc_type            = gv_doc_type_prod
      AND    itp.completed_ind       = 1
      AND    itp.trans_date > FND_DATE.STRING_TO_DATE(gd_prv1_dt_chr,gc_char_dt_format)
      AND    itp.trans_date < FND_DATE.STRING_TO_DATE(gd_flw_dt_chr,gc_char_dt_format)
      AND    itp.reverse_id          IS NULL
      AND    ilm.item_id             = itp.item_id
      AND    ilm.lot_id              = itp.lot_id
      AND    iimb.item_id            = ilm.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(itp.trans_date)
      AND    ximb.end_date_active   >= TRUNC(itp.trans_date)
      AND    gic1.item_id            = itp.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = itp.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    gic3.item_id            = itp.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
      AND    gmd.batch_id            = itp.doc_id
      AND    gmd.line_no             = itp.doc_line
      AND    gmd.line_type           = itp.line_type
      AND    gbh.batch_id            = gmd.batch_id
      AND    grb.routing_id          = gbh.routing_id
      AND    xrpm.routing_class      = grb.routing_class
      AND    xrpm.line_type          = gmd.line_type
      AND    (((gmd.attribute5 IS NULL) AND (xrpm.hit_in_div IS NULL))
             OR (xrpm.hit_in_div = gmd.attribute5))
      AND    itp.doc_type            = xrpm.doc_type
      AND    itp.line_type           = xrpm.line_type
      AND    xrpm.break_col_01       IS NOT NULL
      AND    xrpm.routing_class      <> '70'
      AND    iwm.whse_code           = itp.whse_code
      AND    iwm.whse_code           = ir_param.locat_code
      AND    mcb3.segment1           = lt_crowd_code
-- 2009/03/05 v1.31 ADD START
      AND    iwm.attribute1          = '0'
-- 2009/03/05 v1.31 ADD END
      UNION ALL --prod_i
      SELECT /*+ leading (itp gic1 mcb1 gic2 mcb2 gmd gbh grb) use_nl (itp gic1 mcb1 gic2 mcb2 gmd gbh grb)*/
             iwm.whse_code                        h_whse_code
            ,iwm.whse_name                        h_whse_name
            ,itp.trans_id                         trans_id
            ,iimb.attribute15                     cost_mng_clss
            ,iimb.lot_ctl                         lot_ctl
            ,xlc.unit_ploce                       actual_unit_price
            ,CASE WHEN INSTR(xrpm.break_col_01,gv_hifn) = 0
                       THEN ''
                  WHEN xrpm.rcv_pay_div = gc_rcv_pay_div_in
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  ELSE SUBSTR(xrpm.break_col_01,INSTR(xrpm.break_col_01,gv_hifn) +1)
             END                                  column_no
            ,itp.reason_code                      reason_code
            ,itp.trans_date                       trans_date
            ,TO_CHAR(itp.trans_date, 'YYYYMM')  trans_ym
            ,CASE WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN TO_CHAR(ABS(TO_NUMBER(xrpm.rcv_pay_div)))
                  ELSE xrpm.rcv_pay_div
             END                                  rcv_pay_div
            ,xrpm.dealings_div                    dealings_div
            ,itp.doc_type                         doc_type
            ,ir_param.item_class                  item_div
            ,ir_param.goods_class                 prod_div
            ,mcb3.segment1                        crowd_code
            ,SUBSTR(mcb3.segment1, 1, 3)          crowd_low
            ,SUBSTR(mcb3.segment1, 1, 2)          crowd_mid
            ,SUBSTR(mcb3.segment1, 1, 1)          crowd_high
            ,itp.item_id                          item_id
            ,itp.lot_id                           lot_id
            ,NVL(itp.trans_qty, 0)                trans_qty
            ,itp.trans_date                       arrival_date
            ,TO_CHAR(itp.trans_date, gc_char_ym_format) arrival_ym
            ,iimb.item_no                         item_code
            ,ximb.item_short_name                 item_name
      FROM   ic_tran_pnd                      itp
            ,ic_item_mst_b                    iimb
            ,xxcmn_item_mst_b                 ximb
            ,ic_lots_mst                      ilm
            ,xxcmn_lot_cost                   xlc
            ,gmi_item_categories              gic1
            ,mtl_categories_b                 mcb1
            ,gmi_item_categories              gic2
            ,mtl_categories_b                 mcb2
            ,gmi_item_categories              gic3
            ,mtl_categories_b                 mcb3
            ,gme_material_details             gmd
            ,gme_batch_header                 gbh
            ,gmd_routings_b                   grb
            ,xxcmn_rcv_pay_mst                xrpm
            ,ic_whse_mst                      iwm
      WHERE  itp.doc_type            = gv_doc_type_prod
      AND    itp.completed_ind       = 1
      AND    itp.trans_date > FND_DATE.STRING_TO_DATE(gd_prv1_dt_chr,gc_char_dt_format)
      AND    itp.trans_date < FND_DATE.STRING_TO_DATE(gd_flw_dt_chr,gc_char_dt_format)
      AND    itp.reverse_id          IS NULL
      AND    ilm.item_id             = itp.item_id
      AND    ilm.lot_id              = itp.lot_id
      AND    iimb.item_id            = ilm.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(itp.trans_date)
      AND    ximb.end_date_active   >= TRUNC(itp.trans_date)
      AND    gic1.item_id            = itp.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = itp.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    mcb2.segment1           IN ('1','4')
      AND    gic3.item_id            = itp.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
      AND    gmd.batch_id            = itp.doc_id
      AND    gmd.line_no             = itp.doc_line
      AND    gmd.line_type           = itp.line_type
      AND    gbh.batch_id            = gmd.batch_id
      AND    grb.routing_id          = gbh.routing_id
      AND    xrpm.routing_class      = grb.routing_class
      AND    xrpm.line_type          = gmd.line_type
      AND    (((gmd.attribute5 IS NULL) AND (xrpm.hit_in_div IS NULL))
             OR (xrpm.hit_in_div = gmd.attribute5))
      AND    itp.doc_type            = xrpm.doc_type
      AND    itp.line_type           = xrpm.line_type
      AND    xrpm.break_col_01       IS NOT NULL
      AND    xrpm.routing_class      = '70'
      AND    (EXISTS (SELECT 1
                      FROM   gme_material_details gmd2
                            ,gmi_item_categories  gic
                            ,mtl_categories_b     mcb
                      WHERE  gmd2.batch_id   = gmd.batch_id
                      AND    gmd2.line_no    = gmd.line_no
                      AND    gmd2.line_type  = -1
                      AND    gic.item_id     = gmd2.item_id
                      AND    gic.category_set_id = cn_item_class_id
                      AND    gic.category_id = mcb.category_id
                      AND    mcb.segment1    = xrpm.item_div_origin))
      AND    (EXISTS (SELECT 1
                      FROM   gme_material_details gmd3
                            ,gmi_item_categories  gic
                            ,mtl_categories_b     mcb
                      WHERE  gmd3.batch_id   = gmd.batch_id
                      AND    gmd3.line_no    = gmd.line_no
                      AND    gmd3.line_type  = 1
                      AND    gic.item_id     = gmd3.item_id
                      AND    gic.category_set_id = cn_item_class_id
                      AND    gic.category_id = mcb.category_id
                      AND    mcb.segment1    = xrpm.item_div_ahead))
      AND    iwm.whse_code           = itp.whse_code
      AND    iwm.whse_code           = ir_param.locat_code
      AND    mcb3.segment1           = lt_crowd_code
-- 2009/03/05 v1.31 ADD START
      AND    iwm.attribute1          = '0'
-- 2009/03/05 v1.31 ADD END
      UNION ALL
      SELECT /*+ leading (xoha xola rsl itp gic1 mcb1 gic2 mcb2 ooha otta) use_nl (xoha xola rsl itp gic1 mcb1 gic2 mcb2 ooha otta) */
             iwm.whse_code                        h_whse_code
            ,iwm.whse_name                        h_whse_name
            ,itp.trans_id                         trans_id
            ,iimb.attribute15                     cost_mng_clss
            ,iimb.lot_ctl                         lot_ctl
            ,xlc.unit_ploce                       actual_unit_price
            ,CASE WHEN INSTR(xrpm.break_col_01,gv_hifn) = 0
                       THEN ''
                  WHEN xrpm.rcv_pay_div = gc_rcv_pay_div_in
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  ELSE SUBSTR(xrpm.break_col_01,INSTR(xrpm.break_col_01,gv_hifn) +1)
             END                                  column_no
            ,itp.reason_code                      reason_code
            ,itp.trans_date                       trans_date
            ,TO_CHAR(itp.trans_date, 'YYYYMM')  trans_ym
            ,CASE WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN TO_CHAR(ABS(TO_NUMBER(xrpm.rcv_pay_div)))
                  ELSE xrpm.rcv_pay_div
             END                                  rcv_pay_div
            ,xrpm.dealings_div                    dealings_div
            ,itp.doc_type                         doc_type
            ,ir_param.item_class                  item_div
            ,ir_param.goods_class                 prod_div
            ,mcb3.segment1                        crowd_code
            ,SUBSTR(mcb3.segment1, 1, 3)          crowd_low
            ,SUBSTR(mcb3.segment1, 1, 2)          crowd_mid
            ,SUBSTR(mcb3.segment1, 1, 1)          crowd_high
            ,itp.item_id                          item_id
            ,itp.lot_id                           lot_id
            ,NVL(itp.trans_qty, 0)                trans_qty
            ,xoha.arrival_date                    arrival_date
            ,TO_CHAR(xoha.arrival_date, gc_char_ym_format) arrival_ym
            ,iimb.item_no                         item_code
            ,ximb.item_short_name                 item_name
      FROM   ic_tran_pnd                      itp
            ,rcv_shipment_lines               rsl
            ,oe_order_headers_all             ooha
            ,oe_transaction_types_all         otta
            ,xxwsh_order_headers_all          xoha
            ,xxwsh_order_lines_all            xola
            ,ic_item_mst_b                    iimb
            ,xxcmn_item_mst_b                 ximb
            ,ic_lots_mst                      ilm
            ,xxcmn_lot_cost                   xlc
            ,gmi_item_categories              gic1
            ,mtl_categories_b                 mcb1
            ,gmi_item_categories              gic2
            ,mtl_categories_b                 mcb2
            ,gmi_item_categories              gic3
            ,mtl_categories_b                 mcb3
            ,xxcmn_rcv_pay_mst                xrpm
            ,ic_whse_mst                      iwm
      WHERE  itp.doc_type            = gv_doc_type_porc
      AND    itp.completed_ind       = 1
      AND    xoha.latest_external_flag = 'Y'
      AND    xoha.arrival_date > FND_DATE.STRING_TO_DATE(gd_prv1_dt_chr,gc_char_dt_format)
      AND    xoha.arrival_date < FND_DATE.STRING_TO_DATE(gd_flw_dt_chr,gc_char_dt_format)
      AND    xoha.req_status         IN ('04','08')
      AND    ilm.item_id             = itp.item_id
      AND    ilm.lot_id              = itp.lot_id
      AND    iimb.item_id            = itp.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(itp.trans_date)
      AND    ximb.end_date_active   >= TRUNC(itp.trans_date)
      AND    gic1.item_id            = itp.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = itp.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    gic3.item_id            = itp.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
      AND    rsl.shipment_header_id  = itp.doc_id
      AND    rsl.line_num            = itp.doc_line
      AND    rsl.oe_order_header_id  = xola.header_id
      AND    rsl.oe_order_line_id    = xola.line_id
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    ((otta.attribute4           <> '2')
             OR  (otta.attribute4       IS NULL))
      AND    otta.attribute1         IN ('1','2')
      AND    xoha.header_id          = ooha.header_id
      AND    xola.order_header_id    = xoha.order_header_id
      AND    xola.request_item_code  = xola.shipping_item_code
      AND    xrpm.doc_type           = itp.doc_type
      AND    xrpm.source_document_code = 'RMA'
      AND    xrpm.dealings_div       IN ('101','103')
      AND    xrpm.shipment_provision_div = DECODE(xoha.req_status,'04','1','08','2')
      AND    xrpm.shipment_provision_div = otta.attribute1
      AND    ((xrpm.ship_prov_rcv_pay_category IS NULL)
             OR (xrpm.ship_prov_rcv_pay_category = otta.attribute11))
      AND    xrpm.break_col_01       IS NOT NULL
      AND    xrpm.item_div_origin    IS NULL
      AND    xrpm.item_div_ahead     IS NULL
      AND    iwm.whse_code           = itp.whse_code
      AND    iwm.whse_code           = ir_param.locat_code
      AND    mcb3.segment1           = lt_crowd_code
-- 2009/03/05 v1.31 ADD START
      AND    iwm.attribute1          = '0'
-- 2009/03/05 v1.31 ADD END
      UNION ALL
      SELECT /*+ leading (xoha xola rsl itp gic1 mcb1 gic2 mcb2 ooha otta) use_nl (xoha xola rsl itp gic1 mcb1 gic2 mcb2 ooha otta) */
             iwm.whse_code                        h_whse_code
            ,iwm.whse_name                        h_whse_name
            ,itp.trans_id                         trans_id
            ,iimb.attribute15                     cost_mng_clss
            ,iimb.lot_ctl                         lot_ctl
            ,xlc.unit_ploce                       actual_unit_price
            ,CASE WHEN INSTR(xrpm.break_col_01,gv_hifn) = 0
                       THEN ''
                  WHEN xrpm.rcv_pay_div = gc_rcv_pay_div_in
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  ELSE SUBSTR(xrpm.break_col_01,INSTR(xrpm.break_col_01,gv_hifn) +1)
             END                                  column_no
            ,itp.reason_code                      reason_code
            ,itp.trans_date                       trans_date
            ,TO_CHAR(itp.trans_date, 'YYYYMM')  trans_ym
            ,CASE WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN TO_CHAR(ABS(TO_NUMBER(xrpm.rcv_pay_div)))
                  ELSE xrpm.rcv_pay_div
             END                                  rcv_pay_div
            ,xrpm.dealings_div                    dealings_div
            ,itp.doc_type                         doc_type
            ,ir_param.item_class                  item_div
            ,ir_param.goods_class                 prod_div
            ,mcb3.segment1                        crowd_code
            ,SUBSTR(mcb3.segment1, 1, 3)          crowd_low
            ,SUBSTR(mcb3.segment1, 1, 2)          crowd_mid
            ,SUBSTR(mcb3.segment1, 1, 1)          crowd_high
            ,iimb.item_id                         item_id
            ,itp.lot_id                           lot_id
            ,NVL(itp.trans_qty, 0)                trans_qty
            ,xoha.arrival_date                      arrival_date
            ,TO_CHAR(xoha.arrival_date, gc_char_ym_format) arrival_ym
            ,iimb.item_no                         item_code
            ,ximb.item_short_name                 item_name
      FROM   ic_tran_pnd                      itp
            ,rcv_shipment_lines               rsl
            ,oe_order_headers_all             ooha
            ,oe_transaction_types_all         otta
            ,xxwsh_order_headers_all          xoha
            ,xxwsh_order_lines_all            xola
            ,ic_item_mst_b                    iimb
            ,ic_item_mst_b                    iimb2
            ,xxcmn_item_mst_b                 ximb
            ,ic_lots_mst                      ilm
            ,xxcmn_lot_cost                   xlc
            ,gmi_item_categories              gic1
            ,mtl_categories_b                 mcb1
            ,gmi_item_categories              gic2
            ,mtl_categories_b                 mcb2
            ,gmi_item_categories              gic3
            ,mtl_categories_b                 mcb3
            ,gmi_item_categories              gic4
            ,mtl_categories_b                 mcb4
            ,xxcmn_rcv_pay_mst                xrpm
            ,ic_whse_mst                      iwm
      WHERE  itp.doc_type            = gv_doc_type_porc
      AND    itp.completed_ind       = 1
      AND    xoha.latest_external_flag = 'Y'
      AND    xoha.arrival_date > FND_DATE.STRING_TO_DATE(gd_prv1_dt_chr,gc_char_dt_format)
      AND    xoha.arrival_date < FND_DATE.STRING_TO_DATE(gd_flw_dt_chr,gc_char_dt_format)
      AND    xoha.req_status         IN ('04','08')
      AND    ilm.item_id             = itp.item_id
      AND    ilm.lot_id              = itp.lot_id
      AND    iimb.item_id            = itp.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    iimb2.item_no           = xola.request_item_code
      AND    ximb.start_date_active <= TRUNC(itp.trans_date)
      AND    ximb.end_date_active   >= TRUNC(itp.trans_date)
      AND    gic1.item_id            = itp.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = itp.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    gic3.item_id            = itp.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
      AND    gic4.item_id            = iimb2.item_id
      AND    gic4.category_set_id    = cn_item_class_id
      AND    gic4.category_id        = mcb4.category_id
      AND    rsl.shipment_header_id  = itp.doc_id
      AND    rsl.line_num            = itp.doc_line
      AND    rsl.oe_order_header_id  = xoha.header_id
      AND    rsl.oe_order_line_id    = xola.line_id
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    ((otta.attribute4           <> '2')
             OR  (otta.attribute4       IS NULL))
      AND    otta.attribute1         IN ('1','2')
      AND    xoha.header_id          = ooha.header_id
      AND    xola.order_header_id    = xoha.order_header_id
      AND    xrpm.doc_type           = itp.doc_type
      AND    xrpm.source_document_code = 'RMA'
      AND    xrpm.dealings_div       = '106'
      AND    xrpm.shipment_provision_div = DECODE(xoha.req_status,'04','1','08','2')
      AND    xrpm.shipment_provision_div = otta.attribute1
      AND    xrpm.ship_prov_rcv_pay_category = otta.attribute11
      AND    xrpm.item_div_ahead     = mcb4.segment1
      AND    mcb2.segment1           <> '5'
      AND    xrpm.break_col_01       IS NOT NULL
      AND    iwm.whse_code           = itp.whse_code
      AND    iwm.whse_code           = ir_param.locat_code
      AND    mcb3.segment1           = lt_crowd_code
-- 2009/03/05 v1.31 ADD START
      AND    iwm.attribute1          = '0'
-- 2009/03/05 v1.31 ADD END
      UNION ALL
      SELECT /*+ leading (xoha xola rsl itp gic1 mcb1 gic2 mcb2 ooha otta xrpm) use_nl (xoha xola rsl itp gic1 mcb1 gic2 mcb2 rsl ooha otta xrpm) */
             iwm.whse_code                        h_whse_code
            ,iwm.whse_name                        h_whse_name
            ,itp.trans_id                         trans_id
            ,iimb.attribute15                     cost_mng_clss
            ,iimb.lot_ctl                         lot_ctl
            ,xlc.unit_ploce                       actual_unit_price
            ,CASE WHEN INSTR(xrpm.break_col_01,gv_hifn) = 0
                       THEN ''
                  WHEN xrpm.rcv_pay_div = gc_rcv_pay_div_in
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  ELSE SUBSTR(xrpm.break_col_01,INSTR(xrpm.break_col_01,gv_hifn) +1)
             END                                  column_no
            ,itp.reason_code                      reason_code
            ,itp.trans_date                       trans_date
            ,TO_CHAR(itp.trans_date, 'YYYYMM')  trans_ym
            ,CASE WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN TO_CHAR(ABS(TO_NUMBER(xrpm.rcv_pay_div)))
                  ELSE xrpm.rcv_pay_div
             END                                  rcv_pay_div
            ,xrpm.dealings_div                    dealings_div
            ,itp.doc_type                         doc_type
            ,ir_param.item_class                  item_div
            ,ir_param.goods_class                 prod_div
            ,mcb3.segment1                        crowd_code
            ,SUBSTR(mcb3.segment1, 1, 3)          crowd_low
            ,SUBSTR(mcb3.segment1, 1, 2)          crowd_mid
            ,SUBSTR(mcb3.segment1, 1, 1)          crowd_high
            ,iimb.item_id                         item_id
            ,itp.lot_id                           lot_id
            ,NVL(itp.trans_qty, 0)                trans_qty
            ,xoha.arrival_date                    arrival_date
            ,TO_CHAR(xoha.arrival_date, gc_char_ym_format) arrival_ym
            ,iimb.item_no                         item_code
            ,ximb.item_short_name                 item_name
      FROM   ic_tran_pnd                      itp
            ,rcv_shipment_lines               rsl
            ,oe_order_headers_all             ooha
            ,oe_transaction_types_all         otta
            ,xxwsh_order_headers_all          xoha
            ,xxwsh_order_lines_all            xola
            ,ic_item_mst_b                    iimb
            ,ic_item_mst_b                    iimb2
            ,xxcmn_item_mst_b                 ximb
            ,ic_lots_mst                      ilm
            ,xxcmn_lot_cost                   xlc
            ,gmi_item_categories              gic1
            ,mtl_categories_b                 mcb1
            ,gmi_item_categories              gic2
            ,mtl_categories_b                 mcb2
            ,gmi_item_categories              gic3
            ,mtl_categories_b                 mcb3
            ,gmi_item_categories              gic4
            ,mtl_categories_b                 mcb4
            ,xxcmn_rcv_pay_mst                xrpm
            ,ic_whse_mst                      iwm
      WHERE  itp.doc_type            = gv_doc_type_porc
      AND    itp.completed_ind       = 1
      AND    xoha.latest_external_flag = 'Y'
      AND    xoha.arrival_date > FND_DATE.STRING_TO_DATE(gd_prv1_dt_chr,gc_char_dt_format)
      AND    xoha.arrival_date < FND_DATE.STRING_TO_DATE(gd_flw_dt_chr,gc_char_dt_format)
      AND    xoha.req_status         = '04'
      AND    ilm.item_id             = itp.item_id
      AND    ilm.lot_id              = itp.lot_id
      AND    iimb.item_id            = itp.item_id
      AND    iimb2.item_no           = xola.request_item_code
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(itp.trans_date)
      AND    ximb.end_date_active   >= TRUNC(itp.trans_date)
      AND    gic1.item_id            = itp.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = itp.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    gic3.item_id            = itp.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
      AND    gic4.item_id            = iimb2.item_id
      AND    gic4.category_set_id    = cn_item_class_id
      AND    gic4.category_id        = mcb4.category_id
      AND    rsl.shipment_header_id  = itp.doc_id
      AND    rsl.line_num            = itp.doc_line
      AND    rsl.oe_order_header_id  = xoha.header_id
      AND    rsl.oe_order_line_id    = xola.line_id
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    ((otta.attribute4           <> '2')
             OR  (otta.attribute4       IS NULL))
      AND    xoha.header_id          = ooha.header_id
      AND    xola.order_header_id    = xoha.order_header_id
      AND    xrpm.doc_type           = itp.doc_type
      AND    xrpm.source_document_code = 'RMA'
      AND    xrpm.dealings_div       = '113'
      AND    xrpm.shipment_provision_div = DECODE(xoha.req_status,'04','1','08','2')
      AND    xrpm.item_div_ahead     = mcb4.segment1
      AND    mcb2.segment1           <> '5'
      AND    xrpm.break_col_01       IS NOT NULL
      AND    iwm.whse_code           = itp.whse_code
      AND    iwm.whse_code           = ir_param.locat_code
      AND    mcb3.segment1           = lt_crowd_code
-- 2009/03/05 v1.31 ADD START
      AND    iwm.attribute1          = '0'
-- 2009/03/05 v1.31 ADD END
      UNION ALL
      SELECT /*+ leading (xoha ooha otta xola rsl itp gic1 mcb1 gic2 mcb2) use_nl (xoha ooha otta xola rsl itp gic1 mcb1 gic2 mcb2) */
             iwm.whse_code                        h_whse_code
            ,iwm.whse_name                        h_whse_name
            ,itp.trans_id                         trans_id
            ,iimb.attribute15                     cost_mng_clss
            ,iimb.lot_ctl                         lot_ctl
            ,xlc.unit_ploce                       actual_unit_price
            ,CASE WHEN INSTR(xrpm.break_col_01,gv_hifn) = 0
                       THEN ''
                  WHEN xrpm.rcv_pay_div = gc_rcv_pay_div_in
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  ELSE SUBSTR(xrpm.break_col_01,INSTR(xrpm.break_col_01,gv_hifn) +1)
             END                                  column_no
            ,itp.reason_code                      reason_code
            ,itp.trans_date                       trans_date
            ,TO_CHAR(itp.trans_date, 'YYYYMM')  trans_ym
            ,CASE WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN TO_CHAR(ABS(TO_NUMBER(xrpm.rcv_pay_div)))
                  ELSE xrpm.rcv_pay_div
             END                                  rcv_pay_div
            ,xrpm.dealings_div                    dealings_div
            ,itp.doc_type                         doc_type
            ,ir_param.item_class                  item_div
            ,ir_param.goods_class                 prod_div
            ,mcb3.segment1                        crowd_code
            ,SUBSTR(mcb3.segment1, 1, 3)          crowd_low
            ,SUBSTR(mcb3.segment1, 1, 2)          crowd_mid
            ,SUBSTR(mcb3.segment1, 1, 1)          crowd_high
            ,itp.item_id                          item_id
            ,itp.lot_id                           lot_id
            ,NVL(itp.trans_qty, 0)                trans_qty
            ,xoha.arrival_date                    arrival_date
            ,TO_CHAR(xoha.arrival_date, gc_char_ym_format) arrival_ym
            ,iimb.item_no                         item_code
            ,ximb.item_short_name                 item_name
      FROM   ic_tran_pnd                      itp
            ,rcv_shipment_lines               rsl
            ,oe_order_headers_all             ooha
            ,oe_transaction_types_all         otta
            ,xxwsh_order_headers_all          xoha
            ,xxwsh_order_lines_all            xola
            ,ic_item_mst_b                    iimb
            ,xxcmn_item_mst_b                 ximb
            ,ic_lots_mst                      ilm
            ,xxcmn_lot_cost                   xlc
            ,gmi_item_categories              gic1
            ,mtl_categories_b                 mcb1
            ,gmi_item_categories              gic2
            ,mtl_categories_b                 mcb2
            ,gmi_item_categories              gic3
            ,mtl_categories_b                 mcb3
            ,xxcmn_rcv_pay_mst                xrpm
            ,ic_whse_mst                      iwm
      WHERE  itp.doc_type            = gv_doc_type_porc
      AND    itp.completed_ind       = 1
      AND    xoha.latest_external_flag = 'Y'
      AND    xoha.arrival_date > FND_DATE.STRING_TO_DATE(gd_prv1_dt_chr,gc_char_dt_format)
      AND    xoha.arrival_date < FND_DATE.STRING_TO_DATE(gd_flw_dt_chr,gc_char_dt_format)
      AND    ilm.item_id             = itp.item_id
      AND    ilm.lot_id              = itp.lot_id
      AND    iimb.item_id            = itp.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(itp.trans_date)
      AND    ximb.end_date_active   >= TRUNC(itp.trans_date)
      AND    gic1.item_id            = itp.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = itp.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    gic3.item_id            = itp.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
      AND    rsl.shipment_header_id  = itp.doc_id
      AND    rsl.line_num            = itp.doc_line
      AND    rsl.oe_order_header_id  = xoha.header_id
      AND    rsl.oe_order_line_id    = xola.line_id
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    otta.attribute4         = '2'
      AND    xoha.header_id          = ooha.header_id
      AND    xola.order_header_id    = xoha.order_header_id
      AND    xrpm.doc_type           = itp.doc_type
      AND    xrpm.source_document_code = 'RMA'
      AND    xrpm.dealings_div       IN ('504','509')
      AND    xrpm.stock_adjustment_div = otta.attribute4
      AND    xrpm.ship_prov_rcv_pay_category = otta.attribute11
      AND    xrpm.break_col_01       IS NOT NULL
      AND    iwm.whse_code           = itp.whse_code
      AND    iwm.whse_code           = ir_param.locat_code
      AND    mcb3.segment1           = lt_crowd_code
-- 2009/03/05 v1.31 ADD START
      AND    iwm.attribute1          = '0'
-- 2009/03/05 v1.31 ADD END
      UNION ALL
      SELECT /*+ leading (itp gic1 mcb1 gic2 mcb2) use_nl (itp gic1 mcb1 gic2 mcb2) */
             iwm.whse_code                        h_whse_code
            ,iwm.whse_name                        h_whse_name
-- v1.33 Mod Start
--            ,itp.trans_id                         trans_id
            ,NULL                                 trans_id
-- v1.33 Mod End
            ,iimb.attribute15                     cost_mng_clss
            ,iimb.lot_ctl                         lot_ctl
            ,xlc.unit_ploce                       actual_unit_price
            ,CASE WHEN INSTR(xrpm.break_col_01,gv_hifn) = 0
                       THEN ''
                  WHEN xrpm.rcv_pay_div = gc_rcv_pay_div_in
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  ELSE SUBSTR(xrpm.break_col_01,INSTR(xrpm.break_col_01,gv_hifn) +1)
             END                                  column_no
            ,itp.reason_code                      reason_code
            ,itp.trans_date                       trans_date
            ,TO_CHAR(itp.trans_date, 'YYYYMM')  trans_ym
            ,CASE WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN TO_CHAR(ABS(TO_NUMBER(xrpm.rcv_pay_div)))
                  ELSE xrpm.rcv_pay_div
             END                                  rcv_pay_div
            ,xrpm.dealings_div                    dealings_div
            ,itp.doc_type                         doc_type
            ,ir_param.item_class                  item_div
            ,ir_param.goods_class                 prod_div
            ,mcb3.segment1                        crowd_code
            ,SUBSTR(mcb3.segment1, 1, 3)          crowd_low
            ,SUBSTR(mcb3.segment1, 1, 2)          crowd_mid
            ,SUBSTR(mcb3.segment1, 1, 1)          crowd_high
            ,itp.item_id                          item_id
            ,itp.lot_id                           lot_id
-- v1.33 Mod Start
--            ,NVL(itp.trans_qty, 0)                trans_qty
            ,SUM(NVL(itp.trans_qty, 0))           trans_qty
-- v1.33 Mod End
            ,itp.trans_date                       arrival_date
            ,TO_CHAR(itp.trans_date, gc_char_ym_format) arrival_ym
            ,iimb.item_no                         item_code
            ,ximb.item_short_name                 item_name
      FROM   ic_tran_pnd                      itp
            ,ic_item_mst_b                    iimb
            ,xxcmn_item_mst_b                 ximb
            ,ic_lots_mst                      ilm
            ,xxcmn_lot_cost                   xlc
            ,gmi_item_categories              gic1
            ,mtl_categories_b                 mcb1
            ,gmi_item_categories              gic2
            ,mtl_categories_b                 mcb2
            ,gmi_item_categories              gic3
            ,mtl_categories_b                 mcb3
            ,rcv_shipment_lines               rsl
            ,rcv_transactions                 rt
            ,xxcmn_rcv_pay_mst                xrpm
            ,ic_whse_mst                      iwm
      WHERE  itp.doc_type            = gv_doc_type_porc
      AND    itp.completed_ind       = 1
      AND    itp.trans_date > FND_DATE.STRING_TO_DATE(gd_prv1_dt_chr,gc_char_dt_format)
      AND    itp.trans_date < FND_DATE.STRING_TO_DATE(gd_flw_dt_chr,gc_char_dt_format)
      AND    ilm.item_id             = itp.item_id
      AND    ilm.lot_id              = itp.lot_id
      AND    iimb.item_id            = ilm.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(itp.trans_date)
      AND    ximb.end_date_active   >= TRUNC(itp.trans_date)
      AND    gic1.item_id            = itp.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = itp.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    gic3.item_id            = itp.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
      AND    rsl.shipment_header_id  = itp.doc_id
      AND    rsl.line_num            = itp.doc_line
      AND    rt.transaction_id       = itp.line_id
      AND    rt.shipment_line_id     = rsl.shipment_line_id
      AND    xrpm.doc_type           = itp.doc_type
      AND    xrpm.source_document_code = rsl.source_document_code
      AND    xrpm.transaction_type   = rt.transaction_type
      AND    xrpm.break_col_01       IS NOT NULL
      AND    iwm.whse_code           = itp.whse_code
      AND    iwm.whse_code           = ir_param.locat_code
      AND    mcb3.segment1           = lt_crowd_code
-- 2009/03/05 v1.31 ADD START
      AND    iwm.attribute1          = '0'
-- 2009/03/05 v1.31 ADD END
-- v1.33 Add Start
      GROUP BY
             iwm.whse_code                        -- h_whse_code
            ,iwm.whse_name                        -- h_whse_name
            ,iimb.attribute15                     -- cost_mng_clss
            ,iimb.lot_ctl                         -- lot_ctl
            ,xlc.unit_ploce                       -- actual_unit_price
            ,CASE WHEN INSTR(xrpm.break_col_01,gv_hifn) = 0
                       THEN ''
                  WHEN xrpm.rcv_pay_div = gc_rcv_pay_div_in
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  ELSE SUBSTR(xrpm.break_col_01,INSTR(xrpm.break_col_01,gv_hifn) +1)
             END                                  -- column_no
            ,itp.reason_code                      -- reason_code
            ,itp.trans_date                       -- trans_date
            ,TO_CHAR(itp.trans_date, 'YYYYMM')    -- trans_ym
            ,CASE WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN TO_CHAR(ABS(TO_NUMBER(xrpm.rcv_pay_div)))
                  ELSE xrpm.rcv_pay_div
             END                                  -- rcv_pay_div
            ,xrpm.dealings_div                    -- dealings_div
            ,itp.doc_type                         -- doc_type
            ,ir_param.item_class                  -- item_div
            ,ir_param.goods_class                 -- prod_div
            ,mcb3.segment1                        -- crowd_code
            ,SUBSTR(mcb3.segment1, 1, 3)          -- crowd_low
            ,SUBSTR(mcb3.segment1, 1, 2)          -- crowd_mid
            ,SUBSTR(mcb3.segment1, 1, 1)          -- crowd_high
            ,itp.item_id                          -- item_id
            ,itp.lot_id                           -- lot_id
            ,itp.trans_date                       -- arrival_date
            ,TO_CHAR(itp.trans_date, gc_char_ym_format) -- arrival_ym
            ,iimb.item_no                         -- item_code
            ,ximb.item_short_name                 -- item_name
            ,rsl.attribute1                       -- 受入返品実績アドオン.取引ID
-- v1.33 Add End
      UNION ALL
      SELECT /*+ leading (xoha xola wdd itp gic1 mcb1 gic2 mcb2 ooha otta) use_nl (xoha xola wdd itp gic1 mcb1 gic2 mcb2 ooha otta) */
             iwm.whse_code                        h_whse_code
            ,iwm.whse_name                        h_whse_name
            ,itp.trans_id                         trans_id
            ,iimb.attribute15                     cost_mng_clss
            ,iimb.lot_ctl                         lot_ctl
            ,xlc.unit_ploce                       actual_unit_price
            ,CASE WHEN INSTR(xrpm.break_col_01,gv_hifn) = 0
                       THEN ''
                  WHEN xrpm.rcv_pay_div = gc_rcv_pay_div_in
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  ELSE SUBSTR(xrpm.break_col_01,INSTR(xrpm.break_col_01,gv_hifn) +1)
             END                                  column_no
            ,itp.reason_code                      reason_code
            ,itp.trans_date                       trans_date
            ,TO_CHAR(itp.trans_date, 'YYYYMM')  trans_ym
            ,CASE WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN TO_CHAR(ABS(TO_NUMBER(xrpm.rcv_pay_div)))
                  ELSE xrpm.rcv_pay_div
             END                                  rcv_pay_div
            ,xrpm.dealings_div                    dealings_div
            ,itp.doc_type                         doc_type
            ,ir_param.item_class                  item_div
            ,ir_param.goods_class                 prod_div
            ,mcb3.segment1                        crowd_code
            ,SUBSTR(mcb3.segment1, 1, 3)          crowd_low
            ,SUBSTR(mcb3.segment1, 1, 2)          crowd_mid
            ,SUBSTR(mcb3.segment1, 1, 1)          crowd_high
            ,itp.item_id                          item_id
            ,itp.lot_id                           lot_id
            ,NVL(itp.trans_qty, 0)                trans_qty
            ,xoha.arrival_date                    arrival_date
            ,TO_CHAR(xoha.arrival_date, gc_char_ym_format) arrival_ym
            ,iimb.item_no                         item_code
            ,ximb.item_short_name                 item_name
      FROM   ic_tran_pnd                      itp
            ,wsh_delivery_details             wdd
            ,oe_order_headers_all             ooha
            ,oe_transaction_types_all         otta
            ,xxwsh_order_headers_all          xoha
            ,xxwsh_order_lines_all            xola
            ,ic_item_mst_b                    iimb
            ,xxcmn_item_mst_b                 ximb
            ,ic_lots_mst                      ilm
            ,xxcmn_lot_cost                   xlc
            ,gmi_item_categories              gic1
            ,mtl_categories_b                 mcb1
            ,gmi_item_categories              gic2
            ,mtl_categories_b                 mcb2
            ,gmi_item_categories              gic3
            ,mtl_categories_b                 mcb3
            ,xxcmn_rcv_pay_mst                xrpm
            ,ic_whse_mst                      iwm
      WHERE  itp.doc_type            = gv_doc_type_omso
      AND    itp.completed_ind       = 1
      AND    xoha.latest_external_flag = 'Y'
      AND    xoha.arrival_date > FND_DATE.STRING_TO_DATE(gd_prv2_dt_chr,gc_char_dt_format)
      AND    xoha.arrival_date < FND_DATE.STRING_TO_DATE(gd_flw_dt_chr,gc_char_dt_format)
      AND    xoha.req_status         IN ('04','08')
      AND    ilm.item_id             = itp.item_id
      AND    ilm.lot_id              = itp.lot_id
      AND    iimb.item_id            = ilm.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(itp.trans_date)
      AND    ximb.end_date_active   >= TRUNC(itp.trans_date)
      AND    gic1.item_id            = itp.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = itp.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    gic3.item_id            = itp.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
      AND    wdd.delivery_detail_id  = itp.line_detail_id
      AND    wdd.source_header_id    = xoha.header_id
      AND    wdd.source_line_id      = xola.line_id
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    ((otta.attribute4           <> '2')
             OR  (otta.attribute4       IS NULL))
      AND    otta.attribute1         IN ('1','2')
      AND    xoha.header_id          = ooha.header_id
      AND    xola.order_header_id    = xoha.order_header_id
      AND    xola.request_item_code  = xola.shipping_item_code
      AND    xrpm.doc_type           = itp.doc_type
      AND    xrpm.dealings_div       IN ('101','103')
      AND    xrpm.shipment_provision_div = DECODE(xoha.req_status,'04','1','08','2')
      AND    xrpm.shipment_provision_div = otta.attribute1
      AND    ((xrpm.ship_prov_rcv_pay_category IS NULL)
             OR (xrpm.ship_prov_rcv_pay_category = otta.attribute11))
      AND    xrpm.break_col_01       IS NOT NULL
      AND    xrpm.item_div_origin    IS NULL
      AND    xrpm.item_div_ahead     IS NULL
      AND    iwm.whse_code           = itp.whse_code
      AND    iwm.whse_code           = ir_param.locat_code
      AND    mcb3.segment1           = lt_crowd_code
-- 2009/03/05 v1.31 ADD START
      AND    iwm.attribute1          = '0'
-- 2009/03/05 v1.31 ADD END
      UNION ALL
      SELECT /*+ leading (xoha xola wdd itp gic1 mcb1 gic2 mcb2 ooha otta xrpm) use_nl (xoha xola wdd itp gic1 mcb1 gic2 mcb2 ooha otta xrpm) */
             iwm.whse_code                        h_whse_code
            ,iwm.whse_name                        h_whse_name
            ,itp.trans_id                         trans_id
            ,iimb.attribute15                     cost_mng_clss
            ,iimb.lot_ctl                         lot_ctl
            ,xlc.unit_ploce                       actual_unit_price
            ,CASE WHEN INSTR(xrpm.break_col_01,gv_hifn) = 0
                       THEN ''
                  WHEN xrpm.rcv_pay_div = gc_rcv_pay_div_in
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  ELSE SUBSTR(xrpm.break_col_01,INSTR(xrpm.break_col_01,gv_hifn) +1)
             END                                  column_no
            ,itp.reason_code                      reason_code
            ,itp.trans_date                       trans_date
            ,TO_CHAR(itp.trans_date, 'YYYYMM')  trans_ym
            ,CASE WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN TO_CHAR(ABS(TO_NUMBER(xrpm.rcv_pay_div)))
                  ELSE xrpm.rcv_pay_div
             END                                  rcv_pay_div
            ,xrpm.dealings_div                    dealings_div
            ,itp.doc_type                         doc_type
            ,ir_param.item_class                  item_div
            ,ir_param.goods_class                 prod_div
            ,mcb3.segment1                        crowd_code
            ,SUBSTR(mcb3.segment1, 1, 3)          crowd_low
            ,SUBSTR(mcb3.segment1, 1, 2)          crowd_mid
            ,SUBSTR(mcb3.segment1, 1, 1)          crowd_high
            ,iimb.item_id                         item_id
            ,itp.lot_id                           lot_id
            ,NVL(itp.trans_qty, 0)                trans_qty
            ,xoha.arrival_date                    arrival_date
            ,TO_CHAR(xoha.arrival_date, gc_char_ym_format) arrival_ym
            ,iimb.item_no                         item_code
            ,ximb.item_short_name                 item_name
      FROM   ic_tran_pnd                      itp
            ,wsh_delivery_details             wdd
            ,oe_order_headers_all             ooha
            ,oe_transaction_types_all         otta
            ,xxwsh_order_headers_all          xoha
            ,xxwsh_order_lines_all            xola
            ,ic_item_mst_b                    iimb
            ,ic_item_mst_b                    iimb2
            ,xxcmn_item_mst_b                 ximb
            ,ic_lots_mst                      ilm
            ,xxcmn_lot_cost                   xlc
            ,gmi_item_categories              gic1
            ,mtl_categories_b                 mcb1
            ,gmi_item_categories              gic2
            ,mtl_categories_b                 mcb2
            ,gmi_item_categories              gic3
            ,mtl_categories_b                 mcb3
            ,gmi_item_categories              gic4
            ,mtl_categories_b                 mcb4
            ,xxcmn_rcv_pay_mst                xrpm
            ,ic_whse_mst                      iwm
      WHERE  itp.doc_type            = gv_doc_type_omso
      AND    itp.completed_ind       = 1
      AND    xoha.latest_external_flag = 'Y'
      AND    xoha.arrival_date > FND_DATE.STRING_TO_DATE(gd_prv2_dt_chr,gc_char_dt_format)
      AND    xoha.arrival_date < FND_DATE.STRING_TO_DATE(gd_flw_dt_chr,gc_char_dt_format)
      AND    xoha.req_status         = '08'
      AND    ilm.item_id             = itp.item_id
      AND    ilm.lot_id              = itp.lot_id
      AND    iimb.item_id            = itp.item_id
      AND    iimb2.item_no           = xola.request_item_code
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(itp.trans_date)
      AND    ximb.end_date_active   >= TRUNC(itp.trans_date)
      AND    gic1.item_id            = itp.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = itp.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    gic3.item_id            = itp.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
      AND    gic4.item_id            = iimb2.item_id
      AND    gic4.category_set_id    = cn_item_class_id
      AND    gic4.category_id        = mcb4.category_id
      AND    wdd.delivery_detail_id  = itp.line_detail_id
      AND    wdd.source_header_id    = xoha.header_id
      AND    wdd.source_line_id      = xola.line_id
      AND    xola.order_header_id    = xoha.order_header_id
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    ((otta.attribute4           <> '2')
             OR  (otta.attribute4       IS NULL))
      AND    otta.attribute1         = '2'
      AND    xoha.header_id          = ooha.header_id
      AND    xrpm.doc_type           = itp.doc_type
      AND    xrpm.dealings_div       = '106'
      AND    xrpm.shipment_provision_div = DECODE(xoha.req_status,'04','1','08','2')
      AND    xrpm.shipment_provision_div = otta.attribute1
      AND    xrpm.ship_prov_rcv_pay_category = otta.attribute11
      AND    xrpm.item_div_ahead     = mcb4.segment1
      AND    mcb2.segment1           <> '5'
      AND    xrpm.break_col_01       IS NOT NULL
      AND    iwm.whse_code           = itp.whse_code
      AND    iwm.whse_code           = ir_param.locat_code
      AND    mcb3.segment1           = lt_crowd_code
-- 2009/03/05 v1.31 ADD START
      AND    iwm.attribute1          = '0'
-- 2009/03/05 v1.31 ADD END
      UNION ALL
      SELECT /*+ leading (xoha xola wdd itp gic1 mcb1 gic2 mcb2 ooha otta xrpm) use_nl (xoha xola wdd itp gic1 mcb1 gic2 mcb2 ooha otta xrpm) */
             iwm.whse_code                        h_whse_code
            ,iwm.whse_name                        h_whse_name
            ,itp.trans_id                         trans_id
            ,iimb.attribute15                     cost_mng_clss
            ,iimb.lot_ctl                         lot_ctl
            ,xlc.unit_ploce                       actual_unit_price
            ,CASE WHEN INSTR(xrpm.break_col_01,gv_hifn) = 0
                       THEN ''
                  WHEN xrpm.rcv_pay_div = gc_rcv_pay_div_in
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  ELSE SUBSTR(xrpm.break_col_01,INSTR(xrpm.break_col_01,gv_hifn) +1)
             END                                  column_no
            ,itp.reason_code                      reason_code
            ,itp.trans_date                       trans_date
            ,TO_CHAR(itp.trans_date, 'YYYYMM')  trans_ym
            ,CASE WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN TO_CHAR(ABS(TO_NUMBER(xrpm.rcv_pay_div)))
                  ELSE xrpm.rcv_pay_div
             END                                  rcv_pay_div
            ,xrpm.dealings_div                    dealings_div
            ,itp.doc_type                         doc_type
            ,ir_param.item_class                  item_div
            ,ir_param.goods_class                 prod_div
            ,mcb3.segment1                        crowd_code
            ,SUBSTR(mcb3.segment1, 1, 3)          crowd_low
            ,SUBSTR(mcb3.segment1, 1, 2)          crowd_mid
            ,SUBSTR(mcb3.segment1, 1, 1)          crowd_high
            ,iimb.item_id                         item_id
            ,itp.lot_id                           lot_id
            ,NVL(itp.trans_qty, 0)                trans_qty
            ,xoha.arrival_date                    arrival_date
            ,TO_CHAR(xoha.arrival_date, gc_char_ym_format) arrival_ym
            ,iimb.item_no                         item_code
            ,ximb.item_short_name                 item_name
      FROM   ic_tran_pnd                      itp
            ,wsh_delivery_details             wdd
            ,oe_order_headers_all             ooha
            ,oe_transaction_types_all         otta
            ,xxwsh_order_headers_all          xoha
            ,xxwsh_order_lines_all            xola
            ,ic_item_mst_b                    iimb
            ,ic_item_mst_b                    iimb2
            ,xxcmn_item_mst_b                 ximb
            ,ic_lots_mst                      ilm
            ,xxcmn_lot_cost                   xlc
            ,gmi_item_categories              gic1
            ,mtl_categories_b                 mcb1
            ,gmi_item_categories              gic2
            ,mtl_categories_b                 mcb2
            ,gmi_item_categories              gic3
            ,mtl_categories_b                 mcb3
            ,gmi_item_categories              gic4
            ,mtl_categories_b                 mcb4
            ,xxcmn_rcv_pay_mst                xrpm
            ,ic_whse_mst                      iwm
      WHERE  itp.doc_type            = gv_doc_type_omso
      AND    itp.completed_ind       = 1
      AND    xoha.latest_external_flag = 'Y'
      AND    xoha.arrival_date > FND_DATE.STRING_TO_DATE(gd_prv2_dt_chr,gc_char_dt_format)
      AND    xoha.arrival_date < FND_DATE.STRING_TO_DATE(gd_flw_dt_chr,gc_char_dt_format)
      AND    xoha.req_status         = '04'
      AND    ilm.item_id             = itp.item_id
      AND    ilm.lot_id              = itp.lot_id
      AND    iimb.item_id            = itp.item_id
      AND    iimb2.item_no           = xola.request_item_code
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(itp.trans_date)
      AND    ximb.end_date_active   >= TRUNC(itp.trans_date)
      AND    gic1.item_id            = itp.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = itp.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    gic3.item_id            = itp.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
      AND    gic4.item_id            = iimb2.item_id
      AND    gic4.category_set_id    = cn_item_class_id
      AND    gic4.category_id        = mcb4.category_id
      AND    wdd.delivery_detail_id  = itp.line_detail_id
      AND    wdd.source_header_id    = xoha.header_id
      AND    wdd.source_line_id      = xola.line_id
      AND    xola.order_header_id    = xoha.order_header_id
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    ((otta.attribute4           <> '2')
             OR  (otta.attribute4       IS NULL))
      AND    otta.attribute1         = '1'
      AND    xoha.header_id          = ooha.header_id
      AND    xrpm.doc_type           = itp.doc_type
      AND    xrpm.dealings_div       = '113'
      AND    xrpm.shipment_provision_div = DECODE(xoha.req_status,'04','1','08','2')
      AND    xrpm.item_div_ahead     = mcb4.segment1
      AND    mcb2.segment1           <> '5'
      AND    xrpm.break_col_01       IS NOT NULL
      AND    iwm.whse_code           = itp.whse_code
      AND    iwm.whse_code           = ir_param.locat_code
      AND    mcb3.segment1           = lt_crowd_code
-- 2009/03/05 v1.31 ADD START
      AND    iwm.attribute1          = '0'
-- 2009/03/05 v1.31 ADD END
      UNION ALL
      SELECT /*+ leading (xoha ooha otta xola wdd itp gic1 mcb1 gic2 mcb2) use_nl (xoha ooha otta xola wdd itp gic1 mcb1 gic2 mcb2) */
             iwm.whse_code                        h_whse_code
            ,iwm.whse_name                        h_whse_name
            ,itp.trans_id                         trans_id
            ,iimb.attribute15                     cost_mng_clss
            ,iimb.lot_ctl                         lot_ctl
            ,xlc.unit_ploce                       actual_unit_price
            ,CASE WHEN INSTR(xrpm.break_col_01,gv_hifn) = 0
                       THEN ''
                  WHEN xrpm.rcv_pay_div = gc_rcv_pay_div_in
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  ELSE SUBSTR(xrpm.break_col_01,INSTR(xrpm.break_col_01,gv_hifn) +1)
             END                                  column_no
            ,itp.reason_code                      reason_code
            ,itp.trans_date                       trans_date
            ,TO_CHAR(itp.trans_date, 'YYYYMM')  trans_ym
            ,CASE WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN TO_CHAR(ABS(TO_NUMBER(xrpm.rcv_pay_div)))
                  ELSE xrpm.rcv_pay_div
             END                                  rcv_pay_div
            ,xrpm.dealings_div                    dealings_div
            ,itp.doc_type                         doc_type
            ,ir_param.item_class                  item_div
            ,ir_param.goods_class                 prod_div
            ,mcb3.segment1                        crowd_code
            ,SUBSTR(mcb3.segment1, 1, 3)          crowd_low
            ,SUBSTR(mcb3.segment1, 1, 2)          crowd_mid
            ,SUBSTR(mcb3.segment1, 1, 1)          crowd_high
            ,itp.item_id                          item_id
            ,itp.lot_id                           lot_id
            ,NVL(itp.trans_qty, 0)                trans_qty
            ,xoha.arrival_date                    arrival_date
            ,TO_CHAR(xoha.arrival_date, gc_char_ym_format) arrival_ym
            ,iimb.item_no                         item_code
            ,ximb.item_short_name                 item_name
      FROM   ic_tran_pnd                      itp
            ,wsh_delivery_details             wdd
            ,oe_order_headers_all             ooha
            ,oe_transaction_types_all         otta
            ,xxwsh_order_headers_all          xoha
            ,xxwsh_order_lines_all            xola
            ,ic_item_mst_b                    iimb
            ,xxcmn_item_mst_b                 ximb
            ,ic_lots_mst                      ilm
            ,xxcmn_lot_cost                   xlc
            ,gmi_item_categories              gic1
            ,mtl_categories_b                 mcb1
            ,gmi_item_categories              gic2
            ,mtl_categories_b                 mcb2
            ,gmi_item_categories              gic3
            ,mtl_categories_b                 mcb3
            ,xxcmn_rcv_pay_mst                xrpm
            ,ic_whse_mst                      iwm
      WHERE  itp.doc_type            = gv_doc_type_omso
      AND    itp.completed_ind       = 1
      AND    xoha.latest_external_flag = 'Y'
      AND    xoha.arrival_date > FND_DATE.STRING_TO_DATE(gd_prv2_dt_chr,gc_char_dt_format)
      AND    xoha.arrival_date < FND_DATE.STRING_TO_DATE(gd_flw_dt_chr,gc_char_dt_format)
      AND    ilm.item_id             = itp.item_id
      AND    ilm.lot_id              = itp.lot_id
      AND    iimb.item_id            = itp.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(itp.trans_date)
      AND    ximb.end_date_active   >= TRUNC(itp.trans_date)
      AND    gic1.item_id            = itp.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = itp.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    gic3.item_id            = itp.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
      AND    wdd.delivery_detail_id  = itp.line_detail_id
      AND    wdd.source_header_id    = xoha.header_id
      AND    wdd.source_line_id      = xola.line_id
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    otta.attribute4         = '2'
      AND    xoha.header_id          = ooha.header_id
      AND    xola.order_header_id    = xoha.order_header_id
      AND    xrpm.doc_type           = itp.doc_type
      AND    xrpm.dealings_div       IN ('504','509')
      AND    xrpm.stock_adjustment_div = otta.attribute4
      AND    xrpm.ship_prov_rcv_pay_category = otta.attribute11
      AND    xrpm.break_col_01       IS NOT NULL
      AND    iwm.whse_code           = itp.whse_code
      AND    iwm.whse_code           = ir_param.locat_code
      AND    mcb3.segment1           = lt_crowd_code
-- 2009/03/05 v1.31 ADD START
      AND    iwm.attribute1          = '0'
-- 2009/03/05 v1.31 ADD END
      -- 当月受払無しデータ
      UNION ALL
      SELECT /*+ leading (xsims gic1 mcb1 gic2 mcb2 gic3 mcb3 iimb ximb xlc) use_nl (xsims gic1 mcb1 gic2 mcb2 gic3 mcb3 iimb ximb xlc) */
             iwm.whse_code                        h_whse_code
            ,iwm.whse_name                        h_whse_name
            ,NULL                                 trans_id
            ,iimb.attribute15                     cost_mng_clss
            ,iimb.lot_ctl                         lot_ctl
            ,xlc.unit_ploce                       actual_unit_price
            ,'1'                                  column_no
            ,NULL                                 reason_code
            ,gd_s_date                            trans_date
            ,TO_CHAR(gd_s_date, gc_char_ym_format)  trans_ym
            ,'1'                                  rcv_pay_div
            ,NULL                                 dealings_div
            ,NULL                                 doc_type
            ,ir_param.item_class                  item_div
            ,ir_param.goods_class                 prod_div
            ,mcb3.segment1                        crowd_code
            ,SUBSTR(mcb3.segment1, 1, 3)          crowd_low
            ,SUBSTR(mcb3.segment1, 1, 2)          crowd_mid
            ,SUBSTR(mcb3.segment1, 1, 1)          crowd_high
            ,iimb.item_id                         item_id
            ,0                                    lot_id
            ,0                                    trans_qty
            ,gd_s_date                            arrival_date
            ,TO_CHAR(gd_s_date, gc_char_ym_format)  arrival_ym
            ,iimb.item_no                         item_code
            ,ximb.item_short_name                 item_name
      FROM   xxinv_stc_inventory_month_stck   xsims
            ,ic_item_mst_b                    iimb
            ,xxcmn_item_mst_b                 ximb
            ,ic_lots_mst                      ilm
            ,xxcmn_lot_cost                   xlc
            ,gmi_item_categories              gic1
            ,mtl_categories_b                 mcb1
            ,gmi_item_categories              gic2
            ,mtl_categories_b                 mcb2
            ,gmi_item_categories              gic3
            ,mtl_categories_b                 mcb3
            ,ic_whse_mst                      iwm
      WHERE  xsims.item_id           = iimb.item_id
      AND    ximb.item_id            = iimb.item_id
      AND    ilm.item_id             = xsims.item_id
      AND    ilm.lot_id              = xsims.lot_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.start_date_active <= gd_s_date
      AND    ximb.end_date_active   >= gd_s_date
      AND    gic1.item_id            = xsims.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = xsims.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    gic3.item_id            = xsims.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
      AND    iwm.whse_code           = xsims.whse_code
      AND    xsims.invent_ym         = TO_CHAR(gd_s_date, gc_char_ym_format)
      AND    iwm.whse_code           = ir_param.locat_code
      AND    mcb3.segment1           = lt_crowd_code
-- 2008/12/10 v1.25 UPDATE START
--      AND    xsims.monthly_stock    <> 0
      AND    (
               (xsims.monthly_stock <> 0)
               OR
               (xsims.cargo_stock   <> 0)
             )
      AND    iwm.attribute1          = '0'
-- 2008/12/10 v1.25 UPDATE END
      ORDER BY h_whse_code
              ,crowd_code
              ,item_code
      ;
--
    --===============================================================
    -- 検索条件.帳票種別          ⇒ 倉庫・品目別
    -- 検索条件.群種別            ⇒ 群別
    -- 検索条件.倉庫コード        ⇒ 入力あり
    -- 検索条件.群コード          ⇒ 入力なし
    -- 検索条件.経理群コード      ⇒ 入力なし/入力あり
    --===============================================================
    CURSOR get_data_cur04 IS
      SELECT /*+ leading (xmrh xmril ixm itp gic2 mcb2 gic1 mcb1 iimb ximb) use_nl (xmrh xmril ixm itp gic2 mcb2 gic1 mcb1 iimb ximb) */
             iwm.whse_code                        h_whse_code
            ,iwm.whse_name                        h_whse_name
            ,itp.trans_id                         trans_id
            ,iimb.attribute15                     cost_mng_clss
            ,iimb.lot_ctl                         lot_ctl
            ,xlc.unit_ploce                       actual_unit_price
            ,CASE WHEN INSTR(xrpm.break_col_01,gv_hifn) = 0
                       THEN ''
                  WHEN xrpm.rcv_pay_div = gc_rcv_pay_div_in
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  ELSE SUBSTR(xrpm.break_col_01,INSTR(xrpm.break_col_01,gv_hifn) +1)
             END                                  column_no
            ,itp.reason_code                      reason_code
            ,itp.trans_date                       trans_date
            ,TO_CHAR(itp.trans_date, 'YYYYMM')  trans_ym
            ,CASE WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN TO_CHAR(ABS(TO_NUMBER(xrpm.rcv_pay_div)))
                  ELSE xrpm.rcv_pay_div
             END                                  rcv_pay_div
            ,xrpm.dealings_div                    dealings_div
            ,itp.doc_type                         doc_type
            ,ir_param.item_class                  item_div
            ,ir_param.goods_class                 prod_div
            ,mcb3.segment1                        crowd_code
            ,SUBSTR(mcb3.segment1, 1, 3)          crowd_low
            ,SUBSTR(mcb3.segment1, 1, 2)          crowd_mid
            ,SUBSTR(mcb3.segment1, 1, 1)          crowd_high
            ,itp.item_id                          item_id
            ,itp.lot_id                           lot_id
            ,NVL(itp.trans_qty, 0)                trans_qty
            ,xmrh.actual_arrival_date             arrival_date
            ,TO_CHAR(xmrh.actual_arrival_date, gc_char_ym_format) arrival_ym
            ,iimb.item_no                         item_code
            ,ximb.item_short_name                 item_name
      FROM   ic_tran_pnd                      itp
            ,ic_xfer_mst                      ixm
            ,xxinv_mov_req_instr_headers      xmrh
            ,xxinv_mov_req_instr_lines        xmril
            ,ic_item_mst_b                    iimb
            ,xxcmn_item_mst_b                 ximb
            ,ic_lots_mst                      ilm
            ,xxcmn_lot_cost                   xlc
            ,gmi_item_categories              gic1
            ,mtl_categories_b                 mcb1
            ,gmi_item_categories              gic2
            ,mtl_categories_b                 mcb2
            ,gmi_item_categories              gic3
            ,mtl_categories_b                 mcb3
            ,xxcmn_rcv_pay_mst                xrpm
            ,ic_whse_mst                      iwm
      WHERE  itp.doc_type            = gv_doc_type_xfer
      AND    itp.reason_code         = gv_reason_code_xfer
      AND    itp.completed_ind       = 1
      AND    xmrh.actual_arrival_date > FND_DATE.STRING_TO_DATE(gd_prv1_dt_chr,gc_char_dt_format)
      AND    xmrh.actual_arrival_date < FND_DATE.STRING_TO_DATE(gd_flw_dt_chr,gc_char_dt_format)
      AND    xmrh.mov_hdr_id         = xmril.mov_hdr_id
      AND    itp.doc_id              = ixm.transfer_id
      AND    ixm.attribute1          = TO_CHAR(xmril.mov_line_id)
      AND    ilm.item_id             = itp.item_id
      AND    ilm.lot_id              = itp.lot_id
      AND    iimb.item_id            = itp.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(itp.trans_date)
      AND    ximb.end_date_active   >= TRUNC(itp.trans_date)
      AND    gic1.item_id            = itp.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = itp.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    gic3.item_id            = itp.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
      AND    xrpm.rcv_pay_div        = CASE
                                       WHEN itp.trans_qty >= 0 THEN 1
                                       ELSE -1
                                       END
      AND    xrpm.doc_type           = itp.doc_type
      AND    xrpm.reason_code        = itp.reason_code
      AND    xrpm.break_col_01       IS NOT NULL
      AND    iwm.whse_code           = itp.whse_code
      AND    iwm.whse_code           = ir_param.locat_code
-- 2009/03/05 v1.31 ADD START
      AND    iwm.attribute1          = '0'
-- 2009/03/05 v1.31 ADD END
      UNION ALL
      SELECT /*+ leading (xmrh xmril ijm iaj itc gic2 mcb2 gic1 mcb1 ilm iimb ximb) use_nl (xmrh xmril ijm iaj itc gic2 mcb2 gic1 mcb1 ilm iimb ximb) */
             iwm.whse_code                        h_whse_code
            ,iwm.whse_name                        h_whse_name
            ,itc.trans_id                         trans_id
            ,iimb.attribute15                     cost_mng_clss
            ,iimb.lot_ctl                         lot_ctl
            ,xlc.unit_ploce                       actual_unit_price
            ,CASE WHEN INSTR(xrpm.break_col_01,gv_hifn) = 0
                       THEN ''
                  WHEN xrpm.rcv_pay_div = gc_rcv_pay_div_in
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  ELSE SUBSTR(xrpm.break_col_01,INSTR(xrpm.break_col_01,gv_hifn) +1)
             END                                  column_no
            ,itc.reason_code                      reason_code
            ,itc.trans_date                       trans_date
            ,TO_CHAR(itc.trans_date, 'YYYYMM')  trans_ym
            ,CASE WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN TO_CHAR(ABS(TO_NUMBER(xrpm.rcv_pay_div)))
                  ELSE xrpm.rcv_pay_div
             END                                  rcv_pay_div
            ,xrpm.dealings_div                    dealings_div
            ,itc.doc_type                         doc_type
            ,ir_param.item_class                  item_div
            ,ir_param.goods_class                 prod_div
            ,mcb3.segment1                        crowd_code
            ,SUBSTR(mcb3.segment1, 1, 3)          crowd_low
            ,SUBSTR(mcb3.segment1, 1, 2)          crowd_mid
            ,SUBSTR(mcb3.segment1, 1, 1)          crowd_high
            ,itc.item_id                          item_id
            ,itc.lot_id                           lot_id
            ,NVL(itc.trans_qty, 0)                trans_qty
            ,xmrh.actual_arrival_date             arrival_date
            ,TO_CHAR(xmrh.actual_arrival_date, gc_char_ym_format) arrival_ym
            ,iimb.item_no                         item_code
            ,ximb.item_short_name                 item_name
      FROM   ic_tran_cmp                      itc
            ,ic_adjs_jnl                      iaj
            ,ic_jrnl_mst                      ijm
            ,xxinv_mov_req_instr_headers      xmrh
            ,xxinv_mov_req_instr_lines        xmril
            ,ic_item_mst_b                    iimb
            ,xxcmn_item_mst_b                 ximb
            ,ic_lots_mst                      ilm
            ,xxcmn_lot_cost                   xlc
            ,gmi_item_categories              gic1
            ,mtl_categories_b                 mcb1
            ,gmi_item_categories              gic2
            ,mtl_categories_b                 mcb2
            ,gmi_item_categories              gic3
            ,mtl_categories_b                 mcb3
            ,xxcmn_rcv_pay_mst                xrpm
            ,ic_whse_mst                      iwm
      WHERE  itc.doc_type            = gv_doc_type_trni
      AND    itc.reason_code         = gv_reason_code_trni
      AND    xmrh.actual_arrival_date > FND_DATE.STRING_TO_DATE(gd_prv1_dt_chr,gc_char_dt_format)
      AND    xmrh.actual_arrival_date < FND_DATE.STRING_TO_DATE(gd_flw_dt_chr,gc_char_dt_format)
      AND    xmrh.mov_hdr_id         = xmril.mov_hdr_id
      AND    itc.doc_type            = iaj.trans_type
      AND    itc.doc_id              = iaj.doc_id
      AND    itc.doc_line            = iaj.doc_line
      AND    ijm.journal_id          = iaj.journal_id
      AND    ijm.attribute1          = TO_CHAR(xmril.mov_line_id)
      AND    ilm.item_id             = itc.item_id
      AND    ilm.lot_id              = itc.lot_id
      AND    iimb.item_id            = ilm.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(itc.trans_date)
      AND    ximb.end_date_active   >= TRUNC(itc.trans_date)
      AND    gic1.item_id            = itc.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = itc.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    gic3.item_id            = itc.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
-- 2008/11/19 v1.18 ADD START
      AND    xrpm.rcv_pay_div        = CASE
                                       WHEN itc.trans_qty >= 0 THEN 1
                                       ELSE -1
                                       END
-- 2008/11/19 v1.18 ADD END
      AND    xrpm.doc_type           = itc.doc_type
      AND    xrpm.reason_code        = itc.reason_code
      AND    xrpm.rcv_pay_div        = itc.line_type
      AND    xrpm.break_col_01       IS NOT NULL
      AND    iwm.whse_code           = itc.whse_code
      AND    iwm.whse_code           = ir_param.locat_code
-- 2009/03/05 v1.31 ADD START
      AND    iwm.attribute1          = '0'
-- 2009/03/05 v1.31 ADD END
      UNION ALL
      SELECT /*+ leading (itc gic1 mcb1 gic2 mcb2) use_nl (itc gic1 mcb1 gic2 mcb2)*/
             iwm.whse_code                        h_whse_code
            ,iwm.whse_name                        h_whse_name
            ,itc.trans_id                         trans_id
            ,iimb.attribute15                     cost_mng_clss
            ,iimb.lot_ctl                         lot_ctl
            ,xlc.unit_ploce                       actual_unit_price
            ,CASE WHEN INSTR(xrpm.break_col_01,gv_hifn) = 0
                       THEN ''
                  WHEN xrpm.rcv_pay_div = gc_rcv_pay_div_in
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  ELSE SUBSTR(xrpm.break_col_01,INSTR(xrpm.break_col_01,gv_hifn) +1)
             END                                  column_no
            ,itc.reason_code                      reason_code
            ,itc.trans_date                       trans_date
            ,TO_CHAR(itc.trans_date, 'YYYYMM')  trans_ym
            ,CASE WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN TO_CHAR(ABS(TO_NUMBER(xrpm.rcv_pay_div)))
                  ELSE xrpm.rcv_pay_div
             END                                  rcv_pay_div
            ,xrpm.dealings_div                    dealings_div
            ,itc.doc_type                         doc_type
            ,ir_param.item_class                  item_div
            ,ir_param.goods_class                 prod_div
            ,mcb3.segment1                        crowd_code
            ,SUBSTR(mcb3.segment1, 1, 3)          crowd_low
            ,SUBSTR(mcb3.segment1, 1, 2)          crowd_mid
            ,SUBSTR(mcb3.segment1, 1, 1)          crowd_high
            ,itc.item_id                          item_id
            ,itc.lot_id                           lot_id
            ,NVL(itc.trans_qty, 0)                trans_qty
            ,itc.trans_date                       arrival_date
            ,TO_CHAR(itc.trans_date, gc_char_ym_format) arrival_ym
            ,iimb.item_no                         item_code
            ,ximb.item_short_name                 item_name
      FROM   ic_tran_cmp                      itc
            ,ic_item_mst_b                    iimb
            ,xxcmn_item_mst_b                 ximb
            ,ic_lots_mst                      ilm
            ,xxcmn_lot_cost                   xlc
            ,gmi_item_categories              gic1
            ,mtl_categories_b                 mcb1
            ,gmi_item_categories              gic2
            ,mtl_categories_b                 mcb2
            ,gmi_item_categories              gic3
            ,mtl_categories_b                 mcb3
            ,xxcmn_rcv_pay_mst                xrpm
            ,ic_whse_mst                      iwm
      WHERE  itc.doc_type            = gv_doc_type_adji    --文書タイプ
      AND    itc.reason_code        IN ('X911'
                                       ,'X912'
                                       ,'X921'
                                       ,'X922'
                                       ,'X931'
                                       ,'X932'
                                       ,'X941'
                                       ,'X952'
                                       ,'X953'
                                       ,'X954'
                                       ,'X955'
                                       ,'X956'
                                       ,'X957'
                                       ,'X958'
                                       ,'X959'
                                       ,'X960'
                                       ,'X961'
                                       ,'X962'
                                       ,'X963'
-- 2008/11/19 v1.18 UPDATE START
--                                       ,'X964')
                                       ,'X964'
                                       ,'X965'
                                       ,'X966')
-- 2008/11/19 v1.18 UPDATE END
      AND    itc.trans_date > FND_DATE.STRING_TO_DATE(gd_prv1_dt_chr,gc_char_dt_format)
      AND    itc.trans_date < FND_DATE.STRING_TO_DATE(gd_flw_dt_chr,gc_char_dt_format)
      AND    ilm.item_id             = itc.item_id
      AND    ilm.lot_id              = itc.lot_id
      AND    iimb.item_id            = ilm.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(itc.trans_date)
      AND    ximb.end_date_active   >= TRUNC(itc.trans_date)
      AND    gic1.item_id            = itc.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = itc.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    gic3.item_id            = itc.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
      AND    xrpm.doc_type           = itc.doc_type
      AND    xrpm.reason_code        = itc.reason_code
      AND    xrpm.break_col_01       IS NOT NULL
      AND    iwm.whse_code           = itc.whse_code
      AND    iwm.whse_code           = ir_param.locat_code
-- 2009/03/05 v1.31 ADD START
      AND    iwm.attribute1          = '0'
-- 2009/03/05 v1.31 ADD END
      UNION ALL
      SELECT /*+ leading (itc gic1 mcb1 gic2 mcb2 xrpm) use_nl (itc gic1 mcb1 gic2 mcb2 xrpm) */
             iwm.whse_code                        h_whse_code
            ,iwm.whse_name                        h_whse_name
-- v1.33 Mod Start
--            ,itc.trans_id                         trans_id
            ,NULL                                 trans_id
-- v1.33 Mod End
            ,iimb.attribute15                     cost_mng_clss
            ,iimb.lot_ctl                         lot_ctl
            ,xlc.unit_ploce                       actual_unit_price
            ,CASE WHEN INSTR(xrpm.break_col_01,gv_hifn) = 0
                       THEN ''
                  WHEN xrpm.rcv_pay_div = gc_rcv_pay_div_in
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  ELSE SUBSTR(xrpm.break_col_01,INSTR(xrpm.break_col_01,gv_hifn) +1)
             END                                  column_no
            ,itc.reason_code                      reason_code
            ,itc.trans_date                       trans_date
            ,TO_CHAR(itc.trans_date, 'YYYYMM')  trans_ym
            ,CASE WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN TO_CHAR(ABS(TO_NUMBER(xrpm.rcv_pay_div)))
                  ELSE xrpm.rcv_pay_div
             END                                  rcv_pay_div
            ,xrpm.dealings_div                    dealings_div
            ,itc.doc_type                         doc_type
            ,ir_param.item_class                  item_div
            ,ir_param.goods_class                 prod_div
            ,mcb3.segment1                        crowd_code
            ,SUBSTR(mcb3.segment1, 1, 3)          crowd_low
            ,SUBSTR(mcb3.segment1, 1, 2)          crowd_mid
            ,SUBSTR(mcb3.segment1, 1, 1)          crowd_high
            ,itc.item_id                          item_id
            ,itc.lot_id                           lot_id
-- v1.33 Mod Start
--            ,NVL(itc.trans_qty, 0)                trans_qty
            ,SUM(NVL(itc.trans_qty, 0))           trans_qty
-- v1.33 Mod End
            ,itc.trans_date                       arrival_date
            ,TO_CHAR(itc.trans_date, gc_char_ym_format) arrival_ym
            ,iimb.item_no                         item_code
            ,ximb.item_short_name                 item_name
      FROM   ic_tran_cmp                      itc
-- v1.33 Add Start
            ,ic_adjs_jnl                      iaj
            ,ic_jrnl_mst                      ijm
-- v1.33 Add End
            ,ic_item_mst_b                    iimb
            ,xxcmn_item_mst_b                 ximb
            ,ic_lots_mst                      ilm
            ,xxcmn_lot_cost                   xlc
            ,gmi_item_categories              gic1
            ,mtl_categories_b                 mcb1
            ,gmi_item_categories              gic2
            ,mtl_categories_b                 mcb2
            ,gmi_item_categories              gic3
            ,mtl_categories_b                 mcb3
            ,xxcmn_rcv_pay_mst                xrpm
            ,ic_whse_mst                      iwm
      WHERE  itc.doc_type            = gv_doc_type_adji
      AND    itc.reason_code         = gv_reason_code_adji_po
      AND    itc.trans_date > FND_DATE.STRING_TO_DATE(gd_prv1_dt_chr,gc_char_dt_format)
      AND    itc.trans_date < FND_DATE.STRING_TO_DATE(gd_flw_dt_chr,gc_char_dt_format)
-- v1.33 Add Start
      AND    iaj.trans_type          = itc.doc_type
      AND    iaj.doc_id              = itc.doc_id
      AND    iaj.doc_line            = itc.doc_line
      AND    ijm.journal_id          = iaj.journal_id
-- v1.33 Add End
      AND    ilm.item_id             = itc.item_id
      AND    ilm.lot_id              = itc.lot_id
      AND    iimb.item_id            = ilm.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(itc.trans_date)
      AND    ximb.end_date_active   >= TRUNC(itc.trans_date)
      AND    gic1.item_id            = itc.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = itc.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    gic3.item_id            = itc.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
      AND    xrpm.doc_type           = itc.doc_type
      AND    xrpm.reason_code        = itc.reason_code
      AND    xrpm.break_col_01       IS NOT NULL
      AND    iwm.whse_code           = itc.whse_code
      AND    iwm.whse_code           = ir_param.locat_code
-- 2009/03/05 v1.31 ADD START
      AND    iwm.attribute1          = '0'
-- 2009/03/05 v1.31 ADD END
-- v1.33 Add Start
      GROUP BY
             iwm.whse_code                        -- h_whse_code
            ,iwm.whse_name                        -- h_whse_name
            ,iimb.attribute15                     -- cost_mng_clss
            ,iimb.lot_ctl                         -- lot_ctl
            ,xlc.unit_ploce                       -- actual_unit_price
            ,CASE WHEN INSTR(xrpm.break_col_01,gv_hifn) = 0
                       THEN ''
                  WHEN xrpm.rcv_pay_div = gc_rcv_pay_div_in
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  ELSE SUBSTR(xrpm.break_col_01,INSTR(xrpm.break_col_01,gv_hifn) +1)
             END                                  -- column_no
            ,itc.reason_code                      -- reason_code
            ,itc.trans_date                       -- trans_date
            ,TO_CHAR(itc.trans_date, 'YYYYMM')    -- trans_ym
            ,CASE WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN TO_CHAR(ABS(TO_NUMBER(xrpm.rcv_pay_div)))
                  ELSE xrpm.rcv_pay_div
             END                                  -- rcv_pay_div
            ,xrpm.dealings_div                    -- dealings_div
            ,itc.doc_type                         -- doc_type
            ,ir_param.item_class                  -- item_div
            ,ir_param.goods_class                 -- prod_div
            ,mcb3.segment1                        -- crowd_code
            ,SUBSTR(mcb3.segment1, 1, 3)          -- crowd_low
            ,SUBSTR(mcb3.segment1, 1, 2)          -- crowd_mid
            ,SUBSTR(mcb3.segment1, 1, 1)          -- crowd_high
            ,itc.item_id                          -- item_id
            ,itc.lot_id                           -- lot_id
            ,itc.trans_date                       -- arrival_date
            ,TO_CHAR(itc.trans_date, gc_char_ym_format) -- arrival_ym
            ,iimb.item_no                         -- item_code
            ,ximb.item_short_name                 -- item_name
            ,ijm.attribute1                       -- 受入返品実績アドオン.取引ID
-- v1.33 Add End
      UNION ALL
      SELECT /*+ leading (itc gic1 mcb1 gic2 mcb2 xrpm) use_nl (itc gic1 mcb1 gic2 mcb2 xrpm) */
             iwm.whse_code                        h_whse_code
            ,iwm.whse_name                        h_whse_name
            ,itc.trans_id                         trans_id
            ,iimb.attribute15                     cost_mng_clss
            ,iimb.lot_ctl                         lot_ctl
            ,xlc.unit_ploce                       actual_unit_price
            ,CASE WHEN INSTR(xrpm.break_col_01,gv_hifn) = 0
                       THEN ''
                  WHEN xrpm.rcv_pay_div = gc_rcv_pay_div_in
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  ELSE SUBSTR(xrpm.break_col_01,INSTR(xrpm.break_col_01,gv_hifn) +1)
             END                                  column_no
            ,itc.reason_code                      reason_code
            ,itc.trans_date                       trans_date
            ,TO_CHAR(itc.trans_date, 'YYYYMM')  trans_ym
            ,CASE WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN TO_CHAR(ABS(TO_NUMBER(xrpm.rcv_pay_div)))
                  ELSE xrpm.rcv_pay_div
             END                                  rcv_pay_div
            ,xrpm.dealings_div                    dealings_div
            ,itc.doc_type                         doc_type
            ,ir_param.item_class                  item_div
            ,ir_param.goods_class                 prod_div
            ,mcb3.segment1                        crowd_code
            ,SUBSTR(mcb3.segment1, 1, 3)          crowd_low
            ,SUBSTR(mcb3.segment1, 1, 2)          crowd_mid
            ,SUBSTR(mcb3.segment1, 1, 1)          crowd_high
            ,itc.item_id                          item_id
            ,itc.lot_id                           lot_id
            ,NVL(itc.trans_qty, 0)                trans_qty
            ,itc.trans_date                       arrival_date
            ,TO_CHAR(itc.trans_date, gc_char_ym_format) arrival_ym
            ,iimb.item_no                         item_code
            ,ximb.item_short_name                 item_name
      FROM   ic_tran_cmp                      itc
            ,ic_item_mst_b                    iimb
            ,xxcmn_item_mst_b                 ximb
            ,ic_lots_mst                      ilm
            ,xxcmn_lot_cost                   xlc
            ,gmi_item_categories              gic1
            ,mtl_categories_b                 mcb1
            ,gmi_item_categories              gic2
            ,mtl_categories_b                 mcb2
            ,gmi_item_categories              gic3
            ,mtl_categories_b                 mcb3
            ,xxcmn_rcv_pay_mst                xrpm
            ,ic_whse_mst                      iwm
      WHERE  itc.doc_type            = gv_doc_type_adji
      AND    itc.reason_code         = gv_reason_code_adji_hama
      AND    itc.trans_date > FND_DATE.STRING_TO_DATE(gd_prv1_dt_chr,gc_char_dt_format)
      AND    itc.trans_date < FND_DATE.STRING_TO_DATE(gd_flw_dt_chr,gc_char_dt_format)
      AND    ilm.item_id             = itc.item_id
      AND    ilm.lot_id              = itc.lot_id
      AND    iimb.item_id            = ilm.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(itc.trans_date)
      AND    ximb.end_date_active   >= TRUNC(itc.trans_date)
      AND    gic1.item_id            = itc.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = itc.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    gic3.item_id            = itc.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
      AND    xrpm.doc_type           = itc.doc_type
      AND    xrpm.reason_code        = itc.reason_code
      AND    xrpm.break_col_01       IS NOT NULL
      AND    iwm.whse_code           = itc.whse_code
      AND    iwm.whse_code           = ir_param.locat_code
-- 2009/03/05 v1.31 ADD START
      AND    iwm.attribute1          = '0'
-- 2009/03/05 v1.31 ADD END
      UNION ALL
      SELECT /*+ leading (xmrh xmrl ijm iaj itc gic1 mcb1 gic2 mcb2) use_nl (xmrh xmrl ijm iaj itc gic1 mcb1 gic2 mcb2) */
             iwm.whse_code                        h_whse_code
            ,iwm.whse_name                        h_whse_name
            ,itc.trans_id                         trans_id
            ,iimb.attribute15                     cost_mng_clss
            ,iimb.lot_ctl                         lot_ctl
            ,xlc.unit_ploce                       actual_unit_price
            ,CASE WHEN INSTR(xrpm.break_col_01,gv_hifn) = 0
                       THEN ''
                  WHEN xrpm.rcv_pay_div = gc_rcv_pay_div_in
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  ELSE SUBSTR(xrpm.break_col_01,INSTR(xrpm.break_col_01,gv_hifn) +1)
             END                                  column_no
            ,itc.reason_code                      reason_code
            ,itc.trans_date                       trans_date
            ,TO_CHAR(itc.trans_date, 'YYYYMM')  trans_ym
-- 2008/12/11 v1.26 N.Yoshida mod start
--            ,gc_rcv_pay_div_adj                   rcv_pay_div
            ,xrpm.rcv_pay_div                     rcv_pay_div
-- 2008/12/11 v1.26 N.Yoshida mod end
            ,xrpm.dealings_div                    dealings_div
            ,itc.doc_type                         doc_type
            ,ir_param.item_class                  item_div
            ,ir_param.goods_class                 prod_div
            ,mcb3.segment1                        crowd_code
            ,SUBSTR(mcb3.segment1, 1, 3)          crowd_low
            ,SUBSTR(mcb3.segment1, 1, 2)          crowd_mid
            ,SUBSTR(mcb3.segment1, 1, 1)          crowd_high
            ,itc.item_id                          item_id
            ,itc.lot_id                           lot_id
-- 2008/12/11 v1.26 N.Yoshida mod start
--            ,ABS(NVL(itc.trans_qty, 0))           trans_qty
            ,NVL(itc.trans_qty, 0)                trans_qty
-- 2008/12/11 v1.26 N.Yoshida mod end
            ,xmrh.actual_arrival_date             arrival_date
            ,TO_CHAR(xmrh.actual_arrival_date, gc_char_ym_format) arrival_ym
            ,iimb.item_no                         item_code
            ,ximb.item_short_name                 item_name
      FROM   ic_tran_cmp                      itc
            ,ic_adjs_jnl                      iaj
            ,ic_jrnl_mst                      ijm
            ,xxinv_mov_req_instr_headers      xmrh
            ,xxinv_mov_req_instr_lines        xmrl
            ,ic_item_mst_b                    iimb
            ,xxcmn_item_mst_b                 ximb
            ,ic_lots_mst                      ilm
            ,xxcmn_lot_cost                   xlc
            ,gmi_item_categories              gic1
            ,mtl_categories_b                 mcb1
            ,gmi_item_categories              gic2
            ,mtl_categories_b                 mcb2
            ,gmi_item_categories              gic3
            ,mtl_categories_b                 mcb3
            ,xxcmn_rcv_pay_mst                xrpm
            ,ic_whse_mst                      iwm
      WHERE  itc.doc_type            = gv_doc_type_adji
      AND    itc.reason_code         = gv_reason_code_adji_move
      AND    xmrh.actual_arrival_date > FND_DATE.STRING_TO_DATE(gd_prv1_dt_chr,gc_char_dt_format)
      AND    xmrh.actual_arrival_date < FND_DATE.STRING_TO_DATE(gd_flw_dt_chr,gc_char_dt_format)
      AND    iaj.trans_type          = itc.doc_type
      AND    iaj.doc_id              = itc.doc_id
      AND    iaj.doc_line            = itc.doc_line
      AND    ijm.journal_id          = iaj.journal_id
      AND    ijm.attribute1          = TO_CHAR(xmrl.mov_line_id)
      AND    xmrh.mov_hdr_id         = xmrl.mov_hdr_id
      AND    ilm.item_id             = itc.item_id
      AND    ilm.lot_id              = itc.lot_id
      AND    iimb.item_id            = ilm.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(itc.trans_date)
      AND    ximb.end_date_active   >= TRUNC(itc.trans_date)
      AND    gic1.item_id            = itc.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = itc.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    gic3.item_id            = itc.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
-- 2008/12/11 v1.26 N.Yoshida mod start
      AND    xrpm.rcv_pay_div        = CASE
--                                       WHEN itc.trans_qty >= 0 THEN 1
--                                       ELSE -1
                                       WHEN itc.trans_qty >= 0 THEN -1
                                       ELSE 1
                                       END
-- 2008/12/11 v1.26 N.Yoshida mod end
      AND    xrpm.doc_type           = itc.doc_type
      AND    xrpm.reason_code        = itc.reason_code
      AND    xrpm.break_col_01       IS NOT NULL
      AND    iwm.whse_code           = itc.whse_code
      AND    iwm.whse_code           = ir_param.locat_code
-- 2009/03/05 v1.31 ADD START
      AND    iwm.attribute1          = '0'
-- 2009/03/05 v1.31 ADD END
      UNION ALL
      SELECT /*+ leading (itc gic1 mcb1 gic2 mcb2) use_nl (itc gic1 mcb1 gic2 mcb2) */
             iwm.whse_code                        h_whse_code
            ,iwm.whse_name                        h_whse_name
            ,itc.trans_id                         trans_id
            ,iimb.attribute15                     cost_mng_clss
            ,iimb.lot_ctl                         lot_ctl
            ,xlc.unit_ploce                       actual_unit_price
            ,CASE WHEN INSTR(xrpm.break_col_01,gv_hifn) = 0
                       THEN ''
                  WHEN xrpm.rcv_pay_div = gc_rcv_pay_div_in
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  ELSE SUBSTR(xrpm.break_col_01,INSTR(xrpm.break_col_01,gv_hifn) +1)
             END                                  column_no
            ,itc.reason_code                      reason_code
            ,itc.trans_date                       trans_date
            ,TO_CHAR(itc.trans_date, 'YYYYMM')  trans_ym
            ,CASE WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN TO_CHAR(ABS(TO_NUMBER(xrpm.rcv_pay_div)))
                  ELSE xrpm.rcv_pay_div
             END                                  rcv_pay_div
            ,xrpm.dealings_div                    dealings_div
            ,itc.doc_type                         doc_type
            ,ir_param.item_class                  item_div
            ,ir_param.goods_class                 prod_div
            ,mcb3.segment1                        crowd_code
            ,SUBSTR(mcb3.segment1, 1, 3)          crowd_low
            ,SUBSTR(mcb3.segment1, 1, 2)          crowd_mid
            ,SUBSTR(mcb3.segment1, 1, 1)          crowd_high
            ,itc.item_id                          item_id
            ,itc.lot_id                           lot_id
            ,NVL(itc.trans_qty, 0)                trans_qty
            ,itc.trans_date                       arrival_date
            ,TO_CHAR(itc.trans_date, gc_char_ym_format) arrival_ym
            ,iimb.item_no                         item_code
            ,ximb.item_short_name                 item_name
      FROM   ic_tran_cmp                      itc
            ,ic_item_mst_b                    iimb
            ,xxcmn_item_mst_b                 ximb
            ,ic_lots_mst                      ilm
            ,xxcmn_lot_cost                   xlc
            ,gmi_item_categories              gic1
            ,mtl_categories_b                 mcb1
            ,gmi_item_categories              gic2
            ,mtl_categories_b                 mcb2
            ,gmi_item_categories              gic3
            ,mtl_categories_b                 mcb3
            ,xxcmn_rcv_pay_mst                xrpm
            ,ic_whse_mst                      iwm
      WHERE  itc.doc_type            = gv_doc_type_adji
      AND    itc.reason_code        IN (gv_reason_code_adji_itm
                                       ,gv_reason_code_adji_itm_u
                                       ,gv_reason_code_adji_snt_u
                                       ,gv_reason_code_adji_snt)
      AND    itc.trans_date > FND_DATE.STRING_TO_DATE(gd_prv1_dt_chr,gc_char_dt_format)
      AND    itc.trans_date < FND_DATE.STRING_TO_DATE(gd_flw_dt_chr,gc_char_dt_format)
      AND    ilm.item_id             = itc.item_id
      AND    ilm.lot_id              = itc.lot_id
      AND    iimb.item_id            = ilm.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(itc.trans_date)
      AND    ximb.end_date_active   >= TRUNC(itc.trans_date)
      AND    gic1.item_id            = itc.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = itc.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    gic3.item_id            = itc.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
-- 2008/11/19 v1.18 DELETE START
      --AND    xrpm.rcv_pay_div        = CASE
      --                                 WHEN itc.trans_qty >= 0 THEN 1
      --                                 ELSE -1
      --                                 END
-- 2008/11/19 v1.18 DELETE END
      AND    xrpm.doc_type           = itc.doc_type
      AND    xrpm.reason_code        = itc.reason_code
      AND    xrpm.break_col_01       IS NOT NULL
      AND    iwm.whse_code           = itc.whse_code
      AND    iwm.whse_code           = ir_param.locat_code
-- 2009/03/05 v1.31 ADD START
      AND    iwm.attribute1          = '0'
-- 2009/03/05 v1.31 ADD END
      UNION ALL
      SELECT /*+ leading (itp gic1 mcb1 gic2 mcb2) use_nl (itp gic1 mcb1 gic2 mcb2)*/
             iwm.whse_code                        h_whse_code
            ,iwm.whse_name                        h_whse_name
            ,itp.trans_id                         trans_id
            ,iimb.attribute15                     cost_mng_clss
            ,iimb.lot_ctl                         lot_ctl
            ,xlc.unit_ploce                       actual_unit_price
            ,CASE WHEN INSTR(xrpm.break_col_01,gv_hifn) = 0
                       THEN ''
                  WHEN xrpm.rcv_pay_div = gc_rcv_pay_div_in
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  ELSE SUBSTR(xrpm.break_col_01,INSTR(xrpm.break_col_01,gv_hifn) +1)
             END                                  column_no
            ,itp.reason_code                      reason_code
            ,itp.trans_date                       trans_date
            ,TO_CHAR(itp.trans_date, 'YYYYMM')  trans_ym
            ,CASE WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN TO_CHAR(ABS(TO_NUMBER(xrpm.rcv_pay_div)))
                  ELSE xrpm.rcv_pay_div
             END                                  rcv_pay_div
            ,xrpm.dealings_div                    dealings_div
            ,itp.doc_type                         doc_type
            ,ir_param.item_class                  item_div
            ,ir_param.goods_class                 prod_div
            ,mcb3.segment1                        crowd_code
            ,SUBSTR(mcb3.segment1, 1, 3)          crowd_low
            ,SUBSTR(mcb3.segment1, 1, 2)          crowd_mid
            ,SUBSTR(mcb3.segment1, 1, 1)          crowd_high
            ,itp.item_id                          item_id
            ,itp.lot_id                           lot_id
            ,NVL(itp.trans_qty, 0)                trans_qty
            ,itp.trans_date                       arrival_date
            ,TO_CHAR(itp.trans_date, gc_char_ym_format) arrival_ym
            ,iimb.item_no                         item_code
            ,ximb.item_short_name                 item_name
      FROM   ic_tran_pnd                      itp
            ,ic_item_mst_b                    iimb
            ,xxcmn_item_mst_b                 ximb
            ,ic_lots_mst                      ilm
            ,xxcmn_lot_cost                   xlc
            ,gmi_item_categories              gic1
            ,mtl_categories_b                 mcb1
            ,gmi_item_categories              gic2
            ,mtl_categories_b                 mcb2
            ,gmi_item_categories              gic3
            ,mtl_categories_b                 mcb3
            ,gme_material_details             gmd
            ,gme_batch_header                 gbh
            ,gmd_routings_b                   grb
            ,xxcmn_rcv_pay_mst                xrpm
            ,ic_whse_mst                      iwm
      WHERE  itp.doc_type            = gv_doc_type_prod
      AND    itp.completed_ind       = 1
      AND    itp.trans_date > FND_DATE.STRING_TO_DATE(gd_prv1_dt_chr,gc_char_dt_format)
      AND    itp.trans_date < FND_DATE.STRING_TO_DATE(gd_flw_dt_chr,gc_char_dt_format)
      AND    itp.reverse_id          IS NULL
      AND    ilm.item_id             = itp.item_id
      AND    ilm.lot_id              = itp.lot_id
      AND    iimb.item_id            = ilm.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(itp.trans_date)
      AND    ximb.end_date_active   >= TRUNC(itp.trans_date)
      AND    gic1.item_id            = itp.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = itp.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    gic3.item_id            = itp.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
      AND    gmd.batch_id            = itp.doc_id
      AND    gmd.line_no             = itp.doc_line
      AND    gmd.line_type           = itp.line_type
      AND    gbh.batch_id            = gmd.batch_id
      AND    grb.routing_id          = gbh.routing_id
      AND    xrpm.routing_class      = grb.routing_class
      AND    xrpm.line_type          = gmd.line_type
      AND    (((gmd.attribute5 IS NULL) AND (xrpm.hit_in_div IS NULL))
             OR (xrpm.hit_in_div = gmd.attribute5))
      AND    itp.doc_type            = xrpm.doc_type
      AND    itp.line_type           = xrpm.line_type
      AND    xrpm.break_col_01       IS NOT NULL
      AND    xrpm.routing_class      <> '70'
      AND    iwm.whse_code           = itp.whse_code
      AND    iwm.whse_code           = ir_param.locat_code
-- 2009/03/05 v1.31 ADD START
      AND    iwm.attribute1          = '0'
-- 2009/03/05 v1.31 ADD END
      UNION ALL
      SELECT /*+ leading (itp gic1 mcb1 gic2 mcb2 gmd gbh grb) use_nl (itp gic1 mcb1 gic2 mcb2 gmd gbh grb)*/
             iwm.whse_code                        h_whse_code
            ,iwm.whse_name                        h_whse_name
            ,itp.trans_id                         trans_id
            ,iimb.attribute15                     cost_mng_clss
            ,iimb.lot_ctl                         lot_ctl
            ,xlc.unit_ploce                       actual_unit_price
            ,CASE WHEN INSTR(xrpm.break_col_01,gv_hifn) = 0
                       THEN ''
                  WHEN xrpm.rcv_pay_div = gc_rcv_pay_div_in
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  ELSE SUBSTR(xrpm.break_col_01,INSTR(xrpm.break_col_01,gv_hifn) +1)
             END                                  column_no
            ,itp.reason_code                      reason_code
            ,itp.trans_date                       trans_date
            ,TO_CHAR(itp.trans_date, 'YYYYMM')  trans_ym
            ,CASE WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN TO_CHAR(ABS(TO_NUMBER(xrpm.rcv_pay_div)))
                  ELSE xrpm.rcv_pay_div
             END                                  rcv_pay_div
            ,xrpm.dealings_div                    dealings_div
            ,itp.doc_type                         doc_type
            ,ir_param.item_class                  item_div
            ,ir_param.goods_class                 prod_div
            ,mcb3.segment1                        crowd_code
            ,SUBSTR(mcb3.segment1, 1, 3)          crowd_low
            ,SUBSTR(mcb3.segment1, 1, 2)          crowd_mid
            ,SUBSTR(mcb3.segment1, 1, 1)          crowd_high
            ,itp.item_id                          item_id
            ,itp.lot_id                           lot_id
            ,NVL(itp.trans_qty, 0)                trans_qty
            ,itp.trans_date                       arrival_date
            ,TO_CHAR(itp.trans_date, gc_char_ym_format) arrival_ym
            ,iimb.item_no                         item_code
            ,ximb.item_short_name                 item_name
      FROM   ic_tran_pnd                      itp
            ,ic_item_mst_b                    iimb
            ,xxcmn_item_mst_b                 ximb
            ,ic_lots_mst                      ilm
            ,xxcmn_lot_cost                   xlc
            ,gmi_item_categories              gic1
            ,mtl_categories_b                 mcb1
            ,gmi_item_categories              gic2
            ,mtl_categories_b                 mcb2
            ,gmi_item_categories              gic3
            ,mtl_categories_b                 mcb3
            ,gme_material_details             gmd
            ,gme_batch_header                 gbh
            ,gmd_routings_b                   grb
            ,xxcmn_rcv_pay_mst                xrpm
            ,ic_whse_mst                      iwm
      WHERE  itp.doc_type            = gv_doc_type_prod
      AND    itp.completed_ind       = 1
      AND    itp.trans_date > FND_DATE.STRING_TO_DATE(gd_prv1_dt_chr,gc_char_dt_format)
      AND    itp.trans_date < FND_DATE.STRING_TO_DATE(gd_flw_dt_chr,gc_char_dt_format)
      AND    itp.reverse_id          IS NULL
      AND    ilm.item_id             = itp.item_id
      AND    ilm.lot_id              = itp.lot_id
      AND    iimb.item_id            = ilm.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(itp.trans_date)
      AND    ximb.end_date_active   >= TRUNC(itp.trans_date)
      AND    gic1.item_id            = itp.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = itp.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    mcb2.segment1           IN ('1','4')
      AND    gic3.item_id            = itp.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
      AND    gmd.batch_id            = itp.doc_id
      AND    gmd.line_no             = itp.doc_line
      AND    gmd.line_type           = itp.line_type
      AND    gbh.batch_id            = gmd.batch_id
      AND    grb.routing_id          = gbh.routing_id
      AND    xrpm.routing_class      = grb.routing_class
      AND    xrpm.line_type          = gmd.line_type
      AND    (((gmd.attribute5 IS NULL) AND (xrpm.hit_in_div IS NULL))
             OR (xrpm.hit_in_div = gmd.attribute5))
      AND    itp.doc_type            = xrpm.doc_type
      AND    itp.line_type           = xrpm.line_type
      AND    xrpm.break_col_01       IS NOT NULL
      AND    xrpm.routing_class      = '70'
      AND    (EXISTS (SELECT 1
                      FROM   gme_material_details gmd2
                            ,gmi_item_categories  gic
                            ,mtl_categories_b     mcb
                      WHERE  gmd2.batch_id   = gmd.batch_id
                      AND    gmd2.line_no    = gmd.line_no
                      AND    gmd2.line_type  = -1
                      AND    gic.item_id     = gmd2.item_id
                      AND    gic.category_set_id = cn_item_class_id
                      AND    gic.category_id = mcb.category_id
                      AND    mcb.segment1    = xrpm.item_div_origin))
      AND    (EXISTS (SELECT 1
                      FROM   gme_material_details gmd3
                            ,gmi_item_categories  gic
                            ,mtl_categories_b     mcb
                      WHERE  gmd3.batch_id   = gmd.batch_id
                      AND    gmd3.line_no    = gmd.line_no
                      AND    gmd3.line_type  = 1
                      AND    gic.item_id     = gmd3.item_id
                      AND    gic.category_set_id = cn_item_class_id
                      AND    gic.category_id = mcb.category_id
                      AND    mcb.segment1    = xrpm.item_div_ahead))
      AND    iwm.whse_code           = itp.whse_code
      AND    iwm.whse_code           = ir_param.locat_code
-- 2009/03/05 v1.31 ADD START
      AND    iwm.attribute1          = '0'
-- 2009/03/05 v1.31 ADD END
      UNION ALL
      SELECT /*+ leading (xoha xola rsl itp gic1 mcb1 gic2 mcb2 ooha otta) use_nl (xoha xola rsl itp gic1 mcb1 gic2 mcb2 ooha otta) */
             iwm.whse_code                        h_whse_code
            ,iwm.whse_name                        h_whse_name
            ,itp.trans_id                         trans_id
            ,iimb.attribute15                     cost_mng_clss
            ,iimb.lot_ctl                         lot_ctl
            ,xlc.unit_ploce                       actual_unit_price
            ,CASE WHEN INSTR(xrpm.break_col_01,gv_hifn) = 0
                       THEN ''
                  WHEN xrpm.rcv_pay_div = gc_rcv_pay_div_in
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  ELSE SUBSTR(xrpm.break_col_01,INSTR(xrpm.break_col_01,gv_hifn) +1)
             END                                  column_no
            ,itp.reason_code                      reason_code
            ,itp.trans_date                       trans_date
            ,TO_CHAR(itp.trans_date, 'YYYYMM')  trans_ym
            ,CASE WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN TO_CHAR(ABS(TO_NUMBER(xrpm.rcv_pay_div)))
                  ELSE xrpm.rcv_pay_div
             END                                  rcv_pay_div
            ,xrpm.dealings_div                    dealings_div
            ,itp.doc_type                         doc_type
            ,ir_param.item_class                  item_div
            ,ir_param.goods_class                 prod_div
            ,mcb3.segment1                        crowd_code
            ,SUBSTR(mcb3.segment1, 1, 3)          crowd_low
            ,SUBSTR(mcb3.segment1, 1, 2)          crowd_mid
            ,SUBSTR(mcb3.segment1, 1, 1)          crowd_high
            ,itp.item_id                          item_id
            ,itp.lot_id                           lot_id
            ,NVL(itp.trans_qty, 0)                trans_qty
            ,xoha.arrival_date                    arrival_date
            ,TO_CHAR(xoha.arrival_date, gc_char_ym_format) arrival_ym
            ,iimb.item_no                         item_code
            ,ximb.item_short_name                 item_name
      FROM   ic_tran_pnd                      itp
            ,rcv_shipment_lines               rsl
            ,oe_order_headers_all             ooha
            ,oe_transaction_types_all         otta
            ,xxwsh_order_headers_all          xoha
            ,xxwsh_order_lines_all            xola
            ,ic_item_mst_b                    iimb
            ,xxcmn_item_mst_b                 ximb
            ,ic_lots_mst                      ilm
            ,xxcmn_lot_cost                   xlc
            ,gmi_item_categories              gic1
            ,mtl_categories_b                 mcb1
            ,gmi_item_categories              gic2
            ,mtl_categories_b                 mcb2
            ,gmi_item_categories              gic3
            ,mtl_categories_b                 mcb3
            ,xxcmn_rcv_pay_mst                xrpm
            ,ic_whse_mst                      iwm
      WHERE  itp.doc_type            = gv_doc_type_porc
      AND    itp.completed_ind       = 1
      AND    xoha.latest_external_flag = 'Y'
      AND    xoha.arrival_date > FND_DATE.STRING_TO_DATE(gd_prv1_dt_chr,gc_char_dt_format)
      AND    xoha.arrival_date < FND_DATE.STRING_TO_DATE(gd_flw_dt_chr,gc_char_dt_format)
      AND    xoha.req_status         IN ('04','08')
      AND    ilm.item_id             = itp.item_id
      AND    ilm.lot_id              = itp.lot_id
      AND    iimb.item_id            = itp.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(itp.trans_date)
      AND    ximb.end_date_active   >= TRUNC(itp.trans_date)
      AND    gic1.item_id            = itp.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = itp.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    gic3.item_id            = itp.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
      AND    rsl.shipment_header_id  = itp.doc_id
      AND    rsl.line_num            = itp.doc_line
      AND    rsl.oe_order_header_id  = xola.header_id
      AND    rsl.oe_order_line_id    = xola.line_id
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    ((otta.attribute4           <> '2')
             OR  (otta.attribute4       IS NULL))
      AND    otta.attribute1         IN ('1','2')
      AND    xoha.header_id          = ooha.header_id
      AND    xola.order_header_id    = xoha.order_header_id
      AND    xola.request_item_code  = xola.shipping_item_code
      AND    xrpm.doc_type           = itp.doc_type
      AND    xrpm.source_document_code = 'RMA'
      AND    xrpm.dealings_div       IN ('101','103')
      AND    xrpm.shipment_provision_div = DECODE(xoha.req_status,'04','1','08','2')
      AND    xrpm.shipment_provision_div = otta.attribute1
      AND    ((xrpm.ship_prov_rcv_pay_category IS NULL)
             OR (xrpm.ship_prov_rcv_pay_category = otta.attribute11))
      AND    xrpm.break_col_01       IS NOT NULL
      AND    xrpm.item_div_origin    IS NULL
      AND    xrpm.item_div_ahead     IS NULL
      AND    iwm.whse_code           = itp.whse_code
      AND    iwm.whse_code           = ir_param.locat_code
-- 2009/03/05 v1.31 ADD START
      AND    iwm.attribute1          = '0'
-- 2009/03/05 v1.31 ADD END
      UNION ALL
      SELECT /*+ leading (xoha xola rsl itp gic1 mcb1 gic2 mcb2 ooha otta) use_nl (xoha xola rsl itp gic1 mcb1 gic2 mcb2 ooha otta) */
             iwm.whse_code                        h_whse_code
            ,iwm.whse_name                        h_whse_name
            ,itp.trans_id                         trans_id
            ,iimb.attribute15                     cost_mng_clss
            ,iimb.lot_ctl                         lot_ctl
            ,xlc.unit_ploce                       actual_unit_price
            ,CASE WHEN INSTR(xrpm.break_col_01,gv_hifn) = 0
                       THEN ''
                  WHEN xrpm.rcv_pay_div = gc_rcv_pay_div_in
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  ELSE SUBSTR(xrpm.break_col_01,INSTR(xrpm.break_col_01,gv_hifn) +1)
             END                                  column_no
            ,itp.reason_code                      reason_code
            ,itp.trans_date                       trans_date
            ,TO_CHAR(itp.trans_date, 'YYYYMM')  trans_ym
            ,CASE WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN TO_CHAR(ABS(TO_NUMBER(xrpm.rcv_pay_div)))
                  ELSE xrpm.rcv_pay_div
             END                                  rcv_pay_div
            ,xrpm.dealings_div                    dealings_div
            ,itp.doc_type                         doc_type
            ,ir_param.item_class                  item_div
            ,ir_param.goods_class                 prod_div
            ,mcb3.segment1                        crowd_code
            ,SUBSTR(mcb3.segment1, 1, 3)          crowd_low
            ,SUBSTR(mcb3.segment1, 1, 2)          crowd_mid
            ,SUBSTR(mcb3.segment1, 1, 1)          crowd_high
            ,iimb.item_id                         item_id
            ,itp.lot_id                           lot_id
            ,NVL(itp.trans_qty, 0)                trans_qty
            ,xoha.arrival_date                      arrival_date
            ,TO_CHAR(xoha.arrival_date, gc_char_ym_format) arrival_ym
            ,iimb.item_no                         item_code
            ,ximb.item_short_name                 item_name
      FROM   ic_tran_pnd                      itp
            ,rcv_shipment_lines               rsl
            ,oe_order_headers_all             ooha
            ,oe_transaction_types_all         otta
            ,xxwsh_order_headers_all          xoha
            ,xxwsh_order_lines_all            xola
            ,ic_item_mst_b                    iimb
            ,ic_item_mst_b                    iimb2
            ,xxcmn_item_mst_b                 ximb
            ,ic_lots_mst                      ilm
            ,xxcmn_lot_cost                   xlc
            ,gmi_item_categories              gic1
            ,mtl_categories_b                 mcb1
            ,gmi_item_categories              gic2
            ,mtl_categories_b                 mcb2
            ,gmi_item_categories              gic3
            ,mtl_categories_b                 mcb3
            ,gmi_item_categories              gic4
            ,mtl_categories_b                 mcb4
            ,xxcmn_rcv_pay_mst                xrpm
            ,ic_whse_mst                      iwm
      WHERE  itp.doc_type            = gv_doc_type_porc
      AND    itp.completed_ind       = 1
      AND    xoha.latest_external_flag = 'Y'
      AND    xoha.arrival_date > FND_DATE.STRING_TO_DATE(gd_prv1_dt_chr,gc_char_dt_format)
      AND    xoha.arrival_date < FND_DATE.STRING_TO_DATE(gd_flw_dt_chr,gc_char_dt_format)
      AND    xoha.req_status         IN ('04','08')
      AND    ilm.item_id             = itp.item_id
      AND    ilm.lot_id              = itp.lot_id
      AND    iimb.item_id            = itp.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    iimb2.item_no           = xola.request_item_code
      AND    ximb.start_date_active <= TRUNC(itp.trans_date)
      AND    ximb.end_date_active   >= TRUNC(itp.trans_date)
      AND    gic1.item_id            = itp.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = itp.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    gic3.item_id            = itp.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
      AND    gic4.item_id            = iimb2.item_id
      AND    gic4.category_set_id    = cn_item_class_id
      AND    gic4.category_id        = mcb4.category_id
      AND    rsl.shipment_header_id  = itp.doc_id
      AND    rsl.line_num            = itp.doc_line
      AND    rsl.oe_order_header_id  = xoha.header_id
      AND    rsl.oe_order_line_id    = xola.line_id
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    ((otta.attribute4           <> '2')
             OR  (otta.attribute4       IS NULL))
      AND    otta.attribute1         IN ('1','2')
      AND    xoha.header_id          = ooha.header_id
      AND    xola.order_header_id    = xoha.order_header_id
      AND    xrpm.doc_type           = itp.doc_type
      AND    xrpm.source_document_code = 'RMA'
      AND    xrpm.dealings_div       = '106'
      AND    xrpm.shipment_provision_div = DECODE(xoha.req_status,'04','1','08','2')
      AND    xrpm.shipment_provision_div = otta.attribute1
      AND    xrpm.ship_prov_rcv_pay_category = otta.attribute11
      AND    xrpm.item_div_ahead     = mcb4.segment1
      AND    mcb2.segment1           <> '5'
      AND    xrpm.break_col_01       IS NOT NULL
      AND    iwm.whse_code           = itp.whse_code
      AND    iwm.whse_code           = ir_param.locat_code
-- 2009/03/05 v1.31 ADD START
      AND    iwm.attribute1          = '0'
-- 2009/03/05 v1.31 ADD END
      UNION ALL
      SELECT /*+ leading (xoha xola rsl itp gic1 mcb1 gic2 mcb2 ooha otta xrpm) use_nl (xoha xola rsl itp gic1 mcb1 gic2 mcb2 rsl ooha otta xrpm) */
             iwm.whse_code                        h_whse_code
            ,iwm.whse_name                        h_whse_name
            ,itp.trans_id                         trans_id
            ,iimb.attribute15                     cost_mng_clss
            ,iimb.lot_ctl                         lot_ctl
            ,xlc.unit_ploce                       actual_unit_price
            ,CASE WHEN INSTR(xrpm.break_col_01,gv_hifn) = 0
                       THEN ''
                  WHEN xrpm.rcv_pay_div = gc_rcv_pay_div_in
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  ELSE SUBSTR(xrpm.break_col_01,INSTR(xrpm.break_col_01,gv_hifn) +1)
             END                                  column_no
            ,itp.reason_code                      reason_code
            ,itp.trans_date                       trans_date
            ,TO_CHAR(itp.trans_date, 'YYYYMM')  trans_ym
            ,CASE WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN TO_CHAR(ABS(TO_NUMBER(xrpm.rcv_pay_div)))
                  ELSE xrpm.rcv_pay_div
             END                                  rcv_pay_div
            ,xrpm.dealings_div                    dealings_div
            ,itp.doc_type                         doc_type
            ,ir_param.item_class                  item_div
            ,ir_param.goods_class                 prod_div
            ,mcb3.segment1                        crowd_code
            ,SUBSTR(mcb3.segment1, 1, 3)          crowd_low
            ,SUBSTR(mcb3.segment1, 1, 2)          crowd_mid
            ,SUBSTR(mcb3.segment1, 1, 1)          crowd_high
            ,iimb.item_id                         item_id
            ,itp.lot_id                           lot_id
            ,NVL(itp.trans_qty, 0)                trans_qty
            ,xoha.arrival_date                    arrival_date
            ,TO_CHAR(xoha.arrival_date, gc_char_ym_format) arrival_ym
            ,iimb.item_no                         item_code
            ,ximb.item_short_name                 item_name
      FROM   ic_tran_pnd                      itp
            ,rcv_shipment_lines               rsl
            ,oe_order_headers_all             ooha
            ,oe_transaction_types_all         otta
            ,xxwsh_order_headers_all          xoha
            ,xxwsh_order_lines_all            xola
            ,ic_item_mst_b                    iimb
            ,ic_item_mst_b                    iimb2
            ,xxcmn_item_mst_b                 ximb
            ,ic_lots_mst                      ilm
            ,xxcmn_lot_cost                   xlc
            ,gmi_item_categories              gic1
            ,mtl_categories_b                 mcb1
            ,gmi_item_categories              gic2
            ,mtl_categories_b                 mcb2
            ,gmi_item_categories              gic3
            ,mtl_categories_b                 mcb3
            ,gmi_item_categories              gic4
            ,mtl_categories_b                 mcb4
            ,xxcmn_rcv_pay_mst                xrpm
            ,ic_whse_mst                      iwm
      WHERE  itp.doc_type            = gv_doc_type_porc
      AND    itp.completed_ind       = 1
      AND    xoha.latest_external_flag = 'Y'
      AND    xoha.arrival_date > FND_DATE.STRING_TO_DATE(gd_prv1_dt_chr,gc_char_dt_format)
      AND    xoha.arrival_date < FND_DATE.STRING_TO_DATE(gd_flw_dt_chr,gc_char_dt_format)
      AND    xoha.req_status         = '04'
      AND    ilm.item_id             = itp.item_id
      AND    ilm.lot_id              = itp.lot_id
      AND    iimb.item_id            = itp.item_id
      AND    iimb2.item_no           = xola.request_item_code
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(itp.trans_date)
      AND    ximb.end_date_active   >= TRUNC(itp.trans_date)
      AND    gic1.item_id            = itp.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = itp.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    gic3.item_id            = itp.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
      AND    gic4.item_id            = iimb2.item_id
      AND    gic4.category_set_id    = cn_item_class_id
      AND    gic4.category_id        = mcb4.category_id
      AND    rsl.shipment_header_id  = itp.doc_id
      AND    rsl.line_num            = itp.doc_line
      AND    rsl.oe_order_header_id  = xoha.header_id
      AND    rsl.oe_order_line_id    = xola.line_id
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    ((otta.attribute4           <> '2')
             OR  (otta.attribute4       IS NULL))
      AND    xoha.header_id          = ooha.header_id
      AND    xola.order_header_id    = xoha.order_header_id
      AND    xrpm.doc_type           = itp.doc_type
      AND    xrpm.source_document_code = 'RMA'
      AND    xrpm.dealings_div       = '113'
      AND    xrpm.shipment_provision_div = DECODE(xoha.req_status,'04','1','08','2')
      AND    xrpm.item_div_ahead     = mcb4.segment1
      AND    mcb2.segment1           <> '5'
      AND    xrpm.break_col_01       IS NOT NULL
      AND    iwm.whse_code           = itp.whse_code
      AND    iwm.whse_code           = ir_param.locat_code
-- 2009/03/05 v1.31 ADD START
      AND    iwm.attribute1          = '0'
-- 2009/03/05 v1.31 ADD END
      UNION ALL
      SELECT /*+ leading (xoha ooha otta xola rsl itp gic1 mcb1 gic2 mcb2) use_nl (xoha ooha otta xola rsl itp gic1 mcb1 gic2 mcb2) */
             iwm.whse_code                        h_whse_code
            ,iwm.whse_name                        h_whse_name
            ,itp.trans_id                         trans_id
            ,iimb.attribute15                     cost_mng_clss
            ,iimb.lot_ctl                         lot_ctl
            ,xlc.unit_ploce                       actual_unit_price
            ,CASE WHEN INSTR(xrpm.break_col_01,gv_hifn) = 0
                       THEN ''
                  WHEN xrpm.rcv_pay_div = gc_rcv_pay_div_in
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  ELSE SUBSTR(xrpm.break_col_01,INSTR(xrpm.break_col_01,gv_hifn) +1)
             END                                  column_no
            ,itp.reason_code                      reason_code
            ,itp.trans_date                       trans_date
            ,TO_CHAR(itp.trans_date, 'YYYYMM')  trans_ym
            ,CASE WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN TO_CHAR(ABS(TO_NUMBER(xrpm.rcv_pay_div)))
                  ELSE xrpm.rcv_pay_div
             END                                  rcv_pay_div
            ,xrpm.dealings_div                    dealings_div
            ,itp.doc_type                         doc_type
            ,ir_param.item_class                  item_div
            ,ir_param.goods_class                 prod_div
            ,mcb3.segment1                        crowd_code
            ,SUBSTR(mcb3.segment1, 1, 3)          crowd_low
            ,SUBSTR(mcb3.segment1, 1, 2)          crowd_mid
            ,SUBSTR(mcb3.segment1, 1, 1)          crowd_high
            ,itp.item_id                          item_id
            ,itp.lot_id                           lot_id
            ,NVL(itp.trans_qty, 0)                trans_qty
            ,xoha.arrival_date                    arrival_date
            ,TO_CHAR(xoha.arrival_date, gc_char_ym_format) arrival_ym
            ,iimb.item_no                         item_code
            ,ximb.item_short_name                 item_name
      FROM   ic_tran_pnd                      itp
            ,rcv_shipment_lines               rsl
            ,oe_order_headers_all             ooha
            ,oe_transaction_types_all         otta
            ,xxwsh_order_headers_all          xoha
            ,xxwsh_order_lines_all            xola
            ,ic_item_mst_b                    iimb
            ,xxcmn_item_mst_b                 ximb
            ,ic_lots_mst                      ilm
            ,xxcmn_lot_cost                   xlc
            ,gmi_item_categories              gic1
            ,mtl_categories_b                 mcb1
            ,gmi_item_categories              gic2
            ,mtl_categories_b                 mcb2
            ,gmi_item_categories              gic3
            ,mtl_categories_b                 mcb3
            ,xxcmn_rcv_pay_mst                xrpm
            ,ic_whse_mst                      iwm
      WHERE  itp.doc_type            = gv_doc_type_porc
      AND    itp.completed_ind       = 1
      AND    xoha.latest_external_flag = 'Y'
      AND    xoha.arrival_date > FND_DATE.STRING_TO_DATE(gd_prv1_dt_chr,gc_char_dt_format)
      AND    xoha.arrival_date < FND_DATE.STRING_TO_DATE(gd_flw_dt_chr,gc_char_dt_format)
      AND    ilm.item_id             = itp.item_id
      AND    ilm.lot_id              = itp.lot_id
      AND    iimb.item_id            = itp.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(itp.trans_date)
      AND    ximb.end_date_active   >= TRUNC(itp.trans_date)
      AND    gic1.item_id            = itp.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = itp.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    gic3.item_id            = itp.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
      AND    rsl.shipment_header_id  = itp.doc_id
      AND    rsl.line_num            = itp.doc_line
      AND    rsl.oe_order_header_id  = xoha.header_id
      AND    rsl.oe_order_line_id    = xola.line_id
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    otta.attribute4         = '2'
      AND    xoha.header_id          = ooha.header_id
      AND    xola.order_header_id    = xoha.order_header_id
      AND    xrpm.doc_type           = itp.doc_type
      AND    xrpm.source_document_code = 'RMA'
      AND    xrpm.dealings_div       IN ('504','509')
      AND    xrpm.stock_adjustment_div = otta.attribute4
      AND    xrpm.ship_prov_rcv_pay_category = otta.attribute11
      AND    xrpm.break_col_01       IS NOT NULL
      AND    iwm.whse_code           = itp.whse_code
      AND    iwm.whse_code           = ir_param.locat_code
-- 2009/03/05 v1.31 ADD START
      AND    iwm.attribute1          = '0'
-- 2009/03/05 v1.31 ADD END
      UNION ALL
      SELECT /*+ leading (itp gic1 mcb1 gic2 mcb2) use_nl (itp gic1 mcb1 gic2 mcb2) */
             iwm.whse_code                        h_whse_code
            ,iwm.whse_name                        h_whse_name
-- v1.33 Mod Start
--            ,itp.trans_id                         trans_id
            ,NULL                                 trans_id
-- v1.33 Mod End
            ,iimb.attribute15                     cost_mng_clss
            ,iimb.lot_ctl                         lot_ctl
            ,xlc.unit_ploce                       actual_unit_price
            ,CASE WHEN INSTR(xrpm.break_col_01,gv_hifn) = 0
                       THEN ''
                  WHEN xrpm.rcv_pay_div = gc_rcv_pay_div_in
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  ELSE SUBSTR(xrpm.break_col_01,INSTR(xrpm.break_col_01,gv_hifn) +1)
             END                                  column_no
            ,itp.reason_code                      reason_code
            ,itp.trans_date                       trans_date
            ,TO_CHAR(itp.trans_date, 'YYYYMM')  trans_ym
            ,CASE WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN TO_CHAR(ABS(TO_NUMBER(xrpm.rcv_pay_div)))
                  ELSE xrpm.rcv_pay_div
             END                                  rcv_pay_div
            ,xrpm.dealings_div                    dealings_div
            ,itp.doc_type                         doc_type
            ,ir_param.item_class                  item_div
            ,ir_param.goods_class                 prod_div
            ,mcb3.segment1                        crowd_code
            ,SUBSTR(mcb3.segment1, 1, 3)          crowd_low
            ,SUBSTR(mcb3.segment1, 1, 2)          crowd_mid
            ,SUBSTR(mcb3.segment1, 1, 1)          crowd_high
            ,itp.item_id                          item_id
            ,itp.lot_id                           lot_id
-- v1.33 Mod Start
--            ,NVL(itp.trans_qty, 0)                trans_qty
            ,SUM(NVL(itp.trans_qty, 0))           trans_qty
-- v1.33 Mod End
            ,itp.trans_date                       arrival_date
            ,TO_CHAR(itp.trans_date, gc_char_ym_format) arrival_ym
            ,iimb.item_no                         item_code
            ,ximb.item_short_name                 item_name
      FROM   ic_tran_pnd                      itp
            ,ic_item_mst_b                    iimb
            ,xxcmn_item_mst_b                 ximb
            ,ic_lots_mst                      ilm
            ,xxcmn_lot_cost                   xlc
            ,gmi_item_categories              gic1
            ,mtl_categories_b                 mcb1
            ,gmi_item_categories              gic2
            ,mtl_categories_b                 mcb2
            ,gmi_item_categories              gic3
            ,mtl_categories_b                 mcb3
            ,rcv_shipment_lines               rsl
            ,rcv_transactions                 rt
            ,xxcmn_rcv_pay_mst                xrpm
            ,ic_whse_mst                      iwm
      WHERE  itp.doc_type            = gv_doc_type_porc
      AND    itp.completed_ind       = 1
      AND    itp.trans_date > FND_DATE.STRING_TO_DATE(gd_prv1_dt_chr,gc_char_dt_format)
      AND    itp.trans_date < FND_DATE.STRING_TO_DATE(gd_flw_dt_chr,gc_char_dt_format)
      AND    ilm.item_id             = itp.item_id
      AND    ilm.lot_id              = itp.lot_id
      AND    iimb.item_id            = ilm.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(itp.trans_date)
      AND    ximb.end_date_active   >= TRUNC(itp.trans_date)
      AND    gic1.item_id            = itp.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = itp.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    gic3.item_id            = itp.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
      AND    rsl.shipment_header_id  = itp.doc_id
      AND    rsl.line_num            = itp.doc_line
      AND    rt.transaction_id       = itp.line_id
      AND    rt.shipment_line_id     = rsl.shipment_line_id
      AND    xrpm.doc_type           = itp.doc_type
      AND    xrpm.source_document_code = rsl.source_document_code
      AND    xrpm.transaction_type   = rt.transaction_type
      AND    xrpm.break_col_01       IS NOT NULL
      AND    iwm.whse_code           = itp.whse_code
      AND    iwm.whse_code           = ir_param.locat_code
-- 2009/03/05 v1.31 ADD START
      AND    iwm.attribute1          = '0'
-- 2009/03/05 v1.31 ADD END
-- v1.33 Add Start
      GROUP BY
             iwm.whse_code                        -- h_whse_code
            ,iwm.whse_name                        -- h_whse_name
            ,iimb.attribute15                     -- cost_mng_clss
            ,iimb.lot_ctl                         -- lot_ctl
            ,xlc.unit_ploce                       -- actual_unit_price
            ,CASE WHEN INSTR(xrpm.break_col_01,gv_hifn) = 0
                       THEN ''
                  WHEN xrpm.rcv_pay_div = gc_rcv_pay_div_in
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  ELSE SUBSTR(xrpm.break_col_01,INSTR(xrpm.break_col_01,gv_hifn) +1)
             END                                  -- column_no
            ,itp.reason_code                      -- reason_code
            ,itp.trans_date                       -- trans_date
            ,TO_CHAR(itp.trans_date, 'YYYYMM')    -- trans_ym
            ,CASE WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN TO_CHAR(ABS(TO_NUMBER(xrpm.rcv_pay_div)))
                  ELSE xrpm.rcv_pay_div
             END                                  -- rcv_pay_div
            ,xrpm.dealings_div                    -- dealings_div
            ,itp.doc_type                         -- doc_type
            ,ir_param.item_class                  -- item_div
            ,ir_param.goods_class                 -- prod_div
            ,mcb3.segment1                        -- crowd_code
            ,SUBSTR(mcb3.segment1, 1, 3)          -- crowd_low
            ,SUBSTR(mcb3.segment1, 1, 2)          -- crowd_mid
            ,SUBSTR(mcb3.segment1, 1, 1)          -- crowd_high
            ,itp.item_id                          -- item_id
            ,itp.lot_id                           -- lot_id
            ,itp.trans_date                       -- arrival_date
            ,TO_CHAR(itp.trans_date, gc_char_ym_format) -- arrival_ym
            ,iimb.item_no                         -- item_code
            ,ximb.item_short_name                 -- item_name
            ,rsl.attribute1                       -- 受入返品実績アドオン.取引ID
-- v1.33 Add End
      UNION ALL
      SELECT /*+ leading (xoha xola wdd itp gic1 mcb1 gic2 mcb2 ooha otta) use_nl (xoha xola wdd itp gic1 mcb1 gic2 mcb2 ooha otta) */
             iwm.whse_code                        h_whse_code
            ,iwm.whse_name                        h_whse_name
            ,itp.trans_id                         trans_id
            ,iimb.attribute15                     cost_mng_clss
            ,iimb.lot_ctl                         lot_ctl
            ,xlc.unit_ploce                       actual_unit_price
            ,CASE WHEN INSTR(xrpm.break_col_01,gv_hifn) = 0
                       THEN ''
                  WHEN xrpm.rcv_pay_div = gc_rcv_pay_div_in
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  ELSE SUBSTR(xrpm.break_col_01,INSTR(xrpm.break_col_01,gv_hifn) +1)
             END                                  column_no
            ,itp.reason_code                      reason_code
            ,itp.trans_date                       trans_date
            ,TO_CHAR(itp.trans_date, 'YYYYMM')  trans_ym
            ,CASE WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN TO_CHAR(ABS(TO_NUMBER(xrpm.rcv_pay_div)))
                  ELSE xrpm.rcv_pay_div
             END                                  rcv_pay_div
            ,xrpm.dealings_div                    dealings_div
            ,itp.doc_type                         doc_type
            ,ir_param.item_class                  item_div
            ,ir_param.goods_class                 prod_div
            ,mcb3.segment1                        crowd_code
            ,SUBSTR(mcb3.segment1, 1, 3)          crowd_low
            ,SUBSTR(mcb3.segment1, 1, 2)          crowd_mid
            ,SUBSTR(mcb3.segment1, 1, 1)          crowd_high
            ,itp.item_id                          item_id
            ,itp.lot_id                           lot_id
            ,NVL(itp.trans_qty, 0)                trans_qty
            ,xoha.arrival_date                    arrival_date
            ,TO_CHAR(xoha.arrival_date, gc_char_ym_format) arrival_ym
            ,iimb.item_no                         item_code
            ,ximb.item_short_name                 item_name
      FROM   ic_tran_pnd                      itp
            ,wsh_delivery_details             wdd
            ,oe_order_headers_all             ooha
            ,oe_transaction_types_all         otta
            ,xxwsh_order_headers_all          xoha
            ,xxwsh_order_lines_all            xola
            ,ic_item_mst_b                    iimb
            ,xxcmn_item_mst_b                 ximb
            ,ic_lots_mst                      ilm
            ,xxcmn_lot_cost                   xlc
            ,gmi_item_categories              gic1
            ,mtl_categories_b                 mcb1
            ,gmi_item_categories              gic2
            ,mtl_categories_b                 mcb2
            ,gmi_item_categories              gic3
            ,mtl_categories_b                 mcb3
            ,xxcmn_rcv_pay_mst                xrpm
            ,ic_whse_mst                      iwm
      WHERE  itp.doc_type            = gv_doc_type_omso
      AND    itp.completed_ind       = 1
      AND    xoha.latest_external_flag = 'Y'
      AND    xoha.arrival_date > FND_DATE.STRING_TO_DATE(gd_prv2_dt_chr,gc_char_dt_format)
      AND    xoha.arrival_date < FND_DATE.STRING_TO_DATE(gd_flw_dt_chr,gc_char_dt_format)
      AND    xoha.req_status         IN ('04','08')
      AND    ilm.item_id             = itp.item_id
      AND    ilm.lot_id              = itp.lot_id
      AND    iimb.item_id            = ilm.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(itp.trans_date)
      AND    ximb.end_date_active   >= TRUNC(itp.trans_date)
      AND    gic1.item_id            = itp.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = itp.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    gic3.item_id            = itp.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
      AND    wdd.delivery_detail_id  = itp.line_detail_id
      AND    wdd.source_header_id    = xoha.header_id
      AND    wdd.source_line_id      = xola.line_id
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    ((otta.attribute4           <> '2')
             OR  (otta.attribute4       IS NULL))
      AND    otta.attribute1         IN ('1','2')
      AND    xoha.header_id          = ooha.header_id
      AND    xola.order_header_id    = xoha.order_header_id
      AND    xola.request_item_code  = xola.shipping_item_code
      AND    xrpm.doc_type           = itp.doc_type
      AND    xrpm.dealings_div       IN ('101','103')
      AND    xrpm.shipment_provision_div = DECODE(xoha.req_status,'04','1','08','2')
      AND    xrpm.shipment_provision_div = otta.attribute1
      AND    ((xrpm.ship_prov_rcv_pay_category IS NULL)
             OR (xrpm.ship_prov_rcv_pay_category = otta.attribute11))
      AND    xrpm.break_col_01       IS NOT NULL
      AND    xrpm.item_div_origin    IS NULL
      AND    xrpm.item_div_ahead     IS NULL
      AND    iwm.whse_code           = itp.whse_code
      AND    iwm.whse_code           = ir_param.locat_code
-- 2009/03/05 v1.31 ADD START
      AND    iwm.attribute1          = '0'
-- 2009/03/05 v1.31 ADD END
      UNION ALL
      SELECT /*+ leading (xoha xola wdd itp gic1 mcb1 gic2 mcb2 ooha otta xrpm) use_nl (xoha xola wdd itp gic1 mcb1 gic2 mcb2 ooha otta xrpm) */
             iwm.whse_code                        h_whse_code
            ,iwm.whse_name                        h_whse_name
            ,itp.trans_id                         trans_id
            ,iimb.attribute15                     cost_mng_clss
            ,iimb.lot_ctl                         lot_ctl
            ,xlc.unit_ploce                       actual_unit_price
            ,CASE WHEN INSTR(xrpm.break_col_01,gv_hifn) = 0
                       THEN ''
                  WHEN xrpm.rcv_pay_div = gc_rcv_pay_div_in
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  ELSE SUBSTR(xrpm.break_col_01,INSTR(xrpm.break_col_01,gv_hifn) +1)
             END                                  column_no
            ,itp.reason_code                      reason_code
            ,itp.trans_date                       trans_date
            ,TO_CHAR(itp.trans_date, 'YYYYMM')  trans_ym
            ,CASE WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN TO_CHAR(ABS(TO_NUMBER(xrpm.rcv_pay_div)))
                  ELSE xrpm.rcv_pay_div
             END                                  rcv_pay_div
            ,xrpm.dealings_div                    dealings_div
            ,itp.doc_type                         doc_type
            ,ir_param.item_class                  item_div
            ,ir_param.goods_class                 prod_div
            ,mcb3.segment1                        crowd_code
            ,SUBSTR(mcb3.segment1, 1, 3)          crowd_low
            ,SUBSTR(mcb3.segment1, 1, 2)          crowd_mid
            ,SUBSTR(mcb3.segment1, 1, 1)          crowd_high
            ,iimb.item_id                         item_id
            ,itp.lot_id                           lot_id
            ,NVL(itp.trans_qty, 0)                trans_qty
            ,xoha.arrival_date                    arrival_date
            ,TO_CHAR(xoha.arrival_date, gc_char_ym_format) arrival_ym
            ,iimb.item_no                         item_code
            ,ximb.item_short_name                 item_name
      FROM   ic_tran_pnd                      itp
            ,wsh_delivery_details             wdd
            ,oe_order_headers_all             ooha
            ,oe_transaction_types_all         otta
            ,xxwsh_order_headers_all          xoha
            ,xxwsh_order_lines_all            xola
            ,ic_item_mst_b                    iimb
            ,ic_item_mst_b                    iimb2
            ,xxcmn_item_mst_b                 ximb
            ,ic_lots_mst                      ilm
            ,xxcmn_lot_cost                   xlc
            ,gmi_item_categories              gic1
            ,mtl_categories_b                 mcb1
            ,gmi_item_categories              gic2
            ,mtl_categories_b                 mcb2
            ,gmi_item_categories              gic3
            ,mtl_categories_b                 mcb3
            ,gmi_item_categories              gic4
            ,mtl_categories_b                 mcb4
            ,xxcmn_rcv_pay_mst                xrpm
            ,ic_whse_mst                      iwm
      WHERE  itp.doc_type            = gv_doc_type_omso
      AND    itp.completed_ind       = 1
      AND    xoha.latest_external_flag = 'Y'
      AND    xoha.arrival_date > FND_DATE.STRING_TO_DATE(gd_prv2_dt_chr,gc_char_dt_format)
      AND    xoha.arrival_date < FND_DATE.STRING_TO_DATE(gd_flw_dt_chr,gc_char_dt_format)
      AND    xoha.req_status         = '08'
      AND    ilm.item_id             = itp.item_id
      AND    ilm.lot_id              = itp.lot_id
      AND    iimb.item_id            = itp.item_id
      AND    iimb2.item_no           = xola.request_item_code
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(itp.trans_date)
      AND    ximb.end_date_active   >= TRUNC(itp.trans_date)
      AND    gic1.item_id            = itp.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = itp.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    gic3.item_id            = itp.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
      AND    gic4.item_id            = iimb2.item_id
      AND    gic4.category_set_id    = cn_item_class_id
      AND    gic4.category_id        = mcb4.category_id
      AND    wdd.delivery_detail_id  = itp.line_detail_id
      AND    wdd.source_header_id    = xoha.header_id
      AND    wdd.source_line_id      = xola.line_id
      AND    xola.order_header_id    = xoha.order_header_id
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    ((otta.attribute4           <> '2')
             OR  (otta.attribute4       IS NULL))
      AND    otta.attribute1         = '2'
      AND    xoha.header_id          = ooha.header_id
      AND    xrpm.doc_type           = itp.doc_type
      AND    xrpm.dealings_div       = '106'
      AND    xrpm.shipment_provision_div = DECODE(xoha.req_status,'04','1','08','2')
      AND    xrpm.shipment_provision_div = otta.attribute1
      AND    xrpm.ship_prov_rcv_pay_category = otta.attribute11
      AND    xrpm.item_div_ahead     = mcb4.segment1
      AND    mcb2.segment1           <> '5'
      AND    xrpm.break_col_01       IS NOT NULL
      AND    iwm.whse_code           = itp.whse_code
      AND    iwm.whse_code           = ir_param.locat_code
-- 2009/03/05 v1.31 ADD START
      AND    iwm.attribute1          = '0'
-- 2009/03/05 v1.31 ADD END
      UNION ALL
      SELECT /*+ leading (xoha xola wdd itp gic1 mcb1 gic2 mcb2 ooha otta xrpm) use_nl (xoha xola wdd itp gic1 mcb1 gic2 mcb2 ooha otta xrpm) */
             iwm.whse_code                        h_whse_code
            ,iwm.whse_name                        h_whse_name
            ,itp.trans_id                         trans_id
            ,iimb.attribute15                     cost_mng_clss
            ,iimb.lot_ctl                         lot_ctl
            ,xlc.unit_ploce                       actual_unit_price
            ,CASE WHEN INSTR(xrpm.break_col_01,gv_hifn) = 0
                       THEN ''
                  WHEN xrpm.rcv_pay_div = gc_rcv_pay_div_in
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  ELSE SUBSTR(xrpm.break_col_01,INSTR(xrpm.break_col_01,gv_hifn) +1)
             END                                  column_no
            ,itp.reason_code                      reason_code
            ,itp.trans_date                       trans_date
            ,TO_CHAR(itp.trans_date, 'YYYYMM')  trans_ym
            ,CASE WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN TO_CHAR(ABS(TO_NUMBER(xrpm.rcv_pay_div)))
                  ELSE xrpm.rcv_pay_div
             END                                  rcv_pay_div
            ,xrpm.dealings_div                    dealings_div
            ,itp.doc_type                         doc_type
            ,ir_param.item_class                  item_div
            ,ir_param.goods_class                 prod_div
            ,mcb3.segment1                        crowd_code
            ,SUBSTR(mcb3.segment1, 1, 3)          crowd_low
            ,SUBSTR(mcb3.segment1, 1, 2)          crowd_mid
            ,SUBSTR(mcb3.segment1, 1, 1)          crowd_high
            ,iimb.item_id                         item_id
            ,itp.lot_id                           lot_id
            ,NVL(itp.trans_qty, 0)                trans_qty
            ,xoha.arrival_date                    arrival_date
            ,TO_CHAR(xoha.arrival_date, gc_char_ym_format) arrival_ym
            ,iimb.item_no                         item_code
            ,ximb.item_short_name                 item_name
      FROM   ic_tran_pnd                      itp
            ,wsh_delivery_details             wdd
            ,oe_order_headers_all             ooha
            ,oe_transaction_types_all         otta
            ,xxwsh_order_headers_all          xoha
            ,xxwsh_order_lines_all            xola
            ,ic_item_mst_b                    iimb
            ,ic_item_mst_b                    iimb2
            ,xxcmn_item_mst_b                 ximb
            ,ic_lots_mst                      ilm
            ,xxcmn_lot_cost                   xlc
            ,gmi_item_categories              gic1
            ,mtl_categories_b                 mcb1
            ,gmi_item_categories              gic2
            ,mtl_categories_b                 mcb2
            ,gmi_item_categories              gic3
            ,mtl_categories_b                 mcb3
            ,gmi_item_categories              gic4
            ,mtl_categories_b                 mcb4
            ,xxcmn_rcv_pay_mst                xrpm
            ,ic_whse_mst                      iwm
      WHERE  itp.doc_type            = gv_doc_type_omso
      AND    itp.completed_ind       = 1
      AND    xoha.latest_external_flag = 'Y'
      AND    xoha.arrival_date > FND_DATE.STRING_TO_DATE(gd_prv2_dt_chr,gc_char_dt_format)
      AND    xoha.arrival_date < FND_DATE.STRING_TO_DATE(gd_flw_dt_chr,gc_char_dt_format)
      AND    xoha.req_status         = '04'
      AND    ilm.item_id             = itp.item_id
      AND    ilm.lot_id              = itp.lot_id
      AND    iimb.item_id            = itp.item_id
      AND    iimb2.item_no           = xola.request_item_code
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(itp.trans_date)
      AND    ximb.end_date_active   >= TRUNC(itp.trans_date)
      AND    gic1.item_id            = itp.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = itp.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    gic3.item_id            = itp.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
      AND    gic4.item_id            = iimb2.item_id
      AND    gic4.category_set_id    = cn_item_class_id
      AND    gic4.category_id        = mcb4.category_id
      AND    wdd.delivery_detail_id  = itp.line_detail_id
      AND    wdd.source_header_id    = xoha.header_id
      AND    wdd.source_line_id      = xola.line_id
      AND    xola.order_header_id    = xoha.order_header_id
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    ((otta.attribute4           <> '2')
             OR  (otta.attribute4       IS NULL))
      AND    otta.attribute1         = '1'
      AND    xoha.header_id          = ooha.header_id
      AND    xrpm.doc_type           = itp.doc_type
      AND    xrpm.dealings_div       = '113'
      AND    xrpm.shipment_provision_div = DECODE(xoha.req_status,'04','1','08','2')
      AND    xrpm.item_div_ahead     = mcb4.segment1
      AND    mcb2.segment1           <> '5'
      AND    xrpm.break_col_01       IS NOT NULL
      AND    iwm.whse_code           = itp.whse_code
      AND    iwm.whse_code           = ir_param.locat_code
-- 2009/03/05 v1.31 ADD START
      AND    iwm.attribute1          = '0'
-- 2009/03/05 v1.31 ADD END
      UNION ALL
      SELECT /*+ leading (xoha ooha otta xola wdd itp gic1 mcb1 gic2 mcb2) use_nl (xoha ooha otta xola wdd itp gic1 mcb1 gic2 mcb2) */
             iwm.whse_code                        h_whse_code
            ,iwm.whse_name                        h_whse_name
            ,itp.trans_id                         trans_id
            ,iimb.attribute15                     cost_mng_clss
            ,iimb.lot_ctl                         lot_ctl
            ,xlc.unit_ploce                       actual_unit_price
            ,CASE WHEN INSTR(xrpm.break_col_01,gv_hifn) = 0
                       THEN ''
                  WHEN xrpm.rcv_pay_div = gc_rcv_pay_div_in
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  ELSE SUBSTR(xrpm.break_col_01,INSTR(xrpm.break_col_01,gv_hifn) +1)
             END                                  column_no
            ,itp.reason_code                      reason_code
            ,itp.trans_date                       trans_date
            ,TO_CHAR(itp.trans_date, 'YYYYMM')  trans_ym
            ,CASE WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN TO_CHAR(ABS(TO_NUMBER(xrpm.rcv_pay_div)))
                  ELSE xrpm.rcv_pay_div
             END                                  rcv_pay_div
            ,xrpm.dealings_div                    dealings_div
            ,itp.doc_type                         doc_type
            ,ir_param.item_class                  item_div
            ,ir_param.goods_class                 prod_div
            ,mcb3.segment1                        crowd_code
            ,SUBSTR(mcb3.segment1, 1, 3)          crowd_low
            ,SUBSTR(mcb3.segment1, 1, 2)          crowd_mid
            ,SUBSTR(mcb3.segment1, 1, 1)          crowd_high
            ,itp.item_id                          item_id
            ,itp.lot_id                           lot_id
            ,NVL(itp.trans_qty, 0)                trans_qty
            ,xoha.arrival_date                    arrival_date
            ,TO_CHAR(xoha.arrival_date, gc_char_ym_format) arrival_ym
            ,iimb.item_no                         item_code
            ,ximb.item_short_name                 item_name
      FROM   ic_tran_pnd                      itp
            ,wsh_delivery_details             wdd
            ,oe_order_headers_all             ooha
            ,oe_transaction_types_all         otta
            ,xxwsh_order_headers_all          xoha
            ,xxwsh_order_lines_all            xola
            ,ic_item_mst_b                    iimb
            ,xxcmn_item_mst_b                 ximb
            ,ic_lots_mst                      ilm
            ,xxcmn_lot_cost                   xlc
            ,gmi_item_categories              gic1
            ,mtl_categories_b                 mcb1
            ,gmi_item_categories              gic2
            ,mtl_categories_b                 mcb2
            ,gmi_item_categories              gic3
            ,mtl_categories_b                 mcb3
            ,xxcmn_rcv_pay_mst                xrpm
            ,ic_whse_mst                      iwm
      WHERE  itp.doc_type            = gv_doc_type_omso
      AND    itp.completed_ind       = 1
      AND    xoha.latest_external_flag = 'Y'
      AND    xoha.arrival_date > FND_DATE.STRING_TO_DATE(gd_prv2_dt_chr,gc_char_dt_format)
      AND    xoha.arrival_date < FND_DATE.STRING_TO_DATE(gd_flw_dt_chr,gc_char_dt_format)
      AND    ilm.item_id             = itp.item_id
      AND    ilm.lot_id              = itp.lot_id
      AND    iimb.item_id            = itp.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(itp.trans_date)
      AND    ximb.end_date_active   >= TRUNC(itp.trans_date)
      AND    gic1.item_id            = itp.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = itp.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    gic3.item_id            = itp.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
      AND    wdd.delivery_detail_id  = itp.line_detail_id
      AND    wdd.source_header_id    = xoha.header_id
      AND    wdd.source_line_id      = xola.line_id
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    otta.attribute4         = '2'
      AND    xoha.header_id          = ooha.header_id
      AND    xola.order_header_id    = xoha.order_header_id
      AND    xrpm.doc_type           = itp.doc_type
      AND    xrpm.dealings_div       IN ('504','509')
      AND    xrpm.stock_adjustment_div = otta.attribute4
      AND    xrpm.ship_prov_rcv_pay_category = otta.attribute11
      AND    xrpm.break_col_01       IS NOT NULL
      AND    iwm.whse_code           = itp.whse_code
      AND    iwm.whse_code           = ir_param.locat_code
-- 2009/03/05 v1.31 ADD START
      AND    iwm.attribute1          = '0'
-- 2009/03/05 v1.31 ADD END
      -- 当月受払無しデータ
      UNION ALL
      SELECT /*+ leading (xsims gic1 mcb1 gic2 mcb2 gic3 mcb3 iimb ximb xlc) use_nl (xsims gic1 mcb1 gic2 mcb2 gic3 mcb3 iimb ximb xlc) */
             iwm.whse_code                        h_whse_code
            ,iwm.whse_name                        h_whse_name
            ,NULL                                 trans_id
            ,iimb.attribute15                     cost_mng_clss
            ,iimb.lot_ctl                         lot_ctl
            ,xlc.unit_ploce                       actual_unit_price
            ,'1'                                  column_no
            ,NULL                                 reason_code
            ,gd_s_date                            trans_date
            ,TO_CHAR(gd_s_date, gc_char_ym_format)  trans_ym
            ,'1'                                  rcv_pay_div
            ,NULL                                 dealings_div
            ,NULL                                 doc_type
            ,ir_param.item_class                  item_div
            ,ir_param.goods_class                 prod_div
            ,mcb3.segment1                        crowd_code
            ,SUBSTR(mcb3.segment1, 1, 3)          crowd_low
            ,SUBSTR(mcb3.segment1, 1, 2)          crowd_mid
            ,SUBSTR(mcb3.segment1, 1, 1)          crowd_high
            ,iimb.item_id                         item_id
            ,0                                    lot_id
            ,0                                    trans_qty
            ,gd_s_date                            arrival_date
            ,TO_CHAR(gd_s_date, gc_char_ym_format)  arrival_ym
            ,iimb.item_no                         item_code
            ,ximb.item_short_name                 item_name
      FROM   xxinv_stc_inventory_month_stck   xsims
            ,ic_item_mst_b                    iimb
            ,xxcmn_item_mst_b                 ximb
            ,ic_lots_mst                      ilm
            ,xxcmn_lot_cost                   xlc
            ,gmi_item_categories              gic1
            ,mtl_categories_b                 mcb1
            ,gmi_item_categories              gic2
            ,mtl_categories_b                 mcb2
            ,gmi_item_categories              gic3
            ,mtl_categories_b                 mcb3
            ,ic_whse_mst                      iwm
      WHERE  xsims.item_id           = iimb.item_id
      AND    ximb.item_id            = iimb.item_id
      AND    ilm.item_id             = xsims.item_id
      AND    ilm.lot_id              = xsims.lot_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.start_date_active <= gd_s_date
      AND    ximb.end_date_active   >= gd_s_date
      AND    gic1.item_id            = xsims.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = xsims.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    gic3.item_id            = xsims.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
      AND    iwm.whse_code           = xsims.whse_code
      AND    xsims.invent_ym         = TO_CHAR(gd_s_date, gc_char_ym_format)
      AND    iwm.whse_code           = ir_param.locat_code
-- 2008/12/10 v1.25 UPDATE START
--      AND    xsims.monthly_stock    <> 0
      AND    (
               (xsims.monthly_stock <> 0)
               OR
               (xsims.cargo_stock   <> 0)
             )
      AND    iwm.attribute1          = '0'
-- 2008/12/10 v1.25 UPDATE END
      ORDER BY h_whse_code
              ,crowd_code
              ,item_code
      ;
--
    --===============================================================
    -- 検索条件.帳票種別          ⇒ 品目別
    -- 検索条件.群種別            ⇒ 群別
    -- 検索条件.倉庫コード        ⇒ 入力なし
    -- 検索条件.群コード          ⇒ 入力あり
    -- 検索条件.経理群コード      ⇒ 入力なし/入力あり
    --===============================================================
    CURSOR get_data_cur05 IS
      SELECT /*+ leading (xmrh xmril ixm itp gic2 mcb2 gic1 mcb1 iimb ximb) use_nl (xmrh xmril ixm itp gic2 mcb2 gic1 mcb1 iimb ximb) */
             NULL                                 h_whse_code
            ,NULL                                 h_whse_name
            ,itp.trans_id                         trans_id
            ,iimb.attribute15                     cost_mng_clss
            ,iimb.lot_ctl                         lot_ctl
            ,xlc.unit_ploce                       actual_unit_price
            ,CASE WHEN INSTR(xrpm.break_col_01,gv_hifn) = 0
                       THEN ''
                  WHEN xrpm.rcv_pay_div = gc_rcv_pay_div_in
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  ELSE SUBSTR(xrpm.break_col_01,INSTR(xrpm.break_col_01,gv_hifn) +1)
             END                                  column_no
            ,itp.reason_code                      reason_code
            ,itp.trans_date                       trans_date
            ,TO_CHAR(itp.trans_date, 'YYYYMM')  trans_ym
            ,CASE WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN TO_CHAR(ABS(TO_NUMBER(xrpm.rcv_pay_div)))
                  ELSE xrpm.rcv_pay_div
             END                                  rcv_pay_div
            ,xrpm.dealings_div                    dealings_div
            ,itp.doc_type                         doc_type
            ,ir_param.item_class                  item_div
            ,ir_param.goods_class                 prod_div
            ,mcb3.segment1                        crowd_code
            ,SUBSTR(mcb3.segment1, 1, 3)          crowd_low
            ,SUBSTR(mcb3.segment1, 1, 2)          crowd_mid
            ,SUBSTR(mcb3.segment1, 1, 1)          crowd_high
            ,itp.item_id                          item_id
            ,itp.lot_id                           lot_id
            ,NVL(itp.trans_qty, 0)                trans_qty
            ,xmrh.actual_arrival_date             arrival_date
            ,TO_CHAR(xmrh.actual_arrival_date, gc_char_ym_format) arrival_ym
            ,iimb.item_no                         item_code
            ,ximb.item_short_name                 item_name
      FROM   ic_tran_pnd                      itp
            ,ic_xfer_mst                      ixm
            ,xxinv_mov_req_instr_headers      xmrh
            ,xxinv_mov_req_instr_lines        xmril
            ,ic_item_mst_b                    iimb
            ,xxcmn_item_mst_b                 ximb
            ,ic_lots_mst                      ilm
            ,xxcmn_lot_cost                   xlc
            ,gmi_item_categories              gic1
            ,mtl_categories_b                 mcb1
            ,gmi_item_categories              gic2
            ,mtl_categories_b                 mcb2
            ,gmi_item_categories              gic3
            ,mtl_categories_b                 mcb3
            ,xxcmn_rcv_pay_mst                xrpm
-- 2009/03/05 v1.31 ADD START
            ,ic_whse_mst                      iwm
-- 2009/03/05 v1.31 ADD END
      WHERE  itp.doc_type            = gv_doc_type_xfer
      AND    itp.reason_code         = gv_reason_code_xfer
      AND    itp.completed_ind       = 1
      AND    xmrh.actual_arrival_date > FND_DATE.STRING_TO_DATE(gd_prv1_dt_chr,gc_char_dt_format)
      AND    xmrh.actual_arrival_date < FND_DATE.STRING_TO_DATE(gd_flw_dt_chr,gc_char_dt_format)
      AND    xmrh.mov_hdr_id         = xmril.mov_hdr_id
      AND    itp.doc_id              = ixm.transfer_id
      AND    ixm.attribute1          = TO_CHAR(xmril.mov_line_id)
      AND    ilm.item_id             = itp.item_id
      AND    ilm.lot_id              = itp.lot_id
      AND    iimb.item_id            = itp.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(itp.trans_date)
      AND    ximb.end_date_active   >= TRUNC(itp.trans_date)
      AND    gic1.item_id            = itp.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = itp.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    gic3.item_id            = itp.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
      AND    xrpm.rcv_pay_div        = CASE
                                       WHEN itp.trans_qty >= 0 THEN 1
                                       ELSE -1
                                       END
      AND    xrpm.doc_type           = itp.doc_type
      AND    xrpm.reason_code        = itp.reason_code
      AND    xrpm.break_col_01       IS NOT NULL
      AND    mcb3.segment1           = lt_crowd_code
-- 2009/03/05 v1.31 ADD START
      AND    iwm.whse_code           = itp.whse_code
      AND    iwm.attribute1          = '0'
-- 2009/03/05 v1.31 ADD END
      UNION ALL
      SELECT /*+ leading (xmrh xmril ijm iaj itc gic2 mcb2 gic1 mcb1 ilm iimb ximb) use_nl (xmrh xmril ijm iaj itc gic2 mcb2 gic1 mcb1 ilm iimb ximb) */
             NULL                                 h_whse_code
            ,NULL                                 h_whse_name
            ,itc.trans_id                         trans_id
            ,iimb.attribute15                     cost_mng_clss
            ,iimb.lot_ctl                         lot_ctl
            ,xlc.unit_ploce                       actual_unit_price
            ,CASE WHEN INSTR(xrpm.break_col_01,gv_hifn) = 0
                       THEN ''
                  WHEN xrpm.rcv_pay_div = gc_rcv_pay_div_in
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  ELSE SUBSTR(xrpm.break_col_01,INSTR(xrpm.break_col_01,gv_hifn) +1)
             END                                  column_no
            ,itc.reason_code                      reason_code
            ,itc.trans_date                       trans_date
            ,TO_CHAR(itc.trans_date, 'YYYYMM')  trans_ym
            ,CASE WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN TO_CHAR(ABS(TO_NUMBER(xrpm.rcv_pay_div)))
                  ELSE xrpm.rcv_pay_div
             END                                  rcv_pay_div
            ,xrpm.dealings_div                    dealings_div
            ,itc.doc_type                         doc_type
            ,ir_param.item_class                  item_div
            ,ir_param.goods_class                 prod_div
            ,mcb3.segment1                        crowd_code
            ,SUBSTR(mcb3.segment1, 1, 3)          crowd_low
            ,SUBSTR(mcb3.segment1, 1, 2)          crowd_mid
            ,SUBSTR(mcb3.segment1, 1, 1)          crowd_high
            ,itc.item_id                          item_id
            ,itc.lot_id                           lot_id
            ,NVL(itc.trans_qty, 0)                trans_qty
            ,xmrh.actual_arrival_date             arrival_date
            ,TO_CHAR(xmrh.actual_arrival_date, gc_char_ym_format) arrival_ym
            ,iimb.item_no                         item_code
            ,ximb.item_short_name                 item_name
      FROM   ic_tran_cmp                      itc
            ,ic_adjs_jnl                      iaj
            ,ic_jrnl_mst                      ijm
            ,xxinv_mov_req_instr_headers      xmrh
            ,xxinv_mov_req_instr_lines        xmril
            ,ic_item_mst_b                    iimb
            ,xxcmn_item_mst_b                 ximb
            ,ic_lots_mst                      ilm
            ,xxcmn_lot_cost                   xlc
            ,gmi_item_categories              gic1
            ,mtl_categories_b                 mcb1
            ,gmi_item_categories              gic2
            ,mtl_categories_b                 mcb2
            ,gmi_item_categories              gic3
            ,mtl_categories_b                 mcb3
            ,xxcmn_rcv_pay_mst                xrpm
-- 2009/03/05 v1.31 ADD START
            ,ic_whse_mst                      iwm
-- 2009/03/05 v1.31 ADD END
      WHERE  itc.doc_type            = gv_doc_type_trni
      AND    itc.reason_code         = gv_reason_code_trni
      AND    xmrh.actual_arrival_date > FND_DATE.STRING_TO_DATE(gd_prv1_dt_chr,gc_char_dt_format)
      AND    xmrh.actual_arrival_date < FND_DATE.STRING_TO_DATE(gd_flw_dt_chr,gc_char_dt_format)
      AND    xmrh.mov_hdr_id         = xmril.mov_hdr_id
      AND    itc.doc_type            = iaj.trans_type
      AND    itc.doc_id              = iaj.doc_id
      AND    itc.doc_line            = iaj.doc_line
      AND    ijm.journal_id          = iaj.journal_id
      AND    ijm.attribute1          = TO_CHAR(xmril.mov_line_id)
      AND    ilm.item_id             = itc.item_id
      AND    ilm.lot_id              = itc.lot_id
      AND    iimb.item_id            = ilm.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(itc.trans_date)
      AND    ximb.end_date_active   >= TRUNC(itc.trans_date)
      AND    gic1.item_id            = itc.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = itc.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    gic3.item_id            = itc.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
-- 2008/11/19 v1.18 ADD START
      AND    xrpm.rcv_pay_div        = CASE
                                       WHEN itc.trans_qty >= 0 THEN 1
                                       ELSE -1
                                       END
-- 2008/11/19 v1.18 ADD END
      AND    xrpm.doc_type           = itc.doc_type
      AND    xrpm.reason_code        = itc.reason_code
      AND    xrpm.rcv_pay_div        = itc.line_type
      AND    xrpm.break_col_01       IS NOT NULL
      AND    mcb3.segment1           = lt_crowd_code
-- 2009/03/05 v1.31 ADD START
      AND    iwm.whse_code           = itc.whse_code
      AND    iwm.attribute1          = '0'
-- 2009/03/05 v1.31 ADD END
      UNION ALL
      SELECT /*+ leading (itc gic1 mcb1 gic2 mcb2) use_nl (itc gic1 mcb1 gic2 mcb2)*/
             NULL                                 h_whse_code
            ,NULL                                 h_whse_name
            ,itc.trans_id                         trans_id
            ,iimb.attribute15                     cost_mng_clss
            ,iimb.lot_ctl                         lot_ctl
            ,xlc.unit_ploce                       actual_unit_price
            ,CASE WHEN INSTR(xrpm.break_col_01,gv_hifn) = 0
                       THEN ''
                  WHEN xrpm.rcv_pay_div = gc_rcv_pay_div_in
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  ELSE SUBSTR(xrpm.break_col_01,INSTR(xrpm.break_col_01,gv_hifn) +1)
             END                                  column_no
            ,itc.reason_code                      reason_code
            ,itc.trans_date                       trans_date
            ,TO_CHAR(itc.trans_date, 'YYYYMM')  trans_ym
            ,CASE WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN TO_CHAR(ABS(TO_NUMBER(xrpm.rcv_pay_div)))
                  ELSE xrpm.rcv_pay_div
             END                                  rcv_pay_div
            ,xrpm.dealings_div                    dealings_div
            ,itc.doc_type                         doc_type
            ,ir_param.item_class                  item_div
            ,ir_param.goods_class                 prod_div
            ,mcb3.segment1                        crowd_code
            ,SUBSTR(mcb3.segment1, 1, 3)          crowd_low
            ,SUBSTR(mcb3.segment1, 1, 2)          crowd_mid
            ,SUBSTR(mcb3.segment1, 1, 1)          crowd_high
            ,itc.item_id                          item_id
            ,itc.lot_id                           lot_id
            ,NVL(itc.trans_qty, 0)                trans_qty
            ,itc.trans_date                       arrival_date
            ,TO_CHAR(itc.trans_date, gc_char_ym_format) arrival_ym
            ,iimb.item_no                         item_code
            ,ximb.item_short_name                 item_name
      FROM   ic_tran_cmp                      itc
            ,ic_item_mst_b                    iimb
            ,xxcmn_item_mst_b                 ximb
            ,ic_lots_mst                      ilm
            ,xxcmn_lot_cost                   xlc
            ,gmi_item_categories              gic1
            ,mtl_categories_b                 mcb1
            ,gmi_item_categories              gic2
            ,mtl_categories_b                 mcb2
            ,gmi_item_categories              gic3
            ,mtl_categories_b                 mcb3
            ,xxcmn_rcv_pay_mst                xrpm
-- 2009/03/05 v1.31 ADD START
            ,ic_whse_mst                      iwm
-- 2009/03/05 v1.31 ADD END
      WHERE  itc.doc_type            = gv_doc_type_adji    --文書タイプ
      AND    itc.reason_code        IN ('X911'
                                       ,'X912'
                                       ,'X921'
                                       ,'X922'
                                       ,'X931'
                                       ,'X932'
                                       ,'X941'
                                       ,'X952'
                                       ,'X953'
                                       ,'X954'
                                       ,'X955'
                                       ,'X956'
                                       ,'X957'
                                       ,'X958'
                                       ,'X959'
                                       ,'X960'
                                       ,'X961'
                                       ,'X962'
                                       ,'X963'
-- 2008/11/19 v1.18 UPDATE START
--                                       ,'X964')
                                       ,'X964'
                                       ,'X965'
                                       ,'X966')
-- 2008/11/19 v1.18 UPDATE END
      AND    itc.trans_date > FND_DATE.STRING_TO_DATE(gd_prv1_dt_chr,gc_char_dt_format)
      AND    itc.trans_date < FND_DATE.STRING_TO_DATE(gd_flw_dt_chr,gc_char_dt_format)
      AND    ilm.item_id             = itc.item_id
      AND    ilm.lot_id              = itc.lot_id
      AND    iimb.item_id            = ilm.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(itc.trans_date)
      AND    ximb.end_date_active   >= TRUNC(itc.trans_date)
      AND    gic1.item_id            = itc.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = itc.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    gic3.item_id            = itc.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
      AND    xrpm.doc_type           = itc.doc_type
      AND    xrpm.reason_code        = itc.reason_code
      AND    xrpm.break_col_01       IS NOT NULL
      AND    mcb3.segment1           = lt_crowd_code
-- 2009/03/05 v1.31 ADD START
      AND    iwm.whse_code           = itc.whse_code
      AND    iwm.attribute1          = '0'
-- 2009/03/05 v1.31 ADD END
      UNION ALL
      SELECT /*+ leading (itc gic1 mcb1 gic2 mcb2 xrpm) use_nl (itc gic1 mcb1 gic2 mcb2 xrpm) */
             NULL                                 h_whse_code
            ,NULL                                 h_whse_name
-- v1.33 Mod Start
--            ,itc.trans_id                         trans_id
            ,NULL                                 trans_id
-- v1.33 Mod End
            ,iimb.attribute15                     cost_mng_clss
            ,iimb.lot_ctl                         lot_ctl
            ,xlc.unit_ploce                       actual_unit_price
            ,CASE WHEN INSTR(xrpm.break_col_01,gv_hifn) = 0
                       THEN ''
                  WHEN xrpm.rcv_pay_div = gc_rcv_pay_div_in
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  ELSE SUBSTR(xrpm.break_col_01,INSTR(xrpm.break_col_01,gv_hifn) +1)
             END                                  column_no
            ,itc.reason_code                      reason_code
            ,itc.trans_date                       trans_date
            ,TO_CHAR(itc.trans_date, 'YYYYMM')  trans_ym
            ,CASE WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN TO_CHAR(ABS(TO_NUMBER(xrpm.rcv_pay_div)))
                  ELSE xrpm.rcv_pay_div
             END                                  rcv_pay_div
            ,xrpm.dealings_div                    dealings_div
            ,itc.doc_type                         doc_type
            ,ir_param.item_class                  item_div
            ,ir_param.goods_class                 prod_div
            ,mcb3.segment1                        crowd_code
            ,SUBSTR(mcb3.segment1, 1, 3)          crowd_low
            ,SUBSTR(mcb3.segment1, 1, 2)          crowd_mid
            ,SUBSTR(mcb3.segment1, 1, 1)          crowd_high
            ,itc.item_id                          item_id
            ,itc.lot_id                           lot_id
-- v1.33 Mod Start
--            ,NVL(itc.trans_qty, 0)                trans_qty
            ,SUM(NVL(itc.trans_qty, 0))           trans_qty
-- v1.33 Mod End
            ,itc.trans_date                       arrival_date
            ,TO_CHAR(itc.trans_date, gc_char_ym_format) arrival_ym
            ,iimb.item_no                         item_code
            ,ximb.item_short_name                 item_name
      FROM   ic_tran_cmp                      itc
-- v1.33 Add Start
            ,ic_adjs_jnl                      iaj
            ,ic_jrnl_mst                      ijm
-- v1.33 Add End
            ,ic_item_mst_b                    iimb
            ,xxcmn_item_mst_b                 ximb
            ,ic_lots_mst                      ilm
            ,xxcmn_lot_cost                   xlc
            ,gmi_item_categories              gic1
            ,mtl_categories_b                 mcb1
            ,gmi_item_categories              gic2
            ,mtl_categories_b                 mcb2
            ,gmi_item_categories              gic3
            ,mtl_categories_b                 mcb3
            ,xxcmn_rcv_pay_mst                xrpm
-- 2009/03/05 v1.31 ADD START
            ,ic_whse_mst                      iwm
-- 2009/03/05 v1.31 ADD END
      WHERE  itc.doc_type            = gv_doc_type_adji
      AND    itc.reason_code         = gv_reason_code_adji_po
      AND    itc.trans_date > FND_DATE.STRING_TO_DATE(gd_prv1_dt_chr,gc_char_dt_format)
      AND    itc.trans_date < FND_DATE.STRING_TO_DATE(gd_flw_dt_chr,gc_char_dt_format)
-- v1.33 Add Start
      AND    iaj.trans_type          = itc.doc_type
      AND    iaj.doc_id              = itc.doc_id
      AND    iaj.doc_line            = itc.doc_line
      AND    ijm.journal_id          = iaj.journal_id
-- v1.33 Add End
      AND    ilm.item_id             = itc.item_id
      AND    ilm.lot_id              = itc.lot_id
      AND    iimb.item_id            = ilm.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(itc.trans_date)
      AND    ximb.end_date_active   >= TRUNC(itc.trans_date)
      AND    gic1.item_id            = itc.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = itc.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    gic3.item_id            = itc.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
      AND    xrpm.doc_type           = itc.doc_type
      AND    xrpm.reason_code        = itc.reason_code
      AND    xrpm.break_col_01       IS NOT NULL
      AND    mcb3.segment1           = lt_crowd_code
-- 2009/03/05 v1.31 ADD START
      AND    iwm.whse_code           = itc.whse_code
      AND    iwm.attribute1          = '0'
-- 2009/03/05 v1.31 ADD END
-- v1.33 Add Start
      GROUP BY
             iimb.attribute15                     -- cost_mng_clss
            ,iimb.lot_ctl                         -- lot_ctl
            ,xlc.unit_ploce                       -- actual_unit_price
            ,CASE WHEN INSTR(xrpm.break_col_01,gv_hifn) = 0
                       THEN ''
                  WHEN xrpm.rcv_pay_div = gc_rcv_pay_div_in
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  ELSE SUBSTR(xrpm.break_col_01,INSTR(xrpm.break_col_01,gv_hifn) +1)
             END                                  -- column_no
            ,itc.reason_code                      -- reason_code
            ,itc.trans_date                       -- trans_date
            ,TO_CHAR(itc.trans_date, 'YYYYMM')    -- trans_ym
            ,CASE WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN TO_CHAR(ABS(TO_NUMBER(xrpm.rcv_pay_div)))
                  ELSE xrpm.rcv_pay_div
             END                                  -- rcv_pay_div
            ,xrpm.dealings_div                    -- dealings_div
            ,itc.doc_type                         -- doc_type
            ,ir_param.item_class                  -- item_div
            ,ir_param.goods_class                 -- prod_div
            ,mcb3.segment1                        -- crowd_code
            ,SUBSTR(mcb3.segment1, 1, 3)          -- crowd_low
            ,SUBSTR(mcb3.segment1, 1, 2)          -- crowd_mid
            ,SUBSTR(mcb3.segment1, 1, 1)          -- crowd_high
            ,itc.item_id                          -- item_id
            ,itc.lot_id                           -- lot_id
            ,itc.trans_date                       -- arrival_date
            ,TO_CHAR(itc.trans_date, gc_char_ym_format) -- arrival_ym
            ,iimb.item_no                         -- item_code
            ,ximb.item_short_name                 -- item_name
            ,ijm.attribute1                       -- 受入返品実績アドオン.取引ID
-- v1.33 Add End
      UNION ALL
      SELECT /*+ leading (itc gic1 mcb1 gic2 mcb2 xrpm) use_nl (itc gic1 mcb1 gic2 mcb2 xrpm) */
             NULL                                 h_whse_code
            ,NULL                                 h_whse_name
            ,itc.trans_id                         trans_id
            ,iimb.attribute15                     cost_mng_clss
            ,iimb.lot_ctl                         lot_ctl
            ,xlc.unit_ploce                       actual_unit_price
            ,CASE WHEN INSTR(xrpm.break_col_01,gv_hifn) = 0
                       THEN ''
                  WHEN xrpm.rcv_pay_div = gc_rcv_pay_div_in
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  ELSE SUBSTR(xrpm.break_col_01,INSTR(xrpm.break_col_01,gv_hifn) +1)
             END                                  column_no
            ,itc.reason_code                      reason_code
            ,itc.trans_date                       trans_date
            ,TO_CHAR(itc.trans_date, 'YYYYMM')  trans_ym
            ,CASE WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN TO_CHAR(ABS(TO_NUMBER(xrpm.rcv_pay_div)))
                  ELSE xrpm.rcv_pay_div
             END                                  rcv_pay_div
            ,xrpm.dealings_div                    dealings_div
            ,itc.doc_type                         doc_type
            ,ir_param.item_class                  item_div
            ,ir_param.goods_class                 prod_div
            ,mcb3.segment1                        crowd_code
            ,SUBSTR(mcb3.segment1, 1, 3)          crowd_low
            ,SUBSTR(mcb3.segment1, 1, 2)          crowd_mid
            ,SUBSTR(mcb3.segment1, 1, 1)          crowd_high
            ,itc.item_id                          item_id
            ,itc.lot_id                           lot_id
            ,NVL(itc.trans_qty, 0)                trans_qty
            ,itc.trans_date                       arrival_date
            ,TO_CHAR(itc.trans_date, gc_char_ym_format) arrival_ym
            ,iimb.item_no                         item_code
            ,ximb.item_short_name                 item_name
      FROM   ic_tran_cmp                      itc
            ,ic_item_mst_b                    iimb
            ,xxcmn_item_mst_b                 ximb
            ,ic_lots_mst                      ilm
            ,xxcmn_lot_cost                   xlc
            ,gmi_item_categories              gic1
            ,mtl_categories_b                 mcb1
            ,gmi_item_categories              gic2
            ,mtl_categories_b                 mcb2
            ,gmi_item_categories              gic3
            ,mtl_categories_b                 mcb3
            ,xxcmn_rcv_pay_mst                xrpm
-- 2009/03/05 v1.31 ADD START
            ,ic_whse_mst                      iwm
-- 2009/03/05 v1.31 ADD END
      WHERE  itc.doc_type            = gv_doc_type_adji
      AND    itc.reason_code         = gv_reason_code_adji_hama
      AND    itc.trans_date > FND_DATE.STRING_TO_DATE(gd_prv1_dt_chr,gc_char_dt_format)
      AND    itc.trans_date < FND_DATE.STRING_TO_DATE(gd_flw_dt_chr,gc_char_dt_format)
      AND    ilm.item_id             = itc.item_id
      AND    ilm.lot_id              = itc.lot_id
      AND    iimb.item_id            = ilm.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(itc.trans_date)
      AND    ximb.end_date_active   >= TRUNC(itc.trans_date)
      AND    gic1.item_id            = itc.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = itc.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    gic3.item_id            = itc.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
      AND    xrpm.doc_type           = itc.doc_type
      AND    xrpm.reason_code        = itc.reason_code
      AND    xrpm.break_col_01       IS NOT NULL
      AND    mcb3.segment1           = lt_crowd_code
-- 2009/03/05 v1.31 ADD START
      AND    iwm.whse_code           = itc.whse_code
      AND    iwm.attribute1          = '0'
-- 2009/03/05 v1.31 ADD END
      UNION ALL
      SELECT /*+ leading (xmrh xmrl ijm iaj itc gic1 mcb1 gic2 mcb2) use_nl (xmrh xmrl ijm iaj itc gic1 mcb1 gic2 mcb2) */
             NULL                                 h_whse_code
            ,NULL                                 h_whse_name
            ,itc.trans_id                         trans_id
            ,iimb.attribute15                     cost_mng_clss
            ,iimb.lot_ctl                         lot_ctl
            ,xlc.unit_ploce                       actual_unit_price
            ,CASE WHEN INSTR(xrpm.break_col_01,gv_hifn) = 0
                       THEN ''
                  WHEN xrpm.rcv_pay_div = gc_rcv_pay_div_in
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  ELSE SUBSTR(xrpm.break_col_01,INSTR(xrpm.break_col_01,gv_hifn) +1)
             END                                  column_no
            ,itc.reason_code                      reason_code
            ,itc.trans_date                       trans_date
            ,TO_CHAR(itc.trans_date, 'YYYYMM')  trans_ym
-- 2008/12/11 v1.26 N.Yoshida mod start
--            ,gc_rcv_pay_div_adj                   rcv_pay_div
            ,xrpm.rcv_pay_div                     rcv_pay_div
-- 2008/12/11 v1.26 N.Yoshida mod end
            ,xrpm.dealings_div                    dealings_div
            ,itc.doc_type                         doc_type
            ,ir_param.item_class                  item_div
            ,ir_param.goods_class                 prod_div
            ,mcb3.segment1                        crowd_code
            ,SUBSTR(mcb3.segment1, 1, 3)          crowd_low
            ,SUBSTR(mcb3.segment1, 1, 2)          crowd_mid
            ,SUBSTR(mcb3.segment1, 1, 1)          crowd_high
            ,itc.item_id                          item_id
            ,itc.lot_id                           lot_id
-- 2008/12/11 v1.26 N.Yoshida mod start
--            ,ABS(NVL(itc.trans_qty, 0))           trans_qty
            ,NVL(itc.trans_qty, 0)                trans_qty
-- 2008/12/11 v1.26 N.Yoshida mod end
            ,xmrh.actual_arrival_date             arrival_date
            ,TO_CHAR(xmrh.actual_arrival_date, gc_char_ym_format) arrival_ym
            ,iimb.item_no                         item_code
            ,ximb.item_short_name                 item_name
      FROM   ic_tran_cmp                      itc
            ,ic_adjs_jnl                      iaj
            ,ic_jrnl_mst                      ijm
            ,xxinv_mov_req_instr_headers      xmrh
            ,xxinv_mov_req_instr_lines        xmrl
            ,ic_item_mst_b                    iimb
            ,xxcmn_item_mst_b                 ximb
            ,ic_lots_mst                      ilm
            ,xxcmn_lot_cost                   xlc
            ,gmi_item_categories              gic1
            ,mtl_categories_b                 mcb1
            ,gmi_item_categories              gic2
            ,mtl_categories_b                 mcb2
            ,gmi_item_categories              gic3
            ,mtl_categories_b                 mcb3
            ,xxcmn_rcv_pay_mst                xrpm
-- 2009/03/05 v1.31 ADD START
            ,ic_whse_mst                      iwm
-- 2009/03/05 v1.31 ADD END
      WHERE  itc.doc_type            = gv_doc_type_adji
      AND    itc.reason_code         = gv_reason_code_adji_move
      AND    xmrh.actual_arrival_date > FND_DATE.STRING_TO_DATE(gd_prv1_dt_chr,gc_char_dt_format)
      AND    xmrh.actual_arrival_date < FND_DATE.STRING_TO_DATE(gd_flw_dt_chr,gc_char_dt_format)
      AND    iaj.trans_type          = itc.doc_type
      AND    iaj.doc_id              = itc.doc_id
      AND    iaj.doc_line            = itc.doc_line
      AND    ijm.journal_id          = iaj.journal_id
      AND    ijm.attribute1          = TO_CHAR(xmrl.mov_line_id)
      AND    xmrh.mov_hdr_id         = xmrl.mov_hdr_id
      AND    ilm.item_id             = itc.item_id
      AND    ilm.lot_id              = itc.lot_id
      AND    iimb.item_id            = ilm.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(itc.trans_date)
      AND    ximb.end_date_active   >= TRUNC(itc.trans_date)
      AND    gic1.item_id            = itc.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = itc.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    gic3.item_id            = itc.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
-- 2008/12/11 v1.26 N.Yoshida mod start
      AND    xrpm.rcv_pay_div        = CASE
--                                       WHEN itc.trans_qty >= 0 THEN 1
--                                       ELSE -1
                                       WHEN itc.trans_qty >= 0 THEN -1
                                       ELSE 1
                                       END
-- 2008/12/11 v1.26 N.Yoshida mod end
      AND    xrpm.doc_type           = itc.doc_type
      AND    xrpm.reason_code        = itc.reason_code
      AND    xrpm.break_col_01       IS NOT NULL
      AND    mcb3.segment1           = lt_crowd_code
-- 2009/03/05 v1.31 ADD START
      AND    iwm.whse_code           = itc.whse_code
      AND    iwm.attribute1          = '0'
-- 2009/03/05 v1.31 ADD END
      UNION ALL
      SELECT /*+ leading (itc gic1 mcb1 gic2 mcb2) use_nl (itc gic1 mcb1 gic2 mcb2) */
             NULL                                 h_whse_code
            ,NULL                                 h_whse_name
            ,itc.trans_id                         trans_id
            ,iimb.attribute15                     cost_mng_clss
            ,iimb.lot_ctl                         lot_ctl
            ,xlc.unit_ploce                       actual_unit_price
            ,CASE WHEN INSTR(xrpm.break_col_01,gv_hifn) = 0
                       THEN ''
                  WHEN xrpm.rcv_pay_div = gc_rcv_pay_div_in
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  ELSE SUBSTR(xrpm.break_col_01,INSTR(xrpm.break_col_01,gv_hifn) +1)
             END                                  column_no
            ,itc.reason_code                      reason_code
            ,itc.trans_date                       trans_date
            ,TO_CHAR(itc.trans_date, 'YYYYMM')  trans_ym
            ,CASE WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN TO_CHAR(ABS(TO_NUMBER(xrpm.rcv_pay_div)))
                  ELSE xrpm.rcv_pay_div
             END                                  rcv_pay_div
            ,xrpm.dealings_div                    dealings_div
            ,itc.doc_type                         doc_type
            ,ir_param.item_class                  item_div
            ,ir_param.goods_class                 prod_div
            ,mcb3.segment1                        crowd_code
            ,SUBSTR(mcb3.segment1, 1, 3)          crowd_low
            ,SUBSTR(mcb3.segment1, 1, 2)          crowd_mid
            ,SUBSTR(mcb3.segment1, 1, 1)          crowd_high
            ,itc.item_id                          item_id
            ,itc.lot_id                           lot_id
            ,NVL(itc.trans_qty, 0)                trans_qty
            ,itc.trans_date                       arrival_date
            ,TO_CHAR(itc.trans_date, gc_char_ym_format) arrival_ym
            ,iimb.item_no                         item_code
            ,ximb.item_short_name                 item_name
      FROM   ic_tran_cmp                      itc
            ,ic_item_mst_b                    iimb
            ,xxcmn_item_mst_b                 ximb
            ,ic_lots_mst                      ilm
            ,xxcmn_lot_cost                   xlc
            ,gmi_item_categories              gic1
            ,mtl_categories_b                 mcb1
            ,gmi_item_categories              gic2
            ,mtl_categories_b                 mcb2
            ,gmi_item_categories              gic3
            ,mtl_categories_b                 mcb3
            ,xxcmn_rcv_pay_mst                xrpm
-- 2009/03/05 v1.31 ADD START
            ,ic_whse_mst                      iwm
-- 2009/03/05 v1.31 ADD END
      WHERE  itc.doc_type            = gv_doc_type_adji
      AND    itc.reason_code        IN (gv_reason_code_adji_itm
                                       ,gv_reason_code_adji_itm_u
                                       ,gv_reason_code_adji_snt_u
                                       ,gv_reason_code_adji_snt)
      AND    itc.trans_date > FND_DATE.STRING_TO_DATE(gd_prv1_dt_chr,gc_char_dt_format)
      AND    itc.trans_date < FND_DATE.STRING_TO_DATE(gd_flw_dt_chr,gc_char_dt_format)
      AND    ilm.item_id             = itc.item_id
      AND    ilm.lot_id              = itc.lot_id
      AND    iimb.item_id            = ilm.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(itc.trans_date)
      AND    ximb.end_date_active   >= TRUNC(itc.trans_date)
      AND    gic1.item_id            = itc.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = itc.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    gic3.item_id            = itc.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
-- 2008/11/19 v1.18 DELETE START
      --AND    xrpm.rcv_pay_div        = CASE
      --                                 WHEN itc.trans_qty >= 0 THEN 1
      --                                 ELSE -1
      --                                 END
-- 2008/11/19 v1.18 DELETE END
      AND    xrpm.doc_type           = itc.doc_type
      AND    xrpm.reason_code        = itc.reason_code
      AND    xrpm.break_col_01       IS NOT NULL
      AND    mcb3.segment1           = lt_crowd_code
-- 2009/03/05 v1.31 ADD START
      AND    iwm.whse_code           = itc.whse_code
      AND    iwm.attribute1          = '0'
-- 2009/03/05 v1.31 ADD END
      UNION ALL
      SELECT /*+ leading (itp gic1 mcb1 gic2 mcb2) use_nl (itp gic1 mcb1 gic2 mcb2)*/
             NULL                                 h_whse_code
            ,NULL                                 h_whse_name
            ,itp.trans_id                         trans_id
            ,iimb.attribute15                     cost_mng_clss
            ,iimb.lot_ctl                         lot_ctl
            ,xlc.unit_ploce                       actual_unit_price
            ,CASE WHEN INSTR(xrpm.break_col_01,gv_hifn) = 0
                       THEN ''
                  WHEN xrpm.rcv_pay_div = gc_rcv_pay_div_in
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  ELSE SUBSTR(xrpm.break_col_01,INSTR(xrpm.break_col_01,gv_hifn) +1)
             END                                  column_no
            ,itp.reason_code                      reason_code
            ,itp.trans_date                       trans_date
            ,TO_CHAR(itp.trans_date, 'YYYYMM')  trans_ym
            ,CASE WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN TO_CHAR(ABS(TO_NUMBER(xrpm.rcv_pay_div)))
                  ELSE xrpm.rcv_pay_div
             END                                  rcv_pay_div
            ,xrpm.dealings_div                    dealings_div
            ,itp.doc_type                         doc_type
            ,ir_param.item_class                  item_div
            ,ir_param.goods_class                 prod_div
            ,mcb3.segment1                        crowd_code
            ,SUBSTR(mcb3.segment1, 1, 3)          crowd_low
            ,SUBSTR(mcb3.segment1, 1, 2)          crowd_mid
            ,SUBSTR(mcb3.segment1, 1, 1)          crowd_high
            ,itp.item_id                          item_id
            ,itp.lot_id                           lot_id
            ,NVL(itp.trans_qty, 0)                trans_qty
            ,itp.trans_date                       arrival_date
            ,TO_CHAR(itp.trans_date, gc_char_ym_format) arrival_ym
            ,iimb.item_no                         item_code
            ,ximb.item_short_name                 item_name
      FROM   ic_tran_pnd                      itp
            ,ic_item_mst_b                    iimb
            ,xxcmn_item_mst_b                 ximb
            ,ic_lots_mst                      ilm
            ,xxcmn_lot_cost                   xlc
            ,gmi_item_categories              gic1
            ,mtl_categories_b                 mcb1
            ,gmi_item_categories              gic2
            ,mtl_categories_b                 mcb2
            ,gmi_item_categories              gic3
            ,mtl_categories_b                 mcb3
            ,gme_material_details             gmd
            ,gme_batch_header                 gbh
            ,gmd_routings_b                   grb
            ,xxcmn_rcv_pay_mst                xrpm
-- 2009/03/05 v1.31 ADD START
            ,ic_whse_mst                      iwm
-- 2009/03/05 v1.31 ADD END
      WHERE  itp.doc_type            = gv_doc_type_prod
      AND    itp.completed_ind       = 1
      AND    itp.trans_date > FND_DATE.STRING_TO_DATE(gd_prv1_dt_chr,gc_char_dt_format)
      AND    itp.trans_date < FND_DATE.STRING_TO_DATE(gd_flw_dt_chr,gc_char_dt_format)
      AND    itp.reverse_id          IS NULL
      AND    ilm.item_id             = itp.item_id
      AND    ilm.lot_id              = itp.lot_id
      AND    iimb.item_id            = ilm.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(itp.trans_date)
      AND    ximb.end_date_active   >= TRUNC(itp.trans_date)
      AND    gic1.item_id            = itp.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = itp.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    gic3.item_id            = itp.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
      AND    gmd.batch_id            = itp.doc_id
      AND    gmd.line_no             = itp.doc_line
      AND    gmd.line_type           = itp.line_type
      AND    gbh.batch_id            = gmd.batch_id
      AND    grb.routing_id          = gbh.routing_id
      AND    xrpm.routing_class      = grb.routing_class
      AND    xrpm.line_type          = gmd.line_type
      AND    (((gmd.attribute5 IS NULL) AND (xrpm.hit_in_div IS NULL))
             OR (xrpm.hit_in_div = gmd.attribute5))
      AND    itp.doc_type            = xrpm.doc_type
      AND    itp.line_type           = xrpm.line_type
      AND    xrpm.break_col_01       IS NOT NULL
      AND    xrpm.routing_class      <> '70'
      AND    mcb3.segment1           = lt_crowd_code
-- 2009/03/05 v1.31 ADD START
      AND    iwm.whse_code           = itp.whse_code
      AND    iwm.attribute1          = '0'
-- 2009/03/05 v1.31 ADD END
      UNION ALL
      SELECT /*+ leading (itp gic1 mcb1 gic2 mcb2 gmd gbh grb) use_nl (itp gic1 mcb1 gic2 mcb2 gmd gbh grb)*/
             NULL                                 h_whse_code
            ,NULL                                 h_whse_name
            ,itp.trans_id                         trans_id
            ,iimb.attribute15                     cost_mng_clss
            ,iimb.lot_ctl                         lot_ctl
            ,xlc.unit_ploce                       actual_unit_price
            ,CASE WHEN INSTR(xrpm.break_col_01,gv_hifn) = 0
                       THEN ''
                  WHEN xrpm.rcv_pay_div = gc_rcv_pay_div_in
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  ELSE SUBSTR(xrpm.break_col_01,INSTR(xrpm.break_col_01,gv_hifn) +1)
             END                                  column_no
            ,itp.reason_code                      reason_code
            ,itp.trans_date                       trans_date
            ,TO_CHAR(itp.trans_date, 'YYYYMM')  trans_ym
            ,CASE WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN TO_CHAR(ABS(TO_NUMBER(xrpm.rcv_pay_div)))
                  ELSE xrpm.rcv_pay_div
             END                                  rcv_pay_div
            ,xrpm.dealings_div                    dealings_div
            ,itp.doc_type                         doc_type
            ,ir_param.item_class                  item_div
            ,ir_param.goods_class                 prod_div
            ,mcb3.segment1                        crowd_code
            ,SUBSTR(mcb3.segment1, 1, 3)          crowd_low
            ,SUBSTR(mcb3.segment1, 1, 2)          crowd_mid
            ,SUBSTR(mcb3.segment1, 1, 1)          crowd_high
            ,itp.item_id                          item_id
            ,itp.lot_id                           lot_id
            ,NVL(itp.trans_qty, 0)                trans_qty
            ,itp.trans_date                       arrival_date
            ,TO_CHAR(itp.trans_date, gc_char_ym_format) arrival_ym
            ,iimb.item_no                         item_code
            ,ximb.item_short_name                 item_name
      FROM   ic_tran_pnd                      itp
            ,ic_item_mst_b                    iimb
            ,xxcmn_item_mst_b                 ximb
            ,ic_lots_mst                      ilm
            ,xxcmn_lot_cost                   xlc
            ,gmi_item_categories              gic1
            ,mtl_categories_b                 mcb1
            ,gmi_item_categories              gic2
            ,mtl_categories_b                 mcb2
            ,gmi_item_categories              gic3
            ,mtl_categories_b                 mcb3
            ,gme_material_details             gmd
            ,gme_batch_header                 gbh
            ,gmd_routings_b                   grb
            ,xxcmn_rcv_pay_mst                xrpm
-- 2009/03/05 v1.31 ADD START
            ,ic_whse_mst                      iwm
-- 2009/03/05 v1.31 ADD END
      WHERE  itp.doc_type            = gv_doc_type_prod
      AND    itp.completed_ind       = 1
      AND    itp.trans_date > FND_DATE.STRING_TO_DATE(gd_prv1_dt_chr,gc_char_dt_format)
      AND    itp.trans_date < FND_DATE.STRING_TO_DATE(gd_flw_dt_chr,gc_char_dt_format)
      AND    itp.reverse_id          IS NULL
      AND    ilm.item_id             = itp.item_id
      AND    ilm.lot_id              = itp.lot_id
      AND    iimb.item_id            = ilm.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(itp.trans_date)
      AND    ximb.end_date_active   >= TRUNC(itp.trans_date)
      AND    gic1.item_id            = itp.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = itp.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    mcb2.segment1           IN ('1','4')
      AND    gic3.item_id            = itp.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
      AND    gmd.batch_id            = itp.doc_id
      AND    gmd.line_no             = itp.doc_line
      AND    gmd.line_type           = itp.line_type
      AND    gbh.batch_id            = gmd.batch_id
      AND    grb.routing_id          = gbh.routing_id
      AND    xrpm.routing_class      = grb.routing_class
      AND    xrpm.line_type          = gmd.line_type
      AND    (((gmd.attribute5 IS NULL) AND (xrpm.hit_in_div IS NULL))
             OR (xrpm.hit_in_div = gmd.attribute5))
      AND    itp.doc_type            = xrpm.doc_type
      AND    itp.line_type           = xrpm.line_type
      AND    xrpm.break_col_01       IS NOT NULL
      AND    xrpm.routing_class      = '70'
      AND    (EXISTS (SELECT 1
                      FROM   gme_material_details gmd2
                            ,gmi_item_categories  gic
                            ,mtl_categories_b     mcb
                      WHERE  gmd2.batch_id   = gmd.batch_id
                      AND    gmd2.line_no    = gmd.line_no
                      AND    gmd2.line_type  = -1
                      AND    gic.item_id     = gmd2.item_id
                      AND    gic.category_set_id = cn_item_class_id
                      AND    gic.category_id = mcb.category_id
                      AND    mcb.segment1    = xrpm.item_div_origin))
      AND    (EXISTS (SELECT 1
                      FROM   gme_material_details gmd3
                            ,gmi_item_categories  gic
                            ,mtl_categories_b     mcb
                      WHERE  gmd3.batch_id   = gmd.batch_id
                      AND    gmd3.line_no    = gmd.line_no
                      AND    gmd3.line_type  = 1
                      AND    gic.item_id     = gmd3.item_id
                      AND    gic.category_set_id = cn_item_class_id
                      AND    gic.category_id = mcb.category_id
                      AND    mcb.segment1    = xrpm.item_div_ahead))
      AND    mcb3.segment1           = lt_crowd_code
-- 2009/03/05 v1.31 ADD START
      AND    iwm.whse_code           = itp.whse_code
      AND    iwm.attribute1          = '0'
-- 2009/03/05 v1.31 ADD END
      UNION ALL
      SELECT /*+ leading (xoha xola rsl itp gic1 mcb1 gic2 mcb2 ooha otta) use_nl (xoha xola rsl itp gic1 mcb1 gic2 mcb2 ooha otta) */
             NULL                                 h_whse_code
            ,NULL                                 h_whse_name
            ,itp.trans_id                         trans_id
            ,iimb.attribute15                     cost_mng_clss
            ,iimb.lot_ctl                         lot_ctl
            ,xlc.unit_ploce                       actual_unit_price
            ,CASE WHEN INSTR(xrpm.break_col_01,gv_hifn) = 0
                       THEN ''
                  WHEN xrpm.rcv_pay_div = gc_rcv_pay_div_in
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  ELSE SUBSTR(xrpm.break_col_01,INSTR(xrpm.break_col_01,gv_hifn) +1)
             END                                  column_no
            ,itp.reason_code                      reason_code
            ,itp.trans_date                       trans_date
            ,TO_CHAR(itp.trans_date, 'YYYYMM')  trans_ym
            ,CASE WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN TO_CHAR(ABS(TO_NUMBER(xrpm.rcv_pay_div)))
                  ELSE xrpm.rcv_pay_div
             END                                  rcv_pay_div
            ,xrpm.dealings_div                    dealings_div
            ,itp.doc_type                         doc_type
            ,ir_param.item_class                  item_div
            ,ir_param.goods_class                 prod_div
            ,mcb3.segment1                        crowd_code
            ,SUBSTR(mcb3.segment1, 1, 3)          crowd_low
            ,SUBSTR(mcb3.segment1, 1, 2)          crowd_mid
            ,SUBSTR(mcb3.segment1, 1, 1)          crowd_high
            ,itp.item_id                          item_id
            ,itp.lot_id                           lot_id
            ,NVL(itp.trans_qty, 0)                trans_qty
            ,xoha.arrival_date                    arrival_date
            ,TO_CHAR(xoha.arrival_date, gc_char_ym_format) arrival_ym
            ,iimb.item_no                         item_code
            ,ximb.item_short_name                 item_name
      FROM   ic_tran_pnd                      itp
            ,rcv_shipment_lines               rsl
            ,oe_order_headers_all             ooha
            ,oe_transaction_types_all         otta
            ,xxwsh_order_headers_all          xoha
            ,xxwsh_order_lines_all            xola
            ,ic_item_mst_b                    iimb
            ,xxcmn_item_mst_b                 ximb
            ,ic_lots_mst                      ilm
            ,xxcmn_lot_cost                   xlc
            ,gmi_item_categories              gic1
            ,mtl_categories_b                 mcb1
            ,gmi_item_categories              gic2
            ,mtl_categories_b                 mcb2
            ,gmi_item_categories              gic3
            ,mtl_categories_b                 mcb3
            ,xxcmn_rcv_pay_mst                xrpm
-- 2009/03/05 v1.31 ADD START
            ,ic_whse_mst                      iwm
-- 2009/03/05 v1.31 ADD END
      WHERE  itp.doc_type            = gv_doc_type_porc
      AND    itp.completed_ind       = 1
      AND    xoha.latest_external_flag = 'Y'
      AND    xoha.arrival_date > FND_DATE.STRING_TO_DATE(gd_prv1_dt_chr,gc_char_dt_format)
      AND    xoha.arrival_date < FND_DATE.STRING_TO_DATE(gd_flw_dt_chr,gc_char_dt_format)
      AND    xoha.req_status         IN ('04','08')
      AND    ilm.item_id             = itp.item_id
      AND    ilm.lot_id              = itp.lot_id
      AND    iimb.item_id            = itp.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(itp.trans_date)
      AND    ximb.end_date_active   >= TRUNC(itp.trans_date)
      AND    gic1.item_id            = itp.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = itp.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    gic3.item_id            = itp.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
      AND    rsl.shipment_header_id  = itp.doc_id
      AND    rsl.line_num            = itp.doc_line
      AND    rsl.oe_order_header_id  = xola.header_id
      AND    rsl.oe_order_line_id    = xola.line_id
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    ((otta.attribute4           <> '2')
             OR  (otta.attribute4       IS NULL))
      AND    otta.attribute1         IN ('1','2')
      AND    xoha.header_id          = ooha.header_id
      AND    xola.order_header_id    = xoha.order_header_id
      AND    xola.request_item_code  = xola.shipping_item_code
      AND    xrpm.doc_type           = itp.doc_type
      AND    xrpm.source_document_code = 'RMA'
      AND    xrpm.dealings_div       IN ('101','103')
      AND    xrpm.shipment_provision_div = DECODE(xoha.req_status,'04','1','08','2')
      AND    xrpm.shipment_provision_div = otta.attribute1
      AND    ((xrpm.ship_prov_rcv_pay_category IS NULL)
             OR (xrpm.ship_prov_rcv_pay_category = otta.attribute11))
      AND    xrpm.break_col_01       IS NOT NULL
      AND    xrpm.item_div_origin    IS NULL
      AND    xrpm.item_div_ahead     IS NULL
      AND    mcb3.segment1           = lt_crowd_code
-- 2009/03/05 v1.31 ADD START
      AND    iwm.whse_code           = itp.whse_code
      AND    iwm.attribute1          = '0'
-- 2009/03/05 v1.31 ADD END
      UNION ALL
      SELECT /*+ leading (xoha xola rsl itp gic1 mcb1 gic2 mcb2 ooha otta) use_nl (xoha xola rsl itp gic1 mcb1 gic2 mcb2 ooha otta) */
             NULL                                 h_whse_code
            ,NULL                                 h_whse_name
            ,itp.trans_id                         trans_id
            ,iimb.attribute15                     cost_mng_clss
            ,iimb.lot_ctl                         lot_ctl
            ,xlc.unit_ploce                       actual_unit_price
            ,CASE WHEN INSTR(xrpm.break_col_01,gv_hifn) = 0
                       THEN ''
                  WHEN xrpm.rcv_pay_div = gc_rcv_pay_div_in
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  ELSE SUBSTR(xrpm.break_col_01,INSTR(xrpm.break_col_01,gv_hifn) +1)
             END                                  column_no
            ,itp.reason_code                      reason_code
            ,itp.trans_date                       trans_date
            ,TO_CHAR(itp.trans_date, 'YYYYMM')  trans_ym
            ,CASE WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN TO_CHAR(ABS(TO_NUMBER(xrpm.rcv_pay_div)))
                  ELSE xrpm.rcv_pay_div
             END                                  rcv_pay_div
            ,xrpm.dealings_div                    dealings_div
            ,itp.doc_type                         doc_type
            ,ir_param.item_class                  item_div
            ,ir_param.goods_class                 prod_div
            ,mcb3.segment1                        crowd_code
            ,SUBSTR(mcb3.segment1, 1, 3)          crowd_low
            ,SUBSTR(mcb3.segment1, 1, 2)          crowd_mid
            ,SUBSTR(mcb3.segment1, 1, 1)          crowd_high
            ,iimb.item_id                         item_id
            ,itp.lot_id                           lot_id
            ,NVL(itp.trans_qty, 0)                trans_qty
            ,xoha.arrival_date                      arrival_date
            ,TO_CHAR(xoha.arrival_date, gc_char_ym_format) arrival_ym
            ,iimb.item_no                         item_code
            ,ximb.item_short_name                 item_name
      FROM   ic_tran_pnd                      itp
            ,rcv_shipment_lines               rsl
            ,oe_order_headers_all             ooha
            ,oe_transaction_types_all         otta
            ,xxwsh_order_headers_all          xoha
            ,xxwsh_order_lines_all            xola
            ,ic_item_mst_b                    iimb
            ,ic_item_mst_b                    iimb2
            ,xxcmn_item_mst_b                 ximb
            ,ic_lots_mst                      ilm
            ,xxcmn_lot_cost                   xlc
            ,gmi_item_categories              gic1
            ,mtl_categories_b                 mcb1
            ,gmi_item_categories              gic2
            ,mtl_categories_b                 mcb2
            ,gmi_item_categories              gic3
            ,mtl_categories_b                 mcb3
            ,gmi_item_categories              gic4
            ,mtl_categories_b                 mcb4
            ,xxcmn_rcv_pay_mst                xrpm
-- 2009/03/05 v1.31 ADD START
            ,ic_whse_mst                      iwm
-- 2009/03/05 v1.31 ADD END
      WHERE  itp.doc_type            = gv_doc_type_porc
      AND    itp.completed_ind       = 1
      AND    xoha.latest_external_flag = 'Y'
      AND    xoha.arrival_date > FND_DATE.STRING_TO_DATE(gd_prv1_dt_chr,gc_char_dt_format)
      AND    xoha.arrival_date < FND_DATE.STRING_TO_DATE(gd_flw_dt_chr,gc_char_dt_format)
      AND    xoha.req_status         IN ('04','08')
      AND    ilm.item_id             = itp.item_id
      AND    ilm.lot_id              = itp.lot_id
      AND    iimb.item_id            = itp.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    iimb2.item_no           = xola.request_item_code
      AND    ximb.start_date_active <= TRUNC(itp.trans_date)
      AND    ximb.end_date_active   >= TRUNC(itp.trans_date)
      AND    gic1.item_id            = itp.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = itp.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    gic3.item_id            = itp.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
      AND    gic4.item_id            = iimb2.item_id
      AND    gic4.category_set_id    = cn_item_class_id
      AND    gic4.category_id        = mcb4.category_id
      AND    rsl.shipment_header_id  = itp.doc_id
      AND    rsl.line_num            = itp.doc_line
      AND    rsl.oe_order_header_id  = xoha.header_id
      AND    rsl.oe_order_line_id    = xola.line_id
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    ((otta.attribute4           <> '2')
             OR  (otta.attribute4       IS NULL))
      AND    otta.attribute1         IN ('1','2')
      AND    xoha.header_id          = ooha.header_id
      AND    xola.order_header_id    = xoha.order_header_id
      AND    xrpm.doc_type           = itp.doc_type
      AND    xrpm.source_document_code = 'RMA'
      AND    xrpm.dealings_div       = '106'
      AND    xrpm.shipment_provision_div = DECODE(xoha.req_status,'04','1','08','2')
      AND    xrpm.shipment_provision_div = otta.attribute1
      AND    xrpm.ship_prov_rcv_pay_category = otta.attribute11
      AND    xrpm.item_div_ahead     = mcb4.segment1
      AND    mcb2.segment1           <> '5'
      AND    xrpm.break_col_01       IS NOT NULL
      AND    mcb3.segment1           = lt_crowd_code
-- 2009/03/05 v1.31 ADD START
      AND    iwm.whse_code           = itp.whse_code
      AND    iwm.attribute1          = '0'
-- 2009/03/05 v1.31 ADD END
      UNION ALL
      SELECT /*+ leading (xoha xola rsl itp gic1 mcb1 gic2 mcb2 ooha otta xrpm) use_nl (xoha xola rsl itp gic1 mcb1 gic2 mcb2 rsl ooha otta xrpm) */
             NULL                                 h_whse_code
            ,NULL                                 h_whse_name
            ,itp.trans_id                         trans_id
            ,iimb.attribute15                     cost_mng_clss
            ,iimb.lot_ctl                         lot_ctl
            ,xlc.unit_ploce                       actual_unit_price
            ,CASE WHEN INSTR(xrpm.break_col_01,gv_hifn) = 0
                       THEN ''
                  WHEN xrpm.rcv_pay_div = gc_rcv_pay_div_in
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  ELSE SUBSTR(xrpm.break_col_01,INSTR(xrpm.break_col_01,gv_hifn) +1)
             END                                  column_no
            ,itp.reason_code                      reason_code
            ,itp.trans_date                       trans_date
            ,TO_CHAR(itp.trans_date, 'YYYYMM')  trans_ym
            ,CASE WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN TO_CHAR(ABS(TO_NUMBER(xrpm.rcv_pay_div)))
                  ELSE xrpm.rcv_pay_div
             END                                  rcv_pay_div
            ,xrpm.dealings_div                    dealings_div
            ,itp.doc_type                         doc_type
            ,ir_param.item_class                  item_div
            ,ir_param.goods_class                 prod_div
            ,mcb3.segment1                        crowd_code
            ,SUBSTR(mcb3.segment1, 1, 3)          crowd_low
            ,SUBSTR(mcb3.segment1, 1, 2)          crowd_mid
            ,SUBSTR(mcb3.segment1, 1, 1)          crowd_high
            ,iimb.item_id                         item_id
            ,itp.lot_id                           lot_id
            ,NVL(itp.trans_qty, 0)                trans_qty
            ,xoha.arrival_date                    arrival_date
            ,TO_CHAR(xoha.arrival_date, gc_char_ym_format) arrival_ym
            ,iimb.item_no                         item_code
            ,ximb.item_short_name                 item_name
      FROM   ic_tran_pnd                      itp
            ,rcv_shipment_lines               rsl
            ,oe_order_headers_all             ooha
            ,oe_transaction_types_all         otta
            ,xxwsh_order_headers_all          xoha
            ,xxwsh_order_lines_all            xola
            ,ic_item_mst_b                    iimb
            ,ic_item_mst_b                    iimb2
            ,xxcmn_item_mst_b                 ximb
            ,ic_lots_mst                      ilm
            ,xxcmn_lot_cost                   xlc
            ,gmi_item_categories              gic1
            ,mtl_categories_b                 mcb1
            ,gmi_item_categories              gic2
            ,mtl_categories_b                 mcb2
            ,gmi_item_categories              gic3
            ,mtl_categories_b                 mcb3
            ,gmi_item_categories              gic4
            ,mtl_categories_b                 mcb4
            ,xxcmn_rcv_pay_mst                xrpm
-- 2009/03/05 v1.31 ADD START
            ,ic_whse_mst                      iwm
-- 2009/03/05 v1.31 ADD END
      WHERE  itp.doc_type            = gv_doc_type_porc
      AND    itp.completed_ind       = 1
      AND    xoha.latest_external_flag = 'Y'
      AND    xoha.arrival_date > FND_DATE.STRING_TO_DATE(gd_prv1_dt_chr,gc_char_dt_format)
      AND    xoha.arrival_date < FND_DATE.STRING_TO_DATE(gd_flw_dt_chr,gc_char_dt_format)
      AND    xoha.req_status         = '04'
      AND    ilm.item_id             = itp.item_id
      AND    ilm.lot_id              = itp.lot_id
      AND    iimb.item_id            = itp.item_id
      AND    iimb2.item_no           = xola.request_item_code
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(itp.trans_date)
      AND    ximb.end_date_active   >= TRUNC(itp.trans_date)
      AND    gic1.item_id            = itp.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = itp.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    gic3.item_id            = itp.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
      AND    gic4.item_id            = iimb2.item_id
      AND    gic4.category_set_id    = cn_item_class_id
      AND    gic4.category_id        = mcb4.category_id
      AND    rsl.shipment_header_id  = itp.doc_id
      AND    rsl.line_num            = itp.doc_line
      AND    rsl.oe_order_header_id  = xoha.header_id
      AND    rsl.oe_order_line_id    = xola.line_id
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    ((otta.attribute4           <> '2')
             OR  (otta.attribute4       IS NULL))
      AND    xoha.header_id          = ooha.header_id
      AND    xola.order_header_id    = xoha.order_header_id
      AND    xrpm.doc_type           = itp.doc_type
      AND    xrpm.source_document_code = 'RMA'
      AND    xrpm.dealings_div       = '113'
      AND    xrpm.shipment_provision_div = DECODE(xoha.req_status,'04','1','08','2')
      AND    xrpm.item_div_ahead     = mcb4.segment1
      AND    mcb2.segment1           <> '5'
      AND    xrpm.break_col_01       IS NOT NULL
      AND    mcb3.segment1           = lt_crowd_code
-- 2009/03/05 v1.31 ADD START
      AND    iwm.whse_code           = itp.whse_code
      AND    iwm.attribute1          = '0'
-- 2009/03/05 v1.31 ADD END
      UNION ALL
      SELECT /*+ leading (xoha ooha otta xola rsl itp gic1 mcb1 gic2 mcb2) use_nl (xoha ooha otta xola rsl itp gic1 mcb1 gic2 mcb2) */
             NULL                                 h_whse_code
            ,NULL                                 h_whse_name
            ,itp.trans_id                         trans_id
            ,iimb.attribute15                     cost_mng_clss
            ,iimb.lot_ctl                         lot_ctl
            ,xlc.unit_ploce                       actual_unit_price
            ,CASE WHEN INSTR(xrpm.break_col_01,gv_hifn) = 0
                       THEN ''
                  WHEN xrpm.rcv_pay_div = gc_rcv_pay_div_in
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  ELSE SUBSTR(xrpm.break_col_01,INSTR(xrpm.break_col_01,gv_hifn) +1)
             END                                  column_no
            ,itp.reason_code                      reason_code
            ,itp.trans_date                       trans_date
            ,TO_CHAR(itp.trans_date, 'YYYYMM')  trans_ym
            ,CASE WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN TO_CHAR(ABS(TO_NUMBER(xrpm.rcv_pay_div)))
                  ELSE xrpm.rcv_pay_div
             END                                  rcv_pay_div
            ,xrpm.dealings_div                    dealings_div
            ,itp.doc_type                         doc_type
            ,ir_param.item_class                  item_div
            ,ir_param.goods_class                 prod_div
            ,mcb3.segment1                        crowd_code
            ,SUBSTR(mcb3.segment1, 1, 3)          crowd_low
            ,SUBSTR(mcb3.segment1, 1, 2)          crowd_mid
            ,SUBSTR(mcb3.segment1, 1, 1)          crowd_high
            ,itp.item_id                          item_id
            ,itp.lot_id                           lot_id
            ,NVL(itp.trans_qty, 0)                trans_qty
            ,xoha.arrival_date                    arrival_date
            ,TO_CHAR(xoha.arrival_date, gc_char_ym_format) arrival_ym
            ,iimb.item_no                         item_code
            ,ximb.item_short_name                 item_name
      FROM   ic_tran_pnd                      itp
            ,rcv_shipment_lines               rsl
            ,oe_order_headers_all             ooha
            ,oe_transaction_types_all         otta
            ,xxwsh_order_headers_all          xoha
            ,xxwsh_order_lines_all            xola
            ,ic_item_mst_b                    iimb
            ,xxcmn_item_mst_b                 ximb
            ,ic_lots_mst                      ilm
            ,xxcmn_lot_cost                   xlc
            ,gmi_item_categories              gic1
            ,mtl_categories_b                 mcb1
            ,gmi_item_categories              gic2
            ,mtl_categories_b                 mcb2
            ,gmi_item_categories              gic3
            ,mtl_categories_b                 mcb3
            ,xxcmn_rcv_pay_mst                xrpm
-- 2009/03/05 v1.31 ADD START
            ,ic_whse_mst                      iwm
-- 2009/03/05 v1.31 ADD END
      WHERE  itp.doc_type            = gv_doc_type_porc
      AND    itp.completed_ind       = 1
      AND    xoha.latest_external_flag = 'Y'
      AND    xoha.arrival_date > FND_DATE.STRING_TO_DATE(gd_prv1_dt_chr,gc_char_dt_format)
      AND    xoha.arrival_date < FND_DATE.STRING_TO_DATE(gd_flw_dt_chr,gc_char_dt_format)
      AND    ilm.item_id             = itp.item_id
      AND    ilm.lot_id              = itp.lot_id
      AND    iimb.item_id            = itp.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(itp.trans_date)
      AND    ximb.end_date_active   >= TRUNC(itp.trans_date)
      AND    gic1.item_id            = itp.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = itp.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    gic3.item_id            = itp.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
      AND    rsl.shipment_header_id  = itp.doc_id
      AND    rsl.line_num            = itp.doc_line
      AND    rsl.oe_order_header_id  = xoha.header_id
      AND    rsl.oe_order_line_id    = xola.line_id
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    otta.attribute4         = '2'
      AND    xoha.header_id          = ooha.header_id
      AND    xola.order_header_id    = xoha.order_header_id
      AND    xrpm.doc_type           = itp.doc_type
      AND    xrpm.source_document_code = 'RMA'
      AND    xrpm.dealings_div       IN ('504','509')
      AND    xrpm.stock_adjustment_div = otta.attribute4
      AND    xrpm.ship_prov_rcv_pay_category = otta.attribute11
      AND    xrpm.break_col_01       IS NOT NULL
      AND    mcb3.segment1           = lt_crowd_code
-- 2009/03/05 v1.31 ADD START
      AND    iwm.whse_code           = itp.whse_code
      AND    iwm.attribute1          = '0'
-- 2009/03/05 v1.31 ADD END
      UNION ALL
      SELECT /*+ leading (itp gic1 mcb1 gic2 mcb2) use_nl (itp gic1 mcb1 gic2 mcb2) */
             NULL                                 h_whse_code
            ,NULL                                 h_whse_name
-- v1.33 Mod Start
--            ,itp.trans_id                         trans_id
            ,NULL                                 trans_id
-- v1.33 Mod End
            ,iimb.attribute15                     cost_mng_clss
            ,iimb.lot_ctl                         lot_ctl
            ,xlc.unit_ploce                       actual_unit_price
            ,CASE WHEN INSTR(xrpm.break_col_01,gv_hifn) = 0
                       THEN ''
                  WHEN xrpm.rcv_pay_div = gc_rcv_pay_div_in
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  ELSE SUBSTR(xrpm.break_col_01,INSTR(xrpm.break_col_01,gv_hifn) +1)
             END                                  column_no
            ,itp.reason_code                      reason_code
            ,itp.trans_date                       trans_date
            ,TO_CHAR(itp.trans_date, 'YYYYMM')  trans_ym
            ,CASE WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN TO_CHAR(ABS(TO_NUMBER(xrpm.rcv_pay_div)))
                  ELSE xrpm.rcv_pay_div
             END                                  rcv_pay_div
            ,xrpm.dealings_div                    dealings_div
            ,itp.doc_type                         doc_type
            ,ir_param.item_class                  item_div
            ,ir_param.goods_class                 prod_div
            ,mcb3.segment1                        crowd_code
            ,SUBSTR(mcb3.segment1, 1, 3)          crowd_low
            ,SUBSTR(mcb3.segment1, 1, 2)          crowd_mid
            ,SUBSTR(mcb3.segment1, 1, 1)          crowd_high
            ,itp.item_id                          item_id
            ,itp.lot_id                           lot_id
-- v1.33 Mod Start
--            ,NVL(itp.trans_qty, 0)                trans_qty
            ,SUM(NVL(itp.trans_qty, 0))           trans_qty
-- v1.33 Mod End
            ,itp.trans_date                       arrival_date
            ,TO_CHAR(itp.trans_date, gc_char_ym_format) arrival_ym
            ,iimb.item_no                         item_code
            ,ximb.item_short_name                 item_name
      FROM   ic_tran_pnd                      itp
            ,ic_item_mst_b                    iimb
            ,xxcmn_item_mst_b                 ximb
            ,ic_lots_mst                      ilm
            ,xxcmn_lot_cost                   xlc
            ,gmi_item_categories              gic1
            ,mtl_categories_b                 mcb1
            ,gmi_item_categories              gic2
            ,mtl_categories_b                 mcb2
            ,gmi_item_categories              gic3
            ,mtl_categories_b                 mcb3
            ,rcv_shipment_lines               rsl
            ,rcv_transactions                 rt
            ,xxcmn_rcv_pay_mst                xrpm
-- 2009/03/05 v1.31 ADD START
            ,ic_whse_mst                      iwm
-- 2009/03/05 v1.31 ADD END
      WHERE  itp.doc_type            = gv_doc_type_porc
      AND    itp.completed_ind       = 1
      AND    itp.trans_date > FND_DATE.STRING_TO_DATE(gd_prv1_dt_chr,gc_char_dt_format)
      AND    itp.trans_date < FND_DATE.STRING_TO_DATE(gd_flw_dt_chr,gc_char_dt_format)
      AND    ilm.item_id             = itp.item_id
      AND    ilm.lot_id              = itp.lot_id
      AND    iimb.item_id            = ilm.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(itp.trans_date)
      AND    ximb.end_date_active   >= TRUNC(itp.trans_date)
      AND    gic1.item_id            = itp.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = itp.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    gic3.item_id            = itp.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
      AND    rsl.shipment_header_id  = itp.doc_id
      AND    rsl.line_num            = itp.doc_line
      AND    rt.transaction_id       = itp.line_id
      AND    rt.shipment_line_id     = rsl.shipment_line_id
      AND    xrpm.doc_type           = itp.doc_type
      AND    xrpm.source_document_code = rsl.source_document_code
      AND    xrpm.transaction_type   = rt.transaction_type
      AND    xrpm.break_col_01       IS NOT NULL
      AND    mcb3.segment1           = lt_crowd_code
-- 2009/03/05 v1.31 ADD START
      AND    iwm.whse_code           = itp.whse_code
      AND    iwm.attribute1          = '0'
-- 2009/03/05 v1.31 ADD END
-- v1.33 Add Start
      GROUP BY
             iimb.attribute15                     -- cost_mng_clss
            ,iimb.lot_ctl                         -- lot_ctl
            ,xlc.unit_ploce                       -- actual_unit_price
            ,CASE WHEN INSTR(xrpm.break_col_01,gv_hifn) = 0
                       THEN ''
                  WHEN xrpm.rcv_pay_div = gc_rcv_pay_div_in
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  ELSE SUBSTR(xrpm.break_col_01,INSTR(xrpm.break_col_01,gv_hifn) +1)
             END                                  -- column_no
            ,itp.reason_code                      -- reason_code
            ,itp.trans_date                       -- trans_date
            ,TO_CHAR(itp.trans_date, 'YYYYMM')    -- trans_ym
            ,CASE WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN TO_CHAR(ABS(TO_NUMBER(xrpm.rcv_pay_div)))
                  ELSE xrpm.rcv_pay_div
             END                                  -- rcv_pay_div
            ,xrpm.dealings_div                    -- dealings_div
            ,itp.doc_type                         -- doc_type
            ,ir_param.item_class                  -- item_div
            ,ir_param.goods_class                 -- prod_div
            ,mcb3.segment1                        -- crowd_code
            ,SUBSTR(mcb3.segment1, 1, 3)          -- crowd_low
            ,SUBSTR(mcb3.segment1, 1, 2)          -- crowd_mid
            ,SUBSTR(mcb3.segment1, 1, 1)          -- crowd_high
            ,itp.item_id                          -- item_id
            ,itp.lot_id                           -- lot_id
            ,itp.trans_date                       -- arrival_date
            ,TO_CHAR(itp.trans_date, gc_char_ym_format) -- arrival_ym
            ,iimb.item_no                         -- item_code
            ,ximb.item_short_name                 -- item_name
            ,rsl.attribute1                       -- 受入返品実績アドオン.取引ID
-- v1.33 Add End
      UNION ALL
      SELECT /*+ leading (xoha xola wdd itp gic1 mcb1 gic2 mcb2 ooha otta) use_nl (xoha xola wdd itp gic1 mcb1 gic2 mcb2 ooha otta) */
             NULL                                 h_whse_code
            ,NULL                                 h_whse_name
            ,itp.trans_id                         trans_id
            ,iimb.attribute15                     cost_mng_clss
            ,iimb.lot_ctl                         lot_ctl
            ,xlc.unit_ploce                       actual_unit_price
            ,CASE WHEN INSTR(xrpm.break_col_01,gv_hifn) = 0
                       THEN ''
                  WHEN xrpm.rcv_pay_div = gc_rcv_pay_div_in
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  ELSE SUBSTR(xrpm.break_col_01,INSTR(xrpm.break_col_01,gv_hifn) +1)
             END                                  column_no
            ,itp.reason_code                      reason_code
            ,itp.trans_date                       trans_date
            ,TO_CHAR(itp.trans_date, 'YYYYMM')  trans_ym
            ,CASE WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN TO_CHAR(ABS(TO_NUMBER(xrpm.rcv_pay_div)))
                  ELSE xrpm.rcv_pay_div
             END                                  rcv_pay_div
            ,xrpm.dealings_div                    dealings_div
            ,itp.doc_type                         doc_type
            ,ir_param.item_class                  item_div
            ,ir_param.goods_class                 prod_div
            ,mcb3.segment1                        crowd_code
            ,SUBSTR(mcb3.segment1, 1, 3)          crowd_low
            ,SUBSTR(mcb3.segment1, 1, 2)          crowd_mid
            ,SUBSTR(mcb3.segment1, 1, 1)          crowd_high
            ,itp.item_id                          item_id
            ,itp.lot_id                           lot_id
            ,NVL(itp.trans_qty, 0)                trans_qty
            ,xoha.arrival_date                    arrival_date
            ,TO_CHAR(xoha.arrival_date, gc_char_ym_format) arrival_ym
            ,iimb.item_no                         item_code
            ,ximb.item_short_name                 item_name
      FROM   ic_tran_pnd                      itp
            ,wsh_delivery_details             wdd
            ,oe_order_headers_all             ooha
            ,oe_transaction_types_all         otta
            ,xxwsh_order_headers_all          xoha
            ,xxwsh_order_lines_all            xola
            ,ic_item_mst_b                    iimb
            ,xxcmn_item_mst_b                 ximb
            ,ic_lots_mst                      ilm
            ,xxcmn_lot_cost                   xlc
            ,gmi_item_categories              gic1
            ,mtl_categories_b                 mcb1
            ,gmi_item_categories              gic2
            ,mtl_categories_b                 mcb2
            ,gmi_item_categories              gic3
            ,mtl_categories_b                 mcb3
            ,xxcmn_rcv_pay_mst                xrpm
-- 2009/03/05 v1.31 ADD START
            ,ic_whse_mst                      iwm
-- 2009/03/05 v1.31 ADD END
      WHERE  itp.doc_type            = gv_doc_type_omso
      AND    itp.completed_ind       = 1
      AND    xoha.latest_external_flag = 'Y'
      AND    xoha.arrival_date > FND_DATE.STRING_TO_DATE(gd_prv2_dt_chr,gc_char_dt_format)
      AND    xoha.arrival_date < FND_DATE.STRING_TO_DATE(gd_flw_dt_chr,gc_char_dt_format)
      AND    xoha.req_status         IN ('04','08')
      AND    ilm.item_id             = itp.item_id
      AND    ilm.lot_id              = itp.lot_id
      AND    iimb.item_id            = ilm.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(itp.trans_date)
      AND    ximb.end_date_active   >= TRUNC(itp.trans_date)
      AND    gic1.item_id            = itp.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = itp.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    gic3.item_id            = itp.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
      AND    wdd.delivery_detail_id  = itp.line_detail_id
      AND    wdd.source_header_id    = xoha.header_id
      AND    wdd.source_line_id      = xola.line_id
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    ((otta.attribute4           <> '2')
             OR  (otta.attribute4       IS NULL))
      AND    otta.attribute1         IN ('1','2')
      AND    xoha.header_id          = ooha.header_id
      AND    xola.order_header_id    = xoha.order_header_id
      AND    xola.request_item_code  = xola.shipping_item_code
      AND    xrpm.doc_type           = itp.doc_type
      AND    xrpm.dealings_div       IN ('101','103')
      AND    xrpm.shipment_provision_div = DECODE(xoha.req_status,'04','1','08','2')
      AND    xrpm.shipment_provision_div = otta.attribute1
      AND    ((xrpm.ship_prov_rcv_pay_category IS NULL)
             OR (xrpm.ship_prov_rcv_pay_category = otta.attribute11))
      AND    xrpm.break_col_01       IS NOT NULL
      AND    xrpm.item_div_origin    IS NULL
      AND    xrpm.item_div_ahead     IS NULL
      AND    mcb3.segment1           = lt_crowd_code
-- 2009/03/05 v1.31 ADD START
      AND    iwm.whse_code           = itp.whse_code
      AND    iwm.attribute1          = '0'
-- 2009/03/05 v1.31 ADD END
      UNION ALL
      SELECT /*+ leading (xoha xola wdd itp gic1 mcb1 gic2 mcb2 ooha otta xrpm) use_nl (xoha xola wdd itp gic1 mcb1 gic2 mcb2 ooha otta xrpm) */
             NULL                                 h_whse_code
            ,NULL                                 h_whse_name
            ,itp.trans_id                         trans_id
            ,iimb.attribute15                     cost_mng_clss
            ,iimb.lot_ctl                         lot_ctl
            ,xlc.unit_ploce                       actual_unit_price
            ,CASE WHEN INSTR(xrpm.break_col_01,gv_hifn) = 0
                       THEN ''
                  WHEN xrpm.rcv_pay_div = gc_rcv_pay_div_in
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  ELSE SUBSTR(xrpm.break_col_01,INSTR(xrpm.break_col_01,gv_hifn) +1)
             END                                  column_no
            ,itp.reason_code                      reason_code
            ,itp.trans_date                       trans_date
            ,TO_CHAR(itp.trans_date, 'YYYYMM')  trans_ym
            ,CASE WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN TO_CHAR(ABS(TO_NUMBER(xrpm.rcv_pay_div)))
                  ELSE xrpm.rcv_pay_div
             END                                  rcv_pay_div
            ,xrpm.dealings_div                    dealings_div
            ,itp.doc_type                         doc_type
            ,ir_param.item_class                  item_div
            ,ir_param.goods_class                 prod_div
            ,mcb3.segment1                        crowd_code
            ,SUBSTR(mcb3.segment1, 1, 3)          crowd_low
            ,SUBSTR(mcb3.segment1, 1, 2)          crowd_mid
            ,SUBSTR(mcb3.segment1, 1, 1)          crowd_high
            ,iimb.item_id                         item_id
            ,itp.lot_id                           lot_id
            ,NVL(itp.trans_qty, 0)                trans_qty
            ,xoha.arrival_date                    arrival_date
            ,TO_CHAR(xoha.arrival_date, gc_char_ym_format) arrival_ym
            ,iimb.item_no                         item_code
            ,ximb.item_short_name                 item_name
      FROM   ic_tran_pnd                      itp
            ,wsh_delivery_details             wdd
            ,oe_order_headers_all             ooha
            ,oe_transaction_types_all         otta
            ,xxwsh_order_headers_all          xoha
            ,xxwsh_order_lines_all            xola
            ,ic_item_mst_b                    iimb
            ,ic_item_mst_b                    iimb2
            ,xxcmn_item_mst_b                 ximb
            ,ic_lots_mst                      ilm
            ,xxcmn_lot_cost                   xlc
            ,gmi_item_categories              gic1
            ,mtl_categories_b                 mcb1
            ,gmi_item_categories              gic2
            ,mtl_categories_b                 mcb2
            ,gmi_item_categories              gic3
            ,mtl_categories_b                 mcb3
            ,gmi_item_categories              gic4
            ,mtl_categories_b                 mcb4
            ,xxcmn_rcv_pay_mst                xrpm
-- 2009/03/05 v1.31 ADD START
            ,ic_whse_mst                      iwm
-- 2009/03/05 v1.31 ADD END
      WHERE  itp.doc_type            = gv_doc_type_omso
      AND    itp.completed_ind       = 1
      AND    xoha.latest_external_flag = 'Y'
      AND    xoha.arrival_date > FND_DATE.STRING_TO_DATE(gd_prv2_dt_chr,gc_char_dt_format)
      AND    xoha.arrival_date < FND_DATE.STRING_TO_DATE(gd_flw_dt_chr,gc_char_dt_format)
      AND    xoha.req_status         = '08'
      AND    ilm.item_id             = itp.item_id
      AND    ilm.lot_id              = itp.lot_id
      AND    iimb.item_id            = itp.item_id
      AND    iimb2.item_no           = xola.request_item_code
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(itp.trans_date)
      AND    ximb.end_date_active   >= TRUNC(itp.trans_date)
      AND    gic1.item_id            = itp.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = itp.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    gic3.item_id            = itp.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
      AND    gic4.item_id            = iimb2.item_id
      AND    gic4.category_set_id    = cn_item_class_id
      AND    gic4.category_id        = mcb4.category_id
      AND    wdd.delivery_detail_id  = itp.line_detail_id
      AND    wdd.source_header_id    = xoha.header_id
      AND    wdd.source_line_id      = xola.line_id
      AND    xola.order_header_id    = xoha.order_header_id
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    ((otta.attribute4           <> '2')
             OR  (otta.attribute4       IS NULL))
      AND    otta.attribute1         = '2'
      AND    xoha.header_id          = ooha.header_id
      AND    xrpm.doc_type           = itp.doc_type
      AND    xrpm.dealings_div       = '106'
      AND    xrpm.shipment_provision_div = DECODE(xoha.req_status,'04','1','08','2')
      AND    xrpm.shipment_provision_div = otta.attribute1
      AND    xrpm.ship_prov_rcv_pay_category = otta.attribute11
      AND    xrpm.item_div_ahead     = mcb4.segment1
      AND    mcb2.segment1           <> '5'
      AND    xrpm.break_col_01       IS NOT NULL
      AND    mcb3.segment1           = lt_crowd_code
-- 2009/03/05 v1.31 ADD START
      AND    iwm.whse_code           = itp.whse_code
      AND    iwm.attribute1          = '0'
-- 2009/03/05 v1.31 ADD END
      UNION ALL
      SELECT /*+ leading (xoha xola wdd itp gic1 mcb1 gic2 mcb2 ooha otta xrpm) use_nl (xoha xola wdd itp gic1 mcb1 gic2 mcb2 ooha otta xrpm) */
             NULL                                 h_whse_code
            ,NULL                                 h_whse_name
            ,itp.trans_id                         trans_id
            ,iimb.attribute15                     cost_mng_clss
            ,iimb.lot_ctl                         lot_ctl
            ,xlc.unit_ploce                       actual_unit_price
            ,CASE WHEN INSTR(xrpm.break_col_01,gv_hifn) = 0
                       THEN ''
                  WHEN xrpm.rcv_pay_div = gc_rcv_pay_div_in
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  ELSE SUBSTR(xrpm.break_col_01,INSTR(xrpm.break_col_01,gv_hifn) +1)
             END                                  column_no
            ,itp.reason_code                      reason_code
            ,itp.trans_date                       trans_date
            ,TO_CHAR(itp.trans_date, 'YYYYMM')  trans_ym
            ,CASE WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN TO_CHAR(ABS(TO_NUMBER(xrpm.rcv_pay_div)))
                  ELSE xrpm.rcv_pay_div
             END                                  rcv_pay_div
            ,xrpm.dealings_div                    dealings_div
            ,itp.doc_type                         doc_type
            ,ir_param.item_class                  item_div
            ,ir_param.goods_class                 prod_div
            ,mcb3.segment1                        crowd_code
            ,SUBSTR(mcb3.segment1, 1, 3)          crowd_low
            ,SUBSTR(mcb3.segment1, 1, 2)          crowd_mid
            ,SUBSTR(mcb3.segment1, 1, 1)          crowd_high
            ,iimb.item_id                         item_id
            ,itp.lot_id                           lot_id
            ,NVL(itp.trans_qty, 0)                trans_qty
            ,xoha.arrival_date                    arrival_date
            ,TO_CHAR(xoha.arrival_date, gc_char_ym_format) arrival_ym
            ,iimb.item_no                         item_code
            ,ximb.item_short_name                 item_name
      FROM   ic_tran_pnd                      itp
            ,wsh_delivery_details             wdd
            ,oe_order_headers_all             ooha
            ,oe_transaction_types_all         otta
            ,xxwsh_order_headers_all          xoha
            ,xxwsh_order_lines_all            xola
            ,ic_item_mst_b                    iimb
            ,ic_item_mst_b                    iimb2
            ,xxcmn_item_mst_b                 ximb
            ,ic_lots_mst                      ilm
            ,xxcmn_lot_cost                   xlc
            ,gmi_item_categories              gic1
            ,mtl_categories_b                 mcb1
            ,gmi_item_categories              gic2
            ,mtl_categories_b                 mcb2
            ,gmi_item_categories              gic3
            ,mtl_categories_b                 mcb3
            ,gmi_item_categories              gic4
            ,mtl_categories_b                 mcb4
            ,xxcmn_rcv_pay_mst                xrpm
-- 2009/03/05 v1.31 ADD START
            ,ic_whse_mst                      iwm
-- 2009/03/05 v1.31 ADD END
      WHERE  itp.doc_type            = gv_doc_type_omso
      AND    itp.completed_ind       = 1
      AND    xoha.latest_external_flag = 'Y'
      AND    xoha.arrival_date > FND_DATE.STRING_TO_DATE(gd_prv2_dt_chr,gc_char_dt_format)
      AND    xoha.arrival_date < FND_DATE.STRING_TO_DATE(gd_flw_dt_chr,gc_char_dt_format)
      AND    xoha.req_status         = '04'
      AND    ilm.item_id             = itp.item_id
      AND    ilm.lot_id              = itp.lot_id
      AND    iimb.item_id            = itp.item_id
      AND    iimb2.item_no           = xola.request_item_code
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(itp.trans_date)
      AND    ximb.end_date_active   >= TRUNC(itp.trans_date)
      AND    gic1.item_id            = itp.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = itp.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    gic3.item_id            = itp.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
      AND    gic4.item_id            = iimb2.item_id
      AND    gic4.category_set_id    = cn_item_class_id
      AND    gic4.category_id        = mcb4.category_id
      AND    wdd.delivery_detail_id  = itp.line_detail_id
      AND    wdd.source_header_id    = xoha.header_id
      AND    wdd.source_line_id      = xola.line_id
      AND    xola.order_header_id    = xoha.order_header_id
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    ((otta.attribute4           <> '2')
             OR  (otta.attribute4       IS NULL))
      AND    otta.attribute1         = '1'
      AND    xoha.header_id          = ooha.header_id
      AND    xrpm.doc_type           = itp.doc_type
      AND    xrpm.dealings_div       = '113'
      AND    xrpm.shipment_provision_div = DECODE(xoha.req_status,'04','1','08','2')
      AND    xrpm.item_div_ahead     = mcb4.segment1
      AND    mcb2.segment1           <> '5'
      AND    xrpm.break_col_01       IS NOT NULL
      AND    mcb3.segment1           = lt_crowd_code
-- 2009/03/05 v1.31 ADD START
      AND    iwm.whse_code           = itp.whse_code
      AND    iwm.attribute1          = '0'
-- 2009/03/05 v1.31 ADD END
      UNION ALL
      SELECT /*+ leading (xoha ooha otta xola wdd itp gic1 mcb1 gic2 mcb2) use_nl (xoha ooha otta xola wdd itp gic1 mcb1 gic2 mcb2) */
             NULL                                 h_whse_code
            ,NULL                                 h_whse_name
            ,itp.trans_id                         trans_id
            ,iimb.attribute15                     cost_mng_clss
            ,iimb.lot_ctl                         lot_ctl
            ,xlc.unit_ploce                       actual_unit_price
            ,CASE WHEN INSTR(xrpm.break_col_01,gv_hifn) = 0
                       THEN ''
                  WHEN xrpm.rcv_pay_div = gc_rcv_pay_div_in
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  ELSE SUBSTR(xrpm.break_col_01,INSTR(xrpm.break_col_01,gv_hifn) +1)
             END                                  column_no
            ,itp.reason_code                      reason_code
            ,itp.trans_date                       trans_date
            ,TO_CHAR(itp.trans_date, 'YYYYMM')  trans_ym
            ,CASE WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN TO_CHAR(ABS(TO_NUMBER(xrpm.rcv_pay_div)))
                  ELSE xrpm.rcv_pay_div
             END                                  rcv_pay_div
            ,xrpm.dealings_div                    dealings_div
            ,itp.doc_type                         doc_type
            ,ir_param.item_class                  item_div
            ,ir_param.goods_class                 prod_div
            ,mcb3.segment1                        crowd_code
            ,SUBSTR(mcb3.segment1, 1, 3)          crowd_low
            ,SUBSTR(mcb3.segment1, 1, 2)          crowd_mid
            ,SUBSTR(mcb3.segment1, 1, 1)          crowd_high
            ,itp.item_id                          item_id
            ,itp.lot_id                           lot_id
            ,NVL(itp.trans_qty, 0)                trans_qty
            ,xoha.arrival_date                    arrival_date
            ,TO_CHAR(xoha.arrival_date, gc_char_ym_format) arrival_ym
            ,iimb.item_no                         item_code
            ,ximb.item_short_name                 item_name
      FROM   ic_tran_pnd                      itp
            ,wsh_delivery_details             wdd
            ,oe_order_headers_all             ooha
            ,oe_transaction_types_all         otta
            ,xxwsh_order_headers_all          xoha
            ,xxwsh_order_lines_all            xola
            ,ic_item_mst_b                    iimb
            ,xxcmn_item_mst_b                 ximb
            ,ic_lots_mst                      ilm
            ,xxcmn_lot_cost                   xlc
            ,gmi_item_categories              gic1
            ,mtl_categories_b                 mcb1
            ,gmi_item_categories              gic2
            ,mtl_categories_b                 mcb2
            ,gmi_item_categories              gic3
            ,mtl_categories_b                 mcb3
            ,xxcmn_rcv_pay_mst                xrpm
-- 2009/03/05 v1.31 ADD START
            ,ic_whse_mst                      iwm
-- 2009/03/05 v1.31 ADD END
      WHERE  itp.doc_type            = gv_doc_type_omso
      AND    itp.completed_ind       = 1
      AND    xoha.latest_external_flag = 'Y'
      AND    xoha.arrival_date > FND_DATE.STRING_TO_DATE(gd_prv2_dt_chr,gc_char_dt_format)
      AND    xoha.arrival_date < FND_DATE.STRING_TO_DATE(gd_flw_dt_chr,gc_char_dt_format)
      AND    ilm.item_id             = itp.item_id
      AND    ilm.lot_id              = itp.lot_id
      AND    iimb.item_id            = itp.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(itp.trans_date)
      AND    ximb.end_date_active   >= TRUNC(itp.trans_date)
      AND    gic1.item_id            = itp.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = itp.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    gic3.item_id            = itp.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
      AND    wdd.delivery_detail_id  = itp.line_detail_id
      AND    wdd.source_header_id    = xoha.header_id
      AND    wdd.source_line_id      = xola.line_id
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    otta.attribute4         = '2'
      AND    xoha.header_id          = ooha.header_id
      AND    xola.order_header_id    = xoha.order_header_id
      AND    xrpm.doc_type           = itp.doc_type
      AND    xrpm.dealings_div       IN ('504','509')
      AND    xrpm.stock_adjustment_div = otta.attribute4
      AND    xrpm.ship_prov_rcv_pay_category = otta.attribute11
      AND    xrpm.break_col_01       IS NOT NULL
      AND    mcb3.segment1           = lt_crowd_code
-- 2009/03/05 v1.31 ADD START
      AND    iwm.whse_code           = itp.whse_code
      AND    iwm.attribute1          = '0'
-- 2009/03/05 v1.31 ADD END
      -- 当月受払無しデータ
      UNION ALL
      SELECT /*+ leading (xsims gic1 mcb1 gic2 mcb2 gic3 mcb3 iimb ximb xlc) use_nl (xsims gic1 mcb1 gic2 mcb2 gic3 mcb3 iimb ximb xlc) */
             NULL                                 h_whse_code
            ,NULL                                 h_whse_name
            ,NULL                                 trans_id
            ,iimb.attribute15                     cost_mng_clss
            ,iimb.lot_ctl                         lot_ctl
            ,xlc.unit_ploce                       actual_unit_price
            ,'1'                                  column_no
            ,NULL                                 reason_code
            ,gd_s_date                            trans_date
            ,TO_CHAR(gd_s_date, gc_char_ym_format)  trans_ym
            ,'1'                                  rcv_pay_div
            ,NULL                                 dealings_div
            ,NULL                                 doc_type
            ,ir_param.item_class                  item_div
            ,ir_param.goods_class                 prod_div
            ,mcb3.segment1                        crowd_code
            ,SUBSTR(mcb3.segment1, 1, 3)          crowd_low
            ,SUBSTR(mcb3.segment1, 1, 2)          crowd_mid
            ,SUBSTR(mcb3.segment1, 1, 1)          crowd_high
            ,iimb.item_id                         item_id
            ,0                                    lot_id
            ,0                                    trans_qty
            ,gd_s_date                            arrival_date
            ,TO_CHAR(gd_s_date, gc_char_ym_format)  arrival_ym
            ,iimb.item_no                         item_code
            ,ximb.item_short_name                 item_name
      FROM   xxinv_stc_inventory_month_stck   xsims
            ,ic_item_mst_b                    iimb
            ,xxcmn_item_mst_b                 ximb
            ,ic_lots_mst                      ilm
            ,xxcmn_lot_cost                   xlc
            ,gmi_item_categories              gic1
            ,mtl_categories_b                 mcb1
            ,gmi_item_categories              gic2
            ,mtl_categories_b                 mcb2
            ,gmi_item_categories              gic3
            ,mtl_categories_b                 mcb3
-- 2008/12/10 v1.25 ADD START
            ,ic_whse_mst                      iwm
-- 2008/12/10 v1.25 ADD END
      WHERE  xsims.item_id           = iimb.item_id
      AND    ximb.item_id            = iimb.item_id
      AND    ilm.item_id             = xsims.item_id
      AND    ilm.lot_id              = xsims.lot_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.start_date_active <= gd_s_date
      AND    ximb.end_date_active   >= gd_s_date
      AND    gic1.item_id            = xsims.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = xsims.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    gic3.item_id            = xsims.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
      AND    xsims.invent_ym         = TO_CHAR(gd_s_date, gc_char_ym_format)
      AND    mcb3.segment1           = lt_crowd_code
-- 2008/12/10 v1.25 UPDATE START
--      AND    xsims.monthly_stock    <> 0
      AND    (
               (xsims.monthly_stock <> 0)
               OR
               (xsims.cargo_stock   <> 0)
             )
      AND    iwm.whse_code           = xsims.whse_code
      AND    iwm.attribute1          = '0'
-- 2008/12/10 v1.25 UPDATE END
      ORDER BY crowd_code
              ,item_code
      ;
--
    --===============================================================
    -- 検索条件.帳票種別          ⇒ 品目別
    -- 検索条件.群種別            ⇒ 群別
    -- 検索条件.倉庫コード        ⇒ 入力なし
    -- 検索条件.群コード          ⇒ 入力なし
    -- 検索条件.経理群コード      ⇒ 入力なし/入力あり
    --===============================================================
    CURSOR get_data_cur06 IS
      SELECT /*+ leading (xmrh xmril ixm itp gic2 mcb2 gic1 mcb1 iimb ximb) use_nl (xmrh xmril ixm itp gic2 mcb2 gic1 mcb1 iimb ximb) */
             NULL                                 h_whse_code
            ,NULL                                 h_whse_name
            ,itp.trans_id                         trans_id
            ,iimb.attribute15                     cost_mng_clss
            ,iimb.lot_ctl                         lot_ctl
            ,xlc.unit_ploce                       actual_unit_price
            ,CASE WHEN INSTR(xrpm.break_col_01,gv_hifn) = 0
                       THEN ''
                  WHEN xrpm.rcv_pay_div = gc_rcv_pay_div_in
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  ELSE SUBSTR(xrpm.break_col_01,INSTR(xrpm.break_col_01,gv_hifn) +1)
             END                                  column_no
            ,itp.reason_code                      reason_code
            ,itp.trans_date                       trans_date
            ,TO_CHAR(itp.trans_date, 'YYYYMM')  trans_ym
            ,CASE WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN TO_CHAR(ABS(TO_NUMBER(xrpm.rcv_pay_div)))
                  ELSE xrpm.rcv_pay_div
             END                                  rcv_pay_div
            ,xrpm.dealings_div                    dealings_div
            ,itp.doc_type                         doc_type
            ,ir_param.item_class                  item_div
            ,ir_param.goods_class                 prod_div
            ,mcb3.segment1                        crowd_code
            ,SUBSTR(mcb3.segment1, 1, 3)          crowd_low
            ,SUBSTR(mcb3.segment1, 1, 2)          crowd_mid
            ,SUBSTR(mcb3.segment1, 1, 1)          crowd_high
            ,itp.item_id                          item_id
            ,itp.lot_id                           lot_id
            ,NVL(itp.trans_qty, 0)                trans_qty
            ,xmrh.actual_arrival_date             arrival_date
            ,TO_CHAR(xmrh.actual_arrival_date, gc_char_ym_format) arrival_ym
            ,iimb.item_no                         item_code
            ,ximb.item_short_name                 item_name
      FROM   ic_tran_pnd                      itp
            ,ic_xfer_mst                      ixm
            ,xxinv_mov_req_instr_headers      xmrh
            ,xxinv_mov_req_instr_lines        xmril
            ,ic_item_mst_b                    iimb
            ,xxcmn_item_mst_b                 ximb
            ,ic_lots_mst                      ilm
            ,xxcmn_lot_cost                   xlc
            ,gmi_item_categories              gic1
            ,mtl_categories_b                 mcb1
            ,gmi_item_categories              gic2
            ,mtl_categories_b                 mcb2
            ,gmi_item_categories              gic3
            ,mtl_categories_b                 mcb3
            ,xxcmn_rcv_pay_mst                xrpm
-- 2009/03/05 v1.31 ADD START
            ,ic_whse_mst                      iwm
-- 2009/03/05 v1.31 ADD END
      WHERE  itp.doc_type            = gv_doc_type_xfer
      AND    itp.reason_code         = gv_reason_code_xfer
      AND    itp.completed_ind       = 1
      AND    xmrh.actual_arrival_date > FND_DATE.STRING_TO_DATE(gd_prv1_dt_chr,gc_char_dt_format)
      AND    xmrh.actual_arrival_date < FND_DATE.STRING_TO_DATE(gd_flw_dt_chr,gc_char_dt_format)
      AND    xmrh.mov_hdr_id         = xmril.mov_hdr_id
      AND    itp.doc_id              = ixm.transfer_id
      AND    ixm.attribute1          = TO_CHAR(xmril.mov_line_id)
      AND    ilm.item_id             = itp.item_id
      AND    ilm.lot_id              = itp.lot_id
      AND    iimb.item_id            = itp.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(itp.trans_date)
      AND    ximb.end_date_active   >= TRUNC(itp.trans_date)
      AND    gic1.item_id            = itp.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = itp.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    gic3.item_id            = itp.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
      AND    xrpm.rcv_pay_div        = CASE
                                       WHEN itp.trans_qty >= 0 THEN 1
                                       ELSE -1
                                       END
      AND    xrpm.doc_type           = itp.doc_type
      AND    xrpm.reason_code        = itp.reason_code
      AND    xrpm.break_col_01       IS NOT NULL
-- 2009/03/05 v1.31 ADD START
      AND    iwm.whse_code           = itp.whse_code
      AND    iwm.attribute1          = '0'
-- 2009/03/05 v1.31 ADD END
      UNION ALL
      SELECT /*+ leading (xmrh xmril ijm iaj itc gic2 mcb2 gic1 mcb1 ilm iimb ximb) use_nl (xmrh xmril ijm iaj itc gic2 mcb2 gic1 mcb1 ilm iimb ximb) */
             NULL                                 h_whse_code
            ,NULL                                 h_whse_name
            ,itc.trans_id                         trans_id
            ,iimb.attribute15                     cost_mng_clss
            ,iimb.lot_ctl                         lot_ctl
            ,xlc.unit_ploce                       actual_unit_price
            ,CASE WHEN INSTR(xrpm.break_col_01,gv_hifn) = 0
                       THEN ''
                  WHEN xrpm.rcv_pay_div = gc_rcv_pay_div_in
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  ELSE SUBSTR(xrpm.break_col_01,INSTR(xrpm.break_col_01,gv_hifn) +1)
             END                                  column_no
            ,itc.reason_code                      reason_code
            ,itc.trans_date                       trans_date
            ,TO_CHAR(itc.trans_date, 'YYYYMM')  trans_ym
            ,CASE WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN TO_CHAR(ABS(TO_NUMBER(xrpm.rcv_pay_div)))
                  ELSE xrpm.rcv_pay_div
             END                                  rcv_pay_div
            ,xrpm.dealings_div                    dealings_div
            ,itc.doc_type                         doc_type
            ,ir_param.item_class                  item_div
            ,ir_param.goods_class                 prod_div
            ,mcb3.segment1                        crowd_code
            ,SUBSTR(mcb3.segment1, 1, 3)          crowd_low
            ,SUBSTR(mcb3.segment1, 1, 2)          crowd_mid
            ,SUBSTR(mcb3.segment1, 1, 1)          crowd_high
            ,itc.item_id                          item_id
            ,itc.lot_id                           lot_id
            ,NVL(itc.trans_qty, 0)                trans_qty
            ,xmrh.actual_arrival_date             arrival_date
            ,TO_CHAR(xmrh.actual_arrival_date, gc_char_ym_format) arrival_ym
            ,iimb.item_no                         item_code
            ,ximb.item_short_name                 item_name
      FROM   ic_tran_cmp                      itc
            ,ic_adjs_jnl                      iaj
            ,ic_jrnl_mst                      ijm
            ,xxinv_mov_req_instr_headers      xmrh
            ,xxinv_mov_req_instr_lines        xmril
            ,ic_item_mst_b                    iimb
            ,xxcmn_item_mst_b                 ximb
            ,ic_lots_mst                      ilm
            ,xxcmn_lot_cost                   xlc
            ,gmi_item_categories              gic1
            ,mtl_categories_b                 mcb1
            ,gmi_item_categories              gic2
            ,mtl_categories_b                 mcb2
            ,gmi_item_categories              gic3
            ,mtl_categories_b                 mcb3
            ,xxcmn_rcv_pay_mst                xrpm
-- 2009/03/05 v1.31 ADD START
            ,ic_whse_mst                      iwm
-- 2009/03/05 v1.31 ADD END
      WHERE  itc.doc_type            = gv_doc_type_trni
      AND    itc.reason_code         = gv_reason_code_trni
      AND    xmrh.actual_arrival_date > FND_DATE.STRING_TO_DATE(gd_prv1_dt_chr,gc_char_dt_format)
      AND    xmrh.actual_arrival_date < FND_DATE.STRING_TO_DATE(gd_flw_dt_chr,gc_char_dt_format)
      AND    xmrh.mov_hdr_id         = xmril.mov_hdr_id
      AND    itc.doc_type            = iaj.trans_type
      AND    itc.doc_id              = iaj.doc_id
      AND    itc.doc_line            = iaj.doc_line
      AND    ijm.journal_id          = iaj.journal_id
      AND    ijm.attribute1          = TO_CHAR(xmril.mov_line_id)
      AND    ilm.item_id             = itc.item_id
      AND    ilm.lot_id              = itc.lot_id
      AND    iimb.item_id            = ilm.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(itc.trans_date)
      AND    ximb.end_date_active   >= TRUNC(itc.trans_date)
      AND    gic1.item_id            = itc.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = itc.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    gic3.item_id            = itc.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
-- 2008/11/19 v1.18 ADD START
      AND    xrpm.rcv_pay_div        = CASE
                                       WHEN itc.trans_qty >= 0 THEN 1
                                       ELSE -1
                                       END
-- 2008/11/19 v1.18 ADD END
      AND    xrpm.doc_type           = itc.doc_type
      AND    xrpm.reason_code        = itc.reason_code
      AND    xrpm.rcv_pay_div        = itc.line_type
      AND    xrpm.break_col_01       IS NOT NULL
-- 2009/03/05 v1.31 ADD START
      AND    iwm.whse_code           = itc.whse_code
      AND    iwm.attribute1          = '0'
-- 2009/03/05 v1.31 ADD END
      UNION ALL
      SELECT /*+ leading (itc gic1 mcb1 gic2 mcb2) use_nl (itc gic1 mcb1 gic2 mcb2)*/
             NULL                                 h_whse_code
            ,NULL                                 h_whse_name
            ,itc.trans_id                         trans_id
            ,iimb.attribute15                     cost_mng_clss
            ,iimb.lot_ctl                         lot_ctl
            ,xlc.unit_ploce                       actual_unit_price
            ,CASE WHEN INSTR(xrpm.break_col_01,gv_hifn) = 0
                       THEN ''
                  WHEN xrpm.rcv_pay_div = gc_rcv_pay_div_in
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  ELSE SUBSTR(xrpm.break_col_01,INSTR(xrpm.break_col_01,gv_hifn) +1)
             END                                  column_no
            ,itc.reason_code                      reason_code
            ,itc.trans_date                       trans_date
            ,TO_CHAR(itc.trans_date, 'YYYYMM')  trans_ym
            ,CASE WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN TO_CHAR(ABS(TO_NUMBER(xrpm.rcv_pay_div)))
                  ELSE xrpm.rcv_pay_div
             END                                  rcv_pay_div
            ,xrpm.dealings_div                    dealings_div
            ,itc.doc_type                         doc_type
            ,ir_param.item_class                  item_div
            ,ir_param.goods_class                 prod_div
            ,mcb3.segment1                        crowd_code
            ,SUBSTR(mcb3.segment1, 1, 3)          crowd_low
            ,SUBSTR(mcb3.segment1, 1, 2)          crowd_mid
            ,SUBSTR(mcb3.segment1, 1, 1)          crowd_high
            ,itc.item_id                          item_id
            ,itc.lot_id                           lot_id
            ,NVL(itc.trans_qty, 0)                trans_qty
            ,itc.trans_date                       arrival_date
            ,TO_CHAR(itc.trans_date, gc_char_ym_format) arrival_ym
            ,iimb.item_no                         item_code
            ,ximb.item_short_name                 item_name
      FROM   ic_tran_cmp                      itc
            ,ic_item_mst_b                    iimb
            ,xxcmn_item_mst_b                 ximb
            ,ic_lots_mst                      ilm
            ,xxcmn_lot_cost                   xlc
            ,gmi_item_categories              gic1
            ,mtl_categories_b                 mcb1
            ,gmi_item_categories              gic2
            ,mtl_categories_b                 mcb2
            ,gmi_item_categories              gic3
            ,mtl_categories_b                 mcb3
            ,xxcmn_rcv_pay_mst                xrpm
-- 2009/03/05 v1.31 ADD START
            ,ic_whse_mst                      iwm
-- 2009/03/05 v1.31 ADD END
      WHERE  itc.doc_type            = gv_doc_type_adji    --文書タイプ
      AND    itc.reason_code        IN ('X911'
                                       ,'X912'
                                       ,'X921'
                                       ,'X922'
                                       ,'X931'
                                       ,'X932'
                                       ,'X941'
                                       ,'X952'
                                       ,'X953'
                                       ,'X954'
                                       ,'X955'
                                       ,'X956'
                                       ,'X957'
                                       ,'X958'
                                       ,'X959'
                                       ,'X960'
                                       ,'X961'
                                       ,'X962'
                                       ,'X963'
-- 2008/11/19 v1.18 UPDATE START
--                                       ,'X964')
                                       ,'X964'
                                       ,'X965'
                                       ,'X966')
-- 2008/11/19 v1.18 UPDATE END
      AND    itc.trans_date > FND_DATE.STRING_TO_DATE(gd_prv1_dt_chr,gc_char_dt_format)
      AND    itc.trans_date < FND_DATE.STRING_TO_DATE(gd_flw_dt_chr,gc_char_dt_format)
      AND    ilm.item_id             = itc.item_id
      AND    ilm.lot_id              = itc.lot_id
      AND    iimb.item_id            = ilm.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(itc.trans_date)
      AND    ximb.end_date_active   >= TRUNC(itc.trans_date)
      AND    gic1.item_id            = itc.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = itc.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    gic3.item_id            = itc.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
      AND    xrpm.doc_type           = itc.doc_type
      AND    xrpm.reason_code        = itc.reason_code
      AND    xrpm.break_col_01       IS NOT NULL
-- 2009/03/05 v1.31 ADD START
      AND    iwm.whse_code           = itc.whse_code
      AND    iwm.attribute1          = '0'
-- 2009/03/05 v1.31 ADD END
      UNION ALL
      SELECT /*+ leading (itc gic1 mcb1 gic2 mcb2 xrpm) use_nl (itc gic1 mcb1 gic2 mcb2 xrpm) */
             NULL                                 h_whse_code
            ,NULL                                 h_whse_name
-- v1.33 Mod Start
--            ,itc.trans_id                         trans_id
            ,NULL                                 trans_id
-- v1.33 Mod End
            ,iimb.attribute15                     cost_mng_clss
            ,iimb.lot_ctl                         lot_ctl
            ,xlc.unit_ploce                       actual_unit_price
            ,CASE WHEN INSTR(xrpm.break_col_01,gv_hifn) = 0
                       THEN ''
                  WHEN xrpm.rcv_pay_div = gc_rcv_pay_div_in
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  ELSE SUBSTR(xrpm.break_col_01,INSTR(xrpm.break_col_01,gv_hifn) +1)
             END                                  column_no
            ,itc.reason_code                      reason_code
            ,itc.trans_date                       trans_date
            ,TO_CHAR(itc.trans_date, 'YYYYMM')  trans_ym
            ,CASE WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN TO_CHAR(ABS(TO_NUMBER(xrpm.rcv_pay_div)))
                  ELSE xrpm.rcv_pay_div
             END                                  rcv_pay_div
            ,xrpm.dealings_div                    dealings_div
            ,itc.doc_type                         doc_type
            ,ir_param.item_class                  item_div
            ,ir_param.goods_class                 prod_div
            ,mcb3.segment1                        crowd_code
            ,SUBSTR(mcb3.segment1, 1, 3)          crowd_low
            ,SUBSTR(mcb3.segment1, 1, 2)          crowd_mid
            ,SUBSTR(mcb3.segment1, 1, 1)          crowd_high
            ,itc.item_id                          item_id
            ,itc.lot_id                           lot_id
-- v1.33 Mod Start
--            ,NVL(itc.trans_qty, 0)                trans_qty
            ,SUM(NVL(itc.trans_qty, 0))           trans_qty
-- v1.33 Mod End
            ,itc.trans_date                       arrival_date
            ,TO_CHAR(itc.trans_date, gc_char_ym_format) arrival_ym
            ,iimb.item_no                         item_code
            ,ximb.item_short_name                 item_name
      FROM   ic_tran_cmp                      itc
-- v1.33 Add Start
            ,ic_adjs_jnl                      iaj
            ,ic_jrnl_mst                      ijm
-- v1.33 Add End
            ,ic_item_mst_b                    iimb
            ,xxcmn_item_mst_b                 ximb
            ,ic_lots_mst                      ilm
            ,xxcmn_lot_cost                   xlc
            ,gmi_item_categories              gic1
            ,mtl_categories_b                 mcb1
            ,gmi_item_categories              gic2
            ,mtl_categories_b                 mcb2
            ,gmi_item_categories              gic3
            ,mtl_categories_b                 mcb3
            ,xxcmn_rcv_pay_mst                xrpm
-- 2009/03/05 v1.31 ADD START
            ,ic_whse_mst                      iwm
-- 2009/03/05 v1.31 ADD END
      WHERE  itc.doc_type            = gv_doc_type_adji
      AND    itc.reason_code         = gv_reason_code_adji_po
      AND    itc.trans_date > FND_DATE.STRING_TO_DATE(gd_prv1_dt_chr,gc_char_dt_format)
      AND    itc.trans_date < FND_DATE.STRING_TO_DATE(gd_flw_dt_chr,gc_char_dt_format)
-- v1.33 Add Start
      AND    iaj.trans_type          = itc.doc_type
      AND    iaj.doc_id              = itc.doc_id
      AND    iaj.doc_line            = itc.doc_line
      AND    ijm.journal_id          = iaj.journal_id
-- v1.33 Add End
      AND    ilm.item_id             = itc.item_id
      AND    ilm.lot_id              = itc.lot_id
      AND    iimb.item_id            = ilm.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(itc.trans_date)
      AND    ximb.end_date_active   >= TRUNC(itc.trans_date)
      AND    gic1.item_id            = itc.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = itc.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    gic3.item_id            = itc.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
      AND    xrpm.doc_type           = itc.doc_type
      AND    xrpm.reason_code        = itc.reason_code
      AND    xrpm.break_col_01       IS NOT NULL
-- 2009/03/05 v1.31 ADD START
      AND    iwm.whse_code           = itc.whse_code
      AND    iwm.attribute1          = '0'
-- 2009/03/05 v1.31 ADD END
-- v1.33 Add Start
      GROUP BY
             iimb.attribute15                     -- cost_mng_clss
            ,iimb.lot_ctl                         -- lot_ctl
            ,xlc.unit_ploce                       -- actual_unit_price
            ,CASE WHEN INSTR(xrpm.break_col_01,gv_hifn) = 0
                       THEN ''
                  WHEN xrpm.rcv_pay_div = gc_rcv_pay_div_in
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  ELSE SUBSTR(xrpm.break_col_01,INSTR(xrpm.break_col_01,gv_hifn) +1)
             END                                  -- column_no
            ,itc.reason_code                      -- reason_code
            ,itc.trans_date                       -- trans_date
            ,TO_CHAR(itc.trans_date, 'YYYYMM')    -- trans_ym
            ,CASE WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN TO_CHAR(ABS(TO_NUMBER(xrpm.rcv_pay_div)))
                  ELSE xrpm.rcv_pay_div
             END                                  -- rcv_pay_div
            ,xrpm.dealings_div                    -- dealings_div
            ,itc.doc_type                         -- doc_type
            ,ir_param.item_class                  -- item_div
            ,ir_param.goods_class                 -- prod_div
            ,mcb3.segment1                        -- crowd_code
            ,SUBSTR(mcb3.segment1, 1, 3)          -- crowd_low
            ,SUBSTR(mcb3.segment1, 1, 2)          -- crowd_mid
            ,SUBSTR(mcb3.segment1, 1, 1)          -- crowd_high
            ,itc.item_id                          -- item_id
            ,itc.lot_id                           -- lot_id
            ,itc.trans_date                       -- arrival_date
            ,TO_CHAR(itc.trans_date, gc_char_ym_format) -- arrival_ym
            ,iimb.item_no                         -- item_code
            ,ximb.item_short_name                 -- item_name
            ,ijm.attribute1                       -- 受入返品実績アドオン.取引ID
-- v1.33 Add End
      UNION ALL
      SELECT /*+ leading (itc gic1 mcb1 gic2 mcb2 xrpm) use_nl (itc gic1 mcb1 gic2 mcb2 xrpm) */
             NULL                                 h_whse_code
            ,NULL                                 h_whse_name
            ,itc.trans_id                         trans_id
            ,iimb.attribute15                     cost_mng_clss
            ,iimb.lot_ctl                         lot_ctl
            ,xlc.unit_ploce                       actual_unit_price
            ,CASE WHEN INSTR(xrpm.break_col_01,gv_hifn) = 0
                       THEN ''
                  WHEN xrpm.rcv_pay_div = gc_rcv_pay_div_in
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  ELSE SUBSTR(xrpm.break_col_01,INSTR(xrpm.break_col_01,gv_hifn) +1)
             END                                  column_no
            ,itc.reason_code                      reason_code
            ,itc.trans_date                       trans_date
            ,TO_CHAR(itc.trans_date, 'YYYYMM')  trans_ym
            ,CASE WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN TO_CHAR(ABS(TO_NUMBER(xrpm.rcv_pay_div)))
                  ELSE xrpm.rcv_pay_div
             END                                  rcv_pay_div
            ,xrpm.dealings_div                    dealings_div
            ,itc.doc_type                         doc_type
            ,ir_param.item_class                  item_div
            ,ir_param.goods_class                 prod_div
            ,mcb3.segment1                        crowd_code
            ,SUBSTR(mcb3.segment1, 1, 3)          crowd_low
            ,SUBSTR(mcb3.segment1, 1, 2)          crowd_mid
            ,SUBSTR(mcb3.segment1, 1, 1)          crowd_high
            ,itc.item_id                          item_id
            ,itc.lot_id                           lot_id
            ,NVL(itc.trans_qty, 0)                trans_qty
            ,itc.trans_date                       arrival_date
            ,TO_CHAR(itc.trans_date, gc_char_ym_format) arrival_ym
            ,iimb.item_no                         item_code
            ,ximb.item_short_name                 item_name
      FROM   ic_tran_cmp                      itc
            ,ic_item_mst_b                    iimb
            ,xxcmn_item_mst_b                 ximb
            ,ic_lots_mst                      ilm
            ,xxcmn_lot_cost                   xlc
            ,gmi_item_categories              gic1
            ,mtl_categories_b                 mcb1
            ,gmi_item_categories              gic2
            ,mtl_categories_b                 mcb2
            ,gmi_item_categories              gic3
            ,mtl_categories_b                 mcb3
            ,xxcmn_rcv_pay_mst                xrpm
-- 2009/03/05 v1.31 ADD START
            ,ic_whse_mst                      iwm
-- 2009/03/05 v1.31 ADD END
      WHERE  itc.doc_type            = gv_doc_type_adji
      AND    itc.reason_code         = gv_reason_code_adji_hama
      AND    itc.trans_date > FND_DATE.STRING_TO_DATE(gd_prv1_dt_chr,gc_char_dt_format)
      AND    itc.trans_date < FND_DATE.STRING_TO_DATE(gd_flw_dt_chr,gc_char_dt_format)
      AND    ilm.item_id             = itc.item_id
      AND    ilm.lot_id              = itc.lot_id
      AND    iimb.item_id            = ilm.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(itc.trans_date)
      AND    ximb.end_date_active   >= TRUNC(itc.trans_date)
      AND    gic1.item_id            = itc.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = itc.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    gic3.item_id            = itc.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
      AND    xrpm.doc_type           = itc.doc_type
      AND    xrpm.reason_code        = itc.reason_code
      AND    xrpm.break_col_01       IS NOT NULL
-- 2009/03/05 v1.31 ADD START
      AND    iwm.whse_code           = itc.whse_code
      AND    iwm.attribute1          = '0'
-- 2009/03/05 v1.31 ADD END
      UNION ALL
      SELECT /*+ leading (xmrh xmrl ijm iaj itc gic1 mcb1 gic2 mcb2) use_nl (xmrh xmrl ijm iaj itc gic1 mcb1 gic2 mcb2) */
             NULL                                 h_whse_code
            ,NULL                                 h_whse_name
            ,itc.trans_id                         trans_id
            ,iimb.attribute15                     cost_mng_clss
            ,iimb.lot_ctl                         lot_ctl
            ,xlc.unit_ploce                       actual_unit_price
            ,CASE WHEN INSTR(xrpm.break_col_01,gv_hifn) = 0
                       THEN ''
                  WHEN xrpm.rcv_pay_div = gc_rcv_pay_div_in
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  ELSE SUBSTR(xrpm.break_col_01,INSTR(xrpm.break_col_01,gv_hifn) +1)
             END                                  column_no
            ,itc.reason_code                      reason_code
            ,itc.trans_date                       trans_date
            ,TO_CHAR(itc.trans_date, 'YYYYMM')  trans_ym
-- 2008/12/11 v1.26 N.Yoshida mod start
--            ,gc_rcv_pay_div_adj                   rcv_pay_div
            ,xrpm.rcv_pay_div                     rcv_pay_div
-- 2008/12/11 v1.26 N.Yoshida mod end
            ,xrpm.dealings_div                    dealings_div
            ,itc.doc_type                         doc_type
            ,ir_param.item_class                  item_div
            ,ir_param.goods_class                 prod_div
            ,mcb3.segment1                        crowd_code
            ,SUBSTR(mcb3.segment1, 1, 3)          crowd_low
            ,SUBSTR(mcb3.segment1, 1, 2)          crowd_mid
            ,SUBSTR(mcb3.segment1, 1, 1)          crowd_high
            ,itc.item_id                          item_id
            ,itc.lot_id                           lot_id
-- 2008/12/11 v1.26 N.Yoshida mod start
--            ,ABS(NVL(itc.trans_qty, 0))           trans_qty
            ,NVL(itc.trans_qty, 0)                trans_qty
-- 2008/12/11 v1.26 N.Yoshida mod end
            ,xmrh.actual_arrival_date             arrival_date
            ,TO_CHAR(xmrh.actual_arrival_date, gc_char_ym_format) arrival_ym
            ,iimb.item_no                         item_code
            ,ximb.item_short_name                 item_name
      FROM   ic_tran_cmp                      itc
            ,ic_adjs_jnl                      iaj
            ,ic_jrnl_mst                      ijm
            ,xxinv_mov_req_instr_headers      xmrh
            ,xxinv_mov_req_instr_lines        xmrl
            ,ic_item_mst_b                    iimb
            ,xxcmn_item_mst_b                 ximb
            ,ic_lots_mst                      ilm
            ,xxcmn_lot_cost                   xlc
            ,gmi_item_categories              gic1
            ,mtl_categories_b                 mcb1
            ,gmi_item_categories              gic2
            ,mtl_categories_b                 mcb2
            ,gmi_item_categories              gic3
            ,mtl_categories_b                 mcb3
            ,xxcmn_rcv_pay_mst                xrpm
-- 2009/03/05 v1.31 ADD START
            ,ic_whse_mst                      iwm
-- 2009/03/05 v1.31 ADD END
      WHERE  itc.doc_type            = gv_doc_type_adji
      AND    itc.reason_code         = gv_reason_code_adji_move
      AND    xmrh.actual_arrival_date > FND_DATE.STRING_TO_DATE(gd_prv1_dt_chr,gc_char_dt_format)
      AND    xmrh.actual_arrival_date < FND_DATE.STRING_TO_DATE(gd_flw_dt_chr,gc_char_dt_format)
      AND    iaj.trans_type          = itc.doc_type
      AND    iaj.doc_id              = itc.doc_id
      AND    iaj.doc_line            = itc.doc_line
      AND    ijm.journal_id          = iaj.journal_id
      AND    ijm.attribute1          = TO_CHAR(xmrl.mov_line_id)
      AND    xmrh.mov_hdr_id         = xmrl.mov_hdr_id
      AND    ilm.item_id             = itc.item_id
      AND    ilm.lot_id              = itc.lot_id
      AND    iimb.item_id            = ilm.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(itc.trans_date)
      AND    ximb.end_date_active   >= TRUNC(itc.trans_date)
      AND    gic1.item_id            = itc.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = itc.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    gic3.item_id            = itc.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
-- 2008/12/11 v1.26 N.Yoshida mod start
      AND    xrpm.rcv_pay_div        = CASE
--                                       WHEN itc.trans_qty >= 0 THEN 1
--                                       ELSE -1
                                       WHEN itc.trans_qty >= 0 THEN -1
                                       ELSE 1
                                       END
-- 2008/12/11 v1.26 N.Yoshida mod end
      AND    xrpm.doc_type           = itc.doc_type
      AND    xrpm.reason_code        = itc.reason_code
      AND    xrpm.break_col_01       IS NOT NULL
-- 2009/03/05 v1.31 ADD START
      AND    iwm.whse_code           = itc.whse_code
      AND    iwm.attribute1          = '0'
-- 2009/03/05 v1.31 ADD END
      UNION ALL
      SELECT /*+ leading (itc gic1 mcb1 gic2 mcb2) use_nl (itc gic1 mcb1 gic2 mcb2) */
             NULL                                 h_whse_code
            ,NULL                                 h_whse_name
            ,itc.trans_id                         trans_id
            ,iimb.attribute15                     cost_mng_clss
            ,iimb.lot_ctl                         lot_ctl
            ,xlc.unit_ploce                       actual_unit_price
            ,CASE WHEN INSTR(xrpm.break_col_01,gv_hifn) = 0
                       THEN ''
                  WHEN xrpm.rcv_pay_div = gc_rcv_pay_div_in
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  ELSE SUBSTR(xrpm.break_col_01,INSTR(xrpm.break_col_01,gv_hifn) +1)
             END                                  column_no
            ,itc.reason_code                      reason_code
            ,itc.trans_date                       trans_date
            ,TO_CHAR(itc.trans_date, 'YYYYMM')  trans_ym
            ,CASE WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN TO_CHAR(ABS(TO_NUMBER(xrpm.rcv_pay_div)))
                  ELSE xrpm.rcv_pay_div
             END                                  rcv_pay_div
            ,xrpm.dealings_div                    dealings_div
            ,itc.doc_type                         doc_type
            ,ir_param.item_class                  item_div
            ,ir_param.goods_class                 prod_div
            ,mcb3.segment1                        crowd_code
            ,SUBSTR(mcb3.segment1, 1, 3)          crowd_low
            ,SUBSTR(mcb3.segment1, 1, 2)          crowd_mid
            ,SUBSTR(mcb3.segment1, 1, 1)          crowd_high
            ,itc.item_id                          item_id
            ,itc.lot_id                           lot_id
            ,NVL(itc.trans_qty, 0)                trans_qty
            ,itc.trans_date                       arrival_date
            ,TO_CHAR(itc.trans_date, gc_char_ym_format) arrival_ym
            ,iimb.item_no                         item_code
            ,ximb.item_short_name                 item_name
      FROM   ic_tran_cmp                      itc
            ,ic_item_mst_b                    iimb
            ,xxcmn_item_mst_b                 ximb
            ,ic_lots_mst                      ilm
            ,xxcmn_lot_cost                   xlc
            ,gmi_item_categories              gic1
            ,mtl_categories_b                 mcb1
            ,gmi_item_categories              gic2
            ,mtl_categories_b                 mcb2
            ,gmi_item_categories              gic3
            ,mtl_categories_b                 mcb3
            ,xxcmn_rcv_pay_mst                xrpm
-- 2009/03/05 v1.31 ADD START
            ,ic_whse_mst                      iwm
-- 2009/03/05 v1.31 ADD END
      WHERE  itc.doc_type            = gv_doc_type_adji
      AND    itc.reason_code        IN (gv_reason_code_adji_itm
                                       ,gv_reason_code_adji_itm_u
                                       ,gv_reason_code_adji_snt_u
                                       ,gv_reason_code_adji_snt)
      AND    itc.trans_date > FND_DATE.STRING_TO_DATE(gd_prv1_dt_chr,gc_char_dt_format)
      AND    itc.trans_date < FND_DATE.STRING_TO_DATE(gd_flw_dt_chr,gc_char_dt_format)
      AND    ilm.item_id             = itc.item_id
      AND    ilm.lot_id              = itc.lot_id
      AND    iimb.item_id            = ilm.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(itc.trans_date)
      AND    ximb.end_date_active   >= TRUNC(itc.trans_date)
      AND    gic1.item_id            = itc.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = itc.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    gic3.item_id            = itc.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
-- 2008/11/19 v1.18 DELETE START
      --AND    xrpm.rcv_pay_div        = CASE
      --                                 WHEN itc.trans_qty >= 0 THEN 1
      --                                 ELSE -1
      --                                 END
-- 2008/11/19 v1.18 DELETE END
      AND    xrpm.doc_type           = itc.doc_type
      AND    xrpm.reason_code        = itc.reason_code
      AND    xrpm.break_col_01       IS NOT NULL
-- 2009/03/05 v1.31 ADD START
      AND    iwm.whse_code           = itc.whse_code
      AND    iwm.attribute1          = '0'
-- 2009/03/05 v1.31 ADD END
      UNION ALL
      SELECT /*+ leading (itp gic1 mcb1 gic2 mcb2) use_nl (itp gic1 mcb1 gic2 mcb2)*/
             NULL                                 h_whse_code
            ,NULL                                 h_whse_name
            ,itp.trans_id                         trans_id
            ,iimb.attribute15                     cost_mng_clss
            ,iimb.lot_ctl                         lot_ctl
            ,xlc.unit_ploce                       actual_unit_price
            ,CASE WHEN INSTR(xrpm.break_col_01,gv_hifn) = 0
                       THEN ''
                  WHEN xrpm.rcv_pay_div = gc_rcv_pay_div_in
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  ELSE SUBSTR(xrpm.break_col_01,INSTR(xrpm.break_col_01,gv_hifn) +1)
             END                                  column_no
            ,itp.reason_code                      reason_code
            ,itp.trans_date                       trans_date
            ,TO_CHAR(itp.trans_date, 'YYYYMM')  trans_ym
            ,CASE WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN TO_CHAR(ABS(TO_NUMBER(xrpm.rcv_pay_div)))
                  ELSE xrpm.rcv_pay_div
             END                                  rcv_pay_div
            ,xrpm.dealings_div                    dealings_div
            ,itp.doc_type                         doc_type
            ,ir_param.item_class                  item_div
            ,ir_param.goods_class                 prod_div
            ,mcb3.segment1                        crowd_code
            ,SUBSTR(mcb3.segment1, 1, 3)          crowd_low
            ,SUBSTR(mcb3.segment1, 1, 2)          crowd_mid
            ,SUBSTR(mcb3.segment1, 1, 1)          crowd_high
            ,itp.item_id                          item_id
            ,itp.lot_id                           lot_id
            ,NVL(itp.trans_qty, 0)                trans_qty
            ,itp.trans_date                       arrival_date
            ,TO_CHAR(itp.trans_date, gc_char_ym_format) arrival_ym
            ,iimb.item_no                         item_code
            ,ximb.item_short_name                 item_name
      FROM   ic_tran_pnd                      itp
            ,ic_item_mst_b                    iimb
            ,xxcmn_item_mst_b                 ximb
            ,ic_lots_mst                      ilm
            ,xxcmn_lot_cost                   xlc
            ,gmi_item_categories              gic1
            ,mtl_categories_b                 mcb1
            ,gmi_item_categories              gic2
            ,mtl_categories_b                 mcb2
            ,gmi_item_categories              gic3
            ,mtl_categories_b                 mcb3
            ,gme_material_details             gmd
            ,gme_batch_header                 gbh
            ,gmd_routings_b                   grb
            ,xxcmn_rcv_pay_mst                xrpm
-- 2009/03/05 v1.31 ADD START
            ,ic_whse_mst                      iwm
-- 2009/03/05 v1.31 ADD END
      WHERE  itp.doc_type            = gv_doc_type_prod
      AND    itp.completed_ind       = 1
      AND    itp.trans_date > FND_DATE.STRING_TO_DATE(gd_prv1_dt_chr,gc_char_dt_format)
      AND    itp.trans_date < FND_DATE.STRING_TO_DATE(gd_flw_dt_chr,gc_char_dt_format)
      AND    itp.reverse_id          IS NULL
      AND    ilm.item_id             = itp.item_id
      AND    ilm.lot_id              = itp.lot_id
      AND    iimb.item_id            = ilm.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(itp.trans_date)
      AND    ximb.end_date_active   >= TRUNC(itp.trans_date)
      AND    gic1.item_id            = itp.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = itp.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    gic3.item_id            = itp.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
      AND    gmd.batch_id            = itp.doc_id
      AND    gmd.line_no             = itp.doc_line
      AND    gmd.line_type           = itp.line_type
      AND    gbh.batch_id            = gmd.batch_id
      AND    grb.routing_id          = gbh.routing_id
      AND    xrpm.routing_class      = grb.routing_class
      AND    xrpm.line_type          = gmd.line_type
      AND    (((gmd.attribute5 IS NULL) AND (xrpm.hit_in_div IS NULL))
             OR (xrpm.hit_in_div = gmd.attribute5))
      AND    itp.doc_type            = xrpm.doc_type
      AND    itp.line_type           = xrpm.line_type
      AND    xrpm.break_col_01       IS NOT NULL
      AND    xrpm.routing_class      <> '70'
-- 2009/03/05 v1.31 ADD START
      AND    iwm.whse_code           = itp.whse_code
      AND    iwm.attribute1          = '0'
-- 2009/03/05 v1.31 ADD END
      UNION ALL
      SELECT /*+ leading (itp gic1 mcb1 gic2 mcb2 gmd gbh grb) use_nl (itp gic1 mcb1 gic2 mcb2 gmd gbh grb)*/
             NULL                                 h_whse_code
            ,NULL                                 h_whse_name
            ,itp.trans_id                         trans_id
            ,iimb.attribute15                     cost_mng_clss
            ,iimb.lot_ctl                         lot_ctl
            ,xlc.unit_ploce                       actual_unit_price
            ,CASE WHEN INSTR(xrpm.break_col_01,gv_hifn) = 0
                       THEN ''
                  WHEN xrpm.rcv_pay_div = gc_rcv_pay_div_in
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  ELSE SUBSTR(xrpm.break_col_01,INSTR(xrpm.break_col_01,gv_hifn) +1)
             END                                  column_no
            ,itp.reason_code                      reason_code
            ,itp.trans_date                       trans_date
            ,TO_CHAR(itp.trans_date, 'YYYYMM')  trans_ym
            ,CASE WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN TO_CHAR(ABS(TO_NUMBER(xrpm.rcv_pay_div)))
                  ELSE xrpm.rcv_pay_div
             END                                  rcv_pay_div
            ,xrpm.dealings_div                    dealings_div
            ,itp.doc_type                         doc_type
            ,ir_param.item_class                  item_div
            ,ir_param.goods_class                 prod_div
            ,mcb3.segment1                        crowd_code
            ,SUBSTR(mcb3.segment1, 1, 3)          crowd_low
            ,SUBSTR(mcb3.segment1, 1, 2)          crowd_mid
            ,SUBSTR(mcb3.segment1, 1, 1)          crowd_high
            ,itp.item_id                          item_id
            ,itp.lot_id                           lot_id
            ,NVL(itp.trans_qty, 0)                trans_qty
            ,itp.trans_date                       arrival_date
            ,TO_CHAR(itp.trans_date, gc_char_ym_format) arrival_ym
            ,iimb.item_no                         item_code
            ,ximb.item_short_name                 item_name
      FROM   ic_tran_pnd                      itp
            ,ic_item_mst_b                    iimb
            ,xxcmn_item_mst_b                 ximb
            ,ic_lots_mst                      ilm
            ,xxcmn_lot_cost                   xlc
            ,gmi_item_categories              gic1
            ,mtl_categories_b                 mcb1
            ,gmi_item_categories              gic2
            ,mtl_categories_b                 mcb2
            ,gmi_item_categories              gic3
            ,mtl_categories_b                 mcb3
            ,gme_material_details             gmd
            ,gme_batch_header                 gbh
            ,gmd_routings_b                   grb
            ,xxcmn_rcv_pay_mst                xrpm
-- 2009/03/05 v1.31 ADD START
            ,ic_whse_mst                      iwm
-- 2009/03/05 v1.31 ADD END
      WHERE  itp.doc_type            = gv_doc_type_prod
      AND    itp.completed_ind       = 1
      AND    itp.trans_date > FND_DATE.STRING_TO_DATE(gd_prv1_dt_chr,gc_char_dt_format)
      AND    itp.trans_date < FND_DATE.STRING_TO_DATE(gd_flw_dt_chr,gc_char_dt_format)
      AND    itp.reverse_id          IS NULL
      AND    ilm.item_id             = itp.item_id
      AND    ilm.lot_id              = itp.lot_id
      AND    iimb.item_id            = ilm.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(itp.trans_date)
      AND    ximb.end_date_active   >= TRUNC(itp.trans_date)
      AND    gic1.item_id            = itp.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = itp.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    mcb2.segment1           IN ('1','4')
      AND    gic3.item_id            = itp.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
      AND    gmd.batch_id            = itp.doc_id
      AND    gmd.line_no             = itp.doc_line
      AND    gmd.line_type           = itp.line_type
      AND    gbh.batch_id            = gmd.batch_id
      AND    grb.routing_id          = gbh.routing_id
      AND    xrpm.routing_class      = grb.routing_class
      AND    xrpm.line_type          = gmd.line_type
      AND    (((gmd.attribute5 IS NULL) AND (xrpm.hit_in_div IS NULL))
             OR (xrpm.hit_in_div = gmd.attribute5))
      AND    itp.doc_type            = xrpm.doc_type
      AND    itp.line_type           = xrpm.line_type
      AND    xrpm.break_col_01       IS NOT NULL
      AND    xrpm.routing_class      = '70'
      AND    (EXISTS (SELECT 1
                      FROM   gme_material_details gmd2
                            ,gmi_item_categories  gic
                            ,mtl_categories_b     mcb
                      WHERE  gmd2.batch_id   = gmd.batch_id
                      AND    gmd2.line_no    = gmd.line_no
                      AND    gmd2.line_type  = -1
                      AND    gic.item_id     = gmd2.item_id
                      AND    gic.category_set_id = cn_item_class_id
                      AND    gic.category_id = mcb.category_id
                      AND    mcb.segment1    = xrpm.item_div_origin))
      AND    (EXISTS (SELECT 1
                      FROM   gme_material_details gmd3
                            ,gmi_item_categories  gic
                            ,mtl_categories_b     mcb
                      WHERE  gmd3.batch_id   = gmd.batch_id
                      AND    gmd3.line_no    = gmd.line_no
                      AND    gmd3.line_type  = 1
                      AND    gic.item_id     = gmd3.item_id
                      AND    gic.category_set_id = cn_item_class_id
                      AND    gic.category_id = mcb.category_id
                      AND    mcb.segment1    = xrpm.item_div_ahead))
-- 2009/03/05 v1.31 ADD START
      AND    iwm.whse_code           = itp.whse_code
      AND    iwm.attribute1          = '0'
-- 2009/03/05 v1.31 ADD END
      UNION ALL
      SELECT /*+ leading (xoha xola rsl itp gic1 mcb1 gic2 mcb2 ooha otta) use_nl (xoha xola rsl itp gic1 mcb1 gic2 mcb2 ooha otta) */
             NULL                                 h_whse_code
            ,NULL                                 h_whse_name
            ,itp.trans_id                         trans_id
            ,iimb.attribute15                     cost_mng_clss
            ,iimb.lot_ctl                         lot_ctl
            ,xlc.unit_ploce                       actual_unit_price
            ,CASE WHEN INSTR(xrpm.break_col_01,gv_hifn) = 0
                       THEN ''
                  WHEN xrpm.rcv_pay_div = gc_rcv_pay_div_in
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  ELSE SUBSTR(xrpm.break_col_01,INSTR(xrpm.break_col_01,gv_hifn) +1)
             END                                  column_no
            ,itp.reason_code                      reason_code
            ,itp.trans_date                       trans_date
            ,TO_CHAR(itp.trans_date, 'YYYYMM')  trans_ym
            ,CASE WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN TO_CHAR(ABS(TO_NUMBER(xrpm.rcv_pay_div)))
                  ELSE xrpm.rcv_pay_div
             END                                  rcv_pay_div
            ,xrpm.dealings_div                    dealings_div
            ,itp.doc_type                         doc_type
            ,ir_param.item_class                  item_div
            ,ir_param.goods_class                 prod_div
            ,mcb3.segment1                        crowd_code
            ,SUBSTR(mcb3.segment1, 1, 3)          crowd_low
            ,SUBSTR(mcb3.segment1, 1, 2)          crowd_mid
            ,SUBSTR(mcb3.segment1, 1, 1)          crowd_high
            ,itp.item_id                          item_id
            ,itp.lot_id                           lot_id
            ,NVL(itp.trans_qty, 0)                trans_qty
            ,xoha.arrival_date                    arrival_date
            ,TO_CHAR(xoha.arrival_date, gc_char_ym_format) arrival_ym
            ,iimb.item_no                         item_code
            ,ximb.item_short_name                 item_name
      FROM   ic_tran_pnd                      itp
            ,rcv_shipment_lines               rsl
            ,oe_order_headers_all             ooha
            ,oe_transaction_types_all         otta
            ,xxwsh_order_headers_all          xoha
            ,xxwsh_order_lines_all            xola
            ,ic_item_mst_b                    iimb
            ,xxcmn_item_mst_b                 ximb
            ,ic_lots_mst                      ilm
            ,xxcmn_lot_cost                   xlc
            ,gmi_item_categories              gic1
            ,mtl_categories_b                 mcb1
            ,gmi_item_categories              gic2
            ,mtl_categories_b                 mcb2
            ,gmi_item_categories              gic3
            ,mtl_categories_b                 mcb3
            ,xxcmn_rcv_pay_mst                xrpm
-- 2009/03/05 v1.31 ADD START
            ,ic_whse_mst                      iwm
-- 2009/03/05 v1.31 ADD END
      WHERE  itp.doc_type            = gv_doc_type_porc
      AND    itp.completed_ind       = 1
      AND    xoha.latest_external_flag = 'Y'
      AND    xoha.arrival_date > FND_DATE.STRING_TO_DATE(gd_prv1_dt_chr,gc_char_dt_format)
      AND    xoha.arrival_date < FND_DATE.STRING_TO_DATE(gd_flw_dt_chr,gc_char_dt_format)
      AND    xoha.req_status         IN ('04','08')
      AND    ilm.item_id             = itp.item_id
      AND    ilm.lot_id              = itp.lot_id
      AND    iimb.item_id            = itp.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(itp.trans_date)
      AND    ximb.end_date_active   >= TRUNC(itp.trans_date)
      AND    gic1.item_id            = itp.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = itp.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    gic3.item_id            = itp.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
      AND    rsl.shipment_header_id  = itp.doc_id
      AND    rsl.line_num            = itp.doc_line
      AND    rsl.oe_order_header_id  = xola.header_id
      AND    rsl.oe_order_line_id    = xola.line_id
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    ((otta.attribute4           <> '2')
             OR  (otta.attribute4       IS NULL))
      AND    otta.attribute1         IN ('1','2')
      AND    xoha.header_id          = ooha.header_id
      AND    xola.order_header_id    = xoha.order_header_id
      AND    xola.request_item_code  = xola.shipping_item_code
      AND    xrpm.doc_type           = itp.doc_type
      AND    xrpm.source_document_code = 'RMA'
      AND    xrpm.dealings_div       IN ('101','103')
      AND    xrpm.shipment_provision_div = DECODE(xoha.req_status,'04','1','08','2')
      AND    xrpm.shipment_provision_div = otta.attribute1
      AND    ((xrpm.ship_prov_rcv_pay_category IS NULL)
             OR (xrpm.ship_prov_rcv_pay_category = otta.attribute11))
      AND    xrpm.break_col_01       IS NOT NULL
      AND    xrpm.item_div_origin    IS NULL
      AND    xrpm.item_div_ahead     IS NULL
-- 2009/03/05 v1.31 ADD START
      AND    iwm.whse_code           = itp.whse_code
      AND    iwm.attribute1          = '0'
-- 2009/03/05 v1.31 ADD END
      UNION ALL
      SELECT /*+ leading (xoha xola rsl itp gic1 mcb1 gic2 mcb2 ooha otta) use_nl (xoha xola rsl itp gic1 mcb1 gic2 mcb2 ooha otta) */
             NULL                                 h_whse_code
            ,NULL                                 h_whse_name
            ,itp.trans_id                         trans_id
            ,iimb.attribute15                     cost_mng_clss
            ,iimb.lot_ctl                         lot_ctl
            ,xlc.unit_ploce                       actual_unit_price
            ,CASE WHEN INSTR(xrpm.break_col_01,gv_hifn) = 0
                       THEN ''
                  WHEN xrpm.rcv_pay_div = gc_rcv_pay_div_in
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  ELSE SUBSTR(xrpm.break_col_01,INSTR(xrpm.break_col_01,gv_hifn) +1)
             END                                  column_no
            ,itp.reason_code                      reason_code
            ,itp.trans_date                       trans_date
            ,TO_CHAR(itp.trans_date, 'YYYYMM')  trans_ym
            ,CASE WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN TO_CHAR(ABS(TO_NUMBER(xrpm.rcv_pay_div)))
                  ELSE xrpm.rcv_pay_div
             END                                  rcv_pay_div
            ,xrpm.dealings_div                    dealings_div
            ,itp.doc_type                         doc_type
            ,ir_param.item_class                  item_div
            ,ir_param.goods_class                 prod_div
            ,mcb3.segment1                        crowd_code
            ,SUBSTR(mcb3.segment1, 1, 3)          crowd_low
            ,SUBSTR(mcb3.segment1, 1, 2)          crowd_mid
            ,SUBSTR(mcb3.segment1, 1, 1)          crowd_high
            ,iimb.item_id                         item_id
            ,itp.lot_id                           lot_id
            ,NVL(itp.trans_qty, 0)                trans_qty
            ,xoha.arrival_date                      arrival_date
            ,TO_CHAR(xoha.arrival_date, gc_char_ym_format) arrival_ym
            ,iimb.item_no                         item_code
            ,ximb.item_short_name                 item_name
      FROM   ic_tran_pnd                      itp
            ,rcv_shipment_lines               rsl
            ,oe_order_headers_all             ooha
            ,oe_transaction_types_all         otta
            ,xxwsh_order_headers_all          xoha
            ,xxwsh_order_lines_all            xola
            ,ic_item_mst_b                    iimb
            ,ic_item_mst_b                    iimb2
            ,xxcmn_item_mst_b                 ximb
            ,ic_lots_mst                      ilm
            ,xxcmn_lot_cost                   xlc
            ,gmi_item_categories              gic1
            ,mtl_categories_b                 mcb1
            ,gmi_item_categories              gic2
            ,mtl_categories_b                 mcb2
            ,gmi_item_categories              gic3
            ,mtl_categories_b                 mcb3
            ,gmi_item_categories              gic4
            ,mtl_categories_b                 mcb4
            ,xxcmn_rcv_pay_mst                xrpm
-- 2009/03/05 v1.31 ADD START
            ,ic_whse_mst                      iwm
-- 2009/03/05 v1.31 ADD END
      WHERE  itp.doc_type            = gv_doc_type_porc
      AND    itp.completed_ind       = 1
      AND    xoha.latest_external_flag = 'Y'
      AND    xoha.arrival_date > FND_DATE.STRING_TO_DATE(gd_prv1_dt_chr,gc_char_dt_format)
      AND    xoha.arrival_date < FND_DATE.STRING_TO_DATE(gd_flw_dt_chr,gc_char_dt_format)
      AND    xoha.req_status         IN ('04','08')
      AND    ilm.item_id             = itp.item_id
      AND    ilm.lot_id              = itp.lot_id
      AND    iimb.item_id            = itp.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    iimb2.item_no           = xola.request_item_code
      AND    ximb.start_date_active <= TRUNC(itp.trans_date)
      AND    ximb.end_date_active   >= TRUNC(itp.trans_date)
      AND    gic1.item_id            = itp.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = itp.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    gic3.item_id            = itp.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
      AND    gic4.item_id            = iimb2.item_id
      AND    gic4.category_set_id    = cn_item_class_id
      AND    gic4.category_id        = mcb4.category_id
      AND    rsl.shipment_header_id  = itp.doc_id
      AND    rsl.line_num            = itp.doc_line
      AND    rsl.oe_order_header_id  = xoha.header_id
      AND    rsl.oe_order_line_id    = xola.line_id
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    ((otta.attribute4           <> '2')
             OR  (otta.attribute4       IS NULL))
      AND    otta.attribute1         IN ('1','2')
      AND    xoha.header_id          = ooha.header_id
      AND    xola.order_header_id    = xoha.order_header_id
      AND    xrpm.doc_type           = itp.doc_type
      AND    xrpm.source_document_code = 'RMA'
      AND    xrpm.dealings_div       = '106'
      AND    xrpm.shipment_provision_div = DECODE(xoha.req_status,'04','1','08','2')
      AND    xrpm.shipment_provision_div = otta.attribute1
      AND    xrpm.ship_prov_rcv_pay_category = otta.attribute11
      AND    xrpm.item_div_ahead     = mcb4.segment1
      AND    mcb2.segment1           <> '5'
      AND    xrpm.break_col_01       IS NOT NULL
-- 2009/03/05 v1.31 ADD START
      AND    iwm.whse_code           = itp.whse_code
      AND    iwm.attribute1          = '0'
-- 2009/03/05 v1.31 ADD END
      UNION ALL
      SELECT /*+ leading (xoha xola rsl itp gic1 mcb1 gic2 mcb2 ooha otta xrpm) use_nl (xoha xola rsl itp gic1 mcb1 gic2 mcb2 rsl ooha otta xrpm) */
             NULL                                 h_whse_code
            ,NULL                                 h_whse_name
            ,itp.trans_id                         trans_id
            ,iimb.attribute15                     cost_mng_clss
            ,iimb.lot_ctl                         lot_ctl
            ,xlc.unit_ploce                       actual_unit_price
            ,CASE WHEN INSTR(xrpm.break_col_01,gv_hifn) = 0
                       THEN ''
                  WHEN xrpm.rcv_pay_div = gc_rcv_pay_div_in
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  ELSE SUBSTR(xrpm.break_col_01,INSTR(xrpm.break_col_01,gv_hifn) +1)
             END                                  column_no
            ,itp.reason_code                      reason_code
            ,itp.trans_date                       trans_date
            ,TO_CHAR(itp.trans_date, 'YYYYMM')  trans_ym
            ,CASE WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN TO_CHAR(ABS(TO_NUMBER(xrpm.rcv_pay_div)))
                  ELSE xrpm.rcv_pay_div
             END                                  rcv_pay_div
            ,xrpm.dealings_div                    dealings_div
            ,itp.doc_type                         doc_type
            ,ir_param.item_class                  item_div
            ,ir_param.goods_class                 prod_div
            ,mcb3.segment1                        crowd_code
            ,SUBSTR(mcb3.segment1, 1, 3)          crowd_low
            ,SUBSTR(mcb3.segment1, 1, 2)          crowd_mid
            ,SUBSTR(mcb3.segment1, 1, 1)          crowd_high
            ,iimb.item_id                         item_id
            ,itp.lot_id                           lot_id
            ,NVL(itp.trans_qty, 0)                trans_qty
            ,xoha.arrival_date                    arrival_date
            ,TO_CHAR(xoha.arrival_date, gc_char_ym_format) arrival_ym
            ,iimb.item_no                         item_code
            ,ximb.item_short_name                 item_name
      FROM   ic_tran_pnd                      itp
            ,rcv_shipment_lines               rsl
            ,oe_order_headers_all             ooha
            ,oe_transaction_types_all         otta
            ,xxwsh_order_headers_all          xoha
            ,xxwsh_order_lines_all            xola
            ,ic_item_mst_b                    iimb
            ,ic_item_mst_b                    iimb2
            ,xxcmn_item_mst_b                 ximb
            ,ic_lots_mst                      ilm
            ,xxcmn_lot_cost                   xlc
            ,gmi_item_categories              gic1
            ,mtl_categories_b                 mcb1
            ,gmi_item_categories              gic2
            ,mtl_categories_b                 mcb2
            ,gmi_item_categories              gic3
            ,mtl_categories_b                 mcb3
            ,gmi_item_categories              gic4
            ,mtl_categories_b                 mcb4
            ,xxcmn_rcv_pay_mst                xrpm
-- 2009/03/05 v1.31 ADD START
            ,ic_whse_mst                      iwm
-- 2009/03/05 v1.31 ADD END
      WHERE  itp.doc_type            = gv_doc_type_porc
      AND    itp.completed_ind       = 1
      AND    xoha.latest_external_flag = 'Y'
      AND    xoha.arrival_date > FND_DATE.STRING_TO_DATE(gd_prv1_dt_chr,gc_char_dt_format)
      AND    xoha.arrival_date < FND_DATE.STRING_TO_DATE(gd_flw_dt_chr,gc_char_dt_format)
      AND    xoha.req_status         = '04'
      AND    ilm.item_id             = itp.item_id
      AND    ilm.lot_id              = itp.lot_id
      AND    iimb.item_id            = itp.item_id
      AND    iimb2.item_no           = xola.request_item_code
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(itp.trans_date)
      AND    ximb.end_date_active   >= TRUNC(itp.trans_date)
      AND    gic1.item_id            = itp.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = itp.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    gic3.item_id            = itp.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
      AND    gic4.item_id            = iimb2.item_id
      AND    gic4.category_set_id    = cn_item_class_id
      AND    gic4.category_id        = mcb4.category_id
      AND    rsl.shipment_header_id  = itp.doc_id
      AND    rsl.line_num            = itp.doc_line
      AND    rsl.oe_order_header_id  = xoha.header_id
      AND    rsl.oe_order_line_id    = xola.line_id
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    ((otta.attribute4           <> '2')
             OR  (otta.attribute4       IS NULL))
      AND    xoha.header_id          = ooha.header_id
      AND    xola.order_header_id    = xoha.order_header_id
      AND    xrpm.doc_type           = itp.doc_type
      AND    xrpm.source_document_code = 'RMA'
      AND    xrpm.dealings_div       = '113'
      AND    xrpm.shipment_provision_div = DECODE(xoha.req_status,'04','1','08','2')
      AND    xrpm.item_div_ahead     = mcb4.segment1
      AND    mcb2.segment1           <> '5'
      AND    xrpm.break_col_01       IS NOT NULL
-- 2009/03/05 v1.31 ADD START
      AND    iwm.whse_code           = itp.whse_code
      AND    iwm.attribute1          = '0'
-- 2009/03/05 v1.31 ADD END
      UNION ALL
      SELECT /*+ leading (xoha ooha otta xola rsl itp gic1 mcb1 gic2 mcb2) use_nl (xoha ooha otta xola rsl itp gic1 mcb1 gic2 mcb2) */
             NULL                                 h_whse_code
            ,NULL                                 h_whse_name
            ,itp.trans_id                         trans_id
            ,iimb.attribute15                     cost_mng_clss
            ,iimb.lot_ctl                         lot_ctl
            ,xlc.unit_ploce                       actual_unit_price
            ,CASE WHEN INSTR(xrpm.break_col_01,gv_hifn) = 0
                       THEN ''
                  WHEN xrpm.rcv_pay_div = gc_rcv_pay_div_in
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  ELSE SUBSTR(xrpm.break_col_01,INSTR(xrpm.break_col_01,gv_hifn) +1)
             END                                  column_no
            ,itp.reason_code                      reason_code
            ,itp.trans_date                       trans_date
            ,TO_CHAR(itp.trans_date, 'YYYYMM')  trans_ym
            ,CASE WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN TO_CHAR(ABS(TO_NUMBER(xrpm.rcv_pay_div)))
                  ELSE xrpm.rcv_pay_div
             END                                  rcv_pay_div
            ,xrpm.dealings_div                    dealings_div
            ,itp.doc_type                         doc_type
            ,ir_param.item_class                  item_div
            ,ir_param.goods_class                 prod_div
            ,mcb3.segment1                        crowd_code
            ,SUBSTR(mcb3.segment1, 1, 3)          crowd_low
            ,SUBSTR(mcb3.segment1, 1, 2)          crowd_mid
            ,SUBSTR(mcb3.segment1, 1, 1)          crowd_high
            ,itp.item_id                          item_id
            ,itp.lot_id                           lot_id
            ,NVL(itp.trans_qty, 0)                trans_qty
            ,xoha.arrival_date                    arrival_date
            ,TO_CHAR(xoha.arrival_date, gc_char_ym_format) arrival_ym
            ,iimb.item_no                         item_code
            ,ximb.item_short_name                 item_name
      FROM   ic_tran_pnd                      itp
            ,rcv_shipment_lines               rsl
            ,oe_order_headers_all             ooha
            ,oe_transaction_types_all         otta
            ,xxwsh_order_headers_all          xoha
            ,xxwsh_order_lines_all            xola
            ,ic_item_mst_b                    iimb
            ,xxcmn_item_mst_b                 ximb
            ,ic_lots_mst                      ilm
            ,xxcmn_lot_cost                   xlc
            ,gmi_item_categories              gic1
            ,mtl_categories_b                 mcb1
            ,gmi_item_categories              gic2
            ,mtl_categories_b                 mcb2
            ,gmi_item_categories              gic3
            ,mtl_categories_b                 mcb3
            ,xxcmn_rcv_pay_mst                xrpm
-- 2009/03/05 v1.31 ADD START
            ,ic_whse_mst                      iwm
-- 2009/03/05 v1.31 ADD END
      WHERE  itp.doc_type            = gv_doc_type_porc
      AND    itp.completed_ind       = 1
      AND    xoha.latest_external_flag = 'Y'
      AND    xoha.arrival_date > FND_DATE.STRING_TO_DATE(gd_prv1_dt_chr,gc_char_dt_format)
      AND    xoha.arrival_date < FND_DATE.STRING_TO_DATE(gd_flw_dt_chr,gc_char_dt_format)
      AND    ilm.item_id             = itp.item_id
      AND    ilm.lot_id              = itp.lot_id
      AND    iimb.item_id            = itp.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(itp.trans_date)
      AND    ximb.end_date_active   >= TRUNC(itp.trans_date)
      AND    gic1.item_id            = itp.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = itp.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    gic3.item_id            = itp.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
      AND    rsl.shipment_header_id  = itp.doc_id
      AND    rsl.line_num            = itp.doc_line
      AND    rsl.oe_order_header_id  = xoha.header_id
      AND    rsl.oe_order_line_id    = xola.line_id
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    otta.attribute4         = '2'
      AND    xoha.header_id          = ooha.header_id
      AND    xola.order_header_id    = xoha.order_header_id
      AND    xrpm.doc_type           = itp.doc_type
      AND    xrpm.source_document_code = 'RMA'
      AND    xrpm.dealings_div       IN ('504','509')
      AND    xrpm.stock_adjustment_div = otta.attribute4
      AND    xrpm.ship_prov_rcv_pay_category = otta.attribute11
      AND    xrpm.break_col_01       IS NOT NULL
-- 2009/03/05 v1.31 ADD START
      AND    iwm.whse_code           = itp.whse_code
      AND    iwm.attribute1          = '0'
-- 2009/03/05 v1.31 ADD END
      UNION ALL
      SELECT /*+ leading (itp gic1 mcb1 gic2 mcb2) use_nl (itp gic1 mcb1 gic2 mcb2) */
             NULL                                 h_whse_code
            ,NULL                                 h_whse_name
-- v1.33 Mod Start
--            ,itp.trans_id                         trans_id
            ,NULL                                 trans_id
-- v1.33 Mod End
            ,iimb.attribute15                     cost_mng_clss
            ,iimb.lot_ctl                         lot_ctl
            ,xlc.unit_ploce                       actual_unit_price
            ,CASE WHEN INSTR(xrpm.break_col_01,gv_hifn) = 0
                       THEN ''
                  WHEN xrpm.rcv_pay_div = gc_rcv_pay_div_in
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  ELSE SUBSTR(xrpm.break_col_01,INSTR(xrpm.break_col_01,gv_hifn) +1)
             END                                  column_no
            ,itp.reason_code                      reason_code
            ,itp.trans_date                       trans_date
            ,TO_CHAR(itp.trans_date, 'YYYYMM')  trans_ym
            ,CASE WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN TO_CHAR(ABS(TO_NUMBER(xrpm.rcv_pay_div)))
                  ELSE xrpm.rcv_pay_div
             END                                  rcv_pay_div
            ,xrpm.dealings_div                    dealings_div
            ,itp.doc_type                         doc_type
            ,ir_param.item_class                  item_div
            ,ir_param.goods_class                 prod_div
            ,mcb3.segment1                        crowd_code
            ,SUBSTR(mcb3.segment1, 1, 3)          crowd_low
            ,SUBSTR(mcb3.segment1, 1, 2)          crowd_mid
            ,SUBSTR(mcb3.segment1, 1, 1)          crowd_high
            ,itp.item_id                          item_id
            ,itp.lot_id                           lot_id
-- v1.33 Mod Start
--            ,NVL(itp.trans_qty, 0)                trans_qty
            ,SUM(NVL(itp.trans_qty, 0))           trans_qty
-- v1.33 Mod End
            ,itp.trans_date                       arrival_date
            ,TO_CHAR(itp.trans_date, gc_char_ym_format) arrival_ym
            ,iimb.item_no                         item_code
            ,ximb.item_short_name                 item_name
      FROM   ic_tran_pnd                      itp
            ,ic_item_mst_b                    iimb
            ,xxcmn_item_mst_b                 ximb
            ,ic_lots_mst                      ilm
            ,xxcmn_lot_cost                   xlc
            ,gmi_item_categories              gic1
            ,mtl_categories_b                 mcb1
            ,gmi_item_categories              gic2
            ,mtl_categories_b                 mcb2
            ,gmi_item_categories              gic3
            ,mtl_categories_b                 mcb3
            ,rcv_shipment_lines               rsl
            ,rcv_transactions                 rt
            ,xxcmn_rcv_pay_mst                xrpm
-- 2009/03/05 v1.31 ADD START
            ,ic_whse_mst                      iwm
-- 2009/03/05 v1.31 ADD END
      WHERE  itp.doc_type            = gv_doc_type_porc
      AND    itp.completed_ind       = 1
      AND    itp.trans_date > FND_DATE.STRING_TO_DATE(gd_prv1_dt_chr,gc_char_dt_format)
      AND    itp.trans_date < FND_DATE.STRING_TO_DATE(gd_flw_dt_chr,gc_char_dt_format)
      AND    ilm.item_id             = itp.item_id
      AND    ilm.lot_id              = itp.lot_id
      AND    iimb.item_id            = ilm.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(itp.trans_date)
      AND    ximb.end_date_active   >= TRUNC(itp.trans_date)
      AND    gic1.item_id            = itp.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = itp.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    gic3.item_id            = itp.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
      AND    rsl.shipment_header_id  = itp.doc_id
      AND    rsl.line_num            = itp.doc_line
      AND    rt.transaction_id       = itp.line_id
      AND    rt.shipment_line_id     = rsl.shipment_line_id
      AND    xrpm.doc_type           = itp.doc_type
      AND    xrpm.source_document_code = rsl.source_document_code
      AND    xrpm.transaction_type   = rt.transaction_type
      AND    xrpm.break_col_01       IS NOT NULL
-- 2009/03/05 v1.31 ADD START
      AND    iwm.whse_code           = itp.whse_code
      AND    iwm.attribute1          = '0'
-- 2009/03/05 v1.31 ADD END
-- v1.33 Add Start
      GROUP BY
             iimb.attribute15                     -- cost_mng_clss
            ,iimb.lot_ctl                         -- lot_ctl
            ,xlc.unit_ploce                       -- actual_unit_price
            ,CASE WHEN INSTR(xrpm.break_col_01,gv_hifn) = 0
                       THEN ''
                  WHEN xrpm.rcv_pay_div = gc_rcv_pay_div_in
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  ELSE SUBSTR(xrpm.break_col_01,INSTR(xrpm.break_col_01,gv_hifn) +1)
             END                                  -- column_no
            ,itp.reason_code                      -- reason_code
            ,itp.trans_date                       -- trans_date
            ,TO_CHAR(itp.trans_date, 'YYYYMM')    -- trans_ym
            ,CASE WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN TO_CHAR(ABS(TO_NUMBER(xrpm.rcv_pay_div)))
                  ELSE xrpm.rcv_pay_div
             END                                  -- rcv_pay_div
            ,xrpm.dealings_div                    -- dealings_div
            ,itp.doc_type                         -- doc_type
            ,ir_param.item_class                  -- item_div
            ,ir_param.goods_class                 -- prod_div
            ,mcb3.segment1                        -- crowd_code
            ,SUBSTR(mcb3.segment1, 1, 3)          -- crowd_low
            ,SUBSTR(mcb3.segment1, 1, 2)          -- crowd_mid
            ,SUBSTR(mcb3.segment1, 1, 1)          -- crowd_high
            ,itp.item_id                          -- item_id
            ,itp.lot_id                           -- lot_id
            ,itp.trans_date                       -- arrival_date
            ,TO_CHAR(itp.trans_date, gc_char_ym_format) -- arrival_ym
            ,iimb.item_no                         -- item_code
            ,ximb.item_short_name                 -- item_name
            ,rsl.attribute1                       -- 受入返品実績アドオン.取引ID
-- v1.33 Add End
      UNION ALL
      SELECT /*+ leading (xoha xola wdd itp gic1 mcb1 gic2 mcb2 ooha otta) use_nl (xoha xola wdd itp gic1 mcb1 gic2 mcb2 ooha otta) */
             NULL                                 h_whse_code
            ,NULL                                 h_whse_name
            ,itp.trans_id                         trans_id
            ,iimb.attribute15                     cost_mng_clss
            ,iimb.lot_ctl                         lot_ctl
            ,xlc.unit_ploce                       actual_unit_price
            ,CASE WHEN INSTR(xrpm.break_col_01,gv_hifn) = 0
                       THEN ''
                  WHEN xrpm.rcv_pay_div = gc_rcv_pay_div_in
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  ELSE SUBSTR(xrpm.break_col_01,INSTR(xrpm.break_col_01,gv_hifn) +1)
             END                                  column_no
            ,itp.reason_code                      reason_code
            ,itp.trans_date                       trans_date
            ,TO_CHAR(itp.trans_date, 'YYYYMM')  trans_ym
            ,CASE WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN TO_CHAR(ABS(TO_NUMBER(xrpm.rcv_pay_div)))
                  ELSE xrpm.rcv_pay_div
             END                                  rcv_pay_div
            ,xrpm.dealings_div                    dealings_div
            ,itp.doc_type                         doc_type
            ,ir_param.item_class                  item_div
            ,ir_param.goods_class                 prod_div
            ,mcb3.segment1                        crowd_code
            ,SUBSTR(mcb3.segment1, 1, 3)          crowd_low
            ,SUBSTR(mcb3.segment1, 1, 2)          crowd_mid
            ,SUBSTR(mcb3.segment1, 1, 1)          crowd_high
            ,itp.item_id                          item_id
            ,itp.lot_id                           lot_id
            ,NVL(itp.trans_qty, 0)                trans_qty
            ,xoha.arrival_date                    arrival_date
            ,TO_CHAR(xoha.arrival_date, gc_char_ym_format) arrival_ym
            ,iimb.item_no                         item_code
            ,ximb.item_short_name                 item_name
      FROM   ic_tran_pnd                      itp
            ,wsh_delivery_details             wdd
            ,oe_order_headers_all             ooha
            ,oe_transaction_types_all         otta
            ,xxwsh_order_headers_all          xoha
            ,xxwsh_order_lines_all            xola
            ,ic_item_mst_b                    iimb
            ,xxcmn_item_mst_b                 ximb
            ,ic_lots_mst                      ilm
            ,xxcmn_lot_cost                   xlc
            ,gmi_item_categories              gic1
            ,mtl_categories_b                 mcb1
            ,gmi_item_categories              gic2
            ,mtl_categories_b                 mcb2
            ,gmi_item_categories              gic3
            ,mtl_categories_b                 mcb3
            ,xxcmn_rcv_pay_mst                xrpm
-- 2009/03/05 v1.31 ADD START
            ,ic_whse_mst                      iwm
-- 2009/03/05 v1.31 ADD END
      WHERE  itp.doc_type            = gv_doc_type_omso
      AND    itp.completed_ind       = 1
      AND    xoha.latest_external_flag = 'Y'
      AND    xoha.arrival_date > FND_DATE.STRING_TO_DATE(gd_prv2_dt_chr,gc_char_dt_format)
      AND    xoha.arrival_date < FND_DATE.STRING_TO_DATE(gd_flw_dt_chr,gc_char_dt_format)
      AND    xoha.req_status         IN ('04','08')
      AND    ilm.item_id             = itp.item_id
      AND    ilm.lot_id              = itp.lot_id
      AND    iimb.item_id            = ilm.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(itp.trans_date)
      AND    ximb.end_date_active   >= TRUNC(itp.trans_date)
      AND    gic1.item_id            = itp.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = itp.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    gic3.item_id            = itp.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
      AND    wdd.delivery_detail_id  = itp.line_detail_id
      AND    wdd.source_header_id    = xoha.header_id
      AND    wdd.source_line_id      = xola.line_id
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    ((otta.attribute4           <> '2')
             OR  (otta.attribute4       IS NULL))
      AND    otta.attribute1         IN ('1','2')
      AND    xoha.header_id          = ooha.header_id
      AND    xola.order_header_id    = xoha.order_header_id
      AND    xola.request_item_code  = xola.shipping_item_code
      AND    xrpm.doc_type           = itp.doc_type
      AND    xrpm.dealings_div       IN ('101','103')
      AND    xrpm.shipment_provision_div = DECODE(xoha.req_status,'04','1','08','2')
      AND    xrpm.shipment_provision_div = otta.attribute1
      AND    ((xrpm.ship_prov_rcv_pay_category IS NULL)
             OR (xrpm.ship_prov_rcv_pay_category = otta.attribute11))
      AND    xrpm.break_col_01       IS NOT NULL
      AND    xrpm.item_div_origin    IS NULL
      AND    xrpm.item_div_ahead     IS NULL
-- 2009/03/05 v1.31 ADD START
      AND    iwm.whse_code           = itp.whse_code
      AND    iwm.attribute1          = '0'
-- 2009/03/05 v1.31 ADD END
      UNION ALL
      SELECT /*+ leading (xoha xola wdd itp gic1 mcb1 gic2 mcb2 ooha otta xrpm) use_nl (xoha xola wdd itp gic1 mcb1 gic2 mcb2 ooha otta xrpm) */
             NULL                                 h_whse_code
            ,NULL                                 h_whse_name
            ,itp.trans_id                         trans_id
            ,iimb.attribute15                     cost_mng_clss
            ,iimb.lot_ctl                         lot_ctl
            ,xlc.unit_ploce                       actual_unit_price
            ,CASE WHEN INSTR(xrpm.break_col_01,gv_hifn) = 0
                       THEN ''
                  WHEN xrpm.rcv_pay_div = gc_rcv_pay_div_in
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  ELSE SUBSTR(xrpm.break_col_01,INSTR(xrpm.break_col_01,gv_hifn) +1)
             END                                  column_no
            ,itp.reason_code                      reason_code
            ,itp.trans_date                       trans_date
            ,TO_CHAR(itp.trans_date, 'YYYYMM')  trans_ym
            ,CASE WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN TO_CHAR(ABS(TO_NUMBER(xrpm.rcv_pay_div)))
                  ELSE xrpm.rcv_pay_div
             END                                  rcv_pay_div
            ,xrpm.dealings_div                    dealings_div
            ,itp.doc_type                         doc_type
            ,ir_param.item_class                  item_div
            ,ir_param.goods_class                 prod_div
            ,mcb3.segment1                        crowd_code
            ,SUBSTR(mcb3.segment1, 1, 3)          crowd_low
            ,SUBSTR(mcb3.segment1, 1, 2)          crowd_mid
            ,SUBSTR(mcb3.segment1, 1, 1)          crowd_high
            ,iimb.item_id                         item_id
            ,itp.lot_id                           lot_id
            ,NVL(itp.trans_qty, 0)                trans_qty
            ,xoha.arrival_date                    arrival_date
            ,TO_CHAR(xoha.arrival_date, gc_char_ym_format) arrival_ym
            ,iimb.item_no                         item_code
            ,ximb.item_short_name                 item_name
      FROM   ic_tran_pnd                      itp
            ,wsh_delivery_details             wdd
            ,oe_order_headers_all             ooha
            ,oe_transaction_types_all         otta
            ,xxwsh_order_headers_all          xoha
            ,xxwsh_order_lines_all            xola
            ,ic_item_mst_b                    iimb
            ,ic_item_mst_b                    iimb2
            ,xxcmn_item_mst_b                 ximb
            ,ic_lots_mst                      ilm
            ,xxcmn_lot_cost                   xlc
            ,gmi_item_categories              gic1
            ,mtl_categories_b                 mcb1
            ,gmi_item_categories              gic2
            ,mtl_categories_b                 mcb2
            ,gmi_item_categories              gic3
            ,mtl_categories_b                 mcb3
            ,gmi_item_categories              gic4
            ,mtl_categories_b                 mcb4
            ,xxcmn_rcv_pay_mst                xrpm
-- 2009/03/05 v1.31 ADD START
            ,ic_whse_mst                      iwm
-- 2009/03/05 v1.31 ADD END
      WHERE  itp.doc_type            = gv_doc_type_omso
      AND    itp.completed_ind       = 1
      AND    xoha.latest_external_flag = 'Y'
      AND    xoha.arrival_date > FND_DATE.STRING_TO_DATE(gd_prv2_dt_chr,gc_char_dt_format)
      AND    xoha.arrival_date < FND_DATE.STRING_TO_DATE(gd_flw_dt_chr,gc_char_dt_format)
      AND    xoha.req_status         = '08'
      AND    ilm.item_id             = itp.item_id
      AND    ilm.lot_id              = itp.lot_id
      AND    iimb.item_id            = itp.item_id
      AND    iimb2.item_no           = xola.request_item_code
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(itp.trans_date)
      AND    ximb.end_date_active   >= TRUNC(itp.trans_date)
      AND    gic1.item_id            = itp.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = itp.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    gic3.item_id            = itp.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
      AND    gic4.item_id            = iimb2.item_id
      AND    gic4.category_set_id    = cn_item_class_id
      AND    gic4.category_id        = mcb4.category_id
      AND    wdd.delivery_detail_id  = itp.line_detail_id
      AND    wdd.source_header_id    = xoha.header_id
      AND    wdd.source_line_id      = xola.line_id
      AND    xola.order_header_id    = xoha.order_header_id
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    ((otta.attribute4           <> '2')
             OR  (otta.attribute4       IS NULL))
      AND    otta.attribute1         = '2'
      AND    xoha.header_id          = ooha.header_id
      AND    xrpm.doc_type           = itp.doc_type
      AND    xrpm.dealings_div       = '106'
      AND    xrpm.shipment_provision_div = DECODE(xoha.req_status,'04','1','08','2')
      AND    xrpm.shipment_provision_div = otta.attribute1
      AND    xrpm.ship_prov_rcv_pay_category = otta.attribute11
      AND    xrpm.item_div_ahead     = mcb4.segment1
      AND    mcb2.segment1           <> '5'
      AND    xrpm.break_col_01       IS NOT NULL
-- 2009/03/05 v1.31 ADD START
      AND    iwm.whse_code           = itp.whse_code
      AND    iwm.attribute1          = '0'
-- 2009/03/05 v1.31 ADD END
      UNION ALL
      SELECT /*+ leading (xoha xola wdd itp gic1 mcb1 gic2 mcb2 ooha otta xrpm) use_nl (xoha xola wdd itp gic1 mcb1 gic2 mcb2 ooha otta xrpm) */
             NULL                                 h_whse_code
            ,NULL                                 h_whse_name
            ,itp.trans_id                         trans_id
            ,iimb.attribute15                     cost_mng_clss
            ,iimb.lot_ctl                         lot_ctl
            ,xlc.unit_ploce                       actual_unit_price
            ,CASE WHEN INSTR(xrpm.break_col_01,gv_hifn) = 0
                       THEN ''
                  WHEN xrpm.rcv_pay_div = gc_rcv_pay_div_in
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  ELSE SUBSTR(xrpm.break_col_01,INSTR(xrpm.break_col_01,gv_hifn) +1)
             END                                  column_no
            ,itp.reason_code                      reason_code
            ,itp.trans_date                       trans_date
            ,TO_CHAR(itp.trans_date, 'YYYYMM')  trans_ym
            ,CASE WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN TO_CHAR(ABS(TO_NUMBER(xrpm.rcv_pay_div)))
                  ELSE xrpm.rcv_pay_div
             END                                  rcv_pay_div
            ,xrpm.dealings_div                    dealings_div
            ,itp.doc_type                         doc_type
            ,ir_param.item_class                  item_div
            ,ir_param.goods_class                 prod_div
            ,mcb3.segment1                        crowd_code
            ,SUBSTR(mcb3.segment1, 1, 3)          crowd_low
            ,SUBSTR(mcb3.segment1, 1, 2)          crowd_mid
            ,SUBSTR(mcb3.segment1, 1, 1)          crowd_high
            ,iimb.item_id                         item_id
            ,itp.lot_id                           lot_id
            ,NVL(itp.trans_qty, 0)                trans_qty
            ,xoha.arrival_date                    arrival_date
            ,TO_CHAR(xoha.arrival_date, gc_char_ym_format) arrival_ym
            ,iimb.item_no                         item_code
            ,ximb.item_short_name                 item_name
      FROM   ic_tran_pnd                      itp
            ,wsh_delivery_details             wdd
            ,oe_order_headers_all             ooha
            ,oe_transaction_types_all         otta
            ,xxwsh_order_headers_all          xoha
            ,xxwsh_order_lines_all            xola
            ,ic_item_mst_b                    iimb
            ,ic_item_mst_b                    iimb2
            ,xxcmn_item_mst_b                 ximb
            ,ic_lots_mst                      ilm
            ,xxcmn_lot_cost                   xlc
            ,gmi_item_categories              gic1
            ,mtl_categories_b                 mcb1
            ,gmi_item_categories              gic2
            ,mtl_categories_b                 mcb2
            ,gmi_item_categories              gic3
            ,mtl_categories_b                 mcb3
            ,gmi_item_categories              gic4
            ,mtl_categories_b                 mcb4
            ,xxcmn_rcv_pay_mst                xrpm
-- 2009/03/05 v1.31 ADD START
            ,ic_whse_mst                      iwm
-- 2009/03/05 v1.31 ADD END
      WHERE  itp.doc_type            = gv_doc_type_omso
      AND    itp.completed_ind       = 1
      AND    xoha.latest_external_flag = 'Y'
      AND    xoha.arrival_date > FND_DATE.STRING_TO_DATE(gd_prv2_dt_chr,gc_char_dt_format)
      AND    xoha.arrival_date < FND_DATE.STRING_TO_DATE(gd_flw_dt_chr,gc_char_dt_format)
      AND    xoha.req_status         = '04'
      AND    ilm.item_id             = itp.item_id
      AND    ilm.lot_id              = itp.lot_id
      AND    iimb.item_id            = itp.item_id
      AND    iimb2.item_no           = xola.request_item_code
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(itp.trans_date)
      AND    ximb.end_date_active   >= TRUNC(itp.trans_date)
      AND    gic1.item_id            = itp.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = itp.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    gic3.item_id            = itp.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
      AND    gic4.item_id            = iimb2.item_id
      AND    gic4.category_set_id    = cn_item_class_id
      AND    gic4.category_id        = mcb4.category_id
      AND    wdd.delivery_detail_id  = itp.line_detail_id
      AND    wdd.source_header_id    = xoha.header_id
      AND    wdd.source_line_id      = xola.line_id
      AND    xola.order_header_id    = xoha.order_header_id
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    ((otta.attribute4           <> '2')
             OR  (otta.attribute4       IS NULL))
      AND    otta.attribute1         = '1'
      AND    xoha.header_id          = ooha.header_id
      AND    xrpm.doc_type           = itp.doc_type
      AND    xrpm.dealings_div       = '113'
      AND    xrpm.shipment_provision_div = DECODE(xoha.req_status,'04','1','08','2')
      AND    xrpm.item_div_ahead     = mcb4.segment1
      AND    mcb2.segment1           <> '5'
      AND    xrpm.break_col_01       IS NOT NULL
-- 2009/03/05 v1.31 ADD START
      AND    iwm.whse_code           = itp.whse_code
      AND    iwm.attribute1          = '0'
-- 2009/03/05 v1.31 ADD END
      UNION ALL
      SELECT /*+ leading (xoha ooha otta xola wdd itp gic1 mcb1 gic2 mcb2) use_nl (xoha ooha otta xola wdd itp gic1 mcb1 gic2 mcb2) */
             NULL                                 h_whse_code
            ,NULL                                 h_whse_name
            ,itp.trans_id                         trans_id
            ,iimb.attribute15                     cost_mng_clss
            ,iimb.lot_ctl                         lot_ctl
            ,xlc.unit_ploce                       actual_unit_price
            ,CASE WHEN INSTR(xrpm.break_col_01,gv_hifn) = 0
                       THEN ''
                  WHEN xrpm.rcv_pay_div = gc_rcv_pay_div_in
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN SUBSTR(xrpm.break_col_01,1,INSTR(xrpm.break_col_01,gv_hifn) -1)
                  ELSE SUBSTR(xrpm.break_col_01,INSTR(xrpm.break_col_01,gv_hifn) +1)
             END                                  column_no
            ,itp.reason_code                      reason_code
            ,itp.trans_date                       trans_date
            ,TO_CHAR(itp.trans_date, 'YYYYMM')  trans_ym
            ,CASE WHEN xrpm.dealings_div_name = gv_dealings_name_po
                       THEN TO_CHAR(ABS(TO_NUMBER(xrpm.rcv_pay_div)))
                  ELSE xrpm.rcv_pay_div
             END                                  rcv_pay_div
            ,xrpm.dealings_div                    dealings_div
            ,itp.doc_type                         doc_type
            ,ir_param.item_class                  item_div
            ,ir_param.goods_class                 prod_div
            ,mcb3.segment1                        crowd_code
            ,SUBSTR(mcb3.segment1, 1, 3)          crowd_low
            ,SUBSTR(mcb3.segment1, 1, 2)          crowd_mid
            ,SUBSTR(mcb3.segment1, 1, 1)          crowd_high
            ,itp.item_id                          item_id
            ,itp.lot_id                           lot_id
            ,NVL(itp.trans_qty, 0)                trans_qty
            ,xoha.arrival_date                    arrival_date
            ,TO_CHAR(xoha.arrival_date, gc_char_ym_format) arrival_ym
            ,iimb.item_no                         item_code
            ,ximb.item_short_name                 item_name
      FROM   ic_tran_pnd                      itp
            ,wsh_delivery_details             wdd
            ,oe_order_headers_all             ooha
            ,oe_transaction_types_all         otta
            ,xxwsh_order_headers_all          xoha
            ,xxwsh_order_lines_all            xola
            ,ic_item_mst_b                    iimb
            ,xxcmn_item_mst_b                 ximb
            ,ic_lots_mst                      ilm
            ,xxcmn_lot_cost                   xlc
            ,gmi_item_categories              gic1
            ,mtl_categories_b                 mcb1
            ,gmi_item_categories              gic2
            ,mtl_categories_b                 mcb2
            ,gmi_item_categories              gic3
            ,mtl_categories_b                 mcb3
            ,xxcmn_rcv_pay_mst                xrpm
-- 2009/03/05 v1.31 ADD START
            ,ic_whse_mst                      iwm
-- 2009/03/05 v1.31 ADD END
      WHERE  itp.doc_type            = gv_doc_type_omso
      AND    itp.completed_ind       = 1
      AND    xoha.latest_external_flag = 'Y'
      AND    xoha.arrival_date > FND_DATE.STRING_TO_DATE(gd_prv2_dt_chr,gc_char_dt_format)
      AND    xoha.arrival_date < FND_DATE.STRING_TO_DATE(gd_flw_dt_chr,gc_char_dt_format)
      AND    ilm.item_id             = itp.item_id
      AND    ilm.lot_id              = itp.lot_id
      AND    iimb.item_id            = itp.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(itp.trans_date)
      AND    ximb.end_date_active   >= TRUNC(itp.trans_date)
      AND    gic1.item_id            = itp.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = itp.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    gic3.item_id            = itp.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
      AND    wdd.delivery_detail_id  = itp.line_detail_id
      AND    wdd.source_header_id    = xoha.header_id
      AND    wdd.source_line_id      = xola.line_id
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    otta.attribute4         = '2'
      AND    xoha.header_id          = ooha.header_id
      AND    xola.order_header_id    = xoha.order_header_id
      AND    xrpm.doc_type           = itp.doc_type
      AND    xrpm.dealings_div       IN ('504','509')
      AND    xrpm.stock_adjustment_div = otta.attribute4
      AND    xrpm.ship_prov_rcv_pay_category = otta.attribute11
      AND    xrpm.break_col_01       IS NOT NULL
-- 2009/03/05 v1.31 ADD START
      AND    iwm.whse_code           = itp.whse_code
      AND    iwm.attribute1          = '0'
-- 2009/03/05 v1.31 ADD END
      -- 当月受払無しデータ
      UNION ALL
      SELECT /*+ leading (xsims gic1 mcb1 gic2 mcb2 gic3 mcb3 iimb ximb xlc) use_nl (xsims gic1 mcb1 gic2 mcb2 gic3 mcb3 iimb ximb xlc) */
             NULL                                 h_whse_code
            ,NULL                                 h_whse_name
            ,NULL                                 trans_id
            ,iimb.attribute15                     cost_mng_clss
            ,iimb.lot_ctl                         lot_ctl
            ,xlc.unit_ploce                       actual_unit_price
            ,'1'                                  column_no
            ,NULL                                 reason_code
            ,gd_s_date                            trans_date
            ,TO_CHAR(gd_s_date, gc_char_ym_format)  trans_ym
            ,'1'                                  rcv_pay_div
            ,NULL                                 dealings_div
            ,NULL                                 doc_type
            ,ir_param.item_class                  item_div
            ,ir_param.goods_class                 prod_div
            ,mcb3.segment1                        crowd_code
            ,SUBSTR(mcb3.segment1, 1, 3)          crowd_low
            ,SUBSTR(mcb3.segment1, 1, 2)          crowd_mid
            ,SUBSTR(mcb3.segment1, 1, 1)          crowd_high
            ,iimb.item_id                         item_id
            ,0                                    lot_id
            ,0                                    trans_qty
            ,gd_s_date                            arrival_date
            ,TO_CHAR(gd_s_date, gc_char_ym_format)  arrival_ym
            ,iimb.item_no                         item_code
            ,ximb.item_short_name                 item_name
      FROM   xxinv_stc_inventory_month_stck   xsims
            ,ic_item_mst_b                    iimb
            ,xxcmn_item_mst_b                 ximb
            ,ic_lots_mst                      ilm
            ,xxcmn_lot_cost                   xlc
            ,gmi_item_categories              gic1
            ,mtl_categories_b                 mcb1
            ,gmi_item_categories              gic2
            ,mtl_categories_b                 mcb2
            ,gmi_item_categories              gic3
            ,mtl_categories_b                 mcb3
-- 2008/12/10 v1.25 ADD START
            ,ic_whse_mst                      iwm
-- 2008/12/10 v1.25 ADD END
      WHERE  xsims.item_id           = iimb.item_id
      AND    ximb.item_id            = iimb.item_id
      AND    ilm.item_id             = xsims.item_id
      AND    ilm.lot_id              = xsims.lot_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.start_date_active <= gd_s_date
      AND    ximb.end_date_active   >= gd_s_date
      AND    gic1.item_id            = xsims.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = xsims.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    gic3.item_id            = xsims.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
      AND    xsims.invent_ym         = TO_CHAR(gd_s_date, gc_char_ym_format)
-- 2008/12/10 v1.25 UPDATE START
--      AND    xsims.monthly_stock    <> 0
      AND    (
               (xsims.monthly_stock <> 0)
               OR
               (xsims.cargo_stock   <> 0)
             )
      AND    iwm.whse_code           = xsims.whse_code
      AND    iwm.attribute1          = '0'
-- 2008/12/10 v1.25 UPDATE END
      ORDER BY crowd_code
              ,item_code
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
    --集計期間設定
  -- ir_param.exec_year_month := lv_f_date;
    gd_s_date :=  FND_DATE.STRING_TO_DATE(ir_param.exec_year_month || gv_fdy || ' ' || gc_e_time
                                           , gc_char_dt_format);
--
--    gd_s_date :=  FND_DATE.STRING_TO_DATE(ir_param.exec_year_month  , gc_char_ym_format);
    gd_e_date := LAST_DAY(gd_s_date) + 1;
    gd_e_date := TRUNC(gd_e_date);
    --月首在庫数量を取得する為、前月データまで対象とする。
    gd_s_date :=  ADD_MONTHS(gd_s_date, -1);

    --前々月の末日
    gd_prv2_last_date  :=  LAST_DAY(ADD_MONTHS(gd_s_date, -1));
    gd_prv2_dt_chr :=  TO_CHAR(gd_prv2_last_date, gc_char_dt_format);
--
    --前月の末日
    gd_prv1_last_date  :=  LAST_DAY(gd_s_date);
    gd_prv1_dt_chr :=  TO_CHAR(gd_prv1_last_date, gc_char_dt_format);
--
    --翌月の月初日
    gd_follow_date :=  gd_e_date;
    gd_flw_dt_chr :=  TO_CHAR(gd_follow_date, gc_char_dt_format);
--
-- 2008/10/20 v1.10 UPDATE START
/*
    -- ----------------------------------------------------
    -- ＳＥＬＥＣＴ句生成
    -- ----------------------------------------------------
--
    lv_select1 := '  SELECT';
    --倉庫別を選択した場合は倉庫コードを取得する。
    IF (ir_param.print_kind = gc_print_type1) THEN
      lv_select1 := lv_select1
              || ' iwm.whse_code            h_whse_code'            -- ヘッダ：倉庫コード
              || ',iwm.whse_name            h_whse_name'            -- ヘッダ：倉庫名称
              ;
    ELSE
      lv_select1 := lv_select1
              || ' NULL                     h_whse_code'            -- ヘッダ：倉庫コード
              || ',NULL                     h_whse_name'            -- ヘッダ：倉庫名称
              ;
    END IF;
    lv_select1 := lv_select1
              || ',trn.trans_id            trans_id'           --TRANS_ID
              || ',xleiv.item_attribute15   cost_mng_clss'     -- 原価管理区分
              || ',xleiv.lot_ctl            lot_ctl'           -- ロット管理
              || ',xleiv.actual_unit_price  actual_unit_price' -- 実際単価
              || ',CASE WHEN INSTR(xlvv.attribute1,''' || gv_hifn || ''') = 0'
              || '           THEN '''''
              || '      WHEN xrpmxv.rcv_pay_div = ' || gc_rcv_pay_div_in
              || '           THEN SUBSTR(xlvv.attribute1,1,'
              || '                INSTR(xlvv.attribute1,''' || gv_hifn || ''') -1)'
              || '      WHEN xrpmxv.dealings_div_name = ''' || gv_dealings_name_po || ''''
              || '           THEN SUBSTR(xlvv.attribute1,1,'
              || '                INSTR(xlvv.attribute1,''' || gv_hifn || ''') -1)'
              || '      ELSE'
              || '                SUBSTR(xlvv.attribute1,INSTR(xlvv.attribute1,'''
              ||                                         gv_hifn || ''') +1)'
              || ' END  column_no'                                        -- 項目位置
              || ',trn.reason_code                     reason_code'       -- 事由コード
              || ',trn.trans_date                      trans_date'        -- 取引日
              || ',TO_CHAR(trn.trans_date, ''YYYYMM'') trans_ym'          -- 取引年月
              || ',CASE WHEN xrpmxv.dealings_div_name = ''' || gv_dealings_name_po || ''''
              || '           THEN TO_CHAR(ABS(TO_NUMBER(xrpmxv.rcv_pay_div))) '
              || '      ELSE'
              || '            xrpmxv.rcv_pay_div'
              || ' END  rcv_pay_div'                                      -- 受払区分
              || ',xrpmxv.dealings_div                 dealings_div'      -- 取引区分
              || ',trn.doc_type                        doc_type'          -- 文書タイプ
              || ',xleiv.item_div                      item_div'          -- 品目区分
              || ',xleiv.prod_div                      prod_div'          -- 商品区分
              ;
    IF (ir_param.crowd_kind = gc_grp_type3) THEN
      -- 群種別＝「3：郡別」が指定されている場合
      lv_select1 := lv_select1 || ',xleiv.crowd_code                crowd_code'       --群コード
                               || ',SUBSTR(xleiv.crowd_code, 1, 3)  crowd_low'        --小群
                               || ',SUBSTR(xleiv.crowd_code, 1, 2)  crowd_mid'        --中群
                               || ',SUBSTR(xleiv.crowd_code, 1, 1)  crowd_high'       --大群
                               ;
    ELSIF (ir_param.crowd_kind = gc_grp_type4) THEN
      -- 群種別＝「4：経理郡別」が指定されている場合
      lv_select1 := lv_select1 || ',xleiv.acnt_crowd_code  crowd_code'               --経理群コード
                               || ',SUBSTR(xleiv.acnt_crowd_code, 1, 3)  crowd_low'   --小群
                               || ',SUBSTR(xleiv.acnt_crowd_code, 1, 2)  crowd_mid'   --中群
                               || ',SUBSTR(xleiv.acnt_crowd_code, 1, 1)  crowd_high'  --大群
                               ;
    END IF;
--
    lv_select2 := ''
               || ',trn.item_id              item_id'                                   --品目ID
               || ',trn.lot_id               lot_id'                                    --ロットID
               || ',NVL(trn.trans_qty, 0)    trans_qty'                                 --取引数量
               || ',trn.trans_date           arrival_date'                              --着荷日
               || ',TO_CHAR(trn.trans_date, ''' || gc_char_ym_format || ''') arrival_ym'--着荷年月
               || ',xleiv.item_code          item_code'                                --品目コード
               || ',xleiv.item_short_name    item_name'                                 --品目名称
               ;
    -- ----------------------------------------------------
    -- ＦＲＯＭ句生成
    -- ----------------------------------------------------
--
    lv_from :=  ' FROM '
            || ' xxcmn_lot_each_item_v     xleiv'    -- ロット別品目情報
            || ',xxcmn_lookup_values2_v    xlvv'     -- クイックコード情報view2
            ;
    --倉庫別を選択した場合は倉庫マスタを結合する。
    IF (ir_param.print_kind = gc_print_type1) THEN
      lv_from :=  lv_from
              || ',ic_whse_mst               iwm'      -- OPM倉庫マスタ
              ;
    END IF;
--
    -- ----------------------------------------------------
    -- ＷＨＥＲＥ句生成
    -- ----------------------------------------------------
    lv_where := ' WHERE '
             || ' ((xleiv.start_date_active IS NULL)'
             || '  OR (xleiv.start_date_active IS NOT NULL AND xleiv.start_date_active <= '
             || '          TRUNC(trn.trans_date)))'
             || ' AND ((xleiv.end_date_active IS NULL)'
             || '      OR (xleiv.end_date_active IS NOT NULL AND xleiv.end_date_active >= '
             || '          TRUNC(trn.trans_date)))'
             || ' AND xleiv.item_id    = trn.item_id'
             || ' AND xleiv.lot_id     = trn.lot_id'
             || ' AND xleiv.prod_div   = ''' || ir_param.goods_class || ''''
             || ' AND xleiv.item_div   = ''' || ir_param.item_class  || ''''
             || ' AND xlvv.attribute1 IS NOT NULL'
             ;
    ---------------------------------------------------------------------------------------------
    --  ルックアップ（対象帳票）
    lv_where :=  lv_where
      || ' AND xlvv.lookup_type       = ''' || gc_lookup_type_print_flg || ''''
      || ' AND xrpmxv.dealings_div    = xlvv.meaning'
      || ' AND xlvv.enabled_flag      = ''Y'''
      || ' AND (xlvv.start_date_active IS NULL OR'
      || ' xlvv.start_date_active  <= TRUNC(trn.trans_date))'
      || ' AND (xlvv.end_date_active   IS NULL OR'
      || ' xlvv.end_date_active    >= TRUNC(trn.trans_date))'
      ;
    ---------------------------------------------------------------------------------------------
    -- 帳票種別＝１：倉庫別・品目別の場合
    IF (ir_param.print_kind = gc_print_type1) THEN
      lv_where := lv_where
               || ' AND iwm.whse_code  = trn.whse_code'
               ;
      -- 倉庫コードが指定されている場合
      IF (ir_param.locat_code  IS NOT NULL) THEN
        lv_where := lv_where
                 || ' AND iwm.whse_code = ''' || ir_param.locat_code || ''''
                 ;
      END IF;
    END IF;
    ---------------------------------------------------------------------------------------------
    -- 群種別＝「3：郡別」が指定されている場合
    IF (ir_param.crowd_kind = gc_grp_type3) THEN
      -- 群コードが入力されている場合
      IF (ir_param.crowd_code  IS NOT NULL) THEN
        lv_where := lv_where
                 || ' AND xleiv.crowd_code  = ''' || ir_param.crowd_code || ''''
                 ;
      END IF;
    END IF;
    ---------------------------------------------------------------------------------------------
    -- 群種別＝「4：経理郡別」が指定されている場合
    IF (ir_param.crowd_kind = gc_grp_type4) THEN
      -- 経理群コードが入力されている場合
       IF (ir_param.acnt_crowd_code  IS NOT NULL) THEN
        lv_where := lv_where
                 || ' AND xleiv.acnt_crowd_code  = ''' || ir_param.acnt_crowd_code || ''''
                 ;
      END IF;
    END IF;
--
    -- ----------------------------------------------------
    -- SQL生成( XFER :経理受払区分情報ＶＩＷ移動積送あり）
    -- ----------------------------------------------------
    lv_from_xfer := ''
      || ',ic_tran_pnd               trn'      -- 保留在庫トラン
      || ',xxcmn_rcv_pay_mst_xfer_v  xrpmxv'   -- 受払VIW
      || ',ic_xfer_mst               ixm'      -- ＯＰＭ在庫転送マスタ
      || ',xxinv_mov_req_instr_lines xmril'    -- 移動依頼／指示明細（アドオン）
       ;
--
    lv_where_xfer :=  ''
      || ' AND trn.trans_date > FND_DATE.STRING_TO_DATE(''' || gd_prv1_dt_chr    || ''',  '''
      ||                                                       gc_char_dt_format || ''')'--取引日
      || ' AND trn.trans_date < FND_DATE.STRING_TO_DATE(''' || gd_flw_dt_chr     || ''',  '''
      ||                                                       gc_char_dt_format || ''')'
      || ' AND trn.doc_type            = ''' || gv_doc_type_xfer    || '''' --文書タイプ
      || ' AND trn.reason_code         = ''' || gv_reason_code_xfer || '''' --事由コード
      || ' AND trn.completed_ind       = 1'                                 --完了区分
      || ' AND trn.doc_type            = xrpmxv.doc_type'                   --文書タイプ
      || ' AND trn.reason_code         = xrpmxv.reason_code'                --事由コード
      || ' AND xrpmxv.rcv_pay_div      = CASE WHEN trn.trans_qty >= 0 THEN 1 ELSE -1 END'
      || ' AND trn.doc_id              = ixm.transfer_id'
      || ' AND ixm.attribute1          = xmril.mov_line_id'
       ;
    -- ＳＱＬ生成(XFER)
    lv_sql_xfer := lv_select1 || lv_select2 || lv_from || lv_from_xfer
                || lv_where || lv_where_xfer;
--
    -- ----------------------------------------------------
    -- SQL生成( TRNI :経理受払区分情報ＶＩＷ移動積送なし）
    -- ----------------------------------------------------
    lv_from_trni := ''
      || ',ic_tran_cmp               trn'      -- 保留在庫トラン
      || ',xxcmn_rcv_pay_mst_trni_v  xrpmxv'   --  受払VIW
      || ',ic_adjs_jnl               iaj'      -- ＯＰＭ在庫調整ジャーナル
      || ',ic_jrnl_mst               ijm'      -- ＯＰＭジャーナルマスタ
      || ',xxinv_mov_req_instr_lines xmril'    -- 移動依頼／指示明細（アドオン）
       ;
--
    lv_where_trni :=  ''
      || ' AND trn.trans_date > FND_DATE.STRING_TO_DATE(''' || gd_prv1_dt_chr    || ''',  '''
      ||                                                       gc_char_dt_format || ''')'--取引日
      || ' AND trn.trans_date < FND_DATE.STRING_TO_DATE(''' || gd_flw_dt_chr     || ''',  '''
      ||                                                       gc_char_dt_format || ''')'
      || ' AND trn.doc_type            = ''' || gv_doc_type_trni    || '''' --文書タイプ
      || ' AND trn.reason_code         = ''' || gv_reason_code_trni || '''' --事由コード
      || ' AND trn.doc_type            = xrpmxv.doc_type'                   --文書タイプ
      || ' AND trn.line_type           = xrpmxv.rcv_pay_div'                --ラインタイプ
      || ' AND trn.reason_code         = xrpmxv.reason_code'                --事由コード
      || ' AND xrpmxv.rcv_pay_div      = CASE WHEN trn.trans_qty >= 0 THEN 1 ELSE -1 END'
      || ' AND trn.doc_type            = iaj.trans_type'
      || ' AND trn.doc_id              = iaj.doc_id'
      || ' AND trn.doc_line            = iaj.doc_line'
      || ' AND iaj.journal_id          = ijm.journal_id'
      || ' AND ijm.attribute1          = xmril.mov_line_id'
       ;
    -- ＳＱＬ生成(TRNI)
    lv_sql_trni := lv_select1 || lv_select2 || lv_from || lv_from_trni
                || lv_where || lv_where_trni;
--
    -- ----------------------------------------------------
    -- SQL生成(1. ADJI :経理受払区分情報ＶＩＷ在庫調整(他)
    -- ----------------------------------------------------
    lv_from_adji := ''
      || ',ic_tran_cmp               trn'      -- 完了在庫トラン
      || ',xxcmn_rcv_pay_mst_adji_v  xrpmxv'   --  受払VIW
       ;
--
    lv_where_adji :=  ''
      || ' AND trn.trans_date > FND_DATE.STRING_TO_DATE(''' || gd_prv1_dt_chr    || ''',  '''
      ||                                                       gc_char_dt_format || ''')'--取引日
      || ' AND trn.trans_date < FND_DATE.STRING_TO_DATE(''' || gd_flw_dt_chr     || ''',  '''
      ||                                                       gc_char_dt_format || ''')'
      || ' AND trn.doc_type            = ''' || gv_doc_type_adji    || '''' --文書タイプ
      || ' AND trn.doc_type            = xrpmxv.doc_type'                   --文書タイプ
      || ' AND trn.reason_code         = xrpmxv.reason_code'                --事由コード
      || ' AND trn.reason_code        <> ''' || gv_reason_code_adji_po   || ''''
      || ' AND trn.reason_code        <> ''' || gv_reason_code_adji_hama || ''''
      || ' AND trn.reason_code        <> ''' || gv_reason_code_adji_move || ''''
      || ' AND trn.reason_code        <> ''' || gv_reason_code_adji_othr || ''''
      || ' AND trn.reason_code        <> ''' || gv_reason_code_adji_itm  || ''''
      || ' AND trn.reason_code        <> ''' || gv_reason_code_adji_snt  || ''''
       ;
    -- ＳＱＬ生成(adji)他
    lv_sql_adji := lv_select1 || lv_select2 || lv_from || lv_from_adji
                || lv_where || lv_where_adji;
--
    -- ------------------------------------------------------
    -- SQL生成(2. ADJI :経理受払区分情報ＶＩＷ在庫調整(仕入)-
    -- ------------------------------------------------------
--
    lv_from_adji_po := ''
      || ',ic_tran_cmp               trn'      -- 完了在庫トラン
      || ',xxcmn_rcv_pay_mst_adji_v  xrpmxv'   --  受払VIW
      || ',ic_adjs_jnl               iaj'      -- OPM在庫調整ジャーナル
      || ',ic_jrnl_mst               ijm'      -- OPMジャーナルマスタ
      || ',xxpo_rcv_and_rtn_txns     xrrt'     -- 受入返品実績アドオン
       ;
--
    lv_where_adji_po :=  ''
      || ' AND trn.trans_date > FND_DATE.STRING_TO_DATE(''' || gd_prv1_dt_chr    || ''',  '''
      ||                                                       gc_char_dt_format || ''')'--取引日
      || ' AND trn.trans_date < FND_DATE.STRING_TO_DATE(''' || gd_flw_dt_chr     || ''',  '''
      ||                                                       gc_char_dt_format || ''')'
      || ' AND trn.doc_type            = ''' || gv_doc_type_adji    || '''' --文書タイプ
      || ' AND trn.doc_type            = xrpmxv.doc_type'                   --文書タイプ
      || ' AND trn.reason_code         = xrpmxv.reason_code'                --事由コード
      || ' AND trn.reason_code         = ''' || gv_reason_code_adji_po || ''''
      || ' AND iaj.trans_type          = trn.doc_type'
      || ' AND iaj.doc_id              = trn.doc_id'
      || ' AND iaj.doc_line            = trn.doc_line'
      || ' AND ijm.journal_id          = iaj.journal_id'
      || ' AND xrrt.txns_id            = ijm.attribute1'
       ;
    -- ＳＱＬ生成(adji)仕入
    lv_sql_adji_po := lv_select1 || lv_select2 || lv_from || lv_from_adji_po
                   || lv_where || lv_where_adji_po;
--
    -- ----------------------------------------------------
    -- SQL生成(3. ADJI :経理受払区分情報ＶＩＷ在庫調整(浜岡)
    -- ----------------------------------------------------
    lv_from_adji_hm := ''
      || ',ic_tran_cmp               trn'      -- 完了在庫トラン
      || ',xxcmn_rcv_pay_mst_adji_v  xrpmxv'   --  受払VIW
      || ',ic_adjs_jnl               iaj'      -- OPM在庫調整ジャーナル
      || ',ic_jrnl_mst               ijm'      -- OPMジャーナルマスタ
      || ',xxpo_namaha_prod_txns     xnpt'     -- 精算実績アドオン
       ;
--
    lv_where_adji_hm :=  ''
      || ' AND trn.trans_date > FND_DATE.STRING_TO_DATE(''' || gd_prv1_dt_chr    || ''',  '''
      ||                                                       gc_char_dt_format || ''')'--取引日
      || ' AND trn.trans_date < FND_DATE.STRING_TO_DATE(''' || gd_flw_dt_chr     || ''',  '''
      ||                                                       gc_char_dt_format || ''')'
      || ' AND trn.doc_type            = ''' || gv_doc_type_adji    || '''' --文書タイプ
      || ' AND trn.doc_type            = xrpmxv.doc_type'                   --文書タイプ
      || ' AND trn.reason_code         = xrpmxv.reason_code'                --事由コード
      || ' AND trn.reason_code         = ''' || gv_reason_code_adji_hama || ''''
      || ' AND iaj.trans_type          = trn.doc_type'
      || ' AND iaj.doc_id              = trn.doc_id'
      || ' AND iaj.doc_line            = trn.doc_line'
      || ' AND ijm.journal_id          = iaj.journal_id'
      || ' AND xnpt.entry_number       = ijm.attribute1'
       ;
    -- ＳＱＬ生成(adji)仕入
    lv_sql_adji_hm := lv_select1 || lv_select2 || lv_from || lv_from_adji_hm
                   || lv_where || lv_where_adji_hm;
--
    -- ----------------------------------------------------
    -- SQL生成(4. ADJI :経理受払区分情報ＶＩＷ在庫調整(移動)
    -- ----------------------------------------------------
    lv_from_adji_mv := ''
      || ',ic_tran_cmp               trn'      -- 完了在庫トラン
      || ',xxcmn_rcv_pay_mst_adji_v  xrpmxv'   --  受払VIW
      || ',ic_adjs_jnl               iaj'      -- OPM在庫調整ジャーナル
      || ',ic_jrnl_mst               ijm'      -- OPMジャーナルマスタ
      || ',xxpo_vendor_supply_txns   xvst'     -- 外注出来高実績
       ;
--
    lv_where_adji_mv :=  ''
      || ' AND trn.trans_date > FND_DATE.STRING_TO_DATE(''' || gd_prv1_dt_chr    || ''',  '''
      ||                                                       gc_char_dt_format || ''')'--取引日
      || ' AND trn.trans_date < FND_DATE.STRING_TO_DATE(''' || gd_flw_dt_chr     || ''',  '''
      ||                                                       gc_char_dt_format || ''')'
      || ' AND trn.doc_type            = ''' || gv_doc_type_adji    || '''' --文書タイプ
      || ' AND trn.doc_type            = xrpmxv.doc_type'                   --文書タイプ
      || ' AND trn.reason_code         = xrpmxv.reason_code'                --事由コード
      || ' AND trn.reason_code         = ''' || gv_reason_code_adji_move || ''''
      || ' AND xrpmxv.rcv_pay_div      = CASE WHEN trn.trans_qty >= 0 THEN 1 ELSE -1 END'
      || ' AND iaj.trans_type          = trn.doc_type'
      || ' AND iaj.doc_id              = trn.doc_id'
      || ' AND iaj.doc_line            = trn.doc_line'
      || ' AND ijm.journal_id          = iaj.journal_id'
      || ' AND xvst.txns_id            = ijm.attribute1'
       ;
    -- ＳＱＬ生成(adji)
    lv_sql_adji_mv := lv_select1 || lv_select2 || lv_from || lv_from_adji_mv
                   || lv_where || lv_where_adji_mv;
--
    -- ----------------------------------------------------
    -- SQL生成(5. ADJI :経理受払区分情報ＶＩＷ在庫調整(その他払出)
    -- ----------------------------------------------------
    lv_from_adji_snt := ''
      || ',ic_tran_cmp               trn'      -- 完了在庫トラン
      || ',xxcmn_rcv_pay_mst_adji_v  xrpmxv'   --  受払VIW
       ;
--
    lv_where_adji_snt :=  ''
      || ' AND trn.trans_date > FND_DATE.STRING_TO_DATE(''' || gd_prv1_dt_chr    || ''',  '''
      ||                                                       gc_char_dt_format || ''')'--取引日
      || ' AND trn.trans_date < FND_DATE.STRING_TO_DATE(''' || gd_flw_dt_chr     || ''',  '''
      ||                                                       gc_char_dt_format || ''')'
      || ' AND trn.doc_type            = ''' || gv_doc_type_adji    || '''' --文書タイプ
      || ' AND trn.doc_type            = xrpmxv.doc_type'                   --文書タイプ
      || ' AND trn.reason_code         = xrpmxv.reason_code'                --事由コード
      || ' AND ((trn.reason_code       = ''' || gv_reason_code_adji_itm || ''')'
      || '  OR  (trn.reason_code       = ''' || gv_reason_code_adji_snt || '''))'
      || ' AND xrpmxv.rcv_pay_div      = CASE WHEN trn.trans_qty >= 0 THEN 1 ELSE -1 END'
       ;
    -- ＳＱＬ生成(adji)
    lv_sql_adji_snt := lv_select1 || lv_select2 || lv_from || lv_from_adji_snt
                    || lv_where || lv_where_adji_snt;
--
    -- ----------------------------------------------------
    -- SQL生成( PROD :経理受払区分情報ＶＩＷ生産関連（Reverse_idなし）品種・品目振替なし
    -- ----------------------------------------------------
    lv_from_prod := ''
      || ',ic_tran_pnd               trn'      -- 保留在庫トラン
      || ',xxcmn_rcv_pay_mst_prod_v  xrpmxv'   --  受払VIW
      || ',xxcmn_lookup_values2_v    xlvv2'    -- クイックコード情報view2
       ;
--
    lv_where_prod :=  ''
      || ' AND trn.trans_date > FND_DATE.STRING_TO_DATE(''' || gd_prv1_dt_chr    || ''',  '''
      ||                                                       gc_char_dt_format || ''')'--取引日
      || ' AND trn.trans_date < FND_DATE.STRING_TO_DATE(''' || gd_flw_dt_chr     || ''',  '''
      ||                                                       gc_char_dt_format || ''')'
      || ' AND xleiv.prod_div          = ''' || ir_param.goods_class || ''''
      || ' AND xleiv.item_div          = ''' || ir_param.item_class || ''''
      || ' AND trn.doc_type            = ''' || gv_doc_type_prod    || '''' --文書タイプ
      || ' AND trn.completed_ind       = 1'                                 --完了区分
      || ' AND trn.reverse_id          IS NULL'
      || ' AND trn.doc_type            = xrpmxv.doc_type'                   --文書タイプ
      || ' AND trn.line_type           = xrpmxv.line_type'                  --ラインタイプ
      || ' AND trn.doc_id              = xrpmxv.doc_id'                     --バッチID
      || ' AND trn.doc_line            = xrpmxv.doc_line'                   --
      || ' AND trn.line_type           = xrpmxv.gmd_line_type'              --
      || ' AND xlvv2.meaning          <> ''' || gv_dealings_div_prod1 || ''''   -- 品種振替
      || ' AND xlvv2.meaning          <> ''' || gv_dealings_div_prod2 || ''''   -- 品目振替
      || ' AND xlvv2.lookup_type       = ''' || gc_lookup_type_dealing_div || ''''
      || ' AND xrpmxv.dealings_div     = xlvv2.lookup_code'
      || ' AND xlvv2.enabled_flag      = ''Y'''
      || ' AND (xlvv2.start_date_active IS NULL OR'
      || ' xlvv2.start_date_active    <= TRUNC(trn.trans_date))'
      || ' AND (xlvv2.end_date_active   IS NULL OR'
      || ' xlvv2.end_date_active      >= TRUNC(trn.trans_date))'
       ;
    -- ＳＱＬ生成(prod)Reverse_idなし
    lv_sql_prod := lv_select1 || lv_select2 || lv_from || lv_from_prod
                || lv_where || lv_where_prod;
--
    -- ----------------------------------------------------
    -- SQL生成(2.PROD :経理受払区分情報ＶＩＷ生産関連（Reverse_idなし）品種・品目振替
    -- ----------------------------------------------------
--
    lv_from_prod_i := ''
      || ',ic_tran_pnd               trn'      -- 保留在庫トラン
      || ',ic_tran_pnd               trn2'     -- 保留在庫トラン
      || ',xxcmn_rcv_pay_mst_prod_v  xrpmxv'   --  受払VIW
      || ',xxcmn_lot_each_item_v     xleiv2'   -- ロット別品目情報
      || ',xxcmn_lookup_values2_v    xlvv2'    -- クイックコード情報view2
       ;
--
    lv_where_prod_i :=  ''
      || ' AND trn.trans_date >  FND_DATE.STRING_TO_DATE(''' || gd_prv1_dt_chr   || ''',  '''
      ||                                                       gc_char_dt_format || ''')'--取引日
      || ' AND trn.trans_date <  FND_DATE.STRING_TO_DATE(''' || gd_flw_dt_chr    || ''',  '''
      ||                                                       gc_char_dt_format || ''')'
      || ' AND trn2.trans_date > FND_DATE.STRING_TO_DATE(''' || gd_prv1_dt_chr   || ''',  '''
      ||                                                       gc_char_dt_format || ''')'--取引日
      || ' AND trn2.trans_date < FND_DATE.STRING_TO_DATE(''' || gd_flw_dt_chr    || ''',  '''
      ||                                                       gc_char_dt_format || ''')'
      || ' AND ((xleiv2.start_date_active IS NULL)'
      || '      OR (xleiv2.start_date_active IS NOT NULL AND xleiv2.start_date_active <= '
      || '          TRUNC(trn2.trans_date)))'
      || ' AND ((xleiv2.end_date_active IS NULL)'
      || '      OR (xleiv2.end_date_active IS NOT NULL AND xleiv2.end_date_active >= '
      || '          TRUNC(trn2.trans_date)))'
      || ' AND trn.doc_type            = ''' || gv_doc_type_prod    || '''' --文書タイプ
      || ' AND trn.completed_ind       = 1'                                 --完了区分
      || ' AND trn.reverse_id          IS NULL'
      || ' AND trn.doc_type            = xrpmxv.doc_type'                   --文書タイプ
      || ' AND trn.line_type           = xrpmxv.line_type'                  --ラインタイプ
      || ' AND trn.doc_id              = xrpmxv.doc_id'                     --バッチID
      || ' AND trn.doc_line            = xrpmxv.doc_line'                   --
      || ' AND trn2.completed_ind      = 1'                                 --完了区分
      || ' AND trn2.reverse_id         IS NULL'
      || ' AND trn2.line_type       = CASE'
      || '                             WHEN trn.line_type = -1 THEN 1'
      || '                             WHEN trn.line_type = 1 THEN -1'
      || '                             END'
      || ' AND xlvv2.meaning IN (''' || gv_dealings_div_prod1 || ''','''
      ||                                gv_dealings_div_prod2 || ''')'       -- 品種振替,品目振替
      || ' AND xlvv2.lookup_type  = ''' || gc_lookup_type_dealing_div || ''''
      || ' AND xrpmxv.dealings_div         = xlvv2.lookup_code'
      || ' AND (xlvv2.START_DATE_ACTIVE IS NULL OR '
      || '      xlvv2.START_DATE_ACTIVE <= TRUNC(trn.trans_date))'
      || ' AND (xlvv2.END_DATE_ACTIVE   IS NULL OR '
      || '      xlvv2.END_DATE_ACTIVE   >= TRUNC(trn.trans_date))'
      || ' AND trn.doc_id              = trn2.doc_id'
      || ' AND trn.doc_line            = trn2.doc_line'
      || ' AND trn2.item_id            = xleiv2.item_id'
      || ' AND trn2.lot_id             = xleiv2.lot_id'
      || ' AND xleiv.item_div = CASE'
      || '                          WHEN trn.line_type = -1 THEN xrpmxv.item_div_origin'
      || '                          WHEN trn.line_type = 1  THEN xrpmxv.item_div_ahead'
      || '                       END'
      || ' AND xleiv2.item_div = CASE'
      || '                          WHEN trn.line_type = 1 THEN xrpmxv.item_div_origin'
      || '                          WHEN trn.line_type = -1 THEN xrpmxv.item_div_ahead'
      || '                       END'
      || ' AND xrpmxv.item_id  = trn.item_id'
       ;
    -- ＳＱＬ生成(prod)Reverse_idなし：品種・品目振替
    lv_sql_prod_i := lv_select1 || lv_select2 || lv_from || lv_from_prod_i
                  || lv_where || lv_where_prod_i;
--
    -- ----------------------------------------------------
    -- SQL生成(1. PORC :経理受払区分情報ＶＩＷ購買関連    -
    -- ----------------------------------------------------
    lv_select_porc := ''
      || ',NVL( xrpmxv.item_id,trn.item_id)  item_id'  -- 品目ID
      || ',trn.lot_id               lot_id'            -- ロットID
-- 2008/08/22 v1.9 UPDATE START
--      || ',NVL2(xrpmxv.item_id,trn.trans_qty,'
--      || ' trn.trans_qty * TO_NUMBER(xrpmxv.rcv_pay_div)) trans_qty'-- 取引数量
      || ',trn.trans_qty   trans_qty'                               -- 取引数量
-- 2008/08/22 v1.9 UPDATE END
      || ',trn.trans_date  arrival_date'                            -- 着荷日
      || ',TO_CHAR(trn.trans_date, ''' || gc_char_ym_format || ''') arrival_ym'-- 着荷年月
      || ',xitem.item_no            item_code' -- 品目コード
      || ',xitem.item_short_name    item_name' -- 品目名称
      ;
--
    lv_from_porc := ''
      || ',ic_tran_pnd                     trn'      -- 保留在庫トラン
      || ',xxcmn_rcv_pay_mst_porc_rma01_v  xrpmxv'   -- 受払VIW（RMA）
      || ',xxcmn_item_mst2_v               xitem'    -- 品目マスタVIEW2
      ;
--
    lv_where_porc :=  ''
      || ' AND trn.trans_date > FND_DATE.STRING_TO_DATE(''' || gd_prv1_dt_chr    || ''',  '''
      ||                                                       gc_char_dt_format || ''')'--取引日
      || ' AND trn.trans_date < FND_DATE.STRING_TO_DATE(''' || gd_flw_dt_chr     || ''',  '''
      ||                                                       gc_char_dt_format || ''')'
      || ' AND trn.doc_type            = ''' || gv_doc_type_porc    || '''' --文書タイプ
      || ' AND trn.completed_ind       = 1'                                 --完了区分
      || ' AND trn.doc_type            = xrpmxv.doc_type'                   --文書タイプ
      || ' AND trn.doc_id              = xrpmxv.doc_id'                     --バッチID
      || ' AND trn.doc_line            = xrpmxv.doc_line'                   --明細ID
      || ' AND  xitem.item_id          = NVL(xrpmxv.item_id,trn.item_id)'
      || ' AND (XITEM.START_DATE_ACTIVE IS NULL OR '
      || '      XITEM.START_DATE_ACTIVE <= TRUNC(trn.trans_date))'
      || ' AND (XITEM.END_DATE_ACTIVE   IS NULL OR '
      || '      XITEM.END_DATE_ACTIVE  >= TRUNC(trn.trans_date))'
       ;
    -- ＳＱＬ生成(porc)
    lv_sql_porc := lv_select1 || lv_select_porc || lv_from || lv_from_porc
                || lv_where || lv_where_porc;
--
    -- ----------------------------------------------------
    -- SQL生成(2. PORC :経理受払区分情報ＶＩＷ購買関連（仕入）
    -- ----------------------------------------------------
    lv_from_porc_po := ''
      || ',ic_tran_pnd                  trn'      -- 保留在庫トラン
      || ',xxcmn_rcv_pay_mst_porc_po_v  xrpmxv'   --  受払VIW（PO）
       ;
--
    lv_where_porc_po :=  ''
      || ' AND trn.trans_date > FND_DATE.STRING_TO_DATE(''' || gd_prv1_dt_chr    || ''',  '''
      ||                                                       gc_char_dt_format || ''')'--取引日
      || ' AND trn.trans_date < FND_DATE.STRING_TO_DATE(''' || gd_flw_dt_chr     || ''',  '''
      ||                                                       gc_char_dt_format || ''')'
      || ' AND trn.doc_type            = ''' || gv_doc_type_porc    || '''' --文書タイプ
      || ' AND trn.completed_ind       = 1'                                 --完了区分
      || ' AND trn.doc_type            = xrpmxv.doc_type'                   --文書タイプ
      || ' AND trn.doc_id              = xrpmxv.doc_id'                     --バッチID
      || ' AND trn.doc_line            = xrpmxv.doc_line'                   --
      || ' AND trn.line_id             = xrpmxv.line_id'
       ;
    -- ＳＱＬ生成(porc)仕入
    lv_sql_porc_po := lv_select1 || lv_select2 || lv_from || lv_from_porc_po
                   || lv_where || lv_where_porc_po;
--
    -- ----------------------------------------------------
    -- SQL生成( OMSO :経理受払区分情報ＶＩＷ受注関連
    -- ----------------------------------------------------
    lv_select_omso := ''
      || ',NVL( xrpmxv.item_id,trn.item_id)  item_id'  -- 品目ID
      || ',trn.lot_id               lot_id'            -- ロットID
-- 2008/08/22 v1.9 UPDATE START
--      || ',NVL2(xrpmxv.item_id,trn.trans_qty,'
--      || ' trn.trans_qty * TO_NUMBER(xrpmxv.rcv_pay_div)) trans_qty'-- 取引数量
      || ',trn.trans_qty   trans_qty'                               -- 取引数量
-- 2008/08/22 v1.9 UPDATE END
      || ',xrpmxv.arrival_date           arrival_date' -- 着荷日
      || ',TO_CHAR(xrpmxv.arrival_date, '''
      || gc_char_ym_format || ''') arrival_ym'         -- 着荷年月
      || ',xitem.item_no            item_code'         -- 品目コード
      || ',xitem.item_short_name    item_name'         -- 品目名称
      ;
--
    lv_from_omsso := ''
      || ',ic_tran_pnd               trn'      -- 保留在庫トラン
      || ',xxcmn_rcv_pay_mst_omso_v  xrpmxv'   -- 受払VIW
      || ',xxcmn_item_mst2_v         xitem'    -- 品目マスタVIEW2
       ;
--
    lv_where_omsso :=  ''
      || ' AND trn.trans_date > FND_DATE.STRING_TO_DATE(''' || gd_prv2_dt_chr    || ''',  '''
      ||                                                       gc_char_dt_format || ''')'--取引日
      || ' AND trn.trans_date < FND_DATE.STRING_TO_DATE(''' || gd_flw_dt_chr     || ''',  '''
      ||                                                       gc_char_dt_format || ''')'
      || ' AND trn.doc_type         = ''' || gv_doc_type_omso    || '''' --文書タイプ
      || ' AND trn.completed_ind    = 1'                                 --完了区分
      || ' AND trn.doc_type         = xrpmxv.doc_type'                   --文書タイプ
      || ' AND trn.line_detail_id   = xrpmxv.doc_line'                   --
      || ' AND  xitem.item_id          = NVL(xrpmxv.item_id,trn.item_id)'
      || ' AND (XITEM.START_DATE_ACTIVE IS NULL OR '
      || '      XITEM.START_DATE_ACTIVE <= TRUNC(trn.trans_date))'
      || ' AND (XITEM.END_DATE_ACTIVE   IS NULL OR '
      || '      XITEM.END_DATE_ACTIVE  >= TRUNC(trn.trans_date))'
       ;
    -- ＳＱＬ生成(OMSO)
    lv_sql_omsso := lv_select1 || lv_select_omso || lv_from || lv_from_omsso
                 || lv_where || lv_where_omsso;
--
    -- ----------------------------------------------------
    -- ＯＲＤＥＲ  ＢＹ句生成
    -- ----------------------------------------------------
    -- 帳票種別＝１：倉庫別・品目別の場合
    IF (ir_param.print_kind = gc_print_type1) THEN
      lv_order_by := ' ORDER BY'
                  || ' h_whse_code'     -- ヘッダ：倉庫コード
                  || ',crowd_code'      -- 群コード
                  || ',item_code'       -- 品目コード
                  ;
    ELSE
      lv_order_by := ' ORDER BY'
                  || ' crowd_code'      -- 群コード
                  || ',item_code'       -- 品目コード
                  ;
    END IF;
--
    -- ====================================================
    -- ＳＱＬ生成
    -- ====================================================
    lv_sql := ''
      ||  lv_sql_xfer
      ||  ' UNION ALL '
      ||  lv_sql_trni
      ||  ' UNION ALL '
      ||  lv_sql_adji
      ||  ' UNION ALL '
      ||  lv_sql_adji_po
      ||  ' UNION ALL '
      ||  lv_sql_adji_hm
      ||  ' UNION ALL '
      ||  lv_sql_adji_mv
      ;
    lv_sql2 := ''
      ||  ' UNION ALL '
      ||  lv_sql_adji_snt
      ||  ' UNION ALL '
      ||  lv_sql_prod
      ||  ' UNION ALL '
      ||  lv_sql_prod_i
       ;
    lv_sql3 := ''
      ||  ' UNION ALL '
      ||  lv_sql_porc
      ||  ' UNION ALL '
      ||  lv_sql_porc_po
      ||  ' UNION ALL '
      ||  lv_sql_omsso
      ||  ' '
       ;
--
    -- ====================================================
    -- データ抽出
    -- ====================================================
    -- オープン
    OPEN lc_ref FOR lv_sql || lv_sql2 || lv_sql3 || lv_order_by;
    -- バルクフェッチ
    FETCH lc_ref BULK COLLECT INTO ot_data_rec;
    -- カーソルクローズ
    CLOSE lc_ref;
--
    IF (ir_param.print_kind = gc_print_type1) THEN
--
      -- 倉庫コードが指定されていない場合
      IF (ir_param.locat_code IS NULL) THEN
--
        -- 群種別＝「3：郡別」が指定されている場合
        IF (ir_param.crowd_kind = gc_grp_type3) THEN
          -- 群コードが入力されている場合
          IF (ir_param.crowd_code  IS NOT NULL) THEN
--
NULL;
--            OPEN  get_data_cur01;
--            FETCH get_data_cur01 BULK COLLECT INTO ot_data_rec;
--            CLOSE get_data_cur01;
--
          -- 群コードが入力されていない場合
          ELSE
--
            OPEN  get_data_cur02;
            FETCH get_data_cur02 BULK COLLECT INTO ot_data_rec;
            CLOSE get_data_cur02;
--
          END IF;
--
        END IF;
--
      -- 倉庫コードが指定されている場合
      ELSE
--
        -- 群種別＝「3：郡別」が指定されている場合
        IF (ir_param.crowd_kind = gc_grp_type3) THEN
          -- 群コードが入力されている場合
          IF (ir_param.crowd_code  IS NOT NULL) THEN
--
NULL;
--            OPEN  get_data_cur03;
--            FETCH get_data_cur03 BULK COLLECT INTO ot_data_rec;
--            CLOSE get_data_cur03;
--
          -- 群コードが入力されていない場合
          ELSE
--
NULL;
--            OPEN  get_data_cur04;
--            FETCH get_data_cur04 BULK COLLECT INTO ot_data_rec;
--            CLOSE get_data_cur04;
--
          END IF;
--
        END IF;
--
      END IF;
--
    END IF;
*/
    -- 帳票種別＝「1：倉庫・品目別」が指定されている場合
    IF (ir_param.print_kind = gc_print_type1) THEN
--
      -- 倉庫コードが指定されていない場合
      IF (ir_param.locat_code IS NULL) THEN
--
        -- 群種別＝「3：郡別」が指定されている場合
        IF (ir_param.crowd_kind = gc_grp_type3) THEN
-- 2008/11/10 v1.16 ADD START
--
          ln_crowd_code_id := cn_crowd_code_id;
          lt_crowd_code    := ir_param.crowd_code;
--
-- 2008/11/10 v1.16 ADD END
          -- 群コードが入力されている場合
          IF (ir_param.crowd_code  IS NOT NULL) THEN
--
            OPEN  get_data_cur01;
            FETCH get_data_cur01 BULK COLLECT INTO ot_data_rec;
            CLOSE get_data_cur01;
--
          -- 群コードが入力されていない場合
          ELSE
--
            OPEN  get_data_cur02;
            FETCH get_data_cur02 BULK COLLECT INTO ot_data_rec;
            CLOSE get_data_cur02;
--
          END IF;
--
        -- 群種別＝「4：経理郡別」が指定されている場合
        ELSIF (ir_param.crowd_kind = gc_grp_type4) THEN
-- 2008/11/10 v1.16 ADD START
--
          ln_crowd_code_id := cn_acnt_crowd_code_id;
          lt_crowd_code    := ir_param.acnt_crowd_code;
--
-- 2008/11/10 v1.16 ADD END
          -- 経理群コードが入力されている場合
          IF (ir_param.acnt_crowd_code  IS NOT NULL) THEN
--
-- 2008/11/10 v1.16 UPDATE START
--            OPEN  get_data_cur05;
--            FETCH get_data_cur05 BULK COLLECT INTO ot_data_rec;
--            CLOSE get_data_cur05;
            OPEN  get_data_cur01;
            FETCH get_data_cur01 BULK COLLECT INTO ot_data_rec;
            CLOSE get_data_cur01;
-- 2008/11/10 v1.16 UPDATE END
--
          -- 経理群コードが入力されていない場合
          ELSE
--
-- 2008/11/10 v1.16 UPDATE START
--            OPEN  get_data_cur10;
--            FETCH get_data_cur10 BULK COLLECT INTO ot_data_rec;
--            CLOSE get_data_cur10;
            OPEN  get_data_cur02;
            FETCH get_data_cur02 BULK COLLECT INTO ot_data_rec;
            CLOSE get_data_cur02;
-- 2008/11/10 v1.16 UPDATE END
--
          END IF;
--
        END IF;
--
      -- 倉庫コードが指定されている場合
      ELSE
--
        -- 群種別＝「3：郡別」が指定されている場合
        IF (ir_param.crowd_kind = gc_grp_type3) THEN
-- 2008/11/10 v1.16 ADD START
--
          ln_crowd_code_id := cn_crowd_code_id;
          lt_crowd_code    := ir_param.crowd_code;
--
-- 2008/11/10 v1.16 ADD END
          -- 群コードが入力されている場合
          IF (ir_param.crowd_code  IS NOT NULL) THEN
--
            OPEN  get_data_cur03;
            FETCH get_data_cur03 BULK COLLECT INTO ot_data_rec;
            CLOSE get_data_cur03;
--
          -- 群コードが入力されていない場合
          ELSE
--
            OPEN  get_data_cur04;
            FETCH get_data_cur04 BULK COLLECT INTO ot_data_rec;
            CLOSE get_data_cur04;
--
          END IF;
--
        -- 群種別＝「4：経理郡別」が指定されている場合
        ELSIF (ir_param.crowd_kind = gc_grp_type4) THEN
-- 2008/11/10 v1.16 ADD START
--
          ln_crowd_code_id := cn_acnt_crowd_code_id;
          lt_crowd_code    := ir_param.acnt_crowd_code;
--
-- 2008/11/10 v1.16 ADD END
          -- 経理群コードが入力されている場合
          IF (ir_param.acnt_crowd_code  IS NOT NULL) THEN
--
-- 2008/11/10 v1.16 UPDATE START
--            OPEN  get_data_cur06;
--            FETCH get_data_cur06 BULK COLLECT INTO ot_data_rec;
--            CLOSE get_data_cur06;
            OPEN  get_data_cur03;
            FETCH get_data_cur03 BULK COLLECT INTO ot_data_rec;
            CLOSE get_data_cur03;
-- 2008/11/10 v1.16 UPDATE END
--
          -- 経理群コードが入力されていない場合
          ELSE
--
-- 2008/11/10 v1.16 UPDATE START
--            OPEN  get_data_cur11;
--            FETCH get_data_cur11 BULK COLLECT INTO ot_data_rec;
--            CLOSE get_data_cur11;
            OPEN  get_data_cur04;
            FETCH get_data_cur04 BULK COLLECT INTO ot_data_rec;
            CLOSE get_data_cur04;
          END IF;
-- 2008/11/10 v1.16 UPDATE END
--
        END IF;
--
      END IF;
--
    -- 帳票種別＝「2：品目別」が指定されている場合
    ELSIF (ir_param.print_kind = gc_print_type2) THEN
--
      -- 群種別＝「3：郡別」が指定されている場合
      IF (ir_param.crowd_kind = gc_grp_type3) THEN
-- 2008/11/10 v1.16 ADD START
--
        ln_crowd_code_id := cn_crowd_code_id;
        lt_crowd_code    := ir_param.crowd_code;
--
-- 2008/11/10 v1.16 ADD END
        -- 群コードが入力されている場合
        IF (ir_param.crowd_code  IS NOT NULL) THEN
--
          OPEN  get_data_cur05;
          FETCH get_data_cur05 BULK COLLECT INTO ot_data_rec;
          CLOSE get_data_cur05;
--
        -- 群コードが入力されていない場合
        ELSE
--
          OPEN  get_data_cur06;
          FETCH get_data_cur06 BULK COLLECT INTO ot_data_rec;
          CLOSE get_data_cur06;
--
        END IF;
--
      -- 群種別＝「4：経理郡別」が指定されている場合
      ELSIF (ir_param.crowd_kind = gc_grp_type4) THEN
-- 2008/11/10 v1.16 ADD START
--
        ln_crowd_code_id := cn_acnt_crowd_code_id;
        lt_crowd_code    := ir_param.acnt_crowd_code;
--
-- 2008/11/10 v1.16 ADD END
        -- 経理群コードが入力されている場合
        IF (ir_param.acnt_crowd_code  IS NOT NULL) THEN
--
-- 2008/11/10 v1.16 UPDATE START
--          OPEN  get_data_cur09;
--          FETCH get_data_cur09 BULK COLLECT INTO ot_data_rec;
--          CLOSE get_data_cur09;
          OPEN  get_data_cur05;
          FETCH get_data_cur05 BULK COLLECT INTO ot_data_rec;
          CLOSE get_data_cur05;
-- 2008/11/10 v1.16 UPDATE END
--
        -- 経理群コードが入力されていない場合
        ELSE
--
-- 2008/11/10 v1.16 UPDATE START
--          OPEN  get_data_cur12;
--          FETCH get_data_cur12 BULK COLLECT INTO ot_data_rec;
--          CLOSE get_data_cur12;
          OPEN  get_data_cur06;
          FETCH get_data_cur06 BULK COLLECT INTO ot_data_rec;
          CLOSE get_data_cur06;
-- 2008/11/10 v1.16 UPDATE END
--
        END IF;
--
      END IF;
--
    END IF;
-- 2008/10/20 v1.10 UPDATE END
--
  EXCEPTION
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      IF (lc_ref%ISOPEN) THEN
        CLOSE lc_ref;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      IF (lc_ref%ISOPEN) THEN
        CLOSE lc_ref;
      END IF;
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      IF (lc_ref%ISOPEN) THEN
        CLOSE lc_ref;
      END IF;
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END prc_get_report_data;
--
  /**********************************************************************************
   * Procedure Name   : prc_create_xml_data
   * Description      : ＸＭＬデータ作成
   ***********************************************************************************/
  PROCEDURE prc_create_xml_data(
      ir_param          IN  rec_param_data    -- 01.レコード  ：パラメータ
     ,ov_errbuf         OUT VARCHAR2          --    エラー・メッセージ           --# 固定 #
     ,ov_retcode        OUT VARCHAR2          --    リターン・コード             --# 固定 #
     ,ov_errmsg         OUT VARCHAR2          --    ユーザー・エラー・メッセージ --# 固定 #
    )
  IS
--
    -- =====================================================
    -- 固定ローカル定数
    -- =====================================================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'prc_create_xml_data'; -- プログラム名
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
    -- *** ローカル定数 ***
    -- キーブレイク判断用
    lc_break_init           VARCHAR2(100) DEFAULT '*';            -- 初期値
    lc_break_null           VARCHAR2(100) DEFAULT '**';           -- ＮＵＬＬ判定
--
    -- *** ローカル変数 ***
    -- キーブレイク判断用
    lv_whse_code            VARCHAR2(30) DEFAULT lc_break_init;  -- 倉庫コード
    lv_crowd_high           VARCHAR2(30) DEFAULT lc_break_init;  -- 大群コード
    lv_crowd_mid            VARCHAR2(30) DEFAULT lc_break_init;  -- 中群コード
    lv_crowd_low            VARCHAR2(30) DEFAULT lc_break_init;  -- 小群コード
    lv_crowd_dtl            VARCHAR2(30) DEFAULT lc_break_init;  -- 群コード
    lv_item_code            VARCHAR2(30) DEFAULT lc_break_init;  -- 品目コード
--
-- 2008/11/17 v1.16 ADD START
    ln_cargo_qty            NUMBER;                              -- 積送中数量
    ln_cargo_amt            NUMBER;                              -- 積送中金額（実際単価)
--
-- 2008/11/17 v1.16 ADD END
    -- 計算用
    in_hifn_position        NUMBER       DEFAULT 0;              -- 計算用：ポジション
    ln_i                    NUMBER       DEFAULT 0;              -- カウンター用
    ln_price                NUMBER       DEFAULT 0;              -- 原価用
    in_hifn_pos             NUMBER       DEFAULT 0;              -- 列位置
    --戻り値
    lb_sts                  BOOLEAN       DEFAULT TRUE;
--
    -- *** ローカル・例外処理 ***
    no_data_expt            EXCEPTION;             -- 取得レコードなし
--
    -------------------------
    --1.品目明細クリア処理  -
    -------------------------
    PROCEDURE initialize
    IS
    BEGIN
      gn_fst_inv_qty  :=  0;--月首在庫数量
      gn_fst_inv_amt  :=  0;--月首在庫金額
      gn_lst_inv_qty  :=  0;--棚卸在庫数量
      gn_lst_inv_amt  :=  0;--棚卸在庫金額
      <<item_rec_clear>>
      FOR i IN 1 .. gc_print_pos_max LOOP
       qty(i) := 0;
       amt(i) := 0;
      END LOOP  item_rec_clear;
    END initialize;
    ----------------------
    --2.ＸＭＬ 1行出力   -
    ----------------------
    PROCEDURE prc_xml_add(
       iv_name    IN   VARCHAR2                 --   タグネーム
      ,ic_type    IN   CHAR                     --   タグタイプ
      ,iv_data    IN   VARCHAR2 DEFAULT NULL    --   データ
      ,iv_zero    IN   BOOLEAN  DEFAULT TRUE)   --   ゼロサプレス
    IS
    BEGIN
      gl_xml_idx := gt_xml_data_table.COUNT + 1;
      gt_xml_data_table(gl_xml_idx).tag_name  := iv_name;
      --データの場合
      IF (ic_type = 'D') THEN
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
        IF (iv_zero = TRUE) THEN
          gt_xml_data_table(gl_xml_idx).tag_value := NVL(iv_data, 0) ; --Nullの場合０表示
        ELSE
          gt_xml_data_table(gl_xml_idx).tag_value := iv_data ;         --Nullでもそのまま表示
        END IF;
      ELSE
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
      END IF;
    END prc_xml_add;
--
    ------------------------------------------------
    --3.在庫数取得(実際原価用) 戻り値：数量 ,金額 --
    ------------------------------------------------
    PROCEDURE prc_ac_inv_qty_get(
       ib_stock           IN   BOOLEAN  --TRUE:月首  FALSE:棚卸
      ,in_pos             IN   NUMBER   --品目レコード配列位置
      ,in_price           IN   NUMBER   --原価
      ,iv_exec_year_month IN   VARCHAR2 --処理年月
      ,on_inv_qty         OUT  NUMBER   --数量
      ,on_inv_amt         OUT  NUMBER)  --金額
    IS
--
      --在庫数戻り値
      on_inv_qty_tbl NUMBER DEFAULT 0;--在庫テーブルより
      --在庫金額戻り値
      on_inv_amt_tbl NUMBER DEFAULT 0;--在庫テーブルより
      --日付計算用
      ld_invent_date  DATE  DEFAULT FND_DATE.STRING_TO_DATE(
                                      iv_exec_year_month || gv_fdy, gc_char_d_format);
      --棚卸年月抽出用
      lv_invent_yyyymm  VARCHAR2(06)  DEFAULT NULL;
--
    BEGIN
-- 2008/11/17 v1.16 ADD START
      -- 変数の初期化
      ln_cargo_qty   :=  0;
      ln_cargo_amt   :=  0;
--
-- 2008/11/17 v1.16 ADD END
      -- 「月首」指定の場合は前月の年月を求めます。
      IF  (ib_stock  =  TRUE)  THEN
        ld_invent_date  :=  TRUNC(ld_invent_date, gv_month_edt) - 1;
        lv_invent_yyyymm  :=  TO_CHAR(ld_invent_date, gc_char_ym_format);
      ELSE
        lv_invent_yyyymm  := iv_exec_year_month;
      END IF;
--
      -- ===============================================================
      -- 棚卸月末在庫テーブルより「前月末在庫数」「金額」を取得します。=
      -- ===============================================================
      -- 倉庫別の場合は倉庫毎の棚卸を取得する。
      IF  (gt_body_data(in_pos).whse_code IS NOT NULL) THEN
-- 2008/12/03 v1.20 ADD START
       -- 月首在庫を求める場合
       IF  (ib_stock  =  TRUE)  THEN
        -- 月末在庫より数量を取得
-- 2008/12/03 v1.20 ADD END
        BEGIN
-- 2008/11/17 v 1.16 UPDATE START
/*
-- 2008/11/17 v1.16 UPDATE START
--          SELECT  SUM(stc.monthly_stock) AS stock
          SELECT  SUM(NVL(stc.monthly_stock, 0)) AS stock
-- 2008/10/20 v1.10 UPDATE START
--                 ,SUM(stc.monthly_stock * in_price) AS stock_amt
                 ,SUM(stc.monthly_stock * xlc.unit_ploce) AS stock_amt
-- 2008/10/20 v1.10 UPDATE END
-- 2008/11/17 v1.16 ADD END
          INTO   on_inv_qty_tbl
                ,on_inv_amt_tbl
          FROM   xxinv_stc_inventory_month_stck stc
-- 2008/10/20 v1.10 ADD START
                ,xxcmn_lot_cost         xlc
-- 2008/10/20 v1.10 ADD END
          WHERE  stc.whse_code    = gt_body_data(in_pos).whse_code
          AND  stc.item_id    = gt_body_data(in_pos).item_id
-- 2008/10/20 v1.10 UPDATE START
--          AND   stc.invent_ym = lv_invent_yyyymm;
          AND    stc.invent_ym  = lv_invent_yyyymm
          AND    stc.item_id    = xlc.item_id
          AND    stc.lot_id     = xlc.lot_id;
--
-- 2008/10/20 v1.10 UPDATE END
*/
          SELECT  SUM(NVL(stc.monthly_stock, 0)) AS stock
-- 2008/12/25 v1.29 UPDATE START
--                 ,SUM(NVL(stc.cargo_stock, 0))   AS cargo_stock
                 ,SUM(NVL(stc.cargo_stock, 0) - NVL(stc.cargo_stock_not_stn, 0)) AS cargo_stock
-- 2008/12/25 v1.29 UPDATE END
                 --,SUM(NVL(stc.monthly_stock, 0) * NVL(xlc.unit_ploce, 0)) AS stock_amt
                 --,SUM(NVL(stc.cargo_stock, 0) * NVL(xlc.unit_ploce, 0)) AS cargo_price
                 ,SUM(ROUND(NVL(stc.monthly_stock, 0) * NVL(xlc.unit_ploce, 0))) AS stock_amt
-- 2008/12/25 v1.29 UPDATE START
--                 ,SUM(ROUND(NVL(stc.cargo_stock, 0) * NVL(xlc.unit_ploce, 0))) AS cargo_price
                 ,SUM(ROUND((NVL(stc.cargo_stock, 0) - NVL(stc.cargo_stock_not_stn, 0)) * NVL(xlc.unit_ploce, 0))) AS cargo_price
-- 2008/12/25 v1.29 UPDATE END
          INTO   on_inv_qty_tbl
                ,ln_cargo_qty
                ,on_inv_amt_tbl
                ,ln_cargo_amt
          FROM   xxinv_stc_inventory_month_stck stc
-- 2008/12/10 v1.25 ADD START
                ,ic_whse_mst                    iwm
-- 2008/12/10 v1.25 ADD END
                ,xxcmn_lot_cost         xlc
          WHERE  stc.whse_code    = gt_body_data(in_pos).whse_code
          AND    stc.item_id    = gt_body_data(in_pos).item_id
          AND    stc.invent_ym  = lv_invent_yyyymm
-- 2008/12/10 v1.25 ADD START
          AND    iwm.whse_code  = stc.whse_code
          AND    iwm.attribute1 = '0'
-- 2008/12/10 v1.25 ADD END
-- 2008/12/09 v1.24 UPDATE START
--          AND    stc.item_id    = xlc.item_id
--          AND    stc.lot_id     = xlc.lot_id;
          AND    stc.item_id    = xlc.item_id(+)
          AND    stc.lot_id     = xlc.lot_id(+);
-- 2008/12/09 v1.24 UPDATE END
-- 2008/11/17 v 1.16 UPDATE END
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            on_inv_qty_tbl :=  0;
            on_inv_amt_tbl :=  0;
-- 2008/12/09 v1.24 UPDATE START
            ln_cargo_qty   :=  0;
            ln_cargo_amt   :=  0;
-- 2008/12/09 v1.24 UPDATE END
        END;
-- 2008/12/03 v1.20 ADD START
--
       -- 棚卸在庫を求める場合
       ELSE
        -- 棚卸結果より数量を取得
        BEGIN
-- 2008/12/05 MOD START
--          SELECT  SUM(stcr.case_amt * stcr.content * stcr.loose_amt) AS stock
--                 ,SUM(NVL(stc.cargo_stock, 0))   AS cargo_stock
--                 ,SUM(ROUND((stcr.case_amt * stcr.content * stcr.loose_amt) * NVL(xlc.unit_ploce, 0))) AS stock_amt
--                 ,SUM(ROUND(NVL(stc.cargo_stock, 0) * NVL(xlc.unit_ploce, 0))) AS cargo_price
-- 2008/12/09 v1.24 UPDATE START
          /*SELECT SUM(NVL(stcr.case_amt,0) * NVL(stcr.content,0) + NVL(stcr.loose_amt,0)) AS stock
                 ,SUM(NVL(stc.cargo_stock, 0))   AS cargo_stock
                 ,SUM(ROUND((NVL(stcr.case_amt,0) * NVL(stcr.content,0) + NVL(stcr.loose_amt,0)) * NVL(xlc.unit_ploce, 0))) AS stock_amt
                 ,SUM(ROUND(NVL(stc.cargo_stock, 0) * NVL(xlc.unit_ploce, 0))) AS cargo_price
-- 2008/12/05 MOD END
          INTO   on_inv_qty_tbl
                ,ln_cargo_qty
                ,on_inv_amt_tbl
                ,ln_cargo_amt
          FROM   xxinv_stc_inventory_month_stck   stc
                ,xxinv_stc_inventory_result       stcr
                ,xxcmn_lot_cost                   xlc
          WHERE  stc.whse_code    = gt_body_data(in_pos).whse_code
          AND    stc.item_id      = gt_body_data(in_pos).item_id
          AND    stc.invent_ym    = lv_invent_yyyymm
          AND    stc.item_id      = xlc.item_id
          AND    stc.lot_id       = xlc.lot_id
          AND    stc.item_id      = stcr.item_id
          AND    stc.lot_id       = stcr.lot_id
          AND    stc.whse_code    = stcr.invent_whse_code
          ;*/
--
-- 2008/12/18 v1.27 N.Yoshida mod start
          -- 月末在庫数取得
/*          SELECT SUM(NVL(stcr.case_amt,0) * NVL(stcr.content,0) + NVL(stcr.loose_amt,0)) AS stock
                 ,SUM(ROUND((NVL(stcr.case_amt,0) * NVL(stcr.content,0) + NVL(stcr.loose_amt,0)) * NVL(xlc.unit_ploce, 0))) AS stock_amt
          INTO   on_inv_qty_tbl
                ,on_inv_amt_tbl
          FROM   xxinv_stc_inventory_result       stcr
                ,xxcmn_lot_cost                   xlc
-- 2008/12/10 v1.25 ADD START
                ,ic_whse_mst                      iwm
-- 2008/12/10 v1.25 ADD END
          WHERE  stcr.invent_whse_code    = gt_body_data(in_pos).whse_code
          AND    stcr.item_id      = gt_body_data(in_pos).item_id
          AND    TO_CHAR(stcr.invent_date,'YYYYMM')  = lv_invent_yyyymm
          AND    stcr.item_id      = xlc.item_id(+)
          AND    stcr.lot_id       = xlc.lot_id(+)
-- 2008/12/10 v1.25 ADD START
          AND    iwm.whse_code     = stcr.invent_whse_code
          AND    iwm.attribute1    = '0'
-- 2008/12/10 v1.25 ADD END
          ;
--
          -- 月末積送中数取得
          SELECT SUM(NVL(stc.cargo_stock, 0))   AS cargo_stock
                 ,SUM(ROUND(NVL(stc.cargo_stock, 0) * NVL(xlc.unit_ploce, 0))) AS cargo_price
          INTO   ln_cargo_qty
                ,ln_cargo_amt
          FROM   xxinv_stc_inventory_month_stck   stc
                ,xxcmn_lot_cost                   xlc
-- 2008/12/10 v1.25 ADD START
                ,ic_whse_mst                      iwm
-- 2008/12/10 v1.25 ADD END
          WHERE  stc.whse_code    = gt_body_data(in_pos).whse_code
          AND    stc.item_id      = gt_body_data(in_pos).item_id
          AND    stc.invent_ym    = lv_invent_yyyymm
          AND    stc.item_id      = xlc.item_id(+)
          AND    stc.lot_id       = xlc.lot_id(+)
-- 2008/12/10 v1.25 ADD START
          AND    iwm.whse_code    = stc.whse_code
          AND    iwm.attribute1   = '0'
-- 2008/12/10 v1.25 ADD END
          ;*/
-- 2008/12/09 v1.24 UPDATE END
--
          -- 月末在庫数取得
          SELECT SUM(stcr_in.trans_qty) AS stock
                ,SUM(ROUND(stcr_in.trans_qty * NVL(xlc.unit_ploce, 0))) AS stock_amt
          INTO   on_inv_qty_tbl
                ,on_inv_amt_tbl
          FROM  (SELECT  stcr.invent_whse_code
                        ,stcr.item_id
                        ,stcr.lot_id
                        ,SUM(ROUND(NVL(stcr.case_amt,0) * NVL(stcr.content,0) + NVL(stcr.loose_amt,0), 3)) AS trans_qty
                 FROM    xxinv_stc_inventory_result  stcr
                        ,ic_whse_mst                 iwm
                 WHERE   stcr.invent_whse_code  = gt_body_data(in_pos).whse_code
                 AND     stcr.item_id           = gt_body_data(in_pos).item_id
                 AND     TO_CHAR(stcr.invent_date,'YYYYMM')  = lv_invent_yyyymm
                 AND     iwm.whse_code          = stcr.invent_whse_code
                 AND     iwm.attribute1         = '0'
                 GROUP BY stcr.invent_whse_code, stcr.item_id, stcr.lot_id
                ) stcr_in
                ,xxcmn_lot_cost                   xlc
          WHERE  stcr_in.item_id      = xlc.item_id(+)
          AND    stcr_in.lot_id       = xlc.lot_id(+)
          ;
--
          -- 月末積送中数取得
          SELECT SUM(stc_in.cargo_stock)   AS cargo_stock
                ,SUM(ROUND(stc_in.cargo_stock * NVL(xlc.unit_ploce, 0))) AS cargo_price
          INTO   ln_cargo_qty
                ,ln_cargo_amt
          FROM  (SELECT  stc.whse_code
                        ,stc.item_id
                        ,stc.lot_id
-- 2008/12/25 v1.29 UPDATE START
--                        ,SUM(NVL(stc.cargo_stock, 0)) AS cargo_stock
                        ,SUM(NVL(stc.cargo_stock, 0) - NVL(stc.cargo_stock_not_stn, 0)) AS cargo_stock
-- 2008/12/25 v1.29 UPDATE END
                 FROM    xxinv_stc_inventory_month_stck   stc
                        ,ic_whse_mst                      iwm
                 WHERE   stc.whse_code    = gt_body_data(in_pos).whse_code
                 AND     stc.item_id      = gt_body_data(in_pos).item_id
                 AND     stc.invent_ym    = lv_invent_yyyymm
                 AND     iwm.whse_code    = stc.whse_code
                 AND     iwm.attribute1   = '0'
                 GROUP BY stc.whse_code, stc.item_id, stc.lot_id
                ) stc_in
                ,xxcmn_lot_cost  xlc
          WHERE  stc_in.item_id      = xlc.item_id(+)
          AND    stc_in.lot_id       = xlc.lot_id(+)
          ;
-- 2008/12/18 v1.27 N.Yoshida mod end
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            on_inv_qty_tbl :=  0;
            on_inv_amt_tbl :=  0;
-- 2008/12/09 v1.24 UPDATE START
            ln_cargo_qty   :=  0;
            ln_cargo_amt   :=  0;
-- 2008/12/09 v1.24 UPDATE END
        END;
--
       END IF;
--
-- 2008/12/03 v1.20 UPDATE END
      -- 品目別の場合は品目の合計棚卸を取得する。
      ELSE
-- 2008/12/03 v1.20 ADD START
       -- 月首在庫を求める場合
       IF  (ib_stock  =  TRUE)  THEN
        -- 月末在庫より数量を取得
-- 2008/12/03 v1.20 ADD END
        BEGIN
-- 2008/11/17 v1.16 UPDATE START
/*
          SELECT  SUM(stc.monthly_stock) AS stock
-- 2008/10/20 v1.10 UPDATE START
--                 ,SUM(stc.monthly_stock * in_price) AS stock_amt
                 ,SUM(stc.monthly_stock * xlc.unit_ploce) AS stock_amt
-- 2008/10/20 v1.10 UPDATE END
          INTO   on_inv_qty_tbl
                ,on_inv_amt_tbl
          FROM   xxinv_stc_inventory_month_stck stc
-- 2008/10/20 v1.10 ADD START
                ,xxcmn_lot_cost         xlc
-- 2008/10/20 v1.10 ADD END
          WHERE  stc.item_id    = gt_body_data(in_pos).item_id
-- 2008/10/20 v1.10 UPDATE START
--          AND   stc.invent_ym = lv_invent_yyyymm;
          AND    stc.invent_ym  = lv_invent_yyyymm
          AND    stc.item_id    = xlc.item_id
          AND    stc.lot_id     = xlc.lot_id;
--
*/
          SELECT  SUM(NVL(stc.monthly_stock, 0)) AS stock
-- 2008/12/25 v1.29 UPDATE START
--                 ,SUM(NVL(stc.cargo_stock, 0))   AS cargo_stock
                 ,SUM(NVL(stc.cargo_stock, 0) - NVL(stc.cargo_stock_not_stn, 0)) AS cargo_stock
-- 2008/12/25 v1.29 UPDATE END
                 --,SUM(NVL(stc.monthly_stock, 0) * NVL(xlc.unit_ploce, 0)) AS stock_amt
                 --,SUM(NVL(stc.cargo_stock, 0) * NVL(xlc.unit_ploce, 0)) AS cargo_price
                 ,SUM(ROUND(NVL(stc.monthly_stock, 0) * NVL(xlc.unit_ploce, 0))) AS stock_amt
-- 2008/12/25 v1.29 UPDATE START
--                 ,SUM(ROUND(NVL(stc.cargo_stock, 0) * NVL(xlc.unit_ploce, 0))) AS cargo_price
                 ,SUM(ROUND((NVL(stc.cargo_stock, 0) - NVL(stc.cargo_stock_not_stn, 0)) * NVL(xlc.unit_ploce, 0))) AS cargo_price
-- 2008/12/25 v1.29 UPDATE END
          INTO   on_inv_qty_tbl
                ,ln_cargo_qty
                ,on_inv_amt_tbl
                ,ln_cargo_amt
          FROM   xxinv_stc_inventory_month_stck stc
                ,xxcmn_lot_cost         xlc
-- 2008/12/10 v1.25 ADD START
                ,ic_whse_mst                    iwm
-- 2008/12/10 v1.25 ADD END
          WHERE  stc.item_id    = gt_body_data(in_pos).item_id
          AND    stc.invent_ym  = lv_invent_yyyymm
-- 2008/12/10 v1.25 ADD START
          AND    iwm.whse_code  = stc.whse_code
          AND    iwm.attribute1 = '0'
-- 2008/12/10 v1.25 ADD END
-- 2008/12/09 v1.24 UPDATE START
--          AND    stc.item_id    = xlc.item_id
--          AND    stc.lot_id     = xlc.lot_id;
          AND    stc.item_id    = xlc.item_id(+)
          AND    stc.lot_id     = xlc.lot_id(+);
-- 2008/12/09 v1.24 UPDATE END
-- 2008/11/17 v1.16 UPDATE END
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            on_inv_qty_tbl :=  0;
            on_inv_amt_tbl :=  0;
-- 2008/11/17 v1.16 ADD START
            ln_cargo_qty   :=  0;
            ln_cargo_amt   :=  0;
-- 2008/11/17 v1.16 ADD END
        END;
-- 2008/12/03 v1.20 ADD START
--
       -- 棚卸在庫を求める場合
       ELSE
        -- 棚卸結果より数量を取得
        BEGIN
-- 2008/12/05 MOD START
--          SELECT  SUM(stcr.case_amt * stcr.content * stcr.loose_amt) AS stock
--                 ,SUM(NVL(stc.cargo_stock, 0))   AS cargo_stock
--                 ,SUM(ROUND((stcr.case_amt * stcr.content * stcr.loose_amt) * NVL(xlc.unit_ploce, 0))) AS stock_amt
--                 ,SUM(ROUND(NVL(stc.cargo_stock, 0) * NVL(xlc.unit_ploce, 0))) AS cargo_price
-- 2008/12/09 v1.24 UPDATE START
          /*SELECT SUM(NVL(stcr.case_amt,0) * NVL(stcr.content,0) + NVL(stcr.loose_amt,0)) AS stock
                 ,SUM(NVL(stc.cargo_stock, 0))   AS cargo_stock
                 ,SUM(ROUND((NVL(stcr.case_amt,0) * NVL(stcr.content,0) + NVL(stcr.loose_amt,0)) * NVL(xlc.unit_ploce, 0))) AS stock_amt
                 ,SUM(ROUND(NVL(stc.cargo_stock, 0) * NVL(xlc.unit_ploce, 0))) AS cargo_price
-- 2008/12/05 MOD END
          INTO   on_inv_qty_tbl
                ,ln_cargo_qty
                ,on_inv_amt_tbl
                ,ln_cargo_amt
          FROM   xxinv_stc_inventory_month_stck   stc
                ,xxinv_stc_inventory_result       stcr
                ,xxcmn_lot_cost                   xlc
          WHERE  stc.item_id      = gt_body_data(in_pos).item_id
          AND    stc.invent_ym    = lv_invent_yyyymm
          AND    stc.item_id      = xlc.item_id
          AND    stc.lot_id       = xlc.lot_id
          AND    stc.item_id      = stcr.item_id
          AND    stc.lot_id       = stcr.lot_id
          AND    stc.whse_code    = stcr.invent_whse_code
          ;*/
--
-- 2008/12/18 v1.27 N.Yoshida mod start
          -- 月末在庫数取得
          /*SELECT SUM(NVL(stcr.case_amt,0) * NVL(stcr.content,0) + NVL(stcr.loose_amt,0)) AS stock
                 ,SUM(ROUND((NVL(stcr.case_amt,0) * NVL(stcr.content,0) + NVL(stcr.loose_amt,0)) * NVL(xlc.unit_ploce, 0))) AS stock_amt
          INTO   on_inv_qty_tbl
                ,on_inv_amt_tbl
          FROM   xxinv_stc_inventory_result       stcr
                ,xxcmn_lot_cost                   xlc
-- 2008/12/10 v1.25 ADD START
                ,ic_whse_mst                      iwm
-- 2008/12/10 v1.25 ADD END
          WHERE  stcr.item_id      = gt_body_data(in_pos).item_id
          AND    TO_CHAR(stcr.invent_date,'YYYYMM')  = lv_invent_yyyymm
          AND    stcr.item_id      = xlc.item_id(+)
          AND    stcr.lot_id       = xlc.lot_id(+)
-- 2008/12/10 v1.25 ADD START
          AND    iwm.whse_code     = stcr.invent_whse_code
          AND    iwm.attribute1    = '0'
-- 2008/12/10 v1.25 ADD END
          ;
--
          -- 月末積送中数取得
          SELECT SUM(NVL(stc.cargo_stock, 0))   AS cargo_stock
                 ,SUM(ROUND(NVL(stc.cargo_stock, 0) * NVL(xlc.unit_ploce, 0))) AS cargo_price
          INTO   ln_cargo_qty
                ,ln_cargo_amt
          FROM   xxinv_stc_inventory_month_stck   stc
                ,xxcmn_lot_cost                   xlc
-- 2008/12/10 v1.25 ADD START
                ,ic_whse_mst                      iwm
-- 2008/12/10 v1.25 ADD END
          WHERE  stc.item_id      = gt_body_data(in_pos).item_id
          AND    stc.invent_ym    = lv_invent_yyyymm
          AND    stc.item_id      = xlc.item_id(+)
          AND    stc.lot_id       = xlc.lot_id(+)
-- 2008/12/10 v1.25 ADD START
          AND    iwm.whse_code    = stc.whse_code
          AND    iwm.attribute1   = '0'
-- 2008/12/10 v1.25 ADD END
          ;*/
-- 2008/12/09 v1.24 UPDATE END
--
          -- 月末在庫数取得
          SELECT SUM(stcr_in.trans_qty) AS stock
                ,SUM(ROUND(stcr_in.trans_qty * NVL(xlc.unit_ploce, 0))) AS stock_amt
          INTO   on_inv_qty_tbl
                ,on_inv_amt_tbl
          FROM  (SELECT  stcr.invent_whse_code
                        ,stcr.item_id
                        ,stcr.lot_id
                        ,SUM(ROUND(NVL(stcr.case_amt,0) * NVL(stcr.content,0) + NVL(stcr.loose_amt,0), 3)) AS trans_qty
                 FROM    xxinv_stc_inventory_result  stcr
                        ,ic_whse_mst                 iwm
                 WHERE   stcr.item_id           = gt_body_data(in_pos).item_id
                 AND     TO_CHAR(stcr.invent_date,'YYYYMM')  = lv_invent_yyyymm
                 AND     iwm.whse_code          = stcr.invent_whse_code
                 AND     iwm.attribute1         = '0'
                 GROUP BY stcr.invent_whse_code, stcr.item_id, stcr.lot_id
                ) stcr_in
                ,xxcmn_lot_cost                   xlc
          WHERE  stcr_in.item_id      = xlc.item_id(+)
          AND    stcr_in.lot_id       = xlc.lot_id(+)
          ;
--
          -- 月末積送中数取得
          SELECT SUM(stc_in.cargo_stock)   AS cargo_stock
                ,SUM(ROUND(stc_in.cargo_stock * NVL(xlc.unit_ploce, 0))) AS cargo_price
          INTO   ln_cargo_qty
                ,ln_cargo_amt
          FROM  (SELECT  stc.whse_code
                        ,stc.item_id
                        ,stc.lot_id
-- 2008/12/25 v1.29 UPDATE START
--                        ,SUM(NVL(stc.cargo_stock, 0)) AS cargo_stock
                        ,SUM(NVL(stc.cargo_stock, 0) - NVL(stc.cargo_stock_not_stn, 0)) AS cargo_stock
-- 2008/12/25 v1.29 UPDATE END
                 FROM    xxinv_stc_inventory_month_stck   stc
                        ,ic_whse_mst                      iwm
                 WHERE   stc.item_id      = gt_body_data(in_pos).item_id
                 AND     stc.invent_ym    = lv_invent_yyyymm
                 AND     iwm.whse_code    = stc.whse_code
                 AND     iwm.attribute1   = '0'
                 GROUP BY stc.whse_code, stc.item_id, stc.lot_id
                ) stc_in
                ,xxcmn_lot_cost  xlc
          WHERE  stc_in.item_id      = xlc.item_id(+)
          AND    stc_in.lot_id       = xlc.lot_id(+)
          ;
-- 2008/12/18 v1.27 N.Yoshida mod end
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            on_inv_qty_tbl :=  0;
            on_inv_amt_tbl :=  0;
            ln_cargo_qty   :=  0;
            ln_cargo_amt   :=  0;
        END;
--
       END IF;
--
-- 2008/12/03 v1.20 UPDATE END
      END IF;
--
-- 2008/12/09 v1.24 UPDATE START
-- 2008/11/17 v1.16 ADD START
     /*IF (ib_stock  =  TRUE) THEN
-- 2008/11/17 v1.16 ADD END
      on_inv_qty  :=  NVL(on_inv_qty_tbl, 0);
      on_inv_amt  :=  NVL(on_inv_amt_tbl, 0);
-- 2008/11/17 v1.16 ADD START
     ELSE
      on_inv_qty  :=  NVL(on_inv_qty_tbl, 0) + NVL(ln_cargo_qty, 0);
      on_inv_amt  :=  NVL(on_inv_amt_tbl, 0) + NVL(ln_cargo_amt, 0);
     END IF;*/
      on_inv_qty  :=  NVL(on_inv_qty_tbl, 0) + NVL(ln_cargo_qty, 0);
      on_inv_amt  :=  NVL(on_inv_amt_tbl, 0) + NVL(ln_cargo_amt, 0);
-- 2008/11/17 v1.16 ADD END
-- 2008/11/17 v1.16 DELETE START
-- 2008/12/09 v1.24 UPDATE END
/*
      --棚卸未確定：「棚卸月末在庫テーブルの数量＝０」は在庫は０とみなす。
      IF  (on_inv_qty = 0) AND (ib_stock  = FALSE) THEN
        on_inv_qty  :=  0;
        on_inv_amt  :=  0;
      END IF;
*/
-- 2008/11/17 v1.16 DELETE END
--
    END prc_ac_inv_qty_get;
--
    ---------------------------------------------
    --4.在庫数取得(標準原価用) 戻り値：数量 -
    ---------------------------------------------
-- 2008/12/10 v1.25 UPDTE START
/*
    FUNCTION fnc_st_inv_qty_get(
       ib_stock           IN   BOOLEAN    --TRUE:月首 FALSE:棚卸
      ,in_pos             IN   NUMBER     --品目レコード配列位置
      ,iv_exec_year_month IN   VARCHAR2)  --処理年月
      RETURN NUMBER
    IS
*/
    PROCEDURE fnc_st_inv_qty_get(
       ib_stock           IN   BOOLEAN  --TRUE:月首  FALSE:棚卸
      ,in_pos             IN   NUMBER   --品目レコード配列位置
      ,in_price           IN   NUMBER   --原価
      ,iv_exec_year_month IN   VARCHAR2 --処理年月
      ,on_inv_qty         OUT  NUMBER   --数量
      ,on_inv_amt         OUT  NUMBER)  --金額
    IS
-- 2008/12/10 v1.25 UPDTE END
--
      --在庫数戻り値
      on_inv_qty_tbl NUMBER DEFAULT 0;--在庫テーブルより
-- 2008/12/10 v1.25 ADD START
      --在庫金額戻り値
      on_inv_amt_tbl NUMBER DEFAULT 0;--在庫テーブルより
-- 2008/12/10 v1.25 ADD END
      on_inv_qty_viw NUMBER DEFAULT 0;--受払VIWより
      --日付計算用
      ld_invent_date  DATE  DEFAULT FND_DATE.STRING_TO_DATE(
                                      iv_exec_year_month || gv_fdy, gc_char_d_format);
      --棚卸年月抽出用
      lv_invent_yyyymm  VARCHAR2(06)  DEFAULT NULL;
    BEGIN
-- 2008/11/17 v1.16 ADD START
      -- 変数の初期化
      ln_cargo_qty   :=  0;
-- 2008/12/10 v1.25 ADD START
      ln_cargo_amt   :=  0;
-- 2008/12/10 v1.25 ADD END
--
-- 2008/11/17 v1.16 ADD END
      -- 「月首」指定の場合は前月の年月を求めます。
      IF  (ib_stock  =  TRUE)  THEN
        ld_invent_date  :=  TRUNC(ld_invent_date, gv_month_edt) - 1;
        lv_invent_yyyymm  :=  TO_CHAR(ld_invent_date, gc_char_ym_format);
--
       -- 「棚卸」指定の場合は当月の年月を求めます。
      ELSE
        lv_invent_yyyymm  := iv_exec_year_month;
      END IF;
      -- ===============================================================
      -- 棚卸月末在庫テーブルより「前月末在庫数」「金額」を取得します。=
      -- ===============================================================
      -- 倉庫別の場合は倉庫毎の在庫を取得する。
      IF  (gt_body_data(in_pos).whse_code IS NOT NULL) THEN
-- 2008/12/03 v1.20 ADD START
       -- 月首在庫を求める場合
       IF  (ib_stock  =  TRUE)  THEN
        -- 月末在庫より数量を取得
-- 2008/12/03 v1.20 ADD END
        BEGIN
-- 2008/11/17 v1.16 UPDATE START
--          SELECT SUM(stc.monthly_stock) AS stock
--          INTO   on_inv_qty_tbl
          SELECT SUM(NVL(stc.monthly_stock, 0)) AS stock
-- 2008/12/25 v1.29 UPDATE START
--                ,SUM(NVL(stc.cargo_stock, 0))   AS cargo_stock
                ,SUM(NVL(stc.cargo_stock, 0) - NVL(stc.cargo_stock_not_stn, 0)) AS cargo_stock
-- 2008/12/25 v1.29 UPDATE END
-- 2008/12/10 v1.25 ADD START
                ,SUM(ROUND(NVL(stc.monthly_stock, 0) * NVL(in_price, 0))) AS stock_amt
-- 2008/12/25 v1.29 UPDATE START
--                ,SUM(ROUND(NVL(stc.cargo_stock, 0) * NVL(in_price, 0))) AS cargo_price
                ,SUM(ROUND((NVL(stc.cargo_stock, 0) - NVL(stc.cargo_stock_not_stn, 0)) * NVL(in_price, 0))) AS cargo_price
-- 2008/12/25 v1.29 UPDATE END
-- 2008/12/10 v1.25 ADD END
          INTO   on_inv_qty_tbl
                ,ln_cargo_qty
-- 2008/12/10 v1.25 ADD START
                ,on_inv_amt_tbl
                ,ln_cargo_amt
-- 2008/12/10 v1.25 ADD END
-- 2008/11/17 v1.16 UPDATE END
          FROM   xxinv_stc_inventory_month_stck stc
-- 2008/12/10 v1.25 ADD START
                ,ic_whse_mst                    iwm
-- 2008/12/10 v1.25 ADD END
          WHERE  stc.whse_code    = gt_body_data(in_pos).whse_code
          AND    stc.item_id    = gt_body_data(in_pos).item_id
-- 2008/12/10 v1.25 ADD START
          AND    iwm.whse_code    = stc.whse_code
          AND    iwm.attribute1   = '0'
-- 2008/12/10 v1.25 ADD END
          AND   stc.invent_ym = lv_invent_yyyymm;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            on_inv_qty_tbl :=  0;
-- 2008/12/09 v1.24 UPDATE START
            ln_cargo_qty   :=  0;
-- 2008/12/09 v1.24 UPDATE END
-- 2008/12/10 v1.25 UPDATE START
            on_inv_amt_tbl :=  0;
            ln_cargo_amt   :=  0;
--
-- 2008/12/10 v1.25 UPDATE END
        END;
-- 2008/12/03 v1.20 ADD START
--
       -- 棚卸在庫を求める場合
       ELSE
        -- 棚卸結果より数量を取得
        BEGIN
-- 2008/12/05 MOD START
--          SELECT  SUM(stcr.case_amt * stcr.content * stcr.loose_amt) AS stock
--                 ,SUM(NVL(stc.cargo_stock, 0))   AS cargo_stock
-- 2008/12/09 v1.24 UPDATE START
          /*SELECT SUM(NVL(stcr.case_amt,0) * NVL(stcr.content,0) + NVL(stcr.loose_amt,0)) AS stock
                 ,SUM(NVL(stc.cargo_stock, 0))   AS cargo_stock
-- 2008/12/05 MOD END
          INTO   on_inv_qty_tbl
                ,ln_cargo_qty
          FROM   xxinv_stc_inventory_month_stck stc
                ,xxinv_stc_inventory_result     stcr
          WHERE  stc.whse_code    = gt_body_data(in_pos).whse_code
          AND    stc.item_id      = gt_body_data(in_pos).item_id
          AND    stc.invent_ym    = lv_invent_yyyymm
          AND    stc.item_id      = stcr.item_id
-- 2008/12/08 DELETE START
--          AND    stc.lot_id       = stcr.lot_id
-- 2008/12/08 DELETE END
          AND    stc.whse_code    = stcr.invent_whse_code
          ;*/
--
          -- 月末在庫数取得
-- 2008/12/18 v1.27 N.Yoshida mod start
-- 2008/12/10 UPDTE START
--          SELECT SUM(stcr.case_amt * stcr.content * stcr.loose_amt) AS stock
--          INTO   on_inv_qty_tbl
          /*SELECT SUM(NVL(stcr.case_amt,0) * NVL(stcr.content,0) + NVL(stcr.loose_amt,0)) AS stock
                 ,SUM(ROUND((NVL(stcr.case_amt,0) * NVL(stcr.content,0) + NVL(stcr.loose_amt,0)) * NVL(in_price, 0))) AS stock_amt
          INTO   on_inv_qty_tbl
                ,on_inv_amt_tbl
-- 2008/12/10 UPDTE END
          FROM   xxinv_stc_inventory_result   stcr
-- 2008/12/10 v1.25 ADD START
                ,ic_whse_mst                  iwm
-- 2008/12/10 v1.25 ADD END
          WHERE  stcr.invent_whse_code = gt_body_data(in_pos).whse_code
          AND    stcr.item_id          = gt_body_data(in_pos).item_id
          AND    TO_CHAR(stcr.invent_date,'YYYYMM')  = lv_invent_yyyymm
-- 2008/12/10 v1.25 ADD START
          AND    iwm.whse_code         = stcr.invent_whse_code
          AND    iwm.attribute1        = '0'
-- 2008/12/10 v1.25 ADD END
          ;
--
          -- 月末積送中数取得
          SELECT SUM(NVL(stc.cargo_stock, 0))   AS cargo_stock
-- 2008/12/10 ADD START
                 ,SUM(ROUND(NVL(stc.cargo_stock, 0) * NVL(in_price, 0))) AS cargo_price
-- 2008/12/10 ADD END
          INTO   ln_cargo_qty
-- 2008/12/10 ADD START
                ,ln_cargo_amt
-- 2008/12/10 ADD END
          FROM   xxinv_stc_inventory_month_stck       stc
-- 2008/12/10 v1.25 ADD START
                ,ic_whse_mst                          iwm
-- 2008/12/10 v1.25 ADD END
          WHERE  stc.whse_code    = gt_body_data(in_pos).whse_code
          AND    stc.item_id      = gt_body_data(in_pos).item_id
          AND    stc.invent_ym    = lv_invent_yyyymm
-- 2008/12/10 v1.25 ADD START
          AND    iwm.whse_code    = stc.whse_code
          AND    iwm.attribute1   = '0'
-- 2008/12/10 v1.25 ADD END
          ;*/
-- 2008/12/09 v1.24 UPDATE END
--
          -- 月末在庫数取得
          SELECT SUM(stcr_in.trans_qty) AS stock
                ,SUM(ROUND(stcr_in.trans_qty * NVL(in_price, 0))) AS stock_amt
          INTO   on_inv_qty_tbl
                ,on_inv_amt_tbl
          FROM  (SELECT  stcr.invent_whse_code
                        ,stcr.item_id
                        ,stcr.lot_id
                        ,SUM(ROUND(NVL(stcr.case_amt,0) * NVL(stcr.content,0) + NVL(stcr.loose_amt,0), 3)) AS trans_qty
                 FROM    xxinv_stc_inventory_result  stcr
                        ,ic_whse_mst                 iwm
                 WHERE   stcr.invent_whse_code  = gt_body_data(in_pos).whse_code
                 AND     stcr.item_id           = gt_body_data(in_pos).item_id
                 AND     TO_CHAR(stcr.invent_date,'YYYYMM')  = lv_invent_yyyymm
                 AND     iwm.whse_code          = stcr.invent_whse_code
                 AND     iwm.attribute1         = '0'
                 GROUP BY stcr.invent_whse_code, stcr.item_id, stcr.lot_id
                ) stcr_in
          ;
--
          -- 月末積送中数取得
          SELECT SUM(stc_in.cargo_stock)   AS cargo_stock
                ,SUM(ROUND(stc_in.cargo_stock * NVL(in_price, 0))) AS cargo_price
          INTO   ln_cargo_qty
                ,ln_cargo_amt
          FROM  (SELECT  stc.whse_code
                        ,stc.item_id
                        ,stc.lot_id
-- 2008/12/25 v1.29 UPDATE START
--                        ,SUM(NVL(stc.cargo_stock, 0)) AS cargo_stock
                        ,SUM(NVL(stc.cargo_stock, 0) - NVL(stc.cargo_stock_not_stn, 0)) AS cargo_stock
-- 2008/12/25 v1.29 UPDATE END
                 FROM    xxinv_stc_inventory_month_stck   stc
                        ,ic_whse_mst                      iwm
                 WHERE   stc.whse_code    = gt_body_data(in_pos).whse_code
                 AND     stc.item_id      = gt_body_data(in_pos).item_id
                 AND     stc.invent_ym    = lv_invent_yyyymm
                 AND     iwm.whse_code    = stc.whse_code
                 AND     iwm.attribute1   = '0'
                 GROUP BY stc.whse_code, stc.item_id, stc.lot_id
                ) stc_in
          ;
-- 2008/12/18 v1.27 N.Yoshida mod end
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            on_inv_qty_tbl :=  0;
            ln_cargo_qty   :=  0;
-- 2008/12/10 v1.25 ADD START
            on_inv_amt_tbl :=  0;
            ln_cargo_amt   :=  0;
-- 2008/12/10 v1.25 ADD END
        END;
--
       END IF;
--
-- 2008/12/03 v1.20 UPDATE END
      ELSE
-- 2008/12/03 v1.20 ADD START
       -- 月首在庫を求める場合
       IF  (ib_stock  =  TRUE)  THEN
        -- 月末在庫より数量を取得
-- 2008/12/03 v1.20 ADD END
        BEGIN
-- 2008/11/17 v1.16 UPDATE START
--          SELECT SUM(stc.monthly_stock) AS stock
--          INTO   on_inv_qty_tbl
          SELECT SUM(NVL(stc.monthly_stock, 0)) AS stock
-- 2008/12/25 v1.29 UPDATE START
--                ,SUM(NVL(stc.cargo_stock, 0))   AS cargo_stock
                ,SUM(NVL(stc.cargo_stock, 0) - NVL(stc.cargo_stock_not_stn, 0))   AS cargo_stock
-- 2008/12/25 v1.29 UPDATE END
-- 2008/12/10 v1.25 ADD START
                ,SUM(ROUND(NVL(stc.monthly_stock, 0) * NVL(in_price, 0))) AS stock_amt
-- 2008/12/25 v1.29 UPDATE START
--                ,SUM(ROUND(NVL(stc.cargo_stock, 0) * NVL(in_price, 0))) AS cargo_price
                ,SUM(ROUND((NVL(stc.cargo_stock, 0) - NVL(stc.cargo_stock_not_stn, 0)) * NVL(in_price, 0))) AS cargo_price
-- 2008/12/25 v1.29 UPDATE END
-- 2008/12/10 v1.25 ADD END
          INTO   on_inv_qty_tbl
                ,ln_cargo_qty
-- 2008/12/10 v1.25 ADD START
                ,on_inv_amt_tbl
                ,ln_cargo_amt
-- 2008/12/10 v1.25 ADD END
-- 2008/11/17 v1.16 UPDATE END
          FROM   xxinv_stc_inventory_month_stck stc
-- 2008/12/10 v1.25 ADD START
                ,ic_whse_mst                    iwm
-- 2008/12/10 v1.25 ADD END
          WHERE  stc.item_id    = gt_body_data(in_pos).item_id
-- 2008/12/10 v1.25 ADD START
          AND    iwm.whse_code  = stc.whse_code
          AND    iwm.attribute1 = '0'
-- 2008/12/10 v1.25 ADD END
          AND   stc.invent_ym = lv_invent_yyyymm;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            on_inv_qty_tbl :=  0;
-- 2008/11/17 v1.16 ADD START
            ln_cargo_qty   :=  0;
-- 2008/11/17 v1.16 ADD END
-- 2008/12/10 v1.25 ADD START
            on_inv_amt_tbl :=  0;
            ln_cargo_amt   :=  0;
-- 2008/12/10 v1.25 ADD END
        END;
-- 2008/12/03 v1.20 ADD START
--
       -- 棚卸在庫を求める場合
       ELSE
        -- 棚卸結果より数量を取得
        BEGIN
-- 2008/12/05 MOD START
--          SELECT  SUM(stcr.case_amt * stcr.content * stcr.loose_amt) AS stock
--                 ,SUM(NVL(stc.cargo_stock, 0))   AS cargo_stock
-- 2008/12/09 v1.24 UPDATE START
          /*SELECT SUM(NVL(stcr.case_amt,0) * NVL(stcr.content,0) + NVL(stcr.loose_amt,0)) AS stock
                 ,SUM(NVL(stc.cargo_stock, 0))   AS cargo_stock
-- 2008/12/05 MOD END
          INTO   on_inv_qty_tbl
                ,ln_cargo_qty
          FROM   xxinv_stc_inventory_month_stck stc
                ,xxinv_stc_inventory_result     stcr
          WHERE  stc.item_id      = gt_body_data(in_pos).item_id
          AND    stc.invent_ym    = lv_invent_yyyymm
          AND    stc.item_id      = stcr.item_id
-- 2008/12/08 DELETE START
--          AND    stc.lot_id       = stcr.lot_id
-- 2008/12/08 DELETE END
          AND    stc.whse_code    = stcr.invent_whse_code
          ;*/
--
          -- 月末在庫数取得
-- 2008/12/18 v1.27 N.Yoshida mod start
-- 2008/12/10 v1.25 UPDATE START
--          SELECT SUM(stcr.case_amt * stcr.content * stcr.loose_amt) AS stock
          /*SELECT SUM(stcr.case_amt * stcr.content + stcr.loose_amt) AS stock
-- 2008/12/10 v1.25 UPDATE END
-- 2008/12/10 v1.25 ADD START
                 ,SUM(ROUND((NVL(stcr.case_amt,0) * NVL(stcr.content,0) + NVL(stcr.loose_amt,0)) * NVL(in_price, 0))) AS stock_amt
-- 2008/12/10 v1.25 ADD END
          INTO   on_inv_qty_tbl
-- 2008/12/10 v1.25 ADD START
                ,on_inv_amt_tbl
-- 2008/12/10 v1.25 ADD END
          FROM   xxinv_stc_inventory_result   stcr
-- 2008/12/10 v1.25 ADD START
                ,ic_whse_mst                  iwm
-- 2008/12/10 v1.25 ADD END
          WHERE  stcr.item_id      = gt_body_data(in_pos).item_id
          AND    TO_CHAR(stcr.invent_date,'YYYYMM')  = lv_invent_yyyymm
-- 2008/12/10 v1.25 ADD START
          AND    iwm.whse_code     = stcr.invent_whse_code
          AND    iwm.attribute1    = '0'
-- 2008/12/10 v1.25 ADD END
          ;
--
          -- 月末積送中数取得
          SELECT SUM(NVL(stc.cargo_stock, 0))   AS cargo_stock
-- 2008/12/10 v1.25 ADD START
                 ,SUM(ROUND(NVL(stc.cargo_stock, 0) * NVL(in_price, 0))) AS cargo_price
-- 2008/12/10 v1.25 ADD END
          INTO   ln_cargo_qty
-- 2008/12/10 v1.25 ADD START
                ,ln_cargo_amt
-- 2008/12/10 v1.25 ADD END
          FROM   xxinv_stc_inventory_month_stck       stc
-- 2008/12/10 v1.25 ADD START
                ,ic_whse_mst                          iwm
-- 2008/12/10 v1.25 ADD END
          WHERE  stc.item_id      = gt_body_data(in_pos).item_id
          AND    stc.invent_ym    = lv_invent_yyyymm
-- 2008/12/10 v1.25 ADD START
          AND    iwm.whse_code    = stc.whse_code
          AND    iwm.attribute1   = '0'
-- 2008/12/10 v1.25 ADD END
          ;*/
-- 2008/12/09 v1.24 UPDATE END
--
          -- 月末在庫数取得
          SELECT SUM(stcr_in.trans_qty) AS stock
                ,SUM(ROUND(stcr_in.trans_qty * NVL(in_price, 0))) AS stock_amt
          INTO   on_inv_qty_tbl
                ,on_inv_amt_tbl
          FROM  (SELECT  stcr.invent_whse_code
                        ,stcr.item_id
                        ,stcr.lot_id
                        ,SUM(ROUND(NVL(stcr.case_amt,0) * NVL(stcr.content,0) + NVL(stcr.loose_amt,0), 3)) AS trans_qty
                 FROM    xxinv_stc_inventory_result  stcr
                        ,ic_whse_mst                 iwm
                 WHERE   stcr.item_id           = gt_body_data(in_pos).item_id
                 AND     TO_CHAR(stcr.invent_date,'YYYYMM')  = lv_invent_yyyymm
                 AND     iwm.whse_code          = stcr.invent_whse_code
                 AND     iwm.attribute1         = '0'
                 GROUP BY stcr.invent_whse_code, stcr.item_id, stcr.lot_id
                ) stcr_in
          ;
--
          -- 月末積送中数取得
          SELECT SUM(stc_in.cargo_stock)   AS cargo_stock
                ,SUM(ROUND(stc_in.cargo_stock * NVL(in_price, 0))) AS cargo_price
          INTO   ln_cargo_qty
                ,ln_cargo_amt
          FROM  (SELECT  stc.whse_code
                        ,stc.item_id
                        ,stc.lot_id
-- 2008/12/25 v1.29 UPDATE START
--                        ,SUM(NVL(stc.cargo_stock, 0)) AS cargo_stock
                        ,SUM(NVL(stc.cargo_stock, 0) - NVL(stc.cargo_stock_not_stn, 0)) AS cargo_stock
-- 2008/12/25 v1.29 UPDATE END
                 FROM    xxinv_stc_inventory_month_stck   stc
                        ,ic_whse_mst                      iwm
                 WHERE   stc.item_id      = gt_body_data(in_pos).item_id
                 AND     stc.invent_ym    = lv_invent_yyyymm
                 AND     iwm.whse_code    = stc.whse_code
                 AND     iwm.attribute1   = '0'
                 GROUP BY stc.whse_code, stc.item_id, stc.lot_id
                ) stc_in
          ;
-- 2008/12/18 v1.27 N.Yoshida mod end
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            on_inv_qty_tbl :=  0;
            ln_cargo_qty   :=  0;
-- 2008/12/10 v1.25 ADD START
            on_inv_amt_tbl :=  0;
            ln_cargo_amt   :=  0;
-- 2008/12/10 v1.25 ADD END
        END;
--
       END IF;
--
-- 2008/12/03 v1.20 UPDATE END
      END IF;
--
-- 2008/12/09 v1.24 UPDATE START
-- 2008/11/17 v1.16 ADD START
     /*IF (ib_stock  =  TRUE) THEN
-- 2008/11/17 v1.16 ADD END
      RETURN  NVL(on_inv_qty_tbl, 0);
-- 2008/11/17 v1.16 ADD START
     ELSE
      RETURN  NVL(on_inv_qty_tbl, 0) + NVL(ln_cargo_qty, 0);
     END IF;*/
-- 2008/11/17 v1.16 ADD END
-- 2008/12/10 v1.25 UPDATE START
--      RETURN  NVL(on_inv_qty_tbl, 0) + NVL(ln_cargo_qty, 0);
      on_inv_qty  :=  NVL(on_inv_qty_tbl, 0) + NVL(ln_cargo_qty, 0);
      on_inv_amt  :=  NVL(on_inv_amt_tbl, 0) + NVL(ln_cargo_amt, 0);
-- 2008/12/10 v1.25 UPDATE END
-- 2008/12/09 v1.24 UPDATE END
--
    END fnc_st_inv_qty_get;
--
    --------------------------
    --5.明細項目 ＸＭＬ出力  -
    --------------------------
    PROCEDURE prc_xml_body_add(
       in_pos             IN  NUMBER    --品目レコード配列位置
      ,iv_exec_year_month IN  VARCHAR2  --処理年月
      ,in_price           IN  NUMBER)   --品目原価
    IS
      --月首在庫
      ln_inv_qty        NUMBER DEFAULT 0;--数量
      ln_inv_amt        NUMBER DEFAULT 0;--金額
      --月末在庫
      ln_end_stock_qty  NUMBER DEFAULT 0;--数量
      ln_end_stock_amt  NUMBER DEFAULT 0;--金額
      --棚卸在庫
      ln_stock_qty      NUMBER DEFAULT 0;--数量
      ln_stock_amt      NUMBER DEFAULT 0;--金額
      --
      ln_amt            NUMBER DEFAULT 0;--当月項目金額
      ib_stock          BOOLEAN DEFAULT TRUE;
      ib_print          BOOLEAN DEFAULT FALSE;
-- 2008/11/25 v1.19 ADD START
      ib_zero           BOOLEAN DEFAULT TRUE;
-- 2008/11/25 v1.19 ADD END
--
    BEGIN
      -- =====================================================
      -- 明細出力編集
      -- =====================================================
--
      --月首在庫数
      IF  (    (NVL(gt_body_data(in_pos).cost_mng_clss, '0') = gc_cost_ac)
           AND (NVL(gt_body_data(in_pos).lot_ctl, '0')       = gc_lot_ctl_y) )
      THEN
        prc_ac_inv_qty_get(                             --実際原価の場合
           ib_stock             =>  ib_stock
          ,in_pos               =>  in_pos
          ,in_price             =>  in_price
          ,iv_exec_year_month   =>  iv_exec_year_month
          ,on_inv_qty           =>  ln_inv_qty
          ,on_inv_amt           =>  ln_inv_amt);
--
-- 2008/12/10 v1.25 UPDATE START
/*
          ln_inv_qty  :=  ln_inv_qty  + gn_fst_inv_qty;
-- 2008/11/04 v1.12 UPDATE START
--          ln_inv_amt  :=  ln_inv_amt  + gn_fst_inv_amt;
          ln_inv_amt  :=  ROUND(ln_inv_amt  + gn_fst_inv_amt);
-- 2008/11/04 v1.12 UPDATE END
      ELSE
        ln_inv_qty  :=  fnc_st_inv_qty_get(             --標準原価の場合
                           ib_stock
                          ,in_pos
                          ,iv_exec_year_month);
--
        ln_inv_qty  :=  ln_inv_qty  + gn_fst_inv_qty;
-- 2008/11/04 v1.12 UPDATE START
--        ln_inv_amt  :=  in_price * ln_inv_qty;
        ln_inv_amt  :=  ROUND(in_price * ln_inv_qty);
-- 2008/11/04 v1.12 UPDATE END
      END IF;
*/
      ELSE
        fnc_st_inv_qty_get(                             --標準原価の場合
           ib_stock             =>  ib_stock
          ,in_pos               =>  in_pos
          ,in_price             =>  in_price
          ,iv_exec_year_month   =>  iv_exec_year_month
          ,on_inv_qty           =>  ln_inv_qty
          ,on_inv_amt           =>  ln_inv_amt);
--
      END IF;
--
-- 2008/12/10 v1.25 UPDATE END
--
      prc_xml_add( 'g_item', 'T');
      prc_xml_add('item_code', 'D', gt_body_data(in_pos).item_code); --品目ID
      prc_xml_add('item_name', 'D', gt_body_data(in_pos).item_name); --品目名称
      prc_xml_add('first_inv_qty', 'D', TO_CHAR(NVL(ln_inv_qty, 0)));--月首在庫数量
      prc_xml_add('first_inv_amt', 'D', TO_CHAR(NVL(ln_inv_amt, 0)));--月首在庫金額
      ib_print  := TRUE;
--
      ln_end_stock_qty  :=  ln_end_stock_qty + ln_inv_qty;
      ln_end_stock_amt  :=  ln_end_stock_amt + ln_inv_amt;
--
      -- 項目出力編集（受入～払出）
      <<field_edit_loop>>
      FOR i IN 1 .. gc_print_pos_max LOOP
        --項目出力
-- 2008/11/10 UPDATE START
/*
        --実際原価の場合
        IF  (    (NVL(gt_body_data(in_pos).cost_mng_clss, '0') = gc_cost_ac)
             AND (NVL(gt_body_data(in_pos).lot_ctl, '0')       = gc_lot_ctl_y) )
        THEN
-- 2008/10/20 v1.10 UPDATE START
--          ln_amt  :=  NVL(qty(i), 0)  *  in_price;
          ln_amt  :=  NVL(amt(i), 0);
-- 2008/11/04 UPDATE END
-- 2008/10/20 v1.10 UPDATE END
        ELSE
-- 2008/10/20 v1.10 UPDATE START
--          ln_amt  :=  NVL(amt(i), 0);                                     --標準原価の場合
-- 2008/11/04 UPDATE START
--          ln_amt  :=  NVL(qty(i), 0)  *  in_price;
          ln_amt  :=  ROUND(NVL(qty(i), 0)  *  in_price);
-- 2008/11/04 UPDATE END
-- 2008/10/20 v1.10 UPDATE END
        END IF;
*/
        ln_amt  :=  NVL(amt(i), 0);
-- 2008/11/10 UPDATE END
--
        IF  (ib_print = FALSE) THEN
          prc_xml_add( 'g_item', 'T');
          prc_xml_add('item_code', 'D', gt_body_data(in_pos).item_code); --品目ID
          prc_xml_add('item_name', 'D', gt_body_data(in_pos).item_name); --品目名称
          ib_print  := TRUE;
        END IF;
        prc_xml_add(tag_name(i) || gv_qty_prf, 'D', TO_CHAR(qty(i)), FALSE);
        prc_xml_add(tag_name(i) || gv_amt_prf, 'D', TO_CHAR(ln_amt), FALSE);
--
        --月末在庫集計
        IF  (i <  gc_pay_pos_strt)  THEN
          ln_end_stock_qty  :=  ln_end_stock_qty  + qty(i);--数量
          ln_end_stock_amt  :=  ln_end_stock_amt  + ln_amt;--金額
        ELSE
          ln_end_stock_qty  :=  ln_end_stock_qty  - qty(i);--数量
          ln_end_stock_amt  :=  ln_end_stock_amt  - ln_amt;--金額
        END IF;
-- 2008/11/25 v1.19 ADD START
--
        IF ((NVL(qty(i), 0) <> 0) OR (NVL(amt(i), 0) <> 0))THEN
          ib_zero := FALSE;
        END IF;
--
-- 2008/11/25 v1.19 ADD END
      END LOOP  field_edit_loop;
--
      IF  (ib_print = FALSE) THEN
        prc_xml_add( 'g_item', 'T');
        prc_xml_add('item_code', 'D', gt_body_data(in_pos).item_code); --品目ID
        prc_xml_add('item_name', 'D', gt_body_data(in_pos).item_name); --品目名称
        ib_print  := TRUE;
      END IF;
      prc_xml_add('end_inv_qty', 'D',   TO_CHAR(NVL(ln_end_stock_qty, 0)));--月末在庫数量
      prc_xml_add('end_inv_amt', 'D',   TO_CHAR(NVL(ln_end_stock_amt, 0)));--月末在庫金額
--
      ib_stock  :=  FALSE;
      --棚卸在庫数
      IF  (    (NVL(gt_body_data(in_pos).cost_mng_clss, '0') = gc_cost_ac)
           AND (NVL(gt_body_data(in_pos).lot_ctl, '0')       = gc_lot_ctl_y) )
      THEN
        prc_ac_inv_qty_get(                             --実際原価の場合
           ib_stock             =>  ib_stock
          ,in_pos               =>  in_pos
          ,in_price             =>  in_price
          ,iv_exec_year_month   =>  iv_exec_year_month
          ,on_inv_qty           =>  ln_stock_qty
          ,on_inv_amt           =>  ln_stock_amt);
--
-- 2008/12/10 v1.25 UPDATE START
/*
          ln_stock_qty  :=  ln_stock_qty  + gn_lst_inv_qty;
          ln_stock_amt  :=  ln_stock_amt  + gn_lst_inv_amt;
      ELSE
        ln_stock_qty  :=  fnc_st_inv_qty_get(            --標準原価の場合
                             ib_stock
                            ,in_pos
                            ,iv_exec_year_month);
--
        ln_stock_qty  :=  ln_stock_qty  + gn_lst_inv_qty;
        ln_stock_amt  :=  in_price * ln_stock_qty;
*/
      ELSE
        fnc_st_inv_qty_get(                             --標準原価の場合
           ib_stock             =>  ib_stock
          ,in_pos               =>  in_pos
          ,in_price             =>  in_price
          ,iv_exec_year_month   =>  iv_exec_year_month
          ,on_inv_qty           =>  ln_stock_qty
          ,on_inv_amt           =>  ln_stock_amt);
--
-- 2008/12/10 v1.25 UPDATE END
      END IF;
      --棚卸数が確定している場合のみ出力します。
      IF  (ln_stock_qty !=  0)  THEN
        IF  (ib_print = FALSE) THEN
          prc_xml_add( 'g_item', 'T');
          prc_xml_add('item_code', 'D', gt_body_data(in_pos).item_code); --品目ID
          prc_xml_add('item_name', 'D', gt_body_data(in_pos).item_name); --品目名称
          ib_print  := TRUE;
        END IF;
        prc_xml_add('inv_qty', 'D',       TO_CHAR(NVL(ln_stock_qty, 0)));--棚卸在庫数量
        prc_xml_add('inv_amt', 'D',       TO_CHAR(NVL(ln_stock_amt, 0)));--棚卸在庫金額
-- 2008/08/20 v1.8 UPDATE START
--        IF  (ln_end_stock_qty !=  0 OR ln_stock_qty != 0)  THEN
        IF  (ln_end_stock_qty <> 0)  THEN
-- 2008/08/20 v1.8 UPDATE END
          IF  (ib_print = FALSE) THEN
            prc_xml_add( 'g_item', 'T');
            prc_xml_add('item_code', 'D', gt_body_data(in_pos).item_code); --品目ID
            prc_xml_add('item_name', 'D', gt_body_data(in_pos).item_name); --品目名称
            ib_print  := TRUE;
          END IF;
-- 2008/12/22 v1.28 UPDATE START
--          prc_xml_add('quantity', 'D',      TO_CHAR((ln_end_stock_qty  - ln_stock_qty)));--差異数量
--          prc_xml_add('amount', 'D',        TO_CHAR((ln_end_stock_amt  - ln_stock_amt)));--差異金額
          prc_xml_add('quantity', 'D',      TO_CHAR((NVL(ln_end_stock_qty, 0)  - NVL(ln_stock_qty, 0))));--差異数量
          prc_xml_add('amount', 'D',        TO_CHAR((NVL(ln_end_stock_amt, 0)  - NVL(ln_stock_amt, 0))));--差異金額
-- 2008/12/22 v1.28 UPDATE END
-- 2009/01/07 v1.30 UPDATE START
        ELSE
          prc_xml_add('quantity', 'D',      TO_CHAR((NVL(ln_end_stock_qty, 0)  - NVL(ln_stock_qty, 0))));--差異数量
          prc_xml_add('amount', 'D',        TO_CHAR((NVL(ln_end_stock_amt, 0)  - NVL(ln_stock_amt, 0))));--差異金額
-- 2009/01/07 v1.30 UPDATE END
        END IF;
      ELSE
        IF  (ib_print = TRUE) THEN
          prc_xml_add('inv_qty', 'D',  0);--棚卸在庫数量
          prc_xml_add('inv_amt', 'D',  0);--棚卸在庫金額
-- 2008/08/20 v1.8 UPDATE START
--          prc_xml_add('quantity','D',  0);--差異数量
--          prc_xml_add('amount',  'D',  0);--差異金額
-- 2008/12/22 v1.28 UPDATE START
--          prc_xml_add('quantity', 'D',      TO_CHAR((ln_end_stock_qty  - ln_stock_qty)));--差異数量
--          prc_xml_add('amount', 'D',        TO_CHAR((ln_end_stock_amt  - ln_stock_amt)));--差異金額
          prc_xml_add('quantity', 'D',      TO_CHAR((NVL(ln_end_stock_qty, 0)  - NVL(ln_stock_qty, 0))));--差異数量
          prc_xml_add('amount', 'D',        TO_CHAR((NVL(ln_end_stock_amt, 0)  - NVL(ln_stock_amt, 0))));--差異金額
-- 2008/12/22 v1.28 UPDATE END
-- 2008/08/20 v1.8 UPDATE END
        END IF;
      END IF;
--
-- 2008/11/25 v1.19 ADD START
      -- 当月受払・月首・棚卸の数量・金額が全てゼロの場合
      IF (
            (ib_zero = TRUE)
              AND (ln_inv_qty = 0)
                AND (ln_inv_amt = 0)
                  AND (ln_stock_qty = 0)
                    AND (ln_stock_amt = 0)
          ) THEN
      ------------------------------
      -- 出力判定用タグ
      ------------------------------
        prc_xml_add('flg', 'D', '1');
      ELSE
        prc_xml_add('flg', 'D', '0');
      END IF;
--
-- 2008/11/25 v1.19 ADD END
      IF  (ib_print = TRUE) THEN
        prc_xml_add( '/g_item', 'T');
      END IF;
--
    END prc_xml_body_add;
--
    ----------------------
    --6.品目の原価の取得 -
    ----------------------
    FUNCTION fnc_item_unit_pric_get(
      in_pos   IN   VARCHAR2)    --品目レコード配列位置
      RETURN NUMBER
    IS
--
      --原価戻り値
      on_unit_price NUMBER DEFAULT 0;
--
    BEGIN
      --原価区分(1)＝標準原価のとき
      IF  (   (NVL(gt_body_data(in_pos).cost_mng_clss, '0') = gc_cost_st)
           OR (NVL(gt_body_data(in_pos).lot_ctl, '0')       = gc_lot_ctl_n) )
      THEN
        -- =========================================
        -- 標準原価マスタより標準単価を取得します。=
        -- =========================================
        BEGIN
-- 2009/05/29 MOD START
          SELECT stnd_unit_price as price
          INTO   on_unit_price
          FROM   xxcmn_stnd_unit_price_v xsup
          WHERE  xsup.item_id    =  gt_body_data(in_pos).item_id
            AND xsup.start_date_active  <= gd_st_unit_date
            AND xsup.end_date_active    >= gd_st_unit_date;
--          SELECT stnd_unit_price as price
--          INTO   on_unit_price
--          FROM   xxcmn_stnd_unit_price_v xsup
--          WHERE  xsup.item_id    =  gt_body_data(in_pos).item_id
--            AND (xsup.start_date_active IS NULL OR
--                 xsup.start_date_active  <= TRUNC(gt_body_data(in_pos).trans_date))
--            AND (xsup.end_date_active   IS NULL OR
--                 xsup.end_date_active    >= TRUNC(gt_body_data(in_pos).trans_date));
-- 2009/05/29 MOD END
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            on_unit_price :=  0;
        END;
--
     --原価区分(0)＝実際原価のとき
      ELSIF (    (NVL(gt_body_data(in_pos).cost_mng_clss, '0') = gc_cost_ac)
             AND (NVL(gt_body_data(in_pos).lot_ctl, '0')       = gc_lot_ctl_y) )
      THEN
        on_unit_price :=  NVL(gt_body_data(in_pos).actual_unit_price, 0);
      ELSE
        on_unit_price :=  0;
      END IF;
--
      RETURN  on_unit_price;
--
    END fnc_item_unit_pric_get;
--
    ----------------------
    --7.品目明細加算処理 -
    ----------------------
    PROCEDURE prc_item_sum(
      in_pos        IN   NUMBER           --   品目レコード配列位置
     ,in_unit_pric  IN   NUMBER           --   原価
     ,ir_param      IN   rec_param_data)  -- 01.入力パラメータ群
    IS
      -- *** ローカル変数 ***
      ln_col_pos     NUMBER DEFAULT 0;  --受払区分毎の印字位置数値
      ln_qty         NUMBER DEFAULT 0;  --数量
      ln_rcv_pay_div NUMBER DEFAULT 0;  --受払区分
    BEGIN
--
      --数量設定
      ln_qty  :=  NVL(gt_body_data(in_pos).trans_qty, 0);
--
      --印字位置(集計列位置）を数値へ変換
      BEGIN
        ln_col_pos  :=  TO_NUMBER(gt_body_data(in_pos).print_pos);
      EXCEPTION
      WHEN VALUE_ERROR THEN
        ln_col_pos :=  0;
      END;
--
      --受払区分を数値へ変換
      BEGIN
        ln_rcv_pay_div  :=  TO_NUMBER(gt_body_data(in_pos).rcv_pay_div);
      EXCEPTION
      WHEN VALUE_ERROR THEN
        ln_rcv_pay_div :=  0;
      END;
--
-- 2008/11/04 v1.12 ADD START
-- 2008/11/07 v1.15 ADD START
     IF (gt_body_data(in_pos).arrival_ym = ir_param.exec_year_month) THEN
-- 2008/11/07 v1.15 ADD END
      ----------------
      --当月明細加算 -
      ----------------
      IF  (ln_col_pos >=  1 ) AND (ln_col_pos <= gc_print_pos_max)  THEN
        --数量加算(当月分の数量は受払区分で符号チェンジしておく）
        qty(ln_col_pos)  :=  qty(ln_col_pos) +  (ln_qty  *  ln_rcv_pay_div);
        --金額加算
        amt(ln_col_pos)  :=  amt(ln_col_pos) +  ROUND(in_unit_pric * (ln_qty  *  ln_rcv_pay_div));
      END IF;
--
-- 2008/11/04 v1.12 ADD END
-- 2008/11/07 v1.15 ADD START
     END IF;
-- 2008/11/07 v1.15 ADD END
-- 2008/11/17 v1.17 DELETE START
/*
      --取引日の年月＝パラメータ.処理年月 AND 着荷日の年月  != パラメータ.処理年月
      IF (gt_body_data(in_pos).trans_ym = ir_param.exec_year_month)
        AND ( gt_body_data(in_pos).arrival_ym = ir_param.exec_year_month)  THEN
-- 2008/11/04 v1.12 UPDATE START
        ----------------
        --当月明細加算 -
        ----------------
        IF  (ln_col_pos >=  1 ) AND (ln_col_pos <= gc_print_pos_max)  THEN
          --数量加算(当月分の数量は受払区分で符号チェンジしておく）
          qty(ln_col_pos)  :=  qty(ln_col_pos) +  (ln_qty  *  ln_rcv_pay_div);
          --金額加算
-- 2008/11/04 v1.12 UPDATE START
--          amt(ln_col_pos)  :=  amt(ln_col_pos) +  in_unit_pric * (ln_qty  *  ln_rcv_pay_div);
          amt(ln_col_pos)  :=  amt(ln_col_pos) +  ROUND(in_unit_pric * (ln_qty  *  ln_rcv_pay_div));
-- 2008/11/04 v1.12 UPDATE END
        END IF;
        NULL;
-- 2008/11/04 v1.12 UPDATE END
--
      --取引日の年月＝パラメータ.処理年月の前月 AND 着荷日の年月  = パラメータ.処理年月
      ELSIF (gt_body_data(in_pos).trans_ym = TO_CHAR(gd_s_date, gc_char_ym_format))
        AND ( gt_body_data(in_pos).arrival_ym = ir_param.exec_year_month)  THEN
        -----------------------------
        --月首数量および金額加算 ----
        -----------------------------
-- 2008/11/07 v1.12 UPDATE START
--        gn_fst_inv_qty  :=  gn_fst_inv_qty  + ln_qty;
--        gn_fst_inv_amt  :=  gn_fst_inv_amt  + (ln_qty * in_unit_pric);
        gn_fst_inv_qty  :=  gn_fst_inv_qty  + (ln_qty * ln_rcv_pay_div);
        gn_fst_inv_amt  :=  gn_fst_inv_amt  + ROUND((ln_qty * ln_rcv_pay_div) * in_unit_pric);
-- 2008/11/07 v1.12 UPDATE END
--
      --取引日の年月＝パラメータ.処理年月 AND 着荷日の年月  = パラメータ.処理年月の翌月
      ELSIF (gt_body_data(in_pos).trans_ym = ir_param.exec_year_month)
        AND ( gt_body_data(in_pos).arrival_ym = TO_CHAR(gd_follow_date, gc_char_ym_format))  THEN
        -----------------------------
        --棚卸数量および金額加算 ----
        -----------------------------
        gn_lst_inv_qty  :=  gn_lst_inv_qty  +  (ln_qty * ln_rcv_pay_div);
-- 2008/11/04 v1.12 UPDATE START
--        gn_lst_inv_amt  :=  gn_fst_inv_amt  + (ln_qty * in_unit_pric);
        gn_lst_inv_amt  :=  gn_fst_inv_amt  + ROUND((ln_qty * ln_rcv_pay_div) * in_unit_pric);
-- 2008/11/04 v1.12 UPDATE END
      END IF;
*/
-- 2008/11/17 v1.17 DELETE END
    END prc_item_sum;
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
    -- 項目データ抽出処理
    -- =====================================================
    prc_get_report_data(
        ir_param      => ir_param       -- 01.入力パラメータ群
       ,ot_data_rec   => gt_body_data   -- 02.取得レコード群
       ,ov_errbuf     => lv_errbuf      --    エラー・メッセージ           --# 固定 #
       ,ov_retcode    => lv_retcode     --    リターン・コード             --# 固定 #
       ,ov_errmsg     => lv_errmsg      --    ユーザー・エラー・メッセージ --# 固定 #
      );
    IF ( lv_retcode = gv_status_error ) THEN
      RAISE global_api_expt;
--
    -- 取得データが０件の場合
    ELSIF ( gt_body_data.COUNT = 0 ) THEN
      RAISE no_data_expt;
--
    END IF;
--
    -- =====================================================
    -- 項目データ抽出・出力処理
    -- =====================================================
    -- -----------------------------------------------------
    -- ユーザーＧ開始タグ出力
    -- -----------------------------------------------------
    prc_xml_add('user_info', 'T', NULL);
    -- -----------------------------------------------------
    -- ユーザーＧデータタグ出力
    -- -----------------------------------------------------
--
    -- 帳票ＩＤ
    prc_xml_add('report_id', 'D', gv_report_id);
    -- 実施日
    prc_xml_add('exec_date', 'D', TO_CHAR( gd_exec_date, gc_char_dt_format ));
    -- 担当部署
    prc_xml_add('exec_user_dept', 'D', NVL(gv_user_dept, ' '));
    -- 担当者名
    prc_xml_add('exec_user_name', 'D', NVL(gv_user_name, ' '));
    --倉庫別を選択し、倉庫コードが指定されている場合は「倉庫計」は出力しなので「品目別」としておく
    IF ((ir_param.print_kind = gc_print_type1) AND (ir_param.locat_code  IS NOT NULL))
      OR (ir_param.print_kind = gc_print_type2) THEN
      prc_xml_add('print_type', 'D', gc_print_type2);--品目別と同じ扱い
    ELSE
      prc_xml_add('print_type', 'D', gc_print_type1);--倉庫別と同じ扱い
    END IF;
    -- 帳票種別
    prc_xml_add('out_div', 'D', ir_param.print_kind);
    -- 帳票種別名
    prc_xml_add('out_div_name', 'D', SUBSTRB(gv_print_class_name, 1, 20));
    -- 品目区分
    prc_xml_add('item_div', 'D', ir_param.item_class);
    -- 品目区分名
    prc_xml_add('item_div_name', 'D', SUBSTRB(gv_item_class_name, 1, 20));
    -- 処理年
    prc_xml_add('exec_year', 'D',  SUBSTR(ir_param.exec_year_month, 1, gc_exec_year_m));
    -- 処理月
    prc_xml_add('exec_month', 'D', SUBSTR(ir_param.exec_year_month, gc_exec_year_y, gc_m_pos));
    -- 群種別
    prc_xml_add('crowd_div', 'D', ir_param.crowd_kind);
    -- 群種別名
    prc_xml_add('crowd_div_name', 'D', SUBSTRB(gv_crowd_kind_name, 1, 20));
    -- 商品区分
    prc_xml_add('prod_div', 'D', ir_param.goods_class);
    -- 商品区分名
    prc_xml_add('prod_div_name', 'D', SUBSTRB(gv_goods_class_name, 1, 20));
    -- -----------------------------------------------------
    -- ユーザーＧ終了タグ出力
    -- -----------------------------------------------------
    prc_xml_add('/user_info', 'T', NULL);
    -- -----------------------------------------------------
    -- データＬＧ開始タグ出力
    -- -----------------------------------------------------
    prc_xml_add('data_info', 'T', NULL);
    -- -----------------------------------------------------
    -- 倉庫ＬＧ開始タグ出力
    -- -----------------------------------------------------
    prc_xml_add('lg_locat', 'T', NULL);
--
    -- 「対象データ行位置」の初期値設定
    ln_i  :=  1;
   --=========================================総合計
    <<total_loop>>
    WHILE (ln_i  <= gt_body_data.COUNT)                                            LOOP
      lv_whse_code  :=  NVL(gt_body_data(ln_i).whse_code, lc_break_null);
      prc_xml_add('g_locat', 'T');
      ln_position :=  ln_position + 1;
      prc_xml_add('position', 'D', TO_CHAR(ln_position));
      prc_xml_add('locat_code', 'D', NVL(gt_body_data(ln_i).whse_code, 0));
      prc_xml_add('locat_name', 'D', gt_body_data(ln_i).whse_name);
      prc_xml_add('warehouse_code', 'D', lv_whse_code);
      prc_xml_add('lg_crowd_high', 'T');
      --=============================================倉庫コード開始
      <<whse_code_loop>>
      WHILE (ln_i  <= gt_body_data.COUNT)
        AND (NVL( gt_body_data(ln_i).whse_code, lc_break_null )  = lv_whse_code)     LOOP
        lv_crowd_high  :=  NVL(gt_body_data(ln_i).crowd_high, lc_break_null);
        prc_xml_add('g_crowd_high', 'T');
        prc_xml_add('crowd_high', 'D', gt_body_data(ln_i).crowd_high);
        prc_xml_add('lg_crowd_mid', 'T');
        --===============================================大群コード開始
        <<large_grp_loop>>
        WHILE (ln_i  <= gt_body_data.COUNT)
          AND (NVL( gt_body_data(ln_i).whse_code, lc_break_null )  = lv_whse_code)
          AND (NVL( gt_body_data(ln_i).crowd_high, lc_break_null ) = lv_crowd_high)    LOOP
          lv_crowd_mid  :=  NVL(gt_body_data(ln_i).crowd_mid, lc_break_null);
          prc_xml_add('g_crowd_mid', 'T');
          prc_xml_add('crowd_mid', 'D', gt_body_data(ln_i).crowd_mid);
          prc_xml_add('lg_crowd_low', 'T');
          --================================================中群コード開始
          <<midle_grp_loop>>
          WHILE (ln_i  <= gt_body_data.COUNT)
            AND (NVL( gt_body_data(ln_i).whse_code, lc_break_null ) = lv_whse_code)
            AND (NVL( gt_body_data(ln_i).crowd_mid, lc_break_null ) = lv_crowd_mid)      LOOP
            lv_crowd_low  :=  NVL(gt_body_data(ln_i).crowd_low, lc_break_null);
            prc_xml_add('g_crowd_low', 'T');
            prc_xml_add('crowd_low', 'D', gt_body_data(ln_i).crowd_low);
            prc_xml_add('lg_crowd_dtl', 'T');
            --====================================================小群コード開始
            <<minor_grp_loop>>
            WHILE (ln_i  <= gt_body_data.COUNT)
              AND (NVL( gt_body_data(ln_i).whse_code, lc_break_null ) = lv_whse_code)
              AND (NVL( gt_body_data(ln_i).crowd_low, lc_break_null ) = lv_crowd_low)      LOOP
              lv_crowd_dtl  :=  NVL(gt_body_data(ln_i).crowd_code, lc_break_null);
              prc_xml_add('g_crowd_dtl', 'T');
              prc_xml_add('crowd_dtl', 'D', gt_body_data(ln_i).crowd_code);
              prc_xml_add('lg_item', 'T');
              --========================================================群コード開始
              <<grp_loop>>
              WHILE (ln_i  <= gt_body_data.COUNT)
                AND (NVL( gt_body_data(ln_i).whse_code, lc_break_null ) = lv_whse_code)
                AND (NVL( gt_body_data(ln_i).crowd_code, lc_break_null ) = lv_crowd_dtl)     LOOP
                lv_item_code  :=  NVL( gt_body_data(ln_i).item_code, lc_break_null );
                initialize(); --品目明細クリア
-- 2008/10/20 v1.10 DELETE START
--                ln_price :=  fnc_item_unit_pric_get(ln_i);--原価取得
-- 2008/10/20 v1.10 DELETE END
                --==========================================================品目開始
                <<item_loop>>
                WHILE (ln_i  <= gt_body_data.COUNT)
                  AND (NVL( gt_body_data(ln_i).whse_code, lc_break_null ) = lv_whse_code)
                  AND (NVL( gt_body_data(ln_i).item_code, lc_break_null ) = lv_item_code)      LOOP
-- 2008/10/20 v1.10 ADD START
                  ln_price :=  fnc_item_unit_pric_get(ln_i);--原価取得
-- 2008/10/20 v1.10 ADD END
                  --品目明細加算処理
                  prc_item_sum(ln_i,  ln_price, ir_param);
                  ln_i  :=  ln_i  + 1; --次明細位置
                END LOOP  item_loop;--======================================品目終了
                prc_xml_body_add(ln_i - 1,
                  ir_param.exec_year_month, ln_price); --品目明細出力
              END LOOP  grp_loop;--=====================================群コード終了
              prc_xml_add('/lg_item', 'T');
              prc_xml_add('/g_crowd_dtl', 'T');
            END LOOP  minor_grp_loop;--===========================小群コード終了
            prc_xml_add('/lg_crowd_dtl', 'T');
            prc_xml_add('/g_crowd_low',  'T');
          END LOOP  midle_grp_loop;--========================中群コード終了
          prc_xml_add('/lg_crowd_low',  'T');
          prc_xml_add('/g_crowd_mid', 'T');
        END LOOP  large_grp_loop;--======================大群コード終了
        prc_xml_add('/lg_crowd_mid', 'T');
        prc_xml_add('/g_crowd_high', 'T');
      END LOOP  whse_code_loop;--====================倉庫計終了
      prc_xml_add('/lg_crowd_high', 'T');
      prc_xml_add('/g_locat', 'T');
    END LOOP  total_loop;--====================総合計(ALL END)
--
    prc_xml_add('/lg_locat', 'T');
    prc_xml_add('/data_info', 'T'); --データ終了
--
  EXCEPTION
    -- *** 取得データ０件 ***
    WHEN no_data_expt THEN
      ov_retcode := gv_status_warn;
      ov_errmsg  := xxcmn_common_pkg.get_msg( gc_application
                                             ,'APP-XXCMN-10122' );
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
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
      iv_yyyymm               IN     VARCHAR2    -- 01 : 処理年月
     ,iv_product_class        IN     VARCHAR2    -- 02 : 商品区分
     ,iv_item_class           IN     VARCHAR2    -- 03 : 品目区分
     ,iv_report_type          IN     VARCHAR2    -- 04 : 帳票種別
     ,iv_whse_code            IN     VARCHAR2    -- 05 : 倉庫コード
     ,iv_group_type           IN     VARCHAR2    -- 06 : 群種別
     ,iv_group_code           IN     VARCHAR2    -- 07 : 群コード
     ,iv_accounting_grp_code  IN     VARCHAR2    -- 08 : 経理群コード
     ,ov_errbuf               OUT    VARCHAR2         -- エラー・メッセージ           --# 固定 #
     ,ov_retcode              OUT    VARCHAR2         -- リターン・コード             --# 固定 #
     ,ov_errmsg               OUT    VARCHAR2         -- ユーザー・エラー・メッセージ --# 固定 #
    )
  IS
--
--#####################  固定ローカル定数変数宣言部 START   ####################
--
    -- ======================================================
    -- 固定ローカル定数
    -- ======================================================
    cv_prg_name    CONSTANT VARCHAR2(30) := 'submain'; -- プログラム名
    -- ======================================================
    -- ローカル変数
    -- ======================================================
    lv_errbuf  VARCHAR2(5000);                   --   エラー・メッセージ
    lv_retcode VARCHAR2(1);                      --   リターン・コード
    lv_errmsg  VARCHAR2(5000);                   --   ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ======================================================
    -- ユーザー宣言部
    -- ======================================================
    -- *** ローカル変数 ***
    lr_param_rec            rec_param_data;          -- パラメータ受渡し用
    lv_f_date               VARCHAR2(20);
--
    lv_xml_string           VARCHAR2(32000);
    ln_retcode              NUMBER;
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
    -- 帳票出力値格納
    gv_report_id               := 'XXCMN770001T';         -- 帳票ID
    gd_exec_date               := SYSDATE;                -- 実施日
--
    lv_f_date := TO_CHAR(FND_DATE.STRING_TO_DATE(iv_yyyymm , gc_char_ym_format),gc_char_ym_format);
    IF (lv_f_date IS NULL) THEN
      lr_param_rec.exec_year_month := iv_yyyymm;
    ELSE
      lr_param_rec.exec_year_month := lv_f_date;
    END IF;                                                 -- 01 : 処理年月     (必須)
    -- 2009/05/29 ADD START
    gd_st_unit_date := FND_DATE.STRING_TO_DATE(iv_yyyymm , gc_char_ym_format);
    -- 2009/05/29 ADD END
--
    lr_param_rec.goods_class     := iv_product_class;       -- 02 : 商品区分    （必須)
    lr_param_rec.item_class      := iv_item_class;          -- 03 : 品目区分    （必須)
    lr_param_rec.print_kind      := iv_report_type;         -- 04 : 帳票種別    （必須)
    lr_param_rec.locat_code      := iv_whse_code;           -- 05 : 倉庫コード  （任意)
    lr_param_rec.crowd_kind      := iv_group_type;          -- 06 : 群種別      （必須)
    lr_param_rec.crowd_code      := iv_group_code;          -- 07 : 群コード    （任意)
    lr_param_rec.acnt_crowd_code := iv_accounting_grp_code; -- 08 : 経理群コード（任意)
    -- =====================================================
    -- 前処理
    -- =====================================================
    prc_initialize(
        ir_param          => lr_param_rec       -- 入力パラメータ群
       ,ov_errbuf         => lv_errbuf          -- エラー・メッセージ           --# 固定 #
       ,ov_retcode        => lv_retcode         -- リターン・コード             --# 固定 #
       ,ov_errmsg         => lv_errmsg          -- ユーザー・エラー・メッセージ --# 固定 #
      );
    IF (lv_retcode = gv_status_error)
     OR (lv_retcode = gv_status_warn) THEN
      RAISE global_process_expt ;
    END IF;
--
    -- =====================================================
    -- 帳票データ出力
    -- =====================================================
    prc_create_xml_data(
        ir_param          => lr_param_rec       -- 入力パラメータレコード
       ,ov_errbuf         => lv_errbuf          -- エラー・メッセージ           --# 固定 #
       ,ov_retcode        => lv_retcode         -- リターン・コード             --# 固定 #
       ,ov_errmsg         => lv_errmsg          -- ユーザー・エラー・メッセージ --# 固定 #
      );
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ==================================================
    -- ＸＭＬ出力
    -- ==================================================
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<?xml version="1.0" encoding="shift_jis" ?>' );
    -- --------------------------------------------------
    -- 抽出データが０件の場合
    -- --------------------------------------------------
    IF  ( lv_errmsg IS NOT NULL )
    AND ( lv_retcode = gv_status_warn ) THEN
      -- ０件メッセージ出力
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<root>');
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '  <data_info>');
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '    <lg_locat>');
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '      <g_locat>');
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '       <msg>' || lv_errmsg || '</msg>');
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '      </g_locat>');
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '    </lg_locat>');
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '  </data_info>');
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '</root>');
--
      -- ０件メッセージログ出力
      lv_errmsg  := xxcmn_common_pkg.get_msg( gc_application
                                             ,'APP-XXCMN-10154'
                                             ,'TABLE'
                                             ,gv_print_name );
--
    -- --------------------------------------------------
    -- 帳票データが出力できた場合
    -- --------------------------------------------------
    ELSE
      -- ＸＭＬヘッダー出力
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<root>' );
--
      -- ＸＭＬデータ部出力
      <<xml_data_table>>
      FOR i IN 1 .. gt_xml_data_table.COUNT LOOP
        -- 編集したデータをタグに変換
        lv_xml_string := fnc_conv_xml
                          (
                            iv_name   => gt_xml_data_table(i).tag_name    -- タグネーム
                           ,iv_value  => gt_xml_data_table(i).tag_value   -- タグデータ
                           ,ic_type   => gt_xml_data_table(i).tag_type    -- タグタイプ
                          );
        -- ＸＭＬタグ出力
        FND_FILE.PUT_LINE( FND_FILE.OUTPUT, lv_xml_string );
      END LOOP xml_data_table;
--
      -- ＸＭＬフッダー出力
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '</root>' );
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
  END submain;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : コンカレント実行ファイル登録プロシージャ
   **********************************************************************************/
--
  PROCEDURE main(
      errbuf                  OUT    VARCHAR2    -- エラーメッセージ
     ,retcode                 OUT    VARCHAR2    -- エラーコード
     ,iv_yyyymm               IN     VARCHAR2    -- 01 : 処理年月
     ,iv_product_class        IN     VARCHAR2    -- 02 : 商品区分
     ,iv_item_class           IN     VARCHAR2    -- 03 : 品目区分
     ,iv_report_type          IN     VARCHAR2    -- 04 : 帳票種別
     ,iv_whse_code            IN     VARCHAR2    -- 05 : 倉庫コード
     ,iv_group_type           IN     VARCHAR2    -- 06 : 群種別
     ,iv_group_code           IN     VARCHAR2    -- 07 : 群コード
     ,iv_accounting_grp_code  IN     VARCHAR2    -- 08 : 経理群コード
    )
--
--###########################  固定部 START   ###########################
--
  IS
--
    -- ======================================================
    -- 固定ローカル定数
    -- ======================================================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'main'; -- プログラム名
    -- ======================================================
    -- ローカル変数
    -- ======================================================
    lv_errbuf               VARCHAR2(5000);      --   エラー・メッセージ
    lv_retcode              VARCHAR2(1);         --   リターン・コード
    lv_errmsg               VARCHAR2(5000);      --   ユーザー・エラー・メッセージ
--
  BEGIN
--
--###########################  固定部 END   #############################
--
    -- ======================================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ======================================================
    submain(
        iv_yyyymm               => iv_yyyymm              -- 01 : 処理年月
       ,iv_product_class        => iv_product_class       -- 02 : 商品区分
       ,iv_item_class           => iv_item_class          -- 03 : 品目区分
       ,iv_report_type          => iv_report_type         -- 04 : 帳票種別
       ,iv_whse_code            => iv_whse_code           -- 05 : 倉庫コード
       ,iv_group_type           => iv_group_type          -- 06 : 群種別
       ,iv_group_code           => iv_group_code          -- 07 : 群コード
       ,iv_accounting_grp_code  => iv_accounting_grp_code -- 08 : 経理群コード
       ,ov_errbuf               => lv_errbuf              -- エラー・メッセージ
       ,ov_retcode              => lv_retcode             -- リターン・コード#
       ,ov_errmsg               => lv_errmsg);            -- ユーザー・エラー・メッセージ
--
--###########################  固定部 START   #####################################################
--
    -- ======================================================
    -- エラー・メッセージ出力
    -- ======================================================
    IF  ( lv_retcode = gv_status_error )
     OR ( lv_retcode = gv_status_warn  ) THEN
      errbuf := lv_errmsg;
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf);
    END IF;
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
END xxcmn770001c;
/
