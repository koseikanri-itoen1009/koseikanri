/*============================================================================
* ファイル名 : XxcsoSpDecisionValidateUtils
* 概要説明   : SP専決登録画面用検証ユーティリティクラス
* バージョン : 1.25
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-12-27 1.0  SCS小川浩    新規作成
* 2009-03-04 1.1  SCS小川浩    課題一覧No.73対応
* 2009-03-23 1.2  SCS柳平直人  [ST障害T1_0163]課題No.115取り込み
* 2009-04-13 1.3  SCS柳平直人  [ST障害T1_0225]契約先validate修正
* 2009-04-27 1.4  SCS柳平直人  [ST障害T1_0708]入力項目チェック処理統一修正
* 2009-05-19 1.5  SCS柳平直人  [ST障害T1_1058]契約先validate処理統一対応
                                               可視性のためT1_0225対応物理削除
* 2009-06-08 1.6  SCS柳平直人  [ST障害T1_1307]半角カナチェックメッセージ修正
* 2009-08-06 1.7  SCS小川浩    [SCS障害0000887]回送先チェック対応
* 2009-10-14 1.8  SCS阿部大輔  [共通課題IE554,IE573]住所対応
* 2009-11-29 1.9  SCS阿部大輔  [E_本稼動_00106]アカウント複数対応
* 2009-12-17 1.10 SCS阿部大輔  [E_本稼動_00514]郵便番号対応
* 2010-01-08 1.11 SCS阿部大輔  [E_本稼動_01030]承認権限チェック対応
* 2010-01-12 1.12 SCS阿部大輔  [E_本稼動_00823]顧客マスタの整合性チェック対応
* 2010-01-15 1.13 SCS阿部大輔  [E_本稼動_00950]画面値、ＤＢ値チェック対応
* 2010-01-20 1.14 SCS阿部大輔  [E_本稼動_01176]顧客コード必須対応
* 2010-03-01 1.15 SCS阿部大輔  [E_本稼動_01678]現金支払対応
* 2011-04-04 1.16 SCS吉元強樹  [E_本稼動_02498]SP専決回送先承認者必須チェック対応
* 2013-04-19 1.17 SCSK桐生和幸 [E_本稼動_09603]契約書未確定による顧客区分遷移の変更対応
* 2014-01-31 1.18 SCSK桐生和幸 [E_本稼動_11397]売価1円対応
* 2014-12-15 1.19 SCSK桐生和幸 [E_本稼動_12565]SP・契約書画面改修対応
* 2016-01-07 1.20 SCSK山下翔太 [E_本稼動_13456]自販機管理システム代替対応
* 2018-05-16 1.21 SCSK小路恭弘 [E_本稼動_14989]ＳＰ項目追加
* 2020-08-21 1.22 SCSK佐々木大和[E_本稼動_15904]税抜きでの自販機BM計算について
* 2020-10-28 1.23 SCSK佐々木大和[E_本稼動_16293]SP・契約書画面からの仕入先コードの選択について
* 2022-04-21 1.24 SCSK二村悠香 [E_本稼動_18060]自販機顧客別利益管理
* 2022-07-20 1.25 SCSK赤地学   [E_本稼動_18508]自販機SPが承認できない
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso020001j.util;

import oracle.apps.fnd.framework.server.OADBTransaction;
import oracle.apps.fnd.framework.OAException;
import oracle.jbo.domain.Number;
import oracle.jdbc.OracleCallableStatement;
import oracle.jdbc.OracleTypes;
import oracle.sql.NUMBER;
import itoen.oracle.apps.xxcso.common.util.XxcsoUtils;
import itoen.oracle.apps.xxcso.common.util.XxcsoValidateUtils;
import itoen.oracle.apps.xxcso.common.util.XxcsoMessage;
import itoen.oracle.apps.xxcso.common.util.XxcsoConstants;
import itoen.oracle.apps.xxcso.xxcso020001j.server.XxcsoSpDecisionHeaderFullVOImpl;
import itoen.oracle.apps.xxcso.xxcso020001j.server.XxcsoSpDecisionHeaderFullVORowImpl;
import itoen.oracle.apps.xxcso.xxcso020001j.server.XxcsoSpDecisionInstCustFullVOImpl;
import itoen.oracle.apps.xxcso.xxcso020001j.server.XxcsoSpDecisionInstCustFullVORowImpl;
import itoen.oracle.apps.xxcso.xxcso020001j.server.XxcsoSpDecisionCntrctCustFullVOImpl;
import itoen.oracle.apps.xxcso.xxcso020001j.server.XxcsoSpDecisionCntrctCustFullVORowImpl;
import itoen.oracle.apps.xxcso.xxcso020001j.server.XxcsoSpDecisionBm1CustFullVOImpl;
import itoen.oracle.apps.xxcso.xxcso020001j.server.XxcsoSpDecisionBm1CustFullVORowImpl;
import itoen.oracle.apps.xxcso.xxcso020001j.server.XxcsoSpDecisionBm2CustFullVOImpl;
import itoen.oracle.apps.xxcso.xxcso020001j.server.XxcsoSpDecisionBm2CustFullVORowImpl;
import itoen.oracle.apps.xxcso.xxcso020001j.server.XxcsoSpDecisionBm3CustFullVOImpl;
import itoen.oracle.apps.xxcso.xxcso020001j.server.XxcsoSpDecisionBm3CustFullVORowImpl;
import itoen.oracle.apps.xxcso.xxcso020001j.server.XxcsoSpDecisionAttachFullVOImpl;
import itoen.oracle.apps.xxcso.xxcso020001j.server.XxcsoSpDecisionAttachFullVORowImpl;
import itoen.oracle.apps.xxcso.xxcso020001j.server.XxcsoSpDecisionSendFullVOImpl;
import itoen.oracle.apps.xxcso.xxcso020001j.server.XxcsoSpDecisionSendFullVORowImpl;
import itoen.oracle.apps.xxcso.xxcso020001j.server.XxcsoSpDecisionScLineFullVOImpl;
import itoen.oracle.apps.xxcso.xxcso020001j.server.XxcsoSpDecisionScLineFullVORowImpl;
import itoen.oracle.apps.xxcso.xxcso020001j.server.XxcsoSpDecisionAllCcLineFullVOImpl;
import itoen.oracle.apps.xxcso.xxcso020001j.server.XxcsoSpDecisionAllCcLineFullVORowImpl;
import itoen.oracle.apps.xxcso.xxcso020001j.server.XxcsoSpDecisionSelCcLineFullVOImpl;
import itoen.oracle.apps.xxcso.xxcso020001j.server.XxcsoSpDecisionSelCcLineFullVORowImpl;
import com.sun.java.util.collections.List;
import com.sun.java.util.collections.ArrayList;
import java.sql.SQLException;
// Ver.1.24 Add Start
import oracle.jbo.domain.Date;
// Ver.1.24 Add End

/*******************************************************************************
 * SP専決書登録画面用のデータを検証するためのユーティリティクラスです。
 * @author  SCS小川浩
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoSpDecisionValidateUtils 
{
  /*****************************************************************************
   * 設置先の検証
   * @param txn         OADBTransactionインスタンス
   * @param headerVo    SP専決ヘッダ登録／更新用ビューインスタンス
   * @param installVo   設置先登録／更新用ビューインスタンス
// 2009-11-29 [E_本稼動_00106] Add Start
   * @param OperationMode  操作モード
// 2009-11-29 [E_本稼動_00106] Add End
   * @param submitFlag  提出用フラグ
   * @return List       エラーリスト
   *****************************************************************************
   */
  public static List validateInstallCust(
    OADBTransaction                     txn
   ,XxcsoSpDecisionHeaderFullVOImpl     headerVo
   ,XxcsoSpDecisionInstCustFullVOImpl   installVo
// 2009-11-29 [E_本稼動_00106] Add Start
   ,String                              OperationMode
// 2009-11-29 [E_本稼動_00106] Add End
   ,boolean                             submitFlag
  )
  {
    XxcsoUtils.debug(txn, "[START]");
    
    List errorList = new ArrayList();
    String token1 = null;
    
    /////////////////////////////////////
    // 各行を取得
    /////////////////////////////////////
    XxcsoSpDecisionHeaderFullVORowImpl headerRow
      = (XxcsoSpDecisionHeaderFullVORowImpl)headerVo.first();
    XxcsoSpDecisionInstCustFullVORowImpl installRow
      = (XxcsoSpDecisionInstCustFullVORowImpl)installVo.first();

    XxcsoValidateUtils utils = XxcsoValidateUtils.getInstance(txn);

    String applicationType = headerRow.getApplicationType();
    
// 2009-11-29 [E_本稼動_00106] Add Start
    /////////////////////////////////////
    // 設置先：顧客コード
    /////////////////////////////////////
// 2010-01-20 [E_本稼動_01176] Add Start
    // 提出ボタンの場合
    if (OperationMode==XxcsoSpDecisionConstants.OPERATION_SUBMIT)
    {
      token1 = XxcsoSpDecisionConstants.TOKEN_VALUE_INSTALL_REGION
              + XxcsoConstants.TOKEN_VALUE_DELIMITER1
              + XxcsoSpDecisionConstants.TOKEN_VALUE_INST_ACCOUNT_NUMBER;
      errorList
        =  utils.requiredCheck(
             errorList
            ,installRow.getInstallAccountNumber()
            ,token1
            ,0
           );
    }
// 2010-01-20 [E_本稼動_01176] Add End
    // 提出、承認、確認ボタンの場合
    if (
        OperationMode==XxcsoSpDecisionConstants.OPERATION_SUBMIT ||
        OperationMode==XxcsoSpDecisionConstants.OPERATION_CONFIRM ||
        OperationMode==XxcsoSpDecisionConstants.OPERATION_APPROVE
       )
    {
      String AccountNumber;
// 2010-01-12 [E_本稼動_00823] Add Start
      // アカウント複数検証
// 2010-01-12 [E_本稼動_00823] Add End
      AccountNumber = validateAccount(txn,installRow.getInstallAccountNumber());
      if (!(AccountNumber == null || "".equals(AccountNumber)))
      {
        token1 =AccountNumber;
        OAException error
          = XxcsoMessage.createErrorMessage(
              XxcsoConstants.APP_XXCSO1_00586
             ,XxcsoConstants.TOKEN_REGION
             ,AccountNumber
            );
        errorList.add(error);
      }
// 2010-01-12 [E_本稼動_00823] Add Start
      String customerStatus = installRow.getCustomerStatus();
      // MC,MC候補の時のみチェック
      if ( XxcsoSpDecisionConstants.CUST_STATUS_MC.equals(customerStatus)     ||
         XxcsoSpDecisionConstants.CUST_STATUS_MC_CAND.equals(customerStatus)
       )
      {
        // 顧客使用目的検証
        String SiteUseCode;
        SiteUseCode = validateSiteUses(txn,installRow.getInstallAccountNumber());
        if (!(SiteUseCode == null || "".equals(SiteUseCode)))
        {
          token1 =AccountNumber;
          OAException error
            = XxcsoMessage.createErrorMessage(
                XxcsoConstants.APP_XXCSO1_00589
               ,XxcsoConstants.TOKEN_PARAM1
               ,SiteUseCode
              );
          errorList.add(error);
        }
      }
// 2010-01-12 [E_本稼動_00823] Add End
    }
// 2009-11-29 [E_本稼動_00106] Add End

    /////////////////////////////////////
    // 設置先：顧客名
    /////////////////////////////////////
    token1 = XxcsoSpDecisionConstants.TOKEN_VALUE_INSTALL_REGION
            + XxcsoConstants.TOKEN_VALUE_DELIMITER1
            + XxcsoSpDecisionConstants.TOKEN_VALUE_INST_PARTY_NAME;
    if ( submitFlag )
    {
      errorList
        =  utils.requiredCheck(
              errorList
            ,installRow.getPartyName()
            ,token1
            ,0
           );
    }
    errorList
      = utils.checkIllegalString(
          errorList
         ,installRow.getPartyName()
         ,token1
         ,0
        );
// 2009-04-27 [ST障害T1_0708] Add Start
    if ( ! isDoubleByte(
             txn
            ,installRow.getPartyName()
           )
       )
    {
      OAException error
        = XxcsoMessage.createErrorMessage(
            XxcsoConstants.APP_XXCSO1_00565
           ,XxcsoConstants.TOKEN_REGION
           ,XxcsoSpDecisionConstants.TOKEN_VALUE_INSTALL_REGION
           ,XxcsoConstants.TOKEN_COLUMN
           ,XxcsoSpDecisionConstants.TOKEN_VALUE_INST_PARTY_NAME
          );
      errorList.add(error);
    }
// 2009-04-27 [ST障害T1_0708] Add End

    /////////////////////////////////////
    // 設置先：顧客名（カナ）
    /////////////////////////////////////
    token1 = XxcsoSpDecisionConstants.TOKEN_VALUE_INSTALL_REGION
            + XxcsoConstants.TOKEN_VALUE_DELIMITER1
            + XxcsoSpDecisionConstants.TOKEN_VALUE_INST_PARTY_NAME_ALT;
    errorList
      = utils.checkIllegalString(
          errorList
         ,installRow.getPartyNameAlt()
         ,token1
         ,0
        );
// 2009-04-27 [ST障害T1_0708] Mod Start
//    if ( ! isDoubleByteKana(
//             txn
//            ,installRow.getPartyNameAlt()
//           )
//       )
//    {
//      OAException error
//        = XxcsoMessage.createErrorMessage(
//            XxcsoConstants.APP_XXCSO1_00286
//           ,XxcsoConstants.TOKEN_REGION
//           ,XxcsoSpDecisionConstants.TOKEN_VALUE_INSTALL_REGION
//           ,XxcsoConstants.TOKEN_COLUMN
//           ,XxcsoSpDecisionConstants.TOKEN_VALUE_INST_PARTY_NAME_ALT
//          );
//      errorList.add(error);
//    }
    // 半角カナチェック
    if ( ! isSingleByteKana(
             txn
            ,installRow.getPartyNameAlt()
           )
       )
    {
      OAException error
        = XxcsoMessage.createErrorMessage(
// 2009-06-08 [ST障害T1_1307] Mod Start
//            XxcsoConstants.APP_XXCSO1_00533
            XxcsoConstants.APP_XXCSO1_00573
// 2009-06-08 [ST障害T1_1307] Mod End
           ,XxcsoConstants.TOKEN_REGION
           ,XxcsoSpDecisionConstants.TOKEN_VALUE_INSTALL_REGION
           ,XxcsoConstants.TOKEN_COLUMN
           ,XxcsoSpDecisionConstants.TOKEN_VALUE_INST_PARTY_NAME_ALT
          );
      errorList.add(error);
    }
// 2009-04-27 [ST障害T1_0708] Mod End

// 2009-04-27 [ST障害T1_0708] Add Start
    /////////////////////////////////////
    // 設置先：設置先名
    /////////////////////////////////////
    token1 = XxcsoSpDecisionConstants.TOKEN_VALUE_INSTALL_REGION
            + XxcsoConstants.TOKEN_VALUE_DELIMITER1
            + XxcsoSpDecisionConstants.TOKEN_VALUE_INST_NAME;
    errorList
      = utils.checkIllegalString(
          errorList
         ,installRow.getInstallName()
         ,token1
         ,0
        );
    if ( ! isDoubleByte(
             txn
            ,installRow.getInstallName()
           )
       )
    {
      OAException error
        = XxcsoMessage.createErrorMessage(
            XxcsoConstants.APP_XXCSO1_00565
           ,XxcsoConstants.TOKEN_REGION
           ,XxcsoSpDecisionConstants.TOKEN_VALUE_INSTALL_REGION
           ,XxcsoConstants.TOKEN_COLUMN
           ,XxcsoSpDecisionConstants.TOKEN_VALUE_INST_NAME
          );
      errorList.add(error);
    }
// 2009-04-27 [ST障害T1_0708] Add End

    /////////////////////////////////////
    // 設置先：郵便番号
    /////////////////////////////////////
    token1 = XxcsoSpDecisionConstants.TOKEN_VALUE_INSTALL_REGION
            + XxcsoConstants.TOKEN_VALUE_DELIMITER1
            + XxcsoSpDecisionConstants.TOKEN_VALUE_POSTAL_CODE;
    if ( submitFlag )
    {
      if ( installRow.getPostalCodeFirst() == null             ||
           "".equals(installRow.getPostalCodeFirst().trim())   ||
           installRow.getPostalCodeSecond() == null            ||
           "".equals(installRow.getPostalCodeSecond().trim())
         )
      {
        OAException error
          = XxcsoMessage.createErrorMessage(
              XxcsoConstants.APP_XXCSO1_00005
             ,XxcsoConstants.TOKEN_COLUMN
             ,token1
            );
        errorList.add(error);
      }

      if ( ! isPostalCode(
               txn
              ,installRow.getPostalCodeFirst()
              ,installRow.getPostalCodeSecond()
             )
         )
      {
        token1 = XxcsoSpDecisionConstants.TOKEN_VALUE_INSTALL_REGION;
        OAException error
          = XxcsoMessage.createErrorMessage(
              XxcsoConstants.APP_XXCSO1_00287
             ,XxcsoConstants.TOKEN_REGION
             ,token1
            );
        errorList.add(error);
      }
    }

    /////////////////////////////////////
    // 設置先：都道府県
    /////////////////////////////////////
    token1 = XxcsoSpDecisionConstants.TOKEN_VALUE_INSTALL_REGION
            + XxcsoConstants.TOKEN_VALUE_DELIMITER1
            + XxcsoSpDecisionConstants.TOKEN_VALUE_STATE;
    if ( submitFlag )
    {
      errorList
        = utils.requiredCheck(
            errorList
           ,installRow.getState()
           ,token1
           ,0
          );
    }
    errorList
      = utils.checkIllegalString(
          errorList
         ,installRow.getState()
         ,token1
         ,0
        );
// 2009-04-27 [ST障害T1_0708] Add Start
    if ( ! isDoubleByte(
             txn
            ,installRow.getState()
           )
       )
    {
      OAException error
        = XxcsoMessage.createErrorMessage(
            XxcsoConstants.APP_XXCSO1_00565
           ,XxcsoConstants.TOKEN_REGION
           ,XxcsoSpDecisionConstants.TOKEN_VALUE_INSTALL_REGION
           ,XxcsoConstants.TOKEN_COLUMN
           ,XxcsoSpDecisionConstants.TOKEN_VALUE_STATE
          );
      errorList.add(error);
    }
// 2009-04-27 [ST障害T1_0708] Add End

    /////////////////////////////////////
    // 設置先：市・区
    /////////////////////////////////////
    token1 = XxcsoSpDecisionConstants.TOKEN_VALUE_INSTALL_REGION
            + XxcsoConstants.TOKEN_VALUE_DELIMITER1
            + XxcsoSpDecisionConstants.TOKEN_VALUE_CITY;
    if ( submitFlag )
    {
      errorList
        = utils.requiredCheck(
            errorList
           ,installRow.getCity()
           ,token1
           ,0
          );
    }
    errorList
      = utils.checkIllegalString(
          errorList
         ,installRow.getCity()
         ,token1
         ,0
        );
// 2009-04-27 [ST障害T1_0708] Add Start
    if ( ! isDoubleByte(
             txn
            ,installRow.getCity()
           )
       )
    {
      OAException error
        = XxcsoMessage.createErrorMessage(
            XxcsoConstants.APP_XXCSO1_00565
           ,XxcsoConstants.TOKEN_REGION
           ,XxcsoSpDecisionConstants.TOKEN_VALUE_INSTALL_REGION
           ,XxcsoConstants.TOKEN_COLUMN
           ,XxcsoSpDecisionConstants.TOKEN_VALUE_CITY
          );
      errorList.add(error);
    }
// 2009-04-27 [ST障害T1_0708] Add End

    /////////////////////////////////////
    // 設置先：住所1
    /////////////////////////////////////
    token1 = XxcsoSpDecisionConstants.TOKEN_VALUE_INSTALL_REGION
            + XxcsoConstants.TOKEN_VALUE_DELIMITER1
            + XxcsoSpDecisionConstants.TOKEN_VALUE_ADDRESS1;
    if ( submitFlag )
    {
      errorList
        = utils.requiredCheck(
            errorList
           ,installRow.getAddress1()
           ,token1
           ,0
          );
    }
    errorList
      = utils.checkIllegalString(
          errorList
         ,installRow.getAddress1()
         ,token1
         ,0
        );
// 2009-04-27 [ST障害T1_0708] Add Start
    if ( ! isDoubleByte(
             txn
            ,installRow.getAddress1()
           )
       )
    {
      OAException error
        = XxcsoMessage.createErrorMessage(
            XxcsoConstants.APP_XXCSO1_00565
           ,XxcsoConstants.TOKEN_REGION
           ,XxcsoSpDecisionConstants.TOKEN_VALUE_INSTALL_REGION
           ,XxcsoConstants.TOKEN_COLUMN
           ,XxcsoSpDecisionConstants.TOKEN_VALUE_ADDRESS1
          );
      errorList.add(error);
    }
// 2009-04-27 [ST障害T1_0708] Add End

    /////////////////////////////////////
    // 設置先：住所2
    /////////////////////////////////////
    token1 = XxcsoSpDecisionConstants.TOKEN_VALUE_INSTALL_REGION
            + XxcsoConstants.TOKEN_VALUE_DELIMITER1
            + XxcsoSpDecisionConstants.TOKEN_VALUE_ADDRESS2;
    errorList
      = utils.checkIllegalString(
          errorList
         ,installRow.getAddress2()
         ,token1
         ,0
        );
// 2009-04-27 [ST障害T1_0708] Add Start
    if ( ! isDoubleByte(
             txn
            ,installRow.getAddress2()
           )
       )
    {
      OAException error
        = XxcsoMessage.createErrorMessage(
            XxcsoConstants.APP_XXCSO1_00565
           ,XxcsoConstants.TOKEN_REGION
           ,XxcsoSpDecisionConstants.TOKEN_VALUE_INSTALL_REGION
           ,XxcsoConstants.TOKEN_COLUMN
           ,XxcsoSpDecisionConstants.TOKEN_VALUE_ADDRESS2
          );
      errorList.add(error);
    }
// 2009-04-27 [ST障害T1_0708] Add End

    /////////////////////////////////////
    // 設置先：電話番号
    /////////////////////////////////////
// 2009-11-29 [E_本稼動_00106] Add Start
    token1 = XxcsoSpDecisionConstants.TOKEN_VALUE_INSTALL_REGION
            + XxcsoConstants.TOKEN_VALUE_DELIMITER1
            + XxcsoSpDecisionConstants.TOKEN_VALUE_ADDRESS_LINIE;
    if ( submitFlag )
    {
      errorList
        = utils.requiredCheck(
            errorList
           ,installRow.getAddressLinesPhonetic()
           ,token1
           ,0
          );
    }
// 2009-11-29 [E_本稼動_00106] Add End
    if ( ! utils.isTelNumber(installRow.getAddressLinesPhonetic()) )
    {
      OAException error
        = XxcsoMessage.createErrorMessage(
            XxcsoConstants.APP_XXCSO1_00288
           ,XxcsoConstants.TOKEN_REGION
           ,XxcsoSpDecisionConstants.TOKEN_VALUE_INSTALL_REGION
          );
      errorList.add(error);
    }

    /////////////////////////////////////
    // 設置先：業態（小分類）
    /////////////////////////////////////
    token1 = XxcsoSpDecisionConstants.TOKEN_VALUE_INSTALL_REGION
            + XxcsoConstants.TOKEN_VALUE_DELIMITER1
            + XxcsoSpDecisionConstants.TOKEN_VALUE_BUSINESS_CONDITION;
    if ( submitFlag )
    {
      errorList
        = utils.requiredCheck(
            errorList
           ,installRow.getBusinessConditionType()
           ,token1
           ,0
          );
    }
    
    /////////////////////////////////////
    // 設置先：業種
    /////////////////////////////////////
    token1 = XxcsoSpDecisionConstants.TOKEN_VALUE_INSTALL_REGION
            + XxcsoConstants.TOKEN_VALUE_DELIMITER1
            + XxcsoSpDecisionConstants.TOKEN_VALUE_BUSINESS_TYPE;
    if ( submitFlag )
    {
      errorList
        = utils.requiredCheck(
            errorList
           ,installRow.getBusinessType()
           ,token1
           ,0
          );
    }
    
    /////////////////////////////////////
    // 設置先：設置場所
    /////////////////////////////////////
    token1 = XxcsoSpDecisionConstants.TOKEN_VALUE_INSTALL_REGION
            + XxcsoConstants.TOKEN_VALUE_DELIMITER1
            + XxcsoSpDecisionConstants.TOKEN_VALUE_INSTALL_LOCATION;
    if ( submitFlag )
    {
      String installLocation = installRow.getInstallLocation();
      String extRefOpclType = installRow.getExternalReferenceOpclType();
      if ( installLocation == null    ||
           "".equals(installLocation) ||
           extRefOpclType == null     ||
           "".equals(extRefOpclType)
         )
      {
        OAException error
          = XxcsoMessage.createErrorMessage(
              XxcsoConstants.APP_XXCSO1_00005
             ,XxcsoConstants.TOKEN_COLUMN
             ,token1
            );
        errorList.add(error);
      }
    }
    
    /////////////////////////////////////
    // 設置先：社員数
    /////////////////////////////////////
    token1 = XxcsoSpDecisionConstants.TOKEN_VALUE_INSTALL_REGION
            + XxcsoConstants.TOKEN_VALUE_DELIMITER1
            + XxcsoSpDecisionConstants.TOKEN_VALUE_EMPLOYEES;
    errorList
      = utils.checkStringToNumber(
          errorList
         ,installRow.getEmployeeNumber()
         ,token1
         ,0
         ,7
         ,true
         ,true
         ,false
         ,0
        );
    
    /////////////////////////////////////
    // 設置先：担当拠点
    /////////////////////////////////////
    token1 = XxcsoSpDecisionConstants.TOKEN_VALUE_INSTALL_REGION
            + XxcsoConstants.TOKEN_VALUE_DELIMITER1
            + XxcsoSpDecisionConstants.TOKEN_VALUE_PUBLISHED_BASE;
    if ( submitFlag )
    {
      errorList
        = utils.requiredCheck(
            errorList
           ,installRow.getPublishBaseCode()
           ,token1
           ,0
          );
    }
    errorList
      = utils.checkIllegalString(
          errorList
         ,installRow.getPublishBaseCode()
         ,token1
         ,0
        );

    /////////////////////////////////////
    // 設置先：設置日
    /////////////////////////////////////
    if ( submitFlag )
    {
      if ( XxcsoSpDecisionConstants.APP_TYPE_NEW.equals(applicationType) )
      {
        token1 = XxcsoSpDecisionConstants.TOKEN_VALUE_INSTALL_REGION
                + XxcsoConstants.TOKEN_VALUE_DELIMITER1
                + XxcsoSpDecisionConstants.TOKEN_VALUE_INSTALL_DATE;
        errorList
          = utils.requiredCheck(
              errorList
             ,headerRow.getInstallDate()
             ,token1
             ,0
            );
      }
    }

    /////////////////////////////////////
    // 設置先：リース仲介会社
    /////////////////////////////////////
    token1 = XxcsoSpDecisionConstants.TOKEN_VALUE_INSTALL_REGION
            + XxcsoConstants.TOKEN_VALUE_DELIMITER1
            + XxcsoSpDecisionConstants.TOKEN_VALUE_LEASE_COMP;
    errorList
      = utils.checkIllegalString(
          errorList
         ,headerRow.getLeaseCompany()
         ,token1
         ,0
        );

    XxcsoUtils.debug(txn, "[END]");

    return errorList;
  }


  
  /*****************************************************************************
   * 契約先の検証
   * @param txn         OADBTransactionインスタンス
   * @param headerVo    SP専決ヘッダ登録／更新用ビューインスタンス
   * @param cntrctVo    契約先登録／更新用ビューインスタンス
   * @param submitFlag  提出用フラグ
   * @return List       エラーリスト
   *****************************************************************************
   */
  public static List validateCntrctCust(
    OADBTransaction                     txn
   ,XxcsoSpDecisionHeaderFullVOImpl     headerVo
   ,XxcsoSpDecisionCntrctCustFullVOImpl cntrctVo
   ,boolean                             submitFlag
  )
  {
    XxcsoUtils.debug(txn, "[START]");
    
    List errorList = new ArrayList();
    String token1 = null;
    
    /////////////////////////////////////
    // 各行を取得
    /////////////////////////////////////
    XxcsoSpDecisionHeaderFullVORowImpl headerRow
      = (XxcsoSpDecisionHeaderFullVORowImpl)headerVo.first();
    XxcsoSpDecisionCntrctCustFullVORowImpl cntrctRow
      = (XxcsoSpDecisionCntrctCustFullVORowImpl)cntrctVo.first();

    XxcsoValidateUtils utils = XxcsoValidateUtils.getInstance(txn);

    /////////////////////////////////////
    // 契約先：契約先名
    /////////////////////////////////////
    token1 = XxcsoSpDecisionConstants.TOKEN_VALUE_CNTRCT_REGION
            + XxcsoConstants.TOKEN_VALUE_DELIMITER1
            + XxcsoSpDecisionConstants.TOKEN_VALUE_CNTR_PARTY_NAME;
    if ( submitFlag )
    {
      errorList
        =  utils.requiredCheck(
              errorList
            ,cntrctRow.getPartyName()
            ,token1
            ,0
           );
    }
    errorList
      = utils.checkIllegalString(
          errorList
         ,cntrctRow.getPartyName()
         ,token1
         ,0
        );
// 2009-04-27 [ST障害T1_0708] Add Start
      if ( ! isDoubleByte(
               txn
              ,cntrctRow.getPartyName()
             )
         )
      {
        OAException error
          = XxcsoMessage.createErrorMessage(
              XxcsoConstants.APP_XXCSO1_00565
             ,XxcsoConstants.TOKEN_REGION
             ,XxcsoSpDecisionConstants.TOKEN_VALUE_CNTRCT_REGION
             ,XxcsoConstants.TOKEN_COLUMN
             ,XxcsoSpDecisionConstants.TOKEN_VALUE_CNTR_PARTY_NAME
            );
        errorList.add(error);
      }
// 2009-04-27 [ST障害T1_0708] Add End

    /////////////////////////////////////
    // 契約先：契約先名カナ
    /////////////////////////////////////
    token1 = XxcsoSpDecisionConstants.TOKEN_VALUE_CNTRCT_REGION
            + XxcsoConstants.TOKEN_VALUE_DELIMITER1
            + XxcsoSpDecisionConstants.TOKEN_VALUE_CNTR_PARTY_NAME_ALT;
    errorList
      = utils.checkIllegalString(
          errorList
         ,cntrctRow.getPartyNameAlt()
         ,token1
         ,0
        );
// 2009-04-27 [ST障害T1_0708] Mod Start
//    if ( ! isDoubleByteKana(
//             txn
//            ,cntrctRow.getPartyNameAlt()
//           )
//       )
//    {
//      OAException error
//        = XxcsoMessage.createErrorMessage(
//            XxcsoConstants.APP_XXCSO1_00286
//           ,XxcsoConstants.TOKEN_REGION
//           ,XxcsoSpDecisionConstants.TOKEN_VALUE_CNTRCT_REGION
//           ,XxcsoConstants.TOKEN_COLUMN
//           ,XxcsoSpDecisionConstants.TOKEN_VALUE_CNTR_PARTY_NAME_ALT
//          );
//      errorList.add(error);
//    }
      // 半角カナチェック
      if ( ! isSingleByteKana(
               txn
              ,cntrctRow.getPartyNameAlt()
             )
         )
      {
        OAException error
          = XxcsoMessage.createErrorMessage(
// 2009-06-08 [ST障害T1_1307] Mod Start
//            XxcsoConstants.APP_XXCSO1_00533
            XxcsoConstants.APP_XXCSO1_00573
// 2009-06-08 [ST障害T1_1307] Mod End
             ,XxcsoConstants.TOKEN_REGION
             ,XxcsoSpDecisionConstants.TOKEN_VALUE_CNTRCT_REGION
             ,XxcsoConstants.TOKEN_COLUMN
             ,XxcsoSpDecisionConstants.TOKEN_VALUE_CNTR_PARTY_NAME_ALT
            );
        errorList.add(error);
      }
// 2009-04-27 [ST障害T1_0708] Mod End

    /////////////////////////////////////
    // 契約先：郵便番号
    /////////////////////////////////////
    token1 = XxcsoSpDecisionConstants.TOKEN_VALUE_CNTRCT_REGION
            + XxcsoConstants.TOKEN_VALUE_DELIMITER1
            + XxcsoSpDecisionConstants.TOKEN_VALUE_POSTAL_CODE;
    if ( submitFlag )
    {
      if ( cntrctRow.getPostalCodeFirst() == null             ||
           "".equals(cntrctRow.getPostalCodeFirst().trim())   ||
           cntrctRow.getPostalCodeSecond() == null            ||
           "".equals(cntrctRow.getPostalCodeSecond().trim())
         )
      {
        OAException error
          = XxcsoMessage.createErrorMessage(
              XxcsoConstants.APP_XXCSO1_00005
             ,XxcsoConstants.TOKEN_COLUMN
             ,token1
            );
        errorList.add(error);
      }

      if ( ! isPostalCode(
               txn
              ,cntrctRow.getPostalCodeFirst()
              ,cntrctRow.getPostalCodeSecond()
             )
         )
      {
        token1 = XxcsoSpDecisionConstants.TOKEN_VALUE_CNTRCT_REGION;
        OAException error
          = XxcsoMessage.createErrorMessage(
              XxcsoConstants.APP_XXCSO1_00287
             ,XxcsoConstants.TOKEN_REGION
             ,token1
            );
        errorList.add(error);
      }
    }

    /////////////////////////////////////
    // 契約先：都道府県
    /////////////////////////////////////
    token1 = XxcsoSpDecisionConstants.TOKEN_VALUE_CNTRCT_REGION
            + XxcsoConstants.TOKEN_VALUE_DELIMITER1
            + XxcsoSpDecisionConstants.TOKEN_VALUE_STATE;
    if ( submitFlag )
    {
      errorList
        = utils.requiredCheck(
            errorList
           ,cntrctRow.getState()
           ,token1
           ,0
          );
    }
    errorList
      = utils.checkIllegalString(
          errorList
         ,cntrctRow.getState()
         ,token1
         ,0
        );
// 2009-04-27 [ST障害T1_0708] Add Start
      if ( ! isDoubleByte(
               txn
              ,cntrctRow.getState()
             )
         )
      {
        OAException error
          = XxcsoMessage.createErrorMessage(
              XxcsoConstants.APP_XXCSO1_00565
             ,XxcsoConstants.TOKEN_REGION
             ,XxcsoSpDecisionConstants.TOKEN_VALUE_CNTRCT_REGION
             ,XxcsoConstants.TOKEN_COLUMN
             ,XxcsoSpDecisionConstants.TOKEN_VALUE_STATE
            );
        errorList.add(error);
      }
// 2009-04-27 [ST障害T1_0708] Add End

    /////////////////////////////////////
    // 契約先：市・区
    /////////////////////////////////////
    token1 = XxcsoSpDecisionConstants.TOKEN_VALUE_CNTRCT_REGION
            + XxcsoConstants.TOKEN_VALUE_DELIMITER1
            + XxcsoSpDecisionConstants.TOKEN_VALUE_CITY;
    if ( submitFlag )
    {
      errorList
        = utils.requiredCheck(
            errorList
           ,cntrctRow.getCity()
           ,token1
           ,0
          );
    }
    errorList
      = utils.checkIllegalString(
          errorList
         ,cntrctRow.getCity()
         ,token1
         ,0
        );
// 2009-04-27 [ST障害T1_0708] Add Start
      if ( ! isDoubleByte(
               txn
              ,cntrctRow.getCity()
             )
         )
      {
        OAException error
          = XxcsoMessage.createErrorMessage(
              XxcsoConstants.APP_XXCSO1_00565
             ,XxcsoConstants.TOKEN_REGION
             ,XxcsoSpDecisionConstants.TOKEN_VALUE_CNTRCT_REGION
             ,XxcsoConstants.TOKEN_COLUMN
             ,XxcsoSpDecisionConstants.TOKEN_VALUE_CITY
            );
        errorList.add(error);
      }
// 2009-04-27 [ST障害T1_0708] Add End

    /////////////////////////////////////
    // 契約先：住所1
    /////////////////////////////////////
    token1 = XxcsoSpDecisionConstants.TOKEN_VALUE_CNTRCT_REGION
            + XxcsoConstants.TOKEN_VALUE_DELIMITER1
            + XxcsoSpDecisionConstants.TOKEN_VALUE_ADDRESS1;
    if ( submitFlag )
    {
      errorList
        = utils.requiredCheck(
            errorList
           ,cntrctRow.getAddress1()
           ,token1
           ,0
          );
    }
    errorList
      = utils.checkIllegalString(
          errorList
         ,cntrctRow.getAddress1()
         ,token1
         ,0
        );
// 2009-04-27 [ST障害T1_0708] Add Start
      if ( ! isDoubleByte(
               txn
              ,cntrctRow.getAddress1()
             )
         )
      {
        OAException error
          = XxcsoMessage.createErrorMessage(
              XxcsoConstants.APP_XXCSO1_00565
             ,XxcsoConstants.TOKEN_REGION
             ,XxcsoSpDecisionConstants.TOKEN_VALUE_CNTRCT_REGION
             ,XxcsoConstants.TOKEN_COLUMN
             ,XxcsoSpDecisionConstants.TOKEN_VALUE_ADDRESS1
            );
        errorList.add(error);
      }
// 2009-04-27 [ST障害T1_0708] Add End

    /////////////////////////////////////
    // 契約先：住所2
    /////////////////////////////////////
    token1 = XxcsoSpDecisionConstants.TOKEN_VALUE_CNTRCT_REGION
            + XxcsoConstants.TOKEN_VALUE_DELIMITER1
            + XxcsoSpDecisionConstants.TOKEN_VALUE_ADDRESS2;
    errorList
      = utils.checkIllegalString(
          errorList
         ,cntrctRow.getAddress2()
         ,token1
         ,0
        );
// 2009-04-27 [ST障害T1_0708] Add Start
      if ( ! isDoubleByte(
               txn
              ,cntrctRow.getAddress2()
             )
         )
      {
        OAException error
          = XxcsoMessage.createErrorMessage(
              XxcsoConstants.APP_XXCSO1_00565
             ,XxcsoConstants.TOKEN_REGION
             ,XxcsoSpDecisionConstants.TOKEN_VALUE_CNTRCT_REGION
             ,XxcsoConstants.TOKEN_COLUMN
             ,XxcsoSpDecisionConstants.TOKEN_VALUE_ADDRESS2
            );
        errorList.add(error);
      }
// 2009-04-27 [ST障害T1_0708] Add End

    /////////////////////////////////////
    // 契約先：電話番号
    /////////////////////////////////////
    if ( ! utils.isTelNumber(cntrctRow.getAddressLinesPhonetic()) )
    {
      OAException error
        = XxcsoMessage.createErrorMessage(
            XxcsoConstants.APP_XXCSO1_00288
           ,XxcsoConstants.TOKEN_REGION
           ,XxcsoSpDecisionConstants.TOKEN_VALUE_CNTRCT_REGION
          );
      errorList.add(error);
    }

    /////////////////////////////////////
    // 契約先：代表者名
    /////////////////////////////////////
    token1 = XxcsoSpDecisionConstants.TOKEN_VALUE_CNTRCT_REGION
            + XxcsoConstants.TOKEN_VALUE_DELIMITER1
            + XxcsoSpDecisionConstants.TOKEN_VALUE_DELEGATE;
    errorList
      = utils.checkIllegalString(
          errorList
         ,cntrctRow.getRepresentativeName()
         ,token1
         ,0
        );
// 2009-04-27 [ST障害T1_0708] Add Start
      if ( ! isDoubleByte(
               txn
              ,cntrctRow.getRepresentativeName()
             )
         )
      {
        OAException error
          = XxcsoMessage.createErrorMessage(
              XxcsoConstants.APP_XXCSO1_00565
             ,XxcsoConstants.TOKEN_REGION
             ,XxcsoSpDecisionConstants.TOKEN_VALUE_CNTRCT_REGION
             ,XxcsoConstants.TOKEN_COLUMN
             ,XxcsoSpDecisionConstants.TOKEN_VALUE_DELEGATE
            );
        errorList.add(error);
      }
// 2009-04-27 [ST障害T1_0708] Add End

    XxcsoUtils.debug(txn, "[END]");

    return errorList;
  }


  
