/*============================================================================
* ファイル名 : XxcsoSpDecisionConstants
* 概要説明   : SP専決固定値クラス
* バージョン : 1.14
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-12-17 1.0  SCS小川浩    新規作成
* 2009-03-23 1.1  SCS柳平直人  [ST障害T1_0163]課題No.115取り込み
* 2009-04-20 1.2  SCS柳平直人  [ST障害T1_0302]返却ボタン押下後表示不正対応
* 2009-04-27 1.3  SCS柳平直人  [ST障害T1_0708]文字列チェック処理統一修正
* 2009-08-24 1.4  SCS阿部大輔  [SCS障害0001104]申請区分チェック対応
* 2009-08-24 1.4  SCS阿部大輔  [SCS障害0001104]申請区分チェック対応
* 2009-11-29 1.5  SCS阿部大輔  [E_本稼動_00106]アカウント複数対応
* 2010-01-12 1.6  SCS阿部大輔  [E_本稼動_00823]顧客マスタの整合性チェック対応
* 2010-01-20 1.7  SCS阿部大輔  [E_本稼動_01176]顧客コード必須対応
* 2010-03-04 1.8  SCS阿部大輔  [E_本稼動_01678]現金支払対応
* 2014-01-31 1.9  SCSK桐生和幸 [E_本稼動_11397]売価1円対応
* 2014-03-13 1.10 SCSK桐生和幸 [E_本稼動_11670]税率変更警告メッセージ出力対応
* 2014-12-15 1.11 SCSK桐生和幸 [E_本稼動_12565]SP・契約書画面改修対応
* 2016-01-07 1.12 SCSK山下翔太 [E_本稼動_13456]自販機管理システム代替対応
* 2018-05-16 1.13 SCSK小路恭弘 [E_本稼動_14989]ＳＰ項目追加
* 2022-03-29 1.14 SCSK二村悠香 [E_本稼動_18060]自販機顧客別利益管理
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso020001j.util;

/*******************************************************************************
 * アドオン：SP専決の固定値クラスです。
 * @author  SCS小川浩
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoSpDecisionConstants 
{
  /*****************************************************************************
   * センタリングオブジェクト
   *****************************************************************************
   */
  public static final String[] CENTERING_OBJECTS =
  {
    "ApplyBaseTermLayout"
   ,"ApplyUserTermLayout"
   ,"ApplyDateTermLayout"
   ,"StatusTermLayout"
   ,"SpDecisionNumberTermLayout"
   ,"AccountTermLayout"
   ,"ApplyUserLayout"
   ,"InstallPostalCodeLayout"
   ,"BizCondTypeLayout"
   ,"BusinessTypeLayout"
   ,"InstallLocationLayout"
   ,"PublishBaseLayout"
   ,"ContractPostalCodeLayout"
// 2016-01-07 [E_本稼動_13456] Del Start
//   ,"VdInfo1Layout"
//   ,"VdInfo2Layout"
//   ,"VdInfo3Layout"
//   ,"VdInfo3RequiredLayout"
// 2016-01-07 [E_本稼動_13456] Del End
   ,"Bm1PostalCodeLayout"
   ,"Bm1TransferTypeLayout"
   ,"Bm1PaymentTypeLayout"
   ,"Bm1InquiryBaseLayout"
   ,"Bm2PostalCodeLayout"
   ,"Bm2TransferTypeLayout"
   ,"Bm2PaymentTypeLayout"
   ,"Bm2InquiryBaseLayout"
   ,"CntrPostalCodeLayout"
   ,"CntrTransferTypeLayout"
   ,"CntrPaymentTypeLayout"
   ,"CntrInquiryBaseLayout"
   ,"Bm3PostalCodeLayout"
   ,"Bm3TransferTypeLayout"
   ,"Bm3PaymentTypeLayout"
   ,"Bm3InquiryBaseLayout"
   ,"SalesGrossMarginRateLayout"
   ,"BmRateLayout"
   ,"OperatingProfitRateLayout"
  };

  /*****************************************************************************
   * 必須オブジェクト
   *****************************************************************************
   */
  public static final String[] REQUIRED_OBJECTS =
  {
    "InstallPostalCodeLayout"
   ,"BizCondTypeLayout"
   ,"BusinessTypeLayout"
   ,"InstallLocationLayout"
   ,"PublishBaseLayout"
   ,"ContractPostalCodeLayout"
// 2016-01-07 [E_本稼動_13456] Del Start
//   ,"VdInfo1Layout"
//   ,"VdInfo2Layout"
//   ,"VdInfo3RequiredLayout"
// 2016-01-07 [E_本稼動_13456] Del End
   ,"Bm1PostalCodeLayout"
// 2010-03-01 [E_本稼動_01678] Add Start
//   ,"Bm1TransferTypeLayout"
// 2010-03-01 [E_本稼動_01678] Add End
   ,"Bm1PaymentTypeLayout"
   ,"Bm2PostalCodeLayout"
// 2010-03-01 [E_本稼動_01678] Add Start
//   ,"Bm2TransferTypeLayout"
// 2010-03-01 [E_本稼動_01678] Add End
   ,"Bm2PaymentTypeLayout"
   ,"CntrPostalCodeLayout"
   ,"CntrTransferTypeLayout"
   ,"CntrPaymentTypeLayout"
   ,"Bm3PostalCodeLayout"
// 2010-03-01 [E_本稼動_01678] Add Start
//   ,"Bm3TransferTypeLayout"
// 2010-03-01 [E_本稼動_01678] Add End
   ,"Bm3PaymentTypeLayout"
   ,"BmRateLayout"
  };


  /*****************************************************************************
   * 読取専用オブジェクト
   *****************************************************************************
   */
  public static final String[] READONLY_OBJECTS =
  {
    "ConditionReasonView"
   ,"OtherContentView"
  };
  
  /*****************************************************************************
   * 検索区分
   *****************************************************************************
   */
  public static final String REGIST_MODE  = "1";
  public static final String APPROVE_MODE = "2";
  
  /*****************************************************************************
   * 処理区分
   *****************************************************************************
   */
  public static final String DETAIL_MODE = "1";
  public static final String COPY_MODE   = "2";

  /*****************************************************************************
   * 顧客区分
   *****************************************************************************
   */
  public static final String CUST_CLASS_INSTALL = "1";
  public static final String CUST_CLASS_CNTRCT  = "2";
  public static final String CUST_CLASS_BM1     = "3";
  public static final String CUST_CLASS_BM2     = "4";
  public static final String CUST_CLASS_BM3     = "5";
  
  /*****************************************************************************
   * ステータス
   *****************************************************************************
   */
  public static final String STATUS_INPUT   = "1";
  public static final String STATUS_APPROVE = "2";
  public static final String STATUS_ENABLE  = "3";
  public static final String STATUS_REJECT  = "4";

  /*****************************************************************************
   * 申請区分
   *****************************************************************************
   */
  public static final String APP_TYPE_NEW   = "1";
  public static final String APP_TYPE_MOD   = "2";

  /*****************************************************************************
   * 顧客ステータス
   *****************************************************************************
   */
  public static final String CUST_STATUS_MC_CAND = "10";
  public static final String CUST_STATUS_MC      = "20";
  
  /*****************************************************************************
   * 業態（小分類）
   *****************************************************************************
   */
  public static final String BIZ_COND_OFF_SET_VD = "24";
  public static final String BIZ_COND_FULL_VD    = "25";

