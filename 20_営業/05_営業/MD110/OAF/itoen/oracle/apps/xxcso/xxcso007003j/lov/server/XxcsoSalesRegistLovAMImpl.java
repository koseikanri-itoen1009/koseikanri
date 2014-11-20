/*============================================================================
* ファイル名 : XxcsoSalesRegistLovAMImpl
* 概要説明   : 商談決定情報入力LOVアプリケーションモジュールクラス
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2009-01-06 1.0  SCS小川浩    新規作成
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso007003j.lov.server;
import oracle.apps.fnd.framework.server.OAApplicationModuleImpl;

/*******************************************************************************
 * 商談決定情報入力のLOVアプリケーションモジュールクラス
 * @author  SCS小川浩
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoSalesRegistLovAMImpl extends OAApplicationModuleImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoSalesRegistLovAMImpl()
  {
  }

  /**
   * 
   * Container's getter for XxcsoInventoryItemLovVO1
   */
  public XxcsoInventoryItemLovVOImpl getXxcsoInventoryItemLovVO1()
  {
    return (XxcsoInventoryItemLovVOImpl)findViewObject("XxcsoInventoryItemLovVO1");
  }

  /**
   * 
   * Container's getter for XxcsoNotifyUserLovVO1
   */
  public XxcsoNotifyUserLovVOImpl getXxcsoNotifyUserLovVO1()
  {
    return (XxcsoNotifyUserLovVOImpl)findViewObject("XxcsoNotifyUserLovVO1");
  }

  /**
   * 
   * Container's getter for XxcsoQuoteItemLovVO1
   */
  public XxcsoQuoteItemLovVOImpl getXxcsoQuoteItemLovVO1()
  {
    return (XxcsoQuoteItemLovVOImpl)findViewObject("XxcsoQuoteItemLovVO1");
  }

  /**
   * 
   * Sample main for debugging Business Components code using the tester.
   */
  public static void main(String[] args)
  {
    launchTester("itoen.oracle.apps.xxcso.xxcso007003j.lov.server", "XxcsoSalesRegistLovAMLocal");
  }

  /**
   * 
   * Container's getter for XxcsoApprovalUserLovVO1
   */
  public XxcsoApprovalUserLovVOImpl getXxcsoApprovalUserLovVO1()
  {
    return (XxcsoApprovalUserLovVOImpl)findViewObject("XxcsoApprovalUserLovVO1");
  }
}