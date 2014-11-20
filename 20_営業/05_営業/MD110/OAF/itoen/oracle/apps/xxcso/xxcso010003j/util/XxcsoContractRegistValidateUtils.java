/*============================================================================
* ファイル名 : XxcsoContractRegistValidateUtils
* 概要説明   : 自販機設置契約情報登録検証ユーティリティクラス
* バージョン : 1.6
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2009-01-27 1.0  SCS柳平直人  新規作成
* 2009-02-16 1.1  SCS柳平直人  [CT1-005]送付先必須チェック削除
*                              [CT1障害]BM口座名義カナ半角カナチェック修正
* 2009-04-08 1.2  SCS柳平直人  [ST障害T1_0364]仕入先重複チェック修正対応
* 2009-04-09 1.3  SCS柳平直人  [ST障害T1_0327]月末締翌20日払チェック処理修正
* 2009-04-27 1.4  SCS柳平直人  [ST障害T1_0708]入力項目チェック処理統一修正
* 2009-06-08 1.5  SCS柳平直人  [ST障害T1_1307]半角カナチェックメッセージ修正
* 2009-10-14 1.6  SCS阿部大輔  [共通課題IE554,IE573]住所対応
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso010003j.util;

import com.sun.java.util.collections.ArrayList;
import com.sun.java.util.collections.List;

import itoen.oracle.apps.xxcso.common.util.XxcsoConstants;
import itoen.oracle.apps.xxcso.common.util.XxcsoMessage;
import itoen.oracle.apps.xxcso.common.util.XxcsoUtils;
import itoen.oracle.apps.xxcso.common.util.XxcsoValidateUtils;
import itoen.oracle.apps.xxcso.xxcso010003j.server.XxcsoBm1BankAccountFullVOImpl;
import itoen.oracle.apps.xxcso.xxcso010003j.server.XxcsoBm1BankAccountFullVORowImpl;
import itoen.oracle.apps.xxcso.xxcso010003j.server.XxcsoBm1DestinationFullVOImpl;
import itoen.oracle.apps.xxcso.xxcso010003j.server.XxcsoBm1DestinationFullVORowImpl;
import itoen.oracle.apps.xxcso.xxcso010003j.server.XxcsoBm2BankAccountFullVOImpl;
import itoen.oracle.apps.xxcso.xxcso010003j.server.XxcsoBm2BankAccountFullVORowImpl;
import itoen.oracle.apps.xxcso.xxcso010003j.server.XxcsoBm2DestinationFullVOImpl;
import itoen.oracle.apps.xxcso.xxcso010003j.server.XxcsoBm2DestinationFullVORowImpl;
import itoen.oracle.apps.xxcso.xxcso010003j.server.XxcsoBm3BankAccountFullVOImpl;
import itoen.oracle.apps.xxcso.xxcso010003j.server.XxcsoBm3BankAccountFullVORowImpl;
import itoen.oracle.apps.xxcso.xxcso010003j.server.XxcsoBm3DestinationFullVOImpl;
import itoen.oracle.apps.xxcso.xxcso010003j.server.XxcsoBm3DestinationFullVORowImpl;
import itoen.oracle.apps.xxcso.xxcso010003j.server.XxcsoContractCustomerFullVOImpl;
import itoen.oracle.apps.xxcso.xxcso010003j.server.XxcsoContractCustomerFullVORowImpl;
import itoen.oracle.apps.xxcso.xxcso010003j.server.XxcsoContractManagementFullVOImpl;
import itoen.oracle.apps.xxcso.xxcso010003j.server.XxcsoContractManagementFullVORowImpl;
import itoen.oracle.apps.xxcso.xxcso010003j.server.XxcsoPageRenderVOImpl;
import itoen.oracle.apps.xxcso.xxcso010003j.server.XxcsoPageRenderVORowImpl;
import java.sql.SQLException;
import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.framework.server.OADBTransaction;
import oracle.jbo.domain.Number;
import oracle.jbo.domain.Date;
import oracle.jdbc.OracleCallableStatement;
import oracle.jdbc.OracleTypes;
// 2009-04-08 [ST障害T1_0364] Add Start
import oracle.sql.NUMBER;
import com.sun.java.util.collections.HashMap;
import com.sun.java.util.collections.Iterator;
// 2009-04-08 [ST障害T1_0364] Add End

/*******************************************************************************
 * 自販機設置契約情報登録検証ユーティリティクラス。
 * @author  SCS柳平直人
 * @version 1.1
 *******************************************************************************
 */
public class XxcsoContractRegistValidateUtils 
{

  /*****************************************************************************
   * 契約者（甲）情報の検証
   * @param txn         OADBTransactionインスタンス
   * @param cntrctVo    契約先テーブル情報用ビューインスタンス
   * @param fixedFrag   確定ボタン押下フラグ
   * @return List       エラーリスト
   *****************************************************************************
   */
  public static List validateContractCustomer(
    OADBTransaction                     txn
   ,XxcsoContractManagementFullVOImpl   mngVo
   ,XxcsoContractCustomerFullVOImpl     cntrctVo
   ,boolean                             fixedFrag
  )
  {
    List   errorList = new ArrayList();
    String token1    = null;

    final String tokenMain
      = XxcsoContractRegistConstants.TOKEN_VALUE_CONTRACT_INFO
       + XxcsoConstants.TOKEN_VALUE_DELIMITER1;

    XxcsoUtils.debug(txn, "[START]");

    // ***********************************
    // データ行を取得
    // ***********************************
    XxcsoContractManagementFullVORowImpl mngVoRow
      = (XxcsoContractManagementFullVORowImpl) mngVo.first();

    XxcsoContractCustomerFullVORowImpl cntrctVoRow
      = (XxcsoContractCustomerFullVORowImpl) cntrctVo.first(); 

    XxcsoValidateUtils utils = XxcsoValidateUtils.getInstance(txn);

    // ///////////////////////////////////
    // 契約先名
    // ///////////////////////////////////
    token1 = tokenMain
            + XxcsoContractRegistConstants.TOKEN_VALUE_CONTRACT_NAME;
    // 確定ボタン時のみ必須入力チェック
    if ( fixedFrag )
    {
      errorList
        =  utils.requiredCheck(
             errorList
            ,cntrctVoRow.getContractName()
            ,token1
            ,0
           );
    }
    // 禁則文字チェック
    errorList
      = utils.checkIllegalString(
          errorList
         ,cntrctVoRow.getContractName()
         ,token1
         ,0
        );
// 2009-04-27 [ST障害T1_0708] Add Start
    // 全角文字チェック
    if ( ! isDoubleByte( txn, cntrctVoRow.getContractName() ) )
    {
      OAException error
        = XxcsoMessage.createErrorMessage(
            XxcsoConstants.APP_XXCSO1_00565
           ,XxcsoConstants.TOKEN_REGION
           ,XxcsoContractRegistConstants.TOKEN_VALUE_CONTRACT_INFO
           ,XxcsoConstants.TOKEN_COLUMN
           ,XxcsoContractRegistConstants.TOKEN_VALUE_CONTRACT_NAME
          );
      errorList.add(error);
    }
// 2009-04-27 [ST障害T1_0708] Add End

    // ///////////////////////////////////
    // 代表者名
    // ///////////////////////////////////
    token1 = tokenMain
            + XxcsoContractRegistConstants.TOKEN_VALUE_DELEGATE_NAME;
    // 確定ボタン時のみ必須入力チェック
    if ( fixedFrag )
    {
      errorList
        =  utils.requiredCheck(
             errorList
            ,cntrctVoRow.getDelegateName()
            ,token1
            ,0
           );
    }
    // 禁則文字チェック
    errorList
      = utils.checkIllegalString(
          errorList
         ,cntrctVoRow.getDelegateName()
         ,token1
         ,0
        );
// 2009-04-27 [ST障害T1_0708] Add Start
    // 全角文字チェック
    if ( ! isDoubleByte( txn, cntrctVoRow.getDelegateName() ) )
    {
      OAException error
        = XxcsoMessage.createErrorMessage(
            XxcsoConstants.APP_XXCSO1_00565
           ,XxcsoConstants.TOKEN_REGION
           ,XxcsoContractRegistConstants.TOKEN_VALUE_CONTRACT_INFO
           ,XxcsoConstants.TOKEN_COLUMN
           ,XxcsoContractRegistConstants.TOKEN_VALUE_DELEGATE_NAME
          );
      errorList.add(error);
    }
// 2009-04-27 [ST障害T1_0708] Add End

    // ///////////////////////////////////
    // 郵便番号
    // ///////////////////////////////////
    token1 = tokenMain
            + XxcsoContractRegistConstants.TOKEN_VALUE_CONTRACT_POST_CODE;
    if ( fixedFrag )
    {
      errorList
        = utils.requiredCheck(
            errorList
           ,cntrctVoRow.getPostCode()
           ,token1
           ,0
          );
    }
    if ( ! isPostalCode(cntrctVoRow.getPostCode()) )
    {
      token1 = tokenMain
              + XxcsoContractRegistConstants.TOKEN_VALUE_CONTRACT_POST_CODE;
      OAException error
        = XxcsoMessage.createErrorMessage(
            XxcsoConstants.APP_XXCSO1_00532
           ,XxcsoConstants.TOKEN_REGION
           ,XxcsoContractRegistConstants.TOKEN_VALUE_CONTRACT_INFO
          );
      errorList.add(error);
    }

    // ///////////////////////////////////
    // 都道府県
    // ///////////////////////////////////
    token1 = tokenMain
            + XxcsoContractRegistConstants.TOKEN_VALUE_CONTRACT_PREFECTURES;
    // 確定ボタン時のみ必須入力チェック
    if ( fixedFrag )
    {
      errorList
        =  utils.requiredCheck(
             errorList
            ,cntrctVoRow.getPrefectures()
            ,token1
            ,0
           );
    }
    // 禁則文字チェック
    errorList
      = utils.checkIllegalString(
          errorList
         ,cntrctVoRow.getPrefectures()
         ,token1
         ,0
        );
// 2009-04-27 [ST障害T1_0708] Add Start
    // 全角文字チェック
    if ( ! isDoubleByte( txn, cntrctVoRow.getPrefectures() ) )
    {
      OAException error
        = XxcsoMessage.createErrorMessage(
            XxcsoConstants.APP_XXCSO1_00565
           ,XxcsoConstants.TOKEN_REGION
           ,XxcsoContractRegistConstants.TOKEN_VALUE_CONTRACT_INFO
           ,XxcsoConstants.TOKEN_COLUMN
           ,XxcsoContractRegistConstants.TOKEN_VALUE_CONTRACT_PREFECTURES
          );
      errorList.add(error);
    }
// 2009-04-27 [ST障害T1_0708] Add End

    // ///////////////////////////////////
    // 市・区
    // ///////////////////////////////////
    token1 = tokenMain
            + XxcsoContractRegistConstants.TOKEN_VALUE_CONTRACT_CITY_WARD;
    // 確定ボタン時のみ必須入力チェック
    if ( fixedFrag )
    {
      errorList
        =  utils.requiredCheck(
             errorList
            ,cntrctVoRow.getCityWard()
            ,token1
            ,0
           );
    }
    // 禁則文字チェック
    errorList
      = utils.checkIllegalString(
          errorList
         ,cntrctVoRow.getCityWard()
         ,token1
         ,0
        );
// 2009-04-27 [ST障害T1_0708] Add Start
    // 全角文字チェック
    if ( ! isDoubleByte( txn, cntrctVoRow.getCityWard() ) )
    {
      OAException error
        = XxcsoMessage.createErrorMessage(
            XxcsoConstants.APP_XXCSO1_00565
           ,XxcsoConstants.TOKEN_REGION
           ,XxcsoContractRegistConstants.TOKEN_VALUE_CONTRACT_INFO
           ,XxcsoConstants.TOKEN_COLUMN
           ,XxcsoContractRegistConstants.TOKEN_VALUE_CONTRACT_CITY_WARD
          );
      errorList.add(error);
    }
// 2009-04-27 [ST障害T1_0708] Add End

    // ///////////////////////////////////
    // 住所１
    // ///////////////////////////////////
    token1 = tokenMain
            + XxcsoContractRegistConstants.TOKEN_VALUE_CONTRACT_ADDRESS_1;
    // 確定ボタン時のみ必須入力チェック
    if ( fixedFrag )
    {
      errorList
        =  utils.requiredCheck(
             errorList
            ,cntrctVoRow.getAddress1()
            ,token1
            ,0
           );
    }
    // 禁則文字チェック
    errorList
      = utils.checkIllegalString(
          errorList
         ,cntrctVoRow.getAddress1()
         ,token1
         ,0
        );
// 2009-04-27 [ST障害T1_0708] Add Start
    // 全角文字チェック
    if ( ! isDoubleByte( txn, cntrctVoRow.getAddress1() ) )
    {
      OAException error
        = XxcsoMessage.createErrorMessage(
            XxcsoConstants.APP_XXCSO1_00565
           ,XxcsoConstants.TOKEN_REGION
           ,XxcsoContractRegistConstants.TOKEN_VALUE_CONTRACT_INFO
           ,XxcsoConstants.TOKEN_COLUMN
           ,XxcsoContractRegistConstants.TOKEN_VALUE_CONTRACT_ADDRESS_1
          );
      errorList.add(error);
    }
// 2009-04-27 [ST障害T1_0708] Add End

    // ///////////////////////////////////
    // 住所２
    // ///////////////////////////////////
    token1 = tokenMain
            + XxcsoContractRegistConstants.TOKEN_VALUE_CONTRACT_ADDRESS_2;
    // 禁則文字チェック
    errorList
      = utils.checkIllegalString(
          errorList
         ,cntrctVoRow.getAddress2()
         ,token1
         ,0
        );
// 2009-04-27 [ST障害T1_0708] Add Start
    // 全角文字チェック
    if ( ! isDoubleByte( txn, cntrctVoRow.getAddress2() ) )
    {
      OAException error
        = XxcsoMessage.createErrorMessage(
            XxcsoConstants.APP_XXCSO1_00565
           ,XxcsoConstants.TOKEN_REGION
           ,XxcsoContractRegistConstants.TOKEN_VALUE_CONTRACT_INFO
           ,XxcsoConstants.TOKEN_COLUMN
           ,XxcsoContractRegistConstants.TOKEN_VALUE_CONTRACT_ADDRESS_2
          );
      errorList.add(error);
    }
// 2009-04-27 [ST障害T1_0708] Add End

    // ///////////////////////////////////
    // 契約書発行日
    // ///////////////////////////////////
    token1 = tokenMain
            + XxcsoContractRegistConstants.TOKEN_VALUE_CONTRACT_EFFECT_DATE;
    // 確定ボタン時のみ必須入力チェック
    if ( fixedFrag )
    {
      errorList
        =  utils.requiredCheck(
             errorList
            ,mngVoRow.getContractEffectDate()
            ,token1
            ,0
           );
    }

    XxcsoUtils.debug(txn, "[END]");

    return errorList;
  }