// 2016-01-07 [E_本稼動_13456] Del Start
//  /*****************************************************************************
//   * 新／旧
//   *****************************************************************************
//   */
//  public static final String NEW_OLD_NEW         = "1";
//  public static final String NEW_OLD_OLD         = "2";
//
//  /*****************************************************************************
//   * 規格内／外
//   *****************************************************************************
//   */
//  public static final String STANDARD_TYPE_STD   = "1";
//  public static final String STANDARD_TYPE_EXT   = "2";
// 2016-01-07 [E_本稼動_13456] Del End

  /*****************************************************************************
   * 取引条件
   *****************************************************************************
   */
  public static final String COND_SALES                = "1";
  public static final String COND_SALES_CONTRIBUTE     = "2";
  public static final String COND_CNTNR                = "3";
  public static final String COND_CNTNR_CONTRIBUTE     = "4";
  public static final String COND_NON_PAY_BM           = "5";

  /*****************************************************************************
   * 全容器区分
   *****************************************************************************
   */
  public static final String CNTNR_ALL = "1";
  public static final String CNTNR_SEL = "2";

  /*****************************************************************************
   * 電気代区分
   *****************************************************************************
   */
// 2009-03-23 [ST障害T1_0163] Add Start
  public static final String ELEC_NONE     = "0";
