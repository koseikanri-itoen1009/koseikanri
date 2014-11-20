CREATE OR REPLACE PACKAGE xxpo360004c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : XXPO360004C(spec)
 * Description      : 仕入明細表
 * MD.050/070       : 有償支給帳票Issue1.0(T_MD050_BPO_360)
 *                  : 有償支給帳票Issue1.0(T_MD070_BPO_36E)
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
 *  2008/03/17    1.0   Y.Majikina       新規作成
 *  2008/05/12    1.1   Y.Majikina       受入返品、発注なし返品時の総合計値に
 *                                       マイナスを掛けるよう修正
 *                                       発注なし仕入れ返品の場合、受入返品実績の換算入数を
 *                                       取得するよう修正
 *  2008/05/13    1.2   Y.Majikina       品目ごとに品目計が表示されない点を修正
 *                                       データによって、YY/MM/DD、YY/M/Dのような書式で出力される
 *                                       点を修正
 *  2008/05/14    1.3   Y.Majikina       担当部署、担当者名の最大長処理を追加
 *                                       セキュリティの条件を修正
 *  2008/05/23    1.4   Y.Majikina       数量取得項目の変更。金額計算の不備を修正
 *  2008/05/23    1.5   Y.Majikina       セキュリティ区分２でログインしたときにSQLエラーになる点を
 *                                       修正
 *  2008/05/26    1.6   R.Tomoyose       発注あり仕入先返品時、単価は受入返品実績アドオンより取得
 *  2008/05/29    1.7   T.Ikehara        計の出力ﾌﾗｸﾞを追加、修正(ﾚｲｱｳﾄのｾｯｼｮﾝ修正対応の為)
 *                                        パラメータ：担当部署の際の出力内容を変更
 *  2008/06/13    1.8   Y.Ishikawa        ロットコピーにより作成した発注の仕入帳票を出力すると
 *                                       、１つの明細の情報が２件以上されないよう修正。
 *  2008/06/16    1.9   I.Higa           TEMP領域エラー回避のため、xxpo_categories_vを２つ以上使用
 *                                       しないようにする
 *  2008/06/25    1.10  T.Endou          特定文字列を出力しようとすると、エラーとなり帳票が出力
 *                                       されない現象への対応
 *  2008/06/25    1.11  Y.Ishikawa       総数は、数量(QUANTITY)ではなく受入返品数量
 *                                       (RCV_RTN_QUANTITY)をセットする
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
      errbuf                OUT   VARCHAR2,  -- エラーメッセージ
      retcode               OUT   VARCHAR2,  -- エラーコード
      iv_deliver_from       IN    VARCHAR2,  -- 納入日FROM
      iv_deliver_to         IN    VARCHAR2,  -- 納入日TO
      iv_item_division      IN    VARCHAR2,  -- 商品区分
      iv_dept_code          IN    VARCHAR2,  -- 担当部署
      iv_vendor_code1       IN    VARCHAR2,  -- 取引先1
      iv_vendor_code2       IN    VARCHAR2,  -- 取引先2
      iv_vendor_code3       IN    VARCHAR2,  -- 取引先3
      iv_vendor_code4       IN    VARCHAR2,  -- 取引先4
      iv_vendor_code5       IN    VARCHAR2,  -- 取引先5
      iv_art_division       IN    VARCHAR2,  -- 品目区分
      iv_crowd1             IN    VARCHAR2,  -- 群1
      iv_crowd2             IN    VARCHAR2,  -- 群2
      iv_crowd3             IN    VARCHAR2,  -- 群3
      iv_art1               IN    VARCHAR2,  -- 品目1
      iv_art2               IN    VARCHAR2,  -- 品目2
      iv_art3               IN    VARCHAR2,  -- 品目3
      iv_security_flg       IN    VARCHAR2   -- セキュリティ区分
    );
--
END xxpo360004c;
/
