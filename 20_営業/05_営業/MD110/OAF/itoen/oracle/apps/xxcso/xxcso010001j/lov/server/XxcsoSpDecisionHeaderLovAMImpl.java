/*============================================================================
* ファイル名 : XxcsoInstallAccountLovAMImpl
* 概要説明   : SP専決書情報ＬＯＶアプリケーション・モジュールクラス
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-10-31 1.0  SCS及川領    新規作成
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso010001j.lov.server;
import oracle.apps.fnd.framework.server.OAApplicationModuleImpl;
/*******************************************************************************
 * SP専決書情報ＬＯＶを作成するためのアプリケーション・モジュールクラスです。
 * @author  SCS及川領
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoSpDecisionHeaderLovAMImpl extends OAApplicationModuleImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoSpDecisionHeaderLovAMImpl()
  {
  }

  /**
   * 
   * Container's getter for XxcsoSpDecisionHeaderLovVO1
   */
  public XxcsoSpDecisionHeaderLovVOImpl getXxcsoSpDecisionHeaderLovVO1()
  {
    return (XxcsoSpDecisionHeaderLovVOImpl)findViewObject("XxcsoSpDecisionHeaderLovVO1");
  }

  /**
   * 
   * Sample main for debugging Business Components code using the tester.
   */
  public static void main(String[] args)
  {
    launchTester("itoen.oracle.apps.xxcso.xxcso010001j.lov.server", "XxcsoSpDecisionHeaderLovAMLocal");
  }
}