// 2016-01-07 [E_本稼動_13456] Del Start
//  /*****************************************************************************
//   * VD情報の検証
//   * @param txn         OADBTransactionインスタンス
//   * @param headerVo    SP専決ヘッダ登録／更新用ビューインスタンス
//   * @param submitFlag  提出用フラグ
//   * @return List       エラーリスト
//   *****************************************************************************
//   */
//  public static List validateVdInfo(
//    OADBTransaction                     txn
//   ,XxcsoSpDecisionHeaderFullVOImpl     headerVo
//   ,boolean                             submitFlag
//  )
//  {
//    XxcsoUtils.debug(txn, "[START]");
//    
//    List errorList = new ArrayList();
//    String token1 = null;
//    
//    /////////////////////////////////////
//    // 各行を取得
//    /////////////////////////////////////
//    XxcsoSpDecisionHeaderFullVORowImpl headerRow
//      = (XxcsoSpDecisionHeaderFullVORowImpl)headerVo.first();
//
//    XxcsoValidateUtils utils = XxcsoValidateUtils.getInstance(txn);
//
//    String newoldType = headerRow.getNewoldType();
//    
//    /////////////////////////////////////
//    // VD情報：新／旧
//    /////////////////////////////////////
//    token1 = XxcsoSpDecisionConstants.TOKEN_VALUE_VD_INFO_REGION
//            + XxcsoConstants.TOKEN_VALUE_DELIMITER1
//            + XxcsoSpDecisionConstants.TOKEN_VALUE_NEW_OLD;
//
//    if ( submitFlag )
//    {
//      errorList
//        = utils.requiredCheck(
//            errorList
//           ,headerRow.getNewoldType()
//           ,token1
//           ,0
//          );
//    }
//
//    /////////////////////////////////////
//    // VD情報：セレ数
//    /////////////////////////////////////
//    token1 = XxcsoSpDecisionConstants.TOKEN_VALUE_VD_INFO_REGION
//            + XxcsoConstants.TOKEN_VALUE_DELIMITER1
//            + XxcsoSpDecisionConstants.TOKEN_VALUE_SELE_NUMBER;
//    errorList
//      = utils.checkStringToNumber(
//          errorList
//         ,headerRow.getSeleNumber()
//         ,token1
//         ,0
//         ,3
//         ,true
//         ,true
//
//         ,submitFlag
//         ,0
//        );
//
//    /////////////////////////////////////
//    // VD情報：メーカー名
//    /////////////////////////////////////
//    token1 = XxcsoSpDecisionConstants.TOKEN_VALUE_VD_INFO_REGION
//            + XxcsoConstants.TOKEN_VALUE_DELIMITER1
//            + XxcsoSpDecisionConstants.TOKEN_VALUE_MAKER_NAME;
//
//    if ( submitFlag )
//    {
//      errorList
//        = utils.requiredCheck(
//            errorList
//           ,headerRow.getMakerCode()
//           ,token1
//           ,0
//          );
//    }
//
//    /////////////////////////////////////
//    // VD情報：規格内／外
//    /////////////////////////////////////
//    token1 = XxcsoSpDecisionConstants.TOKEN_VALUE_VD_INFO_REGION
//            + XxcsoConstants.TOKEN_VALUE_DELIMITER1
//            + XxcsoSpDecisionConstants.TOKEN_VALUE_STD_TYPE;
//
//    if ( submitFlag )
//    {
//      errorList
//        = utils.requiredCheck(
//            errorList
//           ,headerRow.getStandardType()
//           ,token1
//           ,0
//          );
//    }
//
//    /////////////////////////////////////
//    // VD情報：機種コード
//    /////////////////////////////////////
//    if ( submitFlag )
//    {
//      if ( XxcsoSpDecisionConstants.NEW_OLD_NEW.equals(newoldType) )
//      {
//        token1 = XxcsoSpDecisionConstants.TOKEN_VALUE_VD_INFO_REGION
//                + XxcsoConstants.TOKEN_VALUE_DELIMITER1
//                + XxcsoSpDecisionConstants.TOKEN_VALUE_VENDOR_MODEL;
//        errorList
//          = utils.requiredCheck(
//              errorList
//             ,headerRow.getUnNumber()
//             ,token1
//             ,0
//            );
//      }
//    }
//    
//    XxcsoUtils.debug(txn, "[END]");
//
//    return errorList;
//  }
// 2016-01-07 [E_本稼動_13456] Del End

  
  /*****************************************************************************
   * その他条件の検証
   * @param txn         OADBTransactionインスタンス
   * @param headerVo    SP専決ヘッダ登録／更新用ビューインスタンス
   * @param submitFlag  提出用フラグ
   * @param installVo   設置先登録／更新用ビューインスタンス
   * @return List       エラーリスト
   *****************************************************************************
   */
  public static List validateOtherCondition(
    OADBTransaction                     txn
   ,XxcsoSpDecisionHeaderFullVOImpl     headerVo
   ,boolean                             submitFlag
// 2018-05-16 [E_本稼動_14989] Add Start
   ,XxcsoSpDecisionInstCustFullVOImpl   installVo
// 2018-05-16 [E_本稼動_14989] Add End
  )
  {
    XxcsoUtils.debug(txn, "[START]");
    
    List errorList = new ArrayList();
    String token1 = null;
    
    /////////////////////////////////////
    // 各行を取得
    /////////////////////////////////////
    XxcsoSpDecisionHeaderFullVORowImpl headerRow
      = (XxcsoSpDecisionHeaderFullVORowImpl)headerVo.first();

    XxcsoValidateUtils utils = XxcsoValidateUtils.getInstance(txn);

    String electricityType = headerRow.getElectricityType();

    /////////////////////////////////////
    // その他条件：契約年数
    /////////////////////////////////////
    token1 = XxcsoSpDecisionConstants.TOKEN_VALUE_OTHER_COND_REGION
            + XxcsoConstants.TOKEN_VALUE_DELIMITER1
            + XxcsoSpDecisionConstants.TOKEN_VALUE_CONTRACT_YEAR;
    errorList
      = utils.checkStringToNumber(
          errorList
         ,headerRow.getContractYearDate()
         ,token1
         ,0
         ,2
         ,true
// 2014-12-15 [E_本稼動_12565] Mod Start
//         ,true
         ,false
// 2014-12-15 [E_本稼動_12565] Mod End
         ,submitFlag
         ,0
        );
// 2014-12-15 [E_本稼動_12565] Del Start
//    /////////////////////////////////////
//    // その他条件：初回設置協賛金
//    /////////////////////////////////////
//    token1 = XxcsoSpDecisionConstants.TOKEN_VALUE_OTHER_COND_REGION
//            + XxcsoConstants.TOKEN_VALUE_DELIMITER1
//            + XxcsoSpDecisionConstants.TOKEN_VALUE_INST_SUP_AMT;
//    errorList
//      = utils.checkStringToNumber(
//          errorList
//         ,headerRow.getInstallSupportAmt()
//         ,token1
//         ,0
//         ,8
//         ,true
//         ,false
//         ,false
//         ,0
//        );

//    /////////////////////////////////////
//    // その他条件：2回目以降設置協賛金
//    /////////////////////////////////////
//    token1 = XxcsoSpDecisionConstants.TOKEN_VALUE_OTHER_COND_REGION
//            + XxcsoConstants.TOKEN_VALUE_DELIMITER1
//            + XxcsoSpDecisionConstants.TOKEN_VALUE_INST_SUP_AMT2;
//    errorList
//      = utils.checkStringToNumber(
//          errorList
//         ,headerRow.getInstallSupportAmt2()
//         ,token1
//         ,0
//         ,8
//         ,true
//         ,false
//         ,false
//         ,0
//        );

//    /////////////////////////////////////
//    // その他条件：支払サイクル
//    /////////////////////////////////////
//    token1 = XxcsoSpDecisionConstants.TOKEN_VALUE_OTHER_COND_REGION
//            + XxcsoConstants.TOKEN_VALUE_DELIMITER1
//            + XxcsoSpDecisionConstants.TOKEN_VALUE_PAYMENT_CYCLE;
//    errorList
//      = utils.checkStringToNumber(
//          errorList
//         ,headerRow.getPaymentCycle()
//         ,token1
//         ,0
//         ,2
//         ,true
//         ,false
//         ,false
//         ,0
//        );
    
//    /////////////////////////////////////
//    // その他条件：電気代
//    /////////////////////////////////////
//    boolean requiredFlag = false;
//// 2009-03-23 [ST障害T1_0163] Add Start
//    boolean zeroCheckFlag = false;
//// 2009-03-23 [ST障害T1_0163] Add End
//    if ( XxcsoSpDecisionConstants.ELEC_FIXED.equals(electricityType) ||
//         XxcsoSpDecisionConstants.ELEC_VALIABLE.equals(electricityType)
//       )
//    {
//      requiredFlag = true;
//// 2009-03-23 [ST障害T1_0163] Add Start
//      zeroCheckFlag = true;
//// 2009-03-23 [ST障害T1_0163] Add End
//    }
//    if ( ! submitFlag )
//    {
//      requiredFlag = false;
//// 2009-03-23 [ST障害T1_0163] Add Start
//      zeroCheckFlag = false;
//// 2009-03-23 [ST障害T1_0163] Add End
//    }
//    token1 = XxcsoSpDecisionConstants.TOKEN_VALUE_OTHER_COND_REGION
//            + XxcsoConstants.TOKEN_VALUE_DELIMITER1
//            + XxcsoSpDecisionConstants.TOKEN_VALUE_ELECTRICITY_AMOUNT;
//// 2009-03-23 [ST障害T1_0163] Mod Start
////    errorList
////      = utils.checkStringToNumber(
////          errorList
////         ,headerRow.getElectricityAmount()
////         ,token1
////         ,0
////         ,5
////         ,true
////         ,false
////         ,requiredFlag
////         ,0
////        );
//    errorList
//      = utils.checkStringToNumber(
//          errorList
//         ,headerRow.getElectricityAmount()
//         ,token1
//         ,0
//         ,5
//         ,true
//         ,zeroCheckFlag
//         ,requiredFlag
//         ,0
//        );
//// 2009-03-23 [ST障害T1_0163] Mod End
// 2014-12-15 [E_本稼動_12565] Del End
// 2014-12-15 [E_本稼動_12565] Add Start
    /////////////////////////////////////
    // その他条件：契約月数
    /////////////////////////////////////
    token1 = XxcsoSpDecisionConstants.TOKEN_VALUE_OTHER_COND_REGION
            + XxcsoConstants.TOKEN_VALUE_DELIMITER1
            + XxcsoSpDecisionConstants.TOKEN_VALUE_CONTRACT_YEAR_MONTH;
    errorList
      = utils.checkStringToNumber(
          errorList
         ,headerRow.getContractYearMonth()
         ,token1
         ,0
         ,2
         ,true
         ,false
         ,submitFlag
         ,0
        );

    /////////////////////////////////////
    // その他条件：契約期間開始（年)
    /////////////////////////////////////
    token1 = XxcsoSpDecisionConstants.TOKEN_VALUE_OTHER_COND_REGION
            + XxcsoConstants.TOKEN_VALUE_DELIMITER1
            + XxcsoSpDecisionConstants.TOKEN_VALUE_CONTRACT_START_YEAR;
    errorList
      = utils.checkStringToNumber(
          errorList
         ,headerRow.getContractStartYear()
         ,token1
         ,0
         ,4
         ,true
         ,true
         ,submitFlag
         ,0
        );

    /////////////////////////////////////
    // その他条件：契約期間開始（月)
    /////////////////////////////////////
    token1 = XxcsoSpDecisionConstants.TOKEN_VALUE_OTHER_COND_REGION
            + XxcsoConstants.TOKEN_VALUE_DELIMITER1
            + XxcsoSpDecisionConstants.TOKEN_VALUE_CONTRACT_START_MONTH;
    errorList
      = utils.checkStringToNumber(
          errorList
         ,headerRow.getContractStartMonth()
         ,token1
         ,0
         ,2
         ,true
         ,true
         ,submitFlag
         ,0
        );

    /////////////////////////////////////
    // その他条件：契約期間終了（年)
    /////////////////////////////////////
    token1 = XxcsoSpDecisionConstants.TOKEN_VALUE_OTHER_COND_REGION
            + XxcsoConstants.TOKEN_VALUE_DELIMITER1
            + XxcsoSpDecisionConstants.TOKEN_VALUE_CONTRACT_END_YEAR;
    errorList
      = utils.checkStringToNumber(
          errorList
         ,headerRow.getContractEndYear()
         ,token1
         ,0
         ,4
         ,true
         ,true
         ,submitFlag
         ,0
        );

    /////////////////////////////////////
    // その他条件：契約期間終了（月)
    /////////////////////////////////////
    token1 = XxcsoSpDecisionConstants.TOKEN_VALUE_OTHER_COND_REGION
            + XxcsoConstants.TOKEN_VALUE_DELIMITER1
            + XxcsoSpDecisionConstants.TOKEN_VALUE_CONTRACT_END_MONTHR;
    errorList
      = utils.checkStringToNumber(
          errorList
         ,headerRow.getContractEndMonth()
         ,token1
         ,0
         ,2
         ,true
         ,true
         ,submitFlag
         ,0
        );

    /////////////////////////////////////
    // その他条件：契約年数と契約期間の整合性
    /////////////////////////////////////
    if ( ( submitFlag ) && ( errorList.size() == 0 ) )
    {
      // 契約月数が11以下であるかチェック
      token1 = XxcsoSpDecisionConstants.TOKEN_VALUE_OTHER_COND_REGION
              + XxcsoConstants.TOKEN_VALUE_DELIMITER1
              + XxcsoSpDecisionConstants.TOKEN_VALUE_CONTRACT_YEAR_MONTH;

      int contractYear      = Integer.valueOf( headerRow.getContractYearDate() ).intValue();
      int contractYearMonth = Integer.valueOf( headerRow.getContractYearMonth() ).intValue();
      int culYearMonth      = contractYear + contractYearMonth;

      if ( contractYearMonth > 11 )
      {
        errorList.add(
            XxcsoMessage.createErrorMessage(
              XxcsoConstants.APP_XXCSO1_00718
             ,XxcsoConstants.TOKEN_COLUMN
             ,token1
            )
        );
      }

      // 契約年数と契約月数をあわせて0であるかチェック
      token1 = XxcsoSpDecisionConstants.TOKEN_VALUE_CONTRACT_YEAR;

      if ( culYearMonth == 0 )
      {
        errorList.add(
            XxcsoMessage.createErrorMessage(
              XxcsoConstants.APP_XXCSO1_00730
             ,XxcsoConstants.TOKEN_COLUMN
             ,token1
            )
        );
      }

      // 契約期間開始（年）が西暦であるかチェック
      token1 = XxcsoSpDecisionConstants.TOKEN_VALUE_OTHER_COND_REGION
              + XxcsoConstants.TOKEN_VALUE_DELIMITER1
              + XxcsoSpDecisionConstants.TOKEN_VALUE_CONTRACT_START_YEAR;

      if ( ! isYear( headerRow.getContractStartYear() ) )
      {
        errorList.add(
            XxcsoMessage.createErrorMessage(
              XxcsoConstants.APP_XXCSO1_00720
             ,XxcsoConstants.TOKEN_COLUMN
             ,token1
            )
        );
      }

      // 契約期間開始（月）が12以下であるかチェック
      token1 = XxcsoSpDecisionConstants.TOKEN_VALUE_OTHER_COND_REGION
              + XxcsoConstants.TOKEN_VALUE_DELIMITER1
              + XxcsoSpDecisionConstants.TOKEN_VALUE_CONTRACT_START_MONTH;

      if ( ! isMonth( headerRow.getContractStartMonth() ) )
      {
        errorList.add(
            XxcsoMessage.createErrorMessage(
              XxcsoConstants.APP_XXCSO1_00719
             ,XxcsoConstants.TOKEN_COLUMN
             ,token1
            )
        );
      }

      // 契約期間終了（年）が西暦であるかチェック
      token1 = XxcsoSpDecisionConstants.TOKEN_VALUE_OTHER_COND_REGION
              + XxcsoConstants.TOKEN_VALUE_DELIMITER1
              + XxcsoSpDecisionConstants.TOKEN_VALUE_CONTRACT_END_YEAR;

      if ( ! isYear( headerRow.getContractEndYear() ) )
      {
        errorList.add(
            XxcsoMessage.createErrorMessage(
              XxcsoConstants.APP_XXCSO1_00720
             ,XxcsoConstants.TOKEN_COLUMN
             ,token1
            )
        );
      }

      // 契約期間終了（月）が12以下であるかチェック
      token1 = XxcsoSpDecisionConstants.TOKEN_VALUE_OTHER_COND_REGION
              + XxcsoConstants.TOKEN_VALUE_DELIMITER1
              + XxcsoSpDecisionConstants.TOKEN_VALUE_CONTRACT_END_MONTHR;

      if ( ! isMonth( headerRow.getContractEndMonth() ) )
      {
        errorList.add(
            XxcsoMessage.createErrorMessage(
              XxcsoConstants.APP_XXCSO1_00719
             ,XxcsoConstants.TOKEN_COLUMN
             ,token1
            )
        );
      }

      if ( errorList.size() == 0 )
      {
        // 契約年月と契約開始、終了の整合性チェック
        String contractEnd = validateContractEnd(
                              txn
                             ,headerRow.getContractYearDate()
                             ,headerRow.getContractYearMonth()
                             ,headerRow.getContractStartYear()
                             ,headerRow.getContractStartMonth()
                             ,headerRow.getContractEndYear()
                             ,headerRow.getContractEndMonth()
                            );

        if ( ! "0".equals(contractEnd) )
        {
          errorList.add(
              XxcsoMessage.createErrorMessage(
               XxcsoConstants.APP_XXCSO1_00721
               ,XxcsoConstants.TOKEN_RESULTS
               ,contractEnd
              )
          );
        }
      }
    }
// 2018-05-16 [E_本稼動_14989] Add Start

    XxcsoSpDecisionInstCustFullVORowImpl installRow
      = (XxcsoSpDecisionInstCustFullVORowImpl)installVo.first();

    //工期、設置見込み期間必須フラグ取得
    boolean requiredCheckFlag = getRequiredCheckFlag(
                                 txn
                                ,installRow.getBusinessType()
                                ,installRow.getBusinessConditionType()
                                );

    /////////////////////////////////////
    // その他条件：工期開始（年)
    /////////////////////////////////////
    token1 = XxcsoSpDecisionConstants.TOKEN_VALUE_OTHER_COND_REGION
            + XxcsoConstants.TOKEN_VALUE_DELIMITER1
            + XxcsoSpDecisionConstants.TOKEN_VALUE_CONSTRUCTION_START_YEAR;
    errorList
      = utils.checkStringToNumber(
          errorList
         ,headerRow.getConstructionStartYear()
         ,token1
         ,0
         ,4
         ,true
         ,true
         ,requiredCheckFlag
         ,0
        );

    /////////////////////////////////////
    // その他条件：工期開始（月)
    /////////////////////////////////////
    token1 = XxcsoSpDecisionConstants.TOKEN_VALUE_OTHER_COND_REGION
            + XxcsoConstants.TOKEN_VALUE_DELIMITER1
            + XxcsoSpDecisionConstants.TOKEN_VALUE_CONSTRUCTION_START_MONTH;
    errorList
      = utils.checkStringToNumber(
          errorList
         ,headerRow.getConstructionStartMonth()
         ,token1
         ,0
         ,2
         ,true
         ,true
         ,requiredCheckFlag
         ,0
        );

    /////////////////////////////////////
    // その他条件：工期終了（年)
    /////////////////////////////////////
    token1 = XxcsoSpDecisionConstants.TOKEN_VALUE_OTHER_COND_REGION
            + XxcsoConstants.TOKEN_VALUE_DELIMITER1
            + XxcsoSpDecisionConstants.TOKEN_VALUE_CONSTRUCTION_END_YEAR;
    errorList
      = utils.checkStringToNumber(
          errorList
         ,headerRow.getConstructionEndYear()
         ,token1
         ,0
         ,4
         ,true
         ,true
         ,requiredCheckFlag
         ,0
        );

    /////////////////////////////////////
    // その他条件：工期終了（月)
    /////////////////////////////////////
    token1 = XxcsoSpDecisionConstants.TOKEN_VALUE_OTHER_COND_REGION
            + XxcsoConstants.TOKEN_VALUE_DELIMITER1
            + XxcsoSpDecisionConstants.TOKEN_VALUE_CONSTRUCTION_END_MONTHR;
    errorList
      = utils.checkStringToNumber(
          errorList
         ,headerRow.getConstructionEndMonth()
         ,token1
         ,0
         ,2
         ,true
         ,true
         ,requiredCheckFlag
         ,0
        );

    /////////////////////////////////////
    // その他条件：工期の整合性
    /////////////////////////////////////
    if ( ( submitFlag ) && ( errorList.size() == 0 ) )
    {
      // 工期開始（年）が西暦であるかチェック
      token1 = XxcsoSpDecisionConstants.TOKEN_VALUE_OTHER_COND_REGION
              + XxcsoConstants.TOKEN_VALUE_DELIMITER1
              + XxcsoSpDecisionConstants.TOKEN_VALUE_CONSTRUCTION_START_YEAR;

      if ( ! isYear( headerRow.getConstructionStartYear() ) )
      {
        errorList.add(
            XxcsoMessage.createErrorMessage(
              XxcsoConstants.APP_XXCSO1_00720
             ,XxcsoConstants.TOKEN_COLUMN
             ,token1
            )
        );
      }

      // 工期開始（月）が12以下であるかチェック
      token1 = XxcsoSpDecisionConstants.TOKEN_VALUE_OTHER_COND_REGION
              + XxcsoConstants.TOKEN_VALUE_DELIMITER1
              + XxcsoSpDecisionConstants.TOKEN_VALUE_CONSTRUCTION_START_MONTH;

      if ( ! isMonth( headerRow.getConstructionStartMonth() ) )
      {
        errorList.add(
            XxcsoMessage.createErrorMessage(
              XxcsoConstants.APP_XXCSO1_00719
             ,XxcsoConstants.TOKEN_COLUMN
             ,token1
            )
        );
      }

      // 工期終了（年）が西暦であるかチェック
      token1 = XxcsoSpDecisionConstants.TOKEN_VALUE_OTHER_COND_REGION
              + XxcsoConstants.TOKEN_VALUE_DELIMITER1
              + XxcsoSpDecisionConstants.TOKEN_VALUE_CONSTRUCTION_END_YEAR;

      if ( ! isYear( headerRow.getConstructionEndYear() ) )
      {
        errorList.add(
            XxcsoMessage.createErrorMessage(
              XxcsoConstants.APP_XXCSO1_00720
             ,XxcsoConstants.TOKEN_COLUMN
             ,token1
            )
        );
      }

      // 工期終了（月）が12以下であるかチェック
      token1 = XxcsoSpDecisionConstants.TOKEN_VALUE_OTHER_COND_REGION
              + XxcsoConstants.TOKEN_VALUE_DELIMITER1
              + XxcsoSpDecisionConstants.TOKEN_VALUE_CONSTRUCTION_END_MONTHR;

      if ( ! isMonth( headerRow.getConstructionEndMonth() ) )
      {
        errorList.add(
            XxcsoMessage.createErrorMessage(
              XxcsoConstants.APP_XXCSO1_00719
             ,XxcsoConstants.TOKEN_COLUMN
             ,token1
            )
        );
      }

      if ( errorList.size() == 0 )
      {
        token1 = XxcsoSpDecisionConstants.TOKEN_VALUE_OTHER_COND_REGION
                + XxcsoConstants.TOKEN_VALUE_DELIMITER1
                + XxcsoSpDecisionConstants.TOKEN_VALUE_CONSTRUCTION_PERIOD;

        // 工期開始、終了の整合性チェック
        // 開始(年)が未入力で、開始(月)、終了(年)、終了(月)のいずれかが入力
        if ( ( headerRow.getConstructionStartYear()    == null
            && ( headerRow.getConstructionStartMonth() != null
              || headerRow.getConstructionEndYear()    != null
              || headerRow.getConstructionEndMonth()   != null ) )
          //または、開始(年)が入力で、開始(月)、終了(年)、終了(月)のいずれかが未入力
          || ( headerRow.getConstructionStartYear()    != null
            && ( headerRow.getConstructionStartMonth() == null
              || headerRow.getConstructionEndYear()    == null
              || headerRow.getConstructionEndMonth()   == null ) ) )
        {
          errorList.add(
              XxcsoMessage.createErrorMessage(
               XxcsoConstants.APP_XXCSO1_00878
               ,XxcsoConstants.TOKEN_COLUMN
               ,token1
              )
          );
        }
      }

      if ( errorList.size() == 0 )
      {
        if ( headerRow.getConstructionStartYear() != null )
        {
          int constructionStartYear  = Integer.valueOf( headerRow.getConstructionStartYear() ).intValue();
          int constructionStartMonth = Integer.valueOf( headerRow.getConstructionStartMonth() ).intValue();
          int constructionEndYear    = Integer.valueOf( headerRow.getConstructionEndYear() ).intValue();
          int constructionEndMonth   = Integer.valueOf( headerRow.getConstructionEndMonth() ).intValue();

          // 工期開始、終了の整合性チェック
          if ( constructionStartYear > constructionEndYear
            || ( constructionStartYear  == constructionEndYear
              && constructionStartMonth >  constructionEndMonth ) )
          {
            errorList.add(
                XxcsoMessage.createErrorMessage(
                 XxcsoConstants.APP_XXCSO1_00883
                 ,XxcsoConstants.TOKEN_COLUMN
                 ,token1
                )
            );
          }
        }
      }
    }

    /////////////////////////////////////
    // その他条件：設置見込み期間開始（年)
    /////////////////////////////////////
    token1 = XxcsoSpDecisionConstants.TOKEN_VALUE_OTHER_COND_REGION
            + XxcsoConstants.TOKEN_VALUE_DELIMITER1
            + XxcsoSpDecisionConstants.TOKEN_VALUE_INSTALLATION_START_YEAR;
    errorList
      = utils.checkStringToNumber(
          errorList
         ,headerRow.getInstallationStartYear()
         ,token1
         ,0
         ,4
         ,true
         ,true
         ,requiredCheckFlag
         ,0
        );

    /////////////////////////////////////
    // その他条件：設置見込み期間開始（月)
    /////////////////////////////////////
    token1 = XxcsoSpDecisionConstants.TOKEN_VALUE_OTHER_COND_REGION
            + XxcsoConstants.TOKEN_VALUE_DELIMITER1
            + XxcsoSpDecisionConstants.TOKEN_VALUE_INSTALLATION_START_MONTH;
    errorList
      = utils.checkStringToNumber(
          errorList
         ,headerRow.getInstallationStartMonth()
         ,token1
         ,0
         ,2
         ,true
         ,true
         ,requiredCheckFlag
         ,0
        );

    /////////////////////////////////////
    // その他条件：設置見込み期間終了（年)
    /////////////////////////////////////
    token1 = XxcsoSpDecisionConstants.TOKEN_VALUE_OTHER_COND_REGION
            + XxcsoConstants.TOKEN_VALUE_DELIMITER1
            + XxcsoSpDecisionConstants.TOKEN_VALUE_INSTALLATION_END_YEAR;
    errorList
      = utils.checkStringToNumber(
          errorList
         ,headerRow.getInstallationEndYear()
         ,token1
         ,0
         ,4
         ,true
         ,true
         ,requiredCheckFlag
         ,0
        );

    /////////////////////////////////////
    // その他条件：設置見込み期間終了（月)
    /////////////////////////////////////
    token1 = XxcsoSpDecisionConstants.TOKEN_VALUE_OTHER_COND_REGION
            + XxcsoConstants.TOKEN_VALUE_DELIMITER1
            + XxcsoSpDecisionConstants.TOKEN_VALUE_INSTALLATION_END_MONTH;
    errorList
      = utils.checkStringToNumber(
          errorList
         ,headerRow.getInstallationEndMonth()
         ,token1
         ,0
         ,2
         ,true
         ,true
         ,requiredCheckFlag
         ,0
        );

    /////////////////////////////////////
    // その他条件：設置見込み期間の整合性
    /////////////////////////////////////
    if ( ( submitFlag ) && ( errorList.size() == 0 ) )
    {
      // 設置見込み期間開始（年）が西暦であるかチェック
      token1 = XxcsoSpDecisionConstants.TOKEN_VALUE_OTHER_COND_REGION
              + XxcsoConstants.TOKEN_VALUE_DELIMITER1
              + XxcsoSpDecisionConstants.TOKEN_VALUE_INSTALLATION_START_YEAR;

      if ( ! isYear( headerRow.getInstallationStartYear() ) )
      {
        errorList.add(
            XxcsoMessage.createErrorMessage(
              XxcsoConstants.APP_XXCSO1_00720
             ,XxcsoConstants.TOKEN_COLUMN
             ,token1
            )
        );
      }

      // 設置見込み期間開始（月）が12以下であるかチェック
      token1 = XxcsoSpDecisionConstants.TOKEN_VALUE_OTHER_COND_REGION
              + XxcsoConstants.TOKEN_VALUE_DELIMITER1
              + XxcsoSpDecisionConstants.TOKEN_VALUE_INSTALLATION_START_MONTH;

      if ( ! isMonth( headerRow.getInstallationStartMonth() ) )
      {
        errorList.add(
            XxcsoMessage.createErrorMessage(
              XxcsoConstants.APP_XXCSO1_00719
             ,XxcsoConstants.TOKEN_COLUMN
             ,token1
            )
        );
      }

      // 設置見込み期間終了（年）が西暦であるかチェック
      token1 = XxcsoSpDecisionConstants.TOKEN_VALUE_OTHER_COND_REGION
              + XxcsoConstants.TOKEN_VALUE_DELIMITER1
              + XxcsoSpDecisionConstants.TOKEN_VALUE_INSTALLATION_END_YEAR;

      if ( ! isYear( headerRow.getInstallationEndYear() ) )
      {
        errorList.add(
            XxcsoMessage.createErrorMessage(
              XxcsoConstants.APP_XXCSO1_00720
             ,XxcsoConstants.TOKEN_COLUMN
             ,token1
            )
        );
      }

      // 設置見込み期間終了（月）が12以下であるかチェック
      token1 = XxcsoSpDecisionConstants.TOKEN_VALUE_OTHER_COND_REGION
              + XxcsoConstants.TOKEN_VALUE_DELIMITER1
              + XxcsoSpDecisionConstants.TOKEN_VALUE_INSTALLATION_END_MONTH;

      if ( ! isMonth( headerRow.getInstallationEndMonth() ) )
      {
        errorList.add(
            XxcsoMessage.createErrorMessage(
              XxcsoConstants.APP_XXCSO1_00719
             ,XxcsoConstants.TOKEN_COLUMN
             ,token1
            )
        );
      }

      if ( errorList.size() == 0 )
      {
        token1 = XxcsoSpDecisionConstants.TOKEN_VALUE_OTHER_COND_REGION
                + XxcsoConstants.TOKEN_VALUE_DELIMITER1
                + XxcsoSpDecisionConstants.TOKEN_VALUE_INSTALLATION_PERIOD;
        // 設置見込み期間開始、設置見込み期間の整合性チェック
        // 開始(年)が未入力で、開始(月)、終了(年)、終了(月)のいずれかが入力
        if ( ( headerRow.getInstallationStartYear()    == null
            && ( headerRow.getInstallationStartMonth() != null
              || headerRow.getInstallationEndYear()    != null
              || headerRow.getInstallationEndMonth()   != null ) )
          //または、開始(年)が入力で、開始(月)、終了(年)、終了(月)のいずれかが未入力
          || (   headerRow.getInstallationStartYear()  != null
            && ( headerRow.getInstallationStartMonth() == null
              || headerRow.getInstallationEndYear()    == null
              || headerRow.getInstallationEndMonth()   == null ) ) )
        {
          errorList.add(
              XxcsoMessage.createErrorMessage(
               XxcsoConstants.APP_XXCSO1_00878
               ,XxcsoConstants.TOKEN_COLUMN
               ,token1
              )
          );
        }
      }

      if ( errorList.size() == 0 )
      {
        if ( headerRow.getInstallationStartYear() != null )
        {
          int installationStartYear  = Integer.valueOf( headerRow.getInstallationStartYear() ).intValue();
          int installationStartMonth = Integer.valueOf( headerRow.getInstallationStartMonth() ).intValue();
          int installationEndYear    = Integer.valueOf( headerRow.getInstallationEndYear() ).intValue();
          int installationEndMonth   = Integer.valueOf( headerRow.getInstallationEndMonth() ).intValue();

          // 設置見込み期間開始、終了の整合性チェック
          if ( installationStartYear > installationEndYear
            || ( installationStartYear  == installationEndYear
              && installationStartMonth >  installationEndMonth ) )
          {
            errorList.add(
                XxcsoMessage.createErrorMessage(
                 XxcsoConstants.APP_XXCSO1_00883
                 ,XxcsoConstants.TOKEN_COLUMN
                 ,token1
                )
            );
          }
        }
      }
    }

// 2018-05-16 [E_本稼動_14989] Add End
// Ver.1.24 Del Start
    //String adAssetsType = headerRow.getAdAssetsType();
    //if ( XxcsoSpDecisionConstants.CHECK_YES.equals(adAssetsType) )
    //{
      /////////////////////////////////////
      // その他条件：総額（行政財産使用料）
      /////////////////////////////////////
    //  token1 = XxcsoSpDecisionConstants.TOKEN_VALUE_OTHER_COND_REGION
    //          + XxcsoConstants.TOKEN_VALUE_DELIMITER1
    //          + XxcsoSpDecisionConstants.TOKEN_VALUE_AD_ASSETS_AMT;
    //  errorList
    //    = utils.checkStringToNumber(
    //        errorList
    //       ,headerRow.getAdAssetsAmt()
    //       ,token1
    //       ,0
    //       ,8
    //       ,true
    //       ,true
    //       ,submitFlag
    //       ,0
    //      );
      /////////////////////////////////////
      // その他条件：今回支払（行政財産使用料）
      /////////////////////////////////////
    //  token1 = XxcsoSpDecisionConstants.TOKEN_VALUE_OTHER_COND_REGION
    //          + XxcsoConstants.TOKEN_VALUE_DELIMITER1
    //          + XxcsoSpDecisionConstants.TOKEN_VALUE_AD_ASSETS_THIS_TIME;
    //  errorList
    //    = utils.checkStringToNumber(
    //        errorList
    //       ,headerRow.getAdAssetsThisTime()
    //       ,token1
    //       ,0
    //       ,8
    //       ,true
    //       ,true
    //       ,submitFlag
    //       ,0
    //      );
      /////////////////////////////////////
      // その他条件：支払年数（行政財産使用料）
      /////////////////////////////////////
    //  token1 = XxcsoSpDecisionConstants.TOKEN_VALUE_OTHER_COND_REGION
    //          + XxcsoConstants.TOKEN_VALUE_DELIMITER1
    //          + XxcsoSpDecisionConstants.TOKEN_VALUE_AD_ASSETS_PAYMENT_YEAR;
    //  errorList
    //    = utils.checkStringToNumber(
    //        errorList
    //       ,headerRow.getAdAssetsPaymentYear()
    //       ,token1
    //       ,0
    //       ,2
    //       ,true
    //       ,true
    //       ,submitFlag
    //       ,0
    //      );

      /////////////////////////////////////
      // その他条件：支払期日（行政財産使用料）
      /////////////////////////////////////
    //  if ( submitFlag )
    //  {
    //    token1 = XxcsoSpDecisionConstants.TOKEN_VALUE_OTHER_COND_REGION
    //            + XxcsoConstants.TOKEN_VALUE_DELIMITER1
    //            + XxcsoSpDecisionConstants.TOKEN_VALUE_AD_ASSETS_PAYMENT_DATE;
    //    errorList
    //      = utils.requiredCheck(
    //          errorList
    //         ,headerRow.getAdAssetsPaymentDate()
    //         ,token1
    //         ,0
    //        );
    //  }
    //}
// Ver.1.24 Del End
// 2014-12-15 [E_本稼動_12565] Add End
    XxcsoUtils.debug(txn, "[END]");

    return errorList;
  }

  
  /*****************************************************************************
   * その他条件の検証
   * @param txn         OADBTransactionインスタンス
   * @param headerVo    SP専決ヘッダ登録／更新用ビューインスタンス
   * @param submitFlag  提出用フラグ
   * @return List       エラーリスト
   *****************************************************************************
   */
  public static List validateConditionReason(
    OADBTransaction                     txn
   ,XxcsoSpDecisionHeaderFullVOImpl     headerVo
   ,boolean                             submitFlag
  )
  {
    XxcsoUtils.debug(txn, "[START]");
    
    List errorList = new ArrayList();
    String token1 = null;
    
    /////////////////////////////////////
    // 各行を取得
    /////////////////////////////////////
    XxcsoSpDecisionHeaderFullVORowImpl headerRow
      = (XxcsoSpDecisionHeaderFullVORowImpl)headerVo.first();

    XxcsoValidateUtils utils = XxcsoValidateUtils.getInstance(txn);

    /////////////////////////////////////
    // その他条件：特別条件
    /////////////////////////////////////
    token1 = XxcsoSpDecisionConstants.TOKEN_VALUE_OTHER_COND_REGION
            + XxcsoConstants.TOKEN_VALUE_DELIMITER1
            + XxcsoSpDecisionConstants.TOKEN_VALUE_COND_REASON;
    errorList
      = utils.checkIllegalString(
          errorList
         ,headerRow.getConditionReason()
         ,token1
         ,0
        );

    XxcsoUtils.debug(txn, "[END]");

    return errorList;
  }

