/*============================================================================
* ファイル名 : XxcsoSpDecisionSearchAMImpl
* 概要説明   : SP専決書検索画面アプリケーション・モジュールクラス
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-12-16 1.0  SCS小川浩     新規作成
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso020001j.server;

import oracle.apps.fnd.framework.server.OAApplicationModuleImpl;
import oracle.apps.fnd.framework.server.OADBTransaction;
import oracle.jbo.domain.Number;
import itoen.oracle.apps.xxcso.common.util.XxcsoMessage;
import itoen.oracle.apps.xxcso.common.util.XxcsoUtils;
import itoen.oracle.apps.xxcso.common.util.XxcsoConstants;
import itoen.oracle.apps.xxcso.common.poplist.server.XxcsoLookupListVOImpl;
import itoen.oracle.apps.xxcso.xxcso020001j.util.XxcsoSpDecisionConstants;
/*******************************************************************************
 * SP専決書を検索するためのアプリケーション・モジュールクラスです。
 * @author  SCS小川浩
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoSpDecisionSearchAMImpl extends OAApplicationModuleImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoSpDecisionSearchAMImpl()
  {
  }



  /*****************************************************************************
   * アプリケーション・モジュールの初期化処理です。
   * @param searchClass 検索区分
   *****************************************************************************
   */
  public void initDetails(
    String searchClass
  )
  {
    OADBTransaction txn = getOADBTransaction();
    
    XxcsoUtils.debug(txn, "[START]");

    XxcsoSpDecisionSearchInitVOImpl initVo = getXxcsoSpDecisionSearchInitVO1();
    if ( initVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionSearchInitVOImpl"
        );
    }

    if ( ! initVo.isPreparedForExecution() )
    {
      initVo.initQuery(
        searchClass
      );

      XxcsoSpDecisionSearchInitVORowImpl initRow
        = (XxcsoSpDecisionSearchInitVORowImpl)initVo.first();
    
      initRow.setCopyButtonRender(Boolean.FALSE);
      initRow.setDetailButtonRender(Boolean.FALSE);

      if ( XxcsoSpDecisionConstants.APPROVE_MODE.equals(searchClass) )
      {
        initRow.setApplyBaseUserRender(Boolean.FALSE);
      }
      else
      {
        initRow.setApplyBaseUserRender(Boolean.TRUE);
      }
    }
    
    XxcsoLookupListVOImpl statusListVo = getXxcsoSpDecisionStatusListVO();
    if ( statusListVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionStatusListVO"
        );      
    }

    statusListVo.initQuery(
      "XXCSO1_SP_STATUS_CD"
     ,"lookup_code"
    );

    XxcsoUtils.debug(txn, "[END]");
  }

  /*****************************************************************************
   * 消去ボタン押下時の処理です。
   *****************************************************************************
   */
  public void handleClearButton()
  {
    OADBTransaction txn = getOADBTransaction();
    
    XxcsoUtils.debug(txn, "[START]");

    XxcsoSpDecisionSearchInitVOImpl initVo = getXxcsoSpDecisionSearchInitVO1();
    if ( initVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionSearchInitVOImpl"
        );
    }

    XxcsoSpDecisionSearchInitVORowImpl initRow
      = (XxcsoSpDecisionSearchInitVORowImpl)initVo.first();
    
    initVo.initQuery(
      initRow.getSearchClass()
    );

    initRow = (XxcsoSpDecisionSearchInitVORowImpl)initVo.first();
    initRow.setEmployeeNumber(null);
    initRow.setFullName(null);
    
    XxcsoUtils.debug(txn, "[END]");
  }

  /*****************************************************************************
   * 検索ボタン押下時の処理です。
   *****************************************************************************
   */
  public void handleSearchButton()
  {
    OADBTransaction txn = getOADBTransaction();
    
    XxcsoUtils.debug(txn, "[START]");

    XxcsoSpDecisionSearchInitVOImpl initVo = getXxcsoSpDecisionSearchInitVO1();
    if ( initVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionSearchInitVOImpl"
        );
    }

    XxcsoSpDecisionSearchInitVORowImpl initRow
      = (XxcsoSpDecisionSearchInitVORowImpl)initVo.first();
    
    XxcsoSpDecisionSummaryVOImpl sumVo = getXxcsoSpDecisionSummaryVO1();
    if ( sumVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionSummaryVOImpl"
        );      
    }

    sumVo.initQuery(
      initRow.getSearchClass()
     ,initRow.getApplyBaseCode()
     ,initRow.getEmployeeNumber()
     ,initRow.getApplyDateStart()
     ,initRow.getApplyDateEnd()
     ,initRow.getStatus()
     ,initRow.getSpDecisionNumber()
     ,initRow.getCustAccountId()
    );

    if ( sumVo.first() == null )
    {
      initRow.setCopyButtonRender(Boolean.FALSE);
      initRow.setDetailButtonRender(Boolean.FALSE);
    }
    else
    {
      if ( XxcsoSpDecisionConstants.APPROVE_MODE.equals(
             initRow.getSearchClass()
           )
         )
      {
        initRow.setCopyButtonRender(Boolean.FALSE);
      }
      else
      {
        initRow.setCopyButtonRender(Boolean.TRUE);
      }
      initRow.setDetailButtonRender(Boolean.TRUE);
    }
    
    XxcsoUtils.debug(txn, "[END]");
  }

  /*****************************************************************************
   * コピーの作成ボタン押下時の処理です。
   *****************************************************************************
   */
  public String handleCopyButton()
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");
    
    XxcsoSpDecisionSummaryVOImpl sumVo = getXxcsoSpDecisionSummaryVO1();
    if ( sumVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionSummaryVOImpl"
        );      
    }

    XxcsoSpDecisionSummaryVORowImpl sumRow
      = (XxcsoSpDecisionSummaryVORowImpl)sumVo.first();

    Number spDecisionHeaderId = null;
    boolean existFlag = false;
    
    while ( sumRow != null )
    {
      if ( "Y".equals(sumRow.getSelectFlag()) )
      {
        existFlag = true;
        spDecisionHeaderId = sumRow.getSpDecisionHeaderId();
        break;
      }
      sumRow = (XxcsoSpDecisionSummaryVORowImpl)sumVo.next();
    }

    if ( ! existFlag )
    {
      throw XxcsoMessage.createErrorMessage(XxcsoConstants.APP_XXCSO1_00304);
    }

    XxcsoUtils.debug(txn, "[END]");
    
    return spDecisionHeaderId.toString();
  }

  /*****************************************************************************
   * 詳細ボタン押下時の処理です。
   *****************************************************************************
   */
  public String handleDetailButton()
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");
    
    XxcsoSpDecisionSummaryVOImpl sumVo = getXxcsoSpDecisionSummaryVO1();
    if ( sumVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionSummaryVOImpl"
        );      
    }

    XxcsoSpDecisionSummaryVORowImpl sumRow
      = (XxcsoSpDecisionSummaryVORowImpl)sumVo.first();

    Number spDecisionHeaderId = null;
    boolean existFlag = false;
    
    while ( sumRow != null )
    {
      if ( "Y".equals(sumRow.getSelectFlag()) )
      {
        existFlag = true;
        spDecisionHeaderId = sumRow.getSpDecisionHeaderId();
        break;
      }
      sumRow = (XxcsoSpDecisionSummaryVORowImpl)sumVo.next();
    }

    if ( ! existFlag )
    {
      throw XxcsoMessage.createErrorMessage(XxcsoConstants.APP_XXCSO1_00304);
    }

    XxcsoUtils.debug(txn, "[END]");
    
    return spDecisionHeaderId.toString();
  }

  
  /**
   * 
   * Container's getter for XxcsoSpDecisionSearchInitVO1
   */
  public XxcsoSpDecisionSearchInitVOImpl getXxcsoSpDecisionSearchInitVO1()
  {
    return (XxcsoSpDecisionSearchInitVOImpl)findViewObject("XxcsoSpDecisionSearchInitVO1");
  }

  /**
   * 
   * Sample main for debugging Business Components code using the tester.
   */
  public static void main(String[] args)
  {
    launchTester("itoen.oracle.apps.xxcso.xxcso020001j.server", "XxcsoSpDecisionSearchAMLocal");
  }

  /**
   * 
   * Container's getter for XxcsoSpDecisionStatusListVO
   */
  public XxcsoLookupListVOImpl getXxcsoSpDecisionStatusListVO()
  {
    return (XxcsoLookupListVOImpl)findViewObject("XxcsoSpDecisionStatusListVO");
  }

  /**
   * 
   * Container's getter for XxcsoSpDecisionSummaryVO1
   */
  public XxcsoSpDecisionSummaryVOImpl getXxcsoSpDecisionSummaryVO1()
  {
    return (XxcsoSpDecisionSummaryVOImpl)findViewObject("XxcsoSpDecisionSummaryVO1");
  }
}