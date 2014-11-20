CREATE OR REPLACE PACKAGE BODY xxcmn960010c
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2012. All rights reserved.
 *
 * Package Name     : XXCMN960010C(body)
 * Description      : 受注パージ実行
 * MD.050           : T_MD050_BPO_96J_受注パージ実行
 * Version          : 1.00
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                    Description
 * ---------------------- ----------------------------------------------------------
 *  genpurgeset             パージセット出力処理
 *  updpurgeorder           パージセット更新処理
 *  purgerorder             パージ実行
 *  submain                 メイン処理プロシージャ
 *  main                    コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2012/10/25    1.00  SCSK 宮本直樹    新規作成
 *  2013/03/06    1.00  SCSK 菅原大輔    課題23対応（保留/完了在庫トラン（PORC）存在確認追加）
 *
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
  cv_msg_part               CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont               CONSTANT VARCHAR2(3) := '.';
--
--################################  固定部 END   ##################################
--
--#######################  固定グローバル変数宣言部 START   #######################
--
  gv_out_msg                VARCHAR2(2000);
  gv_sep_msg                VARCHAR2(2000);
  gv_exec_user              VARCHAR2(100);
  gv_conc_name              VARCHAR2(30);
  gv_conc_status            VARCHAR2(30);
  gn_purgeset_cnt           NUMBER;        -- パージセット出力件数
  gn_target_cnt             NUMBER;        -- 対象件数
  gn_normal_cnt             NUMBER;        -- 正常件数
  gn_warning_cnt            NUMBER;        -- 標準がパージに失敗した件数
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
  local_process_expt        EXCEPTION;
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name               CONSTANT VARCHAR2(100) := 'XXCMN960010C'; -- パッケージ名
  cv_appl_short_name        CONSTANT VARCHAR2(10)  := 'XXCMN';            -- アドオン：共通・IF領域
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  cv_conc_p_c               CONSTANT VARCHAR2(100) := 'COMPLETE';
  cv_conc_s_n               CONSTANT VARCHAR2(100) := 'NORMAL';
  cv_conc_s_w               CONSTANT VARCHAR2(100) := 'WARNING';
  cv_conc_s_e               CONSTANT VARCHAR2(100) := 'ERROR';
  cv_conc_s_c               CONSTANT VARCHAR2(100) := 'CANCELLED';
  cv_conc_s_t               CONSTANT VARCHAR2(100) := 'TERMINATED';
  cv_param_0                CONSTANT VARCHAR2(100) := '0';
  cv_param_1                CONSTANT VARCHAR2(100) := '1';
  cv_is_purgable_y          CONSTANT  VARCHAR2(1)  := 'Y';
  cv_is_purgable_n          CONSTANT  VARCHAR2(1)  := 'N';
  cv_is_purged_y            CONSTANT  VARCHAR2(1)  := 'Y';
  cv_is_purged_n            CONSTANT  VARCHAR2(1)  := 'N';
--
  cv_child_app_short_name   CONSTANT VARCHAR2(100) := 'ONT';
  cv_child_pgm_genpset      CONSTANT VARCHAR2(100) := 'GENPSETWHERE';
  cv_child_pgm_ordpur       CONSTANT VARCHAR2(100) := 'ORDPUR';
--
  cv_mst_normal             CONSTANT VARCHAR2(10)  := '正常終了';
  cv_mst_warn               CONSTANT VARCHAR2(10)  := '警告終了';
  cv_mst_error              CONSTANT VARCHAR2(10)  := '異常終了';
  cv_msg_xxcmn10135         CONSTANT VARCHAR2(100) := 'APP-XXCMN-10135';  -- 要求の発行失敗エラー
  cv_local_others_msg       CONSTANT VARCHAR2(100) := 'APP-XXCMN-11017';  -- 処理に失敗しました。パージセットID: ＆KEY
  cv_request_err_msg        CONSTANT VARCHAR2(100) := 'APP-XXCMN-11020';  -- 要求[ ＆REQUEST ]が正常に終了しませんでした。
  cv_token_key              CONSTANT VARCHAR2(10)  := 'KEY';
  cv_request_err_token      CONSTANT VARCHAR2(10)  := 'REQUEST';
--
  cv_min_date               CONSTANT VARCHAR2(100) := '1900/01/01 00:00:00';
  cv_yyyymmdd_literal       CONSTANT VARCHAR2(10)  := 'YYYY/MM/DD';
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gd_syori_date             DATE;   --処理日
  gn_purge_range            NUMBER; --パージ期間(処理日-この期間の日付が基準出庫日)
  gn_purge_range_fix        NUMBER; --パージ期間補正(基準出庫日-この補正値の日付より古いものがパージされる)
  gn_purge_range_day        NUMBER; --パージレンジ日数(From基準出庫日-この日数 To基準出庫日　のデータがパージされる)
  gn_purgeset_del_period    NUMBER; --パージセット削除期間(処理日-この日数より古い更新日のパージセットは削除される)
  gn_org_id                 NUMBER; --営業単位
  gn_purgeset_from_day      NUMBER; --パージセット処理対象開始日数
  gn_commit_range           NUMBER; --コミットレンジ
  gn_purge_set_count        NUMBER;
  gv_pre_purge_set_name     VARCHAR2(100);           -- パージセット名のプレフィックス
--
  /**********************************************************************************
   * Procedure Name   : genpurgeset
   * Description      : パージセット出力処理
   **********************************************************************************/
  PROCEDURE genpurgeset(
    on_purge_set_id OUT NUMBER,       -- 1.パージセットID(本PROCEDUREで取得される)
    ov_errbuf       OUT VARCHAR2,     --   エラー・メッセージ                  --# 固定 #
    ov_retcode      OUT VARCHAR2,     --   リターン・コード                    --# 固定 #
    ov_errmsg       OUT VARCHAR2)     --   ユーザー・エラー・メッセージ        --# 固定 #
--
  IS
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT  VARCHAR2(100) := 'genpurgeset';     -- プログラム名
    cv_xxcmn_purgeset_exist CONSTANT  VARCHAR2(100) := 'APP-XXCMN-11016'; -- パージセット名[ ＆PURGE_SET_NAME ]が既に存在します。
    cv_token_purgeset_exist CONSTANT  VARCHAR2(100) := 'PURGE_SET_NAME';
    cv_min_time             CONSTANT  VARCHAR2(10)  := ' 00:00:00';
    cv_max_time             CONSTANT  VARCHAR2(10)  := ' 23:59:59';
--
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf                         VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode                        VARCHAR2(1);     -- リターン・コード
    lv_errmsg                         VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
    --FND_REQUEST.SUBMIT_REQUESTで使用する変数
    lv_phase                          VARCHAR2(100);
    lv_status                         VARCHAR2(100);
    lv_dev_phase                      VARCHAR2(100);
    lv_dev_status                     VARCHAR2(100);
    ln_request_id                     NUMBER;          -- 子コンカレントの要求ID
--
    lt_purge_set_name                 oe_purge_sets.purge_set_name%TYPE;        --パージセット名  
    lt_purge_set_description          oe_purge_sets.purge_set_description%TYPE; --パージセット適用
    lt_purge_set_name_exist           oe_purge_sets.purge_set_name%TYPE;        --同一セット名存在チェック用
    ln_purge_set_count                NUMBER;                                   --パージセットテーブルに書き出された件数
    lv_ordered_date_low               VARCHAR2(100);                            --コンカレントに渡す受注日(From)
    lv_ordered_date_high              VARCHAR2(100);                            --コンカレントに渡す受注日(To)
    ld_std_syukko_date                DATE;                                     --基準出庫日
--
  BEGIN
--
    ov_retcode := cv_status_normal;
    --*********************************************************************************
    --パージセット名、パージセット適用を導出
    --*********************************************************************************
    /*
    --a)パージ・セット名：パージ・セットを識別するための、一意の名称を入力する。（例：タイトル+パージ実施日(yyyymmdd)）
    --b)パージ・セット適用：パージ・セットの摘要を入力する。（例：タイトル+パージ実施日(yyyymmdd)）
    lt_パージセット名   := gv_パージセット名接頭語 || TO_CHAR(gd_処理日,'YYYYMMDD';
    lt_パージセット適用 := gv_パージセット名接頭語 || TO_CHAR(gd_処理日,'YYYYMMDD';
    */
    lt_purge_set_name         := gv_pre_purge_set_name || TO_CHAR(gd_syori_date,cv_yyyymmdd_literal);
    lt_purge_set_description  := gv_pre_purge_set_name || TO_CHAR(gd_syori_date,cv_yyyymmdd_literal);
