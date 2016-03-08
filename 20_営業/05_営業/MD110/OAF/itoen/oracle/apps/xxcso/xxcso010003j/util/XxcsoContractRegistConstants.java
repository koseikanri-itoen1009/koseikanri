/*============================================================================
* ファイル名 : XxcsoContractRegistConstants
* 概要説明   : 自販機設置契約情報登録共通固定値クラス
* バージョン : 2.2
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2009-01-27 1.0  SCS小川浩    新規作成
* 2009-02-16 1.1  SCS柳平直人  [CT1-008]BM指定チェックボックス不正対応
*                                       BM支払区分の追加
* 2009-04-08 1.2  SCS柳平直人  [ST障害T1_0364]仕入先重複チェック修正対応
* 2009-04-27 1.3  SCS柳平直人  [ST障害T1_0708]文字列チェック処理統一修正
* 2010-02-09 1.4  SCS阿部大輔  [E_本稼動_01538]契約書の複数確定対応
* 2010-03-01 1.5  SCS阿部大輔  [E_本稼動_01678]現金支払対応
* 2010-03-01 1.5  SCS阿部大輔  [E_本稼動_01868]物件対応
* 2010-01-06 1.6  SCS桐生和幸  [E_本稼動_02498]銀行支店マスタチェック対応
* 2011-06-06 1.7  SCS桐生和幸  [E_本稼動_01963]新規仕入先作成チェック対応
* 2012-06-12 1.8  SCSK桐生和幸 [E_本稼動_09602]契約取消ボタン追加対応
* 2013-04-01 1.9  SCSK桐生和幸 [E_本稼動_10413]銀行口座マスタ変更チェック追加対応
* 2015-02-06 2.0  SCSK山下翔太 [E_本稼動_12565]SP専決・契約書画面改修
* 2015-11-30 2.1  SCSK山下翔太 [E_本稼動_13345]オーナ変更マスタ連携エラー対応
* 2016-01-06 2.2  SCSK桐生和幸 [E_本稼動_13456]自販機管理システム代替対応
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso010003j.util;

/*******************************************************************************
 * 自販機設置契約情報登録共通固定値クラス。
 * @author  SCS柳平直人
 * @version 1.1
 *******************************************************************************
 */
public class XxcsoContractRegistConstants
{

  /*****************************************************************************
   * センタリングオブジェクト
   *****************************************************************************
   */
  public static final String[] CENTERING_OBJECTS =
  {
    "InputUserLayout"
   ,"CloseDayLayout"
   ,"TransferDayLayout"
   ,"ContractPeriodLayout"
   ,"CancellationOfferLayout"
   ,"Bm1BankTransferFeeDivLayout"
   ,"Bm1BellingDetailsDivLayout"
   ,"Bm1InqueryBaseLayout"
   ,"Bm1BankNameLayout"
   ,"Bm1BranchNameLayout"
   ,"Bm1BankAccountTypeLayout"
   ,"Bm2BankTransferFeeDivLayout"
   ,"Bm2BellingDetailsDivLayout"
   ,"Bm2InqueryBaseLayout"
   ,"Bm2BankNameLayout"
   ,"Bm2BranchNameLayout"
   ,"Bm2BankAccountTypeLayout"
   ,"Bm3BankTransferFeeDivLayout"
   ,"Bm3BellingDetailsDivLayout"
   ,"Bm3InqueryBaseLayout"
   ,"Bm3BankNameLayout"
   ,"Bm3BranchNameLayout"
   ,"Bm3BankAccountTypeLayout"
// 2015-02-06 [E_本稼動_12565] Add Start
   ,"InstSuppBankTransferFeeDivLayout"
   ,"InstSuppBankNameLayout"
   ,"InstSuppBranchNameLayout"
   ,"InstSuppBankAccountTypeLayout"
   ,"IntroChgBankTransferFeeDivLayout"
   ,"IntroChgBankNameLayout"
   ,"IntroChgBranchNameLayout"
   ,"IntroChgBankAccountTypeLayout"
   ,"ElectricBankTransferFeeDivLayout"
   ,"ElectricBankNameLayout"
   ,"ElectricBranchNameLayout"
   ,"ElectricBankAccountTypeLayout"
// 2015-02-06 [E_本稼動_12565] Add End
   ,"OwnerChangeLayout"
   ,"PublishBaseLayout"
   ,"InstallCodeLayout"
   ,"BaseLeaderLayout"
  };


