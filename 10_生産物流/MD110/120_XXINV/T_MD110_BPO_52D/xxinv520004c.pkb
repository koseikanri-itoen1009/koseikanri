CREATE OR REPLACE PACKAGE BODY xxinv520004c
AS
/*****************************************************************************
* パッケージ名：xxinv520004c
* 機能概要　　：工順マスタ登録(品目振替予定)
* バージョン　：1.0
* 作成者　　　：二瓶 大輔
* 作成日　　　：2008/11/17
* 変更者　　　：
* 最終変更日　：
* 修正内容　　：
* 
*****************************************************************************/
--
  --==========================================================================
  --  グローバル定数
  --==========================================================================
  gv_status_normal        CONSTANT VARCHAR2(1)    := '0';    --正常
  gv_status_warn          CONSTANT VARCHAR2(1)    := '1';    --警告
  gv_status_error         CONSTANT VARCHAR2(1)    := '2';    --失敗
  gv_pkg_name             CONSTANT VARCHAR2(30)   := 'xxinv520004c';
--
  gv_fml_sts_new          CONSTANT VARCHAR2(4)    := '100';  -- 新規
  gv_fml_sts_appr         CONSTANT VARCHAR2(4)    := '700';  -- 一般使用の承認
--
  gv_msg_kbn_inv          CONSTANT VARCHAR2(5)    := 'XXINV';
-- メッセージ番号
  gv_msg_52a_00           CONSTANT VARCHAR2(15)   := 'APP-XXINV-10000'; -- APIエラー
  gv_tkn_api_name         CONSTANT VARCHAR2(15)   := 'API_NAME';
--
  gv_tkn_upd_routing      CONSTANT VARCHAR2(20)   := '工順更新';
--
  --==========================================================================
  --  グローバル変数
  --==========================================================================
  gn_total_cnt            NUMBER  := 0;
--
  gv_proc_name            VARCHAR2(100);
--
  --==========================================================================
  --  グローバル例外
  --==========================================================================
  sub_func_expt    EXCEPTION;
  oprn_id_err      EXCEPTION;
  --*** 共通関数例外 ***
  global_api_expt  EXCEPTION;
--
  /***************************************************************************
  * PUROCEDURE名：submain
  * 機能概要　　：工順マスタ登録処理メイン
  * 引数　　　　：
  *               OUT  ov_ret_status               リターン・ステータス
  *               OUT  ov_err_msg                  エラー・メッセージ
  * 注意事項　　：
  ***************************************************************************/
  PROCEDURE submain(
    ov_ret_status  OUT VARCHAR2
  , ov_err_msg     OUT VARCHAR2
  )
  IS
--
    --========================================================================
    --  ローカル変数
    --========================================================================
    lv_ret_status                VARCHAR2(1)   ;     --  リターン・ステータス
    -- INSERT_FORMULA API用変数
    lv_return_status             VARCHAR2(2)   ;
    ln_message_count             NUMBER        ;
    lv_msg_date                  VARCHAR2(2000);
    -- MODIFY_STATUS API用変数
    lv_msg_list                  VARCHAR2(2000);
    --********************
    -- 工順マスタ情報
    --********************
    lt_routing_no                gmd_routings_b.routing_no%TYPE;              -- 工順No
    lt_routings_step_tab         gmd_routings_pub.gmd_routings_step_tab;      -- 工順配列
    lt_routings_step_dep_tab     gmd_routings_pub.gmd_routings_step_dep_tab;  -- ダミー工順配列
    routings_b_rec               gmd_routings%rowtype;                        -- 工順データ格納用
    ln_oprn_id                   gmd_operations_b.oprn_id%type;               -- 工程ID格納用
--
    --========================================================================
    --  エラー処理
    --========================================================================
    lv_err_msg                   VARCHAR2(2000);  --  エラー・メッセージ
--
    --========================================================================
    --  保管場所情報の抽出
    --========================================================================
    CURSOR  locations_cur
    IS
      SELECT xilv.segment1  location        -- 納品場所
           , xilv.whse_code whse_code       -- 納品倉庫
      FROM   xxcmn_item_locations_v xilv
      WHERE  NOT EXISTS (SELECT 1
                         FROM   gmd_routings_b x
                         WHERE  x.routing_no = '9' || xilv.segment1 )
      ORDER BY xilv.segment1
      ;
--
    --========================================================================
    --  工程ID取得
    --========================================================================
    CURSOR lc_oprn_id
    IS
      SELECT oprn_id
      FROM   gmd_operations_b gob
      WHERE  gob.oprn_no = '900' -- 品目振替
      ;
--
  BEGIN
    --========================================================================
    --  OUTパラメータの初期化
    --========================================================================
    ov_ret_status :=  gv_status_normal;
    ov_err_msg    :=  NULL;
--
    --========================================================================
    --  工程ID取得
    --========================================================================
    OPEN  lc_oprn_id;
    FETCH lc_oprn_id INTO ln_oprn_id;
    IF ( lc_oprn_id%NOTFOUND ) THEN
      CLOSE lc_oprn_id;
      RAISE oprn_id_err;
    END IF;
    CLOSE lc_oprn_id;