--
    --*********************************************************************************
    --パラメータにセットする受注日FROM、TOの値を導出
    --*********************************************************************************
    /*
    --c)受注日：自：処理日－(2)で取得したパージ期間 - (2)で取得したパージセット作成開始日数
    --             至：処理日－(2)で取得したパージ期間 + (2)で取得したパージ期間補正（※出荷日と受注日のズレを考慮）
    lv_ordered_date_low  :=  TO_CHAR(gd_処理日 - gn_パージ期間 - gn_パージセット作成開始日数,'YYYY/MM/DD') || cv_時刻最小値;
    lv_ordered_date_high :=  TO_CHAR(gd_処理日 - gn_パージ期間 + gn_パージ期間補正,'YYYY/MM/DD') || cv_時刻最大値;
    */
    lv_ordered_date_low   := TO_CHAR(gd_syori_date - gn_purge_range - gn_purgeset_from_day, cv_yyyymmdd_literal) || cv_min_time;
    lv_ordered_date_high  := TO_CHAR(gd_syori_date - gn_purge_range + gn_purge_range_fix, cv_yyyymmdd_literal) || cv_max_time;
--
    --*********************************************************************************
    --同一パージセット名称の存在チェック
    --*********************************************************************************
    /*
    purge_set_nameで標準パージセットテーブルを検索し、
    同じpurge_set_nameのレコード有無を取得する。
    SELECT PURGE_SET_NAME
    INTO lt_パージセット名存在
    FROM OE_PURGE_SETS
    WHERE PURGE_SET_NAME = lt_パージセット名
    AND ROWNUM = 1;
    */
    BEGIN
      SELECT
        ops.purge_set_name    AS purge_set_name
      INTO
        lt_purge_set_name_exist
      FROM
        oe_purge_sets ops 
      WHERE
        ops.purge_set_name = lt_purge_set_name
        AND ROWNUM = 1;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        NULL;
    END;
--
    --同一パージセット名が存在したら、メッセージを出力し、ステータスを警告にする。
    --（その後の動作に影響はないので、処理は続行する。）
    IF ( lt_purge_set_name_exist IS NOT NULL )  THEN
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_xxcmn_purgeset_exist -- パージセット名[ ＆PURGE_SET_NAME ]が既に存在します。
                    ,iv_token_name1  => cv_token_purgeset_exist
                    ,iv_token_value1 => lt_purge_set_name
                   );
    --出力にメッセージを出力する
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
      --ステータスを警告にする
      ov_retcode := cv_status_warn;
    END IF;
--
    --*********************************************************************************
    --導出された値を元に、要求の発行「受注パージ選択(GENPSETWHERE)」を実施する。
    --*********************************************************************************
    /*
    ln_request_id := FND_REQUEST.SUBMIT_REQUEST(.
                       application       => cv_child_app_short_name           .--アプリケーション短縮名
                     , program           => cv_child_pgm_genpset              .--プログラム名
                     , argument1         => lt_purge_set_name                 .--パージ・セット名
                     , argument2         => lt_purge_set_description          .--パージ・セット摘要
                     , argument8         => lv_ordered_date_low               .--受注日(FROM)
                     , argument9         => lv_ordered_date_high              .--受注日(TO)
                       );.
    */
    ln_request_id := FND_REQUEST.SUBMIT_REQUEST(
                       application       => cv_child_app_short_name     --アプリケーション短縮名
                     , program           => cv_child_pgm_genpset        --プログラム名
                     , argument1         => lt_purge_set_name           --パージ・セット名
                     , argument2         => lt_purge_set_description    --パージ・セット摘要
                     , argument3         => ''
                     , argument4         => ''
                     , argument5         => ''
                     , argument6         => ''
                     , argument7         => ''
                     , argument8         => lv_ordered_date_low         --受注日(FROM)
                     , argument9         => lv_ordered_date_high        --受注日(TO)
                     , argument10        => ''
                     , argument11        => ''
                     , argument12        => ''
                       );
--
    -- コンカレント起動失敗の場合はエラー処理
    /*
    IF ( ln_request_id = 0 ) THEN.
      lv_errmsg := xxcmn_common_pkg.get_msg(
                     iv_application   =>gv_cons_msg_kbn_cmn
                    ,iv_name          => gv_msg_xxcmn10135);
      RAISE global_api_others_expt;
    ELSE
      COMMIT;
    END IF;
    */
    IF ( NVL(ln_request_id, 0) = 0 ) THEN
      ov_errmsg := xxcmn_common_pkg.get_msg(
                     iv_application   => cv_appl_short_name
                    ,iv_name          => cv_msg_xxcmn10135);
      RAISE global_api_others_expt;
    ELSE
      COMMIT;
    END IF;
--
    --*********************************************************************************
    --発行されたコンカレントの終了チェック
    --*********************************************************************************
    --コンカレント実行結果を取得
    /*
    IF ( FND_CONCURRENT.WAIT_FOR_REQUEST(.
           request_id => ln_request_id.
          ,interval   => 1.
          ,max_wait   => 0.
          ,phase      => lv_phase.
          ,status     => lv_status.
          ,dev_phase  => lv_dev_phase.
          ,dev_status => lv_dev_status.
          ,message    => lv_errbuf.
          ) ) THEN
    */
    IF ( FND_CONCURRENT.WAIT_FOR_REQUEST(
           request_id => ln_request_id
          ,interval   => 1
          ,max_wait   => 0
          ,phase      => lv_phase
          ,status     => lv_status
          ,dev_phase  => lv_dev_phase
          ,dev_status => lv_dev_status
          ,message    => ov_errbuf
          ) ) THEN
--
      -- ステータス反映
      -- フェーズ:完了
      IF ( lv_dev_phase = cv_conc_p_c ) THEN
--
        /*
          lv_dev_statusが'ERROR','CANCELLED','TERMINATED'の場合はエラー終了
        　　　　ステータスをエラーにして終了
          lv_dev_statusが'WARNING'の場合は警告終了
        　　　　ステータスを警告にする

          lv_dev_statusが'NORMAL'の場合は正常処理続行

          lv_dev_statusが上記以外の場合はエラー終了
        　　　　ステータスをエラーにして終了
        */
        --ステータスコードにより状況判定
        CASE lv_dev_status
          --エラー
          WHEN cv_conc_s_e THEN
            ov_errmsg := xxcmn_common_pkg.get_msg(
                           iv_application  => cv_appl_short_name
                          ,iv_name         => cv_request_err_msg
                          ,iv_token_name1  => cv_request_err_token
                          ,iv_token_value1 => cv_child_pgm_genpset
                         );
            RAISE global_api_others_expt;

          --キャンセル
          WHEN cv_conc_s_c THEN
            ov_errmsg := xxcmn_common_pkg.get_msg(
                           iv_application  => cv_appl_short_name
                          ,iv_name         => cv_request_err_msg
                          ,iv_token_name1  => cv_request_err_token
                          ,iv_token_value1 => cv_child_pgm_genpset
                         );
            RAISE global_api_others_expt;

          --強制終了
          WHEN cv_conc_s_t THEN
            ov_errmsg := xxcmn_common_pkg.get_msg(
                           iv_application  => cv_appl_short_name
                          ,iv_name         => cv_request_err_msg
                          ,iv_token_name1  => cv_request_err_token
                          ,iv_token_value1 => cv_child_pgm_genpset
                         );
            RAISE global_api_others_expt;

          --警告終了
          WHEN cv_conc_s_w THEN
            --今まで正常の場合のみ警告ステータス
            IF ( ov_retcode < 1 ) THEN
              ov_retcode := cv_status_warn;
            END IF;
 
          --正常終了
          WHEN cv_conc_s_n THEN
              NULL;

          --他の値は例外処理
          ELSE
            ov_errmsg := xxcmn_common_pkg.get_msg(
                           iv_application  => cv_appl_short_name
                          ,iv_name         => cv_request_err_msg
                          ,iv_token_name1  => cv_request_err_token
                          ,iv_token_value1 => cv_child_pgm_genpset
                         );
            RAISE global_api_others_expt;
        END CASE;

      --完了まで処理を待つが、完了ステータスではなかった場合の例外ハンドル
      ELSE
        ov_errmsg := xxcmn_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name
                      ,iv_name         => cv_request_err_msg
                      ,iv_token_name1  => cv_request_err_token
                      ,iv_token_value1 => cv_child_pgm_genpset
                     );
        RAISE global_api_others_expt;
      END IF;
