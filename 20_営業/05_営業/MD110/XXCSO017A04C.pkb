CREATE OR REPLACE PACKAGE BODY APPS.XXCSO017A04C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCSO017A04C(body)
 * Description      : 帳合問屋用見積入力画面から、見積番号、版毎に見積書を  
 *                    帳票に出力します。
 * MD.050           : MD050_CSO_017_A04_見積書（帳合問屋用）PDF出力
 * Version          : 1.9
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  chk_param              パラメータ・チェック(A-1)
 *  process_data           加工処理(A-3)
 *  insert_row             ワークテーブル出力(A-4)
 *  insert_blanks          ワークテーブル(空行)出力(A-5)
 *  act_svf                SVF起動(A-6)
 *  delete_row             ワークテーブルデータ削除(A-7)
 *  submain                メイン処理プロシージャ
 *                           データ取得(A-2)
 *                           SVF起動APIエラーチェック(A-8)
 *  main                   コンカレント実行ファイル登録プロシージャ
 *                           終了処理(A-9)
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009-01-21    1.0   Kazuyo.Hosoi     新規作成
 *  2009-03-03    1.1   Kazuyo.Hosoi     SVF起動API埋め込み
 *  2009-03-05    1.1   Kazuyo.Hosoi     帳票レイアウトレビュー指摘対応
 *                                       (郵便番号の取得、JANコードの編集)
 *  2009-04-03    1.2   Kazuo.Satomura   ＳＴ障害対応(T1_0294,0301)
 *  2009-05-01    1.3   Tomoko.Mori      T1_0897対応
 *  2009-05-07    1.4   Kazuo.Satomura   ＳＴ障害対応(T1_0889)
 *  2009-05-13    1.5   Kazuo.Satomura   ＳＴ障害対応(T1_0972,T1_0974)
 *  2009-05-20    1.6   Makoto.Ohtsuki   ＳＴ障害対応(T1_0696)
 *  2009-06-17    1.7   Daisuke.Abe      ＳＴ障害対応(T1_1257)
 *  2009-07-30    1.8   Daisuke.Abe      SCS障害対応(0000806)
 *  2009-12-16    1.9   Daisuke.Abe      E_本稼動_00501
 *****************************************************************************************/
--
--#######################  固定グローバル定数宣言部 START   #######################
--
  --ステータス・コード
  cv_status_normal          CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal; --正常:0
  cv_status_warn            CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_warn;   --警告:1
  cv_status_error           CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;  --異常:2
  --WHOカラム
  cn_created_by             CONSTANT NUMBER      := fnd_global.user_id;         --CREATED_BY
  cd_creation_date          CONSTANT DATE        := SYSDATE;                    --CREATION_DATE
  cn_last_updated_by        CONSTANT NUMBER      := fnd_global.user_id;         --LAST_UPDATED_BY
  cd_last_update_date       CONSTANT DATE        := SYSDATE;                    --LAST_UPDATE_DATE
  cn_last_update_login      CONSTANT NUMBER      := fnd_global.login_id;        --LAST_UPDATE_LOGIN
  cn_request_id             CONSTANT NUMBER      := fnd_global.conc_request_id; --REQUEST_ID
  cn_program_application_id CONSTANT NUMBER      := fnd_global.prog_appl_id;    --PROGRAM_APPLICATION_ID
  cn_program_id             CONSTANT NUMBER      := fnd_global.conc_program_id; --PROGRAM_ID
  cd_program_update_date    CONSTANT DATE        := SYSDATE;                    --PROGRAM_UPDATE_DATE
--
  cv_msg_part      CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont      CONSTANT VARCHAR2(3) := '.';
--
--################################  固定部 END   ##################################
--
--#######################  固定グローバル変数宣言部 START   #######################
--
  gv_out_msg       VARCHAR2(2000);
  gv_sep_msg       VARCHAR2(2000);
  gv_exec_user     VARCHAR2(100);
  gv_conc_name     VARCHAR2(30);
  gv_conc_status   VARCHAR2(30);
  gn_target_cnt    NUMBER;                    -- 対象件数
  gn_normal_cnt    NUMBER;                    -- 正常件数
  gn_error_cnt     NUMBER;                    -- エラー件数
  gn_warn_cnt      NUMBER;                    -- スキップ件数
--
--################################  固定部 END   ##################################
--
--##########################  固定共通例外宣言部 START  ###########################
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
--################################  固定部 END   ##################################
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name            CONSTANT VARCHAR2(100) := 'XXCSO017A04C';  -- パッケージ名
  cv_app_name            CONSTANT VARCHAR2(5)   := 'XXCSO';         -- アプリケーション短縮名
  cn_org_id              CONSTANT NUMBER        := TO_NUMBER(SUBSTRB(USERENV('CLIENT_INFO'), 1, 10)); -- ログイン組織ＩＤ
  -- 日付書式
  cv_format_date_ymd1    CONSTANT VARCHAR2(8)   := 'YYYYMMDD';      -- 日付フォーマット（年月日）
  cv_format_date_ymd2    CONSTANT VARCHAR2(10)  := 'YYYY/MM/DD';    -- 日付フォーマット（年/月/日）
  -- メッセージコード
  cv_tkn_number_01       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00496';  -- パラメータ出力
  cv_tkn_number_02       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00005';  -- 必須項目エラー
  cv_tkn_number_03       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00495';  -- 出力情報未取得エラー
  cv_tkn_number_04       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00042';  -- ＤＢ登録・更新エラー
  cv_tkn_number_05       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00278';  -- ロックエラーメッセージ
  cv_tkn_number_06       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00417';  -- APIエラーメッセージ
  cv_tkn_number_07       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00503';  -- 明細0件メッセージ
/* 2009.06.17 D.Abe T1_1257対応 START */
  cv_tkn_number_08       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00575';  -- 入数エラー
  cv_unit_type_hs          CONSTANT VARCHAR2(1)  := '1';                  -- 単価区分:1(本数)
  cv_unit_type_cs          CONSTANT VARCHAR2(1)  := '2';                  -- 単価区分:2(C/S)
  cv_unit_type_bl          CONSTANT VARCHAR2(1)  := '3';                  -- 単価区分:3:ボール
/* 2009.06.17 D.Abe T1_1257対応 END */
  -- トークンコード
  cv_tkn_param_nm        CONSTANT VARCHAR2(20) := 'PARAM_NAME';
  cv_tkn_val             CONSTANT VARCHAR2(20) := 'VALUE';
  cv_tkn_clmn            CONSTANT VARCHAR2(20) := 'COLUMN';
  cv_tkn_param1          CONSTANT VARCHAR2(20) := 'PARAM1';
  cv_tkn_act             CONSTANT VARCHAR2(20) := 'ACTION';
  cv_tkn_errmsg          CONSTANT VARCHAR2(20) := 'ERRMSG';
  cv_tkn_tbl             CONSTANT VARCHAR2(20) := 'TABLE';
  cv_tkn_err_msg         CONSTANT VARCHAR2(20) := 'ERR_MSG';
  cv_tkn_api_nm          CONSTANT VARCHAR2(20) := 'API_NAME';
  cv_tkn_qt_num          CONSTANT VARCHAR2(20) := 'QUOTE_NUMBER';
  --
  cv_msg_prnthss_l       CONSTANT VARCHAR2(1)  := '(';
  cv_msg_prnthss_r       CONSTANT VARCHAR2(1)  := ')';
  cv_msg_comma           CONSTANT VARCHAR2(1)  := ',';
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gn_page_cnt            NUMBER DEFAULT 1;  -- 空行出力用ページカウンタ
  gn_rec_cnt             NUMBER DEFAULT 1;  -- 空行出力用レコードカウンタ
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  -- 見積帳票ワークテーブル データ格納用レコード型定義
  TYPE g_rp_qte_lst_data_rtype IS RECORD(
     quote_header_id               xxcso_rep_quote_list.quote_header_id%TYPE            -- 見積ヘッダーＩＤ
    ,line_order                    xxcso_rep_quote_list.line_order%TYPE                 -- 並び順
    ,quote_line_id                 xxcso_rep_quote_list.quote_line_id%TYPE              -- 見積明細ＩＤ 
    ,quote_number                  xxcso_rep_quote_list.quote_number%TYPE               -- 見積番号
    ,reference_quote_number        xxcso_quote_headers.reference_quote_number%TYPE      -- 参照用見積番号
    ,publish_date                  xxcso_rep_quote_list.publish_date%TYPE               -- 発行日
    ,customer_name                 xxcso_rep_quote_list.customer_name%TYPE              -- 顧客名
    ,account_number                xxcso_quote_headers.account_number%TYPE              -- 顧客コード
    ,sales_name                    xxcso_rep_quote_list.sales_name%TYPE                 -- 販売先名
    ,deliv_place                   xxcso_rep_quote_list.deliv_place%TYPE                -- 納入場所
    ,header_payment_condition      xxcso_rep_quote_list.header_payment_condition%TYPE   -- ヘッダー支払条件
    ,base_code                     xxcso_quote_headers.base_code%TYPE                   -- 拠点コード
    /* 2009.05.13 K.Satomura T1_0972対応 START */
    ,base_zip                      xxcso_rep_quote_list.base_zip%TYPE                   -- 拠点郵便番号
    /* 2009.05.13 K.Satomura T1_0972対応 END */
    ,base_addr                     xxcso_rep_quote_list.base_addr%TYPE                  -- 拠点住所
    ,base_name                     xxcso_rep_quote_list.base_name%TYPE                  -- 拠点名
    ,base_phone_no                 xxcso_rep_quote_list.base_phone_no%TYPE              -- 拠点電話番号
    ,quote_unit_sale               xxcso_rep_quote_list.quote_unit_sale%TYPE            -- 見積単位(販売先)
    ,quote_unit_warehouse          xxcso_rep_quote_list.quote_unit_warehouse%TYPE       -- 見積単位(帳合問屋)
    ,unit_type                     xxcso_quote_headers.unit_type%TYPE                   -- 単価区分
    ,quote_submit_name             xxcso_quote_headers.quote_submit_name%TYPE           -- 見積書提出先名
    ,dliv_prce_tx_t                xxcso_quote_headers.deliv_price_tax_type%TYPE        -- 店納価格税区分
    ,dliv_prce_tx_t_nm             xxcso_rep_quote_list.deliv_price_tax_type%TYPE       -- 店納価格税区分名
    ,special_note                  xxcso_rep_quote_list.special_note%TYPE               -- 特記事項
    ,inventory_item_id             xxcso_quote_lines.inventory_item_id%TYPE             -- 品目ＩＤ
    ,item_name                     xxcso_rep_quote_list.item_name%TYPE                  -- 商品名
    ,jan_code                      xxcso_rep_quote_list.jan_code%TYPE                   -- JANコード
    ,standards                     xxcso_rep_quote_list.standard%TYPE                   -- 規格
    ,inc_num                       xxcso_rep_quote_list.inc_num%TYPE                    -- 入数 
    ,sticer_price                  xxcso_rep_quote_list.sticer_price%TYPE               -- メーカー希望小売価格
    ,quote_div                     xxcso_quote_lines.quote_div%TYPE                     -- 見積区分
    ,quote_div_nm                  xxcso_rep_quote_list.quote_div%TYPE                  -- 見積区分名
    ,quotation_price               xxcso_rep_quote_list.quotation_price%TYPE            -- 建値
    ,usually_deliv_price           xxcso_rep_quote_list.usually_deliv_price%TYPE        -- 通常店納価格
    ,this_time_deliv_price         xxcso_rep_quote_list.this_time_deliv_price%TYPE      -- 今回店納価格
    ,usuall_net_price              xxcso_rep_quote_list.usuall_net_price%TYPE           -- 通常ＮＥＴ価格
    ,this_time_net_price           xxcso_rep_quote_list.this_time_net_price%TYPE        -- 今回ＮＥＴ価格
    ,line_payment_condition        xxcso_rep_quote_list.line_payment_condition%TYPE     -- 明細支払条件
    ,amount_of_margin              xxcso_rep_quote_list.amount_of_margin%TYPE           -- マージン額
    ,margin_rate                   xxcso_rep_quote_list.margin_rate%TYPE                -- マージン率
    ,quote_start_date              xxcso_rep_quote_list.quote_start_date%TYPE           -- 期間（開始）
    ,quote_end_date                xxcso_rep_quote_list.quote_end_date%TYPE             -- 期間（終了）
    ,sales_discount_amt            xxcso_rep_quote_list.sales_discount_amt%TYPE         -- 売上値引
    ,remarks                       xxcso_rep_quote_list.remarks%TYPE                    -- 備考
    ,created_by                    xxcso_rep_quote_list.created_by%TYPE                 -- 作成者
    ,creation_date                 xxcso_rep_quote_list.creation_date%TYPE              -- 作成日
    ,last_updated_by               xxcso_rep_quote_list.last_updated_by%TYPE            -- 最終更新者
    ,last_update_date              xxcso_rep_quote_list.last_update_date%TYPE           -- 最終更新日
    ,last_update_login             xxcso_rep_quote_list.last_update_login%TYPE          -- 最終更新ログイン
    ,request_id                    xxcso_rep_quote_list.request_id%TYPE                 -- 要求ＩＤ        
    ,program_application_id        xxcso_rep_quote_list.program_application_id%TYPE     -- ｺﾝｶﾚﾝﾄﾌﾟﾛｸﾞﾗﾑｱﾌﾟﾘｹｰｼｮﾝ
    ,program_id                    xxcso_rep_quote_list.program_id%TYPE                 -- ｺﾝｶﾚﾝﾄﾌﾟﾛｸﾞﾗﾑＩＤ
    ,program_update_date           xxcso_rep_quote_list.program_update_date%TYPE        -- ﾌﾟﾛｸﾞﾗﾑ更新日
  );
  --
  /**********************************************************************************
   * Procedure Name   : chk_param
   * Description      : パラメータ・チェック(A-1)
   ***********************************************************************************/
  PROCEDURE chk_param(
     in_qt_hdr_id        IN  NUMBER           -- 見積ヘッダーID
    ,ov_errbuf           OUT NOCOPY VARCHAR2  -- エラー・メッセージ            --# 固定 #
    ,ov_retcode          OUT NOCOPY VARCHAR2  -- リターン・コード              --# 固定 #
    ,ov_errmsg           OUT NOCOPY VARCHAR2  -- ユーザー・エラー・メッセージ  --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'chk_param';     -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
    -- *** ローカル定数 ***
    cv_qt_hdr_id        CONSTANT VARCHAR2(100)   := '見積ヘッダーＩＤ';
    -- *** ローカル変数 ***
    -- メッセージ出力用
    lv_msg              VARCHAR2(5000);
    -- *** ローカル例外 ***
    chk_param_expt   EXCEPTION;  -- 見積ヘッダーＩＤ未入力エラー
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ===========================
    -- 起動パラメータメッセージ出力
    -- ===========================
    -- 空行の挿入
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
--
    lv_msg := xxccp_common_pkg.get_msg(
                 iv_application  => cv_app_name           --アプリケーション短縮名
                ,iv_name         => cv_tkn_number_01      --メッセージコード
                ,iv_token_name1  => cv_tkn_param_nm       --トークンコード1
                ,iv_token_value1 => cv_qt_hdr_id          --トークン値1
                ,iv_token_name2  => cv_tkn_val            --トークンコード2
                ,iv_token_value2 => TO_CHAR(in_qt_hdr_id) --トークン値2
              );
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => lv_msg
    );
    -- ===========================
    -- パラメータ必須チェック
    -- ===========================
    IF (in_qt_hdr_id IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name           --アプリケーション短縮名
                    ,iv_name         => cv_tkn_number_02      --メッセージコード
                    ,iv_token_name1  => cv_tkn_clmn           --トークンコード1
                    ,iv_token_value1 => cv_qt_hdr_id          --トークン値1
                   );
      lv_errbuf := lv_errmsg || SQLERRM;
      RAISE chk_param_expt;
    END IF;
    -- 空行の挿入
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
--
  EXCEPTION
    -- *** 見積ヘッダーＩＤ未入力エラー ***
    WHEN chk_param_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END chk_param;
