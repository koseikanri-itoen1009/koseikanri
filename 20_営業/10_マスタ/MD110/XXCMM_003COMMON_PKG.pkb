CREATE OR REPLACE PACKAGE BODY xxcmm_003common_pkg
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name           : xxcmm_003common_pkg(body)
 * Description            :
 * MD.110                 : MD110_CMM_顧客_共通関数
 * Version                : 1.10
 *
 * Program List
 *  --------------------      ---- ----- --------------------------------------------------
 *   Name                     Type  Ret   Description
 *  --------------------      ---- ----- --------------------------------------------------
 *  cust_status_update_check   F          顧客ステータス更新可否チェック
 *  update_hz_party            P          パーティマスタ更新用関数
 *  cust_name_kana_check       F          顧客名称・顧客名称カナチェック
 *  cust_site_check            F          顧客所在地全角半角チェック
 *  cust_required_check        P          顧客必須項目チェック
 *
 * Change Record
 * ------------ ----- ---------------- -----------------------------------------------
 *  Date         Ver.  Editor           Description
 * ------------ ----- ---------------- -----------------------------------------------
 *  2009/01/30    1.0  Yuuki.Nakamura   新規作成
 *  2009/02/26    1.1  Yutaka.Kuboshima パーティマスタ更新関数追加
 *  2009/03/26    1.2  Yutaka.Kuboshima 顧客名称・顧客名称カナチェック
 *                                      顧客所在地全角半角チェック追加
 *  2009/04/07    1.3  Yutaka.Kuboshima 障害T1_0303の対応
 *  2009/05/22    1.4  Yutaka.Kuboshima 障害T1_1089の対応
 *  2009/06/19    1.5  Yutaka.Kuboshima 障害T1_1500の対応
 *  2009/07/14    1.6  Yutaka.Kuboshima 統合テスト障害0000674の対応
 *  2009/07/15    1.7  Yutaka.Kuboshima 統合テスト障害0000648の対応
 *  2009/09/15    1.8  Yutaka.Kuboshima 統合テスト障害0001350の対応
 *  2009/10/30    1.9  Yutaka.Kuboshima 障害E_T4_00100の対応
 *  2009/11/26    1.10 Yutaka.Kuboshima 障害E_本稼動_00106の対応
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
-- 2009/04/07 Ver1.3 add start by Yutaka.Kuboshima
    cv_mc_candidates  CONSTANT VARCHAR2(2) := '10';
-- 2009/04/07 Ver1.3 add end by Yutaka.Kuboshima
    cv_customer       CONSTANT VARCHAR2(2) := '10';
    cv_su_customer    CONSTANT VARCHAR2(2) := '12';
    cv_trust_corp     CONSTANT VARCHAR2(2) := '13';
    cv_ar_manage      CONSTANT VARCHAR2(2) := '14';
    cv_root           CONSTANT VARCHAR2(2) := '15';
    cv_wholesale      CONSTANT VARCHAR2(2) := '16';
    cv_planning       CONSTANT VARCHAR2(2) := '17';
    cv_edi            CONSTANT VARCHAR2(2) := '18';
    cv_hyakka         CONSTANT VARCHAR2(2) := '19';
-- 2009/09/15 Ver1.8 add start by Yutaka.Kuboshima
    cv_seikyu         CONSTANT VARCHAR2(2) := '20';
    cv_tokatu         CONSTANT VARCHAR2(2) := '21';
-- 2009/09/15 Ver1.8 add end by Yutaka.Kuboshima
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
-- 2009/07/14 Ver1.6 modify start by Yutaka.Kuboshima
--      ELSIF (iv_cust_status = cv_rested) AND ((iv_cust_will_status = cv_mc) OR (iv_cust_will_status = cv_cust) OR (iv_cust_will_status = cv_rectif_credit) OR (iv_cust_will_status = cv_stop_approved)) THEN
      ELSIF (iv_cust_status = cv_rested) AND ((iv_cust_will_status = cv_cust) OR (iv_cust_will_status = cv_rectif_credit) OR (iv_cust_will_status = cv_stop_approved)) THEN
-- 2009/07/14 Ver1.6 modify end by Yutaka.Kuboshima
        RETURN cv_success;
      ELSIF (iv_cust_status = cv_rectif_credit) AND (iv_cust_will_status = cv_stop_approved)  THEN
        RETURN cv_success;
-- 2009/04/07 Ver1.3 add start by Yutaka.Kuboshima
      ELSIF (iv_cust_status = cv_mc_candidates) AND (iv_cust_will_status = cv_stop_approved)  THEN
        RETURN cv_success;
-- 2009/04/07 Ver1.3 add end by Yutaka.Kuboshima
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
-- 2009/09/15 Ver1.8 modify start by Yutaka.Kuboshima
--    ELSIF ((iv_cust_class = cv_root) OR (iv_cust_class = cv_wholesale) OR (iv_cust_class = cv_planning) OR (iv_cust_class = cv_edi) OR (iv_cust_class = cv_hyakka)) THEN
    -- 顧客区分'20','21'を追加
    ELSIF ((iv_cust_class = cv_root) OR (iv_cust_class = cv_wholesale) OR (iv_cust_class = cv_planning) OR (iv_cust_class = cv_edi) OR (iv_cust_class = cv_hyakka) OR (iv_cust_class = cv_seikyu) OR (iv_cust_class = cv_tokatu)) THEN
