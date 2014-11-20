CREATE OR REPLACE PACKAGE XXCOP006A01C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOP006A01C(spec)
 * Description      : 横持計画
 * MD.050           : 横持計画 MD050_COP_006_A01
 * Version          : 1.1
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
 *  2009/12/01    1.0   M.Hokkanji       新規作成
 *  2010/02/03    1.1   Y.Goto           E_本稼動_01222
 *
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
     errbuf                 OUT    VARCHAR2                 --   エラーメッセージ #固定#
    ,retcode                OUT    VARCHAR2                 --   エラーコード     #固定#
    ,iv_planning_date_from  IN     VARCHAR2                 -- 1.計画立案期間(FROM)
    ,iv_planning_date_to    IN     VARCHAR2                 -- 2.計画立案期間(TO)
    ,iv_plan_type           IN     VARCHAR2                 -- 3.出荷計画区分
    ,iv_shipment_date_from  IN     VARCHAR2                 -- 4.出荷ペース計画期間(FROM)
    ,iv_shipment_date_to    IN     VARCHAR2                 -- 5.出荷ペース計画期間(TO)
    ,iv_forecast_date_from  IN     VARCHAR2                 -- 6.出荷予測期間(FROM)
    ,iv_forecast_date_to    IN     VARCHAR2                 -- 7.出荷予測期間(TO)
    ,iv_allocated_date      IN     VARCHAR2                 -- 8.出荷引当済日
    ,iv_item_code           IN     VARCHAR2                 -- 9.品目コード
--20100203_Ver1.1_E_本稼動_01222_SCS.Goto_ADD_START
    ,iv_working_days        IN     VARCHAR2                 --10.稼動日数
    ,iv_stock_adjust_value  IN     VARCHAR2                 --11.在庫日数調整値
--20100203_Ver1.1_E_本稼動_01222_SCS.Goto_ADD_END
  );
END XXCOP006A01C;
/
