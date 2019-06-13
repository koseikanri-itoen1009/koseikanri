CREATE OR REPLACE PACKAGE XXCOS_COMMON_PKG
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOS_COMMON_PKG(spec)
 * Description      : 共通関数パッケージ(販売)
 * MD.070           : 共通関数    MD070_IPO_COS
 * Version          : 1.4
 *
 * Program List
 * --------------------------- ------ ---------- -----------------------------------------
 *  Name                        Type   Return     Description
 * --------------------------- ------ ---------- -----------------------------------------
 *  get_key_info                P                 キー情報編集
 *  get_uom_cnv                 P                 単位換算取得
 *  get_delivered_from          P                 納品形態取得
 *  get_sales_calendar_code     P                 販売用カレンダーコード取得
 *  check_sales_operation_day   F      NUMBER     販売用稼働日チェック
 *  get_period_year             P                 当年度会計期間取得
 *  get_account_period          P                 会計期間情報取得
 *  get_specific_master         F      VARCHAR2   特定マスタ取得(クイックコード)
 *  get_tax_rate_info           P                 品目別消費税率取得関数
 *  
 * Change Record
 * ------------- ----- ---------------- --------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- --------------------------------------------------
 *  2008/11/21    1.0   SCS              新規作成
 *  2009/04/30    1.1   T.Kitajima       [T1_0710]get_delivered_from 出荷拠点コード取得方法変更
 *  2009/05/14    1.2   N.Maeda          [T1_0997]納品形態区分の導出方法修正
 *  2009/08/03    1.3   N.Maeda          [0000433]get_account_period,get_specific_masterの
 *                                                参照タイプコード取得時の不要なテーブル結合の削除
 *  2019/06/04    1.4   S.Kuwako         [E_本稼動_15472]軽減税率用の消費税率取得関数の追加
 *
 ****************************************************************************************/
--
  /************************************************************************
   * Procedure Name  : makeup_key_info
   * Description     : キー情報編集
   ************************************************************************/
  PROCEDURE makeup_key_info(
    iv_item_name1             IN            VARCHAR2  DEFAULT NULL,         -- 項目名称１
    iv_item_name2             IN            VARCHAR2  DEFAULT NULL,         -- 項目名称２
    iv_item_name3             IN            VARCHAR2  DEFAULT NULL,         -- 項目名称３
    iv_item_name4             IN            VARCHAR2  DEFAULT NULL,         -- 項目名称４
    iv_item_name5             IN            VARCHAR2  DEFAULT NULL,         -- 項目名称５
    iv_item_name6             IN            VARCHAR2  DEFAULT NULL,         -- 項目名称６
    iv_item_name7             IN            VARCHAR2  DEFAULT NULL,         -- 項目名称７
    iv_item_name8             IN            VARCHAR2  DEFAULT NULL,         -- 項目名称８
    iv_item_name9             IN            VARCHAR2  DEFAULT NULL,         -- 項目名称９
    iv_item_name10            IN            VARCHAR2  DEFAULT NULL,         -- 項目名称１０
    iv_item_name11            IN            VARCHAR2  DEFAULT NULL,         -- 項目名称１１
    iv_item_name12            IN            VARCHAR2  DEFAULT NULL,         -- 項目名称１２
    iv_item_name13            IN            VARCHAR2  DEFAULT NULL,         -- 項目名称１３
    iv_item_name14            IN            VARCHAR2  DEFAULT NULL,         -- 項目名称１４
    iv_item_name15            IN            VARCHAR2  DEFAULT NULL,         -- 項目名称１５
    iv_item_name16            IN            VARCHAR2  DEFAULT NULL,         -- 項目名称１６
    iv_item_name17            IN            VARCHAR2  DEFAULT NULL,         -- 項目名称１７
    iv_item_name18            IN            VARCHAR2  DEFAULT NULL,         -- 項目名称１８
    iv_item_name19            IN            VARCHAR2  DEFAULT NULL,         -- 項目名称１９
    iv_item_name20            IN            VARCHAR2  DEFAULT NULL,         -- 項目名称２０
    iv_data_value1            IN            VARCHAR2  DEFAULT NULL,         -- データの値１
    iv_data_value2            IN            VARCHAR2  DEFAULT NULL,         -- データの値２
    iv_data_value3            IN            VARCHAR2  DEFAULT NULL,         -- データの値３
    iv_data_value4            IN            VARCHAR2  DEFAULT NULL,         -- データの値４
    iv_data_value5            IN            VARCHAR2  DEFAULT NULL,         -- データの値５
    iv_data_value6            IN            VARCHAR2  DEFAULT NULL,         -- データの値６
    iv_data_value7            IN            VARCHAR2  DEFAULT NULL,         -- データの値７
    iv_data_value8            IN            VARCHAR2  DEFAULT NULL,         -- データの値８
    iv_data_value9            IN            VARCHAR2  DEFAULT NULL,         -- データの値９
    iv_data_value10           IN            VARCHAR2  DEFAULT NULL,         -- データの値１０
    iv_data_value11           IN            VARCHAR2  DEFAULT NULL,         -- データの値１１
    iv_data_value12           IN            VARCHAR2  DEFAULT NULL,         -- データの値１２
    iv_data_value13           IN            VARCHAR2  DEFAULT NULL,         -- データの値１３
    iv_data_value14           IN            VARCHAR2  DEFAULT NULL,         -- データの値１４
    iv_data_value15           IN            VARCHAR2  DEFAULT NULL,         -- データの値１５
    iv_data_value16           IN            VARCHAR2  DEFAULT NULL,         -- データの値１６
    iv_data_value17           IN            VARCHAR2  DEFAULT NULL,         -- データの値１７
    iv_data_value18           IN            VARCHAR2  DEFAULT NULL,         -- データの値１８
    iv_data_value19           IN            VARCHAR2  DEFAULT NULL,         -- データの値１９
    iv_data_value20           IN            VARCHAR2  DEFAULT NULL,         -- データの値２０
    ov_key_info               OUT    NOCOPY VARCHAR2,                       -- キー情報
    ov_errbuf                 OUT    NOCOPY VARCHAR2,                       -- エラー・メッセージエラー       #固定#
    ov_retcode                OUT    NOCOPY VARCHAR2,                       -- リターン・コード               #固定#
    ov_errmsg                 OUT    NOCOPY VARCHAR2                        -- ユーザー・エラー・メッセージ   #固定#
  );
