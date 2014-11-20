CREATE OR REPLACE PACKAGE XXINV550003C
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : XXINV550003C(spec)
 * Description      : 計画・移動・在庫：在庫(帳票)
 * MD.050/070       : T_MD050_BPO_550_在庫(帳票)Issue1.0 (T_MD050_BPO_550)
 *                  : 振替明細表                         (T_MD070_BPO_55C)
 * Version          : 1.23
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
 *  2008/2/18     1.0  Yusuke Tabata    新規作成
 *  2008/5/01     1.1  Yusuke Tabata    変更要求対応
 *  2008/6/03     1.2  Takao Ohashi     結合テスト不具合
 *  2008/6/06     1.3  Takao Ohashi     結合テスト不具合
 *  2008/6/17     1.4  Kazuo Kumamoto   結合テスト不具合(ソート順変更・受入だけの伝票は先に出力)
 *  2008/07/02    1.5  Satoshi Yunba    禁則文字対応
 *  2008/09/26    1.6  Akiyosi Shiina   T_S_528対応
 *  2008/10/16    1.7  Takao Ohashi     T_S_492,T_S_557,T_S_494対応
 *  2008/11/11    1.8  Takao Ohashi     指摘549対応
 *  2008/11/20    1.9  Takao Ohashi     指摘691対応
 *  2008/11/28    1.10 Akiyosi Shiina   本番#227対応
 *  2008/12/06    1.11 Takahito Miyata  本番#521対応
 *  2008/12/10    1.12 Takao Ohashi     本番#639対応
 *  2008/12/16    1.13 Naoki Fukuda     本番#639対応
 *  2008/12/26    1.14 Takao Ohashi     本番#809,867対応
 *  2009/01/09    1.15 Takao Ohashi     I_S_50対応(履歴全削除)
 *  2009/01/15    1.16 Natsuki Yoshida  I_S_50対応(帳票タイトル対応)、本番#972
 *  2009/01/16    1.17 Takao Ohashi     I_S_50対応(予実区分値修正)
 *  2009/01/20    1.18 Akiyoshi Shiina  本番#263対応
 *  2009/03/06    1.19 H.Itou           本番#1283対応
 *  2009/03/12    1.20 Akiyoshi Shiina  本番#1296対応
 *  2009/03/17    1.21 Akiyoshi Shiina  本番#1325対応
 *  2009/05/12    1.22 M.Nomura         本番#1468対応
 *  2009/06/25    1.23 Marushita        本番#1346対応
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
 PROCEDURE main
    (
      errbuf                  OUT    VARCHAR2     -- エラーメッセージ
     ,retcode                 OUT    VARCHAR2     -- エラーコード
     ,iv_target_class         IN     VARCHAR2     -- 01 : 予実区分
     ,iv_date_from            IN     VARCHAR2     -- 02 : 年月日_FROM
     ,iv_date_to              IN     VARCHAR2     -- 03 : 年月日_TO
     ,iv_out_item_ctl         IN     VARCHAR2     -- 04 : 払出品目区分
     ,iv_item1                IN     VARCHAR2     -- 05 : 品目ID1
     ,iv_item2                IN     VARCHAR2     -- 06 : 品目ID2
     ,iv_item3                IN     VARCHAR2     -- 07 : 品目ID3
     ,iv_reason_code          IN     VARCHAR2     -- 08 : 事由コード
     ,iv_item_location_id     IN     VARCHAR2     -- 09 : 保管倉庫ID
     ,iv_dept_id              IN     VARCHAR2     -- 10 : 担当部署ID
     ,iv_entry_no1            IN     VARCHAR2     -- 11 : 伝票No1
     ,iv_entry_no2            IN     VARCHAR2     -- 12 : 伝票No2
     ,iv_entry_no3            IN     VARCHAR2     -- 13 : 伝票No3
     ,iv_entry_no4            IN     VARCHAR2     -- 14 : 伝票No4
     ,iv_entry_no5            IN     VARCHAR2     -- 15 : 伝票No5
     ,iv_price_ctl_flg        IN     VARCHAR2     -- 16 : 金額表示
     ,iv_emp_no               IN     VARCHAR2     -- 17 : 担当者
     ,iv_creation_date_from   IN     VARCHAR2     -- 18 : 更新時間FROM
     ,iv_creation_date_to     IN     VARCHAR2     -- 19 : 更新時間TO
     
    ) ;
END XXINV550003C ;
/