// 2009-03-23 [ST障害T1_0163] Add End
  public static final String ELEC_FIXED    = "1";
  public static final String ELEC_VALIABLE = "2";
  
  /*****************************************************************************
   * 送付先
   *****************************************************************************
   */
  public static final String SEND_SAME_INSTALL = "1";
  public static final String SEND_SAME_CNTRCT  = "2";
  public static final String SEND_OTHER        = "3";

  /*****************************************************************************
   * 振込手数料負担
   *****************************************************************************
   */
  public static final String TRANSFER_CUST     = "S";

  /*****************************************************************************
   * 支払方法・明細書
   *****************************************************************************
   */
// 2010-03-01 [E_本稼動_01678] Add Start
  public static final String PAYMENT_TYPE_CASH = "4";
// 2010-03-01 [E_本稼動_01678] Add End
  public static final String PAYMENT_TYPE_NONE = "5";

  /*****************************************************************************
   * 範囲
   *****************************************************************************
   */
  public static final String RANGE_TYPE_RELATION = "1";

  /*****************************************************************************
   * 作業依頼区分
   *****************************************************************************
   */
  public static final String REQ_APPROVE = "1";
  public static final String REQ_CONFIRM = "2";

  /*****************************************************************************
   * 決裁状態区分
   *****************************************************************************
   */
  public static final String APPR_NONE   = "0";
  public static final String APPR_DURING = "1";
  public static final String APPR_END    = "2";

// 2009-04-20 [ST障害T1_0302] Add Start
  /*****************************************************************************
   * 決裁内容
   *****************************************************************************
   */
  public static final String APPR_CONT_APPROVE = "1";
  public static final String APPR_CONT_REJECT  = "2";
  public static final String APPR_CONT_CONFIRM = "3";
  public static final String APPR_CONT_RETURN  = "4";
// 2009-04-20 [ST障害T1_0302] Add End

// 2014-01-31 [E_本稼動_11397] Add Start
  /*****************************************************************************
   * カード売区分
   *****************************************************************************
   */
  public static final String CARD_SALE_CLASS_SALE = "0";
  public static final String CARD_SALE_CLASS_CARD = "1";
// 2014-01-31 [E_本稼動_11397] Add End

// 2014-12-15 [E_本稼動_12565] Add Start
  /*****************************************************************************
   * 行政財産使用料・設置協賛金・電気代・紹介手数料
   *****************************************************************************
   */
  public static final String CHECK_NO  = "0";  //チェック無し
  public static final String CHECK_YES = "1";  //チェック有り
  /*****************************************************************************
   * 支払条件（設置協賛金）
   *****************************************************************************
   */
  public static final String ONE_YEAR_PAY  = "1";  //1年払い
  public static final String TOTAL_PAY     = "2";  //総額払い
// Ver.1.14 Add Start
  public static final String QUARTER_PAY   = "3";  //四半期払い
  public static final String HALF_PAY      = "4";  //半年払い
  public static final String TWO_YEAR_PAY       = "5";  //2年払い
  public static final String THREE_YEAR_PAY     = "6";  //3年期払い
// Ver.1.14 Add End

  /*****************************************************************************
   * 支払条件（電気代）
   *****************************************************************************
   */
  public static final String CONTRACT       = "1";  //契約先
  public static final String CONTRACT_OTHER = "2";  //契約先以外

  /*****************************************************************************
   * 支払条件（紹介手数料）
   *****************************************************************************
   */
  public static final String SALES_BULK  = "1";  //売上に応じない一括支払の場合
  public static final String SALES_PAR   = "2";  //販売金額に対する％の場合
  public static final String SALES_AMT   = "3";  //1本につき何円の場合

