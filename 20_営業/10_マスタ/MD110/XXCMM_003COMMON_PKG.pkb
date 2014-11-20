CREATE OR REPLACE PACKAGE BODY xxcmm_003common_pkg
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name           : xxcmm_003common_pkg(body)
 * Description            :
 * MD.110                 : MD110_CMM_顧客_共通関数
 * Version                : 1.0
 *
 * Program List
 *  --------------------      ---- ----- --------------------------------------------------
 *   Name                     Type  Ret   Description
 *  --------------------      ---- ----- --------------------------------------------------
 *  cust_status_update_check  F           顧客ステータス更新可否チェック
 *  update_hz_party           P           パーティマスタ更新用関数
 *  cust_name_kana_check      F           顧客名称・顧客名称カナチェック
 *  cust_site_check           F           顧客所在地全角半角チェック
 *
 * Change Record
 * ------------ ----- ---------------- -----------------------------------------------
 *  Date         Ver.  Editor           Description
 * ------------ ----- ---------------- -----------------------------------------------
 *  2009-01-30    1.0  Yuuki.Nakamura   新規作成
 *  2009-02-26    1.1  Yutaka.Kuboshima パーティマスタ更新関数追加
 *  2009-03-26    1.2  Yutaka.Kuboshima 顧客名称・顧客名称カナチェック
 *                                      顧客所在地全角半角チェック追加
 *****************************************************************************************/
  -- ===============================
  -- グローバル変数
  -- ===============================
  cv_msg_part     CONSTANT VARCHAR2(100) := ' : ';
  cv_msg_cont     CONSTANT VARCHAR2(3)   := '.';
--
  cv_pkg_name     CONSTANT VARCHAR2(100) := 'XXCMM_003COMMON_PKG';              -- パッケージ名
  cv_cnst_period  CONSTANT VARCHAR2(1)   := '.';                                -- ピリオド
