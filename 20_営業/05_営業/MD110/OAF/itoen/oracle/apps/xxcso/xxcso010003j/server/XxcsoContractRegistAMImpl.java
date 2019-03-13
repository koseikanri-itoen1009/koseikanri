/*==============================================================================
* ファイル名 : XxcsoContractRegistAMImpl
* 概要説明   : 自販機設置契約情報登録画面アプリケーション・モジュールクラス
* バージョン : 2.2
*==============================================================================
* 修正履歴
* 日付       Ver. 担当者         修正内容
* ---------- ---- -------------- ----------------------------------------------
* 2009-01-27 1.0  SCS小川浩      新規作成
* 2009-02-16 1.1  SCS柳平直人    [CT1-008]BM指定チェックボックス不正対応
* 2009-02-23 1.1  SCS柳平直人    [CT1-021]送付先コード取得不正対応
*                                [CT1-022]口座情報取得不正対応
* 2009-04-08 1.2  SCS柳平直人    [ST障害T1_0364]仕入先重複チェック修正対応
* 2010-01-26 1.3  SCS阿部大輔    [E_本稼動_01314]契約書発効日必須対応
* 2010-01-20 1.4  SCS阿部大輔    [E_本稼動_01176]口座種別対応
* 2010-02-09 1.5  SCS阿部大輔    [E_本稼動_01538]契約書の複数確定対応
* 2010-03-01 1.6  SCS阿部大輔    [E_本稼動_01678]現金支払対応
* 2011-06-06 1.7  SCS桐生和幸    [E_本稼動_01963]新規仕入先作成チェック対応
* 2012-06-12 1.8  SCS桐生和幸    [E_本稼動_09602]契約取消ボタン追加対応
* 2013-04-01 1.9  SCSK桐生和幸   [E_本稼動_10413]銀行口座マスタ変更チェック追加対応
* 2015-02-09 2.0  SCSK山下翔太   [E_本稼動_12565]SP専決・契約書画面改修
* 2016-01-06 2.1  SCSK桐生和幸   [E_本稼動_13456]自販機管理システム代替対応
* 2019-02-19 2.2  SCSK佐々木大和 [E_本稼動_15349]仕入先CD制御対応
*==============================================================================
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

// 2015-02-09 [E_本稼動_12565] Add Start
    XxcsoContractOtherCustFullVOImpl contrOtherCustVo
      = getXxcsoContractOtherCustFullVO1();
    if ( contrOtherCustVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoContractOtherCustFullVO1");
    }

    XxcsoSpDecisionHeadersSummuryVOImpl spDecHedSumVo
      = getXxcsoSpDecisionHeadersSummuryVO1();
    if ( spDecHedSumVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoSpDecisionHeadersSummuryVO1");
    }
// 2015-02-09 [E_本稼動_12565] Add End
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
// 2015-02-09 [E_本稼動_12565] Add Start
     ,contrOtherCustVo
     ,spDecHedSumVo
// 2015-02-09 [E_本稼動_12565] Add End
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
// 2015-02-09 [E_本稼動_12565] Add Start
    XxcsoContractOtherCustFullVOImpl contrOtherCustVo
      = getXxcsoContractOtherCustFullVO1();
    if ( contrOtherCustVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoContractOtherCustFullVO1");
    }

    XxcsoSpDecisionHeadersSummuryVOImpl spDecHedSumVo
      = getXxcsoSpDecisionHeadersSummuryVO1();
    if ( spDecHedSumVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoSpDecisionHeadersSummuryVO1");
    }
// 2015-02-09 [E_本稼動_12565] Add End
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
// 2015-02-09 [E_本稼動_12565] Add Start
     ,contrOtherCustVo
     ,spDecHedSumVo
// 2015-02-09 [E_本稼動_12565] Add End
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
// 2015-02-09 [E_本稼動_12565] Add Start
    XxcsoContractOtherCustFullVOImpl contrOtherCustVo
      = getXxcsoContractOtherCustFullVO1();
    if ( contrOtherCustVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoContractOtherCustFullVO1");
    }

    XxcsoSpDecisionHeadersSummuryVOImpl spDecHedSumVo
      = getXxcsoSpDecisionHeadersSummuryVO1();
    if ( spDecHedSumVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoSpDecisionHeadersSummuryVO1");
    }

    XxcsoContractOtherCustFullVOImpl contrOtherCustVo2
      = getXxcsoContractOtherCustFullVO2();
    if ( contrOtherCustVo2 == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoContractOtherCustFullVO2");
    }
// 2015-02-09 [E_本稼動_12565] Add End
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
// 2015-02-09 [E_本稼動_12565] Add Start
     ,contrOtherCustVo
     ,spDecHedSumVo
     ,contrOtherCustVo2
// 2015-02-09 [E_本稼動_12565] Add End
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

// 2016-01-06 [E_本稼動_13456] Add Start
    XxcsoPageRenderVOImpl pageRndrVo = getXxcsoPageRenderVO1();
    if ( pageRndrVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoPageRenderVOImpl");
    }
// 2016-01-06 [E_本稼動_13456] Add End

// 2010-03-01 [E_本稼動_01678] Add Start
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
// 2010-03-01 [E_本稼動_01678] Add End
// 2015-02-09 [E_本稼動_12565] Add Start
    XxcsoContractOtherCustFullVOImpl contrOtherCustVo
      = getXxcsoContractOtherCustFullVO1();
    if ( contrOtherCustVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoContractOtherCustFullVO1");
    }
// 2015-02-09 [E_本稼動_12565] Add End

    XxcsoContractManagementFullVORowImpl mngRow
      = (XxcsoContractManagementFullVORowImpl) mngVo.first();

// 2016-01-06 [E_本稼動_13456] Add Start
    XxcsoPageRenderVORowImpl pageRndrVoRow
      = (XxcsoPageRenderVORowImpl) pageRndrVo.first(); 
// 2016-01-06 [E_本稼動_13456] Add End

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
// 2010-03-01 [E_本稼動_01678] Add Start
      // 口座情報反映処理
      XxcsoContractRegistReflectUtils.reflectBankAccount(
        dest1Vo
       ,bank1Vo
       ,dest2Vo
       ,bank2Vo
       ,dest3Vo
       ,bank3Vo
      );
// 2010-03-01 [E_本稼動_01678] Add End
// 2016-01-06 [E_本稼動_13456] Add Start
      // オーナー変更の場合
      if ( XxcsoContractRegistConstants.OWNER_CHANGE_FLAG_ON.equals(
           pageRndrVoRow.getOwnerChangeFlag() )
      )
      {
        // 自販機S連携フラグ
        mngRow.setVdmsInterfaceFlag(XxcsoContractRegistConstants.INTERFACE_NONE);
      }
      else
      {
        // 自販機S連携フラグ
        mngRow.setVdmsInterfaceFlag(XxcsoContractRegistConstants.INTERFACE_NO_TARGET);
      }
// 2016-01-06 [E_本稼動_13456] Add End
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

// 2016-01-06 [E_本稼動_13456] Add Start
    XxcsoPageRenderVOImpl pageRndrVo = getXxcsoPageRenderVO1();
    if ( pageRndrVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoPageRenderVOImpl");
    }
// 2016-01-06 [E_本稼動_13456] Add End

// 2010-03-01 [E_本稼動_01678] Add Start
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
// 2010-03-01 [E_本稼動_01678] Add End
// 2015-02-09 [E_本稼動_12565] Add Start
    XxcsoContractOtherCustFullVOImpl contrOtherCustVo
      = getXxcsoContractOtherCustFullVO1();
    if ( contrOtherCustVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoContractOtherCustFullVO1");
    }
// 2015-02-09 [E_本稼動_12565] Add End

    XxcsoContractManagementFullVORowImpl mngRow
      = (XxcsoContractManagementFullVORowImpl) mngVo.first();
// 2010-02-09 [E_本稼動_01538] Mod Start

// 2016-01-06 [E_本稼動_13456] Add Start
    XxcsoPageRenderVORowImpl pageRndrVoRow
      = (XxcsoPageRenderVORowImpl) pageRndrVo.first(); 
// 2016-01-06 [E_本稼動_13456] Add End

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
// 2016-01-06 [E_本稼動_13456] Add Start
      // オーナー変更の場合
      if ( XxcsoContractRegistConstants.OWNER_CHANGE_FLAG_ON.equals(
           pageRndrVoRow.getOwnerChangeFlag() )
      )
      {
        // 自販機S連携フラグ
        mngRow.setVdmsInterfaceFlag(XxcsoContractRegistConstants.INTERFACE_NONE);
      }
      else
      {
        // 自販機S連携フラグ
        mngRow.setVdmsInterfaceFlag(XxcsoContractRegistConstants.INTERFACE_NO_TARGET);
      }
// 2016-01-06 [E_本稼動_13456] Add End
    }
    // 適用ボタン押下の場合
    else
    {
      // ステータス
      mngRow.setStatus(XxcsoContractRegistConstants.STS_INPUT);
// 2016-01-06 [E_本稼動_13456] Add Start
      // オーナー変更の場合
      if ( XxcsoContractRegistConstants.OWNER_CHANGE_FLAG_ON.equals(
           pageRndrVoRow.getOwnerChangeFlag() )
      )
      {
        // 自販機S連携フラグ
        mngRow.setVdmsInterfaceFlag(XxcsoContractRegistConstants.INTERFACE_NONE);
      }
      else
      {
        // 自販機S連携フラグ
        mngRow.setVdmsInterfaceFlag(XxcsoContractRegistConstants.INTERFACE_NO_TARGET);
      }
// 2016-01-06 [E_本稼動_13456] Add End
    }

// 2010-03-01 [E_本稼動_01678] Add Start
    // 口座情報反映処理
    XxcsoContractRegistReflectUtils.reflectBankAccount(
      dest1Vo
     ,bank1Vo
     ,dest2Vo
     ,bank2Vo
     ,dest3Vo
     ,bank3Vo
    );
// 2010-03-01 [E_本稼動_01678] Add End

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

// 2012-06-12 Ver1.8 [E_本稼動_09602] Add Start
  /*****************************************************************************
   * 契約取消処理
   *****************************************************************************
   */
  public HashMap handleRejectOkButton(String actionValue)
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

    // ステータスを取消済に変更
    mngRow.setStatus(XxcsoContractRegistConstants.STS_REJECT);

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
// 2012-06-12 Ver1.8 [E_本稼動_09602] Add End

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
// 2015-02-09 [E_本稼動_12565] Add Start
    XxcsoContractOtherCustFullVOImpl contrOtherCustVo
      = getXxcsoContractOtherCustFullVO1();
    if ( contrOtherCustVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoContractOtherCustFullVO1");
    }
