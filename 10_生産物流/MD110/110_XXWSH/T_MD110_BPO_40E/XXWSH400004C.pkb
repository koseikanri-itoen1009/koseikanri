create or replace PACKAGE BODY xxwsh400004c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name           : xxwsh400004c(BODY)
 * Description            : 出荷依頼締め関数
 * MD.050                 : T_MD050_BPO_401_出荷依頼
 * MD.070                 : T_MD070_BPO_40E_出荷依頼締め関数
 * Version                : 1.14
 *
 * Program List
 *  ------------------------ ---- ---- --------------------------------------------------
 *   Name                    Type Ret  Description
 *  ------------------------ ---- ---- --------------------------------------------------
 *  in_order_type_id         P         出庫形態ID
 *  iv_deliver_from          P         出荷元
 *  iv_sales_base            P         拠点
 *  iv_sales_base_category   P         拠点カテゴリ
 *  in_lead_time_day         P         生産物流LT
 *  id_schedule_ship_date    P         出庫日
 *  iv_base_record_class     P         基準レコード区分
 *  iv_request_no            P         依頼No
 *  iv_tighten_class         P         締め処理区分
 *  in_tightening_program_id P         締めコンカレントID
 *  iv_tightening_status_chk_class
 *                           P         締めステータスチェック区分
 *  iv_callfrom_flg          P         呼出元フラグ
 *  iv_prod_class            P         商品区分
 *  iv_instruction_dept      P         部署
 * ------------- ----------- --------- --------------------------------------------------
 *  Date         Ver.  Editor          Description
 * ------------- ----- --------------- --------------------------------------------------
 *  2008/4/8     1.0   R.Matusita      新規作成
 *  2008/5/19    1.1   Oracle 上原正好 内部変更要求#80対応 パラメータ「拠点」追加
 *  2008/5/21    1.2   Oracle 上原正好 結合テストバグ修正
 *                                     パラメータ「締め処理区分」がNULLのときは'1'(初回締め)とする
 *                                     指示部署取得処理SQL修正(顧客情報VIEWを参照しない)
 *                                     呼出元フラグ'2'(画面)の場合の取得SQLを変更
 *                                     （依頼Noのみをキー項目に更新対象のデータを取得する)
 *  2008/6/06    1.3   Oracle 石渡賢和 リードタイムチェック時の判定を変更
 *  2008/6/27    1.4   Oracle 上原正好 内部課題56対応 呼出元が画面の場合にも締め管理アドオン登録
 *  2008/6/30    1.5   Oracle 北寒寺正夫 ST不具合対応#326
 *  2008/7/01    1.6   Oracle 北寒寺正夫 ST不具合対応#338
 *  2008/08/05   1.7   Oracle 山根一浩 出荷追加_5対応
 *  2008/10/10   1.8   Oracle 伊藤ひとみ 統合テスト指摘239対応
 *  2008/10/28   1.9   Oracle 伊藤ひとみ 統合テスト指摘141対応
 *  2008/11/14   1.10  SCS    伊藤ひとみ 統合テスト指摘650対応
 *  2008/12/01   1.11  SCS    菅原大輔   本番指摘253対応（暫定）
 *  2008/12/07   1.12  SCS    菅原大輔   本番#386
 *  2008/12/17   1.13  SCS    上原/福田  本番#81
 *  2008/12/17   1.13  SCS    福田       APP-XXWSH-11204エラー発生時に即時終了しないようにする
 *  2008/12/23   1.14  SCS    上原       本番#81 再締め処理時の抽出条件にリードタイムを追加
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
  gv_msg_part      CONSTANT VARCHAR2(3) := ' :';
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
  gv_pkg_name      CONSTANT VARCHAR2(100) := 'xxwsh400004c'; -- パッケージ名
--
  gv_cnst_msg_kbn  CONSTANT VARCHAR2(5)   := 'XXWSH';
  gv_cnst_msg_cmn  CONSTANT VARCHAR2(5)   := 'XXCMN';
--
  gv_cnst_sep_msg  CONSTANT VARCHAR2(15)  := 'APP-XXCMN-00003';  -- sep_msg
  gv_cnst_cmn_008  CONSTANT VARCHAR2(15)  := 'APP-XXCMN-00008';  -- 処理件数
  gv_cnst_cmn_009  CONSTANT VARCHAR2(15)  := 'APP-XXCMN-00009';  -- 成功件数
  gv_cnst_cmn_010  CONSTANT VARCHAR2(15)  := 'APP-XXCMN-00010';  -- エラー件数
  gv_cnst_cmn_011  CONSTANT VARCHAR2(15)  := 'APP-XXCMN-00011';  -- スキップ件数
  gv_cnst_cmn_cnt  CONSTANT VARCHAR2(15)  := 'CNT';              -- CNT
--
  -- 項目チェック
--
  gv_cnst_msg_fomt CONSTANT VARCHAR2(15)  := 'APP-XXWSH-11211';  -- マスタ書式エラーメッセージ
  gv_cnst_msg_204  CONSTANT VARCHAR2(15)  := 'APP-XXWSH-11204';  -- 締め処理実施済みエラー
  gv_cnst_msg_205  CONSTANT VARCHAR2(15)  := 'APP-XXWSH-11205';  -- 締め関数用共通関数エラー
  gv_cnst_msg_206  CONSTANT VARCHAR2(15)  := 'APP-XXWSH-11206';  -- 稼働日チェックエラー
  gv_cnst_msg_207  CONSTANT VARCHAR2(15)  := 'APP-XXWSH-11207';  -- リードタイムチェックエラー
  gv_cnst_msg_208  CONSTANT VARCHAR2(15)  := 'APP-XXWSH-11208';  -- 指示部署取得エラー
  gv_cnst_msg_null CONSTANT VARCHAR2(15)  := 'APP-XXWSH-11201';  -- 必須チェックエラーメッセージ
  gv_cnst_msg_222  CONSTANT VARCHAR2(15)  := 'APP-XXWSH-11224';  -- 択一選択チェックエラーメッセージ
  gv_cnst_msg_prop CONSTANT VARCHAR2(15)  := 'APP-XXWSH-11210';  -- 妥当性チェックエラーメッセージ
  gv_cnst_msg_001  CONSTANT VARCHAR2(15)  := 'APP-XXWSH-11202';  -- ﾛｯｸｴﾗｰ
  gv_cnst_msg_002  CONSTANT VARCHAR2(15)  := 'APP-XXWSH-11212';  -- 対象データなし
  gv_cnst_msg_003  CONSTANT VARCHAR2(15)  := 'APP-XXWSH-11213';  -- 処理件数出力
  gv_cnst_msg_220  CONSTANT VARCHAR2(15)  := 'APP-XXWSH-11220';  -- 正常処理件数出力
  gv_cnst_msg_221  CONSTANT VARCHAR2(15)  := 'APP-XXWSH-11221';  -- 警告処理件数出力
--
  gv_msg_xxcmn10146 CONSTANT VARCHAR2(100)  := 'APP-XXCMN-10146';
--                                            -- メッセージ：ロック取得エラー
  gv_cnst_token_api_name  CONSTANT VARCHAR2(15)  := 'API_NAME';
--
  gv_cnst_tkn_table       CONSTANT VARCHAR2(15)  := 'TABLE';
  gv_cnst_tkn_item        CONSTANT VARCHAR2(15)  := 'ITEM';
  gv_cnst_tkn_value       CONSTANT VARCHAR2(15)  := 'VALUE';
  gv_cnst_file_id_name    CONSTANT VARCHAR2(7)   := 'FILE_ID';
  gv_cnst_tkn_para        CONSTANT VARCHAR2(9)   := 'PARAMETER';
--
  gv_status_01            CONSTANT VARCHAR2(2)   := '01';    -- 入力中
  gv_status_02            CONSTANT VARCHAR2(2)   := '02';    -- 拠点確定
  gv_status_03            CONSTANT VARCHAR2(2)   := '03';    -- 締め済み
  gv_line_feed            CONSTANT VARCHAR2(1)   := CHR(10); -- 改行コード;
--
  gv_msg_null_01          CONSTANT VARCHAR2(30)  := '基準レコード区分';
  gv_msg_null_02          CONSTANT VARCHAR2(30)  := '締め処理区分';
  gv_msg_null_03          CONSTANT VARCHAR2(30)  := '呼出元フラグ';
  gv_msg_null_04          CONSTANT VARCHAR2(30)  := '締めステータス区分';
  gv_msg_null_06          CONSTANT VARCHAR2(30)  := '締めステータスチェック区分';
  gv_msg_null_08          CONSTANT VARCHAR2(30)  := '出庫日';
  gv_msg_null_05          CONSTANT VARCHAR2(30)  := '依頼No';
  gv_msg_null_07          CONSTANT VARCHAR2(30)  := '出庫形態';
  gv_msg_null_10          CONSTANT VARCHAR2(30)  := '生産物流LT/引取変更LT';
  gv_msg_null_11          CONSTANT VARCHAR2(30)  := '締めコンカレントID';
-- 2008/11/14 H.Itou Add Start 統合テスト指摘650 着荷日非稼働日警告の時にOUTパラメータ.エラーメッセージに返すメッセージ
  gv_msg_warn_01          CONSTANT VARCHAR2(30)  := '稼働日';
-- 2008/11/14 H.Itou Add End
  gv_status_A             CONSTANT VARCHAR2(1)   := 'A'; -- 有効
  gn_m999                 CONSTANT NUMBER        := -999;
  gv_ALL                  CONSTANT VARCHAR2(3)   := 'ALL';
  gv_sales_base_category_0 CONSTANT VARCHAR2(3)   := '0';
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
  gt_header_id_upd_tab    order_header_id_ttype; -- 受注ヘッダアドオンID
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
--
  gv_out_msg         VARCHAR2(2000);
  gv_sep_msg         VARCHAR2(2000);
  gn_target_cnt      NUMBER;                    -- 対象件数
  gn_normal_cnt      NUMBER;                    -- 正常件数
  gn_error_cnt       NUMBER;                    -- エラー件数
  gn_warn_cnt        NUMBER;                    -- スキップ件数
  gv_callfrom_flg    VARCHAR2(1);               -- 呼出元フラグ
  gv_party_number    VARCHAR2(30);              -- 組織番号
  gn_user_id         NUMBER;                    -- ログインしているユーザー
  gn_login_id        NUMBER;                    -- 最終更新ログイン
  gv_sales_base_category VARCHAR2(3);           -- 拠点カテゴリ
  gv_base_record_class VARCHAR2(2);             -- 基準レコード区分
  gn_conc_request_id NUMBER;                    -- 要求ID
  gn_prog_appl_id    NUMBER;                    -- コンカレント・プログラム・アプリケーションID
  gn_conc_program_id NUMBER;                    -- コンカレント・プログラムID
--
   /**********************************************************************************
   * Procedure Name   : insert_tightening_control
   * Description      : 締め済みレコード登録 (E-5)
   ***********************************************************************************/
  PROCEDURE insert_tightening_control(
    in_order_type_id         IN  NUMBER    DEFAULT NULL, -- 出庫形態ID
    iv_deliver_from          IN  VARCHAR2  DEFAULT NULL, -- 出荷元
    iv_sales_base            IN  VARCHAR2  DEFAULT NULL, -- 拠点
    iv_sales_base_category   IN  VARCHAR2  DEFAULT NULL, -- 拠点カテゴリ
    in_lead_time_day         IN  NUMBER    DEFAULT NULL, -- 生産物流LT
    id_schedule_ship_date    IN  DATE      DEFAULT NULL, -- 出庫日
    iv_prod_class            IN  VARCHAR2  DEFAULT NULL, -- 商品区分
    iv_base_record_class     IN  VARCHAR2  DEFAULT NULL, -- 基準レコード区分
    ov_errbuf                OUT NOCOPY VARCHAR2,        -- エラー・メッセージ           --# 固定 #
    ov_retcode               OUT NOCOPY VARCHAR2,        -- リターン・コード             --# 固定 #
    ov_errmsg                OUT NOCOPY VARCHAR2)        -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(30) := 'insert_tightening_control'; -- プログラム名
    cv_tighten_release_class_1       VARCHAR2(1)  := '1'; -- 締め/解除区分 締め
    cv_base_record_class_Z           VARCHAR2(1)    := 'Z'; -- 基準レコード区分Z
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
    ln_transaction_id   NUMBER DEFAULT 0;
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
    SELECT xxwsh_tightening_control_s1.NEXTVAL       -- トランザクションID
    INTO   ln_transaction_id
    FROM   dual;
--
    -- 基準レコード区分が'Z'の場合、コンカレントIDに'-(マイナス)トランザクションID'をセットする。
    IF (iv_base_record_class = cv_base_record_class_Z) THEN
      gn_conc_request_id := - ln_transaction_id;
--      gn_conc_program_id := - ln_transaction_id;
    END IF;
    -- =====================================
    -- 出荷依頼締め管理（アドオン）登録
    -- =====================================
    INSERT INTO xxwsh_tightening_control
       (transaction_id
      , concurrent_id
      , order_type_id
      , deliver_from
      , prod_class
      , sales_branch
      , sales_branch_category
      , lead_time_day
      , schedule_ship_date
      , tighten_release_class
      , tightening_date
      , base_record_class
      , created_by
      , creation_date
      , last_updated_by
      , last_update_date
      , last_update_login
      , request_id
      , program_application_id
      , program_id
      , program_update_date)
    VALUES(
        ln_transaction_id             -- トランザクションID
      , gn_conc_request_id            -- コンカレントID
      , NVL(in_order_type_id,gn_m999) -- 受注タイプID
      , NVL(iv_deliver_from,gv_ALL)   -- 出荷元保管場所
      , NVL(iv_prod_class,gv_ALL)     -- 商品区分
      , NVL(iv_sales_base,gv_ALL)     -- 拠点
      , NVL(gv_sales_base_category,gv_ALL) -- 拠点カテゴリ
      , NVL(in_lead_time_day,gn_m999) -- 生産物流LT
      , NVL(id_schedule_ship_date,SYSDATE) -- 出荷予定日
      , cv_tighten_release_class_1    -- 締め/解除区分 1：締め
      , SYSDATE                       -- 締め実施日時
      , iv_base_record_class          -- 基準レコード区分
      , gn_user_id                    -- 作成者
      , SYSDATE                       -- 作成日
      , gn_user_id                    -- 最終更新者
      , SYSDATE                       -- 最終更新日
      , gn_login_id                   -- 最終更新ログイン
      , gn_conc_request_id            -- 要求ID
      , gn_prog_appl_id               -- コンカレント・プログラム・アプリケーションID
      , gn_conc_program_id            -- コンカレント・プログラムID
      , SYSDATE);                     -- プログラム更新日
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
  END insert_tightening_control;