--
  /**********************************************************************************
   * Procedure Name   : process_data
   * Description      : 加工処理(A-3)
   ***********************************************************************************/
  PROCEDURE process_data(
     io_rp_qte_lst_dt_rec  IN OUT NOCOPY g_rp_qte_lst_data_rtype  -- 見積データ
    ,ov_errbuf             OUT NOCOPY VARCHAR2                    -- エラー・メッセージ            --# 固定 #
    ,ov_retcode            OUT NOCOPY VARCHAR2                    -- リターン・コード              --# 固定 #
    ,ov_errmsg             OUT NOCOPY VARCHAR2                    -- ユーザー・エラー・メッセージ  --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'process_data';  -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    -- クイックコード取得
    cv_lkup_tp_tx_dvsn       CONSTANT VARCHAR2(30) := 'XXCSO1_TAX_DIVISION';
    cv_lkup_tp_unt_prc_dvsn  CONSTANT VARCHAR2(30) := 'XXCSO1_UNIT_PRICE_DIVISION';
    cv_lkup_tp_qte_dvsn      CONSTANT VARCHAR2(30) := 'XXCSO1_QUOTE_DIVISION';
    /* 2009.04.03 K.Satomura T1_0294対応 START */
    --cv_lkup_tp_itm_nt_um_cd  CONSTANT VARCHAR2(30) := 'XXINV_ITM_NET_UOM_CODE';
    cv_lkup_tp_itm_nt_um_cd  CONSTANT VARCHAR2(30) := 'XXCMM_ITM_NET_UOM_CODE';
    /* 2009.04.03 K.Satomura T1_0294対応 END */
    --
    cv_yes                   CONSTANT VARCHAR2(1)  := 'Y';
    cv_zero                  CONSTANT VARCHAR2(1)  := '0';
    cv_quote_div             CONSTANT VARCHAR2(1)  := '4';                  -- 見積区分 4:原価割れ(特別販売)
    /* 2009.05.07 K.Satomura T1_0889対応 START */
    --cv_fmt                   CONSTANT VARCHAR2(7)  := 'FM9,999';            -- 規格編集用フォーマット
    /* 2009.05.13 K.Satomura T1_0974対応 START */
    --cv_fmt                   CONSTANT VARCHAR2(9)  := 'FM9,999.9';            -- 規格編集用フォーマット
    cv_fmt                   CONSTANT VARCHAR2(9)  := 'FM9,990.0';            -- 規格編集用フォーマット
    /* 2009.05.13 K.Satomura T1_0974対応 END */
    /* 2009.05.07 K.Satomura T1_0889対応 END */
/* 2009.06.17 D.Abe T1_1257対応 START */
    --cv_unit_type_hs          CONSTANT VARCHAR2(1)  := '1';                  -- 単価区分:1(本数)
    --cv_unit_type_cs          CONSTANT VARCHAR2(1)  := '2';                  -- 単価区分:2(C/S)
    --cv_unit_type_bl          CONSTANT VARCHAR2(1)  := '3';                  -- 単価区分:3:ボール
/* 2009.06.17 D.Abe T1_1257対応 END */
    -- メッセージ出力用トークン
    cv_tkn_party_name        CONSTANT VARCHAR2(100) := '顧客名';
    cv_tkn_sales_name        CONSTANT VARCHAR2(100) := '顧客販売先名';
    cv_tkn_loc_info          CONSTANT VARCHAR2(100) := '拠点情報';
    cv_tkn_dlv_prc_tx_t_nm   CONSTANT VARCHAR2(100) := '店納価格税区分名';
    cv_tkn_unit_tp_nm_1      CONSTANT VARCHAR2(100) := '単価区分名（帳合問屋）';
    cv_tkn_unit_tp_nm_2      CONSTANT VARCHAR2(100) := '単価区分名（販売先）';
    cv_tkn_item_info         CONSTANT VARCHAR2(100) := '品目情報';
    cv_tkn_qt_div_nm         CONSTANT VARCHAR2(100) := '見積区分名';
    cv_tkn_itm_nt_um_cd_nm   CONSTANT VARCHAR2(100) := '内容量単位名';
    --
    cv_qt_line_id            CONSTANT VARCHAR2(100) := '明細ＩＤ : ';
    cv_invntry_itm_id        CONSTANT VARCHAR2(100) := '品目ＩＤ : ';
    cv_ln_ordr               CONSTANT VARCHAR2(100) := '並び順 : ';
    --
    cv_jan                   CONSTANT VARCHAR2(100) := 'JAN ';              -- JANコード編集文字列
    cv_space                 CONSTANT VARCHAR2(100) := ' ';                 -- 半角スペース
    -- *** ローカル変数 ***
    lt_party_name            xxcso_cust_accounts_v.party_name%TYPE;         -- 顧客名
    lt_sales_name            xxcso_cust_accounts_v.party_name%TYPE;         -- 販売先名
    lt_location_name         xxcso_locations_v2.location_name%TYPE;         -- 正式名
    lt_address_line1         xxcso_locations_v2.address_line1%TYPE;         -- 住所
    lt_phone                 xxcso_locations_v2.phone%TYPE;                 -- 電話番号
    ld_sysdate               DATE;
    lt_mean_dlv_prce_tx_tp   fnd_lookup_values_vl.meaning%TYPE;             -- 店納価格税区分名
    lt_mean_unit_tp_1        fnd_lookup_values_vl.meaning%TYPE;             -- 単価区分名（帳合問屋）
    lt_mean_unit_tp_2        fnd_lookup_values_vl.meaning%TYPE;             -- 単価区分名（販売先）
    lt_item_short_name       xxcso_inventory_items_v2.item_short_name%TYPE; -- 商品名
    lt_fixed_price_new       xxcso_inventory_items_v2.fixed_price_new%TYPE; -- メーカー希望小売価格
    lt_jan_code              xxcso_inventory_items_v2.jan_code%TYPE;        -- JANコード
    lt_case_inc_num          xxcso_inventory_items_v2.case_inc_num%TYPE;    -- ケース入数
    lt_bowl_inc_num          xxcso_inventory_items_v2.bowl_inc_num%TYPE;    -- ボール入数
    lv_qt_div_nm             VARCHAR2(240);                                 -- 見積区分名
    lt_nets                  xxcso_inventory_items_v2.nets%TYPE;            -- 内容量
    lt_nets_uom_code         xxcso_inventory_items_v2.nets_uom_code%TYPE;   -- 内容量単位
    lt_nets_uom_cd_nm        fnd_lookup_values_vl.meaning%TYPE;             -- 内容量単位名
    lt_zip                   xxcso_locations_v2.zip%TYPE;                   -- 郵便番号
    -- メッセージ格納用
    lv_msg                   VARCHAR2(5000);
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- システム日付を編集し、格納
    ld_sysdate := TRUNC(SYSDATE);
--
    -- ===========================
    -- 顧客名取得
    -- ===========================
    BEGIN
      SELECT xcav.party_name  party_name  -- 顧客名
      INTO   lt_party_name
      FROM   xxcso_cust_accounts_v  xcav  -- 顧客マスタビュー
      WHERE  xcav.account_number = io_rp_qte_lst_dt_rec.account_number;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_app_name           --アプリケーション短縮名
                   ,iv_name         => cv_tkn_number_03      --メッセージコード
                   ,iv_token_name1  => cv_tkn_param1         --トークンコード1
                   ,iv_token_value1 => cv_tkn_party_name     --トークン値1
                  );
        fnd_file.put_line(
          which  => FND_FILE.LOG
         ,buff   => lv_msg
        );
        ov_retcode := cv_status_warn;
    END;
    -- ===========================
    -- 販売先名取得
    -- ===========================
    BEGIN
      SELECT xcav.party_name  sales_name  -- 顧客名(販売先名)
      INTO   lt_sales_name
      FROM   xxcso_cust_accounts_v  xcav  -- 顧客マスタビュー
            ,xxcso_quote_headers    xqh   -- 見積ヘッダーテーブル
      WHERE  xqh.quote_number   = io_rp_qte_lst_dt_rec.reference_quote_number
        AND  xqh.account_number = xcav.account_number
        /* 2009.04.03 K.Satomura T_0301対応 START */
        AND  xqh.quote_revision_number =
        (
          SELECT MAX(xqh2.quote_revision_number)
          FROM   xxcso_quote_headers xqh2
          WHERE  xqh2.quote_number   = io_rp_qte_lst_dt_rec.reference_quote_number
        )
        /* 2009.04.03 K.Satomura T_0301対応 END */
        ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_app_name           --アプリケーション短縮名
                   ,iv_name         => cv_tkn_number_03      --メッセージコード
                   ,iv_token_name1  => cv_tkn_param1         --トークンコード1
                   ,iv_token_value1 => cv_tkn_sales_name     --トークン値1
                  );
        fnd_file.put_line(
          which  => FND_FILE.LOG
         ,buff   => lv_msg
        );
        ov_retcode := cv_status_warn;
    END;
    -- ====================================
    -- 拠点名・拠点住所・拠点電話番号取得
    -- ====================================
    BEGIN
      SELECT  xlv2.location_name  location_name  -- 正式名
             ,xlv2.address_line1  address_line1  -- 住所
             ,xlv2.phone          phone          -- 電話番号
             ,xlv2.zip            zip            -- 郵便番号
      INTO    lt_location_name
             ,lt_address_line1
             ,lt_phone
             ,lt_zip
      FROM   xxcso_locations_v2 xlv2  -- 事業所マスタ(最新)ビュー
      WHERE  xlv2.dept_code = io_rp_qte_lst_dt_rec.base_code;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_app_name           --アプリケーション短縮名
                   ,iv_name         => cv_tkn_number_03      --メッセージコード
                   ,iv_token_name1  => cv_tkn_param1         --トークンコード1
                   ,iv_token_value1 => cv_tkn_loc_info       --トークン値1
                  );
        fnd_file.put_line(
          which  => FND_FILE.LOG
         ,buff   => lv_msg
        );
        ov_retcode := cv_status_warn;
    END;
    -- ====================================
    -- 店納価格税区分名取得
    -- ====================================
    BEGIN
      SELECT flvv.meaning  meaning       -- 内容(店納価格税区分名)
      INTO   lt_mean_dlv_prce_tx_tp
      FROM   fnd_lookup_values_vl flvv   -- クイックコード
      WHERE  flvv.lookup_type   = cv_lkup_tp_tx_dvsn
        AND  flvv.enabled_flag  = cv_yes
        AND  NVL(flvv.start_date_active, ld_sysdate) <= ld_sysdate
        AND  NVL(flvv.end_date_active, ld_sysdate)   >= ld_sysdate
        AND  flvv.lookup_code   = io_rp_qte_lst_dt_rec.dliv_prce_tx_t;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_app_name             --アプリケーション短縮名
                   ,iv_name         => cv_tkn_number_03        --メッセージコード
                   ,iv_token_name1  => cv_tkn_param1           --トークンコード1
                   ,iv_token_value1 => cv_tkn_dlv_prc_tx_t_nm  --トークン値1
                  );
        fnd_file.put_line(
          which  => FND_FILE.LOG
         ,buff   => lv_msg
        );
        ov_retcode := cv_status_warn;
    END;
    -- ====================================
    -- 単価区分名取得(帳合問屋)
    -- ====================================
    BEGIN
      SELECT flvv.meaning  meaning       -- 内容(単価区分名)
      INTO   lt_mean_unit_tp_1
      FROM   fnd_lookup_values_vl flvv   -- クイックコード
      WHERE  flvv.lookup_type   = cv_lkup_tp_unt_prc_dvsn
        AND  flvv.enabled_flag  = cv_yes
        AND  NVL(flvv.start_date_active, ld_sysdate) <= ld_sysdate
        AND  NVL(flvv.end_date_active, ld_sysdate)   >= ld_sysdate
        AND  flvv.lookup_code   = io_rp_qte_lst_dt_rec.unit_type;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_app_name             --アプリケーション短縮名
                   ,iv_name         => cv_tkn_number_03        --メッセージコード
                   ,iv_token_name1  => cv_tkn_param1           --トークンコード1
                   ,iv_token_value1 => cv_tkn_unit_tp_nm_1     --トークン値1
                  );
        fnd_file.put_line(
          which  => FND_FILE.LOG
         ,buff   => lv_msg
        );
        ov_retcode := cv_status_warn;
    END;
    -- ====================================
    -- 品目情報取得
    -- ====================================
    BEGIN
      SELECT  xiiv2.item_short_name   item_short_name -- 品名・略称
             ,xiiv2.nets              nets            -- 内容量
             ,xiiv2.nets_uom_code     nets_uom_code   -- 内容量単位
             ,xiiv2.fixed_price_new   fixed_price_new -- 定価(新)
             ,xiiv2.jan_code          jan_code        -- JANコード
             ,xiiv2.case_inc_num      case_inc_num    -- ケース入数
             ,xiiv2.bowl_inc_num      bowl_inc_num    -- ボール入数
      INTO   lt_item_short_name
             ,lt_nets
             ,lt_nets_uom_code
             ,lt_fixed_price_new
             ,lt_jan_code
             ,lt_case_inc_num
             ,lt_bowl_inc_num
      FROM   xxcso_inventory_items_v2 xiiv2  -- 品目マスタ(最新)ビュー
      WHERE  xiiv2.inventory_item_id = io_rp_qte_lst_dt_rec.inventory_item_id;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_app_name             --アプリケーション短縮名
                   ,iv_name         => cv_tkn_number_03        --メッセージコード
                   ,iv_token_name1  => cv_tkn_param1           --トークンコード1
                   ,iv_token_value1 => cv_tkn_item_info        --トークン値1
                  );
        fnd_file.put_line(
          which  => FND_FILE.LOG
         ,buff   => lv_msg        ||cv_msg_prnthss_l||
                    cv_qt_line_id ||TO_CHAR(io_rp_qte_lst_dt_rec.quote_line_id)       ||cv_msg_comma||
                    cv_invntry_itm_id||TO_CHAR(io_rp_qte_lst_dt_rec.inventory_item_id)||cv_msg_comma||
                    cv_ln_ordr       ||TO_CHAR(io_rp_qte_lst_dt_rec.line_order)       ||cv_msg_prnthss_r
        );
        ov_retcode := cv_status_warn;
    END;
    -- ====================================
    -- 見積区分名取得
    -- ====================================
    BEGIN
      SELECT DECODE(io_rp_qte_lst_dt_rec.quote_div
                    ,cv_quote_div, flvv.description
                    ,flvv.meaning
                    )  qt_div_nm         -- 見積区分名
      INTO   lv_qt_div_nm
      FROM   fnd_lookup_values_vl flvv   -- クイックコード
      WHERE  flvv.lookup_type   = cv_lkup_tp_qte_dvsn
        AND  flvv.enabled_flag  = cv_yes
        AND  NVL(flvv.start_date_active, ld_sysdate) <= ld_sysdate
        AND  NVL(flvv.end_date_active, ld_sysdate)   >= ld_sysdate
        AND  flvv.lookup_code   = io_rp_qte_lst_dt_rec.quote_div;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_app_name             --アプリケーション短縮名
                   ,iv_name         => cv_tkn_number_03        --メッセージコード
                   ,iv_token_name1  => cv_tkn_param1           --トークンコード1
                   ,iv_token_value1 => cv_tkn_qt_div_nm        --トークン値1
                  );
        fnd_file.put_line(
          which  => FND_FILE.LOG
         ,buff   => lv_msg        ||cv_msg_prnthss_l||
                    cv_qt_line_id ||TO_CHAR(io_rp_qte_lst_dt_rec.quote_line_id)       ||cv_msg_comma||
                    cv_invntry_itm_id||TO_CHAR(io_rp_qte_lst_dt_rec.inventory_item_id)||cv_msg_comma||
                    cv_ln_ordr       ||TO_CHAR(io_rp_qte_lst_dt_rec.line_order)       ||cv_msg_prnthss_r
        );
        ov_retcode := cv_status_warn;
    END;
    -- ====================================
    -- 単価区分名取得(販売先)
    -- ====================================
    BEGIN
      SELECT flvv.meaning  meaning        -- 内容(単価区分名)
      INTO   lt_mean_unit_tp_2
      FROM   fnd_lookup_values_vl   flvv  -- クイックコード
            ,xxcso_quote_headers    xqh   -- 見積ヘッダーテーブル
      WHERE  flvv.lookup_type   = cv_lkup_tp_unt_prc_dvsn
        AND  flvv.enabled_flag  = cv_yes
        AND  NVL(flvv.start_date_active, ld_sysdate) <= ld_sysdate
        AND  NVL(flvv.end_date_active, ld_sysdate)   >= ld_sysdate
        AND  xqh.quote_number   = io_rp_qte_lst_dt_rec.reference_quote_number
        AND  xqh.unit_type      = flvv.lookup_code
        /* 2009.04.03 K.Satomura T_0301対応 START */
        AND  xqh.quote_revision_number =
        (
          SELECT MAX(xqh2.quote_revision_number)
          FROM   xxcso_quote_headers xqh2
          WHERE  xqh2.quote_number   = io_rp_qte_lst_dt_rec.reference_quote_number
        )
        /* 2009.04.03 K.Satomura T_0301対応 END */
        ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_app_name             --アプリケーション短縮名
                   ,iv_name         => cv_tkn_number_03        --メッセージコード
                   ,iv_token_name1  => cv_tkn_param1           --トークンコード1
                   ,iv_token_value1 => cv_tkn_unit_tp_nm_2     --トークン値1
                  );
        fnd_file.put_line(
          which  => FND_FILE.LOG
         ,buff   => lv_msg
        );
        ov_retcode := cv_status_warn;
    END;
    -- ====================================
    -- 内容量単位名取得
    -- ====================================
    BEGIN
      SELECT flvv.meaning  meaning       -- 内容(内容量単位名)
      INTO   lt_nets_uom_cd_nm
      FROM   fnd_lookup_values_vl flvv   -- クイックコード
     WHERE  flvv.lookup_type   = cv_lkup_tp_itm_nt_um_cd
        AND  flvv.enabled_flag  = cv_yes
        AND  NVL(flvv.start_date_active, ld_sysdate) <= ld_sysdate
        AND  NVL(flvv.end_date_active, ld_sysdate)   >= ld_sysdate
        AND  flvv.lookup_code   = lt_nets_uom_code;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_app_name             --アプリケーション短縮名
                   ,iv_name         => cv_tkn_number_03        --メッセージコード
                   ,iv_token_name1  => cv_tkn_param1           --トークンコード1
                   ,iv_token_value1 => cv_tkn_itm_nt_um_cd_nm  --トークン値1
                  );
        fnd_file.put_line(
          which  => FND_FILE.LOG
         ,buff   => lv_msg        ||cv_msg_prnthss_l||
                    cv_qt_line_id ||TO_CHAR(io_rp_qte_lst_dt_rec.quote_line_id)       ||cv_msg_comma||
                    cv_invntry_itm_id||TO_CHAR(io_rp_qte_lst_dt_rec.inventory_item_id)||cv_msg_comma||
                    cv_ln_ordr       ||TO_CHAR(io_rp_qte_lst_dt_rec.line_order)       ||cv_msg_prnthss_r
        );
        ov_retcode := cv_status_warn;
    END;

    -- ====================================
    -- 取得値をOUTパラメータに設定
    -- ====================================
    io_rp_qte_lst_dt_rec.customer_name     := NVL(io_rp_qte_lst_dt_rec.quote_submit_name,
                                                lt_party_name);                              -- 顧客名
    io_rp_qte_lst_dt_rec.sales_name        := lt_sales_name;                                 -- 販売先名
    /* 2009.05.13 K.Satomura T1_0972対応 START */
    --io_rp_qte_lst_dt_rec.base_addr         := lt_zip || cv_space || lt_address_line1;        -- 拠点住所
    io_rp_qte_lst_dt_rec.base_zip          := lt_zip;                                        -- 拠点郵便番号
    io_rp_qte_lst_dt_rec.base_addr         := lt_address_line1;                              -- 拠点住所
    /* 2009.05.13 K.Satomura T1_0972対応 END */
    io_rp_qte_lst_dt_rec.base_name         := lt_location_name;                              -- 拠点名
    io_rp_qte_lst_dt_rec.base_phone_no     := lt_phone;                                      -- 拠点電話番号
    io_rp_qte_lst_dt_rec.dliv_prce_tx_t_nm := lt_mean_dlv_prce_tx_tp;                        -- 店納価格税区分名
    io_rp_qte_lst_dt_rec.quote_unit_warehouse := lt_mean_unit_tp_1;                          -- 見積単位(帳合問屋)
    io_rp_qte_lst_dt_rec.quote_unit_sale      := lt_mean_unit_tp_2;                          -- 見積単位(販売先)
    io_rp_qte_lst_dt_rec.item_name         := lt_item_short_name;                            -- 商品名
    IF lt_jan_code IS NULL THEN
      io_rp_qte_lst_dt_rec.jan_code        := NULL;
    ELSE
      io_rp_qte_lst_dt_rec.jan_code        := cv_jan || SUBSTRB(lt_jan_code, 1, 7) ||
                                                cv_space || SUBSTRB(lt_jan_code, 8, 6);      -- JANコード
    END IF;
    io_rp_qte_lst_dt_rec.standards         := TO_CHAR(lt_nets, cv_fmt) || lt_nets_uom_cd_nm; -- 規格
    IF io_rp_qte_lst_dt_rec.unit_type = cv_unit_type_hs THEN
      io_rp_qte_lst_dt_rec.inc_num         := NVL(lt_case_inc_num, cv_zero);
    ELSIF io_rp_qte_lst_dt_rec.unit_type = cv_unit_type_cs THEN
      io_rp_qte_lst_dt_rec.inc_num         := NVL(lt_case_inc_num, cv_zero);
    ELSIF io_rp_qte_lst_dt_rec.unit_type = cv_unit_type_bl THEN
      io_rp_qte_lst_dt_rec.inc_num         := NVL(TO_CHAR(lt_bowl_inc_num), cv_zero);
    END IF;                                                                                  -- 入数
    io_rp_qte_lst_dt_rec.sticer_price      := NVL(lt_fixed_price_new, cv_zero);              -- メーカー希望小売価格
    io_rp_qte_lst_dt_rec.quote_div_nm      := lv_qt_div_nm;                                  -- 見積区分名