-- 2009/09/15 Ver1.8 modify end by Yutaka.Kuboshima
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
    --オブジェクトナンバー設定
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
-- 2009/05/22 Ver1.4 add start by Yutaka.Kuboshima
  /**********************************************************************************
   * Procedure  Name  : cust_required_check
   * Description      : 顧客必須項目チェック
   ***********************************************************************************/
  PROCEDURE cust_required_check(
-- 2009/06/19 Ver1.5 modify start by Yutaka.Kuboshima
--                                iv_customer_number  IN  VARCHAR2,  -- 顧客番号
                                in_customer_id      IN  NUMBER,    -- 顧客ID
-- 2009/06/19 Ver1.5 modify end by Yutaka.Kuboshima
                                iv_cust_status      IN  VARCHAR2,  -- 顧客ステータス（変更前）
                                iv_cust_will_status IN  VARCHAR2,  -- 顧客ステータス（変更後）
                                ov_retcode          OUT VARCHAR2,  -- リターン・コード             --# 固定 #
                                ov_errmsg           OUT VARCHAR2)  -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(50) := 'cust_required_check';  -- プログラム名
    cv_cnst_msg_kbn         CONSTANT VARCHAR2(5)  := 'XXCMM';                -- アドオン：共通・マスタ
    -- メッセージ
    cv_msg_xxcmm_00001      CONSTANT VARCHAR2(16) := 'APP-XXCMM1-00001';     -- 対象データ無しエラー
    cv_msg_xxcmm_00347      CONSTANT VARCHAR2(16) := 'APP-XXCMM1-00347';     -- 使用目的存在チェックエラー
    cv_msg_xxcmm_00348      CONSTANT VARCHAR2(16) := 'APP-XXCMM1-00348';     -- 項目未設定エラー
    cv_msg_xxcmm_00349      CONSTANT VARCHAR2(16) := 'APP-XXCMM1-00349';     -- 確認メッセージ
-- 2009/07/15 Ver1.7 add start by Yutaka.Kuboshima
    cv_msg_xxcmm_00350      CONSTANT VARCHAR2(16) := 'APP-XXCMM1-00350';     -- 支払方法未登録メッセージ
-- 2009/07/15 Ver1.7 add end by Yutaka.Kuboshima
    --
    -- トークン
    cv_tkn_site_use         CONSTANT VARCHAR2(16) := 'SITE_USE';             -- 使用目的名
    cv_tkn_item             CONSTANT VARCHAR2(16) := 'ITEM';                 -- 項目名
    --
    -- トークン値
    cv_token_cust_number    CONSTANT VARCHAR2(50) := '[顧客番号]';           -- トークン値(顧客番号)
    cv_token_cust_kbn       CONSTANT VARCHAR2(50) := '[顧客区分]';           -- トークン値(顧客区分)
    cv_token_cust_name      CONSTANT VARCHAR2(50) := '[顧客名称]';           -- トークン値(顧客名称)
    cv_token_postal_code    CONSTANT VARCHAR2(50) := '[郵便番号]';           -- トークン値(郵便番号)
    cv_token_state          CONSTANT VARCHAR2(50) := '[都道府県]';           -- トークン値(都道府県)
    cv_token_city           CONSTANT VARCHAR2(50) := '[市・区]';             -- トークン値(市・区)
    cv_token_address1       CONSTANT VARCHAR2(50) := '[住所１]';             -- トークン値(住所１)
    cv_token_address3       CONSTANT VARCHAR2(50) := '[地区コード]';         -- トークン値(地区コード)
    cv_token_phonetic       CONSTANT VARCHAR2(50) := '[電話番号]';           -- トークン値(電話番号)
    cv_token_old_code       CONSTANT VARCHAR2(50) := '[旧本部コード]';       -- トークン値(旧本部コード)
    cv_token_new_code       CONSTANT VARCHAR2(50) := '[新本部コード]';       -- トークン値(新本部コード)
    cv_token_apply_date     CONSTANT VARCHAR2(50) := '[適用開始日]';         -- トークン値(適用開始日)
    cv_token_actual_div     CONSTANT VARCHAR2(50) := '[拠点実績有無区分]';   -- トークン値(拠点実績有無区分)
    cv_token_ship_div       CONSTANT VARCHAR2(50) := '[出荷管理元区分]';     -- トークン値(出荷管理元区分)
    cv_token_change_div     CONSTANT VARCHAR2(50) := '[倉替対象可否区分]';   -- トークン値(倉替対象可否区分)
    cv_token_user_div       CONSTANT VARCHAR2(50) := '[利用者区分]';         -- トークン値(利用者区分)
    cv_token_bill_to        CONSTANT VARCHAR2(50) := '[請求先]';             -- トークン値(請求先)
    cv_token_ship_to        CONSTANT VARCHAR2(50) := '[出荷先]';             -- トークン値(出荷先)
    cv_token_other_to       CONSTANT VARCHAR2(50) := '[その他]';             -- トークン値(その他)
    cv_token_bill_to_use_id CONSTANT VARCHAR2(50) := '[請求先事業所]';       -- トークン値(請求先事業所)
-- 2009/09/15 Ver1.8 delete start by Yutaka.Kuboshima
-- 請求書発行区分は必須項目対象から外す
--    cv_token_invoice_div    CONSTANT VARCHAR2(50) := '[請求書発行区分]';     -- トークン値(請求書発行区分)
-- 2009/09/15 Ver1.8 delete end by Yutaka.Kuboshima
    cv_token_payment_id     CONSTANT VARCHAR2(50) := '[支払条件]';           -- トークン値(支払条件)
    cv_token_tax_rule       CONSTANT VARCHAR2(50) := '[税金端数処理]';       -- トークン値(税金端数処理)
-- 2009/07/15 Ver1.7 add start by Yutaka.Kuboshima
    cv_token_site_use       CONSTANT VARCHAR2(50) := '使用目的';             -- トークン値(使用目的)
    cv_token_no             CONSTANT VARCHAR2(50) := 'の';                   -- トークン値(の)
