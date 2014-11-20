/*============================================================================
* ファイル名 : XxcsoRscRtnRsrcLovAMImpl
* 概要説明   : 担当営業員LOV用アプリケーション・モジュールクラス
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2009-01-16 1.0  SCS富尾和基    新規作成
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso019009j.lov.server;
import oracle.apps.fnd.framework.server.OAApplicationModuleImpl;

/*******************************************************************************
 * 担当営業員LOVのアプリケーション・モジュールクラス
 * @author  SCS富尾和基
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoRscRtnRsrcLovAMImpl extends OAApplicationModuleImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoRscRtnRsrcLovAMImpl()
  {
  }

  /**
   * 
   * Container's getter for XxcsoRscRtnRsrcLovVO1
   */
  public XxcsoRscRtnRsrcLovVOImpl getXxcsoRscRtnRsrcLovVO1()
  {
    return (XxcsoRscRtnRsrcLovVOImpl)findViewObject("XxcsoRscRtnRsrcLovVO1");
  }

  /**
   * 
   * Sample main for debugging Business Components code using the tester.
   */
  public static void main(String[] args)
  {
    launchTester("itoen.oracle.apps.xxcso.xxcso019009j.lov.server", "XxcsoRscRtnRsrcLovAMLocal");
  }
}