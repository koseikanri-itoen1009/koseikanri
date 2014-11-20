CREATE OR REPLACE PACKAGE xxpo360005c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : XXPO360005C(spec)
 * Description      : 代行請求書（帳票）
 * MD.050/070       : 仕入（帳票）Issue1.0  (T_MD050_BPO_360)
 *                    代行請求書            (T_MD070_BPO_36F)
 * Version          : 1.15
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
 *  2008/04/04    1.0   T.Endou          新規作成
 *  2008/05/09    1.1   T.Endou          発注なし仕入先返品データが抽出されない対応
 *  2008/05/13    1.2   T.Endou          OPM品目情報VIEW参照を削除
 *  2008/05/13    1.3   T.Endou          発注なし仕入先返品のときに使用する単価が不正
 *                                       「単価」から「粉引後単価」に修正
 *  2008/05/14    1.4   T.Endou          セキュリティ要件不具合対応
 *  2008/05/23    1.5   Y.Majikina       数量取得項目の変更。金額計算の不備を修正
 *  2008/05/26    1.6   T.Endou          発注あり仕入先返品の場合は、以下を使用する修正
 *                                       1.返品アドオン.粉引後単価
 *                                       2.返品アドオン.預かり口銭金額
 *                                       3.返品アドオン.賦課金額
 *  2008/05/26    1.7   T.Endou          外部倉庫ユーザーのセキュリティは不要なため削除
 *  2008/06/25    1.8   T.Endou          特定文字列を出力しようとすると、エラーとなり帳票が出力
 *                                       されない現象への対応
 *  2008/10/22    1.9   I.Higa           取引先の取得項目が不正（仕入先名⇒正式名）
 *  2008/10/24    1.10  T.Ohashi         T_S_432対応（敬称の付与）
 *  2008/11/04    1.11  Y.Yamamoto       統合障害#471
 *  2008/11/28    1.12  T.Yoshimoto      本番障害#204
 *  2009/01/08    1.13  N.Yoshida        本番障害#970
 *  2009/03/30    1.14  A.Shiina         本番障害#1346
 *  2009/05/26    1.15  T.Yoshimoto      本番障害#1478
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
      errbuf                OUT    VARCHAR2         -- エラーメッセージ
     ,retcode               OUT    VARCHAR2         -- エラーコード
     ,iv_deliver_from       IN     VARCHAR2         -- 納入日FROM
     ,iv_deliver_to         IN     VARCHAR2         -- 納入日TO
     ,iv_vendor_code1       IN     VARCHAR2         -- 取引先１
     ,iv_vendor_code2       IN     VARCHAR2         -- 取引先２
     ,iv_vendor_code3       IN     VARCHAR2         -- 取引先３
     ,iv_vendor_code4       IN     VARCHAR2         -- 取引先４
     ,iv_vendor_code5       IN     VARCHAR2         -- 取引先５
     ,iv_assen_vendor_code1 IN     VARCHAR2         -- 斡旋者１
     ,iv_assen_vendor_code2 IN     VARCHAR2         -- 斡旋者２
     ,iv_assen_vendor_code3 IN     VARCHAR2         -- 斡旋者３
     ,iv_assen_vendor_code4 IN     VARCHAR2         -- 斡旋者４
     ,iv_assen_vendor_code5 IN     VARCHAR2         -- 斡旋者５
     ,iv_dept_code1         IN     VARCHAR2         -- 担当部署１
     ,iv_dept_code2         IN     VARCHAR2         -- 担当部署２
     ,iv_dept_code3         IN     VARCHAR2         -- 担当部署３
     ,iv_dept_code4         IN     VARCHAR2         -- 担当部署４
     ,iv_dept_code5         IN     VARCHAR2         -- 担当部署５
     ,iv_security_flg       IN     VARCHAR2         -- セキュリティ区分
    ) ;
END xxpo360005c ;
/