--
   /**********************************************************************************
   * Procedure Name   : delete_tightening_control
   * Description      : 締め解除レコード削除 (E-8)
   ***********************************************************************************/
  PROCEDURE delete_tightening_control(
    ln_conc_request_id       IN  NUMBER,                 -- コンカレントID
    ov_errbuf                OUT NOCOPY VARCHAR2,        -- エラー・メッセージ           --# 固定 #
    ov_retcode               OUT NOCOPY VARCHAR2,        -- リターン・コード             --# 固定 #
    ov_errmsg                OUT NOCOPY VARCHAR2)        -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(30) := 'delete_tightening_control'; -- プログラム名
    cv_tighten_release_class_2       VARCHAR2(1)  := '2'; -- 締め/解除区分 解除
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
    -- *** ローカル・カーソル ***
--
    -- 表ロック取得
    CURSOR get_tab_lock_cur
    IS
      SELECT  transaction_id
      FROM    xxwsh_tightening_control
      WHERE   concurrent_id         = ln_conc_request_id          -- コンカレントID
      AND     tighten_release_class = cv_tighten_release_class_2  -- 締め/解除区分 2：解除
      FOR UPDATE NOWAIT
      ;
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
    -- ===============================
    -- 表ロック取得
    -- ===============================
    BEGIN
      <<get_lock_loop>>
      FOR loop_cnt IN get_tab_lock_cur LOOP
        EXIT;
      END LOOP get_lock_loop;
--
    EXCEPTION
      --*** ロック取得エラー ***
      WHEN check_lock_expt THEN
        -- エラーメッセージ取得
        lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg(
                      gv_cnst_msg_kbn   -- モジュール名略称：XXCMN マスタ・経理共通
                     ,gv_msg_xxcmn10146 -- メッセージ：ロック取得エラー
                     ),1,5000);
        RAISE global_api_expt;
    END;
--
    -- =====================================
    -- 出荷依頼締め管理（アドオン）削除
    -- =====================================
    DELETE FROM xxwsh_tightening_control
    WHERE concurrent_id         = ln_conc_request_id          -- コンカレントID
    AND   tighten_release_class = cv_tighten_release_class_2; -- 締め/解除区分 2：解除
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
  END delete_tightening_control;
--
   /**********************************************************************************
   * Procedure Name   : get_party_number
   * Description      : 指示部署取得処理
   ***********************************************************************************/
  PROCEDURE get_party_number(
    id_schedule_ship_date IN  DATE,                   -- 出庫日
    ov_party_number       OUT NOCOPY VARCHAR2,        -- 組織番号
    ov_user_name          OUT NOCOPY VARCHAR2,        -- ユーザー名
    ov_errbuf             OUT NOCOPY VARCHAR2,        -- エラー・メッセージ           --# 固定 #
    ov_retcode            OUT NOCOPY VARCHAR2,        -- リターン・コード             --# 固定 #
    ov_errmsg             OUT NOCOPY VARCHAR2)        -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(20) := 'get_party_number';       -- プログラム名
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
    cv_customer_class_code VARCHAR2(1) := '1';
    -- *** ローカル変数 ***
--
    ln_user_id             NUMBER;                -- ログインしているユーザーのID取得
    lv_party_number        VARCHAR2(30)  := NULL; -- 組織番号
    lv_user_name           VARCHAR2(100) := NULL; -- ユーザー名
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
    SELECT xlv.location_code,fu.user_name
    INTO   lv_party_number,lv_user_name
    FROM   xxcmn_locations2_v        xlv    -- 事業所情報VIEW2
          ,per_all_assignments_f     paaf   -- 従業員割当マスタ
          ,fnd_user                  fu     -- ユーザーマスタ
    WHERE  fu.user_id                =  gn_user_id
    AND    paaf.person_id            =  fu.employee_id
    AND    paaf.primary_flag         =  'Y'
    AND    paaf.effective_start_date <= TRUNC(NVL(id_schedule_ship_date,SYSDATE))
    AND    paaf.effective_end_date   >= TRUNC(NVL(id_schedule_ship_date,SYSDATE))
    AND    xlv.start_date_active     <= TRUNC(NVL(id_schedule_ship_date,SYSDATE))
    AND    xlv.end_date_active       >= TRUNC(NVL(id_schedule_ship_date,SYSDATE))
    AND    xlv.inactive_date         Is Null
    AND    xlv.location_id           =  paaf.location_id;
--
    ov_party_number := lv_party_number;
    ov_user_name    := lv_user_name;
--
  EXCEPTION
--
    WHEN NO_DATA_FOUND THEN
      ov_party_number := NULL;
      ov_user_name    := NULL;
      ov_retcode      := gv_status_error;
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
  END get_party_number;
--
  /**********************************************************************************
   * Procedure Name   : upd_table_batch
   * Description      : ステータス一括更新処理(E-7)
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
--
    -- =====================================
    -- 一括更新処理
    -- =====================================
    FORALL ln_cnt IN 1 .. gt_header_id_upd_tab.COUNT
      -- 受注ヘッダアドオン更新(締め済み)
      UPDATE xxwsh_order_headers_all
      SET req_status              = gv_status_03                   -- ステータス(03:締め済み)
         ,instruction_dept        = gv_party_number                -- E-2組織番号
         ,tightening_program_id   = gn_conc_request_id             -- 要求ID
         ,last_updated_by         = gn_user_id                     -- 最終更新者
         ,last_update_date        = SYSDATE                        -- 最終更新日
         ,last_update_login       = gn_login_id                    -- 最終更新ログイン
         ,request_id              = gn_conc_request_id             -- 要求ID
         ,program_application_id  = gn_prog_appl_id                -- ｺﾝｶﾚﾝﾄ・ﾌﾟﾛｸﾞﾗﾑ・ｱﾌﾟﾘｹｰｼｮﾝID
         ,program_id              = gn_conc_program_id             -- コンカレント・プログラムID
         ,program_update_date     = SYSDATE                        -- プログラム更新日
      WHERE order_header_id       = gt_header_id_upd_tab(ln_cnt);  -- 受注ヘッダアドオンID
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
    IF (gv_callfrom_flg = 1) THEN
--    呼び出し元フラグが１：コンカレントの場合はログ出力する
--
      -- ==================================
      -- リターン・コードのセット、終了処理
      -- ==================================
--
      gn_target_cnt := in_target_cnt;
      gn_normal_cnt := in_normal_cnt;
      gn_error_cnt  := in_error_cnt;
      gn_warn_cnt   := in_warn_cnt;
--
      --処理件数出力
      gv_out_msg := xxcmn_common_pkg.get_msg(gv_cnst_msg_cmn,
                                             gv_cnst_cmn_008,
                                             gv_cnst_cmn_cnt,TO_CHAR(gn_target_cnt));
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
      --正常件数出力
      gv_out_msg := xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
                                             gv_cnst_msg_220,
                                             gv_cnst_cmn_cnt,TO_CHAR(gn_normal_cnt));
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
      --エラー件数出力
      gv_out_msg := xxcmn_common_pkg.get_msg(gv_cnst_msg_cmn,
                                             gv_cnst_cmn_010,
                                             gv_cnst_cmn_cnt,TO_CHAR(gn_error_cnt));
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
      --警告件数出力
      gv_out_msg := xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
                                             gv_cnst_msg_221,
                                             gv_cnst_cmn_cnt,TO_CHAR(gn_warn_cnt));
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
   * Procedure Name   : init_proc
   * Description      : 関連データ取得
   ***********************************************************************************/
  PROCEDURE init_proc(
    id_schedule_ship_date     IN   DATE,                -- 出庫日
    ln_transaction_type_id    OUT  NUMBER,              -- タイプID
    ov_errbuf           OUT NOCOPY VARCHAR2,            -- エラー・メッセージ           --# 固定 #
    ov_retcode          OUT NOCOPY VARCHAR2,            -- リターン・コード             --# 固定 #
    ov_errmsg           OUT NOCOPY VARCHAR2)            -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(20) := 'init_proc';       -- プログラム名
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
    cv_app_name             CONSTANT VARCHAR2(5)  := 'XXWSH';             -- アプリケーション短縮名
    cv_msg_ng_data          CONSTANT VARCHAR2(15) := 'APP-XXWSH-11223';   -- 対象データなし
    cv_tkn_item             CONSTANT VARCHAR2(15) := 'ITEM';              -- トークン：対象名
    cv_format_type          CONSTANT VARCHAR2(20) := 'フォーマットパターン';
    cv_tkn_value            CONSTANT VARCHAR2(15) := 'VALUE';             -- トークン：値
--
    -- プロファイル
    cv_tran_type_plan       CONSTANT VARCHAR2(30) := 'XXWSH_TRAN_TYPE_PLAN';
    -- *** ローカル変数 ***
    lv_tran_type_plan           VARCHAR2(100);   -- プロファイル：引当変更
--
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
    -- ***************************************
    -- ***         プロファイル取得        ***
    -- ***************************************
    -- プロファイル「引当変更」取得
    lv_tran_type_plan := FND_PROFILE.VALUE(cv_tran_type_plan);
--
--
    -- タイプID取得
    BEGIN
      SELECT  transaction_type_id
      INTO    ln_transaction_type_id
      FROM    xxwsh_oe_transaction_types2_v -- 受注タイプ情報VIEW2
      WHERE   transaction_type_name =  lv_tran_type_plan
      AND     start_date_active    <= TRUNC(NVL(id_schedule_ship_date,SYSDATE))
      AND     (end_date_active     IS NULL
      OR       end_date_active     >= TRUNC(NVL(id_schedule_ship_date,SYSDATE))
              )
      ;
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN                           -- *** データ取得エラー ***
        lv_errmsg := xxcmn_common_pkg.get_msg(
                            cv_app_name,                -- アプリケーション短縮名：XXINV
                            cv_msg_ng_data,             -- APP-XXINV-10008：対象データなし
                            cv_tkn_item,                -- トークン：対象名
                            cv_format_type,             -- フォーマットパターン
                            cv_tkn_value,               -- トークン：値
                            lv_tran_type_plan);         -- ファイルフォーマット
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
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
  END init_proc;
--
  /**********************************************************************************
   * Procedure Name   : 出荷依頼締め
   * Description      : ship_tightening
   ***********************************************************************************/
  PROCEDURE ship_tightening(
    in_order_type_id         IN  NUMBER    DEFAULT NULL, -- 出庫形態ID
    iv_deliver_from          IN  VARCHAR2  DEFAULT NULL, -- 出荷元
    iv_sales_base            IN  VARCHAR2  DEFAULT NULL, -- 拠点
    iv_sales_base_category   IN  VARCHAR2  DEFAULT NULL, -- 拠点カテゴリ
    in_lead_time_day         IN  NUMBER    DEFAULT NULL, -- 生産物流LT
    id_schedule_ship_date    IN  DATE      DEFAULT NULL, -- 出庫日
    iv_base_record_class     IN  VARCHAR2  DEFAULT NULL, -- 基準レコード区分
    iv_request_no            IN  VARCHAR2  DEFAULT NULL, -- 依頼No
    iv_tighten_class         IN  VARCHAR2  DEFAULT NULL, -- 締め処理区分
    in_tightening_program_id IN  NUMBER    DEFAULT NULL, -- 締めコンカレントID
    iv_tightening_status_chk_class
                             IN  VARCHAR2,               -- 締めステータスチェック区分
    iv_callfrom_flg          IN  VARCHAR2,               -- 呼出元フラグ
    iv_prod_class            IN  VARCHAR2  DEFAULT NULL, -- 商品区分
    iv_instruction_dept      IN  VARCHAR2  DEFAULT NULL, -- 部署
    ov_errbuf                OUT NOCOPY  VARCHAR2,       -- エラー・メッセージ           --# 固定 #
    ov_retcode               OUT NOCOPY  VARCHAR2,       -- リターン・コード             --# 固定 #
    ov_errmsg                OUT NOCOPY  VARCHAR2)       -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name    CONSTANT          VARCHAR2(100)  := 'ship_tightening'; -- プログラム名
    cv_order_category_code           VARCHAR2(5)    := 'ORDER';           -- 受注
    cv_shipping_shikyu_class         VARCHAR2(1)    := '1';               -- 出荷依頼
    cv_get_oprtn_day_api             VARCHAR2(50)   := '稼働日算出関数';
    cv_get_oprtn_day_lt              VARCHAR2(50)   := '生産物流LT／引取変更LT';
    cv_calc_lead_time_api            VARCHAR2(50)   := 'リードタイム算出';
    cv_get_oprtn_day_lt2             VARCHAR2(50)   := '配送リードタイム';