  /*****************************************************************************
   * 振込日・締め日情報の検証
   * @param txn         OADBTransactionインスタンス
   * @param pageRndrVo  ページ属性設定ビューインスタンス
   * @param mngVo       契約管理テーブル情報ビューインスタンス
   * @param fixedFrag   確定ボタン押下フラグ
   * @return List       エラーリスト
   *****************************************************************************
   */
  public static List validateContractTransfer(
    OADBTransaction                     txn
   ,XxcsoPageRenderVOImpl               pageRndrVo
   ,XxcsoContractManagementFullVOImpl   mngVo
   ,boolean                             fixedFrag
  )
  {
    List errorList = new ArrayList();

    final String tokenMain
      = XxcsoContractRegistConstants.TOKEN_VALUE_PAYCOND_INFO
       + XxcsoConstants.TOKEN_VALUE_DELIMITER1;

    String token1 = null;

    XxcsoUtils.debug(txn, "[START]");

    // ***********************************
    // データ行を取得
    // ***********************************
    XxcsoPageRenderVORowImpl pageRndrVoRow
      = (XxcsoPageRenderVORowImpl) pageRndrVo.first();

    XxcsoContractManagementFullVORowImpl mngVoRow
      = (XxcsoContractManagementFullVORowImpl) mngVo.first();


    // SP専決明細で手数料が発生しない場合は「-」表示となるためチェック不要
    if ( pageRndrVoRow.getPayCondInfoDisabled().booleanValue() )
    {
      return errorList;
    }

    XxcsoValidateUtils utils = XxcsoValidateUtils.getInstance(txn);

    // ///////////////////////////////////
    // 締め日
    // ///////////////////////////////////
    token1 = tokenMain
            + XxcsoContractRegistConstants.TOKEN_VALUE_CLOSE_DAY_CODE;

    // 確定ボタン時のみ必須入力チェック
    if ( fixedFrag )
    {
      errorList
        =  utils.requiredCheck(
             errorList
            ,mngVoRow.getCloseDayCode()
            ,token1
            ,0
           );
    }

    // ///////////////////////////////////
    // 振込月
    // ///////////////////////////////////
    token1 = tokenMain
            + XxcsoContractRegistConstants.TOKEN_VALUE_TRANSFER_MONTH_CODE;
    if ( fixedFrag )
    {
      errorList
        =  utils.requiredCheck(
             errorList
            ,mngVoRow.getTransferMonthCode()
            ,token1
            ,0
           );
    }
    

    // ///////////////////////////////////
    // 振込日
    // ///////////////////////////////////
    token1 = tokenMain
            + XxcsoContractRegistConstants.TOKEN_VALUE_TRANSFER_DAY_CODE;
    if ( fixedFrag )
    {
      errorList
        =  utils.requiredCheck(
             errorList
            ,mngVoRow.getTransferDayCode()
            ,token1
            ,0
           );
    }

    XxcsoUtils.debug(txn, "[END]");

    return errorList;
  }

  /*****************************************************************************
   * 契約期間・途中解除情報の検証
   * @param txn         OADBTransactionインスタンス
   * @param mngVo       契約管理テーブル情報ビューインスタンス
   * @param fixedFrag   確定ボタン押下フラグ
   * @return List       エラーリスト
   *****************************************************************************
   */
  public static List validateCancellationOffer(
    OADBTransaction                     txn
   ,XxcsoContractManagementFullVOImpl   mngVo
   ,boolean                             fixedFrag
  )
  {
    List errorList = new ArrayList();

    final String tokenMain
      = XxcsoContractRegistConstants.TOKEN_VALUE_PERIOD_INFO
       + XxcsoConstants.TOKEN_VALUE_DELIMITER1;

    String token1 = null;

    XxcsoUtils.debug(txn, "[START]");

    // ***********************************
    // データ行を取得
    // ***********************************
    XxcsoContractManagementFullVORowImpl mngVoRow
      = (XxcsoContractManagementFullVORowImpl) mngVo.first();

    XxcsoValidateUtils utils = XxcsoValidateUtils.getInstance(txn);

    // ///////////////////////////////////
    // 契約解除申出
    // ///////////////////////////////////
    token1 = tokenMain
            + XxcsoContractRegistConstants.TOKEN_VALUE_CANCELLATION_OFFER_CODE;
    // 確定ボタン時のみ必須入力チェック
    if ( fixedFrag )
    {
      errorList
        =  utils.requiredCheck(
             errorList
            ,mngVoRow.getCancellationOfferCode()
            ,token1
            ,0
           );
    }

    XxcsoUtils.debug(txn, "[END]");

    return errorList;
  }

  /*****************************************************************************
   * ＢＭ１指定情報の検証
   * @param txn          OADBTransactionインスタンス
   * @param pageRndrVo   ページ属性設定用ビューインスタンス
   * @param bm1DestVo    送付先テーブル情報用ビューインスタンス
   * @param bm1BankAccVo 銀行口座アドオンマスタ情報用ビューインスタンス
   * @param isFixed      確定ボタン押下フラグ
   * @return List        エラーリスト
   *****************************************************************************
   */
  public static List validateBm1Dest(
    OADBTransaction                     txn
   ,XxcsoPageRenderVOImpl               pageRndrVo
   ,XxcsoBm1DestinationFullVOImpl       bm1DestVo
   ,XxcsoBm1BankAccountFullVOImpl       bm1BankAccVo
   ,boolean                             fixedFrag
  )
  {
    List errorList = new ArrayList();

    final String tokenMain
      = XxcsoContractRegistConstants.TOKEN_VALUE_BM1_DEST
       + XxcsoConstants.TOKEN_VALUE_DELIMITER1
       + XxcsoContractRegistConstants.TOKEN_VALUE_BM1;
    
    String token1 = null;

    XxcsoUtils.debug(txn, "[START]");

    // ***********************************
    // データ行を取得
    // ***********************************
    XxcsoPageRenderVORowImpl pageRndrVoRow
      = (XxcsoPageRenderVORowImpl) pageRndrVo.first();

    XxcsoBm1DestinationFullVORowImpl bm1DestVoRow
      = (XxcsoBm1DestinationFullVORowImpl) bm1DestVo.first();

    XxcsoBm1BankAccountFullVORowImpl bm1BankAccVoRow
      = (XxcsoBm1BankAccountFullVORowImpl) bm1BankAccVo.first();


    // 指定チェックのON／OFFチェック
    if ( !isChecked( pageRndrVoRow.getBm1ExistFlag() ) )
    {
      // OFFの場合は終了
      return errorList;
    }

    XxcsoValidateUtils utils = XxcsoValidateUtils.getInstance(txn);

    // ///////////////////////////////////
    // 振込手数料負担
    // ///////////////////////////////////
    token1 = tokenMain
        + XxcsoContractRegistConstants.TOKEN_VALUE_BANK_TRANSFER_FEE_CHARGE_DIV;
    // 確定ボタン時のみ必須入力チェック
    if ( fixedFrag )
    {
      errorList
        =  utils.requiredCheck(
             errorList
            ,bm1DestVoRow.getBankTransferFeeChargeDiv()
            ,token1
            ,0
           );
    }

    // ///////////////////////////////////
    // 支払方法、明細書
    // ///////////////////////////////////
    token1 = tokenMain
            + XxcsoContractRegistConstants.TOKEN_VALUE_BELLING_DETAILS_DIV;
    // 確定ボタン時のみ必須入力チェック
    if ( fixedFrag )
    {
      errorList
        = utils.requiredCheck(
            errorList
           ,bm1DestVoRow.getBellingDetailsDiv()
           ,token1
           ,0
          );
    }

    // ///////////////////////////////////
    // 問合せ担当拠点
    // ///////////////////////////////////
    token1 = tokenMain
            + XxcsoContractRegistConstants.TOKEN_VALUE_INQUERY_CHARGE_HUB_CD;

    // 確定ボタン時のみ必須入力チェック
    if ( fixedFrag )
    {
      errorList
        = utils.requiredCheck(
            errorList
           ,bm1DestVoRow.getInqueryChargeHubCd()
           ,token1
           ,0
          );
    }

    // ///////////////////////////////////
    // 送付先名
    // ///////////////////////////////////
    token1 = tokenMain
            + XxcsoContractRegistConstants.TOKEN_VALUE_PAYMENT_NAME;
    // 確定ボタン時のみ必須入力チェック
    if ( fixedFrag )
    {
      errorList
        = utils.requiredCheck(
            errorList
           ,bm1DestVoRow.getPaymentName()
           ,token1
           ,0
          );
    }
    // 禁則文字チェック
    errorList
      = utils.checkIllegalString(
          errorList
         ,bm1DestVoRow.getPaymentName()
         ,token1
         ,0
        );
// 2009-04-27 [ST障害T1_0708] Add Start
    // 全角文字チェック
    if ( ! isDoubleByte( txn, bm1DestVoRow.getPaymentName() ) )
    {
      OAException error
        = XxcsoMessage.createErrorMessage(
            XxcsoConstants.APP_XXCSO1_00565
           ,XxcsoConstants.TOKEN_REGION
           ,XxcsoContractRegistConstants.TOKEN_VALUE_BM1_DEST
           ,XxcsoConstants.TOKEN_COLUMN
           ,XxcsoContractRegistConstants.TOKEN_VALUE_PAYMENT_NAME
          );
      errorList.add(error);
    }
// 2009-04-27 [ST障害T1_0708] Add End

    // ///////////////////////////////////
    // 送付先名カナ
    // ///////////////////////////////////
    token1 = tokenMain
            + XxcsoContractRegistConstants.TOKEN_VALUE_PAYMENT_NAME_ALT;

    // 確定ボタン時のみ必須入力チェック
    if ( fixedFrag )
    {
      errorList
        = utils.requiredCheck(
            errorList
           ,bm1DestVoRow.getPaymentNameAlt()
           ,token1
           ,0
          );
    }
    // 禁則文字チェック
    errorList
      = utils.checkIllegalString(
          errorList
         ,bm1DestVoRow.getPaymentNameAlt()
         ,token1
         ,0
        );
// 2009-04-27 [ST障害T1_0708] Mod Start
//    // 全角カナチェック
//    if ( ! isDoubleByteKana(txn, bm1DestVoRow.getPaymentNameAlt()) )
//    {
//      OAException error
//        = XxcsoMessage.createErrorMessage(
//            XxcsoConstants.APP_XXCSO1_00286
//           ,XxcsoConstants.TOKEN_REGION
//           ,XxcsoContractRegistConstants.TOKEN_VALUE_BM1_DEST
//           ,XxcsoConstants.TOKEN_COLUMN
//           ,XxcsoContractRegistConstants.TOKEN_VALUE_PAYMENT_NAME_ALT
//          );
//      errorList.add(error);
//    }
    // 半角カナチェック
    if ( ! isSingleByteKana( txn, bm1DestVoRow.getPaymentNameAlt() ) )
    {
      OAException error
        = XxcsoMessage.createErrorMessage(
// 2009-06-08 [ST障害T1_1307] Mod Start
//            XxcsoConstants.APP_XXCSO1_00533
            XxcsoConstants.APP_XXCSO1_00573
// 2009-06-08 [ST障害T1_1307] Mod End
           ,XxcsoConstants.TOKEN_REGION
           ,XxcsoContractRegistConstants.TOKEN_VALUE_BM1_DEST
           ,XxcsoConstants.TOKEN_COLUMN
           ,XxcsoContractRegistConstants.TOKEN_VALUE_PAYMENT_NAME_ALT
          );
      errorList.add(error);
    }
// 2009-04-27 [ST障害T1_0708] Mod End

    // ///////////////////////////////////
    // 送付先住所（郵便番号）
    // ///////////////////////////////////
    token1 = tokenMain
            + XxcsoContractRegistConstants.TOKEN_VALUE_POST_CODE;
    if ( fixedFrag )
    {
      errorList
        = utils.requiredCheck(
            errorList
           ,bm1DestVoRow.getPostCode()
           ,token1
           ,0
          );
    }
    if ( ! isPostalCode(bm1DestVoRow.getPostCode()) )
    {
      OAException error
        = XxcsoMessage.createErrorMessage(
            XxcsoConstants.APP_XXCSO1_00532
           ,XxcsoConstants.TOKEN_REGION
           ,XxcsoContractRegistConstants.TOKEN_VALUE_BM1_DEST
          );
      errorList.add(error);
    }
// 2009-10-14 [IE554,IE573] Add Start
//    // ///////////////////////////////////
//    // 送付先住所（都道府県）
//    // ///////////////////////////////////
//    token1 = tokenMain
//            + XxcsoContractRegistConstants.TOKEN_VALUE_PREFECTURES;
//
//    // 確定ボタン時のみ必須入力チェック
//    if ( fixedFrag )
//    {
//      errorList
//        = utils.requiredCheck(
//            errorList
//           ,bm1DestVoRow.getPrefectures()
//           ,token1
//           ,0
//          );
//    }
//    // 禁則文字チェック
//    errorList
//      = utils.checkIllegalString(
//          errorList
//         ,bm1DestVoRow.getPrefectures()
//         ,token1
//         ,0
//        );
//// 2009-04-27 [ST障害T1_0708] Add Start
//    // 全角文字チェック
//    if ( ! isDoubleByte( txn, bm1DestVoRow.getPrefectures() ) )
//    {
//      OAException error
//        = XxcsoMessage.createErrorMessage(
//            XxcsoConstants.APP_XXCSO1_00565
//           ,XxcsoConstants.TOKEN_REGION
//           ,XxcsoContractRegistConstants.TOKEN_VALUE_BM1_DEST
//           ,XxcsoConstants.TOKEN_COLUMN
//           ,XxcsoContractRegistConstants.TOKEN_VALUE_PREFECTURES
//          );
//      errorList.add(error);
//    }
//// 2009-04-27 [ST障害T1_0708] Add End
//
//    // ///////////////////////////////////
//    // 送付先住所（市・区）
//    // ///////////////////////////////////
//    token1 = tokenMain
//            + XxcsoContractRegistConstants.TOKEN_VALUE_CITY_WARD;
//    // 確定ボタン時のみ必須入力チェック
//    if ( fixedFrag )
//    {
//      errorList
//        = utils.requiredCheck(
//            errorList
//           ,bm1DestVoRow.getCityWard()
//           ,token1
//           ,0
//          );
//    }
//    // 禁則文字チェック
//    errorList
//      = utils.checkIllegalString(
//          errorList
//         ,bm1DestVoRow.getCityWard()
//         ,token1
//         ,0
//        );
//// 2009-04-27 [ST障害T1_0708] Add Start
//    // 全角文字チェック
//    if ( ! isDoubleByte( txn, bm1DestVoRow.getCityWard() ) )
//    {
//      OAException error
//        = XxcsoMessage.createErrorMessage(
//            XxcsoConstants.APP_XXCSO1_00565
//           ,XxcsoConstants.TOKEN_REGION
//           ,XxcsoContractRegistConstants.TOKEN_VALUE_BM1_DEST
//           ,XxcsoConstants.TOKEN_COLUMN
//           ,XxcsoContractRegistConstants.TOKEN_VALUE_CITY_WARD
//          );
//      errorList.add(error);
//    }
//// 2009-04-27 [ST障害T1_0708] Add End
// 2009-10-14 [IE554,IE573] Add End
    // ///////////////////////////////////
    // 送付先住所（住所１）
    // ///////////////////////////////////
    token1 = tokenMain
            + XxcsoContractRegistConstants.TOKEN_VALUE_ADDRESS_1;
    // 確定ボタン時のみ必須入力チェック
    if ( fixedFrag )
    {
      errorList
        = utils.requiredCheck(
            errorList
           ,bm1DestVoRow.getAddress1()
           ,token1
           ,0
          );
    }
    // 禁則文字チェック
    errorList
      = utils.checkIllegalString(
          errorList
         ,bm1DestVoRow.getAddress1()
         ,token1
         ,0
        );
// 2009-04-27 [ST障害T1_0708] Add Start
    // 全角文字チェック
    if ( ! isDoubleByte( txn, bm1DestVoRow.getAddress1() ) )
    {
      OAException error
        = XxcsoMessage.createErrorMessage(
            XxcsoConstants.APP_XXCSO1_00565
           ,XxcsoConstants.TOKEN_REGION
           ,XxcsoContractRegistConstants.TOKEN_VALUE_BM1_DEST
           ,XxcsoConstants.TOKEN_COLUMN
           ,XxcsoContractRegistConstants.TOKEN_VALUE_ADDRESS_1
          );
      errorList.add(error);
    }
// 2009-04-27 [ST障害T1_0708] Add End

    // ///////////////////////////////////
    // 送付先住所（住所２）
    // ///////////////////////////////////
    token1 = tokenMain
            + XxcsoContractRegistConstants.TOKEN_VALUE_ADDRESS_2;
    // 禁則文字チェック
    errorList
      = utils.checkIllegalString(
          errorList
         ,bm1DestVoRow.getAddress2()
         ,token1
         ,0
        );
// 2009-04-27 [ST障害T1_0708] Add Start
    // 全角文字チェック
    if ( ! isDoubleByte( txn, bm1DestVoRow.getAddress2() ) )
    {
      OAException error
        = XxcsoMessage.createErrorMessage(
            XxcsoConstants.APP_XXCSO1_00565
           ,XxcsoConstants.TOKEN_REGION
           ,XxcsoContractRegistConstants.TOKEN_VALUE_BM1_DEST
           ,XxcsoConstants.TOKEN_COLUMN
           ,XxcsoContractRegistConstants.TOKEN_VALUE_ADDRESS_2
          );
      errorList.add(error);
    }
// 2009-04-27 [ST障害T1_0708] Add End

    // ///////////////////////////////////
    // 送付先電話番号
    // ///////////////////////////////////
    token1 = tokenMain
            + XxcsoContractRegistConstants.TOKEN_VALUE_ADDRESS_LINES_PHONETIC;

    if ( ! utils.isTelNumber(bm1DestVoRow.getAddressLinesPhonetic()) )
    {
      OAException error
        = XxcsoMessage.createErrorMessage(
            XxcsoConstants.APP_XXCSO1_00288
           ,XxcsoConstants.TOKEN_REGION
           ,XxcsoContractRegistConstants.TOKEN_VALUE_BM1_DEST
          );
      errorList.add(error);
    }

    // ///////////////////////////////////
    // 金融機関名
    // ///////////////////////////////////
    token1 = tokenMain
            + XxcsoContractRegistConstants.TOKEN_VALUE_BANK_NUMBER;
    // 確定ボタン時のみ必須入力チェック
    if ( fixedFrag )
    {
      errorList
        = utils.requiredCheck(
            errorList
           ,bm1BankAccVoRow.getBankNumber()
           ,token1
           ,0
          );
    }

    // ///////////////////////////////////
    // 口座種別
    // ///////////////////////////////////
    token1 = tokenMain
            + XxcsoContractRegistConstants.TOKEN_VALUE_BANK_ACCOUNT_TYPE;
    // 確定ボタン時のみ必須入力チェック
    if ( fixedFrag )
    {
      errorList
        = utils.requiredCheck(
            errorList
           ,bm1BankAccVoRow.getBankAccountType()
           ,token1
           ,0
          );
    }

    // ///////////////////////////////////
    // 口座番号
    // ///////////////////////////////////
    token1 = tokenMain
            + XxcsoContractRegistConstants.TOKEN_VALUE_BANK_ACCOUNT_NUMBER;
    // 確定ボタン時のみ必須入力チェック
    if ( fixedFrag )
    {
      errorList
        = utils.requiredCheck(
            errorList
           ,bm1BankAccVoRow.getBankAccountNumber()
           ,token1
           ,0
          );
    }
    // 禁則文字チェック
    errorList
      = utils.checkIllegalString(
          errorList
         ,bm1BankAccVoRow.getBankAccountNumber()
         ,token1
         ,0
        );

    // ///////////////////////////////////
    // 口座名義カナ
    // ///////////////////////////////////
    token1 = tokenMain
            + XxcsoContractRegistConstants.TOKEN_VALUE_BANK_ACCOUNT_NAME_KANA;
    // 確定ボタン時のみ必須入力チェック
    if ( fixedFrag )
    {
      errorList
        = utils.requiredCheck(
            errorList
           ,bm1BankAccVoRow.getBankAccountNameKana()
           ,token1
           ,0
          );
    }

    // 禁則文字チェック
    errorList
      = utils.checkIllegalString(
          errorList
         ,bm1BankAccVoRow.getBankAccountNameKana()
         ,token1
         ,0
        );

    // 半角カナチェック（BFA関数）
    if ( ! isBfaSingleByteKana(txn, bm1BankAccVoRow.getBankAccountNameKana()) )
    {
      OAException error
        = XxcsoMessage.createErrorMessage(
            XxcsoConstants.APP_XXCSO1_00533
           ,XxcsoConstants.TOKEN_REGION
           ,XxcsoContractRegistConstants.TOKEN_VALUE_BM1_DEST
           ,XxcsoConstants.TOKEN_COLUMN
           ,XxcsoContractRegistConstants.TOKEN_VALUE_BANK_ACCOUNT_NAME_KANA
          );
      errorList.add(error);
    }

    // ///////////////////////////////////
    // 口座名義漢字
    // ///////////////////////////////////
    token1 = tokenMain
            + XxcsoContractRegistConstants.TOKEN_VALUE_BANK_ACCOUNT_NAME_KANJI;
    // 確定ボタン時のみ必須入力チェック
    if ( fixedFrag )
    {
      errorList
        = utils.requiredCheck(
            errorList
           ,bm1BankAccVoRow.getBankAccountNameKanji()
           ,token1
           ,0
          );
    }
    // 禁則文字チェック
    errorList
      = utils.checkIllegalString(
          errorList
         ,bm1BankAccVoRow.getBankAccountNameKanji()
         ,token1
         ,0
        );
// 2009-04-27 [ST障害T1_0708] Add Start
    // 全角文字チェック
    if ( ! isDoubleByte( txn, bm1BankAccVoRow.getBankAccountNameKanji() ) )
    {
      OAException error
        = XxcsoMessage.createErrorMessage(
            XxcsoConstants.APP_XXCSO1_00565
           ,XxcsoConstants.TOKEN_REGION
           ,XxcsoContractRegistConstants.TOKEN_VALUE_BM1_DEST
           ,XxcsoConstants.TOKEN_COLUMN
           ,XxcsoContractRegistConstants.TOKEN_VALUE_BANK_ACCOUNT_NAME_KANJI
          );
      errorList.add(error);
    }
// 2009-04-27 [ST障害T1_0708] Add End

    XxcsoUtils.debug(txn, "[END]");
    return errorList;
  }