--
    --WAIT_FOR_REQUESTが異常だった場合の例外ハンドル
    ELSE
        ov_errmsg := xxcmn_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name
                      ,iv_name         => cv_request_err_msg
                      ,iv_token_name1  => cv_request_err_token
                      ,iv_token_value1 => cv_child_pgm_genpset
                     );
        RAISE global_api_others_expt;
    END IF;
--
    --*********************************************************************************
    --パージセットIDの取得
    --*********************************************************************************
    --lt_purge_set_nameをキーに標準パージセットテーブルを検索し、
    --作成されたパージセットIDを取得（パージセットIDの最大値）
    /*
    SELECT MAX(パージセットID)
    INTO on_パージセットID
    FROM 受注パージセットテーブル
    WHERE パージセット名 = lt_パージセット名;
    */
    SELECT
      MAX(ops.purge_set_id)  AS max_purge_set_id
    INTO
      on_purge_set_id
    FROM
      oe_purge_sets ops
    WHERE
      ops.purge_set_name = lt_purge_set_name;
--
    --値が取得できなかった場合はエラー終了
    IF ( on_purge_set_id IS NULL ) THEN
        --エラー処理
        ov_retcode := cv_status_error;
        RAISE local_process_expt;
    END IF;
--
  EXCEPTION
    WHEN local_process_expt THEN
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
      ROLLBACK;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errmsg := xxcmn_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_local_others_msg
                    ,iv_token_name1  => cv_token_key
                    ,iv_token_value1 => TO_CHAR(on_purge_set_id)
                   );
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
  END genpurgeset;
--
  /**********************************************************************************
   * Procedure Name   : updpurgeorder
   * Description      : パージセット更新処理
   **********************************************************************************/
  PROCEDURE updpurgeorder(
    in_purge_set_id         IN  NUMBER,       -- 1.パージセットID(指定したIDが対象となる)
    on_purge_target_count   OUT NUMBER,       -- 2.パージ対象件数(本処理で適格='Y'にした件数が戻る)
    ov_errbuf               OUT VARCHAR2,     --   エラー・メッセージ                  --# 固定 #
    ov_retcode              OUT VARCHAR2,     --   リターン・コード                    --# 固定 #
    ov_errmsg               OUT VARCHAR2      --   ユーザー・エラー・メッセージ        --# 固定 #
  )
  IS
--
    cv_prg_name                 CONSTANT  VARCHAR2(100) := 'updpurgeorder';    -- プログラム名

    cv_status_wsh_keijozumi     CONSTANT  VARCHAR2(2)   :=  '04';--04:出荷実績計上済
    cv_status_po_keijozumi      CONSTANT  VARCHAR2(2)   :=  '08';--08:出荷実績計上済
--Add 20130306 V1.00 SCSK D.Sugahara Start
    cv_doc_type_porc            CONSTANT  VARCHAR2(10)   :=  'PORC'; --文書タイプ：受入
    cv_doc_source_rma           CONSTANT  VARCHAR2(10)   :=  'RMA';  --ソース文書タイプ：返品受注
--Add 20130306 V1.00 SCSK D.Sugahara End
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf                           VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode                          VARCHAR2(1);     -- リターン・コード
    lv_errmsg                           VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
    ln_purge_set_count                  NUMBER DEFAULT 0; --パージ情報テーブルに書き出された件数
    ln_purge_target_count               NUMBER DEFAULT 0; --対象となるレコード件数
    ln_purge_update_count               NUMBER DEFAULT 0; --対象となるレコード件数
    ld_std_syukko_date                  DATE;   --基準出庫日
    ld_purge_set_del_std_date           DATE;   --パージセット削除基準日
    ln_purge_set_upd_yet                NUMBER DEFAULT 0; --未更新ヘッダID件数

    TYPE l_header_id_ttype IS TABLE OF xxcmn_order_headers_all_arc.header_id%TYPE;
    l_header_id_tab l_header_id_ttype;

    TYPE l_purge_set_header_id_ttype IS TABLE OF oe_purge_orders.header_id%TYPE  INDEX BY BINARY_INTEGER;
    l_purge_set_header_id_tab l_purge_set_header_id_ttype;

    l_purge_set_lock_id_tab l_purge_set_header_id_ttype;

    TYPE l_del_purge_set_id_ttype IS TABLE OF oe_purge_sets.purge_set_id%TYPE;
    l_del_purge_set_id_tab l_del_purge_set_id_ttype;

  BEGIN
    ov_retcode := cv_status_normal;
    --*********************************************************************************
    --パージセットテーブル、パージ情報テーブル上の古いレコードを削除
    --*********************************************************************************
    --レコード削除する日付（削除基準日）を求める
    --ld_パージセット削除基準日 := gd_処理日 - gn_パージセット削除期間;
    ld_purge_set_del_std_date := gd_syori_date - gn_purgeset_del_period;
--
    --削除対象とするパージセットIDを取得
    /*
    SELECT
        purge_set_id
    BULK COLLECT
    INTO
        l_del_purge_set_id_tab
    FROM
        パージセットテーブル,
        パージ情報テーブル
    WHERE
        パージ情報テーブル．パージセットID = パージセットテーブル．パージセットID
        パージ情報テーブル．最終更新日 < ln_パージセット削除基準日;
    FOR UPDATE NOWAIT;
    */
    SELECT
        ops.purge_set_id AS purge_set_id
    BULK COLLECT
    INTO
        l_del_purge_set_id_tab
    FROM
        oe_purge_sets   ops,
        oe_purge_orders opo   --パージ情報テーブルも削除するためロック対象に含める
    WHERE
          ops.purge_set_id = opo.purge_set_id
      AND ops.last_update_date < ld_purge_set_del_std_date
    FOR UPDATE NOWAIT;
--
    --パージ情報テーブル削除
    /*
    FORALL i IN 1 .. v_purge_set_id.count 
      DELETE FROM
          oe_purge_orders
      WHERE
          purge_set_id = l_del_purge_set_id_tab(i);
    */
    FORALL i IN 1 .. l_del_purge_set_id_tab.COUNT 
      DELETE
      FROM
          oe_purge_orders
      WHERE
          purge_set_id = l_del_purge_set_id_tab(i);
--
    --パージセットテーブル削除
    /*
    FORALL i IN 1 .. v_purge_set_id.count 
      DELETE FROM
          oe_purge_sets
      WHERE
          purge_set_id = l_del_purge_set_id_tab(i);
    */
    FORALL i IN 1 .. l_del_purge_set_id_tab.COUNT 
      DELETE
      FROM
          oe_purge_sets
      WHERE
          purge_set_id = l_del_purge_set_id_tab(i);
--
    --*********************************************************************************
    --受注パージテーブルに出力されたデータの適格を一度"N"に更新する
    --*********************************************************************************
--
    /*
    パージ情報テーブルで処理対象となるパージセットIDのレコードをロック
    SELECT
      ヘッダID
    BULK COLLECT
    INTO
        l_purge_set_header_id_tab
    FROM
      受注パージ情報テーブル
    WHERE
      パージセットID = in_パージセットID
    FOR UPDATE NOWAIT;
    */
    SELECT
      opo.header_id       AS header_id
    BULK COLLECT
    INTO
        l_purge_set_lock_id_tab
    FROM
      oe_purge_orders        opo
    WHERE
      opo.purge_set_id = in_purge_set_id
    FOR UPDATE NOWAIT;
--
    /*
    UPDATE パージ情報テーブル
    SET    適格='Y'
    WHERE  パージセットID = パージセット作成で作成されたパージセットID
    */
    UPDATE
      oe_purge_orders --パージ情報テーブル
    SET
       is_purgable            = cv_is_purgable_n          --適格
      ,last_update_date       = cd_last_update_date       --WHOカラム
      ,last_updated_by        = cn_last_updated_by        --WHOカラム 
      ,last_update_logon      = cn_last_update_login      --WHOカラム
      ,program_application_id = cn_program_application_id --WHOカラム
      ,program_id             = cn_program_id             --WHOカラム
      ,program_update_date    = cd_program_update_date    --WHOカラム
    WHERE
        purge_set_id = in_purge_set_id; --作成されたパージセットIDで全件を更新
