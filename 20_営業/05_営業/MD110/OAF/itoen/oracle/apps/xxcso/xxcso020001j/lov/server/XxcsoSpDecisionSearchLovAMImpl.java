/*============================================================================
* ファイル名 : XxcsoSpDecisionSearchLovAMImpl
* 概要説明   : SP専決検索画面LOV用アプリケーション・モジュールクラス
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-12-18 1.0  SCS小川浩    新規作成
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso020001j.lov.server;
import oracle.apps.fnd.framework.server.OAApplicationModuleImpl;

/*******************************************************************************
 * SP専決検索画面のLOVのアプリケーション・モジュールクラスです。
 * @author  SCS小川浩
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoSpDecisionSearchLovAMImpl extends OAApplicationModuleImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoSpDecisionSearchLovAMImpl()
  {
  }


  /**
   * 
   * Sample main for debugging Business Components code using the tester.
   */
  public static void main(String[] args)
  {
    launchTester("itoen.oracle.apps.xxcso.xxcso020001j.lov.server", "XxcsoAccountForSearchLovAMLocal");
  }

  /**
   * 
   * Container's getter for XxcsoAccountForSearchLovVO1
   */
  public XxcsoAccountForSearchLovVOImpl getXxcsoAccountForSearchLovVO1()
  {
    return (XxcsoAccountForSearchLovVOImpl)findViewObject("XxcsoAccountForSearchLovVO1");
  }

  /**
   * 
   * Container's getter for XxcsoApplyUserLovVO1
   */
  public XxcsoApplyUserLovVOImpl getXxcsoApplyUserLovVO1()
  {
    return (XxcsoApplyUserLovVOImpl)findViewObject("XxcsoApplyUserLovVO1");
  }
}