  /*****************************************************************************
   * ＢＭ２指定情報の検証
   * @param txn          OADBTransactionインスタンス
   * @param pageRndrVo   ページ属性設定用ビューインスタンス
   * @param bm1DestVo    送付先テーブル情報用ビューインスタンス
   * @param bm1BankAccVo 銀行口座アドオンマスタ情報用ビューインスタンス
   * @param isFixed      確定ボタン押下フラグ
   * @return List        エラーリスト
   *****************************************************************************
   */
  public static List validateBm2Dest(
    OADBTransaction                     txn
   ,XxcsoPageRenderVOImpl               pageRndrVo
   ,XxcsoBm2DestinationFullVOImpl       bm2DestVo
   ,XxcsoBm2BankAccountFullVOImpl       bm2BankAccVo
   ,boolean                             fixedFrag
  )
  {
    List errorList = new ArrayList();

    final String tokenMain
      = XxcsoContractRegistConstants.TOKEN_VALUE_BM2_DEST
       + XxcsoConstants.TOKEN_VALUE_DELIMITER1
       + XxcsoContractRegistConstants.TOKEN_VALUE_BM2;
    
    String token1 = null;

    XxcsoUtils.debug(txn, "[START]");

    // ***********************************
    // データ行を取得
    // ***********************************
    XxcsoPageRenderVORowImpl pageRndrVoRow
      = (XxcsoPageRenderVORowImpl) pageRndrVo.first();

    XxcsoBm2DestinationFullVORowImpl bm2DestVoRow
      = (XxcsoBm2DestinationFullVORowImpl) bm2DestVo.first();

    XxcsoBm2BankAccountFullVORowImpl bm2BankAccVoRow
      = (XxcsoBm2BankAccountFullVORowImpl) bm2BankAccVo.first();


    // 指定チェックのON／OFFチェック
    if ( !isChecked( pageRndrVoRow.getBm2ExistFlag() ) )
    {
      // OFFの場合は終了
      return errorList;
    }

    XxcsoValidateUtils utils = XxcsoValidateUtils.getInstance(txn);

    // ///////////////////////////////////
    // 振込手数料負担
    // ///////////////////////////////////
    token1 = tokenMain
        + XxcsoContractRegistConstants.TOKEN_VALUE_BANK_TRANSFER_FEE_CHARGE_DIV;
    // 確定ボタン時のみ必須入力チェック
    if ( fixedFrag )
    {
      errorList
        =  utils.requiredCheck(
             errorList
            ,bm2DestVoRow.getBankTransferFeeChargeDiv()
            ,token1
            ,0
           );
    }

    // ///////////////////////////////////
    // 支払方法、明細書
    // ///////////////////////////////////
    token1 = tokenMain
            + XxcsoContractRegistConstants.TOKEN_VALUE_BELLING_DETAILS_DIV;
    // 確定ボタン時のみ必須入力チェック
    if ( fixedFrag )
    {
      errorList
        = utils.requiredCheck(
            errorList
           ,bm2DestVoRow.getBellingDetailsDiv()
           ,token1
           ,0
          );
    }

    // ///////////////////////////////////
    // 問合せ担当拠点
    // ///////////////////////////////////
    token1 = tokenMain
            + XxcsoContractRegistConstants.TOKEN_VALUE_INQUERY_CHARGE_HUB_CD;

    // 確定ボタン時のみ必須入力チェック
    if ( fixedFrag )
    {
      errorList
        = utils.requiredCheck(
            errorList
           ,bm2DestVoRow.getInqueryChargeHubCd()
           ,token1
           ,0
          );
    }

    // ///////////////////////////////////
    // 送付先名
    // ///////////////////////////////////
    token1 = tokenMain
            + XxcsoContractRegistConstants.TOKEN_VALUE_PAYMENT_NAME;
    // 確定ボタン時のみ必須入力チェック
    if ( fixedFrag )
    {
      errorList
        = utils.requiredCheck(
            errorList
           ,bm2DestVoRow.getPaymentName()
           ,token1
           ,0
          );
    }
    // 禁則文字チェック
    errorList
      = utils.checkIllegalString(
          errorList
         ,bm2DestVoRow.getPaymentName()
         ,token1
         ,0
        );
// 2009-04-27 [ST障害T1_0708] Add Start
    // 全角文字チェック
    if ( ! isDoubleByte( txn, bm2DestVoRow.getPaymentName() ) )
    {
      OAException error
        = XxcsoMessage.createErrorMessage(
            XxcsoConstants.APP_XXCSO1_00565
           ,XxcsoConstants.TOKEN_REGION
           ,XxcsoContractRegistConstants.TOKEN_VALUE_BM2_DEST
           ,XxcsoConstants.TOKEN_COLUMN
           ,XxcsoContractRegistConstants.TOKEN_VALUE_PAYMENT_NAME
          );
      errorList.add(error);
    }
// 2009-04-27 [ST障害T1_0708] Add End

    // ///////////////////////////////////
    // 送付先名カナ
    // ///////////////////////////////////
    token1 = tokenMain
            + XxcsoContractRegistConstants.TOKEN_VALUE_PAYMENT_NAME_ALT;

    // 確定ボタン時のみ必須入力チェック
    if ( fixedFrag )
    {
      errorList
        = utils.requiredCheck(
            errorList
           ,bm2DestVoRow.getPaymentNameAlt()
           ,token1
           ,0
          );
    }
    // 禁則文字チェック
    errorList
      = utils.checkIllegalString(
          errorList
         ,bm2DestVoRow.getPaymentNameAlt()
         ,token1
         ,0
        );
// 2009-04-27 [ST障害T1_0708] Mod Start
//    // 全角カナチェック
//    if ( ! isDoubleByteKana(txn, bm2DestVoRow.getPaymentNameAlt()) )
//    {
//      OAException error
//        = XxcsoMessage.createErrorMessage(
//            XxcsoConstants.APP_XXCSO1_00286
//           ,XxcsoConstants.TOKEN_REGION
//           ,XxcsoContractRegistConstants.TOKEN_VALUE_BM2_DEST
//           ,XxcsoConstants.TOKEN_COLUMN
//           ,XxcsoContractRegistConstants.TOKEN_VALUE_PAYMENT_NAME_ALT
//          );
//      errorList.add(error);
//    }
      // 半角カナチェック
    if ( ! isSingleByteKana( txn, bm2DestVoRow.getPaymentNameAlt() ) )
    {
      OAException error
        = XxcsoMessage.createErrorMessage(
// 2009-06-08 [ST障害T1_1307] Mod Start
//            XxcsoConstants.APP_XXCSO1_00533
            XxcsoConstants.APP_XXCSO1_00573
// 2009-06-08 [ST障害T1_1307] Mod End
           ,XxcsoConstants.TOKEN_REGION
           ,XxcsoContractRegistConstants.TOKEN_VALUE_BM2_DEST
           ,XxcsoConstants.TOKEN_COLUMN
           ,XxcsoContractRegistConstants.TOKEN_VALUE_PAYMENT_NAME_ALT
          );
      errorList.add(error);
    }
// 2009-04-27 [ST障害T1_0708] Mod End

    // ///////////////////////////////////
    // 送付先住所（郵便番号）
    // ///////////////////////////////////
    token1 = tokenMain
            + XxcsoContractRegistConstants.TOKEN_VALUE_POST_CODE;
    // 確定ボタン時のみ必須入力チェック
    if ( fixedFrag )
    {
      errorList
        = utils.requiredCheck(
            errorList
           ,bm2DestVoRow.getPostCode()
           ,token1
           ,0
          );
    }
    if ( ! isPostalCode(bm2DestVoRow.getPostCode()) )
    {
      OAException error
        = XxcsoMessage.createErrorMessage(
            XxcsoConstants.APP_XXCSO1_00532
           ,XxcsoConstants.TOKEN_REGION
           ,XxcsoContractRegistConstants.TOKEN_VALUE_BM2_DEST
          );
      errorList.add(error);
    }
// 2009-10-14 [IE554,IE573] Add Start
//    // ///////////////////////////////////
//    // 送付先住所（都道府県）
//    // ///////////////////////////////////
//    token1 = tokenMain
//            + XxcsoContractRegistConstants.TOKEN_VALUE_PREFECTURES;
//
//    // 確定ボタン時のみ必須入力チェック
//    if ( fixedFrag )
//    {
//      errorList
//        = utils.requiredCheck(
//            errorList
//           ,bm2DestVoRow.getPrefectures()
//           ,token1
//           ,0
//          );
//    }
//    // 禁則文字チェック
//    errorList
//      = utils.checkIllegalString(
//          errorList
//         ,bm2DestVoRow.getPrefectures()
//         ,token1
//         ,0
//        );
//// 2009-04-27 [ST障害T1_0708] Add Start
//    // 全角文字チェック
//    if ( ! isDoubleByte( txn, bm2DestVoRow.getPrefectures() ) )
//    {
//      OAException error
//        = XxcsoMessage.createErrorMessage(
//            XxcsoConstants.APP_XXCSO1_00565
//           ,XxcsoConstants.TOKEN_REGION
//           ,XxcsoContractRegistConstants.TOKEN_VALUE_BM2_DEST
//           ,XxcsoConstants.TOKEN_COLUMN
//           ,XxcsoContractRegistConstants.TOKEN_VALUE_PREFECTURES
//          );
//      errorList.add(error);
//    }
//// 2009-04-27 [ST障害T1_0708] Add End
//
//    // ///////////////////////////////////
//    // 送付先住所（市・区）
//    // ///////////////////////////////////
//    token1 = tokenMain
//            + XxcsoContractRegistConstants.TOKEN_VALUE_CITY_WARD;
//    // 確定ボタン時のみ必須入力チェック
//    if ( fixedFrag )
//    {
//      errorList
//        = utils.requiredCheck(
//            errorList
//           ,bm2DestVoRow.getCityWard()
//           ,token1
//           ,0
//          );
//    }
//    // 禁則文字チェック
//    errorList
//      = utils.checkIllegalString(
//          errorList
//         ,bm2DestVoRow.getCityWard()
//         ,token1
//         ,0
//        );
/// 2009-04-27 [ST障害T1_0708] Add Start
//    // 全角文字チェック
//    if ( ! isDoubleByte( txn, bm2DestVoRow.getCityWard() ) )
//    {
//      OAException error
//        = XxcsoMessage.createErrorMessage(
//            XxcsoConstants.APP_XXCSO1_00565
//           ,XxcsoConstants.TOKEN_REGION
//           ,XxcsoContractRegistConstants.TOKEN_VALUE_BM2_DEST
//           ,XxcsoConstants.TOKEN_COLUMN
//           ,XxcsoContractRegistConstants.TOKEN_VALUE_CITY_WARD
//          );
//      errorList.add(error);
//    }
//// 2009-04-27 [ST障害T1_0708] Add End
// 2009-10-14 [IE554,IE573] Add End
    // ///////////////////////////////////
    // 送付先住所（住所１）
    // ///////////////////////////////////
    token1 = tokenMain
            + XxcsoContractRegistConstants.TOKEN_VALUE_ADDRESS_1;
    // 確定ボタン時のみ必須入力チェック
    if ( fixedFrag )
    {
      errorList
        = utils.requiredCheck(
            errorList
           ,bm2DestVoRow.getAddress1()
           ,token1
           ,0
          );
    }
    // 禁則文字チェック
    errorList
      = utils.checkIllegalString(
          errorList
         ,bm2DestVoRow.getAddress1()
         ,token1
         ,0
        );
// 2009-04-27 [ST障害T1_0708] Add Start
    // 全角文字チェック
    if ( ! isDoubleByte( txn, bm2DestVoRow.getAddress1() ) )
    {
      OAException error
        = XxcsoMessage.createErrorMessage(
            XxcsoConstants.APP_XXCSO1_00565
           ,XxcsoConstants.TOKEN_REGION
           ,XxcsoContractRegistConstants.TOKEN_VALUE_BM2_DEST
           ,XxcsoConstants.TOKEN_COLUMN
           ,XxcsoContractRegistConstants.TOKEN_VALUE_ADDRESS_1
          );
      errorList.add(error);
    }
// 2009-04-27 [ST障害T1_0708] Add End

    // ///////////////////////////////////
    // 送付先住所（住所２）
    // ///////////////////////////////////
    token1 = tokenMain
            + XxcsoContractRegistConstants.TOKEN_VALUE_ADDRESS_2;
    // 禁則文字チェック
    errorList
      = utils.checkIllegalString(
          errorList
         ,bm2DestVoRow.getAddress2()
         ,token1
         ,0
        );
// 2009-04-27 [ST障害T1_0708] Add Start
    // 全角文字チェック
    if ( ! isDoubleByte( txn, bm2DestVoRow.getAddress2() ) )
    {
      OAException error
        = XxcsoMessage.createErrorMessage(
            XxcsoConstants.APP_XXCSO1_00565
           ,XxcsoConstants.TOKEN_REGION
           ,XxcsoContractRegistConstants.TOKEN_VALUE_BM2_DEST
           ,XxcsoConstants.TOKEN_COLUMN
           ,XxcsoContractRegistConstants.TOKEN_VALUE_ADDRESS_2
          );
      errorList.add(error);
    }
// 2009-04-27 [ST障害T1_0708] Add End

    // ///////////////////////////////////
    // 送付先電話番号
    // ///////////////////////////////////
    token1 = tokenMain
            + XxcsoContractRegistConstants.TOKEN_VALUE_ADDRESS_LINES_PHONETIC;

    if ( ! utils.isTelNumber(bm2DestVoRow.getAddressLinesPhonetic()) )
    {
      OAException error
        = XxcsoMessage.createErrorMessage(
            XxcsoConstants.APP_XXCSO1_00288
           ,XxcsoConstants.TOKEN_REGION
           ,XxcsoContractRegistConstants.TOKEN_VALUE_BM2_DEST
          );
      errorList.add(error);
    }

    // ///////////////////////////////////
    // 金融機関名
    // ///////////////////////////////////
    token1 = tokenMain
            + XxcsoContractRegistConstants.TOKEN_VALUE_BANK_NUMBER;
    // 確定ボタン時のみ必須入力チェック
    if ( fixedFrag )
    {
      errorList
        = utils.requiredCheck(
            errorList
           ,bm2BankAccVoRow.getBankNumber()
           ,token1
           ,0
          );
    }

    // ///////////////////////////////////
    // 口座種別
    // ///////////////////////////////////
    token1 = tokenMain
            + XxcsoContractRegistConstants.TOKEN_VALUE_BANK_ACCOUNT_TYPE;
    // 確定ボタン時のみ必須入力チェック
    if ( fixedFrag )
    {
      errorList
        = utils.requiredCheck(
            errorList
           ,bm2BankAccVoRow.getBankAccountType()
           ,token1
           ,0
          );
    }

    // ///////////////////////////////////
    // 口座番号
    // ///////////////////////////////////
    token1 = tokenMain
            + XxcsoContractRegistConstants.TOKEN_VALUE_BANK_ACCOUNT_NUMBER;
    // 確定ボタン時のみ必須入力チェック
    if ( fixedFrag )
    {
      errorList
        = utils.requiredCheck(
            errorList
           ,bm2BankAccVoRow.getBankAccountNumber()
           ,token1
           ,0
          );
    }
    // 禁則文字チェック
    errorList
      = utils.checkIllegalString(
          errorList
         ,bm2BankAccVoRow.getBankAccountNumber()
         ,token1
         ,0
        );

    // ///////////////////////////////////
    // 口座名義カナ
    // ///////////////////////////////////
    token1 = tokenMain
            + XxcsoContractRegistConstants.TOKEN_VALUE_BANK_ACCOUNT_NAME_KANA;
    // 確定ボタン時のみ必須入力チェック
    if ( fixedFrag )
    {
      errorList
        = utils.requiredCheck(
            errorList
           ,bm2BankAccVoRow.getBankAccountNameKana()
           ,token1
           ,0
          );
    }

    // 禁則文字チェック
    errorList
      = utils.checkIllegalString(
          errorList
         ,bm2BankAccVoRow.getBankAccountNameKana()
         ,token1
         ,0
        );

    // 半角カナチェック（BFA関数）
    if ( ! isBfaSingleByteKana(txn, bm2BankAccVoRow.getBankAccountNameKana()) )
    {
      OAException error
        = XxcsoMessage.createErrorMessage(
            XxcsoConstants.APP_XXCSO1_00533
           ,XxcsoConstants.TOKEN_REGION
           ,XxcsoContractRegistConstants.TOKEN_VALUE_BM2_DEST
           ,XxcsoConstants.TOKEN_COLUMN
           ,XxcsoContractRegistConstants.TOKEN_VALUE_BANK_ACCOUNT_NAME_KANA
          );
      errorList.add(error);
    }

    // ///////////////////////////////////
    // 口座名義漢字
    // ///////////////////////////////////
    token1 = tokenMain
            + XxcsoContractRegistConstants.TOKEN_VALUE_BANK_ACCOUNT_NAME_KANJI;
    // 確定ボタン時のみ必須入力チェック
    if ( fixedFrag )
    {
      errorList
        = utils.requiredCheck(
            errorList
           ,bm2BankAccVoRow.getBankAccountNameKanji()
           ,token1
           ,0
          );
    }
    // 禁則文字チェック
    errorList
      = utils.checkIllegalString(
          errorList
         ,bm2BankAccVoRow.getBankAccountNameKanji()
         ,token1
         ,0
        );
// 2009-04-27 [ST障害T1_0708] Add Start
    // 全角文字チェック
    if ( ! isDoubleByte( txn, bm2BankAccVoRow.getBankAccountNameKanji() ) )
    {
      OAException error
        = XxcsoMessage.createErrorMessage(
            XxcsoConstants.APP_XXCSO1_00565
           ,XxcsoConstants.TOKEN_REGION
           ,XxcsoContractRegistConstants.TOKEN_VALUE_BM2_DEST
           ,XxcsoConstants.TOKEN_COLUMN
           ,XxcsoContractRegistConstants.TOKEN_VALUE_BANK_ACCOUNT_NAME_KANJI
          );
      errorList.add(error);
    }
// 2009-04-27 [ST障害T1_0708] Add End

    XxcsoUtils.debug(txn, "[END]");

    return errorList;
  }