-- 2009/07/15 Ver1.7 add end by Yutaka.Kuboshima
    -- 顧客区分
    cv_cust_kyoten_kbn      CONSTANT VARCHAR2(2)  := '1';                    -- 拠点
    cv_cust_kokyaku_kbn     CONSTANT VARCHAR2(2)  := '10';                   -- 顧客
    cv_cust_uesama_kbn      CONSTANT VARCHAR2(2)  := '12';                   -- 上様顧客
    cv_cust_houjin_kbn      CONSTANT VARCHAR2(2)  := '13';                   -- 法人顧客
    cv_cust_urikake_kbn     CONSTANT VARCHAR2(2)  := '14';                   -- 売掛管理先
    cv_cust_junkai_kbn      CONSTANT VARCHAR2(2)  := '15';                   -- 巡回
    cv_cust_hanbai_kbn      CONSTANT VARCHAR2(2)  := '16';                   -- 販売先
    cv_cust_keikaku_kbn     CONSTANT VARCHAR2(2)  := '17';                   -- 計画立案用
    cv_cust_edichain_kbn    CONSTANT VARCHAR2(2)  := '18';                   -- EDIチェーン
    cv_cust_hyakkaten_kbn   CONSTANT VARCHAR2(2)  := '19';                   -- 百貨店伝区
-- 2009/09/15 Ver1.8 add start by Yutaka.Kuboshima
    cv_cust_seikyu_kbn      CONSTANT VARCHAR2(2)  := '20';                   -- 請求書用
    cv_cust_toukatu_kbn     CONSTANT VARCHAR2(2)  := '21';                   -- 統括請求書用
-- 2009/09/15 Ver1.8 add end by Yutaka.Kuboshima
    -- 顧客ステータス
    cv_cust_mckouho_sts     CONSTANT VARCHAR2(2)  := '10';                   -- MC候補
    cv_cust_mc_sts          CONSTANT VARCHAR2(2)  := '20';                   -- MC
    cv_cust_spkessai_sts    CONSTANT VARCHAR2(2)  := '25';                   -- SP決裁済
    cv_cust_shounin_sts     CONSTANT VARCHAR2(2)  := '30';                   -- 承認済
    cv_cust_kokyaku_sts     CONSTANT VARCHAR2(2)  := '40';                   -- 顧客
    cv_cust_kyusi_sts       CONSTANT VARCHAR2(2)  := '50';                   -- 休止
    cv_cust_kousei_sts      CONSTANT VARCHAR2(2)  := '80';                   -- 更正債権
    cv_cust_tyusi_sts       CONSTANT VARCHAR2(2)  := '90';                   -- 中止決裁済
    cv_cust_taishougai_sts  CONSTANT VARCHAR2(2)  := '99';                   -- 対象外
    -- 使用目的コード
    cv_site_use_bill_to     CONSTANT VARCHAR2(10) := 'BILL_TO';              -- 使用目的コード(請求先)
    cv_site_use_ship_to     CONSTANT VARCHAR2(10) := 'SHIP_TO';              -- 使用目的コード(出荷先)
    cv_site_use_other_to    CONSTANT VARCHAR2(10) := 'OTHER_TO';             -- 使用目的コード(その他)
    -- その他
    cv_a_flag               CONSTANT VARCHAR2(1)  := 'A';                    -- 有効フラグ(A)
-- 2009/07/15 Ver1.7 add start by Yutaka.Kuboshima
    cv_y_flag               CONSTANT VARCHAR2(1)  := 'Y';                    -- 有効フラグ(Y)
-- 2009/07/15 Ver1.7 add end by Yutaka.Kuboshima
--
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errmsg               VARCHAR2(8000);
    lv_errmsg_00347         VARCHAR2(2000);
    lv_errmsg_00348         VARCHAR2(2000);
    lv_errmsg_00349         VARCHAR2(2000);
    lv_item_token           VARCHAR2(4000);
-- 2009/07/15 Ver1.7 add start by Yutaka.Kuboshima
    lv_item_token_bill      VARCHAR2(200);   -- 使用目的[請求先]専用トークン
    lv_item_token_ship      VARCHAR2(200);   -- 使用目的[出荷先]専用トークン
    lv_errmsg_00348_bill    VARCHAR2(2000);  -- 使用目的[請求先]専用メッセージ
    lv_errmsg_00348_ship    VARCHAR2(2000);  -- 使用目的[出荷先]専用メッセージ
    lv_errmsg_00350         VARCHAR2(2000);  -- 支払方法未登録エラーメッセージ
    lv_receipt_err          VARCHAR2(1);     -- 支払方法チェック結果
-- 2009/07/15 Ver1.7 add start by Yutaka.Kuboshima
    lv_site_use_token       VARCHAR2(200);
    lv_retcode              VARCHAR2(1);
--
    -- ===============================
    -- ローカルカーソル
    -- ===============================
    -- 顧客必須項目チェック用カーソル
    CURSOR cust_required_check_cur
    IS
      SELECT hca.account_number          account_number          -- 顧客番号
            ,hca.customer_class_code     customer_class_code     -- 顧客区分
            ,hca.attribute1              old_base_code           -- 旧本部コード
            ,hca.attribute2              new_base_code           -- 新本部コード
            ,hca.attribute3              apply_start_date        -- 適用開始日
            ,hca.attribute4              base_actual_exists_div  -- 拠点実績有無区分
            ,hca.attribute5              ship_management_div     -- 出荷管理元区分
            ,hca.attribute6              change_bay_target_div   -- 倉替対象可否区分
            ,hca.attribute8              user_div                -- 利用者区分
            ,hp.party_name               party_name              -- 顧客名称
            ,cust.postal_code            postal_code             -- 郵便番号
            ,cust.state                  state                   -- 都道府県
            ,cust.city                   city                    -- 市・区
            ,cust.address1               address1                -- 住所１
            ,cust.address3               address3                -- 地区コード
            ,cust.address_lines_phonetic address_lines_phonetic  -- 電話番号
            ,cust.site_use_code          site_use_code           -- 使用目的
            ,cust.bill_to_site_use_id    bill_to_site_use_id     -- 請求先事業所
