/*============================================================================
* ファイル名 : XxcsoSalesNotificationAMImpl
* 概要説明   : 商談決定情報通知画面アプリケーション・モジュールクラス
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2009-01-08 1.0  SCS小川浩    新規作成
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso007002j.server;
import oracle.apps.fnd.framework.server.OAApplicationModuleImpl;
import oracle.apps.fnd.framework.server.OADBTransaction;
import itoen.oracle.apps.xxcso.common.util.XxcsoUtils;
import itoen.oracle.apps.xxcso.common.util.XxcsoMessage;
import itoen.oracle.apps.xxcso.xxcso007002j.util.XxcsoSalesNotificationConstants;
import com.sun.java.util.collections.HashMap;

/*******************************************************************************
 * 商談決定情報通知を表示するためのアプリケーション・モジュールクラスです。
 * @author  SCS小川浩
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoSalesNotificationAMImpl extends OAApplicationModuleImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoSalesNotificationAMImpl()
  {
  }



  /*****************************************************************************
   * アプリケーション・モジュールの初期化処理です。
   * @param mode     実行モード
   * @param notifyId 通知ID
   *****************************************************************************
   */
  public void initDetails(
    String mode
   ,String notifyId
  )
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    // インスタンス取得
    XxcsoSalesNotifySummaryVOImpl notifyVo
      = getXxcsoSalesNotifySummaryVO1();
    if ( notifyVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSalesNotifyUserSumVO1"
        );
    }

    XxcsoSalesHeaderHistSumVOImpl headerVo
      = getXxcsoSalesHeaderHistSumVO1();
    if ( headerVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSalesHeaderHistSumVO1"
        );
    }

    XxcsoSalesLineHistSumVOImpl lineVo
      = getXxcsoSalesLineHistSumVO1();
    if ( lineVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSalesLineHistSumVO1"
        );
    }

    XxcsoSalesNotifyUserSumVOImpl userVo
      = getXxcsoSalesNotifyUserSumVO1();
    if ( userVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSalesNotifyUserSumVO1"
        );
    }

    ///////////////////////////////////////
    // 通知IDより履歴ヘッダIDを取得
    ///////////////////////////////////////
    notifyVo.initQuery(notifyId);
    XxcsoSalesNotifySummaryVORowImpl notifyRow
      = (XxcsoSalesNotifySummaryVORowImpl)notifyVo.first();

    if ( XxcsoSalesNotificationConstants.MODE_REQUEST.equals(mode) )
    {
      notifyRow.setNotifyListHdrRNRender(Boolean.TRUE);
      notifyRow.setApprRjctCommentHdrRNRender(Boolean.FALSE);
    }

    if ( XxcsoSalesNotificationConstants.MODE_RESULT.equals(mode) )
    {
      notifyRow.setNotifyListHdrRNRender(Boolean.TRUE);
      notifyRow.setApprRjctCommentHdrRNRender(Boolean.TRUE);
    }

    if ( XxcsoSalesNotificationConstants.MODE_NOTIFY.equals(mode) )
    {
      notifyRow.setNotifyListHdrRNRender(Boolean.FALSE);
      notifyRow.setApprRjctCommentHdrRNRender(Boolean.FALSE);
    }

    ///////////////////////////////////////
    // 履歴ヘッダIDより各VOの初期化
    ///////////////////////////////////////
    headerVo.initQuery(notifyRow.getHeaderHistoryId());
    XxcsoSalesHeaderHistSumVORowImpl headerRow
      = (XxcsoSalesHeaderHistSumVORowImpl)headerVo.first();

    if ( "Y".equals(headerRow.getSalesDashboadUseFlag()) )
    {
      headerRow.setLeadDescriptionLinkRender(Boolean.TRUE);
    }
    else
    {
      headerRow.setLeadDescriptionLinkRender(Boolean.FALSE);
    }
    
    lineVo.initQuery(notifyRow.getHeaderHistoryId());
    userVo.initQuery(notifyRow.getHeaderHistoryId());

    XxcsoSalesLineHistSumVORowImpl lineRow
      = (XxcsoSalesLineHistSumVORowImpl)lineVo.first();
    while ( lineRow != null )
    {
      setLineRender(lineRow);
      lineRow = (XxcsoSalesLineHistSumVORowImpl)lineVo.next();
    }
    lineVo.first();
    
    XxcsoUtils.debug(txn, "[END]");
  }


  /*****************************************************************************
   * 商談名リンククリック処理
   * @return HashMap URLパラメータ
   *****************************************************************************
   */
  public HashMap handleSelectLeadDescriptionLink()
  {
    OADBTransaction txn = getOADBTransaction();
    
    XxcsoUtils.debug(txn, "[START]");

    XxcsoSalesHeaderHistSumVOImpl headerVo
      = getXxcsoSalesHeaderHistSumVO1();
    if ( headerVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSalesHeaderHistSumVO1"
        );
    }

    XxcsoSalesHeaderHistSumVORowImpl headerRow
      = (XxcsoSalesHeaderHistSumVORowImpl)headerVo.first();

    HashMap params = new HashMap(1);
    params.put(
      "ASNReqFrmOpptyId"
     ,headerRow.getLeadId()
    );
    
    XxcsoUtils.debug(txn, "[END]");

    return params;
  }


  /*****************************************************************************
   * 商談決定情報履歴明細行の表示／非表示の設定処理です。
   * @param lineRow 商談決定情報履歴明細行インスタンス
   *****************************************************************************
   */
  private void setLineRender(
    XxcsoSalesLineHistSumVORowImpl lineRow
  )
  {
    OADBTransaction txn = getOADBTransaction();
    
    XxcsoUtils.debug(txn, "[START]");

    // すべて表示に設定します。
    lineRow.setSalesAdoptClassRender(Boolean.TRUE);
    lineRow.setSalesAreaRender(Boolean.TRUE);
    lineRow.setDelivPriceRender(Boolean.TRUE);
    lineRow.setStoreSalesPriceRender(Boolean.TRUE);
    lineRow.setStoreSalesPriceIncTaxRender(Boolean.TRUE);
    lineRow.setQuotationPriceRender(Boolean.TRUE);

    String salesClassCode = lineRow.getSalesClassCode();
    if ( salesClassCode == null || "".equals(salesClassCode) )
    {
      lineRow.setSalesAdoptClassRender(Boolean.FALSE);
    }
    else
    {
      if ( XxcsoSalesNotificationConstants.SALES_CLASS_CAMP.equals(
             salesClassCode)
         )
      {
        // 採用区分を非表示に設定します。
        lineRow.setSalesAdoptClassRender(Boolean.FALSE);
      }
      if ( XxcsoSalesNotificationConstants.SALES_CLASS_CUT.equals(
             salesClassCode)
         )
      {
        // 採用区分、販売対象エリア、店納価格、
        // 売価（税抜）、売価（税込）、建値
        // を非表示に設定します。
        lineRow.setSalesAdoptClassRender(Boolean.FALSE);
        lineRow.setSalesAreaRender(Boolean.FALSE);
        lineRow.setDelivPriceRender(Boolean.FALSE);
        lineRow.setStoreSalesPriceRender(Boolean.FALSE);
        lineRow.setStoreSalesPriceIncTaxRender(Boolean.FALSE);
        lineRow.setQuotationPriceRender(Boolean.FALSE);
      }
    }
    
    XxcsoUtils.debug(txn, "[END]");
  }

  
  /**
   * 
   * Container's getter for XxcsoSalesHeaderHistSumVO1
   */
  public XxcsoSalesHeaderHistSumVOImpl getXxcsoSalesHeaderHistSumVO1()
  {
    return (XxcsoSalesHeaderHistSumVOImpl)findViewObject("XxcsoSalesHeaderHistSumVO1");
  }

  /**
   * 
   * Container's getter for XxcsoSalesLineHistSumVO1
   */
  public XxcsoSalesLineHistSumVOImpl getXxcsoSalesLineHistSumVO1()
  {
    return (XxcsoSalesLineHistSumVOImpl)findViewObject("XxcsoSalesLineHistSumVO1");
  }


  /**
   * 
   * Sample main for debugging Business Components code using the tester.
   */
  public static void main(String[] args)
  {
    launchTester("itoen.oracle.apps.xxcso.xxcso007002j.server", "XxcsoSalesNotificationAMLocal");
  }

  /**
   * 
   * Container's getter for XxcsoSalesNotifyUserSumVO1
   */
  public XxcsoSalesNotifyUserSumVOImpl getXxcsoSalesNotifyUserSumVO1()
  {
    return (XxcsoSalesNotifyUserSumVOImpl)findViewObject("XxcsoSalesNotifyUserSumVO1");
  }

  /**
   * 
   * Container's getter for XxcsoSalesNotifySummaryVO1
   */
  public XxcsoSalesNotifySummaryVOImpl getXxcsoSalesNotifySummaryVO1()
  {
    return (XxcsoSalesNotifySummaryVOImpl)findViewObject("XxcsoSalesNotifySummaryVO1");
  }
}