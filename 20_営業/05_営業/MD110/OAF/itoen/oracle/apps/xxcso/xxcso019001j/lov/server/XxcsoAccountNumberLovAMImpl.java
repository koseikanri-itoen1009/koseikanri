/*============================================================================
* ファイル名 : XxcsoAccountNumberLovAMImpl
* 概要説明   : 訪問・売上計画画面　顧客コードＬＯＶアプリケーションモジュールクラス
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2009-01-07 1.0  SCS朴邦彦　  新規作成
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso019001j.lov.server;
import oracle.apps.fnd.framework.server.OAApplicationModuleImpl;

/*******************************************************************************
 * 訪問・売上計画画面　顧客コードＬＯＶアプリケーションモジュールクラス
 * @author  SCS朴邦彦
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoAccountNumberLovAMImpl extends OAApplicationModuleImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoAccountNumberLovAMImpl()
  {
  }

  /**
   * 
   * Container's getter for XxcsoAccountNumberLovVO1
   */
  public XxcsoAccountNumberLovVOImpl getXxcsoAccountNumberLovVO1()
  {
    return (XxcsoAccountNumberLovVOImpl)findViewObject("XxcsoAccountNumberLovVO1");
  }

  /**
   * 
   * Sample main for debugging Business Components code using the tester.
   */
  public static void main(String[] args)
  {
    launchTester("itoen.oracle.apps.xxcso.xxcso019001j.lov.server", "XxcsoAccountNumberLovAMLocal");
  }
}