--
    cv_order_type_id_04              VARCHAR2(2)    := '04';  -- 引取変更
    cv_customer_class_code_1         VARCHAR2(1)    := '1'; -- 顧客区分
    cv_code_class_4                  VARCHAR2(1)    := '4'; -- 1：倉庫
    cv_code_class_9                  VARCHAR2(1)    := '9'; -- 9：配送先
    cv_code_class_1                  VARCHAR2(1)    := '1'; -- 1：拠点
    cv_prod_class_2                  VARCHAR2(1)    := '2'; -- 2：ドリンク
    cv_prod_class_1                  VARCHAR2(1)    := '1'; -- 1：リーフ
    cv_tighten_class_1               VARCHAR2(1)    := '1'; -- 締め処理区分1:初回
    cv_tighten_class_2               VARCHAR2(1)    := '2'; -- 締め処理区分2:再
    cv_tightening_status_chk_cla_1   VARCHAR2(1)    := '1'; -- 締めステータスチェック区分1
    cv_tightening_status_chk_cla_2   VARCHAR2(1)    := '2'; -- 締めステータスチェック区分2
    cv_tightening_status_chk_cla_0   VARCHAR2(1)    := '0'; -- 締めステータスチェック区分0
    cv_base_record_class_Y           VARCHAR2(1)    := 'Y'; -- 基準レコード区分Y
    cv_base_record_class_N           VARCHAR2(1)    := 'N'; -- 基準レコード区分N
    cv_base_record_class_Z           VARCHAR2(1)    := 'Z'; -- 基準レコード区分Z
    cv_callfrom_flg_1                VARCHAR2(1)    := '1'; -- 呼出元フラグ1
    cv_callfrom_flg_2                VARCHAR2(1)    := '2'; -- 呼出元フラグ2
    cv_status_2                      VARCHAR2(1)    := '2'; -- 締めステータス2
    cv_status_4                      VARCHAR2(1)    := '4'; -- 締めステータス4
    cv_deliver_from_4                VARCHAR2(1)    := '4'; -- 倉庫4
    cv_deliver_to_9                  VARCHAR2(1)    := '9'; -- 配送先9
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
    -- *** ローカル変数 ***
--
    ln_retcode                       NUMBER DEFAULT 0; -- リターンコード
--
    ld_oprtn_day                     DATE;         -- 稼働日日付
    ld_sysdate                       DATE;         -- システム日付
    ld_schedule_ship_date            DATE;         -- 出庫日
    ln_data_cnt                      NUMBER := 0;  -- データ件数
    ln_target_cnt                    NUMBER := 0;  -- 処理件数
    ln_normal_cnt                    NUMBER := 0;  -- 正常件数
    ln_warn_cnt                      NUMBER := 0;  -- ワーニング処理件数
    lv_err_message                   VARCHAR2(4000); -- エラーメッセージ
--
    ln_lead_time                     NUMBER;       -- 生産物流LT／引取変更LT
    ln_delivery_lt                   NUMBER;       -- 配送LT
    lv_status                        VARCHAR2(2);  -- 締めステータス
    ln_bfr_order_header_id           NUMBER DEFAULT 0;  -- 受注ヘッダアドオンID
    ln_order_header_id_lock          NUMBER;            -- 受注ヘッダアドオンID(ロック用)  2008/12/17 本番障害#81 Add
--
    ln_deliver_from_nullflg          NUMBER;       -- 出荷元NULLチェックフラグ
    ln_prod_class_nullflg            NUMBER;       -- 商品区分NULLチェックフラグ
    ln_request_no_nullflg            NUMBER;       -- 依頼NoNULLチェックフラグ
    ln_schedule_ship_date_nullflg    NUMBER;       -- 出庫日NULLチェックフラグ
    ln_drink_base_category_flg       NUMBER;       -- ドリンク拠点カテゴリフラグ
    ln_leaf_base_category_flg        NUMBER;       -- リーフ拠点カテゴリフラグ
    ln_tightening_prog_id_nullflg    NUMBER;       -- 締めコンカレントIDNULLチェックフラグ
    ln_order_type_id_nullflg         NUMBER;       -- 出庫形態IDNULLチェックフラグ
    ln_lock_error_flg                NUMBER;       -- ロックエラーフラグ                    2008/12/17 本番障害#81 Add
    ln_stschk_error_flg              NUMBER;       -- 締めステータスチェックエラーフラグ    2008/12/17 Add V1.13 APP-XXWSH-11204エラー発生時に即時終了しないようにする
    lv_user_name                     VARCHAR2(100); -- ユーザー名
    ln_transaction_type_id           NUMBER;       -- タイプID
    -- 動的SQL格納用
    lv_sql                           VARCHAR2(32000);
    lv_lead_time_w                   VARCHAR2(32000);
--
    -- 対象依頼Noによる取得用（画面）
    cv_main_sql                      CONSTANT VARCHAR2(32000) :=
       ' SELECT
            xoha.tightening_program_id tightening_program_id -- 締めコンカレントID
           ,xoha.order_type_id         order_type_id         -- 受注タイプID
           ,NULL                       lead_time_day         -- 引取変更LT
           ,NVL(xoha.shipped_date,xoha.schedule_ship_date)    schedule_ship_date    -- 出荷予定日
           ,NVL(xoha.arrival_date,xoha.schedule_arrival_date) schedule_arrival_date -- 着荷予定日
           ,NVL(xoha.result_deliver_to,xoha.deliver_to) deliver_to            -- 出荷先
           ,xoha.deliver_from          deliver_from          -- 出荷元保管場所
           ,xoha.prod_class            prod_class            -- 商品区分
           ,xoha.request_no            request_no            -- 依頼No
           ,xoha.order_header_id       order_header_id       -- 受注ヘッダアドオンID
         FROM
           xxwsh_order_headers_all       xoha           -- 受注ヘッダアドオン
         WHERE
           xoha.request_no         =  :iv_request_no    -- 依頼No
--2008/12/07 D.Sugahara Mod Start
         FOR UPDATE OF xoha.order_header_id  SKIP LOCKED '
--         FOR UPDATE OF xoha.order_header_id NOWAIT
--2008/12/07 D.Sugahara Mod End
      ;
    -- 締め処理