--
    -----------------------------
    --  工順マスタ情報  編集(固定部分)
    -----------------------------
    routings_b_rec.owner_orgn_code          := '2020';                  -- 所有者組織コード
    routings_b_rec.process_loss             := 0;
    routings_b_rec.routing_vers             := 1;                       -- 工順バージョン
    routings_b_rec.routing_desc             := '品目振替';              -- 摘要(「NULL」固定)
    routings_b_rec.routing_class            := '70';                    -- 工順区分(「70：品目振替」固定)
    routings_b_rec.routing_qty              := 1;                       -- 数量(「1」固定)
    routings_b_rec.item_um                  := 'kg';                    -- 単位(「kg」固定)
    routings_b_rec.attribute1               := '品目振替';              -- ライン名・略称(「品目振替」固定)
    routings_b_rec.attribute2               := '1';                     -- ライン区分(「1：自社ライン」固定)
    routings_b_rec.attribute13              := '31';                    -- 伝票区分(「31：再　製」固定)
    routings_b_rec.attribute14              := '2191';                  -- 成績管理部署(「2191：仕入管理課」固定)
    routings_b_rec.attribute15              := '1';                     -- 内外区分(「1：自社」固定)
    routings_b_rec.attribute16              := '2';                     -- 製造品区分(「2：リーフ」固定)
    routings_b_rec.attribute17              := 'N';                     -- 新缶煎区分(「N」固定)
    routings_b_rec.attribute18              := 'N';                     -- 送信対象フラグ(「N」固定)
    routings_b_rec.attribute19              := 'ZZZZ';                  -- 固有記号(「ZZZZ」固定)
    routings_b_rec.effective_start_date     := TO_DATE('20080401', 'YYYY/MM/DD');
--
    -----------------------------
    --  工程情報  編集(固定部分)
    -----------------------------
    lt_routings_step_tab(1).routingstep_no  := 10;          --工順詳細番号
    lt_routings_step_tab(1).oprn_id         := ln_oprn_id;  --工程ID
--
    --========================================================================
    --  工順マスタ情報の抽出
    --========================================================================
    FOR locations_rec IN locations_cur LOOP
      --全体件数のカウントアップ
      gn_total_cnt := gn_total_cnt + 1;
      --キー項目格納
      lt_routing_no := '9' || locations_rec.location;
      -----------------------------
      --  工順マスタ情報  編集(変動部分)
      -----------------------------
      routings_b_rec.routing_no   := lt_routing_no;           -- 工順No
      routings_b_rec.attribute9   := locations_rec.location;  -- 納品場所
      routings_b_rec.attribute21  := locations_rec.whse_code; -- 納品倉庫
--
      -----------------------------
      --  工順登録(EBS標準API)
      -----------------------------
      GMD_ROUTINGS_PUB.INSERT_ROUTING(
          p_api_version           => 1.0                      -- APIバージョン番号
        , p_init_msg_list         => TRUE                     -- メッセージ初期化フラグ
        , p_commit                => FALSE                    -- 自動コミットフラグ
        , p_routings              => routings_b_rec           -- 工順テーブル
        , p_routings_step_tbl     => lt_routings_step_tab     -- 工順配列
        , p_routings_step_dep_tbl => lt_routings_step_dep_tab -- ダミー工順配列
        , x_message_count         => ln_message_count         -- エラーメッセージ件数
        , x_message_list          => lv_msg_list              -- エラーメッセージ
        , x_return_status         => lv_return_status         -- プロセス終了ステータス
          );
      -- ステータス変更処理が成功でない場合
      IF ( lv_return_status  <>  fnd_api.g_ret_sts_success ) THEN
--
        FOR cnt IN 1..ln_message_count LOOP
          lv_msg_date := fnd_msg_pub.get(cnt ,'F');
          DBMS_OUTPUT.PUT_LINE('EBS標準API:' || lv_msg_date);
        END loop;
--
        lv_err_msg     := 'ERR:工順マスタ登録(EBS標準API)(' || gv_proc_name || ')' || '(キー項目:ライン№=' || lt_routing_no || ')';
        lv_ret_status  := gv_status_error;
        RAISE sub_func_expt;
      END IF;
--
      BEGIN
        -- 工順IDの取得
        SELECT grb.routing_id
        INTO   routings_b_rec.routing_id
        FROM   gmd_routings_b grb   -- 工順マスタ
        WHERE  grb.routing_no = lt_routing_no
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          RAISE global_api_expt;
      END;
--
      -----------------------------
      -- 工順ステータス変更(EBS標準API)
      -----------------------------
      GMD_STATUS_PUB.MODIFY_STATUS(
          p_api_version    => 1.0
        , p_init_msg_list  => TRUE
        , p_entity_name    => 'ROUTING'
        , p_entity_id      => routings_b_rec.routing_id
        , p_entity_no      => NULL            -- (NULL固定)
        , p_entity_version => NULL            -- (NULL固定)
        , p_to_status      => gv_fml_sts_appr
        , p_ignore_flag    => FALSE
        , x_message_count  => ln_message_count
        , x_message_list   => lv_msg_list
        , x_return_status  => lv_return_status
          );