// 2014-12-15 [E_本稼動_12565] Add Start
  /*****************************************************************************
   * 覚書情報の検証
   * @param txn         OADBTransactionインスタンス
   * @param headerVo    SP専決ヘッダ登録／更新用ビューインスタンス
   * @param submitFlag  提出用フラグ
   * @return List       エラーリスト
   *****************************************************************************
   */
  public static List validateMemorandumInfo(
    OADBTransaction                     txn
   ,XxcsoSpDecisionHeaderFullVOImpl     headerVo
   ,boolean                             submitFlag
  )
  {
    XxcsoUtils.debug(txn, "[START]");
    
    List errorList = new ArrayList();
    String token1 = null;
// Ver.1.24 Add Start
    String token2 = null;
// Ver.1.24 Add End
XxcsoUtils.debug(txn, "覚書情報提出ボタンフラグ："+submitFlag);    
    /////////////////////////////////////
    // 各行を取得
    /////////////////////////////////////
    XxcsoSpDecisionHeaderFullVORowImpl headerRow
      = (XxcsoSpDecisionHeaderFullVORowImpl)headerVo.first();

    XxcsoValidateUtils utils = XxcsoValidateUtils.getInstance(txn);

    String installSuppType   = headerRow.getInstallSuppType();
    String electricType      = headerRow.getElectricType();
    String introChgType      = headerRow.getIntroChgType();
XxcsoUtils.debug(txn, "設置協賛金チェック："+installSuppType);
    // 設置協賛金
    if ( XxcsoSpDecisionConstants.CHECK_YES.equals(installSuppType) )
    {
XxcsoUtils.debug(txn, "設置協賛金総額："+headerRow.getInstallSuppAmt()); 
      /////////////////////////////////////
      // 覚書情報：総額（設置協賛金）
      /////////////////////////////////////
      token1 = XxcsoSpDecisionConstants.TOKEN_VALUE_MEMO_RANDUM_INFO_REGION
              + XxcsoConstants.TOKEN_VALUE_DELIMITER1
              + XxcsoSpDecisionConstants.TOKEN_VALUE_AD_INSTALL_SUPP_AMT;
      errorList
        = utils.checkStringToNumber(
            errorList
           ,headerRow.getInstallSuppAmt()
           ,token1
           ,0
           ,8
           ,true
// Ver.1.24 Mod Start
//           ,true
           ,false
// Ver.1.24 Mod End
           ,submitFlag
           ,0
          );

      String installSuppPaymentType = headerRow.getInstallSuppPaymentType();
      if ( XxcsoSpDecisionConstants.ONE_YEAR_PAY.equals(installSuppPaymentType) 
// Ver.1.24 Add Start
        || XxcsoSpDecisionConstants.QUARTER_PAY.equals(installSuppPaymentType)
        || XxcsoSpDecisionConstants.HALF_PAY.equals(installSuppPaymentType))
// Ver.1.24 Add End
      {
        /////////////////////////////////////
        // 覚書情報：今回支払（設置協賛金）
        /////////////////////////////////////
        token1 = XxcsoSpDecisionConstants.TOKEN_VALUE_MEMO_RANDUM_INFO_REGION
                + XxcsoConstants.TOKEN_VALUE_DELIMITER1
                + XxcsoSpDecisionConstants.TOKEN_VALUE_INSTALL_SUPP_THIS_TIME;
// Ver.1.24 Add Start
        token2 = XxcsoSpDecisionConstants.TOKEN_VALUE_MEMO_RANDUM_INFO_REGION
                + XxcsoConstants.TOKEN_VALUE_DELIMITER1
                + XxcsoSpDecisionConstants.TOKEN_VALUE_AD_INSTALL_SUPP_AMT;
// Ver.1.24 Add End
        errorList
          = utils.checkStringToNumber(
              errorList
             ,headerRow.getInstallSuppThisTime()
             ,token1
             ,0
             ,8
             ,true
// Ver.1.24 Mod Start
//             ,true
             ,false
// Ver.1.24 Mod End
             ,submitFlag
             ,0
            ); 
// Ver.1.24 Add Start
        if ( !(headerRow.getInstallSuppThisTime() == null || "".equals(headerRow.getInstallSuppThisTime()) )
          && !(headerRow.getInstallSuppAmt() == null || "".equals(headerRow.getInstallSuppAmt()) ))
        {
          String installSuppAmt = headerRow.getInstallSuppAmt().replaceAll(",", "");
          int intInstallSuppAmt = Integer.parseInt(installSuppAmt);

          if ( intInstallSuppAmt == 0 )
          { 
            headerRow.setInstallSuppThisTime("0");
          }

          String installSuppThisTime = headerRow.getInstallSuppThisTime().replaceAll(",", "");
          int intInstallSuppThisTime = Integer.parseInt(installSuppThisTime);

          if ( intInstallSuppThisTime > intInstallSuppAmt )
          {
            OAException error
              = XxcsoMessage.createErrorMessage(
                  XxcsoConstants.APP_XXCSO1_00487
                 ,XxcsoConstants.TOKEN_COLUMN
                 ,token2
                 ,XxcsoConstants.TOKEN_MIN_VALUE
                 ,token1
                );

            errorList.add(error);          
          }

          if ( intInstallSuppAmt > 0 && intInstallSuppThisTime == 0 )
          {
            OAException error
              = XxcsoMessage.createErrorMessage(
                  XxcsoConstants.APP_XXCSO1_00487
                 ,XxcsoConstants.TOKEN_COLUMN
                 ,token1
                 ,XxcsoConstants.TOKEN_MIN_VALUE
                 ,"０"
                );

            errorList.add(error);
          }
        }
// Ver.1.24 Add End
      }

      /////////////////////////////////////
      // 覚書情報：支払年数（設置協賛金）
      /////////////////////////////////////
      token1 = XxcsoSpDecisionConstants.TOKEN_VALUE_MEMO_RANDUM_INFO_REGION
              + XxcsoConstants.TOKEN_VALUE_DELIMITER1
              + XxcsoSpDecisionConstants.TOKEN_VALUE_INSTALL_SUPP_PAYMENT_YEAR;

      errorList
        = utils.checkStringToNumber(
            errorList
           ,headerRow.getInstallSuppPaymentYear()
           ,token1
           ,0
           ,2
           ,true
// Ver.1.24 Mod Start
//           ,true
           ,false
// Ver.1.24 Mod End
           ,submitFlag
           ,0
          );

// Ver.1.24 Mod Start
      if ( !(headerRow.getInstallSuppAmt() == null || "".equals(headerRow.getInstallSuppAmt()) )
        && !(headerRow.getInstallSuppPaymentYear() == null || "".equals(headerRow.getInstallSuppPaymentYear()) ))
      {
        String installSuppAmt = headerRow.getInstallSuppAmt().replaceAll(",", "");
        int intInstallSuppAmt = Integer.parseInt(installSuppAmt);
          if ( intInstallSuppAmt == 0 )
          { 
            headerRow.setInstallSuppPaymentYear("0");
          }
      }
// Ver.1.24 Mod End

      /////////////////////////////////////
      // 覚書情報：支払期日（設置協賛金）
      /////////////////////////////////////
      if ( submitFlag )
      {
        token1 = XxcsoSpDecisionConstants.TOKEN_VALUE_MEMO_RANDUM_INFO_REGION
                + XxcsoConstants.TOKEN_VALUE_DELIMITER1
                + XxcsoSpDecisionConstants.TOKEN_VALUE_INSTALL_SUPP_PAYMENT_DATE;
        errorList
          = utils.requiredCheck(
              errorList
             ,headerRow.getInstallSuppPaymentDate()
             ,token1
             ,0
            );
      }
// Ver.1.24 Add Start
      ///////////////////////////////////////
      // 覚書情報：支払期間開始日（設置協賛金）（年）
    ///////////////////////////////////////
      if ( submitFlag )
      {
        List installPayStartYearList = new ArrayList();
        
        token1 = XxcsoSpDecisionConstants.TOKEN_VALUE_MEMO_RANDUM_INFO_REGION
                + XxcsoConstants.TOKEN_VALUE_DELIMITER1
                + XxcsoSpDecisionConstants.TOKEN_VALUE_INSTALL_SUPP_PAY_START_YEAR;
        installPayStartYearList
          = utils.checkStringToNumber(
              installPayStartYearList
             ,headerRow.getInstallPayStartYear()
             ,token1
             ,0
             ,4
             ,true
             ,true
             ,true
             ,0
            );     

        if(installPayStartYearList.size() == 0)
        {
          // 支払期間開始日（設置協賛金）（年）が西暦であるかチェック
          if ( ! isYear( headerRow.getInstallPayStartYear() ) )
          {
            installPayStartYearList.add(
                XxcsoMessage.createErrorMessage(
                  XxcsoConstants.APP_XXCSO1_00720
                 ,XxcsoConstants.TOKEN_COLUMN
                 ,token1
                )
            );
          }
        }

        errorList.addAll(installPayStartYearList);          
        
      }      
      ///////////////////////////////////////
      // 覚書情報：支払期間開始日（設置協賛金）（月）
      ///////////////////////////////////////
      if ( submitFlag )
      {      
        List installPayStartMonthList = new ArrayList();

        token1 = XxcsoSpDecisionConstants.TOKEN_VALUE_MEMO_RANDUM_INFO_REGION
              + XxcsoConstants.TOKEN_VALUE_DELIMITER1
              + XxcsoSpDecisionConstants.TOKEN_VALUE_INSTALL_SUPP_PAY_START_MONTH;
        installPayStartMonthList
          = utils.checkStringToNumber(
              installPayStartMonthList
             ,headerRow.getInstallPayStartMonth()
             ,token1
             ,0
             ,2
             ,true
             ,true
             ,true
             ,0
            );

        if(installPayStartMonthList.size() == 0)
        {
          // 支払期間開始日（設置協賛金）（月）が12以下であるかチェック
          if ( ! isMonth( headerRow.getInstallPayStartMonth() ) )
          {
            installPayStartMonthList.add(
                XxcsoMessage.createErrorMessage(
                  XxcsoConstants.APP_XXCSO1_00719
                 ,XxcsoConstants.TOKEN_COLUMN
                 ,token1
                )
            );
          }     
        }

        errorList.addAll(installPayStartMonthList);          
      }    
      ///////////////////////////////////////
      // 覚書情報：支払期間終了日（設置協賛金）(年)
      ///////////////////////////////////////
      if ( submitFlag )
      {
        List installPayEndYearhList = new ArrayList();
        
        token1 = XxcsoSpDecisionConstants.TOKEN_VALUE_MEMO_RANDUM_INFO_REGION
                + XxcsoConstants.TOKEN_VALUE_DELIMITER1
                + XxcsoSpDecisionConstants.TOKEN_VALUE_INSTALL_SUPP_PAY_END_YEAR;
        installPayEndYearhList
          = utils.checkStringToNumber(
              installPayEndYearhList
             ,headerRow.getInstallPayEndYear()
             ,token1
             ,0
             ,4
             ,true
             ,true
             ,true
             ,0
            );

        if(installPayEndYearhList.size() == 0)
        {
          // 支払期間終了日（設置協賛金）（年）が西暦であるかチェック
          if ( ! isYear( headerRow.getInstallPayEndYear() ) )
          {
            installPayEndYearhList.add(
                XxcsoMessage.createErrorMessage(
                  XxcsoConstants.APP_XXCSO1_00720
                 ,XxcsoConstants.TOKEN_COLUMN
                 ,token1
                )
            );
          } 
        }

        errorList.addAll(installPayEndYearhList);          

      }
      ///////////////////////////////////////
      // 覚書情報：支払期間終了日（設置協賛金）(月)
      ///////////////////////////////////////
      if ( submitFlag )
      {

        List installPayEndMonthList = new ArrayList();
        
        token1 = XxcsoSpDecisionConstants.TOKEN_VALUE_MEMO_RANDUM_INFO_REGION
                + XxcsoConstants.TOKEN_VALUE_DELIMITER1
                + XxcsoSpDecisionConstants.TOKEN_VALUE_INSTALL_SUPP_PAY_END_MONTH;
        installPayEndMonthList
          = utils.checkStringToNumber(
              installPayEndMonthList
             ,headerRow.getInstallPayEndMonth()
             ,token1
             ,0
             ,2
             ,true
             ,true
             ,true
             ,0
            ); 

        if(installPayEndMonthList.size() == 0)
        {
          // 支払期間終了日（設置協賛金）（月）が12以下であるかチェック
          if ( ! isMonth( headerRow.getInstallPayEndMonth() ) )
          {
            installPayEndMonthList.add(
                XxcsoMessage.createErrorMessage(
                  XxcsoConstants.APP_XXCSO1_00719
                 ,XxcsoConstants.TOKEN_COLUMN
                 ,token1
                )
            );
          }
        }

        errorList.addAll(installPayEndMonthList);          
      }
// Ver.1.24 Add End
    }

    // 電気代
    if ( XxcsoSpDecisionConstants.CHECK_YES.equals(electricType) )
    {
      /////////////////////////////////////
      // 覚書情報：電気代
      /////////////////////////////////////
      token1 = XxcsoSpDecisionConstants.TOKEN_VALUE_MEMO_RANDUM_INFO_REGION
              + XxcsoConstants.TOKEN_VALUE_DELIMITER1
              + XxcsoSpDecisionConstants.TOKEN_VALUE_ELECTRICITY_AMT_MONTH;
      errorList
        = utils.checkStringToNumber(
            errorList
           ,headerRow.getElectricityAmount()
           ,token1
           ,0
           ,5
           ,true
           ,true
           ,submitFlag
           ,0
          );

      String  electricPaymentType  = headerRow.getElectricPaymentType();

      if ( XxcsoSpDecisionConstants.CONTRACT_OTHER.equals(electricPaymentType) )
      {
        /////////////////////////////////////
        // 覚書情報：契約先以外名（電気代）
        /////////////////////////////////////
        token1 = XxcsoSpDecisionConstants.TOKEN_VALUE_MEMO_RANDUM_INFO_REGION
                + XxcsoConstants.TOKEN_VALUE_DELIMITER1
                + XxcsoSpDecisionConstants.TOKEN_VALUE_ELECTRIC_TRANS_NAME;
        if ( submitFlag )
        {
          errorList
            = utils.requiredCheck(
                errorList
               ,headerRow.getElectricTransName()
               ,token1
               ,0
              );
        }
        errorList
          = utils.checkIllegalString(
              errorList
             ,headerRow.getElectricTransName()
             ,token1
             ,0
            );
        if ( ! isDoubleByte(
                 txn
                ,headerRow.getElectricTransName()
               )
           )
        {
          OAException error
            = XxcsoMessage.createErrorMessage(
                XxcsoConstants.APP_XXCSO1_00565
               ,XxcsoConstants.TOKEN_REGION
               ,XxcsoSpDecisionConstants.TOKEN_VALUE_MEMO_RANDUM_INFO_REGION
               ,XxcsoConstants.TOKEN_COLUMN
               ,XxcsoSpDecisionConstants.TOKEN_VALUE_ELECTRIC_TRANS_NAME
              );
          errorList.add(error);
        }

        /////////////////////////////////////
        // 覚書情報：契約先以外名カナ（電気代）
        /////////////////////////////////////
        token1 = XxcsoSpDecisionConstants.TOKEN_VALUE_MEMO_RANDUM_INFO_REGION
                + XxcsoConstants.TOKEN_VALUE_DELIMITER1
                + XxcsoSpDecisionConstants.TOKEN_VALUE_ELECTRIC_TRANS_NAME_ALT;
        if ( submitFlag )
        {
          errorList
            = utils.requiredCheck(
                errorList
               ,headerRow.getElectricTransNameAlt()
               ,token1
               ,0
              );
        }
        errorList
          = utils.checkIllegalString(
              errorList
             ,headerRow.getElectricTransNameAlt()
             ,token1
             ,0
            );
        if ( ! isSingleByteKana(
                 txn
                ,headerRow.getElectricTransNameAlt()
               )
           )
        {
          OAException error
            = XxcsoMessage.createErrorMessage(
                XxcsoConstants.APP_XXCSO1_00573
               ,XxcsoConstants.TOKEN_REGION
               ,XxcsoSpDecisionConstants.TOKEN_VALUE_MEMO_RANDUM_INFO_REGION
               ,XxcsoConstants.TOKEN_COLUMN
               ,XxcsoSpDecisionConstants.TOKEN_VALUE_ELECTRIC_TRANS_NAME_ALT
              );
          errorList.add(error);
        }
      }
    }

    // 紹介手数料
    if ( XxcsoSpDecisionConstants.CHECK_YES.equals(introChgType) )
    {

      String introChgPaymentType = headerRow.getIntroChgPaymentType();

      if ( XxcsoSpDecisionConstants.SALES_BULK.equals(introChgPaymentType) )
      {
        /////////////////////////////////////
        // 覚書情報：総額（紹介手数料）
        /////////////////////////////////////
        token1 = XxcsoSpDecisionConstants.TOKEN_VALUE_MEMO_RANDUM_INFO_REGION
                + XxcsoConstants.TOKEN_VALUE_DELIMITER1
                + XxcsoSpDecisionConstants.TOKEN_VALUE_INTRO_CHG_AMT;
        errorList
          = utils.checkStringToNumber(
              errorList
             ,headerRow.getIntroChgAmt()
             ,token1
             ,0
             ,8
             ,true
             ,true
             ,submitFlag
             ,0
            );

        /////////////////////////////////////
        // 覚書情報：今回支払（紹介手数料）
        /////////////////////////////////////
        token1 = XxcsoSpDecisionConstants.TOKEN_VALUE_MEMO_RANDUM_INFO_REGION
                + XxcsoConstants.TOKEN_VALUE_DELIMITER1
                + XxcsoSpDecisionConstants.TOKEN_VALUE_INTRO_CHG_THIS_TIME;
        errorList
          = utils.checkStringToNumber(
              errorList
             ,headerRow.getIntroChgThisTime()
             ,token1
             ,0
             ,8
             ,true
             ,true
             ,submitFlag
             ,0
            );

        /////////////////////////////////////
        // 覚書情報：支払年数（紹介手数料）
        /////////////////////////////////////
        token1 = XxcsoSpDecisionConstants.TOKEN_VALUE_MEMO_RANDUM_INFO_REGION
                + XxcsoConstants.TOKEN_VALUE_DELIMITER1
                + XxcsoSpDecisionConstants.TOKEN_VALUE_INTRO_CHG_PAYMENT_YEAR;
        errorList
          = utils.checkStringToNumber(
              errorList
             ,headerRow.getIntroChgPaymentYear()
             ,token1
             ,0
             ,2
             ,true
             ,true
             ,submitFlag
             ,0
            );

        /////////////////////////////////////
        // 覚書情報：支払期日（紹介手数料）
        /////////////////////////////////////
        if ( submitFlag )
        {
          token1 = XxcsoSpDecisionConstants.TOKEN_VALUE_MEMO_RANDUM_INFO_REGION
                  + XxcsoConstants.TOKEN_VALUE_DELIMITER1
                  + XxcsoSpDecisionConstants.TOKEN_VALUE_INTRO_CHG_PAYMENT_DATE;
          errorList
            = utils.requiredCheck(
                errorList
               ,headerRow.getIntroChgPaymentDate()
               ,token1
               ,0
              );
        }
      }
      else
      {
        if ( XxcsoSpDecisionConstants.SALES_PAR.equals(introChgPaymentType) )
        {
          /////////////////////////////////////
          // 覚書情報：販売金額当り紹介手数料率
          /////////////////////////////////////
          token1 = XxcsoSpDecisionConstants.TOKEN_VALUE_MEMO_RANDUM_INFO_REGION
                  + XxcsoConstants.TOKEN_VALUE_DELIMITER1
                  + XxcsoSpDecisionConstants.TOKEN_VALUE_INTRO_CHG_PER_SALES_PRICE;
          errorList
            = utils.checkStringToNumber(
                errorList
               ,headerRow.getIntroChgPerSalesPrice()
               ,token1
               ,2
               ,3
               ,true
               ,true
               ,submitFlag
               ,0
              );

        }
        else if (  XxcsoSpDecisionConstants.SALES_AMT.equals(introChgPaymentType) )
        {
          /////////////////////////////////////
          // 覚書情報：1本当り紹介手数料額
          /////////////////////////////////////
          token1 = XxcsoSpDecisionConstants.TOKEN_VALUE_MEMO_RANDUM_INFO_REGION
                  + XxcsoConstants.TOKEN_VALUE_DELIMITER1
                  + XxcsoSpDecisionConstants.TOKEN_VALUE_INTRO_CHG_PER_PIECE;
          errorList
            = utils.checkStringToNumber(
                errorList
               ,headerRow.getIntroChgPerPiece()
               ,token1
               ,0
               ,8
               ,true
               ,true
               ,submitFlag
               ,0
              );
        }
      }
      /////////////////////////////////////
      // 覚書情報：契約先以外名（紹介手数料）
      /////////////////////////////////////
      token1 = XxcsoSpDecisionConstants.TOKEN_VALUE_MEMO_RANDUM_INFO_REGION
              + XxcsoConstants.TOKEN_VALUE_DELIMITER1
              + XxcsoSpDecisionConstants.TOKEN_VALUE_INTRO_CHG_TRANS_NAME;
      if ( submitFlag )
      {
        errorList
          = utils.requiredCheck(
              errorList
             ,headerRow.getIntroChgTransName()
             ,token1
             ,0
            );
      }
      errorList
        = utils.checkIllegalString(
            errorList
           ,headerRow.getIntroChgTransName()
           ,token1
           ,0
          );
      if ( ! isDoubleByte(
               txn
              ,headerRow.getIntroChgTransName()
             )
         )
      {
        OAException error
          = XxcsoMessage.createErrorMessage(
              XxcsoConstants.APP_XXCSO1_00565
             ,XxcsoConstants.TOKEN_REGION
             ,XxcsoSpDecisionConstants.TOKEN_VALUE_MEMO_RANDUM_INFO_REGION
             ,XxcsoConstants.TOKEN_COLUMN
             ,XxcsoSpDecisionConstants.TOKEN_VALUE_INTRO_CHG_TRANS_NAME
            );
        errorList.add(error);
      }

        /////////////////////////////////////
        // 覚書情報：契約先以外名カナ（紹介手数料）
        /////////////////////////////////////
        token1 = XxcsoSpDecisionConstants.TOKEN_VALUE_MEMO_RANDUM_INFO_REGION
                + XxcsoConstants.TOKEN_VALUE_DELIMITER1
                + XxcsoSpDecisionConstants.TOKEN_VALUE_INTRO_CHG_TRANS_NAME_ALT;
        if ( submitFlag )
        {
          errorList
            = utils.requiredCheck(
                errorList
               ,headerRow.getIntroChgTransNameAlt()
               ,token1
               ,0
              );
        }
        errorList
          = utils.checkIllegalString(
              errorList
             ,headerRow.getIntroChgTransNameAlt()
             ,token1
             ,0
            );
        if ( ! isSingleByteKana(
                 txn
                ,headerRow.getIntroChgTransNameAlt()
               )
           )
        {
          OAException error
            = XxcsoMessage.createErrorMessage(
                XxcsoConstants.APP_XXCSO1_00573
               ,XxcsoConstants.TOKEN_REGION
               ,XxcsoSpDecisionConstants.TOKEN_VALUE_MEMO_RANDUM_INFO_REGION
               ,XxcsoConstants.TOKEN_COLUMN
               ,XxcsoSpDecisionConstants.TOKEN_VALUE_INTRO_CHG_TRANS_NAME_ALT
              );
          errorList.add(error);
        }
    }

// Ver.1.24 Add Start
    // 行政財産使用料
    String adAssetsType = headerRow.getAdAssetsType();
    if ( XxcsoSpDecisionConstants.CHECK_YES.equals(adAssetsType) )
    {
      /////////////////////////////////////
      // 覚書情報：総額（行政財産使用料）
      /////////////////////////////////////
      token1 = XxcsoSpDecisionConstants.TOKEN_VALUE_MEMO_RANDUM_INFO_REGION
              + XxcsoConstants.TOKEN_VALUE_DELIMITER1
              + XxcsoSpDecisionConstants.TOKEN_VALUE_AD_ASSETS_AMT;
      errorList
        = utils.checkStringToNumber(
            errorList
           ,headerRow.getAdAssetsAmt()
           ,token1
           ,0
           ,8
           ,true
           ,false
           ,submitFlag
           ,0
          );

      String adAssetsPaymentType = headerRow.getAdAssetsPaymentType();
      if ( XxcsoSpDecisionConstants.ONE_YEAR_PAY.equals(adAssetsPaymentType)
        || XxcsoSpDecisionConstants.QUARTER_PAY.equals(adAssetsPaymentType)
        || XxcsoSpDecisionConstants.HALF_PAY.equals(adAssetsPaymentType))
      {
      /////////////////////////////////////
      // 覚書情報：今回支払（行政財産使用料）
      /////////////////////////////////////
        token1 = XxcsoSpDecisionConstants.TOKEN_VALUE_MEMO_RANDUM_INFO_REGION
                + XxcsoConstants.TOKEN_VALUE_DELIMITER1
                + XxcsoSpDecisionConstants.TOKEN_VALUE_AD_ASSETS_THIS_TIME;

        token2 = XxcsoSpDecisionConstants.TOKEN_VALUE_MEMO_RANDUM_INFO_REGION
                + XxcsoConstants.TOKEN_VALUE_DELIMITER1
                + XxcsoSpDecisionConstants.TOKEN_VALUE_AD_ASSETS_AMT;

        errorList
          = utils.checkStringToNumber(
              errorList
             ,headerRow.getAdAssetsThisTime()
             ,token1
             ,0
             ,8
             ,true
             ,false
             ,submitFlag
             ,0
            );

        if ( !(headerRow.getAdAssetsThisTime() == null || "".equals(headerRow.getAdAssetsThisTime()) )
          && !(headerRow.getAdAssetsAmt() == null || "".equals(headerRow.getAdAssetsAmt()) ))
        {
          String adAmt = headerRow.getAdAssetsAmt().replaceAll(",", "");
          int intAdAmt = Integer.parseInt(adAmt);

          if ( intAdAmt == 0 )
          { 
            headerRow.setAdAssetsThisTime("0");
          }
          
          String adThisTime = headerRow.getAdAssetsThisTime().replaceAll(",", "");
          int intAdThisTime = Integer.parseInt(adThisTime);
          
          if ( intAdThisTime > intAdAmt )
          {
            OAException error
              = XxcsoMessage.createErrorMessage(
                  XxcsoConstants.APP_XXCSO1_00487
                 ,XxcsoConstants.TOKEN_COLUMN
                 ,token2
                 ,XxcsoConstants.TOKEN_MIN_VALUE
                 ,token1
                );

            errorList.add(error);          
          }

          if ( intAdAmt > 0 && intAdThisTime == 0 )
          {
            OAException error
              = XxcsoMessage.createErrorMessage(
                  XxcsoConstants.APP_XXCSO1_00487
                 ,XxcsoConstants.TOKEN_COLUMN
                 ,token1
                 ,XxcsoConstants.TOKEN_MIN_VALUE
                 ,"０"
                );

            errorList.add(error);
          }
        }
      }

      /////////////////////////////////////
      // 覚書情報：支払年数（行政財産使用料）
      /////////////////////////////////////
      token1 = XxcsoSpDecisionConstants.TOKEN_VALUE_MEMO_RANDUM_INFO_REGION
              + XxcsoConstants.TOKEN_VALUE_DELIMITER1
              + XxcsoSpDecisionConstants.TOKEN_VALUE_AD_ASSETS_PAYMENT_YEAR;
      
      errorList
        = utils.checkStringToNumber(
            errorList
           ,headerRow.getAdAssetsPaymentYear()
           ,token1
           ,0
           ,2
           ,true
           ,false
           ,submitFlag
           ,0
          );

      if ( !(headerRow.getAdAssetsAmt() == null || "".equals(headerRow.getAdAssetsAmt()) )
        && !(headerRow.getAdAssetsPaymentYear() == null || "".equals(headerRow.getAdAssetsPaymentYear()) ))
      {
        String adAmt = headerRow.getAdAssetsAmt().replaceAll(",", "");
        int intAdAmt = Integer.parseInt(adAmt);
          if ( intAdAmt == 0 )
          { 
            headerRow.setAdAssetsPaymentYear("0");
          }
      }

      /////////////////////////////////////
      // 覚書情報：支払期日（行政財産使用料）
      /////////////////////////////////////
      if ( submitFlag )
      {
        token1 = XxcsoSpDecisionConstants.TOKEN_VALUE_MEMO_RANDUM_INFO_REGION
                + XxcsoConstants.TOKEN_VALUE_DELIMITER1
                + XxcsoSpDecisionConstants.TOKEN_VALUE_AD_ASSETS_PAYMENT_DATE;
        errorList
          = utils.requiredCheck(
              errorList
             ,headerRow.getAdAssetsPaymentDate()
             ,token1
             ,0
            );
      }

      ///////////////////////////////////////////
      // 覚書情報：支払期間開始日（行政財産使用料）（年）
      ///////////////////////////////////////////
      if ( submitFlag )
      {

        List adAssetsPayStartYearList = new ArrayList();
        
        token1 = XxcsoSpDecisionConstants.TOKEN_VALUE_MEMO_RANDUM_INFO_REGION
                + XxcsoConstants.TOKEN_VALUE_DELIMITER1
                + XxcsoSpDecisionConstants.TOKEN_VALUE_AD_ASSETS_PAY_START_YEAR;
        adAssetsPayStartYearList
          = utils.checkStringToNumber(
              adAssetsPayStartYearList
             ,headerRow.getAdAssetsPayStartYear()
             ,token1
             ,0
             ,4
             ,true
             ,true
             ,true
             ,0
            );  

        if( adAssetsPayStartYearList.size() == 0 )
        {
           // 支払期間開始日（行政財産使用料）（年）が西暦であるかチェック
          if ( ! isYear( headerRow.getAdAssetsPayStartYear() ) )
          {
            adAssetsPayStartYearList.add(
                XxcsoMessage.createErrorMessage(
                  XxcsoConstants.APP_XXCSO1_00720
                 ,XxcsoConstants.TOKEN_COLUMN
                 ,token1
                )
            );
          }              
        }

        errorList.addAll(adAssetsPayStartYearList);          

      }
      ///////////////////////////////////////////
      // 覚書情報：支払期間開始日（行政財産使用料）（月）
      ///////////////////////////////////////////
      if ( submitFlag )
      {
        List adAssetsPayStartMonthList = new ArrayList();
        
        token1 = XxcsoSpDecisionConstants.TOKEN_VALUE_MEMO_RANDUM_INFO_REGION
                + XxcsoConstants.TOKEN_VALUE_DELIMITER1
                + XxcsoSpDecisionConstants.TOKEN_VALUE_AD_ASSETS_PAY_START_MONTH;
        adAssetsPayStartMonthList
          = utils.checkStringToNumber(
              adAssetsPayStartMonthList
             ,headerRow.getAdAssetsPayStartMonth()
             ,token1
             ,0
             ,2
             ,true
             ,true
             ,true
             ,0
            );   

        if( adAssetsPayStartMonthList.size() == 0 )
        {
          // 支払期間開始日（行政財産使用料）（月）が12以下であるかチェック
          if ( ! isMonth( headerRow.getAdAssetsPayStartMonth() ) )
          {
            adAssetsPayStartMonthList.add(
                XxcsoMessage.createErrorMessage(
                  XxcsoConstants.APP_XXCSO1_00719
                 ,XxcsoConstants.TOKEN_COLUMN
                 ,token1
                )
            );
          }	  
        }

        errorList.addAll(adAssetsPayStartMonthList);          

      }
      ///////////////////////////////////////////
      // 覚書情報：支払期間終了日（行政財産使用料）（年）
      ///////////////////////////////////////////
      if ( submitFlag )
      {
        List adAssetsPayEndYearList = new ArrayList();
        
        token1 = XxcsoSpDecisionConstants.TOKEN_VALUE_MEMO_RANDUM_INFO_REGION
                + XxcsoConstants.TOKEN_VALUE_DELIMITER1
                + XxcsoSpDecisionConstants.TOKEN_VALUE_AD_ASSETS_PAY_END_YEAR;
        adAssetsPayEndYearList
          = utils.checkStringToNumber(
              adAssetsPayEndYearList
             ,headerRow.getAdAssetsPayEndYear()
             ,token1
             ,0
             ,4
             ,true
             ,true
             ,true
             ,0
            ); 

        if( adAssetsPayEndYearList.size() == 0 )
        {
          // 支払期間終了日（行政財産使用料）（年）が西暦であるかチェック
          if ( ! isYear( headerRow.getAdAssetsPayEndYear() ) )
          {
            adAssetsPayEndYearList.add(
                XxcsoMessage.createErrorMessage(
                  XxcsoConstants.APP_XXCSO1_00720
                 ,XxcsoConstants.TOKEN_COLUMN
                 ,token1
                )
            );
          }	 
        }

        errorList.addAll(adAssetsPayEndYearList);          
      }
      ///////////////////////////////////////////
      // 覚書情報：支払期間終了日（行政財産使用料）（月）
      ///////////////////////////////////////////
      if ( submitFlag )
      {
        List adAssetsPayEndMonthList = new ArrayList();
        
        token1 = XxcsoSpDecisionConstants.TOKEN_VALUE_MEMO_RANDUM_INFO_REGION
                + XxcsoConstants.TOKEN_VALUE_DELIMITER1
                + XxcsoSpDecisionConstants.TOKEN_VALUE_AD_ASSETS_PAY_END_MONTH;        
        adAssetsPayEndMonthList
          = utils.checkStringToNumber(
              adAssetsPayEndMonthList
             ,headerRow.getAdAssetsPayEndMonth()
             ,token1
             ,0
             ,2
             ,true
             ,true
             ,true
             ,0
            ); 

        if( adAssetsPayEndMonthList.size() == 0 )
        {
          // 支払期間終了日（行政財産使用料）（月）が12以下であるかチェック
          if ( ! isMonth( headerRow.getAdAssetsPayEndMonth() ) )
          {
            adAssetsPayEndMonthList.add(
                XxcsoMessage.createErrorMessage(
                  XxcsoConstants.APP_XXCSO1_00719
                 ,XxcsoConstants.TOKEN_COLUMN
                 ,token1
                )
            );
          }
        }

        errorList.addAll(adAssetsPayEndMonthList);          
      }
    }
// Ver.1.24 Add End

    XxcsoUtils.debug(txn, "[END]");

    return errorList;
  }
