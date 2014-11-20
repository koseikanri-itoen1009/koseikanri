CREATE OR REPLACE PACKAGE xxcmm_003common_pkg
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name           : xxcmm_003common_pkg(spec)
 * Description            :
 * MD.110                 : MD110_CMM_顧客_共通関数
 * Version                : 1.0
 *
 * Program List
 *  --------------------      ---- ----- --------------------------------------------------
 *   Name                     Type  Ret   Description
 *  --------------------      ---- ----- --------------------------------------------------
 *  cust_status_update_check  F           顧客ステータス更新可否チェック
 *  update_hz_party           P           パーティマスタ更新関数
 *
 * Change Record
 * ------------ ----- ---------------- -----------------------------------------------
 *  Date         Ver.  Editor           Description
 * ------------ ----- ---------------- -----------------------------------------------
 *  2009-01-30    1.0  Yuuki.Nakamura   新規作成
 *  2009-02-26    1.1  Yutaka.Kuboshima パーティマスタ更新関数追加
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
END xxcmm_003common_pkg;
/
