/*============================================================================
* ファイル名 : XxcsoRtnRsrcBulkUpdateLovAMImpl
* 概要説明   : 顧客コードLOV用アプリケーション・モジュールクラス
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
 * 顧客コードLOVのアプリケーション・モジュールクラス
 * @author  SCS富尾和基
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoRtnRsrcBulkUpdateLovAMImpl extends OAApplicationModuleImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoRtnRsrcBulkUpdateLovAMImpl()
  {
  }

  /**
   * 
   * Container's getter for XxcsoAccountRtnRsrcLovVO1
   */
  public XxcsoAccountRtnRsrcLovVOImpl getXxcsoAccountRtnRsrcLovVO1()
  {
    return (XxcsoAccountRtnRsrcLovVOImpl)findViewObject("XxcsoAccountRtnRsrcLovVO1");
  }

  /**
   * 
   * Sample main for debugging Business Components code using the tester.
   */
  public static void main(String[] args)
  {
    launchTester("itoen.oracle.apps.xxcso.xxcso019009j.lov.server", "XxcsoRtnRsrcBulkUpdateLovAMLocal");
  }


}