-- 2009/09/15 Ver1.8 delete start by Yutaka.Kuboshima
-- 請求書発行区分は必須項目対象から外す
--            ,cust.invoice_issue_div      invoice_issue_div       -- 請求書発行区分
-- 2009/09/15 Ver1.8 delete end by Yutaka.Kuboshima
            ,cust.payment_term_id        payment_term_id         -- 支払条件
            ,cust.tax_rounding_rule      tax_rounding_rule       -- 税金端数処理
-- 2009/07/15 Ver1.7 add start by Yutaka.Kuboshima
            ,cust.primary_flag           primary_flag            -- 支払方法主フラグ
-- 2009/07/15 Ver1.7 add end by Yutaka.Kuboshima
      FROM   hz_cust_accounts   hca
            ,hz_parties         hp
            ,(SELECT hca2.cust_account_id       cust_account_id
                    ,hl2.postal_code            postal_code
                    ,hl2.state                  state
                    ,hl2.city                   city
                    ,hl2.address1               address1
                    ,hl2.address3               address3
                    ,hl2.address_lines_phonetic address_lines_phonetic
                    ,hcsuv.site_use_code        site_use_code
                    ,hcsuv.bill_to_site_use_id  bill_to_site_use_id
-- 2009/09/15 Ver1.8 delete start by Yutaka.Kuboshima
-- 請求書発行区分は必須項目対象から外す
--                    ,hcsuv.invoice_issue_div    invoice_issue_div
-- 2009/09/15 Ver1.8 delete end by Yutaka.Kuboshima
                    ,hcsuv.payment_term_id      payment_term_id
                    ,hcsuv.tax_rounding_rule    tax_rounding_rule
-- 2009/07/15 Ver1.7 add start by Yutaka.Kuboshima
                    ,rcrmv.primary_flag         primary_flag
-- 2009/07/15 Ver1.7 add end by Yutaka.Kuboshima
              FROM   hz_cust_accounts   hca2
                    ,hz_parties         hp2
                    ,hz_party_sites     hps2
                    ,hz_locations       hl2
                    ,(SELECT hca3.cust_account_id       cust_account_id
                            ,hcsu3.site_use_code        site_use_code
                            ,hcsu3.bill_to_site_use_id  bill_to_site_use_id
-- 2009/09/15 Ver1.8 delete start by Yutaka.Kuboshima
-- 請求書発行区分は必須項目対象から外す
--                           ,hcsu3.attribute1           invoice_issue_div
-- 2009/09/15 Ver1.8 delete end by Yutaka.Kuboshima
                            ,hcsu3.payment_term_id      payment_term_id
                            ,hcsu3.tax_rounding_rule    tax_rounding_rule
                      FROM   hz_cust_accounts   hca3
                            ,hz_parties         hp3
                            ,hz_party_sites     hps3
                            ,hz_locations       hl3
                            ,hz_cust_acct_sites hcas3
                            ,hz_cust_site_uses  hcsu3
                      WHERE  hca3.party_id           = hp3.party_id
                        AND  hp3.party_id            = hps3.party_id
                        AND  hps3.location_id        = hl3.location_id
                        AND  hps3.party_site_id      = hcas3.party_site_id
                        AND  hcas3.cust_acct_site_id = hcsu3.cust_acct_site_id
-- 2009/11/26 Ver1.10 E_本稼動_00106 add start by Yutaka.Kuboshima
                        AND  hca3.cust_account_id    = hcas3.cust_account_id
-- 2009/11/26 Ver1.10 E_本稼動_00106 add end by Yutaka.Kuboshima
                        AND  hcsu3.status            = cv_a_flag
                        AND ( ( hca3.customer_class_code = cv_cust_kyoten_kbn
                            AND hcsu3.site_use_code = cv_site_use_other_to)
                          OR  ( hca3.customer_class_code IN (cv_cust_kokyaku_kbn, cv_cust_uesama_kbn)
                            AND hcsu3.site_use_code IN (cv_site_use_bill_to, cv_site_use_ship_to))
                          OR  ( hca3.customer_class_code = cv_cust_urikake_kbn
                            AND hcsu3.site_use_code = cv_site_use_bill_to)
-- 2009/09/15 Ver1.8 modify start by Yutaka.Kuboshima
--                          OR  ( hca3.customer_class_code IN (cv_cust_houjin_kbn, cv_cust_junkai_kbn, cv_cust_hanbai_kbn, cv_cust_keikaku_kbn, cv_cust_edichain_kbn, cv_cust_hyakkaten_kbn)
                          -- 顧客区分'20','21'を追加
                          OR  ( hca3.customer_class_code IN (cv_cust_houjin_kbn, cv_cust_junkai_kbn, cv_cust_hanbai_kbn, cv_cust_keikaku_kbn, cv_cust_edichain_kbn, cv_cust_hyakkaten_kbn, cv_cust_seikyu_kbn, cv_cust_toukatu_kbn)
-- 2009/09/15 Ver1.8 modify start by Yutaka.Kuboshima
                            AND hcsu3.site_use_code = cv_site_use_other_to)
                            )
                        AND  hl3.location_id         = (SELECT MIN(hps31.location_id)
                                                        FROM   hz_cust_acct_sites hcas31,
                                                               hz_party_sites     hps31
                                                        WHERE  hcas31.cust_account_id = hca3.cust_account_id
                                                        AND    hcas31.party_site_id   = hps31.party_site_id
                                                        AND    hps31.status           = cv_a_flag)
                     ) hcsuv
-- 2009/07/15 Ver1.7 add start by Yutaka.Kuboshima
                    ,(SELECT hca.cust_account_id customer_id
                            ,rcrm.primary_flag   primary_flag
                      FROM   hz_cust_accounts        hca
                            ,ra_cust_receipt_methods rcrm
                      WHERE  hca.cust_account_id = rcrm.customer_id
                        AND  rcrm.cust_receipt_method_id = (SELECT rcrm2.cust_receipt_method_id
                                                            FROM   hz_cust_accounts hca2
                                                                  ,hz_cust_acct_sites hcas2
                                                                  ,ra_cust_receipt_methods rcrm2
                                                            WHERE  hca2.cust_account_id = rcrm2.customer_id
                                                              AND  hca2.cust_account_id = hcas2.cust_account_id
                                                              AND  hca.cust_account_id  = hca2.cust_account_id
-- 2009/10/30 Ver1.9 modify start by Yutaka.Kuboshima
--                                                              AND  rcrm.primary_flag    = cv_y_flag
                                                              AND  rcrm2.primary_flag   = cv_y_flag
-- 2009/10/30 Ver1.9 modify end by Yutaka.Kuboshima
                                                              AND  ROWNUM = 1)
                     ) rcrmv
-- 2009/07/15 Ver1.7 add end by Yutaka.Kuboshima
              WHERE  hca2.party_id           = hp2.party_id(+)
                AND  hp2.party_id            = hps2.party_id(+)
                AND  hps2.location_id        = hl2.location_id(+)
                AND  hca2.cust_account_id    = hcsuv.cust_account_id(+)
                AND  hl2.location_id         = (SELECT MIN(hps21.location_id)
                                                FROM   hz_cust_acct_sites hcas21,
                                                       hz_party_sites     hps21
                                                WHERE  hcas21.cust_account_id = hca2.cust_account_id
                                                AND    hcas21.party_site_id   = hps21.party_site_id
                                                AND    hps21.status           = cv_a_flag)
-- 2009/07/15 Ver1.7 add start by Yutaka.Kuboshima
                AND  hca2.cust_account_id    = rcrmv.customer_id(+)
-- 2009/07/15 Ver1.7 add end by Yutaka.Kuboshima
             ) cust
      WHERE  hca.party_id        = hp.party_id(+)
        AND  hca.cust_account_id = cust.cust_account_id(+)
-- 2009/06/19 Ver1.5 modify start by Yutaka.Kuboshima
--        AND  hca.account_number  = iv_customer_number
        AND  hca.cust_account_id = in_customer_id
-- 2009/06/19 Ver1.5 modify end by Yutaka.Kuboshima
      ORDER BY cust.site_use_code;
    -- 顧客必須項目チェック用カーソル型レコード
    cust_required_check_rec cust_required_check_cur%ROWTYPE;
--
    -- ===============================
    -- ユーザー定義例外
    -- ===============================
    no_data_found_expt EXCEPTION;
--
  BEGIN
--
    -- 初期処理
    lv_errmsg  := NULL;
    lv_retcode := cv_success;
    -- 対象データ取得
    OPEN cust_required_check_cur;
    FETCH cust_required_check_cur INTO cust_required_check_rec;
    -- 対象データが存在するか
    IF (cust_required_check_cur%NOTFOUND) THEN
      RAISE no_data_found_expt;
    END IF;
    -- チェック起動条件
    IF ( (  cust_required_check_rec.customer_class_code = cv_cust_kokyaku_kbn
        AND iv_cust_status = cv_cust_mckouho_sts
        AND iv_cust_will_status =cv_cust_shounin_sts)
      OR (  cust_required_check_rec.customer_class_code = cv_cust_kokyaku_kbn
        AND iv_cust_status = cv_cust_mc_sts
        AND iv_cust_will_status =cv_cust_shounin_sts)
      OR (  cust_required_check_rec.customer_class_code = cv_cust_kokyaku_kbn
        AND iv_cust_status = cv_cust_spkessai_sts
        AND iv_cust_will_status =cv_cust_shounin_sts)
      OR (  cust_required_check_rec.customer_class_code = cv_cust_kyoten_kbn
        AND iv_cust_status IS NULL
        AND iv_cust_will_status =cv_cust_taishougai_sts)
      OR (  cust_required_check_rec.customer_class_code = cv_cust_kokyaku_kbn
        AND iv_cust_status IS NULL
        AND iv_cust_will_status =cv_cust_shounin_sts)
      OR (  cust_required_check_rec.customer_class_code = cv_cust_uesama_kbn
        AND iv_cust_status IS NULL
        AND iv_cust_will_status =cv_cust_shounin_sts)
      OR (  cust_required_check_rec.customer_class_code = cv_cust_houjin_kbn
        AND iv_cust_status IS NULL
        AND iv_cust_will_status =cv_cust_taishougai_sts)
      OR (  cust_required_check_rec.customer_class_code = cv_cust_urikake_kbn
        AND iv_cust_status IS NULL
        AND iv_cust_will_status =cv_cust_taishougai_sts)
      OR (  cust_required_check_rec.customer_class_code = cv_cust_junkai_kbn
        AND iv_cust_status IS NULL
        AND iv_cust_will_status =cv_cust_taishougai_sts)
      OR (  cust_required_check_rec.customer_class_code = cv_cust_hanbai_kbn
        AND iv_cust_status IS NULL
        AND iv_cust_will_status =cv_cust_taishougai_sts)
      OR (  cust_required_check_rec.customer_class_code = cv_cust_keikaku_kbn
        AND iv_cust_status IS NULL
        AND iv_cust_will_status =cv_cust_taishougai_sts)
      OR (  cust_required_check_rec.customer_class_code = cv_cust_edichain_kbn
        AND iv_cust_status IS NULL
        AND iv_cust_will_status =cv_cust_taishougai_sts)
      OR (  cust_required_check_rec.customer_class_code = cv_cust_hyakkaten_kbn
        AND iv_cust_status IS NULL
        AND iv_cust_will_status =cv_cust_taishougai_sts)
-- 2009/09/15 Ver1.8 add start by Yutaka.Kuboshima
      -- 顧客区分'20','21'のチェック起動条件を追加
      OR (  cust_required_check_rec.customer_class_code = cv_cust_seikyu_kbn
        AND iv_cust_status IS NULL
        AND iv_cust_will_status =cv_cust_taishougai_sts)
      OR (  cust_required_check_rec.customer_class_code = cv_cust_toukatu_kbn
        AND iv_cust_status IS NULL
        AND iv_cust_will_status =cv_cust_taishougai_sts)
-- 2009/09/15 Ver1.8 add end by Yutaka.Kuboshima
       )
    THEN
      -- 顧客番号NULLチェック
      IF (cust_required_check_rec.account_number IS NULL) THEN
        lv_item_token := cv_token_cust_number;
      END IF;
      -- 顧客区分NULLチェック
      IF (cust_required_check_rec.customer_class_code IS NULL) THEN
        lv_item_token := lv_item_token || cv_token_cust_kbn;
      END IF;
      -- 顧客名称NULLチェック
      IF (cust_required_check_rec.party_name IS NULL) THEN
        lv_item_token := lv_item_token || cv_token_cust_name;
      END IF;
      -- 郵便番号NULLチェック
      IF (cust_required_check_rec.postal_code IS NULL) THEN
        lv_item_token := lv_item_token || cv_token_postal_code;
      END IF;
      -- 都道府県NULLチェック
      IF (cust_required_check_rec.state IS NULL) THEN
        lv_item_token := lv_item_token || cv_token_state;
      END IF;
      -- 市・区NULLチェック
      IF (cust_required_check_rec.city IS NULL) THEN
        lv_item_token := lv_item_token || cv_token_city;
      END IF;
      -- 住所１NULLチェック
      IF (cust_required_check_rec.address1 IS NULL) THEN
        lv_item_token := lv_item_token || cv_token_address1;
      END IF;
      -- 地区コードNULLチェック
      IF (cust_required_check_rec.address3 IS NULL) THEN
        lv_item_token := lv_item_token || cv_token_address3;
      END IF;
      -- 電話番号NULLチェック
      IF (cust_required_check_rec.address_lines_phonetic IS NULL) THEN
        lv_item_token := lv_item_token || cv_token_phonetic;
      END IF;
      -- 顧客区分が'1'(拠点)の場合
      IF (cust_required_check_rec.customer_class_code = cv_cust_kyoten_kbn) THEN
        -- 旧本部コードNULLチェック
        IF (cust_required_check_rec.old_base_code IS NULL) THEN
          lv_item_token := lv_item_token || cv_token_old_code;
        END IF;
        -- 新本部コードNULLチェック
        IF (cust_required_check_rec.new_base_code IS NULL) THEN
          lv_item_token := lv_item_token || cv_token_new_code;
        END IF;
        -- 適用開始日NULLチェック
        IF (cust_required_check_rec.apply_start_date IS NULL) THEN
          lv_item_token := lv_item_token || cv_token_apply_date;
        END IF;
        -- 拠点実績有無区分NULLチェック
        IF (cust_required_check_rec.base_actual_exists_div IS NULL) THEN
          lv_item_token := lv_item_token || cv_token_actual_div;
        END IF;
        -- 出荷管理元区分NULLチェック
        IF (cust_required_check_rec.ship_management_div IS NULL) THEN
          lv_item_token := lv_item_token || cv_token_ship_div;
        END IF;
        -- 倉替対象可否区分NULLチェック
        IF (cust_required_check_rec.change_bay_target_div IS NULL) THEN
          lv_item_token := lv_item_token || cv_token_change_div;
        END IF;
        -- 利用者区分NULLチェック
        IF (cust_required_check_rec.user_div IS NULL) THEN
          lv_item_token := lv_item_token || cv_token_user_div;
        END IF;
        -- 使用目的存在チェック
        IF (cust_required_check_rec.site_use_code IS NULL) THEN
          lv_site_use_token := lv_site_use_token || cv_token_other_to;
        END IF;
      -- 顧客区分が'10'(顧客),'12'(上様顧客)の場合
      ELSIF (cust_required_check_rec.customer_class_code IN (cv_cust_kokyaku_kbn, cv_cust_uesama_kbn)) THEN
-- 2009/07/15 Ver1.7 add start by Yutaka.Kuboshima
        -- 支払方法存在チェック
        IF (cust_required_check_rec.primary_flag IS NULL) THEN
          lv_receipt_err := cv_error;
        END IF;
-- 2009/07/15 Ver1.7 add end by Yutaka.Kuboshima
        -- 使用目的(請求先)存在チェック
        -- 使用目的がNULL(請求先、出荷先共に未設定)の場合
        IF (cust_required_check_rec.site_use_code IS NULL) THEN
          lv_site_use_token := lv_site_use_token || cv_token_bill_to || cv_token_ship_to;
        -- 使用目的(出荷先)の場合
        ELSIF (cust_required_check_rec.site_use_code = cv_site_use_ship_to) THEN
          lv_site_use_token := lv_site_use_token || cv_token_bill_to;
          -- 請求先事業所NULLチェック
          IF (cust_required_check_rec.bill_to_site_use_id IS NULL) THEN
-- 2009/07/15 Ver1.7 modify start by Yutaka.Kuboshima
--            lv_item_token := lv_item_token || cv_token_bill_to_use_id;
            lv_item_token_ship := lv_item_token_ship || cv_token_bill_to_use_id;
-- 2009/07/15 Ver1.7 modify end by Yutaka.Kuboshima
          END IF;
        -- 使用目的(請求先)の場合
        ELSIF (cust_required_check_rec.site_use_code = cv_site_use_bill_to) THEN
-- 2009/09/15 Ver1.8 delete start by Yutaka.Kuboshima
-- 請求書発行区分は必須項目対象から外す
--          -- 請求書発行区分NULLチェック
--          IF (cust_required_check_rec.invoice_issue_div IS NULL) THEN
---- 2009/07/15 Ver1.7 modify start by Yutaka.Kuboshima
----            lv_item_token := lv_item_token || cv_token_invoice_div;
--            lv_item_token_bill := lv_item_token_bill || cv_token_invoice_div;
---- 2009/07/15 Ver1.7 modify end by Yutaka.Kuboshima
--          END IF;
-- 2009/09/15 Ver1.8 delete end by Yutaka.Kuboshima
          -- 支払条件NULLチェック
          IF (cust_required_check_rec.payment_term_id IS NULL) THEN
-- 2009/07/15 Ver1.7 modify start by Yutaka.Kuboshima
--            lv_item_token := lv_item_token || cv_token_payment_id;
            lv_item_token_bill := lv_item_token_bill || cv_token_payment_id;
-- 2009/07/15 Ver1.7 modify end by Yutaka.Kuboshima
          END IF;
          -- 税金端数処理NULLチェック
          IF (cust_required_check_rec.tax_rounding_rule IS NULL) THEN
-- 2009/07/15 Ver1.7 modify start by Yutaka.Kuboshima
--            lv_item_token := lv_item_token || cv_token_tax_rule;
            lv_item_token_bill := lv_item_token_bill || cv_token_tax_rule;
-- 2009/07/15 Ver1.7 modify end by Yutaka.Kuboshima
          END IF;
          -- 出荷先レコードの取得
          FETCH cust_required_check_cur INTO cust_required_check_rec;
          -- 対象データが存在するか
          -- 存在しない場合、出荷先レコード未設定
          IF (cust_required_check_cur%NOTFOUND) THEN
            lv_site_use_token := lv_site_use_token || cv_token_ship_to;
          ELSE
            -- 請求先事業所NULLチェック
            IF (cust_required_check_rec.bill_to_site_use_id IS NULL) THEN
-- 2009/07/15 Ver1.7 modify start by Yutaka.Kuboshima
--              lv_item_token := lv_item_token || cv_token_bill_to_use_id;
              lv_item_token_ship := lv_item_token_ship || cv_token_bill_to_use_id;
-- 2009/07/15 Ver1.7 modify end by Yutaka.Kuboshima
            END IF;
          END IF;
        END IF;
      -- 顧客区分が'14'(売掛管理先)の場合
      ELSIF (cust_required_check_rec.customer_class_code = cv_cust_urikake_kbn) THEN
-- 2009/07/15 Ver1.7 add start by Yutaka.Kuboshima
        -- 支払方法存在チェック
        IF (cust_required_check_rec.primary_flag IS NULL) THEN
          lv_receipt_err := cv_error;
        END IF;
-- 2009/07/15 Ver1.7 add end by Yutaka.Kuboshima
        -- 使用目的(請求先)存在チェック
        -- 使用目的がNULL(請求先未設定)の場合
        IF (cust_required_check_rec.site_use_code IS NULL) THEN
          lv_site_use_token := lv_site_use_token || cv_token_bill_to;
        ELSE
-- 2009/09/15 Ver1.8 delete start by Yutaka.Kuboshima
-- 請求書発行区分は必須項目対象から外す
--          -- 請求書発行区分NULLチェック
--          IF (cust_required_check_rec.invoice_issue_div IS NULL) THEN
---- 2009/07/15 Ver1.7 modify start by Yutaka.Kuboshima
----            lv_item_token := lv_item_token || cv_token_invoice_div;
--            lv_item_token_bill := lv_item_token_bill || cv_token_invoice_div;
---- 2009/07/15 Ver1.7 modify end by Yutaka.Kuboshima
--          END IF;
-- 2009/09/15 Ver1.8 delete end by Yutaka.Kuboshima
          -- 支払条件NULLチェック
          IF (cust_required_check_rec.payment_term_id IS NULL) THEN
-- 2009/07/15 Ver1.7 modify start by Yutaka.Kuboshima
--            lv_item_token := lv_item_token || cv_token_payment_id;
            lv_item_token_bill := lv_item_token_bill || cv_token_payment_id;
-- 2009/07/15 Ver1.7 modify end by Yutaka.Kuboshima
          END IF;
          -- 税金端数処理NULLチェック
          IF (cust_required_check_rec.tax_rounding_rule IS NULL) THEN
-- 2009/07/15 Ver1.7 modify start by Yutaka.Kuboshima
--            lv_item_token := lv_item_token || cv_token_tax_rule;
            lv_item_token_bill := lv_item_token_bill || cv_token_tax_rule;
-- 2009/07/15 Ver1.7 modify end by Yutaka.Kuboshima
          END IF;
        END IF;
-- 2009/09/15 Ver1.8 modify start by Yutaka.Kuboshima
--      ELSIF (cust_required_check_rec.customer_class_code IN (cv_cust_houjin_kbn, cv_cust_junkai_kbn, cv_cust_hanbai_kbn, cv_cust_keikaku_kbn, cv_cust_edichain_kbn, cv_cust_hyakkaten_kbn)) THEN
      -- 顧客区分が'13'(法人顧客),'15'(巡回),'16'(販売先),'17'(計画立案用),'18'(EDIチェーン),'19'(百貨店伝区),'20'(請求書用),'21'(統括請求書用)の場合
      ELSIF (cust_required_check_rec.customer_class_code IN (cv_cust_houjin_kbn, cv_cust_junkai_kbn, cv_cust_hanbai_kbn, cv_cust_keikaku_kbn, cv_cust_edichain_kbn, cv_cust_hyakkaten_kbn, cv_cust_seikyu_kbn, cv_cust_toukatu_kbn)) THEN
-- 2009/09/15 Ver1.8 modify end by Yutaka.Kuboshima
        -- 使用目的存在チェック
        IF (cust_required_check_rec.site_use_code IS NULL) THEN
          lv_site_use_token := lv_site_use_token || cv_token_other_to;
        END IF;
      END IF;
      -- エラーメッセージ生成
      -- 項目NULLチェックエラーの場合
      IF (lv_item_token IS NOT NULL) THEN
        lv_errmsg_00348 := xxccp_common_pkg.get_msg(cv_cnst_msg_kbn,
                                                    cv_msg_xxcmm_00348,
                                                    cv_tkn_item,
                                                    lv_item_token) || CHR(10);
-- 2009/07/15 Ver1.7 add start by Yutaka.Kuboshima
        lv_retcode := cv_error;
-- 2009/07/15 Ver1.7 add end by Yutaka.Kuboshima
      END IF;
      -- 使用目的存在チェックエラーの場合
      IF (lv_site_use_token IS NOT NULL) THEN
        lv_errmsg_00347 := xxccp_common_pkg.get_msg(cv_cnst_msg_kbn,
                                                    cv_msg_xxcmm_00347,
                                                    cv_tkn_site_use,
                                                    lv_site_use_token) || CHR(10);
-- 2009/07/15 Ver1.7 add start by Yutaka.Kuboshima
        lv_retcode := cv_error;
-- 2009/07/15 Ver1.7 add end by Yutaka.Kuboshima
      END IF;
-- 2009/07/15 Ver1.7 add start by Yutaka.Kuboshima
      -- 使用目的[請求先]項目NULLチェックエラーの場合
      IF (lv_item_token_bill IS NOT NULL) THEN
        lv_errmsg_00348_bill := cv_token_site_use || cv_token_bill_to || cv_token_no ||
                                xxccp_common_pkg.get_msg(cv_cnst_msg_kbn,
                                                         cv_msg_xxcmm_00348,
                                                         cv_tkn_item,
                                                         lv_item_token_bill) || CHR(10);
        lv_retcode := cv_error;
      END IF;
      -- 使用目的[出荷先]項目NULLチェックエラーの場合
      IF (lv_item_token_ship IS NOT NULL) THEN
        lv_errmsg_00348_ship := cv_token_site_use || cv_token_ship_to || cv_token_no ||
                                xxccp_common_pkg.get_msg(cv_cnst_msg_kbn,
                                                         cv_msg_xxcmm_00348,
                                                         cv_tkn_item,
                                                         lv_item_token_ship) || CHR(10);
        lv_retcode := cv_error;
      END IF;
      -- 支払方法未登録チェックエラーの場合
      IF (lv_receipt_err = cv_error) THEN
        lv_errmsg_00350 := xxccp_common_pkg.get_msg(cv_cnst_msg_kbn,
                                                    cv_msg_xxcmm_00350) || CHR(10);
        lv_retcode := cv_error;
      END IF;
-- 2009/07/15 Ver1.7 add start by Yutaka.Kuboshima
-- 2009/07/15 Ver1.7 modify start by Yutaka.Kuboshima
--      IF (lv_errmsg_00347 IS NOT NULL OR lv_errmsg_00348 IS NOT NULL) THEN
      -- リターンコードが警告の場合
      IF (lv_retcode = cv_error) THEN
-- 2009/07/15 Ver1.7 modify end by Yutaka.Kuboshima
        lv_errmsg_00349 := xxccp_common_pkg.get_msg(cv_cnst_msg_kbn,
                                                    cv_msg_xxcmm_00349);
-- 2009/07/15 Ver1.7 modify start by Yutaka.Kuboshima
--        lv_errmsg  := lv_errmsg_00347 || lv_errmsg_00348 || lv_errmsg_00349;
        lv_errmsg  := lv_errmsg_00347 || lv_errmsg_00348 || lv_errmsg_00348_bill ||
                      lv_errmsg_00348_ship || lv_errmsg_00350 || lv_errmsg_00349;
-- 2009/07/15 Ver1.7 modify end by Yutaka.Kuboshima
      END IF;
    END IF;
    -- OUTパラメータセット
    ov_errmsg  := lv_errmsg;
    ov_retcode := lv_retcode;
  EXCEPTION
    -- *** 対象データ無し ***
    WHEN no_data_found_expt THEN
      ov_errmsg  := xxccp_common_pkg.get_msg(cv_cnst_msg_kbn,
                                             cv_msg_xxcmm_00001);
      ov_retcode := cv_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(cv_pkg_name || cv_cnst_period || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000), TRUE);
  END cust_required_check;
-- 2009/05/22 Ver1.4 add end by Yutaka.Kuboshima
END xxcmm_003common_pkg;
/
