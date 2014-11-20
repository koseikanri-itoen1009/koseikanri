/*============================================================================
* ファイル名 : XxccpOpenWorkListAMImpl
* 概要説明   : オープンワークリストアプリケーション・モジュールクラス
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2009-08-10 1.0  SCS小川浩     新規作成
*============================================================================
*/
package itoen.oracle.apps.xxccp.xxccp010A01j.server;
import oracle.apps.fnd.framework.server.OAApplicationModuleImpl;

/*******************************************************************************
 * オープンワークリストを表示するためのアプリケーション・モジュールクラスです。
 * @author  SCS小川浩
 * @version 1.0
 *******************************************************************************
 */
public class XxccpOpenWorkListAMImpl extends OAApplicationModuleImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxccpOpenWorkListAMImpl()
  {
  }


  /*****************************************************************************
   * アプリケーション・モジュールの初期化処理です。
   * @param userName ログインユーザー名
   *****************************************************************************
   */
  public void initDetails(
    String  userName
  )
  {
    XxccpOpenWorkListPVOImpl pvo = getXxccpOpenWorkListPVO1();
    pvo.executeQuery();
    XxccpOpenWorkListPVORowImpl prow
      = (XxccpOpenWorkListPVORowImpl)pvo.first();
    prow.setSalesOpenWorkListRender(Boolean.FALSE);
    prow.setMfgOpenWorkListRender(Boolean.FALSE);
    prow.setSysOpenWorkListRender(Boolean.FALSE);
    
    XxccpUserRespCheckVOImpl checkVo = getXxccpUserRespCheckVO1();
    checkVo.initQuery(userName);
    XxccpUserRespCheckVORowImpl checkRow
      = (XxccpUserRespCheckVORowImpl)checkVo.first();

    if ( "Y".equals(checkRow.getSysadminUserFlag()) )
    {
      prow.setSysOpenWorkListRender(Boolean.TRUE);
    }
    else
    {
      prow.setMfgOpenWorkListRender(Boolean.TRUE);
      if ( "Y".equals(checkRow.getSalesRespExistsFlag()) )
      {
        prow.setSalesOpenWorkListRender(Boolean.TRUE);      
      }
    }
  }




  /**
   * 
   * Sample main for debugging Business Components code using the tester.
   */
  public static void main(String[] args)
  {
    launchTester("itoen.oracle.apps.xxccp.xxccp010A01j.server", "XxccpOpenWorkListAMLocal");
  }

  /**
   * 
   * Container's getter for XxccpUserRespCheckVO1
   */
  public XxccpUserRespCheckVOImpl getXxccpUserRespCheckVO1()
  {
    return (XxccpUserRespCheckVOImpl)findViewObject("XxccpUserRespCheckVO1");
  }

  /**
   * 
   * Container's getter for XxccpOpenWorkListPVO1
   */
  public XxccpOpenWorkListPVOImpl getXxccpOpenWorkListPVO1()
  {
    return (XxccpOpenWorkListPVOImpl)findViewObject("XxccpOpenWorkListPVO1");
  }


}