// 2014-12-15 [E_本稼動_12565] Add End
  
  /*****************************************************************************
   * BM1の検証
   * @param txn           OADBTransactionインスタンス
   * @param bm1Vo         BM1登録／更新用ビューインスタンス
   * @param submitFlag    提出用フラグ
   * @return List         エラーリスト
   *****************************************************************************
   */
  public static List validateBm1Cust(
    OADBTransaction                     txn
   ,XxcsoSpDecisionBm1CustFullVOImpl    bm1Vo
   ,boolean                             submitFlag
  )
  {
    XxcsoUtils.debug(txn, "[START]");
    
    List errorList = new ArrayList();
    String token1 = null;
    
    /////////////////////////////////////
    // 各行を取得
    /////////////////////////////////////
    XxcsoSpDecisionBm1CustFullVORowImpl bm1Row
      = (XxcsoSpDecisionBm1CustFullVORowImpl)bm1Vo.first();

    XxcsoValidateUtils utils = XxcsoValidateUtils.getInstance(txn);

    String bmPaymentType = bm1Row.getBmPaymentType();
    String checkValue = null;
    /////////////////////////////////////
    // BM1：送付先名
    /////////////////////////////////////
    token1 = XxcsoSpDecisionConstants.TOKEN_VALUE_BM1_REGION
            + XxcsoConstants.TOKEN_VALUE_DELIMITER1
            + XxcsoSpDecisionConstants.TOKEN_VALUE_BM_PARTY_NAME;
    if ( submitFlag )
    {
      errorList
        =  utils.requiredCheck(
              errorList
            ,bm1Row.getPartyName()
            ,token1
            ,0
           );
    }
    errorList
      = utils.checkIllegalString(
          errorList
         ,bm1Row.getPartyName()
         ,token1
         ,0
        );
// 2009-04-27 [ST障害T1_0708] Add Start
    if ( ! isDoubleByte(
             txn
            ,bm1Row.getPartyName()
           )
       )
    {
      OAException error
        = XxcsoMessage.createErrorMessage(
            XxcsoConstants.APP_XXCSO1_00565
           ,XxcsoConstants.TOKEN_REGION
           ,XxcsoSpDecisionConstants.TOKEN_VALUE_BM1_REGION
           ,XxcsoConstants.TOKEN_COLUMN
           ,XxcsoSpDecisionConstants.TOKEN_VALUE_BM_PARTY_NAME
          );
      errorList.add(error);
    }
// 2009-04-27 [ST障害T1_0708] Add End

    /////////////////////////////////////
    // BM1：送付先名（カナ）
    /////////////////////////////////////
    token1 = XxcsoSpDecisionConstants.TOKEN_VALUE_BM1_REGION
            + XxcsoConstants.TOKEN_VALUE_DELIMITER1
            + XxcsoSpDecisionConstants.TOKEN_VALUE_BM_PARTY_NAME_ALT;
    if ( submitFlag )
    {
      errorList
        = utils.requiredCheck(
            errorList
           ,bm1Row.getPartyNameAlt()
           ,token1
           ,0
          );
    }
    errorList
      = utils.checkIllegalString(
          errorList
         ,bm1Row.getPartyNameAlt()
         ,token1
         ,0
        );
// 2009-04-27 [ST障害T1_0708] Mod Start
//    if ( ! isDoubleByteKana(
//             txn
//            ,bm1Row.getPartyNameAlt()
//           )
//       )
//    {
//      OAException error
//        = XxcsoMessage.createErrorMessage(
//            XxcsoConstants.APP_XXCSO1_00286
//           ,XxcsoConstants.TOKEN_REGION
//           ,XxcsoSpDecisionConstants.TOKEN_VALUE_BM1_REGION
//           ,XxcsoConstants.TOKEN_COLUMN
//           ,XxcsoSpDecisionConstants.TOKEN_VALUE_BM_PARTY_NAME_ALT
//          );
//      errorList.add(error);
//    }
    // 半角カナチェック
    if ( ! isSingleByteKana(
             txn
            ,bm1Row.getPartyNameAlt()
            )
       )
    {
      OAException error
        = XxcsoMessage.createErrorMessage(
// 2009-06-08 [ST障害T1_1307] Mod Start
//            XxcsoConstants.APP_XXCSO1_00533
            XxcsoConstants.APP_XXCSO1_00573
// 2009-06-08 [ST障害T1_1307] Mod End
           ,XxcsoConstants.TOKEN_REGION
           ,XxcsoSpDecisionConstants.TOKEN_VALUE_BM1_REGION
           ,XxcsoConstants.TOKEN_COLUMN
           ,XxcsoSpDecisionConstants.TOKEN_VALUE_BM_PARTY_NAME_ALT
          );
      errorList.add(error);
    }
// 2009-04-27 [ST障害T1_0708] Mod End
    
    /////////////////////////////////////
    // BM1：郵便番号
    /////////////////////////////////////
    token1 = XxcsoSpDecisionConstants.TOKEN_VALUE_BM1_REGION
            + XxcsoConstants.TOKEN_VALUE_DELIMITER1
            + XxcsoSpDecisionConstants.TOKEN_VALUE_POSTAL_CODE;
    if ( submitFlag )
    {
      if ( bm1Row.getPostalCodeFirst() == null             ||
           "".equals(bm1Row.getPostalCodeFirst().trim())   ||
           bm1Row.getPostalCodeSecond() == null            ||
           "".equals(bm1Row.getPostalCodeSecond().trim())
         )
      {
        OAException error
          = XxcsoMessage.createErrorMessage(
              XxcsoConstants.APP_XXCSO1_00005
             ,XxcsoConstants.TOKEN_COLUMN
             ,token1
            );
        errorList.add(error);
      }

      if ( ! isPostalCode(
               txn
              ,bm1Row.getPostalCodeFirst()
              ,bm1Row.getPostalCodeSecond()
             )
         )
      {
        token1 = XxcsoSpDecisionConstants.TOKEN_VALUE_BM1_REGION;
        OAException error
          = XxcsoMessage.createErrorMessage(
              XxcsoConstants.APP_XXCSO1_00287
             ,XxcsoConstants.TOKEN_REGION
             ,token1
            );
        errorList.add(error);
      }
    }
// 2009-10-14 [IE554,IE573] Add Start
//    /////////////////////////////////////
//    // BM1：都道府県
//    /////////////////////////////////////
//    token1 = XxcsoSpDecisionConstants.TOKEN_VALUE_BM1_REGION
//            + XxcsoConstants.TOKEN_VALUE_DELIMITER1
//            + XxcsoSpDecisionConstants.TOKEN_VALUE_STATE;
//    if ( submitFlag )
//    {
//      errorList
//        = utils.requiredCheck(
//            errorList
//           ,bm1Row.getState()
//           ,token1
//           ,0
//          );
//    }
//    errorList
//      = utils.checkIllegalString(
//          errorList
//         ,bm1Row.getState()
//         ,token1
//         ,0
//        );
//// 2009-04-27 [ST障害T1_0708] Add Start
//    if ( ! isDoubleByte(
//             txn
//            ,bm1Row.getState()
//           )
//       )
//    {
//      OAException error
//        = XxcsoMessage.createErrorMessage(
//            XxcsoConstants.APP_XXCSO1_00565
//           ,XxcsoConstants.TOKEN_REGION
//           ,XxcsoSpDecisionConstants.TOKEN_VALUE_BM1_REGION
//           ,XxcsoConstants.TOKEN_COLUMN
//           ,XxcsoSpDecisionConstants.TOKEN_VALUE_STATE
//          );
//      errorList.add(error);
//    }
//// 2009-04-27 [ST障害T1_0708] Add End
//
//    /////////////////////////////////////
//    // BM1：市・区
//    /////////////////////////////////////
//    token1 = XxcsoSpDecisionConstants.TOKEN_VALUE_BM1_REGION
//            + XxcsoConstants.TOKEN_VALUE_DELIMITER1
//            + XxcsoSpDecisionConstants.TOKEN_VALUE_CITY;
//    if ( submitFlag )
//    {
//      errorList
//        = utils.requiredCheck(
//            errorList
//           ,bm1Row.getCity()
//           ,token1
//           ,0
//          );
//    }
//    errorList
//      = utils.checkIllegalString(
//          errorList
//         ,bm1Row.getCity()
//         ,token1
//         ,0
//        );
//// 2009-04-27 [ST障害T1_0708] Add Start
//    if ( ! isDoubleByte(
//             txn
//            ,bm1Row.getCity()
//           )
//       )
//    {
//      OAException error
//        = XxcsoMessage.createErrorMessage(
//            XxcsoConstants.APP_XXCSO1_00565
//           ,XxcsoConstants.TOKEN_REGION
//           ,XxcsoSpDecisionConstants.TOKEN_VALUE_BM1_REGION
//           ,XxcsoConstants.TOKEN_COLUMN
//           ,XxcsoSpDecisionConstants.TOKEN_VALUE_CITY
//          );
//      errorList.add(error);
//    }
//// 2009-04-27 [ST障害T1_0708] Add End
// 2009-10-14 [IE554,IE573] Add End
    /////////////////////////////////////
    // BM1：住所1
    /////////////////////////////////////
    token1 = XxcsoSpDecisionConstants.TOKEN_VALUE_BM1_REGION
            + XxcsoConstants.TOKEN_VALUE_DELIMITER1
            + XxcsoSpDecisionConstants.TOKEN_VALUE_ADDRESS1;
    if ( submitFlag )
    {
      errorList
        = utils.requiredCheck(
            errorList
           ,bm1Row.getAddress1()
           ,token1
           ,0
          );
    }
    errorList
      = utils.checkIllegalString(
          errorList
         ,bm1Row.getAddress1()
         ,token1
         ,0
        );
// 2009-04-27 [ST障害T1_0708] Add Start
    if ( ! isDoubleByte(
             txn
            ,bm1Row.getAddress1()
           )
       )
    {
      OAException error
        = XxcsoMessage.createErrorMessage(
            XxcsoConstants.APP_XXCSO1_00565
           ,XxcsoConstants.TOKEN_REGION
           ,XxcsoSpDecisionConstants.TOKEN_VALUE_BM1_REGION
           ,XxcsoConstants.TOKEN_COLUMN
           ,XxcsoSpDecisionConstants.TOKEN_VALUE_ADDRESS1
          );
      errorList.add(error);
    }
// 2009-04-27 [ST障害T1_0708] Add End

    /////////////////////////////////////
    // BM1：住所2
    /////////////////////////////////////
    token1 = XxcsoSpDecisionConstants.TOKEN_VALUE_BM1_REGION
            + XxcsoConstants.TOKEN_VALUE_DELIMITER1
            + XxcsoSpDecisionConstants.TOKEN_VALUE_ADDRESS2;
    errorList
      = utils.checkIllegalString(
          errorList
         ,bm1Row.getAddress2()
         ,token1
         ,0
        );
// 2009-04-27 [ST障害T1_0708] Add Start
    if ( ! isDoubleByte(
             txn
            ,bm1Row.getAddress2()
           )
       )
    {
      OAException error
        = XxcsoMessage.createErrorMessage(
            XxcsoConstants.APP_XXCSO1_00565
           ,XxcsoConstants.TOKEN_REGION
           ,XxcsoSpDecisionConstants.TOKEN_VALUE_BM1_REGION
           ,XxcsoConstants.TOKEN_COLUMN
           ,XxcsoSpDecisionConstants.TOKEN_VALUE_ADDRESS2
          );
      errorList.add(error);
    }
// 2009-04-27 [ST障害T1_0708] Add End

    /////////////////////////////////////
    // BM1：電話番号
    /////////////////////////////////////
    if ( ! utils.isTelNumber(bm1Row.getAddressLinesPhonetic()) )
    {
      OAException error
        = XxcsoMessage.createErrorMessage(
            XxcsoConstants.APP_XXCSO1_00288
           ,XxcsoConstants.TOKEN_REGION
           ,XxcsoSpDecisionConstants.TOKEN_VALUE_BM1_REGION
          );
      errorList.add(error);
    }

    /////////////////////////////////////
    // BM1：振込手数料負担
    /////////////////////////////////////
    token1 = XxcsoSpDecisionConstants.TOKEN_VALUE_BM1_REGION
            + XxcsoConstants.TOKEN_VALUE_DELIMITER1
            + XxcsoSpDecisionConstants.TOKEN_VALUE_TRANSFER;
    if ( submitFlag )
    {
// 2010-03-01 [E_本稼動_01678] Add Start
      // BM1の支払方法・明細書が現金支払以外の場合
      if (! XxcsoSpDecisionConstants.PAYMENT_TYPE_CASH.equals(bm1Row.getBmPaymentType()))
      {
// 2010-03-01 [E_本稼動_01678] Add End
        errorList
          = utils.requiredCheck(
              errorList
             ,bm1Row.getTransferCommissionType()
             ,token1
             ,0
            );
// 2010-03-01 [E_本稼動_01678] Add Start
      }
// 2010-03-01 [E_本稼動_01678] Add End
    }
    
    XxcsoUtils.debug(txn, "[END]");

    return errorList;
  }



  /*****************************************************************************
   * BM2の検証
   * @param txn         OADBTransactionインスタンス
   * @param headerVo    SP専決ヘッダ登録／更新用ビューインスタンス
   * @param bm2Vo       BM2登録／更新用ビューインスタンス
   * @param submitFlag  提出用フラグ
   * @return List       エラーリスト
   *****************************************************************************
   */
  public static List validateBm2Cust(
    OADBTransaction                     txn
   ,XxcsoSpDecisionHeaderFullVOImpl     headerVo
   ,XxcsoSpDecisionBm2CustFullVOImpl    bm2Vo
   ,boolean                             submitFlag
  )
  {
    XxcsoUtils.debug(txn, "[START]");
    
    List errorList = new ArrayList();
    String token1 = null;
    
    /////////////////////////////////////
    // 各行を取得
    /////////////////////////////////////
    XxcsoSpDecisionHeaderFullVORowImpl headerRow
      = (XxcsoSpDecisionHeaderFullVORowImpl)headerVo.first();
    XxcsoSpDecisionBm2CustFullVORowImpl bm2Row
      = (XxcsoSpDecisionBm2CustFullVORowImpl)bm2Vo.first();

    XxcsoValidateUtils utils = XxcsoValidateUtils.getInstance(txn);

    String condBizType = headerRow.getConditionBusinessType();
    String regionName = XxcsoSpDecisionConstants.TOKEN_VALUE_BM2_REGION;
    if ( XxcsoSpDecisionConstants.COND_CNTNR_CONTRIBUTE.equals(condBizType) ||
         XxcsoSpDecisionConstants.COND_SALES_CONTRIBUTE.equals(condBizType)
       )
    {
      regionName = XxcsoSpDecisionConstants.TOKEN_VALUE_CONTRIBUTE_REGION;
    }
    
    /////////////////////////////////////
    // BM2：送付先名
    /////////////////////////////////////
    token1 = regionName
            + XxcsoConstants.TOKEN_VALUE_DELIMITER1
            + XxcsoSpDecisionConstants.TOKEN_VALUE_BM_PARTY_NAME;
    if ( submitFlag )
    {
      errorList
        =  utils.requiredCheck(
              errorList
            ,bm2Row.getPartyName()
            ,token1
            ,0
           );
    }
    errorList
      = utils.checkIllegalString(
          errorList
         ,bm2Row.getPartyName()
         ,token1
         ,0
        );
// 2009-04-27 [ST障害T1_0708] Add Start
    if ( ! isDoubleByte(
             txn
            ,bm2Row.getPartyName()
           )
       )
    {
      OAException error
        = XxcsoMessage.createErrorMessage(
            XxcsoConstants.APP_XXCSO1_00565
           ,XxcsoConstants.TOKEN_REGION
           ,regionName
           ,XxcsoConstants.TOKEN_COLUMN
           ,XxcsoSpDecisionConstants.TOKEN_VALUE_BM_PARTY_NAME
          );
      errorList.add(error);
    }
// 2009-04-27 [ST障害T1_0708] Add End
    
    /////////////////////////////////////
    // BM2：送付先名（カナ）
    /////////////////////////////////////
    token1 = regionName
            + XxcsoConstants.TOKEN_VALUE_DELIMITER1
            + XxcsoSpDecisionConstants.TOKEN_VALUE_BM_PARTY_NAME_ALT;
    if ( submitFlag )
    {
      errorList
        = utils.requiredCheck(
            errorList
           ,bm2Row.getPartyNameAlt()
           ,token1
           ,0
          );
    }
    errorList
      = utils.checkIllegalString(
          errorList
         ,bm2Row.getPartyNameAlt()
         ,token1
         ,0
        );
// 2009-04-27 [ST障害T1_0708] Mod Start
//    if ( ! isDoubleByteKana(
//             txn
//            ,bm2Row.getPartyNameAlt()
//           )
//       )
//    {
//      OAException error
//        = XxcsoMessage.createErrorMessage(
//            XxcsoConstants.APP_XXCSO1_00286
//           ,XxcsoConstants.TOKEN_REGION
//           ,regionName
//           ,XxcsoConstants.TOKEN_COLUMN
//           ,XxcsoSpDecisionConstants.TOKEN_VALUE_BM_PARTY_NAME_ALT
//          );
//      errorList.add(error);
//    }
    // 半角カナチェック
    if ( ! isSingleByteKana(
             txn
            ,bm2Row.getPartyNameAlt()
           )
       )
    {
      OAException error
        = XxcsoMessage.createErrorMessage(
// 2009-06-08 [ST障害T1_1307] Mod Start
//            XxcsoConstants.APP_XXCSO1_00533
            XxcsoConstants.APP_XXCSO1_00573
// 2009-06-08 [ST障害T1_1307] Mod End
           ,XxcsoConstants.TOKEN_REGION
           ,regionName
           ,XxcsoConstants.TOKEN_COLUMN
           ,XxcsoSpDecisionConstants.TOKEN_VALUE_BM_PARTY_NAME_ALT
          );
      errorList.add(error);
    }
// 2009-04-27 [ST障害T1_0708] Mod End
    
    /////////////////////////////////////
    // BM2：郵便番号
    /////////////////////////////////////
    token1 = regionName
            + XxcsoConstants.TOKEN_VALUE_DELIMITER1
            + XxcsoSpDecisionConstants.TOKEN_VALUE_POSTAL_CODE;
    if ( submitFlag )
    {
      if ( bm2Row.getPostalCodeFirst() == null             ||
           "".equals(bm2Row.getPostalCodeFirst().trim())   ||
           bm2Row.getPostalCodeSecond() == null            ||
           "".equals(bm2Row.getPostalCodeSecond().trim())
         )
      {
        OAException error
          = XxcsoMessage.createErrorMessage(
              XxcsoConstants.APP_XXCSO1_00005
             ,XxcsoConstants.TOKEN_COLUMN
             ,token1
            );
        errorList.add(error);
      }

      if ( ! isPostalCode(
               txn
              ,bm2Row.getPostalCodeFirst()
              ,bm2Row.getPostalCodeSecond()
             )
         )
      {
        OAException error
          = XxcsoMessage.createErrorMessage(
              XxcsoConstants.APP_XXCSO1_00287
             ,XxcsoConstants.TOKEN_REGION
             ,regionName
            );
        errorList.add(error);
      }
    }

// 2009-10-14 [IE554,IE573] Add Start
//    /////////////////////////////////////
//    // BM2：都道府県
//    /////////////////////////////////////
//    token1 = regionName
//            + XxcsoConstants.TOKEN_VALUE_DELIMITER1
//            + XxcsoSpDecisionConstants.TOKEN_VALUE_STATE;
//    if ( submitFlag )
//    {
//      errorList
//        = utils.requiredCheck(
//            errorList
//           ,bm2Row.getState()
//           ,token1
//           ,0
//          );
//    }
//    errorList
//      = utils.checkIllegalString(
//          errorList
//         ,bm2Row.getState()
//         ,token1
//         ,0
//        );
//// 2009-04-27 [ST障害T1_0708] Add Start
//    if ( ! isDoubleByte(
//             txn
//            ,bm2Row.getState()
//           )
//       )
//    {
//      OAException error
//        = XxcsoMessage.createErrorMessage(
//            XxcsoConstants.APP_XXCSO1_00565
//           ,XxcsoConstants.TOKEN_REGION
//           ,regionName
//           ,XxcsoConstants.TOKEN_COLUMN
//           ,XxcsoSpDecisionConstants.TOKEN_VALUE_STATE
//          );
//      errorList.add(error);
//    }
//// 2009-04-27 [ST障害T1_0708] Add End
//
//    /////////////////////////////////////
//    // BM2：市・区
//    /////////////////////////////////////
//    token1 = regionName
//            + XxcsoConstants.TOKEN_VALUE_DELIMITER1
//            + XxcsoSpDecisionConstants.TOKEN_VALUE_CITY;
//    if ( submitFlag )
//    {
//      errorList
//        = utils.requiredCheck(
//            errorList
//           ,bm2Row.getCity()
//           ,token1
//           ,0
//          );
//    }
//    errorList
//      = utils.checkIllegalString(
//          errorList
//         ,bm2Row.getCity()
//         ,token1
//         ,0
//        );
//// 2009-04-27 [ST障害T1_0708] Add Start
//    if ( ! isDoubleByte(
//             txn
//            ,bm2Row.getCity()
//           )
//       )
//    {
//      OAException error
//        = XxcsoMessage.createErrorMessage(
//            XxcsoConstants.APP_XXCSO1_00565
//           ,XxcsoConstants.TOKEN_REGION
//           ,regionName
//           ,XxcsoConstants.TOKEN_COLUMN
//           ,XxcsoSpDecisionConstants.TOKEN_VALUE_CITY
//          );
//      errorList.add(error);
//    }
//// 2009-04-27 [ST障害T1_0708] Add End
// 2009-10-14 [IE554,IE573] Add End

    /////////////////////////////////////
    // BM2：住所1
    /////////////////////////////////////
    token1 = regionName
            + XxcsoConstants.TOKEN_VALUE_DELIMITER1
            + XxcsoSpDecisionConstants.TOKEN_VALUE_ADDRESS1;
    if ( submitFlag )
    {
      errorList
        = utils.requiredCheck(
            errorList
           ,bm2Row.getAddress1()
           ,token1
           ,0
          );
    }
    errorList
      = utils.checkIllegalString(
          errorList
         ,bm2Row.getAddress1()
         ,token1
         ,0
        );
// 2009-04-27 [ST障害T1_0708] Add Start
    if ( ! isDoubleByte(
             txn
            ,bm2Row.getAddress1()
           )
       )
    {
      OAException error
        = XxcsoMessage.createErrorMessage(
            XxcsoConstants.APP_XXCSO1_00565
           ,XxcsoConstants.TOKEN_REGION
           ,regionName
           ,XxcsoConstants.TOKEN_COLUMN
           ,XxcsoSpDecisionConstants.TOKEN_VALUE_ADDRESS1
          );
      errorList.add(error);
    }
// 2009-04-27 [ST障害T1_0708] Add End

    /////////////////////////////////////
    // BM2：住所2
    /////////////////////////////////////
    token1 = regionName
            + XxcsoConstants.TOKEN_VALUE_DELIMITER1
            + XxcsoSpDecisionConstants.TOKEN_VALUE_ADDRESS2;
    errorList
      = utils.checkIllegalString(
          errorList
         ,bm2Row.getAddress2()
         ,token1
         ,0
        );
// 2009-04-27 [ST障害T1_0708] Add Start
    if ( ! isDoubleByte(
             txn
            ,bm2Row.getAddress2()
           )
       )
    {
      OAException error
        = XxcsoMessage.createErrorMessage(
            XxcsoConstants.APP_XXCSO1_00565
           ,XxcsoConstants.TOKEN_REGION
           ,regionName
           ,XxcsoConstants.TOKEN_COLUMN
           ,XxcsoSpDecisionConstants.TOKEN_VALUE_ADDRESS2
          );
      errorList.add(error);
    }
// 2009-04-27 [ST障害T1_0708] Add End

    /////////////////////////////////////
    // BM2：電話番号
    /////////////////////////////////////
    if ( ! utils.isTelNumber(bm2Row.getAddressLinesPhonetic()) )
    {
      OAException error
        = XxcsoMessage.createErrorMessage(
            XxcsoConstants.APP_XXCSO1_00288
           ,XxcsoConstants.TOKEN_REGION
           ,regionName
          );
      errorList.add(error);
    }

    /////////////////////////////////////
    // BM2：振込手数料負担
    /////////////////////////////////////
    token1 = regionName
            + XxcsoConstants.TOKEN_VALUE_DELIMITER1
            + XxcsoSpDecisionConstants.TOKEN_VALUE_TRANSFER;
    if ( submitFlag )
    {
// 2010-03-01 [E_本稼動_01678] Add Start
      // BM2の支払方法・明細書が現金支払以外の場合
      if (! XxcsoSpDecisionConstants.PAYMENT_TYPE_CASH.equals(bm2Row.getBmPaymentType()))
      {
// 2010-03-01 [E_本稼動_01678] Add End
        errorList
          = utils.requiredCheck(
              errorList
             ,bm2Row.getTransferCommissionType()
             ,token1
             ,0
            );
// 2010-03-01 [E_本稼動_01678] Add Start
      }
// 2010-03-01 [E_本稼動_01678] Add End
    }
    
    XxcsoUtils.debug(txn, "[END]");

    return errorList;
  }



  /*****************************************************************************
   * BM3の検証
   * @param txn         OADBTransactionインスタンス
   * @param bm3Vo       BM3登録／更新用ビューインスタンス
   * @param submitFlag  提出用フラグ
   * @return List       エラーリスト
   *****************************************************************************
   */
  public static List validateBm3Cust(
    OADBTransaction                     txn
   ,XxcsoSpDecisionBm3CustFullVOImpl    bm3Vo
   ,boolean                             submitFlag
  )
  {
    XxcsoUtils.debug(txn, "[START]");
    
    List errorList = new ArrayList();
    String token1 = null;
    
    /////////////////////////////////////
    // 各行を取得
    /////////////////////////////////////
    XxcsoSpDecisionBm3CustFullVORowImpl bm3Row
      = (XxcsoSpDecisionBm3CustFullVORowImpl)bm3Vo.first();

    XxcsoValidateUtils utils = XxcsoValidateUtils.getInstance(txn);

    /////////////////////////////////////
    // BM3：送付先名
    /////////////////////////////////////
    token1 = XxcsoSpDecisionConstants.TOKEN_VALUE_BM3_REGION
            + XxcsoConstants.TOKEN_VALUE_DELIMITER1
            + XxcsoSpDecisionConstants.TOKEN_VALUE_BM_PARTY_NAME;
    if ( submitFlag )
    {
      errorList
        =  utils.requiredCheck(
              errorList
            ,bm3Row.getPartyName()
            ,token1
            ,0
           );
    }
    errorList
      = utils.checkIllegalString(
          errorList
         ,bm3Row.getPartyName()
         ,token1
         ,0
        );
// 2009-04-27 [ST障害T1_0708] Add Start
    if ( ! isDoubleByte(
             txn
            ,bm3Row.getPartyName()
           )
       )
    {
      OAException error
        = XxcsoMessage.createErrorMessage(
            XxcsoConstants.APP_XXCSO1_00565
           ,XxcsoConstants.TOKEN_REGION
           ,XxcsoSpDecisionConstants.TOKEN_VALUE_BM3_REGION
           ,XxcsoConstants.TOKEN_COLUMN
           ,XxcsoSpDecisionConstants.TOKEN_VALUE_BM_PARTY_NAME
          );
      errorList.add(error);
    }
// 2009-04-27 [ST障害T1_0708] Add End
    
    /////////////////////////////////////
    // BM3：送付先名（カナ）
    /////////////////////////////////////
    token1 = XxcsoSpDecisionConstants.TOKEN_VALUE_BM3_REGION
            + XxcsoConstants.TOKEN_VALUE_DELIMITER1
            + XxcsoSpDecisionConstants.TOKEN_VALUE_BM_PARTY_NAME_ALT;
    if ( submitFlag )
    {
      errorList
        = utils.requiredCheck(
            errorList
           ,bm3Row.getPartyNameAlt()
           ,token1
           ,0
          );
    }
    errorList
      = utils.checkIllegalString(
          errorList
         ,bm3Row.getPartyNameAlt()
         ,token1
         ,0
        );
// 2009-04-27 [ST障害T1_0708] Add Start
//    if ( ! isDoubleByteKana(
//             txn
//            ,bm3Row.getPartyNameAlt()
//           )
//       )
//    {
//      OAException error
//        = XxcsoMessage.createErrorMessage(
//            XxcsoConstants.APP_XXCSO1_00286
//           ,XxcsoConstants.TOKEN_REGION
//           ,XxcsoSpDecisionConstants.TOKEN_VALUE_BM3_REGION
//           ,XxcsoConstants.TOKEN_COLUMN
//           ,XxcsoSpDecisionConstants.TOKEN_VALUE_BM_PARTY_NAME_ALT
//          );
//      errorList.add(error);
//    }
    // 半角カナチェック
    if ( ! isSingleByteKana(
             txn
            ,bm3Row.getPartyNameAlt()
           )
       )
    {
      OAException error
        = XxcsoMessage.createErrorMessage(
// 2009-06-08 [ST障害T1_1307] Mod Start
//            XxcsoConstants.APP_XXCSO1_00533
            XxcsoConstants.APP_XXCSO1_00573
// 2009-06-08 [ST障害T1_1307] Mod End
           ,XxcsoConstants.TOKEN_REGION
           ,XxcsoSpDecisionConstants.TOKEN_VALUE_BM3_REGION
           ,XxcsoConstants.TOKEN_COLUMN
           ,XxcsoSpDecisionConstants.TOKEN_VALUE_BM_PARTY_NAME_ALT
          );
      errorList.add(error);
    }
// 2009-04-27 [ST障害T1_0708] Add End
    
    /////////////////////////////////////
    // BM3：郵便番号
    /////////////////////////////////////
    token1 = XxcsoSpDecisionConstants.TOKEN_VALUE_BM3_REGION
            + XxcsoConstants.TOKEN_VALUE_DELIMITER1
            + XxcsoSpDecisionConstants.TOKEN_VALUE_POSTAL_CODE;
    if ( submitFlag )
    {
      if ( bm3Row.getPostalCodeFirst() == null             ||
           "".equals(bm3Row.getPostalCodeFirst().trim())   ||
           bm3Row.getPostalCodeSecond() == null            ||
           "".equals(bm3Row.getPostalCodeSecond().trim())
         )
      {
        OAException error
          = XxcsoMessage.createErrorMessage(
              XxcsoConstants.APP_XXCSO1_00005
             ,XxcsoConstants.TOKEN_COLUMN
             ,token1
            );
        errorList.add(error);
      }

      if ( ! isPostalCode(
               txn
              ,bm3Row.getPostalCodeFirst()
              ,bm3Row.getPostalCodeSecond()
             )
         )
      {
        token1 = XxcsoSpDecisionConstants.TOKEN_VALUE_BM3_REGION;
        OAException error
          = XxcsoMessage.createErrorMessage(
              XxcsoConstants.APP_XXCSO1_00287
             ,XxcsoConstants.TOKEN_REGION
             ,token1
            );
        errorList.add(error);
      }
    }
// 2009-10-14 [IE554,IE573] Add Start
//    /////////////////////////////////////
//    // BM3：都道府県
//    /////////////////////////////////////
//    token1 = XxcsoSpDecisionConstants.TOKEN_VALUE_BM3_REGION
//            + XxcsoConstants.TOKEN_VALUE_DELIMITER1
//            + XxcsoSpDecisionConstants.TOKEN_VALUE_STATE;
//    if ( submitFlag )
//    {
//      errorList
//        = utils.requiredCheck(
//            errorList
//           ,bm3Row.getState()
//           ,token1
//           ,0
//          );
//    }
//    errorList
//      = utils.checkIllegalString(
//          errorList
//         ,bm3Row.getState()
//         ,token1
//         ,0
//        );
//// 2009-04-27 [ST障害T1_0708] Add Start
//    if ( ! isDoubleByte(
//             txn
//            ,bm3Row.getState()
//           )
//       )
//    {
//      OAException error
//        = XxcsoMessage.createErrorMessage(
//            XxcsoConstants.APP_XXCSO1_00565
//           ,XxcsoConstants.TOKEN_REGION
//           ,XxcsoSpDecisionConstants.TOKEN_VALUE_BM3_REGION
//           ,XxcsoConstants.TOKEN_COLUMN
//           ,XxcsoSpDecisionConstants.TOKEN_VALUE_STATE
//          );
//      errorList.add(error);
//    }
//// 2009-04-27 [ST障害T1_0708] Add End
//
//    /////////////////////////////////////
//    // BM3：市・区
//    /////////////////////////////////////
//    token1 = XxcsoSpDecisionConstants.TOKEN_VALUE_BM3_REGION
//            + XxcsoConstants.TOKEN_VALUE_DELIMITER1
//            + XxcsoSpDecisionConstants.TOKEN_VALUE_CITY;
//    if ( submitFlag )
//    {
//      errorList
//        = utils.requiredCheck(
//            errorList
//           ,bm3Row.getCity()
//           ,token1
//           ,0
//          );
//    }
//    errorList
//      = utils.checkIllegalString(
//          errorList
//         ,bm3Row.getCity()
//         ,token1
//         ,0
//        );
//// 2009-04-27 [ST障害T1_0708] Add Start
//    if ( ! isDoubleByte(
//             txn
//            ,bm3Row.getCity()
//           )
//       )
//    {
//      OAException error
//        = XxcsoMessage.createErrorMessage(
//            XxcsoConstants.APP_XXCSO1_00565
//           ,XxcsoConstants.TOKEN_REGION
//           ,XxcsoSpDecisionConstants.TOKEN_VALUE_BM3_REGION
//           ,XxcsoConstants.TOKEN_COLUMN
//           ,XxcsoSpDecisionConstants.TOKEN_VALUE_CITY
//          );
//      errorList.add(error);
//    }
//// 2009-04-27 [ST障害T1_0708] Add End
// 2009-10-14 [IE554,IE573] Add End

    /////////////////////////////////////
    // BM3：住所1
    /////////////////////////////////////
    token1 = XxcsoSpDecisionConstants.TOKEN_VALUE_BM3_REGION
            + XxcsoConstants.TOKEN_VALUE_DELIMITER1
            + XxcsoSpDecisionConstants.TOKEN_VALUE_ADDRESS1;
    if ( submitFlag )
    {
      errorList
        = utils.requiredCheck(
            errorList
           ,bm3Row.getAddress1()
           ,token1
           ,0
          );
    }
    errorList
      = utils.checkIllegalString(
          errorList
         ,bm3Row.getAddress1()
         ,token1
         ,0
        );
// 2009-04-27 [ST障害T1_0708] Add Start
    if ( ! isDoubleByte(
             txn
            ,bm3Row.getAddress1()
           )
       )
    {
      OAException error
        = XxcsoMessage.createErrorMessage(
            XxcsoConstants.APP_XXCSO1_00565
           ,XxcsoConstants.TOKEN_REGION
           ,XxcsoSpDecisionConstants.TOKEN_VALUE_BM3_REGION
           ,XxcsoConstants.TOKEN_COLUMN
           ,XxcsoSpDecisionConstants.TOKEN_VALUE_ADDRESS1
          );
      errorList.add(error);
    }
// 2009-04-27 [ST障害T1_0708] Add End

    /////////////////////////////////////
    // BM3：住所2
    /////////////////////////////////////
    token1 = XxcsoSpDecisionConstants.TOKEN_VALUE_BM3_REGION
            + XxcsoConstants.TOKEN_VALUE_DELIMITER1
            + XxcsoSpDecisionConstants.TOKEN_VALUE_ADDRESS2;
    errorList
      = utils.checkIllegalString(
          errorList
         ,bm3Row.getAddress2()
         ,token1
         ,0
        );
// 2009-04-27 [ST障害T1_0708] Add Start
    if ( ! isDoubleByte(
             txn
            ,bm3Row.getAddress2()
           )
       )
    {
      OAException error
        = XxcsoMessage.createErrorMessage(
            XxcsoConstants.APP_XXCSO1_00565
           ,XxcsoConstants.TOKEN_REGION
           ,XxcsoSpDecisionConstants.TOKEN_VALUE_BM3_REGION
           ,XxcsoConstants.TOKEN_COLUMN
           ,XxcsoSpDecisionConstants.TOKEN_VALUE_ADDRESS2
          );
      errorList.add(error);
    }
// 2009-04-27 [ST障害T1_0708] Add End

    /////////////////////////////////////
    // BM3：電話番号
    /////////////////////////////////////
    if ( ! utils.isTelNumber(bm3Row.getAddressLinesPhonetic()) )
    {
      OAException error
        = XxcsoMessage.createErrorMessage(
            XxcsoConstants.APP_XXCSO1_00288
           ,XxcsoConstants.TOKEN_REGION
           ,XxcsoSpDecisionConstants.TOKEN_VALUE_BM3_REGION
          );
      errorList.add(error);
    }

    /////////////////////////////////////
    // BM3：振込手数料負担
    /////////////////////////////////////
    token1 = XxcsoSpDecisionConstants.TOKEN_VALUE_BM3_REGION
            + XxcsoConstants.TOKEN_VALUE_DELIMITER1
            + XxcsoSpDecisionConstants.TOKEN_VALUE_TRANSFER;
    if ( submitFlag )
    {
// 2010-03-01 [E_本稼動_01678] Add Start
      // BM3の支払方法・明細書が現金支払以外の場合
      if (! XxcsoSpDecisionConstants.PAYMENT_TYPE_CASH.equals(bm3Row.getBmPaymentType()))
      {
// 2010-03-01 [E_本稼動_01678] Add End
        errorList
          = utils.requiredCheck(
              errorList
             ,bm3Row.getTransferCommissionType()
             ,token1
             ,0
            );
// 2010-03-01 [E_本稼動_01678] Add Start
      }
// 2010-03-01 [E_本稼動_01678] Add End
    }
    
    XxcsoUtils.debug(txn, "[END]");

    return errorList;
  }