-- 2008/12/17 mod start ver1.13 M_Uehara
    cv_main_sql1                   CONSTANT VARCHAR2(32000) :=
        'SELECT
              tightening_program_id,            -- 締めコンカレントID
              order_type_id,                    -- 受注タイプID
              lead_time_day,                    -- リードタイム
              schedule_ship_date,               -- 出荷予定日
              schedule_arrival_date,            -- 着荷予定日
              deliver_to,                       -- 配送先
              deliver_from,                     -- 出庫元
              prod_class,                       -- 商品区分
              request_no,                       -- 依頼No
              order_header_id                   -- 受注ヘッダアドオンID
         FROM (
           -- 配送LT（倉庫・配送先）で取得
           SELECT
             xoha.tightening_program_id tightening_program_id
                                           -- 受注タイプID - 受注ヘッダアドオン.締めコンカレントID
           , xoha.order_type_id         order_type_id
                                           -- 受注タイプID - 受注ヘッダアドオン.受注タイプID
           , CASE xottv.transaction_type_id -- 受注タイプ
               WHEN :ln_transaction_type_id THEN
                    -- 引取変更
                    xdl.receipt_change_lead_time_day  -- 引き取り変更LT（倉庫・配送先）
               ELSE
                    -- 引取変更以外
                DECODE(xoha.prod_class,:cv_prod_class_2,  -- ドリンク生産物流LT
                       xdl.drink_lead_time_day     --ドリンク生産物流LT（倉庫・配送先）
                                       ,:cv_prod_class_1,  -- リーフ生産物流LT
                        xdl.leaf_lead_time_day       -- リーフ生産物流LT（倉庫・配送先）
                       )
             END                        lead_time_day -- リードタイム
           , xoha.schedule_ship_date    schedule_ship_date
                                                          -- 出庫日 - 受注ヘッダアドオン.出荷予定日
           , xoha.schedule_arrival_date schedule_arrival_date
                                                          -- 着日 - 受注ヘッダアドオン.着荷予定日
           , xoha.deliver_to            deliver_to
                                                          -- 配送先コード - 受注ヘッダアドオン.出荷先
           , xoha.deliver_from          deliver_from
                                          -- 出荷元保管場所コード - 受注ヘッダアドオン.出荷元保管場所
           , xoha.prod_class            prod_class
                                                          -- 商品区分 - 受注ヘッダアドオン.商品区分
           , xoha.request_no            request_no
                                                          -- 依頼No - 受注ヘッダアドオン.依頼No
           , xoha.order_header_id       order_header_id   -- 受注ヘッダアドオンID
           FROM
             xxwsh_oe_transaction_types2_v xottv    --①受注タイプ情報VIEW2
            ,xxwsh_order_headers_all       xoha     --②受注ヘッダアドオン
            ,xxcmn_cust_accounts2_v        xcav
            ,xxcmn_cust_acct_sites2_v      xcasv
            ,(SELECT DISTINCT
                  lt.code_class1                  code_class1,
                                                                --コード区分1（倉庫・配送先）
                  lt.entering_despatching_code1   entering_despatching_code1,
                                                                --入出庫場所コード１（倉庫・配送先）
                  lt.code_class2                  code_class2,
                                                                --コード区分2（倉庫・配送先）
                  lt.entering_despatching_code2   entering_despatching_code2,
                                                                --入出庫場所コード2（倉庫・配送先）
                  lt.drink_lead_time_day          drink_lead_time_day,
                                                                --ドリンク生産物流LT（倉庫・配送先）
                  lt.leaf_lead_time_day           leaf_lead_time_day,
                                                                --リーフ生産物流LT（倉庫・配送先）
                  lt.receipt_change_lead_time_day receipt_change_lead_time_day,
                                                                --引き取り変更LT（倉庫・配送先）
                  lt.lt_start_date_active         lt_start_date_active,
                  lt.lt_end_date_active           lt_end_date_active
             FROM
                   xxcmn_delivery_lt2_v          lt    --配送L/Tアドオンマスタ（倉庫・配送先）
             WHERE lt.code_class1                   = :cv_code_class_4 --コード区分1：倉庫
             AND   lt.code_class2                   = :cv_code_class_9 --コード区分2：配送先
           )                           xdl    --配送L/Tアドオンマスタ（倉庫・配送先）
           ';
/**
    cv_main_sql1                   CONSTANT VARCHAR2(32000) :=
       ' SELECT
           xoha.tightening_program_id tightening_program_id
                                         -- 受注タイプID - 受注ヘッダアドオン.締めコンカレントID
         , xoha.order_type_id         order_type_id
                                         -- 受注タイプID - 受注ヘッダアドオン.受注タイプID
         , CASE xottv.transaction_type_id -- 受注タイプ
             WHEN :ln_transaction_type_id THEN
                  -- 引取変更
              NVL(xdl.lt1_rcpt_cng_lead_time_day  -- 引き取り変更LT（倉庫・配送先）
                 ,xdl.lt2_rcpt_cng_lead_time_day) -- 引き取り変更LT（倉庫・拠点）
             ELSE
                  -- 引取変更以外
              DECODE(xoha.prod_class,:cv_prod_class_2,  -- ドリンク生産物流LT
                     NVL(xdl.lt1_drink_lead_time_day     --ドリンク生産物流LT（倉庫・配送先）
                       , xdl.lt2_drink_lead_time_day)     --ドリンク生産物流LT（倉庫・拠点）
                                     ,:cv_prod_class_1,  -- リーフ生産物流LT
                      NVL(xdl.lt1_leaf_lead_time_day       -- リーフ生産物流LT（倉庫・配送先）
                       , xdl.lt2_leaf_lead_time_day)      -- リーフ生産物流LT（倉庫・拠点）
                     )
           END                        lead_time_day -- リードタイム
         , xoha.schedule_ship_date    schedule_ship_date
                                                        -- 出庫日 - 受注ヘッダアドオン.出荷予定日
         , xoha.schedule_arrival_date schedule_arrival_date
                                                        -- 着日 - 受注ヘッダアドオン.着荷予定日
         , xoha.deliver_to            deliver_to
                                                        -- 配送先コード - 受注ヘッダアドオン.出荷先
         , xoha.deliver_from          deliver_from
                                        -- 出荷元保管場所コード - 受注ヘッダアドオン.出荷元保管場所
         , xoha.prod_class            prod_class
                                                        -- 商品区分 - 受注ヘッダアドオン.商品区分
         , xoha.request_no            request_no
                                                        -- 依頼No - 受注ヘッダアドオン.依頼No
         , xoha.order_header_id       order_header_id   -- 受注ヘッダアドオンID
         FROM
           xxwsh_oe_transaction_types2_v xottv    --①受注タイプ情報VIEW2
          ,xxwsh_order_headers_all       xoha     --②受注ヘッダアドオン
          ,xxcmn_cust_accounts2_v        xcav     --④顧客情報VIEW2
          ,xxcmn_cust_accounts2_v        xcav2    --顧客情報VIEW2-2
          ,xxcmn_cust_acct_sites2_v      xcasv2'; --顧客サイト情報VIEW2-2
**/
-- 2008/12/17 mod end ver1.13 M_Uehara
--
    cv_retable                     CONSTANT VARCHAR2(32000) :=
        ' ,xxwsh_tightening_control      xtc';    --出荷依頼締め管理（アドオン）
--
-- 2008/12/17 del start ver1.13 M_Uehara
/**
    cv_main_sql2                   CONSTANT VARCHAR2(32000) :=
     '   ,(SELECT DISTINCT
             lt2.code_class1                  lt2_code_class1,
                                                   --コード区分１（倉庫・配送先）
             lt2.entering_despatching_code1   lt2_entering_despatching_code1,
                                                               --入出庫場所コード１（倉庫・配送先）
             lt1.code_class2                  lt1_code_class2,
                                                               --コード区分２（倉庫・配送先）
             lt1.entering_despatching_code2   lt1_entering_despatching_code2,
                                                               --入出庫場所コード２（倉庫・配送先）
             lt2.code_class2                  lt2_code_class2,
                                                               --コード区分２（倉庫・拠点）
             lt2.entering_despatching_code2   lt2_entering_despatching_code2,
                                                               --入出庫場所コード２（倉庫・拠点）
             lt1.drink_lead_time_day          lt1_drink_lead_time_day,
                                                               --ドリンク生産物流LT（倉庫・配送先）
             lt1.leaf_lead_time_day           lt1_leaf_lead_time_day,
                                                               --リーフ生産物流LT（倉庫・配送先）
             lt1.receipt_change_lead_time_day lt1_rcpt_cng_lead_time_day,
                                                               --引き取り変更LT（倉庫・配送先）
             lt2.drink_lead_time_day          lt2_drink_lead_time_day,
                                                               --ドリンク生産物流LT（倉庫・拠点）
             lt2.leaf_lead_time_day           lt2_leaf_lead_time_day,
                                                               --リーフ生産物流LT（倉庫・拠点）
             lt2.receipt_change_lead_time_day lt2_rcpt_cng_lead_time_day,
                                                               --引き取り変更LT（倉庫・拠点）
             lt1.lt_start_date_active         lt1_start_date_active,
             lt1.lt_end_date_active           lt1_end_date_active,
             lt2.lt_start_date_active         lt2_start_date_active,
             lt2.lt_end_date_active           lt2_end_date_active,
             lt2.xcav_start_date_active       xcav_start_date_active,
             lt2.xcav_end_date_active         xcav_end_date_active,
             lt2.xcasv_start_date_active      xcasv_start_date_active,
             lt2.xcasv_end_date_active        xcasv_end_date_active
           FROM
          (SELECT DISTINCT
                lt.code_class1                  code_class1,
                                                              --コード区分1（倉庫・拠点）
                lt.entering_despatching_code1   entering_despatching_code1,
                                                              --入出庫場所コード１（倉庫・拠点）
                lt.code_class2                  code_class2,
                                                              --コード区分2（倉庫・拠点）
                lt.entering_despatching_code2   entering_despatching_code2,
                                                              --入出庫場所コード2（倉庫・拠点）
                lt.drink_lead_time_day          drink_lead_time_day,
                                                              --ドリンク生産物流LT（倉庫・拠点）
                lt.leaf_lead_time_day           leaf_lead_time_day,
                                                              --リーフ生産物流LT（倉庫・拠点）
                lt.receipt_change_lead_time_day receipt_change_lead_time_day,
                                                              --引き取り変更LT（倉庫・拠点）
                xcav.party_number               party_number,
                xcasv.party_site_number         party_site_number,
                lt.lt_start_date_active         lt_start_date_active,
                lt.lt_end_date_active           lt_end_date_active,
                xcav.start_date_active          xcav_start_date_active,
                xcav.end_date_active            xcav_end_date_active,
                xcasv.start_date_active         xcasv_start_date_active,
                xcasv.end_date_active           xcasv_end_date_active
           FROM
                 xxcmn_delivery_lt2_v          lt    --配送L/Tアドオンマスタ（倉庫・拠点）
                ,xxcmn_cust_accounts2_v        xcav
                ,xxcmn_cust_acct_sites2_v      xcasv
           WHERE lt.code_class1                   = :cv_code_class_4 --コード区分1：倉庫
           AND   lt.code_class2                   = :cv_code_class_1 --コード区分2：拠点
           AND   lt.entering_despatching_code2    = xcav.party_number
           AND   xcasv.base_code                  = xcav.party_number
         )                           lt2    --配送L/Tアドオンマスタ（倉庫・拠点）
         ,xxcmn_delivery_lt2_v       lt1    --配送L/Tアドオンマスタ（倉庫・配送先）
         WHERE lt2.code_class1                   = lt1.code_class1(+)
         AND   lt2.entering_despatching_code1    = lt1.entering_despatching_code1(+)
         AND   lt2.party_site_number             = lt1.entering_despatching_code2(+)
         AND   lt1.code_class2(+)                = :cv_code_class_9 --コード区分2：配送先
         ) xdl
       WHERE xottv.order_category_code   =  :cv_order_category_code
                                -- 受注タイプ.受注カテゴリ＝「受注」かつ
       AND   xottv.shipping_shikyu_class =  :cv_shipping_shikyu_class
                                -- 受注タイプ.出荷支給区分＝「出荷依頼」かつ
       AND   xoha.order_type_id          =  xottv.transaction_type_id
                                -- 受注ヘッダアドオン.受注タイプID＝受注タイプ.取引タイプIDかつ
       AND   xoha.req_status             =  :gv_status_02';
                                -- 受注ヘッダアドオン.ステータス＝「02:拠点確定」かつ
**/
-- 2008/12/17 mod end ver1.13 M_Uehara
--
    cv_rewhere                     CONSTANT VARCHAR2(32000) :=
     ' WHERE xottv.order_category_code   =  :cv_order_category_code
                                  -- 受注タイプ.受注カテゴリ＝「受注」かつ
         AND   xottv.shipping_shikyu_class =  :cv_shipping_shikyu_class
                                  -- 受注タイプ.出荷支給区分＝「出荷依頼」かつ
         AND   xoha.order_type_id          =  xottv.transaction_type_id
                                  -- 受注ヘッダアドオン.受注タイプID＝受注タイプ.取引タイプIDかつ
         AND   xoha.req_status             =  :gv_status_02
                                  -- 受注ヘッダアドオン.ステータス＝「02:拠点確定」かつ
       AND   (1 = :ln_tightening_prog_id_nullflg -- フラグが0なら締めコンカレントIDを条件に追加する
              OR xtc.concurrent_id       = :in_tightening_program_id)
                                -- 出荷依頼締め管理（アドオン）.コンカレントID
                                -- ＝パラメータ.締めコンカレントIDかつ
       AND   xtc.order_type_id           = DECODE(xtc.order_type_id
                                                ,:gn_m999,:gn_m999
                                                         , xoha.order_type_id)
                                -- 出荷依頼締め管理（アドオン）.受注タイプID
                                -- ＝受注ヘッダアドオン. 受注タイプIDかつ
       AND   xtc.deliver_from            = DECODE(xtc.deliver_from
                                              ,:gv_ALL,:gv_ALL
                                                      , xoha.deliver_from)
                                -- 出荷依頼締め管理（アドオン）.出荷元保管場所
                                -- ＝受注ヘッダアドオン.出荷元保管場所かつ
       AND   xtc.schedule_ship_date      = xoha.schedule_ship_date
                                -- 出荷依頼締め管理（アドオン）.出荷予定日
                                -- ＝受注ヘッダアドオン.出荷予定日かつ
       AND   xtc.prod_class              = xoha.prod_class
                                -- 出荷依頼締め管理（アドオン）.商品区分
                                -- ＝受注ヘッダアドオン.商品区分かつ
       AND   xtc.sales_branch           = DECODE(xtc.sales_branch
                                              ,:gv_ALL,:gv_ALL
                                              ,xoha.head_sales_branch)
                                -- 出荷依頼締め管理（アドオン）.拠点
                                -- ＝受注ヘッダアドオン.管轄拠点かつ
       AND   xtc.sales_branch_category   = DECODE(xtc.sales_branch_category
                                              ,:gv_ALL,:gv_ALL ,
                                              DECODE(xtc.prod_class
                                                   , :cv_prod_class_2, xcav.drink_base_category
                                                   , :cv_prod_class_1, xcav.leaf_base_category))';
                                -- 出荷依頼締め管理（アドオン）.拠点カテゴリ
                                -- ＝顧客マスタ.拠点カテゴリかつ
--
    cv_where                       CONSTANT VARCHAR2(32000) :=
     ' WHERE xottv.order_category_code   =  :cv_order_category_code
                                  -- 受注タイプ.受注カテゴリ＝「受注」かつ
       AND   xottv.shipping_shikyu_class =  :cv_shipping_shikyu_class
                                  -- 受注タイプ.出荷支給区分＝「出荷依頼」かつ
       AND   xoha.order_type_id          =  xottv.transaction_type_id
                                  -- 受注ヘッダアドオン.受注タイプID＝受注タイプ.取引タイプIDかつ
       AND   xoha.req_status             =  :gv_status_02
                                  -- 受注ヘッダアドオン.ステータス＝「02:拠点確定」かつ
       AND  ((1 = :ln_order_type_id_nullflg) -- フラグが0なら出荷元を条件に追加する
              OR  (xoha.order_type_id     =  :in_order_type_id))
                                -- 受注ヘッダアドオン.出庫形態ID＝パラメータ.出庫形態IDかつ
       AND  ((1 = :ln_deliver_from_nullflg) -- フラグが0なら出荷元を条件に追加する
              OR (xoha.deliver_from       = :iv_deliver_from))
                                -- 受注ヘッダアドオン.出荷元保管場所＝パラメータ.出荷元かつ
       AND  ((1 = :ln_request_no_nullflg) -- フラグが0なら依頼Noを条件に追加する
              OR (xoha.request_no         = :iv_request_no))
                                -- 受注ヘッダアドオン.依頼No＝パラメータ.依頼Noかつ
       AND  ((1 = :ln_schedule_ship_date_nullflg) -- フラグが0なら出庫日を条件に追加する
              OR (xoha.schedule_ship_date = :id_schedule_ship_date))
                                -- 受注ヘッダアドオン.出荷予定日＝パラメータ.出庫日かつ
       AND  ((1 = :ln_prod_class_nullflg) -- フラグが0なら依頼Noを条件に追加する
              OR (xoha.prod_class         = :iv_prod_class))';
                                -- 受注ヘッダアドオン.商品区分＝パラメータ.商品区分 かつ
--
-- 2008/12/17 mod start ver1.13 M_Uehara
    cv_main_sql2                   CONSTANT VARCHAR2(32000) :=
     ' AND   xcav.party_number            = xoha.head_sales_branch
                   -- パーティマスタ(管轄拠点)．組織番号＝受注ヘッダアドオン．管轄拠点かつ
       AND   xcav.start_date_active       <= NVL(xoha.shipped_date,xoha.schedule_ship_date)
                   -- パーティアドオンマスタ(管轄拠点)．適用開始日≦パラメータ. 出庫日かつ
       AND   xcav.end_date_active         >= NVL(xoha.shipped_date,xoha.schedule_ship_date)
                                -- パーティアドオンマスタ.適用終了日≧パラメータ. 出庫日かつ
       AND   xcav.customer_class_code     = :cv_customer_class_code_1
                                -- 顧客マスタ．顧客区分=1かつ
       AND  ((1 = :ln_drink_base_category_flg)
                                    -- フラグが0ならドリンク拠点カテゴリを条件に追加する
              OR (xcav.drink_base_category         = :iv_sales_base_category))
                                -- 顧客マスタ．ドリンク拠点カテゴリ＝パラメータ．拠点カテゴリ
       AND  ((1 = :ln_leaf_base_category_flg)
                                    -- フラグが0ならリーフ拠点カテゴリを条件に追加する
              OR (xcav.leaf_base_category = :iv_sales_base_category))
                                -- 顧客マスタ．リーフ拠点カテゴリ＝パラメータ．拠点カテゴリ
       AND   xdl.entering_despatching_code1  = xoha.deliver_from
                                                           -- 受注ヘッダアドオン.出荷元保管場所
       AND   xdl.entering_despatching_code2  = xoha.deliver_to
                                                           -- 受注ヘッダアドオン.配送先
       AND   xcasv.base_code                  = xcav.party_number
       AND   xoha.deliver_to_id             =  xcasv.party_site_id
       AND   xcasv.start_date_active         <= xoha.schedule_ship_date
                                                           -- 受注ヘッダアドオン.出荷予定日
       AND  (xcasv.end_date_active           IS NULL
         OR  xcasv.end_date_active           >= xoha.schedule_ship_date)'
       ;                                                   -- 受注ヘッダアドオン.出荷予定日
     cv_lead_time_w1                   CONSTANT VARCHAR2(32000)
     :=    ' AND  receipt_change_lead_time_day =  :in_lead_time_day';
                                     -- 引き取り変更LT（倉庫・配送先）
                                     -- 引き取り変更LT（倉庫・拠点）
--
     cv_lead_time_w2                   CONSTANT VARCHAR2(32000)
     :=    ' AND  drink_lead_time_day =  :in_lead_time_day';
                                     --ドリンク生産物流LT（倉庫・配送先）
                                     --ドリンク生産物流LT（倉庫・拠点）
--
     cv_lead_time_w3                   CONSTANT VARCHAR2(32000)
     :=    ' AND  leaf_lead_time_day =  :in_lead_time_day';
                                     -- リーフ生産物流LT（倉庫・配送先
                                     -- リーフ生産物流LT（倉庫・拠点）
     cv_main_sql3                   CONSTANT VARCHAR2(32000) :=
     ' AND   xcav.account_status            =  :gv_status_A--（有効）
       AND   xcasv.cust_acct_site_status    =  :gv_status_A--（有効）
       AND   xcasv.cust_site_uses_status    =  :gv_status_A--（有効）
       AND   xottv.start_date_active        <= NVL(:id_schedule_ship_date,xoha.schedule_ship_date)
       AND  (xottv.end_date_active          IS NULL
       OR    xottv.end_date_active          >= NVL(:id_schedule_ship_date,xoha.schedule_ship_date)) '  ;
--
     cv_union                       CONSTANT VARCHAR2(32000) :=
     ' UNION '
     ;
    cv_main_sql4                    CONSTANT VARCHAR2(32000) :=
     '   -- 配送LT（倉庫・拠点）で取得
         SELECT
           xoha.tightening_program_id tightening_program_id
                                         -- 受注タイプID - 受注ヘッダアドオン.締めコンカレントID
         , xoha.order_type_id         order_type_id
                                         -- 受注タイプID - 受注ヘッダアドオン.受注タイプID
         , CASE xottv.transaction_type_id -- 受注タイプ
             WHEN :ln_transaction_type_id THEN
                  -- 引取変更
                  xdl.receipt_change_lead_time_day  -- 引き取り変更LT（倉庫・拠点）
             ELSE
                  -- 引取変更以外
              DECODE(xoha.prod_class,:cv_prod_class_2,  -- ドリンク生産物流LT
                     xdl.drink_lead_time_day     --ドリンク生産物流LT（倉庫・拠点）
                                     ,:cv_prod_class_1,  -- リーフ生産物流LT
                      xdl.leaf_lead_time_day       -- リーフ生産物流LT（倉庫・拠点）
                     )
           END                        lead_time_day -- リードタイム
         , xoha.schedule_ship_date    schedule_ship_date
                                                        -- 出庫日 - 受注ヘッダアドオン.出荷予定日
         , xoha.schedule_arrival_date schedule_arrival_date
                                                        -- 着日 - 受注ヘッダアドオン.着荷予定日
         , xoha.deliver_to            deliver_to
                                                        -- 配送先コード - 受注ヘッダアドオン.出荷先
         , xoha.deliver_from          deliver_from
                                        -- 出荷元保管場所コード - 受注ヘッダアドオン.出荷元保管場所
         , xoha.prod_class            prod_class
                                                        -- 商品区分 - 受注ヘッダアドオン.商品区分
         , xoha.request_no            request_no
                                                        -- 依頼No - 受注ヘッダアドオン.依頼No
         , xoha.order_header_id       order_header_id   -- 受注ヘッダアドオンID
         FROM
           xxwsh_oe_transaction_types2_v xottv    --①受注タイプ情報VIEW2
          ,xxwsh_order_headers_all       xoha     --②受注ヘッダアドオン
          ,xxcmn_cust_accounts2_v        xcav
          ,(SELECT DISTINCT
                lt.code_class1                  code_class1,
                                                              --コード区分1（倉庫・拠点）
                lt.entering_despatching_code1   entering_despatching_code1,
                                                              --入出庫場所コード１（倉庫・拠点）
                lt.code_class2                  code_class2,
                                                              --コード区分2（倉庫・拠点）
                lt.entering_despatching_code2   entering_despatching_code2,
                                                              --入出庫場所コード2（倉庫・拠点）
                lt.drink_lead_time_day          drink_lead_time_day,
                                                              --ドリンク生産物流LT（倉庫・拠点）
                lt.leaf_lead_time_day           leaf_lead_time_day,
                                                              --リーフ生産物流LT（倉庫・拠点）
                lt.receipt_change_lead_time_day receipt_change_lead_time_day,
                                                              --引き取り変更LT（倉庫・拠点）
                lt.lt_start_date_active         lt_start_date_active,
                lt.lt_end_date_active           lt_end_date_active
           FROM
                 xxcmn_delivery_lt2_v          lt    --配送L/Tアドオンマスタ（倉庫・拠点）
           WHERE lt.code_class1                   = :cv_code_class_4 --コード区分1：倉庫
           AND   lt.code_class2                   = :cv_code_class_1 --コード区分2：拠点
         )                           xdl    --配送L/Tアドオンマスタ（倉庫・拠点）
       ';
    cv_main_sql5                   CONSTANT VARCHAR2(32000) :=
     ' AND   xcav.party_number            = xoha.head_sales_branch
                   -- パーティマスタ(管轄拠点)．組織番号＝受注ヘッダアドオン．管轄拠点かつ
       AND   xcav.start_date_active       <= NVL(xoha.shipped_date,xoha.schedule_ship_date)
                   -- パーティアドオンマスタ(管轄拠点)．適用開始日≦パラメータ. 出庫日かつ
       AND   xcav.end_date_active         >= NVL(xoha.shipped_date,xoha.schedule_ship_date)
                                -- パーティアドオンマスタ.適用終了日≧パラメータ. 出庫日かつ
       AND   xcav.customer_class_code     = :cv_customer_class_code_1
                                -- 顧客マスタ．顧客区分=1かつ
       AND  ((1 = :ln_drink_base_category_flg)
                                    -- フラグが0ならドリンク拠点カテゴリを条件に追加する
              OR (xcav.drink_base_category         = :iv_sales_base_category))
                                -- 顧客マスタ．ドリンク拠点カテゴリ＝パラメータ．拠点カテゴリ
       AND  ((1 = :ln_leaf_base_category_flg)
                                    -- フラグが0ならリーフ拠点カテゴリを条件に追加する
              OR (xcav.leaf_base_category = :iv_sales_base_category))
                                -- 顧客マスタ．リーフ拠点カテゴリ＝パラメータ．拠点カテゴリ
       AND   xdl.entering_despatching_code1  = xoha.deliver_from
                                                           -- 受注ヘッダアドオン.出荷元保管場所
       AND   xdl.entering_despatching_code2  = xoha.head_sales_branch
                                                           -- 受注ヘッダアドオン.拠点
       ';
     cv_main_sql6                   CONSTANT VARCHAR2(32000) :=
     ' AND   xcav.account_status            =  :gv_status_A--（有効）
       AND   xottv.start_date_active        <= NVL(:id_schedule_ship_date,xoha.schedule_ship_date)
       AND  (xottv.end_date_active          IS NULL
       OR    xottv.end_date_active          >= NVL(:id_schedule_ship_date,xoha.schedule_ship_date))
          ---------------------------------------------------------------------------------------------
          -- 配送L/Tアドオン（配送先で登録されていないこと）
          ---------------------------------------------------------------------------------------------
       AND NOT EXISTS ( SELECT  1
                        FROM    xxcmn_delivery_lt2_v  xdl2v       -- 配送L/Tアドオン
                        WHERE   xdl2v.code_class1                 = :cv_deliver_from_4
                        AND     xdl2v.entering_despatching_code1  = xoha.deliver_from
                        AND     xdl2v.code_class2                 = :cv_deliver_to_9
                        AND     xdl2v.entering_despatching_code2  = xoha.deliver_to
                        AND     NVL(xoha.shipped_date,xoha.schedule_ship_date) BETWEEN xdl2v.lt_start_date_active 
                        AND NVL( xdl2v.lt_end_date_active, NVL(xoha.shipped_date,xoha.schedule_ship_date) )
                     )
        )';