--
      -- ステータス変更処理が成功でない場合
      IF ( lv_return_status <> fnd_api.g_ret_sts_success ) THEN
        lv_err_msg    := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv
                                                , gv_msg_52a_00
                                                , gv_tkn_api_name
                                                , gv_tkn_upd_routing);
        lv_ret_status := gv_status_error;
        RAISE global_api_expt;
      -- ステータス変更処理が成功の場合
      ELSIF ( lv_return_status = fnd_api.g_ret_sts_success ) THEN
        -- 確定処理
        COMMIT;
      END IF;
--
    END LOOP;
--
  EXCEPTION
    WHEN oprn_id_err THEN
      IF ( locations_cur%ISOPEN ) THEN
          CLOSE  locations_cur;
      END IF;
      ov_err_msg     := 'ERR:工程ID取得失敗(' 
                        || gv_proc_name || ')' || '(キー項目:ライン№=' || lt_routing_no || ')' || SQLCODE || ':' || SQLERRM ;
      ov_ret_status  := gv_status_error;
    WHEN global_api_expt THEN
      IF ( locations_cur%ISOPEN ) THEN
        CLOSE  locations_cur;
      END IF;
      ov_err_msg     := 'ERR:妥当性ルールステータス変更(EBS標準API)失敗(' 
                        || gv_proc_name || ')' || '(キー項目:ライン№=' || lt_routing_no || ')' || SQLCODE || ':' || SQLERRM ;
      ov_ret_status  := gv_status_error;
    WHEN sub_func_expt THEN
      IF ( locations_cur%ISOPEN ) THEN
        CLOSE  locations_cur;
      END IF;
      ov_err_msg     :=  lv_err_msg;
      ov_ret_status  :=  lv_ret_status;
    WHEN OTHERS THEN
      IF ( locations_cur%ISOPEN ) THEN
        CLOSE  locations_cur;
      END IF;
      ov_err_msg     := lv_err_msg;
      ov_ret_status  := lv_ret_status;
--
  END submain;
--
  /***************************************************************************
  * PUROCEDURE名：main
  * 機能概要　　：工順マスタ登録
  * 引数　　　　：
  * 注意事項　　：
  ***************************************************************************/
  PROCEDURE main
  IS
--
    --========================================================================
    --  エラー処理
    --========================================================================
    ln_ret_status         NUMBER;          --  リターン・ステータス
    lv_err_msg            VARCHAR2(2000);  --  エラー・メッセージ
--
  BEGIN
--
    gn_total_cnt      := 0;
--
    --=======================================================================
    --  コンカレントヘッダログ出力
    --=======================================================================
    DBMS_OUTPUT.PUT_LINE('========== START:' || gv_pkg_name || ':工順マスタ登録  ==========');
--
    --========================================================================
    --  submain 処理
    --========================================================================
    gv_proc_name  :=  'submain';
    submain(
      ov_ret_status  => ln_ret_status
    , ov_err_msg     => lv_err_msg
      );
    IF ( ln_ret_status <> gv_status_normal ) THEN
      RAISE sub_func_expt;
    END IF;
--
    --========================================================================
    --  コンカレントフッダログ出力
    --========================================================================
    DBMS_OUTPUT.PUT_LINE('戻り値                    :' || gv_status_normal); --  リターン・コード（正常）
    DBMS_OUTPUT.PUT_LINE('処理件数(routings )       :' || gn_total_cnt);
    DBMS_OUTPUT.PUT_LINE('========== END  :' || gv_pkg_name || ':工順マスタ登録  ==========');
--
  EXCEPTION
    WHEN sub_func_expt THEN
      DBMS_OUTPUT.PUT_LINE('戻り値                    :' || gv_status_error); --  リターン・コード（異常）
      DBMS_OUTPUT.PUT_LINE('エラーバッファ            :' || lv_err_msg);
      DBMS_OUTPUT.PUT_LINE('処理件数(routings )       :' || gn_total_cnt);
      DBMS_OUTPUT.PUT_LINE('========== END  :' || gv_pkg_name || ':工順マスタ登録  ==========');
      ROLLBACK;
    WHEN OTHERS THEN
      lv_err_msg  := 'ERR:工順マスタ登録(EBS標準API)' || gv_pkg_name || ':' || SQLCODE || ':' || SQLERRM ;
      DBMS_OUTPUT.PUT_LINE('戻り値                    :' || gv_status_error); --  リターン・コード（異常）
      DBMS_OUTPUT.PUT_LINE('エラーバッファ            :' || lv_err_msg);
      DBMS_OUTPUT.PUT_LINE('処理件数(routings )       :' || gn_total_cnt);
      DBMS_OUTPUT.PUT_LINE('========== END  :' || gv_pkg_name || ':工順マスタ登録  ==========');
      ROLLBACK;
  END main;
--
END xxinv520004c;
/