// 2014-12-15 [E_本稼動_12565] Del Start
//  /*****************************************************************************
//   * 契約書への記載事項の検証
//   * @param txn         OADBTransactionインスタンス
//   * @param headerVo    SP専決ヘッダ登録／更新用ビューインスタンス
//   * @param submitFlag  提出用フラグ
//   * @return List       エラーリスト
//   *****************************************************************************
//   */
//  public static List validateContractContent(
//    OADBTransaction                     txn
//   ,XxcsoSpDecisionHeaderFullVOImpl     headerVo
//   ,boolean                             submitFlag
//  )
//  {
//    XxcsoUtils.debug(txn, "[START]");
//    
//    List errorList = new ArrayList();
//    String token1 = null;
//    
//    /////////////////////////////////////
//    // 各行を取得
//    /////////////////////////////////////
//    XxcsoSpDecisionHeaderFullVORowImpl headerRow
//      = (XxcsoSpDecisionHeaderFullVORowImpl)headerVo.first();
//
//    XxcsoValidateUtils utils = XxcsoValidateUtils.getInstance(txn);
//
//    /////////////////////////////////////
//    // 契約書への記載事項：特約事項
//    /////////////////////////////////////
//    token1 = XxcsoSpDecisionConstants.TOKEN_VALUE_CNTRCT_CONTENT_REGION
//            + XxcsoConstants.TOKEN_VALUE_DELIMITER1
//            + XxcsoSpDecisionConstants.TOKEN_VALUE_OTHER_CONTENT;
//    errorList
//      = utils.checkIllegalString(
//          errorList
//         ,headerRow.getOtherContent()
//         ,token1
//         ,0
//        );
//
//    XxcsoUtils.debug(txn, "[END]");
//
//    return errorList;
//  }
// 2014-12-15 [E_本稼動_12565] Del End
  

  /*****************************************************************************
   * 概算年間損益の検証
   * @param txn         OADBTransactionインスタンス
   * @param headerVo    SP専決ヘッダ登録／更新用ビューインスタンス
   * @param submitFlag  提出用フラグ
   * @return List       エラーリスト
   *****************************************************************************
   */
  public static List validateEstimateProfit(
    OADBTransaction                     txn
   ,XxcsoSpDecisionHeaderFullVOImpl     headerVo
   ,boolean                             submitFlag
  )
  {
    XxcsoUtils.debug(txn, "[START]");
    
    List errorList = new ArrayList();
    String token1 = null;
    
    /////////////////////////////////////
    // 各行を取得
    /////////////////////////////////////
    XxcsoSpDecisionHeaderFullVORowImpl headerRow
      = (XxcsoSpDecisionHeaderFullVORowImpl)headerVo.first();

    XxcsoValidateUtils utils = XxcsoValidateUtils.getInstance(txn);

    /////////////////////////////////////
    // 取引条件
    /////////////////////////////////////
    token1 = XxcsoSpDecisionConstants.TOKEN_VALUE_COND_BIZ;
    if ( submitFlag )
    {
      errorList
        = utils.requiredCheck(
            errorList
           ,headerRow.getConditionBusinessType()
           ,token1
           ,0
          );
    }

    /////////////////////////////////////
    // その他条件：契約年数
    /////////////////////////////////////
    token1 = XxcsoSpDecisionConstants.TOKEN_VALUE_OTHER_COND_REGION
            + XxcsoConstants.TOKEN_VALUE_DELIMITER1
            + XxcsoSpDecisionConstants.TOKEN_VALUE_CONTRACT_YEAR;
    errorList
      = utils.checkStringToNumber(
          errorList
         ,headerRow.getContractYearDate()
         ,token1
         ,0
         ,2
         ,true
// 2014-12-15 [E_本稼動_12565] Mod Start
//         ,true
         ,false
// 2014-12-15 [E_本稼動_12565] Mod End
         ,submitFlag
         ,0
        );


    /////////////////////////////////////
    // 覚書情報：総額（設置協賛金）
    /////////////////////////////////////
// 2014-12-15 [E_本稼動_12565] Mod Start
    token1 = XxcsoSpDecisionConstants.TOKEN_VALUE_MEMO_RANDUM_INFO_REGION
// 2014-12-15 [E_本稼動_12565] Mod End
            + XxcsoConstants.TOKEN_VALUE_DELIMITER1
// 2014-12-15 [E_本稼動_12565] Mod Start
//            + XxcsoSpDecisionConstants.TOKEN_VALUE_INST_SUP_AMT;
            + XxcsoSpDecisionConstants.TOKEN_VALUE_AD_INSTALL_SUPP_AMT;
// 2014-12-15 [E_本稼動_12565] Mod Start
    errorList
      = utils.checkStringToNumber(
          errorList
// 2014-12-15 [E_本稼動_12565] Mod Start
//         ,headerRow.getInstallSupportAmt()
         ,headerRow.getInstallSuppAmt()
// 2014-12-15 [E_本稼動_12565] Mod Start
         ,token1
         ,0
         ,8
         ,true
         ,false
         ,false
         ,0
        );

    /////////////////////////////////////
    // 覚書情報：電気代
    /////////////////////////////////////
// 2014-12-15 [E_本稼動_12565] Mod Start
//    token1 = XxcsoSpDecisionConstants.TOKEN_VALUE_OTHER_COND_REGION
    token1 = XxcsoSpDecisionConstants.TOKEN_VALUE_MEMO_RANDUM_INFO_REGION
// 2014-12-15 [E_本稼動_12565] Mod End
            + XxcsoConstants.TOKEN_VALUE_DELIMITER1
            + XxcsoSpDecisionConstants.TOKEN_VALUE_ELECTRICITY_AMOUNT;
    errorList
      = utils.checkStringToNumber(
          errorList
         ,headerRow.getElectricityAmount()
         ,token1
         ,0
         ,5
         ,true
         ,false
         ,false
         ,0
        );

    /////////////////////////////////////
    // 概算年間損益：月間売上
    /////////////////////////////////////
    token1 = XxcsoSpDecisionConstants.TOKEN_VALUE_EST_PROFIT_REGION
            + XxcsoConstants.TOKEN_VALUE_DELIMITER1
            + XxcsoSpDecisionConstants.TOKEN_VALUE_SALES_MONTH;
    errorList
      = utils.checkStringToNumber(
          errorList
         ,headerRow.getSalesMonth()
         ,token1
         ,0
         ,4
         ,true
         ,true
         ,submitFlag
         ,0
        );

    /////////////////////////////////////
    // 概算年間損益：BM率
    /////////////////////////////////////
    token1 = XxcsoSpDecisionConstants.TOKEN_VALUE_EST_PROFIT_REGION
            + XxcsoConstants.TOKEN_VALUE_DELIMITER1
            + XxcsoSpDecisionConstants.TOKEN_VALUE_BM_RATE;
    errorList
      = utils.checkStringToNumber(
          errorList
         ,headerRow.getBmRate()
         ,token1
         ,2
         ,2
         ,true
         ,false
         ,submitFlag
         ,0
        );

    /////////////////////////////////////
    // 概算年間損益：リース料（月額）
    /////////////////////////////////////
    token1 = XxcsoSpDecisionConstants.TOKEN_VALUE_EST_PROFIT_REGION
            + XxcsoConstants.TOKEN_VALUE_DELIMITER1
            + XxcsoSpDecisionConstants.TOKEN_VALUE_LEASE_CHARGE;
    errorList
      = utils.checkStringToNumber(
          errorList
         ,headerRow.getLeaseChargeMonth()
         ,token1
         ,0
         ,2
         ,true
         ,false
         ,submitFlag
         ,0
        );

    /////////////////////////////////////
    // 概算年間損益：工事費
    /////////////////////////////////////
    token1 = XxcsoSpDecisionConstants.TOKEN_VALUE_EST_PROFIT_REGION
            + XxcsoConstants.TOKEN_VALUE_DELIMITER1
            + XxcsoSpDecisionConstants.TOKEN_VALUE_CONSTRUCT_CHARGE;
    errorList
      = utils.checkStringToNumber(
          errorList
         ,headerRow.getConstructionCharge()
         ,token1
         ,0
         ,4
         ,true
         ,false
         ,false
         ,0
        );

    /////////////////////////////////////
    // 概算年間損益：電気代（月）
    /////////////////////////////////////
    token1 = XxcsoSpDecisionConstants.TOKEN_VALUE_EST_PROFIT_REGION
            + XxcsoConstants.TOKEN_VALUE_DELIMITER1
            + XxcsoSpDecisionConstants.TOKEN_VALUE_ELECTRICITY_AMT_MONTH;
    errorList
      = utils.checkStringToNumber(
          errorList
         ,headerRow.getElectricityAmtMonth()
         ,token1
         ,2
         ,3
         ,true
         ,false
         ,false
         ,0
        );

    XxcsoUtils.debug(txn, "[END]");

    return errorList;
  }



  /*****************************************************************************
   * 添付の検証
   * @param txn         OADBTransactionインスタンス
   * @param attachVo    添付登録／更新用ビューインスタンス
   * @param submitFlag  提出用フラグ
   * @return List       エラーリスト
   *****************************************************************************
   */
  public static List validateAttach(
    OADBTransaction                     txn
   ,XxcsoSpDecisionAttachFullVOImpl     attachVo
   ,boolean                             submitFlag
  )
  {
    XxcsoUtils.debug(txn, "[START]");
    
    List errorList = new ArrayList();
    String token1 = null;
    
    /////////////////////////////////////
    // 各行を取得
    /////////////////////////////////////
    XxcsoSpDecisionAttachFullVORowImpl attachRow
      = (XxcsoSpDecisionAttachFullVORowImpl)attachVo.first();

    XxcsoValidateUtils utils = XxcsoValidateUtils.getInstance(txn);

    /////////////////////////////////////
    // 添付：摘要
    /////////////////////////////////////
    token1 = XxcsoSpDecisionConstants.TOKEN_VALUE_ATTACH_REGION
            + XxcsoConstants.TOKEN_VALUE_DELIMITER1
            + XxcsoSpDecisionConstants.TOKEN_VALUE_EXCERPT;

    int index = 0;
    while ( attachRow != null )
    {
      index++;
      
      errorList
        = utils.checkIllegalString(
            errorList
           ,attachRow.getExcerpt()
           ,token1
           ,index
          );

      attachRow = (XxcsoSpDecisionAttachFullVORowImpl)attachVo.next();
    }

    XxcsoUtils.debug(txn, "[END]");

    return errorList;
  }



  /*****************************************************************************
   * 回送先の検証
   * @param txn         OADBTransactionインスタンス
   * @param headerVo    SP専決ヘッダ登録／更新用ビューインスタンス
   * @param bm1Vo       BM1登録／更新用ビューインスタンス
   * @param bm2Vo       BM2登録／更新用ビューインスタンス
   * @param bm3Vo       BM3登録／更新用ビューインスタンス
   * @param scVo        売価別条件登録／更新用ビューインスタンス
   * @param allCcVo     全容器一律条件登録／更新用ビューインスタンス
   * @param selCcVo     容器別条件登録／更新用ビューインスタンス
   * @param sendVo      回送先登録／更新用ビューインスタンス
   * @param submitFlag  提出用フラグ
   * @return List       エラーリスト
   *****************************************************************************
   */
  public static List validateSend(
    OADBTransaction                     txn
   ,XxcsoSpDecisionHeaderFullVOImpl     headerVo
// 2010-03-01 [E_本稼動_01678] Add Start
   ,XxcsoSpDecisionBm1CustFullVOImpl    bm1Vo
   ,XxcsoSpDecisionBm2CustFullVOImpl    bm2Vo
   ,XxcsoSpDecisionBm3CustFullVOImpl    bm3Vo
// 2010-03-01 [E_本稼動_01678] Add End
   ,XxcsoSpDecisionScLineFullVOImpl     scVo
   ,XxcsoSpDecisionAllCcLineFullVOImpl  allCcVo
   ,XxcsoSpDecisionSelCcLineFullVOImpl  selCcVo
   ,XxcsoSpDecisionSendFullVOImpl       sendVo
   ,boolean                             submitFlag
  )
  {
    XxcsoUtils.debug(txn, "[START]");
    
    List errorList = new ArrayList();
    String token1 = null;
    
    /////////////////////////////////////
    // 各行を取得
    /////////////////////////////////////
    XxcsoSpDecisionHeaderFullVORowImpl headerRow
      = (XxcsoSpDecisionHeaderFullVORowImpl)headerVo.first();
// 2010-03-01 [E_本稼動_01678] Add Start
    XxcsoSpDecisionBm1CustFullVORowImpl bm1Row
      = (XxcsoSpDecisionBm1CustFullVORowImpl)bm1Vo.first();
    XxcsoSpDecisionBm2CustFullVORowImpl bm2Row
      = (XxcsoSpDecisionBm2CustFullVORowImpl)bm2Vo.first();
    XxcsoSpDecisionBm3CustFullVORowImpl bm3Row
      = (XxcsoSpDecisionBm3CustFullVORowImpl)bm3Vo.first();
// 2010-03-01 [E_本稼動_01678] Add End
    XxcsoSpDecisionScLineFullVORowImpl scRow
      = (XxcsoSpDecisionScLineFullVORowImpl)scVo.first();
    XxcsoSpDecisionAllCcLineFullVORowImpl allCcRow
      = (XxcsoSpDecisionAllCcLineFullVORowImpl)allCcVo.first();
    XxcsoSpDecisionSelCcLineFullVORowImpl selCcRow
      = (XxcsoSpDecisionSelCcLineFullVORowImpl)selCcVo.first();
    XxcsoSpDecisionSendFullVORowImpl sendRow
      = (XxcsoSpDecisionSendFullVORowImpl)sendVo.first();

    XxcsoValidateUtils utils = XxcsoValidateUtils.getInstance(txn);

    /////////////////////////////////////
    // 決裁コメント
    /////////////////////////////////////
    int index = 0;
    Number currentAuthLevel = null;
    
    while ( sendRow != null )
    {
      index++;

      if ( submitFlag )
      {
        token1 = XxcsoSpDecisionConstants.TOKEN_VALUE_SEND_REGION
                + XxcsoConstants.TOKEN_VALUE_DELIMITER1
                + XxcsoSpDecisionConstants.TOKEN_VALUE_EMPLOYEE_NUMBER;

        errorList
          = utils.requiredCheck(
              errorList
             ,sendRow.getApproveCode()
             ,token1
             ,index
            );
      }
      
      token1 = XxcsoSpDecisionConstants.TOKEN_VALUE_SEND_REGION
              + XxcsoConstants.TOKEN_VALUE_DELIMITER1
              + XxcsoSpDecisionConstants.TOKEN_VALUE_COMMENT;

      errorList
        = utils.checkIllegalString(
            errorList
           ,sendRow.getApprovalComment()
           ,token1
           ,index
          );

      String approvalStateType = sendRow.getApprovalStateType();
      if ( XxcsoSpDecisionConstants.APPR_DURING.equals(approvalStateType) )
      {
        currentAuthLevel = sendRow.getApprAuthLevelNumber();
      }
      
      sendRow = (XxcsoSpDecisionSendFullVORowImpl)sendVo.next();
    }

    if ( ! submitFlag )
    {
      return errorList;
    }

    OracleCallableStatement stmt = null;
    NUMBER lastApprAuthLevel = NUMBER.zero();
    StringBuffer sql = new StringBuffer(100);

    try
    {
      NUMBER returnValue = null;
      int checkValue = 0;
      
      /////////////////////////////////////
      // 承認権限レベル番号１
      /////////////////////////////////////
      sql.append("BEGIN");
      sql.append("  :1 := xxcso_020001j_pkg.get_appr_auth_level_num_1(");
      sql.append("          :2, :3, :4, :5");
      sql.append("        );");
      sql.append("END;");

      XxcsoUtils.debug(txn, "execute = " + sql.toString());
      
      stmt
        = (OracleCallableStatement)
            txn.createCallableStatement(sql.toString(), 0);
        
      String condBizType = headerRow.getConditionBusinessType();
      String allContainerType = headerRow.getAllContainerType();
      
      if ( XxcsoSpDecisionConstants.COND_SALES.equals(condBizType)           ||
           XxcsoSpDecisionConstants.COND_SALES_CONTRIBUTE.equals(condBizType)
         )
      {
        scRow = (XxcsoSpDecisionScLineFullVORowImpl)scVo.first();
        while ( scRow != null )
        {
          stmt.registerOutParameter(1, OracleTypes.NUMBER);
          stmt.setString(2, scRow.getFixedPrice());
          stmt.setString(3, scRow.getSalesPrice());
          stmt.setNull(4, OracleTypes.VARCHAR);
          stmt.setString(5, scRow.getBmConvRatePerSalesPrice());

          stmt.execute();

          returnValue = stmt.getNUMBER(1);
          XxcsoUtils.debug(
            txn, "return = " + returnValue.stringValue()
          );

          XxcsoUtils.debug(
            txn, "lastApprAuthLevel = " + lastApprAuthLevel.stringValue()
          );

          checkValue = returnValue.compareTo(lastApprAuthLevel);
          XxcsoUtils.debug(
            txn, "return.comareTo(lastApprAuthLevel) = " + checkValue
          );
          
          if ( checkValue > 0 )
          {
            lastApprAuthLevel = returnValue;
          }

          scRow = (XxcsoSpDecisionScLineFullVORowImpl)scVo.next();
        }
      }

      if ( XxcsoSpDecisionConstants.COND_CNTNR.equals(condBizType)           ||
           XxcsoSpDecisionConstants.COND_CNTNR_CONTRIBUTE.equals(condBizType)
         )
      {
        if ( XxcsoSpDecisionConstants.CNTNR_ALL.equals(allContainerType) )
        {
          allCcRow = (XxcsoSpDecisionAllCcLineFullVORowImpl)allCcVo.first();
          while ( allCcRow != null )
          {
            String discountAmt = allCcRow.getDiscountAmt();
            if ( discountAmt == null || "".equals(discountAmt) )
            {
              allCcRow = (XxcsoSpDecisionAllCcLineFullVORowImpl)allCcVo.next();
              continue;
            }

            stmt.registerOutParameter(1, OracleTypes.NUMBER);
            stmt.setNull(2, OracleTypes.VARCHAR);
            stmt.setNull(3, OracleTypes.VARCHAR);
            stmt.setString(4, allCcRow.getDiscountAmt());
            stmt.setString(5, allCcRow.getBmConvRatePerSalesPrice());

            stmt.execute();

            returnValue = stmt.getNUMBER(1);
            XxcsoUtils.debug(
              txn, "return = " + returnValue.stringValue()
            );

            XxcsoUtils.debug(
              txn, "lastApprAuthLevel = " + lastApprAuthLevel.stringValue()
            );

            checkValue = returnValue.compareTo(lastApprAuthLevel);
            XxcsoUtils.debug(
              txn, "return.comareTo(lastApprAuthLevel) = " + checkValue
            );
          
            if ( checkValue > 0 )
            {
              lastApprAuthLevel = returnValue;
            }

            allCcRow = (XxcsoSpDecisionAllCcLineFullVORowImpl)allCcVo.next();
          }
        }
        else
        {
          selCcRow = (XxcsoSpDecisionSelCcLineFullVORowImpl)selCcVo.first();
          while ( selCcRow != null )
          {
            String discountAmt = selCcRow.getDiscountAmt();
            if ( discountAmt == null || "".equals(discountAmt) )
            {
              selCcRow = (XxcsoSpDecisionSelCcLineFullVORowImpl)selCcVo.next();
              continue;
            }

            stmt.registerOutParameter(1, OracleTypes.NUMBER);
            stmt.setNull(2, OracleTypes.VARCHAR);
            stmt.setNull(3, OracleTypes.VARCHAR);
            stmt.setString(4, selCcRow.getDiscountAmt());
            stmt.setString(5, selCcRow.getBmConvRatePerSalesPrice());

            stmt.execute();

            returnValue = stmt.getNUMBER(1);
            XxcsoUtils.debug(
              txn, "return = " + returnValue.stringValue()
            );

            XxcsoUtils.debug(
              txn, "lastApprAuthLevel = " + lastApprAuthLevel.stringValue()
            );

            checkValue = returnValue.compareTo(lastApprAuthLevel);
            XxcsoUtils.debug(
              txn, "return.comareTo(lastApprAuthLevel) = " + checkValue
            );
          
            if ( checkValue > 0 )
            {
              lastApprAuthLevel = returnValue;
            }

            selCcRow = (XxcsoSpDecisionSelCcLineFullVORowImpl)selCcVo.next();
          }
        }
      }

      if ( stmt != null )
      {
        stmt.close();
        stmt = null;
      }

      sql.delete(0, sql.length());

      /////////////////////////////////////
      // 承認権限レベル番号２
      /////////////////////////////////////
      sql.append("BEGIN");
      sql.append("  :1 := xxcso_020001j_pkg.get_appr_auth_level_num_2(:2);");
      sql.append("END;");

      XxcsoUtils.debug(txn, "execute = " + sql.toString());

      stmt
        = (OracleCallableStatement)
            txn.createCallableStatement(sql.toString(), 0);

      stmt.registerOutParameter(1, OracleTypes.NUMBER);
// 2014-12-15 [E_本稼動_12565] Mod Start
//      stmt.setString(2, headerRow.getInstallSupportAmt());
      stmt.setString(2, headerRow.getInstallSuppAmt());
// 2014-12-15 [E_本稼動_12565] Mod End

      stmt.execute();

      returnValue = stmt.getNUMBER(1);
      XxcsoUtils.debug(
        txn, "return = " + returnValue.stringValue()
      );

      XxcsoUtils.debug(
        txn, "lastApprAuthLevel = " + lastApprAuthLevel.stringValue()
      );

      checkValue = returnValue.compareTo(lastApprAuthLevel);
      XxcsoUtils.debug(
        txn, "return.comareTo(lastApprAuthLevel) = " + checkValue
      );
          
      if ( checkValue > 0 )
      {
        lastApprAuthLevel = returnValue;
      }

      if ( stmt != null )
      {
        stmt.close();
      }

      sql.delete(0, sql.length());

      /////////////////////////////////////
      // 承認権限レベル番号３
      /////////////////////////////////////
      String elecType = headerRow.getElectricityType();
      if ( XxcsoSpDecisionConstants.ELEC_FIXED.equals(elecType)    ||
           XxcsoSpDecisionConstants.ELEC_VALIABLE.equals(elecType)
         )
      {
        sql.append("BEGIN");
        sql.append("  :1 := xxcso_020001j_pkg.get_appr_auth_level_num_3(:2);");
        sql.append("END;");

        XxcsoUtils.debug(txn, "execute = " + sql.toString());

        stmt
          = (OracleCallableStatement)
              txn.createCallableStatement(sql.toString(), 0);

        stmt.registerOutParameter(1, OracleTypes.NUMBER);
        stmt.setString(2, headerRow.getElectricityAmount());

        stmt.execute();

        returnValue = stmt.getNUMBER(1);
        XxcsoUtils.debug(
          txn, "return = " + returnValue.stringValue()
        );

        XxcsoUtils.debug(
          txn, "lastApprAuthLevel = " + lastApprAuthLevel.stringValue()
        );

        checkValue = returnValue.compareTo(lastApprAuthLevel);
        XxcsoUtils.debug(
          txn, "return.comareTo(lastApprAuthLevel) = " + checkValue
        );
          
        if ( checkValue > 0 )
        {
          lastApprAuthLevel = returnValue;
        }

        if ( stmt != null )
        {
          stmt.close();
          stmt = null;
        }

        sql.delete(0, sql.length());
      }

      XxcsoUtils.debug(
        txn, "now authLevel = " + lastApprAuthLevel.stringValue()
      );

      /////////////////////////////////////
      // 承認権限レベル番号４
      /////////////////////////////////////
      sql.append("BEGIN");
      sql.append("  :1 := xxcso_020001j_pkg.get_appr_auth_level_num_4(:2);");
      sql.append("END;");

      XxcsoUtils.debug(txn, "execute = " + sql.toString());

      stmt
        = (OracleCallableStatement)
            txn.createCallableStatement(sql.toString(), 0);

      stmt.registerOutParameter(1, OracleTypes.NUMBER);
      stmt.setString(2, headerRow.getConstructionCharge());

      stmt.execute();

      returnValue = stmt.getNUMBER(1);
      XxcsoUtils.debug(
        txn, "return = " + returnValue.stringValue()
      );

      XxcsoUtils.debug(
        txn, "lastApprAuthLevel = " + lastApprAuthLevel.stringValue()
      );

      checkValue = returnValue.compareTo(lastApprAuthLevel);
      XxcsoUtils.debug(
        txn, "return.comareTo(lastApprAuthLevel) = " + checkValue
      );
          
      if ( checkValue > 0 )
      {
        lastApprAuthLevel = returnValue;
      }

      if ( stmt != null )
      {
        stmt.close();
        stmt = null;
      }

      sql.delete(0, sql.length());

// 2010-03-01 [E_本稼動_01678] Add Start
      /////////////////////////////////////
      // 承認権限レベル番号５
      /////////////////////////////////////
      sql.append("BEGIN");
      sql.append("  :1 := xxcso_020001j_pkg.get_appr_auth_level_num_5(");
      sql.append("          :2, :3, :4);");
      sql.append("END;");

      XxcsoUtils.debug(txn, "execute = " + sql.toString());

      stmt
        = (OracleCallableStatement)
            txn.createCallableStatement(sql.toString(), 0);

      stmt.registerOutParameter(1, OracleTypes.NUMBER);
      stmt.setString(2, bm1Row.getBmPaymentType());
      stmt.setString(3, bm2Row.getBmPaymentType());
      stmt.setString(4, bm3Row.getBmPaymentType());

      stmt.execute();

      returnValue = stmt.getNUMBER(1);
      XxcsoUtils.debug(
        txn, "return = " + returnValue.stringValue()
      );

      XxcsoUtils.debug(
        txn, "lastApprAuthLevel = " + lastApprAuthLevel.stringValue()
      );

      checkValue = returnValue.compareTo(lastApprAuthLevel);
          
      if ( checkValue > 0 )
      {
        lastApprAuthLevel = returnValue;
      }

      if ( stmt != null )
      {
        stmt.close();
      }

      sql.delete(0, sql.length());
// 2010-03-01 [E_本稼動_01678] Add End

// Ver.1.24 Add Start
      /////////////////////////////////////
      // 承認権限レベル番号６
      /////////////////////////////////////
      sql.append("BEGIN");
      sql.append("  :1 := xxcso_020001j_pkg.get_appr_auth_level_num_6(:2);");
      sql.append("END;");

      XxcsoUtils.debug(txn, "execute = " + sql.toString());

      stmt
        = (OracleCallableStatement)
            txn.createCallableStatement(sql.toString(), 0);

      stmt.registerOutParameter(1, OracleTypes.NUMBER);
      stmt.setString(2, headerRow.getAdAssetsAmt());

      stmt.execute();

      returnValue = stmt.getNUMBER(1);
      XxcsoUtils.debug(
        txn, "return = " + returnValue.stringValue()
      );

      XxcsoUtils.debug(
        txn, "lastApprAuthLevel = " + lastApprAuthLevel.stringValue()
      );

      checkValue = returnValue.compareTo(lastApprAuthLevel);
      XxcsoUtils.debug(
        txn, "return.comareTo(lastApprAuthLevel) = " + checkValue
      );
          
      if ( checkValue > 0 )
      {
        lastApprAuthLevel = returnValue;
      }

      if ( stmt != null )
      {
        stmt.close();
      }

      sql.delete(0, sql.length());
// Ver.1.24 Add End

      if ( lastApprAuthLevel.compareTo(NUMBER.zero()) == 0 )
      {
        /////////////////////////////////////
        // 承認権限レベル番号（デフォルト）
        /////////////////////////////////////
        sql.append("BEGIN");
        sql.append("  xxcso_020001j_pkg.get_appr_auth_level_num_0(");
        sql.append("    on_appr_auth_level_num => :1");
        sql.append("   ,ov_errbuf              => :2");
        sql.append("   ,ov_retcode             => :3");
        sql.append("   ,ov_errmsg              => :4");
        sql.append("  );");
        sql.append("END;");

        XxcsoUtils.debug(txn, "execute = " + sql.toString());

        stmt
          = (OracleCallableStatement)
              txn.createCallableStatement(sql.toString(), 0);

        stmt.registerOutParameter(1, OracleTypes.NUMBER);
        stmt.registerOutParameter(2, OracleTypes.VARCHAR);
        stmt.registerOutParameter(3, OracleTypes.VARCHAR);
        stmt.registerOutParameter(4, OracleTypes.VARCHAR);

        stmt.execute();

        returnValue = stmt.getNUMBER(1);
        String errBuf  = stmt.getString(2);
        String retCode = stmt.getString(3);
        String errMsg  = stmt.getString(4);
        
        XxcsoUtils.debug(
          txn, "return  = " + returnValue.stringValue()
        );
        XxcsoUtils.debug(txn, "errBuf  = " + errBuf);
        XxcsoUtils.debug(txn, "retCode = " + retCode);
        XxcsoUtils.debug(txn, "errMsg   = " + errMsg);

        if ( ! "0".equals(retCode) )
        {
          OAException error = XxcsoMessage.createErrorMessage(retCode);
          errorList.add(error);
        }
        else
        {
          lastApprAuthLevel = returnValue;
        }
      }
    }
    catch ( SQLException sqle )
    {
      XxcsoUtils.unexpected(txn, sqle);
      throw
        XxcsoMessage.createSqlErrorMessage(
          sqle
         ,XxcsoSpDecisionConstants.TOKEN_VALUE_APPR_AUTH_LEVEL_CHK
        );
    }
    finally
    {
      try
      {
        if ( stmt != null )
        {
          stmt.close();
        }
      }
      catch ( SQLException sqle )
      {
        XxcsoUtils.unexpected(txn, sqle);
      }
    }

    if ( errorList.size() > 0 )
    {
      return errorList;
    }

// 2009-08-06 [障害0000887] Add Start
// 2010-01-08 [E_本稼動_01030] Add Start
    // ステータスが承認依頼中の場合
    if ( XxcsoSpDecisionConstants.STATUS_APPROVE.equals(headerRow.getStatus()) )
    {
// 2010-01-08 [E_本稼動_01030] Add End
      if ( currentAuthLevel != null )
      {
        sendRow = (XxcsoSpDecisionSendFullVORowImpl)sendVo.first();
        boolean checkFlag = false;

        while ( sendRow != null )
        {
          Number checkAuthNumber = sendRow.getApprAuthLevelNumber();
          if ( checkAuthNumber.compareTo(currentAuthLevel) == 0 )
          {
            checkFlag = true;
          }

          if ( checkFlag )
          {
            String workRequestType = sendRow.getWorkRequestType();
            if ( XxcsoSpDecisionConstants.REQ_APPROVE.equals(workRequestType) )
            {
              int checkValue = checkAuthNumber.compareTo(lastApprAuthLevel);
              if ( checkValue > 0 )
              {
                lastApprAuthLevel = checkAuthNumber;
              }

              break;
            }
          }

          sendRow = (XxcsoSpDecisionSendFullVORowImpl)sendVo.next();
        }
      }
// 2010-01-08 [E_本稼動_01030] Add Start
    }
// 2010-01-08 [E_本稼動_01030] Add End
// 2009-08-06 [障害0000887] Add End

    XxcsoUtils.debug(
      txn, "last apprAuthLevel = " + lastApprAuthLevel.stringValue()
    );
    
    sendRow = (XxcsoSpDecisionSendFullVORowImpl)sendVo.first();
    boolean checkFlag = false;
    boolean existFlag = false;
    String lastApprAuthName = null;
    
    while ( sendRow != null )
    {
      // 承認権限レベルを取得する
      Number checkAuthNumber = sendRow.getApprAuthLevelNumber();
      XxcsoUtils.debug(
        txn, "checkAuthLevel = " + checkAuthNumber.stringValue()
      );
      
      if ( lastApprAuthLevel.compareTo(checkAuthNumber) == 0 )
      {
        // 最終承認レベル名を取得する
        lastApprAuthName = sendRow.getApprovalAuthorityName();
        
        // 承認権限レベルが判定用承認権限レベルと等しい場合、
        // 作業中の承認権限レベルと判定する
        if ( currentAuthLevel != null )
        {
          // 判定用承認権限レベルが作業中の承認権限レベルより
          // 小さい場合は、判定用承認権限レベルを作業中の承認権限レベルに
          // 設定する
          
          XxcsoUtils.debug(
            txn, "current authLevel = " + currentAuthLevel.stringValue()
          );

          int checkValue = lastApprAuthLevel.compareTo(currentAuthLevel);
          if ( checkValue < 0 )
          {
            lastApprAuthLevel = currentAuthLevel;
          }
        }

// 2011-04-04 v1.16 T.Yoshimoto Add Start E_本稼動_02496
        // 作業依頼区分を取得する
        String workRequestType = sendRow.getWorkRequestType();
        // 作業依頼区分が承認の場合、必須エラーとする
        if ( XxcsoSpDecisionConstants.REQ_APPROVE.equals(workRequestType) )
        {
          // 回送先社員番号を取得する
          String approveCode = sendRow.getApproveCode();
          if ( XxcsoSpDecisionConstants.INIT_APPROVE_CODE.equals(approveCode) )
          {
            String currentApprovalAutorityName = sendRow.getApprovalAuthorityName();
            OAException error
              = XxcsoMessage.createErrorMessage(
                  XxcsoConstants.APP_XXCSO1_00345
                 ,XxcsoConstants.TOKEN_ITEM
                 ,currentApprovalAutorityName
                );

            errorList.add(error);

          }
        }
// 2011-04-04 v1.16 T.Yoshimoto Add End E_本稼動_02496

        // 以降に有効回送先があるかどうかをチェックする
        checkFlag = true;
      }

      if ( ! checkFlag )
      {
// 2011-04-04 v1.16 T.Yoshimoto Add Start E_本稼動_02496
        // 作業依頼区分を取得する
        String workRequestType = sendRow.getWorkRequestType();
        // 作業依頼区分が承認の場合、必須エラーとする
        if ( XxcsoSpDecisionConstants.REQ_APPROVE.equals(workRequestType) )
        {
          // 回送先社員番号を取得する
          String approveCode = sendRow.getApproveCode();
          if ( XxcsoSpDecisionConstants.INIT_APPROVE_CODE.equals(approveCode) )
          {
            String currentApprovalAutorityName = sendRow.getApprovalAuthorityName();
            OAException error
              = XxcsoMessage.createErrorMessage(
                  XxcsoConstants.APP_XXCSO1_00345
                 ,XxcsoConstants.TOKEN_ITEM
                 ,currentApprovalAutorityName
                );
            errorList.add(error);
          }
        }
// 2011-04-04 v1.16 T.Yoshimoto Add End E_本稼動_02496
        // 有効チェックフラグが立っていない場合は、次のレコードへ
        sendRow = (XxcsoSpDecisionSendFullVORowImpl)sendVo.next();
        continue;
      }

      // 回送先社員番号を取得する
      String approveCode = sendRow.getApproveCode();
      if ( XxcsoSpDecisionConstants.INIT_APPROVE_CODE.equals(approveCode) )
      {
        // 回送先が省略の場合は、次のレコードへ
        sendRow = (XxcsoSpDecisionSendFullVORowImpl)sendVo.next();
        continue;
      }

      // 作業依頼区分を取得する
      String workRequestType = sendRow.getWorkRequestType();
      if ( XxcsoSpDecisionConstants.REQ_CONFIRM.equals(workRequestType) )
      {
        // 確認の場合は、次のレコードへ
        sendRow = (XxcsoSpDecisionSendFullVORowImpl)sendVo.next();
        continue;
      }

      // すべてのチェックを通った場合のみ、存在フラグを立てる
      existFlag = true;
      break;
    }

    if ( ! existFlag )
    {
      OAException error
        = XxcsoMessage.createErrorMessage(
            XxcsoConstants.APP_XXCSO1_00306
           ,XxcsoConstants.TOKEN_FORWARD
           ,lastApprAuthName
          );
      errorList.add(error);
    }
    
    XxcsoUtils.debug(txn, "[END]");

    return errorList;
  }



// 2010-01-15 [E_本稼動_00950] Add Start
  /*****************************************************************************
   * ＤＢ値の検証
   * @param txn         OADBTransactionインスタンス
   * @param headerVo    SP専決ヘッダ登録／更新用ビューインスタンス
   * @return List       エラーリスト
   *****************************************************************************
   */
  public static List validateDb(
    OADBTransaction                     txn
   ,XxcsoSpDecisionHeaderFullVOImpl     headerVo
  )
  {
    XxcsoUtils.debug(txn, "[START]");
    
    List errorList = new ArrayList();
   
    /////////////////////////////////////
    // 各行を取得
    /////////////////////////////////////
    XxcsoSpDecisionHeaderFullVORowImpl headerRow
      = (XxcsoSpDecisionHeaderFullVORowImpl)headerVo.first();

    XxcsoValidateUtils utils = XxcsoValidateUtils.getInstance(txn);

    // 新規登録の場合は処理終了。
    Number spDecisionHeaderId = headerRow.getSpDecisionHeaderId();
    if (spDecisionHeaderId.intValue() < 0)
    {
      return errorList;
    }

    // ＤＢ値チェック処理
    OracleCallableStatement stmt = null;
    String errBuf  = "";
    String retCode = "";
    String errMsg  = "";

    try
    {
      StringBuffer sql = new StringBuffer(100);
 
      sql.append("BEGIN");
      sql.append("  xxcso_020001j_pkg.chk_validate_db(");
      sql.append("    in_sp_decision_header_id      => :1");
      sql.append("   ,id_last_update_date           => :2");
      sql.append("   ,ov_errbuf                     => :3");
      sql.append("   ,ov_retcode                    => :4");
      sql.append("   ,ov_errmsg                     => :5");
      sql.append("  );");
      sql.append("END;");

      XxcsoUtils.debug(txn, "execute = " + sql.toString());

      stmt
        = (OracleCallableStatement)
            txn.createCallableStatement(sql.toString(), 0);

      stmt.setNUMBER(1, headerRow.getSpDecisionHeaderId());
      stmt.setDATE(2, headerRow.getLastUpdateDate());
      stmt.registerOutParameter(3, OracleTypes.VARCHAR);
      stmt.registerOutParameter(4, OracleTypes.VARCHAR);
      stmt.registerOutParameter(5, OracleTypes.VARCHAR);

      stmt.execute();

      errBuf  = stmt.getString(3);
      retCode = stmt.getString(4);
      errMsg  = stmt.getString(5);
      
      XxcsoUtils.debug(txn, "errBuf  = " + errBuf);
      XxcsoUtils.debug(txn, "retCode = " + retCode);
      XxcsoUtils.debug(txn, "errMsg  = " + errMsg);

    }
    catch ( SQLException e )
    {
      XxcsoUtils.unexpected(txn, e);
      throw
        XxcsoMessage.createSqlErrorMessage(
          e
         ,XxcsoSpDecisionConstants.TOKEN_VALUE_SITE_USE_CODE_CHK
        );
    }
    finally
    {
      try
      {
        if ( stmt != null )
        {
          stmt.close();
        }
      }
      catch ( SQLException e )
      {
        XxcsoUtils.unexpected(txn, e);
      }
    }

    if ( ! "0".equals(retCode) )
    {
        OAException error
          = XxcsoMessage.createErrorMessage(
              XxcsoConstants.APP_XXCSO1_00003
             ,XxcsoConstants.TOKEN_RECORD
             ,XxcsoConstants.TOKEN_VALUE_SP_DECISION_NUM +
              headerRow.getSpDecisionNumber()
            );
        errorList.add(error);
    }

    XxcsoUtils.debug(txn, "[END]");

    return errorList;
  }