/** 
           cv_main_sql3                   CONSTANT VARCHAR2(32000) :=
     ' AND   xcav.party_number            = xoha.head_sales_branch
                   -- パーティマスタ(管轄拠点)．組織番号＝受注ヘッダアドオン．管轄拠点かつ
       AND   xcav.start_date_active       <= NVL(xoha.shipped_date,xoha.schedule_ship_date)
                   -- パーティアドオンマスタ(管轄拠点)．適用開始日≦パラメータ. 出庫日かつ
       AND   xcav.end_date_active         >= NVL(xoha.shipped_date,xoha.schedule_ship_date)
                                -- パーティアドオンマスタ.適用終了日≧パラメータ. 出庫日かつ
       AND   xcav.customer_class_code     = :cv_customer_class_code_1
                                -- 顧客マスタ．顧客区分=1かつ
       AND  ((1 = :ln_drink_base_category_flg)
                                    -- フラグが0ならドリンク拠点カテゴリを条件に追加する
              OR (xcav.drink_base_category         = :iv_sales_base_category))
                                -- 顧客マスタ．ドリンク拠点カテゴリ＝パラメータ．拠点カテゴリ
       AND  ((1 = :ln_leaf_base_category_flg)
                                    -- フラグが0ならリーフ拠点カテゴリを条件に追加する
              OR (xcav.leaf_base_category = :iv_sales_base_category))
                                -- 顧客マスタ．リーフ拠点カテゴリ＝パラメータ．拠点カテゴリ
       AND   xdl.lt2_entering_despatching_code1  = xoha.deliver_from
                                                           -- 受注ヘッダアドオン.出荷元保管場所
       AND  (xdl.lt1_entering_despatching_code2  IS NULL
         OR  xdl.lt1_entering_despatching_code2  = xoha.deliver_to)
                                                           -- 受注ヘッダアドオン.出荷先
       AND   xdl.lt2_entering_despatching_code2  = xoha.head_sales_branch
                                                           -- 受注ヘッダアドオン.管轄拠点
                                                           -- 受注ヘッダアドオン.出荷予定日
       AND  (xdl.lt1_start_date_active           IS NULL
         OR  xdl.lt1_start_date_active           <= xoha.schedule_ship_date)
                                                           -- 受注ヘッダアドオン.出荷予定日
       AND  (xdl.lt1_end_date_active             IS NULL
         OR  xdl.lt1_end_date_active             >= xoha.schedule_ship_date)
                                                           -- 受注ヘッダアドオン.出荷予定日
       AND   xdl.lt2_start_date_active           <= xoha.schedule_ship_date
                                                           -- 受注ヘッダアドオン.出荷予定日
       AND  (xdl.lt2_end_date_active             IS NULL
         OR  xdl.lt2_end_date_active             >= xoha.schedule_ship_date)
                                                           -- 受注ヘッダアドオン.出荷予定日
       AND   xdl.xcav_start_date_active          <= xoha.schedule_ship_date
                                                           -- 受注ヘッダアドオン.出荷予定日
       AND  (xdl.xcav_end_date_active            IS NULL
         OR  xdl.xcav_end_date_active            >= xoha.schedule_ship_date)
                                                           -- 受注ヘッダアドオン.出荷予定日
       AND   xdl.xcasv_start_date_active         <= xoha.schedule_ship_date
                                                           -- 受注ヘッダアドオン.出荷予定日
       AND  (xdl.xcasv_end_date_active           IS NULL
         OR  xdl.xcasv_end_date_active           >= xoha.schedule_ship_date)'
       ;                                                   -- 受注ヘッダアドオン.出荷予定日
--
     cv_lead_time_w1                   CONSTANT VARCHAR2(32000)
     :=    ' AND  NVL(xdl.lt1_rcpt_cng_lead_time_day
                     ,xdl.lt2_rcpt_cng_lead_time_day) =  :in_lead_time_day';
                                     -- 引き取り変更LT（倉庫・配送先）
                                     -- 引き取り変更LT（倉庫・拠点）
--
     cv_lead_time_w2                   CONSTANT VARCHAR2(32000)
     :=    ' AND  NVL(xdl.lt1_drink_lead_time_day
                    , xdl.lt2_drink_lead_time_day) =  :in_lead_time_day';
                                     --ドリンク生産物流LT（倉庫・配送先）
                                     --ドリンク生産物流LT（倉庫・拠点）
--
     cv_lead_time_w3                   CONSTANT VARCHAR2(32000)
     :=    ' AND  NVL(xdl.lt1_leaf_lead_time_day
                    , xdl.lt2_leaf_lead_time_day) =  :in_lead_time_day';
                                     -- リーフ生産物流LT（倉庫・配送先
                                     -- リーフ生産物流LT（倉庫・拠点）
--
    cv_main_sql4                   CONSTANT VARCHAR2(32000) :=
     ' AND   xoha.deliver_to_id             =  xcasv2.party_site_id
       AND   xcasv2.party_id                =  xcav2.party_id
       AND   xcav2.start_date_active        <= NVL(:id_schedule_ship_date,xoha.schedule_ship_date)
       AND   xcav2.end_date_active          >= NVL(:id_schedule_ship_date,xoha.schedule_ship_date)
       AND   xcasv2.start_date_active       <= NVL(:id_schedule_ship_date,xoha.schedule_ship_date)
       AND   xcasv2.end_date_active         >= NVL(:id_schedule_ship_date,xoha.schedule_ship_date)
       AND   xcav.account_status            =  :gv_status_A--（有効）
       AND   xcav2.account_status           =  :gv_status_A--（有効）
       AND   xcasv2.cust_acct_site_status   =  :gv_status_A--（有効）
       AND   xcasv2.cust_site_uses_status   =  :gv_status_A--（有効）
       AND   xottv.start_date_active        <= NVL(:id_schedule_ship_date,xoha.schedule_ship_date)
       AND  (xottv.end_date_active          IS NULL
       OR    xottv.end_date_active          >= NVL(:id_schedule_ship_date,xoha.schedule_ship_date))
--2008/12/07 D.Sugahara Mod Start
         FOR UPDATE OF xoha.req_status SKIP LOCKED '
--       FOR UPDATE OF xoha.req_status NOWAIT'
--2008/12/07 D.Sugahara Mod End
      ;
**/
-- 2008/12/17 mod end ver1.13 M_Uehara
--
    -- *** ローカル・カーソル ***
--
    TYPE ref_cursor   IS REF CURSOR ;             -- 初回締め用
    upd_status_cur     ref_cursor ;
--
    TYPE reref_cursor   IS REF CURSOR ;           -- 再締め用
    reupd_status_cur     reref_cursor ;
    -- *** ローカル・レコード ***
--
--
    TYPE ret_value  IS RECORD
      (
        tightening_program_id          xxwsh_order_headers_all.tightening_program_id%TYPE  -- 締めコンカレントID
       ,order_type_id                  xxwsh_order_headers_all.order_type_id%TYPE          -- 受注タイプID
       ,lead_time_day                  NUMBER                                              -- 引取変更LT
       ,schedule_ship_date             xxwsh_order_headers_all.schedule_ship_date%TYPE     -- 出荷予定日
       ,schedule_arrival_date          xxwsh_order_headers_all.schedule_ship_date%TYPE     -- 着荷予定日
       ,deliver_to                     xxwsh_order_headers_all.deliver_to%TYPE             -- 出荷先
       ,deliver_from                   xxwsh_order_headers_all.deliver_from%TYPE           -- 出荷元保管場所
       ,prod_class                     xxwsh_order_headers_all.prod_class%TYPE             -- 商品区分
       ,request_no                     xxwsh_order_headers_all.request_no%TYPE             -- 依頼No
       ,order_header_id                xxwsh_order_headers_all.order_header_id%TYPE        -- 受注ヘッダアドオンID
      );
    lr_u_rec    ret_value ;
