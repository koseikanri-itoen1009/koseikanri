/*============================================================================
* ファイル名 : XxcsoSalesRegistAMImpl
* 概要説明   : 商談決定情報表示画面アプリケーション・モジュールクラス
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2009-01-08 1.0  SCS小川浩    新規作成
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso007001j.server;
import oracle.apps.fnd.framework.server.OAApplicationModuleImpl;
import oracle.apps.fnd.framework.server.OADBTransaction;
import itoen.oracle.apps.xxcso.common.util.XxcsoUtils;
import itoen.oracle.apps.xxcso.common.util.XxcsoMessage;
import itoen.oracle.apps.xxcso.common.util.XxcsoConstants;
import com.sun.java.util.collections.HashMap;
import itoen.oracle.apps.xxcso.xxcso007001j.util.XxcsoSalesDecisionViewConstants;

/*******************************************************************************
 * 商談決定情報を表示するためのアプリケーション・モジュールクラスです。
 * @author  SCS小川浩
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoSalesDecisionViewAMImpl extends OAApplicationModuleImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoSalesDecisionViewAMImpl()
  {
  }



  /*****************************************************************************
   * アプリケーション・モジュールの初期化処理です。
   * @param leadId 商談ID
   *****************************************************************************
   */
  public void initDetails(
    String leadId
  )
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    // インスタンス取得
    XxcsoSalesHeaderSummaryVOImpl headerVo
      = getXxcsoSalesHeaderSummaryVO1();
    if ( headerVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSalesHeaderSummaryVO1"
        );
    }

    XxcsoSalesLineSummaryVOImpl lineVo
      = getXxcsoSalesLineSummaryVO1();
    if ( lineVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSalesLineSummaryVO1"
        );
    }

    /////////////////////////////////////
    // 検索実行
    /////////////////////////////////////
    headerVo.initQuery(leadId);
    lineVo.initQuery(leadId);

    XxcsoSalesHeaderSummaryVORowImpl headerRow
      = (XxcsoSalesHeaderSummaryVORowImpl)headerVo.first();

    if ( "1".equals(headerRow.getLeadUpdEnabled()) )
    {
      headerRow.setForwardButtonRender(Boolean.TRUE);
    }
    else
    {
      headerRow.setForwardButtonRender(Boolean.FALSE);
    }

    XxcsoSalesLineSummaryVORowImpl lineRow
      = (XxcsoSalesLineSummaryVORowImpl)lineVo.first();

    while ( lineRow != null )
    {
      setLineRender(lineRow);

      lineRow = (XxcsoSalesLineSummaryVORowImpl)lineVo.next();
    }
    lineVo.first();
    
    XxcsoUtils.debug(txn, "[END]");
  }


  /*****************************************************************************
   * 商談決定情報入力へボタン押下処理です。
   * @return HashMap URLパラメータ
   *****************************************************************************
   */
  public HashMap handleForwardButton()
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    if ( getTransaction().isDirty() )
    {
      throw XxcsoMessage.createErrorMessage(XxcsoConstants.APP_XXCSO1_00335);
    }

    // インスタンス取得
    XxcsoSalesHeaderSummaryVOImpl headerVo
      = getXxcsoSalesHeaderSummaryVO1();
    if ( headerVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSalesHeaderSummaryVO1"
        );
    }

    XxcsoSalesHeaderSummaryVORowImpl headerRow
      = (XxcsoSalesHeaderSummaryVORowImpl)headerVo.first();
    
    HashMap params = new HashMap(1);
    params.put(
      XxcsoConstants.TRANSACTION_KEY1
     ,headerRow.getLeadId()
    );
    
    XxcsoUtils.debug(txn, "[END]");

    return params;
  }


  /*****************************************************************************
   * 商談決定情報明細行の表示／非表示の設定処理です。
   * @param lineRow 商談決定情報明細行インスタンス
   *****************************************************************************
   */
  private void setLineRender(
    XxcsoSalesLineSummaryVORowImpl lineRow
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
      if ( XxcsoSalesDecisionViewConstants.SALES_CLASS_CAMP.equals(
             salesClassCode)
         )
      {
        // 採用区分を非表示に設定します。
        lineRow.setSalesAdoptClassRender(Boolean.FALSE);
      }
      if ( XxcsoSalesDecisionViewConstants.SALES_CLASS_CUT.equals(
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
   * Container's getter for XxcsoSalesHeaderSummaryVO1
   */
  public XxcsoSalesHeaderSummaryVOImpl getXxcsoSalesHeaderSummaryVO1()
  {
    return (XxcsoSalesHeaderSummaryVOImpl)findViewObject("XxcsoSalesHeaderSummaryVO1");
  }

  /**
   * 
   * Container's getter for XxcsoSalesLineSummaryVO1
   */
  public XxcsoSalesLineSummaryVOImpl getXxcsoSalesLineSummaryVO1()
  {
    return (XxcsoSalesLineSummaryVOImpl)findViewObject("XxcsoSalesLineSummaryVO1");
  }

  /**
   * 
   * Sample main for debugging Business Components code using the tester.
   */
  public static void main(String[] args)
  {
    launchTester("itoen.oracle.apps.xxcso.xxcso007001j.server", "XxcsoSalesDecisionViewAMLocal");
  }
}