// 2010-01-15 [E_本稼動_00950] Add End



  /*****************************************************************************
   * 売価別条件の検証
   * @param txn         OADBTransactionインスタンス
   * @param headerVo    SP専決ヘッダ登録／更新用ビューインスタンス
   * @param scVo        売価別条件登録／更新用ビューインスタンス
   * @param submitFlag  提出用フラグ
   * @return List       エラーリスト
   *****************************************************************************
   */
  public static List validateScLine(
    OADBTransaction                     txn
   ,XxcsoSpDecisionHeaderFullVOImpl     headerVo
   ,XxcsoSpDecisionScLineFullVOImpl     scVo
   ,boolean                             submitFlag
  )
  {
    XxcsoUtils.debug(txn, "[START]");

// 2014-01-31 [E_本稼動_11397] Add Start
    XxcsoValidateUtils utils = XxcsoValidateUtils.getInstance(txn);
// 2014-01-31 [E_本稼動_11397] Add End    
    List errorList = new ArrayList();
    List fixedPriceList = new ArrayList();
    List salesPriceList = new ArrayList();
    List repeatFixedPriceList = new ArrayList();
    List repeatSalesPriceList = new ArrayList();

    /////////////////////////////////////
    // 各行を取得
    /////////////////////////////////////
    XxcsoSpDecisionHeaderFullVORowImpl headerRow
      = (XxcsoSpDecisionHeaderFullVORowImpl)headerVo.first();
    XxcsoSpDecisionScLineFullVORowImpl scRow
      = (XxcsoSpDecisionScLineFullVORowImpl)scVo.first();

    int index = 0;
    String condBizType = headerRow.getConditionBusinessType();
    boolean contributeFlag = false;
    
    if ( XxcsoSpDecisionConstants.COND_SALES_CONTRIBUTE.equals(condBizType) )
    {
      contributeFlag = true;
    }

    /////////////////////////////////
    // 数値・必須チェック
    /////////////////////////////////
    while ( scRow != null )
    {
      index++;
      String fixedPrice = scRow.getFixedPrice();
      String salesPrice = scRow.getSalesPrice();
      String bm1BmRate  = scRow.getBm1BmRate();
      String bm1BmAmt   = scRow.getBm1BmAmount();
      String bm2BmRate  = scRow.getBm2BmRate();
      String bm2BmAmt   = scRow.getBm2BmAmount();
      String bm3BmRate  = scRow.getBm3BmRate();
      String bm3BmAmt   = scRow.getBm3BmAmount();
// 2014-01-31 [E_本稼動_11397] Add Start
      String cardSaleClass = scRow.getCardSaleClass();
// 2014-01-31 [E_本稼動_11397] Add End

      errorList.addAll(
        validateFixedPrice(txn, fixedPrice, submitFlag, index)
      );
      errorList.addAll(
        validateSalesPrice(txn, salesPrice, submitFlag, index)
      );
      errorList.addAll(
        validateBm1BmRate(txn, bm1BmRate, submitFlag, index)
      );
      errorList.addAll(
        validateBm1BmAmt(txn, bm1BmAmt, submitFlag, index)
      );
      errorList.addAll(
        validateBm2BmRate(txn, bm2BmRate, contributeFlag, submitFlag, index)
      );
      errorList.addAll(
        validateBm2BmAmt(txn, bm2BmAmt, contributeFlag, submitFlag, index)
      );
      errorList.addAll(
        validateBm3BmRate(txn, bm3BmRate, submitFlag, index)
      );
      errorList.addAll(
        validateBm3BmAmt(txn, bm3BmAmt, submitFlag, index)
      );
// 2014-01-31 [E_本稼動_11397] Add Start
      errorList
        = utils.requiredCheck(
              errorList
             ,cardSaleClass
             ,XxcsoSpDecisionConstants.TOKEN_VALUE_CARD_SALE_CLASS
             ,index
            );
// 2014-01-31 [E_本稼動_11397] Add End

      if ( ! submitFlag )
      {
        scRow = (XxcsoSpDecisionScLineFullVORowImpl)scVo.next();
        continue;
      }
      
      if ( (bm1BmRate == null || "".equals(bm1BmRate.trim())) &&
           (bm2BmRate == null || "".equals(bm2BmRate.trim())) &&
           (bm3BmRate == null || "".equals(bm3BmRate.trim())) &&
           (bm1BmAmt  == null || "".equals(bm1BmAmt.trim()))  &&
           (bm2BmAmt  == null || "".equals(bm2BmAmt.trim()))  &&
           (bm3BmAmt  == null || "".equals(bm3BmAmt.trim()))
         )
      {
// 課題一覧No.73対応 START
//        OAException error = null;
//        if ( contributeFlag )
//        {
//          error
//            = XxcsoMessage.createErrorMessage(
//                XxcsoConstants.APP_XXCSO1_00480
//               ,XxcsoConstants.TOKEN_INDEX
//               ,String.valueOf(index)
//              );
//        }
//        else
//        {
//          error
//            = XxcsoMessage.createErrorMessage(
//                XxcsoConstants.APP_XXCSO1_00289
//               ,XxcsoConstants.TOKEN_INDEX
//               ,String.valueOf(index)
//              );
//        }
//        
//        errorList.add(error);
// 課題一覧No.73対応 END
      }
      else
      {
// 課題一覧No.73対応 START
//        if ( bm1BmRate != null      &&
//             ! "".equals(bm1BmRate) &&
//             bm1BmAmt  != null      &&
//             ! "".equals(bm1BmAmt)
//           )
//        {
//          OAException error
//            = XxcsoMessage.createErrorMessage(
//                XxcsoConstants.APP_XXCSO1_00489
//               ,XxcsoConstants.TOKEN_REGION
//               ,XxcsoSpDecisionConstants.TOKEN_VALUE_BM1_REGION
//               ,XxcsoConstants.TOKEN_INDEX
//               ,String.valueOf(index)
//              );
//          errorList.add(error);
//        }
//
//        if ( bm2BmRate != null      &&
//             ! "".equals(bm2BmRate) &&
//             bm2BmAmt  != null      &&
//             ! "".equals(bm2BmAmt)
//           )
//        {
//          OAException error = null;
//
//          if ( contributeFlag )
//          {
//            error
//              = XxcsoMessage.createErrorMessage(
//                  XxcsoConstants.APP_XXCSO1_00489
//                 ,XxcsoConstants.TOKEN_REGION
//                 ,XxcsoSpDecisionConstants.TOKEN_VALUE_CONTRIBUTE_REGION
//                 ,XxcsoConstants.TOKEN_INDEX
//                 ,String.valueOf(index)
//                );
//          }
//          else
//          {
//            error
//              = XxcsoMessage.createErrorMessage(
//                  XxcsoConstants.APP_XXCSO1_00489
//                 ,XxcsoConstants.TOKEN_REGION
//                 ,XxcsoSpDecisionConstants.TOKEN_VALUE_BM2_REGION
//                 ,XxcsoConstants.TOKEN_INDEX
//                 ,String.valueOf(index)
//                );
//          }
//          errorList.add(error);
//        }
//
//        if ( bm3BmRate != null      &&
//             ! "".equals(bm3BmRate) &&
//             bm3BmAmt  != null      &&
//             ! "".equals(bm3BmAmt)
//           )
//        {
//          OAException error
//            = XxcsoMessage.createErrorMessage(
//                XxcsoConstants.APP_XXCSO1_00489
//               ,XxcsoConstants.TOKEN_REGION
//               ,XxcsoSpDecisionConstants.TOKEN_VALUE_BM3_REGION
//               ,XxcsoConstants.TOKEN_INDEX
//               ,String.valueOf(index)
//              );
//          errorList.add(error);
//        }

        if ( isBothBmValue(txn, bm1BmRate, bm1BmAmt) )
        {
          OAException error
            = XxcsoMessage.createErrorMessage(
                XxcsoConstants.APP_XXCSO1_00489
               ,XxcsoConstants.TOKEN_REGION
               ,XxcsoSpDecisionConstants.TOKEN_VALUE_BM1_REGION
               ,XxcsoConstants.TOKEN_INDEX
               ,String.valueOf(index)
              );
          errorList.add(error);
        }

        if ( isBothBmValue(txn, bm2BmRate, bm2BmAmt) )
        {
          OAException error = null;

          if ( contributeFlag )
          {
            error
              = XxcsoMessage.createErrorMessage(
                  XxcsoConstants.APP_XXCSO1_00489
                 ,XxcsoConstants.TOKEN_REGION
                 ,XxcsoSpDecisionConstants.TOKEN_VALUE_CONTRIBUTE_REGION
                 ,XxcsoConstants.TOKEN_INDEX
                 ,String.valueOf(index)
                );
          }
          else
          {
            error
              = XxcsoMessage.createErrorMessage(
                  XxcsoConstants.APP_XXCSO1_00489
                 ,XxcsoConstants.TOKEN_REGION
                 ,XxcsoSpDecisionConstants.TOKEN_VALUE_BM2_REGION
                 ,XxcsoConstants.TOKEN_INDEX
                 ,String.valueOf(index)
                );
          }
          errorList.add(error);
        }

        if ( isBothBmValue(txn, bm3BmRate, bm3BmAmt) )
        {
          OAException error
            = XxcsoMessage.createErrorMessage(
                XxcsoConstants.APP_XXCSO1_00489
               ,XxcsoConstants.TOKEN_REGION
               ,XxcsoSpDecisionConstants.TOKEN_VALUE_BM3_REGION
               ,XxcsoConstants.TOKEN_INDEX
               ,String.valueOf(index)
              );
          errorList.add(error);
        }
// 課題一覧No.73対応 END
      }
      
      scRow = (XxcsoSpDecisionScLineFullVORowImpl)scVo.next();
    }

    if ( index == 0 )
    {
      OAException error
        = XxcsoMessage.createErrorMessage(
            XxcsoConstants.APP_XXCSO1_00491
          );
      errorList.add(error);
    }
    
    if ( errorList.size() > 0 )
    {
      return errorList;
    }

    if ( ! submitFlag )
    {
      return errorList;
    }
    
    index = 0;

    scRow = (XxcsoSpDecisionScLineFullVORowImpl)scVo.first();

    /////////////////////////////////
    // 重複チェック
    /////////////////////////////////
    while ( scRow != null )
    {
      index++;
      String fixedPrice = scRow.getFixedPrice().replaceAll(",","");
// 2014-01-31 [E_本稼動_11397] Add Start
      String cardSaleclass = scRow.getCardSaleClass();
      String chkStr = fixedPrice + cardSaleclass;
      String tokenValCardSale = "";
// 2014-01-31 [E_本稼動_11397] Add End
// 2014-01-31 [E_本稼動_11397] Mod Start
//      if ( fixedPriceList.contains(fixedPrice) )
//      {
//        if ( ! repeatFixedPriceList.contains(fixedPrice) )
//        {
//          repeatFixedPriceList.add(fixedPrice);
//        }
//
//        OAException error
//          = XxcsoMessage.createErrorMessage(
//              XxcsoConstants.APP_XXCSO1_00425
//             ,XxcsoConstants.TOKEN_PRICE
//             ,fixedPrice
//            );

//        errorList.add(error);
      if ( fixedPriceList.contains(chkStr) )
      {
        //既に同一の組み合わせでエラーリストに登録されているものは除外
        if ( ! repeatFixedPriceList.contains(chkStr) )
        {
          //メッセージ編集
          if ( XxcsoSpDecisionConstants.CARD_SALE_CLASS_SALE.equals(cardSaleclass) )
          {
            tokenValCardSale = XxcsoSpDecisionConstants.TOKEN_VALUE_CARD_SALE_CLASS_SALE; //現金
          }
          else
          {
            tokenValCardSale = XxcsoSpDecisionConstants.TOKEN_VALUE_CARD_SALE_CLASS_CARD; //カード
          }

          OAException error
            = XxcsoMessage.createErrorMessage(
                XxcsoConstants.APP_XXCSO1_00425
               ,XxcsoConstants.TOKEN_PRICE
               ,fixedPrice
               ,XxcsoConstants.TOKEN_CARD_SALE
               ,tokenValCardSale
              );

          errorList.add(error);

          repeatFixedPriceList.add(chkStr);          
        }
// 2014-01-31 [E_本稼動_11397] Mod End
      }
      else
      {
// 2014-01-31 [E_本稼動_11397] Mod Start
//        fixedPriceList.add(fixedPrice);
        fixedPriceList.add(chkStr);
// 2014-01-31 [E_本稼動_11397] Mod End
      }
      
      String salesPrice = scRow.getSalesPrice().replaceAll(",","");
      if ( salesPriceList.contains(salesPrice) )
      {
        if ( ! repeatSalesPriceList.contains(salesPrice) )
        {
// 2014-01-31 [E_本稼動_11397] Del Start
//          repeatSalesPriceList.add(salesPrice);
//        }
// 2014-01-31 [E_本稼動_11397] Del End

          OAException error
            = XxcsoMessage.createErrorMessage(
                XxcsoConstants.APP_XXCSO1_00426
               ,XxcsoConstants.TOKEN_PRICE
               ,salesPrice
              );

          errorList.add(error);
// 2014-01-31 [E_本稼動_11397] Add Start
          repeatSalesPriceList.add(salesPrice);
        }
// 2014-01-31 [E_本稼動_11397] Add End
      }
      else
      {
        salesPriceList.add(salesPrice);
      }
      
      scRow = (XxcsoSpDecisionScLineFullVORowImpl)scVo.next();
    }

    if ( errorList.size() > 0 )
    {
      return errorList;
    }

    index = 0;

    scRow = (XxcsoSpDecisionScLineFullVORowImpl)scVo.first();

    /////////////////////////////////
    // 合計値チェック
    /////////////////////////////////
    while ( scRow != null )
    {
      index++;
      String salesPrice = scRow.getSalesPrice();
      String bm1BmRate  = scRow.getBm1BmRate();
      String bm1BmAmt   = scRow.getBm1BmAmount();
      String bm2BmRate  = scRow.getBm2BmRate();
      String bm2BmAmt   = scRow.getBm2BmAmount();
      String bm3BmRate  = scRow.getBm3BmRate();
      String bm3BmAmt   = scRow.getBm3BmAmount();

      if ( ! isLimitTotalValue(
               bm1BmRate
              ,bm2BmRate
              ,bm3BmRate
              ,String.valueOf(100)
             )
         )
      {
        OAException error = null;
        if ( contributeFlag )
        {
          error
            = XxcsoMessage.createErrorMessage(
                XxcsoConstants.APP_XXCSO1_00481
               ,XxcsoConstants.TOKEN_INDEX
               ,String.valueOf(index)
              );
          
        }
        else
        {
          error
            = XxcsoMessage.createErrorMessage(
                XxcsoConstants.APP_XXCSO1_00291
               ,XxcsoConstants.TOKEN_INDEX
               ,String.valueOf(index)
              );
        }

        errorList.add(error);
      }

      if ( ! isLimitTotalValue(
               bm1BmAmt
              ,bm2BmAmt
              ,bm3BmAmt
              ,salesPrice
             )
         )
      {
        OAException error = null;
        if ( contributeFlag )
        {
          error
            = XxcsoMessage.createErrorMessage(
                XxcsoConstants.APP_XXCSO1_00482
               ,XxcsoConstants.TOKEN_INDEX
               ,String.valueOf(index)
              );
        }
        else
        {
          error
            = XxcsoMessage.createErrorMessage(
                XxcsoConstants.APP_XXCSO1_00292
               ,XxcsoConstants.TOKEN_INDEX
               ,String.valueOf(index)
              );
        }

        errorList.add(error);
      }
      
      scRow = (XxcsoSpDecisionScLineFullVORowImpl)scVo.next();
    }
    
    XxcsoUtils.debug(txn, "[END]");

    return errorList;
  }



  /*****************************************************************************
   * 全容器一律条件の検証
   * @param txn         OADBTransactionインスタンス
   * @param headerVo    SP専決ヘッダ登録／更新用ビューインスタンス
   * @param allCcVo     全容器一律条件登録／更新用ビューインスタンス
   * @param submitFlag  提出用フラグ
   * @return List       エラーリスト
   *****************************************************************************
   */
  public static List validateAllCcLine(
    OADBTransaction                     txn
   ,XxcsoSpDecisionHeaderFullVOImpl     headerVo
   ,XxcsoSpDecisionAllCcLineFullVOImpl  allCcVo
   ,boolean                             submitFlag
  )
  {
    XxcsoUtils.debug(txn, "[START]");
    
    List errorList = new ArrayList();

    /////////////////////////////////////
    // 各行を取得
    /////////////////////////////////////
    XxcsoSpDecisionHeaderFullVORowImpl headerRow
      = (XxcsoSpDecisionHeaderFullVORowImpl)headerVo.first();
    XxcsoSpDecisionAllCcLineFullVORowImpl allCcRow
      = (XxcsoSpDecisionAllCcLineFullVORowImpl)allCcVo.first();

    int index = 0;
    String condBizType = headerRow.getConditionBusinessType();
    boolean contributeFlag = false;
    
    if ( XxcsoSpDecisionConstants.COND_CNTNR_CONTRIBUTE.equals(condBizType) )
    {
      contributeFlag = true;
    }

    int nullLineCount = 0;
    
    /////////////////////////////////
    // 数値・必須チェック
    /////////////////////////////////
    while ( allCcRow != null )
    {
      index++;
      String discountAmt = allCcRow.getDiscountAmt();
      String bm1BmRate = allCcRow.getBm1BmRate();
      String bm1BmAmt  = allCcRow.getBm1BmAmount();
      String bm2BmRate = allCcRow.getBm2BmRate();
      String bm2BmAmt  = allCcRow.getBm2BmAmount();
      String bm3BmRate = allCcRow.getBm3BmRate();
      String bm3BmAmt  = allCcRow.getBm3BmAmount();

      errorList.addAll(
        validateDiscountAmt(txn, discountAmt, submitFlag, index)
      );
      errorList.addAll(
        validateBm1BmRate(txn, bm1BmRate, submitFlag, index)
      );
      errorList.addAll(
        validateBm1BmAmt(txn, bm1BmAmt, submitFlag, index)
      );
      errorList.addAll(
        validateBm2BmRate(txn, bm2BmRate, contributeFlag, submitFlag, index)
      );
      errorList.addAll(
        validateBm2BmAmt(txn, bm2BmAmt, contributeFlag, submitFlag, index)
      );
      errorList.addAll(
        validateBm3BmRate(txn, bm3BmRate, submitFlag, index)
      );
      errorList.addAll(
        validateBm3BmAmt(txn, bm3BmAmt, submitFlag, index)
      );

      if ( ! submitFlag )
      {
        allCcRow = (XxcsoSpDecisionAllCcLineFullVORowImpl)allCcVo.next();
        continue;
      }
      
// 課題一覧No.73対応 START
//      if ( (bm1BmRate   == null || "".equals(bm1BmRate.trim()))   &&
//           (bm2BmRate   == null || "".equals(bm2BmRate.trim()))   &&
//           (bm3BmRate   == null || "".equals(bm3BmRate.trim()))   &&
//           (bm1BmAmt    == null || "".equals(bm1BmAmt.trim()))    &&
//           (bm2BmAmt    == null || "".equals(bm2BmAmt.trim()))    &&
//           (bm3BmAmt    == null || "".equals(bm3BmAmt.trim()))    &&
//           (discountAmt == null || "".equals(discountAmt.trim()))
//         )
//      {
//        nullLineCount++;
//      }
// 課題一覧No.73対応 END
      
      if ( (bm1BmRate == null || "".equals(bm1BmRate.trim())) &&
           (bm2BmRate == null || "".equals(bm2BmRate.trim())) &&
           (bm3BmRate == null || "".equals(bm3BmRate.trim())) &&
           (bm1BmAmt  == null || "".equals(bm1BmAmt.trim()))  &&
           (bm2BmAmt  == null || "".equals(bm2BmAmt.trim()))  &&
           (bm3BmAmt  == null || "".equals(bm3BmAmt.trim()))
         )
      {
        if ( discountAmt != null && ! "".equals(discountAmt) )
        {
          OAException error = null;
          if ( contributeFlag )
          {
            error
              = XxcsoMessage.createErrorMessage(
                  XxcsoConstants.APP_XXCSO1_00483
                 ,XxcsoConstants.TOKEN_INDEX
                 ,String.valueOf(index)
                );
          }
          else
          {
            error
              = XxcsoMessage.createErrorMessage(
                  XxcsoConstants.APP_XXCSO1_00294
                 ,XxcsoConstants.TOKEN_INDEX
                 ,String.valueOf(index)
                );
          }

          errorList.add(error);
        }
      }
      else
      {
// 課題一覧No.73対応 START
//        if ( discountAmt == null || "".equals(discountAmt.trim()) )
//        {
//          OAException error = null;
//          if ( contributeFlag )
//          {
//            error
//              = XxcsoMessage.createErrorMessage(
//                  XxcsoConstants.APP_XXCSO1_00484
//                 ,XxcsoConstants.TOKEN_INDEX
//                 ,String.valueOf(index)
//                );
//          }
//          else
//          {
//            error
//              = XxcsoMessage.createErrorMessage(
//                  XxcsoConstants.APP_XXCSO1_00295
//                 ,XxcsoConstants.TOKEN_INDEX
//                 ,String.valueOf(index)
//                );
//          }
//
//          errorList.add(error);
//        }
// 課題一覧No.73対応 END

// 課題一覧No.73対応 START
//        if ( bm1BmRate != null      &&
//             ! "".equals(bm1BmRate) &&
//             bm1BmAmt  != null      &&
//             ! "".equals(bm1BmAmt)
//           )
//        {
//          OAException error
//            = XxcsoMessage.createErrorMessage(
//                XxcsoConstants.APP_XXCSO1_00489
//               ,XxcsoConstants.TOKEN_REGION
//               ,XxcsoSpDecisionConstants.TOKEN_VALUE_BM1_REGION
//               ,XxcsoConstants.TOKEN_INDEX
//               ,String.valueOf(index)
//              );
//          errorList.add(error);
//        }
//
//        if ( bm2BmRate != null      &&
//             ! "".equals(bm2BmRate) &&
//             bm2BmAmt  != null      &&
//             ! "".equals(bm2BmAmt)
//           )
//        {
//          OAException error = null;
//
//          if ( contributeFlag )
//          {
//            error
//              = XxcsoMessage.createErrorMessage(
//                  XxcsoConstants.APP_XXCSO1_00489
//                 ,XxcsoConstants.TOKEN_REGION
//                 ,XxcsoSpDecisionConstants.TOKEN_VALUE_CONTRIBUTE_REGION
//                 ,XxcsoConstants.TOKEN_INDEX
//                 ,String.valueOf(index)
//                );
//          }
//          else
//          {
//            error
//              = XxcsoMessage.createErrorMessage(
//                  XxcsoConstants.APP_XXCSO1_00489
//                 ,XxcsoConstants.TOKEN_REGION
//                 ,XxcsoSpDecisionConstants.TOKEN_VALUE_BM2_REGION
//                 ,XxcsoConstants.TOKEN_INDEX
//                 ,String.valueOf(index)
//                );
//          }
//          errorList.add(error);
//        }
//
//        if ( bm3BmRate != null      &&
//             ! "".equals(bm3BmRate) &&
//             bm3BmAmt  != null      &&
//             ! "".equals(bm3BmAmt)
//           )
//        {
//          OAException error
//            = XxcsoMessage.createErrorMessage(
//                XxcsoConstants.APP_XXCSO1_00489
//               ,XxcsoConstants.TOKEN_REGION
//               ,XxcsoSpDecisionConstants.TOKEN_VALUE_BM3_REGION
//               ,XxcsoConstants.TOKEN_INDEX
//               ,String.valueOf(index)
//              );
//          errorList.add(error);
//        }

        if ( isBothBmValue(txn, bm1BmRate, bm1BmAmt) )
        {
          OAException error
            = XxcsoMessage.createErrorMessage(
                XxcsoConstants.APP_XXCSO1_00489
               ,XxcsoConstants.TOKEN_REGION
               ,XxcsoSpDecisionConstants.TOKEN_VALUE_BM1_REGION
               ,XxcsoConstants.TOKEN_INDEX
               ,String.valueOf(index)
              );
          errorList.add(error);
        }

        if ( isBothBmValue(txn, bm2BmRate, bm2BmAmt) )
        {
          OAException error = null;

          if ( contributeFlag )
          {
            error
              = XxcsoMessage.createErrorMessage(
                  XxcsoConstants.APP_XXCSO1_00489
                 ,XxcsoConstants.TOKEN_REGION
                 ,XxcsoSpDecisionConstants.TOKEN_VALUE_CONTRIBUTE_REGION
                 ,XxcsoConstants.TOKEN_INDEX
                 ,String.valueOf(index)
                );
          }
          else
          {
            error
              = XxcsoMessage.createErrorMessage(
                  XxcsoConstants.APP_XXCSO1_00489
                 ,XxcsoConstants.TOKEN_REGION
                 ,XxcsoSpDecisionConstants.TOKEN_VALUE_BM2_REGION
                 ,XxcsoConstants.TOKEN_INDEX
                 ,String.valueOf(index)
                );
          }
          errorList.add(error);
        }

        if ( isBothBmValue(txn, bm3BmRate, bm3BmAmt) )
        {
          OAException error
            = XxcsoMessage.createErrorMessage(
                XxcsoConstants.APP_XXCSO1_00489
               ,XxcsoConstants.TOKEN_REGION
               ,XxcsoSpDecisionConstants.TOKEN_VALUE_BM3_REGION
               ,XxcsoConstants.TOKEN_INDEX
               ,String.valueOf(index)
              );
          errorList.add(error);
        }
// 課題一覧No.73対応 END
      }

      allCcRow = (XxcsoSpDecisionAllCcLineFullVORowImpl)allCcVo.next();
    }

    if ( errorList.size() > 0 )
    {
      return errorList;
    }

    if ( ! submitFlag )
    {
      return errorList;
    }
    
// 課題一覧No.73対応 START
//    if ( allCcVo.getRowCount() == nullLineCount )
//    {
//      throw XxcsoMessage.createErrorMessage(XxcsoConstants.APP_XXCSO1_00293);
//    }
// 課題一覧No.73対応 END
    
    index = 0;

    allCcRow = (XxcsoSpDecisionAllCcLineFullVORowImpl)allCcVo.first();

    /////////////////////////////////
    // 合計値チェック
    /////////////////////////////////
    while ( allCcRow != null )
    {
      index++;
      String discountAmt = allCcRow.getDiscountAmt();
      Number fixedPrice  = allCcRow.getDefinedFixedPrice();
      String bm1BmRate   = allCcRow.getBm1BmRate();
      String bm1BmAmt    = allCcRow.getBm1BmAmount();
      String bm2BmRate   = allCcRow.getBm2BmRate();
      String bm2BmAmt    = allCcRow.getBm2BmAmount();
      String bm3BmRate   = allCcRow.getBm3BmRate();
      String bm3BmAmt    = allCcRow.getBm3BmAmount();

      if ( ! isLimitTotalValue(
               bm1BmRate
              ,bm2BmRate
              ,bm3BmRate
              ,String.valueOf(100)
             )
         )
      {
        OAException error = null;
        if ( contributeFlag )
        {
          error
            = XxcsoMessage.createErrorMessage(
                XxcsoConstants.APP_XXCSO1_00485
               ,XxcsoConstants.TOKEN_INDEX
               ,String.valueOf(index)
              );
        }
        else
        {
          error
            = XxcsoMessage.createErrorMessage(
                XxcsoConstants.APP_XXCSO1_00298
               ,XxcsoConstants.TOKEN_INDEX
               ,String.valueOf(index)
              );
        }

        errorList.add(error);
      }

      double discountAmtDoubleValue = (double)0;

      if ( discountAmt != null && ! "".equals(discountAmt) )
      {
        discountAmtDoubleValue
          = Double.parseDouble(discountAmt.replaceFirst(",",""));
      }

      double limitValue = discountAmtDoubleValue + fixedPrice.doubleValue();
      if ( limitValue <= (double)0 )
      {
        errorList.add(
          XxcsoMessage.createErrorMessage(
            XxcsoConstants.APP_XXCSO1_00530
           ,XxcsoConstants.TOKEN_INDEX
           ,String.valueOf(index)
          )
        );
      }
      else
      {
        if ( ! isLimitTotalValue(
                 bm1BmAmt
                ,bm2BmAmt
                ,bm3BmAmt
                ,String.valueOf(limitValue)
               )
           )
        {
          OAException error = null;
          if ( contributeFlag )
          {
            error
              = XxcsoMessage.createErrorMessage(
                  XxcsoConstants.APP_XXCSO1_00486
                 ,XxcsoConstants.TOKEN_PRICE
                 ,String.valueOf((int)limitValue)
                 ,XxcsoConstants.TOKEN_INDEX
                 ,String.valueOf(index)
                );
          }
          else
          {
            error
              = XxcsoMessage.createErrorMessage(
                  XxcsoConstants.APP_XXCSO1_00299
                 ,XxcsoConstants.TOKEN_PRICE
                 ,String.valueOf((int)limitValue)
                 ,XxcsoConstants.TOKEN_INDEX
                 ,String.valueOf(index)
                );
          }

          errorList.add(error);
        }
      }
      
      allCcRow = (XxcsoSpDecisionAllCcLineFullVORowImpl)allCcVo.next();
    }
    
    XxcsoUtils.debug(txn, "[END]");

    return errorList;
  }



  /*****************************************************************************
   * 容器別条件の検証
   * @param txn         OADBTransactionインスタンス
   * @param headerVo    SP専決ヘッダ登録／更新用ビューインスタンス
   * @param selCcVo     容器別条件登録／更新用ビューインスタンス
   * @param submitFlag  提出用フラグ
   * @return List       エラーリスト
   *****************************************************************************
   */
  public static List validateSelCcLine(
    OADBTransaction                     txn
   ,XxcsoSpDecisionHeaderFullVOImpl     headerVo
   ,XxcsoSpDecisionSelCcLineFullVOImpl  selCcVo
   ,boolean                             submitFlag
  )
  {
    XxcsoUtils.debug(txn, "[START]");
    
    List errorList = new ArrayList();

    /////////////////////////////////////
    // 各行を取得
    /////////////////////////////////////
    XxcsoSpDecisionHeaderFullVORowImpl headerRow
      = (XxcsoSpDecisionHeaderFullVORowImpl)headerVo.first();
    XxcsoSpDecisionSelCcLineFullVORowImpl selCcRow
      = (XxcsoSpDecisionSelCcLineFullVORowImpl)selCcVo.first();

    int index = 0;
    String condBizType = headerRow.getConditionBusinessType();
    boolean contributeFlag = false;
    
    if ( XxcsoSpDecisionConstants.COND_CNTNR_CONTRIBUTE.equals(condBizType) )
    {
      contributeFlag = true;
    }

    int nullLineCount = 0;
    
    /////////////////////////////////
    // 数値・必須チェック
    /////////////////////////////////
    while ( selCcRow != null )
    {
      index++;
      String discountAmt = selCcRow.getDiscountAmt();
      String bm1BmRate = selCcRow.getBm1BmRate();
      String bm1BmAmt  = selCcRow.getBm1BmAmount();
      String bm2BmRate = selCcRow.getBm2BmRate();
      String bm2BmAmt  = selCcRow.getBm2BmAmount();
      String bm3BmRate = selCcRow.getBm3BmRate();
      String bm3BmAmt  = selCcRow.getBm3BmAmount();

      errorList.addAll(
        validateDiscountAmt(txn, discountAmt, submitFlag, index)
      );
      errorList.addAll(
        validateBm1BmRate(txn, bm1BmRate, submitFlag, index)
      );
      errorList.addAll(
        validateBm1BmAmt(txn, bm1BmAmt, submitFlag, index)
      );
      errorList.addAll(
        validateBm2BmRate(txn, bm2BmRate, contributeFlag, submitFlag, index)
      );
      errorList.addAll(
        validateBm2BmAmt(txn, bm2BmAmt, contributeFlag, submitFlag, index)
      );
      errorList.addAll(
        validateBm3BmRate(txn, bm3BmRate, submitFlag, index)
      );
      errorList.addAll(
        validateBm3BmAmt(txn, bm3BmAmt, submitFlag, index)
      );

      if ( ! submitFlag )
      {
        selCcRow = (XxcsoSpDecisionSelCcLineFullVORowImpl)selCcVo.next();
        continue;
      }
      
// 課題一覧No.73対応 START
//      if ( (bm1BmRate   == null || "".equals(bm1BmRate.trim()))   &&
//           (bm2BmRate   == null || "".equals(bm2BmRate.trim()))   &&
//           (bm3BmRate   == null || "".equals(bm3BmRate.trim()))   &&
//           (bm1BmAmt    == null || "".equals(bm1BmAmt.trim()))    &&
//           (bm2BmAmt    == null || "".equals(bm2BmAmt.trim()))    &&
//           (bm3BmAmt    == null || "".equals(bm3BmAmt.trim()))    &&
//           (discountAmt == null || "".equals(discountAmt.trim()))
//         )
//      {
//        nullLineCount++;
//      }
// 課題一覧No.73対応 END
      
      if ( (bm1BmRate == null || "".equals(bm1BmRate.trim())) &&
           (bm2BmRate == null || "".equals(bm2BmRate.trim())) &&
           (bm3BmRate == null || "".equals(bm3BmRate.trim())) &&
           (bm1BmAmt  == null || "".equals(bm1BmAmt.trim()))  &&
           (bm2BmAmt  == null || "".equals(bm2BmAmt.trim()))  &&
           (bm3BmAmt  == null || "".equals(bm3BmAmt.trim()))
         )
      {
        if ( discountAmt != null && ! "".equals(discountAmt) )
        {
          OAException error = null;
          if ( contributeFlag )
          {
            error
              = XxcsoMessage.createErrorMessage(
                  XxcsoConstants.APP_XXCSO1_00483
                 ,XxcsoConstants.TOKEN_INDEX
                 ,String.valueOf(index)
                );
          }
          else
          {
            error
              = XxcsoMessage.createErrorMessage(
                  XxcsoConstants.APP_XXCSO1_00294
                 ,XxcsoConstants.TOKEN_INDEX
                 ,String.valueOf(index)
                );
          }

          errorList.add(error);
        }
      }
      else
      {
// 課題一覧No.73対応 START
//        if ( discountAmt == null || "".equals(discountAmt.trim()) )
//        {
//          OAException error = null;
//          
//          if ( contributeFlag )
//          {
//            error
//              = XxcsoMessage.createErrorMessage(
//                  XxcsoConstants.APP_XXCSO1_00484
//                 ,XxcsoConstants.TOKEN_INDEX
//                 ,String.valueOf(index)
//                );
//          }
//          else
//          {
//            error
//              = XxcsoMessage.createErrorMessage(
//                  XxcsoConstants.APP_XXCSO1_00295
//                 ,XxcsoConstants.TOKEN_INDEX
//                 ,String.valueOf(index)
//                );
//          }
//
//          errorList.add(error);
//        }
// 課題一覧No.73対応 END

// 課題一覧No.73対応 START
//        if ( bm1BmRate != null      &&
//             ! "".equals(bm1BmRate) &&
//             bm1BmAmt  != null      &&
//             ! "".equals(bm1BmAmt)
//           )
//        {
//          OAException error
//            = XxcsoMessage.createErrorMessage(
//                XxcsoConstants.APP_XXCSO1_00489
//               ,XxcsoConstants.TOKEN_REGION
//               ,XxcsoSpDecisionConstants.TOKEN_VALUE_BM1_REGION
//               ,XxcsoConstants.TOKEN_INDEX
//               ,String.valueOf(index)
//              );
//          errorList.add(error);
//        }
//
//        if ( bm2BmRate != null      &&
//             ! "".equals(bm2BmRate) &&
//             bm2BmAmt  != null      &&
//             ! "".equals(bm2BmAmt)
//           )
//        {
//          OAException error = null;
//
//          if ( contributeFlag )
//          {
//            error
//              = XxcsoMessage.createErrorMessage(
//                  XxcsoConstants.APP_XXCSO1_00489
//                 ,XxcsoConstants.TOKEN_REGION
//                 ,XxcsoSpDecisionConstants.TOKEN_VALUE_CONTRIBUTE_REGION
//                 ,XxcsoConstants.TOKEN_INDEX
//                 ,String.valueOf(index)
//                );
//          }
//          else
//          {
//            error
//              = XxcsoMessage.createErrorMessage(
//                  XxcsoConstants.APP_XXCSO1_00489
//                 ,XxcsoConstants.TOKEN_REGION
//                 ,XxcsoSpDecisionConstants.TOKEN_VALUE_BM2_REGION
//                 ,XxcsoConstants.TOKEN_INDEX
//                 ,String.valueOf(index)
//                );
//          }
//          errorList.add(error);
//        }
//
//        if ( bm3BmRate != null      &&
//             ! "".equals(bm3BmRate) &&
//             bm3BmAmt  != null      &&
//             ! "".equals(bm3BmAmt)
//           )
//        {
//          OAException error
//            = XxcsoMessage.createErrorMessage(
//                XxcsoConstants.APP_XXCSO1_00489
//               ,XxcsoConstants.TOKEN_REGION
//               ,XxcsoSpDecisionConstants.TOKEN_VALUE_BM3_REGION
//               ,XxcsoConstants.TOKEN_INDEX
//               ,String.valueOf(index)
//              );
//          errorList.add(error);
//        }

        if ( isBothBmValue(txn, bm1BmRate, bm1BmAmt) )
        {
          OAException error
            = XxcsoMessage.createErrorMessage(
                XxcsoConstants.APP_XXCSO1_00489
               ,XxcsoConstants.TOKEN_REGION
               ,XxcsoSpDecisionConstants.TOKEN_VALUE_BM1_REGION
               ,XxcsoConstants.TOKEN_INDEX
               ,String.valueOf(index)
              );
          errorList.add(error);
        }

        if ( isBothBmValue(txn, bm2BmRate, bm2BmAmt) )
        {
          OAException error = null;

          if ( contributeFlag )
          {
            error
              = XxcsoMessage.createErrorMessage(
                  XxcsoConstants.APP_XXCSO1_00489
                 ,XxcsoConstants.TOKEN_REGION
                 ,XxcsoSpDecisionConstants.TOKEN_VALUE_CONTRIBUTE_REGION
                 ,XxcsoConstants.TOKEN_INDEX
                 ,String.valueOf(index)
                );
          }
          else
          {
            error
              = XxcsoMessage.createErrorMessage(
                  XxcsoConstants.APP_XXCSO1_00489
                 ,XxcsoConstants.TOKEN_REGION
                 ,XxcsoSpDecisionConstants.TOKEN_VALUE_BM2_REGION
                 ,XxcsoConstants.TOKEN_INDEX
                 ,String.valueOf(index)
                );
          }
          errorList.add(error);
        }

        if ( isBothBmValue(txn, bm3BmRate, bm3BmAmt) )
        {
          OAException error
            = XxcsoMessage.createErrorMessage(
                XxcsoConstants.APP_XXCSO1_00489
               ,XxcsoConstants.TOKEN_REGION
               ,XxcsoSpDecisionConstants.TOKEN_VALUE_BM3_REGION
               ,XxcsoConstants.TOKEN_INDEX
               ,String.valueOf(index)
              );
          errorList.add(error);
        }
// 課題一覧No.73対応 END
      }
      
      selCcRow = (XxcsoSpDecisionSelCcLineFullVORowImpl)selCcVo.next();
    }

    if ( errorList.size() > 0 )
    {
      return errorList;
    }

    if ( ! submitFlag )
    {
      return errorList;
    }
    
    if ( selCcVo.getRowCount() == nullLineCount )
    {
      throw XxcsoMessage.createErrorMessage(XxcsoConstants.APP_XXCSO1_00293);
    }
    
    index = 0;

    selCcRow = (XxcsoSpDecisionSelCcLineFullVORowImpl)selCcVo.first();

    /////////////////////////////////
    // 合計値チェック
    /////////////////////////////////
    while ( selCcRow != null )
    {
      index++;
      String discountAmt = selCcRow.getDiscountAmt();
      Number fixedPrice  = selCcRow.getDefinedFixedPrice();
      String bm1BmRate   = selCcRow.getBm1BmRate();
      String bm1BmAmt    = selCcRow.getBm1BmAmount();
      String bm2BmRate   = selCcRow.getBm2BmRate();
      String bm2BmAmt    = selCcRow.getBm2BmAmount();
      String bm3BmRate   = selCcRow.getBm3BmRate();
      String bm3BmAmt    = selCcRow.getBm3BmAmount();

      if ( ! isLimitTotalValue(
               bm1BmRate
              ,bm2BmRate
              ,bm3BmRate
              ,String.valueOf(100)
             )
         )
      {
        OAException error = null;
        if ( contributeFlag )
        {
          error
            = XxcsoMessage.createErrorMessage(
                XxcsoConstants.APP_XXCSO1_00485
               ,XxcsoConstants.TOKEN_INDEX
               ,String.valueOf(index)
              );
        }
        else
        {
          error
            = XxcsoMessage.createErrorMessage(
                XxcsoConstants.APP_XXCSO1_00298
               ,XxcsoConstants.TOKEN_INDEX
               ,String.valueOf(index)
              );
        }
        
        errorList.add(error);
      }

      double discountAmtDoubleValue = (double)0;

      if ( discountAmt != null && ! "".equals(discountAmt) )
      {
        discountAmtDoubleValue
          = Double.parseDouble(discountAmt.replaceAll(",",""));
      }

      double limitValue = discountAmtDoubleValue + fixedPrice.doubleValue();
      if ( limitValue <= (double)0 )
      {
        errorList.add(
          XxcsoMessage.createErrorMessage(
            XxcsoConstants.APP_XXCSO1_00530
           ,XxcsoConstants.TOKEN_INDEX
           ,String.valueOf(index)
          )
        );
      }
      else
      {
        if ( ! isLimitTotalValue(
                 bm1BmAmt
                ,bm2BmAmt
                ,bm3BmAmt
                ,String.valueOf(limitValue)
               )
           )
        {
          OAException error = null;
          if ( contributeFlag )
          {
            error
              = XxcsoMessage.createErrorMessage(
                  XxcsoConstants.APP_XXCSO1_00486
                 ,XxcsoConstants.TOKEN_PRICE
                 ,String.valueOf((int)limitValue)
                 ,XxcsoConstants.TOKEN_INDEX
                 ,String.valueOf(index)
                );
          }
          else
          {
            error
              = XxcsoMessage.createErrorMessage(
                  XxcsoConstants.APP_XXCSO1_00299
                 ,XxcsoConstants.TOKEN_PRICE
                 ,String.valueOf((int)limitValue)
                 ,XxcsoConstants.TOKEN_INDEX
                 ,String.valueOf(index)
                );
          }
          errorList.add(error);
        }
      }
      
      selCcRow = (XxcsoSpDecisionSelCcLineFullVORowImpl)selCcVo.next();
    }
    
    XxcsoUtils.debug(txn, "[END]");

    return errorList;
  }