--
    --更新件数を取得（＝出力件数と同等）
    gn_purgeset_cnt := SQL%ROWCOUNT;

    /*
    件数が0件の場合は処理終了
    IF gn_対象件数 = 0 THEN
      終了処理
    END IF;
    */
    IF ( gn_purgeset_cnt = 0 ) THEN
      on_purge_target_count := 0;
      RETURN;
    END IF;
--
    --基準出庫日を求める
    --ld_基準出庫日 := gd_処理日 - gn_パージ期間;
    ld_std_syukko_date := gd_syori_date - gn_purge_range;
--
    --*********************************************************************************
    --受注ヘッダアドオンテーブルと受注パージテーブルから、対象の受注ヘッダIDを導出
    --*********************************************************************************
    /*
    SELECT.
          HEADER_ID
    BULK COLLECT
    INTO   l_header_id_tab
    FROM (
    SELECT
          OHAB.HEADER_ID
    FROM
          受注ヘッダアドオンテーブル(BK) OHAB,
          OE_ORDER_HEADERS_ALL OOHA,
          OE_PURGE_ORDERS OPO
    WHERE
          OOHA.営業単位 = ln_営業単位
      AND OHAB.着荷日< id_基準出庫日
      AND OHAB.着荷日 >= id_基準出庫日 - ln_パージレンジ日数
      AND OHAB.ステータス IN ('04','08')
      AND OOHA.HEADER_ID = OPO.HEADER_ID
      AND OHAB.HEADER_ID = OOHA.HEADER_ID
--Add 20130306 V1.00 SCSK D.Sugahara Start
      AND  NOT EXISTS (
                SELECT  1 
                FROM     保留在庫トラン  itp  
                        ,受入明細    rsl
                        ,受入ヘッダ  rsh
                WHERE  itp.doc_type             = 'PORC'
                AND    rsh.shipment_header_id   = itp.doc_id
                AND    rsl.shipment_header_id   = rsh.shipment_header_id
                AND    rsl.line_num             = itp.doc_line
                AND    rsl.source_document_code = 'RMA'
                AND    rsl.oe_order_header_id   = xoohaa.header_id
                AND    ROWNUM                   = 1
              )
      AND  NOT EXISTS (
                SELECT  1
                FROM     完了在庫トラン  itc  
                        ,受入明細    rsl
                        ,受入ヘッダ  rsh
                WHERE  itc.doc_type             = 'PORC'
                AND    rsh.shipment_header_id   = itc.doc_id
                AND    rsl.shipment_header_id   = rsh.shipment_header_id
                AND    rsl.line_num             = itc.doc_line
                AND    rsl.source_document_code = 'RMA'
                AND    rsl.oe_order_header_id   = xoohaa.header_id
                AND    ROWNUM                   = 1
              )
--Add 20130306 V1.00 SCSK D.Sugahara End
    );
    */
    SELECT
          header_id AS header_id
    BULK COLLECT
    INTO  l_header_id_tab
    FROM (
--Mod 20130306 V1.00 SCSK D.Sugahara Start   
--課題23対応 ヒント句修正
      SELECT /*+ LEADING( xohaa xoohaa opo ) 
              USE_NL( xohaa xoohaa opo ) 
              INDEX( xohaa XXCMN_OHAA_N15 ) 
              INDEX( xoohaa XXCMN_OE_ORDER_H_ALL_ARC_PK ) 
              */
--Mod 20130306 V1.00 SCSK D.Sugahara End
            xohaa.header_id AS header_id
      FROM
            xxcmn_order_headers_all_arc xohaa,                --受注ヘッダ（アドオン）バックアップ
            xxcmn_oe_order_headers_all_arc xoohaa,            --受注ヘッダ（標準）バックアップ
            oe_purge_orders opo                               --パージ情報
      WHERE
            opo.purge_set_id = in_purge_set_id
        AND xoohaa.org_id = gn_org_id                         --受注ヘッダ（標準）バックアップの営業単位=プロファイル値
        AND xohaa.arrival_date <  ld_std_syukko_date          --受注ヘッダ（アドオン）バックアップの着荷日を判定
        AND xohaa.arrival_date >= ld_std_syukko_date - gn_purge_range_day
        AND xohaa.req_status IN (
                                cv_status_wsh_keijozumi,      --04:出荷実績計上済
                                cv_status_po_keijozumi )      --08:出荷実績計上済
        AND xoohaa.header_id = opo.header_id                  --受注ヘッダ（標準）バックアップにデータが存在する
        AND xohaa.header_id = xoohaa.header_id                --受注ヘッダ（アドオン）バックアップにデータが存在する
--Add 20130306 V1.00 SCSK D.Sugahara Start   
--保留在庫トラン、完了在庫トランのPROC(RMA)が存在する場合は対象外とする条件を追加
--課題23対応
        AND  NOT EXISTS (
                  SELECT  1 
                            /*+ LEADING(rsl rsh itp) USE_NL(rsl rsh itp) 
                                INDEX( rsl RCV_SHIPMENT_LINES_U2 )
                                INDEX( itp IC_TRAN_PNDI2 ) 
                            */
                  FROM     ic_tran_pnd  itp  --OPM保留在庫トランザクション(標準)
                          ,rcv_shipment_lines    rsl
                          ,rcv_shipment_headers  rsh
                  WHERE  itp.doc_type             = cv_doc_type_porc
                  AND    rsh.shipment_header_id   = itp.doc_id
                  AND    rsl.shipment_header_id   = rsh.shipment_header_id
                  AND    rsl.line_num             = itp.doc_line
                  AND    rsl.source_document_code = cv_doc_source_rma
                  AND    rsl.oe_order_header_id   = xoohaa.header_id
                  AND    ROWNUM                   = 1
                )
        AND  NOT EXISTS (
                  SELECT  1
                            /*+ LEADING(rsl rsh itc) USE_NL(rsl rsh itc) 
                                INDEX( rsl RCV_SHIPMENT_LINES_U2 )
                                INDEX( itc IC_TRAN_CMPI2 ) 
                            */
                  FROM     ic_tran_cmp  itc  --OPM完了在庫トランザクション(標準)
                          ,rcv_shipment_lines    rsl
                          ,rcv_shipment_headers  rsh
                  WHERE  itc.doc_type             = cv_doc_type_porc
                  AND    rsh.shipment_header_id   = itc.doc_id
                  AND    rsl.shipment_header_id   = rsh.shipment_header_id
                  AND    rsl.line_num             = itc.doc_line
                  AND    rsl.source_document_code = cv_doc_source_rma
                  AND    rsl.oe_order_header_id   = xoohaa.header_id
                  AND    ROWNUM                   = 1
                )
--Add 20130306 V1.00 SCSK D.Sugahara End
    );
    --*********************************************************************************
    --抽出結果の件数を取得
    --*********************************************************************************
    --ln_purge_target_count :=l_処理対象カーソルヘッダID_tab.count;
    ln_purge_target_count := l_header_id_tab.COUNT;
    /*
    パージ対象データが存在した場合(ln_purge_target_count > 0 ) は、
    その対象データに対して「適格」='Y'の更新を実行する。
    */
    IF ( ln_purge_target_count ) > 0 THEN
      << purge_set_update_loop >>
      /*
      << purge_set_update_loop >>
      FOR ln_main_idx in 1 .. l_処理対象カーソルヘッダID_tab.COUNT
      LOOP
      */
      FOR ln_main_idx in 1 .. l_header_id_tab.COUNT
      LOOP
        -- ===============================================
        -- 分割コミット
        -- ===============================================
        /*
          NVL(gn_分割コミット数, 0) <> 0の場合
        */
        IF ( NVL(gn_commit_range, 0) <> 0 ) THEN
          /*
            ln_未コミット更新件数（パージセット） > 0
            かつ MOD(ln_未更新パージ情報件数, gn_分割コミット数) = 0の場合
          */
          IF (  (ln_purge_set_upd_yet > 0)
            AND (MOD(ln_purge_set_upd_yet, gn_commit_range) = 0)
             )
          THEN
            /*
            コミットレンジに達したのでl_処理対象ヘッダID_tabの内容で一括UPDATEする
            FORALL ln_idx IN 1..ln_未更新パージ情報件数
              UPDATE
                パージ情報テーブル 
              SET
                適格 = 'Y'
                各WHOカラム更新
              WHERE
                    パージセットID = ⑤で取得した処理中のパージセットID
                AND パージ済 = 'N'
                AND header_id = l_処理対象ヘッダID_tab(ln_idx);
            */
            BEGIN
              FORALL ln_idx IN 1..ln_purge_set_upd_yet
                UPDATE
                  oe_purge_orders 
                SET
                   is_purgable            = cv_is_purgable_y          --「適格」を'Y'に更新
                  ,last_update_date       = cd_last_update_date       --WHOカラム
                  ,last_updated_by        = cn_last_updated_by        --WHOカラム
                  ,last_update_logon      = cn_last_update_login      --WHOカラム
                  ,program_application_id = cn_program_application_id --WHOカラム
                  ,program_id             = cn_program_id             --WHOカラム
                  ,program_update_date    = cd_program_update_date    --WHOカラム
                WHERE
                      purge_set_id = in_purge_set_id                  --対象にしているパージセットIDである
                  AND NVL(is_purged,cv_is_purged_n) = cv_is_purged_n  --パージされていない
                  AND header_id = l_purge_set_header_id_tab(ln_idx);            --対象となった受注ヘッダIDである
            EXCEPTION
              WHEN OTHERS THEN
                RAISE local_process_expt;
            END;
