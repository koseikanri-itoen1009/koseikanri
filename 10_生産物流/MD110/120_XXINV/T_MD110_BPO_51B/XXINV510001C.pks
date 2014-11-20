CREATE OR REPLACE PACKAGE xxinv510001c 
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : XXINV510001C(spec)
 * Description      : 移動伝票
 * MD.050/070       : 移動実績 T_MD050_BPO_510
 *                  : 移動伝票 T_MD070_BPO_51A
 * Version          : 1.8
 *
 * Program List
 * ---------------------------- ----------------------------------------------------
 *  Name                        Description
 * ---------------------------- ----------------------------------------------------
 *  convert_into_xml            データ変換処理ファンクション
 *  output_xml                  XMLデータ出力処理プロシージャ
 *  prc_create_zeroken_xml_data 取得件数０件時ＸＭＬデータ作成
 *  create_xml_head             XMLデータ作成処理プロシージャ(ヘッダ部)
 *  create_xml_line             XMLデータ作成処理プロシージャ(明細部)
 *  create_xml_sum              XMLデータ作成処理プロシージャ(合計部)
 *  create_xml                  XMLデータ作成処理プロシージャ
 *  submain                     メイン処理プロシージャ
 *  main                        コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ------------------ -------------------------------------------------
 *  Date          Ver.  Editor             Description
 * ------------- ----- ------------------ -------------------------------------------------
 *  2008/03/05    1.0   Yuki Komikado      初回作成
 *  2008/05/26    1.1   Kazuo Kumamoto     結合テスト障害対応
 *  2008/05/28    1.2   Yuko Kawano        結合テスト障害対応
 *  2008/05/29    1.3   Yuko Kawano        結合テスト障害対応
 *  2008/06/24    1.4   Yasuhisa Yamamoto  変更要求対応#92
 *  2008/07/18    1.5   Yasuhisa Yamamoto  内部変更要求対応
 *  2008/07/29    1.6   Marushita          禁則文字「'」「"」「<」「>」「＆」対応
 *  2008/07/30    1.7   Yuko Kawano        内部変更要求対応#164
 *  2008/11/04    1.8   Yasuhisa Yamamoto  統合障害#508,554
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
  PROCEDURE main (
    errbuf                OUT    VARCHAR2,         -- エラーメッセージ
    retcode               OUT    VARCHAR2,         -- エラーコード
    iv_product_class      IN     VARCHAR2,         -- 01.製品識別区分
    iv_prod_class_code    IN     VARCHAR2,         -- 02.商品区分
    iv_target_class       IN     VARCHAR2,         -- 03.指示/実績区分
    iv_move_no            IN     VARCHAR2,         -- 04.移動番号
    iv_move_instr_post_cd IN     VARCHAR2,         -- 05.移動指示部署
    iv_ship               IN     VARCHAR2,         -- 06.出庫元
    iv_arrival            IN     VARCHAR2,         -- 07.入庫先
    iv_ship_date_from     IN     VARCHAR2,         -- 08.出庫日FROM
    iv_ship_date_to       IN     VARCHAR2,         -- 09.出庫日TO
    iv_delivery_no        IN     VARCHAR2);        -- 10.配送No.
END xxinv510001c;
/
