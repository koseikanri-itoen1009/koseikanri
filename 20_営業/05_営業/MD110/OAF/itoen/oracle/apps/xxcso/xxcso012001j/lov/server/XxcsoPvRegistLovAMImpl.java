/*============================================================================
* ファイル名 : XxcsoPvRegistLovAMImpl
* 概要説明   : パーソナライズ・ビュー作成画面／LOVアプリケーションモジュールクラス
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-12-15 1.0  SCS柳平直人  新規作成
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso012001j.lov.server;
import oracle.apps.fnd.framework.server.OAApplicationModuleImpl;

/*******************************************************************************
 * パーソナライズ・ビュー作成画面／LOVアプリケーションモジュールクラス
 * @author  SCS柳平直人
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoPvRegistLovAMImpl extends OAApplicationModuleImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoPvRegistLovAMImpl()
  {
  }


  /**
   * 
   * Sample main for debugging Business Components code using the tester.
   */
  public static void main(String[] args)
  {
    launchTester("itoen.oracle.apps.xxcso.xxcso012001j.lov.server", "XxcsoEmployeeItemLovAMLocal");
  }

  /**
   * 
   * Container's getter for XxcsoBaseItemLovVO1
   */
  public XxcsoBaseItemLovVOImpl getXxcsoBaseItemLovVO1()
  {
    return (XxcsoBaseItemLovVOImpl)findViewObject("XxcsoBaseItemLovVO1");
  }

  /**
   * 
   * Container's getter for XxcsoModelTypeSearchLovVO1
   */
  public XxcsoModelTypeSearchLovVOImpl getXxcsoModelTypeSearchLovVO1()
  {
    return (XxcsoModelTypeSearchLovVOImpl)findViewObject("XxcsoModelTypeSearchLovVO1");
  }

  /**
   * 
   * Container's getter for XxcsoAccountItemLovVO1
   */
  public XxcsoAccountItemLovVOImpl getXxcsoAccountItemLovVO1()
  {
    return (XxcsoAccountItemLovVOImpl)findViewObject("XxcsoAccountItemLovVO1");
  }
}