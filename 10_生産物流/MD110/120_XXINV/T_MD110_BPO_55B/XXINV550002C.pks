CREATE OR REPLACE PACKAGE XXINV550002C
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : XXINV550002C(spec)
 * Description      : 受払台帳作成
 * MD.050/070       : 在庫(帳票)Draft2A (T_MD050_BPO_550)
 *                    受払台帳Draft1A   (T_MD070_BPO_55B)
 * Version          : 1.38
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
 *  2008/07/01    1.12  Kazuo Kumamoto   結合テスト障害対応(パラメータ.品目・商品区分・品目区分組み合わせチェック)
 *  2008/07/01    1.13  Kazuo Kumamoto   結合テスト障害対応(パラメータ.物流ブロック・倉庫/保管倉庫をOR条件とする)
 *  2008/07/02    1.14  Satoshi Yunba    禁則文字対応
 *  2008/07/07    1.15 Yasuhisa Yamamoto 結合テスト障害対応(発注実績の取得数量を発注明細から取得するように変更)
 *  2008/09/16    1.16  Hitomi Itou      T_TE080_BPO_550 指摘31(積送ありの場合も同一倉庫内移動の場合、抽出しない。)
 *                                       T_TE080_BPO_550 指摘28(在庫調整実績情報の受入返品情報取得(相手先在庫)を追加)
 *                                       T_TE080_BPO_540 指摘44(同上)
 *                                       変更要求#171(同上)
 *  2008/09/22    1.17  Hitomi Itou      T_TE080_BPO_550 指摘28(在庫調整実績情報の外注出来高情報・受入返品情報取得(相手先在庫)の相手先を取引先に変更)
 *  2008/10/20    1.18  Takao Ohashi     T_S_492(出力されない処理区分と事由コートの組み合わせを出力させる)
 *  2008/10/23    1.19  Takao Ohashi     指摘442(品目振替情報の取得条件修正)
 *  2008/11/07    1.20  Hitomi Itou      統合テスト指摘548対応
 *  2008/11/17    1.21  Takao Ohashi     指摘356対応
 *  2008/11/20    1.22  Naoki Fukuda     統合テスト障害696対応
 *  2008/11/21    1.23  Natsuki Yoshida  統合テスト障害687対応
 *  2008/11/28    1.24  Hitomi Itou      本番障害#227対応
 *  2008/12/02    1.25  Natsuki Yoshida  本番障害#327対応
 *  2008/12/02    1.26  Takao Ohashi     本番障害#327対応
 *  2008/12/03    1.27  Natsuki Yoshida  本番障害#371対応
 *  2008/12/04    1.28  Hitomi Itou      本番障害#362対応
 *  2008/12/18    1.29 Yasuhisa Yamamoto 本番障害#732,#772対応
 *  2008/12/24    1.30  Natsuki Yoshida  本番障害#842対応(履歴は全て削除)
 *  2008/12/29    1.31  Natsuki Yoshida  本番障害#809,#899対応
 *  2008/12/30    1.32  Natsuki Yoshida  本番障害#705対応
 *  2009/01/05    1.33  Akiyoshi Shiina  本番障害#916対応
 *  2009/02/04    1.34 Yasuhisa Yamamoto 本番障害#1120対応
 *  2009/02/05    1.35 Yasuhisa Yamamoto 本番障害#1120対応(追加対応)
 *  2009/02/13    1.36 Yasuhisa Yamamoto 本番障害#1189対応
 *  2009/03/30    1.37  Akiyoshi Shiina  本番障害#1346対応
 *  2009/10/14    1.38 Masayuki Nomura   本番障害#1659対応
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
