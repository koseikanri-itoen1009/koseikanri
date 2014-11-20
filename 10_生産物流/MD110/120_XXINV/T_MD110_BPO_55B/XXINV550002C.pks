CREATE OR REPLACE PACKAGE XXINV550002C
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : XXINV550002C(spec)
 * Description      : 受払台帳作成
 * MD.050/070       : 在庫(帳票)Draft2A (T_MD050_BPO_550)
 *                    受払台帳Draft1A   (T_MD070_BPO_55B)
 * Version          : 1.11
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
 *  2008/02/07    1.0   Kazuo Kumamoto   新規作成
 *  2008/05/07    1.1   Kazuo Kumamoto   内部変更要求#33対応
 *  2008/05/15    1.2   Kazuo Kumamoto   内部変更要求#93対応
 *  2008/05/15    1.3   Kazuo Kumamoto   SQLチューニング
 *  2008/06/04    1.4   Takao Ohashi     結合テスト不具合修正
 *  2008/06/05    1.5   Kazuo Kumamoto   結合テスト障害対応(出荷の出荷数を*-1)
 *  2008/06/05    1.6   Kazuo Kumamoto   SQLチューニング
 *  2008/06/05    1.7   Kazuo Kumamoto   結合テスト障害対応(出荷の相手先取得方法を変更)
 *  2008/06/05    1.8   Kazuo Kumamoto   結合テスト障害対応(出荷の受払区分アドオンマスタ抽出条件変更)
 *  2008/06/09    1.9   Kazuo Kumamoto   結合テスト障害対応(生産の日付条件変更)
 *  2008/06/09    1.10  Kazuo Kumamoto   結合テスト障害対応(出荷の受払区分アドオンマスタ抽出条件追加)
 *  2008/06/23    1.11  Kazuo Kumamoto   結合テスト障害対応(単位の出力内容変更)
 *
 *****************************************************************************************/
--
--#######################  固定グローバル変数宣言部 START   #######################
--
  TYPE xml_rec  IS RECORD (tag_name  VARCHAR2(50)
                          ,tag_value VARCHAR2(2000)
                          ,tag_type  CHAR(1));
--
  TYPE xml_data IS TABLE OF xml_rec INDEX BY BINARY_INTEGER;
--
--################################  固定部 END   ###############################
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf               OUT    VARCHAR2         --   エラーメッセージ
   ,retcode              OUT    VARCHAR2         --   エラーコード
   ,iv_ymd_from          IN     VARCHAR2         --    1. 年月日_FROM
   ,iv_ymd_to            IN     VARCHAR2         --    2. 年月日_TO
   ,iv_base_date         IN     VARCHAR2         --    3. 着日基準／発日基準
   ,iv_inout_ctl         IN     VARCHAR2         --    4. 入出庫区分
   ,iv_prod_div          IN     VARCHAR2         --    5. 商品区分
   ,iv_unit_ctl          IN     VARCHAR2         --    6. 単位区分
   ,iv_wh_loc_ctl        IN     VARCHAR2         --    7. 倉庫/保管倉庫選択区分
   ,iv_wh_code_01        IN     VARCHAR2         --    8. 倉庫/保管倉庫コード1
   ,iv_wh_code_02        IN     VARCHAR2         --    9. 倉庫/保管倉庫コード2
   ,iv_wh_code_03        IN     VARCHAR2         --   10. 倉庫/保管倉庫コード3
   ,iv_block_01          IN     VARCHAR2         --   11. ブロック1
   ,iv_block_02          IN     VARCHAR2         --   12. ブロック2
   ,iv_block_03          IN     VARCHAR2         --   13. ブロック3
   ,iv_item_div          IN     VARCHAR2         --   14. 品目区分
   ,iv_item_code_01      IN     VARCHAR2         --   15. 品目コード1
   ,iv_item_code_02      IN     VARCHAR2         --   16. 品目コード2
   ,iv_item_code_03      IN     VARCHAR2         --   17. 品目コード3
   ,iv_lot_no_01         IN     VARCHAR2         --   18. ロットNo1
   ,iv_lot_no_02         IN     VARCHAR2         --   19. ロットNo2
   ,iv_lot_no_03         IN     VARCHAR2         --   20. ロットNo3
   ,iv_mnfctr_date_01    IN     VARCHAR2         --   21. 製造年月日1
   ,iv_mnfctr_date_02    IN     VARCHAR2         --   22. 製造年月日2
   ,iv_mnfctr_date_03    IN     VARCHAR2         --   23. 製造年月日3
   ,iv_reason_code_01    IN     VARCHAR2         --   24. 事由コード1
   ,iv_reason_code_02    IN     VARCHAR2         --   25. 事由コード2
   ,iv_reason_code_03    IN     VARCHAR2         --   26. 事由コード3
   ,iv_symbol            IN     VARCHAR2         --   27. 固有記号
  );
END XXINV550002C;
/
