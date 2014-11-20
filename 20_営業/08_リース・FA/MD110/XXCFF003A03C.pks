CREATE OR REPLACE PACKAGE XXCFF003A03C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCFF003A03C(spec)
 * Description      : リース種類判定
 * MD.050           : MD050_CFF_003_A03_リース種類判定
 * Version          : 1.0
 *
 * Program List
 * --------------------      ---- ----- --------------------------------------------------
 *  Name                     Type  Ret   Description
 * --------------------      ---- ----- --------------------------------------------------
 *  main                      P          コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008-12-04    1.0   SCS 増子 秀幸    新規作成
 *
 *****************************************************************************************/
--
--#######################  プロシージャ宣言部 START   #######################
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    iv_lease_type                  IN  VARCHAR2,    -- 1.リース区分
    in_payment_frequency           IN  NUMBER,      -- 2.支払回数
    in_first_charge                IN  NUMBER,      -- 3.初回月額リース料
    in_second_charge               IN  NUMBER,      -- 4.２回目以降月額リース料
    in_estimated_cash_price        IN  NUMBER,      -- 5.見積現金購入価額
    in_life_in_months              IN  NUMBER,      -- 6.法定耐用年数
    id_contract_ym                 IN  DATE,        -- 7.契約年月
    ov_lease_kind                  OUT VARCHAR2,    -- 8.リース種類
    on_present_value_discount_rate OUT NUMBER,      -- 9.現在価値割引率
    on_present_value               OUT NUMBER,      -- 10.現在価値
    on_original_cost               OUT NUMBER,      -- 11.取得価額
    on_calc_interested_rate        OUT NUMBER,      -- 12.計算利子率
    ov_errbuf                      OUT VARCHAR2,    -- エラー・メッセージ
    ov_retcode                     OUT VARCHAR2,    -- リターン・コード
    ov_errmsg                      OUT VARCHAR2     -- ユーザー・エラー・メッセージ
  );
--
END XXCFF003A03C
;
/