// 2014-12-15 [E_本稼動_12565] Add End

  /*****************************************************************************
   * オペレーションモード
   *****************************************************************************
   */
  public static final String OPERATION_SUBMIT  = "SUBMIT";
  public static final String OPERATION_CONFIRM = "CONFIRM";
  public static final String OPERATION_RETURN  = "RETURN";
  public static final String OPERATION_APPROVE = "APPROVE";
  public static final String OPERATION_REJECT  = "REJECT";
// 2016-01-07 [E_本稼動_13456] Del Start
//  // 2009-08-24 [障害0001104] Add Start
//  public static final String OPERATION_REQUEST = "REQUEST";
//  // 2009-08-24 [障害0001104] Add End
// 2016-01-07 [E_本稼動_13456] Del End
  
  /*****************************************************************************
   * オペレーションモード
   *****************************************************************************
   */
  public static final int MAX_ATTACH_FILE_NAME_LENGTH = 100;

  /*****************************************************************************
   * 初期値
   *****************************************************************************
   */
  public static final String INIT_STATUS         = STATUS_INPUT;
  public static final String INIT_APP_TYPE       = APP_TYPE_NEW;
  public static final String INIT_BM1_PAY_CLASS  = PAYMENT_TYPE_NONE;
  public static final String INIT_BM2_PAY_CLASS  = PAYMENT_TYPE_NONE;
  public static final String INIT_BM3_PAY_CLASS  = PAYMENT_TYPE_NONE;
  public static final String INIT_CONSTRUCT_CHG  = "0";
  public static final String INIT_ELEC_CHG_MONTH = "0";
  public static final String INIT_RANGE_TYPE     = RANGE_TYPE_RELATION;
  public static final String INIT_APPROVE_CODE   = "*";
  
  /*****************************************************************************
   * マップパラメータ
   *****************************************************************************
   */
  public static final String PARAM_URL_PARAM = "URL_PARAM";
  public static final String PARAM_MESSAGE   = "MESSAGE";

  /*****************************************************************************
   * トークン値
   *****************************************************************************
   */
  public static final String
    TOKEN_VALUE_SP_DECISION           = "SP専決書";
  public static final String
    TOKEN_VALUE_SP_DEC_NUM            = "SP専決書番号：";
  public static final String
    TOKEN_VALUE_SUBMIT                = "提出";
  public static final String
    TOKEN_VALUE_CONFIRM               = "確認";
  public static final String
    TOKEN_VALUE_RETURN                = "返却";
  public static final String
    TOKEN_VALUE_APPROVE               = "承認";
  public static final String
    TOKEN_VALUE_REJECT                = "否決";
// 2016-01-07 [E_本稼動_13456] Del Start
//  public static final String
//    TOKEN_VALUE_REQUEST_CONC          = "発注依頼登録処理";
// 2016-01-07 [E_本稼動_13456] Del End
  public static final String
    TOKEN_VALUE_START                 = "起動";
// 2010-01-20 [E_本稼動_01176] Add Start
  public static final String 
    TOKEN_VALUE_INST_ACCOUNT_NUMBER   = "顧客コード";
