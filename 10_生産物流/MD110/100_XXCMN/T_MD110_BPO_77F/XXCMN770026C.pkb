CREATE OR REPLACE PACKAGE BODY xxcmn770026c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxcmn770026c(body)
 * Description      : 出庫実績表
 * MD.050/070       : 月次〆処理(経理)Issue1.0 (T_MD050_BPO_770)
 *                    月次〆処理(経理)Issue1.0 (T_MD070_BPO_77F)
 * Version          : 1.26
 *
 * Program List
 * -------------------------- ----------------------------------------------------------
 *  Name                       Description
 * -------------------------- ----------------------------------------------------------
 *  fnc_conv_xml              FUNCTION  : ＸＭＬタグに変換する。
 *  prc_initialize            PROCEDURE : 前処理(F-1)
 *  prc_get_report_data       PROCEDURE : 明細データ取得(F-1)
 *  prc_create_xml_data       PROCEDURE : ＸＭＬデータ作成(F-2)
 *  submain                   PROCEDURE : メイン処理プロシージャ
 *  main                      PROCEDURE : コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/04/11    1.0   Y.Itou           新規作成
 *  2008/05/16    1.1   T.Endou          不具合ID:77F-09,10対応
 *                                       77F-09 処理年月パラYYYYM入力対応
 *                                       77F-10 担当部署、担当者名の最大文字数制限の修正
 *  2008/05/16    1.2   T.Endou          実際原価取得方法の変更
 *  2008/06/16    1.3   T.Endou          取引区分
 *                                        ・有償
 *                                        ・振替有償_出荷
 *                                        ・商品振替有償_出荷
 *                                       場合は、受注ヘッダアドオン.取引先サイトIDで紐付ける
 *  2008/06/24    1.4   I.Higa           データが無い項目でも０を出力する
 *  2008/06/25    1.5   T.Endou          特定文字列を出力しようとすると、エラーとなり帳票が出力
 *                                       されない現象への対応
 *  2008/07/18    1.6   T.Ikehara        出力件数カウントタグ追加
 *  2008/08/07    1.7   T.Endou          参照ビューの変更「xxcmn_rcv_pay_mst_porc_rma_v」→
 *                                                       「xxcmn_rcv_pay_mst_porc_rma26_v」
 *  2008/09/02    1.8   A.Shiina         仕様不備障害#T_S_475対応
 *  2008/09/22    1.9   A.Shiina         内部変更要求#236対応
 *  2008/10/15    1.10  A.Shiina         T_S_524対応
 *  2008/10/24    1.11  N.Yoshida        T_S_524対応(再対応)
 *  2008/10/24    1.12  T.Yoshida        T_S_524対応(再対応2)
 *                                           変更箇所多数のため、修正履歴を残していないので、
 *                                           修正箇所確認の際は前Verと差分比較すること
 *  2008/11/12    1.13  N.Yoshida        移行データ検証不具合対応(履歴削除)
 *  2008/12/02    1.14  A.Shiina         本番#207対応
 *  2008/12/08    1.15  N.Yoshida        本番障害数値あわせ対応(受注ヘッダの最新フラグを追加)
 *  2008/12/13    1.16  A.Shiina         本番#428対応
 *  2008/12/13    1.17  N.Yoshida        本番#428対応(再対応)
 *  2008/12/16    1.18  A.Shiina         本番#749対応
 *  2008/12/16    1.19  A.Shiina         本番#754対応 -- 対応削除
 *  2008/12/17    1.20  A.Shiina         本番#428対応(PT対応)
 *  2008/12/18    1.21  A.Shiina         本番#799対応
 *  2009/01/09    1.22  A.Shiina         本番#987対応
 *  2009/01/10    1.23  A.Shiina         本番#987対応(再対応)
 *  2009/01/21    1.24  N.Yoshida        本番#1016対応(v1.23の取り止めを含む)
 *  2009/05/29    1.25  Marushita        本番障害1511対応
 *  2009/10/02    1.26  Marushita        本番障害1648対応
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
  -- ======================================================
  -- ユーザー宣言部
  -- ======================================================
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  gv_pkg_name                 CONSTANT VARCHAR2(20) := 'xxcmn770026c' ; -- パッケージ名
  gv_print_name               CONSTANT VARCHAR2(20) := '出庫実績表' ;   -- 帳票名
--
  ------------------------------
  -- 集計グループ
  ------------------------------
  gc_party_sum_desc           CONSTANT VARCHAR2(16) := '出荷先計';
  gc_whse_sum_desc            CONSTANT VARCHAR2(16) := '倉庫計';
  gc_article_div_sum_name     CONSTANT VARCHAR2(16) := '品目区分総計';
  gc_result_post_sum_name     CONSTANT VARCHAR2(16) := '成績部署計';
--
  ------------------------------
  -- 品目カテゴリ関連
  ------------------------------
  gc_cat_set_name_prod_div    CONSTANT VARCHAR2(20) := '商品区分' ;
  gc_cat_set_name_item_div    CONSTANT VARCHAR2(20) := '品目区分' ;
  gc_cat_set_name_crowd       CONSTANT VARCHAR2(20) := '群コード' ;
  gc_cat_set_name_acnt_crowd  CONSTANT VARCHAR2(20) := '経理部用群コード' ;
--
  ------------------------------
  -- 入力パラメータ
  ------------------------------
  gc_param_all_code           CONSTANT VARCHAR2(20) := 'ALL' ;
  gc_param_all_name           CONSTANT VARCHAR2(20) := '集計無し' ;
--
  ------------------------------
  -- エラーメッセージ関連
  ------------------------------
  gc_application              CONSTANT VARCHAR2(5)  := 'XXCMN' ;       -- アプリケーション
  gc_crowd_type_3             CONSTANT VARCHAR2(1)  := '3' ;           -- 郡種別：郡コード
  gc_crowd_type_4             CONSTANT VARCHAR2(1)  := '4' ;           -- 郡種別：経理郡コード
--
  ------------------------------
  -- 項目編集関連
  ------------------------------
  gc_char_ym_format           CONSTANT VARCHAR2(30) := 'YYYYMMDD' ;
  gc_char_m_format            CONSTANT VARCHAR2(30) := 'YYYYMM' ;
  gc_char_dt_format           CONSTANT VARCHAR2(30) := 'YYYY/MM/DD HH24:MI:SS';
--
  ------------------------------
  -- クイックコード・タイプ名
  ------------------------------
  gc_xxcmn_new_acc_div        CONSTANT VARCHAR2(30) := 'XXCMN_NEW_ACCOUNT_DIV';
--
  -- 原価区分
  gc_cost_ac                  CONSTANT VARCHAR2(1) := '0'; --実際原価
  gc_cost_st                  CONSTANT VARCHAR2(1) := '1'; --標準原価
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  -- 入力パラメータ格納用レコード変数
  TYPE rec_param_data  IS RECORD (
    proc_from                 VARCHAR2(6)       -- 01 : 処理年月FROM
   ,proc_to                   VARCHAR2(6)       -- 02 : 処理年月TO
   ,rcv_pay_div               VARCHAR2(5)       -- 03 : 受払区分
   ,rcv_pay_div_name          VARCHAR2(20)      --    : 受払区分名
   ,prod_div                  VARCHAR2(1)       -- 04 : 商品区分
   ,prod_div_name             VARCHAR2(20)      --    : 商品区分名
   ,item_div                  VARCHAR2(1)       -- 05 : 品目区分
   ,item_div_name             VARCHAR2(20)      --    : 品目区分名
   ,result_post               VARCHAR2(4)       -- 06 : 成績部署
   ,result_post_name          VARCHAR2(20)      --    : 成績部署名
   ,whse_code                 VARCHAR2(4)       -- 07 : 倉庫コード
   ,whse_name                 VARCHAR2(20)      --    : 倉庫名
   ,party_code                VARCHAR2(4)       -- 08 : 出荷先コード
   ,party_name                VARCHAR2(20)      --    : 出荷先名
   ,crowd_type                VARCHAR2(1)       -- 09 : 郡種別
   ,crowd_code                VARCHAR2(4)       -- 10 : 郡コード
   ,acnt_crowd_code           VARCHAR2(4)       -- 11 : 経理群コード
   ,output_type               VARCHAR2(20)      -- 12 : 出力種別
  ) ;
--
  -- 出荷実績表データ格納用レコード変数
  TYPE rec_data_type_dtl  IS RECORD (
-- 2008/09/22 v1.9 UPDATE START
/*
    group1_code               VARCHAR2(5)                         -- [集計1]コード
   ,group2_code               VARCHAR2(5)                         -- [集計2]コード
   ,group3_code               VARCHAR2(5)                         -- [集計3]コード
   ,group4_code               VARCHAR2(5)                         -- [集計4]コード
   ,group5_code               VARCHAR2(4)                         -- [集計5]集計郡コード
   ,req_item_code             ic_item_mst_b.item_no%TYPE          -- 出荷品目コード
   ,item_code                 ic_item_mst_b.item_no%TYPE          -- 品目コード
   ,req_item_name             xxcmn_item_mst_b.item_name%TYPE     -- 出荷品目名称
   ,item_name                 xxcmn_item_mst_b.item_name%TYPE     -- 品目名称
*/
    group1_code               VARCHAR2(240)                       -- [集計1]コード
   ,group2_code               VARCHAR2(40)                        -- [集計2]コード
   ,group3_code               VARCHAR2(30)                        -- [集計3]コード
   ,group4_code               VARCHAR2(30)                        -- [集計4]コード
   ,group5_code               VARCHAR2(40)                        -- [集計5]集計郡コード
-- 2008/12/13 v1.16 ADD START
   ,group1_name               VARCHAR2(240)                       -- [集計1]名称
   ,group2_name               VARCHAR2(240)                       -- [集計2]名称
   ,group3_name               VARCHAR2(240)                       -- [集計3]名称
   ,group4_name               VARCHAR2(240)                       -- [集計4]名称
-- 2008/12/13 v1.16 ADD END
   ,req_item_code             VARCHAR2(240)                        -- 出荷品目コード
   ,item_code                 xxcmn_lot_each_item_v.item_code%TYPE        -- 品目コード
   ,req_item_name             xxcmn_item_mst2_v.item_short_name%TYPE      -- 出荷品目名称
   ,item_name                 xxcmn_lot_each_item_v.item_short_name%TYPE  -- 品目名称
-- 2008/09/22 v1.9 UPDATE END
   ,trans_um                  ic_tran_pnd.trans_um%TYPE           -- 取引単位
   ,trans_qty                 NUMBER                              -- 取引数量
   ,actual_price              NUMBER                              -- 実際金額
   ,stnd_price                NUMBER                              -- 標準金額
   ,price                     NUMBER                              -- 有償金額
   ,tax                       NUMBER                              -- 消費税
  ) ;
  TYPE tab_data_type_dtl IS TABLE OF rec_data_type_dtl INDEX BY BINARY_INTEGER ;
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gn_user_id                    fnd_user.user_id%TYPE DEFAULT FND_GLOBAL.USER_ID; -- ユーザーＩＤ
  ------------------------------
  -- ＳＱＬ条件用
  ------------------------------
  gv_user_dept                  xxcmn_locations_all.location_short_name%TYPE;     -- 担当部署
  gv_user_name                  per_all_people_f.per_information18%TYPE;          -- 担当者
  ------------------------------
  -- ＸＭＬ用
  ------------------------------
  gv_report_id                  VARCHAR2(15) ;              -- 帳票ID
  gd_exec_date                  DATE ;                      -- 実施日
--
  gt_main_data                  tab_data_type_dtl ;         -- 取得レコード表
  gt_xml_data_table             XML_DATA ;                  -- ＸＭＬデータタグ表
  gl_xml_idx                    NUMBER DEFAULT 0 ;          -- ＸＭＬデータタグ表のインデックス
--
-- 2008/12/13 v1.16 DELETE START
/*
  gv_gr1_sum_desc               VARCHAR2(16) DEFAULT NULL ; -- 集計１名称
  gv_gr2_sum_desc               VARCHAR2(16) DEFAULT NULL ; -- 集計２名称
  gv_gr3_sum_desc               VARCHAR2(16) DEFAULT NULL ; -- 集計３名称
  gv_gr4_sum_desc               VARCHAR2(16) DEFAULT NULL ; -- 集計４名称
--
*/
-- 2008/12/13 v1.16 DELETE END
  ------------------------------
  -- 取引区分
  ------------------------------
  gv_charge                     xxcmn_lookup_values_v.lookup_code%TYPE; -- 有償;
  gv_trans_charge               xxcmn_lookup_values_v.lookup_code%TYPE; -- 振替有償_出荷';
  gv_item_charge                xxcmn_lookup_values_v.lookup_code%TYPE; -- 商品振替有償_出荷';
--
--#####################  固定共通例外宣言部 START   ####################
--
  --*** 処理部共通例外 ***
  global_process_expt         EXCEPTION ;
  --*** 共通関数例外 ***
  global_api_expt             EXCEPTION ;
  --*** 共通関数OTHERS例外 ***
  global_api_others_expt      EXCEPTION ;
--
  PRAGMA EXCEPTION_INIT(global_api_others_expt,-20000) ;
--
--###########################  固定部 END   ############################
--
  /**********************************************************************************
   * Function Name    : fnc_conv_xml
   * Description      : ＸＭＬタグに変換する。
   ***********************************************************************************/
  FUNCTION fnc_conv_xml (
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
   * Procedure Name   : prc_initialize
   * Description      : 前処理(F-1)
   ***********************************************************************************/
  PROCEDURE prc_initialize (
    ir_param             IN OUT NOCOPY rec_param_data -- 01.入力パラメータ群
   ,ov_errbuf               OUT    VARCHAR2           -- エラー・メッセージ           --# 固定 #
   ,ov_retcode              OUT    VARCHAR2           -- リターン・コード             --# 固定 #
   ,ov_errmsg               OUT    VARCHAR2           -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'prc_initialize' ; -- プログラム名
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
    -- 取引区分
    lc_charge             CONSTANT VARCHAR2(30) := '有償';
    lc_trans_charge       CONSTANT VARCHAR2(30) := '振替有償_出荷';
    lc_item_charge        CONSTANT VARCHAR2(30) := '商品振替有償_出荷';
    lc_xxcmn_dealings_div CONSTANT VARCHAR2(30) := 'XXCMN_DEALINGS_DIV';
--
    -- *** ローカル変数 ***
    -- *** ローカル・例外処理 ***
    get_value_expt        EXCEPTION ;     -- 値取得エラー
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
    gv_user_dept := xxcmn_common_pkg.get_user_dept( gn_user_id ) ;
--
    -- ====================================================
    -- 担当者名取得
    -- ====================================================
    gv_user_name := xxcmn_common_pkg.get_user_name( gn_user_id ) ;
--
    -- ====================================================
    -- 受入区分名取得
    -- ====================================================
    -- 個人選択の場合、名称を取得する
    IF ( ir_param.rcv_pay_div IS NOT NULL ) THEN
      BEGIN
        SELECT SUBSTRB( xlvv.meaning, 1, 20)
        INTO   ir_param.rcv_pay_div_name
        FROM   xxcmn_lookup_values_v xlvv
        WHERE  xlvv.lookup_type  = gc_xxcmn_new_acc_div
        AND    xlvv.lookup_code  = ir_param.rcv_pay_div
        AND    ROWNUM            = 1
        ;
      EXCEPTION
        -- データなし
        WHEN NO_DATA_FOUND THEN
          NULL;
      END;
    END IF;
--
    -- ====================================================
    -- 商品区分名取得
    -- ====================================================
    -- 個人選択の場合、名称を取得する
    IF ( ir_param.prod_div IS NOT NULL ) THEN
      BEGIN
        SELECT SUBSTRB( xcv.description, 1, 20)
        INTO   ir_param.prod_div_name
        FROM   xxcmn_categories_v xcv
        WHERE  xcv.category_set_name = gc_cat_set_name_prod_div
        AND    xcv.segment1          = ir_param.prod_div
        AND    ROWNUM                = 1;
      EXCEPTION
        -- データなし
        WHEN NO_DATA_FOUND THEN
          NULL;
      END;
    END IF;
--
    -- ====================================================
    -- 品目区分名取得
    -- ====================================================
    -- 個人選択の場合、名称を取得する
    IF ( ir_param.item_div IS NOT NULL ) THEN
      BEGIN
        SELECT SUBSTRB( xcv.description, 1, 20)
        INTO   ir_param.item_div_name
        FROM   xxcmn_categories_v xcv
        WHERE  xcv.category_set_name = gc_cat_set_name_item_div
        AND    xcv.segment1          = ir_param.item_div
        AND    ROWNUM                = 1;
      EXCEPTION
        -- データなし
        WHEN NO_DATA_FOUND THEN
          NULL;
      END;
    END IF;
--
    -- ====================================================
    -- 成績部署名取得
    -- ====================================================
    -- [ALL]の場合、名称に固定値「集計無し」を設定
    IF  ( ir_param.result_post IS NOT NULL )
    AND ( ir_param.result_post = gc_param_all_code )
    THEN
      ir_param.result_post_name := gc_param_all_name;
--
    -- 個人選択の場合、名称を取得する
    ELSIF ( ir_param.result_post IS NOT NULL ) THEN
      BEGIN
        SELECT SUBSTRB( xlv.location_short_name, 1, 20)
        INTO   ir_param.result_post_name
        FROM   xxcmn_locations_v xlv
        WHERE  xlv.location_code = ir_param.result_post
        AND    ROWNUM            = 1;
      EXCEPTION
        -- データなし
        WHEN NO_DATA_FOUND THEN
          NULL;
      END;
    END IF;
--
    -- ====================================================
    -- 倉庫名取得
    -- ====================================================
    -- [ALL]の場合、名称に固定値「集計無し」を設定
    IF  ( ir_param.whse_code IS NOT NULL )
    AND ( ir_param.whse_code = gc_param_all_code )
    THEN
      ir_param.whse_name := gc_param_all_name;
--
    -- 個人選択の場合、名称を取得する
    ELSIF ( ir_param.whse_code IS NOT NULL ) THEN
      BEGIN
        SELECT SUBSTRB( iwm.whse_name, 1, 20)
        INTO   ir_param.whse_name
        FROM   ic_whse_mst iwm
        WHERE  iwm.whse_code = ir_param.whse_code
        AND    ROWNUM        = 1;
      EXCEPTION
        -- データなし
        WHEN NO_DATA_FOUND THEN
          NULL;
      END;
    END IF;
--
    -- ====================================================
    -- 出荷先名取得
    -- ====================================================
    -- [ALL]の場合、名称に固定値「集計なし」を設定
    IF  ( ir_param.party_code IS NOT NULL )
    AND ( ir_param.party_code = gc_param_all_code )
    THEN
      ir_param.party_name := gc_param_all_name;
--
    -- 個人選択の場合、名称を取得する
    ELSIF ( ir_param.party_code IS NOT NULL ) THEN
-- 2008/12/16 v1.18 ADD START
     -- 出荷の場合
     IF (ir_param.rcv_pay_div IN ('102', '101', '112')) THEN
-- 2008/12/16 v1.18 ADD END
      BEGIN
        SELECT SUBSTRB( xpv.party_short_name, 1, 20)
        INTO   ir_param.party_name
-- 2009/10/02 MOD START
--        FROM   xxcmn_parties_v xpv
        FROM   xxcmn_cust_accounts3_v xpv
-- 2009/10/02 MOD START
        WHERE  xpv.party_number = ir_param.party_code
        AND    ROWNUM           = 1;
      EXCEPTION
        -- データなし
        WHEN NO_DATA_FOUND THEN
          NULL;
      END;
-- 2008/12/16 v1.18 ADD START
     -- 有償の場合
     ELSIF (ir_param.rcv_pay_div IN ('103', '105', '108')) THEN
      BEGIN
        SELECT SUBSTRB( xvv.vendor_short_name, 1, 20)
        INTO   ir_param.party_name
        FROM   xxcmn_vendors_v xvv
        WHERE  xvv.segment1 = ir_param.party_code
        AND    ROWNUM           = 1;
      EXCEPTION
        -- データなし
        WHEN NO_DATA_FOUND THEN
          NULL;
      END;
--
     END IF;
--
-- 2008/12/16 v1.18 ADD END
    END IF;
--
    -- ====================================================
    -- 取引先区分コード取得（有償）
    -- ====================================================
    BEGIN
      SELECT xlvv.lookup_code
      INTO   gv_charge
      FROM   xxcmn_lookup_values_v xlvv
      WHERE  xlvv.lookup_type = lc_xxcmn_dealings_div
      AND    xlvv.meaning     = lc_charge
      AND    ROWNUM           = 1;
    EXCEPTION
      -- データなし
      WHEN NO_DATA_FOUND THEN
        NULL;
    END;
--
    -- ====================================================
    -- 取引先区分コード取得（振替有償_出荷）
    -- ====================================================
    BEGIN
      SELECT xlvv.lookup_code
      INTO   gv_trans_charge
      FROM   xxcmn_lookup_values_v xlvv
      WHERE  xlvv.lookup_type = lc_xxcmn_dealings_div
      AND    xlvv.meaning     = lc_trans_charge
      AND    ROWNUM           = 1;
    EXCEPTION
      -- データなし
      WHEN NO_DATA_FOUND THEN
        NULL;
    END;
--
    -- ====================================================
    -- 取引先区分コード取得（商品振替有償_出荷）
    -- ====================================================
    BEGIN
      SELECT xlvv.lookup_code
      INTO   gv_item_charge
      FROM   xxcmn_lookup_values_v xlvv
      WHERE  xlvv.lookup_type = lc_xxcmn_dealings_div
      AND    xlvv.meaning     = lc_item_charge
      AND    ROWNUM           = 1;
    EXCEPTION
      -- データなし
      WHEN NO_DATA_FOUND THEN
        NULL;
    END;
--
  EXCEPTION
    --*** 値取得エラー例外 ***
    WHEN get_value_expt THEN
--
      ov_errmsg  := lv_errmsg ;
      ov_errbuf  := lv_errmsg ;
      ov_retcode := lv_retcode ;
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
  END prc_initialize ;
--
  /**********************************************************************************
   * Procedure Name   : prc_get_report_data
   * Description      : 明細データ取得(F-1)
   ***********************************************************************************/
  PROCEDURE prc_get_report_data (
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
    cv_prg_name   CONSTANT  VARCHAR2(100) := 'prc_get_report_data'; -- プログラム名
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
-- 2008/10/24 v1.10 ADD START
    cn_prod_class_id     CONSTANT NUMBER := TO_NUMBER(FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_PROD_CLASS'));
    cn_item_class_id     CONSTANT NUMBER := TO_NUMBER(FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_ITEM_CLASS'));
    cn_crowd_code_id     CONSTANT NUMBER := TO_NUMBER(FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_CROWD_CODE'));
    cn_acnt_crowd_id     CONSTANT NUMBER := TO_NUMBER(FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_ACNT_CROWD_CODE'));
-- 2008/10/24 v1.10 ADD END
--
    -- *** ローカル・変数 ***
-- 2008/10/24 v1.10 UPDATE START
    /*lv_select               VARCHAR2(32000) ;     -- データ取得用ＳＱＬ
    lv_from_omso            VARCHAR2(32000) ;     -- データ取得用ＳＱＬ
    lv_from_porc            VARCHAR2(32000) ;     -- データ取得用ＳＱＬ
    lv_where                VARCHAR2(32000) ;     -- データ取得用ＳＱＬ
    lv_group_by             VARCHAR2(32000) ;     -- データ取得用ＳＱＬ
    lv_order_by             VARCHAR2(32000) ;     -- データ取得用ＳＱＬ
    lv_sql                  VARCHAR2(32000) ;     -- データ取得用ＳＱＬ
    lv_from_porc_charge     VARCHAR2(32000) ;     -- データ取得用ＳＱＬ
    lv_from_omso_charge     VARCHAR2(32000) ;     -- データ取得用ＳＱＬ
    lv_where_no_charge      VARCHAR2(32000) ;     -- データ取得用ＳＱＬ
    lv_where_charge         VARCHAR2(32000) ;     -- データ取得用ＳＱＬ
    lv_from_porc_where      VARCHAR2(32000) ;     -- データ取得用ＳＱＬ
    lv_from_omso_where      VARCHAR2(32000) ;     -- データ取得用ＳＱＬ*/
    lv_where                VARCHAR2(32767) ;     -- データ取得用ＳＱＬ
    lv_where2               VARCHAR2(32767) ;     -- データ取得用ＳＱＬ
    lv_where3               VARCHAR2(32767) ;     -- データ取得用ＳＱＬ
    lv_select_main_start            VARCHAR2(32767) ;     -- データ取得用ＳＱＬ
    lv_select_common                VARCHAR2(32767) ;     -- データ取得用ＳＱＬ
    lv_select_main_end              VARCHAR2(32767) ;     -- データ取得用ＳＱＬ
    lv_select_group1                VARCHAR2(32767) ;     -- データ取得用ＳＱＬ
    lv_select_group1_2              VARCHAR2(32767) ;     -- データ取得用ＳＱＬ
    lv_select_group2                VARCHAR2(32767) ;     -- データ取得用ＳＱＬ
    lv_select_group3                VARCHAR2(32767) ;     -- データ取得用ＳＱＬ
    lv_select_group3_2              VARCHAR2(32767) ;     -- データ取得用ＳＱＬ
    lv_select_group4                VARCHAR2(32767) ;     -- データ取得用ＳＱＬ
    lv_select_group5                VARCHAR2(32767) ;     -- データ取得用ＳＱＬ
    lv_select_group5_2              VARCHAR2(32767) ;     -- データ取得用ＳＱＬ
    lv_select_group6                VARCHAR2(32767) ;     -- データ取得用ＳＱＬ
    lv_select_group7                VARCHAR2(32767) ;     -- データ取得用ＳＱＬ
    lv_select_group7_2              VARCHAR2(32767) ;     -- データ取得用ＳＱＬ
    lv_select_group8                VARCHAR2(32767) ;     -- データ取得用ＳＱＬ
    lv_select_g1_po102_1_hint       VARCHAR2(32767) ;     -- データ取得用ＳＱＬ
    lv_select_g1_po102_2_hint       VARCHAR2(32767) ;     -- データ取得用ＳＱＬ
    lv_select_g1_po102_3_hint       VARCHAR2(32767) ;     -- データ取得用ＳＱＬ
    lv_select_g1_po102_4_hint       VARCHAR2(32767) ;     -- データ取得用ＳＱＬ
    lv_select_g1_po102_6_hint       VARCHAR2(32767) ;     -- データ取得用ＳＱＬ
    lv_select_1_po102               VARCHAR2(32767) ;     -- データ取得用ＳＱＬ
    lv_select_2_po102               VARCHAR2(32767) ;     -- データ取得用ＳＱＬ
    lv_select_g1_po101_1_hint       VARCHAR2(32767) ;     -- データ取得用ＳＱＬ
    lv_select_g1_po101_2_hint       VARCHAR2(32767) ;     -- データ取得用ＳＱＬ
    lv_select_g1_po101_3_hint       VARCHAR2(32767) ;     -- データ取得用ＳＱＬ
    lv_select_g1_po101_4_hint       VARCHAR2(32767) ;     -- データ取得用ＳＱＬ
    lv_select_g1_po101_6_hint       VARCHAR2(32767) ;     -- データ取得用ＳＱＬ
    lv_select_1_po101               VARCHAR2(32767) ;     -- データ取得用ＳＱＬ
    lv_select_2_po101               VARCHAR2(32767) ;     -- データ取得用ＳＱＬ
    lv_select_g1_po112_1_hint       VARCHAR2(32767) ;     -- データ取得用ＳＱＬ
    lv_select_g1_po112_2_hint       VARCHAR2(32767) ;     -- データ取得用ＳＱＬ
    lv_select_g1_po112_3_hint       VARCHAR2(32767) ;     -- データ取得用ＳＱＬ
    lv_select_g1_po112_4_hint       VARCHAR2(32767) ;     -- データ取得用ＳＱＬ
    lv_select_g1_po112_6_hint       VARCHAR2(32767) ;     -- データ取得用ＳＱＬ
    lv_select_1_po112               VARCHAR2(32767) ;     -- データ取得用ＳＱＬ
    lv_select_2_po112               VARCHAR2(32767) ;     -- データ取得用ＳＱＬ
    lv_select_g1_po103x5_1_hint     VARCHAR2(32767) ;     -- データ取得用ＳＱＬ
    lv_select_g1_po103x5_2_hint     VARCHAR2(32767) ;     -- データ取得用ＳＱＬ
    lv_select_g1_po103x5_3_hint     VARCHAR2(32767) ;     -- データ取得用ＳＱＬ
    lv_select_g1_po103x5_4_hint     VARCHAR2(32767) ;     -- データ取得用ＳＱＬ
    lv_select_g1_po103x5_6_hint     VARCHAR2(32767) ;     -- データ取得用ＳＱＬ
    lv_select_1_po103x5             VARCHAR2(32767) ;     -- データ取得用ＳＱＬ
    lv_select_2_po103x5             VARCHAR2(32767) ;     -- データ取得用ＳＱＬ
    lv_select_g1_po103x124_1_hint   VARCHAR2(32767) ;     -- データ取得用ＳＱＬ
    lv_select_g1_po103x124_2_hint   VARCHAR2(32767) ;     -- データ取得用ＳＱＬ
    lv_select_g1_po103x124_3_hint   VARCHAR2(32767) ;     -- データ取得用ＳＱＬ
    lv_select_g1_po103x124_4_hint   VARCHAR2(32767) ;     -- データ取得用ＳＱＬ
    lv_select_g1_po103x124_6_hint   VARCHAR2(32767) ;     -- データ取得用ＳＱＬ
    lv_select_1_po103x124           VARCHAR2(32767) ;     -- データ取得用ＳＱＬ
    lv_select_2_po103x124           VARCHAR2(32767) ;     -- データ取得用ＳＱＬ
    lv_select_g1_po105_1_hint       VARCHAR2(32767) ;     -- データ取得用ＳＱＬ
    lv_select_g1_po105_2_hint       VARCHAR2(32767) ;     -- データ取得用ＳＱＬ
    lv_select_g1_po105_3_hint       VARCHAR2(32767) ;     -- データ取得用ＳＱＬ
    lv_select_g1_po105_4_hint       VARCHAR2(32767) ;     -- データ取得用ＳＱＬ
    lv_select_g1_po105_6_hint       VARCHAR2(32767) ;     -- データ取得用ＳＱＬ
    lv_select_1_po105               VARCHAR2(32767) ;     -- データ取得用ＳＱＬ
    lv_select_2_po105               VARCHAR2(32767) ;     -- データ取得用ＳＱＬ
    lv_select_g1_po108_1_hint       VARCHAR2(32767) ;     -- データ取得用ＳＱＬ
    lv_select_g1_po108_2_hint       VARCHAR2(32767) ;     -- データ取得用ＳＱＬ
    lv_select_g1_po108_3_hint       VARCHAR2(32767) ;     -- データ取得用ＳＱＬ
    lv_select_g1_po108_4_hint       VARCHAR2(32767) ;     -- データ取得用ＳＱＬ
    lv_select_g1_po108_6_hint       VARCHAR2(32767) ;     -- データ取得用ＳＱＬ
    lv_select_1_po108               VARCHAR2(32767) ;     -- データ取得用ＳＱＬ
    lv_select_2_po108               VARCHAR2(32767) ;     -- データ取得用ＳＱＬ
--
    lv_select_g1_om102_1_hint       VARCHAR2(32767) ;     -- データ取得用ＳＱＬ
    lv_select_g1_om102_2_hint       VARCHAR2(32767) ;     -- データ取得用ＳＱＬ
    lv_select_g1_om102_3_hint       VARCHAR2(32767) ;     -- データ取得用ＳＱＬ
    lv_select_g1_om102_4_hint       VARCHAR2(32767) ;     -- データ取得用ＳＱＬ
    lv_select_g1_om102_6_hint       VARCHAR2(32767) ;     -- データ取得用ＳＱＬ
    lv_select_1_om102               VARCHAR2(32767) ;     -- データ取得用ＳＱＬ
    lv_select_2_om102               VARCHAR2(32767) ;     -- データ取得用ＳＱＬ
    lv_select_g1_om101_1_hint       VARCHAR2(32767) ;     -- データ取得用ＳＱＬ
    lv_select_g1_om101_2_hint       VARCHAR2(32767) ;     -- データ取得用ＳＱＬ
    lv_select_g1_om101_3_hint       VARCHAR2(32767) ;     -- データ取得用ＳＱＬ
    lv_select_g1_om101_4_hint       VARCHAR2(32767) ;     -- データ取得用ＳＱＬ
    lv_select_g1_om101_6_hint       VARCHAR2(32767) ;     -- データ取得用ＳＱＬ
    lv_select_1_om101               VARCHAR2(32767) ;     -- データ取得用ＳＱＬ
    lv_select_2_om101               VARCHAR2(32767) ;     -- データ取得用ＳＱＬ
    lv_select_g1_om112_1_hint       VARCHAR2(32767) ;     -- データ取得用ＳＱＬ
    lv_select_g1_om112_2_hint       VARCHAR2(32767) ;     -- データ取得用ＳＱＬ
    lv_select_g1_om112_3_hint       VARCHAR2(32767) ;     -- データ取得用ＳＱＬ
    lv_select_g1_om112_4_hint       VARCHAR2(32767) ;     -- データ取得用ＳＱＬ
    lv_select_g1_om112_6_hint       VARCHAR2(32767) ;     -- データ取得用ＳＱＬ
    lv_select_1_om112               VARCHAR2(32767) ;     -- データ取得用ＳＱＬ
    lv_select_2_om112               VARCHAR2(32767) ;     -- データ取得用ＳＱＬ
    lv_select_g1_om103x5_1_hint     VARCHAR2(32767) ;     -- データ取得用ＳＱＬ
    lv_select_g1_om103x5_2_hint     VARCHAR2(32767) ;     -- データ取得用ＳＱＬ
    lv_select_g1_om103x5_3_hint     VARCHAR2(32767) ;     -- データ取得用ＳＱＬ
    lv_select_g1_om103x5_4_hint     VARCHAR2(32767) ;     -- データ取得用ＳＱＬ
    lv_select_g1_om103x5_6_hint     VARCHAR2(32767) ;     -- データ取得用ＳＱＬ
    lv_select_1_om103x5             VARCHAR2(32767) ;     -- データ取得用ＳＱＬ
    lv_select_2_om103x5             VARCHAR2(32767) ;     -- データ取得用ＳＱＬ
    lv_select_g1_om103x124_1_hint   VARCHAR2(32767) ;     -- データ取得用ＳＱＬ
    lv_select_g1_om103x124_2_hint   VARCHAR2(32767) ;     -- データ取得用ＳＱＬ
    lv_select_g1_om103x124_3_hint   VARCHAR2(32767) ;     -- データ取得用ＳＱＬ
    lv_select_g1_om103x124_4_hint   VARCHAR2(32767) ;     -- データ取得用ＳＱＬ
    lv_select_g1_om103x124_6_hint   VARCHAR2(32767) ;     -- データ取得用ＳＱＬ
    lv_select_1_om103x124           VARCHAR2(32767) ;     -- データ取得用ＳＱＬ
    lv_select_2_om103x124           VARCHAR2(32767) ;     -- データ取得用ＳＱＬ
    lv_select_g1_om105_1_hint       VARCHAR2(32767) ;     -- データ取得用ＳＱＬ
    lv_select_g1_om105_2_hint       VARCHAR2(32767) ;     -- データ取得用ＳＱＬ
    lv_select_g1_om105_3_hint       VARCHAR2(32767) ;     -- データ取得用ＳＱＬ
    lv_select_g1_om105_4_hint       VARCHAR2(32767) ;     -- データ取得用ＳＱＬ
    lv_select_g1_om105_6_hint       VARCHAR2(32767) ;     -- データ取得用ＳＱＬ
    lv_select_1_om105               VARCHAR2(32767) ;     -- データ取得用ＳＱＬ
    lv_select_2_om105               VARCHAR2(32767) ;     -- データ取得用ＳＱＬ
    lv_select_g1_om108_1_hint       VARCHAR2(32767) ;     -- データ取得用ＳＱＬ
    lv_select_g1_om108_2_hint       VARCHAR2(32767) ;     -- データ取得用ＳＱＬ
    lv_select_g1_om108_3_hint       VARCHAR2(32767) ;     -- データ取得用ＳＱＬ
    lv_select_g1_om108_4_hint       VARCHAR2(32767) ;     -- データ取得用ＳＱＬ
    lv_select_g1_om108_6_hint       VARCHAR2(32767) ;     -- データ取得用ＳＱＬ
    lv_select_1_om108               VARCHAR2(32767) ;     -- データ取得用ＳＱＬ
    lv_select_2_om108               VARCHAR2(32767) ;     -- データ取得用ＳＱＬ
--
    lt_lkup_code            fnd_lookup_values.lookup_code%TYPE;
    --lv_crowd_c_name         VARCHAR2(20) ;        -- 郡コードカラム名(抽出条件用)
--
    -- *** ローカル・カーソル ***
    TYPE   ref_cursor IS REF CURSOR ;
    lc_ref ref_cursor ;
--
    get_cur01    ref_cursor;
-- 2008/10/24 v1.10 UPDATE END
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
-- 2008/10/24 v1.10 UPDATE START
-- 2008/10/24 v1.10 ADD START  
    SELECT flv.lookup_code
    INTO   lt_lkup_code
    FROM   xxcmn_lookup_values_v flv
    WHERE  flv.lookup_type = 'XXCMN_CONSUMPTION_TAX_RATE'
    AND    ROWNUM          = 1;
--
    lv_select_main_start :=
       ' SELECT'
    || '  mst.group1_code AS group1_code' -- [集計1]コード
    || ' ,mst.group2_code AS group2_code' -- [集計2]コード
    || ' ,mst.group3_code AS group3_code' -- [集計3]コード
    || ' ,mst.group4_code AS group4_code' -- [集計4]コード
    || ' ,mst.group5_code AS group5_code' -- [集計5]コード
-- 2008/12/13 v1.16 ADD START
    || ' ,mst.group1_name AS group1_name' -- [集計1]名称
    || ' ,mst.group2_name AS group2_name' -- [集計2]名称
    || ' ,mst.group3_name AS group3_name' -- [集計3]名称
    || ' ,mst.group4_name AS group4_name' -- [集計4]名称
-- 2008/12/13 v1.16 ADD END
    || ' ,mst.request_item_code AS request_item_code' -- 出荷品目コード
    || ' ,mst.item_code AS item_code' -- 品目コード
    || ' ,MAX(mst.request_item_name) AS request_item_name' -- 出荷品目名称
    || ' ,MAX(mst.item_name) AS item_name' -- 取引単位
    || ' ,MAX(mst.trans_um) AS trans_um' -- 取引数量
    || ' ,SUM(mst.trans_qty) AS trans_qty' -- 取引数量
    || ' ,SUM(mst.actual_price) AS actual_price' -- 実際金額
    || ' ,SUM(mst.stnd_price) AS stnd_price' -- 標準金額
    || ' ,SUM(mst.price) AS price' -- 有償金額
    || ' ,SUM(mst.price * DECODE( NVL(mst.tax,0),0,0,(mst.tax/100) ) )'
    || ' AS tax' -- 消費税率 
    || ' FROM ('
       ;
-- 
 -- 共通SELECT
    lv_select_common :=
       ' xola.request_item_code AS request_item_code'
    || ' ,ximb2.item_short_name AS request_item_name'
    || ' ,iimb.item_no AS item_code'
    || ' ,ximb.item_short_name AS item_name'
    || ' ,itp.trans_um AS trans_um'
    || ' ,itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)'
    || ' AS trans_qty' -- 取引数量 
-- 2008/12/02 v1.14 UPDATE START
/*
    || ' ,(' 
    || ' ROUND((CASE iimb2.attribute15'
    || ' WHEN ''1'' THEN xsupv.stnd_unit_price' 
    || ' ELSE DECODE('
    || ' iimb2.lot_ctl' 
    || ' ,1,(SELECT DECODE('
    || ' SUM(NVL(xlc.trans_qty,0))' 
    || ' ,0,0' 
    || ' ,SUM(xlc.trans_qty * xlc.unit_ploce) / SUM(NVL(xlc.trans_qty,0)))'
    || ' FROM xxcmn_lot_cost xlc'
    || ' WHERE xlc.item_id = iimb2.item_id),xsupv.stnd_unit_price)' 
    || ' END) * (itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)))'
    || ' ) AS actual_price' -- 実際金額
*/
    || ' ,(' 
    || ' ROUND((CASE iimb2.attribute15'
-- 2009/01/16 v1.23 UPDATE START
-- 2009/01/22 v1.24 UPDATE START
    || '          WHEN ''1'' THEN NVL(xsupv.stnd_unit_price, 0) ' 
--    || ' WHEN ''1'' THEN ' 
--    || ' NVL((SELECT xsupv.stnd_unit_price '
--    || ' FROM xxcmn_stnd_unit_price_v xsupv '
--    || ' WHERE xsupv.item_id = itp.item_id '
--    || ' AND xsupv.start_date_active <= TRUNC(itp.trans_date) '
--    || ' AND xsupv.end_date_active >= TRUNC(itp.trans_date) '
--    || ' ), 0) '
-- 2009/01/22 v1.24 UPDATE END
-- 2009/01/16 v1.23 UPDATE END
    || '          ELSE DECODE(iimb2.lot_ctl' 
    || '                     ,1,NVL(xlc.unit_ploce, 0)' 
-- 2009/01/16 v1.23 UPDATE START
-- 2009/01/22 v1.24 UPDATE START
    || '                     ,NVL(xsupv.stnd_unit_price, 0))' 
--    || ' ,NVL((SELECT xsupv.stnd_unit_price '
--    || ' FROM xxcmn_stnd_unit_price_v xsupv '
--    || ' WHERE xsupv.item_id = itp.item_id '
--    || ' AND xsupv.start_date_active <= TRUNC(itp.trans_date) '
--    || ' AND xsupv.end_date_active >= TRUNC(itp.trans_date) '
--    || ' ), 0)) '
-- 2009/01/22 v1.24 UPDATE END
-- 2009/01/16 v1.23 UPDATE END
    || '        END) * (itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)))' 
    || ' ) AS actual_price' -- 実際金額
-- 2008/12/02 v1.14 UPDATE END
-- 2009/01/16 v1.23 UPDATE START
-- 2009/01/22 v1.24 UPDATE START
    || ' ,ROUND(NVL(xsupv.stnd_unit_price, 0) * (itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div))'
--    || ' ,ROUND( '
--    || ' (NVL((SELECT xsupv.stnd_unit_price '
--    || ' FROM xxcmn_stnd_unit_price_v xsupv '
--    || ' WHERE xsupv.item_id = itp.item_id '
--    || ' AND xsupv.start_date_active <= TRUNC(itp.trans_date) '
--    || ' AND xsupv.end_date_active >= TRUNC(itp.trans_date) '
--    || ' ), 0) '
--    || ' ) * (itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div))'
-- 2009/01/22 v1.24 UPDATE END
-- 2009/01/16 v1.23 UPDATE END
    || ' ) AS stnd_price' -- 標準金額
-- 2008/12/02 v1.14 UPDATE START
/*
    || ' ,(CASE iimb.lot_ctl'
    || ' WHEN 0 THEN ROUND((xola.unit_price * (itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div))))'
    || ' ELSE ROUND(((SELECT DECODE('
    || ' SUM(NVL(xlc.trans_qty,0))' 
    || ' ,0,0' 
    || ' ,SUM(xlc.trans_qty * xlc.unit_ploce) / SUM(NVL(xlc.trans_qty,0)))'
    || ' FROM xxcmn_lot_cost xlc'
    || ' WHERE xlc.item_id = itp.item_id ) * (itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)))'
    || ' )' 
    || ' END) AS price' -- 有償金額
*/
-- 2008/12/18 v1.21 UPDATE START
--    || ' ,xola.unit_price * (itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)) AS price' -- 有償金額
    || ' ,ROUND(xola.unit_price * (itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div))) AS price' -- 有償金額
-- 2008/12/18 v1.21 UPDATE END
-- 2008/12/02 v1.14 UPDATE END
    || ' ,TO_NUMBER(''' || lt_lkup_code    || ''') AS tax' 
    ;
-- 
 -- 共通SELECT group1 
    lv_select_group1 :=
       ' ,ooha.attribute11 AS group1_code' -- 成績部署 
    || ' ,mcb2.segment1 AS group2_code' -- 品目区分
    || ' ,itp.whse_code AS group3_code' -- 倉庫
--    || ' ,xpv.party_number AS group4_code' -- 出荷先
    || ' ,hca.account_number AS group4_code' -- 出荷先
    || ' ,mcb3.segment1 AS group5_code' -- 郡コード or 経理郡コード 
-- 2008/12/13 v1.16 ADD START
--    || ' ,xla.location_short_name  AS group1_name' -- 成績部署名称
    || ' ,NULL                    AS group1_name' -- 成績部署名称
--    || ' ,mct.description         AS group2_name' -- 品目区分名称
    || ' ,NULL                    AS group2_name' -- 品目区分名称
-- 2009/01/21 v1.24 UPDATE START
--    || ' ,NULL                    AS group3_name' -- 倉庫名称
    || ' ,iwm.whse_name           AS group3_name' -- 倉庫名称
-- 2009/01/21 v1.24 UPDATE END
-- 2008/12/17 v1.20 UPDATE START
--    || ' ,xpv.party_short_name    AS group4_name' -- 出荷先名称
    || ' ,xp.party_short_name    AS group4_name' -- 出荷先名称
-- 2008/12/17 v1.20 UPDATE END
-- 2008/12/13 v1.16 ADD END
    ;
--
-- 2008/12/13 v1.16 ADD START
 -- 共通SELECT group1_2
    lv_select_group1_2 :=
       ' ,ooha.attribute11 AS group1_code' -- 成績部署 
    || ' ,mcb2.segment1 AS group2_code' -- 品目区分
    || ' ,itp.whse_code AS group3_code' -- 倉庫
    || ' ,pv.segment1 AS group4_code' -- 支給先
    || ' ,mcb3.segment1 AS group5_code' -- 郡コード or 経理郡コード 
--    || ' ,xla.location_short_name  AS group1_name' -- 成績部署名称
    || ' ,NULL                    AS group1_name' -- 成績部署名称
--    || ' ,mct.description         AS group2_name' -- 品目区分名称
    || ' ,NULL                    AS group2_name' -- 品目区分名称
-- 2009/01/21 v1.24 UPDATE START
--    || ' ,NULL                    AS group3_name' -- 倉庫名称
    || ' ,iwm.whse_name           AS group3_name' -- 倉庫名称
-- 2009/01/21 v1.24 UPDATE END
    || ' ,pv.vendor_name          AS group4_name' -- 支給先名称
    ;
--
-- 2008/12/13 v1.16 ADD END
 -- 共通SELECT group2 
    lv_select_group2 :=
       ' ,ooha.attribute11 AS group1_code' -- 成績部署 
    || ' ,mcb2.segment1 AS group2_code' -- 品目区分
    || ' ,itp.whse_code AS group3_code' -- 倉庫
    || ' ,NULL AS group4_code' -- NULL
    || ' ,mcb3.segment1 AS group5_code' -- 郡コード or 経理郡コード 
-- 2008/12/13 v1.16 ADD START
--    || ' ,xla.location_short_name  AS group1_name' -- 成績部署名称
    || ' ,NULL                    AS group1_name' -- 成績部署名称
--    || ' ,mct.description         AS group2_name' -- 品目区分名称
    || ' ,NULL                    AS group2_name' -- 品目区分名称
-- 2009/01/21 v1.24 UPDATE START
--    || ' ,NULL                    AS group3_name' -- 倉庫名称
    || ' ,iwm.whse_name           AS group3_name' -- 倉庫名称
-- 2009/01/21 v1.24 UPDATE END
    || ' ,NULL                    AS group4_name' -- NULL
-- 2008/12/13 v1.16 ADD END
    ;
-- 
 -- 共通SELECT group3 
    lv_select_group3 :=
       ' ,ooha.attribute11 AS group1_code' -- 成績部署 
    || ' ,mcb2.segment1 AS group2_code' -- 品目区分
--    || ' ,xpv.party_number AS group3_code' -- 出荷先
    || ' ,hca.account_number AS group3_code' -- 出荷先
    || ' ,NULL AS group4_code' -- NULL
    || ' ,mcb3.segment1 AS group5_code' -- 郡コード or 経理郡コード 
-- 2008/12/13 v1.16 ADD START
--    || ' ,xla.location_short_name  AS group1_name' -- 成績部署名称
    || ' ,NULL                    AS group1_name' -- 成績部署名称
--    || ' ,mct.description         AS group2_name' -- 品目区分名称
    || ' ,NULL                    AS group2_name' -- 品目区分名称
-- 2008/12/17 v1.20 UPDATE START
--    || ' ,xpv.party_short_name    AS group3_name' -- 出荷先名称
    || ' ,xp.party_short_name    AS group3_name' -- 出荷先名称
-- 2008/12/17 v1.20 UPDATE END
    || ' ,NULL                    AS group4_name' -- NULL
-- 2008/12/13 v1.16 ADD END
    ;
-- 
-- 2008/12/13 v1.16 ADD START
 -- 共通SELECT group3_2
    lv_select_group3_2 :=
       ' ,ooha.attribute11 AS group1_code' -- 成績部署 
    || ' ,mcb2.segment1 AS group2_code' -- 品目区分
    || ' ,pv.segment1 AS group3_code' -- 支給先
    || ' ,NULL AS group4_code' -- NULL
    || ' ,mcb3.segment1 AS group5_code' -- 郡コード or 経理郡コード 
--    || ' ,xla.location_short_name  AS group1_name' -- 成績部署名称
    || ' ,NULL                    AS group1_name' -- 成績部署名称
--    || ' ,mct.description         AS group2_name' -- 品目区分名称
    || ' ,NULL                    AS group2_name' -- 品目区分名称
    || ' ,pv.vendor_name          AS group3_name' -- 支給先名称
    || ' ,NULL                    AS group4_name' -- NULL
    ;
--
-- 2008/12/13 v1.16 ADD END
 -- 共通SELECT group4 
    lv_select_group4 :=
       ' ,ooha.attribute11 AS group1_code' -- 成績部署 
    || ' ,mcb2.segment1 AS group2_code' -- 品目区分
    || ' ,NULL AS group3_code' -- NULL
    || ' ,NULL AS group4_code' -- NULL
    || ' ,mcb3.segment1 AS group5_code' -- 郡コード or 経理郡コード 
-- 2008/12/13 v1.16 ADD START
--    || ' ,xla.location_short_name  AS group1_name' -- 成績部署名称
    || ' ,NULL                    AS group1_name' -- 成績部署名称
--    || ' ,mct.description         AS group2_name' -- 品目区分名称
    || ' ,NULL                    AS group2_name' -- 品目区分名称
    || ' ,NULL                    AS group3_name' -- NULL
    || ' ,NULL                    AS group4_name' -- NULL
-- 2008/12/13 v1.16 ADD END
    ;
-- 
 -- 共通SELECT group5 
    lv_select_group5 :=
       ' ,mcb2.segment1 AS group1_code' -- 品目区分 
    || ' ,itp.whse_code AS group2_code' -- 倉庫
--    || ' ,xpv.party_number AS group3_code' -- 出荷先
    || ' ,hca.account_number AS group3_code' -- 出荷先
    || ' ,NULL AS group4_code' -- NULL
    || ' ,mcb3.segment1 AS group5_code' -- 郡コード or 経理郡コード 
-- 2008/12/13 v1.16 ADD START
--    || ' ,mct.description         AS group1_name' -- 品目区分名称
    || ' ,NULL                    AS group1_name' -- 品目区分名称
-- 2009/01/21 v1.24 UPDATE START
--    || ' ,NULL                    AS group2_name' -- 倉庫名称
    || ' ,iwm.whse_name           AS group2_name' -- 倉庫名称
-- 2009/01/21 v1.24 UPDATE END
-- 2008/12/17 v1.20 UPDATE START
--    || ' ,xpv.party_short_name    AS group3_name' -- 出荷先名称
    || ' ,xp.party_short_name    AS group3_name' -- 出荷先名称
-- 2008/12/17 v1.20 UPDATE END
    || ' ,NULL                    AS group4_name' -- NULL
-- 2008/12/13 v1.16 ADD END
    ;
--
-- 2008/12/13 v1.16 ADD START
 -- 共通SELECT group5_2
    lv_select_group5_2 :=
       ' ,mcb2.segment1 AS group1_code' -- 品目区分 
    || ' ,itp.whse_code AS group2_code' -- 倉庫
    || ' ,pv.segment1 AS group3_code' -- 支給先
    || ' ,NULL AS group4_code' -- NULL
    || ' ,mcb3.segment1 AS group5_code' -- 郡コード or 経理郡コード 
--    || ' ,mct.description         AS group1_name' -- 品目区分名称
    || ' ,NULL                    AS group1_name' -- 品目区分名称
-- 2009/01/21 v1.24 UPDATE START
--    || ' ,NULL                    AS group2_name' -- 倉庫名称
    || ' ,iwm.whse_name           AS group2_name' -- 倉庫名称
-- 2009/01/21 v1.24 UPDATE END
    || ' ,pv.vendor_name          AS group3_name' -- 支給先名称
    || ' ,NULL                    AS group4_name' -- NULL
    ;
-- 2008/12/13 v1.16 ADD END
-- 
 -- 共通SELECT group6 
    lv_select_group6 :=
       ' ,mcb2.segment1 AS group1_code' -- 品目区分 
    || ' ,itp.whse_code AS group2_code' -- 倉庫
    || ' ,NULL AS group3_code' -- NULL
    || ' ,NULL AS group4_code' -- NULL
    || ' ,mcb3.segment1 AS group5_code' -- 郡コード or 経理郡コード 
-- 2008/12/13 v1.16 ADD START
--    || ' ,mct.description         AS group1_name' -- 品目区分名称
    || ' ,NULL                    AS group1_name' -- 品目区分名称
-- 2009/01/21 v1.24 UPDATE START
--    || ' ,NULL                    AS group2_name' -- 倉庫名称
    || ' ,iwm.whse_name           AS group2_name' -- 倉庫名称
-- 2009/01/21 v1.24 UPDATE END
    || ' ,NULL                    AS group3_name' -- NULL
    || ' ,NULL                    AS group4_name' -- NULL
-- 2008/12/13 v1.16 ADD END
    ;
-- 
 -- 共通SELECT group7 
    lv_select_group7 :=
       ' ,mcb2.segment1 AS group1_code' -- 品目区分 
--    || ' ,xpv.party_number AS group2_code' -- 出荷先
    || ' ,hca.account_number AS group2_code' -- 出荷先
    || ' ,NULL AS group3_code' -- NULL
    || ' ,NULL AS group4_code' -- NULL
    || ' ,mcb3.segment1 AS group5_code' -- 郡コード or 経理郡コード 
-- 2008/12/13 v1.16 ADD START
--    || ' ,mct.description         AS group1_name' -- 品目区分名称
    || ' ,NULL                    AS group1_name' -- 品目区分名称
-- 2008/12/17 v1.20 UPDATE START
--    || ' ,xpv.party_short_name    AS group2_name' -- 出荷先名称
    || ' ,xp.party_short_name    AS group2_name' -- 出荷先名称
-- 2008/12/17 v1.20 UPDATE END
    || ' ,NULL                    AS group3_name' -- NULL
    || ' ,NULL                    AS group4_name' -- NULL
-- 2008/12/13 v1.16 ADD END
    ;
-- 
-- 2008/12/13 v1.16 ADD START
 -- 共通SELECT group7_2
    lv_select_group7_2 :=
       ' ,mcb2.segment1 AS group1_code' -- 品目区分 
    || ' ,pv.segment1 AS group2_code' -- 支給先
    || ' ,NULL AS group3_code' -- NULL
    || ' ,NULL AS group4_code' -- NULL
    || ' ,mcb3.segment1 AS group5_code' -- 郡コード or 経理郡コード 
--    || ' ,mct.description         AS group1_name' -- 品目区分名称
    || ' ,NULL                    AS group1_name' -- 品目区分名称
    || ' ,pv.vendor_name          AS group2_name' -- 支給先名称
    || ' ,NULL                    AS group3_name' -- NULL
    || ' ,NULL                    AS group4_name' -- NULL
    ;
--
-- 2008/12/13 v1.16 ADD END
 -- 共通SELECT group8 
    lv_select_group8 :=
       ' ,mcb2.segment1 AS group1_code' -- 品目区分 
    || ' ,NULL AS group2_code' -- NULL
    || ' ,NULL AS group3_code' -- NULL
    || ' ,NULL AS group4_code' -- NULL
    || ' ,mcb3.segment1 AS group5_code' -- 郡コード or 経理郡コード 
-- 2008/12/13 v1.16 ADD START
--    || ' ,mct.description         AS group1_name' -- 品目区分名称
    || ' ,NULL                    AS group1_name' -- 品目区分名称
    || ' ,NULL                    AS group2_name' -- NULL
    || ' ,NULL                    AS group3_name' -- NULL
    || ' ,NULL                    AS group4_name' -- NULL
-- 2008/12/13 v1.16 ADD END
    ;
-- 
    lv_select_main_end :=
       ' ) mst' 
    || ' GROUP BY '
    || ' mst.group1_code' -- [集計1]コード
    || ' ,mst.group2_code' -- [集計2]コード
    || ' ,mst.group3_code' -- [集計3]コード
    || ' ,mst.group4_code' -- [集計4]コード
    || ' ,mst.group5_code' -- [集計5]コード
-- 2008/12/13 v1.16 ADD START
    || ' ,mst.group1_name' -- [集計1]名称
    || ' ,mst.group2_name' -- [集計2]名称
    || ' ,mst.group3_name' -- [集計3]名称
    || ' ,mst.group4_name' -- [集計4]名称
-- 2008/12/13 v1.16 ADD END
    || ' ,mst.request_item_code' -- 出荷品目コード
    || ' ,mst.item_code' -- 品目コード
    || ' ORDER BY '
    || ' mst.group1_code' -- [集計1]コード
    || ' ,mst.group2_code' -- [集計2]コード
    || ' ,mst.group3_code' -- [集計3]コード
    || ' ,mst.group4_code' -- [集計4]コード
    || ' ,mst.group5_code' -- [集計5]コード
    || ' ,mst.request_item_code' -- 出荷品目コード
    || ' ,mst.item_code' -- 品目コード
    ;
-- 
 --===============================================================
 -- GROUP1、2、4、6、7
 --===============================================================
-- 
 -- PORC_102
 -- パターン:1
    lv_select_1_po102 :=
       ' FROM ' 
    || '  ic_tran_pnd itp'
    || ' ,rcv_shipment_lines rsl'
--    || ' ,oe_order_lines_all oola'
    || ' ,oe_order_headers_all ooha'
    || ' ,oe_transaction_types_all otta'
    || ' ,xxwsh_order_headers_all xoha'
    || ' ,xxwsh_order_lines_all xola'
    || ' ,gmi_item_categories gic1'
    || ' ,mtl_categories_b mcb1'
    || ' ,gmi_item_categories gic2'
    || ' ,mtl_categories_b mcb2'
    || ' ,gmi_item_categories gic3'
    || ' ,mtl_categories_b mcb3'
    || ' ,ic_item_mst_b iimb'
    || ' ,xxcmn_item_mst_b ximb'
    || ' ,ic_lots_mst ilm'
    || ' ,xxcmn_lot_cost xlc'
    || ' ,ic_item_mst_b iimb2'
    || ' ,xxcmn_item_mst_b ximb2'
-- 2009/01/16 v1.23 DELETE START
-- 2009/01/22 v1.24 UPDATE START
    || ' ,xxcmn_stnd_unit_price_v xsupv' -- 標準原価情報View 
-- 2009/01/22 v1.24 UPDATE END
-- 2009/01/16 v1.23 DELETE END
-- 2008/12/17 v1.20 UPDATE START
/*
    || ' ,xxcmn_party_sites2_v xpsv' -- パーティサイト情報View2 
-- 2008/12/13 v1.17 N.Yoshida mod start
--    || ' ,xxcmn_parties2_v xpv' -- パーティ情報View2 
--    || ' ,xxcmn_cust_accounts2_v xpv' -- 顧客情報View2 
    || ' ,xxcmn_parties xpv' -- 顧客情報View2 
*/
    || ' ,hz_party_sites hps'
    || ' ,xxcmn_parties xp'
-- 2008/12/17 v1.20 UPDATE END
    || ' ,hz_cust_accounts hca'
-- 2008/12/13 v1.17 N.Yoshida mod start
    || ' ,xxcmn_rcv_pay_mst xrpm'
-- 2008/12/13 v1.16 ADD START
-- 2009/01/21 v1.24 N.Yoshida ADD START
    || ' ,ic_whse_mst iwm'
-- 2009/01/21 v1.24 N.Yoshida ADD END
--    || ' ,hr_locations_all  hla '
--    || ' ,xxcmn_locations_all xla '
--    || ' ,mtl_categories_tl mct '
-- 2008/12/13 v1.16 ADD END
    || ' WHERE itp.doc_type = ''PORC''' -- 文書タイプ(PORC)
    || ' AND itp.completed_ind = 1' -- 完了フラグ
--    || ' AND itp.trans_date >= FND_DATE.STRING_TO_DATE(''' || ir_param.proc_from    || ''',''yyyymm'')'
--    || ' AND itp.trans_date < ADD_MONTHS( FND_DATE.STRING_TO_DATE(''' || ir_param.proc_to    || ''',''yyyymm''),1)'
    || ' AND xoha.latest_external_flag = ''Y'''
    || ' AND xoha.arrival_date >= FND_DATE.STRING_TO_DATE(''' || ir_param.proc_from    || ''',''yyyymm'')'
    || ' AND xoha.arrival_date < ADD_MONTHS( FND_DATE.STRING_TO_DATE(''' || ir_param.proc_to    || ''',''yyyymm''),1)'
    || ' AND xoha.req_status = ''04''' 
    || ' AND gic1.item_id = itp.item_id' 
    || ' AND gic1.category_set_id = ''' || cn_prod_class_id    || ''''
    || ' AND gic1.category_id = mcb1.category_id' 
    || ' AND mcb1.segment1 = ''' || ir_param.prod_div    || ''''
    || ' AND gic2.item_id = itp.item_id' 
    || ' AND gic2.category_set_id = ''' || cn_item_class_id    || ''''
    || ' AND gic2.category_id = mcb2.category_id' 
    || ' AND mcb2.segment1 = ''5''' 
    || ' AND gic3.item_id = itp.item_id' 
    || ' AND gic3.category_id = mcb3.category_id' 
    || ' AND xrpm.item_div_ahead = mcb2.segment1' 
    || ' AND xrpm.item_div_origin = mcb2.segment1' 
    || ' AND ilm.item_id = itp.item_id' 
    || ' AND ilm.lot_id = itp.lot_id' 
    || ' AND iimb.item_id = ilm.item_id' 
    || ' AND xlc.item_id(+) = ilm.item_id' 
    || ' AND xlc.lot_id (+) = ilm.lot_id'
    || ' AND ximb.item_id = iimb.item_id' 
    || ' AND ximb.start_date_active <= TRUNC(itp.trans_date)' 
    || ' AND ximb.end_date_active >= TRUNC(itp.trans_date)' 
    || ' AND rsl.shipment_header_id = itp.doc_id' 
    || ' AND rsl.line_num = itp.doc_line' 
--    || ' AND oola.header_id = rsl.oe_order_header_id' 
--    || ' AND oola.line_id = rsl.oe_order_line_id' 
--    || ' AND ooha.header_id = rsl.oe_order_header_id' 
    || ' AND otta.transaction_type_id = ooha.order_type_id' 
    || ' AND ((otta.attribute4 <> ''2'')' 
    || ' OR (otta.attribute4 IS NULL))' 
--    || ' AND xoha.header_id = ooha.header_id' 
--    || ' AND xola.line_id = rsl.oe_order_line_id' 
    || ' AND rsl.oe_order_header_id  = xola.header_id' 
    || ' AND rsl.oe_order_line_id    = xola.line_id' 
    || ' AND xoha.header_id          = ooha.header_id' 
    || ' AND xola.order_header_id    = xoha.order_header_id' 
    || ' AND xola.request_item_code = xola.shipping_item_code' 
    || ' AND iimb2.item_no = xola.request_item_code' 
    || ' AND ximb2.item_id = iimb2.item_id' 
    || ' AND ximb2.start_date_active <= TRUNC(itp.trans_date)' 
    || ' AND ximb2.end_date_active >= TRUNC(itp.trans_date)' 
-- 2009/01/09 v1.22 UPDATE START
--    || ' AND xsupv.item_id = itp.item_id' 
--    || ' AND xsupv.start_date_active <= TRUNC(itp.trans_date)' 
--    || ' AND xsupv.end_date_active >= TRUNC(itp.trans_date)' 
-- 2009/01/16 v1.23 DELETE START
---- 2009/01/22 v1.24 UPDATE START
--    || ' AND xsupv.item_id(+) = itp.item_id' 
--    || ' AND NVL(xsupv.start_date_active, TRUNC(itp.trans_date)) <= TRUNC(itp.trans_date)' 
--    || ' AND NVL(xsupv.end_date_active, TRUNC(itp.trans_date)) >= TRUNC(itp.trans_date)' 
---- 2009/01/22 v1.24 UPDATE START
-- 2009/05/29 MOD START v1.24 DEL
    || ' AND xsupv.item_id(+) = itp.item_id' 
    || ' AND NVL(xsupv.start_date_active, TRUNC(xoha.arrival_date)) <= TRUNC(xoha.arrival_date)' 
    || ' AND NVL(xsupv.end_date_active, TRUNC(xoha.arrival_date)) >= TRUNC(xoha.arrival_date)' 
-- 2009/05/29 MOD END
-- 2009/01/16 v1.23 DELETE END
-- 2009/01/09 v1.22 UPDATE END
-- 2008/12/17 v1.20 UPDATE START
/*
    || ' AND xpsv.party_site_id = xoha.result_deliver_to_id' 
    || ' AND xpsv.start_date_active <= TRUNC(itp.trans_date)' 
    || ' AND xpsv.end_date_active >= TRUNC(itp.trans_date)' 
    || ' AND xpsv.party_id = xpv.party_id' 
    || ' AND xpv.start_date_active <= TRUNC(itp.trans_date)' 
    || ' AND xpv.end_date_active >= TRUNC(itp.trans_date)' 
*/
    || ' AND hps.party_site_id     = xoha.result_deliver_to_id' 
    || ' AND xp.party_id           = hps.party_id' 
    || ' AND xp.start_date_active <= TRUNC(itp.trans_date)' 
    || ' AND xp.end_date_active   >= TRUNC(itp.trans_date)' 
    || ' AND hca.party_id          = hps.party_id' 
-- 2008/12/17 v1.20 UPDATE END
    || ' AND xrpm.doc_type = itp.doc_type' 
    || ' AND xrpm.doc_type = ''PORC'''
    || ' AND xrpm.source_document_code = ''RMA'''
    || ' AND xrpm.dealings_div = ''102''' 
    || ' AND xrpm.shipment_provision_div = otta.attribute1' 
    || ' AND xrpm.break_col_06 IS NOT NULL'
-- 2009/01/21 v1.24 N.Yoshida ADD START
    || ' AND itp.whse_code = iwm.whse_code'
-- 2009/01/21 v1.24 N.Yoshida ADD END
-- 2008/12/13 v1.16 ADD START
--    || ' AND hla.location_code  = ooha.attribute11'
--    || ' AND hla.location_id    = xla.location_id'
--    || ' AND hla.inactive_date  IS NULL'
--    || ' AND xla.start_date_active <= TRUNC(SYSDATE)'
--    || ' AND xla.end_date_active   >= TRUNC(SYSDATE)'
--    || ' AND mct.category_id   = mcb2.category_id'
-- 2008/12/17 v1.20 DELETE START
--    || ' AND hca.party_id =  xpv.party_id'
-- 2008/12/17 v1.20 DELETE END
--    || ' AND xl.start_date_active  <= TRUNC(SYSDATE)'
--    || ' AND xl.end_date_active    >= TRUNC(SYSDATE)'
--    || ' AND mct.source_lang   = ''JA'''
--    || ' AND mct.language      = ''JA'''
-- 2008/12/13 v1.16 ADD END
    ;
--
-- 
 -- PORC_101
 -- パターン:1
    lv_select_1_po101 :=
       ' FROM ' 
    || ' ic_tran_pnd itp'
    || ' ,rcv_shipment_lines rsl'
--    || ' ,oe_order_lines_all oola'
    || ' ,oe_order_headers_all ooha'
    || ' ,oe_transaction_types_all otta'
    || ' ,xxwsh_order_headers_all xoha'
    || ' ,xxwsh_order_lines_all xola'
    || ' ,gmi_item_categories gic1'
    || ' ,mtl_categories_b mcb1'
    || ' ,gmi_item_categories gic2'
    || ' ,mtl_categories_b mcb2'
    || ' ,gmi_item_categories gic3'
    || ' ,mtl_categories_b mcb3'
    || ' ,ic_item_mst_b iimb'
    || ' ,xxcmn_item_mst_b ximb'
    || ' ,ic_lots_mst ilm'
    || ' ,xxcmn_lot_cost xlc'
    || ' ,ic_item_mst_b iimb2'
    || ' ,xxcmn_item_mst_b ximb2'
-- 2009/01/16 v1.23 DELETE START
-- 2009/01/22 v1.24 UPDATE START
    || ' ,xxcmn_stnd_unit_price_v xsupv' -- 標準原価情報View 
-- 2009/01/22 v1.24 UPDATE END
-- 2009/01/16 v1.23 DELETE END
-- 2008/12/17 v1.20 UPDATE START
/*
    || ' ,xxcmn_party_sites2_v xpsv' -- パーティサイト情報View2 
-- 2008/12/13 v1.17 N.Yoshida mod start
--    || ' ,xxcmn_parties2_v xpv' -- パーティ情報View2 
--    || ' ,xxcmn_cust_accounts2_v xpv' -- 顧客情報View2 
    || ' ,xxcmn_parties xpv' -- 顧客情報View2 
*/
    || ' ,hz_party_sites hps'
    || ' ,xxcmn_parties xp'
-- 2008/12/17 v1.20 UPDATE END
    || ' ,hz_cust_accounts hca'
-- 2008/12/13 v1.17 N.Yoshida mod start
    || ' ,xxcmn_rcv_pay_mst xrpm'
-- 2008/12/13 v1.16 ADD START
-- 2009/01/21 v1.24 N.Yoshida ADD START
    || ' ,ic_whse_mst iwm'
-- 2009/01/21 v1.24 N.Yoshida ADD END
--    || ' ,hr_locations_all  hla '
--    || ' ,xxcmn_locations_all xla '
--    || ' ,mtl_categories_tl mct '
-- 2008/12/13 v1.16 ADD END
    || ' WHERE itp.doc_type = ''PORC''' -- 文書タイプ(PORC)
    || ' AND itp.completed_ind = 1' -- 完了フラグ
--    || ' AND itp.trans_date >= FND_DATE.STRING_TO_DATE(''' || ir_param.proc_from    || ''',''yyyymm'')'
--    || ' AND itp.trans_date < ADD_MONTHS( FND_DATE.STRING_TO_DATE(''' || ir_param.proc_to    || ''',''yyyymm''),1)'
    || ' AND xoha.latest_external_flag = ''Y'''
    || ' AND xoha.arrival_date >= FND_DATE.STRING_TO_DATE(''' || ir_param.proc_from    || ''',''yyyymm'')'
    || ' AND xoha.arrival_date < ADD_MONTHS( FND_DATE.STRING_TO_DATE(''' || ir_param.proc_to    || ''',''yyyymm''),1)'
    || ' AND xoha.req_status = ''04''' 
    || ' AND gic1.item_id = itp.item_id' 
    || ' AND gic1.category_set_id = ''' || cn_prod_class_id    || ''''
    || ' AND gic1.category_id = mcb1.category_id' 
    || ' AND mcb1.segment1 = ''' || ir_param.prod_div    || ''''
    || ' AND gic2.item_id = itp.item_id' 
    || ' AND gic2.category_set_id = ''' || cn_item_class_id    || ''''
    || ' AND gic2.category_id = mcb2.category_id' 
    || ' AND mcb2.segment1 IN (''1'',''2'',''4'')' 
    || ' AND gic3.item_id = itp.item_id' 
    || ' AND gic3.category_id = mcb3.category_id' 
    || ' AND ilm.item_id = itp.item_id' 
    || ' AND ilm.lot_id = itp.lot_id' 
    || ' AND iimb.item_id = ilm.item_id' 
    || ' AND xlc.item_id(+) = ilm.item_id' 
    || ' AND xlc.lot_id (+) = ilm.lot_id'
    || ' AND ximb.item_id = iimb.item_id' 
    || ' AND ximb.start_date_active <= TRUNC(itp.trans_date)' 
    || ' AND ximb.end_date_active >= TRUNC(itp.trans_date)' 
    || ' AND rsl.shipment_header_id = itp.doc_id' 
    || ' AND rsl.line_num = itp.doc_line' 
--    || ' AND oola.header_id = rsl.oe_order_header_id' 
--    || ' AND oola.line_id = rsl.oe_order_line_id' 
--    || ' AND ooha.header_id = rsl.oe_order_header_id' 
    || ' AND otta.transaction_type_id = ooha.order_type_id' 
    || ' AND ((otta.attribute4 <> ''2'')' 
    || ' OR (otta.attribute4 IS NULL))' 
--    || ' AND xoha.header_id = ooha.header_id' 
--    || ' AND xola.line_id = rsl.oe_order_line_id' 
    || ' AND rsl.oe_order_header_id  = xola.header_id' 
    || ' AND rsl.oe_order_line_id    = xola.line_id' 
    || ' AND xoha.header_id          = ooha.header_id' 
    || ' AND xola.order_header_id    = xoha.order_header_id' 
    || ' AND xola.request_item_code = xola.shipping_item_code' 
    || ' AND iimb2.item_no = xola.request_item_code' 
    || ' AND ximb2.item_id = iimb2.item_id' 
    || ' AND ximb2.start_date_active <= TRUNC(itp.trans_date)' 
    || ' AND ximb2.end_date_active >= TRUNC(itp.trans_date)' 
-- 2009/01/09 v1.22 UPDATE START
--    || ' AND xsupv.item_id = itp.item_id' 
--    || ' AND xsupv.start_date_active <= TRUNC(itp.trans_date)' 
--    || ' AND xsupv.end_date_active >= TRUNC(itp.trans_date)' 
-- 2009/01/16 v1.23 DELETE START
---- 2009/01/22 v1.24 UPDATE START
--    || ' AND xsupv.item_id(+) = itp.item_id' 
--    || ' AND NVL(xsupv.start_date_active, TRUNC(itp.trans_date)) <= TRUNC(itp.trans_date)' 
--    || ' AND NVL(xsupv.end_date_active, TRUNC(itp.trans_date)) >= TRUNC(itp.trans_date)' 
---- 2009/01/22 v1.24 UPDATE END
-- 2009/05/29 MOD START v1.24 DEL
    || ' AND xsupv.item_id(+) = itp.item_id' 
    || ' AND NVL(xsupv.start_date_active, TRUNC(xoha.arrival_date)) <= TRUNC(xoha.arrival_date)' 
    || ' AND NVL(xsupv.end_date_active, TRUNC(xoha.arrival_date)) >= TRUNC(xoha.arrival_date)' 
-- 2009/05/29 MOD END
-- 2009/01/16 v1.23 DELETE END
-- 2009/01/09 v1.22 UPDATE END
-- 2008/12/17 v1.20 UPDATE START
/*
    || ' AND xpsv.party_site_id = xoha.result_deliver_to_id' 
    || ' AND xpsv.start_date_active <= TRUNC(itp.trans_date)' 
    || ' AND xpsv.end_date_active >= TRUNC(itp.trans_date)' 
    || ' AND xpsv.party_id = xpv.party_id' 
    || ' AND xpv.start_date_active <= TRUNC(itp.trans_date)' 
    || ' AND xpv.end_date_active >= TRUNC(itp.trans_date)' 
*/
    || ' AND hps.party_site_id     = xoha.result_deliver_to_id' 
    || ' AND xp.party_id           = hps.party_id' 
    || ' AND xp.start_date_active <= TRUNC(itp.trans_date)' 
    || ' AND xp.end_date_active   >= TRUNC(itp.trans_date)' 
    || ' AND hca.party_id          = hps.party_id' 
-- 2008/12/17 v1.20 UPDATE END
    || ' AND xrpm.doc_type = itp.doc_type' 
    || ' AND xrpm.doc_type = ''PORC'''
    || ' AND xrpm.source_document_code = ''RMA'''
    || ' AND xrpm.dealings_div = ''101''' 
    || ' AND xrpm.shipment_provision_div = otta.attribute1' 
    || ' AND xrpm.break_col_06 IS NOT NULL'
-- 2009/01/21 v1.24 N.Yoshida ADD START
    || ' AND itp.whse_code = iwm.whse_code'
-- 2009/01/21 v1.24 N.Yoshida ADD END
-- 2008/12/13 v1.16 ADD START
--    || ' AND hla.location_code  = ooha.attribute11'
--    || ' AND hla.location_id    = xla.location_id'
--    || ' AND mct.category_id   = mcb2.category_id'
--    || ' AND hla.inactive_date  IS NULL'
--    || ' AND xla.start_date_active <= TRUNC(SYSDATE)'
--    || ' AND xla.end_date_active   >= TRUNC(SYSDATE)'
-- 2008/12/17 v1.20 DELETE START
--    || ' AND hca.party_id =  xpv.party_id'
-- 2008/12/17 v1.20 DELETE END
--    || ' AND mct.source_lang   = ''JA'''
--    || ' AND mct.language      = ''JA'''
-- 2008/12/13 v1.16 ADD END
    ;
-- 
 -- PORC_112
 -- パターン:1
    lv_select_1_po112 :=
       ' FROM ' 
    || ' ic_tran_pnd itp'
    || ' ,rcv_shipment_lines rsl'
--    || ' ,oe_order_lines_all oola'
    || ' ,oe_order_headers_all ooha'
    || ' ,oe_transaction_types_all otta'
    || ' ,xxwsh_order_headers_all xoha'
    || ' ,xxwsh_order_lines_all xola'
    || ' ,gmi_item_categories gic1'
    || ' ,mtl_categories_b mcb1'
    || ' ,gmi_item_categories gic2'
    || ' ,mtl_categories_b mcb2'
    || ' ,gmi_item_categories gic3'
    || ' ,mtl_categories_b mcb3'
    || ' ,gmi_item_categories gic4'
    || ' ,mtl_categories_b mcb4'
    || ' ,ic_item_mst_b iimb'
    || ' ,xxcmn_item_mst_b ximb'
    || ' ,ic_lots_mst ilm'
    || ' ,xxcmn_lot_cost xlc'
    || ' ,ic_item_mst_b iimb2'
    || ' ,xxcmn_item_mst_b ximb2'
--    || ' ,ic_item_mst_b iimb3'
-- 2009/01/16 v1.12 DELETE START
-- 2009/01/22 v1.24 UPDATE START
    || ' ,xxcmn_stnd_unit_price_v xsupv' -- 標準原価情報View 
-- 2009/01/22 v1.24 UPDATE END
-- 2009/01/16 v1.12 DELETE END
-- 2008/12/17 v1.20 UPDATE START
/*
    || ' ,xxcmn_party_sites2_v xpsv' -- パーティサイト情報View2 
-- 2008/12/13 v1.17 N.Yoshida mod start
--    || ' ,xxcmn_parties2_v xpv' -- パーティ情報View2 
--    || ' ,xxcmn_cust_accounts2_v xpv' -- 顧客情報View2 
    || ' ,xxcmn_parties xpv' -- 顧客情報View2 
*/
    || ' ,hz_party_sites hps'
    || ' ,xxcmn_parties xp'
-- 2008/12/17 v1.20 UPDATE END
    || ' ,hz_cust_accounts hca'
-- 2008/12/13 v1.17 N.Yoshida mod start
    || ' ,xxcmn_rcv_pay_mst xrpm'
-- 2008/12/13 v1.16 ADD START
-- 2009/01/21 v1.24 N.Yoshida ADD START
    || ' ,ic_whse_mst iwm'
-- 2009/01/21 v1.24 N.Yoshida ADD END
--    || ' ,hr_locations_all  hla '
--    || ' ,xxcmn_locations_all xla '
--    || ' ,mtl_categories_tl mct '
-- 2008/12/13 v1.16 ADD END
    || ' WHERE itp.doc_type = ''PORC''' -- 文書タイプ(PORC)
    || ' AND itp.completed_ind = 1' -- 完了フラグ
--    || ' AND itp.trans_date >= FND_DATE.STRING_TO_DATE(''' || ir_param.proc_from    || ''',''yyyymm'')'
--    || ' AND itp.trans_date < ADD_MONTHS( FND_DATE.STRING_TO_DATE(''' || ir_param.proc_to    || ''',''yyyymm''),1)'
    || ' AND xoha.latest_external_flag = ''Y'''
    || ' AND xoha.arrival_date >= FND_DATE.STRING_TO_DATE(''' || ir_param.proc_from    || ''',''yyyymm'')'
    || ' AND xoha.arrival_date < ADD_MONTHS( FND_DATE.STRING_TO_DATE(''' || ir_param.proc_to    || ''',''yyyymm''),1)'
    || ' AND xoha.req_status = ''04''' 
    || ' AND gic1.item_id = iimb2.item_id' 
    || ' AND gic1.category_set_id = ''' || cn_prod_class_id    || ''''
    || ' AND gic1.category_id = mcb1.category_id' 
    || ' AND mcb1.segment1 = ''' || ir_param.prod_div    || ''''
    || ' AND gic2.item_id = iimb2.item_id' 
    || ' AND gic2.category_set_id = ''' ||cn_item_class_id    || '''' 
    || ' AND gic2.category_id = mcb2.category_id' 
    || ' AND mcb2.segment1 = ''5''' 
    || ' AND gic3.item_id = iimb2.item_id' 
    || ' AND gic3.category_id = mcb3.category_id' 
    || ' AND gic4.item_id = itp.item_id' 
    || ' AND gic4.category_set_id = ''' || cn_item_class_id    || ''''
    || ' AND gic4.category_id = mcb4.category_id' 
    || ' AND mcb4.segment1 IN (''1'',''2'',''4'')' 
    || ' AND xrpm.item_div_ahead = mcb2.segment1' 
    || ' AND ilm.item_id = itp.item_id' 
    || ' AND ilm.lot_id = itp.lot_id' 
    || ' AND iimb.item_id = ilm.item_id' 
    || ' AND xlc.item_id(+) = ilm.item_id' 
    || ' AND xlc.lot_id (+) = ilm.lot_id'
    || ' AND ximb.item_id = iimb.item_id' 
    || ' AND ximb.start_date_active <= TRUNC(itp.trans_date)' 
    || ' AND ximb.end_date_active >= TRUNC(itp.trans_date)' 
    || ' AND rsl.shipment_header_id = itp.doc_id' 
    || ' AND rsl.line_num = itp.doc_line' 
--    || ' AND oola.header_id = rsl.oe_order_header_id' 
--    || ' AND oola.line_id = rsl.oe_order_line_id' 
--    || ' AND ooha.header_id = rsl.oe_order_header_id' 
    || ' AND otta.transaction_type_id = ooha.order_type_id' 
    || ' AND ((otta.attribute4 <> ''2'')' 
    || ' OR (otta.attribute4 IS NULL))' 
--    || ' AND xoha.header_id = ooha.header_id' 
--    || ' AND xola.line_id = rsl.oe_order_line_id' 
    || ' AND ooha.header_id = rsl.oe_order_header_id' 
    || ' AND xoha.header_id = rsl.oe_order_header_id' 
    || ' AND xoha.header_id = ooha.header_id' 
    || ' AND xola.order_header_id = xoha.order_header_id' 
    || ' AND xola.line_id = rsl.oe_order_line_id' 
    || ' AND iimb2.item_no = xola.request_item_code' 
    || ' AND ximb2.item_id = iimb2.item_id' 
    || ' AND ximb2.start_date_active <= TRUNC(itp.trans_date)' 
    || ' AND ximb2.end_date_active >= TRUNC(itp.trans_date)' 
-- 2009/01/09 v1.22 UPDATE START
--    || ' AND xsupv.item_id = iimb2.item_id' 
--    || ' AND xsupv.start_date_active <= TRUNC(itp.trans_date)' 
--    || ' AND xsupv.end_date_active >= TRUNC(itp.trans_date)' 
-- 2009/01/16 v1.12 DELETE START
---- 2009/01/22 v1.24 UPDATE START
--    || ' AND xsupv.item_id(+) = iimb2.item_id' 
--    || ' AND NVL(xsupv.start_date_active, TRUNC(itp.trans_date)) <= TRUNC(itp.trans_date)' 
--    || ' AND NVL(xsupv.end_date_active, TRUNC(itp.trans_date)) >= TRUNC(itp.trans_date)' 
---- 2009/01/22 v1.24 UPDATE START
-- 2009/05/29 MOD START v1.24 DEL
    || ' AND xsupv.item_id(+) = iimb2.item_id' 
    || ' AND NVL(xsupv.start_date_active, TRUNC(xoha.arrival_date)) <= TRUNC(xoha.arrival_date)' 
    || ' AND NVL(xsupv.end_date_active, TRUNC(xoha.arrival_date)) >= TRUNC(xoha.arrival_date)' 
-- 2009/05/29 MOD END
-- 2009/01/16 v1.12 DELETE END
-- 2009/01/09 v1.22 UPDATE END
-- 2008/12/17 v1.20 UPDATE START
/*
    || ' AND xpsv.party_site_id = xoha.result_deliver_to_id' 
    || ' AND xpsv.start_date_active <= TRUNC(itp.trans_date)' 
    || ' AND xpsv.end_date_active >= TRUNC(itp.trans_date)' 
    || ' AND xpsv.party_id = xpv.party_id' 
    || ' AND xpv.start_date_active <= TRUNC(itp.trans_date)' 
    || ' AND xpv.end_date_active >= TRUNC(itp.trans_date)' 
*/
    || ' AND hps.party_site_id     = xoha.result_deliver_to_id' 
    || ' AND xp.party_id           = hps.party_id' 
    || ' AND xp.start_date_active <= TRUNC(itp.trans_date)' 
    || ' AND xp.end_date_active   >= TRUNC(itp.trans_date)' 
    || ' AND hca.party_id          = hps.party_id' 
-- 2008/12/17 v1.20 UPDATE END
    || ' AND xrpm.doc_type = itp.doc_type' 
    || ' AND xrpm.doc_type = ''PORC'''
    || ' AND xrpm.source_document_code = ''RMA'''
    || ' AND xrpm.dealings_div = ''112''' 
    || ' AND xrpm.shipment_provision_div = otta.attribute1' 
    || ' AND xrpm.break_col_06 IS NOT NULL'
-- 2009/01/21 v1.24 N.Yoshida ADD START
    || ' AND itp.whse_code = iwm.whse_code'
-- 2009/01/21 v1.24 N.Yoshida ADD END
-- 2008/12/13 v1.16 ADD START
--    || ' AND hla.location_code  = ooha.attribute11'
--    || ' AND hla.location_id    = xla.location_id'
--    || ' AND hla.inactive_date  IS NULL'
--    || ' AND xla.start_date_active <= TRUNC(SYSDATE)'
--    || ' AND xla.end_date_active   >= TRUNC(SYSDATE)'
--    || ' AND mct.category_id   = mcb2.category_id'
-- 2008/12/17 v1.20 DELETe START
--    || ' AND hca.party_id =  xpv.party_id'
-- 2008/12/17 v1.20 DELETe END
--    || ' AND mct.source_lang   = ''JA'''
--    || ' AND mct.language      = ''JA'''
-- 2008/12/13 v1.16 ADD END
    ;
-- 
 -- PORC_103_5
 -- パターン:1
    lv_select_1_po103x5 :=
       ' FROM ' 
    || ' ic_tran_pnd itp'
    || ' ,rcv_shipment_lines rsl'
--    || ' ,oe_order_lines_all oola'
    || ' ,oe_order_headers_all ooha'
    || ' ,oe_transaction_types_all otta'
    || ' ,xxwsh_order_headers_all xoha'
    || ' ,xxwsh_order_lines_all xola'
    || ' ,gmi_item_categories gic1'
    || ' ,mtl_categories_b mcb1'
    || ' ,gmi_item_categories gic2'
    || ' ,mtl_categories_b mcb2'
    || ' ,gmi_item_categories gic3'
    || ' ,mtl_categories_b mcb3'
    || ' ,ic_item_mst_b iimb'
    || ' ,xxcmn_item_mst_b ximb'
    || ' ,ic_lots_mst ilm'
    || ' ,xxcmn_lot_cost xlc'
    || ' ,ic_item_mst_b iimb2'
    || ' ,xxcmn_item_mst_b ximb2'
-- 2009/01/16 v1.23 DELETE START
-- 2009/01/22 v1.24 UPDATE START
    || ' ,xxcmn_stnd_unit_price_v xsupv' -- 標準原価情報View 
-- 2009/01/22 v1.24 UPDATE END
-- 2009/01/16 v1.23 DELETE END
    || ' ,po_vendor_sites_all pvsa' -- 仕入先サイトマスタ 
    || ' ,po_vendors pv' -- 仕入先マスタ 
-- 2008/12/13 v1.17 DELETE START
--    || ' ,xxcmn_parties2_v xpv' -- パーティ情報View2 
-- 2008/12/13 v1.17 DELETE END
    || ' ,xxcmn_rcv_pay_mst xrpm'
-- 2008/12/13 v1.16 ADD START
-- 2009/01/21 v1.24 N.Yoshida ADD START
    || ' ,ic_whse_mst iwm'
-- 2009/01/21 v1.24 N.Yoshida ADD END
--    || ' ,hr_locations_all  hla '
--    || ' ,xxcmn_locations_all xla '
--    || ' ,mtl_categories_tl mct '
-- 2008/12/13 v1.16 ADD END
    || ' WHERE itp.doc_type = ''PORC''' -- 文書タイプ(PORC)
    || ' AND itp.completed_ind = 1' -- 完了フラグ
--    || ' AND itp.trans_date >= FND_DATE.STRING_TO_DATE(''' || ir_param.proc_from    || ''',''yyyymm'')'
--    || ' AND itp.trans_date < ADD_MONTHS( FND_DATE.STRING_TO_DATE(''' || ir_param.proc_to    || ''',''yyyymm''),1)'
    || ' AND xoha.latest_external_flag = ''Y'''
    || ' AND xoha.arrival_date >= FND_DATE.STRING_TO_DATE(''' || ir_param.proc_from    || ''',''yyyymm'')'
    || ' AND xoha.arrival_date < ADD_MONTHS( FND_DATE.STRING_TO_DATE(''' || ir_param.proc_to    || ''',''yyyymm''),1)'
    || ' AND xoha.req_status = ''08''' 
    || ' AND gic1.item_id = itp.item_id' 
    || ' AND gic1.category_set_id = ''' || cn_prod_class_id    || ''''
    || ' AND gic1.category_id = mcb1.category_id' 
    || ' AND mcb1.segment1 = ''' || ir_param.prod_div    || ''''
    || ' AND gic2.item_id = itp.item_id' 
    || ' AND gic2.category_set_id = ''' || cn_item_class_id    || ''''
    || ' AND gic2.category_id = mcb2.category_id' 
    || ' AND mcb2.segment1 = ''5''' 
    || ' AND gic3.item_id = itp.item_id' 
    || ' AND gic3.category_id = mcb3.category_id' 
    || ' AND ilm.item_id = itp.item_id' 
    || ' AND ilm.lot_id = itp.lot_id' 
    || ' AND iimb.item_id = ilm.item_id' 
    || ' AND xlc.item_id(+) = ilm.item_id' 
    || ' AND xlc.lot_id (+) = ilm.lot_id'
    || ' AND ximb.item_id = iimb.item_id' 
    || ' AND ximb.start_date_active <= TRUNC(itp.trans_date)' 
    || ' AND ximb.end_date_active >= TRUNC(itp.trans_date)' 
    || ' AND rsl.shipment_header_id = itp.doc_id' 
    || ' AND rsl.line_num = itp.doc_line' 
--    || ' AND oola.header_id = rsl.oe_order_header_id' 
--    || ' AND oola.line_id = rsl.oe_order_line_id' 
--    || ' AND ooha.header_id = rsl.oe_order_header_id' 
    || ' AND otta.transaction_type_id = ooha.order_type_id' 
    || ' AND ((otta.attribute4 <> ''2'')' 
    || ' OR (otta.attribute4 IS NULL))' 
--    || ' AND xoha.header_id = ooha.header_id' 
--    || ' AND xola.line_id = rsl.oe_order_line_id' 
    || ' AND rsl.oe_order_header_id  = xola.header_id' 
    || ' AND rsl.oe_order_line_id    = xola.line_id' 
    || ' AND xoha.header_id          = ooha.header_id' 
    || ' AND xola.order_header_id    = xoha.order_header_id' 
    || ' AND xola.request_item_code = xola.shipping_item_code' 
    || ' AND iimb2.item_no = xola.request_item_code' 
    || ' AND ximb2.item_id = iimb2.item_id' 
    || ' AND ximb2.start_date_active <= TRUNC(itp.trans_date)' 
    || ' AND ximb2.end_date_active >= TRUNC(itp.trans_date)' 
-- 2009/01/09 v1.22 UPDATE START
--    || ' AND xsupv.item_id = itp.item_id' 
--    || ' AND xsupv.start_date_active <= TRUNC(itp.trans_date)' 
--    || ' AND xsupv.end_date_active >= TRUNC(itp.trans_date)' 
-- 2009/01/16 v1.23 DELETE START
---- 2009/01/22 v1.24 UPDATE START
--    || ' AND xsupv.item_id(+) = itp.item_id' 
--    || ' AND NVL(xsupv.start_date_active, TRUNC(itp.trans_date)) <= TRUNC(itp.trans_date)' 
--    || ' AND NVL(xsupv.end_date_active, TRUNC(itp.trans_date)) >= TRUNC(itp.trans_date)' 
---- 2009/01/22 v1.24 UPDATE START
-- 2009/05/29 MOD START v1.24 DEL
    || ' AND xsupv.item_id(+) = itp.item_id' 
    || ' AND NVL(xsupv.start_date_active, TRUNC(xoha.arrival_date)) <= TRUNC(xoha.arrival_date)' 
    || ' AND NVL(xsupv.end_date_active, TRUNC(xoha.arrival_date)) >= TRUNC(xoha.arrival_date)' 
-- 2009/05/29 MOD END
-- 2009/01/16 v1.23 DELETE END
-- 2009/01/09 v1.22 UPDATE END
    || ' AND pvsa.vendor_site_id = xoha.vendor_site_id' 
    || ' AND pv.vendor_id = pvsa.vendor_id' 
-- 2008/12/13 v1.16 UPDATE START
--    || ' AND pv.customer_num = xpv.account_number' 
--    || ' AND xoha.customer_id = xpv.party_id' 
-- 2008/12/13 v1.16 UPDATE END
-- 2008/12/13 v1.17 DELETE START
--    || ' AND xpv.start_date_active <= TRUNC(itp.trans_date)' 
--    || ' AND xpv.end_date_active >= TRUNC(itp.trans_date)' 
-- 2008/12/13 v1.17 DELETE START
    || ' AND xrpm.doc_type = itp.doc_type' 
    || ' AND xrpm.doc_type = ''PORC'''
    || ' AND xrpm.source_document_code = ''RMA'''
    || ' AND xrpm.dealings_div = ''103''' 
    || ' AND xrpm.shipment_provision_div = otta.attribute1' 
    || ' AND xrpm.ship_prov_rcv_pay_category = otta.attribute11' 
    || ' AND (xrpm.item_div_origin = mcb2.segment1' 
    || ' OR xrpm.item_div_origin IS NULL)' 
    || ' AND xrpm.break_col_06 IS NOT NULL'
    || ' AND xrpm.item_div_origin = mcb2.segment1' 
-- 2009/01/21 v1.24 N.Yoshida ADD START
    || ' AND itp.whse_code = iwm.whse_code'
-- 2009/01/21 v1.24 N.Yoshida ADD END
-- 2008/12/13 v1.16 ADD START
--    || ' AND hla.location_code  = ooha.attribute11'
--    || ' AND hla.location_id    = xla.location_id'
--    || ' AND mct.category_id   = mcb2.category_id'
--    || ' AND hla.inactive_date  IS NULL'
--    || ' AND xla.start_date_active <= TRUNC(SYSDATE)'
--    || ' AND xla.end_date_active   >= TRUNC(SYSDATE)'
--    || ' AND mct.source_lang   = ''JA'''
--    || ' AND mct.language      = ''JA'''
-- 2008/12/13 v1.16 ADD END
    ;
-- 
 -- PORC_103_124
 -- パターン:1
    lv_select_1_po103x124 :=
       ' FROM ' 
    || ' ic_tran_pnd itp'
    || ' ,rcv_shipment_lines rsl'
--    || ' ,oe_order_lines_all oola'
    || ' ,oe_order_headers_all ooha'
    || ' ,oe_transaction_types_all otta'
    || ' ,xxwsh_order_headers_all xoha'
    || ' ,xxwsh_order_lines_all xola'
    || ' ,gmi_item_categories gic1'
    || ' ,mtl_categories_b mcb1'
    || ' ,gmi_item_categories gic2'
    || ' ,mtl_categories_b mcb2'
    || ' ,gmi_item_categories gic3'
    || ' ,mtl_categories_b mcb3'
    || ' ,ic_item_mst_b iimb'
    || ' ,xxcmn_item_mst_b ximb'
    || ' ,ic_lots_mst ilm'
    || ' ,xxcmn_lot_cost xlc'
    || ' ,ic_item_mst_b iimb2'
    || ' ,xxcmn_item_mst_b ximb2'
-- 2009/01/16 v1.23 DELETE START
-- 2009/01/22 v1.24 UPDATE START
    || ' ,xxcmn_stnd_unit_price_v xsupv' -- 標準原価情報View 
-- 2009/01/22 v1.24 UPDATE END
-- 2009/01/16 v1.23 DELETE END
    || ' ,po_vendor_sites_all pvsa' -- 仕入先サイトマスタ 
    || ' ,po_vendors pv' -- 仕入先マスタ 
-- 2008/12/13 v1.17 DELETE START
--    || ' ,xxcmn_parties2_v xpv' -- パーティ情報View2 
-- 2008/12/13 v1.17 DELETE END
    || ' ,xxcmn_rcv_pay_mst xrpm'
-- 2008/12/13 v1.16 ADD START
-- 2009/01/21 v1.24 N.Yoshida ADD START
    || ' ,ic_whse_mst iwm'
-- 2009/01/21 v1.24 N.Yoshida ADD END
--    || ' ,hr_locations_all  hla '
--    || ' ,xxcmn_locations_all xla '
--    || ' ,mtl_categories_tl mct '
-- 2008/12/13 v1.16 ADD END
    || ' WHERE itp.doc_type = ''PORC''' -- 文書タイプ(PORC)
    || ' AND itp.completed_ind = 1' -- 完了フラグ
--    || ' AND itp.trans_date >= FND_DATE.STRING_TO_DATE(''' || ir_param.proc_from    || ''',''yyyymm'')'
--    || ' AND itp.trans_date < ADD_MONTHS( FND_DATE.STRING_TO_DATE(''' || ir_param.proc_to    || ''',''yyyymm''),1)'
    || ' AND xoha.latest_external_flag = ''Y'''
    || ' AND xoha.arrival_date >= FND_DATE.STRING_TO_DATE(''' || ir_param.proc_from    || ''',''yyyymm'')'
    || ' AND xoha.arrival_date < ADD_MONTHS( FND_DATE.STRING_TO_DATE(''' || ir_param.proc_to    || ''',''yyyymm''),1)'
    || ' AND xoha.req_status = ''08''' 
    || ' AND gic1.item_id = itp.item_id' 
    || ' AND gic1.category_set_id = ''' || cn_prod_class_id    || ''''
    || ' AND gic1.category_id = mcb1.category_id' 
    || ' AND mcb1.segment1 = ''' || ir_param.prod_div    || ''''
    || ' AND gic2.item_id = itp.item_id' 
    || ' AND gic2.category_set_id = ''' || cn_item_class_id    || ''''
    || ' AND gic2.category_id = mcb2.category_id' 
    || ' AND mcb2.segment1 IN (''1'',''2'',''4'')' 
    || ' AND gic3.item_id = itp.item_id' 
    || ' AND gic3.category_id = mcb3.category_id' 
    || ' AND ilm.item_id = itp.item_id' 
    || ' AND ilm.lot_id = itp.lot_id' 
    || ' AND iimb.item_id = ilm.item_id' 
    || ' AND xlc.item_id(+) = ilm.item_id' 
    || ' AND xlc.lot_id (+) = ilm.lot_id'
    || ' AND ximb.item_id = iimb.item_id' 
    || ' AND ximb.start_date_active <= TRUNC(itp.trans_date)' 
    || ' AND ximb.end_date_active >= TRUNC(itp.trans_date)' 
    || ' AND rsl.shipment_header_id = itp.doc_id' 
    || ' AND rsl.line_num = itp.doc_line' 
--    || ' AND oola.header_id = rsl.oe_order_header_id' 
--    || ' AND oola.line_id = rsl.oe_order_line_id' 
--    || ' AND ooha.header_id = rsl.oe_order_header_id' 
    || ' AND otta.transaction_type_id = ooha.order_type_id' 
    || ' AND ((otta.attribute4 <> ''2'')' 
    || ' OR (otta.attribute4 IS NULL))' 
--    || ' AND xoha.header_id = ooha.header_id' 
--    || ' AND xola.line_id = rsl.oe_order_line_id' 
    || ' AND rsl.oe_order_header_id  = xola.header_id'
    || ' AND rsl.oe_order_line_id    = xola.line_id'
    || ' AND xoha.header_id          = ooha.header_id'
    || ' AND xola.order_header_id    = xoha.order_header_id'
    || ' AND xola.request_item_code = xola.shipping_item_code'
    || ' AND iimb2.item_no = xola.request_item_code' 
    || ' AND ximb2.item_id = iimb2.item_id' 
    || ' AND ximb2.start_date_active <= TRUNC(itp.trans_date)' 
    || ' AND ximb2.end_date_active >= TRUNC(itp.trans_date)' 
-- 2009/01/09 v1.22 UPDATE START
--    || ' AND xsupv.item_id = itp.item_id' 
--    || ' AND xsupv.start_date_active <= TRUNC(itp.trans_date)' 
--    || ' AND xsupv.end_date_active >= TRUNC(itp.trans_date)' 
-- 2009/01/16 v1.23 DELETE START
---- 2009/01/22 v1.24 UPDATE START
--    || ' AND xsupv.item_id(+) = itp.item_id' 
--    || ' AND NVL(xsupv.start_date_active, TRUNC(itp.trans_date)) <= TRUNC(itp.trans_date)' 
--    || ' AND NVL(xsupv.end_date_active, TRUNC(itp.trans_date)) >= TRUNC(itp.trans_date)' 
---- 2009/01/22 v1.24 UPDATE START
-- 2009/05/29 MOD START v1.24 DEL
    || ' AND xsupv.item_id(+) = itp.item_id' 
    || ' AND NVL(xsupv.start_date_active, TRUNC(xoha.arrival_date)) <= TRUNC(xoha.arrival_date)' 
    || ' AND NVL(xsupv.end_date_active, TRUNC(xoha.arrival_date)) >= TRUNC(xoha.arrival_date)' 
-- 2009/05/29 MOD END
-- 2009/01/16 v1.23 DELETE END
-- 2009/01/09 v1.22 UPDATE END
    || ' AND pvsa.vendor_site_id = xoha.vendor_site_id' 
    || ' AND pv.vendor_id = pvsa.vendor_id' 
-- 2008/12/13 v1.16 UPDATE START
--    || ' AND pv.customer_num = xpv.account_number' 
--    || ' AND xoha.customer_id = xpv.party_id' 
-- 2008/12/13 v1.16 UPDATE END
-- 2008/12/13 v1.17 DELETE START
--    || ' AND xpv.start_date_active <= TRUNC(itp.trans_date)' 
--    || ' AND xpv.end_date_active >= TRUNC(itp.trans_date)' 
-- 2008/12/13 v1.17 DELETE START
    || ' AND xrpm.doc_type = itp.doc_type' 
    || ' AND xrpm.doc_type = ''PORC'''
    || ' AND xrpm.source_document_code = ''RMA'''
    || ' AND xrpm.dealings_div = ''103''' 
    || ' AND xrpm.shipment_provision_div = otta.attribute1' 
    || ' AND xrpm.ship_prov_rcv_pay_category = otta.attribute11' 
    || ' AND (xrpm.item_div_origin = mcb2.segment1' 
    || ' OR xrpm.item_div_origin IS NULL)' 
    || ' AND xrpm.break_col_06 IS NOT NULL'
    || ' AND xrpm.item_div_origin IS NULL' 
-- 2009/01/21 v1.24 N.Yoshida ADD START
    || ' AND itp.whse_code = iwm.whse_code'
-- 2009/01/21 v1.24 N.Yoshida ADD END
-- 2008/12/13 v1.16 ADD START
--    || ' AND hla.location_code  = ooha.attribute11'
--    || ' AND hla.location_id    = xla.location_id'
--    || ' AND mct.category_id   = mcb2.category_id'
--    || ' AND hla.inactive_date  IS NULL'
--    || ' AND xla.start_date_active <= TRUNC(SYSDATE)'
--    || ' AND xla.end_date_active   >= TRUNC(SYSDATE)'
--    || ' AND mct.source_lang   = ''JA'''
--    || ' AND mct.language      = ''JA'''
-- 2008/12/13 v1.16 ADD END
    ;
-- 
 -- PORC_105
 -- パターン:1
    lv_select_1_po105 :=
       ' FROM ' 
    || ' ic_tran_pnd itp'
    || ' ,rcv_shipment_lines rsl'
--    || ' ,oe_order_lines_all oola'
    || ' ,oe_order_headers_all ooha'
    || ' ,oe_transaction_types_all otta'
    || ' ,xxwsh_order_headers_all xoha'
    || ' ,xxwsh_order_lines_all xola'
    || ' ,gmi_item_categories gic1'
    || ' ,mtl_categories_b mcb1'
    || ' ,gmi_item_categories gic2'
    || ' ,mtl_categories_b mcb2'
    || ' ,gmi_item_categories gic3'
    || ' ,mtl_categories_b mcb3'
    || ' ,gmi_item_categories gic4'
    || ' ,mtl_categories_b mcb4'
    || ' ,ic_item_mst_b iimb'
    || ' ,xxcmn_item_mst_b ximb'
    || ' ,ic_lots_mst ilm'
    || ' ,xxcmn_lot_cost xlc'
    || ' ,ic_item_mst_b iimb2'
    || ' ,xxcmn_item_mst_b ximb2'
--    || ' ,ic_item_mst_b iimb3'
-- 2009/01/09 v1.22 UPDATE START
-- 2009/01/22 v1.24 UPDATE START
    || ' ,xxcmn_stnd_unit_price_v xsupv' -- 標準原価情報View 
-- 2009/01/22 v1.24 UPDATE END
-- 2009/01/09 v1.22 UPDATE END
    || ' ,po_vendor_sites_all pvsa' -- 仕入先サイトマスタ 
    || ' ,po_vendors pv' -- 仕入先マスタ 
-- 2008/12/13 v1.17 DELETE START
--    || ' ,xxcmn_parties2_v xpv' -- パーティ情報View2 
-- 2008/12/13 v1.17 DELETE END
    || ' ,xxcmn_rcv_pay_mst xrpm'
-- 2008/12/13 v1.16 ADD START
-- 2009/01/21 v1.24 N.Yoshida ADD START
    || ' ,ic_whse_mst iwm'
-- 2009/01/21 v1.24 N.Yoshida ADD END
--    || ' ,hr_locations_all  hla '
--    || ' ,xxcmn_locations_all xla '
--    || ' ,mtl_categories_tl mct '
-- 2008/12/13 v1.16 ADD END
    || ' WHERE itp.doc_type = ''PORC''' -- 文書タイプ(PORC)
    || ' AND itp.completed_ind = 1' -- 完了フラグ
--    || ' AND itp.trans_date >= FND_DATE.STRING_TO_DATE(''' || ir_param.proc_from    || ''',''yyyymm'')'
--    || ' AND itp.trans_date < ADD_MONTHS( FND_DATE.STRING_TO_DATE(''' || ir_param.proc_to    || ''',''yyyymm''),1)'
    || ' AND xoha.latest_external_flag = ''Y'''
    || ' AND xoha.arrival_date >= FND_DATE.STRING_TO_DATE(''' || ir_param.proc_from    || ''',''yyyymm'')'
    || ' AND xoha.arrival_date < ADD_MONTHS( FND_DATE.STRING_TO_DATE(''' || ir_param.proc_to    || ''',''yyyymm''),1)'
    || ' AND xoha.req_status = ''08''' 
    || ' AND gic1.item_id = iimb2.item_id' 
    || ' AND gic1.category_set_id = ''' || cn_prod_class_id    || ''''
    || ' AND gic1.category_id = mcb1.category_id' 
    || ' AND mcb1.segment1 = ''' || ir_param.prod_div    || ''''
    || ' AND gic2.item_id = iimb2.item_id' 
    || ' AND gic2.category_set_id = ''' || cn_item_class_id    || ''''
    || ' AND gic2.category_id = mcb2.category_id' 
    || ' AND mcb2.segment1 = ''5'''
    || ' AND gic3.item_id = iimb2.item_id' 
    || ' AND gic3.category_id = mcb3.category_id' 
    || ' AND gic4.item_id = itp.item_id' 
    || ' AND gic4.category_set_id = ''' || cn_item_class_id    || ''''
    || ' AND gic4.category_id = mcb4.category_id' 
    || ' AND mcb4.segment1 IN (''1'',''2'',''4'')' 
    || ' AND xrpm.item_div_ahead = mcb2.segment1' 
    || ' AND ilm.item_id = itp.item_id' 
    || ' AND ilm.lot_id = itp.lot_id' 
    || ' AND iimb.item_id = ilm.item_id' 
    || ' AND xlc.item_id(+) = ilm.item_id' 
    || ' AND xlc.lot_id (+) = ilm.lot_id'
    || ' AND ximb.item_id = iimb.item_id' 
    || ' AND ximb.start_date_active <= TRUNC(itp.trans_date)' 
    || ' AND ximb.end_date_active >= TRUNC(itp.trans_date)' 
    || ' AND rsl.shipment_header_id = itp.doc_id' 
    || ' AND rsl.line_num = itp.doc_line' 
--    || ' AND oola.header_id = rsl.oe_order_header_id' 
--    || ' AND oola.line_id = rsl.oe_order_line_id' 
--    || ' AND ooha.header_id = rsl.oe_order_header_id' 
    || ' AND otta.transaction_type_id = ooha.order_type_id' 
    || ' AND ((otta.attribute4 <> ''2'')' 
    || ' OR (otta.attribute4 IS NULL))' 
--    || ' AND xoha.header_id = ooha.header_id' 
--    || ' AND xola.line_id = rsl.oe_order_line_id' 
    || ' AND ooha.header_id = rsl.oe_order_header_id' 
    || ' AND xoha.header_id = rsl.oe_order_header_id' 
    || ' AND xoha.header_id = ooha.header_id' 
    || ' AND xola.order_header_id = xoha.order_header_id' 
    || ' AND xola.line_id   = rsl.oe_order_line_id' 
    || ' AND iimb2.item_no = xola.request_item_code' 
    || ' AND ximb2.item_id = iimb2.item_id' 
    || ' AND ximb2.start_date_active <= TRUNC(itp.trans_date)' 
    || ' AND ximb2.end_date_active >= TRUNC(itp.trans_date)' 
-- 2009/01/09 v1.22 UPDATE START
--    || ' AND xsupv.item_id = iimb2.item_id' 
--    || ' AND xsupv.start_date_active <= TRUNC(itp.trans_date)' 
--    || ' AND xsupv.end_date_active >= TRUNC(itp.trans_date)' 
-- 2009/01/09 v1.22 UPDATE START
---- 2009/01/22 v1.24 UPDATE START
--    || ' AND xsupv.item_id(+) = iimb2.item_id' 
--    || ' AND NVL(xsupv.start_date_active, TRUNC(itp.trans_date)) <= TRUNC(itp.trans_date)' 
--    || ' AND NVL(xsupv.end_date_active, TRUNC(itp.trans_date)) >= TRUNC(itp.trans_date)' 
---- 2009/01/22 v1.24 UPDATE START
-- 2009/05/29 MOD START v1.24 DEL
    || ' AND xsupv.item_id(+) = iimb2.item_id' 
    || ' AND NVL(xsupv.start_date_active, TRUNC(xoha.arrival_date)) <= TRUNC(xoha.arrival_date)' 
    || ' AND NVL(xsupv.end_date_active, TRUNC(xoha.arrival_date)) >= TRUNC(xoha.arrival_date)' 
-- 2009/01/09 v1.22 UPDATE END
-- 2009/01/09 v1.22 UPDATE END
    || ' AND pvsa.vendor_site_id = xoha.vendor_site_id' 
    || ' AND pv.vendor_id = pvsa.vendor_id' 
-- 2008/12/13 v1.16 UPDATE START
--    || ' AND pv.customer_num = xpv.account_number' 
--    || ' AND xoha.customer_id = xpv.party_id' 
-- 2008/12/13 v1.16 UPDATE END
-- 2008/12/13 v1.17 DELETE START
--    || ' AND xpv.start_date_active <= TRUNC(itp.trans_date)' 
--    || ' AND xpv.end_date_active >= TRUNC(itp.trans_date)' 
-- 2008/12/13 v1.17 DELETE START
    || ' AND xrpm.doc_type = itp.doc_type' 
    || ' AND xrpm.doc_type = ''PORC'''
    || ' AND xrpm.source_document_code = ''RMA'''
    || ' AND xrpm.dealings_div = ''105''' 
    || ' AND xrpm.shipment_provision_div = otta.attribute1' 
    || ' AND xrpm.ship_prov_rcv_pay_category = otta.attribute11' 
    || ' AND xrpm.break_col_06 IS NOT NULL'
-- 2009/01/21 v1.24 N.Yoshida ADD START
    || ' AND itp.whse_code = iwm.whse_code'
-- 2009/01/21 v1.24 N.Yoshida ADD END
-- 2008/12/13 v1.16 ADD START
--    || ' AND hla.location_code  = ooha.attribute11'
--    || ' AND hla.location_id    = xla.location_id'
--    || ' AND mct.category_id   = mcb2.category_id'
--    || ' AND hla.inactive_date  IS NULL'
--    || ' AND xla.start_date_active <= TRUNC(SYSDATE)'
--    || ' AND xla.end_date_active   >= TRUNC(SYSDATE)'
--    || ' AND mct.source_lang   = ''JA'''
--    || ' AND mct.language      = ''JA'''
-- 2008/12/13 v1.16 ADD END
    ;
-- 
 -- PORC_108
 -- パターン:1
    lv_select_1_po108 :=
       ' FROM ' 
    || ' ic_tran_pnd itp'
    || ' ,rcv_shipment_lines rsl'
--    || ' ,oe_order_lines_all oola'
    || ' ,oe_order_headers_all ooha'
    || ' ,oe_transaction_types_all otta'
    || ' ,xxwsh_order_headers_all xoha'
    || ' ,xxwsh_order_lines_all xola'
    || ' ,gmi_item_categories gic1'
    || ' ,mtl_categories_b mcb1'
    || ' ,gmi_item_categories gic2'
    || ' ,mtl_categories_b mcb2'
    || ' ,gmi_item_categories gic3'
    || ' ,mtl_categories_b mcb3'
    || ' ,gmi_item_categories gic4'
    || ' ,mtl_categories_b mcb4'
    || ' ,gmi_item_categories gic5'
    || ' ,mtl_categories_b mcb5'
    || ' ,ic_item_mst_b iimb'
    || ' ,xxcmn_item_mst_b ximb'
    || ' ,ic_lots_mst ilm'
    || ' ,xxcmn_lot_cost xlc'
    || ' ,ic_item_mst_b iimb2'
    || ' ,xxcmn_item_mst_b ximb2'
--    || ' ,ic_item_mst_b iimb3'
-- 2009/01/09 v1.22 UPDATE START
-- 2009/01/22 v1.24 UPDATE START
    || ' ,xxcmn_stnd_unit_price_v xsupv' -- 標準原価情報View 
-- 2009/01/22 v1.24 UPDATE END
-- 2009/01/09 v1.22 UPDATE END
    || ' ,po_vendor_sites_all pvsa' -- 仕入先サイトマスタ 
    || ' ,po_vendors pv' -- 仕入先マスタ 
-- 2008/12/13 v1.17 DELETE START
--    || ' ,xxcmn_parties2_v xpv' -- パーティ情報View2 
-- 2008/12/13 v1.17 DELETE END
    || ' ,xxcmn_rcv_pay_mst xrpm'
-- 2008/12/13 v1.16 ADD START
-- 2009/01/21 v1.24 N.Yoshida ADD START
    || ' ,ic_whse_mst iwm'
-- 2009/01/21 v1.24 N.Yoshida ADD END
--    || ' ,hr_locations_all  hla '
--    || ' ,xxcmn_locations_all xla '
--    || ' ,mtl_categories_tl mct '
-- 2008/12/13 v1.16 ADD END
    || ' WHERE itp.doc_type = ''PORC''' -- 文書タイプ(PORC)
    || ' AND itp.completed_ind = 1' -- 完了フラグ
--    || ' AND itp.trans_date >= FND_DATE.STRING_TO_DATE(''' || ir_param.proc_from    || ''',''yyyymm'')'
--    || ' AND itp.trans_date < ADD_MONTHS( FND_DATE.STRING_TO_DATE(''' || ir_param.proc_to    || ''',''yyyymm''),1)'
    || ' AND xoha.latest_external_flag = ''Y'''
    || ' AND xoha.arrival_date >= FND_DATE.STRING_TO_DATE(''' || ir_param.proc_from    || ''',''yyyymm'')'
    || ' AND xoha.arrival_date < ADD_MONTHS( FND_DATE.STRING_TO_DATE(''' || ir_param.proc_to    || ''',''yyyymm''),1)'
    || ' AND xoha.req_status = ''08''' 
    || ' AND gic1.item_id = iimb2.item_id' 
    || ' AND gic1.category_set_id = ''' || cn_prod_class_id    || ''''
    || ' AND gic1.category_id = mcb1.category_id' 
    || ' AND mcb1.segment1 = ''' || ir_param.prod_div    || ''''
    || ' AND mcb1.segment1 = ''1''' 
    || ' AND gic2.item_id = iimb2.item_id' 
    || ' AND gic2.category_set_id = ''' || cn_item_class_id    || ''''
    || ' AND gic2.category_id = mcb2.category_id' 
    || ' AND mcb2.segment1 = ''5''' 
    || ' AND gic3.item_id = iimb2.item_id' 
    || ' AND gic3.category_id = mcb3.category_id' 
    || ' AND gic4.item_id = itp.item_id' 
    || ' AND gic4.category_set_id = ''' || cn_item_class_id    || ''''
    || ' AND gic4.category_id = mcb4.category_id' 
    || ' AND mcb4.segment1 = ''5''' 
    || ' AND gic5.item_id = itp.item_id' 
    || ' AND gic5.category_set_id = ''' || cn_prod_class_id    || ''''
    || ' AND gic5.category_id = mcb5.category_id' 
    || ' AND mcb5.segment1 = ''2''' 
    || ' AND ilm.item_id = itp.item_id' 
    || ' AND ilm.lot_id = itp.lot_id' 
    || ' AND iimb.item_id = ilm.item_id' 
    || ' AND xlc.item_id(+) = ilm.item_id' 
    || ' AND xlc.lot_id (+) = ilm.lot_id'
    || ' AND ximb.item_id = iimb.item_id' 
    || ' AND ximb.start_date_active <= TRUNC(itp.trans_date)' 
    || ' AND ximb.end_date_active >= TRUNC(itp.trans_date)' 
    || ' AND rsl.shipment_header_id = itp.doc_id' 
    || ' AND rsl.line_num = itp.doc_line' 
--    || ' AND oola.header_id = rsl.oe_order_header_id' 
--    || ' AND oola.line_id = rsl.oe_order_line_id' 
--    || ' AND ooha.header_id = rsl.oe_order_header_id' 
    || ' AND otta.transaction_type_id = ooha.order_type_id' 
    || ' AND ((otta.attribute4 <> ''2'')' 
    || ' OR (otta.attribute4 IS NULL))' 
--    || ' AND xoha.header_id = ooha.header_id' 
--    || ' AND xola.line_id = rsl.oe_order_line_id' 
    || ' AND ooha.header_id  = rsl.oe_order_header_id' 
    || ' AND xoha.header_id  = rsl.oe_order_header_id' 
    || ' AND xoha.header_id = ooha.header_id' 
    || ' AND xola.order_header_id = xoha.order_header_id' 
    || ' AND xola.line_id    = rsl.oe_order_line_id' 
    || ' AND iimb2.item_no = xola.request_item_code' 
    || ' AND ximb2.item_id = iimb2.item_id' 
    || ' AND ximb2.start_date_active <= TRUNC(itp.trans_date)' 
    || ' AND ximb2.end_date_active   >= TRUNC(itp.trans_date)' 
-- 2009/01/09 v1.22 UPDATE START
--    || ' AND xsupv.item_id = iimb2.item_id' 
--    || ' AND xsupv.start_date_active <= TRUNC(itp.trans_date)' 
--    || ' AND xsupv.end_date_active >= TRUNC(itp.trans_date)' 
-- 2009/01/09 v1.22 UPDATE START
---- 2009/01/22 v1.24 UPDATE START
--    || ' AND xsupv.item_id(+) = iimb2.item_id' 
--    || ' AND NVL(xsupv.start_date_active, TRUNC(itp.trans_date)) <= TRUNC(itp.trans_date)' 
--    || ' AND NVL(xsupv.end_date_active, TRUNC(itp.trans_date)) >= TRUNC(itp.trans_date)' 
---- 2009/01/22 v1.24 UPDATE END
-- 2009/05/29 MOD START v1.24 DEL
    || ' AND xsupv.item_id(+) = iimb2.item_id' 
    || ' AND NVL(xsupv.start_date_active, TRUNC(xoha.arrival_date)) <= TRUNC(xoha.arrival_date)' 
    || ' AND NVL(xsupv.end_date_active, TRUNC(xoha.arrival_date)) >= TRUNC(xoha.arrival_date)' 
-- 2009/05/29 MOD END
-- 2009/01/09 v1.22 UPDATE END
    || ' AND pvsa.vendor_site_id = xoha.vendor_site_id' 
    || ' AND pv.vendor_id = pvsa.vendor_id' 
-- 2008/12/13 v1.16 UPDATE START
--    || ' AND pv.customer_num = xpv.account_number' 
--    || ' AND xoha.customer_id = xpv.party_id' 
-- 2008/12/13 v1.16 UPDATE END
-- 2008/12/13 v1.17 DELETE START
--    || ' AND xpv.start_date_active <= TRUNC(itp.trans_date)' 
--    || ' AND xpv.end_date_active >= TRUNC(itp.trans_date)' 
-- 2008/12/13 v1.17 DELETE START
    || ' AND xrpm.doc_type = itp.doc_type' 
    || ' AND xrpm.doc_type = ''PORC'''
    || ' AND xrpm.source_document_code = ''RMA'''
    || ' AND xrpm.dealings_div = ''108''' 
    || ' AND xrpm.shipment_provision_div = otta.attribute1' 
    || ' AND xrpm.ship_prov_rcv_pay_category = otta.attribute11' 
    || ' AND xrpm.break_col_06 IS NOT NULL'
-- 2009/01/21 v1.24 N.Yoshida ADD START
    || ' AND itp.whse_code = iwm.whse_code'
-- 2009/01/21 v1.24 N.Yoshida ADD END
-- 2008/12/13 v1.16 ADD START
--    || ' AND hla.location_code  = ooha.attribute11'
--    || ' AND hla.location_id    = xla.location_id'
--    || ' AND mct.category_id   = mcb2.category_id'
--    || ' AND hla.inactive_date  IS NULL'
--    || ' AND xla.start_date_active <= TRUNC(SYSDATE)'
--    || ' AND xla.end_date_active   >= TRUNC(SYSDATE)'
--    || ' AND mct.source_lang   = ''JA'''
--    || ' AND mct.language      = ''JA'''
-- 2008/12/13 v1.16 ADD END
    ;
-- 
 -- OMSO_102
 -- パターン:1
    lv_select_1_om102 :=
       ' FROM ' 
    || ' ic_tran_pnd itp'
    || ' ,wsh_delivery_details wdd'
--    || ' ,oe_order_lines_all oola'
    || ' ,oe_order_headers_all ooha'
    || ' ,oe_transaction_types_all otta'
    || ' ,xxwsh_order_headers_all xoha'
    || ' ,xxwsh_order_lines_all xola'
    || ' ,gmi_item_categories gic1'
    || ' ,mtl_categories_b mcb1'
    || ' ,gmi_item_categories gic2'
    || ' ,mtl_categories_b mcb2'
    || ' ,gmi_item_categories gic3'
    || ' ,mtl_categories_b mcb3'
    || ' ,ic_item_mst_b iimb'
    || ' ,xxcmn_item_mst_b ximb'
    || ' ,ic_lots_mst ilm'
    || ' ,xxcmn_lot_cost xlc'
    || ' ,ic_item_mst_b iimb2'
    || ' ,xxcmn_item_mst_b ximb2'
-- 2009/01/09 v1.22 UPDATE START
-- 2009/01/22 v1.24 UPDATE START
    || ' ,xxcmn_stnd_unit_price_v xsupv' -- 標準原価情報View 
-- 2009/01/22 v1.24 UPDATE END
-- 2009/01/09 v1.22 UPDATE END
-- 2008/12/17 v1.20 UPDATE START
/*
    || ' ,xxcmn_party_sites2_v xpsv' -- パーティサイト情報View2 
-- 2008/12/13 v1.17 N.Yoshida mod start
--    || ' ,xxcmn_parties2_v xpv' -- パーティ情報View2 
--    || ' ,xxcmn_cust_accounts2_v xpv' -- 顧客情報View2 
    || ' ,xxcmn_parties xpv' -- 顧客情報View2 
*/
    || ' ,hz_party_sites hps'
    || ' ,xxcmn_parties xp'
-- 2008/12/17 v1.20 UPDATE END
    || ' ,hz_cust_accounts hca'
-- 2008/12/13 v1.17 N.Yoshida mod start
    || ' ,xxcmn_rcv_pay_mst xrpm'
-- 2008/12/13 v1.16 ADD START
-- 2009/01/21 v1.24 N.Yoshida ADD START
    || ' ,ic_whse_mst iwm'
-- 2009/01/21 v1.24 N.Yoshida ADD END
--    || ' ,hr_locations_all  hla '
--    || ' ,xxcmn_locations_all xla '
--    || ' ,mtl_categories_tl mct '
-- 2008/12/13 v1.16 ADD END
    || ' WHERE itp.doc_type = ''OMSO''' 
    || ' AND itp.completed_ind = 1' 
--    || ' AND itp.trans_date >= FND_DATE.STRING_TO_DATE(''' || ir_param.proc_from    || ''',''yyyymm'')'
--    || ' AND itp.trans_date < ADD_MONTHS( FND_DATE.STRING_TO_DATE(''' || ir_param.proc_to    || ''',''yyyymm''),1)'
    || ' AND xoha.latest_external_flag = ''Y'''
    || ' AND xoha.arrival_date >= FND_DATE.STRING_TO_DATE(''' || ir_param.proc_from    || ''',''yyyymm'')'
    || ' AND xoha.arrival_date < ADD_MONTHS( FND_DATE.STRING_TO_DATE(''' || ir_param.proc_to    || ''',''yyyymm''),1)'
    || ' AND xoha.req_status = ''04''' 
    || ' AND gic1.item_id = itp.item_id' 
    || ' AND gic1.category_set_id = ''' || cn_prod_class_id    || ''''
    || ' AND gic1.category_id = mcb1.category_id' 
    || ' AND mcb1.segment1 = ''' || ir_param.prod_div    || ''''
    || ' AND gic2.item_id = itp.item_id' 
    || ' AND gic2.category_set_id = ''' || cn_item_class_id    || ''''
    || ' AND gic2.category_id = mcb2.category_id' 
    || ' AND mcb2.segment1 = ''5''' 
    || ' AND gic3.item_id = itp.item_id' 
    || ' AND gic3.category_id = mcb3.category_id' 
    || ' AND xrpm.item_div_ahead = mcb2.segment1' 
    || ' AND xrpm.item_div_origin = mcb2.segment1' 
    || ' AND ilm.item_id = itp.item_id' 
    || ' AND ilm.lot_id = itp.lot_id' 
    || ' AND iimb.item_id = ilm.item_id' 
    || ' AND xlc.item_id(+) = ilm.item_id' 
    || ' AND xlc.lot_id (+) = ilm.lot_id'
    || ' AND ximb.item_id = iimb.item_id' 
    || ' AND ximb.start_date_active <= TRUNC(itp.trans_date)' 
    || ' AND ximb.end_date_active >= TRUNC(itp.trans_date)' 
    || ' AND wdd.delivery_detail_id = itp.line_detail_id' 
--    || ' AND oola.org_id = wdd.org_id' 
--    || ' AND oola.header_id = wdd.source_header_id' 
--    || ' AND oola.line_id = wdd.source_line_id' 
--    || ' AND ooha.header_id = wdd.source_header_id' 
    || ' AND otta.transaction_type_id = ooha.order_type_id' 
    || ' AND ((otta.attribute4 <> ''2'')' 
    || ' OR (otta.attribute4 IS NULL))' 
--    || ' AND xoha.header_id = ooha.header_id' 
--    || ' AND xola.line_id = wdd.source_line_id'
    || ' AND wdd.source_header_id  = xoha.header_id' 
    || ' AND wdd.source_line_id    = xola.line_id' 
    || ' AND xoha.header_id        = ooha.header_id' 
    || ' AND xola.order_header_id  = xoha.order_header_id' 
    || ' AND xola.request_item_code = xola.shipping_item_code' 
    || ' AND iimb2.item_no = xola.request_item_code' 
    || ' AND ximb2.item_id = iimb2.item_id' 
    || ' AND ximb2.start_date_active <= TRUNC(itp.trans_date)' 
    || ' AND ximb2.end_date_active >= TRUNC(itp.trans_date)' 
-- 2009/01/09 v1.22 UPDATE START
--    || ' AND xsupv.item_id = itp.item_id' 
--    || ' AND xsupv.start_date_active <= TRUNC(itp.trans_date)' 
--    || ' AND xsupv.end_date_active >= TRUNC(itp.trans_date)' 
-- 2009/01/09 v1.22 UPDATE START
---- 2009/01/22 v1.24 UPDATE START
--    || ' AND xsupv.item_id(+) = itp.item_id' 
--    || ' AND NVL(xsupv.start_date_active, TRUNC(itp.trans_date)) <= TRUNC(itp.trans_date)' 
--    || ' AND NVL(xsupv.end_date_active, TRUNC(itp.trans_date)) >= TRUNC(itp.trans_date)' 
---- 2009/01/22 v1.24 UPDATE START
-- 2009/05/29 MOD START v1.24 DEL
    || ' AND xsupv.item_id(+) = itp.item_id' 
    || ' AND NVL(xsupv.start_date_active, TRUNC(xoha.arrival_date)) <= TRUNC(xoha.arrival_date)' 
    || ' AND NVL(xsupv.end_date_active, TRUNC(xoha.arrival_date)) >= TRUNC(xoha.arrival_date)' 
-- 2009/05/29 MOD END
-- 2009/01/09 v1.22 UPDATE END
-- 2009/01/09 v1.22 UPDATE END
-- 2008/12/17 v1.20 UPDATE START
/*
    || ' AND xpsv.party_site_id = xoha.result_deliver_to_id' 
    || ' AND xpsv.start_date_active <= TRUNC(itp.trans_date)' 
    || ' AND xpsv.end_date_active >= TRUNC(itp.trans_date)' 
    || ' AND xpsv.party_id = xpv.party_id' 
    || ' AND xpv.start_date_active <= TRUNC(itp.trans_date)' 
    || ' AND xpv.end_date_active >= TRUNC(itp.trans_date)' 
*/
    || ' AND hps.party_site_id = xoha.result_deliver_to_id' 
    || ' AND xp.party_id       = hps.party_id' 
    || ' AND hca.party_id      = hps.party_id' 

-- 2008/12/17 v1.20 UPDATE END
    || ' AND xrpm.doc_type = itp.doc_type' 
    || ' AND xrpm.doc_type = ''OMSO'''
    || ' AND xrpm.dealings_div = ''102''' 
    || ' AND xrpm.shipment_provision_div = otta.attribute1' 
    || ' AND xrpm.break_col_06 IS NOT NULL'
-- 2009/01/21 v1.24 N.Yoshida ADD START
    || ' AND itp.whse_code = iwm.whse_code'
-- 2009/01/21 v1.24 N.Yoshida ADD END
-- 2008/12/13 v1.16 ADD START
--    || ' AND hla.location_code  = ooha.attribute11'
--    || ' AND hla.location_id    = xla.location_id'
--    || ' AND mct.category_id   = mcb2.category_id'
--    || ' AND hla.inactive_date  IS NULL'
--    || ' AND xla.start_date_active <= TRUNC(SYSDATE)'
--    || ' AND xla.end_date_active   >= TRUNC(SYSDATE)'
-- 2008/12/17 v1.20 DELETE START
--    || ' AND hca.party_id =  xpv.party_id'
-- 2008/12/17 v1.20 DELETE END
--    || ' AND mct.source_lang   = ''JA'''
--    || ' AND mct.language      = ''JA'''
-- 2008/12/13 v1.16 ADD END
    ;
-- 
 -- OMSO_101
 -- パターン:1
    lv_select_1_om101 :=
       ' FROM ' 
    || ' ic_tran_pnd itp'
    || ' ,wsh_delivery_details wdd'
--    || ' ,oe_order_lines_all oola'
    || ' ,oe_order_headers_all ooha'
    || ' ,oe_transaction_types_all otta'
    || ' ,xxwsh_order_headers_all xoha'
    || ' ,xxwsh_order_lines_all xola'
    || ' ,gmi_item_categories gic1'
    || ' ,mtl_categories_b mcb1'
    || ' ,gmi_item_categories gic2'
    || ' ,mtl_categories_b mcb2'
    || ' ,gmi_item_categories gic3'
    || ' ,mtl_categories_b mcb3'
    || ' ,ic_item_mst_b iimb'
    || ' ,xxcmn_item_mst_b ximb'
    || ' ,ic_lots_mst ilm'
    || ' ,xxcmn_lot_cost xlc'
    || ' ,ic_item_mst_b iimb2'
    || ' ,xxcmn_item_mst_b ximb2'
-- 2009/01/09 v1.22 UPDATE START
-- 2009/01/22 v1.24 UPDATE START
    || ' ,xxcmn_stnd_unit_price_v xsupv' -- 標準原価情報View 
-- 2009/01/22 v1.24 UPDATE END
-- 2009/01/09 v1.22 UPDATE END
-- 2008/12/17 v1.20 UPDATE START
/*
    || ' ,xxcmn_party_sites2_v xpsv' -- パーティサイト情報View2 
-- 2008/12/13 v1.17 N.Yoshida mod start
--    || ' ,xxcmn_parties2_v xpv' -- パーティ情報View2 
--    || ' ,xxcmn_cust_accounts2_v xpv' -- 顧客情報View2 
    || ' ,xxcmn_parties xpv' -- 顧客情報View2 
*/
    || ' ,hz_party_sites hps'
    || ' ,xxcmn_parties xp'

-- 2008/12/17 v1.20 UPDATE END
    || ' ,hz_cust_accounts hca'
-- 2008/12/13 v1.17 N.Yoshida mod start
    || ' ,xxcmn_rcv_pay_mst xrpm'
-- 2008/12/13 v1.16 ADD START
-- 2009/01/21 v1.24 N.Yoshida ADD START
    || ' ,ic_whse_mst iwm'
-- 2009/01/21 v1.24 N.Yoshida ADD END
--    || ' ,hr_locations_all  hla '
--    || ' ,xxcmn_locations_all xla '
--    || ' ,mtl_categories_tl mct '
-- 2008/12/13 v1.16 ADD END
    || ' WHERE itp.doc_type = ''OMSO''' 
    || ' AND itp.completed_ind = 1' 
--    || ' AND itp.trans_date >= FND_DATE.STRING_TO_DATE(''' || ir_param.proc_from    || ''',''yyyymm'')'
--    || ' AND itp.trans_date < ADD_MONTHS( FND_DATE.STRING_TO_DATE(''' || ir_param.proc_to    || ''',''yyyymm''),1)'
    || ' AND xoha.latest_external_flag = ''Y'''
    || ' AND xoha.arrival_date >= FND_DATE.STRING_TO_DATE(''' || ir_param.proc_from    || ''',''yyyymm'')'
    || ' AND xoha.arrival_date < ADD_MONTHS( FND_DATE.STRING_TO_DATE(''' || ir_param.proc_to    || ''',''yyyymm''),1)'
    || ' AND xoha.req_status = ''04''' 
    || ' AND gic1.item_id = itp.item_id' 
    || ' AND gic1.category_set_id = ''' || cn_prod_class_id    || ''''
    || ' AND gic1.category_id = mcb1.category_id' 
    || ' AND mcb1.segment1 = ''' || ir_param.prod_div    || ''''
    || ' AND gic2.item_id = itp.item_id' 
    || ' AND gic2.category_set_id = ''' || cn_item_class_id    || ''''
    || ' AND gic2.category_id = mcb2.category_id' 
    || ' AND mcb2.segment1 IN (''1'',''2'',''4'')' 
    || ' AND gic3.item_id = itp.item_id' 
    || ' AND gic3.category_id = mcb3.category_id' 
    || ' AND ilm.item_id = itp.item_id' 
    || ' AND ilm.lot_id = itp.lot_id' 
    || ' AND iimb.item_id = ilm.item_id' 
    || ' AND xlc.item_id(+) = ilm.item_id' 
    || ' AND xlc.lot_id (+) = ilm.lot_id'
    || ' AND ximb.item_id = iimb.item_id' 
    || ' AND ximb.start_date_active <= TRUNC(itp.trans_date)' 
    || ' AND ximb.end_date_active >= TRUNC(itp.trans_date)' 
    || ' AND wdd.delivery_detail_id = itp.line_detail_id' 
--    || ' AND oola.org_id = wdd.org_id' 
--    || ' AND oola.header_id = wdd.source_header_id' 
--    || ' AND oola.line_id = wdd.source_line_id' 
--    || ' AND ooha.header_id = wdd.source_header_id' 
    || ' AND otta.transaction_type_id = ooha.order_type_id' 
    || ' AND ((otta.attribute4 <> ''2'')' 
    || ' OR (otta.attribute4 IS NULL))' 
--    || ' AND xoha.header_id = ooha.header_id' 
--    || ' AND xola.line_id = wdd.source_line_id'
    || ' AND wdd.source_header_id   = xoha.header_id'
    || ' AND wdd.source_line_id     = xola.line_id'
    || ' AND xoha.header_id         = ooha.header_id'
    || ' AND xola.order_header_id   = xoha.order_header_id'
    || ' AND xola.request_item_code = xola.shipping_item_code'
    || ' AND iimb2.item_no = xola.request_item_code' 
    || ' AND ximb2.item_id = iimb2.item_id' 
    || ' AND ximb2.start_date_active <= TRUNC(itp.trans_date)' 
    || ' AND ximb2.end_date_active >= TRUNC(itp.trans_date)' 
-- 2009/01/09 v1.22 UPDATE START
--    || ' AND xsupv.item_id = itp.item_id' 
--    || ' AND xsupv.start_date_active <= TRUNC(itp.trans_date)' 
--    || ' AND xsupv.end_date_active >= TRUNC(itp.trans_date)' 
-- 2009/01/09 v1.22 UPDATE START
---- 2009/01/22 v1.24 UPDATE START
--    || ' AND xsupv.item_id(+) = itp.item_id' 
--    || ' AND NVL(xsupv.start_date_active, TRUNC(itp.trans_date)) <= TRUNC(itp.trans_date)' 
--    || ' AND NVL(xsupv.end_date_active, TRUNC(itp.trans_date)) >= TRUNC(itp.trans_date)' 
---- 2009/01/22 v1.24 UPDATE START
-- 2009/05/29 MOD START v1.24 DEL
    || ' AND xsupv.item_id(+) = itp.item_id' 
    || ' AND NVL(xsupv.start_date_active, TRUNC(xoha.arrival_date)) <= TRUNC(xoha.arrival_date)' 
    || ' AND NVL(xsupv.end_date_active, TRUNC(xoha.arrival_date)) >= TRUNC(xoha.arrival_date)' 
-- 2009/05/29 MOD END
-- 2009/01/09 v1.22 UPDATE END
-- 2009/01/09 v1.22 UPDATE END
-- 2008/12/17 v1.20 UPDATE START
/*
    || ' AND xpsv.party_site_id = xoha.result_deliver_to_id' 
    || ' AND xpsv.start_date_active <= TRUNC(itp.trans_date)' 
    || ' AND xpsv.end_date_active >= TRUNC(itp.trans_date)' 
    || ' AND xpsv.party_id = xpv.party_id' 
    || ' AND xpv.start_date_active <= TRUNC(itp.trans_date)' 
    || ' AND xpv.end_date_active >= TRUNC(itp.trans_date)' 
*/
    || ' AND hps.party_site_id     = xoha.result_deliver_to_id' 
    || ' AND xp.party_id           = hps.party_id' 
    || ' AND xp.start_date_active <= TRUNC(itp.trans_date)' 
    || ' AND xp.end_date_active   >= TRUNC(itp.trans_date)' 
    || ' AND hca.party_id          = hps.party_id' 
-- 2008/12/17 v1.20 UPDATE END
    || ' AND xrpm.doc_type = itp.doc_type' 
    || ' AND xrpm.doc_type = ''OMSO'''
    || ' AND xrpm.dealings_div = ''101''' 
    || ' AND xrpm.shipment_provision_div = otta.attribute1' 
    || ' AND xrpm.break_col_06 IS NOT NULL'
-- 2009/01/21 v1.24 N.Yoshida ADD START
    || ' AND itp.whse_code = iwm.whse_code'
-- 2009/01/21 v1.24 N.Yoshida ADD END
-- 2008/12/13 v1.16 ADD START
--    || ' AND hla.location_code  = ooha.attribute11'
--    || ' AND hla.location_id    = xla.location_id'
--    || ' AND mct.category_id   = mcb2.category_id'
--    || ' AND hla.inactive_date  IS NULL'
--    || ' AND xla.start_date_active <= TRUNC(SYSDATE)'
--    || ' AND xla.end_date_active   >= TRUNC(SYSDATE)'
-- 2008/12/17 v1.20 DELETE START
--    || ' AND hca.party_id =  xpv.party_id'
-- 2008/12/17 v1.20 DELETE END
--    || ' AND mct.source_lang   = ''JA'''
--    || ' AND mct.language      = ''JA'''
-- 2008/12/13 v1.16 ADD END
    ;
-- 
 -- OMSO_112
 -- パターン:1
    lv_select_1_om112 :=
       ' FROM ' 
    || ' ic_tran_pnd itp'
    || ' ,wsh_delivery_details wdd'
--    || ' ,oe_order_lines_all oola'
    || ' ,oe_order_headers_all ooha'
    || ' ,oe_transaction_types_all otta'
    || ' ,xxwsh_order_headers_all xoha'
    || ' ,xxwsh_order_lines_all xola'
    || ' ,gmi_item_categories gic1'
    || ' ,mtl_categories_b mcb1'
    || ' ,gmi_item_categories gic2'
    || ' ,mtl_categories_b mcb2'
    || ' ,gmi_item_categories gic3'
    || ' ,mtl_categories_b mcb3'
    || ' ,gmi_item_categories gic4'
    || ' ,mtl_categories_b mcb4'
    || ' ,ic_item_mst_b iimb'
    || ' ,xxcmn_item_mst_b ximb'
    || ' ,ic_lots_mst ilm'
    || ' ,xxcmn_lot_cost xlc'
    || ' ,ic_item_mst_b iimb2'
    || ' ,xxcmn_item_mst_b ximb2'
--    || ' ,ic_item_mst_b iimb3'
-- 2009/01/09 v1.22 UPDATE START
-- 2009/01/22 v1.24 UPDATE START
    || ' ,xxcmn_stnd_unit_price_v xsupv' -- 標準原価情報View 
-- 2009/01/22 v1.24 UPDATE END
-- 2009/01/09 v1.22 UPDATE END
-- 2008/12/17 v1.20 UPDATE START
/*
    || ' ,xxcmn_party_sites2_v xpsv' -- パーティサイト情報View2 
-- 2008/12/13 v1.17 N.Yoshida mod start
--    || ' ,xxcmn_parties2_v xpv' -- パーティ情報View2 
--    || ' ,xxcmn_cust_accounts2_v xpv' -- 顧客情報View2 
    || ' ,xxcmn_parties xpv' -- 顧客情報View2 
*/
    || ' ,hz_party_sites hps'
    || ' ,xxcmn_parties xp'
-- 2008/12/17 v1.20 UPDATE END
    || ' ,hz_cust_accounts hca'
-- 2008/12/13 v1.17 N.Yoshida mod start
    || ' ,xxcmn_rcv_pay_mst xrpm'
-- 2008/12/13 v1.16 ADD START
-- 2009/01/21 v1.24 N.Yoshida ADD START
    || ' ,ic_whse_mst iwm'
-- 2009/01/21 v1.24 N.Yoshida ADD END
--    || ' ,hr_locations_all  hla '
--    || ' ,xxcmn_locations_all xla '
--    || ' ,mtl_categories_tl mct '
-- 2008/12/13 v1.16 ADD END
    || ' WHERE itp.doc_type = ''OMSO''' 
    || ' AND itp.completed_ind = 1' 
--    || ' AND itp.trans_date >= FND_DATE.STRING_TO_DATE(''' || ir_param.proc_from    || ''',''yyyymm'')'
--    || ' AND itp.trans_date < ADD_MONTHS( FND_DATE.STRING_TO_DATE(''' || ir_param.proc_to    || ''',''yyyymm''),1)'
    || ' AND xoha.latest_external_flag = ''Y'''
    || ' AND xoha.arrival_date >= FND_DATE.STRING_TO_DATE(''' || ir_param.proc_from    || ''',''yyyymm'')'
    || ' AND xoha.arrival_date < ADD_MONTHS( FND_DATE.STRING_TO_DATE(''' || ir_param.proc_to    || ''',''yyyymm''),1)'
    || ' AND xoha.req_status = ''04''' 
    || ' AND gic1.item_id = iimb2.item_id' 
    || ' AND gic1.category_set_id = ''' || cn_prod_class_id    || ''''
    || ' AND gic1.category_id = mcb1.category_id' 
    || ' AND mcb1.segment1 = ''' || ir_param.prod_div    || ''''
    || ' AND gic2.item_id = iimb2.item_id' 
    || ' AND gic2.category_set_id = ''' || cn_item_class_id    || ''''
    || ' AND gic2.category_id = mcb2.category_id' 
    || ' AND mcb2.segment1 = ''5''' 
    || ' AND gic3.item_id = iimb2.item_id' 
    || ' AND gic3.category_id = mcb3.category_id' 
    || ' AND gic4.item_id = itp.item_id' 
    || ' AND gic4.category_set_id = ''' || cn_item_class_id    || ''''
    || ' AND gic4.category_id = mcb4.category_id' 
    || ' AND mcb4.segment1 IN (''1'',''2'',''4'')' 
    || ' AND xrpm.item_div_ahead = mcb2.segment1' 
    || ' AND ilm.item_id = itp.item_id' 
    || ' AND ilm.lot_id = itp.lot_id' 
    || ' AND iimb.item_id = ilm.item_id' 
    || ' AND xlc.item_id(+) = ilm.item_id' 
    || ' AND xlc.lot_id (+) = ilm.lot_id'
    || ' AND ximb.item_id = iimb.item_id' 
    || ' AND ximb.start_date_active <= TRUNC(itp.trans_date)' 
    || ' AND ximb.end_date_active >= TRUNC(itp.trans_date)' 
    || ' AND wdd.delivery_detail_id = itp.line_detail_id' 
--    || ' AND oola.org_id = wdd.org_id' 
--    || ' AND oola.header_id = wdd.source_header_id' 
--    || ' AND oola.line_id = wdd.source_line_id' 
--    || ' AND ooha.header_id = wdd.source_header_id' 
    || ' AND otta.transaction_type_id = ooha.order_type_id' 
    || ' AND ((otta.attribute4 <> ''2'')' 
    || ' OR (otta.attribute4 IS NULL))' 
--    || ' AND xoha.header_id = ooha.header_id' 
--    || ' AND xola.line_id = wdd.source_line_id'
    || ' AND xoha.header_id = wdd.source_header_id' 
    || ' AND xoha.header_id = ooha.header_id' 
    || ' AND xola.order_header_id = xoha.order_header_id' 
    || ' AND xola.line_id = wdd.source_line_id' 
    || ' AND iimb2.item_no = xola.request_item_code' 
    || ' AND ximb2.item_id = iimb2.item_id' 
    || ' AND ximb2.start_date_active <= TRUNC(itp.trans_date)' 
    || ' AND ximb2.end_date_active >= TRUNC(itp.trans_date)' 
-- 2009/01/09 v1.22 UPDATE START
--    || ' AND xsupv.item_id = iimb2.item_id' 
--    || ' AND xsupv.start_date_active <= TRUNC(itp.trans_date)' 
--    || ' AND xsupv.end_date_active >= TRUNC(itp.trans_date)' 
-- 2009/01/09 v1.22 UPDATE START
---- 2009/01/22 v1.24 UPDATE START
--    || ' AND xsupv.item_id(+) = iimb2.item_id' 
--    || ' AND NVL(xsupv.start_date_active, TRUNC(itp.trans_date)) <= TRUNC(itp.trans_date)' 
--    || ' AND NVL(xsupv.end_date_active, TRUNC(itp.trans_date)) >= TRUNC(itp.trans_date)' 
---- 2009/01/22 v1.24 UPDATE START
-- 2009/05/29 MOD START v1.24 DEL
    || ' AND xsupv.item_id(+) = iimb2.item_id' 
    || ' AND NVL(xsupv.start_date_active, TRUNC(xoha.arrival_date)) <= TRUNC(xoha.arrival_date)' 
    || ' AND NVL(xsupv.end_date_active, TRUNC(xoha.arrival_date)) >= TRUNC(xoha.arrival_date)' 
-- 2009/05/29 MOD END
-- 2009/01/09 v1.22 UPDATE END
-- 2009/01/09 v1.22 UPDATE END
-- 2008/12/17 v1.20 UPDATE START
/*
    || ' AND xpsv.party_site_id = xoha.result_deliver_to_id' 
    || ' AND xpsv.start_date_active <= TRUNC(itp.trans_date)' 
    || ' AND xpsv.end_date_active >= TRUNC(itp.trans_date)' 
    || ' AND xpsv.party_id = xpv.party_id' 
    || ' AND xpv.start_date_active <= TRUNC(itp.trans_date)' 
    || ' AND xpv.end_date_active >= TRUNC(itp.trans_date)' 
*/
    || ' AND hps.party_site_id     = xoha.result_deliver_to_id' 
    || ' AND xp.party_id           = hps.party_id' 
    || ' AND xp.start_date_active <= TRUNC(itp.trans_date)' 
    || ' AND xp.end_date_active   >= TRUNC(itp.trans_date)' 
    || ' AND hca.party_id          = hps.party_id' 
-- 2008/12/17 v1.20 UPDATE END
    || ' AND xrpm.doc_type = itp.doc_type' 
    || ' AND xrpm.doc_type = ''OMSO'''
    || ' AND xrpm.dealings_div = ''112''' 
    || ' AND xrpm.shipment_provision_div = otta.attribute1' 
    || ' AND xrpm.break_col_06 IS NOT NULL'
-- 2009/01/21 v1.24 N.Yoshida ADD START
    || ' AND itp.whse_code = iwm.whse_code'
-- 2009/01/21 v1.24 N.Yoshida ADD END
-- 2008/12/13 v1.16 ADD START
--    || ' AND hla.location_code  = ooha.attribute11'
--    || ' AND hla.location_id    = xla.location_id'
--    || ' AND mct.category_id   = mcb2.category_id'
--    || ' AND hla.inactive_date  IS NULL'
--    || ' AND xla.start_date_active <= TRUNC(SYSDATE)'
--    || ' AND xla.end_date_active   >= TRUNC(SYSDATE)'
-- 2008/12/17 DELETE START
--    || ' AND hca.party_id =  xpv.party_id'
-- 2008/12/17 DELETE END
--    || ' AND mct.source_lang   = ''JA'''
--    || ' AND mct.language      = ''JA'''
-- 2008/12/13 v1.16 ADD END
    ;
-- 
 -- OMSO_103_5
 -- パターン:1
    lv_select_1_om103x5 :=
       ' FROM ' 
    || ' ic_tran_pnd itp'
    || ' ,wsh_delivery_details wdd'
--    || ' ,oe_order_lines_all oola'
    || ' ,oe_order_headers_all ooha'
    || ' ,oe_transaction_types_all otta'
    || ' ,xxwsh_order_headers_all xoha'
    || ' ,xxwsh_order_lines_all xola'
    || ' ,gmi_item_categories gic1'
    || ' ,mtl_categories_b mcb1'
    || ' ,gmi_item_categories gic2'
    || ' ,mtl_categories_b mcb2'
    || ' ,gmi_item_categories gic3'
    || ' ,mtl_categories_b mcb3'
    || ' ,ic_item_mst_b iimb'
    || ' ,xxcmn_item_mst_b ximb'
    || ' ,ic_lots_mst ilm'
    || ' ,xxcmn_lot_cost xlc'
    || ' ,ic_item_mst_b iimb2'
    || ' ,xxcmn_item_mst_b ximb2'
-- 2009/01/09 v1.22 UPDATE START
-- 2009/01/22 v1.24 UPDATE START
    || ' ,xxcmn_stnd_unit_price_v xsupv' -- 標準原価情報View 
-- 2009/01/22 v1.24 UPDATE END
-- 2009/01/09 v1.22 UPDATE END
    || ' ,po_vendor_sites_all pvsa' -- 仕入先サイトマスタ 
    || ' ,po_vendors pv' -- 仕入先マスタ 
-- 2008/12/13 v1.17 DELETE START
--    || ' ,xxcmn_parties2_v xpv' -- パーティ情報View2 
-- 2008/12/13 v1.17 DELETE END
    || ' ,xxcmn_rcv_pay_mst xrpm'
-- 2008/12/13 v1.16 ADD START
-- 2009/01/21 v1.24 N.Yoshida ADD START
    || ' ,ic_whse_mst iwm'
-- 2009/01/21 v1.24 N.Yoshida ADD END
--    || ' ,hr_locations_all  hla '
--    || ' ,xxcmn_locations_all xla '
--    || ' ,mtl_categories_tl mct '
-- 2008/12/13 v1.16 ADD END
    || ' WHERE itp.doc_type = ''OMSO''' 
    || ' AND itp.completed_ind = 1' 
--    || ' AND itp.trans_date >= FND_DATE.STRING_TO_DATE(''' || ir_param.proc_from    || ''',''yyyymm'')'
--    || ' AND itp.trans_date < ADD_MONTHS( FND_DATE.STRING_TO_DATE(''' || ir_param.proc_to    || ''',''yyyymm''),1)'
    || ' AND xoha.latest_external_flag = ''Y'''
    || ' AND xoha.arrival_date >= FND_DATE.STRING_TO_DATE(''' || ir_param.proc_from    || ''',''yyyymm'')'
    || ' AND xoha.arrival_date < ADD_MONTHS( FND_DATE.STRING_TO_DATE(''' || ir_param.proc_to    || ''',''yyyymm''),1)'
    || ' AND xoha.req_status = ''08''' 
    || ' AND gic1.item_id = itp.item_id' 
    || ' AND gic1.category_set_id = ''' || cn_prod_class_id    || ''''
    || ' AND gic1.category_id = mcb1.category_id' 
    || ' AND mcb1.segment1 = ''' || ir_param.prod_div    || ''''
    || ' AND gic2.item_id = itp.item_id' 
    || ' AND gic2.category_set_id = ''' || cn_item_class_id    || ''''
    || ' AND gic2.category_id = mcb2.category_id' 
    || ' AND mcb2.segment1 = ''5''' 
    || ' AND gic3.item_id = itp.item_id' 
    || ' AND gic3.category_id = mcb3.category_id' 
    || ' AND ilm.item_id = itp.item_id' 
    || ' AND ilm.lot_id = itp.lot_id' 
    || ' AND iimb.item_id = ilm.item_id' 
    || ' AND xlc.item_id(+) = ilm.item_id' 
    || ' AND xlc.lot_id (+) = ilm.lot_id'
    || ' AND ximb.item_id = iimb.item_id' 
    || ' AND ximb.start_date_active <= TRUNC(itp.trans_date)' 
    || ' AND ximb.end_date_active >= TRUNC(itp.trans_date)' 
    || ' AND wdd.delivery_detail_id = itp.line_detail_id' 
--    || ' AND oola.org_id = wdd.org_id' 
--    || ' AND oola.header_id = wdd.source_header_id' 
--    || ' AND oola.line_id = wdd.source_line_id' 
--    || ' AND ooha.header_id = wdd.source_header_id' 
    || ' AND otta.transaction_type_id = ooha.order_type_id' 
    || ' AND ((otta.attribute4 <> ''2'')' 
    || ' OR (otta.attribute4 IS NULL))' 
--    || ' AND xoha.header_id = ooha.header_id' 
--    || ' AND xola.line_id = wdd.source_line_id'
    || ' AND wdd.source_header_id = xoha.header_id'
    || ' AND wdd.source_line_id = xola.line_id'
    || ' AND xoha.header_id = ooha.header_id'
    || ' AND xola.order_header_id = xoha.order_header_id'
    || ' AND xola.request_item_code = xola.shipping_item_code'
    || ' AND iimb2.item_no = xola.request_item_code' 
    || ' AND ximb2.item_id = iimb2.item_id' 
    || ' AND ximb2.start_date_active <= TRUNC(itp.trans_date)' 
    || ' AND ximb2.end_date_active >= TRUNC(itp.trans_date)' 
-- 2009/01/09 v1.22 UPDATE START
--    || ' AND xsupv.item_id = itp.item_id' 
--    || ' AND xsupv.start_date_active <= TRUNC(itp.trans_date)' 
--    || ' AND xsupv.end_date_active >= TRUNC(itp.trans_date)' 
-- 2009/01/09 v1.22 UPDATE START
---- 2009/01/22 v1.24 UPDATE START
--    || ' AND xsupv.item_id(+) = itp.item_id' 
--    || ' AND NVL(xsupv.start_date_active, TRUNC(itp.trans_date)) <= TRUNC(itp.trans_date)' 
--    || ' AND NVL(xsupv.end_date_active, TRUNC(itp.trans_date)) >= TRUNC(itp.trans_date)' 
---- 2009/01/22 v1.24 UPDATE START
-- 2009/05/29 MOD START v1.24 DEL
    || ' AND xsupv.item_id(+) = itp.item_id' 
    || ' AND NVL(xsupv.start_date_active, TRUNC(xoha.arrival_date)) <= TRUNC(xoha.arrival_date)' 
    || ' AND NVL(xsupv.end_date_active, TRUNC(xoha.arrival_date)) >= TRUNC(xoha.arrival_date)' 
-- 2009/05/29 MOD END
-- 2009/01/09 v1.22 UPDATE END
-- 2009/01/09 v1.22 UPDATE END
    || ' AND pvsa.vendor_site_id = xoha.vendor_site_id' 
    || ' AND pv.vendor_id = pvsa.vendor_id' 
-- 2008/12/13 v1.16 UPDATE START
--    || ' AND pv.customer_num = xpv.account_number' 
--    || ' AND xoha.customer_id = xpv.party_id' 
-- 2008/12/13 v1.16 UPDATE END
-- 2008/12/13 v1.17 DELETE START
--    || ' AND xpv.start_date_active <= TRUNC(itp.trans_date)' 
--    || ' AND xpv.end_date_active >= TRUNC(itp.trans_date)' 
-- 2008/12/13 v1.17 DELETE START
    || ' AND xrpm.doc_type = itp.doc_type' 
    || ' AND xrpm.doc_type = ''OMSO'''
    || ' AND xrpm.dealings_div = ''103''' 
    || ' AND xrpm.shipment_provision_div = otta.attribute1' 
    || ' AND xrpm.ship_prov_rcv_pay_category = otta.attribute11' 
    || ' AND (xrpm.item_div_origin = mcb2.segment1' 
    || ' OR xrpm.item_div_origin IS NULL)' 
    || ' AND xrpm.break_col_06 IS NOT NULL'
    || ' AND xrpm.item_div_origin = mcb2.segment1' 
-- 2009/01/21 v1.24 N.Yoshida ADD START
    || ' AND itp.whse_code = iwm.whse_code'
-- 2009/01/21 v1.24 N.Yoshida ADD END
-- 2008/12/13 v1.16 ADD START
--    || ' AND hla.location_code  = ooha.attribute11'
--    || ' AND hla.location_id    = xla.location_id'
--    || ' AND mct.category_id   = mcb2.category_id'
--    || ' AND hla.inactive_date  IS NULL'
--    || ' AND xla.start_date_active <= TRUNC(SYSDATE)'
--    || ' AND xla.end_date_active   >= TRUNC(SYSDATE)'
--    || ' AND mct.source_lang   = ''JA'''
--    || ' AND mct.language      = ''JA'''
-- 2008/12/13 v1.16 ADD END
    ;
-- 
 -- OMSO_103_124
 -- パターン:1
    lv_select_1_om103x124 :=
       ' FROM ' 
    || ' ic_tran_pnd itp'
    || ' ,wsh_delivery_details wdd'
--    || ' ,oe_order_lines_all oola'
    || ' ,oe_order_headers_all ooha'
    || ' ,oe_transaction_types_all otta'
    || ' ,xxwsh_order_headers_all xoha'
    || ' ,xxwsh_order_lines_all xola'
    || ' ,gmi_item_categories gic1'
    || ' ,mtl_categories_b mcb1'
    || ' ,gmi_item_categories gic2'
    || ' ,mtl_categories_b mcb2'
    || ' ,gmi_item_categories gic3'
    || ' ,mtl_categories_b mcb3'
    || ' ,ic_item_mst_b iimb'
    || ' ,xxcmn_item_mst_b ximb'
    || ' ,ic_lots_mst ilm'
    || ' ,xxcmn_lot_cost xlc'
    || ' ,ic_item_mst_b iimb2'
    || ' ,xxcmn_item_mst_b ximb2'
-- 2009/01/09 v1.22 UPDATE START
-- 2009/01/22 v1.24 UPDATE START
    || ' ,xxcmn_stnd_unit_price_v xsupv' -- 標準原価情報View 
-- 2009/01/22 v1.24 UPDATE END
-- 2009/01/09 v1.22 UPDATE END
    || ' ,po_vendor_sites_all pvsa' -- 仕入先サイトマスタ 
    || ' ,po_vendors pv' -- 仕入先マスタ 
-- 2008/12/13 v1.17 DELETE START
--    || ' ,xxcmn_parties2_v xpv' -- パーティ情報View2 
-- 2008/12/13 v1.17 DELETE END
    || ' ,xxcmn_rcv_pay_mst xrpm'
-- 2008/12/13 v1.16 ADD START
-- 2009/01/21 v1.24 N.Yoshida ADD START
    || ' ,ic_whse_mst iwm'
-- 2009/01/21 v1.24 N.Yoshida ADD END
--    || ' ,hr_locations_all  hla '
--    || ' ,xxcmn_locations_all xla '
--    || ' ,mtl_categories_tl mct '
-- 2008/12/13 v1.16 ADD END
    || ' WHERE itp.doc_type = ''OMSO''' 
    || ' AND itp.completed_ind = 1' 
--    || ' AND itp.trans_date >= FND_DATE.STRING_TO_DATE(''' || ir_param.proc_from    || ''',''yyyymm'')'
--    || ' AND itp.trans_date < ADD_MONTHS( FND_DATE.STRING_TO_DATE(''' || ir_param.proc_to    || ''',''yyyymm''),1)'
    || ' AND xoha.latest_external_flag = ''Y'''
    || ' AND xoha.arrival_date >= FND_DATE.STRING_TO_DATE(''' || ir_param.proc_from    || ''',''yyyymm'')'
    || ' AND xoha.arrival_date < ADD_MONTHS( FND_DATE.STRING_TO_DATE(''' || ir_param.proc_to    || ''',''yyyymm''),1)'
    || ' AND xoha.req_status = ''08''' 
    || ' AND gic1.item_id = itp.item_id' 
    || ' AND gic1.category_set_id = ''' || cn_prod_class_id    || ''''
    || ' AND gic1.category_id = mcb1.category_id' 
    || ' AND mcb1.segment1 = ''' || ir_param.prod_div    || ''''
    || ' AND gic2.item_id = itp.item_id' 
    || ' AND gic2.category_set_id = ''' || cn_item_class_id    || ''''
    || ' AND gic2.category_id = mcb2.category_id' 
    || ' AND mcb2.segment1 IN (''1'',''2'',''4'')' 
    || ' AND gic3.item_id = itp.item_id' 
    || ' AND gic3.category_id = mcb3.category_id' 
    || ' AND ilm.item_id = itp.item_id' 
    || ' AND ilm.lot_id = itp.lot_id' 
    || ' AND iimb.item_id = ilm.item_id' 
    || ' AND xlc.item_id(+) = ilm.item_id' 
    || ' AND xlc.lot_id (+) = ilm.lot_id'
    || ' AND ximb.item_id = iimb.item_id' 
    || ' AND ximb.start_date_active <= TRUNC(itp.trans_date)' 
    || ' AND ximb.end_date_active >= TRUNC(itp.trans_date)' 
    || ' AND wdd.delivery_detail_id = itp.line_detail_id' 
--    || ' AND oola.org_id = wdd.org_id' 
--    || ' AND oola.header_id = wdd.source_header_id' 
--    || ' AND oola.line_id = wdd.source_line_id' 
--    || ' AND ooha.header_id = wdd.source_header_id' 
    || ' AND otta.transaction_type_id = ooha.order_type_id' 
    || ' AND ((otta.attribute4 <> ''2'')' 
    || ' OR (otta.attribute4 IS NULL))' 
--    || ' AND xoha.header_id = ooha.header_id' 
--    || ' AND xola.line_id = wdd.source_line_id'
    || ' AND wdd.source_header_id = xoha.header_id'
    || ' AND wdd.source_line_id = xola.line_id'
    || ' AND xoha.header_id = ooha.header_id'
    || ' AND xola.order_header_id = xoha.order_header_id'
    || ' AND xola.request_item_code = xola.shipping_item_code'
    || ' AND iimb2.item_no = xola.request_item_code' 
    || ' AND ximb2.item_id = iimb2.item_id' 
    || ' AND ximb2.start_date_active <= TRUNC(itp.trans_date)' 
    || ' AND ximb2.end_date_active >= TRUNC(itp.trans_date)' 
-- 2009/01/09 v1.22 UPDATE START
--    || ' AND xsupv.item_id = itp.item_id' 
--    || ' AND xsupv.start_date_active <= TRUNC(itp.trans_date)' 
--    || ' AND xsupv.end_date_active >= TRUNC(itp.trans_date)' 
-- 2009/01/09 v1.22 UPDATE START
---- 2009/01/22 v1.24 UPDATE START
--    || ' AND xsupv.item_id(+) = itp.item_id' 
--    || ' AND NVL(xsupv.start_date_active, TRUNC(itp.trans_date)) <= TRUNC(itp.trans_date)' 
--    || ' AND NVL(xsupv.end_date_active, TRUNC(itp.trans_date)) >= TRUNC(itp.trans_date)' 
---- 2009/01/22 v1.24 UPDATE START
-- 2009/05/29 MOD START v1.24 DEL
    || ' AND xsupv.item_id(+) = itp.item_id' 
    || ' AND NVL(xsupv.start_date_active, TRUNC(xoha.arrival_date)) <= TRUNC(xoha.arrival_date)' 
    || ' AND NVL(xsupv.end_date_active, TRUNC(xoha.arrival_date)) >= TRUNC(xoha.arrival_date)' 
-- 2009/05/29 MOD END
-- 2009/01/09 v1.22 UPDATE END
-- 2009/01/09 v1.22 UPDATE END
    || ' AND pvsa.vendor_site_id = xoha.vendor_site_id' 
    || ' AND pv.vendor_id = pvsa.vendor_id' 
-- 2008/12/13 v1.16 UPDATE START
--    || ' AND pv.customer_num = xpv.account_number' 
--    || ' AND xoha.customer_id = xpv.party_id' 
-- 2008/12/13 v1.16 UPDATE END
-- 2008/12/13 v1.17 DELETE START
--    || ' AND xpv.start_date_active <= TRUNC(itp.trans_date)' 
--    || ' AND xpv.end_date_active >= TRUNC(itp.trans_date)' 
-- 2008/12/13 v1.17 DELETE START
    || ' AND xrpm.doc_type = itp.doc_type' 
    || ' AND xrpm.doc_type = ''OMSO'''
    || ' AND xrpm.dealings_div = ''103''' 
    || ' AND xrpm.shipment_provision_div = otta.attribute1' 
    || ' AND xrpm.ship_prov_rcv_pay_category = otta.attribute11' 
    || ' AND (xrpm.item_div_origin = mcb2.segment1' 
    || ' OR xrpm.item_div_origin IS NULL)' 
    || ' AND xrpm.break_col_06 IS NOT NULL'
    || ' AND xrpm.item_div_origin IS NULL' 
-- 2009/01/21 v1.24 N.Yoshida ADD START
    || ' AND itp.whse_code = iwm.whse_code'
-- 2009/01/21 v1.24 N.Yoshida ADD END
-- 2008/12/13 v1.16 ADD START
--    || ' AND hla.location_code  = ooha.attribute11'
--    || ' AND hla.location_id    = xla.location_id'
--    || ' AND mct.category_id   = mcb2.category_id'
--    || ' AND hla.inactive_date  IS NULL'
--    || ' AND xla.start_date_active <= TRUNC(SYSDATE)'
--    || ' AND xla.end_date_active   >= TRUNC(SYSDATE)'
--    || ' AND mct.source_lang   = ''JA'''
--    || ' AND mct.language      = ''JA'''
-- 2008/12/13 v1.16 ADD END
    ;
-- 
 -- OMSO_105
 -- パターン:1
    lv_select_1_om105 :=
       ' FROM ' 
    || ' ic_tran_pnd itp'
    || ' ,wsh_delivery_details wdd'
--    || ' ,oe_order_lines_all oola'
    || ' ,oe_order_headers_all ooha'
    || ' ,oe_transaction_types_all otta'
    || ' ,xxwsh_order_headers_all xoha'
    || ' ,xxwsh_order_lines_all xola'
    || ' ,gmi_item_categories gic1'
    || ' ,mtl_categories_b mcb1'
    || ' ,gmi_item_categories gic2'
    || ' ,mtl_categories_b mcb2'
    || ' ,gmi_item_categories gic3'
    || ' ,mtl_categories_b mcb3'
    || ' ,gmi_item_categories gic4'
    || ' ,mtl_categories_b mcb4'
    || ' ,ic_item_mst_b iimb'
    || ' ,xxcmn_item_mst_b ximb'
    || ' ,ic_lots_mst ilm'
    || ' ,xxcmn_lot_cost xlc'
    || ' ,ic_item_mst_b iimb2'
    || ' ,xxcmn_item_mst_b ximb2'
--    || ' ,ic_item_mst_b iimb3'
-- 2009/01/09 v1.22 UPDATE START
-- 2009/01/22 v1.24 UPDATE START
    || ' ,xxcmn_stnd_unit_price_v xsupv' -- 標準原価情報View 
-- 2009/01/22 v1.24 UPDATE END
-- 2009/01/09 v1.22 UPDATE END
    || ' ,po_vendor_sites_all pvsa' -- 仕入先サイトマスタ 
    || ' ,po_vendors pv' -- 仕入先マスタ 
-- 2008/12/13 v1.17 DELETE START
--    || ' ,xxcmn_parties2_v xpv' -- パーティ情報View2 
-- 2008/12/13 v1.17 DELETE END
    || ' ,xxcmn_rcv_pay_mst xrpm'
-- 2008/12/13 v1.16 ADD START
-- 2009/01/21 v1.24 N.Yoshida ADD START
    || ' ,ic_whse_mst iwm'
-- 2009/01/21 v1.24 N.Yoshida ADD END
--    || ' ,hr_locations_all  hla '
--    || ' ,xxcmn_locations_all xla '
--    || ' ,mtl_categories_tl mct '
-- 2008/12/13 v1.16 ADD END
    || ' WHERE itp.doc_type = ''OMSO''' 
    || ' AND itp.completed_ind = 1' 
--    || ' AND itp.trans_date >= FND_DATE.STRING_TO_DATE(''' || ir_param.proc_from    || ''',''yyyymm'')'
--    || ' AND itp.trans_date < ADD_MONTHS( FND_DATE.STRING_TO_DATE(''' || ir_param.proc_to    || ''',''yyyymm''),1)'
    || ' AND xoha.latest_external_flag = ''Y'''
    || ' AND xoha.arrival_date >= FND_DATE.STRING_TO_DATE(''' || ir_param.proc_from    || ''',''yyyymm'')'
    || ' AND xoha.arrival_date < ADD_MONTHS( FND_DATE.STRING_TO_DATE(''' || ir_param.proc_to    || ''',''yyyymm''),1)'
    || ' AND xoha.req_status = ''08''' 
    || ' AND gic1.item_id = iimb2.item_id' 
    || ' AND gic1.category_set_id = ''' || cn_prod_class_id    || ''''
    || ' AND gic1.category_id = mcb1.category_id' 
    || ' AND mcb1.segment1 = ''' || ir_param.prod_div    || ''''
    || ' AND gic2.item_id = iimb2.item_id' 
    || ' AND gic2.category_set_id = ''' || cn_item_class_id    || ''''
    || ' AND gic2.category_id = mcb2.category_id' 
    || ' AND mcb2.segment1 = ''5''' 
    || ' AND gic3.item_id = iimb2.item_id' 
    || ' AND gic3.category_id = mcb3.category_id' 
    || ' AND gic4.item_id = itp.item_id' 
    || ' AND gic4.category_set_id = ''' || cn_item_class_id    || ''''
    || ' AND gic4.category_id = mcb4.category_id' 
    || ' AND mcb4.segment1 IN (''1'',''2'',''4'')' 
    || ' AND xrpm.item_div_ahead = mcb2.segment1' 
    || ' AND ilm.item_id = itp.item_id' 
    || ' AND ilm.lot_id = itp.lot_id' 
    || ' AND iimb.item_id = ilm.item_id' 
    || ' AND xlc.item_id(+) = ilm.item_id' 
    || ' AND xlc.lot_id (+) = ilm.lot_id'
    || ' AND ximb.item_id = iimb.item_id' 
    || ' AND ximb.start_date_active <= TRUNC(itp.trans_date)' 
    || ' AND ximb.end_date_active >= TRUNC(itp.trans_date)' 
    || ' AND wdd.delivery_detail_id = itp.line_detail_id' 
--    || ' AND oola.org_id = wdd.org_id' 
--    || ' AND oola.header_id = wdd.source_header_id' 
--    || ' AND oola.line_id = wdd.source_line_id' 
--    || ' AND ooha.header_id = wdd.source_header_id' 
    || ' AND otta.transaction_type_id = ooha.order_type_id' 
    || ' AND ((otta.attribute4 <> ''2'')' 
    || ' OR (otta.attribute4 IS NULL))' 
--    || ' AND xoha.header_id = ooha.header_id' 
--    || ' AND xola.line_id = wdd.source_line_id'
    || ' AND xoha.header_id = wdd.source_header_id' 
    || ' AND xoha.header_id = ooha.header_id' 
    || ' AND xola.order_header_id = xoha.order_header_id' 
    || ' AND xola.line_id = wdd.source_line_id' 
    || ' AND iimb2.item_no = xola.request_item_code' 
    || ' AND ximb2.item_id = iimb2.item_id' 
    || ' AND ximb2.start_date_active <= TRUNC(itp.trans_date)' 
    || ' AND ximb2.end_date_active >= TRUNC(itp.trans_date)' 
-- 2009/01/09 v1.22 UPDATE START
--    || ' AND xsupv.item_id = iimb2.item_id' 
--    || ' AND xsupv.start_date_active <= TRUNC(itp.trans_date)' 
--    || ' AND xsupv.end_date_active >= TRUNC(itp.trans_date)' 
-- 2009/01/09 v1.22 UPDATE START
---- 2009/01/22 v1.24 UPDATE START
--    || ' AND xsupv.item_id(+) = iimb2.item_id' 
--    || ' AND NVL(xsupv.start_date_active, TRUNC(itp.trans_date)) <= TRUNC(itp.trans_date)' 
--    || ' AND NVL(xsupv.end_date_active, TRUNC(itp.trans_date)) >= TRUNC(itp.trans_date)' 
---- 2009/01/22 v1.24 UPDATE START
-- 2009/05/29 MOD START v1.24 DEL
    || ' AND xsupv.item_id(+) = iimb2.item_id' 
    || ' AND NVL(xsupv.start_date_active, TRUNC(xoha.arrival_date)) <= TRUNC(xoha.arrival_date)' 
    || ' AND NVL(xsupv.end_date_active, TRUNC(xoha.arrival_date)) >= TRUNC(xoha.arrival_date)' 
-- 2009/05/29 MOD END
-- 2009/01/09 v1.22 UPDATE END
-- 2009/01/09 v1.22 UPDATE END
    || ' AND pvsa.vendor_site_id = xoha.vendor_site_id' 
    || ' AND pv.vendor_id = pvsa.vendor_id' 
-- 2008/12/13 v1.16 UPDATE START
--    || ' AND pv.customer_num = xpv.account_number' 
--    || ' AND xoha.customer_id = xpv.party_id' 
-- 2008/12/13 v1.16 UPDATE END
-- 2008/12/13 v1.17 DELETE START
--    || ' AND xpv.start_date_active <= TRUNC(itp.trans_date)' 
--    || ' AND xpv.end_date_active >= TRUNC(itp.trans_date)' 
-- 2008/12/13 v1.17 DELETE START
    || ' AND xrpm.doc_type = itp.doc_type' 
    || ' AND xrpm.doc_type = ''OMSO'''
    || ' AND xrpm.dealings_div = ''105''' 
    || ' AND xrpm.shipment_provision_div = otta.attribute1' 
    || ' AND xrpm.ship_prov_rcv_pay_category = otta.attribute11' 
    || ' AND xrpm.break_col_06 IS NOT NULL'
-- 2009/01/21 v1.24 N.Yoshida ADD START
    || ' AND itp.whse_code = iwm.whse_code'
-- 2009/01/21 v1.24 N.Yoshida ADD END
-- 2008/12/13 v1.16 ADD START
--    || ' AND hla.location_code  = ooha.attribute11'
--    || ' AND hla.location_id    = xla.location_id'
--    || ' AND mct.category_id   = mcb2.category_id'
--    || ' AND hla.inactive_date  IS NULL'
--    || ' AND xla.start_date_active <= TRUNC(SYSDATE)'
--    || ' AND xla.end_date_active   >= TRUNC(SYSDATE)'
--    || ' AND mct.source_lang   = ''JA'''
--    || ' AND mct.language      = ''JA'''
-- 2008/12/13 v1.16 ADD END
    ;
-- 
 -- OMSO_108
 -- パターン:1
    lv_select_1_om108 :=
       ' FROM ' 
    || ' ic_tran_pnd itp'
    || ' ,wsh_delivery_details wdd'
--    || ' ,oe_order_lines_all oola'
    || ' ,oe_order_headers_all ooha'
    || ' ,oe_transaction_types_all otta'
    || ' ,xxwsh_order_headers_all xoha'
    || ' ,xxwsh_order_lines_all xola'
    || ' ,gmi_item_categories gic1'
    || ' ,mtl_categories_b mcb1'
    || ' ,gmi_item_categories gic2'
    || ' ,mtl_categories_b mcb2'
    || ' ,gmi_item_categories gic3'
    || ' ,mtl_categories_b mcb3'
    || ' ,gmi_item_categories gic4'
    || ' ,mtl_categories_b mcb4'
    || ' ,gmi_item_categories gic5'
    || ' ,mtl_categories_b mcb5'
    || ' ,ic_item_mst_b iimb'
    || ' ,xxcmn_item_mst_b ximb'
    || ' ,ic_lots_mst ilm'
    || ' ,xxcmn_lot_cost xlc'
    || ' ,ic_item_mst_b iimb2'
    || ' ,xxcmn_item_mst_b ximb2'
--    || ' ,ic_item_mst_b iimb3'
-- 2009/01/09 v1.22 UPDATE START
-- 2009/01/22 v1.24 UPDATE START
    || ' ,xxcmn_stnd_unit_price_v xsupv' -- 標準原価情報View 
-- 2009/01/22 v1.24 UPDATE END
-- 2009/01/09 v1.22 UPDATE END
    || ' ,po_vendor_sites_all pvsa' -- 仕入先サイトマスタ 
    || ' ,po_vendors pv' -- 仕入先マスタ 
-- 2008/12/13 v1.17 DELETE START
--    || ' ,xxcmn_parties2_v xpv' -- パーティ情報View2 
-- 2008/12/13 v1.17 DELETE END
    || ' ,xxcmn_rcv_pay_mst xrpm'
-- 2008/12/13 v1.16 ADD START
-- 2009/01/21 v1.24 N.Yoshida ADD START
    || ' ,ic_whse_mst iwm'
-- 2009/01/21 v1.24 N.Yoshida ADD END
--    || ' ,hr_locations_all  hla '
--    || ' ,xxcmn_locations_all xla '
--    || ' ,mtl_categories_tl mct '
-- 2008/12/13 v1.16 ADD END
    || ' WHERE itp.doc_type = ''OMSO''' 
    || ' AND itp.completed_ind = 1' 
--    || ' AND itp.trans_date >= FND_DATE.STRING_TO_DATE(''' || ir_param.proc_from    || ''',''yyyymm'')'
--    || ' AND itp.trans_date < ADD_MONTHS( FND_DATE.STRING_TO_DATE(''' || ir_param.proc_to    || ''',''yyyymm''),1)'
    || ' AND xoha.latest_external_flag = ''Y'''
    || ' AND xoha.arrival_date >= FND_DATE.STRING_TO_DATE(''' || ir_param.proc_from    || ''',''yyyymm'')'
    || ' AND xoha.arrival_date < ADD_MONTHS( FND_DATE.STRING_TO_DATE(''' || ir_param.proc_to    || ''',''yyyymm''),1)'
    || ' AND xoha.req_status = ''08''' 
    || ' AND gic1.item_id = iimb2.item_id' 
    || ' AND gic1.category_set_id = ''' || cn_prod_class_id    || ''''
    || ' AND gic1.category_id = mcb1.category_id' 
    || ' AND mcb1.segment1 = ''' || ir_param.prod_div    || ''''
    || ' AND mcb1.segment1 = ''1''' 
    || ' AND gic2.item_id = iimb2.item_id' 
    || ' AND gic2.category_set_id = ''' || cn_item_class_id    || ''''
    || ' AND gic2.category_id = mcb2.category_id' 
    || ' AND mcb2.segment1 = ''5''' 
    || ' AND gic3.item_id = iimb2.item_id' 
    || ' AND gic3.category_set_id = ''' || cn_crowd_code_id    || ''''
    || ' AND gic3.category_id = mcb3.category_id' 
    || ' AND gic4.item_id = itp.item_id' 
    || ' AND gic4.category_set_id = ''' || cn_item_class_id    || ''''
    || ' AND gic4.category_id = mcb4.category_id' 
    || ' AND mcb4.segment1 = ''5''' 
    || ' AND gic5.item_id = itp.item_id' 
    || ' AND gic5.category_set_id = ''' || cn_prod_class_id    || ''''
    || ' AND gic5.category_id = mcb5.category_id' 
    || ' AND mcb5.segment1 = ''2''' 
    || ' AND ilm.item_id = itp.item_id' 
    || ' AND ilm.lot_id = itp.lot_id' 
    || ' AND iimb.item_id = ilm.item_id' 
    || ' AND xlc.item_id(+) = ilm.item_id' 
    || ' AND xlc.lot_id (+) = ilm.lot_id'
    || ' AND ximb.item_id = iimb.item_id' 
    || ' AND ximb.start_date_active <= TRUNC(itp.trans_date)' 
    || ' AND ximb.end_date_active >= TRUNC(itp.trans_date)' 
    || ' AND wdd.delivery_detail_id = itp.line_detail_id' 
--    || ' AND oola.org_id = wdd.org_id' 
--    || ' AND oola.header_id = wdd.source_header_id' 
--    || ' AND oola.line_id = wdd.source_line_id' 
--    || ' AND ooha.header_id = wdd.source_header_id' 
    || ' AND otta.transaction_type_id = ooha.order_type_id' 
    || ' AND ((otta.attribute4 <> ''2'')' 
    || ' OR (otta.attribute4 IS NULL))' 
--    || ' AND xoha.header_id = ooha.header_id' 
--    || ' AND xola.line_id = wdd.source_line_id'
    || ' AND xoha.header_id = wdd.source_header_id' 
    || ' AND xoha.header_id = ooha.header_id' 
    || ' AND xola.order_header_id = xoha.order_header_id' 
    || ' AND xola.line_id  = wdd.source_line_id' 
    || ' AND iimb2.item_no = xola.request_item_code' 
    || ' AND ximb2.item_id = iimb2.item_id' 
    || ' AND ximb2.start_date_active <= TRUNC(itp.trans_date)' 
    || ' AND ximb2.end_date_active >= TRUNC(itp.trans_date)' 
-- 2009/01/09 v1.22 UPDATE START
--    || ' AND xsupv.item_id = iimb2.item_id' 
--    || ' AND xsupv.start_date_active <= TRUNC(itp.trans_date)' 
--    || ' AND xsupv.end_date_active >= TRUNC(itp.trans_date)' 
-- 2009/01/09 v1.22 UPDATE START
---- 2009/01/22 v1.24 UPDATE START
--    || ' AND xsupv.item_id(+) = iimb2.item_id' 
--    || ' AND NVL(xsupv.start_date_active, TRUNC(itp.trans_date)) <= TRUNC(itp.trans_date)' 
--    || ' AND NVL(xsupv.end_date_active, TRUNC(itp.trans_date)) >= TRUNC(itp.trans_date)' 
---- 2009/01/22 v1.24 UPDATE START
-- 2009/05/29 MOD START v1.24 DEL
    || ' AND xsupv.item_id(+) = iimb2.item_id' 
    || ' AND NVL(xsupv.start_date_active, TRUNC(xoha.arrival_date)) <= TRUNC(xoha.arrival_date)' 
    || ' AND NVL(xsupv.end_date_active, TRUNC(xoha.arrival_date)) >= TRUNC(xoha.arrival_date)' 
-- 2009/05/29 MOD END
-- 2009/01/09 v1.22 UPDATE END
-- 2009/01/09 v1.22 UPDATE END
    || ' AND pvsa.vendor_site_id = xoha.vendor_site_id' 
    || ' AND pv.vendor_id = pvsa.vendor_id' 
-- 2008/12/13 v1.16 UPDATE START
--    || ' AND pv.customer_num = xpv.account_number' 
--    || ' AND xoha.customer_id = xpv.party_id' 
-- 2008/12/13 v1.16 UPDATE END
-- 2008/12/13 v1.17 DELETE START
--    || ' AND xpv.start_date_active <= TRUNC(itp.trans_date)' 
--    || ' AND xpv.end_date_active >= TRUNC(itp.trans_date)' 
-- 2008/12/13 v1.17 DELETE START
    || ' AND xrpm.doc_type = itp.doc_type' 
    || ' AND xrpm.doc_type = ''OMSO'''
    || ' AND xrpm.dealings_div = ''108''' 
    || ' AND xrpm.shipment_provision_div = otta.attribute1' 
    || ' AND xrpm.ship_prov_rcv_pay_category = otta.attribute11' 
    || ' AND xrpm.break_col_06 IS NOT NULL'
-- 2009/01/21 v1.24 N.Yoshida ADD START
    || ' AND itp.whse_code = iwm.whse_code'
-- 2009/01/21 v1.24 N.Yoshida ADD END
-- 2008/12/13 v1.16 ADD START
--    || ' AND hla.location_code  = ooha.attribute11'
--    || ' AND hla.location_id    = xla.location_id'
--    || ' AND mct.category_id   = mcb2.category_id'
--    || ' AND hla.inactive_date  IS NULL'
--    || ' AND xla.start_date_active <= TRUNC(SYSDATE)'
--    || ' AND xla.end_date_active   >= TRUNC(SYSDATE)'
--    || ' AND mct.source_lang   = ''JA'''
--    || ' AND mct.language      = ''JA'''
-- 2008/12/13 v1.16 ADD END
    ;
---------------------------
--  パターン別ヒント句
---------------------------
 --===============================================================
 -- GROUP1 PTN01
 --===============================================================
-- 2009/01/22 v1.24 UPDATE START
-- ヒント句にpush_pred(xsupv)を一律追加
-- 2009/01/22 v1.24 UPDATE START
--
 -- PORC_102
    lv_select_g1_po102_1_hint :=
       --' SELECT /*+ leading(itp gic2 mcb2 gic1 mcb1 rsl ooha otta) use_nl(itp gic2 mcb2 gic1 mcb1 rsl ooha otta) */'; 
-- 2008/12/17 v1.20 UPDTE START
--       ' SELECT /*+ leading (xoha xola rsl itp gic1 mcb1 gic2 mcb2 ooha otta) use_nl (xoha xola rsl itp gic1 mcb1 gic2 mcb2 ooha otta) */'; 
       ' SELECT /*+ leading (xoha xola rsl itp gic1 mcb1 gic2 mcb2 ooha otta) use_nl (xoha xola rsl itp gic1 mcb1 gic2 mcb2 ooha otta) push_pred(xsupv) */'; 
-- 2008/12/17 v1.20 UPDTE END
--
 -- PORC_101
    lv_select_g1_po101_1_hint :=
       --' SELECT /*+ leading(itp gic2 mcb2 gic1 mcb1 rsl ooha otta) use_nl(itp gic2 mcb2 gic1 mcb1 rsl ooha otta) */'; 
       ' SELECT /*+ leading (xoha xola rsl itp gic1 mcb1 gic2 mcb2 ooha otta) use_nl (xoha xola rsl itp gic1 mcb1 gic2 mcb2 ooha otta) push_pred(xsupv) */'; 
--
 -- PORC_112
    lv_select_g1_po112_1_hint :=
       --' SELECT /*+ leading(itp rsl xola iimb3 gic2 mcb2 gic1 mcb1 ooha otta) use_nl(itp rsl xola iimb3 gic2 mcb2 gic1 mcb1 ooha otta) */'; 
       --' SELECT /*+ leading (itp rsl xoha xola iimb2 gic2 mcb2 gic1 mcb1 ooha otta) use_nl (itp rsl xoha xola iimb2 gic2 mcb2 gic1 mcb1 ooha otta) */'; 
-- 2008/12/17 v1.20 UPDATE START
--       ' SELECT /*+ leading (xoha xola iimb2 gic2 mcb2 gic1 mcb1 ooha otta) use_nl (xoha xola iimb2 gic2 mcb2 gic1 mcb1 ooha otta) */';
       ' SELECT /*+ leading (xoha ooha otta xola iimb2 gic1 mcb1 gic2 mcb2) use_nl (xoha ooha otta xola iimb2 gic1 mcb1 gic2 mcb2) push_pred(xsupv) */';
-- 2008/12/17 v1.20 UPDATE END
--
 -- PORC_103_5
    lv_select_g1_po103x5_1_hint :=
       --' SELECT /*+ leading(itp gic2 mcb2 gic1 mcb1 rsl ooha otta) use_nl(itp gic2 mcb2 gic1 mcb1 rsl ooha otta) */'; 
       ' SELECT /*+ leading (xoha xola rsl itp gic1 mcb1 gic2 mcb2 ooha otta) use_nl (xoha xola rsl itp gic1 mcb1 gic2 mcb2 ooha otta) push_pred(xsupv) */'; 
-- 
 -- PORC_103_124
    lv_select_g1_po103x124_1_hint :=
       --' SELECT /*+ leading(itp gic2 mcb2 gic1 mcb1 rsl ooha otta) use_nl(itp gic2 mcb2 gic1 mcb1 rsl ooha otta) */'; 
       ' SELECT /*+ leading (xoha xola rsl itp gic1 mcb1 gic2 mcb2 ooha otta) use_nl (xoha xola rsl itp gic1 mcb1 gic2 mcb2 ooha otta) push_pred(xsupv) */'; 
-- 
 -- PORC_105
    lv_select_g1_po105_1_hint :=
       --' SELECT /*+ leading(itp rsl xola iimb3 gic2 mcb2 gic1 mcb1 ooha otta) use_nl(itp rsl xola iimb3 gic2 mcb2 gic1 mcb1 ooha otta) */'; 
       --' SELECT /*+ leading (itp rsl xoha xola iimb2 gic2 mcb2 gic1 mcb1 ooha otta) use_nl (itp rsl xoha xola iimb2 gic2 mcb2 gic1 mcb1 ooha otta) */'; 
       ' SELECT /*+ leading (xoha xola iimb2 gic2 mcb2 gic1 mcb1 ooha otta) use_nl (xoha xola iimb2 gic2 mcb2 gic1 mcb1 ooha otta) push_pred(xsupv) */'; 
-- 
 -- PORC_108
    lv_select_g1_po108_1_hint :=
       --' SELECT /*+ leading(itp gic4 mcb4 gic5 mcb5 rsl xola iimb3 gic2 mcb2 gic1 mcb1 ooha otta) use_nl(itp gic4 mcb4 gic5 mcb5 rsl xola iimb3 gic2 mcb2 gic1 mcb1 ooha otta) */'; 
       --' SELECT /*+ leading (itp rsl xoha xola iimb2 gic2 mcb2 gic1 mcb1 ooha otta) use_nl (itp rsl xoha xola iimb2 gic2 mcb2 gic1 mcb1 ooha otta) */'; 
       ' SELECT /*+ leading (xoha xola iimb2 gic2 mcb2 gic1 mcb1 ooha otta) use_nl (xoha xola iimb2 gic2 mcb2 gic1 mcb1 ooha otta) push_pred(xsupv) */'; 
-- 
 -- OMSO_102
    lv_select_g1_om102_1_hint :=
       --' SELECT /*+ leading(itp gic2 mcb2 gic1 mcb1 wdd ooha otta) use_nl(itp gic2 mcb2 gic1 mcb1 wdd ooha otta)*/';
-- 2008/12/17 v1.20 UPDATE START
--       ' SELECT /*+ leading (xoha xola wdd itp gic1 mcb1 gic2 mcb2 ooha otta) use_nl (xoha xola wdd itp gic1 mcb1 gic2 mcb2 ooha otta) */';
       ' SELECT /*+ leading (xoha xola wdd itp gic1 mcb1 gic2 mcb2 ooha otta xrpm) use_nl (xoha xola wdd itp gic1 mcb1 gic2 mcb2 ooha otta xrpm) push_pred(xsupv) */';
-- 2008/12/17 v1.20 UPDATE END
-- 
 -- OMSO_101
    lv_select_g1_om101_1_hint :=
       --' SELECT /*+ leading(itp gic2 mcb2 gic1 mcb1 wdd ooha otta) use_nl(itp gic2 mcb2 gic1 mcb1 wdd ooha otta)*/';
       ' SELECT /*+ leading (xoha xola wdd itp gic1 mcb1 gic2 mcb2 ooha otta) use_nl (xoha xola wdd itp gic1 mcb1 gic2 mcb2 ooha otta) push_pred(xsupv) */';
-- 
 -- OMSO_112
    lv_select_g1_om112_1_hint :=
       --' SELECT /*+ leading(itp wdd xola iimb3 gic2 mcb2 gic1 mcb1 ooha otta) use_nl(itp wdd xola iimb3 gic2 mcb2 gic1 mcb1 ooha otta)*/';
       ' SELECT /*+ leading (xoha xola iimb2 gic1 mcb1 gic2 mcb2 ooha otta xrpm wdd itp) use_nl (xoha xola iimb2 gic1 mcb1 gic2 mcb2 ooha otta xrpm wdd itp) push_pred(xsupv) */';
-- 
 -- OMSO_103_5
    lv_select_g1_om103x5_1_hint :=
       --' SELECT /*+ leading(itp gic2 mcb2 gic1 mcb1 wdd ooha otta) use_nl(itp gic2 mcb2 gic1 mcb1 wdd ooha otta)*/';
-- 2008/12/17 v1.20 UPDATE START
--       ' SELECT /*+ leading (xoha xola wdd itp gic1 mcb1 gic2 mcb2 ooha otta) use_nl (xoha xola wdd itp gic1 mcb1 gic2 mcb2 ooha otta) */';
       ' SELECT /*+ leading (xoha ooha otta xola wdd itp gic1 mcb1 gic2 mcb2) use_nl (xoha ooha otta xola wdd itp gic1 mcb1 gic2 mcb2) push_pred(xsupv) */';
-- 2008/12/17 v1.20 UPDATE END
-- 
 -- OMSO_103_124
    lv_select_g1_om103x124_1_hint :=
       --' SELECT /*+ leading(itp gic2 mcb2 gic1 mcb1 wdd ooha otta) use_nl(itp gic2 mcb2 gic1 mcb1 wdd ooha otta)*/';
       ' SELECT /*+ leading (xoha xola wdd itp gic1 mcb1 gic2 mcb2 ooha otta) use_nl (xoha xola wdd itp gic1 mcb1 gic2 mcb2 ooha otta) push_pred(xsupv) */';
-- 
 -- OMSO_105
    lv_select_g1_om105_1_hint :=
       --' SELECT /*+ leading(itp wdd xola iimb3 gic2 mcb2 gic1 mcb1 ooha otta xrpm) use_nl(itp wdd xola iimb3 gic2 mcb2 gic1 mcb1 ooha otta xrpm) */';
       ' SELECT /*+ leading (xoha xola iimb2 gic1 mcb1 gic2 mcb2 ooha otta xrpm wdd itp) use_nl (xoha xola iimb2 gic1 mcb1 gic2 mcb2 ooha otta xrpm wdd itp) push_pred(xsupv) */';
-- 
 -- OMSO_108
    lv_select_g1_om108_1_hint :=
       --' SELECT /*+ leading(itp gic4 mcb4 gic5 mcb5 wdd xola iimb3 gic2 mcb2 gic1 mcb1 ooha otta) use_nl(itp gic4 mcb4 gic5 mcb5 wdd xola iimb3 gic2 mcb2 gic1 mcb1 ooha otta) */';
       ' SELECT /*+ leading (xoha xola iimb2 gic1 mcb1 gic2 mcb2 ooha otta xrpm wdd itp) use_nl (xoha xola iimb2 gic1 mcb1 gic2 mcb2 ooha otta xrpm wdd itp) push_pred(xsupv) */';

 --===============================================================
 -- GROUP1 PTN02
 --===============================================================
-- 
 -- PORC_102
    lv_select_g1_po102_2_hint :=
       --' SELECT /*+ leading(itp gic2 mcb2 gic1 mcb1 rsl ooha otta) use_nl(itp gic2 mcb2 gic1 mcb1 rsl ooha otta) */'; 
       ' SELECT /*+ leading (xoha xola rsl itp gic1 mcb1 gic2 mcb2 ooha otta) use_nl (xoha xola rsl itp gic1 mcb1 gic2 mcb2 ooha otta) push_pred(xsupv) */'; 
--
 -- PORC_101
    lv_select_g1_po101_2_hint :=
       --' SELECT /*+ leading(itp gic2 mcb2 gic1 mcb1 rsl ooha otta) use_nl(itp gic2 mcb2 gic1 mcb1 rsl ooha otta) */'; 
       ' SELECT /*+ leading (xoha xola rsl itp gic1 mcb1 gic2 mcb2 ooha otta) use_nl (xoha xola rsl itp gic1 mcb1 gic2 mcb2 ooha otta) push_pred(xsupv) */'; 
--
 -- PORC_112
    lv_select_g1_po112_2_hint :=
       --' SELECT /*+ leading(itp rsl xola iimb3 gic2 mcb2 gic1 mcb1 ooha otta) use_nl(itp rsl xola iimb3 gic2 mcb2 gic1 mcb1 ooha otta) */'; 
       --' SELECT /*+ leading (itp rsl xoha xola iimb2 gic2 mcb2 gic1 mcb1 ooha otta) use_nl (itp rsl xoha xola iimb2 gic2 mcb2 gic1 mcb1 ooha otta) */'; 
       ' SELECT /*+ leading (xoha xola iimb2 gic2 mcb2 gic1 mcb1 ooha otta) use_nl (xoha xola iimb2 gic2 mcb2 gic1 mcb1 ooha otta) push_pred(xsupv) */';
--
 -- PORC_103_5
    lv_select_g1_po103x5_2_hint :=
       --' SELECT /*+ leading(itp gic2 mcb2 gic1 mcb1 rsl ooha otta) use_nl(itp gic2 mcb2 gic1 mcb1 rsl ooha otta) */'; 
       ' SELECT /*+ leading (xoha xola rsl itp gic1 mcb1 gic2 mcb2 ooha otta) use_nl (xoha xola rsl itp gic1 mcb1 gic2 mcb2 ooha otta) push_pred(xsupv) */'; 
-- 
 -- PORC_103_124
    lv_select_g1_po103x124_2_hint :=
       --' SELECT /*+ leading(itp gic2 mcb2 gic1 mcb1 rsl ooha otta) use_nl(itp gic2 mcb2 gic1 mcb1 rsl ooha otta) */'; 
       ' SELECT /*+ leading (xoha xola rsl itp gic1 mcb1 gic2 mcb2 ooha otta) use_nl (xoha xola rsl itp gic1 mcb1 gic2 mcb2 ooha otta) push_pred(xsupv) */'; 
-- 
 -- PORC_105
    lv_select_g1_po105_2_hint :=
       --' SELECT /*+ leading(itp rsl xola iimb3 gic2 mcb2 gic1 mcb1 ooha otta) use_nl(itp rsl xola iimb3 gic2 mcb2 gic1 mcb1 ooha otta) */'; 
       --' SELECT /*+ leading (itp rsl xoha xola iimb2 gic2 mcb2 gic1 mcb1 ooha otta) use_nl (itp rsl xoha xola iimb2 gic2 mcb2 gic1 mcb1 ooha otta) */'; 
       ' SELECT /*+ leading (xoha xola iimb2 gic2 mcb2 gic1 mcb1 ooha otta) use_nl (xoha xola iimb2 gic2 mcb2 gic1 mcb1 ooha otta) push_pred(xsupv) */'; 
-- 
 -- PORC_108
    lv_select_g1_po108_2_hint :=
       --' SELECT /*+ leading(itp rsl xola iimb3 gic2 mcb2 gic1 mcb1 gic4 mcb4 gic5 mcb5 ooha otta) use_nl(itp rsl xola iimb3 gic2 mcb2 gic1 gic4 mcb4 gic5 mcb5 mcb1 ooha otta) */'; 
       --' SELECT /*+ leading (itp rsl xoha xola iimb2 gic2 mcb2 gic1 mcb1 ooha otta) use_nl (itp rsl xoha xola iimb2 gic2 mcb2 gic1 mcb1 ooha otta) */'; 
       ' SELECT /*+ leading (xoha xola iimb2 gic2 mcb2 gic1 mcb1 ooha otta) use_nl (xoha xola iimb2 gic2 mcb2 gic1 mcb1 ooha otta) push_pred(xsupv) */'; 
-- 
 -- OMSO_102
    lv_select_g1_om102_2_hint :=
       --' SELECT /*+ leading(itp gic2 mcb2 gic1 mcb1 wdd ooha otta) use_nl(itp gic2 mcb2 gic1 mcb1 wdd ooha otta)*/';
       ' SELECT /*+ leading (xoha xola wdd itp gic1 mcb1 gic2 mcb2 ooha otta) use_nl (xoha xola wdd itp gic1 mcb1 gic2 mcb2 ooha otta) push_pred(xsupv) */';
-- 
 -- OMSO_101
    lv_select_g1_om101_2_hint :=
       --' SELECT /*+ leading(itp gic2 mcb2 gic1 mcb1 wdd ooha otta) use_nl(itp gic2 mcb2 gic1 mcb1 wdd ooha otta)*/';
       ' SELECT /*+ leading (xoha xola wdd itp gic1 mcb1 gic2 mcb2 ooha otta) use_nl (xoha xola wdd itp gic1 mcb1 gic2 mcb2 ooha otta) push_pred(xsupv) */';
-- 
 -- OMSO_112
    lv_select_g1_om112_2_hint :=
       --' SELECT /*+ leading(itp wdd xola iimb3 gic2 mcb2 gic1 mcb1 ooha otta) use_nl(itp wdd xola iimb3 gic2 mcb2 gic1 mcb1 ooha otta)*/';
       ' SELECT /*+ leading (xoha xola iimb2 gic1 mcb1 gic2 mcb2 ooha otta xrpm wdd itp) use_nl (xoha xola iimb2 gic1 mcb1 gic2 mcb2 ooha otta xrpm wdd itp) push_pred(xsupv) */';
-- 
 -- OMSO_103_5
    lv_select_g1_om103x5_2_hint :=
       --' SELECT /*+ leading(itp gic2 mcb2 gic1 mcb1 wdd ooha otta) use_nl(itp gic2 mcb2 gic1 mcb1 wdd ooha otta)*/';
       ' SELECT /*+ leading (xoha xola wdd itp gic1 mcb1 gic2 mcb2 ooha otta) use_nl (xoha xola wdd itp gic1 mcb1 gic2 mcb2 ooha otta) push_pred(xsupv) */';
-- 
 -- OMSO_103_124
    lv_select_g1_om103x124_2_hint :=
       --' SELECT /*+ leading(itp gic2 mcb2 gic1 mcb1 wdd ooha otta) use_nl(itp gic2 mcb2 gic1 mcb1 wdd ooha otta)*/';
       ' SELECT /*+ leading (xoha xola wdd itp gic1 mcb1 gic2 mcb2 ooha otta) use_nl (xoha xola wdd itp gic1 mcb1 gic2 mcb2 ooha otta) push_pred(xsupv) */';
-- 
 -- OMSO_105
    lv_select_g1_om105_2_hint :=
       --' SELECT /*+ leading(itp wdd xola iimb3 gic2 mcb2 gic1 mcb1 ooha otta xrpm) use_nl(itp wdd xola iimb3 gic2 mcb2 gic1 mcb1 ooha otta xrpm) */';
       ' SELECT /*+ leading (xoha xola iimb2 gic1 mcb1 gic2 mcb2 ooha otta xrpm wdd itp) use_nl (xoha xola iimb2 gic1 mcb1 gic2 mcb2 ooha otta xrpm wdd itp) push_pred(xsupv) */';
-- 
 -- OMSO_108
    lv_select_g1_om108_2_hint :=
       --' SELECT /*+ leading(itp wdd xola iimb3 gic2 mcb2 gic1 mcb1 gic4 mcb4 gic5 mcb5 ooha otta) use_nl(itp wdd xola iimb3 gic2 mcb2 gic1 mcb1 gic4 mcb4 gic5 mcb5 ooha otta) */';
       ' SELECT /*+ leading (xoha xola iimb2 gic1 mcb1 gic2 mcb2 ooha otta xrpm wdd itp) use_nl (xoha xola iimb2 gic1 mcb1 gic2 mcb2 ooha otta xrpm wdd itp) push_pred(xsupv) */';
 --===============================================================
 -- GROUP1 PTN03
 --===============================================================
-- 
 -- PORC_102
    lv_select_g1_po102_3_hint :=
       --' SELECT /*+ leading(itp gic3 mcb3 gic2 mcb2 gic1 mcb1 rsl ooha otta) use_nl(itp gic3 mcb3 gic2 mcb2 gic1 mcb1 rsl ooha otta) */'; 
       ' SELECT /*+ leading (xoha xola rsl itp gic3 mcb3 gic1 mcb1 gic2 mcb2 ooha otta) use_nl (xoha xola rsl itp gic3 mcb3 gic1 mcb1 gic2 mcb2 ooha otta) push_pred(xsupv) */'; 
--
 -- PORC_101
    lv_select_g1_po101_3_hint :=
       --' SELECT /*+ leading(itp gic3 mcb3 gic2 mcb2 gic1 mcb1 rsl ooha otta) use_nl(itp gic3 mcb3 gic2 mcb2 gic1 mcb1 rsl ooha otta) */'; 
       ' SELECT /*+ leading (xoha xola rsl itp gic3 mcb3 gic1 mcb1 gic2 mcb2 ooha otta) use_nl (xoha xola rsl itp gic3 mcb3 gic1 mcb1 gic2 mcb2 ooha otta) push_pred(xsupv) */'; 
--
 -- PORC_112
    lv_select_g1_po112_3_hint :=
       --' SELECT /*+ leading(itp rsl xola iimb3 gic3 mcb3 gic2 mcb2 gic1 mcb1 ooha otta) use_nl(itp rsl xola iimb3 gic3 mcb3 gic2 mcb2 gic1 mcb1 ooha otta) */'; 
       --' SELECT /*+ leading (itp rsl xoha xola iimb2 gic3 mcb3 gic2 mcb2 gic1 mcb1 ooha otta) use_nl (itp rsl xoha xola iimb2 gic3 mcb3 gic2 mcb2 gic1 mcb1 ooha otta) */'; 
       ' SELECT /*+ leading (xoha xola iimb2 gic3 mcb3 gic2 mcb2 gic1 mcb1 ooha otta) use_nl (xoha xola gic3 mcb3 iimb2 gic2 mcb2 gic1 mcb1 ooha otta) push_pred(xsupv) */';
--
 -- PORC_103_5
    lv_select_g1_po103x5_3_hint :=
       --' SELECT /*+ leading(itp gic3 mcb3 gic2 mcb2 gic1 mcb1 rsl ooha otta) use_nl(itp gic3 mcb3 gic2 mcb2 gic1 mcb1 rsl ooha otta) */'; 
       ' SELECT /*+ leading (xoha xola rsl itp gic3 mcb3 gic1 mcb1 gic2 mcb2 ooha otta) use_nl (xoha xola rsl itp gic3 mcb3 gic1 mcb1 gic2 mcb2 ooha otta) push_pred(xsupv) */'; 
-- 
 -- PORC_103_124
    lv_select_g1_po103x124_3_hint :=
       --' SELECT /*+ leading(itp gic3 mcb3 gic2 mcb2 gic1 mcb1 rsl ooha otta) use_nl(itp gic3 mcb3 gic2 mcb2 gic1 mcb1 rsl ooha otta) */'; 
       ' SELECT /*+ leading (xoha xola rsl itp gic3 mcb3 gic1 mcb1 gic2 mcb2 ooha otta) use_nl (xoha xola rsl itp gic3 mcb3 gic1 mcb1 gic2 mcb2 ooha otta) push_pred(xsupv) */'; 
-- 
 -- PORC_105
    lv_select_g1_po105_3_hint :=
       --' SELECT /*+ leading(itp rsl xola iimb3 gic3 mcb3 gic2 mcb2 gic1 mcb1 ooha otta) use_nl(itp rsl xola iimb3 gic3 mcb3 gic2 mcb2 gic1 mcb1 ooha otta) */'; 
       --' SELECT /*+ leading (itp rsl xoha xola iimb2 gic3 mcb3 gic2 mcb2 gic1 mcb1 ooha otta) use_nl (itp rsl xoha xola iimb2 gic3 mcb3 gic2 mcb2 gic1 mcb1 ooha otta) */'; 
       ' SELECT /*+ leading (xoha xola iimb2 gic3 mcb3 gic2 mcb2 gic1 mcb1 ooha otta) use_nl (xoha xola iimb2 gic3 mcb3 gic2 mcb2 gic1 mcb1 ooha otta) push_pred(xsupv) */'; 
-- 
 -- PORC_108
    lv_select_g1_po108_3_hint :=
       --' SELECT /*+ leading(itp rsl xola iimb3 gic3 mcb3 gic2 mcb2 gic1 mcb1 gic4 mcb4 gic5 mcb5 ooha otta) use_nl(itp rsl xola iimb3 gic3 mcb3 gic2 mcb2 gic1 mcb1 gic4 mcb4 gic5 mcb5 ooha otta) */'; 
       --' SELECT /*+ leading (itp rsl xoha xola iimb2 gic3 mcb3 gic2 mcb2 gic1 mcb1 ooha otta) use_nl (itp rsl xoha xola iimb2 gic2 mcb2 gic1 mcb1 ooha otta) */'; 
       ' SELECT /*+ leading (xoha xola iimb2 gic3 mcb3 gic2 mcb2 gic1 mcb1 ooha otta) use_nl (xoha xola iimb2 gic3 mcb3 gic2 mcb2 gic1 mcb1 ooha otta) push_pred(xsupv) */'; 
-- 
 -- OMSO_102
    lv_select_g1_om102_3_hint :=
       --' SELECT /*+ leading(itp gic3 mcb3 gic2 mcb2 gic1 mcb1 wdd ooha otta) use_nl(itp gic3 mcb3 gic2 mcb2 gic1 mcb1 wdd ooha otta)*/';
       ' SELECT /*+ leading (xoha xola wdd itp gic3 mcb3 gic1 mcb1 gic2 mcb2 ooha otta) use_nl (xoha xola wdd itp gic3 mcb3 gic1 mcb1 gic2 mcb2 ooha otta) push_pred(xsupv) */';
-- 
 -- OMSO_101
    lv_select_g1_om101_3_hint :=
       --' SELECT /*+ leading(itp gic3 mcb3 gic2 mcb2 gic1 mcb1 wdd ooha otta) use_nl(itp gic3 mcb3 gic2 mcb2 gic1 mcb1 wdd ooha otta)*/';
       ' SELECT /*+ leading (xoha xola wdd itp gic3 mcb3 gic1 mcb1 gic2 mcb2 ooha otta) use_nl (xoha xola wdd itp gic3 mcb3 gic1 mcb1 gic2 mcb2 ooha otta) push_pred(xsupv) */';
-- 
 -- OMSO_112
    lv_select_g1_om112_3_hint :=
       --' SELECT /*+ leading(itp wdd xola iimb3 gic3 mcb3 gic2 mcb2 gic1 mcb1 ooha otta) use_nl(itp wdd xola iimb3 gic3 mcb3 gic2 mcb2 gic1 mcb1 ooha otta)*/';
       ' SELECT /*+ leading (xoha xola iimb2 gic3 mcb3 gic1 mcb1 gic2 mcb2 ooha otta xrpm wdd itp) use_nl (xoha xola iimb2 gic3 mcb3 gic1 mcb1 gic2 mcb2 ooha otta xrpm wdd itp) push_pred(xsupv) */';
-- 
 -- OMSO_103_5
    lv_select_g1_om103x5_3_hint :=
       --' SELECT /*+ leading(itp gic3 mcb3 gic2 mcb2 gic1 mcb1 wdd ooha otta) use_nl(itp gic3 mcb3 gic2 mcb2 gic1 mcb1 wdd ooha otta)*/';
       ' SELECT /*+ leading (xoha xola wdd itp gic3 mcb3 gic1 mcb1 gic2 mcb2 ooha otta) use_nl (xoha xola wdd itp gic3 mcb3 gic1 mcb1 gic2 mcb2 ooha otta) push_pred(xsupv) */';
-- 
 -- OMSO_103_124
    lv_select_g1_om103x124_3_hint :=
       --' SELECT /*+ leading(itp gic3 mcb3 gic2 mcb2 gic1 mcb1 wdd ooha otta) use_nl(itp gic3 mcb3 gic2 mcb2 gic1 mcb1 wdd ooha otta)*/';
       ' SELECT /*+ leading (xoha xola wdd itp gic3 mcb3 gic1 mcb1 gic2 mcb2 ooha otta) use_nl (xoha xola wdd itp gic3 mcb3 gic1 mcb1 gic2 mcb2 ooha otta) push_pred(xsupv) */';
-- 
 -- OMSO_105
    lv_select_g1_om105_3_hint :=
       --' SELECT /*+ leading(itp wdd xola iimb3 gic3 mcb3 gic2 mcb2 gic1 mcb1 ooha otta xrpm) use_nl(itp wdd xola iimb3 gic3 mcb3 gic2 mcb2 gic1 mcb1 ooha otta xrpm) */';
       ' SELECT /*+ leading (xoha xola iimb2 gic3 mcb3 gic1 mcb1 gic2 mcb2 ooha otta xrpm wdd itp) use_nl (xoha xola iimb2 gic3 mcb3 gic1 mcb1 gic2 mcb2 ooha otta xrpm wdd itp) push_pred(xsupv) */';
-- 
 -- OMSO_108
    lv_select_g1_om108_3_hint :=
       --' SELECT /*+ leading(itp wdd xola iimb3 gic3 mcb3 gic2 mcb2 gic1 mcb1 gic4 mcb4 gic5 mcb5 ooha otta) use_nl(itp wdd xola iimb3 gic3 mcb3 gic2 mcb2 gic1 mcb1 gic4 mcb4 gic5 mcb5 ooha otta) */';
       ' SELECT /*+ leading (xoha xola iimb2 gic3 mcb3 gic1 mcb1 gic2 mcb2 ooha otta xrpm wdd itp) use_nl (xoha xola iimb2 gic3 mcb3 gic1 mcb1 gic2 mcb2 ooha otta xrpm wdd itp) push_pred(xsupv) */';
--
 --===============================================================
 -- GROUP1 PTN04
 --===============================================================
-- 
 -- PORC_102
    lv_select_g1_po102_4_hint :=
       --' SELECT /*+ leading(itp rsl ooha otta xrpm gic2 mcb2 gic1 mcb1) use_nl(itp rsl ooha otta xrpm gic2 mcb2 gic1 mcb1) */'; 
       ' SELECT /*+ leading (xoha xola rsl ooha otta xrpm itp gic1 mcb1 gic2 mcb2) use_nl (xoha xola rsl ooha otta xrpm itp gic1 mcb1 gic2 mcb2) push_pred(xsupv) */'; 
--
 -- PORC_101
    lv_select_g1_po101_4_hint :=
       --' SELECT /*+ leading(itp rsl ooha otta xrpm gic2 mcb2 gic1 mcb1) use_nl(itp rsl ooha otta xrpm gic2 mcb2 gic1 mcb1) */'; 
       ' SELECT /*+ leading (xoha xola rsl ooha otta xrpm itp gic1 mcb1 gic2 mcb2) use_nl (xoha xola rsl ooha otta xrpm itp gic1 mcb1 gic2 mcb2) push_pred(xsupv) */'; 
--
 -- PORC_112
    lv_select_g1_po112_4_hint :=
       --' SELECT /*+ leading(itp rsl ooha otta xrpm xola iimb3 gic2 mcb2 gic1 mcb1) use_nl(itp rsl ooha otta xrpm xola iimb3 gic2 mcb2 gic1 mcb1) */'; 
       --' SELECT /*+ leading (itp rsl ooha otta xrpm xoha xola iimb2 gic2 mcb2 gic1 mcb1) use_nl (itp rsl ooha otta xrpm xoha xola iimb2 gic2 mcb2 gic1 mcb1 ooha otta) */'; 
       ' SELECT /*+ leading (xoha xola iimb2 gic2 mcb2 gic1 mcb1 ooha otta) use_nl (xoha xola iimb2 gic2 mcb2 gic1 mcb1 ooha otta) push_pred(xsupv) */';
--
 -- PORC_103_5
    lv_select_g1_po103x5_4_hint :=
       --' SELECT /*+ leading(itp rsl ooha otta xrpm gic2 mcb2 gic1 mcb1) use_nl(itp rsl ooha otta xrpm gic2 mcb2 gic1 mcb1) */'; 
       ' SELECT /*+ leading (xoha xola rsl ooha otta xrpm itp gic1 mcb1 gic2 mcb2) use_nl (xoha xola rsl ooha otta xrpm itp gic1 mcb1 gic2 mcb2) push_pred(xsupv) */'; 
-- 
 -- PORC_103_124
    lv_select_g1_po103x124_4_hint :=
       --' SELECT /*+ leading(itp rsl ooha otta xrpm gic2 mcb2 gic1 mcb1) use_nl(itp rsl ooha otta xrpm gic2 mcb2 gic1 mcb1) */'; 
       ' SELECT /*+ leading (xoha xola rsl ooha otta xrpm itp gic1 mcb1 gic2 mcb2) use_nl (xoha xola rsl ooha otta xrpm itp gic1 mcb1 gic2 mcb2) push_pred(xsupv) */'; 
-- 
 -- PORC_105
    lv_select_g1_po105_4_hint :=
       --' SELECT /*+ leading(itp rsl ooha otta xrpm xola iimb3 gic2 mcb2 gic1 mcb1) use_nl(itp rsl ooha otta xrpm xola iimb3 gic2 mcb2 gic1 mcb1) */'; 
       --' SELECT /*+ leading (itp rsl ooha otta xrpm xoha xola iimb2 gic2 mcb2 gic1 mcb1) use_nl (itp rsl ooha otta xrpm xoha xola iimb2 gic2 mcb2 gic1 mcb1 ooha otta) */'; 
       ' SELECT /*+ leading (xoha xola iimb2 gic2 mcb2 gic1 mcb1 ooha otta) use_nl (xoha xola iimb2 gic2 mcb2 gic1 mcb1 ooha otta) push_pred(xsupv) */'; 
-- 
 -- PORC_108
    lv_select_g1_po108_4_hint :=
       --' SELECT /*+ leading(itp rsl ooha otta xrpm gic4 mcb4 gic5 mcb5 xola iimb3 gic2 mcb2 gic1 mcb1) use_nl(itp rsl ooha otta xrpm gic4 mcb4 gic5 mcb5 xola iimb3 gic2 mcb2 gic1 mcb1) */'; 
       --' SELECT /*+ leading (itp rsl ooha otta xrpm xoha xola iimb2 gic2 mcb2 gic1 mcb1) use_nl (itp rsl ooha otta xrpm xoha xola iimb2 gic2 mcb2 gic1 mcb1 ooha otta) */'; 
       ' SELECT /*+ leading (xoha xola iimb2 gic2 mcb2 gic1 mcb1 ooha otta) use_nl (xoha xola iimb2 gic2 mcb2 gic1 mcb1 ooha otta) push_pred(xsupv) */'; 
-- 
 -- OMSO_102
    lv_select_g1_om102_4_hint :=
       --' SELECT /*+ leading(xrpm otta ooha wdd itp gic2 mcb2 gic1 mcb1) use_nl(xrpm otta ooha wdd itp gic2 mcb2 gic1 mcb1)*/';
       ' SELECT /*+ leading (xoha xola wdd ooha otta xrpm itp gic1 mcb1 gic2 mcb2) use_nl (xoha xola wdd ooha otta xrpm itp gic1 mcb1 gic2 mcb2) push_pred(xsupv) */';
-- 
 -- OMSO_101
    lv_select_g1_om101_4_hint :=
       --' SELECT /*+ leading(xrpm otta ooha wdd itp gic2 mcb2 gic1 mcb1) use_nl(xrpm otta ooha wdd itp gic2 mcb2 gic1 mcb1)*/';
       ' SELECT /*+ leading (xoha xola wdd ooha otta xrpm itp gic1 mcb1 gic2 mcb2) use_nl (xoha xola wdd ooha otta xrpm itp gic1 mcb1 gic2 mcb2) push_pred(xsupv) */';
-- 
 -- OMSO_112
    lv_select_g1_om112_4_hint :=
       --' SELECT /*+ leading(xrpm otta ooha wdd xola iimb3 gic2 mcb2 gic1 mcb1) use_nl(xrpm otta ooha wdd xola iimb3 gic2 mcb2 gic1 mcb1)*/';
       ' SELECT /*+ leading (xoha xola iimb2 gic1 mcb1 gic2 mcb2 ooha otta xrpm wdd itp) use_nl (xoha xola iimb2 gic1 mcb1 gic2 mcb2 ooha otta xrpm wdd itp) push_pred(xsupv) */';
-- 
 -- OMSO_103_5
    lv_select_g1_om103x5_4_hint :=
       --' SELECT /*+ leading(xrpm otta ooha wdd itp gic2 mcb2 gic1 mcb1) use_nl(xrpm otta ooha wdd itp gic2 mcb2 gic1 mcb1)*/';
       ' SELECT /*+ leading (xoha xola wdd ooha otta xrpm itp gic1 mcb1 gic2 mcb2) use_nl (xoha xola wdd ooha otta xrpm itp gic1 mcb1 gic2 mcb2) push_pred(xsupv) */';
-- 
 -- OMSO_103_124
    lv_select_g1_om103x124_4_hint :=
       --' SELECT /*+ leading(xrpm otta ooha wdd itp gic2 mcb2 gic1 mcb1) use_nl(xrpm otta ooha wdd itp gic2 mcb2 gic1 mcb1)*/';
       ' SELECT /*+ leading (xoha xola wdd ooha otta xrpm itp gic1 mcb1 gic2 mcb2) use_nl (xoha xola wdd ooha otta xrpm itp gic1 mcb1 gic2 mcb2) push_pred(xsupv) */';
-- 
 -- OMSO_105
    lv_select_g1_om105_4_hint :=
       --' SELECT /*+ leading(xrpm otta ooha wdd xola iimb3 gic2 mcb2 gic1 mcb1) use_nl(xrpm otta ooha wdd xola iimb3 gic2 mcb2 gic1 mcb1)*/';
       ' SELECT /*+ leading (xoha xola iimb2 gic1 mcb1 gic2 mcb2 ooha otta xrpm wdd itp) use_nl (xoha xola iimb2 gic1 mcb1 gic2 mcb2 ooha otta xrpm wdd itp) push_pred(xsupv) */';
-- 
 -- OMSO_108
    lv_select_g1_om108_4_hint :=
       --' SELECT /*+ leading(xrpm otta ooha wdd xola iimb3 gic2 mcb2 gic1 mcb1) use_nl(xrpm otta ooha wdd xola iimb3 gic2 mcb2 gic1 mcb1)*/';
       ' SELECT /*+ leading (xoha xola iimb2 gic1 mcb1 gic2 mcb2 ooha otta xrpm wdd itp) use_nl (xoha xola iimb2 gic1 mcb1 gic2 mcb2 ooha otta xrpm wdd itp) push_pred(xsupv) */';
--
 --===============================================================
 -- GROUP1 PTN05
 --===============================================================
 -- GROUP1 PTN03と同様
--
 --===============================================================
 -- GROUP1 PTN06
 --===============================================================
-- 
 -- PORC_102
    lv_select_g1_po102_6_hint :=
       --' SELECT /*+ leading(itp rsl ooha otta xrpm gic3 mcb3 gic2 mcb2 gic1 mcb1) use_nl(itp rsl ooha otta xrpm gic3 mcb3 gic2 mcb2 gic1 mcb1) */'; 
       ' SELECT /*+ leading (xoha xola rsl ooha otta xrpm itp gic3 mcb3 gic1 mcb1 gic2 mcb2) use_nl (xoha xola rsl ooha otta xrpm itp gic3 mcb3 gic1 mcb1 gic2 mcb2) push_pred(xsupv) */'; 
--
 -- PORC_101
    lv_select_g1_po101_6_hint :=
       --' SELECT /*+ leading(itp rsl ooha otta xrpm gic3 mcb3 gic2 mcb2 gic1 mcb1) use_nl(itp rsl ooha otta xrpm gic3 mcb3 gic2 mcb2 gic1 mcb1) */'; 
       ' SELECT /*+ leading (xoha xola rsl ooha otta xrpm itp gic3 mcb3 gic1 mcb1 gic2 mcb2) use_nl (xoha xola rsl ooha otta xrpm itp gic3 mcb3 gic1 mcb1 gic2 mcb2) push_pred(xsupv) */'; 
--
 -- PORC_112
    lv_select_g1_po112_6_hint :=
       --' SELECT /*+ leading(itp rsl ooha otta xrpm xola iimb3 gic3 mcb3 gic2 mcb2 gic1 mcb1) use_nl(itp rsl ooha otta xrpm xola iimb3 gic3 mcb3 gic2 mcb2 gic1 mcb1) */'; 
       --' SELECT /*+ leading (itp rsl ooha otta xrpm xoha xola iimb2 gic3 mcb3 gic2 mcb2 gic1 mcb1) use_nl (itp rsl ooha otta xrpm xoha xola iimb2 gic3 mcb3 gic2 mcb2 gic1 mcb1 ooha otta) */'; 
       ' SELECT /*+ leading (xoha xola iimb2 gic3 mcb3 gic2 mcb2 gic1 mcb1 ooha otta) use_nl (xoha xola iimb2 gic3 mcb3 gic2 mcb2 gic1 mcb1 ooha otta) push_pred(xsupv) */';
--
 -- PORC_103_5
    lv_select_g1_po103x5_6_hint :=
       --' SELECT /*+ leading(itp rsl ooha otta xrpm gic3 mcb3 gic2 mcb2 gic1 mcb1) use_nl(itp rsl ooha otta xrpm gic3 mcb3 gic2 mcb2 gic1 mcb1) */'; 
       ' SELECT /*+ leading (xoha xola rsl ooha otta xrpm itp gic3 mcb3 gic1 mcb1 gic2 mcb2) use_nl (xoha xola rsl ooha otta xrpm itp gic3 mcb3 gic1 mcb1 gic2 mcb2) push_pred(xsupv) */'; 
-- 
 -- PORC_103_124
    lv_select_g1_po103x124_6_hint :=
       --' SELECT /*+ leading(itp rsl ooha otta xrpm gic3 mcb3 gic2 mcb2 gic1 mcb1) use_nl(itp rsl ooha otta xrpm gic3 mcb3 gic2 mcb2 gic1 mcb1) */'; 
       ' SELECT /*+ leading (xoha xola rsl ooha otta xrpm itp gic3 mcb3 gic1 mcb1 gic2 mcb2) use_nl (xoha xola rsl ooha otta xrpm itp gic3 mcb3 gic1 mcb1 gic2 mcb2) push_pred(xsupv) */'; 
-- 
 -- PORC_105
    lv_select_g1_po105_6_hint :=
       --' SELECT /*+ leading(itp rsl ooha otta xrpm xola iimb3 gic3 mcb3 gic2 mcb2 gic1 mcb1) use_nl(itp rsl ooha otta xrpm xola iimb3 gic3 mcb3 gic2 mcb2 gic1 mcb1) */'; 
       --' SELECT /*+ leading (itp rsl ooha otta xrpm xoha xola iimb2 gic3 mcb3 gic2 mcb2 gic1 mcb1) use_nl (itp rsl ooha otta xrpm xoha xola iimb2 gic3 mcb3 gic2 mcb2 gic1 mcb1 ooha otta) */';
       ' SELECT /*+ leading (xoha xola iimb2 gic3 mcb3 gic2 mcb2 gic1 mcb1 ooha otta) use_nl (xoha xola iimb2 gic3 mcb3 gic2 mcb2 gic1 mcb1 ooha otta) push_pred(xsupv) */'; 
-- 
 -- PORC_108
    lv_select_g1_po108_6_hint :=
       --' SELECT /*+ leading(itp rsl ooha otta xrpm xola iimb3 gic3 mcb3 gic2 mcb2 gic1 mcb1) use_nl(itp rsl ooha otta xrpm xola iimb3 gic3 mcb3 gic2 mcb2 gic1 mcb1) */'; 
       --' SELECT /*+ leading (itp rsl ooha otta xrpm xoha xola iimb2 gic3 mcb3 gic2 mcb2 gic1 mcb1) use_nl (itp rsl ooha otta xrpm xoha xola iimb2 gic3 mcb3 gic2 mcb2 gic1 mcb1 ooha otta) */';
       ' SELECT /*+ leading (xoha xola iimb2 gic3 mcb3 gic2 mcb2 gic1 mcb1 ooha otta) use_nl (xoha xola iimb2 gic3 mcb3 gic2 mcb2 gic1 mcb1 ooha otta) push_pred(xsupv) */'; 
-- 
 -- OMSO_102
    lv_select_g1_om102_6_hint :=
       --' SELECT /*+ leading(xrpm otta ooha wdd itp gic3 mcb3 gic2 mcb2 gic1 mcb1) use_nl(xrpm otta ooha wdd itp gic3 mcb3 gic2 mcb2 gic1 mcb1)*/';
       ' SELECT /*+ leading (xoha xola wdd ooha otta xrpm itp gic3 mcb3 gic1 mcb1 gic2 mcb2) use_nl (xoha xola wdd ooha otta xrpm itp gic3 mcb3 gic1 mcb1 gic2 mcb2) push_pred(xsupv) */';
-- 
 -- OMSO_101
    lv_select_g1_om101_6_hint :=
       --' SELECT /*+ leading(xrpm otta ooha wdd itp gic3 mcb3 gic2 mcb2 gic1 mcb1) use_nl(xrpm otta ooha wdd itp gic3 mcb3 gic2 mcb2 gic1 mcb1)*/';
       ' SELECT /*+ leading (xoha xola wdd ooha otta xrpm itp gic3 mcb3 gic1 mcb1 gic2 mcb2) use_nl (xoha xola wdd ooha otta xrpm itp gic3 mcb3 gic1 mcb1 gic2 mcb2) push_pred(xsupv) */';
-- 
 -- OMSO_112
    lv_select_g1_om112_6_hint :=
       --' SELECT /*+ leading(xrpm otta ooha wdd xola iimb3 gic3 mcb3 gic2 mcb2 gic1 mcb1) use_nl(xrpm otta ooha wdd xola iimb3 gic3 mcb3 gic2 mcb2 gic1 mcb1)*/';
       ' SELECT /*+ leading (xoha xola iimb2 gic3 mcb3 gic1 mcb1 gic2 mcb2 ooha otta xrpm wdd itp) use_nl (xoha xola iimb2 gic3 mcb3 gic1 mcb1 gic2 mcb2 ooha otta xrpm wdd itp) push_pred(xsupv) */';
-- 
 -- OMSO_103_5
    lv_select_g1_om103x5_6_hint :=
       --' SELECT /*+ leading(xrpm otta ooha wdd itp gic3 mcb3 gic2 mcb2 gic1 mcb1) use_nl(xrpm otta ooha wdd itp gic3 mcb3 gic2 mcb2 gic1 mcb1)*/';
       ' SELECT /*+ leading (xoha xola wdd ooha otta xrpm itp gic3 mcb3 gic1 mcb1 gic2 mcb2) use_nl (xoha xola wdd ooha otta xrpm itp gic3 mcb3 gic1 mcb1 gic2 mcb2) push_pred(xsupv) */';
-- 
 -- OMSO_103_124
    lv_select_g1_om103x124_6_hint :=
       --' SELECT /*+ leading(xrpm otta ooha wdd itp gic3 mcb3 gic2 mcb2 gic1 mcb1) use_nl(xrpm otta ooha wdd itp gic3 mcb3 gic2 mcb2 gic1 mcb1)*/';
       ' SELECT /*+ leading (xoha xola wdd ooha otta xrpm itp gic3 mcb3 gic1 mcb1 gic2 mcb2) use_nl (xoha xola wdd ooha otta xrpm itp gic3 mcb3 gic1 mcb1 gic2 mcb2) push_pred(xsupv) */';
-- 
 -- OMSO_105
    lv_select_g1_om105_6_hint :=
       --' SELECT /*+ leading(xrpm otta ooha wdd xola iimb3 gic3 mcb3 gic2 mcb2 gic1 mcb1) use_nl(xrpm otta ooha wdd xola iimb3 gic3 mcb3 gic2 mcb2 gic1 mcb1)*/';
       ' SELECT /*+ leading (xoha xola iimb2 gic3 mcb3 gic1 mcb1 gic2 mcb2 ooha otta xrpm wdd itp) use_nl (xoha xola iimb2 gic3 mcb3 gic1 mcb1 gic2 mcb2 ooha otta xrpm wdd itp) push_pred(xsupv) */';
-- 
 -- OMSO_108
    lv_select_g1_om108_6_hint :=
       --' SELECT /*+ leading(xrpm otta ooha wdd xola iimb3 gic3 mcb3 gic2 mcb2 gic1 mcb1) use_nl(xrpm otta ooha wdd xola iimb3 gic3 mcb3 gic2 mcb2 gic1 mcb1)*/';
       ' SELECT /*+ leading (xoha xola iimb2 gic3 mcb3 gic1 mcb1 gic2 mcb2 ooha otta xrpm wdd itp) use_nl (xoha xola iimb2 gic3 mcb3 gic1 mcb1 gic2 mcb2 ooha otta xrpm wdd itp) push_pred(xsupv) */';
--
 --===============================================================
--
 -- GROUP1 PTN07
 --===============================================================
 -- GROUP1 PTN04と同様
-- 
 --===============================================================
--
 -- GROUP1 PTN08
 --===============================================================
 -- GROUP1 PTN06と同様
-- 
-- 2008/10/24 v1.10 ADD START
--
    -- 入力パラメーターの設定
    -- 「受払区分」を抽出条件に設定
    IF  ( ir_param.rcv_pay_div IS NOT NULL ) THEN
      lv_where := lv_where
        || ' AND xrpm.new_div_account = ''' || ir_param.rcv_pay_div || ''''
        ;
    END IF;
--
    -- 「倉庫コード」が個別選択されている場合(*ALLを除く)、抽出条件に設定
    IF  ( ir_param.whse_code IS NOT NULL )
    AND ( ir_param.whse_code != gc_param_all_code )
    THEN
      lv_where := lv_where
        || ' AND itp.whse_code = '''        || ir_param.whse_code || ''''
        ;
    END IF;
--
    -- 「成績部署」が個別選択されている場合(*ALLを除く)、抽出条件に設定
    IF  ( ir_param.result_post IS NOT NULL )
    AND ( ir_param.result_post != gc_param_all_code )
    THEN
      lv_where := lv_where
--        || ' AND xrpm.result_post = '''     || ir_param.result_post || ''''
        || ' AND ooha.attribute11 = '''     || ir_param.result_post || ''''
        ;
    END IF;
--
    -- 「郡種別」が「3:郡コード」で、かつ、「郡コード」が入力されている場合、抽出条件に設定
    IF    ( ir_param.crowd_type = gc_crowd_type_3 ) THEN
      lv_where := lv_where
        || ' AND gic3.category_set_id = '''      || cn_crowd_code_id || ''''
        ;
--
      IF ( ir_param.crowd_code IS NOT NULL ) THEN
        lv_where := lv_where
          || ' AND mcb3.segment1 = '''      || ir_param.crowd_code || ''''
          ;
      END IF;
    -- 「郡種別」が「4:経理郡コード」で、かつ、「経理郡コード」が入力されている場合、抽出条件に設定
    ELSIF ( ir_param.crowd_type =  gc_crowd_type_4 ) THEN
      lv_where := lv_where
        || ' AND gic3.category_set_id = ''' || cn_acnt_crowd_id || ''''
        ;
      IF ( ir_param.acnt_crowd_code IS NOT NULL ) THEN
        lv_where := lv_where
          || ' AND mcb3.segment1 = ''' || ir_param.acnt_crowd_code || ''''
          ;
      END IF;
    END IF;
--
    -- 「品目区分」が個別選択されている場合、抽出条件に設定
    IF  ( ir_param.item_div IS NOT NULL ) THEN
      lv_where := lv_where
--        || ' AND mcb2.item_div = '''        || ir_param.item_div || ''''
        || ' AND mcb2.segment1 = '''        || ir_param.item_div || ''''
        ;
    END IF;
--
    -- 「出荷先コード」が個別選択されている場合(*ALLを除く)、抽出条件に設定
    IF  ( ir_param.party_code IS NOT NULL )
    AND ( ir_param.party_code != gc_param_all_code )
    THEN
-- 2008/12/13 v1.17 N.yoshida mod start
      lv_where2 := lv_where
        || ' AND xoha.customer_code = '''    || ir_param.party_code || ''''
               ;
      lv_where3 := lv_where
        || ' AND xoha.vendor_code   = '''    || ir_param.party_code || ''''
               ;
    ELSE
      lv_where2 := lv_where;
      lv_where3 := lv_where;
-- 2008/12/13 v1.17 N.yoshida mod end
    END IF;
--
    -- 集計パターン１設定 (集計：1.成績部署、2.品目区分、3.倉庫、4.出荷先)
    IF  ( ir_param.result_post IS NULL )
    AND ( ir_param.whse_code   IS NULL )
    AND ( ir_param.party_code  IS NULL )
    THEN
--
      --GROUP1
      --PTN01
      --品目区分          =  NULL
      --群(経理群)コード  =  NULL
      --受払区分          =  NULL
      IF  (  ir_param.item_div    IS NULL ) 
      AND (((ir_param.crowd_type = gc_crowd_type_3) AND ( ir_param.crowd_code       IS NULL )) OR
          (( ir_param.crowd_type = gc_crowd_type_4) AND ( ir_param.acnt_crowd_code  IS NULL )))
      AND (  ir_param.rcv_pay_div IS NULL )
      THEN
        -- オープン
        OPEN  get_cur01 FOR lv_select_main_start
                         || lv_select_g1_po102_1_hint
                         || lv_select_common
                         || lv_select_group1
                         || lv_select_1_po102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po101_1_hint
                         || lv_select_common
                         || lv_select_group1
                         || lv_select_1_po101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po112_1_hint
                         || lv_select_common
                         || lv_select_group1
                         || lv_select_1_po112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po103x5_1_hint
                         || lv_select_common
                         || lv_select_group1_2
                         || lv_select_1_po103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po103x124_1_hint
                         || lv_select_common
                         || lv_select_group1_2
                         || lv_select_1_po103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po105_1_hint
                         || lv_select_common
                         || lv_select_group1_2
                         || lv_select_1_po105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po108_1_hint
                         || lv_select_common
                         || lv_select_group1_2
                         || lv_select_1_po108
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om102_1_hint
                         || lv_select_common
                         || lv_select_group1
                         || lv_select_1_om102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om101_1_hint
                         || lv_select_common
                         || lv_select_group1
                         || lv_select_1_om101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om112_1_hint
                         || lv_select_common
                         || lv_select_group1
                         || lv_select_1_om112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om103x5_1_hint
                         || lv_select_common
                         || lv_select_group1_2
                         || lv_select_1_om103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om103x124_1_hint
                         || lv_select_common
                         || lv_select_group1_2
                         || lv_select_1_om103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om105_1_hint
                         || lv_select_common
                         || lv_select_group1_2
                         || lv_select_1_om105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om108_1_hint
                         || lv_select_common
                         || lv_select_group1_2
                         || lv_select_1_om108
                         || lv_where3
                         || lv_select_main_end
                         ;
        -- バルクフェッチ
        FETCH get_cur01 BULK COLLECT INTO ot_data_rec ;
        -- カーソルクローズ
        CLOSE get_cur01 ;
--
      --GROUP1
      --PTN02
      --品目区分          <> NULL
      --群(経理群)コード  =  NULL
      --受払区分          =  NULL
      ELSIF (ir_param.item_div    IS NOT NULL ) 
      AND (((ir_param.crowd_type = gc_crowd_type_3) AND ( ir_param.crowd_code       IS NULL )) OR
          (( ir_param.crowd_type = gc_crowd_type_4) AND ( ir_param.acnt_crowd_code  IS NULL )))
      AND (  ir_param.rcv_pay_div IS NULL )
      THEN
        -- オープン
        OPEN  get_cur01 FOR lv_select_main_start
                         || lv_select_g1_po102_2_hint
                         || lv_select_common
                         || lv_select_group1
                         || lv_select_1_po102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po101_2_hint
                         || lv_select_common
                         || lv_select_group1
                         || lv_select_1_po101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po112_2_hint
                         || lv_select_common
                         || lv_select_group1
                         || lv_select_1_po112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po103x5_2_hint
                         || lv_select_common
                         || lv_select_group1_2
                         || lv_select_1_po103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po103x124_2_hint
                         || lv_select_common
                         || lv_select_group1_2
                         || lv_select_1_po103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po105_2_hint
                         || lv_select_common
                         || lv_select_group1_2
                         || lv_select_1_po105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po108_2_hint
                         || lv_select_common
                         || lv_select_group1_2
                         || lv_select_1_po108
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om102_2_hint
                         || lv_select_common
                         || lv_select_group1
                         || lv_select_1_om102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om101_2_hint
                         || lv_select_common
                         || lv_select_group1
                         || lv_select_1_om101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om112_2_hint
                         || lv_select_common
                         || lv_select_group1
                         || lv_select_1_om112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om103x5_2_hint
                         || lv_select_common
                         || lv_select_group1_2
                         || lv_select_1_om103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om103x124_2_hint
                         || lv_select_common
                         || lv_select_group1_2
                         || lv_select_1_om103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om105_2_hint
                         || lv_select_common
                         || lv_select_group1_2
                         || lv_select_1_om105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om108_2_hint
                         || lv_select_common
                         || lv_select_group1_2
                         || lv_select_1_om108
                         || lv_where3
                         || lv_select_main_end
                         ;
        -- バルクフェッチ
        FETCH get_cur01 BULK COLLECT INTO ot_data_rec ;
        -- カーソルクローズ
        CLOSE get_cur01 ;
--
      --GROUP1
      --PTN03
      --品目区分          =  NULL
      --群(経理群)コード  <> NULL
      --受払区分          =  NULL
      ELSIF (ir_param.item_div    IS NULL ) 
      AND (((ir_param.crowd_type = gc_crowd_type_3) AND ( ir_param.crowd_code       IS NOT NULL )) OR
          (( ir_param.crowd_type = gc_crowd_type_4) AND ( ir_param.acnt_crowd_code  IS NOT NULL )))
      AND (  ir_param.rcv_pay_div IS NULL )
      THEN
        -- オープン
        OPEN  get_cur01 FOR lv_select_main_start
                         || lv_select_g1_po102_3_hint
                         || lv_select_common
                         || lv_select_group1
                         || lv_select_1_po102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po101_3_hint
                         || lv_select_common
                         || lv_select_group1
                         || lv_select_1_po101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po112_3_hint
                         || lv_select_common
                         || lv_select_group1
                         || lv_select_1_po112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po103x5_3_hint
                         || lv_select_common
                         || lv_select_group1_2
                         || lv_select_1_po103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po103x124_3_hint
                         || lv_select_common
                         || lv_select_group1_2
                         || lv_select_1_po103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po105_3_hint
                         || lv_select_common
                         || lv_select_group1_2
                         || lv_select_1_po105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po108_3_hint
                         || lv_select_common
                         || lv_select_group1_2
                         || lv_select_1_po108
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om102_3_hint
                         || lv_select_common
                         || lv_select_group1
                         || lv_select_1_om102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om101_3_hint
                         || lv_select_common
                         || lv_select_group1
                         || lv_select_1_om101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om112_3_hint
                         || lv_select_common
                         || lv_select_group1
                         || lv_select_1_om112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om103x5_3_hint
                         || lv_select_common
                         || lv_select_group1_2
                         || lv_select_1_om103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om103x124_3_hint
                         || lv_select_common
                         || lv_select_group1_2
                         || lv_select_1_om103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om105_3_hint
                         || lv_select_common
                         || lv_select_group1_2
                         || lv_select_1_om105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om108_3_hint
                         || lv_select_common
                         || lv_select_group1_2
                         || lv_select_1_om108
                         || lv_where3
                         || lv_select_main_end
                         ;
        -- バルクフェッチ
        FETCH get_cur01 BULK COLLECT INTO ot_data_rec ;
        -- カーソルクローズ
        CLOSE get_cur01 ;
--
      --GROUP1
      --PTN04
      --品目区分          =  NULL
      --群(経理群)コード  =  NULL
      --受払区分          <> NULL
      ELSIF (ir_param.item_div    IS NULL ) 
      AND (((ir_param.crowd_type = gc_crowd_type_3) AND ( ir_param.crowd_code       IS NULL )) OR
          (( ir_param.crowd_type = gc_crowd_type_4) AND ( ir_param.acnt_crowd_code  IS NULL )))
      AND (  ir_param.rcv_pay_div IS NOT NULL )
      THEN
        -- オープン
        OPEN  get_cur01 FOR lv_select_main_start
                         || lv_select_g1_po102_4_hint
                         || lv_select_common
                         || lv_select_group1
                         || lv_select_1_po102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po101_4_hint
                         || lv_select_common
                         || lv_select_group1
                         || lv_select_1_po101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po112_4_hint
                         || lv_select_common
                         || lv_select_group1
                         || lv_select_1_po112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po103x5_4_hint
                         || lv_select_common
                         || lv_select_group1_2
                         || lv_select_1_po103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po103x124_4_hint
                         || lv_select_common
                         || lv_select_group1_2
                         || lv_select_1_po103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po105_4_hint
                         || lv_select_common
                         || lv_select_group1_2
                         || lv_select_1_po105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po108_4_hint
                         || lv_select_common
                         || lv_select_group1_2
                         || lv_select_1_po108
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om102_4_hint
                         || lv_select_common
                         || lv_select_group1
                         || lv_select_1_om102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om101_4_hint
                         || lv_select_common
                         || lv_select_group1
                         || lv_select_1_om101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om112_4_hint
                         || lv_select_common
                         || lv_select_group1
                         || lv_select_1_om112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om103x5_4_hint
                         || lv_select_common
                         || lv_select_group1_2
                         || lv_select_1_om103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om103x124_4_hint
                         || lv_select_common
                         || lv_select_group1_2
                         || lv_select_1_om103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om105_4_hint
                         || lv_select_common
                         || lv_select_group1_2
                         || lv_select_1_om105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om108_4_hint
                         || lv_select_common
                         || lv_select_group1_2
                         || lv_select_1_om108
                         || lv_where3
                         || lv_select_main_end
                         ;
        -- バルクフェッチ
        FETCH get_cur01 BULK COLLECT INTO ot_data_rec ;
        -- カーソルクローズ
        CLOSE get_cur01 ;
--
      --GROUP1
      --PTN05
      --品目区分          <> NULL
      --群(経理群)コード  <> NULL
      --受払区分          =  NULL
      ELSIF (ir_param.item_div    IS NOT NULL ) 
      AND (((ir_param.crowd_type = gc_crowd_type_3) AND ( ir_param.crowd_code       IS NOT NULL )) OR
          (( ir_param.crowd_type = gc_crowd_type_4) AND ( ir_param.acnt_crowd_code  IS NOT NULL )))
      AND (  ir_param.rcv_pay_div IS NULL )
      THEN
        -- オープン
        OPEN  get_cur01 FOR lv_select_main_start
                         || lv_select_g1_po102_3_hint
                         || lv_select_common
                         || lv_select_group1
                         || lv_select_1_po102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po101_3_hint
                         || lv_select_common
                         || lv_select_group1
                         || lv_select_1_po101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po112_3_hint
                         || lv_select_common
                         || lv_select_group1
                         || lv_select_1_po112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po103x5_3_hint
                         || lv_select_common
                         || lv_select_group1_2
                         || lv_select_1_po103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po103x124_3_hint
                         || lv_select_common
                         || lv_select_group1_2
                         || lv_select_1_po103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po105_3_hint
                         || lv_select_common
                         || lv_select_group1_2
                         || lv_select_1_po105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po108_3_hint
                         || lv_select_common
                         || lv_select_group1_2
                         || lv_select_1_po108
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om102_3_hint
                         || lv_select_common
                         || lv_select_group1
                         || lv_select_1_om102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om101_3_hint
                         || lv_select_common
                         || lv_select_group1
                         || lv_select_1_om101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om112_3_hint
                         || lv_select_common
                         || lv_select_group1
                         || lv_select_1_om112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om103x5_3_hint
                         || lv_select_common
                         || lv_select_group1_2
                         || lv_select_1_om103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om103x124_3_hint
                         || lv_select_common
                         || lv_select_group1_2
                         || lv_select_1_om103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om105_3_hint
                         || lv_select_common
                         || lv_select_group1_2
                         || lv_select_1_om105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om108_3_hint
                         || lv_select_common
                         || lv_select_group1_2
                         || lv_select_1_om108
                         || lv_where3
                         || lv_select_main_end
                         ;
        -- バルクフェッチ
        FETCH get_cur01 BULK COLLECT INTO ot_data_rec ;
        -- カーソルクローズ
        CLOSE get_cur01 ;
--
      --GROUP1
      --PTN06
      --品目区分          =  NULL
      --群(経理群)コード  <> NULL
      --受払区分          <> NULL
      ELSIF (ir_param.item_div    IS NULL ) 
      AND (((ir_param.crowd_type = gc_crowd_type_3) AND ( ir_param.crowd_code       IS NOT NULL )) OR
          (( ir_param.crowd_type = gc_crowd_type_4) AND ( ir_param.acnt_crowd_code  IS NOT NULL )))
      AND (  ir_param.rcv_pay_div IS NOT NULL )
      THEN
        -- オープン
        OPEN  get_cur01 FOR lv_select_main_start
                         || lv_select_g1_po102_6_hint
                         || lv_select_common
                         || lv_select_group1
                         || lv_select_1_po102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po101_6_hint
                         || lv_select_common
                         || lv_select_group1
                         || lv_select_1_po101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po112_6_hint
                         || lv_select_common
                         || lv_select_group1
                         || lv_select_1_po112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po103x5_6_hint
                         || lv_select_common
                         || lv_select_group1_2
                         || lv_select_1_po103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po103x124_6_hint
                         || lv_select_common
                         || lv_select_group1_2
                         || lv_select_1_po103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po105_6_hint
                         || lv_select_common
                         || lv_select_group1_2
                         || lv_select_1_po105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po108_6_hint
                         || lv_select_common
                         || lv_select_group1_2
                         || lv_select_1_po108
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om102_6_hint
                         || lv_select_common
                         || lv_select_group1
                         || lv_select_1_om102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om101_6_hint
                         || lv_select_common
                         || lv_select_group1
                         || lv_select_1_om101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om112_6_hint
                         || lv_select_common
                         || lv_select_group1
                         || lv_select_1_om112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om103x5_6_hint
                         || lv_select_common
                         || lv_select_group1_2
                         || lv_select_1_om103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om103x124_6_hint
                         || lv_select_common
                         || lv_select_group1_2
                         || lv_select_1_om103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om105_6_hint
                         || lv_select_common
                         || lv_select_group1_2
                         || lv_select_1_om105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om108_6_hint
                         || lv_select_common
                         || lv_select_group1_2
                         || lv_select_1_om108
                         || lv_where3
                         || lv_select_main_end
                         ;
        -- バルクフェッチ
        FETCH get_cur01 BULK COLLECT INTO ot_data_rec ;
        -- カーソルクローズ
        CLOSE get_cur01 ;
--
      --GROUP1
      --PTN07
      --品目区分          <> NULL
      --群(経理群)コード  =  NULL
      --受払区分          <> NULL
      ELSIF (ir_param.item_div    IS NOT NULL ) 
      AND (((ir_param.crowd_type = gc_crowd_type_3) AND ( ir_param.crowd_code       IS NULL )) OR
          (( ir_param.crowd_type = gc_crowd_type_4) AND ( ir_param.acnt_crowd_code  IS NULL )))
      AND (  ir_param.rcv_pay_div IS NOT NULL )
      THEN
        -- オープン
        OPEN  get_cur01 FOR lv_select_main_start
                         || lv_select_g1_po102_4_hint
                         || lv_select_common
                         || lv_select_group1
                         || lv_select_1_po102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po101_4_hint
                         || lv_select_common
                         || lv_select_group1
                         || lv_select_1_po101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po112_4_hint
                         || lv_select_common
                         || lv_select_group1
                         || lv_select_1_po112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po103x5_4_hint
                         || lv_select_common
                         || lv_select_group1_2
                         || lv_select_1_po103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po103x124_4_hint
                         || lv_select_common
                         || lv_select_group1_2
                         || lv_select_1_po103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po105_4_hint
                         || lv_select_common
                         || lv_select_group1_2
                         || lv_select_1_po105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po108_4_hint
                         || lv_select_common
                         || lv_select_group1_2
                         || lv_select_1_po108
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om102_4_hint
                         || lv_select_common
                         || lv_select_group1
                         || lv_select_1_om102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om101_4_hint
                         || lv_select_common
                         || lv_select_group1
                         || lv_select_1_om101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om112_4_hint
                         || lv_select_common
                         || lv_select_group1
                         || lv_select_1_om112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om103x5_4_hint
                         || lv_select_common
                         || lv_select_group1_2
                         || lv_select_1_om103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om103x124_4_hint
                         || lv_select_common
                         || lv_select_group1_2
                         || lv_select_1_om103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om105_4_hint
                         || lv_select_common
                         || lv_select_group1_2
                         || lv_select_1_om105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om108_4_hint
                         || lv_select_common
                         || lv_select_group1_2
                         || lv_select_1_om108
                         || lv_where3
                         || lv_select_main_end
                         ;
        -- バルクフェッチ
        FETCH get_cur01 BULK COLLECT INTO ot_data_rec ;
        -- カーソルクローズ
        CLOSE get_cur01 ;
--
      --GROUP1
      --PTN08
      --品目区分          <> NULL
      --群(経理群)コード  <> NULL
      --受払区分          <> NULL
      ELSE
        -- オープン
        OPEN  get_cur01 FOR lv_select_main_start
                         || lv_select_g1_po102_6_hint
                         || lv_select_common
                         || lv_select_group1
                         || lv_select_1_po102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po101_6_hint
                         || lv_select_common
                         || lv_select_group1
                         || lv_select_1_po101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po112_6_hint
                         || lv_select_common
                         || lv_select_group1
                         || lv_select_1_po112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po103x5_6_hint
                         || lv_select_common
                         || lv_select_group1_2
                         || lv_select_1_po103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po103x124_6_hint
                         || lv_select_common
                         || lv_select_group1_2
                         || lv_select_1_po103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po105_6_hint
                         || lv_select_common
                         || lv_select_group1_2
                         || lv_select_1_po105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po108_6_hint
                         || lv_select_common
                         || lv_select_group1_2
                         || lv_select_1_po108
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om102_6_hint
                         || lv_select_common
                         || lv_select_group1
                         || lv_select_1_om102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om101_6_hint
                         || lv_select_common
                         || lv_select_group1
                         || lv_select_1_om101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om112_6_hint
                         || lv_select_common
                         || lv_select_group1
                         || lv_select_1_om112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om103x5_6_hint
                         || lv_select_common
                         || lv_select_group1_2
                         || lv_select_1_om103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om103x124_6_hint
                         || lv_select_common
                         || lv_select_group1_2
                         || lv_select_1_om103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om105_6_hint
                         || lv_select_common
                         || lv_select_group1_2
                         || lv_select_1_om105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om108_6_hint
                         || lv_select_common
                         || lv_select_group1_2
                         || lv_select_1_om108
                         || lv_where3
                         || lv_select_main_end
                         ;
        -- バルクフェッチ
        FETCH get_cur01 BULK COLLECT INTO ot_data_rec ;
        -- カーソルクローズ
        CLOSE get_cur01 ;
      END IF;
--
    -- 集計パターン２設定 (集計：1.成績部署、2.品目区分、3.倉庫)
    ELSIF ( ir_param.result_post IS NULL )
    AND   ( ir_param.whse_code   IS NULL )
    AND   ( ir_param.party_code  IS NOT NULL )
    THEN
--
      --GROUP2
      --PTN01
      --品目区分          =  NULL
      --群(経理群)コード  =  NULL
      --受払区分          =  NULL
      IF  (  ir_param.item_div    IS NULL ) 
      AND (((ir_param.crowd_type = gc_crowd_type_3) AND ( ir_param.crowd_code       IS NULL )) OR
          (( ir_param.crowd_type = gc_crowd_type_4) AND ( ir_param.acnt_crowd_code  IS NULL )))
      AND (  ir_param.rcv_pay_div IS NULL )
      THEN
        -- オープン
        OPEN  get_cur01 FOR lv_select_main_start
                         || lv_select_g1_po102_1_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_po102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po101_1_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_po101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po112_1_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_po112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po103x5_1_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_po103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po103x124_1_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_po103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po105_1_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_po105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po108_1_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_po108
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om102_1_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_om102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om101_1_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_om101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om112_1_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_om112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om103x5_1_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_om103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om103x124_1_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_om103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om105_1_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_om105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om108_1_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_om108
                         || lv_where3
                         || lv_select_main_end
                         ;
        -- バルクフェッチ
        FETCH get_cur01 BULK COLLECT INTO ot_data_rec ;
        -- カーソルクローズ
        CLOSE get_cur01 ;
--
      --GROUP2
      --PTN02
      --品目区分          <> NULL
      --群(経理群)コード  =  NULL
      --受払区分          =  NULL
      ELSIF (ir_param.item_div    IS NOT NULL ) 
      AND (((ir_param.crowd_type = gc_crowd_type_3) AND ( ir_param.crowd_code       IS NULL )) OR
          (( ir_param.crowd_type = gc_crowd_type_4) AND ( ir_param.acnt_crowd_code  IS NULL )))
      AND (  ir_param.rcv_pay_div IS NULL )
      THEN
        -- オープン
        OPEN  get_cur01 FOR lv_select_main_start
                         || lv_select_g1_po102_2_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_po102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po101_2_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_po101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po112_2_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_po112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po103x5_2_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_po103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po103x124_2_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_po103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po105_2_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_po105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po108_2_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_po108
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om102_2_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_om102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om101_2_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_om101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om112_2_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_om112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om103x5_2_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_om103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om103x124_2_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_om103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om105_2_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_om105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om108_2_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_om108
                         || lv_where3
                         || lv_select_main_end
                         ;
        -- バルクフェッチ
        FETCH get_cur01 BULK COLLECT INTO ot_data_rec ;
        -- カーソルクローズ
        CLOSE get_cur01 ;
--
      --GROUP2
      --PTN03
      --品目区分          =  NULL
      --群(経理群)コード  <> NULL
      --受払区分          =  NULL
      ELSIF (ir_param.item_div    IS NULL ) 
      AND (((ir_param.crowd_type = gc_crowd_type_3) AND ( ir_param.crowd_code       IS NOT NULL )) OR
          (( ir_param.crowd_type = gc_crowd_type_4) AND ( ir_param.acnt_crowd_code  IS NOT NULL )))
      AND (  ir_param.rcv_pay_div IS NULL )
      THEN
        -- オープン
        OPEN  get_cur01 FOR lv_select_main_start
                         || lv_select_g1_po102_3_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_po102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po101_3_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_po101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po112_3_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_po112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po103x5_3_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_po103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po103x124_3_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_po103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po105_3_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_po105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po108_3_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_po108
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om102_3_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_om102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om101_3_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_om101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om112_3_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_om112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om103x5_3_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_om103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om103x124_3_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_om103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om105_3_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_om105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om108_3_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_om108
                         || lv_where3
                         || lv_select_main_end
                         ;
        -- バルクフェッチ
        FETCH get_cur01 BULK COLLECT INTO ot_data_rec ;
        -- カーソルクローズ
        CLOSE get_cur01 ;
--
      --GROUP2
      --PTN04
      --品目区分          =  NULL
      --群(経理群)コード  =  NULL
      --受払区分          <> NULL
      ELSIF (ir_param.item_div    IS NULL ) 
      AND (((ir_param.crowd_type = gc_crowd_type_3) AND ( ir_param.crowd_code       IS NULL )) OR
          (( ir_param.crowd_type = gc_crowd_type_4) AND ( ir_param.acnt_crowd_code  IS NULL )))
      AND (  ir_param.rcv_pay_div IS NOT NULL )
      THEN
        -- オープン
        OPEN  get_cur01 FOR lv_select_main_start
                         || lv_select_g1_po102_4_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_po102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po101_4_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_po101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po112_4_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_po112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po103x5_4_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_po103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po103x124_4_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_po103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po105_4_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_po105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po108_4_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_po108
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om102_4_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_om102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om101_4_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_om101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om112_4_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_om112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om103x5_4_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_om103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om103x124_4_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_om103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om105_4_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_om105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om108_4_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_om108
                         || lv_where3
                         || lv_select_main_end
                         ;
        -- バルクフェッチ
        FETCH get_cur01 BULK COLLECT INTO ot_data_rec ;
        -- カーソルクローズ
        CLOSE get_cur01 ;
--
      --GROUP2
      --PTN05
      --品目区分          <> NULL
      --群(経理群)コード  <> NULL
      --受払区分          =  NULL
      ELSIF (ir_param.item_div    IS NOT NULL ) 
      AND (((ir_param.crowd_type = gc_crowd_type_3) AND ( ir_param.crowd_code       IS NOT NULL )) OR
          (( ir_param.crowd_type = gc_crowd_type_4) AND ( ir_param.acnt_crowd_code  IS NOT NULL )))
      AND (  ir_param.rcv_pay_div IS NULL )
      THEN
        -- オープン
        OPEN  get_cur01 FOR lv_select_main_start
                         || lv_select_g1_po102_3_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_po102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po101_3_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_po101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po112_3_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_po112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po103x5_3_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_po103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po103x124_3_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_po103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po105_3_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_po105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po108_3_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_po108
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om102_3_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_om102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om101_3_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_om101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om112_3_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_om112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om103x5_3_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_om103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om103x124_3_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_om103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om105_3_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_om105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om108_3_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_om108
                         || lv_where3
                         || lv_select_main_end
                         ;
        -- バルクフェッチ
        FETCH get_cur01 BULK COLLECT INTO ot_data_rec ;
        -- カーソルクローズ
        CLOSE get_cur01 ;
--
      --GROUP2
      --PTN06
      --品目区分          =  NULL
      --群(経理群)コード  <> NULL
      --受払区分          <> NULL
      ELSIF (ir_param.item_div    IS NULL ) 
      AND (((ir_param.crowd_type = gc_crowd_type_3) AND ( ir_param.crowd_code       IS NOT NULL )) OR
          (( ir_param.crowd_type = gc_crowd_type_4) AND ( ir_param.acnt_crowd_code  IS NOT NULL )))
      AND (  ir_param.rcv_pay_div IS NOT NULL )
      THEN
        -- オープン
        OPEN  get_cur01 FOR lv_select_main_start
                         || lv_select_g1_po102_6_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_po102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po101_6_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_po101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po112_6_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_po112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po103x5_6_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_po103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po103x124_6_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_po103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po105_6_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_po105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po108_6_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_po108
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om102_6_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_om102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om101_6_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_om101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om112_6_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_om112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om103x5_6_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_om103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om103x124_6_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_om103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om105_6_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_om105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om108_6_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_om108
                         || lv_where3
                         || lv_select_main_end
                         ;
        -- バルクフェッチ
        FETCH get_cur01 BULK COLLECT INTO ot_data_rec ;
        -- カーソルクローズ
        CLOSE get_cur01 ;
--
      --GROUP2
      --PTN07
      --品目区分          <> NULL
      --群(経理群)コード  =  NULL
      --受払区分          <> NULL
      ELSIF (ir_param.item_div    IS NOT NULL ) 
      AND (((ir_param.crowd_type = gc_crowd_type_3) AND ( ir_param.crowd_code       IS NULL )) OR
          (( ir_param.crowd_type = gc_crowd_type_4) AND ( ir_param.acnt_crowd_code  IS NULL )))
      AND (  ir_param.rcv_pay_div IS NOT NULL )
      THEN
        -- オープン
        OPEN  get_cur01 FOR lv_select_main_start
                         || lv_select_g1_po102_4_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_po102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po101_4_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_po101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po112_4_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_po112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po103x5_4_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_po103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po103x124_4_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_po103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po105_4_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_po105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po108_4_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_po108
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om102_4_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_om102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om101_4_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_om101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om112_4_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_om112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om103x5_4_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_om103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om103x124_4_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_om103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om105_4_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_om105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om108_4_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_om108
                         || lv_where3
                         || lv_select_main_end
                         ;
        -- バルクフェッチ
        FETCH get_cur01 BULK COLLECT INTO ot_data_rec ;
        -- カーソルクローズ
        CLOSE get_cur01 ;
--
      --GROUP2
      --PTN08
      --品目区分          <> NULL
      --群(経理群)コード  <> NULL
      --受払区分          <> NULL
      ELSE
        -- オープン
        OPEN  get_cur01 FOR lv_select_main_start
                         || lv_select_g1_po102_6_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_po102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po101_6_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_po101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po112_6_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_po112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po103x5_6_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_po103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po103x124_6_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_po103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po105_6_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_po105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po108_6_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_po108
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om102_6_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_om102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om101_6_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_om101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om112_6_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_om112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om103x5_6_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_om103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om103x124_6_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_om103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om105_6_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_om105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om108_6_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_om108
                         || lv_where3
                         || lv_select_main_end
                         ;
        -- バルクフェッチ
        FETCH get_cur01 BULK COLLECT INTO ot_data_rec ;
        -- カーソルクローズ
        CLOSE get_cur01 ;
      END IF;
--
    -- 集計パターン３設定 (集計：1.成績部署、2.品目区分、3.出荷先)
    ELSIF ( ir_param.result_post IS NULL )
    AND   ( ir_param.whse_code   IS NOT NULL )
    AND   ( ir_param.party_code  IS NULL )
    THEN
--
      --GROUP3
      --PTN01
      --品目区分          =  NULL
      --群(経理群)コード  =  NULL
      --受払区分          =  NULL
      IF  (  ir_param.item_div    IS NULL ) 
      AND (((ir_param.crowd_type = gc_crowd_type_3) AND ( ir_param.crowd_code       IS NULL )) OR
          (( ir_param.crowd_type = gc_crowd_type_4) AND ( ir_param.acnt_crowd_code  IS NULL )))
      AND (  ir_param.rcv_pay_div IS NULL )
      THEN
        -- オープン
        OPEN  get_cur01 FOR lv_select_main_start
                         || lv_select_g1_po102_1_hint
                         || lv_select_common
                         || lv_select_group3
                         || lv_select_1_po102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po101_1_hint
                         || lv_select_common
                         || lv_select_group3
                         || lv_select_1_po101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po112_1_hint
                         || lv_select_common
                         || lv_select_group3
                         || lv_select_1_po112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po103x5_1_hint
                         || lv_select_common
                         || lv_select_group3_2
                         || lv_select_1_po103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po103x124_1_hint
                         || lv_select_common
                         || lv_select_group3_2
                         || lv_select_1_po103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po105_1_hint
                         || lv_select_common
                         || lv_select_group3_2
                         || lv_select_1_po105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po108_1_hint
                         || lv_select_common
                         || lv_select_group3_2
                         || lv_select_1_po108
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om102_1_hint
                         || lv_select_common
                         || lv_select_group3
                         || lv_select_1_om102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om101_1_hint
                         || lv_select_common
                         || lv_select_group3
                         || lv_select_1_om101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om112_1_hint
                         || lv_select_common
                         || lv_select_group3
                         || lv_select_1_om112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om103x5_1_hint
                         || lv_select_common
                         || lv_select_group3_2
                         || lv_select_1_om103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om103x124_1_hint
                         || lv_select_common
                         || lv_select_group3_2
                         || lv_select_1_om103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om105_1_hint
                         || lv_select_common
                         || lv_select_group3_2
                         || lv_select_1_om105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om108_1_hint
                         || lv_select_common
                         || lv_select_group3_2
                         || lv_select_1_om108
                         || lv_where3
                         || lv_select_main_end
                         ;
        -- バルクフェッチ
        FETCH get_cur01 BULK COLLECT INTO ot_data_rec ;
        -- カーソルクローズ
        CLOSE get_cur01 ;
--
      --GROUP3
      --PTN02
      --品目区分          <> NULL
      --群(経理群)コード  =  NULL
      --受払区分          =  NULL
      ELSIF (ir_param.item_div    IS NOT NULL ) 
      AND (((ir_param.crowd_type = gc_crowd_type_3) AND ( ir_param.crowd_code       IS NULL )) OR
          (( ir_param.crowd_type = gc_crowd_type_4) AND ( ir_param.acnt_crowd_code  IS NULL )))
      AND (  ir_param.rcv_pay_div IS NULL )
      THEN
        -- オープン
        OPEN  get_cur01 FOR lv_select_main_start
                         || lv_select_g1_po102_2_hint
                         || lv_select_common
                         || lv_select_group3
                         || lv_select_1_po102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po101_2_hint
                         || lv_select_common
                         || lv_select_group3
                         || lv_select_1_po101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po112_2_hint
                         || lv_select_common
                         || lv_select_group3
                         || lv_select_1_po112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po103x5_2_hint
                         || lv_select_common
                         || lv_select_group3_2
                         || lv_select_1_po103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po103x124_2_hint
                         || lv_select_common
                         || lv_select_group3_2
                         || lv_select_1_po103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po105_2_hint
                         || lv_select_common
                         || lv_select_group3_2
                         || lv_select_1_po105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po108_2_hint
                         || lv_select_common
                         || lv_select_group3_2
                         || lv_select_1_po108
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om102_2_hint
                         || lv_select_common
                         || lv_select_group3
                         || lv_select_1_om102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om101_2_hint
                         || lv_select_common
                         || lv_select_group3
                         || lv_select_1_om101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om112_2_hint
                         || lv_select_common
                         || lv_select_group3
                         || lv_select_1_om112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om103x5_2_hint
                         || lv_select_common
                         || lv_select_group3_2
                         || lv_select_1_om103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om103x124_2_hint
                         || lv_select_common
                         || lv_select_group3_2
                         || lv_select_1_om103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om105_2_hint
                         || lv_select_common
                         || lv_select_group3_2
                         || lv_select_1_om105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om108_2_hint
                         || lv_select_common
                         || lv_select_group3_2
                         || lv_select_1_om108
                         || lv_where3
                         || lv_select_main_end
                         ;
        -- バルクフェッチ
        FETCH get_cur01 BULK COLLECT INTO ot_data_rec ;
        -- カーソルクローズ
        CLOSE get_cur01 ;
--
      --GROUP3
      --PTN03
      --品目区分          =  NULL
      --群(経理群)コード  <> NULL
      --受払区分          =  NULL
      ELSIF (ir_param.item_div    IS NULL ) 
      AND (((ir_param.crowd_type = gc_crowd_type_3) AND ( ir_param.crowd_code       IS NOT NULL )) OR
          (( ir_param.crowd_type = gc_crowd_type_4) AND ( ir_param.acnt_crowd_code  IS NOT NULL )))
      AND (  ir_param.rcv_pay_div IS NULL )
      THEN
        -- オープン
        OPEN  get_cur01 FOR lv_select_main_start
                         || lv_select_g1_po102_3_hint
                         || lv_select_common
                         || lv_select_group3
                         || lv_select_1_po102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po101_3_hint
                         || lv_select_common
                         || lv_select_group3
                         || lv_select_1_po101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po112_3_hint
                         || lv_select_common
                         || lv_select_group3
                         || lv_select_1_po112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po103x5_3_hint
                         || lv_select_common
                         || lv_select_group3_2
                         || lv_select_1_po103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po103x124_3_hint
                         || lv_select_common
                         || lv_select_group3_2
                         || lv_select_1_po103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po105_3_hint
                         || lv_select_common
                         || lv_select_group3_2
                         || lv_select_1_po105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po108_3_hint
                         || lv_select_common
                         || lv_select_group3_2
                         || lv_select_1_po108
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om102_3_hint
                         || lv_select_common
                         || lv_select_group3
                         || lv_select_1_om102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om101_3_hint
                         || lv_select_common
                         || lv_select_group3
                         || lv_select_1_om101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om112_3_hint
                         || lv_select_common
                         || lv_select_group3
                         || lv_select_1_om112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om103x5_3_hint
                         || lv_select_common
                         || lv_select_group3_2
                         || lv_select_1_om103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om103x124_3_hint
                         || lv_select_common
                         || lv_select_group3_2
                         || lv_select_1_om103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om105_3_hint
                         || lv_select_common
                         || lv_select_group3_2
                         || lv_select_1_om105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om108_3_hint
                         || lv_select_common
                         || lv_select_group3_2
                         || lv_select_1_om108
                         || lv_where3
                         || lv_select_main_end
                         ;
        -- バルクフェッチ
        FETCH get_cur01 BULK COLLECT INTO ot_data_rec ;
        -- カーソルクローズ
        CLOSE get_cur01 ;
--
      --GROUP3
      --PTN04
      --品目区分          =  NULL
      --群(経理群)コード  =  NULL
      --受払区分          <> NULL
      ELSIF (ir_param.item_div    IS NULL ) 
      AND (((ir_param.crowd_type = gc_crowd_type_3) AND ( ir_param.crowd_code       IS NULL )) OR
          (( ir_param.crowd_type = gc_crowd_type_4) AND ( ir_param.acnt_crowd_code  IS NULL )))
      AND (  ir_param.rcv_pay_div IS NOT NULL )
      THEN
        -- オープン
        OPEN  get_cur01 FOR lv_select_main_start
                         || lv_select_g1_po102_4_hint
                         || lv_select_common
                         || lv_select_group3
                         || lv_select_1_po102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po101_4_hint
                         || lv_select_common
                         || lv_select_group3
                         || lv_select_1_po101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po112_4_hint
                         || lv_select_common
                         || lv_select_group3
                         || lv_select_1_po112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po103x5_4_hint
                         || lv_select_common
                         || lv_select_group3_2
                         || lv_select_1_po103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po103x124_4_hint
                         || lv_select_common
                         || lv_select_group3_2
                         || lv_select_1_po103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po105_4_hint
                         || lv_select_common
                         || lv_select_group3_2
                         || lv_select_1_po105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po108_4_hint
                         || lv_select_common
                         || lv_select_group3_2
                         || lv_select_1_po108
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om102_4_hint
                         || lv_select_common
                         || lv_select_group3
                         || lv_select_1_om102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om101_4_hint
                         || lv_select_common
                         || lv_select_group3
                         || lv_select_1_om101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om112_4_hint
                         || lv_select_common
                         || lv_select_group3
                         || lv_select_1_om112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om103x5_4_hint
                         || lv_select_common
                         || lv_select_group3_2
                         || lv_select_1_om103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om103x124_4_hint
                         || lv_select_common
                         || lv_select_group3_2
                         || lv_select_1_om103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om105_4_hint
                         || lv_select_common
                         || lv_select_group3_2
                         || lv_select_1_om105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om108_4_hint
                         || lv_select_common
                         || lv_select_group3_2
                         || lv_select_1_om108
                         || lv_where3
                         || lv_select_main_end
                         ;
        -- バルクフェッチ
        FETCH get_cur01 BULK COLLECT INTO ot_data_rec ;
        -- カーソルクローズ
        CLOSE get_cur01 ;
--
      --GROUP3
      --PTN05
      --品目区分          <> NULL
      --群(経理群)コード  <> NULL
      --受払区分          =  NULL
      ELSIF (ir_param.item_div    IS NOT NULL ) 
      AND (((ir_param.crowd_type = gc_crowd_type_3) AND ( ir_param.crowd_code       IS NOT NULL )) OR
          (( ir_param.crowd_type = gc_crowd_type_4) AND ( ir_param.acnt_crowd_code  IS NOT NULL )))
      AND (  ir_param.rcv_pay_div IS NULL )
      THEN
        -- オープン
        OPEN  get_cur01 FOR lv_select_main_start
                         || lv_select_g1_po102_3_hint
                         || lv_select_common
                         || lv_select_group3
                         || lv_select_1_po102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po101_3_hint
                         || lv_select_common
                         || lv_select_group3
                         || lv_select_1_po101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po112_3_hint
                         || lv_select_common
                         || lv_select_group3
                         || lv_select_1_po112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po103x5_3_hint
                         || lv_select_common
                         || lv_select_group3_2
                         || lv_select_1_po103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po103x124_3_hint
                         || lv_select_common
                         || lv_select_group3_2
                         || lv_select_1_po103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po105_3_hint
                         || lv_select_common
                         || lv_select_group3_2
                         || lv_select_1_po105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po108_3_hint
                         || lv_select_common
                         || lv_select_group3_2
                         || lv_select_1_po108
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om102_3_hint
                         || lv_select_common
                         || lv_select_group3
                         || lv_select_1_om102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om101_3_hint
                         || lv_select_common
                         || lv_select_group3
                         || lv_select_1_om101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om112_3_hint
                         || lv_select_common
                         || lv_select_group3
                         || lv_select_1_om112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om103x5_3_hint
                         || lv_select_common
                         || lv_select_group3_2
                         || lv_select_1_om103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om103x124_3_hint
                         || lv_select_common
                         || lv_select_group3_2
                         || lv_select_1_om103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om105_3_hint
                         || lv_select_common
                         || lv_select_group3_2
                         || lv_select_1_om105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om108_3_hint
                         || lv_select_common
                         || lv_select_group3_2
                         || lv_select_1_om108
                         || lv_where3
                         || lv_select_main_end
                         ;
        -- バルクフェッチ
        FETCH get_cur01 BULK COLLECT INTO ot_data_rec ;
        -- カーソルクローズ
        CLOSE get_cur01 ;
--
      --GROUP3
      --PTN06
      --品目区分          =  NULL
      --群(経理群)コード  <> NULL
      --受払区分          <> NULL
      ELSIF (ir_param.item_div    IS NULL ) 
      AND (((ir_param.crowd_type = gc_crowd_type_3) AND ( ir_param.crowd_code       IS NOT NULL )) OR
          (( ir_param.crowd_type = gc_crowd_type_4) AND ( ir_param.acnt_crowd_code  IS NOT NULL )))
      AND (  ir_param.rcv_pay_div IS NOT NULL )
      THEN
        -- オープン
        OPEN  get_cur01 FOR lv_select_main_start
                         || lv_select_g1_po102_6_hint
                         || lv_select_common
                         || lv_select_group3
                         || lv_select_1_po102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po101_6_hint
                         || lv_select_common
                         || lv_select_group3
                         || lv_select_1_po101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po112_6_hint
                         || lv_select_common
                         || lv_select_group3
                         || lv_select_1_po112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po103x5_6_hint
                         || lv_select_common
                         || lv_select_group3_2
                         || lv_select_1_po103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po103x124_6_hint
                         || lv_select_common
                         || lv_select_group3_2
                         || lv_select_1_po103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po105_6_hint
                         || lv_select_common
                         || lv_select_group3_2
                         || lv_select_1_po105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po108_6_hint
                         || lv_select_common
                         || lv_select_group3_2
                         || lv_select_1_po108
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om102_6_hint
                         || lv_select_common
                         || lv_select_group3
                         || lv_select_1_om102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om101_6_hint
                         || lv_select_common
                         || lv_select_group3
                         || lv_select_1_om101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om112_6_hint
                         || lv_select_common
                         || lv_select_group3
                         || lv_select_1_om112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om103x5_6_hint
                         || lv_select_common
                         || lv_select_group3_2
                         || lv_select_1_om103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om103x124_6_hint
                         || lv_select_common
                         || lv_select_group3_2
                         || lv_select_1_om103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om105_6_hint
                         || lv_select_common
                         || lv_select_group3_2
                         || lv_select_1_om105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om108_6_hint
                         || lv_select_common
                         || lv_select_group3_2
                         || lv_select_1_om108
                         || lv_where3
                         || lv_select_main_end
                         ;
        -- バルクフェッチ
        FETCH get_cur01 BULK COLLECT INTO ot_data_rec ;
        -- カーソルクローズ
        CLOSE get_cur01 ;
--
      --GROUP3
      --PTN07
      --品目区分          <> NULL
      --群(経理群)コード  =  NULL
      --受払区分          <> NULL
      ELSIF (ir_param.item_div    IS NOT NULL ) 
      AND (((ir_param.crowd_type = gc_crowd_type_3) AND ( ir_param.crowd_code       IS NULL )) OR
          (( ir_param.crowd_type = gc_crowd_type_4) AND ( ir_param.acnt_crowd_code  IS NULL )))
      AND (  ir_param.rcv_pay_div IS NOT NULL )
      THEN
        -- オープン
        OPEN  get_cur01 FOR lv_select_main_start
                         || lv_select_g1_po102_4_hint
                         || lv_select_common
                         || lv_select_group3
                         || lv_select_1_po102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po101_4_hint
                         || lv_select_common
                         || lv_select_group3
                         || lv_select_1_po101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po112_4_hint
                         || lv_select_common
                         || lv_select_group3
                         || lv_select_1_po112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po103x5_4_hint
                         || lv_select_common
                         || lv_select_group3_2
                         || lv_select_1_po103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po103x124_4_hint
                         || lv_select_common
                         || lv_select_group3_2
                         || lv_select_1_po103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po105_4_hint
                         || lv_select_common
                         || lv_select_group3_2
                         || lv_select_1_po105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po108_4_hint
                         || lv_select_common
                         || lv_select_group3_2
                         || lv_select_1_po108
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om102_4_hint
                         || lv_select_common
                         || lv_select_group3
                         || lv_select_1_om102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om101_4_hint
                         || lv_select_common
                         || lv_select_group3
                         || lv_select_1_om101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om112_4_hint
                         || lv_select_common
                         || lv_select_group3
                         || lv_select_1_om112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om103x5_4_hint
                         || lv_select_common
                         || lv_select_group3_2
                         || lv_select_1_om103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om103x124_4_hint
                         || lv_select_common
                         || lv_select_group3_2
                         || lv_select_1_om103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om105_4_hint
                         || lv_select_common
                         || lv_select_group3_2
                         || lv_select_1_om105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om108_4_hint
                         || lv_select_common
                         || lv_select_group3_2
                         || lv_select_1_om108
                         || lv_where3
                         || lv_select_main_end
                         ;
        -- バルクフェッチ
        FETCH get_cur01 BULK COLLECT INTO ot_data_rec ;
        -- カーソルクローズ
        CLOSE get_cur01 ;
--
      --GROUP3
      --PTN08
      --品目区分          <> NULL
      --群(経理群)コード  <> NULL
      --受払区分          <> NULL
      ELSE
        -- オープン
        OPEN  get_cur01 FOR lv_select_main_start
                         || lv_select_g1_po102_6_hint
                         || lv_select_common
                         || lv_select_group3
                         || lv_select_1_po102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po101_6_hint
                         || lv_select_common
                         || lv_select_group3
                         || lv_select_1_po101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po112_6_hint
                         || lv_select_common
                         || lv_select_group3
                         || lv_select_1_po112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po103x5_6_hint
                         || lv_select_common
                         || lv_select_group3_2
                         || lv_select_1_po103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po103x124_6_hint
                         || lv_select_common
                         || lv_select_group3_2
                         || lv_select_1_po103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po105_6_hint
                         || lv_select_common
                         || lv_select_group3_2
                         || lv_select_1_po105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po108_6_hint
                         || lv_select_common
                         || lv_select_group3_2
                         || lv_select_1_po108
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om102_6_hint
                         || lv_select_common
                         || lv_select_group3
                         || lv_select_1_om102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om101_6_hint
                         || lv_select_common
                         || lv_select_group3
                         || lv_select_1_om101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om112_6_hint
                         || lv_select_common
                         || lv_select_group3
                         || lv_select_1_om112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om103x5_6_hint
                         || lv_select_common
                         || lv_select_group3_2
                         || lv_select_1_om103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om103x124_6_hint
                         || lv_select_common
                         || lv_select_group3_2
                         || lv_select_1_om103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om105_6_hint
                         || lv_select_common
                         || lv_select_group3_2
                         || lv_select_1_om105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om108_6_hint
                         || lv_select_common
                         || lv_select_group3_2
                         || lv_select_1_om108
                         || lv_where3
                         || lv_select_main_end
                         ;
        -- バルクフェッチ
        FETCH get_cur01 BULK COLLECT INTO ot_data_rec ;
        -- カーソルクローズ
        CLOSE get_cur01 ;
      END IF;
--
    -- 集計パターン４設定 (集計：1.成績部署、2.品目区分)
    ELSIF ( ir_param.result_post IS NULL )
    AND   ( ir_param.whse_code   IS NOT NULL )
    AND   ( ir_param.party_code  IS NOT NULL )
    THEN
--
      --GROUP4
      --PTN01
      --品目区分          =  NULL
      --群(経理群)コード  =  NULL
      --受払区分          =  NULL
      IF  (  ir_param.item_div    IS NULL ) 
      AND (((ir_param.crowd_type = gc_crowd_type_3) AND ( ir_param.crowd_code       IS NULL )) OR
          (( ir_param.crowd_type = gc_crowd_type_4) AND ( ir_param.acnt_crowd_code  IS NULL )))
      AND (  ir_param.rcv_pay_div IS NULL )
      THEN
        -- オープン
        OPEN  get_cur01 FOR lv_select_main_start
                         || lv_select_g1_po102_1_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_po102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po101_1_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_po101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po112_1_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_po112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po103x5_1_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_po103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po103x124_1_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_po103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po105_1_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_po105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po108_1_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_po108
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om102_1_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_om102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om101_1_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_om101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om112_1_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_om112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om103x5_1_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_om103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om103x124_1_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_om103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om105_1_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_om105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om108_1_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_om108
                         || lv_where3
                         || lv_select_main_end
                         ;
        -- バルクフェッチ
        FETCH get_cur01 BULK COLLECT INTO ot_data_rec ;
        -- カーソルクローズ
        CLOSE get_cur01 ;
--
      --GROUP4
      --PTN02
      --品目区分          <> NULL
      --群(経理群)コード  =  NULL
      --受払区分          =  NULL
      ELSIF (ir_param.item_div    IS NOT NULL ) 
      AND (((ir_param.crowd_type = gc_crowd_type_3) AND ( ir_param.crowd_code       IS NULL )) OR
          (( ir_param.crowd_type = gc_crowd_type_4) AND ( ir_param.acnt_crowd_code  IS NULL )))
      AND (  ir_param.rcv_pay_div IS NULL )
      THEN
        -- オープン
        OPEN  get_cur01 FOR lv_select_main_start
                         || lv_select_g1_po102_2_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_po102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po101_2_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_po101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po112_2_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_po112
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po103x5_2_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_po103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po103x124_2_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_po103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po105_2_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_po105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po108_2_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_po108
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om102_2_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_om102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om101_2_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_om101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om112_2_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_om112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om103x5_2_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_om103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om103x124_2_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_om103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om105_2_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_om105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om108_2_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_om108
                         || lv_where3
                         || lv_select_main_end
                         ;
        -- バルクフェッチ
        FETCH get_cur01 BULK COLLECT INTO ot_data_rec ;
        -- カーソルクローズ
        CLOSE get_cur01 ;
--
      --GROUP4
      --PTN03
      --品目区分          =  NULL
      --群(経理群)コード  <> NULL
      --受払区分          =  NULL
      ELSIF (ir_param.item_div    IS NULL ) 
      AND (((ir_param.crowd_type = gc_crowd_type_3) AND ( ir_param.crowd_code       IS NOT NULL )) OR
          (( ir_param.crowd_type = gc_crowd_type_4) AND ( ir_param.acnt_crowd_code  IS NOT NULL )))
      AND (  ir_param.rcv_pay_div IS NULL )
      THEN
        -- オープン
        OPEN  get_cur01 FOR lv_select_main_start
                         || lv_select_g1_po102_3_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_po102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po101_3_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_po101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po112_3_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_po112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po103x5_3_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_po103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po103x124_3_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_po103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po105_3_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_po105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po108_3_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_po108
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om102_3_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_om102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om101_3_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_om101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om112_3_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_om112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om103x5_3_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_om103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om103x124_3_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_om103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om105_3_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_om105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om108_3_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_om108
                         || lv_where3
                         || lv_select_main_end
                         ;
        -- バルクフェッチ
        FETCH get_cur01 BULK COLLECT INTO ot_data_rec ;
        -- カーソルクローズ
        CLOSE get_cur01 ;
--
      --GROUP4
      --PTN04
      --品目区分          =  NULL
      --群(経理群)コード  =  NULL
      --受払区分          <> NULL
      ELSIF (ir_param.item_div    IS NULL ) 
      AND (((ir_param.crowd_type = gc_crowd_type_3) AND ( ir_param.crowd_code       IS NULL )) OR
          (( ir_param.crowd_type = gc_crowd_type_4) AND ( ir_param.acnt_crowd_code  IS NULL )))
      AND (  ir_param.rcv_pay_div IS NOT NULL )
      THEN
        -- オープン
        OPEN  get_cur01 FOR lv_select_main_start
                         || lv_select_g1_po102_4_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_po102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po101_4_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_po101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po112_4_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_po112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po103x5_4_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_po103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po103x124_4_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_po103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po105_4_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_po105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po108_4_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_po108
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om102_4_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_om102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om101_4_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_om101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om112_4_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_om112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om103x5_4_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_om103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om103x124_4_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_om103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om105_4_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_om105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om108_4_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_om108
                         || lv_where3
                         || lv_select_main_end
                         ;
        -- バルクフェッチ
        FETCH get_cur01 BULK COLLECT INTO ot_data_rec ;
        -- カーソルクローズ
        CLOSE get_cur01 ;
--
      --GROUP4
      --PTN05
      --品目区分          <> NULL
      --群(経理群)コード  <> NULL
      --受払区分          =  NULL
      ELSIF (ir_param.item_div    IS NOT NULL ) 
      AND (((ir_param.crowd_type = gc_crowd_type_3) AND ( ir_param.crowd_code       IS NOT NULL )) OR
          (( ir_param.crowd_type = gc_crowd_type_4) AND ( ir_param.acnt_crowd_code  IS NOT NULL )))
      AND (  ir_param.rcv_pay_div IS NULL )
      THEN
        -- オープン
        OPEN  get_cur01 FOR lv_select_main_start
                         || lv_select_g1_po102_3_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_po102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po101_3_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_po101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po112_3_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_po112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po103x5_3_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_po103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po103x124_3_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_po103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po105_3_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_po105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po108_3_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_po108
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om102_3_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_om102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om101_3_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_om101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om112_3_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_om112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om103x5_3_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_om103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om103x124_3_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_om103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om105_3_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_om105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om108_3_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_om108
                         || lv_where3
                         || lv_select_main_end
                         ;
        -- バルクフェッチ
        FETCH get_cur01 BULK COLLECT INTO ot_data_rec ;
        -- カーソルクローズ
        CLOSE get_cur01 ;
--
      --GROUP4
      --PTN06
      --品目区分          =  NULL
      --群(経理群)コード  <> NULL
      --受払区分          <> NULL
      ELSIF (ir_param.item_div    IS NULL ) 
      AND (((ir_param.crowd_type = gc_crowd_type_3) AND ( ir_param.crowd_code       IS NOT NULL )) OR
          (( ir_param.crowd_type = gc_crowd_type_4) AND ( ir_param.acnt_crowd_code  IS NOT NULL )))
      AND (  ir_param.rcv_pay_div IS NOT NULL )
      THEN
        -- オープン
        OPEN  get_cur01 FOR lv_select_main_start
                         || lv_select_g1_po102_6_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_po102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po101_6_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_po101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po112_6_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_po112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po103x5_6_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_po103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po103x124_6_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_po103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po105_6_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_po105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po108_6_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_po108
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om102_6_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_om102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om101_6_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_om101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om112_6_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_om112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om103x5_6_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_om103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om103x124_6_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_om103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om105_6_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_om105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om108_6_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_om108
                         || lv_where3
                         || lv_select_main_end
                         ;
        -- バルクフェッチ
        FETCH get_cur01 BULK COLLECT INTO ot_data_rec ;
        -- カーソルクローズ
        CLOSE get_cur01 ;
--
      --GROUP4
      --PTN07
      --品目区分          <> NULL
      --群(経理群)コード  =  NULL
      --受払区分          <> NULL
      ELSIF (ir_param.item_div    IS NOT NULL ) 
      AND (((ir_param.crowd_type = gc_crowd_type_3) AND ( ir_param.crowd_code       IS NULL )) OR
          (( ir_param.crowd_type = gc_crowd_type_4) AND ( ir_param.acnt_crowd_code  IS NULL )))
      AND (  ir_param.rcv_pay_div IS NOT NULL )
      THEN
        -- オープン
        OPEN  get_cur01 FOR lv_select_main_start
                         || lv_select_g1_po102_4_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_po102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po101_4_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_po101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po112_4_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_po112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po103x5_4_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_po103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po103x124_4_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_po103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po105_4_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_po105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po108_4_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_po108
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om102_4_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_om102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om101_4_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_om101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om112_4_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_om112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om103x5_4_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_om103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om103x124_4_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_om103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om105_4_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_om105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om108_4_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_om108
                         || lv_where3
                         || lv_select_main_end
                         ;
        -- バルクフェッチ
        FETCH get_cur01 BULK COLLECT INTO ot_data_rec ;
        -- カーソルクローズ
        CLOSE get_cur01 ;
--
      --GROUP4
      --PTN08
      --品目区分          <> NULL
      --群(経理群)コード  <> NULL
      --受払区分          <> NULL
      ELSE
        -- オープン
        OPEN  get_cur01 FOR lv_select_main_start
                         || lv_select_g1_po102_6_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_po102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po101_6_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_po101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po112_6_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_po112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po103x5_6_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_po103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po103x124_6_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_po103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po105_6_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_po105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po108_6_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_po108
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om102_6_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_om102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om101_6_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_om101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om112_6_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_om112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om103x5_6_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_om103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om103x124_6_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_om103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om105_6_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_om105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om108_6_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_om108
                         || lv_where3
                         || lv_select_main_end
                         ;
        -- バルクフェッチ
        FETCH get_cur01 BULK COLLECT INTO ot_data_rec ;
        -- カーソルクローズ
        CLOSE get_cur01 ;
      END IF;
--
    -- 集計パターン５設定 (集計：1.品目区分、2.倉庫、3.出荷先)
    ELSIF ( ir_param.result_post IS NOT NULL )
    AND   ( ir_param.whse_code   IS NULL )
    AND   ( ir_param.party_code  IS NULL )
    THEN
--
      --GROUP5
      --PTN01
      --品目区分          =  NULL
      --群(経理群)コード  =  NULL
      --受払区分          =  NULL
      IF  (  ir_param.item_div    IS NULL ) 
      AND (((ir_param.crowd_type = gc_crowd_type_3) AND ( ir_param.crowd_code       IS NULL )) OR
          (( ir_param.crowd_type = gc_crowd_type_4) AND ( ir_param.acnt_crowd_code  IS NULL )))
      AND (  ir_param.rcv_pay_div IS NULL )
      THEN
        -- オープン
        OPEN  get_cur01 FOR lv_select_main_start
                         || lv_select_g1_po102_1_hint
                         || lv_select_common
                         || lv_select_group5
                         || lv_select_1_po102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po101_1_hint
                         || lv_select_common
                         || lv_select_group5
                         || lv_select_1_po101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po112_1_hint
                         || lv_select_common
                         || lv_select_group5
                         || lv_select_1_po112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po103x5_1_hint
                         || lv_select_common
                         || lv_select_group5_2
                         || lv_select_1_po103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po103x124_1_hint
                         || lv_select_common
                         || lv_select_group5_2
                         || lv_select_1_po103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po105_1_hint
                         || lv_select_common
                         || lv_select_group5_2
                         || lv_select_1_po105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po108_1_hint
                         || lv_select_common
                         || lv_select_group5_2
                         || lv_select_1_po108
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om102_1_hint
                         || lv_select_common
                         || lv_select_group5
                         || lv_select_1_om102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om101_1_hint
                         || lv_select_common
                         || lv_select_group5
                         || lv_select_1_om101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om112_1_hint
                         || lv_select_common
                         || lv_select_group5
                         || lv_select_1_om112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om103x5_1_hint
                         || lv_select_common
                         || lv_select_group5_2
                         || lv_select_1_om103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om103x124_1_hint
                         || lv_select_common
                         || lv_select_group5_2
                         || lv_select_1_om103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om105_1_hint
                         || lv_select_common
                         || lv_select_group5_2
                         || lv_select_1_om105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om108_1_hint
                         || lv_select_common
                         || lv_select_group5_2
                         || lv_select_1_om108
                         || lv_where3
                         || lv_select_main_end
                         ;
        -- バルクフェッチ
        FETCH get_cur01 BULK COLLECT INTO ot_data_rec ;
        -- カーソルクローズ
        CLOSE get_cur01 ;
--
      --GROUP5
      --PTN02
      --品目区分          <> NULL
      --群(経理群)コード  =  NULL
      --受払区分          =  NULL
      ELSIF (ir_param.item_div    IS NOT NULL ) 
      AND (((ir_param.crowd_type = gc_crowd_type_3) AND ( ir_param.crowd_code       IS NULL )) OR
          (( ir_param.crowd_type = gc_crowd_type_4) AND ( ir_param.acnt_crowd_code  IS NULL )))
      AND (  ir_param.rcv_pay_div IS NULL )
      THEN
        -- オープン
        OPEN  get_cur01 FOR lv_select_main_start
                         || lv_select_g1_po102_2_hint
                         || lv_select_common
                         || lv_select_group5
                         || lv_select_1_po102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po101_2_hint
                         || lv_select_common
                         || lv_select_group5
                         || lv_select_1_po101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po112_2_hint
                         || lv_select_common
                         || lv_select_group5
                         || lv_select_1_po112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po103x5_2_hint
                         || lv_select_common
                         || lv_select_group5_2
                         || lv_select_1_po103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po103x124_2_hint
                         || lv_select_common
                         || lv_select_group5_2
                         || lv_select_1_po103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po105_2_hint
                         || lv_select_common
                         || lv_select_group5_2
                         || lv_select_1_po105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po108_2_hint
                         || lv_select_common
                         || lv_select_group5_2
                         || lv_select_1_po108
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om102_2_hint
                         || lv_select_common
                         || lv_select_group5
                         || lv_select_1_om102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om101_2_hint
                         || lv_select_common
                         || lv_select_group5
                         || lv_select_1_om101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om112_2_hint
                         || lv_select_common
                         || lv_select_group5
                         || lv_select_1_om112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om103x5_2_hint
                         || lv_select_common
                         || lv_select_group5_2
                         || lv_select_1_om103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om103x124_2_hint
                         || lv_select_common
                         || lv_select_group5_2
                         || lv_select_1_om103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om105_2_hint
                         || lv_select_common
                         || lv_select_group5_2
                         || lv_select_1_om105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om108_2_hint
                         || lv_select_common
                         || lv_select_group5_2
                         || lv_select_1_om108
                         || lv_where3
                         || lv_select_main_end
                         ;
        -- バルクフェッチ
        FETCH get_cur01 BULK COLLECT INTO ot_data_rec ;
        -- カーソルクローズ
        CLOSE get_cur01 ;
--
      --GROUP5
      --PTN03
      --品目区分          =  NULL
      --群(経理群)コード  <> NULL
      --受払区分          =  NULL
      ELSIF (ir_param.item_div    IS NULL ) 
      AND (((ir_param.crowd_type = gc_crowd_type_3) AND ( ir_param.crowd_code       IS NOT NULL )) OR
          (( ir_param.crowd_type = gc_crowd_type_4) AND ( ir_param.acnt_crowd_code  IS NOT NULL )))
      AND (  ir_param.rcv_pay_div IS NULL )
      THEN
        -- オープン
        OPEN  get_cur01 FOR lv_select_main_start
                         || lv_select_g1_po102_3_hint
                         || lv_select_common
                         || lv_select_group5
                         || lv_select_1_po102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po101_3_hint
                         || lv_select_common
                         || lv_select_group5
                         || lv_select_1_po101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po112_3_hint
                         || lv_select_common
                         || lv_select_group5
                         || lv_select_1_po112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po103x5_3_hint
                         || lv_select_common
                         || lv_select_group5_2
                         || lv_select_1_po103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po103x124_3_hint
                         || lv_select_common
                         || lv_select_group5_2
                         || lv_select_1_po103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po105_3_hint
                         || lv_select_common
                         || lv_select_group5_2
                         || lv_select_1_po105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po108_3_hint
                         || lv_select_common
                         || lv_select_group5_2
                         || lv_select_1_po108
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om102_3_hint
                         || lv_select_common
                         || lv_select_group5
                         || lv_select_1_om102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om101_3_hint
                         || lv_select_common
                         || lv_select_group5
                         || lv_select_1_om101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om112_3_hint
                         || lv_select_common
                         || lv_select_group5
                         || lv_select_1_om112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om103x5_3_hint
                         || lv_select_common
                         || lv_select_group5_2
                         || lv_select_1_om103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om103x124_3_hint
                         || lv_select_common
                         || lv_select_group5_2
                         || lv_select_1_om103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om105_3_hint
                         || lv_select_common
                         || lv_select_group5_2
                         || lv_select_1_om105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om108_3_hint
                         || lv_select_common
                         || lv_select_group5_2
                         || lv_select_1_om108
                         || lv_where3
                         || lv_select_main_end
                         ;
        -- バルクフェッチ
        FETCH get_cur01 BULK COLLECT INTO ot_data_rec ;
        -- カーソルクローズ
        CLOSE get_cur01 ;
--
      --GROUP5
      --PTN04
      --品目区分          =  NULL
      --群(経理群)コード  =  NULL
      --受払区分          <> NULL
      ELSIF (ir_param.item_div    IS NULL ) 
      AND (((ir_param.crowd_type = gc_crowd_type_3) AND ( ir_param.crowd_code       IS NULL )) OR
          (( ir_param.crowd_type = gc_crowd_type_4) AND ( ir_param.acnt_crowd_code  IS NULL )))
      AND (  ir_param.rcv_pay_div IS NOT NULL )
      THEN
        -- オープン
        OPEN  get_cur01 FOR lv_select_main_start
                         || lv_select_g1_po102_4_hint
                         || lv_select_common
                         || lv_select_group5
                         || lv_select_1_po102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po101_4_hint
                         || lv_select_common
                         || lv_select_group5
                         || lv_select_1_po101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po112_4_hint
                         || lv_select_common
                         || lv_select_group5
                         || lv_select_1_po112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po103x5_4_hint
                         || lv_select_common
                         || lv_select_group5_2
                         || lv_select_1_po103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po103x124_4_hint
                         || lv_select_common
                         || lv_select_group5_2
                         || lv_select_1_po103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po105_4_hint
                         || lv_select_common
                         || lv_select_group5_2
                         || lv_select_1_po105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po108_4_hint
                         || lv_select_common
                         || lv_select_group5_2
                         || lv_select_1_po108
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om102_4_hint
                         || lv_select_common
                         || lv_select_group5
                         || lv_select_1_om102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om101_4_hint
                         || lv_select_common
                         || lv_select_group5
                         || lv_select_1_om101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om112_4_hint
                         || lv_select_common
                         || lv_select_group5
                         || lv_select_1_om112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om103x5_4_hint
                         || lv_select_common
                         || lv_select_group5_2
                         || lv_select_1_om103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om103x124_4_hint
                         || lv_select_common
                         || lv_select_group5_2
                         || lv_select_1_om103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om105_4_hint
                         || lv_select_common
                         || lv_select_group5_2
                         || lv_select_1_om105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om108_4_hint
                         || lv_select_common
                         || lv_select_group5_2
                         || lv_select_1_om108
                         || lv_where3
                         || lv_select_main_end
                         ;
        -- バルクフェッチ
        FETCH get_cur01 BULK COLLECT INTO ot_data_rec ;
        -- カーソルクローズ
        CLOSE get_cur01 ;
--
      --GROUP5
      --PTN05
      --品目区分          <> NULL
      --群(経理群)コード  <> NULL
      --受払区分          =  NULL
      ELSIF (ir_param.item_div    IS NOT NULL ) 
      AND (((ir_param.crowd_type = gc_crowd_type_3) AND ( ir_param.crowd_code       IS NOT NULL )) OR
          (( ir_param.crowd_type = gc_crowd_type_4) AND ( ir_param.acnt_crowd_code  IS NOT NULL )))
      AND (  ir_param.rcv_pay_div IS NULL )
      THEN
        -- オープン
        OPEN  get_cur01 FOR lv_select_main_start
                         || lv_select_g1_po102_3_hint
                         || lv_select_common
                         || lv_select_group5
                         || lv_select_1_po102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po101_3_hint
                         || lv_select_common
                         || lv_select_group5
                         || lv_select_1_po101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po112_3_hint
                         || lv_select_common
                         || lv_select_group5
                         || lv_select_1_po112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po103x5_3_hint
                         || lv_select_common
                         || lv_select_group5_2
                         || lv_select_1_po103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po103x124_3_hint
                         || lv_select_common
                         || lv_select_group5_2
                         || lv_select_1_po103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po105_3_hint
                         || lv_select_common
                         || lv_select_group5_2
                         || lv_select_1_po105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po108_3_hint
                         || lv_select_common
                         || lv_select_group5_2
                         || lv_select_1_po108
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om102_3_hint
                         || lv_select_common
                         || lv_select_group5
                         || lv_select_1_om102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om101_3_hint
                         || lv_select_common
                         || lv_select_group5
                         || lv_select_1_om101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om112_3_hint
                         || lv_select_common
                         || lv_select_group5
                         || lv_select_1_om112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om103x5_3_hint
                         || lv_select_common
                         || lv_select_group5_2
                         || lv_select_1_om103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om103x124_3_hint
                         || lv_select_common
                         || lv_select_group5_2
                         || lv_select_1_om103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om105_3_hint
                         || lv_select_common
                         || lv_select_group5_2
                         || lv_select_1_om105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om108_3_hint
                         || lv_select_common
                         || lv_select_group5_2
                         || lv_select_1_om108
                         || lv_where3
                         || lv_select_main_end
                         ;
        -- バルクフェッチ
        FETCH get_cur01 BULK COLLECT INTO ot_data_rec ;
        -- カーソルクローズ
        CLOSE get_cur01 ;
--
      --GROUP5
      --PTN06
      --品目区分          =  NULL
      --群(経理群)コード  <> NULL
      --受払区分          <> NULL
      ELSIF (ir_param.item_div    IS NULL ) 
      AND (((ir_param.crowd_type = gc_crowd_type_3) AND ( ir_param.crowd_code       IS NOT NULL )) OR
          (( ir_param.crowd_type = gc_crowd_type_4) AND ( ir_param.acnt_crowd_code  IS NOT NULL )))
      AND (  ir_param.rcv_pay_div IS NOT NULL )
      THEN
        -- オープン
        OPEN  get_cur01 FOR lv_select_main_start
                         || lv_select_g1_po102_6_hint
                         || lv_select_common
                         || lv_select_group5
                         || lv_select_1_po102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po101_6_hint
                         || lv_select_common
                         || lv_select_group5
                         || lv_select_1_po101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po112_6_hint
                         || lv_select_common
                         || lv_select_group5
                         || lv_select_1_po112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po103x5_6_hint
                         || lv_select_common
                         || lv_select_group5_2
                         || lv_select_1_po103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po103x124_6_hint
                         || lv_select_common
                         || lv_select_group5_2
                         || lv_select_1_po103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po105_6_hint
                         || lv_select_common
                         || lv_select_group5_2
                         || lv_select_1_po105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po108_6_hint
                         || lv_select_common
                         || lv_select_group5_2
                         || lv_select_1_po108
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om102_6_hint
                         || lv_select_common
                         || lv_select_group5
                         || lv_select_1_om102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om101_6_hint
                         || lv_select_common
                         || lv_select_group5
                         || lv_select_1_om101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om112_6_hint
                         || lv_select_common
                         || lv_select_group5
                         || lv_select_1_om112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om103x5_6_hint
                         || lv_select_common
                         || lv_select_group5_2
                         || lv_select_1_om103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om103x124_6_hint
                         || lv_select_common
                         || lv_select_group5_2
                         || lv_select_1_om103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om105_6_hint
                         || lv_select_common
                         || lv_select_group5_2
                         || lv_select_1_om105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om108_6_hint
                         || lv_select_common
                         || lv_select_group5_2
                         || lv_select_1_om108
                         || lv_where3
                         || lv_select_main_end
                         ;
        -- バルクフェッチ
        FETCH get_cur01 BULK COLLECT INTO ot_data_rec ;
        -- カーソルクローズ
        CLOSE get_cur01 ;
--
      --GROUP5
      --PTN07
      --品目区分          <> NULL
      --群(経理群)コード  =  NULL
      --受払区分          <> NULL
      ELSIF (ir_param.item_div    IS NOT NULL ) 
      AND (((ir_param.crowd_type = gc_crowd_type_3) AND ( ir_param.crowd_code       IS NULL )) OR
          (( ir_param.crowd_type = gc_crowd_type_4) AND ( ir_param.acnt_crowd_code  IS NULL )))
      AND (  ir_param.rcv_pay_div IS NOT NULL )
      THEN
        -- オープン
        OPEN  get_cur01 FOR lv_select_main_start
                         || lv_select_g1_po102_4_hint
                         || lv_select_common
                         || lv_select_group5
                         || lv_select_1_po102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po101_4_hint
                         || lv_select_common
                         || lv_select_group5
                         || lv_select_1_po101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po112_4_hint
                         || lv_select_common
                         || lv_select_group5
                         || lv_select_1_po112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po103x5_4_hint
                         || lv_select_common
                         || lv_select_group5_2
                         || lv_select_1_po103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po103x124_4_hint
                         || lv_select_common
                         || lv_select_group5_2
                         || lv_select_1_po103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po105_4_hint
                         || lv_select_common
                         || lv_select_group5_2
                         || lv_select_1_po105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po108_4_hint
                         || lv_select_common
                         || lv_select_group5_2
                         || lv_select_1_po108
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om102_4_hint
                         || lv_select_common
                         || lv_select_group5
                         || lv_select_1_om102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om101_4_hint
                         || lv_select_common
                         || lv_select_group5
                         || lv_select_1_om101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om112_4_hint
                         || lv_select_common
                         || lv_select_group5
                         || lv_select_1_om112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om103x5_4_hint
                         || lv_select_common
                         || lv_select_group5_2
                         || lv_select_1_om103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om103x124_4_hint
                         || lv_select_common
                         || lv_select_group5_2
                         || lv_select_1_om103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om105_4_hint
                         || lv_select_common
                         || lv_select_group5_2
                         || lv_select_1_om105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om108_4_hint
                         || lv_select_common
                         || lv_select_group5_2
                         || lv_select_1_om108
                         || lv_where3
                         || lv_select_main_end
                         ;
        -- バルクフェッチ
        FETCH get_cur01 BULK COLLECT INTO ot_data_rec ;
        -- カーソルクローズ
        CLOSE get_cur01 ;
--
      --GROUP5
      --PTN08
      --品目区分          <> NULL
      --群(経理群)コード  <> NULL
      --受払区分          <> NULL
      ELSE
        -- オープン
        OPEN  get_cur01 FOR lv_select_main_start
                         || lv_select_g1_po102_6_hint
                         || lv_select_common
                         || lv_select_group5
                         || lv_select_1_po102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po101_6_hint
                         || lv_select_common
                         || lv_select_group5
                         || lv_select_1_po101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po112_6_hint
                         || lv_select_common
                         || lv_select_group5
                         || lv_select_1_po112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po103x5_6_hint
                         || lv_select_common
                         || lv_select_group5_2
                         || lv_select_1_po103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po103x124_6_hint
                         || lv_select_common
                         || lv_select_group5_2
                         || lv_select_1_po103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po105_6_hint
                         || lv_select_common
                         || lv_select_group5_2
                         || lv_select_1_po105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po108_6_hint
                         || lv_select_common
                         || lv_select_group5_2
                         || lv_select_1_po108
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om102_6_hint
                         || lv_select_common
                         || lv_select_group5
                         || lv_select_1_om102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om101_6_hint
                         || lv_select_common
                         || lv_select_group5
                         || lv_select_1_om101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om112_6_hint
                         || lv_select_common
                         || lv_select_group5
                         || lv_select_1_om112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om103x5_6_hint
                         || lv_select_common
                         || lv_select_group5_2
                         || lv_select_1_om103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om103x124_6_hint
                         || lv_select_common
                         || lv_select_group5_2
                         || lv_select_1_om103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om105_6_hint
                         || lv_select_common
                         || lv_select_group5_2
                         || lv_select_1_om105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om108_6_hint
                         || lv_select_common
                         || lv_select_group5_2
                         || lv_select_1_om108
                         || lv_where3
                         || lv_select_main_end
                         ;
        -- バルクフェッチ
        FETCH get_cur01 BULK COLLECT INTO ot_data_rec ;
        -- カーソルクローズ
        CLOSE get_cur01 ;
      END IF;
--
    -- 集計パターン６設定 (集計：1.品目区分、2.倉庫)
    ELSIF ( ir_param.result_post IS NOT NULL )
    AND   ( ir_param.whse_code   IS NULL )
    AND   ( ir_param.party_code  IS NOT NULL )
    THEN
--
      --GROUP6
      --PTN01
      --品目区分          =  NULL
      --群(経理群)コード  =  NULL
      --受払区分          =  NULL
      IF  (  ir_param.item_div    IS NULL ) 
      AND (((ir_param.crowd_type = gc_crowd_type_3) AND ( ir_param.crowd_code       IS NULL )) OR
          (( ir_param.crowd_type = gc_crowd_type_4) AND ( ir_param.acnt_crowd_code  IS NULL )))
      AND (  ir_param.rcv_pay_div IS NULL )
      THEN
        -- オープン
        OPEN  get_cur01 FOR lv_select_main_start
                         || lv_select_g1_po102_1_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_po102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po101_1_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_po101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po112_1_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_po112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po103x5_1_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_po103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po103x124_1_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_po103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po105_1_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_po105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po108_1_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_po108
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om102_1_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_om102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om101_1_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_om101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om112_1_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_om112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om103x5_1_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_om103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om103x124_1_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_om103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om105_1_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_om105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om108_1_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_om108
                         || lv_where3
                         || lv_select_main_end
                         ;
        -- バルクフェッチ
        FETCH get_cur01 BULK COLLECT INTO ot_data_rec ;
        -- カーソルクローズ
        CLOSE get_cur01 ;
--
      --GROUP6
      --PTN02
      --品目区分          <> NULL
      --群(経理群)コード  =  NULL
      --受払区分          =  NULL
      ELSIF (ir_param.item_div    IS NOT NULL ) 
      AND (((ir_param.crowd_type = gc_crowd_type_3) AND ( ir_param.crowd_code       IS NULL )) OR
          (( ir_param.crowd_type = gc_crowd_type_4) AND ( ir_param.acnt_crowd_code  IS NULL )))
      AND (  ir_param.rcv_pay_div IS NULL )
      THEN
        -- オープン
        OPEN  get_cur01 FOR lv_select_main_start
                         || lv_select_g1_po102_2_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_po102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po101_2_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_po101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po112_2_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_po112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po103x5_2_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_po103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po103x124_2_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_po103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po105_2_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_po105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po108_2_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_po108
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om102_2_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_om102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om101_2_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_om101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om112_2_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_om112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om103x5_2_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_om103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om103x124_2_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_om103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om105_2_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_om105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om108_2_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_om108
                         || lv_where3
                         || lv_select_main_end
                         ;
        -- バルクフェッチ
        FETCH get_cur01 BULK COLLECT INTO ot_data_rec ;
        -- カーソルクローズ
        CLOSE get_cur01 ;
--
      --GROUP6
      --PTN03
      --品目区分          =  NULL
      --群(経理群)コード  <> NULL
      --受払区分          =  NULL
      ELSIF (ir_param.item_div    IS NULL ) 
      AND (((ir_param.crowd_type = gc_crowd_type_3) AND ( ir_param.crowd_code       IS NOT NULL )) OR
          (( ir_param.crowd_type = gc_crowd_type_4) AND ( ir_param.acnt_crowd_code  IS NOT NULL )))
      AND (  ir_param.rcv_pay_div IS NULL )
      THEN
        -- オープン
        OPEN  get_cur01 FOR lv_select_main_start
                         || lv_select_g1_po102_3_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_po102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po101_3_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_po101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po112_3_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_po112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po103x5_3_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_po103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po103x124_3_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_po103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po105_3_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_po105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po108_3_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_po108
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om102_3_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_om102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om101_3_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_om101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om112_3_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_om112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om103x5_3_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_om103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om103x124_3_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_om103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om105_3_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_om105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om108_3_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_om108
                         || lv_where3
                         || lv_select_main_end
                         ;
        -- バルクフェッチ
        FETCH get_cur01 BULK COLLECT INTO ot_data_rec ;
        -- カーソルクローズ
        CLOSE get_cur01 ;
--
      --GROUP6
      --PTN04
      --品目区分          =  NULL
      --群(経理群)コード  =  NULL
      --受払区分          <> NULL
      ELSIF (ir_param.item_div    IS NULL ) 
      AND (((ir_param.crowd_type = gc_crowd_type_3) AND ( ir_param.crowd_code       IS NULL )) OR
          (( ir_param.crowd_type = gc_crowd_type_4) AND ( ir_param.acnt_crowd_code  IS NULL )))
      AND (  ir_param.rcv_pay_div IS NOT NULL )
      THEN
        -- オープン
        OPEN  get_cur01 FOR lv_select_main_start
                         || lv_select_g1_po102_4_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_po102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po101_4_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_po101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po112_4_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_po112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po103x5_4_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_po103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po103x124_4_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_po103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po105_4_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_po105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po108_4_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_po108
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om102_4_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_om102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om101_4_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_om101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om112_4_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_om112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om103x5_4_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_om103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om103x124_4_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_om103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om105_4_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_om105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om108_4_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_om108
                         || lv_where3
                         || lv_select_main_end
                         ;
        -- バルクフェッチ
        FETCH get_cur01 BULK COLLECT INTO ot_data_rec ;
        -- カーソルクローズ
        CLOSE get_cur01 ;
--
      --GROUP6
      --PTN05
      --品目区分          <> NULL
      --群(経理群)コード  <> NULL
      --受払区分          =  NULL
      ELSIF (ir_param.item_div    IS NOT NULL ) 
      AND (((ir_param.crowd_type = gc_crowd_type_3) AND ( ir_param.crowd_code       IS NOT NULL )) OR
          (( ir_param.crowd_type = gc_crowd_type_4) AND ( ir_param.acnt_crowd_code  IS NOT NULL )))
      AND (  ir_param.rcv_pay_div IS NULL )
      THEN
        -- オープン
        OPEN  get_cur01 FOR lv_select_main_start
                         || lv_select_g1_po102_3_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_po102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po101_3_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_po101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po112_3_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_po112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po103x5_3_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_po103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po103x124_3_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_po103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po105_3_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_po105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po108_3_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_po108
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om102_3_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_om102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om101_3_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_om101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om112_3_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_om112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om103x5_3_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_om103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om103x124_3_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_om103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om105_3_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_om105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om108_3_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_om108
                         || lv_where3
                         || lv_select_main_end
                         ;
        -- バルクフェッチ
        FETCH get_cur01 BULK COLLECT INTO ot_data_rec ;
        -- カーソルクローズ
        CLOSE get_cur01 ;
--
      --GROUP6
      --PTN06
      --品目区分          =  NULL
      --群(経理群)コード  <> NULL
      --受払区分          <> NULL
      ELSIF (ir_param.item_div    IS NULL ) 
      AND (((ir_param.crowd_type = gc_crowd_type_3) AND ( ir_param.crowd_code       IS NOT NULL )) OR
          (( ir_param.crowd_type = gc_crowd_type_4) AND ( ir_param.acnt_crowd_code  IS NOT NULL )))
      AND (  ir_param.rcv_pay_div IS NOT NULL )
      THEN
        -- オープン
        OPEN  get_cur01 FOR lv_select_main_start
                         || lv_select_g1_po102_6_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_po102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po101_6_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_po101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po112_6_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_po112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po103x5_6_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_po103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po103x124_6_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_po103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po105_6_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_po105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po108_6_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_po108
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om102_6_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_om102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om101_6_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_om101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om112_6_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_om112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om103x5_6_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_om103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om103x124_6_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_om103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om105_6_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_om105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om108_6_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_om108
                         || lv_where3
                         || lv_select_main_end
                         ;
        -- バルクフェッチ
        FETCH get_cur01 BULK COLLECT INTO ot_data_rec ;
        -- カーソルクローズ
        CLOSE get_cur01 ;
--
      --GROUP6
      --PTN07
      --品目区分          <> NULL
      --群(経理群)コード  =  NULL
      --受払区分          <> NULL
      ELSIF (ir_param.item_div    IS NOT NULL ) 
      AND (((ir_param.crowd_type = gc_crowd_type_3) AND ( ir_param.crowd_code       IS NULL )) OR
          (( ir_param.crowd_type = gc_crowd_type_4) AND ( ir_param.acnt_crowd_code  IS NULL )))
      AND (  ir_param.rcv_pay_div IS NOT NULL )
      THEN
        -- オープン
        OPEN  get_cur01 FOR lv_select_main_start
                         || lv_select_g1_po102_4_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_po102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po101_4_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_po101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po112_4_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_po112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po103x5_4_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_po103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po103x124_4_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_po103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po105_4_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_po105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po108_4_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_po108
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om102_4_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_om102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om101_4_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_om101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om112_4_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_om112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om103x5_4_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_om103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om103x124_4_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_om103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om105_4_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_om105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om108_4_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_om108
                         || lv_where3
                         || lv_select_main_end
                         ;
        -- バルクフェッチ
        FETCH get_cur01 BULK COLLECT INTO ot_data_rec ;
        -- カーソルクローズ
        CLOSE get_cur01 ;
--
      --GROUP6
      --PTN08
      --品目区分          <> NULL
      --群(経理群)コード  <> NULL
      --受払区分          <> NULL
      ELSE
        -- オープン
        OPEN  get_cur01 FOR lv_select_main_start
                         || lv_select_g1_po102_6_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_po102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po101_6_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_po101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po112_6_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_po112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po103x5_6_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_po103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po103x124_6_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_po103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po105_6_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_po105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po108_6_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_po108
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om102_6_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_om102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om101_6_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_om101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om112_6_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_om112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om103x5_6_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_om103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om103x124_6_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_om103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om105_6_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_om105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om108_6_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_om108
                         || lv_where3
                         || lv_select_main_end
                         ;
        -- バルクフェッチ
        FETCH get_cur01 BULK COLLECT INTO ot_data_rec ;
        -- カーソルクローズ
        CLOSE get_cur01 ;
      END IF;
--
    -- 集計パターン７設定 (集計：1.品目区分、2.出荷先)
    ELSIF ( ir_param.result_post IS NOT NULL )
    AND   ( ir_param.whse_code   IS NOT NULL )
    AND   ( ir_param.party_code  IS NULL )
    THEN
--
      --GROUP7
      --PTN01
      --品目区分          =  NULL
      --群(経理群)コード  =  NULL
      --受払区分          =  NULL
      IF  (  ir_param.item_div    IS NULL ) 
      AND (((ir_param.crowd_type = gc_crowd_type_3) AND ( ir_param.crowd_code       IS NULL )) OR
          (( ir_param.crowd_type = gc_crowd_type_4) AND ( ir_param.acnt_crowd_code  IS NULL )))
      AND (  ir_param.rcv_pay_div IS NULL )
      THEN
        -- オープン
        OPEN  get_cur01 FOR lv_select_main_start
                         || lv_select_g1_po102_1_hint
                         || lv_select_common
                         || lv_select_group7
                         || lv_select_1_po102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po101_1_hint
                         || lv_select_common
                         || lv_select_group7
                         || lv_select_1_po101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po112_1_hint
                         || lv_select_common
                         || lv_select_group7
                         || lv_select_1_po112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po103x5_1_hint
                         || lv_select_common
                         || lv_select_group7_2
                         || lv_select_1_po103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po103x124_1_hint
                         || lv_select_common
                         || lv_select_group7_2
                         || lv_select_1_po103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po105_1_hint
                         || lv_select_common
                         || lv_select_group7_2
                         || lv_select_1_po105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po108_1_hint
                         || lv_select_common
                         || lv_select_group7_2
                         || lv_select_1_po108
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om102_1_hint
                         || lv_select_common
                         || lv_select_group7
                         || lv_select_1_om102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om101_1_hint
                         || lv_select_common
                         || lv_select_group7
                         || lv_select_1_om101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om112_1_hint
                         || lv_select_common
                         || lv_select_group7
                         || lv_select_1_om112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om103x5_1_hint
                         || lv_select_common
                         || lv_select_group7_2
                         || lv_select_1_om103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om103x124_1_hint
                         || lv_select_common
                         || lv_select_group7_2
                         || lv_select_1_om103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om105_1_hint
                         || lv_select_common
                         || lv_select_group7_2
                         || lv_select_1_om105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om108_1_hint
                         || lv_select_common
                         || lv_select_group7_2
                         || lv_select_1_om108
                         || lv_where3
                         || lv_select_main_end
                         ;
        -- バルクフェッチ
        FETCH get_cur01 BULK COLLECT INTO ot_data_rec ;
        -- カーソルクローズ
        CLOSE get_cur01 ;
--
      --GROUP7
      --PTN02
      --品目区分          <> NULL
      --群(経理群)コード  =  NULL
      --受払区分          =  NULL
      ELSIF (ir_param.item_div    IS NOT NULL ) 
      AND (((ir_param.crowd_type = gc_crowd_type_3) AND ( ir_param.crowd_code       IS NULL )) OR
          (( ir_param.crowd_type = gc_crowd_type_4) AND ( ir_param.acnt_crowd_code  IS NULL )))
      AND (  ir_param.rcv_pay_div IS NULL )
      THEN
        -- オープン
        OPEN  get_cur01 FOR lv_select_main_start
                         || lv_select_g1_po102_2_hint
                         || lv_select_common
                         || lv_select_group7
                         || lv_select_1_po102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po101_2_hint
                         || lv_select_common
                         || lv_select_group7
                         || lv_select_1_po101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po112_2_hint
                         || lv_select_common
                         || lv_select_group7
                         || lv_select_1_po112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po103x5_2_hint
                         || lv_select_common
                         || lv_select_group7_2
                         || lv_select_1_po103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po103x124_2_hint
                         || lv_select_common
                         || lv_select_group7_2
                         || lv_select_1_po103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po105_2_hint
                         || lv_select_common
                         || lv_select_group7_2
                         || lv_select_1_po105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po108_2_hint
                         || lv_select_common
                         || lv_select_group7_2
                         || lv_select_1_po108
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om102_2_hint
                         || lv_select_common
                         || lv_select_group7
                         || lv_select_1_om102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om101_2_hint
                         || lv_select_common
                         || lv_select_group7
                         || lv_select_1_om101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om112_2_hint
                         || lv_select_common
                         || lv_select_group7
                         || lv_select_1_om112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om103x5_2_hint
                         || lv_select_common
                         || lv_select_group7_2
                         || lv_select_1_om103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om103x124_2_hint
                         || lv_select_common
                         || lv_select_group7_2
                         || lv_select_1_om103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om105_2_hint
                         || lv_select_common
                         || lv_select_group7_2
                         || lv_select_1_om105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om108_2_hint
                         || lv_select_common
                         || lv_select_group7_2
                         || lv_select_1_om108
                         || lv_where3
                         || lv_select_main_end
                         ;
        -- バルクフェッチ
        FETCH get_cur01 BULK COLLECT INTO ot_data_rec ;
        -- カーソルクローズ
        CLOSE get_cur01 ;
--
      --GROUP7
      --PTN03
      --品目区分          =  NULL
      --群(経理群)コード  <> NULL
      --受払区分          =  NULL
      ELSIF (ir_param.item_div    IS NULL ) 
      AND (((ir_param.crowd_type = gc_crowd_type_3) AND ( ir_param.crowd_code       IS NOT NULL )) OR
          (( ir_param.crowd_type = gc_crowd_type_4) AND ( ir_param.acnt_crowd_code  IS NOT NULL )))
      AND (  ir_param.rcv_pay_div IS NULL )
      THEN
        -- オープン
        OPEN  get_cur01 FOR lv_select_main_start
                         || lv_select_g1_po102_3_hint
                         || lv_select_common
                         || lv_select_group7
                         || lv_select_1_po102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po101_3_hint
                         || lv_select_common
                         || lv_select_group7
                         || lv_select_1_po101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po112_3_hint
                         || lv_select_common
                         || lv_select_group7
                         || lv_select_1_po112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po103x5_3_hint
                         || lv_select_common
                         || lv_select_group7_2
                         || lv_select_1_po103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po103x124_3_hint
                         || lv_select_common
                         || lv_select_group7_2
                         || lv_select_1_po103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po105_3_hint
                         || lv_select_common
                         || lv_select_group7_2
                         || lv_select_1_po105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po108_3_hint
                         || lv_select_common
                         || lv_select_group7_2
                         || lv_select_1_po108
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om102_3_hint
                         || lv_select_common
                         || lv_select_group7
                         || lv_select_1_om102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om101_3_hint
                         || lv_select_common
                         || lv_select_group7
                         || lv_select_1_om101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om112_3_hint
                         || lv_select_common
                         || lv_select_group7
                         || lv_select_1_om112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om103x5_3_hint
                         || lv_select_common
                         || lv_select_group7_2
                         || lv_select_1_om103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om103x124_3_hint
                         || lv_select_common
                         || lv_select_group7_2
                         || lv_select_1_om103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om105_3_hint
                         || lv_select_common
                         || lv_select_group7_2
                         || lv_select_1_om105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om108_3_hint
                         || lv_select_common
                         || lv_select_group7_2
                         || lv_select_1_om108
                         || lv_where3
                         || lv_select_main_end
                         ;
        -- バルクフェッチ
        FETCH get_cur01 BULK COLLECT INTO ot_data_rec ;
        -- カーソルクローズ
        CLOSE get_cur01 ;
--
      --GROUP7
      --PTN04
      --品目区分          =  NULL
      --群(経理群)コード  =  NULL
      --受払区分          <> NULL
      ELSIF (ir_param.item_div    IS NULL ) 
      AND (((ir_param.crowd_type = gc_crowd_type_3) AND ( ir_param.crowd_code       IS NULL )) OR
          (( ir_param.crowd_type = gc_crowd_type_4) AND ( ir_param.acnt_crowd_code  IS NULL )))
      AND (  ir_param.rcv_pay_div IS NOT NULL )
      THEN
        -- オープン
        OPEN  get_cur01 FOR lv_select_main_start
                         || lv_select_g1_po102_4_hint
                         || lv_select_common
                         || lv_select_group7
                         || lv_select_1_po102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po101_4_hint
                         || lv_select_common
                         || lv_select_group7
                         || lv_select_1_po101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po112_4_hint
                         || lv_select_common
                         || lv_select_group7
                         || lv_select_1_po112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po103x5_4_hint
                         || lv_select_common
                         || lv_select_group7_2
                         || lv_select_1_po103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po103x124_4_hint
                         || lv_select_common
                         || lv_select_group7_2
                         || lv_select_1_po103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po105_4_hint
                         || lv_select_common
                         || lv_select_group7_2
                         || lv_select_1_po105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po108_4_hint
                         || lv_select_common
                         || lv_select_group7_2
                         || lv_select_1_po108
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om102_4_hint
                         || lv_select_common
                         || lv_select_group7
                         || lv_select_1_om102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om101_4_hint
                         || lv_select_common
                         || lv_select_group7
                         || lv_select_1_om101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om112_4_hint
                         || lv_select_common
                         || lv_select_group7
                         || lv_select_1_om112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om103x5_4_hint
                         || lv_select_common
                         || lv_select_group7_2
                         || lv_select_1_om103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om103x124_4_hint
                         || lv_select_common
                         || lv_select_group7_2
                         || lv_select_1_om103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om105_4_hint
                         || lv_select_common
                         || lv_select_group7_2
                         || lv_select_1_om105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om108_4_hint
                         || lv_select_common
                         || lv_select_group7_2
                         || lv_select_1_om108
                         || lv_where3
                         || lv_select_main_end
                         ;
        -- バルクフェッチ
        FETCH get_cur01 BULK COLLECT INTO ot_data_rec ;
        -- カーソルクローズ
        CLOSE get_cur01 ;
--
      --GROUP7
      --PTN05
      --品目区分          <> NULL
      --群(経理群)コード  <> NULL
      --受払区分          =  NULL
      ELSIF (ir_param.item_div    IS NOT NULL ) 
      AND (((ir_param.crowd_type = gc_crowd_type_3) AND ( ir_param.crowd_code       IS NOT NULL )) OR
          (( ir_param.crowd_type = gc_crowd_type_4) AND ( ir_param.acnt_crowd_code  IS NOT NULL )))
      AND (  ir_param.rcv_pay_div IS NULL )
      THEN
        -- オープン
        OPEN  get_cur01 FOR lv_select_main_start
                         || lv_select_g1_po102_3_hint
                         || lv_select_common
                         || lv_select_group7
                         || lv_select_1_po102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po101_3_hint
                         || lv_select_common
                         || lv_select_group7
                         || lv_select_1_po101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po112_3_hint
                         || lv_select_common
                         || lv_select_group7
                         || lv_select_1_po112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po103x5_3_hint
                         || lv_select_common
                         || lv_select_group7_2
                         || lv_select_1_po103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po103x124_3_hint
                         || lv_select_common
                         || lv_select_group7_2
                         || lv_select_1_po103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po105_3_hint
                         || lv_select_common
                         || lv_select_group7_2
                         || lv_select_1_po105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po108_3_hint
                         || lv_select_common
                         || lv_select_group7_2
                         || lv_select_1_po108
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om102_3_hint
                         || lv_select_common
                         || lv_select_group7
                         || lv_select_1_om102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om101_3_hint
                         || lv_select_common
                         || lv_select_group7
                         || lv_select_1_om101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om112_3_hint
                         || lv_select_common
                         || lv_select_group7
                         || lv_select_1_om112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om103x5_3_hint
                         || lv_select_common
                         || lv_select_group7_2
                         || lv_select_1_om103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om103x124_3_hint
                         || lv_select_common
                         || lv_select_group7_2
                         || lv_select_1_om103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om105_3_hint
                         || lv_select_common
                         || lv_select_group7_2
                         || lv_select_1_om105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om108_3_hint
                         || lv_select_common
                         || lv_select_group7_2
                         || lv_select_1_om108
                         || lv_where3
                         || lv_select_main_end
                         ;
        -- バルクフェッチ
        FETCH get_cur01 BULK COLLECT INTO ot_data_rec ;
        -- カーソルクローズ
        CLOSE get_cur01 ;
--
      --GROUP7
      --PTN06
      --品目区分          =  NULL
      --群(経理群)コード  <> NULL
      --受払区分          <> NULL
      ELSIF (ir_param.item_div    IS NULL ) 
      AND (((ir_param.crowd_type = gc_crowd_type_3) AND ( ir_param.crowd_code       IS NOT NULL )) OR
          (( ir_param.crowd_type = gc_crowd_type_4) AND ( ir_param.acnt_crowd_code  IS NOT NULL )))
      AND (  ir_param.rcv_pay_div IS NOT NULL )
      THEN
        -- オープン
        OPEN  get_cur01 FOR lv_select_main_start
                         || lv_select_g1_po102_6_hint
                         || lv_select_common
                         || lv_select_group7
                         || lv_select_1_po102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po101_6_hint
                         || lv_select_common
                         || lv_select_group7
                         || lv_select_1_po101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po112_6_hint
                         || lv_select_common
                         || lv_select_group7
                         || lv_select_1_po112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po103x5_6_hint
                         || lv_select_common
                         || lv_select_group7_2
                         || lv_select_1_po103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po103x124_6_hint
                         || lv_select_common
                         || lv_select_group7_2
                         || lv_select_1_po103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po105_6_hint
                         || lv_select_common
                         || lv_select_group7_2
                         || lv_select_1_po105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po108_6_hint
                         || lv_select_common
                         || lv_select_group7_2
                         || lv_select_1_po108
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om102_6_hint
                         || lv_select_common
                         || lv_select_group7
                         || lv_select_1_om102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om101_6_hint
                         || lv_select_common
                         || lv_select_group7
                         || lv_select_1_om101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om112_6_hint
                         || lv_select_common
                         || lv_select_group7
                         || lv_select_1_om112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om103x5_6_hint
                         || lv_select_common
                         || lv_select_group7_2
                         || lv_select_1_om103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om103x124_6_hint
                         || lv_select_common
                         || lv_select_group7_2
                         || lv_select_1_om103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om105_6_hint
                         || lv_select_common
                         || lv_select_group7_2
                         || lv_select_1_om105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om108_6_hint
                         || lv_select_common
                         || lv_select_group7_2
                         || lv_select_1_om108
                         || lv_where3
                         || lv_select_main_end
                         ;
        -- バルクフェッチ
        FETCH get_cur01 BULK COLLECT INTO ot_data_rec ;
        -- カーソルクローズ
        CLOSE get_cur01 ;
--
      --GROUP7
      --PTN07
      --品目区分          <> NULL
      --群(経理群)コード  =  NULL
      --受払区分          <> NULL
      ELSIF (ir_param.item_div    IS NOT NULL ) 
      AND (((ir_param.crowd_type = gc_crowd_type_3) AND ( ir_param.crowd_code       IS NULL )) OR
          (( ir_param.crowd_type = gc_crowd_type_4) AND ( ir_param.acnt_crowd_code  IS NULL )))
      AND (  ir_param.rcv_pay_div IS NOT NULL )
      THEN
        -- オープン
        OPEN  get_cur01 FOR lv_select_main_start
                         || lv_select_g1_po102_4_hint
                         || lv_select_common
                         || lv_select_group7
                         || lv_select_1_po102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po101_4_hint
                         || lv_select_common
                         || lv_select_group7
                         || lv_select_1_po101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po112_4_hint
                         || lv_select_common
                         || lv_select_group7
                         || lv_select_1_po112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po103x5_4_hint
                         || lv_select_common
                         || lv_select_group7_2
                         || lv_select_1_po103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po103x124_4_hint
                         || lv_select_common
                         || lv_select_group7_2
                         || lv_select_1_po103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po105_4_hint
                         || lv_select_common
                         || lv_select_group7_2
                         || lv_select_1_po105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po108_4_hint
                         || lv_select_common
                         || lv_select_group7_2
                         || lv_select_1_po108
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om102_4_hint
                         || lv_select_common
                         || lv_select_group7
                         || lv_select_1_om102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om101_4_hint
                         || lv_select_common
                         || lv_select_group7
                         || lv_select_1_om101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om112_4_hint
                         || lv_select_common
                         || lv_select_group7
                         || lv_select_1_om112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om103x5_4_hint
                         || lv_select_common
                         || lv_select_group7_2
                         || lv_select_1_om103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om103x124_4_hint
                         || lv_select_common
                         || lv_select_group7_2
                         || lv_select_1_om103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om105_4_hint
                         || lv_select_common
                         || lv_select_group7_2
                         || lv_select_1_om105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om108_4_hint
                         || lv_select_common
                         || lv_select_group7_2
                         || lv_select_1_om108
                         || lv_where3
                         || lv_select_main_end
                         ;
        -- バルクフェッチ
        FETCH get_cur01 BULK COLLECT INTO ot_data_rec ;
        -- カーソルクローズ
        CLOSE get_cur01 ;
--
      --GROUP7
      --PTN08
      --品目区分          <> NULL
      --群(経理群)コード  <> NULL
      --受払区分          <> NULL
      ELSE
        -- オープン
        OPEN  get_cur01 FOR lv_select_main_start
                         || lv_select_g1_po102_6_hint
                         || lv_select_common
                         || lv_select_group7
                         || lv_select_1_po102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po101_6_hint
                         || lv_select_common
                         || lv_select_group7
                         || lv_select_1_po101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po112_6_hint
                         || lv_select_common
                         || lv_select_group7
                         || lv_select_1_po112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po103x5_6_hint
                         || lv_select_common
                         || lv_select_group7_2
                         || lv_select_1_po103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po103x124_6_hint
                         || lv_select_common
                         || lv_select_group7_2
                         || lv_select_1_po103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po105_6_hint
                         || lv_select_common
                         || lv_select_group7_2
                         || lv_select_1_po105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po108_6_hint
                         || lv_select_common
                         || lv_select_group7_2
                         || lv_select_1_po108
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om102_6_hint
                         || lv_select_common
                         || lv_select_group7
                         || lv_select_1_om102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om101_6_hint
                         || lv_select_common
                         || lv_select_group7
                         || lv_select_1_om101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om112_6_hint
                         || lv_select_common
                         || lv_select_group7
                         || lv_select_1_om112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om103x5_6_hint
                         || lv_select_common
                         || lv_select_group7_2
                         || lv_select_1_om103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om103x124_6_hint
                         || lv_select_common
                         || lv_select_group7_2
                         || lv_select_1_om103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om105_6_hint
                         || lv_select_common
                         || lv_select_group7_2
                         || lv_select_1_om105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om108_6_hint
                         || lv_select_common
                         || lv_select_group7_2
                         || lv_select_1_om108
                         || lv_where3
                         || lv_select_main_end
                         ;
        -- バルクフェッチ
        FETCH get_cur01 BULK COLLECT INTO ot_data_rec ;
        -- カーソルクローズ
        CLOSE get_cur01 ;
      END IF;
--
    -- 集計パターン８設定 (集計：1.品目区分)
    ELSIF ( ir_param.result_post IS NOT NULL )
    AND   ( ir_param.whse_code   IS NOT NULL )
    AND   ( ir_param.party_code  IS NOT NULL )
    THEN
--
      --GROUP8
      --PTN01
      --品目区分          =  NULL
      --群(経理群)コード  =  NULL
      --受払区分          =  NULL
      IF  (  ir_param.item_div    IS NULL ) 
      AND (((ir_param.crowd_type = gc_crowd_type_3) AND ( ir_param.crowd_code       IS NULL )) OR
          (( ir_param.crowd_type = gc_crowd_type_4) AND ( ir_param.acnt_crowd_code  IS NULL )))
      AND (  ir_param.rcv_pay_div IS NULL )
      THEN
        -- オープン
        OPEN  get_cur01 FOR lv_select_main_start
                         || lv_select_g1_po102_1_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_po102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po101_1_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_po101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po112_1_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_po112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po103x5_1_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_po103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po103x124_1_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_po103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po105_1_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_po105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po108_1_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_po108
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om102_1_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_om102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om101_1_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_om101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om112_1_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_om112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om103x5_1_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_om103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om103x124_1_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_om103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om105_1_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_om105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om108_1_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_om108
                         || lv_where3
                         || lv_select_main_end
                         ;
        -- バルクフェッチ
        FETCH get_cur01 BULK COLLECT INTO ot_data_rec ;
        -- カーソルクローズ
        CLOSE get_cur01 ;
--
      --GROUP8
      --PTN02
      --品目区分          <> NULL
      --群(経理群)コード  =  NULL
      --受払区分          =  NULL
      ELSIF (ir_param.item_div    IS NOT NULL ) 
      AND (((ir_param.crowd_type = gc_crowd_type_3) AND ( ir_param.crowd_code       IS NULL )) OR
          (( ir_param.crowd_type = gc_crowd_type_4) AND ( ir_param.acnt_crowd_code  IS NULL )))
      AND (  ir_param.rcv_pay_div IS NULL )
      THEN
        -- オープン
        OPEN  get_cur01 FOR lv_select_main_start
                         || lv_select_g1_po102_2_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_po102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po101_2_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_po101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po112_2_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_po112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po103x5_2_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_po103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po103x124_2_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_po103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po105_2_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_po105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po108_2_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_po108
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om102_2_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_om102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om101_2_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_om101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om112_2_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_om112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om103x5_2_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_om103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om103x124_2_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_om103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om105_2_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_om105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om108_2_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_om108
                         || lv_where3
                         || lv_select_main_end
                         ;
        -- バルクフェッチ
        FETCH get_cur01 BULK COLLECT INTO ot_data_rec ;
        -- カーソルクローズ
        CLOSE get_cur01 ;
--
      --GROUP8
      --PTN03
      --品目区分          =  NULL
      --群(経理群)コード  <> NULL
      --受払区分          =  NULL
      ELSIF (ir_param.item_div    IS NULL ) 
      AND (((ir_param.crowd_type = gc_crowd_type_3) AND ( ir_param.crowd_code       IS NOT NULL )) OR
          (( ir_param.crowd_type = gc_crowd_type_4) AND ( ir_param.acnt_crowd_code  IS NOT NULL )))
      AND (  ir_param.rcv_pay_div IS NULL )
      THEN
        -- オープン
        OPEN  get_cur01 FOR lv_select_main_start
                         || lv_select_g1_po102_3_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_po102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po101_3_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_po101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po112_3_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_po112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po103x5_3_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_po103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po103x124_3_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_po103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po105_3_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_po105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po108_3_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_po108
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om102_3_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_om102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om101_3_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_om101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om112_3_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_om112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om103x5_3_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_om103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om103x124_3_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_om103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om105_3_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_om105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om108_3_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_om108
                         || lv_where3
                         || lv_select_main_end
                         ;
        -- バルクフェッチ
        FETCH get_cur01 BULK COLLECT INTO ot_data_rec ;
        -- カーソルクローズ
        CLOSE get_cur01 ;
--
      --GROUP8
      --PTN04
      --品目区分          =  NULL
      --群(経理群)コード  =  NULL
      --受払区分          <> NULL
      ELSIF (ir_param.item_div    IS NULL ) 
      AND (((ir_param.crowd_type = gc_crowd_type_3) AND ( ir_param.crowd_code       IS NULL )) OR
          (( ir_param.crowd_type = gc_crowd_type_4) AND ( ir_param.acnt_crowd_code  IS NULL )))
      AND (  ir_param.rcv_pay_div IS NOT NULL )
      THEN
        -- オープン
        OPEN  get_cur01 FOR lv_select_main_start
                         || lv_select_g1_po102_4_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_po102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po101_4_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_po101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po112_4_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_po112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po103x5_4_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_po103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po103x124_4_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_po103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po105_4_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_po105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po108_4_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_po108
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om102_4_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_om102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om101_4_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_om101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om112_4_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_om112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om103x5_4_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_om103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om103x124_4_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_om103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om105_4_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_om105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om108_4_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_om108
                         || lv_where3
                         || lv_select_main_end
                         ;
        -- バルクフェッチ
        FETCH get_cur01 BULK COLLECT INTO ot_data_rec ;
        -- カーソルクローズ
        CLOSE get_cur01 ;
--
      --GROUP8
      --PTN05
      --品目区分          <> NULL
      --群(経理群)コード  <> NULL
      --受払区分          =  NULL
      ELSIF (ir_param.item_div    IS NOT NULL ) 
      AND (((ir_param.crowd_type = gc_crowd_type_3) AND ( ir_param.crowd_code       IS NOT NULL )) OR
          (( ir_param.crowd_type = gc_crowd_type_4) AND ( ir_param.acnt_crowd_code  IS NOT NULL )))
      AND (  ir_param.rcv_pay_div IS NULL )
      THEN
        -- オープン
        OPEN  get_cur01 FOR lv_select_main_start
                         || lv_select_g1_po102_3_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_po102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po101_3_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_po101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po112_3_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_po112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po103x5_3_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_po103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po103x124_3_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_po103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po105_3_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_po105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po108_3_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_po108
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om102_3_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_om102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om101_3_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_om101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om112_3_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_om112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om103x5_3_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_om103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om103x124_3_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_om103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om105_3_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_om105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om108_3_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_om108
                         || lv_where3
                         || lv_select_main_end
                         ;
        -- バルクフェッチ
        FETCH get_cur01 BULK COLLECT INTO ot_data_rec ;
        -- カーソルクローズ
        CLOSE get_cur01 ;
--
      --GROUP8
      --PTN06
      --品目区分          =  NULL
      --群(経理群)コード  <> NULL
      --受払区分          <> NULL
      ELSIF (ir_param.item_div    IS NULL ) 
      AND (((ir_param.crowd_type = gc_crowd_type_3) AND ( ir_param.crowd_code       IS NOT NULL )) OR
          (( ir_param.crowd_type = gc_crowd_type_4) AND ( ir_param.acnt_crowd_code  IS NOT NULL )))
      AND (  ir_param.rcv_pay_div IS NOT NULL )
      THEN
        -- オープン
        OPEN  get_cur01 FOR lv_select_main_start
                         || lv_select_g1_po102_6_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_po102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po101_6_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_po101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po112_6_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_po112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po103x5_6_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_po103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po103x124_6_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_po103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po105_6_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_po105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po108_6_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_po108
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om102_6_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_om102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om101_6_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_om101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om112_6_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_om112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om103x5_6_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_om103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om103x124_6_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_om103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om105_6_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_om105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om108_6_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_om108
                         || lv_where3
                         || lv_select_main_end
                         ;
        -- バルクフェッチ
        FETCH get_cur01 BULK COLLECT INTO ot_data_rec ;
        -- カーソルクローズ
        CLOSE get_cur01 ;
--
      --GROUP8
      --PTN07
      --品目区分          <> NULL
      --群(経理群)コード  =  NULL
      --受払区分          <> NULL
      ELSIF (ir_param.item_div    IS NOT NULL ) 
      AND (((ir_param.crowd_type = gc_crowd_type_3) AND ( ir_param.crowd_code       IS NULL )) OR
          (( ir_param.crowd_type = gc_crowd_type_4) AND ( ir_param.acnt_crowd_code  IS NULL )))
      AND (  ir_param.rcv_pay_div IS NOT NULL )
      THEN
        -- オープン
        OPEN  get_cur01 FOR lv_select_main_start
                         || lv_select_g1_po102_4_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_po102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po101_4_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_po101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po112_4_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_po112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po103x5_4_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_po103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po103x124_4_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_po103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po105_4_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_po105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po108_4_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_po108
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om102_4_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_om102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om101_4_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_om101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om112_4_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_om112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om103x5_4_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_om103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om103x124_4_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_om103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om105_4_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_om105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om108_4_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_om108
                         || lv_where3
                         || lv_select_main_end
                         ;
        -- バルクフェッチ
        FETCH get_cur01 BULK COLLECT INTO ot_data_rec ;
        -- カーソルクローズ
        CLOSE get_cur01 ;
--
      --GROUP8
      --PTN08
      --品目区分          <> NULL
      --群(経理群)コード  <> NULL
      --受払区分          <> NULL
      ELSE
        -- オープン
        OPEN  get_cur01 FOR lv_select_main_start
                         || lv_select_g1_po102_6_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_po102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po101_6_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_po101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po112_6_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_po112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po103x5_6_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_po103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po103x124_6_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_po103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po105_6_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_po105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po108_6_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_po108
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om102_6_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_om102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om101_6_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_om101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om112_6_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_om112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om103x5_6_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_om103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om103x124_6_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_om103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om105_6_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_om105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om108_6_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_om108
                         || lv_where3
                         || lv_select_main_end
                         ;
        -- バルクフェッチ
        FETCH get_cur01 BULK COLLECT INTO ot_data_rec ;
        -- カーソルクローズ
        CLOSE get_cur01 ;
      END IF;

--
    END IF;
--
-- 2008/10/24 v1.10 ADD END
--
  EXCEPTION
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      IF (lc_ref%ISOPEN) THEN
        CLOSE lc_ref ;
      END IF ;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      IF (lc_ref%ISOPEN) THEN
        CLOSE lc_ref ;
      END IF ;
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      IF (lc_ref%ISOPEN) THEN
        CLOSE lc_ref ;
      END IF ;
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END prc_get_report_data ;
--
  /**********************************************************************************
   * Procedure Name   : prc_create_xml_data
   * Description      : ＸＭＬデータ作成(F-2)
   ***********************************************************************************/
  PROCEDURE prc_create_xml_data (
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
    -- *** ローカル定数 ***
    -- キーブレイク判断用
    lc_break_init         VARCHAR2(100) DEFAULT '#' ;            -- 初期値
    lc_break_null         VARCHAR2(100) DEFAULT '*' ;            -- ＮＵＬＬ判定
--
    -- *** ローカル変数 ***
    -- キーブレイク判断用
-- 2008/10/24 v1.10 ADD START
    --lv_gp_cd1             VARCHAR2(5)   DEFAULT lc_break_init ;              -- 集計グループ１
    --lv_gp_cd2             VARCHAR2(5)   DEFAULT lc_break_init ;              -- 集計グループ２
    --lv_gp_cd3             VARCHAR2(5)   DEFAULT lc_break_init ;              -- 集計グループ３
    --lv_gp_cd4             VARCHAR2(5)   DEFAULT lc_break_init ;              -- 集計グループ４
    lv_gp_cd1             VARCHAR2(10)   DEFAULT lc_break_init ;              -- 集計グループ１
    lv_gp_cd2             VARCHAR2(10)   DEFAULT lc_break_init ;              -- 集計グループ２
    lv_gp_cd3             VARCHAR2(10)   DEFAULT lc_break_init ;              -- 集計グループ３
    lv_gp_cd4             VARCHAR2(10)   DEFAULT lc_break_init ;              -- 集計グループ４
-- 2008/10/24 v1.10 ADD END
    lv_crowd_l            VARCHAR2(1)   DEFAULT lc_break_init ;              -- 大郡計グループ
    lv_crowd_m            VARCHAR2(2)   DEFAULT lc_break_init ;              -- 中郡計グループ
    lv_crowd_s            VARCHAR2(3)   DEFAULT lc_break_init ;              -- 小郡計グループ
    lv_crowd_cd           VARCHAR2(4)   DEFAULT lc_break_init ;              -- 詳郡計グループ
--
    -- 計算用
    ln_position           NUMBER        DEFAULT 0;               -- 計算用：ポジション
    ln_i                  NUMBER        DEFAULT 0;               -- カウンター用
    lv_trans_qty          NUMBER ;                               -- 取引数量
    lv_tax                NUMBER ;                               -- 消費税率
    lv_tax_price          NUMBER ;                               -- 消費税
    ln_unit_price1        NUMBER ;                               -- 標準原価
    ln_unit_price2        NUMBER ;                               -- 有償原価
    ln_unit_price3        NUMBER ;                               -- 実際単価
    ln_unit_price4        NUMBER ;                               -- 有－標（原価）
    ln_unit_price5        NUMBER ;                               -- 有－実（原価）
    ln_unit_price6        NUMBER ;                               -- 標－実（原価）
    lv_price1             NUMBER ;                               -- 標準金額
    lv_price2             NUMBER ;                               -- 有償金額
    lv_price3             NUMBER ;                               -- 実際金額
    lv_price4             NUMBER ;                               -- 有－標（金額）
    lv_price5             NUMBER ;                               -- 有－実（金額）
    lv_price6             NUMBER ;                               -- 標－実（金額）
--
    -- *** ローカル・例外処理 ***
    no_data_expt            EXCEPTION ;             -- 取得レコードなし
--
    -- *** ローカル関数 ***
    ----------------------
    --1.ＸＭＬ 1行出力   -
    ----------------------
    PROCEDURE prc_xml_add(
       iv_name    IN   VARCHAR2                 --   タグネーム
      ,ic_type    IN   CHAR                     --   タグタイプ
      ,iv_data    IN   VARCHAR2 DEFAULT NULL)   --   データ
    IS
    BEGIN
      gl_xml_idx := gt_xml_data_table.COUNT + 1;
      gt_xml_data_table(gl_xml_idx).tag_name  := iv_name;
      --データの場合
      IF (ic_type = 'D') THEN
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
        gt_xml_data_table(gl_xml_idx).tag_value := iv_data;
      ELSE
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
      END IF;
    END prc_xml_add;
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
       ,ot_data_rec   => gt_main_data   -- 02.取得レコード群
       ,ov_errbuf     => lv_errbuf      --    エラー・メッセージ           --# 固定 #
       ,ov_retcode    => lv_retcode     --    リターン・コード             --# 固定 #
       ,ov_errmsg     => lv_errmsg      --    ユーザー・エラー・メッセージ --# 固定 #
      ) ;
    IF ( lv_retcode = gv_status_error ) THEN
      RAISE global_api_expt ;
--
    -- 取得データが０件の場合
    ELSIF ( gt_main_data.COUNT = 0 ) THEN
      RAISE no_data_expt ;
--
    END IF ;
--
    -- =====================================================
    -- ＜ヘッダ部＞項目データ抽出・出力処理
    -- =====================================================
--
    -- -----------------------------------------------------
    -- [USER_INFO] データ出力
    -- -----------------------------------------------------
    prc_xml_add('user_info', 'T', NULL);
--
    prc_xml_add('exec_date',          'D', TO_CHAR(gd_exec_date, gc_char_dt_format) ); -- 実施日
    prc_xml_add('report_id',          'D', gv_report_id);                    -- 帳票ＩＤ
    prc_xml_add('exec_user_dept',     'D', SUBSTRB(gv_user_dept,1,10) );     -- 担当部署
    prc_xml_add('exec_user_name',     'D', SUBSTRB(gv_user_name,1,14) );     -- 担当者名
    -- パラメータ
    prc_xml_add('p_item_div_code',    'D', ir_param.prod_div );              -- 商品区分
    prc_xml_add('p_item_div_name',    'D', ir_param.prod_div_name );         -- 商品区分名
    prc_xml_add('p_party_code',       'D', ir_param.party_code );            -- 出荷先コード
    prc_xml_add('p_party_name',       'D', ir_param.party_name );            -- 出荷先名
    prc_xml_add('p_locat_code',       'D', ir_param.whse_code );             -- 倉庫コード
    prc_xml_add('p_locat_name',       'D', ir_param.whse_name );             -- 倉庫名
    prc_xml_add('p_rcv_pay_div_code', 'D', ir_param.rcv_pay_div );           -- 受払区分
    prc_xml_add('p_rcv_pay_div_name', 'D', ir_param.rcv_pay_div_name );      -- 受払区分名
    prc_xml_add('p_article_div_code', 'D', ir_param.item_div );              -- 品目区分
    prc_xml_add('p_article_div_name', 'D', ir_param.item_div_name );         -- 品目区分名
    prc_xml_add('p_result_post_code', 'D', ir_param.result_post );           -- 成績部署
    prc_xml_add('p_result_post_name', 'D', ir_param.result_post_name );      -- 成績部署名
    -- 処理年月(自)
    prc_xml_add('p_trans_ym_from','D', SUBSTRB(ir_param.proc_from,1,4) || '年'
                                    || SUBSTRB(ir_param.proc_from,5,2) || '月' );
    -- 処理年月(至)
    prc_xml_add('p_trans_ym_to',  'D', SUBSTRB(ir_param.proc_to,1,4) || '年'
                                    || SUBSTRB(ir_param.proc_to,5,2) || '月' );
--
    prc_xml_add('/user_info', 'T', NULL);
--
    -- =====================================================
    -- ＜明細部＞項目データ抽出・出力処理
    -- =====================================================
    ln_i := 1;
    -- -----------------------------------------------------
    -- [DATA_INFO] 開始タグ出力
    -- -----------------------------------------------------
    prc_xml_add('data_info', 'T');
    prc_xml_add('lg_gr1',    'T');
--
    --=============================================集計１ループ開始
    <<group1_loop>>
    WHILE ( ln_i  <= gt_main_data.COUNT )
    LOOP
      prc_xml_add('g_gr1', 'T');
      prc_xml_add('gr1_code',     'D', gt_main_data(ln_i).group1_code);
-- 2008/12/13 v1.16 UPDATE START
--      prc_xml_add('gr1_sum_desc', 'D', gv_gr1_sum_desc);
      prc_xml_add('gr1_sum_desc', 'D', gt_main_data(ln_i).group1_name);
-- 2008/12/13 v1.16 UPDATE END
      lv_gp_cd1  :=  NVL(gt_main_data(ln_i).group1_code, lc_break_null);
      --=============================================集計２ループ開始
      prc_xml_add('lg_gr2', 'T');
      <<group2_loop>>
      WHILE ( ln_i  <= gt_main_data.COUNT )
        AND ( NVL(gt_main_data(ln_i).group1_code, lc_break_null) = lv_gp_cd1)
      LOOP
        prc_xml_add('g_gr2', 'T');
        prc_xml_add('gr2_code',     'D', gt_main_data(ln_i).group2_code);
-- 2008/12/13 v1.16 UPDATE START
--        prc_xml_add('gr2_sum_desc', 'D', gv_gr2_sum_desc);
        prc_xml_add('gr2_sum_desc', 'D', gt_main_data(ln_i).group2_name);
-- 2008/12/13 v1.16 UPDATE END
        lv_gp_cd2  :=  NVL(gt_main_data(ln_i).group2_code, lc_break_null);
        --===============================================集計３ループ開始
        prc_xml_add('lg_gr3', 'T');
        <<group3_loop>>
        WHILE ( ln_i  <= gt_main_data.COUNT )
          AND ( NVL(gt_main_data(ln_i).group1_code, lc_break_null) = lv_gp_cd1)
          AND ( NVL(gt_main_data(ln_i).group2_code, lc_break_null) = lv_gp_cd2)
        LOOP
          prc_xml_add('g_gr3', 'T');
          prc_xml_add('gr3_code',     'D', gt_main_data(ln_i).group3_code);
-- 2008/12/13 v1.16 UPDATE START
--          prc_xml_add('gr3_sum_desc', 'D', gv_gr3_sum_desc);
          prc_xml_add('gr3_sum_desc', 'D', gt_main_data(ln_i).group3_name);
-- 2008/12/13 v1.16 UPDATE END
          lv_gp_cd3  :=  NVL(gt_main_data(ln_i).group3_code, lc_break_null);
          --================================================集計４ループ開始
          prc_xml_add('lg_gr4', 'T');
          <<group4_loop>>
          WHILE ( ln_i  <= gt_main_data.COUNT )
            AND ( NVL(gt_main_data(ln_i).group1_code, lc_break_null) = lv_gp_cd1)
            AND ( NVL(gt_main_data(ln_i).group2_code, lc_break_null) = lv_gp_cd2)
            AND ( NVL(gt_main_data(ln_i).group3_code, lc_break_null) = lv_gp_cd3)
          LOOP
            prc_xml_add('g_gr4', 'T');
            prc_xml_add('gr4_code',     'D', gt_main_data(ln_i).group4_code);
-- 2008/12/13 v1.16 UPDATE START
--            prc_xml_add('gr4_sum_desc', 'D', gv_gr4_sum_desc);
            prc_xml_add('gr4_sum_desc', 'D', gt_main_data(ln_i).group4_name);
-- 2008/12/13 v1.16 UPDATE END
            lv_gp_cd4  :=  NVL(gt_main_data(ln_i).group4_code, lc_break_null);
            --================================================大郡計ループ開始
            prc_xml_add('lg_crowd_l', 'T');
            <<crowd_l_loop>>
            WHILE ( ln_i  <= gt_main_data.COUNT )
              AND ( NVL(gt_main_data(ln_i).group1_code, lc_break_null) = lv_gp_cd1)
              AND ( NVL(gt_main_data(ln_i).group2_code, lc_break_null) = lv_gp_cd2)
              AND ( NVL(gt_main_data(ln_i).group3_code, lc_break_null) = lv_gp_cd3)
              AND ( NVL(gt_main_data(ln_i).group4_code, lc_break_null) = lv_gp_cd4)
            LOOP
              prc_xml_add('g_crowd_l', 'T');
              prc_xml_add('crowd_lcode', 'D', SUBSTRB(gt_main_data(ln_i).group5_code,1,1) );
              lv_crowd_l  :=  NVL(SUBSTRB(gt_main_data(ln_i).group5_code,1,1), lc_break_null);
              --================================================中郡計ループ開始
              prc_xml_add('lg_crowd_m', 'T');
              <<crowd_m_loop>>
              WHILE ( ln_i  <= gt_main_data.COUNT )
                AND ( NVL(gt_main_data(ln_i).group1_code, lc_break_null) = lv_gp_cd1)
                AND ( NVL(gt_main_data(ln_i).group2_code, lc_break_null) = lv_gp_cd2)
                AND ( NVL(gt_main_data(ln_i).group3_code, lc_break_null) = lv_gp_cd3)
                AND ( NVL(gt_main_data(ln_i).group4_code, lc_break_null) = lv_gp_cd4)
                AND ( NVL(SUBSTRB(gt_main_data(ln_i).group5_code,1,1),lc_break_null)= lv_crowd_l)
              LOOP
                prc_xml_add('g_crowd_m', 'T');
                prc_xml_add('crowd_mcode', 'D', SUBSTRB(gt_main_data(ln_i).group5_code,1,2) );
                lv_crowd_m  :=  NVL(SUBSTRB(gt_main_data(ln_i).group5_code,1,2), lc_break_null);
                --================================================小郡計ループ開始
                prc_xml_add('lg_crowd_s', 'T');
                <<crowd_s_loop>>
                WHILE ( ln_i  <= gt_main_data.COUNT )
                  AND ( NVL(gt_main_data(ln_i).group1_code, lc_break_null) = lv_gp_cd1)
                  AND ( NVL(gt_main_data(ln_i).group2_code, lc_break_null) = lv_gp_cd2)
                  AND ( NVL(gt_main_data(ln_i).group3_code, lc_break_null) = lv_gp_cd3)
                  AND ( NVL(gt_main_data(ln_i).group4_code, lc_break_null) = lv_gp_cd4)
                  AND ( NVL(SUBSTRB(gt_main_data(ln_i).group5_code,1,2),lc_break_null)
                                                                           = lv_crowd_m)
                LOOP
                  prc_xml_add('g_crowd_s', 'T');
                  prc_xml_add('crowd_scode', 'D', SUBSTRB(gt_main_data(ln_i).group5_code,1,3) );
                  lv_crowd_s := NVL(SUBSTRB(gt_main_data(ln_i).group5_code,1,3), lc_break_null);
                  --================================================詳郡計ループ開始
                  prc_xml_add('lg_crowd', 'T');
                  <<crowd_loop>>
                  WHILE ( ln_i  <= gt_main_data.COUNT )
                    AND ( NVL(gt_main_data(ln_i).group1_code, lc_break_null) = lv_gp_cd1)
                    AND ( NVL(gt_main_data(ln_i).group2_code, lc_break_null) = lv_gp_cd2)
                    AND ( NVL(gt_main_data(ln_i).group3_code, lc_break_null) = lv_gp_cd3)
                    AND ( NVL(gt_main_data(ln_i).group4_code, lc_break_null) = lv_gp_cd4)
                    AND ( NVL(SUBSTRB(gt_main_data(ln_i).group5_code,1,3),lc_break_null)
                                                                             = lv_crowd_s)
                  LOOP
                    prc_xml_add('g_crowd', 'T');
                    prc_xml_add('crowd_code', 'D', gt_main_data(ln_i).group5_code );
                    --================================================品目ループ開始
                    lv_crowd_cd := NVL(gt_main_data(ln_i).group5_code, lc_break_null);
                    prc_xml_add('lg_item', 'T');
                    <<item_loop>>
                    WHILE ( ln_i  <= gt_main_data.COUNT )
                      AND ( NVL(gt_main_data(ln_i).group1_code, lc_break_null) = lv_gp_cd1)
                      AND ( NVL(gt_main_data(ln_i).group2_code, lc_break_null) = lv_gp_cd2)
                      AND ( NVL(gt_main_data(ln_i).group3_code, lc_break_null) = lv_gp_cd3)
                      AND ( NVL(gt_main_data(ln_i).group4_code, lc_break_null) = lv_gp_cd4)
                      AND ( NVL(gt_main_data(ln_i).group5_code, lc_break_null) = lv_crowd_cd)
                    LOOP
                      prc_xml_add('g_item', 'T');
--
                      -- -----------------------------------------------------
                      -- 初期化
                      -- -----------------------------------------------------
                      lv_trans_qty   := NULL;    -- 取引数量
                      lv_tax         := NULL;    -- 消費税率
                      lv_tax_price   := NULL;    -- 消費税
                      ln_unit_price1 := NULL;    -- 標準原価
                      ln_unit_price2 := NULL;    -- 有償原価
                      ln_unit_price3 := NULL;    -- 実際単価
                      ln_unit_price4 := NULL;    -- 有－標（原価）
                      ln_unit_price5 := NULL;    -- 有－実（原価）
                      ln_unit_price6 := NULL;    -- 標－実（原価）
                      lv_price1      := NULL;    -- 標準金額
                      lv_price2      := NULL;    -- 有償金額
                      lv_price3      := NULL;    -- 実際金額
                      lv_price4      := NULL;    -- 有－標（金額）
                      lv_price5      := NULL;    -- 有－実（金額）
                      lv_price6      := NULL;    -- 標－実（金額）
--
                      -- -----------------------------------------------------
                      -- 算出処理＋まるめ処理
                      -- -----------------------------------------------------
                      -- 数量
                      IF  ( NVL(gt_main_data(ln_i).trans_qty,0) != 0 ) THEN
                        lv_trans_qty     := ROUND(gt_main_data(ln_i).trans_qty, 3);
                      END IF;
                      -- 標準金額
                      IF  ( NVL(gt_main_data(ln_i).stnd_price,0) != 0 ) THEN
                        lv_price1        := ROUND(gt_main_data(ln_i).stnd_price);
                        -- 標準原価
                        IF ( NVL(lv_trans_qty,0) != 0 ) THEN
                          ln_unit_price1 := ROUND(gt_main_data(ln_i).stnd_price/lv_trans_qty, 2);
                        END IF;
                      END IF;
                      -- 有償金額
                      IF  ( NVL(gt_main_data(ln_i).price,0) != 0 ) THEN
                        lv_price2        := ROUND(gt_main_data(ln_i).price);
                        -- 有償単価
                        IF ( NVL(lv_trans_qty,0) != 0 ) THEN
                          ln_unit_price2 := ROUND(gt_main_data(ln_i).price/lv_trans_qty, 2);
                        END IF;
                      END IF;
                      -- 消費税
                      IF  ( NVL(gt_main_data(ln_i).tax,0) != 0 ) THEN
                        lv_tax_price     := ROUND(gt_main_data(ln_i).tax);
                      END IF;
                      -- 実際金額
                      IF  ( NVL(gt_main_data(ln_i).actual_price,0) != 0 ) THEN
                        lv_price3        := ROUND(gt_main_data(ln_i).actual_price);
                        -- 実際原価
                        IF ( NVL(lv_trans_qty,0) != 0 ) THEN
                          ln_unit_price3 := ROUND(gt_main_data(ln_i).actual_price/lv_trans_qty, 2);
                        END IF;
                      END IF;
                      -- 有－標(単価)
                      ln_unit_price4   := ROUND( NVL(ln_unit_price2,0) - NVL(ln_unit_price1,0), 2);
                      -- 有－標(金額)
                      lv_price4        := ROUND( NVL(lv_price2,0)      - NVL(lv_price1,0) );
                      -- 有－実(単価)
                      ln_unit_price5   := ROUND( NVL(ln_unit_price2,0) - NVL(ln_unit_price3,0), 2);
                      -- 有－実(金額)
                      lv_price5        := ROUND( NVL(lv_price2,0)      - NVL(lv_price3,0) );
                      -- 標－実(単価)
                      ln_unit_price6   := ROUND( NVL(ln_unit_price1,0) - NVL(ln_unit_price3,0), 2);
                      -- 標－実(金額)
                      lv_price6        := ROUND( NVL(lv_price1,0)      - NVL(lv_price3,0) );
--
                      -- -----------------------------------------------------
                      -- XML出力
                      -- -----------------------------------------------------
                      -- 出荷品目コード・出荷品目名称
                      prc_xml_add('req_item_code','D', gt_main_data(ln_i).req_item_code );
                      prc_xml_add('req_item_name','D', gt_main_data(ln_i).req_item_name );
                      -- 品目コード・品目名称
                      prc_xml_add('item_code'    ,'D', gt_main_data(ln_i).item_code );
                      prc_xml_add('item_name'    ,'D', gt_main_data(ln_i).item_name );
                      -- 単位
                      prc_xml_add('item_um'      ,'D', gt_main_data(ln_i).trans_um );
                      -- 数量
                      prc_xml_add('trans_qty'  ,'D', NVL(lv_trans_qty,0) );
                      -- 消費税
                      prc_xml_add('tax_price'  ,'D', NVL(lv_tax_price,0) );
                      -- 標準原価
                      prc_xml_add('unit_price1','D', NVL(ln_unit_price1,0) );
                      -- 標準金額
                      prc_xml_add('price1'     ,'D', NVL(lv_price1,0) );
                      -- 有償単価
                      prc_xml_add('unit_price2','D', NVL(ln_unit_price2,0) );
                      -- 有償金額
                      prc_xml_add('price2'     ,'D', NVL(lv_price2,0) );
                      -- 実際原価
                      prc_xml_add('unit_price3','D', NVL(ln_unit_price3,0) );
                      -- 実際金額
                      prc_xml_add('price3'     ,'D', NVL(lv_price3,0) );
                      -- 有－標（原価）
                      prc_xml_add('unit_price4','D', NVL(ln_unit_price4,0) );
                      -- 有－標（金額）
                      prc_xml_add('price4'     ,'D', NVL(lv_price4,0) );
                      -- 有－実（原価）
                      prc_xml_add('unit_price5','D', NVL(ln_unit_price5,0) );
                      -- 有－実（金額）
                      prc_xml_add('price5'     ,'D', NVL(lv_price5,0) );
                      -- 標－実（単価）
                      prc_xml_add('unit_price6','D', NVL(ln_unit_price6,0) );
                      -- 標－実（金額）
                      prc_xml_add('price6'     ,'D', NVL(lv_price6,0) );
                      -- 件数カウント
                      prc_xml_add('item_position' ,'D', ln_i );
--
                      ln_i  :=  ln_i  + 1; --次明細位置
                      prc_xml_add('/g_item', 'T');
                    END LOOP  item_loop;
                    prc_xml_add('/lg_item', 'T');
                    --================================================詳郡計ループ終了
                    prc_xml_add('/g_crowd', 'T');
                  END LOOP  crowd_loop;
                  prc_xml_add('/lg_crowd', 'T');
                  --================================================詳郡計ループ終了
                  prc_xml_add('/g_crowd_s', 'T');
                END LOOP  crowd_s_loop;
                prc_xml_add('/lg_crowd_s', 'T');
                --================================================小郡計ループ終了
                prc_xml_add('/g_crowd_m', 'T');
              END LOOP  crowd_m_loop;
              prc_xml_add('/lg_crowd_m', 'T');
              --================================================中郡計ループ終了
              prc_xml_add('/g_crowd_l', 'T');
            END LOOP  crowd_l_loop;
            prc_xml_add('/lg_crowd_l', 'T');
          --================================================大郡計ループ終了
          prc_xml_add('/g_gr4', 'T');
          END LOOP  group4_loop;
          prc_xml_add('/lg_gr4', 'T');
          --================================================集計４ループ終了
          prc_xml_add('/g_gr3', 'T');
        END LOOP  group3_loop;
        prc_xml_add('/lg_gr3', 'T');
        --================================================集計３ループ終了
        prc_xml_add('/g_gr2', 'T');
      END LOOP  group2_loop;
      prc_xml_add('/lg_gr2', 'T');
      --================================================集計２ループ終了
      --最終レコードの場合、総合計行出力フラグをONにする。
      IF (ln_i > gt_main_data.COUNT) THEN
        prc_xml_add('last_recode_flg', 'D', 'Y');
      ELSE
        prc_xml_add('last_recode_flg', 'D', 'N');
      END IF;
      prc_xml_add('/g_gr1', 'T');
    END LOOP  group1_loop;
    prc_xml_add('/lg_gr1', 'T');
    --================================================集計１ループ終了
--
    prc_xml_add('/data_info', 'T'); --データ終了
--
  EXCEPTION
    -- *** 取得データ０件 ***
    WHEN no_data_expt THEN
      ov_retcode := gv_status_warn ;
      ov_errmsg  := xxcmn_common_pkg.get_msg( gc_application
                                             ,'APP-XXCMN-10122' ) ;
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
  PROCEDURE submain (
    iv_proc_from          IN    VARCHAR2  --   01 : 処理年月FROM
   ,iv_proc_to            IN    VARCHAR2  --   02 : 処理年月TO
   ,iv_rcv_pay_div        IN    VARCHAR2  --   03 : 受払区分
   ,iv_prod_div           IN    VARCHAR2  --   04 : 商品区分
   ,iv_item_div           IN    VARCHAR2  --   05 : 品目区分
   ,iv_result_post        IN    VARCHAR2  --   06 : 成績部署
   ,iv_whse_code          IN    VARCHAR2  --   07 : 倉庫コード
   ,iv_party_code         IN    VARCHAR2  --   08 : 出荷先コード
   ,iv_crowd_type         IN    VARCHAR2  --   09 : 郡種別
   ,iv_crowd_code         IN    VARCHAR2  --   10 : 郡コード
   ,iv_acnt_crowd_code    IN    VARCHAR2  --   11 : 経理群コード
   ,iv_output_type        IN    VARCHAR2  --   12 : 出力種別
   ,ov_errbuf            OUT    VARCHAR2  -- エラー・メッセージ           --# 固定 #
   ,ov_retcode           OUT    VARCHAR2  -- リターン・コード             --# 固定 #
   ,ov_errmsg            OUT    VARCHAR2  -- ユーザー・エラー・メッセージ --# 固定 #
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
    -- *** ローカル変数 ***
    lr_param_rec            rec_param_data ;          -- パラメータ受渡し用
--
    lv_xml_string           VARCHAR2(32000) ;
    ln_retcode              NUMBER ;
--
    lv_work_date            VARCHAR2(30); -- 変換用
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
    -- 帳票出力値格納
    gv_report_id                 := iv_output_type || 'T' ;-- 帳票ID
    gd_exec_date                 := SYSDATE ;              -- 実施日
    -- パラメータ格納
    -- 処理年月FROM
    lv_work_date :=
      TO_CHAR(FND_DATE.STRING_TO_DATE( iv_proc_from, gc_char_m_format ), gc_char_m_format );
    IF ( lv_work_date IS NULL ) THEN
      lr_param_rec.proc_from     := iv_proc_from;
    ELSE
      lr_param_rec.proc_from     := lv_work_date;
    END IF;
    -- 処理年月TO
    lv_work_date :=
      TO_CHAR(FND_DATE.STRING_TO_DATE( iv_proc_to, gc_char_m_format ), gc_char_m_format );
    IF ( lv_work_date IS NULL ) THEN
      lr_param_rec.proc_to     := iv_proc_to;
    ELSE
      lr_param_rec.proc_to     := lv_work_date;
    END IF;
    lr_param_rec.rcv_pay_div     := iv_rcv_pay_div;        -- 受払区分
    lr_param_rec.prod_div        := iv_prod_div;           -- 商品区分
    lr_param_rec.item_div        := iv_item_div;           -- 品目区分
    lr_param_rec.result_post     := iv_result_post;        -- 成績部署
    lr_param_rec.whse_code       := iv_whse_code;          -- 倉庫コード
    lr_param_rec.party_code      := iv_party_code;         -- 出荷先コード
    lr_param_rec.crowd_type      := iv_crowd_type;         -- 郡種別
    lr_param_rec.crowd_code      := iv_crowd_code;         -- 郡コード
    lr_param_rec.acnt_crowd_code := iv_acnt_crowd_code;    -- 経理群コード
    lr_param_rec.output_type     := iv_output_type;        -- 出力種別
--
    -- =====================================================
    -- 前処理
    -- =====================================================
    prc_initialize(
        ir_param          => lr_param_rec       -- 入力パラメータ群
       ,ov_errbuf         => lv_errbuf          -- エラー・メッセージ           --# 固定 #
       ,ov_retcode        => lv_retcode         -- リターン・コード             --# 固定 #
       ,ov_errmsg         => lv_errmsg          -- ユーザー・エラー・メッセージ --# 固定 #
    ) ;
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt ;
    END IF ;
--
    -- =====================================================
    -- 帳票データ出力
    -- =====================================================
    prc_create_xml_data(
        ir_param          => lr_param_rec       -- 入力パラメータ群
       ,ov_errbuf         => lv_errbuf          -- エラー・メッセージ           --# 固定 #
       ,ov_retcode        => lv_retcode         -- リターン・コード             --# 固定 #
       ,ov_errmsg         => lv_errmsg          -- ユーザー・エラー・メッセージ --# 固定 #
    ) ;
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt ;
    END IF ;
--
    -- ==================================================
    -- ＸＭＬ出力
    -- ==================================================
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<?xml version="1.0" encoding="shift_jis" ?>' ) ;
--
    -- --------------------------------------------------
    -- 抽出データが０件の場合
    -- --------------------------------------------------
    IF  ( lv_errmsg IS NOT NULL )
    AND ( lv_retcode = gv_status_warn ) THEN
      -- ０件メッセージ出力
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<root>') ;
--
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '  <user_info>') ;
      -- ＸＭＬタグ出力 ＞ 実施日
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<exec_date>'
                                       ||    TO_CHAR(gd_exec_date, gc_char_dt_format)
                                       || '</exec_date>'
                       );
      -- ＸＭＬタグ出力 ＞ 帳票ＩＤ
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<report_id>'
                                       ||    gv_report_id
                                       || '</report_id>'
                       );
      -- ＸＭＬタグ出力 ＞ 担当部署
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<exec_user_dept>'
                                       ||    SUBSTRB(gv_user_dept,1,20)
                                       || '</exec_user_dept>'
                       );
      -- ＸＭＬタグ出力 ＞ 担当者名
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<exec_user_name>'
                                       ||    SUBSTRB(gv_user_name,1,20)
                                       || '</exec_user_name>'
                       );
      -- ＸＭＬタグ出力：商品区分
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<p_item_div_code>'
                                       ||    lr_param_rec.prod_div
                                       || '</p_item_div_code>'
                       );
      -- ＸＭＬタグ出力：商品区分名
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<p_item_div_name>'
                                       ||    lr_param_rec.prod_div_name
                                       || '</p_item_div_name>'
                       );
      -- ＸＭＬタグ出力 出荷先コード
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<p_party_code>'
                                       ||    lr_param_rec.party_code
                                       || '</p_party_code>'
                       );
      -- ＸＭＬタグ出力 出荷先名
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<p_party_name>'
                                       ||    lr_param_rec.party_name
                                       || '</p_party_name>'
                       );
      -- ＸＭＬタグ出力 倉庫コード
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<p_locat_code>'
                                       ||    lr_param_rec.whse_code
                                       || '</p_locat_code>'
                       );
      -- ＸＭＬタグ出力 倉庫名
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<p_locat_name>'
                                       ||    lr_param_rec.whse_name
                                       || '</p_locat_name>'
                       );
      -- ＸＭＬタグ出力 ＞ 受払区分
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<p_rcv_pay_div_code>'
                                       ||    lr_param_rec.rcv_pay_div
                                       || '</p_rcv_pay_div_code>'
                       );
      -- ＸＭＬタグ出力 ＞ 受払区分名
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<p_rcv_pay_div_name>'
                                       ||    lr_param_rec.rcv_pay_div_name
                                       || '</p_rcv_pay_div_name>'
                       );
      -- ＸＭＬタグ出力 ＞ 品目区分
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<p_article_div_code>'
                                       ||    lr_param_rec.item_div
                                       || '</p_article_div_code>'
                       );
      -- ＸＭＬタグ出力 ＞ 品目区分名
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<p_article_div_name>'
                                       ||    lr_param_rec.item_div_name
                                       || '</p_article_div_name>'
                       );
      -- ＸＭＬタグ出力 ＞ 成績部署
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<p_result_post_code>'
                                       ||    lr_param_rec.result_post
                                       || '</p_result_post_code>'
                       );
      -- ＸＭＬタグ出力 ＞ 成績部署名
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<p_result_post_name>'
                                       ||    lr_param_rec.result_post_name
                                       || '</p_result_post_name>'
                       );
      -- ＸＭＬタグ出力 ＞ 処理年月(自)
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<p_trans_ym_from>'
                                       ||    SUBSTRB(lr_param_rec.proc_from,1,4) || '年'
                                       ||    SUBSTRB(lr_param_rec.proc_from,5,2) || '月'
                                       || '</p_trans_ym_from>'
                       );
      -- ＸＭＬタグ出力 ＞ 処理年月(自)
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<p_trans_ym_to>'
                                       ||    SUBSTRB(lr_param_rec.proc_to,1,4) || '年'
                                       ||    SUBSTRB(lr_param_rec.proc_to,5,2) || '月'
                                       || '</p_trans_ym_to>'
                       );
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '  </user_info>') ;
--
      -- ＜data_info＞
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '  <data_info>') ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '    <lg_gr1>') ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '      <g_gr1>') ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '        <lg_gr2>') ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '          <g_gr2>') ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '            <lg_gr3>') ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '              <g_gr3>') ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                <lg_gr4>') ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                  <g_gr4>') ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                    <lg_crowd_l>') ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                      <g_crowd_l>') ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                        <lg_crowd_m>') ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                          <g_crowd_m>') ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                            <lg_crowd_s>') ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                              <g_crowd_s>') ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                                <lg_crowd>') ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                                  <g_crowd>') ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, ' <msg>' || lv_errmsg || '</msg>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                                  </g_crowd>') ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                                </lg_crowd>') ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                              </g_crowd_s>') ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                            </lg_crowd_s>') ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                          </g_crowd_m>') ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                        </lg_crowd_m>') ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                      </g_crowd_l>') ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                    </lg_crowd_l>') ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                  </g_gr4>') ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                </lg_gr4>') ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '              </g_gr3>') ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '            </lg_gr3>') ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '          </g_gr2>') ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '        </lg_gr2>') ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '      </g_gr1>') ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '    </lg_gr1>') ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '  </data_info>') ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '</root>') ;
--
      -- ０件メッセージログ出力
      lv_errmsg  := xxcmn_common_pkg.get_msg( gc_application
                                             ,'APP-XXCMN-10154'
                                             ,'TABLE'
                                             ,gv_print_name ) ;
--
    -- --------------------------------------------------
    -- 帳票データが出力できた場合
    -- --------------------------------------------------
    ELSE
      -- ＸＭＬヘッダー出力
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<root>' ) ;
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
                          ) ;
        -- ＸＭＬタグ出力
        FND_FILE.PUT_LINE( FND_FILE.OUTPUT, lv_xml_string ) ;
      END LOOP xml_data_table ;
--
      -- ＸＭＬフッダー出力
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '</root>' ) ;
--
    END IF ;
--
    -- ==================================================
    -- 終了ステータス設定
    -- ==================================================
    ov_retcode := lv_retcode ;
    ov_errmsg  := lv_errmsg ;
    ov_errbuf  := lv_errbuf ;
--
  EXCEPTION
--#################################  固定例外処理部 START   ###################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg ;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000) ;
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
  END submain ;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : コンカレント実行ファイル登録プロシージャ
   **********************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
      errbuf             OUT   VARCHAR2  -- エラーメッセージ
     ,retcode            OUT   VARCHAR2  -- エラーコード
     ,iv_proc_from       IN    VARCHAR2  --   01 : 処理年月FROM
     ,iv_proc_to         IN    VARCHAR2  --   02 : 処理年月TO
     ,iv_rcv_pay_div     IN    VARCHAR2  --   03 : 受払区分
     ,iv_prod_div        IN    VARCHAR2  --   04 : 商品区分
     ,iv_item_div        IN    VARCHAR2  --   05 : 品目区分
     ,iv_result_post     IN    VARCHAR2  --   06 : 成績部署
     ,iv_whse_code       IN    VARCHAR2  --   07 : 倉庫コード
     ,iv_party_code      IN    VARCHAR2  --   08 : 出荷先コード
     ,iv_crowd_type      IN    VARCHAR2  --   09 : 郡種別
     ,iv_crowd_code      IN    VARCHAR2  --   10 : 郡コード
     ,iv_acnt_crowd_code IN    VARCHAR2  --   11 : 経理群コード
     ,iv_output_type     IN    VARCHAR2  --   12 : 出力種別
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
        iv_proc_from        => iv_proc_from         --   01 : 処理年月FROM
       ,iv_proc_to          => iv_proc_to           --   02 : 処理年月TO
       ,iv_rcv_pay_div      => iv_rcv_pay_div       --   03 : 受払区分
       ,iv_prod_div         => iv_prod_div          --   04 : 商品区分
       ,iv_item_div         => iv_item_div          --   05 : 品目区分
       ,iv_result_post      => iv_result_post       --   06 : 成績部署
       ,iv_whse_code        => iv_whse_code         --   07 : 倉庫コード
       ,iv_party_code       => iv_party_code        --   08 : 出荷先コード
       ,iv_crowd_type       => iv_crowd_type        --   09 : 郡種別
       ,iv_crowd_code       => iv_crowd_code        --   10 : 郡コード
       ,iv_acnt_crowd_code  => iv_acnt_crowd_code   --   11 : 経理群コード
       ,iv_output_type      => iv_output_type       --   12 : 出力種別
       ,ov_errbuf           => lv_errbuf            -- エラー・メッセージ           --# 固定 #
       ,ov_retcode          => lv_retcode           -- リターン・コード             --# 固定 #
       ,ov_errmsg           => lv_errmsg            -- ユーザー・エラー・メッセージ --# 固定 #
     ) ;
--
--###########################  固定部 START   #####################################################
--
    -- ======================================================
    -- エラー・メッセージ出力
    -- ======================================================
    IF  ( lv_retcode = gv_status_error )
     OR ( lv_retcode = gv_status_warn  ) THEN
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
END xxcmn770026c ;
/