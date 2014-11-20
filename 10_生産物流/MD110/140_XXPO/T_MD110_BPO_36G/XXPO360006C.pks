CREATE OR REPLACE PACKAGE xxpo360006c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : XXPO360006C(spec)
 * Description      : 仕入取引明細表
 * MD.050           : 有償支給帳票Issue1.0(T_MD050_BPO_360)
 * MD.070           : 有償支給帳票Issue1.0(T_MD070_BPO_36G)
 * Version          : 1.32
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
 *  2008/03/13    1.0   K.Kamiyoshi      新規作成
 *  2008/05/09    1.1   K.Kamiyoshi      不具合ID5-9対応
 *  2008/05/12    1.2   K.Kamiyoshi      不具合ID10対応
 *  2008/05/13    1.3   K.Kamiyoshi      不具合ID11対応
 *  2008/05/13    1.4   T.Endou         (外部ユーザー)発注なし返品時、セキュリティ要件の対応
 *  2008/05/22    1.5   T.Endou          通常受入時、発注納入明細.口銭区分、賦課金区分を使用する。
 *                                       斡旋者は外部結合とする。
 *                                       納入日の範囲指定は、すべてで受入返品アドオンを使用する。
 *  2008/05/23    1.6   Y.Majikina       数量取得項目の変更。金額計算の不備を修正
 *  2008/05/24    1.7   Y.Majikina       仕入返品時の符号を修正
 *  2008/05/26    1.8   Y.Majikina       発注あり仕入先返品時、粉引率、粉引後単価、単価、
 *                                       口銭区分、口銭、預り口銭金額、賦課金区分、賦課金、
 *                                       賦課金額は、受入返品実績アドオンより取得する
 *  2008/05/28    1.9   Y.Majikina       リッチテキストの改ページセクションの変更による
 *                                       XML構造の修正
 *  2008/05/29    1.10  T.Endou          納入日の範囲指定は、すべて受入返品アドオンを使用する
 *                                       修正はしてあったが、帳票に表示する部分も修正する。
 *  2008/06/03    1.11  T.Endou          担当部署または担当者名が未取得時は正常終了に修正
 *  2008/06/11    1.12  T.Endou          発注なし仕入先返品の場合、返品アドオンの斡旋者IDを使用する
 *  2008/06/17    1.13  T.Ikehara        TEMP領域エラー回避のため、xxpo_categories_vを
 *                                       使用しないようにする
 *  2008/06/24    1.14  T.Ikehara        特定文字列を出力しようとすると、エラーとなり帳票が出力
 *                                       されない現象への対応
 *  2008/07/23    1.15  Y.Ishikawa       XXCMN_ITEM_CATEGORIES3_V→XXCMN_ITEM_CATEGORIES6_V変更
 *  2008/11/06    1.16  Y.Yamamoto       統合指摘#471対応、T_S_430対応
 *  2008/12/02    1.17  H.Marushita      本番障害#348対応
 *  2008/12/03    1.18  H.Marushita      本番障害#374対応
 *  2008/12/05    1.19  A.Shiina         本番障害#499,#506対応
 *  2008/12/07    1.20  N.Yoshida        本番障害#533対応
 *  2009/01/09    1.21  N.Yoshida        本番障害#984対応
 *  2009/03/30    1.22  A.Shiina         本番障害#1346対応
 *  2009/04/02    1.23  A.Shiina         本番障害#1370対応
 *  2009/04/03    1.24  A.Shiina         本番障害#1379対応(v1.22対応取消)
 *  2009/04/23    1.25  A.Shiina         本番障害#1429対応
 *  2009/05/18    1.26  T.Yoshimoto      本番障害#1478対応
 *  2009/06/02    1.27  T.Yoshimoto      本番障害#1515,1516対応
 *  2009/07/03    1.28  T.Yoshimoto      本番障害#1560対応
 *  2009/07/06    1.29  T.Yoshimoto      本番障害#1565対応
 *  2009/08/10    1.30  T.Yoshimoto      本番障害#1596対応
 *  2009/09/24    1.31  T.Yoshimoto      本番障害#1523対応
 *  2010/01/12    1.32  T.Yoshimoto      E_本稼動#892対応
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
      errbuf                OUT   VARCHAR2  -- エラーメッセージ
     ,retcode               OUT   VARCHAR2  -- エラーコード
     ,iv_out_flg            IN    VARCHAR2  --出力区分
     ,iv_deliver_from       IN    VARCHAR2  --納入日FROM
     ,iv_deliver_to         IN    VARCHAR2  --納入日TO
     ,iv_dept_code1         IN    VARCHAR2  --担当部署１
     ,iv_dept_code2         IN    VARCHAR2  --担当部署２
     ,iv_dept_code3         IN    VARCHAR2  --担当部署３
     ,iv_dept_code4         IN    VARCHAR2  --担当部署４
     ,iv_dept_code5         IN    VARCHAR2  --担当部署５
     ,iv_vendor_code1       IN    VARCHAR2  -- 取引先1
     ,iv_vendor_code2       IN    VARCHAR2  -- 取引先2
     ,iv_vendor_code3       IN    VARCHAR2  -- 取引先3
     ,iv_vendor_code4       IN    VARCHAR2  -- 取引先4
     ,iv_vendor_code5       IN    VARCHAR2  -- 取引先5
     ,iv_mediator_code1     IN    VARCHAR2  -- 斡旋者1
     ,iv_mediator_code2     IN    VARCHAR2  -- 斡旋者2
     ,iv_mediator_code3     IN    VARCHAR2  -- 斡旋者3
     ,iv_mediator_code4     IN    VARCHAR2  -- 斡旋者4
     ,iv_mediator_code5     IN    VARCHAR2  -- 斡旋者5
     ,iv_po_num             IN    VARCHAR2  -- 発注番号
     ,iv_item_code          IN    VARCHAR2  -- 品目コード
     ,iv_security_flg       IN    VARCHAR2  -- セキュリティ区分
    );
--
END xxpo360006c;
/