  /*****************************************************************************
   * ＢＭ３指定情報の検証
   * @param txn          OADBTransactionインスタンス
   * @param pageRndrVo   ページ属性設定用ビューインスタンス
   * @param bm1DestVo    送付先テーブル情報用ビューインスタンス
   * @param bm1BankAccVo 銀行口座アドオンマスタ情報用ビューインスタンス
   * @param isFixed      確定ボタン押下フラグ
   * @return List        エラーリスト
   *****************************************************************************
   */
  public static List validateBm3Dest(
    OADBTransaction                     txn
   ,XxcsoPageRenderVOImpl               pageRndrVo
   ,XxcsoBm3DestinationFullVOImpl       bm3DestVo
   ,XxcsoBm3BankAccountFullVOImpl       bm3BankAccVo
   ,boolean                             fixedFrag
  )
  {
    List errorList = new ArrayList();
    final String tokenMain
      = XxcsoContractRegistConstants.TOKEN_VALUE_BM3_DEST
       + XxcsoConstants.TOKEN_VALUE_DELIMITER1
       + XxcsoContractRegistConstants.TOKEN_VALUE_BM3;
    
    String token1 = null;

    XxcsoUtils.debug(txn, "[START]");

    // ***********************************
    // データ行を取得
    // ***********************************
    XxcsoPageRenderVORowImpl pageRndrVoRow
      = (XxcsoPageRenderVORowImpl) pageRndrVo.first(); 

    XxcsoBm3DestinationFullVORowImpl bm3DestVoRow
      = (XxcsoBm3DestinationFullVORowImpl) bm3DestVo.first();

    XxcsoBm3BankAccountFullVORowImpl bm3BankAccVoRow
      = (XxcsoBm3BankAccountFullVORowImpl) bm3BankAccVo.first();


    // 指定チェックのON／OFFチェック
    if ( !isChecked( pageRndrVoRow.getBm3ExistFlag() ) )
    {
      // OFFの場合は終了
      return errorList;
    }

    XxcsoValidateUtils utils = XxcsoValidateUtils.getInstance(txn);

    // ///////////////////////////////////
    // 振込手数料負担
    // ///////////////////////////////////
    token1 = tokenMain
        + XxcsoContractRegistConstants.TOKEN_VALUE_BANK_TRANSFER_FEE_CHARGE_DIV;
    // 確定ボタン時のみ必須入力チェック
    if ( fixedFrag )
    {
      errorList
        =  utils.requiredCheck(
             errorList
            ,bm3DestVoRow.getBankTransferFeeChargeDiv()
            ,token1
            ,0
           );
    }

    // ///////////////////////////////////
    // 支払方法、明細書
    // ///////////////////////////////////
    token1 = tokenMain
            + XxcsoContractRegistConstants.TOKEN_VALUE_BELLING_DETAILS_DIV;
    // 確定ボタン時のみ必須入力チェック
    if ( fixedFrag )
    {
      errorList
        = utils.requiredCheck(
            errorList
           ,bm3DestVoRow.getBellingDetailsDiv()
           ,token1
           ,0
          );
    }

    // ///////////////////////////////////
    // 問合せ担当拠点
    // ///////////////////////////////////
    token1 = tokenMain
            + XxcsoContractRegistConstants.TOKEN_VALUE_INQUERY_CHARGE_HUB_CD;

    // 確定ボタン時のみ必須入力チェック
    if ( fixedFrag )
    {
      errorList
        = utils.requiredCheck(
            errorList
           ,bm3DestVoRow.getInqueryChargeHubCd()
           ,token1
           ,0
          );
    }

    // ///////////////////////////////////
    // 送付先名
    // ///////////////////////////////////
    token1 = tokenMain
            + XxcsoContractRegistConstants.TOKEN_VALUE_PAYMENT_NAME;
    // 確定ボタン時のみ必須入力チェック
    if ( fixedFrag )
    {
      errorList
        = utils.requiredCheck(
            errorList
           ,bm3DestVoRow.getPaymentName()
           ,token1
           ,0
          );
    }
    // 禁則文字チェック
    errorList
      = utils.checkIllegalString(
          errorList
         ,bm3DestVoRow.getPaymentName()
         ,token1
         ,0
        );
// 2009-04-27 [ST障害T1_0708] Add Start
    // 全角文字チェック
    if ( ! isDoubleByte( txn, bm3DestVoRow.getPaymentName() ) )
    {
      OAException error
        = XxcsoMessage.createErrorMessage(
            XxcsoConstants.APP_XXCSO1_00565
           ,XxcsoConstants.TOKEN_REGION
           ,XxcsoContractRegistConstants.TOKEN_VALUE_BM3_DEST
           ,XxcsoConstants.TOKEN_COLUMN
           ,XxcsoContractRegistConstants.TOKEN_VALUE_PAYMENT_NAME
          );
      errorList.add(error);
    }
// 2009-04-27 [ST障害T1_0708] Add End

    // ///////////////////////////////////
    // 送付先名カナ
    // ///////////////////////////////////
    token1 = tokenMain
            + XxcsoContractRegistConstants.TOKEN_VALUE_PAYMENT_NAME_ALT;

    // 確定ボタン時のみ必須入力チェック
    if ( fixedFrag )
    {
      errorList
        = utils.requiredCheck(
            errorList
           ,bm3DestVoRow.getPaymentNameAlt()
           ,token1
           ,0
          );
    }
    // 禁則文字チェック
    errorList
      = utils.checkIllegalString(
          errorList
         ,bm3DestVoRow.getPaymentNameAlt()
         ,token1
         ,0
        );
// 2009-04-27 [ST障害T1_0708] Mod Start
//    // 全角カナチェック
//    if ( ! isDoubleByteKana(txn, bm3DestVoRow.getPaymentNameAlt()) )
//    {
//      OAException error
//        = XxcsoMessage.createErrorMessage(
//            XxcsoConstants.APP_XXCSO1_00286
//           ,XxcsoConstants.TOKEN_REGION
//           ,XxcsoContractRegistConstants.TOKEN_VALUE_BM3_DEST
//           ,XxcsoConstants.TOKEN_COLUMN
//           ,XxcsoContractRegistConstants.TOKEN_VALUE_PAYMENT_NAME_ALT
//          );
//      errorList.add(error);
//    }
    // 半角カナチェック
    if ( ! isSingleByteKana( txn, bm3DestVoRow.getPaymentNameAlt() ) )
    {
      OAException error
        = XxcsoMessage.createErrorMessage(
// 2009-06-08 [ST障害T1_1307] Mod Start
//            XxcsoConstants.APP_XXCSO1_00533
            XxcsoConstants.APP_XXCSO1_00573
// 2009-06-08 [ST障害T1_1307] Mod End
           ,XxcsoConstants.TOKEN_REGION
           ,XxcsoContractRegistConstants.TOKEN_VALUE_BM3_DEST
           ,XxcsoConstants.TOKEN_COLUMN
           ,XxcsoContractRegistConstants.TOKEN_VALUE_PAYMENT_NAME_ALT
          );
      errorList.add(error);
    }
// 2009-04-27 [ST障害T1_0708] Mod End

    // ///////////////////////////////////
    // 送付先住所（郵便番号）
    // ///////////////////////////////////
    token1 = tokenMain
            + XxcsoContractRegistConstants.TOKEN_VALUE_POST_CODE;
    // 確定ボタン時のみ必須入力チェック
    if ( fixedFrag )
    {
      errorList
        = utils.requiredCheck(
            errorList
           ,bm3DestVoRow.getPostCode()
           ,token1
           ,0
          );
    }
    if ( ! isPostalCode(bm3DestVoRow.getPostCode()) )
    {
      OAException error
        = XxcsoMessage.createErrorMessage(
            XxcsoConstants.APP_XXCSO1_00532
           ,XxcsoConstants.TOKEN_REGION
           ,XxcsoContractRegistConstants.TOKEN_VALUE_BM3_DEST
          );
      errorList.add(error);
    }

// 2009-10-14 [IE554,IE573] Add Start
//    // ///////////////////////////////////
//    // 送付先住所（都道府県）
//    // ///////////////////////////////////
//    token1 = tokenMain
//            + XxcsoContractRegistConstants.TOKEN_VALUE_PREFECTURES;
//
//    // 確定ボタン時のみ必須入力チェック
//    if ( fixedFrag )
//    {
//      errorList
//        = utils.requiredCheck(
//            errorList
//           ,bm3DestVoRow.getPrefectures()
//           ,token1
//           ,0
//          );
//    }
//    // 禁則文字チェック
//    errorList
//      = utils.checkIllegalString(
//          errorList
//         ,bm3DestVoRow.getPrefectures()
//         ,token1
//         ,0
//        );
//// 2009-04-27 [ST障害T1_0708] Add Start
//    // 全角文字チェック
//    if ( ! isDoubleByte( txn, bm3DestVoRow.getPrefectures() ) )
//    {
//      OAException error
//        = XxcsoMessage.createErrorMessage(
//            XxcsoConstants.APP_XXCSO1_00565
//           ,XxcsoConstants.TOKEN_REGION
//           ,XxcsoContractRegistConstants.TOKEN_VALUE_BM3_DEST
//           ,XxcsoConstants.TOKEN_COLUMN
//           ,XxcsoContractRegistConstants.TOKEN_VALUE_PREFECTURES
//          );
//      errorList.add(error);
//    }
//// 2009-04-27 [ST障害T1_0708] Add End
//
//    // ///////////////////////////////////
//    // 送付先住所（市・区）
//    // ///////////////////////////////////
//    token1 = tokenMain
//            + XxcsoContractRegistConstants.TOKEN_VALUE_CITY_WARD;
//    // 確定ボタン時のみ必須入力チェック
//    if ( fixedFrag )
//    {
//      errorList
//        = utils.requiredCheck(
//            errorList
//           ,bm3DestVoRow.getCityWard()
//           ,token1
//           ,0
//          );
//    }
//    // 禁則文字チェック
//    errorList
//      = utils.checkIllegalString(
//          errorList
//         ,bm3DestVoRow.getCityWard()
//         ,token1
//         ,0
//        );
//// 2009-04-27 [ST障害T1_0708] Add Start
//    // 全角文字チェック
//    if ( ! isDoubleByte( txn, bm3DestVoRow.getCityWard() ) )
//    {
//      OAException error
//        = XxcsoMessage.createErrorMessage(
//            XxcsoConstants.APP_XXCSO1_00565
//           ,XxcsoConstants.TOKEN_REGION
//           ,XxcsoContractRegistConstants.TOKEN_VALUE_BM3_DEST
//           ,XxcsoConstants.TOKEN_COLUMN
//           ,XxcsoContractRegistConstants.TOKEN_VALUE_CITY_WARD
//          );
//      errorList.add(error);
//    }
//// 2009-04-27 [ST障害T1_0708] Add End
// 2009-10-14 [IE554,IE573] Add End
    // ///////////////////////////////////
    // 送付先住所（住所１）
    // ///////////////////////////////////
    token1 = tokenMain
            + XxcsoContractRegistConstants.TOKEN_VALUE_ADDRESS_1;
    // 確定ボタン時のみ必須入力チェック
    if ( fixedFrag )
    {
      errorList
        = utils.requiredCheck(
            errorList
           ,bm3DestVoRow.getAddress1()
           ,token1
           ,0
          );
    }
    // 禁則文字チェック
    errorList
      = utils.checkIllegalString(
          errorList
         ,bm3DestVoRow.getAddress1()
         ,token1
         ,0
        );
// 2009-04-27 [ST障害T1_0708] Add Start
    // 全角文字チェック
    if ( ! isDoubleByte( txn, bm3DestVoRow.getAddress1() ) )
    {
      OAException error
        = XxcsoMessage.createErrorMessage(
            XxcsoConstants.APP_XXCSO1_00565
           ,XxcsoConstants.TOKEN_REGION
           ,XxcsoContractRegistConstants.TOKEN_VALUE_BM3_DEST
           ,XxcsoConstants.TOKEN_COLUMN
           ,XxcsoContractRegistConstants.TOKEN_VALUE_ADDRESS_1
          );
      errorList.add(error);
    }
// 2009-04-27 [ST障害T1_0708] Add End

    // ///////////////////////////////////
    // 送付先住所（住所２）
    // ///////////////////////////////////
    token1 = tokenMain
            + XxcsoContractRegistConstants.TOKEN_VALUE_ADDRESS_2;
    // 禁則文字チェック
    errorList
      = utils.checkIllegalString(
          errorList
         ,bm3DestVoRow.getAddress2()
         ,token1
         ,0
        );
// 2009-04-27 [ST障害T1_0708] Add Start
    // 全角文字チェック
    if ( ! isDoubleByte( txn, bm3DestVoRow.getAddress2() ) )
    {
      OAException error
        = XxcsoMessage.createErrorMessage(
            XxcsoConstants.APP_XXCSO1_00565
           ,XxcsoConstants.TOKEN_REGION
           ,XxcsoContractRegistConstants.TOKEN_VALUE_BM3_DEST
           ,XxcsoConstants.TOKEN_COLUMN
           ,XxcsoContractRegistConstants.TOKEN_VALUE_ADDRESS_2
          );
      errorList.add(error);
    }
// 2009-04-27 [ST障害T1_0708] Add End

    // ///////////////////////////////////
    // 送付先電話番号
    // ///////////////////////////////////
    token1 = tokenMain
            + XxcsoContractRegistConstants.TOKEN_VALUE_ADDRESS_LINES_PHONETIC;

    if ( ! utils.isTelNumber(bm3DestVoRow.getAddressLinesPhonetic()) )
    {
      OAException error
        = XxcsoMessage.createErrorMessage(
            XxcsoConstants.APP_XXCSO1_00288
           ,XxcsoConstants.TOKEN_REGION
           ,XxcsoContractRegistConstants.TOKEN_VALUE_BM3_DEST
          );
      errorList.add(error);
    }

    // ///////////////////////////////////
    // 金融機関名
    // ///////////////////////////////////
    token1 = tokenMain
            + XxcsoContractRegistConstants.TOKEN_VALUE_BANK_NUMBER;
    // 確定ボタン時のみ必須入力チェック
    if ( fixedFrag )
    {
      errorList
        = utils.requiredCheck(
            errorList
           ,bm3BankAccVoRow.getBankNumber()
           ,token1
           ,0
          );
    }

    // ///////////////////////////////////
    // 口座種別
    // ///////////////////////////////////
    token1 = tokenMain
            + XxcsoContractRegistConstants.TOKEN_VALUE_BANK_ACCOUNT_TYPE;
    // 確定ボタン時のみ必須入力チェック
    if ( fixedFrag )
    {
      errorList
        = utils.requiredCheck(
            errorList
           ,bm3BankAccVoRow.getBankAccountType()
           ,token1
           ,0
          );
    }

    // ///////////////////////////////////
    // 口座番号
    // ///////////////////////////////////
    token1 = tokenMain
            + XxcsoContractRegistConstants.TOKEN_VALUE_BANK_ACCOUNT_NUMBER;
    // 確定ボタン時のみ必須入力チェック
    if ( fixedFrag )
    {
      errorList
        = utils.requiredCheck(
            errorList
           ,bm3BankAccVoRow.getBankAccountNumber()
           ,token1
           ,0
          );
    }
    // 禁則文字チェック
    errorList
      = utils.checkIllegalString(
          errorList
         ,bm3BankAccVoRow.getBankAccountNumber()
         ,token1
         ,0
        );



    // ///////////////////////////////////
    // 口座名義カナ
    // ///////////////////////////////////
    token1 = tokenMain
            + XxcsoContractRegistConstants.TOKEN_VALUE_BANK_ACCOUNT_NAME_KANA;
    // 確定ボタン時のみ必須入力チェック
    if ( fixedFrag )
    {
      errorList
        = utils.requiredCheck(
            errorList
           ,bm3BankAccVoRow.getBankAccountNameKana()
           ,token1
           ,0
          );
    }

    // 禁則文字チェック
    errorList
      = utils.checkIllegalString(
          errorList
         ,bm3BankAccVoRow.getBankAccountNameKana()
         ,token1
         ,0
        );
    // 半角カナチェック
    if ( ! isBfaSingleByteKana(txn, bm3BankAccVoRow.getBankAccountNameKana()) )
    {
      OAException error
        = XxcsoMessage.createErrorMessage(
            XxcsoConstants.APP_XXCSO1_00533
           ,XxcsoConstants.TOKEN_REGION
           ,XxcsoContractRegistConstants.TOKEN_VALUE_BM3_DEST
           ,XxcsoConstants.TOKEN_COLUMN
           ,XxcsoContractRegistConstants.TOKEN_VALUE_BANK_ACCOUNT_NAME_KANA
          );
      errorList.add(error);
    }

    // ///////////////////////////////////
    // 口座名義漢字
    // ///////////////////////////////////
    token1 = tokenMain
            + XxcsoContractRegistConstants.TOKEN_VALUE_BANK_ACCOUNT_NAME_KANJI;
    // 確定ボタン時のみ必須入力チェック
    if ( fixedFrag )
    {
      errorList
        = utils.requiredCheck(
            errorList
           ,bm3BankAccVoRow.getBankAccountNameKanji()
           ,token1
           ,0
          );
    }
    // 禁則文字チェック
    errorList
      = utils.checkIllegalString(
          errorList
         ,bm3BankAccVoRow.getBankAccountNameKanji()
         ,token1
         ,0
        );
// 2009-04-27 [ST障害T1_0708] Add Start
    // 全角文字チェック
    if ( ! isDoubleByte( txn, bm3BankAccVoRow.getBankAccountNameKanji() ) )
    {
      OAException error
        = XxcsoMessage.createErrorMessage(
            XxcsoConstants.APP_XXCSO1_00565
           ,XxcsoConstants.TOKEN_REGION
           ,XxcsoContractRegistConstants.TOKEN_VALUE_BM3_DEST
           ,XxcsoConstants.TOKEN_COLUMN
           ,XxcsoContractRegistConstants.TOKEN_VALUE_BANK_ACCOUNT_NAME_KANJI
          );
      errorList.add(error);
    }
// 2009-04-27 [ST障害T1_0708] Add Start

    XxcsoUtils.debug(txn, "[END]");

    return errorList;
  }