--
    -- ===============================
    -- ユーザー定義例外
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
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
--
    -- 初期化
    gv_callfrom_flg := iv_callfrom_flg;
    lv_err_message := NULL;
    lv_retcode := '0';
    ln_stschk_error_flg := 0;            -- 2008/12/17 Add V1.13
--
    -- 共通更新情報の取得
    gn_user_id         := FND_GLOBAL.USER_ID;        -- ログインしているユーザーのID取得
    gn_login_id        := FND_GLOBAL.LOGIN_ID;       -- 最終更新ログイン
    gn_conc_request_id := FND_GLOBAL.CONC_REQUEST_ID;-- 要求ID
    gn_prog_appl_id    := FND_GLOBAL.PROG_APPL_ID;   -- ｺﾝｶﾚﾝﾄ・ﾌﾟﾛｸﾞﾗﾑ・ｱﾌﾟﾘｹｰｼｮﾝID
    gn_conc_program_id := FND_GLOBAL.CONC_PROGRAM_ID;-- コンカレント・プログラムID
--
--
    -- グローバル変数の初期化
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    gn_warn_cnt   := 0;
--
    -- **************************************************
    -- *** パラメータチェック(E-1)
    -- **************************************************
--
--  必須チェック
--
    -- 「締めステータスチェック区分」チェック
    IF (iv_tightening_status_chk_class IS NULL) THEN
      -- 締めステータスチェック区分のNULLチェックを行います
      lv_err_message := lv_err_message ||
      xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
                               gv_cnst_msg_null,
                               gv_cnst_tkn_para,
                               gv_msg_null_06) || gv_line_feed;
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
--  妥当性チェック
--
    -- 「締め処理区分」チェック
    IF ((NVL(iv_tighten_class,cv_tighten_class_1) <> cv_tighten_class_1)
    AND (NVL(iv_tighten_class,cv_tighten_class_1) <> cv_tighten_class_2)) THEN
      -- 締め処理区分に1:初回、2:再以外のチェックを行います
      lv_err_message := lv_err_message ||
      xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
                               gv_cnst_msg_prop,
                               gv_cnst_tkn_para,
                               gv_msg_null_02) || gv_line_feed;
    END IF;
--
    -- 「締めステータスチェック区分」チェック
    IF ((iv_tightening_status_chk_class <> cv_tightening_status_chk_cla_1)
    AND (iv_tightening_status_chk_class <> cv_tightening_status_chk_cla_2)) THEN
      -- 締めステータスチェック区分に1、2以外のチェックを行います
      lv_err_message := lv_err_message ||
      xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
                               gv_cnst_msg_prop,
                               gv_cnst_tkn_para,
                               gv_msg_null_06) || gv_line_feed;
    END IF;
--
    -- 呼出元フラグが画面の場合、基準レコード区分：'Z'を登録する。
    IF (iv_callfrom_flg = cv_callfrom_flg_2) THEN
      gv_base_record_class := cv_base_record_class_Z;
    END IF;
    -- 「基準レコード区分」が登録されている場合
    IF (iv_base_record_class IS NOT NULL) THEN
      -- 「基準レコード区分」チェック
      IF ((iv_base_record_class <> cv_base_record_class_Y)
      AND (iv_base_record_class <> cv_base_record_class_N)
      AND (iv_base_record_class <> cv_base_record_class_Z)) THEN
        -- 基準レコード区分のNULLチェックを行います
        lv_err_message := lv_err_message ||
        xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
                                 gv_cnst_msg_prop,
                                 gv_cnst_tkn_para,
                                 gv_msg_null_01) || gv_line_feed;
      ELSE
        --グローバル変数に基準レコード区分をセット
        gv_base_record_class := iv_base_record_class;
      END IF;
    END IF;
--
    -- 「出庫日」が登録されている場合
    IF (id_schedule_ship_date IS NOT NULL) THEN
      -- 「出庫日」形式チェック
      IF (gn_status_error
          = xxcmn_common_pkg.check_param_date_yyyymmdd(id_schedule_ship_date)) THEN
        -- 出庫日がYYYY/MM/DDでない場合、エラーを返す
        lv_err_message := lv_err_message ||
        xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
                                 gv_cnst_msg_fomt,
                                 'DATE',
                                 gv_msg_null_08) || gv_line_feed;
      END IF;
    END IF;
--
    -- 「呼出元フラグ」チェック
    IF ((iv_callfrom_flg <> cv_callfrom_flg_1)
    AND (iv_callfrom_flg <> cv_callfrom_flg_2)) THEN
      -- 呼出元フラグのNULLチェックを行います
      lv_err_message := lv_err_message ||
      xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
                               gv_cnst_msg_prop,
                               gv_cnst_tkn_para,
                               gv_msg_null_03) || gv_line_feed;
    END IF;
--
    -- 「呼出元フラグ」「依頼No」妥当チェック
    IF ((iv_callfrom_flg = cv_callfrom_flg_2)
    AND (iv_request_no IS NULL)) THEN
      -- 呼出元フラグが2:画面の時、依頼NoのNULLチェックを行います
      lv_err_message := lv_err_message ||
      xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
                               gv_cnst_msg_null,
                               gv_cnst_tkn_para,
                               gv_msg_null_05) || gv_line_feed;
    END IF;
--
--
    IF (NVL(iv_tighten_class,cv_tighten_class_1) = cv_tighten_class_1)
    AND (iv_callfrom_flg = cv_callfrom_flg_1) THEN
      -- 締め処理区分に1:初回の場合かつ呼出元区分が1：コンカレントの場合チェックを行います
--
      -- 「出庫形態ID」「商品区分」チェック
      IF ((in_order_type_id IS NULL)
      AND (iv_prod_class = cv_prod_class_1)) THEN
        -- 出庫形態IDが未入力の場合かつ
        -- パラメータ.商品区分がリーフの場合
        lv_err_message := lv_err_message ||
        xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
                                 gv_cnst_msg_null,
                                 gv_cnst_tkn_para,
                                 gv_msg_null_07) || gv_line_feed;
      END IF;
--
      -- 内部処理用の変数「拠点カテゴリ」を設定
      -- 入力パラメータ「拠点カテゴリ」が'0'ALLの場合、文字列'ALL'をセット
      IF (iv_sales_base_category = gv_sales_base_category_0) THEN
        gv_sales_base_category := gv_ALL;
      -- 入力パラメータ「拠点カテゴリ」が'0'ALL場合、入力パラメータ「拠点カテゴリ」をセット
      ELSE
        gv_sales_base_category := iv_sales_base_category;
      END IF;
--
      -- 「生産物流LT」チェック
      IF (in_lead_time_day IS NULL) THEN
        -- パラメータ生産物流LTが未入力の場合
        lv_err_message := lv_err_message ||
        xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
                                 gv_cnst_msg_null,
                                 gv_cnst_tkn_para,
                                 gv_msg_null_10) || gv_line_feed;
      END IF;
--
    ELSIF (NVL(iv_tighten_class,cv_tighten_class_1) = cv_tighten_class_2) THEN
      -- 締め処理区分に2:再締めの場合チェックを行います
--
      -- 「締めコンカレントID」チェック
      IF (in_tightening_program_id IS NULL) THEN
        -- パラメータ締めコンカレントIDが未入力の場合
        lv_err_message := lv_err_message ||
        xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
                                 gv_cnst_msg_null,
                                 gv_cnst_tkn_para,
                                 gv_msg_null_11) || gv_line_feed;
      END IF;
--
      -- 「出庫形態ID」「商品区分」チェック
      IF ((in_order_type_id IS NULL)
      AND (iv_prod_class = cv_prod_class_1)) THEN
        -- 出庫形態IDが未入力の場合かつ
        -- パラメータ.商品区分がリーフの場合
        lv_err_message := lv_err_message ||
        xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
                                 gv_cnst_msg_null,
                                 gv_cnst_tkn_para,
                                 gv_msg_null_07) || gv_line_feed;
      END IF;
--
    END IF;
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
    -- パラメータ.出庫形態ID NULLチェック
    IF  (in_order_type_id IS NULL) THEN
      -- 出庫形態IDがNULLの場合
      ln_order_type_id_nullflg := 1;
    ELSE
      ln_order_type_id_nullflg := 0;
    END IF;
--
    -- パラメータ.出庫元 NULLチェック
    IF  (iv_deliver_from IS NULL) THEN
      -- 出庫元がNULLの場合
      ln_deliver_from_nullflg := 1;
    ELSE
      ln_deliver_from_nullflg := 0;
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
    -- パラメータ.商品区分
    IF (iv_prod_class IS NULL) THEN
      -- 商品区分がNULLの場合
      ln_prod_class_nullflg := 1;
    ELSE
      ln_prod_class_nullflg := 0;
    END IF;
--
    -- パラメータ.商品区分
    IF  ((iv_prod_class IS NULL)
    OR   (iv_prod_class <> cv_prod_class_2)
    OR  (gv_sales_base_category IS NULL)
    OR  (gv_sales_base_category = gv_ALL)) THEN
      -- 商品区分がNULLまたは2以外、または拠点カテゴリがNULLまたは'ALL'の場合
      ln_drink_base_category_flg := 1;
    ELSE
      ln_drink_base_category_flg := 0;
    END IF;
--
    -- パラメータ.商品区分
    IF ((iv_prod_class IS NULL)
    OR  (iv_prod_class <> cv_prod_class_1)
    OR  (gv_sales_base_category IS NULL)
    OR  (gv_sales_base_category = gv_ALL)) THEN
      -- 商品区分がNULLまたは2以外、または拠点カテゴリがNULLまたは'ALL'の場合
      ln_leaf_base_category_flg := 1;
    ELSE
      ln_leaf_base_category_flg := 0;
    END IF;
--
    -- パラメータ.締めコンカレントID
    IF (in_tightening_program_id IS NULL) THEN
      -- 締めコンカレントIDがNULLの場合
      ln_tightening_prog_id_nullflg := 1;
    ELSE
      ln_tightening_prog_id_nullflg := 0;
    END IF;
--
--
    ld_sysdate := TRUNC(SYSDATE); -- システム日付の取得
--
    IF (id_schedule_ship_date IS NULL) THEN
      -- システム日付をセット
      ld_schedule_ship_date := ld_sysdate;
    ELSE
      -- 出庫日をセット
      ld_schedule_ship_date := id_schedule_ship_date;
    END IF;
--
    -- ===============================
    -- 関連データ取得
    -- ===============================
    init_proc(
      id_schedule_ship_date,          -- 出庫日
      ln_transaction_type_id,         -- タイプID
      lv_errbuf,                      -- エラー・メッセージ           --# 固定 #
      lv_retcode,                     -- リターン・コード             --# 固定 #
      lv_errmsg);                     -- ユーザー・エラー・メッセージ --# 固定 #
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_api_expt;
    END IF;
--
    -- タイプID = 出庫形態ID
    IF (ln_transaction_type_id = in_order_type_id) THEN
      -- 引取変更
      lv_lead_time_w := cv_lead_time_w1;
    ELSE
      -- 引取変更以外
--
      IF (cv_prod_class_2 = iv_prod_class) THEN
        -- ドリンク生産物流LT
        lv_lead_time_w := cv_lead_time_w2;
      ELSIF (cv_prod_class_1 = iv_prod_class) THEN
        -- リーフ生産物流LT
        lv_lead_time_w := cv_lead_time_w3;
      END IF;
    END IF;
--
    IF (iv_instruction_dept IS NULL) THEN
      -- パラメータ部署が未入力の場合、指示部署取得処理
      get_party_number(ld_schedule_ship_date, -- 出庫日またはシステム日付
                       gv_party_number,       -- 組織番号
                       lv_user_name,          -- ユーザー名
                       lv_retcode,            -- リターンコード
                       lv_errbuf,             -- エラーメッセージコード
                       lv_errmsg);            -- エラーメッセージ
--
      -- リターン・コードにエラーが返された場合はエラー
     IF ((lv_retcode = gn_status_error)
     OR  (gv_party_number IS NULL)) THEN
       -- ログインユーザ指示部署がNULLまたは対象データ無しの場合
       lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
                                             gv_cnst_msg_208,
                                             'USER_NAME',
                                             lv_user_name);
       RAISE global_api_expt;
     END IF;
--
   ELSE
     gv_party_number := iv_instruction_dept;
   END IF;
--
--  更新用PL/SQL表初期化
    gt_header_id_upd_tab.DELETE; -- 受注ヘッダアドオンID
--
    -- **************************************************
    -- *** 出荷依頼情報取得(E-2)
    -- **************************************************
    -- 呼出元フラグが2:画面の場合
    IF (iv_callfrom_flg = cv_callfrom_flg_2) THEN
      lv_sql :=    cv_main_sql;
      -- SQLの実行
      OPEN upd_status_cur FOR lv_sql
        USING
          iv_request_no;
    -- 呼出元フラグが1:コンカレントの場合
    ELSIF (iv_callfrom_flg = cv_callfrom_flg_1) THEN
      IF (NVL(iv_tighten_class,cv_tighten_class_1) = cv_tighten_class_1) THEN
        -- 初回カーソルオープン
--
-- 2008/12/17 mod start ver1.13 M_Uehara
        -- 動的SQL本文を決める
        lv_sql :=   cv_main_sql1
                 || cv_where
                 || cv_main_sql2
                 || lv_lead_time_w
                 || cv_main_sql3
                 || cv_union
                 || cv_main_sql4
                 || cv_where
                 || cv_main_sql5
                 || lv_lead_time_w
                 || cv_main_sql6;