--
  /************************************************************************
   * Procedure Name  : get_uom_cnv
   * Description     : 単位換算取得
   ************************************************************************/
  PROCEDURE get_uom_cnv(
    iv_before_uom_code        IN            VARCHAR2,                       -- 換算前単位コード
    in_before_quantity        IN            NUMBER,                         -- 換算前数量
    iov_item_code             IN OUT NOCOPY VARCHAR2,                       -- 品目コード
    iov_organization_code     IN OUT NOCOPY VARCHAR2,                       -- 在庫組織コード
    ion_inventory_item_id     IN OUT        NUMBER,                         -- 品目ＩＤ
    ion_organization_id       IN OUT        NUMBER,                         -- 在庫組織ＩＤ
    iov_after_uom_code        IN OUT NOCOPY VARCHAR2,                       -- 換算後単位コード
    on_after_quantity         OUT    NOCOPY NUMBER,                         -- 換算後数量
    on_content                OUT    NOCOPY NUMBER,                         -- 入数
    ov_errbuf                 OUT    NOCOPY VARCHAR2,                       -- エラー・メッセージエラー       #固定#
    ov_retcode                OUT    NOCOPY VARCHAR2,                       -- リターン・コード               #固定#
    ov_errmsg                 OUT    NOCOPY VARCHAR2                        -- ユーザー・エラー・メッセージ   #固定#
  );
--
  /************************************************************************
   * Procedure Name  : get_delivered_from
   * Description     : 納品形態取得
   ************************************************************************/
  PROCEDURE get_delivered_from(
    iv_subinventory_code      IN            VARCHAR2,                       -- 保管場所コード
    iv_sales_base_code        IN            VARCHAR2,                       -- 売上拠点コード,
    iv_ship_base_code         IN            VARCHAR2,                       -- 出荷拠点コード,
    iov_organization_code     IN OUT NOCOPY VARCHAR2,                       -- 在庫組織コード
    ion_organization_id       IN OUT        NUMBER,                         -- 在庫組織ＩＤ
    ov_delivered_from         OUT    NOCOPY VARCHAR2,                       -- 納品形態
    ov_errbuf                 OUT    NOCOPY VARCHAR2,                       -- エラー・メッセージエラー       #固定#
    ov_retcode                OUT    NOCOPY VARCHAR2,                       -- リターン・コード               #固定#
    ov_errmsg                 OUT    NOCOPY VARCHAR2                        -- ユーザー・エラー・メッセージ   #固定#
  );
--
  /************************************************************************
   * Procedure Name  : get_sales_calendar_code
   * Description     : 販売用カレンダコード取得
   ************************************************************************/
  PROCEDURE get_sales_calendar_code(
    iov_organization_code     IN OUT NOCOPY VARCHAR2,                       -- 在庫組織コード
    ion_organization_id       IN OUT        NUMBER,                         -- 在庫組織ＩＤ
    ov_calendar_code          OUT    NOCOPY VARCHAR2,                       -- カレンダコード
    ov_errbuf                 OUT    NOCOPY VARCHAR2,                       -- エラー・メッセージエラー       #固定#
    ov_retcode                OUT    NOCOPY VARCHAR2,                       -- リターン・コード               #固定#
    ov_errmsg                 OUT    NOCOPY VARCHAR2                        -- ユーザー・エラー・メッセージ   #固定#
  );
