create or replace PACKAGE BODY xxwsh400003c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name           : xxwsh400003c(BODY)
 * Description            : 出荷依頼確定関数(BODY)
 * MD.050                 : T_MD050_BPO_401_出荷依頼
 * MD.070                 : T_MD070_EDO_BPO_40D_出荷依頼確定関数
 * Version                : 1.30
 *
 * Program List
 *  ------------------------ ---- ---- --------------------------------------------------
 *   Name                    Type Ret  Description
 *  ------------------------ ---- ---- --------------------------------------------------
 *  iv_prod_class            P         商品区分
 *  iv_head_sales_branch     P         管轄拠点
 *  iv_input_sales_branch    P         入力拠点
 *  in_deliver_to_id         P         配送先ID
 *  iv_request_no            P         依頼No
 *  id_schedule_ship_date    P         出庫日
 *  id_schedule_arrival_date P         着日
 *  iv_callfrom_flg          P         呼出元フラグ
 *  iv_status_kbn            P         締めステータスチェック区分
 * ------------- ----------- --------- --------------------------------------------------
 *  Date         Ver.  Editor          Description
 * ------------- ----- --------------- --------------------------------------------------
 *  2008/03/13    1.0   R.Matusita      新規作成
 *  2008/04/23    1.1   R.Matusita      内部変更要求#65
 *  2008/06/03    1.2   M.Uehara        内部変更要求#80
 *  2008/06/05    1.3   N.Yoshida       リードタイム妥当性チェック D-2出庫日 > 稼働日に修正
 *  2008/06/05    1.4   M.Uehara        積載効率チェック(積載効率算出)の実施条件を修正
 *  2008/06/05    1.5   N.Yoshida       出荷可否チェックにて引数設定の修正
 *                                     (入力パラメータ：管轄拠点⇒受注ヘッダの管轄拠点)
 *  2008/06/06    1.6   T.Ishiwata      出荷可否チェックにてエラーメッセージの修正
 *  2008/06/18    1.7   T.Ishiwata      締めステータスチェック区分＝２の場合、Updateするよう修正
 *                                      全体的にネスト修正
 *  2008/06/19    1.8   Y.Shindou       内部変更要求#143対応
 *  2008/07/08    1.9   N.Fukuda        ST不具合対応#405
 *  2008/07/08    1.10  M.Uehara        ST不具合対応#424
 *  2008/07/09    1.11  N.Fukuda        ST不具合対応#430
 *  2008/07/29    1.12  D.Nihei         ST不具合対応#503
 *  2008/07/30    1.13  M.Uehara        ST不具合対応#501
 *  2008/08/06    1.14  D.Nihei         ST不具合対応#525
 *                                      カテゴリ情報VIEW変更
 *  2008/08/11    1.15  M.Hokkanji      内部課題#32対応、内部変更要求#173,178対応
 *  2008/09/01    1.16  N.Yoshida       PT対応(起票なし)
 *  2008/09/24    1.17  M.Hokkanji       TE080_400指摘66対応
 *  2008/10/15    1.18  Marushita        I_S_387対応
 *  2008/11/18    1.19  M.Hokkanji       統合指摘141、632、658対応
 *  2008/11/26    1.20  M.Hokkanji       本番障害133対応
 *  2008/12/02    1.21  M.Nomura         本番障害318対応
 *  2008/12/07    1.22  M.Hokkanji       本番障害514対応
 *  2008/12/13    1.23  M.Hokkanji       本番障害554対応
 *  2008/12/24    1.24  M.Hokkanji       本番障害839対応
 *  2009/01/09    1.25  H.Itou           本番障害894対応
 *  2009/03/03    1.26  Y.Kazama         本番障害#1243対応
 *  2009/04/16    1.27  Y.Kazama         本番障害#1398対応
 *  2009/05/14    1.28  H.Itou           本番障害#1398対応
 *  2009/08/31    1.29  D.Sugahara       本番障害#1601対応
 *  2009/11/12    1.30  H.Itou           本番障害#1648
 *****************************************************************************************/
--
--#######################  固定グローバル定数宣言部 START   #######################
--
  gv_status_normal CONSTANT VARCHAR2(1) := '0';
  gv_status_warn   CONSTANT VARCHAR2(1) := '1';
  gv_status_error  CONSTANT VARCHAR2(1) := '2';
  gv_sts_cd_normal CONSTANT VARCHAR2(1) := 'C';
  gv_sts_cd_warn   CONSTANT VARCHAR2(1) := 'G';
  gv_sts_cd_error  CONSTANT VARCHAR2(1) := 'E';
  gv_msg_part      CONSTANT VARCHAR2(3) := ' : ';
  gv_msg_cont      CONSTANT VARCHAR2(3) := '.';
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
  -- ユーザー定義例外
  -- ===============================
--
  check_lock_expt           EXCEPTION;     -- ロック取得エラー
--
  PRAGMA EXCEPTION_INIT(check_lock_expt, -54);
--
  --*** 処理部共通例外ワーニング ***
  global_process_warn       EXCEPTION;
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  gn_status_normal CONSTANT NUMBER := 0;
  gn_status_error  CONSTANT NUMBER := 1;
  gn_status_warn   CONSTANT NUMBER := 2;
  gv_pkg_name      CONSTANT VARCHAR2(100) := 'xxwsh400003c'; -- パッケージ名
--
  gv_cnst_msg_kbn  CONSTANT VARCHAR2(5)   := 'XXWSH';
  gv_cnst_msg_cmn  CONSTANT VARCHAR2(5)   := 'XXCMN';
--
  gv_cnst_msg_001  CONSTANT VARCHAR2(15)  := 'APP-XXWSH-11162'; -- ﾛｯｸｴﾗｰ
  gv_cnst_msg_002  CONSTANT VARCHAR2(15)  := 'APP-XXWSH-11163'; -- 対象データなし
  gv_cnst_msg_003  CONSTANT VARCHAR2(15)  := 'APP-XXWSH-11165'; -- 処理件数出力
  -- 項目チェック
  gv_cnst_msg_null CONSTANT VARCHAR2(15)  := 'APP-XXWSH-11161';  -- 必須チェックエラーメッセージ
  gv_cnst_msg_prop CONSTANT VARCHAR2(15)  := 'APP-XXWSH-11159';  -- 妥当性チェックエラーメッセージ
  gv_cnst_msg_155  CONSTANT VARCHAR2(15)  := 'APP-XXWSH-11155';  -- 共通関数エラー
  gv_cnst_msg_154  CONSTANT VARCHAR2(15)  := 'APP-XXWSH-11154';  -- 稼働日チェックエラー
  gv_cnst_msg_153  CONSTANT VARCHAR2(15)  := 'APP-XXWSH-11153';  -- リードタイムチェックエラー
  gv_cnst_msg_160  CONSTANT VARCHAR2(15)  := 'APP-XXWSH-11160';  -- 締め実施チェックエラー
  gv_cnst_msg_164  CONSTANT VARCHAR2(15)  := 'APP-XXWSH-11164';  -- 顧客エラー
  gv_cnst_msg_151  CONSTANT VARCHAR2(15)  := 'APP-XXWSH-11151';  -- パレット枚数チェックエラー
  gv_cnst_msg_152  CONSTANT VARCHAR2(15)  := 'APP-XXWSH-11152';  -- マスタチェックエラー
  gv_cnst_msg_166  CONSTANT VARCHAR2(15)  := 'APP-XXWSH-11166';  -- 品目共通エラー
  gv_cnst_msg_167  CONSTANT VARCHAR2(15)  := 'APP-XXWSH-11167';  -- 配数エラー
  gv_cnst_msg_168  CONSTANT VARCHAR2(15)  := 'APP-XXWSH-11168';  -- 数量入力エラーメッセージ
  gv_cnst_msg_169  CONSTANT VARCHAR2(15)  := 'APP-XXWSH-11169';  -- 出荷可否チェック（出荷数制限）エラー
  gv_cnst_msg_170  CONSTANT VARCHAR2(15)  := 'APP-XXWSH-11170';  -- 出荷可否チェック（出荷停止日）エラー
  gv_cnst_msg_156  CONSTANT VARCHAR2(15)  := 'APP-XXWSH-11156';  -- 出荷可否警告（コンカレント）
  gv_cnst_msg_157  CONSTANT VARCHAR2(15)  := 'APP-XXWSH-11157';  -- 出荷可否警告（画面）
  gv_cnst_msg_158  CONSTANT VARCHAR2(15)  := 'APP-XXWSH-11158';  -- 積載効率エラー
  gv_cnst_msg_171  CONSTANT VARCHAR2(15)  := 'APP-XXWSH-11171';  -- 正常処理件数出力
  gv_cnst_msg_172  CONSTANT VARCHAR2(15)  := 'APP-XXWSH-11172';  -- 警告処理件数出力
  gv_cnst_msg_173  CONSTANT VARCHAR2(15)  := 'APP-XXWSH-11173';  -- 出荷可否チェック（出荷数制限）警告
  gv_cnst_msg_174  CONSTANT VARCHAR2(15)  := 'APP-XXWSH-11174';  -- 出荷可否チェック（出荷停止日）警告
  gv_cnst_msg_175  CONSTANT VARCHAR2(15)  := 'APP-XXWSH-11175';  -- 出荷引当対象エラー
-- Ver 1.17 M.Hokkanji START
  gv_cnst_msg_176  CONSTANT VARCHAR2(15)  := 'APP-XXWSH-11176';  -- 運送業者エラー
-- Ver 1.17 M.Hokkanji END
-- Ver 1.19 M.Hokkanji Start
  gv_cnst_msg_177  CONSTANT VARCHAR2(15)  := 'APP-XXWSH-11177';  -- リードタイム不正エラー
-- Ver 1.19 M.Hokkanji End
  gv_cnst_sep_msg  CONSTANT VARCHAR2(15)  := 'APP-XXCMN-00003';  -- sep_msg
  gv_cnst_cmn_008  CONSTANT VARCHAR2(15)  := 'APP-XXCMN-00008';  -- 処理件数
  gv_cnst_cmn_009  CONSTANT VARCHAR2(15)  := 'APP-XXCMN-00009';  -- 成功件数
  gv_cnst_cmn_010  CONSTANT VARCHAR2(15)  := 'APP-XXCMN-00010';  -- エラー件数
  gv_cnst_cmn_011  CONSTANT VARCHAR2(15)  := 'APP-XXCMN-00011';  -- スキップ件数
  gv_cnst_cmn_cnt  CONSTANT VARCHAR2(15)  := 'CNT';              -- CNT
-- Ver 1.15 M.Hokkanji START
  gv_cnst_cmn_012  CONSTANT VARCHAR2(15)  := 'APP-XXCMN-10001';  -- 対象データ無し
-- Ver 1.15 M.Hokkanji END
--
  gv_cnst_token_api_name CONSTANT VARCHAR2(15)  := 'API_NAME';  --
--
  gv_cnst_tkn_table       CONSTANT VARCHAR2(15)  := 'TABLE';
  gv_cnst_tkn_item        CONSTANT VARCHAR2(15)  := 'ITEM';
  gv_cnst_tkn_value       CONSTANT VARCHAR2(15)  := 'VALUE';
  gv_cnst_file_id_name    CONSTANT VARCHAR2(7)   := 'FILE_ID';
  gv_cnst_tkn_para        CONSTANT VARCHAR2(9)   := 'PARAMETER';
-- Ver 1.15 M.Hokkanji START
  gv_cnst_tkn_key         CONSTANT VARCHAR2(15)  := 'KEY';
-- Ver 1.15 M.Hokkanji END
-- Ver 1.17 M.Hokkanji START
  gv_cnst_tkn_request_no  CONSTANT VARCHAR2(15)  := 'REQUEST_NO';
-- Ver 1.17 M.Hokkanji END
-- Ver1.22 M.Hokkanji Start
  gv_cnst_tkn_deliver_from CONSTANT VARCHAR2(15) := 'DELIVER_FROM';
  gv_cnst_tkn_deliver_to   CONSTANT VARCHAR2(15) := 'DELIVER_TO';
  gv_cnst_tkn_head_saled   CONSTANT VARCHAR2(20) := 'HEAD_SALES_BRANCH';
  gv_cnst_tkn_ship_date    CONSTANT VARCHAR2(15) := 'SHIP_DATE';
  gv_cnst_tkn_item_code    CONSTANT VARCHAR2(15) := 'ITEM_CODE';
-- Ver1.22 M.Hokkanji End
--
-- 入力パラメータ名称
  gv_cnst_item_name       CONSTANT VARCHAR2(15)  := '項目名称';
  gv_cnst_item_value      CONSTANT VARCHAR2(15)  := '項目の値';
  gv_cnst_item_len        CONSTANT VARCHAR2(15)  := '項目の長さ';
  gv_cnst_item_decimal    CONSTANT VARCHAR2(50)  := '項目の長さ（小数点以下）';
--
  gv_cnst_file_type       CONSTANT VARCHAR2(30)  := 'フォーマットパターン';
  gv_cnst_target_date     CONSTANT VARCHAR2(30)  := '対象日付';
  gv_cnst_p_days          CONSTANT VARCHAR2(30)  := 'パージ対象期間';
--
  gv_cnst_item_null       CONSTANT VARCHAR2(15)  := '必須フラグ';
  gv_cnst_item_attr       CONSTANT VARCHAR2(15)  := '項目属性';
--
  gv_cnst_period          CONSTANT VARCHAR2(1)   := '.';        -- ピリオド
  gv_cnst_err_msg_space   CONSTANT VARCHAR2(6)   := '      ';   -- スペース
--
  gv_status_01            CONSTANT VARCHAR2(2)   := '01';    -- 入力中
  gv_status_02            CONSTANT VARCHAR2(2)   := '02';    -- 拠点確定
  gv_status_03            CONSTANT VARCHAR2(2)   := '03';    -- 締め済み
  gv_line_feed            CONSTANT VARCHAR2(1)   := CHR(10); -- 改行コード;
--
  gv_msg_null_01          CONSTANT VARCHAR2(30)  := '管轄拠点コード';
  gv_msg_null_02          CONSTANT VARCHAR2(30)  := '入力拠点コード';
  gv_msg_null_03          CONSTANT VARCHAR2(30)  := '呼出元フラグ';
  gv_msg_null_04          CONSTANT VARCHAR2(30)  := '締めステータス区分';
  gv_msg_null_05          CONSTANT VARCHAR2(30)  := '呼出元フラグ';
  gv_msg_null_06          CONSTANT VARCHAR2(30)  := '締めステータスチェック区分';
  gv_msg_null_07          CONSTANT VARCHAR2(30)  := '商品区分';
  gv_msg_null_08          CONSTANT VARCHAR2(30)  := '出庫日';
  gv_status_A             CONSTANT VARCHAR2(1)   := 'A'; -- 有効
--
  gv_transaction_type_name_ship CONSTANT VARCHAR2(100) := '引取変更'; -- 出庫形態 2008/07/08 ST不具合対応#405
-- Ver1.19 M.Hokkanji Start
  gv_transaction_type_name_mat  CONSTANT VARCHAR2(100) := '資材出荷';
-- Ver1.19 M.Hokkanji End
--
  gv_freight_charge_class_on  CONSTANT VARCHAR2(1) := '1'; -- 運賃区分「対象」  2008/07/09 ST不具合対応#430
  gv_freight_charge_class_off CONSTANT VARCHAR2(1) := '0'; -- 運賃区分「対象外」2008/07/09 ST不具合対応#430
-- 2008/07/29 D.Nihei ADD START
  gv_drink                    CONSTANT VARCHAR2(1) := '2'; -- 商品区分「ドリンク」2008/07/29 ST不具合対応#503
-- 2008/07/29 D.Nihei ADD END
-- 2008/08/06 D.Nihei ADD START
  gv_prod                     CONSTANT VARCHAR2(1) := '5'; -- 品目区分「製品」2008/08/06 ST不具合対応#525
-- 2008/08/06 D.Nihei ADD END
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
--
  -- 更新用PL/SQL表型
  TYPE order_header_id_ttype    IS TABLE OF 
  xxwsh_order_headers_all.order_header_id%TYPE INDEX BY BINARY_INTEGER; -- 受注ヘッダアドオンID
--
  -- 更新用PL/SQL表
  gt_header_id_upd_tab    order_header_id_ttype;      -- 受注ヘッダアドオンID
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
--
  gv_out_msg       VARCHAR2(2000);
  gv_sep_msg       VARCHAR2(2000);
  gn_target_cnt    NUMBER;                    -- 対象件数
  gn_normal_cnt    NUMBER;                    -- 正常件数
  gn_error_cnt     NUMBER;                    -- エラー件数
  gn_warn_cnt      NUMBER;                    -- スキップ件数
  gv_callfrom_flg  VARCHAR2(1);               -- 呼出元フラグ
  gv_transaction_type_id_ship VARCHAR2(4) ;   -- 出庫形態 2008/07/08 ST不具合対応#405
--
   /**********************************************************************************
   * Procedure Name   : allow_pickup_flag_chk
   * Description      : 引当対象チェック (D-3)
   ***********************************************************************************/
  FUNCTION allow_pickup_flag_chk(
    iv_deliver_from       IN  VARCHAR2,                   -- 出荷元保管場所コード
    ov_errbuf             OUT NOCOPY VARCHAR2,            -- エラー・メッセージ           --# 固定 #
    ov_retcode            OUT NOCOPY VARCHAR2,            -- リターン・コード             --# 固定 #
    ov_errmsg             OUT NOCOPY VARCHAR2)            -- ユーザー・エラー・メッセージ --# 固定 #
    RETURN NUMBER
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(30) := 'allow_pickup_flag_chk';       -- プログラム名
    cv_err                  CONSTANT xxcmn_item_locations2_v.allow_pickup_flag%TYPE := '0';
-- ##### 20081202 Ver.1.21 本番#318対応 START #####
    cv_table_name_tran               VARCHAR2(30)   := 'OPM保管場所情報VIEW2';
    cv_deliver_from                  VARCHAR2(30)   := '配送先コード';
-- ##### 20081202 Ver.1.21 本番#318対応 END   #####
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
--
    -- *** ローカル変数 ***
--
    lv_allow_pickup_flag    VARCHAR2(150);
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
-- ##### 20081202 Ver.1.21 本番#318対応 START #####
    BEGIN
-- ##### 20081202 Ver.1.21 本番#318対応 END   #####
--
      SELECT allow_pickup_flag           -- 出荷引当対象フラグ
      INTO   lv_allow_pickup_flag
      FROM   xxcmn_item_locations2_v       -- OPM保管場所情報VIEW2
      WHERE  segment1 = iv_deliver_from
      AND    disable_date IS NULL;