  /*****************************************************************************
   * 必須オブジェクト
   *****************************************************************************
   */
  public static final String[] REQUIRED_OBJECTS =
  {
    "CloseDayLayout"
   ,"TransferDayLayout"
   ,"CancellationOfferLayout"
// 2010-03-01 [E_本稼動_01678] Add Start
//   ,"Bm1BankTransferFeeDivLayout"
// 2010-03-01 [E_本稼動_01678] Add End
   ,"Bm1BellingDetailsDivLayout"
   ,"Bm1InqueryBaseLayout"
// 2010-03-01 [E_本稼動_01678] Add Start
//   ,"Bm1BankNameLayout"
//   ,"Bm1BankAccountTypeLayout"
//   ,"Bm2BankTransferFeeDivLayout"
// 2010-03-01 [E_本稼動_01678] Add End
   ,"Bm2BellingDetailsDivLayout"
   ,"Bm2InqueryBaseLayout"
// 2010-03-01 [E_本稼動_01678] Add Start
//   ,"Bm2BankNameLayout"
//   ,"Bm2BankAccountTypeLayout"
//   ,"Bm3BankTransferFeeDivLayout"
// 2010-03-01 [E_本稼動_01678] Add End
   ,"Bm3BellingDetailsDivLayout"
   ,"Bm3InqueryBaseLayout"
// 2010-03-01 [E_本稼動_01678] Add Start
//   ,"Bm3BankNameLayout"
//   ,"Bm3BankAccountTypeLayout"
// 2010-03-01 [E_本稼動_01678] Add End
   ,"PublishBaseLayout"
   ,"InstallCodeLayout"
  };

  /*****************************************************************************
   * 処理区分
   *****************************************************************************
   */
  public static final String MODE_UPDATE          = "1";
  public static final String MODE_COPY            = "2";

  /*****************************************************************************
   * 契約書区分
   *****************************************************************************
   */
  public static final String FORMAT_STD           = "0";
  public static final String FORMAT_OTHER         = "1";

  /*****************************************************************************
   * ステータス
   *****************************************************************************
   */
  public static final String STS_INPUT            = "0";
  public static final String STS_FIX              = "1";
// 2012-06-12 [E_本稼動_09602] Add Start
  public static final String STS_REJECT           = "9";
// 2012-06-12 [E_本稼動_09602] Add End

  /*****************************************************************************
   * 振込日
   *****************************************************************************
   */
  public static final String TRANSFER_DAY_20      = "20";

  /*****************************************************************************
   * 振込月
   *****************************************************************************
   */
  public static final String LAST_DAY             = "30";
  public static final String NEXT_MONTH           = "50";

  /*****************************************************************************
   * 支払明細書タイプ
   *****************************************************************************
   */
  public static final String TRANCE_EXIST          = "1";
  public static final String TRANCE_NON_EXIST      = "2";

  /*****************************************************************************
   * マスタ連携フラグ
   *****************************************************************************
   */
  public static final String COOPERATE_NONE       = "0";

  /*****************************************************************************
   * バッチ処理ステータス
   *****************************************************************************
   */
  public static final String BATCH_PROC_NORMAL    = "0";

  /*****************************************************************************
   * BMチェック
   *****************************************************************************
   */
  public static final String DELIV_BM1            = "1";
  public static final String DELIV_BM2            = "2";
  public static final String DELIV_BM3            = "3";

  /*****************************************************************************
   * ポップリスト初期設定情報
   *****************************************************************************
   */
  public static final String INIT_FORMAT          = FORMAT_STD;
  public static final String INIT_STS             = STS_INPUT;
  public static final String INIT_TRANSFER_MONTH  = NEXT_MONTH;
  public static final String INIT_TRANSFER_DAY    = "20";
  public static final String INIT_CLOSE_DAY       = LAST_DAY;
  public static final String INIT_CANCELLATION    = "1";

  /*****************************************************************************
   * BM指定チェックフラグ
   *****************************************************************************
   */
  public static final String BM_EXIST_FLAG_ON     = "Y";
  public static final String BM_EXIST_FLAG_OFF    = "N";

// 2015-02-06 [E_本稼動_12565] Add Start
  /*****************************************************************************
   * 設置協賛金指定チェックフラグ
   *****************************************************************************
   */
  public static final String INST_SUPP_EXIST_FLAG_ON     = "Y";
  public static final String INST_SUPP_EXIST_FLAG_OFF    = "N";