// 課題一覧No.73対応 START
  /*****************************************************************************
   * BM率／BM金額同時入力チェック
   * @param txn                 OADBTransactionインスタンス
   * @param bmRate              BM率の値
   * @param bmAmount            BM金額の値
   * @return boolean            結果 true  : 両方とも入力されている
   *                                 false : 片方もしくはともに入力されていない
   *****************************************************************************
   */
  public static boolean isBothBmValue(
    OADBTransaction    txn
   ,String             bmRate
   ,String             bmAmount
  )
  {
    XxcsoUtils.debug(txn, "[START]");

    double bmRateDouble   = 0;
    double bmAmountDouble = 0;

    if ( bmRate == null || "".equals(bmRate) )
    {
      return false;
    }

    if ( bmAmount == null || "".equals(bmAmount) )
    {
      return false;
    }
    
    try
    {
      bmRateDouble   = Double.parseDouble(bmRate);
      bmAmountDouble = Double.parseDouble(bmAmount);
    }
    catch ( NumberFormatException nfe )
    {
      return false;
    }

    if ( bmRateDouble   != (double)0 &&
         bmAmountDouble != (double)0
       )
    {
      return true;
    }

    XxcsoUtils.debug(txn, "[END]");

    return false;
  }


  /*****************************************************************************
   * BM入力チェック
   * @param txn                 OADBTransactionインスタンス
   * @param bmRate              BM率の値
   * @param bmAmount            BM金額の値
   * @return boolean            結果 true  : 入力されている
   *                                 false : 入力されていない
   *****************************************************************************
   */
  public static boolean isBmInput(
    OADBTransaction    txn
   ,String             bmRate
   ,String             bmAmount
  )
  {
    XxcsoUtils.debug(txn, "[START]");

    double bmRateDouble   = 0;
    double bmAmountDouble = 0;

    if ( bmRate != null && ! "".equals(bmRate) )
    {
      bmRateDouble   = Double.parseDouble(bmRate);
    }

    if ( bmAmount != null && ! "".equals(bmAmount) )
    {
      bmAmountDouble = Double.parseDouble(bmAmount);
    }
    
    if ( bmRateDouble != (double)0 || bmAmountDouble != (double)0 )
    {
      return true;
    }

    XxcsoUtils.debug(txn, "[END]");

    return false;
  }
// 課題一覧No.73対応 END


  /*****************************************************************************
   * 定価の検証
   * @param txn         OADBTransactionインスタンス
   * @param fixedPrice  定価
   * @param submitFlag  提出用フラグ
   * @param index       行番号
   * @return List       エラーリスト
   *****************************************************************************
   */
  private static List validateFixedPrice(
    OADBTransaction     txn
   ,String              fixedPrice
   ,boolean             submitFlag
   ,int                 index
  )
  {
    XxcsoUtils.debug(txn, "[START]");
    
    List errorList = new ArrayList();

    XxcsoValidateUtils utils = XxcsoValidateUtils.getInstance(txn);
    
    errorList
      = utils.checkStringToNumber(
          errorList
         ,fixedPrice
         ,XxcsoSpDecisionConstants.TOKEN_VALUE_FIXED_PRICE
         ,0
         ,4
         ,submitFlag
         ,false
         ,submitFlag
         ,index
        );

    XxcsoUtils.debug(txn, "[END]");

    return errorList;
  }


  /*****************************************************************************
   * 売価の検証
   * @param txn         OADBTransactionインスタンス
   * @param salesPrice  売価
   * @param submitFlag  提出用フラグ
   * @param index       行番号
   * @return List       エラーリスト
   *****************************************************************************
   */
  private static List validateSalesPrice(
    OADBTransaction     txn
   ,String              salesPrice
   ,boolean             submitFlag
   ,int                 index
  )
  {
    XxcsoUtils.debug(txn, "[START]");

    List errorList = new ArrayList();

    XxcsoValidateUtils utils = XxcsoValidateUtils.getInstance(txn);
    
    errorList
      = utils.checkStringToNumber(
          errorList
         ,salesPrice
         ,XxcsoSpDecisionConstants.TOKEN_VALUE_SALES_PRICE
         ,0
         ,4
         ,submitFlag
         ,submitFlag
         ,submitFlag
         ,index
        );

// 2014-01-31 [E_本稼動_11397] Del Start
//    double doubleValue = 0;
//    boolean unitErrorFlag = false;

//    if ( salesPrice != null               &&
//         ! "".equals(salesPrice.trim())   &&
//         ! "0".equals(salesPrice.trim())
//       )
//    {
//      try
//      {
//        doubleValue = Double.parseDouble(salesPrice.replaceAll(",",""));
//      }
//      catch ( NumberFormatException nfe )
//      {
//        unitErrorFlag = true;
//      }
//      if ( (doubleValue % (double)10) != (double)0 )
//      {
//        unitErrorFlag = true;
//      }
//    }
//    else
//    {
//      unitErrorFlag = true;
//    }

//    if ( submitFlag && unitErrorFlag )
//    {
//      OAException error
//        = XxcsoMessage.createErrorMessage(
//            XxcsoConstants.APP_XXCSO1_00300
//           ,XxcsoConstants.TOKEN_COLUMN
//           ,XxcsoSpDecisionConstants.TOKEN_VALUE_SALES_PRICE
//           ,XxcsoConstants.TOKEN_INDEX
//           ,String.valueOf(index)
//         );

//      errorList.add(error);
//    }
// 2014-01-31 [E_本稼動_11397] Del End
    
    XxcsoUtils.debug(txn, "[END]");

    return errorList;
  }


  /*****************************************************************************
   * 定価からの値引額の検証
   * @param txn         OADBTransactionインスタンス
   * @param discountAmt 定価からの値引額
   * @param submitFlag  提出用フラグ
   * @param index       行番号
   * @return List       エラーリスト
   *****************************************************************************
   */
  private static List validateDiscountAmt(
    OADBTransaction     txn
   ,String              discountAmt
   ,boolean             submitFlag
   ,int                 index
  )
  {
    XxcsoUtils.debug(txn, "[START]");

    List errorList = new ArrayList();

    XxcsoValidateUtils utils = XxcsoValidateUtils.getInstance(txn);
    
    errorList
      = utils.checkStringToNumber(
          errorList
         ,discountAmt
         ,XxcsoSpDecisionConstants.TOKEN_VALUE_DISCOUNT_AMT
         ,0
         ,4
         ,false
         ,false
         ,submitFlag
         ,index
        );

    double doubleValue = 0;
    boolean unitErrorFlag = false;

    if ( discountAmt != null               &&
         ! "".equals(discountAmt.trim())   &&
         ! "0".equals(discountAmt.trim())
       )
    {
      try
      {
        doubleValue = Double.parseDouble(discountAmt.replaceAll(",",""));
      }
      catch ( NumberFormatException nfe )
      {
        unitErrorFlag = true;
      }

      if ( (doubleValue % (double)10) != (double)0 )
      {
        unitErrorFlag = true;
      }
    }

    if ( submitFlag && unitErrorFlag )
    {
      OAException error
        = XxcsoMessage.createErrorMessage(
            XxcsoConstants.APP_XXCSO1_00300
           ,XxcsoConstants.TOKEN_COLUMN
           ,XxcsoSpDecisionConstants.TOKEN_VALUE_DISCOUNT_AMT
           ,XxcsoConstants.TOKEN_INDEX
           ,String.valueOf(index)
          );

      errorList.add(error);
    }
    
    XxcsoUtils.debug(txn, "[END]");

    return errorList;
  }


  /*****************************************************************************
   * BM1BM率の検証
   * @param txn         OADBTransactionインスタンス
   * @param bm1BmRate   BM1BM率
   * @param submitFlag  提出用フラグ
   * @param index       行番号
   * @return List       エラーリスト
   *****************************************************************************
   */
  private static List validateBm1BmRate(
    OADBTransaction     txn
   ,String              bm1BmRate
   ,boolean             submitFlag
   ,int                 index
  )
  {
    XxcsoUtils.debug(txn, "[START]");
    
    List errorList = new ArrayList();

    XxcsoValidateUtils utils = XxcsoValidateUtils.getInstance(txn);
    
    errorList
      = utils.checkStringToNumber(
          errorList
         ,bm1BmRate
         ,XxcsoSpDecisionConstants.TOKEN_VALUE_BM1_BM_RATE
         ,2
         ,2
         ,submitFlag
// 課題一覧No.73対応 START
//         ,submitFlag
         ,false
// 課題一覧No.73対応 END
         ,false
         ,index
        );

    XxcsoUtils.debug(txn, "[END]");

    return errorList;
  }



  /*****************************************************************************
   * BM2BM率の検証
   * @param txn         OADBTransactionインスタンス
   * @param bm2BmRate   BM2BM率
   * @param submitFlag  提出用フラグ
   * @param index       行番号
   * @return List       エラーリスト
   *****************************************************************************
   */
  private static List validateBm2BmRate(
    OADBTransaction     txn
   ,String              bm2BmRate
   ,boolean             contributeFlag
   ,boolean             submitFlag
   ,int                 index
  )
  {
    XxcsoUtils.debug(txn, "[START]");
    
    List errorList = new ArrayList();

    XxcsoValidateUtils utils = XxcsoValidateUtils.getInstance(txn);

    String token = null;

    if ( contributeFlag )
    {
      token = XxcsoSpDecisionConstants.TOKEN_VALUE_CONTRIBUTE_BM_RATE;
    }
    else
    {
      token = XxcsoSpDecisionConstants.TOKEN_VALUE_BM2_BM_RATE;
    }
    
    errorList
      = utils.checkStringToNumber(
          errorList
         ,bm2BmRate
         ,token
         ,2
         ,2
         ,submitFlag
// 課題一覧No.73対応 START
//         ,submitFlag
         ,false
// 課題一覧No.73対応 END
         ,false
         ,index
        );

    XxcsoUtils.debug(txn, "[END]");

    return errorList;
  }



  /*****************************************************************************
   * BM3BM率の検証
   * @param txn         OADBTransactionインスタンス
   * @param bm3BmRate   BM3BM率
   * @param submitFlag  提出用フラグ
   * @param index       行番号
   * @return List       エラーリスト
   *****************************************************************************
   */
  private static List validateBm3BmRate(
    OADBTransaction     txn
   ,String              bm3BmRate
   ,boolean             submitFlag
   ,int                 index
  )
  {
    XxcsoUtils.debug(txn, "[START]");
    
    List errorList = new ArrayList();

    XxcsoValidateUtils utils = XxcsoValidateUtils.getInstance(txn);
    
    errorList
      = utils.checkStringToNumber(
          errorList
         ,bm3BmRate
         ,XxcsoSpDecisionConstants.TOKEN_VALUE_BM3_BM_RATE
         ,2
         ,2
         ,submitFlag
// 課題一覧No.73対応 START
//         ,submitFlag
         ,false
// 課題一覧No.73対応 END
         ,false
         ,index
        );

    XxcsoUtils.debug(txn, "[END]");

    return errorList;
  }



  /*****************************************************************************
   * BM1BM金額の検証
   * @param txn         OADBTransactionインスタンス
   * @param bm1BmAmt    BM1BM金額
   * @param submitFlag  提出用フラグ
   * @param index       行番号
   * @return List       エラーリスト
   *****************************************************************************
   */
  private static List validateBm1BmAmt(
    OADBTransaction     txn
   ,String              bm1BmAmt
   ,boolean             submitFlag
   ,int                 index
  )
  {
    XxcsoUtils.debug(txn, "[START]");
    
    List errorList = new ArrayList();

    XxcsoValidateUtils utils = XxcsoValidateUtils.getInstance(txn);
    
    errorList
      = utils.checkStringToNumber(
          errorList
         ,bm1BmAmt
         ,XxcsoSpDecisionConstants.TOKEN_VALUE_BM1_BM_AMT
         ,2
         ,3
         ,submitFlag
// 課題一覧No.73対応 START
//         ,submitFlag
         ,false
// 課題一覧No.73対応 END
         ,false
         ,index
        );

    XxcsoUtils.debug(txn, "[END]");

    return errorList;
  }


  /*****************************************************************************
   * BM2BM金額の検証
   * @param txn         OADBTransactionインスタンス
   * @param bm2BmAmt    BM2BM金額
   * @param submitFlag  提出用フラグ
   * @param index       行番号
   * @return List       エラーリスト
   *****************************************************************************
   */
  private static List validateBm2BmAmt(
    OADBTransaction     txn
   ,String              bm2BmAmt
   ,boolean             contributeFlag
   ,boolean             submitFlag
   ,int                 index
  )
  {
    XxcsoUtils.debug(txn, "[START]");
    
    List errorList = new ArrayList();

    XxcsoValidateUtils utils = XxcsoValidateUtils.getInstance(txn);

    String token = null;
    
    if ( contributeFlag )
    {
      token = XxcsoSpDecisionConstants.TOKEN_VALUE_CONTRIBUTE_BM_AMT;
    }
    else
    {
      token = XxcsoSpDecisionConstants.TOKEN_VALUE_BM2_BM_AMT;
    }
    
    errorList
      = utils.checkStringToNumber(
          errorList
         ,bm2BmAmt
         ,token
         ,2
         ,3
         ,submitFlag
// 課題一覧No.73対応 START
//         ,submitFlag
         ,false
// 課題一覧No.73対応 END
         ,false
         ,index
        );

    XxcsoUtils.debug(txn, "[END]");

    return errorList;
  }


  /*****************************************************************************
   * BM3BM金額の検証
   * @param txn         OADBTransactionインスタンス
   * @param bm3BmAmt    BM3BM金額
   * @param submitFlag  提出用フラグ
   * @param index       行番号
   * @return List       エラーリスト
   *****************************************************************************
   */
  private static List validateBm3BmAmt(
    OADBTransaction     txn
   ,String              bm3BmAmt
   ,boolean             submitFlag
   ,int                 index
  )
  {
    XxcsoUtils.debug(txn, "[START]");
    
    List errorList = new ArrayList();

    XxcsoValidateUtils utils = XxcsoValidateUtils.getInstance(txn);
    
    errorList
      = utils.checkStringToNumber(
          errorList
         ,bm3BmAmt
         ,XxcsoSpDecisionConstants.TOKEN_VALUE_BM3_BM_AMT
         ,2
         ,3
         ,submitFlag
// 課題一覧No.73対応 START
//         ,submitFlag
         ,false
// 課題一覧No.73対応 END
         ,false
         ,index
        );

    XxcsoUtils.debug(txn, "[END]");

    return errorList;
  }


  /*****************************************************************************
   * 合計値の検証
   * @param bm1Value    BM1率／BM1金額の値
   * @param bm2Value    BM2率／BM2金額の値
   * @param bm3Value    BM3率／BM3金額の値
   * @param maxValue    最大値
   * @return boolean    検証結果
   *****************************************************************************
   */
  private static boolean isLimitTotalValue(
    String   bm1Value
   ,String   bm2Value
   ,String   bm3Value
   ,String   maxValue
  )
  {
    double bm1DoubleValue = (double)0;
    double bm2DoubleValue = (double)0;
    double bm3DoubleValue = (double)0;
    double maxDoubleValue = (double)0;
    boolean returnValue   = true;
    
    if ( bm1Value != null && ! "".equals(bm1Value.replaceAll(",","")) )
    {
      bm1DoubleValue = Double.parseDouble(bm1Value.replaceAll(",",""));
    }

    if ( bm2Value != null && ! "".equals(bm2Value.replaceAll(",","")) )
    {
      bm2DoubleValue = Double.parseDouble(bm2Value.replaceAll(",",""));
    }

    if ( bm3Value != null && ! "".equals(bm3Value.replaceAll(",","")) )
    {
      bm3DoubleValue = Double.parseDouble(bm3Value.replaceAll(",",""));
    }

    if ( maxValue != null && ! "".equals(maxValue.replaceAll(",","")) )
    {
      maxDoubleValue = Double.parseDouble(maxValue.replaceAll(",",""));
    }

    if ( (bm1DoubleValue + bm2DoubleValue + bm3DoubleValue) > maxDoubleValue )
    {
      returnValue = false;
    }

    return returnValue;
  }


  /*****************************************************************************
   * 郵便番号の検証
   * @param txn                 OADBTransactionインスタンス
   * @param postalCodeFirst     郵便番号（前方）
   * @param postalCodeSecond    郵便番号（後方）
   * @return boolean            検証結果
   *****************************************************************************
   */
  private static boolean isPostalCode(
    OADBTransaction  txn
   ,String           postalCodeFirst
   ,String           postalCodeSecond
  )
  {
    boolean returnValue = true;
    List errorList = new ArrayList();
    
    XxcsoValidateUtils utils = XxcsoValidateUtils.getInstance(txn);

    errorList = 
      utils.checkStringToNumber(
        errorList
       ,postalCodeFirst
       ,"dummy"
       ,4
       ,4
       ,true
       // 2009-12-17 [E_本稼動_00514] Add Start
       //,true
       ,false
       // 2009-12-17 [E_本稼動_00514] Add End
       ,false
       ,0
      );

    if ( errorList.size() > 0 )
    {
      returnValue = false;
    }
    else
    {
      if ( postalCodeFirst == null )
      {
        returnValue = false;
      }
      else
      {
        if ( postalCodeFirst.length() != 3 )
        {
          returnValue = false;
        }
      }
    }

    errorList =
      utils.checkStringToNumber(
        errorList
       ,postalCodeSecond
       ,"dummy"
       ,5
       ,5
       ,true
       // 2009-12-17 [E_本稼動_00514] Add Start
       //,true
       ,false
       // 2009-12-17 [E_本稼動_00514] Add End
       ,false
       ,0
      );

    if ( errorList.size() > 0 )
    {
      returnValue = false;
    }
    else
    {
      if ( postalCodeSecond == null )
      {
        returnValue = false;
      }
      else
      {
        if ( postalCodeSecond.length() != 4 )
        {
          returnValue = false;
        }
      }
    }

    return returnValue;
  }


  /*****************************************************************************
   * 全角カナの検証
   * @param txn                 OADBTransactionインスタンス
   * @param value               チェック対象の値
   * @return boolean            検証結果
   *****************************************************************************
   */
  private static boolean isDoubleByteKana(
    OADBTransaction   txn
   ,String            value
  )
  {
    OracleCallableStatement stmt = null;
    boolean returnValue = true;

    if ( value == null || "".equals(value.trim()) )
    {
      return true;
    }
    
    try
    {
      StringBuffer sql = new StringBuffer(100);
      sql.append("BEGIN");
      sql.append("  :1 := xxcso_020001j_pkg.chk_double_byte_kana(:2);");
      sql.append("END;");

      stmt
        = (OracleCallableStatement)
            txn.createCallableStatement(sql.toString(), 0);

      stmt.registerOutParameter(1, OracleTypes.VARCHAR);
      stmt.setString(2, value);

      stmt.execute();

      String returnString = stmt.getString(1);
      if ( ! "1".equals(returnString) )
      {
        returnValue = false;
      }
    }
    catch ( SQLException e )
    {
      XxcsoUtils.unexpected(txn, e);
      throw
        XxcsoMessage.createSqlErrorMessage(
          e
         ,XxcsoSpDecisionConstants.TOKEN_VALUE_DOUBLE_BYTE_KANA_CHK
        );
    }
    finally
    {
      try
      {
        if ( stmt != null )
        {
          stmt.close();
        }
      }
      catch ( SQLException e )
      {
        XxcsoUtils.unexpected(txn, e);
      }
    }

    return returnValue;
  }

// 2009-04-27 [ST障害T1_0708] Add Start
  /*****************************************************************************
   * 全角文字の検証
   * @param txn                 OADBTransactionインスタンス
   * @param value               チェック対象の値
   * @return boolean            検証結果
   *****************************************************************************
   */
  private static boolean isDoubleByte(
    OADBTransaction   txn
   ,String            value
  )
  {
    OracleCallableStatement stmt = null;
    boolean returnValue = true;

    if ( value == null || "".equals(value.trim()) )
    {
      return true;
    }

    try
    {
      StringBuffer sql = new StringBuffer(100);
      sql.append("BEGIN");
      sql.append("  :1 := xxcso_020001j_pkg.chk_double_byte(:2);");
      sql.append("END;");

      stmt
        = (OracleCallableStatement)
            txn.createCallableStatement(sql.toString(), 0);

      stmt.registerOutParameter(1, OracleTypes.VARCHAR);
      stmt.setString(2, value);

      stmt.execute();

      String returnString = stmt.getString(1);
      if ( ! "1".equals(returnString) )
      {
        returnValue = false;
      }
    }
    catch ( SQLException e )
    {
      XxcsoUtils.unexpected(txn, e);
      throw
        XxcsoMessage.createSqlErrorMessage(
          e
         ,XxcsoSpDecisionConstants.TOKEN_VALUE_DOUBLE_BYTE_CHK
        );
    }
    finally
    {
      try
      {
        if ( stmt != null )
        {
          stmt.close();
        }
      }
      catch ( SQLException e )
      {
        XxcsoUtils.unexpected(txn, e);
      }
    }
    return returnValue;
 }

  /*****************************************************************************
   * 半角カナの検証（共通関数）
   * @param txn                 OADBTransactionインスタンス
   * @param value               チェック対象の値
   * @return boolean            検証結果
   *****************************************************************************
   */
  private static boolean isSingleByteKana(
    OADBTransaction   txn
   ,String            value
  )
  {
    OracleCallableStatement stmt = null;
    boolean returnValue = true;

    if ( value == null || "".equals(value.trim()) )
    {
      return true;
    }

    try
    {
      StringBuffer sql = new StringBuffer(100);
      sql.append("BEGIN");
      sql.append("  :1 := xxcso_020001j_pkg.chk_single_byte_kana(:2);");
      sql.append("END;");

      stmt
        = (OracleCallableStatement)
            txn.createCallableStatement(sql.toString(), 0);

      stmt.registerOutParameter(1, OracleTypes.VARCHAR);
      stmt.setString(2, value);

      stmt.execute();

      String returnString = stmt.getString(1);
      if ( ! "1".equals(returnString) )
      {
        returnValue = false;
      }
    }
    catch ( SQLException e )
    {
      XxcsoUtils.unexpected(txn, e);
      throw
        XxcsoMessage.createSqlErrorMessage(
          e
         ,XxcsoSpDecisionConstants.TOKEN_VALUE_SINGLE_BYTE_KANA_CHK
        );
    }
    finally
    {
      try
      {
        if ( stmt != null )
        {
          stmt.close();
        }
      }
      catch ( SQLException e )
      {
        XxcsoUtils.unexpected(txn, e);
      }
    }
    return returnValue;
 }
// 2009-04-27 [ST障害T1_0708] Add End
// 2009-11-29 [E_本稼動_00106] Add Start
  /*****************************************************************************
   * アカウント複数検証
   * @param txn                 OADBTransactionインスタンス
   * @param value               チェック対象の値
   * @return String             エラーメッセージ
   *****************************************************************************
   */
  private static String validateAccount(
     OADBTransaction   txn
    ,String            Account_Code
  )
  {
    OracleCallableStatement stmt = null;
    String returnValue = "";

    if ( Account_Code == null || "".equals(Account_Code) )
    {
      return "";
    }

    try
    {
      StringBuffer sql = new StringBuffer(100);
 
      sql.append("BEGIN");
      sql.append("  xxcso_020001j_pkg.chk_account_many(");
      sql.append("    iv_account_number      => :1");
      sql.append("   ,ov_errbuf              => :2");
      sql.append("   ,ov_retcode             => :3");
      sql.append("   ,ov_errmsg              => :4");
      sql.append("  );");
      sql.append("END;");

      XxcsoUtils.debug(txn, "execute = " + sql.toString());

      stmt
        = (OracleCallableStatement)
            txn.createCallableStatement(sql.toString(), 0);

      stmt.setString(1, Account_Code);
      stmt.registerOutParameter(2, OracleTypes.VARCHAR);
      stmt.registerOutParameter(3, OracleTypes.VARCHAR);
      stmt.registerOutParameter(4, OracleTypes.VARCHAR);

      stmt.execute();

      String errBuf  = stmt.getString(2);
      String retCode = stmt.getString(3);
      String errMsg  = stmt.getString(4);
      
      XxcsoUtils.debug(txn, "errBuf  = " + errBuf);
      XxcsoUtils.debug(txn, "retCode = " + retCode);
      XxcsoUtils.debug(txn, "errMsg  = " + errMsg);

      if ( ! "0".equals(retCode) )
      {
        returnValue = errMsg;
      }

    }
    catch ( SQLException e )
    {
      XxcsoUtils.unexpected(txn, e);
      throw
        XxcsoMessage.createSqlErrorMessage(
          e
         ,XxcsoSpDecisionConstants.TOKEN_VALUE_ACCOUNT_CHK
        );
    }
    finally
    {
      try
      {
        if ( stmt != null )
        {
          stmt.close();
        }
      }
      catch ( SQLException e )
      {
        XxcsoUtils.unexpected(txn, e);
      }
    }
    return returnValue;
 }
// 2009-11-29 [E_本稼動_00106] Add End
// 2010-01-12 [E_本稼動_00823] Add Start
  /*****************************************************************************
   * 顧客使用目的検証
   * @param txn                 OADBTransactionインスタンス
   * @param value               チェック対象の値
   * @return String             エラーメッセージ
   *****************************************************************************
   */
  private static String validateSiteUses(
     OADBTransaction   txn
    ,String            Account_Code
  )
  {
    OracleCallableStatement stmt = null;
    String returnValue = "";

    if ( Account_Code == null || "".equals(Account_Code) )
    {
      return "";
    }

    try
    {
      StringBuffer sql = new StringBuffer(100);
 
      sql.append("BEGIN");
      sql.append("  xxcso_020001j_pkg.chk_cust_site_uses(");
      sql.append("    iv_account_number      => :1");
      sql.append("   ,ov_errbuf              => :2");
      sql.append("   ,ov_retcode             => :3");
      sql.append("   ,ov_errmsg              => :4");
      sql.append("  );");
      sql.append("END;");

      XxcsoUtils.debug(txn, "execute = " + sql.toString());

      stmt
        = (OracleCallableStatement)
            txn.createCallableStatement(sql.toString(), 0);

      stmt.setString(1, Account_Code);
      stmt.registerOutParameter(2, OracleTypes.VARCHAR);
      stmt.registerOutParameter(3, OracleTypes.VARCHAR);
      stmt.registerOutParameter(4, OracleTypes.VARCHAR);

      stmt.execute();

      String errBuf  = stmt.getString(2);
      String retCode = stmt.getString(3);
      String errMsg  = stmt.getString(4);
      
      XxcsoUtils.debug(txn, "errBuf  = " + errBuf);
      XxcsoUtils.debug(txn, "retCode = " + retCode);
      XxcsoUtils.debug(txn, "errMsg  = " + errMsg);

      if ( ! "0".equals(retCode) )
      {
        returnValue = errMsg;
      }

    }
    catch ( SQLException e )
    {
      XxcsoUtils.unexpected(txn, e);
      throw
        XxcsoMessage.createSqlErrorMessage(
          e
         ,XxcsoSpDecisionConstants.TOKEN_VALUE_SITE_USE_CODE_CHK
        );
    }
    finally
    {
      try
      {
        if ( stmt != null )
        {
          stmt.close();
        }
      }
      catch ( SQLException e )
      {
        XxcsoUtils.unexpected(txn, e);
      }
    }
    return returnValue;
 }
// 2010-01-12 [E_本稼動_00823] Add End
// 2016-01-07 [E_本稼動_13456] Del Start
//// 2013-04-19 [E_本稼動_09603] Add Start
//  /*****************************************************************************
//   * 契約の存在検証
//   * @param txn            OADBTransactionインスタンス
//   * @param contractexists 契約存在フラグ
//   *****************************************************************************
//   */
//  public static List validateContractExists(
//    OADBTransaction     txn
//   ,String              contractexists
//  )
//  {
//    XxcsoUtils.debug(txn, "[START]");
//
//    List errorList = new ArrayList();
//
//    if ( "N".equals(contractexists) )
//    {
//      OAException error
//            = XxcsoMessage.createErrorMessage(
//                XxcsoConstants.APP_XXCSO1_00648
//               ,XxcsoConstants.TOKEN_ACTION
//               ,XxcsoSpDecisionConstants.TOKEN_VALUE_REQUEST_CONC
//              );
//      errorList.add(error);
//    }
//
//    XxcsoUtils.debug(txn, "[END]");
//
//    return errorList;
//  }
//// 2013-04-19 [E_本稼動_09603] Add End
// 2016-01-07 [E_本稼動_13456] Del End
// 2014-12-15 [E_本稼動_12565] Add Start
  /*****************************************************************************
   * 月の検証
   * @param  Month              チェック対象の値
   * @return boolean            結果 true  : チェックOK
   *                                 false : チェックNG
   *****************************************************************************
   */
  private static boolean isMonth(
    String            month
  )
  {

    if ( month == null )
    {
      return true;
    }

    int inputMonth = Integer.valueOf( month ).intValue();

    if ( inputMonth > 12 )
    {
      return false;
    }
    return true;
  }

  /*****************************************************************************
   * 西暦の検証
   * @param  year               チェック対象の値
   * @return boolean            結果 true  : チェックOK
   *                                 false : チェックNG
   *****************************************************************************
   */
  private static boolean isYear(
    String            year
  )
  {

    if ( year == null )
    {
      return true;
    }

    if ( year.length() < 4 )
    {
      return false;
    }
    return true;
  }

  /*****************************************************************************
   * 契約終了期間の検証
   * @param txn                 OADBTransactionインスタンス
   * @param ContractStartYear   契約期間開始（年）
   * @param ContractStartMonth  契約期間開始（月）
   * @param ContractYearDate    契約年数
   * @param ContractYearMonth   契約月数
   * @return String             契約終了期間
   *****************************************************************************
   */
  private static String validateContractEnd(
     OADBTransaction   txn
    ,String            contractYearDate
    ,String            contractYearMonth
    ,String            contractStartYear
    ,String            contractStartMonth
    ,String            contractEndYear
    ,String            contractEndMonth
  
  )
  {
    XxcsoUtils.debug(txn, "[START]");

    OracleCallableStatement stmt = null;
    String returnValue = "0";

    if (    ( contractYearDate   == null && ! "0".equals(contractYearDate) )
         || ( contractYearMonth  == null && ! "0".equals(contractYearMonth) )
         || ( contractStartYear  == null && ! "0".equals(contractStartYear) )
         || ( contractStartMonth == null && ! "0".equals(contractStartMonth) )
         || ( contractEndYear    == null && ! "0".equals(contractEndYear) )
         || ( contractEndMonth   == null && ! "0".equals(contractEndMonth) )
       )
    {
      return returnValue;
    }

    try
    {
      StringBuffer sql = new StringBuffer(100);
 
      sql.append("BEGIN");
      sql.append("  xxcso_020001j_pkg.get_contract_end_period(");
      sql.append("    iv_contract_year_date   => :1" );
      sql.append("   ,iv_contract_year_month  => :2" );
      sql.append("   ,iv_contract_start_year  => :3" );
      sql.append("   ,iv_contract_start_month => :4" );
      sql.append("   ,iv_contract_end_year    => :5" );
      sql.append("   ,iv_contract_end_month   => :6" );
      sql.append("   ,ov_contract_end         => :7" );
      sql.append("   ,ov_errbuf               => :8" );
      sql.append("   ,ov_retcode              => :9" );
      sql.append("   ,ov_errmsg               => :10");
      sql.append("  );");
      sql.append("END;");

      XxcsoUtils.debug(txn, "execute = " + sql.toString());

      stmt
        = (OracleCallableStatement)
            txn.createCallableStatement(sql.toString(), 0);

      stmt.setString(1, contractYearDate);
      stmt.setString(2, contractYearMonth);
      stmt.setString(3, contractStartYear);
      stmt.setString(4, contractStartMonth);
      stmt.setString(5, contractEndYear);
      stmt.setString(6, contractEndMonth);
      stmt.registerOutParameter(7,  OracleTypes.VARCHAR);
      stmt.registerOutParameter(8,  OracleTypes.VARCHAR);
      stmt.registerOutParameter(9,  OracleTypes.VARCHAR);
      stmt.registerOutParameter(10, OracleTypes.VARCHAR);

      stmt.execute();

      String contractEnd  = stmt.getString(7);
      String errBuf       = stmt.getString(8);
      String retCode      = stmt.getString(9);
      String errMsg       = stmt.getString(10);

      if ( ! "0".equals(retCode) )
      {
        returnValue = contractEnd;
      }

    }
    catch ( SQLException e )
    {
      XxcsoUtils.unexpected(txn, e);
      throw
        XxcsoMessage.createSqlErrorMessage(
          e
         ,XxcsoSpDecisionConstants.TOKEN_VALUE_CONTRACT_END_CHK
        );
    }
    finally
    {
      try
      {
        if ( stmt != null )
        {
          stmt.close();
        }
      }
      catch ( SQLException e )
      {
        XxcsoUtils.unexpected(txn, e);
      }
    }

    XxcsoUtils.debug(txn, "[END]");

    return returnValue;
  }
