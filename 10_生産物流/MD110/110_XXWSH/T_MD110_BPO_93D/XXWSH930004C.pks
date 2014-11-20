CREATE OR REPLACE PACKAGE xxwsh930004c 
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxwsh930004C(spec)
 * Description      : 入出庫情報差異リスト（出庫基準）
 * MD.050/070       : 生産物流共通（出荷・移動インタフェース）Issue1.0(T_MD050_BPO_930)
 *                    生産物流共通（出荷・移動インタフェース）Issue1.0(T_MD070_BPO_93D)
 * Version          : 1.14
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
 *  2008/02/19    1.0   Oracle井澤直也   新規作成
 *  2008/06/23    1.1   Oracle大橋孝郎   不具合ログ対応
 *  2008/06/25    1.2   Oracle大橋孝郎   不具合ログ対応
 *  2008/06/30    1.3   Oracle大橋孝郎   不具合ログ対応
 *  2008/07/08    1.4   Oracle弓場哲士   禁則文字対応
 *  2008/07/09    1.5   Oracle椎名昭圭   変更要求対応#92
 *  2008/07/28    1.6   Oracle椎名昭圭   ST不具合#197、内部課題#32、内部変更要求#180対応
 *  2008/10/09    1.7   Oracle福田直樹   統合テスト障害#338対応
 *  2008/10/17    1.8   Oracle福田直樹   課題T_S_458対応(部署を任意入力パラメータに変更。PACKAGEの修正はなし)
 *  2008/10/17    1.8   Oracle福田直樹   変更要求#210対応
 *  2008/10/20    1.9   Oracle福田直樹   課題T_S_486対応
 *  2008/10/20    1.9   Oracle福田直樹   統合テスト障害#394(1)対応
 *  2008/10/20    1.9   Oracle福田直樹   統合テスト障害#394(2)対応
 *  2008/10/31    1.10  Oracle福田直樹   統合指摘#462対応
 *  2008/11/17    1.11  Oracle福田直樹   統合指摘#651対応(課題T_S_486再対応)
 *  2008/12/17    1.12  Oracle福田直樹   本番障害#764対応
 *  2008/12/25    1.13  Oracle福田直樹   本番障害#831対応
 *  2009/01/06    1.14  Oracle吉田夏樹   本番障害#929対応
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
     ,iv_prod_div           IN     VARCHAR2         -- 01 : 商品区分
     ,iv_item_div           IN     VARCHAR2         -- 02 : 品目区分
     ,iv_date_from          IN     VARCHAR2         -- 03 : 出庫日From
     ,iv_date_to            IN     VARCHAR2         -- 04 : 出庫日To
     ,iv_dept_code          IN     VARCHAR2         -- 05 : 部署
     ,iv_output_type        IN     VARCHAR2         -- 06 : 出力区分
     ,iv_block_01           IN     VARCHAR2         -- 07 : ブロック１
     ,iv_block_02           IN     VARCHAR2         -- 08 : ブロック２
     ,iv_block_03           IN     VARCHAR2         -- 09 : ブロック３
     ,iv_ship_to_locat_code IN     VARCHAR2         -- 10 : 出庫元
     ,iv_online_type        IN     VARCHAR2         -- 11 : オンライン対象区分
     ,iv_request_no         IN     VARCHAR2         -- 12 : 依頼No／移動No
    ) ;
--
END xxwsh930004c ;
/
