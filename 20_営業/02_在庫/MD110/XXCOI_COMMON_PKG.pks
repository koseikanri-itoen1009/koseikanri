CREATE OR REPLACE PACKAGE XXCOI_COMMON_PKG
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOI_COMMON_PKG(spec)
 * Description      : 共通関数パッケージ(在庫)
 * MD.070           : 共通関数    MD070_IPO_COI
 * Version          : 1.5
 *
 * Program List
 * ------------------------- ------------------------------------------------------------
 *  Name                      Description
 * ------------------------- -------------------------------------------------------
 *  ORG_ACCT_PERIOD_CHK        在庫会計期間チェック
 *  GET_ORGANIZATION_ID        在庫組織ID取得
 *  GET_BELONGING_BASE         所属拠点コード取得1
 *  GET_BASE_CODE              所属拠点コード取得2
 *  GET_BELONGING_BASE2        所属拠点コード取得3
 *  GET_MEANING                LOOKUP情報取得
 *  GET_CMPNT_COST             標準原価取得
 *  GET_DISCRETE_COST          営業原価取得
 *  GET_TRANSACTION_TYPE_ID    取引タイプID取得
 *  GET_ITEM_INFO              品目情報取得1
 *  GET_ITEM_CODE              品目情報取得2
 *  GET_UOM_DISABLE_INFO       単位無効日情報取得
 *  GET_SUBINVENTORY_INFO1     保管場所情報取得1
 *  GET_SUBINVENTORY_INFO2     保管場所情報取得2
 *  GET_MANAGE_DEPT_F          管理課判別フラグ取得
 *  GET_LOOKUP_VALUES          クイックコードマスタ情報取得
 *  CONVERT_WHOUSE_SUBINV_CODE HHT保管場所コード変換 倉庫保管場所コード変換
 *  CONVERT_EMP_SUBINV_CODE    HHT保管場所コード変換 営業車保管場所コード変換
 *  CONVERT_CUST_SUBINV_CODE   HHT保管場所コード変換 預け先保管場所コード変換
 *  CONVERT_BASE_SUBINV_CODE   HHT保管場所コード変換 メイン倉庫保管場所コード変換
 *  CHECK_CUST_STATUS          HHT保管場所コード変換 顧客ステータスチェック
 *  CONVERT_SUBINV_CODE        HHT保管場所コード変換
 *  GET_DISPOSITION_ID         勘定科目別名ID取得
 *  ADD_HHT_ERR_LIST_DATA      HHT情報取込エラー出力
 *  GET_DISPOSITION_ID_2       勘定科目別名ID取得2
 *  GET_ITEM_INFO2             品目情報取得(品目ID、単位コード)
 *  GET_BASE_AFF_ACTIVE_DATE   拠点AFF部門適用開始日取得
 *  GET_SUBINV_AFF_ACTIVE_DATE 保管場所AFF部門適用開始日取得
 *  CHK_AFF_ACTIVE             AFF部門チェック
 *  CRE_LOT_TRX_TEMP           ロット別取引TEMP作成
 *  DEL_LOT_TRX_TEMP           ロット別取引TEMP削除
 *  CRE_LOT_TRX                ロット別取引明細作成
 *  GET_CUSTOMER_ID            顧客導出（受注アドオン）
 *  GET_PARENT_CHILD_ITEM_INFO 品目コード導出（親／子）
 *  INS_UPD_LOT_HOLD_INFO      ロット情報保持マスタ反映
 *  INS_UPD_DEL_LOT_ONHAND     ロット別手持数量反映
 *  GET_FRESH_CONDITION_DATE   鮮度条件基準日算出
 *  GET_RESERVED_QUANTITY      引当可能数算出
 *  GET_FRESH_CONDITION_DATE_F 鮮度条件基準日算出(ファンクション型)
 * 
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/10/23    1.0   T.Nishikawa      新規作成
 *  2009/03/24    1.1   S.Kayahara       最終行に/追加
 *  2010/03/23    1.2   Y.Goto           [E_本稼動_01943]AFF部門適用開始日取得を追加
 *  2010/03/29    1.3   Y.Goto           [E_本稼動_01943]AFF部門チェックを追加
 *  2011/11/01    1.4   T.Yoshimoto      [E_本稼動_07570]所属拠点コード取得3を追加
 *  2014/10/28    1.5   Y.Nagasue        [E_本稼動_12237]倉庫管理システム対応 以下の関数を新規作成
 *                                        ロット別取引TEMP作成、ロット別取引TEMP削除、ロット別取引明細、
 *                                        顧客導出（受注アドオン）、品目コード導出（親／子）、
 *                                        ロット情報保持マスタ反映、ロット別手持数量反映、
 *                                        鮮度条件基準日算出、引当可能数算出、鮮度条件基準日算出(ファンクション型)
 *
 *****************************************************************************************/
--
-- == 2014/10/28 Ver1.5 Y.Nagasue ADD START ======================================================
  --==============================================
  -- レコードタイプ
  --==============================================
  TYPE item_info_rtype IS RECORD
  (item_id            mtl_system_items_b.inventory_item_id%TYPE -- 品目ID
  ,item_no            ic_item_mst_b.item_no%TYPE            -- 品目コード
  ,item_short_name    xxcmn_item_mst_b.item_short_name%TYPE -- 略称
  ,item_kbn           mtl_categories_vl.segment1%TYPE       -- 商品区分
  ,item_kbn_name      mtl_categories_vl.description%TYPE    -- 商品区分名
  );
  --==============================================
  -- テーブルタイプ
  --==============================================
  TYPE item_info_ttype IS TABLE OF item_info_rtype INDEX BY BINARY_INTEGER;
