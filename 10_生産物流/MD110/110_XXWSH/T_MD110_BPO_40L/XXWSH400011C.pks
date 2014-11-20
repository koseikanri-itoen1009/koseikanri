CREATE OR REPLACE PACKAGE xxwsh400011c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxwsh400011c(spec)
 * Description      : 出荷依頼締め起動処理
 * MD.050           : T_MD050_BPO_401_出荷依頼
 * MD.070           : 出荷依頼締め処理 T_MD070_BPO_40H
 * Version          : 1.1
 *
 * Program List
 * -------------------- ------------------------------------------------------------
 *  Name                 Description
 * -------------------- ------------------------------------------------------------
 *  main                 メイン関数
 *
 *  Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009/01/16   1.0   T.Ohashi         初回作成
 *  2009/02/23   1.1   M.Nomura         本番#1176対応（追加修正）
 *
 *****************************************************************************************/
--
  -- メイン関数
  PROCEDURE main(
    errbuf                   OUT NOCOPY VARCHAR2,        --  エラー・メッセージ
    retcode                  OUT NOCOPY VARCHAR2,        --  リターン・コード
    iv_order_type_id         IN  VARCHAR2,               --  1.出庫形態ID
    iv_deliver_from          IN  VARCHAR2,               --  2.出荷元
    iv_sales_base            IN  VARCHAR2,               --  3.拠点
    iv_sales_base_category   IN  VARCHAR2,               --  4.拠点カテゴリ
    iv_lead_time_day         IN  VARCHAR2,               --  5.生産物流LT
    iv_schedule_ship_date    IN  VARCHAR2,               --  6.出庫日
    iv_base_record_class     IN  VARCHAR2,               --  7.基準レコード区分
    iv_request_no            IN  VARCHAR2,               --  8.依頼No
    iv_tighten_class         IN  VARCHAR2,               --  9.締め処理区分
    iv_prod_class            IN  VARCHAR2,               -- 10.商品区分
    iv_tightening_program_id IN  VARCHAR2,               -- 11.締めコンカレントID
    iv_instruction_dept      IN  VARCHAR2                -- 12.部署
    );
END xxwsh400011c;
/
