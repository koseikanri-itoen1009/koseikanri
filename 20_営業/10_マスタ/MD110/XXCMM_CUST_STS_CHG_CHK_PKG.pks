CREATE OR REPLACE PACKAGE XXCMM_CUST_STS_CHG_CHK_PKG
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCMM_CUST_STS_CHK_PKG(spec)
 * Description      : 顧客ステータスを「中止」に変更する際、ステータス変更が可能か判定を行います。
 * MD.050           : MD050_CMM_003_A11_顧客ステータス変更チェック
 * Version          : 1.0
 *
 * Program List
 * -------------------- ------------------------------------------------------------
 *  Name                 Description
 * -------------------- ------------------------------------------------------------
 *  main                 実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009-01-08    1.0   Takuya.Kaihara   main新規作成
 *
 *****************************************************************************************/
--
  --実行ファイル登録プロシージャ
  PROCEDURE main(
    in_cust_id      IN  NUMBER,       --   顧客ID
    iv_gtai_syo     IN  VARCHAR2,     --   業態分類（小分類）
    ov_check_status OUT VARCHAR2,     --   チェックステータス
    ov_err_message  OUT VARCHAR2      --   エラーメッセージ
  );
END XXCMM_CUST_STS_CHG_CHK_PKG;
/