-- == 2014/10/28 Ver1.5 Y.Nagasue ADD END ======================================================
--
/************************************************************************
 * Function Name   : ORG_ACCT_PERIOD_CHK
 * Description     : 対象日に対応する在庫会計期間がオープンしているかを
 *                   チェックする。
 ************************************************************************/
  PROCEDURE org_acct_period_chk(
    in_organization_id IN  NUMBER             -- 在庫組織ID
   ,id_target_date     IN  DATE               -- 対象日
   ,ob_chk_result      OUT BOOLEAN            -- チェック結果
   ,ov_errbuf          OUT VARCHAR2           -- エラーメッセージ
   ,ov_retcode         OUT VARCHAR2           -- リターン・コード(0:正常、2:エラー)
   ,ov_errmsg          OUT VARCHAR2           -- ユーザー・エラーメッセージ
  );
/************************************************************************
 * Function Name   : GET_ORGANIZATION_ID
 * Description     : 販売物流領域の在庫組織IDを取得する。
 ************************************************************************/
  FUNCTION get_organization_id(
    iv_organization_code IN VARCHAR2
  ) RETURN NUMBER;
/************************************************************************
 * Procedure Name  : GET_BELONGING_BASE
 * Description     : ログインユーザーに紐付く所属拠点コードを取得する。
 ************************************************************************/
  PROCEDURE get_belonging_base(
    in_user_id        IN  NUMBER              -- ユーザーID
   ,id_target_date    IN  DATE                -- 対象日
   ,ov_base_code      OUT VARCHAR2            -- 拠点コード
   ,ov_errbuf         OUT VARCHAR2            -- エラーメッセージ
   ,ov_retcode        OUT VARCHAR2            -- リターン・コード(0:正常、2:エラー)
   ,ov_errmsg         OUT VARCHAR2            -- ユーザー・エラーメッセージ
  );
/************************************************************************
 * Function Name   : GET_BASE_CODE
 * Description     : 所属拠点コード取得のファンクション機能。
 ************************************************************************/
  FUNCTION get_base_code(
    in_user_id        IN  NUMBER              -- ユーザーID
   ,id_target_date    IN  DATE                -- 対象日
  ) RETURN VARCHAR2;
/************************************************************************
 * Function Name   : GET_MEANING
 * Description     : クイックコードの参照タイプ・参照コードの内容を取得する。
 ************************************************************************/
  FUNCTION get_meaning(
    iv_lookup_type    IN  VARCHAR2            -- 参照タイプ
   ,iv_lookup_code    IN  VARCHAR2            -- 参照コード
  ) RETURN VARCHAR2;
/************************************************************************
 * Procedure Name  : GET_CMPNT_COST
 * Description     : 品目IDを元に標準原価を取得します。
 ************************************************************************/
  PROCEDURE get_cmpnt_cost(
    in_item_id        IN  NUMBER              -- 品目ID
   ,in_org_id         IN  NUMBER              -- 組織ID
   ,id_period_date    IN  DATE                -- 対象日
   ,ov_cmpnt_cost     OUT VARCHAR2            -- 標準原価
   ,ov_errbuf         OUT VARCHAR2            -- エラーメッセージ
   ,ov_retcode        OUT VARCHAR2            -- リターン・コード(0:正常、2:エラー)
   ,ov_errmsg         OUT VARCHAR2            -- ユーザー・エラーメッセージ
  );
/************************************************************************
 * Procedure Name  : GET_DISCRETE_COST
 * Description     : 品目IDを元に確定済みの営業原価を取得します。
 ************************************************************************/
  PROCEDURE get_discrete_cost(
    in_item_id        IN  NUMBER              -- 品目ID
   ,in_org_id         IN  NUMBER              -- 組織ID
   ,id_target_date    IN  DATE                -- 対象日
   ,ov_discrete_cost  OUT VARCHAR2            -- 営業原価
   ,ov_errbuf         OUT VARCHAR2            -- エラーメッセージ
   ,ov_retcode        OUT VARCHAR2            -- リターン・コード(0:正常、2:エラー)
   ,ov_errmsg         OUT VARCHAR2            -- ユーザー・エラーメッセージ
  );
/************************************************************************
 * Function Name   : GET_TRANSACTION_TYPE_ID
 * Description     : 取引タイプ名をもとに、取引タイプIDを取得
 ************************************************************************/
  FUNCTION  get_transaction_type_id(
    iv_transaction_type_name IN VARCHAR2     -- 取引タイプ名
  ) RETURN NUMBER;
/************************************************************************
 * Function Name   : GET_ITEM_CODE
 * Description     : 品目IDをもとに品目コードを取得する。
 ************************************************************************/
  FUNCTION get_item_code(
    in_item_id    IN NUMBER
   ,in_org_id     IN NUMBER
  ) RETURN VARCHAR2;
