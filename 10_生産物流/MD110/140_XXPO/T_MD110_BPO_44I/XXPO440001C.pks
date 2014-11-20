CREATE OR REPLACE PACKAGE xxpo440001c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxpo440001c(spec)
 * Description      : 有償出庫指示書
 * MD.050/070       : 有償支給帳票Issue1.0(T_MD050_BPO_444)
 *                    有償支給帳票Issue1.0(T_MD070_BPO_44I)
 * Version          : 1.4
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
 *  2008/03/19    1.0   Oracle井澤直也   新規作成
 *  2008/05/16    1.1   Oracle藤井良平   結合テスト不具合（機能ID：440、不具合ID：5）
 *                                       結合テスト不具合（機能ID：440、不具合ID：6）
 *                                       結合テスト不具合（機能ID：440、不具合ID：7）
 *                                       結合テスト不具合（機能ID：440、不具合ID：8）
 *  2008/05/19    1.2   Oracle藤井良平   結合テスト不具合（機能ID：440、不具合ID：9）
 *                                       結合テスト不具合（機能ID：440、不具合ID：10）
 *                                       結合テスト不具合（機能ID：440、不具合ID：11）
 *                                       結合テスト不具合（機能ID：440、不具合ID：12）
 *                                       結合テスト不具合（機能ID：440、不具合ID：13）
 *  2008/05/21    1.3   Oracle田畑祐亮   結合テスト不具合（機能ID：440、不具合ID：19）
 *  2008/06/19    1.4   Oracle熊本和郎   結合テスト不具合
 *                                         1.レビュー指摘事項No.11：適用日管理を行う。
 *                                         2.レビュー指摘事項No.13：取引先名、配送先名の
 *                                           折り返しをコンカレント側で行う。
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
      errbuf                OUT    VARCHAR2         -- エラーメッセージ
     ,retcode               OUT    VARCHAR2         -- エラーコード
     ,iv_use_purpose        IN     VARCHAR2         -- 01 : 使用目的
     ,iv_request_no         IN     VARCHAR2         -- 02 : 依頼No
     ,iv_exec_user_dept     IN     VARCHAR2         -- 03 : 担当部署
     ,iv_update_exec_user   IN     VARCHAR2         -- 04 : 更新担当
     ,iv_update_date_from   IN     VARCHAR2         -- 05 : 更新日付From
     ,iv_update_date_to     IN     VARCHAR2         -- 06 : 更新日付To
     ,iv_vendor             IN     VARCHAR2         -- 07 : 取引先
     ,iv_deliver_to         IN     VARCHAR2         -- 08 : 配送先
     ,iv_shipped_locat_code IN     VARCHAR2         -- 09 : 出庫倉庫
     ,iv_shipped_date_from  IN     VARCHAR2         -- 10 : 出庫日From
     ,iv_shipped_date_to    IN     VARCHAR2         -- 11 : 出庫日To
     ,iv_prod_class         IN     VARCHAR2         -- 12 : 商品区分
     ,iv_item_class         IN     VARCHAR2         -- 13 : 品目区分
     ,iv_security_class     IN     VARCHAR2         -- 14 : 有償セキュリティ区分
    ) ;
--
END xxpo440001c ;
/