  /*****************************************************************************
   * 設置先情報の検証
   * @param txn         OADBTransactionインスタンス
   * @param pageRndrVo  ページ属性設定ビューインスタンス
   * @param contMngVo   契約管理テーブル情報ビューインスタンス
   * @param fixedFrag   確定ボタン押下フラグ
   * @return List       エラーリスト
   *****************************************************************************
   */
  public static List validateContractInstall(
    OADBTransaction                     txn
   ,XxcsoPageRenderVOImpl               pageRndrVo
   ,XxcsoContractManagementFullVOImpl   contMngVo
   ,boolean                             fixedFrag
  )
  {
    List errorList = new ArrayList();
    String token1 = null;

    final String tokenMain
      = XxcsoContractRegistConstants.TOKEN_VALUE_INSTALL_INFO
       + XxcsoConstants.TOKEN_VALUE_DELIMITER1;

    XxcsoUtils.debug(txn, "[START]");

    // ***********************************
    // データ行を取得
    // ***********************************
    XxcsoPageRenderVORowImpl pageRndrVoRow
      = (XxcsoPageRenderVORowImpl) pageRndrVo.first(); 

    XxcsoContractManagementFullVORowImpl contMngVoRow
      = (XxcsoContractManagementFullVORowImpl) contMngVo.first();

    XxcsoValidateUtils utils = XxcsoValidateUtils.getInstance(txn);

    // ///////////////////////////////////
    // 設置先名
    // ///////////////////////////////////
    token1 = tokenMain
            + XxcsoContractRegistConstants.TOKEN_VALUE_INSTALL_PARTY_NAME;
    // 確定ボタン時のみ必須入力チェック
    if ( fixedFrag )
    {
      errorList
        =  utils.requiredCheck(
             errorList
            ,contMngVoRow.getInstallPartyName()
            ,token1
            ,0
           );
    }
    // 禁則文字チェック
    errorList
      = utils.checkIllegalString(
          errorList
         ,contMngVoRow.getInstallPartyName()
         ,token1
         ,0
        );
// 2009-04-27 [ST障害T1_0708] Add Start
    // 全角文字チェック
    if ( ! isDoubleByte( txn, contMngVoRow.getInstallPartyName() ) )
    {
      OAException error
        = XxcsoMessage.createErrorMessage(
            XxcsoConstants.APP_XXCSO1_00565
           ,XxcsoConstants.TOKEN_REGION
           ,XxcsoContractRegistConstants.TOKEN_VALUE_INSTALL_INFO
           ,XxcsoConstants.TOKEN_COLUMN
           ,XxcsoContractRegistConstants.TOKEN_VALUE_INSTALL_PARTY_NAME
          );
      errorList.add(error);
    }
// 2009-04-27 [ST障害T1_0708] Add End

    // ///////////////////////////////////
    // 設置先住所（郵便番号）
    // ///////////////////////////////////
    token1 = tokenMain
            + XxcsoContractRegistConstants.TOKEN_VALUE_INSTALL_POSTAL_CODE;
    // 確定ボタン時のみ必須入力チェック
    if ( fixedFrag )
    {
      errorList
        =  utils.requiredCheck(
             errorList
            ,contMngVoRow.getInstallPostalCode()
            ,token1
            ,0
           );
    }
    // 郵便番号整合性チェック
    if ( ! isPostalCode(contMngVoRow.getInstallPostalCode()) )
    {
      token1 = tokenMain
              + XxcsoContractRegistConstants.TOKEN_VALUE_INSTALL_POSTAL_CODE;
      OAException error
        = XxcsoMessage.createErrorMessage(
            XxcsoConstants.APP_XXCSO1_00532
           ,XxcsoConstants.TOKEN_REGION
           ,XxcsoContractRegistConstants.TOKEN_VALUE_INSTALL_INFO
          );
      errorList.add(error);
    }

    // ///////////////////////////////////
    // 設置先住所（都道府県）
    // ///////////////////////////////////
    token1 = tokenMain
            + XxcsoContractRegistConstants.TOKEN_VALUE_INSTALL_STATE;
    // 確定ボタン時のみ必須入力チェック
    if ( fixedFrag )
    {
      errorList
        =  utils.requiredCheck(
             errorList
            ,contMngVoRow.getInstallState()
            ,token1
            ,0
           );
    }
    // 禁則文字チェック
    errorList
      = utils.checkIllegalString(
          errorList
         ,contMngVoRow.getInstallState()
         ,token1
         ,0
        );
// 2009-04-27 [ST障害T1_0708] Add Start
    // 全角文字チェック
    if ( ! isDoubleByte( txn, contMngVoRow.getInstallState() ) )
    {
      OAException error
        = XxcsoMessage.createErrorMessage(
            XxcsoConstants.APP_XXCSO1_00565
           ,XxcsoConstants.TOKEN_REGION
           ,XxcsoContractRegistConstants.TOKEN_VALUE_INSTALL_INFO
           ,XxcsoConstants.TOKEN_COLUMN
           ,XxcsoContractRegistConstants.TOKEN_VALUE_INSTALL_STATE
          );
      errorList.add(error);
    }
// 2009-04-27 [ST障害T1_0708] Add End

    // ///////////////////////////////////
    // 設置先住所（市・区）
    // ///////////////////////////////////
    token1 = tokenMain
            + XxcsoContractRegistConstants.TOKEN_VALUE_INSTALL_CITY;
    // 確定ボタン時のみ必須入力チェック
    if ( fixedFrag )
    {
      errorList
        =  utils.requiredCheck(
             errorList
            ,contMngVoRow.getInstallCity()
            ,token1
            ,0
           );
    }
    // 禁則文字チェック
    errorList
      = utils.checkIllegalString(
          errorList
         ,contMngVoRow.getInstallCity()
         ,token1
         ,0
        );
// 2009-04-27 [ST障害T1_0708] Add Start
    // 全角文字チェック
    if ( ! isDoubleByte( txn, contMngVoRow.getInstallCity() ) )
    {
      OAException error
        = XxcsoMessage.createErrorMessage(
            XxcsoConstants.APP_XXCSO1_00565
           ,XxcsoConstants.TOKEN_REGION
           ,XxcsoContractRegistConstants.TOKEN_VALUE_INSTALL_INFO
           ,XxcsoConstants.TOKEN_COLUMN
           ,XxcsoContractRegistConstants.TOKEN_VALUE_INSTALL_CITY
          );
      errorList.add(error);
    }
// 2009-04-27 [ST障害T1_0708] Add End

    // ///////////////////////////////////
    // 設置先住所（住所１）
    // ///////////////////////////////////
    token1 = tokenMain
            + XxcsoContractRegistConstants.TOKEN_VALUE_INSTALL_ADDRESS1;
    // 確定ボタン時のみ必須入力チェック
    if ( fixedFrag )
    {
      errorList
        =  utils.requiredCheck(
             errorList
            ,contMngVoRow.getInstallAddress1()
            ,token1
            ,0
           );
    }
    // 禁則文字チェック
    errorList
      = utils.checkIllegalString(
          errorList
         ,contMngVoRow.getInstallAddress1()
         ,token1
         ,0
        );
// 2009-04-27 [ST障害T1_0708] Add Start
    // 全角文字チェック
    if ( ! isDoubleByte( txn, contMngVoRow.getInstallAddress1() ) )
    {
      OAException error
        = XxcsoMessage.createErrorMessage(
            XxcsoConstants.APP_XXCSO1_00565
           ,XxcsoConstants.TOKEN_REGION
           ,XxcsoContractRegistConstants.TOKEN_VALUE_INSTALL_INFO
           ,XxcsoConstants.TOKEN_COLUMN
           ,XxcsoContractRegistConstants.TOKEN_VALUE_INSTALL_ADDRESS1
          );
      errorList.add(error);
    }
// 2009-04-27 [ST障害T1_0708] Add End

    // ///////////////////////////////////
    // 設置先住所（住所２）
    // ///////////////////////////////////
    token1 = tokenMain
            + XxcsoContractRegistConstants.TOKEN_VALUE_INSTALL_ADDRESS2;
    // 禁則文字チェック
    errorList
      = utils.checkIllegalString(
          errorList
         ,contMngVoRow.getInstallAddress2()
         ,token1
         ,0
        );
// 2009-04-27 [ST障害T1_0708] Add Start
    // 全角文字チェック
    if ( ! isDoubleByte( txn, contMngVoRow.getInstallAddress2() ) )
    {
      OAException error
        = XxcsoMessage.createErrorMessage(
            XxcsoConstants.APP_XXCSO1_00565
           ,XxcsoConstants.TOKEN_REGION
           ,XxcsoContractRegistConstants.TOKEN_VALUE_INSTALL_INFO
           ,XxcsoConstants.TOKEN_COLUMN
           ,XxcsoContractRegistConstants.TOKEN_VALUE_INSTALL_ADDRESS2
          );
      errorList.add(error);
    }
// 2009-04-27 [ST障害T1_0708] Add End

    // ///////////////////////////////////
    // 設置日
    // ///////////////////////////////////
    token1 = tokenMain
            + XxcsoContractRegistConstants.TOKEN_VALUE_INSTALL_DATE;
    // 確定ボタン時のみ必須入力チェック
    if ( fixedFrag )
    {
      errorList
        =  utils.requiredCheck(
             errorList
            ,contMngVoRow.getInstallDate()
            ,token1
            ,0
           );
    }


    // ///////////////////////////////////
    // 物件コード
    // ///////////////////////////////////
    token1 = tokenMain
            + XxcsoContractRegistConstants.TOKEN_VALUE_INSTALL_CODE;

    // オーナー変更チェックON時のみチェック
    if ( XxcsoContractRegistConstants.OWNER_CHANGE_FLAG_ON.equals(
         pageRndrVoRow.getOwnerChangeFlag()
    ) 
    )
    {
      // 常に必須入力チェック
      errorList
        =  utils.requiredCheck(
             errorList
            ,contMngVoRow.getInstallCode()
            ,token1
            ,0
           );
    }

    XxcsoUtils.debug(txn, "[END]");

    return errorList;
  }