--
-- ##### 20081202 Ver.1.21 本番#318対応 START #####
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_msg_cmn,
                                              gv_cnst_cmn_012,
                                              gv_cnst_tkn_table,
                                              cv_table_name_tran,
                                              gv_cnst_tkn_key,
                                              cv_deliver_from || ':' || iv_deliver_from);
        lv_errbuf := lv_errmsg;
      RETURN gn_status_error;
    END;
-- ##### 20081202 Ver.1.21 本番#318対応 END   #####
--
    IF (lv_allow_pickup_flag = cv_err) THEN
      -- 引当不可
      RETURN gn_status_error;
--
    ELSE
      RETURN gn_status_normal;
    END IF;
--
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
      RETURN gn_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
      RETURN gn_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
      RETURN gn_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END allow_pickup_flag_chk;
--
   /**********************************************************************************
   * Procedure Name   : get_plan_item_flag
   * Description      : 計画商品フラグ取得処理 (D-8)
   ***********************************************************************************/
  FUNCTION get_plan_item_flag(
    iv_shipping_item_code    IN  VARCHAR2,                -- 品目コード
    iv_head_sales_branch     IN  VARCHAR2,                -- 拠点コード
    iv_deliver_from          IN  VARCHAR2,                -- 出荷元保管場所コード
    id_schedule_ship_date    IN  DATE,                    -- 出庫日
    ov_errbuf             OUT NOCOPY VARCHAR2,            -- エラー・メッセージ           --# 固定 #
    ov_retcode            OUT NOCOPY VARCHAR2,            -- リターン・コード             --# 固定 #
    ov_errmsg             OUT NOCOPY VARCHAR2)            -- ユーザー・エラー・メッセージ --# 固定 #
    RETURN NUMBER
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(20) := 'get_plan_item_flag';       -- プログラム名
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
--
    -- *** ローカル変数 ***
--
    ln_cnt    NUMBER;
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    SELECT COUNT(1)
    INTO   ln_cnt
    FROM   xxcmn_sourcing_rules2_v -- 物流構成情報VIEW2
    WHERE  item_code            =  iv_shipping_item_code
    AND    base_code            =  iv_head_sales_branch
    AND    delivery_whse_code   =  iv_deliver_from
    AND    start_date_active    <= id_schedule_ship_date
    AND    end_date_active      >= id_schedule_ship_date
    AND    plan_item_flag       =  1;                  -- 計画商品フラグ ON
--
    IF (ln_cnt = 0) THEN
      -- 存在しない
      RETURN gn_status_error;
--
    ELSE
      -- 存在する
      RETURN gn_status_normal;
    END IF;
--
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
      RETURN gn_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
      RETURN gn_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
      RETURN gn_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_plan_item_flag;
--
   /**********************************************************************************
   * Procedure Name   : master_check
   * Description      : マスタチェック (D-7)
   ***********************************************************************************/
  FUNCTION master_check(
    iv_shipping_item_code    IN  VARCHAR2,                   -- 品目コード
    iv_deliver_to            IN  VARCHAR2,                   -- 配送先コード
    iv_head_sales_branch     IN  VARCHAR2,                   -- 拠点コード
    iv_deliver_from          IN  VARCHAR2,                   -- 出荷元保管場所コード
    id_schedule_ship_date    IN  DATE,                       -- 出庫日
    ov_errbuf             OUT NOCOPY VARCHAR2,            -- エラー・メッセージ           --# 固定 #
    ov_retcode            OUT NOCOPY VARCHAR2,            -- リターン・コード             --# 固定 #
    ov_errmsg             OUT NOCOPY VARCHAR2)            -- ユーザー・エラー・メッセージ --# 固定 #
    RETURN NUMBER
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(20) := 'master_check';       -- プログラム名
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
--
    cv_ZZZZZZZ     VARCHAR2(7)    := 'ZZZZZZZ'; -- クイックコード「コード区分」「倉庫」
    -- *** ローカル変数 ***
--
    ln_cnt    NUMBER;
    ln_cnt2   NUMBER;
    ln_cnt3   NUMBER;
    ln_cnt4   NUMBER;
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
-- 2009/01/09 H.Itou Mod Start 本番障害#894
--    -- 1.物流構成アドオンマスタのチェック
--    SELECT COUNT(1)
--    INTO   ln_cnt
--    FROM   xxcmn_sourcing_rules2_v                            -- 物流構成情報VIEW2
--    WHERE  item_code            =  iv_shipping_item_code      -- 品目コード
--    AND    ship_to_code         =  iv_deliver_to              -- 配送先コード
--    AND    delivery_whse_code   =  iv_deliver_from            -- 出荷元保管場所コード
--    AND    start_date_active    <= id_schedule_ship_date      -- 出庫日
--    AND    end_date_active      >= id_schedule_ship_date;     -- 出庫日
----
--    IF (ln_cnt = 0) THEN
--      -- 2.物流構成アドオンマスタのチェック(1で該当なしの場合)
--      SELECT COUNT(1)
--      INTO   ln_cnt2
--      FROM   xxcmn_sourcing_rules2_v                            -- 物流構成情報VIEW2
--      WHERE  item_code            =  iv_shipping_item_code      -- 品目コード
--      AND    base_code            =  iv_head_sales_branch       -- 拠点コード
--      AND    delivery_whse_code   =  iv_deliver_from            -- 出荷元保管場所コード
--      AND    start_date_active    <= id_schedule_ship_date      -- 出庫日
--      AND    end_date_active      >= id_schedule_ship_date;     -- 出庫日
----
--      IF (ln_cnt2 = 0) THEN
--        -- 3.物流構成アドオンマスタのチェック(2で該当なしの場合)
--        SELECT COUNT(1)
--        INTO   ln_cnt3
--        FROM   xxcmn_sourcing_rules2_v                           -- 物流構成情報VIEW2
--        WHERE  item_code            =  cv_ZZZZZZZ
--        AND    ship_to_code         =  iv_deliver_to             -- 配送先コード
--        AND    delivery_whse_code   =  iv_deliver_from           -- 出荷元保管場所コード
--        AND    start_date_active    <= id_schedule_ship_date     -- 出庫日
--        AND    end_date_active      >= id_schedule_ship_date;    -- 出庫日
----
--        IF (ln_cnt3 = 0) THEN
--          -- 4.物流構成アドオンマスタのチェック(3で該当なしの場合)
--          SELECT COUNT(1)
--          INTO   ln_cnt4
--          FROM   xxcmn_sourcing_rules2_v                            -- 物流構成情報VIEW2
--          WHERE  item_code            =  cv_ZZZZZZZ
--          AND    base_code            =  iv_head_sales_branch       -- 拠点コード
--          AND    delivery_whse_code   =  iv_deliver_from            -- 出荷元保管場所コード
--          AND    start_date_active    <= id_schedule_ship_date      -- 出庫日
--          AND    end_date_active      >= id_schedule_ship_date;     -- 出庫日
----
--          IF (ln_cnt4 = 0) THEN
--            -- 5.存在しない場合、エラー
--            RETURN gn_status_error;
--          END IF;
----
--        END IF;
----
--      END IF;
----
--    END IF;
--
--    -- 存在する
--    RETURN gn_status_normal;
----
    -- 物流構成存在チェック関数
    lv_retcode := xxwsh_common_pkg.chk_sourcing_rules(
                    it_item_code          => iv_shipping_item_code    -- 1.品目コード
                   ,it_base_code          => iv_head_sales_branch     -- 2.管轄拠点
                   ,it_ship_to_code       => iv_deliver_to            -- 3.配送先
                   ,it_delivery_whse_code => iv_deliver_from          -- 4.出庫倉庫
                   ,id_standard_date      => id_schedule_ship_date    -- 5.基準日(適用日基準日)
                  );
--
    -- 戻り値が正常でない場合、エラー
    IF (lv_retcode <> gv_status_normal) THEN
      RETURN gn_status_error;
--
     -- 戻り値が正常の場合、正常
    ELSE
      RETURN gn_status_normal;
    END IF;
-- 2009/01/09 H.Itou Mod End
--
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
      RETURN gn_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
      RETURN gn_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
      RETURN gn_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END master_check;
--
  /**********************************************************************************
   * Procedure Name   : upd_table_batch
   * Description      : ステータス一括更新処理(D-12)
   ***********************************************************************************/
  PROCEDURE upd_table_batch(
    ov_errbuf   OUT NOCOPY VARCHAR2,  --   エラー・メッセージ           --# 固定 #
    ov_retcode  OUT NOCOPY VARCHAR2,  --   リターン・コード             --# 固定 #
    ov_errmsg   OUT NOCOPY VARCHAR2)  --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_table_batch'; -- プログラム名
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
--
    -- *** ローカル変数 ***
--
    ln_user_id          NUMBER;            -- ログインしているユーザー
    ln_login_id         NUMBER;            -- 最終更新ログイン
    ln_conc_request_id  NUMBER;            -- 要求ID
    ln_prog_appl_id     NUMBER;            -- コンカレント・プログラム・アプリケーションID
    ln_conc_program_id  NUMBER;            -- コンカレント・プログラムID
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- 共通更新情報の取得
    ln_user_id         := FND_GLOBAL.USER_ID;        -- ログインしているユーザーのID取得
    ln_login_id        := FND_GLOBAL.LOGIN_ID;       -- 最終更新ログイン
    ln_conc_request_id := FND_GLOBAL.CONC_REQUEST_ID;-- 要求ID
    ln_prog_appl_id    := FND_GLOBAL.PROG_APPL_ID;   -- コンカレント・プログラム・アプリケーションID
    ln_conc_program_id := FND_GLOBAL.CONC_PROGRAM_ID;-- コンカレント・プログラムID
--
    -- =====================================
    -- 一括更新処理
    -- =====================================
    FORALL ln_cnt IN 1 .. gt_header_id_upd_tab.COUNT
      -- 受注ヘッダアドオン更新(拠点確定)
      UPDATE xxwsh_order_headers_all
      SET req_status              = gv_status_02                   -- ステータス(02:拠点確定)
         ,last_updated_by         = ln_user_id                     -- 最終更新者
         ,last_update_date        = SYSDATE                        -- 最終更新日
         ,last_update_login       = ln_login_id                    -- 最終更新ログイン
         ,request_id              = ln_conc_request_id             -- 要求ID
         ,program_application_id  = ln_prog_appl_id                -- ｺﾝｶﾚﾝﾄ・ﾌﾟﾛｸﾞﾗﾑ・ｱﾌﾟﾘｹｰｼｮﾝID
         ,program_id              = ln_conc_program_id             -- コンカレント・プログラムID
         ,program_update_date     = SYSDATE                        -- プログラム更新日
      WHERE order_header_id       = gt_header_id_upd_tab(ln_cnt); -- 受注ヘッダアドオンID
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
  END upd_table_batch;
--
  /**********************************************************************************
   * Procedure Name   : out_log
   * Description      : 件数出力処理
   ***********************************************************************************/
  PROCEDURE out_log(
    in_target_cnt   IN NUMBER,  --   処理件数
    in_normal_cnt   IN NUMBER,  --   成功件数
    in_error_cnt    IN NUMBER,  --   エラー件数
    in_warn_cnt     IN NUMBER)  --   スキップ件数
  IS
--
  BEGIN
--
--
    IF (gv_callfrom_flg = '1') THEN
      -- ==================================
      -- リターン・コードのセット、終了処理
      -- ==================================
--
--    呼び出し元フラグが１：コンカレントの場合はログ出力する
--
      gn_target_cnt := in_target_cnt;
      gn_normal_cnt := in_normal_cnt;
      gn_error_cnt  := in_error_cnt;
      gn_warn_cnt   := in_warn_cnt;
--
      --処理件数出力
      gv_out_msg := xxcmn_common_pkg.get_msg(gv_cnst_msg_cmn,gv_cnst_cmn_008,gv_cnst_cmn_cnt,TO_CHAR(gn_target_cnt));
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
      --正常件数出力
      gv_out_msg := xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,gv_cnst_msg_171,gv_cnst_cmn_cnt,TO_CHAR(gn_normal_cnt));
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
      --エラー件数出力
      gv_out_msg := xxcmn_common_pkg.get_msg(gv_cnst_msg_cmn,gv_cnst_cmn_010,gv_cnst_cmn_cnt,TO_CHAR(gn_error_cnt));
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
      --警告件数出力
      gv_out_msg := xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,gv_cnst_msg_172,gv_cnst_cmn_cnt,TO_CHAR(gn_warn_cnt));
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
      --区切り文字出力
      gv_sep_msg := xxcmn_common_pkg.get_msg(gv_cnst_msg_cmn,gv_cnst_sep_msg);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_sep_msg);
    END IF;
--
  EXCEPTION
    WHEN OTHERS THEN
      gn_target_cnt := 0;
      gn_normal_cnt := 0;
      gn_error_cnt  := 0;
      gn_warn_cnt   := 0;
--
  END out_log;
--
  /**********************************************************************************
   * Procedure Name   : 出荷依頼確定
   * Description      : ship_set
   ***********************************************************************************/
  PROCEDURE ship_set(
    iv_prod_class            IN  VARCHAR2  DEFAULT NULL, -- 商品区分
    iv_head_sales_branch     IN  VARCHAR2  DEFAULT NULL, -- 管轄拠点
    iv_input_sales_branch    IN  VARCHAR2  DEFAULT NULL, -- 入力拠点
    in_deliver_to_id         IN  NUMBER    DEFAULT NULL, -- 配送先ID
    iv_request_no            IN  VARCHAR2  DEFAULT NULL, -- 依頼No
    id_schedule_ship_date    IN  DATE      DEFAULT NULL, -- 出庫日
    id_schedule_arrival_date IN  DATE      DEFAULT NULL, -- 着日
    iv_callfrom_flg          IN  VARCHAR2,               -- 呼出元フラグ
    iv_status_kbn            IN  VARCHAR2,               -- 締めステータスチェック区分
    ov_errbuf                OUT NOCOPY  VARCHAR2,       -- エラー・メッセージ           --# 固定 #
    ov_retcode               OUT NOCOPY  VARCHAR2,       -- リターン・コード             --# 固定 #
    ov_errmsg                OUT NOCOPY  VARCHAR2)       -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name    CONSTANT          VARCHAR2(100)  := 'ship_set'; -- プログラム名
    cv_order_category_code           VARCHAR2(5)    := 'ORDER'; -- 
    cv_shipping_shikyu_class         VARCHAR2(1)    := '1'; -- 
    cv_latest_external_flag          VARCHAR2(1)    := 'Y'; -- 
    cv_delete_flag                   VARCHAR2(1)    := 'Y'; -- 
    cv_whse_code                     VARCHAR2(1)    := '4'; -- クイックコード「コード区分」「倉庫」
    cv_deliver_to                    VARCHAR2(1)    := '9'; -- クイックコード「コード区分」「配送先」
    cv_ship_disable                  xxcmn_item_mst2_v.ship_class%TYPE :=  '0';  -- 出荷区分「否」
-- Ver1.15 M.Hokkanji Start
-- 内部変更178,T_S_476対応
--    cv_obsolete_class                xxcmn_item_mst2_v.obsolete_class%TYPE :=  'D';  -- 
    cv_obsolete_class                xxcmn_item_mst2_v.obsolete_class%TYPE :=  '1';  --
    cv_tran_type_name_ara            VARCHAR2(10)   := '荒茶出荷';
    cv_tran_type_name                VARCHAR2(15)   := '取引タイプ名';
    cv_table_name_tran               VARCHAR2(30)   := '受注タイプ情報VIEW';
    cv_weight_capacity_class_1       VARCHAR2(1)    := '1'; -- 重量
    cv_small_amount_class_1          VARCHAR2(1)    := '1'; -- 小口区分
-- Ver1.15 M.Hokkanji End
-- Ver1.19 M.Hokkanji Start
    cv_tran_type_name_mat            VARCHAR2(10)   := '資材出荷';
-- Ver1.19 M.Hokkanji End
    cv_prod_class_leaf               VARCHAR2(1)    := '1'; -- リーフ
    cv_rate_class                    xxcmn_item_mst2_v.rate_class%TYPE :=  '0';  -- 
    cv_item_kbn                      VARCHAR2(8)    := '品目区分'; -- 
    cv_get_oprtn_day_api             VARCHAR2(50)   := '稼働日算出関数'; -- 
    cv_get_oprtn_day_lt              VARCHAR2(50)   := '生産物流LT／引取変更LT';
    cv_calc_lead_time_api            VARCHAR2(50)   := 'リードタイム算出';
    cv_get_oprtn_day_lt2             VARCHAR2(50)   := '配送リードタイム';
    cv_get_max_pallet_qty_api        VARCHAR2(50)   := '最大パレット枚数チェック';
    cv_get_max_pallet_qty_msg        VARCHAR2(50)   := '最大パレット枚数が取得できませんでした。';
    cv_master_check_msg              VARCHAR2(50)   := '出荷可能品目ではありません（出荷区分＝「否」）';
    cv_master_check_msg2             VARCHAR2(50)   := '売上対象区分が「1」ではありません';
-- Ver1.15 M.Hokkanji START
--    cv_master_check_msg3             VARCHAR2(50)   := '廃止区分が「D」ではありません';
    cv_master_check_msg3             VARCHAR2(50)   := '品目が廃止されているため処理できません。';