--
        -- SQLの実行
        OPEN upd_status_cur FOR lv_sql
          USING
            ln_transaction_type_id,
            cv_prod_class_2,
            cv_prod_class_1,
            cv_code_class_4,
            cv_code_class_9,
            cv_order_category_code,
            cv_shipping_shikyu_class,
            gv_status_02,
            ln_order_type_id_nullflg,
            in_order_type_id,
            ln_deliver_from_nullflg,
            iv_deliver_from,
            ln_request_no_nullflg,
            iv_request_no,
            ln_schedule_ship_date_nullflg,
            id_schedule_ship_date,
            ln_prod_class_nullflg,
            iv_prod_class,
            cv_customer_class_code_1,
            ln_drink_base_category_flg,
            iv_sales_base_category,
            ln_leaf_base_category_flg,
            iv_sales_base_category,
            in_lead_time_day,
            gv_status_A,
            gv_status_A,
            gv_status_A,
            id_schedule_ship_date,
            id_schedule_ship_date,
            ln_transaction_type_id,
            cv_prod_class_2,
            cv_prod_class_1,
            cv_code_class_4,
            cv_code_class_1,
            cv_order_category_code,
            cv_shipping_shikyu_class,
            gv_status_02,
            ln_order_type_id_nullflg,
            in_order_type_id,
            ln_deliver_from_nullflg,
            iv_deliver_from,
            ln_request_no_nullflg,
            iv_request_no,
            ln_schedule_ship_date_nullflg,
            id_schedule_ship_date,
            ln_prod_class_nullflg,
            iv_prod_class,
            cv_customer_class_code_1,
            ln_drink_base_category_flg,
            iv_sales_base_category,
            ln_leaf_base_category_flg,
            iv_sales_base_category,
            in_lead_time_day,
            gv_status_A,
            id_schedule_ship_date,
            id_schedule_ship_date,
            cv_deliver_from_4,
            cv_deliver_to_9
            ;
--
      ELSE
        -- 再締めカーソルオープン
--
        -- 動的SQL本文を決める
        lv_sql :=   cv_main_sql1
                 || cv_retable
                 || cv_rewhere
                 || cv_main_sql2
-- 2008/12/23 addd start ver1.14 M_Uehara
                 || lv_lead_time_w
-- 2008/12/23 addd end ver1.14 M_Uehara
                 || cv_main_sql3
                 || cv_union
                 || cv_main_sql4
                 || cv_retable
                 || cv_rewhere
                 || cv_main_sql5
-- 2008/12/23 addd start ver1.14 M_Uehara
                 || lv_lead_time_w
-- 2008/12/23 addd end ver1.14 M_Uehara
                 || cv_main_sql6;
--
        -- SQLの実行
        OPEN reupd_status_cur FOR lv_sql
          USING
            ln_transaction_type_id,
            cv_prod_class_2,
            cv_prod_class_1,
            cv_code_class_4,
            cv_code_class_9,
            cv_order_category_code,
            cv_shipping_shikyu_class,
            gv_status_02,
            ln_tightening_prog_id_nullflg,
            in_tightening_program_id,
            gn_m999,
            gn_m999,
            gv_ALL,
            gv_ALL,
            gv_ALL,
            gv_ALL,
            gv_ALL,
            gv_ALL,
            cv_prod_class_2,
            cv_prod_class_1,
            cv_customer_class_code_1,
            ln_drink_base_category_flg,
            iv_sales_base_category,
            ln_leaf_base_category_flg,
            iv_sales_base_category,
-- 2008/12/23 addd start ver1.14 M_Uehara
            in_lead_time_day,
-- 2008/12/23 addd end ver1.14 M_Uehara
            gv_status_A,
            gv_status_A,
            gv_status_A,
            id_schedule_ship_date,
            id_schedule_ship_date,
            ln_transaction_type_id,
            cv_prod_class_2,
            cv_prod_class_1,
            cv_code_class_4,
            cv_code_class_1,
            cv_order_category_code,
            cv_shipping_shikyu_class,
            gv_status_02,
            ln_tightening_prog_id_nullflg,
            in_tightening_program_id,
            gn_m999,
            gn_m999,
            gv_ALL,
            gv_ALL,
            gv_ALL,
            gv_ALL,
            gv_ALL,
            gv_ALL,
            cv_prod_class_2,
            cv_prod_class_1,
            cv_customer_class_code_1,
            ln_drink_base_category_flg,
            iv_sales_base_category,
            ln_leaf_base_category_flg,
            iv_sales_base_category,
-- 2008/12/23 addd start ver1.14 M_Uehara
            in_lead_time_day,
-- 2008/12/23 addd end ver1.14 M_Uehara
            gv_status_A,
            id_schedule_ship_date,
            id_schedule_ship_date,
            cv_deliver_from_4,
            cv_deliver_to_9
            ;
--
/**
        -- 動的SQL本文を決める
        lv_sql :=   cv_main_sql1
                 || cv_main_sql2
                 || cv_where
                 || cv_main_sql3
                 || lv_lead_time_w
                 || cv_main_sql4;
--
        -- SQLの実行
        OPEN upd_status_cur FOR lv_sql
          USING
            ln_transaction_type_id,
            cv_prod_class_2,
            cv_prod_class_1,
            cv_code_class_4,
            cv_code_class_1,
            cv_code_class_9,
            cv_order_category_code,
            cv_shipping_shikyu_class,
            gv_status_02,
            ln_order_type_id_nullflg,
            in_order_type_id,
            ln_deliver_from_nullflg,
            iv_deliver_from,
            ln_request_no_nullflg,
            iv_request_no,
            ln_schedule_ship_date_nullflg,
            id_schedule_ship_date,
            ln_prod_class_nullflg,
            iv_prod_class,
            cv_customer_class_code_1,
            ln_drink_base_category_flg,
            iv_sales_base_category,
            ln_leaf_base_category_flg,
            iv_sales_base_category,
            in_lead_time_day,
            id_schedule_ship_date,
            id_schedule_ship_date,
            id_schedule_ship_date,
            id_schedule_ship_date,
            gv_status_A,
            gv_status_A,
            gv_status_A,
            gv_status_A,
            id_schedule_ship_date,
            id_schedule_ship_date
            ;
--
      ELSE
        -- 再締めカーソルオープン
--
        -- 動的SQL本文を決める
        lv_sql :=   cv_main_sql1
                 || cv_retable
                 || cv_main_sql2
                 || cv_rewhere
                 || cv_main_sql3
                 || cv_main_sql4;
--
        -- SQLの実行
        OPEN reupd_status_cur FOR lv_sql
          USING
-- 1.6 UPD START
--            cv_order_type_id_04,
            ln_transaction_type_id,
-- 1.6 UPD END
            cv_prod_class_2,
            cv_prod_class_1,
            cv_code_class_4,
            cv_code_class_1,
            cv_code_class_9,
            cv_order_category_code,
            cv_shipping_shikyu_class,
            gv_status_02,
            ln_tightening_prog_id_nullflg,
            in_tightening_program_id,
            gn_m999,
            gn_m999,
            gv_ALL,
            gv_ALL,
            gv_ALL,
            gv_ALL,
            gv_ALL,
            gv_ALL,
            cv_prod_class_2,
            cv_prod_class_1,
            cv_customer_class_code_1,
            ln_drink_base_category_flg,
            iv_sales_base_category,
            ln_leaf_base_category_flg,
            iv_sales_base_category,
            id_schedule_ship_date,
            id_schedule_ship_date,
            id_schedule_ship_date,
            id_schedule_ship_date,
            gv_status_A,
            gv_status_A,
            gv_status_A,
            gv_status_A,
            id_schedule_ship_date,
            id_schedule_ship_date
            ;
**/
-- 2008/12/17 mod end ver1.13 M_Uehara
--
      END IF;
    END IF;
--
    -- ========================================
    -- データのチェックを行う
    -- ========================================
    <<data_loop>>
    LOOP
--
      -- レコード読込
      IF (NVL(iv_tighten_class,cv_tighten_class_1) = cv_tighten_class_1) THEN
        FETCH upd_status_cur INTO lr_u_rec;
        EXIT WHEN upd_status_cur%NOTFOUND;
      ELSE
        FETCH reupd_status_cur INTO lr_u_rec;
        EXIT WHEN reupd_status_cur%NOTFOUND;
      END IF;
--
      -- 2008/12/17 本番障害#81 Add Start ----------------
      ln_lock_error_flg := 0;
      BEGIN
        SELECT xoha.order_header_id
        INTO   ln_order_header_id_lock
        FROM   xxwsh_order_headers_all xoha
        WHERE  xoha.order_header_id = lr_u_rec.order_header_id
        FOR UPDATE NOWAIT;
      EXCEPTION
        WHEN OTHERS THEN
          ln_lock_error_flg := 1;
      END;
--
      IF (ln_lock_error_flg = 0) THEN
      -- 2008/12/17 本番障害#81 Add End ----------------
--
        ln_target_cnt := ln_target_cnt + 1;   --2008/08/05 Add
--
        -- 処理件数をカウント
        IF (ln_bfr_order_header_id <> lr_u_rec.order_header_id) THEN
          --ln_target_cnt := ln_target_cnt + 1;   --2008/08/05 Del
          ln_bfr_order_header_id := lr_u_rec.order_header_id;
        END IF;
--
        ln_data_cnt := ln_data_cnt + 1;
--
        IF (iv_tightening_status_chk_class = cv_tightening_status_chk_cla_1) THEN
          -- 締めステータスチェック区分が1:チェック有りの場合
--
          -- **************************************************
          -- *** 締めステータスチェック(E-3)
          -- **************************************************
--
          lv_status :=
          xxwsh_common_pkg.check_tightening_status(lr_u_rec.order_type_id,  -- E-2受注タイプID
                                                   iv_deliver_from,         -- パラメータ.出荷元
                                                   iv_sales_base,           -- パラメータ.拠点
                                                   iv_sales_base_category,  -- パラメータ.拠点カテゴリ
                                                   lr_u_rec.lead_time_day,  -- E-2生産物流LT
                                                   lr_u_rec.schedule_ship_date,   -- E-2出庫日
                                                   lr_u_rec.prod_class);    -- E-2商品区分
--
          -- 締めステータスが'2'または'4'の場合はエラー
          IF ((lv_status = cv_status_2) OR (lv_status = cv_status_4)) THEN
            -- 2008/12/17 Del Start Ver1.13 -----------------------------------
            --lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
            --                                      gv_cnst_msg_204);
            --RAISE global_api_expt;
            -- 2008/12/17 Del Start Ver1.13 -----------------------------------
            -- 2008/12/17 Add Start Ver1.13 -----------------------------------
            FND_FILE.PUT_LINE(FND_FILE.LOG,
              '締めステータスチェックエラー'                  ||
              '/伝票No:'       || lr_u_rec.request_no         ||
              '/受注タイプID:' || lr_u_rec.order_type_id      ||
              '/出荷元:'       || iv_deliver_from             ||
              '/拠点:'         || iv_sales_base               ||
              '/拠点カテゴリ:' || iv_sales_base_category      ||
              '/生産物流LT:'   || lr_u_rec.lead_time_day      ||
              '/出庫日:'       || lr_u_rec.schedule_ship_date ||
              '/商品区分:'     || lr_u_rec.prod_class);
--
            ln_stschk_error_flg := 1;
            -- 2008/12/17 Add End Ver1.13 -------------------------------------
--
          END IF;
        END IF;
--
        -- 締めステータスチェック区分が0:チェック無しの場合
        IF (iv_callfrom_flg = cv_callfrom_flg_2) THEN
          -- 呼出元フラグ 2:画面の場合はE-4、E-5は行わない
          NULL;
        ELSE
--
          -- **************************************************
          -- *** リードタイムチェック(E-4)
          -- **************************************************
--
          -- 出庫日の稼働日チェック
          ln_retcode := xxwsh_common_pkg.get_oprtn_day(lr_u_rec.schedule_ship_date, -- E-2出庫日
                                                       lr_u_rec.deliver_from, -- E-2出荷元保管場所
                                                       NULL,                  -- 配送先コード
                                                       0,                     -- リードタイム
                                                       lr_u_rec.prod_class,   -- E-2商品区分
                                                       ld_oprtn_day);         -- 稼働日日付
--
          -- リターン・コードにエラーが返された場合はエラー
          IF (ln_retcode = gn_status_error) THEN
            lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
                                                  gv_cnst_msg_205,
                                                  gv_cnst_token_api_name,
                                                  cv_get_oprtn_day_api,
                                                  'ERR_MSG',
                                                  '',
                                                  'REQUEST_NO',
                                                  lr_u_rec.request_no);
            RAISE global_api_expt;
--
          -- 出庫日が稼働日でない場合はエラー
          ELSIF (ld_oprtn_day <> lr_u_rec.schedule_ship_date) THEN
            -- 出力項目の稼働日日付≠入力パラメータで渡した日付
            lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
                                                  gv_cnst_msg_206,
                                                  'IN_DATE',
                                                  TO_CHAR(lr_u_rec.schedule_ship_date,'YYYY/MM/DD'),
                                                  'REQUEST_NO',
                                                  lr_u_rec.request_no);
            RAISE global_api_expt;
          END IF;
--
          -- 着日の稼働日チェック
          ln_retcode := xxwsh_common_pkg.get_oprtn_day(lr_u_rec.schedule_arrival_date, -- E-2着日
                                                       NULL,                  -- 出荷元保管場所
                                                       lr_u_rec.deliver_to,   -- 配送先コード
                                                       0,                     -- リードタイム
                                                       lr_u_rec.prod_class,   -- E-2商品区分
                                                       ld_oprtn_day);         -- 稼働日日付
--
          -- リターン・コードにエラーが返された場合はエラー
          IF (ln_retcode = gn_status_error) THEN
            lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
                                                  gv_cnst_msg_205,
                                                  gv_cnst_token_api_name,
                                                  cv_get_oprtn_day_api,
                                                  'ERR_MSG',
                                                  '',
                                                  'REQUEST_NO',
                                                  lr_u_rec.request_no);
            RAISE global_api_expt;