  /*****************************************************************************
   * 発行元所属情報の検証
   * @param txn         OADBTransactionインスタンス
   * @param contMngVo   契約管理テーブル情報用ビューインスタンス
   * @param fixedFrag   確定ボタン押下フラグ
   * @return List       エラーリスト
   *****************************************************************************
   */
  public static List validatePublishBase(
    OADBTransaction                     txn
   ,XxcsoContractManagementFullVOImpl   contMngVo
   ,boolean                             fixedFrag
  )
  {
    List errorList = new ArrayList();
    String token1 = null;

    final String tokenMain
      = XxcsoContractRegistConstants.TOKEN_VALUE_PUBLISH_BASE_INFO
       + XxcsoConstants.TOKEN_VALUE_DELIMITER1;

    XxcsoUtils.debug(txn, "[START]");

    // ***********************************
    // データ行を取得
    // ***********************************
    XxcsoContractManagementFullVORowImpl contMngVoRow
      = (XxcsoContractManagementFullVORowImpl) contMngVo.first(); 

    XxcsoValidateUtils utils = XxcsoValidateUtils.getInstance(txn);

    // ///////////////////////////////////
    // 担当拠点
    // ///////////////////////////////////
    token1 = tokenMain
            + XxcsoContractRegistConstants.TOKEN_VALUE_PUBLISH_DEPT_CODE;
    // 確定ボタン時のみ必須入力チェック
    if ( fixedFrag )
    {
      errorList
        =  utils.requiredCheck(
             errorList
            ,contMngVoRow.getPublishDeptCode()
            ,token1
            ,0
           );
    }

    XxcsoUtils.debug(txn, "[END]");

    return errorList;
  }

  /*****************************************************************************
   * 設置日AR会計期間クローズチェック処理
   * @param txn         OADBTransactionインスタンス
   * @param contMngVo   契約管理テーブル情報用ビューインスタンス
   * @param fixedFrag   確定ボタン押下フラグ
   * @return List       エラーリスト
   *****************************************************************************
   */
  public static OAException validateInstallDate(
    OADBTransaction                     txn
   ,XxcsoPageRenderVOImpl               pageRndrVo
   ,XxcsoContractManagementFullVOImpl   mngVo
   ,boolean                             fixedFrag
  )
  {
    OAException oaeMsg = null;

    XxcsoUtils.debug(txn, "[START]");

    // ***********************************
    // データ行を取得
    // ***********************************
    XxcsoPageRenderVORowImpl pageRndrVoRow
      = (XxcsoPageRenderVORowImpl) pageRndrVo.first(); 

    XxcsoContractManagementFullVORowImpl mngRow
      = (XxcsoContractManagementFullVORowImpl) mngVo.first();

    // 確定ボタン押下時以外はチェック不要
    if ( ! fixedFrag )
    {
      return oaeMsg;
    }

    // オーナー変更チェックボックスがOFFの場合はチェック不要
    if ( ! isOwnerChangeFlagChecked(pageRndrVoRow.getOwnerChangeFlag()) )
    {
      return oaeMsg;
    }

    // 設置先日 AR会計期間重複チェック
    if ( ! isArGlPriodStatus(txn, mngRow.getInstallDate()) )
    {
      oaeMsg
        = XxcsoMessage.createErrorMessage(XxcsoConstants.APP_XXCSO1_00450);
    }

    return oaeMsg;
  }
  

