CREATE OR REPLACE PACKAGE XXCOS011A03C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2009. All rights reserved.
 *
 * Package Name     : XXCOS011A03C (spec)
 * Description      : 納品予定データの作成を行う
 * MD.050           : 納品予定データ作成 (MD050_COS_011_A03)
 * Version          : 1.7
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
 *  2009/01/08    1.0   H.Fujimoto       新規作成
 *  2009/02/20    1.1   H.Fujimoto       結合不具合No.106
 *  2009/02/24    1.2   H.Fujimoto       結合不具合No.126,134
 *  2009/02/25    1.3   H.Fujimoto       結合不具合No.135
 *  2009/02/25    1.4   H.Fujimoto       結合不具合No.141
 *  2009/02/27    1.5   H.Fujimoto       結合不具合No.146,149
 *  2009/03/04    1.6   H.Fujimoto       結合不具合No.154
 *  2009/04/28    1.7   K.Kiriu          [T1_0756]レコード長変更対応
 *
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf              OUT    VARCHAR2,         --   エラーメッセージ #固定#
    retcode             OUT    VARCHAR2,         --   エラーコード     #固定#
    iv_file_name        IN     VARCHAR2,         --   1.ファイル名
    iv_make_class       IN     VARCHAR2,         --   2.作成区分
    iv_edi_c_code       IN     VARCHAR2,         --   3.EDIチェーン店コード
    iv_edi_f_number     IN     VARCHAR2,         --   4.EDI伝送追番
    iv_shop_date_from   IN     VARCHAR2,         --   5.店舗納品日From
    iv_shop_date_to     IN     VARCHAR2,         --   6.店舗納品日To
    iv_sale_class       IN     VARCHAR2,         --   7.定番特売区分
    iv_area_code        IN     VARCHAR2,         --   8.地区コード
    iv_center_date      IN     VARCHAR2,         --   9.センター納品日
    iv_delivery_time    IN     VARCHAR2,         --  10.納品時刻
    iv_delivery_charge  IN     VARCHAR2,         --  11.納品担当者
    iv_carrier_means    IN     VARCHAR2,         --  12.輸送手段
    iv_proc_date        IN     VARCHAR2,         --  13.処理日
    iv_proc_time        IN     VARCHAR2          --  14.処理時刻
  );
END XXCOS011A03C;
/
