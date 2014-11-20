/*============================================================================
* ファイル名 : XxcsoBaseSearchLovVOImpl
* 概要説明   : 週次活動状況照会／部署検索LOVアプリケーションモジュールクラス
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-11-06 1.0  SCS柳平直人  新規作成
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso008001j.lov.server;
import oracle.apps.fnd.framework.server.OAApplicationModuleImpl;

/*******************************************************************************
 * 週次活動状況照会　部署検索LOVアプリケーションモジュールクラス
 * @author  SCS柳平直人
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoBaseSearchLovAMImpl extends OAApplicationModuleImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoBaseSearchLovAMImpl()
  {
  }


  /**
   * 
   * Sample main for debugging Business Components code using the tester.
   */
  public static void main(String[] args)
  {
    launchTester("itoen.oracle.apps.xxcso.xxcso008001j.lov.server", "XxcsoDivisionSearchLovAMLocal");
  }

  /**
   * 
   * Container's getter for XxcsoBaseSearchLovVO1
   */
  public XxcsoBaseSearchLovVOImpl getXxcsoBaseSearchLovVO1()
  {
    return (XxcsoBaseSearchLovVOImpl)findViewObject("XxcsoBaseSearchLovVO1");
  }
}