--
    -- 空行の挿入
    IF ov_retcode = cv_status_warn THEN
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => ''
      );
    END IF;

    /* 2009.06.17 D.Abe T1_1257対応 START */
    -- ====================================
    -- 入数チェック
    -- ====================================
    -- ケースの場合
    IF ((io_rp_qte_lst_dt_rec.unit_type = cv_unit_type_cs) AND
        (lt_case_inc_num IS NULL OR lt_case_inc_num = 0 )) THEN
      lv_msg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_app_name             --アプリケーション短縮名
                 ,iv_name         => cv_tkn_number_08        --メッセージコード
                 ,iv_token_name1  => cv_tkn_val              --トークンコード1
                 ,iv_token_value1 => io_rp_qte_lst_dt_rec.item_name  --トークン値1
                );
      ov_errmsg  := lv_msg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_msg,1,5000);
        ov_retcode := cv_status_error;
    -- ボールの場合
    ELSIF ((io_rp_qte_lst_dt_rec.unit_type = cv_unit_type_bl) AND
           (lt_bowl_inc_num IS NULL OR  lt_bowl_inc_num = 0)) THEN
      lv_msg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_app_name             --アプリケーション短縮名
                 ,iv_name         => cv_tkn_number_08        --メッセージコード
                 ,iv_token_name1  => cv_tkn_val              --トークンコード1
                 ,iv_token_value1 => io_rp_qte_lst_dt_rec.item_name  --トークン値1
                );
      ov_errmsg  := lv_msg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_msg,1,5000);
        ov_retcode := cv_status_error;
    END IF;                                                                                  -- 入数
    /* 2009.06.17 D.Abe T1_1257対応 END */
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END process_data;
--
  /**********************************************************************************
   * Procedure Name   : insert_row
   * Description      : ワークテーブル出力(A-4)
   ***********************************************************************************/
  PROCEDURE insert_row(
     i_rp_qte_lst_data_rec  IN  g_rp_qte_lst_data_rtype  -- 見積データ
    ,ov_errbuf              OUT NOCOPY VARCHAR2          -- エラー・メッセージ            --# 固定 #
    ,ov_retcode             OUT NOCOPY VARCHAR2          -- リターン・コード              --# 固定 #
    ,ov_errmsg              OUT NOCOPY VARCHAR2          -- ユーザー・エラー・メッセージ  --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'insert_row';     -- プログラム名
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
    cv_tkn_tbl_nm         CONSTANT VARCHAR2(100) := '見積帳票ワークテーブルの登録';
    -- *** ローカル例外 ***
    insert_row_expt     EXCEPTION;          -- ワークテーブル出力処理例外
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ======================
    -- CSV出力処理 
    -- ======================
    BEGIN
      -- ワークテーブル出力
      INSERT INTO xxcso_rep_quote_list
        ( quote_work_id                -- 見積帳票ワークテーブルＩＤ
         ,quote_header_id              -- 見積ヘッダーＩＤ
         ,line_order                   -- 並び順
         ,quote_line_id                -- 見積明細ＩＤ
         ,quote_number                 -- 見積番号
         ,publish_date                 -- 発行日
         ,customer_name                -- 顧客名
         ,sales_name                   -- 販売先名
         ,deliv_place                  -- 納入場所
         ,header_payment_condition     -- ヘッダー支払条件
         /* 2009.05.13 K.Satomura T1_0972対応 START */
         ,base_zip                     -- 拠点郵便番号
         /* 2009.05.13 K.Satomura T1_0972対応 END */
         ,base_addr                    -- 拠点住所
         ,base_name                    -- 拠点名
         ,base_phone_no                -- 拠点電話番号
         ,quote_unit_sale              -- 見積単位(販売先)
         ,quote_unit_warehouse         -- 見積単位(帳合問屋)
         ,deliv_price_tax_type         -- 店納価格税区分
         ,special_note                 -- 特記事項
         ,item_name                    -- 商品名
         ,jan_code                     -- JANコード
         ,standard                     -- 規格
         ,inc_num                      -- 入数 
         ,sticer_price                 -- メーカー希望小売価格
         ,quote_div                    -- 見積区分名
         ,quotation_price              -- 建値
         ,usually_deliv_price          -- 通常店納価格
         ,this_time_deliv_price        -- 今回店納価格
         ,usuall_net_price             -- 通常ＮＥＴ価格
         ,this_time_net_price          -- 今回ＮＥＴ価格
         ,line_payment_condition       -- 明細支払条件
         ,amount_of_margin             -- マージン額
         ,margin_rate                  -- マージン率
         ,quote_start_date             -- 期間（開始）
         ,quote_end_date               -- 期間（終了）
         ,sales_discount_amt           -- 売上値引
         ,remarks                      -- 備考
         ,created_by                   -- 作成者
         ,creation_date                -- 作成日
         ,last_updated_by              -- 最終更新者
         ,last_update_date             -- 最終更新日
         ,last_update_login            -- 最終更新ログイン
         ,request_id                   -- 要求ｉｄ        
         ,program_application_id       -- ｺﾝｶﾚﾝﾄﾌﾟﾛｸﾞﾗﾑｱﾌﾟﾘｹｰｼｮﾝ
         ,program_id                   -- ｺﾝｶﾚﾝﾄﾌﾟﾛｸﾞﾗﾑｉｄ
         ,program_update_date          -- ﾌﾟﾛｸﾞﾗﾑ更新日
        )
      VALUES
        ( xxcso_rep_quote_list_s01.NEXTVAL                     -- 見積帳票ワークテーブルＩＤ
         ,i_rp_qte_lst_data_rec.quote_header_id                -- 見積ヘッダーＩＤ
         ,i_rp_qte_lst_data_rec.line_order                     -- 並び順
         ,i_rp_qte_lst_data_rec.quote_line_id                  -- 見積明細ＩＤ
         ,i_rp_qte_lst_data_rec.quote_number                   -- 見積番号
         ,i_rp_qte_lst_data_rec.publish_date                   -- 発行日
         ,i_rp_qte_lst_data_rec.customer_name                  -- 顧客名
         ,i_rp_qte_lst_data_rec.sales_name                     -- 販売先名
         ,i_rp_qte_lst_data_rec.deliv_place                    -- 納入場所
         ,i_rp_qte_lst_data_rec.header_payment_condition       -- ヘッダー支払条件
         /* 2009.05.13 K.Satomura T1_0972対応 START */
         ,i_rp_qte_lst_data_rec.base_zip                       -- 拠点郵便番号
         /* 2009.05.13 K.Satomura T1_0972対応 END */
         ,i_rp_qte_lst_data_rec.base_addr                      -- 拠点住所
         ,i_rp_qte_lst_data_rec.base_name                      -- 拠点名
         ,i_rp_qte_lst_data_rec.base_phone_no                  -- 拠点電話番号
         ,i_rp_qte_lst_data_rec.quote_unit_sale                -- 見積単位(販売先)
         ,i_rp_qte_lst_data_rec.quote_unit_warehouse           -- 見積単位(帳合問屋)
         ,i_rp_qte_lst_data_rec.dliv_prce_tx_t_nm              -- 店納価格税区分名
         ,i_rp_qte_lst_data_rec.special_note                   -- 特記事項
         ,i_rp_qte_lst_data_rec.item_name                      -- 商品名
         ,i_rp_qte_lst_data_rec.jan_code                       -- JANコード
         ,i_rp_qte_lst_data_rec.standards                      -- 規格
         ,i_rp_qte_lst_data_rec.inc_num                        -- 入数
         ,i_rp_qte_lst_data_rec.sticer_price                   -- メーカー希望小売価格
         ,i_rp_qte_lst_data_rec.quote_div_nm                   -- 見積区分名
         ,i_rp_qte_lst_data_rec.quotation_price                -- 建値
         ,i_rp_qte_lst_data_rec.usually_deliv_price            -- 通常店納価格
         ,i_rp_qte_lst_data_rec.this_time_deliv_price          -- 今回店納価格
         ,i_rp_qte_lst_data_rec.usuall_net_price               -- 通常ＮＥＴ価格
         ,i_rp_qte_lst_data_rec.this_time_net_price            -- 今回ＮＥＴ価格
         ,i_rp_qte_lst_data_rec.line_payment_condition         -- 明細支払条件
         ,i_rp_qte_lst_data_rec.amount_of_margin               -- マージン額
         ,i_rp_qte_lst_data_rec.margin_rate                    -- マージン率
         ,i_rp_qte_lst_data_rec.quote_start_date               -- 期間（開始）
         ,i_rp_qte_lst_data_rec.quote_end_date                 -- 期間（終了）
         ,i_rp_qte_lst_data_rec.sales_discount_amt             -- 売上値引
         ,i_rp_qte_lst_data_rec.remarks                        -- 備考
         ,i_rp_qte_lst_data_rec.created_by                     -- 作成者
         ,i_rp_qte_lst_data_rec.creation_date                  -- 作成日
         ,i_rp_qte_lst_data_rec.last_updated_by                -- 最終更新者
         ,i_rp_qte_lst_data_rec.last_update_date               -- 最終更新日
         ,i_rp_qte_lst_data_rec.last_update_login              -- 最終更新ログイン
         ,i_rp_qte_lst_data_rec.request_id                     -- 要求ＩＤ
         ,i_rp_qte_lst_data_rec.program_application_id         -- ｺﾝｶﾚﾝﾄﾌﾟﾛｸﾞﾗﾑｱﾌﾟﾘｹｰｼｮﾝ
         ,i_rp_qte_lst_data_rec.program_id                     -- ｺﾝｶﾚﾝﾄﾌﾟﾛｸﾞﾗﾑＩＤ
         ,i_rp_qte_lst_data_rec.program_update_date            -- ﾌﾟﾛｸﾞﾗﾑ更新日
        );
--
    EXCEPTION
      WHEN OTHERS THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_app_name             --アプリケーション短縮名
                 ,iv_name         => cv_tkn_number_04        --メッセージコード
                 ,iv_token_name1  => cv_tkn_act              --トークンコード1
                 ,iv_token_value1 => cv_tkn_tbl_nm           --トークン値1
                 ,iv_token_name2  => cv_tkn_errmsg           --トークンコード2
                 ,iv_token_value2 => SQLERRM                 --トークン値2
                );
        lv_errbuf := lv_errmsg || SQLERRM;
        RAISE insert_row_expt;
    END;