-- Ver1.15 M.Hokkanji END
    cv_master_check_msg4             VARCHAR2(50)   := '率区分が「0」ではありません';
    cv_master_check_attr             VARCHAR2(50)   := '出荷入数';
    cv_master_check_attr2            VARCHAR2(50)   := '入数';
    cv_c_s_j_chk   VARCHAR2(50)   := '出荷数制限（商品部）';
    cv_c_s_j_api   VARCHAR2(50)   := '出荷可否チェック';
    cv_c_s_j_msg   VARCHAR2(50)   := '出荷可否チェックでエラーが発生しました。';
    cv_c_s_j_msg3  VARCHAR2(50)   := '出庫形態（引取変更）が取得できませんでした。';   -- 2008/07/08 ST不具合対応#405
    cv_c_s_j_chk2  VARCHAR2(50)   := '出荷数制限（物流部）';
    cv_c_s_j_chk3  VARCHAR2(50)   := '引取計画チェック';
    cv_c_s_j_msg2  VARCHAR2(50)   := '出荷可否チェックで計画総量を超えています。';
    cv_c_s_j_chk4  VARCHAR2(50)   := '出荷可否チェック（引取計画チェック）';
    cv_c_s_j_chk5  VARCHAR2(50)   := '計画商品引取計画チェック';
    cv_calc_load_efficiency_api
                   VARCHAR2(50)   := '積載効率チェック(積載効率算出)';
    cv_sales_div   VARCHAR2(1)    := '1'; -- クイックコード「コード区分」「倉庫」
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(32000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(32000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
--
    -- *** ローカル変数 ***
--
    ln_retcode                       NUMBER;       -- リターンコード
    ln_d8retcode                     NUMBER;       -- D-8処理結果リターンコード
--
    ld_oprtn_day                     DATE;         -- 稼働日日付
    ld_sysdate                       DATE;         -- システム日付
    ln_data_cnt                      NUMBER := 0;  -- データ件数
    ln_warn_flg                      NUMBER := 0;  -- ワーニングフラグ
    ln_target_cnt                    NUMBER := 0;  -- 処理件数
    ln_normal_cnt                    NUMBER := 0;  -- 正常件数
    ln_warn_cnt                      NUMBER := 0;  -- ワーニング処理件数
    lv_err_message                   VARCHAR2(32000); -- エラーメッセージ
    lv_warn_message                  VARCHAR2(32000); -- ワーニングメッセージ
--
    ln_lead_time                     NUMBER;       -- 生産物流LT／引取変更LT
    ln_delivery_lt                   NUMBER;       -- 配送LT
    lv_status                        VARCHAR2(2);  -- 締めステータス
--
    ln_drink_deadweight              NUMBER;       -- ドリンク積載重量
    ln_leaf_deadweight               NUMBER;       -- リーフ積載重量
    ln_drink_loading_capacity        NUMBER;       -- ドリンク積載容積
    ln_leaf_loading_capacity         NUMBER;       -- リーフ積載容積
    ln_palette_max_qty               NUMBER;       -- パレット最大枚数
--
    lv_bfr_request_no                VARCHAR2(12); -- 前依頼No
    ln_bfr_sum_weight                NUMBER;       -- 前積載重量合計
    ln_bfr_sum_capacity              NUMBER;       -- 前積載容積合計
    lv_bfr_deliver_from              VARCHAR2(4);  -- 前出荷元保管場所
    lv_bfr_deliver_to                VARCHAR2(9);  -- 前配送先コード
    lv_bfr_shipping_method_code      VARCHAR2(2);  -- 前配送区分
    lv_bfr_prod_class                VARCHAR2(2);  -- 前商品区分
    id_bfr_schedule_ship_date        DATE;         -- 前出庫日
    lv_bfr_freight_charge_class      VARCHAR2(1);  -- 前運賃区分 2008/07/09 ST不具合対応#430
--
    lv_loading_over_class            VARCHAR2(1);  -- 積載オーバー区分
    lv_ship_methods                  VARCHAR2(30); -- 出荷方法
    ln_load_efficiency_weight        NUMBER;       -- 重量積載効率
    ln_load_efficiency_capacity      NUMBER;       -- 容積積載効率
    lv_mixed_ship_method             VARCHAR2(30); -- 混載配送区分
    ln_bfr_order_header_id           NUMBER;       -- 受注ヘッダアドオンID
--
    ln_head_sales_branch_nullflg     NUMBER;       -- 管轄拠点コードNULLチェックフラグ
    in_deliver_to_id_nullflg         NUMBER;       -- 配送先IDNULLチェックフラグ
    ln_request_no_nullflg            NUMBER;       -- 依頼NoNULLチェックフラグ
    ln_schedule_ship_date_nullflg    NUMBER;       -- 出庫日NULLチェックフラグ
    ln_s_a_d_nullflg                 NUMBER;       -- 着日NULLチェックフラグ
-- 2008/08/06 D.Nihei ADD START
    ln_case_total                    NUMBER;       -- ケース総合計
-- 2008/08/06 D.Nihei ADD END
-- Ver1.15 M.Hokkanji Start
    lt_weight_capacity_class         xxwsh_order_headers_all.weight_capacity_class%TYPE; -- 重量容積区分
    lt_transaction_type_id           xxwsh_oe_transaction_types_v.transaction_type_id%TYPE; -- 荒茶出荷ID保管
-- Ver1.15 M.Hokkanji End
-- Ver1.17 M.Hokkanji Start
    lv_bfr_freight_carrier_code      xxwsh_order_headers_all.freight_carrier_code%TYPE; --運送業者
-- Ver1.17 M.Hokkanji End
-- Ver1.19 M.Hokkanji Start
    lt_transaction_type_id_mat       xxwsh_oe_transaction_types_v.transaction_type_id%TYPE; -- 資材出荷ID保管
-- Ver1.19 M.Hokkanji End
-- Ver1.27 Y.Kazama 本番障害#1398 Add Start
    lt_party_site_number            xxcmn_cust_acct_sites2_v.party_site_number%TYPE; -- サイト番号
-- Ver1.27 Y.Kazama 本番障害#1398 Add End
-- 2008/09/01 N.Yoshida ADD START
    lv_select     VARCHAR2(32000) ;
    lv_select_other     VARCHAR2(32000) ;
    lv_select_c1     VARCHAR2(32000) ;
    lv_select_c2     VARCHAR2(32000) ;
    lv_select_c3     VARCHAR2(32000) ;
    lv_select_c4     VARCHAR2(32000) ;
    lv_select_c5     VARCHAR2(32000) ;
    lv_sql     VARCHAR2(32000) ;
    -- *** ローカル・カーソル ***    
    TYPE   ref_cursor IS REF CURSOR ;
    upd_status_cur ref_cursor ;
    TYPE ret_value  IS RECORD
      (
        shipping_item_code          xxwsh_order_lines_all.shipping_item_code%TYPE
       ,quantity                    xxwsh_order_lines_all.quantity%TYPE
       ,deliver_from_id             xxwsh_order_headers_all.deliver_from_id%TYPE
       ,schedule_ship_date          xxwsh_order_headers_all.shipped_date%TYPE
       ,head_sales_branch           xxwsh_order_headers_all.head_sales_branch%TYPE
       ,shipping_inventory_item_id  xxcmn_item_mst2_v.inventory_item_id %TYPE
       ,prod_class                  xxwsh_order_headers_all.prod_class%TYPE
       ,deliver_from                xxwsh_order_headers_all.deliver_from%TYPE
       ,deliver_to                  xxwsh_order_headers_all.deliver_to%TYPE
       ,request_no                  xxwsh_order_headers_all.request_no%TYPE
       ,schedule_arrival_date       xxwsh_order_headers_all.arrival_date%TYPE
       ,shipping_method_code        xxwsh_order_headers_all.shipping_method_code%TYPE
       ,sum_weight                  xxwsh_order_headers_all.sum_weight%TYPE
       ,sum_capacity                xxwsh_order_headers_all.sum_capacity%TYPE
       ,pallet_sum_quantity         xxwsh_order_headers_all.pallet_sum_quantity %TYPE
       ,order_type_id               xxwsh_order_headers_all.order_type_id%TYPE
       ,base_category               xxcmn_cust_accounts2_v.leaf_base_category%TYPE
       ,sum_pallet_weight           xxwsh_order_headers_all.sum_pallet_weight%TYPE
       ,weight_capacity_class       xxwsh_order_headers_all.weight_capacity_class %TYPE
       ,based_request_quantity      xxwsh_order_lines_all.based_request_quantity %TYPE
       ,request_item_code           xxwsh_order_lines_all.request_item_code  %TYPE
       ,request_item_id             xxwsh_order_lines_all.request_item_id%TYPE
       ,small_amount_class          xxwsh_ship_method2_v.small_amount_class %TYPE
       ,item_id                     xxcmn_item_mst2_v.item_id%TYPE
-- Ver1.24 M.Hokkanji Start
--       ,parent_item_id              xxcmn_item_mst2_v.parent_item_id %TYPE
-- Ver1.24 M.Hokkanji End
       ,num_of_deliver              xxcmn_item_mst2_v.num_of_deliver%TYPE
       ,num_of_cases                xxcmn_item_mst2_v.num_of_cases%TYPE
-- Ver1.24 M.Hokkanji Start
--       ,ship_class                  xxcmn_item_mst2_v.ship_class%TYPE
--       ,sales_div                   xxcmn_item_mst2_v.sales_div%TYPE
--       ,obsolete_class              xxcmn_item_mst2_v.obsolete_class%TYPE
--       ,rate_class                  xxcmn_item_mst2_v.rate_class%TYPE
-- Ver1.24 M.Hokkanji End
       ,delivery_qty                xxcmn_item_mst2_v.delivery_qty%TYPE
       ,item_class_code             xxcmn_item_categories5_v.item_class_code%TYPE
-- Ver1.24 M.Hokkanji Start
       ,opm_request_item_id         xxcmn_item_mst2_v.item_id%TYPE
       ,parent_item_id              xxcmn_item_mst2_v.parent_item_id %TYPE
       ,ship_class                  xxcmn_item_mst2_v.ship_class%TYPE
       ,sales_div                   xxcmn_item_mst2_v.sales_div%TYPE
       ,obsolete_class              xxcmn_item_mst2_v.obsolete_class%TYPE
       ,rate_class                  xxcmn_item_mst2_v.rate_class%TYPE
-- Ver1.24 M.Hokkanji End
       ,account_number              xxcmn_cust_accounts2_v.account_number%TYPE
       ,cust_enable_flag            xxcmn_cust_accounts2_v.cust_enable_flag%TYPE
       ,location_rel_code           xxcmn_cust_accounts2_v.location_rel_code %TYPE
       ,order_header_id             xxwsh_order_headers_all.order_header_id%TYPE
       ,conv_unit                   xxcmn_item_mst2_v.conv_unit%TYPE
       ,freight_charge_class        xxwsh_order_headers_all.freight_charge_class%TYPE
-- Ver 1.17 M.Hokkanji START
       ,freight_carrier_code        xxwsh_order_headers_all.freight_carrier_code%TYPE
-- Ver 1.17 M.Hokkanji END
      );
    loop_cnt    ret_value ;
    
    /*CURSOR upd_status_cur
    IS
      SELECT  xola.shipping_item_code shipping_item_code -- 品目コード - 受注明細アドオン.出荷品目
            , xola.quantity           quantity           -- 数量 - 受注明細アドオン.数量
            , xoha.deliver_from_id    deliver_from_id    -- 出荷元ID - 受注ヘッダアドオン.出荷元ID
            , NVL(xoha.shipped_date,xoha.schedule_ship_date)
                                   schedule_ship_date    -- 出庫日 - 受注ヘッダアドオン.出荷予定日
            , xoha.head_sales_branch  head_sales_branch  -- 拠点コード - 受注ヘッダアドオン.管轄拠点
            , ximv.inventory_item_id 
                            shipping_inventory_item_id   -- 品目ID - invの品目ID
            , xoha.prod_class         prod_class         -- 商品区分 - 受注ヘッダアドオン.商品区分
            , xoha.deliver_from       deliver_from       -- 出荷元保管場所コード - 受注ヘッダアドオン.出荷元保管場所
            , NVL(xoha.result_deliver_to,xoha.deliver_to)         deliver_to         -- 配送先コード - 受注ヘッダアドオン.出荷先
            , xoha.request_no         request_no         -- 依頼No - 受注ヘッダアドオン.依頼No
            , NVL(xoha.arrival_date,xoha.schedule_arrival_date) 
                                   schedule_arrival_date -- 着日 - 受注ヘッダアドオン.着荷予定日
            , NVL(xoha.result_shipping_method_code,xoha.shipping_method_code) 
                                    shipping_method_code -- 配送区分 - 受注ヘッダアドオン.配送区分
            , xoha.sum_weight         sum_weight         -- 積載重量合計 - 受注ヘッダアドオン.積載重量合計
            , xoha.sum_capacity       sum_capacity       -- 積載容積合計 - 受注ヘッダアドオン.積載容積合計
            , xoha.pallet_sum_quantity
                                    pallet_sum_quantity  -- パレット合計枚数 - 受注ヘッダアドオン.パレット合計枚数
            , xoha.order_type_id      order_type_id      -- 受注タイプID - 受注ヘッダアドオン.受注タイプID
            , DECODE(iv_prod_class
                ,'1', xcav.leaf_base_category            -- リーフ拠点カテゴリ 顧客情報VIEW2
                ,'2', xcav.drink_base_category           -- ドリンク拠点カテゴリ 顧客情報VIEW2
                      ,'') base_category                 -- 拠点カテゴリ
-- Ver1.15 M.Hokkanji START
            , xoha.sum_pallet_weight  sum_pallet_weight  -- 合計パレット重量 変更#173
            , xoha.weight_capacity_class weight_capacity_class -- 重量容積区分
            , xola.based_request_quantity based_request_quantity -- 拠点依頼数量
            , xola.request_item_code request_item_code   -- 依頼品目コード
            , xola.request_item_id request_item_id       -- 依頼品目ID
            , xsmv.small_amount_class small_amount_class -- 小口区分
            , ximv.item_id item_id                       -- 品目ID(OPMの品目ID)
            , ximv.parent_item_id parent_item_id         -- 親品目ID
-- Ver1.15 M.Hokkanji END
            , ximv.num_of_deliver     num_of_deliver     -- 出荷入数 - OPM品目マスタ.出荷入数
            , ximv.num_of_cases       num_of_cases       -- 入数 OPM品目マスタ.入数
            , ximv.ship_class         ship_class         -- 出荷区分 - OPM品目マスタ.出荷区分
            , ximv.sales_div          sales_div          -- 売上対象区分 - OPM品目マスタ. 売上対象区分
            , ximv.obsolete_class     obsolete_class     -- 廃止区分 - OPM品目マスタ. 廃止区分
            , ximv.rate_class         rate_class         -- 率区分 - OPM品目マスタ. 率区分
            , ximv.delivery_qty       delivery_qty       -- 配数 - OPM品目マスタ.配数
            , xicv.item_class_code    item_class_code    -- 品目区分 - 品目カテゴリ.セグメント1
            , xcav.account_number     account_number     -- 顧客コード - 顧客マスタ. 顧客コード
            , xcav.cust_enable_flag   cust_enable_flag   -- 中止客申請フラグ - 顧客マスタ. 中止客申請フラグ
            , xcav.location_rel_code  location_rel_code  -- 拠点実績有無区分 - 顧客マスタ.拠点実績有無区分
            , xoha.order_header_id    order_header_id    -- 受注ヘッダアドオンID
            , ximv.conv_unit          conv_unit          -- 入出庫換算単位 OPM品目マスタ入出庫換算単位
            , xoha.freight_charge_class   freight_charge_class   -- 運賃区分 2008/07/09 ST不具合対応#430
      FROM
         xxwsh_oe_transaction_types2_v xottv  --①受注タイプ情報VIEW2
        ,xxwsh_order_headers_all       xoha   --②受注ヘッダアドオン
        ,xxwsh_order_lines_all         xola   --③受注明細アドオン
        ,xxcmn_cust_accounts2_v        xcav   --④顧客情報VIEW2
        ,xxcmn_cust_acct_sites2_v      xcasv  --⑤顧客サイト情報VIEW2
        ,xxcmn_item_mst2_v             ximv   --⑥OPM品目情報VIEW2
        ,xxcmn_item_categories5_v      xicv   --OPM品目カテゴリ割当情報VIEW5
-- Ver1.15 M.Hokkanji START
        ,xxwsh_ship_method2_v          xsmv   --配送区分情報VIEW2
-- Ver1.15 M.Hokkanji END
      WHERE xottv.order_category_code   =  cv_order_category_code 
                                --受注カテゴリコード
      AND   xottv.shipping_shikyu_class =  cv_shipping_shikyu_class
                                -- 出荷支給区分＝「出荷依頼
      AND   xoha.order_type_id          =  xottv.TRANSACTION_TYPE_ID
                                -- 受注ヘッダアドオン.受注タイプID＝受注タイプ.取引タイプIDかつ
      AND   xoha.latest_external_flag   =  cv_latest_external_flag
                                -- 最新フラグ＝’Y'
      AND   xoha.prod_class             =  iv_prod_class
                                -- 受注ヘッダアドオン.商品区分＝パラメータ.商品区分 かつ
      AND   xoha.req_status             =  gv_status_01
                                -- 受注ヘッダアドオン.ステータス＝「01:入力中」かつ
      AND   (1 = ln_request_no_nullflg -- フラグが0なら依頼Noを条件に追加する
             OR xoha.request_no = iv_request_no)
                                -- 受注ヘッダアドオン.依頼No＝パラメータ.依頼Noかつ
      AND   (1 = ln_head_sales_branch_nullflg -- フラグが0なら管轄拠点コードを条件に追加する
             OR xoha.head_sales_branch = iv_head_sales_branch)
                                -- 受注ヘッダアドオン.管轄拠点＝パラメータ.管轄拠点コードかつ
      AND   xoha.input_sales_branch     =  iv_input_sales_branch
                                -- 受注ヘッダアドオン.入力拠点＝パラメータ.入力拠点コードかつ
      AND   (1 = ln_schedule_ship_date_nullflg -- フラグが0なら出庫日を条件に追加する
             OR NVL(xoha.shipped_date,xoha.schedule_ship_date) = id_schedule_ship_date)
                                -- 受注ヘッダアドオン.出荷予定日＝パラメータ.出庫日かつ
      AND   (1 = ln_s_a_d_nullflg -- フラグが0なら着日を条件に追加する
             OR NVL(xoha.arrival_date,xoha.schedule_arrival_date) = id_schedule_arrival_date)
                                -- 受注ヘッダアドオン.着荷予定日＝パラメータ.着日かつ
      AND   (1 = in_deliver_to_id_nullflg -- フラグが0なら配送先IDを条件に追加する
             OR NVL(xoha.result_deliver_to_id,xoha.deliver_to_id) = in_deliver_to_id)
                                -- 受注ヘッダアドオン.出荷先ID＝パラメータ.配送先IDかつ
      AND   xoha.order_header_id        =  xola.order_header_id
        -- 受注ヘッダアドオン.受注ヘッダアドオンID＝受注明細アドオン.受注ヘッダアドオンIDかつ
      AND   NVL(xoha.result_deliver_to_id,xoha.deliver_to_id)          =  xcasv.party_site_id
        -- 受注ヘッダアドオン.出荷先ID ＝ パーティサイトアドオンマスタ.パーティサイトIDかつ
      AND   xcav.party_id               =    xcasv.party_id 
        -- パーティアドオンマスタ.パーティサイトID＝パーティサイトアドオンマスタ.パーティサイトIDかつ
      AND   xcav.start_date_active   <= NVL(id_schedule_ship_date,NVL(xoha.shipped_date,xoha.schedule_ship_date))
                                -- パーティアドオンマスタ.適用開始日≦パラメータ.出庫日かつ
      AND   xcav.end_date_active     >= NVL(id_schedule_ship_date,NVL(xoha.shipped_date,xoha.schedule_ship_date))
                                -- パーティアドオンマスタ.適用終了日≧パラメータ. 出庫日かつ
      AND   xcasv.start_date_active  <= NVL(id_schedule_ship_date,NVL(xoha.shipped_date,xoha.schedule_ship_date))
                                -- パーティサイトアドオンマスタ.適用開始日≦パラメータ. 出庫日かつ
      AND   xcasv.end_date_active    >= NVL(id_schedule_ship_date,NVL(xoha.shipped_date,xoha.schedule_ship_date))
                                -- パーティサイトアドオンマスタ.適用終了日≧パラメータ. 出庫日かつ
      AND   ximv.item_no             =  xola.shipping_item_code
                                -- OPM品目マスタ.品目＝受注明細アドオン.出荷品目かつ
      AND   ximv.start_date_active   <= NVL(id_schedule_ship_date,NVL(xoha.shipped_date,xoha.schedule_ship_date))
                                -- OPM品目アドオンマスタ.適用開始日≦パラメータ. 出庫日かつ
      AND   ximv.end_date_active     >= NVL(id_schedule_ship_date,NVL(xoha.shipped_date,xoha.schedule_ship_date))
                                -- OPM品目アドオンマスタ.適用終了日≧パラメータ. 出庫日かつ
      AND   xicv .item_id            =  ximv.item_id 
                                -- OPM品目カテゴリ割当(品目区分).品目ID＝OPM品目アドオンマスタ.品目ID
      AND   xola.delete_flag         <> cv_delete_flag
                                -- 受注明細アドオン.削除フラグ ≠ ’Y’
      AND   xcav.account_status      =  gv_status_A--（有効）
      AND   xottv.start_date_active  <= NVL(id_schedule_ship_date,NVL(xoha.shipped_date,xoha.schedule_ship_date))
      AND  (xottv.end_date_active    IS NULL
      OR    xottv.end_date_active    >= NVL(id_schedule_ship_date,NVL(xoha.shipped_date,xoha.schedule_ship_date)))
-- Ver 1.15 M.Hokkanji START
      AND   xsmv.ship_method_code(+) = NVL(xoha.result_shipping_method_code,xoha.shipping_method_code)
      AND   xsmv.start_date_active(+)  <= NVL(id_schedule_ship_date,NVL(xoha.shipped_date,xoha.schedule_ship_date))
      AND  (xsmv.end_date_active(+)    >= NVL(id_schedule_ship_date,NVL(xoha.shipped_date,xoha.schedule_ship_date)))
-- Ver 1.15 M.Hokkanji END
      ORDER BY xoha.request_no, xola.shipping_item_code
                                -- 依頼No,品目コード
      FOR UPDATE OF xoha.req_status NOWAIT
      ;*/
-- 2008/09/01 N.Yoshida ADD END
--
    -- *** ローカル・レコード ***
--
    -- ===============================
    -- ユーザー定義例外
    -- ===============================
--
  BEGIN
--
-- 2008/09/01 N.Yoshida ADD START
      lv_select :=
      'SELECT  xola.shipping_item_code shipping_item_code' -- 品目コード - 受注明細アドオン.出荷品目
    ||      ', xola.quantity           quantity          ' -- 数量 - 受注明細アドオン.数量
    ||      ', xoha.deliver_from_id    deliver_from_id   ' -- 出荷元ID - 受注ヘッダアドオン.出荷元ID
    ||      ', NVL(xoha.shipped_date,xoha.schedule_ship_date)'
    ||      '                        schedule_ship_date  ' -- 出庫日 - 受注ヘッダアドオン.出荷予定日
    ||      ' , xoha.head_sales_branch  head_sales_branch ' -- 拠点コード - 受注ヘッダアドオン.管轄拠点
    ||      ' , ximv.inventory_item_id '
    ||      '                 shipping_inventory_item_id ' -- 品目ID - invの品目ID
    ||      ' , xoha.prod_class         prod_class       ' -- 商品区分 - 受注ヘッダアドオン.商品区分
    ||      ' , xoha.deliver_from       deliver_from     ' -- 出荷元保管場所コード - 受注ヘッダアドオン.出荷元保管場所
    ||      ' , NVL(xoha.result_deliver_to,xoha.deliver_to)         deliver_to  '       -- 配送先コード - 受注ヘッダアドオン.出荷先
    ||      ' , xoha.request_no         request_no       ' -- 依頼No - 受注ヘッダアドオン.依頼No
    ||      ' , NVL(xoha.arrival_date,xoha.schedule_arrival_date) '
    ||      '                        schedule_arrival_date ' -- 着日 - 受注ヘッダアドオン.着荷予定日
    ||      ' , NVL(xoha.result_shipping_method_code,xoha.shipping_method_code) '
    ||      '                        shipping_method_code ' -- 配送区分 - 受注ヘッダアドオン.配送区分
    ||      ' , xoha.sum_weight         sum_weight        ' -- 積載重量合計 - 受注ヘッダアドオン.積載重量合計
    ||      ' , xoha.sum_capacity       sum_capacity      ' -- 積載容積合計 - 受注ヘッダアドオン.積載容積合計
    ||      ' , xoha.pallet_sum_quantity '
    ||      '                         pallet_sum_quantity ' -- パレット合計枚数 - 受注ヘッダアドオン.パレット合計枚数
    ||      ' , xoha.order_type_id      order_type_id     ' -- 受注タイプID - 受注ヘッダアドオン.受注タイプID
    ||      ' , DECODE(''' || iv_prod_class || ''''
    ||      '     ,''' || 1 || ''', xcav.leaf_base_category          ' -- リーフ拠点カテゴリ 顧客情報VIEW2
    ||      '     ,''' || 2 || ''', xcav.drink_base_category         ' -- ドリンク拠点カテゴリ 顧客情報VIEW2
    ||      '           ,'''')  base_category               ' -- 拠点カテゴリ
    ||      ', xoha.sum_pallet_weight  sum_pallet_weight ' -- 合計パレット重量 変更#173
    ||      ', xoha.weight_capacity_class weight_capacity_class ' -- 重量容積区分
    ||      ', xola.based_request_quantity based_request_quantity ' -- 拠点依頼数量
    ||      ', xola.request_item_code request_item_code  ' -- 依頼品目コード
    ||      ', xola.request_item_id request_item_id      ' -- 依頼品目ID
    ||      ', xsmv.small_amount_class small_amount_class ' -- 小口区分
    ||      ', ximv.item_id item_id                      ' -- 品目ID(OPMの品目ID)
-- Ver1.24 M.Hokkanji Start
--    ||      ', ximv.parent_item_id parent_item_id        ' -- 親品目ID
-- Ver1.24 M.Hokkanji End
    ||      ', ximv.num_of_deliver     num_of_deliver    ' -- 出荷入数 - OPM品目マスタ.出荷入数
    ||      ', ximv.num_of_cases       num_of_cases      ' -- 入数 OPM品目マスタ.入数
-- Ver1.24 M.Hokkanji Start
--    ||      ', ximv.ship_class         ship_class        ' -- 出荷区分 - OPM品目マスタ.出荷区分
--    ||      ', ximv.sales_div          sales_div         ' -- 売上対象区分 - OPM品目マスタ. 売上対象区分
--    ||      ', ximv.obsolete_class     obsolete_class    ' -- 廃止区分 - OPM品目マスタ. 廃止区分
--    ||      ', ximv.rate_class         rate_class        ' -- 率区分 - OPM品目マスタ. 率区分
-- Ver1.24 M.Hokkanji End
    ||      ', ximv.delivery_qty       delivery_qty      ' -- 配数 - OPM品目マスタ.配数
    ||      ', xicv.item_class_code    item_class_code   ' -- 品目区分 - 品目カテゴリ.セグメント1
-- Ver1.24 M.Hokkanji Start
    ||      ', ximv2.item_id opm_request_item_id         ' -- 品目ID(OPMの品目ID)
    ||      ', ximv2.parent_item_id parent_item_id        ' -- 親品目ID
    ||      ', ximv2.ship_class         ship_class        ' -- 出荷区分 - OPM品目マスタ.出荷区分
    ||      ', ximv2.sales_div          sales_div         ' -- 売上対象区分 - OPM品目マスタ. 売上対象区分
    ||      ', ximv2.obsolete_class     obsolete_class    ' -- 廃止区分 - OPM品目マスタ. 廃止区分
    ||      ', ximv2.rate_class         rate_class        ' -- 率区分 - OPM品目マスタ. 率区分
-- Ver1.24 M.Hokkanji End
    ||      ', xcav.account_number     account_number    ' -- 顧客コード - 顧客マスタ. 顧客コード
    ||      ', xcav.cust_enable_flag   cust_enable_flag  ' -- 中止客申請フラグ - 顧客マスタ. 中止客申請フラグ
    ||      ', xcav.location_rel_code  location_rel_code ' -- 拠点実績有無区分 - 顧客マスタ.拠点実績有無区分
    ||      ', xoha.order_header_id    order_header_id   ' -- 受注ヘッダアドオンID
    ||      ', ximv.conv_unit          conv_unit         ' -- 入出庫換算単位 OPM品目マスタ入出庫換算単位
    ||      ', xoha.freight_charge_class   freight_charge_class '  -- 運賃区分 2008/07/09 ST不具合対応#430
    ||      ', NVL(xoha.result_freight_carrier_code,xoha.freight_carrier_code) '
    ||      '                          freight_carrier_code ' -- 運送業者 - 受注ヘッダアドオン.運送業者 2008/09/24 TE080_400指摘66対応
    ||  ' FROM'
    ||  '   xxwsh_oe_transaction_types2_v xottv ' --①受注タイプ情報VIEW2
    ||  '  ,xxwsh_order_headers_all       xoha  ' --②受注ヘッダアドオン
    ||  '  ,xxwsh_order_lines_all         xola  ' --③受注明細アドオン
    ||  '  ,xxcmn_cust_accounts2_v        xcav  ' --④顧客情報VIEW2
    ||  '  ,xxcmn_cust_acct_sites2_v      xcasv ' --⑤顧客サイト情報VIEW2
    ||  '  ,xxcmn_item_mst2_v             ximv  ' --⑥OPM品目情報VIEW2
-- Ver1.24 M.Hokkanji Start
    ||  '  ,xxcmn_item_mst2_v             ximv2 ' --OPM品目情報VIEW2(依頼品目用)
-- Ver1.24 M.Hokkanji End
    ||  '  ,xxcmn_item_categories5_v      xicv  ' --OPM品目カテゴリ割当情報VIEW5
    ||  '  ,xxwsh_ship_method2_v          xsmv  ' --配送区分情報VIEW2
    ||  ' WHERE xottv.order_category_code   =  ''' || cv_order_category_code || ''''
                                --受注カテゴリコード
    ||  ' AND   xottv.shipping_shikyu_class =  ''' || cv_shipping_shikyu_class || ''''
                                -- 出荷支給区分＝「出荷依頼
    ||  ' AND   xoha.order_type_id          =  xottv.TRANSACTION_TYPE_ID '
                                -- 受注ヘッダアドオン.受注タイプID＝受注タイプ.取引タイプIDかつ
    ||  ' AND   xoha.latest_external_flag   =  ''' || cv_latest_external_flag || ''''
                                -- 最新フラグ＝’Y'
    ||  ' AND   xoha.prod_class             =  ''' || iv_prod_class || ''''
                                -- 受注ヘッダアドオン.商品区分＝パラメータ.商品区分 かつ
    ||  ' AND   xoha.req_status             =  ''' || gv_status_01 || ''''
                                -- 受注ヘッダアドオン.ステータス＝「01:入力中」かつ
    ||  ' AND   xoha.input_sales_branch     =  ''' || iv_input_sales_branch || ''''
                                -- 受注ヘッダアドオン.入力拠点＝パラメータ.入力拠点コードかつ
    ||  ' AND   xoha.order_header_id        =  xola.order_header_id '
        -- 受注ヘッダアドオン.受注ヘッダアドオンID＝受注明細アドオン.受注ヘッダアドオンIDかつ
-- Ver1.27 Y.Kazama 本番障害#1398 Mod Start
    ||  ' AND   NVL(xoha.result_deliver_to,xoha.deliver_to) = xcasv.party_site_number '
    ||  ' AND   xcasv.party_site_status                     = ''A'''  -- サイトステータス[A:有効]
--    ||  ' AND   NVL(xoha.result_deliver_to_id,xoha.deliver_to_id)          =  xcasv.party_site_id '
-- Ver1.27 Y.Kazama 本番障害#1398 Mod End
        -- 受注ヘッダアドオン.出荷先ID ＝ パーティサイトアドオンマスタ.パーティサイトIDかつ
    ||  ' AND   xcav.party_id               =    xcasv.party_id '
        -- パーティアドオンマスタ.パーティサイトID＝パーティサイトアドオンマスタ.パーティサイトIDかつ
    ||  ' AND   xcav.start_date_active   <= NVL(''' || id_schedule_ship_date || ''',NVL(xoha.shipped_date,xoha.schedule_ship_date)) '
                                -- パーティアドオンマスタ.適用開始日≦パラメータ.出庫日かつ
    ||  ' AND   xcav.end_date_active     >= NVL(''' || id_schedule_ship_date || ''',NVL(xoha.shipped_date,xoha.schedule_ship_date)) '
                                -- パーティアドオンマスタ.適用終了日≧パラメータ. 出庫日かつ
    ||  ' AND   xcasv.start_date_active  <= NVL(''' || id_schedule_ship_date || ''',NVL(xoha.shipped_date,xoha.schedule_ship_date)) '
                                -- パーティサイトアドオンマスタ.適用開始日≦パラメータ. 出庫日かつ
    ||  ' AND   xcasv.end_date_active    >= NVL(''' || id_schedule_ship_date || ''',NVL(xoha.shipped_date,xoha.schedule_ship_date)) '
                                -- パーティサイトアドオンマスタ.適用終了日≧パラメータ. 出庫日かつ
    ||  ' AND   ximv.item_no             =  xola.shipping_item_code '
                                -- OPM品目マスタ.品目＝受注明細アドオン.出荷品目かつ
    ||  ' AND   ximv.start_date_active   <= NVL(''' || id_schedule_ship_date || ''',NVL(xoha.shipped_date,xoha.schedule_ship_date)) '
                                -- OPM品目アドオンマスタ.適用開始日≦パラメータ. 出庫日かつ
    ||  ' AND   ximv.end_date_active     >= NVL(''' || id_schedule_ship_date || ''',NVL(xoha.shipped_date,xoha.schedule_ship_date)) '
                                -- OPM品目アドオンマスタ.適用終了日≧パラメータ. 出庫日かつ
    ||  ' AND   xicv .item_id            =  ximv.item_id  '
                                -- OPM品目カテゴリ割当(品目区分).品目ID＝OPM品目アドオンマスタ.品目ID
    ||  ' AND   xola.delete_flag         <> ''' || cv_delete_flag || ''''
                                -- 受注明細アドオン.削除フラグ ≠ ’Y’
-- Ver1.24 M.Hokkanji Start
    ||  ' AND   ximv2.item_no            =  xola.request_item_code '
                                -- OPM品目アドオンマスタ.品目＝受注明細アドオン.依頼品目かつ
    ||  ' AND   ximv2.start_date_active   <= NVL(''' || id_schedule_ship_date || ''',NVL(xoha.shipped_date,xoha.schedule_ship_date)) '
                                -- OPM品目アドオンマスタ.適用開始日≦パラメータ. 出庫日かつ
    ||  ' AND   ximv2.end_date_active     >= NVL(''' || id_schedule_ship_date || ''',NVL(xoha.shipped_date,xoha.schedule_ship_date)) '
                                -- OPM品目アドオンマスタ.適用終了日≧パラメータ. 出庫日かつ
-- Ver1.24 M.Hokkanji End
-- Ver1.30 H.Itou Del Start 本番障害#1648
--    ||  ' AND   xcav.account_status      =  ''' || gv_status_A || '''' --（有効）
-- Ver1.30 H.Itou Del End
    ||  ' AND   xottv.start_date_active  <= NVL(''' || id_schedule_ship_date || ''',NVL(xoha.shipped_date,xoha.schedule_ship_date)) '
    ||  ' AND  (xottv.end_date_active    IS NULL '
    ||  ' OR    xottv.end_date_active    >= NVL(''' || id_schedule_ship_date || ''',NVL(xoha.shipped_date,xoha.schedule_ship_date))) '
    ||  ' AND   xsmv.ship_method_code(+) = NVL(xoha.result_shipping_method_code,xoha.shipping_method_code) '
    ||  ' AND   xsmv.start_date_active(+)  <= NVL(''' || id_schedule_ship_date || ''',NVL(xoha.shipped_date,xoha.schedule_ship_date)) '
    ||  ' AND  (xsmv.end_date_active(+)    >= NVL(''' || id_schedule_ship_date || ''',NVL(xoha.shipped_date,xoha.schedule_ship_date))) ';
-- Ver1.30 H.Itou Add Start 本番障害#1648
    -- ステータスチェック区分が「2」の場合、顧客ステータスの制御は画面に入っているため、顧客ステータスの条件は不要
    -- ※実績入力画面で顧客ステータスが無効ののデータを入力できる。
    IF (iv_status_kbn = '1') THEN
      lv_select := lv_select ||
        ' AND   xcav.account_status      =  ''' || gv_status_A || ''''; --（有効）
    END IF;
-- Ver1.30 H.Itou Add End
    lv_select_other :=
    '  ORDER BY xoha.request_no, xola.shipping_item_code '  -- 依頼No,品目コード
    || '  FOR UPDATE OF xoha.req_status NOWAIT';
--
-- 2008/09/01 N.Yoshida ADD END
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
--
    -- 初期化
    gv_callfrom_flg := iv_callfrom_flg;
    lv_err_message := NULL;
    lv_warn_message := NULL;
    lv_bfr_request_no := '';
    ln_bfr_order_header_id := 0;
--
    -- グローバル変数の初期化
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    gn_warn_cnt   := 0;
--
    -- **************************************************
    -- *** パラメータチェック(D-1)
    -- **************************************************
--
--  必須チェック
--
    -- 「入力拠点」チェック
    IF (iv_input_sales_branch IS NULL) THEN
      -- 入力拠点のNULLチェックを行います
      lv_err_message := lv_err_message ||
               xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
                                        gv_cnst_msg_null,
                                        gv_cnst_tkn_para,
                                        gv_msg_null_02) || gv_line_feed;
    END IF;
--
    -- 「呼出元フラグ」チェック
    IF (iv_callfrom_flg IS NULL) THEN
      -- 呼出元フラグのNULLチェックを行います
      lv_err_message := lv_err_message ||
               xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
                                        gv_cnst_msg_null,
                                        gv_cnst_tkn_para,
                                        gv_msg_null_03) || gv_line_feed;
    END IF;
--
    -- 「締めステータスチェック区分」チェック
    IF (iv_status_kbn IS NULL) THEN
      -- 締めステータスチェック区分のNULLチェックを行います
      lv_err_message := lv_err_message ||
               xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
                                        gv_cnst_msg_null,
                                        gv_cnst_tkn_para,
                                        gv_msg_null_04) || gv_line_feed;
    END IF;
--
    -- 「商品区分」チェック
    IF (iv_prod_class IS NULL) THEN
      -- 商品区分のNULLチェックを行います
      lv_err_message := lv_err_message ||
               xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
                                        gv_cnst_msg_null,
                                        gv_cnst_tkn_para,
                                        gv_msg_null_07) || gv_line_feed;
    END IF;
--
--  妥当性チェック
--
    -- 「呼出元フラグ」チェック
    IF ((iv_callfrom_flg <> '1') AND (iv_callfrom_flg <> '2')) THEN
      -- 呼出元フラグのNULLチェックを行います
      lv_err_message := lv_err_message ||
               xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
                                        gv_cnst_msg_prop,
                                        gv_cnst_tkn_para,
                                        gv_msg_null_05) || gv_line_feed;
    END IF;
--
    -- 「締めステータスチェック区分」チェック
    IF ((iv_status_kbn <> '1') AND (iv_status_kbn <> '2')) THEN
      -- 締めステータスチェック区分に1、2以外のチェックを行います
      lv_err_message := lv_err_message ||
               xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
                                        gv_cnst_msg_prop,
                                        gv_cnst_tkn_para,
                                        gv_msg_null_06) || gv_line_feed;
    END IF;
-- Ver1.15 M.Hokkanji START
    -- 出庫形態(荒茶出荷)を取得
    BEGIN
      SELECT xottv.transaction_type_id
        INTO lt_transaction_type_id
        FROM xxwsh_oe_transaction_types_v xottv
       WHERE xottv.transaction_type_name = cv_tran_type_name_ara;
    EXCEPTION
      WHEN OTHERS THEN
        lv_err_message := lv_err_message ||
                 xxcmn_common_pkg.get_msg(gv_cnst_msg_cmn,
                                          gv_cnst_cmn_012,
                                          gv_cnst_tkn_table,
                                          cv_table_name_tran,
                                          gv_cnst_tkn_key,
                                          cv_tran_type_name || ':' || cv_tran_type_name_ara);
    END;
-- Ver1.15 M.Hokkanji END
-- Ver1.19 M.Hokkanji Start
    -- 出庫形態(荒茶出荷)を取得
    BEGIN
      SELECT xottv.transaction_type_id
        INTO lt_transaction_type_id_mat
        FROM xxwsh_oe_transaction_types_v xottv
       WHERE xottv.transaction_type_name = cv_tran_type_name_mat;
    EXCEPTION
      WHEN OTHERS THEN
        lv_err_message := lv_err_message ||
                 xxcmn_common_pkg.get_msg(gv_cnst_msg_cmn,
                                          gv_cnst_cmn_012,
                                          gv_cnst_tkn_table,
                                          cv_table_name_tran,
                                          gv_cnst_tkn_key,
                                          cv_tran_type_name || ':' || cv_tran_type_name_mat);
    END;
-- Ver1.19 M.Hokkanji End
--
    -- **************************************************
    -- *** メッセージの整形
    -- **************************************************
    -- メッセージが登録されている場合
    IF (lv_err_message IS NOT NULL) THEN
      -- 最後の改行コードを削除しOUTパラメータに設定
      lv_errmsg := RTRIM(lv_err_message, gv_line_feed);
      -- エラーとして終了
      RAISE global_api_expt;
    END IF;
--
--
-- 2008/09/01 N.Yoshida ADD START
    /*
    -- パラメータ.管轄拠点コードNULLチェック
    IF  (iv_head_sales_branch IS NULL) THEN
      -- 管轄拠点コードがNULLの場合
      ln_head_sales_branch_nullflg := 1;
    ELSE
      ln_head_sales_branch_nullflg := 0;
    END IF;
--
    -- パラメータ.配送先IDNULLチェック
    IF  (in_deliver_to_id IS NULL) THEN
      -- 配送先IDがNULLの場合
      in_deliver_to_id_nullflg := 1;
    ELSE
      in_deliver_to_id_nullflg := 0;
    END IF;
--
    -- パラメータ.依頼No NULLチェック
    IF  (iv_request_no IS NULL) THEN
      -- 配送先IDがNULLの場合
      ln_request_no_nullflg := 1;
    ELSE
      ln_request_no_nullflg := 0;
    END IF;
--
    -- パラメータ.出庫日 NULLチェック
    IF  (id_schedule_ship_date IS NULL) THEN
      -- 出庫日がNULLの場合
      ln_schedule_ship_date_nullflg := 1;
    ELSE
      ln_schedule_ship_date_nullflg := 0;
    END IF;
--
    -- パラメータ.着日 NULLチェック
    IF  (id_schedule_arrival_date IS NULL) THEN
      -- 着日がNULLの場合
      ln_s_a_d_nullflg := 1;
    ELSE
      ln_s_a_d_nullflg := 0;
    END IF;
    */
    -- パラメータ.管轄拠点コードNULLチェック
    IF  (iv_head_sales_branch IS NULL) THEN
      -- 管轄拠点コードがNULLの場合
      lv_select_c1 := '';
    ELSE
      lv_select_c1 := ' AND xoha.head_sales_branch = ''' || iv_head_sales_branch || '''';
    END IF;
--
    -- パラメータ.配送先IDNULLチェック
    IF  (in_deliver_to_id IS NULL) THEN
      -- 配送先IDがNULLの場合
      lv_select_c2 := '';
    ELSE
-- Ver1.27 Y.Kazama 本番障害#1398 Mod Start
      -- 配送先IDを基に配送先コード取得
      SELECT xcasv.party_site_number
      INTO   lt_party_site_number
-- Ver1.28 H.Itou 本番障害#1398 Mod Start アドオンマスタに複数登録されている場合があるのため、VIEW1に変更
--      FROM   xxcmn_cust_acct_sites2_v  xcasv
      FROM   xxcmn_cust_acct_sites_v  xcasv
-- Ver1.28 H.Itou 本番障害#1398 Mod End
      WHERE  xcasv.party_site_id     = in_deliver_to_id
-- Ver1.28 H.Itou 本番障害#1398 Del Start
--      AND    xcasv.party_site_status = 'A'  -- サイトステータス[A:有効]
-- Ver1.28 H.Itou 本番障害#1398 Del End
      ;
--
      lv_select_c2 := ' AND NVL(xoha.result_deliver_to,xoha.deliver_to) = ''' || lt_party_site_number ||  '''';
--      lv_select_c2 := ' AND NVL(xoha.result_deliver_to_id,xoha.deliver_to_id) = ''' || in_deliver_to_id ||  '''';
-- Ver1.27 Y.Kazama 本番障害#1398 Mod End
    END IF;
--
    -- パラメータ.依頼No NULLチェック
    IF  (iv_request_no IS NULL) THEN
      -- 配送先IDがNULLの場合
      lv_select_c3 := '';
    ELSE
      lv_select_c3 := ' AND xoha.request_no = ''' || iv_request_no || '''';
    END IF;
--
    -- パラメータ.出庫日 NULLチェック
    IF  (id_schedule_ship_date IS NULL) THEN
      -- 出庫日がNULLの場合
      lv_select_c4 := '';
    ELSE
      lv_select_c4 := ' AND NVL(xoha.shipped_date,xoha.schedule_ship_date) = ''' || id_schedule_ship_date || '''';
    END IF;
--
    -- パラメータ.着日 NULLチェック
    IF  (id_schedule_arrival_date IS NULL) THEN
      -- 着日がNULLの場合
      lv_select_c5 := '';
    ELSE
      lv_select_c5 := ' AND NVL(xoha.arrival_date,xoha.schedule_arrival_date) = ''' || id_schedule_arrival_date || '''';
    END IF;
-- 2008/09/01 N.Yoshida ADD END
--
    ld_sysdate := TRUNC(SYSDATE); -- システム日付の取得
--
--  更新用PL/SQL表初期化
    gt_header_id_upd_tab.DELETE;                 -- 受注ヘッダアドオンID
--
    -- ========================================
    -- データのチェックを行う
    -- ========================================
--
-- 2008/09/01 N.Yoshida ADD START
    --<<data_loop>>
    --FOR loop_cnt IN upd_status_cur LOOP
    OPEN upd_status_cur FOR lv_select || lv_select_c1 || lv_select_c2 || lv_select_c3 || lv_select_c4 ||
                            lv_select_c5 || lv_select_other;
    <<data_loop>>
    LOOP
      FETCH upd_status_cur INTO loop_cnt;
      EXIT WHEN upd_status_cur%NOTFOUND;
-- 2008/09/01 N.Yoshida ADD END
--
      -- 処理件数をカウント
      IF (ln_bfr_order_header_id <> loop_cnt.order_header_id) THEN
        ln_target_cnt := ln_target_cnt + 1;
        ln_bfr_order_header_id := loop_cnt.order_header_id;
      END IF;
--
      ln_data_cnt := ln_data_cnt + 1;
--
      -- 呼出元フラグが1:コンカレントの場合
      IF (iv_callfrom_flg = '1') THEN
        -- **************************************************
        -- *** 稼働日チェック(D-3)
        -- **************************************************
  --
-- Ver1.15 M.Hokkanji START
-- 稼働日チェックは荒茶出荷の場合はチェックを行わない
        IF ( loop_cnt.order_type_id <> lt_transaction_type_id) THEN
-- Ver1.15 M.Hokkanji END
          -- 出庫日の稼働日チェック
          ln_retcode := xxwsh_common_pkg.get_oprtn_day(loop_cnt.schedule_ship_date, -- D-2出庫日
                                                       loop_cnt.deliver_from,       -- D-2出荷元保管場所
                                                       NULL,                        -- 配送先コード
                                                       0,                           -- リードタイム
                                                       loop_cnt.prod_class,         -- D-2商品区分
                                                       ld_oprtn_day);               -- 稼働日日付
--
          -- リターン・コードにエラーが返された場合はエラー
          IF (ln_retcode = gn_status_error) THEN
            lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
                                                  gv_cnst_msg_155,
                                                  'API_NAME',
                                                  cv_get_oprtn_day_api,
                                                  'ERR_MSG',
                                                  '',
                                                  'REQUEST_NO',
                                                  loop_cnt.request_no);
            RAISE global_api_expt;
--
          -- 出庫日が稼働日でない場合はエラー
-- Ver1.15 M.Hokkanji TE080_400指摘No75 START
          -- 稼働日日付が一致しない場合はエラーに変更
--          ELSIF (ld_oprtn_day IS NULL) THEN
          ELSIF (ld_oprtn_day <> loop_cnt.schedule_ship_date) THEN
-- Ver1.15 M.Hokkanji TE080_400指摘No75 END
            lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
                                                  gv_cnst_msg_154,
                                                  'IN_DATE',
-- Ver1.15 M.Hokkanji TE080_400指摘No75 START
--                                                  loop_cnt.schedule_ship_date,
                                                  TO_CHAR(loop_cnt.schedule_ship_date,'YYYY/MM/DD'),
-- Ver1.15 M.Hokkanji TE080_400指摘No75 END
                                                  'REQUEST_NO',
                                                  loop_cnt.request_no);
            RAISE global_api_expt;
          END IF;
--
          -- 着日の稼働日チェック
          ln_retcode := xxwsh_common_pkg.get_oprtn_day(loop_cnt.schedule_arrival_date, -- D-2着日
                                                       NULL,                  -- 出荷元保管場所
                                                       loop_cnt.deliver_to,   -- 配送先コード
                                                       0,                     -- リードタイム
                                                       loop_cnt.prod_class,   -- D-2商品区分
                                                       ld_oprtn_day);         -- 稼働日日付
--
          -- リターン・コードにエラーが返された場合はエラー
          IF (ln_retcode = gn_status_error) THEN
            lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
                                                  gv_cnst_msg_155,
                                                  'API_NAME',
                                                  cv_get_oprtn_day_api,
                                                  'ERR_MSG',
                                                  '',
                                                  'REQUEST_NO',
                                                  loop_cnt.request_no);
            RAISE global_api_expt;
--
          -- 着日が稼働日でない場合は警告
-- Ver1.15 M.Hokkanji TE080_400指摘No75 START
          -- 稼働日日付が一致しない場合はエラーに変更
--          ELSIF (ld_oprtn_day IS NULL) THEN
          ELSIF (ld_oprtn_day <> loop_cnt.schedule_arrival_date) THEN
-- Ver1.15 M.Hokkanji TE080_400指摘No75 END
            lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
                                                  gv_cnst_msg_154,
                                                  'IN_DATE',
-- Ver1.15 M.Hokkanji TE080_400指摘No75 START
--                                                  loop_cnt.schedule_arrival_date,
                                                  TO_CHAR(loop_cnt.schedule_arrival_date,'YYYY/MM/DD'),
-- Ver1.15 M.Hokkanji TE080_400指摘No75 END
                                                  'REQUEST_NO',
                                                  loop_cnt.request_no) || gv_line_feed;
            -- 警告をセット
            ln_warn_cnt := 1;
            IF (gv_callfrom_flg = '1') THEN
              FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg );
            -- Ver1.18 MARUSHITA START
            ELSE
              lv_warn_message := lv_warn_message || lv_errmsg || gv_line_feed;
            -- Ver1.18 MARUSHITA END
            END IF;
          END IF;
-- Ver1.15 M.Hokkanji START
        END IF;
-- Ver1.15 M.Hokkanji END
  --
        -- 引当対象チェック
        ln_retcode := allow_pickup_flag_chk(loop_cnt.deliver_from,   -- D-2出荷元保管場所
                                            lv_retcode,              -- リターンコード
                                            lv_errbuf,               -- エラーメッセージコード
                                            lv_errmsg);              -- エラーメッセージ
  --
        -- リターン・コードにエラーが返された場合はエラー
        IF (ln_retcode = gn_status_error) THEN
          lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
                                                gv_cnst_msg_175,
                                                'REQUEST_NO',
                                                loop_cnt.request_no,
                                                'SHIP_FROM',
                                                loop_cnt.deliver_from);
          RAISE global_api_expt;
        END IF;
  --
-- Ver1.15 M.Hokkanji START
-- リードタイムチェックは荒茶出荷の場合はチェックを行わない
        IF ( loop_cnt.order_type_id <> lt_transaction_type_id) THEN
-- Ver1.15 M.Hokkanji END
          -- **************************************************
          -- *** リードタイムチェック(D-4)
          -- **************************************************
--
          xxwsh_common910_pkg.calc_lead_time('4',                            -- 倉庫
                                             loop_cnt.deliver_from,          -- D-2出荷元保管場所
                                             '9',                            -- 配送先
                                             loop_cnt.deliver_to,            -- D-2配送先コード
                                             loop_cnt.prod_class,            -- D-2商品区分
                                             loop_cnt.order_type_id,         -- D-2受注タイプID
                                             loop_cnt.schedule_ship_date,    -- D-2出荷予定日
                                             lv_retcode,                     -- リターンコード
                                             lv_errbuf,                      -- エラーメッセージコード
                                             lv_errmsg,                      -- エラーメッセージ
                                             ln_lead_time,                   -- 生産物流LT／引取変更LT
                                             ln_delivery_lt);                -- 配送LT
--
          -- リターン・コードにエラーが返された場合はエラー
          IF (ln_retcode = gn_status_error) THEN
            lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
                                                  gv_cnst_msg_155,
                                                  'API_NAME',
                                                  cv_calc_lead_time_api,
                                                  'ERR_MSG',
                                                  lv_errmsg,
                                                  'REQUEST_NO',
                                                  loop_cnt.request_no);
            RAISE global_api_expt;
          END IF;
--
          -- リードタイム妥当チェック
-- Ver1.23 M.Hokkanji Start
--          ln_retcode :=
-- Ver1.23 M.Hokkanji End
-- Ver1.19 M.Hokkanji Start
-- 出庫日の生産物流LTの稼働日を取得するように変更
--          xxwsh_common_pkg.get_oprtn_day(loop_cnt.schedule_arrival_date, -- D-2着日
--                                         NULL,                           -- 出荷元保管場所
--                                         loop_cnt.deliver_to,            -- D-2配送先コード
--                                         ln_delivery_lt,                 -- リードタイム
--                                         loop_cnt.prod_class,            -- D-2商品区分
--                                         ld_oprtn_day);                  -- 稼働日日付
-- Ver1.23 M.Hokkanji Start
--          xxwsh_common_pkg.get_oprtn_day(loop_cnt.schedule_ship_date,    -- D-2出荷予定日
--                                         NULL,                           -- 出荷元保管場所
--                                         loop_cnt.deliver_to,            -- D-2配送先コード
--                                         ln_lead_time,                   -- 生産物流LT
--                                         loop_cnt.prod_class,            -- D-2商品区分
--                                         ld_oprtn_day);                  -- 稼働日日付
-- Ver1.23 M.Hokkanji End
-- Ver1.19 M.Hokkanji End
--
-- Ver1.23 M.Hokkanji Start
          -- リターン・コードにエラーが返された場合はエラー
--          IF (ln_retcode = gn_status_error) THEN
--            lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
-- Ver1.15 M.Hokkanji START
 --                                                 gv_cnst_msg_155,
--                                                  gv_cnst_msg_154,
-- Ver1.15 M.Hokkanji END
--                                                  'API_NAME',
--                                                  cv_get_oprtn_day_api,
--                                                  'ERR_MSG',
--                                                  '',
--                                                  'REQUEST_NO',
--                                                  loop_cnt.request_no);
--            RAISE global_api_expt;
--          END IF;
-- Ver1.23 M.Hokkanji End
--
-- Ver1.19 M.Hokkanji Start
          IF (ln_delivery_lt IS NULL ) THEN
            lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
                                                  gv_cnst_msg_177,
                                                  'REQUEST_NO',
                                                  loop_cnt.request_no);
            RAISE global_api_expt;
          END IF;
-- Ver1.19 M.Hokkanji End
          -- D-2出庫日 > (着日 - 配送LT)
          IF (loop_cnt.schedule_ship_date >
                 (loop_cnt.schedule_arrival_date - ln_delivery_lt)) THEN
 --          IF (loop_cnt.schedule_ship_date > ld_oprtn_day) THEN
            -- リードタイムを満たしていない
-- Ver1.19 M.Hokkanji End
            lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
                                                  gv_cnst_msg_153,
                                                  'LT_CLASS',
-- Ver1.19 M.Hokkanji Start
--                                                  cv_get_oprtn_day_lt,
                                                  cv_get_oprtn_day_lt2,
-- Ver1.19 M.Hokkanji End
                                                  'REQUEST_NO',
                                                  loop_cnt.request_no);
            RAISE global_api_expt;
          END IF;
--
          -- システム日付 > 稼働日
-- Ver1.19 M.Hokkanji Start
--          IF (ld_sysdate > ld_oprtn_day) THEN
-- Ver1.23 M.Hokkanji Start
--          IF (ld_sysdate > ld_oprtn_day + 1) THEN
          IF (ld_sysdate > (loop_cnt.schedule_ship_date - ln_lead_time + 1)) THEN
-- Ver1.23 M.Hokkanji End
-- Ver1.19 M.Hokkanji End
            -- 配送リードタイムが妥当でない
            lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
                                                  gv_cnst_msg_153,
                                                  'LT_CLASS',
-- Ver1.19 M.Hokkanji Start
                                                  cv_get_oprtn_day_lt,
                                                  --cv_get_oprtn_day_lt2,
-- Ver1.19 M.Hokkanji End
                                                  'REQUEST_NO',
                                                  loop_cnt.request_no);
            RAISE global_api_expt;
          END IF;
-- Ver1.15 M.Hokkanji START
        END IF;
-- Ver1.15 M.Hokkanji END
      END IF;
--
      IF (iv_status_kbn = '1') THEN  -- 2008/07/30 ST不具合対応#501
        -- 締めステータスチェック区分が1:チェック有りの場合
        -- D-2中止客申請フラグが'0'以外の場合はエラー
        IF (loop_cnt.cust_enable_flag <> '0') THEN
          lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
                                                gv_cnst_msg_164,
                                                'REQUEST_NO',
                                                loop_cnt.request_no,
                                                'CUST',
                                                loop_cnt.account_number);
          RAISE global_api_expt;
--
        END IF;
--
      -- **************************************************
      -- *** 締めステータス・顧客チェック(D-5)
      -- **************************************************
--
--      IF (iv_status_kbn = '1') THEN  2008/07/30 ST不具合対応#501
        -- 締めステータスチェック区分が1:チェック有りの場合
        lv_status :=
        xxwsh_common_pkg.check_tightening_status(loop_cnt.order_type_id,       -- D-2受注タイプID
                                                 loop_cnt.deliver_from,        -- D-2出荷元保管場所
                                                 loop_cnt.head_sales_branch,   -- D-2拠点
                                                 NULL,                         -- 拠点カテゴリ
                                                 ln_lead_time,                 -- D-4生産物流LT
                                                 loop_cnt.schedule_ship_date,  -- D-2出庫日
                                                 loop_cnt.prod_class);         -- D-2商品区分
--
        -- 締めステータスが'2'または'4'の場合はエラー
        IF ((lv_status = '2') OR (lv_status = '4')) THEN
          lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
                                                gv_cnst_msg_160,
                                                'REQUEST_NO',
                                                loop_cnt.request_no);
          RAISE global_api_expt;
--
        END IF;
--
        -- **************************************************
        -- *** 最大パレット枚数チェック(D-6)
        -- **************************************************
--
        -- 最大パレット枚数算出関数               運賃区分がONの場合にチェックする(2008/07/09 ST不具合対応#430)
        --                                        商品区分がドリンクの場合にチェックする(2008/07/29 ST不具合対応#503)
-- 2008/07/29 D.Nihei MOD START
--        IF ( loop_cnt.freight_charge_class = gv_freight_charge_class_on ) THEN  -- 2008/07/09 ST不具合対応#430
        IF ( (loop_cnt.freight_charge_class = gv_freight_charge_class_on )
         AND (loop_cnt.prod_class           = gv_drink                   ) ) THEN  -- 2008/07/29 ST不具合対応#503
-- 2008/07/29 D.Nihei MOD START
--
          ln_retcode :=
          xxwsh_common_pkg.get_max_pallet_qty(cv_whse_code, -- クイックコード「コード区分」「倉庫」
                                              loop_cnt.deliver_from,         -- D-2出荷元保管場所
                                              cv_deliver_to,
                                                            -- クイックコード「コード区分」「配送先」
                                              loop_cnt.deliver_to,           -- D-2配送先コード
                                              loop_cnt.schedule_ship_date,   -- D-2出庫日
                                              loop_cnt.shipping_method_code, -- D-2配送区分
                                              ln_drink_deadweight,           -- ドリンク積載重量
                                              ln_leaf_deadweight,            -- リーフ積載重量
                                              ln_drink_loading_capacity,     -- ドリンク積載容積
                                              ln_leaf_loading_capacity,      -- リーフ積載容積
                                              ln_palette_max_qty);           -- パレット最大枚数
--
          -- リターン・コードにエラーが返された場合はエラー
          IF (ln_retcode = gn_status_error) THEN
            lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
                                                  gv_cnst_msg_155,
                                                  'API_NAME',
                                                  cv_get_max_pallet_qty_api,
                                                  'ERR_MSG',
                                                  cv_get_max_pallet_qty_msg,
                                                  'REQUEST_NO',
                                                  loop_cnt.request_no);
            RAISE global_api_expt;
--
          -- D-2パレット合計枚数 > D-6パレット最大枚数の場合はエラー
          ELSIF (loop_cnt.pallet_sum_quantity > ln_palette_max_qty) THEN
            lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
                                              gv_cnst_msg_151,
                                              'REQUEST_NO',
                                              loop_cnt.request_no);
            RAISE global_api_expt;
--
          END IF;
        END IF;  -- 2008/07/09 ST不具合対応#430
--      END IF; -- 2008/07/30 ST不具合対応#501
--
        -- **************************************************
        -- *** マスタチェック(D-7)
        -- **************************************************
--
-- Ver1.15 M.Hokkanji START
-- 荒茶出荷の場合は物流構成存在チェックは行わない TE080400指摘75
-- 物流構成存在チェックは依頼品目で行う、それに伴い依頼品目が設定されている場合のみチェックを行う
-- 
        IF ( (loop_cnt.order_type_id <> lt_transaction_type_id) AND
             (loop_cnt.request_item_code IS NOT NULL)) THEN
--          ln_retcode := master_check(loop_cnt.shipping_item_code,    -- D-2品目コード
          ln_retcode := master_check(loop_cnt.request_item_code,     -- D-2依頼品目コード
-- Ver1.15 M.Hokkanji END
                                     loop_cnt.deliver_to,            -- D-2配送先コード
                                     loop_cnt.head_sales_branch,     -- D-2拠点コード
                                     loop_cnt.deliver_from,          -- D-2出荷元保管場所
                                     loop_cnt.schedule_ship_date,    -- D-2出庫日
                                     lv_retcode,                     -- リターンコード
                                     lv_errbuf,                      -- エラーメッセージコード
                                     lv_errmsg);                     -- エラーメッセージ
--
          -- リターン・コードにエラーが返された場合はエラー
          IF (ln_retcode = gn_status_error) THEN
-- Ver1.22 M.Hokkanji Start
            lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
                                                  gv_cnst_msg_152,
                                                  'REQUEST_NO',
                                                  loop_cnt.request_no,
                                                  gv_cnst_tkn_item_code,
                                                  loop_cnt.request_item_code,
                                                  gv_cnst_tkn_deliver_to,
                                                  loop_cnt.deliver_to,
                                                  gv_cnst_tkn_head_saled,
                                                  loop_cnt.head_sales_branch,
                                                  gv_cnst_tkn_deliver_from,
                                                  loop_cnt.deliver_from,
                                                  gv_cnst_tkn_ship_date,
                                                  TO_CHAR(loop_cnt.schedule_ship_date,'YYYY/MM/DD')
                                                  );
--            lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
--                                                  gv_cnst_msg_152,
--                                                  'REQUEST_NO',
--                                                  loop_cnt.request_no);
-- Ver1.22 M.Hokkanji End
            RAISE global_api_expt;
          END IF;
-- Ver1.15 M.Hokkanji START
        END IF;
--
        -- D-2出荷区分が「否」の場合
        IF (loop_cnt.ship_class = cv_ship_disable) THEN
--        ELSIF (loop_cnt.ship_class = cv_ship_disable) THEN
-- Ver1.15 M.Hokkanji END
          lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
                                                gv_cnst_msg_166,
                                                'ITEM_ERRMSG',
                                                cv_master_check_msg,
                                                'REQUEST_NO',
                                                loop_cnt.request_no,
                                                'ITEM_CODE',
-- Ver1.24 M.Hokkanji Start
                                                loop_cnt.request_item_code);
--                                                loop_cnt.shipping_item_code);
-- Ver1.24 M.Hokkanji End
          RAISE global_api_expt;
--
        -- D-2売上対象区分が「1」以外の場合
-- Ver1.15 M.Hokkanji START
-- TE080_400指摘74対応(品目が親の場合のみチェックを行う)
--        ELSIF (loop_cnt.sales_div <> cv_sales_div) THEN
-- Ver1.19 M.Hokkanji Start
--        ELSIF ((loop_cnt.sales_div <> cv_sales_div) AND
--               (loop_cnt.item_id = loop_cnt.parent_item_id)) THEN
-- Ver1.19 M.Hokkanji END
-- Ver1.15 M.Hokkanji END]
-- Ver1.19 M.Hokkanji Start
-- 資材出荷は売上対象区分のチェックを行わないように修正
        ELSIF (loop_cnt.order_type_id <> lt_transaction_type_id_mat) AND
              ((loop_cnt.sales_div <> cv_sales_div) AND
-- Ver1.24 M.Hokkanji Start
               (loop_cnt.opm_request_item_id = loop_cnt.parent_item_id)) THEN
--               (loop_cnt.item_id = loop_cnt.parent_item_id)) THEN
-- Ver1.24 M.Hokkanji End
-- Ver1.19 M.Hokkanji End
          lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
                                                gv_cnst_msg_166,
                                                'ITEM_ERRMSG',
                                                cv_master_check_msg2,
                                                'REQUEST_NO',
                                                loop_cnt.request_no,
                                                'ITEM_CODE',
-- Ver1.24 M.Hokkanji Start
                                                loop_cnt.request_item_code);
--                                                loop_cnt.shipping_item_code);
-- Ver1.24 M.Hokkanji End
          RAISE global_api_expt;
--
        -- D-2廃止区分が「1」の場合
        ELSIF (loop_cnt.obsolete_class = cv_obsolete_class) THEN
          lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
                                                gv_cnst_msg_166,
                                                'ITEM_ERRMSG',
                                                cv_master_check_msg3,
                                                'REQUEST_NO',
                                                loop_cnt.request_no,
                                                'ITEM_CODE',
-- Ver1.24 M.Hokkanji Start
                                                loop_cnt.request_item_code);
--                                                loop_cnt.shipping_item_code);
-- Ver1.24 M.Hokkanji End
          RAISE global_api_expt;
--
        -- D-2率区分が「0」の場合
        ELSIF (loop_cnt.rate_class <> cv_rate_class) THEN
          lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
                                                gv_cnst_msg_166,
                                                'ITEM_ERRMSG',
                                                cv_master_check_msg4,
                                                'REQUEST_NO',
                                                loop_cnt.request_no,
                                                'ITEM_CODE',
-- Ver1.24 M.Hokkanji Start
                                                loop_cnt.request_item_code);
--                                                loop_cnt.shipping_item_code);
-- Ver1.24 M.Hokkanji End
          RAISE global_api_expt;
--
-- 2008/08/06 D.Nihei DEL START
--        -- D-2で取得した数量がD-2で取得した配数の整数倍でない場合
--        ELSIF (mod(loop_cnt.quantity, loop_cnt.delivery_qty) <> 0) THEN
--          -- 数量を配数で割った余りが0でない場合
--          lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
--                                                gv_cnst_msg_167,
--                                                'REQUEST_NO',
--                                                loop_cnt.request_no,
--                                                'ITEM_CODE',
--                                                loop_cnt.shipping_item_code);
--          -- 警告をセット
--          lv_warn_message := lv_warn_message || lv_errmsg || gv_line_feed;
--          ln_warn_flg := 1;
--          IF (gv_callfrom_flg = '1') THEN
--            FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg );
--          END IF;
-- 2008/08/06 D.Nihei DEL END
--
        -- D-2で取得した数量がD-2で取得した出荷入数の整数倍でない場合
        ELSIF ((loop_cnt.num_of_deliver IS NOT NULL)
        AND    (mod(loop_cnt.quantity, loop_cnt.num_of_deliver) <> 0)) THEN
          -- 数量を出荷入数で割った余りが0でない場合
          lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
                                                gv_cnst_msg_168,
                                                'ATTR_TYPE',
                                                cv_master_check_attr,
                                                'REQUEST_NO',
                                                loop_cnt.request_no,
                                                'ITEM_CODE',
                                                loop_cnt.shipping_item_code);
          RAISE global_api_expt;
--
        -- D-2で取得した数量がD-2で取得した入数の整数倍でない場合
        ELSIF ((loop_cnt.num_of_cases IS NOT NULL)
        AND    (loop_cnt.conv_unit IS NOT NULL) --入出庫換算単位
        AND    (mod(loop_cnt.quantity,loop_cnt.num_of_cases) <> 0)) THEN
        -- 数量を入数で割った余りが0でない場合
          lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
                                            gv_cnst_msg_168,
                                            'ATTR_TYPE',
                                            cv_master_check_attr2,
                                            'REQUEST_NO',
                                            loop_cnt.request_no,
                                            'ITEM_CODE',
                                            loop_cnt.shipping_item_code);
          RAISE global_api_expt;
--
        END IF;
--
-- 2008/08/06 D.Nihei ADD START
        ln_case_total := 0; -- ケース総合計
        -- 商品区分が「ドリンク」且つ品目区分が「製品」の場合
        IF ( ( loop_cnt.prod_class      = gv_drink )
         AND ( loop_cnt.item_class_code = gv_prod  ) ) THEN
--
          -- 「ケース総合計」を取得
          IF ( loop_cnt.num_of_deliver IS NOT NULL ) THEN
            ln_case_total := loop_cnt.quantity / loop_cnt.num_of_deliver;
--
          ELSIF ( loop_cnt.num_of_cases IS NOT NULL ) THEN
            ln_case_total := loop_cnt.quantity / loop_cnt.num_of_cases;
--
          ELSE
            ln_case_total := loop_cnt.quantity;
--
          END IF;
--
          -- 「ケース総合計」がD-2で取得した配数の整数倍でない場合
          IF (mod(ln_case_total, loop_cnt.delivery_qty) <> 0) THEN
            -- 数量を配数で割った余りが0でない場合
            lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
                                                  gv_cnst_msg_167,
                                                  'REQUEST_NO',
                                                  loop_cnt.request_no,
                                                  'ITEM_CODE',
                                                  loop_cnt.shipping_item_code);
            -- 警告をセット
            ln_warn_flg := 1;
            IF (gv_callfrom_flg = '1') THEN
              FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg );
            -- Ver1.18 MARUSHITA START
            ELSE
              lv_warn_message := lv_warn_message || lv_errmsg || gv_line_feed;
            -- Ver1.18 MARUSHITA END
            END IF;
--
          END IF;
--
        END IF;
-- 2008/08/06 D.Nihei ADD END
      -- ステータスチェック有りの場合は出荷可否チェック処理を実施
--      IF ( iv_status_kbn = '1' ) THEN -- 2008/07/30 ST不具合対応#501
                                        -- マスタチェックの実施条件にステータスチェック区分を追加
        -- **************************************************
        -- *** 計画商品フラグ取得処理(D-8)
        -- **************************************************
--
-- Ver1.15 M.Hokkanji START
-- TE080_400指摘78対応
--        ln_d8retcode := get_plan_item_flag(loop_cnt.shipping_item_code,   -- D-2品目コード
        ln_d8retcode := get_plan_item_flag(loop_cnt.request_item_code,   -- 依頼品目コード
-- Ver1.15 M.Hokkanji END
                                           loop_cnt.head_sales_branch,    -- D-2拠点コード
                                           loop_cnt.deliver_from,         -- D-2出荷元保管場所
                                           loop_cnt.schedule_ship_date,   -- D-2出庫日
                                           lv_retcode,                    -- リターンコード
                                           lv_errbuf,                     -- エラーメッセージコード
                                           lv_errmsg);                    -- エラーメッセージ
--
--
        -- **************************************************
        -- *** 出荷可否チェック(D-9)
        -- **************************************************
--
-- Ver1.15 M.Hokkanji START
-- TE080_400指摘78対応に伴い依頼品目、拠点依頼数量が設定されている場合のみチェックを行う
-- （支持無し実績入力でも当関数を呼ぶため）
        IF ((loop_cnt.request_item_id IS NOT NULL) AND
            (loop_cnt.based_request_quantity IS NOT NULL)) THEN
        -- チェック１
-- Ver1.15 M.Hokkanji END
          xxwsh_common910_pkg.check_shipping_judgment('2',                            -- チェック方法'2'商品部チェック
                                                      loop_cnt.head_sales_branch,     -- D-2拠点コード
-- Ver1.15 M.Hokkanji START
-- TE080_400指摘78対応
                                                      loop_cnt.request_item_id,       -- D-2依頼品目ID
                                                      loop_cnt.based_request_quantity, -- D-2拠点依頼数量
--                                                    loop_cnt.shipping_inventory_item_id,-- D-2品目ID
--                                                    loop_cnt.quantity,              -- D-2数量
-- Ver1.15 M.Hokkanji END
                                                      loop_cnt.schedule_arrival_date, -- D-2着日
                                                      loop_cnt.deliver_from_id,       -- D-2出庫元ID
                                                      loop_cnt.request_no,            -- 依頼No   6/19追加
                                                      lv_retcode,                     -- リターンコード
                                                      lv_errbuf,                 -- エラーメッセージコード
                                                      lv_errmsg,                      -- エラーメッセージ
                                                      ln_retcode);                    -- 処理結果
--
          IF (( lv_retcode = '0' )
          AND ( iv_status_kbn = '1' )              -- 締めステータスチェック区分有り(拠点担当）
--20090831 D.Sugahara V1.29 Mod Start 拠点担当の場合は売上拠点かどうかにかかわらずエラーとする
--          AND ( loop_cnt.location_rel_code = '1' ) -- D-2拠点実績有無区分のON（売上拠点=1）
--20090831 D.Sugahara V1.29 Mod End
          AND ( ln_retcode = 1)) THEN
--
            lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
                                                       gv_cnst_msg_169,
                                                       'CHK_TYPE',
                                                       cv_c_s_j_chk,
                                                       'ITEM_CODE',
-- Ver1.15 M.Hokkanji START
-- TE080_400指摘78対応
                                                       loop_cnt.request_item_code,
--                                                       loop_cnt.shipping_item_code,
-- Ver1.15 M.Hokkanji END

                                                       'REQUEST_NO',
                                                       loop_cnt.request_no);
            RAISE global_api_expt;
--
--20090831 D.Sugahara V1.29 Mod Start
--拠点担当の場合は売上拠点かどうかにかかわらずエラーとする
/*
          ELSIF (( lv_retcode = '0' )
          AND    ( iv_status_kbn = '1' )              -- 締めステータスチェック区分有り(拠点担当）
--20090831 D.Sugahara V1.29 Mod Start
--          AND    ( loop_cnt.location_rel_code = '2' ) -- D-2拠点実績有無区分のON（売上なし拠点=2）
          AND    ( loop_cnt.location_rel_code = '0' ) -- D-2拠点実績有無区分のON（売上なし拠点=0）
--20090831 D.Sugahara V1.29 Mod End
          AND    ( ln_retcode = 1)) THEN
--
            lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
                                                       gv_cnst_msg_173,
                                                       'CHK_TYPE',
                                                       cv_c_s_j_chk,
                                                       'ITEM_CODE',
-- Ver1.15 M.Hokkanji START
-- TE080_400指摘78対応
                                                       loop_cnt.request_item_code,
--                                                       loop_cnt.shipping_item_code,
-- Ver1.15 M.Hokkanji END
                                                       'REQUEST_NO',
                                                       loop_cnt.request_no);
            -- 警告をセット
            ln_warn_flg := 1;
            IF (gv_callfrom_flg = '1') THEN
              FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg );
            -- Ver1.18 MARUSHITA START
            ELSE
              lv_warn_message := lv_warn_message || lv_errmsg || gv_line_feed;
            -- Ver1.18 MARUSHITA END
            END IF;
*/
--20090831 D.Sugahara V1.29 Mod End
--
          ELSIF (( lv_retcode = '0' )
          AND    ( iv_status_kbn = '2' ) -- 締めステータスチェック区分無し(物流担当）
--20090831 D.Sugahara V1.29 Mod Start
--物流担当の場合は売上拠点かどうかを見ない
          --AND    ( loop_cnt.location_rel_code = '2' ) -- D-2拠点実績有無区分のON（売上なし拠点=2）
--20090831 D.Sugahara V1.29 Mod End
          AND    ( ln_retcode = 1 )) THEN
            lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
                                                       gv_cnst_msg_173,
                                                       'CHK_TYPE',
                                                       cv_c_s_j_chk,
                                                       'ITEM_CODE',
-- Ver1.15 M.Hokkanji START
-- TE080_400指摘78対応
                                                       loop_cnt.request_item_code,
--                                                       loop_cnt.shipping_item_code,
-- Ver1.15 M.Hokkanji END
                                                       'REQUEST_NO',
                                                       loop_cnt.request_no);
            -- 警告をセット
            ln_warn_flg := 1;
            IF (gv_callfrom_flg = '1') THEN
              FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg );
            -- Ver1.18 MARUSHITA START
            ELSE
              lv_warn_message := lv_warn_message || lv_errmsg || gv_line_feed;
            -- Ver1.18 MARUSHITA END
            END IF;
--
          -- リターン・コードにエラーが返された場合はエラー
          ELSIF ( lv_retcode = gn_status_error ) THEN
              lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
                                                    gv_cnst_msg_155,
                                                    'API_NAME',
                                                    cv_c_s_j_api,
                                                    'ERR_MSG',
                                                    lv_errmsg, --cv_c_s_j_msg,
                                                    'REQUEST_NO',
                                                    loop_cnt.request_no);
              RAISE global_api_expt;
          END IF;
--
          -- チェック２
          xxwsh_common910_pkg.check_shipping_judgment('3',                           -- チェック方法
                                                      loop_cnt.head_sales_branch,    -- 拠点コード
-- Ver1.15 M.Hokkanji START
-- TE080_400指摘78対応
                                                      loop_cnt.request_item_id,       -- D-2依頼品目ID
                                                      loop_cnt.based_request_quantity, -- D-2拠点依頼数量
--                                                    loop_cnt.shipping_inventory_item_id,-- D-2品目ID
--                                                    loop_cnt.quantity,              -- D-2数量
-- Ver1.15 M.Hokkanji END
                                                      loop_cnt.schedule_ship_date,   -- D-2出庫日
                                                      loop_cnt.deliver_from_id,      -- D-2出庫元ID
                                                      loop_cnt.request_no,            -- 依頼No   6/19追加
                                                      lv_retcode,                    -- リターンコード
                                                      lv_errbuf,              -- エラーメッセージコード
                                                      lv_errmsg,                     -- エラーメッセージ
                                                      ln_retcode);                   -- 処理結果
--
          -- リターン・コードにエラーが返された場合はエラー
          IF (( lv_retcode = '0' )
          AND ( iv_status_kbn = '1' ) -- 締めステータスチェック区分 有り
          AND ( ln_retcode = 1 )) THEN
            lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
                                                  gv_cnst_msg_169,
                                                  'CHK_TYPE',
                                                  cv_c_s_j_chk2,
                                                  'ITEM_CODE',
-- Ver1.15 M.Hokkanji START
-- TE080_400指摘78対応
                                                  loop_cnt.request_item_code,
--                                                loop_cnt.shipping_item_code,
-- Ver1.15 M.Hokkanji END
                                                  'REQUEST_NO',
                                                  loop_cnt.request_no);
              RAISE global_api_expt;
--
          ELSIF (( lv_retcode = '0' )
          AND ( iv_status_kbn = '2' ) -- 締めステータスチェック区分 無し
          AND ( ln_retcode = 1 )) THEN
            lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
                                                  gv_cnst_msg_173,
                                                  'CHK_TYPE',
                                                  cv_c_s_j_chk2,
                                                  'ITEM_CODE',
-- Ver1.15 M.Hokkanji START
-- TE080_400指摘78対応
                                                  loop_cnt.request_item_code,
--                                                loop_cnt.shipping_item_code,
-- Ver1.15 M.Hokkanji END
                                                  'REQUEST_NO',
                                                  loop_cnt.request_no);
            -- 警告をセット

            ln_warn_flg := 1;
            IF (gv_callfrom_flg = '1') THEN
              FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg );
            -- Ver1.18 MARUSHITA START
            ELSE
              lv_warn_message := lv_warn_message || lv_errmsg || gv_line_feed;
            -- Ver1.18 MARUSHITA END
            END IF;
--
          ELSIF (( lv_retcode = '0' )
          AND ( iv_status_kbn = '1' ) -- 締めステータスチェック区分 有り
          AND ( ln_retcode = 2 )) THEN
            lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
                                                  gv_cnst_msg_170,
                                                  'CHK_TYPE',
                                                  cv_c_s_j_chk2,
                                                  'ITEM_CODE',
-- Ver1.15 M.Hokkanji START
-- TE080_400指摘78対応
                                                  loop_cnt.request_item_code,
--                                                loop_cnt.shipping_item_code,
-- Ver1.15 M.Hokkanji END
                                                  'REQUEST_NO',
                                                  loop_cnt.request_no);
            RAISE global_api_expt;
--
          ELSIF (( lv_retcode = '0' )
          AND    ( iv_status_kbn = '2' ) -- 締めステータスチェック区分 無し
          AND    ( ln_retcode = 2 )) THEN
            lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
                                                  gv_cnst_msg_174,
                                                  'CHK_TYPE',
                                                  cv_c_s_j_chk2,
                                                  'ITEM_CODE',
-- Ver1.15 M.Hokkanji START
-- TE080_400指摘78対応
                                                  loop_cnt.request_item_code,
--                                                loop_cnt.shipping_item_code,
-- Ver1.15 M.Hokkanji END
                                                  'REQUEST_NO',
                                                  loop_cnt.request_no);
            -- 警告をセット
            ln_warn_flg := 1;
            IF (gv_callfrom_flg = '1') THEN
              FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg );
            -- Ver1.18 MARUSHITA START
            ELSE
              lv_warn_message := lv_warn_message || lv_errmsg || gv_line_feed;
            -- Ver1.18 MARUSHITA END
            END IF;
--
          -- リターン・コードにエラーが返された場合はエラー
          ELSIF ( lv_retcode = gn_status_error ) THEN-- 
            lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
                                                  gv_cnst_msg_155,
                                                  'API_NAME',
                                                  cv_c_s_j_api,
                                                  'ERR_MSG',
                                                  lv_errmsg, --cv_c_s_j_msg,
                                                  'REQUEST_NO',
                                                  loop_cnt.request_no);
            RAISE global_api_expt;
--
          END IF;
--
          IF ( iv_prod_class = cv_prod_class_leaf ) THEN -- リーフのみ
--
-- ##### 20081202 Ver.1.21 本番#318対応 START #####
            BEGIN
-- ##### 20081202 Ver.1.21 本番#318対応 END   #####
--
              -- 2008/07/08 ST不具合対応#405 START
              -- 出庫形態(引取変更)取得
              SELECT transaction_type_id
                INTO gv_transaction_type_id_ship
                FROM XXWSH_OE_TRANSACTION_TYPES2_V
                WHERE transaction_type_name = gv_transaction_type_name_ship;
--
-- ##### 20081202 Ver.1.21 本番#318対応 START #####
            EXCEPTION
              -- 取得できなかった場合は返り値に1：処理エラーを返し終了
              WHEN OTHERS THEN
                lv_errmsg :=xxcmn_common_pkg.get_msg(gv_cnst_msg_cmn,
                                                  gv_cnst_cmn_012,
                                                  gv_cnst_tkn_table,
                                                  cv_table_name_tran,
                                                  gv_cnst_tkn_key,
                                                  cv_tran_type_name || ':' || gv_transaction_type_name_ship);
                RAISE global_api_expt;
            END;
-- ##### 20081202 Ver.1.21 本番#318対応 END   #####
--
            IF gv_transaction_type_id_ship IS NULL THEN  -- 取得できない場合はエラー
              lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
                                                    gv_cnst_msg_155,
                                                    'API_NAME',
                                                    cv_c_s_j_api,
                                                    'ERR_MSG',
                                                    cv_c_s_j_msg3,
                                                    'REQUEST_NO',
                                                    loop_cnt.request_no);
              RAISE global_api_expt;
            END IF;
            -- 2008/07/08 ST不具合対応#405 END
--
            -- リーフで出庫形態が引取変更以外ならチェックは行わない 2008/07/08 ST不具合対応#405
            IF ( loop_cnt.order_type_id = gv_transaction_type_id_ship ) THEN
--
              -- チェック３
              xxwsh_common910_pkg.check_shipping_judgment('1',                           -- チェック方法
                                                          loop_cnt.head_sales_branch,    -- 拠点コード
-- Ver1.15 M.Hokkanji START
-- TE080_400指摘78対応
                                                          loop_cnt.request_item_id,       -- D-2依頼品目ID
                                                          loop_cnt.based_request_quantity, -- D-2拠点依頼数量
--                                                          loop_cnt.shipping_inventory_item_id,-- D-2品目ID
--                                                          loop_cnt.quantity,              -- D-2数量
-- Ver1.15 M.Hokkanji END
                                                          loop_cnt.schedule_arrival_date, -- D-2着日
                                                          loop_cnt.deliver_from_id,     -- D-2出庫元ID
                                                          loop_cnt.request_no,           -- 依頼No   6/19追加
                                                          lv_retcode,                   -- リターンコード
                                                          lv_errbuf,            -- エラーメッセージコード
                                                          lv_errmsg,                    -- エラーメッセージ
                                                          ln_retcode);                  -- 処理結果
              -- リターン・コードにエラーが返された場合はエラー
              IF (( lv_retcode = '0' )
              AND ( iv_callfrom_flg = '1' ) -- パラメータ・呼出元フラグ
              AND ( ln_retcode = 1 )) THEN
                lv_errmsg :=
                xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
                                         gv_cnst_msg_156,
                                         'API_NAME',
                                         cv_c_s_j_api,
                                         'CHK_TYPE',
                                         cv_c_s_j_chk3,
                                         'ERR_MSG',
                                         cv_c_s_j_msg2,
                                         'REQUEST_NO',
                                         loop_cnt.request_no,
                                         'ITEM_CODE',
-- Ver1.15 M.Hokkanji START
-- TE080_400指摘78対応
                                         loop_cnt.request_item_code);
--                                       loop_cnt.shipping_item_code,
-- Ver1.15 M.Hokkanji END
                -- 警告をセット
                ln_warn_flg := 1;
                lv_retcode := gv_status_warn;
                IF (gv_callfrom_flg = '1') THEN
                  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg );
                -- Ver1.18 MARUSHITA START
                ELSE
                  lv_warn_message := lv_warn_message || lv_errmsg || gv_line_feed;
                -- Ver1.18 MARUSHITA END
                END IF;
--
              ELSIF (( lv_retcode = '0' )
              AND    ( iv_callfrom_flg = '2' ) -- パラメータ・呼出元フラグ
              AND    ( ln_retcode = 1 )) THEN
                lv_errmsg :=
                xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
                                         gv_cnst_msg_157,
                                         'ITEM_CODE',
-- Ver1.15 M.Hokkanji START
-- TE080_400指摘78対応
                                         loop_cnt.request_item_code,
--                                       loop_cnt.shipping_item_code,
-- Ver1.15 M.Hokkanji END
                                         'CHK_TYPE',
                                         cv_c_s_j_chk4);
                -- 警告をセット
                ln_warn_cnt := 1;
                lv_retcode := gv_status_warn;
                IF (gv_callfrom_flg = '1') THEN
                  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg );
                -- Ver1.18 MARUSHITA START
                ELSE
                  lv_warn_message := lv_warn_message || lv_errmsg || gv_line_feed;
                -- Ver1.18 MARUSHITA END
                END IF;
--
              -- リターン・コードにエラーが返された場合はエラー
              ELSIF ( lv_retcode = gn_status_error ) THEN-- 
                lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
                                                      gv_cnst_msg_155,
                                                      'API_NAME',
                                                      cv_c_s_j_api,
                                                      'ERR_MSG',
                                                      lv_errmsg, --cv_c_s_j_msg,
                                                      'REQUEST_NO',
                                                      loop_cnt.request_no);
                RAISE global_api_expt;
              END IF;
--
            END IF;
--
          END IF;
-- Ver1.20 本番指摘133暫定対応
-- Ver1.26 Y.Kazama 本番障害#1243 本番指摘133のコメント化解除
--
          IF ( ln_d8retcode = 0 ) THEN
            -- D-8で計画商品フラグが取得できなかった場合は、本チェックは行いません。
--
            -- チェック４
            xxwsh_common910_pkg.check_shipping_judgment('4',                           -- チェック方法
                                                        loop_cnt.head_sales_branch,    -- 拠点コード
-- Ver1.15 M.Hokkanji START
-- TE080_400指摘78対応
                                                        loop_cnt.request_item_id,       -- D-2依頼品目ID
                                                        loop_cnt.based_request_quantity, -- D-2拠点依頼数量
--                                                      loop_cnt.shipping_inventory_item_id,-- D-2品目ID
--                                                      loop_cnt.quantity,              -- D-2数量
-- Ver1.15 M.Hokkanji END
                                                        loop_cnt.schedule_ship_date,   -- D-2出庫日
                                                        loop_cnt.deliver_from_id,      -- D-2出庫元ID
                                                        loop_cnt.request_no,           -- 依頼No   6/19追加
                                                        lv_retcode,                  -- リターンコード
                                                        lv_errbuf,           -- エラーメッセージコード
                                                        lv_errmsg,                -- エラーメッセージ
                                                        ln_retcode);              -- 処理結果
--
            -- リターン・コードにエラーが返された場合はエラー
            IF (( lv_retcode = '0' )
            AND ( ln_retcode = 1) 
            AND (  iv_callfrom_flg = '1' )) THEN-- パラメータ・呼出元フラグ
              lv_errmsg :=
              xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
                                       gv_cnst_msg_156,
                                       'API_NAME',
                                       cv_c_s_j_api,
                                       'CHK_TYPE',
                                       cv_c_s_j_chk5,
                                       'ERR_MSG',
                                       cv_c_s_j_msg2,
                                       'REQUEST_NO',
                                       loop_cnt.request_no,
                                       'ITEM_CODE',
-- Ver1.15 M.Hokkanji START
-- TE080_400指摘78対応
                                       loop_cnt.request_item_code);
--                                       loop_cnt.shipping_item_code,
-- Ver1.15 M.Hokkanji END
              -- 警告をセット
              ln_warn_flg := 1;
              IF (gv_callfrom_flg = '1') THEN
                FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg );
              -- Ver1.18 MARUSHITA START
              ELSE
                lv_warn_message := lv_warn_message || lv_errmsg || gv_line_feed;
              -- Ver1.18 MARUSHITA END
              END IF;
--
            ELSIF (( lv_retcode = '0' )
            AND    ( ln_retcode = 1) 
            AND    ( iv_callfrom_flg = '2' )) THEN-- パラメータ・呼出元フラグ
              lv_errmsg :=
              xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
                                       gv_cnst_msg_157,
                                       'CHK_TYPE',
                                       cv_c_s_j_chk5,
                                       'ITEM_CODE',
-- Ver1.15 M.Hokkanji START
-- TE080_400指摘78対応
                                       loop_cnt.request_item_code);
--                                       loop_cnt.shipping_item_code,
-- Ver1.15 M.Hokkanji END
              -- 警告をセット
              ln_warn_flg := 1;
              IF (gv_callfrom_flg = '1') THEN
                FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg );
              -- Ver1.18 MARUSHITA START
              ELSE
                lv_warn_message := lv_warn_message || lv_errmsg || gv_line_feed;
              -- Ver1.18 MARUSHITA END
              END IF;
--
            -- リターン・コードにエラーが返された場合はエラー
            ELSIF ( lv_retcode = gn_status_error ) THEN
              lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
                                                    gv_cnst_msg_155,
                                                    'API_NAME',
                                                    cv_c_s_j_api,
                                                    'ERR_MSG',
                                                    lv_errmsg, --cv_c_s_j_msg,
                                                    'REQUEST_NO',
                                                    loop_cnt.request_no);
              RAISE global_api_expt;
--
            END IF;
--
          END IF;
--Ver1.30 M.Hokkanji End 本番障害133暫定対応
-- Ver1.15 M.Hokkanji START
        END IF;
-- Ver1.15 M.Hokkanji END
--
--
        -- **************************************************
        -- *** 積載効率チェック(積載効率算出)(D-10)
        -- **************************************************
--
        IF ((lv_bfr_request_no <> loop_cnt.request_no)
        AND ( lv_bfr_freight_charge_class = gv_freight_charge_class_on ) -- 運賃区分がONの場合にチェックする(2008/07/09 ST不具合対応#430)
        AND ( ln_data_cnt > 1 )) THEN
--
-- Ver 1.17 M.Hokkanji START
        -- 運送業者がNULLの場合
        IF (lv_bfr_freight_carrier_code IS NULL ) THEN
          lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
                                                gv_cnst_msg_176,
                                                gv_cnst_tkn_request_no,
                                                lv_bfr_request_no);
          RAISE global_api_expt;
        END IF;
-- Ver 1.17 M.Hokkanji END
-- Ver1.15 M.Hokkanji START
          -- 重量容積区分の値によりいずれかのみチェックを行うように修正（両方見るのはヘッダに値セット時のみ）
          IF (lt_weight_capacity_class = cv_weight_capacity_class_1) THEN
-- Ver1.15 M.Hokkanji END
            -- 前依頼No <> D-2依頼No の場合
            xxwsh_common910_pkg.calc_load_efficiency(ln_bfr_sum_weight,        -- 前積載重量合計
                                                     NULL,                     -- 前積載容積合計
                                                     cv_whse_code,
                                                              -- クイックコード「コード区分」「倉庫」
                                                     lv_bfr_deliver_from,      -- 前出荷元保管場所
                                                     cv_deliver_to,
                                                              -- クイックコード「コード区分」「配送先」
                                                     lv_bfr_deliver_to,        -- 前配送先コード
                                                     lv_bfr_shipping_method_code,
                                                                               -- 前配送区分
                                                     lv_bfr_prod_class,        -- 前商品区分
                                                     '0',                      -- 対象外 
                                                     id_bfr_schedule_ship_date,-- 前出庫日
                                                     lv_retcode,               -- リターンコード
                                                     lv_errbuf,              -- エラーメッセージコード
                                                     lv_errmsg,                -- エラーメッセージ
                                                     lv_loading_over_class,    -- 積載オーバー区分
                                                     lv_ship_methods,          -- 出荷方法
                                                     ln_load_efficiency_weight,
                                                                               -- 重量積載効率
                                                     ln_load_efficiency_capacity,
                                                                               -- 容積積載効率
                                                     lv_mixed_ship_method);    -- 混載配送区分
  --
            -- リターン・コードにエラーが返された場合はエラー
            IF ( lv_retcode = gn_status_error ) THEN
              lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
                                                    gv_cnst_msg_155,
                                                    'API_NAME',
                                                    cv_calc_load_efficiency_api,
                                                    'ERR_MSG',
                                                    lv_errmsg,
                                                    'REQUEST_NO',
                                                    lv_bfr_request_no,'POS',27);
              RAISE global_api_expt;
  --
            ELSIF ( lv_loading_over_class = 1 ) THEN-- 積載オーバーの場合
              lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
                                                    gv_cnst_msg_158,
                                                    'API_NAME',
                                                    cv_calc_load_efficiency_api,                                                                    
                                                    'ERR_MSG',
                                                    lv_errmsg,
                                                    'REQUEST_NO',
                                                    lv_bfr_request_no,'POS',28);
              RAISE global_api_expt;
  --
            END IF;
-- Ver1.15 M.Hokkanji START
          ELSE
-- Ver1.15 M.Hokkanji EMD
--
            -- 前依頼No <> D-2依頼No の場合(容積チェック)
            xxwsh_common910_pkg.calc_load_efficiency(NULL,                     -- 前積載重量合計
                                                     ln_bfr_sum_capacity,      -- 前積載容積合計
                                                     cv_whse_code,
                                                              -- クイックコード「コード区分」「倉庫」
                                                     lv_bfr_deliver_from,      -- 前出荷元保管場所
                                                     cv_deliver_to,
                                                              -- クイックコード「コード区分」「配送先」
                                                     lv_bfr_deliver_to,        -- 前配送先コード
                                                     lv_bfr_shipping_method_code,
                                                                               -- 前配送区分
                                                     lv_bfr_prod_class,        -- 前商品区分
                                                     '0',                      -- 対象外 
                                                     id_bfr_schedule_ship_date,-- 前出庫日
                                                     lv_retcode,               -- リターンコード
                                                     lv_errbuf,              -- エラーメッセージコード
                                                     lv_errmsg,                -- エラーメッセージ
                                                     lv_loading_over_class,    -- 積載オーバー区分
                                                     lv_ship_methods,          -- 出荷方法
                                                     ln_load_efficiency_weight,
                                                                               -- 重量積載効率
                                                     ln_load_efficiency_capacity,
                                                                               -- 容積積載効率
                                                     lv_mixed_ship_method);    -- 混載配送区分
  --
            -- リターン・コードにエラーが返された場合はエラー
            IF ( lv_retcode = gn_status_error ) THEN
              lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
                                                    gv_cnst_msg_155,
                                                    'API_NAME',
                                                    cv_calc_load_efficiency_api,
                                                    'ERR_MSG',
                                                    lv_errmsg,
                                                    'REQUEST_NO',
                                                    lv_bfr_request_no);
              RAISE global_api_expt;
  --
            ELSIF ( lv_loading_over_class = 1 ) THEN-- 積載オーバーの場合
              lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
                                                    gv_cnst_msg_158,
                                                    'API_NAME',
                                                    cv_calc_load_efficiency_api,                                                                    
                                                    'ERR_MSG',
                                                    lv_errmsg,
                                                    'REQUEST_NO',
                                                    lv_bfr_request_no);
              RAISE global_api_expt;
  --
            END IF;
-- Ver1.15 M.Hokkanji START
          END IF;
-- Ver1.15 M.Hokkanji EMD
--
        END IF;
--
      END IF;
--
      -- 前データをセット
      lv_bfr_request_no            := loop_cnt.request_no;           -- 前依頼No
-- Ver1.15 M.Hokkanji START
      -- 小口の場合
      IF ( loop_cnt.small_amount_class = cv_small_amount_class_1) THEN
        ln_bfr_sum_weight          := NVL(loop_cnt.sum_weight,0);  -- 前積載重量合計
      ELSE
        ln_bfr_sum_weight          := NVL(loop_cnt.sum_weight,0) +
                                      NVL(loop_cnt.sum_pallet_weight,0); -- 前積載重量合計
      END IF;
      ln_bfr_sum_capacity          := NVL(loop_cnt.sum_capacity,0);  -- 前積載容積合計
      lt_weight_capacity_class     := loop_cnt.weight_capacity_class; -- 重量容積区分
-- Ver1.15 M.Hokkanji END
      lv_bfr_deliver_from          := loop_cnt.deliver_from;         -- 前出荷元保管場所
      lv_bfr_deliver_to            := loop_cnt.deliver_to;           -- 前配送先コード
      lv_bfr_shipping_method_code  := loop_cnt.shipping_method_code; -- 前配送区分
      lv_bfr_prod_class            := loop_cnt.prod_class;           -- 前商品区分
      id_bfr_schedule_ship_date    := loop_cnt.schedule_ship_date;   -- 前出庫日
      lv_bfr_freight_charge_class  := loop_cnt.freight_charge_class; -- 前運賃区分 2008/07/09 ST不具合対応#430
-- Ver1.17 M.Hokkanji Start
      lv_bfr_freight_carrier_code  := loop_cnt.freight_carrier_code; -- 運送業者
-- Ver1.17 M.Hokkanji End
--
--
      -- **************************************************
      -- *** PL/SQL表への挿入(D-11)
      -- **************************************************
--
      gt_header_id_upd_tab(ln_data_cnt) := loop_cnt.order_header_id; -- 受注ヘッダアドオンID
--
      ln_normal_cnt := ln_target_cnt;
      ln_warn_cnt   := ln_warn_cnt + ln_warn_flg;
      ln_warn_flg   := 0;
--
-- 2008/09/01 N.Yoshida ADD START
    --END LOOP upd_data_loop;
    END LOOP data_loop;
    CLOSE upd_status_cur;
-- 2008/09/01 N.Yoshida ADD END

-- Ver 1.17 M.Hokkanji START
    IF (( ln_data_cnt <> 0)
    AND ( lv_bfr_freight_charge_class = gv_freight_charge_class_on )
    AND ( lv_bfr_freight_carrier_code IS NULL)) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
                                            gv_cnst_msg_176,
                                            gv_cnst_tkn_request_no,
                                            lv_bfr_request_no);
      RAISE global_api_expt;
    END IF;
-- Ver 1.17 M.Hokkanji END
--
    IF ( ln_data_cnt = 0 ) THEN
      -- 出荷依頼情報対象データなし
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
                                            gv_cnst_msg_002);
      -- 警告をセット
      lv_warn_message := lv_errmsg;
-- Ver1.27 Y.Kazama 本番障害#1398 Mod Start
      ln_warn_cnt := 0 ;
--      ln_warn_cnt := 1 ;
-- Ver1.27 Y.Kazama 本番障害#1398 Mod End
      RAISE global_process_warn;
--
    -- 出荷依頼情報対象データあり
    -- チェック無しの場合はチェック処理を実施しない
    ELSIF (( ln_data_cnt > 0 ) AND ( iv_status_kbn = '2' )) THEN
      NULL;
    ELSE
--
      -- 最後に積載効率チェックを行う
      -- **************************************************
      -- *** 積載効率チェック(積載効率算出)(D-10)
      -- **************************************************
--
      -- 運賃区分がONの場合にチェックする   2008/07/09 ST不具合対応#430
      IF ( lv_bfr_freight_charge_class = gv_freight_charge_class_on ) THEN
--
-- Ver1.15 M.Hokkanji START
        -- 重量容積区分の値によりいずれかのみチェックを行うように修正（両方見るのはヘッダに値セット時のみ）
        IF (lt_weight_capacity_class = cv_weight_capacity_class_1) THEN
-- Ver1.15 M.Hokkanji END
          -- 前依頼No <> D-2依頼No の場合（重量チェック）
          xxwsh_common910_pkg.calc_load_efficiency(ln_bfr_sum_weight,        -- 前積載重量合計
                                                   NULL,                     -- 前積載容積合計
                                                   cv_whse_code,
                                                            -- クイックコード「コード区分」「倉庫」
                                                   lv_bfr_deliver_from,      -- 前出荷元保管場所
                                                   cv_deliver_to,
                                                            -- クイックコード「コード区分」「配送先」
                                                   lv_bfr_deliver_to,        -- 前配送先コード
                                                   lv_bfr_shipping_method_code,
                                                                                 -- 前配送区分
                                                   lv_bfr_prod_class,            -- 前商品区分
                                                   '0',                          -- 対象外 
                                                   id_bfr_schedule_ship_date,    -- 前出庫日
                                                   lv_retcode,                   -- リターンコード
                                                   lv_errbuf,                    -- エラーメッセージコード
                                                   lv_errmsg,                    -- エラーメッセージ
                                                   lv_loading_over_class,        -- 積載オーバー区分
                                                   lv_ship_methods,              -- 出荷方法
                                                   ln_load_efficiency_weight,    -- 重量積載効率
                                                   ln_load_efficiency_capacity,  -- 容積積載効率
                                                   lv_mixed_ship_method);        -- 混載配送区分
  --
          -- リターン・コードにエラーが返された場合はエラー
          IF ( lv_retcode = gn_status_error ) THEN
            lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
                                                  gv_cnst_msg_155,
                                                  'API_NAME',
                                                  cv_calc_load_efficiency_api,
                                                  'ERR_MSG',
                                                  lv_errmsg,
                                                  'REQUEST_NO',
                                                  lv_bfr_request_no,'POS',29);
            RAISE global_api_expt;
  --
          ELSIF ( lv_loading_over_class = 1 ) THEN-- 積載オーバーの場合
            lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
                                                  gv_cnst_msg_158,
                                                  'API_NAME',
                                                  cv_calc_load_efficiency_api,
                                                  'ERR_MSG',
                                                  lv_errmsg,
                                                  'REQUEST_NO',
                                                  lv_bfr_request_no,'POS',30);
            RAISE global_api_expt;
  --
          END IF;
-- Ver1.15 M.Hokkanji START
        ELSE
-- Ver1.15 M.Hokkanji END
  --
          -- 前依頼No <> D-2依頼No の場合(容積チェック)
          xxwsh_common910_pkg.calc_load_efficiency(NULL,                     -- 前積載重量合計
                                                   ln_bfr_sum_capacity,      -- 前積載容積合計
                                                   cv_whse_code,
                                                            -- クイックコード「コード区分」「倉庫」
                                                   lv_bfr_deliver_from,      -- 前出荷元保管場所
                                                   cv_deliver_to,
                                                            -- クイックコード「コード区分」「配送先」
                                                   lv_bfr_deliver_to,        -- 前配送先コード
                                                   lv_bfr_shipping_method_code,
                                                                                 -- 前配送区分
                                                   lv_bfr_prod_class,            -- 前商品区分
                                                   '0',                          -- 対象外 
                                                   id_bfr_schedule_ship_date,    -- 前出庫日
                                                   lv_retcode,                   -- リターンコード
                                                   lv_errbuf,                    -- エラーメッセージコード
                                                   lv_errmsg,                    -- エラーメッセージ
                                                   lv_loading_over_class,        -- 積載オーバー区分
                                                   lv_ship_methods,              -- 出荷方法
                                                   ln_load_efficiency_weight,    -- 重量積載効率
                                                   ln_load_efficiency_capacity,  -- 容積積載効率
                                                   lv_mixed_ship_method);        -- 混載配送区分
  --
          -- リターン・コードにエラーが返された場合はエラー
          IF ( lv_retcode = gn_status_error ) THEN
            lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
                                                  gv_cnst_msg_155,
                                                  'API_NAME',
                                                  cv_calc_load_efficiency_api,
                                                  'ERR_MSG',
                                                  lv_errmsg,
                                                  'REQUEST_NO',
                                                  lv_bfr_request_no);
            RAISE global_api_expt;
  --
          ELSIF ( lv_loading_over_class = 1 ) THEN-- 積載オーバーの場合
            lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
                                                  gv_cnst_msg_158,
                                                  'API_NAME',
                                                  cv_calc_load_efficiency_api,                                                                    
                                                  'ERR_MSG',
                                                  lv_errmsg,
                                                  'REQUEST_NO',
                                                  lv_bfr_request_no);
            RAISE global_api_expt;
  --
          END IF;
-- Ver1.15 M.Hokkanji START
        END IF;
-- Ver1.15 M.Hokkanji END
--
      END IF;  -- 2008/07/09 ST不具合対応#430
--
    END IF;
--
    -- **************************************************
    -- *** ステータス一括更新(D-12)
    -- **************************************************
--
    upd_table_batch(
       ov_errbuf  => lv_errbuf    -- エラー・メッセージ           --# 固定 #
     , ov_retcode => lv_retcode   -- リターン・コード             --# 固定 #
     , ov_errmsg  => lv_errmsg    -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    -- ステータス一括更新処理がエラーの場合
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_api_expt;
    END IF;
--
    -- **************************************************
    -- *** OUTパラメータセット(D-13)
    -- **************************************************
--
    IF (ln_warn_cnt > 0) THEN
      ov_retcode := gv_status_warn;
      IF (gv_callfrom_flg = '1') THEN
        lv_errmsg := NULL;
      ELSE
        lv_errmsg := lv_warn_message;
      END IF;
      RAISE global_process_warn;
    ELSE
      ov_retcode := lv_retcode;
    END IF;
--
    --==============================================================
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
    --==============================================================
--
    -- ==================================
    -- リターン・コードのセット、終了処理
    -- ==================================
    out_log(ln_target_cnt,ln_normal_cnt,0,ln_warn_cnt);
--
  EXCEPTION
--
    WHEN check_lock_expt THEN                           --*** ロック取得エラー ***
      -- エラーメッセージ取得
--
-- 2008/09/01 N.Yoshida ADD START
      IF ( upd_status_cur%ISOPEN )THEN
        CLOSE upd_status_cur;
      END IF;
-- 2008/09/01 N.Yoshida ADD END
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
                                            gv_cnst_msg_001);
      lv_errbuf := lv_errmsg;
      ov_errmsg := lv_errmsg;
      ov_errbuf := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
      out_log(0,0,1,0);
--
    WHEN global_process_warn THEN                           --*** ワーニング ***
-- 2008/09/01 N.Yoshida ADD START
      IF ( upd_status_cur%ISOPEN )THEN
        CLOSE upd_status_cur;
      END IF;
-- 2008/09/01 N.Yoshida ADD END
      ov_errmsg := lv_errmsg;
      ov_errbuf := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_warn;
      out_log(ln_target_cnt,ln_normal_cnt,0,ln_warn_cnt);
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
-- 2008/09/01 N.Yoshida ADD START
      IF ( upd_status_cur%ISOPEN )THEN
        CLOSE upd_status_cur;
      END IF;
-- 2008/09/01 N.Yoshida ADD END
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
      out_log(ln_data_cnt,ln_normal_cnt,1,ln_warn_cnt);
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
-- 2008/09/01 N.Yoshida ADD START
      IF ( upd_status_cur%ISOPEN )THEN
        CLOSE upd_status_cur;
      END IF;
-- 2008/09/01 N.Yoshida ADD END
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
      out_log(ln_data_cnt,ln_normal_cnt,1,ln_warn_cnt);
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
-- 2008/09/01 N.Yoshida ADD START
      IF ( upd_status_cur%ISOPEN )THEN
        CLOSE upd_status_cur;
      END IF;
-- 2008/09/01 N.Yoshida ADD END
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
      out_log(ln_data_cnt,ln_normal_cnt,1,ln_warn_cnt);
--
--#####################################  固定部 END   ##########################################
--
  END ship_set;
  --
END xxwsh400003c;
/