--
            /*
            正常件数にUPDATEで更新した件数を加算
            gn_対象件数 := gn_対象件数 + SQL%ROWCOUNT;
            ln_未更新パージ情報件数 := 0;
            COMMIT;
            */
            gn_target_cnt := gn_target_cnt + SQL%ROWCOUNT;
            ln_purge_set_upd_yet := 0;
            COMMIT;
            /*
            コミットレンジ分のUPDATEが完了したので、コレクションを初期化
            l_処理対象ヘッダID.DELETE;
            */
            l_purge_set_header_id_tab.DELETE;
--
            /*
            コミットしたことでロックが外れるため、パージセットID単位で再度ロックをかける
            l_処理対象ヘッダID.DELETE;
            SELECT
              ヘッダID
            BULK COLLECT
            INTO
              l_ロック中パージセットID_tab
            FROM
              パージ情報テーブル
            WHERE
              パージセットID = ⑤で取得した処理中のパージセットID
            FOR UPDATE NOWAIT;
            */
            l_purge_set_lock_id_tab.DELETE;
 
            SELECT
              opo.header_id AS header_id
            BULK COLLECT
            INTO
              l_purge_set_lock_id_tab
            FROM
              oe_purge_orders opo
            WHERE
              opo.purge_set_id = in_purge_set_id
            FOR UPDATE NOWAIT;
          END IF;
        END IF;
        
        /*
        ln_未更新パージ情報件数を1つ加算する。
        --
        l_処理対象ヘッダID(ln_未更新パージ情報件数) := l_処理対象カーソルヘッダID(ln_main_idx);
        END LOOP purge_set_update_loop;
        */
        ln_purge_set_upd_yet := ln_purge_set_upd_yet + 1;
        l_purge_set_header_id_tab(ln_purge_set_upd_yet) := l_header_id_tab(ln_main_idx);
      END LOOP purge_set_update_loop;
--
      /*
      コミットされていない残りの処理対象ヘッダIDを更新する
      FORALL ln_idx IN 1..ln_未更新パージ情報件数
        UPDATE
          パージ情報テーブル 
        SET
          適格 = 'Y'
          各WHOカラム更新
        WHERE
              パージセットID = ⑤で取得した処理中のパージセットID
          AND パージ済 = 'N'
          AND header_id = l_処理対象ヘッダID_tab(ln_idx);
      */
      BEGIN
        FORALL ln_idx IN 1..ln_purge_set_upd_yet
          UPDATE
            oe_purge_orders 
          SET
             is_purgable            = cv_is_purgable_y          --「適格」を'Y'に更新
            ,last_update_date       = cd_last_update_date       --WHOカラム
            ,last_updated_by        = cn_last_updated_by        --WHOカラム
            ,last_update_logon      = cn_last_update_login      --WHOカラム
            ,program_application_id = cn_program_application_id --WHOカラム
            ,program_id             = cn_program_id             --WHOカラム
            ,program_update_date    = cd_program_update_date    --WHOカラム
          WHERE
                purge_set_id = in_purge_set_id                  --対象にしているパージセットIDである
            AND NVL(is_purged,cv_is_purged_n) = cv_is_purged_n  --パージされていない
            AND header_id = l_purge_set_header_id_tab(ln_idx);            --対象となった受注ヘッダIDである
      EXCEPTION
        WHEN OTHERS THEN
          RAISE local_process_expt;
      END;
      /*
      正常件数にUPDATEで更新した件数を加算
      gn_対象件数 := gn_対象件数 + SQL%ROWCOUNT;
      */
      gn_target_cnt := gn_target_cnt + SQL%ROWCOUNT;
    END IF;
    on_purge_target_count := gn_target_cnt;
--
  EXCEPTION
    WHEN local_process_expt THEN
      ov_errmsg := xxcmn_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_local_others_msg
                    ,iv_token_name1  => cv_token_key
                    ,iv_token_value1 => TO_CHAR(in_purge_set_id) || ':' ||
                                                l_purge_set_header_id_tab(SQL%BULK_EXCEPTIONS(1).ERROR_INDEX)
                   );
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_pkg_name||cv_msg_part||SQLERRM;
      gn_warning_cnt := gn_warning_cnt + 1;
      ov_retcode := cv_status_error;
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
      ROLLBACK;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errmsg := xxcmn_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_local_others_msg
                    ,iv_token_name1  => cv_token_key
                    ,iv_token_value1 => TO_CHAR(in_purge_set_id)
                   );
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_pkg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
  END updpurgeorder;
--
  /**********************************************************************************
   * Procedure Name   : purgerorder
   * Description      : パージ実行
   **********************************************************************************/
  PROCEDURE purgerorder(
    in_purge_set_id IN  NUMBER,       -- 1.パージセットID(この値が処理対象となる)
    ov_errbuf       OUT VARCHAR2,     --   エラー・メッセージ                  --# 固定 #
    ov_retcode      OUT VARCHAR2,     --   リターン・コード                    --# 固定 #
    ov_errmsg       OUT VARCHAR2      --   ユーザー・エラー・メッセージ        --# 固定 #
  )
--
--
--###########################  固定部 START   ###########################
--
  IS
    cv_prg_name                 CONSTANT VARCHAR2(100) := 'purgerorder';             -- プログラム名

    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf                   VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode                  VARCHAR2(1);     -- リターン・コード
    lv_errmsg                   VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
    lv_purge_err_cnt            NUMBER;
--
    --FND_REQUEST.SUBMIT_REQUESTで使用する変数
    lv_phase                    VARCHAR2(100);
    lv_status                   VARCHAR2(100);
    lv_dev_phase                VARCHAR2(100);
    lv_dev_status               VARCHAR2(100);
    ln_request_id               NUMBER;          -- 子コンカレントの要求ID

    --*********************************************************************************
    --パージ結果レコード取得用カーソル
    --*********************************************************************************
    /*
    CURSOR パージ情報エラー_cur(
      パージセットID            NUMBER
    )
    IS
    SELECT
    　　ヘッダID
    　　受注番号
    　　エラーテキスト
    FROM
      パージ情報テーブル
    WHERE
          パージセットID = in_purge_set_id
      AND パージ適格 = 'Y'
      AND パージ済 = 'N';
    */
    CURSOR purge_order_error_cur(
      in_purge_set_id            NUMBER
    )
    IS
      SELECT
        opo.header_id     AS header_id,
        opo.order_number  AS order_number,
        opo.error_text    AS error_text
      FROM
        oe_purge_orders   opo
      WHERE
            opo.purge_set_id = in_purge_set_id
        AND NVL(opo.is_purgable,cv_is_purgable_n) = cv_is_purgable_y  --パージ適格（Y=パージ対象）
        AND NVL(opo.is_purged,cv_is_purged_n)     = cv_is_purged_n    --パージ済フラグ(Y=パージ済)
    ;
  BEGIN
    ov_retcode := cv_status_normal;
    lv_purge_err_cnt := 0;
    FND_FILE.PUT_LINE (FND_FILE.LOG, 'パージ・セットID:' || TO_CHAR(in_purge_set_id));
    --*********************************************************************************
    --パージセットIDを基に、要求の発行　「受注パージ(ORDPUR)」　を実施する。
    --*********************************************************************************
    ln_request_id := FND_REQUEST.SUBMIT_REQUEST(
                       application       => cv_child_app_short_name   --アプリケーション短縮名
                     , program           => cv_child_pgm_ordpur       --プログラム名
                     , argument1         => in_purge_set_id           --パージ・セットID
                       );
    -- コンカレント起動失敗の場合はエラー処理
    IF ( NVL(ln_request_id, 0) = 0 ) THEN
      ov_errmsg := xxcmn_common_pkg.get_msg(
                     iv_application   => cv_appl_short_name
                    ,iv_name          => cv_msg_xxcmn10135);
      RAISE global_api_others_expt;
    ELSE
      COMMIT;
    END IF;

    --*********************************************************************************
    --発行されたコンカレントの終了チェック
    --*********************************************************************************
    IF ( FND_CONCURRENT.WAIT_FOR_REQUEST(
           request_id => ln_request_id
          ,interval   => 1
          ,max_wait   => 0
          ,phase      => lv_phase
          ,status     => lv_status
          ,dev_phase  => lv_dev_phase
          ,dev_status => lv_dev_status
          ,message    => ov_errbuf
          ) ) THEN
      -- ステータス反映
