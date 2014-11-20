/*============================================================================
* ファイル名 : XxcsoSpDecisionSearchAMImpl
* 概要説明   : SP専決書検索画面アプリケーション・モジュールクラス
* バージョン : 1.4
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-12-16 1.0  SCS小川浩     新規作成
* 2009-04-20 1.1  SCS柳平直人   [ST障害T1_0619]消去ボタン初期化不正対応
* 2009-08-04 1.2  SCS小川浩     [SCS障害0000821]承認用画面のコピーボタン表示対応
* 2009-09-02 1.3  SCS阿部大輔   [SCS障害0001265]検索条件の修正対応
* 2011-04-25 1.4  SCS桐生和幸   [E_本稼動_07224]SP専決参照権限変更対応
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

/* 20090902_abe_0001265 START*/
    Boolean btnFlag = initRow.getCopyButtonRender();
/* 20090902_abe_0001265 END*/
// 2011-04-25 [E_本稼動_07224] Add Start
    Boolean btnFlag2 = initRow.getDetailButtonRender();
// 2011-04-25 [E_本稼動_07224] Add End

    initRow = (XxcsoSpDecisionSearchInitVORowImpl)initVo.first();
    initRow.setEmployeeNumber(null);
    initRow.setFullName(null);
// 2009-04-20 [ST障害T1_0302] Add Start
    if ( XxcsoSpDecisionConstants.APPROVE_MODE.equals(
        initRow.getSearchClass())
    )
    {
      initRow.setApplyBaseUserRender(Boolean.FALSE);
/* 20090902_abe_0001265 START*/
//      initRow.setCopyButtonRender(Boolean.FALSE);
/* 20090902_abe_0001265 END*/
    }
    else
    {
      initRow.setApplyBaseUserRender(Boolean.TRUE);
/* 20090902_abe_0001265 START*/
//      initRow.setCopyButtonRender(Boolean.TRUE);
/* 20090902_abe_0001265 END*/
    }
/* 20090902_abe_0001265 START*/
    if ( Boolean.TRUE.equals(btnFlag) )
    {
      initRow.setCopyButtonRender(Boolean.TRUE);
/* 20090902_abe_0001265 END*/
// 2011-04-25 [E_本稼動_07224] Del Start
//      initRow.setDetailButtonRender(Boolean.TRUE);
// 2011-04-25 [E_本稼動_07224] Del End
/* 20090902_abe_0001265 START*/
    }
    else
    {
      initRow.setCopyButtonRender(Boolean.FALSE);
// 2011-04-25 [E_本稼動_07224] Del Start
//      initRow.setDetailButtonRender(Boolean.FALSE);
// 2011-04-25 [E_本稼動_07224] Del End
    }
/* 20090902_abe_0001265 END*/
// 2009-04-20 [ST障害T1_0302] Add End
// 2011-04-25 [E_本稼動_07224] Add Start
    if ( Boolean.TRUE.equals(btnFlag2) )
    {
      initRow.setDetailButtonRender(Boolean.TRUE);
    }
    else
    {
      initRow.setDetailButtonRender(Boolean.FALSE);
    }
// 2011-04-25 [E_本稼動_07224] Add End
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
// 2009-08-04 [障害0000821] Mod Start
//      initRow.setCopyButtonRender(Boolean.FALSE);
// 2011-04-25 [E_本稼動_07224] Mod Start
//        initRow.setCopyButtonRender(Boolean.TRUE);
        if ( initRow.getInitActPoBaseCode() == null )
        {
          initRow.setCopyButtonRender(Boolean.TRUE);
        }
        else
        {
          //発注代行拠点の場合、コピーの使用は不可
          initRow.setCopyButtonRender(Boolean.FALSE);
        }
// 2011-04-25 [E_本稼動_07224] Mod End
// 2009-08-04 [障害0000821] Mod End
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