--
  cv_success      CONSTANT VARCHAR2(1)   := xxccp_common_pkg.set_status_normal; -- 正常:0
  cv_error        CONSTANT VARCHAR2(1)   := xxccp_common_pkg.set_status_error;  -- 異常:2
  cv_success_api  CONSTANT VARCHAR2(1)   := 'S';                                -- API成功時返却ステータス
  cv_user_entered CONSTANT VARCHAR2(12)  := 'USER_ENTERED';                     --パーティマスタ更新ＡＰＩコンテンツソースタイプ
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
--
  /**********************************************************************************
   * Function  Name   : cust_status_update_allow
   * Description      : 顧客ステータス更新可否チェック
   ***********************************************************************************/
  --リターンコードnormalのとき更新可能。リターンコードerrorのとき更新不可。
  FUNCTION cust_status_update_allow(iv_cust_class        IN VARCHAR2  -- 顧客区分
                                   ,iv_cust_status       IN VARCHAR2  -- 顧客ステータス（変更前）
                                   ,iv_cust_will_status  IN VARCHAR2) -- 顧客ステータス（変更後）
    RETURN VARCHAR2
  IS
    -- ===============================
    -- ローカル定数
    -- ===============================
    cv_kyoten         CONSTANT VARCHAR2(1) := '1';
    cv_out_cust       CONSTANT VARCHAR2(2) := '99';
    cv_rectif_credit  CONSTANT VARCHAR2(2) := '80';
    cv_stop_approved  CONSTANT VARCHAR2(2) := '90';
    cv_mc             CONSTANT VARCHAR2(2) := '20';
    cv_sp_approved    CONSTANT VARCHAR2(2) := '25';
    cv_approved       CONSTANT VARCHAR2(2) := '30';
    cv_cust           CONSTANT VARCHAR2(2) := '40';
    cv_rested         CONSTANT VARCHAR2(2) := '50';
    cv_customer       CONSTANT VARCHAR2(2) := '10';
    cv_su_customer    CONSTANT VARCHAR2(2) := '12';
    cv_trust_corp     CONSTANT VARCHAR2(2) := '13';
    cv_ar_manage      CONSTANT VARCHAR2(2) := '14';
    cv_root           CONSTANT VARCHAR2(2) := '15';
    cv_wholesale      CONSTANT VARCHAR2(2) := '16';
    cv_planning       CONSTANT VARCHAR2(2) := '17';
    cv_edi            CONSTANT VARCHAR2(2) := '18';
    cv_hyakka         CONSTANT VARCHAR2(2) := '19';
    -- ===============================
    -- ローカル変数
    -- ===============================
  --
  BEGIN
    IF (iv_cust_status = iv_cust_will_status) THEN
      RETURN cv_success;
    ELSIF (iv_cust_class = cv_kyoten) THEN
      IF (iv_cust_status = cv_out_cust) AND (iv_cust_will_status = cv_stop_approved) THEN
        RETURN cv_success;
      END IF;
    ELSIF (iv_cust_class = cv_customer) THEN
      IF (iv_cust_status = cv_mc) AND (iv_cust_will_status = cv_stop_approved) THEN
        RETURN cv_success;
      ELSIF (iv_cust_status = cv_sp_approved) AND (iv_cust_will_status = cv_stop_approved)  THEN
        RETURN cv_success;
      ELSIF (iv_cust_status = cv_approved) AND (iv_cust_will_status = cv_stop_approved)  THEN
        RETURN cv_success;
      ELSIF (iv_cust_status = cv_cust) AND ((iv_cust_will_status = cv_rested) OR (iv_cust_will_status = cv_rectif_credit) OR (iv_cust_will_status = cv_stop_approved)) THEN
        RETURN cv_success;
      ELSIF (iv_cust_status = cv_rested) AND ((iv_cust_will_status = cv_mc) OR (iv_cust_will_status = cv_cust) OR (iv_cust_will_status = cv_rectif_credit) OR (iv_cust_will_status = cv_stop_approved)) THEN
        RETURN cv_success;
      ELSIF (iv_cust_status = cv_rectif_credit) AND (iv_cust_will_status = cv_stop_approved)  THEN
        RETURN cv_success;
      END IF;
    ELSIF (iv_cust_class = cv_su_customer) THEN
      IF (iv_cust_status = cv_approved) AND (iv_cust_will_status = cv_stop_approved) THEN
        RETURN cv_success;
      ELSIF (iv_cust_status = cv_cust) AND (iv_cust_will_status = cv_stop_approved) THEN
        RETURN cv_success;
      END IF;
    ELSIF (iv_cust_class = cv_trust_corp) THEN
      IF (iv_cust_status = cv_out_cust) AND (iv_cust_will_status = cv_rectif_credit) THEN
        RETURN cv_success;
      ELSIF (iv_cust_status = cv_rectif_credit) AND (iv_cust_will_status = cv_stop_approved) THEN
        RETURN cv_success;
      ELSIF (iv_cust_status = cv_out_cust) AND (iv_cust_will_status = cv_stop_approved) THEN
        RETURN cv_success;
      END IF;
    ELSIF (iv_cust_class = cv_ar_manage) THEN
      IF (iv_cust_status = cv_out_cust) AND (iv_cust_will_status = cv_rectif_credit) THEN
        RETURN cv_success;
      ELSIF (iv_cust_status = cv_rectif_credit) AND (iv_cust_will_status = cv_stop_approved) THEN
        RETURN cv_success;
      ELSIF (iv_cust_status = cv_out_cust) AND (iv_cust_will_status = cv_stop_approved) THEN
        RETURN cv_success;
      END IF;
    ELSIF ((iv_cust_class = cv_root) OR (iv_cust_class = cv_wholesale) OR (iv_cust_class = cv_planning) OR (iv_cust_class = cv_edi) OR (iv_cust_class = cv_hyakka)) THEN
      IF (iv_cust_status = cv_out_cust) AND (iv_cust_will_status = cv_stop_approved) THEN
        RETURN cv_success;
      END IF;
    END IF;
    RETURN cv_error;
  END cust_status_update_allow;
  /**********************************************************************************
   * Procedure  Name  : update_hz_party
   * Description      : パーティマスタ更新関数
   ***********************************************************************************/
  PROCEDURE update_hz_party(in_party_id    IN  NUMBER,    -- パーティID
                            iv_cust_status IN  VARCHAR2,  -- 顧客ステータス
                            ov_errbuf      OUT VARCHAR2,  -- エラー・メッセージ           --# 固定 #
                            ov_retcode     OUT VARCHAR2,  -- リターン・コード             --# 固定 #
                            ov_errmsg      OUT VARCHAR2)  -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ローカル定数
    cv_prg_name                       CONSTANT VARCHAR2(100) := 'update_hz_party'; -- プログラム名
    cv_init_list_api                  CONSTANT VARCHAR2(1)   := 'T';               -- API起動初期リスト設定値
    -- ローカル変数
    lv_return_status                  VARCHAR2(5000);
    ln_msg_count                      NUMBER;
    lv_msg_data                       VARCHAR2(5000);
    lv_retcode                        VARCHAR2(1);
    lv_errmsg                         VARCHAR2(5000);
    ln_party_id                       NUMBER;
    lv_content_source_type            VARCHAR2(12);
    p_party_rec                       hz_party_v2pub.party_rec_type;
    p_organization_rec                hz_party_v2pub.organization_rec_type;
    ln_party_object_version_number    NUMBER;
    ln_profile_id                     NUMBER;
    -- カーソル宣言
    -- パーティマスタオブジェクトナンバー取得カーソル
    CURSOR get_party_object_number_cur
    IS
      SELECT hp.object_version_number object_version_number
      FROM hz_parties hp
      WHERE hp.party_id = in_party_id;
    -- パーティマスタオブジェクトナンバー取得レコード型
    get_party_object_number_rec get_party_object_number_cur%ROWTYPE;
  BEGIN
    --パーティID設定
    ln_party_id := in_party_id;
    -- オブジェクトナンバー取得
    OPEN get_party_object_number_cur;
    FETCH get_party_object_number_cur INTO get_party_object_number_rec;
    CLOSE get_party_object_number_cur;
    -- コンテントソースタイプ設定
    lv_content_source_type := cv_user_entered;
    --組織情報取得API
    hz_party_v2pub.get_organization_rec(cv_init_list_api,
                                        ln_party_id,
                                        lv_content_source_type,
                                        p_organization_rec,
                                        lv_return_status,
                                        ln_msg_count,
                                        lv_msg_data);
    -- エラー発生時
    IF (lv_return_status <> cv_success_api) THEN
      RAISE global_api_expt;
    END IF;
    --パーティ情報取得API
    hz_party_v2pub.get_party_rec(cv_init_list_api,
                                 ln_party_id,
                                 p_party_rec,
                                 lv_return_status,
                                 ln_msg_count,
                                 lv_msg_data);
    --パーティ情報更新値設定
    -- エラー発生時
    IF (lv_return_status <> cv_success_api) THEN
      RAISE global_api_expt;
    END IF;
    --顧客ステータス設定
    p_organization_rec.duns_number_c := iv_cust_status;
    -- オブジェクトナンバー設定
    ln_party_object_version_number   := get_party_object_number_rec.object_version_number;
    --パーティ情報設定
    p_organization_rec.party_rec     := p_party_rec;
    --パーティマスタ更新API呼び出し
    hz_party_v2pub.update_organization(cv_init_list_api,
                                       p_organization_rec,
                                       ln_party_object_version_number,
                                       ln_profile_id,
                                       lv_return_status,
                                       ln_msg_count,
                                       lv_msg_data);
    -- エラー発生時
    IF (lv_return_status <> cv_success_api) THEN
      RAISE global_api_expt;
    END IF;
    ov_retcode := cv_success;
  EXCEPTION
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_msg_data;
      ov_errbuf  := SUBSTRB(cv_pkg_name || cv_msg_cont|| cv_prg_name || cv_msg_part || lv_msg_data, 1, 5000);
      ov_retcode := cv_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(cv_pkg_name || cv_cnst_period || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000), TRUE);
  END update_hz_party;
  /**********************************************************************************
   * Function  Name   : cust_name_kana_check
   * Description      : 顧客名称・顧客名称カナチェック
   ***********************************************************************************/
  --顧客名称・顧客名称カナチェック。リターンコードnormalのとき正常。リターンコードerrorのときエラー。
  FUNCTION cust_name_kana_check(iv_cust_name_mir           IN VARCHAR2   -- 顧客名称
                               ,iv_cust_name_phonetic_mir  IN VARCHAR2)  -- 顧客名称カナ
    RETURN VARCHAR2
  IS
    -- ===============================
    -- ローカル定数
    -- ===============================
    -- ===============================
    -- ローカル変数
    -- ===============================
  --
  BEGIN
    IF     NVL(xxccp_common_pkg.chk_double_byte(iv_cust_name_mir),TRUE)
      AND  NVL(xxccp_common_pkg.chk_single_byte(iv_cust_name_phonetic_mir),TRUE) THEN
      RETURN cv_success;
    END IF;
    RETURN cv_error;
  END cust_name_kana_check;