--
      -- フェーズ:完了
      IF ( lv_dev_phase = cv_conc_p_c ) THEN
--
        /*
            -- ステータス:異常
          lv_dev_statusが'ERROR','CANCELLED','TERMINATED'の場合はエラー終了
        　　　　ステータスをエラーにして終了
          lv_dev_statusが'WARNING'の場合は警告終了
        　　　　ステータスを警告にする

          lv_dev_statusが'NORMAL'の場合は正常処理続行

          lv_dev_statusが上記以外の場合はエラー終了
        　　　　ステータスをエラーにして終了
        */
        --ステータスコードにより状況判定
        CASE lv_dev_status
          --エラー
          WHEN cv_conc_s_e THEN
            ov_errmsg := xxcmn_common_pkg.get_msg(
                           iv_application  => cv_appl_short_name
                          ,iv_name         => cv_request_err_msg
                          ,iv_token_name1  => cv_request_err_token
                          ,iv_token_value1 => cv_child_pgm_ordpur
                         );
            RAISE global_api_others_expt;

          --キャンセル
          WHEN cv_conc_s_c THEN
            ov_errmsg := xxcmn_common_pkg.get_msg(
                           iv_application  => cv_appl_short_name
                          ,iv_name         => cv_request_err_msg
                          ,iv_token_name1  => cv_request_err_token
                          ,iv_token_value1 => cv_child_pgm_ordpur
                         );
            RAISE global_api_others_expt;

          --強制終了
          WHEN cv_conc_s_t THEN
            ov_errmsg := xxcmn_common_pkg.get_msg(
                           iv_application  => cv_appl_short_name
                          ,iv_name         => cv_request_err_msg
                          ,iv_token_name1  => cv_request_err_token
                          ,iv_token_value1 => cv_child_pgm_ordpur
                         );
            RAISE global_api_others_expt;

          --警告終了
          WHEN cv_conc_s_w THEN
            --今まで正常の場合のみ警告ステータス
            IF ( ov_retcode < 1 ) THEN
              ov_retcode := cv_status_warn;
            END IF;
 
          --正常終了
          WHEN cv_conc_s_n THEN
              NULL;

          --他の値は例外処理
          ELSE
            ov_errmsg := xxcmn_common_pkg.get_msg(
                           iv_application  => cv_appl_short_name
                          ,iv_name         => cv_request_err_msg
                          ,iv_token_name1  => cv_request_err_token
                          ,iv_token_value1 => cv_child_pgm_ordpur
                         );
            RAISE global_api_others_expt;
        END CASE;

      --完了まで処理を待つが、完了ステータスではなかった場合の例外ハンドル
      ELSE
        ov_errmsg := xxcmn_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name
                      ,iv_name         => cv_request_err_msg
                      ,iv_token_name1  => cv_request_err_token
                      ,iv_token_value1 => cv_child_pgm_ordpur
                     );
        RAISE global_api_others_expt;
      END IF;
--
    --WAIT_FOR_REQUESTが異常だった場合の例外ハンドル
    ELSE
        ov_errmsg := xxcmn_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name
                      ,iv_name         => cv_request_err_msg
                      ,iv_token_name1  => cv_request_err_token
                      ,iv_token_value1 => cv_child_pgm_ordpur
                     );
        RAISE global_api_others_expt;
    END IF;

    --*********************************************************************************
    --パージ情報テーブルから、エラーテキストを取得しメッセージに出力
    --*********************************************************************************
    /*
    << パージ情報エラー_loop >>
    FOR パージ情報エラー_rec IN パージ情報エラー_cur(
                          処理中のパージセットID
                         )
    LOOP
      パージ情報エラー件数 := パージ情報エラー件数 + 1;
      FND_FILE.PUT_LINE (FND_FILE.OUTPUT, '受注番号[' || カーソルの受注番号 || 
                                         ']:' || カーソルのエラーテキスト );
    END LOOP パージ情報エラー_loop;
    */
    << purge_order_error_loop >>
    FOR lr_purge_order_error_rec IN purge_order_error_cur(
                           in_purge_set_id
                         )
    LOOP
      lv_purge_err_cnt := lv_purge_err_cnt + 1;
      FND_FILE.PUT_LINE (FND_FILE.OUTPUT, '受注番号[' || TO_CHAR(lr_purge_order_error_rec.order_number) || 
                                          ']:'        || TO_CHAR(lr_purge_order_error_rec.error_text));
    END LOOP purge_order_error_loop;
    /*
    --エラーテキストが１つ以上あったらステータスを警告にする
    IF パージ情報エラー件数 >0 THEN
      IF ( ov_retcode < 1 ) THEN
        ov_retcode := cv_status_warn;
      END IF;
    END IF;
    */
    IF ( lv_purge_err_cnt > 0 ) THEN
      IF ( ov_retcode < 1 ) THEN
        ov_retcode := cv_status_warn;
      END IF;
    END IF;

    /*
    --処理件数の取得
        gn_警告件数 := lv_パージエラー件数;
        gn_正常件数 := gn_対象件数 - gn_警告件数;
    */
    gn_warning_cnt := lv_purge_err_cnt;
    gn_normal_cnt := gn_target_cnt - gn_warning_cnt;
--
  EXCEPTION
    WHEN local_process_expt THEN
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
      ROLLBACK;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errmsg := xxcmn_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_local_others_msg
                    ,iv_token_name1  => cv_token_key
                    ,iv_token_value1 => TO_CHAR(in_purge_set_id)
                   );
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;

  END purgerorder;

  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
--
--#####################  固定ローカル定数変数宣言部 START   ####################
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name                   CONSTANT VARCHAR2(100) := 'submain'; -- プログラム名
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf                     VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode                    VARCHAR2(1);     -- リターン・コード
    lv_errmsg                     VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    --プロファイル値取得用キー
    cv_xxcmn_purge_range_fix      CONSTANT VARCHAR2(100) := 'XXCMN_PURGE_RANGE_FIX';      --パージ期間補正
    cv_xxcmn_purge_range          CONSTANT VARCHAR2(100) := 'XXCMN_PURGE_RANGE';          --パージレンジ
    cv_xxcmn_purgeset_del_period  CONSTANT VARCHAR2(100) := 'XXCMN_PURGESET_DEL_PERIOD';  --パージセット削除期間
    cv_xxcmn_pre_purge_set_name   CONSTANT VARCHAR2(100) := 'XXCMN_PURGESET_NAME_PREFIX'; --パージセット名の先頭文字列
    cv_xxcmn_purgeset_from_day    CONSTANT VARCHAR2(100) := 'XXCMN_PURGESET_FROM_DAY';    --パージセット作成のFromから基準日-パージレンジまでの日数
    cv_xxcmn_commit_range         CONSTANT VARCHAR2(100) := 'XXCMN_COMMIT_RANGE';         --XXCMN:分割コミット数
    cv_xxcmn_org_id               CONSTANT VARCHAR2(100) := 'ORG_ID';                     --営業単位
    cv_purge_type                 CONSTANT VARCHAR2(1)   := '0';                          --パージタイプ（0:パージ処理期間）
    cv_purge_code                 CONSTANT VARCHAR2(30)  := '9601';                       --パージ定義コード
