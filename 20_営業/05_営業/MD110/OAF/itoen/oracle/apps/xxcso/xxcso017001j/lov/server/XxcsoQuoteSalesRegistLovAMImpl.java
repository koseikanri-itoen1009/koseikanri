/*============================================================================
* ファイル名 : XxcsoQuoteSalesRegistLovAMImpl
* 概要説明   : 販売先見積入力画面LOV用アプリケーション・モジュールクラス
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-12-21 1.0  SCS小川浩    新規作成
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso017001j.lov.server;
import oracle.apps.fnd.framework.server.OAApplicationModuleImpl;
/*******************************************************************************
 * 販売先見積入力画面のLOVのアプリケーション・モジュールクラスです。
 * @author  SCS小川浩
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoQuoteSalesRegistLovAMImpl extends OAApplicationModuleImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoQuoteSalesRegistLovAMImpl()
  {
  }

  /**
   * 
   * Sample main for debugging Business Components code using the tester.
   */
  public static void main(String[] args)
  {
    launchTester("itoen.oracle.apps.xxcso.xxcso017001j.lov.server", "XxcsoQuoteSalesRegistLovAMLocal");
  }

  /**
   * 
   * Container's getter for XxcsoAccountSearchLovVO1
   */
  public XxcsoAccountSearchLovVOImpl getXxcsoAccountSearchLovVO1()
  {
    return (XxcsoAccountSearchLovVOImpl)findViewObject("XxcsoAccountSearchLovVO1");
  }

  /**
   * 
   * Container's getter for XxcsoInventoryItemSearchLovVO1
   */
  public XxcsoInventoryItemSearchLovVOImpl getXxcsoInventoryItemSearchLovVO1()
  {
    return (XxcsoInventoryItemSearchLovVOImpl)findViewObject("XxcsoInventoryItemSearchLovVO1");
  }
}