// 2015-02-09 [E_本稼動_12565] Add End
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
// 2010-03-01 [E_本稼動_01678] Add Start
       ,mngVo
// 2010-03-01 [E_本稼動_01678] Add End
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
// 2010-03-01 [E_本稼動_01678] Add Start
       ,mngVo
// 2010-03-01 [E_本稼動_01678] Add End
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
// 2010-03-01 [E_本稼動_01678] Add Start
       ,mngVo
// 2010-03-01 [E_本稼動_01678] Add End
       ,dest3Vo
       ,bank3Vo
       ,fixedFlag
      )
    );
// 2015-02-09 [E_本稼動_12565] Add Start
    /////////////////////////////////////
    // 検証処理：設置協賛金情報・紹介手数料・電気代
    /////////////////////////////////////
    errorList.addAll(
      XxcsoContractRegistValidateUtils.validateInstIntroElectric(
        txn
       ,pageRenderVo
       ,mngVo
       ,contrOtherCustVo
       ,fixedFlag
      )
    );
// 2015-02-09 [E_本稼動_12565] Add End
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
// 2011-06-06 Ver1.7 [E_本稼動_01963] Add Start
  /*****************************************************************************
   * 支払先作成済みチェック処理
   *****************************************************************************
   */
  public void supplierCheck()
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    mMessage = this.validateSupplierInfo();

    XxcsoUtils.debug(txn, "[END]");
  }

  /*****************************************************************************
   * 支払先作成済みチェック
   * @return OAException 
   *****************************************************************************
   */
  private OAException validateSupplierInfo()
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    OAException confirmMsg = null;

    StringBuffer sbMsg = new StringBuffer();

    String vendorCode = null;

    //インスタンス取得
    XxcsoPageRenderVOImpl pageRenderVo
      = getXxcsoPageRenderVO1();
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

    // 行インスタンス取得
    XxcsoPageRenderVORowImpl pageRenderRow
      = (XxcsoPageRenderVORowImpl) pageRenderVo.first();

    XxcsoContractManagementFullVORowImpl mngRow
      = (XxcsoContractManagementFullVORowImpl) mngVo.first();

    XxcsoBm1DestinationFullVORowImpl dest1Row
      = (XxcsoBm1DestinationFullVORowImpl)dest1Vo.first();

    XxcsoBm2DestinationFullVORowImpl dest2Row
      = (XxcsoBm2DestinationFullVORowImpl) dest2Vo.first();

    XxcsoBm3DestinationFullVORowImpl dest3Row
      = (XxcsoBm3DestinationFullVORowImpl) dest3Vo.first();

    /////////////////////////////////////
    // BM1送付先コード変更チェック
    /////////////////////////////////////
    // BM1指定がONの場合
    if ( XxcsoContractRegistValidateUtils.isChecked(
           pageRenderRow.getBm1ExistFlag() ) )
    {

      //BM1仕入先新規作成チェック
      vendorCode = XxcsoContractRegistValidateUtils.SuppllierMstCheck(
                         txn
                         ,mngRow.getContractNumber()
                         ,mngRow.getInstallAccountNumber()
                         ,dest1Row.getDeliveryDiv()
                         ,dest1Row.getSupplierId()
                       );

      //戻り値がNULL以外の場合
      if (  !( vendorCode == null || "".equals(vendorCode.trim()) ) )
      {

        //BM1トークン設定
        sbMsg.append( XxcsoContractRegistConstants.TOKEN_VALUE_BM1 );
        sbMsg.append( XxcsoConstants.TOKEN_VALUE_DELIMITER3 );

        //別契約が新規作成でない場合
        if ( !XxcsoContractRegistConstants.CREATE_VENDOR.equals(vendorCode) )
        {
          //取得した過去契約の仕入先コードを設定
          sbMsg.append( vendorCode );
        }
        else
        {
          //過去契約が仕入先を新規作成するトークン設定
          sbMsg.append(
            XxcsoContractRegistConstants.TOKEN_CREATE_VENDOR_BEFORE_CONT );
        }

      }

    }

    /////////////////////////////////////
    // BM2送付先コード変更チェック
    /////////////////////////////////////
    //初期化
    vendorCode = null;
    // BM2指定がONの場合
    if ( XxcsoContractRegistValidateUtils.isChecked(
           pageRenderRow.getBm2ExistFlag() ) )
    {
      //BM2仕入先新規作成チェック
      vendorCode = XxcsoContractRegistValidateUtils.SuppllierMstCheck(
                         txn
                        ,mngRow.getContractNumber()
                        ,mngRow.getInstallAccountNumber()
                        ,dest2Row.getDeliveryDiv()
                        ,dest2Row.getSupplierId()
                       );
      //戻り値がNULL以外の場合
      if ( !( vendorCode == null || "".equals(vendorCode.trim()) ) )
      {
        //BM1のメッセージが生成されている場合、区切り文字設定
        if (sbMsg.length() > 0) 
        {
          sbMsg.append(XxcsoConstants.TOKEN_VALUE_DELIMITER5);
          sbMsg.append(XxcsoConstants.TOKEN_VALUE_DELIMITER4);
          sbMsg.append(XxcsoConstants.TOKEN_VALUE_DELIMITER5);
        }

        //BM2トークン設定
        sbMsg.append( XxcsoContractRegistConstants.TOKEN_VALUE_BM2 );
        sbMsg.append( XxcsoConstants.TOKEN_VALUE_DELIMITER3 );

        //別契約が新規作成でない場合
        if ( !XxcsoContractRegistConstants.CREATE_VENDOR.equals(vendorCode) )
        {
          //取得した過去契約の仕入先コードを設定
          sbMsg.append( vendorCode );
        }
        else
        {
          //過去契約が仕入先を新規作成するトークン設定
          sbMsg.append(
            XxcsoContractRegistConstants.TOKEN_CREATE_VENDOR_BEFORE_CONT );
        }
        
      }

    }

    /////////////////////////////////////
    // BM3送付先コード変更チェック
    /////////////////////////////////////
    //初期化
    vendorCode = null;
    // BM3指定がONの場合
    if ( XxcsoContractRegistValidateUtils.isChecked(
           pageRenderRow.getBm3ExistFlag() ) )
    {
      //BM3仕入先新規作成チェック
      vendorCode = XxcsoContractRegistValidateUtils.SuppllierMstCheck(
                         txn
                        ,mngRow.getContractNumber()
                        ,mngRow.getInstallAccountNumber()
                        ,dest3Row.getDeliveryDiv()
                        ,dest3Row.getSupplierId()
                       );
      //戻り値がNULL以外の場合
      if ( !( vendorCode == null || "".equals(vendorCode.trim()) ) )
      {
        //BM1もしくはBM2のメッセージが生成されている場合、区切り文字設定
        if (sbMsg.length() > 0)
        {
          sbMsg.append(XxcsoConstants.TOKEN_VALUE_DELIMITER5);
          sbMsg.append(XxcsoConstants.TOKEN_VALUE_DELIMITER4);
          sbMsg.append(XxcsoConstants.TOKEN_VALUE_DELIMITER5);
        }

        //BM3トークン設定
        sbMsg.append( XxcsoContractRegistConstants.TOKEN_VALUE_BM3 );
        sbMsg.append( XxcsoConstants.TOKEN_VALUE_DELIMITER3 );
      
        //別契約が新規作成でない場合
        if ( !XxcsoContractRegistConstants.CREATE_VENDOR.equals(vendorCode) )
        {
          //取得した過去契約の仕入先コードを設定
          sbMsg.append( vendorCode );
        }
        else
        {
          //過去契約が仕入先を新規作成するトークン設定
          sbMsg.append(
            XxcsoContractRegistConstants.TOKEN_CREATE_VENDOR_BEFORE_CONT );
        }
        
      }

    }

    // 送付先コードが変更された場合、確認画面を表示する
    if (sbMsg.length() > 0) 
    {

      confirmMsg
        = XxcsoMessage.createConfirmMessage(
            XxcsoConstants.APP_XXCSO1_00614
           ,XxcsoConstants.TOKEN_BM_INFO
           ,new String(sbMsg)
          );
    }

    XxcsoUtils.debug(txn, "[END]");

    return confirmMsg;
  }

  /*****************************************************************************
   * 銀行口座作成済みチェック処理
   *****************************************************************************
   */
  public void bankAccountCheck()
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    mMessage = this.validatebankAccountInfo();

    XxcsoUtils.debug(txn, "[END]");
  }

  /*****************************************************************************
   * 銀行口座作成済みチェック
   * @return OAException 
   *****************************************************************************
   */
  private OAException validatebankAccountInfo()
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    OAException confirmMsg = null;

    StringBuffer sbMsg = new StringBuffer();

    String vendorCode = null;

    //インスタンス取得
    XxcsoPageRenderVOImpl pageRenderVo
      = getXxcsoPageRenderVO1();
    if ( pageRenderVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoPageRenderVOImpl");
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

    // 行インスタンス取得
    XxcsoPageRenderVORowImpl pageRenderRow
      = (XxcsoPageRenderVORowImpl) pageRenderVo.first();

    XxcsoBm1DestinationFullVORowImpl dest1Row
      = (XxcsoBm1DestinationFullVORowImpl)dest1Vo.first();

    XxcsoBm2DestinationFullVORowImpl dest2Row
      = (XxcsoBm2DestinationFullVORowImpl) dest2Vo.first();

    XxcsoBm3DestinationFullVORowImpl dest3Row
      = (XxcsoBm3DestinationFullVORowImpl) dest3Vo.first();

    XxcsoBm1BankAccountFullVORowImpl bank1Row
      = (XxcsoBm1BankAccountFullVORowImpl)bank1Vo.first();

    XxcsoBm2BankAccountFullVORowImpl bank2Row
      = (XxcsoBm2BankAccountFullVORowImpl)bank2Vo.first();

    XxcsoBm3BankAccountFullVORowImpl bank3Row
      = (XxcsoBm3BankAccountFullVORowImpl)bank3Vo.first();

    /////////////////////////////////////
    // BM1銀行口座チェック
    /////////////////////////////////////
    // BM1指定がONの場合
    if ( XxcsoContractRegistValidateUtils.isChecked(
           pageRenderRow.getBm1ExistFlag() ) )
    {

      //BM1送付先が指定されていない場合
      if ( dest1Row.getSupplierId() == null )
      {
      
        //BM1銀行口座新規作成チェック
        vendorCode = XxcsoContractRegistValidateUtils.BankAccountMstCheck(
                           txn
                           ,bank1Row.getBankNumber()
                           ,bank1Row.getBranchNumber()
                           ,bank1Row.getBankAccountNumber()
                         );

        //戻り値がNULL以外の場合
        if ( !( vendorCode == null || "".equals(vendorCode.trim()) ) )
        {
          //BM1トークン設定
          sbMsg.append( XxcsoContractRegistConstants.TOKEN_VALUE_BM1 );
          sbMsg.append( XxcsoConstants.TOKEN_VALUE_DELIMITER3 );
          sbMsg.append( vendorCode );
        }
      }
    }

    /////////////////////////////////////
    // BM2銀行口座チェック
    /////////////////////////////////////
    //初期化
    vendorCode = null;
    // BM2指定がONの場合
    if ( XxcsoContractRegistValidateUtils.isChecked(
           pageRenderRow.getBm2ExistFlag() ) )
    {
    
      //BM2送付先が指定されていない場合
      if ( dest2Row.getSupplierId() == null )
      {

        //BM2銀行口座新規作成チェック
        vendorCode = XxcsoContractRegistValidateUtils.BankAccountMstCheck(
                           txn
                           ,bank2Row.getBankNumber()
                           ,bank2Row.getBranchNumber()
                           ,bank2Row.getBankAccountNumber()
                         );

        //戻り値がNULL以外の場合
        if ( !( vendorCode == null || "".equals(vendorCode.trim()) ) )
        {
          //BM1のメッセージが生成されている場合、区切り文字設定
          if (sbMsg.length() > 0)
          {
            sbMsg.append(XxcsoConstants.TOKEN_VALUE_DELIMITER5);
            sbMsg.append(XxcsoConstants.TOKEN_VALUE_DELIMITER4);
            sbMsg.append(XxcsoConstants.TOKEN_VALUE_DELIMITER5);
          }

          //BM2トークン設定
          sbMsg.append( XxcsoContractRegistConstants.TOKEN_VALUE_BM2 );
          sbMsg.append( XxcsoConstants.TOKEN_VALUE_DELIMITER3 );
          sbMsg.append( vendorCode );
        }
      }
    }

    /////////////////////////////////////
    // BM3銀行口座チェック
    /////////////////////////////////////
    //初期化
    vendorCode = null;
    // BM3指定がONの場合
    if ( XxcsoContractRegistValidateUtils.isChecked(
           pageRenderRow.getBm3ExistFlag() ) )
    {

      //BM3送付先が指定されていない場合
      if ( dest3Row.getSupplierId() == null )
      {
      
        //BM3銀行口座新規作成チェック
        vendorCode = XxcsoContractRegistValidateUtils.BankAccountMstCheck(
                           txn
                           ,bank3Row.getBankNumber()
                           ,bank3Row.getBranchNumber()
                           ,bank3Row.getBankAccountNumber()
                         );

        //戻り値がNULL以外の場合
        if ( !( vendorCode == null || "".equals(vendorCode.trim()) ) )
        {
          //BM1もしくはBM2のメッセージが生成されている場合、区切り文字設定
          if (sbMsg.length() > 0)
          {
            sbMsg.append(XxcsoConstants.TOKEN_VALUE_DELIMITER5);
            sbMsg.append(XxcsoConstants.TOKEN_VALUE_DELIMITER4);
            sbMsg.append(XxcsoConstants.TOKEN_VALUE_DELIMITER5);
          }

          //BM3トークン設定
          sbMsg.append( XxcsoContractRegistConstants.TOKEN_VALUE_BM3 );
          sbMsg.append( XxcsoConstants.TOKEN_VALUE_DELIMITER3 );
          sbMsg.append( vendorCode );
        }
      }
    }

    // 銀行口座が存在する場合、確認画面を表示する
    if (sbMsg.length() > 0) 
    {

      confirmMsg
        = XxcsoMessage.createConfirmMessage(
            XxcsoConstants.APP_XXCSO1_00615
           ,XxcsoConstants.TOKEN_BM_INFO
           ,new String(sbMsg)
          );
    }

    XxcsoUtils.debug(txn, "[END]");

    return confirmMsg;
  }