  /*****************************************************************************
   * 紹介手数料指定チェックフラグ
   *****************************************************************************
   */
  public static final String INTRO_CHG_EXIST_FLAG_ON     = "Y";
  public static final String INTRO_CHG_EXIST_FLAG_OFF    = "N";

  /*****************************************************************************
   * 電気代指定チェックフラグ
   *****************************************************************************
   */
  public static final String ELECTRIC_EXIST_FLAG_ON     = "Y";
  public static final String ELECTRIC_EXIST_FLAG_OFF    = "N";
// 2015-02-06 [E_本稼動_12565] Add End

  /*****************************************************************************
   * オーナー変更チェックフラグ
   *****************************************************************************
   */
  public static final String OWNER_CHANGE_FLAG_ON     = "Y";
  public static final String OWNER_CHANGE_FLAG_OFF    = "N";

  /*****************************************************************************
   * 画面セキュリティ判定フラグ
   *****************************************************************************
   */
  public static final String AUTH_NONE                = "0";
  public static final String AUTH_ACCOUNT             = "1";
  public static final String AUTH_BASE_LEADER         = "2";

  /*****************************************************************************
   * マップパラメータ
   *****************************************************************************
   */
  public static final String PARAM_URL_PARAM          = "URL_PARAM";
  public static final String PARAM_MESSAGE            = "MESSAGE";

  /*****************************************************************************
   * BM支払区分
   *****************************************************************************
   */
// 2010-03-01 [E_本稼動_01678] Add Start
  public static final String BM_PAYMENT_TYPE4         = "4";
// 2010-03-01 [E_本稼動_01678] Add End
  public static final String BM_PAYMENT_TYPE5         = "5";

// 2015-02-06 [E_本稼動_12565] Add Start
  /*****************************************************************************
   * 支払区分（設置協賛金）
   *****************************************************************************
   */
  public static final String INST_SUPP_TYPE0         = "0";
  public static final String INST_SUPP_TYPE1         = "1";

/*****************************************************************************
   * 支払区分（紹介手数料）
   *****************************************************************************
   */
  public static final String INTRO_CHG_TYPE0         = "0";
  public static final String INTRO_CHG_TYPE1         = "1";

/*****************************************************************************
   * 支払条件（電気代）
   *****************************************************************************
   */
  public static final String ELECTRIC_PAYMENT_TYPE1  = "1";
  public static final String ELECTRIC_PAYMENT_TYPE2  = "2";
// 2015-02-06 [E_本稼動_12565] Add End

// 2009-04-08 [ST障害T1_0364] Add Start
  /*****************************************************************************
   * オペレーションモード（押下ボタン）
   *****************************************************************************
   */
  public static final String OPERATION_APPLY  = "APPLY";
  public static final String OPERATION_SUBMIT = "SUBMIT";
// 2009-04-08 [ST障害T1_0364] Add End
// 2011-06-06 Ver1.7 [E_本稼動_01963] Add Start
  /*****************************************************************************
   * BM送付先新規作成判定
   *****************************************************************************
   */
  public static final String CREATE_VENDOR    = "CREATE";
// 2011-06-06 Ver1.7 [E_本稼動_01963] Add End

// 2016-01-06 [E_本稼動_13456] Add Start
  /*****************************************************************************
   * 自販機S連携フラグ
   *****************************************************************************
   */
  public static final String INTERFACE_NONE       = "0";
  public static final String INTERFACE_NO_TARGET  = "9";
// 2016-01-06 [E_本稼動_13456] Add End

  /*****************************************************************************
   * トークン値
   *****************************************************************************
   */
  // リージョン名
  public static final String
    TOKEN_VALUE_CONTRACT_INFO           = "契約者（甲）情報";
  public static final String
    TOKEN_VALUE_PAYCOND_INFO            = "振込日・締め日情報";
  public static final String
    TOKEN_VALUE_PERIOD_INFO             = "契約期間・途中解除情報";
  public static final String
    TOKEN_VALUE_BM1_DEST                = "ＢＭ１指定情報";
  public static final String
    TOKEN_VALUE_BM2_DEST                = "ＢＭ２指定情報";
  public static final String
    TOKEN_VALUE_BM3_DEST                = "ＢＭ３指定情報";
// 2015-02-06 [E_本稼動_12565] Add Start
  public static final String
    TOKEN_VALUE_INST_SUPP               = "設置協賛金情報";
  public static final String
    TOKEN_VALUE_INTRO_CHG               = "紹介手数料情報";
  public static final String
    TOKEN_VALUE_ELECTRIC                = "電気代情報";
// 2015-02-06 [E_本稼動_12565] Add End
  public static final String
    TOKEN_VALUE_INSTALL_INFO            = "設置先情報";
  public static final String
    TOKEN_VALUE_PUBLISH_BASE_INFO       = "発行元所属情報";