--
/************************************************************************
 * Procedure Name  : get_item_info
 * Description     : 品目チェックに使用する品目付加情報を取得します。
 ************************************************************************/
  PROCEDURE get_item_info(
    ov_errbuf               OUT VARCHAR2   -- 1.エラーメッセージ
   ,ov_retcode              OUT VARCHAR2   -- 2.リターン・コード
   ,ov_errmsg               OUT VARCHAR2   -- 3.ユーザー・エラーメッセージ
   ,iv_item_code            IN  VARCHAR2   -- 4.品目コード
   ,in_org_id               IN  NUMBER     -- 5.在庫組織ID
   ,ov_item_status          OUT VARCHAR2   -- 6.品目ステータス
   ,ov_cust_order_flg       OUT VARCHAR2   -- 7.顧客受注可能フラグ
   ,ov_transaction_enable   OUT VARCHAR2   -- 8.取引可能
   ,ov_stock_enabled_flg    OUT VARCHAR2   -- 9.在庫保有可能フラグ
   ,ov_return_enable        OUT VARCHAR2   -- 10.返品可能
   ,ov_sales_class          OUT VARCHAR2   -- 11.売上対象区分
   ,ov_primary_unit         OUT VARCHAR2   -- 12.基準単位
  );
/************************************************************************
 * Procedure Name  : get_item_info2
 * Description     : 品目チェックに使用する品目付加情報を取得します。
 ************************************************************************/
  PROCEDURE get_item_info2(
    ov_errbuf               OUT VARCHAR2   -- 1.エラーメッセージ
   ,ov_retcode              OUT VARCHAR2   -- 2.リターン・コード
   ,ov_errmsg               OUT VARCHAR2   -- 3.ユーザー・エラーメッセージ
   ,iv_item_code            IN  VARCHAR2   -- 4.品目コード
   ,in_org_id               IN  NUMBER     -- 5.在庫組織ID
   ,ov_item_status          OUT VARCHAR2   -- 6.品目ステータス
   ,ov_cust_order_flg       OUT VARCHAR2   -- 7.顧客受注可能フラグ
   ,ov_transaction_enable   OUT VARCHAR2   -- 8.取引可能
   ,ov_stock_enabled_flg    OUT VARCHAR2   -- 9.在庫保有可能フラグ
   ,ov_return_enable        OUT VARCHAR2   -- 10.返品可能
   ,ov_sales_class          OUT VARCHAR2   -- 11.売上対象区分
   ,ov_primary_unit         OUT VARCHAR2   -- 12.基準単位
   ,on_inventory_item_id    OUT NUMBER     -- 13.品目ID
   ,ov_primary_uom_code     OUT VARCHAR2   -- 14.基準単位コード
  );
--
/************************************************************************
 * Procedure Name  : get_uom_disable_info
 * Description     : 単位マスタより単位の無効日を取得します。
 ************************************************************************/
  PROCEDURE get_uom_disable_info(
    ov_errbuf         OUT VARCHAR2   -- 1.エラーメッセージ
   ,ov_retcode        OUT VARCHAR2   -- 2.リターン・コード
   ,ov_errmsg         OUT VARCHAR2   -- 3.ユーザー・エラーメッセージ
   ,iv_unit_code      IN  VARCHAR2   -- 4.単位コード
   ,od_disable_date   OUT DATE       -- 5.無効日
  );
--
/************************************************************************
 * Procedure Name  : get_subinventory_info1
 * Description     : 保管場所マスタより、拠点コード・倉庫コードを基に
 *                   保管場所コードと無効日を取得します。
 ************************************************************************/
  PROCEDURE get_subinventory_info1(
    ov_errbuf         OUT VARCHAR2   -- 1.エラーメッセージ
   ,ov_retcode        OUT VARCHAR2   -- 2.リターン・コード
   ,ov_errmsg         OUT VARCHAR2   -- 3.ユーザー・エラーメッセージ
   ,iv_base_code      IN  VARCHAR2   -- 4.拠点コード
   ,iv_whse_code      IN  VARCHAR2   -- 5.倉庫コード
   ,ov_sec_inv_nm     OUT VARCHAR2   -- 6.保管場所コード
   ,od_disable_date   OUT DATE       -- 7.無効日
  );
--
/************************************************************************
 * Procedure Name  : get_subinventory_info2
 * Description     : 保管場所マスタより、拠点コード・店舗コードを基に
 *                   保管場所コードと無効日を取得します。
 ************************************************************************/
  PROCEDURE get_subinventory_info2(
    ov_errbuf         OUT VARCHAR2   -- 1.エラーメッセージ
   ,ov_retcode        OUT VARCHAR2   -- 2.リターン・コード
   ,ov_errmsg         OUT VARCHAR2   -- 3.ユーザー・エラーメッセージ
   ,iv_base_code      IN  VARCHAR2   -- 4.拠点コード
   ,iv_shop_code      IN  VARCHAR2   -- 5.店舗コード
   ,ov_sec_inv_nm     OUT VARCHAR2   -- 6.保管場所コード
   ,od_disable_date   OUT DATE       -- 7.無効日
  );
--
/************************************************************************
 * Function Name   : GET_MANAGE_DEPT_F
 * Description     : 自拠点が管理課か単独拠点なのかを判別するフラグを取得する。
 *                   戻り値：0（単独拠点）、1（管理課）
 ************************************************************************/
  FUNCTION get_manage_dept_f(
    iv_base_code   IN   VARCHAR2   -- 1.拠点コード
  ) RETURN NUMBER;   -- 管理課判別フラグ
