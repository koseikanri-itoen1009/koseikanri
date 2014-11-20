/*============================================================================
* ファイル名 : XxcsoQuoteStoreRegistLovAMImpl
* 概要説明   : 帳合問屋用見積入力画面LOV用アプリケーション・モジュールクラス
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2009-01-15 1.0  SCS及川領    新規作成
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso017002j.lov.server;
import oracle.apps.fnd.framework.server.OAApplicationModuleImpl;
/*******************************************************************************
 * 帳合問屋用見積入力画面のLOVのアプリケーション・モジュールクラスです。
 * @author  SCS及川領
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoQuoteStoreRegistLovAMImpl extends OAApplicationModuleImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoQuoteStoreRegistLovAMImpl()
  {
  }

  /**
   * 
   * Container's getter for XxcsoRefQuoteNumberLovVO1
   */
  public XxcsoRefQuoteNumberLovVOImpl getXxcsoRefQuoteNumberLovVO1()
  {
    return (XxcsoRefQuoteNumberLovVOImpl)findViewObject("XxcsoRefQuoteNumberLovVO1");
  }

  /**
   * 
   * Sample main for debugging Business Components code using the tester.
   */
  public static void main(String[] args)
  {
    launchTester("itoen.oracle.apps.xxcso.xxcso017002j.lov.server", "XxcsoQuoteStoreRegistLovAMLocal");
  }

  /**
   * 
   * Container's getter for XxcsoAccountStoreLovVO1
   */
  public XxcsoAccountStoreLovVOImpl getXxcsoAccountStoreLovVO1()
  {
    return (XxcsoAccountStoreLovVOImpl)findViewObject("XxcsoAccountStoreLovVO1");
  }


}