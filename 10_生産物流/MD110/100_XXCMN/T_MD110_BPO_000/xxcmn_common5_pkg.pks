CREATE OR REPLACE PACKAGE apps.xxcmn_common5_pkg
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2018. All rights reserved.
 *
 * Package Name           : xxcmn_common5_pkg(body)
 * Description            : 共通関数5
 * MD.070(CMD.050)        : T_MD050_BPO_000_共通関数5.xls
 * Version                : 1.1
 *
 * Program List
 *  -------------------- ---- ----- --------------------------------------------------
 *   Name                Type  Ret   Description
 *  -------------------- ---- ----- --------------------------------------------------
 *  get_use_by_date       F    DATE  賞味期限取得関数
 *  chek_lot_unit_price   F    NUM   月跨ぎのロット単価変更チェック
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2018/02/22    1.0   H.Sasaki        新規作成(E_本稼動_14859)
 *  2020/07/30    1.1   Y.Shoji         E_本稼動_16375対応
 *
 *****************************************************************************************/
--
  -- ===============================
  -- プロシージャおよびファンクション
  -- ===============================
--
  FUNCTION  get_use_by_date(
      id_producted_date     IN DATE       --  1.製造日
    , iv_expiration_type    IN VARCHAR2   --  2.表示区分
    , in_expiration_day     IN NUMBER     --  3.賞味期間
    , in_expiration_month   IN NUMBER     --  4.賞味期間(月)
  ) RETURN DATE;
--
-- Ver_1.1 E_本稼動_16375 ADD Start
  FUNCTION  chek_lot_unit_price(
      id_base_date          IN DATE       --  1.基準日
    , in_lot_id             IN NUMBER     --  2.ロットID
    , iv_unit_price         IN VARCHAR2   --  3.単価
  ) RETURN NUMBER;
--
-- Ver_1.1 E_本稼動_16375 ADD End
END xxcmn_common5_pkg;
/