--
  /**********************************************************************************
   * Function  Name   : cust_site_check
   * Description      : 顧客所在地全角半角チェック
   ***********************************************************************************/
  --顧客所在地全角半角チェック。リターンコードnormalのとき正常。リターンコードerrorのときエラー。
  FUNCTION cust_site_check(iv_cust_site IN VARCHAR2)  -- 顧客所在地文字列
    RETURN VARCHAR2
  IS
    -- ===============================
    -- ローカル定数
    -- ===============================
    cv_dot        CONSTANT VARCHAR2(1) := '.';
    cv_escape_dot CONSTANT VARCHAR2(2) := '\.';
  --
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_cust_site VARCHAR2(3000) := NULL;
  --
  BEGIN
    --エスケープシーケンスの\.を文字列から除去
    lv_cust_site := REPLACE(iv_cust_site, cv_escape_dot);
    IF   (xxccp_common_pkg.chk_number(xxccp_common_pkg.char_delim_partition(  lv_cust_site
                                                                              ,cv_dot
                                                                              ,1))
      AND LENGTHB(xxccp_common_pkg.char_delim_partition( lv_cust_site
                                                        ,cv_dot
                                                        ,1)) = 7)
      AND xxccp_common_pkg.chk_tel_format(xxccp_common_pkg.char_delim_partition(  lv_cust_site
                                                                                 ,cv_dot
                                                                                 ,7))
      AND xxccp_common_pkg.chk_double_byte(xxccp_common_pkg.char_delim_partition(  lv_cust_site
                                                                                  ,cv_dot
                                                                                  ,2))
      AND xxccp_common_pkg.chk_double_byte(xxccp_common_pkg.char_delim_partition(  lv_cust_site
                                                                                  ,cv_dot
                                                                                  ,3))
      AND xxccp_common_pkg.chk_double_byte(xxccp_common_pkg.char_delim_partition(  lv_cust_site
                                                                                  ,cv_dot
                                                                                  ,4))
      AND nvl(xxccp_common_pkg.chk_double_byte(xxccp_common_pkg.char_delim_partition(  lv_cust_site
                                                                                      ,cv_dot
                                                                                      ,5)),TRUE) THEN
      RETURN cv_success;
    END IF;
    RETURN cv_error;
  END cust_site_check;
END xxcmm_003common_pkg;