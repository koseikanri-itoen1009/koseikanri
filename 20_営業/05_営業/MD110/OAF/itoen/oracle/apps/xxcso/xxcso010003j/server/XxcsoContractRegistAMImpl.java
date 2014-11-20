/*============================================================================
* ファイル名 : XxcsoContractRegistAMImpl
* 概要説明   : 自販機設置契約情報登録画面アプリケーション・モジュールクラス
* バージョン : 1.5
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2009-01-27 1.0  SCS小川浩    新規作成
* 2009-02-16 1.1  SCS柳平直人  [CT1-008]BM指定チェックボックス不正対応
* 2009-02-23 1.1  SCS柳平直人  [CT1-021]送付先コード取得不正対応
*                              [CT1-022]口座情報取得不正対応
* 2009-04-08 1.2  SCS柳平直人  [ST障害T1_0364]仕入先重複チェック修正対応
* 2010-01-26 1.3  SCS阿部大輔  [E_本稼動_01314]契約書発効日必須対応
* 2010-01-20 1.4  SCS阿部大輔  [E_本稼動_01176]口座種別対応
* 2010-02-09 1.5  SCS阿部大輔  [E_本稼動_01538]契約書の複数確定対応
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso010003j.server;

import com.sun.java.util.collections.ArrayList;
import com.sun.java.util.collections.HashMap;
import com.sun.java.util.collections.List;

import itoen.oracle.apps.xxcso.common.poplist.server.XxcsoLookupListVOImpl;
import itoen.oracle.apps.xxcso.common.util.XxcsoConstants;
import itoen.oracle.apps.xxcso.common.util.XxcsoMessage;
import itoen.oracle.apps.xxcso.common.util.XxcsoUtils;
import itoen.oracle.apps.xxcso.xxcso010003j.util.XxcsoContractRegistConstants;
import itoen.oracle.apps.xxcso.xxcso010003j.util.XxcsoContractRegistInitUtils;
import itoen.oracle.apps.xxcso.xxcso010003j.util.XxcsoContractRegistPropertyUtils;
import itoen.oracle.apps.xxcso.xxcso010003j.util.XxcsoContractRegistReflectUtils;
import itoen.oracle.apps.xxcso.xxcso010003j.util.XxcsoContractRegistValidateUtils;

import java.sql.SQLException;

import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.framework.server.OAApplicationModuleImpl;
import oracle.apps.fnd.framework.server.OADBTransaction;

import oracle.jbo.server.ViewLinkImpl;

import oracle.jdbc.OracleCallableStatement;
import oracle.jdbc.OracleTypes;

import oracle.sql.NUMBER;


/*******************************************************************************
 * 自販機設置契約情報の保存／確定を行うためのアプリケーション・モジュールクラス。
 * @author  SCS柳平直人
 * @version 1.1
 *******************************************************************************
 */