--
/************************************************************************
 * Function Name   : get_lookup_values
 * Description     : クイックコードマスタの各項目値をレコード型で取得する。
 ************************************************************************/
  TYPE lookup_rec IS RECORD(
     meaning      fnd_lookup_values.meaning%TYPE
    ,description  fnd_lookup_values.description%TYPE
    ,attribute1   fnd_lookup_values.attribute1%TYPE
    ,attribute2   fnd_lookup_values.attribute2%TYPE
    ,attribute3   fnd_lookup_values.attribute3%TYPE
    ,attribute4   fnd_lookup_values.attribute4%TYPE
    ,attribute5   fnd_lookup_values.attribute5%TYPE
    ,attribute6   fnd_lookup_values.attribute6%TYPE
    ,attribute7   fnd_lookup_values.attribute7%TYPE
    ,attribute8   fnd_lookup_values.attribute8%TYPE
    ,attribute9   fnd_lookup_values.attribute9%TYPE
    ,attribute10  fnd_lookup_values.attribute10%TYPE
    ,attribute11  fnd_lookup_values.attribute11%TYPE
    ,attribute12  fnd_lookup_values.attribute12%TYPE
    ,attribute13  fnd_lookup_values.attribute13%TYPE
    ,attribute14  fnd_lookup_values.attribute14%TYPE
    ,attribute15  fnd_lookup_values.attribute15%TYPE
  );
  --
  FUNCTION get_lookup_values(
    iv_lookup_type    IN  VARCHAR2
   ,iv_lookup_code    IN  VARCHAR2
   ,id_enabled_date   IN  DATE  DEFAULT SYSDATE
  ) RETURN lookup_rec;
/************************************************************************
 * Procedure Name  : CONVERT_WHOUSE_SUBINV_CODE
 * Description     : HHT保管場所コード変換 倉庫保管場所コード変換
 ************************************************************************/
  PROCEDURE convert_whouse_subinv_code(
    ov_errbuf                       OUT NOCOPY VARCHAR2   -- 1.エラーメッセージ
   ,ov_retcode                      OUT NOCOPY VARCHAR2   -- 2.リターン・コード(1:正常、2:エラー)
   ,ov_errmsg                       OUT NOCOPY VARCHAR2   -- 3.ユーザー・エラーメッセージ
   ,iv_base_code                    IN         VARCHAR2   -- 4.拠点コード
   ,iv_warehouse_code               IN         VARCHAR2   -- 5.倉庫コード
   ,in_organization_id              IN         NUMBER     -- 6.在庫組織ID
   ,ov_subinv_code                  OUT NOCOPY VARCHAR2   -- 7.保管場所コード
   ,ov_base_code                    OUT NOCOPY VARCHAR2   -- 8.拠点コード
   ,ov_subinv_div                   OUT NOCOPY VARCHAR2   -- 9.保管場所区分
  );
/************************************************************************
 * Procedure Name  : CONVERT_EMP_SUBINV_CODE
 * Description     : HHT保管場所コード変換 営業車保管場所コード変換
 ************************************************************************/
  PROCEDURE convert_emp_subinv_code(
    ov_errbuf                       OUT NOCOPY VARCHAR2   -- 1.エラーメッセージ
   ,ov_retcode                      OUT NOCOPY VARCHAR2   -- 2.リターン・コード(1:正常、2:エラー)
   ,ov_errmsg                       OUT NOCOPY VARCHAR2   -- 3.ユーザー・エラーメッセージ
   ,iv_base_code                    IN         VARCHAR2   -- 4.拠点コード
   ,iv_employee_number              IN         VARCHAR2   -- 5.従業員コード
   ,id_transaction_date             IN         DATE       -- 6.伝票日付
   ,in_organization_id              IN         NUMBER     -- 7.在庫組織ID
   ,ov_subinv_code                  OUT NOCOPY VARCHAR2   -- 8.保管場所コード
   ,ov_base_code                    OUT NOCOPY VARCHAR2   -- 9.拠点コード
   ,ov_subinv_div                   OUT NOCOPY VARCHAR2   -- 10.保管場所区分
  );
/************************************************************************
 * Procedure Name  : CONVERT_CUST_SUBINV_CODE
 * Description     : HHT保管場所コード変換 預け先保管場所コード変換
 ************************************************************************/
  PROCEDURE convert_cust_subinv_code(
    ov_errbuf                       OUT NOCOPY VARCHAR2   -- 1.エラーメッセージ
   ,ov_retcode                      OUT NOCOPY VARCHAR2   -- 2.リターン・コード(1:正常、2:エラー)
   ,ov_errmsg                       OUT NOCOPY VARCHAR2   -- 3.ユーザー・エラーメッセージ
   ,iv_base_code                    IN         VARCHAR2   -- 4.拠点コード
   ,iv_cust_code                    IN         VARCHAR2   -- 5.顧客コード
   ,id_transaction_date             IN         DATE       -- 6.伝票日付
   ,in_organization_id              IN         NUMBER     -- 7.在庫組織ID
   ,iv_record_type                  IN         VARCHAR2   -- 8.レコード種別
   ,iv_hht_form_flag                IN         VARCHAR2   -- 9.HHT取引入力画面フラグ
   ,ov_subinv_code                  OUT NOCOPY VARCHAR2   --10.保管場所コード
   ,ov_base_code                    OUT NOCOPY VARCHAR2   --11.拠点コード
   ,ov_subinv_div                   OUT NOCOPY VARCHAR2   --12.保管場所区区分
   ,ov_business_low_type            OUT NOCOPY VARCHAR2   --13.業態小分類
  );
