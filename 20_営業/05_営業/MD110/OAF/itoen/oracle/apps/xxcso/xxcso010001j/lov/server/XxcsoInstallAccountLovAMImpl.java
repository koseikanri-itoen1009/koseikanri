/*============================================================================
* ファイル名 : XxcsoInstallAccountLovAMImpl
* 概要説明   : 顧客情報ＬＯＶアプリケーション・モジュールクラス
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
 * 顧客情報ＬＯＶを作成するためのアプリケーション・モジュールクラスです。
 * @author  SCS及川領
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoInstallAccountLovAMImpl extends OAApplicationModuleImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoInstallAccountLovAMImpl()
  {
  }

  /**
   * 
   * Container's getter for XxcsoInstallAccountLovVO1
   */
  public XxcsoInstallAccountLovVOImpl getXxcsoInstallAccountLovVO1()
  {
    return (XxcsoInstallAccountLovVOImpl)findViewObject("XxcsoInstallAccountLovVO1");
  }

  /**
   * 
   * Sample main for debugging Business Components code using the tester.
   */
  public static void main(String[] args)
  {
    launchTester("itoen.oracle.apps.xxcso.xxcso010001j.lov.server", "XxcsoInstallAccountLovAMLocal");
  }
}