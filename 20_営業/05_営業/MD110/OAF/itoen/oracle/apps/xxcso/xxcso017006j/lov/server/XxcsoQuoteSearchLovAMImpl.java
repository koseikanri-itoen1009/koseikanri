/*============================================================================
* ファイル名 : XxcsoQuoteSearchLovAMImpl
* 概要説明   : 見積番号LOVアプリケーション・モジュールクラス
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-12-22 1.0  SCS張吉    新規作成
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso017006j.lov.server;
import oracle.apps.fnd.framework.server.OAApplicationModuleImpl;

/*******************************************************************************
 * 見積番号LOVを作成するためのアプリケーション・モジュールクラスです。
 * @author  SCS張吉
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoQuoteSearchLovAMImpl extends OAApplicationModuleImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoQuoteSearchLovAMImpl()
  {
  }


  /**
   * 
   * Sample main for debugging Business Components code using the tester.
   */
  public static void main(String[] args)
  {
    launchTester("itoen.oracle.apps.xxcso.xxcso017006j.lov.server", "XxcsoQuoteSearchLovAMLocal");
  }

  /**
   * 
   * Container's getter for XxcsoQuoteSearchLovVO1
   */
  public XxcsoQuoteSearchLovVOImpl getXxcsoQuoteSearchLovVO1()
  {
    return (XxcsoQuoteSearchLovVOImpl)findViewObject("XxcsoQuoteSearchLovVO1");
  }
}