/************************************************************************
 * Procedure Name  : CONVERT_BASE_SUBINV_CODE
 * Description     : HHT保管場所コード変換 メイン倉庫保管場所コード変換
 ************************************************************************/
   PROCEDURE convert_base_subinv_code(
    ov_errbuf                       OUT NOCOPY VARCHAR2   -- 1.エラーメッセージ
   ,ov_retcode                      OUT NOCOPY VARCHAR2   -- 2.リターン・コード(1:正常、2:エラー)
   ,ov_errmsg                       OUT NOCOPY VARCHAR2   -- 3.ユーザー・エラーメッセージ
   ,iv_dept_code                    IN         VARCHAR2   -- 4.拠点コード
   ,in_organization_id              IN         NUMBER     -- 5.在庫組織ID
   ,ov_subinv_code                  OUT NOCOPY VARCHAR2   -- 6.保管場所コード
   ,ov_base_code                    OUT NOCOPY VARCHAR2   -- 7.拠点コード
   ,ov_subinv_div                   OUT NOCOPY VARCHAR2   -- 8.保管場所変換区分
  );
/************************************************************************
 * Procedure Name  : CHECK_CUST_STATUS
 * Description     : HHT保管場所コード変換 顧客ステータスチェック
 ************************************************************************/
  PROCEDURE check_cust_status(
    ov_errbuf                       OUT NOCOPY VARCHAR2   -- 1.エラーメッセージ
   ,ov_retcode                      OUT NOCOPY VARCHAR2   -- 2.リターン・コード(1:正常、2:エラー)
   ,ov_errmsg                       OUT NOCOPY VARCHAR2   -- 3.ユーザー・エラーメッセージ
   ,iv_cust_code                    IN         VARCHAR2   -- 4.顧客コード
  );
/************************************************************************
 * Procedure Name  : CONVERT_SUBINV_CODE
 * Description     : HHT保管場所コード変換
 ************************************************************************/
  PROCEDURE convert_subinv_code(
    ov_errbuf                       OUT NOCOPY VARCHAR2   -- 1.エラーメッセージ
   ,ov_retcode                      OUT NOCOPY VARCHAR2   -- 2.リターン・コード(1:正常、2:エラー)
   ,ov_errmsg                       OUT NOCOPY VARCHAR2   -- 3.ユーザー・エラーメッセージ
   ,iv_record_type                  IN         VARCHAR2   -- 4.レコード種別
   ,iv_invoice_type                 IN         VARCHAR2   -- 5.伝票区分
   ,iv_department_flag              IN         VARCHAR2   -- 6.百貨店フラグ
   ,iv_base_code                    IN         VARCHAR2   -- 7.拠点コード
   ,iv_outside_code                 IN         VARCHAR2   -- 8.出庫側コード
   ,iv_inside_code                  IN         VARCHAR2   -- 9.入庫側コード
   ,id_transaction_date             IN         DATE       -- 10.取引日
   ,in_organization_id              IN         NUMBER     -- 11.在庫組織ID
   ,iv_hht_form_flag                IN         VARCHAR2   -- 12.HHT取引入力画面フラグ
   ,ov_outside_subinv_code          OUT NOCOPY VARCHAR2   -- 13.出庫側保管場所コード
   ,ov_inside_subinv_code           OUT NOCOPY VARCHAR2   -- 14.入庫側保管場所コード
   ,ov_outside_base_code            OUT NOCOPY VARCHAR2   -- 15.出庫側拠点コード
   ,ov_inside_base_code             OUT NOCOPY VARCHAR2   -- 16.入庫側拠点コード
   ,ov_outside_subinv_code_conv     OUT NOCOPY VARCHAR2   -- 17.出庫側保管場所変換区分
   ,ov_inside_subinv_code_conv      OUT NOCOPY VARCHAR2   -- 18.入庫側保管場所変換区分
   ,ov_outside_business_low_type    OUT NOCOPY VARCHAR2   -- 19.出庫側業態小分類
   ,ov_inside_business_low_type     OUT NOCOPY VARCHAR2   -- 20.入庫側業態小分類
   ,ov_outside_cust_code            OUT NOCOPY VARCHAR2   -- 21.出庫側顧客コード
   ,ov_inside_cust_code             OUT NOCOPY VARCHAR2   -- 22.入庫側顧客コード
   ,ov_hht_program_div              OUT NOCOPY VARCHAR2   -- 23.入出庫ジャーナル処理区分
   ,ov_item_convert_div             OUT NOCOPY VARCHAR2   -- 24.商品振替区分
   ,ov_stock_uncheck_list_div       OUT NOCOPY VARCHAR2   -- 25.入庫未確認リスト対象区分
   ,ov_stock_balance_list_div       OUT NOCOPY VARCHAR2   -- 26.入庫差異確認リスト対象区分
   ,ov_consume_vd_flag              OUT NOCOPY VARCHAR2   -- 27.消化VD補充対象フラグ
   ,ov_outside_subinv_div           OUT NOCOPY VARCHAR2   -- 28.出庫側保管場所区分
   ,ov_inside_subinv_div            OUT NOCOPY VARCHAR2   -- 29.入庫側保管場所区分
  );
--
/************************************************************************
 * Function Name   : GET_DISPOSITION_ID
 * Description     : 勘定科目別名取引を作成する際に必要となる
 *                   勘定科目別名IDを取得します。有効日判定あり。
 ************************************************************************/
  FUNCTION get_disposition_id(
    iv_inv_account_kbn        IN VARCHAR2   -- 1.入出庫勘定区分
   ,iv_dept_code              IN VARCHAR2   -- 2.部門コード
   ,in_organization_id        IN NUMBER     -- 3.在庫組織ID
  ) RETURN NUMBER;                          -- 勘定科目別名ID