--
  EXCEPTION
    -- *** ワークテーブル出力処理例外 ***
    WHEN insert_row_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END insert_row;
--
  /**********************************************************************************
   * Procedure Name   : insert_blanks
   * Description      : ワークテーブル(空行)出力(A-5)
   ***********************************************************************************/
  PROCEDURE insert_blanks(
     i_rp_qte_lst_data_rec  IN  g_rp_qte_lst_data_rtype  -- 見積データ     
    ,ov_errbuf              OUT NOCOPY VARCHAR2          -- エラー・メッセージ            --# 固定 #
    ,ov_retcode             OUT NOCOPY VARCHAR2          -- リターン・コード              --# 固定 #
    ,ov_errmsg              OUT NOCOPY VARCHAR2          -- ユーザー・エラー・メッセージ  --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'insert_blanks';     -- プログラム名
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
    cv_tkn_tbl_nm         CONSTANT VARCHAR2(100) := '見積帳票ワークテーブル(空行)の登録';
    -- *** ローカル例外 ***
    insert_blanks_expt     EXCEPTION;          -- ワークテーブル出力処理例外
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ======================
    -- CSV出力処理 
    -- ======================
    BEGIN
      -- ワークテーブル出力
      INSERT INTO xxcso_rep_quote_list
        ( quote_work_id                -- 見積帳票ワークテーブルＩＤ
         ,quote_header_id              -- 見積ヘッダーＩＤ
         ,quote_line_id                -- 見積明細ＩＤ 
         ,quote_number                 -- 見積番号
         ,publish_date                 -- 発行日
         ,customer_name                -- 顧客名
         ,sales_name                   -- 販売先名
         ,deliv_place                  -- 納入場所
         ,header_payment_condition     -- ヘッダー支払条件
         /* 2009.05.13 K.Satomura T1_0972対応 START */
         ,base_zip                     -- 拠点郵便番号
         /* 2009.05.13 K.Satomura T1_0972対応 END */
         ,base_addr                    -- 拠点住所
         ,base_name                    -- 拠点名
         ,base_phone_no                -- 拠点電話番号
         ,quote_unit_sale              -- 見積単位(販売先)
         ,quote_unit_warehouse         -- 見積単位(帳合問屋)
         ,deliv_price_tax_type         -- 店納価格税区分
         ,special_note                 -- 特記事項
         ,created_by                   -- 作成者
         ,creation_date                -- 作成日
         ,last_updated_by              -- 最終更新者
         ,last_update_date             -- 最終更新日
         ,last_update_login            -- 最終更新ログイン
         ,request_id                   -- 要求ＩＤ        
         ,program_application_id       -- ｺﾝｶﾚﾝﾄﾌﾟﾛｸﾞﾗﾑｱﾌﾟﾘｹｰｼｮﾝ
         ,program_id                   -- ｺﾝｶﾚﾝﾄﾌﾟﾛｸﾞﾗﾑＩＤ
         ,program_update_date          -- ﾌﾟﾛｸﾞﾗﾑ更新日
        )
      VALUES
        ( xxcso_rep_quote_list_s01.NEXTVAL                     -- 見積帳票ワークテーブルＩＤ
         ,i_rp_qte_lst_data_rec.quote_header_id                -- 見積ヘッダーＩＤ
         ,i_rp_qte_lst_data_rec.quote_line_id                  -- 見積明細ＩＤ
         ,i_rp_qte_lst_data_rec.quote_number                   -- 見積番号
         ,i_rp_qte_lst_data_rec.publish_date                   -- 発行日
         ,i_rp_qte_lst_data_rec.customer_name                  -- 顧客名
         ,i_rp_qte_lst_data_rec.sales_name                     -- 販売先名
         ,i_rp_qte_lst_data_rec.deliv_place                    -- 納入場所
         ,i_rp_qte_lst_data_rec.header_payment_condition       -- ヘッダー支払条件
         /* 2009.05.13 K.Satomura T1_0972対応 START */
         ,i_rp_qte_lst_data_rec.base_zip                       -- 拠点郵便番号
         /* 2009.05.13 K.Satomura T1_0972対応 END */
         ,i_rp_qte_lst_data_rec.base_addr                      -- 拠点住所
         ,i_rp_qte_lst_data_rec.base_name                      -- 拠点名
         ,i_rp_qte_lst_data_rec.base_phone_no                  -- 拠点電話番号
         ,i_rp_qte_lst_data_rec.quote_unit_sale                -- 見積単位(販売先)
         ,i_rp_qte_lst_data_rec.quote_unit_warehouse           -- 見積単位(帳合問屋)
         ,i_rp_qte_lst_data_rec.dliv_prce_tx_t_nm              -- 店納価格税区分名
         ,i_rp_qte_lst_data_rec.special_note                   -- 特記事項
         ,i_rp_qte_lst_data_rec.created_by                     -- 作成者
         ,i_rp_qte_lst_data_rec.creation_date                  -- 作成日
         ,i_rp_qte_lst_data_rec.last_updated_by                -- 最終更新者
         ,i_rp_qte_lst_data_rec.last_update_date               -- 最終更新日
         ,i_rp_qte_lst_data_rec.last_update_login              -- 最終更新ログイン
         ,i_rp_qte_lst_data_rec.request_id                     -- 要求ＩＤ
         ,i_rp_qte_lst_data_rec.program_application_id         -- ｺﾝｶﾚﾝﾄﾌﾟﾛｸﾞﾗﾑｱﾌﾟﾘｹｰｼｮﾝ
         ,i_rp_qte_lst_data_rec.program_id                     -- ｺﾝｶﾚﾝﾄﾌﾟﾛｸﾞﾗﾑＩＤ
         ,i_rp_qte_lst_data_rec.program_update_date            -- ﾌﾟﾛｸﾞﾗﾑ更新日
        );
--
    EXCEPTION
      WHEN OTHERS THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_app_name             --アプリケーション短縮名
                 ,iv_name         => cv_tkn_number_04        --メッセージコード
                 ,iv_token_name1  => cv_tkn_act              --トークンコード1
                 ,iv_token_value1 => cv_tkn_tbl_nm           --トークン値1
                 ,iv_token_name2  => cv_tkn_errmsg           --トークンコード2
                 ,iv_token_value2 => SQLERRM                 --トークン値2
                );
        lv_errbuf := lv_errmsg || SQLERRM;
        RAISE insert_blanks_expt;
    END;