--
    --メッセージ
    cv_get_profile_msg            CONSTANT VARCHAR2(100) := 'APP-XXCMN-10002';  -- プロファイル[ ＆NG_PROFILE ]の取得に失敗しました。
    cv_token_profile              CONSTANT VARCHAR2(100) := 'NG_PROFILE';
    cv_get_period_msg             CONSTANT VARCHAR2(100) := 'APP-XXCMN-11011';  -- パージ期間の取得に失敗しました。
--
    -- *** ローカル変数 ***
    ln_purge_set_id               NUMBER;          --パージセットID
    ln_purge_target_count         NUMBER;           --処理対象件数
--
  BEGIN
--
    -- グローバル変数の初期化
    gn_purgeset_cnt := 0;
    gn_target_cnt   := 0;
    gn_normal_cnt   := 0;
    gn_warning_cnt  := 0;
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
--
    --*********************************************
    --***      MD.050のフロー図を表す           ***
    --***      分岐と処理部の呼び出しを行う     ***
    --*********************************************
--
    --*********************************************************************************
    --値の取得、定義
    --*********************************************************************************
    --(1)処理日を取得する。
    --ld_処理日 := 処理日取得共通関数;
    gd_syori_date := xxcmn_common4_pkg.get_syori_date;
    IF ( gd_syori_date IS NULL ) THEN
      ov_retcode := cv_status_error;
      RAISE local_process_expt;
    END IF;
--
    --(2)パージ期間をルックアップより取得する。
    --gn_パージ期間 := パージ期間取得共通関数(cv_パージ定義コード);
    gn_purge_range          := xxcmn_common4_pkg.get_purge_period(cv_purge_type, cv_purge_code);
    IF ( gn_purge_range IS NULL ) THEN
      ov_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name
                      ,iv_name         => cv_get_period_msg
                     );
      ov_retcode := cv_status_error;
      RAISE local_process_expt;
    END IF;
--
    --gn_コミットレンジ := プロファイルより取得;
    BEGIN
      gn_commit_range  := TO_NUMBER(fnd_profile.value(cv_xxcmn_commit_range));
      IF ( gn_commit_range IS NULL ) THEN
--
        ov_errmsg := xxcmn_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name
                      ,iv_name         => cv_get_profile_msg
                      ,iv_token_name1  => cv_token_profile
                      ,iv_token_value1 => cv_xxcmn_commit_range
                     );
        ov_retcode := cv_status_error;
        RAISE local_process_expt;
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        ov_errmsg := xxcmn_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name
                      ,iv_name         => cv_get_profile_msg
                      ,iv_token_name1  => cv_token_profile
                      ,iv_token_value1 => cv_xxcmn_commit_range
                     );
        ov_retcode := cv_status_error;
        RAISE local_process_expt;
    END;
    FND_FILE.PUT_LINE (FND_FILE.LOG, '分割コミット数:' || TO_CHAR(gn_commit_range));
--
    --ln_パージ期間補正 := プロファイルより取得;
    BEGIN
      gn_purge_range_fix      := TO_NUMBER(fnd_profile.value(cv_xxcmn_purge_range_fix));
      IF ( gn_purge_range_fix IS NULL ) THEN
        ov_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appl_short_name
                        ,iv_name         => cv_get_profile_msg
                        ,iv_token_name1  => cv_token_profile
                        ,iv_token_value1 => cv_xxcmn_purge_range_fix
                       );
        ov_retcode := cv_status_error;
        RAISE local_process_expt;
      END IF;
    EXCEPTION
      --数値でなかった場合、TO_NUMBERのエラーをキャッチしてエラーメッセージ設定
      WHEN OTHERS THEN
        ov_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appl_short_name
                        ,iv_name         => cv_get_profile_msg
                        ,iv_token_name1  => cv_token_profile
                        ,iv_token_value1 => cv_xxcmn_purge_range_fix
                       );
        ov_retcode := cv_status_error;
        RAISE local_process_expt;
    END;
    FND_FILE.PUT_LINE (FND_FILE.LOG, 'パージ期間補正:' || TO_CHAR(gn_purge_range_fix));
--
    --ln_パージレンジ := プロファイルより取得;
    BEGIN
      gn_purge_range_day      := TO_NUMBER(fnd_profile.value(cv_xxcmn_purge_range));
      IF ( gn_purge_range_day IS NULL ) THEN
        ov_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appl_short_name
                        ,iv_name         => cv_get_profile_msg
                        ,iv_token_name1  => cv_token_profile
                        ,iv_token_value1 => cv_xxcmn_purge_range
                       );
        ov_retcode := cv_status_error;
        RAISE local_process_expt;
      END IF;
    EXCEPTION
      --数値でなかった場合、TO_NUMBERのエラーをキャッチしてエラーメッセージ設定
      WHEN OTHERS THEN
        ov_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appl_short_name
                        ,iv_name         => cv_get_profile_msg
                        ,iv_token_name1  => cv_token_profile
                        ,iv_token_value1 => cv_xxcmn_purge_range
                       );
        ov_retcode := cv_status_error;
        RAISE local_process_expt;
    END;
    FND_FILE.PUT_LINE (FND_FILE.LOG, 'パージレンジ:' || TO_CHAR(gn_purge_range_day));
--
    --ln_パージセット削除期間 := プロファイルより取得;
    BEGIN
      gn_purgeset_del_period  := TO_NUMBER(fnd_profile.value(cv_xxcmn_purgeset_del_period));
      IF ( gn_purgeset_del_period IS NULL ) THEN
        ov_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appl_short_name
                        ,iv_name         => cv_get_profile_msg
                        ,iv_token_name1  => cv_token_profile
                        ,iv_token_value1 => cv_xxcmn_purgeset_del_period
                       );
        ov_retcode := cv_status_error;
        RAISE local_process_expt;
      END IF;
    EXCEPTION
      --数値でなかった場合、TO_NUMBERのエラーをキャッチしてエラーメッセージ設定
      WHEN OTHERS THEN
        ov_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appl_short_name
                        ,iv_name         => cv_get_profile_msg
                        ,iv_token_name1  => cv_token_profile
                        ,iv_token_value1 => cv_xxcmn_purgeset_del_period
                       );
        ov_retcode := cv_status_error;
        RAISE local_process_expt;
    END;
    FND_FILE.PUT_LINE (FND_FILE.LOG, 'パージセット削除期間:' || TO_CHAR(gn_purgeset_del_period));
--
    --gn_パージセット処理開始日数       := TO_NUMBER(プロファイルより取得);
    BEGIN
      gn_purgeset_from_day  := TO_NUMBER(fnd_profile.value(cv_xxcmn_purgeset_from_day));
      IF ( gn_purgeset_from_day IS NULL ) THEN
        ov_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appl_short_name
                        ,iv_name         => cv_get_profile_msg
                        ,iv_token_name1  => cv_token_profile
                        ,iv_token_value1 => cv_xxcmn_purgeset_from_day
                       );
        ov_retcode := cv_status_error;
        RAISE local_process_expt;
      END IF;
    EXCEPTION
      --数値でなかった場合、TO_NUMBERのエラーをキャッチしてエラーメッセージ設定
      WHEN OTHERS THEN
        ov_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appl_short_name
                        ,iv_name         => cv_get_profile_msg
                        ,iv_token_name1  => cv_token_profile
                        ,iv_token_value1 => cv_xxcmn_purgeset_from_day
                       );
        ov_retcode := cv_status_error;
        RAISE local_process_expt;
    END;
    FND_FILE.PUT_LINE (FND_FILE.LOG, 'パージセット作成開始日数:' || TO_CHAR(gn_purgeset_from_day));

    --ln_営業単位 := プロファイルより取得;
    gn_org_id               := TO_NUMBER(fnd_profile.value(cv_xxcmn_org_id));