--
/************************************************************************
 * Procedure Name  : ADD_HHT_ERR_LIST_DATA
 * Description     : HHTデータ(入出庫・棚卸)取込の際にエラーとなった
 *                   レコードをもとに、HHTエラーリスト帳票に必要な
 *                   データをHHTエラーリスト帳票ワークテーブルに追加します。
 ************************************************************************/
  PROCEDURE add_hht_err_list_data(
    ov_errbuf                 OUT VARCHAR2   -- 1.エラー・メッセージ
   ,ov_retcode                OUT VARCHAR2   -- 2.リターン・コード
   ,ov_errmsg                 OUT VARCHAR2   -- 3.ユーザー・エラー・メッセージ
   ,iv_base_code              IN  VARCHAR2   -- 4.拠点コード
   ,iv_origin_shipment        IN  VARCHAR2   -- 5.出庫側コード
   ,iv_data_name              IN  VARCHAR2   -- 6.データ名称
   ,id_transaction_date       IN  DATE       -- 7.取引日
   ,iv_entry_number           IN  VARCHAR2   -- 8.伝票NO
   ,iv_party_num              IN  VARCHAR2   -- 9.入庫側コード
   ,iv_performance_by_code    IN  VARCHAR2   -- 10.営業員コード
   ,iv_item_code              IN  VARCHAR2   -- 11.品目コード
   ,iv_error_message          IN  VARCHAR2   -- 12.エラー内容
  );
--
/************************************************************************
 * Function Name   : GET_DISPOSITION_ID_2
 * Description     : 勘定科目別名取引を作成する際に必要となる
 *                   勘定科目別名IDを取得します。有効日判定なし。
 ************************************************************************/
  FUNCTION get_disposition_id_2(
    iv_inv_account_kbn        IN VARCHAR2   -- 1.入出庫勘定区分
   ,iv_dept_code              IN VARCHAR2   -- 2.部門コード
   ,in_organization_id        IN NUMBER     -- 3.在庫組織ID
  ) RETURN NUMBER;                          -- 勘定科目別名ID
--
-- == 2010/03/23 V1.2 Added START ===============================================================
/************************************************************************
 * Function Name   : GET_BASE_AFF_ACTIVE_DATE
 * Description     : 拠点コードからAFF部門の適用開始日を取得する。
 ************************************************************************/
  PROCEDURE get_base_aff_active_date(
    iv_base_code             IN  VARCHAR2   -- 拠点コード
   ,od_start_date_active     OUT DATE       -- 適用開始日
   ,ov_errbuf                OUT VARCHAR2   -- エラーメッセージ
   ,ov_retcode               OUT VARCHAR2   -- リターン・コード(0:正常、2:エラー)
   ,ov_errmsg                OUT VARCHAR2   -- ユーザー・エラーメッセージ
  );
--
/************************************************************************
 * Function Name   : GET_SUBINV_AFF_ACTIVE_DATE
 * Description     : 保管場所コードからAFF部門の適用開始日を取得する。
 ************************************************************************/
  PROCEDURE get_subinv_aff_active_date(
    in_organization_id       IN  NUMBER     -- 在庫組織ID
   ,iv_subinv_code           IN  VARCHAR2   -- 保管場所コード
   ,od_start_date_active     OUT DATE       -- 適用開始日
   ,ov_errbuf                OUT VARCHAR2   -- エラーメッセージ
   ,ov_retcode               OUT VARCHAR2   -- リターン・コード(0:正常、2:エラー)
   ,ov_errmsg                OUT VARCHAR2   -- ユーザー・エラーメッセージ
  );
--
-- == 2010/03/23 V1.2 Added END   ===============================================================
-- == 2010/03/29 V1.3 Added START ===============================================================
/************************************************************************
 * Function Name   : CHK_AFF_ACTIVE
 * Description     : AFF部門の使用可能チェックを行います。
 ************************************************************************/
  FUNCTION chk_aff_active(
    in_organization_id       IN  NUMBER     -- 在庫組織ID
   ,iv_base_code             IN  VARCHAR2   -- 拠点コード
   ,iv_subinv_code           IN  VARCHAR2   -- 保管場所コード
   ,id_target_date           IN  DATE       -- 対象日
  ) RETURN VARCHAR2;                        -- チェック結果
--
-- == 2010/03/29 V1.3 Added END   ===============================================================
-- 2011/11/01 v1.4 T.Yoshimoto Add Start E_本稼動_07570
/************************************************************************
 * Procedure Name  : GET_BELONGING_BASE2
 * Description     : 営業員に紐付く所属拠点コードを取得する。
 ************************************************************************/
  PROCEDURE get_belonging_base2(
    in_employee_code  IN  VARCHAR2        -- 営業員コード
   ,id_target_date    IN  DATE            -- 対象日
   ,ov_base_code      OUT VARCHAR2        -- 拠点コード
   ,ov_errbuf         OUT VARCHAR2        -- エラーメッセージ
   ,ov_retcode        OUT VARCHAR2        -- リターン・コード(0:正常、2:エラー)
   ,ov_errmsg         OUT VARCHAR2        -- ユーザー・エラーメッセージ
  );