  // 項目名
  // 契約者（甲）情報リージョン
  public static final String
    TOKEN_VALUE_CONTRACT_NAME           = "契約者名(全角)";
  public static final String
    TOKEN_VALUE_DELEGATE_NAME           = "代表者名(全角)";
  public static final String
    TOKEN_VALUE_CONTRACT_POST_CODE      = "契約者住所　郵便番号(半角)";
  public static final String
    TOKEN_VALUE_CONTRACT_PREFECTURES    = "契約者住所　都道府県(全角)";
  public static final String
    TOKEN_VALUE_CONTRACT_CITY_WARD      = "契約者住所　市・区(全角)";
  public static final String
    TOKEN_VALUE_CONTRACT_ADDRESS_1      = "契約者住所　住所１(全角)";
  public static final String
    TOKEN_VALUE_CONTRACT_ADDRESS_2      = "契約者住所　住所２(全角)";
  public static final String
    TOKEN_VALUE_CONTRACT_EFFECT_DATE    = "契約書発効日";

  // 振込日・締め日情報リージョン
  public static final String
    TOKEN_VALUE_CLOSE_DAY_CODE          = "締め日";
  public static final String
    TOKEN_VALUE_TRANSFER_MONTH_CODE     = "振込月";
  public static final String
    TOKEN_VALUE_TRANSFER_DAY_CODE       = "振込日";

  // 契約期間・途中解除情報
  public static final String
    TOKEN_VALUE_CANCELLATION_OFFER_CODE = "契約解除申出";

  // ＢＭ指定情報
  public static final String
    TOKEN_VALUE_BM1                     = "ＢＭ１";
  public static final String
    TOKEN_VALUE_BM2                     = "ＢＭ２";
  public static final String
    TOKEN_VALUE_BM3                     = "ＢＭ３";

  public static final String
    TOKEN_VALUE_DELIVERY_CODE           = "送付先コード";
  public static final String
    TOKEN_VALUE_BANK_TRANSFER_FEE_CHARGE_DIV = "振込手数料負担";
  public static final String
    TOKEN_VALUE_BELLING_DETAILS_DIV     = "支払方法、明細書";
  public static final String
    TOKEN_VALUE_INQUERY_CHARGE_HUB_CD   = "問合せ担当拠点";
  public static final String
    TOKEN_VALUE_PAYMENT_NAME            = "送付先名(全角)";
  public static final String
    TOKEN_VALUE_PAYMENT_NAME_ALT        = "送付先名カナ(半角)";
  public static final String
    TOKEN_VALUE_POST_CODE               = "送付先住所　郵便番号(0000000)";
  public static final String
    TOKEN_VALUE_PREFECTURES             = "送付先住所　都道府県(全角)";
  public static final String
    TOKEN_VALUE_CITY_WARD               = "送付先住所　市・区(全角)";
  public static final String
    TOKEN_VALUE_ADDRESS_1               = "送付先住所　住所１(全角)";
  public static final String
    TOKEN_VALUE_ADDRESS_2               = "送付先住所　住所２(全角)";
  public static final String
    TOKEN_VALUE_ADDRESS_LINES_PHONETIC  = "送付先電話番号(00-0000-0000)";
  public static final String
    TOKEN_VALUE_BANK_NUMBER             = "金融機関名";
  public static final String
    TOKEN_VALUE_BANK_ACCOUNT_TYPE       = "口座種別";
  public static final String
    TOKEN_VALUE_BANK_ACCOUNT_NUMBER     = "口座番号(半角)";
  public static final String
    TOKEN_VALUE_BANK_ACCOUNT_NAME_KANA  = "口座名義カナ(半角)";
  public static final String
    TOKEN_VALUE_BANK_ACCOUNT_NAME_KANJI = "口座名義漢字(全角)";