--
    --gv_パージセット名接頭語 := プロファイルより取得;
    gv_pre_purge_set_name               := fnd_profile.value(cv_xxcmn_pre_purge_set_name);
    IF ( gv_pre_purge_set_name IS NULL ) THEN
      ov_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name
                      ,iv_name         => cv_get_profile_msg
                      ,iv_token_name1  => cv_token_profile
                      ,iv_token_value1 => cv_xxcmn_pre_purge_set_name
                     );
      ov_retcode := cv_status_error;
      RAISE local_process_expt;
    END IF;
--
    ln_purge_target_count := 0;
--
    -- ===============================
    -- <パージセット出力処理>を呼び出す
    -- ===============================
    genpurgeset(
      ln_purge_set_id,    --パージセットID(本処理でセットされる)
      lv_errbuf,          -- エラー・メッセージ           --# 固定 #
      lv_retcode,         -- リターン・コード             --# 固定 #
      lv_errmsg);         -- ユーザー・エラー・メッセージ --# 固定 #
--
    IF ( lv_retcode = cv_status_error ) THEN
      --(エラー処理)
      ov_errmsg := lv_errmsg;
      ov_retcode := cv_status_error;
      RAISE local_process_expt;
    ELSIF ( lv_retcode = cv_status_warn ) THEN
      --警告処理
      --submainの終了ステータス(ov_retcode)のセットや
      --エラーメッセージをセットするロジックなどを記述して下さい。
      ov_errmsg := lv_errmsg;
      ov_retcode := cv_status_warn;
    ELSIF ( lv_retcode = cv_status_normal ) THEN
      --正常終了
      NULL;
    ELSE
      --異常な戻り値の場合はエラー
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- <パージセット更新処理>を呼び出す
    -- ===============================
    updpurgeorder(
      ln_purge_set_id,        --パージセットID(本処理で使用される)
      ln_purge_target_count,  --パージ対象件数(本処理で適格='Y'にした件数が戻る)
      lv_errbuf,              -- エラー・メッセージ           --# 固定 #
      lv_retcode,             -- リターン・コード             --# 固定 #
      lv_errmsg);             -- ユーザー・エラー・メッセージ --# 固定 #
--
    IF ( lv_retcode = cv_status_error ) THEN
      --(エラー処理)
      ov_errmsg := lv_errmsg;
      ov_retcode := cv_status_error;
      RAISE local_process_expt;
    ELSIF ( lv_retcode = cv_status_warn ) THEN
      --本処理に警告ステータスは無いので処理無し
      NULL;
    ELSIF ( lv_retcode = cv_status_normal ) THEN
      --正常終了
      NULL;
    ELSE
      --異常な戻り値の場合はエラー
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- 「適格」を'Y'に更新したカウント＞０の場合は
    --  <パージ実行処理>を呼び出す
    -- ===============================
    --適格='Y'にしたレコードが存在する場合のみ本処理を実行する
    IF ( ln_purge_target_count > 0 ) THEN
      purgerorder(
        ln_purge_set_id,   --パージセットID(本処理でセットされる)
        lv_errbuf,         -- エラー・メッセージ           --# 固定 #
        lv_retcode,        -- リターン・コード             --# 固定 #
        lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
--
      IF ( lv_retcode = cv_status_error ) THEN
        --(エラー処理)
        ov_errmsg := lv_errmsg;
        ov_retcode := cv_status_error;
        RAISE local_process_expt;
      ELSIF ( lv_retcode = cv_status_warn ) THEN
        --警告終了時
        ov_retcode := cv_status_warn;
      ELSIF ( lv_retcode = cv_status_normal ) THEN
        --正常終了
        NULL;
      ELSE
        --異常な戻り値の場合はエラー
        RAISE global_process_expt;
      END IF;
    END IF;
  EXCEPTION
      -- *** 任意で例外処理を記述する ****
    WHEN local_process_expt THEN
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      -- カーソルのクローズをここに記述する
--
--#################################  固定例外処理部 START   ###################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
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
    errbuf        OUT VARCHAR2,      --   エラー・メッセージ  --# 固定 #
    retcode       OUT VARCHAR2       --   リターン・コード    --# 固定 #
  )
--
--
--###########################  固定部 START   ###########################
--
  IS
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name        CONSTANT VARCHAR2(100) := 'main';             -- プログラム名
--
    cv_normal_msg      CONSTANT VARCHAR2(100) := '正常終了'; -- 正常終了メッセージ
    cv_warn_msg        CONSTANT VARCHAR2(100) := '警告終了'; -- 警告終了メッセージ
    cv_error_msg       CONSTANT VARCHAR2(100) := 'エラー終了'; -- エラー終了全ロールバック
--
    cv_cnt_msg          CONSTANT VARCHAR2(100) := 'APP-XXCMN-11040';             -- ＆TBL_NAME ＆SHORI 件数： ＆CNT 件
    cv_token_cnt        CONSTANT VARCHAR2(100) := 'CNT';                         -- 件数メッセージ用トークン名（件数）
    cv_token_cnt_table  CONSTANT VARCHAR2(100) := 'TBL_NAME';                    -- 件数メッセージ用トークン名（テーブル名）
    cv_token_cnt_shori  CONSTANT VARCHAR2(100) := 'SHORI';                       -- 件数メッセージ用トークン名（処理名）
    cv_table_cnt_ooha   CONSTANT VARCHAR2(100) := '受注ヘッダ（標準）';                -- 件数メッセージ用テーブル名
    cv_shori_cnt_del    CONSTANT VARCHAR2(100) := '削除';                -- 件数メッセージ用処理名
    cv_shori_cnt_target CONSTANT VARCHAR2(100) := '対象';                -- 件数メッセージ用処理名
    cv_shori_cnt_normal CONSTANT VARCHAR2(100) := '成功';                -- 件数メッセージ用処理名
    cv_shori_cnt_error  CONSTANT VARCHAR2(100) := '失敗';                -- 件数メッセージ用処理名
--
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf          VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode         VARCHAR2(1);     -- リターン・コード
    lv_errmsg          VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
    lv_message_code    VARCHAR2(100);   -- 終了メッセージコード
    --
  BEGIN
--
--###########################  固定部 START   #####################################################
--
    -- 固定出力
    -- コンカレントヘッダメッセージ出力関数の呼び出し
    xxccp_common_pkg.put_log_header(
       ov_retcode => lv_retcode
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
       lv_errbuf   -- エラー・メッセージ           --# 固定 #
      ,lv_retcode  -- リターン・コード             --# 固定 #
      ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    --エラー出力
    IF (lv_retcode = cv_status_error) THEN
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg --ユーザー・エラーメッセージ
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --エラーメッセージ
      );
    END IF;
    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    
    /*
    --対象件数出力：gn_対象件数
    --成功件数出力：gn_正常件数
    --エラー件数出力：gn_警告件数
    */
    --対象件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_cnt_msg
                    ,iv_token_name1  => cv_token_cnt_table
                    ,iv_token_value1 => cv_table_cnt_ooha
                    ,iv_token_name2  => cv_token_cnt_shori
                    ,iv_token_value2 => cv_shori_cnt_del || cv_shori_cnt_target
                    ,iv_token_name3  => cv_token_cnt
                    ,iv_token_value3 => TO_CHAR(gn_target_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --成功件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_cnt_msg
                    ,iv_token_name1  => cv_token_cnt_table
                    ,iv_token_value1 => cv_table_cnt_ooha
                    ,iv_token_name2  => cv_token_cnt_shori
                    ,iv_token_value2 => cv_shori_cnt_del || cv_shori_cnt_normal
                    ,iv_token_name3  => cv_token_cnt
                    ,iv_token_value3 => TO_CHAR(gn_normal_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --エラー件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_cnt_msg
                    ,iv_token_name1  => cv_token_cnt_table
                    ,iv_token_value1 => cv_table_cnt_ooha
                    ,iv_token_name2  => cv_token_cnt_shori
                    ,iv_token_value2 => cv_shori_cnt_del || cv_shori_cnt_error
                    ,iv_token_name3  => cv_token_cnt
                    ,iv_token_value3 => TO_CHAR(gn_warning_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    --終了メッセージ
    IF (lv_retcode = cv_status_normal) THEN
      gv_out_msg := cv_normal_msg;
    ELSIF(lv_retcode = cv_status_warn) THEN
      gv_out_msg := cv_warn_msg;
    ELSIF(lv_retcode = cv_status_error) THEN
      gv_out_msg := cv_error_msg;
    END IF;
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
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
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
  END main;
END xxcmn960010c;
/