  /*****************************************************************************
   * BM相関チェック
   * @param pageRndrVo   ページ属性設定用ビューインスタンス
   * @param contMngVo    契約管理テーブル情報用ビューインスタンス
   * @param bm1DestVo    BM1送付先テーブル情報用ビューインスタンス
   * @param bm1BankAccVo BM1銀行口座アドオンマスタ情報用ビューインスタンス
   * @param bm2DestVo    BM2送付先テーブル情報用ビューインスタンス
   * @param bm2BankAccVo BM2銀行口座アドオンマスタ情報用ビューインスタンス
   * @param bm3DestVo    BM3送付先テーブル情報用ビューインスタンス
   * @param bm3BankAccVo BM3銀行口座アドオンマスタ情報用ビューインスタンス
   * @param fixedFrag    確定ボタン押下フラグ
   * @return OAException エラー
   *****************************************************************************
   */
  public static OAException validateBmRelation(
    OADBTransaction                     txn
   ,XxcsoPageRenderVOImpl               pageRndrVo
   ,XxcsoContractManagementFullVOImpl   contMngVo
   ,XxcsoBm1DestinationFullVOImpl       bm1DestVo
   ,XxcsoBm1BankAccountFullVOImpl       bm1BankAccVo
   ,XxcsoBm2DestinationFullVOImpl       bm2DestVo
   ,XxcsoBm2BankAccountFullVOImpl       bm2BankAccVo
   ,XxcsoBm3DestinationFullVOImpl       bm3DestVo
   ,XxcsoBm3BankAccountFullVOImpl       bm3BankAccVo
// 2009-04-08 [ST障害T1_0364] Add Start
   ,boolean                             fixedFrag
// 2009-04-08 [ST障害T1_0364] Add End
  )
  {
    OAException oaeMsg = null;

    XxcsoUtils.debug(txn, "[START]");
    // ***********************************
    // データ行を取得
    // ***********************************
    XxcsoPageRenderVORowImpl pageRndrVoRow
      = (XxcsoPageRenderVORowImpl) pageRndrVo.first(); 

    XxcsoContractManagementFullVORowImpl contMngVoRow
      = (XxcsoContractManagementFullVORowImpl) contMngVo.first();

    XxcsoBm1DestinationFullVORowImpl bm1DestVoRow
      = (XxcsoBm1DestinationFullVORowImpl) bm1DestVo.first();

    XxcsoBm1BankAccountFullVORowImpl bm1BankAccVoRow
      = (XxcsoBm1BankAccountFullVORowImpl) bm1BankAccVo.first();

    XxcsoBm2DestinationFullVORowImpl bm2DestVoRow
      = (XxcsoBm2DestinationFullVORowImpl) bm2DestVo.first();

    XxcsoBm2BankAccountFullVORowImpl bm2BankAccVoRow
      = (XxcsoBm2BankAccountFullVORowImpl) bm2BankAccVo.first();

    XxcsoBm3DestinationFullVORowImpl bm3DestVoRow
      = (XxcsoBm3DestinationFullVORowImpl) bm3DestVo.first();

    XxcsoBm3BankAccountFullVORowImpl bm3BankAccVoRow
      = (XxcsoBm3BankAccountFullVORowImpl) bm3BankAccVo.first();

    boolean retCheck = false;

    // 送付先情報
    String bm1VendorCode  = null;
    String bm2VendorCode  = null;
    String bm3VendorCode  = null;
    String bm1PaymentName = null;
    String bm2PaymentName = null;
    String bm3PaymentName = null;
    Number bm1SupplierId  = null;
    Number bm2SupplierId  = null;
    Number bm3SupplierId  = null;

    // 銀行口座情報
    String bm1BankName              = null;
    String bm2BankName              = null;
    String bm3BankName              = null;
    String bm1BranchNumber          = null;
    String bm2BranchNumber          = null;
    String bm3BranchNumber          = null;
    String bm1BankAccountNumber     = null;
    String bm2BankAccountNumber     = null;
    String bm3BankAccountNumber     = null;
    String bm1BankAccountNameKana   = null;
    String bm2BankAccountNameKana   = null;
    String bm3BankAccountNameKana   = null;
    String bm1BankAccountNameKanji  = null;
    String bm2BankAccountNameKanji  = null;
    String bm3BankAccountNameKanji  = null;
    
    // 送付先情報の取得
    // BM1送付先情報
    if (bm1DestVoRow != null)
    {
      bm1VendorCode  = bm1DestVoRow.getVendorCode();
      bm1PaymentName = bm1DestVoRow.getPaymentName();
      bm1SupplierId  = bm1DestVoRow.getSupplierId();
    }
    // BM2送付先情報
    if (bm2DestVoRow != null)
    {
      bm2VendorCode  = bm2DestVoRow.getVendorCode();
      bm2PaymentName = bm2DestVoRow.getPaymentName();
      bm2SupplierId  = bm2DestVoRow.getSupplierId();
    }
    // BM3送付先情報
    if (bm3DestVoRow != null)
    {
      bm3VendorCode  = bm3DestVoRow.getVendorCode();
      bm3PaymentName = bm3DestVoRow.getPaymentName();
      bm3SupplierId  = bm3DestVoRow.getSupplierId();
    }

    // 銀行口座情報の取得
    // BM1銀行口座情報
    if (bm1BankAccVoRow != null)
    {
      bm1BankName             = bm1BankAccVoRow.getBankName();
      bm1BranchNumber         = bm1BankAccVoRow.getBranchNumber();
      bm1BankAccountNumber    = bm1BankAccVoRow.getBankAccountNumber();
      bm1BankAccountNameKana  = bm1BankAccVoRow.getBankAccountNameKana();
      bm1BankAccountNameKanji = bm1BankAccVoRow.getBankAccountNameKanji();
    }
    // BM2銀行口座情報
    if (bm2BankAccVoRow != null)
    {
      bm2BankName             = bm2BankAccVoRow.getBankName();
      bm2BranchNumber         = bm2BankAccVoRow.getBranchNumber();
      bm2BankAccountNumber    = bm2BankAccVoRow.getBankAccountNumber();
      bm2BankAccountNameKana  = bm2BankAccVoRow.getBankAccountNameKana();
      bm2BankAccountNameKanji = bm2BankAccVoRow.getBankAccountNameKanji();
    }

    // BM3銀行口座情報
    if (bm3BankAccVoRow != null)
    {
      bm3BankName             = bm3BankAccVoRow.getBankName();
      bm3BranchNumber         = bm3BankAccVoRow.getBranchNumber();
      bm3BankAccountNumber    = bm3BankAccVoRow.getBankAccountNumber();
      bm3BankAccountNameKana  = bm3BankAccVoRow.getBankAccountNameKana();
      bm3BankAccountNameKanji = bm3BankAccVoRow.getBankAccountNameKanji();
    }

    // ***********************************
    // 送付先重複チェック
    // ***********************************
    retCheck
      = isDuplicateBmDest(
          pageRndrVoRow
         ,bm1VendorCode
         ,bm2VendorCode
         ,bm3VendorCode
         ,false
        );

    if (retCheck) 
    {
      oaeMsg
        = XxcsoMessage.createErrorMessage(XxcsoConstants.APP_XXCSO1_00521);
      return oaeMsg;
    }

    // 2009-10-14 [IE554,IE573] Add Start
    //// ***********************************
    //// 送付先名重複チェック
    //// ***********************************
    //retCheck
    //  = isDuplicateBmDest(
    //      pageRndrVoRow
    //     ,bm1PaymentName
    //     ,bm2PaymentName
    //     ,bm3PaymentName
    //     ,false
    //    );
    //
    //if (retCheck)
    //{
    //  oaeMsg
    //    = XxcsoMessage.createErrorMessage(XxcsoConstants.APP_XXCSO1_00522);
    //  return oaeMsg;
    //}
    // 2009-10-14 [IE554,IE573] Add End

    // ***********************************
    // 仕入先名重複チェック（）
    // ***********************************
// 2009-04-08 [ST障害T1_0364] Mod Start
//    retCheck
//      = isDuplicateVendorName(
//          txn
//         ,bm1PaymentName
//         ,bm2PaymentName
//         ,bm3PaymentName
//         ,contMngVoRow.getContractManagementId()
//         ,bm1SupplierId
//         ,bm2SupplierId
//         ,bm3SupplierId
//        );
//    if (retCheck)
//    {
//      oaeMsg
//        = XxcsoMessage.createErrorMessage(
//            duplicateErrId
//           ,XxcsoConstants.TOKEN_ITEM
//           ,XxcsoContractRegistConstants.TOKEN_VALUE_BM_VENDOR_NAME
//          );
//      return oaeMsg;
//    }
    String operationValue = null;
    if ( fixedFrag )
    {
      // 確定ボタン押下時
      operationValue = XxcsoContractRegistConstants.OPERATION_SUBMIT;
    }
    else
    {
      // 提出ボタン押下時
      operationValue = XxcsoContractRegistConstants.OPERATION_APPLY;
    }

    oaeMsg
      = chkDuplicateVendorName(
          txn
         ,bm1PaymentName
         ,bm2PaymentName
         ,bm3PaymentName
         ,bm1SupplierId
         ,bm2SupplierId
         ,bm3SupplierId
         ,operationValue
        );
    if ( oaeMsg != null)
    {
      return oaeMsg;
    }
// 2009-04-08 [ST障害T1_0364] Mod End

    // ***********************************
    // 銀行口座情報整合性チェック
    // 金融機関名／支店名／口座番号、口座名義人漢字同一チェック
    // ***********************************
    // ①金融機関名重複チェック
    retCheck
      = isDuplicateBmDest(
          pageRndrVoRow
         ,bm1BankName
         ,bm2BankName
         ,bm3BankName
         ,true
        );
    if ( !retCheck )
    {
      return oaeMsg;
    }
    // ②支店名重複チェック
    retCheck
      = isDuplicateBmDest(
          pageRndrVoRow
         ,bm1BranchNumber
         ,bm2BranchNumber
         ,bm3BranchNumber
         ,true
        );
    if ( !retCheck )
    {
      return oaeMsg;
    }
    // ③口座番号重複チェック
    retCheck
      = isDuplicateBmDest(
          pageRndrVoRow
         ,bm1BankAccountNumber
         ,bm2BankAccountNumber
         ,bm3BankAccountNumber
         ,true
        );
    if ( !retCheck )
    {
      return oaeMsg;
    }
    // 口座名義人（カナ）重複チェック
    retCheck
      = isDuplicateBmDest(
          pageRndrVoRow
         ,bm1BankAccountNameKana
         ,bm2BankAccountNameKana
         ,bm3BankAccountNameKana
         ,true
        );
    if ( !retCheck )
    {
      oaeMsg
        = XxcsoMessage.createErrorMessage(XxcsoConstants.APP_XXCSO1_00523);
      return oaeMsg;
    }

    // 口座名義人（漢字）重複チェック
    retCheck
      = isDuplicateBmDest(
          pageRndrVoRow
         ,bm1BankAccountNameKanji
         ,bm2BankAccountNameKanji
         ,bm3BankAccountNameKanji
         ,true
        );
    if ( !retCheck )
    {
      oaeMsg
        = XxcsoMessage.createErrorMessage(XxcsoConstants.APP_XXCSO1_00523);
      return oaeMsg;
    }

    return oaeMsg;
  }

  /*****************************************************************************
   * 支払明細書整合性チェック
   * @param pageRndrVo   ページ属性設定用ビューインスタンス
   * @param contMngVo    契約管理テーブル情報用ビューインスタンス
   * @param bm1DestVo    BM1送付先テーブル情報用ビューインスタンス
   * @param bm2DestVo    BM2送付先テーブル情報用ビューインスタンス
   * @param bm3DestVo    BM3送付先テーブル情報用ビューインスタンス
   * @param fixedFlag    確定ボタン押下フラグ
   * @return OAException エラー
   *****************************************************************************
   */
  public static OAException validateBellingDetailsCompliance(
    OADBTransaction                     txn
   ,XxcsoPageRenderVOImpl               pageRndrVo
   ,XxcsoContractManagementFullVOImpl   contMngVo
   ,XxcsoBm1DestinationFullVOImpl       bm1DestVo
   ,XxcsoBm2DestinationFullVOImpl       bm2DestVo
   ,XxcsoBm3DestinationFullVOImpl       bm3DestVo
   ,boolean                             fixedFrag
 )
  {
    OAException oaeMsg = null;

    XxcsoUtils.debug(txn, "[START]");

    // 確定ボタン押下時以外は終了
    if (! fixedFrag )
    {
      return oaeMsg;
    }

    // ***********************************
    // データ行を取得
    // ***********************************
    XxcsoPageRenderVORowImpl pageRndrVoRow
      = (XxcsoPageRenderVORowImpl) pageRndrVo.first(); 

    XxcsoContractManagementFullVORowImpl contMngVoRow
      = (XxcsoContractManagementFullVORowImpl) contMngVo.first();

    XxcsoBm1DestinationFullVORowImpl bm1DestVoRow
      = (XxcsoBm1DestinationFullVORowImpl) bm1DestVo.first();

    XxcsoBm2DestinationFullVORowImpl bm2DestVoRow
      = (XxcsoBm2DestinationFullVORowImpl) bm2DestVo.first();

    XxcsoBm3DestinationFullVORowImpl bm3DestVoRow
      = (XxcsoBm3DestinationFullVORowImpl) bm3DestVo.first();

    String bm1BellingDetailsDiv = null;
    String bm2BellingDetailsDiv = null;
    String bm3BellingDetailsDiv = null;

    if (bm1DestVoRow != null)
    {
      bm1BellingDetailsDiv = bm1DestVoRow.getBellingDetailsDiv();
    }
    if (bm2DestVoRow != null)
    {
      bm2BellingDetailsDiv = bm2DestVoRow.getBellingDetailsDiv();
    }
    if (bm3DestVoRow != null)
    {
      bm3BellingDetailsDiv = bm3DestVoRow.getBellingDetailsDiv();
    }



    // 月末締翌20日払チェック
    boolean lastMonthTwentiethPayFlag
      = isLastMonthTwentiethPay(
          contMngVoRow.getCloseDayCode()
         ,contMngVoRow.getTransferMonthCode()
         ,contMngVoRow.getTransferDayCode()
        );

    // BM1 月末締翌20日払-支払明細書区分本振整合性チェック
    boolean bm1Compliance
      = isBellingDetailsCompliance(
              lastMonthTwentiethPayFlag
             ,pageRndrVoRow.getBm1ExistFlag()
             ,bm1BellingDetailsDiv
        );

    // BM2 月末締翌20日払-支払明細書区分本振整合性チェック
    boolean bm2Compliance
      = isBellingDetailsCompliance(
              lastMonthTwentiethPayFlag
             ,pageRndrVoRow.getBm2ExistFlag()
             ,bm2BellingDetailsDiv
        );

    // BM3 月末締翌20日払-支払明細書区分本振整合性チェック
    boolean bm3Compliance
      = isBellingDetailsCompliance(
              lastMonthTwentiethPayFlag
             ,pageRndrVoRow.getBm3ExistFlag()
             ,bm3BellingDetailsDiv
        );

    // BM1、BM2、BM3のいずれかが満たしていなければエラー
    if ( ! bm1Compliance || ! bm2Compliance || ! bm3Compliance )
    {
      oaeMsg
        = XxcsoMessage.createErrorMessage(XxcsoConstants.APP_XXCSO1_00452);
    }

    XxcsoUtils.debug(txn, "[END]");

    return oaeMsg;
  }


  /*****************************************************************************
   * BM重複チェック
   * @param pageRndrVoRow ページ属性設定用ビュー行インスタンス
   * @param bm1Dest  BM1送付先テーブルチェック対象値
   * @param bm2Dest  BM2送付先テーブルチェック対象値
   * @param bm3Dest  BM3送付先テーブルチェック対象値
   * @param allFlag  1～3完全一致指定フラグ(true:完全一致 false:不一致)
   * @return boolean true: 重複している false:重複していない
   *****************************************************************************
   */
  private static boolean isDuplicateBmDest(
    XxcsoPageRenderVORowImpl            pageRndrVoRow
   ,String                              bm1Dest
   ,String                              bm2Dest
   ,String                              bm3Dest
   ,boolean                             allFlag
  )
  {
    List chkList = new ArrayList(3);
    int     chkCnt = 0;
    String dummy = "dummy";

    String bm1Exist = pageRndrVoRow.getBm1ExistFlag();
    String bm2Exist = pageRndrVoRow.getBm2ExistFlag();
    String bm3Exist = pageRndrVoRow.getBm3ExistFlag();

    if ( isChecked(bm1Exist) && isChecked(bm2Exist) && isChecked(bm3Exist) )
    {
      chkCnt = 3;
      chkList.add(bm1Dest);
      chkList.add(bm2Dest);
      chkList.add(bm3Dest);
    }
    else if ( isChecked(bm1Exist) && isChecked(bm2Exist) )
    {
      chkCnt = 1;
      chkList.add(bm1Dest);
      chkList.add(bm2Dest);
    }
    else if ( isChecked(bm1Exist) && isChecked(bm3Exist) )
    {
      chkCnt = 1;
      chkList.add(bm1Dest);
      chkList.add(bm3Dest);
    }
    else if ( isChecked(bm2Exist) && isChecked(bm3Exist) )
    {
      chkCnt = 1;
      chkList.add(bm2Dest);
      chkList.add(bm3Dest);
    }
    else
    {
      // 上記以外は1件または未設定のチェックとみなし、終了
      return false;
    }

    int size = chkList.size();
    int dupCnt = 0;
    for (int i = 0; i < size; i++)
    {
      // チェック対象元
      String dataOrg = (String) chkList.get(i);
      if ( dataOrg == null || "".equals(dataOrg) )
      {
        continue;
      }

      for (int j = i + 1; j < size; j++)
      {
        String data = (String) chkList.get(j);
        if ( data == null || "".equals(data) )
        {
          continue;
        }

        if ( dataOrg.equals(data) )
        {
          dupCnt++;
        }
      }
    }

    boolean ret = false;
    if (allFlag)
    {    
      if (dupCnt == chkCnt)
      {
        ret = true;
      }
    }
    else
    {
      if (dupCnt > 0)
      {
        ret = true;
      }
    }
    return ret;
  }

  /*****************************************************************************
   * 月末締翌20日払-支払明細書区分本振整合性チェック
   * @param lastMonthTwentiethPayFlag 月末締翌20日払フラグ
   * @param bmExistFlag               BM指定チェック
   * @param bmBellingDetailsDiv       BM支払い明細書区分
   * @return boolean true:整合性エラーではない false:整合性エラー
   *****************************************************************************
   */
  private static boolean isBellingDetailsCompliance(
    boolean lastMonthTwentiethPayFlag
   ,String  bmExistFlag
   ,String  bmBellingDetailsDiv
  )
  {
    boolean returnValue = true;

    if ( isChecked(bmExistFlag) )
    {
      boolean bmBellingDetailsTranceferFlag
        = isBellingDetailsTransfer(bmBellingDetailsDiv);

      if ( lastMonthTwentiethPayFlag )
      {
        if ( ! bmBellingDetailsTranceferFlag )
        {
// 2009-04-09 [ST障害T1_0327] Mod Start
//          returnValue = false;
          returnValue = true;
// 2009-04-09 [ST障害T1_0327] Mod End
        }
      }
      else
      {
        if ( bmBellingDetailsTranceferFlag )
        {
          returnValue = false;
        }
      }
    }

    return returnValue;

  }


  /*****************************************************************************
   * BMチェックボックスチェック判定
   * @param  existFlag チェックボックスValue
   * @return boolean true:ON false:OFF
   *****************************************************************************
   */
  private static boolean isChecked(String existFlag)
  {
    return
      XxcsoContractRegistConstants.BM_EXIST_FLAG_ON.equals(existFlag);
  }

  /*****************************************************************************
   * オーナー変更チェックボックスチェック判定
   * @param  ownerChangeFlag チェックボックスValue
   * @return boolean true:ON false:OFF
   *****************************************************************************
   */
  private static boolean isOwnerChangeFlagChecked(String ownerChangeFlag)
  {
    return
      XxcsoContractRegistConstants.OWNER_CHANGE_FLAG_ON.equals(ownerChangeFlag);
  }

  /*****************************************************************************
   *月末締翌20日払判定
   * @param  
   * @return boolean true:月末締翌20日払 false:月末締翌20日払ではない
   *****************************************************************************
   */
  private static boolean isLastMonthTwentiethPay(
    String closeDayCode
   ,String transferMonthCode
   ,String transferDayCode
   )
  {
    return
      XxcsoContractRegistConstants.LAST_DAY.equals(closeDayCode)
    && XxcsoContractRegistConstants.NEXT_MONTH.equals(transferMonthCode)
    && XxcsoContractRegistConstants.TRANSFER_DAY_20.equals(transferDayCode);
  }