// 2011-06-06 Ver1.7 [E_本稼動_01963] Add End
// 2012-06-12 Ver1.8 [E_本稼動_09602] Add Start
  /*****************************************************************************
   * 契約取消確認処理
   *****************************************************************************
   */
  public void RejectContract()
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    mMessage = this.RejectContractConfirm();

    XxcsoUtils.debug(txn, "[END]");
  }

  /*****************************************************************************
   * 契約取消確認
   * @return OAException 
   *****************************************************************************
   */
  private OAException RejectContractConfirm()
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    OAException confirmMsg = null;

    //契約取消確認メッセージ取得
    confirmMsg
      = XxcsoMessage.createConfirmMessage(
          XxcsoConstants.APP_XXCSO1_00639
        );

    XxcsoUtils.debug(txn, "[END]");

    return confirmMsg;
  }
// 2012-06-12 Ver1.8 [E_本稼動_09602] Add End
  /**
   * 
   * Container's getter for XxcsoContractManagementFullVO1
   */
  public XxcsoContractManagementFullVOImpl getXxcsoContractManagementFullVO1()
  {
    return (XxcsoContractManagementFullVOImpl)findViewObject("XxcsoContractManagementFullVO1");
  }

// 2013-04-01 Ver1.9 [E_本稼動_10413] Add START
  /*****************************************************************************
   * 銀行口座マスタ変更チェック処理
   *****************************************************************************
   */
  public void bankAccountChangeCheck()
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    mMessage = this.validatebankAccountChangeInfo();

    XxcsoUtils.debug(txn, "[END]");
  }

  /*****************************************************************************
   * 銀行口座マスタ変更チェック
   * @return OAException 
   *****************************************************************************
   */
  private OAException validatebankAccountChangeInfo()
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    OAException  confirmMsg = null;
    OAException  MsgData    = null;

    StringBuffer sbMsg    = new StringBuffer();

    String retVal         = null;
    String BkAcType       = null;
    String BkAcHldNameAlt = null;
    String BkAcHldName    = null;

    OracleCallableStatement stmt = null;

    //インスタンス取得
    XxcsoPageRenderVOImpl pageRenderVo
      = getXxcsoPageRenderVO1();
    if ( pageRenderVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoPageRenderVOImpl");
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

    // 行インスタンス取得
    XxcsoPageRenderVORowImpl pageRenderRow
      = (XxcsoPageRenderVORowImpl) pageRenderVo.first();

    XxcsoBm1BankAccountFullVORowImpl bank1Row
      = (XxcsoBm1BankAccountFullVORowImpl)bank1Vo.first();

    XxcsoBm2BankAccountFullVORowImpl bank2Row
      = (XxcsoBm2BankAccountFullVORowImpl)bank2Vo.first();

    XxcsoBm3BankAccountFullVORowImpl bank3Row
      = (XxcsoBm3BankAccountFullVORowImpl)bank3Vo.first();

    /////////////////////////////////////
    // BM1銀行口座変更チェック
    /////////////////////////////////////
    // BM1指定がONの場合
    if ( XxcsoContractRegistValidateUtils.isChecked(
           pageRenderRow.getBm1ExistFlag() ) )
    {
      //銀行・支店・口座がnull以外の場合
      if (( bank1Row.getBankNumber() != null )
         &&( bank1Row.getBranchNumber() != null )
         &&( bank1Row.getBankAccountNumber() != null ))
      {
        try
        {

          StringBuffer sql = new StringBuffer(300);
          //  銀行口座マスタ変更チェック
          sql.append("BEGIN");
          sql.append("  :1 := xxcso_010003j_pkg.chk_bank_account_change(");
          sql.append("        iv_bank_number             => :2");          // 銀行番号
          sql.append("       ,iv_bank_num                => :3");          // 支店番号
          sql.append("       ,iv_bank_account_num        => :4");          // 口座番号
          sql.append("       ,iv_bank_account_type       => :5");          // 口座種別(画面入力)
          sql.append("       ,iv_account_holder_name_alt => :6");          // 口座名義カナ(画面入力)
          sql.append("       ,iv_account_holder_name     => :7");          // 口座名義漢字(画面入力)
          sql.append("       ,ov_bank_account_type       => :8");          // 口座種別(マスタ)
          sql.append("       ,ov_account_holder_name_alt => :9");          // 口座名義カナ(マスタ)
          sql.append("       ,ov_account_holder_name     => :10");         // 口座名義漢字(マスタ)
          sql.append("        );");
          sql.append("END;");

          stmt
            = (OracleCallableStatement)
                txn.createCallableStatement(sql.toString(), 0);

          stmt.registerOutParameter(1, OracleTypes.VARCHAR);
          stmt.setString(2, bank1Row.getBankNumber());
          stmt.setString(3, bank1Row.getBranchNumber());
          stmt.setString(4, bank1Row.getBankAccountNumber());
          stmt.setString(5, bank1Row.getBankAccountType());
          stmt.setString(6, bank1Row.getBankAccountNameKana());
          stmt.setString(7, bank1Row.getBankAccountNameKanji());
          stmt.registerOutParameter(8, OracleTypes.VARCHAR);
          stmt.registerOutParameter(9, OracleTypes.VARCHAR);
          stmt.registerOutParameter(10,OracleTypes.VARCHAR);

          stmt.execute();

          retVal         = stmt.getString(1);   //リターンコード
          BkAcType       = stmt.getString(8);   //口座種別(マスタ)
          BkAcHldNameAlt = stmt.getString(9);   //口座名義カナ(マスタ)
          BkAcHldName    = stmt.getString(10);  //口座名義漢字(マスタ)

          //戻り値が2(変更あり)の場合
          if ( "2".equals(retVal) )
          {
            //BM1トークン設定
            sbMsg.append( XxcsoContractRegistConstants.TOKEN_VALUE_BM1 );
            //口座情報をマスタの値で更新
            bank1Row.setBankAccountType(BkAcType);
            bank1Row.setBankAccountNameKana(BkAcHldNameAlt);
            bank1Row.setBankAccountNameKanji(BkAcHldName);
          }

        }
        catch ( SQLException e )
        {
          XxcsoUtils.unexpected(txn, e);
          throw
            XxcsoMessage.createSqlErrorMessage(
              e
             ,XxcsoContractRegistConstants.TOKEN_VALUE_PLURAL_SUPPLIER_CHK
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

    retVal         = null;
    BkAcType       = null;
    BkAcHldNameAlt = null;
    BkAcHldName    = null;

    /////////////////////////////////////
    // BM2銀行口座変更チェック
    /////////////////////////////////////
    // BM2指定がONの場合
    if ( XxcsoContractRegistValidateUtils.isChecked(
           pageRenderRow.getBm2ExistFlag() ) )
    {
      //銀行・支店・口座がnull以外の場合
      if (( bank2Row.getBankNumber() != null )
         &&( bank2Row.getBranchNumber() != null )
         &&( bank2Row.getBankAccountNumber() != null ))
      {
        try
        {

          StringBuffer sql = new StringBuffer(300);
          //  銀行口座マスタ変更チェック
          sql.append("BEGIN");
          sql.append("  :1 := xxcso_010003j_pkg.chk_bank_account_change(");
          sql.append("        iv_bank_number             => :2");          // 銀行番号
          sql.append("       ,iv_bank_num                => :3");          // 支店番号
          sql.append("       ,iv_bank_account_num        => :4");          // 口座番号
          sql.append("       ,iv_bank_account_type       => :5");          // 口座種別(画面入力)
          sql.append("       ,iv_account_holder_name_alt => :6");          // 口座名義カナ(画面入力)
          sql.append("       ,iv_account_holder_name     => :7");          // 口座名義漢字(画面入力)
          sql.append("       ,ov_bank_account_type       => :8");          // 口座種別(マスタ)
          sql.append("       ,ov_account_holder_name_alt => :9");          // 口座名義カナ(マスタ)
          sql.append("       ,ov_account_holder_name     => :10");         // 口座名義漢字(マスタ)
          sql.append("        );");
          sql.append("END;");

          stmt
            = (OracleCallableStatement)
                txn.createCallableStatement(sql.toString(), 0);

          stmt.registerOutParameter(1, OracleTypes.VARCHAR);
          stmt.setString(2, bank2Row.getBankNumber());
          stmt.setString(3, bank2Row.getBranchNumber());
          stmt.setString(4, bank2Row.getBankAccountNumber());
          stmt.setString(5, bank2Row.getBankAccountType());
          stmt.setString(6, bank2Row.getBankAccountNameKana());
          stmt.setString(7, bank2Row.getBankAccountNameKanji());
          stmt.registerOutParameter(8, OracleTypes.VARCHAR);
          stmt.registerOutParameter(9, OracleTypes.VARCHAR);
          stmt.registerOutParameter(10,OracleTypes.VARCHAR);

          stmt.execute();

          retVal         = stmt.getString(1);   //リターンコード
          BkAcType       = stmt.getString(8);   //口座種別(マスタ)
          BkAcHldNameAlt = stmt.getString(9);   //口座名義カナ(マスタ)
          BkAcHldName    = stmt.getString(10);  //口座名義漢字(マスタ)

          //戻り値が2(変更あり)の場合
          if ( "2".equals(retVal) )
          {
            //区切り文字設定
           if (sbMsg.length() > 0) 
           {
            sbMsg.append(XxcsoConstants.TOKEN_VALUE_DELIMITER5);
            sbMsg.append(XxcsoConstants.TOKEN_VALUE_DELIMITER4);
            sbMsg.append(XxcsoConstants.TOKEN_VALUE_DELIMITER5);
           }
            //BM2トークン設定
            sbMsg.append( XxcsoContractRegistConstants.TOKEN_VALUE_BM2 );
            //口座情報をマスタの値で更新
            bank2Row.setBankAccountType(BkAcType);
            bank2Row.setBankAccountNameKana(BkAcHldNameAlt);
            bank2Row.setBankAccountNameKanji(BkAcHldName);
          }

        }
        catch ( SQLException e )
        {
          XxcsoUtils.unexpected(txn, e);
          throw
            XxcsoMessage.createSqlErrorMessage(
              e
             ,XxcsoContractRegistConstants.TOKEN_VALUE_PLURAL_SUPPLIER_CHK
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

    retVal         = null;
    BkAcType       = null;
    BkAcHldNameAlt = null;
    BkAcHldName    = null;

    /////////////////////////////////////
    // BM3銀行口座変更チェック
    /////////////////////////////////////
    // BM3指定がONの場合
    if ( XxcsoContractRegistValidateUtils.isChecked(
           pageRenderRow.getBm3ExistFlag() ) )
    {
      //銀行・支店・口座がnull以外の場合
      if (( bank3Row.getBankNumber() != null )
         &&( bank3Row.getBranchNumber() != null )
         &&( bank3Row.getBankAccountNumber() != null ))
      {
        try
        {

          StringBuffer sql = new StringBuffer(300);
          //  銀行口座マスタ変更チェック
          sql.append("BEGIN");
          sql.append("  :1 := xxcso_010003j_pkg.chk_bank_account_change(");
          sql.append("        iv_bank_number             => :2");          // 銀行番号
          sql.append("       ,iv_bank_num                => :3");          // 支店番号
          sql.append("       ,iv_bank_account_num        => :4");          // 口座番号
          sql.append("       ,iv_bank_account_type       => :5");          // 口座種別(画面入力)
          sql.append("       ,iv_account_holder_name_alt => :6");          // 口座名義カナ(画面入力)
          sql.append("       ,iv_account_holder_name     => :7");          // 口座名義漢字(画面入力)
          sql.append("       ,ov_bank_account_type       => :8");          // 口座種別(マスタ)
          sql.append("       ,ov_account_holder_name_alt => :9");          // 口座名義カナ(マスタ)
          sql.append("       ,ov_account_holder_name     => :10");         // 口座名義漢字(マスタ)
          sql.append("        );");
          sql.append("END;");

          stmt
            = (OracleCallableStatement)
                txn.createCallableStatement(sql.toString(), 0);

          stmt.registerOutParameter(1, OracleTypes.VARCHAR);
          stmt.setString(2, bank3Row.getBankNumber());
          stmt.setString(3, bank3Row.getBranchNumber());
          stmt.setString(4, bank3Row.getBankAccountNumber());
          stmt.setString(5, bank3Row.getBankAccountType());
          stmt.setString(6, bank3Row.getBankAccountNameKana());
          stmt.setString(7, bank3Row.getBankAccountNameKanji());
          stmt.registerOutParameter(8, OracleTypes.VARCHAR);
          stmt.registerOutParameter(9, OracleTypes.VARCHAR);
          stmt.registerOutParameter(10,OracleTypes.VARCHAR);

          stmt.execute();

          retVal         = stmt.getString(1);   //リターンコード
          BkAcType       = stmt.getString(8);   //口座種別(マスタ)
          BkAcHldNameAlt = stmt.getString(9);   //口座名義カナ(マスタ)
          BkAcHldName    = stmt.getString(10);  //口座名義漢字(マスタ)

          //戻り値が2(変更あり)の場合
          if ( "2".equals(retVal) )
          {
            //区切り文字設定
           if (sbMsg.length() > 0) 
           {
            sbMsg.append(XxcsoConstants.TOKEN_VALUE_DELIMITER5);
            sbMsg.append(XxcsoConstants.TOKEN_VALUE_DELIMITER4);
            sbMsg.append(XxcsoConstants.TOKEN_VALUE_DELIMITER5);
           }
            //BM3トークン設定
            sbMsg.append( XxcsoContractRegistConstants.TOKEN_VALUE_BM3 );
            //口座情報をマスタの値で更新
            bank3Row.setBankAccountType(BkAcType);
            bank3Row.setBankAccountNameKana(BkAcHldNameAlt);
            bank3Row.setBankAccountNameKanji(BkAcHldName);
          }

        }
        catch ( SQLException e )
        {
          XxcsoUtils.unexpected(txn, e);
          throw
            XxcsoMessage.createSqlErrorMessage(
              e
             ,XxcsoContractRegistConstants.TOKEN_VALUE_PLURAL_SUPPLIER_CHK
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

    // 銀行口座が存在する場合、確認画面を表示する
    if (sbMsg.length() > 0) 
    {

      confirmMsg
        = XxcsoMessage.createWarningMessage(
            XxcsoConstants.APP_XXCSO1_00646
           ,XxcsoConstants.TOKEN_BM_INFO
           ,new String(sbMsg)
          );
    }

    XxcsoUtils.debug(txn, "[END]");

    return confirmMsg;
  }
// 2013-04-01 Ver1.9 [E_本稼動_10413] Add End
// V2.2 Y.Sasaki Added START
  /*****************************************************************************
   * 送付先情報の変更チェック処理
   *****************************************************************************
   */
  public void suppllierChangeCheck()
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    mMessage = this.validateSuppllierChangeInfo();

    XxcsoUtils.debug(txn, "[END]");
  }

  /*****************************************************************************
   * 送付先情報の変更チェック
   * @return OAException 
   *****************************************************************************
   */
  private OAException validateSuppllierChangeInfo()
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    OAException  confirmMsg = null;
    OAException  MsgData    = null;

    StringBuffer sbMsg    = new StringBuffer();

    String retVal         = null;

    String msgVenCd       = null;

    //送付先情報
    String BmTranComType  = null;   //振込手数料負担
    String BmPayType      = null;   //支払方法、明細書
    String InqBaseCode    = null;   //問合せ担当拠点
    String InqBaseName    = null;   //問合せ担当拠点名
    String VenName        = null;   //送付先名
    String VenNameAlt     = null;   //送付先名カナ
    String Zip            = null;   //郵便番号
    String Address1       = null;   //住所１
    String Address2       = null;   //住所２
    String PhoneNum       = null;   //電話番号

    //送付先の銀行情報
    String BkNum          = null;   //金融機関コード
    String BkName         = null;   //金融機関名
    String BkBranNum      = null;   //支店コード
    String BkBranName     = null;   //支店名
    String BkAcType       = null;   //口座種別
    String BkAcTypeName   = null;   //口座種別名
    String BkAcNum        = null;   //口座番号
    String BkAcHldNameAlt = null;   //口座名義カナ
    String BkAcHldName    = null;   //口座名義漢字

    OracleCallableStatement stmt = null;

    OracleCallableStatement debug = null;

    //インスタンス取得
    XxcsoPageRenderVOImpl pageRenderVo
      = getXxcsoPageRenderVO1();
    if ( pageRenderVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoPageRenderVOImpl");
    }

    //BM1の送付先情報のインスタンス取得
    XxcsoBm1DestinationFullVOImpl dest1Vo
      = getXxcsoBm1DestinationFullVO1();
    if ( dest1Vo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoBm1DestinationFullVO1");
    }

    //BM1の銀行情報のインスタンス取得
    XxcsoBm1BankAccountFullVOImpl bank1Vo
      = getXxcsoBm1BankAccountFullVO1();
    if ( bank1Vo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoBm1BankAccountFullVO1");
    }

    //BM2の送付先情報のインスタンス取得
    XxcsoBm2DestinationFullVOImpl dest2Vo
      = getXxcsoBm2DestinationFullVO1();
    if ( dest2Vo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoBm2DestinationFullVO1");
    }

    //BM2の銀行情報のインスタンス取得
    XxcsoBm2BankAccountFullVOImpl bank2Vo
      = getXxcsoBm2BankAccountFullVO1();
    if ( bank2Vo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoBm2BankAccountFullVO1");
    }

    //BM3の送付先情報のインスタンス取得
    XxcsoBm3DestinationFullVOImpl dest3Vo
      = getXxcsoBm3DestinationFullVO1();
    if ( dest3Vo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoBm3DestinationFullVO1");
    }

    //BM3の銀行情報のインスタンス取得
    XxcsoBm3BankAccountFullVOImpl bank3Vo
      = getXxcsoBm3BankAccountFullVO1();
    if ( bank3Vo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoBm3BankAccountFullVO1");
    }

    // 行インスタンス取得
    XxcsoPageRenderVORowImpl pageRenderRow
      = (XxcsoPageRenderVORowImpl) pageRenderVo.first();

    //BM1の送付先情報の行インスタンス取得
    XxcsoBm1DestinationFullVORowImpl bm1DestVoRow
      = (XxcsoBm1DestinationFullVORowImpl) dest1Vo.first();

    //BM1の銀行情報の行インスタンス取得
    XxcsoBm1BankAccountFullVORowImpl bank1Row
      = (XxcsoBm1BankAccountFullVORowImpl)bank1Vo.first();

    //BM2の送付先情報の行インスタンス取得
    XxcsoBm2DestinationFullVORowImpl bm2DestVoRow
      = (XxcsoBm2DestinationFullVORowImpl) dest2Vo.first();

    //BM2の銀行情報の行インスタンス取得
    XxcsoBm2BankAccountFullVORowImpl bank2Row
      = (XxcsoBm2BankAccountFullVORowImpl)bank2Vo.first();

    //BM3の送付先情報の行インスタンス取得
    XxcsoBm3DestinationFullVORowImpl bm3DestVoRow
      = (XxcsoBm3DestinationFullVORowImpl) dest3Vo.first();

    //BM3の銀行情報の行インスタンス取得
    XxcsoBm3BankAccountFullVORowImpl bank3Row
      = (XxcsoBm3BankAccountFullVORowImpl)bank3Vo.first();

    /////////////////////////////////////
    // BM1送付先変更チェック
    /////////////////////////////////////
    // BM1指定がONの場合
    if ( XxcsoContractRegistValidateUtils.isChecked(
           pageRenderRow.getBm1ExistFlag() ) )
    {
      //送付先コードがnull以外の場合
      if (bm1DestVoRow.getVendorCode() != null )
      {
        // メッセージ用に入力値の送付先コードを保持
        msgVenCd = bm1DestVoRow.getVendorCode();
        try
        {
          StringBuffer sql = new StringBuffer(300);
          //  送付先変更チェック
          sql.append("BEGIN");
          sql.append("  :1 := xxcso_010003j_pkg.chk_supp_info_change(");
          sql.append("        iv_vendor_code                  => :2");          // 送付先コード
          sql.append("       ,ov_bm_transfer_commission_type  => :3");          // 振込手数料負担
          sql.append("       ,ov_bm_payment_type              => :4");          // 支払方法、明細書
          sql.append("       ,ov_inquiry_base_code            => :5");          // 問合せ担当拠点
          sql.append("       ,ov_inquiry_base_name            => :6");          // 問合せ担当拠点名
          sql.append("       ,ov_vendor_name                  => :7");          // 送付先名
          sql.append("       ,ov_vendor_name_alt              => :8");          // 送付先名カナ
          sql.append("       ,ov_zip                          => :9");          // 郵便番号
          sql.append("       ,ov_address_line1                => :10");         // 住所１
          sql.append("       ,ov_address_line2                => :11");         // 住所２
          sql.append("       ,ov_phone_number                 => :12");         // 電話番号
          sql.append("       ,ov_bank_number                  => :13");         // 金融機関コード
          sql.append("       ,ov_bank_name                    => :14");         // 金融機関名
          sql.append("       ,ov_bank_branch_number           => :15");         // 支店コード
          sql.append("       ,ov_bank_branch_name             => :16");         // 支店名
          sql.append("       ,ov_bank_account_type            => :17");         // 口座種別
          sql.append("       ,ov_bank_account_num             => :18");         // 口座番号
          sql.append("       ,ov_bank_account_holder_nm_alt   => :19");         // 口座名義カナ
          sql.append("       ,ov_bank_account_holder_nm       => :20");         // 口座名義漢字
          sql.append("        );");
          sql.append("END;");

          stmt
            = (OracleCallableStatement)
                txn.createCallableStatement(sql.toString(), 0);

          stmt.registerOutParameter(1, OracleTypes.VARCHAR);
          stmt.setString(2, bm1DestVoRow.getVendorCode());
          stmt.registerOutParameter(3, OracleTypes.VARCHAR);
          stmt.registerOutParameter(4, OracleTypes.VARCHAR);
          stmt.registerOutParameter(5, OracleTypes.VARCHAR);
          stmt.registerOutParameter(6, OracleTypes.VARCHAR);
          stmt.registerOutParameter(7, OracleTypes.VARCHAR);
          stmt.registerOutParameter(8, OracleTypes.VARCHAR);
          stmt.registerOutParameter(9, OracleTypes.VARCHAR);
          stmt.registerOutParameter(10,OracleTypes.VARCHAR);
          stmt.registerOutParameter(11,OracleTypes.VARCHAR);
          stmt.registerOutParameter(12,OracleTypes.VARCHAR);
          stmt.registerOutParameter(13,OracleTypes.VARCHAR);
          stmt.registerOutParameter(14,OracleTypes.VARCHAR);
          stmt.registerOutParameter(15,OracleTypes.VARCHAR);
          stmt.registerOutParameter(16,OracleTypes.VARCHAR);
          stmt.registerOutParameter(17,OracleTypes.VARCHAR);
          stmt.registerOutParameter(18,OracleTypes.VARCHAR);
          stmt.registerOutParameter(19,OracleTypes.VARCHAR);
          stmt.registerOutParameter(20,OracleTypes.VARCHAR);

          stmt.execute();

          retVal = stmt.getString(1);   //リターンコード

         //リターンコードが1(ダミー仕入先)の場合
          if ( "1".equals(retVal) )
          {
            //送付先情報
            BmTranComType   = stmt.getString(3);   //振込手数料負担
            BmPayType       = stmt.getString(4);   //支払方法、明細書
            InqBaseCode     = stmt.getString(5);   //問合せ担当拠点
            InqBaseName     = stmt.getString(6);   //問合せ担当拠点名
            VenName         = stmt.getString(7);   //送付先名
            VenNameAlt      = stmt.getString(8);   //送付先名カナ
            Zip             = stmt.getString(9);   //郵便番号
            Address1        = stmt.getString(10);  //住所１
            Address2        = stmt.getString(11);  //住所２
            PhoneNum        = stmt.getString(12);  //電話番号

            //送付先の銀行情報
            BkNum           = stmt.getString(13);  //金融機関コード
            BkName          = stmt.getString(14);  //金融機関名
            BkBranNum       = stmt.getString(15);  //支店コード
            BkBranName      = stmt.getString(16);  //支店名
            BkAcType        = stmt.getString(17);  //口座種別
            BkAcNum         = stmt.getString(18);  //口座番号
            BkAcHldNameAlt  = stmt.getString(19);  //口座名義カナ
            BkAcHldName     = stmt.getString(20);  //口座名義漢字

            //全ての項目に対して変更があるかチェック
            if (   !(bm1DestVoRow.getBankTransferFeeChargeDiv() != null && (bm1DestVoRow.getBankTransferFeeChargeDiv()).equals(BmTranComType)
                    || bm1DestVoRow.getBankTransferFeeChargeDiv() == null && BmTranComType == null)
                || !(bm1DestVoRow.getBellingDetailsDiv() != null && (bm1DestVoRow.getBellingDetailsDiv()).equals(BmPayType))
                || !(bm1DestVoRow.getInqueryChargeHubCd() != null && (bm1DestVoRow.getInqueryChargeHubCd()).equals(InqBaseCode))
                || !(bm1DestVoRow.getInqueryChargeHubName() != null && (bm1DestVoRow.getInqueryChargeHubName()).equals(InqBaseName))
                || !(bm1DestVoRow.getPaymentName() != null &&  (bm1DestVoRow.getPaymentName()).equals(VenName))
                || !(bm1DestVoRow.getPaymentNameAlt() != null && (bm1DestVoRow.getPaymentNameAlt()).equals(VenNameAlt))
                || !(bm1DestVoRow.getPostCode() != null && (bm1DestVoRow.getPostCode()).equals(Zip))
                || !(bm1DestVoRow.getAddress1() != null && (bm1DestVoRow.getAddress1()).equals(Address1))
                || !(bm1DestVoRow.getAddress2() != null && (bm1DestVoRow.getAddress2()).equals(Address2)
                    || bm1DestVoRow.getAddress2() == null && Address2 == null)
                || !(bm1DestVoRow.getAddressLinesPhonetic() != null && (bm1DestVoRow.getAddressLinesPhonetic()).equals(PhoneNum)
                    || bm1DestVoRow.getAddressLinesPhonetic() == null && PhoneNum == null)
                || !(bank1Row.getBankNumber() != null && (bank1Row.getBankNumber()).equals(BkNum)
                    || bank1Row.getBankNumber() == null && BkNum == null)
                || !(bank1Row.getBankName() != null && (bank1Row.getBankName()).equals(BkName)
                    || bank1Row.getBankName() == null && BkName == null)
                || !(bank1Row.getBranchNumber() != null && (bank1Row.getBranchNumber()).equals(BkBranNum)
                    || bank1Row.getBranchNumber() == null && BkBranNum == null)
                || !(bank1Row.getBranchName() != null && (bank1Row.getBranchName()).equals(BkBranName)
                    || bank1Row.getBranchName() == null && BkBranName == null)
                || !(bank1Row.getBankAccountType() != null && (bank1Row.getBankAccountType()).equals(BkAcType)
                    || bank1Row.getBankAccountType() == null && BkAcType == null)
                || !(bank1Row.getBankAccountNumber() != null && (bank1Row.getBankAccountNumber()).equals(BkAcNum)
                    || bank1Row.getBankAccountNumber() == null && BkAcNum == null)
                || !(bank1Row.getBankAccountNameKana() != null && (bank1Row.getBankAccountNameKana()).equals(BkAcHldNameAlt)
                    || bank1Row.getBankAccountNameKana() == null && BkAcHldNameAlt == null)
                || !(bank1Row.getBankAccountNameKanji() != null && (bank1Row.getBankAccountNameKanji()).equals(BkAcHldName)
                    || bank1Row.getBankAccountNameKanji() == null && BkAcHldName == null))
            {
              //BM1トークン設定
              sbMsg.append(  XxcsoContractRegistConstants.TOKEN_VALUE_BM1 
                           + XxcsoConstants.TOKEN_VALUE_DELIMITER3
                           + msgVenCd );

              //送付先情報をマスタの値で更新
              bm1DestVoRow.setBankTransferFeeChargeDiv(BmTranComType);
              bm1DestVoRow.setBellingDetailsDiv(BmPayType);
              bm1DestVoRow.setInqueryChargeHubCd(InqBaseCode);
              bm1DestVoRow.setInqueryChargeHubName(InqBaseName);
              bm1DestVoRow.setPaymentName(VenName);
              bm1DestVoRow.setPaymentNameAlt(VenNameAlt);
              bm1DestVoRow.setPostCode(Zip);
              bm1DestVoRow.setAddress1(Address1);
              bm1DestVoRow.setAddress2(Address2);
              bm1DestVoRow.setAddressLinesPhonetic(PhoneNum);

              //口座情報をマスタの値で更新
              bank1Row.setBankNumber(BkNum);
              bank1Row.setBankName(BkName);
              bank1Row.setBranchNumber(BkBranNum);
              bank1Row.setBranchName(BkBranName);
              bank1Row.setBankAccountType(BkAcType);
              bank1Row.setBankAccountNumber(BkAcNum);
              bank1Row.setBankAccountNameKana(BkAcHldNameAlt);
              bank1Row.setBankAccountNameKanji(BkAcHldName);
            }
          }

        }
        catch ( SQLException e )
        {
          XxcsoUtils.unexpected(txn, e);
          throw
            XxcsoMessage.createSqlErrorMessage(
              e
             ,XxcsoContractRegistConstants.TOKEN_VALUE_SUPPLIER_CHANGE_CHK
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

    retVal         = null;
    BkAcType       = null;
    BkAcHldNameAlt = null;
    BkAcHldName    = null;
    msgVenCd       = null;

    /////////////////////////////////////
    // BM2送付先変更チェック
    /////////////////////////////////////
    // BM2指定がONの場合
    if ( XxcsoContractRegistValidateUtils.isChecked(
           pageRenderRow.getBm2ExistFlag() ) )
    {
      //送付先コードがnull以外の場合
      if (bm2DestVoRow.getVendorCode() != null )
      {
        // メッセージ用にパラメータを保持
        msgVenCd = bm2DestVoRow.getVendorCode();
        try
        {

          StringBuffer sql = new StringBuffer(300);
          //  送付先変更チェック
          sql.append("BEGIN");
          sql.append("  :1 := xxcso_010003j_pkg.chk_supp_info_change(");
          sql.append("        iv_vendor_code                  => :2");          // 送付先コード
          sql.append("       ,ov_bm_transfer_commission_type  => :3");          // 振込手数料負担
          sql.append("       ,ov_bm_payment_type              => :4");          // 支払方法、明細書
          sql.append("       ,ov_inquiry_base_code            => :5");          // 問合せ担当拠点
          sql.append("       ,ov_inquiry_base_name            => :6");          // 問合せ担当拠点名
          sql.append("       ,ov_vendor_name                  => :7");          // 送付先名
          sql.append("       ,ov_vendor_name_alt              => :8");          // 送付先名カナ
          sql.append("       ,ov_zip                          => :9");          // 郵便番号
          sql.append("       ,ov_address_line1                => :10");         // 住所１
          sql.append("       ,ov_address_line2                => :11");         // 住所２
          sql.append("       ,ov_phone_number                 => :12");         // 電話番号
          sql.append("       ,ov_bank_number                  => :13");         // 金融機関コード
          sql.append("       ,ov_bank_name                    => :14");         // 金融機関名
          sql.append("       ,ov_bank_branch_number           => :15");         // 支店コード
          sql.append("       ,ov_bank_branch_name             => :16");         // 支店名
          sql.append("       ,ov_bank_account_type            => :17");         // 口座種別
          sql.append("       ,ov_bank_account_num             => :18");         // 口座番号
          sql.append("       ,ov_bank_account_holder_nm_alt   => :19");         // 口座名義カナ
          sql.append("       ,ov_bank_account_holder_nm       => :20");         // 口座名義漢字
          sql.append("        );");
          sql.append("END;");

          stmt
            = (OracleCallableStatement)
                txn.createCallableStatement(sql.toString(), 0);

          stmt.registerOutParameter(1, OracleTypes.VARCHAR);
          stmt.setString(2, bm2DestVoRow.getVendorCode());
          stmt.registerOutParameter(3, OracleTypes.VARCHAR);
          stmt.registerOutParameter(4, OracleTypes.VARCHAR);
          stmt.registerOutParameter(5, OracleTypes.VARCHAR);
          stmt.registerOutParameter(6, OracleTypes.VARCHAR);
          stmt.registerOutParameter(7, OracleTypes.VARCHAR);
          stmt.registerOutParameter(8, OracleTypes.VARCHAR);
          stmt.registerOutParameter(9, OracleTypes.VARCHAR);
          stmt.registerOutParameter(10,OracleTypes.VARCHAR);
          stmt.registerOutParameter(11,OracleTypes.VARCHAR);
          stmt.registerOutParameter(12,OracleTypes.VARCHAR);
          stmt.registerOutParameter(13,OracleTypes.VARCHAR);
          stmt.registerOutParameter(14,OracleTypes.VARCHAR);
          stmt.registerOutParameter(15,OracleTypes.VARCHAR);
          stmt.registerOutParameter(16,OracleTypes.VARCHAR);
          stmt.registerOutParameter(17,OracleTypes.VARCHAR);
          stmt.registerOutParameter(18,OracleTypes.VARCHAR);
          stmt.registerOutParameter(19,OracleTypes.VARCHAR);
          stmt.registerOutParameter(20,OracleTypes.VARCHAR);

          stmt.execute();

          retVal = stmt.getString(1);   //リターンコード

        	//戻り値が1(ダミー仕入先)の場合、項目が変更されていないかチェック
          if ( "1".equals(retVal) )
          {
            //送付先情報
            BmTranComType   = stmt.getString(3);   //振込手数料負担
            BmPayType       = stmt.getString(4);   //支払方法、明細書
            InqBaseCode     = stmt.getString(5);   //問合せ担当拠点
            InqBaseName     = stmt.getString(6);   //問合せ担当拠点名
            VenName         = stmt.getString(7);   //送付先名
            VenNameAlt      = stmt.getString(8);   //送付先名カナ
            Zip             = stmt.getString(9);   //郵便番号
            Address1        = stmt.getString(10);  //住所１
            Address2        = stmt.getString(11);  //住所２
            PhoneNum        = stmt.getString(12);  //電話番号

            //送付先の銀行情報
            BkNum           = stmt.getString(13);  //金融機関コード
            BkName          = stmt.getString(14);  //金融機関名
            BkBranNum       = stmt.getString(15);  //支店コード
            BkBranName      = stmt.getString(16);  //支店名
            BkAcType        = stmt.getString(17);  //口座種別
            BkAcNum         = stmt.getString(18);  //口座番号
            BkAcHldNameAlt  = stmt.getString(19);  //口座名義カナ
            BkAcHldName     = stmt.getString(20);  //口座名義漢字

            //全ての項目に対して変更があるかチェック
            if (   !(bm2DestVoRow.getBankTransferFeeChargeDiv() != null && (bm2DestVoRow.getBankTransferFeeChargeDiv()).equals(BmTranComType)
                    || bm2DestVoRow.getBankTransferFeeChargeDiv() == null && BmTranComType == null)
                || !(bm2DestVoRow.getBellingDetailsDiv() != null && (bm2DestVoRow.getBellingDetailsDiv()).equals(BmPayType))
                || !(bm2DestVoRow.getInqueryChargeHubCd() != null && (bm2DestVoRow.getInqueryChargeHubCd()).equals(InqBaseCode))
                || !(bm2DestVoRow.getInqueryChargeHubName() != null && (bm2DestVoRow.getInqueryChargeHubName()).equals(InqBaseName))
                || !(bm2DestVoRow.getPaymentName() != null &&  (bm2DestVoRow.getPaymentName()).equals(VenName))
                || !(bm2DestVoRow.getPaymentNameAlt() != null && (bm2DestVoRow.getPaymentNameAlt()).equals(VenNameAlt))
                || !(bm2DestVoRow.getPostCode() != null && (bm2DestVoRow.getPostCode()).equals(Zip))
                || !(bm2DestVoRow.getAddress1() != null && (bm2DestVoRow.getAddress1()).equals(Address1))
                || !(bm2DestVoRow.getAddress2() != null && (bm2DestVoRow.getAddress2()).equals(Address2)
                    || bm2DestVoRow.getAddress2() == null && Address2 == null)
                || !(bm2DestVoRow.getAddressLinesPhonetic() != null && (bm2DestVoRow.getAddressLinesPhonetic()).equals(PhoneNum)
                    || bm2DestVoRow.getAddressLinesPhonetic() == null && PhoneNum == null )
                || !(bank2Row.getBankNumber() != null && (bank2Row.getBankNumber()).equals(BkNum)
                    || bank2Row.getBankNumber() == null && BkNum == null)
                || !(bank2Row.getBankName() != null && (bank2Row.getBankName()).equals(BkName)
                    || bank2Row.getBankName() == null && BkName == null)
                || !(bank2Row.getBranchNumber() != null && (bank2Row.getBranchNumber()).equals(BkBranNum)
                    || bank2Row.getBranchNumber() == null && BkBranNum == null)
                || !(bank2Row.getBranchName() != null && (bank2Row.getBranchName()).equals(BkBranName)
                    || bank2Row.getBranchName() == null && BkBranName == null)
                || !(bank2Row.getBankAccountType() != null && (bank2Row.getBankAccountType()).equals(BkAcType)
                    || bank2Row.getBankAccountType() == null && BkAcType == null)
                || !(bank2Row.getBankAccountNumber() != null && (bank2Row.getBankAccountNumber()).equals(BkAcNum)
                    || bank2Row.getBankAccountNumber() == null && BkAcNum == null)
                || !(bank2Row.getBankAccountNameKana() != null && (bank2Row.getBankAccountNameKana()).equals(BkAcHldNameAlt)
                    || bank2Row.getBankAccountNameKana() == null && BkAcHldNameAlt == null)
                || !(bank2Row.getBankAccountNameKanji() != null && (bank2Row.getBankAccountNameKanji()).equals(BkAcHldName)
                    || bank2Row.getBankAccountNameKanji() == null && BkAcHldName == null))
            {
              //BM2トークン設定
              if ( sbMsg.length() > 0 )
              {
                sbMsg.append( XxcsoConstants.TOKEN_VALUE_DELIMITER2 );//カンマの挿入
              }
              sbMsg.append(  XxcsoContractRegistConstants.TOKEN_VALUE_BM2 
                           + XxcsoConstants.TOKEN_VALUE_DELIMITER3
                           + msgVenCd );

              //送付先情報をマスタの値で更新
              bm2DestVoRow.setBankTransferFeeChargeDiv(BmTranComType);
              bm2DestVoRow.setBellingDetailsDiv(BmPayType);
              bm2DestVoRow.setInqueryChargeHubCd(InqBaseCode);
              bm2DestVoRow.setInqueryChargeHubName(InqBaseName);
              bm2DestVoRow.setPaymentName(VenName);
              bm2DestVoRow.setPaymentNameAlt(VenNameAlt);
              bm2DestVoRow.setPostCode(Zip);
              bm2DestVoRow.setAddress1(Address1);
              bm2DestVoRow.setAddress2(Address2);
              bm2DestVoRow.setAddressLinesPhonetic(PhoneNum);

              //口座情報をマスタの値で更新
              bank2Row.setBankNumber(BkNum);
              bank2Row.setBankName(BkName);
              bank2Row.setBranchNumber(BkBranNum);
              bank2Row.setBranchName(BkBranName);
              bank2Row.setBankAccountType(BkAcType);
              bank2Row.setBankAccountNumber(BkAcNum);
              bank2Row.setBankAccountNameKana(BkAcHldNameAlt);
              bank2Row.setBankAccountNameKanji(BkAcHldName);
            }
          }

        }
        catch ( SQLException e )
        {
          XxcsoUtils.unexpected(txn, e);
          throw
            XxcsoMessage.createSqlErrorMessage(
              e
             ,XxcsoContractRegistConstants.TOKEN_VALUE_SUPPLIER_CHANGE_CHK
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

    retVal         = null;
    BkAcType       = null;
    BkAcHldNameAlt = null;
    BkAcHldName    = null;
    msgVenCd       = null;

    /////////////////////////////////////
    // BM3送付先変更チェック
    /////////////////////////////////////
    // BM3指定がONの場合
    if ( XxcsoContractRegistValidateUtils.isChecked(
           pageRenderRow.getBm3ExistFlag() ) )
    {
      //送付先コードがnull以外の場合
      if (bm3DestVoRow.getVendorCode() != null)
      {
        // メッセージ用に入力値を保持
        msgVenCd = bm3DestVoRow.getVendorCode();
        try
        {

          StringBuffer sql = new StringBuffer(300);
          //  送付先変更チェック
          sql.append("BEGIN");
          sql.append("  :1 := xxcso_010003j_pkg.chk_supp_info_change(");
          sql.append("        iv_vendor_code                  => :2");          // 送付先コード
          sql.append("       ,ov_bm_transfer_commission_type  => :3");          // 振込手数料負担
          sql.append("       ,ov_bm_payment_type              => :4");          // 支払方法、明細書
          sql.append("       ,ov_inquiry_base_code            => :5");          // 問合せ担当拠点
          sql.append("       ,ov_inquiry_base_name            => :6");          // 問合せ担当拠点名
          sql.append("       ,ov_vendor_name                  => :7");          // 送付先名
          sql.append("       ,ov_vendor_name_alt              => :8");          // 送付先名カナ
          sql.append("       ,ov_zip                          => :9");          // 郵便番号
          sql.append("       ,ov_address_line1                => :10");         // 住所１
          sql.append("       ,ov_address_line2                => :11");         // 住所２
          sql.append("       ,ov_phone_number                 => :12");         // 電話番号
          sql.append("       ,ov_bank_number                  => :13");         // 金融機関コード
          sql.append("       ,ov_bank_name                    => :14");         // 金融機関名
          sql.append("       ,ov_bank_branch_number           => :15");         // 支店コード
          sql.append("       ,ov_bank_branch_name             => :16");         // 支店名
          sql.append("       ,ov_bank_account_type            => :17");         // 口座種別
          sql.append("       ,ov_bank_account_num             => :18");         // 口座番号
          sql.append("       ,ov_bank_account_holder_nm_alt   => :19");         // 口座名義カナ
          sql.append("       ,ov_bank_account_holder_nm       => :20");         // 口座名義漢字
          sql.append("        );");
          sql.append("END;");

          stmt
            = (OracleCallableStatement)
                txn.createCallableStatement(sql.toString(), 0);

          stmt.registerOutParameter(1, OracleTypes.VARCHAR);
          stmt.setString(2, bm3DestVoRow.getVendorCode());
          stmt.registerOutParameter(3, OracleTypes.VARCHAR);
          stmt.registerOutParameter(4, OracleTypes.VARCHAR);
          stmt.registerOutParameter(5, OracleTypes.VARCHAR);
          stmt.registerOutParameter(6, OracleTypes.VARCHAR);
          stmt.registerOutParameter(7, OracleTypes.VARCHAR);
          stmt.registerOutParameter(8, OracleTypes.VARCHAR);
          stmt.registerOutParameter(9, OracleTypes.VARCHAR);
          stmt.registerOutParameter(10,OracleTypes.VARCHAR);
          stmt.registerOutParameter(11,OracleTypes.VARCHAR);
          stmt.registerOutParameter(12,OracleTypes.VARCHAR);
          stmt.registerOutParameter(13,OracleTypes.VARCHAR);
          stmt.registerOutParameter(14,OracleTypes.VARCHAR);
          stmt.registerOutParameter(15,OracleTypes.VARCHAR);
          stmt.registerOutParameter(16,OracleTypes.VARCHAR);
          stmt.registerOutParameter(17,OracleTypes.VARCHAR);
          stmt.registerOutParameter(18,OracleTypes.VARCHAR);
          stmt.registerOutParameter(19,OracleTypes.VARCHAR);
          stmt.registerOutParameter(20,OracleTypes.VARCHAR);

          stmt.execute();

          retVal = stmt.getString(1);   //リターンコード

        	//戻り値が1(ダミー仕入先)場合
          if ( "1".equals(retVal) )
          {
            //送付先情報
            BmTranComType   = stmt.getString(3);   //振込手数料負担
            BmPayType       = stmt.getString(4);   //支払方法、明細書
            InqBaseCode     = stmt.getString(5);   //問合せ担当拠点
            InqBaseName     = stmt.getString(6);   //問合せ担当拠点名
            VenName         = stmt.getString(7);   //送付先名
            VenNameAlt      = stmt.getString(8);   //送付先名カナ
            Zip             = stmt.getString(9);   //郵便番号
            Address1        = stmt.getString(10);  //住所１
            Address2        = stmt.getString(11);  //住所２
            PhoneNum        = stmt.getString(12);  //電話番号

            //送付先の銀行情報
            BkNum           = stmt.getString(13);  //金融機関コード
            BkName          = stmt.getString(14);  //金融機関名
            BkBranNum       = stmt.getString(15);  //支店コード
            BkBranName      = stmt.getString(16);  //支店名
            BkAcType        = stmt.getString(17);  //口座種別
            BkAcNum         = stmt.getString(18);  //口座番号
            BkAcHldNameAlt  = stmt.getString(19);  //口座名義カナ
            BkAcHldName     = stmt.getString(20);  //口座名義漢字

            //全ての項目に対して変更があるかチェック
            if (   !(bm3DestVoRow.getBankTransferFeeChargeDiv() != null && (bm3DestVoRow.getBankTransferFeeChargeDiv()).equals(BmTranComType)
                    || bm3DestVoRow.getBankTransferFeeChargeDiv() == null && BmTranComType == null)
                || !(bm3DestVoRow.getBellingDetailsDiv() != null && (bm3DestVoRow.getBellingDetailsDiv()).equals(BmPayType))
                || !(bm3DestVoRow.getInqueryChargeHubCd() != null && (bm3DestVoRow.getInqueryChargeHubCd()).equals(InqBaseCode))
                || !(bm3DestVoRow.getInqueryChargeHubName() != null && (bm3DestVoRow.getInqueryChargeHubName()).equals(InqBaseName))
                || !(bm3DestVoRow.getPaymentName() != null &&  (bm3DestVoRow.getPaymentName()).equals(VenName))
                || !(bm3DestVoRow.getPaymentNameAlt() != null && (bm3DestVoRow.getPaymentNameAlt()).equals(VenNameAlt))
                || !(bm3DestVoRow.getPostCode() != null && (bm3DestVoRow.getPostCode()).equals(Zip))
                || !(bm3DestVoRow.getAddress1() != null && (bm3DestVoRow.getAddress1()).equals(Address1))
                || !(bm3DestVoRow.getAddress2() != null && (bm3DestVoRow.getAddress2()).equals(Address2)
                    || bm3DestVoRow.getAddress2() == null && Address2 == null)
                || !(bm3DestVoRow.getAddressLinesPhonetic() != null && (bm3DestVoRow.getAddressLinesPhonetic()).equals(PhoneNum)
                    || bm3DestVoRow.getAddressLinesPhonetic() == null && PhoneNum == null)
                || !(bank3Row.getBankNumber() != null && (bank3Row.getBankNumber()).equals(BkNum)
                    || bank3Row.getBankNumber() == null && BkNum == null)
                || !(bank3Row.getBankName() != null && (bank3Row.getBankName()).equals(BkName)
                    || bank3Row.getBankName() == null && BkName == null)
                || !(bank3Row.getBranchNumber() != null && (bank3Row.getBranchNumber()).equals(BkBranNum)
                    || bank3Row.getBranchNumber() == null && BkBranNum == null)
                || !(bank3Row.getBranchName() != null && (bank3Row.getBranchName()).equals(BkBranName)
                    || bank3Row.getBranchName() == null && BkBranName == null)
                || !(bank3Row.getBankAccountType() != null && (bank3Row.getBankAccountType()).equals(BkAcType)
                    || bank3Row.getBankAccountType() == null && BkAcType == null)
                || !(bank3Row.getBankAccountNumber() != null && (bank3Row.getBankAccountNumber()).equals(BkAcNum)
                    || bank3Row.getBankAccountNumber() == null && BkAcNum == null)
                || !(bank3Row.getBankAccountNameKana() != null && (bank3Row.getBankAccountNameKana()).equals(BkAcHldNameAlt)
                    || bank3Row.getBankAccountNameKana() == null && BkAcHldNameAlt == null)
                || !(bank3Row.getBankAccountNameKanji() != null && (bank3Row.getBankAccountNameKanji()).equals(BkAcHldName)
                    || bank3Row.getBankAccountNameKanji() == null && BkAcHldName == null))
            {
              //BM3トークン設定
              if ( sbMsg.length() > 0 )
              {
                sbMsg.append( XxcsoConstants.TOKEN_VALUE_DELIMITER2 );
              }
              sbMsg.append(  XxcsoContractRegistConstants.TOKEN_VALUE_BM3 
                           + XxcsoConstants.TOKEN_VALUE_DELIMITER3
                           + msgVenCd );

              //送付先情報をマスタの値で更新
              bm3DestVoRow.setBankTransferFeeChargeDiv(BmTranComType);
              bm3DestVoRow.setBellingDetailsDiv(BmPayType);
              bm3DestVoRow.setInqueryChargeHubCd(InqBaseCode);
              bm3DestVoRow.setInqueryChargeHubName(InqBaseName);
              bm3DestVoRow.setPaymentName(VenName);
              bm3DestVoRow.setPaymentNameAlt(VenNameAlt);
              bm3DestVoRow.setPostCode(Zip);
              bm3DestVoRow.setAddress1(Address1);
              bm3DestVoRow.setAddress2(Address2);
              bm3DestVoRow.setAddressLinesPhonetic(PhoneNum);

              //口座情報をマスタの値で更新
              bank3Row.setBankNumber(BkNum);
              bank3Row.setBankName(BkName);
              bank3Row.setBranchNumber(BkBranNum);
              bank3Row.setBranchName(BkBranName);
              bank3Row.setBankAccountType(BkAcType);
              bank3Row.setBankAccountNumber(BkAcNum);
              bank3Row.setBankAccountNameKana(BkAcHldNameAlt);
              bank3Row.setBankAccountNameKanji(BkAcHldName);
            }
          }

        }
        catch ( SQLException e )
        {
          XxcsoUtils.unexpected(txn, e);
          throw
            XxcsoMessage.createSqlErrorMessage(
              e
             ,XxcsoContractRegistConstants.TOKEN_VALUE_SUPPLIER_CHANGE_CHK
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
    
    // 送付先情報が変更されている場合、確認画面を表示する
    if (sbMsg.length() > 0)
    {
      confirmMsg
        = XxcsoMessage.createWarningMessage(
            XxcsoConstants.APP_XXCSO1_00889
           ,XxcsoConstants.TOKEN_VENDOR_CD
           ,new String(sbMsg)
          );
     }

    XxcsoUtils.debug(txn, "[END]");

    return confirmMsg;
  }
// V2.2 Y.Sasaki Added END
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

  /**
   * 
   * Container's getter for getXxcsoSpDecisionHeadersSummuryVO1
   */
  public XxcsoSpDecisionHeadersSummuryVOImpl getXxcsoSpDecisionHeadersSummuryVO1()
  {
    return (XxcsoSpDecisionHeadersSummuryVOImpl)findViewObject("XxcsoSpDecisionHeadersSummuryVO1");
  }





  /**
   * 
   * Container's getter for XxcsoSpDecisionHeadersSummuryVO2
   */
  public XxcsoSpDecisionHeadersSummuryVOImpl getXxcsoSpDecisionHeadersSummuryVO2()
  {
    return (XxcsoSpDecisionHeadersSummuryVOImpl)findViewObject("XxcsoSpDecisionHeadersSummuryVO2");
  }

  /**
   * 
   * Container's getter for XxcsoContractOtherCustFullVO1
   */
  public XxcsoContractOtherCustFullVOImpl getXxcsoContractOtherCustFullVO1()
  {
    return (XxcsoContractOtherCustFullVOImpl)findViewObject("XxcsoContractOtherCustFullVO1");
  }




  /**
   * 
   * Container's getter for XxcsoContractOtherCustFullVO2
   */
  public XxcsoContractOtherCustFullVOImpl getXxcsoContractOtherCustFullVO2()
  {
    return (XxcsoContractOtherCustFullVOImpl)findViewObject("XxcsoContractOtherCustFullVO2");
  }
















































}