public class XxcsoContractRegistAMImpl extends OAApplicationModuleImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoContractRegistAMImpl()
  {
  }

  /*****************************************************************************
   * 出力メッセージ
   *****************************************************************************
   */
  private OAException mMessage = null;

  /*****************************************************************************
   * アプリケーション・モジュールの初期化処理です（新規作成）。
   * @param spDecisionHeaderId   SP専決ヘッダID
   * @param contractManagementId 契約管理ID
   *****************************************************************************
   */
  public void initDetailsCreate(
    String spDecisionHeaderId
   ,String contractManagementId
  )
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    // インスタンス取得
    XxcsoPageRenderVOImpl pageRenderVo
      = getXxcsoPageRenderVO1();
    if ( pageRenderVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoPageRenderVOImpl");
    }

    XxcsoLoginUserAuthorityVOImpl userAuthVo
      = getXxcsoLoginUserAuthorityVO1();
    if ( userAuthVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoLoginUserAuthorityVOImpl");
    }

    XxcsoLoginUserSummaryVOImpl userVo
      = getXxcsoLoginUserSummaryVO1();
    if ( userVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoLoginUserSummaryVO1");
    }

    XxcsoContractCreateInitVOImpl createVo
      = getXxcsoContractCreateInitVO1();
    if ( createVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoContractCreateInitVO1");
    }

    XxcsoSalesCondSummaryVOImpl salesCondVo
      = getXxcsoSalesCondSummaryVO1();
    if ( salesCondVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoSalesCondSummaryVOImpl");
    }

    XxcsoContainerCondSummaryVOImpl contCondVo
      = getXxcsoContainerCondSummaryVO1();
    if ( contCondVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoContainerCondSummaryVOImpl");
    }

    XxcsoInitBmInfoSummaryVOImpl initBmVo
      = getXxcsoInitBmInfoSummaryVO1();
    if ( initBmVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoInitBmInfoSummaryVO1");
    }

    XxcsoContractManagementFullVOImpl mngVo
      = getXxcsoContractManagementFullVO1();
    if ( mngVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoContractManagementFullVO1");
    }

    XxcsoContractCustomerFullVOImpl cntrctVo
      = getXxcsoContractCustomerFullVO1();
    if ( cntrctVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoContractCustomerFullVO1");
    }

    XxcsoBm1DestinationFullVOImpl dest1Vo
      = getXxcsoBm1DestinationFullVO1();
    if ( dest1Vo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoBm1DestinationFullVO1");
    }

    XxcsoBm2DestinationFullVOImpl dest2Vo
      = getXxcsoBm2DestinationFullVO1();
    if ( dest2Vo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoBm2DestinationFullVO1");
    }

    XxcsoBm3DestinationFullVOImpl dest3Vo
      = getXxcsoBm3DestinationFullVO1();
    if ( dest3Vo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoBm3DestinationFullVO1");
    }

    XxcsoBm1BankAccountFullVOImpl bank1Vo
      = getXxcsoBm1BankAccountFullVO1();
    if ( bank1Vo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoBm1BankAccountFullVO1");
    }

    XxcsoBm2BankAccountFullVOImpl bank2Vo
      = getXxcsoBm2BankAccountFullVO1();
    if ( bank2Vo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoBm2BankAccountFullVO1");
    }

    XxcsoBm3BankAccountFullVOImpl bank3Vo
      = getXxcsoBm3BankAccountFullVO1();
    if ( bank3Vo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoBm3BankAccountFullVO1");
    }

    XxcsoBm1ContractSpCustFullVOImpl spCust1Vo
      = getXxcsoBm1ContractSpCustFullVO1();
    if ( spCust1Vo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoBm1ContractSpCustFullVO1");
    }

    XxcsoBm2ContractSpCustFullVOImpl spCust2Vo
      = getXxcsoBm2ContractSpCustFullVO1();
    if ( spCust2Vo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoBm2ContractSpCustFullVO1");
    }

    XxcsoBm3ContractSpCustFullVOImpl spCust3Vo
      = getXxcsoBm3ContractSpCustFullVO1();
    if ( spCust3Vo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoBm3ContractSpCustFullVO1");
    }


    XxcsoContractRegistInitUtils.initCreate(
      txn
     ,spDecisionHeaderId
     ,pageRenderVo
     ,userAuthVo
     ,userVo
     ,createVo
     ,salesCondVo
     ,contCondVo
     ,initBmVo
     ,mngVo
     ,cntrctVo
     ,dest1Vo
     ,dest2Vo
     ,dest3Vo
     ,bank1Vo
     ,bank2Vo
     ,bank3Vo
     ,spCust1Vo
     ,spCust2Vo
     ,spCust3Vo
    );
    
    XxcsoUtils.debug(txn, "[END]");
  }

  /*****************************************************************************
   * アプリケーション・モジュールの初期化処理です（更新）。
   * @param spDecisionHeaderId   SP専決ヘッダID
   * @param contractManagementId 契約管理ID
   *****************************************************************************
   */
  public void initDetailsUpdate(
    String spDecisionHeaderId
   ,String contractManagementId
  )
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    // インスタンス取得
    XxcsoPageRenderVOImpl pageRenderVo
      = getXxcsoPageRenderVO1();
    if ( pageRenderVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoPageRenderVOImpl");
    }

    XxcsoLoginUserAuthorityVOImpl userAuthVo
      = getXxcsoLoginUserAuthorityVO1();
    if ( userAuthVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoLoginUserAuthorityVOImpl");
    }

    XxcsoLoginUserSummaryVOImpl userVo
      = getXxcsoLoginUserSummaryVO1();
    if ( userVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoLoginUserSummaryVO1");
    }

    XxcsoContractCreateInitVOImpl createVo
      = getXxcsoContractCreateInitVO1();
    if ( createVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoContractCreateInitVO1");
    }

    XxcsoSalesCondSummaryVOImpl salesCondVo
      = getXxcsoSalesCondSummaryVO1();
    if ( salesCondVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoSalesCondSummaryVOImpl");
    }

    XxcsoContainerCondSummaryVOImpl contCondVo
      = getXxcsoContainerCondSummaryVO1();
    if ( contCondVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoContainerCondSummaryVOImpl");
    }

    XxcsoInitBmInfoSummaryVOImpl initBmVo
      = getXxcsoInitBmInfoSummaryVO1();
    if ( initBmVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoInitBmInfoSummaryVO1");
    }

    XxcsoContractManagementFullVOImpl mngVo
      = getXxcsoContractManagementFullVO1();
    if ( mngVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoContractManagementFullVO1");
    }

    XxcsoContractCustomerFullVOImpl cntrctVo
      = getXxcsoContractCustomerFullVO1();
    if ( cntrctVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoContractCustomerFullVO1");
    }

    XxcsoBm1DestinationFullVOImpl dest1Vo
      = getXxcsoBm1DestinationFullVO1();
    if ( dest1Vo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoBm1DestinationFullVO1");
    }

    XxcsoBm2DestinationFullVOImpl dest2Vo
      = getXxcsoBm2DestinationFullVO1();
    if ( dest2Vo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoBm2DestinationFullVO1");
    }

    XxcsoBm3DestinationFullVOImpl dest3Vo
      = getXxcsoBm3DestinationFullVO1();
    if ( dest3Vo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoBm3DestinationFullVO1");
    }

    XxcsoBm1BankAccountFullVOImpl bank1Vo
      = getXxcsoBm1BankAccountFullVO1();
    if ( bank1Vo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoBm1BankAccountFullVO1");
    }

    XxcsoBm2BankAccountFullVOImpl bank2Vo
      = getXxcsoBm2BankAccountFullVO1();
    if ( bank2Vo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoBm2BankAccountFullVO1");
    }

    XxcsoBm3BankAccountFullVOImpl bank3Vo
      = getXxcsoBm3BankAccountFullVO1();
    if ( bank3Vo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoBm3BankAccountFullVO1");
    }

    XxcsoBm1ContractSpCustFullVOImpl spCust1Vo
      = getXxcsoBm1ContractSpCustFullVO1();
    if ( spCust1Vo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoBm1ContractSpCustFullVO1");
    }

    XxcsoBm2ContractSpCustFullVOImpl spCust2Vo
      = getXxcsoBm2ContractSpCustFullVO1();
    if ( spCust2Vo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoBm2ContractSpCustFullVO1");
    }

    XxcsoBm3ContractSpCustFullVOImpl spCust3Vo
      = getXxcsoBm3ContractSpCustFullVO1();
    if ( spCust3Vo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoBm3ContractSpCustFullVO1");
    }

    XxcsoContractRegistInitUtils.initUpdate(
      txn
     ,contractManagementId
     ,spDecisionHeaderId
     ,pageRenderVo
     ,userAuthVo
     ,userVo
     ,createVo
     ,salesCondVo
     ,contCondVo
     ,initBmVo
     ,mngVo
     ,cntrctVo
     ,dest1Vo
     ,dest2Vo
     ,dest3Vo
     ,bank1Vo
     ,bank2Vo
     ,bank3Vo
     ,spCust1Vo
     ,spCust2Vo
     ,spCust3Vo
    );
    XxcsoUtils.debug(txn, "[END]");
  }

  /*****************************************************************************
   * アプリケーション・モジュールの初期化処理です（コピー）。
   * @param spDecisionHeaderId   SP専決ヘッダID
   * @param contractManagementId 契約管理ID
   *****************************************************************************
   */
  public void initDetailsCopy(
    String spDecisionHeaderId
   ,String contractManagementId
  )
  {
    OADBTransaction txn = getOADBTransaction();
    XxcsoUtils.debug(txn, "[START]");

    // インスタンス取得
    XxcsoPageRenderVOImpl pageRenderVo
      = getXxcsoPageRenderVO1();
    if ( pageRenderVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoPageRenderVOImpl");
    }

    XxcsoLoginUserAuthorityVOImpl userAuthVo
      = getXxcsoLoginUserAuthorityVO1();
    if ( userAuthVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoLoginUserAuthorityVOImpl");
    }

    XxcsoLoginUserSummaryVOImpl userVo
      = getXxcsoLoginUserSummaryVO1();
    if ( userVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoLoginUserSummaryVO1");
    }

    XxcsoContractCreateInitVOImpl createVo
      = getXxcsoContractCreateInitVO1();
    if ( createVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoContractCreateInitVO1");
    }

    XxcsoSalesCondSummaryVOImpl salesCondVo
      = getXxcsoSalesCondSummaryVO1();
    if ( salesCondVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoSalesCondSummaryVOImpl");
    }

    XxcsoContainerCondSummaryVOImpl contCondVo
      = getXxcsoContainerCondSummaryVO1();
    if ( contCondVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoContainerCondSummaryVOImpl");
    }

    XxcsoInitBmInfoSummaryVOImpl initBmVo
      = getXxcsoInitBmInfoSummaryVO1();
    if ( initBmVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoInitBmInfoSummaryVO1");
    }

    XxcsoContractManagementFullVOImpl mngVo
      = getXxcsoContractManagementFullVO1();
    if ( mngVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoContractManagementFullVO1");
    }

    XxcsoContractCustomerFullVOImpl cntrctVo
      = getXxcsoContractCustomerFullVO1();
    if ( cntrctVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoContractCustomerFullVO1");
    }

    XxcsoBm1DestinationFullVOImpl dest1Vo
      = getXxcsoBm1DestinationFullVO1();
    if ( dest1Vo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoBm1DestinationFullVO1");
    }

    XxcsoBm2DestinationFullVOImpl dest2Vo
      = getXxcsoBm2DestinationFullVO1();
    if ( dest2Vo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoBm2DestinationFullVO1");
    }

    XxcsoBm3DestinationFullVOImpl dest3Vo
      = getXxcsoBm3DestinationFullVO1();
    if ( dest3Vo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoBm3DestinationFullVO1");
    }

    XxcsoBm1BankAccountFullVOImpl bank1Vo
      = getXxcsoBm1BankAccountFullVO1();
    if ( bank1Vo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoBm1BankAccountFullVO1");
    }

    XxcsoBm2BankAccountFullVOImpl bank2Vo
      = getXxcsoBm2BankAccountFullVO1();
    if ( bank2Vo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoBm2BankAccountFullVO1");
    }

    XxcsoBm3BankAccountFullVOImpl bank3Vo
      = getXxcsoBm3BankAccountFullVO1();
    if ( bank3Vo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoBm3BankAccountFullVO1");
    }

    XxcsoBm1ContractSpCustFullVOImpl spCust1Vo
      = getXxcsoBm1ContractSpCustFullVO1();
    if ( spCust1Vo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoBm1ContractSpCustFullVO1");
    }

    XxcsoBm2ContractSpCustFullVOImpl spCust2Vo
      = getXxcsoBm2ContractSpCustFullVO1();
    if ( spCust2Vo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoBm2ContractSpCustFullVO1");
    }

    XxcsoBm3ContractSpCustFullVOImpl spCust3Vo
      = getXxcsoBm3ContractSpCustFullVO1();
    if ( spCust3Vo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoBm3ContractSpCustFullVO1");
    }

    XxcsoContractManagementFullVOImpl mngVo2
      = getXxcsoContractManagementFullVO2();
    if ( mngVo2 == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoContractManagementFullVO2");
    }

    XxcsoBm1DestinationFullVOImpl dest1Vo2
      = getXxcsoBm1DestinationFullVO2();
    if ( dest1Vo2 == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoBm1DestinationFullVO2");
    }

    XxcsoBm2DestinationFullVOImpl dest2Vo2
      = getXxcsoBm2DestinationFullVO2();
    if ( dest2Vo2 == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoBm2DestinationFullVO2");
    }

    XxcsoBm3DestinationFullVOImpl dest3Vo2
      = getXxcsoBm3DestinationFullVO2();
    if ( dest3Vo2 == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoBm3DestinationFullVO2");
    }

    XxcsoBm1BankAccountFullVOImpl bank1Vo2
      = getXxcsoBm1BankAccountFullVO2();
    if ( bank1Vo2 == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoBm1BankAccountFullVO2");
    }

    XxcsoBm2BankAccountFullVOImpl bank2Vo2
      = getXxcsoBm2BankAccountFullVO2();
    if ( bank2Vo2 == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoBm2BankAccountFullVO2");
    }

    XxcsoBm3BankAccountFullVOImpl bank3Vo2
      = getXxcsoBm3BankAccountFullVO2();
    if ( bank3Vo2 == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoBm3BankAccountFullVO2");
    }

    XxcsoContractRegistInitUtils.initCopy(
      txn
     ,contractManagementId
     ,spDecisionHeaderId
     ,pageRenderVo
     ,userAuthVo
     ,userVo
     ,createVo
     ,salesCondVo
     ,contCondVo
     ,initBmVo
     ,mngVo
     ,cntrctVo
     ,dest1Vo
     ,dest2Vo
     ,dest3Vo
     ,bank1Vo
     ,bank2Vo
     ,bank3Vo
     ,spCust1Vo
     ,spCust2Vo
     ,spCust3Vo
     ,mngVo2
     ,dest1Vo2
     ,dest2Vo2
     ,dest3Vo2
     ,bank1Vo2
     ,bank2Vo2
     ,bank3Vo2
    );

    XxcsoUtils.debug(txn, "[END]");
  }

  /*****************************************************************************
   * 表示属性設定処理です。
   *****************************************************************************
   */
  public void setAttributeProperty()
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    // インスタンス取得
    XxcsoPageRenderVOImpl pageRenderVo = getXxcsoPageRenderVO1();
    if ( pageRenderVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoPageRenderVOImpl");
    }

    XxcsoLoginUserAuthorityVOImpl userAuthVo
      = getXxcsoLoginUserAuthorityVO1();
    if ( userAuthVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoLoginUserAuthorityVOImpl");
    }

    XxcsoContractManagementFullVOImpl mngVo
      = getXxcsoContractManagementFullVO1();
    if ( mngVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoContractManagementFullVO1");
    }

    XxcsoContractCreateInitVOImpl createVo = getXxcsoContractCreateInitVO1();
    if ( createVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoContractCreateInitVO1");
    }

    // 本処理
    XxcsoContractRegistPropertyUtils.setAttributeProperty(
      pageRenderVo
     ,userAuthVo
     ,mngVo
     ,createVo
    );

    XxcsoUtils.debug(txn, "[END]");

  }

  /*****************************************************************************
   * ポップリストの初期化処理です。
   *****************************************************************************
   */
  public void initPopList()
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    // 契約書フォーマット
    XxcsoLookupListVOImpl contractFormatVo = getXxcsoContractFormatListVO();
    if ( contractFormatVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoContractFormatListVO");
    }

    contractFormatVo.initQuery(
      "XXCSO1_CONTRACT_FORMAT"
     ,"lookup_code"
    );

    // ステータス
    XxcsoLookupListVOImpl contractStatusVo = getXxcsoContractStatusListVO();
    if ( contractStatusVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoContractStatusListVO");
    }

    contractStatusVo.initQuery(
      "XXCSO1_CONTRACT_STATUS"
     ,"lookup_code"
    );

    // 日付タイプ（締め日、振込日）
    XxcsoLookupListVOImpl daysListVo = getXxcsoDaysListVO();
    if ( daysListVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoDaysListVO");
    }

    daysListVo.initQuery(
      "XXCSO1_DAYS_TYPE"
     ,"TO_NUMBER(lookup_code)"
    );

    // 月タイプ（振込月）
    XxcsoLookupListVOImpl monthsListVo = getXxcsoMonthsListVO();
    if ( monthsListVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoMonthsListVO");
    }

    monthsListVo.initQuery(
      "XXCSO1_MONTHS_TYPE"
     ,"lookup_code"
    );

    // 契約解除申し出
    XxcsoLookupListVOImpl cancellationListVo
      = getXxcsoCancellationListVO();
    if ( cancellationListVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoCancellationListVO");
    }

    cancellationListVo.initQuery(
      "XXCSO1_CANCELLATION_MONTH"
     ,"lookup_code"
    );

    // 振込手数料負担
    XxcsoLookupListVOImpl transferFeeListVo
      = getXxcsoTransferFeeListVO();
    if ( transferFeeListVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoTransferFeeListVO");
    }

    transferFeeListVo.initQuery(
      "XXCSO1_SP_TRANSFER_FEE_TYPE"
     ,"lookup_code"
    );

    // 支払方法、明細書
    XxcsoLookupListVOImpl bmPaymentListVo = getXxcsoBmPaymentListVO();
    if ( bmPaymentListVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoBmPaymentListVO");
    }

    bmPaymentListVo.initQuery(
      "XXCMM_BM_PAYMENT_KBN"
     ,"(attribute1 = 'Y') AND (lookup_code <> '5')"
     ,"lookup_code"
    );

    // 口座種別
    XxcsoLookupListVOImpl kozaListVo = getXxcsoKozaListVO();
    if ( kozaListVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoKozaListVO");
    }

    kozaListVo.initQuery(
// 2010-01-20 [E_本稼動_01176] Add Start
      //"JP_BANK_ACCOUNT_TYPE"
      "XXCSO1_KOZA_TYPE"
// 2010-01-20 [E_本稼動_01176] Add End
     ,"lookup_code"
    );
    
    XxcsoUtils.debug(txn, "[END]");
  }

  /*****************************************************************************
   * 取消ボタン押下処理
   *****************************************************************************
   */
  public void handleCancelButton()
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    this.rollback();

    XxcsoUtils.debug(txn, "[END]");
  }

  /*****************************************************************************
   * 適用ボタン押下処理
   *****************************************************************************
   */
  public void handleApplyButton()
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    this.validateAll(false);

    mMessage = this.validateBmAccountInfo();

    XxcsoUtils.debug(txn, "[END]");
  }

  /*****************************************************************************
   * 確定ボタン押下処理
   *****************************************************************************
   */
  public void handleSubmitButton()
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    this.validateAll(true);

    mMessage = this.validateBmAccountInfo();

    XxcsoUtils.debug(txn, "[END]");

  }


  /*****************************************************************************
   * PDF作成ボタン押下処理
   *****************************************************************************
   */
  public HashMap handlePrintPdfButton()
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    XxcsoContractManagementFullVOImpl mngVo
      = getXxcsoContractManagementFullVO1();
    if ( mngVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoContractManagementFullVO1");
    }

    XxcsoContractManagementFullVORowImpl mngRow
      = (XxcsoContractManagementFullVORowImpl) mngVo.first();

    // 契約書フォーマットにその他が選択されている場合、エラー
    if ( XxcsoContractRegistConstants.FORMAT_OTHER.equals(
          mngRow.getContractFormat()
         )
    )
    {
      throw
        XxcsoMessage.createErrorMessage( XxcsoConstants.APP_XXCSO1_00448 );
    }

    // ステータスが作成中の場合は入力チェック実施
    if (XxcsoContractRegistConstants.STS_INPUT.equals( mngRow.getStatus() ) )
    {
 // 2010-01-26 [E_本稼動_01314] Add Start
      //if ( getTransaction().isDirty() )
      //{
// 2010-01-26 [E_本稼動_01314] Add End
      this.validateAll(false);
// 2010-02-09 [E_本稼動_01538] Mod Start
      /////////////////////////////////////
      // 検証処理：ＤＢ値検証
      /////////////////////////////////////
      OAException oaeMsg = null;

      oaeMsg
        = XxcsoContractRegistValidateUtils.validateDb(
            txn
           ,mngVo
          );
      if (oaeMsg != null)
      {
        throw oaeMsg;
      }
// 2010-02-09 [E_本稼動_01538] Mod End
      // 保存処理を実行します。
      this.commit();
// 2010-01-26 [E_本稼動_01314] Add Start
      //}
// 2010-01-26 [E_本稼動_01314] Add End
    }
    else
    {
      this.rollback();
    }

    // /////////////////
    // PDF作成処理Start
    // /////////////////
    OracleCallableStatement stmt      = null;
    NUMBER                  requestId = null;

    // コンカレントの実行
    try
    {
      StringBuffer sql = new StringBuffer(100);
      sql.append("BEGIN");
      sql.append("  :1 := fnd_request.submit_request(");
      sql.append("         application       => 'XXCSO'");
      sql.append("        ,program           => 'XXCSO010A04C'");
      sql.append("        ,description       => NULL");
      sql.append("        ,start_time        => NULL");
      sql.append("        ,sub_request       => FALSE");
      sql.append("        ,argument1         => :2");
      sql.append("       );");
      sql.append("END;");

      stmt
        = (OracleCallableStatement)
            txn.createCallableStatement(sql.toString(), 0);

      stmt.registerOutParameter(1, OracleTypes.NUMBER);
      stmt.setString(2, mngRow.getContractManagementId().stringValue());

      stmt.execute();

      requestId = stmt.getNUMBER(1);
    }
    catch ( SQLException e )
    {
      XxcsoUtils.unexpected(txn, e);
      throw
        XxcsoMessage.createSqlErrorMessage(
          e
         ,XxcsoContractRegistConstants.TOKEN_VALUE_PDF_OUT
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

    // コンカレントのリクエストIDよりエラーメッセージの取得
    if ( NUMBER.zero().equals(requestId) )
    {
      try
      {
        StringBuffer sql = new StringBuffer(50);
        sql.append("BEGIN fnd_message.retrieve(:1); END;");

        stmt
          = (OracleCallableStatement)
              txn.createCallableStatement(sql.toString(), 0);

        stmt.registerOutParameter(1, OracleTypes.VARCHAR);

        stmt.execute();

        String errmsg = stmt.getString(1);

        throw
          XxcsoMessage.createErrorMessage(
            XxcsoConstants.APP_XXCSO1_00310
           ,XxcsoConstants.TOKEN_CONC
           ,XxcsoContractRegistConstants.TOKEN_VALUE_PDF_OUT
           ,XxcsoConstants.TOKEN_CONCMSG
           ,errmsg
          );
      }
      catch ( SQLException e )
      {
        XxcsoUtils.unexpected(txn, e);
        throw
          XxcsoMessage.createSqlErrorMessage(
            e
           ,XxcsoContractRegistConstants.TOKEN_VALUE_PDF_OUT
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

    this.commit();

    // APP_XXCSO1_00001のrecordに設定する文言
    StringBuffer sbRecord = new StringBuffer();
    sbRecord.append( XxcsoConstants.TOKEN_VALUE_CONTRACT_REGIST );
    sbRecord.append( XxcsoContractRegistConstants.TOKEN_VALUE_PDF_OUT );
    sbRecord.append( XxcsoConstants.TOKEN_VALUE_SEP_LEFT );
    sbRecord.append( XxcsoConstants.TOKEN_VALUE_REQUEST_ID );
    sbRecord.append( requestId.stringValue() );
    sbRecord.append( XxcsoConstants.TOKEN_VALUE_SEP_RIGHT );

    // 正常終了メッセージ
    OAException msg
      = XxcsoMessage.createConfirmMessage(
          XxcsoConstants.APP_XXCSO1_00001
         ,XxcsoConstants.TOKEN_RECORD
         ,new String( sbRecord )
         ,XxcsoConstants.TOKEN_ACTION
         ,XxcsoContractRegistConstants.TOKEN_VALUE_START
        );

    // URLパラメータ用Map
    HashMap params = new HashMap(3);
    params.put(
      XxcsoConstants.EXECUTE_MODE
     ,XxcsoContractRegistConstants.MODE_UPDATE
    );
    params.put(
      XxcsoConstants.TRANSACTION_KEY1
     ,mngRow.getSpDecisionHeaderId().toString()
    );
    params.put(
      XxcsoConstants.TRANSACTION_KEY2
     ,mngRow.getContractManagementId().toString()
    );

    // AM戻り値用Mapへの設定
    HashMap returnMap = new HashMap(2);
    returnMap.put(
      XxcsoContractRegistConstants.PARAM_URL_PARAM
     ,params
    );
    returnMap.put(
      XxcsoContractRegistConstants.PARAM_MESSAGE
     ,msg
    );

    XxcsoUtils.debug(txn, "[END]");

    return returnMap;

  }

  /*****************************************************************************
   * 確認ダイアログOKボタン押下時処理
   * （ダイアログ未出力時も登録処理としてCallされる）
   * @param   actionValue 保存or確定の文字列
   * @return  HashMap     再表示用情報格納Map
   *****************************************************************************
   */
  public HashMap handleConfirmOkButton(String actionValue)
  {
    OADBTransaction txn = getOADBTransaction();
    XxcsoUtils.debug(txn, "[START]");

    XxcsoContractManagementFullVOImpl mngVo
      = getXxcsoContractManagementFullVO1();
    if ( mngVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoContractManagementFullVO1");
    }

    XxcsoContractManagementFullVORowImpl mngRow
      = (XxcsoContractManagementFullVORowImpl) mngVo.first();

// 2010-02-09 [E_本稼動_01538] Mod Start
    /////////////////////////////////////
    // 検証処理：ＤＢ値検証
    /////////////////////////////////////
    OAException oaeMsg = null;

    oaeMsg
      = XxcsoContractRegistValidateUtils.validateDb(
          txn
         ,mngVo
        );
    if (oaeMsg != null)
    {
      throw oaeMsg;
    }
// 2010-02-09 [E_本稼動_01538] Mod End
    // 確定ボタン押下の場合
    if ( XxcsoConstants.TOKEN_VALUE_DECISION.equals(actionValue) )
    {
      // ステータス
      mngRow.setStatus(XxcsoContractRegistConstants.STS_FIX);
      // マスタ連携フラグ
      mngRow.setCooperateFlag(XxcsoContractRegistConstants.COOPERATE_NONE);
    }
    // 適用ボタン押下の場合
    else
    {
      // ステータス
      mngRow.setStatus(XxcsoContractRegistConstants.STS_INPUT);
    }

    this.commit();

    // 正常終了メッセージ
    OAException msg
      = XxcsoMessage.createConfirmMessage(
          XxcsoConstants.APP_XXCSO1_00001
         ,XxcsoConstants.TOKEN_RECORD
         ,XxcsoConstants.TOKEN_VALUE_CONTRACT_REGIST
         ,XxcsoConstants.TOKEN_ACTION
         ,actionValue
        );


    // URLパラメータ用Map
    HashMap params = new HashMap(3);
    params.put(
      XxcsoConstants.EXECUTE_MODE
     ,XxcsoContractRegistConstants.MODE_UPDATE
    );
    params.put(
      XxcsoConstants.TRANSACTION_KEY1
     ,mngRow.getSpDecisionHeaderId().toString()
    );
    params.put(
      XxcsoConstants.TRANSACTION_KEY2
     ,mngRow.getContractManagementId().toString()
    );

    // AM戻り値用Mapへの設定
    HashMap returnMap = new HashMap(2);
    returnMap.put(
      XxcsoContractRegistConstants.PARAM_URL_PARAM
     ,params
    );
    returnMap.put(
      XxcsoContractRegistConstants.PARAM_MESSAGE
     ,msg
    );

    XxcsoUtils.debug(txn, "[END]");

    return returnMap;
  }

  /*****************************************************************************
   * オーナー変更チェックボックス変更処理
   *****************************************************************************
   */
  public void handleOwnerChangeFlagChange()
  {
    // インスタンス取得
    XxcsoPageRenderVOImpl pageRenderVo = getXxcsoPageRenderVO1();
    if ( pageRenderVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoPageRenderVOImpl");
    }

    XxcsoContractManagementFullVOImpl mngVo
      = getXxcsoContractManagementFullVO1();
    if ( mngVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoContractManagementFullVO1");
    }

    // 画面属性設定
    XxcsoContractRegistPropertyUtils.setAttributeOwnerChange(pageRenderVo);

    // 画面項目内用設定
    XxcsoContractRegistReflectUtils.reflectInstallInfo(
      pageRenderVo
     ,mngVo
    );
  }

  /*****************************************************************************
   * 各イベント処理の最後に行われる処理です。
   *****************************************************************************
   */
  public void afterProcess()
  {
    OADBTransaction txn = getOADBTransaction();
    
    XxcsoUtils.debug(txn, "[START]");

    XxcsoBm1DestinationFullVOImpl dest1Vo
      = getXxcsoBm1DestinationFullVO1();
    if ( dest1Vo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoBm1DestinationFullVO1"
        );
    }

    XxcsoBm2DestinationFullVOImpl dest2Vo
      = getXxcsoBm2DestinationFullVO1();
    if ( dest2Vo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoBm2DestinationFullVO1"
        );
    }

    XxcsoBm3DestinationFullVOImpl dest3Vo
      = getXxcsoBm3DestinationFullVO1();
    if ( dest3Vo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoBm3DestinationFullVO1"
        );
    }

    ////////////////////////////////////
    // 仕入先マスタ使用フラグを設定
    ////////////////////////////////////
    XxcsoBm1DestinationFullVORowImpl dest1Row
      = (XxcsoBm1DestinationFullVORowImpl)dest1Vo.first();
    XxcsoBm2DestinationFullVORowImpl dest2Row
      = (XxcsoBm2DestinationFullVORowImpl)dest2Vo.first();
    XxcsoBm3DestinationFullVORowImpl dest3Row
      = (XxcsoBm3DestinationFullVORowImpl)dest3Vo.first();

    if ( dest1Row != null )
    {
      if ( dest1Row.getSupplierId() != null )
      {
        dest1Row.setVendorFlag("Y");
      }
      else
      {
        dest1Row.setVendorFlag("N");
      }
    }

    if ( dest2Row != null )
    {
      if ( dest2Row.getSupplierId() != null )
      {
        dest2Row.setVendorFlag("Y");
      }
      else
      {
        dest2Row.setVendorFlag("N");
      }
    }

    if ( dest3Row != null )
    {
      if ( dest3Row.getSupplierId() != null )
      {
        dest3Row.setVendorFlag("Y");
      }
      else
      {
        dest3Row.setVendorFlag("N");
      }
    }

    XxcsoUtils.debug(txn, "[END]");
  }


  /*****************************************************************************
   * メッセージを取得します。
   * @return mMessage
   *****************************************************************************
   */
  public OAException getMessage()
  {
    return mMessage;
  }

  /*****************************************************************************
   * 全リージョンの値検証
   * @param fixedFlag 確定ボタン押下フラグ
   *****************************************************************************
   */
  private void validateAll(
    boolean fixedFlag
  )
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");
    
    List errorList = new ArrayList();

    // インスタンス取得
    XxcsoPageRenderVOImpl pageRenderVo = getXxcsoPageRenderVO1();
    if ( pageRenderVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoPageRenderVOImpl");
    }

    XxcsoContractManagementFullVOImpl mngVo
      = getXxcsoContractManagementFullVO1();
    if ( mngVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoContractManagementFullVO1");
    }

    XxcsoContractCustomerFullVOImpl cntrctVo
      = getXxcsoContractCustomerFullVO1();
    if ( cntrctVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoContractCustomerFullVO1");
    }

    XxcsoBm1DestinationFullVOImpl dest1Vo
      = getXxcsoBm1DestinationFullVO1();
    if ( dest1Vo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoBm1DestinationFullVO1");
    }

    XxcsoBm2DestinationFullVOImpl dest2Vo
      = getXxcsoBm2DestinationFullVO1();
    if ( dest2Vo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoBm2DestinationFullVO1");
    }

    XxcsoBm3DestinationFullVOImpl dest3Vo
      = getXxcsoBm3DestinationFullVO1();
    if ( dest3Vo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoBm3DestinationFullVO1");
    }

    XxcsoBm1BankAccountFullVOImpl bank1Vo
      = getXxcsoBm1BankAccountFullVO1();
    if ( bank1Vo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoBm1BankAccountFullVO1");
    }

    XxcsoBm2BankAccountFullVOImpl bank2Vo
      = getXxcsoBm2BankAccountFullVO1();
    if ( bank2Vo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoBm2BankAccountFullVO1");
    }

    XxcsoBm3BankAccountFullVOImpl bank3Vo
      = getXxcsoBm3BankAccountFullVO1();
    if ( bank3Vo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoBm3BankAccountFullVO1");
    }

    XxcsoBm1ContractSpCustFullVOImpl spCust1Vo
      = getXxcsoBm1ContractSpCustFullVO1();
    if ( spCust1Vo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoBm1ContractSpCustFullVO1");
    }

    XxcsoBm2ContractSpCustFullVOImpl spCust2Vo
      = getXxcsoBm2ContractSpCustFullVO1();
    if ( spCust2Vo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoBm2ContractSpCustFullVO1");
    }

    XxcsoBm3ContractSpCustFullVOImpl spCust3Vo
      = getXxcsoBm3ContractSpCustFullVO1();
    if ( spCust3Vo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoBm3ContractSpCustFullVO1");
    }

    /////////////////////////////////////
    // 検証処理：契約者（甲）情報
    /////////////////////////////////////
    errorList.addAll(
      XxcsoContractRegistValidateUtils.validateContractCustomer(
        txn
       ,mngVo
       ,cntrctVo
       ,fixedFlag
      )
    );

    /////////////////////////////////////
    // 検証処理：振込日・締め日情報
    /////////////////////////////////////
    errorList.addAll(
      XxcsoContractRegistValidateUtils.validateContractTransfer(
        txn
       ,pageRenderVo
       ,mngVo
       ,fixedFlag
      )
    );

    /////////////////////////////////////
    // 検証処理：契約期間・途中解除情報
    /////////////////////////////////////
    errorList.addAll(
      XxcsoContractRegistValidateUtils.validateCancellationOffer(
        txn
       ,mngVo
       ,fixedFlag
      )
    );

    /////////////////////////////////////
    // 検証処理：ＢＭ１指定情報
    /////////////////////////////////////
    errorList.addAll(
      XxcsoContractRegistValidateUtils.validateBm1Dest(
        txn
       ,pageRenderVo
       ,dest1Vo
       ,bank1Vo
       ,fixedFlag
      )
    );

    /////////////////////////////////////
    // 検証処理：ＢＭ２指定情報
    /////////////////////////////////////
    errorList.addAll(
      XxcsoContractRegistValidateUtils.validateBm2Dest(
        txn
       ,pageRenderVo
       ,dest2Vo
       ,bank2Vo
       ,fixedFlag
      )
    );

    /////////////////////////////////////
    // 検証処理：ＢＭ３指定情報
    /////////////////////////////////////
    errorList.addAll(
      XxcsoContractRegistValidateUtils.validateBm3Dest(
        txn
       ,pageRenderVo
       ,dest3Vo
       ,bank3Vo
       ,fixedFlag
      )
    );

    /////////////////////////////////////
    // 検証処理：設置先情報
    /////////////////////////////////////
    errorList.addAll(
      XxcsoContractRegistValidateUtils.validateContractInstall(
        txn
       ,pageRenderVo
       ,mngVo
       ,fixedFlag
      )
    );

    /////////////////////////////////////
    // 検証処理：発行元所属情報
    /////////////////////////////////////
    errorList.addAll(
      XxcsoContractRegistValidateUtils.validatePublishBase(
        txn
       ,mngVo
       ,fixedFlag
      )
    );

    if ( errorList.size() > 0 )
    {
      OAException.raiseBundledOAException(errorList);
    }

    OAException oaeMsg = null;

    /////////////////////////////////////
    // 検証処理：設置日AR会計期間チェック
    /////////////////////////////////////
    oaeMsg
      = XxcsoContractRegistValidateUtils.validateInstallDate(
          txn
         ,pageRenderVo
         ,mngVo
         ,fixedFlag
        );

    if (oaeMsg != null)
    {
      throw oaeMsg;
    }

    /////////////////////////////////////
    // 検証処理：BM相関チェック
    /////////////////////////////////////
    oaeMsg
      = XxcsoContractRegistValidateUtils.validateBmRelation(
          txn
         ,pageRenderVo
         ,mngVo
         ,dest1Vo
         ,bank1Vo
         ,dest2Vo
         ,bank2Vo
         ,dest3Vo
         ,bank3Vo
// 2009-04-08 [ST障害T1_0364] Add Start
         ,fixedFlag
// 2009-04-08 [ST障害T1_0364] Add End
        );
    if (oaeMsg != null)
    {
      throw oaeMsg;
    }

    /////////////////////////////////////
    // 検証処理：支払明細書整合性チェック
    /////////////////////////////////////
    oaeMsg
      = XxcsoContractRegistValidateUtils.validateBellingDetailsCompliance(
          txn
         ,pageRenderVo
         ,mngVo
         ,dest1Vo
         ,dest2Vo
         ,dest3Vo
         ,fixedFlag
        );
    if (oaeMsg != null)
    {
      throw oaeMsg;
    }

    XxcsoUtils.debug(txn, "[END]");
  }

  /*****************************************************************************
   * BM関連顧客チェック（AM内チェック）
   * @return OAException 
   *****************************************************************************
   */
  private OAException validateBmAccountInfo()
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    OAException confirmMsg = null;

    // 画面インスタンス取得
    XxcsoContractManagementFullVOImpl mngVo
      = getXxcsoContractManagementFullVO1();
    if ( mngVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoContractManagementFullVO1");
    }

    XxcsoBm1DestinationFullVOImpl dest1Vo
      = getXxcsoBm1DestinationFullVO1();
    if ( dest1Vo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoBm1DestinationFullVO1");
    }

    XxcsoBm2DestinationFullVOImpl dest2Vo
      = getXxcsoBm2DestinationFullVO1();
    if ( dest2Vo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoBm2DestinationFullVO1");
    }

    XxcsoBm3DestinationFullVOImpl dest3Vo
      = getXxcsoBm3DestinationFullVO1();
    if ( dest3Vo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoBm3DestinationFullVO1");
    }
    // 画面行インスタンス取得
    XxcsoContractManagementFullVORowImpl mngRow
      = (XxcsoContractManagementFullVORowImpl) mngVo.first();

    XxcsoBm1DestinationFullVORowImpl bm1DestVoRow
      = (XxcsoBm1DestinationFullVORowImpl) dest1Vo.first();

    XxcsoBm2DestinationFullVORowImpl bm2DestVoRow
      = (XxcsoBm2DestinationFullVORowImpl) dest2Vo.first();

    XxcsoBm3DestinationFullVORowImpl bm3DestVoRow
      = (XxcsoBm3DestinationFullVORowImpl) dest3Vo.first();

    String bm1VendorCode = null;
    String bm2VendorCode = null;
    String bm3VendorCode = null;

    if ( bm1DestVoRow != null )
    {
      bm1VendorCode = bm1DestVoRow.getVendorCode();
    }
    if ( bm2DestVoRow != null )
    {
      bm2VendorCode = bm2DestVoRow.getVendorCode();
    }
    if ( bm3DestVoRow != null )
    {
      bm3VendorCode = bm3DestVoRow.getVendorCode();
    }

    // 検証用VOの初期化
    XxcsoBmAccountInfoSummaryVOImpl bmAccVo = getXxcsoBmAccountInfoSummaryVO1();
    if ( bmAccVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoBmAccountInfoSummaryVOImpl");
    }
    bmAccVo.initQuery(
      bm1VendorCode
     ,bm2VendorCode
     ,bm3VendorCode
     ,mngRow.getInstallAccountId()
    );

    XxcsoBmAccountInfoSummaryVORowImpl bmAccVoRow
      = (XxcsoBmAccountInfoSummaryVORowImpl) bmAccVo.first();
    if ( bmAccVoRow == null )
    {
      return confirmMsg;
    }

    int rowCnt = 0;
    StringBuffer sbMsg = new StringBuffer();
    while ( bmAccVoRow != null )
    {
      if (rowCnt != 0)
      {
        sbMsg.append(XxcsoConstants.TOKEN_VALUE_DELIMITER2);
      }
      // 「顧客コード：顧客名」でエラー用のメッセージを生成
      sbMsg.append(bmAccVoRow.getAccountNumber());
      sbMsg.append(XxcsoConstants.TOKEN_VALUE_DELIMITER3);
      sbMsg.append(bmAccVoRow.getPartyName());
      rowCnt++;
      bmAccVoRow = (XxcsoBmAccountInfoSummaryVORowImpl) bmAccVo.next();
    }

    confirmMsg
      = XxcsoMessage.createConfirmMessage(
          XxcsoConstants.APP_XXCSO1_00453
         ,XxcsoConstants.TOKEN_ACCOUNTS
         ,new String(sbMsg)
        );

    XxcsoUtils.debug(txn, "[END]");

    return confirmMsg;
  }

  /*****************************************************************************
   * コミット処理です。
   *****************************************************************************
   */
  private void commit()
  {
    OADBTransaction txn = getOADBTransaction();
    XxcsoUtils.debug(txn, "[START]");

    getTransaction().commit();

    XxcsoUtils.debug(txn, "[END]");
  }

  /*****************************************************************************
   * ロールバック処理です。
   *****************************************************************************
   */
  private void rollback()
  {
    OADBTransaction txn = getOADBTransaction();
    XxcsoUtils.debug(txn, "[START]");

    if ( getTransaction().isDirty() )
    {
      getTransaction().rollback();
    }

    XxcsoUtils.debug(txn, "[END]");
  }