  /*****************************************************************************
   * 支払明細書区分本振判定
   * @param  bellingDetailsDiv 支払明細書区分
   * @return boolean true :本振（案内書あり）または 本振（案内書なし）
   *                 false:以外の値
   *****************************************************************************
   */
  private static boolean isBellingDetailsTransfer(
    String bellingDetailsDiv
  )
  {
    return
      XxcsoContractRegistConstants.TRANCE_EXIST.equals(bellingDetailsDiv)
    || XxcsoContractRegistConstants.TRANCE_NON_EXIST.equals(bellingDetailsDiv);
  }

  /*****************************************************************************
   * 郵便番号の検証
   * @param  postalCode    郵便番号
   * @return boolean       検証結果
   *****************************************************************************
   */
  private static boolean isPostalCode(
   String postalCode
  )
  {
    boolean returnValue = true;
    
    if ( postalCode == null || "".equals(postalCode.trim()) )
    {
      // null空文字時はチェック不要
      return true;
    }

    // 7桁の半角文字か
    if ( postalCode.getBytes().length != 7 )
    {
      returnValue = false;
    }
    else
    {
      // 半角数値が指定されているか
      if ( ! postalCode.matches("^[0-9]+$") )
      {
        returnValue = false;
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
      sql.append("  :1 := xxcso_010003j_pkg.chk_double_byte_kana(:2);");
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
         ,XxcsoContractRegistConstants.TOKEN_VALUE_DOUBLE_BYTE_KANA_CHK
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
   * 半角カナの検証（BFA関数）
   * @param txn                 OADBTransactionインスタンス
   * @param value               チェック対象の値
   * @return boolean            検証結果
   *****************************************************************************
   */
  private static boolean isBfaSingleByteKana(
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
      sql.append("  :1 := xxcso_010003j_pkg.chk_bfa_single_byte_kana(:2);");
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
         ,XxcsoContractRegistConstants.TOKEN_VALUE_BFA_SINGLE_BYTE_KANA_CHK
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
   * AR会計期間クローズチェック
   * @param txn                 OADBTransactionインスタンス
   * @param value               チェック対象の値
   * @return boolean            検証結果
   *****************************************************************************
   */
  private static boolean isArGlPriodStatus(
    OADBTransaction   txn
   ,Date              value
  )
  {
    OracleCallableStatement stmt = null;
    boolean returnValue = true;
    
    if ( value == null)
    {
      return true;
    }
    
    try
    {
      StringBuffer sql = new StringBuffer(100);
      sql.append("BEGIN");
      sql.append("  :1 := xxcso_util_common_pkg.");
      sql.append("check_ar_gl_period_status(TO_DATE(:2));");
      sql.append("END;");

      stmt
        = (OracleCallableStatement)
            txn.createCallableStatement(sql.toString(), 0);

      stmt.registerOutParameter(1, OracleTypes.VARCHAR);
      stmt.setString(2, value.dateValue().toString());

      stmt.execute();

      String returnString = stmt.getString(1);
      if ( ! "TRUE".equals(returnString) )
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
         ,XxcsoContractRegistConstants.TOKEN_VALUE_AR_GL_PERIOD_STATUS
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

// 2009-04-08 [ST障害T1_0364] Del Start
//  /*****************************************************************************
//   * 送付先名マスタ存在チェック
//   * @param txn                 OADBTransactionインスタンス
//   * @param dm1VendorName       DM1送付先名
//   * @param dm2VendorName       DM2送付先名
//   * @param dm3VendorName       DM3送付先名
//   * @param dm1SupplierId       DM1仕入先ID
//   * @param dm2SupplierId       DM2仕入先ID
//   * @param dm3SupplierId       DM3仕入先ID
//   * @return boolean            検証結果
//   *****************************************************************************
//   */
//  private static boolean isDuplicateVendorName(
//    OADBTransaction   txn
//   ,String            dm1VendorName
//   ,String            dm2VendorName
//   ,String            dm3VendorName
//   ,Number            contMngId
//   ,Number            dm1SupplierId
//   ,Number            dm2SupplierId
//   ,Number            dm3SupplierId
//  )
//  {
//    OracleCallableStatement stmt = null;
//    boolean returnValue = true;
//    
//    try
//    {
//      StringBuffer sql = new StringBuffer(100);
//      sql.append("BEGIN");
//      sql.append("  :1 := xxcso_010003j_pkg.");
//      sql.append("chk_duplicate_vendor_name(:2, :3, :4, :5, :6, :7, :8);");
//      sql.append("END;");
//
//      // パラメータの自動販売機設置契約書IDのマイナス値考慮
//      Number paramContMngId = null;
//      if (contMngId != null && (contMngId.intValue() > 0) )
//      {
//        paramContMngId = contMngId;
//      }
//
//      stmt
//        = (OracleCallableStatement)
//            txn.createCallableStatement(sql.toString(), 0);
//
//      int idx = 1;
//      stmt.registerOutParameter(idx++, OracleTypes.VARCHAR);
//      stmt.setString(idx++, dm1VendorName);
//      stmt.setString(idx++, dm2VendorName);
//      stmt.setString(idx++, dm3VendorName);
//      stmt.setNUMBER(idx++, paramContMngId);
//      stmt.setNUMBER(idx++, dm1SupplierId);
//      stmt.setNUMBER(idx++, dm2SupplierId);
//      stmt.setNUMBER(idx++, dm3SupplierId);
//
//      stmt.execute();
//
//      String returnString = stmt.getString(1);
//      if ( ! "1".equals(returnString) )
//      {
//        returnValue = false;
//      }
//    }
//    catch ( SQLException e )
//    {
//      XxcsoUtils.unexpected(txn, e);
//      throw
//        XxcsoMessage.createSqlErrorMessage(
//          e
//         ,XxcsoContractRegistConstants.TOKEN_VALUE_DUPLICATE_VENDOR_NAME_CHK
//        );
//    }
//    finally
//    {
//      try
//      {
//        if ( stmt != null )
//        {
//          stmt.close();
//        }
//      }
//      catch ( SQLException e )
//      {
//        XxcsoUtils.unexpected(txn, e);
//      }
//    }
//
//    return returnValue;
//  }
// 2009-04-08 [ST障害T1_0364] Del End
// 2009-04-08 [ST障害T1_0364] Add Start
  /*****************************************************************************
   * 送付先名マスタ存在チェック
   * @param txn                 OADBTransactionインスタンス
   * @param bm1VendorName       DM1送付先名
   * @param bm2VendorName       DM2送付先名
   * @param bm3VendorName       DM3送付先名
   * @param bm1SupplierId       DM1仕入先ID
   * @param bm2SupplierId       DM2仕入先ID
   * @param bm3SupplierId       DM3仕入先ID
   * @param operationValue      押下ボタン判別値
   * @return OAException        エラーメッセージ
   *****************************************************************************
   */
   private static OAException chkDuplicateVendorName(
    OADBTransaction   txn
   ,String            bm1VendorName
   ,String            bm2VendorName
   ,String            bm3VendorName
   ,Number            bm1SupplierId
   ,Number            bm2SupplierId
   ,Number            bm3SupplierId
   ,String            operationValue
   )
  {
    OracleCallableStatement stmt        = null;
    OAException             returnMsg   = null;
    ArrayList               bmList      = null;
    ArrayList               cntNumList  = null;
    
    try
    {
      StringBuffer sql = new StringBuffer(300);
      sql.append("BEGIN");
      sql.append("  xxcso_010003j_pkg.chk_duplicate_vendor_name(");
      sql.append("     iv_bm1_vendor_name     => :1");
      sql.append("    ,iv_bm2_vendor_name     => :2");
      sql.append("    ,iv_bm3_vendor_name     => :3");
      sql.append("    ,in_bm1_supplier_id     => :4");
      sql.append("    ,in_bm2_supplier_id     => :5");
      sql.append("    ,in_bm3_supplier_id     => :6");
      sql.append("    ,iv_operation_mode      => :7");
      sql.append("    ,on_bm1_dup_count       => :8");
      sql.append("    ,on_bm2_dup_count       => :9");
      sql.append("    ,on_bm3_dup_count       => :10");
      sql.append("    ,ov_bm1_contract_number => :11");
      sql.append("    ,ov_bm2_contract_number => :12");
      sql.append("    ,ov_bm3_contract_number => :13");
      sql.append("    ,ov_errbuf              => :14");
      sql.append("    ,ov_retcode             => :15");
      sql.append("    ,ov_errmsg              => :16");
      sql.append("  );");
      sql.append("END;");

      stmt
        = (OracleCallableStatement)
            txn.createCallableStatement(sql.toString(), 0);

      stmt.setString(1, bm1VendorName);
      stmt.setString(2, bm2VendorName);
      stmt.setString(3, bm3VendorName);
      stmt.setNUMBER(4, bm1SupplierId);
      stmt.setNUMBER(5, bm2SupplierId);
      stmt.setNUMBER(6, bm3SupplierId);
      stmt.setString(7, operationValue);
      stmt.registerOutParameter(8,  OracleTypes.NUMBER);
      stmt.registerOutParameter(9,  OracleTypes.NUMBER);
      stmt.registerOutParameter(10, OracleTypes.NUMBER);
      stmt.registerOutParameter(11, OracleTypes.VARCHAR);
      stmt.registerOutParameter(12, OracleTypes.VARCHAR);
      stmt.registerOutParameter(13, OracleTypes.VARCHAR);
      stmt.registerOutParameter(14, OracleTypes.VARCHAR);
      stmt.registerOutParameter(15, OracleTypes.VARCHAR);
      stmt.registerOutParameter(16, OracleTypes.VARCHAR);

      XxcsoUtils.debug(txn, "execute stored start");
      stmt.execute();
      XxcsoUtils.debug(txn, "execute stored end");

      NUMBER bm1DupCnt    = stmt.getNUMBER(8);
      NUMBER bm2DupCnt    = stmt.getNUMBER(9);
      NUMBER bm3DupCnt    = stmt.getNUMBER(10);
      String bm1CntrctNum = stmt.getString(11);
      String bm2CntrctNum = stmt.getString(12);
      String bm3CntrctNum = stmt.getString(13);
      String errBuf       = stmt.getString(14);
      String retCode      = stmt.getString(15);
      String errMsg       = stmt.getString(16);

      XxcsoUtils.debug(txn, "bm1DupCnt    = " + bm1DupCnt.stringValue());
      XxcsoUtils.debug(txn, "bm2DupCnt    = " + bm2DupCnt.stringValue());
      XxcsoUtils.debug(txn, "bm2DupCnt    = " + bm3DupCnt.stringValue());
      XxcsoUtils.debug(txn, "bm1CntrctNum = " + bm1CntrctNum);
      XxcsoUtils.debug(txn, "bm2CntrctNum = " + bm2CntrctNum);
      XxcsoUtils.debug(txn, "bm2CntrctNum = " + bm3CntrctNum);
      XxcsoUtils.debug(txn, "errbuf       = " + errBuf);
      XxcsoUtils.debug(txn, "retCode      = " + retCode);
      XxcsoUtils.debug(txn, "errmsg       = " + errMsg);

      if ( ! "0".equals(retCode) )
      {
        // ////////////////////////////////
        // BM送付先エラー箇所の設定
        // ////////////////////////////////
        bmList = new ArrayList(3);
        if ( ! "0".equals(bm1DupCnt.stringValue()) )
        {
          bmList.add(
            XxcsoContractRegistConstants.TOKEN_VALUE_BM1
            + XxcsoContractRegistConstants.TOKEN_VALUE_PAYMENT_NAME
          );
        }
        if ( ! "0".equals(bm2DupCnt.stringValue()) )
        {
          bmList.add(
            XxcsoContractRegistConstants.TOKEN_VALUE_BM2
            + XxcsoContractRegistConstants.TOKEN_VALUE_PAYMENT_NAME
          );
        }
        if ( ! "0".equals(bm3DupCnt.stringValue()) )
        {
          bmList.add(
            XxcsoContractRegistConstants.TOKEN_VALUE_BM3
            + XxcsoContractRegistConstants.TOKEN_VALUE_PAYMENT_NAME
          );
        }

        StringBuffer sbTokenItem = new StringBuffer();
        int listCnt = bmList.size();
        for (int i = 0; i < listCnt; i++)
        {
          if (i != 0)
          {
            sbTokenItem.append(XxcsoConstants.TOKEN_VALUE_DELIMITER2);
          }
          sbTokenItem.append( (String) bmList.get(i) );
        }

        // ////////////////////////////////
        // 契約書番号の設定
        // ////////////////////////////////
        HashMap cntrctNumErrMap = new HashMap();
        cntrctNumErrMap.put(bm1CntrctNum, bm1CntrctNum);
        cntrctNumErrMap.put(bm2CntrctNum, bm2CntrctNum);
        cntrctNumErrMap.put(bm3CntrctNum, bm3CntrctNum);
        cntrctNumErrMap.remove(null);
        cntrctNumErrMap.remove("");

        StringBuffer sbTokenRecord = new StringBuffer();
        Iterator ite = cntrctNumErrMap.keySet().iterator();
        int mapCnt = 0;
        while( ite.hasNext() )
        {
          String contractNumber = (String)ite.next();
          if (mapCnt != 0)
          {
            sbTokenRecord.append(XxcsoConstants.TOKEN_VALUE_DELIMITER2);
          }
          sbTokenRecord.append(contractNumber);
          mapCnt++;
        }

        if ( "1".equals(retCode) )
        {
          // 2009-10-14 [IE554,IE573] Add Start
          // 仕入先マスタ重複エラー
          //returnMsg
          //  = XxcsoMessage.createErrorMessage(
          //      XxcsoConstants.APP_XXCSO1_00558
          //     ,XxcsoConstants.TOKEN_ITEM
          //     ,new String(sbTokenItem)
          //    );
          // 2009-10-14 [IE554,IE573] Add End
        }
        else
        {
          // 2009-10-14 [IE554,IE573] Add Start
          // 送付先テーブル重複エラー
          //returnMsg
          //  = XxcsoMessage.createErrorMessage(
          //      XxcsoConstants.APP_XXCSO1_00559
          //     ,XxcsoConstants.TOKEN_ITEM
          //     ,new String(sbTokenItem)
          //     ,XxcsoConstants.TOKEN_RECORD
          //     ,new String(sbTokenRecord)
          //    );
          // 2009-10-14 [IE554,IE573] Add End
        }
      }
    }
    catch ( SQLException e )
    {
      XxcsoUtils.unexpected(txn, e);
      throw
        XxcsoMessage.createSqlErrorMessage(
          e
         ,XxcsoContractRegistConstants.TOKEN_VALUE_DUPLICATE_VENDOR_NAME_CHK
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

    return returnMsg;
  }
// 2009-04-08 [ST障害T1_0364] Add End

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
      sql.append("  :1 := xxcso_010003j_pkg.chk_double_byte(:2);");
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
         ,XxcsoContractRegistConstants.TOKEN_VALUE_DOUBLE_BYTE_CHK
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
      sql.append("  :1 := xxcso_010003j_pkg.chk_single_byte_kana(:2);");
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
         ,XxcsoContractRegistConstants.TOKEN_VALUE_SINGLE_BYTE_KANA_CHK
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

}