// 2014-12-15 [E_本稼動_12565] Add End
// 2018-05-16 [E_本稼動_14989] Add Start

  /*****************************************************************************
   * 工期、設置見込み期間必須フラグ取得
   * @param  txn            OADBTransactionインスタンス
   * @param  businessType   業種
   * @param  bizCondType    業態（小分類）
   * @return boolean        フラグ
   *****************************************************************************
   */
  private static boolean getRequiredCheckFlag(
     OADBTransaction   txn
    ,String            businessType
    ,String            bizCondType
  )
  {
    XxcsoUtils.debug(txn, "[START]");

    OracleCallableStatement stmt = null;
    boolean returnValue = false;

    try
    {
      StringBuffer sql = new StringBuffer(100);
 
      sql.append("BEGIN");
      sql.append("  xxcso_020001j_pkg.get_required_check_flag(");
      sql.append("    iv_business_type => :1" );
      sql.append("   ,iv_biz_cond_type => :2" );
      sql.append("   ,on_check_count   => :3" );
      sql.append("   ,ov_errbuf        => :4" );
      sql.append("   ,ov_retcode       => :5" );
      sql.append("   ,ov_errmsg        => :6");
      sql.append("  );");
      sql.append("END;");

      XxcsoUtils.debug(txn, "execute = " + sql.toString());

      stmt
        = (OracleCallableStatement)
            txn.createCallableStatement(sql.toString(), 0);

      stmt.setString(1, businessType);
      stmt.setString(2, bizCondType);
      stmt.registerOutParameter(3, OracleTypes.NUMBER);
      stmt.registerOutParameter(4, OracleTypes.VARCHAR);
      stmt.registerOutParameter(5, OracleTypes.VARCHAR);
      stmt.registerOutParameter(6, OracleTypes.VARCHAR);

      stmt.execute();

      NUMBER checkCount   = stmt.getNUMBER(3);
      String errBuf       = stmt.getString(4);
      String retCode      = stmt.getString(5);
      String errMsg       = stmt.getString(6);

      int checkValue      = checkCount.intValue();

      if ( checkValue == 2 )
      {
        returnValue = true;
      }

    }
    catch ( SQLException e )
    {
      XxcsoUtils.unexpected(txn, e);
      throw
        XxcsoMessage.createSqlErrorMessage(
          e
         ,XxcsoSpDecisionConstants.TOKEN_VALUE_CONSTRUCTION_PERIOD
        );
    }
    finally
    {
      try
      {
        if ( stmt != null )
        {
          stmt.close();
        }
      }
      catch ( SQLException e )
      {
        XxcsoUtils.unexpected(txn, e);
      }
    }

    XxcsoUtils.debug(txn, "[END]");

    return returnValue;
  }

// 2018-05-16 [E_本稼動_14989] Add End
// [E_本稼動_15904] Add Start
  /*****************************************************************************
   * BM税区分妥当性チェック
   * @param  txn            OADBTransactionインスタンス
   * @param  headerVo       SP専決ヘッダ登録／更新用ビューインスタンス
   * @param  bm1Vo          BM1登録／更新用ビューインスタンス
   * @param  bm2Vo          BM2登録／更新用ビューインスタンス
   * @param  bm3Vo          BM3登録／更新用ビューインスタンス
   * @param  OperationMode  操作モード
   * @return boolean        フラグ
   *****************************************************************************
   */
 public static List validateBmTaxKbn(
    OADBTransaction                     txn
   ,XxcsoSpDecisionHeaderFullVOImpl     headerVo
   ,XxcsoSpDecisionBm1CustFullVOImpl    bm1Vo
   ,XxcsoSpDecisionBm2CustFullVOImpl    bm2Vo
   ,XxcsoSpDecisionBm3CustFullVOImpl    bm3Vo
   ,String                              OperationMode
  )
  {
    /////////////////////////////////////
    // 各行を取得
    /////////////////////////////////////
    XxcsoSpDecisionHeaderFullVORowImpl headerRow
      = (XxcsoSpDecisionHeaderFullVORowImpl)headerVo.first();
    XxcsoSpDecisionBm1CustFullVORowImpl bm1Row
      = (XxcsoSpDecisionBm1CustFullVORowImpl)bm1Vo.first();
    XxcsoSpDecisionBm2CustFullVORowImpl bm2Row
      = (XxcsoSpDecisionBm2CustFullVORowImpl)bm2Vo.first();
    XxcsoSpDecisionBm3CustFullVORowImpl bm3Row
      = (XxcsoSpDecisionBm3CustFullVORowImpl)bm3Vo.first();
    List errorList = new ArrayList();
    // 提出、承認、確認ボタンの場合
    if (
        OperationMode==XxcsoSpDecisionConstants.OPERATION_SUBMIT ||
        OperationMode==XxcsoSpDecisionConstants.OPERATION_CONFIRM ||
        OperationMode==XxcsoSpDecisionConstants.OPERATION_APPROVE
       )
    {
      // BM1のチェック
      if(  !(bm1Row.getVendorNumber() == null 
         || "".equals(bm1Row.getVendorNumber()))
        )
      {
        // 税区分リージョンとBM1リージョンの税区分が一致していない場合エラー
        if(!(headerRow.getBm1TaxKbn().equals(bm1Row.getBm1TaxKbnCodeView())))
        {
          OAException error
            = XxcsoMessage.createErrorMessage(
                XxcsoConstants.APP_XXCSO1_00909
               ,XxcsoConstants.TOKEN_BM_KBN
               ,XxcsoSpDecisionConstants.TOKEN_VALUE_BM1_REGION
              );
          errorList.add(error);
        }
      }
      // BM2のチェック
      if(  !(bm2Row.getVendorNumber() == null 
         || "".equals(bm2Row.getVendorNumber()))
        )
      {
        // 税区分リージョンとBM2リージョンの税区分が一致していない場合エラー
        if(!(headerRow.getBm2TaxKbn().equals(bm2Row.getBm2TaxKbnCodeView())))
        {
          OAException error
            = XxcsoMessage.createErrorMessage(
                XxcsoConstants.APP_XXCSO1_00909
               ,XxcsoConstants.TOKEN_BM_KBN
               ,XxcsoSpDecisionConstants.TOKEN_VALUE_BM2_REGION
              );
          errorList.add(error);
        }
      }
      // BM3のチェック
      if ( !(bm3Row.getVendorNumber() == null 
         || "".equals(bm3Row.getVendorNumber()))
        )
      {
      // 税区分リージョンとBM3リージョンの税区分が一致していない場合エラー
        if(!(headerRow.getBm3TaxKbn().equals(bm3Row.getBm3TaxKbnCodeView())))
        {
          OAException error
            = XxcsoMessage.createErrorMessage(
                XxcsoConstants.APP_XXCSO1_00909
               ,XxcsoConstants.TOKEN_BM_KBN
               ,XxcsoSpDecisionConstants.TOKEN_VALUE_BM3_REGION
              );
          errorList.add(error);
        }
      }
    }
    return errorList;
  }
// [E_本稼動_15904] Add End
// [E_本稼動_16293] Add Start
  /*****************************************************************************
   * 仕入先無効チェック
   * @param  txn            OADBTransactionインスタンス
   * @param  bm1Vo          BM1登録／更新用ビューインスタンス
   * @param  bm2Vo          BM2登録／更新用ビューインスタンス
   * @param  bm3Vo          BM3登録／更新用ビューインスタンス
   * @param  OperationMode  操作モード
   *****************************************************************************
   */
 public static List validateInbalidVendor(
    OADBTransaction                     txn
   ,XxcsoSpDecisionBm1CustFullVOImpl    bm1Vo
   ,XxcsoSpDecisionBm2CustFullVOImpl    bm2Vo
   ,XxcsoSpDecisionBm3CustFullVOImpl    bm3Vo
   ,String                              OperationMode
  )
  {
    /////////////////////////////////////
    // 各行を取得
    /////////////////////////////////////
    XxcsoSpDecisionBm1CustFullVORowImpl bm1Row
      = (XxcsoSpDecisionBm1CustFullVORowImpl)bm1Vo.first();
    XxcsoSpDecisionBm2CustFullVORowImpl bm2Row
      = (XxcsoSpDecisionBm2CustFullVORowImpl)bm2Vo.first();
    XxcsoSpDecisionBm3CustFullVORowImpl bm3Row
      = (XxcsoSpDecisionBm3CustFullVORowImpl)bm3Vo.first();
      
    // 変数の初期化  
    List errorList = new ArrayList();
    int bmMaxLoopCnt = 3;
    int loopCnt      = 0;
    OracleCallableStatement stmt = null;
    String retCode = null;
    String vendorCode = null;
    String bmToken = null;
    StringBuffer sql = null;
    
    // 提出、承認ボタンの場合
    if (
        OperationMode==XxcsoSpDecisionConstants.OPERATION_SUBMIT ||
        OperationMode==XxcsoSpDecisionConstants.OPERATION_APPROVE
       )
    {
      XxcsoUtils.debug(txn, "[START]");
      
      while (loopCnt < bmMaxLoopCnt) {
        // 変数の初期化
        stmt = null;
        retCode = null;
        vendorCode = null;
        bmToken = null;
        sql = null;
        ++loopCnt;

        // 仕入先番号、メッセージトークンに値を格納
        switch (loopCnt) {
          case 1:
            if (bm1Row != null) {vendorCode = bm1Row.getVendorNumber();}
            bmToken = XxcsoSpDecisionConstants.TOKEN_VALUE_BM1_REGION;
            break;
          case 2:
            if (bm2Row != null) {vendorCode = bm2Row.getVendorNumber();}
            bmToken = XxcsoSpDecisionConstants.TOKEN_VALUE_BM2_REGION;
            break;
          case 3:
            if (bm3Row != null) {vendorCode = bm3Row.getVendorNumber();}
            bmToken = XxcsoSpDecisionConstants.TOKEN_VALUE_BM3_REGION;
            break;
        }          
        try
        {
          //　仕入先番号がnullでない場合、チェックを実施
          if (vendorCode != null)
          {
            sql = new StringBuffer(100);
 
            sql.append("BEGIN");
            sql.append("  xxcso_020001j_pkg.chk_vendor_inbalid(");
            sql.append("    iv_vendor_code  => :1" );
            sql.append("   ,ov_retcode      => :2" );
            sql.append("  );");
            sql.append("END;");

            XxcsoUtils.debug(txn, "execute = " + sql.toString());

            stmt
              = (OracleCallableStatement)
                  txn.createCallableStatement(sql.toString(), 0);

            stmt.setString(1, vendorCode);
            stmt.registerOutParameter(2, OracleTypes.VARCHAR);

            stmt.execute();

            retCode = stmt.getString(2);

            // チェック結果が正常以外の場合、エラーメッセージを取得&戻り値に格納
            if ( !"0".equals(retCode) )
            {
              OAException error
                = XxcsoMessage.createErrorMessage(
                    XxcsoConstants.APP_XXCSO1_00911
                   ,XxcsoConstants.TOKEN_BM_KBN
                   ,bmToken
                   ,XxcsoConstants.TOKEN_VENDOR_CD
                   ,vendorCode
                  );
              errorList.add(error);
            }
          }
        }
        catch ( SQLException e )
        {
          XxcsoUtils.unexpected(txn, e);
          throw
            XxcsoMessage.createSqlErrorMessage(
              e
             ,XxcsoSpDecisionConstants.TOKEN_VALUE_CONSTRUCTION_PERIOD
            );
        }
        finally
        {
          try
          {
            if ( stmt != null )
            {
              stmt.close();
            }
          }
          catch ( SQLException e )
          {
            XxcsoUtils.unexpected(txn, e);
          }
        }
      }
      XxcsoUtils.debug(txn, "[END]");
    }
    return errorList;
  }
// [E_本稼動_16293] Add End
// Ver.1.24 Add Start
  /*****************************************************************************
   * 支払期間開始日チェック
   * @param txn                 OADBTransactionインスタンス
   * @param headerVo            SP専決ヘッダ登録／更新用ビューインスタンス
   * @param installVo           設置先登録／更新用ビューインスタンス
   * @return List               エラーリスト
   *****************************************************************************
   */
  public static List chkPayStartDate(
    OADBTransaction                     txn
   ,XxcsoSpDecisionHeaderFullVOImpl     headerVo
   ,XxcsoSpDecisionInstCustFullVOImpl   installVo
  )
  {
    XxcsoUtils.debug(txn, "[START]");
    /////////////////////////////////////
    // 各行を取得
    /////////////////////////////////////
    XxcsoSpDecisionHeaderFullVORowImpl headerRow
      = (XxcsoSpDecisionHeaderFullVORowImpl)headerVo.first();
    XxcsoSpDecisionInstCustFullVORowImpl installRow
      = (XxcsoSpDecisionInstCustFullVORowImpl)installVo.first();

    // 変数の初期化
    List errorList = new ArrayList();
    OracleCallableStatement stmt = null; 
    String retCode = null;
    String token1  = null;
    String token2  = null;
    String contractNumber = null;
    String spNumber = null;
    Date   installPayStartMon  = null;
    Date   installPayEndMon    = null;
    Date   adAssetsPayStartMon = null;
    Date   adAssetsPayEndMon   = null;

    String installSuppType      = headerRow.getInstallSuppType();
    String adAssetsType         = headerRow.getAdAssetsType();

    // 支払期間開始日（設置協賛金）
    Date installPayStartDate = makeDate(
              headerRow.getInstallPayStartYear(),
              headerRow.getInstallPayStartMonth());

    // 支払期間終了日（設置協賛金）          
    Date installPayEndDate = makeDate(
              headerRow.getInstallPayEndYear(),
              headerRow.getInstallPayEndMonth());

    // 支払期間開始日（行政財産使用料）          
    Date adAssetsPayStartDate = makeDate(
              headerRow.getAdAssetsPayStartYear(),
              headerRow.getAdAssetsPayStartMonth());

    // 支払期間終了日（行政財産使用料）          
    Date adAssetsPayEndDate = makeDate(
              headerRow.getAdAssetsPayEndYear(),
              headerRow.getAdAssetsPayEndMonth());

    // 設置協賛金
    if ( XxcsoSpDecisionConstants.CHECK_YES.equals(installSuppType) )
    {
      if ( !(installPayStartDate == null || "".equals(installPayStartDate))
        && !(installPayEndDate == null || "".equals(installPayEndDate)))
      {
        // 支払期間大小チェック
        try
        {
          StringBuffer sql = new StringBuffer(100);

          sql.append("BEGIN");
          sql.append("  xxcso_020001j_pkg.chk_pay_date(");
          sql.append("    id_pay_start_date      => :1");
          sql.append("   ,id_pay_end_date        => :2");
          sql.append("   ,ov_retcode             => :3");
          sql.append("  );");
          sql.append("END;");

          XxcsoUtils.debug(txn, "execute = " + sql.toString());

          stmt
            = (OracleCallableStatement)
                txn.createCallableStatement(sql.toString(), 0);

          stmt.setDATE(1, installPayStartDate);
          stmt.setDATE(2, installPayEndDate);
          stmt.registerOutParameter(3, OracleTypes.VARCHAR);

          stmt.execute();
          retCode            = stmt.getString(3);
          // チェック結果が正常以外の場合、エラーメッセージを取得&戻り値に格納
          if ( !"0".equals(retCode) )
          {
            token1 = XxcsoSpDecisionConstants.TOKEN_VALUE_MEMO_RANDUM_INFO_REGION
                   + XxcsoConstants.TOKEN_VALUE_DELIMITER1
                   + XxcsoSpDecisionConstants.TOKEN_VALUE_INSTALL_SUPP_PAY_END_DATE;

            token2 = XxcsoSpDecisionConstants.TOKEN_VALUE_MEMO_RANDUM_INFO_REGION
                   + XxcsoConstants.TOKEN_VALUE_DELIMITER1
                   + XxcsoSpDecisionConstants.TOKEN_VALUE_INSTALL_SUPP_PAY_START_DATE;

            OAException error
              = XxcsoMessage.createErrorMessage(
                  XxcsoConstants.APP_XXCSO1_00920
                 ,XxcsoConstants.TOKEN_DATE1
                 ,token1
                 ,XxcsoConstants.TOKEN_DATE2
                 ,token2
                );
            errorList.add(error);          
          }
        }
        catch ( SQLException e )
        {
          XxcsoUtils.unexpected(txn, e);
          throw
            XxcsoMessage.createSqlErrorMessage(
              e
             ,XxcsoSpDecisionConstants.TOKEN_VALUE_CHK_PAY_DATE
             );
        }
        finally
        {
          try
          {
            if ( stmt != null )
            {
              stmt.close();
            }
          }
          catch ( SQLException e )
          {
            XxcsoUtils.unexpected(txn, e);
          }
        }

        // 支払期間開始日チェック
        try
        {
          StringBuffer sql = new StringBuffer(100);
 
          sql.append("BEGIN");
          sql.append("  xxcso_020001j_pkg.chk_pay_start_date(");
          sql.append("    iv_account_number      => :1");
          sql.append("   ,id_pay_start_date      => :2");
          sql.append("   ,id_pay_end_date        => :3");
          sql.append("   ,iv_data_kbn            => :4");
          sql.append("   ,od_pay_start_date      => :5");
          sql.append("   ,od_pay_end_date        => :6");
          sql.append("   ,ov_contract_number     => :7");
          sql.append("   ,ov_sp_decision_number  => :8");
          sql.append("   ,ov_retcode             => :9");
          sql.append("  );");
          sql.append("END;");

          XxcsoUtils.debug(txn, "execute = " + sql.toString());

          stmt
            = (OracleCallableStatement)
                txn.createCallableStatement(sql.toString(), 0);

          stmt.setString(1, installRow.getInstallAccountNumber());
          stmt.setDATE(2, installPayStartDate);
          stmt.setDATE(3, installPayEndDate);
          stmt.setString(4, XxcsoSpDecisionConstants.INSTALL_SUPP_KBN);
          stmt.registerOutParameter(5, OracleTypes.DATE);
          stmt.registerOutParameter(6, OracleTypes.DATE);
          stmt.registerOutParameter(7, OracleTypes.VARCHAR);
          stmt.registerOutParameter(8, OracleTypes.VARCHAR);
          stmt.registerOutParameter(9, OracleTypes.VARCHAR);

          stmt.execute();
          installPayStartMon = new Date(stmt.getDate(5));
          installPayEndMon   = new Date(stmt.getDate(6));
          contractNumber     = stmt.getString(7);
          spNumber           = stmt.getString(8);
          retCode            = stmt.getString(9);

          // 支払期間開始日、支払期間終了日に当月の1日を設定
          headerRow.setInstallPayStartDate((Date)installPayStartMon);
          headerRow.setInstallPayEndDate((Date)installPayEndMon);

          // チェック結果が正常以外の場合、エラーメッセージを取得&戻り値に格納
          if ( !"0".equals(retCode) )
          {
            token1 = XxcsoSpDecisionConstants.TOKEN_VALUE_MEMO_RANDUM_INFO_REGION
                   + XxcsoConstants.TOKEN_VALUE_DELIMITER1
                   + XxcsoSpDecisionConstants.TOKEN_VALUE_INSTALL_SUPP_PAY_START_DATE;

            OAException error
              = XxcsoMessage.createErrorMessage(
                  XxcsoConstants.APP_XXCSO1_00916
                 ,XxcsoConstants.TOKEN_ITEM
                 ,token1
                 ,XxcsoConstants.TOKEN_SP_NUMBER
                 ,spNumber
                 ,XxcsoConstants.TOKEN_CONTRACT_NUMBER
                 ,contractNumber
              );
            errorList.add(error);
          }
        }
        catch ( SQLException e )
        {
          XxcsoUtils.unexpected(txn, e);
          throw
            XxcsoMessage.createSqlErrorMessage(
              e
             ,XxcsoSpDecisionConstants.TOKEN_VALUE_CHK_PAY_START_DATE
             );
        }
        finally
        {
          try
          {
            if ( stmt != null )
            {
              stmt.close();
            }
          }
          catch ( SQLException e )
          {
            XxcsoUtils.unexpected(txn, e);
          }
        }
      }
    }

    // 行政財産使用料
    if ( XxcsoSpDecisionConstants.CHECK_YES.equals(adAssetsType) )
    {
      if ( !(adAssetsPayStartDate == null || "".equals(adAssetsPayStartDate))
        && !(adAssetsPayEndDate == null || "".equals(adAssetsPayEndDate)))
      {
        // 支払期間大小チェック
        try
        {
          StringBuffer sql = new StringBuffer(100);

          sql.append("BEGIN");
          sql.append("  xxcso_020001j_pkg.chk_pay_date(");
          sql.append("    id_pay_start_date      => :1");
          sql.append("   ,id_pay_end_date        => :2");
          sql.append("   ,ov_retcode             => :3");
          sql.append("  );");
          sql.append("END;");

          XxcsoUtils.debug(txn, "execute = " + sql.toString());

          stmt
            = (OracleCallableStatement)
                txn.createCallableStatement(sql.toString(), 0);

          stmt.setDATE(1, adAssetsPayStartDate);
          stmt.setDATE(2, adAssetsPayEndDate);
          stmt.registerOutParameter(3, OracleTypes.VARCHAR);

          stmt.execute();
          retCode            = stmt.getString(3);
          // チェック結果が正常以外の場合、エラーメッセージを取得&戻り値に格納
          if ( !"0".equals(retCode) )
          {
            token1 = XxcsoSpDecisionConstants.TOKEN_VALUE_MEMO_RANDUM_INFO_REGION
                   + XxcsoConstants.TOKEN_VALUE_DELIMITER1
                   + XxcsoSpDecisionConstants.TOKEN_VALUE_AD_ASSETS_PAY_END_DATE;

            token2 = XxcsoSpDecisionConstants.TOKEN_VALUE_MEMO_RANDUM_INFO_REGION
                   + XxcsoConstants.TOKEN_VALUE_DELIMITER1
                   + XxcsoSpDecisionConstants.TOKEN_VALUE_AD_ASSETS_PAY_START_DATE;

            OAException error
              = XxcsoMessage.createErrorMessage(
                  XxcsoConstants.APP_XXCSO1_00920
                 ,XxcsoConstants.TOKEN_DATE1
                 ,token1
                 ,XxcsoConstants.TOKEN_DATE2
                 ,token2
                );
            errorList.add(error);          
          }
        }
        catch ( SQLException e )
        {
          XxcsoUtils.unexpected(txn, e);
          throw
            XxcsoMessage.createSqlErrorMessage(
              e
             ,XxcsoSpDecisionConstants.TOKEN_VALUE_CHK_PAY_DATE
             );
        }
        finally
        {
          try
          {
            if ( stmt != null )
            {
              stmt.close();
            }
          }
          catch ( SQLException e )
          {
            XxcsoUtils.unexpected(txn, e);
          }
        }

        // 支払期間開始日チェック
        try
        {
          StringBuffer sql = new StringBuffer(100);
 
          sql.append("BEGIN");
          sql.append("  xxcso_020001j_pkg.chk_pay_start_date(");
          sql.append("    iv_account_number      => :1");
          sql.append("   ,id_pay_start_date      => :2");
          sql.append("   ,id_pay_end_date        => :3");
          sql.append("   ,iv_data_kbn            => :4");
          sql.append("   ,od_pay_start_date      => :5");
          sql.append("   ,od_pay_end_date        => :6");
          sql.append("   ,ov_contract_number     => :7");
          sql.append("   ,ov_sp_decision_number  => :8");
          sql.append("   ,ov_retcode             => :9");
          sql.append("  );");
          sql.append("END;");

          XxcsoUtils.debug(txn, "execute = " + sql.toString());

          stmt
            = (OracleCallableStatement)
                txn.createCallableStatement(sql.toString(), 0);

          stmt.setString(1, installRow.getInstallAccountNumber());
          stmt.setDATE(2, adAssetsPayStartDate);
          stmt.setDATE(3, adAssetsPayEndDate);
          stmt.setString(4, XxcsoSpDecisionConstants.AD_ASSETS_KBN);
          stmt.registerOutParameter(5, OracleTypes.DATE);
          stmt.registerOutParameter(6, OracleTypes.DATE);
          stmt.registerOutParameter(7, OracleTypes.VARCHAR);
          stmt.registerOutParameter(8, OracleTypes.VARCHAR);
          stmt.registerOutParameter(9, OracleTypes.VARCHAR);

          stmt.execute();
          adAssetsPayStartMon = new Date(stmt.getDate(5));
          adAssetsPayEndMon   = new Date(stmt.getDate(6));
          contractNumber      = stmt.getString(7);
          spNumber            = stmt.getString(8);
          retCode             = stmt.getString(9);

          // 支払期間開始日、支払期間終了日に当月の1日を設定
          headerRow.setAdAssetsPayStartDate((Date)adAssetsPayStartMon);
          headerRow.setAdAssetsPayEndDate((Date)adAssetsPayEndMon);

          // チェック結果が正常以外の場合、エラーメッセージを取得&戻り値に格納
          if ( !"0".equals(retCode) )
          {
            token1 = XxcsoSpDecisionConstants.TOKEN_VALUE_MEMO_RANDUM_INFO_REGION
                   + XxcsoConstants.TOKEN_VALUE_DELIMITER1
                   + XxcsoSpDecisionConstants.TOKEN_VALUE_AD_ASSETS_PAY_START_DATE;

            OAException error
              = XxcsoMessage.createErrorMessage(
                  XxcsoConstants.APP_XXCSO1_00916
                 ,XxcsoConstants.TOKEN_ITEM
                 ,token1
                 ,XxcsoConstants.TOKEN_SP_NUMBER
                 ,spNumber
                 ,XxcsoConstants.TOKEN_CONTRACT_NUMBER
                 ,contractNumber
              );
            errorList.add(error);
          }
        }
        catch ( SQLException e )
        {
          XxcsoUtils.unexpected(txn, e);
          throw
            XxcsoMessage.createSqlErrorMessage(
              e
             ,XxcsoSpDecisionConstants.TOKEN_VALUE_CHK_PAY_START_DATE
            );
        }
        finally
        {
          try
          {
            if ( stmt != null )
            {
              stmt.close();
            }
          }
          catch ( SQLException e )
          {
            XxcsoUtils.unexpected(txn, e);
          }
        }
      }
    }
    return errorList;
 }

   /*****************************************************************************
   * 支払期間開始年月、支払期間終了年月チェック
   * @param txn                 OADBTransactionインスタンス
   * @param headerRow           SP専決ヘッダ登録／更新用ビュー行
   * @param requiredCheckFlag   必須フラグ
   *****************************************************************************
   */
    public static void chkInstallPayAdAssetsPayYearMonth(
      OADBTransaction                     txn
     ,XxcsoSpDecisionHeaderFullVORowImpl headerRow
     ,boolean                             requiredCheckFlag 
    )
    {

      XxcsoUtils.debug(txn, "[START]");
      
      XxcsoValidateUtils utils = XxcsoValidateUtils.getInstance(txn);
      String token1  = null;
      List errorList = new ArrayList();

      ///////////////////////////////////////      
      // 覚書情報：支払期間開始日（設置協賛金）（年）
      ///////////////////////////////////////
      List installPayStartYearList = new ArrayList();
      
      token1 = XxcsoSpDecisionConstants.TOKEN_VALUE_MEMO_RANDUM_INFO_REGION
              + XxcsoConstants.TOKEN_VALUE_DELIMITER1
              + XxcsoSpDecisionConstants.TOKEN_VALUE_INSTALL_SUPP_PAY_START_YEAR;
      installPayStartYearList
        = utils.checkStringToNumber(
            installPayStartYearList
           ,headerRow.getInstallPayStartYear()
           ,token1
           ,0
           ,4
           ,true
           ,true
           ,requiredCheckFlag
           ,0
          ); 

      if( installPayStartYearList.size() == 0 )
      {
        // 支払期間開始日（設置協賛金）（年）が西暦であるかチェック
        if ( ! isYear( headerRow.getInstallPayStartYear() ) )
        {
          installPayStartYearList.add(
              XxcsoMessage.createErrorMessage(
                XxcsoConstants.APP_XXCSO1_00720
               ,XxcsoConstants.TOKEN_COLUMN
               ,token1
              )
          );
        }
      }
      
      errorList.addAll(installPayStartYearList);
               
      ///////////////////////////////////////
      // 覚書情報：支払期間開始日（設置協賛金）（月）
      ///////////////////////////////////////
      List installPayStartMonthList = new ArrayList();
      
      token1 = XxcsoSpDecisionConstants.TOKEN_VALUE_MEMO_RANDUM_INFO_REGION
            + XxcsoConstants.TOKEN_VALUE_DELIMITER1
            + XxcsoSpDecisionConstants.TOKEN_VALUE_INSTALL_SUPP_PAY_START_MONTH;
      installPayStartMonthList
        = utils.checkStringToNumber(
            installPayStartMonthList
           ,headerRow.getInstallPayStartMonth()
           ,token1
           ,0
           ,2
           ,true
           ,true
           ,requiredCheckFlag
           ,0
          ); 

      if( installPayStartMonthList.size() == 0 )
      {
        // 支払期間開始日（設置協賛金）（月）が12以下であるかチェック
        if ( ! isMonth( headerRow.getInstallPayStartMonth() ) )
        {
          installPayStartMonthList.add(
              XxcsoMessage.createErrorMessage(
                XxcsoConstants.APP_XXCSO1_00719
               ,XxcsoConstants.TOKEN_COLUMN
               ,token1
              )
          );
        }    
      }

      errorList.addAll(installPayStartMonthList);
      
      ///////////////////////////////////////
      // 覚書情報：支払期間終了日（設置協賛金）(年)
      ///////////////////////////////////////
      List installPayStartEndYearList = new ArrayList();
      
      token1 = XxcsoSpDecisionConstants.TOKEN_VALUE_MEMO_RANDUM_INFO_REGION
              + XxcsoConstants.TOKEN_VALUE_DELIMITER1
              + XxcsoSpDecisionConstants.TOKEN_VALUE_INSTALL_SUPP_PAY_END_YEAR;
      installPayStartEndYearList
        = utils.checkStringToNumber(
            installPayStartEndYearList
           ,headerRow.getInstallPayEndYear()
           ,token1
           ,0
           ,4
           ,true
           ,true
           ,requiredCheckFlag
           ,0
          ); 

      if( installPayStartEndYearList.size() == 0 )
      {
        // 支払期間終了日（設置協賛金）（年）が西暦であるかチェック
        if ( ! isYear( headerRow.getInstallPayEndYear() ) )
        {
          installPayStartEndYearList.add(
              XxcsoMessage.createErrorMessage(
                XxcsoConstants.APP_XXCSO1_00720
               ,XxcsoConstants.TOKEN_COLUMN
               ,token1
              )
          );
        } 
      }

      errorList.addAll(installPayStartEndYearList);        
     
      ///////////////////////////////////////
      // 覚書情報：支払期間終了日（設置協賛金）(月)
      ///////////////////////////////////////
      List installPayStartEndMonthList = new ArrayList();
      
      token1 = XxcsoSpDecisionConstants.TOKEN_VALUE_MEMO_RANDUM_INFO_REGION
              + XxcsoConstants.TOKEN_VALUE_DELIMITER1
              + XxcsoSpDecisionConstants.TOKEN_VALUE_INSTALL_SUPP_PAY_END_MONTH;
      installPayStartEndMonthList
        = utils.checkStringToNumber(
            installPayStartEndMonthList
           ,headerRow.getInstallPayEndMonth()
           ,token1
           ,0
           ,2
           ,true
           ,true
           ,requiredCheckFlag
           ,0
          );  

      if(installPayStartEndMonthList.size() == 0)
      {
        // 支払期間終了日（設置協賛金）（月）が12以下であるかチェック
        if ( ! isMonth( headerRow.getInstallPayEndMonth() ) )
        {
          installPayStartEndMonthList.add(
              XxcsoMessage.createErrorMessage(
                XxcsoConstants.APP_XXCSO1_00719
               ,XxcsoConstants.TOKEN_COLUMN
               ,token1
              )
          );
        }  
      }

      errorList.addAll(installPayStartEndMonthList);        
      
      ///////////////////////////////////////////
      // 覚書情報：支払期間開始日（行政財産使用料）（年）
      ///////////////////////////////////////////
      List adAssetsPayStartYearList = new ArrayList();
      
      token1 = XxcsoSpDecisionConstants.TOKEN_VALUE_MEMO_RANDUM_INFO_REGION
              + XxcsoConstants.TOKEN_VALUE_DELIMITER1
              + XxcsoSpDecisionConstants.TOKEN_VALUE_AD_ASSETS_PAY_START_YEAR;
      adAssetsPayStartYearList
        = utils.checkStringToNumber(
            adAssetsPayStartYearList
           ,headerRow.getAdAssetsPayStartYear()
           ,token1
           ,0
           ,4
           ,true
           ,true
           ,requiredCheckFlag
           ,0
          );
      if(adAssetsPayStartYearList.size() == 0)
      {
        // 支払期間開始日（行政財産使用料）（年）が西暦であるかチェック
        if ( ! isYear( headerRow.getAdAssetsPayStartYear() ) )
        {
          adAssetsPayStartYearList.add(
              XxcsoMessage.createErrorMessage(
                XxcsoConstants.APP_XXCSO1_00720
               ,XxcsoConstants.TOKEN_COLUMN
               ,token1
              )
          );
        }         
      }

      errorList.addAll(adAssetsPayStartYearList);        

      ///////////////////////////////////////////
      // 覚書情報：支払期間開始日（行政財産使用料）（月）
      ///////////////////////////////////////////
      List adAssetsPayStartMonthList = new ArrayList();
      
      token1 = XxcsoSpDecisionConstants.TOKEN_VALUE_MEMO_RANDUM_INFO_REGION
              + XxcsoConstants.TOKEN_VALUE_DELIMITER1
              + XxcsoSpDecisionConstants.TOKEN_VALUE_AD_ASSETS_PAY_START_MONTH;
      adAssetsPayStartMonthList
        = utils.checkStringToNumber(
            adAssetsPayStartMonthList
           ,headerRow.getAdAssetsPayStartMonth()
           ,token1
           ,0
           ,2
           ,true
           ,true
           ,requiredCheckFlag
           ,0
          );

      if(adAssetsPayStartMonthList.size() == 0)
      {
        // 支払期間開始日（行政財産使用料）（月）が12以下であるかチェック
        if ( ! isMonth( headerRow.getAdAssetsPayStartMonth() ) )
        {
          adAssetsPayStartMonthList.add(
              XxcsoMessage.createErrorMessage(
                XxcsoConstants.APP_XXCSO1_00719
               ,XxcsoConstants.TOKEN_COLUMN
               ,token1
              )
          );
        }
      }

      errorList.addAll(adAssetsPayStartMonthList);       

      ///////////////////////////////////////////
      // 覚書情報：支払期間終了日（行政財産使用料）（年）
      ///////////////////////////////////////////
      List adAssetsPayEndYearList = new ArrayList();
      
      token1 = XxcsoSpDecisionConstants.TOKEN_VALUE_MEMO_RANDUM_INFO_REGION
              + XxcsoConstants.TOKEN_VALUE_DELIMITER1
              + XxcsoSpDecisionConstants.TOKEN_VALUE_AD_ASSETS_PAY_END_YEAR;
      adAssetsPayEndYearList
        = utils.checkStringToNumber(
            adAssetsPayEndYearList
           ,headerRow.getAdAssetsPayEndYear()
           ,token1
           ,0
           ,4
           ,true
           ,true
           ,requiredCheckFlag
           ,0
          ); 

      if( adAssetsPayEndYearList.size() == 0 )
      {
        // 支払期間終了日（行政財産使用料）（年）が西暦であるかチェック
        if ( ! isYear( headerRow.getAdAssetsPayEndYear() ) )
        {
          adAssetsPayEndYearList.add(
              XxcsoMessage.createErrorMessage(
                XxcsoConstants.APP_XXCSO1_00720
               ,XxcsoConstants.TOKEN_COLUMN
               ,token1
              )
          );
        }
      }

      errorList.addAll(adAssetsPayEndYearList);        
      
      ///////////////////////////////////////////
      // 覚書情報：支払期間終了日（行政財産使用料）（月）
      ///////////////////////////////////////////
      List adAssetsPayEndMonthList = new ArrayList();
      
      token1 = XxcsoSpDecisionConstants.TOKEN_VALUE_MEMO_RANDUM_INFO_REGION
              + XxcsoConstants.TOKEN_VALUE_DELIMITER1
              + XxcsoSpDecisionConstants.TOKEN_VALUE_AD_ASSETS_PAY_END_MONTH;        
      adAssetsPayEndMonthList
        = utils.checkStringToNumber(
            adAssetsPayEndMonthList
           ,headerRow.getAdAssetsPayEndMonth()
           ,token1
           ,0
           ,2
           ,true
           ,true
           ,requiredCheckFlag
           ,0
          ); 
      if(adAssetsPayEndMonthList.size() == 0)
      {
        // 支払期間終了日（行政財産使用料）（月）が12以下であるかチェック
        if ( ! isMonth( headerRow.getAdAssetsPayEndMonth() ) )
        {
          adAssetsPayEndMonthList.add(
              XxcsoMessage.createErrorMessage(
                XxcsoConstants.APP_XXCSO1_00719
               ,XxcsoConstants.TOKEN_COLUMN
               ,token1
              )
          );
        }
      }

      errorList.addAll(adAssetsPayEndMonthList);        
      
      if ( errorList.size() > 0 )
      {
        OAException.raiseBundledOAException(errorList);
      }

      XxcsoUtils.debug(txn, "[END]");
    }

    
  /*****************************************************************************
   * 年、月からYYYY-MM-01を作成する
   * @param   strYear    年の文字列
   * @param   strMonth   月の文字列
   * @return  Date     年-月-01
   *****************************************************************************
   */
   public static Date makeDate(String strYear,String strMonth)
   {

     Date returnDate = null;
     String dateStr = "";

     // Ver.1.25 Add Start
     // 月が1桁の場合、先頭0埋めする
     if( strMonth != null && strMonth.length() == 1 )
     {
          strMonth = "0" + strMonth;
     }
     // Ver.1.25 Add End
   
     if( strYear != null && strMonth != null )
     {
          dateStr = strYear + "-" + strMonth + "-01";
     }

     if(!"".equals(dateStr))
     {
          returnDate = new Date(dateStr);
     }
    
    return returnDate;
    
   } 
// Ver.1.24 Add End
}