// 2010-01-20 [E_本稼動_01176] Add End
  public static final String 
    TOKEN_VALUE_INST_PARTY_NAME       = "顧客名(全角)";
  public static final String
    TOKEN_VALUE_INST_PARTY_NAME_ALT   = "顧客名カナ(半角)";
  public static final String
    TOKEN_VALUE_INST_NAME             = "設置先名(全角)";
  public static final String
    TOKEN_VALUE_POSTAL_CODE           = "郵便番号";
  public static final String
    TOKEN_VALUE_STATE                 = "都道府県(全角)";
  public static final String
    TOKEN_VALUE_CITY                  = "市・区(全角)";
  public static final String
    TOKEN_VALUE_ADDRESS1              = "住所1(全角)";
  public static final String
    TOKEN_VALUE_ADDRESS2              = "住所2(全角)";
  public static final String
    TOKEN_VALUE_ADDRESS_LINIE         = "電話番号(00-0000-0000)";
  public static final String
    TOKEN_VALUE_BUSINESS_CONDITION    = "業態（小分類）";
  public static final String
    TOKEN_VALUE_BUSINESS_TYPE         = "業種";
  public static final String
    TOKEN_VALUE_INSTALL_LOCATION      = "設置場所";
  public static final String
    TOKEN_VALUE_EMPLOYEES             = "社員数";
  public static final String
    TOKEN_VALUE_PUBLISHED_BASE        = "担当拠点";
  public static final String
    TOKEN_VALUE_INSTALL_DATE          = "設置日";
  public static final String
    TOKEN_VALUE_LEASE_COMP            = "リース仲介会社";
  public static final String 
    TOKEN_VALUE_CNTR_PARTY_NAME       = "契約先名(全角)";
  public static final String
    TOKEN_VALUE_CNTR_PARTY_NAME_ALT   = "契約先名カナ(半角)";
  public static final String
    TOKEN_VALUE_DELEGATE              = "代表者(全角)";
// 2016-01-07 [E_本稼動_13456] Del Start
//  public static final String
//    TOKEN_VALUE_NEW_OLD               = "新／旧";
//  public static final String
//    TOKEN_VALUE_MAKER_NAME            = "メーカー名";
//  public static final String
//    TOKEN_VALUE_STD_TYPE              = "規格内／外";
//  public static final String
//    TOKEN_VALUE_SELE_NUMBER           = "セレ数";
//  public static final String
//    TOKEN_VALUE_MAKER_CODE            = "メーカー名";
//  public static final String
//    TOKEN_VALUE_VENDOR_MODEL          = "機種コード";
// 2016-01-07 [E_本稼動_13456] Del End
  public static final String
    TOKEN_VALUE_COND_BIZ              = "取引条件";
  public static final String
    TOKEN_VALUE_FIXED_PRICE           = "定価";
  public static final String
    TOKEN_VALUE_SALES_PRICE           = "売価";
  public static final String
    TOKEN_VALUE_DISCOUNT_AMT          = "定価からの値引額";
  public static final String
    TOKEN_VALUE_BM1_BM_RATE           = "BM1のBM率";
  public static final String
    TOKEN_VALUE_BM2_BM_RATE           = "BM2のBM率";
  public static final String
    TOKEN_VALUE_CONTRIBUTE_BM_RATE    = "寄付金のBM率";
  public static final String
    TOKEN_VALUE_BM3_BM_RATE           = "BM3のBM率";
  public static final String
    TOKEN_VALUE_BM1_BM_AMT            = "BM1のBM金額";
  public static final String
    TOKEN_VALUE_BM2_BM_AMT            = "BM2のBM金額";
  public static final String
    TOKEN_VALUE_CONTRIBUTE_BM_AMT     = "寄付金のBM金額";
  public static final String
    TOKEN_VALUE_BM3_BM_AMT            = "BM3のBM金額";
  public static final String
    TOKEN_VALUE_CONTRACT_YEAR         = "契約年数";
  public static final String
    TOKEN_VALUE_INST_SUP_AMT          = "初回設置協賛金";
  public static final String
    TOKEN_VALUE_INST_SUP_AMT2         = "2回目以降設置協賛金";
  public static final String
    TOKEN_VALUE_PAYMENT_CYCLE         = "支払サイクル";
  public static final String
    TOKEN_VALUE_ELECTRICITY_AMOUNT    = "電気代";
  public static final String
    TOKEN_VALUE_COND_REASON           = "特別条件の理由/特記事項/他条件";
  public static final String
    TOKEN_VALUE_BM1_SEND_TYPE         = "送付先";
  public static final String 
    TOKEN_VALUE_BM_PARTY_NAME         = "送付先名(全角)";
  public static final String
    TOKEN_VALUE_BM_PARTY_NAME_ALT     = "送付先名カナ(半角)";
  public static final String
    TOKEN_VALUE_TRANSFER              = "振込手数料負担";
  public static final String
    TOKEN_VALUE_OTHER_CONTENT         = "特約事項";
  public static final String
    TOKEN_VALUE_SALES_MONTH           = "月間売上";
  public static final String
    TOKEN_VALUE_BM_RATE               = "支払ＢＭ率";
  public static final String
    TOKEN_VALUE_LEASE_CHARGE          = "リース料（月額）";
  public static final String
    TOKEN_VALUE_CONSTRUCT_CHARGE      = "工事費";
  public static final String
    TOKEN_VALUE_ELECTRICITY_AMT_MONTH = "電気代（月）";
  public static final String
    TOKEN_VALUE_EXCERPT               = "摘要";
  public static final String
    TOKEN_VALUE_COMMENT               = "決裁コメント";
  public static final String
    TOKEN_VALUE_INSTALL_REGION        = "設置先";
  public static final String 
    TOKEN_VALUE_CNTRCT_REGION         = "契約先";
  public static final String
    TOKEN_VALUE_BM1_REGION            = "BM1";
  public static final String
    TOKEN_VALUE_BM2_REGION            = "BM2";
  public static final String
    TOKEN_VALUE_CONTRIBUTE_REGION     = "寄付金";
  public static final String
    TOKEN_VALUE_BM3_REGION            = "BM3";
  public static final String
    TOKEN_VALUE_VD_INFO_REGION        = "VD情報";
  public static final String
    TOKEN_VALUE_COND_BIZ_REGION       = "取引条件";
  public static final String
    TOKEN_VALUE_OTHER_COND_REGION     = "その他条件";
