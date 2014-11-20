CREATE OR REPLACE PACKAGE xxcmm_003common_pkg
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name           : xxcmm_003common_pkg(body)
 * Description            :
 * MD.110                 : MD110_CMM_顧客_共通関数
 * Version                : 1.3
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
 *  2009/05/22    1.3  Yutaka.Kuboshima 顧客必須項目チェック追加
 *  2009/06/19    1.4  Yutaka.Kuboshima 障害T1_1500対応
 *****************************************************************************************/
 --
  --顧客ステータス更新可否チェック
  FUNCTION cust_status_update_allow(iv_cust_class        IN VARCHAR2  -- 顧客区分
                                   ,iv_cust_status       IN VARCHAR2  -- 顧客ステータス（変更前）
                                   ,iv_cust_will_status  IN VARCHAR2) -- 顧客ステータス（変更後）
    RETURN VARCHAR2;
  --パーティマスタ更新用関数
  PROCEDURE update_hz_party(in_party_id    IN  NUMBER,    -- パーティID
                            iv_cust_status IN  VARCHAR2,  -- 顧客ステータス
                            ov_errbuf      OUT VARCHAR2,  -- エラー・メッセージ           --# 固定 #
                            ov_retcode     OUT VARCHAR2,  -- リターン・コード             --# 固定 #
                            ov_errmsg      OUT VARCHAR2); -- ユーザー・エラー・メッセージ --# 固定 #
  --顧客名称・顧客名称カナチェック
  FUNCTION cust_name_kana_check(iv_cust_name_mir           IN VARCHAR2   -- 顧客名称
                               ,iv_cust_name_phonetic_mir  IN VARCHAR2)  -- 顧客名称カナ
    RETURN VARCHAR2;
  --顧客所在地全角半角チェック
  FUNCTION cust_site_check(iv_cust_site  IN VARCHAR2)   -- 顧客所在地文字列
    RETURN VARCHAR2;
-- 2009/05/22 Ver1.3 add start by Yutaka.Kuboshima
  --顧客必須項目チェック
  PROCEDURE cust_required_check(
-- 2009/06/19 Ver1.4 modify start by Yutaka.Kuboshima
--                                iv_customer_number  IN  VARCHAR2,  -- 顧客番号
                                in_customer_id      IN  NUMBER,    -- 顧客ID
-- 2009/06/19 Ver1.4 modify end by Yutaka.Kuboshima
                                iv_cust_status      IN  VARCHAR2,  -- 顧客ステータス（変更前）
                                iv_cust_will_status IN  VARCHAR2,  -- 顧客ステータス（変更後）
                                ov_retcode          OUT VARCHAR2,  -- リターン・コード             --# 固定 #
                                ov_errmsg           OUT VARCHAR2); -- ユーザー・エラー・メッセージ --# 固定 #
-- 2009/05/22 Ver1.3 add end by Yutaka.Kuboshima
END xxcmm_003common_pkg;
/