-- 2011/11/01 v1.4 T.Yoshimoto Add End
-- == 2014/10/28 Ver1.5 Y.Nagasue ADD START ======================================================
/************************************************************************
 * Procedure Name  : CRE_LOT_TRX_TEMP
 * Description     : ロット別取引TEMP作成
 ************************************************************************/
  PROCEDURE cre_lot_trx_temp(
    in_trx_set_id       IN  NUMBER   -- 取引セットID
   ,iv_parent_item_code IN  VARCHAR2 -- 親品目コード
   ,iv_child_item_code  IN  VARCHAR2 -- 子品目コード
   ,iv_lot              IN  VARCHAR2 -- ロット(賞味期限)
   ,iv_diff_sum_code    IN  VARCHAR2 -- 固有記号
   ,iv_trx_type_code    IN  VARCHAR2 -- 取引タイプコード
   ,id_trx_date         IN  DATE     -- 取引日
   ,iv_slip_num         IN  VARCHAR2 -- 伝票No
   ,in_case_in_qty      IN  NUMBER   -- 入数
   ,in_case_qty         IN  NUMBER   -- ケース数
   ,in_singly_qty       IN  NUMBER   -- バラ数
   ,in_summary_qty      IN  NUMBER   -- 取引数量
   ,iv_base_code        IN  VARCHAR2 -- 拠点コード
   ,iv_subinv_code      IN  VARCHAR2 -- 保管場所コード
   ,iv_tran_subinv_code IN  VARCHAR2 -- 転送先保管場所コード
   ,iv_tran_loc_code    IN  VARCHAR2 -- 転送先ロケーションコード
   ,iv_inout_code       IN  VARCHAR2 -- 入出庫コード
   ,iv_source_code      IN  VARCHAR2 -- ソースコード
   ,iv_relation_key     IN  VARCHAR2 -- 紐付けキー
   ,on_trx_id           OUT NUMBER   -- ロット別TEMP取引ID
   ,ov_errbuf           OUT VARCHAR2 -- エラーメッセージ
   ,ov_retcode          OUT VARCHAR2 -- リターン・コード(0:正常、2:エラー)
   ,ov_errmsg           OUT VARCHAR2 -- ユーザー・エラーメッセージ
  );
--
/************************************************************************
 * Procedure Name  : DEL_LOT_TRX_TEMP
 * Description     : ロット別取引TEMP削除
 ************************************************************************/
  PROCEDURE del_lot_trx_temp(
    in_trx_id  IN  NUMBER          -- ロット別TEMP取引ID
   ,ov_errbuf  OUT VARCHAR2        -- エラーメッセージ
   ,ov_retcode OUT VARCHAR2        -- リターン・コード(0:正常、2:エラー)
   ,ov_errmsg  OUT VARCHAR2        -- ユーザー・エラーメッセージ
  );
--
/************************************************************************
 * Procedure Name  : CRE_LOT_TRX
 * Description     : ロット別取引明細作成
 ************************************************************************/
  PROCEDURE cre_lot_trx(
    in_trx_set_id            IN  NUMBER   -- 取引セットID
   ,iv_parent_item_code      IN  VARCHAR2 -- 親品目コード
   ,iv_child_item_code       IN  VARCHAR2 -- 子品目コード
   ,iv_lot                   IN  VARCHAR2 -- ロット(賞味期限)
   ,iv_diff_sum_code         IN  VARCHAR2 -- 固有記号
   ,iv_trx_type_code         IN  VARCHAR2 -- 取引タイプコード
   ,id_trx_date              IN  DATE     -- 取引日
   ,iv_slip_num              IN  VARCHAR2 -- 伝票No
   ,in_case_in_qty           IN  NUMBER   -- 入数
   ,in_case_qty              IN  NUMBER   -- ケース数
   ,in_singly_qty            IN  NUMBER   -- バラ数
   ,in_summary_qty           IN  NUMBER   -- 取引数量
   ,iv_base_code             IN  VARCHAR2 -- 拠点コード
   ,iv_subinv_code           IN  VARCHAR2 -- 保管場所コード
   ,iv_loc_code              IN  VARCHAR2 -- ロケーションコード
   ,iv_tran_subinv_code      IN  VARCHAR2 -- 転送先保管場所コード
   ,iv_tran_loc_code         IN  VARCHAR2 -- 転送先ロケーションコード
   ,iv_source_code           IN  VARCHAR2 -- ソースコード
   ,iv_relation_key          IN  VARCHAR2 -- 紐付けキー
   ,iv_reason                IN  VARCHAR2 -- 事由
   ,iv_reserve_trx_type_code IN  VARCHAR2 -- 引当時取引タイプコード
   ,on_trx_id                OUT NUMBER   -- ロット別取引明細
   ,ov_errbuf                OUT VARCHAR2 -- エラーメッセージ
   ,ov_retcode               OUT VARCHAR2 -- リターン・コード(0:正常、2:エラー)
   ,ov_errmsg                OUT VARCHAR2 -- ユーザー・エラーメッセージ
  );
--
/************************************************************************
 * Function Name   : GET_CUSTOMER_ID
 * Description     : 顧客導出（受注アドオン）
 ************************************************************************/
--
  FUNCTION get_customer_id(
    in_deliver_to_id IN NUMBER -- 出荷先ID
  ) RETURN NUMBER 
  ;
--
/************************************************************************
 * Procedure Name  : GET_PARENT_CHILD_ITEM_INFO
 * Description     : 品目コード導出（親／子）
 ************************************************************************/
--
  PROCEDURE get_parent_child_item_info(
    id_date             IN  DATE            -- 日付
   ,in_inv_org_id       IN  NUMBER          -- 在庫組織ID
   ,in_parent_item_id   IN  NUMBER          -- 親品目ID
   ,in_child_item_id    IN  NUMBER          -- 子品目ID
   ,ot_item_info_tab    OUT item_info_ttype -- 品目情報（テーブル型）
   ,ov_errbuf           OUT VARCHAR2        -- エラーメッセージ
   ,ov_retcode          OUT VARCHAR2        -- リターン・コード(0:正常、2:エラー)
   ,ov_errmsg           OUT VARCHAR2        -- ユーザー・エラーメッセージ
  );