// 2014-12-15 [E_本稼動_12565] Add Start
  public static final String
    TOKEN_VALUE_MEMO_RANDUM_INFO_REGION = "覚書情報";
// 2014-12-15 [E_本稼動_12565] Add End
  public static final String
    TOKEN_VALUE_CNTRCT_CONTENT_REGION = "契約書への記載事項";
  public static final String
    TOKEN_VALUE_EST_PROFIT_REGION     = "概算年間損益";
  public static final String
    TOKEN_VALUE_ATTACH_REGION         = "添付";
  public static final String
    TOKEN_VALUE_SEND_REGION           = "回送先";
  public static final String
    TOKEN_VALUE_DOUBLE_BYTE_KANA_CHK  = "全角カナチェック";
  public static final String
    TOKEN_VALUE_TEL_FORMAT_CHK        = "電話番号書式チェック";
  public static final String
    TOKEN_VALUE_ATTACH_FILE_NAME      = "添付ファイル名";
  public static final String
    TOKEN_VALUE_CALC_LINE             = "定価換算率計算";
  public static final String
    TOKEN_VALUE_APPR_AUTH_LEVEL_CHK   = "承認権限レベル判定";
// 2016-01-07 [E_本稼動_13456] Del Start
//  public static final String
//    TOKEN_VALUE_IB_REQUEST            = "自販機（什器）発注依頼データ連携機能";
// 2016-01-07 [E_本稼動_13456] Del End
  public static final String
    TOKEN_VALUE_CONV_NUMBER_SEPARATE  = "数値のセパレート変換";
  public static final String
    TOKEN_VALUE_SALES_COND            = "売価別条件";
  public static final String
    TOKEN_VALUE_EMPLOYEE_NUMBER       = "社員番号";
// 2009-04-27 [ST障害T1_0708] Add Start
  public static final String
    TOKEN_VALUE_SINGLE_BYTE_KANA_CHK  = "半角カナチェック";
  public static final String
    TOKEN_VALUE_DOUBLE_BYTE_CHK       = "全角文字チェック";
// 2009-04-27 [ST障害T1_0708] Add End
// 2009-11-29 [E_本稼動_00106] Add Start
  public static final String
     TOKEN_VALUE_ACCOUNT_CHK           = "複数アカウントチェック";