--
  /************************************************************************
   * Function Name   : check_sales_oprtn_day
   * Description     : 販売用稼働日チェック
   ************************************************************************/
  FUNCTION check_sales_oprtn_day(
    id_check_target_date      IN            DATE,                           -- チェック対象日付
    iv_calendar_code          IN            VARCHAR2                        -- カレンダコード
  ) RETURN  NUMBER;
--
  /************************************************************************
   * Procedure Name  : get_period_year
   * Description     : 当年度会計期間取得
   ************************************************************************/
  PROCEDURE get_period_year(
    id_base_date              IN            DATE,                           --   基準日
    od_start_date             OUT    NOCOPY DATE,                           --   当年度会計開始日
    od_end_date               OUT    NOCOPY DATE,                           --   当年度会計終了日
    ov_errbuf                 OUT    NOCOPY VARCHAR2,                       -- エラー・メッセージエラー       #固定#
    ov_retcode                OUT    NOCOPY VARCHAR2,                       -- リターン・コード               #固定#
    ov_errmsg                 OUT    NOCOPY VARCHAR2                        -- ユーザー・エラー・メッセージ   #固定#
  );
--
  /************************************************************************
   * Procedure Name  : get_account_period
   * Description     : 会計期間情報取得
   ************************************************************************/
  PROCEDURE get_account_period(
    iv_account_period         IN            VARCHAR2,                       -- 会計区分
    id_base_date              IN            DATE,                           -- 基準日
    ov_status                 OUT    NOCOPY VARCHAR2,                       -- ステータス
    od_start_date             OUT    NOCOPY DATE,                           -- 会計(FROM)
    od_end_date               OUT    NOCOPY DATE,                           -- 会計(TO)
    ov_errbuf                 OUT    NOCOPY VARCHAR2,                       -- エラー・メッセージエラー       #固定#
    ov_retcode                OUT    NOCOPY VARCHAR2,                       -- リターン・コード               #固定#
    ov_errmsg                 OUT    NOCOPY VARCHAR2                        -- ユーザー・エラー・メッセージ   #固定#
  );
--
  /************************************************************************
   * Function Name   : get_specific_master
   * Description     : 特定マスタ取得(クイックコード)
   ************************************************************************/
  FUNCTION get_specific_master(
    it_lookup_type            IN            fnd_lookup_types.lookup_type%TYPE, -- ルックアップタイプ
    it_lookup_code            IN            fnd_lookup_values.lookup_code%TYPE -- ルックアップコード
  ) RETURN  VARCHAR2;
--
  /************************************************************************
   * Procedure Name  : get_tax_rate_info
   * Description     : 品目別消費税率取得関数
   ************************************************************************/
  PROCEDURE get_tax_rate_info(
    iv_item_code                   IN         VARCHAR2,                      -- 品目コード
    id_base_date                   IN         DATE,                          -- 基準日
    ov_class_for_variable_tax      OUT NOCOPY VARCHAR2,                      -- 軽減税率用税種別
    ov_tax_name                    OUT NOCOPY VARCHAR2,                      -- 税率キー名称
    ov_tax_description             OUT NOCOPY VARCHAR2,                      -- 摘要
    ov_tax_histories_code          OUT NOCOPY VARCHAR2,                      -- 消費税履歴コード
    ov_tax_histories_description   OUT NOCOPY VARCHAR2,                      -- 消費税履歴名称
    od_start_date                  OUT NOCOPY DATE,                          -- 税率キー_開始日
    od_end_date                    OUT NOCOPY DATE,                          -- 税率キー_終了日
    od_start_date_histories        OUT NOCOPY DATE,                          -- 消費税履歴_開始日
    od_end_date_histories          OUT NOCOPY DATE,                          -- 消費税履歴_終了日
    on_tax_rate                    OUT NOCOPY NUMBER,                        -- 税率
    ov_tax_class_suppliers_outside OUT NOCOPY VARCHAR2,                      -- 税区分_仕入外税
    ov_tax_class_suppliers_inside  OUT NOCOPY VARCHAR2,                      -- 税区分_仕入内税
    ov_tax_class_sales_outside     OUT NOCOPY VARCHAR2,                      -- 税区分_売上外税
    ov_tax_class_sales_inside      OUT NOCOPY VARCHAR2,                      -- 税区分_売上内税
    ov_errbuf                      OUT NOCOPY VARCHAR2,                      -- エラー・メッセージエラー       #固定#
    ov_retcode                     OUT NOCOPY VARCHAR2,                      -- リターン・コード               #固定#
    ov_errmsg                      OUT NOCOPY VARCHAR2                       -- ユーザー・エラー・メッセージ   #固定#
  );
--
END XXCOS_COMMON_PKG;
/
