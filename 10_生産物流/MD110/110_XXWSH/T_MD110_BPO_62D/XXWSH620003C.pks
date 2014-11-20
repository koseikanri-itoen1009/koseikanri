CREATE OR REPLACE PACKAGE xxwsh620003c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxwsh620003c(spec)
 * Description      : 入庫依頼表
 * MD.050           : 引当/配車(帳票) T_MD050_BPO_620
 * MD.070           : 入庫依頼表 T_MD070_BPO_62D
 * Version          : 1.9
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
 *  2008/03/13    1.0   Nozomi Kashiwagi 新規作成
 *  2008/06/04    1.1   Jun Nakada       確定処理未実施(通知日時=NULL)の場合の出力制御
 *  2008/06/23    1.2   Yoshikatu Shindou 配送区分情報VIEWのリレーションを外部結合に変更
 *                                         (システムテスト不具合#228)
 *  2008/07/02    1.3   Satoshi Yunba    禁則文字対応
 *  2008/07/10    1.4   Akiyoshi Shiina  変更要求対応#92
 *  2008/07/11    1.5   Masayoshi Uehara ST不具合#441対応
 *  2008/07/15    1.6   Akiyoshi Shiina  変更要求対応#92修正
 *  2008/08/04    1.7   Takao Ohashi     結合出荷テスト(出荷追加_19)修正
 *  2008/10/06    1.8   Yuko Kawano      統合指摘#242修正(出庫日FROMを任意に変更)
 *                                       T_S_501(ソート順の変更)
 *  2008/10/20    1.9   Yuko Kawano      課題#32,変更#168対応
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
     errbuf                    OUT    VARCHAR2         --   エラーメッセージ
    ,retcode                   OUT    VARCHAR2         --   エラーコード
    ,iv_dept                   IN     VARCHAR2         --   01 : 部署
    ,iv_plan_decide_kbn        IN     VARCHAR2         --   02 : 予定/確定区分
    ,iv_ship_from              IN     VARCHAR2         --   03 : 出庫日From
    ,iv_ship_to                IN     VARCHAR2         --   04 : 出庫日To
    ,iv_notif_date             IN     VARCHAR2         --   05 : 確定通知実施日
    ,iv_notif_time_from        IN     VARCHAR2         --   06 : 確定通知実施時間From
    ,iv_notif_time_to          IN     VARCHAR2         --   07 : 確定通知実施時間To
    ,iv_block1                 IN     VARCHAR2         --   08 : ブロック1
    ,iv_block2                 IN     VARCHAR2         --   09 : ブロック2
    ,iv_block3                 IN     VARCHAR2         --   10 : ブロック3
    ,iv_ship_to_locat_code     IN     VARCHAR2         --   11 : 入庫先
    ,iv_shipped_locat_code     IN     VARCHAR2         --   12 : 出庫元
    ,iv_freight_carrier_code   IN     VARCHAR2         --   13 : 運送業者
    ,iv_delivery_no            IN     VARCHAR2         --   14 : 配送No
    ,iv_mov_num                IN     VARCHAR2         --   15 : 移動No
    ,iv_online_kbn             IN     VARCHAR2         --   16 : オンライン対象区分
    ,iv_item_kbn               IN     VARCHAR2         --   17 : 品目区分
    ,iv_arrival_date_from      IN     VARCHAR2         --   18 : 着日From
    ,iv_arrival_date_to        IN     VARCHAR2         --   19 : 着日To
  );
END xxwsh620003c;
/