// 2009-11-29 [E_本稼動_00106] Add End
// 2010-01-12 [E_本稼動_00823] Add Start
  public static final String
     TOKEN_VALUE_SITE_USE_CODE_CHK     = "顧客使用目的チェック";
// 2010-01-12 [E_本稼動_00823] Add End
// 2014-01-31 [E_本稼動_11397] Add Start
  public static final String
     TOKEN_VALUE_CARD_SALE_CLASS       = "カード売区分";
  public static final String
     TOKEN_VALUE_CARD_SALE_CLASS_SALE  = "現金";
  public static final String
     TOKEN_VALUE_CARD_SALE_CLASS_CARD  = "カード";
// 2014-01-31 [E_本稼動_11397] Add End
// 2014-03-13 [E_本稼動_11670] Add Start
  public static final String
    TOKEN_VALUE_COMPARE_TAX_CODE       = "税比較関数の実行";
// 2014-03-13 [E_本稼動_11670] Add End
// 2014-12-15 [E_本稼動_12565] Add Start
  public static final String
    TOKEN_VALUE_CONTRACT_YEAR_MONTH    = "契約月数";
  public static final String
    TOKEN_VALUE_CONTRACT_START_YEAR    = "契約期間開始（年）";
  public static final String
    TOKEN_VALUE_CONTRACT_START_MONTH   = "契約期間開始（月）";
  public static final String
    TOKEN_VALUE_CONTRACT_END_YEAR      = "契約期間終了（年）";
  public static final String
    TOKEN_VALUE_CONTRACT_END_MONTHR    = "契約期間終了（月）";
  public static final String
    TOKEN_VALUE_AD_ASSETS_AMT          = "総額（行政財産使用料）";
  public static final String
    TOKEN_VALUE_AD_ASSETS_THIS_TIME    = "今回支払（行政財産使用料）";
  public static final String
    TOKEN_VALUE_AD_ASSETS_PAYMENT_YEAR = "支払年数（行政財産使用料）";
  public static final String
    TOKEN_VALUE_AD_ASSETS_PAYMENT_DATE = "支払期日（行政財産使用料）";
  public static final String
    TOKEN_VALUE_AD_INSTALL_SUPP_AMT    = "総額（設置協賛金）";
  public static final String
    TOKEN_VALUE_INSTALL_SUPP_THIS_TIME = "今回支払（設置協賛金）";
  public static final String
    TOKEN_VALUE_INSTALL_SUPP_PAYMENT_YEAR = "支払年数（設置協賛金）";
  public static final String
    TOKEN_VALUE_INSTALL_SUPP_PAYMENT_DATE = "支払期日（設置協賛金）";
  public static final String
    TOKEN_VALUE_ELECTRIC_TRANS_NAME       = "契約先以外名（電気代）";
  public static final String
    TOKEN_VALUE_ELECTRIC_TRANS_NAME_ALT   = "契約先以外名カナ（電気代）";
  public static final String
    TOKEN_VALUE_INTRO_CHG_AMT             = "総額（紹介手数料）";
  public static final String
    TOKEN_VALUE_INTRO_CHG_THIS_TIME       = "今回支払（紹介手数料）";
  public static final String
    TOKEN_VALUE_INTRO_CHG_PAYMENT_YEAR    = "支払年数（紹介手数料）";
  public static final String
    TOKEN_VALUE_INTRO_CHG_PAYMENT_DATE    = "支払期日（紹介手数料）";
  public static final String
    TOKEN_VALUE_INTRO_CHG_PER_SALES_PRICE = "販売金額に対し（紹介手数料）";
  public static final String
    TOKEN_VALUE_INTRO_CHG_PER_PIECE       = "１本につき（紹介手数料）";
  public static final String
    TOKEN_VALUE_INTRO_CHG_TRANS_NAME      = "契約先以外名（紹介手数料）";
  public static final String
    TOKEN_VALUE_INTRO_CHG_TRANS_NAME_ALT  = "契約先以外名カナ（紹介手数料）";
  public static final String
     TOKEN_VALUE_CONTRACT_END_CHK         = "契約終了期間の検証";