--
  EXCEPTION
    -- *** ワークテーブル出力処理例外 ***
    WHEN insert_blanks_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END insert_blanks;
--
  /**********************************************************************************
   * Procedure Name   : act_svf
   * Description      : SVF起動(A-6)
   ***********************************************************************************/
  PROCEDURE act_svf(
     ov_errbuf              OUT NOCOPY VARCHAR2          -- エラー・メッセージ            --# 固定 #
    ,ov_retcode             OUT NOCOPY VARCHAR2          -- リターン・コード              --# 固定 #
    ,ov_errmsg              OUT NOCOPY VARCHAR2          -- ユーザー・エラー・メッセージ  --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'act_svf';     -- プログラム名
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
    cv_tkn_api_nm_svf CONSTANT  VARCHAR2(20) := 'SVF起動';
    cv_svf_form_name  CONSTANT  VARCHAR2(20) := 'XXCSO017A04S.xml';  -- フォーム様式ファイル名
    cv_svf_query_name CONSTANT  VARCHAR2(20) := 'XXCSO017A04S.vrq';  -- クエリー様式ファイル名
    cv_output_mode    CONSTANT  VARCHAR2(1)  := '1';  
    -- *** ローカル変数 ***
    lv_svf_file_name   VARCHAR2(50);
    lv_file_id         VARCHAR2(30)  := NULL;
    lv_conc_name       VARCHAR2(30)  := NULL;
    lv_user_name       VARCHAR2(240) := NULL;
    lv_resp_name       VARCHAR2(240) := NULL;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ======================
    -- SVF起動処理 
    -- ======================
    -- ファイル名の設定
    lv_svf_file_name := cv_pkg_name
                     || TO_CHAR (cd_creation_date, cv_format_date_ymd1)
                     || TO_CHAR (cn_request_id);
--
    BEGIN
      SELECT  user_concurrent_program_name,
              xx00_global_pkg.user_name   ,
              xx00_global_pkg.resp_name
      INTO    lv_conc_name,
              lv_user_name,
              lv_resp_name
      FROM    fnd_concurrent_programs_tl
      WHERE   concurrent_program_id =cn_request_id
      AND     LANGUAGE = 'JA'
      ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_conc_name := cv_pkg_name;
    END;
--
    lv_file_id := cv_pkg_name;
--
    xxccp_svfcommon_pkg.submit_svf_request(
      ov_errbuf       => lv_errbuf             -- エラー・メッセージ           --# 固定 #
     ,ov_retcode      => lv_retcode            -- リターン・コード             --# 固定 #
     ,ov_errmsg       => lv_errmsg             -- ユーザー・エラー・メッセージ --# 固定 #
     ,iv_conc_name    => lv_conc_name          -- コンカレント名
     ,iv_file_name    => lv_svf_file_name      -- 出力ファイル名
     ,iv_file_id      => lv_file_id            -- 帳票ID
     ,iv_output_mode  => cv_output_mode        -- 出力区分(=1：PDF出力）
     ,iv_frm_file     => cv_svf_form_name      -- フォーム様式ファイル名
     ,iv_vrq_file     => cv_svf_query_name     -- クエリー様式ファイル名
     ,iv_org_id       => fnd_global.org_id     -- ORG_ID
     ,iv_user_name    => lv_user_name          -- ログイン・ユーザ名
     ,iv_resp_name    => lv_resp_name          -- ログイン・ユーザの職責名
     ,iv_doc_name     => NULL                  -- 文書名
     ,iv_printer_name => NULL                  -- プリンタ名
     ,iv_request_id   => cn_request_id         -- 要求ID
     ,iv_nodata_msg   => NULL                  -- データなしメッセージ
     );
--
    -- SVF起動APIの呼び出しはエラーか
    IF (lv_retcode <> cv_status_normal) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_app_name             --アプリケーション短縮名
                 ,iv_name         => cv_tkn_number_06        --メッセージコード
                 ,iv_token_name1  => cv_tkn_api_nm           --トークンコード1
                 ,iv_token_value1 => cv_tkn_api_nm_svf       --トークン値1
                );
      lv_errbuf := lv_errmsg || SQLERRM;
      RAISE global_api_expt;
    END IF;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END act_svf;
--
  /**********************************************************************************
   * Procedure Name   : delete_row
   * Description      : ワークテーブルデータ削除(A-7)
   ***********************************************************************************/
  PROCEDURE delete_row(
     ov_errbuf              OUT NOCOPY VARCHAR2          -- エラー・メッセージ            --# 固定 #
    ,ov_retcode             OUT NOCOPY VARCHAR2          -- リターン・コード              --# 固定 #
    ,ov_errmsg              OUT NOCOPY VARCHAR2          -- ユーザー・エラー・メッセージ  --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'delete_row';     -- プログラム名
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
    cv_tkn_tbl_nm         CONSTANT VARCHAR2(100) := '見積帳票ワークテーブル';
    -- *** ローカル変数 ***
    lt_quote_work_id      xxcso_rep_quote_list.quote_work_id%TYPE;  -- 見積帳票ワークテーブルＩＤ格納用
    -- *** ローカル例外 ***
    tbl_lock_expt  EXCEPTION;  -- テーブルロックエラー
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ==========================
    -- ロックの確認
    -- ==========================
    BEGIN
      SELECT xrql.quote_work_id  quote_work_id  -- 見積帳票ワークテーブルＩＤ
      INTO   lt_quote_work_id
      FROM   xxcso_rep_quote_list  xrql         -- 見積帳票ワークテーブル
      WHERE  xrql.request_id = cn_request_id
        AND  ROWNUM = 1
      FOR UPDATE NOWAIT;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_app_name             --アプリケーション短縮名
                   ,iv_name         => cv_tkn_number_05        --メッセージコード
                   ,iv_token_name1  => cv_tkn_tbl              --トークンコード1
                   ,iv_token_value1 => cv_tkn_tbl_nm           --トークン値1
                   ,iv_token_name2  => cv_tkn_err_msg          --トークンコード2
                   ,iv_token_value2 => SQLERRM                 --トークン値2
                  );
        lv_errbuf := lv_errmsg || SQLERRM;
        RAISE tbl_lock_expt;
    END;
    -- ==========================
    -- ワークテーブルデータ削除
    -- ==========================
    DELETE FROM xxcso_rep_quote_list xrql -- 見積帳票ワークテーブル
    WHERE xrql.request_id = cn_request_id;
--
  EXCEPTION
    -- *** テーブルロックエラー ***
    WHEN tbl_lock_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END delete_row;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   ***********************************************************************************/
  PROCEDURE submain(
     in_qt_hdr_id        IN  NUMBER            -- 見積ヘッダーID
    ,ov_errbuf           OUT NOCOPY VARCHAR2   -- エラー・メッセージ            --# 固定 #
    ,ov_retcode          OUT NOCOPY VARCHAR2   -- リターン・コード              --# 固定 #
    ,ov_errmsg           OUT NOCOPY VARCHAR2   -- ユーザー・エラー・メッセージ  --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'submain';     -- プログラム名
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
    cv_tkn_qt_info    CONSTANT VARCHAR2(100) := '見積情報';
    cv_zero           CONSTANT VARCHAR2(1)   := '0';
    cv_prcntg         CONSTANT VARCHAR2(1)   := '%';
    -- 空行出力処理用
    cn_page_cnt1      CONSTANT NUMBER  := 1;
    cn_rec_cnt1       CONSTANT NUMBER  := 1;
    cn_rec_cnt14      CONSTANT NUMBER  := 14;
    cn_rec_cnt15      CONSTANT NUMBER  := 15;
    cn_rec_cnt16      CONSTANT NUMBER  := 16;
    cn_rec_cnt21      CONSTANT NUMBER  := 21;
    cn_rec_cnt22      CONSTANT NUMBER  := 22;
    cn_rec_cnt24      CONSTANT NUMBER  := 24;
    cn_rec_cnt37      CONSTANT NUMBER  := 37;
    cn_rec_cnt45      CONSTANT NUMBER  := 45;
    -- IN,OUTパラメータ格納用
    ln_qt_hdr_id      NUMBER;         -- INパラメータ見積ヘッダーＩＤ
    -- *** ローカル変数 ***
    ln_ins_cnt        NUMBER DEFAULT 0;         -- カウンタ
    ln_rec_num        NUMBER DEFAULT 0;         -- 空行出力用レコードカウンタ格納用
    ln_loop_cnt       NUMBER DEFAULT 0;         -- 空行出力用loopカウンタ
    lt_quote_number   xxcso_quote_headers.quote_number%TYPE; -- 見積番号格納用
    -- SVF起動API戻り値格納用
    lv_errbuf_svf     VARCHAR2(5000);           -- エラー・メッセージ
    lv_retcode_svf    VARCHAR2(1);              -- リターン・コード
    lv_errmsg_svf     VARCHAR2(5000);           -- ユーザー・エラー・メッセージ
--
    -- *** ローカル・カーソル ***
    -- 見積データ抽出カーソル
    CURSOR get_quote_data_cur
    IS
      SELECT  xqh.quote_header_id              quote_header_id           -- 見積ヘッダーＩＤ
              ,xqh.quote_number                quote_number              -- 見積番号
              ,xqh.reference_quote_number      reference_quote_number    -- 参照用見積番号
              ,xqh.publish_date                publish_date              -- 発行日
              ,xqh.account_number              account_number            -- 顧客コード
              ,xqh.base_code                   base_code                 -- 拠点コード
              ,xqh.deliv_place                 deliv_place               -- 納入場所
              ,xqh.payment_condition           payment_condition         -- 支払条件
              ,xqh.special_note                special_note              -- 特記事項
              ,xqh.deliv_price_tax_type        deliv_price_tax_type      -- 店納価格税区分
              ,xqh.unit_type                   unit_type                 -- 単価区分
              ,xqh.quote_submit_name           quote_submit_name         -- 見積書提出先名
              ,xql.quote_line_id               quote_line_id             -- 見積明細ＩＤ
              ,xql.inventory_item_id           inventory_item_id         -- 品目ＩＤ
              ,xql.quote_div                   quote_div                 -- 見積区分
              ,xql.quotation_price             quotation_price           -- 建値
              ,xql.usually_deliv_price         usually_deliv_price       -- 通常店納価格
              ,xql.this_time_deliv_price       this_time_deliv_price     -- 今回店納価格
              ,xql.usuall_net_price            usuall_net_price          -- 通常ＮＥＴ価格
              ,xql.this_time_net_price         this_time_net_price       -- 今回ＮＥＴ価格
              ,xql.amount_of_margin            amount_of_margin          -- マージン額
              ,xql.margin_rate                 margin_rate               -- マージン率
              ,xql.quote_start_date            quote_start_date          -- 期間（開始）
              ,xql.quote_end_date              quote_end_date            -- 期間（終了）
              ,xql.sales_discount_price        sales_discount_price      -- 売上値引
              ,xql.remarks                     remarks                   -- 備考
              ,xql.line_order                  line_order                -- 並び順
      FROM  xxcso_quote_headers  xqh   -- 見積ヘッダーテーブル
           ,xxcso_quote_lines    xql   -- 見積明細テーブル
      WHERE  xqh.quote_header_id = ln_qt_hdr_id
        AND  xqh.quote_header_id = xql.quote_header_id
      ORDER BY  xql.line_order        -- 並び順
               ,xql.quote_line_id     -- 見積明細ＩＤ
      ;
--
    -- *** ローカル・レコード ***
    l_get_quote_dt_rec     get_quote_data_cur%ROWTYPE;
    l_rp_qte_lst_data_rec  g_rp_qte_lst_data_rtype;
    -- *** ローカル・例外 ***
    no_data_expt           EXCEPTION; -- 対象データ0件例外
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
--
    -- カウンタの初期化
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    ln_ins_cnt    := 0;
    -- INパラメータ格納
    ln_qt_hdr_id := in_qt_hdr_id;  -- INパラメータ見積ヘッダーＩＤ
--
    -- ========================================
    -- A-1.パラメータ・チェック
    -- ========================================
    chk_param(
      in_qt_hdr_id     => ln_qt_hdr_id        -- 見積ヘッダーID
     ,ov_errbuf        => lv_errbuf           -- エラー・メッセージ            --# 固定 #
     ,ov_retcode       => lv_retcode          -- リターン・コード              --# 固定 #
     ,ov_errmsg        => lv_errmsg           -- ユーザー・エラー・メッセージ  --# 固定 #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
    -- ========================================
    -- A-2.データ取得
    -- ========================================
    -- カーソルオープン
    OPEN get_quote_data_cur;
--
    <<get_quote_data_loop>>
    LOOP
      FETCH get_quote_data_cur INTO l_get_quote_dt_rec;
      -- 処理対象件数格納
      gn_target_cnt := get_quote_data_cur%ROWCOUNT;
--
      -- 処理対象データが存在しなかった場合EXIT
      EXIT WHEN get_quote_data_cur%NOTFOUND
      OR  get_quote_data_cur%ROWCOUNT = 0;
--
      -- レコード変数初期化
      l_rp_qte_lst_data_rec := NULL;
--
      -- 取得データを格納
      l_rp_qte_lst_data_rec.quote_header_id          := l_get_quote_dt_rec.quote_header_id;           -- 見積ヘッダーＩＤ
      l_rp_qte_lst_data_rec.line_order               := l_get_quote_dt_rec.line_order;                -- 並び順
      l_rp_qte_lst_data_rec.quote_line_id            := l_get_quote_dt_rec.quote_line_id;             -- 見積明細ＩＤ 
      l_rp_qte_lst_data_rec.quote_number             := l_get_quote_dt_rec.quote_number;              -- 見積番号
      l_rp_qte_lst_data_rec.reference_quote_number   := l_get_quote_dt_rec.reference_quote_number;    -- 参照用見積番号
      l_rp_qte_lst_data_rec.publish_date             := TO_CHAR(l_get_quote_dt_rec.publish_date
                                                          ,cv_format_date_ymd1);                      -- 発行日
      l_rp_qte_lst_data_rec.account_number           := l_get_quote_dt_rec.account_number;            -- 顧客コード
      l_rp_qte_lst_data_rec.deliv_place              := l_get_quote_dt_rec.deliv_place;               -- 納入場所
      l_rp_qte_lst_data_rec.header_payment_condition := l_get_quote_dt_rec.payment_condition;         -- ヘッダー支払条件
      l_rp_qte_lst_data_rec.base_code                := l_get_quote_dt_rec.base_code;                 -- 拠点コード
      l_rp_qte_lst_data_rec.unit_type                := l_get_quote_dt_rec.unit_type;                 -- 単価区分
      l_rp_qte_lst_data_rec.quote_submit_name        := l_get_quote_dt_rec.quote_submit_name;         -- 見積書提出先名
      l_rp_qte_lst_data_rec.dliv_prce_tx_t           := l_get_quote_dt_rec.deliv_price_tax_type;      -- 店納価格税区分
      l_rp_qte_lst_data_rec.special_note             := l_get_quote_dt_rec.special_note;              -- 特記事項
      l_rp_qte_lst_data_rec.inventory_item_id        := l_get_quote_dt_rec.inventory_item_id;         -- 品目ＩＤ
      l_rp_qte_lst_data_rec.quote_div                := l_get_quote_dt_rec.quote_div;                 -- 見積区分
      l_rp_qte_lst_data_rec.quotation_price          := l_get_quote_dt_rec.quotation_price;           -- 建値
      l_rp_qte_lst_data_rec.usually_deliv_price      := l_get_quote_dt_rec.usually_deliv_price;       -- 通常店納価格
      l_rp_qte_lst_data_rec.this_time_deliv_price    := l_get_quote_dt_rec.this_time_deliv_price;     -- 今回店納価格
      l_rp_qte_lst_data_rec.usuall_net_price         := l_get_quote_dt_rec.usuall_net_price;          -- 通常ＮＥＴ価格
      l_rp_qte_lst_data_rec.this_time_net_price      := l_get_quote_dt_rec.this_time_net_price;       -- 今回ＮＥＴ価格
/* 2009.06.17 D.Abe T1_1257対応 START */
      -- 今回ＮＥＴ価格が0より大きい場合
      --IF (l_get_quote_dt_rec.this_time_net_price > 0) THEN
      --  l_rp_qte_lst_data_rec.line_payment_condition   := l_get_quote_dt_rec.quotation_price
      --                                                      - l_get_quote_dt_rec.this_time_net_price;
      ---- 今回ＮＥＴ価格が0以下の場合
      --ELSIF (l_get_quote_dt_rec.this_time_net_price <= 0) THEN
      --  -- 通常ＮＥＴ価格が0より大きい場合
      --  IF (l_get_quote_dt_rec.usuall_net_price > 0) THEN
      --    l_rp_qte_lst_data_rec.line_payment_condition   := l_get_quote_dt_rec.quotation_price
      --                                                        - l_get_quote_dt_rec.usuall_net_price;
      --  -- 通常ＮＥＴ価格が0以下の場合
      --  ELSIF (l_get_quote_dt_rec.usuall_net_price <= 0) THEN
      --    l_rp_qte_lst_data_rec.line_payment_condition   := l_get_quote_dt_rec.quotation_price - 0;
      --  END IF;
      --END IF; -- 明細支払条件
/* 2009.06.17 D.Abe T1_1257対応 END */
      --
      l_rp_qte_lst_data_rec.amount_of_margin         := NVL(l_get_quote_dt_rec.amount_of_margin, 0);  -- マージン額
      l_rp_qte_lst_data_rec.margin_rate              := NVL(TO_CHAR(l_get_quote_dt_rec.margin_rate), cv_zero)
                                                          || cv_prcntg;                               -- マージン率
      --
      l_rp_qte_lst_data_rec.quote_start_date         := TO_CHAR(l_get_quote_dt_rec.quote_start_date
                                                          ,cv_format_date_ymd2);                      -- 期間（開始）
      l_rp_qte_lst_data_rec.quote_end_date           := TO_CHAR(l_get_quote_dt_rec.quote_end_date
                                                          ,cv_format_date_ymd2);                      -- 期間（終了）
/* 2009.07.30 D.Abe 0000806対応 START */
      --l_rp_qte_lst_data_rec.sales_discount_amt       := l_get_quote_dt_rec.sales_discount_price;      -- 売上値引
      l_rp_qte_lst_data_rec.sales_discount_amt       := TO_CHAR(l_get_quote_dt_rec.sales_discount_price,'FM99,990.00');      -- 売上値引
/* 2009.07.30 D.Abe 0000806対応 END */
      l_rp_qte_lst_data_rec.remarks                  := l_get_quote_dt_rec.remarks;                   -- 備考
      l_rp_qte_lst_data_rec.created_by               := cn_created_by;                                -- 作成者
      l_rp_qte_lst_data_rec.creation_date            := cd_creation_date;                             -- 作成日
      l_rp_qte_lst_data_rec.last_updated_by          := cn_last_updated_by;                           -- 最終更新者
      l_rp_qte_lst_data_rec.last_update_date         := cd_last_update_date;                          -- 最終更新日
      l_rp_qte_lst_data_rec.last_update_login        := cn_last_update_login;                         -- 最終更新ログイン
      l_rp_qte_lst_data_rec.request_id               := cn_request_id;                                -- 要求ＩＤ
      l_rp_qte_lst_data_rec.program_application_id   := cn_program_application_id;                    -- ｺﾝｶﾚﾝﾄﾌﾟﾛｸﾞﾗﾑｱﾌﾟﾘｹｰｼｮﾝ
      l_rp_qte_lst_data_rec.program_id               := cn_program_id;                                -- ｺﾝｶﾚﾝﾄﾌﾟﾛｸﾞﾗﾑＩＤ
      l_rp_qte_lst_data_rec.program_update_date      := cd_program_update_date;                       -- ﾌﾟﾛｸﾞﾗﾑ更新日
--
      -- ========================================
      -- A-3.加工処理
      -- ========================================
      process_data(
        io_rp_qte_lst_dt_rec   => l_rp_qte_lst_data_rec  -- 見積データ
       ,ov_errbuf              => lv_errbuf              -- エラー・メッセージ            --# 固定 #
       ,ov_retcode             => lv_retcode             -- リターン・コード              --# 固定 #
       ,ov_errmsg              => lv_errmsg              -- ユーザー・エラー・メッセージ  --# 固定 #
      );
--
      IF (lv_retcode = cv_status_warn) THEN
        -- エラー件数カウント
        gn_error_cnt := gn_error_cnt + 1;
        -- リターンコードに警告を設定
        ov_retcode := cv_status_warn;
      ELSIF (lv_retcode = cv_status_error) THEN
        RAISE global_process_expt;
/* 2009.06.17 D.Abe T1_1257対応 START */
      ELSE
        -- 支払条件の修正
        IF (l_get_quote_dt_rec.unit_type = cv_unit_type_hs) THEN
          -- 今回ＮＥＴ価格が0より大きい場合
          IF (l_get_quote_dt_rec.this_time_net_price > 0) THEN
            l_rp_qte_lst_data_rec.line_payment_condition   := l_get_quote_dt_rec.quotation_price
                                                                - l_get_quote_dt_rec.this_time_net_price;
          -- 今回ＮＥＴ価格が0以下の場合
          /* 2009.07.30 D.Abe 0000806対応 START */
          ELSE
--          ELSIF (l_get_quote_dt_rec.this_time_net_price <= 0) THEN
          /* 2009.07.30 D.Abe 0000806対応 END */

            -- 通常ＮＥＴ価格が0より大きい場合
            IF (l_get_quote_dt_rec.usuall_net_price > 0) THEN
              l_rp_qte_lst_data_rec.line_payment_condition   := l_get_quote_dt_rec.quotation_price
                                                                  - l_get_quote_dt_rec.usuall_net_price;
            -- 通常ＮＥＴ価格が0以下の場合
            ELSIF (l_get_quote_dt_rec.usuall_net_price <= 0) THEN
              l_rp_qte_lst_data_rec.line_payment_condition   := l_get_quote_dt_rec.quotation_price - 0;
            END IF;
          END IF; -- 明細支払条件
        ELSE
          -- 今回ＮＥＴ価格が0より大きい場合
          IF (l_get_quote_dt_rec.this_time_net_price > 0) THEN
            /* 2009.12.16 D.Abe E_本稼動_00501対応 START */
            --l_rp_qte_lst_data_rec.line_payment_condition   := l_get_quote_dt_rec.quotation_price
            l_rp_qte_lst_data_rec.line_payment_condition   := (l_get_quote_dt_rec.quotation_price / 
                                                                  l_rp_qte_lst_data_rec.inc_num)
            /* 2009.12.16 D.Abe E_本稼動_00501対応 END */
                                                                - (l_get_quote_dt_rec.this_time_net_price / 
                                                                  l_rp_qte_lst_data_rec.inc_num);
          -- 今回ＮＥＴ価格が0以下の場合
          /* 2009.07.30 D.Abe 0000806対応 START */
          ELSE
--          ELSIF (l_get_quote_dt_rec.this_time_net_price <= 0) THEN
          /* 2009.07.30 D.Abe 0000806対応 END */
            -- 通常ＮＥＴ価格が0より大きい場合
            IF (l_get_quote_dt_rec.usuall_net_price > 0) THEN
              /* 2009.12.16 D.Abe E_本稼動_00501対応 START */
              --l_rp_qte_lst_data_rec.line_payment_condition   := l_get_quote_dt_rec.quotation_price
              l_rp_qte_lst_data_rec.line_payment_condition   := (l_get_quote_dt_rec.quotation_price / 
                                                                  l_rp_qte_lst_data_rec.inc_num)
              /* 2009.12.16 D.Abe E_本稼動_00501対応 END */
                                                                  - (l_get_quote_dt_rec.usuall_net_price / 
                                                                  l_rp_qte_lst_data_rec.inc_num);
            -- 通常ＮＥＴ価格が0以下の場合
            ELSIF (l_get_quote_dt_rec.usuall_net_price <= 0) THEN
              /* 2009.12.16 D.Abe E_本稼動_00501対応 START */
              --l_rp_qte_lst_data_rec.line_payment_condition   := l_get_quote_dt_rec.quotation_price - 0;
              l_rp_qte_lst_data_rec.line_payment_condition   := (l_get_quote_dt_rec.quotation_price / 
                                                                l_rp_qte_lst_data_rec.inc_num)
                                                                 - 0;
              /* 2009.12.16 D.Abe E_本稼動_00501対応 END */
            END IF;
          END IF; -- 明細支払条件
        END IF;
      END IF;
/* 2009.06.17 D.Abe T1_1257対応 END */

      -- ========================================
      -- A-4.ワークテーブル出力
      -- ========================================
      insert_row(
        i_rp_qte_lst_data_rec  => l_rp_qte_lst_data_rec  -- 見積データ
       ,ov_errbuf              => lv_errbuf              -- エラー・メッセージ            --# 固定 #
       ,ov_retcode             => lv_retcode             -- リターン・コード              --# 固定 #
       ,ov_errmsg              => lv_errmsg              -- ユーザー・エラー・メッセージ  --# 固定 #
      );
--
      IF (lv_retcode = cv_status_error) THEN
        RAISE global_process_expt;
      END IF;
      -- 空行出力用ページ、レコードをカウント
      -- 帳票は1ページ目か
      IF (gn_page_cnt = cn_page_cnt1) THEN
        -- レコードは16レコード以上か
        IF (gn_rec_cnt >= cn_rec_cnt16) THEN
          -- ページをカウントアップし、レコード数に1を設定する
          gn_page_cnt := gn_page_cnt + 1;
          gn_rec_cnt  := cn_rec_cnt1;
        ELSE
          gn_rec_cnt := gn_rec_cnt + 1;
        END IF;
      ELSE
        -- レコードは24レコード以上か
        IF (gn_rec_cnt >= cn_rec_cnt24) THEN
          -- ページをカウントアップし、レコード数に1を設定する
          gn_page_cnt := gn_page_cnt + 1;
          gn_rec_cnt  := cn_rec_cnt1;
        ELSE
          gn_rec_cnt := gn_rec_cnt + 1;
        END IF;
      END IF;
--
      -- INSERT成功件数をカウントアップ
      ln_ins_cnt := ln_ins_cnt + 1;
--
    END LOOP get_quote_data_loop;
--
    -- カーソルクローズ
    CLOSE get_quote_data_cur;
--
    -- 処理対象データが0件の場合、INパラメータ.見積ヘッダーＩＤより見積番号を取得
    IF (gn_target_cnt = 0) THEN
      BEGIN
        SELECT xqh.quote_number   quote_number     -- 見積番号
        INTO   lt_quote_number
        FROM   xxcso_quote_headers  xqh            -- 見積ヘッダーテーブル
        WHERE  xqh.quote_header_id = ln_qt_hdr_id
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name         --アプリケーション短縮名
                     ,iv_name         => cv_tkn_number_03    --メッセージコード
                     ,iv_token_name1  => cv_tkn_param1       --トークンコード1
                     ,iv_token_value1 => cv_tkn_qt_info      --トークン値1
                    );
          lv_errbuf := lv_errmsg || SQLERRM;
          RAISE no_data_expt;
        WHEN OTHERS THEN
          RAISE;
      END;
--
      lv_errmsg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_app_name             --アプリケーション短縮名
                 ,iv_name         => cv_tkn_number_07        --メッセージコード
                 ,iv_token_name1  => cv_tkn_qt_num           --トークンコード1
                 ,iv_token_value1 => lt_quote_number         --トークン値1
                );
      lv_errbuf := lv_errmsg || SQLERRM;
      RAISE no_data_expt;
    END IF;
    -- ========================================
    -- A-5.空行出力処理
    -- ========================================
    -- 帳票は1ページ目か
    IF (gn_page_cnt = cn_page_cnt1) THEN
      -- レコードは14レコード以下か
      IF (gn_rec_cnt <= cn_rec_cnt14) THEN
        -- 14よりレコード数を引いた数分空行を登録する
        ln_rec_num  := cn_rec_cnt14 - gn_rec_cnt;
      -- レコードは15～16レコードの間か
      ELSIF (gn_rec_cnt BETWEEN cn_rec_cnt15 AND cn_rec_cnt16) THEN
        -- 37よりレコード数を引いた数分空行を登録する
        ln_rec_num  := cn_rec_cnt37 - gn_rec_cnt;
      END IF;
    ELSE
      -- レコードは21レコード以下か
      IF (gn_rec_cnt <= cn_rec_cnt21) THEN
        -- 21よりレコード数を引いた数分空行を登録する
        ln_rec_num  := cn_rec_cnt21 - gn_rec_cnt;
      -- レコードは22～24レコードの間か
      ELSIF (gn_rec_cnt BETWEEN cn_rec_cnt22 AND cn_rec_cnt24) THEN
        -- 45よりレコード数を引いた数分空行を登録する
        ln_rec_num  := cn_rec_cnt45 - gn_rec_cnt;
      END IF;
    END IF;
--
    -- 空行出力処理
    LOOP <<insert_blanks_loop>>
      -- 空行出力用レコード件数分出力した時点でEXITする
      EXIT WHEN ln_loop_cnt = ln_rec_num;
      --
      insert_blanks(
         i_rp_qte_lst_data_rec => l_rp_qte_lst_data_rec    -- 見積データ
        ,ov_errbuf     => lv_errbuf                        -- エラー・メッセージ            --# 固定 #
        ,ov_retcode    => lv_retcode                       -- リターン・コード              --# 固定 #
        ,ov_errmsg     => lv_errmsg                        -- ユーザー・エラー・メッセージ  --# 固定 #
      );
--
      IF (lv_retcode = cv_status_error) THEN
        RAISE global_process_expt;
      END IF;
      --
      ln_loop_cnt := ln_loop_cnt +1;
    END LOOP insert_blanks_loop;
--
    -- ========================================
    -- A-6.SVF起動
    -- ========================================
    act_svf(
       ov_errbuf     => lv_errbuf_svf                    -- エラー・メッセージ            --# 固定 #
      ,ov_retcode    => lv_retcode_svf                   -- リターン・コード              --# 固定 #
      ,ov_errmsg     => lv_errmsg_svf                    -- ユーザー・エラー・メッセージ  --# 固定 #
    );
--
    IF (lv_retcode_svf <> cv_status_error) THEN
      gn_normal_cnt := ln_ins_cnt;
    END IF;
--
    -- ========================================
    -- A-7.ワークテーブルデータ削除
    -- ========================================
    delete_row(
       ov_errbuf     => lv_errbuf                        -- エラー・メッセージ            --# 固定 #
      ,ov_retcode    => lv_retcode                       -- リターン・コード              --# 固定 #
      ,ov_errmsg     => lv_errmsg                        -- ユーザー・エラー・メッセージ  --# 固定 #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ========================================
    -- A-8.SVF起動APIエラーチェック
    -- ========================================
    IF (lv_retcode_svf = cv_status_error) THEN
      lv_errmsg := lv_errmsg_svf;
      lv_errbuf := lv_errbuf_svf;
      RAISE global_process_expt;
    END IF;
--
  EXCEPTION
    -- *** 対象データ0件例外ハンドラ ***
    WHEN no_data_expt THEN
      -- エラー件数カウント
      gn_error_cnt := gn_error_cnt + 1;
--
      -- カーソルがクローズされていない場合
      IF (get_quote_data_cur%ISOPEN) THEN
        -- カーソルクローズ
        CLOSE get_quote_data_cur;
      END IF;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      -- エラー件数カウント
      gn_error_cnt := gn_error_cnt + 1;
--
      -- カーソルがクローズされていない場合
      IF (get_quote_data_cur%ISOPEN) THEN
        -- カーソルクローズ
        CLOSE get_quote_data_cur;
      END IF;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      -- エラー件数カウント
      gn_error_cnt := gn_error_cnt + 1;
--
      -- カーソルがクローズされていない場合
      IF (get_quote_data_cur%ISOPEN) THEN
        -- カーソルクローズ
        CLOSE get_quote_data_cur;
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM||lv_errbuf;
      ov_retcode := cv_status_error;
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      -- エラー件数カウント
      gn_error_cnt := gn_error_cnt + 1;
--
      -- カーソルがクローズされていない場合
      IF (get_quote_data_cur%ISOPEN) THEN
        -- カーソルクローズ
        CLOSE get_quote_data_cur;
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END submain;
--
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : コンカレント実行ファイル登録プロシージャ
   **********************************************************************************/
--
  PROCEDURE main(
     errbuf        OUT NOCOPY VARCHAR2    --   エラー・メッセージ  --# 固定 #
    ,retcode       OUT NOCOPY VARCHAR2    --   リターン・コード    --# 固定 #
    ,in_qt_hdr_id  IN  NUMBER             --   見積ヘッダーID
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
--
    cv_appl_short_name CONSTANT VARCHAR2(10)  := 'XXCCP';            -- アドオン：共通・IF領域
    cv_target_rec_msg  CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90000'; -- 対象件数メッセージ
    cv_success_rec_msg CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90001'; -- 成功件数メッセージ
    cv_error_rec_msg   CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002'; -- エラー件数メッセージ
    cv_skip_rec_msg    CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90003'; -- スキップ件数メッセージ
    cv_cnt_token       CONSTANT VARCHAR2(10)  := 'COUNT';            -- 件数メッセージ用トークン名
    cv_normal_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; -- 正常終了メッセージ
    cv_warn_msg        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005'; -- 警告終了メッセージ
    cv_error_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006'; -- エラー終了全ロールバック
--
    /* 2009.05.20 M.Ohtsuki T1_0696対応 START */
--    cv_log_msg         CONSTANT VARCHAR2(100) := 'システムエラーが発生しました。システム管理者に確認してください。';
    /* 2009.05.20 M.Ohtsuki T1_0696対応 END */
    -- エラーメッセージ
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf          VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode         VARCHAR2(1);     -- リターン・コード
    lv_errmsg          VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
    lv_message_code    VARCHAR2(100);   -- 終了メッセージコード
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_log             CONSTANT VARCHAR2(3)   := 'LOG';  -- コンカレントヘッダメッセージ出力 出力区分
--
  BEGIN
--
--###########################  固定部 START   #####################################################
--
    -- 固定出力
    -- コンカレントヘッダメッセージ出力関数の呼び出し
    xxccp_common_pkg.put_log_header(
       iv_which   => cv_log
      ,ov_retcode => lv_retcode
      ,ov_errbuf  => lv_errbuf
      ,ov_errmsg  => lv_errmsg
    );
    --
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_api_others_expt;
    END IF;
--
--###########################  固定部 END   #############################
--
    -- ===============================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ===============================================
    submain(
       in_qt_hdr_id   => in_qt_hdr_id       -- 見積ヘッダーID
      ,ov_errbuf      => lv_errbuf          -- エラー・メッセージ            --# 固定 #
      ,ov_retcode     => lv_retcode         -- リターン・コード              --# 固定 #
      ,ov_errmsg      => lv_errmsg          -- ユーザー・エラー・メッセージ  --# 固定 #
    );
--
    IF (lv_retcode = cv_status_error) THEN
       --エラー出力
       fnd_file.put_line(
          which  => FND_FILE.LOG
    /* 2009.05.20 M.Ohtsuki T1_0696対応 START */
--         ,buff   => lv_errmsg                  --ユーザー・エラーメッセージ
--↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓
         ,buff   => SUBSTRB(
                    cv_pkg_name||cv_msg_cont||
                    cv_prg_name||cv_msg_part||
                    lv_errbuf,1,5000
                    )
    /* 2009.05.20 M.Ohtsuki T1_0696対応 END */
       );
    /* 2009.05.20 M.Ohtsuki T1_0696対応 START */
--       fnd_file.put_line(
--          which  => FND_FILE.LOG
--         ,buff   => SUBSTRB(
--                      cv_log_msg ||cv_msg_prnthss_l||
--                      cv_pkg_name||cv_msg_cont||
--                      cv_prg_name||cv_msg_part||
--                      lv_errbuf  ||cv_msg_prnthss_r,1,5000
--                    )
--       );                                                     --エラーメッセージ
    /* 2009.05.20 M.Ohtsuki T1_0696対応 START */
    END IF;
--
    -- =======================
    -- A-9.終了処理 
    -- =======================
    --空行の出力
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
    --対象件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                   );
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --
    --成功件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_success_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_normal_cnt)
                   );
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --
    --エラー件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_error_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_error_cnt)
                   );
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --
    --終了メッセージ
    IF (lv_retcode = cv_status_normal) THEN
      lv_message_code := cv_normal_msg;
    ELSIF (lv_retcode = cv_status_warn) THEN
      lv_message_code := cv_warn_msg;      
    ELSIF(lv_retcode = cv_status_error) THEN
      lv_message_code := cv_error_msg;
    END IF;
    --
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => lv_message_code
                   );
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
--
    --ステータスセット
    retcode := lv_retcode;
    --終了ステータスがエラーの場合はROLLBACKする
    IF (retcode = cv_status_error) THEN
      ROLLBACK;
    END IF;
--
  EXCEPTION
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM||lv_errbuf;
      retcode := cv_status_error;
      ROLLBACK;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
  END main;
--
--###########################  固定部 END   #######################################################
--
END XXCSO017A04C;
/