// 2010-02-09 [E_本稼動_01538] Mod Start
  /*****************************************************************************
   * マスタ連携待ちチェック処理です。
   *****************************************************************************
   */
  public void cooperateWaitCheck()
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    mMessage = this.cooperateWaitInfo();

    XxcsoUtils.debug(txn, "[END]");
  }
  /*****************************************************************************
   * マスタ連携待ちチェック
   * @return OAException 
   *****************************************************************************
   */
  private OAException cooperateWaitInfo()
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    OAException confirmMsg = null;

    // 画面インスタンス取得
    XxcsoContractManagementFullVOImpl mngVo
      = getXxcsoContractManagementFullVO1();
    if ( mngVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoContractManagementFullVO1");
    }
    // 画面行インスタンス取得
    XxcsoContractManagementFullVORowImpl mngRow
      = (XxcsoContractManagementFullVORowImpl) mngVo.first();

    OracleCallableStatement stmt = null;

    // マスタ連携待ちチェック
    String ContractNumber = null;

    try
    {
      StringBuffer sql = new StringBuffer(300);
      sql.append("BEGIN");
      sql.append("  :1 := xxcso_010003j_pkg.chk_cooperate_wait(");
      sql.append("        iv_account_number    => :2");
      sql.append("        );");
      sql.append("END;");

      stmt
        = (OracleCallableStatement)
            txn.createCallableStatement(sql.toString(), 0);

      stmt.registerOutParameter(1, OracleTypes.VARCHAR);
      stmt.setString(2, mngRow.getInstallAccountNumber());

      stmt.execute();

      ContractNumber = stmt.getString(1);
    }
    catch ( SQLException e )
    {
      XxcsoUtils.unexpected(txn, e);
      throw
        XxcsoMessage.createSqlErrorMessage(
          e
         ,XxcsoContractRegistConstants.TOKEN_VALUE_COOPERATE_WAIT_INFO_CHK
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

    if (!(ContractNumber == null || "".equals(ContractNumber)))
    {
      confirmMsg
        = XxcsoMessage.createErrorMessage(
            XxcsoConstants.APP_XXCSO1_00595
           ,XxcsoConstants.TOKEN_RECORD
           ,ContractNumber
          );
    }

    XxcsoUtils.debug(txn, "[END]");

    return confirmMsg;
  }
// 2010-02-09 [E_本稼動_01538] Mod End
  /**
   * 
   * Container's getter for XxcsoContractManagementFullVO1
   */
  public XxcsoContractManagementFullVOImpl getXxcsoContractManagementFullVO1()
  {
    return (XxcsoContractManagementFullVOImpl)findViewObject("XxcsoContractManagementFullVO1");
  }

  /**
   * 
   * Container's getter for XxcsoBm1DestinationFullVO1
   */
  public XxcsoBm1DestinationFullVOImpl getXxcsoBm1DestinationFullVO1()
  {
    return (XxcsoBm1DestinationFullVOImpl)findViewObject("XxcsoBm1DestinationFullVO1");
  }

  /**
   * 
   * Container's getter for XxcsoBm2DestinationFullVO1
   */
  public XxcsoBm2DestinationFullVOImpl getXxcsoBm2DestinationFullVO1()
  {
    return (XxcsoBm2DestinationFullVOImpl)findViewObject("XxcsoBm2DestinationFullVO1");
  }

  /**
   * 
   * Container's getter for XxcsoBm3DestinationFullVO1
   */
  public XxcsoBm3DestinationFullVOImpl getXxcsoBm3DestinationFullVO1()
  {
    return (XxcsoBm3DestinationFullVOImpl)findViewObject("XxcsoBm3DestinationFullVO1");
  }

  /**
   * 
   * Container's getter for XxcsoContractCustomerFullVO1
   */
  public XxcsoContractCustomerFullVOImpl getXxcsoContractCustomerFullVO1()
  {
    return (XxcsoContractCustomerFullVOImpl)findViewObject("XxcsoContractCustomerFullVO1");
  }

  /**
   * 
   * Container's getter for XxcsoBm1ContractSpCustFullVO1
   */
  public XxcsoBm1ContractSpCustFullVOImpl getXxcsoBm1ContractSpCustFullVO1()
  {
    return (XxcsoBm1ContractSpCustFullVOImpl)findViewObject("XxcsoBm1ContractSpCustFullVO1");
  }

  /**
   * 
   * Container's getter for XxcsoBm1BankAccountFullVO1
   */
  public XxcsoBm1BankAccountFullVOImpl getXxcsoBm1BankAccountFullVO1()
  {
    return (XxcsoBm1BankAccountFullVOImpl)findViewObject("XxcsoBm1BankAccountFullVO1");
  }

  /**
   * 
   * Container's getter for XxcsoBm2BankAccountFullVO1
   */
  public XxcsoBm2BankAccountFullVOImpl getXxcsoBm2BankAccountFullVO1()
  {
    return (XxcsoBm2BankAccountFullVOImpl)findViewObject("XxcsoBm2BankAccountFullVO1");
  }

  /**
   * 
   * Container's getter for XxcsoBm3BankAccountFullVO1
   */
  public XxcsoBm3BankAccountFullVOImpl getXxcsoBm3BankAccountFullVO1()
  {
    return (XxcsoBm3BankAccountFullVOImpl)findViewObject("XxcsoBm3BankAccountFullVO1");
  }

  /**
   * 
   * Container's getter for XxcsoContractMngBm1DestVL1
   */
  public ViewLinkImpl getXxcsoContractMngBm1DestVL1()
  {
    return (ViewLinkImpl)findViewLink("XxcsoContractMngBm1DestVL1");
  }

  /**
   * 
   * Container's getter for XxcsoContractMngBm2DestVL1
   */
  public ViewLinkImpl getXxcsoContractMngBm2DestVL1()
  {
    return (ViewLinkImpl)findViewLink("XxcsoContractMngBm2DestVL1");
  }

  /**
   * 
   * Container's getter for XxcsoContractMngBm3DestVL1
   */
  public ViewLinkImpl getXxcsoContractMngBm3DestVL1()
  {
    return (ViewLinkImpl)findViewLink("XxcsoContractMngBm3DestVL1");
  }

  /**
   * 
   * Container's getter for XxcsoBm1DestBankVL1
   */
  public ViewLinkImpl getXxcsoBm1DestBankVL1()
  {
    return (ViewLinkImpl)findViewLink("XxcsoBm1DestBankVL1");
  }

  /**
   * 
   * Container's getter for XxcsoBm2DestBankVL1
   */
  public ViewLinkImpl getXxcsoBm2DestBankVL1()
  {
    return (ViewLinkImpl)findViewLink("XxcsoBm2DestBankVL1");
  }

  /**
   * 
   * Container's getter for XxcsoBm3DestBankVL1
   */
  public ViewLinkImpl getXxcsoBm3DestBankVL1()
  {
    return (ViewLinkImpl)findViewLink("XxcsoBm3DestBankVL1");
  }

  /**
   * 
   * Sample main for debugging Business Components code using the tester.
   */
  public static void main(String[] args)
  {
    launchTester("itoen.oracle.apps.xxcso.xxcso010003j.server", "XxcsoContractRegistAMLocal");
  }

  /**
   * 
   * Container's getter for XxcsoContractCreateInitVO1
   */
  public XxcsoContractCreateInitVOImpl getXxcsoContractCreateInitVO1()
  {
    return (XxcsoContractCreateInitVOImpl)findViewObject("XxcsoContractCreateInitVO1");
  }

  /**
   * 
   * Container's getter for XxcsoInitBmInfoSummaryVO1
   */
  public XxcsoInitBmInfoSummaryVOImpl getXxcsoInitBmInfoSummaryVO1()
  {
    return (XxcsoInitBmInfoSummaryVOImpl)findViewObject("XxcsoInitBmInfoSummaryVO1");
  }

  /**
   * 
   * Container's getter for XxcsoLoginUserSummaryVO1
   */
  public XxcsoLoginUserSummaryVOImpl getXxcsoLoginUserSummaryVO1()
  {
    return (XxcsoLoginUserSummaryVOImpl)findViewObject("XxcsoLoginUserSummaryVO1");
  }

  /**
   * 
   * Container's getter for XxcsoBm2ContractSpCustFullVO1
   */
  public XxcsoBm2ContractSpCustFullVOImpl getXxcsoBm2ContractSpCustFullVO1()
  {
    return (XxcsoBm2ContractSpCustFullVOImpl)findViewObject("XxcsoBm2ContractSpCustFullVO1");
  }

  /**
   * 
   * Container's getter for XxcsoBm3ContractSpCustFullVO1
   */
  public XxcsoBm3ContractSpCustFullVOImpl getXxcsoBm3ContractSpCustFullVO1()
  {
    return (XxcsoBm3ContractSpCustFullVOImpl)findViewObject("XxcsoBm3ContractSpCustFullVO1");
  }

  /**
   * 
   * Container's getter for XxcsoSalesCondSummaryVO1
   */
  public XxcsoSalesCondSummaryVOImpl getXxcsoSalesCondSummaryVO1()
  {
    return (XxcsoSalesCondSummaryVOImpl)findViewObject("XxcsoSalesCondSummaryVO1");
  }

  /**
   * 
   * Container's getter for XxcsoContainerCondSummaryVO1
   */
  public XxcsoContainerCondSummaryVOImpl getXxcsoContainerCondSummaryVO1()
  {
    return (XxcsoContainerCondSummaryVOImpl)findViewObject("XxcsoContainerCondSummaryVO1");
  }

  /**
   * 
   * Container's getter for XxcsoContractFormatListVO
   */
  public XxcsoLookupListVOImpl getXxcsoContractFormatListVO()
  {
    return (XxcsoLookupListVOImpl)findViewObject("XxcsoContractFormatListVO");
  }

  /**
   * 
   * Container's getter for XxcsoContractStatusListVO
   */
  public XxcsoLookupListVOImpl getXxcsoContractStatusListVO()
  {
    return (XxcsoLookupListVOImpl)findViewObject("XxcsoContractStatusListVO");
  }

  /**
   * 
   * Container's getter for XxcsoDaysListVO
   */
  public XxcsoLookupListVOImpl getXxcsoDaysListVO()
  {
    return (XxcsoLookupListVOImpl)findViewObject("XxcsoDaysListVO");
  }

  /**
   * 
   * Container's getter for XxcsoMonthsListVO
   */
  public XxcsoLookupListVOImpl getXxcsoMonthsListVO()
  {
    return (XxcsoLookupListVOImpl)findViewObject("XxcsoMonthsListVO");
  }

  /**
   * 
   * Container's getter for XxcsoCancellationListVO
   */
  public XxcsoLookupListVOImpl getXxcsoCancellationListVO()
  {
    return (XxcsoLookupListVOImpl)findViewObject("XxcsoCancellationListVO");
  }

  /**
   * 
   * Container's getter for XxcsoTransferFeeListVO
   */
  public XxcsoLookupListVOImpl getXxcsoTransferFeeListVO()
  {
    return (XxcsoLookupListVOImpl)findViewObject("XxcsoTransferFeeListVO");
  }

  /**
   * 
   * Container's getter for XxcsoBmPaymentListVO
   */
  public XxcsoLookupListVOImpl getXxcsoBmPaymentListVO()
  {
    return (XxcsoLookupListVOImpl)findViewObject("XxcsoBmPaymentListVO");
  }

  /**
   * 
   * Container's getter for XxcsoKozaListVO
   */
  public XxcsoLookupListVOImpl getXxcsoKozaListVO()
  {
    return (XxcsoLookupListVOImpl)findViewObject("XxcsoKozaListVO");
  }

  /**
   * 
   * Container's getter for XxcsoPageRenderVO1
   */
  public XxcsoPageRenderVOImpl getXxcsoPageRenderVO1()
  {
    return (XxcsoPageRenderVOImpl)findViewObject("XxcsoPageRenderVO1");
  }


  /**
   * 
   * Container's getter for XxcsoContractManagementFullVO2
   */
  public XxcsoContractManagementFullVOImpl getXxcsoContractManagementFullVO2()
  {
    return (XxcsoContractManagementFullVOImpl)findViewObject("XxcsoContractManagementFullVO2");
  }

  /**
   * 
   * Container's getter for XxcsoBm1DestinationFullVO2
   */
  public XxcsoBm1DestinationFullVOImpl getXxcsoBm1DestinationFullVO2()
  {
    return (XxcsoBm1DestinationFullVOImpl)findViewObject("XxcsoBm1DestinationFullVO2");
  }

  /**
   * 
   * Container's getter for XxcsoBm2DestinationFullVO2
   */
  public XxcsoBm2DestinationFullVOImpl getXxcsoBm2DestinationFullVO2()
  {
    return (XxcsoBm2DestinationFullVOImpl)findViewObject("XxcsoBm2DestinationFullVO2");
  }

  /**
   * 
   * Container's getter for XxcsoBm3DestinationFullVO2
   */
  public XxcsoBm3DestinationFullVOImpl getXxcsoBm3DestinationFullVO2()
  {
    return (XxcsoBm3DestinationFullVOImpl)findViewObject("XxcsoBm3DestinationFullVO2");
  }

  /**
   * 
   * Container's getter for XxcsoBm1BankAccountFullVO2
   */
  public XxcsoBm1BankAccountFullVOImpl getXxcsoBm1BankAccountFullVO2()
  {
    return (XxcsoBm1BankAccountFullVOImpl)findViewObject("XxcsoBm1BankAccountFullVO2");
  }

  /**
   * 
   * Container's getter for XxcsoBm2BankAccountFullVO2
   */
  public XxcsoBm2BankAccountFullVOImpl getXxcsoBm2BankAccountFullVO2()
  {
    return (XxcsoBm2BankAccountFullVOImpl)findViewObject("XxcsoBm2BankAccountFullVO2");
  }

  /**
   * 
   * Container's getter for XxcsoBm3BankAccountFullVO2
   */
  public XxcsoBm3BankAccountFullVOImpl getXxcsoBm3BankAccountFullVO2()
  {
    return (XxcsoBm3BankAccountFullVOImpl)findViewObject("XxcsoBm3BankAccountFullVO2");
  }

  /**
   * 
   * Container's getter for XxcsoContractCustomerFullVO2
   */
  public XxcsoContractCustomerFullVOImpl getXxcsoContractCustomerFullVO2()
  {
    return (XxcsoContractCustomerFullVOImpl)findViewObject("XxcsoContractCustomerFullVO2");
  }




  /**
   * 
   * Container's getter for XxcsoContractMngBm1DestVL2
   */
  public ViewLinkImpl getXxcsoContractMngBm1DestVL2()
  {
    return (ViewLinkImpl)findViewLink("XxcsoContractMngBm1DestVL2");
  }

  /**
   * 
   * Container's getter for XxcsoContractMngBm2DestVL2
   */
  public ViewLinkImpl getXxcsoContractMngBm2DestVL2()
  {
    return (ViewLinkImpl)findViewLink("XxcsoContractMngBm2DestVL2");
  }

  /**
   * 
   * Container's getter for XxcsoContractMngBm3DestVL2
   */
  public ViewLinkImpl getXxcsoContractMngBm3DestVL2()
  {
    return (ViewLinkImpl)findViewLink("XxcsoContractMngBm3DestVL2");
  }

  /**
   * 
   * Container's getter for XxcsoBm1DestBankVL2
   */
  public ViewLinkImpl getXxcsoBm1DestBankVL2()
  {
    return (ViewLinkImpl)findViewLink("XxcsoBm1DestBankVL2");
  }

  /**
   * 
   * Container's getter for XxcsoBm2DestBankVL2
   */
  public ViewLinkImpl getXxcsoBm2DestBankVL2()
  {
    return (ViewLinkImpl)findViewLink("XxcsoBm2DestBankVL2");
  }

  /**
   * 
   * Container's getter for XxcsoBm3DestBankVL2
   */
  public ViewLinkImpl getXxcsoBm3DestBankVL2()
  {
    return (ViewLinkImpl)findViewLink("XxcsoBm3DestBankVL2");
  }

  /**
   * 
   * Container's getter for XxcsoBmAccountInfoSummaryVO1
   */
  public XxcsoBmAccountInfoSummaryVOImpl getXxcsoBmAccountInfoSummaryVO1()
  {
    return (XxcsoBmAccountInfoSummaryVOImpl)findViewObject("XxcsoBmAccountInfoSummaryVO1");
  }

  /**
   * 
   * Container's getter for XxcsoLoginUserAuthorityVO1
   */
  public XxcsoLoginUserAuthorityVOImpl getXxcsoLoginUserAuthorityVO1()
  {
    return (XxcsoLoginUserAuthorityVOImpl)findViewObject("XxcsoLoginUserAuthorityVO1");
  }


}