// 2014-12-15 [E_本稼動_12565] Add End
// 2018-05-16 [E_本稼動_14989] Add Start
  public static final String
    TOKEN_VALUE_CONSTRUCTION_PERIOD       = "工期";
  public static final String
    TOKEN_VALUE_CONSTRUCTION_START_YEAR   = "工期開始（年）";
  public static final String
    TOKEN_VALUE_CONSTRUCTION_START_MONTH  = "工期開始（月）";
  public static final String
    TOKEN_VALUE_CONSTRUCTION_END_YEAR     = "工期終了（年）";
  public static final String
    TOKEN_VALUE_CONSTRUCTION_END_MONTHR   = "工期終了（月）";
  public static final String
    TOKEN_VALUE_INSTALLATION_PERIOD       = "設置見込み期間";
  public static final String
    TOKEN_VALUE_INSTALLATION_START_YEAR   = "設置見込み期間開始（年）";
  public static final String
    TOKEN_VALUE_INSTALLATION_START_MONTH  = "設置見込み期間開始（月）";
  public static final String
    TOKEN_VALUE_INSTALLATION_END_YEAR     = "設置見込み期間終了（年）";
  public static final String
    TOKEN_VALUE_INSTALLATION_END_MONTH    = "設置見込み期間終了（月）";

// 2018-05-16 [E_本稼動_14989] Add End
// Ver.1.14 Add Start
  public static final String TAX_TYPE    = "税区分";
  public static final String
    TOKEN_VALUE_INSTALL_SUPP_PAYMENT_TYPE   = "支払条件（設置協賛金）";
  public static final String
    TOKEN_VALUE_INSTALL_SUPP_PAY_START_DATE = "支払期間開始日（設置協賛金）";
  public static final String
    TOKEN_VALUE_INSTALL_SUPP_PAY_START_YEAR = "支払期間開始日（設置協賛金）（年）";
  public static final String
    TOKEN_VALUE_INSTALL_SUPP_PAY_START_MONTH = "支払期間開始日（設置協賛金）（月）";
  public static final String
    TOKEN_VALUE_INSTALL_SUPP_PAY_END_DATE   = "支払期間終了日（設置協賛金）";
  public static final String
    TOKEN_VALUE_INSTALL_SUPP_PAY_END_YEAR   = "支払期間終了日（設置協賛金）（年）";
  public static final String
    TOKEN_VALUE_INSTALL_SUPP_PAY_END_MONTH   = "支払期間終了日（設置協賛金）（月）";
  public static final String
    TOKEN_VALUE_AD_ASSETS_PAYMENT_TYPE      = "支払条件（行政財産使用料）";
  public static final String
    TOKEN_VALUE_AD_ASSETS_PAY_START_DATE    = "支払期間開始日（行政財産使用料）";
  public static final String
    TOKEN_VALUE_AD_ASSETS_PAY_START_YEAR    = "支払期間開始日（行政財産使用料）（年）";
  public static final String
    TOKEN_VALUE_AD_ASSETS_PAY_START_MONTH    = "支払期間開始日（行政財産使用料）（月）";
  public static final String
    TOKEN_VALUE_AD_ASSETS_PAY_END_DATE      = "支払期間終了日（行政財産使用料）";
  public static final String
    TOKEN_VALUE_AD_ASSETS_PAY_END_YEAR      = "支払期間終了日（行政財産使用料）（年）";
  public static final String
    TOKEN_VALUE_AD_ASSETS_PAY_END_MONTH      = "支払期間終了日（行政財産使用料）（月）";
  public static final String
    TOKEN_VALUE_CHK_PAY_START_DATE          = "支払期間開始日のチェック";
  public static final String
    TOKEN_VALUE_CHK_PAY_ITM                 = "支払項目のチェック";
  public static final String
    TOKEN_VALUE_CHK_PAY_DATE                = "支払期間大小のチェック";
  /*****************************************************************************
   * データ区分
   *****************************************************************************
   */
  public static final String INSTALL_SUPP_KBN = "1";
  public static final String AD_ASSETS_KBN    = "2";
// Ver.1.14 Add End
}