  // 設置先情報
  public static final String
    TOKEN_VALUE_INSTALL_PARTY_NAME      = "設置先名(全角)";
  public static final String
    TOKEN_VALUE_INSTALL_POSTAL_CODE     = "設置先住所　郵便番号(0000000)";
  public static final String
    TOKEN_VALUE_INSTALL_STATE           = "設置先住所　都道府県(全角)";
  public static final String
    TOKEN_VALUE_INSTALL_CITY            = "設置先住所　市・区(全角)";
  public static final String
    TOKEN_VALUE_INSTALL_ADDRESS1        = "設置先住所　住所１(全角)";
  public static final String
    TOKEN_VALUE_INSTALL_ADDRESS2        = "設置先住所　住所２(全角)";
  public static final String
    TOKEN_VALUE_INSTALL_DATE            = "設置日";
  public static final String
    TOKEN_VALUE_INSTALL_CODE            = "物件コード";

  // 発行元所属情報
  public static final String
    TOKEN_VALUE_PUBLISH_DEPT_CODE       = "担当拠点";

  // チェックエラーメッセージ付加文言
  public static final String
    TOKEN_VALUE_DOUBLE_BYTE_KANA_CHK    = "全角カナチェック";
  public static final String
    TOKEN_VALUE_TEL_FORMAT_CHK          = "電話番号書式チェック";
  public static final String
    TOKEN_VALUE_DUPLICATE_VENDOR_NAME_CHK = "仕入先名重複チェック";
  public static final String
    TOKEN_VALUE_AR_GL_PERIOD_STATUS     = "AR会計期間クローズチェック";
  public static final String
    TOKEN_VALUE_BM_VENDOR_NAME          = "ＢＭ１送付先名～ＢＭ３送付先名";
// 2009-04-27 [ST障害T1_0708] Add Start
  public static final String
    TOKEN_VALUE_BFA_SINGLE_BYTE_KANA_CHK = "BFA半角カナチェック";
  public static final String
    TOKEN_VALUE_SINGLE_BYTE_KANA_CHK    = "半角カナチェック";
  public static final String
    TOKEN_VALUE_DOUBLE_BYTE_CHK         = "全角文字チェック";
// 2009-04-27 [ST障害T1_0708] Add End
// 2010-02-09 [E_本稼動_01538] Mod Start
  public static final String 
    TOKEN_VALUE_COOPERATE_WAIT_INFO_CHK = "マスタ連携待ちチェック";
  public static final String 
    TOKEN_VALUE_COOPERATE_STATUS_CHK    = "マスタ連携中チェック";
  public static final String 
    TOKEN_VALUE_VALIDATE_DB_CHK         = "DB値検証チェック";
// 2010-02-09 [E_本稼動_01538] Mod End
// 2010-03-01 [E_本稼動_01678] Add Start
  public static final String 
    TOKEN_VALUE_PAYMENT_TYPE_CASH_CHK   = "現金支払検証チェック";
// 2010-03-01 [E_本稼動_01678] Add End
// 2010-03-01 [E_本稼動_01868] Add Start
  public static final String 
    TOKEN_VALUE_INSTALL_CODE_CHK        = "物件コード検証チェック";
// 2010-03-01 [E_本稼動_01868] Add End
// 2015-11-30 [E_本稼動_13345] Add Start
  public static final String
    TOKEN_VALUE_STOP_ACCOUNT_CHK        = "中止顧客検証チェック";
  public static final String
    TOKEN_VALUE_ACCOUNT_INSTALL_CODE_CHK = "顧客物件検証チェック";
// 2015-11-30 [E_本稼動_13345] Add End
// 2011-01-06 Ver1.6 [E_本稼動_02498] Add Start
  public static final String 
    TOKEN_VALUE_BANK_BRANCH_CHK         = "銀行支店マスタチェック";
// 2011-01-06 Ver1.6 [E_本稼動_02498] Add End
// 2011-06-06 Ver1.7 [E_本稼動_01963] Add Start
  public static final String
    TOKEN_VALUE_SUPLLIER_MST_CHK        = "仕入先マスタチェック";
  public static final String
    TOKEN_CREATE_VENDOR_BEFORE_CONT     = "作成中";
  public static final String
    TOKEN_VALUE_BUNK_ACCOUNT_MST_CHK    = "銀行口座マスタチェック";
// 2011-06-06 Ver1.7 [E_本稼動_01963] Add End
// 2013-04-01 Ver1.9 [E_本稼動_10413] Add Start
  public static final String
    TOKEN_VALUE_PLURAL_SUPPLIER_CHK     = "銀行口座マスタ変更チェック";
// 2013-04-01 Ver1.9 [E_本稼動_10413] Add End
  // PDF出力時付加文言
  public static final String
    TOKEN_VALUE_PDF_OUT                 = "PDF出力";
  public static final String
    TOKEN_VALUE_START                   = "起動";

}