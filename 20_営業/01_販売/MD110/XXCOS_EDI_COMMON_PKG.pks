CREATE OR REPLACE PACKAGE xxcos_edi_common_pkg
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name           : xxcos_edi_common_pkg(spec)
 * Description            :
 * MD.070                 : MD070_IPO_COS_共通関数
 * Version                : 1.8
 *
 * Program List
 *  ----------------------------- ---- ----- -----------------------------------------
 *   Name                         Type  Ret   Description
 *  ----------------------------- ---- ----- -----------------------------------------
 *  edi_manual_order_acquisition  P          EDI受注手入力分取込
 *
 * Change Record
 * ------------ ----- ---------------- -----------------------------------------------
 *  Date         Ver.  Editor           Description
 * ------------ ----- ---------------- -----------------------------------------------
 *  2008/11/26   1.0   H.Fujimoto       新規作成
 *  2009/03/03   1.1   H.Fujimoto       結合不具合No152
 *  2009/03/24   1.2   T.Miyata         ST障害：T1_0126
 *  2009/04/24   1.3   K.Kiriu          ST障害：T1_0112
 *  2009/06/19   1.4   N.Maeda          [T1_1358]対応
 *  2009/07/13   1.5   K.Kiriu          [0000660]対応
 *  2009/07/14   1.6   K.Kiriu          [0000064]対応
 *  2009/08/11   1.7   K.Kiriu          [0000966]対応
 *  2010/07/12   1.8   S.Niki           [E_本稼動_02637]対応
 *****************************************************************************************/
 --
  -- EDI受注手入力分取込
  PROCEDURE edi_manual_order_acquisition(
               iv_edi_chain_code           IN VARCHAR2  DEFAULT NULL  -- EDIチェーン店コード
              ,iv_edi_forward_number       IN VARCHAR2  DEFAULT NULL  -- EDI伝送追番
              ,id_shop_delivery_date_from  IN DATE      DEFAULT NULL  -- 店舗納品日(From)
              ,id_shop_delivery_date_to    IN DATE      DEFAULT NULL  -- 店舗納品日(To)
              ,iv_regular_ar_sale_class    IN VARCHAR2  DEFAULT NULL  -- 定番特売区分
              ,iv_area_code                IN VARCHAR2  DEFAULT NULL  -- 地区コード
              ,id_center_delivery_date     IN DATE      DEFAULT NULL  -- センター納品日
              ,in_organization_id          IN NUMBER    DEFAULT NULL  -- 在庫組織ID
/* 2010/07/12 Ver1.8 Add Start */
              ,iv_boot_flag                IN VARCHAR2  DEFAULT NULL  -- 起動種別(1：コンカレント、2：画面)
              ,ov_err_flag                 OUT NOCOPY VARCHAR2        -- エラー種別
/* 2010/07/12 Ver1.8 Add End */
              ,ov_errbuf                   OUT NOCOPY VARCHAR2        -- エラー・メッセージ           --# 固定 #
              ,ov_retcode                  OUT NOCOPY VARCHAR2        -- リターン・コード             --# 固定 #
              ,ov_errmsg                   OUT NOCOPY VARCHAR2        -- ユーザー・エラー・メッセージ --# 固定 #
            );
 --
END xxcos_edi_common_pkg;
/
