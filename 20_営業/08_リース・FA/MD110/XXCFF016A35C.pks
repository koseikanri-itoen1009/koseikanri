CREATE OR REPLACE PACKAGE XXCFF016A35C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2012. All rights reserved.
 *
 * Package Name     : XXCFF016A35C(spec)
 * Description      : リース契約メンテナンス
 * MD.050           : MD050_CFF_016_A35_リース契約メンテナンス
 * Version          : 1.0
 *
 * Program List
 * -------------------- ------------------------------------------------------------
 *  Name                 Description
 * -------------------- ------------------------------------------------------------
 *  main                 コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2012/10/12    1.0   SCSK谷口         新規作成
 *
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf                  OUT VARCHAR2,   --    エラーメッセージ #固定#
    retcode                 OUT VARCHAR2,   --    エラーコード     #固定#
    iv_contract_number      IN  VARCHAR2,   -- 1. 契約番号
    iv_lease_company        IN  VARCHAR2,   -- 2. リース会社
    iv_update_reason        IN  VARCHAR2,   -- 3. 更新事由
    iv_lease_start_date     IN  VARCHAR2,   -- 4. リース開始日
    iv_lease_end_date       IN  VARCHAR2,   -- 5. リース終了日
    iv_payment_frequency    IN  VARCHAR2,   -- 6. 支払回数
    iv_contract_date        IN  VARCHAR2,   -- 7. 契約日
    iv_first_payment_date   IN  VARCHAR2,   -- 8. 初回支払日
    iv_second_payment_date  IN  VARCHAR2,   -- 9. ２回目支払日
    iv_third_payment_date   IN  VARCHAR2,   -- 10.３回目以降支払日
    iv_comments             IN  VARCHAR2    -- 11.件名
  );
END XXCFF016A35C;
/