--
/************************************************************************
 * Procedure Name  : INS_UPD_LOT_HOLD_INFO
 * Description     : ロット情報保持マスタ反映
 ************************************************************************/
--
  PROCEDURE ins_upd_lot_hold_info(
    in_customer_id    IN  NUMBER   -- 顧客ID
   ,in_deliver_to_id  IN  NUMBER   -- 出荷先ID
   ,in_parent_item_id IN  NUMBER   -- 親品目ID
   ,iv_deliver_lot    IN  VARCHAR2 -- 納品ロット
   ,id_delivery_date  IN  DATE     -- 納品日
   ,iv_e_s_kbn        IN  VARCHAR2 -- 営業生産区分
   ,iv_cancel_kbn     IN  VARCHAR2 -- 取消区分
   ,ov_errbuf         OUT VARCHAR2 -- エラーメッセージ
   ,ov_retcode        OUT VARCHAR2 -- リターン・コード(0:正常、2:エラー)
   ,ov_errmsg         OUT VARCHAR2 -- ユーザー・エラーメッセージ
  );
--
/************************************************************************
 * Function Name   : INS_UPD_DEL_LOT_ONHAND
 * Description     : ロット別手持数量反映
 ************************************************************************/
--
  PROCEDURE ins_upd_del_lot_onhand(
    in_inv_org_id       IN  NUMBER   -- 在庫組織ID
   ,iv_base_code        IN  VARCHAR2 -- 拠点コード
   ,iv_subinv_code      IN  VARCHAR2 -- 保管場所コード
   ,iv_loc_code         IN  VARCHAR2 -- ロケーションコード
   ,in_child_item_id    IN  NUMBER   -- 子品目ID
   ,iv_lot              IN  VARCHAR2 -- ロット(賞味期限)
   ,iv_diff_sum_code    IN  VARCHAR2 -- 固有記号
   ,in_case_in_qty      IN  NUMBER   -- 入数
   ,in_case_qty         IN  NUMBER   -- ケース数
   ,in_singly_qty       IN  NUMBER   -- バラ数
   ,in_summary_qty      IN  NUMBER   -- 取引数量
   ,ov_errbuf           OUT VARCHAR2 -- エラーメッセージ
   ,ov_retcode          OUT VARCHAR2 -- リターン・コード(0:正常、2:エラー)
   ,ov_errmsg           OUT VARCHAR2 -- ユーザー・エラーメッセージ
  );
--
/************************************************************************
 * Procedure Name  : GET_FRESH_CONDITION_DATE
 * Description     : 鮮度条件基準日算出
 ************************************************************************/
--
  PROCEDURE get_fresh_condition_date(
    id_use_by_date           IN  DATE     -- 賞味期限
   ,id_product_date          IN  DATE     -- 製造年月日
   ,iv_fresh_condition       IN  VARCHAR2 -- 鮮度条件
   ,od_fresh_condition_date  OUT DATE     -- 鮮度条件基準日
   ,ov_errbuf                OUT VARCHAR2 -- エラーメッセージ
   ,ov_retcode               OUT VARCHAR2 -- リターン・コード(0:正常、2:エラー)
   ,ov_errmsg                OUT VARCHAR2 -- ユーザー・エラーメッセージ
  );
--
/************************************************************************
 * Procedure Name  : GET_RESERVED_QUANTITY
 * Description     : 引当可能数算出
 ************************************************************************/
--
  PROCEDURE get_reserved_quantity(
    in_inv_org_id       IN  NUMBER   -- 在庫組織ID
   ,iv_base_code        IN  VARCHAR2 -- 拠点コード
   ,iv_subinv_code      IN  VARCHAR2 -- 保管場所コード
   ,iv_loc_code         IN  VARCHAR2 -- ロケーションコード
   ,in_child_item_id    IN  NUMBER   -- 子品目ID
   ,iv_lot              IN  VARCHAR2 -- ロット(賞味期限)
   ,iv_diff_sum_code    IN  VARCHAR2 -- 固有記号
   ,on_case_in_qty      OUT NUMBER   -- 入数
   ,on_case_qty         OUT NUMBER   -- ケース数
   ,on_singly_qty       OUT NUMBER   -- バラ数
   ,on_summary_qty      OUT NUMBER   -- 取引数量
   ,ov_errbuf           OUT VARCHAR2 -- エラーメッセージ
   ,ov_retcode          OUT VARCHAR2 -- リターン・コード(0:正常、2:エラー)
   ,ov_errmsg           OUT VARCHAR2 -- ユーザー・エラーメッセージ
  );
--
/************************************************************************
 * Function Name   : GET_FRESH_CONDITION_DATE_F
 * Description     : 鮮度条件基準日算出(ファンクション型)
 ************************************************************************/
--
  FUNCTION get_fresh_condition_date_f(
    id_use_by_date     IN  DATE     -- 賞味期限
   ,id_product_date    IN  DATE     -- 製造年月日
   ,iv_fresh_condition IN  VARCHAR2 -- 鮮度条件
  ) RETURN DATE
  ;
--
-- == 2014/10/28 Ver1.5 Y.Nagasue ADD END ======================================================
END XXCOI_COMMON_PKG;
/
