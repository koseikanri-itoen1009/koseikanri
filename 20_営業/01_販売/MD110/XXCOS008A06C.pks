CREATE OR REPLACE PACKAGE APPS.XXCOS008A06C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOS008A06C(spec)
 * Description      : 出荷依頼実績からの受注作成
 * MD.050           : 出荷依頼実績からの受注作成 MD050_COS_008_A06
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
 *  2010/03/23    1.0   H.Itou           main新規作成
 *
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf                         OUT  VARCHAR2        --   エラーメッセージ #固定#
   ,retcode                        OUT  VARCHAR2        --   エラーコード     #固定#
   ,iv_delivery_base_code          IN   VARCHAR2        -- 01.納品拠点コード
   ,iv_input_sales_branch          IN   VARCHAR2        -- 02.入力拠点コード
   ,iv_head_sales_branch           IN   VARCHAR2        -- 03.管轄拠点コード
   ,iv_request_no                  IN   VARCHAR2        -- 04.出荷依頼No
   ,iv_entered_by_code             IN   VARCHAR2        -- 05.出荷依頼入力者
   ,iv_cust_code                   IN   VARCHAR2        -- 06.顧客コード
   ,iv_deliver_to                  IN   VARCHAR2        -- 07.配送先コード
   ,iv_location_code               IN   VARCHAR2        -- 08.出庫元コード
   ,iv_schedule_ship_date_from     IN   VARCHAR2        -- 09.出庫日（FROM）
   ,iv_schedule_ship_date_to       IN   VARCHAR2        -- 10.出庫日（TO）
   ,iv_request_date_from           IN   VARCHAR2        -- 11.着日（FROM）
   ,iv_request_date_to             IN   VARCHAR2        -- 12.着日（TO）
   ,iv_cust_po_number              IN   VARCHAR2        -- 13.顧客発注番号
   ,iv_customer_po_set_type        IN   VARCHAR2        -- 14.顧客発注番号区分
   ,iv_uom_type                    IN   VARCHAR2        -- 15.換算単位区分
   ,iv_item_type                   IN   VARCHAR2        -- 16.商品区分
   ,iv_transaction_type_id         IN   VARCHAR2        -- 17.出庫形態
   ,iv_chain_code_sales            IN   VARCHAR2        -- 18.販売先チェーン
   ,iv_chain_code_deliv            IN   VARCHAR2        -- 19.納品先チェーン
  );
END XXCOS008A06C;
/