--
          -- 着日が稼働日でない場合はエラー
          ELSIF (ld_oprtn_day <> lr_u_rec.schedule_arrival_date) THEN
            lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
                                                  gv_cnst_msg_206,
                                                  'IN_DATE',
                                                  TO_CHAR(lr_u_rec.schedule_arrival_date,'YYYY/MM/DD'),
                                                  'REQUEST_NO',
                                                  lr_u_rec.request_no);
  -- 2008/11/14 H.Itou Mod Start 統合テスト指摘650 着荷日が稼働日でない場合、警告（登録は行う。）
  --          RAISE global_api_expt;
            ln_warn_cnt := ln_warn_cnt + 1;
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
            ov_errmsg := gv_msg_warn_01;
  -- 2008/11/14 H.Itou Mod End
          END IF;
--
/* 20081201 D.Sugahara Deleted※暫定 Start --リードタイムエラーを回避するため
          -- リードタイム算出
          xxwsh_common910_pkg.calc_lead_time(cv_deliver_from_4,     -- 4:倉庫
                                             lr_u_rec.deliver_from, -- E-2出荷元保管場所
                                             cv_deliver_to_9,       -- 9:配送先
                                             lr_u_rec.deliver_to,   -- E-2配送先コード
                                             lr_u_rec.prod_class,   -- E-2商品区分
                                             lr_u_rec.order_type_id,-- E-2受注タイプID
                                             lr_u_rec.schedule_ship_date,-- E-2出庫日
                                             lv_retcode,            -- リターンコード
                                             lv_errbuf,             -- エラーメッセージコード
                                             lv_errmsg,             -- エラーメッセージ
                                             ln_lead_time,          -- 生産物流LT／引取変更LT
                                             ln_delivery_lt);       -- 配送LT
--
          -- リターン・コードにエラーが返された場合はエラー
          IF (ln_retcode = gn_status_error) THEN
            lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
                                                  gv_cnst_msg_205,
                                                  gv_cnst_token_api_name,
                                                  cv_calc_lead_time_api,
                                                  'ERR_MSG',
                                                  lv_errmsg,
                                                  'REQUEST_NO',
                                                  lr_u_rec.request_no);
            RAISE global_api_expt;
          END IF;
--
-- 2008/11/14 H.Itou Mod Start 統合テスト指摘650 着荷日 － 配送リードタイムは稼動日を考慮しない。
--        -- リードタイム妥当チェック
--        ln_retcode :=
--        xxwsh_common_pkg.get_oprtn_day(lr_u_rec.schedule_arrival_date, -- E-2着日
--                                       NULL,                           -- 出荷元保管場所
--                                       lr_u_rec.deliver_to,            -- E-2配送先コード
--                                       ln_delivery_lt,                 -- リードタイム
--                                       lr_u_rec.prod_class,            -- E-2商品区分
--                                       ld_oprtn_day);                  -- 稼働日日付
----
--        -- リターン・コードにエラーが返された場合はエラー
--        IF (ln_retcode = gn_status_error) THEN
--          lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
--                                                gv_cnst_msg_205,
--                                                gv_cnst_token_api_name,
--                                                cv_get_oprtn_day_api,
--                                                'ERR_MSG',
--                                                '',
--                                                'REQUEST_NO',
--                                                lr_u_rec.request_no);
--          RAISE global_api_expt;
--        END IF;
          -- 着荷日 － 配送リードタイムを取得
          ld_oprtn_day := lr_u_rec.schedule_arrival_date - ln_delivery_lt;
-- 2008/11/14 H.Itou Mod End
--
          -- E-2出庫日 < 稼働日
          IF (lr_u_rec.schedule_ship_date > ld_oprtn_day) THEN
            -- リードタイムを満たしていない
            lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
                                                  gv_cnst_msg_207,
                                                  'LT_CLASS',
                                                  cv_get_oprtn_day_lt2,
                                                  'REQUEST_NO',
                                                  lr_u_rec.request_no);
            RAISE global_api_expt;
          END IF;
--
          -- リードタイム妥当チェック
          ln_retcode :=
          xxwsh_common_pkg.get_oprtn_day(lr_u_rec.schedule_ship_date,    -- E-2出庫日
                                         NULL,                           -- 出荷元保管場所
                                         lr_u_rec.deliver_to,            -- E-2配送先コード
                                         ln_lead_time,                   -- リードタイム
                                         lr_u_rec.prod_class,            -- E-2商品区分
                                         ld_oprtn_day);                  -- 稼働日日付
--
          -- リターン・コードにエラーが返された場合はエラー
          IF (ln_retcode = gn_status_error) THEN
            lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
                                                  gv_cnst_msg_205,
                                                  gv_cnst_token_api_name,
                                                  cv_get_oprtn_day_api,
                                                  'ERR_MSG',
                                                  '',
                                                  'REQUEST_NO',
                                                  lr_u_rec.request_no);
            RAISE global_api_expt;
          END IF;
--
-- 2008/10/28 H.Itou Mod Start 統合テスト指摘141 生産物流LT／引取変更LTチェックは、当日出荷の場合があるので、稼働日＋1 でチェックを行う。
--        -- システム日付 > 稼働日
--        IF (ld_sysdate > ld_oprtn_day) THEN
          -- システム日付 > 稼働日 + 1
          IF (ld_sysdate > ld_oprtn_day + 1) THEN
-- 2008/10/28 H.Itou Mod End
            -- 配送リードタイムが妥当でない
            lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
                                                  gv_cnst_msg_207,
                                                  'LT_CLASS',
                                                  cv_get_oprtn_day_lt,
                                                  'REQUEST_NO',
                                                  lr_u_rec.request_no);
            RAISE global_api_expt;
          END IF;
  */
--
--20081201 D.Sugahara Deleted※暫定 End --リードタイムエラーを回避するため
--
        END IF;
--
        -- **************************************************
        -- *** PL/SQL表への挿入(E-6)
        -- **************************************************
--
        gt_header_id_upd_tab(ln_data_cnt) := lr_u_rec.order_header_id; -- 受注ヘッダアドオンID
--
-- 2008/08/05 Mod ↓
--      ln_normal_cnt := ln_target_cnt;
        ln_normal_cnt := ln_normal_cnt + 1;
-- 2008/08/05 Mod ↑
--
      END IF;    -- 2008/12/17 本番障害#81 Add
--
    END LOOP data_loop;
--
    IF ( upd_status_cur%ISOPEN ) THEN
      CLOSE upd_status_cur;
    END IF;
    IF ( reupd_status_cur%ISOPEN ) THEN
      CLOSE reupd_status_cur;
    END IF;
--
    -- 2008/12/17 Add Start Ver1.13 --------------------------------
    IF (ln_stschk_error_flg = 1) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,gv_cnst_msg_204);
      RAISE global_api_expt;
    END IF;
    -- 2008/12/17 Add End Ver1.13 -------------------------------------
--
-- 2008/10/10 H.Itou Add Start 締めレコード作成は、対象データなしでも行う。
    -- **************************************************
    -- *** 締め済みレコード登録(E-5)
    -- **************************************************
--
    insert_tightening_control(in_order_type_id,       -- 出庫形態ID
                              iv_deliver_from,        -- 出荷元
                              iv_sales_base,          -- 拠点
                              gv_sales_base_category, -- 拠点カテゴリ
                              in_lead_time_day,       -- 生産物流LT
                              id_schedule_ship_date,  -- 出庫日
                              iv_prod_class,          -- 商品区分
                              gv_base_record_class,   -- 基準レコード区分
                              lv_retcode,             -- リターンコード
                              lv_errbuf,              -- エラーメッセージコード
                              lv_errmsg);             -- エラーメッセージ
--
    -- 締め済みレコード登録処理がエラーの場合
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_api_expt;
    END IF;
-- 2008/10/10 H.Itou Add End
--
    IF ( ln_data_cnt = 0 ) THEN
      -- 出荷依頼情報対象データなし
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
                                            gv_cnst_msg_002);
      -- 警告をセット
      ln_warn_cnt := 1 ;
      ov_errmsg := lv_errmsg;
      ov_errbuf := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
    ELSE
      -- 出荷依頼情報対象データあり
--
      -- Del start 2008/06/27 uehara 呼出元が画面でも締め済みレコードを登録する。
--      IF (iv_callfrom_flg = cv_callfrom_flg_1) THEN
        -- 呼出元フラグ 1:コンカレント
      -- Del end 2008/06/27 uehara
--
-- 2008/10/10 H.Itou Del Start 締めレコード作成は、対象データなしでも行うので、移動
--      -- **************************************************
--      -- *** 締め済みレコード登録(E-5)
--      -- **************************************************
----
--      insert_tightening_control(in_order_type_id,       -- 出庫形態ID
--                                iv_deliver_from,        -- 出荷元
--                                iv_sales_base,          -- 拠点
--                                gv_sales_base_category, -- 拠点カテゴリ
--                                in_lead_time_day,       -- 生産物流LT
--                                id_schedule_ship_date,  -- 出庫日
--                                iv_prod_class,          -- 商品区分
--                                gv_base_record_class,   -- 基準レコード区分
--                                lv_retcode,             -- リターンコード
--                                lv_errbuf,              -- エラーメッセージコード
--                                lv_errmsg);             -- エラーメッセージ
----
--      -- 締め済みレコード登録処理がエラーの場合
--      IF (lv_retcode = gv_status_error) THEN
--        RAISE global_api_expt;
--      END IF;
-- 2008/10/10 H.Itou Del End
      -- Del start 2008/06/27 uehara
--      END IF;
      -- Del end 2008/06/27 uehara
--
      -- **************************************************
      -- *** ステータス一括更新(E-7)
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
    END IF;
--
    IF (iv_callfrom_flg = cv_callfrom_flg_1) THEN
      -- 呼出元フラグ 1:コンカレント
--
      IF (NVL(iv_tighten_class,cv_tighten_class_1) = cv_tighten_class_2) THEN
        --締め処理区分が2:再の場合
--
      -- **************************************************
      -- *** 締め解除レコード削除 (E-8)
      -- **************************************************
--
        delete_tightening_control(in_tightening_program_id, -- 締めコンカレントID
                                  lv_retcode,               -- リターンコード
                                  lv_errbuf,                -- エラーメッセージコード
                                  lv_errmsg);               -- エラーメッセージ
--
        -- ステータス一括更新処理がエラーの場合
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_api_expt;
        END IF;
--
      END IF;
--
    END IF;
--
    -- **************************************************
    -- *** OUTパラメータセット(E-9)
    -- **************************************************
--
    IF (ln_warn_cnt > 0) THEN
      ov_retcode := gv_status_warn;
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
      IF ( upd_status_cur%ISOPEN ) THEN
        CLOSE upd_status_cur;
      END IF;
      IF ( reupd_status_cur%ISOPEN ) THEN
        CLOSE reupd_status_cur;
      END IF;
      -- エラーメッセージ取得
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
                                            gv_cnst_msg_001);
      lv_errbuf := lv_errmsg;
      ov_errmsg := lv_errmsg;
      ov_errbuf := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
      out_log(0,0,1,0);
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      IF ( upd_status_cur%ISOPEN ) THEN
--2008/08/05 Mod ↓
        <<count_loop_upd>>
        LOOP
          FETCH upd_status_cur INTO lr_u_rec;
          EXIT WHEN upd_status_cur%NOTFOUND;
          ln_target_cnt := ln_target_cnt + 1;
        END LOOP count_loop_upd;
--2008/08/05 Mod ↑
--
        CLOSE upd_status_cur;
      END IF;
      IF ( reupd_status_cur%ISOPEN ) THEN
--2008/08/05 Mod ↓
        <<count_loop_reupd>>
        LOOP
          FETCH reupd_status_cur INTO lr_u_rec;
          EXIT WHEN reupd_status_cur%NOTFOUND;
          ln_target_cnt := ln_target_cnt + 1;
        END LOOP count_loop_reupd;
--2008/08/05 Mod ↑
--
        CLOSE reupd_status_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
--2008/08/05 Mod ↓
--      out_log(ln_data_cnt,ln_normal_cnt,1,ln_warn_cnt);
      out_log(ln_target_cnt,ln_normal_cnt,1,ln_warn_cnt);
--2008/08/05 Mod ↑
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      IF ( upd_status_cur%ISOPEN ) THEN
--2008/08/05 Mod ↓
        <<count_loop_upd>>
        LOOP
          FETCH upd_status_cur INTO lr_u_rec;
          EXIT WHEN upd_status_cur%NOTFOUND;
          ln_target_cnt := ln_target_cnt + 1;
        END LOOP count_loop_upd;
--2008/08/05 Mod ↑
--
        CLOSE upd_status_cur;
      END IF;
      IF ( reupd_status_cur%ISOPEN ) THEN
--2008/08/05 Mod ↓
        <<count_loop_reupd>>
        LOOP
          FETCH reupd_status_cur INTO lr_u_rec;
          EXIT WHEN reupd_status_cur%NOTFOUND;
          ln_target_cnt := ln_target_cnt + 1;
        END LOOP count_loop_reupd;
--2008/08/05 Mod ↑
--
        CLOSE reupd_status_cur;
      END IF;
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--2008/08/05 Mod ↓
--      out_log(ln_data_cnt,ln_normal_cnt,1,ln_warn_cnt);
      out_log(ln_target_cnt,ln_normal_cnt,1,ln_warn_cnt);
--2008/08/05 Mod ↑
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      IF ( upd_status_cur%ISOPEN ) THEN
        CLOSE upd_status_cur;
      END IF;
      IF ( reupd_status_cur%ISOPEN ) THEN
        CLOSE reupd_status_cur;
      END IF;
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--2008/08/05 Mod ↓
--      out_log(ln_data_cnt,ln_normal_cnt,1,ln_warn_cnt);
      out_log(ln_target_cnt,ln_normal_cnt,1,ln_warn_cnt);
--2008/08/05 Mod ↑
--
--#####################################  固定部 END   ##########################################
--
  END ship_tightening;
  --
END xxwsh400004c;
/
